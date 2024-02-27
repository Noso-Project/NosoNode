unit NosoNetwork;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, strutils,
  IdContext, IdGlobal, IdTCPClient,
  nosodebug, nosotime, nosogeneral, nosoheaders, nosocrypto, nosoblock,nosoconsensus,
  nosounit,nosonosoCFG,nosogvts,nosomasternodes,nosopsos;

Type

  TThreadClientRead = class(TThread)
    private
      FSlot: Integer;
    protected
      procedure Execute; override;
    public
      constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
  end;

  Tconectiondata = Packed Record
    Autentic        : boolean;                 // si la conexion esta autenticada por un ping
    Connections     : Integer;             // A cuantos pares esta conectado
    tipo            : string[8];                   // Tipo: SER o CLI
    ip: string[20];                    // La IP del par
    lastping: string[15];              // UTCTime del ultimo ping
    context: TIdContext;               // Informacion para los canales cliente
    Lastblock: string[15];             // Numero del ultimo bloque
    LastblockHash: string[64];         // Hash del ultimo bloque
    SumarioHash : string[64];          // Hash del sumario de cuenta
    Pending: Integer;                  // Cantidad de operaciones pendientes
    Protocol : integer;                // Numero de protocolo usado
    Version : string[8];
    ListeningPort : integer;
    offset : integer;                  // Segundos de diferencia a su tiempo
    ResumenHash : String[64];           //
    ConexStatus : integer;
    IsBusy : Boolean;
    Thread : TThreadClientRead;
    MNsHash : string[5];
    MNsCount : Integer;
    BestHashDiff : string[32];
    MNChecksCount : integer;
    GVTsHash      : string[32];
    CFGHash       : string[32];
    MerkleHash    : string[32];
    PSOHash       : string[32];
    end;

  TBotData = Packed Record
   ip          : string[15];
   LastRefused : int64;
   end;

  Procedure ClearOutTextToSlot(slot:integer);
  Function GetTextToSlot(slot:integer):string;
  Procedure TextToSlot(Slot:integer;LText:String);

  Function GetConexIndex(Slot:integer): Tconectiondata;
  Procedure SetConexIndex(Slot: integer; LData:Tconectiondata);
  Procedure SetConexIndexBusy(LSlot:integer;value:Boolean);
  Procedure SetConexIndexLastPing(LSlot:integer;value:string);
  procedure SetConexReserved(LSlot:Integer;Reserved:boolean);
  procedure StartConexThread(LSlot:Integer);

  Procedure UpdateMyData();
  Procedure IncClientReadThreads();
  Procedure DecClientReadThreads();
  Function GetClientReadThreads():integer;

  Procedure AddToIncoming(Index:integer;texto:string);
  Function GetIncoming(Index:integer):String;
  Function LengthIncoming(Index:integer):integer;
  Procedure ClearIncoming(Index:integer);

  Procedure UpdateBotData(IPUser:String);
  Procedure DeleteBots();
  function BotExists(IPUser:String):Boolean;

  Procedure InitializeElements();
  Procedure ClearElements();

CONST
  MaxConecciones   = 99;

var
  // General
  Conexiones       : array [1..MaxConecciones] of Tconectiondata;
  SlotLines        : array [1..MaxConecciones] of TStringList;
  CanalCliente     : array [1..MaxConecciones] of TIdTCPClient;
  ArrayOutgoing    : array [1..MaxConecciones] of array of string;
  BotsList         : array of TBotData;
  // Donwloading files
  DownloadHeaders  : boolean = false;
  DownloadSumary   : Boolean = false;
  DownLoadBlocks   : boolean = false;
  DownLoadGVTs     : boolean = false;
  DownloadPSOs     : boolean = false;
  // Last time files request
  LastTimeMNHashRequestes      : int64 = 0;
  LastTimeBestHashRequested    : int64 = 0;
  LastTimeMNsRequested         : int64 = 0;
  LastTimeChecksRequested      : int64 = 0;
  LastRunMNVerification        : int64 = 0;
  LasTimeGVTsRequest           : int64 = 0;
  LastTimeRequestSumary        : int64 = 0;
  LastTimeRequestBlock         : int64 = 0;
  LastTimeRequestResumen       : int64 = 0;
  LastTimePendingRequested     : int64 = 0;
  LasTimePSOsRequest           : int64 = 0;
  LastBotClear                 : int64 = 0;
  ForceCompleteHeadersDownload : boolean = false;
  // Local data hashes
  MyLastBlock     : integer = 0;
  MyLastBlockHash : String = '';
  MyResumenHash   : String = '';
  //MyGVTsHash      : string = '';
  MyCFGHash       : string = '';
  MyPublicIP      : String = '';
  MyMNsHash       : String = '';
  // Local information
  LastBlockData         : BlockHeaderData;
  OpenReadClientThreads : integer = 0;
  // Critical sections
  CSClientReads         : TRTLCriticalSection;
  CSIncomingArr         : array[1..MaxConecciones] of TRTLCriticalSection;
  CSOutGoingArr         : array[1..MaxConecciones] of TRTLCriticalSection;
  CSConexiones          : TRTLCriticalSection;
  CSBotsList            : TRTLCriticalSection;

IMPLEMENTATION

{$REGION ArrayOutgoing}

Procedure ClearOutTextToSlot(slot:integer);
Begin
  EnterCriticalSection(CSOutGoingArr[slot]);
  SetLength(ArrayOutgoing[slot],0);
  LeaveCriticalSection(CSOutGoingArr[slot]);
End;

Function GetTextToSlot(slot:integer):string;
Begin
  result := '';
  if ( (Slot>=1) and (slot<=MaxConecciones) ) then
    begin
    EnterCriticalSection(CSOutGoingArr[slot]);
    if length(ArrayOutgoing[slot])>0 then
      begin
      result:= ArrayOutgoing[slot][0];
      Delete(ArrayOutgoing[slot],0,1);
      end;
    LeaveCriticalSection(CSOutGoingArr[slot]);
    end;
End;

Procedure TextToSlot(Slot:integer;LText:String);
Begin
  EnterCriticalSection(CSOutGoingArr[slot]);
  Insert(LText,ArrayOutgoing[slot],length(ArrayOutgoing[slot]));
  LeaveCriticalSection(CSOutGoingArr[slot]);
End;

{$ENDREGION ArrayOutgoing}

{$REGION Conexiones control}

Function GetConexIndex(Slot:integer): Tconectiondata;
Begin
  if ( (slot < 1) or (Slot > MaxConecciones) ) then result := Default(Tconectiondata);
  EnterCriticalSection(CSConexiones);
  Result := Conexiones[Slot];
  LeaveCriticalSection(CSConexiones);
End;

Procedure SetConexIndex(Slot: integer; LData:Tconectiondata);
Begin
  EnterCriticalSection(CSConexiones);
  Conexiones[Slot] := LData;
  LeaveCriticalSection(CSConexiones);
End;

Procedure SetConexIndexBusy(LSlot:integer;value:Boolean);
Begin
  EnterCriticalSection(CSConexiones);
  Conexiones[LSlot].IsBusy := value;
  LeaveCriticalSection(CSConexiones);
End;

Procedure SetConexIndexLastPing(LSlot:integer;value:string);
Begin
  EnterCriticalSection(CSConexiones);
  Conexiones[LSlot].lastping := value;
  LeaveCriticalSection(CSConexiones);
End;

procedure SetConexReserved(LSlot:Integer;Reserved:boolean);
var
  ToShow : string = '';
Begin
  if reserved then ToShow := 'RES';
  EnterCriticalSection(CSConexiones);
  Conexiones[LSlot].tipo := ToShow;
  LeaveCriticalSection(CSConexiones);
End;

procedure StartConexThread(LSlot:Integer);
Begin
  EnterCriticalSection(CSConexiones);
  Conexiones[Lslot].Thread := TThreadClientRead.Create(true, Lslot);
  Conexiones[Lslot].Thread.FreeOnTerminate:=true;
  Conexiones[Lslot].Thread.Start;
  LeaveCriticalSection(CSConexiones);
End;

{$ENDREGION Conexiones control}

{$REGION General Data}

// Updates local data hashes
Procedure UpdateMyData();
Begin
  MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
  LastBlockData   := LoadBlockDataHeader(MyLastBlock);
  MyResumenHash   := HashMD5File(ResumenFilename);
  if MyResumenHash = GetConsensus(5) then
    ForceCompleteHeadersDownload := false;
  MyMNsHash       := HashMD5File(MasterNodesFilename);
  MyCFGHash       := Copy(HAshMD5String(GetCFGDataStr),1,5);
End;

{$ENDREGION General Data}

{$REGION Thread Client read}

constructor TThreadClientRead.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
Begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
End;

Function GetStreamFromClient(Slot:integer;out LStream:TMemoryStream):boolean;
Begin
  result := false;
  LStream.Clear;
  TRY
    CanalCliente[Slot].IOHandler.ReadStream(LStream);
    Result := True;
  EXCEPT on E:Exception do
    ToDeepDeb('');
  END;

End;

procedure TThreadClientRead.Execute;
var
  LLine        : String;
  MemStream    : TMemoryStream;
  BlockZipName : string = '';
  OnBuffer     : boolean = true;
  Errored      : Boolean;
  downloaded   : boolean;
  LineToSend   : string;
  LineSent     : boolean;
  KillIt       : boolean = false;
  SavedToFile  : boolean;
  FTPTime      : int64;
  FTPSize      : int64;
  FTPSpeed     : int64;
  ErrMsg       : string;
begin
  CanalCliente[FSlot].ReadTimeout:=1000;
  CanalCliente[FSlot].IOHandler.MaxLineLength:=Maxint;
  AddNewOpenThread('ReadClient '+FSlot.ToString,UTCTime);
  REPEAT
    sleep(10);
    OnBuffer := true;
    if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
      begin
      CanalCliente[FSlot].IOHandler.CheckForDataOnSource(100);
      if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
        begin
        OnBuffer := false;
        REPEAT
          LineToSend := GetTextToSlot(Fslot);
          if LineToSend <> '' then
            begin
            CanalCliente[FSlot].IOHandler.Writeln(LineToSend);
            end;
        UNTIL LineToSend='' ;
        end;
      end;
    if OnBuffer then
      begin
      While not CanalCliente[FSlot].IOHandler.InputBufferIsEmpty do
        begin
        SetConexIndexBusy(FSlot,true);
        SetConexIndexLastPing(fSlot,UTCTimeStr);
        LLine := '';
          TRY
          LLine := CanalCliente[FSlot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
          EXCEPT on E:Exception do
            begin
            ErrMsg := E.Message;
            SetConexIndexBusy(FSlot,false);
            KillIt := true;
            continue;
            end;
          END; {TRY}
        if LLine <> '' then
          begin
          CanalCliente[FSlot].ReadTimeout:=10000;
          if Parameter(LLine,0) = 'RESUMENFILE' then
            begin
            DownloadHeaders := true;
            MemStream := TMemoryStream.Create;
            if GetStreamFromClient(FSlot,MemStream) then SavedToFile := SaveStreamAsHeaders(MemStream)
            else SavedToFile := false;
            if SavedToFile then
              begin
              LastTimeRequestResumen := 0;
              UpdateMyData();
              end
            else killit := true;
            MemStream.Free;
            DownloadHeaders := false;
            end

          else if Parameter(LLine,0) = 'SUMARYFILE' then
            begin
            DownloadSumary := true;
            MemStream := TMemoryStream.Create;
            if GetStreamFromClient(FSlot,MemStream) then SavedToFile := SaveSummaryToFile(MemStream)
            else SavedToFile := false;
            if SavedToFile then
              begin
              UpdateMyData();
              CreateSumaryIndex();
              LastTimeRequestSumary := 0;
              end
            else killit := true;
            MemStream.Free;
            DownloadSumary := false;
            end

          else if Parameter(LLine,0) = 'PSOSFILE' then
            begin
            DownloadPSOs := true;
            MemStream := TMemoryStream.Create;
            if GetStreamFromClient(FSlot,MemStream) then SavedToFile := SavePSOsToFile(MemStream)
            else SavedToFile := false;
            if SavedToFile then
              begin
              LoadPSOFileFromDisk;
              UpdateMyData();
              LasTimePSOsRequest := 0;
              end
            else killit := true;
            MemStream.Free;
            DownloadPSOs := false;
            end

          else if Parameter(LLine,0) = 'GVTSFILE' then
            begin
            DownloadGVTs := true;
            AddFileProcess('Get','GVTFile',CanalCliente[FSlot].Host,GetTickCount64);
            //ToLog('events',TimeToStr(now)+rs0089); //'Receiving GVTs'
            ToLog('console','Receiving GVTs file'); //'Receiving GVTs'
            MemStream := TMemoryStream.Create;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                ToLog('console',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format('Error Receiving GVTs from %s (%s)',[GetConexIndex(fSlot).ip,E.Message])); //'Error Receiving GVTs from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then
              begin
              Errored := false;
              EnterCriticalSection(CSGVTsArray);
                TRY
                MemStream.SaveToFile(GVTsFilename);
                Errored := False;
                EXCEPT on E:Exception do
                  begin
                    Errored := true;
                    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error saving GVTs to file: '+E.Message);
                  end;
                END; {TRY}
              LeaveCriticalSection(CSGVTsArray);
              end;
            if Downloaded and not errored then
              begin
              //ToLog('console','GVTS file downloaded');
              GetGVTsFileData;
              //UpdateMyGVTsList;
              end;
            MemStream.Free;
            DownloadGVTs := false;
            FTPTime := CloseFileProcess('Get','GVTFile',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            //ToLog('nodeftp','Downloaded GVTs from '+CanalCliente[FSlot].Host+' at '+FTPTime.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'BLOCKZIP' then
            begin  // START RECEIVING BLOCKS
            AddFileProcess('Get','Blocks',CanalCliente[FSlot].Host,GetTickCount64);
            //ToLog('events',TimeToStr(now)+rs0006); //'Receiving blocks'
            BlockZipName := BlockDirectory+'blocks.zip';
            TryDeleteFile(BlockZipName);
            MemStream := TMemoryStream.Create;
            DownLoadBlocks := true;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              MemStream.SaveToFile(BlockZipName);
              Errored := false;
              EXCEPT ON E:Exception do
                begin
                //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0007,[conexiones[fSlot].ip,E.Message])); //'Error Receiving blocks from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                Errored := true;
                end;
              END; {TRY}
            If not Errored then
              begin
              if UnzipFile(BlockDirectory+'blocks.zip',true) then
                begin
                MyLastBlock := GetMyLastUpdatedBlock();
                MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
                //ToLog('events',TimeToStr(now)+format(rs0021,[IntToStr(MyLastBlock)])); //'Blocks received up to '+IntToStr(MyLastBlock));
                LastTimeRequestBlock := 0;
                UpdateMyData();
                end;
              end;
            MemStream.Free;
            DownLoadBlocks := false;
            FTPTime := CloseFileProcess('Get','Blocks',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            //ToLog('nodeftp','Downloaded blocks from '+CanalCliente[FSlot].Host+' at '+FTPTime.ToString+' kb/s');
            end // END RECEIVING BLOCKS
          else
            begin
            AddToIncoming(FSlot,LLine);
            end;
          end;
      SetConexIndexBusy(FSlot,false);
      end; // end while client is not empty
    end; // End OnBuffer
  UNTIL ( (terminated) or (not CanalCliente[FSlot].Connected) or (KillIt) );
  DecClientReadThreads;
  CloseOpenThread('ReadClient '+FSlot.ToString);
End;

//Procedure ProcessLine(LLine:String;)

{$ENDREGION Thread Client read}

{$REGION ClientReadThreads}

Procedure IncClientReadThreads();
Begin
  EnterCriticalSection(CSClientReads);
  Inc(OpenReadClientThreads);
  LeaveCriticalSection(CSClientReads);
End;

Procedure DecClientReadThreads();
Begin
  EnterCriticalSection(CSClientReads);
  Dec(OpenReadClientThreads);
  LeaveCriticalSection(CSClientReads);
End;

Function GetClientReadThreads():integer;
Begin
  EnterCriticalSection(CSClientReads);
  Result := OpenReadClientThreads;
  LeaveCriticalSection(CSClientReads);
End;

{$ENDREGION ClientReadThreads}

{$REGION Incoming/outgoing info}

Procedure AddToIncoming(Index:integer;texto:string);
Begin
  EnterCriticalSection(CSIncomingArr[Index]);
  SlotLines[Index].Add(texto);
  LeaveCriticalSection(CSIncomingArr[Index]);
End;

Function GetIncoming(Index:integer):String;
Begin
  result := '';
  if LengthIncoming(Index) > 0 then
    begin
    EnterCriticalSection(CSIncomingArr[Index]);
    result := SlotLines[Index][0];
    SlotLines[index].Delete(0);
    LeaveCriticalSection(CSIncomingArr[Index]);
    end;
End;

Function LengthIncoming(Index:integer):integer;
Begin
  EnterCriticalSection(CSIncomingArr[Index]);
  result := SlotLines[Index].Count;
  LeaveCriticalSection(CSIncomingArr[Index]);
End;

Procedure ClearIncoming(Index:integer);
Begin
  EnterCriticalSection(CSIncomingArr[Index]);
  SlotLines[Index].Clear;
  LeaveCriticalSection(CSIncomingArr[Index]);
End;


{$ENDREGION Incoming/outgoing info}

{$REGION Bots array}

Procedure UpdateBotData(IPUser:String);
var
  contador : integer = 0;
  updated : boolean = false;
Begin
  EnterCriticalSection(CSBotsList);
  for contador := 0 to length(BotsList)-1 do
    begin
    if BotsList[Contador].ip = IPUser then
      begin
      BotsList[Contador].LastRefused:=UTCTime;
      Updated := true;
      end;
    end;
  LeaveCriticalSection(CSBotsList);
  if not updated then
    begin
    EnterCriticalSection(CSBotsList);
    SetLength(BotsList,Length(BotsList)+1);
    BotsList[Length(BotsList)-1].ip:=IPUser;
    BotsList[Length(BotsList)-1].LastRefused:=UTCTime;
    LeaveCriticalSection(CSBotsList);
    end;
End;

Procedure DeleteBots();
Begin
  EnterCriticalSection(CSBotsList);
  SetLength(BotsList,0);
  LeaveCriticalSection(CSBotsList);
  LastBotClear := UTCTime;
End;

function BotExists(IPUser:String):Boolean;
var
  contador : integer = 0;
Begin
  Result := false;
  EnterCriticalSection(CSBotsList);
  for contador := 0 to length(BotsList)-1 do
    if BotsList[contador].ip = IPUser then
      begin
      result := true;
      break;
      end;
  LeaveCriticalSection(CSBotsList);
End;

{$ENDREGION Bots array}

{$REGION Unit related}

Procedure InitializeElements();
var
  counter: integer;
Begin
  InitCriticalSection(CSClientReads);
  InitCriticalSection(CSConexiones);
  InitCriticalSection(CSBotsList);
  SetLength(BotsList,0);
  for counter := 1 to MaxConecciones do
    begin
    InitCriticalSection(CSIncomingArr[counter]);
    SlotLines[counter] := TStringlist.Create;
    CanalCliente[counter] := TIdTCPClient.Create(nil);
    InitCriticalSection(CSOutGoingArr[counter]);
    SetLength(ArrayOutgoing[counter],0);
    end;
End;

Procedure ClearElements();
var
  counter: integer;
Begin
  DoneCriticalSection(CSClientReads);
  DoneCriticalSection(CSConexiones);
  DoneCriticalSection(CSBotsList);
  for counter := 1 to MaxConecciones do
    begin
    DoneCriticalSection(CSIncomingArr[counter]);
    SlotLines[counter].Free;
    CanalCliente[counter].Free;
    DoneCriticalSection(CSOutGoingArr[counter]);
    end;
End;

{$ENDREGION Unit related}

INITIALIZATION
  InitializeElements();


FINALIZATION
  ClearElements;

END. // End unit

