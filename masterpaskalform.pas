unit MasterPaskalForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLType,
  Grids, ExtCtrls, Buttons, IdTCPServer, IdContext, IdGlobal, IdTCPClient,
  fileutil, Clipbrd, Menus, formexplore, lclintf, ComCtrls,
  strutils, math, IdHTTPServer, IdCustomHTTPServer,
  IdHTTP, fpJSON, Types, DefaultTranslator, LCLTranslator, translation, nosodebug,
  IdComponent,nosogeneral,nosocrypto, nosounit, nosoconsensus, nosopsos, NosoWallCon,
  nosoheaders, nosoblock,nosonetwork,nosogvts,nosomasternodes,nosonosocfg,nosoIPControl;

type

   { TThreadClientRead }

  {
  TNodeConnectionInfo = class(TObject)
  private
    FTimeLast: Int64;
  public
    constructor Create;
    property TimeLast: int64 read FTimeLast write FTimeLast;
  end;
  }

  TServerTipo = class(TObject)
  private
    VSlot: integer;
  public
    constructor Create;
    property Slot: integer read VSlot write VSlot;
  end;

  {
  TThreadClientRead = class(TThread)
   private
     FSlot: Integer;
   protected
     procedure Execute; override;
   public
     constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
   end;
  }

  TThreadDirective = class(TThread)
   private
     command: string;
   protected
     procedure Execute; override;
   public
     constructor Create(const CreatePaused: Boolean; const TCommand:string);
   end;

  TThreadSendOutMsjs = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

  TThreadKeepConnect = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

  TThreadIndexer = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;


  TUpdateMNs = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

  TCryptoThread = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

  TUpdateLogs = class(TThread)
    private
      procedure UpdateConsole;
      procedure UpdateEvents;
      procedure UpdateExceps;
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

  {
  BotData = Packed Record
     ip: string[15];
     LastRefused : string[17];
     end;
  }

  {
  NodeData = Packed Record
     ip: string[15];
     port: string[8];
     LastConexion : string[17];
     end;
  }
  {
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
     Version : string[8];
     ListeningPort : integer;
     offset : integer;                  // Segundos de diferencia a su tiempo
     ResumenHash : String[64];           //
     ConexStatus : integer;
     IsBusy : Boolean;
     Thread : TThreadClientRead;
     MNsHash : string[5];
     MNsCount : Integer;
     BestHashDiff : string[32];
     MNChecksCount : integer;
     GVTsHash      : string[32];
     CFGHash       : string[32];
     MerkleHash    : string[32];
     PSOHash       : string[32];
     end;
  }
  {
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
   }

  NetworkData = Packed Record
     Value : String[64];   // el valor almacenado
     Porcentaje : integer; // porcentaje de peers que tienen el valor
     Count : integer;      // cuantos peers comparten ese valor
     Slot : integer;       // en que slots estan esos peers
     end;

  {
  ResumenData = Packed Record
     block : integer;
     blockhash : string[32];
     SumHash : String[32];
     end;
  }
  {
  BlockOrdersArray = Array of OrderData;
  }

  TArrayPos = Packed Record
       address : string[32];
       end;

  BlockArraysPos = array of TArrayPos;

  TMasterNode = Packed Record
       SignAddress : string[40];
       PublicKey   : string[120];
       FundAddress : string[40];
       Ip          : string[40];
       Port        : integer;
       Block       : integer;
       BlockHash   : string[32];
       Signature   : string[120];
       Time        : string[15];
       ReportHash  : string[32];
       end;

  {
  TMNode = Packed Record
       Ip           : string[15];
       Port         : integer;
       Sign         : string[40];
       Fund         : string[40];
       First        : integer;
       Last         : integer;
       Total        : integer;
       Validations  : integer;
       Hash         : String[32];
       end;
   }

   {
  TMNCheck = Record
       ValidatorIP  : string;      // Validator IP
       Block        : integer;
       SignAddress  : string;
       PubKey       : string;
       ValidNodes   : string;
       Signature    : string;
       end;
   }

  TArrayCriptoOp = Packed record
       tipo: integer;
       data: string;
       result: string;
       end;

  {
  TNMSData = Packed Record
       Diff   : string;
       Hash   : String;
       Miner  : String;
       TStamp : string;
       Pkey   : string;
       Signat : string;
       end;
  }

  {
  TMNsData  = Packed Record
       ipandport  : string;
       address    : string;
       age        : integer;
       end;
  }
  {
  TGVT = packed record
       number   : string[2];
       owner    : string[32];
       Hash     : string[64];
       control  : integer;
       end;
  }
  {
  TNosoCFG = packed record
       NetStatus : string;
       SeedNode  : string;
       NTPNodes  : string;
       Pools     : string;
       end;
  }
  {TOrdIndex = record
       block  : integer;
       orders : string;
       end;}

  { TForm1 }

  TForm1 = class(TForm)
    BitBtnDonate: TBitBtn;
    BitBtnWeb: TBitBtn;
    BSaveNodeOptions: TBitBtn;
    BitBtnPending: TBitBtn;
    BitBtnBlocks: TBitBtn;
    BTestNode: TBitBtn;
    Button1: TButton;
    Button2: TButton;
    CBSendReports: TCheckBox;
    CBKeepBlocksDB: TCheckBox;
    CB_BACKRPCaddresses: TCheckBox;
    CB_WO_Autoupdate: TCheckBox;
    CBAutoIP: TCheckBox;
    CBRunNodeAlone: TCheckBox;
    CB_WO_HideEmpty: TCheckBox;
    Edit2: TEdit;
    Label19: TLabel;
    Memobannedmethods: TMemo;
    Label1: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    LabelNodesHash: TLabel;
    LE_Rpc_Pass: TEdit;
    Label13: TLabel;
    LE_Rpc_Port: TEdit;
    Label12: TLabel;
    LabeledEdit9: TEdit;
    Label11: TLabel;
    LabeledEdit8: TEdit;
    Label10: TLabel;
    LabeledEdit6: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    LabeledEdit5: TEdit;
    PageControl2: TPageControl;
    PCNodes: TPageControl;
    PC_Processes: TPageControl;
    Panel10: TPanel;
    Panel11: TPanel;
    Panel12: TPanel;
    Panel13: TPanel;
    Panel14: TPanel;
    Panel15: TPanel;
    Panel16: TPanel;
    Panel17: TPanel;
    Panel18: TPanel;
    Panel19: TPanel;
    Panel20: TPanel;
    Panel21: TPanel;
    Panel23: TPanel;
    PanelTransferGVT: TPanel;
    PanelNodesHeaders: TPanel;
    Panel7: TPanel;
    Panel9: TPanel;
    SG_OpenThreads: TStringGrid;
    SG_FileProcs: TStringGrid;
    StaRPCimg: TImage;
    StaSerImg: TImage;
    StaConLab: TLabel;
    Imgs32: TImageList;
    ImgRotor: TImage;
    GridNodes: TStringGrid;
    GVTsGrid: TStringGrid;
    SGConSeeds: TStringGrid;
    TabGVTs: TTabSheet;
    TabConsensus: TTabSheet;
    TabSheet1: TTabSheet;
    TabNodesReported: TTabSheet;
    TabNodesVerified: TTabSheet;
    TabThreads: TTabSheet;
    TabFiles: TTabSheet;
    StaTimeLab: TLabel;
    SCBitSend: TBitBtn;
    SCBitClea: TBitBtn;
    CB_AUTORPC: TCheckBox;
    CB_WO_Multisend: TCheckBox;
    CheckBox4: TCheckBox;
    CB_RPCFilter: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    CheckBox9: TCheckBox;
    Edit1: TEdit;
    ConsoleLine: TEdit;
    EditSCMont: TEdit;
    EditSCDest: TEdit;
    EditCustom: TEdit;
    Image1: TImage;
    ImageOptionsAbout: TImage;
    ImgSCMont: TImage;
    ImgSCDest: TImage;
    ImageOut: TImage;
    ImageInc: TImage;
    Imagenes: TImageList;
    LSCTop: TLabel;
    LabAbout: TLabel;
    LabelBigBalance: TLabel;
    Latido : TTimer;
    InfoTimer : TTimer;
    InicioTimer : TTimer;
    MainMenu: TMainMenu;
    MemoSCCon: TMemo;
    MemoConsola: TMemo;
    DataPanel: TStringGrid;
    MenuItem1: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    DireccionesPanel: TStringGrid;
    InfoPanel: TPanel;
    PanelCustom: TPanel;
    PanelSend: TPanel;
    ConsolePopUp2: TPopupMenu;
    ConsoLinePopUp2: TPopupMenu;
    SCBitCancel: TBitBtn;
    SCBitConf: TBitBtn;
    BDefAddr: TSpeedButton;
    BCustomAddr: TSpeedButton;
    BCopyAddr: TSpeedButton;
    BNewAddr: TSpeedButton;
    BOkCustom: TSpeedButton;
    SGridSC: TStringGrid;
    SBSCPaste: TSpeedButton;
    SBSCMax: TSpeedButton;
    TabAddresses: TTabSheet;
    TabNodes: TTabSheet;
    TabWalletMain: TPageControl;
    TopPanel: TPanel;
    StatusPanel: TPanel;
    RestartTimer : Ttimer;
    MemoRPCWhitelist: TMemo;
    Memo2: TMemo;
    MemoLog: TMemo;
    MemoExceptLog: TMemo;
    PageControl1: TPageControl;
    PCMonitor: TPageControl;
    PageMain: TPageControl;
    Server: TIdTCPServer;
    RPCServer : TIdHTTPServer;
    SG_Performance: TStringGrid;
    tabOptions: TTabSheet;
    TabOpt_Wallet: TTabSheet;
    TabProcesses: TTabSheet;
    TabNodeOptions: TTabSheet;
    Tab_Options_RPC: TTabSheet;
    Tab_Options_Trade: TTabSheet;
    TabMonitor: TTabSheet;
    TabDebug_Log: TTabSheet;
    TabSheet8: TTabSheet;
    TabMonitorMonitor: TTabSheet;
    Tab_Options_About: TTabSheet;
    TabWallet: TTabSheet;
    TabConsole: TTabSheet;

    procedure BitBtnDonateClick(sender: TObject);
    procedure BitBtnWebClick(sender: TObject);
    procedure BSaveNodeOptionsClick(sender: TObject);
    procedure BTestNodeClick(sender: TObject);
    procedure Button1Click(sender: TObject);
    procedure Button2Click(sender: TObject);
    procedure CBKeepBlocksDBChange(Sender: TObject);
    procedure CBRunNodeAloneChange(sender: TObject);
    procedure CBSendReportsChange(Sender: TObject);
    procedure CB_BACKRPCaddressesChange(Sender: TObject);
    procedure CB_RPCFilterChange(sender: TObject);
    procedure CB_WO_AutoupdateChange(sender: TObject);
    procedure CBAutoIPClick(sender: TObject);
    procedure CB_WO_HideEmptyChange(Sender: TObject);
    procedure DataPanelResize(sender: TObject);
    procedure DireccionesPanelDrawCell(sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DireccionesPanelResize(sender: TObject);
    procedure FormCloseQuery(sender: TObject; var CanClose: boolean);
    procedure FormCreate(sender: TObject);
    procedure FormDestroy(sender: TObject);
    procedure FormResize(sender: TObject);
    procedure GridNodesResize(sender: TObject);
    procedure GVTsGridResize(sender: TObject);
    procedure LE_Rpc_PassEditingDone(sender: TObject);
    Procedure LoadOptionsToPanel();
    procedure FormShow(sender: TObject);
    Procedure InicoTimerEjecutar(sender: TObject);
    procedure MemobannedmethodsEditingDone(Sender: TObject);

    procedure MemoRPCWhitelistEditingDone(sender: TObject);
    procedure PC_ProcessesResize(Sender: TObject);
    Procedure RestartTimerEjecutar(sender: TObject);
    Procedure StartProgram();
    Procedure ConsoleLineKeyup(sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Grid1PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure Grid2PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    Procedure heartbeat(sender: TObject);
    Procedure InfoTimerEnd(sender: TObject);
    function  ClientsCount : Integer ;
    procedure SG_PerformanceResize(sender: TObject);
    procedure SG_OpenThreadsResize(Sender: TObject);
    procedure StaConLabDblClick(sender: TObject);
    procedure SGConSeedsResize(Sender: TObject);
    procedure TabNodeOptionsShow(sender: TObject);
    procedure Tab_Options_AboutResize(sender: TObject);
    Procedure TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
    Procedure BDefAddrOnClick(sender: TObject);
    Procedure BCustomAddrOnClick(sender: TObject);
    Procedure EditCustomKeyUp(sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure BOkCustomClick(sender: TObject);
    Procedure PanelCustomMouseLeave(sender: TObject);
    Procedure BNewAddrOnClick(sender: TObject);
    Procedure BCopyAddrClick(sender: TObject);
    Procedure CheckForHint(sender:TObject);
    Procedure SBSCPasteOnClick(sender:TObject);
    Procedure SBSCMaxOnClick(sender:TObject);
    Procedure EditSCDestChange(sender:TObject);
    Procedure EditSCMontChange(sender:TObject);
    Procedure DisablePopUpMenu(sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure EditMontoOnKeyUp(sender: TObject; var Key: char);
    Procedure SCBitSendOnClick(sender:TObject);
    Procedure SCBitCancelOnClick(sender:TObject);
    Procedure SCBitConfOnClick(sender:TObject);
    Procedure ResetSendFundsPanel(sender:TObject);

    // NODE SERVER
    Function TryMessageToNode(AContext: TIdContext;message:string):boolean;
    Function GetStreamFromContext(AContext: TIdContext;out LStream:TMemoryStream):boolean;

    // RPC
    procedure RPCServerExecute(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

    // MAIN MENU
    Procedure MMImpWallet(sender:TObject);
    Procedure MMExpWallet(sender:TObject);
    Procedure MMQuit(sender:TObject);
    Procedure MMRestart(sender:TObject);

    // CONSOLE POPUP
    Procedure CheckConsolePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure ConsolePopUpClear(sender:TObject);
    Procedure ConsolePopUpCopy(sender:TObject);

    // CONSOLE LINE POPUP
    Procedure CheckConsoLinePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure ConsoLinePopUpClear(sender:TObject);
    Procedure ConsoLinePopUpCopy(sender:TObject);
    Procedure ConsoLinePopUpPaste(sender:TObject);

    // OPTIONS
      // WALLET
    procedure CB_WO_MultisendChange(sender: TObject);
      // RPC
    procedure CB_AUTORPCChange(sender: TObject);
    procedure LE_Rpc_PortEditingDone(sender: TObject);

  private

  public

  end;

Procedure InitMainForm();
Procedure CloseeAppSafely();
Procedure UpdateStatusBar();
Procedure CompleteInicio();



CONST
  HexAlphabet    : string = '0123456789ABCDEF';
  ReservedWords  : string = 'NULL,DELADDR';
  FundsAddress   : string = 'NpryectdevepmentfundsGE';
  JackPotAddress : string = 'NPrjectPrtcRandmJacptE5';
  ValidProtocolCommands : string = '$PING$PONG$GETPENDING$NEWBL$GETRESUMEN$LASTBLOCK$GETCHECKS'+
                                   '$CUSTOMORDERADMINMSGNETREQ$REPORTNODE$GETMNS$BESTHASH$MNREPO$MNCHECK'+
                                   'GETMNSFILEMNFILEGETHEADUPDATE$GETSUMARY$GETGVTSGVTSFILE$SNDGVTGETCFGDATA'+
                                   'SETCFGDATA$GETPSOSPSOSFILE';
  HideCommands : String = 'CLEAR SENDPOOLSOLUTION SENDPOOLSTEPS DELBOTS';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';

  MainnetVersion = '0.4.3';
  {$IFDEF WINDOWS}
  RestartFileName = 'launcher.bat';
  updateextension = 'zip';
  {$ENDIF}
  {$IFDEF UNIX}
  RestartFileName = 'launcher.sh';
  updateextension = 'tgz';
  {$ENDIF}
  NodeRelease = 'Aa8';
  OficialRelease = true;
  BetaRelease    = false;
  VersionRequired = '0.4.2';
  BuildDate = 'August 2024';
  {Developer addresses}
  ADMINHash = 'N4PeJyqj8diSXnfhxSQdLpo8ddXTaGd';
  AdminPubKey = 'BL17ZOMYGHMUIUpKQWM+3tXKbcXF0F+kd4QstrB0X7iWvWdOSrlJvTPLQufc1Rkxl6JpKKj/KSHpOEBK+6ukFK4=';
  Authorizedaddresses = 'N4HgivS84xzgG6uPAnhQprLVsfry6GM N4GvsJ7SjBw6Ls8XNk6gELpXoLTt5Dv';

  DefaultServerPort = 8080;
  MaxConecciones  = 99;
  //Protocolo = 2;
  DefaultDonation = 10;
  // Custom values for coin
  SecondsPerBlock = 600;            // 10 minutes
  PremineAmount = 1030390730000;    // 1030390730000;
  InitialReward = 5000000000;       // Initial reward
  BlockHalvingInterval = 210000;    // 210000;
  HalvingSteps = 10;                // total number of halvings
  Comisiontrfr = 10000;             // ammount/Comisiontrfr = 0.01 % of the ammount
  ComisionCustom = 200000;          // 0.05 % of the Initial reward
  CoinSimbol = 'NOSO';              // Coin symbol
  CoinName = 'Noso';                // Coin name
  CoinChar = 'N';                   // Char for addresses
  MinimunFee = 10;
  NewMinFee  = 1000000;              // Minimun fee for transfer
  PoSPercentage = 1000;             // PoS part: reward * PoS / 10000
  MNsPercentage = 2000;
  PosStackCoins = 20;               // PoS stack ammoount: supply*20 / PoSStack
  PoSBlockStart : integer = 8425;   // first block with PoSPayment
  PoSBlockEnd   : integer = 88500;  // To verify
  MNBlockStart  : integer = 48010;  // First block with MNpayments
  InitialBlockDiff = 60;            // First 20 blocks diff
  GenesysTimeStamp = 1615132800;    // 1615132800;
  AvailableMarkets = '/LTC';
  SumMarkInterval  = 100;
  SecurityBlocks   = 4000;
  //GVTBaseValue     = 70000000000;
  Update050Block   = 120000;

var
  Form1            : TForm1;
  //Customizationfee : int64 = InitialReward div ComisionCustom;
  {Options}
  FileAdvOptions   : textfile;
  S_AdvOpt         : boolean = false;
  RPCPort          : integer = 8078;
  RPCPass          : string = 'default';
  MaxPeersAllow    : integer = 50;
  WO_AutoServer    : boolean = false;
  WO_PosWarning    : int64 = 7;
  WO_MultiSend     : boolean = false;
  WO_HideEmpty     : boolean = false;
  WO_Language      : string = 'en';
    WO_LastPoUpdate: string = MainnetVersion+NodeRelease;
  WO_CloseStart    : boolean = true;
  WO_AutoUpdate    : Boolean = true;
  WO_SendReport    : boolean = false;
  WO_StopGUI    : boolean = false;
  WO_BlockDB       : boolean = false;
  WO_PRestart      : int64 = 0;
  WO_skipBlocks   : boolean = false;
  RPCFilter        : boolean = true;
  RPCWhitelist     : string = '127.0.0.1,localhost';
  RPCBanned        : string = '';
  RPCAuto          : boolean = false;
  RPCSaveNew       : boolean = false;
  //MN_IP            : string = 'localhost';
  //MN_Port          : string = '8080';
  //MN_Funds         : string = '';
  //MN_Sign          : string = '';
  MN_AutoIP        : Boolean = false;
  //MN_FileText      : String = '';
  WO_FullNode      : boolean = true;

  {Network}
  MaxOutgoingConnections : integer = 3;
  {
  SlotLines        : array [1..MaxConecciones] of TStringList;
  CanalCliente     : array [1..MaxConecciones] of TIdTCPClient;
  }
  //ListadoBots      : array of BotData;
  //ListaNodos       : array of NodeData;
  //ArrayPoolTXs     : Array of TOrderData;
  ArrayOrderIDsProcessed : array of string;
  OutgoingMsjs     : TStringlist;
  KeepServerOn     : Boolean = false;
   LastTryServerOn : Int64 = 0;
   ServerStartTime : Int64 = 0;
  {
  DownloadHeaders  : boolean = false;
  DownloadSumary   : Boolean = false;
  DownLoadBlocks   : boolean = false;
  DownLoadGVTs     : boolean = false;
  DownloadPSOs     : boolean = false;
  }
  RebuildingSumary : boolean = false;
  //OpenReadClientThreads : integer = 0;

  // Threads
  SendOutMsgsThread : TThreadSendOutMsjs;
  KeepConnectThread : TThreadKeepConnect;
  IndexerThread     : TThreadIndexer;
  ThreadMNs         : TUpdateMNs;
  CryptoThread      : TCryptoThread;
  UpdateLogsThread  : TUpdateLogs;

  // GUI/APP related
  ConnectedRotor       : integer = 0;
  EngineLastUpdate     : int64 = 0;
  LastLogLine          : String = '';
  RestartNosoAfterQuit : boolean = false;
  U_DirPanel           : boolean = false;
  U_DataPanel          : boolean = true;
  G_ClosingAPP         : Boolean = false;
  MyCurrentBalance     : Int64 = 0;
  G_Launching          : boolean = true;
  G_CloseRequested     : boolean = false;
  G_LastPing           : int64;
  G_TotalPings         : Int64 = 0;
  LastCommand          : string = '';
  ProcessLines         : TStringlist;
  //LastBotClear         : string = '';
  S_Wallet             : boolean = false;
  MontoIncoming        : Int64 = 0;
  MontoOutgoing        : Int64 = 0;
  InfoPanelTime        : integer = 0;

  // FormState
  FormState_Top    : integer;
  FormState_Left   : integer;
  FormState_Heigth : integer;
  FormState_Width  : integer;
  FormState_Status : integer;

  // Masternodes
  //G_MNVerifications  : integer = 0;
  //ArrayMNsData       : array of TMNsData;
  LastTimeReportMyMN : int64 = 0;
  MNsArray           : array of TMasterNode;
  //WaitingMNs         : array of String;
  U_MNsGrid          : boolean = false;
  U_MNsGrid_Last     : int64 = 0;

  //MNsList       : array of TMnode;
  //ArrMNChecks   : array of TMNCheck;
  MNsRandomWait : Integer= 0;


  {
  //MySumarioHash : String = '';
  MyLastBlock     : integer = 0;
  MyLastBlockHash : String = '';
  MyResumenHash   : String = '';
  MyGVTsHash      : string = '';
  MyCFGHash       : string = '';
  MyPublicIP      : String = '';
  MyMNsHash       : String = '';
  }






  {LastBlockData : BlockHeaderData;}
  BuildingBlock : integer = 0;


  Last_SyncWithMainnet         : int64 = 0;
  {
  LastTimeRequestSumary        : int64 = 0;
  LastTimeRequestBlock         : int64 = 0;
  LastTimeRequestResumen       : int64 = 0;
  LastTimePendingRequested     : int64 = 0;
  }
  //ForceCompleteHeadersDownload : boolean = false;
  {
  LastTimeMNHashRequestes      : int64 = 0;
  LastTimeBestHashRequested    : int64 = 0;
  LastTimeMNsRequested         : int64 = 0;
  LastTimeChecksRequested      : int64 = 0;
  LastRunMNVerification        : int64 = 0;
  LasTimeGVTsRequest           : int64 = 0;
  }
  //LasTimeCFGRequest            : int64 = 0;
  //LasTimePSOsRequest           : int64 = 0;

  // Variables asociadas a mi conexion
  MyConStatus          :  integer = 0;
  STATUS_Connected     : boolean = false;





  BuildNMSBlock : int64 = 0;

  ArrayCriptoOp : array of TArrayCriptoOp;

  // Critical Sections
  CSProcessLines: TRTLCriticalSection;
  CSOutgoingMsjs: TRTLCriticalSection;
  CSBlocksAccess: TRTLCriticalSection;
  //CSPending     : TRTLCriticalSection;
  CSCriptoThread: TRTLCriticalSection;
  CSClosingApp  : TRTLCriticalSection;
  //CSClientReads : TRTLCriticalSection;
  //CSGVTsArray   : TRTLCriticalSection;
  CSNosoCFGStr  : TRTLCriticalSection;

  //MNs system
  //CSMNsArray    : TRTLCriticalSection;
  //CSWaitingMNs  : TRTLCriticalSection;
  //CSMNsChecks   : TRTLCriticalSection;

  CSIdsProcessed: TRTLCriticalSection;


  // Outgoing lines, needs to be initialized
  //CSOutGoingArr : array[1..MaxConecciones] of TRTLCriticalSection;
     //ArrayOutgoing : array[1..MaxConecciones] of array of string;
  //CSIncomingArr : array[1..MaxConecciones] of TRTLCriticalSection;



  // Filename variables
  MarksDirectory      : string= 'NOSODATA'+DirectorySeparator+'SUMMARKS'+DirectorySeparator;
  GVTMarksDirectory   : string= 'NOSODATA'+DirectorySeparator+'SUMMARKS'+DirectorySeparator+'GVTS'+DirectorySeparator;
  UpdatesDirectory    : string= 'NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator;
  LogsDirectory       : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator;
  ExceptLogFilename   : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'exceptlog.txt';
  ConsoleLogFilename  : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'console.txt';
  NodeFTPLogFilename  : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'nodeftp.txt';
  DeepDebLogFilename  : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'deepdeb.txt';
  EventLogFilename    : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'eventlog.txt';
  ResumeLogFilename   : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'report.txt';
  PerformanceFIlename : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'performance.txt';
  AdvOptionsFilename  : string= 'NOSODATA'+DirectorySeparator+'advopt.txt';
  {MasterNodesFilename : string= 'NOSODATA'+DirectorySeparator+'masternodes.txt';}
  ZipHeadersFileName  : string= 'NOSODATA'+DirectorySeparator+'blchhead.zip';
  {GVTsFilename        : string= 'NOSODATA'+DirectorySeparator+'gvts.psk';}
  ClosedAppFilename   : string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'proclo.dat';
  RPCBakDirectory     : string= 'NOSODATA'+DirectorySeparator+'SUMMARKS'+DirectorySeparator+'RPC'+DirectorySeparator;


IMPLEMENTATION

Uses
  mpgui, mpdisk, mpParser, mpRed, nosotime, mpProtocol, mpcoin,
  mpRPC,mpblock;

{$R *.lfm}

{
// Identify the pool miners connections
constructor TNodeConnectionInfo.Create;
Begin
FTimeLast:= 0;
End;
}

constructor TServerTipo.Create;
Begin
VSlot:= -1;
End;

// ***************
// *** THREADS ***
// ***************

{$REGION Thread update logs}

constructor TUpdateLogs.Create(CreateSuspended : boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TUpdateLogs.UpdateConsole();
Begin
if not WO_StopGUI then
  form1.MemoConsola.Lines.Add(LastLogLine);
End;

procedure TUpdateLogs.UpdateEvents();
Begin
if not WO_StopGUI then
  form1.MemoLog.Lines.Add(LastLogLine);
End;

procedure TUpdateLogs.UpdateExceps();
Begin
if not WO_StopGUI then
  form1.MemoExceptLog.Lines.Add(LastLogLine);
End;

procedure TUpdateLogs.Execute;
Begin
  AddNewOpenThread('UpdateLogs',UTCTime);
  While not terminated do
    begin
    sleep(10);
    UpdateOpenThread('UpdateLogs',UTCTime);
    while GetLogLine('console',lastlogline) do Synchronize(@UpdateConsole);
    while GetLogLine('events',lastlogline) do Synchronize(@UpdateEvents);
    while GetLogLine('exceps',lastlogline) do Synchronize(@UpdateExceps);
    GetLogLine('nodeftp',lastlogline);
    // Deep debug
    Repeat
    until not GetDeepDebLine(lastlogline);
    end;
End;

{$ENDREGION Thread update logs}

{$REGION Thread Client read}
 {
constructor TThreadClientRead.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
Begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
End;

procedure TThreadClientRead.Execute;
var
  LLine: String;
  MemStream    : TMemoryStream;
  BlockZipName : string = '';
  Continuar    : boolean = true;
  Errored      : Boolean;
  downloaded   : boolean;
  LineToSend   : string;
  LineSent     : boolean;
  KillIt       : boolean = false;
  SavedToFile  : boolean;
  FTPTime      : int64;
  FTPSize      : int64;
  FTPSpeed     : int64;
  ErrMsg       : string;
begin
  AddNewOpenThread('ReadClient '+FSlot.ToString,UTCTime);
  REPEAT
    TRY
    sleep(10);
    continuar := true;
    if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
      begin
      CanalCliente[FSlot].IOHandler.CheckForDataOnSource(1000);
      if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then Continuar := false;
      end;
    if Continuar then
      begin
      While not CanalCliente[FSlot].IOHandler.InputBufferIsEmpty do
        begin
        Conexiones[fSlot].IsBusy:=true;
        Conexiones[fSlot].lastping:=UTCTimeStr;
          TRY
          CanalCliente[FSlot].ReadTimeout:=1000;
          CanalCliente[FSlot].IOHandler.MaxLineLength:=Maxint;
          LLine := CanalCliente[FSlot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
          EXCEPT on E:Exception do
            begin
            ErrMsg := E.Message;
            ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0002,[IntToStr(Fslot)+slinebreak+ErrMsg]));
            Conexiones[fSlot].IsBusy:=false;
            if AnsiContainsStr(Uppercase(ErrMsg),'SOCKET ERROR') then
              begin
              KillIt := true;
              ToLog('console',Format('Socket error: ',[ErrMsg]));
              end;
            continue;
            end;
          END; {TRY}
        if continuar then
          begin
          if Parameter(LLine,0) = 'RESUMENFILE' then
            begin
            DownloadHeaders := true;
            AddFileProcess('Get','Headers',CanalCliente[FSlot].Host,GetTickCount64);
            ToLog('events',TimeToStr(now)+rs0003); //'Receiving headers'
            ToLog('console',rs0003); //'Receiving headers'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0004,[conexiones[fSlot].ip,E.Message])); //'Error Receiving headers from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then SavedToFile := SaveStreamAsHeaders(MemStream)
            else SavedToFile := false;
            if ((Downloaded) and (SavedToFile)) then
              begin
              ToLog('console',format(rs0005,[copy(HashMD5File(ResumenFilename),1,5)])); //'Headers file received'
              LastTimeRequestResumen := 0;
              UpdateMyData();
              end
            else ToLog('console','Error downloading headers: downloaded: '+booltostr(Downloaded,true)+' / Saved: '+booltostr(SavedToFile,true));
            MemStream.Free;
            DownloadHeaders := false;
            FTPTime := CloseFileProcess('Get','Headers',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded headers from '+CanalCliente[FSlot].Host+' at '+FTPSpeed.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'SUMARYFILE' then
            begin
            DownloadSumary := true;
            AddFileProcess('Get','Summary',CanalCliente[FSlot].Host,GetTickCount64);
            ToLog('console',rs0085); //'Receiving sumary'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0086,[conexiones[fSlot].ip,E.Message])); //'Error Receiving sumary from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then SavedToFile := SaveSummaryToFile(MemStream);
            if ((Downloaded) and (SavedToFile)) then
              begin
              ToLog('console',format(rs0087,[copy(HashMD5File(SummaryFileName),1,5)])); //'Sumary file received'
              UpdateMyData();
              CreateSumaryIndex();
              UpdateWalletFromSumario;
              LastTimeRequestSumary := 0;
              end;
            MemStream.Free;
            DownloadSumary := false;
            FTPTime := CloseFileProcess('Get','Summary',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded summary from '+CanalCliente[FSlot].Host+' at '+FTPSpeed.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'PSOSFILE' then
            begin
            DownloadPSOs := true;
            AddFileProcess('Get','PSOs',CanalCliente[FSlot].Host,GetTickCount64);
            ToLog('console','Receiving PSOs'); //'Receiving psos'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0092,[conexiones[fSlot].ip,E.Message])); //'Error Receiving sumary from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then SavedToFile := SavePSOsToFile(MemStream);
            if Downloaded and SavedToFile then
              begin
              ToLog('console',format(rs0093,[copy(HashMD5File(PSOsFileName),1,5)])); //'PSOs file received'
              LoadPSOFileFromDisk;
              UpdateMyData();
              LasTimePSOsRequest := 0;
              end;
            MemStream.Free;
            DownloadPSOs := false;
            FTPTime := CloseFileProcess('Get','PSOs',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded PSOs from '+CanalCliente[FSlot].Host+' at '+FTPSpeed.ToString+' kb/s');
            end

          else if Parameter(LLine,0) = 'GVTSFILE' then
            begin
            DownloadGVTs := true;
            AddFileProcess('Get','GVTFile',CanalCliente[FSlot].Host,GetTickCount64);
            ToLog('events',TimeToStr(now)+rs0089); //'Receiving GVTs'
            ToLog('console',rs0089); //'Receiving GVTs'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              downloaded := True;
              EXCEPT ON E:Exception do
                begin
                ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0090,[conexiones[fSlot].ip,E.Message])); //'Error Receiving GVTs from
                downloaded := false;
                end;
              END; {TRY}
            if Downloaded then
              begin
              Errored := false;
              EnterCriticalSection(CSGVTsArray);
                TRY
                MemStream.SaveToFile(GVTsFilename);
                Errored := False;
                EXCEPT on E:Exception do
                  begin
                    Errored := true;
                    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error saving GVTs to file: '+E.Message);
                  end;
                END; {TRY}
              LeaveCriticalSection(CSGVTsArray);
              end;
            if Downloaded and not errored then
              begin
              ToLog('console','GVTS file downloaded');
              GetGVTsFileData;
              UpdateMyGVTsList;
              end;
            MemStream.Free;
            DownloadGVTs := false;
            FTPTime := CloseFileProcess('Get','GVTFile',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded GVTs from '+CanalCliente[FSlot].Host+' at '+FTPTime.ToString+' kb/s');
            end

          else if LLine = 'BLOCKZIP' then
            begin  // START RECEIVING BLOCKS
            AddFileProcess('Get','Blocks',CanalCliente[FSlot].Host,GetTickCount64);
            ToLog('events',TimeToStr(now)+rs0006); //'Receiving blocks'
            BlockZipName := BlockDirectory+'blocks.zip';
            TryDeleteFile(BlockZipName);
            MemStream := TMemoryStream.Create;
            DownLoadBlocks := true;
            CanalCliente[FSlot].ReadTimeout:=10000;
              TRY
              CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
              FTPsize := MemStream.Size;
              MemStream.SaveToFile(BlockZipName);
              Errored := false;
              EXCEPT ON E:Exception do
                begin
                ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0007,[conexiones[fSlot].ip,E.Message])); //'Error Receiving blocks from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                Errored := true;
                end;
              END; {TRY}
            If not Errored then
              begin
              if UnzipBlockFile(BlockDirectory+'blocks.zip',true) then
                begin
                MyLastBlock := GetMyLastUpdatedBlock();
                MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
                ToLog('events',TimeToStr(now)+format(rs0021,[IntToStr(MyLastBlock)])); //'Blocks received up to '+IntToStr(MyLastBlock));
                LastTimeRequestBlock := 0;
                UpdateMyData();
                end;
              end;
            MemStream.Free;
            DownLoadBlocks := false;
            FTPTime := CloseFileProcess('Get','Blocks',CanalCliente[FSlot].Host,GetTickCount64);
            FTPSpeed := (FTPSize div FTPTime);
            ToLog('nodeftp','Downloaded blocks from '+CanalCliente[FSlot].Host+' at '+FTPTime.ToString+' kb/s');
            end // END RECEIVING BLOCKS
        else
          begin
          AddToIncoming(FSlot,LLine);
          end;
        end;
      Conexiones[fSlot].IsBusy:=false;
      end; // end while client is not empty
    end; // End if continuar

    EXCEPT ON E:Exception do
      begin
      ErrMsg := E.Message;
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'*****CRITICAL**** Error inside Client thread: '+ErrMsg);
      KillIt := true;
      end;
    END; {TRY}
  UNTIL ( (terminated) or (not CanalCliente[FSlot].Connected) or (KillIt) );
  DecClientReadThreads;
  CloseOpenThread('ReadClient '+FSlot.ToString);
End;
}
{$ENDREGION Thread Client read}

{$REGION Thread Directive}

constructor TThreadDirective.Create(const CreatePaused: Boolean; const TCommand:string);
begin
  inherited Create(CreatePaused);
  Command := TCommand;
end;

procedure TThreadDirective.Execute;
var
  TimeToRun : int64;
  TFinished  : boolean = false;
Begin
AddNewOpenThread('Directives',UTCTime);
if command = 'rpcrestart' then
   begin
   timetorun := BlockAge+3;
   command := 'restart';
   end
else TimeToRun := 50+(MNsRandomWait*20);
While not Tfinished do
   begin
   sleep(10);
   if BlockAge = TimeToRun then
      begin
      ProcesslinesAdd(Command);
      TFinished := true;
      end;
   end;
End;

{$ENDREGION Thread Directive}

{$REGION Thread Update MNs}

constructor TUpdateMNs.Create(CreateSuspended : boolean);
Begin
  inherited Create(CreateSuspended);
End;

// Process the Masternodes reports
procedure TUpdateMNs.Execute;
const
  LastIPVerify : int64 = 0;
var
  TextLine   : String;
  ReportInfo : String = '';
  MyIP       : string;
Begin
  AddNewOpenThread('Masternodes',UTCTime);
  Randomize;
  MNsRandomWait := Random(21);
  While not terminated do
    begin
    UpdateOpenThread('Masternodes',UTCTime);
    if UTCTime mod 10 = 0 then
      begin
      if ( (IsValidator(LocalMN_IP)) and (BlockAge>500+(MNsRandomWait div 4)) and (Not IsMyMNCheckDone) and
        (BlockAge<575)and(LastRunMNVerification<>UTCTime) and (MyConStatus = 3) and(VerifyThreadsCount<=0) ) then
        begin
        LastRunMNVerification := UTCTime;
        TextLine := RunMNVerification(MyLastBlock,GetSynctus,LocalMN_IP,GetWallArrIndex(WallAddIndex(LocalMN_Sign)).PublicKey,GetWallArrIndex(WallAddIndex(LocalMN_Sign)).PrivateKey);
        OutGoingMsjsAdd(ProtocolLine(MNCheck)+TextLine);
        //ToLog('console','Masternodes Verification completed: '+TextLine)
        end;
      end;
    if ( (BlockAge > 10) and (LastIPVerify<UTCtime) ) then
      begin
      LastIPVerify := NextBlockTimeStamp;
      MyIP := GetMiIP();
      //ToLog('console','Auto IP executed');
      if  ( (MyIP <> '') and (MyIP <> LocalMN_IP) and (MyIP <> 'Closing NODE') and (MyIP <> 'BANNED') and (IsValidIP(MyIP))) then
        begin
        ToLog('console','Auto IP: updated to '+MyIp);
        LocalMN_IP := MyIP;
        S_AdvOpt := true;
        end;
      end;
    While LengthWaitingMNs > 0 do
      begin
      TextLine := GetWaitingMNs;
      if not IsIPMNAlreadyProcessed(TextLine) then
        begin
        ReportInfo := CheckMNReport(TextLine,MyLastBlock);
        if  ReportInfo <> '' then
          outGOingMsjsAdd(GetPTCEcn+ReportInfo);
        sleep(1);
        end;
      end;
    Sleep(10);
    end;
End;

{$ENDREGION Thread Update MNs}

{$REGION Thread Crypto}

constructor TCryptoThread.Create(CreateSuspended : boolean);
Begin
  inherited Create(CreateSuspended);
End;

Procedure TCryptoThread.Execute;
var
  NewAddrss : integer = 0;
  PosRef : integer; cadena,claveprivada,firma, resultado:string;
  NewAddress : WalletData;
  PubKey,PriKey : string;
Begin
  AddNewOpenThread('Crypto',UTCTime);
  While not terminated do
    begin
    UpdateOpenThread('Crypto',UTCTime);
    NewAddrss := 0;
    if length(ArrayCriptoOp)>0 then
      begin
      if ArrayCriptoOp[0].tipo = 0 then
        begin

        end
      else if ArrayCriptoOp[0].tipo = 1 then // Crear direccion
        begin
        NewAddress := Default(WalletData);
        NewAddress.Hash:=GenerateNewAddress(PubKey,PriKey);
        NewAddress.PublicKey:=pubkey;
        NewAddress.PrivateKey:=PriKey;
        InsertToWallArr(NewAddress);
        S_Wallet := true;
        U_DirPanel := true;
        Inc(NewAddrss);
        end
      else if ArrayCriptoOp[0].tipo = 2 then // customizar
        begin
        posRef := pos('$',ArrayCriptoOp[0].data);
        cadena := copy(ArrayCriptoOp[0].data,1,posref-1);
        claveprivada := copy (ArrayCriptoOp[0].data,posref+1,length(ArrayCriptoOp[0].data));
        firma := GetStringSigned(cadena,claveprivada);
        resultado := StringReplace(ArrayCriptoOp[0].result,'[[RESULT]]',firma,[rfReplaceAll, rfIgnoreCase]);
        OutgoingMsjsAdd(resultado);
        OutText('Customization sent',false,2);
        end
      else if ArrayCriptoOp[0].tipo = 3 then // enviar fondos
        begin
          TRY
          Sendfunds(ArrayCriptoOp[0].data);
          EXCEPT ON E:Exception do
            ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2501,[E.Message]));
          END{Try};
        end
      else if ArrayCriptoOp[0].tipo = 4 then // recibir customizacion
        begin
        TRY
          PTC_Custom(ArrayCriptoOp[0].data);
        EXCEPT ON E:Exception do
          ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2502,[E.Message]));
        END{Try};
        end
      else if ArrayCriptoOp[0].tipo = 5 then // recibir transferencia
        begin
          TRY
          PTC_Order(ArrayCriptoOp[0].data);
          EXCEPT ON E:Exception do
            ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2503,[E.Message]));
          END{Try};
        end
      else if ArrayCriptoOp[0].tipo = 6 then // Send GVT
        begin
        TRY
          SendGVT(ArrayCriptoOp[0].data);
        EXCEPT ON E:Exception do
          ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2504,[E.Message]));
        END{Try};
        end
      else if ArrayCriptoOp[0].tipo = 7 then // Send GVT
        begin
        TRY
          PTC_SendGVT(ArrayCriptoOp[0].data);
        EXCEPT ON E:Exception do
          ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs2505,[E.Message]));
        END{Try};
        end
      else
        begin
        ToLog('exceps','Invalid cryptoop: '+ArrayCriptoOp[0].tipo.ToString);
        end;
      DeleteCriptoOp();
      sleep(10);
      end;
    if NewAddrss > 0 then OutText(IntToStr(NewAddrss)+' new addresses',false,2);
    Sleep(10);
    end;
End;

{$ENDREGION Thread Crypto}

{$REGION Thread Send outgoing msgs}

constructor TThreadSendOutMsjs.Create(CreateSuspended : boolean);
Begin
  inherited Create(CreateSuspended);
End;

// Send the outgoing messages
procedure TThreadSendOutMsjs.Execute;
Var
  Slot :integer = 1;
  Linea : string;
  Counter : int64 = 0;
Begin
AddNewOpenThread('SendMSGS',UTCTime);
While not terminated do
   begin
   UpdateOpenThread('SendMSGS',UTCTime);
   if OutgoingMsjs.Count > 0 then
      begin
      Linea := OutgoingMsjsGet();
      if Linea <> '' then
         begin
         For Slot := 1 to MaxConecciones do
            begin
            TRY
            if IsSlotConnected(slot) then PTC_SendLine(Slot,linea);
            EXCEPT on E:Exception do
                ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0008,[E.Message]));
               //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error sending outgoing message: '+E.Message);
            END{Try};
            end;
         end;
      Sleep(10);
      end;
   Sleep(10);
   End;
End;

{$ENDREGION Thread Send outgoing msgs}

{$REGION Thread keepConnected}

constructor TThreadKeepConnect.Create(CreateSuspended : boolean);
Begin
  inherited Create(CreateSuspended);
End;

procedure TThreadKeepConnect.Execute;
const
  LastTrySlot  : integer = 0;
  LAstTryTime  : int64 = 0;
  Unables      : integer = 0;
  PRestartTime : int64 = 0;
var
  TryThis   : boolean = true;
  Loops     : integer = 0;
  OutGoing  : integer;
Begin
  AddNewOpenThread('KeepConnect',UTCTime);
  if WO_PRestart > 0 then
    begin
    PRestartTime := UTCTime + (WO_PRestart*600);
    ToLog('Console','PRestart set at '+TimestampToDate(PRestartTime));
    end;
  while not terminated do
    begin
    UpdateOpenThread('KeepConnect',UTCTime);
    TryThis := true;
    if getTotalConexiones >= 99 then TryThis := false;
    if GetTotalSyncedConnections>=3 then TryThis := false;
    if ((BlockAge <10) or (blockAge>595)) then TryThis := false;
    if trythis then
      begin
      Inc(LastTrySlot);
      if LastTrySlot >= NodesListLen then LastTrySlot := 0;
      if ((GetSlotFromIP(NodesIndex(LastTrySlot).ip)=0) AND (GetFreeSlot()>0) and (NodesIndex(LastTrySlot).ip<>LocalMN_IP)) then
        ConnectClient(NodesIndex(LastTrySlot).ip,NodesIndex(LastTrySlot).port);
      end;
    sleep(3000);
    if PRestartTime > 0 then
      begin
      if ( (blockAge>120) and (blockAge<450) and (UTCTime>PRestartTime) ) then
        ProcesslinesAdd('restart');
      end;
    end;
  if EngineLastUpdate+10 < UTCTime then Parse_RestartNoso;
  CloseOpenThread('KeepConnect');
End;

{$ENDREGION Thread keepConnected}

{$REGION Thread Indexer}

constructor TThreadIndexer.Create(CreateSuspended : boolean);
begin
  inherited Create(CreateSuspended);
end;

procedure TThreadIndexer.Execute;
Begin
  AddNewOpenThread('Indexer',UTCTime);
  tolog('console','Starting indexer');
  while not terminated do
    begin
    if not WO_BlockDB then
       begin
       sleep(1000);
       continue;
       end;
    if MyLastBlock > GetDBLastBlock then
      begin
      if ( (blockAge>60) and (copy(MyLastBlockHash,1,5) =copy(getconsensus(10),1,5)) ) then
        begin
        UpdateBlockDatabase;;
        end;
      end;
    sleep(1000);
    end;
  CloseOpenThread('Indexer');
End;

{$ENDREGION Thread Indexer}

//***********************
// *** FORM RELATIVES ***
//***********************

{$REGION Form1}

procedure TForm1.FormCreate(sender: TObject);
var
  counter : integer;
Begin
  ProcessLines       := TStringlist.Create;
  OutgoingMsjs       := TStringlist.Create;
  Randomize;
  InitCriticalSection(CSProcessLines);
  InitCriticalSection(CSOutgoingMsjs);
  InitCriticalSection(CSBlocksAccess);
  //InitCriticalSection(CSPending);
  InitCriticalSection(CSCriptoThread);
  //InitCriticalSection(CSMNsArray);
  //InitCriticalSection(CSWaitingMNs);
  InitCriticalSection(CSMNsChecks);
  InitCriticalSection(CSClosingApp);
  //InitCriticalSection(CSNosoCFGStr);
  InitCriticalSection(CSIdsProcessed);
  for counter := 1 to MaxConecciones do
    begin
    //InitCriticalSection(CSOutGoingArr[counter]);
    //InitCriticalSection(CSIncomingArr[counter]);
    //SetLength(ArrayOutgoing[counter],0);
    //SlotLines[counter] := TStringlist.Create;
    //CanalCliente[counter] := TIdTCPClient.Create(form1);
    end;
  CreateFormInicio();
  CreateFormSlots();
  SetLength(ArrayOrderIDsProcessed,0);
  //SetLength(ArrayMNsData,0);
  //Setlength(ArrayPoolTXs,0);
End;

procedure TForm1.FormDestroy(sender: TObject);
var
  contador : integer;
Begin
  DoneCriticalSection(CSProcessLines);
  DoneCriticalSection(CSOutgoingMsjs);
  DoneCriticalSection(CSBlocksAccess);
  //DoneCriticalSection(CSPending);
  DoneCriticalSection(CSCriptoThread);
  //DoneCriticalSection(CSMNsArray);
  //DoneCriticalSection(CSWaitingMNs);
  DoneCriticalSection(CSMNsChecks);
  DoneCriticalSection(CSClosingApp);
  //DoneCriticalSection(CSNosoCFGStr);
  DoneCriticalSection(CSIdsProcessed);
  for contador := 1 to MaxConecciones do
    begin
    //DoneCriticalSection(CSOutGoingArr[contador]);
    //DoneCriticalSection(CSIncomingArr[contador]);
    end;
  //for contador := 1 to maxconecciones do
    //If Assigned(SlotLines[contador]) then SlotLines[contador].Free;
  form1.Server.free;
  form1.RPCServer.Free;
End;

Procedure TForm1.FormResize(sender: TObject);
Begin
  InfoPanel.Left:= (Form1.ClientWidth div 2) - (InfoPanel.Width div 2);
  InfoPanel.Top := (Form1.ClientHeight div 2) - (InfoPanel.Height div 2);
End;

procedure TForm1.FormShow(sender: TObject);
Const
  GoAhead : boolean = true;
Begin
  if GoAhead then
    begin
    GoAhead := false;
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
End;

// Manual request to close the app
Procedure TForm1.FormCloseQuery(sender: TObject; var CanClose: boolean);
Begin
  G_CloseRequested := true;
  CanClose:= G_ClosingAPP;
End;

{$ENDREGION}

{$REGION Start app}

Procedure TForm1.InicoTimerEjecutar(sender: TObject);
Begin
  InicioTimer.Enabled:=false;
  StartProgram;
End;

// Init the mainform
Procedure InitMainForm();
Begin
  // Make sure ALL tabs are set correct at startup
  Form1.PageMain.ActivePage:= Form1.TabWallet;
  Form1.TabWalletMain.ActivePage:= Form1.TabAddresses;
  Form1.PageControl1.ActivePage:= Form1.TabOpt_Wallet;
  Form1.PCMonitor.ActivePage:=form1.TabDebug_Log;
  // Resize all grids at launch
  Form1.SG_PerformanceResize(nil);
  {Add all resize methods here}
  form1.DataPanel.FocusRectVisible:=false;
  form1.DataPanel.ColWidths[0]:= 79;
  form1.DataPanel.ColWidths[1]:= 115;
  form1.DataPanel.ColWidths[2]:= 79;
  form1.DataPanel.ColWidths[3]:= 115;
  Form1.imagenes.GetBitMap(9,Form1.ImageInc.Picture.Bitmap);
  Form1.imagenes.GetBitmap(10,Form1.Imageout.Picture.Bitmap);
  form1.DireccionesPanel.Options:= form1.DireccionesPanel.Options+[goRowSelect]-[goRangeSelect];
  form1.DireccionesPanel.ColWidths[0]:= 260;form1.DireccionesPanel.ColWidths[1]:= 107;
  form1.DireccionesPanel.FocusRectVisible:=false;
  form1.SGConSeeds.FocusRectVisible:=false;
  Form1.BDefAddr.Parent:=form1.DireccionesPanel;
  form1.BCustomAddr.Parent:=form1.DireccionesPanel;
  form1.BCopyAddr.Parent:=form1.DireccionesPanel;
  Form1.BNewAddr.Parent:=form1.DireccionesPanel;
  Form1.SGridSC.FocusRectVisible:=false;
  Form1.imagenes.GetBitMap(54,form1.ImgRotor.picture.BitMap);
  form1.LabAbout.Caption:=CoinName+' project'+SLINEBREAK+'Designed by bermello (imAOG)'+SLINEBREAK+
                          'Crypto routines by Xor-el'+SLINEBREAK+
                          'Version '+MainnetVersion+NodeRelease+SLINEBREAK+'Protocol '+IntToStr(Protocolo)+SLINEBREAK+BuildDate;
  form1.SG_Performance.FocusRectVisible:=false;
  form1.SG_Performance.ColWidths[0]:= 142;form1.SG_Performance.ColWidths[1]:= 73;
  form1.SG_Performance.ColWidths[2]:= 73;form1.SG_Performance.ColWidths[3]:= 73;

  Form1.Latido:= TTimer.Create(Form1);
  Form1.Latido.Enabled:=false;Form1.Latido.Interval:=200;
  Form1.Latido.OnTimer:= @form1.heartbeat;

  Form1.InfoTimer:= TTimer.Create(Form1);
  Form1.InfoTimer.Enabled:=false;Form1.InfoTimer.Interval:=50;
  Form1.InfoTimer.OnTimer:= @form1.InfoTimerEnd;

  Form1.Server := TIdTCPServer.Create(Form1);
  Form1.Server.DefaultPort:=DefaultServerPort;
  Form1.Server.Active:=false;
  Form1.Server.UseNagle:=true;
  Form1.Server.TerminateWaitTime:=10000;
  Form1.Server.OnExecute:=@form1.IdTCPServer1Execute;
  Form1.Server.OnConnect:=@form1.IdTCPServer1Connect;
  Form1.Server.OnDisconnect:=@form1.IdTCPServer1Disconnect;
  Form1.Server.OnException:=@Form1.IdTCPServer1Exception;

  Form1.RPCServer := TIdHTTPServer.Create(Form1);
  Form1.RPCServer.DefaultPort:=RPCPort;
  Form1.RPCServer.Active:=false;
  Form1.RPCServer.UseNagle:=true;
  Form1.RPCServer.TerminateWaitTime:=5000;
  Form1.RPCServer.OnCommandGet:=@form1.RPCServerExecute;
End;

// Start the application
Procedure TForm1.StartProgram();
Begin
  Form1.InfoPanel.Visible:=false;
  AddNewOpenThread('Main',UTCTime);
  if FileStructure > 0 then
    begin
    Application.MessageBox('There was an error creating the files structure and the program will close.', 'NosoNode Error', MB_ICONINFORMATION);
    Halt();
    end;
  MixTxtFiles([DeepDebLogFilename,ConsoleLogFilename,EventLogFilename,ExceptLogFilename,NodeFTPLogFilename,PerformanceFIlename],ResumeLogFilename,true);
  InitDeepDeb(DeepDebLogFilename,format('( %s - %s )',[MainnetVersion+NodeRelease, OSVersion]));
  NosoDebug_UsePerformance := true;
  UpdateLogsThread := TUpdateLogs.Create(true);
  UpdateLogsThread.FreeOnTerminate:=true;
  UpdateLogsThread.Start;
  CreateNewLog('console',ConsoleLogFilename);
  CreateNewLog('events',EventLogFilename);
  CreateNewLog('exceps',ExceptLogFilename);
  CreateNewLog('nodeftp',NodeFTPLogFilename);
  OutText(rs0022,false,1); //'✓ Files tree ok'
  InitMainForm();
  OutText(rs0023,false,1); //✓ GUI initialized
  VerifyFiles();
  if ( (not fileExists(ClosedAppFilename)) and (WO_Sendreport) ) then
    begin
    if SEndFileViaTCP(ResumeLogFilename,'REPORT','debuglogs.nosocoin.com',18081) then
      begin
      OutText('✓ Bug report sent to developers',false,1);
      end
    else OutText('x Error sending report to developers',false,1);
    end;
  TryDeleteFile(ClosedAppFilename);
  InitGUI();
  GetTimeOffset(PArameter(GetCFGDataStr,2));
  OutText('✓ Mainnet time synced',false,1);
  UpdateMyData();
  OutText(rs0024,false,1); //'✓ My data updated'
  LoadOptionsToPanel();
  form1.Caption:=coinname+format(rs0027,[MainnetVersion,NodeRelease]);
  Application.Title := coinname+format(rs0027,[MainnetVersion,NodeRelease]);   // Wallet
  ToLog('console',coinname+format(rs0027,[MainnetVersion,NodeRelease]));
  If BetaRelease then ToLog('console','*** WARNING ***'+slinebreak+'This is a beta version ('+MainnetVersion+NodeRelease+') Use it carefully, do not store funds on its wallet and report any issue to development team.');
  UpdateMyGVTsList;
  OutText(rs0088,false,1); // '✓ My GVTs grid updated';
  if fileexists(RestartFileName) then
    begin
    Deletefile(RestartFileName);
    OutText(rs0069,false,1); // '✓ Launcher file deleted';
    end;
  Form1.Latido.Enabled:=true;
  OutText('Noso is ready',false,1);
  SetNodesArray(GetCFGDataStr(1));
  StartAutoConsensus;
  if WO_CloseStart then
    begin
    G_Launching := false;
    if WO_autoserver then KeepServerOn := true;
    FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
    SetLength(ArrayCriptoOp,0);
    Setlength(MNsArray,0);
    Setlength(MNsList,0);
    Setlength(ArrMNChecks,0);
    //Setlength(WaitingMNs,0);
      ThreadMNs := TUpdateMNs.Create(true);
      ThreadMNs.FreeOnTerminate:=true;
      ThreadMNs.Start;
      CryptoThread := TCryptoThread.Create(true);
      CryptoThread.FreeOnTerminate:=true;
      CryptoThread.Start;
      SendOutMsgsThread := TThreadSendOutMsjs.Create(true);
      SendOutMsgsThread.FreeOnTerminate:=true;
      SendOutMsgsThread.Start;
      KeepConnectThread := TThreadKeepConnect.Create(true);
      KeepConnectThread.FreeOnTerminate:=true;
      KeepConnectThread.Start;
      if WO_BlockDB then
        begin
        IndexerThread := TThreadIndexer.Create(true);
        IndexerThread.FreeOnTerminate:=true;
        IndexerThread.Start;
        end;
    ToLog('events',TimeToStr(now)+rs0029); //NewLogLines := NewLogLines-1; //'Noso session started'
    info(rs0029);  //'Noso session started'
    infopanel.BringToFront;
    forminicio.Visible:=false;
    form1.Visible:=true;
    if FormState_Status = 0 then
      begin
      form1.Top:=FormState_Top;
      form1.Left:=FormState_Left;
      end;
    Form1.RestartTimer.Enabled:=true;
    end // CLOSE start form
  else FormInicio.BorderIcons:=FormInicio.BorderIcons-[biminimize]+[bisystemmenu];
End;

Procedure CompleteInicio();
Begin
  G_Launching := false;
  if WO_autoserver then KeepServerOn := true;
  FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
  SetLength(ArrayCriptoOp,0);
  Setlength(MNsArray,0);
  Setlength(MNsList,0);
  Setlength(ArrMNChecks,0);
  //Setlength(WaitingMNs,0);
    ThreadMNs := TUpdateMNs.Create(true);
    ThreadMNs.FreeOnTerminate:=true;
    ThreadMNs.Start;
    CryptoThread := TCryptoThread.Create(true);
    CryptoThread.FreeOnTerminate:=true;
    CryptoThread.Start;
    SendOutMsgsThread := TThreadSendOutMsjs.Create(true);
    SendOutMsgsThread.FreeOnTerminate:=true;
    SendOutMsgsThread.Start;
  ToLog('events',TimeToStr(now)+rs0029); //NewLogLines := NewLogLines-1; //'Noso session started'
  info(rs0029);  //'Noso session started'
  form1.infopanel.BringToFront;
  forminicio.Visible:=false;
  form1.Visible:=true;
  if FormState_Status = 0 then
    begin
    form1.Top:=FormState_Top;
    form1.Left:=FormState_Left;
    end;
  Form1.RestartTimer.Enabled:=true;
End;

Procedure TForm1.LoadOptionsToPanel();
Begin
  // WALLET
  CB_WO_HideEmpty.Checked   := WO_HideEmpty;
  CB_WO_Multisend.Checked   := WO_Multisend;
  CB_WO_Autoupdate.Checked  := WO_AutoUpdate;
  CBSendReports.checked     := WO_SendReport;
  // RPC
  LE_Rpc_Port.Text := IntToStr(RPCPort);
  LE_Rpc_Pass.Text := RPCPass;
  CB_BACKRPCaddresses.Checked := RPCSaveNew;
  CBRunNodeAlone.Checked:= WO_StopGUI;
  CBKeepBlocksDB.Checked:= WO_BlockDB;
  CB_RPCFilter.Checked:=RPCFilter;
  MemoRPCWhitelist.Text:=RPCWhitelist;
  Memobannedmethods.Text:=RPCBanned;
  if not RPCFilter then MemoRPCWhitelist.Enabled:=false;
  CB_AUTORPC.Checked:= RPCAuto;
End;

{$ENDREGION}

//*********************
// *** GUI CONTROLS ***
//*********************

{$REGION GUI controls}

// Double click open conexions slots form
procedure TForm1.StaConLabDblClick(sender: TObject);
Begin
  formslots.Visible:=true;
End;

// Check keypress on commandline
Procedure TForm1.ConsoleLineKeyup(sender: TObject; var Key: Word; Shift: TShiftState);
var
  LineText : String;
Begin
  LineText := ConsoleLine.Text;
  if Key=VK_RETURN then
    begin
    ConsoleLine.Text := '';
    LastCommand := LineText;
    if LineText <> '' then ProcessLinesAdd(LineText);
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
    {CTRL+I}
    end;
  if ((Shift = [ssCtrl]) and (Key = VK_K)) then
    begin
    {CTRL+K}
    end;
  if ((Shift = [ssCtrl]) and (Key = VK_O)) then
    begin
    {CTRL+O}
    end;
  if ((Shift = [ssCtrl]) and (Key = VK_L)) then
    begin
    {CTRL+L}
    end;
  if ((Shift = [ssCtrl, ssAlt]) and (Key = VK_D)) then
    begin
    {ctrl+alt+d}
    end;
End;

// Adjust data panel background colors
procedure TForm1.Grid1PrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  ts: TTextStyle;
Begin
  if ((ACol = 0) or (ACol = 2)) then
    begin
    (sender as TStringGrid).Canvas.Brush.Color :=  cl3dlight;
    ts := (sender as TStringGrid).Canvas.TextStyle;
    ts.Alignment := taCenter;
    (sender as TStringGrid).Canvas.TextStyle := ts;
    end
  else
    begin
    ts := (sender as TStringGrid).Canvas.TextStyle;
    ts.Alignment := taRightJustify;
    (sender as TStringGrid).Canvas.TextStyle := ts;
    end;
End;

// Color for addresses panel
procedure TForm1.Grid2PrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
var
  ts: TTextStyle;
  posrequired : int64;
Begin
  posrequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
  if (ACol=1)  then
    begin
    ts := (sender as TStringGrid).Canvas.TextStyle;
    ts.Alignment := taRightJustify;
    (sender as TStringGrid).Canvas.TextStyle := ts;
    {
    if ((aRow>0) and (GetWallArrIndex(aRow-1).Balance>posrequired) and (GetWallArrIndex(aRow-1).Balance>(posrequired+(WO_PosWarning*140*10000000))) ) then
      begin
      (sender as TStringGrid).Canvas.Brush.Color :=  clmoneygreen;
      (sender as TStringGrid).Canvas.font.Color :=  clblack;
      end;
    if ((aRow>0) and (GetWallArrIndex(aRow-1).Balance>posrequired) and (GetWallArrIndex(aRow-1).Balance< (posrequired+(WO_PosWarning*140*10000000))) ) then
      begin
      (sender as TStringGrid).Canvas.Brush.Color :=  clYellow;
      (sender as TStringGrid).Canvas.font.Color :=  clblack;
      end
    }
    end;
  if ( (ACol = 0) and (ARow>0) and (AnsiContainsStr(GetCFGDataStr(5),GetWallArrIndex(aRow-1).Hash)) ) then
    begin
    (sender as TStringGrid).Canvas.Brush.Color :=  clRed;
    (sender as TStringGrid).Canvas.font.Color :=  clblack;
    end;
End;

// Clear debug memo: Events
procedure TForm1.Button1Click(sender: TObject);
Begin
  MemoLog.Lines.Clear;
End;

// Clear debug memo: Exceptions
procedure TForm1.Button2Click(sender: TObject);
Begin
  MemoExceptLog.Lines.Clear;
End;

// Resize: data panel
procedure TForm1.DataPanelResize(sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.DataPanel.Width;
  form1.DataPanel.ColWidths[0]:= thispercent(20,GridWidth);
  form1.DataPanel.ColWidths[1]:= thispercent(30,GridWidth);
  form1.DataPanel.ColWidths[2]:= thispercent(20,GridWidth);
  form1.DataPanel.ColWidths[3]:= thispercent(30,GridWidth);
End;

// Resize: GridAddresses
procedure TForm1.DireccionesPanelResize(sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.DireccionesPanel.Width;
  form1.DireccionesPanel.ColWidths[0]:= thispercent(68,GridWidth);
  form1.DireccionesPanel.ColWidths[1]:= thispercent(32,GridWidth, true);
End;

// Resize: grid nodes
procedure TForm1.GridNodesResize(sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.GridNodes.Width;
  form1.GridNodes.ColWidths[0]:= thispercent(36,GridWidth);
  form1.GridNodes.ColWidths[1]:= thispercent(64,GridWidth,true);
  form1.GridNodes.ColWidths[2]:= thispercent(0,GridWidth);
  form1.GridNodes.ColWidths[3]:= thispercent(0,GridWidth);
  form1.GridNodes.ColWidths[4]:= thispercent(0,GridWidth, true);
End;

// Resize: consensus
procedure TForm1.SGConSeedsResize(Sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.SGConSeeds.Width;
  form1.SGConSeeds.ColWidths[0]:= thispercent(20,GridWidth);
  form1.SGConSeeds.ColWidths[1]:= thispercent(20,GridWidth);
  form1.SGConSeeds.ColWidths[2]:= thispercent(40,GridWidth);
  form1.SGConSeeds.ColWidths[3]:= thispercent(20,GridWidth,true);
End;

// Resize: Performance
procedure TForm1.SG_PerformanceResize(sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.SG_Performance.Width;
  form1.SG_Performance.ColWidths[0]:= thispercent(40,GridWidth);
  form1.SG_Performance.ColWidths[1]:= thispercent(20,GridWidth);
  form1.SG_Performance.ColWidths[2]:= thispercent(20,GridWidth);
  form1.SG_Performance.ColWidths[3]:= thispercent(20,GridWidth,true);
End;

// Resize: Processes Threads
procedure TForm1.SG_OpenThreadsResize(Sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.SG_Performance.Width;
  form1.SG_OpenThreads.ColWidths[0]:= thispercent(50,GridWidth);
  form1.SG_OpenThreads.ColWidths[1]:= thispercent(30,GridWidth);
  form1.SG_OpenThreads.ColWidths[2]:= thispercent(20,GridWidth,true);
End;

// Resize: Processes Files
procedure TForm1.PC_ProcessesResize(Sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.SG_Performance.Width;
  form1.SG_FilePRocs.ColWidths[0]:= thispercent(25,GridWidth);
  form1.SG_FilePRocs.ColWidths[1]:= thispercent(25,GridWidth);
  form1.SG_FilePRocs.ColWidths[2]:= thispercent(25,GridWidth);
  form1.SG_FilePRocs.ColWidths[3]:= thispercent(25,GridWidth,true);
End;

//Resize: About
procedure TForm1.Tab_Options_AboutResize(sender: TObject);
Begin
  ImageOptionsAbout.BorderSpacing.Left:=
    (Tab_Options_About.ClientWidth div 2) -
    (ImageOptionsAbout.Width div 2);
  BitBtnWeb.BorderSpacing.Left:=
    (Tab_Options_About.ClientWidth div 2) -
    (BitBtnWeb.Width div 2);
  BitBtnDonate.BorderSpacing.Left:=
    (Tab_Options_About.ClientWidth div 2) -
    (BitBtnDonate.Width div 2);
End;

// Resize: GVTs grid
procedure TForm1.GVTsGridResize(sender: TObject);
var
  GridWidth : integer;
Begin
  GridWidth := form1.GVTsGrid.Width;
  form1.GVTsGrid.ColWidths[0]:= thispercent(20,GridWidth);
  form1.GVTsGrid.ColWidths[1]:= thispercent(80,GridWidth,true);
End;

{$ENDREGION}

{$REGION To Re-evaluate}

// App heartbeat
Procedure TForm1.heartbeat(sender: TObject);
Begin
  UpdateOpenThread('Main',UTCTime);
  if EngineLastUpdate <> UTCtime then EngineLastUpdate := UTCtime;
  Form1.Latido.Enabled:=false;
  if ( (UTCTime >= BuildNMSBlock) and (BuildNMSBlock>0) and (MyConStatus=3) and (MyLastBlock=StrToIntDef(GetCOnsensus(2),-1)) ) then
    begin
    ToLog('events','Starting construction of block '+(MyLastBlock+1).ToString);
    BuildNewBlock(MyLastBlock+1,BuildNMSBlock,MyLastBlockHash,{GetNMSData.Miner}'NpryectdevepmentfundsGE',{GetNMSData.Hash}'!!!!!!!!!100000000');
    G_MNVerifications := 0;
    end;
  BeginPerformance('ActualizarGUI');
  ActualizarGUI();
  EndPerformance('ActualizarGUI');
  BeginPerformance('SaveUpdatedFiles');
  SaveUpdatedFiles();
  EndPerformance('SaveUpdatedFiles');
  BeginPerformance('ProcesarLineas');
  ProcesarLineas();
  EndPerformance('ProcesarLineas');
  BeginPerformance('LeerLineasDeClientes');
  LeerLineasDeClientes();
  EndPerformance('LeerLineasDeClientes');
  BeginPerformance('ParseProtocolLines');
  ParseProtocolLines();
  EndPerformance('ParseProtocolLines');
  BeginPerformance('VerifyConnectionStatus');
  VerifyConnectionStatus();
  EndPerformance('VerifyConnectionStatus');
  if G_CloseRequested then CloseeAppSafely();
  if FormSlots.Visible then UpdateSlotsGrid();
  Inc(ConnectedRotor); if ConnectedRotor>6 then ConnectedRotor := 0;
  UpdateStatusBar;
  if ((UTCTime mod 60 = 0) and (LastIPsClear<>UTCTime)) then ClearIPControls;
  if ( (UTCTime mod 3600=3590) and (LastBotClear<>UTCTime) and (Form1.Server.Active) ) then DeleteBots;
  if ( (UTCTime mod 600>=570) and (UTCTime>NosoT_LastUpdate+599) ) then
    UpdateOffset(PArameter(GetCFGDataStr,2));
  Form1.Latido.Enabled:=true;
End;

// Info label timer
Procedure TForm1.InfoTimerEnd(sender: TObject);
Begin
  InfoPanelTime := InfoPanelTime-50;
  if InfoPanelTime <= 0 then
    begin
    InfoPanelTime := 0;
    InfoPanel.Caption:='';
    InfoPanel.sendtoback;
    end;
End;

// Displays incoming/outgoing amounts
Procedure TForm1.CheckForHint(sender:TObject);
Begin
  Processhint(sender);
End;

// Disable default popup menu for a control
Procedure TForm1.DisablePopUpMenu(sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
  Handled := True;
End;

// Updates status bar
Procedure UpdateStatusBar();
Begin
  if WO_StopGUI then exit;
  if Form1.Server.Active then Form1.StaSerImg.Visible:=true
  else Form1.StaSerImg.Visible:=false;
  Form1.StaConLab.Caption:=IntToStr(GetTotalSyncedConnections);
  if MyConStatus = 0 then Form1.StaConLab.Color:= clred;
  if MyConStatus = 1 then Form1.StaConLab.Color:= clyellow;
  if MyConStatus = 2 then Form1.StaConLab.Color:= claqua;
  if MyConStatus = 3 then Form1.StaConLab.Color:= clgreen;
  Form1.BitBtnBlocks.Caption:=IntToStr(MyLastBlock);
  form1.BitBtnPending.Caption:=GetPendingCount.ToString;
  if form1.RPCServer.active then Form1.StaRPCimg.Visible:=true
  else Form1.StaRPCimg.Visible:=false;
  Form1.Imgs32.GetBitMap(ConnectedRotor,form1.ImgRotor.picture.BitMap);
End;

Procedure TForm1.RestartTimerEjecutar(sender: TObject);
Begin
  if BlockAge<590 then
    begin
    if BuildNMSBlock < UTCTime then
      begin
      BuildNMSBlock := NextBlockTimeStamp;
      ToLog('events','Next block time set to: '+TimeStampToDate(BuildNMSBlock));
      end;
    end;
  RestartTimer.Enabled:=false;
  if not WO_StopGUI then
    StaTimeLab.Caption:=TimestampToDate(UTCTime);
  if G_CloseRequested then
    begin
    if not G_CloseRequested then
      begin
      RestartNosoAfterQuit := true;
      end;
    CloseeAppSafely;
    end
  else RestartTimer.Enabled:=true;
End;

{$ENDREGION}

{$REGION CloseApp}

Procedure CloseeAppSafely();
var
  counter      : integer;
  GoAhead      : boolean = false;
  EarlyRestart : Boolean;

  procedure CloseLine(texto:String);
  Begin
    gridinicio.RowCount:=gridinicio.RowCount+1;
    gridinicio.Cells[0,gridinicio.RowCount-1]:=Texto;
    gridinicio.TopRow:=gridinicio.RowCount;
    Application.ProcessMessages;
  End;

Begin
  EnterCriticalSection(CSClosingApp);
  if not G_ClosingAPP then
    begin
    G_ClosingAPP := true;
    GoAhead := true;
    end;
  LeaveCriticalSection(CSClosingApp);
  if GoAhead then
    begin
    PerformanceToFile(PerformanceFilename);
    EarlyRestart := form1.Server.Active;
    Form1.Latido.Enabled:=false; // Stopped the latido
    form1.RestartTimer.Enabled:=false;
    forminicio.Caption:='Closing';
    gridinicio.RowCount := 0;
    form1.Visible:=false;
    forminicio.Visible:=true;
    FormInicio.BorderIcons:=FormInicio.BorderIcons-[bisystemmenu];
    CloseLine(rs0030);  //   Closing wallet
    CreateADV(false); // save advopt
    sleep(100);
    CloseAllforms();
    CloseLine('Forms closed');
    sleep(100);
    CloseLine(CerrarClientes(false));
    sleep(100);
    if ((EarlyRestart) and (RestartNosoAfterQuit)) then RestartNoso;
    if form1.Server.Active then
      begin
      if StopServer then CloseLine('Node server stopped')
      else CloseLine('Error closing node server');
      end;
    sleep(100);
    If Assigned(ProcessLines) then ProcessLines.Free;
    CloseLine('Componnents freed');
    sleep(100);
    EnterCriticalSection(CSOutgoingMsjs);
    OutgoingMsjs.clear;
    LeaveCriticalSection(CSOutgoingMsjs);
    TRY
      If Assigned(SendOutMsgsThread) then
        begin
        SendOutMsgsThread.Terminate;
        for counter := 1 to 10 do
          begin
          if ( (Assigned(SendOutMsgsThread)) and (not SendOutMsgsThread.Terminated) ) then sleep(1000)
          else break;
          end;
        end;
    if ((Assigned(SendOutMsgsThread)) and (not SendOutMsgsThread.Terminated)) then CloseLine('Out thread NOT CLOSED')
    else CloseLine('Out thread closed properly');
    EXCEPT ON E: EXCEPTION DO
      CloseLine('Error closing Out thread');
    END{Try};
    sleep(100);
    If Assigned(OutgoingMsjs) then OutgoingMsjs.Free;
    EnterCriticalSection(CSCriptoThread);
    SetLength(ArrayCriptoOp,0);
    LeaveCriticalSection(CSCriptoThread);
    TRY
    If Assigned(CryptoThread) then
      begin
      CryptoThread.Terminate;
      for counter := 1 to 10 do
        begin
        if ( (Assigned(CryptoThread)) and (not CryptoThread.Terminated) ) then sleep(1000)
        else break;
        end;
      end;
    if ((Assigned(CryptoThread)) and (not CryptoThread.Terminated)) then CloseLine('Crypto thread NOT CLOSED')
    else CloseLine('Crypto thread closed properly');
    EXCEPT ON E: EXCEPTION DO
      CloseLine('Error closing crypto thread');
    END{Try};
    sleep(100);
    TRY
    If Assigned(UpdateLogsThread) then
      begin
      UpdateLogsThread.Terminate;
      for counter := 1 to 10 do
        begin
        if ( (Assigned(UpdateLogsThread)) and (not UpdateLogsThread.Terminated) ) then sleep(1000)
        else break;
        end;
      end;
    if ((Assigned(UpdateLogsThread)) and (not UpdateLogsThread.Terminated)) then CloseLine('Updatelogs thread NOT CLOSED')
    else CloseLine('Updatelogs thread closed properly');
    EXCEPT ON E: EXCEPTION DO
      CloseLine('Error closing Updatelogs thread');
    END{Try};
    sleep(100);
    TRY
    If Assigned(ThreadMNs) then
      begin
      ThreadMNs.Terminate;
      for counter := 1 to 10 do
        begin
        if ( (Assigned(ThreadMNs)) and (not ThreadMNs.Terminated) ) then sleep(1000)
        else break;
        end;
      end;
    if ((Assigned(ThreadMNs)) and (not ThreadMNs.Terminated)) then CloseLine('Nodes thread NOT CLOSED')
    else CloseLine('Nodes thread closed properly');
    EXCEPT ON E: EXCEPTION DO
      CloseLine('Error closing Nodes thread');
    END{Try};
    sleep(100);
    if ((not EarlyRestart) and (RestartNosoAfterQuit)) then RestartNoso;
    CreateEmptyFile(ClosedAppFilename);
    form1.Close;
    end;
End;

{$ENDREGION}

{$REGION RPC Server}

// A RPC REQUEST ENTERS
procedure TForm1.RPCServerExecute(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);
var
  PostString: String = '';
//  StreamString: TStream ;
  StreamString: TStringStream ;
Begin
if ( (RPCFilter) and (Not ValidRPCHost(ARequestInfo.RemoteIP)) ) then
   begin
   AResponseInfo.ContentText:= GetJSONErrorCode(498,-1);
   end
else if ARequestInfo.Command <> 'POST' then
   begin
   AResponseInfo.ContentText:= GetJSONErrorCode(400,-1);
   end
else if ARequestInfo.Command = 'POST' then
   begin  // Is a post request
   StreamString := TStringStream.Create('', TEncoding.UTF8);
   TRY
   StreamString.LoadFromStream(ARequestInfo.PostStream);
   if assigned(StreamString) then
      begin
      StreamString.Position:=0;
      PostString := ReadStringFromStream(StreamString,-1,IndyTextEncoding_UTF8);
      end;
   EXCEPT ON E:EXCEPTION DO
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on Http server: '+E.Message);
   END; {TRY}
   AResponseInfo.ContentText:= ParseRPCJSON(PostString);
   StreamString.Free;
   end;
End;

{$ENDREGION}

// *****************************
// *** NODE SERVER FUNCTIONS ***
// *****************************

{$REGION Node Server}

// returns the number of active connections
function TForm1.ClientsCount : Integer ;
var
  Clients : TList;
Begin
  Clients:= server.Contexts.LockList;
    TRY
    Result := Clients.Count ;
    EXCEPT ON E:Exception do
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error getting server list count: '+E.Message);
    END; {TRY}
  server.Contexts.UnlockList;
End ;

// Try message to Node safely
Function TForm1.TryMessageToNode(AContext: TIdContext;message:string):boolean;
Begin
  result := true;
  TRY
  Acontext.Connection.IOHandler.WriteLn(message);
  EXCEPT on E:Exception do
    begin
    result := false
    end;
  END;{Try}
End;

// Get stream from client
Function TForm1.GetStreamFromContext(AContext: TIdContext;out LStream:TMemoryStream):boolean;
Begin
  result := false;
  LStream.Clear;
  TRY
    AContext.Connection.IOHandler.ReadStream(LStream);
    Result := True;
  EXCEPT on E:Exception do
    ToDeepDeb('NosoServer,GetStreamFromContext,'+E.Message);
  END;
End;

// Trys to close a server connection safely
Procedure TForm1.TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
Begin
  TRY
  if closemsg <>'' then
    Acontext.Connection.IOHandler.WriteLn(closemsg);
  AContext.Connection.Disconnect();
  Acontext.Connection.IOHandler.InputBuffer.Clear;
  EXCEPT on E:Exception do
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0042,[E.Message]));
  END; {TRY}
End;

// Node server gets a line
procedure TForm1.IdTCPServer1Execute(AContext: TIdContext);
var
  LLine : String = '';
  IPUser : String = '';
  slot : integer = 0;
  UpdateZipName : String = ''; UpdateVersion : String = ''; UpdateHash:string ='';
  UpdateClavePublica :string ='';UpdateFirma : string = '';
  MemStream   : TMemoryStream;
  BlockZipName: string = '';
  GetFileOk : boolean = false;
  GoAhead : boolean;
  NextLines : array of string;
  LineToSend : string;
  LinesSent : integer = 0;
  FTPTime, FTPSize, FTPSpeed : int64;
Begin
  GoAhead := true;
  IPUser := AContext.Connection.Socket.Binding.PeerIP;
  slot := GetSlotFromIP(IPUser);
    REPEAT
    LineToSend := GetTextToSlot(slot);
    if LineToSend <> '' then
      begin
      TryMessageToNode(AContext,LineToSend);
      Inc(LinesSent);
      end;
    UNTIL LineToSend='' ;
  if LinesSent >0 then exit;
  if slot = 0 then
    begin
    TryCloseServerConnection(AContext);
    exit;
    end;
  if ( (MyConStatus <3) and (not IsSeedNode(IPUser)) ) then
    begin
    TryCloseServerConnection(AContext,'Closing NODE');
    exit;
    end;
  TRY
  LLine := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
  EXCEPT on E:Exception do
    begin
    TryCloseServerConnection(AContext);
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0045,[IPUser,E.Message]));
    GoAhead := false;
    end;
  END{Try};
  if GoAhead then
    begin
    SetConexIndexBusy(Slot,true);
    if Parameter(LLine,0) = 'RESUMENFILE' then
      begin
      MemStream := TMemoryStream.Create;
      DownloadHeaders := true;
        TRY
        AContext.Connection.IOHandler.ReadStream(MemStream);
        GetFileOk := true;
        EXCEPT ON E:EXCEPTION do
          begin
          TryCloseServerConnection(AContext);
          GetFileOk := false;
          end;
        END; {TRY}
      if GetfileOk then
        begin
        if SaveStreamAsHeaders(MemStream) then
          ToLog('console',Format(rs0047,[copy(HashMD5File(ResumenFilename),1,5)]));//'Headers file received'
        end;
      UpdateMyData();
      LastTimeRequestResumen := 0;
      DownloadHeaders := false;
      MemStream.Free;
      end // END GET RESUMEN FILE
   else if LLine = 'BLOCKZIP' then
     begin
     BlockZipName := BlockDirectory+'blocks.zip';
     TryDeleteFile(BlockZipName);
     MemStream := TMemoryStream.Create;
     DownLoadBlocks := true;
       TRY
       AContext.Connection.IOHandler.ReadStream(MemStream);
       MemStream.SaveToFile(BlockZipName);
       GetFileOk := true;
       EXCEPT ON E:Exception do
         begin
         GetFileOk := false;
         TryCloseServerConnection(AContext);
         end;
       END; {TRY}
       if GetFileOk then
         begin
         if UnzipFile(BlockDirectory+'blocks.zip',true) then
           begin
           MyLastBlock := GetMyLastUpdatedBlock();
           LastTimeRequestBlock := 0;
           ToLog('events',TimeToStr(now)+format(rs0021,[IntToStr(MyLastBlock)])); //'Blocks received up to '+IntToStr(MyLastBlock));
           end
         end;
       MemStream.Free;
       DownLoadBlocks := false;
     end
   else if parameter(LLine,4) = '$GETRESUMEN' then
      begin
      AddFileProcess('Send','Headers',IPUser,GetTickCount64);
      MemStream := TMemoryStream.Create;
      FTPSize := GetHeadersAsMemStream(MemStream);
      if FTPSize>0 then
         begin
            TRY
            Acontext.Connection.IOHandler.WriteLn('RESUMENFILE');
            Acontext.connection.IOHandler.Write(MemStream,0,true);
            EXCEPT on E:Exception do
               begin
               Form1.TryCloseServerConnection(GetConexIndex(Slot).context);
               ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0051,[E.Message]));
               end;
            END; {TRY}
         end;
      MemStream.Free;
      FTPTime := CloseFileProcess('Send','Headers',IPUser,GetTickCount64);
      FTPSpeed := (FTPSize div FTPTime);
      ToLog('nodeftp','Uploaded headers to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
      end
   else if parameter(LLine,4) = '$GETSUMARY' then
      begin
      AddFileProcess('Send','Summary',IPUser,GetTickCount64);
      MemStream := TMemoryStream.Create;
      FTPSize := GetSummaryAsMemStream(MemStream);
      if FTPSize>0 then
         begin
           TRY
           Acontext.Connection.IOHandler.WriteLn('SUMARYFILE');
           Acontext.connection.IOHandler.Write(MemStream,0,true);
           EXCEPT on E:Exception do
           END; {TRY}
         end;
      MemStream.Free;
      FTPTime := CloseFileProcess('Send','Summary',IPUser,GetTickCount64);
      FTPSpeed := (FTPSize div FTPTime);
      ToLog('nodeftp','Uploaded Summary to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
      end
   else if parameter(LLine,4) = '$GETPSOS' then
      begin
      AddFileProcess('Send','PSOs',IPUser,GetTickCount64);
      MemStream := TMemoryStream.Create;
      FTPSize := GetPSOsAsMemStream(MemStream);
      if FTPSize>0 then
         begin
           TRY
           Acontext.Connection.IOHandler.WriteLn('PSOSFILE');
           Acontext.connection.IOHandler.Write(MemStream,0,true);
           EXCEPT on E:Exception do
           END; {TRY}
         end;
      MemStream.Free;
      FTPTime := CloseFileProcess('Send','PSOs',IPUser,GetTickCount64);
      FTPSpeed := (FTPSize div FTPTime);
      ToLog('nodeftp','Uploaded PSOs to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
      end
   else if parameter(LLine,4) = '$LASTBLOCK' then
      begin // START SENDING BLOCKS
      AddFileProcess('Send','Blocks',IPUser,GetTickCount64);
      BlockZipName := CreateZipBlockfile(StrToIntDef(parameter(LLine,5),0));
      if BlockZipName <> '' then
         begin
         MemStream := TMemoryStream.Create;
            TRY
            MemStream.LoadFromFile(BlockZipName);
            GetFileOk := true;
            EXCEPT ON E:Exception do
               begin
               GetFileOk := false;
               end;
            END; {TRY}
         FTPSize := MemStream.Size;
         If GetFileOk then
            begin
               TRY
               Acontext.Connection.IOHandler.WriteLn('BLOCKZIP');
               Acontext.connection.IOHandler.Write(MemStream,0,true);
               ToLog('events',TimeToStr(now)+Format(rs0052,[IPUser,BlockZipName])); //SERVER: BlockZip send to '+IPUser+':'+BlockZipName);
               EXCEPT ON E:Exception do
                  begin
                  Form1.TryCloseServerConnection(GetConexIndex(Slot).context);
                  //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0053,[E.Message])); //'SERVER: Error sending ZIP blocks file ('+E.Message+')');
                  end
               END; {TRY}
            end;
         MemStream.Free;
         FTPTime := CloseFileProcess('Send','Blocks',IPUser,GetTickCount64);
         FTPSpeed := (FTPSize div FTPTime);
         ToLog('nodeftp','Uploaded Blocks to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
         Trydeletefile(BlockZipName); // safe function to delete files
         end
      end // END SENDING BLOCKS

      else if parameter(LLine,4) = '$GETGVTS' then
         begin
         AddFileProcess('Send','GVTs',IPUser,GetTickCount64);
         MemStream := TMemoryStream.Create;
         FTPSize := GetGVTsAsStream(MemStream);
         if FTPSize>0 then
           begin
             TRY
             Acontext.Connection.IOHandler.WriteLn('GVTSFILE');
             Acontext.connection.IOHandler.Write(MemStream,0,true);
             EXCEPT on E:Exception do
             END; {TRY}
           end;
         MemStream.Free;
         FTPTime := CloseFileProcess('Send','GVTs',IPUser,GetTickCount64);
         FTPSpeed := (FTPSize div FTPTime);
         ToLog('nodeftp','Uploaded GVTs to '+IPUser+' at '+FTPSpeed.ToString+' kb/s');
         end // SENDING GVTS FILE

      else if parameter(LLine,0) = 'PSOSFILE' then
        begin
        DownloadPSOs := true;
        MemStream := TMemoryStream.Create;
        if GetStreamFromContext(Acontext,MemStream) then
          begin
          if SavePSOsToFile(MemStream) then
            begin
            LoadPSOFileFromDisk;
            UpdateMyData();
            ToLog('console','PSOs file received on server');
            end;
          end;
        MemStream.Free;
        DownloadPSOs := false;
        LasTimePSOsRequest := 0;
        end

   else if AnsiContainsStr(ValidProtocolCommands,Uppercase(parameter(LLine,4))) then
      begin
         TRY
         AddToIncoming(slot,LLine);
         EXCEPT
         On E :Exception do
            ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0054,[E.Message]));
            //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'SERVER: Server error adding received line ('+E.Message+')');
         END; {TRY}
      end
   else
      begin
      TryCloseServerConnection(AContext);
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+Format(rs0055,[LLine]));
      //ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'SERVER: Got unexpected line: '+LLine);
      end;
   SetConexIndexBusy(Slot,false);
   end;
End;

// Un usuario intenta conectarse
procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
const
  LastBlocksRequest : int64 = 0;
var
  IPUser      : string;
  LLine       : String;
  MiIp        : String = '';
  Peerversion : string = '';
  GoAhead     : boolean;
  GetFileOk   : boolean = false;
  MemStream   : TMemoryStream;
  ContextData : TServerTipo;
  ThisSlot    : integer;
  PeerUTC     : int64;
  BlockZipName: string = '';
  BlockZipsize: int64;
Begin
  GoAhead := true;
  ContextData := TServerTipo.Create;
  ContextData.Slot:=0;
  AContext.Data:=ContextData;
  IPUser := AContext.Connection.Socket.Binding.PeerIP;
  if BotExists(IPUser) then
    begin
    TryCloseServerConnection(AContext,'BANNED');
    exit;
    end;
  if AddIPControl(IPUser) > 99 then
    begin
    TryCloseServerConnection(AContext,'');
    UpdateBotData(IPUser);
    ToLog('console','IP spammer: '+IPUser);
    exit;
    end;
  if ( (MyConStatus <3) and (not IsSeedNode(IPUser)) ) then
    begin
    TryCloseServerConnection(AContext,'Closing NODE');
    exit;
    end;
  if KeepServerOn = false then // Reject any new connection if we are closing the server
    begin
    TryCloseServerConnection(AContext,'Closing NODE');
    exit;
    end;
  LLine := '';
  TRY
    LLine := AContext.Connection.IOHandler.ReadLn('',1000,-1,IndyTextEncoding_UTF8);
  EXCEPT on E:Exception do
    begin
    TryCloseServerConnection(AContext);
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+format(rs0057,[E.Message]));
    GoAhead := false;
    end;
  END{Try};
  MiIp        := Parameter(LLine,1);
  Peerversion := Parameter(LLine,2);
  PeerUTC     := StrToInt64Def(Parameter(LLine,3),0);
  if GoAhead then
    begin
    if parameter(LLine,0) = 'NODESTATUS' then
      TryCloseServerConnection(AContext,'NODESTATUS '+GetNodeStatusString)
    else if parameter(LLine,0) = 'NSLORDER' then
      TryCloseServerConnection(AContext,PTC_Order(LLine))
    else if parameter(LLine,0) = 'NSLCUSTOM' then
      TryCloseServerConnection(AContext,PTC_Custom(GetOpData(LLine)).ToString)
    else if parameter(LLine,0) = 'NSLSENDGVT' then
      TryCloseServerConnection(AContext,PTC_SendGVT(LLine).ToString)
    else if parameter(LLine,0) = 'GETMIIP' then
      TryCloseServerConnection(AContext,IPUser)
    else if parameter(LLine,0) = 'MNVER' then
      TryCloseServerConnection(AContext,GetVerificationMNLine(IPUser))
    else if parameter(LLine,0) = 'NSLBALANCE' then
      TryCloseServerConnection(AContext,IntToStr(GetAddressAvailable(parameter(LLine,1))))
    else if parameter(LLine,0) = 'NSLPEND' then
      TryCloseServerConnection(AContext,PendingRawInfo(false))
    else if parameter(LLine,0) = 'NSLPENDFULL' then
      TryCloseServerConnection(AContext,PendingRawInfo)
    else if parameter(LLine,0) = 'NSLBLKORD' then
      TryCloseServerConnection(AContext,GEtNSLBlkOrdInfo(LLine))
    else if parameter(LLine,0) = 'NSLTIME' then
      TryCloseServerConnection(AContext,UTCTimeStr)
    else if parameter(LLine,0) = 'NSLMNS' then
      TryCloseServerConnection(AContext,GetMN_FileText)
    else if parameter(LLine,0) = 'NSLCFG' then
      TryCloseServerConnection(AContext,GetCFGDataStr)
    else if parameter(LLine,0) = 'NSLGVT' then
      begin
      MemStream := TMemoryStream.Create;
      if GetGVTsAsStream(MemStream) > 0 then GetFileOk := true
      else GetFileOk := false;
      if GetFileOk then
         begin
            TRY
            Acontext.Connection.IOHandler.WriteLn('GVTFILE '+Copy(MyGVTsHash,0,5));
            Acontext.connection.IOHandler.Write(MemStream,0,true);
            EXCEPT on E:Exception do
               begin
               end;
            END; {TRY}
         end;
      MemStream.Free;
      TryCloseServerConnection(AContext);
      end
    {
    else if parameter(LLine,0) = 'NSLBLOCKS' then
      begin
      if LastBlocksRequest+15>UTCTime then
        begin
        TryCloseServerConnection(AContext);
        Exit;
        end;
      MemStream := TMemoryStream.Create;
      BlockZipsize := GetBlocksAsStream(MemStream,StrToIntDef(parameter(LLine,1),-1),MyLastBlock);
      If BlockZipsize > 0 then
        begin
        LastBlocksRequest := UTCTIme;
          TRY
          Acontext.Connection.IOHandler.WriteLn('BLOCKZIP '+inttoStr(BlockZipsize));
          Acontext.connection.IOHandler.Write(MemStream,0,true);
          EXCEPT on E:Exception do
            begin
            end;
          END; {TRY}
        end;
      MemStream.Free;
      TryCloseServerConnection(AContext);
      end
    }
    else if parameter(LLine,0) = 'GETZIPSUMARY' then  //
      begin
      MemStream := TMemoryStream.Create;
      if GetZIPSummaryAsMemStream(MemStream) > 0 then GetFileOk := true
      else GetFileOk := false;
      if GetFileOk then
         begin
            TRY
            Acontext.Connection.IOHandler.WriteLn('ZIPSUMARY '+Copy(MySumarioHash,0,5));
            Acontext.connection.IOHandler.Write(MemStream,0,true);
            EXCEPT on E:Exception do
               begin
               end;
            END; {TRY}
         end;
      MemStream.Free;
      TryCloseServerConnection(AContext);
      end
   {
   else if not IsSeedNode(IPUser) then
     begin
     TryCloseServerConnection(AContext,'');
     exit;
     end
   }
   else if Copy(LLine,1,4) <> 'PSK ' then  // invalid protocol
      begin
      ToLog('events',TimeToStr(now)+format(rs0058,[IPUser])); //ToLog('events',TimeToStr(now)+'SERVER: Invalid client->'+IPUser);
      TryCloseServerConnection(AContext,'WRONG_PROTOCOL');
      UpdateBotData(IPUser);
      end

   else if IPUser = MyPublicIP then
      begin
      ToLog('events',TimeToStr(now)+rs0059);
      //ToLog('events',TimeToStr(now)+'SERVER: Own connected');
      TryCloseServerConnection(AContext);
      end

   else if ( (Abs(UTCTime-PeerUTC)>5) and (Mylastblock >= 70000) ) then
      begin
      TryCloseServerConnection(AContext,'WRONG_TIME');
      end
   {
   else if BotExists(IPUser) then // known bot
      begin
      TryCloseServerConnection(AContext,'BANNED');
      end
   }
   else if GetSlotFromIP(IPUser) > 0 then
      begin
      ToLog('events',TimeToStr(now)+Format(rs0060,[IPUser]));
      //ToLog('events',TimeToStr(now)+'SERVER: Duplicated connection->'+IPUser);
      TryCloseServerConnection(AContext,GetPTCEcn+'DUPLICATED');
      UpdateBotData(IPUser);
      end
   else if Copy(Peerversion,1,3) < Copy(VersionRequired,1,3) then
      begin
      TryCloseServerConnection(AContext,GetPTCEcn+'OLDVERSION->REQUIRED_'+VersionRequired);
      end
   else if Copy(LLine,1,4) = 'PSK ' then
      begin    // Check for available slot
      ThisSlot := SaveConection('CLI',IPUser,Acontext);
      if ThisSlot = 0 then  // Server full
         TryCloseServerConnection(AContext)
      else
         begin
         ToLog('events',TimeToStr(now)+format(rs0061,[IPUser])); //New Connection from:
         ContextData.Slot:=ThisSlot;
         AContext.Data:=ContextData;
         if IsValidIP(MiIp) then MyPublicIP := MiIp;
         U_DataPanel := true;
         ClearOutTextToSlot(ThisSlot);
         end;
      end
   else
      begin
      ToLog('events',TimeToStr(now)+Format(rs0062,[IPUser]));
      //ToLog('events',TimeToStr(now)+'SERVER: Closed unhandled incoming connection->'+IPUser);
      TryCloseServerConnection(AContext);
      end;
   end;
End;

// Un cliente se desconecta del servidor
procedure TForm1.IdTCPServer1Disconnect(AContext: TIdContext);
var
  ContextData : TServerTipo;
Begin
  ContextData:= TServerTipo(AContext.Data);
  if ContextData.Slot>0 then
    CloseSlot(ContextData.Slot);
End;

// Excepcion en el servidor
procedure TForm1.IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
Begin
  CloseSlot(GetSlotFromContext(AContext));
  ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Server Excepcion: '+AException.Message);    //Server Excepcion:
End;

{$ENDREGION Node Server}

{$REGION Addresses Stringgrid}

// Set selected address as default
Procedure TForm1.BDefAddrOnClick(sender: TObject);
Begin
  if DireccionesPanel.Row > 0 then
    ProcessLinesAdd('SETDEFAULT '+DireccionesPanel.Cells[0,DireccionesPanel.Row]);
End;

// Shows customization panel
Procedure TForm1.BCustomAddrOnClick(sender: TObject);
var
  Address : string;
Begin
  Address := DireccionesPanel.Cells[0,DireccionesPanel.Row];
  if not IsValidHashAddress(address) then info('Address already customized')
  else if AddressAlreadyCustomized(address) then info('Address already customized')
  else if GetAddressBalanceIndexed(Address)-GetAddressPendingPays(address)< GetCustFee(MyLastBlock) then info('Insufficient funds')
  else
    begin
    DireccionesPanel.Enabled:=false;
    PanelCustom.Visible := true;
    PanelCustom.BringToFront;
    EditCustom.SetFocus;
    end;
End;

// Get return press on customization panel
Procedure Tform1.EditCustomKeyUp(sender: TObject; var Key: Word; Shift: TShiftState);
Begin
  if Key=VK_RETURN then
    begin
    ProcessLinesAdd('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
    PanelCustom.Visible := false;
    EditCustom.Text := '';
    end;
End;

// Process customization
Procedure TForm1.BOkCustomClick(sender: TObject);
Begin
  ProcessLinesAdd('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
  PanelCustom.Visible := false;
  EditCustom.Text := '';
End;

// Close customization panel on mouse leave
Procedure TForm1.PanelCustomMouseLeave(sender: TObject);
Begin
  PanelCustom.Visible := false;
  DireccionesPanel.Enabled:=true;
End;

// New address button
Procedure TForm1.BNewAddrOnClick(sender: TObject);
Begin
  ProcessLinesAdd('newaddress');
End;

// Copy address button
Procedure TForm1.BCopyAddrClick(sender: TObject);
Begin
  Clipboard.AsText:= DireccionesPanel.Cells[0,DireccionesPanel.Row];
  {
  if GetWallArrIndex(DireccionesPanel.Row-1).custom <> '' then
    Clipboard.AsText:= GetWallArrIndex(DireccionesPanel.Row-1).custom
  else Clipboard.AsText:= GetWallArrIndex(DireccionesPanel.Row-1).Hash;
  }
  info('Copied to clipboard');//'Copied to clipboard'
End;

// Grid Addresses DrawCell
procedure TForm1.DireccionesPanelDrawCell(sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Bitmap    : TBitmap;
  myRect    : TRect;
  ColWidth : Integer;
Begin
  if ( (aRow>0) and (aCol=0) and (AnsiContainsstr(GetMN_FileText,GetWallArrIndex(aRow-1).Hash)) ) then
    begin
    ColWidth := (sender as TStringGrid).ColWidths[0];
    Bitmap        := TBitmap.Create;
    Imagenes.GetBitmap(68,Bitmap);
    myRect        := Arect;
    myrect.Left   := ColWidth-20;
    myRect.Right  := ColWidth-4;
    myrect.top    := myrect.Top+2;
    myrect.Bottom := myrect.Top+18;
    (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
    Bitmap.free
    end;
End;

{$ENDREGION Addresses Stringgrid}

{$REGION sendfunds panel}

// Paste on target send funds address
Procedure TForm1.SBSCPasteOnClick(sender:TObject);
Begin
  EditSCDest.SetFocus;
  EditSCDest.Text:=Clipboard.AsText;
  EditSCDest.SelStart:=length(EditSCDest.Text);
End;

// Paste maximum amount on edit
Procedure TForm1.SBSCMaxOnClick(sender:TObject);
Begin
  if not WO_MultiSend then
    begin
    EditSCMont.Text:=Int2curr(GetMaximunToSend(GetWalletBalance))
    end
  else
    begin
    EditSCMont.Text:=Int2Curr(GetMaximunToSend(GetAddressBalanceIndexed(GetWallArrIndex(0).hash)))
    end;
End;

// Validate send funds target
Procedure Tform1.EditSCDestChange(sender:TObject);
Begin
  if EditSCDest.Text = '' then ImgSCDest.Picture.Clear
  else
    begin
    EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
    if ((IsValidHashAddress(EditSCDest.Text)) or (AliasAlreadyExists(EditSCDest.Text))) then
      Form1.imagenes.GetBitmap(17,ImgSCDest.Picture.Bitmap)
    else Form1.imagenes.GetBitmap(14,ImgSCDest.Picture.Bitmap);
    end;
End;

// On send funds amount edit
Procedure TForm1.EditMontoOnKeyUp(sender: TObject; var Key: char);
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
  if EditSCMont.SelStart > length(EditSCMont.Text)-9 then // Decimal
    begin
    Actualmente[currpos+1] := ultimo;
    EditSCMont.Text:=Actualmente;
    EditSCMont.SelStart := currpos+1;
    end;
  if EditSCMont.SelStart <= length(EditSCMont.Text)-9 then // Decimal
    begin
    ParteEntera := copy(actualmente,1,length(Actualmente)-9);
    ParteDecimal := copy(actualmente,length(Actualmente)-7,8);
    if currpos = PosicionEnElPunto then // Just before point
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

// Validate send funds amount
Procedure Tform1.EditSCMontChange(sender:TObject);
Begin
  if ((StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)>0) and
     (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)<=GetMaximunToSend(GetWalletBalance)))then
    begin
    Form1.imagenes.GetBitmap(17,ImgSCMont.Picture.Bitmap);
    end
  else Form1.imagenes.GetBitmap(14,ImgSCMont.Picture.Bitmap);
  if EditSCMont.Text = '0.00000000' then ImgSCMont.Picture.Clear;
End;

// Cancel sendfunds
Procedure Tform1.SCBitCancelOnClick(sender:TObject);
Begin
  EditSCDest.Enabled:=true;
  EditSCMont.Enabled:=true;
  MemoSCCon.Enabled:=true;
  SCBitSend.Visible:=true;
  SCBitConf.Visible:=false;
  SCBitCancel.Visible:=false;
End;

// Accept send funds
Procedure Tform1.SCBitSendOnClick(sender:TObject);
Begin
  if ( ( ((AliasAlreadyExists(EditSCDest.Text)) or (IsValidHashAddress(EditSCDest.Text))) ) and
     (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)>0) and
     (StrToInt64Def(StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase]),-1)<=GetMaximunToSend(GetWalletBalance)) ) then
    begin
    MemoSCCon.Text:=Parameter(MemoSCCon.text,0);
    EditSCDest.Enabled:=false;
    EditSCMont.Enabled:=false;
    MemoSCCon.Enabled:=false;
    SCBitSend.Visible:=false;
    SCBitConf.Visible:=true;
    SCBitCancel.Visible:=true;
    end
  else info('Invalid parameters');
End;

// Process send funds
Procedure Tform1.SCBitConfOnClick(sender:TObject);
Begin
  ProcessLinesAdd('SENDTO '+EditSCDest.Text+' '+
                          StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase])+' '+
                          MemoSCCon.Text);
  ResetSendFundsPanel(sender);
End;

// Clear send funds panel
Procedure TForm1.ResetSendFundsPanel(sender:TObject);
Begin
  EditSCDest.Enabled:=true;EditSCDest.Text:='';
  EditSCMont.Enabled:=true;EditSCMont.Text:='0.00000000';
  MemoSCCon.Enabled:=true;MemoSCCon.Text:='';
  SCBitSend.Visible:=true;
  SCBitConf.Visible:=false;
  SCBitCancel.Visible:=false;
End;

{$ENDREGION sendfunds panel }

//******************************************************************************
// MAINMENU
//******************************************************************************

{$REGION mainmenu}

// Main Menu: Import Wallet
Procedure Tform1.MMImpWallet (sender:TObject);
Begin
  ShowExplorer(GetCurrentDir,'Import Wallet','*.pkw','impwallet (-resultado-)',true);
End;

// Main Menu: Export wallet
Procedure Tform1.MMExpWallet(sender:TObject);
Begin
  ShowExplorer(GetCurrentDir,'Export Wallet to','*.pkw','expwallet (-resultado-)',false);
End;

// menuprincipal restart
Procedure Tform1.MMRestart(sender:TObject);
Begin
ProcessLinesAdd('restart');
End;

// menuprincipal salir
Procedure Tform1.MMQuit(sender:TObject);
Begin
G_CloseRequested := true;
End;

{$ENDREGION mainmenu}

//******************************************************************************
// ConsolePopUp
//******************************************************************************

{$REGION Console popup}

// Validate popup status
Procedure TForm1.CheckConsolePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
  if MemoConsola.Text <> '' then ConsolePopUp2.Items[0].Enabled:= true
  else ConsolePopUp2.Items[0].Enabled:= false;
  if length(Memoconsola.SelText)>0 then ConsolePopUp2.Items[1].Enabled:= true
  else ConsolePopUp2.Items[1].Enabled:= false;
End;

// Clear
Procedure TForm1.ConsolePopUpClear(sender:TObject);
Begin
  ProcessLinesAdd('clear');
End;

// Copy
Procedure TForm1.ConsolePopUpCopy(sender:TObject);
Begin
  Clipboard.AsText:= Memoconsola.SelText;
  info('Copied to clipboard');
End;

{$ENDREGION Console popup}

//******************************************************************************
// CommandLine PopUp
//******************************************************************************

{$REGION command line popup}

// Validate command line popup
Procedure TForm1.CheckConsoLinePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
  if ConsoleLine.Text <> '' then ConsoLinePopUp2.Items[0].Enabled:= true
  else ConsoLinePopUp2.Items[0].Enabled:= false;
  if length(ConsoleLine.SelText)>0 then ConsoLinePopUp2.Items[1].Enabled:= true
  else ConsoLinePopUp2.Items[1].Enabled:= false;
  if length(Clipboard.AsText)>0 then ConsoLinePopUp2.Items[2].Enabled:= true
  else ConsoLinePopUp2.Items[2].Enabled:= false;
End;

// Clear
Procedure TForm1.ConsoLinePopUpClear(sender:TObject);
Begin
  ConsoleLine.Text:='';
  ConsoleLine.Setfocus;
End;

// Copy
Procedure TForm1.ConsoLinePopUpCopy(sender:TObject);
Begin
Clipboard.AsText:= ConsoleLine.SelText;
info('Copied to clipboard');
End;

// Paste
Procedure TForm1.ConsoLinePopUpPaste(sender:TObject);
var
  CurrText : String; Currpos : integer;
Begin
  CurrText := ConsoleLine.Text;
  Currpos := ConsoleLine.SelStart;
  Insert(Clipboard.AsText,CurrText,ConsoleLine.SelStart+1);
  ConsoleLine.Text := CurrText;ConsoleLine.SelStart:=currpos+length(Clipboard.AsText);
  ConsoleLine.Setfocus;
End;

{$ENDREGION command line popup}

//******************************************************************************
// OPTIONS CONTROLS
//******************************************************************************

{$REGION Options: wallet}

// Autoupdate option
procedure TForm1.CB_WO_AutoupdateChange(sender: TObject);
Begin
  if not G_Launching then
    begin
    if CB_WO_Autoupdate.Checked then
      begin
      WO_AutoUpdate := true;
      end
    else
      begin
      WO_AutoUpdate := false ;
      end;
    S_AdvOpt := true;
    end;
  if WO_AutoUpdate then
    begin
    {$IFDEF WINDOWS}
    if ( (not fileexists('libeay32.dll')) or (not fileexists('ssleay32.dll')) ) then
      ToLog('console','Warning: SSL files missed. Auto directive update will not work properly');
    {$ENDIF}
    end
  else
    begin
    ToLog('console','Auto-update option is disabled. This could cause your node to become inactive on mandatory updates.');
    end;
End;

// Send from multiple addresses
procedure TForm1.CB_WO_MultisendChange(sender: TObject);
Begin
  if not G_Launching then
    begin
    if CB_WO_Multisend.Checked then WO_Multisend := true
    else WO_Multisend := false ;
    S_AdvOpt := true;
    end;
End;

// hide empty addresses
procedure TForm1.CB_WO_HideEmptyChange(Sender: TObject);
Begin
  if not G_Launching then
    begin
    if CB_WO_HideEmpty.Checked then WO_HideEmpty := true
    else WO_HideEmpty := false ;
    S_AdvOpt := true;
    U_DirPanel:= true;
    end;
End;

// Options Wallet: Keep blocks Database
procedure TForm1.CBKeepBlocksDBChange(Sender: TObject);
Begin
  if not G_Launching then
    begin
    if CBKeepBlocksDB.Checked then WO_BlockDB := true
    else WO_BlockDB := false;
    end;
End;

// Options Wallet: Stop GUI
procedure TForm1.CBRunNodeAloneChange(sender: TObject);
Begin
  if not G_Launching then
    begin
    if CBRunNodeAlone.Checked then WO_StopGUI := true
    else WO_StopGUI := false;
    end;
End;

// Options Wallet: Send reports
procedure TForm1.CBSendReportsChange(Sender: TObject);
Begin
  if not G_Launching then
    begin
    if CBSendReports.Checked then WO_SendReport := true
    else WO_SendReport := false;
    end;
End;

{$ENDREGION Options: wallet}

{$REGION Options: Node}

// Load Masternode options when TAB is selected
procedure TForm1.TabNodeOptionsShow(sender: TObject);
Begin
  CBAutoIP.checked:=MN_AutoIP;
  CheckBox4.Checked:=WO_AutoServer;
  LabeledEdit5.Text:=LocalMN_IP;
  //LabeledEdit5.visible:=not MN_AutoIP;
  LabeledEdit6.Text:=LocalMN_Port;
  LabeledEdit8.Text:=LocalMN_Funds;
  LabeledEdit9.Text:=LocalMN_Sign;
End;

// Save Node options
procedure TForm1.BSaveNodeOptionsClick(sender: TObject);
Begin
  WO_AutoServer :=CheckBox4.Checked;
  LocalMN_IP         :=Trim(LabeledEdit5.Text);
  LocalMN_Port       :=Trim(LabeledEdit6.Text);
  LocalMN_Funds      :=Trim(LabeledEdit8.Text);
  LocalMN_Sign       :=Trim(LabeledEdit9.Text);
  MN_AutoIP          :=CBAutoIP.Checked;
  LastTimeReportMyMN := 0;
  S_AdvOpt := true;
  if not WO_AutoServer and form1.Server.Active then processlinesadd('serveroff');
  if WO_AutoServer and not form1.Server.Active then processlinesadd('serveron');
  info('Masternode options saved');
End;

// Test master node configuration
procedure TForm1.BTestNodeClick(sender: TObject);
var
  Client : TidTCPClient;
  LineResult : String = '';
  ServerActivated : boolean = false;
  IPToUse : String;
Begin
  if WallAddIndex(LabeledEdit9.Text) < 0 then
    begin
    info(rs0081); // Invalid sign address
    exit;
    end;
  if GetAddressBalanceIndexed(LabeledEdit8.Text) < GetStackRequired(MylastBlock) then
    begin
    info(rs0082); // Funds address do not owns enough coins
    exit;
    end;
  if form1.Server.Active then
    begin
    info(rs0080);   //You can not test while server is active
    exit;
    end;
  if MyConStatus < 3 then
    begin
    info(rs0083);   //You need update the wallet
    exit;
    end;
  TRY
  form1.Server.Active := true;
  ServerActivated := true;
  EXCEPT on E:Exception do
    begin
    info('Error activating server: '+E.Message);
    exit;
    end;
  END;{Try}
  LineResult := '';
  Client := TidTCPClient.Create(nil);
  if CBAutoIP.Checked then IPToUse:= GetMiIp()
  else IPToUse := trim(LabeledEdit5.text);
  Client.Host:= IPToUse;
  Client.Port:= StrToIntDef(Trim(LabeledEdit6.Text),8080);
  Client.ConnectTimeout:= 1000;
  Client.ReadTimeout:= 1000;
  TRY
  Client.Connect;
  Client.IOHandler.WriteLn('NODESTATUS');
  LineResult := Client.IOHandler.ReadLn(IndyTextEncoding_UTF8);
  EXCEPT on E:Exception do
    begin
    info('Cant connect to '+IPToUse);
    client.Free;
    if ServerActivated then form1.Server.Active := false;
    exit;
    end;
  END;{Try}
  if LineResult <> '' then info(IPToUse+': OK')
  else info ('Test Failed: '+IPToUse);
  if client.Connected then Client.Disconnect();
  if ServerActivated then form1.Server.Active := false;
  client.Free;
End;

{$ENDREGION Options: Node}

{$REGION Options: RPC}

// Enable/Disable RPC
procedure TForm1.CB_AUTORPCChange(sender: TObject);
Begin
  if not G_Launching then
    begin
    RPCAuto:= CB_AUTORPC.Checked;
    S_AdvOpt := true;
    end;
End;

// Edit RPC port
procedure TForm1.LE_Rpc_PortEditingDone(sender: TObject);
Begin
  if StrToIntDef(LE_Rpc_Port.Text,-1) <> RPCPort then
    begin
    SetRPCPort('SETRPCPORT '+LE_Rpc_Port.Text);
    LE_Rpc_Port.Text := IntToStr(RPCPort);
    S_AdvOpt := true;
    info ('New RPC port set');
    end;
End;

// Edit RPC password
procedure TForm1.LE_Rpc_PassEditingDone(sender: TObject);
Begin
  if ((not G_Launching) and (LE_Rpc_Pass.Text<>RPCPass)) then
    begin
    setRPCpassword(LE_Rpc_Pass.Text);
    LE_Rpc_Pass.Text:=RPCPass;
    S_AdvOpt := true;
    info ('New RPC password set');
    end;
End;

// Enable RPC filter
procedure TForm1.CB_RPCFilterChange(sender: TObject);
Begin
  if not G_Launching then
    begin
    if CB_RPCFilter.Checked then
      begin
      RPCFilter := true;
      MemoRPCWhitelist.Enabled:=true;
      end
    else
      begin
      RPCFilter := false;
      MemoRPCWhitelist.Enabled:=false;
      end;
    S_AdvOpt := true;
    end;
End;

// Backup RPC created addresses (to be deprecated, always enable)
procedure TForm1.CB_BACKRPCaddressesChange(Sender: TObject);
Begin
  if not G_Launching then
    begin
    if CB_BACKRPCaddresses.Checked then RPCSaveNew := true
    else RPCSaveNew := false;
    end;
End;

// Set MN IP to Auto
procedure TForm1.CBAutoIPClick(sender: TObject);
var
  MyIP : string;
Begin
  if CBAutoIP.Checked then
    begin
    MyIP := GetMiIP();
      begin
      LabeledEdit5.Caption:=MyIP;
      if  MyIP <> LocalMN_IP then
        begin
        LocalMN_IP := MyIP;
        S_AdvOpt := true;
        end
      end;
    end;
  //LabeledEdit5.Visible:=false
  //else LabeledEdit5.Visible:=true;
End;

// Editing RPC filter memo
procedure TForm1.MemoRPCWhitelistEditingDone(sender: TObject);
var
  newlist : string;
Begin
  if ( (not G_Launching) and (MemoRPCWhitelist.Text<>RPCWhitelist) ) then
    begin
    newlist := trim(MemoRPCWhitelist.Text);
    newlist := parameter(newlist,0);
    MemoRPCWhitelist.Text := newlist;
    RPCWhitelist := newlist;
    S_AdvOpt := true;
    end;
End;

// Editing RPC banned memo
procedure TForm1.MemobannedmethodsEditingDone(Sender: TObject);
var
  newlist : string;
Begin
  if ( (not G_Launching) and (Memobannedmethods.Text<>RPCBanned) ) then
    begin
    newlist := trim(Memobannedmethods.Text);
    newlist := parameter(newlist,0);
    Memobannedmethods.Text := newlist;
    RPCBanned := newlist;
    S_AdvOpt := true;
    end;
End;

{$ENDREGION Options: RPC}

{$REGION Options: About}

 // Button: Options -> About -> donate
procedure TForm1.BitBtnDonateClick(sender: TObject);
Begin
  form1.PageMain.ActivePage := form1.TabWallet;
  form1.TabWalletMain.ActivePage := form1.TabAddresses;
  PanelSend.Visible:=true;
  Form1.EditSCDest.Text:='NpryectdevepmentfundsGE';
  Form1.EditSCMont.Text:=IntToStr(DefaultDonation)+'.00000000';
  Form1.MemoSCCon.Text:='Donation';
End;

// Button: Options -> About -> web
Procedure TForm1.BitBtnWebClick(sender: TObject);
Begin
  OpenDocument('https://nosocoin.com');
End;

{$ENDREGION Options: About}

END. // END PROGRAM

