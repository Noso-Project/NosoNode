unit mpRed;

{$mode objfpc}{$H+}

interface

uses
  Classes, forms, SysUtils, MasterPaskalForm, MPTime, IdContext, IdGlobal, mpGUI, mpDisk,
  mpBlock, mpMiner, fileutil, graphics,  dialogs, strutils, mpcoin, fphttpclient,
  opensslsockets,translation, IdHTTP, IdComponent, IdSSLOpenSSL, mpmn, IdTCPClient;

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
Procedure UpdateNetworkData();
Function IsAllSynced():Boolean;
Procedure UpdateMyData();
Procedure ActualizarseConLaRed();
Procedure AddNewBot(linea:string);
function GetOutGoingConnections():integer;
function GetIncomingConnections():integer;
Function GetSeedConnections():integer;
Procedure SendNetworkRequests(timestamp,direccion:string;block:integer);
function GetOrderDetails(orderid:string):orderdata;
Function GetNodeStatusString():string;
Function IsSafeIP(IP:String):boolean;
Function GetLastRelease():String;
Function GetWebSeedNodes():String;
Function GetOS():string;
Function GetLastVerZipFile(version,LocalOS:string):boolean;
Function GetSyncTus():String;
function GetMiIP():String;
Function NodeServerInfo():String;
Procedure ClearReceivedOrdersIDs();

implementation

Uses
  mpParser, mpProtocol, mpCripto;

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
SetCurrentJob('SaveConection',true);
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
         Conexiones[contador].lastping:=UTCTime;
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
   Conexiones[ToSLot].lastping:=UTCTime;
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
SetCurrentJob('SaveConection',false);
end;

Procedure ForceServer();
var
  PortNumber : integer;
Begin
KeepServerOn := true;
PortNumber := StrToIntDef(MN_Port,8080);
if Form1.Server.Active then
   begin
   ConsoleLinesAdd(LangLine(160)); //'Server Already active'
   end
else
   begin
      TRY
      LastTryServerOn := StrToInt64(UTCTime);
      Form1.Server.Bindings.Clear;
      Form1.Server.DefaultPort:=PortNumber;//UserOptions.Port;
      Form1.Server.Active:=true;
      ConsoleLinesAdd(LangLine(14)+PortNumber.ToString);   //Server ENABLED. Listening on port
      ServerStartTime := UTCTime.ToInt64;
      U_DataPanel := true;
      EXCEPT on E : Exception do
        ToLog(LangLine(15));       //Unable to start Server
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
   ConsoleLinesAdd(rs2000); //Sign address not valid
   exit;
   end;
if MyConStatus < 3 then
   begin
   consolelinesadd(rs2001);
   exit;
   end;
KeepServerOn := true;
if Form1.Server.Active then
   begin
   ConsoleLinesAdd(LangLine(160)); //'Server Already active'
   end
else
   begin
      try
      LastTryServerOn := StrToInt64(UTCTime);
      Form1.Server.Bindings.Clear;
      Form1.Server.DefaultPort:=PortNumber;//UserOptions.Port;
      Form1.Server.Active:=true;
      ConsoleLinesAdd(LangLine(14)+PortNumber.ToString);   //Server ENABLED. Listening on port
      ServerStartTime := UTCTime.ToInt64;
      U_DataPanel := true;
      except
      on E : Exception do
        ToLog(LangLine(15));       //Unable to start Server
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
SetCurrentJob('StopServer',true);
KeepServerOn := false;
   TRY
   Form1.Server.Active:=false;
   ConsoleLinesAdd(LangLine(16));             //Server stopped
   U_DataPanel := true;
   EXCEPT on E:Exception do
      begin
      result := false;
      end;
   END{Try};
SetCurrentJob('StopServer',false);
end;

// Cierra la conexion del slot especificado
Procedure CerrarSlot(Slot:integer);
Begin
SetCurrentJob('CerrarSlot',true);
setmilitime('CerrarSlot',1);
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
  ToExcLog('Error: Closing slot '+IntToStr(Slot)+SLINEBREAK+E.Message);
END;{Try}
EnterCriticalSection(CSNodesList);
Conexiones[Slot] := Default(conectiondata);
LeaveCriticalSection(CSNodesList);
setmilitime('CerrarSlot',1);
SetCurrentJob('CerrarSlot',false);
End;

// Intenta conectar a los nodos
Procedure ConnectToServers();
var
  //contador : integer = 0;
  proceder : boolean = true;
  Success : boolean = false;
  Intentos : integer = 0;
  rannumber : integer;
  OutGoing  : integer;
Begin
OutGoing := GetOutGoingConnections;
SetCurrentJob('ConnectToServers',true);
setmilitime('ConnectToServers',1);
if not CONNECT_Try then
   begin
   ToLog(LangLine(162)); //'Trying connection to servers'
   CONNECT_Try := true;
   end;
if OutGoing >= MaxOutgoingConnections then proceder := false;
if getTotalConexiones >= MaxConecciones then Proceder := false;
if GetSeedConnections>=3 then proceder := false;
if proceder then
   begin
   rannumber := random(length(ListaNodos));
   REPEAT
   Inc(rannumber);
   if rannumber >=length(ListaNodos) then rannumber := 0;
   if ((GetSlotFromIP(ListaNodos[rannumber].ip)=0) AND (GetFreeSlot()>0) and (ListaNodos[rannumber].ip<>MN_Ip)) then
      begin
      if ConnectClient(ListaNodos[rannumber].ip,ListaNodos[rannumber].port) > 0 then Inc(OutGoing);
      //Success := true;
      end;
   intentos+=1;
   CONNECT_LastTime := IntTOStr(UTCTime.ToInt64+60);
   UNTIL ((Success) or (intentos = length(ListaNodos)) or (OutGoing=MaxOutgoingConnections));
   end;
if  ( (not Form1.Server.Active) and(IsSeedNode(MN_IP)) and (GetOutGoingConnections=0) and (WO_autoserver) )then
   forceserver;
CONNECT_LastTime := UTCTime();
setmilitime('ConnectToServers',2);
SetCurrentJob('ConnectToServers',false);
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
   ToExcLog('Error un-reserving slot '+number.ToString);
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
SetCurrentJob('ConnectClient',true);
result := 0;
ConContext := Default(TIdContext);
Slot := ReserveSlot();
if Address = '127.0.0.1' then
   begin
   ToLog(LangLine(29));    //127.0.0.1 is an invalid server address
   SetCurrentJob('ConnectClient',false);
   errored := true;
   end
else if Slot = 0 then // No free slots
   begin
   SetCurrentJob('ConnectClient',false);
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
      ToLog(LangLine(30)+Address);          //Connected TO:
      Conexiones[slot].Thread := TThreadClientRead.Create(true, slot);
      Conexiones[slot].Thread.FreeOnTerminate:=true;
      Conexiones[slot].Thread.Start;
      IncClientReadThreads;
      result := Slot;
         TRY
         CanalCliente[Slot].IOHandler.WriteLn('PSK '+Address+' '+ProgramVersion+subversion);
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
      ToExcLog('Error Connecting to '+Address+': '+E.Message);
      UnReserveSlot(Slot);
      end;
   END;{Try}
   }
   end
else UnReserveSlot(Slot);
SetCurrentJob('ConnectClient',false);
End;

// Retuns the number of active peers connections
function GetTotalConexiones():integer;
var
  counter:integer;
Begin
setmilitime('GetTotalConexiones',1);
result := 0;
for counter := 1 to MaxConecciones do
   if IsSlotConnected(Counter) then result := result + 1;
setmilitime('GetTotalConexiones',2);
End;

// Cierra todas las conexiones salientes
function CerrarClientes(ServerToo:Boolean=True):string;
var
  Contador: integer;
Begin
result := '';
CONNECT_Try := false;
SetCurrentJob('CerrarClientes',true);
   TRY
   for contador := 1 to MaxConecciones do
      begin
      if conexiones[contador].tipo='SER' then CerrarSlot(contador);
      end;
   Result := 'Clients connections closed'
   EXCEPT on E:EXCEPTION do
      begin
      ToExcLog('Error closing client');
      Result := 'Error closing clients';
      end;
   END; {TRY}
if ServerToo then
   begin
   if form1.Server.active then ProcessLinesAdd('SERVEROFF');
   end;
SetCurrentJob('CerrarClientes',false);
End;

// Verifica todas las conexiones tipo SER y lee las lineas entrantes que puedan tener
// Tambien desconecta los slots con mas de 15 segundos sin un ping
Procedure LeerLineasDeClientes();
var
  contador : integer = 0;
Begin
SetCurrentJob('LeerLineasDeClientes',true);
for contador := 1 to Maxconecciones do
   begin
   if IsSlotConnected(contador) then
     begin
     if ( (StrToInt64(UTCTime) > StrToInt64Def(conexiones[contador].lastping,0)+15) and
        (not conexiones[contador].IsBusy) and (not REbuildingSumary) )then
        begin
        ToLog(LangLine(32)+conexiones[contador].ip);   //Conection closed: Time Out Auth ->
        CerrarSlot(contador);
        end;
     end;
   end;
SetCurrentJob('LeerLineasDeClientes',false);
End;

// Checks the current connection status (0-3)
Procedure VerifyConnectionStatus();
var
  NumeroConexiones : integer = 0;
Begin
SetCurrentJob('VerifyConnectionStatus',true);
TRY
if ( (CONNECT_Try) and (StrToInt64(UTCTime)>StrToInt64Def(CONNECT_LastTime,StrToInt64(UTCTime))+5) ) then
   begin
   CONNECT_LastTime := IntTOStr(UTCTime.ToInt64+60);
   ConnectToServers;

   end;
NumeroConexiones := GetTotalConexiones;
if NumeroConexiones = 0 then  // Desconeectado
   begin
   EnterCriticalSection(CSCriptoThread);
   SetLength(ArrayCriptoOp,0); // Delete operations from crypto thread
   LeaveCriticalSection(CSCriptoThread);
   EnterCriticalSection(CSIdsProcessed);
   Setlength(ArrayOrderIDsProcessed,0); // clear processed Orders
   LeaveCriticalSection(CSIdsProcessed);
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
      ConsoleLinesAdd(LangLine(33));       //Disconnected
      G_TotalPings := 0;
      Miner_IsOn := false;
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
   G_LastPing := StrToInt64(UTCTime);
   ConsoleLinesAdd(LangLine(34)); //Connecting...
   Form1.imagenes.GetBitmap(2,form1.ConnectButton.Glyph);
   end;
if MyConStatus > 0 then
   begin
   if (G_LastPing + 5) < StrToInt64(UTCTime) then
      begin
      G_LastPing := StrToInt64(UTCTime);
      OutgoingMsjsAdd(ProtocolLine(ping));
      end;
   end;
if ((NumeroConexiones>=MinConexToWork) and (MyConStatus<2) and (not STATUS_Connected)) then
   begin
   STATUS_Connected := true;
   MyConStatus := 2;
   SetNMSData('','','');
   ConsoleLinesAdd(LangLine(35));     //Connected
   end;
if STATUS_Connected then
   begin
   UpdateNetworkData();
   if Last_ActualizarseConLaRed+4<UTCTime.ToInt64 then ActualizarseConLaRed();
   end;
if ( (MyConStatus = 2) and (STATUS_Connected) and (IntToStr(MyLastBlock) = NetLastBlock.Value)
     and (MySumarioHash=NetSumarioHash.Value) and(MyResumenhash = NetResumenHash.Value) ) then
   begin
   SetNMSData('','','');
   MyConStatus := 3;
   U_Mytrxs := true;
   ConsoleLinesAdd(LangLine(36));   //Updated!
   ResetMinerInfo();
   if RPCAuto then  ProcessLinesAdd('RPCON');
   if StrToIntDef(NetPendingTrxs.Value,0)<GetPendingCount then
      begin
      setlength(PendingTxs,0);
      end;
   if 1=1 {((StrToIntDef(NetPendingTrxs.Value,0)>GetPendingCount) and (LastTimePendingRequested+5<UTCTime.ToInt64)
      and (not CriptoThreadRunning) )} then
      begin
      PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));  // Get pending
      LastTimePendingRequested := UTCTime.ToInt64;
      ConsoleLinesAdd('Pending requested to '+conexiones[NetPendingTrxs.Slot].ip);
      end;
   // Get MNS
   PTC_SendLine(NetMNsHash.Slot,ProtocolLine(11));  // Get MNs
   LastTimeMNsRequested := UTCTime.ToInt64;
   ConsoleLinesAdd('Master nodes requested');
   OutgoingMsjsAdd(ProtocolLine(ping));
   Form1.imagenes.GetBitmap(0,form1.ConnectButton.Glyph);
   end;
if MyConStatus = 3 then
   begin
   SetCurrentJob('MyConStatus3',true);
   if ((StrToIntDef(NetPendingTrxs.Value,0)>GetPendingCount) and (LastTimePendingRequested+5<UTCTime.ToInt64) and
      (length(ArrayCriptoOp)=0) ) then
      begin
      ClearReceivedOrdersIDs();
      PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));  // Get pending
      LastTimePendingRequested := UTCTime.ToInt64;
      ConsoleLinesAdd('Pending requested to '+conexiones[NetPendingTrxs.Slot].ip);
      end;
   if ( (not MyMNIsListed) and (Form1.Server.Active) and (UTCTime.ToInt64>LastTimeReportMyMN+5)
        and (BlockAge>10+MNsRandomWait) and (BlockAge<495) and(1=1) ) then
     begin
     OutGoingMsjsAdd(ProtocolLine(MNReport));
     ToLog('My Masternode reported');
     LastTimeReportMyMN := UTCTime.ToInt64;
     end;
   SetCurrentJob('MyConStatus3',false);
   end;
EXCEPT ON E:Exception do
   begin
   ToExcLog(format(rs2002,[E.Message])+' '+CurrentJob);
   end;
END{Try};
SetCurrentJob('VerifyConnectionStatus',false);
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

Procedure UpdateNetworkData();
Begin
SetCurrentJob('UpdateNetworkData',true);
NetLastBlock := UpdateNetworkLastBlock; // Buscar cual es el ultimo bloque por consenso
NetLastBlockHash := UpdateNetworkLastBlockHash;
NetSumarioHash := UpdateNetworkSumario; // Busca el hash del sumario por consenso
NetPendingTrxs := UpdateNetworkPendingTrxs;
NetResumenHash := UpdateNetworkResumenHash;
NetMNsHash := UpdateNetworkMNsHash;
NetMNsCount := UpdateNetworkMNsCOunt;
NetBestHash := UpdateNetworkBestHash;
NetMNsChecks := UpdateNetworkMNsChecks;
U_DataPanel := true;
SetCurrentJob('UpdateNetworkData',false);
End;

Function IsAllSynced():Boolean;
Begin
result := true;
if MyLastBlock <> StrToIntDef(NetLastBlock.Value,0) then result := false;
if MyLastBlockHash <> NetLastBlockHash.Value then result := false;
if MySumarioHash <> NetSumarioHash.Value then result := false;
if MyResumenHash <> NetResumenHash.Value then result := false;
//if GetPendingCount <> StrToIntDef(NetPendingTrxs.Value,0) then result := false;
if GetMNsListLength <> StrToIntDef(NetMNsCount.Value,0) then result := false;
//if NetBestHash.Value <> GetNMSData.Diff then result := false;
//if GetMNsChecksCount <> StrToIntDef(NetMNsChecks.Value,0) then result := false;
if NetMNsHash.value <>  Copy(MyMNsHash,1,5) then result := false;
End;

// Actualiza mi informacion para compoartirla en la red
Procedure UpdateMyData();
Begin
SetCurrentJob('UpdateMyData',true);
MySumarioHash := HashMD5File(SumarioFilename);
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MyResumenHash := HashMD5File(ResumenFilename);
if MyResumenHash = NetResumenHash.Value then ForceCompleteHeadersDownload := false;
MyMNsHash     := HashMD5File(MasterNodesFilename);
U_PoSGrid := true;
SetCurrentJob('UpdateMyData',false);
End;

// Request necessary files/info to update
Procedure ActualizarseConLaRed();
var
  NLBV : integer = 0; // network last block value
Begin
if BuildingBlock>0 then exit;
if ((BlockAge <10) or (blockAge>595)) then exit;
SetCurrentJob('ActualizarseConLaRed',true);
NLBV := StrToIntDef(NetLastBlock.Value,0);
if ((MyResumenhash <> NetResumenHash.Value) and (NLBV>mylastblock)) then  // Request headers
   begin
   ClearAllPending;
   SetNMSData('','','');
   ClearMNsChecks();
   ClearMNsList();
   if ((LastTimeRequestResumen+5 < UTCTime.ToInt64) and (not DownloadHeaders)) then
      begin
      if ( (NLBV-mylastblock >= 144) or (ForceCompleteHeadersDownload) ) then
         begin
         PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7)); // GetResumen
         ConsoleLinesAdd(LangLine(163)); //'Headers file requested'
         LastTimeRequestResumen := StrToInt64(UTCTime);
         end
      else // If less than 144 block just update heades
         begin
         //PTC_SendLine(NetResumenHash.Slot,ProtocolLine(18)); // GetResumen update
         PTC_SendLine(NetResumenHash.Slot,ProtocolLine(18)); // GetResumen
         ConsoleLinesAdd('Headers update requested'); //'Headers file requested'
         LastTimeRequestResumen := StrToInt64(UTCTime);
         end;
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock <NLBV)) then  // request up to 100 blocks
   begin
   ClearAllPending;
   SetNMSData('','','');
   ClearMNsChecks();
   ClearMNsList();
   if ((LastTimeRequestBlock+5<StrToInt64(UTCTime))and (not DownLoadBlocks)) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(8)); // lastblock
      ConsoleLinesAdd(LangLine(164)+IntToStr(mylastblock)); //'LastBlock requested from block '
      LastTimeRequestBlock := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value) and (ListaSumario[0].LastOP < mylastblock)) then
   begin  // complete or rebuild sumary
   CompleteSumary();
   end
// Blockchain status issues starts here
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value) and (ListaSumario[0].LastOP = mylastblock)) then
   begin
   UndoneLastBlock();
   end
else if ( (mylastblock = NLBV) and ( (MyResumenhash <> NetResumenHash.Value) or
   (MyLastBlockHash<>NetLastBlockHash.value) ) ) then
   begin
   ConsoleLinesAdd(MyLastBlockHash+' '+MyLastBlockHash);
   UndoneLastBlock();
   end
// Update headers
else if ((MyResumenhash <> NetResumenHash.Value) and (NLBV=mylastblock) and (MyLastBlockHash=NetLastBlockHash.value)
   and (MySumarioHash=NetSumarioHash.Value) and (not DownloadHeaders) ) then
   begin
   ClearAllPending;
   SetNMSData('','','');
   PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7)); // GetResumen
   ConsoleLinesAdd(LangLine(163)); //'Headers file requested'
   LastTimeRequestResumen := StrToInt64(UTCTime);
   end
else if ( (StrToIntDef(NetMNsCount.Value,0)>GetMNsListLength) and (LastTimeMNsRequested+5<UTCTime.ToInt64)
           and (LengthWaitingMNs = 0) ) then
   begin
   EnterCriticalSection(CSMNsIPCheck);
   Setlength(ArrayIPsProcessed,0);
   LeaveCriticalSection(CSMNsIPCheck);
   PTC_SendLine(NetMNsCount.Slot,ProtocolLine(11));  // Get MNsList
   LastTimeMNsRequested := UTCTime.ToInt64;
   ConsoleLinesAdd('Master nodes requested');
   end
else if ((StrToIntDef(NetMNsChecks.Value,0)>GetMNsChecksCount) and (LastTimeChecksRequested+5<UTCTime.ToInt64)) then
   begin
   PTC_SendLine(NetMNsChecks.Slot,ProtocolLine(GetChecks));  // Get MNsChecks
   LastTimeChecksRequested := UTCTime.ToInt64;
   ConsoleLinesAdd('Checks requested to '+conexiones[NetMNsChecks.Slot].ip);
   end
else if ( (NetMNsHash.value<>Copy(MyMNsHash,1,5)) and (LastTimeMNHashRequestes+5<UTCTime.ToInt64) and
          (NetMNsHash.value<>'') ) then
   begin
   PTC_SendLine(NetMNsHash.Slot,ProtocolLine(GetMNsFile));  // Get MNsFile
   LastTimeMNHashRequestes := UTCTime.ToInt64;
   ConsoleLinesAdd('Mns File requested to '+conexiones[NetMNsChecks.Slot].ip);
   end
else if ( (GetNMSData.Diff<>NetBestHash.Value) and (LastTimeBestHashRequested+5<UTCTime.ToInt64) ) then
   begin
   {
   PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));
   LastTimeBestHashRequested := UTCTime.ToInt64;
   ConsolelinesAdd('Requesting besthash');
   }
   end;
if IsAllSynced then Last_ActualizarseConLaRed := Last_ActualizarseConLaRed+5;
SetCurrentJob('ActualizarseConLaRed',false);
End;

Procedure AddNewBot(linea:string);
var
  iptoadd: string;
Begin
IpToAdd := Parameter(Linea,1);
if not IsValidIP(IpToAdd) then
   begin
   ConsoleLinesAdd('Invalid IP');
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

Procedure SendNetworkRequests(timestamp,direccion:string;block:integer);
var
  texttosend: string;
  hashreq : string;
  hashvalue : string;
  tipo : integer;
Begin
tipo := 1;  // hashrate
hashreq := HashMD5String( IntToStr(tipo)+timestamp+direccion+IntToStr(block)+IntToStr(Miner_LastHashRate) );
hashvalue := HashMD5String(IntToStr(Miner_LastHashRate));
texttosend := GetPTCEcn+'NETREQ 1 '+timestamp+' '+direccion+' '+IntToStr(block)+' '+
   hashreq+' '+hashvalue+' '+IntToStr(Miner_LastHashRate);  // tipo 1: hashrate
OutgoingMsjsAdd(texttosend);
UpdateMyRequests(1,timestamp,block, hashreq, hashvalue);
ConsoleLinesAdd('hashrate starts in '+IntToStr(Miner_LastHashRate));
tipo := 2; // peers
hashreq := HashMD5String( IntToStr(tipo)+timestamp+direccion+IntToStr(block)+'1');
hashvalue := HashMD5String('1');
texttosend := GetPTCEcn+'NETREQ 2 '+timestamp+' '+direccion+' '+IntToStr(block)+' '+
   hashreq+' '+hashvalue+' '+'1';  // tipo 2: peers
OutgoingMsjsAdd(texttosend);
UpdateMyRequests(2,timestamp,block, hashreq, hashvalue);
ConsoleLinesAdd('peers starts in 1');
End;

function GetOrderDetails(orderid:string):orderdata;
var
  counter,counter2 : integer;
  orderfound : boolean = false;
  resultorder : orderdata;
  ArrTrxs : BlockOrdersArray;
  LastBlockToCheck : integer;
  CopyPendings : array of orderdata;
Begin
setmilitime('GetOrderDetails',1);
resultorder := default(orderdata);
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
   LastBlockToCheck := mylastblock-4000;
   if LastBlockToCheck<1 then LastBlockToCheck := 1;
   for counter := mylastblock downto LastBlockToCheck do
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
setmilitime('GetOrderDetails',2);
End;

Function GetNodeStatusString():string;
Begin
//NODESTATUS 1{Peers} 2{LastBlock} 3{Pendings} 4{Delta} 5{headers} 6{version} 7{UTCTime} 8{MNsHash} 9{MNscount}
//           10{LasBlockHash} 11{BestHashDiff} 12{LastBlockTimeEnd} 13{LBMiner} 14{ChecksCount} 15{LastBlockPoW}
//           16{LastBlockDiff}
result := {1}IntToStr(GetTotalConexiones)+' '+{2}IntToStr(MyLastBlock)+' '+{3}GetPendingCount.ToString+' '+
          {4}IntToStr(UTCTime.ToInt64-EngineLastUpdate)+' '+{5}copy(myResumenHash,0,5)+' '+
          {6}ProgramVersion+SubVersion+' '+{7}UTCTime+' '+{8}copy(MyMnsHash,0,5)+' '+{9}GetMNsListLength.ToString+' '+
          {10}MyLastBlockHash+' '+{11}GetNMSData.Diff+' '+{12}IntToStr(LastBlockData.TimeEnd)+' '+
          {13}LastBlockData.AccountMiner+' '+{14}GetMNsChecksCount.ToString+' '+{15}Parameter(LastBlockData.Solution,2)+' '+
          {16}Parameter(LastBlockData.Solution,1);
End;

Function IsSafeIP(IP:String):boolean;
Begin
if Pos(IP,DefaultNodes)>0 then result:=true
else result := false;
if IP = '107.172.30.204' then result := true;
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
   Consolelinesadd('ERROR RETRIEVING LAST RELEASES DATA: '+E.Message);
   end;
END;//TRY
Conector.Free;
result := readedLine;
End;

Function GetWebSeedNodes():String;
var
  readedLine : string = '';
  Conector : TFPHttpClient;
Begin
Conector := TFPHttpClient.Create(nil);
conector.ConnectTimeout:=1000;
conector.IOTimeout:=1000;
TRY
   readedLine := Conector.SimpleGet('https://raw.githubusercontent.com/Noso-Project/NosoWallet/main/seednodes.txt');
EXCEPT on E: Exception do
   begin
   Consolelinesadd('ERROR RETRIEVING WebSeedNodes: '+E.Message);
   end;
END;//TRY
Conector.Free;
result := readedLine;
End;

// Retrieves the OS for download the lastest version
Function GetOS():string;

  Function Is32Bit: Boolean;
  Begin
  Result:= SizeOf(Pointer) <= 4;
  End;

Begin
{$IFDEF UNIX}
result := 'Linux';
{$ENDIF}
{$IFDEF WINDOWS}
result := 'Windows';
{$ENDIF}
if Is32Bit then result := result+'32'
else result := result+'64';
End;

Function GetLastVerZipFile(version,LocalOS:string):boolean;
var
  MS: TMemoryStream;
  Int_SumarySize : int64;
  //IdSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
  DownLink : String = '';
  extension : string;
  Conector : TFPHttpClient;
Begin
result := false;
if localOS = 'Windows32' then
   DownLink := 'https://github.com/Noso-Project/NosoWallet/releases/download/v'+version+'/noso-v'+version+'-i386-win32.zip';
if localOS = 'Windows64' then
   DownLink := 'https://github.com/Noso-Project/NosoWallet/releases/download/v'+version+'/noso-v'+version+'-x86_64-win64.zip';
if localOS = 'Linux64' then
   DownLink := 'https://github.com/Noso-Project/NosoWallet/releases/download/v'+version+'/noso-v'+version+'-x86_64-linux.zip';
MS := TMemoryStream.Create;
Conector := TFPHttpClient.Create(nil);
conector.ConnectTimeout:=1000;
conector.IOTimeout:=1000;
conector.AllowRedirect:=true;
   TRY
   Conector.Get(DownLink,MS);
   MS.SaveToFile('NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator+'update.zip');
   result := true;
   EXCEPT ON E:Exception do
      ConsoleLines.Add('Error downloading last release: '+E.Message);
   END{Try};
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
   ConsolelinesAdd('****************************************'+slinebreak+'GetSyncTus:'+e.Message);
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
   ToExcLog('Error on GetMiIP: '+E.Message)
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
   Totalseconds := UTCTime.ToInt64-ServerStartTime;
   Days := Totalseconds div 86400;
   remain := Totalseconds mod 86400;
   hours := remain div 3600;
   remain := remain mod 3600;
   minutes := remain div 60;
   remain := remain mod 60;
   seconds := remain;
   if Days > 0 then Result:= Format('%dd %.2d:%.2d:%.2d', [Days, Hours, Minutes, Seconds])
   else Result:= Format('%.2d:%.2d:%.2d', [Hours, Minutes, Seconds]);
   end;
End;

Procedure ClearReceivedOrdersIDs();
Begin
EnterCriticalSection(CSIdsProcessed);
Setlength(ArrayOrderIDsProcessed,0); // clear processed Orders
LeaveCriticalSection(CSIdsProcessed);
End;

END. // END UNIT

