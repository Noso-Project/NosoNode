unit mpParser;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpGUI, mpRed, mpDisk, nosotime, mpblock, mpcoin,
  dialogs, fileutil, forms, idglobal, strutils, mpRPC, DateUtils, Clipbrd,translation,
  idContext, math, mpMN, MPSysCheck, nosodebug, nosogeneral, nosocrypto;

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
Procedure ShowSumary();
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
Procedure GroupCoins(linetext:string);
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
Procedure showPosrequired(linetext:string);
Procedure ShowBlockMNs(LineText:string);
Procedure showgmts(LineText:string);
Procedure ShowSystemInfo(Linetext:string);

// EXCHANGE
Procedure PostOffer(LineText:String);

Procedure DebugTest(linetext:string);
Procedure DebugTest2(linetext:string);

Function Fest(Lparameter:string): int64;
Procedure CheckFestIncomings(Address:String);
Procedure totallocked();

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
else if UpperCase(Command) = 'SUMARY' then ShowSumary()
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
else if UpperCase(Command) = 'REBUILDSUMARY' then RebuildSumario(MyLastBlock)
else if UpperCase(Command) = 'REBUILDHEADERS' then BuildHeaderFile(MyLastBlock)
else if UpperCase(Command) = 'GROUPCOINS' then Groupcoins(linetext)
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
else if UpperCase(Command) = 'DECTO58' then
  begin
  AddLineToDebugLog('console',BMDecTo58(parameter(linetext,1)));
  AddLineToDebugLog('console',B10toB58(parameter(linetext,1)));
  end
else if UpperCase(Command) = 'HEXTO58' then
  begin
  AddLineToDebugLog('console',BMHexTo58(parameter(linetext,1),58));
  AddLineToDebugLog('console',B16toB58(parameter(linetext,1)));
  end
else if UpperCase(Command) = '58TODEC' then
  begin
  AddLineToDebugLog('console',BM58ToDec(parameter(linetext,1)));
  AddLineToDebugLog('console',B58toB10(parameter(linetext,1)));
  end
else if UpperCase(Command) = 'DECTOHEX' then
  begin
  AddLineToDebugLog('console',BMDectoHex(parameter(linetext,1)));
  AddLineToDebugLog('console',B10ToB16(parameter(linetext,1)));
  end
else if UpperCase(Command) = 'HEXTODEC' then
  begin
  AddLineToDebugLog('console',BMHexToDec(parameter(linetext,1)));
  AddLineToDebugLog('console',B16toB10(parameter(linetext,1)));
  end
else if UpperCase(Command) = '58TOHEX' then
  begin
  AddLineToDebugLog('console',BM58toHex(parameter(linetext,1)));
  AddLineToDebugLog('console',B58toB16(parameter(linetext,1)));
  end
else if UpperCase(Command) = 'NOSOHASH' then AddLineToDebugLog('console',Nosohash(parameter(linetext,1)))
else if UpperCase(Command) = 'PENDING' then AddLineToDebugLog('console',PendingRawInfo)
else if UpperCase(Command) = 'HEADER' then AddLineToDebugLog('console',LastHeaders(StrToIntDef(parameter(linetext,1),-1)))
else if UpperCase(Command) = 'HEADSIZE' then AddLineToDebugLog('console',GetHeadersSize.ToString)
else if UpperCase(Command) = 'CHECKSUM' then AddLineToDebugLog('console',BMDecTo58(BMB58resumen(parameter(linetext,1))))

// CONSULTING
else if UpperCase(Command) = 'NETRATE' then AddLineToDebugLog('console','Average Mainnet hashrate: '+HashrateToShow(MainNetHashrate))
else if UpperCase(Command) = 'LISTGVT' then ListGVTs()
else if UpperCase(Command) = 'SYSTEM' then ShowSystemInfo(Linetext)
else if UpperCase(Command) = 'NOSOCFG' then AddLineToDebugLog('console',GetNosoCFGString)
else if UpperCase(Command) = 'FUNDS' then AddLineToDebugLog('console','Project funds: '+Int2curr(GetAddressAvailable('NpryectdevepmentfundsGE')))

// 0.2.1 DEBUG
else if UpperCase(Command) = 'BLOCKPOS' then ShowBlockPos(LineText)
else if UpperCase(Command) = 'POSSTACK' then showPosrequired(linetext)
else if UpperCase(Command) = 'BLOCKMNS' then ShowBlockMNs(LineText)
else if UpperCase(Command) = 'MYIP' then AddLineToDebugLog('console',GetMiIP)
else if UpperCase(Command) = 'SHOWUPDATES' then AddLineToDebugLog('console',StringAvailableUpdates)
else if UpperCase(Command) = 'SETMODE' then SetCFGData(parameter(linetext,1),0)
else if UpperCase(Command) = 'ADDNODE' then AddCFGData(parameter(linetext,1),1)
else if UpperCase(Command) = 'DELNODE' then RemoveCFGData(parameter(linetext,1),1)
else if UpperCase(Command) = 'ADDPOOL' then AddCFGData(parameter(linetext,1),3)
else if UpperCase(Command) = 'DELPOOL' then RemoveCFGData(parameter(linetext,1),3)
else if UpperCase(Command) = 'RESTORECFG' then RestoreCFGData()
else if UpperCase(Command) = 'ISALLSYNCED' then AddLineToDebugLog('console',IsAllsynced.ToString)
else if UpperCase(Command) = 'FEST' then Fest(parameter(linetext,1))
else if UpperCase(Command) = 'FEST2' then CheckFestIncomings(parameter(linetext,1))
else if UpperCase(Command) = 'FREEZED' then Totallocked()

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

// muestra el sumario completo
Procedure ShowSumary();
var
  contador : integer = 0;
  TotalCoins : int64 = 0;
  EmptyAddresses : int64 = 0;
  NegAdds : integer = 0;
  ThisCustom : string;
  CustomsAdds : string = '';
  DuplicatedCustoms : string = ' ';
  DuplicatedCount : integer = 0;
  BiggerAmmount : int64 = 0;
  BiggerAddress : string = '';
  AsExpected : string = '';
  NotValid   : integer = 0;
  NotValidBalance : int64 = 0;
  NotValidStr     : string = '';
Begin
EnterCriticalSection(CSSumary);
For contador := 0 to length(ListaSumario)-1 do
   begin
   if not IsValidHashAddress(ListaSumario[contador].Hash) then
      begin
      Inc(NotValid);
      Inc(NotValidBalance,ListaSumario[contador].Balance);
      NotValidStr := NotValidStr+contador.ToString+'->'+ListaSumario[contador].Hash+slinebreak;
      end;
   if ListaSumario[contador].custom ='' then ThisCustom := 'NULL'
      else ThisCustom := ListaSumario[contador].custom;
   {
   AddLineToDebugLog('console',ListaSumario[contador].Hash+' '+Int2Curr(ListaSumario[contador].Balance)+' '+
      ThisCustom+' '+
      IntToStr(ListaSumario[contador].LastOP)+' '+IntToStr(ListaSumario[contador].Score));
   EngineLastUpdate := UTCTime.ToInt64;
   }
   // Custom adds verification
   if ( (thiscustom <> 'NULL') and (AnsiContainsStr(CustomsAdds,' '+thiscustom+' ')) ) then
      begin
      DuplicatedCount +=1;
      DuplicatedCustoms := DuplicatedCustoms+thiscustom+' ';
      end
   else CustomsAdds := CustomsAdds+thiscustom+' ';

   if ListaSumario[contador].Balance < 0 then NegAdds+=1;
   TotalCOins := totalCoins+ ListaSumario[contador].Balance;
   if ListaSumario[contador].Balance = 0 then EmptyAddresses +=1;
   if ListaSumario[contador].Balance > BiggerAmmount then
      begin
      BiggerAmmount := ListaSumario[contador].Balance;
      BiggerAddress := ListaSumario[contador].Hash;
      end;
   end;
{
if NotValid>0 then
   begin
   AddLineToDebugLog('console',Format('Not Valid: %d [%s]',[NotValid,Int2Curr(NotValidBalance)]));
   AddLineToDebugLog('console',NotValidStr);
   end;
}
AddLineToDebugLog('console',IntToStr(Length(ListaSumario))+' addresses.'); //addresses
AddLineToDebugLog('console',IntToStr(EmptyAddresses)+' empty.'); //addresses
if NegAdds>0 then AddLineToDebugLog('console','Possible issues: '+IntToStr(NegAdds));
if DuplicatedCount>2 then
   begin
   AddLineToDebugLog('console','Duplicated alias: '+DuplicatedCount.ToString);
   AddLineToDebugLog('console',DuplicatedCustoms);
   end;
if TotalCoins = GetSupply(MyLastBlock) then AsExpected := '✓'
else AsExpected := '✗ '+Int2curr(TotalCoins-GetSupply(MyLastBlock));
AddLineToDebugLog('console',Int2Curr(Totalcoins)+' '+CoinSimbol+' '+AsExpected);
AddLineToDebugLog('console','Bigger : '+BiggerAddress);
AddLineToDebugLog('console','Balance: '+Int2curr(BiggerAmmount));
LeaveCriticalSection(CSSumary);
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
  LOrders : BlockOrdersArray;
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
         AddLineToDebugLog('console',Format('%-35s -> %-35s : %s',[LOrders[counter].sender,LOrders[counter].Receiver,int2curr(LOrders[counter].AmmountTrf)]));
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
  ArrayTrfrs : Array of orderdata;
  currtime : string;
  TrxLinea : integer = 0;
  OrderHashString : String;
  OrderString : string;
  AliasIndex : integer;
  Procesar : boolean = true;
  ResultOrderID : String = '';
  CoinsAvailable : int64;
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
   AliasIndex:=AddressSumaryIndex(Destination);
   if AliasIndex<0 then
      begin
      if showOutput then AddLineToDebugLog('console','Invalid destination.'); //'Invalid destination.'
      Procesar := false;
      end
   else Destination := ListaSumario[aliasIndex].Hash;
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
   Comision := GetFee(Monto);
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
   AliasIndex:=AddressSumaryIndex(Destination);
   if AliasIndex<0 then
      begin
      if showOutput then AddLineToDebugLog('console','Invalid destination.'); //'Invalid destination.'
      Exit;
      end
   else Destination := ListaSumario[aliasIndex].Hash;
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
   reward := InitialReward div StrToInt64(BMExponente('2',IntToStr(contador)));
   MarketCap := marketcap+(reward*BlockHalvingInterval);
   Texto := Format('From block %7d until %7d : %11s',[block1,block2,Int2curr(reward)]);
   //Texto :='From block '+IntToStr(block1)+' until '+IntToStr(block2)+': '+Int2curr(reward); //'From block '+' until '
   AddLineToDebugLog('console',Texto);
   end;
AddLineToDebugLog('console','And then '+int2curr(0)); //'And then '
MarketCap := MarketCap+PremineAmount-InitialReward; // descuenta una recompensa inicial x bloque 0
AddLineToDebugLog('console','Final supply: '+int2curr(MarketCap)); //'Final supply: '
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
AddLineToDebugLog('console','Coins to group: '+Int2curr(Total)+' '+Coinsimbol); //'Coins to group: '
if uppercase(Proceder) = 'DO' then
   begin
   if Total = 0 then
     AddLineToDebugLog('console','You do not have coins to group.') //'You do not have coins to group.'
   else
     ProcessLinesAdd('SENDTO '+Listadirecciones[0].Hash+' '+IntToStr(GetMaximunToSend(Total)));
   end;
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
   AddLineToDebugLog('console','All bots deleted');
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
  if ListaSumario[AddressSumaryIndex(Address)].custom <> '' then
    Address := Format('%s [%s]',[Address,ListaSumario[AddressSumaryIndex(Address)].custom]);
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
Begin
addtoshow := parameter(LineText,1);
sumposition := AddressSumaryIndex(addtoshow);
addhash := ListaSumario[sumposition].Hash;
if sumposition<0 then
   AddLineToDebugLog('console','Address do not exists in sumary.')
else
   begin
   onsumary := GetAddressBalance(addtoshow);
   pending := GetAddressPendingPays(addtoshow);
   AddLineToDebugLog('console','Address   : '+ListaSumario[sumposition].Hash+' ('+IntToStr(sumposition)+')'+slinebreak+
                    'Alias     : '+ListaSumario[sumposition].Custom+slinebreak+
                    'Sumary    : '+Int2curr(onsumary)+slinebreak+
                    'Incoming  : '+Int2Curr(GetAddressIncomingpays(ListaSumario[sumposition].Hash))+slinebreak+
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
  ArrTrxs : BlockOrdersArray;
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
            incomingtrx += 1;
            inccoins := inccoins+ArrTrxs[contador2].AmmountTrf;
            transSL.Add(IntToStr(Counter)+'] '+ArrTrxs[contador2].sender+'<-- '+Int2curr(ArrTrxs[contador2].AmmountTrf));
            end;
         if ArrTrxs[contador2].sender = addtoshow then // outgoing order
            begin
            outgoingtrx +=1;
            outcoins := outcoins + ArrTrxs[contador2].AmmountTrf + ArrTrxs[contador2].AmmountFee;
            //transSL.Add(IntToStr(Counter)+'] '+ArrTrxs[contador2].Receiver+'--> '+Int2curr(ArrTrxs[contador2].AmmountTrf));
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
inbalance := GetAddressBalance(addtoshow);
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

Procedure showPosrequired(linetext:string);
var
  PosRequired : int64;
  contador : integer;
  Cantidad : integer = 0;
  TotalStacked : int64 =0;
Begin
PosRequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
for contador := 0 to length(ListaSumario)-1 do
      begin
      if listasumario[contador].Balance >= PosRequired then
         begin
         Cantidad +=1;
         AddLineToDebugLog('console',listasumario[contador].Hash+': '+Int2curr(listasumario[contador].Balance));
         TotalStacked := TotalStacked +listasumario[contador].Balance;
         end;
      end;
AddLineToDebugLog('console','Pos At block          : '+inttostr(Mylastblock));
AddLineToDebugLog('console','PoS required Stake    : '+Int2Curr(PosRequired));
AddLineToDebugLog('console','Current PoS addresses : '+inttostr(Cantidad));
AddLineToDebugLog('console','Total Staked          : '+Int2Curr(TotalStacked));
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
if ((numero <1) or (numero >2000)) then
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
FeeTotal := GetFee(amount)*feetramos;


if FromAddress = '' then ErrorCode := -1
else if direccionEsMia(FromAddress) < 0 then ErrorCode := 1
else if ((amount = 0) or (amount+GetFee(amount)>GetAddressAvailable(FromAddress))) then ErrorCode := 2
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

Function Fest(Lparameter:string): int64;
var
  gpuaddresses   : string = 'N3rDNAzuFcyBnH3rG5M56bBjq2bnwDr N3qnz2zu74DVjYoVroHrNNNbUM8qsFx N33DAWq68ACWpGc6XL62PPG4zZ1RK9r N2njS6xiWN2it4VBpq2u39As49jSMDJ N3GVPtCtJEecL7k8ncTQttV6aynMNEj N2ws6PCwsSXGtAWxughYv9XnACmyPGY N4YubUBaEemehazgZqKD3R8hJM7zZEt N3anJkZy3j3Ee1pHBCrSxG9W6tPheDq Np6ZiMh4hVZ19wEkCdQMvT7yVdMhE8 N2pVvkCaaW7JCkhXoa9dcJjVErKi3Eg N33ESwr5vftYf8A3BUqkChG5yJpP5DT N3HQcYAon9eSzr8SbYX4nsjPVbhmMFT N2KcXAFbBqibnsk7MbZ3psr25beqpFC N3fxxEuLQU8Zz1LauraHhzAZrCrpcGi N2cZaWaJ3bqLkPhMZyKZnUhskJWFMFL N2U2Jcb1Xxiu9rDGRM2TnSB63u5n1By N2HopBx11qPw94Ayv34jdXXyUBqnHEL N4BGneSP3HeGi5egN7EJTP45C5f4SAL N2zJbdxt5t9SCQZ3E16CvzofjdQyzFZ N3yKqmmeuCzGdxw19QL8iXJf3nDXaFP N44SfiknCrrWpLiMgQPPvwm7nHU7yG7 NqZGWu1rJVXcBeZMzLE5rPsYBpcvFD N499FWbPsUY5h3p4sRPF2qQRRpVrXDB N2rrmqCHkCiBV8ScF1LWY5SaRJNryDm NQKQyKBuehBs3APqDENucFdUEFYzDp N2vmSe7amrjDncce9NTxsWBn5xhCbGH N48nrMA42tNqaF165AamNRF2J8xYoBc N3iTmGhUjWUn6Vmn6paWSXbKzPsDpFz N2BqfnLgg1NYPq16Qe3Go34swEmEGCn N4YutV8NjshtyeBBcxG9nfqb8r942FQ N4ACwJftf6JvpZcEwvLPjC2G3vZCVED N4Gg7JwHQrSA9X4sHr65UWZSvstedE8 N2Rp15hLv8ouxANmBPRzGd5vvZaZcFH N4DtkgbLtNWXhcxJYJxWmBQf4hAttGB N2Nq8jVfVrR5hcjV2MGPBgmpHt9KSDx N4WEZUeRiQyeC2wqiZF7HLaX59RCXD9 N4SWhz5DUeFMFRx3h8HsztjKbrGFxEz N3Qz5iNztWzNxKER26eomYAg5Jz7rF7 N2F5qhZkW9CTGhe35NpfYyr1NCgsBDY N2o1biP6zPaBXwjoPHYdAhGqqajswGJ N3TVNtbCxQ564FrRBEbs7mtSQzdg4Dn N4EEsEA87BC6eYEoJYsiuaUpaVqvLDs N365M7yrKMSoRb1NdTSi92ViRjxWTDH N3ceEphqsW7WLnRhwzYaY4kcahYx4Gk N3ADQ9EfUi4jiWbRzTBnoMPSbK3jTDQ N43jf8nHbBoeNsUJoMvntScpn3xQWG2 N3p8pPQcJTiZ9uGCnDsvNsK3E2hAiDm N49wrHQzgfb3tDNAc9wHxoaJNVbPZF6 N43pVv9PC9ccPFQPtMAdan3yt8aQzE3 N2tocd6Mma1MywbXMtAPwqWmF92QMEw N4Xyb6qv1XhptB92ykxvgXaytARCPGV N3UWTdwWMVShpLXdwQB3vNddkuJBfFY N3gL72Xd6JAPZiytD5LHTiAi85mbWCF N3QJ4hieJP7SXj1b6zKkuWFJ7dep6DA N2n4Aak9zx3TrVPgVrZFp9LZDJQZ8Dm N3cfBiBRn4YyzWBBq2Ji4HNwmFb62D5 N27RUfDzbJ8K2qe4oJ4torKagsEuKEC N28hfULqtCoHWpGnvbGsweYFyUu4AG6 N2ZadG2iPxoK6mgXHy7Lax79yK9XKDt N3J3ysVaRVDZvppGMz2LCiPG5MVfmED N4J199VisLqAtcPGrzV7W6CeV6eCzDK N4MTaXvXrnRir5SL6QApqVayM6aBPEd N3owtAdv7GUjQaTkcpobYV2hVC1YhFT N3cn3gvn4NMkC1ShGtjjvVUMxaPhQFQ N2HVqQ3RtCH8w9GUte8FjnBsDKwiQDg N3G75Hg7qLEEWBBWMazhCEKhpWaUXCL N447fXsRapHXePfzAng1HEbWtwkGYF2 N46yS186TQ5K4ddAnbvH4Na8GbFcgBS N3YBRRqMSkaqjkxA6kQNpFijnvuDBFv N3S54MdbzyVcVbpKZymkAgVEiY6KqFP N2QB8bXS1m9wYdAEay6yYaY1k5R1kCo N42qytVBKcxMYSE3uJmgaScxEERUZEt N4CV2rBu6u26W7Q1fbprMEoj7p2FmCf N3yMhH1oAhe4aZF4AjfBr6tnkzDwZEm N2wuFjv3zJ5rTmmAhFzoknnP5MfKRGF N2CMsb31waojcohGfmgjPvNYJmkdsGg N3qgmKw8xJn3CCUhoKejjsX3fcjjzGY N2tLe75z572bArQgKNVDtffBtQGg1Co N3pXq4rt3XXGeZrpFv4VKc6NNEkFzEk N3URnnLCt7HniYKEAjkgVkbrY1zj1Ez N2LEyMQKgys3BmcDaCH5DsRZSXjeZDs N2QXr1Xuxem4F5HXm2yPYQrAF3mt4Di N3ZdSVifW4urbEwYEosY33mscpADAF6 N3TsWiPCAKTa58Kpy5H88KzXuz7mKDL N3oa8JShrsN4JW1o3ntTudawMpAxdFg N23qLbJ8sRZF1vWGiUTAXcMn7YLhHCu N3jEh4Fiekhxpks5HDhPuftXGWzMhGT N3G3EEM5F5y5Co7xHgnxhyjAJ1M1vCL N2xaaev56hG8aKqTamoRUCzEhLp5bEv N2xu9baca3dkcQ4WMtbjPjGWNY1tHEj N2CgeYNV9qjy5GMKAyJku5iQmKXFGDr N23WhGuuV9tcBH3TNEo1QLFdSav4XCn N3CniPhb6Kiz8VGTCrPoyuUtbLHtjFy N3dpTSkaVRronhPyW3wpGoR5ce6sbGb N2P9WTbYioCirCp5jT3hiAYts4fmKEj N3CkiMw1udKhwKKF2qCYCjbVCnx4kEX N3BuGCTjV9ZFRFJ466SG3DDXD3u9B9R N25uTAKe8ZxRZvCAC4AZsXThLznfXE7 N2c69eqGDtEigoeeehtp981oNuBmTF3 N39xnSHHphmUS4Pp21AQvv3TxovWNEg N2kqnfqQ3w9YNciYebDXXMXMaxrKZFz N4VDD6tfP2S6jbuZXrNKwTq7b8ybmEc N2t8DnUkkXWng5tq88fzGKfthE7uhFn NfkLphfSn2Yt67j5tWxyrxdZZ945Fa N2XirUt5ypAX8ZpMUVgrEsxeHmBFLFh N2m4WSY7kKhoRy4YFF55FvYbADvCdCt N315zyoJzoC4oGRwahA9ad6s7f5w6E6 N25mVh9kAn68frWwXcCoXqsqoSAkWFj N22bGXDNgRmektXn3e2bXCmN1YpRMDa N2ovckPZcLerGLZXDzfk2cdspTgnwHQ N3m5BbMLHiBWfxfmos6Y7CVXHZiqJEC N4GmHNYLb7QKUE46U2Lcm5VqB5ruPBi N3TbsPXYp9o9Tz17dzmgGHL1GYHZXDp N4ZANbLnjk7wVvyWwT93TPDVchqPwFg N2qqdinuU54rCHtvLKEUmYjss36UNFP N2YdUKrgB9nwdCNhSqt7RWPqZSqiNFb N2Co8xcsb9pXWzyx2S2YeaLqiQKYZFr N2RkMHuSeRJgqVHh66fv7AN1o4m6TCv N3CuD5jgKZAeb9p1oe54RLQ82u2ZaBr N2x2YGwMe3aSbbqLabctwioJrgrmDGk N4Fj7mLqkYuGyJSvWky5xJ52e9RbqFH N3hsddLn1eTyVXFP49yGkZ7SZp3GDDi N39bKq26Befv2HZHynP1UdSW7hSbpDG N2VzAiWuzwRdNjCSfnZEhvbSAagZSGc N2ELyH2T2Y4WBr5enVYXW57Qzaf7CBz N2AaEsqBYgqvkKfsaKJPiBSUaAbv8F2 N2GGCrBGGXToWzy4DPqPChK7qjd5WDM N3mHbGgc7wkdBWetRrCAw6pNN6c4CDs N4Xd1HZvwYBBEwdgkt4NbHz2jY27tEM N3aCRXhxRZUNrA9TbRa6Y9C7MABpWCM N3vzej6WubCbA22zB9Kp2L7kJprZADb N2KRgE74P4aqmNbdBAbe9KvZXzCH8CW N3g3HBb3ejA8A21WtCdWVLXWwgdvGCY N45ieftyTZ4BnvZDM5UhbVDyEb5BxET N34Gvggc57bnvKEpTtGg2P6Mbbh9FDL N33xXYm15w65ZiqCtQ9p8qFYby5jDDm N49o5Qf4KzsuTvv9U1xrnKHkUxmL3FX N28c8oagK9vBJ4XCkK2hMyYqR7qVtDd N3QeeoUPUfSgUoXA8PZQMQghidwirFs N2boMVGF73UGXUnxxU7tgdLQatdFZEa N2JybRS3ADN3xdXh5HzNx8ok4pywWEq N227mFt3vBUsWG8LJC5kGeGGKp5ddBp N2MKqzPAy7XetXMBELP7sjFCruECFDc N2akq1adfVUeiosAbhgcTFLAXAX6PEV N2gcG3cwKtgbBn9gWGUNGWEyitfj9Ey N2TPkfJtzHsh7wq1QZBzXFvbp1Um6Fa N3Cg1eZWCqYUAPVhFmzTKxujAvXMiFG N25nvVuxeQL9oA274qHyPh1RSEozME4 N3pPjdHL1F7JpQJQfm27rLg9jzdPYDU N4PA2LcZFMo8bQ7YQERf5SGQjU9sqC5 N3dFfmLqYvJAf8zm7MJBym76rdr45E9 N49oEeCYPuTT9krUDmmAo5hQfn8mYEc N2CX2tAEHwFRvC87uaugWe9XJyj7HDP N2C8gpeDsvcsszXayNrufArQgJaDcHJ N3Q6DJgyZsMCu5w7a8rHjKr5g7eacDx N3JrStw1FQSpBmuDm18d5ZvXWonx3Ew N36S4ZouYDKevfVtqLNHxqm7dt3iqFy N2DuRyizg3FixB275vwDB1iAQH2anDH N2LBeivs9dodkoyUnrzdLpMY5Q6cHGT N44JNgv1dLCPCWcQt672R8an3mcVdC2 N3nRNW1VikmAKwCX85X9UqsuUjCgnEc N3BNDcrACstRkdcVPgBDCCjAnWXpxER N2iu1HpaftYBaTVoZMbANyPemT2pxFn N41Sk3c3Cc7HZVRqH3ASf5bdZv1HhBc N3X3Syy8CdcWnLx2SKG7bMQcZyVdtEb N3gwiZMmVm1og1z8Yoxmd3ev1BGbFFK N3TD9SKdXef3ZnJVp8maBSasUpowfF6 N3eWDeyCCHGi6G1PAjamHTQAThETgCJ N3vJF3WmE2Em7PhMYp5VNdJJ9rbQAC7 N4JCq8z46nnNaM7vrMLBmRRp7Dzw2Dn N2QBMZWjTu6YHkBR7X4wcVKYWLhgrDr N2oRUgQJh3yEts7U9dujDCSHEdswdF2 N3TvfuJ5W9Qqt1GeWPW6CooJkFfMWDy N3SfDni4484JNjFb2nPEFNQdUSXsPBy N4AMx1MXWm7dfRRwvH8he2MNXvX1BDF N49xfVsGA6FRrppsThLZzckAbVVcHFZ N3Y7EbcqrcyswYBbA8HZY6XQYGFtvEt N2JCB8zkK9vFfDaaxvLG7LdgBFHrGD6 NdmXp2C33phxc9L2Tsxug68EzdSuEi N37CsHtfQHyWigRFhEjY1uMmipEpWFQ N3KfRgaZR4Z9gDhSe8VhnfWzn8ZRFEK N4FpCg386DWpMz3TzMA1cJTPkceXYCn N23gP6NL8EUuipA99M8xnAPzzYg5MCr N3f3STZ51ELJeQhD87wREzeTPUu5VCA N3qz9NzL3yns2wLWYKkn7WrKENpgFFW N4KaLTFccTRu8u2QvEDyKY2mz1bUWDp N2MxoJ3FPTrnGVyqwTiVM2SiN6SYcEk N3JRStapK2fAFJnGU41T8Wn6yiydaDR N2JKpyinRqJ1YSKm7PLnmf8yn3tYBEw N3kkwyxhUEe3dqfigJQtzfFkmYtY1Ho N2Y3jWWUC5f9DoctgxDRBQbwqHB8bDd N2KRsrchWCK5RenSoJ7KhVTAw7SvSEA N2RrNcwkQrP1LRbvAju2TDSezbEjyFn N38SXYz26Wo8XoUEFVssYr3QhsZ4hEF N4CCaQQzw2qXLgUyf4uerk3dtRGYXFb N2aCJFKXGrPYt524mUwANYNvnZmHNDP N3wpRiSNtnziwQeqBEEKsdbJLgsK5GN N25ofKTb6iQsYzRsnYbAZgMqkYtFkGK N4YtN748YBR7Z5fMAUJYMBuG8jM1GAX N2dssuRRHQtBHxC7sWnqXK1xKZaYbFd N2vMZWS8atDqiUyL6p8V6v4zz7WqwFi N3RELs7u4LyaaJ72h7Mc6WyxCgrUqE1 N46HAHkBUqpMi6DwwDPs2JPkvqaiyEw N7YybmwQiMCdUwsEaMzzTJjBS331Ee N24qwaBf6eDCaqisj4V4M1Bc85pmACf N2kH1p7BFhF5VVqTSstrA6HF83G2NBB N4QX1gzGrzFEBrzruAUsbtNpLsTyfHJ N4NZ4MWL3kc7zFM7pY5a8SMAEg98bB8 N2ggoPCywntouK19ZAshxWF2mjNL5Fd N3sc6xJA8feisQBBMMUkp15Mt9DPcD3 N2jyQUekL6DcxzU5eJBLD6bXZ3mFiDm N3chKjoWpYtbyUTegQhtah4VubgyVJ2 N2FjbBeucnBSttjVhLPyyJ1BfcTFGFE N2UhsX6tK9oXAPUowuAeiqLv27iURFB N2VbUfKdFMqGsjos4LvKCDkdzvLLvFt N42vxNHLcodEwii3PcJmr9AJhSdnmFG N4W7YgKUynWuvC2oZwzff9hEs6bhsGc N3M7LbtQHWzUeB3N7Ar8vKUvTfLHECs N3GPRA8gRrgMpL8Rp1yfanZh27svzEt N4ZLHLazeqVaKca7dzHEGJbLWyMPgEd N3JF6vWNzgFKTnTAc1KhqqB9yq7EJDT N3jPKSWkE6pjuCusWwkeHutoZEAwLGf N3jrvvbrByUGX3pvJE2TPZN4YCDSuEb N3WYiUAcyjZMaYgR4cYZpe6GghThvFj N4XnBqbtghEhZpJoEAsj2G2hBgJgkF3 N3cThNgZ45y2jUA6VGkYLTUbupGETDP N3ekJe7MKeGVayYEPkqKLYqcV9ycjFF N3ojSxiM2pMFXkhzfSbw5Lyk6YLZaG7 N4196NPg2HFTW1522h2VK6shKo5ctA5 N3DGXbPyUoqVtHYXRXVPrRVmdDfUHFF N3kzHCSzavTuLA2SVybcHeWR5McJwF7 N3t9SckJfXzpbF82sAmbVPsTfYkyeG8 N4SH5yif3JLqSQJTmFafvnfeas5GNEY N2w22N5st47C1AArmMtvkP4k8fcKTCc N2Uq2YEDCLE1QdQ1ZTdC3sZDh4GxkBc N2xcgumEX3ZfXRPjzxJo3pnj7RdQRGE N3hpxYechdTGuTHBPmd58uZtPytaUGc N3b8AuWPXi3yLzwZ8qcerkpfzA8XwGe N2JaErDgPcG2Yk3mSiRVPnL4HzXvnEC N28aMph6nsSgTkGcKmQbD9uN59uR2Dd N2xj7x6NbHLwfhT1jE3rGBqJfqnP9EG N33ZEXq9QSCkU9pkTyiW1L4KUhduoE2 N4YP47WC9rpRwg4avUJ6rZdz4AvryEw N3tXX7iQ9XazigSKRv7446bNV2T3HCK N3fYdzCUWvQtKTF8wm8Y4mzbMt95JEk N3WMNviqqp4XhFY72oTpHvdi4yTu8FY N2y3eECDzF635iwJnzM2oksDnZ662Cs N3ANeMfCEhwV2N4NC4c5D4cTV7xonBq N2dXGQTpEFbUgwwiaqn6iiJ6bsf8cFi N2fdZNGCC85rRfwWsNU6GbvTSDx3HDG N3L13VCme2LRzhfk9BdWajyoY6bB8DH N2h9CUoTsFoT1UzXBxfYc1v2eUz2zEz N2ERhm2U21mLS6v8xG3SfuWGXSGy5CU N3p8TKfJX91EB8fdooFALoVpTnChLCx N25rx7UtqTEg6kL5ka7nSZ3x2odD3DZ N4MFDtvMPSdo14Ae4EipZADd3HEKBBQ N3Mk7HSUUybqwEHbX4KLQBc3Wc4y6Ct N4YiyXSTQb1JcYrTJdbrAxExM2CnzFJ N28mYg75cnHSzzY1XWZroDWPTfHm3EL N2xKbk8i829oNw2YmaD52hx15SdKuCw N2KkN9SECkCj17K2eicWxe9F7w3TMBn N2miQu7KM19GgyShA8WcC43N5hBMDBC N2d753XxE6gE5XUwyraPs9S2cwy48DP N2pmTn4xjFNjbAmJNcZwWBV4n3J2WDw N26USYi512ruoDL8AKo1HdHGJXmzQCA N2qWigrcvNmqavHxGgUSKL2azBpS9GL N4Zb7hKhYKM7z95rbGeEp2gdwPvccEa N26mJEzTDU6PutavjB2g3RmG5enwyEe N313owetoYouHCqxBtg13aV1gBj9FEL N2MV8QgdXLsVoUKnHuMczd7nu8HsQFM N32PcMi8F3EnBTSdfRhtUhjQ3cebqDm N3BQQf7zNS7dZBRfLv29sYPRxqrUGDz N34fq2omtACQibMhq51PngrRPgDAsEM N3V2GCrWMBybZUXJUxndXDUeY8iWQE8 N4J1rP5PpQ999ey4TEee3DquWyrf1DB N3kFjtm4A9wAxJ9QZHXTrc8s38QsXDk NAW93jU9HufNTFEm2J4NsF6bC17rAf NA3UdWYd4NWku6v6KL7gPStHM11bBt N4Z6qqJvumBupXJFfGtQPzoEZoSmuH9 N4Wd5NyqN72nPESZ7puN5JTh3kLp2Cr N3SfWZ35MckB7DFadpjXae9Ts4LFUCg N22bhdv4mUawzEXfosscEx6Dt5P7XFY N4EKcqkSrxZSHF4nQHRbkwvkbx76CFE N3wbMegcSaGmRb2ot3RtVReXMkZ4QEz N3pXHaJYtaz7unsmuYCM7kpvbent6HN N2EjptjicmYAj74EAikWRT9HkXhsHEi N2zRVYQzmpxLJSANujxXG7gCRSi4EF3 N3HJJFqXfaCQPhzV8beffFZV7eEnLDq N3JFDuT4dJmCxsEcuN3vXZTwXs8XgF2 N4VRrMEsp7kvnBXKARiJ5nDeAFiHfDs N2VaLTyPNZ842YqT13H6ydBpqS1NDBu N2MjmwT8ZzcAZVmUjAGN51jssB8UHDx N38EFB5pBe2vCosT4HNAPji8c47obBd N2wh7zNHHq45ECNzQcEmqSYtMucPsF6 N2etWLN9w3doFescqweegs9L1X7e9F2 N4EuW8Hg3ChNBkYprKPZQrAd7wPRTDf N269VttywPZKzjmKp6GpYsSj1z7peGT N3dFsK9vGhw4kDX7UezKTYpfCV89EDd N4HD1zLstgfXPNJUWSxYMxWwzKUrJFy N3REdWyHV23m6DDATqi1CZb9yKvmzDN N2LXAwk3WD524anDngj6TthMWjyuxEn N43JWM5uSMQQrVoRB3gDRtdMzhm1BDF N2SeLLxEAmn2SVtB26EX6WMnaK5WjCK N33UatDLrJxrSEZqqsgLfEJ1AGGK1DL N3AFvA7UoZAxvzZLb3HExfV3BXsxAEC N28jBJDp9jBzUHR6j6HxqJuLMFVErD8 N2RvwbXP4hs2CE1V2HoAzDUgVEt5wDS N2fu7b8PMHFMpYdxKCUcq4nZMQqBKDi N3Kd8rD43snaDbBGmYogjypfPAEi2E4 NAf2wStjjKZw1YLNBrJmHZsWsJV2ET N3XYm2yU8dkA8SE7mzsUrpsSxfxmrGz N24BDDRYqWnU8tZuGp3kx8ns248NsDb N31FZ3GKrL9wavRrGUZaJReYHB2UUCY N2pbRVacnb4koYpKQVhaRDyp8wzcQGf N2JGSuXjAoQW1Ty8S44VpjJuSwMR4DS N3taBpXabCtCFq4JsVxV1XWQg5feGEJ NALNGYBW1eT1KPUXGoHtxzNoaGe4Ct N4W2x7HGkvzu2ckN9NRJDtWxGHakiEi N3ZmR8u6SJa3GWceR49EAmNhQD1i2BK NAuyF59bpQY1Y5FRJy8AeCte714GBM N2ScVcWiCBjY4gQSFsn6G1A5syUvwE7 N2xwnMbPwrgcqxTxUrt5DXyVY5KXcHg N3NBsXTovBrQQxkMuTFVSeJZnahRxGL N3UE2nV7gEoBXSeY1m2erffE4qLq6D1 N2kJYd3H3g3o7FQAcY63kS85VBsCqB7 N3ZbWUTToesJHTyFFuicyucAPwoZzHG N3zBfLvWUhMey1zDm87ArPkbqEbhTFM N2tr6odTWaXCYgDPnLN72ReP8qoiLE4 N2BL9Y1EpbFmggG7K5pq93pqtPsQtDk N3Ts8k5sSvgHxpy3yrAD7SBD7ZWFmES N2qKKeR31A9rdhnidMzuDXtvZ8SpZFK N2en85z451qJYP5RyuXh2AK5JvUMVCN N2uSzE87a7gJrf6kTZYE95aquBSarE2 NBWxfNhtu7WjEWjUDQwUrpPTZx35FS N2ngTm4CTVpN8LWcZb6JPivyUwfFbEw N3Mufwyptb58oRKgrSszG8NNCZZEZFn N2B9wGnxKP5KVYqXuywRsQNJ6vcL4En N2kmTD4mnm4kxb8eCDP7ApP3VRy49Cv NBdadsbFs4M7ksP9Zq6KVpj5bX94DK N2WB1byXUaQN4bWXeN33f41B9SDHUAg N2FysS8GDe8mRT1jZ8cLpN1EJV6PUBv N4BjVc8xpwaEXo1F4nTU8ghV4ZwGqEX N2ZA1qBU76rWsxkkXNjNVAHaUE3o8D7 NA1kMwKfyjquKYX2r6x6FrobUgpPFh N236dX6RLDZy7aCPfPuaLLNBukPjyDU N35KHsUqh1SQGDGHcDZjhCU9bij12By N23ZopJmFYNfaMx8TETUi6M2GWaXxDa N2oFrcKzPxDU598XgtNQfNNmTVquAEu NtLp5upSBxt5FNTJYUfAnRmFHWtkF3 NSK88wtZSc1KB7m5oo5vFAQ9BEbTBj';
  StringToText   : string ='';
  thisaddress    : string = '';
  ThisBalance    : int64;
  totalbalance   : int64 = 0;
  addressescount : integer = 0;
  counter        : integer = 0;
  ActiveMNs      : integer = 0;
  counter2       : integer = 0;
  counter3       : integer;
  counter4       : integer;
  ArrTrxs        : BlockOrdersArray;
  OwnedGVTs      : string ='';
  Suspicious     : integer = 0;
  SuspiAdd       : string = '';
  MNsAddresses   : string = '';
  SuspBalance    : int64 = 0;
  SuspMNs        : string = '';
  FinalList      : string = '';
  FinalCount     : integer = 0;
  FinalBalance   : int64 = 0;
  ToLockStr      : string = '';
Begin
  result := 0;
  if LParameter <> '' then StringToText := LParameter
  else StringToText := gpuaddresses;
  repeat
  thisaddress := parameter(StringToText,counter);
  if thisaddress <> '' then
    begin
    ThisBalance := GetAddressBalance(thisaddress);
    totalbalance := totalbalance+ThisBalance;
    Inc(addressescount);
    if ThisBalance > 0 then
      begin
      FinalList := FinalList+'O) '+ThisAddress+' '+int2curr(thisbalance)+' '+ListaSumario[AddressSumaryIndex(ThisAddress)].custom+slinebreak;
      ToLockStr := ToLockStr+ThisAddress+':';
      inc(finalcount);
      inc(FinalBalance,ThisBalance);
      end;
    if AnsiContainsStr(GetMN_FileText,thisaddress) then
      begin
      Inc(ActiveMNs);
      MNsAddresses := MNsAddresses+ThisAddress+' ';
      end;
    for counter2 := 0 to length(ArrGVTs)-1 do
      begin
      if ArrGVTs[counter2].owner = thisaddress then
         OwnedGVTs := OwnedGVTs+counter2.ToString+' ';
      end;
    for counter3 := MyLastBlock downto 70000 do
      begin
      ArrTrxs := GetBlockTrxs(counter3);
      if Length(ArrTrxs)>0 then
        begin
        for counter4 := 0 to length(ArrTrxs)-1 do
          begin
          if ArrTrxs[counter4].sender=thisaddress then
            begin
            if ( (not AnsiCOntainsStr(SuspiAdd,ArrTrxs[counter4].Receiver)) and (not AnsiCOntainsStr(gpuaddresses,ArrTrxs[counter4].Receiver)) ) then
              begin
              Inc(Suspicious);
              SuspiAdd := SuspiAdd+ArrTrxs[counter4].Receiver+' '+Int2Curr(GetAddressBalance(ArrTrxs[counter4].Receiver))+slinebreak;
              Inc(SuspBalance,GetAddressBalance(ArrTrxs[counter4].Receiver));
              if AnsiContainsStr(GetMN_FileText,ArrTrxs[counter4].Receiver) then
                SuspMNs := SuspMNs+ArrTrxs[counter4].Receiver+' ';
              if GetAddressBalance(ArrTrxs[counter4].Receiver)>0 then
                begin
                FinalList := FinalList+'S) '+ArrTrxs[counter4].Receiver+' '+Int2curr(GetAddressBalance(ArrTrxs[counter4].Receiver))+' '+ListaSumario[AddressSumaryIndex(ArrTrxs[counter4].Receiver)].custom+slinebreak;
                ToLockStr := ToLockStr+ArrTrxs[counter4].Receiver+':';
                inc(finalcount);
                inc(FinalBalance,GetAddressBalance(ArrTrxs[counter4].Receiver));
                end;
              end;
            for counter2 := 0 to length(ArrGVTs)-1 do
               begin
               if ArrGVTs[counter2].owner = thisaddress then
                  OwnedGVTs := OwnedGVTs+counter2.ToString+' ';
               end;
            end;
          end;
        end;
      end;
    AddLineToDebugLog('console',format('Address [%d] %s completed - %s',[counter+1,Thisaddress,int2curr(ThisBalance)]));
    application.ProcessMessages;
    end;
  inc(counter);
  until thisaddress = '';
  result := totalbalance;
  AddLineToDebugLog('console','Addresses count: '+addressescount.ToString);
  AddLineToDebugLog('console','Balance        : '+int2curr(totalbalance));
  AddLineToDebugLog('console','Masternodes    : '+MNsAddresses);
  AddLineToDebugLog('console','GVTs           : '+OwnedGVTs);
  AddLineToDebugLog('console','Suspicious     : '+Suspicious.ToString);
  AddLineToDebugLog('console','Balance        : '+int2curr(SuspBalance));
  AddLineToDebugLog('console','Masternodes    : '+SuspMNs);
  AddLineToDebugLog('console','FINAL          : '+Finalcount.ToString);
  AddLineToDebugLog('console','FINAL BALANCE  : '+int2curr(FinalBalance));
  AddLineToDebugLog('console','FINAL LIST     : '+slinebreak+finallist);
  AddLineToDebugLog('console','TOLOCK'+slinebreak+ToLockStr);
End;

Procedure CheckFestIncomings(Address:String);
var
  gpuaddresses   : string = 'N3rDNAzuFcyBnH3rG5M56bBjq2bnwDr N3qnz2zu74DVjYoVroHrNNNbUM8qsFx N33DAWq68ACWpGc6XL62PPG4zZ1RK9r N2njS6xiWN2it4VBpq2u39As49jSMDJ N3GVPtCtJEecL7k8ncTQttV6aynMNEj N2ws6PCwsSXGtAWxughYv9XnACmyPGY N4YubUBaEemehazgZqKD3R8hJM7zZEt N3anJkZy3j3Ee1pHBCrSxG9W6tPheDq Np6ZiMh4hVZ19wEkCdQMvT7yVdMhE8 N2pVvkCaaW7JCkhXoa9dcJjVErKi3Eg N33ESwr5vftYf8A3BUqkChG5yJpP5DT N3HQcYAon9eSzr8SbYX4nsjPVbhmMFT N2KcXAFbBqibnsk7MbZ3psr25beqpFC N3fxxEuLQU8Zz1LauraHhzAZrCrpcGi N2cZaWaJ3bqLkPhMZyKZnUhskJWFMFL N2U2Jcb1Xxiu9rDGRM2TnSB63u5n1By N2HopBx11qPw94Ayv34jdXXyUBqnHEL N4BGneSP3HeGi5egN7EJTP45C5f4SAL N2zJbdxt5t9SCQZ3E16CvzofjdQyzFZ N3yKqmmeuCzGdxw19QL8iXJf3nDXaFP N44SfiknCrrWpLiMgQPPvwm7nHU7yG7 NqZGWu1rJVXcBeZMzLE5rPsYBpcvFD N499FWbPsUY5h3p4sRPF2qQRRpVrXDB N2rrmqCHkCiBV8ScF1LWY5SaRJNryDm NQKQyKBuehBs3APqDENucFdUEFYzDp N2vmSe7amrjDncce9NTxsWBn5xhCbGH N48nrMA42tNqaF165AamNRF2J8xYoBc N3iTmGhUjWUn6Vmn6paWSXbKzPsDpFz N2BqfnLgg1NYPq16Qe3Go34swEmEGCn N4YutV8NjshtyeBBcxG9nfqb8r942FQ N4ACwJftf6JvpZcEwvLPjC2G3vZCVED N4Gg7JwHQrSA9X4sHr65UWZSvstedE8 N2Rp15hLv8ouxANmBPRzGd5vvZaZcFH N4DtkgbLtNWXhcxJYJxWmBQf4hAttGB N2Nq8jVfVrR5hcjV2MGPBgmpHt9KSDx N4WEZUeRiQyeC2wqiZF7HLaX59RCXD9 N4SWhz5DUeFMFRx3h8HsztjKbrGFxEz N3Qz5iNztWzNxKER26eomYAg5Jz7rF7 N2F5qhZkW9CTGhe35NpfYyr1NCgsBDY N2o1biP6zPaBXwjoPHYdAhGqqajswGJ N3TVNtbCxQ564FrRBEbs7mtSQzdg4Dn N4EEsEA87BC6eYEoJYsiuaUpaVqvLDs N365M7yrKMSoRb1NdTSi92ViRjxWTDH N3ceEphqsW7WLnRhwzYaY4kcahYx4Gk N3ADQ9EfUi4jiWbRzTBnoMPSbK3jTDQ N43jf8nHbBoeNsUJoMvntScpn3xQWG2 N3p8pPQcJTiZ9uGCnDsvNsK3E2hAiDm N49wrHQzgfb3tDNAc9wHxoaJNVbPZF6 N43pVv9PC9ccPFQPtMAdan3yt8aQzE3 N2tocd6Mma1MywbXMtAPwqWmF92QMEw N4Xyb6qv1XhptB92ykxvgXaytARCPGV N3UWTdwWMVShpLXdwQB3vNddkuJBfFY N3gL72Xd6JAPZiytD5LHTiAi85mbWCF N3QJ4hieJP7SXj1b6zKkuWFJ7dep6DA N2n4Aak9zx3TrVPgVrZFp9LZDJQZ8Dm N3cfBiBRn4YyzWBBq2Ji4HNwmFb62D5 N27RUfDzbJ8K2qe4oJ4torKagsEuKEC N28hfULqtCoHWpGnvbGsweYFyUu4AG6 N2ZadG2iPxoK6mgXHy7Lax79yK9XKDt N3J3ysVaRVDZvppGMz2LCiPG5MVfmED N4J199VisLqAtcPGrzV7W6CeV6eCzDK N4MTaXvXrnRir5SL6QApqVayM6aBPEd N3owtAdv7GUjQaTkcpobYV2hVC1YhFT N3cn3gvn4NMkC1ShGtjjvVUMxaPhQFQ N2HVqQ3RtCH8w9GUte8FjnBsDKwiQDg N3G75Hg7qLEEWBBWMazhCEKhpWaUXCL N447fXsRapHXePfzAng1HEbWtwkGYF2 N46yS186TQ5K4ddAnbvH4Na8GbFcgBS N3YBRRqMSkaqjkxA6kQNpFijnvuDBFv N3S54MdbzyVcVbpKZymkAgVEiY6KqFP N2QB8bXS1m9wYdAEay6yYaY1k5R1kCo N42qytVBKcxMYSE3uJmgaScxEERUZEt N4CV2rBu6u26W7Q1fbprMEoj7p2FmCf N3yMhH1oAhe4aZF4AjfBr6tnkzDwZEm N2wuFjv3zJ5rTmmAhFzoknnP5MfKRGF N2CMsb31waojcohGfmgjPvNYJmkdsGg N3qgmKw8xJn3CCUhoKejjsX3fcjjzGY N2tLe75z572bArQgKNVDtffBtQGg1Co N3pXq4rt3XXGeZrpFv4VKc6NNEkFzEk N3URnnLCt7HniYKEAjkgVkbrY1zj1Ez N2LEyMQKgys3BmcDaCH5DsRZSXjeZDs N2QXr1Xuxem4F5HXm2yPYQrAF3mt4Di N3ZdSVifW4urbEwYEosY33mscpADAF6 N3TsWiPCAKTa58Kpy5H88KzXuz7mKDL N3oa8JShrsN4JW1o3ntTudawMpAxdFg N23qLbJ8sRZF1vWGiUTAXcMn7YLhHCu N3jEh4Fiekhxpks5HDhPuftXGWzMhGT N3G3EEM5F5y5Co7xHgnxhyjAJ1M1vCL N2xaaev56hG8aKqTamoRUCzEhLp5bEv N2xu9baca3dkcQ4WMtbjPjGWNY1tHEj N2CgeYNV9qjy5GMKAyJku5iQmKXFGDr N23WhGuuV9tcBH3TNEo1QLFdSav4XCn N3CniPhb6Kiz8VGTCrPoyuUtbLHtjFy N3dpTSkaVRronhPyW3wpGoR5ce6sbGb N2P9WTbYioCirCp5jT3hiAYts4fmKEj N3CkiMw1udKhwKKF2qCYCjbVCnx4kEX N3BuGCTjV9ZFRFJ466SG3DDXD3u9B9R N25uTAKe8ZxRZvCAC4AZsXThLznfXE7 N2c69eqGDtEigoeeehtp981oNuBmTF3 N39xnSHHphmUS4Pp21AQvv3TxovWNEg N2kqnfqQ3w9YNciYebDXXMXMaxrKZFz N4VDD6tfP2S6jbuZXrNKwTq7b8ybmEc N2t8DnUkkXWng5tq88fzGKfthE7uhFn NfkLphfSn2Yt67j5tWxyrxdZZ945Fa N2XirUt5ypAX8ZpMUVgrEsxeHmBFLFh N2m4WSY7kKhoRy4YFF55FvYbADvCdCt N315zyoJzoC4oGRwahA9ad6s7f5w6E6 N25mVh9kAn68frWwXcCoXqsqoSAkWFj N22bGXDNgRmektXn3e2bXCmN1YpRMDa N2ovckPZcLerGLZXDzfk2cdspTgnwHQ N3m5BbMLHiBWfxfmos6Y7CVXHZiqJEC N4GmHNYLb7QKUE46U2Lcm5VqB5ruPBi N3TbsPXYp9o9Tz17dzmgGHL1GYHZXDp N4ZANbLnjk7wVvyWwT93TPDVchqPwFg N2qqdinuU54rCHtvLKEUmYjss36UNFP N2YdUKrgB9nwdCNhSqt7RWPqZSqiNFb N2Co8xcsb9pXWzyx2S2YeaLqiQKYZFr N2RkMHuSeRJgqVHh66fv7AN1o4m6TCv N3CuD5jgKZAeb9p1oe54RLQ82u2ZaBr N2x2YGwMe3aSbbqLabctwioJrgrmDGk N4Fj7mLqkYuGyJSvWky5xJ52e9RbqFH N3hsddLn1eTyVXFP49yGkZ7SZp3GDDi N39bKq26Befv2HZHynP1UdSW7hSbpDG N2VzAiWuzwRdNjCSfnZEhvbSAagZSGc N2ELyH2T2Y4WBr5enVYXW57Qzaf7CBz N2AaEsqBYgqvkKfsaKJPiBSUaAbv8F2 N2GGCrBGGXToWzy4DPqPChK7qjd5WDM N3mHbGgc7wkdBWetRrCAw6pNN6c4CDs N4Xd1HZvwYBBEwdgkt4NbHz2jY27tEM N3aCRXhxRZUNrA9TbRa6Y9C7MABpWCM N3vzej6WubCbA22zB9Kp2L7kJprZADb N2KRgE74P4aqmNbdBAbe9KvZXzCH8CW N3g3HBb3ejA8A21WtCdWVLXWwgdvGCY N45ieftyTZ4BnvZDM5UhbVDyEb5BxET N34Gvggc57bnvKEpTtGg2P6Mbbh9FDL N33xXYm15w65ZiqCtQ9p8qFYby5jDDm N49o5Qf4KzsuTvv9U1xrnKHkUxmL3FX N28c8oagK9vBJ4XCkK2hMyYqR7qVtDd N3QeeoUPUfSgUoXA8PZQMQghidwirFs N2boMVGF73UGXUnxxU7tgdLQatdFZEa N2JybRS3ADN3xdXh5HzNx8ok4pywWEq N227mFt3vBUsWG8LJC5kGeGGKp5ddBp N2MKqzPAy7XetXMBELP7sjFCruECFDc N2akq1adfVUeiosAbhgcTFLAXAX6PEV N2gcG3cwKtgbBn9gWGUNGWEyitfj9Ey N2TPkfJtzHsh7wq1QZBzXFvbp1Um6Fa N3Cg1eZWCqYUAPVhFmzTKxujAvXMiFG N25nvVuxeQL9oA274qHyPh1RSEozME4 N3pPjdHL1F7JpQJQfm27rLg9jzdPYDU N4PA2LcZFMo8bQ7YQERf5SGQjU9sqC5 N3dFfmLqYvJAf8zm7MJBym76rdr45E9 N49oEeCYPuTT9krUDmmAo5hQfn8mYEc N2CX2tAEHwFRvC87uaugWe9XJyj7HDP N2C8gpeDsvcsszXayNrufArQgJaDcHJ N3Q6DJgyZsMCu5w7a8rHjKr5g7eacDx N3JrStw1FQSpBmuDm18d5ZvXWonx3Ew N36S4ZouYDKevfVtqLNHxqm7dt3iqFy N2DuRyizg3FixB275vwDB1iAQH2anDH N2LBeivs9dodkoyUnrzdLpMY5Q6cHGT N44JNgv1dLCPCWcQt672R8an3mcVdC2 N3nRNW1VikmAKwCX85X9UqsuUjCgnEc N3BNDcrACstRkdcVPgBDCCjAnWXpxER N2iu1HpaftYBaTVoZMbANyPemT2pxFn N41Sk3c3Cc7HZVRqH3ASf5bdZv1HhBc N3X3Syy8CdcWnLx2SKG7bMQcZyVdtEb N3gwiZMmVm1og1z8Yoxmd3ev1BGbFFK N3TD9SKdXef3ZnJVp8maBSasUpowfF6 N3eWDeyCCHGi6G1PAjamHTQAThETgCJ N3vJF3WmE2Em7PhMYp5VNdJJ9rbQAC7 N4JCq8z46nnNaM7vrMLBmRRp7Dzw2Dn N2QBMZWjTu6YHkBR7X4wcVKYWLhgrDr N2oRUgQJh3yEts7U9dujDCSHEdswdF2 N3TvfuJ5W9Qqt1GeWPW6CooJkFfMWDy N3SfDni4484JNjFb2nPEFNQdUSXsPBy N4AMx1MXWm7dfRRwvH8he2MNXvX1BDF N49xfVsGA6FRrppsThLZzckAbVVcHFZ N3Y7EbcqrcyswYBbA8HZY6XQYGFtvEt N2JCB8zkK9vFfDaaxvLG7LdgBFHrGD6 NdmXp2C33phxc9L2Tsxug68EzdSuEi N37CsHtfQHyWigRFhEjY1uMmipEpWFQ N3KfRgaZR4Z9gDhSe8VhnfWzn8ZRFEK N4FpCg386DWpMz3TzMA1cJTPkceXYCn N23gP6NL8EUuipA99M8xnAPzzYg5MCr N3f3STZ51ELJeQhD87wREzeTPUu5VCA N3qz9NzL3yns2wLWYKkn7WrKENpgFFW N4KaLTFccTRu8u2QvEDyKY2mz1bUWDp N2MxoJ3FPTrnGVyqwTiVM2SiN6SYcEk N3JRStapK2fAFJnGU41T8Wn6yiydaDR N2JKpyinRqJ1YSKm7PLnmf8yn3tYBEw N3kkwyxhUEe3dqfigJQtzfFkmYtY1Ho N2Y3jWWUC5f9DoctgxDRBQbwqHB8bDd N2KRsrchWCK5RenSoJ7KhVTAw7SvSEA N2RrNcwkQrP1LRbvAju2TDSezbEjyFn N38SXYz26Wo8XoUEFVssYr3QhsZ4hEF N4CCaQQzw2qXLgUyf4uerk3dtRGYXFb N2aCJFKXGrPYt524mUwANYNvnZmHNDP N3wpRiSNtnziwQeqBEEKsdbJLgsK5GN N25ofKTb6iQsYzRsnYbAZgMqkYtFkGK N4YtN748YBR7Z5fMAUJYMBuG8jM1GAX N2dssuRRHQtBHxC7sWnqXK1xKZaYbFd N2vMZWS8atDqiUyL6p8V6v4zz7WqwFi N3RELs7u4LyaaJ72h7Mc6WyxCgrUqE1 N46HAHkBUqpMi6DwwDPs2JPkvqaiyEw N7YybmwQiMCdUwsEaMzzTJjBS331Ee N24qwaBf6eDCaqisj4V4M1Bc85pmACf N2kH1p7BFhF5VVqTSstrA6HF83G2NBB N4QX1gzGrzFEBrzruAUsbtNpLsTyfHJ N4NZ4MWL3kc7zFM7pY5a8SMAEg98bB8 N2ggoPCywntouK19ZAshxWF2mjNL5Fd N3sc6xJA8feisQBBMMUkp15Mt9DPcD3 N2jyQUekL6DcxzU5eJBLD6bXZ3mFiDm N3chKjoWpYtbyUTegQhtah4VubgyVJ2 N2FjbBeucnBSttjVhLPyyJ1BfcTFGFE N2UhsX6tK9oXAPUowuAeiqLv27iURFB N2VbUfKdFMqGsjos4LvKCDkdzvLLvFt N42vxNHLcodEwii3PcJmr9AJhSdnmFG N4W7YgKUynWuvC2oZwzff9hEs6bhsGc N3M7LbtQHWzUeB3N7Ar8vKUvTfLHECs N3GPRA8gRrgMpL8Rp1yfanZh27svzEt N4ZLHLazeqVaKca7dzHEGJbLWyMPgEd N3JF6vWNzgFKTnTAc1KhqqB9yq7EJDT N3jPKSWkE6pjuCusWwkeHutoZEAwLGf N3jrvvbrByUGX3pvJE2TPZN4YCDSuEb N3WYiUAcyjZMaYgR4cYZpe6GghThvFj N4XnBqbtghEhZpJoEAsj2G2hBgJgkF3 N3cThNgZ45y2jUA6VGkYLTUbupGETDP N3ekJe7MKeGVayYEPkqKLYqcV9ycjFF N3ojSxiM2pMFXkhzfSbw5Lyk6YLZaG7 N4196NPg2HFTW1522h2VK6shKo5ctA5 N3DGXbPyUoqVtHYXRXVPrRVmdDfUHFF N3kzHCSzavTuLA2SVybcHeWR5McJwF7 N3t9SckJfXzpbF82sAmbVPsTfYkyeG8 N4SH5yif3JLqSQJTmFafvnfeas5GNEY N2w22N5st47C1AArmMtvkP4k8fcKTCc N2Uq2YEDCLE1QdQ1ZTdC3sZDh4GxkBc N2xcgumEX3ZfXRPjzxJo3pnj7RdQRGE N3hpxYechdTGuTHBPmd58uZtPytaUGc N3b8AuWPXi3yLzwZ8qcerkpfzA8XwGe N2JaErDgPcG2Yk3mSiRVPnL4HzXvnEC N28aMph6nsSgTkGcKmQbD9uN59uR2Dd N2xj7x6NbHLwfhT1jE3rGBqJfqnP9EG N33ZEXq9QSCkU9pkTyiW1L4KUhduoE2 N4YP47WC9rpRwg4avUJ6rZdz4AvryEw N3tXX7iQ9XazigSKRv7446bNV2T3HCK N3fYdzCUWvQtKTF8wm8Y4mzbMt95JEk N3WMNviqqp4XhFY72oTpHvdi4yTu8FY N2y3eECDzF635iwJnzM2oksDnZ662Cs N3ANeMfCEhwV2N4NC4c5D4cTV7xonBq N2dXGQTpEFbUgwwiaqn6iiJ6bsf8cFi N2fdZNGCC85rRfwWsNU6GbvTSDx3HDG N3L13VCme2LRzhfk9BdWajyoY6bB8DH N2h9CUoTsFoT1UzXBxfYc1v2eUz2zEz N2ERhm2U21mLS6v8xG3SfuWGXSGy5CU N3p8TKfJX91EB8fdooFALoVpTnChLCx N25rx7UtqTEg6kL5ka7nSZ3x2odD3DZ N4MFDtvMPSdo14Ae4EipZADd3HEKBBQ N3Mk7HSUUybqwEHbX4KLQBc3Wc4y6Ct N4YiyXSTQb1JcYrTJdbrAxExM2CnzFJ N28mYg75cnHSzzY1XWZroDWPTfHm3EL N2xKbk8i829oNw2YmaD52hx15SdKuCw N2KkN9SECkCj17K2eicWxe9F7w3TMBn N2miQu7KM19GgyShA8WcC43N5hBMDBC N2d753XxE6gE5XUwyraPs9S2cwy48DP N2pmTn4xjFNjbAmJNcZwWBV4n3J2WDw N26USYi512ruoDL8AKo1HdHGJXmzQCA N2qWigrcvNmqavHxGgUSKL2azBpS9GL N4Zb7hKhYKM7z95rbGeEp2gdwPvccEa N26mJEzTDU6PutavjB2g3RmG5enwyEe N313owetoYouHCqxBtg13aV1gBj9FEL N2MV8QgdXLsVoUKnHuMczd7nu8HsQFM N32PcMi8F3EnBTSdfRhtUhjQ3cebqDm N3BQQf7zNS7dZBRfLv29sYPRxqrUGDz N34fq2omtACQibMhq51PngrRPgDAsEM N3V2GCrWMBybZUXJUxndXDUeY8iWQE8 N4J1rP5PpQ999ey4TEee3DquWyrf1DB N3kFjtm4A9wAxJ9QZHXTrc8s38QsXDk NAW93jU9HufNTFEm2J4NsF6bC17rAf NA3UdWYd4NWku6v6KL7gPStHM11bBt N4Z6qqJvumBupXJFfGtQPzoEZoSmuH9 N4Wd5NyqN72nPESZ7puN5JTh3kLp2Cr N3SfWZ35MckB7DFadpjXae9Ts4LFUCg N22bhdv4mUawzEXfosscEx6Dt5P7XFY N4EKcqkSrxZSHF4nQHRbkwvkbx76CFE N3wbMegcSaGmRb2ot3RtVReXMkZ4QEz N3pXHaJYtaz7unsmuYCM7kpvbent6HN N2EjptjicmYAj74EAikWRT9HkXhsHEi N2zRVYQzmpxLJSANujxXG7gCRSi4EF3 N3HJJFqXfaCQPhzV8beffFZV7eEnLDq N3JFDuT4dJmCxsEcuN3vXZTwXs8XgF2 N4VRrMEsp7kvnBXKARiJ5nDeAFiHfDs N2VaLTyPNZ842YqT13H6ydBpqS1NDBu N2MjmwT8ZzcAZVmUjAGN51jssB8UHDx N38EFB5pBe2vCosT4HNAPji8c47obBd N2wh7zNHHq45ECNzQcEmqSYtMucPsF6 N2etWLN9w3doFescqweegs9L1X7e9F2 N4EuW8Hg3ChNBkYprKPZQrAd7wPRTDf N269VttywPZKzjmKp6GpYsSj1z7peGT N3dFsK9vGhw4kDX7UezKTYpfCV89EDd N4HD1zLstgfXPNJUWSxYMxWwzKUrJFy N3REdWyHV23m6DDATqi1CZb9yKvmzDN N2LXAwk3WD524anDngj6TthMWjyuxEn N43JWM5uSMQQrVoRB3gDRtdMzhm1BDF N2SeLLxEAmn2SVtB26EX6WMnaK5WjCK N33UatDLrJxrSEZqqsgLfEJ1AGGK1DL N3AFvA7UoZAxvzZLb3HExfV3BXsxAEC N28jBJDp9jBzUHR6j6HxqJuLMFVErD8 N2RvwbXP4hs2CE1V2HoAzDUgVEt5wDS N2fu7b8PMHFMpYdxKCUcq4nZMQqBKDi N3Kd8rD43snaDbBGmYogjypfPAEi2E4 NAf2wStjjKZw1YLNBrJmHZsWsJV2ET N3XYm2yU8dkA8SE7mzsUrpsSxfxmrGz N24BDDRYqWnU8tZuGp3kx8ns248NsDb N31FZ3GKrL9wavRrGUZaJReYHB2UUCY N2pbRVacnb4koYpKQVhaRDyp8wzcQGf N2JGSuXjAoQW1Ty8S44VpjJuSwMR4DS N3taBpXabCtCFq4JsVxV1XWQg5feGEJ NALNGYBW1eT1KPUXGoHtxzNoaGe4Ct N4W2x7HGkvzu2ckN9NRJDtWxGHakiEi N3ZmR8u6SJa3GWceR49EAmNhQD1i2BK NAuyF59bpQY1Y5FRJy8AeCte714GBM N2ScVcWiCBjY4gQSFsn6G1A5syUvwE7 N2xwnMbPwrgcqxTxUrt5DXyVY5KXcHg N3NBsXTovBrQQxkMuTFVSeJZnahRxGL N3UE2nV7gEoBXSeY1m2erffE4qLq6D1 N2kJYd3H3g3o7FQAcY63kS85VBsCqB7 N3ZbWUTToesJHTyFFuicyucAPwoZzHG N3zBfLvWUhMey1zDm87ArPkbqEbhTFM N2tr6odTWaXCYgDPnLN72ReP8qoiLE4 N2BL9Y1EpbFmggG7K5pq93pqtPsQtDk N3Ts8k5sSvgHxpy3yrAD7SBD7ZWFmES N2qKKeR31A9rdhnidMzuDXtvZ8SpZFK N2en85z451qJYP5RyuXh2AK5JvUMVCN N2uSzE87a7gJrf6kTZYE95aquBSarE2 NBWxfNhtu7WjEWjUDQwUrpPTZx35FS N2ngTm4CTVpN8LWcZb6JPivyUwfFbEw N3Mufwyptb58oRKgrSszG8NNCZZEZFn N2B9wGnxKP5KVYqXuywRsQNJ6vcL4En N2kmTD4mnm4kxb8eCDP7ApP3VRy49Cv NBdadsbFs4M7ksP9Zq6KVpj5bX94DK N2WB1byXUaQN4bWXeN33f41B9SDHUAg N2FysS8GDe8mRT1jZ8cLpN1EJV6PUBv N4BjVc8xpwaEXo1F4nTU8ghV4ZwGqEX N2ZA1qBU76rWsxkkXNjNVAHaUE3o8D7 NA1kMwKfyjquKYX2r6x6FrobUgpPFh N236dX6RLDZy7aCPfPuaLLNBukPjyDU N35KHsUqh1SQGDGHcDZjhCU9bij12By N23ZopJmFYNfaMx8TETUi6M2GWaXxDa N2oFrcKzPxDU598XgtNQfNNmTVquAEu NtLp5upSBxt5FNTJYUfAnRmFHWtkF3 NSK88wtZSc1KB7m5oo5vFAQ9BEbTBj';
  counter,counter2 : integer;
  ArrTrxs        : BlockOrdersArray;
  TrackTrxs : string;
  count : integer = 0;
  totalmont : int64;
Begin
for counter := MyLastBlock downto 70000 do
   begin
   ArrTrxs := GetBlockTrxs(counter);
   if Length(ArrTrxs)>0 then
      begin
      for counter2 := 0 to length(ArrTrxs)-1 do
         begin
         if ( (AnsiCOntainsStr(GPUAddresses,ArrTrxs[counter2].sender)) and (ArrTrxs[counter2].receiver = address) ) then
            begin
            TrackTrxs := TrackTrxs+format('%d] %s <- %s',[counter,ArrTrxs[counter2].sender,Int2curr(ArrTrxs[counter2].AmmountTrf)])+slinebreak;
            inc(count);
            Inc(totalmont,ArrTrxs[counter2].AmmountTrf);
            end;
         end;
      end;
   end;
AddLineToDebugLog('console','Count: '+count.tostring);
AddLineToDebugLog('console',TrackTrxs);
End;

Procedure totallocked();
var
  sourcestr: string;
  thisadd  : string;
  counter  : integer = 0;
  total    : int64 = 0;
  count    : integer = 0;
Begin
sourcestr := GetNosoCFGString(5);
repeat
Thisadd := Parameter(sourcestr,counter,':');
if thisadd <> '' then
   begin
   Inc(Total,ListaSumario[AddressSumaryIndex(thisadd)].Balance);
   Inc(count);
   AddLineToDebugLog('console',format('%-35s : %15s',[thisadd,int2curr(ListaSumario[AddressSumaryIndex(thisadd)].Balance)]));
   end;
inc(counter);
until thisadd = '';
AddLineToDebugLog('console',format('Freezed %d : %s',[count,int2curr(Total)]));

End;


END. // END UNIT

