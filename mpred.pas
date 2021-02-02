unit mpRed;

{$mode objfpc}{$H+}

interface

uses
  Classes, forms, SysUtils, MasterPaskalForm, MPTime, IdContext, IdGlobal, mpGUI, mpDisk,
  mpBlock, mpMiner, fileutil, graphics;

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
function UpdateNetworkSumario():NetWorkData;
function UpdateNetworkPendingTrxs():NetworkData;
function UpdateNetworkResumenHash():NetworkData;
Procedure UpdateNetworkData();
Procedure UpdateMyData();
Procedure CheckIncomingUpdateFile(version,hash, clavepublica, firma, namefile: string);
Procedure ActualizarseConLaRed();

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
end;

// Activa el servidor
procedure StartServer();
Begin
if Form1.Server.Active then
   begin
   ConsoleLines.Add(LangLine(160)); //'Server Already active'
   exit;
   end;
   try
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
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo='CLI' then CerrarSlot(contador);
   end;
Form1.Server.Active:=false;
ConsoleLines.Add(LangLine(16));             //Server stopped
U_DataPanel := true;
end;

// Cierra la conexion del slot especificado
procedure CerrarSlot(Slot:integer);
begin
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
  contador : integer = 0;
begin
if Length(listanodos) = 0 then
   begin
   ConsoleLines.Add(LangLine(161));  //'You need add some nodes first'
   exit;
   end;
if not CONNECT_Try then
   begin
   ConsoleLines.Add(LangLine(162)); //'Trying connection to servers'
   end;
CONNECT_Try := true;
if getTotalConexiones >= MaxConecciones then Exit;
while contador < length(ListaNodos) do
   begin
   if ((GetSlotFromIP(ListaNodos[contador].ip)=0) AND (GetFreeSlot()>0)) then
      begin
      ConnectClient(ListaNodos[contador].ip,ListaNodos[contador].port);
      end
   else if GetSlotFromIP(ListaNodos[contador].ip)>0 then
      begin
      //ConsoleLines.Add('Already connected to '+ListaNodos[contador].ip);
      end;
   contador := contador +1;
   end;
CONNECT_LastTime := UTCTime();
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
ConContext := Default(TIdContext);
if Address = '127.0.0.1' then
   begin
   consoleLines.Add(LangLine(29));    //127.0.0.1 is an invalid server address
   exit;
   end;
Slot := GetFreeSlot();
if Slot = 0 then // No free slots
   begin
   result := 0;
   exit;
   end;
CanalCliente[Slot].Host:=Address;
CanalCliente[Slot].Port:=StrToIntDef(Port,8080);
   try
   CanalCliente[Slot].ConnectTimeout:= 200;
   CanalCliente[Slot].Connect;
   SaveConection('SER',Address,ConContext);
   OutText(LangLine(30)+Address,true);          //Connected TO:
   UpdateNodeData(Address,Port);
   CanalCliente[Slot].IOHandler.WriteLn('PSK '+Address);
   CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(3));   // Send PING
   If UserOptions.GetNodes then
     CanalCliente[Slot].IOHandler.WriteLn(ProtocolLine(GetNodes));
   result := Slot;
   Except
   on E:Exception do
      begin
      if E.Message<>'localhost: Connect timed out.' then
        ConsoleLines.Add(Address+': '+E.Message);
      result := 0;
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
for contador := 1 to MaxConecciones do
   begin
   if conexiones[contador].tipo='SER' then CerrarSlot(contador);
   end;
CONNECT_Try := false;
End;

// Lee las lineas linea de los CanalesCliente
procedure ReadClientLines(Slot:int64);
var
  LLine: String;
  UpdateZipName : String = ''; UpdateVersion : String = ''; UpdateHash:string ='';
  UpdateClavePublica :string ='';UpdateFirma : string = '';
  AFileStream : TFileStream;
  BlockZipName : string = '';
begin
if CanalCliente[Slot].IOHandler.InputBufferIsEmpty then
   begin
   CanalCliente[Slot].IOHandler.CheckForDataOnSource(10);
   if CanalCliente[Slot].IOHandler.InputBufferIsEmpty then Exit;
   end;
While not CanalCliente[Slot].IOHandler.InputBufferIsEmpty do
   begin
   LLine := CanalCliente[Slot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
   if GetCommand(LLine) = 'UPDATE' then
      begin
      UpdateVersion := Parameter(LLine,1);
      UpdateHash := Parameter(LLine,2);
      UpdateClavePublica := Parameter(LLine,3);
      UpdateFirma := Parameter(LLine,4);
      UpdateZipName := 'mpupdate'+UpdateVersion+'.zip';
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
      consolelines.Add(LAngLine(74)); //'Headers file received'
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
      BuildHeaderFile();
      ResetMinerInfo();
      LastTimeRequestBlock := 0;
      end
   else
      SlotLines[Slot].Add(LLine);
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
   if Conexiones[contador].tipo = 'SER' then
      begin
      ReadClientLines(contador);
      end;
   if Conexiones[contador].tipo <> '' then
     begin
     if StrToInt64(UTCTime) > StrToInt64(conexiones[contador].lastping)+15 then
        begin
        ConsoleLines.Add(LangLine(32)+conexiones[contador].ip);   //Conection closed: Time Out Auth ->
        CerrarSlot(contador);
        end;
     end;
   end;
End;

// Verifica el estado de la conexion
Procedure VerifyConnectionStatus();
var
  NumeroConexiones : integer = 0;
Begin
if ((CONNECT_Try) and (StrToInt64(UTCTime)>StrToInt64(CONNECT_LastTime)+5)) then ConnectToServers;
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
   ConsoleLines.Add(LangLine(36));   //Updated!
   ResetMinerInfo();
   if StrToInt(NetPendingTrxs.Value)> length(PendingTXs) then
     PTC_SendLine(NetPendingTrxs.Slot,ProtocolLine(5));
   OutgoingMsjs.Add(ProtocolLine(ping));
   Form1.imagenes.GetBitmap(0,ConnectButton.Glyph);
   end;
if MyConStatus = 3 then
   begin

   end;
End;

// Rellena el array consenso
Procedure UpdateConsenso(data:String;Slot:integer);
var
  contador : integer = 0;
  Maximo : integer;
  Existia : boolean = false;
Begin
maximo := length(ArrayConsenso);
while contador < maximo do
   begin
   if Data = ArrayConsenso[contador].value then
      begin
      ArrayConsenso[contador].count := ArrayConsenso[contador].count +1;
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
Higher := -1;
Posicion := -1;
for contador := 0 to length(ArrayConsenso)-1 do
   Begin
   if ArrayConsenso[contador].count > higher then
      begin
      higher := ArrayConsenso[contador].count;
      Posicion := contador;
      end;
   end;
result := Posicion;
End;

function UpdateNetworkLastBlock():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
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

function UpdateNetworkSumario():NetworkData;
var
  contador : integer = 1;
Begin
SetLength(ArrayConsenso,0);
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
NetLastBlock := UpdateNetworkLastBlock; // Buscar cual es el ultimo bloque por consenso
NetSumarioHash := UpdateNetworkSumario; // Busca el hash del sumario por consenso
NetPendingTrxs := UpdateNetworkPendingTrxs;
NetResumenHash := UpdateNetworkResumenHash;
U_DataPanel := true;
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

Procedure CheckIncomingUpdateFile(version,hash, clavepublica, firma, namefile: string);
var
  Proceder : boolean = true;
Begin
if GetAddressFromPublicKey(clavepublica) <> Adminhash then Proceder := false;
if not VerifySignedString(version+' '+hash,firma,clavepublica) then Proceder := false;
if HashMD5File(namefile) <> hash then Proceder := false;
if not proceder then
   begin
   consoleLines.Add(LangLine(37));      //Update file received is wrong
   deletefile(namefile);
   end
else
   begin
   if version <= ProgramVersion then
      begin
      consoleLines.Add(LangLine(38)); //Update file received is obsolete
      deletefile(namefile);
      exit;
      end;
   if UserOptions.Auto_Updater then
         begin
         UnzipBlockFile(namefile,false);
         copyfile(namefile,UpdatesDirectory+namefile);
         deletefile(namefile);
         RunExternalProgram('mpUpdater.exe');
         Application.Terminate;
         end
   else
      begin
      // que hacer si la opcion autopupdate no esta activada
      end;
   end;
End;

// Solicitar los archivos necesarios para actualizarse con la red
Procedure ActualizarseConLaRed();
var
  NLBV : integer = 0; // network last block valur
Begin
NLBV := StrToInt(NetLastBlock.Value);
if ((MyResumenhash <> NetResumenHash.Value) and (NLBV>mylastblock)) then  // solicitar cabeceras de bloque
   begin
   if LastTimeRequestResumen+5 < StrToInt64(UTCTime) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7));
      consolelines.Add(LangLine(163)); //'Headers file requested'
      LastTimeRequestResumen := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock <NLBV)) then  // solicitar hasta 100 bloques
   begin
   if LastTimeRequestBlock+5 < StrToInt64(UTCTime) then
      begin
      PTC_SendLine(NetResumenHash.Slot,ProtocolLine(8));
      consolelines.Add(LangLine(164)+IntToStr(mylastblock)); //'LastBlock requested from block '
      LastTimeRequestBlock := StrToInt64(UTCTime);
      end;
   end
else if ((MyResumenhash = NetResumenHash.Value) and (mylastblock = NLBV) and
        (MySumarioHash<>NetSumarioHash.Value)) then
   begin  // Reconstruir sumario
   RebuildSumario();
   end
End;


END. // END UNIT

