unit mpParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpGUI, mpRed, mpDisk, mpCripto, mpTime, mpblock, mpcoin,
  dialogs, fileutil, forms, idglobal, poolmanage, strutils;

Procedure ProcesarLineas();
function GetOpData(textLine:string):String;
Procedure ParseCommandLine(LineText:string);
Function GetCommand(LineText:String):String;
Function Parameter(LineText:String;ParamNumber:int64):String;
Procedure Addnode(linea:String);
Procedure ShowNodes();
Procedure DeleteNode(Texto:string);
Procedure ShowBots();
Procedure ShowSlots();
Procedure ShowUserOptions();
function GetWalletBalance(): Int64;
Procedure SetGetNodesON();
Procedure SetGetNodesOFF();
Procedure ConnectTo(LineText:string);
Procedure MinerOn();
Procedure MinerOff();
Procedure ToTrayON();
Procedure ToTrayOFF();
Procedure ShowSumary();
Procedure AutoServerON();
Procedure AutoServerOFF();
Procedure AutoConnectON();
Procedure AutoConnectOFF();
Procedure ShowWallet();
Procedure EnviarUpdate(LineText:string);
Procedure AutoUpdateON();
Procedure AutoUpdateOFF();
Procedure UsePoolOn();
Procedure UsePoolOff();
Procedure ImportarWallet(LineText:string);
Procedure ExportarWallet(LineText:string);
Procedure ShowBlchHead();
Procedure SetDefaultAddress(linetext:string);
Procedure ParseShowBlockInfo(LineText:string);
Procedure ShowBlockInfo(numberblock:integer);
Procedure showmd160(linetext:string);
Procedure CustomizeAddress(linetext:string);
Procedure Parse_SendFunds(LineText:string);
Procedure SendFunds(LineText:string);
Procedure ShowHalvings();
Procedure GroupCoins(linetext:string);
Procedure CreateTraslationFile();
Procedure ImportLanguage(linetext:string);
Procedure SetServerPort(LineText:string);
Procedure Sha256(LineText:string);
Procedure TestParser(LineText:String);
Procedure DeleteBot(LineText:String);
Procedure showCriptoThreadinfo();
Procedure SetMiningCPUS(LineText:string);
Procedure Parse_RestartNoso();
Procedure ShowNetworkDataInfo();
Procedure CreatePool(LineText:string);
Procedure ShowPoolInfo();
Procedure JoinPool(LineText:string);
Procedure Deletepool(LineText:string);
Procedure GetOwnerHash(LineText:string);
Procedure CheckOwnerHash(LineText:string);
function AvailableUpdates():string;
Procedure RunUpdate(linea:string);
Procedure ChangePoolPassword(LineText:string);
Procedure ChangePoolFee(LineText:string);
Procedure ChangePoolMembers(LineText:string);
Procedure ChangePoolPayrate(LineText:string);
Procedure PoolExpelMember(LineText:string);
Procedure SendAdminMessage(linetext:string);
Procedure ShowAddressBalance(LineText:string);
Procedure SetReadTimeOutTIme(LineText:string);
Procedure SetConnectTimeOutTIme(LineText:string);
Procedure ShowNetReqs();
Procedure RequestHeaders();

implementation

uses
  mpProtocol, mpMiner;

// Procesa las lineas de la linea de comandos
Procedure ProcesarLineas();
Begin
While ProcessLines.Count > 0 do
   begin
   ParseCommandLine(ProcessLines[0]);
   if ProcessLines.Count>0 then ProcessLines.Delete(0);
   end;
End;

// Elimina el encabezado de una linea de protocolo
function GetOpData(textLine:string):String;
var
  CharPos : integer;
Begin
charpos := pos('$',textline);
result := copy(textline,charpos,length(textline));
End;

Procedure ParseCommandLine(LineText:string);
var
  Command : String;
begin
Command :=GetCommand(Linetext);
if Command = '' then exit;
if not AnsiContainsStr(HideCommands,Uppercase(command)) then ConsoleLines.Add('>> '+Linetext);
if UpperCase(Command) = 'LANG' then Language(linetext)
else if UpperCase(Command) = 'VER' then ConsoleLines.Add(ProgramVersion+SubVersion)
else if UpperCase(Command) = 'SERVERON' then StartServer()
else if UpperCase(Command) = 'SERVEROFF' then StopServer()
else if UpperCase(Command) = 'ADDNODE' then AddNode(linetext)
else if UpperCase(Command) = 'NODES' then ShowNodes()
else if UpperCase(Command) = 'DELNODE' then DeleteNode(linetext)
else if UpperCase(Command) = 'BOTS' then ShowBots()
else if UpperCase(Command) = 'SLOTS' then ShowSlots()
else if UpperCase(Command) = 'CONNECT' then ConnectToServers()
else if UpperCase(Command) = 'DISCONNECT' then CerrarClientes()
else if UpperCase(Command) = 'OFFSET' then consolelines.Add('Server: '+G_NTPServer+SLINEBREAK+LangLine(17)+IntToStr(G_TimeOffSet))
//else if UpperCase(Command) = 'SSLPATH' then consolelines.Add(UserOptions.SSLPath)
else if UpperCase(Command) = 'NEWADDRESS' then NuevaDireccion(linetext)
else if UpperCase(Command) = 'USEROPTIONS' then ShowUserOptions()
else if UpperCase(Command) = 'BALANCE' then ConsoleLines.Add(Int2Curr(GetWalletBalance)+' '+CoinSimbol)
else if UpperCase(Command) = 'GETNODESON' then SetGetNodesON()
else if UpperCase(Command) = 'GETNODESOFF' then SetGetNodesOFF()
else if UpperCase(Command) = 'CONNECTTO' then ConnectTo(Linetext)
else if UpperCase(Command) = 'MINERON' then Mineron()
else if UpperCase(Command) = 'MINEROFF' then Mineroff()
else if UpperCase(Command) = 'SUMARY' then ShowSumary()
else if UpperCase(Command) = 'AUTOSERVERON' then AutoServerON()
else if UpperCase(Command) = 'AUTOSERVEROFF' then AutoServerOFF()
else if UpperCase(Command) = 'AUTOCONNECTON' then AutoConnectON()
else if UpperCase(Command) = 'AUTOCONNECTOFF' then AutoConnectOFF()
else if UpperCase(Command) = 'AUTOUPDATEON' then AutoUpdateON()
else if UpperCase(Command) = 'AUTOUPDATEOFF' then AutoUpdateOFF()
else if UpperCase(Command) = 'SHOWWALLET' then ShowWallet()
else if UpperCase(Command) = 'SENDUPDATE' then EnviarUpdate(LineText)
else if UpperCase(Command) = 'IMPWALLET' then ImportarWallet(LineText)
else if UpperCase(Command) = 'EXPWALLET' then ExportarWallet(LineText)
else if UpperCase(Command) = 'RESUMEN' then ShowBlchHead()
else if UpperCase(Command) = 'SETDEFAULT' then SetDefaultAddress(LineText)
else if UpperCase(Command) = 'LBINFO' then ShowBlockInfo(MyLastBlock)
else if UpperCase(Command) = 'TIMESTAMP' then ConsoleLines.Add(UTCTime)
else if UpperCase(Command) = 'MD160' then showmd160(LineText)
else if UpperCase(Command) = 'UNDONEBLOCK' then UndoneLastBlock  // to be removed
else if UpperCase(Command) = 'CUSTOMIZE' then CustomizeAddress(LineText)
else if UpperCase(Command) = 'SENDTO' then Parse_SendFunds(LineText)
else if UpperCase(Command) = 'HALVING' then ShowHalvings()
else if UpperCase(Command) = 'REBUILDSUMARY' then RebuildSumario(MyLastBlock)
else if UpperCase(Command) = 'GROUPCOINS' then Groupcoins(linetext)
else if UpperCase(Command) = 'GENLANG' then CreateTraslationFile()
else if UpperCase(Command) = 'IMPLANG' then ImportLanguage(LineText)
else if UpperCase(Command) = 'SETPORT' then SetServerPort(LineText)
else if UpperCase(Command) = 'RESETMINER' then ResetMinerInfo
else if UpperCase(Command) = 'SHA256' then Sha256(LineText)
else if UpperCase(Command) = 'TOTRAYON' then ToTrayON()
else if UpperCase(Command) = 'TOTRAYOFF' then ToTrayOFF()
else if UpperCase(Command) = 'CLEAR' then Memoconsola.Lines.clear
else if UpperCase(Command) = 'TP' then TestParser(LineText)
else if UpperCase(Command) = 'DELBOT' then DeleteBot(LineText)
else if UpperCase(Command) = 'CRIPTO' then showCriptoThreadinfo()
else if UpperCase(Command) = 'CPUMINE' then SetMiningCPUS(LineText)
else if UpperCase(Command) = 'BLOCK' then ParseShowBlockInfo(LineText)
//else if UpperCase(Command) = 'TESTNET' then TestNetwork(LineText)
else if UpperCase(Command) = 'RUNDIAG' then RunDiagnostico(LineText)
else if UpperCase(Command) = 'RESTART' then Parse_RestartNoso()
else if UpperCase(Command) = 'SND' then ShowNetworkDataInfo()
else if UpperCase(Command) = 'OSVERSION' then ConsoleLines.Add(OsVersion)
else if UpperCase(Command) = 'SENDMESSAGE' then SendAdminMessage(linetext)
else if UpperCase(Command) = 'MYHASH' then ConsoleLines.Add(HashMD5File('noso.exe'))
else if UpperCase(Command) = 'ADDBOT' then AddNewBot(LineText)
else if UpperCase(Command) = 'SHOWBALANCE' then ShowAddressBalance(LineText)
else if UpperCase(Command) = 'SETRTOT' then SetReadTimeOutTIme(LineText)
else if UpperCase(Command) = 'SETCTOT' then SetConnectTimeOutTIme(LineText)
else if UpperCase(Command) = 'STATUS' then ConsoleLines.Add(GetCurrentStatus(1))
else if UpperCase(Command) = 'OWNER' then GetOwnerHash(LineText)
else if UpperCase(Command) = 'CHECKOWNER' then CheckOwnerHash(LineText)
else if UpperCase(Command) = 'UPDATE' then RunUpdate(LineText)
else if UpperCase(Command) = 'RESTOREBLOCKCHAIN' then RestoreBlockChain()
else if UpperCase(Command) = 'REQHEAD' then RequestHeaders()
else if UpperCase(Command) = 'SAVEADV' then CreateADV(true)
else if UpperCase(Command) = 'PMM' then setlength(PoolServerConex,90)

// POOL RELATED COMMANDS
else if UpperCase(Command) = 'CREATEPOOL' then CreatePool(LineText)
else if UpperCase(Command) = 'POOLINFO' then ShowPoolInfo()
else if UpperCase(Command) = 'DELPOOL' then DeletePool(LineText)
else if UpperCase(Command) = 'STARTPOOLSERVER' then StartPoolServer(poolinfo.Port)
else if UpperCase(Command) = 'USEPOOLON' then UsePoolOn()
else if UpperCase(Command) = 'USEPOOLOFF' then UsePoolOff()
else if UpperCase(Command) = 'POOLPASS' then ChangePoolPassword(LineText)
else if UpperCase(Command) = 'POOLFEE' then ChangePoolFee(LineText)
else if UpperCase(Command) = 'POOLMEMBERS' then ChangePoolMembers(LineText)
else if UpperCase(Command) = 'POOLPAYINTERVAL' then ChangePoolPayrate(LineText)
else if UpperCase(Command) = 'POOLEXPEL' then PoolExpelMember(LineText)
else if UpperCase(Command) = 'SENDPOOLSTEPS' then SendPoolStepsInfo(StrToInt(Parameter(LineText,1)))
else if UpperCase(Command) = 'POOLHASHRATE' then SendPoolHashRateRequest()
else if UpperCase(Command) = 'SAVEPOOLFILES' then SavePoolFiles()

// NETWORK VALUES
else if UpperCase(Command) = 'NETREQS' then ShowNetReqs()
else if UpperCase(Command) = 'NETHASH' then consolelines.Add('Network hashrate: '+IntToStr(networkhashrate))
else if UpperCase(Command) = 'NETPEERS' then consolelines.Add('Network peers: '+IntToStr(networkpeers))

else ConsoleLines.Add(LangLine(0)+Command);  // Unknow command
end;

// Obtiene el comando de una linea
Function GetCommand(LineText:String):String;
var
  Temp : String = '';
  ThisChar : Char;
  Contador : int64 = 1;
Begin
while contador <= Length(LineText) do
   begin
   ThisChar := Linetext[contador];
   if  ThisChar = ' ' then
      begin
      result := temp;
      exit;
      end
   else temp := temp+ ThisChar;
   contador := contador+1;
   end;
Result := Temp;
End;

// Devuelve un parametro del texto
Function Parameter(LineText:String;ParamNumber:int64):String;
var
  Temp : String = '';
  ThisChar : Char;
  Contador : int64 = 1;
  WhiteSpaces : int64 = 0;
  parentesis : boolean = false;
Begin
while contador <= Length(LineText) do
   begin
   ThisChar := Linetext[contador];
   if ((thischar = '(') and (not parentesis)) then parentesis := true
   else if ((thischar = '(') and (parentesis)) then
      begin
      result := '';
      exit;
      end
   else if ((ThisChar = ')') and (parentesis)) then
      begin
      if WhiteSpaces = ParamNumber then
         begin
         result := temp;
         exit;
         end
      else
         begin
         parentesis := false;
         temp := '';
         end;
      end
   else if ((ThisChar = ' ') and (not parentesis)) then
      begin
      WhiteSpaces := WhiteSpaces +1;
      if WhiteSpaces > Paramnumber then
         begin
         result := temp;
         exit;
         end;
      end
   else if ((ThisChar = ' ') and (parentesis) and (WhiteSpaces = ParamNumber)) then
      begin
      temp := temp+ ThisChar;
      end
   else if WhiteSpaces = ParamNumber then temp := temp+ ThisChar;
   contador := contador+1;
   end;
if temp = ' ' then temp := '';
Result := Temp;
End;

// Añade un nodo
Procedure Addnode(linea:String);
var
  ip : String = '';
  port : String = '';
Begin
ip := Parameter(Linea,1);
if not isvalidip(IP) then
  begin
  OutText('Invalid node',false,2);
  exit;
  end;
Port := Parameter(Linea,2);
if ((port = '') or (StrToIntDef(port,-1)<0)) then port := '8080';
if NodeExists(Ip,Port)<0 then
   begin
   UpdateNodeData(Ip,port);
   ConsoleLines.Add(LangLine(41));      //Node added.
   end
else
   begin
   UpdateNodeData(Ip,port); // actualizar la ultima conexion valida
   ConsoleLines.Add(LangLine(42)); //Node already exists.
   end
End;

// muestra los nodos
Procedure ShowNodes();
var
  contador : integer = 0;
Begin
for contador := 0 to length(ListaNodos) - 1 do
   consoleLines.Add(IntToStr(contador)+'- '+Listanodos[contador].ip+':'+Listanodos[contador].port+
   ' '+TimeSinceStamp(CadToNum(Listanodos[contador].LastConexion,0,'STI fails on shownodes')));
End;

// Elimina el nodo indicado por su numero
Procedure DeleteNode(Texto:string);
var
  numero : integer = 0;
  contador : integer = 0;
Begin
numero := StrToIntDef(Parameter(Texto,1),-1);
if ((numero<0) or (numero>length(ListaNodos)-1)) then
   begin
   consolelines.add(LangLine(43)); //Invalid node index.
   exit;
   end
else
   begin
   for contador := numero to length(listanodos)-2 do
      begin
      listanodos[contador].ip:=listanodos[contador+1].ip;
      listanodos[contador].port:=listanodos[contador+1].port;
      listanodos[contador].LastConexion:=listanodos[contador+1].LastConexion;
      end;
   setlength(listanodos,length(listanodos)-1);
   S_NodeData := True;
   ConsoleLines.Add(LangLine(44)+IntToStr(numero));  //Node deleted :
   FillNodeList();
   end;
End;

// muestra los Bots
Procedure ShowBots();
var
  contador : integer = 0;
Begin
for contador := 0 to length(ListadoBots) - 1 do
   consoleLines.Add(IntToStr(contador)+'- '+ListadoBots[contador].ip);
ConsoleLines.Add(IntToStr(length(ListadoBots))+LangLine(45));  // bots registered
End;

// muestra la informacion de los slots
Procedure ShowSlots();
var
  contador : integer = 0;
Begin
ConsoleLines.Add(LangLine(46)); //Number Type ConnectedTo ChannelUsed LinesOnWait SumHash LBHash Offset ConStatus
for contador := 1 to MaxConecciones do
   begin
   ConsoleLines.Add(IntToStr(contador)+' '+conexiones[contador].tipo+
   ' '+conexiones[contador].ip+
   ' '+BoolToStr(CanalCliente[contador].connected,true)+' '+IntToStr(SlotLines[contador].count)+
   ' '+conexiones[contador].SumarioHash+' '+conexiones[contador].LastblockHash+' '+
   IntToStr(conexiones[contador].offset)+' '+IntToStr(conexiones[contador].ConexStatus));
   end;
end;

// Muestras las opciones del usuario
Procedure ShowUserOptions();
Begin
consolelines.Add('Language: '+IdiomasDisponibles[Useroptions.language]);
consolelines.Add('Server Port: '+IntToStr(UserOptions.Port));
consolelines.Add('Get Nodes: '+BoolToStr(UserOptions.GetNodes,true));
//consolelines.Add('OpenSSL Path: '+UserOptions.SSLPath);
consolelines.Add('Wallet: '+UserOptions.Wallet);
consolelines.Add('PoolData: '+UserOptions.PoolInfo);
consolelines.Add('AutoServer: '+BoolToStr(UserOptions.AutoServer,true));
consolelines.Add('AutoConnect: '+BoolToStr(UserOptions.AutoConnect,true));
consolelines.Add('AutoUpdate: '+BoolToStr(UserOptions.Auto_Updater,true));
consolelines.Add('Version Page: '+UserOptions.VersionPage);
consolelines.Add('Mine to pool: '+BoolToStr(UserOptions.UsePool,true));
End;

// devuelve el saldo en satoshis de la cartera
function GetWalletBalance(): Int64;
var
  contador : integer = 0;
  totalEnSumario : Int64 = 0;
Begin
for contador := 0 to length(Listadirecciones)-1 do
   begin
   totalEnSumario := totalEnSumario+Listadirecciones[contador].Balance;
   end;
result := totalEnSumario-MontoOutgoing;
End;

// activa la opcion de usuario para solicitar nodos la conectarse
Procedure SetGetNodesON();
Begin
UserOptions.GetNodes:=true;
S_Options := true;
U_DataPanel := true;
ConsoleLines.Add(LangLine(47)+LangLine(48)); //GetNodes option is now  // ACTIVE
End;

// desactiva la opcion de usuario para solicitar nodos la conectarse
Procedure SetGetNodesOFF();
Begin
UserOptions.GetNodes:=false;
S_Options := true;
U_DataPanel := true;
ConsoleLines.Add(LangLine(47)+LangLine(49)); //GetNodes option is now  // INACTIVE
End;

// Conecta a un server especificado
Procedure ConnectTo(LineText:string);
var
  Ip, Port : String;
Begin
Ip := Parameter(Linetext, 1);
Port := Parameter(Linetext, 2);
if StrToIntDef(Port,-1) = -1 then Port := '8080';
ConnectClient(ip,port);
End;

// activa el minero
Procedure MinerOn();
Begin
Miner_Active := true;
U_Datapanel := true;
ConsoleLines.Add(LangLine(50)+LAngLine(48));   // miner //active
End;

Procedure ToTrayON();
Begin
UserOptions.ToTray :=true;
S_Options := true;
ConsoleLines.Add('Minimize to tray is now '+LangLine(48)); //GetNodes option is now  // INACTIVE
End;

Procedure ToTrayOFF();
Begin
UserOptions.ToTray :=false;
S_Options := true;
ConsoleLines.Add('Minimize to tray is now '+LangLine(49)); //GetNodes option is now  // INACTIVE
End;

// desactiva el minero
Procedure Mineroff();
Begin
Miner_Active := false;
if Miner_IsOn then Miner_IsOn := false;
U_Datapanel := true;
ConsoleLines.Add(LangLine(50)+LAngLine(49));    // miner //inactive
End;

// muestra el sumario completo
Procedure ShowSumary();
var
  contador : integer = 0;
  TotalCoins : int64 = 0;
  EmptyAddresses : int64 = 0;
Begin
For contador := 0 to length(ListaSumario)-1 do
   begin
   {
   consolelines.Add(ListaSumario[contador].Hash+' '+Int2Curr(ListaSumario[contador].Balance)+' '+
      SLINEBREAK+ListaSumario[contador].custom+' '+
      IntToStr(ListaSumario[contador].LastOP)+' '+IntToStr(ListaSumario[contador].Score));
   }
   TotalCOins := totalCoins+ ListaSumario[contador].Balance;
   if ListaSumario[contador].Balance <= 0 then EmptyAddresses +=1;
   end;
consoleLines.Add(IntToStr(Length(ListaSumario))+langline(51)); //addresses
consoleLines.Add(IntToStr(EmptyAddresses)+' empty.'); //addresses
ConsoleLines.Add(Int2Curr(Totalcoins)+' '+CoinSimbol);
End;

Procedure AutoServerON();
Begin
UserOptions.Autoserver := true;
S_Options := true;
ConsoleLines.Add(LangLine(52)+LAngLine(48));   //autoserver //active
End;

Procedure AutoServerOFF();
Begin
UserOptions.Autoserver := false;
S_Options := true;
ConsoleLines.Add(LangLine(52)+LAngLine(49));   //autoserver //inactive
End;

Procedure AutoConnectON();
Begin
UserOptions.AutoConnect := true;
S_Options := true;
ConsoleLines.Add(LangLine(53)+LAngLine(48));     //autoconnect // active
End;

Procedure AutoConnectOFF();
Begin
UserOptions.AutoConnect := false;
S_Options := true;
ConsoleLines.Add(LangLine(53)+LAngLine(49));    //autoconnect // inactive
End;

// muestra las direcciones de la cartera
Procedure ShowWallet();
var
  contador : integer = 0;
Begin
for contador := 0 to length(ListaDirecciones)-1 do
   begin
   consolelines.Add(Listadirecciones[contador].Hash);
   end;
consoleLines.Add(IntToStr(Length(ListaDirecciones))+LangLine(51));
ConsoleLines.Add(Int2Curr(GetWalletBalance)+' '+CoinSimbol);
End;

// enviar archivo de autoupdate
Procedure EnviarUpdate(LineText:string);
var
  Version : string = '';
  FileName : string = '';
  FilenameHash : string = '';
  TextToSend : String = '';
  Contador : integer = 1;
  AFileStream : TFileStream;
  ClavePublica : string = '';
  Firma : string = '';
  Envios : integer = 0;
  FileForSize : File Of byte;
  ByPassed : boolean = false;
Begin
ClavePublica := Parameter (linetext,2);
if GetAddressFromPublicKey(ClavePublica) = Adminhash then
   begin
   Bypassed := true;
   FilenameHash := Parameter (linetext,3);
   Firma := Parameter (linetext,4);
   end;
if ((DireccionEsMia(AdminHash)<0) and(not ByPassed)) then
   begin
   ConsoleLines.Add(LangLine(54)); //Only the Noso developers can do this
   exit;
   end;
version := Parameter (linetext,1);
FileName := 'nosoupdate'+version+'.zip';
if not fileexists(UpdatesDirectory+filename) then
   begin
   ConsoleLines.Add(LangLine(55)+filename);   //The specified zip file not exists:
   exit;
   end;
{temporal para probar como obtener el tamaño del archivo}
Assign (FileForSize,UpdatesDirectory+filename);
  Reset (FileForSize);
  ConsoleLines.Add ('File size in bytes : '+IntToStr(FileSize(FileForSize) div 1024)+' kb');
  Close (FileForSize);
{hasta aqui lo temporal}
if not bypassed then FilenameHash := HashMD5File(UpdatesDirectory+filename);
if not bypassed then ClavePublica := ListaDirecciones[DireccionEsMia(AdminHash)].PublicKey;
if not bypassed then Firma := GetStringSigned(version+' '+FilenameHash,ListaDirecciones[DireccionEsMia(AdminHash)].PrivateKey);
TextToSend := 'UPDATE '+Version+' '+FilenameHash+' '+ClavePublica+' '+firma;
AFileStream := TFileStream.Create(UpdatesDirectory+Filename, fmOpenRead + fmShareDenyNone);
For contador := 1 to maxconecciones do
   begin
   if conexiones[contador].tipo='CLI' then
      begin
      Conexiones[contador].context.Connection.IOHandler.WriteLn(TextToSend);
      Conexiones[contador].context.connection.IOHandler.Write(AFileStream,0,true);
      Envios := envios + 1;
      end;
   if conexiones[contador].tipo='SER' then
      begin
      CanalCliente[contador].IOHandler.WriteLn(TextToSend);
      CanalCliente[contador].IOHandler.Write(AFileStream,0,true);
      Envios := envios + 1;
      end;
   end;
AFileStream.Free;
if envios = 0 then ConsoleLines.Add(LangLine(56)) else ConsoleLines.Add(LangLine(57)+intToStr(envios));   //Can not send the update file // Update file sent to peers:
End;

Procedure AutoUpdateON();
Begin
UserOptions.Auto_Updater := true;
S_Options := true;
ConsoleLines.Add(LangLine(58)+LangLine(48));     //autoupdate //active
End;

Procedure AutoUpdateOFF();
Begin
UserOptions.Auto_Updater := false;
S_Options := true;
ConsoleLines.Add(LangLine(58)+LangLine(49));     //autoupdate //inactive
End;

Procedure UsePoolOn();
Begin
if UserOptions.PoolInfo<>'' then
   begin
   UserOptions.UsePool := true;
   S_Options := true;
   ConsoleLines.Add('Mine for pool is now '+LangLine(48));     //autoupdate //active
   end;
End;

Procedure UsePoolOff();
Begin
UserOptions.UsePool := false;
S_Options := true;
ConsoleLines.Add('Mine for pool is now '+LangLine(49));     //autoupdate //inactive
End;

Procedure ExportarWallet(LineText:string);
var
  destino : string = '';
Begin
destino := Parameter(linetext,1);
destino := StringReplace(destino,'*',' ',[rfReplaceAll, rfIgnoreCase]);
if fileexists(destino+'.pkw') then
   begin
   consolelines.Add('Error: Can not overwrite existing wallets');
   exit;
   end;
if copyfile(useroptions.Wallet,destino+'.pkw',[]) then
   begin
   consolelines.Add('Wallet saved as '+destino+'.pkw');
   end
else
   begin
   consolelines.Add('Failed');
   end;
End;

Procedure ImportarWallet(LineText:string);
var
  Cartera : string = '';
  CarteraFile : file of WalletData;
  DatoLeido : Walletdata;
  Contador : integer = 0;
  Nuevos: integer = 0;
Begin
Cartera := Parameter(linetext,1);
Cartera := StringReplace(Cartera,'*',' ',[rfReplaceAll, rfIgnoreCase]);
if not FileExists(cartera) then
   begin
   consolelines.Add(langLine(60));//Specified wallet file do not exists.
   exit;
   end;
assignfile(CarteraFile,Cartera);
try
reset(CarteraFile);
seek(CarteraFile,0);
Read(CarteraFile,DatoLeido);
if not IsValidAddress(DatoLeido.Hash) then
   begin
   closefile(CarteraFile);
   consolelines.Add('The file is not a valid wallet');
   exit;
   end;
for contador := 0 to filesize(CarteraFile)-1 do
   begin
   seek(CarteraFile,contador);
   Read(CarteraFile,DatoLeido);
   if ((DireccionEsMia(DatoLeido.Hash) < 0) and (IsValidAddress(DatoLeido.Hash))) then
      begin
      setlength(ListaDirecciones,Length(ListaDirecciones)+1);
      ListaDirecciones[length(ListaDirecciones)-1] := DatoLeido;
      Nuevos := nuevos+1;
      end;
   end;
closefile(CarteraFile);
except on E:Exception  do
consolelines.Add(LangLine(134)); //'The file is not a valid wallet'
end;
if nuevos > 0 then
   begin
   OutText(LangLine(135)+IntToStr(nuevos),false,2); //'Addresses imported: '
   UpdateWalletFromSumario;
   Deletefile(MyTrxFilename);
   RebulidTrxThread := Beginthread(tthreadfunc(@NewMyTrx));
   end
else ConsoleLines.Add(LangLine(136));  //'No new addreses found.'
End;

Procedure ShowBlchHead();
var
  Dato: ResumenData;
  Registros : integer = 0;
Begin
consolelines.Add('Block hash - Sumary hash');
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Registros := filesize(FileResumen);
while not eof (fileresumen) do
   begin
   read(fileresumen, dato);
   consolelines.Add(IntToStr(dato.block)+' '+copy(dato.blockhash,1,5)+' '+copy(dato.SumHash,1,5));
   end;
closefile(FileResumen);
Consolelines.Add(IntToStr(Registros)+' registers');
End;

// Cambiar la primera direccion de la wallet
Procedure SetDefaultAddress(linetext:string);
var
  Numero: Integer;
  OldData, NewData: walletData;
Begin
Numero := StrToIntDef(Parameter(linetext,1),-1);
if ((Numero < 0) or (numero > length(ListaDirecciones)-1)) then
   begin
   OutText(LangLine(137),false,2);  //'Invalid address number.'
   exit;
   end
else if numero = 0 then
   begin
   OutText(LangLine(138),false,2); //'Address 0 is already the default.'
   exit;
   end;
OldData := ListaDirecciones[0];
NewData := ListaDirecciones[numero];
ListaDirecciones[numero] := OldData;
ListaDirecciones[0] := NewData;
OutText(LangLine(139)+NewData.Hash,false,2); //'New default address: '
S_Wallet := true;
U_DirPanel := true;
End;

Procedure ParseShowBlockInfo(LineText:string);
var
  blnumber : integer;
Begin
blnumber := StrToIntDef(Parameter(linetext,1),-1);
if (blnumber < 0) or (blnumber>MylastBlock) then
   outtext('Invalid block number')
else ShowBlockInfo(blnumber);
End;

Procedure ShowBlockInfo(numberblock:integer);
var
  Header : BlockHeaderData;
Begin
if fileexists(BlockDirectory+IntToStr(numberblock)+'.blk') then
   begin
   Header := LoadBlockDataHeader(numberblock);
   consolelines.Add('Last block info');
   consolelines.Add('Hash  :       '+HashMD5File(BlockDirectory+IntToStr(numberblock)+'.blk'));
   consolelines.Add('Number:       '+IntToStr(Header.Number));
   consolelines.Add('Time start:   '+IntToStr(Header.TimeStart));
   consolelines.Add('Time end:     '+IntToStr(Header.TimeEnd));
   consolelines.Add('Time total:   '+IntToStr(Header.TimeTotal));
   consolelines.Add('L20 average:  '+IntToStr(Header.TimeLast20));
   consolelines.Add('Transactions: '+IntToStr(Header.TrxTotales));
   consolelines.Add('Difficult:    '+IntToStr(Header.Difficult));
   consolelines.Add('Target:       '+Header.TargetHash);
   consolelines.Add('Solution:     '+Header.Solution);
   consolelines.Add('Last Hash:    '+Header.LastBlockHash);
   consolelines.Add('Next Diff:    '+IntToStr(Header.NxtBlkDiff));
   consolelines.Add('Miner:        '+Header.AccountMiner);
   consolelines.Add('Fees:         '+IntToStr(Header.MinerFee));
   consolelines.Add('Reward:       '+IntToStr(Header.Reward));
   end;
End;

Procedure showmd160(linetext:string);
var
  tohash : string;
Begin
tohash := Parameter(linetext,1);
consolelines.Add(HashMD160String(tohash));
End;

Procedure CustomizeAddress(linetext:string);
var
  address, AddAlias, TrfrHash, OrderHash, CurrTime : String;
  cont : integer;
  procesar : boolean = true;
Begin
address := Parameter(linetext,1);
AddAlias := Parameter(linetext,2);
if DireccionEsMia(address)<0 then
   begin
   consolelines.Add(LAngLine(140));  //'Invalid address'
   procesar := false;
   end;
if ListaDirecciones[DireccionEsMia(address)].Custom <> '' then
   begin
   consolelines.Add(LangLine(141)); //'Address already have a custom alias'
   procesar := false;
   end;
if ( (length(AddAlias)<5) or (length(AddAlias)>40) ) then
   begin
   OutText(LangLine(142),false,2); //'Alias must have between 5 and 40 chars'
   procesar := false;
   end;
if IsValidAddress(addalias) then
   begin
   consolelines.Add(LangLine(143)); //'Alias can not be a valid address'
   procesar := false;
   end;
if ListaDirecciones[DireccionEsMia(address)].Balance < Customizationfee then
   begin
   consolelines.Add(LangLine(144)); //'Insufficient balance'
   procesar := false;
   end;
if AddressAlreadyCustomized(Address) then
   begin
   consolelines.Add(LangLine(141)); //'Address already have a custom alias'
   procesar := false;
   end;
if AddressSumaryIndex(addalias) >= 0 then
   begin
   consolelines.Add('Alias already exists');
   procesar := false;
   end;
for cont := 1 to length(addalias) do
   begin
   if pos(addalias[cont],CustomValid)=0 then
      begin
      consolelines.Add('Invalid character in alias: '+addalias[cont]);
      info('Invalid character in alias: '+addalias[cont]);
      procesar := false;
      end;
   end;
if procesar then
   begin
   CurrTime := UTCTime;
   TrfrHash := GetTransferHash(CurrTime+Address+addalias+IntToStr(MyLastblock));
   OrderHash := GetOrderHash('1'+currtime+TrfrHash);
   AddCriptoOp(2,'Customize this '+address+' '+addalias+'$'+ListaDirecciones[DireccionEsMia(address)].PrivateKey,
           ProtocolLine(9)+    // CUSTOM
           OrderHash+' '+  // OrderID
           '1'+' '+        // OrderLines
           'CUSTOM'+' '+   // OrderType
           CurrTime+' '+   // Timestamp
           'null'+' '+     // concept
           '1'+' '+        // Trxline
           ListaDirecciones[DireccionEsMia(address)].PublicKey+' '+    // sender
           ListaDirecciones[DireccionEsMia(address)].Hash+' '+    // address
           AddAlias+' '+   // receiver
           IntToStr(Customizationfee)+' '+  // Amountfee
           '0'+' '+                         // amount trfr
           '[[RESULT]] '+//GetStringSigned('Customize this '+address+' '+addalias,ListaDirecciones[DireccionEsMia(address)].PrivateKey)+' '+
           TrfrHash);      // trfrhash
   StartCriptoThread();
   end;
End;

// Incluye una solicitud de envio de fondos a la cola de transacciones cripto
Procedure Parse_SendFunds(LineText:string);
Begin
AddCriptoOp(3,linetext,'');
StartCriptoThread();
End;

// Ejecuta una orden de transferencia
Procedure SendFunds(LineText:string);
var
  Destination, amount, concepto : string;
  monto, comision : int64;
  montoToShow, comisionToShow : int64;
  contador : integer;
  Restante : int64;
  ArrayTrfrs : Array of orderdata;
  currtime : string;
  TrxLinea : integer = 0;
  OrderHashString : String;
  OrderString : string;
  AliasIndex : integer;
  Procesar : boolean = true;
Begin
setmilitime('SendFunds',1);
Destination := Parameter(Linetext,1);
amount       := Parameter(Linetext,2);
concepto    := Parameter(Linetext,3);
if ((Destination='') or (amount='')) then
   begin
   consolelines.add(LAngLine(145)); //'Invalid parameters.'
   Procesar := false;
   end;
if not IsValidAddress(Destination) then
   begin
   AliasIndex:=AddressSumaryIndex(Destination);
   if AliasIndex<0 then
      begin
      consolelines.add(LangLine(146)); //'Invalid destination.'
      Procesar := false;
      end
   else Destination := ListaSumario[aliasIndex].Hash;
   end;
monto := StrToInt64Def(amount,-1);
if concepto = '' then concepto := 'null';
if monto<=0 then
   begin
   consolelines.add(LangLine(147)); //'Invalid ammount.'
   Procesar := false;
   end;
if procesar then
   begin
   Comision := GetFee(Monto);
   montoToShow := Monto;
   comisionToShow := Comision;
   Restante := monto+comision;
   if Restante > GetWalletBalance then
      begin
      consolelines.add(LAngLine(148)+Int2curr(Monto+comision));//'Insufficient funds. Needed: '
      Procesar := false;
      end;
   end;
// empezar proceso
if procesar then
   begin
   currtime := UTCTime;
   Setlength(ArrayTrfrs,0);
   Contador := length(ListaDirecciones)-1;
   OrderHashString := currtime;
   while monto > 0 do
      begin
      setmilitime('SendFundsVerify',1);
      if ListaDirecciones[contador].Balance-GetAddressPendingPays(ListaDirecciones[contador].Hash) > 0 then
         begin
         trxLinea := TrxLinea+1;
         Setlength(ArrayTrfrs,length(arraytrfrs)+1);
         ArrayTrfrs[length(arraytrfrs)-1]:= SendFundsFromAddress(ListaDirecciones[contador].Hash,
                                            Destination,monto, comision, Concepto, CurrTime,TrxLinea);
         comision := comision-ArrayTrfrs[length(arraytrfrs)-1].AmmountFee;
         monto := monto-ArrayTrfrs[length(arraytrfrs)-1].AmmountTrf;
         OrderHashString := OrderHashString+ArrayTrfrs[length(arraytrfrs)-1].TrfrID;
         end;
      Contador := contador -1;
      setmilitime('SendFundsVerify',2);
      end;
   for contador := 0 to length(ArrayTrfrs)-1 do
      begin
      ArrayTrfrs[contador].OrderID:=GetOrderHash(IntToStr(trxLinea)+OrderHashString);
      ArrayTrfrs[contador].OrderLines:=trxLinea;
      end;
   consolelines.Add('Send '+Int2Curr(montoToShow)+' fee '+Int2Curr(comisionToShow)+slinebreak+
                    'Order ID: '+GetOrderHash(IntToStr(trxLinea)+OrderHashString));

   OrderString := GetPTCEcn+'ORDER '+IntToStr(trxLinea)+' $';
   for contador := 0 to length(ArrayTrfrs)-1 do
      begin
      OrderString := orderstring+GetStringfromOrder(ArrayTrfrs[contador])+' $';
      end;
   Setlength(orderstring,length(orderstring)-2);
   OutgoingMsjs.Add(OrderString);
   setmilitime('SendFunds',2);
   end // End procesar
else
   begin
   consolelines.Add('Syntax: sendto {destination} {ammount} {concept}');
   end;
End;

// Muestra la escala de halvings
Procedure ShowHalvings();
var
  contador : integer;
  texto : string;
  block1, block2 : integer;
  reward : int64;
  MarketCap : int64 = 0;
Begin
for contador := 0 to HalvingSteps do
   begin
   block1 := BlockHalvingInterval*(contador);
   if block1 = 0 then block1 := 1;
   block2 := (BlockHalvingInterval*(contador+1))-1;
   reward := InitialReward div StrToInt(BMExponente('2',IntToStr(contador)));
   MarketCap := marketcap+(reward*BlockHalvingInterval);
   Texto := LangLine(149)+IntToStr(block1)+LangLine(150)+IntToStr(block2)+': '+Int2curr(reward); //'From block '+' until '
   consolelines.Add(Texto);
   end;
consolelines.Add(LangLine(151)+int2curr(0)); //'And then '
MarketCap := MarketCap+PremineAmount-InitialReward; // descuenta una recompensa inicial x bloque 0
ConsoleLines.Add(LangLine(152)+int2curr(MarketCap)); //'Final supply: '
End;

// Muestra y procesa el monto a agrupar en la direccion principal
Procedure GroupCoins(linetext:string);
var
  cont : integer;
  proceder : string = '';
  Total : int64 = 0;
Begin
Proceder := Parameter(linetext,1);
if length(listaDirecciones)>0 then
  for cont := 1 to length(listaDirecciones)-1 do
    Total += GetAddressBalance(ListaDirecciones[cont].Hash);
ConsoleLines.Add(LangLine(153)+Int2curr(Total)+' '+Coinsimbol); //'Coins to group: '
if uppercase(Proceder) = 'DO' then
   begin
   if Total = 0 then
     ConsoleLines.Add(LangLine(154)) //'You do not have coins to group.'
   else
     ProcessLines.Add('SENDTO '+Listadirecciones[0].Hash+' '+IntToStr(GetMaximunToSend(Total)));
   end;
End;

// Crea un arhivo de texto para exportar para las traducciones
Procedure CreateTraslationFile();
var
  NewFile : textfile;
  contador : integer;
Begin
try
if fileexists(TranslationFilename) then Deletefile(TranslationFilename);
assignfile(NewFile,TranslationFilename);
rewrite(NewFile);
writeln(NewFile,'**'+coinname+LangLine(155)+'**'); //' wallet translation file'
writeln(NewFile,'**'+LangLine(156)+'**'); //'Translate each line into the blank line below it'
writeln(NewFile,'**'+LangLine(157)+'**');
for contador := 1 to DLSL.Count-1 do
   begin
   writeln(NewFile,DLSL[contador]);
   if contador < DLSL.Count-1 then WriteLn(Newfile)
   else Write(Newfile,'')
   end;
closefile(NewFile);
consolelines.Add(LangLine(158)); //'Translation file generated.'
   except on E:Exception do
   consolelines.Add(LangLine(159));  //'Something went wrong'
   end;
End;

// Importar un archivo de traduccion
Procedure ImportLanguage(linetext:string);
var
  Nombrearchivo : string;
  Archivo : Textfile;
  Idiomas : integer;
  Original : string[255];
  linea : string[255];
  NombreIdioma : string;
  arrayofstrings : array of string;
  archivo2 : file of string[255];
  contador : integer;
  ListaDeIdiomas : array of string;
  LineasViejas : array of string;
Begin
Nombrearchivo := parameter(linetext,1);
Nombrearchivo := StringReplace(Nombrearchivo,'*',' ',[rfReplaceAll, rfIgnoreCase]);
if ((nombrearchivo='') or (not fileexists(Nombrearchivo))) then
   begin
   consolelines.Add('Invalid file name');
   exit;
   end;
assignfile(archivo,Nombrearchivo);
reset(archivo);
readln(archivo);readln(archivo);readln(archivo);readln(archivo);
// leer nombre del nuevo idioma
readln(archivo,NombreIdioma);
if NombreIDioma = '' then
  begin
  closefile(archivo);
  consolelines.Add('Empty file');
  exit;
  end;
setlength(arrayofstrings,0);
// leer lineas del nuevo idioma
while not eof(archivo) do
   begin
   ReadLn(archivo,original);
   ReadLn(archivo,linea);
   if ((Original[1] = ' ') and (Linea[1] <> ' ')) then
     linea := ' '+linea;
   if ((Original[length(original)] = ' ') and (Linea[length(linea)] <> ' ')) then
     linea := linea+' ';
   insert(linea,arrayofstrings,length(arrayofstrings));
   end;
closefile(archivo);
if length(arrayofstrings) <> DLSL.Count-2 then
   begin
   consolelines.Add('The file is not valid. Lines/Expected: '+
                    IntToStr(length(arrayofstrings))+'/'+IntToStr(DLSL.Count-2));
   exit;
   end;
assignfile(archivo2,LanguageFileName);
reset(archivo2);
read(archivo2,linea); // leer la cantidad de idiomas ya instalados
Idiomas := StrToIntDef(linea,1)+1;
setlength(ListaDeIdiomas,0);
// leer los idiomas preexistentes
for contador := 1 to idiomas-1 do
   begin
   seek(archivo2,contador);
   read(archivo2,linea);
   if linea = NombreIdioma then
      begin
      closefile(archivo2);
      consolelines.Add(Nombreidioma+' already loaded');
      exit;
      end;
   insert(linea,ListaDeIdiomas,length(ListaDeIdiomas));
   end;
insert(NombreIdioma,ListaDeIdiomas,length(ListaDeIdiomas));
// leer las lineas preexistentes
Setlength(LineasViejas,0);
for contador := idiomas to filesize(archivo2)-1 do
   begin
   seek(archivo2,contador);
   read(archivo2,linea);
   insert(linea,LineasViejas,length(LineasViejas));
   end;
closefile(archivo2);
insert(arrayofstrings,LineasViejas,length(LineasViejas));
insert(LineasViejas,ListaDeIdiomas,length(ListaDeIdiomas));
rewrite(archivo2);
write(archivo2,intToStr(idiomas));
for contador := 1 to length(ListaDeIdiomas) do
   begin
   seek(archivo2,contador);
   write(archivo2,ListaDeIdiomas[contador-1]);
   end;
closefile(archivo2);
CargarIdioma(idiomas-1);
LangSelect.Items.Clear;
for contador := 0 to IdiomasDisponibles.Count-1 do
   LangSelect.Items.Add(IdiomasDisponibles[contador]);
LangSelect.ItemIndex := idiomas-1;
InicializarGUI();
ConsoleLines.Add('Loaded: '+NombreIdioma);
End;

// cambia el puerto de escucha
Procedure SetServerPort(LineText:string);
var
  NewPort:string = '';
Begin
NewPort := parameter(linetext,1);
if ((StrToIntDef(NewPort,0) < 1) or (StrToIntDef(NewPort,0)>65535)) then
   begin
   Consolelines.Add('Invalid Port');
   exit;
   end;
UserOptions.Port :=StrToIntDef(NewPort,0);
OutText('New listening port: '+NewPort,false,2);
S_Options := true;
End;

// regresa el sha256 de una cadena
Procedure Sha256(LineText:string);
var
  TextToSha : string = '';
Begin
TextToSha :=  parameter(linetext,1);
consolelines.Add(HashSha256String(TextToSha));
End;

// prueba la lectura de parametros de la linea de comandos
Procedure TestParser(LineText:String);
var
  contador : integer = 1;
  continuar : boolean;
  parametro : string;
Begin
consolelines.Add(Parameter(linetext,0));
continuar := true;
repeat
   begin
   parametro := Parameter(linetext,contador);
   if parametro = '' then continuar := false
   else
     begin
     consolelines.Add(inttostr(contador)+' '+parametro);
     contador := contador+1;
     end;
   end;
until not continuar
End;

// Borra la IP enviada de la lista de bots si existe
Procedure DeleteBot(LineText:String);
var
  IPBot : String;
  contador : integer;
Begin
IPBot := Parameter(linetext,1);
if IPBot = '' then
   begin
   consolelines.Add('Invalid IP');
   exit;
   end;
if uppercase(IPBot) = 'ALL' then
   begin
   SetLength(ListadoBots,0);
   LastBotClear := UTCTime;
   S_BotData := true;
   consolelines.Add('All bots deleted');
   exit;
   end;
for contador := 0 to length(ListadoBots)-1 do
   begin
   if ListadoBots[contador].ip = IPBot then
      begin
      Delete(ListadoBots,Contador,1);
      S_BotData := true;
      consolelines.Add(IPBot+' deleted from bot list');
      exit;
      end;
   end;
consolelines.Add('IP do not exists in Bot list');
End;

Procedure showCriptoThreadinfo();
Begin
consolelines.Add(Booltostr(CriptoThreadRunning,true)+' '+
                 inttostr(length(CriptoOpstipo))+' '+
                 inttostr(length(CriptoOpsoper))+' '+
                 inttostr(length(CriptoOpsResu)));
End;

Procedure SetMiningCPUS(LineText:string);
var
  numero : integer;
Begin
numero := StrToIntDef(Parameter(linetext,1),0);
if numero < 1 then
  begin
  outtext('You must set 1 or more CPUs for mining',false,2);
  exit;
  end;
if numero > G_CpuCount then
  begin
  outtext('Maximun number of CPUs: '+IntToStr(G_CpuCount),false,2);
  exit;
  end;
G_MiningCPUs := numero;
outtext('Mining CPUs set to: '+IntToStr(numero),false,2);
if G_MiningCPUs > 2 then
  consolelines.Add('*** WARNING ***'+slinebreak+'Using more than 2 CPUs to mine is NOT RECOMMENDED'+slinebreak+
                   'Not support if you decide to mine with '+IntToStr(G_MiningCPUs)+' CPUs'+slinebreak+
                   '***************');
DefCPUs := G_MiningCPUs;
ResetMinerInfo;
KillAllMiningThreads;
Miner_Active := false;
if Miner_IsOn then Miner_IsOn := false;
U_Datapanel := true;
End;

Procedure Parse_RestartNoso();
Begin
RestartNosoAfterQuit := true;
CerrarPrograma();
End;

// Muestra la informacion de la red
// Este procedimiento debe amppliarse para que muestre la informacion solicitada
Procedure ShowNetworkDataInfo();
Begin
consolelines.Add('Network last block');
consolelines.Add('Value: '+NetLastBlock.Value);
consolelines.Add('Count: '+IntToStr(NetLastBlock.Count));
consolelines.Add('Percent: '+IntToStr(NetLastBlock.porcentaje));
consolelines.Add('Slot: '+IntToStr(NetLastBlock.slot));
End;

Procedure ShowPoolInfo();
var
  dato : PoolInfoData;
Begin
if fileexists(PoolInfoFilename) then
   begin
   Dato := GetPoolInfoFromDisk();
   consolelines.Add('My Pool Info: ');
   Consolelines.Add('Name: '+dato.Name);
   Consolelines.Add('Address: '+dato.Direccion);
   Consolelines.Add('Fee: '+IntToStr(dato.Porcentaje)+'/10000');
   Consolelines.Add('MaxMembers: '+IntToStr(dato.MaxMembers));
   consolelines.add('Members: '+IntToStr(length(ArrayPoolMembers)));
   Consolelines.Add('Port: '+IntToStr(dato.Port));
   Consolelines.Add('PayRatio: '+IntToStr(dato.TipoPago));
   consolelines.Add('Listening: '+BoolToStr(form1.PoolServer.Active,true));
   end
else consolelines.Add('You do not own a pool.');
End;

// Crea un pool de mineria
Procedure CreatePool(LineText:string);
var
  nombre:string;
  direccionminado: string;
  porcentaje: integer;
  maxmembers : integer;
  port:integer;
  TipoPago : integer;
  Password : string;
  Parametrosok : integer = 0;
  MiPrefijo : string;
Begin
if fileexists(PoolInfoFilename) then
  begin
  consolelines.Add('You already owns a minning pool');
  exit;
  end;
nombre := Parameter(linetext,1);
port := StrToIntDef(Parameter(linetext,2),8082);
Password := Parameter(linetext,3);
direccionminado := Listadirecciones[0].Hash;
porcentaje := 100;
maxmembers := Pool_Max_Members;
TipoPago := 100;
if ( (Length(nombre)<3) or (length(nombre)>15) ) then Parametrosok := 1;
if ((port<1) or (port>65535)) then Parametrosok := 2;
if port = UserOptions.Port then Parametrosok := 3;
if ( (length(Password)<1) or (length(Password)>10) ) then Parametrosok := 4;
if parametrosok = 0 then
   begin
   CrearArchivoPoolInfo(nombre,direccionminado,porcentaje,maxmembers,port,tipopago,password);
   CrearArchivoPoolMembers();
   ConsoleLines.Add('Mining pool created');
   MiPrefijo := PoolAddNewMember(direccionminado);
   useroptions.PoolInfo:=direccionminado+' '+MiPrefijo+' '+'localhost '+IntToStr(port)+' '+
      direccionminado+' '+nombre+' '+password;
   UserOptions.UsePool := true;
   GuardarOpciones;
   RestartNosoAfterQuit := true;
   CerrarPrograma();
   end
else
   begin
   consolelines.Add('CreatePool: Invalid parameters'+slinebreak+
   'createpool {name} {port} {password}');
   end;
End;

// Try to join a pool
Procedure JoinPool(LineText:string);
var
  Ip,direccion,password : string;
  Port : integer;
  parametrosok : boolean = true;
Begin
consolelines.Add('Deprecated since 0.2.0J');
consolelines.Add('Use NosoMiner to mine in a pool');
exit;
if UserOptions.poolinfo = '' then
   begin
   ip := Parameter(linetext,1);
   port := StrToIntDef(Parameter(linetext,2),0);
   direccion := Parameter(linetext,3);
   if UpperCase(direccion) = 'DEFAULT' then direccion := Listadirecciones[0].Hash;
   password := Parameter(linetext,4);
   //if not IsValidIP(ip) then parametrosok := false;
   if ((port<1) or (port>65535)) then Parametrosok := false;
   if DireccionEsMia(direccion)<0 then Parametrosok := false;
   if parametrosok then
      begin
      //ConnectPoolClient(ip,port,password,direccion);
      //SendPoolMessage(password+' '+direccion+' JOIN '+ip+' '+IntToStr(port));
      consolelines.Add('Join pool request sent');
      end
   else consolelines.Add('Join Pool: Invalid parameters'+slinebreak+'joinpool {ip} {port} {address} {password}');
   end
else consolelines.Add('You already are in a pool');
End;

Procedure DeletePool(LineText:string);
var
  confirmation : String;
  confirmed : boolean = false;
  saving : string;
  savefiles: boolean = true;
Begin
confirmation := parameter (linetext,1);
if UpperCase(confirmation)= 'YES' then confirmed := true;
saving := UpperCase(parameter(linetext,2));
if saving = 'NOSAVE' then savefiles := false;
if confirmed then
   begin
   if savefiles then
      begin
      SavePoolFiles();
      end;
   if fileexists(PoolInfoFilename) then
      begin
      deletefile(PoolInfoFilename);
      consolelines.Add('Own pool deleted');
      deletefile(PoolMembersFilename);
      if form1.PoolServer.Active then form1.PoolServer.Active := false;
      setlength(arraypoolmembers,0);
      Miner_OwnsAPool := false;
      end
   else consolelines.add('You do no owns a pool data');
   if useroptions.PoolInfo<>'' then
      begin
      useroptions.PoolInfo:='';
      consolelines.Add('Pool connection data deleted');
      S_Options := true;
      end
   else consolelines.Add('You are not a pool member');
   UserOptions.UsePool := false;
   S_Options := true;
   if formpool.Visible then formpool.Visible:=false;
   end
else
   begin
   consolelines.Add('delpool {yes} [NOSAVE]');
   end;
End;

Procedure GetOwnerHash(LineText:string);
var
  direccion, currtime : string;
Begin
direccion := parameter(linetext,1);
if DireccionEsMia(direccion)<0 then
  begin
  consolelines.Add('Invalid address');
  end
else
   begin
   currtime := UTCTime;
   consolelines.Add(direccion+' owner cert'+slinebreak+
                    ListaDirecciones[DireccionEsMia(direccion)].PublicKey+':'+currtime+':'+GetStringSigned('I OWN THIS ADDRESS '+direccion+currtime,ListaDirecciones[DireccionEsMia(direccion)].PrivateKey));
   end;
End;

Procedure CheckOwnerHash(LineText:string);
var
  data, pubkey, direc,firmtime,firma : string;
Begin
data := parameter(LineText,1);
data := StringReplace(data,':',' ',[rfReplaceAll, rfIgnoreCase]);
pubkey := Parameter(data,0);
firmtime := Parameter(data,1);
firma := Parameter(data,2);
direc := GetAddressFromPublicKey(pubkey);
if ListaSumario[AddressSumaryIndex(direc)].custom <> '' then direc := ListaSumario[AddressSumaryIndex(direc)].custom;
if VerifySignedString('I OWN THIS ADDRESS '+direc+firmtime,firma,pubkey) then
   consolelines.Add(direc+' verified '+TimeSinceStamp(StrToInt64(firmtime))+' ago.')
else consolelines.Add('Invalid verification');
End;

// devuelve una cadena con los updates disponibles
function AvailableUpdates():string;
var
  updatefiles : TStringList;
  contador : integer = 0;
  resultado :  string = '';
  version : string;
Begin
updatefiles := TStringList.Create;
FindAllFiles(updatefiles, UpdatesDirectory, 'nosoupdate*.zip', false);
while contador < updatefiles.Count do
   begin
   version :=copy(updatefiles[contador],28,5);
   if version > ProgramVersion then Resultado := Resultado + version +' ';
   contador += 1;
   end;
updatefiles.Free;
if length(resultado) >0 then setlength(resultado,length(resultado)-1);
result := resultado;
End;

Procedure RunUpdate(linea:string);
var
  version : string;
Begin
version := parameter(linea,1);
if fileexists(UpdatesDirectory+'nosoupdate'+version+'.zip') then
   begin
   UnzipBlockFile(UpdatesDirectory+'nosoupdate'+version+'.zip',false);
   copyfile(UpdatesDirectory+'noso'+version+'.exe','noso'+version+'.exe');
   useroptions.JustUpdated:=true;
   GuardarOpciones();
   CrearRestartfile();
   EjecutarAutoUpdate(version);
   Application.Terminate;
   end
else consolelines.add('Invalid update');
End;

Procedure ChangePoolPassword(LineText:string);
var
  oldpass, newpass : string;
Begin
if not Miner_OwnsAPool then
   begin
   Consolelines.Add('Only pool admin can change password');
   exit;
   end;
oldpass := Parameter(LineText,1);
newpass := Parameter(LineText,2);
if length(newpass) > 10 then setlength(newpass,10);
if oldpass <> MyPoolData.Password then
   begin
   Consolelines.Add('Invalid password');
   exit;
   end;
if Miner_OwnsAPool then // si posse el pool, cambiar ambas
  begin
  PoolInfo.PassWord:=newpass;
  GuardarArchivoPoolInfo;
  GetPoolInfoFromDisk();
  end;
MyPoolData.Password:= newpass;
SaveMyPoolData;
End;

Procedure ChangePoolFee(LineText:string);
var
  newfee : integer;
Begin
newfee := StrToIntDef(Parameter(linetext,1),-1);
if (not Miner_OwnsAPool) then
   begin
   Consolelines.Add('Only pool admin can change fees');
   exit;
   end
else
   begin
   if newfee<0 then
      begin
      Consolelines.Add('Invalid pool fee');
      exit;
      end;
   poolinfo.Porcentaje:=newfee;
   GuardarArchivoPoolInfo;
   GetPoolInfoFromDisk();
   EdBuFee.Caption:=IntToStr(poolinfo.Porcentaje);
   end;
End;

Procedure ChangePoolMembers(LineText:string);
var
  newmembers: integer;
Begin
newmembers := StrToIntDef(Parameter(linetext,1),-1);
if (not Miner_OwnsAPool) then
   begin
   Consolelines.Add('Only pool admin can change max members');
   exit;
   end
else
   begin
   if ( (newmembers<length(arraypoolmembers)) or (newmembers>Pool_Max_Members) ) then
      begin
      Consolelines.Add('Invalid number of members');
      exit;
      end;
   poolinfo.MaxMembers:=newmembers;
   GuardarArchivoPoolInfo;
   GetPoolInfoFromDisk();
   EdMaxMem.Caption:=IntToStr(poolinfo.MaxMembers);
   end;
End;

Procedure ChangePoolPayrate(LineText:string);
var
  newpayrate: integer;
Begin
newpayrate := StrToIntDef(Parameter(linetext,1),-1);
if (not Miner_OwnsAPool) then
   begin
   Consolelines.Add('Only pool admin can change pay interval');
   exit;
   end
else
   begin
   if ( (newpayrate<1) or (newpayrate>1008) ) then
      begin
      Consolelines.Add('Invalid number for pay interval');
      exit;
      end;
   poolinfo.TipoPago:=newpayrate;
   GuardarArchivoPoolInfo;
   GetPoolInfoFromDisk();
   EdPayRate.Caption:=IntToStr(poolinfo.TipoPago);
   end;
End;

Procedure PoolExpelMember(LineText:string);
var
  member: string;
  MemberPosition : integer;
  MemberBalance : Int64;
  paybalance : string;
Begin
member := Parameter(linetext,1);
paybalance := Uppercase(Parameter(linetext,2));
if Paybalance <> 'YES' then paybalance := 'NO';
if DireccionEsMia(member)>=0 then
   begin
   consolelines.Add('You can not expel yourself from your pool');
   exit;
   end;
MemberPosition := GetPoolMemberPosition(member);
if (not Miner_OwnsAPool) then
   begin
   Consolelines.Add('Only pool admin can expel members');
   exit;
   end
else
   begin
   if (MemberPosition<0) then
      begin
      Consolelines.Add('User do not exists in the pool');
      exit;
      end;
   MemberBalance := GetPoolMemberBalance(member);
   if ( (MemberBalance>0) and (paybalance='YES') ) then // Enviar pago si posee saldo
      begin
      Processlines.Add('sendto '+member+' '+IntToStr(GetMaximunToSend(MemberBalance))+' EXPEL_POOLPAYMENT_'+PoolInfo.Name);
      ClearPoolUserBalance(member);
      ConsoleLines.Add('Pool expel payment sent: '+inttoStr(GetMaximunToSend(MemberBalance)));
      tolog('Pool expel payment sent: '+int2curr(GetMaximunToSend(MemberBalance)));
      PoolMembersTotalDeuda := GetTotalPoolDeuda();
      end;
   arraypoolmembers[MemberPosition].Direccion:='';
   arraypoolmembers[MemberPosition].prefijo := '';
   ArrayPoolMembers[MemberPosition].Deuda:=0;
   ArrayPoolMembers[MemberPosition].Soluciones:=0;
   ArrayPoolMembers[MemberPosition].LastPago:=0;
   ArrayPoolMembers[MemberPosition].TotalGanado:=0;
   ArrayPoolMembers[MemberPosition].LastSolucion:=0;
   ArrayPoolMembers[MemberPosition].LastEarned:=0;
   S_PoolMembers := true;
   Tolog('POOLEXPEL: '+member+SLINEBREAK+'BALANCE: '+int2curr(MemberBalance)+' PAID: '+paybalance);
   end;
End;

Procedure SendAdminMessage(linetext:string);
var
  mensaje,currtime, firma, hashmsg : string;
Begin
if (DireccionEsMia(AdminHash)<0) then
   begin
   ConsoleLines.Add(LangLine(54)); //Only the Noso developers can do this
   exit;
   end;
Mensaje := parameter(linetext,1);
currtime := UTCTime;
firma := GetStringSigned(currtime+mensaje,ListaDirecciones[DireccionEsMia(AdminHash)].PrivateKey);
hashmsg := HashMD5String(currtime+mensaje+firma);
mensaje := StringReplace(mensaje,' ','_',[rfReplaceAll, rfIgnoreCase]);
OutgoingMsjs.Add(GetPTCEcn+'ADMINMSG '+currtime+' '+mensaje+' '+firma+' '+hashmsg);
mensaje := StringReplace(mensaje,'_',' ',[rfReplaceAll, rfIgnoreCase]);
ConsoleLines.Add('Message sent: '+mensaje);
End;

Procedure ShowAddressBalance(LineText:string);
var
  addtoshow : string;
  sumposition : integer;
  onsumary, pending : int64;
Begin
addtoshow := parameter(LineText,1);
sumposition := AddressSumaryIndex(addtoshow);
if sumposition<0 then
   consolelines.Add('Address do not exists in sumary.')
else
   begin
   onsumary := GetAddressBalance(addtoshow);
   pending := GetAddressPendingPays(addtoshow);
   consolelines.Add('Address  : '+addtoshow+slinebreak+
                    'Sumary   : '+Int2curr(onsumary)+slinebreak+
                    'Pending  : '+Int2curr(pending)+slinebreak+
                    'Available: '+int2curr(onsumary-pending));
   end;
End;

Procedure SetReadTimeOutTIme(LineText:string);
var
  newvalue : integer;
Begin
newvalue := StrToIntDef(parameter(LineText,1),-1);
if newvalue < 0 then consolelines.Add('ReadTimeOutTime= '+IntToStr(ReadTimeOutTIme))
else
  begin
  ReadTimeOutTIme := newvalue;
  Consolelines.Add('ReadTimeOutTime set to '+IntToStr(newvalue));
  end;
End;

Procedure SetConnectTimeOutTIme(LineText:string);
var
  newvalue : integer;
Begin
newvalue := StrToIntDef(parameter(LineText,1),-1);
if newvalue < 0 then consolelines.Add('ConnectTimeOutTime= '+IntToStr(ConnectTimeOutTIme))
else
  begin
  ConnectTimeOutTIme := newvalue;
  Consolelines.Add('ConnectTimeOutTime set to '+IntToStr(newvalue));
  end;
End;

Procedure ShowNetReqs();
var
  contador : integer;
Begin
if length(ArrayNetworkRequests)>0 then
   begin
   consolelines.Add('Tipo TimeStamp Block Hash');
   for contador := 0 to length(ArrayNetworkRequests)-1 do
      begin
      consolelines.Add(IntToStr(ArrayNetworkRequests[contador].tipo)+' '+IntToStr(ArrayNetworkRequests[contador].timestamp)+' '+
         IntToStr(ArrayNetworkRequests[contador].block)+' '+ArrayNetworkRequests[contador].hashreq);
      end;
   end;
End;

Procedure RequestHeaders();
Begin
PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7));
End;

END. // END UNIT

