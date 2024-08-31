unit mpRed;

{$mode objfpc}{$H+}

interface

uses
  Classes, forms, SysUtils, MasterPaskalForm, nosotime, IdContext, IdGlobal, mpGUI, mpDisk,
  mpBlock, fileutil, graphics,  dialogs, strutils, mpcoin, fphttpclient,
  opensslsockets,translation, IdHTTP, IdComponent, IdSSLOpenSSL, IdTCPClient,
  nosodebug,nosogeneral, nosocrypto, nosounit, nosoconsensus, nosopsos,nosowallcon,
  nosoheaders, nosoblock, nosonosocfg,nosonetwork,nosogvts,nosomasternodes;

function GetSlotFromIP(Ip:String):int64;
function GetSlotFromContext(Context:TidContext):int64;
//function BotExists(IPUser:String):Boolean;
//function NodeExists(IPUser,Port:String):integer;
function SaveConection(tipo,ipuser:String;contextdata:TIdContext;toSlot:integer=-1):integer;
Procedure ForceServer();
procedure StartServer();
function StopServer():boolean;
//procedure CloseSlot(Slot:integer);
Function IsSlotFree(number:integer):Boolean;
//Function IsSlotConnected(number:integer):Boolean;
function GetFreeSlot():integer;
function ReserveSlot():integer;
function ConnectClient(Address,Port:String):integer;
//function GetTotalConexiones():integer;
//function GetTotalVerifiedConnections():Integer;
function GetTotalSyncedConnections():Integer;
function CerrarClientes(ServerToo:Boolean=True):string;
Procedure LeerLineasDeClientes();
Procedure VerifyConnectionStatus();
//Function IsAllSynced():integer;
//Procedure UpdateMyData();
Procedure SyncWithMainnet();
function GetOutGoingConnections():integer;
function GetIncomingConnections():integer;
Function GetSeedConnections():integer;
Function GetValidSlotForSeed(out Slot:integer):boolean;
function GetOrderDetails(orderid:string):TOrderGroup;
function GetOrderSources(orderid:string):string;
Function GetNodeStatusString():string;
Function IsSafeIP(IP:String):boolean;
Function GetLastRelease():String;
Function GetRepoFile(LurL:String):String;
Function GetOS():string;
Function GetLastVerZipFile(version,LocalOS:string):boolean;
//Function GetSyncTus():String;
function GetMiIP():String;
Function NodeServerInfo():String;
Procedure ClearReceivedOrdersIDs();
function SendOrderToNode(OrderString:String):String;

implementation

Uses
  mpParser, mpProtocol;

// RETURNS THE SLOT OF THE GIVEN IP
function GetSlotFromIP(Ip:String):int64;
var
  contador : integer;
Begin
Result := 0;
for contador := 1 to MaxConecciones do
   begin
   if GetConexIndex(contador).ip=ip then
      begin
      result := contador;
      break;
      end;
   end;
end;

// RETURNS THE SLOT OF THE GIVEN CONTEXT
function GetSlotFromContext(Context:TidContext):int64;
var
  contador : integer;
Begin
Result := 0;
for contador := 1 to MaxConecciones do
   begin
   if GetConexIndex(contador).context=Context then
      begin
      result := contador;
      break;
      end;
   end;
end;

{
// Devuelve si un bot existe o no en la base de datos
function BotExists(IPUser:String):Boolean;
var
  contador : integer = 0;
Begin
Result := false;
for contador := 0 to length(ListadoBots)-1 do
   if ListadoBots[contador].ip = IPUser then result := true;
End;
}

{
// Devuelve si un Nodo existe o no en la base de datos
function NodeExists(IPUser,Port:String):integer;
var
  contador : integer = 0;
Begin
  Result := -1;
  for contador := 0 to length(ListadoBots)-1 do
    if ((ListaNodos[contador].ip = IPUser) and (ListaNodos[contador].port = port)) then result := contador;
End;
}
// Almacena una conexion con sus datos en el array Conexiones
function SaveConection(tipo,ipuser:String;contextdata:TIdContext;toSlot:integer=-1):integer;
var
  counter   : integer = 1;
  Slot       : int64 = 0;
  FoundSlot  : boolean = false;
  NewValue   : Tconectiondata;
begin
  NewValue := Default(Tconectiondata);
  NewValue.Autentic:=false;
  NewValue.Connections:=0;
  NewValue.tipo := tipo;
  NewValue.ip:= ipuser;
  NewValue.lastping:=UTCTimeStr;
  NewValue.context:=contextdata;
  NewValue.Lastblock:='0';
  NewValue.LastblockHash:='';
  NewValue.SumarioHash:='';
  NewValue.ListeningPort:=-1;
  NewValue.Pending:=0;
  NewValue.ResumenHash:='';
  NewValue.ConexStatus:=0;
  if ToSLot<0 then
    begin
    For counter := 1 to MaxConecciones do
      begin
      if GetConexIndex(counter).tipo = '' then
        begin
        SetConexIndex(counter,NewValue);
        ClearIncoming(counter);
        FoundSlot := true;
        result := counter;
        break;
        end;
      end;
    if not FoundSlot then Result := 0;
    end
  else
    begin
    SetConexIndex(toSlot,NewValue);
    ClearIncoming(ToSLot);
    result := ToSLot;
    end;
end;

Procedure ForceServer();
var
  PortNumber : integer;
Begin
KeepServerOn := true;
PortNumber := StrToIntDef(LocalMN_Port,8080);
if Form1.Server.Active then
   begin
   ToLog('console','Server Already active'); //'Server Already active'
   end
else
   begin
      TRY
      LastTryServerOn := UTCTime;
      Form1.Server.Bindings.Clear;
      Form1.Server.DefaultPort:=PortNumber;
      Form1.Server.Active:=true;
      ToLog('console','Server ENABLED. Listening on port '+PortNumber.ToString);   //Server ENABLED. Listening on port
      ServerStartTime := UTCTime;
      U_DataPanel := true;
      EXCEPT on E : Exception do
        ToLog('events',TimeToStr(now)+'Unable to start Server');       //Unable to start Server
      END; {TRY}
   end;
End;

// Activa el servidor
procedure StartServer();
var
  PortNumber : integer;
Begin
PortNumber := StrToIntDef(LocalMN_Port,8080);
if WallAddIndex(LocalMN_Sign)<0 then
   begin
   ToLog('console',rs2000); //Sign address not valid
   exit;
   end;
if MyConStatus < 3 then // rs2001 = 'Wallet not updated';
   begin
   ToLog('console',rs2001);
   exit;
   end;
KeepServerOn := true;
if Form1.Server.Active then
   begin
   ToLog('console','Server Already active'); //'Server Already active'
   end
else
   begin
      try
      LastTryServerOn := UTCTime;
      Form1.Server.Bindings.Clear;
      Form1.Server.DefaultPort:=PortNumber;
      Form1.Server.Active:=true;
      ToLog('console','Server ENABLED. Listening on port '+PortNumber.ToString);   //Server ENABLED. Listening on port
      ServerStartTime := UTCTime;
      U_DataPanel := true;
      except
      on E : Exception do
        ToLog('events',TimeToStr(now)+'Unable to start Server: '+e.Message);       //Unable to start Server
      end;
   end;
End;

// Apaga el servidor
function StopServer():boolean;
var
  Contador: integer;
Begin
result := true;
if not Form1.Server.Active then exit;
KeepServerOn := false;
   TRY
   Form1.Server.Active:=false;
   U_DataPanel := true;
   EXCEPT on E:Exception do
      begin
      result := false;
      end;
   END{Try};
end;

{
// Cierra la conexion del slot especificado
Procedure CloseSlot(Slot:integer);
Begin
  BeginPerformance('CloseSlot');
  TRY
  if GetConexIndex(Slot).tipo='CLI' then
    begin
    ClearIncoming(slot);
    GetConexIndex(Slot).context.Connection.Disconnect;
    Sleep(10);
    //Conexiones[Slot].Thread.terminate; // free ? WaitFor??
    end;
  if GetConexIndex(Slot).tipo='SER' then
    begin
    ClearIncoming(slot);
    CanalCliente[Slot].IOHandler.InputBuffer.Clear;
    CanalCliente[Slot].Disconnect;
    end;
  EXCEPT on E:Exception do
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error: Closing slot '+IntToStr(Slot)+SLINEBREAK+E.Message);
  END;{Try}
  SetConexIndex(Slot,Default(Tconectiondata));
  EndPerformance('CloseSlot');
End;
}

Function IsSlotFree(number:integer):Boolean;
Begin
  result := true;
  if GetConexIndex(number).tipo <> '' then result := false;
End;

{
Function IsSlotConnected(number:integer):Boolean;
Begin
  result := false;
  if ((GetConexIndex(number).tipo = 'SER') or (GetConexIndex(number).tipo = 'CLI')) then result := true;
End;
}

// Returns first available slot
function GetFreeSlot():integer;
var
  contador : integer = 1;
Begin
result := 0;
for contador := 1 to MaxConecciones do
   begin
   if IsSlotFree(Contador) then
      begin
      result := contador;
      break;
      end;
   end;
End;

// Reserves the first available slot
function ReserveSlot():integer;
var
  contador : integer = 1;
Begin
  result := 0;
  for contador := 1 to MaxConecciones do
    begin
    if IsSlotFree(Contador) then
      begin
      SetConexReserved(contador,True);
      result := contador;
      break;
      end;
    end;
End;

// Reserves the first available slot
Procedure UnReserveSlot(number:integer);
Begin
  if GetConexIndex(number).tipo ='RES' then
    begin
    SetConexReserved(number,False);
    CloseSlot(Number);
    end
  else
    begin
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error un-reserving slot '+number.ToString);
    end;
End;

// Connects a client and returns the slot
function ConnectClient(Address,Port:String):integer;
var
  Slot : integer = 0;
  ConContext : TIdContext; // EMPTY
  Errored : boolean = false;
  SavedSlot : integer;
  ConnectOk : boolean = false;
Begin
  result := 0;
  ConContext := Default(TIdContext);
  Slot := ReserveSlot();
  if Slot = 0 then exit;  // No free slots
  CanalCliente[Slot].Host:=Address;
  CanalCliente[Slot].Port:=StrToIntDef(Port,8080);
  CanalCliente[Slot].ConnectTimeout:= 1000;
  ClearOutTextToSlot(slot);
    TRY
    CanalCliente[Slot].Connect;
    ConnectOk := true;
    EXCEPT on E:Exception do
      begin
      ConnectOk := False;
      end;
    END;{TRY}
  if connectok then
    begin
    SavedSlot := SaveConection('SER',Address,ConContext,slot);
    ToLog('events',TimeToStr(now)+'Connected TO: '+Address);          //Connected TO:
    StartConexThread(Slot);
    result := Slot;
      TRY
      CanalCliente[Slot].IOHandler.WriteLn('PSK '+Address+' '+MainnetVersion+NodeRelease+' '+UTCTimeStr);
      CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(3));   // Send PING
      EXCEPT on E:Exception do
        begin
        result := 0;
        CloseSlot(slot);
        end;
      END;{TRY}
    end
  else
    begin
    result := 0;
    UnReserveSlot(Slot);
    end;
End;

{
// Retuns the number of active peers connections
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
}

{
function GetTotalVerifiedConnections():Integer;
var
  counter:integer;
Begin
result := 0;
for counter := 1 to MaxConecciones do
   if conexiones[Counter].Autentic then result := result + 1;
End;
}

function GetTotalSyncedConnections():Integer;
var
  counter:integer;
Begin
result := 0;
for counter := 1 to MaxConecciones do
   if GetConexIndex(Counter).MerkleHash = GetCOnsensus(0) then result := result + 1;
End;

// Close all outgoing connections
function CerrarClientes(ServerToo:Boolean=True):string;
var
  Contador: integer;
Begin
result := '';
   TRY
   for contador := 1 to MaxConecciones do
      begin
      if GetConexIndex(contador).tipo='SER' then CloseSlot(contador);
      end;
   Result := 'Clients connections closed'
   EXCEPT on E:EXCEPTION do
      begin
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error closing client');
      Result := 'Error closing clients';
      end;
   END; {TRY}
if ServerToo then
   begin
   if form1.Server.active then StopServer;
   end;
End;

// This needs to be included on peers threads
Procedure LeerLineasDeClientes();
var
  contador : integer = 0;
Begin
for contador := 1 to Maxconecciones do
   begin
   if IsSlotConnected(contador) then
     begin
     if ( (UTCTime > StrToInt64Def(GetConexIndex(contador).lastping,0)+15) and
        (not GetConexIndex(contador).IsBusy) and (not REbuildingSumary) )then
        begin
        ToLog('events',TimeToStr(now)+'Conection closed: Time Out Auth -> '+GetConexIndex(contador).ip);   //Conection closed: Time Out Auth ->
        CloseSlot(contador);
        end;
     if GetConexIndex(contador).IsBusy then SetConexIndexLastPing(contador,UTCTimeStr);
     end;
   end;
End;

// Checks the current connection status (0-3)
Procedure VerifyConnectionStatus();
var
  NumeroConexiones : integer = 0;
  ValidSlot        : integer;
Begin
TRY
NumeroConexiones := GetTotalConexiones;
if NumeroConexiones = 0 then  // Desconectado
   begin
   EnterCriticalSection(CSCriptoThread);
   SetLength(ArrayCriptoOp,0); // Delete operations from crypto thread
   LeaveCriticalSection(CSCriptoThread);
   EnterCriticalSection(CSIdsProcessed);
   Setlength(ArrayOrderIDsProcessed,0); // clear processed Orders
   LeaveCriticalSection(CSIdsProcessed);
   ClearMNsChecks();
   ClearMNsList();
   MyConStatus := 0;
   if STATUS_Connected then
      begin
      STATUS_Connected := false;
      ToLog('console','Disconnected.');       //Disconnected
      G_TotalPings := 0;
      U_Datapanel:= true;
      ClearAllPending; //THREADSAFE
      end;
   // Resetear todos los valores
   end;
if ((NumeroConexiones>0) and (NumeroConexiones<3) and (MyConStatus = 0)) then // Conectando
   begin
   MyConStatus:=1;
   G_LastPing := UTCTime;
   ToLog('console','Connecting...'); //Connecting...
   end;
if MyConStatus > 0 then
   begin
   if (G_LastPing + 5) < UTCTime then
      begin
      G_LastPing := UTCTime;
      OutgoingMsjsAdd(ProtocolLine(ping));
      end;
   end;
if ((NumeroConexiones>=3) and (MyConStatus<2) and (not STATUS_Connected)) then
   begin
   STATUS_Connected := true;
   MyConStatus := 2;
   ToLog('console','Connected.');     //Connected
   end;
if STATUS_Connected then
   begin
   //UpdateNetworkData();
   if Last_SyncWithMainnet+4<UTCTime then SyncWithMainnet();
   end;
if ( (MyConStatus = 2) and (STATUS_Connected) and (IntToStr(MyLastBlock) = Getconsensus(2))
     and (copy(MySumarioHash,0,5)=GetConsensus(17)) and(copy(GetResumenHash,0,5) = GetConsensus(5)) ) then
   begin
   GetValidSlotForSeed(ValidSlot);
   ClearReceivedOrdersIDs;
   MyConStatus := 3;
   ToLog('console','Updated!');   //Updated!
   //if RPCAuto then  ProcessLinesAdd('RPCON');
   if WO_AutoServer then ProcessLinesAdd('serveron');
   if StrToIntDef(GetConsensus(3),0)<GetPendingCount then
      begin
      setlength(ArrayPoolTXs,0);
      end;
   // Get MNS
   PTC_SendLine(ValidSlot,ProtocolLine(11));  // Get MNs
   LastTimeMNsRequested := UTCTime;
   OutgoingMsjsAdd(ProtocolLine(ping));
   end;
if MyConStatus = 3 then
   begin
   GetValidSlotForSeed(ValidSlot);
   if ( (RPCAuto) and (not Form1.RPCServer.Active) ) then  ProcessLinesAdd('RPCON');
   if ( (not RPCAuto) and (Form1.RPCServer.Active) ) then  ProcessLinesAdd('RPCOFF');
   if ((StrToIntDef(GetConsensus(3),0)>GetPendingCount) and (LastTimePendingRequested+5<UTCTime) and
      (length(ArrayCriptoOp)=0) ) then
      begin
      ClearReceivedOrdersIDs();
      PTC_SendLine(ValidSlot,ProtocolLine(5));  // Get pending
      LastTimePendingRequested := UTCTime;
      end;
   if GetAddressBalanceIndexed(LocalMN_Funds) < GetStackRequired(MyLastBlock) then LastTimeReportMyMN := NextBlockTimeStamp+5;
   if ( (not IsMyMNListed(LocalMN_IP)) and (Form1.Server.Active) and (UTCTime>LastTimeReportMyMN+5)
        and (BlockAge>10+MNsRandomWait) and (BlockAge<495) and(1=1) ) then
     begin
     OutGoingMsjsAdd(ProtocolLine(MNReport));
     ToLog('events',TimeToStr(now)+'My Masternode reported');
     LastTimeReportMyMN := UTCTime;
     end;
   end;
EXCEPT ON E:Exception do
   begin
   ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2002,[E.Message]));
   end;
END{Try};
End;

{
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
}
{
// Actualiza mi informacion para compoartirla en la red
Procedure UpdateMyData();
Begin
MySumarioHash := HashMD5File(SummaryFileName);
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
SetResumenHash := HashMD5File(ResumenFilename);
  if SetResumenHash = GetConsensus(5) then ForceCompleteHeadersDownload := false;
MyMNsHash     := HashMD5File(MasterNodesFilename);
MyCFGHash     := Copy(HashMD5String(GetCFGDataStr),1,5);
End;
}



// Request necessary files/info to update
Procedure SyncWithMainnet();
var
  NLBV          : integer = 0; // network last block value
  LastDownBlock : integer = 0;
  ValidSlot     : integer;
  ConsenLB      : int64;
  Removed       : integer = 0;
Begin
if BuildingBlock>0 then exit;
if GetConsensus = '' then exit;
if ((BlockAge <10) or (blockAge>595)) then exit;
ConsenLB := StrToIntDef(GetConsensus(2),-1);
if ( (MyLastBlock > ConsenLB) and (ConsenLB >= 0) ) then
   begin
   Removed := RemoveBlocks(ConsenLB);
   ToLog('console',format('%d blocks deleted',[Removed]));
   //RestartNoso;
   Exit;
   end;
NLBV := StrToIntDef(GetConsensus(cLastBlock),0);

// *** New Synchronization methods

// *** Update CFG file.
if ( (GetConsensus(19)<>Copy(GetCFGHash,0,5)) and (LasTimeCFGRequest+5<UTCTime) and
          (GetConsensus(19)<>'') ) then
  begin
  if GetValidSlotForSeed(ValidSlot) then
    begin
    PTC_SendLine(ValidSlot,ProtocolLine(GetCFG));
    LasTimeCFGRequest := UTCTime;
    ToLog('console','Noso CFG file requested');
    end;
  end;

// *** Update MNs file
if ( (GetConsensus(8)<>Copy(GetMNsHash,1,5)) and (LastTimeMNHashRequestes+5<UTCTime) and
          (GetConsensus(8)<>'') ) then
  begin
  if GetValidSlotForSeed(ValidSlot) then
    begin
    PTC_SendLine(ValidSlot,ProtocolLine(GetMNsFile));  // Get MNsFile
    LastTimeMNHashRequestes := UTCTime;
    ToLog('console','Mns File requested to '+GetConexIndex(ValidSlot).ip);
    end;
  end;

// *** update headers
if Copy(GetResumenhash,0,5) <> GetConsensus(cHeaders) then  // Request headers
   begin
   ClearAllPending;
   ClearMNsChecks();
   ClearMNsList();
   if ((LastTimeRequestResumen+10 < UTCTime) and (not DownloadHeaders)) then
      begin
      if ( (NLBV-mylastblock >= 144) or (ForceCompleteHeadersDownload) ) then
         begin
         if GetValidSlotForSeed(ValidSlot) then
            begin
            PTC_SendLine(ValidSlot,ProtocolLine(7)); // GetResumen
            ToLog('console','Headers file requested to '+GetConexIndex(ValidSlot).ip); //'Headers file requested'
            LastTimeRequestResumen := UTCTime;
            end;
         end
      else // If less than 144 block just update headers
         begin
         if GetValidSlotForSeed(ValidSlot) then
            begin
            PTC_SendLine(ValidSlot,ProtocolLine(18)); // GetResumen
            ToLog('console',Format('Headers update (%d) requested from %s',[mylastblock,GetConexIndex(ValidSlot).ip]));
            LastTimeRequestResumen := UTCTime;
            end;
         end;
      end;
   end;

// *** Update blocks
if ((Copy(GetResumenhash,0,5) = GetConsensus(5)) and (mylastblock <NLBV)) then  // request up to 100 blocks
   begin
   ClearAllPending;
   ClearMNsChecks();
   ClearMNsList();
   if ((LastTimeRequestBlock+5<UTCTime)and (not DownLoadBlocks)) then
      begin
      if GetValidSlotForSeed(ValidSlot) then
         begin
         PTC_SendLine(ValidSlot,ProtocolLine(8)); // lastblock
         if WO_FullNode then ToLog('console','LastBlock requested from block '+IntToStr(mylastblock)+' to '+GetConexIndex(ValidSlot).ip) //'LastBlock requested from block '
         else
            begin
            LastDownBlock := NLBV-SecurityBlocks;
            if LastDownBlock<MyLastBlock then LastDownBlock:=MyLastBlock;
            ToLog('console','LastBlock requested from block '+IntToStr(LastDownBlock));
            end;
         LastTimeRequestBlock := UTCTime;
         end;
      end;
   end;

// Update summary
if ((copy(GetResumenhash,0,5) = GetConsensus(5)) and (mylastblock = NLBV) and
        (MySumarioHash<>GetConsensus(17)) {and (SummaryLastop < mylastblock)}) then
   begin  // complete or download summary
   if (SummaryLastop+(2*SumMarkInterval) < mylastblock) then
      begin
      if ((LastTimeRequestsumary+5 < UTCTime) and (not DownloadSumary) ) then
         begin
         if GetValidSlotForSeed(ValidSlot) then
            begin
            PTC_SendLine(ValidSlot,ProtocolLine(6)); // Getsumary
            ToLog('console',rs2003); //'sumary file requested'
            LastTimeRequestsumary := UTCTime;
            end;
         end;
      end
   else
      begin
      CompleteSumary();
      end;
   end;

// Update GVTs file
if ( (GetConsensus(18)<>Copy(MyGVTsHash,0,5)) and (LasTimeGVTsRequest+5<UTCTime) and
          (GetConsensus(18)<>'') and (not DownloadGVTs) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetGVTs));
      LasTimeGVTsRequest := UTCTime;
      ToLog('console','GVTs File requested to '+GetConexIndex(ValidSlot).ip);
      end;
   end;

// Update PSOs file
if ( (GetConsensus(20)<>Copy(PSOFileHash,0,5)) and (LasTimePSOsRequest+5<UTCTime) and
          (GetConsensus(20)<>'') and (not DownloadPSOs) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetPSOs));
      LasTimePSOsRequest := UTCTime;
      ToLog('console','Requested PSOs to: '+GetConexIndex(ValidSlot).ip);
      end;
   end;

// *** Request reported MNs
if ( (StrToIntDef(GetConsensus(9),0)>GetMNsListLength) and (LastTimeMNsRequested+5<UTCTime)
           and (LengthWaitingMNs = 0) and (BlockAge>30) and (IsAllSynced=0) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      ClearMNIPProcessed;
      PTC_SendLine(ValidSlot,ProtocolLine(11));  // Get MNsList
      LastTimeMNsRequested := UTCTime;
      ToLog('console','MNs reports requested to '+GetConexIndex(ValidSlot).ip);
      end;
   end;

// *** Request MNs verifications
if ((StrToIntDef(GetConsensus(14),0)>GetMNsChecksCount) and (LastTimeChecksRequested+5<UTCTime) and (IsAllSynced=0) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetChecks));  // Get MNsChecks
      LastTimeChecksRequested := UTCTime;
      ToLog('console','Checks requested to '+GetConexIndex(ValidSlot).ip);
      end;
   end;

// Blockchain status issues starts here
if ((copy(GetResumenhash,0,5) = GetConsensus(5)) and (mylastblock = NLBV) and
        (copy(MySumarioHash,0,5)<>GetConsensus(17)) and (SummaryLastop = mylastblock) and (LastTimeRequestsumary+5 < UTCTime)) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
     begin
     ToLog('console',format('%s <> %s',[copy(MySumarioHash,0,5),GetConsensus(17)]));
     PTC_SendLine(ValidSlot,ProtocolLine(6)); // Getsumary
     ToLog('console',rs2003); //'sumary file requested'
     LastTimeRequestsumary := UTCTime;
     end;
   end
else if ( (mylastblock = NLBV) and ( (copy(GetResumenhash,0,5) <> GetConsensus(5)) or
   (MyLastBlockHash<>GetConsensus(10)) ) ) then
   begin
   ToLog('console',MyLastBlockHash+' '+MyLastBlockHash);
   UndoneLastBlock();
   end
// Update headers
else if ((copy(GetResumenhash,0,5) <> GetConsensus(5)) and (NLBV=mylastblock) and (MyLastBlockHash=GetConsensus(10))
   and (copy(MySumarioHash,0,5)=GetConsensus(17)) and (not DownloadHeaders) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      ClearAllPending;
      PTC_SendLine(ValidSlot,ProtocolLine(7));
      ToLog('console','Headers file requested');
      LastTimeRequestResumen := UTCTime;
      end;
   end;

if IsAllSynced=0 then Last_SyncWithMainnet := UTCTime;
End;

function GetOutGoingConnections():integer;
var
  contador : integer;
Begin
  Result := 0;
  for contador := 1 to MaxConecciones do
    begin
    if GetConexIndex(contador).tipo='SER' then
      Inc(Result);
    end;
end;

function GetIncomingConnections():integer;
var
  contador : integer;
Begin
  result:= 0;
  for contador := 1 to MaxConecciones do
    begin
    if GetConexIndex(contador).tipo='CLI' then
      Inc(result);
    end;
end;

Function GetValidSlotForSeed(out Slot:integer):boolean;
const
  SlotCount : integer = 0;
var
  counter : integer;
Begin
  Result := false;
  for counter := 1 to MaxConecciones do
    begin
    Inc(SlotCount);
    if SlotCount > MaxConecciones then SlotCount := 1;
    if ( (GetConexIndex(SlotCount).MerkleHash = GetConsensus(0)) ) then
      begin
      result := true;
      slot := SlotCount;
      break;
      end;
    end;
End;

Function GetSeedConnections():integer;
var
  contador : integer;
Begin
  Result := 0;
  for contador := 1 to MaxConecciones do
    begin
    if IsSeedNode(GetConexIndex(contador).ip) then
      Inc(Result);
    end;
End;

function GetOrderDetails(orderid:string):TOrderGroup;
var
  counter,counter2 : integer;
  orderfound : boolean = false;
  resultorder : TOrderGroup;
  ArrTrxs : TBlockOrdersArray;
  LastBlockToCheck : integer = 0;
  FirstBlockToCheck : integer;
  TryonIndex       : integer = -1;
  CopyPendings : array of Torderdata;
Begin
BeginPerformance('GetOrderDetails');
resultorder := default(TOrderGroup);
result := resultorder;
if GetPendingCount>0 then
   begin
   EnterCriticalSection(CSPending);
   SetLength(CopyPendings,0);
   CopyPendings := copy(ArrayPoolTXs,0,length(ArrayPoolTXs));
   LeaveCriticalSection(CSPending);
   for counter := 0 to length(CopyPendings)-1 do
      begin
      if CopyPendings[counter].OrderID = orderid then
         begin
         resultorder.OrderID:=CopyPendings[counter].OrderID;
         resultorder.Block := -1;
         resultorder.reference:=CopyPendings[counter].reference;
         resultorder.TimeStamp:=CopyPendings[counter].TimeStamp;
         resultorder.receiver:= CopyPendings[counter].receiver;
         if CopyPendings[counter].OrderLines = 1 then
            resultorder.sender  := CopyPendings[counter].address
         else
            resultorder.sender:=resultorder.sender+format('[%s,%d,%d]',[CopyPendings[counter].Address,CopyPendings[counter].AmmountTrf,CopyPendings[counter].AmmountFee]);
         resultorder.AmmountTrf:=resultorder.AmmountTrf+CopyPendings[counter].AmmountTrf;
         resultorder.AmmountFee:=resultorder.AmmountFee+CopyPendings[counter].AmmountFee;
         resultorder.OrderLines+=1;
         resultorder.OrderType:=CopyPendings[counter].OrderType;
         orderfound := true;
         end;
      end;
   end;
if orderfound then result := resultorder
else
   begin
   TryonIndex := GetBlockFromOrder(orderid);
   if TryonIndex >= 0 then
      begin
      ToLog('console', 'Order found on index: '+TryOnIndex.ToString());
      ArrTrxs := GetBlockTrxs(TryonIndex);
      if length(ArrTrxs)>0 then
        begin
        for counter2 := 0 to length(ArrTrxs)-1 do
          begin
          if ArrTrxs[counter2].OrderID = orderid then
            begin
            resultorder.OrderID:=ArrTrxs[counter2].OrderID;
            resultorder.Block := ArrTrxs[counter2].Block;
            resultorder.reference:=ArrTrxs[counter2].reference;
            resultorder.TimeStamp:=ArrTrxs[counter2].TimeStamp;
            resultorder.receiver:=ArrTrxs[counter2].receiver;
            if ArrTrxs[counter2].OrderLines=1 then
              resultorder.sender := ArrTrxs[counter2].sender
            else
              resultorder.sender:=resultorder.sender+format('[%s,%d,%d]',[ArrTrxs[counter2].Address,ArrTrxs[counter2].AmmountTrf,ArrTrxs[counter2].AmmountFee]);
            resultorder.AmmountTrf:=resultorder.AmmountTrf+ArrTrxs[counter2].AmmountTrf;
            resultorder.AmmountFee:=resultorder.AmmountFee+ArrTrxs[counter2].AmmountFee;
            resultorder.OrderLines+=1;
            resultorder.OrderType:=ArrTrxs[counter2].OrderType;
            orderfound := true;
            end;
          end;
        end;
      SetLength(ArrTrxs,0);
      end
   else
     begin
     FirstBlockToCheck := mylastblock;
     ToLog('console', 'Order not on index');
     end;
   end;
result := resultorder;
EndPerformance('GetOrderDetails');
End;

function GetOrderSources(orderid:string):string;
var
  LastBlockToCheck : integer;
  Counter          : integer;
  counter2         : integer;
  ArrTrxs          : TBlockOrdersArray;
  orderfound       : boolean = false;
Begin
result := '';
if WO_FullNode then LastBlockToCheck := 1
else LastBlockToCheck := mylastblock-SecurityBlocks;
if LastBlockToCheck<1 then LastBlockToCheck := 1;
for counter := mylastblock downto mylastblock-4000 do
   begin
   ArrTrxs := GetBlockTrxs(counter);
   if length(ArrTrxs)>0 then
      begin
      for counter2 := 0 to length(ArrTrxs)-1 do
         begin
         if ArrTrxs[counter2].OrderID = orderid then
            begin
            Result := Result+Format('[%s,%d,%d]',[ArrTrxs[counter2].sender,ArrTrxs[counter2].AmmountTrf,ArrTrxs[counter2].AmmountFee]);
            orderfound := true;
            end;
         end;
      end;
   if orderfound then break;
   SetLength(ArrTrxs,0);
   end;
if not orderfound then result := 'Order Not Found';
End;

Function GetNodeStatusString():string;
Begin
//NODESTATUS 1{Peers} 2{LastBlock} 3{Pendings} 4{Delta} 5{headers} 6{version} 7{UTCTime} 8{MNsHash}
//           9{MNscount} 10{LasBlockHash} 11{BestHashDiff} 12{LastBlockTimeEnd} 13{LBMiner}
//           14{ChecksCount} 15{LastBlockPoW} 16{LastBlockDiff} 17{summary} 18{GVTs} 19{nosoCFG}
//           20{PSOHash}
result := {1}IntToStr(GetTotalConexiones)+' '+{2}IntToStr(MyLastBlock)+' '+{3}GetPendingCount.ToString+' '+
          {4}IntToStr(UTCTime-EngineLastUpdate)+' '+{5}copy(GetResumenHash,0,5)+' '+
          {6}MainnetVersion+NodeRelease+' '+{7}UTCTimeStr+' '+{8}copy(GetMnsHash,0,5)+' '+{9}GetMNsListLength.ToString+' '+
          {10}MyLastBlockHash+' '+{11}{GetNMSData.Diff}'null'+' '+{12}IntToStr(LastBlockData.TimeEnd)+' '+
          {13}LastBlockData.AccountMiner+' '+{14}GetMNsChecksCount.ToString+' '+{15}Parameter(LastBlockData.Solution,2)+' '+
          {16}Parameter(LastBlockData.Solution,1)+' '+{17}copy(MySumarioHash,0,5)+' '+{18}copy(MyGVTsHash,0,5)+' '+
          {19}Copy(GetCFGHash,0,5)+' '+{20}copy(PSOFileHash,0,5);
End;

Function IsSafeIP(IP:String):boolean;
Begin
if Pos(IP,Parameter(GetCFGDataStr,1))>0 then result:=true
else result := false;
End;

Function GetLastRelease():String;
var
  readedLine : string = '';
  Conector : TFPHttpClient;
Begin
Conector := TFPHttpClient.Create(nil);
conector.ConnectTimeout:=1000;
conector.IOTimeout:=1000;
TRY
   readedLine := Conector.SimpleGet('https://raw.githubusercontent.com/Noso-Project/NosoWallet/main/lastrelease.txt');
   // Binance API example
   //readedLine := Conector.SimpleGet('https://api.binance.com/api/v3/ticker/price?symbol=LTCUSDT');
EXCEPT on E: Exception do
   begin
   ToLog('console','ERROR RETRIEVING LAST RELEASE DATA: '+E.Message);
   end;
END;//TRY
Conector.Free;
result := readedLine;
End;

Function GetRepoFile(LurL:String):String;
var
  readedLine : string = '';
  Conector : TFPHttpClient;
Begin
  Conector := TFPHttpClient.Create(nil);
  conector.ConnectTimeout:=1000;
  conector.IOTimeout:=1000;
  TRY
    readedLine := Conector.SimpleGet(LurL);
  EXCEPT on E: Exception do
    begin
    ToDeepDeb('mpRed,GetRepoFile,'+E.Message);
    end;
  END;//TRY
  Conector.Free;
  result := readedLine;
End;

// Retrieves the OS for download the lastest version
Function GetOS():string;
Begin
{$IFDEF UNIX}
result := 'Linux';
{$ENDIF}
{$IFDEF WINDOWS}
result := 'Win';
{$ENDIF}
End;

Function GetLastVerZipFile(version,LocalOS:string):boolean;
var
  MS        : TMemoryStream;
  DownLink  : String = '';
  Conector  : TFPHttpClient;
  Trys      : Integer = 0;
Begin
result := false;
if Uppercase(localOS) = 'WIN' then
   DownLink := 'https://github.com/Noso-Project/NosoWallet/releases/download/v'+version+'/noso-v'+version+'-x86_64-win64.zip';
if Uppercase(localOS) = 'LINUX' then
   DownLink := 'https://github.com/Noso-Project/NosoWallet/releases/download/v'+version+'/noso-v'+version+'-x86_64-linux.zip';
MS := TMemoryStream.Create;
Conector := TFPHttpClient.Create(nil);
conector.ConnectTimeout:=1000;
conector.IOTimeout:=1000;
conector.AllowRedirect:=true;
Repeat
Inc(Trys);
   TRY
   Conector.Get(DownLink,MS);
   MS.SaveToFile('NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator+version+'_'+LocalOS+'.zip');
   result := true;
   EXCEPT ON E:Exception do
      begin
      ToLog('console',Format('Error downloading release (Try %d): %s',[Trys,E.Message]));
      end;
   END{Try};
until ( (result = true) or (Trys = 3) );
MS.Free;
conector.free;
End;

{
Function GetSyncTus():String;
Begin
  result := '';
  TRY
    Result := MyLastBlock.ToString+Copy(GetResumenHash,1,3)+Copy(MySumarioHash,1,3)+Copy(MyLastBlockHash,1,3);
  EXCEPT ON E:EXCEPTION do
    begin
    ToLog('console','****************************************'+slinebreak+'GetSyncTus:'+e.Message);
    end;
  END; {TRY}
End;
}
function GetMiIP():String;
var
  TCPClient : TidTCPClient;
  NodeToUse : integer;
Begin
  NodeToUse := Random(NodesListLen);
  Result := '';
  TCPClient := TidTCPClient.Create(nil);
  TCPclient.Host:=NodesIndex(NodeToUse).ip;
  TCPclient.Port:=StrToIntDef(NodesIndex(NodeToUse).port,8080);
  TCPclient.ConnectTimeout:= 1000;
  TCPclient.ReadTimeout:=1000;
  TRY
    TCPclient.Connect;
    TCPclient.IOHandler.WriteLn('GETMIIP');
    Result := TCPclient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
    TCPclient.Disconnect();
  EXCEPT on E:Exception do
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on GetMiIP: '+E.Message)
  END{try};
  TCPClient.Free;
End;

Function NodeServerInfo():String;
var
  TotalSeconds,days,hours,minutes,seconds, remain : integer;
Begin
if not form1.Server.Active then Result := 'OFF'
else
   begin
   Totalseconds := UTCTime-ServerStartTime;
   Days := Totalseconds div 86400;
   remain := Totalseconds mod 86400;
   hours := remain div 3600;
   remain := remain mod 3600;
   minutes := remain div 60;
   remain := remain mod 60;
   seconds := remain;
   if Days > 0 then Result:= Format('[%d] %dd %.2d:%.2d:%.2d', [G_MNVerifications, Days, Hours, Minutes, Seconds])
   else Result:= Format('[%d] %.2d:%.2d:%.2d', [G_MNVerifications,Hours, Minutes, Seconds]);
   end;
End;

Procedure ClearReceivedOrdersIDs();
Begin
EnterCriticalSection(CSIdsProcessed);
Setlength(ArrayOrderIDsProcessed,0); // clear processed Orders
LeaveCriticalSection(CSIdsProcessed);
End;

// Sends a order to the mainnet
function SendOrderToNode(OrderString:String):String;
var
  Client    : TidTCPClient;
  RanNode   : integer;
  TrysCount : integer = 0;
  WasOk     : Boolean = false;
Begin
  Result := '';
  if MyConStatus<3 then
     begin
     Result := 'ERROR 20';
     exit;
     end;
  Client := TidTCPClient.Create(nil);
    REPEAT
    Inc(TrysCount);
    if GetValidSlotForSeed(RanNode) then
      begin
      Client.Host:=GetConexIndex(RanNode).ip;
      Client.Port:=GetConexIndex(RanNode).ListeningPort;
      Client.ConnectTimeout:= 3000;
      Client.ReadTimeout:=3000;
        TRY
        Client.Connect;
        Client.IOHandler.WriteLn(OrderString);
        Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
        WasOK := True;
        EXCEPT on E:Exception do
          begin
          Result := 'ERROR 19';
          end;
        END{Try};
      end;
      UNTIL ( (WasOk) or (TrysCount=3) );
  if result <> '' then U_DirPanel := true;
  if result = '' then result := 'ERROR 21';
  if client.Connected then Client.Disconnect();
  client.Free;
End;

END. // END UNIT

