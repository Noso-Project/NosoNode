unit mpdisk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, Dialogs, Forms, mpTime, FileUtil, LCLType,
  lclintf, controls, mpCripto, mpBlock, Zipper, mpLang, mpcoin, mpMn,
  {$IFDEF WINDOWS}Win32Proc, {$ENDIF}
  mpminer, translation, strutils;

Procedure VerificarArchivos();

// *** New files system
// Nodes file
Procedure FillNodeList();
Function IsSeedNode(IP:String):boolean;
// Except log file
Procedure CreateExceptlog();
Procedure ToExcLog(Texto:string);
Procedure SaveExceptLog();
// Pool payments file
Procedure CreatePoolPayfile();
Procedure AddPoolPay(Texto:string);
Procedure SavePoolPays();

// GVTs file handling
Procedure CreateGVTsFile();
Procedure GetGVTsFileData();
Procedure SaveGVTs();


Procedure CreateTextFile(FileName:String);
Procedure CreateLog();
Procedure CreatePoolLog();
Procedure CreateMasterNodesFile();
Procedure CreateADV(saving:boolean);
Procedure LoadADV();
Function GetLanguage():string;
Procedure ExtractPoFiles();
Procedure CreateFileFromResource(resourcename,filename:string);
Procedure ToLog(Texto:string);
Procedure SaveLog();
Procedure CrearArchivoOpciones();
Procedure CargarOpciones();
Procedure GuardarOpciones();
Procedure CrearIdiomaFile();
Procedure CargarIdioma(numero:integer);
Procedure CrearBotData();
Procedure DepurarBots();
Procedure CargarBotData();
Procedure UpdateBotData(IPUser:String);
Procedure SaveBotData();

// sumary
Procedure UpdateWalletFromSumario();
Procedure CreateSumario();
Procedure LoadSumaryFromFile(source:string='');
Procedure GuardarSumario(SaveCheckmark:boolean = false);
Procedure UpdateSumario(Direccion:string;monto:Int64;score:integer;LastOpBlock:string);
Procedure AddBlockToSumary(BlockNumber:integer;SaveAndUpdate:boolean = true);
Procedure CompleteSumary();
Procedure RebuildSumario(UntilBlock:integer);

// My transactions
Procedure CrearMistrx();
Procedure CargarMisTrx();
Procedure SaveMyTrxsLastUpdatedblock(Number:integer;PoSPayouts, PoSEarnings, MNsPayouts, MNsEarnings:int64);
Procedure RebuildMyTrx(blocknumber:integer);
Procedure SaveMyTrxsToDisk(Cantidad:integer);

Procedure CrearNTPData();
Procedure CargarNTPData();
Procedure SaveUpdatedFiles();
Procedure CrearWallet();
Procedure CargarWallet(wallet:String);
Procedure GuardarWallet();

function GetMyLastUpdatedBlock():int64;

function SetCustomAlias(Address,Addalias:String;block:integer):Boolean;
Function UnzipBlockFile(filename:String;delFile:boolean):boolean;
function UnZipUpdateFromRepo(Tver,TArch:String):boolean;
Procedure CreateResumen();
Procedure BuildHeaderFile(untilblock:integer);
Procedure AddBlchHead(Numero: int64; hash,sumhash:string);
Function DelBlChHeadLast(Block:integer): boolean;
Function GetHeadersSize():integer;
Function ShowBlockHeaders(BlockNumber:Integer):String;
Function LastHeaders(FromBlock:integer):String;

Procedure CreateLauncherFile(IncludeUpdate:boolean = false);
Procedure RestartNoso();
Procedure NewDoctor();
Procedure RunDiagnostico(linea:string);
Procedure GuardarArchivoPoolInfo();
function GetPoolInfoFromDisk():PoolInfoData;
Procedure LoadPoolMembers();
Procedure CrearArchivoPoolMembers;
Procedure EjecutarAutoUpdate(version:string);
Procedure CrearRestartfile();
Procedure RestartConditions();
Procedure CrearCrashInfo();
function OSVersion: string;
{$IFDEF WINDOWS} Function GetWinVer():string; {$ENDIF}
Procedure RestoreBlockChain();
Procedure RestoreSumary(fromBlock:integer=0);
Procedure InitCrossValues();
function TryDeleteFile(filename:string):boolean;
function TryCopyFile(Source, destination:string):boolean;
function AppFileName():string;

implementation

Uses
  mpParser, mpGUI, mpRed, mpProtocol;

// Complete file verification
Procedure VerificarArchivos();
var
  contador : integer;
Begin
LoadDefLangList();
if not directoryexists(BlockDirectory) then CreateDir(BlockDirectory);
OutText('✓ Block folder ok',false,1);
if not directoryexists(UpdatesDirectory) then CreateDir(UpdatesDirectory);
OutText('✓ Updates folder ok',false,1);
if not directoryexists(MarksDirectory) then CreateDir(MarksDirectory);
OutText('✓ Marks folder ok',false,1);

if not directoryexists(LogsDirectory) then CreateDir(LogsDirectory);
if not FileExists (ExceptLogFilename) then CreateExceptlog;
OutText('✓ Except Log file ok',false,1);

if not FileExists (AdvOptionsFilename) then CreateADV(false) else LoadADV();
OutText('✓ Advanced options loaded',false,1);
if not FileExists (ErrorLogFilename) then Createlog;
OutText('✓ Log file ok',false,1);

if not FileExists(MasterNodesFilename) then CreateMasterNodesFile;
GetMNsFileData;
OutText('✓ Masternodes file ok',false,1);


if not FileExists(GVTsFilename) then CreateGVTsFile;
GetGVTsFileData;
OutText('✓ GVTs file ok',false,1);

if not FileExists (UserOptions.wallet) then CrearWallet() else CargarWallet(UserOptions.wallet);
OutText('✓ Wallet file ok',false,1);
if not Fileexists(BotDataFilename) then CrearBotData() else CargarBotData();
OutText('✓ Bots file ok',false,1);

FillNodeList;  // Fills the hardcoded seed nodes list

if not Fileexists(NTPDataFilename) then CrearNTPData() else CargarNTPData();
OutText('✓ NTP servers file ok',false,1);
if not Fileexists(SumarioFilename) then CreateSumario() else LoadSumaryFromFile();
OutText('✓ Sumary file ok',false,1);
if not Fileexists(ResumenFilename) then CreateResumen();
OutText('✓ Headers file ok',false,1);
if not FileExists(BlockDirectory+'0.blk') then CrearBloqueCero();
if not FileExists(MyTrxFilename) then CrearMistrx() else CargarMisTrx();
OutText('✓ My transactions file ok',false,1);

MyLastBlock := GetMyLastUpdatedBlock;
OutText('✓ My last block verified: '+MyLastBlock.ToString,false,1);
//OutText('✓ Headers file build',false,1);

UpdateWalletFromSumario();
OutText('✓ Wallet updated',false,1);
End;

// ***********************
// *** NEW FILE SYSTEM *** (0.2.0N and higher)
// ***********************

// *** NODE FILE ***

// Fills hardcoded seed nodes list
Procedure FillNodeList(); // 0.2.1Lb2 revisited
var
  counter : integer;
  ThisNode : string = '';
  Thisport  : integer;
  continuar : boolean = true;
  NodeToAdd : NodeData;
Begin
counter := 1;
SetLength(ListaNodos,0);
Repeat
   ThisNode := parameter(DefaultNodes,counter);
   ThisNode := StringReplace(ThisNode,':',' ',[rfReplaceAll, rfIgnoreCase]);
   ThisPort := StrToIntDef(Parameter(ThisNode,1),8080);
   ThisNode := Parameter(ThisNode,0);
   if thisnode = '' then continuar := false
   else
      begin
      NodeToAdd.ip:=ThisNode;
      NodeToAdd.port:=IntToStr(ThisPort);
      NodeToAdd.LastConexion:=UTCTime;
      Insert(NodeToAdd,Listanodos,Length(ListaNodos));
      counter+=1;
      end;
until not continuar;
End;

// If the specified IP a seed node
Function IsSeedNode(IP:String):boolean;
Begin
Result := false;
if AnsiContainsStr(DefaultNodes,ip) then result := true;
End;

// *** EXCEPTLOG FILE ***

// Creates except log file
Procedure CreateExceptlog();
var
  archivo : textfile;
Begin
   try
   Assignfile(archivo, ExceptLogFilename);
   rewrite(archivo);
   Closefile(archivo);
   Except on E:Exception do
      tolog ('Error creating the log file');
   end;
End;

// Add Except log line
Procedure ToExcLog(Texto:string);
Begin
EnterCriticalSection(CSExcLogLines);
   TRY
   if copy(texto,1,7)<>'SERVER:' then
     ExceptLines.Add(FormatDateTime('dd MMMM YYYY HH:MM:SS.zzz', Now)+' -> '+texto);
   EXCEPT on E:Exception do begin end;
   END;{TRY}
LeaveCriticalSection(CSExcLogLines);
S_Exc := true;
End;

// Save Except log file to disk
Procedure SaveExceptLog();
var
  archivo : textfile;
  IOCode : integer;
Begin
setmilitime('SaveExceptLog',1);
Assignfile(archivo, ExceptLogFilename);
{$I-}Append(archivo){$I+};
IOCode := IOResult;
If IOCode = 0 then
   begin
   EnterCriticalSection(CSExcLogLines);
      TRY
      while ExceptLines.Count>0 do
         begin
         Writeln(archivo, ExceptLines[0]);
         if not WO_OmmitMemos then
            form1.MemoExceptLog.Lines.Add( ExceptLines[0]);
         NewExclogLines +=1;
         ExceptLines.Delete(0);
         end;
      S_Exc := false;
      Except on E:Exception do
         tolog ('Error saving the Except log file: '+E.Message);
      end;
   Closefile(archivo);
   LeaveCriticalSection(CSExcLogLines);
   end
else if IOCode = 5 then
   {$I-}Closefile(archivo){$I+};
setmilitime('SaveExceptLog',2);
End;

// *** Pool payments file ***

// Creates pool pays file
Procedure CreatePoolPayfile();
var
  archivo : file of PoolPaymentData;
Begin
TRY
Assignfile(archivo, PoolPaymentsFilename);
rewrite(archivo);
Closefile(archivo);
EXCEPT on E:Exception do
   toexclog ('Error creating pool payments file');
END;
End;

// Add Except log line
Procedure AddPoolPay(Texto:string);
Begin
EnterCriticalSection(CSPoolPay);
SetLength(ArrPoolPays,length(ArrPoolPays)+1);
ArrPoolPays[length(ArrPoolPays)-1].block:= StrToIntDef(parameter(texto,0),-1);
ArrPoolPays[length(ArrPoolPays)-1].address:=parameter(texto,1);
ArrPoolPays[length(ArrPoolPays)-1].amount:= StrToInt64Def(parameter(texto,2),0);
ArrPoolPays[length(ArrPoolPays)-1].Order:= parameter(texto,3);
PoolPaysLines.Add(texto);
LeaveCriticalSection(CSPoolPay);
S_PoolPays := true;
End;

// Save pool pays file to disk
Procedure SavePoolPays();
var
  archivo : textfile;
Begin
setmilitime('SavePoolPays',1);
Assignfile(archivo, PoolPaymentsFilename);
Append(archivo);
try
   while PoolPaysLines.Count>0 do
      begin
      if StrToIntDef(parameter(PoolPaysLines[0],2),0)>0 then
         Writeln(archivo, PoolPaysLines[0]);
      EnterCriticalSection(CSPoolPay);
      PoolPaysLines.Delete(0);
      LeaveCriticalSection(CSPoolPay);
      end;
   S_PoolPays := false;
Except on E:Exception do
   tolog ('Error saving Pool pays file');
end;
Closefile(archivo);
setmilitime('SavePoolPays',2);
End;

// *** BOTS FILE ***


// *****************************************************************************

// creates the specified text file
Procedure CreateTextFile(FileName:String);
var
  archivo : textfile;
Begin
   try
   Assignfile(archivo, FileName);
   rewrite(archivo);
   Closefile(archivo);
   Except on E:Exception do
      toExclog ('Error creating text file: '+filename);
   end;
End;


// Creates log file
Procedure CreateLog();
var
  archivo : textfile;
Begin
   try
   Assignfile(archivo, ErrorLogFilename);
   rewrite(archivo);
   Closefile(archivo);
   Except on E:Exception do
      tolog ('Error creating the log file');
   end;
End;

// Creates pool log file
Procedure CreatePoolLog();
var
  archivo : textfile;
Begin
   try
   Assignfile(archivo, PoolLogFilename);
   rewrite(archivo);
   Closefile(archivo);
   Except on E:Exception do
      tolog ('Error creating the pool log file');
   end;
End;

Procedure CreateMasterNodesFile();
var
  archivo : textfile;
Begin
TRY
Assignfile(archivo, MAsternodesfilename);
rewrite(archivo);
Closefile(archivo);
EXCEPT on E:Exception do
   tolog ('Error creating the masternodes file');
END;
End;

Procedure CreateGVTsFile();
Begin
TRY
Assignfile(FileGVTs, GVTsFilename);
rewrite(FileGVTs);
Closefile(FileGVTs);
EXCEPT on E:Exception do
   tolog ('Error creating the GVTs file');
END;
MyGVTsHash := HashMD5File(GVTsFilename);
End;

// Load GVTs array from file
Procedure GetGVTsFileData();
var
  counter : integer;
Begin
EnterCriticalSection(CSGVTsArray);
Assignfile(FileGVTs, GVTsFilename);
TRY
reset(FileGVTs);
Setlength(ArrGVTs,filesize(FileGVTs));
For counter := 0 to filesize(FileGVTs)-1 do
   begin
   seek(FileGVTs,counter);
   read(FileGVTs,ArrGVTs[counter]);
   end;
Closefile(FileGVTs);
EXCEPT ON E:Exception do
   tolog ('Error loading the GVTs from file');
END;
MyGVTsHash := HashMD5File(GVTsFilename);
LeaveCriticalSection(CSGVTsArray);
End;

// Save GVTs array to file
Procedure SaveGVTs();
var
  counter : integer;
Begin
Assignfile(FileGVTs, GVTsFilename);
EnterCriticalSection(CSGVTsArray);
TRY
rewrite(FileGVTs);
For counter := 0 to length(ArrGVTs)-1 do
   begin
   seek(FileGVTs,counter);
   write(FileGVTs,ArrGVTs[counter]);
   end;
Closefile(FileGVTs);
EXCEPT ON E:Exception do
   tolog ('Error loading the GVTs from file');
END;
MyGVTsHash := HashMD5File(GVTsFilename);
LeaveCriticalSection(CSGVTsArray);
End;

// Creates/Saves Advopt file
Procedure CreateADV(saving:boolean);
Begin
setmilitime('CreateADV',1);
   try
   Assignfile(FileAdvOptions, AdvOptionsFilename);
   rewrite(FileAdvOptions);
   writeln(FileAdvOptions,'ctot '+inttoStr(ConnectTimeOutTime));
   writeln(FileAdvOptions,'rtot '+inttoStr(ReadTimeOutTIme));
   writeln(FileAdvOptions,'UserFontSize '+inttoStr(UserFontSize));
   writeln(FileAdvOptions,'UserRowHeigth '+inttoStr(UserRowHeigth));
   writeln(FileAdvOptions,'CPUs '+inttoStr(DefCPUs));
   writeln(FileAdvOptions,'PoolExpel '+inttoStr(PoolExpelBlocks));
   writeln(FileAdvOptions,'PoolShare '+inttoStr(PoolShare));
   writeln(FileAdvOptions,'RPCPort '+inttoStr(RPCPort));
   writeln(FileAdvOptions,'RPCPass '+RPCPass);
   writeln(FileAdvOptions,'ShowedOrders '+IntToStr(ShowedOrders));
   writeln(FileAdvOptions,'MaxPeers '+IntToStr(MaxPeersAllow));
   writeln(FileAdvOptions,'PoolStepsDeep '+IntToStr(PoolStepsDeep));
   writeln(FileAdvOptions,'AutoConnect '+BoolToStr(WO_AutoConnect,true));
   writeln(FileAdvOptions,'ToTray '+BoolToStr(WO_ToTray,true));
   writeln(FileAdvOptions,'MinConexToWork '+IntToStr(MinConexToWork));
   writeln(FileAdvOptions,'PosWarning '+IntToStr(WO_PosWarning));
   writeln(FileAdvOptions,'AntiFreeze '+BoolToStr(WO_AntiFreeze,true));
   writeln(FileAdvOptions,'MultiSend '+BoolToStr(WO_MultiSend,true));
   writeln(FileAdvOptions,'AntifreezeTime '+IntToStr(WO_AntifreezeTime));
   writeln(FileAdvOptions,'RPCFilter '+BoolToStr(RPCFilter,true));
   writeln(FileAdvOptions,'RPCWhiteList '+RPCWhitelist);
   writeln(FileAdvOptions,'RPCAuto '+BoolToStr(RPCAuto,true));
   writeln(FileAdvOptions,'Language '+(WO_Language));
   writeln(FileAdvOptions,'Autoserver '+BoolToStr(WO_AutoServer,true));
   writeln(FileAdvOptions,'PoUpdate '+(WO_LastPoUpdate));
   writeln(FileAdvOptions,'Closestart '+BoolToStr(WO_CloseStart,true));
   writeln(FileAdvOptions,'Autoupdate '+BoolToStr(WO_AutoUpdate,true));
   writeln(FileAdvOptions,Format('FormState %d %d %d %d %d',[Form1.Top,form1.Left,form1.Width,form1.Height,form1.WindowState]));

   writeln(FileAdvOptions,'MNIP '+(MN_IP));
   writeln(FileAdvOptions,'MNPort '+(MN_Port));
   writeln(FileAdvOptions,'MNFunds '+(MN_Funds));
   if MN_Sign = '' then MN_Sign := ListaDirecciones[0].Hash;
   writeln(FileAdvOptions,'MNSign '+(MN_Sign));
   writeln(FileAdvOptions,'MNAutoIp '+BoolToStr(MN_AutoIP,true));

   writeln(FileAdvOptions,'PoolRestart '+BoolToStr(POOL_MineRestart,true));
   writeln(FileAdvOptions,'PoolLBS '+BoolToStr(POOL_LBS,true));
   writeln(FileAdvOptions,'WO_RebuildTrx '+BoolToStr(WO_RebuildTrx,true));
   writeln(FileAdvOptions,'WO_FullNode '+BoolToStr(WO_FullNode,true));



   Closefile(FileAdvOptions);
   if saving then tolog('Options file saved');
   S_AdvOpt := false;
   Except on E:Exception do
      toexclog ('Error creating/saving AdvOpt file: '+E.Message);
   end;
   setmilitime('CreateADV',2);
End;

// Loads Advopt values
Procedure LoadADV();
var
  linea:string;
Begin
   try
   Assignfile(FileAdvOptions, AdvOptionsFilename);
   reset(FileAdvOptions);
   while not eof(FileAdvOptions) do
      begin
      readln(FileAdvOptions,linea);
      if parameter(linea,0) ='ctot' then ConnectTimeOutTime:=StrToIntDef(Parameter(linea,1),ConnectTimeOutTime);
      if parameter(linea,0) ='rtot' then ReadTimeOutTIme:=StrToIntDef(Parameter(linea,1),ReadTimeOutTIme);
      if parameter(linea,0) ='UserFontSize' then UserFontSize:=StrToIntDef(Parameter(linea,1),UserFontSize);
      if parameter(linea,0) ='UserRowHeigth' then UserRowHeigth:=StrToIntDef(Parameter(linea,1),UserRowHeigth);
      if parameter(linea,0) ='CPUs' then DefCPUs:=StrToIntDef(Parameter(linea,1),DefCPUs);
      if parameter(linea,0) ='PoolExpel' then PoolExpelBlocks:=StrToIntDef(Parameter(linea,1),PoolExpelBlocks);
      if parameter(linea,0) ='PoolShare' then PoolShare:=StrToIntDef(Parameter(linea,1),PoolShare);
      if parameter(linea,0) ='RPCPort' then RPCPort:=StrToIntDef(Parameter(linea,1),RPCPort);
      if parameter(linea,0) ='RPCPass' then RPCPass:=Parameter(linea,1);
      if parameter(linea,0) ='ShowedOrders' then ShowedOrders:=StrToIntDef(Parameter(linea,1),ShowedOrders);
      if parameter(linea,0) ='MaxPeers' then MaxPeersAllow:=StrToIntDef(Parameter(linea,1),MaxPeersAllow);
      if parameter(linea,0) ='PoolStepsDeep' then PoolStepsDeep:=StrToIntDef(Parameter(linea,1),PoolStepsDeep);
      if parameter(linea,0) ='AutoConnect' then WO_AutoConnect:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='ToTray' then WO_ToTray:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='MinConexToWork' then MinConexToWork:=StrToIntDef(Parameter(linea,1),MinConexToWork);
      if parameter(linea,0) ='PosWarning' then WO_PosWarning:=StrToIntDef(Parameter(linea,1),WO_PosWarning);
      if parameter(linea,0) ='AntiFreeze' then WO_AntiFreeze:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='MultiSend' then WO_MultiSend:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='AntifreezeTime' then WO_AntifreezeTime:=StrToIntDef(Parameter(linea,1),WO_AntifreezeTime);
      if parameter(linea,0) ='RPCFilter' then RPCFilter:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='RPCWhiteList' then RPCWhiteList:=Parameter(linea,1);
      if parameter(linea,0) ='RPCAuto' then RPCAuto:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='Language' then WO_Language:=Parameter(linea,1);
      if parameter(linea,0) ='Autoserver' then WO_AutoServer:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='PoUpdate' then WO_LastPoUpdate:=Parameter(linea,1);
      if parameter(linea,0) ='Closestart' then WO_CloseStart:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='Autoupdate' then WO_AutoUpdate:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='FormState' then
         begin
         FormState_Top    := StrToIntDef(Parameter(linea,1),0);
         FormState_Left   := StrToIntDef(Parameter(linea,2),0);
         FormState_Width  := StrToIntDef(Parameter(linea,3),400);
         FormState_Heigth := StrToIntDef(Parameter(linea,4),560);
         FormState_Status := StrToIntDef(Parameter(linea,5),2);
         if FormState_Status = 2 then // Maximized
            form1.WindowState:=wsMaximized;
         if FormState_Status = 0 then
            begin
            form1.Width:=FormState_Width;
            form1.Height:=FormState_Heigth;
            end;
         if FormState_Status = 1 then
            begin
            FormState_Status := 0;
            form1.Width:=FormState_Width;
            form1.Height:=FormState_Heigth;
            end;
         end;

      if parameter(linea,0) ='MNIP' then MN_IP:=Parameter(linea,1);
      if parameter(linea,0) ='MNPort' then MN_Port:=Parameter(linea,1);
      if parameter(linea,0) ='MNFunds' then MN_Funds:=Parameter(linea,1);
      if parameter(linea,0) ='MNSign' then MN_Sign:=Parameter(linea,1);
      if parameter(linea,0) ='MNAutoIp' then MN_AutoIP:=StrToBool(Parameter(linea,1));

      if parameter(linea,0) ='PoolRestart' then POOL_MineRestart:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='PoolLBS' then POOL_LBS:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='WO_RebuildTrx' then WO_RebuildTrx:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='WO_FullNode' then WO_FullNode:=StrToBool(Parameter(linea,1));

      end;
   Closefile(FileAdvOptions);
   Except on E:Exception do
      tolog ('Error loading AdvOpt file');
   end;
End;

// returns the language to load the
Function GetLanguage():string;
var
  linea : string = '';
  archivo : textfile;
Begin
result := 'en';
WO_LastPoUpdate := '';
if not fileexists('NOSODATA'+DirectorySeparator+'advopt.txt') then
  begin
  result := 'en';
  WO_LastPoUpdate := '';
  end
else
   begin
   Assignfile(archivo, 'NOSODATA'+DirectorySeparator+'advopt.txt');
   reset(archivo);
   while not eof(archivo) do
      begin
      readln(archivo,linea);
      if parameter(linea,0) ='Language' then result:=Parameter(linea,1);
      if parameter(linea,0) ='PoUpdate' then WO_LastPoUpdate:=Parameter(linea,1);
      end;
   Closefile(archivo);
   end;
End;

Procedure ExtractPoFiles();
Begin
CreateFileFromResource('Noso.en','locale'+DirectorySeparator+'Noso.en.po');
CreateFileFromResource('Noso.es','locale'+DirectorySeparator+'Noso.es.po');
CreateFileFromResource('Noso.pt','locale'+DirectorySeparator+'Noso.pt.po');
CreateFileFromResource('Noso.zh','locale'+DirectorySeparator+'Noso.zh.po');
CreateFileFromResource('Noso.de','locale'+DirectorySeparator+'Noso.de.po');
CreateFileFromResource('Noso.ro','locale'+DirectorySeparator+'Noso.ro.po');
CreateFileFromResource('Noso.id','locale'+DirectorySeparator+'Noso.id.po');
CreateFileFromResource('Noso.ru','locale'+DirectorySeparator+'Noso.ru.po');
End;

Procedure CreateFileFromResource(resourcename,filename:string);
var
  Resource: TResourceStream;
begin
  Resource := TResourceStream.Create(HInstance, resourcename, RT_RCDATA);
  Resource.Position := 0;
  Resource.SaveToFile(filename);
  Resource.Free;
End;

// Add log line
Procedure ToLog(Texto:string);
Begin
EnterCriticalSection(CSLoglines);
TRY
LogLines.Add(timetostr(now)+': '+texto);
S_Log := true;
EXCEPT on E:Exception do
   begin

   end;
END{Try};
LeaveCriticalSection(CSLoglines);
End;

// Save log files to disk
Procedure SaveLog();
var
  archivo : textfile;
  IOCode : integer;
Begin
setmilitime('SaveLog',1);
Assignfile(archivo, ErrorLogFilename);
{$I-}Append(archivo);{$I+}
IOCode := IOResult;
if IOCode = 0 then
   begin
   EnterCriticalSection(CSLoglines);
      try
      while LogLines.Count>0 do
         begin
         Writeln(archivo,LogLines[0]);
         if not WO_OmmitMemos then
            form1.MemoLog.Lines.Add(LogLines[0]);
         LogLines.Delete(0);
         end;
      S_Log := false;
      Except on E:Exception do
         toExclog ('Error saving to the log file: '+E.Message);
      end;
   Closefile(archivo);
   LeaveCriticalSection(CSLoglines);
   end
else if IOCode = 5 then
   {$I-}Closefile(archivo){$I+};
setmilitime('SaveLog',2);
End;

// Creates options file
Procedure CrearArchivoOpciones();
var
  DefOptions : Options;
Begin
   try
   assignfile(FileOptions,OptionsFileName);
   rewrite(FileOptions);
   DefOptions.language:=0;
   DefOptions.Port:=8080;
   DefOptions.GetNodes:=false;
   DefOptions.PoolInfo := '';
   DefOptions.wallet:= 'NOSODATA'+DirectorySeparator+'wallet.pkw';
   DefOptions.AutoServer:=false;
   DefOptions.AutoConnect:=true;
   DefOptions.Auto_Updater:=false;
   DefOptions.JustUpdated:=false;
   DefOptions.VersionPage:='https://nosocoin.com';
   DefOptions.ToTray:=false;
   DefOptions.UsePool:=false;
   write(FileOptions,DefOptions);
   closefile(FileOptions);
   UserOptions := DefOptions;
   OutText('✓ Options file created',false,1);
   Except on E:Exception do
      tolog ('Error creating options file');
   end;
End;

// Load options from disk
Procedure CargarOpciones();
Begin
   TRY
   assignfile(FileOptions,OptionsFileName);
   reset(FileOptions);
   read(FileOptions,UserOptions);
   closefile(FileOptions);
   OutText('✓ Options file loaded',false,1);
   EXCEPT on E:Exception do
      tolog ('Error loading user options');
   END; {TRY}
End;

// Save Options to disk
Procedure GuardarOpciones();
Begin
setmilitime('GuardarOpciones',1);
   try
   assignfile(FileOptions,OptionsFileName);
   reset(FileOptions);
   seek(FileOptions,0);
   write(FileOptions,UserOptions);
   closefile(FileOptions);
   S_Options := false;
   Except on E:Exception do
      tolog ('Error saving user options');
   end;
   setmilitime('GuardarOpciones',2);
End;

// Creates the default language file
Procedure CrearIdiomaFile();
Begin
   try
   CrearArchivoLang();
   CargarIdioma(0);
   ConsoleLinesAdd(LangLine(18));  // Default language file created.
   OutText('✓ Language file created',false,1);
   Except on E:Exception do
      tolog ('Error creating default language file');
   end;
End;

// Loads an specified language
Procedure CargarIdioma(numero:integer);
var
  archivo : file of string[255];
  datoleido : string[255] = '';
  Idiomas : integer = 0;
  StartPos : integer = 0;
  Registros : integer = 0;
  Lineas : integer = 0;
  contador : integer = 0;
Begin
   try
   if FileExists(LanguageFileName) then
      begin
      AssignFile(Archivo,LanguageFileName);
      reset(archivo);
      Registros := filesize(archivo);
      seek(archivo,0);read(archivo,datoleido);
      idiomas := CadToNum(Datoleido,1,'Failed Converting language number: '+Datoleido);
      if numero > Idiomas-1 then // El idioma especificado no existe
         begin
         closefile(archivo);
         exit;
         end;
      StringListLang.Clear;
      IdiomasDisponibles.Clear;
      for contador := 1 to idiomas do
         begin
         seek(archivo,contador);read(archivo,datoleido);
         IdiomasDisponibles.Add(datoleido);
         end;
      seek(archivo,1+numero);read(archivo,datoleido);
      CurrentLanguage := datoleido;
      Lineas := (Registros - 1 - idiomas) div idiomas;
      LanguageLines := lineas;
      StartPos := (1+idiomas)+(lineas*numero);
      for contador := 0 to lineas-1 do
         begin
         seek(archivo,startpos+contador);read(archivo,datoleido);
         StringListLang.Add(datoleido);
         end;
      closefile(archivo);
      if not G_Launching then
         begin
         InicializarGUI();
         Form1.BNewAddr.Hint:=LAngLine(64);form1.BCopyAddr.Hint:=LAngLine(65);

         end;
      UserOptions.language:=numero;
      S_Options := true;
      if G_Launching then OutText('✓ Language file loaded',false,1);
      end
   else // si el archivo no existe
      begin
      ConsoleLinesAdd('noso.lng not found');
      tolog('noso.lng not found');
      end
   Except on E:Exception do
      tolog ('Error loading language file');
   end;
End;

// Creates bots file
Procedure CrearBotData();
Begin
   try
   assignfile(FileBotData,BotDataFilename);
   rewrite(FileBotData);
   closefile(FileBotData);
   SetLength(ListadoBots,0);
   Except on E:Exception do
      tolog ('Error creating bot data');
   end;
End;

// Load bots from file
Procedure CargarBotData();
Var
  Leido : BotData;
  contador: integer = 0;
Begin
   try
   assignfile (FileBotData,BotDataFilename);
   contador := 0;
   reset (FileBotData);
   SetLength(ListadoBots,0);
   SetLength(ListadoBots, filesize(FileBotData));
   while contador < (filesize(FileBotData)) do
      begin
      seek (FileBotData, contador);
      read (FileBotData, Leido);
      ListadoBots[contador] := Leido;
      contador := contador + 1;
      end;
   closefile(FileBotData);
   //DepurarBots();
   Except on E:Exception do
      tolog ('Error loading bot data');
   end;
End;

// Bot info debug
Procedure DepurarBots();
var
  contador : integer = 0;
  LimiteTiempo : Int64 = 0;
  NodeDeleted : boolean;
Begin
LimiteTiempo := CadToNum(UTCTime,0,'Failed converting UTC time on depurarbots')-2592000; // Los menores que esto deben ser eliminados(2592000 un mes)
While contador < length(ListadoBots)-1 do
   begin
   NodeDeleted := false;
   if CadToNum(ListadoBots[contador].LastRefused,999999999999,'Failed converting last refused on depurarbots: '+ListadoBots[contador].LastRefused) < LimiteTiempo then
      Begin
      Delete(ListadoBots,Contador,1);
      contador := contador-1;
      NodeDeleted := true;
      end;
   if not NodeDeleted then contador := contador+1;
   end;
S_BotData := true;
End;

// Modifica la hora del ultimo intento del bot, o lo añade si es la primera vez
Procedure UpdateBotData(IPUser:String);
var
  contador : integer = 0;
  updated : boolean = false;
Begin
if IsSafeIP(IPUser) then exit;
for contador := 0 to length(ListadoBots)-1 do
   begin
   if ListadoBots[Contador].ip = IPUser then
      begin
      ListadoBots[Contador].LastRefused:=UTCTime;
      Updated := true;
      end;
   end;
if not updated then
   begin
   SetLength(ListadoBots,Length(ListadoBots)+1);
   ListadoBots[Length(listadoBots)-1].ip:=IPUser;
   ListadoBots[Length(listadoBots)-1].LastRefused:=UTCTime;
   end;
S_BotData := true;
End;

// Save bots to disk
Procedure SaveBotData();
Var
  contador  : integer = 0;
  ErrorCode : integer = 0;
Begin
setmilitime('SaveBotData',1);
SetCurrentJob('SaveBotData',true);
contador := 0;
assignfile (FileBotData,BotDataFilename);
{$I-}reset (FileBotData){$I+};
ErrorCode := IOResult;
if ErrorCode = 0 then
   begin
   TRY
   if length(ListadoBots) > 0 then
      begin
   for contador := 0 to length(ListadoBots)-1 do
         begin
         seek (FileBotData, contador);
         write (FileBotData, ListadoBots[contador]);
         end;
      end;
   Truncate(FileBotData);
   S_BotData := false;
   tolog ('Bot file saved: '+inttoStr(length(ListadoBots))+' registers');
   EXCEPT on E:Exception do
         tolog ('Error saving bots to file :'+E.Message);
   END; {TRY}
   end;
{$I-}closefile(FileBotData);{$I+};
SetCurrentJob('SaveBotData',false);
setmilitime('SaveBotData',2);
End;

// Creates NTP servers file
Procedure CrearNTPData();
Var
  contador : integer = 0;
Begin
   try
   assignfile(FileNTPData,NTPDataFilename);
   setlength(ListaNTP,11);
   ListaNTP[0].host := 'ntp.amnic.net'; ListaNTP[0].LastUsed:='0';
   ListaNTP[1].host := 'ts2.aco.net'; ListaNTP[1].LastUsed:='0';
   ListaNTP[2].host := 'hora.roa.es'; ListaNTP[2].LastUsed:='0';
   ListaNTP[3].host := 'ntp.atomki.mta.hu'; ListaNTP[3].LastUsed:='0';
   ListaNTP[4].host := 'time.esa.int'; ListaNTP[4].LastUsed:='0';
   ListaNTP[5].host := 'time.stdtime.gov.tw'; ListaNTP[5].LastUsed:='0';
   ListaNTP[6].host := 'stratum-1.sjc02.svwh.net'; ListaNTP[6].LastUsed:='0';
   ListaNTP[7].host := 'ntp3.indypl.org'; ListaNTP[7].LastUsed:='0';
   ListaNTP[8].host := 'ntp1.sp.se'; ListaNTP[8].LastUsed:='0';
   ListaNTP[9].host := 'ntp.ntp-servers.com'; ListaNTP[9].LastUsed:='0';
   ListaNTP[10].host := '1.de.pool.ntp.org'; ListaNTP[10].LastUsed:='0';
   rewrite(FileNTPData);
   for contador := 0 to 10 do
      begin
      seek (FileNTPData,contador);
      write(FileNTPData,ListaNTP[contador]);
      end;
   closefile(FileNTPData);
   Except on E:Exception do
      tolog ('Error creating NTP servers file');
   end;
End;

// Load NTP servers
Procedure CargarNTPData();
Var
  contador : integer = 0;
Begin
assignfile(FileNTPData,NTPDataFilename);
   TRY
   reset(FileNTPData);
   setlength(ListaNTP,filesize(FileNTPData));
   for contador := 0 to filesize(FileNTPData)-1 do
      begin
      seek(FileNTPData,contador);
      Read(FileNTPData,ListaNTP[contador]);
      end;
   closefile(FileNTPData);
   EXCEPT on E:Exception do
      tolog ('Error loading NTP servers');
   END;{TRY}
End;

// Saves updates files to disk
Procedure SaveUpdatedFiles();
Begin
SetCurrentJob('SaveUpdatedFiles',true);
if S_BotData then SaveBotData();
if S_Options then GuardarOpciones();
if S_Wallet then GuardarWallet();
if ( (S_Sumario) and (BuildingBlock=0) ) then GuardarSumario();
if S_Log then SaveLog;
if S_Exc then SaveExceptLog;
//if S_PoolPays then SavePoolPays;
if S_PoolInfo then GuardarArchivoPoolInfo;
if S_AdvOpt then CreateADV(true);
SetCurrentJob('SaveUpdatedFiles',false);
End;

// Creates a new wallet
Procedure CrearWallet();
Begin
   try
   if not fileexists (WalletFilename) then // asegurarse de no borrar una cartera previa
      begin
      assignfile(FileWallet,WalletFilename);
      setlength(ListaDirecciones,1);
      rewrite(FileWallet);
      listadirecciones[0] := CreateNewAddress();
      seek(FileWallet,0);
      write(FileWallet,listadirecciones[0]);
      closefile(FileWallet);
      end;
   UserOptions.Wallet:=WalletFilename;
   if FileExists(MyTrxFilename) then DeleteFile(MyTrxFilename);
   S_Options := true;
   Except on E:Exception do
      tolog ('Error creating wallet file');
   end;
End;

// Load a wallet from disk
Procedure CargarWallet(wallet:String);
var
  contador : integer = 0;
Begin
   TRY
   if fileExists(wallet) then
      begin
      assignfile(FileWallet,Wallet);
      setlength(ListaDirecciones,0);
      reset(FileWallet);
      setlength(ListaDirecciones,FileSize(FileWallet));
      for contador := 0 to Length(ListaDirecciones)-1 do
         begin
         seek(FileWallet,contador);
         Read(FileWallet,ListaDirecciones[contador]);
         ListaDirecciones[contador].Pending:=0;
         end;
      closefile(FileWallet);
      end;
   UpdateWalletFromSumario();
   GuardarWallet();                         // Permite corregir cualquier problema con los pending
   EXCEPT on E:Exception do
      tolog ('Error loading wallet from file');
   END;{TRY}
End;

// Save wallet data to disk
Procedure GuardarWallet();
var
  contador : integer = 0;
  previous : int64;
  IOCode   : integer;
Begin
setmilitime('GuardarWallet',1);
Trycopyfile (UserOptions.Wallet,UserOptions.Wallet+'.bak');
assignfile(FileWallet,UserOptions.Wallet);
{$I-}reset(FileWallet);{$I+}
IOCode := IOResult;
If IOCode = 0 then
   begin
   TRY
   for contador := 0 to Length(ListaDirecciones)-1 do
      begin
      seek(FileWallet,contador);
      Previous := ListaDirecciones[contador].Pending;
      ListaDirecciones[contador].Pending := 0;
      write(FileWallet,ListaDirecciones[contador]);
      ListaDirecciones[contador].Pending := Previous;
      end;
   S_Wallet := false;
   EXCEPT on E:Exception do
      ToExcLog ('Error saving wallet to disk ('+E.Message+')');
   END; {TRY}
   end;
{$I-}closefile(FileWallet);{$I+}
IOCode := IOResult;
if IOCode>0 then
   ToExcLog('Unable to close wallet file, error= '+IOCode.ToString );
setmilitime('GuardarWallet',2);
End;

// Updates wallet addresses balance from sumary
Procedure UpdateWalletFromSumario();
var
  Contador, counter : integer;
  ThisExists : boolean = false;
Begin
for contador := 0 to length(ListaDirecciones)-1 do
   begin
   ThisExists := false;
   for counter := 0 to length(ListaSumario)-1 do
      begin
      if ListaDirecciones[contador].Hash = ListaSumario[counter].Hash then
         begin
         ListaDirecciones[contador].Balance:=ListaSumario[counter].Balance;
         ListaDirecciones[contador].LastOP:=ListaSumario[counter].LastOP;
         ListaDirecciones[contador].score:=ListaSumario[counter].score;
         ListaDirecciones[contador].Custom:=ListaSumario[counter].Custom;
         ThisExists := true;
         end;
      end;
   if not ThisExists then
      begin
      ListaDirecciones[contador].Balance:=0;
      ListaDirecciones[contador].LastOP:=0;
      ListaDirecciones[contador].score:=0;
      ListaDirecciones[contador].Custom:='';
      end;
   end;
S_Wallet := true;
U_Dirpanel := true;
End;

// Creates sumary file
Procedure CreateSumario();
Begin
   TRY
   SetLength(ListaSumario,0);
   assignfile(FileSumario,SumarioFilename);
   Rewrite(FileSumario);
   CloseFile(FileSumario);
   // for cases when rebuilding sumary
   if FileExists(BlockDirectory+'0.blk') then UpdateSumario(ADMINHash,PremineAmount,0,'0');
   EXCEPT on E:Exception do
      tolog ('Error creating summary file');
   END; {TRY}
End;

// Loads sumary from disk
Procedure LoadSumaryFromFile(source:string='');
var
  contador : integer = 0;
Begin
if source = '' then source := SumarioFilename
else
   begin
   if not FileExists(Source) then
      begin
      source := SumarioFilename;
      ConsoleLinesAdd('Can not find '+source+slinebreak+'Loading sumary from default');
      end;
   end;
   TRY
   SetLength(ListaSumario,0);
   assignfile(FileSumario,source);
   Reset(FileSumario);
   SetLength(ListaSumario,fileSize(FileSumario));
   for contador := 0 to Filesize(fileSumario)-1 do
      Begin
      seek(filesumario,contador);
      read(FileSumario,Listasumario[contador]);
      end;
   CloseFile(FileSumario);
   EXCEPT on E:Exception do
      tolog ('Error loading summary from file');
   END;
End;

// Save sumary to disk
Procedure GuardarSumario(SaveCheckmark:boolean = false);
var
  contador     : integer = 0;
  CurrentBlock : integer;
  IOCode       : integer;
Begin
setmilitime('GuardarSumario',1);
SetCurrentJob('GuardarSumario',true);
assignfile(FileSumario,SumarioFilename);
EnterCriticalSection(CSSumary);
{$I-}Reset(FileSumario);{$I+};
IOCode := IOResult;
If IOCode = 0 then
   Begin
   TRY
   for contador := 0 to length(ListaSumario)-1 do
      Begin
      seek(filesumario,contador);
      write(FileSumario,Listasumario[contador]);
      end;
   Truncate(filesumario);
   MySumarioHash := HashMD5File(SumarioFilename);
   S_Sumario := false;
   U_DataPanel := true;
   EXCEPT on E:Exception do
      ToExcLog ('Error saving summary file: '+e.Message);
   END; {TRY}
   end
else
   begin
   ToExcLog('Error opening summary: '+IOCode.ToString );
   {$I-}CloseFile(FileSumario);{$I+};
   end;
{$I-}CloseFile(FileSumario);{$I+};
LeaveCriticalSection(CSSumary);
ZipSumary;
if ( (Listasumario[0].LastOP mod SumMarkInterval = 0) and (Listasumario[0].LastOP>0) ) then
   begin
   EnterCriticalSection(CSSumary);
   Trycopyfile(SumarioFilename,MarksDirectory+Listasumario[0].LastOP.ToString+'.bak');
   LeaveCriticalSection(CSSumary);
   end;
SetCurrentJob('GuardarSumario',false);
setmilitime('GuardarSumario',2);
End;

// Returns the last downloaded block
function GetMyLastUpdatedBlock():int64;
Var
  BlockFiles : TStringList;
  contador : int64 = 0;
  LastBlock : int64 = 0;
  OnlyNumbers : String;
Begin
BlockFiles := TStringList.Create;
   TRY
   FindAllFiles(BlockFiles, BlockDirectory, '*.blk', true);
   while contador < BlockFiles.Count do
      begin
      OnlyNumbers := copy(BlockFiles[contador], 17, length(BlockFiles[contador])-20);
      if CadToNum(OnlyNumbers,0,'Failed converting block to number:'+OnlyNumbers) > Lastblock then
         LastBlock := CadToNum(OnlyNumbers,0,'Failed converting block to number:'+OnlyNumbers);
      contador := contador+1;
      end;
   Result := LastBlock;
   EXCEPT on E:Exception do
      tolog ('Error getting my last updated block');
   END; {TRY}
BlockFiles.Free;
end;

Function deleteBlockFiles(fromnumber:integer):integer;
Begin

End;

// Updates sumary
Procedure UpdateSumario(Direccion:string;monto:Int64;score:integer;LastOpBlock:string);
var
  contador : integer = 0;
  Yaexiste : boolean = false;
  NuevoRegistro : SumarioData;
Begin
EnterCriticalSection(CSSumary);
for contador := 0 to length(ListaSumario)-1 do
   begin
   if ((ListaSumario[contador].Hash=Direccion) or (ListaSumario[contador].Custom=Direccion)) then
      begin
      NuevoRegistro := Default(SumarioData);
      NuevoRegistro.Hash:=ListaSumario[contador].Hash;
      NuevoRegistro.Custom:=ListaSumario[contador].Custom;
      NuevoRegistro.Balance:=ListaSumario[contador].Balance+Monto;
      NuevoRegistro.Score:=ListaSumario[contador].Score+score;;
      NuevoRegistro.LastOP:=CadToNum(LastOpBlock,0,'**CRITICAL: STI fail lastop on update sumario:'+LastOpBlock);
      ListaSumario[contador] := NuevoRegistro;
      Yaexiste := true;
      break;
      end;
   end;
if not YaExiste then
   begin
   NuevoRegistro := Default(SumarioData);
   setlength(ListaSumario,Length(ListaSumario)+1);
   NuevoRegistro.Hash:=Direccion;
   NuevoRegistro.Custom:='';
   NuevoRegistro.Balance:=Monto;
   NuevoRegistro.Score:=0;
   NuevoRegistro.LastOP:=CadToNum(LastOpBlock,0,'**CRITICAL: STI fail lastop on update sumario:'+LastOpBlock);
   ListaSumario[length(listasumario)-1] := NuevoRegistro;
   end;
S_Sumario := true;
LeaveCriticalSection(CSSumary);
if DireccionEsMia(Direccion)>= 0 then UpdateWalletFromSumario();
End;

// Set alias for an address if it is empty
function SetCustomAlias(Address,Addalias:String;block:integer):boolean;
var
  cont : integer;
Begin
result := false;
EnterCriticalSection(CSSumary);
for cont := 0 to length(ListaSumario)-1 do
   begin
   if ((ListaSumario[cont].Hash=Address)and (ListaSumario[cont].custom='')) then
      begin
      listasumario[cont].Custom:=Addalias;
      listasumario[cont].LastOP:=block;
      result := true;
      break;
      end;
   end;
LeaveCriticalSection(CSSumary);
if ((result=false) and (block > 10429)) then
   toexclog('Error assigning custom alias to address: '+Address+' -> '+addalias);
End;

// Unzip a zip file and (optional) delete it
Function UnzipBlockFile(filename:String;delFile:boolean):boolean;
var
  UnZipper: TUnZipper;
Begin
Result := true;
UnZipper := TUnZipper.Create;
   TRY
   UnZipper.FileName := filename;
   UnZipper.OutputPath := '';
   UnZipper.Examine;
   UnZipper.UnZipAllFiles;
   EXCEPT on E:Exception do
      begin
      Result := false;
      ToExcLog ('Error unzipping block file '+filename+': '+E.Message);
      end;
   END; {TRY}
if delfile then Trydeletefile(filename);
UnZipper.Free;
End;

function UnZipUpdateFromRepo(Tver,TArch:String):boolean;
var
  UnZipper: TUnZipper;
Begin
result := true;
UnZipper := TUnZipper.Create;
   TRY
   UnZipper.FileName := 'NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator+TVer+'_'+TArch+'.zip';
   UnZipper.OutputPath := 'NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator;
   UnZipper.Examine;
   UnZipper.UnZipAllFiles;
   OutText('File unzipped',false,1)
   EXCEPT on E:Exception do
      begin
      result := false;
      OutText ('Error unzipping update file',false,1);
      OutText (E.Message,false,1);
      end;
   END{Try};
//Trydeletefile('NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator+TVer+'_'+TArch+'.zip');
{
{$IFDEF WINDOWS}Trycopyfile('NOSODATA/UPDATES/Noso.exe','nosonew');{$ENDIF}
{$IFDEF UNIX}Trycopyfile('NOSODATA/UPDATES/Noso','Nosonew');{$ENDIF}
}
UnZipper.Free;
End;

// Creates header file
Procedure CreateResumen();
Begin
   try
   assignfile(FileResumen,ResumenFilename);
   rewrite(FileResumen);
   closefile(FileResumen);
   Except on E:Exception do
      tolog ('Error creating headers file');
   end;
End;

// Rebuild headers file
Procedure BuildHeaderFile(untilblock:integer);
var
  Dato, NewDato: ResumenData;
  Contador : integer = 0;
  CurrHash : String = '';
  LastHash : String = '';
  BlockHeader : BlockHeaderData;
  ArrayOrders : BlockOrdersArray;
  cont : integer;
  newblocks : integer = 0;
Begin
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
ConsoleLinesAdd(LangLine(127)+IntToStr(untilblock)); //'Rebuilding until block '
contador := 0;
while contador <= untilblock do
   begin
   if contador mod 100 = 0 then
      begin
      info('REBUILDING '+Contador.ToString);  //'Rebuilding sumary block: '
      application.ProcessMessages;
      EngineLastUpdate := UTCTime.ToInt64;
      end;
   if ((contador = MyLastBlock) and (contador>0)) then
      LastHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock-1)+'.blk');
   info(LangLine(127)+IntToStr(contador)); //'Rebuild block: '
   BlockHeader := LoadBlockDataHeader(contador);
   dato := default(ResumenData);
   seek(FileResumen,contador);
   if filesize(FileResumen)>contador then
      Read(FileResumen,dato);
   If ((contador>0) and (BlockHeader.LastBlockHash <> LastHash)) then
      begin  // Que hacer si todo encaja pero el sumario no esta bien
      //RestoreBlockChain();
      end;
   CurrHash := HashMD5File(BlockDirectory+IntToStr(contador)+'.blk');
   if  CurrHash <> Dato.blockhash then
      begin
      NewDato := Default(ResumenData);
      NewDato := Dato;
      NewDato.block:=contador;
      NewDato.blockhash:=CurrHash;
      seek(FileResumen,contador);
      Write(FileResumen,Newdato);
      end;
   if contador > ListaSumario[0].LastOP then // el bloque analizado es mayor que el ultimo incluido
      begin                                  // en el sumario asi que se procesan sus trxs
      newblocks := newblocks + 1;
      AddBlockToSumary(contador);
      end;
   // VErificar si el sumario hash no esta en blanco
   seek(FileResumen,contador);
   Read(FileResumen,dato);
   if dato.SumHash = '' then
      begin
      NewDato := Default(ResumenData);
      NewDato := Dato;
      NewDato.SumHash:=HashMD5File(SumarioFilename);
      seek(FileResumen,contador);
      Write(FileResumen,Newdato);
      tolog ('Readjusted sumhash for block '+inttostr(contador));
      end;
   contador := contador+1;
   LastHash := CurrHash;
   end;
while filesize(FileResumen)> Untilblock+1 do  // cabeceras presenta un numero anomalo de registros
   begin
   seek(FileResumen,Untilblock+1);
   truncate(fileResumen);
   toexclog ('Readjusted headers size');
   end;
closefile(FileResumen);
if newblocks>0 then
   begin
   ConsoleLinesAdd(IntToStr(newblocks)+LangLine(129)); //' added to headers'
   U_Mytrxs := true;
   U_DirPanel := true;
   end;
GuardarSumario();
UpdateMyData();
MySumarioHash := HashMD5File(SumarioFilename);
U_Dirpanel := true;
if g_launching then OutText('✓ '+IntToStr(untilblock+1)+' blocks rebuilded',false,1);
End;

// COmpletes the sumary from LAstUpdate to Lastblock
Procedure CompleteSumary();
var
  StartBlock, finishblock : integer;
  counter : integer;
Begin
SetCurrentJob('CompleteSumary',true);
RebuildingSumary := true;
StartBlock := ListaSumario[0].LastOP+1;
finishblock := Mylastblock;
for counter := StartBlock to finishblock do
   begin
   info(LangLine(130)+inttoStr(counter));  //'Rebuilding sumary block: '
   application.ProcessMessages;
   EngineLastUpdate := UTCTime.ToInt64;
   AddBlockToSumary(counter, false);
   end;
SetCurrentJob('save',true);
GuardarSumario();
SetCurrentJob('save',false);
RebuildingSumary := false;
UpdateMyData();
ConsoleLinesAdd('Sumary completed from '+IntToStr(StartBlock)+' to '+IntToStr(finishblock));
SetCurrentJob('CompleteSumary',false);
RebuildMyTrx(finishblock);
info('Sumary completed');
End;

// Add 1 block transactions to sumary
Procedure AddBlockToSumary(BlockNumber:integer;SaveAndUpdate:boolean = true);
var
  cont : integer;
  BlockHeader : BlockHeaderData;
  ArrayOrders : BlockOrdersArray;
  ArrayPos    : BlockArraysPos;
  ArrayMNs    : BlockArraysPos;
  PosReward   : int64;
  PosCount    : integer;
  CounterPos  : integer;
  MNsReward   : int64;
  MNsCount    : integer;
  CounterMNs  : integer;
Begin
SetCurrentJob('AddBlockToSumary'+inttostr(BlockNumber),true);
BlockHeader := Default(BlockHeaderData);
BlockHeader := LoadBlockDataHeader(BlockNumber);
EnterCriticalSection(CSSumary);
UpdateSumario(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,0,IntToStr(BlockNumber));
ArrayOrders := Default(BlockOrdersArray);
ArrayOrders := GetBlockTrxs(BlockNumber);
for cont := 0 to length(ArrayOrders)-1 do
   begin
   if ArrayOrders[cont].OrderType='CUSTOM' then
      begin
      UpdateSumario(ArrayOrders[cont].Sender,Restar(Customizationfee),0,IntToStr(BlockNumber));
      setcustomalias(ArrayOrders[cont].Sender,ArrayOrders[cont].Receiver,BlockNumber);
      end;
   if ArrayOrders[cont].OrderType='TRFR' then
      begin
      UpdateSumario(ArrayOrders[cont].Sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(BlockNumber));
      UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(BlockNumber));
      end;
   end;
setlength(ArrayOrders,0);
if blocknumber >= PoSBlockStart then
   begin
   ArrayPos := GetBlockPoSes(BlockNumber);
   PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
   SetLength(ArrayPos,length(ArrayPos)-1);
   PosCount := length(ArrayPos);
   for counterpos := 0 to PosCount-1 do
      UpdateSumario(ArrayPos[counterPos].address,Posreward,0,IntToStr(BlockNumber));
   UpdateSumario(BlockHeader.AccountMiner,Restar(PosCount*Posreward),0,IntToStr(BlockNumber));
   SetLength(ArrayPos,0);
   end;

if blocknumber >= MNBlockStart then
   begin
   ArrayMNs := GetBlockMNs(BlockNumber);
   MNsReward := StrToIntDef(ArrayMNs[length(ArrayMNs)-1].address,0);
   SetLength(ArrayMNs,length(ArrayMNs)-1);
   MNsCount := length(ArrayMNs);
   for counterMNs := 0 to MNsCount-1 do
      UpdateSumario(ArrayMNs[counterMNs].address,MNsreward,0,IntToStr(BlockNumber));
   UpdateSumario(BlockHeader.AccountMiner,Restar(MNsCount*MNsreward),0,IntToStr(BlockNumber));
   SetLength(ArrayMNs,0);
   end;

ListaSumario[0].LastOP:=BlockNumber;
if ( (SaveAndUpdate) or (BlockNumber mod SumMarkInterval = 0) ) then
   begin
   GuardarSumario();
   {if not RunningDoctor then} UpdateMyData();
   end;
LeaveCriticalSection(CSSumary);
SetCurrentJob('AddBlockToSumary'+inttostr(BlockNumber),false);
End;

// Rebuilds totally sumary
Procedure RebuildSumario(UntilBlock:integer);
var
  contador, cont : integer;
  BlockHeader : BlockHeaderData;
  ArrayOrders : BlockOrdersArray;
  ArrayPos    : BlockArraysPos;
  PosReward   : int64;
  PosCount    : integer;
  CounterPos  : integer;
  ArrayMNs    : BlockArraysPos;
  MNsReward   : int64;
  MNsCount    : integer;
  CounterMNs  : integer;
Begin
SetCurrentJob('RebuildSumario',true);
EnterCriticalSection(CSSumary);
RebuildingSumary := true;
SetLength(ListaSumario,0);
// incluir el pago del bloque genesys
UpdateSumario(ADMINHash,PremineAmount,0,'0');
for contador := 1 to UntilBlock do
   begin
   if contador mod 10 = 0 then
      begin
      info(LangLine(130)+inttoStr(contador));  //'Rebuilding sumary block: '
      EngineLastUpdate := UTCTime.ToInt64;
      application.ProcessMessages;
      end;
   BlockHeader := Default(BlockHeaderData);
   BlockHeader := LoadBlockDataHeader(contador);
   UpdateSumario(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,0,IntToStr(contador));
   ArrayOrders := Default(BlockOrdersArray);
   ArrayOrders := GetBlockTrxs(contador);
   for cont := 0 to length(ArrayOrders)-1 do
      begin
      if ArrayOrders[cont].OrderType='CUSTOM' then
         begin
         UpdateSumario(ArrayOrders[cont].Sender,Restar(Customizationfee),0,IntToStr(contador));
         setcustomalias(ArrayOrders[cont].Sender,ArrayOrders[cont].Receiver,contador);
         end;
      if ArrayOrders[cont].OrderType='TRFR' then
         begin
         UpdateSumario(ArrayOrders[cont].Sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(contador));
         UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(contador));
         end;
      end;
   setlength(ArrayOrders,0);
   if contador >= PoSBlockStart then
      begin
      ArrayPos := GetBlockPoSes(contador);
      PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
      SetLength(ArrayPos,length(ArrayPos)-1);
      PosCount := length(ArrayPos);
      for counterpos := 0 to PosCount-1 do
         UpdateSumario(ArrayPos[counterPos].address,Posreward,0,IntToStr(contador));
      // Restar el PoS al minero
      UpdateSumario(BlockHeader.AccountMiner,Restar(PosCount*Posreward),0,IntToStr(contador));
      SetLength(ArrayPos,0);
      end;

   if contador >= MNBlockStart then
      begin
      ArrayMNs := GetBlockMNs(contador);
      MNsReward := StrToIntDef(ArrayMNs[length(ArrayMNs)-1].address,0);
      SetLength(ArrayMNs,length(ArrayMNs)-1);
      MNsCount := length(ArrayMNs);
      for counterMNs := 0 to MNsCount-1 do
         UpdateSumario(ArrayMNs[counterMNs].address,MNsreward,0,IntToStr(contador));
      UpdateSumario(BlockHeader.AccountMiner,Restar(MNsCount*MNsreward),0,IntToStr(contador));
      SetLength(ArrayMNs,0);
      end;
   ListaSumario[0].LastOP:=contador;
   if contador mod SumMarkInterval = 0 then
      begin
      //form1.MemoConsola.lines.Add('Saving backup');
      GuardarSumario();
      end;
   end;
RebuildingSumary := false;
LeaveCriticalSection(CSSumary);
GuardarSumario();
UpdateMyData();
SetCurrentJob('RebuildSumario',true);
ConsoleLinesAdd(LangLine(131));  //'Sumary rebuilded.'
end;

// adds a header at the end of headers file
Procedure AddBlchHead(Numero: int64; hash,sumhash:string);
var
  Dato: ResumenData;
Begin
EnterCriticalSection(CSHeadAccess);
TRY
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Dato := Default(ResumenData);
Dato.block:=Numero;
Dato.blockhash:=hash;
Dato.SumHash:=sumhash;
seek(fileResumen,filesize(fileResumen));
write(fileResumen,dato);
closefile(FileResumen);
EXCEPT on E:Exception do
   tolog ('Error adding new register to headers');
END;
LeaveCriticalSection(CSHeadAccess);
End;

// Deletes last header from headers file
Function DelBlChHeadLast(Block:integer): boolean;
Begin
EnterCriticalSection(CSHeadAccess);
   TRY
   assignfile(FileResumen,ResumenFilename);
   reset(FileResumen);
   seek(fileResumen,filesize(fileResumen)-1);
   truncate(fileResumen);
   closefile(FileResumen);
   Result := true;
   EXCEPT on E:Exception do
      begin
      tolog ('Error deleting last record from headers');
      result := false;
      end;
   END;{TRY}
LeaveCriticalSection(CSHeadAccess);
End;

Function GetHeadersSize():integer;
Begin
EnterCriticalSection(CSHeadAccess);
assignfile(FileResumen,ResumenFilename);
   TRY
   reset(FileResumen);
   Result := filesize(fileResumen)-1;
   closefile(FileResumen);
   EXCEPT on E:Exception do
      begin
      tolog ('Error retrieving headers size');
      end;
   END;{TRY}
LeaveCriticalSection(CSHeadAccess);
End;

Function ShowBlockHeaders(BlockNumber:Integer):String;
var
  Dato: ResumenData;
Begin
result :='';
if BlockNumber=-1 then BlockNumber:= MyLastBlock;
EnterCriticalSection(CSHeadAccess);
TRY
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Dato := Default(ResumenData);
seek(fileResumen,BlockNumber);
Read(fileResumen,dato);
Result := Dato.block.ToString+':'+Dato.blockhash+':'+Dato.SumHash;
closefile(FileResumen);
EXCEPT on E:Exception do
   tolog ('Error adding new register to headers');
END;
LeaveCriticalSection(CSHeadAccess);
End;

Function LastHeaders(FromBlock:integer):String;
var
  Dato: ResumenData;
Begin
result := '';
if FromBlock<MyLastBlock-1008 then exit;
setmilitime('LastHeaders',1);
EnterCriticalSection(CSHeadAccess);
TRY
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Dato := Default(ResumenData);
seek(fileResumen,FromBlock+1);
While not Eof(fileResumen) do
   begin
   Read(fileResumen,dato);
   Result := Result+Dato.block.ToString+':'+Dato.blockhash+':'+Dato.SumHash+' ';
   end;
closefile(FileResumen);
Result := Trim(Result);
EXCEPT on E:Exception do

END;{TRY}
LeaveCriticalSection(CSHeadAccess);
setmilitime('LastHeaders',2);
End;

// Creates user transactions file
Procedure CrearMistrx();
var
  DefaultOrder : MyTrxData;
Begin
   try
   DefaultOrder := Default(MyTrxData);
   DefaultOrder.Block:=0;
   DefaultOrder.receiver:='0 0 0 0';
   assignfile(FileMyTrx,MyTrxFilename);
   rewrite(FileMyTrx);
   write(FileMyTrx,DefaultOrder);
   closefile(FileMyTrx);
   SetLength(ListaMisTrx,1);
   ListaMisTrx[0] := DefaultOrder;
   Except on E:Exception do
      toexclog ('Error creating my trx file: '+E.Message);
   end;
End;

// Loads user transactions from disk
Procedure CargarMisTrx();
var
  dato : MyTrxData;
  firsToRead : integer;
  counter : integer;
Begin
setmilitime('CargarMisTrx',1);
   try
   assignfile(FileMyTrx,MyTrxFilename);
   reset(FileMyTrx);
   setlength(ListaMisTrx,1);
   seek (FileMyTrx,0);
   Read(FileMyTrx,dato);
   ListaMisTrx[0] := dato;
   //firsToRead := filesize(FileMyTrx)-ShowedOrders;
   //if firsToRead < 1 then firsToRead := 1;
   firsToRead := 1;
   if filesize(FileMyTrx) > 1 then
      begin
      for counter := firsToRead to filesize(FileMyTrx)-1 do
         begin
         seek (FileMyTrx,counter);
         Read(FileMyTrx,dato);
         Insert(dato,ListaMisTrx,length(ListaMisTrx));
         end;
      end;
   closefile(FileMyTrx);
   G_PoSPayouts := StrToInt64Def(parameter(ListaMisTrx[0].receiver,0),0);
   G_PoSEarnings := StrToInt64Def(parameter(ListaMisTrx[0].receiver,1),0);
   G_MNsPayouts := StrToInt64Def(parameter(ListaMisTrx[0].receiver,2),0);
   G_MNsEarnings := StrToInt64Def(parameter(ListaMisTrx[0].receiver,3),0);
   if G_Launching then
      OutText('✓ '+IntToStr(length(ListaMisTrx))+' own transactions',false,1);
   Except on E:Exception do
      toexclog ('Error loading my trx from file');
   end;
setmilitime('CargarMisTrx',2);
End;

// Save value of last checked block for user transactions
Procedure SaveMyTrxsLastUpdatedblock(Number:integer;PoSPayouts, PoSEarnings, MNsPayouts, MNsEarnings:int64);
var
  FirstTrx : MyTrxData;
Begin
SetCurrentJob('SaveMyTrxsLastUpdatedblock',true);
TRY
FirstTrx := Default(MyTrxData);
FirstTrx.block:=Number;
FirstTrx.receiver := IntToStr(PoSPayouts)+' '+IntToStr(PoSEarnings)+' '+IntToStr(MNsPayouts)+' '+IntToStr(MNsEarnings);
assignfile (FileMyTrx,MyTrxFilename);
reset(FileMyTrx);
seek(FileMyTrx,0);
write(FileMyTrx,FirstTrx);
Closefile(FileMyTrx);
G_PoSPayouts  := PoSPayouts;
G_PoSEarnings := PoSEarnings;
G_MNsPayouts  := MNsPayouts;
G_MNsEarnings := MNsEarnings;
ListaMisTrx[0].receiver := IntToStr(PoSPayouts)+' '+IntToStr(PoSEarnings)+' '+IntToStr(MNsPayouts)+' '+IntToStr(MNsEarnings);
if G_PoSPayouts > 0 then
   ToLog(Format('Total PoS : %d : %s',[G_PoSPayouts,Int2curr(G_PoSEarnings)]));
if G_MNsPayouts > 0 then
   ToLog(Format('Total MNs : %d : %s',[G_MNsPayouts,Int2curr(G_MNsEarnings)]));
EXCEPT on E:Exception do
   toExclog ('Error setting last block checked for my trx');
END;{Try}
U_PoSGrid := true;
SetCurrentJob('SaveMyTrxsLastUpdatedblock',false);
End;

// Rebuilds user transactions  file up to specified block
Procedure RebuildMyTrx(blocknumber:integer);
var
  contador,contador2 : integer;
  Existentes : integer;
  Header : BlockHeaderData;
  NewTrx : MyTrxData;
  ArrTrxs : BlockOrdersArray;
  ArrayPos    : BlockArraysPos;
  PosReward   : int64;
  PosCount    : integer;
  CounterPos  : integer;
  PoSPayouts, PoSEarnings : int64;
  MNsPayouts, MNsEarnings : int64;
  BlockPayouts, BlockEarnings : int64;
Begin
if not WO_RebuildTrx then
   begin
   consolelinesAdd('Skipping rebuild transactions');
   exit;
   end;
SetCurrentJob('RebuildMyTrx',true);
Existentes := Length(ListaMisTrx);
if ListaMisTrx[0].Block < blocknumber then
   begin
   TRY
   PoSPayouts := StrToInt64Def(parameter(ListaMisTrx[0].receiver,0),0);
   PoSEarnings := StrToInt64Def(parameter(ListaMisTrx[0].receiver,1),0);
   MNsPayouts := StrToInt64Def(parameter(ListaMisTrx[0].receiver,2),0);
   MNsEarnings := StrToInt64Def(parameter(ListaMisTrx[0].receiver,3),0);
   NewTrx := Default(MyTrxData);
   for contador := ListaMisTrx[0].Block+1 to blocknumber do
      begin
      NewTrx := Default(MyTrxData);
      if Not G_Launching then
         begin
         info(Format('Rebuilding my Trxs: %d',[contador]));
         EngineLastUpdate := UTCTime.ToInt64;
         application.ProcessMessages;
         end
      else
         begin
         gridinicio.RowCount:=gridinicio.RowCount-1;
         OutText(Format('Rebuilding my Trxs: %d',[contador]),false,1);
         end;
      BlockPayouts := 0;
      BlockEarnings := 0;
      Header := LoadBlockDataHeader(contador);
      if DireccionEsMia(Header.AccountMiner)>=0 then // user is miner
         begin
         NewTrx.block:=contador;
         NewTrx.time :=header.TimeEnd;
         NewTrx.tipo :='MINE';
         NewTrx.receiver:=header.AccountMiner;
         NewTrx.monto   :=header.Reward+header.MinerFee;
         NewTrx.trfrID  :='';
         NewTrx.OrderID :='';
         NewTrx.reference:='';
         end;
      ArrTrxs := GetBlockTrxs(contador);
      if length(ArrTrxs)>0 then
         begin
         for contador2 := 0 to length(ArrTrxs)-1 do
            begin
            if DireccionEsMia(ArrTrxs[contador2].sender)>=0 then // user is sender
               begin
               NewTrx := Default(MyTrxData);
               NewTrx.block:=contador;
               NewTrx.time :=header.TimeEnd;
               NewTrx.tipo :=ArrTrxs[contador2].OrderType;
               NewTrx.receiver:= ArrTrxs[contador2].Receiver;
               NewTrx.monto   := Restar(ArrTrxs[contador2].AmmountFee+ArrTrxs[contador2].AmmountTrf);
               NewTrx.trfrID  := ArrTrxs[contador2].TrfrID;
               NewTrx.OrderID := ArrTrxs[contador2].OrderID;
               NewTrx.reference:= ArrTrxs[contador2].reference;
               insert(NewTrx,ListaMisTrx,length(ListaMisTrx));
               end;
            if DireccionEsMia(ArrTrxs[contador2].receiver)>=0 then //user is receiver
               begin
               NewTrx := Default(MyTrxData);
               NewTrx.block:=contador;
               NewTrx.time :=header.TimeEnd;
               NewTrx.tipo :=ArrTrxs[contador2].OrderType;
               NewTrx.receiver:= ArrTrxs[contador2].receiver;
               NewTrx.monto   := ArrTrxs[contador2].AmmountTrf;
               NewTrx.trfrID  := ArrTrxs[contador2].TrfrID;
               NewTrx.OrderID := ArrTrxs[contador2].OrderID;
               NewTrx.reference:= ArrTrxs[contador2].reference;
               insert(NewTrx,ListaMisTrx,length(ListaMisTrx));
               end;
            end;
         end;
      setlength(ArrTrxs,0);
      if contador >= PoSBlockStart then  // PoS payments
         begin
         ArrayPos := GetBlockPoSes(contador);
         PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
         SetLength(ArrayPos,length(ArrayPos)-1);
         PosCount := length(ArrayPos);
         for counterpos := 0 to PosCount-1 do
            begin
            if direccionesmia(ArrayPos[counterPos].address)>=0 then
               begin
               BlockPayouts+=1;
               PoSPayouts := PoSPayouts+1;
               BlockEarnings := BlockEarnings+PosReward;
               PoSEarnings := PoSEarnings + PosReward;
               end;
            end;
         if BlockPayouts > 0 then
            ToLog(Format('PoS : %d -> %d : %s',[contador,BlockPayouts,Int2curr(BlockEarnings)]));
         if NewTrx.tipo ='MINE' then NewTrx.monto :=NewTrx.monto-(PosReward*PosCount);
         SetLength(ArrayPos,0);
         end;
      if contador >= MNBlockStart then  // MNs payments
         begin
         BlockPayouts := 0;
         BlockEarnings := 0;
         ArrayPos := GetBlockMNs(contador);
         PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
         SetLength(ArrayPos,length(ArrayPos)-1);
         PosCount := length(ArrayPos);
         for counterpos := 0 to PosCount-1 do
            begin
            if direccionesmia(ArrayPos[counterPos].address)>=0 then
               begin
               BlockPayouts+=1;
               MNsPayouts := MNsPayouts+1;
               BlockEarnings := BlockEarnings+PosReward;
               MNsEarnings := MNsEarnings + PosReward;
               end;
            end;
         if BlockPayouts > 0 then
            ToLog(Format('MNs : %d -> %d : %s',[contador,BlockPayouts,Int2curr(BlockEarnings)]));
         if NewTrx.tipo ='MINE' then NewTrx.monto :=NewTrx.monto-(PosReward*PosCount);
         SetLength(ArrayPos,0);
         end;
      if NewTrx.tipo ='MINE' then insert(NewTrx,ListaMisTrx,length(ListaMisTrx));
      end;
   ListaMisTrx[0].block:=blocknumber;
   ListaMisTrx[0].receiver:=IntToStr(PoSPayouts)+' '+IntToStr(PoSEarnings)+' '+IntToStr(MNsPayouts)+' '+IntToStr(MNsEarnings);
   if length(ListaMisTrx) > Existentes then  // se han añadido transacciones
      begin
      SaveMyTrxsToDisk(existentes);
      U_Mytrxs := true;
      end;
   SaveMyTrxsLastUpdatedblock(blocknumber, PoSPayouts, PoSEarnings, MNsPayouts, MNsEarnings);
   EXCEPT ON E:Exception do
      ToExcLog('*****CRITICAL***** Error in RebuildMyTrx: '+E.Message);
   END;{Try}
   end;
SetCurrentJob('RebuildMyTrx',false);
End;

// Save last user transactions to disk
Procedure SaveMyTrxsToDisk(Cantidad:integer);
var
  contador : integer;
Begin
setmilitime('SaveMyTrxsToDisk',1);
SetCurrentJob('SaveMyTrxsToDisk',true);
TRY
assignfile (FileMyTrx,MyTrxFilename);
reset(FileMyTrx);
for contador := cantidad to length(ListaMisTrx)-1 do
   begin
   seek(FileMyTrx,contador);
   write(FileMyTrx,ListaMisTrx[contador]);
   end;
Closefile(FileMyTrx);
EXCEPT on E:Exception do
   toExclog ('Error saving my trx to disk');
END;{Try}
SetCurrentJob('SaveMyTrxsToDisk',false);
setmilitime('SaveMyTrxsToDisk',2);
End;

// Creates a bat file for restart
Procedure CreateLauncherFile(IncludeUpdate:boolean = false);
var
  archivo : textfile;
Begin
Assignfile(archivo,RestartFilename);
rewrite(archivo);
TRY
{$IFDEF WINDOWS}
writeln(archivo,'echo Restarting Noso...');
writeln(archivo,'TIMEOUT 5');
writeln(archivo,'tasklist /FI "IMAGENAME eq '+AppFileName+'" 2>NUL | find /I /N "'+AppFileName+'">NUL');
writeln(archivo,'if "%ERRORLEVEL%"=="0" taskkill /F /im '+AppFileName);
if IncludeUpdate then
   begin
   writeln(archivo,'del '+AppFileName);
   writeln(archivo,'ren nosonew noso.exe');
   writeln(archivo,'start noso.exe');
   end
else writeln(archivo,'start '+Appfilename);
{$ENDIF}
{$IFDEF UNIX}
writeln(archivo,'for x in 5 4 3 2 1; do');
writeln(archivo,'echo -ne "Restarting in ${x}\r"');
writeln(archivo,'sleep 1');
writeln(archivo,'done');
writeln(archivo,'PID=$(ps ux | grep -v grep | grep -i '+AppFileName+' | cut -d" " -f 2)');
writeln(archivo,'if [ "${PID}" != "" ]; then');
writeln(archivo,'echo Killing '+AppFileName);
writeln(archivo,'kill ${PID}');
writeln(archivo,'fi');
if IncludeUpdate then
   begin
   writeln(archivo,'rm '+AppFileName);
   writeln(archivo,'mv Nosonew Noso');
   writeln(archivo,'chmod +x Noso');
   writeln(archivo,'./Noso');
   end
else
   writeln(archivo,'./'+AppFileName);
{$ENDIF}
EXCEPT on E:Exception do
   if not G_ClosingAPP then tolog ('Error creating restart file: '+E.Message);
END{Try};
Closefile(archivo);
End;

// Prepares for restart
Procedure RestartNoso();
Begin
CreateLauncherFile();
RunExternalProgram(RestartFilename);
End;

Procedure NewDoctor();
var
  cont : integer;
  firstB,lastB : integer;
  dato : ResumenData;
  WorkLoad : integer;
Begin
firstB := form1.SpinDoctor1.Value;
LastB := form1.SpinDoctor2.Value;
WorkLoad := LastB-FirstB;
form1.MemoDoctor.Lines.Clear;
assignfile(FileResumen,ResumenFilename);
if ((form1.CBBlockhash.Checked) or (form1.CBSummaryhash.Checked)) then
   reset(FileResumen);
if form1.CBSummaryhash.Checked then Rebuildsumario(FirstB-1);
RunningDoctor := True;
for cont := firstB to lastB do
   begin
   if ((form1.CBBlockhash.Checked) or (form1.CBSummaryhash.Checked)) then
      begin
      Seek(FileResumen,cont);
      Read(FileResumen,dato);
      end;
   form1.LabelDoctor.Caption:=format(rs1000,[cont,((Cont-firstB)*100) div Workload]);
   form1.LabelDoctor.Update;
   EngineLastUpdate := UTCTime.ToInt64;
   Application.ProcessMessages;
   if form1.CBBlockexists.Checked then  // check block file
      begin
      if not fileexists(BlockDirectory+IntToStr(cont)+'.blk') then
         begin
         form1.MemoDoctor.Lines.Add(format(rs1001,[cont]));
         form1.MemoDoctor.Lines.Add(format(rs1003,[BlockDirectory+IntToStr(cont)]));
         end;
      end;
   if form1.CBBlockhash.Checked then    // check block hash
      begin
      if HashMD5File(BlockDirectory+IntToStr(cont)+'.blk')<> dato.blockhash then
         begin
         form1.MemoDoctor.Lines.Add(format(rs1001,[cont]));
         form1.MemoDoctor.Lines.Add(Format(rs1002,[HashMD5File(BlockDirectory+IntToStr(cont)+'.blk'),dato.blockhash]));
         end;
      end;
   if form1.CBSummaryhash.Checked then   // Check summary hash
      begin
      AddBlockToSumary(cont);
      if HashMD5File(SumarioFilename) <> dato.SumHash then
         begin
         form1.MemoDoctor.Lines.Add(format(rs1001,[cont]));
         form1.MemoDoctor.Lines.Add(format(rs1004,[HashMD5File(SumarioFilename),dato.SumHash]));
         end;
      end;
   if stopdoctor then break;
   end;
RunningDoctor := false;
if ((form1.CBBlockhash.Checked) or (form1.CBSummaryhash.Checked)) then
   CloseFile(FileResumen);
form1.ButStartDoctor.Visible:=true;
form1.ButStopDoctor.Visible:=false;

End;

// Runs doctor tool
Procedure RunDiagnostico(linea:string);
var
  cont : integer;
  lastblock : integer;
  dato : ResumenData;
  fixfiles: boolean = false;
  errores : integer = 0;
  fixed : integer = 0;
  porcentaje : integer;
  badBlockHashes : string = '';
Begin
Miner_KillThreads := true;
CloseAllforms();
CerrarClientes();
StopServer();
If Miner_IsOn then Miner_IsON := false;
KillAllMiningThreads;
//setlength(CriptoOpsTIPO,0);
RunningDoctor := true;
if UpperCase(parameter(linea,1)) = 'FIX' then fixfiles := true;
lastblock := GetMyLastUpdatedBlock;
forminicio.Caption:='Noso Doctor';
GridInicio.RowCount:=0;
FormInicio.BorderIcons:=FormInicio.BorderIcons-[bisystemmenu];
forminicio.visible := true;
form1.Visible:=false;
if lastblock = 0 then
   begin
   outtext('You can not run diagnostic now',false,1);
   RunningDoctor := false;
   FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
   exit;
   end;
{
outtext('Blocks to check: '+IntToStr(lastblock+1),false,1);
outtext('Checking block files 0 %',false,1);
for cont := 0 to lastblock do
   begin
   gridinicio.RowCount := gridinicio.RowCount-1;
   if not fileexists(BlockDirectory+IntToStr(cont)+'.blk') then
      begin
      errores +=1;
      end;
   EngineLastUpdate := UTCTime.ToInt64;
   porcentaje := (cont * 100) div lastblock;
   outtext('Checking block files '+inttostr(porcentaje)+' %',false,1);
   end;
outtext('Missing blocks: '+IntToStr(errores),false,1);
errores := 0;
}
outtext('Block hash correct 0 %',false,1);
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
for cont := 0 to lastblock do
   begin
   EngineLastUpdate := UTCTime.ToInt64;
   Seek(FileResumen,cont);
   Read(FileResumen,dato);
   gridinicio.RowCount := gridinicio.RowCount-1;
   if HashMD5File(BlockDirectory+IntToStr(cont)+'.blk')<> dato.blockhash then
      begin
      errores +=1;
      badBlockHashes := badBlockHashes+IntToStr(cont)+',';
      if fixfiles then
         begin
         fixed +=1;
         dato.block:=cont;
         dato.blockhash:=HashMD5File(BlockDirectory+IntToStr(cont)+'.blk');
         Seek(FileResumen,cont);
         write(FileResumen,dato);
         end;
      end;
   porcentaje := (cont * 100) div lastblock;
   outtext('Block hash correct '+inttostr(porcentaje)+' %',false,1);
   end;
outtext('Wrong block hashes: '+IntToStr(errores),false,1);
outtext('Numbers: '+badBlockHashes,false,1);
errores := 0;
{
outtext('Sumary hash correct 0 %',false,1);
for cont := 1 to lastblock do
   begin
   EngineLastUpdate := UTCTime.ToInt64;
   Seek(FileResumen,cont);
   Read(FileResumen,dato);
   gridinicio.RowCount := gridinicio.RowCount-1;
   if cont = 1 then RebuildSumario(cont)
   else AddBlockToSumary(cont);
   if HashMD5File(SumarioFilename) <> dato.SumHash then
      begin
      errores +=1;
      if fixfiles then
         begin
         fixed +=1;
         dato.block:=cont;
         dato.SumHash:=HashMD5File(SumarioFilename);
         Seek(FileResumen,cont);
         write(FileResumen,dato);
         end
      end;
   porcentaje := (cont * 100) div lastblock;
   outtext('Sumary hash correct '+IntToStr(porcentaje)+' %',false,1);
   end;
closefile(FileResumen);
outtext('Wrong sumary hashes: '+IntToStr(errores),false,1);
errores := 0;
}
//outtext('Errors: '+IntToStr(errores)+' / Fixed: '+IntToStr(fixed),false,1);
RunningDoctor := false;
FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
UpdateMyData();
End;

// Saves the pool info file
Procedure GuardarArchivoPoolInfo();
Begin
setmilitime('GuardarArchivoPoolInfo',1);
   try
   assignfile(FilePool,PoolInfoFilename);
   rewrite(FilePool);
   write(filepool,PoolInfo);
   Closefile(FilePool);
   Except on E:Exception do
      tolog('Error saving PoolInfo file:'+E.Message);
   end;
S_PoolInfo := false;
setmilitime('GuardarArchivoPoolInfo',2);
End;

// Reads pool info from file
function GetPoolInfoFromDisk():PoolInfoData;
var
  dato : PoolInfoData;
Begin
try
assignfile(FilePool,PoolInfoFilename);
reset(FilePool);
read(filepool,dato);
result := dato;
Closefile(FilePool);
PoolInfo := Dato;
Except on E:Exception do
  tolog('Error loading pool info from disk');
end;
End;

// Creates pool members file
Procedure CrearArchivoPoolMembers;
Begin
assignfile(FilePoolMembers,PoolMembersFilename);
rewrite(FilePoolMembers);
Closefile(FilePoolMembers);
End;

// Load poolmembers file from disk
Procedure LoadPoolMembers();
var
  contador : integer;
  dato : PoolMembersData;
Begin
// ADD A VERIFICATION BEFORE LOAD IT IN CASE THE FILE IS CORRUPTED?
TRY
   assignfile(FilePoolMembers,PoolMembersFilename);
   reset(FilePoolMembers);
   setlength(ArrayPoolMembers,filesize(FilePoolMembers));
   if filesize(FilePoolMembers) > 0 then
      begin
      for contador := 0 to filesize(FilePoolMembers)-1 do
         begin
         seek(FilePoolMembers,contador);
         read(FilePoolMembers,dato);
         ArrayPoolMembers[contador]:= dato;
         end;
      end;
   Closefile(FilePoolMembers);
EXCEPT on E:Exception do
   ToLog('Error loading pool members from disk.');
END;
End;

// Creates and executes autolauncher.bat  // DEPRECATED
Procedure EjecutarAutoUpdate(version:string);
var
  archivo : textfile;
Begin
try
  Assignfile(archivo, 'nosolauncher.bat');
  rewrite(archivo);
  writeln(archivo,'echo Restarting Noso...');
  writeln(archivo,'TIMEOUT 5');
  writeln(archivo,'del noso.exe');
  writeln(archivo,'ren noso'+version+'.exe noso.exe');
  writeln(archivo,'start noso.exe');
  Closefile(archivo);
Except on E:Exception do
   tolog ('Error creating restart file');
end;
RunExternalProgram('nosolauncher.bat');
End;

// Creates autorestart file
Procedure CrearRestartfile();
var
  archivo : textfile;
Begin
Assignfile(archivo, 'restart.txt');
   try
   rewrite(archivo);
   writeln(archivo,GetCurrentStatus(0));
   Closefile(archivo);
   Except on E:Exception do
      tolog ('Error creating restart file');
   end;
End;

// apply restart conditions
Procedure RestartConditions();
var
  archivo : textfile;
  linea : string = '';
  Server,connect : boolean;
Begin
Assignfile(archivo, 'restart.txt');
reset(archivo);
TRY
ReadLn(archivo,linea);
ReadLn(archivo,Miner_RestartedSolution);
EXCEPT ON E:Exception do
   begin

   end;
END{Try};
Closefile(archivo);
server := StrToBoolDef(parameter(linea,1),WO_AutoServer);
connect := StrToBoolDef(parameter(linea,3),WO_AutoConnect);
if server then ProcessLinesAdd('SERVERON');
if connect then ProcessLinesAdd('CONNECT');
tryDeletefile('restart.txt');
End;

// Creates crashinfofile
Procedure CrearCrashInfo();
var
  archivo : textfile;
Begin
Assignfile(archivo, 'crashinfo.txt');
   try
   if not fileexists('crashinfo.txt') then rewrite(archivo)
   else append(archivo);
   writeln(archivo,GetCurrentStatus(1));
   {
   while ExceptLines.Count>0 do
      begin
      Writeln(archivo, ExceptLines[0]);
      ExceptLines.Delete(0);
      end;
   }
   Closefile(archivo);
   Except on E:Exception do
      tolog ('Error creating crashinfo file');
   end;
End;

// Gets OS version
function OSVersion: string;
begin
  {$IFDEF LCLcarbon}
  OSVersion := 'Mac OS X 10.';
  {$ELSE}
  {$IFDEF UNIX}
  OSVersion := 'Linux Kernel ';
  {$ELSE}
  {$IFDEF UNIX}
  OSVersion := 'Unix ';
  {$ELSE}
  {$IFDEF WINDOWS}
  OSVersion:= GetWinVer;
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}
end;

// Returns the windows version
{$IFDEF WINDOWS}
Function GetWinVer():string;
Begin
if WindowsVersion = wv95 then result := 'Windows95'
  else if WindowsVersion = wvNT4 then result := 'WindowsNTv.4'
  else if WindowsVersion = wv98 then result := 'Windows98'
  else if WindowsVersion = wvMe then result := 'WindowsME'
  else if WindowsVersion = wv2000 then result := 'Windows2000'
  else if WindowsVersion = wvXP then result := 'WindowsXP'
  else if WindowsVersion = wvServer2003 then result := 'WindowsServer2003/WindowsXP64'
  else if WindowsVersion = wvVista then result := 'WindowsVista'
  else if WindowsVersion = wv7 then result := 'Windows7'
  else if WindowsVersion = wv10 then result := 'Windows10'
  else result := 'WindowsUnknown';
End;
{$ENDIF}

// Executes the required steps to restore the blockchain
Procedure RestoreBlockChain();
Begin
Miner_KillThreads := true;
CloseAllforms();
CerrarClientes();
StopServer();
If Miner_IsOn then Miner_IsON := false;
KillAllMiningThreads;
//setlength(CriptoOpsTIPO,0);
deletefile(SumarioFilename);
deletefile(SumarioFilename+'.bak');
deletefile(ResumenFilename);
deletefile(MyTrxFilename);
if DeleteDirectory(BlockDirectory,True) then
   RemoveDir(BlockDirectory);
ProcessLinesAdd('restart');
End;

Procedure RestoreSumary(fromBlock:integer=0);
var
  startmark : integer = 0;
Begin
if fromblock = 0 then StartMark := ((GetMyLastUpdatedBlock div SumMarkInterval)-1)*SumMarkInterval
else StartMark := Fromblock;
LoadSumaryFromFile(MarksDirectory+StartMark.ToString+'.bak');
ConsoleLinesAdd('Restoring sumary from '+StartMark.ToString);
CompleteSumary;
End;

Procedure InitCrossValues();
Begin
OptionsFileName     := 'NOSODATA'+DirectorySeparator+'options.psk';
BotDataFilename     := 'NOSODATA'+DirectorySeparator+'botdata.psk';
NodeDataFilename    := 'NOSODATA'+DirectorySeparator+'nodes.psk';
NTPDataFilename     := 'NOSODATA'+DirectorySeparator+'ntpservers.psk';
WalletFilename      := 'NOSODATA'+DirectorySeparator+'wallet.pkw';
SumarioFilename     := 'NOSODATA'+DirectorySeparator+'sumary.psk';
LanguageFileName    := 'NOSODATA'+DirectorySeparator+'noso.lng';
BlockDirectory      := 'NOSODATA'+DirectorySeparator+'BLOCKS'+DirectorySeparator;
MarksDirectory      := 'NOSODATA'+DirectorySeparator+'SUMMARKS'+DirectorySeparator;
UpdatesDirectory    := 'NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator;
LogsDirectory       := 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator;
ExceptLogFilename   := 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'exceptlog.txt';
ResumenFilename     := 'NOSODATA'+DirectorySeparator+'blchhead.nos';
MyTrxFilename       := 'NOSODATA'+DirectorySeparator+'mytrx.nos';
TranslationFilename := 'NOSODATA'+DirectorySeparator+'English_empty.txt';
ErrorLogFilename    := 'NOSODATA'+DirectorySeparator+'errorlog.txt';
PoolLogFilename     := 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'poollog.txt';
PoolInfoFilename    := 'NOSODATA'+DirectorySeparator+'poolinfo.dat';
PoolMembersFilename := 'NOSODATA'+DirectorySeparator+'poolmembers.dat';
AdvOptionsFilename  := 'NOSODATA'+DirectorySeparator+'advopt.txt';
MasterNodesFilename := 'NOSODATA'+DirectorySeparator+'masternodes.txt';
PoolPaymentsFilename:= 'NOSODATA'+DirectorySeparator+'poolpays.psk';
ZipSumaryFileName   := 'NOSODATA'+DirectorySeparator+'sumary.zip';
ZipHeadersFileName  := 'NOSODATA'+DirectorySeparator+'blchhead.zip';
GVTsFilename        := 'NOSODATA'+DirectorySeparator+'gvts.psk';
End;

// Try to delete a file safely
function TryDeleteFile(filename:string):boolean;
Begin
result := true;
   TRY
   deletefile(filename);
   EXCEPT on E:Exception do
      begin
      result := false;
      ToExcLog('Error deleting file ('+filename+') :'+E.Message);
      end;
   END;{TRY}
End;

// Trys to coyy a file safely
function TryCopyFile(Source, destination:string):boolean;
Begin
result := true;
   TRY
   copyfile (source,destination);
   EXCEPT on E:Exception do
      begin
      result := false;
      ToExcLog('Error copying file ('+Source+') :'+E.Message);
      end;
   END; {TRY}
End;

// Returns the name of the app file without path
function AppFileName():string;
var
  cont : integer;
  NameFile : string = '';
Begin
NameFile := Application.ExeName;
result := '';
for cont := Length(NameFile) downto 1 do
 if NameFile[cont] = DirectorySeparator then
   begin
     Result := Copy(NameFile, cont+1, Length(NameFile));
     Break;
   end;
End;


END. // END UNIT

