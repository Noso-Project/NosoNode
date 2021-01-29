unit MasterPaskalForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLType,
  Grids, ExtCtrls, Buttons, IdTCPServer, IdContext, IdGlobal, IdTCPClient,
  fileutil,Clipbrd, Menus, crt, formexplore;

type

  Options = Packed Record
     language: integer;
     Port : integer;
     GetNodes : Boolean;
     SSLPath : String[255];
     Wallet : string[255];
     AutoServer : boolean;
     AutoConnect : Boolean;
     Auto_Updater : boolean;
     JustUpdated : boolean;
     VersionPage : String[255];
     ToTray : boolean;
     end;

  BotData = Packed Record
     ip: string[15];
     LastRefused : string[17];
     end;

  NodeData = Packed Record
     ip: string[15];
     port: string[8];
     LastConexion : string[17];
     end;

  NTPData = Packed Record
     Host: string[50];
     LastUsed : string[17];
     end;

  conectiondata = Packed Record
     Autentic: boolean;                 // si la conexion esta autenticada por un ping
     Connections : Integer;             // A cuantos pares esta conectado
     tipo: string[8];                   // Tipo: SER o CLI
     ip: string[20];                    // La IP del par
     lastping: string[15];              // UTCTime del ultimo ping
     context: TIdContext;               // Informacion para los canales cliente
     Lastblock: string[15];             // Numero del ultimo bloque
     LastblockHash: string[64];         // Hash del ultimo bloque
     SumarioHash : string[64];          // Hash del sumario de cuenta
     Pending: Integer;                  // Cantidad de operaciones pendientes
     Protocol : integer;                // Numero de protocolo usado
     Version : string[6];
     ListeningPort : integer;
     offset : integer;                  // Segundos de diferencia a su tiempo
     ResumenHash : String[64];           //
     ConexStatus : integer;
     end;

  WalletData = Packed Record
     Hash : String[40]; // El hash publico o direccion
     Custom : String[40]; // En caso de que la direccion este personalizada
     PublicKey : String[255]; // clave publica
     PrivateKey : String[255]; // clave privada
     Balance : int64; // el ultimo saldo conocido de la direccion
     Score : int64; // estado del registro de la direccion.
     LastOP : int64;// tiempo de la ultima operacion en UnixTime.
     end;

  SumarioData = Packed Record
     Hash : String[255]; // El hash publico o direccion
     Custom : String[40]; // En caso de que la direccion este personalizada
     Balance : int64; // el ultimo saldo conocido de la direccion
     Score : int64; // estado del registro de la direccion.
     LastOP : int64;// tiempo de la ultima operacion en UnixTime.
     end;

  BlockHeaderData = Packed Record
     Number         : Int64;
     TimeStart      : Int64;
     TimeEnd        : Int64;
     TimeTotal      : integer;
     TimeLast20     : integer;
     TrxTotales     : integer;
     Difficult      : integer;
     TargetHash     : String[32];
     Solution       : String[255];
     NxtBlkDiff     : integer;
     AccountMiner   : String[40];
     MinerFee       : Int64;
     Reward         : Int64;
     end;

  OrderData = Packed Record
     Block : integer;
     OrderID : String[64];
     OrderLines : Integer;
     OrderType : String[6];
     TimeStamp : Int64;
     Concept : String[64];
       TrxLine : integer;
       Sender : String[255];    // La clave publica de quien envia
       Receiver : String[40];
       AmmountFee : Int64;
       AmmountTrf : Int64;
       Signature : String[120];
       TrfrID : String[64];
     end;

  NetworkData = Packed Record
     Value : String[64];
     Count : integer;
     Slot : integer;
     end;

  ResumenData = Packed Record
     block : integer;
     blockhash : string[64];
     SumHash : String[64];
     end;

  DivResult = packed record
     cociente : string[255];
     residuo : string[255];
     end;

  MyTrxData = packed record
     block : integer;
     time  : int64;
     tipo  : string[6];
     receiver : string[64];
     monto    : int64;
     trfrID   : string[64];
     OrderID  : String[64];
     Concepto : String[64];
     end;


  BlockOrdersArray = Array of OrderData;

  { TForm1 }

  TForm1 = class(TForm)
    Imagenes: TImageList;
    Latido : TTimer;
    InfoTimer : TTimer;
    Server: TIdTCPServer;
    SystrayIcon: TTrayIcon;

    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormWindowStateChange(Sender: TObject);
    Procedure LoadOptionsToPanel();
    procedure FormShow(Sender: TObject);
    Procedure ConsoleLineKeyup(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Grid1PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure Grid2PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    Procedure GridMyTxsPrepareCanvas(sender: TObject; aCol, aRow: Integer;aState: TGridDrawState);
    Procedure LatidoEjecutar(Sender: TObject);
    Procedure InfoTimerEnd(Sender: TObject);
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
    Procedure DoubleClickSysTray(Sender: TObject);
    Procedure ConnectCircleOnClick(Sender: TObject);
    Procedure MinerCircleOnClick(Sender: TObject);
    Procedure LangSelectOnChange(Sender: TObject);
    Procedure GridMyTxsOnDoubleClick(Sender: TObject);
    Procedure BCloseTrxDetailsOnClick(Sender: TObject);
    Procedure BCustomAddrOnClick(Sender: TObject);
    Procedure EditCustomKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure BOkCustomClick(Sender: TObject);
    Procedure PanelCustomMouseLeave(Sender: TObject);
    Procedure BNewAddrOnClick(Sender: TObject);
    Procedure BCopyAddrClick(Sender: TObject);
    Procedure CheckForHint(Sender:TObject);
    Procedure BSendCoinsClick(Sender: TObject);
    Procedure BCLoseSendOnClick(Sender: TObject);
    Procedure SBSCPasteOnClick(Sender:TObject);
    Procedure SBSCMaxOnClick(Sender:TObject);
    Procedure EditSCDestChange(Sender:TObject);
    Procedure EditSCMontChange(Sender:TObject);
    Procedure DisablePopUpMenu(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure EditMontoOnKeyUp(Sender: TObject; var Key: char);
    Procedure SCBitSendOnClick(Sender:TObject);
    Procedure SCBitCancelOnClick(Sender:TObject);
    Procedure SCBitConfOnClick(Sender:TObject);
    Procedure ResetearValoresEnvio(Sender:TObject);
    Procedure SBOptionsOnClick(Sender:TObject);
    Procedure SBDelNodeOnClick(Sender:TObject);
    Procedure SBNewNodeOnClick(Sender:TObject);
    Procedure CBGetNodesOnChange(Sender:TObject);
    Procedure CBAutoserverOnChange(Sender:TObject);
    Procedure CBAutoConnectOnChange(Sender:TObject);
    Procedure CBAutoUpdateOnChange(Sender:TObject);
    Procedure CBToTrayOnChange(Sender:TObject);
    // MAIN MENU
    Procedure CheckMMCaptions(Sender:TObject);
    Procedure MMServer(Sender:TObject);
    Procedure MMConnect(Sender:TObject);
    Procedure MMMiner(Sender:TObject);
    Procedure MMImpWallet(Sender:TObject);
    Procedure MMExpWallet(Sender:TObject);
    Procedure MMQuit(Sender:TObject);
    Procedure MMChangeLang(Sender:TObject);
    Procedure MMImpLang(Sender:TObject);
    Procedure MMNewLang(Sender:TObject);
    Procedure MMVerConsola(Sender:TObject);

  private

  public

  end;

Procedure InicializarFormulario();
Procedure CerrarPrograma();

CONST
  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  ReservedWords : string = 'NULL,DELADDR';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';
  ProgramVersion = '0.1.1';
  ADMINHash = 'NUBy1bsprQKeFrVU4K8eKP46QG2ABs';
  OptionsFileName = 'NOSODATA/options.psk';
  BotDataFilename = 'NOSODATA/botdata.psk';
  NodeDataFilename = 'NOSODATA/nodes.psk';
  NTPDataFilename = 'NOSODATA/ntpservers.psk';
  WalletFilename = 'NOSODATA/wallet.pkw';
  SumarioFilename = 'NOSODATA/sumary.psk';
  LanguageFileName = 'NOSODATA/noso.lng';
  BlockDirectory = 'NOSODATA/BLOCKS/';
  UpdatesDirectory = 'NOSODATA/UPDATES/';
  ResumenFilename = 'NOSODATA/blchhead.nos';
  MyTrxFilename = 'NOSODATA/mytrx.nos';
  TranslationFilename = 'NOSODATA/English_empty.txt';
  DefaultServerPort = 8080;
  MaxConecciones  = 15;
  Protocolo = 1;
  Miner_Steps = 10;
  // Custom values for coin
  SecondsPerBlock = 600;            // 10 minutes
  PremineAmount = 1030390730000;                // Ammount premined in genesys block
  InitialReward = 5000000000;      // Initial reward
  BlockHalvingInterval = 210000;    // Number of blocks between halvings. 2 years   105120
  HalvingSteps = 10;                // total number of halvings
  Comisiontrfr = 10000;             // ammount/Comisiontrfr = 0.01 % of the ammount
  ComisionCustom = 200000;          // 0.05 % of the Initial reward
  CoinSimbol = 'NOS';               // Coin 3 chats
  CoinName = 'Noso';                // Coin name
  CoinChar = 'N';                   // Char for addresses
  MinimunFee = 10;                  // Minimun fee for transfer
  ComisionBlockCheck = 12960;       // +- 90 days
  DeadAddressFee = 5000;            // unactive acount fee
  ComisionScrow = 200;              // Coin/BTC market comision = 0.5%
  InitialBlockDiff = 60;            // Dificultad durante los 20 primeros bloques

var
  FirstShow : boolean = false;
  MinConexToWork : integer = 1;
  Customizationfee : int64 = InitialReward div ComisionCustom;
  G_TimeOffSet : Int64 = 0;
  G_NTPServer : String = '';
  G_OpenSSLPath : String = '';
  G_Launching : boolean = true;   // Indica si el programa se esta iniciando
  G_CloseRequested : boolean = false;
  G_LastPing  : int64;            // El segundo del ultimo ping
  G_TotalPings : Int64 = 0;
  Form1: TForm1;
  Memoconsola : Tmemo;
  ConsoleLine : TEdit;
  LastCommand : string = '';
  ProcessLines : TStringlist;
  StringListLang : TStringlist;
  IdiomasDisponibles : TStringlist;
  DLSL : TStringlist;                // Default Language String List
  ConsoleLines : TStringList;
  DataPanel : TStringGrid;
    U_DataPanel : boolean = true;
  LabelBigBalance : TLabel;

    U_DirPanel : boolean = false;
  FileMyTrx  : File of MyTrxData;
    S_MyTrxs  : boolean = false;
  FileOptions : file of options;
    S_Options : Boolean = false;
  FileBotData : File of BotData;
    S_BotData : Boolean = false;
  FileNodeData : File of NodeData;
    S_NodeData : Boolean = false;
  FileNTPData : File of NTPData;
    S_NTPData : boolean = false;
  FileWallet : file of WalletData;
    S_Wallet : boolean = false;
  FileSumario : file of SumarioData;
    S_Sumario : boolean = false;
  FileResumen : file of ResumenData;
    S_Resumen : Boolean = false;
  UserOptions : Options;
  CurrentLanguage : String = '';
  LanguageLines : integer = 0;
  Conexiones : array [1..MaxConecciones] of conectiondata;
  SlotLines : array [1..MaxConecciones] of TStringList;
  CanalCliente : array [1..MaxConecciones] of TIdTCPClient;
  ListadoBots :  array of BotData;
  ListaNodos : array of NodeData;
  ListaNTP : array of NTPData;
  ListaMisTrx : Array of MyTrxData;
  ListaDirecciones : array of walletData; // Contiene las direcciones del wallet
  ListaSumario : array of SumarioData;    // Contiene las direcciones del sumario
  PendingTXs : Array of OrderData;
  OutgoingMsjs : TStringlist;
  ArrayConsenso : array of NetworkData;

  // Variables asociadas a la red
  CONNECT_LastTime : string = ''; // La ultima vez que se intento una conexion
  CONNECT_Try : boolean = false;
  MySumarioHash : String = '';
  MyLastBlock : integer = 0;
  MyLastBlockHash : String = '';
  MyResumenHash : String = '';
  MyPublicIP : String = '';
  LastBlockData : BlockHeaderData;

  NetSumarioHash : NetworkData;
  NetLastBlock : NetworkData;
    LastTimeRequestBlock : int64 = 0;
  NetPendingTrxs : NetworkData;
  NetResumenHash : NetworkData;
    LastTimeRequestResumen : int64 = 0;
  // Variables asociadas a mi conexion
  MyConStatus :  integer = 0;
  STATUS_Connected : boolean = false;

  // Variables asociadas al minero
  Miner_IsON : Boolean = false;
  Miner_Active : Boolean = false;
  Miner_Waiting : int64 = -1;
  Miner_BlockToMine : integer =0;
  Miner_Difficult : integer = 0;
  Miner_DifChars : integer = 0;
  Miner_Target : String = '';
  MINER_FoundedSteps : integer = 0;
  MINER_HashCounter : Int64 = 100000000;
  Miner_HashSeed : String = '!!!!!!!!!';
  Miner_Thread : Int64 = 0;
  Miner_Address : string = '';
  Miner_BlockFOund : boolean = False;
  Miner_Solution : String = '';
  Miner_SolutionVerified : boolean = false;
  Miner_UltimoRecuento : int64 = 100000000;
  Miner_EsteIntervalo : int64 = 0;
  // COmponentes visuales
  MainMenu : TMainMenu;
  MenuItem : TMenuItem;
  ConnectButton : TSpeedButton;
  MinerButton : TSpeedButton;
  ImageInc :TImage;
    MontoIncoming : Int64 = 0;
  ImageOut :TImage;
    MontoOutgoing : Int64 = 0;
  DireccionesPanel : TStringGrid;
    BCustomAddr : TSpeedButton;
      PanelCustom : TPanel;
        EditCustom : TEdit;
        BOkCustom : TSpeedButton;
    BNewAddr : TSpeedButton;
    BCopyAddr : TSpeedButton;
    BSendCoins : TSpeedButton;
  PanelSend : Tpanel;
    LSCTop : Tlabel;
    BCLoseSend : TSpeedButton;
    SGridSC   : Tstringgrid;
    SBSCPaste : TSpeedButton;
    SBSCMax: TSpeedButton;
    EditSCDest : TEdit;
    EditSCMont : TEdit;
    ImgSCDest  : TImage;
    ImgSCMont  : TImage;
    MemoSCCon : Tmemo;
    SCBitClea : TBitBtn;
    SCBitSend : TBitBtn;
    SCBitCancel : TBitBtn;
    SCBitConf : TBitBtn;
  GridMyTxs : TStringGrid;
    BitInfoTrx: TSpeedButton;
    U_Mytrxs: boolean = false;
  PanelTrxDetails : TPanel;
    MemoTrxDetails : TMemo;
    BCloseTrxDetails : TBitBtn;

  PanelScrow : Tpanel;
    BScrowSell : Tbutton;
    BScrowBuy  : TButton;
    GridScrowSell :TStringGrid;

  OptionsPanel : Tpanel;
    LabelNodes : TLabel;
    SBDelNode : TSpeedButton;
    GridNodes : TStringGrid;
    EditIP : TEdit;
    EditPort : TEdit;
    SBNewNode :TSpeedButton;
    LabelOptions:Tlabel;
    OptionsScroll : TScrollBox;
    GridOptions : TStringgrid;
      LangSelect : TComboBox;
      EditMyPort : TEdit;
      EditMaxpeer : TEdit;
      EditMinpeer : TEdit;
      CBGetNodes : TCheckBox;
      CBAutoserver : TCheckBox;
      CBAutoConnect: TCheckBox;
      CBAutoUpdate : TCheckBox;
      CBToTray : TCheckBox;

  SBOptions : TSpeedButton;

  InfoPanel : TPanel;
    InfoPanelTime : integer = 0;

implementation

Uses
  mpgui, mpdisk, mpParser, mpRed, mpTime, mpProtocol, mpMiner, mpcripto, mpcoin;

{$R *.lfm}

{ TForm1 }

// Al iniciar el programa
procedure TForm1.FormShow(Sender: TObject);
var
  contador : integer;
begin
// Se ejecuta solo la primera vez
if FirstShow then exit;
//inicializar lo basico para cargar el idioma
if not directoryexists('NOSODATA') then CreateDir('NOSODATA');
if not FileExists(OptionsFileName) then CrearArchivoOpciones() else CargarOpciones();
StringListLang := TStringlist.Create;
ConsoleLines := TStringlist.Create;
DLSL := TStringlist.Create;
IdiomasDisponibles := TStringlist.Create;
if not FileExists (LanguageFileName) then CrearIdiomaFile() else CargarIdioma(UserOptions.language);
// finalizar la inicializacion
InicializarFormulario();
VerificarArchivos();
InicializarGUI();
InitTime();
UpdateMyData();
ResetMinerInfo();
// Ajustes a mostrar
LoadOptionsToPanel();
form1.Caption:=coinname+LangLine(61)+ProgramVersion;    // Wallet
Application.Title := coinname+LangLine(61)+ProgramVersion;  // Wallet
for contador := 0 to IdiomasDisponibles.Count-1 do
   LangSelect.Items.Add(IdiomasDisponibles[contador]);
LangSelect.ItemIndex:=0;
FillNodeList();
G_Launching := false;
ConsoleLines.Add(coinname+LangLine(61)+ProgramVersion);  // wallet
RebuildMyTrx(MyLastBlock);
UpdateMyTrxGrid();
if UserOptions.AutoServer then ProcessLines.add('SERVERON');
if UserOptions.AutoConnect then ProcessLines.add('CONNECT');
if useroptions.JustUpdated then
   begin
   consolelines.add(LangLine(19)+ProgramVersion);  // Update to version sucessfull:
   useroptions.JustUpdated := false;
   Deletefile('mpupdater.exe');
   S_Options := true;
   end;
Form1.Latido.Enabled:=true;
FirstShow := true;
end;

// Carga las opciones de usuario al panel de opciones
Procedure TForm1.LoadOptionsToPanel();
Begin
EditMyPort.Text:=IntToStr(UserOptions.Port);
EditMaxpeer.Text :=IntToStr(Maxconecciones);
EditMinpeer.text := IntToStr(MinConexToWork);
CBGetNodes.Checked := UserOptions.GetNodes;
CBAutoserver.Checked := UserOptions.AutoServer;
CBAutoConnect.Checked := UserOptions.AutoConnect;
CBAutoUpdate.Checked := UserOptions.AutoConnect;
CBTotray.Checked := UserOptions.ToTray;
End;

// Cuando se solicita cerrar el programa
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
G_CloseRequested := true;
canclose := false;
end;

// Al minimizar verifica si hay que llevarlo a barra de tareas
procedure TForm1.FormWindowStateChange(Sender: TObject);
begin
if not UserOptions.ToTray then exit;
if Form1.WindowState = wsMinimized then
   begin
   SysTrayIcon.visible:=true;
   form1.hide;
   end;
end;

// Chequea las teclas presionadas en la linea de comandos
Procedure TForm1.ConsoleLineKeyup(Sender: TObject; var Key: Word; Shift: TShiftState);
var
  LineText : String;
begin
LineText := ConsoleLine.Text;
if Key=VK_RETURN then
   begin
   ConsoleLine.Text := '';
   LastCommand := LineText;
   ProcessLines.add(LineText);
   end;
if Key=VK_F3 then
   Begin
   ConsoleLine.Text := LastCommand;
   ConsoleLine.SelStart := Length(ConsoleLine.Text);
   end;
if Key=VK_ESCAPE then
   Begin
   ConsoleLine.Text := '';
   ConsoleLine.SelStart := Length(ConsoleLine.Text);
   end;
end;

// Colorea el fondo del data panel adecuadamente
procedure TForm1.Grid1PrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  ts: TTextStyle;
begin
if ((ACol = 0) or (ACol = 2)) then
   begin
   (Sender as TStringGrid).Canvas.Brush.Color :=  cl3dlight;
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taCenter;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end
else
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end;
end;

// Colorea el fondo del panel de direcciones adecuadamente
procedure TForm1.Grid2PrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  ts: TTextStyle;
begin
if (ACol=1)  then
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end;
end;

// Para colorear adecuadamente al grid de mis transacciones
Procedure TForm1.GridMyTxsPrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  ts: TTextStyle;
Begin
if ((ACol=3) and(ARow>0))then
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   if Copy(GridMyTxs.Cells[3,aRow],1,1) = '-' then GridMyTxs.Canvas.Font.Color:=clRed
   else GridMyTxs.Canvas.Font.Color:=clGreen;
   end
else if ((arow=0) and (acol = 3)) then
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end
else
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taCenter;
   (Sender as TStringGrid).Canvas.TextStyle := ts;
   end;
End;

// Ejecutar el ladido del timer
Procedure TForm1.LatidoEjecutar(Sender: TObject);
Begin
Form1.Latido.Enabled:=false;
ActualizarGUI();
MostrarLineasDeConsola();
SaveUpdatedFiles();
ProcesarLineas();
LeerLineasDeClientes();
ParseProtocolLines();
VerifyConnectionStatus();
VerifyMiner();
if G_CloseRequested then CerrarPrograma();
Form1.Latido.Enabled:=true;
if form1.SystrayIcon.Visible then
   form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion+SLINEBREAK+LabelBigBalance.Caption;
end;

//procesa el cierre de la aplicacion
Procedure CerrarPrograma();
Begin
info(LangLine(62));  //   Closing wallet
CerrarClientes();
StopServer();
KillThread(Miner_Thread);
//Showmessage(LangLine(63));  //Closed gracefully
Application.Terminate;
End;

// Crear todos los elementos necesarios para inicializar el programa
Procedure InicializarFormulario();
var
  contador : integer = 0;
Begin
// Elementos visuales
MainMenu := TMainMenu.create(form1);

MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Network';MainMenu.items.Add(MenuItem);
MenuItem.OnClick:=@form1.CheckMMCaptions;
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Start Server';MenuItem.OnClick:=@Form1.MMServer;
  Form1.imagenes.GetBitmap(27,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Connect';MenuItem.OnClick:=@Form1.MMConnect;
  Form1.imagenes.GetBitmap(29,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Miner';MenuItem.OnClick:=@Form1.MMMiner;
  Form1.imagenes.GetBitmap(4,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Import Wallet';MenuItem.OnClick:=@Form1.MMImpWallet;
  Form1.imagenes.GetBitmap(31,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Export Wallet';MenuItem.OnClick:=@Form1.MMExpWallet;
  Form1.imagenes.GetBitmap(32,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Quit Forced';MenuItem.OnClick:=@Form1.MMQuit;
  Form1.imagenes.GetBitmap(18,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);

MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Language';MainMenu.items.Add(MenuItem);
MenuItem.OnClick:=@form1.CheckMMCaptions;
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Change';
  Form1.imagenes.GetBitmap(35,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Import';MenuItem.OnClick:=@Form1.MMImpLang;
  Form1.imagenes.GetBitmap(33,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='New file';MenuItem.OnClick:=@Form1.MMNewLang;
  Form1.imagenes.GetBitmap(34,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);

MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='View';MenuItem.RightJustify:=true;MainMenu.items.Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Console';MenuItem.OnClick:=@Form1.MMVerConsola;
  Form1.imagenes.GetBitmap(25,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);

Memoconsola := TMemo.Create(Form1);
Memoconsola.Parent:=form1;
Memoconsola.Left:=2;Memoconsola.Top:=2;Memoconsola.Height:=280;Memoconsola.Width:=396;
Memoconsola.Color:=clblack;Memoconsola.Font.Color:=clwhite;Memoconsola.ReadOnly:=true;
Memoconsola.Font.Size:=10;Memoconsola.Font.Name:='consolas';
Memoconsola.Visible:=false;Memoconsola.ScrollBars:=ssvertical;

ConsoleLine := TEdit.Create(Form1); ConsoleLine.Parent:=Form1;ConsoleLine.Font.Name:='consolas';
ConsoleLine.Left:=2;ConsoleLine.Top:=282;ConsoleLine.Height:=12;ConsoleLine.Width:=396;
ConsoleLine.AutoSize:=true;ConsoleLine.Color:=clBlack;ConsoleLine.Font.Color:=clWhite;
ConsoleLine.Visible:=false;ConsoleLine.OnKeyUp:=@form1.ConsoleLineKeyup;

DataPanel := TStringGrid.Create(Form1);DataPanel.Parent:=Form1;
DataPanel.Left:=2;DataPanel.Top:=310;DataPanel.Height:=180;DataPanel.Width:=396;
DataPanel.ColCount:=4;DataPanel.rowcount:=8;DataPanel.FixedCols:=0;DataPanel.FixedRows:=0;
DataPanel.enabled:= false;
DataPanel.ScrollBars:=ssnone;
DataPanel.ColWidths[0]:= 79;DataPanel.ColWidths[1]:= 119;DataPanel.ColWidths[2]:= 79;DataPanel.ColWidths[3]:= 119;
DataPanel.Visible:=false;
DataPanel.OnPrepareCanvas:= @Form1.Grid1PrepareCanvas;

LabelBigBalance := TLabel.Create(Form1);LabelBigBalance.Parent:=form1;
LabelBigBalance.Caption:='0 '+Coinsimbol;LabelBigBalance.Font.Size:=18;LabelBigBalance.AutoSize:=false;
LabelBigBalance.Left:= 2;LabelBigBalance.Top:=2;LabelBigBalance.Width:=396;
LabelBigBalance.Height:=28;LabelBigBalance.Alignment:=taRightJustify;
LabelBigBalance.Enabled:=false;
LabelBigBalance.Font.Name:='consolas';

ConnectButton := TSpeedButton.Create(form1);ConnectButton.Parent:=form1;
ConnectButton.Top:=2;ConnectButton.Left:=2;ConnectButton.Height:=26;ConnectButton.Width:=26;
Form1.imagenes.GetBitmap(2,ConnectButton.Glyph);
ConnectButton.Caption:='';ConnectButton.OnClick:=@Form1.ConnectCircleOnClick;
ConnectButton.ShowHint:=true;ConnectButton.OnMouseEnter:=@Form1.CheckForHint;

MinerButton := TSpeedButton.Create(form1);MinerButton.Parent:=form1;
MinerButton.Top:=2;MinerButton.Left:=30;MinerButton.Height:=26;MinerButton.Width:=26;
Form1.imagenes.GetBitmap(4,MinerButton.Glyph);
MinerButton.Caption:='';MinerButton.OnClick:=@Form1.MinerCircleOnClick;
MinerButton.ShowHint:=true;MinerButton.OnMouseEnter:=@Form1.CheckForHint;

SBOptions := TSpeedButton.Create(Form1);SBOptions.Parent:=Form1;
SBOptions.Left:=58;SBOptions.Top:=2;SBOptions.Height:=26;SBOptions.Width:=26;
Form1.imagenes.GetBitmap(22,SBOptions.Glyph);
SBOptions.Visible:=true;SBOptions.OnClick:=@form1.SBOptionsOnClick;
SBOptions.hint:='Show/Hide options';SBOptions.ShowHint:=true;

ImageInc := TImage.Create(form1);ImageInc.Parent:=form1;
ImageInc.Top:=2;ImageInc.Left:=86;ImageInc.Height:=17;ImageInc.Width:=17;
Form1.imagenes.GetIcon(9,ImageInc.Picture.Icon);ImageInc.Visible:=false;
ImageInc.ShowHint:=true;ImageInc.OnMouseEnter:=@Form1.CheckForHint;

ImageOut := TImage.Create(form1);ImageOut.Parent:=form1;
ImageOut.Top:=12;ImageOut.Left:=93;ImageOut.Height:=17;ImageOut.Width:=17;
Form1.imagenes.GetIcon(10,Imageout.Picture.Icon);ImageOut.Visible:=false;
ImageOut.ShowHint:=true;ImageOut.OnMouseEnter:=@Form1.CheckForHint;

DireccionesPanel := TStringGrid.Create(Form1);DireccionesPanel.Parent:=Form1;
DireccionesPanel.Left:=2;DireccionesPanel.Top:=30;DireccionesPanel.Height:=135;DireccionesPanel.Width:=396;
DireccionesPanel.ColCount:=2;DireccionesPanel.rowcount:=1;DireccionesPanel.FixedCols:=0;DireccionesPanel.FixedRows:=0;
DireccionesPanel.FixedRows:=1;
DireccionesPanel.ScrollBars:=ssVertical;
DireccionesPanel.Options:= DireccionesPanel.Options+[goRowSelect]-[goRangeSelect];
DireccionesPanel.Font.Name:='consolas'; DireccionesPanel.Font.Size:=10;
DireccionesPanel.ColWidths[0]:= 260;DireccionesPanel.ColWidths[1]:= 115;
DireccionesPanel.OnPrepareCanvas:= @Form1.Grid2PrepareCanvas;

  BCustomAddr := TSpeedButton.Create(form1);BCustomAddr.Parent:=DireccionesPanel;
  BCustomAddr.Top:=2;BCustomAddr.Left:=192;BCustomAddr.Height:=18;BCustomAddr.Width:=18;
  Form1.imagenes.GetBitmap(12,BCustomAddr.Glyph);
  BCustomAddr.Caption:='';BCustomAddr.OnClick:=@Form1.BCustomAddrOnClick;
  BCustomAddr.Hint:='Customize address';BCustomAddr.ShowHint:=true;

    PanelCustom := TPanel.Create(Form1);PanelCustom.Parent:=DireccionesPanel;
    PanelCustom.Left:=0;PanelCustom.Top:=0;PanelCustom.Height:=20;PanelCustom.Width:=250;
    PanelCustom.BevelColor:=clBlack;PanelCustom.Visible:=false;
    PanelCustom.font.Name:='consolas';PanelCustom.Font.Size:=14;
    PanelCustom.BringToFront;PanelCustom.OnMouseLeave:=@Form1.PanelCustomMouseLeave;

      EditCustom := TEdit.Create(Form1);EditCustom.Parent:=PanelCustom;EditCustom.AutoSize:=false;
      EditCustom.Left:=1;EditCustom.Top:=1;EditCustom.Height:=18;EditCustom.Width:=230;
      EditCustom.Font.Name:='consolas'; EditCustom.Font.Size:=8;
      EditCustom.Alignment:=taLeftJustify;EditCustom.Visible:=true;
      EditCustom.Color:=clBlack;EditCustom.Font.color:=clwhite;
      EditCustom.OnKeyUp :=@form1.EditCustomKeyUp;
      EditCustom.OnContextPopup:=@form1.DisablePopUpMenu;

      BOkCustom := TSpeedButton.Create(form1);BOkCustom.Parent:=PanelCustom;
      BOkCustom.Top:=1;BOkCustom.Left:=231;BOkCustom.Height:=18;BOkCustom.Width:=18;
      Form1.imagenes.GetBitmap(17,BOkCustom.Glyph);
      BOkCustom.Caption:='';
      BOkCustom.OnClick:=@Form1.BOkCustomClick;
      BOkCustom.Hint:='Confirm';BOkCustom.ShowHint:=true;

  BNewAddr := TSpeedButton.Create(form1);BNewAddr.Parent:=DireccionesPanel;
  BNewAddr.Top:=2;BNewAddr.Left:=240;BNewAddr.Height:=18;BNewAddr.Width:=18;
  Form1.imagenes.GetBitmap(6,BNewAddr.Glyph);
  BNewAddr.Caption:='';BNewAddr.OnClick:=@Form1.BNewAddrOnClick;
  BNewAddr.Hint:=LAngLine(64);BNewAddr.ShowHint:=true;                    //Generate new address

  BCopyAddr := TSpeedButton.Create(form1);BCopyAddr.Parent:=DireccionesPanel;
  BCopyAddr.Top:=2;BCopyAddr.Left:=216;BCopyAddr.Height:=18;BCopyAddr.Width:=18;
  Form1.imagenes.GetBitmap(7,BCopyAddr.Glyph);
  BCopyAddr.Caption:='';BCopyAddr.OnClick:=@Form1.BCopyAddrClick;
  BCopyAddr.Hint:=LAngLine(65);BCopyAddr.ShowHint:=true; //Copy address to clipboard

  BSendCoins := TSpeedButton.Create(form1);BSendCoins.Parent:=DireccionesPanel;
  BSendCoins.Top:=2;BSendCoins.Left:=264;BSendCoins.Height:=18;BSendCoins.Width:=18;
  Form1.imagenes.GetBitmap(8,BSendCoins.Glyph);
  BSendCoins.Caption:='';BSendCoins.OnClick:=@Form1.BSendCoinsClick;
  BSendCoins.Hint:=LangLine(66);BSendCoins.ShowHint:=true;     //Send coins

PanelSend := TPanel.Create(Form1);PanelSend.Parent:=form1;
PanelSend.Left:=2;PanelSend.Top:=30;PanelSend.Height:=135;PanelSend.Width:=396;
PanelSend.BevelColor:=clBlack;PanelSend.Visible:=false;
PanelSend.font.Name:='consolas';PanelSend.Font.Size:=14;
  // La etiqueta que identifica el panel 'send coins';
  LSCTop := TLabel.Create(nil);LSCTop.Parent := PanelSend;
  LSCTop.Top :=2;LSCTop.Left:=152;LSCTop.AutoSize:=true;       //Send coins
  LSCTop.Caption:=LangLine(66);

  BCLoseSend := TSpeedButton.Create(Form1);BCLoseSend.Parent:=PanelSend;
  BCLoseSend.Left:=377;BCLoseSend.Top:=2;
  BCLoseSend.Height:=18;BCLoseSend.Width:=18;
  Form1.imagenes.GetBitmap(14,BCLoseSend.Glyph);
  BCLoseSend.Visible:=true;BCLoseSend.OnClick:=@form1.BCLoseSendOnClick;

  SGridSC := TStringGrid.Create(Form1);SGridSC.Parent:=PanelSend;
  SGridSC.Left:=8;SGridSC.Top:=24;SGridSC.Height:=57;SGridSC.Width:=123;
  SGridSC.ColCount:=1;SGridSC.rowcount:=3;SGridSC.FixedCols:=1;SGridSC.FixedRows:=0;
  SGridSC.DefaultColWidth:=120;SGridSC.DefaultRowHeight:=18;
  SGridSC.ScrollBars:=ssnone;SGridSC.Font.Size:=9;SGridSC.Enabled := false;

  SBSCPaste := TSpeedButton.Create(nil);SBSCPaste.Parent:=PanelSend;
  SBSCPaste.Left:=132;SBSCPaste.Top:=24;SBSCPaste.Height:=18;SBSCPaste.Width:=18;
  Form1.imagenes.GetBitmap(15,SBSCPaste.Glyph);
  SBSCPaste.Visible:=true;SBSCPaste.OnClick:=@form1.SBSCPasteOnClick;
  SBSCPaste.hint:=LangLine(67);SBSCPaste.ShowHint:=true;           //Paste destination

  SBSCMax := TSpeedButton.Create(Form1);SBSCMax.Parent:=PanelSend;
  SBSCMax.Left:=132;SBSCMax.Top:=42;SBSCMax.Height:=18;SBSCMax.Width:=18;
  Form1.imagenes.GetBitmap(6,SBSCMax.Glyph);
  SBSCMax.Visible:=true;SBSCMax.OnClick:=@form1.SBSCMaxOnClick;
  SBSCMax.hint:=LangLine(68);SBSCMax.ShowHint:=true;             //Send all

  EditSCDest := TEdit.Create(Form1);EditSCDest.Parent:=PanelSend;EditSCDest.AutoSize:=false;
  EditSCDest.Left:=152;EditSCDest.Top:=24;EditSCDest.Height:=18;EditSCDest.Width:=222;
  EditSCDest.Font.Name:='consolas'; EditSCDest.Font.Size:=8;
  EditSCDest.Alignment:=taRightJustify;EditSCDest.Visible:=true;
  EditSCDest.OnChange:=@form1.EditSCDestChange;EditSCDest.OnContextPopup:=@form1.DisablePopUpMenu;

  EditSCMont := TEdit.Create(Form1);EditSCMont.Parent:=PanelSend;EditSCMont.AutoSize:=false;
  EditSCMont.Left:=152;EditSCMont.Top:=42;EditSCMont.Height:=18;EditSCMont.Width:=222;
  EditSCMont.Font.Name:='consolas'; EditSCMont.Font.Size:=8;
  EditSCMont.ReadOnly:=true;EditSCMont.Text:='0.00000000';
  EditSCMont.Alignment:=taRightJustify;EditSCMont.Visible:=true;
  EditSCMont.OnKeyPress :=@form1.EditMontoOnKeyUp;
  EditSCMont.OnChange:=@form1.EditSCMontChange;EditSCMont.OnContextPopup:=@form1.DisablePopUpMenu;

  ImgSCDest := TImage.Create(form1);ImgSCDest.Parent:=PanelSend;
  ImgSCDest.Top:=24;ImgSCDest.Left:=377;ImgSCDest.Height:=16;ImgSCDest.Width:=16;
  ImgSCDest.Visible:=true;

  ImgSCMont := TImage.Create(form1);ImgSCMont.Parent:=PanelSend;
  ImgSCMont.Top:=42;ImgSCMont.Left:=377;ImgSCMont.Height:=16;ImgSCMont.Width:=16;
  ImgSCMont.Visible:=true;

  MemoSCCon := TMemo.Create(Form1);MemoSCCon.Parent:=PanelSend;
  MemoSCCon.Left:=132;MemoSCCon.Top:=60;MemoSCCon.Height:=40;MemoSCCon.Width:=242;
  MemoSCCon.Font.Size:=10;MemoSCCon.Font.Name:='consolas';
  MemoSCCon.MaxLength:=64;
  MemoSCCon.Visible:=true;MemoSCCon.ScrollBars:=ssnone;

  SCBitClea := TBitBtn.Create(Form1);SCBitClea.Parent:=PanelSend;
  SCBitClea.Left:=11;SCBitClea.Top:=104;SCBitClea.Height:=22;SCBitClea.Width:=75;
  Form1.imagenes.GetBitmap(20,SCBitClea.Glyph);SCBitClea.Caption:=LangLine(69);    //'Clear'
  SCBitClea.Font.Name:='segoe ui';SCBitClea.Font.Size:=9;
  SCBitClea.Visible:=true;SCBitClea.OnClick:=@form1.ResetearValoresEnvio;

  SCBitSend := TBitBtn.Create(Form1);SCBitSend.Parent:=PanelSend;
  SCBitSend.Left:=160;SCBitSend.Top:=104;SCBitSend.Height:=22;SCBitSend.Width:=75;
  Form1.imagenes.GetBitmap(16,SCBitSend.Glyph);SCBitSend.Caption:=LangLine(70);         //'Send'
  SCBitSend.Font.Name:='segoe ui';SCBitSend.Font.Size:=9;
  SCBitSend.Visible:=true;SCBitSend.OnClick:=@form1.SCBitSendOnClick;

  SCBitCancel := TBitBtn.Create(Form1);SCBitCancel.Parent:=PanelSend;
  SCBitCancel.Left:=160;SCBitCancel.Top:=104;SCBitCancel.Height:=22;SCBitCancel.Width:=75;
  Form1.imagenes.GetBitmap(18,SCBitCancel.Glyph);SCBitCancel.Caption:=LangLine(71); //'Cancel'
  SCBitCancel.Font.Name:='segoe ui';SCBitCancel.Font.Size:=9;
  SCBitCancel.Visible:=false;SCBitCancel.OnClick:=@form1.SCBitCancelOnClick;

  SCBitConf := TBitBtn.Create(Form1);SCBitConf.Parent:=PanelSend;
  SCBitConf.Left:=309;SCBitConf.Top:=104;SCBitConf.Height:=22;SCBitConf.Width:=75;
  Form1.imagenes.GetBitmap(16,SCBitConf.Glyph);SCBitConf.Caption:=LangLine(72);       //'Confirm'
  SCBitConf.Font.Name:='segoe ui';SCBitConf.Font.Size:=9;
  SCBitConf.Visible:=false;SCBitConf.OnClick:=@form1.SCBitConfOnClick;

GridMyTxs := TStringGrid.Create(Form1);GridMyTxs.Parent:=Form1;
GridMyTxs.Left:=2;GridMyTxs.Top:=170;GridMyTxs.Height:=135;GridMyTxs.Width:=396;
GridMyTxs.ColCount:=11;GridMyTxs.rowcount:=1;GridMyTxs.FixedCols:=0;GridMyTxs.FixedRows:=1;
GridMyTxs.ScrollBars:=ssVertical;
GridMyTxs.Options:= GridMyTxs.Options+[goRowSelect]-[goRangeSelect];
GridMyTxs.Font.Name:='consolas'; GridMyTxs.Font.Size:=10;
GridMyTxs.ColWidths[0]:= 60;GridMyTxs.ColWidths[1]:= 60;GridMyTxs.ColWidths[2]:= 100;
GridMyTxs.ColWidths[3]:= 155;
GridMyTxs.OnPrepareCanvas:= @Form1.GridMyTxsPrepareCanvas;

  BitInfoTrx := TSpeedButton.Create(Form1);BitInfoTrx.Parent:=GridMyTxs;
  BitInfoTrx.Left:=224;BitInfoTrx.Top:=2;BitInfoTrx.Height:=18;BitInfoTrx.Width:=18;
  Form1.imagenes.GetBitmap(13,BitInfoTrx.Glyph);
  BitInfoTrx.Visible:=true;BitInfoTrx.OnClick:=@form1.GridMyTxsOnDoubleClick;
  BitInfoTrx.hint:=LangLine(73);BitInfoTrx.ShowHint:=true; //'Transaction details'

PanelTrxDetails := TPanel.Create(Form1);PanelTrxDetails.Parent:=form1;
PanelTrxDetails.Left:=2;PanelTrxDetails.Top:=170;PanelTrxDetails.Height:=135;PanelTrxDetails.Width:=396;
PanelTrxDetails.BevelColor:=clBlack;PanelTrxDetails.Visible:=false;
PanelTrxDetails.font.Name:='consolas';PanelTrxDetails.Font.Size:=14;

   MemoTrxDetails := TMemo.Create(Form1);MemoTrxDetails.Parent:=PanelTrxDetails;
   MemoTrxDetails.Font.Size:=10;MemoTrxDetails.ReadOnly:=true;
   MemoTrxDetails.Color:=clForm;MemoTrxDetails.BorderStyle:=bsNone;
   MemoTrxDetails.Height:=115;MemoTrxDetails.Width:=381;
   MemoTrxDetails.Font.Name:='consolas';MemoTrxDetails.Alignment:=taLeftJustify;
   MemoTrxDetails.Left:=5;MemoTrxDetails.Top:=10;MemoTrxDetails.AutoSize:=false;

   BCloseTrxDetails := TbitBtn.Create(Form1);BCloseTrxDetails.Parent:=PanelTrxDetails;
   BCloseTrxDetails.Left:=377;BCloseTrxDetails.Top:=2;
   BCloseTrxDetails.Height:=18;BCloseTrxDetails.Width:=18;
   Form1.imagenes.GetBitmap(14,BCloseTrxDetails.Glyph);BCloseTrxDetails.Caption:='';
   BCloseTrxDetails.BiDiMode:= bdRightToLeft;
   BCloseTrxDetails.Visible:=true;BCloseTrxDetails.OnClick:=@form1.BCloseTrxDetailsOnClick;

PanelScrow := TPanel.Create(Form1);PanelScrow.Parent:=form1;
PanelScrow.Left:=2;PanelScrow.Top:=307;PanelScrow.Height:=181;PanelScrow.Width:=396;
PanelScrow.BevelColor:=clBlack;PanelScrow.Visible:=true;
PanelScrow.font.Name:='consolas';PanelScrow.Font.Size:=14;

   BScrowSell := TButton.Create(Form1);BScrowSell.Parent:=PanelScrow;
   BScrowSell.Left:=2;BScrowSell.Top:=2;
   BScrowSell.Height:=18;BScrowSell.Width:=50;
   BScrowSell.Caption:='Sell';BScrowSell.Font.Name:='candaras';BScrowSell.Font.Size:=8;
   BScrowSell.Visible:=true;//BScrowSell.OnClick:=@form1.BScrowSellOnClick;

   BScrowBuy := TButton.Create(Form1);BScrowBuy.Parent:=PanelScrow;
   BScrowBuy.Left:=62;BScrowBuy.Top:=2;
   BScrowBuy.Height:=18;BScrowBuy.Width:=50;
   BScrowBuy.Caption:='Buy';BScrowBuy.Font.Name:='consolas';BScrowBuy.Font.Size:=8;
   BScrowBuy.Visible:=true;//BScrowBuy.OnClick:=@form1.BScrowBuyOnClick;

   GridScrowSell := TStringGrid.Create(Form1);GridScrowSell.Parent:=PanelScrow;
   GridScrowSell.Left:=2;GridScrowSell.Top:=22;GridScrowSell.Height:=157;GridScrowSell.width:=392;
   GridScrowSell.FixedCols:=0;GridScrowSell.FixedRows:=1;
   GridScrowSell.rowcount := 1;GridScrowSell.ColCount:=5;
   GridScrowSell.ScrollBars:=ssVertical;
   GridScrowSell.Options:= GridScrowSell.Options+[goRowSelect]-[goRangeSelect];
   GridScrowSell.ColWidths[0]:= 75;GridScrowSell.ColWidths[1]:= 75;GridScrowSell.ColWidths[2]:= 75;
   GridScrowSell.ColWidths[3]:= 75;GridScrowSell.ColWidths[4]:= 71;
   GridScrowSell.Font.Name:='consolas'; GridScrowSell.Font.Size:=8;

   //GridScrowSell.OnPrepareCanvas:= @Form1.GridScrowSellPrepareCanvas;
   //GridScrowSell.OnDblClick:= @Form1.GridScrowSellOnDoubleClick;

InfoPanel := TPanel.Create(Form1);InfoPanel.Parent:=form1;
InfoPanel.Font.Name:='consolas';InfoPanel.Font.Size:=8;
InfoPanel.Left:=100;InfoPanel.AutoSize:=false;
InfoPanel.Color:=clMedGray;
InfoPanel.Top:=245;InfoPanel.Font.Color:=clBlack;
InfoPanel.Width:=200;InfoPanel.Height:=20;InfoPanel.Alignment:=tacenter;
InfoPanel.Caption:='';InfoPanel.Visible:=false;

OptionsPanel := TPanel.Create(Form1);OptionsPanel.Parent:=form1;
OptionsPanel.Left:=2;OptionsPanel.Top:=307;OptionsPanel.Height:=181;OptionsPanel.Width:=396;
OptionsPanel.BevelColor:=clBlack;OptionsPanel.Visible:=false;
OptionsPanel.font.Name:='consolas';OptionsPanel.Font.Size:=14;

  LabelNodes := TLabel.Create(nil);LabelNodes.Parent := OptionsPanel;
  LabelNodes.Top :=2;LabelNodes.Left:=2;LabelNodes.AutoSize:=true;
  LabelNodes.Caption:='Nodes';

  GridNodes := TStringGrid.Create(Form1);GridNodes.Parent:=OptionsPanel;
  GridNodes.Left:=2;GridNodes.Top:=22;GridNodes.Height:=136;GridNodes.Width:=172;
  GridNodes.ColCount:=2;GridNodes.rowcount:=1;GridNodes.FixedCols:=0;GridNodes.FixedRows:=1;
  GridNodes.Options:= GridNodes.Options+[goRowSelect]-[goRangeSelect];
  GridNodes.ScrollBars:=ssvertical;
  GridNodes.ColWidths[0]:= 100;GridNodes.ColWidths[1]:= 50;
  GridNodes.font.Name:='consolas';GridNodes.Font.Size:=8;

    SBDelNode := TSpeedButton.Create(Form1);SBDelNode.Parent:=GridNodes;
    SBDelNode.Left:=78;SBDelNode.Top:=0;SBDelNode.Height:=18;SBDelNode.Width:=18;
    Form1.imagenes.GetBitmap(23,SBDelNode.Glyph);
    SBDelNode.Visible:=true;SBDelNode.OnClick:=@form1.SBDelNodeOnClick;
    SBDelNode.hint:='Delete node';SBDelNode.ShowHint:=true;

  EditIP := TEdit.Create(Form1);EditIP.Parent:=OptionsPanel;EditIP.AutoSize:=false;
  EditIP.Left:=2;EditIP.Top:=160;EditIP.Height:=18;EditIP.Width:=100;
  EditIP.Font.Name:='consolas'; EditIP.Font.Size:=8;
  EditIP.Color:=clBlack;EditIP.Font.color:=clwhite;
  EditIP.Alignment:=taRightJustify;EditIP.Visible:=true;
  EditIP.OnContextPopup:=@form1.DisablePopUpMenu;

  EditPort := TEdit.Create(Form1);EditPort.Parent:=OptionsPanel;EditPort.AutoSize:=false;
  EditPort.Left:=102;EditPort.Top:=160;EditPort.Height:=18;EditPort.Width:=50;
  EditPort.Font.Name:='consolas'; EditPort.Font.Size:=8;
  EditPort.Color:=clBlack;EditPort.Font.color:=clwhite;
  EditPort.Alignment:=taRightJustify;EditPort.Visible:=true;
  EditPort.OnContextPopup:=@form1.DisablePopUpMenu;

  SBNewNode := TSpeedButton.Create(Form1);SBNewNode.Parent:=OptionsPanel;
  SBNewNode.Left:=154;SBNewNode.Top:=160;SBNewNode.Height:=18;SBNewNode.Width:=18;
  Form1.imagenes.GetBitmap(6,SBNewNode.Glyph);
  SBNewNode.Visible:=true;SBNewNode.OnClick:=@form1.SBNewNodeOnClick;
  SBNewNode.hint:='Add new node';SBNewNode.ShowHint:=true;

  LabelOptions := TLabel.Create(nil);LabelOptions.Parent := OptionsPanel;
  LabelOptions.Top :=2;LabelOptions.Left:=176; LabelOptions.AutoSize:=true;
  LabelOptions.Caption:='Options';

  OptionsScroll := TScrollBox.Create(Form1);OptionsScroll.Parent:=OptionsPanel;
  OptionsScroll.Left:=176;OptionsScroll.Top:=22;OptionsScroll.Height:=156;
  OptionsScroll.Width:=218;
  OptionsScroll.Color:=clWhite;
  OptionsScroll.Visible:=true;

    GridOptions := TStringGrid.Create(Form1);GridOptions.Parent:=OptionsScroll;
    GridOptions.Left:=2;GridOptions.Top:=2;GridOptions.Height:=202;GridOptions.Width:=192;
    GridOptions.DefaultColWidth:= 80;GridOptions.DefaultRowHeight:=20;
    GridOptions.ColCount:=2;GridOptions.rowcount:=10;GridOptions.FixedCols:=1;GridOptions.FixedRows:=0;
    GridOptions.Options:= GridOptions.Options+[goRowSelect]-[goRangeSelect];
    GridOptions.ScrollBars:=ssnone;GridOptions.enabled:= false;
    GridOptions.font.Name:='consolas';GridOptions.Font.Size:=8;
    GridOptions.ColWidths[0]:= 110;GridOptions.ColWidths[1]:= 80;

      LangSelect := TComboBox.Create(form1);LangSelect.Parent :=OptionsScroll ;
      LangSelect.Font.Name:='candara';LangSelect.Font.Size:=8;
      LangSelect.Left:=114;LangSelect.Top:=2;
      LangSelect.Height:=12;LangSelect.Width:=80;
      LangSelect.Style:=csDropDownList ;
      LangSelect.OnChange:=@form1.LangSelectOnChange;

      EditMyPort := TEdit.Create(Form1);EditMyPort.Parent:=OptionsScroll;EditMyPort.AutoSize:=false;
      EditMyPort.Left:=114;EditMyPort.Top:=22;EditMyPort.Height:=20;EditMyPort.Width:=80;
      EditMyPort.Font.Name:='consolas'; EditMyPort.Font.Size:=8;
      EditMyPort.Color:=clBlack;EditMyPort.Font.color:=clwhite;
      EditMyPort.Alignment:=taRightJustify;EditMyPort.Visible:=true;
      EditMyPort.OnContextPopup:=@form1.DisablePopUpMenu;

      EditMaxpeer := TEdit.Create(Form1);EditMaxpeer.Parent:=OptionsScroll;EditMaxpeer.AutoSize:=false;
      EditMaxpeer.Left:=114;EditMaxpeer.Top:=42;EditMaxpeer.Height:=20;EditMaxpeer.Width:=80;
      EditMaxpeer.Font.Name:='consolas'; EditMaxpeer.Font.Size:=8;
      EditMaxpeer.Color:=clBlack;EditMaxpeer.Font.color:=clwhite;
      EditMaxpeer.Alignment:=taRightJustify;EditMaxpeer.Visible:=true;
      EditMaxpeer.Enabled:=false;
      EditMaxpeer.OnContextPopup:=@form1.DisablePopUpMenu;

      EditMinpeer := TEdit.Create(Form1);EditMinpeer.Parent:=OptionsScroll;EditMinpeer.AutoSize:=false;
      EditMinpeer.Left:=114;EditMinpeer.Top:=62;EditMinpeer.Height:=20;EditMinpeer.Width:=80;
      EditMinpeer.Font.Name:='consolas'; EditMinpeer.Font.Size:=8;
      EditMinpeer.Color:=clBlack;EditMinpeer.Font.color:=clwhite;
      EditMinpeer.Alignment:=taRightJustify;EditMinpeer.Visible:=true;
      EditMinpeer.OnContextPopup:=@form1.DisablePopUpMenu;

      CBGetNodes :=TcheckBox.Create(form1);CBGetNodes.Parent:=OptionsScroll;
      CBGetNodes.AutoSize:=false;
      CBGetNodes.Left:=176;CBGetNodes.Top:=86;CBGetNodes.Height:=14;CBGetNodes.Width:=14;
      CBGetNodes.Visible:=true;CBGetNodes.OnChange:=@Form1.CBGetNodesOnChange;

      CBAutoserver :=TcheckBox.Create(form1);CBAutoserver.Parent:=OptionsScroll;
      CBAutoserver.AutoSize:=false;
      CBAutoserver.Left:=176;CBAutoserver.Top:=106;CBAutoserver.Height:=14;CBAutoserver.Width:=14;
      CBAutoserver.Visible:=true;CBAutoserver.OnChange:=@Form1.CBAutoserverOnChange;

      CBAutoConnect :=TcheckBox.Create(form1);CBAutoConnect.Parent:=OptionsScroll;
      CBAutoConnect.AutoSize:=false;
      CBAutoConnect.Left:=176;CBAutoConnect.Top:=126;CBAutoConnect.Height:=14;CBAutoConnect.Width:=14;
      CBAutoConnect.Visible:=true;CBAutoConnect.OnChange:=@Form1.CBAutoConnectOnChange;

      CBAutoUpdate :=TcheckBox.Create(form1);CBAutoUpdate.Parent:=OptionsScroll;
      CBAutoUpdate.AutoSize:=false;
      CBAutoUpdate.Left:=176;CBAutoUpdate.Top:=146;CBAutoUpdate.Height:=14;CBAutoUpdate.Width:=14;
      CBAutoUpdate.Visible:=true;CBAutoUpdate.OnChange:=@Form1.CBAutoUpdateOnChange;

      CBToTray :=TcheckBox.Create(form1);CBToTray.Parent:=OptionsScroll;
      CBToTray.AutoSize:=false;
      CBToTray.Left:=176;CBToTray.Top:=186;CBToTray.Height:=14;CBToTray.Width:=14;
      CBToTray.Visible:=true;CBToTray.OnChange:=@Form1.CBToTrayOnChange;

//Elementos no visuales
ProcessLines := TStringlist.Create;
OutgoingMsjs := TStringlist.Create;
Setlength(PendingTXs,0);
For contador := 1 to MaxConecciones do
   begin
   SlotLines[contador] := TStringlist.Create;
   CanalCliente[contador] := TIdTCPClient.Create(form1);
   end;
Form1.Latido:= TTimer.Create(Form1);
Form1.Latido.Enabled:=false;Form1.Latido.Interval:=200;
Form1.Latido.OnTimer:= @form1.LatidoEjecutar;

Form1.InfoTimer:= TTimer.Create(Form1);
Form1.InfoTimer.Enabled:=false;Form1.InfoTimer.Interval:=10;
Form1.InfoTimer.OnTimer:= @form1.InfoTimerEnd;

form1.SystrayIcon := TTrayIcon.Create(form1);
form1.SystrayIcon.BalloonTimeout:=3000;
form1.SystrayIcon.BalloonTitle:=CoinName+' Wallet';
form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion;
form1.SysTrayIcon.OnDblClick:=@form1.DoubleClickSysTray;
form1.imagenes.GetIcon(39,form1.SystrayIcon.icon);

Form1.Server := TIdTCPServer.Create(Form1);
Form1.Server.DefaultPort:=DefaultServerPort;
Form1.Server.Active:=false;
Form1.Server.UseNagle:=true;
Form1.Server.TerminateWaitTime:=5000;
Form1.Server.OnExecute:=@form1.IdTCPServer1Execute;
Form1.Server.OnConnect:=@form1.IdTCPServer1Connect;
Form1.Server.OnDisconnect:=@form1.IdTCPServer1Disconnect;
Form1.Server.OnException:=@Form1.IdTCPServer1Exception;
End;

// Funciones del servidor.

// Recibir una linea
procedure TForm1.IdTCPServer1Execute(AContext: TIdContext);
var
  LLine : String = '';
  IPUser : String = '';
  slot : integer = 0;
  UpdateZipName : String = ''; UpdateVersion : String = ''; UpdateHash:string ='';
  UpdateClavePublica :string ='';UpdateFirma : string = '';
  AFileStream : TFileStream;
  BlockZipName: string = '';

Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
LLine := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
slot := GetSlotFromIP(IPUser);
if slot = 0 then exit;
if GetCommand(LLine) = 'UPDATE' then
   begin
   UpdateVersion := Parameter(LLine,1);
   UpdateHash := Parameter(LLine,2);
   UpdateClavePublica := Parameter(LLine,3);
   UpdateFirma := Parameter(LLine,4);
   UpdateZipName := 'mpupdate'+UpdateVersion+'.zip';
   if FileExists(UpdateZipName) then DeleteFile(UpdateZipName);
   AFileStream := TFileStream.Create(UpdateZipName, fmCreate);
   AContext.Connection.IOHandler.ReadStream(AFileStream);
   AFileStream.Free;
   CheckIncomingUpdateFile(UpdateVersion,UpdateHash,UpdateClavePublica,UpdateFirma,UpdateZipName);
   end
else if GetCommand(LLine) = 'RESUMENFILE' then
   begin
   AFileStream := TFileStream.Create(ResumenFilename, fmCreate);
   AContext.Connection.IOHandler.ReadStream(AFileStream);
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
   AContext.Connection.IOHandler.ReadStream(AFileStream);
   AFileStream.Free;
   UnzipBlockFile(BlockDirectory+'blocks.zip',true);
   MyLastBlock := GetMyLastUpdatedBlock();
   BuildHeaderFile();
   ResetMinerInfo();
   LastTimeRequestBlock := 0;
   end
else
   try
   SlotLines[slot].Add(LLine);
   Except
   On E :Exception do Consolelines.Add(LangLine(7)+LLine); // Error receiving line:
   end;
End;

// Un usuario intenta conectarse
procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
var
  IPUser : string;
  LLine : String;
  MiIp: String = '';
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
LLine := AContext.Connection.IOHandler.ReadLn('',200,-1,IndyTextEncoding_UTF8);
if Copy(LLine,1,4) <> 'PSK ' then  // La linea no contiene un comando valido
   begin
   Consolelines.Add(LangLine(8)+IPUser);     //INVALID CLIENT :
   AContext.Connection.Disconnect;
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   UpdateBotData(IPUser);
   S_BotData := true;
   exit;
   end
else
   begin
   MiIp := Parameter(LLine,1);
   if IPUser = MyPublicIP then // Nos estamos conectando con nosotros mismos
      begin
      ConsoleLines.Add(LangLine(9));  //INCOMING CLOSED: OWN CONNECTION
      AContext.Connection.Disconnect;
      Acontext.Connection.IOHandler.InputBuffer.Clear;
      UpdateBotData(IPUser);
      exit;
      end;
   end;
if BotExists(IPUser) then // Es un bot ya conocido
   begin
   ConsoleLines.Add(LAngLine(10)+IPUser);             //BLACKLISTED FROM:
   AContext.Connection.Disconnect;
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   UpdateBotData(IPUser);
   exit;
   end;
if GetSlotFromIP(IPUser) > 0 then // Conexion duplicada
   begin
   ConsoleLines.Add(LangLine(11)+IPUser);              //DUPLICATE REJECTED:
   AContext.Connection.Disconnect;
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   exit;
   end;
if SaveConection('CLI',IPUser,Acontext) = 0 then   // Servidor lleno
   begin
   AContext.Connection.IOHandler.WriteLn(GetNodesString);
   AContext.Connection.Disconnect;
   ConsoleLines.Add(LangLine(12)+IPUser);           //Server full. Unable to keep conection:
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   end
else
   begin    // Se acepta la nueva conexion
   ConsoleLines.Add(LangLine(13)+IPUser);             //New Connection from:
   If UserOptions.GetNodes then
      Acontext.Connection.IOHandler.WriteLn(ProtocolLine(getnodes));
   MyPublicIP := MiIp;
   U_DataPanel := true;
   end;

End;

// Un cliente se desconecta del servidor
procedure TForm1.IdTCPServer1Disconnect(AContext: TIdContext);
var
  IPUser : string;
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
Acontext.Connection.IOHandler.InputBuffer.Clear;
BorrarSlot('CLI',ipuser);
End;

// Excepcion en el servidor
procedure TForm1.IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
Begin
ConsoleLines.Add(LangLine(6)+AException.Message);    //Server Excepcion:
End;

// DOUBLE CLICK TRAY ICON TO RESTORE
Procedure TForm1.DoubleClickSysTray(Sender: TObject);
Begin
SysTrayIcon.visible:=false;
Form1.WindowState:=wsNormal;
Form1.Show;
End;

// Click en conectar
Procedure TForm1.ConnectCircleOnClick(Sender: TObject);
Begin
if Form1.Server.Active then
   begin
   ProcessLines.Add('serveroff');
   ProcessLines.Add('disconnect');
   end
else if (not Form1.Server.Active) and (CONNECT_Try) then
   ProcessLines.Add('disconnect')
else
   begin
   ProcessLines.Add('serveron');
   ProcessLines.Add('connect');
   end;
End;

// click en el boton de minar
Procedure Tform1.MinerCircleOnClick(Sender: TObject);
Begin
if Miner_Active then
   begin
   ProcessLines.Add('mineroff');
   end
else
   begin
   ProcessLines.Add('mineron');
   end;
End;

// Cambiar el idiomar por combobox
Procedure Tform1.LangSelectOnChange(Sender: TObject);
Begin
if LangSelect.Items[LangSelect.ItemIndex] <> CurrentLanguage then
   ProcessLines.Add('lang '+IntToStr(LangSelect.ItemIndex ));
End;

// Mostrar los detalles de una transaccion
Procedure TForm1.GridMyTxsOnDoubleClick(Sender: TObject);
var
  cont : integer;
  extratext :string = '';
Begin
if GridMyTxs.Row>0 then
   begin
   PanelTrxDetails.visible := true;
   BCloseTrxDetails.Visible:=true;
   MemoTrxDetails.Lines.Clear;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'TRFR' then
      Begin
      if GridMyTxs.Cells[10,GridMyTxs.Row] = 'YES' then // Own transaction'
        extratext :=LangLine(75); //' (OWN)'
      MemoTrxDetails.Text:=
      GridMyTxs.Cells[4,GridMyTxs.Row]+SLINEBREAK+                    //order ID
      LangLine(76)+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+      //'Receiver : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row]+extratext+SLINEBREAK+  //'Ammount  : '
      LangLine(78)+GridMyTxs.Cells[7,GridMyTxs.Row]+SLINEBREAK+    //'Concept  : '
      LangLine(79)+GridMyTxs.Cells[9,GridMyTxs.Row]+SLINEBREAK+      //'Transfers: '
      GetCommand(GridMyTxs.Cells[8,GridMyTxs.Row])+SLINEBREAK;
      if StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1)> 1 then // añadir mas trfids
         for cont := 2 to StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1) do
           MemoTrxDetails.lines.add(parameter(GridMyTxs.Cells[8,GridMyTxs.Row],cont-1));
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'MINE' then
      Begin
      MemoTrxDetails.Text:=
      LangLine(80)+GridMyTxs.Cells[0,GridMyTxs.Row]+SLINEBREAK+ //'Mined    : '
      LangLine(76)+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+   //'Receiver : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row];   //'Ammount  : '
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'CUSTOM' then
      Begin
      MemoTrxDetails.Text:=
      LangLine(81)+SLINEBREAK+                   //'Address customization'
      LangLine(82)+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Hash+SLINEBREAK+//'Address  : '
      LangLine(83)+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Custom;//'Alias    : '
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'FEE' then
      begin
      MemoTrxDetails.Text:=
      LangLine(84)+SLINEBREAK+   //'Maintenance fee'
      LangLine(82)+GridMyTxs.Cells[6,GridMyTxs.Row]+SLINEBREAK+  //'Address  : '
      LangLine(85)+GridMyTxs.Cells[7,GridMyTxs.Row]+SLINEBREAK+  //'Interval : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row]; //'Ammount  : '
      if GridMyTxs.Cells[8,GridMyTxs.Row] = 'YES' then
        MemoTrxDetails.Text:= MemoTrxDetails.Text+LangLine(86);//' (Address deleted from summary)'
      end;
   end;
MemoTrxDetails.SelStart:=0;

End;

// Cierra el panel de detalle de transacciones
Procedure TForm1.BCloseTrxDetailsOnClick(Sender: TObject);
Begin
PanelTrxDetails.visible := false;
End;

// Mostrar el panel de personalizacion
Procedure TForm1.BCustomAddrOnClick(Sender: TObject);
var
  Address : string;
Begin
Address := DireccionesPanel.Cells[0,DireccionesPanel.Row];
if not IsValidAddress(address) then info('Address already customized')
else if AddressAlreadyCustomized(address) then info('Address already customized')
else if GetAddressBalance(Address)-GetAddressPendingPays(address)< Customizationfee then info('Insufficient funds')
else
   begin
   PanelCustom.Visible := true;
   PanelCustom.BringToFront;
   EditCustom.SetFocus;
   end;
End;

Procedure Tform1.EditCustomKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
Begin
if Key=VK_RETURN then
   begin
   ProcessLines.Add('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
   PanelCustom.Visible := false;
   EditCustom.Text := '';
   end;
End;

// Aceptar la personalizacion
Procedure TForm1.BOkCustomClick(Sender: TObject);
Begin
ProcessLines.Add('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
PanelCustom.Visible := false;
EditCustom.Text := '';
End;

// Cerrar el panel de personalizacion cuando el boton sale de el
Procedure TForm1.PanelCustomMouseLeave(Sender: TObject);
Begin
PanelCustom.Visible := false;

End;

// El boton para crear una nueva direccion
Procedure TForm1.BNewAddrOnClick(Sender: TObject);
Begin
ProcessLines.Add('newaddress');
End;

// Copia el hash de la direccion al portapapeles
Procedure TForm1.BCopyAddrClick(Sender: TObject);
Begin
Clipboard.AsText:= ListaDirecciones[DireccionesPanel.Row-1].Hash;
info(LangLine(87));//'Copied to clipboard'
End;

// Abre el panel para enviar coins
Procedure TForm1.BSendCoinsClick(Sender: TObject);
Begin
PanelSend.Visible:=true;
End;

// Cerrar el panel de envio de dinero
Procedure Tform1.BCLoseSendOnClick(Sender: TObject);
Begin
PanelSend.Visible:=false;
End;

// Cada miniciclo del infotimer
Procedure TForm1.InfoTimerEnd(Sender: TObject);
Begin
InfoPanelTime := InfoPanelTime-10;
if InfoPanelTime <= 0 then
  begin
  InfoPanel.Caption:='';
  InfoPanel.Visible:=false;
  Infotimer.Enabled:=false;
  end;
end;

// Procesa el hint a mostrar segun el control
Procedure TForm1.CheckForHint(Sender:TObject);
Begin
Processhint(sender);
End;

// Pegar en el edit de destino de envio de coins
Procedure TForm1.SBSCPasteOnClick(Sender:TObject);
Begin
EditSCDest.SetFocus;
EditSCDest.Text:=Clipboard.AsText;
EditSCDest.SelStart:=length(EditSCDest.Text);
End;

// Pegar el monto maximo en su edit
Procedure TForm1.SBSCMaxOnClick(Sender:TObject);
Begin
EditSCMont.Text:=Int2curr(GetMaximunToSend);
End;

// verifica el destino que marca para enviar coins
Procedure Tform1.EditSCDestChange(Sender:TObject);
Begin
EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
if IsValidAddress(EditSCDest.Text) then
  Form1.imagenes.GetIcon(17,ImgSCDest.Picture.Icon)
else Form1.imagenes.GetIcon(14,ImgSCDest.Picture.Icon);
if EditSCDest.Text = '' then ImgSCDest.Picture.Clear;
End;

// Modificar el monto a enviar
Procedure TForm1.EditMontoOnKeyUp(Sender: TObject; var Key: char);
var
  Permitido : string = '1234567890';
  Ultimo    : char;
  Actualmente : string;
  currpos : integer;
  ParteEntera : string;
  ParteDecimal : string;
  PosicionEnElPunto : integer;
Begin
if key = chr(27) then
  begin
  EditSCMont.Text := '0.00000000';
  EditSCMont.SelStart := 1;
  exit;
  end;
ultimo := char(key);
if pos(ultimo,permitido)= 0 then exit;
Actualmente := EditSCMont.Text;
PosicionEnElPunto := Length(Actualmente)-9;
currpos := EditSCMont.SelStart;
if EditSCMont.SelStart > length(EditSCMont.Text)-9 then // Es un decimal
   begin
   Actualmente[currpos+1] := ultimo;
   EditSCMont.Text:=Actualmente;
   EditSCMont.SelStart := currpos+1;
   end;
if EditSCMont.SelStart <= length(EditSCMont.Text)-9 then // Es un decimal
   begin
   ParteEntera := copy(actualmente,1,length(Actualmente)-9);
   ParteDecimal := copy(actualmente,length(Actualmente)-7,8);
   if currpos = PosicionEnElPunto then // esta justo antes del punto
      begin
      if length(parteentera)>7 then exit;
      ParteEntera := ParteEntera+Ultimo;
      ParteEntera := IntToStr(StrToInt(ParteEntera));
      actualmente := parteentera+'.'+partedecimal;
      EditSCMont.Text:=Actualmente;
      EditSCMont.SelStart := Length(Actualmente)-9;
      end
   else
      begin
      Actualmente[currpos+1] := ultimo;
      ParteEntera := copy(actualmente,1,length(Actualmente)-9);
      ParteEntera := IntToStr(StrToInt(ParteEntera));
      actualmente := parteentera+'.'+partedecimal;
      EditSCMont.Text:=Actualmente;
      EditSCMont.SelStart := currpos+1;
      if ((currpos=0) and (ultimo='0')) then EditSCMont.SelStart := 0;
      end;
   end;
End;

// verifica el monto que se marca para enviar coins
Procedure Tform1.EditSCMontChange(Sender:TObject);
Begin
if ((StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)>0) and
   (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)<=GetMaximunToSend))then
  begin
  Form1.imagenes.GetIcon(17,ImgSCMont.Picture.Icon);
  end
else Form1.imagenes.GetIcon(14,ImgSCMont.Picture.Icon);
if EditSCMont.Text = '0.00000000' then ImgSCMont.Picture.Clear;
End;

// Desactiva el menu popup de un control
Procedure TForm1.DisablePopUpMenu(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
Handled := True;
End;

// Cancelar el envio
Procedure Tform1.SCBitCancelOnClick(Sender:TObject);
Begin
EditSCDest.Enabled:=true;
EditSCMont.Enabled:=true;
MemoSCCon.Enabled:=true;
SCBitSend.Visible:=true;
SCBitConf.Visible:=false;
SCBitCancel.Visible:=false;
End;

// enviar el dinero
Procedure Tform1.SCBitSendOnClick(Sender:TObject);
Begin
if ((IsValidAddress(EditSCDest.Text)) and (((StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)>0) and
   (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)<=GetMaximunToSend)))) then
   begin
   MemoSCCon.Text:=GetCommand(MemoSCCon.text);
   EditSCDest.Enabled:=false;
   EditSCMont.Enabled:=false;
   MemoSCCon.Enabled:=false;
   SCBitSend.Visible:=false;
   SCBitConf.Visible:=true;
   SCBitCancel.Visible:=true;
   end;
End;

// confirmar el envio con los valores
Procedure Tform1.SCBitConfOnClick(Sender:TObject);
Begin
ProcessLines.Add('SENDTO '+EditSCDest.Text+' '+StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]));
ResetearValoresEnvio(Sender);
End;

// Resetear los valores de envio
Procedure TForm1.ResetearValoresEnvio(Sender:TObject);
Begin
EditSCDest.Enabled:=true;EditSCDest.Text:='';
EditSCMont.Enabled:=true;EditSCMont.Text:='0.00000000';
MemoSCCon.Enabled:=true;MemoSCCon.Text:='';
SCBitSend.Visible:=true;
SCBitConf.Visible:=false;
SCBitCancel.Visible:=false;
End;

// Mostrar/ocultar opciones
Procedure Tform1.SBOptionsOnClick(Sender:TObject);
Begin
If OptionsPanel.Visible then optionspanel.Visible:=false
else optionspanel.Visible:=true;
LoadOptionsToPanel();
End;

Procedure Tform1.SBDelNodeOnClick(Sender:TObject);
Begin
Processlines.Add('DELNODE '+IntToStr(Gridnodes.row-1));
End;

Procedure Tform1.SBNewNodeOnClick(Sender:TObject);
Begin
Processlines.Add('ADDNODE '+EditIP.Text+' '+EditPort.Text);
EditIP.Text := '';EditPort.Text := '';
End;

// ACTIVA/DESACTIVA GETNODES
Procedure TForm1.CBGetNodesOnChange(Sender:TObject);
Begin
if G_Launching then exit;
If UserOptions.GetNodes then Processlines.Add('GETNODESOFF')
else Processlines.Add('GETNODESON');
End;

Procedure TForm1.CBAutoserverOnChange(Sender:TObject);
Begin
if G_Launching then exit;
If UserOptions.AutoServer then Processlines.Add('AUTOSERVEROFF')
else Processlines.Add('AUTOSERVERON');
End;

Procedure TForm1.CBAutoConnectOnChange(Sender:TObject);
Begin
if G_Launching then exit;
If UserOptions.AutoConnect then Processlines.Add('AUTOCONNECTOFF')
else Processlines.Add('AUTOCONNECTON');
End;

Procedure TForm1.CBAutoUpdateOnChange(Sender:TObject);
Begin
if G_Launching then exit;
If UserOptions.Auto_Updater then Processlines.Add('AUTOUPDATEOFF')
else Processlines.Add('AUTOUPDATEON');
End;

Procedure TForm1.CBToTrayOnChange(Sender:TObject);
Begin
if G_Launching then exit;
If UserOptions.ToTray then Processlines.Add('TOTRAYOFF')
else Processlines.Add('TOTRAYON');
End;

//******************************************************************************
// MAINMENU
//******************************************************************************

Procedure Tform1.CheckMMCaptions(Sender:TObject);
var
  contador: integer;
Begin
if Form1.Server.Active then MainMenu.Items[0].Items[0].Caption:='Stop Server'
else MainMenu.Items[0].Items[0].Caption:='Start Server';
if CONNECT_Try then MainMenu.Items[0].Items[1].Caption:='Disconnect'
else MainMenu.Items[0].Items[1].Caption:='Connect';
if Miner_Active then MainMenu.Items[0].Items[2].Caption:='Stop mining'
else MainMenu.Items[0].Items[2].Caption:='Mine';
MainMenu.Items[1].Items[0].Clear;
for contador := 0 to LangSelect.Items.Count-1 do
  begin
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:=LangSelect.Items[contador];MenuItem.OnClick:=@Form1.MMChangeLang;
  if LangSelect.Items[contador] = 'English' then Form1.imagenes.GetBitmap(36,MenuItem.bitmap);
  if LangSelect.Items[contador] = 'Español' then Form1.imagenes.GetBitmap(37,MenuItem.bitmap);
  if LangSelect.Items[contador] = 'Polskie' then Form1.imagenes.GetBitmap(38,MenuItem.bitmap);
  MainMenu.items[1].Items[0].Add(MenuItem);
  end;
End;

Procedure Tform1.MMServer(Sender:TObject);
Begin
if Form1.Server.Active then ProcessLines.Add('serveroff')
else ProcessLines.Add('serveron');
End;

Procedure Tform1.MMConnect(Sender:TObject);
Begin
if CONNECT_Try then ProcessLines.Add('disconnect')
else ProcessLines.Add('connect');
End;

Procedure Tform1.MMMiner(Sender:TObject);
Begin
if Miner_Active then ProcessLines.Add('mineroff')
else ProcessLines.Add('mineron');
End;

Procedure Tform1.MMImpWallet (Sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Import Wallet','*.pkw','impwallet (-resultado-)',true);
End;

Procedure Tform1.MMExpWallet(Sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Export Wallet to','*.pkw','expwallet (-resultado-)',false);
End;

Procedure Tform1.MMQuit(Sender:TObject);
Begin
Application.Terminate;
End;

Procedure Tform1.MMChangeLang(Sender:TObject);
var
  valor : integer;
Begin
valor := (sender as TMenuItem).MenuIndex;
ProcessLines.Add('lang '+IntToStr(valor));
End;

Procedure TForm1.MMImpLang(Sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Import Language','English_*.txt','implang (-resultado-)',true);
End;

Procedure TForm1.MMNewLang(Sender:TObject);
Begin
CreateTraslationFile();
End;

Procedure Tform1.MMVerConsola(Sender:TObject);
Begin
if memoconsola.Visible then
   begin
   Memoconsola.Visible:=false;
   ConsoleLine.Visible:=false;
   DataPanel.Visible:=false;
   PanelTrxDetails.Visible:=false;
   DireccionesPanel.Visible:=true;
   GridMyTxs.Visible:=true;
   PanelScrow.Visible:=true;
   optionspanel.Visible:=false;
   MainMenu.Items[2].Items[0].Caption:='Console';
   Form1.imagenes.GetBitmap(25,MainMenu.Items[2].Items[0].bitmap);
   end
else
   begin
   Memoconsola.Visible:=true;
   memoconsola.SelStart := Length(memoconsola.Lines.Text)-1;
   ConsoleLine.Visible:=true;
   DataPanel.Visible:=true;
   DireccionesPanel.Visible:=false;
   GridMyTxs.Visible:=false;
   PanelTrxDetails.Visible:=false;
   PanelScrow.Visible:=false;
   optionspanel.Visible:=false;
   ConsoleLine.SetFocus;
   MainMenu.Items[2].Items[0].Caption:='Wallet';
   Form1.imagenes.GetBitmap(30,MainMenu.Items[2].Items[0].bitmap);
   end;
End;


END. // END PROGRAM










