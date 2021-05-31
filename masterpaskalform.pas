unit MasterPaskalForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLType,
  Grids, ExtCtrls, Buttons, IdTCPServer, IdContext, IdGlobal, IdTCPClient,
  fileutil, Clipbrd, Menus, crt, formexplore, lclintf, ComCtrls, Spin,
  poolmanage, strutils, mpoptions, math, IdHTTPServer, IdCustomHTTPServer,
  fpJSON, Types;

type

   { TThreadClientRead }

   TThreadClientRead = class(TThread)
   private
     FSlot: Integer;
   protected
     procedure Execute; override;
   public
     constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
   end;

  TThreadSendOutMsjs = class(TThread)
    procedure Execute; override;
  end;

  Options = Packed Record
     language: integer;
     Port : integer;
     GetNodes : Boolean;
     PoolInfo : String[255];
     Wallet : string[255];
     AutoServer : boolean;
     AutoConnect : Boolean;
     Auto_Updater : boolean;
     JustUpdated : boolean;
     VersionPage : String[255];
     ToTray : boolean;
     UsePool : Boolean ;
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
     IsBusy : Boolean;
     Thread : TThreadClientRead;
     end;

  WalletData = Packed Record
     Hash : String[40]; // El hash publico o direccion
     Custom : String[40]; // En caso de que la direccion este personalizada
     PublicKey : String[255]; // clave publica
     PrivateKey : String[255]; // clave privada
     Balance : int64; // el ultimo saldo conocido de la direccion
     Pending : int64; // el ultimo saldo de pagos pendientes
     Score : int64; // estado del registro de la direccion.
     LastOP : int64;// tiempo de la ultima operacion en UnixTime.
     end;

  SumarioData = Packed Record
     Hash : String[40]; // El hash publico o direccion
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
     Solution       : String[200]; // 180 necessary
     LastBlockHash  : String[32];
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
       Sender : String[120];    // La clave publica de quien envia
       Address : String[40];
       Receiver : String[40];
       AmmountFee : Int64;
       AmmountTrf : Int64;
       Signature : String[120];
       TrfrID : String[64];
     end;

  NetworkData = Packed Record
     Value : String[64];   // el valor almacenado
     Porcentaje : integer; // porcentake de peers que tienen el valor
     Count : integer;      // cuantos peers comparten ese valor
     Slot : integer;       // en que slots estan esos peers
     end;

  ResumenData = Packed Record
     block : integer;
     blockhash : string[32];
     SumHash : String[32];
     end;

  DivResult = packed record
     cociente : string[255];
     residuo : string[255];
     end;

  MyTrxData = packed record
     block : integer;
     time  : int64;
     tipo  : string[6];
     receiver : string[64];     // Used for PoS storage on transaction 0
     monto    : int64;
     trfrID   : string[64];
     OrderID  : String[64];
     Concepto : String[64];
     end;

  MilitimeData = Packed Record
     Name : string[255];
     Start : int64;
     finish : int64;
     duration : int64;
     Maximo : int64;
     Minimo : int64;
     end;

  BlockOrdersArray = Array of OrderData;

  PoolInfoData = Packed Record
       Name : string[15];
       Direccion : String[40];
       Porcentaje : integer;
       MaxMembers : integer;
       Port : integer;
       TipoPago : integer;
       PassWord : string[10];
       FeeEarned : int64;
       end;

  PoolMembersData = Packed Record
       Direccion : string[40];
       Prefijo : String[10];
       Soluciones : integer;
       Deuda : Int64;
       LastPago : integer;
       TotalGanado : Int64;
       LastSolucion : int64;
       LastEarned : Int64;
       end;

  PoolData = Packed Record
       Name : String[15];
       Ip : string[15];
       port : Integer;
       Direccion : String[40];
       Prefijo : string[10];
       MyAddress : String[40];
       balance : int64;
       LastPago : integer;
       Password : String[10];
       end;

  PoolMinerData = Packed Record
       Block : integer;
       Solucion : string[200];
       steps : Integer;
       Dificult : Integer;
       DiffChars : integer;
       Target : string[64];
       end;

  PoolUserConnection = Packed Record
       Ip : String[15];
       Address : String[40];
       Context : TIdContext;
       slot : integer;
       Hashpower : int64;
       Version: string[10];
       LastPing : int64;
       WrongSteps : integer;
       end;

  NetworkRequestData = Packed Record
       tipo : integer;
       timestamp : int64;
       block : integer;
       hashreq : string[32];
       hashvalue: string[32];
       end;

  PoolPaymentData = Packed Record
       block : integer;
       address : string[32];
       amount : int64;
       Order : string[64];
       end;

  TArrayPos = Packed Record
       address : string[32];
       end;

  BlockArraysPos = array of TArrayPos;

  { TForm1 }

  TForm1 = class(TForm)
    Button1: TButton;
    CB_WO_AutoConnect: TCheckBox;
    CB_WO_ToTray: TCheckBox;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox4: TCheckBox;
    CB_RPC_ON: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    CheckBox9: TCheckBox;
    Edit1: TEdit;
    Image1: TImage;
    Imagenes: TImageList;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    LE_Rpc_Port: TLabeledEdit;
    LE_Rpc_Pass: TLabeledEdit;
    LabeledEdit12: TLabeledEdit;
    LabeledEdit13: TLabeledEdit;
    LabeledEdit14: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit7: TLabeledEdit;
    LabeledEdit8: TLabeledEdit;
    LabeledEdit9: TLabeledEdit;
    Latido : TTimer;
    InfoTimer : TTimer;
    InicioTimer : TTimer;
    CloseTimer : TTimer;
    RestartTimer : Ttimer;
    Memo1: TMemo;
    Memo2: TMemo;
    MemoLog: TMemo;
    MemoExceptLog: TMemo;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PageControl3: TPageControl;
    PageMain: TPageControl;
    Panel1: TPanel;
    Server: TIdTCPServer;
    PoolServer : TIdTCPServer;
    RPCServer : TIdHTTPServer;
    SE_WO_RTOT: TSpinEdit;
    SE_WO_MinPeers: TSpinEdit;
    SE_WO_CTOT: TSpinEdit;
    SE_WO_ShowOrders: TSpinEdit;
    SE_WO_PosWarning: TSpinEdit;
    StaticText1: TStaticText;
    SystrayIcon: TTrayIcon;
    tabOptions: TTabSheet;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    TabExchange: TTabSheet;
    TabMonitor: TTabSheet;
    tabExBuy: TTabSheet;
    TabExSell: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    TabSheet8: TTabSheet;
    TabMainPool: TTabSheet;
    TabWallet: TTabSheet;
    TabConsole: TTabSheet;

    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    Procedure LoadOptionsToPanel();
    procedure FormShow(Sender: TObject);
    Procedure InicoTimerEjecutar(Sender: TObject);
    Procedure RestartTimerEjecutar(Sender: TObject);
    Procedure EjecutarInicio();
    Procedure ConsoleLineKeyup(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Grid1PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure Grid2PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    Procedure GridMyTxsPrepareCanvas(sender: TObject; aCol, aRow: Integer;aState: TGridDrawState);
    Procedure LatidoEjecutar(Sender: TObject);
    Procedure InfoTimerEnd(Sender: TObject);
    Procedure CloseTimerEnd(Sender: TObject);
    function  ClientsCount : Integer ;
    Procedure TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
    Procedure DoubleClickSysTray(Sender: TObject);
    Procedure ConnectCircleOnClick(Sender: TObject);
    Procedure MinerCircleOnClick(Sender: TObject);
    Procedure GridMyTxsOnDoubleClick(Sender: TObject);
    Procedure BitPosInfoOnClick (Sender: TObject);
    Procedure BCloseTrxDetailsOnClick(Sender: TObject);
    Procedure BDefAddrOnClick(Sender: TObject);
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
    // Pool
    Procedure TryClosePoolConnection(AContext: TIdContext; closemsg:string='');
    function PoolClientsCount : Integer ;
    procedure PoolServerConnect(AContext: TIdContext);
    procedure PoolServerExecute(AContext: TIdContext);
    procedure PoolServerDisconnect(AContext: TIdContext);
    procedure PoolServerException(AContext: TIdContext;AException: Exception);
    // RPC
    procedure RPCServerConnect(AContext: TIdContext);
    procedure RPCServerExecute(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

    // MAIN MENU
    Procedure CheckMMCaptions(Sender:TObject);
    Procedure MMServer(Sender:TObject);
    Procedure MMConnect(Sender:TObject);
    Procedure MMMiner(Sender:TObject);
    Procedure MMImpWallet(Sender:TObject);
    Procedure MMExpWallet(Sender:TObject);
    Procedure MMQuit(Sender:TObject);
    Procedure MMAbout(Sender:TObject);
    Procedure MMRestart(Sender:TObject);
    Procedure MMChangeLang(Sender:TObject);
    Procedure MMRunUpdate(Sender:TObject);
    Procedure MMImpLang(Sender:TObject);
    Procedure MMNewLang(Sender:TObject);
    Procedure MMVerConsola(Sender:TObject);
    Procedure MMVerLog(Sender:TObject);
    Procedure MMVerWeb(Sender:TObject);
    Procedure MMVerSlots(Sender:TObject);
    Procedure MMVerPool(Sender:TObject);
    Procedure MMVerMonitor(Sender:TObject);

    // CONSOLE POPUP
    Procedure CheckConsolePopUp(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure ConsolePopUpClear(Sender:TObject);
    Procedure ConsolePopUpCopy(Sender:TObject);

    // CONSOLE LINE POPUP
    Procedure CheckConsoLinePopUp(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure ConsoLinePopUpClear(Sender:TObject);
    Procedure ConsoLinePopUpCopy(Sender:TObject);
    Procedure ConsoLinePopUpPaste(Sender:TObject);

    // TRXDETAILS POPUP
    Procedure CheckTrxDetailsPopUp(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure TrxDetailsPopUpCopyOrder(Sender:TObject);
    Procedure TrxDetailsPopUpCopy(Sender:TObject);

    // OPTIONS
      // WALLET
    procedure CB_WO_AutoConnectChange(Sender: TObject);
    procedure CB_WO_ToTrayChange(Sender: TObject);
    procedure SE_WO_MinPeersChange(Sender: TObject);
    procedure SE_WO_CTOTChange(Sender: TObject);
    procedure SE_WO_RTOTChange(Sender: TObject);
    procedure SE_WO_ShowOrdersChange(Sender: TObject);
    procedure SE_WO_PosWarningChange(Sender: TObject);

  private

  public

  end;

Procedure InicializarFormulario();
Procedure CerrarPrograma();
Procedure UpdateStatusBar();

CONST
  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  ReservedWords : string = 'NULL,DELADDR';
  HideCommands : String = 'CLEAR SENDPOOLSOLUTION SENDPOOLSTEPS POOLHASHRATE';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';
  DefaultNodes : String = 'DefNodes 192.210.160.101 '+
                          '23.95.233.179 '+
                          '75.127.0.216 '+
                          '191.96.103.153 '+
                          '45.141.36.117 '+
                          '199.247.12.166 '+
                          '108.61.250.100';
  ProgramVersion = '0.2.1';
  SubVersion = 'E';
  OficialRelease = true;
  BuildDate = 'May 2021';
  ADMINHash = 'N4PeJyqj8diSXnfhxSQdLpo8ddXTaGd';
  AdminPubKey = 'BL17ZOMYGHMUIUpKQWM+3tXKbcXF0F+kd4QstrB0X7iWvWdOSrlJvTPLQufc1Rkxl6JpKKj/KSHpOEBK+6ukFK4=';
  HasheableChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  DefaultServerPort = 8080;
  MaxConecciones  = 75;
  Protocolo = 1;
  Miner_Steps = 10;
  Pool_Max_Members = 1000;
  // Custom values for coin
  SecondsPerBlock = 600;            // 10 minutes
  PremineAmount = 1030390730000;    // 1030390730000;
  InitialReward = 5000000000;       // Initial reward
  BlockHalvingInterval = 210000;    // 210000;
  HalvingSteps = 10;                // total number of halvings
  Comisiontrfr = 10000;             // ammount/Comisiontrfr = 0.01 % of the ammount
  ComisionCustom = 200000;          // 0.05 % of the Initial reward
  CoinSimbol = 'NOS';               // Coin 3 chars
  CoinName = 'Noso';                // Coin name
  CoinChar = 'N';                   // Char for addresses
  MinimunFee = 10;                  // Minimun fee for transfer
  ComisionBlockCheck = 0;           // +- 90 days
  DeadAddressFee = 0;               // unactive acount fee
  ComisionScrow = 200;              // Coin/BTC market comision = 0.5%
  PoSPercentage = 1000;             // PoS part: reward * PoS / 10000
  PosStackCoins = 20;               // PoS stack ammoount: supply*20 / PoSStack
  PoSBlockStart : integer = 8425;   // first block with PoSPayment
  InitialBlockDiff = 60;            // Dificultad durante los 20 primeros bloques
  GenesysTimeStamp = 1615132800;    // 1615132800;

var
  UserFontSize : integer = 8;
  UserRowHeigth : integer = 22;
  ReadTimeOutTIme : integer = 100;
  ConnectTimeOutTime : integer = 500;
  DefCPUs : integer = 1;
  PoolExpelBlocks :integer = 0;
  PoolShare : integer = 100;
  RPCPort : integer = 8078;
  RPCPass : string = 'default';
  ShowedOrders : integer = 100;
  MaxPeersAllow : integer = 50;
  PoolStepsDeep : integer = 3;
  WO_AutoConnect   : boolean = false;
  WO_ToTray        : boolean = false;
  MinConexToWork   : integer = 1;
  WO_PosWarning    : int64 = 7;


  SynchWarnings : integer = 0;
  ConnectedRotor : integer = 0;
  EngineLastUpdate : int64 = 0;

  // Threads variables
  // ReadingClients : boolean = false;
  // HiloLeerClientes : TThreadLeerClientes;
  SendOutMsgsThread : TThreadSendOutMsjs;
    SendingMsgs : boolean = false;

  MaxOutgoingConnections : integer = 3;
  FirstShow : boolean = false;
  RunningDoctor : boolean = false;

  G_PoSPayouts, G_PoSEarnings : int64;

  CheckMonitor : boolean = false;
  RunDoctorBeforeClose : boolean = false;
  RestartNosoAfterQuit : boolean = false;
  ConsensoValues : integer = 0;
  RebuildingSumary : boolean = false;
  MilitimeArray : array of MilitimeData;
  MyCurrentBalance : Int64 = 0;
  G_CpuCount : integer = 1;
  G_MiningCPUs : Integer = 1;
  Customizationfee : int64 = InitialReward div ComisionCustom;
  G_TIMELocalTimeOffset : int64 = 0;
  G_TimeOffSet : Int64 = 0;
  G_LastLocalTimestamp : int64 = 0;
  G_NTPServer : String = '';
  G_OpenSSLPath : String = '';
  MsgsReceived : string = '';
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
  LogLines : TStringList;
    S_Log : boolean = false;
  ExceptLines : TStringList;
    S_Exc : boolean = false;
  PoolPaysLines : TStringList;
    S_PoolPays : boolean = false;
  ArrPoolPays : array of PoolPaymentData;
  StringAvailableUpdates : String = '';
  DataPanel : TStringGrid;
    U_DataPanel : boolean = true;
  LabelBigBalance : TLabel;

  // Network requests
  ArrayNetworkRequests : array of NetworkRequestData;
     networkhashrate: int64 = 0;
       nethashsend : boolean = false;
     networkpeers : integer;
       netpeerssend : boolean = false;

    U_DirPanel : boolean = false;
  FileMyTrx  : File of MyTrxData;
    S_MyTrxs  : boolean = false;
  FileOptions : file of options;
    S_Options : Boolean = false;
  FileBotData : File of BotData;
    S_BotData : Boolean = false;
  LastBotClear: string = '';
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
  FilePool : File of PoolInfoData;
    PoolInfo : PoolInfoData;
    S_PoolInfo : boolean = false;
  FilePoolMembers : File of PoolMembersData;
    S_PoolMembers : boolean = false;
  FilePoolPays : textfile;
    S_PoolPayments : boolean = false;
  FileAdvOptions : textfile;
    S_AdvOpt : boolean = false;
  PoolServerConex : array of PoolUserConnection;
  PoolTotalHashRate : int64 = 0;

  UserOptions : Options;
  AutoRestarted : Boolean = false;
  CurrentLanguage : String = '';
  CurrentJob : String = '';
  ForcedQuit : boolean = false;
  LanguageLines : integer = 0;
  NewLogLines : integer = 0;
  Conexiones : array [1..MaxConecciones] of conectiondata;
  SlotLines : array [1..MaxConecciones] of TStringList;
  CanalCliente : array [1..MaxConecciones] of TIdTCPClient;
    PoolClientLastPing : int64;
  PoolClientContext : TIdContext;
  ListadoBots :  array of BotData;
  ListaNodos : array of NodeData;
  ListaNTP : array of NTPData;
  ListaMisTrx : Array of MyTrxData;
  ListaDirecciones : array of walletData; // Wallet addresses
  ListaSumario : array of SumarioData;    // Sumary addresses
  PendingTXs : Array of OrderData;
  OutgoingMsjs : TStringlist;
  ArrayConsenso : array of NetworkData;
  ArrayPoolMembers : array of PoolMembersData;
  PoolMembersTotalDeuda : Int64 = 0;

  // Variables asociadas a la red
  KeepServerOn : Boolean = false;
     LastTryServerOn : Int64;
  DownloadHeaders : boolean = false;
  DownLoadBlocks  : boolean = false;
  CONNECT_LastTime : string = ''; // La ultima vez que se intento una conexion
  CONNECT_Try : boolean = false;
  MySumarioHash : String = '';
  MyLastBlock : integer = 0;
  MyLastBlockHash : String = '';
  MyResumenHash : String = '';
  MyPublicIP : String = '';
  LastBlockData : BlockHeaderData;
  UndonedBlocks : boolean = false;

  NetSumarioHash : NetworkData;
    SumaryRebuilded : boolean = false;
  NetLastBlock : NetworkData;
    LastTimeRequestBlock : int64 = 0;
  NetLastBlockHash : NetworkData;
  NetPendingTrxs : NetworkData;
  NetResumenHash : NetworkData;
    LastTimeRequestResumen : int64 = 0;
    LastTimePendingRequested : int64 = 0;

  // Variables asociadas a mi conexion
  MyConStatus :  integer = 0;
  STATUS_Connected : boolean = false;

  // Variables asociadas al minero
  MyPoolData : PoolData;
    PoolMiner : PoolMinerData;
  Miner_OwnsAPool : Boolean = false;
    LastTryStartPoolServer : int64;
    LastTryConnectPoolcanal : Int64;
    LastPoolHashRequest : int64;
    PoolSolutionFails : integer;
  Miner_PoolHashRate : Int64 = 0;
  Miner_IsON : Boolean = false;
  Miner_Active : Boolean = false;
  Miner_Waiting : int64 = -1;
  Miner_BlockToMine : integer =0;
  Miner_Difficult : integer = 0;
  Miner_DifChars : integer = 0;
  Miner_Target : String = '';
  MINER_FoundedSteps : integer = 0;
  MINER_HashCounter : Integer = 100000000;
  Miner_HashSeed : String = '!!!!!!!!!';
  Miner_Thread : array of TThreadID;
  Miner_Address : string = '';
  Miner_BlockFOund : boolean = False;
  Miner_Solution : String = '';
  Miner_SolutionVerified : boolean = false;
  Miner_UltimoRecuento : int64 = 100000000;
  Miner_EsteIntervalo : int64 = 0;
  Miner_KillThreads : boolean = false;
  Miner_LastHashRate : int64 = 0;
  Miner_PoolSharedStep : Array of string;
  RPC_MinerInfo : String = '';
  RPC_MinerReward : int64 = 0;

  // Threads
  RebulidTrxThread : TThreadID;
  CriptoOPsThread : TThreadID;
    CriptoOpsTipo : Array of integer;
    CriptoOpsOper : Array of string;
    CriptoOpsResu : Array of string;
    CriptoThreadRunning : boolean = false;

  // Critical Sections
  CSProcessLines: TRTLCriticalSection;
  CSConsoleLines: TRTLCriticalSection;
  CSOutgoingMsjs: TRTLCriticalSection;
  CSPoolStep    : TRTLCriticalSection;
  CSPoolPay     : TRTLCriticalSection;
  CSHeadAccess  : TRTLCriticalSection;
  CSBlocksAccess: TRTLCriticalSection;
  CSSumary      : TRTLCriticalSection;
  CSPending     : TRTLCriticalSection;
  CSCriptoThread: TRTLCriticalSection;
  CSPoolMembers : TRTLCriticalSection;
  CSMinerJoin   : TRTLCriticalSection; InsideMinerJoin:Boolean;

  // Cross OS variables
  OSFsep : string = '';
  OptionsFileName : string = '';
  BotDataFilename : string = '';
  NodeDataFilename : string = '';
  NTPDataFilename : string = '';
  WalletFilename : string = '';
  SumarioFilename : string = '';
  LanguageFileName : string = '';
  BlockDirectory : string = '';
  UpdatesDirectory : string = '';
  LogsDirectory : string = '';
  ExceptLogFilename : string = '';
  ResumenFilename: string = '';
  MyTrxFilename : string = '';
  TranslationFilename : string = '';
  ErrorLogFilename : string = '';
  PoolInfoFilename : string = '';
  PoolMembersFilename : string = '';
  AdvOptionsFilename : string = '';
  PoolPaymentsFilename : string = '';

  // Visual Components
  MainMenu : TMainMenu;
    MenuItem : TMenuItem;
  ConsolePopUp : TPopupMenu;
  ConsoLinePopUp : TPopupMenu;
  TrxDetailsPopUp : TPopupMenu;

  ConnectButton : TSpeedButton;
  MinerButton : TSpeedButton;
  ImageInc :TImage;
    MontoIncoming : Int64 = 0;
  ImageOut :TImage;
    MontoOutgoing : Int64 = 0;
  DireccionesPanel : TStringGrid;
    BDefAddr : TSpeedButton;
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
    BitPosInfo: TSpeedButton;
    U_Mytrxs: boolean = false;
    LastMyTrxTimeUpdate : int64;
  PanelTrxDetails : TPanel;
    MemoTrxDetails : TMemo;
    BCloseTrxDetails : TBitBtn;

  SBOptions : TSpeedButton;

  InfoPanel : TPanel;
    InfoPanelTime : integer = 0;

  StatusPanel : TPanel;
    StaConRot : Tlabel;
    StaSerImg : TImage;
    StaRPCLab : Tlabel;
    StaConLab : TLabel;
    StaBloImg : TImage;
    StaBloLab : TLabel;
    StaPenImg : TImage;
    StaPenLab : TLabel;
    StaPoolSer : Timage;
    StaMinImg : Timage;
    StaMinLab : TLabel;

  //OTHER
  U_PoolConexGrid : boolean = false;

implementation

Uses
  mpgui, mpdisk, mpParser, mpRed, mpTime, mpProtocol, mpMiner, mpcripto, mpcoin,
  mpRPC;

{$R *.lfm}

{ TThreadClientRead }

procedure TThreadClientRead.Execute;
var
  LLine: String;
  AFileStream : TFileStream;
  BlockZipName : string = '';
  Continuar : boolean = true;
  TruncateLine : string = '';
begin
repeat
delay(200);
continuar := true;
if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
   begin
   CanalCliente[FSlot].IOHandler.CheckForDataOnSource(ReadTimeOutTIme);
   if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
      Continuar := false;
   end;
if Continuar then
   begin
   While not CanalCliente[FSlot].IOHandler.InputBufferIsEmpty do
      begin
      Conexiones[fSlot].IsBusy:=true;
      Conexiones[fSlot].lastping:=UTCTime;
         try
         CanalCliente[FSlot].ReadTimeout:=ReadTimeOutTIme;
         LLine := CanalCliente[FSlot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
         if CanalCliente[FSlot].IOHandler.ReadLnTimedout then
            begin
            ToExcLog('TimeOut reading from slot: '+conexiones[Fslot].ip);
            TruncateLine := TruncateLine+LLine;
            Conexiones[fSlot].IsBusy:=false;
            continue;
            end;
         Except on E:Exception do
            begin
            tolog ('Error Reading lines from slot: '+IntToStr(Fslot)+slinebreak+E.Message);
            Conexiones[fSlot].IsBusy:=false;
            continue;
            end;
         end;
      if continuar then
         begin
         if GetCommand(LLine) = 'RESUMENFILE' then
            begin
            EnterCriticalSection(CSHeadAccess);
            ConsoleLinesadd('Receiving headers');
            DownloadHeaders := true;
               try
               AFileStream := TFileStream.Create(ResumenFilename, fmCreate);
               CanalCliente[FSlot].ReadTimeout:=0;
                  try
                  CanalCliente[FSlot].IOHandler.ReadStream(AFileStream);
                  Except on E:Exception do
                     begin
                     toExcLog(format('Error Receiving headers from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                     consolelinesadd(format('Error Receiving headers from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                     end;
                  end;
               finally
               AFileStream.Free;
               DownloadHeaders := false;
               LeaveCriticalSection(CSHeadAccess);
               end;
            consolelinesAdd(LAngLine(74)+': '+copy(HashMD5File(ResumenFilename),1,5)); //'Headers file received'
            LastTimeRequestResumen := 0;
            UpdateMyData();
            end
         else if LLine = 'BLOCKZIP' then
            begin
            ConsoleLinesadd('Receiving blocks');
            BlockZipName := BlockDirectory+'blocks.zip';
            if FileExists(BlockZipName) then DeleteFile(BlockZipName);
            AFileStream := TFileStream.Create(BlockZipName, fmCreate);
            DownLoadBlocks := true;
               try
               CanalCliente[FSlot].ReadTimeout:=0;
                  try
                  CanalCliente[FSlot].IOHandler.ReadStream(AFileStream);
                  Except on E:Exception do
                     begin
                     consolelinesadd(format('Error Receiving blocks from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                     end;
                  end;
               finally
               AFileStream.Free;
               end;
            UnzipBlockFile(BlockDirectory+'blocks.zip',true);
            MyLastBlock := GetMyLastUpdatedBlock();
            consolelinesadd('Blocks received up to '+IntToStr(MyLastBlock));
            //BuildHeaderFile(MyLastBlock);
            ResetMinerInfo();
            LastTimeRequestBlock := 0;
            DownLoadBlocks := false;
            end
         else
            begin
            SlotLines[FSlot].Add(LLine);
            end;
         end;
      Conexiones[fSlot].IsBusy:=false;
      end;
   end;
until ((terminated) or (not CanalCliente[FSlot].Connected));
End;

constructor TThreadClientRead.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
end;

{ TForm1 }

// ***************
// *** THREADS ***
// ***************

// Send the outgoing messages
procedure TThreadSendOutMsjs.Execute;
Var
  Slot :integer = 1;
Begin
SendingMsgs := true;
While OutgoingMsjs.Count > 0 do
   begin
   For Slot := 1 to MaxConecciones do
      begin
         try
         if conexiones[Slot].tipo <> '' then PTC_SendLine(Slot,OutgoingMsjs[0]);
         Except on E:Exception do
            ToExclog('Error sending outgoing message: '+E.Message);
         end;
      end;
   if OutgoingMsjs.Count > 0 then
      begin
      EnterCriticalSection(CSOutgoingMsjs);
      OutgoingMsjs.Delete(0);
      LeaveCriticalSection(CSOutgoingMsjs);
      end;
   end;
SendingMsgs := false;
End;


//***********************
// *** FORM RELATIVES ***
//***********************

// Form create
procedure TForm1.FormCreate(Sender: TObject);
begin
Randomize;
InitCriticalSection(CSProcessLines);
InitCriticalSection(CSConsoleLines);
InitCriticalSection(CSOutgoingMsjs);
InitCriticalSection(CSPoolStep);
InitCriticalSection(CSPoolPay);
InitCriticalSection(CSHeadAccess);
InitCriticalSection(CSBlocksAccess);
InitCriticalSection(CSSumary);
InitCriticalSection(CSPending);
InitCriticalSection(CSCriptoThread);
InitCriticalSection(CSPoolMembers);
InitCriticalSection(CSMinerJoin);

CreateFormInicio();
CreateFormLog();
CreateFormAbout();
CreateFormMilitime();
CreateFormSlots();
CreateFormPool();
//SetLength(ListaMisTrx,0); destroy?
end;

// Form destroy
procedure TForm1.FormDestroy(Sender: TObject);
begin
DoneCriticalSection(CSProcessLines);
DoneCriticalSection(CSConsoleLines);
DoneCriticalSection(CSOutgoingMsjs);
DoneCriticalSection(CSPoolStep);
DoneCriticalSection(CSPoolPay);
DoneCriticalSection(CSHeadAccess);
DoneCriticalSection(CSBlocksAccess);
DoneCriticalSection(CSSumary);
DoneCriticalSection(CSPending);
DoneCriticalSection(CSCriptoThread);
DoneCriticalSection(CSPoolMembers);
DoneCriticalSection(CSMinerJoin);
end;

// Form show
procedure TForm1.FormShow(Sender: TObject);
var
    Proceder:boolean = true;
begin
// Se ejecuta solo la primera vez
if FirstShow then Proceder:=false;
//inicializar lo basico para cargar el idioma
if proceder then
   begin
   form1.Visible:=false;
   forminicio.Visible:=true;
   Form1.InicioTimer:= TTimer.Create(Form1);
   Form1.InicioTimer.Enabled:=true;
   Form1.InicioTimer.Interval:=1;
   Form1.InicioTimer.OnTimer:= @form1.InicoTimerEjecutar;

   Form1.RestartTimer:= TTimer.Create(Form1);
   Form1.RestartTimer.Enabled:=false;
   Form1.RestartTimer.Interval:=1000;
   Form1.RestartTimer.OnTimer:= @form1.RestartTimerEjecutar;
   end;
end;

Procedure TForm1.InicoTimerEjecutar(Sender: TObject);
Begin
InicioTimer.Enabled:=false;
EjecutarInicio;
End;

// Auto restarts the app from hangs
Procedure TForm1.RestartTimerEjecutar(Sender: TObject);
Begin
RestartTimer.Enabled:=false;
if ((UTCTime.ToInt64 > EngineLastUpdate+30) and (not RebuildingSumary)) then
   begin
   CrearBatFileForRestart();
   AutoRestarted := true;
   CrearCrashInfo();
   CrearRestartfile();
   //CloseAllforms();
   //CerrarClientes();
   //StopServer();
   StopPoolServer();
   if length(ArrayPoolMembers)>0 then GuardarPoolMembers();
   RunExternalProgram('nosolauncher.bat');
   Application.Terminate;
   halt(0);
   end;
RestartTimer.Enabled:=true;
End;

// Ejecuta todo el proceso de carga y lo muestra en el form inicio
Procedure TForm1.EjecutarInicio();
var
  contador : integer;
Begin
InitCrossValues();
// A partir de aqui se inicializa todo
if not directoryexists('NOSODATA') then CreateDir('NOSODATA');
OutText('✓ Data directory ok',false,1);
if not FileExists(OptionsFileName) then CrearArchivoOpciones() else CargarOpciones();
StringListLang := TStringlist.Create;
ConsoleLines := TStringlist.Create;
DLSL := TStringlist.Create;
IdiomasDisponibles := TStringlist.Create;
LogLines := TStringlist.Create;
ExceptLines := TStringlist.Create;
PoolPaysLines := TStringlist.Create;
if not FileExists (LanguageFileName) then CrearIdiomaFile() else CargarIdioma(UserOptions.language);
// finalizar la inicializacion
InicializarFormulario();
OutText('✓ GUI initialized',false,1);
VerificarArchivos();
InicializarGUI();
InitTime();
UpdateMyData();
OutText('✓ My data updated',false,1);
ResetMinerInfo();
OutText('✓ Miner configuration set',false,1);
// Ajustes a mostrar
LoadOptionsToPanel();
form1.Caption:=coinname+LangLine(61)+ProgramVersion+SubVersion;    // Wallet
Application.Title := coinname+LangLine(61)+ProgramVersion;  // Wallet
OutText('✓ '+IntToStr(IdiomasDisponibles.count)+' languages available',false,1);
ConsoleLinesAdd(coinname+LangLine(61)+ProgramVersion+SubVersion);  // wallet
RebuildMyTrx(MyLastBlock);
UpdateMyTrxGrid();
if useroptions.JustUpdated then
   begin
   ConsoleLinesAdd(LangLine(19)+ProgramVersion);  // Update to version sucessfull:
   useroptions.JustUpdated := false;
   S_Options := true;
   OutText('✓ Just updated to a new version',false,1);
   end;
if fileexists('nosolauncher.bat') then Deletefile('nosolauncher.bat');
if fileexists('restart.txt') then RestartConditions();
if GetEnvironmentVariable('NUMBER_OF_PROCESSORS') = '' then G_CpuCount := 1
else G_CpuCount := StrToIntDef(GetEnvironmentVariable('NUMBER_OF_PROCESSORS'),1);
G_CpuCount := 1;
G_MiningCPUs := G_CpuCount;
OutText('✓ '+inttostr(G_CpuCount)+' CPUs found',false,1);
StringAvailableUpdates := AvailableUpdates();
Form1.Latido.Enabled:=true;
G_Launching := false;
OutText('Noso is ready',false,1);
if UserOptions.AutoServer then ProcessLinesAdd('SERVERON');
if WO_AutoConnect then ProcessLinesAdd('CONNECT');
FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
FirstShow := true;
Setlength(CriptoOpsTipo,0);
Setlength(CriptoOpsOper,0);
Setlength(CriptoOpsResu,0);
Setlength(MilitimeArray,0);
Setlength(Miner_Thread,0);
SetLength(ArrayNetworkRequests,0);
SetLength(ArrPoolPays,0);

Tolog('Noso session started'); NewLogLines := NewLogLines-1;
info('Noso session started');
infopanel.BringToFront;
SetCurrentJob('Main',true);
forminicio.Visible:=false;
form1.Visible:=true;
Form1.RestartTimer.Enabled:=true;
End;

// Carga las opciones de usuario al panel de opciones
Procedure TForm1.LoadOptionsToPanel();
Begin
// WALLET
CB_WO_AutoConnect.Checked := WO_AutoConnect;
CB_WO_ToTray.Checked := WO_ToTray;
SE_WO_MinPeers.Value := MinConexToWork;
SE_WO_CTOT.Value:= ConnectTimeOutTime;
SE_WO_RTOT.Value:= ReadTimeOutTIme;
SE_WO_ShowOrders.Value:= ShowedOrders;
SE_WO_PosWarning.Value := WO_PosWarning;
// RPC
LE_Rpc_Port.Text := IntToStr(RPCPort);
LE_Rpc_Pass.Text := RPCPass;
End;

// Cuando se solicita cerrar el programa
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
G_CloseRequested := true;
CloseTimer.Enabled:=true;
canclose := false;
end;

// Al minimizar verifica si hay que llevarlo a barra de tareas
procedure TForm1.FormWindowStateChange(Sender: TObject);
begin
if WO_ToTray then
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
   ProcessLinesAdd(LineText);
   if Uppercase(Linetext) = 'EXIT' then
     begin
     CrearCrashInfo();
     Application.Terminate;
     end;
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
if ((Shift = [ssCtrl]) and (Key = VK_I)) then
   begin
   UserRowHeigth := UserRowHeigth+1;
   ConsoleLinesAdd('UserRowHeigth:'+inttostr(UserRowHeigth));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl]) and (Key = VK_K)) then
   begin
   UserRowHeigth := UserRowHeigth-1;
   ConsoleLinesAdd('UserRowHeigth:'+inttostr(UserRowHeigth));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl]) and (Key = VK_O)) then
   begin
   UserFontSize := UserFontSize+1;
   ConsoleLinesAdd('UserFontSize:'+inttostr(UserFontSize));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl]) and (Key = VK_L)) then
   begin
   UserFontSize := UserFontSize-1;
   ConsoleLinesAdd('UserFontSize:'+inttostr(UserFontSize));
   UpdateRowHeigth();
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
  posrequired : int64;
begin
posrequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
if (ACol=1)  then
   begin
   ts := (Sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (Sender as TStringGrid).Canvas.TextStyle := ts;

   if ((aRow>0) and (ListaDirecciones[aRow-1].Balance>posrequired) and (ListaDirecciones[aRow-1].Balance>(posrequired+(WO_PosWarning*140*10000000))) ) then
      begin
      (Sender as TStringGrid).Canvas.Brush.Color :=  clmoneygreen;
      (Sender as TStringGrid).Canvas.font.Color :=  clblack;
      end;
   if ((aRow>0) and (ListaDirecciones[aRow-1].Balance>posrequired) and (ListaDirecciones[aRow-1].Balance< (posrequired+(WO_PosWarning*140*10000000))) ) then
      begin
      (Sender as TStringGrid).Canvas.Brush.Color :=  clYellow;
      (Sender as TStringGrid).Canvas.font.Color :=  clblack;
      end
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
if EngineLastUpdate <> UTCtime.ToInt64 then EngineLastUpdate := UTCtime.ToInt64;
Form1.Latido.Enabled:=false;
setmilitime('ActualizarGUI',1);
ActualizarGUI();
setmilitime('ActualizarGUI',2);
setmilitime('MostrarLineasDeConsola',1);
MostrarLineasDeConsola();
setmilitime('MostrarLineasDeConsola',2);
setmilitime('SaveUpdatedFiles',1);
SaveUpdatedFiles();
setmilitime('SaveUpdatedFiles',2);
setmilitime('ProcesarLineas',1);
ProcesarLineas();
setmilitime('ProcesarLineas',2);
setmilitime('LeerLineasDeClientes',1);
LeerLineasDeClientes();
setmilitime('LeerLineasDeClientes',2);
setmilitime('ParseProtocolLines',1);
ParseProtocolLines();
setmilitime('ParseProtocolLines',2);
setmilitime('VerifyConnectionStatus',1);
VerifyConnectionStatus();
setmilitime('VerifyConnectionStatus',2);
setmilitime('VerifyMiner',1);
VerifyMiner();
setmilitime('VerifyMiner',2);
if ((KeepServerOn) and (not Form1.Server.Active) and (LastTryServerOn+5<StrToInt64(UTCTime))) then
   ProcessLinesAdd('serveron');
if G_CloseRequested then CerrarPrograma();
if form1.SystrayIcon.Visible then
   form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion+SLINEBREAK+LabelBigBalance.Caption;
if ((CheckMonitor) and (FormMonitor.Visible)) then UpdateMiliTimeForm();
if FormSlots.Visible then UpdateSlotsGrid();
if FormPool.Visible then UpdatePoolForm();
ConnectedRotor +=1; if ConnectedRotor>3 then ConnectedRotor := 0;
UpdateStatusBar;
if ( (StrToInt64(UTCTime) mod 86400=0) and (LastBotClear<>UTCTime) and (Form1.Server.Active) ) then ProcessLinesAdd('delbot all');
Form1.Latido.Enabled:=true;
end;

//procesa el cierre de la aplicacion
Procedure CerrarPrograma();
Begin
CreateADV(false); // save advopt
Miner_IsOn := false;
Miner_KillThreads := true;
info(LangLine(62));  //   Closing wallet
if RestartNosoAfterQuit then CrearRestartfile();
CloseAllforms();
CerrarClientes();
StopServer();
StopPoolServer();
if length(ArrayPoolMembers)>0 then GuardarPoolMembers();
If Miner_IsOn then Miner_IsON := false;
KillAllMiningThreads;
setlength(CriptoOpsTipo,0);
if RunDoctorBeforeClose then RunDiagnostico('rundiag fix');
if RestartNosoAfterQuit then restartnoso();
Application.Terminate;
Halt;
End;

// Run time creation of form components
Procedure InicializarFormulario();
var
  contador : integer = 0;
Begin
// Elementos visuales
MainMenu := TMainMenu.create(form1);
form1.Menu:=MainMenu;

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
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='About...';MenuItem.OnClick:=@Form1.MMAbout;
  Form1.imagenes.GetBitmap(48,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Restart';MenuItem.OnClick:=@Form1.MMRestart;
  Form1.imagenes.GetBitmap(49,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Quit';MenuItem.OnClick:=@Form1.MMQuit;
  Form1.imagenes.GetBitmap(18,MenuItem.bitmap); MainMenu.items[0].Add(MenuItem);

MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Development';
MenuItem.visible := false; MainMenu.items.Add(MenuItem);
MenuItem.OnClick:=@form1.CheckMMCaptions;
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Language';
  Form1.imagenes.GetBitmap(51,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Import';MenuItem.OnClick:=@Form1.MMImpLang;
  Form1.imagenes.GetBitmap(33,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='New file';MenuItem.OnClick:=@Form1.MMNewLang;
  Form1.imagenes.GetBitmap(34,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Updates';
  Form1.imagenes.GetBitmap(50,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Messages';//MenuItem.OnClick:=@Form1.MMNewLang;
  Form1.imagenes.GetBitmap(52,MenuItem.bitmap); MainMenu.items[1].Add(MenuItem);

MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='View';MenuItem.RightJustify:=true;MainMenu.items.Add(MenuItem);
MenuItem.OnClick:=@form1.CheckMMCaptions;
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Console';MenuItem.OnClick:=@Form1.MMVerConsola;
  MenuItem.Visible:=false;Form1.imagenes.GetBitmap(25,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Log';MenuItem.OnClick:=@Form1.MMVerLog;
  MenuItem.Visible:=false;Form1.imagenes.GetBitmap(42,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Monitor';MenuItem.OnClick:=@Form1.MMVerMonitor;
  Form1.imagenes.GetBitmap(44,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='WebPage';MenuItem.OnClick:=@Form1.MMVerWeb;
  Form1.imagenes.GetBitmap(47,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='ConSlots';MenuItem.OnClick:=@Form1.MMVerSlots;
  Form1.imagenes.GetBitmap(29,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);
  MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:='Pool';MenuItem.OnClick:=@Form1.MMVerPool;
  Form1.imagenes.GetBitmap(4,MenuItem.bitmap); MainMenu.items[2].Add(MenuItem);

ConsolePopUp := TPopupMenu.Create(form1);
MenuItem := TMenuItem.Create(ConsolePopUp);MenuItem.Caption := 'Clear';//Form1.imagenes.GetBitmap(0,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.ConsolePopUpClear;ConsolePopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(ConsolePopUp);MenuItem.Caption := 'Copy';Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.ConsolePopUpCopy;ConsolePopUp.Items.Add(MenuItem);

ConsoLinePopUp := TPopupMenu.Create(form1);
MenuItem := TMenuItem.Create(ConsoLinePopUp);MenuItem.Caption := 'Clear';//Form1.imagenes.GetBitmap(0,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.ConsoLinePopUpClear;ConsoLinePopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(ConsoLinePopUp);MenuItem.Caption := 'Copy';Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.ConsoLinePopUpCopy;ConsoLinePopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(ConsoLinePopUp);MenuItem.Caption := 'Paste';Form1.imagenes.GetBitmap(15,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.ConsoLinePopUpPaste;ConsoLinePopUp.Items.Add(MenuItem);

TrxDetailsPopUp := TPopupMenu.Create(form1);
MenuItem := TMenuItem.Create(TrxDetailsPopUp);MenuItem.Caption := 'Copy Order';Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.TrxDetailsPopUpCopyOrder;TrxDetailsPopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(TrxDetailsPopUp);MenuItem.Caption := 'Copy';Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @form1.TrxDetailsPopUpCopy;TrxDetailsPopUp.Items.Add(MenuItem);

Memoconsola := TMemo.Create(Form1);
Memoconsola.Parent:=form1.tabconsole;
Memoconsola.Left:=0;Memoconsola.Top:=0;Memoconsola.Height:=220;Memoconsola.Width:=388;
Memoconsola.Color:=clblack;Memoconsola.Font.Color:=clwhite;Memoconsola.ReadOnly:=true;
Memoconsola.Font.Size:=10;Memoconsola.Font.Name:='consolas';
Memoconsola.Visible:=true;Memoconsola.ScrollBars:=ssvertical;
MemoConsola.OnContextPopup:=@Form1.CheckConsolePopUp;
MemoConsola.PopupMenu:=ConsolePopUp ;

ConsoleLine := TEdit.Create(Form1); ConsoleLine.Parent:=Form1.tabconsole;
ConsoleLine.Font.Name:='consolas';
ConsoleLine.Left:=0;ConsoleLine.Top:=220;ConsoleLine.Height:=12;ConsoleLine.Width:=388;
ConsoleLine.AutoSize:=true;ConsoleLine.Color:=clBlack;ConsoleLine.Font.Color:=clWhite;
ConsoleLine.Visible:=true;ConsoleLine.OnKeyUp:=@form1.ConsoleLineKeyup;
ConsoleLine.OnContextPopup:=@Form1.CheckConsoLinePopUp;
ConsoleLine.PopupMenu:=ConsoLinePopUp ;

DataPanel := TStringGrid.Create(Form1);DataPanel.Parent:=Form1.tabconsole;
DataPanel.Left:=0;DataPanel.Top:=250;DataPanel.Height:=180;DataPanel.Width:=388;
DataPanel.DefaultRowHeight:=UserRowHeigth;
DataPanel.Font.Size:=UserFontSize;
DataPanel.ColCount:=4;DataPanel.rowcount:=8;DataPanel.FixedCols:=0;DataPanel.FixedRows:=0;
DataPanel.enabled:= false;
DataPanel.ScrollBars:=ssnone;
DataPanel.ColWidths[0]:= 79;DataPanel.ColWidths[1]:= 115;DataPanel.ColWidths[2]:= 79;DataPanel.ColWidths[3]:= 115;
DataPanel.Visible:=true;
DataPanel.OnPrepareCanvas:= @Form1.Grid1PrepareCanvas;
DataPanel.FocusRectVisible:=false;

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
Form1.imagenes.GetBitmap(4,MinerButton.Glyph);MinerButton.Visible:=false;
MinerButton.Caption:='';MinerButton.OnClick:=@Form1.MinerCircleOnClick;
MinerButton.ShowHint:=true;MinerButton.OnMouseEnter:=@Form1.CheckForHint;

SBOptions := TSpeedButton.Create(Form1);SBOptions.Parent:=Form1;
SBOptions.Left:=58;SBOptions.Top:=2;SBOptions.Height:=26;SBOptions.Width:=26;
Form1.imagenes.GetBitmap(22,SBOptions.Glyph);
SBOptions.Visible:=false;SBOptions.OnClick:=@form1.SBOptionsOnClick;
SBOptions.hint:='Show/Hide options';SBOptions.ShowHint:=true;

ImageInc := TImage.Create(form1);ImageInc.Parent:=form1;
ImageInc.Top:=2;ImageInc.Left:=86;ImageInc.Height:=17;ImageInc.Width:=17;
Form1.imagenes.GetBitMap(9,ImageInc.Picture.Bitmap);ImageInc.Visible:=false;
ImageInc.ShowHint:=true;ImageInc.OnMouseEnter:=@Form1.CheckForHint;

ImageOut := TImage.Create(form1);ImageOut.Parent:=form1;
ImageOut.Top:=12;ImageOut.Left:=93;ImageOut.Height:=17;ImageOut.Width:=17;
Form1.imagenes.GetBitmap(10,Imageout.Picture.Bitmap);ImageOut.Visible:=false;
ImageOut.ShowHint:=true;ImageOut.OnMouseEnter:=@Form1.CheckForHint;

DireccionesPanel := TStringGrid.Create(Form1);DireccionesPanel.Parent:=form1.TabWallet;
DireccionesPanel.Left:=0;DireccionesPanel.Top:=0;DireccionesPanel.Height:=135;DireccionesPanel.Width:=388;
DireccionesPanel.ColCount:=2;DireccionesPanel.rowcount:=1;DireccionesPanel.FixedCols:=0;DireccionesPanel.FixedRows:=0;
DireccionesPanel.FixedRows:=1;
DireccionesPanel.ScrollBars:=ssVertical;
DireccionesPanel.Options:= DireccionesPanel.Options+[goRowSelect]-[goRangeSelect];
DireccionesPanel.Font.Name:='consolas'; DireccionesPanel.Font.Size:=10;
DireccionesPanel.ColWidths[0]:= 260;DireccionesPanel.ColWidths[1]:= 107;
DireccionesPanel.OnPrepareCanvas:= @Form1.Grid2PrepareCanvas;
DireccionesPanel.FocusRectVisible:=false;

  BDefAddr := TSpeedButton.Create(form1);BDefAddr.Parent:=DireccionesPanel;
  BDefAddr.Top:=2;BDefAddr.Left:=168;BDefAddr.Height:=18;BDefAddr.Width:=18;
  Form1.imagenes.GetBitmap(40,BDefAddr.Glyph);
  BDefAddr.Caption:='';BDefAddr.OnClick:=@Form1.BDefAddrOnClick;
  BDefAddr.Hint:='Set as Default';BDefAddr.ShowHint:=true;

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

PanelSend := TPanel.Create(Form1);PanelSend.Parent:=form1.TabWallet;
PanelSend.Left:=0;PanelSend.Top:=0;PanelSend.Height:=135;PanelSend.Width:=388;
PanelSend.BevelColor:=clBlack;PanelSend.Visible:=false;
PanelSend.font.Name:='consolas';PanelSend.Font.Size:=14;
  // La etiqueta que identifica el panel 'send coins';
  LSCTop := TLabel.Create(PanelSend);LSCTop.Parent := PanelSend;
  LSCTop.Top :=2;LSCTop.Left:=152;LSCTop.AutoSize:=true;       //Send coins
  LSCTop.Caption:=LangLine(66);

  BCLoseSend := TSpeedButton.Create(Form1);BCLoseSend.Parent:=PanelSend;
  BCLoseSend.Left:=369;BCLoseSend.Top:=2;
  BCLoseSend.Height:=18;BCLoseSend.Width:=18;
  Form1.imagenes.GetBitmap(14,BCLoseSend.Glyph);
  BCLoseSend.Visible:=true;BCLoseSend.OnClick:=@form1.BCLoseSendOnClick;

  SGridSC := TStringGrid.Create(Form1);SGridSC.Parent:=PanelSend;
  SGridSC.Left:=8;SGridSC.Top:=24;SGridSC.Height:=57;SGridSC.Width:=115;
  SGridSC.ColCount:=1;SGridSC.rowcount:=3;SGridSC.FixedCols:=1;SGridSC.FixedRows:=0;
  SGridSC.DefaultColWidth:=120;SGridSC.DefaultRowHeight:=18;
  SGridSC.ScrollBars:=ssnone;SGridSC.Font.Size:=9;SGridSC.Enabled := false;
  SGridSC.FocusRectVisible:=false;

  SBSCPaste := TSpeedButton.Create(PanelSend);SBSCPaste.Parent:=PanelSend;
  SBSCPaste.Left:=124;SBSCPaste.Top:=24;SBSCPaste.Height:=18;SBSCPaste.Width:=18;
  Form1.imagenes.GetBitmap(15,SBSCPaste.Glyph);
  SBSCPaste.Visible:=true;SBSCPaste.OnClick:=@form1.SBSCPasteOnClick;
  SBSCPaste.hint:=LangLine(67);SBSCPaste.ShowHint:=true;           //Paste destination

  SBSCMax := TSpeedButton.Create(Form1);SBSCMax.Parent:=PanelSend;
  SBSCMax.Left:=124;SBSCMax.Top:=42;SBSCMax.Height:=18;SBSCMax.Width:=18;
  Form1.imagenes.GetBitmap(6,SBSCMax.Glyph);
  SBSCMax.Visible:=true;SBSCMax.OnClick:=@form1.SBSCMaxOnClick;
  SBSCMax.hint:=LangLine(68);SBSCMax.ShowHint:=true;             //Send all

  EditSCDest := TEdit.Create(Form1);EditSCDest.Parent:=PanelSend;EditSCDest.AutoSize:=false;
  EditSCDest.Left:=144;EditSCDest.Top:=24;EditSCDest.Height:=18;EditSCDest.Width:=222;
  EditSCDest.Font.Name:='consolas'; EditSCDest.Font.Size:=8;
  EditSCDest.Alignment:=taRightJustify;EditSCDest.Visible:=true;
  EditSCDest.OnChange:=@form1.EditSCDestChange;EditSCDest.OnContextPopup:=@form1.DisablePopUpMenu;

  EditSCMont := TEdit.Create(Form1);EditSCMont.Parent:=PanelSend;EditSCMont.AutoSize:=false;
  EditSCMont.Left:=144;EditSCMont.Top:=42;EditSCMont.Height:=18;EditSCMont.Width:=222;
  EditSCMont.Font.Name:='consolas'; EditSCMont.Font.Size:=8;
  EditSCMont.ReadOnly:=true;EditSCMont.Text:='0.00000000';
  EditSCMont.Alignment:=taRightJustify;EditSCMont.Visible:=true;
  EditSCMont.OnKeyPress :=@form1.EditMontoOnKeyUp;
  EditSCMont.OnChange:=@form1.EditSCMontChange;EditSCMont.OnContextPopup:=@form1.DisablePopUpMenu;

  ImgSCDest := TImage.Create(form1);ImgSCDest.Parent:=PanelSend;
  ImgSCDest.Top:=24;ImgSCDest.Left:=369;ImgSCDest.Height:=16;ImgSCDest.Width:=16;
  ImgSCDest.Visible:=true;

  ImgSCMont := TImage.Create(form1);ImgSCMont.Parent:=PanelSend;
  ImgSCMont.Top:=42;ImgSCMont.Left:=369;ImgSCMont.Height:=16;ImgSCMont.Width:=16;
  ImgSCMont.Visible:=true;

  MemoSCCon := TMemo.Create(Form1);MemoSCCon.Parent:=PanelSend;
  MemoSCCon.Left:=124;MemoSCCon.Top:=60;MemoSCCon.Height:=40;MemoSCCon.Width:=242;
  MemoSCCon.Font.Size:=10;MemoSCCon.Font.Name:='consolas';
  MemoSCCon.MaxLength:=64;
  MemoSCCon.Visible:=true;MemoSCCon.ScrollBars:=ssnone;
  MemoSCCon.OnContextPopup:=@form1.DisablePopUpMenu;

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

GridMyTxs := TStringGrid.Create(Form1);GridMyTxs.Parent:=Form1.TabWallet;
GridMyTxs.Left:=0;GridMyTxs.Top:=136;GridMyTxs.Height:=135;GridMyTxs.Width:=388;
GridMyTxs.ColCount:=11;GridMyTxs.rowcount:=1;GridMyTxs.FixedCols:=0;GridMyTxs.FixedRows:=1;
GridMyTxs.ScrollBars:=ssVertical;
GridMyTxs.SelectedColor:=clLtGray;
GridMyTxs.Options:= GridMyTxs.Options+[goRowSelect]-[goRangeSelect];
GridMyTxs.Font.Name:='consolas'; GridMyTxs.Font.Size:=10;
GridMyTxs.ColWidths[0]:= 60;GridMyTxs.ColWidths[1]:= 60;GridMyTxs.ColWidths[2]:= 100;
GridMyTxs.ColWidths[3]:= 147;
GridMyTxs.OnPrepareCanvas:= @Form1.GridMyTxsPrepareCanvas;
GridMyTxs.FocusRectVisible:=false;

  BitInfoTrx := TSpeedButton.Create(Form1);BitInfoTrx.Parent:=GridMyTxs;
  BitInfoTrx.Left:=224;BitInfoTrx.Top:=2;BitInfoTrx.Height:=18;BitInfoTrx.Width:=18;
  Form1.imagenes.GetBitmap(13,BitInfoTrx.Glyph);
  BitInfoTrx.Visible:=true;BitInfoTrx.OnClick:=@form1.GridMyTxsOnDoubleClick;
  BitInfoTrx.hint:=LangLine(73);BitInfoTrx.ShowHint:=true; //'Transaction details'

  BitPosInfo := TSpeedButton.Create(Form1);BitPosInfo.Parent:=GridMyTxs;
  BitPosInfo.Left:=244;BitPosInfo.Top:=2;BitPosInfo.Height:=18;BitPosInfo.Width:=18;
  Form1.imagenes.GetBitmap(53,BitPosInfo.Glyph);
  BitPosInfo.Visible:=true;BitPosInfo.OnClick:=@form1.BitPosInfoOnClick;
  BitPosInfo.hint:='PoS Statistics';BitPosInfo.ShowHint:=true; //'Transaction details'

PanelTrxDetails := TPanel.Create(Form1);PanelTrxDetails.Parent:=Form1.TabWallet;
PanelTrxDetails.Left:=0;PanelTrxDetails.Top:=136;PanelTrxDetails.Height:=135;PanelTrxDetails.Width:=388;
PanelTrxDetails.BevelColor:=clBlack;PanelTrxDetails.Visible:=false;
PanelTrxDetails.font.Name:='consolas';PanelTrxDetails.Font.Size:=14;
PanelTrxDetails.OnContextPopup:=@form1.DisablePopUpMenu;

   MemoTrxDetails := TMemo.Create(Form1);MemoTrxDetails.Parent:=PanelTrxDetails;
   MemoTrxDetails.Font.Size:=10;MemoTrxDetails.ReadOnly:=true;
   MemoTrxDetails.Color:=clForm;MemoTrxDetails.BorderStyle:=bsNone;
   MemoTrxDetails.Height:=115;MemoTrxDetails.Width:=381;
   MemoTrxDetails.Font.Name:='consolas';MemoTrxDetails.Alignment:=taLeftJustify;
   MemoTrxDetails.Left:=5;MemoTrxDetails.Top:=10;MemoTrxDetails.AutoSize:=false;
   MemoTrxDetails.OnContextPopup:=@Form1.CheckTrxDetailsPopUp;
   MemoTrxDetails.PopupMenu:=TrxDetailsPopUp ;

   BCloseTrxDetails := TbitBtn.Create(Form1);BCloseTrxDetails.Parent:=PanelTrxDetails;
   BCloseTrxDetails.Left:=369;BCloseTrxDetails.Top:=2;
   BCloseTrxDetails.Height:=18;BCloseTrxDetails.Width:=18;
   Form1.imagenes.GetBitmap(14,BCloseTrxDetails.Glyph);BCloseTrxDetails.Caption:='';
   BCloseTrxDetails.BiDiMode:= bdRightToLeft;
   BCloseTrxDetails.Visible:=true;BCloseTrxDetails.OnClick:=@form1.BCloseTrxDetailsOnClick;

InfoPanel := TPanel.Create(Form1);InfoPanel.Parent:=form1;
InfoPanel.Font.Name:='consolas';InfoPanel.Font.Size:=8;
InfoPanel.Left:=100;InfoPanel.AutoSize:=false;
InfoPanel.Color:=clMedGray;
InfoPanel.Top:=245;InfoPanel.Font.Color:=clBlack;
InfoPanel.Width:=200;InfoPanel.Height:=20;InfoPanel.Alignment:=tacenter;
InfoPanel.Caption:='';InfoPanel.Visible:=true;
InfoPanel.BringToFront;

StatusPanel := TPanel.Create(Form1);StatusPanel.Parent:=form1;
StatusPanel.Font.Name:='consolas';StatusPanel.Font.Size:=8;
StatusPanel.Left:=2;StatusPanel.AutoSize:=false;
StatusPanel.Color:=clMedGray;
StatusPanel.Top:=488;StatusPanel.Font.Color:=clBlack;
StatusPanel.Width:=396;StatusPanel.Height:=20;StatusPanel.Alignment:=tacenter;
StatusPanel.Caption:='';StatusPanel.Visible:=true;
StatusPanel.BringToFront;

  StaConRot := TLabel.Create(StatusPanel);StaConRot.Parent := StatusPanel;StaConRot.AutoSize:=false;
  {StaConRot.Font.Name:='consolas';}StaConRot.Font.Size:=8;
  StaConRot.Width:= 16; StaConRot.Height:= 16;StaConRot.Top:= 2; StaConRot.Left:= 2;
  StaConRot.Caption:='|';StaConRot.Alignment:=taCenter;

  StaRPCLab := TLabel.Create(StatusPanel);StaRPCLab.Parent := StatusPanel;StaRPCLab.AutoSize:=false;
  StaRPCLab.Font.Name:='consolas';StaRPCLab.Font.Size:=8;
  StaRPCLab.Width:= 16; StaRPCLab.Height:= 16;StaRPCLab.Top:= 2; StaRPCLab.Left:= 22;
  StaRPCLab.Caption:='';StaRPCLab.Alignment:=taCenter;StaRPCLab.Transparent:=false;StaRPCLab.Color:=clMoneyGreen;

  StaSerImg:= TImage.Create(StatusPanel);StaSerImg.Parent := StatusPanel;
  StaSerImg.Width:= 16; StaSerImg.Height:= 16;StaSerImg.Top:= 2; StaSerImg.Left:= 22;
  Form1.imagenes.GetBitMap(27,StaSerImg.picture.BitMap);StaSerImg.Visible:=false;

  StaConLab := TLabel.Create(StatusPanel);StaConLab.Parent := StatusPanel;StaConLab.AutoSize:=false;
  StaConLab.Font.Name:='consolas';StaConLab.Font.Size:=8;
  StaConLab.Width:= 20; StaConLab.Height:= 14;StaConLab.Top:= 4; StaConLab.Left:= 42;
  StaConLab.Caption:='0';StaConLab.Alignment:=taCenter;StaConLab.Transparent:=false;StaConLab.Color:=clRed;

  StaBloImg:= TImage.Create(StatusPanel);StaBloImg.Parent := StatusPanel;
  StaBloImg.Width:= 16; StaBloImg.Height:= 16;StaBloImg.Top:= 2; StaBloImg.Left:= 66;
  Form1.imagenes.GetBitmap(45,StaBloImg.picture.Bitmap);StaBloImg.Visible:=true;

  StaBloLab := TLabel.Create(StatusPanel);StaBloLab.Parent := StatusPanel;StaBloLab.AutoSize:=false;
  StaBloLab.Font.Name:='consolas';StaBloLab.Font.Size:=8;
  StaBloLab.Width:= 50; StaBloLab.Height:= 16;StaBloLab.Top:= 4; StaBloLab.Left:= 84;
  StaBloLab.Caption:='999999';StaBloLab.Alignment:=taLeftjustify;StaConLab.Transparent:=false;StaConLab.Color:=clgray;

  StaPenImg:= TImage.Create(StatusPanel);StaPenImg.Parent := StatusPanel;
  StaPenImg.Width:= 16; StaPenImg.Height:= 16;StaPenImg.Top:= 2; StaPenImg.Left:= 140;
  Form1.imagenes.GetBitmap(46,StaPenImg.picture.Bitmap);StaPenImg.Visible:=true;

  StaPenLab := TLabel.Create(StatusPanel);StaPenLab.Parent := StatusPanel;StaPenLab.AutoSize:=false;
  StaPenLab.Font.Name:='consolas';StaPenLab.Font.Size:=8;
  StaPenLab.Width:= 50; StaPenLab.Height:= 14;StaPenLab.Top:= 4; StaPenLab.Left:= 160;
  StaPenLab.Caption:='9999';StaPenLab.Alignment:=taleftjustify;

  StaMinLab := TLabel.Create(StatusPanel);StaMinLab.Parent := StatusPanel;StaMinLab.AutoSize:=false;
  StaMinLab.Font.Name:='consolas';StaMinLab.Font.Size:=8;
  StaMinLab.Width:= 58; StaMinLab.Height:= 14;StaMinLab.Top:= 4; StaMinLab.Left:= 330;
  StaMinLab.Caption:='9999Kh';StaMinLab.Alignment:=tarightjustify;StaMinLab.Transparent:=false;StaMinLab.Color:=clmenu;

  StaPoolSer:= TImage.Create(StatusPanel);StaPoolSer.Parent := StatusPanel;
  StaPoolSer.Width:= 16; StaPoolSer.Height:= 16;StaPoolSer.Top:= 2; StaPoolSer.Left:= 290;
  Form1.imagenes.GetBitmap(27,StaPoolSer.picture.Bitmap);StaPoolSer.Visible:=false;

  StaMinImg:= TImage.Create(StatusPanel);StaMinImg.Parent := StatusPanel;
  StaMinImg.Width:= 16; StaMinImg.Height:= 16;StaMinImg.Top:= 2; StaMinImg.Left:= 330;
  Form1.imagenes.GetBitmap(11,StaMinImg.picture.Bitmap);StaBloImg.Visible:=true;

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
Form1.InfoTimer.Enabled:=false;Form1.InfoTimer.Interval:=50;
Form1.InfoTimer.OnTimer:= @form1.InfoTimerEnd;

Form1.CloseTimer:= TTimer.Create(Form1);
Form1.CloseTimer.Enabled:=false;Form1.CloseTimer.Interval:=20;
Form1.CloseTimer.OnTimer:= @form1.CloseTimerEnd;

form1.SystrayIcon := TTrayIcon.Create(form1);
form1.SystrayIcon.BalloonTimeout:=3000;
form1.SystrayIcon.BalloonTitle:=CoinName+' Wallet';
form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion;
form1.SysTrayIcon.OnDblClick:=@form1.DoubleClickSysTray;
form1.imagenes.GetIcon(48,form1.SystrayIcon.icon);

Form1.Server := TIdTCPServer.Create(Form1);
Form1.Server.DefaultPort:=DefaultServerPort;
Form1.Server.Active:=false;
Form1.Server.UseNagle:=true;
Form1.Server.TerminateWaitTime:=5000;
Form1.Server.OnExecute:=@form1.IdTCPServer1Execute;
Form1.Server.OnConnect:=@form1.IdTCPServer1Connect;
Form1.Server.OnDisconnect:=@form1.IdTCPServer1Disconnect;
Form1.Server.OnException:=@Form1.IdTCPServer1Exception;

Form1.PoolServer := TIdTCPServer.Create(Form1);
Form1.PoolServer.DefaultPort:=DefaultServerPort;
Form1.PoolServer.Active:=false;
Form1.PoolServer.UseNagle:=true;
Form1.PoolServer.TerminateWaitTime:=50000;
Form1.PoolServer.OnExecute:=@form1.PoolServerExecute;
Form1.PoolServer.OnConnect:=@form1.PoolServerConnect;
Form1.PoolServer.OnDisconnect:=@form1.PoolServerDisconnect;
Form1.PoolServer.OnException:=@Form1.PoolServerException;

Form1.RPCServer := TIdHTTPServer.Create(Form1);
Form1.RPCServer.DefaultPort:=RPCPort;
Form1.RPCServer.Active:=false;
Form1.RPCServer.UseNagle:=true;
Form1.RPCServer.TerminateWaitTime:=50000;
Form1.RPCServer.OnCommandGet:=@form1.RPCServerExecute;
//Form1.RPCServer.OnConnect:=@form1.RPCServerConnect;
//Form1.RCPServer.OnDisconnect:=@form1.PoolServerDisconnect;
//Form1.RCPServer.OnException:=@Form1.PoolServerException;
End;

// Funciones del Servidor RPC

// A RPC REQUEST ENTERS
procedure TForm1.RPCServerExecute(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  PostString: TJSONStringType = '';
  StreamString: TStream ;
Begin
if ARequestInfo.Command <> 'POST' then
   begin
   AResponseInfo.ContentText:= GetJSONErrorCode(400,1);
   end
else if ARequestInfo.Command = 'POST' then
   begin  // Is a post request
   StreamString := ARequestInfo.PostStream;
   if assigned(StreamString) then
      begin
      StreamString.Position:=0;
      PostString := ReadStringFromStream(StreamString,-1,IndyTextEncoding_UTF8);
      end;
   AResponseInfo.ContentText:= ParseRPCJSON(PostString);
   end;
End;

// MOSTLY DEPRECATED
procedure TForm1.RPCServerConnect(AContext: TIdContext);
var
  CloseConnection : boolean = false;
  IpUser, Linea, password,comando : string;
  direccion, orderid : string;
  resultorder : orderdata; orderconfirmations : string;
  TextToSend : String = '';
  BlockSolTime, BlockSolNumber, BlockSolMiner, BlockSolution : String;
  BlockVerification : integer;
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
Linea := AContext.Connection.IOHandler.ReadLn('',ReadTimeOutTIme,-1,IndyTextEncoding_UTF8);
password := parameter(linea,0);
comando := parameter(linea,1);
ConsoleLinesAdd('RPC Line: '+Linea);
if password <> RPCPass then
   begin
   TextToSend := 'PASSFAILED';
   CloseConnection := true;
   end
else
   begin
   if UpperCase(comando) = 'TEST' then
      begin
      TextToSend := 'TESTOK';
      CloseConnection := true;
      end;
   if UpperCase(comando) = 'ADBAL' then
      begin
      direccion := parameter(linea,2);
      TextToSend := Int2Curr(GetAddressBalance(direccion))+' '+
         Int2Curr(GetAddressPendingPays(direccion))+' '+
         Int2Curr(GetAddressBalance(direccion)-GetAddressPendingPays(direccion)) ;
      CloseConnection := true;
      end;
   if UpperCase(comando) = 'ORDERID' then
      begin
      orderid := parameter(linea,2);
      if orderid <> '' then resultorder := GetOrderDetails(orderid)
      else resultorder := Default(orderdata);
      if resultorder.AmmountTrf<=0 then Acontext.Connection.IOHandler.WriteLn('INVALID')
      else
         begin
         if resultorder.Block = 0 then orderconfirmations := 'Pending'
         else orderconfirmations := IntToStr(MyLastBlock-resultorder.Block);
         TextToSend :=orderconfirmations+' '+TimestampToDate(IntToStr(resultorder.TimeStamp))+' '+
            resultorder.Concept+' '+resultorder.Receiver+' '+Int2curr(resultorder.AmmountTrf);
         end;
      CloseConnection := true;
      end;
   if UpperCase(comando) = 'POOLDATA' then
      begin
      TextToSend := 'POOLDATA '+IntToStr(MyLastBlock)+' '+IntToStr(LastBlockData.NxtBlkDiff)+' '+MyLastBlockHash;
      if RPC_MinerReward > 0 then
         begin
         TextToSend := TextToSend+slinebreak+'REWARD '+IntToStr(RPC_MinerReward);
         RPC_MinerReward := 0;
         end;
      end;
   if UpperCase(comando) = 'POOLSOL' then
      begin
      BlockSolTime := UTCTime;
      BlockSolNumber := parameter(linea, 3);
      BlockSolMiner := parameter(linea, 4);
      BlockSolution := parameter(linea, 5);
      BlockSolution := StringReplace(BlockSolution,'_',' ',[rfReplaceAll, rfIgnoreCase]);
      BlockVerification := VerifySolutionForBlock(LastBlockData.NxtBlkDiff, MyLastBlockHash,BlockSolMiner ,BlockSolution);
      if BlockVerification = 0 then
         begin
         ConsoleLinesAdd('Pool solution verified');
         OutgoingMsjsAdd(ProtocolLine(6)+BlockSolTime+' '+BlockSolNumber+' '+
               BlockSolMiner+' '+StringReplace(BlockSolution,' ','_',[rfReplaceAll, rfIgnoreCase]));
         ResetPoolMiningInfo();
         TextToSend := 'BLOCKSOLOK '+BlockSolNumber;
         RPC_MinerInfo := BlockSolMiner;
         end;
      end;
   end;
TRY
   Acontext.Connection.IOHandler.WriteLn(TextToSend);
   if CloseConnection then
      begin
      AContext.Connection.Disconnect;
      Acontext.Connection.IOHandler.InputBuffer.Clear;
      end;
EXCEPT on E:Exception do ToLog('Error on RPC request:'+E.Message);
END;
End;

// *******************
// *** POOL SERVER ***
// *******************

// returns the number of active connections
function TForm1.PoolClientsCount : Integer ;
var
  Clients : TList;
begin
  Clients:= PoolServer.Contexts.LockList;
  try
    Result := Clients.Count ;
  finally
    PoolServer.Contexts.UnlockList;
  end;
end ;

// Try to close a pool connection safely
Procedure TForm1.TryClosePoolConnection(AContext: TIdContext; closemsg:string='');
Begin
try
   if closemsg <>'' then
      Acontext.Connection.IOHandler.WriteLn(closemsg);
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   AContext.Connection.Disconnect;
Except on E:Exception do
   ToExcLog('POOL: Error trying close a pool client connection ('+E.Message+')');
end;
End;

// Funciones del servidor Pool

// El servidor del pool recibe una linea
procedure TForm1.PoolServerExecute(AContext: TIdContext);
var
  Linea, IPUser : String;
  Password, UserDireccion, Comando : String;
  MemberBalance : Int64;
  BloqueStep: integer; SeedStep, HashStep,Solucion : String;
  PoolSolutionStep : integer = 0;
  StepLength, StepValue, StepBase : integer;
  BlockTime : string;
  SendFundsResult : string = '';
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
Linea := AContext.Connection.IOHandler.ReadLn('',ReadTimeOutTIme,-1,IndyTextEncoding_UTF8);
Password := Parameter(Linea,0);
if password <> Poolinfo.PassWord then exit;
UserDireccion := Parameter(Linea,1);
Comando := Parameter(Linea,2);
MemberBalance := GetPoolMemberBalance(UserDireccion);
// *** NEW MINER FORMAT ***
if comando = 'PING' then
   begin
   Acontext.Connection.IOHandler.WriteLn('PONG '+PoolDataString(UserDireccion));
   PoolServerConex[IsPoolMemberConnected(UserDireccion)].Hashpower:=StrToIntDef(Parameter(linea,3),0);
   PoolServerConex[IsPoolMemberConnected(UserDireccion)].LastPing:=StrToInt64Def(UTCTime,0);
   end
else if Comando = 'STEP' then
   begin
   EnterCriticalSection(CSPoolStep);
   PoolServerConex[IsPoolMemberConnected(UserDireccion)].LastPing:=StrToInt64Def(UTCTime,0);
   bloqueStep := StrToIntDef(parameter(linea,3),0);
   SeedStep := parameter(linea,4);
   HashStep := parameter(linea,5);
   StepLength := StrToIntDef(parameter(linea,6),-1);
   StepBase := GetCharsFromDifficult(PoolMiner.Dificult, 0)-PoolStepsDeep; //Get the minimun steplength
   if StepLength<0 then StepLength := PoolMiner.DiffChars;
   StepValue := 16**(StepLength-Stepbase);
   Solucion := HashSha256String(SeedStep+PoolInfo.Direccion+HashStep);
   if ((StepLength>=StepBase) and (StepLength<PoolMiner.DiffChars)) then
      begin                                       // Proof of work solution
      if ( (AnsiContainsStr(Solucion,copy(PoolMiner.Target,1,StepLength))) and
         (GetPoolMemberBalance(UserDireccion)>-1) and (bloqueStep=PoolMiner.Block) and
         (PoolMiner.steps<10) and (not StepAlreadyAdded(SeedStep+HashStep)) ) then
         begin
         AcreditarPoolStep(UserDireccion, StepValue);
         Acontext.Connection.IOHandler.WriteLn('STEPOK '+IntToStr(StepValue));
         insert(SeedStep+HashStep,Miner_PoolSharedStep,length(Miner_PoolSharedStep)+1);
         end;
      end
   else if ( (AnsiContainsStr(Solucion,copy(PoolMiner.Target,1,PoolMiner.DiffChars))) and
       (GetPoolMemberBalance(UserDireccion)>-1) and (bloqueStep=PoolMiner.Block) and
       (IsValidStep(PoolMiner.Solucion,SeedStep+HashStep)) and (PoolMiner.steps<10) and
       (not StepAlreadyAdded(SeedStep+HashStep)) ) then
      begin
      AcreditarPoolStep(UserDireccion, StepValue);
      Acontext.Connection.IOHandler.WriteLn('STEPOK '+IntToStr(StepValue));
      insert(SeedStep+HashStep,Miner_PoolSharedStep,length(Miner_PoolSharedStep)+1);
      PoolMiner.Solucion := PoolMiner.Solucion+SeedStep+HashStep+' ';
      PoolMiner.steps := PoolMiner.steps+1;
      PoolMiner.DiffChars:=GetCharsFromDifficult(PoolMiner.Dificult, PoolMiner.steps);
      if PoolMiner.steps = Miner_Steps then
         begin
         SetLength(PoolMiner.Solucion,length(PoolMiner.Solucion)-1);
         PoolSolutionStep := VerifySolutionForBlock(PoolMiner.Dificult, PoolMiner.Target,PoolInfo.Direccion , PoolMiner.Solucion);
         if PoolSolutionStep=0 then
            Begin
            BlockTime := UTCTime;
            consolelinesAdd('Pool solution verified!');
            OutgoingMsjsAdd(ProtocolLine(6)+BlockTime+' '+IntToStr(PoolMiner.Block)+' '+
               PoolInfo.Direccion+' '+StringReplace(PoolMiner.Solucion,' ','_',[rfReplaceAll, rfIgnoreCase]));
            ResetPoolMiningInfo();
            //SendNetworkRequests(blocktime,PoolInfo.Direccion,PoolMiner.Block);
            end
         else
            begin
            consolelinesAdd('Pool solution FAILED at step '+IntToStr(PoolSolutionStep));
            PoolSolutionFails := PoolSolutionFails+1;
            if PoolSolutionFails >= 3 then
               begin
               PoolSolutionFails := 0;PoolMiner.Solucion := '';PoolMiner.steps:=0;
               end
            else
               begin
               PoolMiner.Solucion:=TruncateBlockSolution(PoolMiner.Solucion,PoolSolutionStep);
               PoolMiner.steps := PoolSolutionStep-1;
               end;
            PoolMiner.DiffChars:=GetCharsFromDifficult(PoolMiner.Dificult, PoolMiner.steps);
            ProcessLinesAdd('SENDPOOLSTEPS '+IntToStr(PoolMiner.steps));
            end;
         end
      else
         begin
         ProcessLinesAdd('SENDPOOLSTEPS '+IntToStr(PoolMiner.steps));
         end;
      end
   else
      begin
      if ((bloqueStep=PoolMiner.Block) and (1=1)) then
         begin
         Acontext.Connection.IOHandler.WriteLn('STEPFAIL');
         PoolServerConex[IsPoolMemberConnected(UserDireccion)].WrongSteps+=1;
         end;
      end;
   LeaveCriticalSection(CSPoolStep);
   end
else if Comando = 'PAYMENT' then
   Begin
   if GetLastPagoPoolMember(UserDireccion)+PoolInfo.TipoPago<MyLastBlock then
      begin
      if memberbalance > 0 then
         begin
         SendFundsResult := SendFunds('sendto '+UserDireccion+' '+IntToStr(GetMaximunToSend(MemberBalance))+' POOLPAYMENT_'+PoolInfo.Name);
         //ProcessLinesAdd('sendto '+UserDireccion+' '+IntToStr(GetMaximunToSend(MemberBalance))+' POOLPAYMENT_'+PoolInfo.Name);
         if SendFundsResult <> '' then // payments is done
            begin
            ClearPoolUserBalance(UserDireccion);
            Acontext.Connection.IOHandler.WriteLn('PAYMENTOK '+UTCTime+' POOLIP '+
               UserDireccion+' 2 '+IntToStr(MyLastBlock)+' '+int2curr(GetMaximunToSend(MemberBalance))+' '+
               SendFundsResult);
            AddPoolPay(IntToStr(MyLastBlock+1)+' '+UserDireccion+' '+IntToStr(GetMaximunToSend(MemberBalance))+' '+
               SendFundsResult);
            PoolMembersTotalDeuda := GetTotalPoolDeuda();
            end
         else                // PAYMENT SEND FUNDS FAIL
            begin
            Acontext.Connection.IOHandler.WriteLn('PAYMENTFAIL TRYAGAIN');
            end;
         end
      else
         begin
         Acontext.Connection.IOHandler.WriteLn('PAYMENTEMPTY');
         end;
      end
   else
      begin
      Acontext.Connection.IOHandler.WriteLn('PAYMENTFAIL');
      end;
   end
else
   begin
   ToExcLog('Pool Unexpected command from: '+ipuser+'->'+Linea);
   //ConsoleLinesAdd('UNEXPECTED_COMMAND');
   end;
End;

// Al conectarse un miembro del pool
procedure TForm1.PoolServerConnect(AContext: TIdContext);
var
  IPUser,Linea,password, comando, minerversion, JoinPrefijo : String;
  UserDireccion : string = '';
  WasHandled : boolean = false;
Begin
if PoolClientsCount > PoolInfo.MaxMembers+3 then
  begin
  TryClosePoolConnection(AContext);
  exit;
  end;
EnterCriticalSection(CSMinerJoin);InsideMinerJoin := true;
IPUser := AContext.Connection.Socket.Binding.PeerIP;
Linea := AContext.Connection.IOHandler.ReadLn('',ReadTimeOutTIme,-1,IndyTextEncoding_UTF8);
if AContext.Connection.IOHandler.ReadLnTimedout then
   begin
      try
      AContext.Connection.Disconnect;
      //Tolog('Pool connection ReadTimeOut: '+IPUSER);
      WasHandled := true;
   except end;
   LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
   exit;
   end;
Password := Parameter(Linea,0);
UserDireccion := Parameter(Linea,1);
comando :=Parameter(Linea,2);
minerversion :=Parameter(Linea,3);
if BotExists(IPUser) then
   begin
   //ConsolelinesAdd('Pool Ban: '+IPUser);
   try
      Acontext.Connection.IOHandler.WriteLn('BANNED');
      Acontext.Connection.IOHandler.InputBuffer.Clear;
      AContext.Connection.Disconnect;
      WasHandled := true;
   except end;
   LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
   exit;
   end;
if password <> Poolinfo.PassWord then  // WRONG PASSWORD.
   begin
   try
      Acontext.Connection.IOHandler.WriteLn('PASSFAILED');
      Acontext.Connection.IOHandler.InputBuffer.Clear;
      AContext.Connection.Disconnect;
      WasHandled := true;
   except end;
   LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
   exit;
   end;
if ( (not isvalidaddress(UserDireccion)) and (AddressSumaryIndex(UserDireccion)<0) ) then
   begin
   Acontext.Connection.IOHandler.WriteLn('INVALIDADDRESS');
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   AContext.Connection.Disconnect;
   WasHandled := true;
   LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
   exit;
   end;
if IsPoolMemberConnected(UserDireccion)>=0 then   // ALREADY CONNECTED
   begin
   Acontext.Connection.IOHandler.WriteLn('ALREADYCONNECTED');
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   AContext.Connection.Disconnect;
   WasHandled := true;
   LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
   exit;
   end;
if Comando = 'JOIN' then
   begin
   JoinPrefijo := PoolAddNewMember(UserDireccion);
   if JoinPrefijo<>'' then
      begin
      Acontext.Connection.IOHandler.WriteLn('JOINOK '+PoolInfo.Direccion+' '+JoinPrefijo+' '+PoolDataString(UserDireccion));
      if not SavePoolServerConnection(IpUser,JoinPrefijo, UserDireccion,minerversion,Acontext) then
         begin
         BorrarPoolServerConex(Acontext);
         WasHandled := true;
         LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
         exit;
         end;
      end
   else
      begin
      Acontext.Connection.IOHandler.WriteLn('POOLFULL');
      Acontext.Connection.IOHandler.InputBuffer.Clear;
      AContext.Connection.Disconnect;
      end;
   WasHandled := true;
   end
else if Comando = 'STATUS' then
   begin
   TryClosePoolConnection(AContext,PoolStatusString);
   //Acontext.Connection.IOHandler.WriteLn(PoolStatusString);
   //Acontext.Connection.IOHandler.InputBuffer.Clear;
   //AContext.Connection.Disconnect;
   WasHandled := true;
   end
else if Comando = 'ADDRESSBAL' then
   begin
   UserDireccion := Parameter(Linea,3);
   Acontext.Connection.IOHandler.WriteLn('ADDRESSBAL '+UserDireccion+' '+IntToStr(GetAddressBalance(UserDireccion))+' '+
   IntToStr(GetAddressIncomingpays(UserDireccion))+' '+
   IntToStr(GetAddressPendingPays(UserDireccion))+' '+
   IntToStr(GetAddressBalance(UserDireccion)-GetAddressPendingPays(UserDireccion)));
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   AContext.Connection.Disconnect;
   WasHandled := true;
   end
else
   begin
   Acontext.Connection.IOHandler.WriteLn('INVALIDCOMMAND');
   Acontext.Connection.IOHandler.InputBuffer.Clear;
   AContext.Connection.Disconnect;
   WasHandled := true;
   end;
if not WasHandled then
   begin
      try
      Acontext.Connection.IOHandler.InputBuffer.Clear;
      AContext.Connection.Disconnect;
      WasHandled := true;
      ToExclog('Closed unhandled pool connection: '+IPUSER);
      except end;
   end;
LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
End;

procedure TForm1.PoolServerDisConnect(AContext: TIdContext);
var
  IPUser : string;
Begin
BorrarPoolServerConex(AContext);
End;

procedure TForm1.PoolServerException(AContext: TIdContext;AException: Exception);
var
  IPUser : string;
Begin
BorrarPoolServerConex(AContext);
End;


// *****************************
// *** NODE SERVER FUNCTIONS ***
// *****************************

// returns the number of active connections
function TForm1.ClientsCount : Integer ;
var
  Clients : TList;
begin
  Clients:= server.Contexts.LockList;
  try
    Result := Clients.Count ;
  finally
    server.Contexts.UnlockList;
  end;
end ;

// Trys to close a server connection safely
Procedure TForm1.TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
Begin
try
   if closemsg <>'' then
      Acontext.Connection.IOHandler.WriteLn(closemsg);
   AContext.Connection.Disconnect();
Except on E:Exception do
   ToExcLog('SERVER: Error trying close a server client connection ('+E.Message+')');
end;
End;

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
  GetFileOk : boolean = false;
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
try
   LLine := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   if AContext.Connection.IOHandler.ReadLnTimedout then
      begin
      TryCloseServerConnection(AContext);
      ToExcLog('SERVER: Timeout reading line from connection');
      exit;
      end;
Except on E:Exception do
   begin
   TryCloseServerConnection(AContext);
   ToExcLog('SERVER: Can not read line from connection '+IPUser+'('+E.Message+')');
   exit;
   end;
end;
slot := GetSlotFromIP(IPUser);
if slot = 0 then
  begin
  ToExcLog('SERVER: Received a line from a client without and assigned slot: '+IPUser);
  TryCloseServerConnection(AContext);
  exit;
  end;
conexiones[slot].IsBusy:=true;
if GetCommand(LLine) = 'UPDATE' then
   begin
   UpdateVersion := Parameter(LLine,1);
   UpdateHash := Parameter(LLine,2);
   UpdateClavePublica := Parameter(LLine,3);
   UpdateFirma := Parameter(LLine,4);
   UpdateZipName := 'nosoupdate'+UpdateVersion+'.zip';
   if FileExists(UpdateZipName) then DeleteFile(UpdateZipName);
   AFileStream := TFileStream.Create(UpdateZipName, fmCreate);
   try
      try
      AContext.Connection.IOHandler.ReadStream(AFileStream);
      GetFileOk := true;
      except on E:Exception do
         begin
         ToExcLog('SERVER: Server error receiving update file ('+E.Message+')');
         TryCloseServerConnection(AContext);
         end;
      end;
   finally
   AFileStream.Free;
   end;
   if GetFileOk then
      CheckIncomingUpdateFile(UpdateVersion,UpdateHash,UpdateClavePublica,UpdateFirma,UpdateZipName);
   end
else if GetCommand(LLine) = 'RESUMENFILE' then
   begin
   EnterCriticalSection(CSHeadAccess);
   AFileStream := TFileStream.Create(ResumenFilename, fmCreate);
   DownloadHeaders := true;
   try
      try
      AContext.Connection.IOHandler.ReadStream(AFileStream);
      GetFileOk := true;
      except on E:Exception do
         begin
         ToExcLog('SERVER: Server error receiving headers file ('+E.Message+')');
         TryCloseServerConnection(AContext);
         end;
      end;
   finally
   DownloadHeaders := false;
   AFileStream.Free;
   LeaveCriticalSection(CSHeadAccess);
   end;
   if GetFileOk then
      begin
      ConsoleLinesAdd(LAngLine(74)+': '+copy(HashMD5File(ResumenFilename),1,5)); //'Headers file received'
      LastTimeRequestResumen := 0;
      UpdateMyData();
      end;
   end
else if LLine = 'BLOCKZIP' then
   begin
   BlockZipName := BlockDirectory+'blocks.zip';
   if FileExists(BlockZipName) then DeleteFile(BlockZipName);
   AFileStream := TFileStream.Create(BlockZipName, fmCreate);
   DownLoadBlocks := true;
   try
      try
      AContext.Connection.IOHandler.ReadStream(AFileStream);
      GetFileOk := true;
      except on E:Exception do
         begin
         ToExcLog('SERVER: Server error receiving block file ('+E.Message+')');
         TryCloseServerConnection(AContext);
         end;
      end;
   finally
   AFileStream.Free;
   DownLoadBlocks := false;
   end;
   if GetFileOk then
      begin
      UnzipBlockFile(BlockDirectory+'blocks.zip',true);
      MyLastBlock := GetMyLastUpdatedBlock();
      //BuildHeaderFile(MyLastBlock);
      ResetMinerInfo();
      LastTimeRequestBlock := 0;
      end;
   end
else if parameter(LLine,4) = '$GETRESUMEN' then
   begin
   EnterCriticalSection(CSHeadAccess);
   AFileStream := TFileStream.Create(ResumenFilename, fmOpenRead + fmShareDenyNone);
   LeaveCriticalSection(CSHeadAccess);
      try
      Acontext.Connection.IOHandler.WriteLn('RESUMENFILE');
      Acontext.connection.IOHandler.Write(AFileStream,0,true);
      ConsoleLinesAdd(LangLine(91)+': '+IPUser);//'Headers file sent'
      Except on E:Exception do
         begin
         Form1.TryCloseServerConnection(Conexiones[Slot].context);
         ToExcLog('SERVER: Error sending headers file ('+E.Message+')');
         end;
      end;
   AFileStream.Free;
   end
else if parameter(LLine,4) = '$LASTBLOCK' then
   begin
   BlockZipName := CreateZipBlockfile(StrToIntDef(parameter(LLine,5),0));
   if BlockZipName <> '' then
      begin
      AFileStream := TFileStream.Create(BlockZipName, fmOpenRead + fmShareDenyNone);
      try
         try
         Acontext.Connection.IOHandler.WriteLn('BLOCKZIP');
         Acontext.connection.IOHandler.Write(AFileStream,0,true);
         ToLog('SERVER: BlockZip send to '+IPUser);
         Except on E:Exception do
            begin
            Form1.TryCloseServerConnection(Conexiones[Slot].context);
            ToExcLog('SERVER: Error sending ZIP blocks file ('+E.Message+')');
            end;
         end;
      finally
      AFileStream.Free;
      end;
      Trydeletefile(BlockZipName);
      end
   end
else
   try
   SlotLines[slot].Add(LLine);
   Except
   On E :Exception do
      ToExcLog('SERVER: Server error adding received line ('+E.Message+')');
   end;
conexiones[slot].IsBusy:=false;
End;

// Un usuario intenta conectarse
procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
var
  IPUser : string;
  LLine : String;
  MiIp: String = '';
  Peerversion : string = '';
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
try
   LLine := AContext.Connection.IOHandler.ReadLn('',200,-1,IndyTextEncoding_UTF8);
   if AContext.Connection.IOHandler.ReadLnTimedout then
      begin
      TryCloseServerConnection(AContext);
      ToExcLog('SERVER: Timeout reading line from new connection');
      exit;
      end;
Except on E:Exception do
   begin
   TryCloseServerConnection(AContext);
   ToExcLog('SERVER: Can not read line from new connection ('+E.Message+')');
   exit;
   end;
end;
MiIp := Parameter(LLine,1);
Peerversion := Parameter(LLine,2);
if parameter(LLine,0) = 'NODESTATUS' then
   begin
   TryCloseServerConnection(AContext,'NODESTATUS '+GetNodeStatusString);
   exit;
   end;
if Copy(LLine,1,4) <> 'PSK ' then  // La linea no contiene un comando valido
   begin
   ConsoleLinesAdd(LangLine(8)+IPUser);     //INVALID CLIENT :
   TryCloseServerConnection(AContext);
   UpdateBotData(IPUser);
   exit;
   end
else
   begin
   if IPUser = MyPublicIP then // Nos estamos conectando con nosotros mismos
      begin
      ConsoleLinesAdd(LangLine(9));  //INCOMING CLOSED: OWN CONNECTION
      TryCloseServerConnection(AContext);
      exit;
      end;
   end;
if BotExists(IPUser) then // Es un bot ya conocido
   begin
   //ConsoleLinesAdd(LAngLine(10)+IPUser);             //BLACKLISTED FROM:
   TryCloseServerConnection(AContext,'BANNED');
   //Consolelinesadd('ADDBOT '+(IPUser));
   exit;
   end;
if GetSlotFromIP(IPUser) > 0 then // Conexion duplicada
   begin
   ConsoleLinesAdd(LangLine(11)+IPUser);
   TryCloseServerConnection(AContext,GetPTCEcn+'DUPLICATED');
   UpdateBotData(IPUser);
   exit;
   end;
if Peerversion < ProgramVersion then // version antigua
   begin
   TryCloseServerConnection(AContext,GetPTCEcn+'OLDVERSION');
   exit;
   end;
if SaveConection('CLI',IPUser,Acontext) = 0 then   // Server full
   begin
   TryCloseServerConnection(AContext);
   end
else
   begin    // Se acepta la nueva conexion
   OutText(LangLine(13)+IPUser,true);             //New Connection from:
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
CerrarSlot(GetSlotFromIP(IPUser));
End;

// Excepcion en el servidor
procedure TForm1.IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
var
  IPUser : string;
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
CerrarSlot(GetSlotFromIP(IPUser));
ToExcLog(LangLine(6)+AException.Message);    //Server Excepcion:
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
if (CONNECT_Try) then
   ProcessLinesAdd('disconnect')
else
   begin
   ProcessLinesAdd('connect');
   end;
End;

// click en el boton de minar
Procedure Tform1.MinerCircleOnClick(Sender: TObject);
Begin
if Miner_Active then
   begin
   ProcessLinesAdd('mineroff');
   end
else
   begin
   ProcessLinesAdd('mineron');
   end;
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
      LangLine(83)+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Custom+SLINEBREAK+//'Alias    : '
      'Amount   : '+Int2Curr(Customizationfee);
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

Procedure TForm1.BitPosInfoOnClick (Sender: TObject);
var
   PosRequired : int64;
Begin
PosRequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
PanelTrxDetails.visible := true;
BCloseTrxDetails.Visible:=true;
MemoTrxDetails.Lines.Clear;
MemoTrxDetails.Lines.Add('PoS Statistics'+slinebreak+
                         'My history'+slinebreak+
                         'PoS payouts : '+IntToStr(G_PoSPayouts)+' payouts'+slinebreak+
                         'PoS earnings: '+Int2Curr(G_PoSEarnings)+' Nos'+Slinebreak+
                         'Mainnet'+Slinebreak+
                         'Next block required: '+Int2Curr(PosRequired)+' Nos'+Slinebreak+
                         'My PoS Addresses   : '+IntToStr(GetMyPosAddressesCount));
End;

// Cierra el panel de detalle de transacciones
Procedure TForm1.BCloseTrxDetailsOnClick(Sender: TObject);
Begin
PanelTrxDetails.visible := false;
End;

// Fija como direccion default a la seleccionada
Procedure TForm1.BDefAddrOnClick(Sender: TObject);
Begin
if DireccionesPanel.Row > 0 then
  ProcessLinesAdd('SETDEFAULT '+IntToStr(DireccionesPanel.Row-1));
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

// Leer la pulsacion de enter en la customizacion de una direccion
Procedure Tform1.EditCustomKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
Begin
if Key=VK_RETURN then
   begin
   ProcessLinesAdd('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
   PanelCustom.Visible := false;
   EditCustom.Text := '';
   end;
End;

// Aceptar la personalizacion
Procedure TForm1.BOkCustomClick(Sender: TObject);
Begin
ProcessLinesAdd('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
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
ProcessLinesAdd('newaddress');
End;

// Copia el hash de la direccion al portapapeles
Procedure TForm1.BCopyAddrClick(Sender: TObject);
Begin
if ListaDirecciones[DireccionesPanel.Row-1].custom <> '' then
  Clipboard.AsText:= ListaDirecciones[DireccionesPanel.Row-1].custom
else Clipboard.AsText:= ListaDirecciones[DireccionesPanel.Row-1].Hash;
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
InfoPanelTime := InfoPanelTime-50;
if InfoPanelTime <= 0 then
  begin
  InfoPanelTime := 0;
  InfoPanel.Caption:='';
  InfoPanel.sendtoback;
  end;
end;

// EL timer para forzar el cierre de la aplicacion
Procedure TForm1.CloseTimerEnd(Sender: TObject);
Begin
CloseTimer.Enabled:=false;
ToLog('Quit : '+CurrentJob);
cerrarprograma();
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
EditSCMont.Text:=Int2curr(GetMaximunToSend(GetWalletBalance));
End;

// verifica el destino que marca para enviar coins
Procedure Tform1.EditSCDestChange(Sender:TObject);
Begin
EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
if ((IsValidAddress(EditSCDest.Text)) or (AddressSumaryIndex(EditSCDest.Text)>=0)) then
  Form1.imagenes.GetBitmap(17,ImgSCDest.Picture.Bitmap)
else Form1.imagenes.GetBitmap(14,ImgSCDest.Picture.Bitmap);
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
      ParteEntera := IntToStr(StrToIntDef(ParteEntera,0));
      actualmente := parteentera+'.'+partedecimal;
      EditSCMont.Text:=Actualmente;
      EditSCMont.SelStart := Length(Actualmente)-9;
      end
   else
      begin
      Actualmente[currpos+1] := ultimo;
      ParteEntera := copy(actualmente,1,length(Actualmente)-9);
      ParteEntera := IntToStr(StrToIntDef(ParteEntera,0));
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
   (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)<=GetMaximunToSend(GetWalletBalance)))then
  begin
  Form1.imagenes.GetBitmap(17,ImgSCMont.Picture.Bitmap);
  end
else Form1.imagenes.GetBitmap(14,ImgSCMont.Picture.Bitmap);
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
if ( ( ((AddressSumaryIndex(EditSCDest.Text)>=0) or (IsValidAddress(EditSCDest.Text))) ) and
   (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)>0) and
   (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)<=GetMaximunToSend(GetWalletBalance)) ) then
   begin
   MemoSCCon.Text:=GetCommand(MemoSCCon.text);
   EditSCDest.Enabled:=false;
   EditSCMont.Enabled:=false;
   MemoSCCon.Enabled:=false;
   SCBitSend.Visible:=false;
   SCBitConf.Visible:=true;
   SCBitCancel.Visible:=true;
   end
else info('Invalid parameters');
End;

// confirmar el envio con los valores
Procedure Tform1.SCBitConfOnClick(Sender:TObject);
Begin
ProcessLinesAdd('SENDTO '+EditSCDest.Text+' '+
                          StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase])+' '+
                          MemoSCCon.Text);
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

End;

// Actualizar barra de estado
Procedure UpdateStatusBar();
Begin
if Form1.Server.Active then StaSerImg.Visible:=true
else StaSerImg.Visible:=false;
StaConLab.Caption:=IntToStr(GetTotalConexiones);
if MyConStatus = 0 then StaConLab.Color:= clred;
if MyConStatus = 1 then StaConLab.Color:= clyellow;
if MyConStatus = 2 then StaConLab.Color:= claqua;
if MyConStatus = 3 then StaConLab.Color:= clgreen;
StaBloLab.Caption:=IntToStr(MyLastBlock);
if Miner_IsON then
  begin
  StaMinLab.Visible:=true;
  StaMinLab.Caption:=IntToStr(Miner_EsteIntervalo*5 div 1000)+'Kh ';
  StaMinImg.Visible:=true;
  end
else
   begin
   StaMinLab.Visible:=false;
   StaMinImg.Visible:=false;
   end;
if length(PendingTXs)>0 then
  begin
  StaPenImg.Visible:=true;
  StaPenLab.Visible:=true;staPenLab.Caption:=IntToStr(length(PendingTXs));
  end
else
   begin
   StaPenImg.Visible:=false;
   StaPenLab.Visible:=false;
   end;
if form1.PoolServer.active then StaPoolSer.Visible:=true
else StaPoolSer.Visible:=false;
if form1.RPCServer.active then StaRPCLab.Visible:=true
else StaRPCLab.Visible:=false;
if ConnectedRotor= 0 then StaConRot.Caption:='|';if ConnectedRotor= 1 then StaConRot.Caption:='/';
if ConnectedRotor= 2 then StaConRot.Caption:='--';if ConnectedRotor= 3 then StaConRot.Caption:='\';
End;

//******************************************************************************
// MAINMENU
//******************************************************************************

// Chequea el estado de todo para actualizar los botones del menu principal
Procedure Tform1.CheckMMCaptions(Sender:TObject);
var
  contador: integer;
  version : string;
Begin
if Form1.Server.Active then MainMenu.Items[0].Items[0].Caption:='Stop Server'
else MainMenu.Items[0].Items[0].Caption:='Start Server';
if CONNECT_Try then MainMenu.Items[0].Items[1].Caption:='Disconnect'
else MainMenu.Items[0].Items[1].Caption:='Connect';
if Miner_Active then MainMenu.Items[0].Items[2].Caption:='Stop mining'
else MainMenu.Items[0].Items[2].Caption:='Mine';
MainMenu.Items[1].Items[0].Clear;
MainMenu.Items[1].Items[3].Clear;
if length(StringAvailableUpdates) > 0 then
   begin
   contador := 0;
   repeat
      version := parameter(StringAvailableUpdates,contador);
      if version <> '' then
         begin
         MenuItem := TMenuItem.Create(MainMenu);MenuItem.Caption:=version;MenuItem.OnClick:=@Form1.MMRunUpdate;
         MainMenu.items[1].Items[3].Add(MenuItem);
         end;
      contador +=1;
   until version = '' ;
   end
else MainMenu.items[1].Items[3].Enabled:=false;
if NewLogLines>0 then MainMenu.Items[2].Items[1].Caption:='View Log ('+IntToStr(NewLogLines)+')'
else MainMenu.Items[2].Items[1].Caption:='View Log';
if fileexists(PoolInfoFilename) then MainMenu.Items[2].Items[5].Visible:=true
else MainMenu.Items[2].Items[5].Visible:=false;
End;

// menu principal servidor
Procedure Tform1.MMServer(Sender:TObject);
Begin
if Form1.Server.Active then ProcessLinesAdd('serveroff')
else ProcessLinesAdd('serveron');
End;

// menu principal conexion
Procedure Tform1.MMConnect(Sender:TObject);
Begin
if CONNECT_Try then ProcessLinesAdd('disconnect')
else ProcessLinesAdd('connect');
End;

// menu principal minero
Procedure Tform1.MMMiner(Sender:TObject);
Begin
if Miner_Active then ProcessLinesAdd('mineroff')
else ProcessLinesAdd('mineron');
End;

// menu principal importar cartera
Procedure Tform1.MMImpWallet (Sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Import Wallet','*.pkw','impwallet (-resultado-)',true);
End;

// menu principal exportar cartera
Procedure Tform1.MMExpWallet(Sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Export Wallet to','*.pkw','expwallet (-resultado-)',false);
End;

// menuprincipal about
Procedure Tform1.MMAbout(Sender:TObject);
Begin
formabout.Visible:=true;
End;

// menuprincipal restart
Procedure Tform1.MMRestart(Sender:TObject);
Begin
ProcessLinesAdd('restart');
End;

// menuprincipal salir
Procedure Tform1.MMQuit(Sender:TObject);
Begin
G_CloseRequested := true;
CloseTimer.Enabled:=true;
End;

// menu principal cambiar idioma
Procedure Tform1.MMChangeLang(Sender:TObject);
var
  valor : integer;
Begin
valor := (sender as TMenuItem).MenuIndex;
ProcessLinesAdd('lang '+IntToStr(valor));
End;

// Ejecuta un update seleccionado en el menuprincipal
Procedure Tform1.MMRunUpdate(Sender:TObject);
var
  valor : integer;
Begin
valor := (sender as TMenuItem).MenuIndex;
ProcessLinesAdd('update '+parameter(StringAvailableUpdates,valor));
End;

// menu principal importar idioma
Procedure TForm1.MMImpLang(Sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Import Language','English_*.txt','implang (-resultado-)',true);
End;

// menu principal generar archivo de idioma
Procedure TForm1.MMNewLang(Sender:TObject);
Begin
CreateTraslationFile();
End;

// Menu principal ver consola
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
   PanelSend.Visible:=false;
   GridMyTxs.Visible:=false;
   PanelTrxDetails.Visible:=false;
   ConsoleLine.SetFocus;
   MainMenu.Items[2].Items[0].Caption:='Wallet';
   Form1.imagenes.GetBitmap(30,MainMenu.Items[2].Items[0].bitmap);
   end;
End;

// Ver el formulario del log
Procedure Tform1.MMVerLog(Sender:TObject);
Begin
FormLog.Visible:=true;
NewLogLines := 0;
FormLog.BringToFront;
End;

// Ver monitor
Procedure TForm1.MMVerMonitor(Sender:TObject);
Begin
FormMonitor.Visible:=true;
FormMonitor.BringToFront;
CheckMonitor := true;
End;

// Abrir pagina web
Procedure TForm1.MMVerWeb(Sender:TObject);
Begin
OpenDocument(UserOptions.VersionPage);
End;

// Abrir form slots
Procedure TForm1.MMVerSlots(Sender:TObject);
Begin
FormSlots.Visible:=true;
End;

// Abrir form pool
Procedure TForm1.MMVerPool(Sender:TObject);
Begin
UpdatePoolForm();
if fileexists(PoolInfoFilename) then
  begin
  formpool.Height:= 400;
  formpool.Width := 560;
  end
else
   begin
   formpool.Height:= 60;
   formpool.Width := 430;
   end;
formpool.Caption:='Mining pool: '+MyPoolData.Name;
EdBuFee.Caption:='Fee: '+IntToStr(poolinfo.Porcentaje);
EdMaxMem.Caption:='Members: '+IntToStr(poolinfo.MaxMembers);
EdPayRate.Caption:='Pay: '+IntToStr(poolinfo.TipoPago);
EdPooExp.Caption:='Expel: '+IntToStr(PoolExpelBlocks);
EdShares.Caption:='Shares: '+IntToStr(PoolShare)+'%';
FormPool.Visible:=true;
End;

//******************************************************************************
// ConsolePopUp
//******************************************************************************

// VErifica que mostrar en el consolepopup
Procedure TForm1.CheckConsolePopUp(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if MemoConsola.Text <> '' then ConsolePopUp.Items[0].Enabled:= true
else ConsolePopUp.Items[0].Enabled:= false;
if length(Memoconsola.SelText)>0 then ConsolePopUp.Items[1].Enabled:= true
else ConsolePopUp.Items[1].Enabled:= false;
End;

Procedure TForm1.ConsolePopUpClear(Sender:TObject);
Begin
ProcessLinesAdd('clear');
End;

Procedure TForm1.ConsolePopUpCopy(Sender:TObject);
Begin
Clipboard.AsText:= Memoconsola.SelText;
info('Copied to clipboard');
End;

//******************************************************************************
// LinePopUp
//******************************************************************************

// VErifica que mostrar en el consolepopup
Procedure TForm1.CheckConsoLinePopUp(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if ConsoleLine.Text <> '' then ConsoLinePopUp.Items[0].Enabled:= true
else ConsoLinePopUp.Items[0].Enabled:= false;
if length(ConsoleLine.SelText)>0 then ConsoLinePopUp.Items[1].Enabled:= true
else ConsoLinePopUp.Items[1].Enabled:= false;
if length(Clipboard.AsText)>0 then ConsoLinePopUp.Items[2].Enabled:= true
else ConsoLinePopUp.Items[2].Enabled:= false;
End;

Procedure TForm1.ConsoLinePopUpClear(Sender:TObject);
Begin
ConsoleLine.Text:='';
ConsoleLine.Setfocus;
End;

Procedure TForm1.ConsoLinePopUpCopy(Sender:TObject);
Begin
Clipboard.AsText:= ConsoleLine.SelText;
info('Copied to clipboard');
End;

Procedure TForm1.ConsoLinePopUpPaste(Sender:TObject);
var
  CurrText : String; Currpos : integer;
Begin
CurrText := ConsoleLine.Text;
Currpos := ConsoleLine.SelStart;
Insert(Clipboard.AsText,CurrText,ConsoleLine.SelStart+1);
ConsoleLine.Text := CurrText;ConsoleLine.SelStart:=currpos+length(Clipboard.AsText);
ConsoleLine.Setfocus;
End;

//******************************************************************************
// TrxDetails PopUp
//******************************************************************************

// VErifica que mostrar en el consolepopup
Procedure TForm1.CheckTrxDetailsPopUp(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if GridMyTxs.Cells[2,GridMyTxs.row] ='TRFR' then TrxDetailsPopUp.Items[0].Visible:= true
else TrxDetailsPopUp.Items[0].visible:= false;
if length(MemoTrxDetails.SelText)>0 then TrxDetailsPopUp.Items[1].Enabled:= true
else TrxDetailsPopUp.Items[1].Enabled:= false;
End;

Procedure TForm1.TrxDetailsPopUpCopyOrder(Sender:TObject);
Begin
Clipboard.AsText:= GridMyTxs.Cells[4,GridMyTxs.row];
info('Order ID copied to clipboard');
End;

Procedure TForm1.TrxDetailsPopUpCopy(Sender:TObject);
Begin
Clipboard.AsText:= MemoTrxDetails.SelText;
info('Copied to clipboard');
End;

//******************************************************************************
// OPTIONS CONTROLS
//******************************************************************************

// WALLET

procedure TForm1.CB_WO_AutoConnectChange(Sender: TObject);
begin
if G_Launching then exit;
if CB_WO_AutoConnect.Checked then WO_AutoConnect := true
else WO_AutoConnect := false ;
S_AdvOpt := true;
end;

procedure TForm1.CB_WO_ToTrayChange(Sender: TObject);
begin
if G_Launching then exit;
if CB_WO_ToTray.Checked then WO_ToTray := true
else WO_ToTray := false ;
S_AdvOpt := true;
end;

procedure TForm1.SE_WO_MinPeersChange(Sender: TObject);
begin
if G_Launching then exit;
MinConexToWork := SE_WO_MinPeers.Value;
S_AdvOpt := true;
end;

procedure TForm1.SE_WO_CTOTChange(Sender: TObject);
begin
if G_Launching then exit;
ConnectTimeOutTime := SE_WO_CTOT.Value;
S_AdvOpt := true;
end;

procedure TForm1.SE_WO_RTOTChange(Sender: TObject);
begin
if G_Launching then exit;
ReadTimeOutTIme := SE_WO_RTOT.Value;
S_AdvOpt := true;
end;

procedure TForm1.SE_WO_ShowOrdersChange(Sender: TObject);
begin
if G_Launching then exit;
ShowedOrders := SE_WO_ShowOrders.Value;
S_AdvOpt := true;
end;

procedure TForm1.SE_WO_PosWarningChange(Sender: TObject);
begin
if G_Launching then exit;
WO_PosWarning := SE_WO_PosWarning.Value;
U_DirPanel := true;
S_AdvOpt := true;
end;


END. // END PROGRAM

