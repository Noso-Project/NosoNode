unit mpRed;

{$mode objfpc}{$H+}

interface

uses
  Classes, forms, SysUtils, MasterPaskalForm, nosotime, IdContext, IdGlobal, mpGUI, mpDisk,
  mpBlock, fileutil, graphics,  dialogs, strutils, mpcoin, fphttpclient,
  opensslsockets,translation, IdHTTP, IdComponent, IdSSLOpenSSL, mpmn, IdTCPClient,
  nosodebug,nosogeneral, nosocrypto, nosounit, nosoconsensus;

function GetSlotFromIP(Ip:String):int64;
function GetSlotFromContext(Context:TidContext):int64;
function BotExists(IPUser:String):Boolean;
function NodeExists(IPUser,Port:String):integer;
function SaveConection(tipo,ipuser:String;contextdata:TIdContext;toSlot:integer=-1):integer;
Procedure ForceServer();
procedure StartServer();
function StopServer():boolean;
procedure CerrarSlot(Slot:integer);
Procedure ConnectToServers();
Function IsSlotFree(number:integer):Boolean;
Function IsSlotConnected(number:integer):Boolean;
function GetFreeSlot():integer;
function ReserveSlot():integer;

Procedure IncClientReadThreads();
Procedure DecClientReadThreads();
Function GetClientReadThreads():integer;
function ConnectClient(Address,Port:String):integer;
function GetTotalConexiones():integer;
function GetTotalVerifiedConnections():Integer;
function GetTotalSyncedConnections():Integer;
function CerrarClientes(ServerToo:Boolean=True):string;
Procedure LeerLineasDeClientes();
Procedure VerifyConnectionStatus();
Procedure UpdateConsenso(data:String;Slot:integer);
Function GetMasConsenso():integer;
function UpdateNetworkLastBlock():NetWorkData;
function UpdateNetworkLastBlockHash():NetworkData;
function UpdateNetworkSumario():NetWorkData;
function UpdateNetworkPendingTrxs():NetworkData;
function UpdateNetworkResumenHash():NetworkData;
function UpdateNetworkMNsHash():NetworkData;
function UpdateNetworkMNsCount():NetworkData;
function UpdateNetworkBestHash():NetworkData;
function UpdateNetworkMNsChecks():NetworkData;
function UpdateNetworkGVTsHash():NetworkData;
function UpdateNetworkCFGHash():NetworkData;
Procedure UpdateNetworkData();
Function IsAllSynced():integer;
Procedure UpdateMyData();
Procedure SyncWithMainnet();
Procedure AddNewBot(linea:string);
function GetOutGoingConnections():integer;
function GetIncomingConnections():integer;
Function GetSeedConnections():integer;
Function GetValidSlotForSeed(out Slot:integer):boolean;
Function BlockFromIndex(LOrderID:String):integer;
function GetOrderDetails(orderid:string):TOrderGroup;
function GetOrderSources(orderid:string):string;
Function GetNodeStatusString():string;
Function IsSafeIP(IP:String):boolean;
Function GetLastRelease():String;
Function GetOS():string;
Function GetLastVerZipFile(version,LocalOS:string):boolean;
Function GetSyncTus():String;
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
   if conexiones[contador].ip=ip then
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
   if conexiones[contador].context=Context then
      begin
      result := contador;
      break;
      end;
   end;
end;

// Devuelve si un bot existe o no en la base de datos
function BotExists(IPUser:String):Boolean;
var
  contador : integer = 0;
Begin
Result := false;
for contador := 0 to length(ListadoBots)-1 do
   if ListadoBots[contador].ip = IPUser then result := true;
End;

// Devuelve si un Nodo existe o no en la base de datos
function NodeExists(IPUser,Port:String):integer;
var
  contador : integer = 0;
Begin
Result := -1;
for contador := 0 to length(ListadoBots)-1 do
   if ((ListaNodos[contador].ip = IPUser) and (ListaNodos[contador].port = port)) then result := contador;
End;

// Almacena una conexion con sus datos en el array Conexiones
function SaveConection(tipo,ipuser:String;contextdata:TIdContext;toSlot:integer=-1):integer;
var
  contador : integer = 1;
  Slot     : int64 = 0;
  FoundSlot: boolean = false;
begin
if ToSLot<0 then
   begin
   EnterCriticalSection(CSNodesList);
   For contador := 1 to MaxConecciones do
      begin
      if Conexiones[contador].tipo = '' then
         begin
         Conexiones[contador] := Default(conectiondata);
         Conexiones[contador].Autentic:=false;
         Conexiones[contador].Connections:=0;
         Conexiones[contador].tipo := tipo;
         Conexiones[contador].ip:= ipuser;
         Conexiones[contador].lastping:=UTCTimeStr;
         Conexiones[contador].context:=contextdata;
         Conexiones[contador].Lastblock:='0';
         Conexiones[contador].LastblockHash:='';
         Conexiones[contador].SumarioHash:='';
         Conexiones[contador].ListeningPort:=-1;
         Conexiones[contador].Pending:=0;
         Conexiones[contador].ResumenHash:='';
         Conexiones[contador].ConexStatus:=0;
         ClearIncoming(contador);
         FoundSlot := true;
         result := contador;
         break;
         end;
      end;
   LeaveCriticalSection(CSNodesList);
   if not FoundSlot then Result := 0;
   end
else
   begin
   EnterCriticalSection(CSNodesList);
   Conexiones[ToSLot] := Default(conectiondata);
   Conexiones[ToSLot].Autentic:=false;
   Conexiones[ToSLot].Connections:=0;
   Conexiones[ToSLot].tipo := tipo;
   Conexiones[ToSLot].ip:= ipuser;
   Conexiones[ToSLot].lastping:=UTCTimeStr;
   Conexiones[ToSLot].context:=contextdata;
   Conexiones[ToSLot].Lastblock:='0';
   Conexiones[ToSLot].LastblockHash:='';
   Conexiones[ToSLot].SumarioHash:='';
   Conexiones[ToSLot].ListeningPort:=-1;
   Conexiones[ToSLot].Pending:=0;
   Conexiones[ToSLot].ResumenHash:='';
   Conexiones[ToSLot].ConexStatus:=0;
   ClearIncoming(ToSLot);
   result := ToSLot;
   LeaveCriticalSection(CSNodesList);
   end;
end;

Procedure ForceServer();
var
  PortNumber : integer;
Begin
KeepServerOn := true;
PortNumber := StrToIntDef(MN_Port,8080);
if Form1.Server.Active then
   begin
   AddLineToDebugLog('console','Server Already active'); //'Server Already active'
   end
else
   begin
      TRY
      LastTryServerOn := UTCTime;
      Form1.Server.Bindings.Clear;
      Form1.Server.DefaultPort:=PortNumber;
      Form1.Server.Active:=true;
      AddLineToDebugLog('console','Server ENABLED. Listening on port '+PortNumber.ToString);   //Server ENABLED. Listening on port
      ServerStartTime := UTCTime;
      U_DataPanel := true;
      EXCEPT on E : Exception do
        AddLineToDebugLog('events',TimeToStr(now)+'Unable to start Server');       //Unable to start Server
      END; {TRY}
   end;
End;

// Activa el servidor
procedure StartServer();
var
  PortNumber : integer;
Begin
PortNumber := StrToIntDef(MN_Port,8080);
if DireccionEsMia(MN_Sign)<0 then
   begin
   AddLineToDebugLog('console',rs2000); //Sign address not valid
   exit;
   end;
if MyConStatus < 3 then
   begin
   AddLineToDebugLog('console',rs2001);
   exit;
   end;
KeepServerOn := true;
if Form1.Server.Active then
   begin
   AddLineToDebugLog('console','Server Already active'); //'Server Already active'
   end
else
   begin
      try
      LastTryServerOn := UTCTime;
      Form1.Server.Bindings.Clear;
      Form1.Server.DefaultPort:=PortNumber;
      Form1.Server.Active:=true;
      AddLineToDebugLog('console','Server ENABLED. Listening on port '+PortNumber.ToString);   //Server ENABLED. Listening on port
      ServerStartTime := UTCTime;
      U_DataPanel := true;
      except
      on E : Exception do
        AddLineToDebugLog('events',TimeToStr(now)+'Unable to start Server');       //Unable to start Server
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
   AddLineToDebugLog('console','Server stopped');             //Server stopped
   U_DataPanel := true;
   EXCEPT on E:Exception do
      begin
      result := false;
      end;
   END{Try};
end;

// Cierra la conexion del slot especificado
Procedure CerrarSlot(Slot:integer);
Begin
BeginPerformance('CerrarSlot');
TRY
if conexiones[Slot].tipo='CLI' then
   begin
   ClearIncoming(slot);
   Conexiones[Slot].context.Connection.Disconnect;
   Sleep(10);
   //Conexiones[Slot].Thread.terminate; // free ? WaitFor??
   end;
if conexiones[Slot].tipo='SER' then
   begin
   ClearIncoming(slot);
   CanalCliente[Slot].IOHandler.InputBuffer.Clear;
   CanalCliente[Slot].Disconnect;
   end;
EXCEPT on E:Exception do
  AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error: Closing slot '+IntToStr(Slot)+SLINEBREAK+E.Message);
END;{Try}
EnterCriticalSection(CSNodesList);
Conexiones[Slot] := Default(conectiondata);
LeaveCriticalSection(CSNodesList);
EndPerformance('CerrarSlot');
End;

// Try connection to nodes
Procedure ConnectToServers();
const
  LastTrySlot : integer = 0;
  LAstTryTime : int64 = 0;
  Unables     : integer = 0;
var
  proceder  : boolean = true;
  Loops     : integer = 0;
  OutGoing  : integer;
Begin
if ((BlockAge <=10) or (blockAge>=595)) then exit;
if LastTryTime >= UTCTime then exit;
OutGoing := GetOutGoingConnections;
BeginPerformance('ConnectToServers');
if not CONNECT_Try then
   begin
   AddLineToDebugLog('events',TimeToStr(now)+' Trying connection to nodes'); //'Trying connection to servers'
   CONNECT_Try := true;
   end;
//if OutGoing >= MaxOutgoingConnections then proceder := false;
if getTotalConexiones >= MaxConecciones then Proceder := false;
if GetTotalSyncedConnections>=3 then proceder := false;
if proceder then
   begin
   REPEAT
   Inc(LastTrySlot);
   if LastTrySlot >=length(ListaNodos) then LastTrySlot := 0;
   if ((GetSlotFromIP(ListaNodos[LastTrySlot].ip)=0) AND (GetFreeSlot()>0) and (ListaNodos[LastTrySlot].ip<>MN_Ip)) then
      begin
      if ConnectClient(ListaNodos[LastTrySlot].ip,ListaNodos[LastTrySlot].port) > 0 then Inc(OutGoing);
      end;
   Inc(Loops);
   CONNECT_LastTime := IntTOStr(UTCTime+60);
   UNTIL ( (Loops >= 5) or (OutGoing=MaxOutgoingConnections));
   end;
if  ( (not Form1.Server.Active) and(IsSeedNode(MN_IP)) and
      (GetOutGoingConnections=0) and (WO_autoserver) )then Inc(Unables)
else Unables := 0;
if Unables >= 10 then forceserver;
CONNECT_LastTime := UTCTimeStr;
EndPerformance('ConnectToServers');
End;

Function IsSlotFree(number:integer):Boolean;
Begin
result := true;
if conexiones[number].tipo <> '' then result := false;
End;

Function IsSlotConnected(number:integer):Boolean;
Begin
result := false;
if ((conexiones[number].tipo = 'SER') or (conexiones[number].tipo = 'CLI')) then result := true;
End;

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
      EnterCriticalSection(CSNodesList);
      Conexiones[contador].tipo:='RES';
      LeaveCriticalSection(CSNodesList);
      result := contador;
      break;
      end;
   end;
End;

// Reserves the first available slot
Procedure UnReserveSlot(number:integer);
Begin
if Conexiones[number].tipo ='RES' then
   begin
   EnterCriticalSection(CSNodesList);
   Conexiones[number].tipo :='';
   LeaveCriticalSection(CSNodesList);
   CerrarSlot(Number);
   end
else
   begin
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error un-reserving slot '+number.ToString);
   end;
End;

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
if Address = '127.0.0.1' then
   begin
   AddLineToDebugLog('events',TimeToStr(now)+'127.0.0.1 is an invalid server address');    //127.0.0.1 is an invalid server address
   errored := true;
   end
else if Slot = 0 then // No free slots
   begin
   errored := true;
   end;
if not errored then
   begin
   if CanalCliente[Slot].Connected then
      begin // Close Slot if it is connected
      {
      TRY
      CanalCliente[Slot].IOHandler.InputBuffer.Clear;
      CanalCliente[Slot].Disconnect;
      Conexiones[Slot] := Default(conectiondata);
      EXCEPT on E:exception do
         begin
         end;
      END;{Try}
      }
      end;
   CanalCliente[Slot].Host:=Address;
   CanalCliente[Slot].Port:=StrToIntDef(Port,8080);
   CanalCliente[Slot].ConnectTimeout:= ConnectTimeOutTime;
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
      AddLineToDebugLog('events',TimeToStr(now)+'Connected TO: '+Address);          //Connected TO:
      Conexiones[slot].Thread := TThreadClientRead.Create(true, slot);
      Conexiones[slot].Thread.FreeOnTerminate:=true;
      Conexiones[slot].Thread.Start;
      IncClientReadThreads;
      result := Slot;
         TRY
         CanalCliente[Slot].IOHandler.WriteLn('PSK '+Address+' '+ProgramVersion+subversion+' '+UTCTimeStr);
         CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(3));   // Send PING
         EXCEPT on E:Exception do
            begin
            result := 0;
            CerrarSlot(slot);
            end;
         END;{TRY}
      end
   else
      begin
      result := 0;
      CerrarSlot(slot);
      end;
   {
   EXCEPT on E:Exception do
      begin
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error Connecting to '+Address+': '+E.Message);
      UnReserveSlot(Slot);
      end;
   END;{Try}
   }
   end
else UnReserveSlot(Slot);
End;

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

function GetTotalVerifiedConnections():Integer;
var
  counter:integer;
Begin
result := 0;
for counter := 1 to MaxConecciones do
   if conexiones[Counter].Autentic then result := result + 1;
End;

function GetTotalSyncedConnections():Integer;
var
  counter:integer;
Begin
result := 0;
for counter := 1 to MaxConecciones do
   if conexiones[Counter].MerkleHash = GetCOnsensus(0) then result := result + 1;
End;

// Close all outgoing connections
function CerrarClientes(ServerToo:Boolean=True):string;
var
  Contador: integer;
Begin
result := '';
CONNECT_Try := false;
   TRY
   for contador := 1 to MaxConecciones do
      begin
      if conexiones[contador].tipo='SER' then CerrarSlot(contador);
      end;
   Result := 'Clients connections closed'
   EXCEPT on E:EXCEPTION do
      begin
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error closing client');
      Result := 'Error closing clients';
      end;
   END; {TRY}
if ServerToo then
   begin
   if form1.Server.active then ProcessLinesAdd('SERVEROFF');
   end;
End;

// Verifica todas las conexiones tipo SER y lee las lineas entrantes que puedan tener
// Tambien desconecta los slots con mas de 15 segundos sin un ping
Procedure LeerLineasDeClientes();
var
  contador : integer = 0;
Begin
for contador := 1 to Maxconecciones do
   begin
   if IsSlotConnected(contador) then
     begin
     if ( (UTCTime > StrToInt64Def(conexiones[contador].lastping,0)+15) and
        (not conexiones[contador].IsBusy) and (not REbuildingSumary) )then
        begin
        AddLineToDebugLog('events',TimeToStr(now)+'Conection closed: Time Out Auth -> '+conexiones[contador].ip);   //Conection closed: Time Out Auth ->
        CerrarSlot(contador);
        end;
     if conexiones[contador].IsBusy then conexiones[contador].lastping := UTCTimeStr;
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
if ( (CONNECT_Try) and (UTCTime>StrToInt64Def(CONNECT_LastTime,UTCTime)+5) ) then
   begin
   CONNECT_LastTime := IntTOStr(UTCTime+60);
   ConnectToServers;
   end;
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
   if Form1.Server.Active then
      begin
      if form1.ConnectButton.Caption='' then
        begin
        form1.ConnectButton.Caption:=' ';
        Form1.imagenes.GetBitmap(1,form1.ConnectButton.Glyph);
        end
      else
         begin
         Form1.imagenes.GetBitmap(2,form1.ConnectButton.Glyph);
         form1.ConnectButton.Caption:='';
         end;
      end
   else Form1.imagenes.GetBitmap(2,form1.ConnectButton.Glyph);
   if STATUS_Connected then
      begin
      STATUS_Connected := false;
      AddLineToDebugLog('console','Disconnected.');       //Disconnected
      G_TotalPings := 0;
      NetSumarioHash.Value:='';
      NetLastBlock.Value:='?';
      NetResumenHash.Value:='';
      NetPendingTrxs.Value:='';
      U_Datapanel:= true;
      ClearAllPending; //THREADSAFE
      Form1.imagenes.GetBitmap(2,form1.ConnectButton.Glyph);
      end;
   // Resetear todos los valores
   end;
if ((NumeroConexiones>0) and (NumeroConexiones<MinConexToWork) and (MyConStatus = 0)) then // Conectando
   begin
   MyConStatus:=1;
   G_LastPing := UTCTime;
   AddLineToDebugLog('console','Connecting...'); //Connecting...
   Form1.imagenes.GetBitmap(2,form1.ConnectButton.Glyph);
   end;
if MyConStatus > 0 then
   begin
   if (G_LastPing + 5) < UTCTime then
      begin
      G_LastPing := UTCTime;
      OutgoingMsjsAdd(ProtocolLine(ping));
      end;
   end;
if ((NumeroConexiones>=MinConexToWork) and (MyConStatus<2) and (not STATUS_Connected)) then
   begin
   STATUS_Connected := true;
   MyConStatus := 2;
   SetNMSData('','','','','','');
   AddLineToDebugLog('console','Connected.');     //Connected
   end;
if STATUS_Connected then
   begin
   UpdateNetworkData();
   if Last_SyncWithMainnet+4<UTCTime then SyncWithMainnet();
   end;
if ( (MyConStatus = 2) and (STATUS_Connected) and (IntToStr(MyLastBlock) = Getconsensus(2))
     and (copy(MySumarioHash,0,5)=GetConsensus(17)) and(copy(MyResumenhash,0,5) = GetConsensus(5)) ) then
   begin
   GetValidSlotForSeed(ValidSlot);
   ClearReceivedOrdersIDs;
   SetNMSData('','','','','','');
   MyConStatus := 3;
   AddLineToDebugLog('console','Updated!');   //Updated!
   if RPCAuto then  ProcessLinesAdd('RPCON');
   if StrToIntDef(GetConsensus(3),0)<GetPendingCount then
      begin
      setlength(PendingTxs,0);
      end;
   // Get MNS
   PTC_SendLine(ValidSlot,ProtocolLine(11));  // Get MNs
   LastTimeMNsRequested := UTCTime;
   OutgoingMsjsAdd(ProtocolLine(ping));
   Form1.imagenes.GetBitmap(0,form1.ConnectButton.Glyph);
   end;
if MyConStatus = 3 then
   begin
   GetValidSlotForSeed(ValidSlot);
   if ((StrToIntDef(GetConsensus(3),0)>GetPendingCount) and (LastTimePendingRequested+5<UTCTime) and
      (length(ArrayCriptoOp)=0) ) then
      begin
      ClearReceivedOrdersIDs();
      PTC_SendLine(ValidSlot,ProtocolLine(5));  // Get pending
      LastTimePendingRequested := UTCTime;
      end;
   if ( (not MyMNIsListed) and (Form1.Server.Active) and (UTCTime>LastTimeReportMyMN+5)
        and (BlockAge>10+MNsRandomWait) and (BlockAge<495) and(1=1) ) then
     begin
     OutGoingMsjsAdd(ProtocolLine(MNReport));
     AddLineToDebugLog('events',TimeToStr(now)+'My Masternode reported');
     LastTimeReportMyMN := UTCTime;
     end;
   end;
EXCEPT ON E:Exception do
   begin
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2002,[E.Message]));
   end;
END{Try};
End;

// Rellena el array consenso
Procedure UpdateConsenso(data:String;Slot:integer);
var
  contador : integer = 0;
  Maximo : integer;
  Existia : boolean = false;
Begin
ConsensoValues +=1;
maximo := length(ArrayConsenso);
while contador < maximo do
   begin
   if Data = ArrayConsenso[contador].value then
      begin
      ArrayConsenso[contador].count += 1;
      existia := true;
      end;
   contador := contador+1;
   end;
if not existia then
   begin
   SetLength(ArrayConsenso,length(ArrayConsenso)+1);
   ArrayConsenso[length(ArrayConsenso)-1].value:=data;
   ArrayConsenso[length(ArrayConsenso)-1].count:=1;
   ArrayConsenso[length(ArrayConsenso)-1].slot:=Slot;
   end;
End;

// Devuelve la posicion del ArrayConsenso donde esta el dato mas frecuente.
Function GetMasConsenso():integer;
var
  contador, Higher, POsicion : integer;
Begin
Higher := 0;
Posicion := -1;
for contador := 0 to length(ArrayConsenso)-1 do
   Begin
   if ArrayConsenso[contador].count > higher then
      begin
      higher := ArrayConsenso[contador].count;
      Posicion := contador;
      end;
   end;
if Posicion >= 0 then
  begin
  ArrayConsenso[Posicion].Porcentaje:=(ArrayConsenso[Posicion].Count*100) div ConsensoValues;
  end;
result := Posicion;
End;

function UpdateNetworkLastBlock():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].Lastblock,contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkLastBlockHash():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].LastblockHash,contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkSumario():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].SumarioHash, contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkPendingTrxs():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(IntToStr(conexiones[contador].Pending), contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkResumenHash():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].ResumenHash, contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkMNsHash():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].MNsHash, contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkMNsCount():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(IntToStr(conexiones[contador].MNsCount), contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkBestHash():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].BestHashDiff, contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkMNsChecks():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(IntToStr(conexiones[contador].MNChecksCount), contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkGVTsHash():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].GVTsHash, contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

function UpdateNetworkCFGHash():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
ConsensoValues := 0;
for contador := 1 to MaxConecciones do
   Begin
   if ( (IsSlotConnected(Contador)) and (IsSeedNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(conexiones[contador].CFGHash, contador);
      end;
   end;
if GetMasConsenso >= 0 then result := ArrayConsenso[GetMasConsenso]
else result := Default(NetworkData);
End;

Procedure UpdateNetworkData();
Begin
NetLastBlock     := UpdateNetworkLastBlock; // Buscar cual es el ultimo bloque por consenso
NetLastBlockHash := UpdateNetworkLastBlockHash;
NetSumarioHash   := UpdateNetworkSumario; // Busca el hash del sumario por consenso
NetPendingTrxs   := UpdateNetworkPendingTrxs;
NetResumenHash   := UpdateNetworkResumenHash;
NetMNsHash       := UpdateNetworkMNsHash;
NetMNsCount      := UpdateNetworkMNsCOunt;
NetBestHash      := UpdateNetworkBestHash;
NetMNsChecks     := UpdateNetworkMNsChecks;
NetGVTSHash      := UpdateNetworkGVTsHash;
NETCFGHash       := UpdateNetworkCFGHash;
U_DataPanel := true;
End;

Function IsAllSynced():integer;
Begin
result := 0;
if MyLastBlock     <> StrToIntDef(GetConsensus(cLastBlock),0) then result := 1;
if MyLastBlockHash <> GetConsensus(cLBHash) then result := 2;
if Copy(MySumarioHash,0,5)   <> GetConsensus(cSumHash) then result := 3;
if Copy(MyResumenHash,0,5)   <> GetConsensus(cHeaders) then result := 4;
{
if Copy(MyMNsHash,1,5) <>  NetMNsHash.value then result := 5;
if MyGVTsHash <> NetGVTSHash.Value then result := 6;
if MyCFGHash <> NETCFGHash.Value then result := 7;
}
End;

// Actualiza mi informacion para compoartirla en la red
Procedure UpdateMyData();
Begin
MySumarioHash := HashMD5File(SummaryFileName);
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MyResumenHash := HashMD5File(ResumenFilename);
  if MyResumenHash = NetResumenHash.Value then ForceCompleteHeadersDownload := false;
MyMNsHash     := HashMD5File(MasterNodesFilename);
MyCFGHash     := Copy(HAshMD5String(GetNosoCFGString),1,5);
End;

// Request necessary files/info to update
Procedure SyncWithMainnet();
var
  NLBV          : integer = 0; // network last block value
  LastDownBlock : integer = 0;
  ValidSlot     : integer;
Begin
if BuildingBlock>0 then exit;
if GetConsensus = '' then exit;
if ((BlockAge <10) or (blockAge>595)) then exit;
NLBV := StrToIntDef(GetConsensus(cLastBlock),0);
if ((Copy(MyResumenhash,0,5) <> GetConsensus(cHeaders)) and (NLBV>mylastblock)) then  // Request headers
   begin
   ClearAllPending;
   SetNMSData('','','','','','');
   ClearMNsChecks();
   ClearMNsList();
   if ((LastTimeRequestResumen+10 < UTCTime) and (not DownloadHeaders)) then
      begin
      if ( (NLBV-mylastblock >= 144) or (ForceCompleteHeadersDownload) ) then
         begin
         if GetValidSlotForSeed(ValidSlot) then
            begin
            PTC_SendLine(ValidSlot,ProtocolLine(7)); // GetResumen
            AddLineToDebugLog('console','Headers file requested to '+conexiones[ValidSlot].ip); //'Headers file requested'
            LastTimeRequestResumen := UTCTime;
            end;
         end
      else // If less than 144 block just update headers
         begin
         if GetValidSlotForSeed(ValidSlot) then
            begin
            PTC_SendLine(ValidSlot,ProtocolLine(18)); // GetResumen
            AddLineToDebugLog('console',Format('Headers update (%d) requested from %s',[mylastblock,conexiones[ValidSlot].ip]));
            LastTimeRequestResumen := UTCTime;
            end;
         end;
      end;
   end
else if ((Copy(MyResumenhash,0,5) = GetConsensus(5)) and (mylastblock <NLBV)) then  // request up to 100 blocks
   begin
   ClearAllPending;
   SetNMSData('','','','','','');
   ClearMNsChecks();
   ClearMNsList();
   if ((LastTimeRequestBlock+5<UTCTime)and (not DownLoadBlocks)) then
      begin
      if GetValidSlotForSeed(ValidSlot) then
         begin
         PTC_SendLine(ValidSlot,ProtocolLine(8)); // lastblock
         if WO_FullNode then AddLineToDebugLog('console','LastBlock requested from block '+IntToStr(mylastblock)+' to '+conexiones[ValidSlot].ip) //'LastBlock requested from block '
         else
            begin
            LastDownBlock := NLBV-SecurityBlocks;
            if LastDownBlock<MyLastBlock then LastDownBlock:=MyLastBlock;
            AddLineToDebugLog('console','LastBlock requested from block '+IntToStr(LastDownBlock));
            end;
         LastTimeRequestBlock := UTCTime;
         end;
      end;
   end
else if ((copy(MyResumenhash,0,5) = GetConsensus(5)) and (mylastblock = NLBV) and
        (MySumarioHash<>GetConsensus(17)) and (SummaryLastop < mylastblock)) then
   begin  // complete or download summary
   if (SummaryLastop+(2*SumMarkInterval) < mylastblock) then
      begin
      if ((LastTimeRequestsumary+5 < UTCTime) and (not DownloadSumary) ) then
         begin
         if GetValidSlotForSeed(ValidSlot) then
            begin
            PTC_SendLine(ValidSlot,ProtocolLine(6)); // Getsumary
            AddLineToDebugLog('console',rs2003); //'sumary file requested'
            LastTimeRequestsumary := UTCTime;
            end;
         end;
      end
   else
      begin
      CompleteSumary();
      //BuildHeaderFile(SummaryLastop);
      end;
   end
// Blockchain status issues starts here
else if ((copy(MyResumenhash,0,5) = GetConsensus(5)) and (mylastblock = NLBV) and
        (copy(MySumarioHash,0,5)<>GetConsensus(17)) and (SummaryLastop = mylastblock) and (LastTimeRequestsumary+5 < UTCTime)) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
     begin
     AddLineToDebugLog('console',format('%s <> %s',[copy(MySumarioHash,0,5),GetConsensus(17)]));
     PTC_SendLine(ValidSlot,ProtocolLine(6)); // Getsumary
     AddLineToDebugLog('console',rs2003); //'sumary file requested'
     LastTimeRequestsumary := UTCTime;
     end;
   end
else if ( (mylastblock = NLBV) and ( (copy(MyResumenhash,0,5) <> GetConsensus(5)) or
   (MyLastBlockHash<>GetConsensus(10)) ) ) then
   begin
   AddLineToDebugLog('console',MyLastBlockHash+' '+MyLastBlockHash);
   UndoneLastBlock();
   end
// Update headers
else if ((copy(MyResumenhash,0,5) <> GetConsensus(5)) and (NLBV=mylastblock) and (MyLastBlockHash=GetConsensus(10))
   and (copy(MySumarioHash,0,5)=GetConsensus(17)) and (not DownloadHeaders) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      ClearAllPending;
      SetNMSData('','','','','','');
      PTC_SendLine(ValidSlot,ProtocolLine(7));
      AddLineToDebugLog('console','Headers file requested');
      LastTimeRequestResumen := UTCTime;
      end;
   end
else if ( (StrToIntDef(GetConsensus(9),0)>GetMNsListLength) and (LastTimeMNsRequested+5<UTCTime)
           and (LengthWaitingMNs = 0) and (BlockAge>30) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      EnterCriticalSection(CSMNsIPCheck);
      Setlength(ArrayIPsProcessed,0);
      LeaveCriticalSection(CSMNsIPCheck);
      PTC_SendLine(ValidSlot,ProtocolLine(11));  // Get MNsList
      LastTimeMNsRequested := UTCTime;
      //AddLineToDebugLog('console','MNs reports requested');
      end;
   end
else if ((StrToIntDef(GetConsensus(14),0)>GetMNsChecksCount) and (LastTimeChecksRequested+5<UTCTime)) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetChecks));  // Get MNsChecks
      LastTimeChecksRequested := UTCTime;
      //AddLineToDebugLog('console','Checks requested to '+conexiones[ValidSlot].ip);
      end;
   end
else if ( (GetConsensus(8)<>Copy(MyMNsHash,1,5)) and (LastTimeMNHashRequestes+5<UTCTime) and
          (GetConsensus(8)<>'') ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetMNsFile));  // Get MNsFile
      LastTimeMNHashRequestes := UTCTime;
      AddLineToDebugLog('console','Mns File requested to '+conexiones[ValidSlot].ip);
      end;
   end
// <-- HERE -->
else if ( (GetConsensus(19)<>Copy(HashMd5String(GetNosoCFGString),0,5)) and (LasTimeCFGRequest+5<UTCTime) and
          (GetConsensus(19)<>'') ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetCFG));
      LasTimeCFGRequest := UTCTime;
      AddLineToDebugLog('console','Noso CFG file requested');
      end;
   end
else if ( (GetConsensus(18)<>Copy(MyGVTsHash,0,5)) and (LasTimeGVTsRequest+5<UTCTime) and
          (GetConsensus(18)<>'') and (not DownloadGVTs) ) then
   begin
   if GetValidSlotForSeed(ValidSlot) then
      begin
      PTC_SendLine(ValidSlot,ProtocolLine(GetGVTs));
      LasTimeGVTsRequest := UTCTime;
      AddLineToDebugLog('console','GVTs File requested to '+conexiones[ValidSlot].ip);
      end;
   end;
if IsAllSynced=0 then Last_SyncWithMainnet := Last_SyncWithMainnet+5;
End;

Procedure AddNewBot(linea:string);
var
  iptoadd: string;
Begin
IpToAdd := Parameter(Linea,1);
if not IsValidIP(IpToAdd) then
   begin
   AddLineToDebugLog('console','Invalid IP');
   end
else
   begin
   UpdateBotData(iptoadd);
   if GetSlotFromIP(iptoadd)>0 then CerrarSlot(GetSlotFromIP(iptoadd));
   end;
End;

function GetOutGoingConnections():integer;
var
  contador : integer;
  resultado : integer = 0;
Begin
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo='SER' then
      resultado += 1;
   end;
Result := resultado;
end;

function GetIncomingConnections():integer;
var
  contador : integer;
  resultado : integer = 0;
Begin
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo='CLI' then
      resultado += 1;
   end;
Result := resultado;
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
    if ( (conexiones[SlotCount].MerkleHash = GetConsensus(0)) ) then
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
  resultado : integer = 0;
Begin
Result := 0;
for contador := 1 to MaxConecciones do
   begin
   if IsSeedNode(conexiones[contador].ip) then
      Inc(Result);
   end;
end;

Function BlockFromIndex(LOrderID:String):integer;
var
  counter : integer;
Begin
  BeginPerformance('BlockFromIndex');
  result := -1;
  for counter := length(ArrayOrdIndex)-1 downto 0 do
    begin
    if AnsiContainsStr(ArrayOrdIndex[counter].orders,LOrderID) then
      begin
      result := ArrayOrdIndex[counter].block;
      break;
      end;
    end;
  EndPerformance('BlockFromIndex');
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
   CopyPendings := copy(PendingTxs,0,length(PendingTxs));
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
   if WO_FullNode then LastBlockToCheck := 1
   else LastBlockToCheck := mylastblock-SecurityBlocks;
   if LastBlockToCheck<1 then LastBlockToCheck := 1;
   TryonIndex :=  BlockFromIndex(orderid);
   if TryonIndex >= 0 then
      begin
      AddLineToDebugLog('console', 'Order found on index!');
      FirstBlockToCheck := TryonIndex;
      end
   else
     begin
     FirstBlockToCheck := mylastblock;
     AddLineToDebugLog('console', 'Order not on index');
     end;

   for counter := FirstBlockToCheck downto LastBlockToCheck do
      begin
      ArrTrxs := GetBlockTrxs(counter);
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
      if orderfound then break;
      SetLength(ArrTrxs,0);
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
  resultorder      : Torderdata;
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
result := {1}IntToStr(GetTotalConexiones)+' '+{2}IntToStr(MyLastBlock)+' '+{3}GetPendingCount.ToString+' '+
          {4}IntToStr(UTCTime-EngineLastUpdate)+' '+{5}copy(myResumenHash,0,5)+' '+
          {6}ProgramVersion+SubVersion+' '+{7}UTCTimeStr+' '+{8}copy(MyMnsHash,0,5)+' '+{9}GetMNsListLength.ToString+' '+
          {10}MyLastBlockHash+' '+{11}GetNMSData.Diff+' '+{12}IntToStr(LastBlockData.TimeEnd)+' '+
          {13}LastBlockData.AccountMiner+' '+{14}GetMNsChecksCount.ToString+' '+{15}Parameter(LastBlockData.Solution,2)+' '+
          {16}Parameter(LastBlockData.Solution,1)+' '+{17}copy(MySumarioHash,0,5)+' '+{18}copy(MyGVTsHash,0,5)+' '+
          {19}Copy(HashMD5String(GetNosoCFGString),0,5);
End;

Function IsSafeIP(IP:String):boolean;
Begin
if Pos(IP,Parameter(GetNosoCFGString,1))>0 then result:=true
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
   AddLineToDebugLog('console','ERROR RETRIEVING LAST RELEASE DATA: '+E.Message);
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
      AddLineToDebugLog('console',Format('Error downloading release (Try %d): %s',[Trys,E.Message]));
      end;
   END{Try};
until ( (result = true) or (Trys = 3) );
MS.Free;
conector.free;
End;

Function GetSyncTus():String;
Begin
result := '';
TRY
Result := MyLastBlock.ToString+Copy(MyResumenHash,1,3)+Copy(MySumarioHash,1,3)+Copy(MyLastBlockHash,1,3);
EXCEPT ON E:EXCEPTION do
   begin
   AddLineToDebugLog('console','****************************************'+slinebreak+'GetSyncTus:'+e.Message);
   end;
END; {TRY}
End;

function GetMiIP():String;
var
  TCPClient : TidTCPClient;
  LineText  : String = '';
  NodeToUse : integer;
Begin
NodeToUse := Random(Length(ListaNodos));
Result := '';
TCPClient := TidTCPClient.Create(nil);
TCPclient.Host:=ListaNodos[NodeToUse].ip;
TCPclient.Port:=StrToIntDef(ListaNodos[NodeToUse].port,8080);
TCPclient.ConnectTimeout:= 1000;
TCPclient.ReadTimeout:=1000;
TRY
TCPclient.Connect;
TCPclient.IOHandler.WriteLn('GETMIIP');
Result := TCPclient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
TCPclient.Disconnect();
EXCEPT on E:Exception do
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on GetMiIP: '+E.Message)
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
  ThisNode  : NodeData;
  TrysCount : integer = 0;
  WasOk     : Boolean = false;
Begin
  Result := '';
  Client := TidTCPClient.Create(nil);
    REPEAT
    Inc(TrysCount);
    if GetValidSlotForSeed(RanNode) then
      begin
      Client.Host:=conexiones[RanNode].ip;
      Client.Port:=conexiones[RanNode].ListeningPort;
      Client.ConnectTimeout:= 3000;
      Client.ReadTimeout:=3000;
        TRY
        Client.Connect;
        Client.IOHandler.WriteLn(OrderString);
        Result := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
        WasOK := True;
        EXCEPT on E:Exception do
          begin

          end;
        END{Try};

      end;
      UNTIL ( (WasOk) or (TrysCount=3) );
  if result <> '' then U_DirPanel := true;
  if client.Connected then Client.Disconnect();
  client.Free;
End;

END. // END UNIT

