unit mpdisk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, Dialogs, Forms, nosotime, FileUtil, LCLType,
  lclintf, controls, mpBlock, Zipper, mpcoin, mpMn, nosodebug,
  translation, strutils,nosogeneral, nosocrypto, nosounit, nosoconsensus, nosopsos,
  nosowallcon, nosoheaders, nosonosocfg, nosoblock,nosonetwork,nosomasternodes,nosogvts;

Function FileStructure():integer;
Procedure VerifyFiles();

// *** New files system
// Nodes file
//Procedure FillNodeList();
Function IsSeedNode(IP:String):boolean;

// GVTs file handling
//Procedure CreateGVTsFile();
//Procedure GetGVTsFileData();
//Procedure SaveGVTs();
//Function ChangeGVTOwner(Lnumber:integer;OldOwner,NewOWner:String): integer;
//Function CountAvailableGVTs():Integer;
//Function GetGVTPrice(available:integer;ToSell:boolean = false):int64;


Procedure CreateMasterNodesFile();
Procedure CreateADV(saving:boolean);
Procedure LoadADV();
Function GetLanguage():string;
Procedure ExtractPoFiles();
Procedure CreateFileFromResource(resourcename,filename:string);


//Procedure UpdateBotData(IPUser:String);

// sumary
Procedure UpdateWalletFromSumario();
Procedure RebuildSummary();
Procedure AddBlockToSumary(BlockNumber:integer;SaveAndUpdate:boolean = true);
Procedure CompleteSumary();

Procedure SaveUpdatedFiles();

//function GetMyLastUpdatedBlock():int64;
Function CreateProperlyClosedAppFile(filename:String):Boolean;

//Function UnzipBlockFile(filename:String;delFile:boolean):boolean;
function UnZipUpdateFromRepo(Tver,TArch:String):boolean;

Procedure CreateLauncherFile(IncludeUpdate:boolean = false);
Procedure RestartNoso();
Procedure CrearRestartfile();
Procedure RestartConditions();
Procedure RestoreBlockChain();
Procedure RestoreSumary(fromBlock:integer=0);
function AppFileName():string;

implementation

Uses
  mpParser, mpGUI, mpRed, mpProtocol;

// Builds the file structure
Function FileStructure():integer;
Begin
  Result := 0;
  if not directoryexists('NOSODATA') then
    if not CreateDir('NOSODATA') then Inc(Result);
  if not directoryexists(LogsDirectory) then
    if not CreateDir(LogsDirectory) then Inc(Result);
  if not directoryexists(BlockDirectory) then
    if not CreateDir(BlockDirectory) then Inc(Result);
  if not directoryexists(UpdatesDirectory) then
    if not CreateDir(UpdatesDirectory) then Inc(Result);
  if not directoryexists(MarksDirectory) then
    if not CreateDir(MarksDirectory) then Inc(Result);
  if not directoryexists(GVTMarksDirectory) then
    if not CreateDir(GVTMarksDirectory) then Inc(Result);
  if not directoryexists(RPCBakDirectory) then
    if not CreateDir(RPCBakDirectory) then Inc(Result);
  if not directoryexists(BlockDirectory+DBDirectory) then
    if not CreateDir(BlockDirectory+DBDirectory) then Inc(Result);
End;

// Complete file verification
Procedure VerifyFiles();
var
  defseeds : string = '';

Begin
  SetHeadersFileName('NOSODATA'+DirectorySeparator+'blchhead.nos');

  if not FileExists (AdvOptionsFilename) then CreateADV(false) else LoadADV();
  OutText('✓ Advanced options loaded',false,1);

  SetMasternodesFilename('NOSODATA'+DirectorySeparator+'masternodes.txt');
  //if not FileExists(MasterNodesFilename) then CreateMasterNodesFile;
  LoadMNsFile;
  OutText('✓ Masternodes file ok',false,1);

if not FileExists(GVTsFilename) then CreateGVTsFile;
GetGVTsFileData;
OutText('✓ GVTs file ok',false,1);

if not FileExists(CFGFilename) then
  begin
  SaveCFGToFile(DefaultNosoCFG);
  GetCFGFromFile;
  Defseeds := GetRepoFile('https://raw.githubusercontent.com/Noso-Project/NosoWallet/main/defseeds.nos');
  if DefSeeds = '' then Defseeds := GetRepoFile('https://api.nosocoin.com/nodes/seed');
  if defseeds <> '' then
    begin
    SetCFGData(Defseeds,1);
    Tolog('console','Defaults seeds downloaded from trustable source');
    end
  else ToLog('console','Unable to download default seeds. Please, use a fallback');
  end;
GetCFGFromFile;
OutText('✓ NosoCFG file ok',false,1);

if not FileExists (WalletFilename) then
  begin
  CreateNewWallet;
  S_AdvOpt := true;
  end
else LoadWallet(WalletFilename);
OutText('✓ Wallet file ok',false,1);

FillNodeList;  // Fills the hardcoded seed nodes list

if not Fileexists(SummaryFileName) then CreateNewSummaryFile(FileExists(BlockDirectory+'0.blk'));
CreateSumaryIndex();
OutText('✓ Sumary file ok',false,1);
if not Fileexists(ResumenFilename) then CreateHeadersFile();
OutText('✓ Headers file ok',false,1);

if not FileExists(BlockDirectory+DBDirectory+DataBaseFilename) then CreateDBFile;
OutText('✓ Database file ok.',false,1);
if WO_BlockDB then
  begin
  OutText('✓ Loading blocks Database.',false,1);
  CreateOrderIDIndex;
  end;
if not FileExists(BlockDirectory+'0.blk') then CrearBloqueCero();
MyLastBlock := GetMyLastUpdatedBlock;
OutText('✓ My last block verified: '+MyLastBlock.ToString,false,1);

UpdateWalletFromSumario();
OutText('✓ Wallet updated',false,1);
ImportAddressesFromBackup(RPCBakDirectory);

LoadPSOFileFromDisk;
End;

// ***********************
// *** NEW FILE SYSTEM *** (0.2.0N and higher)
// ***********************

// *** NODE FILE ***

{
// Fills hardcoded seed nodes list
Procedure FillNodeList(); // 0.2.1Lb2 revisited
var
  counter : integer;
  ThisNode : string = '';
  Thisport  : integer;
  continuar : boolean = true;
  NodeToAdd : TNodeData;
  SourceStr : String = '';
Begin
counter := 0;
SourceStr := Parameter(GetCFGDataStr,1)+GetVerificatorsText;
//ToLog('console',sourcestr);
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
}

// If the specified IP a seed node
Function IsSeedNode(IP:String):boolean;
Begin
  Result := false;
  if AnsiContainsStr(GetCFGDataStr(1),ip) then result := true;
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
  ToLog('events',TimeToStr(now)+'Error creating the masternodes file');
END;
End;

// *** OPTIONS FILE ***
// *****************************************************************************
{$REGION OPTIONS}

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
   writeln(FileAdvOptions,'//Hide empty addresses');
   writeln(FileAdvOptions,'HideEmpty '+BoolToStr(WO_HideEmpty,true));
   writeln(FileAdvOptions,'//Use all addresses to send funds');
   writeln(FileAdvOptions,'MultiSend '+BoolToStr(WO_MultiSend,true));
   writeln(FileAdvOptions,'//Po files language code');
   writeln(FileAdvOptions,'Language '+(WO_Language));
   writeln(FileAdvOptions,'//No GUI refresh');
   writeln(FileAdvOptions,'NoGUI '+BoolToStr(WO_StopGUI,true));
   writeln(FileAdvOptions,'//Po files last update');
   writeln(FileAdvOptions,'PoUpdate '+(WO_LastPoUpdate));
   writeln(FileAdvOptions,'//Close the launch form automatically');
   writeln(FileAdvOptions,'Closestart '+BoolToStr(WO_CloseStart,true));
   writeln(FileAdvOptions,'//Send anonymous report to developers');
   writeln(FileAdvOptions,'SendReport '+BoolToStr(WO_SendReport,true));
   writeln(FileAdvOptions,'//Keep a blocks database');
   writeln(FileAdvOptions,'BlocksDB '+BoolToStr(WO_BlockDB,true));

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
   writeln(FileAdvOptions,'MNIP '+(LocalMN_IP));
   writeln(FileAdvOptions,'//Masternode port');
   writeln(FileAdvOptions,'MNPort '+(LocalMN_Port));
   writeln(FileAdvOptions,'//Masternode funds address');
   writeln(FileAdvOptions,'MNFunds '+(LocalMN_Funds));
   if LocalMN_Sign = '' then LocalMN_Sign := GetWallArrIndex(0).Hash;
   writeln(FileAdvOptions,'//Masternode sign address');
   writeln(FileAdvOptions,'MNSign '+LocalMN_Sign);
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
   writeln(FileAdvOptions,'//Save addresses keys created on a BAK folder');
   writeln(FileAdvOptions,'RPCSaveNew '+BoolToStr(RPCSaveNew,true));
   writeln(FileAdvOptions,'//Banned methods for RPC requests');
   writeln(FileAdvOptions,'RPCBanned '+RPCBanned);
   writeln(FileAdvOptions,'');

   writeln(FileAdvOptions,'---Deprecated. To be removed.---');
   writeln(FileAdvOptions,'MaxPeers '+IntToStr(MaxPeersAllow));
   writeln(FileAdvOptions,'PosWarning '+IntToStr(WO_PosWarning));

   Closefile(FileAdvOptions);
   if saving then ToLog('events',TimeToStr(now)+'Options file saved');
   S_AdvOpt := false;
   Except on E:Exception do
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error creating/saving AdvOpt file: '+E.Message);
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
      if parameter(linea,0) ='RPCPort' then RPCPort:=StrToIntDef(Parameter(linea,1),RPCPort);
      if parameter(linea,0) ='RPCPass' then RPCPass:=Parameter(linea,1);
      if parameter(linea,0) ='MaxPeers' then MaxPeersAllow:=StrToIntDef(Parameter(linea,1),MaxPeersAllow);
      if parameter(linea,0) ='PosWarning' then WO_PosWarning:=StrToIntDef(Parameter(linea,1),WO_PosWarning);
      if parameter(linea,0) ='SendReport' then WO_SendReport:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='BlocksDB' then WO_BlockDB:=StrToBool(Parameter(linea,1));

      if parameter(linea,0) ='MultiSend' then WO_MultiSend:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='HideEmpty' then WO_HideEmpty:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='RPCFilter' then RPCFilter:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='RPCWhiteList' then RPCWhiteList:=Parameter(linea,1);
      if parameter(linea,0) ='RPCBanned' then RPCBanned:=Parameter(linea,1);
      if parameter(linea,0) ='RPCAuto' then RPCAuto:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='RPCSaveNew' then RPCSaveNew:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='Language' then WO_Language:=Parameter(linea,1);
      if parameter(linea,0) ='Autoserver' then WO_AutoServer:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='PoUpdate' then WO_LastPoUpdate:=Parameter(linea,1);
      if parameter(linea,0) ='Closestart' then WO_CloseStart:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='Autoupdate' then WO_AutoUpdate:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='NoGUI' then WO_StopGUI:=StrToBool(Parameter(linea,1));
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

      if parameter(linea,0) ='MNIP' then LocalMN_IP:=Parameter(linea,1);
      if parameter(linea,0) ='MNPort' then LocalMN_Port:=Parameter(linea,1);
      if parameter(linea,0) ='MNFunds' then LocalMN_Funds:=Parameter(linea,1);
      if parameter(linea,0) ='MNSign' then LocalMN_Sign:=Parameter(linea,1);
      if parameter(linea,0) ='MNAutoIp' then MN_AutoIP:=StrToBool(Parameter(linea,1));
      if parameter(linea,0) ='WO_FullNode' then WO_FullNode:=StrToBool(Parameter(linea,1));

      end;
   Closefile(FileAdvOptions);
   Except on E:Exception do
      ToLog('events',TimeToStr(now)+'Error loading AdvOpt file');
   end;
End;

{$ENDREGION Options File}


// *** LANGUAGE HANDLING ***
// *****************************************************************************
{$REGION LANGUAGE}
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

{$ENDREGION}

// *** BOTS FILE ***
// *****************************************************************************
{$REGION BOTS FILE}
{
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
End;
}
{$ENDREGION}

// Saves updates files to disk
Procedure SaveUpdatedFiles();
Begin
if S_Wallet then
  begin
  SaveWalletToFile();
  S_Wallet := false;
  end;
if S_AdvOpt then CreateADV(true);
End;

// Updates wallet addresses balance from sumary
Procedure UpdateWalletFromSumario();
var
  Contador, counter : integer;
  ThisExists : boolean = false;
  SumPos : int64;
  ThisRecord : TSummaryData;
  ThisData   : WalletData;
Begin
exit;
for contador := 0 to LenWallArr-1 do
   begin
   ThisData := GetWallArrIndex(contador);
   SumPos := GetIndexPosition(ThisData.Hash,thisRecord);
   ThisData.Balance := thisRecord.Balance;
   ThisData.LastOP  := thisRecord.LastOP;
   ThisData.score   := thisRecord.score;
   ThisData.Custom  := thisRecord.Custom;
   end;
S_Wallet := true;
U_Dirpanel := true;
End;

Procedure RebuildSummary();
var
  counter      : integer;
  TimeDuration : int64;
Begin
CreateNewSummaryFile(FileExists(BlockDirectory+'0.blk'));
for counter := 1 to MylastBlock do
   begin
   AddBlockToSumary(counter,false);
   if counter mod 100 = 0 then
      begin
      info('Rebuilding summary block: '+inttoStr(counter));
      application.ProcessMessages;
      UpdateSummaryChanges;
      ResetBlockRecords;
      end;
   end;
UpdateSummaryChanges;
UpdateMyData();
CreateSumaryIndex;
TimeDuration := EndPerformance('RebuildSummary');
ToLog('console',format('Sumary rebuild time: %d ms',[TimeDuration]));
End;

{
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
      ToLog('events',TimeToStr(now)+'Error getting my last updated block');
   END; {TRY}
BlockFiles.Free;
end;
}

Function CreateProperlyClosedAppFile(filename:String):Boolean;
var
  MyStream : TMemoryStream;
Begin
  Result := True;
  MyStream := TMemoryStream.Create;
  TRY
    MYStream.SaveToFile(filename);
  EXCEPT ON E:EXCEPTION DO
    begin
    Result := false;
    ToDeepDeb('MpDisk,CreateProperlyClosedAppFile,'+E.Message);
    end;
  END;
  MyStream.Free;
End;

Function deleteBlockFiles(fromnumber:integer):integer;
Begin

End;

// Unzip a zip file and (optional) delete it
{
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
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error unzipping block file '+filename+': '+E.Message);
      end;
   END; {TRY}
if delfile then Trydeletefile(filename);
UnZipper.Free;
End;
}
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
UnZipper.Free;
End;

// COmpletes the sumary from LAstUpdate to Lastblock
Procedure CompleteSumary();
var
  StartBlock, finishblock : integer;
  counter : integer;
Begin
if copy(MySumarioHash,0,5) = GetConsensus(17) then exit;
RebuildingSumary := true;
StartBlock := SummaryLastop+1;
finishblock := Mylastblock;
ToLog('console','Complete summary');
for counter := StartBlock to finishblock do
   begin
   AddBlockToSumary(counter, true);
   if counter mod 1 = 0 then
      begin
      info('Rebuilding summary block: '+inttoStr(counter));  //'Rebuilding sumary block: '
      application.ProcessMessages;
      EngineLastUpdate := UTCTime;
      end;
   end;
SummaryLastop := finishblock;
RebuildingSumary := false;
UpdateMyData();
ZipSumary;
ToLog('console',format('Summary completed from %d to %d (%s)',[StartBlock-1,finishblock,Copy(MySumarioHash,0,5)]));
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
  PosReward   : int64 = 0;
  PosCount    : integer = 0;
  CounterPos  : integer;
  MNsReward   : int64;
  MNsCount    : integer;
  CounterMNs  : integer;
  GVTsTrfer   : integer = 0;
Begin
BlockHeader := Default(BlockHeaderData);
BlockHeader := LoadBlockDataHeader(BlockNumber);
if SaveAndUpdate then ResetBlockRecords;
CreditTo(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,BlockNumber);
ArrayOrders := Default(TBlockOrdersArray);
ArrayOrders := GetBlockTrxs(BlockNumber);
for cont := 0 to length(ArrayOrders)-1 do
   begin
   if ArrayOrders[cont].OrderType='CUSTOM' then
      begin
      IsCustomizacionValid(ArrayOrders[cont].sender,ArrayOrders[cont].Receiver,BlockNumber,true);
      end;
   if ArrayOrders[cont].OrderType='SNDGVT' then
      begin
      Inc(GVTsTrfer);
      SummaryPay(ArrayOrders[cont].sender,Customizationfee,BlockNumber);
      ChangeGVTOwner(StrToIntDef(ArrayOrders[cont].Reference,100),ArrayOrders[cont].sender,ArrayOrders[cont].Receiver);
      end;
   if ArrayOrders[cont].OrderType='TRFR' then
      begin
      if SummaryValidPay(ArrayOrders[cont].sender,ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf,blocknumber) then
         CreditTo(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,BlockNumber)
      else SummaryPay(BlockHeader.AccountMiner,ArrayOrders[cont].AmmountFee,blocknumber)
      end;
   if ArrayOrders[cont].OrderType='PROJCT' then
      begin
      CreditTo('NpryectdevepmentfundsGE',ArrayOrders[cont].AmmountTrf,BlockNumber);
      SummaryPay(BlockHeader.AccountMiner,ArrayOrders[cont].AmmountTrf,blocknumber);
      end;
   end;
setlength(ArrayOrders,0);
if ((blocknumber >= PoSBlockStart) and (blocknumber<=PoSBlockEnd)) then
   begin
   ArrayPos := GetBlockPoSes(BlockNumber);
   PosReward := StrToIntDef(Arraypos[length(Arraypos)-1].address,0);
   SetLength(ArrayPos,length(ArrayPos)-1);
   PosCount := length(ArrayPos);
   for counterpos := 0 to PosCount-1 do
      CreditTo(ArrayPos[counterPos].address,Posreward,BlockNumber);
   SummaryPay(BlockHeader.AccountMiner,PosCount*Posreward,blocknumber);
   SetLength(ArrayPos,0);
   end;

if blocknumber >= MNBlockStart then
   begin
   ArrayMNs := GetBlockMNs(BlockNumber);
   MNsReward := StrToIntDef(ArrayMNs[length(ArrayMNs)-1].address,0);
   SetLength(ArrayMNs,length(ArrayMNs)-1);
   MNsCount := length(ArrayMNs);
   for counterMNs := 0 to MNsCount-1 do
      CreditTo(ArrayMNs[counterMNs].address,MNsreward,BlockNumber);
   SummaryPay(BlockHeader.AccountMiner,MNsCount*MNsreward,BlockNumber);
   SetLength(ArrayMNs,0);
   end;
CreditTo(AdminHash,0,BlockNumber);
if SaveAndUpdate then UpdateSummaryChanges;
if BlockNumber mod 1000 = 0 then TryCopyFile(SummaryFileName,MarksDirectory+BlockNumber.tostring+'.bak');
if GVTsTrfer>0 then
   begin
   SaveGVTs;
   UpdateMyGVTsList;
   end;
U_DirPanel := true;
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
   if not G_ClosingAPP then ToLog('events',TimeToStr(now)+'Error creating restart file: '+E.Message);
END{Try};
Closefile(archivo);
End;

// Prepares for restart
Procedure RestartNoso();
Begin
CreateLauncherFile();
RunExternalProgram(RestartFilename);
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
      ToLog('events',TimeToStr(now)+'Error creating restart file');
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
if server then ProcessLinesAdd('SERVERON');
if connect then ProcessLinesAdd('CONNECT');
tryDeletefile('restart.txt');
End;



// Executes the required steps to restore the blockchain
Procedure RestoreBlockChain();
Begin
CloseAllforms();
CerrarClientes();
StopServer();
//setlength(CriptoOpsTIPO,0);
deletefile(SummaryFileName);
deletefile(SummaryFileName+'.bak');
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
//LoadSummaryFromDisk(MarksDirectory+StartMark.ToString+'.bak');
ToLog('console','Restoring sumary from '+StartMark.ToString);
CompleteSumary;
End;

// Returns the name of the app file without path
function AppFileName():string;
Begin
  result := ExtractFileName(ParamStr(0));
  // For working path: ExtractFilePAth
End;


END. // END UNIT

