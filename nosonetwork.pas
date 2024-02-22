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

  conectiondata = Packed Record
    Autentic: boolean;                 // si la conexion esta autenticada por un ping
    Connections : Integer;             // A cuantos pares esta conectado
    tipo: string[8];                   // Tipo: SER o CLI
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

  Procedure UpdateMyData();

CONST
  MaxConecciones   = 99;

var
  // General
  Conexiones       : array [1..MaxConecciones] of conectiondata;
  SlotLines        : array [1..MaxConecciones] of TStringList;
  CanalCliente     : array [1..MaxConecciones] of TIdTCPClient;
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
  ForceCompleteHeadersDownload : boolean = false;
  // Local data hashes
  MyLastBlock     : integer = 0;
  MyLastBlockHash : String = '';
  MyResumenHash   : String = '';
  MyGVTsHash      : string = '';
  MyCFGHash       : string = '';
  MyPublicIP      : String = '';
  MyMNsHash       : String = '';
  // Local information
  LastBlockData   : BlockHeaderData;


IMPLEMENTATION

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

procedure TThreadClientRead.Execute;
var
  LLine: String;
  MemStream    : TMemoryStream;
  BlockZipName : string = '';
  Continuar    : boolean = true;
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
  AddNewOpenThread('ReadClient '+FSlot.ToString,UTCTime);
  REPEAT
    TRY
    sleep(10);
    continuar := true;
    if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
      begin
      CanalCliente[FSlot].IOHandler.CheckForDataOnSource(1000);
      if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then Continuar := false;
      end;
    if Continuar then
      begin
      While not CanalCliente[FSlot].IOHandler.InputBufferIsEmpty do
        begin
        Conexiones[fSlot].IsBusy:=true;
        Conexiones[fSlot].lastping:=UTCTimeStr;
          TRY
          CanalCliente[FSlot].ReadTimeout:=1000;
          CanalCliente[FSlot].IOHandler.MaxLineLength:=Maxint;
          LLine := CanalCliente[FSlot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
          EXCEPT on E:Exception do
            begin
            ErrMsg := E.Message;
            ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format('Error Reading lines from slot: %s',[IntToStr(Fslot)+slinebreak+ErrMsg]));
            Conexiones[fSlot].IsBusy:=false;
            if AnsiContainsStr(Uppercase(ErrMsg),'SOCKET ERROR') then
              begin
              KillIt := true;
              ToLog('console',Format('Socket error: ',[ErrMsg]));
              end;
            continue;
            end;
          END; {TRY}
        if continuar then
          begin
          if Parameter(LLine,0) = 'RESUMENFILE' then
            begin
            DownloadHeaders := true;
            AddFileProcess('Get','Headers',CanalCliente[FSlot].Host,GetTickCount64);
            //ToLog('events',TimeToStr(now)+'Receiving headers'); //'Receiving headers'
            //ToLog('console',rs0003); //'Receiving headers'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0004,[conexiones[fSlot].ip,E.Message])); //'Error Receiving headers from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then SavedToFile := SaveStreamAsHeaders(MemStream)
            else SavedToFile := false;
            if ((Downloaded) and (SavedToFile)) then
              begin
              //ToLog('console',format(rs0005,[copy(HashMD5File(ResumenFilename),1,5)])); //'Headers file received'
              LastTimeRequestResumen := 0;
              UpdateMyData();
              end
            else ToLog('console','Error downloading headers: downloaded: '+booltostr(Downloaded,true)+' / Saved: '+booltostr(SavedToFile,true));
            MemStream.Free;
            DownloadHeaders := false;
            FTPTime := CloseFileProcess('Get','Headers',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded headers from '+CanalCliente[FSlot].Host+' at '+FTPSpeed.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'SUMARYFILE' then
            begin
            DownloadSumary := true;
            AddFileProcess('Get','Summary',CanalCliente[FSlot].Host,GetTickCount64);
            //ToLog('console',rs0085); //'Receiving sumary'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0086,[conexiones[fSlot].ip,E.Message])); //'Error Receiving sumary from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then SavedToFile := SaveSummaryToFile(MemStream);
            if ((Downloaded) and (SavedToFile)) then
              begin
              //ToLog('console',format(rs0087,[copy(HashMD5File(SummaryFileName),1,5)])); //'Sumary file received'
              UpdateMyData();
              CreateSumaryIndex();
              //UpdateWalletFromSumario;
              LastTimeRequestSumary := 0;
              end;
            MemStream.Free;
            DownloadSumary := false;
            FTPTime := CloseFileProcess('Get','Summary',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded summary from '+CanalCliente[FSlot].Host+' at '+FTPSpeed.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'PSOSFILE' then
            begin
            DownloadPSOs := true;
            AddFileProcess('Get','PSOs',CanalCliente[FSlot].Host,GetTickCount64);
            ToLog('console','Receiving PSOs'); //'Receiving psos'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0092,[conexiones[fSlot].ip,E.Message])); //'Error Receiving sumary from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then SavedToFile := SavePSOsToFile(MemStream);
            if Downloaded and SavedToFile then
              begin
              //ToLog('console',format(rs0093,[copy(HashMD5File(PSOsFileName),1,5)])); //'PSOs file received'
              LoadPSOFileFromDisk;
              UpdateMyData();
              LasTimePSOsRequest := 0;
              end;
            MemStream.Free;
            DownloadPSOs := false;
            FTPTime := CloseFileProcess('Get','PSOs',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded PSOs from '+CanalCliente[FSlot].Host+' at '+FTPSpeed.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'GVTSFILE' then
            begin
            DownloadGVTs := true;
            AddFileProcess('Get','GVTFile',CanalCliente[FSlot].Host,GetTickCount64);
            //ToLog('events',TimeToStr(now)+rs0089); //'Receiving GVTs'
            //ToLog('console',rs0089); //'Receiving GVTs'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0090,[conexiones[fSlot].ip,E.Message])); //'Error Receiving GVTs from
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
              ToLog('console','GVTS file downloaded');
              GetGVTsFileData;
              UpdateMyGVTsList;
              end;
            MemStream.Free;
            DownloadGVTs := false;
            FTPTime := CloseFileProcess('Get','GVTFile',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded GVTs from '+CanalCliente[FSlot].Host+' at '+FTPTime.ToString+' kb/s');
            end

          else if LLine = 'BLOCKZIP' then
            begin  // START RECEIVING BLOCKS
            AddFileProcess('Get','Blocks',CanalCliente[FSlot].Host,GetTickCount64);
            //ToLog('events',TimeToStr(now)+rs0006); //'Receiving blocks'
            BlockZipName := BlockDirectory+'blocks.zip';
            TryDeleteFile(BlockZipName);
            MemStream := TMemoryStream.Create;
            DownLoadBlocks := true;
            CanalCliente[FSlot].ReadTimeout:=10000;
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
              if UnzipBlockFile(BlockDirectory+'blocks.zip',true) then
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
            ToLog('nodeftp','Downloaded blocks from '+CanalCliente[FSlot].Host+' at '+FTPTime.ToString+' kb/s');
            end // END RECEIVING BLOCKS
        else
          begin
          AddToIncoming(FSlot,LLine);
          end;
        end;
      Conexiones[fSlot].IsBusy:=false;
      end; // end while client is not empty
    end; // End if continuar

    EXCEPT ON E:Exception do
      begin
      ErrMsg := E.Message;
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'*****CRITICAL**** Error inside Client thread: '+ErrMsg);
      KillIt := true;
      end;
    END; {TRY}
  UNTIL ( (terminated) or (not CanalCliente[FSlot].Connected) or (KillIt) );
  DecClientReadThreads;
  CloseOpenThread('ReadClient '+FSlot.ToString);
End;

{$ENDREGION Thread Client read}

INITIALIZATION

FINALIZATION

END. // End unit

