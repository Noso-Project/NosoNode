unit mpRed;

{$mode objfpc}{$H+}

interface

uses
  Classes, forms, SysUtils, MasterPaskalForm, MPTime, IdContext, IdGlobal, mpGUI, mpDisk,
  mpBlock, mpMiner, fileutil, graphics,  dialogs,poolmanage, strutils, mpcoin, fphttpclient,
  opensslsockets,translation, IdHTTP, IdComponent, IdSSLOpenSSL, mpmn  ;

function GetSlotFromIP(Ip:String):int64;
function GetSlotFromContext(Context:TidContext):int64;
function BotExists(IPUser:String):Boolean;
function NodeExists(IPUser,Port:String):integer;
function SaveConection(tipo,ipuser:String;contextdata:TIdContext):integer;
Procedure ForceServer();
procedure StartServer();
procedure StopServer();
procedure CerrarSlot(Slot:integer);
Procedure ConnectToServers();
function GetFreeSlot():integer;
function ConnectClient(Address,Port:String):integer;
function GetTotalConexiones():integer;
Procedure CerrarClientes();
procedure ReadClientLines(Slot:int64);
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
Procedure UpdateNetworkData();
Procedure UpdateMyData();
Procedure CheckIncomingUpdateFile(version,hash, clavepublica, firma, namefile: string);
Procedure ActualizarseConLaRed();
Procedure AddNewBot(linea:string);
function GetOutGoingConnections():integer;
function GetIncomingConnections():integer;
Procedure SendNetworkRequests(timestamp,direccion:string;block:integer);
function GetOrderDetails(orderid:string):orderdata;
Function GetNodeStatusString():string;
Function IsAValidNode(IP:String):boolean;
Function GetLastRelease():String;
Function GetOS():string;
Function GetLastVerZipFile(version,LocalOS:string):boolean;

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
function SaveConection(tipo,ipuser:String;contextdata:TIdContext):integer;
var
  contador : integer = 1;
  Slot : int64 = 0;
begin
SetCurrentJob('SaveConection',true);
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
      slot := contador;
      SlotLines[slot].Clear;
      break;
      end;
   end;
result := slot;
SetCurrentJob('SaveConection',false);
end;

Procedure ForceServer();
Begin
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
      Form1.Server.DefaultPort:=UserOptions.Port;
      Form1.Server.Active:=true;
      ConsoleLinesAdd(LangLine(14)+IntToStr(UserOptions.Port));   //Server ENABLED. Listening on port
      U_DataPanel := true;
      except
      on E : Exception do
        ToLog(LangLine(15));       //Unable to start Server
      end;
   end;
End;

// Activa el servidor
procedure StartServer();
Begin
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
      Form1.Server.DefaultPort:=UserOptions.Port;
      Form1.Server.Active:=true;
      ConsoleLinesAdd(LangLine(14)+IntToStr(UserOptions.Port));   //Server ENABLED. Listening on port
      U_DataPanel := true;
      except
      on E : Exception do
        ToLog(LangLine(15));       //Unable to start Server
      end;
   end;
End;

// Apaga el servidor
procedure StopServer();
var
  Contador: integer;
Begin
if not Form1.Server.Active then exit;
SetCurrentJob('StopServer',true);
   TRY
   KeepServerOn := false;
   for contador := 1 to MaxConecciones do
      begin
      info('Closing Node connection: '+conexiones[contador].ip);
      if conexiones[contador].tipo='CLI' then CerrarSlot(contador);
      end;
   Form1.Server.Active:=false;
   ConsoleLinesAdd(LangLine(16));             //Server stopped
   U_DataPanel := true;
   EXCEPT on E:Exception do
      begin

      end;
   END{Try};
SetCurrentJob('StopServer',false);
end;

// Cierra la conexion del slot especificado
Procedure CerrarSlot(Slot:integer);
Begin
SetCurrentJob('CerrarSlot',true);
setmilitime('CerrarSlot',1);
   try
   if conexiones[Slot].tipo='CLI' then
      begin
      SlotLines[slot].Clear;
      Conexiones[Slot].context.Connection.Disconnect;
      Conexiones[Slot].Thread.Free;
      end;
   if conexiones[Slot].tipo='SER' then
      begin
      SlotLines[slot].Clear;
      CanalCliente[Slot].IOHandler.InputBuffer.Clear;
      CanalCliente[Slot].Disconnect;
      end;
   Except on E:Exception do
     begin
     ToExcLog('Error: Closing slot '+IntToStr(Slot)+SLINEBREAK+E.Message);
     end;
   end;
Conexiones[Slot] := Default(conectiondata);
setmilitime('CerrarSlot',1);
SetCurrentJob('CerrarSlot',false);
End;

// Intenta conectar a los nodos
Procedure ConnectToServers();
var
  //contador : integer = 0;
  proceder : boolean = true;
  Intentado : boolean = false;
  Intentos : integer = 0;
  rannumber : integer;
begin
SetCurrentJob('ConnectToServers',true);
setmilitime('ConnectToServers',1);
if Length(listanodos) = 0 then
   begin
   ConsoleLinesAdd(LangLine(161));  //'You need add some nodes first'
   CONNECT_Try := false;
   proceder := false;
   end;
if not CONNECT_Try then
   begin
   ConsoleLinesAdd(LangLine(162)); //'Trying connection to servers'
   CONNECT_Try := true;
   end;
if GetOutGoingConnections >= MaxOutgoingConnections then proceder := false;
if getTotalConexiones >= MaxConecciones then Proceder := false;
if proceder then
   begin
   Repeat
   rannumber := random(length(ListaNodos));
   if ((GetSlotFromIP(ListaNodos[rannumber].ip)=0) AND (GetFreeSlot()>0) and (ListaNodos[rannumber].ip<>MN_Ip)) then
      begin
      ConnectClient(ListaNodos[rannumber].ip,ListaNodos[rannumber].port);
      intentado := true;
      end;
   intentos+=1;
   until ((Intentado) or (intentos = 5));
   end;
CONNECT_LastTime := UTCTime();
setmilitime('ConnectToServers',2);
SetCurrentJob('ConnectToServers',false);
end;

// regresa el primer slot dispoinible, o 0 si no hay ninguno
function GetFreeSlot():integer;
var
  contador : integer = 1;
begin
result := 0;
for contador := 1 to MaxConecciones do
   begin
   if Conexiones[contador].tipo = '' then
      begin
      result := contador;
      break;
      end;
   end;
end;

// Connects a client and returns the slot
function ConnectClient(Address,Port:String):integer;
var
  Slot : integer = 0;
  ConContext : TIdContext; // EMPTY
  Errored : boolean = false;
Begin
SetCurrentJob('ConnectClient',true);
ConContext := Default(TIdContext);
Slot := GetFreeSlot();
if Address = '127.0.0.1' then
   begin
   ToLog(LangLine(29));    //127.0.0.1 is an invalid server address
   SetCurrentJob('ConnectClient',false);
   errored := true;
   end
else if Slot = 0 then // No free slots
   begin
   result := 0;
   SetCurrentJob('ConnectClient',false);
   errored := true;
   end;
if not errored then
   begin
   if CanalCliente[Slot].Connected then
      begin
         try
         CanalCliente[Slot].IOHandler.InputBuffer.Clear;
         CanalCliente[Slot].Disconnect;
         Except on E:exception do begin end;
         end;
      end;
   CanalCliente[Slot].Host:=Address;
   CanalCliente[Slot].Port:=StrToIntDef(Port,8080);
      try
      CanalCliente[Slot].ConnectTimeout:= ConnectTimeOutTime;
      CanalCliente[Slot].Connect;
      SaveConection('SER',Address,ConContext);
      ToLog(LangLine(30)+Address);          //Connected TO:
      UpdateNodeData(Address,Port);
      CanalCliente[Slot].IOHandler.WriteLn('PSK '+Address+' '+ProgramVersion+subversion);
      CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(3));   // Send PING
      Conexiones[slot].Thread := TThreadClientRead.Create(true, slot);
      Conexiones[slot].Thread.FreeOnTerminate:=true;
      Conexiones[slot].Thread.Start;
      result := Slot;
      SetCurrentJob('ConnectClient',false);
      Except on E:Exception do
         begin
         if E.Message<>'localhost: Connect timed out.' then
            ConsoleLinesAdd('EXCP - '+Address+': '+E.Message);
         result := 0;
         SetCurrentJob('ConnectClient',false);
         end;
      end;
   end;
End;

// Devuelve el numero de conexiones activas
function GetTotalConexiones():integer;
var
  Resultado : integer = 0;
  Contador : integer = 0;
Begin
setmilitime('GetTotalConexiones',1);
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo <> '' then resultado := resultado + 1;
   end;
result := resultado;
setmilitime('GetTotalConexiones',2);
End;

// Cierra todas las conexiones salientes
Procedure CerrarClientes();
var
  Contador: integer;
Begin
CONNECT_Try := false;
SetCurrentJob('CerrarClientes',true);
   try
   for contador := 1 to MaxConecciones do
      begin
      if conexiones[contador].tipo='SER' then CerrarSlot(contador);
      end;
   Except on E:Exception do
      begin

      end;
   end;
SetCurrentJob('CerrarClientes',false);
End;

// Read lines form clients: DEPRECATED
procedure ReadClientLines(Slot:int64);
var
  LLine: String;
  UpdateZipName : String = ''; UpdateVersion : String = ''; UpdateHash:string ='';
  UpdateClavePublica :string ='';UpdateFirma : string = '';
  AFileStream : TFileStream;
  BlockZipName : string = '';
  Continuar : boolean = true;
begin
//SetCurrentJob('ReadClientLines',true);
if CanalCliente[Slot].IOHandler.InputBufferIsEmpty then
   begin
   CanalCliente[Slot].IOHandler.CheckForDataOnSource(ReadTimeOutTIme);
   if CanalCliente[Slot].IOHandler.InputBufferIsEmpty then
      begin
      //SetCurrentJob('ReadClientLines',false);
      Continuar := false;
      end;
   end;
if Continuar then
   begin
   While not CanalCliente[Slot].IOHandler.InputBufferIsEmpty do
      begin
      try
      //CanalCliente[Slot].ReadTimeout:=ReadTimeOutTIme;
      LLine := CanalCliente[Slot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
      {
      if CanalCliente[Slot].IOHandler.ReadLnTimedout then
         begin
         exit;
         end;
         }
      if GetCommand(LLine) = 'UPDATE' then
         begin
         UpdateVersion := Parameter(LLine,1);
         UpdateHash := Parameter(LLine,2);
         UpdateClavePublica := Parameter(LLine,3);
         UpdateFirma := Parameter(LLine,4);
         UpdateZipName := 'nosoupdate'+UpdateVersion+'.zip';
         if FileExists(UpdateZipName) then DeleteFile(UpdateZipName);
         AFileStream := TFileStream.Create(UpdateZipName, fmCreate);
         CanalCliente[Slot].IOHandler.ReadStream(AFileStream);
         AFileStream.Free;
         CheckIncomingUpdateFile(UpdateVersion,UpdateHash,UpdateClavePublica,UpdateFirma,UpdateZipName);
         end
      else if GetCommand(LLine) = 'RESUMENFILE' then
         begin
         EnterCriticalSection(CSHeadAccess);
         AFileStream := TFileStream.Create(ResumenFilename, fmCreate);
         DownloadHeaders := true;
         CanalCliente[Slot].IOHandler.ReadStream(AFileStream);
         DownloadHeaders := false;
         AFileStream.Free;
         LeaveCriticalSection(CSHeadAccess);
         consolelinesAdd(LAngLine(74)+': '+copy(HashMD5File(ResumenFilename),1,5)); //'Headers file received'
         LastTimeRequestResumen := 0;
         UpdateMyData();
         end
      else if LLine = 'BLOCKZIP' then
         begin
         BlockZipName := BlockDirectory+'blocks.zip';
         if FileExists(BlockZipName) then DeleteFile(BlockZipName);
         AFileStream := TFileStream.Create(BlockZipName, fmCreate);
         CanalCliente[Slot].IOHandler.ReadStream(AFileStream);
         AFileStream.Free;
         UnzipBlockFile(BlockDirectory+'blocks.zip',true);
         MyLastBlock := GetMyLastUpdatedBlock();
         BuildHeaderFile(MyLastBlock);
         ResetMinerInfo();
         LastTimeRequestBlock := 0;
         end
      else
         SlotLines[Slot].Add(LLine);
      Except on E:Exception do
         begin
         tolog ('Error Reading lines from slot: '+IntToStr(slot)+slinebreak+E.Message);
         //SetCurrentJob('ReadClientLines',false);
         exit;
         end;
      end;
      end;

   end;
//SetCurrentJob('ReadClientLines',false);
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
   if Conexiones[contador].tipo <> '' then
     begin
     if ((StrToInt64(UTCTime) > StrToInt64Def(conexiones[contador].lastping,0)+15) and
        (not conexiones[contador].IsBusy) and (not REbuildingSumary) )then
        begin
        ConsoleLinesAdd(LangLine(32)+conexiones[contador].ip);   //Conection closed: Time Out Auth ->
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
setmilitime('VerifyConnectionStatus',1);
TRY
if ( (CONNECT_Try) and (StrToInt64(UTCTime)>StrToInt64Def(CONNECT_LastTime,StrToInt64(UTCTime))+5) ) then ConnectToServers;
NumeroConexiones := GetTotalConexiones;
if NumeroConexiones = 0 then  // Desconeectado
   begin
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
      SetLength(PendingTXs,0);
      StopPoolServer;
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
   if ( (not G_SendingMsgs) and (OutgoingMsjs.Count > 0) ) then // send the outgoing messages
      begin

      end;
   end;
if ((NumeroConexiones>=MinConexToWork) and (MyConStatus<2) and (not STATUS_Connected)) then
   begin
   STATUS_Connected := true;
   MyConStatus := 2;
   ConsoleLinesAdd(LangLine(35));     //Connected
   end;
if STATUS_Connected then
   begin
   UpdateNetworkData();
   ActualizarseConLaRed();
   end;
if ((MyConStatus = 2) and (STATUS_Connected) and (IntToStr(MyLastBlock) = NetLastBlock.Value)
     and (MySumarioHash=NetSumarioHash.Value) and(MyResumenhash = NetResumenHash.Value)) then
   begin
   MyConStatus := 3;
   U_Mytrxs := true;
   SumaryRebuilded:= false;
   ConsoleLinesAdd(LangLine(36));   //Updated!
   UndonedBlocks := false;
   ResetMinerInfo();
   ResetPoolMiningInfo();
   if RPCAuto then  ProcessLinesAdd('RPCON');
   if ((Miner_OwnsAPool) and (Miner_Active) and(not Form1.PoolServer.Active) and (G_KeepPoolOff = false)) then // Activar el pool propio si se posee uno
      begin
      StartPoolServer(Poolinfo.Port);
      if Form1.PoolServer.Active then ConsoleLinesAdd(PoolInfo.Name+' pool server is listening')
      else ConsoleLinesAdd('Unable to start pool server');
      end;
   if StrToIntDef(NetPendingTrxs.Value,0)<length(PendingTXs) then
      begin
      setlength(PendingTxs,0);
      end;
   if ((StrToIntDef(NetPendingTrxs.Value,0)>length(PendingTXs)) and (LastTimePendingRequested+5<UTCTime.ToInt64)
      and (not CriptoThreadRunning) ) then
      begin
      PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));  // Get pending
      LastTimePendingRequested := UTCTime.ToInt64;
      ConsoleLinesAdd('Pending requested');
      end;
   // Get MNS
   if ((StrToIntDef(NetMNsCount.Value,0)>MyMNsCount) and (UTCTime.ToInt64>LastTimeMNsRequested+5) and (Length(WaitingMNs)=0)) then
      begin
      PTC_SendLine(NetMNsHash.Slot,ProtocolLine(11));  // Get MNs
      LastTimeMNsRequested := UTCTime.ToInt64;
      ConsoleLinesAdd('Master nodes requested');
      end;

   OutgoingMsjsAdd(ProtocolLine(ping));
   Form1.imagenes.GetBitmap(0,form1.ConnectButton.Glyph);
   end;
if MyConStatus = 3 then
   begin
   //if ((RunExpelPoolInactives) and (not BuildingBlock)) then ExpelPoolInactives;
   SetCurrentJob('MyConStatus3',true);
   if StrToIntDef(NetPendingTrxs.Value,0)<length(PendingTXs) then
      begin
      //setlength(PendingTxs,0);
      end;
   if ((StrToIntDef(NetPendingTrxs.Value,0)>length(PendingTXs)) and (LastTimePendingRequested+5<UTCTime.ToInt64) and
      (length(ArrayCriptoOp)=0) ) then
      begin
      SetCurrentJob('RequestingPendings',true);
      PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));  // Get pending
      LastTimePendingRequested := UTCTime.ToInt64;
      ConsoleLinesAdd('Pending requested');
      SetCurrentJob('RequestingPendings',false);
      end;
   if ( (StrToIntDef(NetMNsCount.Value,0) = length(MNsList)) and (not MyMNIsListed) and (UTCTime.ToInt64>LastTimeReportMyMN+5) ) then
     begin
     ReportMyMN;
     LastTimeReportMyMN := UTCTime.ToInt64;
     end;
   if ((StrToIntDef(NetMNsCount.Value,0)>MyMNsCount) and (UTCTime.ToInt64>LastTimeMNsRequested+5) and (Length(WaitingMNs)=0)) then
      begin
      PTC_SendLine(NetMNsHash.Slot,ProtocolLine(11));  // Get MNs
      LastTimeMNsRequested := UTCTime.ToInt64;
      ConsoleLinesAdd('Master nodes requested');
      end;
   if ( (IntToStr(MyLastBlock) <> NetLastBlock.Value) or (MySumarioHash<>NetSumarioHash.Value) or
      (MyResumenhash <> NetResumenHash.Value) ) then // desincronizado
      Begin

      end
   else SynchWarnings := 0;
   if ((Miner_OwnsAPool) and (not Form1.PoolServer.Active) and (G_KeepPoolOff = false)) then // Activar el pool propio si se posee uno
      begin
      if ( (Mylastblock+1 = StrToIntDef(parameter(Miner_RestartedSolution,0),-1)) and
         (StrToIntDef(parameter(Miner_RestartedSolution,1),-1)>0) ) then
         begin
         // REstart pool solution
         RestartPoolSolution();
         end;
      Miner_RestartedSolution := '';
      if LastTryStartPoolServer+5 < StrToInt64(UTCTIME) then
         begin
         StartPoolServer(Poolinfo.Port);
         LastTryStartPoolServer := StrToInt64(UTCTIME);
         if Form1.PoolServer.Active then ConsoleLinesAdd(PoolInfo.Name+' pool server is listening')
         else ConsoleLinesAdd('Unable to start pool server');
         end;
      end;
   if ((Miner_OwnsAPool) and (Form1.PoolServer.Active) and (LastPoolHashRequest+5<StrToInt64(UTCTime))) then
      begin
      ProcessLinesAdd('POOLHASHRATE'); // Verify pool pings
      end;
   SetCurrentJob('MyConStatus3',false);
   end;
EXCEPT ON E:Exception do
   begin
   ToExcLog(format(rs2002,[E.Message]));
   end;
END{Try};
setmilitime('VerifyConnectionStatus',2);
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
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
   if ( (conexiones[contador].tipo<> '') and (IsDefaultNode(conexiones[contador].ip)) ) then
      begin
      UpdateConsenso(IntToStr(conexiones[contador].MNsCount), contador);
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
U_DataPanel := true;
SetCurrentJob('UpdateNetworkData',false);
// Si lastblock y sumario no estan actualizados solicitarlos
End;

// Actualiza mi informacion para compoartirla en la red
Procedure UpdateMyData();
Begin
SetCurrentJob('UpdateMyData',true);
MySumarioHash := HashMD5File(SumarioFilename);
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MyResumenHash := HashMD5File(ResumenFilename);
U_PoSGrid := true;
SetCurrentJob('UpdateMyData',false);
End;

// Verificar y que hacer con un archivo de Update
Procedure CheckIncomingUpdateFile(version,hash, clavepublica, firma, namefile: string);
var
  Proceder : boolean = true;
Begin
if GetAddressFromPublicKey(clavepublica) <> Adminhash then Proceder := false;
if not VerifySignedString(version+' '+hash,firma,clavepublica) then Proceder := false;
if HashMD5File(namefile) <> hash then Proceder := false;
if version <= ProgramVersion then
   begin
   ConsoleLinesAdd(LangLine(38)); //Update file received is obsolete
   trydeletefile(namefile);
   Proceder := false;
   end;
if fileexists(UpdatesDirectory+namefile) then
   begin
   ConsoleLinesAdd('Update file already exists');
   trydeletefile(namefile);
   Proceder := false;
   end;
if not proceder then
   begin
   ConsoleLinesAdd(LangLine(37));      //Update file received is wrong
   trydeletefile(namefile);
   end
else
   begin
   UnzipBlockFile(namefile,false);
   copyfile(namefile,UpdatesDirectory+namefile);
   deletefile(namefile);
   EnviarUpdate('sendupdate '+Version+' '+clavepublica+' '+hash+' '+firma);
   if UserOptions.Auto_Updater then
         begin
         useroptions.JustUpdated:=true;
         GuardarOpciones();
         CrearRestartfile();
         EjecutarAutoUpdate(version);
         form1.close;
         end
   else
      begin
      // que hacer si la opcion autopupdate no esta activada
      deletefile('noso'+version+'.exe');
      if not AnsiContainsStr(StringAvailableUpdates,version) then StringAvailableUpdates := StringAvailableUpdates+' '+version;
      end;
   end;
End;

// Solicitar los archivos necesarios para actualizarse con la red
Procedure ActualizarseConLaRed();
var
  NLBV : integer = 0; // network last block value
Begin
SetCurrentJob('ActualizarseConLaRed',true);
NLBV := StrToIntDef(NetLastBlock.Value,0);
if ((MyResumenhash <> NetResumenHash.Value) and (NLBV>mylastblock)) then  // solicitar cabeceras de bloque
   begin
   if ((LastTimeRequestResumen+5 < StrToInt64(UTCTime)) and (not DownloadHeaders)) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7)); // GetResumen
      ConsoleLinesAdd(LangLine(163)); //'Headers file requested'
      LastTimeRequestResumen := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock <NLBV)) then  // solicitar hasta 100 bloques
   begin
   if ((LastTimeRequestBlock+5<StrToInt64(UTCTime))and (not DownLoadBlocks)) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(8)); // lastblock
      ConsoleLinesAdd(LangLine(164)+IntToStr(mylastblock)); //'LastBlock requested from block '
      LastTimeRequestBlock := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value) and (not SumaryRebuilded)) then
   begin  // complete or rebuild sumary
   if ListaSumario[0].LastOP < mylastblock then CompleteSumary()
   else
      begin
      UndoneLastBlock(true,false);
      //RebuildSumario(MyLastBlock);
      SumaryRebuilded:= true;
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value) and (SumaryRebuilded)) then
   begin  // Blockchain status issue
   ConsoleLinesAdd('EXCEPTION BLOCKCHAIN');
   RebuildSumario(MyLastBlock);
   //UndoneLastBlock(true,false);
   //RestoreBlockChain();
   end;

// Update headers for pool automatically
if ((fileexists(PoolInfoFilename)) and (MyResumenhash <> NetResumenHash.Value) and (NLBV=mylastblock)
   and (MySumarioHash=NetSumarioHash.Value)) then
   begin
   PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7)); // GetResumen
   ConsoleLinesAdd(LangLine(163)); //'Headers file requested'
   LastTimeRequestResumen := StrToInt64(UTCTime);
   end;
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
Begin
setmilitime('GetOrderDetails',1);
resultorder := default(orderdata);
result := resultorder;
if length(PendingTxs)>0 then
   for counter := 0 to length(PendingTxs)-1 do
      begin
      if PendingTxs[counter].OrderID = orderid then
         begin
         resultorder.OrderID:=PendingTxs[counter].OrderID;
         resultorder.Block := -1;
         resultorder.reference:=PendingTxs[counter].reference;
         resultorder.TimeStamp:=PendingTxs[counter].TimeStamp;
         resultorder.receiver:= PendingTxs[counter].receiver;
         resultorder.AmmountTrf:=resultorder.AmmountTrf+PendingTxs[counter].AmmountTrf;
         resultorder.AmmountFee:=resultorder.AmmountFee+PendingTxs[counter].AmmountFee;
         resultorder.OrderLines+=1;
         resultorder.OrderType:=PendingTxs[counter].OrderType;
         orderfound := true;
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
result := IntToStr(GetTotalConexiones)+' '+IntToStr(MyLastBlock)+' '+IntToStr(Length(PendingTXs))+' '+
          IntToStr(UTCTime.ToInt64-EngineLastUpdate)+' '+copy(myResumenHash,0,5)+' '+
          ProgramVersion+SubVersion+' '+UTCTime+' '+copy(MyMnsHash,0,5)+' '+IntTOStr(MyMNsCount);
End;

Function IsAValidNode(IP:String):boolean;
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
conector.ConnectTimeout:=ConnectTimeOutTime;
conector.IOTimeout:=ReadTimeOutTime;
Try
   readedLine := Conector.SimpleGet('https://raw.githubusercontent.com/Noso-Project/NosoWallet/main/lastrelease.txt');
Except on E: Exception do
   begin
   Consolelinesadd('ERROR RETRIEVING LAST RELEASES DATA: '+E.Message);
   end;
end;//TRY
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
{$IFDEF Linux}
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
  IdSSLIOHandler: TIdSSLIOHandlerSocketOpenSSL;
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

// indy mode
IdSSLIOHandler:= TIdSSLIOHandlerSocketOpenSSL.Create;
IdSSLIOHandler.SSLOptions.SSLVersions := [sslvTLSv1,sslvTLSv1_1,sslvTLSv1_2];
MS := TMemoryStream.Create;

// TFPHttpClient mode
Conector := TFPHttpClient.Create(nil);
conector.ConnectTimeout:=1000;
conector.IOTimeout:=1000;
conector.AllowRedirect:=true;


TRY
   TRY
   //Form1.IdHTTPUpdate.HandleRedirects:=true;
   //Form1.IdHTTPUpdate.IOHandler:=IdSSLIOHandler;
   //Form1.IdHTTPUpdate.get(DownLink, MS);
   Conector.Get(DownLink,MS);
   MS.SaveToFile('NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator+'update.zip');
   result := true;
   EXCEPT ON E:Exception do
      begin
      ConsoleLines.Add('Error downloading last release: '+E.Message);
      end;
   END{Try};
FINALLY
MS.Free;
IdSSLIOHandler.Free;
conector.free;
END{try};
End;

END. // END UNIT

