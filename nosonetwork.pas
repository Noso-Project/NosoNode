unit NosoNetwork;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, strutils,
  IdContext, IdGlobal, IdTCPClient,
  nosodebug, nosotime, nosogeneral, nosoheaders, nosocrypto, nosoblock,nosoconsensus,
  nosounit,nosonosoCFG,nosogvts,nosomasternodes,nosopsos
  ;

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

  Function GetPendingCount():integer;
  Procedure ClearAllPending();
  procedure SendPendingsToPeer(Slot:int64);

  function GetPTCEcn():String;
  function IsValidProtocol(line:String):Boolean;
  function GetPingString():string;
  Function ProtocolLine(LCode:integer):String;
  Procedure ProcessPing(LineaDeTexto: string; Slot: integer; Responder:boolean);
  Procedure ProcessIncomingLine(FSlot:integer;LLine:String);
  Procedure SendMNsListToPeer(slot:integer);

  Procedure ClearOutTextToSlot(slot:integer);
  Function GetTextToSlot(slot:integer):string;
  Procedure TextToSlot(Slot:integer;LText:String);

  Function GetConexIndex(Slot:integer): Tconectiondata;
  Procedure SetConexIndex(Slot: integer; LData:Tconectiondata);
  Procedure SetConexIndexBusy(LSlot:integer;value:Boolean);
  Procedure SetConexIndexLastPing(LSlot:integer;value:string);
  procedure SetConexReserved(LSlot:Integer;Reserved:boolean);
  procedure StartConexThread(LSlot:Integer);
  Procedure CloseSlot(Slot:integer);
  function GetTotalConexiones():integer;
  Function IsSlotConnected(number:integer):Boolean;

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
  Protocolo        = 2;
  MainnetVersion   = '0.4.2';
var
  // General
  Conexiones       : array [1..MaxConecciones] of Tconectiondata;
  SlotLines        : array [1..MaxConecciones] of TStringList;
  CanalCliente     : array [1..MaxConecciones] of TIdTCPClient;
  ArrayOutgoing    : array [1..MaxConecciones] of array of string;
  BotsList         : array of TBotData;
  ArrayPoolTXs     : Array of TOrderData;
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
  //
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
  CSPending             : TRTLCriticalSection;

IMPLEMENTATION

Uses
  MasterPaskalForm;    // To be removed, only due to server dependancy until it is implemented

{$REGION Pending Pool transactions}

Function GetPendingCount():integer;
Begin
  EnterCriticalSection(CSPending);
  result := Length(ArrayPoolTXs);
  LeaveCriticalSection(CSPending);
End;

// Clear the pending transactions array safely
Procedure ClearAllPending();
Begin
  EnterCriticalSection(CSPending);
  SetLength(ArrayPoolTXs,0);
  LeaveCriticalSection(CSPending);
End;

// Send pending transactions to peer, former PTC_SendPending

procedure SendPendingsToPeer(Slot:int64);
var
  contador : integer;
  Encab : string;
  Textline : String;
  TextOrder : String;
  CopyArrayPoolTXs : Array of TOrderData;
Begin
  Encab := GetPTCEcn;
  TextOrder := encab+'ORDER ';
  if GetPendingCount > 0 then
    begin
    EnterCriticalSection(CSPending);
    SetLength(CopyArrayPoolTXs,0);
    CopyArrayPoolTXs := copy(ArrayPoolTXs,0,length(ArrayPoolTXs));
    LeaveCriticalSection(CSPending);
    for contador := 0 to Length(CopyArrayPoolTXs)-1 do
      begin
      Textline := GetStringFromOrder(CopyArrayPoolTXs[contador]);
      if (CopyArrayPoolTXs[contador].OrderType='CUSTOM') then
        begin
        TextToSlot(slot,Encab+'$'+TextLine);
        end;
      if (CopyArrayPoolTXs[contador].OrderType='TRFR') then
        begin
        if CopyArrayPoolTXs[contador].TrxLine=1 then TextOrder:= TextOrder+IntToStr(CopyArrayPoolTXs[contador].OrderLines)+' ';
        TextOrder := TextOrder+'$'+GetStringfromOrder(CopyArrayPoolTXs[contador])+' ';
        if CopyArrayPoolTXs[contador].OrderLines=CopyArrayPoolTXs[contador].TrxLine then
          begin
          Setlength(TextOrder,length(TextOrder)-1);
          TextToSlot(slot,TextOrder);
          TextOrder := encab+'ORDER ';
          end;
        end;
      if (CopyArrayPoolTXs[contador].OrderType='SNDGVT') then
        begin
        TextToSlot(slot,Encab+'$'+TextLine);
        end;
      end;
    SetLength(CopyArrayPoolTXs,0);
    end;
End;

{$ENDREGION Pending Pool transactions}


{$REGION Protocol}

// Returns protocolo message header
function GetPTCEcn():String;
Begin
  result := 'PSK '+IntToStr(protocolo)+' '+MainnetVersion+NodeRelease+' '+UTCTimeStr+' ';
End;

function IsValidProtocol(line:String):Boolean;
Begin
  if ( (copy(line,1,4) = 'PSK ') or (copy(line,1,4) = 'NOS ') ) then result := true
  else result := false;
End;

function GetPingString():string;
var
  LPort : integer = 0;
Begin
  if Form1.Server.Active then Lport := Form1.Server.DefaultPort else Lport:= -1 ;
  result :=IntToStr(GetTotalConexiones())+' '+ //
         IntToStr(MyLastBlock)+' '+
         MyLastBlockHash+' '+
         MySumarioHash+' '+
         GetPendingCount.ToString+' '+
         GetResumenHash+' '+
         IntToStr(MyConStatus)+' '+
         IntToStr(Lport)+' '+
         copy(MyMNsHash,0,5)+' '+
         IntToStr(GetMNsListLength)+' '+
         'null'+' '+ //GetNMSData.Diff
         GetMNsChecksCount.ToString+' '+
         MyGVTsHash+' '+
         Copy(HashMD5String(GetCFGDataStr),0,5)+' '+
         Copy(PSOFileHash,0,5);
End;

Function ProtocolLine(LCode:integer):String;
var
  Specific      : String = '';
  Header        : String = '';
Begin
  Header := 'PSK '+IntToStr(protocolo)+' '+MainnetVersion+'zzz '+UTCTimeStr+' ';
  if LCode = 0 then Specific := '';                                 //OnlyHeaders
  if LCode = 3 then Specific := '$PING '+GetPingString;             //Ping
  if LCode = 4 then Specific := '$PONG '+GetPingString;             //Pong
  if LCode = 5 then Specific := '$GETPENDING';                      //GetPending
  if LCode = 6 then Specific := '$GETSUMARY';                       //GetSumary
  if LCode = 7 then Specific := '$GETRESUMEN';                      //GetResumen
  if LCode = 8 then Specific := '$LASTBLOCK '+IntToStr(mylastblock);//LastBlock
  if LCode = 9 then Specific := '$CUSTOM ';                        //Custom
  if LCode = 11 then Specific := '$GETMNS';                         //GetMNs
  if LCode = 12 then Specific := '$BESTHASH';                       //BestHash
  if LCode = 13 then Specific := '$MNREPO '+GetMNReportString(MyLastBlock);      //MNReport
  if LCode = 14 then Specific := '$MNCHECK ';                       //MNCheck
  if LCode = 15 then Specific := '$GETCHECKS';                      //GetChecks
  if LCode = 16 then Specific := 'GETMNSFILE';                      //GetMNsFile
  if LCode = 17 then Specific := 'MNFILE';                              //MNFile
  if LCode = 18 then Specific := 'GETHEADUPDATE '+MyLastBlock.ToString; //GetHeadUpdate
  if LCode = 19 then Specific := 'HEADUPDATE';                      //HeadUpdate
  if LCode = 20 then Specific := '$GETGVTS';                        //GetGVTs
  if LCode = 21 then Specific := '$SNDGVT ';
  if LCode = 30 then Specific := 'GETCFGDATA';                      //GetCFG
  if LCode = 31 then Specific := 'SETCFGDATA $';                    //SETCFG
  if LCode = 32 then Specific := '$GETPSOS';                        //GetPSOs
Result := Header+Specific;
End;

Procedure ProcessPing(LineaDeTexto: string; Slot: integer; Responder:boolean);
var
  NewData : Tconectiondata;
Begin
  NewData               := GetConexIndex(Slot);
  NewData.Autentic      := true;
  NewData.Protocol      := StrToIntDef(Parameter(LineaDeTexto,1),0);
  NewData.Version       := Parameter(LineaDeTexto,2);
  NewData.offset        := StrToInt64Def(Parameter(LineaDeTexto,3),UTCTime)-UTCTime;
  NewData.Connections   := StrToIntDef(Parameter(LineaDeTexto,5),0);
  NewData.Lastblock     := Parameter(LineaDeTexto,6);
  NewData.LastblockHash := Parameter(LineaDeTexto,7);
  NewData.SumarioHash   := Parameter(LineaDeTexto,8);
  NewData.Pending       := StrToIntDef(Parameter(LineaDeTexto,9),0);
  NewData.ResumenHash   := Parameter(LineaDeTexto,10);
  NewData.ConexStatus   := StrToIntDef(Parameter(LineaDeTexto,11),0);
  NewData.ListeningPort := StrToIntDef(Parameter(LineaDeTexto,12),-1);
  NewData.MNsHash       := Parameter(LineaDeTexto,13);
  NewData.MNsCount      := StrToIntDef(Parameter(LineaDeTexto,14),0);
  NewData.BestHashDiff  := 'null'{15};
  NewData.MNChecksCount := StrToIntDef(Parameter(LineaDeTexto,16),0);
  NewData.lastping      := UTCTimeStr;
  NewData.GVTsHash      := Parameter(LineaDeTexto,17);
  NewData.CFGHash       := Parameter(LineaDeTexto,18);
  NewData.PSOHash       := Parameter(LineaDeTexto,19);;
  NewData.MerkleHash    := HashMD5String(NewData.Lastblock+copy(NewData.ResumenHash,0,5)+copy(NewData.MNsHash,0,5)+
                                copy(NewData.LastblockHash,0,5)+copy(NewData.SumarioHash,0,5)+
                                copy(NewData.GVTsHash,0,5)+copy(NewData.CFGHash,0,5));
  SetConexIndex(Slot,NewData);
  if responder then
    begin
    TextToSlot(slot,ProtocolLine(4));
    end;
End;

Procedure ProcessIncomingLine(FSlot:integer;LLine:String);
var
  Protocol, PeerVersion, PeerTime, Command : string;
Begin
  Protocol    := Parameter(LLine,1);
  PeerVersion := Parameter(LLine,2);
  PeerTime    := Parameter(LLine,3);
  Command     := ProCommand(LLine);
  if ((not IsValidProtocol(LLine)) and (not GetConexIndex(FSlot).Autentic)) then
    begin
    UpdateBotData(GetConexIndex(Fslot).ip);
    CloseSlot(FSlot);
    end
  else if UpperCase(LLine) = 'DUPLICATED' then CloseSlot(FSlot)
  else if Copy(UpperCase(LLine),1,10) = 'OLDVERSION' then CloseSlot(FSlot)
  else if Command = '$PING' then ProcessPing(LLine,FSlot,true)
  else if Command = '$PONG' then ProcessPing(LLine,FSlot,false)
  else if Command = '$GETPENDING' then SendPendingsToPeer(FSlot)
End;

Procedure SendMNsListToPeer(slot:integer);
var
  DataArray : array of string;
  counter   : integer;
Begin
  if FillMnsListArray(DataArray) then
    begin
    for counter := 0 to length(DataArray)-1 do
      TextToSlot(slot,GetPTCEcn+'$MNREPO '+DataArray[counter]);
    end;
End;

{$ENDREGION Protocol}

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
  if ( (Slot >= 1) and (Slot <=99) ) then
    begin
    EnterCriticalSection(CSOutGoingArr[slot]);
    Insert(LText,ArrayOutgoing[slot],length(ArrayOutgoing[slot]));
    LeaveCriticalSection(CSOutGoingArr[slot]);
    end;
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
  if ( (slot < 1) or (Slot > MaxConecciones) ) then exit;
  EnterCriticalSection(CSConexiones);
  Conexiones[Slot] := LData;
  LeaveCriticalSection(CSConexiones);
End;

Procedure SetConexIndexBusy(LSlot:integer;value:Boolean);
Begin
  if ( (Lslot < 1) or (LSlot > MaxConecciones) ) then exit;
  EnterCriticalSection(CSConexiones);
  Conexiones[LSlot].IsBusy := value;
  LeaveCriticalSection(CSConexiones);
End;

Procedure SetConexIndexLastPing(LSlot:integer;value:string);
Begin
  if ( (Lslot < 1) or (LSlot > MaxConecciones) ) then exit;
  EnterCriticalSection(CSConexiones);
  Conexiones[LSlot].lastping := value;
  LeaveCriticalSection(CSConexiones);
End;

procedure SetConexReserved(LSlot:Integer;Reserved:boolean);
var
  ToShow : string = '';
Begin
  if ( (Lslot < 1) or (LSlot > MaxConecciones) ) then exit;
  if reserved then ToShow := 'RES';
  EnterCriticalSection(CSConexiones);
  Conexiones[LSlot].tipo := ToShow;
  LeaveCriticalSection(CSConexiones);
End;

procedure StartConexThread(LSlot:Integer);
Begin
  if ( (Lslot < 1) or (LSlot > MaxConecciones) ) then exit;
  EnterCriticalSection(CSConexiones);
  Conexiones[Lslot].Thread := TThreadClientRead.Create(true, Lslot);
  Conexiones[Lslot].Thread.FreeOnTerminate:=true;
  Conexiones[Lslot].Thread.Start;
  LeaveCriticalSection(CSConexiones);
End;

Procedure CloseSlot(Slot:integer);
Begin
  if ( (slot < 1) or (Slot > MaxConecciones) ) then exit;
  BeginPerformance('CloseSlot');
    TRY
    if GetConexIndex(Slot).tipo='CLI' then
      begin
      ClearIncoming(slot);
      GetConexIndex(Slot).context.Connection.Disconnect;
      Sleep(10);
      end;
    if GetConexIndex(Slot).tipo='SER' then
      begin
      If Assigned(Conexiones[Slot].Thread) then
        Conexiones[Slot].Thread.Terminate;
      ClearIncoming(slot);
      CanalCliente[Slot].IOHandler.InputBuffer.Clear;
      CanalCliente[Slot].Disconnect;
      end;
    EXCEPT on E:Exception do
      ToDeepDeb('NosoNetwork,CloseSlot,'+E.Message);
    END;{Try}
  SetConexIndex(Slot,Default(Tconectiondata));
  EndPerformance('CloseSlot');
End;

function GetTotalConexiones():integer;
var
  counter:integer;
Begin
  BeginPerformance('GetTotalConexiones');
  result := 0;
  for counter := 1 to MaxConecciones do
    if IsSlotConnected(Counter) then result := result + 1;
  EndPerformance('GetTotalConexiones');
End;

Function IsSlotConnected(number:integer):Boolean;
Begin
  result := false;
  if ( (number < 1) or (number > MaxConecciones) ) then exit;
  if ((GetConexIndex(number).tipo = 'SER') or (GetConexIndex(number).tipo = 'CLI')) then result := true;
End;

{$ENDREGION Conexiones control}

{$REGION General Data}

// Updates local data hashes
Procedure UpdateMyData();
Begin
  MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
  LastBlockData   := LoadBlockDataHeader(MyLastBlock);
  SetResumenHash;
  if GetResumenHash = GetConsensus(5) then
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

Function LineToClient(Slot:Integer;LLine:String):boolean;
Begin
  Result := false;
  TRY
    CanalCliente[Slot].IOHandler.WriteLn(LLine);
    Result := true;
  EXCEPT on E:Exception do
    ToDeepDeb('NosoNetwork,LineToClient,'+E.Message);
  END;
End;

Function GetStreamFromClient(Slot:integer;out LStream:TMemoryStream):boolean;
Begin
  result := false;
  LStream.Clear;
  TRY
    CanalCliente[Slot].IOHandler.ReadStream(LStream);
    Result := True;
  EXCEPT on E:Exception do
    ToDeepDeb('NosoNetwork,GetStreamFromClient,'+E.Message);
  END;
End;

procedure TThreadClientRead.Execute;
var
  LLine        : String;
  MemStream    : TMemoryStream;
  OnBuffer     : boolean = true;
  Errored      : Boolean;
  downloaded   : boolean;
  LineToSend   : string;
  KillIt       : boolean = false;
  SavedToFile  : boolean;
  LastActive   : int64 = 0;
begin
  CanalCliente[FSlot].ReadTimeout:=1000;
  CanalCliente[FSlot].IOHandler.MaxLineLength:=Maxint;
  IncClientReadThreads;
  AddNewOpenThread('ReadClient '+FSlot.ToString,UTCTime);
  LastActive := UTCTime;
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
          SetConexIndexBusy(FSlot,false);
          KillIt := true;
          continue;
          end;
        END; {TRY}
        if LLine <> '' then
          begin
          LastActive := UTCTime;
          CanalCliente[FSlot].ReadTimeout:=10000;
          if Parameter(LLine,0) = 'RESUMENFILE' then
            begin
            DownloadHeaders := true;
            MemStream := TMemoryStream.Create;
            if GetStreamFromClient(FSlot,MemStream) then SavedToFile := SaveStreamAsHeaders(MemStream)
            else SavedToFile := false;
            if SavedToFile then
              begin
              UpdateMyData();
              end
            else killit := true;
            LastTimeRequestResumen := 0;
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
              end
            else killit := true;
            LastTimeRequestSumary := 0;
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
              end
            else killit := true;
            LasTimePSOsRequest := 0;
            MemStream.Free;
            DownloadPSOs := false;
            end

          else if Parameter(LLine,0) = 'GVTSFILE' then
            begin
            DownloadGVTs := true;
            MemStream := TMemoryStream.Create;
            if GetStreamFromClient(FSlot,MemStream) then SavedToFile := SaveStreamAsGVTs(MemStream)
            else SavedToFile := false;
            if SavedToFile then
              begin
              GetGVTsFileData;
              end
            else killit := true;
            LasTimeGVTsRequest := 0;
            MemStream.Free;
            DownloadGVTs := false;
            end

          else if Parameter(LLine,0) = 'BLOCKZIP' then
            begin
            DownLoadBlocks := true;
            MemStream := TMemoryStream.Create;
            if GetStreamFromClient(FSlot,MemStream) then SavedToFile := SaveStreamAsZipBlocks(MemStream)
            else SavedToFile := false;
            if SavedToFile then
              begin
              if UnzipFile(BlockDirectory+'blocks.zip',true) then
                begin
                MyLastBlock := GetMyLastUpdatedBlock();
                MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
                UpdateMyData();
                end;
              end
            else killit := true;
            LastTimeRequestBlock := 0;
            MemStream.Free;
            DownLoadBlocks := false;
            end // END RECEIVING BLOCKS
          else
            begin
            //ProcessIncomingLine(FSlot,LLine);
            AddToIncoming(FSlot,LLine);
            end;
          end;
      SetConexIndexBusy(FSlot,false);
      end; // end while client is not empty
    end; // End OnBuffer
    if LastActive + 30 < UTCTime then killit := true;
  UNTIL ( (terminated) or (Conexiones[Fslot].tipo='') or  (not CanalCliente[FSlot].Connected) or (KillIt) );
  CloseSlot(Fslot);
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
  InitCriticalSection(CSPending);
  SetLength(BotsList,0);
  Setlength(ArrayPoolTXs,0);
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
  DoneCriticalSection(CSPending);
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

