unit NosoNetwork;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, strutils,
  IdContext, IdGlobal, IdTCPClient, IdTCPServer,
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

  TNodeData = Packed Record
     ip           : string[15];
     port         : string[8];
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

  NodeServerEvents = class
    class procedure OnExecute(AContext: TIdContext);
    class procedure OnConnect(AContext: TIdContext);
    class procedure OnDisconnect(AContext: TIdContext);
    class procedure OnException(AContext: TIdContext);
    end;

  Function GetPendingCount():integer;
  Procedure ClearAllPending();
  procedure SendPendingsToPeer(Slot:int64);
  function TranxAlreadyPending(TrxHash:string):boolean;
  function AddArrayPoolTXs(order:TOrderData):boolean;
  function TrxExistsInLastBlock(trfrhash:String):boolean;

  function GetPTCEcn():String;
  function IsValidProtocol(line:String):Boolean;
  function GetPingString():string;
  Function ProtocolLine(LCode:integer):String;
  Procedure ProcessPing(LineaDeTexto: string; Slot: integer; Responder:boolean);
  Procedure ProcessIncomingLine(FSlot:integer;LLine:String);
  Procedure SendMNsListToPeer(slot:integer);
  Procedure SendMNChecksToPeer(Slot:integer);
  Function GetVerificationMNLine(ToIp:String):String;
  Function IsAllSynced():integer;
  Function GetSyncTus():String;

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
  Function IsValidator(Ip:String):boolean;
  Function ValidateMNCheck(Linea:String):string;

  Procedure InitNodeServer();
  function ClientsCount : Integer ;
  Function TryMessageToClient(AContext: TIdContext;message:string):boolean;
  Function GetStreamFromClient(AContext: TIdContext;out LStream:TMemoryStream):boolean;
  Procedure TryCloseServerConnection(AContext: TIdContext; closemsg:string='');


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

  Procedure FillNodeList();
  Function NodesListLen():integer;
  Function NodesIndex(lIndex:integer):TNodeData;

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
  ArrayMultiTXs    : Array of TMultiOrder;
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
  G_MNVerifications            : integer = 0;
  // Local data hashes
  MyLastBlock     : integer = 0;
  MyLastBlockHash : String = '';
  //
  //MyGVTsHash      : string = '';
  //MyCFGHash       : string = '';
  MyPublicIP      : String = '';
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
  // nodes list
  NodesList             : array of TNodeData;
  CSNodesList           : TRTLCriticalSection;
  // Node server
  NodeServer            : TIdTCPServer;

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

function TranxAlreadyPending(TrxHash:string):boolean;
var
  cont : integer;
Begin
  Result := false;
  if GetPendingCount > 0 then
    begin
    EnterCriticalSection(CSPending);
    for cont := 0 to GetPendingCount-1 do
      begin
      if TrxHash = ArrayPoolTXs[cont].TrfrID then
        begin
        result := true;
        break;
        end;
      end;
    LeaveCriticalSection(CSPending);
    end;
End;

// Add a new trx to the pending pool
function AddArrayPoolTXs(order:TOrderData):boolean;
var
  counter    : integer = 0;
  ToInsert   : boolean = false;
  LResult    : integer = 0;
Begin
  BeginPerformance('AddArrayPoolTXs');
  if order.TimeStamp < LastBlockData.TimeStart then exit;
  if TrxExistsInLastBlock(order.TrfrID) then exit;
  if ((BlockAge>585) and (order.TimeStamp < LastBlockData.TimeStart+540) ) then exit;
  if not TranxAlreadyPending(order.TrfrID) then
    begin
    EnterCriticalSection(CSPending);
    while counter < length(ArrayPoolTXs) do
      begin
      if order.TimeStamp < ArrayPoolTXs[counter].TimeStamp then
        begin
        ToInsert := true;
        LResult := counter;
        break;
        end
      else if order.TimeStamp = ArrayPoolTXs[counter].TimeStamp then
        begin
        if order.OrderID < ArrayPoolTXs[counter].OrderID then
          begin
          ToInsert := true;
          LResult := counter;
          break;
          end
        else if order.OrderID = ArrayPoolTXs[counter].OrderID then
          begin
          if order.TrxLine < ArrayPoolTXs[counter].TrxLine then
            begin
            ToInsert := true;
            LResult := counter;
            break;
            end;
          end;
        end;
      Inc(counter);
      end;
    if not ToInsert then LResult := length(ArrayPoolTXs);
    Insert(order,ArrayPoolTXs,LResult);
    LeaveCriticalSection(CSPending);
    result := true;
    //VerifyIfPendingIsMine(order);
    end;
  EndPerformance('AddArrayPoolTXs');
End;

// Check if the TRxID exists in the last block
function TrxExistsInLastBlock(trfrhash:String):boolean;
var
  ArrayLastBlockTrxs : TBlockOrdersArray;
  cont : integer;
Begin
  Result := false;
  ArrayLastBlockTrxs := Default(TBlockOrdersArray);
  ArrayLastBlockTrxs := GetBlockTrxs(MyLastBlock);
  for cont := 0 to length(ArrayLastBlockTrxs)-1 do
    begin
    if ArrayLastBlockTrxs[cont].TrfrID = trfrhash then
      begin
      result := true ;
      break
      end;
    end;
End;

{$ENDREGION Pending Pool transactions}

{$REGION Pending Multi transactions}

{$ENDREGION}

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
         copy(GetMNsHash,0,5)+' '+
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

Procedure SendMNChecksToPeer(Slot:integer);
var
  Counter : integer;
  Texto : string;
Begin
  if GetMNsChecksCount>0 then
    begin
    EnterCriticalSection(CSMNsChecks);
    for counter := 0 to length(ArrMNChecks)-1 do
      begin
      Texto := ProtocolLine(14)+GetStringFromMNCheck(ArrMNChecks[counter]);
      TextToSlot(slot,Texto);
      end;
    LeaveCriticalSection(CSMNsChecks);
    end;
End;

Function GetVerificationMNLine(ToIp:String):String;
Begin
  if IsAllSynced=0 then
    begin
    Result := 'True '+GetSyncTus+' '+LocalMN_Funds+' '+ToIp+' '+LocalMN_Sign;
    Inc(G_MNVerifications);
    end
  else Result := 'False';
End;

Function IsAllSynced():integer;
Begin
  result := 0;
  if MyLastBlock     <> StrToIntDef(GetConsensus(cLastBlock),0) then result := 1;
  if MyLastBlockHash <> GetConsensus(cLBHash) then result := 2;
  if Copy(MySumarioHash,0,5)   <> GetConsensus(cSumHash) then result := 3;
  if Copy(GetResumenHash,0,5)   <> GetConsensus(cHeaders) then result := 4;
  {
  if Copy(GetMNsHash,1,5) <>  NetMNsHash.value then result := 5;
  if MyGVTsHash <> NetGVTSHash.Value then result := 6;
  if MyCFGHash <> NETCFGHash.Value then result := 7;
  }
End;

Function GetSyncTus():String;
Begin
  result := '';
  TRY
    Result := MyLastBlock.ToString+Copy(GetResumenHash,1,3)+Copy(MySumarioHash,1,3)+Copy(MyLastBlockHash,1,3);
  EXCEPT ON E:EXCEPTION do
    begin
    ToDeepDeb('NosoNetwork,GetSyncTus,'+e.Message);
    end;
  END; {TRY}
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
    if IsSlotConnected(Counter) then Inc(result);
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
  //MyMNsHash       := HashMD5File(MasterNodesFilename);
  //MyCFGHash       := Copy(HAshMD5String(GetCFGDataStr),1,5);
End;

Function IsValidator(Ip:String):boolean;
Begin
  result := false;
  if IsSeedNode(IP) then result := true;
End;

// Verify if a validation report is correct
Function ValidateMNCheck(Linea:String):string;
var
  CheckData : TMNCheck;
  StartPos : integer;
  ReportInfo : String;
  ErrorCode : integer = 0;
Begin
  Result := '';
  StartPos := Pos('$',Linea);
  ReportInfo := copy (Linea,StartPos,length(Linea));
  CheckData := GetMNCheckFromString(Linea);
  if MnsCheckExists(CheckData.ValidatorIP) then exit;
  if not IsValidator(CheckData.ValidatorIP) then ErrorCode := 1;
  if CheckData.Block <> MyLastBlock then ErrorCode := 2;
  if GetAddressFromPublicKey(CheckData.PubKey)<>CheckData.SignAddress then ErrorCode := 3;
  if not VerifySignedString(CheckData.ValidNodes,CheckData.Signature,CheckData.PubKey) then ErrorCode := 4;
  if ErrorCode = 0 then
    begin
    Result := ReportInfo;
    AddMNCheck(CheckData);
    //if form1.Server.Active then
    //  outGOingMsjsAdd(GetPTCEcn+ReportInfo);
    end
End;

{$ENDREGION General Data}

{$REGION Node Server}

Procedure InitNodeServer();
Begin
  NodeServer := TIdTCPServer.Create(nil);
  NodeServer.DefaultPort:=8080;
  NodeServer.Active:=false;
  NodeServer.UseNagle:=true;
  NodeServer.TerminateWaitTime:=10000;
  NodeServer.OnExecute:=@NodeServerEvents.OnExecute;
  NodeServer.OnConnect:=@NodeServerEvents.OnConnect;
  NodeServer.OnDisconnect:=@form1.IdTCPServer1Disconnect;
  NodeServer.OnException:=@Form1.IdTCPServer1Exception;
End;

// returns the number of active connections
function ClientsCount : Integer ;
var
  Clients : TList;
Begin
  Clients:= Nodeserver.Contexts.LockList;
    TRY
    Result := Clients.Count ;
    EXCEPT ON E:Exception do
      ToDeepDeb('NosoNetwork,ClientsCount,'+E.Message);
    END; {TRY}
  Nodeserver.Contexts.UnlockList;
End ;

// Try message to client safely
Function TryMessageToClient(AContext: TIdContext;message:string):boolean;
Begin
  result := true;
  TRY
  Acontext.Connection.IOHandler.WriteLn(message);
  EXCEPT on E:Exception do
    begin
    result := false
    end;
  END;{Try}
End;

// Get stream from client
Function GetStreamFromClient(AContext: TIdContext;out LStream:TMemoryStream):boolean;
Begin
  result := false;
  LStream.Clear;
  TRY
    AContext.Connection.IOHandler.ReadStream(LStream);
    Result := True;
  EXCEPT on E:Exception do
    ToDeepDeb('NosoNetwork,GetStreamFromClient,'+E.Message);
  END;
End;

// Trys to close a server connection safely
Procedure TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
Begin
  TRY
  if closemsg <>'' then
    Acontext.Connection.IOHandler.WriteLn(closemsg);
  AContext.Connection.Disconnect();
  Acontext.Connection.IOHandler.InputBuffer.Clear;
  EXCEPT on E:Exception do
    ToDeepDeb('NosoNetwork,TryCloseServerConnection,'+E.Message);
  END; {TRY}
End;

Class Procedure NodeServerEvents.OnExecute(AContext: TIdContext);
var
  LLine : String = '';
  IPUser : String = '';
  slot : integer = 0;
  UpdateZipName : String = ''; UpdateVersion : String = ''; UpdateHash:string ='';
  UpdateClavePublica :string ='';UpdateFirma : string = '';
  MemStream   : TMemoryStream;
  BlockZipName: string = '';
  GetFileOk : boolean = false;
  GoAhead : boolean;
  NextLines : array of string;
  LineToSend : string;
  LinesSent : integer = 0;
  FTPTime, FTPSize, FTPSpeed : int64;
Begin
  {
  GoAhead := true;
  IPUser := AContext.Connection.Socket.Binding.PeerIP;
  slot := GetSlotFromIP(IPUser);
    REPEAT
    LineToSend := GetTextToSlot(slot);
    if LineToSend <> '' then
      begin
      TryMessageToNode(AContext,LineToSend);
      Inc(LinesSent);
      end;
    UNTIL LineToSend='' ;
  if LinesSent >0 then exit;
  if slot = 0 then
    begin
    TryCloseServerConnection(AContext);
    exit;
    end;
  if ( (MyConStatus <3) and (not IsSeedNode(IPUser)) ) then
    begin
    TryCloseServerConnection(AContext,'Closing NODE');
    exit;
    end;
  TRY
  LLine := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
  EXCEPT on E:Exception do
    begin
    TryCloseServerConnection(AContext);
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0045,[IPUser,E.Message]));
    GoAhead := false;
    end;
  END{Try};
  if GoAhead then
    begin
    SetConexIndexBusy(Slot,true);
    if Parameter(LLine,0) = 'RESUMENFILE' then
      begin
      MemStream := TMemoryStream.Create;
      DownloadHeaders := true;
        TRY
        AContext.Connection.IOHandler.ReadStream(MemStream);
        GetFileOk := true;
        EXCEPT ON E:EXCEPTION do
          begin
          TryCloseServerConnection(AContext);
          GetFileOk := false;
          end;
        END; {TRY}
      if GetfileOk then
        begin
        if SaveStreamAsHeaders(MemStream) then
          ToLog('console',Format(rs0047,[copy(HashMD5File(ResumenFilename),1,5)]));//'Headers file received'
        end;
      UpdateMyData();
      LastTimeRequestResumen := 0;
      DownloadHeaders := false;
      MemStream.Free;
      end // END GET RESUMEN FILE
   else if LLine = 'BLOCKZIP' then
     begin
     BlockZipName := BlockDirectory+'blocks.zip';
     TryDeleteFile(BlockZipName);
     MemStream := TMemoryStream.Create;
     DownLoadBlocks := true;
       TRY
       AContext.Connection.IOHandler.ReadStream(MemStream);
       MemStream.SaveToFile(BlockZipName);
       GetFileOk := true;
       EXCEPT ON E:Exception do
         begin
         GetFileOk := false;
         TryCloseServerConnection(AContext);
         end;
       END; {TRY}
       if GetFileOk then
         begin
         if UnzipFile(BlockDirectory+'blocks.zip',true) then
           begin
           MyLastBlock := GetMyLastUpdatedBlock();
           LastTimeRequestBlock := 0;
           ToLog('events',TimeToStr(now)+format(rs0021,[IntToStr(MyLastBlock)])); //'Blocks received up to '+IntToStr(MyLastBlock));
           end
         end;
       MemStream.Free;
       DownLoadBlocks := false;
     end
   else if parameter(LLine,4) = '$GETRESUMEN' then
      begin
      AddFileProcess('Send','Headers',IPUser,GetTickCount64);
      MemStream := TMemoryStream.Create;
      FTPSize := GetHeadersAsMemStream(MemStream);
      if FTPSize>0 then
         begin
            TRY
            Acontext.Connection.IOHandler.WriteLn('RESUMENFILE');
            Acontext.connection.IOHandler.Write(MemStream,0,true);
            EXCEPT on E:Exception do
               begin
               Form1.TryCloseServerConnection(GetConexIndex(Slot).context);
               ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0051,[E.Message]));
               end;
            END; {TRY}
         end;
      MemStream.Free;
      FTPTime := CloseFileProcess('Send','Headers',IPUser,GetTickCount64);
      FTPSpeed := (FTPSize div FTPTime);
      ToLog('nodeftp','Uploaded headers to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
      end
   else if parameter(LLine,4) = '$GETSUMARY' then
      begin
      AddFileProcess('Send','Summary',IPUser,GetTickCount64);
      MemStream := TMemoryStream.Create;
      FTPSize := GetSummaryAsMemStream(MemStream);
      if FTPSize>0 then
         begin
           TRY
           Acontext.Connection.IOHandler.WriteLn('SUMARYFILE');
           Acontext.connection.IOHandler.Write(MemStream,0,true);
           EXCEPT on E:Exception do
           END; {TRY}
         end;
      MemStream.Free;
      FTPTime := CloseFileProcess('Send','Summary',IPUser,GetTickCount64);
      FTPSpeed := (FTPSize div FTPTime);
      ToLog('nodeftp','Uploaded Summary to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
      end
   else if parameter(LLine,4) = '$GETPSOS' then
      begin
      AddFileProcess('Send','PSOs',IPUser,GetTickCount64);
      MemStream := TMemoryStream.Create;
      FTPSize := GetPSOsAsMemStream(MemStream);
      if FTPSize>0 then
         begin
           TRY
           Acontext.Connection.IOHandler.WriteLn('PSOSFILE');
           Acontext.connection.IOHandler.Write(MemStream,0,true);
           EXCEPT on E:Exception do
           END; {TRY}
         end;
      MemStream.Free;
      FTPTime := CloseFileProcess('Send','PSOs',IPUser,GetTickCount64);
      FTPSpeed := (FTPSize div FTPTime);
      ToLog('nodeftp','Uploaded PSOs to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
      end
   else if parameter(LLine,4) = '$LASTBLOCK' then
      begin // START SENDING BLOCKS
      AddFileProcess('Send','Blocks',IPUser,GetTickCount64);
      BlockZipName := CreateZipBlockfile(StrToIntDef(parameter(LLine,5),0));
      if BlockZipName <> '' then
         begin
         MemStream := TMemoryStream.Create;
            TRY
            MemStream.LoadFromFile(BlockZipName);
            GetFileOk := true;
            EXCEPT ON E:Exception do
               begin
               GetFileOk := false;
               end;
            END; {TRY}
         FTPSize := MemStream.Size;
         If GetFileOk then
            begin
               TRY
               Acontext.Connection.IOHandler.WriteLn('BLOCKZIP');
               Acontext.connection.IOHandler.Write(MemStream,0,true);
               ToLog('events',TimeToStr(now)+Format(rs0052,[IPUser,BlockZipName])); //SERVER: BlockZip send to '+IPUser+':'+BlockZipName);
               EXCEPT ON E:Exception do
                  begin
                  Form1.TryCloseServerConnection(GetConexIndex(Slot).context);
                  //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0053,[E.Message])); //'SERVER: Error sending ZIP blocks file ('+E.Message+')');
                  end
               END; {TRY}
            end;
         MemStream.Free;
         FTPTime := CloseFileProcess('Send','Blocks',IPUser,GetTickCount64);
         FTPSpeed := (FTPSize div FTPTime);
         ToLog('nodeftp','Uploaded Blocks to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
         Trydeletefile(BlockZipName); // safe function to delete files
         end
      end // END SENDING BLOCKS

      else if parameter(LLine,4) = '$GETGVTS' then
         begin
         AddFileProcess('Send','GVTs',IPUser,GetTickCount64);
         MemStream := TMemoryStream.Create;
         FTPSize := GetGVTsAsStream(MemStream);
         if FTPSize>0 then
           begin
             TRY
             Acontext.Connection.IOHandler.WriteLn('GVTSFILE');
             Acontext.connection.IOHandler.Write(MemStream,0,true);
             EXCEPT on E:Exception do
             END; {TRY}
           end;
         MemStream.Free;
         FTPTime := CloseFileProcess('Send','GVTs',IPUser,GetTickCount64);
         FTPSpeed := (FTPSize div FTPTime);
         ToLog('nodeftp','Uploaded GVTs to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
         end // SENDING GVTS FILE

      else if parameter(LLine,0) = 'PSOSFILE' then
        begin
        DownloadPSOs := true;
        MemStream := TMemoryStream.Create;
        if GetStreamFromContext(Acontext,MemStream) then
          begin
          if SavePSOsToFile(MemStream) then
            begin
            LoadPSOFileFromDisk;
            UpdateMyData();
            ToLog('console','PSOs file received on server');
            end;
          end;
        MemStream.Free;
        DownloadPSOs := false;
        LasTimePSOsRequest := 0;
        end

   else if AnsiContainsStr(ValidProtocolCommands,Uppercase(parameter(LLine,4))) then
      begin
         TRY
         AddToIncoming(slot,LLine);
         EXCEPT
         On E :Exception do
            ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0054,[E.Message]));
            //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'SERVER: Server error adding received line ('+E.Message+')');
         END; {TRY}
      end
   else
      begin
      TryCloseServerConnection(AContext);
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0055,[LLine]));
      //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'SERVER: Got unexpected line: '+LLine);
      end;
   SetConexIndexBusy(Slot,false);
   end;
  }

  End;

Class Procedure NodeServerEvents.OnConnect(AContext: TIdContext);
  Begin

  End;

Class Procedure NodeServerEvents.OnDisconnect(AContext: TIdContext);
  Begin

  End;

Class Procedure NodeServerEvents.OnException(AContext: TIdContext);
  Begin

  End;

{$ENDREGION Node Server}

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

Function SendLineToClient(FSlot:Integer;LLine:String):boolean;
Begin
  result := true;
  TRY
    CanalCliente[FSlot].IOHandler.Writeln(LLine);
  EXCEPT ON E:EXCEPTION DO
    begin
    Result := false;
    ToDeepDeb('NosoNetwork,SendLineToClient,'+E.Message);
    end;
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
  ThreadName   : string = '';
  LastActive   : int64 = 0;

begin
  ThreadName := 'ReadClient '+FSlot.ToString+' '+UTCTimeStr;
  CanalCliente[FSlot].ReadTimeout:=1000;
  CanalCliente[FSlot].IOHandler.MaxLineLength:=Maxint;
  IncClientReadThreads;
  AddNewOpenThread(ThreadName,UTCTime);
  LastActive := UTCTime;
  REPEAT
  TRY
    sleep(10);
    OnBuffer := true;
    if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
      begin
      CanalCliente[FSlot].IOHandler.CheckForDataOnSource(1000);
      if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
        begin
        OnBuffer := false;
        REPEAT
          LineToSend := GetTextToSlot(Fslot);
          if LineToSend <> '' then
            begin
            if not SendLineToClient(FSlot,LineToSend) then
              begin
              killit := true;
              Conexiones[FSlot].Thread.Terminate;
              break;
              end;
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
          Conexiones[FSlot].Thread.Terminate;
          KillIt := true;
          break;
          end;
        END; {TRY}
        if LLine <> '' then
          begin
          LastActive := UTCTime;
          UpdateOpenThread(ThreadName,UTCTime);
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
    if GetConexIndex(Fslot).tipo <> 'SER' then killit := true;
    if not CanalCliente[FSlot].Connected  then killit := true;
  EXCEPT ON E:Exception do
    begin
    ToDeepDeb('NosoNetwork,TThreadClientRead,'+E.Message);
    KillIt := True;
    end;
  END;
  UNTIL ( (terminated) or (KillIt) );
  CloseSlot(Fslot);
  DecClientReadThreads;
  CloseOpenThread(ThreadName);
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

{$REGION Nodes list}

Procedure FillNodeList();
var
  counter : integer;
  ThisNode : string = '';
  Thisport  : integer;
  continuar : boolean = true;
  NodeToAdd : TNodeData;
  SourceStr : String = '';
Begin
  counter := 0;
  SourceStr := Parameter(GetCFGDataStr,1)+GetVerificatorsText;
  SourceStr := StringReplace(SourceStr,':',' ',[rfReplaceAll, rfIgnoreCase]);
  EnterCriticalSection(CSNodesList);
  SetLength(NodesList,0);
  Repeat
    ThisNode := parameter(SourceStr,counter);
    ThisNode := StringReplace(ThisNode,';',' ',[rfReplaceAll, rfIgnoreCase]);
    ThisPort := StrToIntDef(Parameter(ThisNode,1),8080);
    ThisNode := Parameter(ThisNode,0);
    if thisnode = '' then continuar := false
    else
      begin
      NodeToAdd.ip:=ThisNode;
      NodeToAdd.port:=IntToStr(ThisPort);
      Insert(NodeToAdd,NodesList,Length(NodesList));
      counter+=1;
      end;
  until not continuar;
  LeaveCriticalSection(CSNodesList);
End;

Function NodesListLen():integer;
Begin
  EnterCriticalSection(CSNodesList);
  result := Length(NodesList);
  LeaveCriticalSection(CSNodesList);
End;

Function NodesIndex(lIndex:integer):TNodeData;
Begin
  result := Default(TNodeData);
  if lIndex >=NodesListLen then exit;
  EnterCriticalSection(CSNodesList);
  result := NodesList[lIndex];
  LeaveCriticalSection(CSNodesList);
End;

{$ENDREGION Nodes list}

{$REGION Unit related}

Procedure InitializeElements();
var
  counter: integer;
Begin
  InitCriticalSection(CSClientReads);
  InitCriticalSection(CSConexiones);
  InitCriticalSection(CSBotsList);
  InitCriticalSection(CSPending);
  InitCriticalSection(CSNodesList);
  SetLength(BotsList,0);
  Setlength(ArrayPoolTXs,0);
  SetLength(ArrayMultiTXs,0);
  Setlength(NodesList,0);
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
  DoneCriticalSection(CSNodesList);
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

