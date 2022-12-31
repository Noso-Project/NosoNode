unit mpdisk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, Dialogs, Forms, nosotime, FileUtil, LCLType,
  lclintf, controls, mpBlock, Zipper, mpcoin, mpMn, nosodebug,
  {$IFDEF WINDOWS}Win32Proc, {$ENDIF}
  translation, strutils,nosogeneral, nosocrypto, nosounit;

Procedure VerificarArchivos();

// *** New files system
// Nodes file
Procedure FillNodeList();
Function IsSeedNode(IP:String):boolean;

// GVTs file handling
Procedure CreateGVTsFile();
Procedure GetGVTsFileData();
Procedure SaveGVTs();
Function ChangeGVTOwner(Lnumber:integer;OldOwner,NewOWner:String): integer;

// NosoCFG file handling
Procedure SaveNosoCFGFile(LStr:String);
Procedure GetCFGDataFromFile();
Procedure SetNosoCFGString(LStr:string);
Function GetNosoCFGString(LParam:integer=-1):String;

Procedure CreateMasterNodesFile();
Procedure CreateADV(saving:boolean);
Procedure LoadADV();
Function GetLanguage():string;
Procedure ExtractPoFiles();
Procedure CreateFileFromResource(resourcename,filename:string);
Procedure CrearBotData();
Procedure CargarBotData();
Procedure UpdateBotData(IPUser:String);
Procedure SaveBotData();

// sumary
Procedure UpdateWalletFromSumario();
Procedure CreateSumario();
Procedure LoadSumaryFromFile(source:string='');
Procedure GuardarSumario(SaveCheckmark:boolean = false);
Procedure UpdateSumario(Direccion:string;monto:Int64;score:int64;LastOpBlock:string);
Procedure AddBlockToSumary(BlockNumber:integer;SaveAndUpdate:boolean = true);
Procedure CompleteSumary();
Procedure RebuildSumario(UntilBlock:integer);
Procedure ReorderSumario();

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
Function GetHeadersLastBlock():integer;
Function ShowBlockHeaders(BlockNumber:Integer):String;
Function LastHeaders(FromBlock:integer):String;

Procedure CreateLauncherFile(IncludeUpdate:boolean = false);
Procedure RestartNoso();
Procedure NewDoctor();
Procedure RunDiagnostico(linea:string);
Procedure CrearRestartfile();
Procedure RestartConditions();
function OSVersion: string;
{$IFDEF WINDOWS} Function GetWinVer():string; {$ENDIF}
Procedure RestoreBlockChain();
Procedure RestoreSumary(fromBlock:integer=0);
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
if not directoryexists(BlockDirectory) then CreateDir(BlockDirectory);
OutText('✓ Block folder ok',false,1);
if not directoryexists(UpdatesDirectory) then CreateDir(UpdatesDirectory);
OutText('✓ Updates folder ok',false,1);
if not directoryexists(MarksDirectory) then CreateDir(MarksDirectory);
OutText('✓ Marks folder ok',false,1);
if not directoryexists(GVTMarksDirectory) then CreateDir(GVTMarksDirectory);
OutText('✓ GVTs Marks folder ok',false,1);

if not FileExists (AdvOptionsFilename) then CreateADV(false) else LoadADV();
OutText('✓ Advanced options loaded',false,1);

if not FileExists(MasterNodesFilename) then CreateMasterNodesFile;
GetMNsFileData;
OutText('✓ Masternodes file ok',false,1);

if not FileExists(GVTsFilename) then CreateGVTsFile;
GetGVTsFileData;
OutText('✓ GVTs file ok',false,1);

if not FileExists(NosoCFGFilename) then SaveNosoCFGFile(DefaultNosoCFG);
GetCFGDataFromFile;
OutText('✓ NosoCFG file ok',false,1);


if not FileExists (WalletFilename) then CrearWallet() else CargarWallet(WalletFilename);
OutText('✓ Wallet file ok',false,1);
if not Fileexists(BotDataFilename) then CrearBotData() else CargarBotData();
OutText('✓ Bots file ok',false,1);

FillNodeList;  // Fills the hardcoded seed nodes list

if not Fileexists(SumarioFilename) then CreateSumario()
else LoadSummaryFromDisk(){LoadSumaryFromFile()};
OutText('✓ Sumary file ok',false,1);
if not Fileexists(ResumenFilename) then CreateResumen();
OutText('✓ Headers file ok',false,1);
if not FileExists(BlockDirectory+'0.blk') then CrearBloqueCero();

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
  SourceStr : String = '';
Begin
counter := 0;
SourceStr := Parameter(GetNosoCFGString,1);
SourceStr := StringReplace(SourceStr,':',' ',[rfReplaceAll, rfIgnoreCase]);
SetLength(ListaNodos,0);
Repeat
   ThisNode := parameter(SourceStr,counter);
   ThisNode := StringReplace(ThisNode,';',' ',[rfReplaceAll, rfIgnoreCase]);
   ThisPort := StrToIntDef(Parameter(ThisNode,1),8080);
   ThisNode := Parameter(ThisNode,0);
   if thisnode = '' then continuar := false
   else
      begin
      NodeToAdd.ip:=ThisNode;
      NodeToAdd.port:=IntToStr(ThisPort);
      NodeToAdd.LastConexion:=UTCTimeStr;
      Insert(NodeToAdd,Listanodos,Length(ListaNodos));
      counter+=1;
      end;
until not continuar;
End;

// If the specified IP a seed node
Function IsSeedNode(IP:String):boolean;
Begin
Result := false;
if AnsiContainsStr(GetNosoCFGString(1),ip) then result := true;
End;


// *** BOTS FILE ***


// *****************************************************************************

Procedure CreateMasterNodesFile();
var
  archivo : textfile;
Begin
TRY
Assignfile(archivo, MAsternodesfilename);
rewrite(archivo);
Closefile(archivo);
EXCEPT on E:Exception do
  AddLineToDebugLog('events',TimeToStr(now)+'Error creating the masternodes file');
END;
End;

Procedure CreateGVTsFile();
Begin
TRY
Assignfile(FileGVTs, GVTsFilename);
rewrite(FileGVTs);
Closefile(FileGVTs);
EXCEPT on E:Exception do
   AddLineToDebugLog('events',TimeToStr(now)+'Error creating the GVTs file');
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
   AddLineToDebugLog('events',TimeToStr(now)+'Error loading the GVTs from file');
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
   AddLineToDebugLog('events',TimeToStr(now)+'Error loading the GVTs from file');
END;
MyGVTsHash := HashMD5File(GVTsFilename);
LeaveCriticalSection(CSGVTsArray);
End;

Function ChangeGVTOwner(Lnumber:integer;OldOwner,NewOWner:String): integer;
var
  ErrorCode : integer = 0;
Begin
result := ErrorCode;
if LNumber > 99 then ErrorCode := 1;
if ArrGVTs[Lnumber].owner <> OldOwner then ErrorCode := 2;
if not IsValidHashAddress(NewOWner) then ErrorCode := 3;
if ErrorCode = 0 then
   begin
   ArrGVTs[Lnumber].owner := NewOWner;
   end;
End;

Procedure SaveNosoCFGFile(LStr:String);
var
  LFile : Textfile;
Begin
Assignfile(LFile, NosoCFGFilename);
TRY
   TRY
   rewrite(LFile);
   write(Lfile,LStr);
   EXCEPT on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error creating the NosoCFG file');
   END;
FINALLY
Closefile(LFile);
END; {TRY}
End;

Procedure GetCFGDataFromFile();
var
  LFile : Textfile;
  LStr  : string = '';
Begin
Assignfile(LFile, NosoCFGFilename);
TRY
   TRY
   reset(LFile);
   ReadLn(Lfile,LStr);
   SetNosoCFGString(LStr);
   EXCEPT on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error loading the NosoCFG file');
   END;
FINALLY
Closefile(LFile);
END; {TRY}
End;

Procedure SetNosoCFGString(LStr:string);
Begin
EnterCriticalSection(CSNosoCFGStr);
NosoCFGStr := LStr;
LEaveCriticalSection(CSNosoCFGStr);
End;

Function GetNosoCFGString(LParam:integer=-1):String;
Begin
EnterCriticalSection(CSNosoCFGStr);
if LParam<0 then Result := NosoCFGStr
else Result := Parameter(NosoCFGStr,LParam);
LeaveCriticalSection(CSNosoCFGStr);
End;

// Creates/Saves Advopt file
Procedure CreateADV(saving:boolean);
Begin
BeginPerformance('CreateADV');
   try
   Assignfile(FileAdvOptions, AdvOptionsFilename);
   rewrite(FileAdvOptions);
   writeln(FileAdvOptions,'---NosoNode config file.---');
   writeln(FileAdvOptions,'');

   writeln(FileAdvOptions,'---Wallet related.---');
   writeln(FileAdvOptions,'//Connect time-out in miliseconds');
   writeln(FileAdvOptions,'ctot '+inttoStr(ConnectTimeOutTime));
   writeln(FileAdvOptions,'//Read time-out in miliseconds');
   writeln(FileAdvOptions,'rtot '+inttoStr(ReadTimeOutTIme));
   writeln(FileAdvOptions,'//Connect automatically to mainnet at start');
   writeln(FileAdvOptions,'AutoConnect '+BoolToStr(WO_AutoConnect,true));
   writeln(FileAdvOptions,'//Minimize to system tray');
   writeln(FileAdvOptions,'ToTray '+BoolToStr(WO_ToTray,true));
   writeln(FileAdvOptions,'//Minimum connections to work');
   writeln(FileAdvOptions,'MinConexToWork '+IntToStr(MinConexToWork));
   writeln(FileAdvOptions,'//Use all addresses to send funds');
   writeln(FileAdvOptions,'MultiSend '+BoolToStr(WO_MultiSend,true));
   writeln(FileAdvOptions,'//Po files language code');
   writeln(FileAdvOptions,'Language '+(WO_Language));
   writeln(FileAdvOptions,'//Po files last update');
   writeln(FileAdvOptions,'PoUpdate '+(WO_LastPoUpdate));
   writeln(FileAdvOptions,'//Close the launch form automatically');
   writeln(FileAdvOptions,'Closestart '+BoolToStr(WO_CloseStart,true));
   writeln(FileAdvOptions,'//Mainform coordinates. Do not manually change this values');
   writeln(FileAdvOptions,Format('FormState %d %d %d %d %d',[Form1.Top,form1.Left,form1.Width,form1.Height,form1.WindowState]));
   writeln(FileAdvOptions,'');

   writeln(FileAdvOptions,'---Masternode---');
   writeln(FileAdvOptions,'//Enable node server at start');
   writeln(FileAdvOptions,'Autoserver '+BoolToStr(WO_AutoServer,true));
   writeln(FileAdvOptions,'//Run autoupdate directives');
   writeln(FileAdvOptions,'Autoupdate '+BoolToStr(WO_AutoUpdate,true));
   writeln(FileAdvOptions,'//Download the complete blockchain');
   writeln(FileAdvOptions,'WO_FullNode '+BoolToStr(WO_FullNode,true));
   writeln(FileAdvOptions,'//Masternode static IP');
   writeln(FileAdvOptions,'MNIP '+(MN_IP));
   writeln(FileAdvOptions,'//Masternode port');
   writeln(FileAdvOptions,'MNPort '+(MN_Port));
   writeln(FileAdvOptions,'//Masternode funds address');
   writeln(FileAdvOptions,'MNFunds '+(MN_Funds));
   if MN_Sign = '' then MN_Sign := ListaDirecciones[0].Hash;
   writeln(FileAdvOptions,'//Masternode sign address');
   writeln(FileAdvOptions,'MNSign '+(MN_Sign));
   writeln(FileAdvOptions,'//Use automatic IP detection for masternode');
   writeln(FileAdvOptions,'MNAutoIp '+BoolToStr(MN_AutoIP,true));
   writeln(FileAdvOptions,'');

   writeln(FileAdvOptions,'---RPC server---');
   writeln(FileAdvOptions,'//RPC server port');
   writeln(FileAdvOptions,'RPCPort '+inttoStr(RPCPort));
   writeln(FileAdvOptions,'//RPC server password');
   writeln(FileAdvOptions,'RPCPass '+RPCPass);
   writeln(FileAdvOptions,'//RPC IP filter active/inactive');
   writeln(FileAdvOptions,'RPCFilter '+BoolToStr(RPCFilter,true));
   writeln(FileAdvOptions,'//RPC whitelisted IPs');
   writeln(FileAdvOptions,'RPCWhiteList '+RPCWhitelist);
   writeln(FileAdvOptions,'//Enable RPC server at start');
   writeln(FileAdvOptions,'RPCAuto '+BoolToStr(RPCAuto,true));
   writeln(FileAdvOptions,'');

   writeln(FileAdvOptions,'---Deprecated. To be removed.---');
   writeln(FileAdvOptions,'UserFontSize '+inttoStr(UserFontSize));
   writeln(FileAdvOptions,'UserRowHeigth '+inttoStr(UserRowHeigth));
   writeln(FileAdvOptions,'ShowedOrders '+IntToStr(ShowedOrders));
   writeln(FileAdvOptions,'MaxPeers '+IntToStr(MaxPeersAllow));
   writeln(FileAdvOptions,'PosWarning '+IntToStr(WO_PosWarning));

   Closefile(FileAdvOptions);
   if saving then AddLineToDebugLog('events',TimeToStr(now)+'Options file saved');
   S_AdvOpt := false;
   Except on E:Exception do
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error creating/saving AdvOpt file: '+E.Message);
   end;
   EndPerformance('CreateADV');
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
      if parameter(linea,0) ='RPCPort' then RPCPort:=StrToIntDef(Parameter(linea,1),RPCPort);
      if parameter(linea,0) ='RPCPass' then RPCPass:=Parameter(linea,1);
      if parameter(linea,0) ='ShowedOrders' then ShowedOrders:=StrToIntDef(Parameter(linea,1),ShowedOrders);
      if parameter(linea,0) ='MaxPeers' then MaxPeersAllow:=StrToIntDef(Parameter(linea,1),MaxPeersAllow);
      if parameter(linea,0) ='AutoConnect' then WO_AutoConnect:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='ToTray' then WO_ToTray:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='MinConexToWork' then MinConexToWork:=StrToIntDef(Parameter(linea,1),MinConexToWork);
      if parameter(linea,0) ='PosWarning' then WO_PosWarning:=StrToIntDef(Parameter(linea,1),WO_PosWarning);
      if parameter(linea,0) ='MultiSend' then WO_MultiSend:=StrToBool(Parameter(linea,1));
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

      if parameter(linea,0) ='WO_FullNode' then WO_FullNode:=StrToBool(Parameter(linea,1));

      end;
   Closefile(FileAdvOptions);
   Except on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error loading AdvOpt file');
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

// Creates bots file
Procedure CrearBotData();
Begin
   try
   assignfile(FileBotData,BotDataFilename);
   rewrite(FileBotData);
   closefile(FileBotData);
   SetLength(ListadoBots,0);
   Except on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error creating bot data');
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
   Except on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error loading bot data');
   end;
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
      ListadoBots[Contador].LastRefused:=UTCTimeStr;
      Updated := true;
      end;
   end;
if not updated then
   begin
   SetLength(ListadoBots,Length(ListadoBots)+1);
   ListadoBots[Length(listadoBots)-1].ip:=IPUser;
   ListadoBots[Length(listadoBots)-1].LastRefused:=UTCTimeStr;
   end;
S_BotData := true;
End;

// Save bots to disk
Procedure SaveBotData();
Var
  contador  : integer = 0;
  ErrorCode : integer = 0;
Begin
BeginPerformance('SaveBotData');
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
   AddLineToDebugLog('events',TimeToStr(now)+'Bot file saved: '+inttoStr(length(ListadoBots))+' registers');
   EXCEPT on E:Exception do
         AddLineToDebugLog('events',TimeToStr(now)+'Error saving bots to file :'+E.Message);
   END; {TRY}
   end;
{$I-}closefile(FileBotData);{$I+};
EndPerformance('SaveBotData');
End;


// Saves updates files to disk
Procedure SaveUpdatedFiles();
Begin
if S_BotData then SaveBotData();
if S_Wallet then GuardarWallet();
if ( (S_Sumario) and (BuildingBlock=0) ) then
   begin
   SaveSummaryToDisk();
   S_Sumario := false;
   end;
if S_AdvOpt then CreateADV(true);
End;

// Creates a new wallet
Procedure CrearWallet();
var
  NewAddress : WalletData;
  PubKey,PriKey : string;
Begin
   TRY
   if not fileexists (WalletFilename) then // asegurarse de no borrar una cartera previa
      begin
      assignfile(FileWallet,WalletFilename);
      setlength(ListaDirecciones,1);
      rewrite(FileWallet);
      NewAddress := Default(WalletData);
      NewAddress.Hash:=GenerateNewAddress(PubKey,PriKey);
      NewAddress.PublicKey:=pubkey;
      NewAddress.PrivateKey:=PriKey;
      listadirecciones[0] := NewAddress;
      seek(FileWallet,0);
      write(FileWallet,listadirecciones[0]);
      closefile(FileWallet);
      end;
   EXCEPT on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error creating wallet file');
   END; {TRY}
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
      AddLineToDebugLog('events',TimeToStr(now)+'Error loading wallet from file');
   END;{TRY}
End;

// Save wallet data to disk
Procedure GuardarWallet();
var
  contador : integer = 0;
  previous : int64;
  IOCode   : integer;
Begin
BeginPerformance('GuardarWallet');
Trycopyfile (WalletFilename,WalletFilename+'.bak');
assignfile(FileWallet,WalletFilename);
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
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error saving wallet to disk ('+E.Message+')');
   END; {TRY}
   end;
{$I-}closefile(FileWallet);{$I+}
IOCode := IOResult;
if IOCode>0 then
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Unable to close wallet file, error= '+IOCode.ToString );
EndPerformance('GuardarWallet');
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
      AddLineToDebugLog('events',TimeToStr(now)+'Error creating summary file');
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
      AddLineToDebugLog('console','Can not find '+source+slinebreak+'Loading sumary from default');
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
      AddLineToDebugLog('events',TimeToStr(now)+'Error loading summary from file');
   END;
End;

// Save sumary to disk
Procedure GuardarSumario(SaveCheckmark:boolean = false);
var
  contador     : integer = 0;
  CurrentBlock : integer;
  IOCode       : integer;
Begin
BeginPerformance('GuardarSumario');
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
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error saving summary file: '+e.Message);
   END; {TRY}
   end
else
   begin
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error opening summary: '+IOCode.ToString );
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
   EnterCriticalSection(CSGVTsArray);
   Trycopyfile(GVTsFilename,GVTMarksDirectory+Listasumario[0].LastOP.ToString+'.bak');
   LeaveCriticalSection(CSGVTsArray);
   end;
EndPerformance('GuardarSumario');
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
      if StrToInt64Def(OnlyNumbers,0) > Lastblock then
         LastBlock := StrToInt64Def(OnlyNumbers,0);
      Inc(contador);
      end;
   Result := LastBlock;
   EXCEPT on E:Exception do
      AddLineToDebugLog('events',TimeToStr(now)+'Error getting my last updated block');
   END; {TRY}
BlockFiles.Free;
end;

Function deleteBlockFiles(fromnumber:integer):integer;
Begin

End;

// Updates sumary
Procedure UpdateSumario(Direccion:string;monto:Int64;score:int64;LastOpBlock:string);
var
  contador : integer = 0;
  Yaexiste : boolean = false;
  NuevoRegistro : TSummaryData;
Begin
BeginPerformance('UpdateSumario');
EnterCriticalSection(CSSumary);
for contador := 0 to length(ListaSumario)-1 do
   begin
   if ((ListaSumario[contador].Hash=Direccion) or (ListaSumario[contador].Custom=Direccion)) then
      begin
      NuevoRegistro := Default(TSummaryData);
      NuevoRegistro.Hash:=ListaSumario[contador].Hash;
      NuevoRegistro.Custom:=ListaSumario[contador].Custom;
      NuevoRegistro.Balance:=ListaSumario[contador].Balance+Monto;
      NuevoRegistro.Score:=ListaSumario[contador].Score+score;;
      NuevoRegistro.LastOP:=StrToInt64def(LastOpBlock,0);
      ListaSumario[contador] := NuevoRegistro;
      Yaexiste := true;
      break;
      end;
   end;
if not YaExiste then
   begin
   NuevoRegistro := Default(TSummaryData);
   setlength(ListaSumario,Length(ListaSumario)+1);
   NuevoRegistro.Hash:=Direccion;
   NuevoRegistro.Custom:='';
   NuevoRegistro.Balance:=Monto;
   NuevoRegistro.Score:=0;
   NuevoRegistro.LastOP:=StrToInt64def(LastOpBlock,0);
   ListaSumario[length(listasumario)-1] := NuevoRegistro;
   end;
S_Sumario := true;
LeaveCriticalSection(CSSumary);
EndPerformance('UpdateSumario');
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
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error assigning custom alias to address: '+Address+' -> '+addalias);
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
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error unzipping block file '+filename+': '+E.Message);
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
      AddLineToDebugLog('events',TimeToStr(now)+'Error creating headers file');
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
  ArrayOrders : TBlockOrdersArray;
  cont : integer;
  newblocks : integer = 0;
Begin
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
AddLineToDebugLog('console','Rebuilding until block '+IntToStr(untilblock)); //'Rebuilding until block '
contador := 0;
SetLength(ListaSumario,0);
UpdateSumario(ADMINHash,PremineAmount,0,'0');
while contador <= untilblock do
   begin
   if contador mod 100 = 0 then
      begin
      info('REBUILDING '+Contador.ToString);  //'Rebuilding sumary block: '
      application.ProcessMessages;
      EngineLastUpdate := UTCTime;
      end;
   if ((contador = MyLastBlock) and (contador>0)) then
      LastHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock-1)+'.blk');
   info('Rebuild block: '+IntToStr(contador)); //'Rebuild block: '
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
   if 1=1 {dato.SumHash = ''} then
      begin
      //NewDato := Default(ResumenData);
      //NewDato := Dato;
      Dato.SumHash:=HashMD5File(SumarioFilename);
      seek(FileResumen,contador);
      Write(FileResumen,dato);
      //AddLineToDebugLog('events',TimeToStr(now)+'Readjusted sumhash for block '+inttostr(contador));
      end;
   contador := contador+1;
   LastHash := CurrHash;
   end;
while filesize(FileResumen)> Untilblock+1 do  // cabeceras presenta un numero anomalo de registros
   begin
   seek(FileResumen,Untilblock+1);
   truncate(fileResumen);
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Readjusted headers size');
   end;
closefile(FileResumen);
if newblocks>0 then
   begin
   AddLineToDebugLog('console',IntToStr(newblocks)+' added to headers'); //' added to headers'
   U_DirPanel := true;
   end;
SaveSummaryToDisk();
S_Sumario := false;
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
RebuildingSumary := true;
StartBlock := ListaSumario[0].LastOP+1;
finishblock := Mylastblock;
for counter := StartBlock to finishblock do
   begin
   info('Rebuilding summary block: '+inttoStr(counter));  //'Rebuilding sumary block: '
   application.ProcessMessages;
   EngineLastUpdate := UTCTime;
   AddBlockToSumary(counter, false);
   end;
SaveSummaryToDisk();
S_Sumario := false;
RebuildingSumary := false;
UpdateMyData();
AddLineToDebugLog('console','Sumary completed from '+IntToStr(StartBlock)+' to '+IntToStr(finishblock));
info('Sumary completed');
End;

// Add 1 block transactions to sumary
Procedure AddBlockToSumary(BlockNumber:integer;SaveAndUpdate:boolean = true);
var
  cont : integer;
  BlockHeader : BlockHeaderData;
  ArrayOrders : TBlockOrdersArray;
  ArrayPos    : BlockArraysPos;
  ArrayMNs    : BlockArraysPos;
  PosReward   : int64;
  PosCount    : integer;
  CounterPos  : integer;
  MNsReward   : int64;
  MNsCount    : integer;
  CounterMNs  : integer;
  GVTsTrfer   : integer = 0;
Begin
BlockHeader := Default(BlockHeaderData);
BlockHeader := LoadBlockDataHeader(BlockNumber);
EnterCriticalSection(CSSumary);
UpdateSumario(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,0,IntToStr(BlockNumber));
ArrayOrders := Default(TBlockOrdersArray);
ArrayOrders := GetBlockTrxs(BlockNumber);
for cont := 0 to length(ArrayOrders)-1 do
   begin
   if ArrayOrders[cont].OrderType='CUSTOM' then
      begin
      UpdateSumario(ArrayOrders[cont].sender,Restar(Customizationfee),0,IntToStr(BlockNumber));
      setcustomalias(ArrayOrders[cont].sender,ArrayOrders[cont].Receiver,BlockNumber);
      end;
   if ArrayOrders[cont].OrderType='SNDGVT' then
      begin
      Inc(GVTsTrfer);
      UpdateSumario(ArrayOrders[cont].sender,Restar(Customizationfee),0,IntToStr(BlockNumber));
      ChangeGVTOwner(StrToIntDef(ArrayOrders[cont].Reference,100),ArrayOrders[cont].sender,ArrayOrders[cont].Receiver);
      end;
   if ArrayOrders[cont].OrderType='TRFR' then
      begin
      UpdateSumario(ArrayOrders[cont].sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(BlockNumber));
      UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(BlockNumber));
      end;
   if ArrayOrders[cont].OrderType='PROJCT' then
      begin
      UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(BlockNumber));
      UpdateSumario(BlockHeader.AccountMiner,Restar(ArrayOrders[cont].AmmountTrf),0,IntToStr(BlockNumber));
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
   SaveSummaryToDisk();
   S_Sumario := false;
   {if not RunningDoctor then} UpdateMyData();
   end;
LeaveCriticalSection(CSSumary);
if GVTsTrfer>0 then
   begin
   SaveGVTs;
   UpdateMyGVTsList;
   end;
End;

// Rebuilds totally sumary
Procedure RebuildSumario(UntilBlock:integer);
var
  contador, cont : integer;
  BlockHeader : BlockHeaderData;
  ArrayOrders : TBlockOrdersArray;
  ArrayPos    : BlockArraysPos;
  PosReward   : int64;
  PosCount    : integer;
  CounterPos  : integer;
  ArrayMNs    : BlockArraysPos;
  MNsReward   : int64;
  MNsCount    : integer;
  CounterMNs  : integer;
  GVTsTrfer   : integer = 0;
Begin
EnterCriticalSection(CSSumary);
RebuildingSumary := true;
SetLength(ListaSumario,0);
// incluir el pago del bloque genesys
UpdateSumario(ADMINHash,PremineAmount,0,'0');
for contador := 1 to UntilBlock do
   begin
   if contador mod 10 = 0 then
      begin
      info('Rebuilding summary block: '+inttoStr(contador));  //'Rebuilding sumary block: '
      EngineLastUpdate := UTCTime;
      application.ProcessMessages;
      end;
   BlockHeader := Default(BlockHeaderData);
   BlockHeader := LoadBlockDataHeader(contador);
   UpdateSumario(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,0,IntToStr(contador));
   ArrayOrders := Default(TBlockOrdersArray);
   ArrayOrders := GetBlockTrxs(contador);
   for cont := 0 to length(ArrayOrders)-1 do
      begin
      if ArrayOrders[cont].OrderType='CUSTOM' then
         begin
         UpdateSumario(ArrayOrders[cont].sender,Restar(Customizationfee),0,IntToStr(contador));
         setcustomalias(ArrayOrders[cont].sender,ArrayOrders[cont].Receiver,contador);
         end;
      if ArrayOrders[cont].OrderType='SNDGVT' then
         begin
         Inc(GVTsTrfer);
         UpdateSumario(ArrayOrders[cont].sender,Restar(Customizationfee),0,IntToStr(contador));
         ChangeGVTOwner(StrToIntDef(ArrayOrders[cont].Reference,100),ArrayOrders[cont].sender,ArrayOrders[cont].Receiver);
         end;
      if ArrayOrders[cont].OrderType='TRFR' then
         begin
         UpdateSumario(ArrayOrders[cont].sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(contador));
         UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(contador));
         end;
      if ArrayOrders[cont].OrderType='PROJCT' then
         begin
         UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(contador));
         UpdateSumario(BlockHeader.AccountMiner,Restar(ArrayOrders[cont].AmmountTrf),0,IntToStr(contador));
         end;
      end;
   setlength(ArrayOrders,0);
   if contador >= PoSBlockStart then
      begin
      ArrayPos := GetBlockPoSes(contador);
      PosReward := StrToInt64Def(Arraypos[length(Arraypos)-1].address,0);
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
      SaveSummaryToDisk();
      S_Sumario := false;
      end;
   end;
RebuildingSumary := false;
LeaveCriticalSection(CSSumary);
SaveSummaryToDisk();
S_Sumario := false;
if GVTsTrfer>0 then
   begin
   SaveGVTs;
   UpdateMyGVTsList;
   end;
UpdateMyData();
AddLineToDebugLog('console','Summary rebuilded.');  //'Sumary rebuilded.'
end;

Procedure ReorderSumario();
var
  counter, counter2 : integer;
  NewSumario : Array of TSummaryData;
  ThisRecord : TSummaryData;
  Added : Boolean;
Begin
BeginPerformance('ReorderSumario');
SetLEngth(NewSumario,0);
For counter := 0 to high(ListaSumario) do
   begin
   ThisRecord := Listasumario[counter];
   if length(NewSumario) = 0 then Insert(ThisRecord,NewSumario,0)
   else
      begin
      Added := false;
      for counter2 := 0 to high(NewSumario) do
         begin
         if ThisRecord.Hash < NewSumario[counter2].Hash then
            begin
            Insert(ThisRecord,NewSumario,counter2);
            Added := true;
            Break;
            end;
         end;
      if not Added then Insert(ThisRecord,NewSumario,length(NewSumario));
      end;
   end;
SetLEngth(ListaSumario,0);
ListaSumario := Copy(NewSumario,0,length(NewSumario));
AddLineToDebugLog('console',EndPerformance('ReorderSumario').ToString+' ms');
End;

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
   AddLineToDebugLog('events',TimeToStr(now)+'Error adding new register to headers');
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
      AddLineToDebugLog('events',TimeToStr(now)+'Error deleting last record from headers');
      result := false;
      end;
   END;{TRY}
LeaveCriticalSection(CSHeadAccess);
End;

Function GetHeadersSize():integer;
Begin
result := -1;
EnterCriticalSection(CSHeadAccess);
assignfile(FileResumen,ResumenFilename);
   TRY
   reset(FileResumen);
   Result := filesize(fileResumen)-1;
   closefile(FileResumen);
   EXCEPT on E:Exception do
      begin
      AddLineToDebugLog('events',TimeToStr(now)+'Error retrieving headers size');
      end;
   END;{TRY}
LeaveCriticalSection(CSHeadAccess);
End;

Function GetHeadersLastBlock():integer;
var
  Dato: ResumenData;
Begin
result := 0;
EnterCriticalSection(CSHeadAccess);
TRY
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Dato := Default(ResumenData);
if filesize(FileResumen)>0 then
   begin
   seek(fileResumen,filesize(FileResumen)-1);
   Read(fileResumen,dato);
   result := Dato.block;
   end;
closefile(FileResumen);
EXCEPT on E:Exception do
   AddLineToDebugLog('events',TimeToStr(now)+'Error reading headers');
END;
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
  AddLineToDebugLog('events',TimeToStr(now)+'Error showing header '+Blocknumber.ToString);
END;
LeaveCriticalSection(CSHeadAccess);
End;

Function LastHeaders(FromBlock:integer):String;
var
  Dato: ResumenData;
Begin
result := '';
if FromBlock<MyLastBlock-1008 then exit;
BeginPerformance('LastHeaders');
EnterCriticalSection(CSHeadAccess);
TRY
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
Dato := Default(ResumenData);
seek(fileResumen,FromBlock-10);
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
EndPerformance('LastHeaders');
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
   if not G_ClosingAPP then AddLineToDebugLog('events',TimeToStr(now)+'Error creating restart file: '+E.Message);
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
  BlockHashErrors : integer = 0;
  SumHashErrors : integer = 0;
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
   EngineLastUpdate := UTCTime;
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
         //form1.MemoDoctor.Lines.Add(format(rs1001,[cont]));
         //form1.MemoDoctor.Lines.Add(Format(rs1002,[HashMD5File(BlockDirectory+IntToStr(cont)+'.blk'),dato.blockhash]));
         Dato.blockhash:=HashMD5File(BlockDirectory+IntToStr(cont)+'.blk');
         Seek(FileResumen,cont);
         write(FileResumen,dato);
         Inc(BlockHashErrors);
         end;
      end;
   if form1.CBSummaryhash.Checked then   // Check summary hash
      begin
      AddBlockToSumary(cont);
      if HashMD5File(SumarioFilename) <> dato.SumHash then
         begin
         //form1.MemoDoctor.Lines.Add(format(rs1001,[cont]));
         //form1.MemoDoctor.Lines.Add(format(rs1004,[HashMD5File(SumarioFilename),dato.SumHash]));
         Dato.SumHash:=HashMD5File(SumarioFilename);
         Seek(FileResumen,cont);
         write(FileResumen,dato);
         Inc(SumHashErrors);
         end;
      end;
   if stopdoctor then break;
   end;
RunningDoctor := false;
if ((form1.CBBlockhash.Checked) or (form1.CBSummaryhash.Checked)) then
   CloseFile(FileResumen);
form1.ButStartDoctor.Visible:=true;
form1.ButStopDoctor.Visible:=false;
form1.MemoDoctor.Lines.Add(format('BlockHash errors: %d',[BlockHashErrors]));
form1.MemoDoctor.Lines.Add(format('SumHash errors  : %d',[SumHashErrors]));
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
CloseAllforms();
CerrarClientes();
StopServer();
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
   EngineLastUpdate := UTCTime;
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
      AddLineToDebugLog('events',TimeToStr(now)+'Error creating restart file');
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
  else if WindowsVersion = wvNT4 then result := 'Windows NTv.4'
  else if WindowsVersion = wv98 then result := 'Windows 98'
  else if WindowsVersion = wvMe then result := 'Windows ME'
  else if WindowsVersion = wv2000 then result := 'Windows 2000'
  else if WindowsVersion = wvXP then result := 'Windows XP'
  else if WindowsVersion = wvServer2003 then result := 'Windows Server 2003 / Windows XP 64'
  else if WindowsVersion = wvVista then result := 'Windows Vista'
  else if WindowsVersion = wv7 then result := 'Windows 7'
  else if WindowsVersion = wv10 then result := 'Windows 10'
  else result := 'WindowsUnknown';
{$IFDEF WIN32}
result := Result+' / 32 Bits';
{$ENDIF}
{$IFDEF WIN64}
result := Result+' / 64 Bits';
{$ENDIF}
End;
{$ENDIF}

// Executes the required steps to restore the blockchain
Procedure RestoreBlockChain();
Begin
CloseAllforms();
CerrarClientes();
StopServer();
//setlength(CriptoOpsTIPO,0);
deletefile(SumarioFilename);
deletefile(SumarioFilename+'.bak');
deletefile(ResumenFilename);
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
LoadSummaryFromDisk(MarksDirectory+StartMark.ToString+'.bak');
AddLineToDebugLog('console','Restoring sumary from '+StartMark.ToString);
CompleteSumary;
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
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error deleting file ('+filename+') :'+E.Message);
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
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error copying file ('+Source+') :'+E.Message);
      end;
   END; {TRY}
End;

// Returns the name of the app file without path
function AppFileName():string;
Begin
result := ExtractFileName(ParamStr(0));
// For wornking path: ExtractFilePAth
End;


END. // END UNIT

