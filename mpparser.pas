unit mpParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpGUI, mpRed, mpDisk, nosotime, mpblock, mpcoin,
  dialogs, fileutil, forms, idglobal, strutils, mpRPC, DateUtils, Clipbrd,translation,
  idContext, math, mpMN, MPSysCheck, nosodebug, nosogeneral, nosocrypto, nosounit, nosoconsensus;

procedure ProcessLinesAdd(const ALine: String);
procedure OutgoingMsjsAdd(const ALine: String);
function OutgoingMsjsGet(): String;

Procedure ProcesarLineas();
function GetOpData(textLine:string):String;
Procedure ParseCommandLine(LineText:string);
procedure NuevaDireccion(linetext:string);
Procedure ShowNodes();
Procedure ShowBots();
Procedure ShowSlots();
Procedure ShowUser_Options();
function GetWalletBalance(): Int64;
Procedure ConnectTo(LineText:string);
Procedure ToTrayON();
Procedure ToTrayOFF();
Procedure AutoServerON();
Procedure AutoServerOFF();
Procedure AutoConnectON();
Procedure AutoConnectOFF();
Procedure ShowWallet();
Procedure ImportarWallet(LineText:string);
Procedure ExportarWallet(LineText:string);
Procedure ShowBlchHead(number:integer);
Procedure SetDefaultAddress(linetext:string);
Procedure ParseShowBlockInfo(LineText:string);
Procedure ShowBlockInfo(numberblock:integer);
Procedure CustomizeAddress(linetext:string);
Procedure Parse_SendFunds(LineText:string);
function SendFunds(LineText:string;showOutput:boolean=true):string;
Procedure Parse_SendGVT(LineText:string);
Function SendGVT(LineText:string;showOutput:boolean=true):string;
Procedure ShowHalvings();
Procedure SetServerPort(LineText:string);
Procedure TestParser(LineText:String);
Procedure DeleteBot(LineText:String);
Procedure showCriptoThreadinfo();
Procedure Parse_RestartNoso();
Procedure ShowNetworkDataInfo();
Procedure GetOwnerHash(LineText:string);
Procedure CheckOwnerHash(LineText:string);
function AvailableUpdates():string;
Procedure RunUpdate(linea:string);
Procedure SendAdminMessage(linetext:string);
Procedure SetReadTimeOutTIme(LineText:string);
Procedure SetConnectTimeOutTIme(LineText:string);
Procedure RequestHeaders();
Procedure RequestSumary();
Procedure ShowOrderDetails(LineText:string);
Procedure ExportAddress(LineText:string);
Procedure ShowAddressInfo(LineText:string);
Procedure ShowAddressHistory(LineText:string);
Procedure ShowTotalFees();
function ShowPrivKey(linea:String;ToConsole:boolean = false):String;
Procedure TestNetwork(LineText:string);
Procedure ShowPendingTrxs();
Procedure WebWallet();
Procedure ExportKeys(linea:string);

// CONSULTING
Function MainNetHashrate(blocks:integer = 100):int64;
Procedure ListGVTs();

// 0.2.1 DEBUG
Procedure ShowBlockPos(LineText:string);
Procedure ShowBlockMNs(LineText:string);
Procedure showgmts(LineText:string);
Procedure ShowSystemInfo(Linetext:string);

// EXCHANGE
Procedure PostOffer(LineText:String);

Procedure DebugTest(linetext:string);
Procedure DebugTest2(linetext:string);

Procedure totallocked();
Procedure ShowSumary();

// CONSENSUS

Procedure ShowConsensus();

implementation

uses
  mpProtocol;

// **************************
// *** CRITICIAL SECTIONS ***
// **************************

// Adds a line to ProcessLines thread safe
Procedure ProcessLinesAdd(const ALine: String);
Begin
EnterCriticalSection(CSProcessLines);
   TRY
   ProcessLines.Add(ALine);
   EXCEPT ON E:Exception do
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on PROCESSLINESADD: '+E.Message);
   END; {TRY}
LeaveCriticalSection(CSProcessLines);
End;

// Adds a line to OutgoingMsjs thread safe
procedure OutgoingMsjsAdd(const ALine: String);
Begin
EnterCriticalSection(CSOutgoingMsjs);
   TRY
   OutgoingMsjs.Add(ALine);
   EXCEPT ON E:Exception do
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on OutgoingMsjsAdd: '+E.Message);
   END{Try};
LeaveCriticalSection(CSOutgoingMsjs);
End;

// Gets a line from OutgoingMsjs thread safe
function OutgoingMsjsGet(): String;
var
  Linea : String;
Begin
Linea := '';
EnterCriticalSection(CSOutgoingMsjs);
TRY
Linea := OutgoingMsjs[0];
OutgoingMsjs.Delete(0);
EXCEPT ON E:Exception do
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error extracting outgoing line: '+E.Message);
END{Try};
LeaveCriticalSection(CSOutgoingMsjs);
result := linea;
End;

// Procesa las lineas de la linea de comandos
Procedure ProcesarLineas();
Begin
While ProcessLines.Count > 0 do
   begin
   ParseCommandLine(ProcessLines[0]);
   if ProcessLines.Count>0 then
     begin
     EnterCriticalSection(CSProcessLines);
     try
        ProcessLines.Delete(0);
     Except on E:Exception do
        begin
        ShowMessage ('Your wallet just exploded and we will close it for your security'+slinebreak+
                    'Error deleting line 0 from ProcessLines');
        halt(0);
        end;
     end;
     LeaveCriticalSection(CSProcessLines);
     end;
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
  Counter : integer;
  LItem   : TSummaryData;
begin
Command :=Parameter(Linetext,0);
if not AnsiContainsStr(HideCommands,Uppercase(command)) then AddLineToDebugLog('Console','>> '+Linetext);
if UpperCase(Command) = 'VER' then AddLineToDebugLog('console',ProgramVersion+SubVersion)
else if UpperCase(Command) = 'SERVERON' then StartServer()
else if UpperCase(Command) = 'SERVEROFF' then StopServer()
else if UpperCase(Command) = 'FORCESERVER' then ForceServer()
else if UpperCase(Command) = 'NODES' then ShowNodes()
else if UpperCase(Command) = 'BOTS' then ShowBots()
else if UpperCase(Command) = 'SLOTS' then ShowSlots()
else if UpperCase(Command) = 'CONNECT' then ConnectToServers()
else if UpperCase(Command) = 'DISCONNECT' then CerrarClientes()
else if UpperCase(Command) = 'OFFSET' then AddLineToDebugLog('console','Server: '+NosoT_LastServer+SLINEBREAK+
  'Time offset seconds: '+IntToStr(NosoT_TimeOffset)+slinebreak+'Last update : '+TimeSinceStamp(NosoT_LastUpdate))
else if UpperCase(Command) = 'NEWADDRESS' then NuevaDireccion(linetext)
else if UpperCase(Command) = 'USEROPTIONS' then ShowUser_Options()
else if UpperCase(Command) = 'BALANCE' then AddLineToDebugLog('console',Int2Curr(GetWalletBalance)+' '+CoinSimbol)
else if UpperCase(Command) = 'CONNECTTO' then ConnectTo(Linetext)
else if UpperCase(Command) = 'AUTOSERVERON' then AutoServerON()
else if UpperCase(Command) = 'AUTOSERVEROFF' then AutoServerOFF()
else if UpperCase(Command) = 'AUTOCONNECTON' then AutoConnectON()
else if UpperCase(Command) = 'AUTOCONNECTOFF' then AutoConnectOFF()
else if UpperCase(Command) = 'SHOWWALLET' then ShowWallet()
else if UpperCase(Command) = 'IMPWALLET' then ImportarWallet(LineText)
else if UpperCase(Command) = 'EXPWALLET' then ExportarWallet(LineText)
else if UpperCase(Command) = 'RESUMEN' then ShowBlchHead(StrToIntDef(Parameter(Linetext,1),MyLastBlock))
else if UpperCase(Command) = 'SETDEFAULT' then SetDefaultAddress(LineText)
else if UpperCase(Command) = 'LBINFO' then ShowBlockInfo(MyLastBlock)
else if UpperCase(Command) = 'TIMESTAMP' then AddLineToDebugLog('console',UTCTimeStr)
else if UpperCase(Command) = 'UNDOBLOCK' then UndoneLastBlock()  // to be removed
else if UpperCase(Command) = 'CUSTOMIZE' then CustomizeAddress(LineText)
else if UpperCase(Command) = 'SENDTO' then Parse_SendFunds(LineText)
else if UpperCase(Command) = 'SENDGVT' then Parse_SendGVT(LineText)
else if UpperCase(Command) = 'HALVING' then ShowHalvings()
else if UpperCase(Command) = 'SETPORT' then SetServerPort(LineText)
else if UpperCase(Command) = 'SHA256' then AddLineToDebugLog('console',HashSha256String(Parameter(LineText,1)))
else if UpperCase(Command) = 'MD5' then AddLineToDebugLog('console',HashMD5String(Parameter(LineText,1)))
else if UpperCase(Command) = 'MD160' then AddLineToDebugLog('console',HashMD160String(Parameter(LineText,1)))
else if UpperCase(Command) = 'TOTRAYON' then ToTrayON()
else if UpperCase(Command) = 'TOTRAYOFF' then ToTrayOFF()
else if UpperCase(Command) = 'CLEAR' then form1.Memoconsola.Lines.clear
else if UpperCase(Command) = 'TP' then TestParser(LineText)
else if UpperCase(Command) = 'DELBOT' then DeleteBot(LineText)
else if UpperCase(Command) = 'CRIPTO' then showCriptoThreadinfo()
else if UpperCase(Command) = 'BLOCK' then ParseShowBlockInfo(LineText)
else if UpperCase(Command) = 'TESTNET' then TestNetwork(LineText)
else if UpperCase(Command) = 'RUNDIAG' then RunDiagnostico(LineText)
else if UpperCase(Command) = 'RESTART' then Parse_RestartNoso()
else if UpperCase(Command) = 'SND' then ShowNetworkDataInfo()
else if UpperCase(Command) = 'OSVERSION' then AddLineToDebugLog('console',OsVersion)
else if UpperCase(Command) = 'DIRECTIVE' then SendAdminMessage(linetext)
else if UpperCase(Command) = 'MYHASH' then AddLineToDebugLog('console',HashMD5File('noso.exe'))
else if UpperCase(Command) = 'ADDBOT' then AddNewBot(LineText)
else if UpperCase(Command) = 'SETRTOT' then SetReadTimeOutTIme(LineText)
else if UpperCase(Command) = 'SETCTOT' then SetConnectTimeOutTIme(LineText)
else if UpperCase(Command) = 'STATUS' then AddLineToDebugLog('console',GetCurrentStatus(1))
else if UpperCase(Command) = 'GETCERT' then GetOwnerHash(LineText)
else if UpperCase(Command) = 'CHECKCERT' then CheckOwnerHash(LineText)
else if UpperCase(Command) = 'UPDATE' then RunUpdate(LineText)
else if UpperCase(Command) = 'RESTOREBLOCKCHAIN' then RestoreBlockChain()
else if UpperCase(Command) = 'RESTORESUMARY' then RestoreSumary(StrToIntDef(Parameter(LineText,1),0))
else if UpperCase(Command) = 'REQHEAD' then RequestHeaders()
else if UpperCase(Command) = 'REQSUM' then RequestSumary()
else if UpperCase(Command) = 'SAVEADV' then CreateADV(true)
else if UpperCase(Command) = 'ORDER' then ShowOrderDetails(LineText)
else if UpperCase(Command) = 'ORDERSOURCES' then AddLineToDebugLog('console',GetOrderSources(Parameter(LineText,1)))
else if UpperCase(Command) = 'EXPORTADDRESS' then ExportAddress(LineText)
else if UpperCase(Command) = 'ADDRESS' then ShowAddressInfo(LineText)
else if UpperCase(Command) = 'HISTORY' then ShowAddressHistory(LineText)
else if UpperCase(Command) = 'TOTALFEES' then ShowTotalFees()
else if UpperCase(Command) = 'SUPPLY' then AddLineToDebugLog('console','Current supply: '+Int2Curr(GetSupply(MyLastBlock)))
else if UpperCase(Command) = 'GMTS' then showgmts(LineText)
else if UpperCase(Command) = 'SHOWPRIVKEY' then ShowPrivKey(LineText, true)
else if UpperCase(Command) = 'SHOWPENDING' then ShowPendingTrxs()
else if UpperCase(Command) = 'WEBWAL' then WebWallet()
else if UpperCase(Command) = 'EXPKEYS' then ExportKeys(LineText)
else if UpperCase(Command) = 'CHECKUPDATES' then AddLineToDebugLog('console',GetLastRelease)
else if UpperCase(Command) = 'ZIPSUMARY' then ZipSumary()
else if UpperCase(Command) = 'ZIPHEADERS' then ZipHeaders()
else if UpperCase(Command) = 'GETPOS' then AddLineToDebugLog('console', GetPoSPercentage(StrToIntdef(Parameter(linetext,1),Mylastblock)).ToString )
else if UpperCase(Command) = 'GETMNS' then AddLineToDebugLog('console', GetMNsPercentage(StrToIntdef(Parameter(linetext,1),Mylastblock)).ToString )
else if UpperCase(Command) = 'CLOSESTARTON' then WO_CloseStart := true
else if UpperCase(Command) = 'CLOSESTARTOFF' then WO_CloseStart := false
else if UpperCase(Command) = 'DT' then DebugTest(LineText)
else if UpperCase(Command) = 'TT' then DebugTest2(LineText)
else if UpperCase(Command) = 'BASE58SUM' then AddLineToDebugLog('console',BMB58resumen(parameter(linetext,1)))
else if UpperCase(Command) = 'NOSOHASH' then AddLineToDebugLog('console',Nosohash(parameter(linetext,1)))
else if UpperCase(Command) = 'PENDING' then AddLineToDebugLog('console',PendingRawInfo)
else if UpperCase(Command) = 'HEADER' then AddLineToDebugLog('console',ShowBlockHeaders(StrToIntDef(parameter(linetext,1),-1)))
else if UpperCase(Command) = 'HEADSIZE' then AddLineToDebugLog('console',GetHeadersSize.ToString)

// New system

else if UpperCase(Command) = 'SUMARY' then ShowSumary()
else if UpperCase(Command) = 'REBUILDSUM' then RebuildSummary()
else if UpperCase(Command) = 'CHECKHEADERS' then BuildHeaderFile(StrToIntDef(parameter(linetext,1),0),StrToIntDef(parameter(linetext,2),-1))
else if UpperCase(Command) = 'REBUILDHEADERS' then RebuildHeadersFile()

// CONSULTING
else if UpperCase(Command) = 'LISTGVT' then ListGVTs()
else if UpperCase(Command) = 'SYSTEM' then ShowSystemInfo(Linetext)
else if UpperCase(Command) = 'NOSOCFG' then AddLineToDebugLog('console',GetNosoCFGString)
else if UpperCase(Command) = 'FUNDS' then AddLineToDebugLog('console','Project funds: '+Int2curr(GetAddressAvailable('NpryectdevepmentfundsGE')))

// 0.2.1 DEBUG
else if UpperCase(Command) = 'BLOCKPOS' then ShowBlockPos(LineText)
else if UpperCase(Command) = 'BLOCKMNS' then ShowBlockMNs(LineText)
else if UpperCase(Command) = 'MYIP' then AddLineToDebugLog('console',GetMiIP)
else if UpperCase(Command) = 'SHOWUPDATES' then AddLineToDebugLog('console',StringAvailableUpdates)
else if UpperCase(Command) = 'SETMODE' then SetCFGData(parameter(linetext,1),0)
else if UpperCase(Command) = 'ADDNODE' then AddCFGData(parameter(linetext,1),1)
else if UpperCase(Command) = 'DELNODE' then RemoveCFGData(parameter(linetext,1),1)
else if UpperCase(Command) = 'ADDPOOL' then AddCFGData(parameter(linetext,1),3)
else if UpperCase(Command) = 'DELPOOL' then RemoveCFGData(parameter(linetext,1),3)
else if UpperCase(Command) = 'RESTORECFG' then RestoreCFGData()
else if UpperCase(Command) = 'ADDNOSOPAY' then AddCFGData(parameter(linetext,1),6)
else if UpperCase(Command) = 'DELNOSOPAY' then RemoveCFGData(parameter(linetext,1),6)
else if UpperCase(Command) = 'ISALLSYNCED' then AddLineToDebugLog('console',IsAllsynced.ToString)
else if UpperCase(Command) = 'FREEZED' then Totallocked()

// 0.4.0
else if UpperCase(Command) = 'CONSENSUS' then ShowConsensus()
else if UpperCase(Command) = 'VALIDATE' then AddLineToDebugLog('console',BoolToStr(ValidateAddressOnDisk(parameter(linetext,1)),true))
// P2P
else if UpperCase(Command) = 'PEERS' then AddLineToDebugLog('console','Server list: '+IntToStr(form1.ClientsCount)+'/'+IntToStr(GetIncomingConnections))

// RPC
else if UpperCase(Command) = 'SETRPCPORT' then SetRPCPort(LineText)
else if UpperCase(Command) = 'RPCON' then SetRPCOn()
else if UpperCase(Command) = 'RPCOFF' then SetRPCOff()

//EXCHANGE
else if UpperCase(Command) = 'POST' then PostOffer(LineText)

else AddLineToDebugLog('console','Unknown command: '+Command);  // Unknow command
end;

// Crea una nueva direccion y la añade a listadirecciones
procedure NuevaDireccion(linetext:string);
var
  cantidad : integer;
  cont : integer;
Begin
AddCRiptoOp(1,'','');
sleep(1);
End;

// muestra los nodos
Procedure ShowNodes();
var
  contador : integer = 0;
Begin
for contador := 0 to length(ListaNodos) - 1 do
   AddLineToDebugLog('console',IntToStr(contador)+'- '+Listanodos[contador].ip+':'+Listanodos[contador].port+
   ' '+TimeSinceStamp(StrToInt64Def(Listanodos[contador].LastConexion,0)));
End;

// muestra los Bots
Procedure ShowBots();
var
  contador : integer = 0;
Begin
for contador := 0 to length(ListadoBots) - 1 do
   AddLineToDebugLog('console',IntToStr(contador)+'- '+ListadoBots[contador].ip);
AddLineToDebugLog('console',IntToStr(length(ListadoBots))+' bots registered.');  // bots registered
End;

// muestra la informacion de los slots
Procedure ShowSlots();
var
  contador : integer = 0;
Begin
AddLineToDebugLog('console','Number Type ConnectedTo ChannelUsed LinesOnWait SumHash LBHash Offset ConStatus'); //Number Type ConnectedTo ChannelUsed LinesOnWait SumHash LBHash Offset ConStatus
for contador := 1 to MaxConecciones do
   begin
   if IsSlotConnected(contador) then
      begin
      AddLineToDebugLog('console',IntToStr(contador)+' '+conexiones[contador].tipo+
      ' '+conexiones[contador].ip+
      ' '+BoolToStr(CanalCliente[contador].connected,true)+' '+IntToStr(LengthIncoming(contador))+
      ' '+conexiones[contador].SumarioHash+' '+conexiones[contador].LastblockHash+' '+
      IntToStr(conexiones[contador].offset)+' '+IntToStr(conexiones[contador].ConexStatus));
      end;
   end;
end;

// Muestras las opciones del usuario
Procedure ShowUser_Options();
Begin
AddLineToDebugLog('console','Language    : '+WO_Language);
AddLineToDebugLog('console','Server Port : '+MN_Port);
AddLineToDebugLog('console','Wallet      : '+WalletFilename);
AddLineToDebugLog('console','AutoServer  : '+BoolToStr(WO_AutoServer,true));
AddLineToDebugLog('console','AutoConnect : '+BoolToStr(WO_AutoConnect,true));
AddLineToDebugLog('console','To Tray     : '+BoolToStr(WO_ToTray,true));
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

Procedure ToTrayON();
Begin
WO_ToTray := true;
//S_Options := true;
S_AdvOpt := true;
G_Launching := true;
form1.CB_WO_ToTray.Checked:=true;
G_Launching := false;
AddLineToDebugLog('console','Minimize to tray is now '+'ACTIVE'); //GetNodes option is now  // INACTIVE
End;

Procedure ToTrayOFF();
Begin
WO_ToTray := false;
//S_Options := true;
S_AdvOpt := false;
G_Launching := true;
form1.CB_WO_ToTray.Checked:=false;
G_Launching := false;
AddLineToDebugLog('console','Minimize to tray is now '+'INACTIVE'); //GetNodes option is now  // INACTIVE
End;

Procedure AutoServerON();
Begin
WO_autoserver := true;
S_AdvOpt := true;
AddLineToDebugLog('console','AutoServer option is now '+'ACTIVE');   //autoserver //active
End;

Procedure AutoServerOFF();
Begin
WO_autoserver := false;
S_AdvOpt := true;
AddLineToDebugLog('console','AutoServer option is now '+'INACTIVE');   //autoserver //inactive
End;

Procedure AutoConnectON();
Begin
WO_AutoConnect := true;
S_AdvOpt := true;
AddLineToDebugLog('console','Autoconnect option is now '+'ACTIVE');     //autoconnect // active
End;

Procedure AutoConnectOFF();
Begin
WO_AutoConnect := false;
S_AdvOpt := true;
AddLineToDebugLog('console','Autoconnect option is now '+'INACTIVE');    //autoconnect // inactive
End;

// muestra las direcciones de la cartera
Procedure ShowWallet();
var
  contador : integer = 0;
Begin
for contador := 0 to length(ListaDirecciones)-1 do
   begin
   AddLineToDebugLog('console',Listadirecciones[contador].Hash);
   end;
AddLineToDebugLog('console',IntToStr(Length(ListaDirecciones))+' addresses.');
AddLineToDebugLog('console',Int2Curr(GetWalletBalance)+' '+CoinSimbol);
End;

Procedure ExportarWallet(LineText:string);
var
  destino : string = '';
Begin
destino := Parameter(linetext,1);
destino := StringReplace(destino,'*',' ',[rfReplaceAll, rfIgnoreCase]);
if fileexists(destino+'.pkw') then
   begin
   AddLineToDebugLog('console','Error: Can not overwrite existing wallets');
   exit;
   end;
if copyfile(WalletFilename,destino+'.pkw',[]) then
   begin
   AddLineToDebugLog('console','Wallet saved as '+destino+'.pkw');
   end
else
   begin
   AddLineToDebugLog('console','Failed');
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
   AddLineToDebugLog('console','Specified wallet file do not exists.');//Specified wallet file do not exists.
   exit;
   end;
assignfile(CarteraFile,Cartera);
try
reset(CarteraFile);
seek(CarteraFile,0);
Read(CarteraFile,DatoLeido);
if not IsValidHashAddress(DatoLeido.Hash) then
   begin
   closefile(CarteraFile);
   AddLineToDebugLog('console','The file is not a valid wallet');
   exit;
   end;
for contador := 0 to filesize(CarteraFile)-1 do
   begin
   seek(CarteraFile,contador);
   Read(CarteraFile,DatoLeido);
   if ((DireccionEsMia(DatoLeido.Hash) < 0) and (IsValidHashAddress(DatoLeido.Hash))) then
      begin
      setlength(ListaDirecciones,Length(ListaDirecciones)+1);
      ListaDirecciones[length(ListaDirecciones)-1] := DatoLeido;
      Nuevos := nuevos+1;
      end;
   end;
closefile(CarteraFile);
except on E:Exception  do
AddLineToDebugLog('console','The file is not a valid wallet'); //'The file is not a valid wallet'
end;
if nuevos > 0 then
   begin
   OutText('Addresses imported: '+IntToStr(nuevos),false,2); //'Addresses imported: '
   UpdateWalletFromSumario;
   end
else AddLineToDebugLog('console','No new addreses found.');  //'No new addreses found.'
End;

Procedure ShowBlchHead(number:integer);
var
  Dato: ResumenData;
  Found : boolean = false;
  StartBlock : integer = 0;
Begin
EnterCriticalSection(CSHeadAccess);
StartBlock := number - 10;
If StartBlock < 0 then StartBlock := 0;
TRY
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Seek(FileResumen,StartBlock);
   REPEAT
   read(fileresumen, dato);
   if Dato.block= number then
      begin
      AddLineToDebugLog('console',IntToStr(dato.block)+' '+copy(dato.blockhash,1,5)+' '+copy(dato.SumHash,1,5));
      Found := true;
      end;
   UNTIL ((Found) or (eof(FileResumen)) );
closefile(FileResumen);
EXCEPT ON E:Exception do
   AddLineToDebugLog('console','Error: '+E.Message)
END;{TRY}
LeaveCriticalSection(CSHeadAccess);
End;

// Cambiar la primera direccion de la wallet
Procedure SetDefaultAddress(linetext:string);
var
  Numero: Integer;
  OldData, NewData: walletData;
Begin
Numero := StrToIntDef(Parameter(linetext,1),-1);
if ((Numero < 0) or (numero > length(ListaDirecciones)-1)) then
   OutText('Invalid address number.',false,2)  //'Invalid address number.'
else if numero = 0 then
   OutText('Address 0 is already the default.',false,2) //'Address 0 is already the default.'
else
   begin
   OldData := ListaDirecciones[0];
   NewData := ListaDirecciones[numero];
   ListaDirecciones[numero] := OldData;
   ListaDirecciones[0] := NewData;
   OutText('New default address: '+NewData.Hash,false,2); //'New default address: '
   S_Wallet := true;
   U_DirPanel := true;
   end;
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
  Header  : BlockHeaderData;
  LOrders : TBlockOrdersArray;
  LPOSes  : BlockArraysPos;
  PosReward : int64;
  PosCount  : integer;
  Counter : integer;
Begin
if fileexists(BlockDirectory+IntToStr(numberblock)+'.blk') then
   begin
   Header := LoadBlockDataHeader(numberblock);
   AddLineToDebugLog('console','Block info: '+IntToStr(numberblock));
   AddLineToDebugLog('console','Hash  :       '+HashMD5File(BlockDirectory+IntToStr(numberblock)+'.blk'));
   AddLineToDebugLog('console','Number:       '+IntToStr(Header.Number));
   AddLineToDebugLog('console','Time start:   '+IntToStr(Header.TimeStart)+' ('+TimestampToDate(Header.TimeStart)+')');
   AddLineToDebugLog('console','Time end:     '+IntToStr(Header.TimeEnd)+' ('+TimestampToDate(Header.TimeEnd)+')');
   AddLineToDebugLog('console','Time total:   '+IntToStr(Header.TimeTotal));
   AddLineToDebugLog('console','L20 average:  '+IntToStr(Header.TimeLast20));
   AddLineToDebugLog('console','Transactions: '+IntToStr(Header.TrxTotales));
   AddLineToDebugLog('console','Difficult:    '+IntToStr(Header.Difficult));
   AddLineToDebugLog('console','Target:       '+Header.TargetHash);
   AddLineToDebugLog('console','Solution:     '+Header.Solution);
   AddLineToDebugLog('console','Last Hash:    '+Header.LastBlockHash);
   AddLineToDebugLog('console','Next Diff:    '+IntToStr(Header.NxtBlkDiff));
   AddLineToDebugLog('console','Miner:        '+Header.AccountMiner);
   AddLineToDebugLog('console','Fees:         '+IntToStr(Header.MinerFee));
   AddLineToDebugLog('console','Reward:       '+IntToStr(Header.Reward));
   LOrders := GetBlockTrxs(numberblock);
   if length(LOrders)>0 then
      begin
      AddLineToDebugLog('console','TRANSACTIONS');
      For Counter := 0 to length(LOrders)-1 do
         begin
         AddLineToDebugLog('console',Format('%-8s %-35s -> %-35s : %s',[LOrders[counter].OrderType,LOrders[counter].sender,LOrders[counter].Receiver,int2curr(LOrders[counter].AmmountTrf)]));
         end;
      end;
   if numberblock>PoSBlockStart then
      begin
      LPoSes := GetBlockPoSes(numberblock);
      PosReward := StrToInt64Def(LPoSes[length(LPoSes)-1].address,0);
      SetLength(LPoSes,length(LPoSes)-1);
      PosCount := length(LPoSes);
      AddLineToDebugLog('console',Format('PoS Reward: %s  /  Addresses: %d  /  Total: %s',[int2curr(PosReward),PosCount,int2curr(PosReward*PosCount)]));
      end;
   if numberblock>MNBlockStart then
      begin
      LPoSes := GetBlockMNs(numberblock);
      PosReward := StrToInt64Def(LPoSes[length(LPoSes)-1].address,0);
      SetLength(LPoSes,length(LPoSes)-1);
      PosCount := length(LPoSes);
      AddLineToDebugLog('console',Format('MNs Reward: %s  /  Addresses: %d  /  Total: %s',[int2curr(PosReward),PosCount,int2curr(PosReward*PosCount)]));
      end;
   end
else
   AddLineToDebugLog('console','Block file do not exists: '+numberblock.ToString);
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
   AddLineToDebugLog('console','Invalid address');  //'Invalid address'
   procesar := false;
   end;
if ListaDirecciones[DireccionEsMia(address)].Custom <> '' then
   begin
   AddLineToDebugLog('console','Address already have a custom alias'); //'Address already have a custom alias'
   procesar := false;
   end;
if ( (length(AddAlias)<5) or (length(AddAlias)>40) ) then
   begin
   OutText('Alias must have between 5 and 40 chars',false,2); //'Alias must have between 5 and 40 chars'
   procesar := false;
   end;
if IsValidHashAddress(addalias) then
   begin
   AddLineToDebugLog('console','Alias can not be a valid address'); //'Alias can not be a valid address'
   procesar := false;
   end;
if ListaDirecciones[DireccionEsMia(address)].Balance < Customizationfee then
   begin
   AddLineToDebugLog('console','Insufficient balance'); //'Insufficient balance'
   procesar := false;
   end;
if AddressAlreadyCustomized(Address) then
   begin
   AddLineToDebugLog('console','Address already have a custom alias'); //'Address already have a custom alias'
   procesar := false;
   end;
if AliasAlreadyExists(addalias) then
   begin
   AddLineToDebugLog('console','Alias already exists');
   procesar := false;
   end;
for cont := 1 to length(addalias) do
   begin
   if pos(addalias[cont],CustomValid)=0 then
      begin
      AddLineToDebugLog('console','Invalid character in alias: '+addalias[cont]);
      info('Invalid character in alias: '+addalias[cont]);
      procesar := false;
      end;
   end;
if procesar then
   begin
   CurrTime := UTCTimeStr;
   TrfrHash := GetTransferHash(CurrTime+Address+addalias);
   OrderHash := GetOrderHash('1'+currtime+TrfrHash);
   AddCriptoOp(2,'Customize this '+address+' '+addalias+'$'+ListaDirecciones[DireccionEsMia(address)].PrivateKey,
           ProtocolLine(9)+    // CUSTOM
           OrderHash+' '+  // OrderID
           '1'+' '+        // OrderLines
           'CUSTOM'+' '+   // OrderType
           CurrTime+' '+   // Timestamp
           'null'+' '+     // reference
           '1'+' '+        // Trxline
           ListaDirecciones[DireccionEsMia(address)].PublicKey+' '+    // sender
           ListaDirecciones[DireccionEsMia(address)].Hash+' '+    // address
           AddAlias+' '+   // receiver
           IntToStr(Customizationfee)+' '+  // Amountfee
           '0'+' '+                         // amount trfr
           '[[RESULT]] '+//GetStringSigned('Customize this '+address+' '+addalias,ListaDirecciones[DireccionEsMia(address)].PrivateKey)+' '+
           TrfrHash);      // trfrhash
   end;
End;

// Incluye una solicitud de envio de fondos a la cola de transacciones cripto
Procedure Parse_SendFunds(LineText:string);
Begin
AddCriptoOp(3,linetext,'');
End;

// Ejecuta una orden de transferencia
function SendFunds(LineText:string;showOutput:boolean=true):string;
var
  Destination, amount, reference : string;
  monto, comision : int64;
  montoToShow, comisionToShow : int64;
  contador : integer;
  Restante : int64;
  ArrayTrfrs : Array of Torderdata;
  currtime : string;
  TrxLinea : integer = 0;
  OrderHashString : String;
  OrderString : string;
  AliasIndex : integer;
  Procesar : boolean = true;
  ResultOrderID : String = '';
  CoinsAvailable : int64;
  DestinationRecord : TSummaryData;
Begin
result := '';
BeginPerformance('SendFunds');
Destination := Parameter(Linetext,1);
amount       := Parameter(Linetext,2);
reference    := Parameter(Linetext,3);
if ((Destination='') or (amount='')) then
   begin
   if showOutput then AddLineToDebugLog('console','Invalid parameters.'); //'Invalid parameters.'
   Procesar := false;
   end;
if not IsValidHashAddress(Destination) then
   begin
   AliasIndex:=GetIndexPosition(Destination,DestinationRecord,true);
   if AliasIndex<0 then
      begin
      if showOutput then AddLineToDebugLog('console','Invalid destination.'); //'Invalid destination.'
      Procesar := false;
      end
   else Destination := DestinationRecord.Hash;
   end;
monto := StrToInt64Def(amount,-1);
if reference = '' then reference := 'null';
if monto<=10 then
   begin
   if showOutput then AddLineToDebugLog('console','Invalid ammount.'); //'Invalid ammount.'
   Procesar := false;
   end;
if procesar then
   begin
   Comision := GetMinimumFee(Monto);
   montoToShow := Monto;
   comisionToShow := Comision;
   Restante := monto+comision;
   if WO_Multisend then CoinsAvailable := ListaDirecciones[0].Balance-GetAddressPendingPays(ListaDirecciones[0].Hash)
   else CoinsAvailable := GetWalletBalance;
   if Restante > CoinsAvailable then
      begin
      if showOutput then AddLineToDebugLog('console','Insufficient funds. Needed: '+Int2curr(Monto+comision));//'Insufficient funds. Needed: '
      Procesar := false;
      end;
   end;
// empezar proceso
if procesar then
   begin
   currtime := UTCTimeStr;
   Setlength(ArrayTrfrs,0);
   Contador := 0;
   OrderHashString := currtime;
   while monto > 0 do
      begin
      BeginPerformance('SendFundsVerify');
      if ListaDirecciones[contador].Balance-GetAddressPendingPays(ListaDirecciones[contador].Hash) > 0 then
         begin
         trxLinea := TrxLinea+1;
         Setlength(ArrayTrfrs,length(arraytrfrs)+1);
         ArrayTrfrs[length(arraytrfrs)-1]:= SendFundsFromAddress(ListaDirecciones[contador].Hash,
                                            Destination,monto, comision, reference, CurrTime,TrxLinea);
         comision := comision-ArrayTrfrs[length(arraytrfrs)-1].AmmountFee;
         monto := monto-ArrayTrfrs[length(arraytrfrs)-1].AmmountTrf;
         OrderHashString := OrderHashString+ArrayTrfrs[length(arraytrfrs)-1].TrfrID;
         end;
      Contador := contador +1;
      EndPerformance('SendFundsVerify');
      end;
   for contador := 0 to length(ArrayTrfrs)-1 do
      begin
      ArrayTrfrs[contador].OrderID:=GetOrderHash(IntToStr(trxLinea)+OrderHashString);
      ArrayTrfrs[contador].OrderLines:=trxLinea;
      end;
   ResultOrderID := GetOrderHash(IntToStr(trxLinea)+OrderHashString);
   if showOutput then AddLineToDebugLog('console','Send to: '+Destination+slinebreak+
                    'Send '+Int2Curr(montoToShow)+' fee '+Int2Curr(comisionToShow)+slinebreak+
                    'Order ID: '+ResultOrderID);
   result := ResultOrderID;

   OrderString := GetPTCEcn+'ORDER '+IntToStr(trxLinea)+' $';
   for contador := 0 to length(ArrayTrfrs)-1 do
      begin
      OrderString := orderstring+GetStringfromOrder(ArrayTrfrs[contador])+' $';
      end;
   Setlength(orderstring,length(orderstring)-2);
   OutgoingMsjsAdd(OrderString);
   EndPerformance('SendFunds');
   end // End procesar
else
   begin
   if showOutput then AddLineToDebugLog('console','Syntax: sendto {destination} {ammount} {reference}');
   end;
End;

// Process a GVT sending
Procedure Parse_SendGVT(LineText:string);
Begin
AddCriptoOp(6,linetext,'');
End;

Function SendGVT(LineText:string;showOutput:boolean=true):string;
var
  GVTNumber   : integer;
  GVTOwner    : string;
  Destination : string = '';
  AliasIndex  : integer;
  Procesar    : boolean = true;
  OrderTime   : string = '';
  TrfrHash    : string = '';
  OrderHash   : string = '';
  ResultStr   : string = '';
  Signature   : string = '';
  GVTNumStr   : string = '';
  StrTosign   : String = '';
  DestinationRecord : TSummaryData;
Begin
result := '';
BeginPerformance('SendGVT');
GVTNumber:= StrToIntDef(Parameter(Linetext,1),-1);
Destination := Parameter(Linetext,2);
if ( (GVTnumber<0) or (GVTnumber>length(ArrGVTs)-1) ) then
   begin
   if showOutput then AddLineToDebugLog('console','Invalid GVT number');
   exit;
   end;
GVTNumStr := ArrGVTs[GVTnumber].number;
GVTOwner := ArrGVTs[GVTnumber].owner;
If DireccionEsMia(GVTOwner)<0 then
   begin
   if showOutput then AddLineToDebugLog('console','You do not own that GVT');
   exit;
   end;
if GetAddressAvailable(GVTOwner)<Customizationfee then
   begin
   if showOutput then AddLineToDebugLog('console','Inssuficient funds');
   exit;
   end;
if not IsValidHashAddress(Destination) then
   begin
   AliasIndex:=GetIndexPosition(Destination,DestinationRecord,true);
   if AliasIndex<0 then
      begin
      if showOutput then AddLineToDebugLog('console','Invalid destination.'); //'Invalid destination.'
      Exit;
      end
   else Destination := DestinationRecord.Hash;
   end;
if GVTOwner=Destination then
   begin
   if showOutput then AddLineToDebugLog('console','Can not transfer GVT to same address');
   exit;
   end;
// TEMP FILTER
if GVTOwner<>ListaDirecciones[0].Hash then
   begin
   if showOutput then AddLineToDebugLog('console','Actually only project GVTs can be transfered');
   exit;
   end;
OrderTime := UTCTimeStr;
TrfrHash := GetTransferHash(OrderTime+GVTOwner+Destination);
OrderHash := GetOrderHash('1'+OrderTime+TrfrHash);
StrTosign := 'Transfer GVT '+GVTNumStr+' '+Destination+OrderTime;
Signature := GetStringSigned(StrTosign,ListaDirecciones[DireccionEsMia(GVTOwner)].PrivateKey);
ResultStr := ProtocolLine(21)+ // sndGVT
             OrderHash+' '+  // OrderID
             '1'+' '+        // OrderLines
             'SNDGVT'+' '+   // OrderType
             OrderTime+' '+   // Timestamp
             GVTNumStr+' '+     // reference
             '1'+' '+        // Trxline
             ListaDirecciones[DireccionEsMia(GVTOwner)].PublicKey+' '+    // sender
             ListaDirecciones[DireccionEsMia(GVTOwner)].Hash+' '+        // address
             Destination+' '+   // receiver
             IntToStr(Customizationfee)+' '+  // Amountfee
             '0'+' '+                         // amount trfr
             Signature+' '+
             TrfrHash;      // trfrhash
OutgoingMsjsAdd(ResultStr);
if showoutput then
   begin
   AddLineToDebugLog('console','GVT '+GVTNumStr+' transfered from '+ListaDirecciones[DireccionEsMia(GVTOwner)].Hash+' to '+Destination);
   AddLineToDebugLog('console','Order: '+OrderHash);
   //AddLineToDebugLog('console',StrToSign);
   end;
EndPerformance('SendGVT');
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
   reward := InitialReward div (2**contador);
   MarketCap := marketcap+(reward*BlockHalvingInterval);
   Texto := Format('From block %7d until %7d : %11s',[block1,block2,Int2curr(reward)]);
   //Texto :='From block '+IntToStr(block1)+' until '+IntToStr(block2)+': '+Int2curr(reward); //'From block '+' until '
   AddLineToDebugLog('console',Texto);
   end;
AddLineToDebugLog('console','And then '+int2curr(0)); //'And then '
MarketCap := MarketCap+PremineAmount-InitialReward; // descuenta una recompensa inicial x bloque 0
AddLineToDebugLog('console','Final supply: '+int2curr(MarketCap)); //'Final supply: '
End;

// cambia el puerto de escucha
Procedure SetServerPort(LineText:string);
var
  NewPort:string = '';
Begin
AddLineToDebugLog('console','Deprecated');
Exit;
NewPort := parameter(linetext,1);
if ((StrToIntDef(NewPort,0) < 1) or (StrToIntDef(NewPort,0)>65535)) then
   begin
   AddLineToDebugLog('console','Invalid Port');
   end
else
   begin
   MN_Port := NewPort;
   OutText('New listening port: '+NewPort,false,2);
   end;
End;

// prueba la lectura de parametros de la linea de comandos
Procedure TestParser(LineText:String);
var
  contador : integer = 1;
  continuar : boolean;
  parametro : string;
Begin
AddLineToDebugLog('console',Parameter(linetext,0));
continuar := true;
repeat
   begin
   parametro := Parameter(linetext,contador);
   if parametro = '' then continuar := false
   else
     begin
     AddLineToDebugLog('console',inttostr(contador)+' '+parametro);
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
  IPDeleted : boolean = false;
Begin
IPBot := Parameter(linetext,1);
if IPBot = '' then
   begin
   AddLineToDebugLog('console','Invalid IP');
   end
else if uppercase(IPBot) = 'ALL' then
   begin
   SetLength(ListadoBots,0);
   LastBotClear := UTCTimeStr;
   S_BotData := true;
   AddLineToDebugLog('events','All bots deleted');
   end
else
   begin
   for contador := 0 to length(ListadoBots)-1 do
      begin
      if ListadoBots[contador].ip = IPBot then
         begin
         Delete(ListadoBots,Contador,1);
         S_BotData := true;
         AddLineToDebugLog('console',IPBot+' deleted from bot list');
         IPDeleted := true;
         end;
      end;
   if not IPDeleted then AddLineToDebugLog('console','IP do not exists in Bot list');
   end;
End;

Procedure showCriptoThreadinfo();
Begin
AddLineToDebugLog('console',Booltostr(CriptoThreadRunning,true)+' '+intToStr(length(ArrayCriptoOp)));
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
AddLineToDebugLog('console','Network last block');
AddLineToDebugLog('console','Value: '+NetLastBlock.Value);
AddLineToDebugLog('console','Count: '+IntToStr(NetLastBlock.Count));
AddLineToDebugLog('console','Percent: '+IntToStr(NetLastBlock.porcentaje));
AddLineToDebugLog('console','Slot: '+IntToStr(NetLastBlock.slot));
End;

Procedure GetOwnerHash(LineText:string);
var
  Direccion, Pubkey, privkey, currtime, Certificate : string;
  AddIndex : integer;
Begin
direccion := parameter(linetext,1);
AddIndex  := DireccionEsMia(direccion);
if ( (AddIndex<0) or (direccion='') ) then
  begin
  AddLineToDebugLog('console','Invalid address');
  end
else
   begin
   currtime := UTCTimeStr;
   Pubkey   := ListaDirecciones[AddIndex].PublicKey;
   Privkey  := ListaDirecciones[AddIndex].PrivateKey;
   Certificate := GetCertificate(Pubkey,privkey,currtime);
   AddLineToDebugLog('console',direccion+' owner cert: '+slinebreak+Certificate);
   end;
End;

Procedure CheckOwnerHash(LineText:string);
var
  data, firmtime, Address, Lalias : string;
Begin
BeginPerformance('CheckOwnerHash');
data := parameter(LineText,1);
Address := CheckCertificate(Data,firmtime);
if Address <> '' then
  begin
  Lalias := GetAddressAlias(Address);
  if Lalias <> '' then
    Address := Format('%s [%s]',[Address,Lalias]);
  AddLineToDebugLog('console',Address+' verified '+TimeSinceStamp(StrToInt64(firmtime))+' ago.')
  end
else
  begin
  AddLineToDebugLog('console','Invalid verification');
  end;
EndPerformance('CheckOwnerHash');
End;

// devuelve una cadena con los updates disponibles
function AvailableUpdates():string;
var
  updatefiles : TStringList;
  contador : integer = 0;
  version : string;
Begin
Result := '';
updatefiles := TStringList.Create;
FindAllFiles(updatefiles, UpdatesDirectory, '*.zip', false);
while contador < updatefiles.Count do
   begin
   version :=copy(updatefiles[contador],18,8);
   Result := result+version+' ';
   Inc(contador);
   end;
updatefiles.Free;
Result := Trim(Result);
End;

// Manual update the app
Procedure RunUpdate(linea:string);
var
  Tversion : string;
  TArch    : string;
  overRule : boolean = false;
Begin
Tversion := parameter(linea,1);
if Tversion = '' then Tversion := Parameter(GetLastRelease,0);
TArch    := Uppercase(parameter(linea,2));
if TArch = '' then TArch := GetOS;
AddLineToDebugLog('console',Format('Trying upgrade to version %s (%s)',[TVersion,TArch]));
if ansicontainsstr(linea,' /or') then overRule := true;
Application.ProcessMessages;
if ( (Tversion = ProgramVersion+Subversion) and (not overRule) ) then
   begin
   AddLineToDebugLog('console','Version '+TVersion+' already installed');
   exit;
   end;
if GetLastVerZipFile(Tversion,TArch) then
   begin
   AddLineToDebugLog('console','Version '+Tversion+' downloaded');
   if UnZipUpdateFromRepo(Tversion,TArch) then
     begin
     AddLineToDebugLog('console','Unzipped !');
     {$IFDEF WINDOWS}Trycopyfile('NOSODATA/UPDATES/Noso.exe','nosonew');{$ENDIF}
     {$IFDEF UNIX}Trycopyfile('NOSODATA/UPDATES/Noso','Nosonew');{$ENDIF}
     CreateLauncherFile(true);
     RunExternalProgram(RestartFilename);
     cerrarprograma();
     end
   end
else
   begin
   AddLineToDebugLog('console','Update Failed');
   end
End;

Procedure SendAdminMessage(linetext:string);
var
  mensaje,currtime, firma, hashmsg : string;
Begin
if (DireccionEsMia(AdminHash)<0) then AddLineToDebugLog('console','Only the Noso developers can do this.') //Only the Noso developers can do this
else
   begin
   mensaje := copy(linetext,11,length(linetext));
   //Mensaje := parameter(linetext,1);
   currtime := UTCTimeStr;
   firma := GetStringSigned(currtime+mensaje,ListaDirecciones[DireccionEsMia(AdminHash)].PrivateKey);
   hashmsg := HashMD5String(currtime+mensaje+firma);
   mensaje := StringReplace(mensaje,' ','_',[rfReplaceAll, rfIgnoreCase]);
   OutgoingMsjsAdd(GetPTCEcn+'ADMINMSG '+currtime+' '+mensaje+' '+firma+' '+hashmsg);
   mensaje := StringReplace(mensaje,'_',' ',[rfReplaceAll, rfIgnoreCase]);
   AddLineToDebugLog('console','Directive sent: '+mensaje);
   end;
End;

Procedure SetReadTimeOutTIme(LineText:string);
var
  newvalue : integer;
Begin
newvalue := StrToIntDef(parameter(LineText,1),-1);
if newvalue < 0 then AddLineToDebugLog('console','ReadTimeOutTime= '+IntToStr(ReadTimeOutTIme))
else
  begin
  ReadTimeOutTIme := newvalue;
  AddLineToDebugLog('console','ReadTimeOutTime set to '+IntToStr(newvalue));
  end;
End;

Procedure SetConnectTimeOutTIme(LineText:string);
var
  newvalue : integer;
Begin
newvalue := StrToIntDef(parameter(LineText,1),-1);
if newvalue < 0 then AddLineToDebugLog('console','ConnectTimeOutTime= '+IntToStr(ConnectTimeOutTIme))
else
  begin
  ConnectTimeOutTIme := newvalue;
  AddLineToDebugLog('console','ConnectTimeOutTime set to '+IntToStr(newvalue));
  end;
End;

Procedure RequestHeaders();
Begin
PTC_SendLine(NetResumenHash.Slot,ProtocolLine(7));
End;

Procedure RequestSumary();
Begin
PTC_SendLine(NetResumenHash.Slot,ProtocolLine(6));
End;

Procedure ShowOrderDetails(LineText:string);
var
  orderid : string;
  orderdetails : string;
  ThisOrderdata : TOrderGroup;
Begin
orderid := parameter(LineText,1);
ThisOrderdata := GetOrderDetails(orderid);
if thisorderdata.AmmountTrf<=0 then
  AddLineToDebugLog('console','Order not found')
else
  begin
  AddLineToDebugLog('console','Time     : '+TimestampToDate(ThisOrderdata.TimeStamp));
  if ThisOrderdata.Block = -1 then AddLineToDebugLog('console','Block: Pending')
  else AddLineToDebugLog('console','Block    : '+IntToStr(ThisOrderdata.Block));
  AddLineToDebugLog('console','Type     : '+ThisOrderdata.OrderType);
  AddLineToDebugLog('console','Trfrs    : '+IntToStr(ThisOrderdata.OrderLines));
  AddLineToDebugLog('console','sender   : '+ThisOrderdata.sender);
  AddLineToDebugLog('console','Receiver : '+ThisOrderdata.receiver);
  AddLineToDebugLog('console','Ammount  : '+Int2curr(ThisOrderdata.AmmountTrf));
  AddLineToDebugLog('console','Fee      : '+Int2curr(ThisOrderdata.AmmountFee));
  AddLineToDebugLog('console','Reference: '+ThisOrderdata.reference);
  end;
End;

// Exports a single address credentials of the wallet
Procedure ExportAddress(LineText:string);
var
  addresshash : string;
  newfile : file of WalletData;
  Data : WalletData;
Begin
addresshash := parameter(LineText,1);
if DireccionEsMia(addresshash) >= 0 then
  begin
  Assignfile(newfile,'tempwallet.pkw');
  rewrite(newfile);
  Data := ListaDirecciones[DireccionEsMia(addresshash)];
  write(newfile,data);
  closefile(newfile);
  AddLineToDebugLog('console','Address exported to tempwallet.pkw');
  end
else AddLineToDebugLog('console','Address not found in wallet');
End;

// Shows all the info of a specified address
Procedure ShowAddressInfo(LineText:string);
var
  addtoshow, addhash, addalias : string;
  sumposition : integer;
  onsumary, pending : int64;
  counter : integer;
  OwnedGVTs : string = '';
  LRecord   : TSummaryData;
Begin
addtoshow := parameter(LineText,1);
if IsValidHashAddress(addtoshow) then
  begin
  addhash := addtoshow;
  addalias := GetAddressAlias(addtoshow);
  end
else
  begin
  sumposition := GetIndexPosition(AddToShow,LRecord,true);
  if Sumposition >= 0 then
    begin
    addhash  := LRecord.Hash;
    AddAlias := AddToShow;
    end;
  end;
if sumposition<0 then
   AddLineToDebugLog('console','Address do not exists in sumary.')
else
   begin
   onsumary := GetAddressBalanceIndexed(addhash);
   pending := GetAddressPendingPays(addhash);
   AddLineToDebugLog('console','Address   : '+addhash+slinebreak+
                    'Alias     : '+AddAlias+slinebreak+
                    'Sumary    : '+Int2curr(onsumary)+slinebreak+
                    'Incoming  : '+Int2Curr(GetAddressIncomingpays(AddHash))+slinebreak+
                    'Outgoing  : '+Int2curr(pending)+slinebreak+
                    'Available : '+int2curr(onsumary-pending));
   if AnsiContainsStr(GetMN_FileText,addhash) then
      AddLineToDebugLog('console','Masternode: Active');
   EnterCriticalSection(CSGVTsArray);
   for counter := 0 to length(ArrGVTs)-1 do
      begin
      if ArrGVTs[counter].owner = addhash then
         begin
         OwnedGVTs := OwnedGVTs+counter.ToString+' ';
         end;
      end;
   LeaveCriticalSection(CSGVTsArray);
   OwnedGVTs := Trim(OwnedGVTs);
   if OwnedGVTs <> '' then
      AddLineToDebugLog('console','GVTs      : '+OwnedGVTs);
   end;
End;

// Shows transaction history of the specified address
Procedure ShowAddressHistory(LineText:string);
var
  BlockCount : integer;
  addtoshow : string;
  counter,contador2 : integer;
  Header : BlockHeaderData;
  ArrTrxs : TBlockOrdersArray;
  incomingtrx : integer = 0; minedblocks : integer = 0;inccoins : int64 = 0;
  outgoingtrx : integer = 0; outcoins : int64 = 0;
  inbalance : int64;
  ArrayPos    : BlockArraysPos;
  PosReward   : int64;
  PosCount    : integer;
  CounterPos  : integer;
  PosPAyments : integer = 0;
  PoSEarnings : int64 = 0;
  TransSL : TStringlist;
  MinedBlocksStr : string = '';
  sumpool1    : int64 = 0;
  sumpool2    : int64 = 0;
  sumpool3    : int64 = 0;
  sumpool4    : int64 = 0;
Begin
BlockCount := StrToIntDef(Parameter(Linetext,2),0);
if BlockCount = 0 then BlockCount := SecurityBlocks-1;
if BlockCount >= MyLastBlock then BlockCount := MyLastBlock-1;
TransSL := TStringlist.Create;
addtoshow := parameter(LineText,1);
for counter := MyLastBlock downto MyLastBlock- BlockCount do
   begin
   if counter mod 10 = 0 then
      begin
      info('History :'+IntToStr(Counter));
      application.ProcessMessages;
      end;
   Header := LoadBlockDataHeader(counter);
   if Header.AccountMiner= addtoshow then // address is miner
     begin
     minedblocks +=1;
     MinedBlocksStr := MinedBlocksStr+Counter.ToString+' ';
     inccoins := inccoins + header.Reward+header.MinerFee;
     end;
   ArrTrxs := GetBlockTrxs(counter);
   if length(ArrTrxs)>0 then
      begin
      for contador2 := 0 to length(ArrTrxs)-1 do
         begin
         if ArrTrxs[contador2].Receiver = addtoshow then // incoming order
            begin
            //{
            if ArrTrxs[contador2].sender = 'N3aXz2RGwj8LAZgtgyyXNRkfQ1EMnFC' then Inc(sumpool1,ArrTrxs[contador2].AmmountTrf);
            if ArrTrxs[contador2].sender = 'N2ophUoAzJw9LtgXbYMiB4u5jWWGJF7' then Inc(sumpool2,ArrTrxs[contador2].AmmountTrf);
            if ArrTrxs[contador2].sender = 'N3ESwXxCAR4jw3GVHgmKiX9zx1ojWEf' then Inc(sumpool3,ArrTrxs[contador2].AmmountTrf);
            if ArrTrxs[contador2].sender = 'N3pzgU2jpvhjW6cSJL8zW8Rzj5fJdFa' then Inc(sumpool4,ArrTrxs[contador2].AmmountTrf);
            incomingtrx += 1;
            inccoins := inccoins+ArrTrxs[contador2].AmmountTrf;
            transSL.Add(IntToStr(Counter)+'] '+ArrTrxs[contador2].sender+'<-- '+Int2curr(ArrTrxs[contador2].AmmountTrf));
            //}
            end;
         if ArrTrxs[contador2].sender = addtoshow then // outgoing order
            begin
            outgoingtrx +=1;
            outcoins := outcoins + ArrTrxs[contador2].AmmountTrf + ArrTrxs[contador2].AmmountFee;
            transSL.Add(IntToStr(Counter)+'] '+ArrTrxs[contador2].Receiver+'--> '+Int2curr(ArrTrxs[contador2].AmmountTrf));
            end;
         end;
      end;
   SetLength(ArrTrxs,0);
   if counter >= PoSBlockStart then
      begin
      ArrayPos := GetBlockPoSes(counter);
      PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
      SetLength(ArrayPos,length(ArrayPos)-1);
      PosCount := length(ArrayPos);
      for counterpos := 0 to PosCount-1 do
         begin
         if ArrayPos[counterPos].address = addtoshow then
           begin
           PosPAyments +=1;
           PosEarnings := PosEarnings+PosReward;
           end;
         end;
      SetLength(ArrayPos,0);
      end;
   end;
inbalance := GetAddressBalanceIndexed(addtoshow);
AddLineToDebugLog('console','Last block : '+inttostr(MyLastBlock));
AddLineToDebugLog('console','Address    : '+addtoshow);
AddLineToDebugLog('console','INCOMINGS');
AddLineToDebugLog('console','  Mined        : '+IntToStr(minedblocks));
AddLineToDebugLog('console','  Mined blocks : '+MinedBlocksStr);
AddLineToDebugLog('console','  Transactions : '+IntToStr(incomingtrx));
AddLineToDebugLog('console','  Coins        : '+Int2Curr(inccoins));
AddLineToDebugLog('console','  PoS Payments : '+IntToStr(PosPAyments));
AddLineToDebugLog('console','  PoS Earnings : '+Int2Curr(PosEarnings));
AddLineToDebugLog('console','OUTGOINGS');
AddLineToDebugLog('console','  Transactions : '+IntToStr(outgoingtrx));
AddLineToDebugLog('console','  Coins        : '+Int2Curr(outcoins));
AddLineToDebugLog('console','TOTAL  : '+Int2Curr(inccoins-outcoins+PoSearnings));
AddLineToDebugLog('console','SUMARY : '+Int2Curr(inbalance));
AddLineToDebugLog('console','');
AddLineToDebugLog('console','Transactions');
While TransSL.Count >0 do
   begin
   AddLineToDebugLog('console',TransSL[0]);
   TransSL.Delete(0);
   end;
TransSL.Free;
{
AddLineToDebugLog('console','Propool  paid : '+Int2curr(sumpool4));
AddLineToDebugLog('console','Estripa  paid : '+Int2curr(sumpool2));
AddLineToDebugLog('console','NosoMN   paid : '+Int2curr(sumpool1));
AddLineToDebugLog('console','Gonefish paid : '+Int2curr(sumpool3));
}
End;

// Shows the total fees paid in the whole blockchain
Procedure ShowTotalFees();
var
  counter : integer;
  Header : BlockHeaderData;
  totalcoins : int64 = 0;
Begin
for counter := 1 to MyLastBlock do
   begin
   Header := LoadBlockDataHeader(counter);
   totalcoins := totalcoins+ header.MinerFee;
   if counter mod 100 = 0 then
     Begin
     info('TOTAL FEES '+counter.ToString);
     application.ProcessMessages;
     end;
   end;
AddLineToDebugLog('console','Blockchain total fees: '+Int2curr(totalcoins));
AddLineToDebugLog('console','Block average        : '+Int2curr(totalcoins div MyLastBlock));
End;

// *******************
// *** DEBUG 0.2.1 ***
// *******************

Procedure ShowBlockPos(LineText:string);
var
  number : integer;
  ArrayPos : BlockArraysPos;
  PosReward : int64;
  PosCount, counterPos : integer;
Begin
number := StrToIntDef(parameter(linetext,1),0);
if ((number < PoSBlockStart) or (number > MyLastBlock))then
   begin
   AddLineToDebugLog('console','Invalid block number: '+number.ToString);
   end
else
   begin
   ArrayPos := GetBlockPoSes(number);
   PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
   SetLength(ArrayPos,length(ArrayPos)-1);
   PosCount := length(ArrayPos);
   for counterpos := 0 to PosCount-1 do
      AddLineToDebugLog('console',ArrayPos[counterPos].address+': '+int2curr(PosReward));
   AddLineToDebugLog('console','Block:   : '+inttostr(number));
   AddLineToDebugLog('console','Addresses: '+IntToStr(PosCount));
   AddLineToDebugLog('console','Reward   : '+int2curr(PosReward));
   AddLineToDebugLog('console','Total    : '+int2curr(PosCount*PosReward));
   SetLength(ArrayPos,0);
   end;
End;

Procedure ShowBlockMNs(LineText:string);
var
  number : integer;
  ArrayMNs : BlockArraysPos;
  MNsReward : int64;
  MNsCount, counterMNs : integer;
Begin
number := StrToIntDef(parameter(linetext,1),0);
if ((number < MNBlockStart) or (number > MyLastBlock))then
   begin
   AddLineToDebugLog('console','Invalid block number: '+number.ToString);
   end
else
   begin
   ArrayMNs := GetBlockMNs(number);
   MNsReward := StrToIntDef(ArrayMNs[length(ArrayMNs)-1].address,0);
   SetLength(ArrayMNs,length(ArrayMNs)-1);
   MNSCount := length(ArrayMNs);
   for counterMNs := 0 to MNsCount-1 do
      AddLineToDebugLog('console',ArrayMNs[counterMNs].address);
   AddLineToDebugLog('console','MNs Block : '+inttostr(number));
   AddLineToDebugLog('console','Addresses : '+IntToStr(MNsCount));
   AddLineToDebugLog('console','Reward    : '+int2curr(MNsReward));
   AddLineToDebugLog('console','Total     : '+int2curr(MNsCount*MNsReward));
   SetLength(ArrayMNs,0);
   end;
End;

Procedure showgmts(LineText:string);
var
  monto: int64;
  gmts, fee : int64;
Begin
monto := StrToInt64Def(Parameter(LineText,1),0);
gmts := GetMaximunToSend(monto);
fee := monto-gmts;
if fee<MinimunFee then fee := MinimunFee;
if monto <= MinimunFee then
   begin
   gmts := 0;
   fee  := 0;
   end;
AddLineToDebugLog('console','Ammount         : '+Int2Curr(monto));
AddLineToDebugLog('console','Maximun to send : '+Int2Curr(gmts));
AddLineToDebugLog('console','Fee paid        : '+Int2Curr(fee));
if gmts+fee = monto then AddLineToDebugLog('console','✓ Match')
else AddLineToDebugLog('console','✗ Error')
End;

// List all GVTs owners
Procedure ListGVTs();
var
  counter : integer;
Begin
AddLineToDebugLog('console','Existing: '+Length(arrgvts).ToString);
for counter := 0 to length(arrgvts)-1 do
   AddLineToDebugLog('console',Format('%.2d %s',[counter,arrgvts[counter].owner]));
UpdateMyGVTsList
End;

Function MainNetHashrate(blocks:integer = 100):int64;
var
  counter : integer;
  TotalRate : double = 0;
  Header : BlockHeaderData;
  ThisBlockDiff : string;
  ThisBlockValue : integer;
  TotalBlocksCalculated : integer = 100;
  ResultStr : string = '';
Begin
TotalBlocksCalculated := blocks;
For counter:= MyLastblock downto Mylastblock-(TotalBlocksCalculated-1) do
   begin
   Header := LoadBlockDataHeader(counter);
   ThisBlockDiff := Parameter(Header.Solution,1);
   ThisBlockValue := GetDiffHashrate(ThisBlockDiff);
   TotalRate := TotalRate+(ThisBlockValue/100);
   ResultStr := ResultStr+Format('[%s]-',[FormatFloat('0.00',ThisBlockValue/100)]);
   end;
//AddLineToDebugLog('console',ResultStr);
TotalRate := TotalRate/TotalBlocksCalculated;
//AddLineToDebugLog('console',format('Average: %s',[FormatFloat('0.00',TotalRate)]));
TotalRate := Power(16,TotalRate);
Result := Round(TotalRate/575);
End;

function ShowPrivKey(linea:String;ToConsole:boolean = false):String;
var
  addtoshow : string;
  sumposition : integer;
Begin
result := '';
addtoshow := parameter(linea,1);
sumposition := DireccionEsMia(addtoshow);
if sumposition<0 then
   begin
   if ToConsole then AddLineToDebugLog('console',rs1504);
   end
else
   begin
   result := ListaDirecciones[sumposition].PrivateKey;
   end;
if ToConsole then AddLineToDebugLog('console',Result);
End;

Procedure TestNetwork(LineText:string);
var
  numero : integer;
  monto : integer;
  contador : integer;
Begin
numero := StrToIntDef(Parameter(linetext,1),0);
if ((numero <1) or (numero >1000)) then
  Outtext('Range must be 1-1000')
else
  begin
  Randomize;
  for contador := 1 to numero do
     begin
     Monto := 100000+contador;
     ProcesslinesAdd('SENDTO devteam_donations '+IntToStr(Monto)+' '+contador.ToString);
     end;
  end;
End;

Procedure ShowPendingTrxs();
Begin

End;

Procedure WebWallet();
var
  contador : integer;
  ToClipboard : String = '';
Begin
for contador := 0 to length(ListaDirecciones)-1 do
   begin
   ToClipboard := ToClipboard+(Listadirecciones[contador].Hash)+',';
   end;
Setlength(ToClipboard,length(ToClipboard)-1);
Clipboard.AsText := ToClipboard;
AddLineToDebugLog('console','Web wallet data copied to clipboard');
End;

Procedure ExportKeys(linea:string);
var
  sumposition : integer;
  addtoshow : string = '';
  Resultado : string = '';
Begin
addtoshow := parameter(linea,1);
sumposition := DireccionEsMia(addtoshow);
if sumposition<0 then
   begin
   AddLineToDebugLog('console',rs1504);
   end
else
   begin
   Resultado := ListaDirecciones[sumposition].PublicKey+' '+ListaDirecciones[sumposition].PrivateKey;
   Clipboard.AsText := Resultado;
   AddLineToDebugLog('console',rs1505);
   end;
end;

Procedure PostOffer(LineText:String);
var
  FromAddress : String = '';
  Amount : int64 = 0;
  Market : String = '';
  Price : int64;
  TotalPost : int64;
  PAyAddress : String = '';
  Duration : int64;
  FeeTotal : int64;
  FeeTramos : int64;

  ErrorCode : integer = 0;
  errorMessage : string = '';
Begin
FromAddress := Parameter(LineText,1);
if UPPERCASE(FromAddress) = 'DEF' then FromAddress := ListaDirecciones[0].Hash;
if UPPERCASE(Parameter(linetext,2)) = 'MAX' then Amount := GetMaximunToSend(GetAddressAvailable(FromAddress))
else Amount := StrToInt64Def(Parameter(linetext,2),0);
Market := UpperCase(Parameter(LineText,3));
Price := StrToInt64Def(Parameter(linetext,4),0);
TotalPost := amount*price div 100000000;
PayAddress := Parameter(LineText,5);
Duration := StrToInt64Def(Parameter(LineText,6),100);
if duration > 1000 then duration := 1000;
Feetramos := duration div 100; if duration mod 100 > 0 then feetramos +=1;
FeeTotal := GetMinimumFee(amount)*feetramos;


if FromAddress = '' then ErrorCode := -1
else if direccionEsMia(FromAddress) < 0 then ErrorCode := 1
else if ((amount = 0) or (amount+GetMinimumFee(amount)>GetAddressAvailable(FromAddress))) then ErrorCode := 2
else if not AnsiContainsStr(AvailableMarkets,market) then ErrorCode := 3
else if price <= 0 then ErrorCode := 4;

if errorcode =-1 then ErrorMessage := 'post {address} {ammount} {market} {price} {payaddress}'+
   ' {duration}';
if errorcode = 1 then ErrorMessage := 'Invalid Address';
if errorcode = 2 then ErrorMessage := 'Invalid Ammount';
if errorcode = 3 then ErrorMessage := 'Invalid market';
if errorcode = 4 then ErrorMessage := 'Invalid price';

If ErrorMessage <> '' then AddLineToDebugLog('console',ErrorMessage)
else
   begin
   AddLineToDebugLog('console','Post Exchange Offer');
   AddLineToDebugLog('console','From Address: '+FromAddress);
   AddLineToDebugLog('console','Ammount     : '+Int2Curr(amount)+' '+CoinSimbol);
   AddLineToDebugLog('console','Market      : '+Market);
   AddLineToDebugLog('console','Price       : '+Int2Curr(price)+' '+Market);
   AddLineToDebugLog('console','Total       : '+Int2Curr(TotalPost)+' '+Market);
   AddLineToDebugLog('console','Pay to      : '+PayAddress);
   AddLineToDebugLog('console','Duration    : '+IntToStr(Duration)+' blocks');
   AddLineToDebugLog('console','Fee         : ('+IntToStr(Feetramos)+') '+Int2Curr(FeeTotal)+' '+CoinSimbol);

   end;

End;

Procedure DebugTest(linetext:string);
var
  Texto : string;
Begin
{
if Myconstatus<3 then
  begin
  AddLineToDebugLog('console','Must be synced');
  exit;
  end;
Texto := GetMNsFileData;
if AnsiContainsStr(Texto,MN_Funds) then AddLineToDebugLog('console',MN_Funds+' got MN Reward on block '+MyLastBlock.ToString)
else AddLineToDebugLog('console',MN_Funds+' not paid')
}
AddLineToDebugLog('console',GetDiffHashrate('0000001').ToString);
End;

Procedure DebugTest2(linetext:string);
var
  total   : integer;
  verifis : integer;
  counter : integer;
Begin
Total := Length(ArrayMNsData);
verifis := (total div 10)+3;
AddLineToDebugLog('console',GetVerificatorsText);
AddLineToDebugLog('console','Masternodes  : '+IntToStr(total));
AddLineToDebugLog('console','Verificators : '+IntToStr(verifis));
for counter := 0 to verifis-1 do
   AddLineToDebugLog('console',format('%s %s %d',[ArrayMNsData[counter].ipandport,copy(arrayMNsData[counter].address,1,5),ArrayMNsData[counter].age]));
End;

Procedure ShowSystemInfo(Linetext:string);
var
  DownSpeed : int64;
  Param     : string;
Begin
if MyConStatus > 0 then exit;
Param := Uppercase(Parameter(Linetext,1));
if param = 'POWER' then
  AddLineToDebugLog('console',Format('Processing       : %d Trx/s',[Sys_HashSpeed]))
else if param = 'MEM' then
  AddLineToDebugLog('console',Format('Available memory : %d MB',[AllocateMem]))
else if param = 'DOWNSPEED' then
  AddLineToDebugLog('console',Format('Download speed   : %d Kb/s',[TestDownloadSpeed]))
else AddLineToDebugLog('console','Invalid parameter: '+Param+slinebreak+'Use: power, mem or downspeed');
End;

Procedure totallocked();
var
  sourcestr: string;
  thisadd  : string;
  counter  : integer = 0;
  total    : int64 = 0;
  count    : integer = 0;
  MNMsg    : string;
  ThisBal  : int64;
Begin
sourcestr := GetNosoCFGString(5);
repeat
Thisadd := Parameter(sourcestr,counter,':');
if thisadd <> '' then
   begin
   ThisBal := GetAddressBalanceIndexed(ThisAdd);
   Inc(Total,ThisBal);
   Inc(count);
   if AnsiContainsStr(GetMN_FileText,Thisadd) then MNMsg := '[MN]'
   else MNMsg := '';
   AddLineToDebugLog('console',format('%-35s : %15s  %s',[thisadd,int2curr(ThisBal),MNMsg]));
   end;
inc(counter);
until thisadd = '';
AddLineToDebugLog('console',format('Freezed %d : %s',[count,int2curr(Total)]));
End;

{ShowsSummary file info}
Procedure ShowSumary();
var
  SumFile : File;
  Readed : integer = 0;
  ThisRecord : TSummaryData;
  IndexPosition : int64;
  CurrPos       : int64 = 0;
  TotalCoins    : int64 = 0;
  AsExpected    : string = '';
  NegativeCount : integer = 0;
Begin
  AssignFile(SumFile,SummaryFileName);
    TRY
    Reset(SumFile,1);
    While not eof(SumFile) do
      begin
      blockread(sumfile,ThisRecord,sizeof(ThisRecord));
      if thisrecord.Balance<0 then
        begin
        Inc(NegativeCount);
        AddLineToDebugLog('console',Format('%s : %s',[ThisRecord.Hash,Int2curr(ThisRecord.Balance)]));
        end;
      inc(TotalCoins,ThisRecord.Balance);
      Inc(currpos);
      end;
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  if TotalCoins = GetSupply(MyLastBlock) then AsExpected := '✓'
  else AsExpected := '✗ '+Int2curr(TotalCoins-GetSupply(MyLastBlock));
  AddLineToDebugLog('console',Int2Curr(Totalcoins)+' '+CoinSimbol+' '+AsExpected);
  AddLineToDebugLog('console','Negative  : '+NegativeCount.ToString);
  AddLineToDebugLog('console','Addresses : '+currpos.ToString);
End;

Procedure ShowConsensus();
var
  counter : integer;
  LText   : string;
Begin
  AddLineToDebugLog('console',Format('(%d / %d) %d %%',[Css_ReachedNodes,Css_TotalNodes,Css_Percentage]));
  for counter := 0 to high(consensus) do
     begin
     LText := Format('%0:12s',[NConsensus[counter]]);
     AddLineToDebugLog('console',Format('%0:2s %s -> %s',[Counter.ToString,LText,Consensus[counter]]));
     end;
End;


END. // END UNIT

