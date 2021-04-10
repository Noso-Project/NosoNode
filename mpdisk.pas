unit mpdisk;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, Dialogs, Forms, mpTime, FileUtil, LCLType,
  lclintf, controls, mpCripto, mpBlock, Zipper, mpLang, mpcoin, poolmanage,
  {$IFDEF WINDOWS}Win32Proc, {$ENDIF}
  mpminer;

Procedure VerificarArchivos();
Procedure CreateLog();
Procedure CreateADV(saving:boolean);
Procedure LoadADV();
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
Procedure CrearNodeData();
Procedure CargarNodeData();
Procedure UpdateNodeData(IPUser:String;Port:string;LastTime:String='');
Procedure FillNodeList();
Procedure SaveNodeData();
Procedure DepurarNodos();
Procedure CrearNTPData();
Procedure CargarNTPData();
Procedure SaveUpdatedFiles();
Procedure CrearWallet();
Procedure CargarWallet(wallet:String);
Procedure GuardarWallet();
Procedure UpdateWalletFromSumario();
Procedure CreateSumario();
Procedure CargarSumario();
Procedure GuardarSumario();
function GetMyLastUpdatedBlock():int64;
Procedure UpdateSumario(Direccion:string;monto:Int64;score:integer;LastOpBlock:string);
function SetCustomAlias(Address,Addalias:String):Boolean;
procedure UnzipBlockFile(filename:String;delfile:boolean);
Procedure CreateResumen();
Procedure BuildHeaderFile(untilblock:integer);
Procedure AddBlockToSumary(BlockNumber:integer);
Procedure RebuildSumario(UntilBlock:integer);
Procedure AddBlchHead(Numero: int64; hash,sumhash:string);
Procedure DelBlChHeadLast();
Procedure CrearMistrx();
Procedure CargarMisTrx();
Procedure SaveMyTrxsLastUpdatedblock(Number:integer);
Procedure RebuildMyTrx(blocknumber:integer);
Procedure SaveMyTrxsToDisk(Cantidad:integer);
function NewMyTrx(aParam:Pointer):PtrInt;
Procedure CrearBatFileForRestart();
Procedure RestartNoso();
Procedure RunDiagnostico(linea:string);
Procedure CrearArchivoPoolInfo(nombre,direccion:string;porcentaje,miembros,port,tipo:integer;pass:string);
Procedure GuardarArchivoPoolInfo();
function GetPoolInfoFromDisk():PoolInfoData;
Procedure LoadPoolMembers();
Procedure CrearArchivoPoolMembers;
Procedure GuardarPoolMembers();
Procedure EjecutarAutoUpdate(version:string);
Procedure CrearRestartfile();
Procedure RestartConditions();
Procedure CrearCrashInfo();
function OSVersion: string;
{$IFDEF WINDOWS} Function GetWinVer():string; {$ENDIF}
Procedure RestoreBlockChain();
Procedure InitCrossValues();

implementation

Uses
  mpParser, mpGUI, mpRed;

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
if not FileExists (AdvOptionsFilename) then CreateADV(false) else LoadADV();
UpdateRowHeigth();
OutText('✓ Advanced options loaded',false,1);
if not FileExists (ErrorLogFilename) then Createlog;
OutText('✓ Log file ok',false,1);

if not FileExists (UserOptions.wallet) then CrearWallet() else CargarWallet(UserOptions.wallet);
OutText('✓ Wallet file ok',false,1);
if not Fileexists(BotDataFilename) then CrearBotData() else CargarBotData();
OutText('✓ Bots file ok',false,1);
if not Fileexists(NodeDataFilename) then CrearNodeData() else CargarNodeData();
OutText('✓ Nodes file ok',false,1);
if not Fileexists(NTPDataFilename) then CrearNTPData() else CargarNTPData();
OutText('✓ NTP servers file ok',false,1);
if not Fileexists(SumarioFilename) then CreateSumario() else CargarSumario();
OutText('✓ Sumary file ok',false,1);
if not Fileexists(ResumenFilename) then CreateResumen();
OutText('✓ Headers file ok',false,1);
if not FileExists(BlockDirectory+'0.blk') then CrearBloqueCero();
if not FileExists(MyTrxFilename) then CrearMistrx() else CargarMisTrx();
OutText('✓ My transactions file ok',false,1);
if fileexists(PoolInfoFilename) then
   begin
   GetPoolInfoFromDisk();
   SetLength(PoolServerConex,PoolInfo.MaxMembers);
   for contador := 0 to length(PoolServerConex)-1 do
      PoolServerConex[contador] := Default(PoolUserConnection);
   consolelines.Add('PoolMaxMembers:'+inttostr(length(PoolServerConex)));
   Miner_OwnsAPool := true;
   LoadPoolMembers();
   ResetPoolMiningInfo();
   PoolMembersTotalDeuda := GetTotalPoolDeuda();
   end;
if UserOptions.PoolInfo<> '' then
   begin
   LoadMyPoolData;
   end;
OutText('✓ Pool info verified',false,1);
MyLastBlock := GetMyLastUpdatedBlock;
BuildHeaderFile(MyLastBlock); // PROBABLY IT IS NOT NECESARY

UpdateWalletFromSumario();
OutText('✓ Wallet updated',false,1);
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

// Creates/Saves Advopt file
Procedure CreateADV(saving:boolean);
Begin
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
   Closefile(FileAdvOptions);
   if saving then consolelines.Add('Advanced Options file saved');
   Except on E:Exception do
      tolog ('Error creating AdvOpt file');
   end;
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
      end;
   Closefile(FileAdvOptions);
   Except on E:Exception do
      tolog ('Error creating AdvOpt file');
   end;
End;

// Add log line
Procedure ToLog(Texto:string);
Begin
LogLines.Add(texto);
S_Log := true;
End;

// Save log files to disk
Procedure SaveLog();
var
  archivo : textfile;
Begin
try
   Assignfile(archivo, ErrorLogFilename);
   Append(archivo);
   while LogLines.Count>0 do
      begin
      Writeln(archivo, timetostr(now)+' '+LogLines[0]);
      LogMemo.Lines.Add(timetostr(now)+' '+LogLines[0]);
      if not formlog.Visible then NewLogLines := NewLogLines+1;
      LogLines.Delete(0);
      end;
   Closefile(archivo);
   S_Log := false;
Except on E:Exception do
   tolog ('Error saving to the log file');
end;

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
   DefOptions.AutoConnect:=false;
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
   try
   assignfile(FileOptions,OptionsFileName);
   reset(FileOptions);
   read(FileOptions,UserOptions);
   closefile(FileOptions);
   OutText('✓ Options file loaded',false,1);
   Except on E:Exception do
      tolog ('Error loading user options');
   end;
End;

// Save Options to disk
Procedure GuardarOpciones();
Begin
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
End;

// Creates the default language file
Procedure CrearIdiomaFile();
Begin
   try
   CrearArchivoLang();
   CargarIdioma(0);
   ConsoleLines.Add(LangLine(18));
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
         BNewAddr.Hint:=LAngLine(64);BCopyAddr.Hint:=LAngLine(65);BSendCoins.Hint:=LangLine(66);
         LSCTop.Caption:=LangLine(66);SBSCPaste.hint:=LangLine(67);SBSCMax.hint:=LangLine(68);
         SCBitClea.Caption:=LangLine(69);SCBitSend.Caption:=LangLine(70);SCBitCancel.Caption:=LangLine(71);
         SCBitConf.Caption:=LangLine(72);BitInfoTrx.hint:=LangLine(73);
         end;
      UserOptions.language:=numero;
      S_Options := true;
      if G_Launching then OutText('✓ Language file loaded',false,1);
      end
   else // si el archivo no existe
      begin
      ConsoleLines.Add('noso.lng not found');
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
Begin
for contador := 0 to length(ListadoBots)-1 do
   begin
   if ListadoBots[Contador].ip = IPUser then
      begin
      ListadoBots[Contador].LastRefused:=UTCTime;
      S_BotData := true;
      Exit;
      end;
   end;
SetLength(ListadoBots,Length(ListadoBots)+1);
ListadoBots[Length(listadoBots)-1].ip:=IPUser;
ListadoBots[Length(listadoBots)-1].LastRefused:=UTCTime;
S_BotData := true;
End;

// Save bots to disk
Procedure SaveBotData();
Var
  contador : integer = 0;
Begin
   try
   assignfile (FileBotData,BotDataFilename);
   contador := 0;
   reset (FileBotData);
   for contador := 0 to length(ListadoBots)-1 do
      begin
      seek (FileBotData, contador);
      write (FileBotData, ListadoBots[contador]);
      end;
   closefile(FileBotData);
   S_BotData := false;
   Except on E:Exception do
         tolog ('Error saving bots to file');
   end;
End;

// Creates node file
Procedure CrearNodeData();
var
  nodoinicial : nodedata;
  continuar : boolean = true;
  contador : integer = 1;
  NodoStr : String;
Begin
   try
   assignfile(FileNodeData,NodeDataFilename);
   rewrite(FileNodeData);
   Repeat
     begin
     NodoStr := Parameter(DefaultNodes,contador);
     if NodoStr = '' then continuar := false
     else
        begin
        NodoInicial.ip:=NodoStr;
        NodoInicial.port:='8080';
        NodoInicial.LastConexion:=UTCTime;
        write(FileNodeData,nodoinicial);
        contador := contador+1;
        end;
     end;
   until not continuar ;
   closefile(FileNodeData);
   SetLength(ListaNodos,0);
   CargarNodeData();
   Except on E:Exception do
         tolog ('Error creating node file');
   end;
End;

// Load nodes from disk
Procedure CargarNodeData();
Var
  Leido : NodeData;
  contador: integer = 0;
Begin
   try
   assignfile (FileNodeData,NodeDataFilename);
   contador := 0;
   reset (FileNodeData);
   SetLength(ListaNodos,0);
   SetLength(ListaNodos, filesize(FileNodeData));
   while contador < (filesize(FileNodeData)) do
      begin
      seek (FileNodeData, contador);
      read (FileNodeData, Leido);
      ListaNodos[contador] := Leido;
      contador := contador + 1;
      end;
   closefile(FileNodeData);
   //DepurarNodos();
   Except on E:Exception do
         tolog ('Error loading node data');
   end;
End;

// Creates/updates a node
Procedure UpdateNodeData(IPUser:String;Port:string;LastTime:string='');
var
  contador : integer = 0;
Begin
S_NodeData := true;
if LastTime = '' then LastTime := UTCTime;
for contador := 0 to length(ListaNodos)-1 do
   begin
   if (ListaNodos[Contador].ip = IPUser)and (ListaNodos[Contador].port = port) then
      begin
      ListaNodos[Contador].LastConexion:=LastTime;
      S_NodeData := true;
      Exit;
      end;
   end;
SetLength(ListaNodos,Length(ListaNodos)+1);
ListaNodos[Length(ListaNodos)-1].ip:=IPUser;
ListaNodos[Length(ListaNodos)-1].port:=port;
ListaNodos[Length(ListaNodos)-1].LastConexion:=LastTime;
FillNodeList();
S_NodeData := true;
End;

// Fills options node list
Procedure FillNodeList();
var
  cont : integer;
Begin
GridNodes.RowCount:=1;
if Length(ListaNodos)>0 then
   begin
   for cont := 0 to Length(ListaNodos)-1 do
      begin
      GridNodes.RowCount:=GridNodes.RowCount+1;
      GridNodes.Cells[0,GridNodes.RowCount-1] := Listanodos[cont].ip;
      GridNodes.Cells[1,GridNodes.RowCount-1] := Listanodos[cont].port;
      end;
   end;
End;

// Saves nodes to disk
Procedure SaveNodeData();
Var
  contador : integer = 0;
Begin
   try
   assignfile (FileNodeData,NodeDataFilename);
   contador := 0;
   rewrite (FileNodeData);
   for contador := 0 to length(ListaNodos)-1 do
      begin
      seek (FileNodeData, contador);
      write (FileNodeData, ListaNodos[contador]);
      end;
   closefile(FileNodeData);
   S_NodeData := false;
   Except on E:Exception do
      tolog ('Error saving nodes to disk');
   end;
End;

// Debugs old nodes
Procedure DepurarNodos();
var
  contador : integer = 0;
  LimiteTiempo : Int64 = 0;
  NodeDeleted : boolean;
Begin
LimiteTiempo := CadToNum(UTCTime,0,'STI failed UTCTime depurarnodos')-2592000; // Los menores que esto deben ser eliminados(2592000 un mes)
While contador < length(ListaNodos)-1 do
   begin
   NodeDeleted := false;
   if CadToNum(ListaNodos[contador].LastConexion,999999999999,'STI failed lastconexion depurarnodos: '+ListaNodos[contador].LastConexion) < LimiteTiempo then
      Begin
      Delete(ListaNodos,Contador,1);
      contador := contador-1;
      NodeDeleted := true;
      end;
   if not NodeDeleted then contador := contador+1;
   end;
S_NodeData := true;
End;

// Creates NTP servers file
Procedure CrearNTPData();
Var
  contador : integer = 0;
Begin
   try
   assignfile(FileNTPData,NTPDataFilename);
   setlength(ListaNTP,10);
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
   rewrite(FileNTPData);
   for contador := 0 to 9 do
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
   try
   assignfile(FileNTPData,NTPDataFilename);
   reset(FileNTPData);
   setlength(ListaNTP,filesize(FileNTPData));
   for contador := 0 to filesize(FileNTPData)-1 do
      begin
      seek(FileNTPData,contador);
      Read(FileNTPData,ListaNTP[contador]);
      end;
   closefile(FileNTPData);
   Except on E:Exception do
      tolog ('Error loading NTP servers');
   end;
End;

// Saves updates files to disk
Procedure SaveUpdatedFiles();
Begin
if S_BotData then SaveBotData();
if S_NodeData then SaveNodeData();
if S_Options then GuardarOpciones();
if S_Wallet then GuardarWallet();
if S_Sumario then GuardarSumario();
if S_PoolMembers then GuardarPoolMembers();
if S_Log then SaveLog;
if S_PoolInfo then GuardarArchivoPoolInfo;
if S_AdvOpt then CreateADV(false);
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
   try
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
   Except on E:Exception do
      tolog ('Error loading wallet from file');
   end;
End;

// Save wallet data to disk
Procedure GuardarWallet();
var
  contador : integer = 0;
  previous : int64;
Begin
   try
   copyfile (UserOptions.Wallet,UserOptions.Wallet+'.bak');
   assignfile(FileWallet,UserOptions.Wallet);
   reset(FileWallet);
   for contador := 0 to Length(ListaDirecciones)-1 do
      begin
      seek(FileWallet,contador);
      Previous := ListaDirecciones[contador].Pending;
      ListaDirecciones[contador].Pending := 0;
      write(FileWallet,ListaDirecciones[contador]);
      ListaDirecciones[contador].Pending := Previous;
      end;
   closefile(FileWallet);
   S_Wallet := false;
   Except on E:Exception do
      tolog ('Error saving wallet to disk');
   end;
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
   try
   SetLength(ListaSumario,0);
   assignfile(FileSumario,SumarioFilename);
   Rewrite(FileSumario);
   CloseFile(FileSumario);
   // for cases when rebuilding sumary
   if FileExists(BlockDirectory+'0.blk') then UpdateSumario(ADMINHash,PremineAmount,0,'0');
   Except on E:Exception do
      tolog ('Error creating sumary file');
   end;
End;

// Loads sumary from disk
Procedure CargarSumario();
var
  contador : integer = 0;
Begin
   TRY
   SetLength(ListaSumario,0);
   assignfile(FileSumario,SumarioFilename);
   Reset(FileSumario);
   SetLength(ListaSumario,fileSize(FileSumario));
   for contador := 0 to Filesize(fileSumario)-1 do
      Begin
      seek(filesumario,contador);
      read(FileSumario,Listasumario[contador]);
      end;
   CloseFile(FileSumario);
   EXCEPT on E:Exception do
      tolog ('Error loading sumary from file');
   END;
End;

// Save sumary to disk
Procedure GuardarSumario();
var
  contador : integer = 0;
Begin
   try
   assignfile(FileSumario,SumarioFilename);
   Reset(FileSumario);
   for contador := 0 to length(ListaSumario)-1 do
      Begin
      seek(filesumario,contador);
      write(FileSumario,Listasumario[contador]);
      end;
   Truncate(filesumario);
   CloseFile(FileSumario);
   MySumarioHash := HashMD5File(SumarioFilename);
   S_Sumario := false;
   U_DataPanel := true;
   Except on E:Exception do
      tolog ('Error saving sumary file');
   end;
End;

// Returns the last downloaded block
function GetMyLastUpdatedBlock():int64;
Var
  BlockFiles : TStringList;
  contador : int64 = 0;
  LastBlock : int64 = 0;
  OnlyNumbers : String;
Begin
   try
   BlockFiles := TStringList.Create;
   FindAllFiles(BlockFiles, BlockDirectory, '*.blk', true);
   while contador < BlockFiles.Count do
      begin
      OnlyNumbers := copy(BlockFiles[contador], 17, length(BlockFiles[contador])-20);
      if CadToNum(OnlyNumbers,0,'Failed converting block to number:'+OnlyNumbers) > Lastblock then
         LastBlock := CadToNum(OnlyNumbers,0,'Failed converting block to number:'+OnlyNumbers);
      contador := contador+1;
      end;
   BlockFiles.Free;
   Result := LastBlock;
   Except on E:Exception do
      tolog ('Error getting my last updated block');
   end;
end;

// Updates sumary
Procedure UpdateSumario(Direccion:string;monto:Int64;score:integer;LastOpBlock:string);
var
  contador : integer = 0;
  Yaexiste : boolean = false;
  NuevoRegistro : SumarioData;
Begin
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
if DireccionEsMia(Direccion)>= 0 then UpdateWalletFromSumario();
End;

// Set alias for an address it it is empty
function SetCustomAlias(Address,Addalias:String):boolean;
var
  cont : integer;
Begin
result := false;
for cont := 0 to length(ListaSumario)-1 do
   begin
   if ((ListaSumario[cont].Hash=Address)and (ListaSumario[cont].custom='')) then
      begin
      listasumario[cont].Custom:=Addalias;
      result := true;
      break;
      end;
   end;
if not result then tolog('Error assigning custom alias to address:'+Address);
End;

// Unzip a zip file and (optional) delete it
procedure UnzipBlockFile(filename:String;delFile:boolean);
var
  UnZipper: TUnZipper;
begin
   try
   UnZipper := TUnZipper.Create;
      try
      UnZipper.FileName := filename;
      UnZipper.OutputPath := '';
      UnZipper.Examine;
      UnZipper.UnZipAllFiles;
      finally
      UnZipper.Free;
      end;
   if delfile then deletefile(filename);
   Except on E:Exception do
      tolog ('Error unzipping block file');
   end;
end;

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
consolelines.Add(LangLine(127)+IntToStr(untilblock)); //'Rebuilding until block '
contador := MyLastBlock;
while contador <= untilblock do
   begin
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
      RestoreBlockChain();
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
      {UpdateSumario(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,0,IntToStr(contador));
      // AQUI LEER LAS TRANSACCIONES Y PROCESARLAS
      ArrayOrders := Default(BlockOrdersArray);
      ArrayOrders := GetBlockTrxs(contador);
      for cont := 0 to length(ArrayOrders)-1 do
         begin
         if ArrayOrders[cont].OrderType='CUSTOM' then
            begin
            UpdateSumario(ArrayOrders[cont].Sender,Restar(Customizationfee),0,IntToStr(contador));
            setcustomalias(ArrayOrders[cont].Sender,ArrayOrders[cont].Receiver);
            end;
         if ArrayOrders[cont].OrderType='TRFR' then
            begin
            UpdateSumario(ArrayOrders[cont].Sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(contador));
            UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(contador));
            end;
         end;
      ListaSumario[0].LastOP:=contador;
      GuardarSumario(); }
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
   tolog ('Readjusted headers size');
   end;
closefile(FileResumen);
if newblocks>0 then
   begin
   ConsoleLines.Add(IntToStr(newblocks)+LangLine(129)); //' added to headers'
   U_Mytrxs := true;
   U_DirPanel := true;
   end;
GuardarSumario();
UpdateMyData();
MySumarioHash := HashMD5File(SumarioFilename);
U_Dirpanel := true;
if g_launching then OutText('✓ '+IntToStr(untilblock+1)+' blocks rebuilded',false,1);
End;

// Add 1 block transactions to sumary
Procedure AddBlockToSumary(BlockNumber:integer);
var
  cont : integer;
  BlockHeader : BlockHeaderData;
  ArrayOrders : BlockOrdersArray;
Begin
BlockHeader := Default(BlockHeaderData);
BlockHeader := LoadBlockDataHeader(BlockNumber);
UpdateSumario(BlockHeader.AccountMiner,BlockHeader.Reward+BlockHeader.MinerFee,0,IntToStr(BlockNumber));
ArrayOrders := Default(BlockOrdersArray);
ArrayOrders := GetBlockTrxs(BlockNumber);
for cont := 0 to length(ArrayOrders)-1 do
   begin
   if ArrayOrders[cont].OrderType='CUSTOM' then
      begin
      UpdateSumario(ArrayOrders[cont].Sender,Restar(Customizationfee),0,IntToStr(BlockNumber));
      setcustomalias(ArrayOrders[cont].Sender,ArrayOrders[cont].Receiver);
      end;
   if ArrayOrders[cont].OrderType='TRFR' then
      begin
      UpdateSumario(ArrayOrders[cont].Sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(BlockNumber));
      UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(BlockNumber));
      end;
   end;
ListaSumario[0].LastOP:=BlockNumber;
GuardarSumario();
UpdateMyData();
End;

// Rebuilds totally sumary
Procedure RebuildSumario(UntilBlock:integer);
var
  contador, cont : integer;
  BlockHeader : BlockHeaderData;
  ArrayOrders : BlockOrdersArray;
Begin
SetLength(ListaSumario,0);
// incluir el pago del bloque genesys
UpdateSumario(ADMINHash,PremineAmount,0,'0');
for contador := 1 to UntilBlock do
   begin
   info(LangLine(130)+inttoStr(contador));  //'Rebuilding sumary block: '
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
         setcustomalias(ArrayOrders[cont].Sender,ArrayOrders[cont].Receiver);
         end;
      if ArrayOrders[cont].OrderType='TRFR' then
         begin
         UpdateSumario(ArrayOrders[cont].Sender,Restar(ArrayOrders[cont].AmmountFee+ArrayOrders[cont].AmmountTrf),0,IntToStr(contador));
         UpdateSumario(ArrayOrders[cont].Receiver,ArrayOrders[cont].AmmountTrf,0,IntToStr(contador));
         end;
      end;
   end;
ListaSumario[0].LastOP:=contador;
GuardarSumario();
UpdateMyData();
consolelines.Add(LangLine(131));  //'Sumary rebuilded.'
end;

// adds a header at the end of headers file
Procedure AddBlchHead(Numero: int64; hash,sumhash:string);
var
  Dato: ResumenData;
Begin
   try
   assignfile(FileResumen,ResumenFilename);
   reset(FileResumen);
   Dato := Default(ResumenData);
   Dato.block:=Numero;
   Dato.blockhash:=hash;
   Dato.SumHash:=sumhash;
   seek(fileResumen,filesize(fileResumen));
   write(fileResumen,dato);
   closefile(FileResumen);
   Except on E:Exception do
      tolog ('Error adding new register to headers');
   end;
End;

// Deletes last header from headers file
Procedure DelBlChHeadLast();
Begin
   try
   assignfile(FileResumen,ResumenFilename);
   reset(FileResumen);
   seek(fileResumen,filesize(fileResumen)-1);
   truncate(fileResumen);
   closefile(FileResumen);
   Except on E:Exception do
      tolog ('Error deleting last record from headers');
   end;
End;

// Creates user transactions file
Procedure CrearMistrx();
var
  DefaultOrder : MyTrxData;
Begin
   try
   DefaultOrder := Default(MyTrxData);
   DefaultOrder.Block:=0;
   assignfile(FileMyTrx,MyTrxFilename);
   rewrite(FileMyTrx);
   write(FileMyTrx,DefaultOrder);
   closefile(FileMyTrx);
   SetLength(ListaMisTrx,1);
   ListaMisTrx[0] := DefaultOrder;
   Except on E:Exception do
      tolog ('Error creating my trx file');
   end;
End;

// Loads user transactions from disk
Procedure CargarMisTrx();
var
  dato : MyTrxData;
Begin
   try
   assignfile(FileMyTrx,MyTrxFilename);
   reset(FileMyTrx);
   setlength(ListaMisTrx,0);
   while not eof(FileMyTrx) do
      begin
      Dato := Default(MyTrxData);
      setlength(ListaMisTrx,length(ListaMisTrx)+1);
      read(FileMyTrx,dato);
      ListaMisTrx[length(ListaMisTrx)-1] := dato;
      end;
   closefile(FileMyTrx);
   Except on E:Exception do
      tolog ('Error loading my trx from file');
   end;
End;

// Save value of last checked block for user transactions
Procedure SaveMyTrxsLastUpdatedblock(Number:integer);
var
  FirstTrx : MyTrxData;
Begin
   try
   FirstTrx := Default(MyTrxData);
   FirstTrx.block:=Number;
   assignfile (FileMyTrx,MyTrxFilename);
   reset(FileMyTrx);
   seek(FileMyTrx,0);
   write(FileMyTrx,FirstTrx);
   Closefile(FileMyTrx);
   Except on E:Exception do
      tolog ('Error setting last block checked for my trx');
   end;
End;

// Rebuilds user transactions  file up to specified block
Procedure RebuildMyTrx(blocknumber:integer);
var
  contador,contador2 : integer;
  Existentes : integer;
  Header : BlockHeaderData;
  NewTrx : MyTrxData;
  ArrTrxs : BlockOrdersArray;
Begin
Existentes := Length(ListaMisTrx);
if ListaMisTrx[0].Block = blocknumber then exit;  // block number already rebuilded
for contador := ListaMisTrx[0].Block+1 to blocknumber do
   begin
   Header := LoadBlockDataHeader(contador);
   if DireccionEsMia(Header.AccountMiner)>=0 then // user is miner
      begin
      NewTrx := Default(MyTrxData);
      NewTrx.block:=contador;
      NewTrx.time :=header.TimeEnd;
      NewTrx.tipo :='MINE';
      NewTrx.receiver:=header.AccountMiner;
      NewTrx.monto   :=header.Reward+header.MinerFee;
      NewTrx.trfrID  :='';
      NewTrx.OrderID :='';
      NewTrx.Concepto:='';
      insert(NewTrx,ListaMisTrx,length(ListaMisTrx));
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
            NewTrx.Concepto:= ArrTrxs[contador2].Concept;
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
            NewTrx.Concepto:= ArrTrxs[contador2].Concept;
            insert(NewTrx,ListaMisTrx,length(ListaMisTrx));
            end;
         end;
      end;
   end;
ListaMisTrx[0].block:=blocknumber;
if length(ListaMisTrx) > Existentes then  // se han añadido transacciones
   begin
   SaveMyTrxsToDisk(existentes);
   U_Mytrxs := true;
   end;
SaveMyTrxsLastUpdatedblock(blocknumber);
End;

// Save last user transactions to disk
Procedure SaveMyTrxsToDisk(Cantidad:integer);
var
  contador : integer;
Begin
   try
   assignfile (FileMyTrx,MyTrxFilename);
   reset(FileMyTrx);
   for contador := cantidad to length(ListaMisTrx)-1 do
      begin
      seek(FileMyTrx,contador);
      write(FileMyTrx,ListaMisTrx[contador]);
      end;
   Closefile(FileMyTrx);
   Except on E:Exception do
      tolog ('Error saving my trx to disk');
   end;
End;

// Non blocking rebuilding user transactions
Function NewMyTrx(aParam:Pointer):PtrInt;
Begin
CrearMistrx();
CargarMisTrx();
RebuildMyTrx(MyLastBlock);
NewMyTrx := -1;
End;

// Creates a bat file for restart
Procedure CrearBatFileForRestart();
var
  archivo : textfile;
Begin
try
  Assignfile(archivo, 'nosolauncher.bat');
  rewrite(archivo);
  writeln(archivo,'echo Restarting Noso...');
  writeln(archivo,'TIMEOUT 5');
  writeln(archivo,'start noso.exe');
  Closefile(archivo);
  Except on E:Exception do
    tolog ('Error creating restart file');
  end;
end;

// Prepares for restart
Procedure RestartNoso();
Begin
CrearBatFileForRestart();
RunExternalProgram('nosolauncher.bat');
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
Begin
Miner_KillThreads := true;
CloseAllforms();
CerrarClientes();
StopServer();
StopPoolServer();
If Miner_IsOn then Miner_IsON := false;
KillAllMiningThreads;
setlength(CriptoOpsTipo,0);
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
outtext('Blocks to check: '+IntToStr(lastblock+1),false,1);
outtext('Checking block files 0 %',false,1);
for cont := 0 to lastblock do
   begin
   gridinicio.RowCount := gridinicio.RowCount-1;
   if not fileexists(BlockDirectory+IntToStr(cont)+'.blk') then
      begin
      errores +=1;
      end;
   porcentaje := (cont * 100) div lastblock;
   outtext('Checking block files '+inttostr(porcentaje)+' %',false,1);
   end;
outtext('Block hash correct 0 %',false,1);
assignfile(FileResumen,ResumenFilename);
reset(FileResumen);
for cont := 0 to lastblock do
   begin
   Seek(FileResumen,cont);
   Read(FileResumen,dato);
   gridinicio.RowCount := gridinicio.RowCount-1;
   if HashMD5File(BlockDirectory+IntToStr(cont)+'.blk')<> dato.blockhash then
      begin
      errores +=1;
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
outtext('Sumary hash correct 0 %',false,1);
for cont := 1 to lastblock do
   begin
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
outtext('Errors: '+IntToStr(errores)+' / Fixed: '+IntToStr(fixed),false,1);
RunningDoctor := false;
FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
UpdateMyData();
End;

// Creates the pool info file
Procedure CrearArchivoPoolInfo(nombre,direccion:string;porcentaje,miembros,port,tipo:integer;pass:string);
var
  dato : PoolInfoData;
Begin
assignfile(FilePool,PoolInfoFilename);
rewrite(FilePool);
dato.Name := nombre;
dato.Direccion:=direccion;
dato.Porcentaje:=porcentaje;
dato.MaxMembers:=miembros;
dato.Port:=port;
dato.TipoPago:=tipo;
Dato.FeeEarned:=0;
dato.PassWord:=pass;
write(filepool,dato);
Closefile(FilePool);
PoolInfo := Dato;
ResetPoolMiningInfo;
End;

// Saves the pool info file
Procedure GuardarArchivoPoolInfo();
Begin
try
assignfile(FilePool,PoolInfoFilename);
rewrite(FilePool);
write(filepool,PoolInfo);
Closefile(FilePool);
Except on E:Exception do
   tolog('Error savinf PoolInfo file:'+E.Message);
end;
S_PoolInfo := false;
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

// Save pool members file to disk
Procedure GuardarPoolMembers();
var
  contador : integer;
Begin
assignfile(FilePoolMembers,PoolMembersFilename);
rewrite(FilePoolMembers);
TRY
for contador := 0 to length(ArrayPoolMembers)-1 do
   begin
   seek(FilePoolMembers,contador);
   write(FilePoolMembers,ArrayPoolMembers[contador]);
   end;
EXCEPT on E:Exception do
   ToLog('Error saving pool members to disk.');
END;
Closefile(FilePoolMembers);
S_PoolMembers := false;
End;

// Creates and executes autolauncher.bat
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
try
  Assignfile(archivo, 'restart.txt');
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
  linea : string;
  Server,connect : boolean;
Begin
Assignfile(archivo, 'restart.txt');
reset(archivo);
ReadLn(archivo,linea);
Closefile(archivo);
server := StrToBool(parameter(linea,1));
connect := StrToBool(parameter(linea,3));
if server then Processlines.Add('SERVERON');
if connect then Processlines.Add('CONNECT');
Deletefile('restart.txt');
End;

// Creates crashinfofile
Procedure CrearCrashInfo();
var
  archivo : textfile;
Begin
try
  Assignfile(archivo, 'crashinfo.txt');
  rewrite(archivo);
  writeln(archivo,GetCurrentStatus(1));
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
  {$IFDEF Linux}
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
StopPoolServer();
If Miner_IsOn then Miner_IsON := false;
KillAllMiningThreads;
setlength(CriptoOpsTipo,0);
deletefile(SumarioFilename);
deletefile(SumarioFilename+'.bak');
deletefile(ResumenFilename);
deletefile(MyTrxFilename);
if DeleteDirectory(BlockDirectory,True) then
   RemoveDir(BlockDirectory);
processlines.Add('restart');
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
UpdatesDirectory    := 'NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator;
ResumenFilename     := 'NOSODATA'+DirectorySeparator+'blchhead.nos';
MyTrxFilename       := 'NOSODATA'+DirectorySeparator+'mytrx.nos';
TranslationFilename := 'NOSODATA'+DirectorySeparator+'English_empty.txt';
ErrorLogFilename    := 'NOSODATA'+DirectorySeparator+'errorlog.txt';
PoolInfoFilename    := 'NOSODATA'+DirectorySeparator+'poolinfo.dat';
PoolMembersFilename := 'NOSODATA'+DirectorySeparator+'poolmembers.dat';
AdvOptionsFilename  := 'NOSODATA'+DirectorySeparator+'advopt.txt';
End;

END. // END UNIT

