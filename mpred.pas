unit mpRed;

{$mode objfpc}{$H+}

interface

uses
  Classes, forms, SysUtils, MasterPaskalForm, MPTime, IdContext, IdGlobal, mpGUI, mpDisk,
  mpBlock, mpMiner, fileutil, graphics,  dialogs,poolmanage, strutils, mpcoin;

function GetSlotFromIP(Ip:String):int64;
function BotExists(IPUser:String):Boolean;
function NodeExists(IPUser,Port:String):integer;
function SaveConection(tipo,ipuser:String;contextdata:TIdContext):integer;
procedure StartServer();
procedure StopServer();
procedure CerrarSlot(Slot:integer);
function BorrarSlot(tipo,ipuser:string):boolean;
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
Procedure UpdateNetworkData();
Procedure UpdateMyData();
Procedure CheckIncomingUpdateFile(version,hash, clavepublica, firma, namefile: string);
Procedure ActualizarseConLaRed();
Procedure AddNewBot(linea:string);
function GetOutGoingConnections():integer;
function GetIncomingConnections():integer;
Procedure SendNetworkRequests(timestamp,direccion:string;block:integer);
function GetOrderDetails(orderid:string):orderdata;

implementation

Uses
  mpParser, mpProtocol, mpCripto;

// RETURNS THE SLOT OF THE GIVEN IP
function GetSlotFromIP(Ip:String):int64;
var
  contador : integer;
Begin
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].ip=ip then
      begin
      result := contador;
      exit;
      end;
   end;
Result := 0;
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

// Activa el servidor
procedure StartServer();
Begin
KeepServerOn := true;
if Form1.Server.Active then
   begin
   ConsoleLines.Add(LangLine(160)); //'Server Already active'
   exit;
   end;
   try
   LastTryServerOn := StrToInt64(UTCTime);
   Form1.Server.Bindings.Clear;
   Form1.Server.DefaultPort:=UserOptions.Port;
   Form1.Server.Active:=true;
   ConsoleLines.Add(LangLine(14)+IntToStr(UserOptions.Port));   //Server ENABLED. Listening on port
   U_DataPanel := true;
   except
   on E : Exception do
     ConsoleLines.Add(LangLine(15));       //Unable to start Server
   end;
end;

// Apaga el servidor
procedure StopServer();
var
  Contador: integer;
Begin
SetCurrentJob('StopServer',true);
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo='CLI' then CerrarSlot(contador);
   end;
Form1.Server.Active:=false;
ConsoleLines.Add(LangLine(16));             //Server stopped
U_DataPanel := true;
KeepServerOn := false;
SetCurrentJob('StopServer',false);
end;

// Cierra la conexion del slot especificado
procedure CerrarSlot(Slot:integer);
begin
SetCurrentJob('CerrarSlot',true);
   try
   if conexiones[Slot].tipo='CLI' then
      begin
      SlotLines[slot].Clear;
      Conexiones[Slot].context.Connection.IOHandler.InputBuffer.Clear;
      Conexiones[Slot].context.Connection.Disconnect;
      Conexiones[Slot] := Default(conectiondata);
      end;
   if conexiones[Slot].tipo='SER' then
      begin
      SlotLines[slot].Clear;
      CanalCliente[Slot].IOHandler.InputBuffer.Clear;
      CanalCliente[Slot].Disconnect;
      Conexiones[Slot] := Default(conectiondata);
      end;
   Except on E:Exception do
     begin
     ToLog('Error: Closing slot '+IntToStr(Slot)+SLINEBREAK+E.Message);
     end;
   end;
SetCurrentJob('CerrarSlot',false);
end;

// ANTICUADO
// Borra el slot de una conexion determinada para poder reusarlo
function BorrarSlot(tipo,ipuser:string):boolean;
var
  contador : int64 = 1;
begin
result := false;
while contador < MaxConecciones+1 do
   begin
   if ((Conexiones[contador].tipo=tipo) and (Conexiones[contador].ip=ipuser)) then
      begin
      Conexiones[contador] := Default(conectiondata);
      result := true;
      break;
      end;
   contador := contador+1;
   end;
end;

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
if Length(listanodos) = 0 then
   begin
   ConsoleLines.Add(LangLine(161));  //'You need add some nodes first'
   CONNECT_Try := false;
   proceder := false;
   end;
if not CONNECT_Try then
   begin
   ConsoleLines.Add(LangLine(162)); //'Trying connection to servers'
   CONNECT_Try := true;
   end;
if GetOutGoingConnections >= MaxOutgoingConnections then proceder := false;
if getTotalConexiones >= MaxConecciones then Proceder := false;
if proceder then
   begin
   Repeat
   rannumber := random(length(ListaNodos));
   if ((GetSlotFromIP(ListaNodos[rannumber].ip)=0) AND (GetFreeSlot()>0)) then
      begin
      ConnectClient(ListaNodos[rannumber].ip,ListaNodos[rannumber].port);
      intentado := true;
      end;
   intentos+=1;
   until ((Intentado) or (intentos = 5));
   {
   while contador < length(ListaNodos) do
      begin
      if ((GetSlotFromIP(ListaNodos[contador].ip)=0) AND (GetFreeSlot()>0)) then
         begin
         if GetOutGoingConnections < MaxOutgoingConnections then
            ConnectClient(ListaNodos[contador].ip,ListaNodos[contador].port);
         end
      else if GetSlotFromIP(ListaNodos[contador].ip)>0 then
         begin
         //ConsoleLines.Add('Already connected to '+ListaNodos[contador].ip);
         end;
      contador := contador +1;
      end;
   }
   end;
CONNECT_LastTime := UTCTime();
SetCurrentJob('ConnectToServers',false);
end;

// regresa el primer slot dispoinible, o 0 si no hay ninguno
function GetFreeSlot():integer;
var
  contador : integer = 1;
begin
for contador := 1 to MaxConecciones do
   begin
   if Conexiones[contador].tipo = '' then
      begin
      result := contador;
      exit;
      end;
   end;
result := 0;
end;

// Conecta un cliente
function ConnectClient(Address,Port:String):integer;
var
  Slot : integer = 0;
  ConContext : TIdContext; // EMPTY
Begin
SetCurrentJob('ConnectClient',true);
ConContext := Default(TIdContext);
if Address = '127.0.0.1' then
   begin
   consoleLines.Add(LangLine(29));    //127.0.0.1 is an invalid server address
   SetCurrentJob('ConnectClient',false);
   exit;
   end;
Slot := GetFreeSlot();
if Slot = 0 then // No free slots
   begin
   result := 0;
   SetCurrentJob('ConnectClient',false);
   exit;
   end;
CanalCliente[Slot].Host:=Address;
CanalCliente[Slot].Port:=StrToIntDef(Port,8080);
   try
   CanalCliente[Slot].ConnectTimeout:= ConnectTimeOutTime;
   CanalCliente[Slot].Connect;
   SaveConection('SER',Address,ConContext);
   OutText(LangLine(30)+Address,true);          //Connected TO:
   UpdateNodeData(Address,Port);
   CanalCliente[Slot].IOHandler.WriteLn('PSK '+Address+' '+ProgramVersion);
   CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(3));   // Send PING
   If UserOptions.GetNodes then
     CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(GetNodes));
   result := Slot;
   SetCurrentJob('ConnectClient',false);
   Except
   on E:Exception do
      begin
      if E.Message<>'localhost: Connect timed out.' then
        ConsoleLines.Add(Address+': '+E.Message);
      result := 0;
      SetCurrentJob('ConnectClient',false);
      exit;
      end;
   end;
End;

// Devuelve el numero de conexiones activas
function GetTotalConexiones():integer;
var
  Resultado : integer = 0;
  Contador : integer = 0;
Begin
for contador := 1 to MaxConecciones do
   begin
   if ((conexiones[contador].tipo='SER') and (not CanalCliente[contador].connected)) then
      begin
      ConsoleLines.Add(LangLine(31)+conexiones[contador].ip);  //Conection lost to
      cerrarslot(contador);
      end;
   if conexiones[contador].tipo <> '' then resultado := resultado + 1;
   end;
result := resultado;
End;

// Cierra todas las conexiones salientes
Procedure CerrarClientes();
var
  Contador: integer;
Begin
SetCurrentJob('CerrarClientes',true);
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo='SER' then CerrarSlot(contador);
   end;
CONNECT_Try := false;
SetCurrentJob('CerrarClientes',false);
End;

// Lee las lineas linea de los CanalesCliente
procedure ReadClientLines(Slot:int64);
var
  LLine: String;
  UpdateZipName : String = ''; UpdateVersion : String = ''; UpdateHash:string ='';
  UpdateClavePublica :string ='';UpdateFirma : string = '';
  AFileStream : TFileStream;
  BlockZipName : string = '';
  Continuar : boolean = true;
begin
SetCurrentJob('ReadClientLines',true);
if CanalCliente[Slot].IOHandler.InputBufferIsEmpty then
   begin
   CanalCliente[Slot].IOHandler.CheckForDataOnSource(ReadTimeOutTIme);
   if CanalCliente[Slot].IOHandler.InputBufferIsEmpty then
      begin
      SetCurrentJob('ReadClientLines',false);
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
         AFileStream := TFileStream.Create(ResumenFilename, fmCreate);
         CanalCliente[Slot].IOHandler.ReadStream(AFileStream);
         AFileStream.Free;
         consolelines.Add(LAngLine(74)+': '+copy(HashMD5File(ResumenFilename),1,5)); //'Headers file received'
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
         SetCurrentJob('ReadClientLines',false);
         exit;
         end;
      end;
      end;

   end;
SetCurrentJob('ReadClientLines',false);
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
   if Conexiones[contador].tipo = 'SER' then
      begin
      ReadClientLines(contador);
      end;
   if Conexiones[contador].tipo <> '' then
     begin
     if StrToInt64(UTCTime) > StrToInt64Def(conexiones[contador].lastping,0)+15 then
        begin
        ConsoleLines.Add(LangLine(32)+conexiones[contador].ip);   //Conection closed: Time Out Auth ->
        CerrarSlot(contador);
        end;
     end;
   end;
SetCurrentJob('LeerLineasDeClientes',false);
End;

// Verifica el estado de la conexion
Procedure VerifyConnectionStatus();
var
  NumeroConexiones : integer = 0;
Begin
SetCurrentJob('VerifyConnectionStatus',true);
if ( (CONNECT_Try) and (StrToInt64(UTCTime)>StrToInt64Def(CONNECT_LastTime,StrToInt64(UTCTime))+5) ) then ConnectToServers;
NumeroConexiones := GetTotalConexiones;
if NumeroConexiones = 0 then  // Desconeectado
   begin
   MyConStatus := 0;
   if Form1.Server.Active then
      begin
      if ConnectButton.Caption='' then
        begin
        ConnectButton.Caption:=' ';
        Form1.imagenes.GetBitmap(1,ConnectButton.Glyph);
        end
      else
         begin
         Form1.imagenes.GetBitmap(2,ConnectButton.Glyph);
         ConnectButton.Caption:='';
         end;
      end
   else Form1.imagenes.GetBitmap(2,ConnectButton.Glyph);
   if STATUS_Connected then
      begin
      STATUS_Connected := false;
      consolelines.Add(LangLine(33));       //Disconnected
      G_TotalPings := 0;
      Miner_IsOn := false;
      NetSumarioHash.Value:='';
      NetLastBlock.Value:='?';
      NetResumenHash.Value:='';
      NetPendingTrxs.Value:='';
      U_Datapanel:= true;
      SetLength(PendingTXs,0);
      StopPoolServer;
      Form1.imagenes.GetBitmap(2,ConnectButton.Glyph);
      end;
   // Resetear todos los valores
   end;
if ((NumeroConexiones>0) and (NumeroConexiones<MinConexToWork) and (MyConStatus = 0)) then // Conectando
   begin
   MyConStatus:=1;
   G_LastPing := StrToInt64(UTCTime);
   ConsoleLines.Add(LangLine(34)); //Connecting...
   Form1.imagenes.GetBitmap(2,ConnectButton.Glyph);
   end;
if MyConStatus > 0 then
   begin
   if G_LastPing + 5 < StrToInt64(UTCTime) then
      begin
      G_LastPing := StrToInt64(UTCTime);
      OutgoingMsjs.Add(ProtocolLine(ping));
      end;
   SendMesjsSalientes();
   end;
if ((NumeroConexiones>=MinConexToWork) and (MyConStatus<2) and (not STATUS_Connected)) then
   begin
   STATUS_Connected := true;
   MyConStatus := 2;
   ConsoleLines.Add(LangLine(35));     //Connected
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
   ConsoleLines.Add(LangLine(36));   //Updated!
   ResetMinerInfo();
   ResetPoolMiningInfo();
   if ((Miner_OwnsAPool) and (Miner_Active) and(not Form1.PoolServer.Active)) then // Activar el pool propio si se posee uno
      begin
      StartPoolServer(Poolinfo.Port);
      if Form1.PoolServer.Active then consolelines.Add(PoolInfo.Name+' pool server is listening')
      else consolelines.Add('Unable to star pool server');
      end;
   if StrToInt(NetPendingTrxs.Value)> length(PendingTXs) then
      PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));
   OutgoingMsjs.Add(ProtocolLine(ping));
   Form1.imagenes.GetBitmap(0,ConnectButton.Glyph);
   end;
if MyConStatus = 3 then
   begin
   if ( (IntToStr(MyLastBlock) <> NetLastBlock.Value) or (MySumarioHash<>NetSumarioHash.Value) or
      (MyResumenhash <> NetResumenHash.Value) ) then // desincronizado
      Begin
      SynchWarnings +=1;
      if SynchWarnings = 50 then
         begin
         MyConStatus := 2;
         UndoneLastBlock;
         setlength(PendingTxs,0);
         consolelines.Add('***WARNING SYNCHRONIZATION***');
         end;
      end
   else SynchWarnings := 0;
   if ((Miner_OwnsAPool) and (not Form1.PoolServer.Active)) then // Activar el pool propio si se posee uno
      begin
      if LastTryStartPoolServer+5 < StrToInt64(UTCTIME) then
         begin
         StartPoolServer(Poolinfo.Port);
         LastTryStartPoolServer := StrToInt64(UTCTIME);
         if Form1.PoolServer.Active then consolelines.Add(PoolInfo.Name+' pool server is listening')
         else consolelines.Add('Unable to start pool server');
         end;
      end;
   if ((Miner_OwnsAPool) and (Form1.PoolServer.Active) and (LastPoolHashRequest+5<StrToInt64(UTCTime))) then
      begin
      ProcessLinesAdd('POOLHASHRATE');
      end;
   end;
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
   if conexiones[contador].tipo<> '' then
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
   if conexiones[contador].tipo<> '' then
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
   if conexiones[contador].tipo<> '' then
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
   if conexiones[contador].tipo<> '' then
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
   if conexiones[contador].tipo<> '' then
      begin
      UpdateConsenso(conexiones[contador].ResumenHash, contador);
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
U_DataPanel := true;
SetCurrentJob('UpdateNetworkData',false);
// Si lastblock y sumario no estan actualizados solicitarlos
End;

// Actualiza mi informacion para compoartirla en la red
Procedure UpdateMyData();
Begin
MySumarioHash := HashMD5File(SumarioFilename);
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MyResumenHash := HashMD5File(ResumenFilename);
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
   consoleLines.Add(LangLine(38)); //Update file received is obsolete
   deletefile(namefile);
   exit;
   end;
if fileexists(UpdatesDirectory+namefile) then
   begin
   consoleLines.Add('Update file already exists'); //Update file received is obsolete
   deletefile(namefile);
   exit;
   end;
if not proceder then
   begin
   consoleLines.Add(LangLine(37));      //Update file received is wrong
   deletefile(namefile);
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
         Application.Terminate;
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
NLBV := StrToInt(NetLastBlock.Value);
if ((MyResumenhash <> NetResumenHash.Value) and (NLBV>mylastblock)) then  // solicitar cabeceras de bloque
   begin
   if LastTimeRequestResumen+5 < StrToInt64(UTCTime) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7)); // GetResumen
      consolelines.Add(LangLine(163)); //'Headers file requested'
      LastTimeRequestResumen := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock <NLBV)) then  // solicitar hasta 100 bloques
   begin
   if LastTimeRequestBlock+5 < StrToInt64(UTCTime) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(8)); // lastblock
      consolelines.Add(LangLine(164)+IntToStr(mylastblock)); //'LastBlock requested from block '
      LastTimeRequestBlock := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value) and (not SumaryRebuilded)) then
   begin  // Reconstruir sumario
   RebuildSumario(MyLastBlock);
   SumaryRebuilded:= true;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value) and (SumaryRebuilded)) then
   begin  // Blockchain status issue

   //RestoreBlockChain();
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
   consolelines.Add('Invalid IP');
   exit;
   end;
UpdateBotData(iptoadd);
if GetSlotFromIP(iptoadd)>0 then CerrarSlot(GetSlotFromIP(iptoadd));
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
OutgoingMsjs.Add(texttosend);
UpdateMyRequests(1,timestamp,block, hashreq, hashvalue);
consolelines.Add('hashrate starts in '+IntToStr(Miner_LastHashRate));
tipo := 2; // peers
hashreq := HashMD5String( IntToStr(tipo)+timestamp+direccion+IntToStr(block)+'1');
hashvalue := HashMD5String('1');
texttosend := GetPTCEcn+'NETREQ 2 '+timestamp+' '+direccion+' '+IntToStr(block)+' '+
   hashreq+' '+hashvalue+' '+'1';  // tipo 2: peers
OutgoingMsjs.Add(texttosend);
UpdateMyRequests(2,timestamp,block, hashreq, hashvalue);
consolelines.Add('peers starts in 1');
End;

function GetOrderDetails(orderid:string):orderdata;
var
  counter,counter2 : integer;
  orderfound : boolean = false;
  resultorder : orderdata;
  ArrTrxs : BlockOrdersArray;
Begin
setmilitime('GetOrderDetails',1);
resultorder := default(orderdata);
result := resultorder;
if length(PendingTxs)>0 then
   for counter := 0 to length(PendingTxs)-1 do
      begin
      if PendingTxs[counter].OrderID = orderid then
         begin
         resultorder.Block := PendingTxs[counter].Block;
         resultorder.Concept:=PendingTxs[counter].Concept;
         resultorder.TimeStamp:=PendingTxs[counter].TimeStamp;
         resultorder.receiver:=PendingTxs[counter].receiver;
         resultorder.AmmountTrf:=resultorder.AmmountTrf+PendingTxs[counter].AmmountTrf;
         orderfound := true;
         end;
      end;
if orderfound then result := resultorder
else
   begin
   for counter := mylastblock downto 1 do
      begin
      ArrTrxs := GetBlockTrxs(counter);
      if length(ArrTrxs)>0 then
         begin
         for counter2 := 0 to length(ArrTrxs)-1 do
            begin
            if ArrTrxs[counter2].OrderID = orderid then
               begin
               resultorder.Block := ArrTrxs[counter2].Block;
               resultorder.Concept:=ArrTrxs[counter2].Concept;
               resultorder.TimeStamp:=ArrTrxs[counter2].TimeStamp;
               resultorder.receiver:=ArrTrxs[counter2].receiver;
               resultorder.AmmountTrf:=resultorder.AmmountTrf+ArrTrxs[counter2].AmmountTrf;
               orderfound := true;
               end;
            end;
         end;
      if orderfound then break;
      end;
   end;
result := resultorder;
setmilitime('GetOrderDetails',2);
End;

END. // END UNIT

