unit MasterPaskalForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLType,
  Grids, ExtCtrls, Buttons, IdTCPServer, IdContext, IdGlobal, IdTCPClient,
  fileutil, Clipbrd, Menus, formexplore, lclintf, ComCtrls, Spin,
  strutils, math, IdHTTPServer, IdCustomHTTPServer,
  IdHTTP, fpJSON, Types, DefaultTranslator, LCLTranslator, translation, nosodebug,
  ubarcodes, IdComponent;

type

   { TThreadClientRead }

  TNodeConnectionInfo = class(TObject)
  private
    FTimeLast: Int64;
  public
    constructor Create;
    property TimeLast: int64 read FTimeLast write FTimeLast;
  end;

  TServerTipo = class(TObject)
  private
    VSlot: integer;
  public
    constructor Create;
    property Slot: integer read VSlot write VSlot;
  end;

  TThreadClientRead = class(TThread)
   private
     FSlot: Integer;
   protected
     procedure Execute; override;
   public
     constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
   end;

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
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
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
     Hash : String[40];    // El hash publico o direccion
     Custom : String[40];  // En caso de que la direccion este personalizada
     Balance : int64;      // el ultimo saldo conocido de la direccion
     Score : int64;        // estado del registro de la direccion.
     LastOP : int64;       // tiempo de la ultima operacion en UnixTime.
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
     Reference : String[64];
       TrxLine : integer;
       sender : String[120];    // La clave publica de quien envia
       Address : String[40];
       Receiver : String[40];
       AmmountFee : Int64;
       AmmountTrf : Int64;
       Signature : String[120];
       TrfrID : String[64];
     end;

    TOrderGroup = Packed Record
     Block      : integer;
     TimeStamp  : Int64;
     OrderID    : string[64];
     OrderType  : String[6];
     OrderLines : Integer;
     Reference  : String[64];
     sender     : string;
     Receiver   : String[40];
     AmmountFee : Int64;
     AmmountTrf : Int64;
     end;

  NetworkData = Packed Record
     Value : String[64];   // el valor almacenado
     Porcentaje : integer; // porcentaje de peers que tienen el valor
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

  BlockOrdersArray = Array of OrderData;

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

  TMNCheck = Record
       ValidatorIP  : string;      // Validator IP
       Block        : integer;
       SignAddress  : string;
       PubKey       : string;
       ValidNodes   : string;
       Signature    : string;
       end;

  TArrayCriptoOp = Packed record
       tipo: integer;
       data: string;
       result: string;
       end;

  TNMSData = Packed Record
       Diff   : string;
       Hash   : String;
       Miner  : String;
       TStamp : string;
       Pkey   : string;
       Signat : string;
       end;

  TMNsData  = Packed Record
       ipandport  : string;
       address    : string;
       age        : integer;
       end;

  TGVT = packed record
       number   : string[2];
       owner    : string[32];
       Hash     : string[64];
       control  : integer;
       end;

  TBlockSumTrfr = packed record
       address  : string[32];
       amount   : int64;
       score    : int64;
       end;

  TNosoCFG = packed record
       NetStatus : string;
       SeedNode  : string;
       NTPNodes  : string;
       Pools     : string;
       end;

  { TForm1 }

  TForm1 = class(TForm)
    BarcodeQR1: TBarcodeQR;
    BQRCode: TSpeedButton;
    BitBtnDonate: TBitBtn;
    BitBtnWeb: TBitBtn;
    BSaveNodeOptions: TBitBtn;
    BitBtnPending: TBitBtn;
    BitBtnBlocks: TBitBtn;
    BTestNode: TBitBtn;
    ButStartDoctor: TButton;
    ButStopDoctor: TButton;
    Button1: TButton;
    Button2: TButton;
    CB_WO_Autoupdate: TCheckBox;
    CBBlockexists: TCheckBox;
    CBBlockhash: TCheckBox;
    CBSummaryhash: TCheckBox;
    CBAutoIP: TCheckBox;
    CB_Currentjob: TCheckBox;
    CBRunNodeAlone: TCheckBox;
    ComboBoxLang: TComboBox;
    Edit2: TEdit;
    Label14: TLabel;
    Label15: TLabel;
    LabelNodesHash: TLabel;
    LabelDoctor: TLabel;
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
    Label1: TLabel;
    Label7: TLabel;
    MemoDoctor: TMemo;
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
    Panel22: TPanel;
    Panel23: TPanel;
    PanelTransferGVT: TPanel;
    PanelNodesHeaders: TPanel;
    PanelDoctor: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    Panel9: TPanel;
    PanelQRImg: TPanel;
    PanelPostOffer: TPanel;
    SCBitSend1: TBitBtn;
    SpeedButton2: TSpeedButton;
    SpeedButton3: TSpeedButton;
    SpinDoctor1: TSpinEdit;
    SpinDoctor2: TSpinEdit;
    StaRPCimg: TImage;
    StaSerImg: TImage;
    StaConLab: TLabel;
    Imgs32: TImageList;
    ImgRotor: TImage;
    GridNodes: TStringGrid;
    GVTsGrid: TStringGrid;
    TabDoctor: TTabSheet;
    TabGVTs: TTabSheet;
    TextQRcode: TStaticText;
    StaTimeLab: TLabel;
    SCBitSend: TBitBtn;
    SCBitClea: TBitBtn;
    CB_AUTORPC: TCheckBox;
    CB_WO_AutoConnect: TCheckBox;
    CB_WO_ToTray: TCheckBox;
    CB_FullNode: TCheckBox;
    CB_WO_Multisend: TCheckBox;
    CB_WO_AntiFreeze: TCheckBox;
    CheckBox4: TCheckBox;
    CB_RPC_ON: TCheckBox;
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
    LAbelTransactionDetails: TLabel;
    LabelNobiexLast: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    LabAbout: TLabel;
    LabelNobiexAverage: TLabel;
    LabelBigBalance: TLabel;
    Latido : TTimer;
    InfoTimer : TTimer;
    InicioTimer : TTimer;
    ConnectButton: TSpeedButton;
    MainMenu: TMainMenu;
    MemoSCCon: TMemo;
    MemoTrxDetails: TMemo;
    MemoConsola: TMemo;
    DataPanel: TStringGrid;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem23: TMenuItem;
    MenuItem24: TMenuItem;
    MenuItem25: TMenuItem;
    MenuItem26: TMenuItem;
    MenuItem27: TMenuItem;
    MenuItem3: TMenuItem;
    MenuItem4: TMenuItem;
    MenuItem5: TMenuItem;
    MenuItem6: TMenuItem;
    MenuItem7: TMenuItem;
    MenuItem8: TMenuItem;
    MenuItem9: TMenuItem;
    DireccionesPanel: TStringGrid;
    InfoPanel: TPanel;
    PanelCustom: TPanel;
    PanelPoSMNs: TPanel;
    PanelTrxDetails: TPanel;
    PanelSend: TPanel;
    GridMyTxs: TStringGrid;
    ConsolePopUp2: TPopupMenu;
    ConsoLinePopUp2: TPopupMenu;
    SCBitCancel: TBitBtn;
    SCBitConf: TBitBtn;
    SpeedButton1: TSpeedButton;
    BDefAddr: TSpeedButton;
    BCustomAddr: TSpeedButton;
    GridPoS: TStringGrid;
    BCopyAddr: TSpeedButton;
    BNewAddr: TSpeedButton;
    BOkCustom: TSpeedButton;
    SGridSC: TStringGrid;
    SBSCPaste: TSpeedButton;
    SBSCMax: TSpeedButton;
    TabAddresses: TTabSheet;
    TabHistory: TTabSheet;
    TabNodes: TTabSheet;
    TabWalletMain: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    PanelNobiex: TPanel;
    TopPanel: TPanel;
    StatusPanel: TPanel;
    RestartTimer : Ttimer;
    MemoRPCWhitelist: TMemo;
    Memo2: TMemo;
    MemoLog: TMemo;
    MemoExceptLog: TMemo;
    PageControl1: TPageControl;
    PageControl2: TPageControl;
    PCMonitor: TPageControl;
    PageMain: TPageControl;
    Server: TIdTCPServer;
    {PoolServer : TIdTCPServer;}
    RPCServer : TIdHTTPServer;
    SE_WO_AntifreezeTime: TSpinEdit;
    SE_WO_RTOT: TSpinEdit;
    SE_WO_MinPeers: TSpinEdit;
    SE_WO_CTOT: TSpinEdit;
    SE_WO_ShowOrders: TSpinEdit;
    SE_WO_PosWarning: TSpinEdit;
    SG_Monitor: TStringGrid;
    GridExLTC: TStringGrid;
    SystrayIcon: TTrayIcon;
    tabOptions: TTabSheet;
    TabOpt_Wallet: TTabSheet;
    TabSheet10: TTabSheet;
    TabNodeOptions: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet5: TTabSheet;
    TabExchange: TTabSheet;
    TabMonitor: TTabSheet;
    tabExBuy: TTabSheet;
    TabDebug_Log: TTabSheet;
    TabSheet8: TTabSheet;
    TabMonitorMonitor: TTabSheet;
    TabSheet9: TTabSheet;
    TabWallet: TTabSheet;
    TabConsole: TTabSheet;

    procedure BarcodeQR1Click(sender: TObject);
    procedure BitBtnDonateClick(sender: TObject);
    procedure BitBtnWebClick(sender: TObject);
    procedure BQRCodeClick(sender: TObject);
    procedure BSaveNodeOptionsClick(sender: TObject);
    procedure BTestNodeClick(sender: TObject);
    procedure ButStartDoctorClick(sender: TObject);
    procedure ButStopDoctorClick(sender: TObject);
    procedure Button1Click(sender: TObject);
    procedure Button2Click(sender: TObject);
    procedure CBRunNodeAloneChange(sender: TObject);
    procedure CB_CurrentjobChange(sender: TObject);
    procedure CB_RPCFilterChange(sender: TObject);
    procedure CB_WO_AutoupdateChange(sender: TObject);
    procedure CBAutoIPClick(sender: TObject);
    procedure CB_FullNodeChange(sender: TObject);
    procedure ComboBoxLangChange(sender: TObject);
    procedure ComboBoxLangDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DataPanelResize(sender: TObject);
    procedure DireccionesPanelDrawCell(sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DireccionesPanelResize(sender: TObject);
    procedure FormCloseQuery(sender: TObject; var CanClose: boolean);
    procedure FormCreate(sender: TObject);
    procedure FormDestroy(sender: TObject);
    procedure FormResize(sender: TObject);
    procedure FormWindowStateChange(sender: TObject);
    procedure GridMyTxsResize(sender: TObject);
    procedure GridMyTxsSelection(sender: TObject; aCol, aRow: Integer);
    procedure GridNodesResize(sender: TObject);
    procedure GridPoSResize(sender: TObject);
    procedure GVTsGridResize(sender: TObject);
    procedure LE_Rpc_PassEditingDone(sender: TObject);
    Procedure LoadOptionsToPanel();
    procedure FormShow(sender: TObject);
    Procedure InicoTimerEjecutar(sender: TObject);
    procedure MemoRPCWhitelistEditingDone(sender: TObject);
    Procedure RestartTimerEjecutar(sender: TObject);
    Procedure EjecutarInicio();
    Procedure ConsoleLineKeyup(sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Grid1PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    procedure Grid2PrepareCanvas(sender: TObject; aCol, aRow: Integer; aState: TGridDrawState);
    Procedure GridMyTxsPrepareCanvas(sender: TObject; aCol, aRow: Integer;aState: TGridDrawState);
    Procedure LatidoEjecutar(sender: TObject);
    Procedure InfoTimerEnd(sender: TObject);
    function  ClientsCount : Integer ;
    procedure SCBitSend1Click(sender: TObject);
    procedure SE_WO_AntifreezeTimeChange(sender: TObject);
    procedure GridExLTCResize(sender: TObject);
    procedure SG_MonitorResize(sender: TObject);
    procedure SpeedButton2Click(sender: TObject);
    procedure SpeedButton3Click(sender: TObject);
    procedure StaConLabDblClick(sender: TObject);
    procedure TabHistoryShow(sender: TObject);
    procedure TabNodeOptionsShow(sender: TObject);
    procedure TabSheet9Resize(sender: TObject);
    Procedure TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
    Procedure DoubleClickSysTray(sender: TObject);
    Procedure ConnectCircleOnClick(sender: TObject);
    Procedure GridMyTxsOnDoubleClick(sender: TObject);
    Procedure BitPosInfoOnClick (sender: TObject);
    Procedure BDefAddrOnClick(sender: TObject);
    Procedure BCustomAddrOnClick(sender: TObject);
    Procedure EditCustomKeyUp(sender: TObject; var Key: Word; Shift: TShiftState);
    Procedure BOkCustomClick(sender: TObject);
    Procedure PanelCustomMouseLeave(sender: TObject);
    Procedure BNewAddrOnClick(sender: TObject);
    Procedure BCopyAddrClick(sender: TObject);
    Procedure CheckForHint(sender:TObject);
    Procedure BSendCoinsClick(sender: TObject);
    Procedure BCLoseSendOnClick(sender: TObject);
    Procedure SBSCPasteOnClick(sender:TObject);
    Procedure SBSCMaxOnClick(sender:TObject);
    Procedure EditSCDestChange(sender:TObject);
    Procedure EditSCMontChange(sender:TObject);
    Procedure DisablePopUpMenu(sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure EditMontoOnKeyUp(sender: TObject; var Key: char);
    Procedure SCBitSendOnClick(sender:TObject);
    Procedure SCBitCancelOnClick(sender:TObject);
    Procedure SCBitConfOnClick(sender:TObject);
    Procedure ResetearValoresEnvio(sender:TObject);
    Procedure CheckClipboardForPays();

    // NODE SERVER
    Function TryMessageToNode(AContext: TIdContext;message:string):boolean;

    // RPC
    procedure RPCServerExecute(AContext: TIdContext;
      ARequestInfo: TIdHTTPRequestInfo; AResponseInfo: TIdHTTPResponseInfo);

    // MAIN MENU
    Procedure CheckMMCaptions(sender:TObject);
    Procedure MMConnect(sender:TObject);
    Procedure MMImpWallet(sender:TObject);
    Procedure MMExpWallet(sender:TObject);
    Procedure MMQuit(sender:TObject);
    Procedure MMRestart(sender:TObject);
    Procedure MMVerWeb(sender:TObject);
    Procedure MMVerSlots(sender:TObject);

    // CONSOLE POPUP
    Procedure CheckConsolePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure ConsolePopUpClear(sender:TObject);
    Procedure ConsolePopUpCopy(sender:TObject);

    // CONSOLE LINE POPUP
    Procedure CheckConsoLinePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure ConsoLinePopUpClear(sender:TObject);
    Procedure ConsoLinePopUpCopy(sender:TObject);
    Procedure ConsoLinePopUpPaste(sender:TObject);

    // TRXDETAILS POPUP
    Procedure TrxDetailsPopUpCopyOrder(sender:TObject);


    // OPTIONS
      // WALLET
    procedure CB_WO_AutoConnectChange(sender: TObject);
    procedure CB_WO_ToTrayChange(sender: TObject);
    procedure SE_WO_MinPeersChange(sender: TObject);
    procedure SE_WO_CTOTChange(sender: TObject);
    procedure SE_WO_RTOTChange(sender: TObject);
    procedure SE_WO_ShowOrdersChange(sender: TObject);
    procedure SE_WO_PosWarningChange(sender: TObject);
    procedure CB_WO_AntiFreezeChange(sender: TObject);
    procedure CB_WO_MultisendChange(sender: TObject);
      // RPC
    procedure CB_RPC_ONChange(sender: TObject);
    procedure CB_AUTORPCChange(sender: TObject);
    procedure LE_Rpc_PortEditingDone(sender: TObject);

  private

  public

  end;

Procedure InicializarFormulario();
Procedure CerrarPrograma();
Procedure UpdateStatusBar();
Procedure GenerateCode();
Procedure CompleteInicio();
Procedure UpdateMyGVTsList();


CONST
  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  ReservedWords : string = 'NULL,DELADDR';
  ValidProtocolCommands : string = '$PING$PONG$GETPENDING$NEWBL$GETRESUMEN$LASTBLOCK$GETCHECKS'+
                                   '$CUSTOMORDERADMINMSGNETREQ$REPORTNODE$GETMNS$BESTHASH$MNREPO$MNCHECK'+
                                   'GETMNSFILEMNFILEGETHEADUPDATE$GETSUMARY$GETGVTSGVTSFILE$SNDGVTGETCFGDATA'+
                                   'SETCFGDATA';
  HideCommands : String = 'CLEAR SENDPOOLSOLUTION SENDPOOLSTEPS';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';

  DefaultNosoCFG : String = 'NORMAL '+
                            '47.87.181.190;8080:47.87.178.205;8080:81.22.38.101;8080:66.151.117.247;8080:47.87.180.219;8080:47.87.137.96;8080:192.3.85.196;8080:192.3.254.186;8080:101.100.138.125;8080:198.46.218.125;8080:63.227.69.162;8080: '+
                            'ts2.aco.net:hora.roa.es:time.esa.int:time.stdtime.gov.tw:stratum-1.sjc02.svwh.net:ntp1.sp.se:1.de.pool.ntp.org:ntps1.pads.ufrj.br:utcnist2.colorado.edu:tick.usask.ca:ntp1.st.keio.ac.jp: '+
                            'N3ESwXxCAR4jw3GVHgmKiX9zx1ojWEf:N2ophUoAzJw9LtgXbYMiB4u5jWWGJF7:N3aXz2RGwj8LAZgtgyyXNRkfQ1EMnFC:N2MVecGnXGHpN8z4RqwJFXSQP6doVDv: '+
                            'nosofish.xyz;8082:nosopool.estripa.online;8082:pool.nosomn.com;8082:159.196.1.198;8082:';

  ProgramVersion = '0.3.3';
  {$IFDEF WINDOWS}
  RestartFileName = 'launcher.bat';
  updateextension = 'zip';
  {$ENDIF}
  {$IFDEF UNIX}
  RestartFileName = 'launcher.sh';
  updateextension = 'tgz';
  {$ENDIF}
  SubVersion = 'Aa1';
  OficialRelease = false;
  VersionRequired = '0.3.3Aa1';
  BuildDate = 'December 2022';
  ADMINHash = 'N4PeJyqj8diSXnfhxSQdLpo8ddXTaGd';
  AdminPubKey = 'BL17ZOMYGHMUIUpKQWM+3tXKbcXF0F+kd4QstrB0X7iWvWdOSrlJvTPLQufc1Rkxl6JpKKj/KSHpOEBK+6ukFK4=';
  DefaultServerPort = 8080;
  MaxConecciones  = 99;
  Protocolo = 2;
  DefaultDonation = 10;
  // Custom values for coin
  SecondsPerBlock = 600;            // 10 minutes
  PremineAmount = 1030390730000;    // 1030390730000;
  InitialReward = 5000000000;       // Initial reward
  BlockHalvingInterval = 210000;    // 210000;
  HalvingSteps = 10;                // total number of halvings
  Comisiontrfr = 10000;             // ammount/Comisiontrfr = 0.01 % of the ammount
  ComisionCustom = 200000;          // 0.05 % of the Initial reward
  CoinSimbol = 'NOSO';               // Coin symbol
  CoinName = 'Noso';                // Coin name
  CoinChar = 'N';                   // Char for addresses
  MinimunFee = 10;                  // Minimun fee for transfer
  ComisionBlockCheck = 0;           // +- 90 days
  DeadAddressFee = 0;               // unactive acount fee
  ComisionScrow = 200;              // Coin/BTC market comision = 0.5%
  PoSPercentage = 1000;             // PoS part: reward * PoS / 10000
  MNsPercentage = 2000;
  PosStackCoins = 20;               // PoS stack ammoount: supply*20 / PoSStack
  PoSBlockStart : integer = 8425;   // first block with PoSPayment
  MNBlockStart  : integer = 48010;  // First block with MNpayments
  InitialBlockDiff = 60;            // Dificultad durante los 20 primeros bloques
  GenesysTimeStamp = 1615132800;    // 1615132800;
  AvailableMarkets = '/LTC';
  SendDirectToPeer = false;
  SumMarkInterval  = 100;
  SecurityBlocks   = 4000;

var
  PoolAddressesList:string = 'N3ESwXxCAR4jw3GVHgmKiX9zx1ojWEf N2ophUoAzJw9LtgXbYMiB4u5jWWGJF7 '+
    'N3aXz2RGwj8LAZgtgyyXNRkfQ1EMnFC N2MVecGnXGHpN8z4RqwJFXSQP6doVDv';

  LockedAddresses : string = 'NpryectdevepmentfundsGE';

  UserFontSize : integer = 8;
  UserRowHeigth : integer = 22;
  ReadTimeOutTIme : integer = 1000;
  ConnectTimeOutTime : integer = 1000;
  RPCPort : integer = 8078;
  RPCPass : string = 'default';
  ShowedOrders : integer = 100;
  MaxPeersAllow : integer = 50;
  WO_AutoConnect   : boolean = false;
  WO_AutoServer    : boolean = false;
  WO_ToTray        : boolean = false;
  MinConexToWork   : integer = 1;
  WO_PosWarning    : int64 = 7;
  WO_AntiFreeze    : boolean = true;
  WO_MultiSend     : boolean = false;
  WO_AntifreezeTime: integer = 10;
  WO_Language      : string = 'en';
    WO_LastPoUpdate: string = ProgramVersion+Subversion;
  WO_CloseStart    : boolean = true;
  WO_AutoUpdate    : Boolean = true;
    UpdateFileSize : int64 = 0;
    FirstTimeUpChe : boolean = true;
  WO_OmmitMemos    : boolean = false;
  RPCFilter        : boolean = true;
  RPCWhitelist     : string = '127.0.0.1,localhost';
  RPCAuto          : boolean = false;
  MN_IP            : string = 'localhost';
  MN_Port          : string = '8080';
  MN_Funds         : string = '';
  MN_Sign          : string = '';
  MN_AutoIP        : Boolean = false;
  MN_FileText      : String = '';
  WO_FullNode      : boolean = true;

  ConnectedRotor : integer = 0;
  EngineLastUpdate : int64 = 0;
  StopDoctor : boolean = false;

  SendOutMsgsThread : TThreadSendOutMsjs;

  ThreadMNs : TUpdateMNs;
  CryptoThread : TCryptoThread;
  UpdateLogsThread : TUpdateLogs;
  LastLogLine      : String = '';

  MaxOutgoingConnections : integer = 3;
  FirstShow : boolean = false;
  RunningDoctor : boolean = false;

  G_PoSPayouts, G_PoSEarnings : int64;
  G_MNsPayouts, G_MNsEarnings : int64;


  RunDoctorBeforeClose : boolean = false;
  RestartNosoAfterQuit : boolean = false;
  ConsensoValues : integer = 0;
  RebuildingSumary : boolean = false;
  MyCurrentBalance : Int64 = 0;
  Customizationfee : int64 = InitialReward div ComisionCustom;
  MsgsReceived : string = '';
  G_Launching : boolean = true;   // Indica si el programa se esta iniciando
  G_CloseRequested : boolean = false;
  G_LastPing  : int64;            // El segundo del ultimo ping
  G_TotalPings : Int64 = 0;
  G_ClosingAPP : Boolean = false;
  Form1: TForm1;
  LastCommand : string = '';
  ProcessLines : TStringlist;
  LogLines : TStringList;
    S_Log : boolean = false;
  ExceptLines : TStringList;
    S_Exc : boolean = false;
  StringAvailableUpdates : String = '';
    U_DataPanel : boolean = true;
    U_PoSGrid : Boolean = true;

  ArrayOrderIDsProcessed : array of string;

    U_DirPanel : boolean = false;
  FileBotData : File of BotData;
    S_BotData : Boolean = false;
  LastBotClear: string = '';
  FileWallet : file of WalletData;
    S_Wallet : boolean = false;
  FileSumario : file of SumarioData;
    S_Sumario : boolean = false;
  FileResumen : file of ResumenData;
    S_Resumen : Boolean = false;

  FileGVTs    : file of TGVT;
  ArrGVTs     : array of TGVT;

  FileAdvOptions : textfile;
    S_AdvOpt : boolean = false;
  PoolTotalHashRate : int64 = 0;

  CurrentJob : String = '';
  NosoCFGStr : String = '';
  ForcedQuit : boolean = false;
  NewLogLines : integer = 0;
  Conexiones : array [1..MaxConecciones] of conectiondata;
  SlotLines : array [1..MaxConecciones] of TStringList;
  CanalCliente : array [1..MaxConecciones] of TIdTCPClient;

  ListadoBots      :  array of BotData;
  ListaNodos       : array of NodeData;
  ListaDirecciones : array of walletData; // Wallet addresses
  ListaSumario     : array of SumarioData;    // Sumary addresses
  PendingTXs       : Array of OrderData;
  OutgoingMsjs     : TStringlist;
  ArrayConsenso    : array of NetworkData;

  // Variables asociadas a la red
  KeepServerOn : Boolean = false;
     LastTryServerOn : Int64 = 0;
     ServerStartTime : Int64 = 0;
  DownloadHeaders : boolean = false;
  DownloadSumary  : Boolean = false;
  DownLoadBlocks  : boolean = false;
  DownLoadGVTs    : boolean = false;
  CONNECT_LastTime : string = ''; // La ultima vez que se intento una conexion
  CONNECT_Try : boolean = false;
  MySumarioHash : String = '';
  MyLastBlock : integer = 0;
  MyLastBlockHash : String = '';
  MyResumenHash : String = '';
  MyGVTsHash    : string = '';
  MyCFGHash     : string = '';
  MyPublicIP : String = '';
  OpenReadClientThreads : integer = 0;
  BlockUndoneTime    : int64 = 0;


  MyMNsHash : String = '';
  ArrayMNsData  : array of TMNsData;


  LastTimeReportMyMN : int64 = 0;
  MyMNsCount : integer = 0;

  LastBlockData : BlockHeaderData;
  BuildingBlock : integer = 0;
  MNsArray   : array of TMasterNode;
  WaitingMNs : array of String;
   U_MNsGrid : boolean = false;
   U_MNsGrid_Last : int64 = 0;

  MNsList   : array of TMnode;
  ArrMNChecks : array of TMNCheck;
  MNsRandomWait : Integer= 0;

  Last_ActualizarseConLaRed : int64 = 0;
  NetSumarioHash : NetworkData;
    SumaryRebuilded : boolean = false;
    LastTimeRequestSumary  : int64 = 0;
  NetLastBlock : NetworkData;
    LastTimeRequestBlock : int64 = 0;
  NetLastBlockHash : NetworkData;
  NetPendingTrxs : NetworkData;
  NetResumenHash : NetworkData;
    LastTimeRequestResumen : int64 = 0;
    LastTimePendingRequested : int64 = 0;
    ForceCompleteHeadersDownload : boolean = false;
  NetMNsHash     : NetworkData;
    LastTimeMNHashRequestes : int64 = 0;
  NetMNsCount    : NetworkData;
  NetBestHash    : NetworkData;
    LastTimeBestHashRequested : int64 = 0;
    LastTimeMNsRequested   : int64 = 0;
  NetMNsChecks   : NetworkData;
    LastTimeChecksRequested : int64 = 0;
  LastRunMNVerification : int64 = 0;
  // Variables asociadas a mi conexion
  MyConStatus          :  integer = 0;
  STATUS_Connected     : boolean = false;
  NetGVTSHash          : NetworkData;
    LasTimeGVTsRequest : int64 = 0;
  NetCFGHash           : NetworkData;
    LasTimeCFGRequest  : int64 = 0;

  NMSData : TNMSData;
  BuildNMSBlock : int64 = 0;

  // Threads
  RebulidTrxThread : TThreadID;
  CriptoOPsThread : TThreadID;
    CriptoThreadRunning : boolean = false;

  ArrayCriptoOp : array of TArrayCriptoOp;

  // Critical Sections
  CSProcessLines: TRTLCriticalSection;
  CSOutgoingMsjs: TRTLCriticalSection;
  CSHeadAccess  : TRTLCriticalSection;
  CSBlocksAccess: TRTLCriticalSection;
  CSSumary      : TRTLCriticalSection;
  CSPending     : TRTLCriticalSection;
  CSCriptoThread: TRTLCriticalSection;
  CSLogLines    : TRTLCriticalSection;
  CSExcLogLines : TRTLCriticalSection;
  CSClosingApp  : TRTLCriticalSection;
  CSNMSData     : TRTLCriticalSection;
  CSCurrentJob  : TRTLCriticalSection;
  CSClientReads : TRTLCriticalSection;
  CSGVTsArray   : TRTLCriticalSection;
  CSNosoCFGStr  : TRTLCriticalSection;

  // old system
  CSMNsArray    : TRTLCriticalSection;
  CSWaitingMNs  : TRTLCriticalSection;
  //new MNs system
  CSMNsList     : TRTLCriticalSection;
  CSMNsChecks   : TRTLCriticalSection;

  CSIdsProcessed: TRTLCriticalSection;
  // Server handling
  CSNodesList   : TRTLCriticalSection;
  // Outgoing lines, needs to be initialized
  CSOutGoingArr : array[1..MaxConecciones] of TRTLCriticalSection;
     ArrayOutgoing : array[1..MaxConecciones] of array of string;
  CSIncomingArr : array[1..MaxConecciones] of TRTLCriticalSection;

  // FormState
  FormState_Top    : integer;
  FormState_Left   : integer;
  FormState_Heigth : integer;
  FormState_Width  : integer;
  FormState_Status : integer;

  // Filename variables

  BotDataFilename     :string= 'NOSODATA'+DirectorySeparator+'botdata.psk';
  WalletFilename      :string= 'NOSODATA'+DirectorySeparator+'wallet.pkw';
  SumarioFilename     :string= 'NOSODATA'+DirectorySeparator+'sumary.psk';
  BlockDirectory      :string= 'NOSODATA'+DirectorySeparator+'BLOCKS'+DirectorySeparator;
  MarksDirectory      :string= 'NOSODATA'+DirectorySeparator+'SUMMARKS'+DirectorySeparator;
  GVTMarksDirectory   :string= 'NOSODATA'+DirectorySeparator+'SUMMARKS'+DirectorySeparator+'GVTS'+DirectorySeparator;
  UpdatesDirectory    :string= 'NOSODATA'+DirectorySeparator+'UPDATES'+DirectorySeparator;
  LogsDirectory       :string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator;
  ExceptLogFilename   :string= 'NOSODATA'+DirectorySeparator+'LOGS'+DirectorySeparator+'exceptlog.txt';
  ResumenFilename     :string= 'NOSODATA'+DirectorySeparator+'blchhead.nos';
  ErrorLogFilename    :string= 'NOSODATA'+DirectorySeparator+'errorlog.txt';
  AdvOptionsFilename  :string= 'NOSODATA'+DirectorySeparator+'advopt.txt';
  MasterNodesFilename :string= 'NOSODATA'+DirectorySeparator+'masternodes.txt';
  ZipSumaryFileName   :string= 'NOSODATA'+DirectorySeparator+'sumary.zip';
  ZipHeadersFileName  :string= 'NOSODATA'+DirectorySeparator+'blchhead.zip';
  GVTsFilename        :string= 'NOSODATA'+DirectorySeparator+'gvts.psk';
  NosoCFGFilename     :string= 'NOSODATA'+DirectorySeparator+'nosocfg.psk';

  MontoIncoming : Int64 = 0;
  MontoOutgoing : Int64 = 0;
  InfoPanelTime : integer = 0;

IMPLEMENTATION

Uses
  mpgui, mpdisk, mpParser, mpRed, nosotime, mpProtocol, mpcripto, mpcoin,
  mpRPC,mpblock, mpMN;

{$R *.lfm}

// Identify the pool miners connections
constructor TNodeConnectionInfo.Create;
Begin
FTimeLast:= 0;
End;

constructor TServerTipo.Create;
Begin
VSlot:= -1;
End;

{Thread update logs}

constructor TUpdateLogs.Create(CreateSuspended : boolean);
Begin
inherited Create(CreateSuspended);
FreeOnTerminate := True;
End;

procedure TUpdateLogs.UpdateConsole();
Begin
form1.MemoConsola.Lines.Add(LastLogLine);
End;

procedure TUpdateLogs.Execute;
Begin
While not terminated do
  begin
  sleep(1);
  //Repeat
    LastLogLine := GetLogLine('console');
    if LastLogLine <> '' then Synchronize(@UpdateConsole);
  //until LastLogLine = '';
  end;
End;

{ TThreadClientRead }

procedure TThreadClientRead.Execute;
var
  LLine: String;
  MemStream    : TMemoryStream;
  BlockZipName : string = '';
  Continuar    : boolean = true;
  TruncateLine : string = '';
  Errored      : Boolean;
  downloaded   : boolean;
  LineToSend   : string;
  LineSent     : boolean;
  KillIt       : boolean = false;
begin
REPEAT
TRY
sleep(1);
continuar := true;
if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
   begin
   CanalCliente[FSlot].IOHandler.CheckForDataOnSource(ReadTimeOutTIme);
   if CanalCliente[FSlot].IOHandler.InputBufferIsEmpty then
      begin
      Continuar := false;
      end;
   end;
if Continuar then
   begin
   While not CanalCliente[FSlot].IOHandler.InputBufferIsEmpty do
      begin
      Conexiones[fSlot].IsBusy:=true;
      Conexiones[fSlot].lastping:=UTCTimeStr;
         TRY
         CanalCliente[FSlot].ReadTimeout:=ReadTimeOutTIme;
         LLine := CanalCliente[FSlot].IOHandler.ReadLn(IndyTextEncoding_UTF8);
         if CanalCliente[FSlot].IOHandler.ReadLnTimedout then
            begin
            ToExcLog(Format(rs0001,[conexiones[Fslot].ip]));
            //ToExcLog('TimeOut reading from slot: '+conexiones[Fslot].ip);
            TruncateLine := TruncateLine+LLine;
            Conexiones[fSlot].IsBusy:=false;
            continue;
            end;
         EXCEPT on E:Exception do
            begin
            ToExcLog(Format(rs0002,[IntToStr(Fslot)+slinebreak+E.Message]));
            //tolog ('Error Reading lines from slot: '+IntToStr(Fslot)+slinebreak+E.Message);
            Conexiones[fSlot].IsBusy:=false;
            continue;
            end;
         END; {TRY}
      if continuar then
         begin
         if GetCommand(LLine) = 'RESUMENFILE' then
            begin
            DownloadHeaders := true;
            ToLog(rs0003); //'Receiving headers'
            AddToLog('console',rs0003); //'Receiving headers'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
               TRY
               CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
               downloaded := True;
               EXCEPT ON E:Exception do
                  begin
                  toExcLog(format(rs0004,[conexiones[fSlot].ip,E.Message])); //'Error Receiving headers from
                  downloaded := false;
                  end;
               END; {TRY}
            if Downloaded then
               begin
               Errored := false;
               EnterCriticalSection(CSHeadAccess);
                  TRY
                  MemStream.SaveToFile(ResumenFilename);
                  Errored := False;
                  EXCEPT on E:Exception do
                     begin
                     Errored := true;
                     toExcLog('Error saving headers to file: '+E.Message);
                     end;
                  END; {TRY}
               LeaveCriticalSection(CSHeadAccess);
               end;
            if Downloaded and not errored then
               begin
               AddToLog('console',format(rs0005,[copy(HashMD5File(ResumenFilename),1,5)])); //'Headers file received'
               LastTimeRequestResumen := 0;
               UpdateMyData();
               end;
            MemStream.Free;
            DownloadHeaders := false;
            end
         else if GetCommand(LLine) = 'SUMARYFILE' then
            begin
            DownloadSumary := true;
            ToLog(rs0085); //'Receiving sumary'
            AddToLog('console',rs0085); //'Receiving sumary'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
               TRY
               CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
               downloaded := True;
               EXCEPT ON E:Exception do
                  begin
                  toExcLog(format(rs0086,[conexiones[fSlot].ip,E.Message])); //'Error Receiving sumary from
                  downloaded := false;
                  end;
               END; {TRY}
            if Downloaded then
               begin
               Errored := false;
               EnterCriticalSection(CSSumary);
                  TRY
                  MemStream.SaveToFile(SumarioFilename);
                  Errored := False;
                  EXCEPT on E:Exception do
                     begin
                     Errored := true;
                     toExcLog('Error saving sumary to file: '+E.Message);
                     end;
                  END; {TRY}
               LeaveCriticalSection(CSSumary);
               end;
            if Downloaded and not errored then
               begin
               AddToLog('console',format(rs0087,[copy(HashMD5File(SumarioFilename),1,5)])); //'Sumary file received'
               EnterCriticalSection(CSSumary);
               LoadSumaryFromFile();
               UpdateWalletFromSumario;
               LeaveCriticalSection(CSSumary);

               LastTimeRequestSumary := 0;
               UpdateMyData();
               end;
            MemStream.Free;
            DownloadSumary := false;
            end

         else if GetCommand(LLine) = 'GVTSFILE' then
            begin
            DownloadGVTs := true;
            ToLog(rs0089); //'Receiving GVTs'
            AddToLog('console',rs0089); //'Receiving GVTs'
            MemStream := TMemoryStream.Create;
            CanalCliente[FSlot].ReadTimeout:=10000;
               TRY
               CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
               downloaded := True;
               EXCEPT ON E:Exception do
                  begin
                  toExcLog(format(rs0090,[conexiones[fSlot].ip,E.Message])); //'Error Receiving GVTs from
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
                     toExcLog('Error saving GVTs to file: '+E.Message);
                     end;
                  END; {TRY}
               LeaveCriticalSection(CSGVTsArray);
               end;
            if Downloaded and not errored then
               begin
               AddToLog('console','GVTS file downloaded');
               GetGVTsFileData;
               UpdateMyGVTsList;
               end;
            MemStream.Free;
            DownloadGVTs := false;
            end

         else if LLine = 'BLOCKZIP' then
            begin  // START RECEIVING BLOCKS
            ToLog(rs0006); //'Receiving blocks'
            BlockZipName := BlockDirectory+'blocks.zip';
            TryDeleteFile(BlockZipName);
            MemStream := TMemoryStream.Create;
            DownLoadBlocks := true;
            CanalCliente[FSlot].ReadTimeout:=10000;
               TRY
               CanalCliente[FSlot].IOHandler.ReadStream(MemStream);
               MemStream.SaveToFile(BlockZipName);
               Errored := false;
               EXCEPT ON E:Exception do
                  begin
                  ToExcLog(format(rs0007,[conexiones[fSlot].ip,E.Message])); //'Error Receiving blocks from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                  Errored := true;
                  end;
               END; {TRY}
            If not Errored then
               begin
               if UnzipBlockFile(BlockDirectory+'blocks.zip',true) then
                  begin
                  MyLastBlock := GetMyLastUpdatedBlock();
                  MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
                  ToLog(format(rs0021,[IntToStr(MyLastBlock)])); //'Blocks received up to '+IntToStr(MyLastBlock));
                  LastTimeRequestBlock := 0;
                  UpdateMyData();
                  end;
               end;
            MemStream.Free;
            DownLoadBlocks := false;
            end // END RECEIVING BLOCKS
         else
            begin
            AddToIncoming(FSlot,LLine);
            end;
         end;
      Conexiones[fSlot].IsBusy:=false;
      end;
   end;

EXCEPT ON E:Exception do
   begin
   ToExcLog('*****CRITICAL**** Error inside Client thread: '+E.Message);
   if AnsiContainsStr(E.Message,'Error # 10053') then KillIt := true;
   end;
END; {TRY}
UNTIL ( (terminated) or (not CanalCliente[FSlot].Connected) or (KillIt) );
DecClientReadThreads;
End;

constructor TThreadClientRead.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
end;

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
TimeToRun := 50+(MNsRandomWait*20);
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

{ TForm1 }

// ***************
// *** THREADS ***
// ***************

constructor TUpdateMNs.Create(CreateSuspended : boolean);
begin
  inherited Create(CreateSuspended);
end;

constructor TCryptoThread.Create(CreateSuspended : boolean);
begin
  inherited Create(CreateSuspended);
end;

constructor TThreadSendOutMsjs.Create(CreateSuspended : boolean);
begin
  inherited Create(CreateSuspended);
end;

// Process the Masternodes reports
procedure TUpdateMNs.Execute;
var
  TextLine : String;
Begin
Randomize;
MNsRandomWait := Random(21);
While not terminated do
   begin
   if UTCTime mod 10 = 0 then
      begin
      if ( (IsValidator(MN_Ip)) and (BlockAge>500+(MNsRandomWait div 4)) and (Not MNVerificationDone) and
         (BlockAge<575)and(LastRunMNVerification<>UTCTime) and (MyConStatus = 3) and(NoVerificators=0) ) then
         begin
         LastRunMNVerification := UTCTime;
         RunMNVerification();
         end;
      end;
   WHile LengthWaitingMNs > 0 do
      begin
      TextLine := GetWaitingMNs;
      if not IsIPMNAlreadyProcessed(TextLine) then
         begin
         CheckMNRepo(TextLine);
         sleep(1);
         end;
      end;
   Sleep(10);
   end;
End;

procedure TCryptoThread.Execute;
var
  NewAddrss : integer = 0;
  PosRef : integer; cadena,claveprivada,firma, resultado:string;
Begin
While not terminated do
   begin
   NewAddrss := 0;
   if length(ArrayCriptoOp)>0 then
      begin
      if ArrayCriptoOp[0].tipo = 0 then // actualizar balance
         begin
         //MyCurrentBalance := GetWalletBalance();
         end
      else if ArrayCriptoOp[0].tipo = 1 then // Crear direccion
         begin
         SetLength(ListaDirecciones,Length(ListaDirecciones)+1);
         ListaDirecciones[Length(ListaDirecciones)-1] := CreateNewAddress;
         S_Wallet := true;
         U_DirPanel := true;
         NewAddrss := NewAddrss + 1;
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
            ToExclog(format(rs2501,[E.Message]));
         END{Try};
         end
      else if ArrayCriptoOp[0].tipo = 4 then // recibir customizacion
         begin
         TRY
         PTC_Custom(ArrayCriptoOp[0].data);
         EXCEPT ON E:Exception do
            ToExclog(format(rs2502,[E.Message]));
         END{Try};
         end
       else if ArrayCriptoOp[0].tipo = 5 then // recibir transferencia
          begin
          TRY
          PTC_Order(ArrayCriptoOp[0].data);
          EXCEPT ON E:Exception do
            ToExclog(format(rs2503,[E.Message]));
          END{Try};
          end
       else if ArrayCriptoOp[0].tipo = 6 then // Send GVT
          begin
          TRY
          SendGVT(ArrayCriptoOp[0].data);
          EXCEPT ON E:Exception do
            ToExclog(format(rs2504,[E.Message]));
          END{Try};
          end
       else if ArrayCriptoOp[0].tipo = 7 then // Send GVT
          begin
          TRY
          PTC_SendGVT(ArrayCriptoOp[0].data);
          EXCEPT ON E:Exception do
            ToExclog(format(rs2505,[E.Message]));
          END{Try};
          end;
      DeleteCriptoOp();
      sleep(1);
      end;
   if NewAddrss > 0 then OutText(IntToStr(NewAddrss)+' new addresses',false,2);
   Sleep(1);
   end;
End;

// Send the outgoing messages
procedure TThreadSendOutMsjs.Execute;
Var
  Slot :integer = 1;
  Linea : string;
  Counter : int64 = 0;
Begin
While not terminated do
   begin
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
                ToExclog(format(rs0008,[E.Message]));
               //ToExclog('Error sending outgoing message: '+E.Message);
            END{Try};
            end;
         end;
      Sleep(1);
      end;
   Sleep(1);
   End;
End;

//***********************
// *** FORM RELATIVES ***
//***********************

// Form create
procedure TForm1.FormCreate(sender: TObject);
var
  counter : integer;
begin
LogLines           := TStringlist.Create;
ExceptLines        := TStringlist.Create;
ProcessLines       := TStringlist.Create;
OutgoingMsjs       := TStringlist.Create;
Randomize;
InitCriticalSection(CSProcessLines);
InitCriticalSection(CSOutgoingMsjs);
InitCriticalSection(CSHeadAccess);
InitCriticalSection(CSBlocksAccess);
InitCriticalSection(CSSumary);
InitCriticalSection(CSPending);
InitCriticalSection(CSCriptoThread);
InitCriticalSection(CSLogLines);
InitCriticalSection(CSExcLogLines);
InitCriticalSection(CSMNsArray);
InitCriticalSection(CSWaitingMNs);
InitCriticalSection(CSMNsList);
InitCriticalSection(CSMNsChecks);
InitCriticalSection(CSClosingApp);
InitCriticalSection(CSNMSData);
InitCriticalSection(CSCurrentJob);
InitCriticalSection(CSClientReads);
InitCriticalSection(CSGVTsArray);
InitCriticalSection(CSNosoCFGStr);

InitCriticalSection(CSIdsProcessed);
InitCriticalSection(CSNodesList);
for counter := 1 to MaxConecciones do
   begin
   InitCriticalSection(CSOutGoingArr[counter]);
   InitCriticalSection(CSIncomingArr[counter]);
   SetLength(ArrayOutgoing[counter],0);
   end;

CreateFormInicio();
CreateFormSlots();
SetLength(ArrayOrderIDsProcessed,0);
SetLength(ArrayMNsData,0);
end;

// Form destroy
procedure TForm1.FormDestroy(sender: TObject);
var
  contador : integer;
begin
DoneCriticalSection(CSProcessLines);
DoneCriticalSection(CSOutgoingMsjs);
DoneCriticalSection(CSHeadAccess);
DoneCriticalSection(CSBlocksAccess);
DoneCriticalSection(CSSumary);
DoneCriticalSection(CSPending);
DoneCriticalSection(CSCriptoThread);
DoneCriticalSection(CSLogLines);
DoneCriticalSection(CSExcLogLines);
DoneCriticalSection(CSMNsArray);
DoneCriticalSection(CSWaitingMNs);
DoneCriticalSection(CSMNsList);
DoneCriticalSection(CSMNsChecks);
DoneCriticalSection(CSClosingApp);
DoneCriticalSection(CSNMSData);
DoneCriticalSection(CSCurrentJob);
DoneCriticalSection(CSClientReads);
DoneCriticalSection(CSGVTsArray);
DoneCriticalSection(CSNosoCFGStr);
DoneCriticalSection(CSIdsProcessed);
DoneCriticalSection(CSNodesList);
for contador := 1 to MaxConecciones do
   begin
   DoneCriticalSection(CSOutGoingArr[contador]);
   DoneCriticalSection(CSIncomingArr[contador]);
   end;
for contador := 1 to maxconecciones do
   If Assigned(SlotLines[contador]) then SlotLines[contador].Free;

form1.Server.free;
form1.RPCServer.Free;
{form1.PoolServer.free;}

end;

// RESIZE MAIN FORM (Lot of things to add here)
procedure TForm1.FormResize(sender: TObject);
begin
//infopanel.Left:=(Form1.Width div 2)-150;
//infopanel.Top:=((Form1.Height-560) div 2)+245;
InfoPanel.Left:=
  (Form1.ClientWidth div 2) -
  (InfoPanel.Width div 2);

InfoPanel.Top:=
  (Form1.ClientHeight div 2) -
  (InfoPanel.Height div 2);

PanelQRImg.Left:=
  (TabAddresses.ClientWidth div 2) -
  (PanelQRImg.Width div 2);
end;

// Form show
procedure TForm1.FormShow(sender: TObject);
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

Procedure TForm1.InicoTimerEjecutar(sender: TObject);
Begin
InicioTimer.Enabled:=false;
EjecutarInicio;
End;

// Auto restarts the app from hangs
Procedure TForm1.RestartTimerEjecutar(sender: TObject);
Begin
If Protocolo > 0 then
   begin
   If ((BlockAge<590) and (GetNMSData.Miner<> '')) then
      begin
      if BuildNMSBlock = 0 then BuildNMSBlock := NextBlockTimeStamp;
      end
   else BuildNMSBlock := 0;
   end;
RestartTimer.Enabled:=false;
StaTimeLab.Caption:=TimestampToDate(UTCTime)+' ('+IntToStr(UTCTime-EngineLastUpdate)+')';
//StaTimeLab.Update;
//if ( ((UTCTime.ToInt64 > EngineLastUpdate+WO_AntiFreezeTime) and (WO_AntiFreeze)) or (G_CloseRequested) ) then
if G_CloseRequested then
   begin
   if 1=1 then
      begin
      if not G_CloseRequested then
         begin
         RestartNosoAfterQuit := true;
         end;
      cerrarprograma;
      end;
   end
else RestartTimer.Enabled:=true;
End;

// Ejecuta todo el proceso de carga y lo muestra en el form inicio
Procedure TForm1.EjecutarInicio();
var
  contador : integer;
  LastRelease : String = '';
Begin
// A partir de aqui se inicializa todo
// Enable units variables
NosoDebug_UsePerformance := true;
UpdateLogsThread := TUpdateLogs.Create(true);
UpdateLogsThread.FreeOnTerminate:=true;
UpdateLogsThread.Start;
CreateNewLog('console');
if not directoryexists('NOSODATA') then CreateDir('NOSODATA');
OutText(rs0022,false,1); //'✓ Data directory ok'
// finalizar la inicializacion
InicializarFormulario();
OutText(rs0023,false,1); //✓ GUI initialized
VerificarArchivos();
InicializarGUI();
//InitTime();
GetTimeOffset(PArameter(GetNosoCFGString,2));
OutText('✓ Mainnet time synced',false,1);
UpdateMyData();
OutText(rs0024,false,1); //'✓ My data updated'
// Ajustes a mostrar
LoadOptionsToPanel();
form1.Caption:=coinname+format(rs0027,[ProgramVersion,SubVersion]);
Application.Title := coinname+format(rs0027,[ProgramVersion,SubVersion]);   // Wallet
AddToLog('console',coinname+format(rs0027,[ProgramVersion,SubVersion]));
UpdateMyGVTsList;
OutText(rs0088,false,1); // '✓ My GVTs grid updated';
if fileexists(RestartFileName) then
   begin
   Deletefile(RestartFileName);
   OutText(rs0069,false,1); // '✓ Launcher file deleted';
   end;
if fileexists('restart.txt') then
   begin
   RestartConditions();
   OutText(rs0070,false,1); // '✓ Restart file deleted';
   end;
StringAvailableUpdates := AvailableUpdates();
Form1.Latido.Enabled:=true;
OutText('Noso is ready',false,1);
if WO_CloseStart then
   begin
   G_Launching := false;
   if WO_autoserver then KeepServerOn := true;
   if WO_AutoConnect then ProcessLinesAdd('CONNECT');
   FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
   FirstShow := true;
   SetLength(ArrayCriptoOp,0);
   Setlength(MNsArray,0);
   Setlength(MNsList,0);
   Setlength(ArrMNChecks,0);

   Setlength(WaitingMNs,0);
      ThreadMNs := TUpdateMNs.Create(true);
      ThreadMNs.FreeOnTerminate:=true;
      ThreadMNs.Start;
      CryptoThread := TCryptoThread.Create(true);
      CryptoThread.FreeOnTerminate:=true;
      CryptoThread.Start;
      SendOutMsgsThread := TThreadSendOutMsjs.Create(true);
      SendOutMsgsThread.FreeOnTerminate:=true;
      SendOutMsgsThread.Start;
   Tolog(rs0029); NewLogLines := NewLogLines-1; //'Noso session started'
   info(rs0029);  //'Noso session started'
   infopanel.BringToFront;
   SetCurrentJob('Main',true);
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
if WO_AutoConnect then ProcessLinesAdd('CONNECT');
FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
FirstShow := true;
SetLength(ArrayCriptoOp,0);
Setlength(MNsArray,0);
Setlength(MNsList,0);
Setlength(ArrMNChecks,0);

Setlength(WaitingMNs,0);
   ThreadMNs := TUpdateMNs.Create(true);
   ThreadMNs.FreeOnTerminate:=true;
   ThreadMNs.Start;
   CryptoThread := TCryptoThread.Create(true);
   CryptoThread.FreeOnTerminate:=true;
   CryptoThread.Start;
   SendOutMsgsThread := TThreadSendOutMsjs.Create(true);
   SendOutMsgsThread.FreeOnTerminate:=true;
   SendOutMsgsThread.Start;
Tolog(rs0029); NewLogLines := NewLogLines-1; //'Noso session started'
info(rs0029);  //'Noso session started'
form1.infopanel.BringToFront;
SetCurrentJob('Main',true);
forminicio.Visible:=false;
form1.Visible:=true;
if FormState_Status = 0 then
   begin
   form1.Top:=FormState_Top;
   form1.Left:=FormState_Left;
   end;
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
CB_WO_AntiFreeze.Checked:=WO_AntiFreeze;
CB_WO_Multisend.Checked:=WO_Multisend;
SE_WO_AntifreezeTime.value := WO_AntifreezeTime;
CB_WO_Autoupdate.Checked := WO_AutoUpdate;
// RPC
LE_Rpc_Port.Text := IntToStr(RPCPort);
LE_Rpc_Pass.Text := RPCPass;
CB_RPCFilter.Checked:=RPCFilter;
MemoRPCWhitelist.Text:=RPCWhitelist;
if not RPCFilter then MemoRPCWhitelist.Enabled:=false;
CB_AUTORPC.Checked:= RPCAuto;
ComboBoxLang.Text:=WO_Language;

End;

// Cuando se solicita cerrar el programa
procedure TForm1.FormCloseQuery(sender: TObject; var CanClose: boolean);
begin
G_CloseRequested := true;
CanClose:= G_ClosingAPP;
end;

// Button donate
procedure TForm1.BitBtnDonateClick(sender: TObject);
begin
form1.PageMain.ActivePage := form1.TabWallet;
form1.TabWalletMain.ActivePage := form1.TabAddresses;
PanelSend.Visible:=true;
Form1.EditSCDest.Text:='NpryectdevepmentfundsGE';
Form1.EditSCMont.Text:=IntToStr(DefaultDonation)+'.00000000';
Form1.MemoSCCon.Text:='Donation';
end;

procedure TForm1.BarcodeQR1Click(sender: TObject);
begin
form1.PanelQRImg.Visible:=false;
form1.DireccionesPanel.Enabled:=true;
end;

// visit web button
procedure TForm1.BitBtnWebClick(sender: TObject);
begin
OpenDocument('https://nosocoin.com');
end;

Procedure GenerateCode();
begin
form1.BarcodeQR1.Text:=form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
end;

procedure TForm1.BQRCodeClick(sender: TObject);
begin
GenerateCode();
form1.DireccionesPanel.Enabled:=false;
form1.TextQRcode.caption := form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
form1.PanelQRImg.Visible:=true;
end;

// Show address on QRCode
procedure TForm1.SpeedButton2Click(sender: TObject);
begin
form1.BarcodeQR1.Text:=form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
form1.TextQRcode.caption := form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
end;

// Show keys on QR code
procedure TForm1.SpeedButton3Click(sender: TObject);
var
  index : integer;
begin
form1.TextQRcode.caption := 'KEYS: '+form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
index := form1.Direccionespanel.Row-1;
form1.BarcodeQR1.Text:=ListaDirecciones[index].PublicKey+' '+ListaDirecciones[index].PrivateKey;
end;

// Double click open conexions slots form
procedure TForm1.StaConLabDblClick(sender: TObject);
begin
formslots.Visible:=true;
end;

// Al minimizar verifica si hay que llevarlo a barra de tareas
procedure TForm1.FormWindowStateChange(sender: TObject);
begin
if WO_ToTray then
   if Form1.WindowState = wsMinimized then
      begin
      SysTrayIcon.visible:=true;
      form1.hide;
      end;
end;

// Chequea las teclas presionadas en la linea de comandos
Procedure TForm1.ConsoleLineKeyup(sender: TObject; var Key: Word; Shift: TShiftState);
var
  LineText : String;
begin
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
   UserRowHeigth := UserRowHeigth+1;
   AddToLog('console','UserRowHeigth:'+inttostr(UserRowHeigth));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl]) and (Key = VK_K)) then
   begin
   UserRowHeigth := UserRowHeigth-1;
   AddToLog('console','UserRowHeigth:'+inttostr(UserRowHeigth));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl]) and (Key = VK_O)) then
   begin
   UserFontSize := UserFontSize+1;
   AddToLog('console','UserFontSize:'+inttostr(UserFontSize));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl]) and (Key = VK_L)) then
   begin
   UserFontSize := UserFontSize-1;
   AddToLog('console','UserFontSize:'+inttostr(UserFontSize));
   UpdateRowHeigth();
   end;
if ((Shift = [ssCtrl, ssAlt]) and (Key = VK_D)) then
   begin
   if not Form1.TabDoctor.TabVisible then
      begin
      Form1.PageMain.ActivePage:= Form1.TabMonitor;
      Form1.TabDoctor.TabVisible:= True;
      Form1.PCMonitor.ActivePage:= Form1.TabDoctor;
      AddToLog('console','Doctor available');
      end
   else
      begin
      Form1.PCMonitor.ActivePage:= Form1.TabDebug_Log;
      Form1.TabDoctor.TabVisible:= False;
      AddToLog('console','Doctor closed');
      end;
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
   ts := (sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (sender as TStringGrid).Canvas.TextStyle := ts;

   if ((aRow>0) and (ListaDirecciones[aRow-1].Balance>posrequired) and (ListaDirecciones[aRow-1].Balance>(posrequired+(WO_PosWarning*140*10000000))) ) then
      begin
      (sender as TStringGrid).Canvas.Brush.Color :=  clmoneygreen;
      (sender as TStringGrid).Canvas.font.Color :=  clblack;
      end;
   if ((aRow>0) and (ListaDirecciones[aRow-1].Balance>posrequired) and (ListaDirecciones[aRow-1].Balance< (posrequired+(WO_PosWarning*140*10000000))) ) then
      begin
      (sender as TStringGrid).Canvas.Brush.Color :=  clYellow;
      (sender as TStringGrid).Canvas.font.Color :=  clblack;
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
   ts := (sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (sender as TStringGrid).Canvas.TextStyle := ts;
   if Copy(GridMyTxs.Cells[3,aRow],1,1) = '-' then GridMyTxs.Canvas.Font.Color:=clRed
   else GridMyTxs.Canvas.Font.Color:=clGreen;
   end
else if ((arow=0) and (acol = 3)) then
   begin
   ts := (sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taRightJustify;
   (sender as TStringGrid).Canvas.TextStyle := ts;
   end
else
   begin
   ts := (sender as TStringGrid).Canvas.TextStyle;
   ts.Alignment := taCenter;
   (sender as TStringGrid).Canvas.TextStyle := ts;
   end;
End;

// Ejecutar el ladido del timer
Procedure TForm1.LatidoEjecutar(sender: TObject);
Begin
if EngineLastUpdate <> UTCtime then EngineLastUpdate := UTCtime;
Form1.Latido.Enabled:=false;
CheckClipboardForPays();
if ( (UTCTime >= BuildNMSBlock) and (BuildNMSBlock>0) and (GetNMSData.Miner<>'') and (MyConStatus=3) ) then
   BuildNewBlock(MyLastBlock+1,BuildNMSBlock,MyLastBlockHash,GetNMSData.Miner,GetNMSData.Hash);
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
if ( (KeepServerOn) and (not Form1.Server.Active) and (LastTryServerOn+5<UTCTime)
      and (MyConStatus = 3) ) then
   ProcessLinesAdd('serveron');
if G_CloseRequested then CerrarPrograma();
if form1.SystrayIcon.Visible then
   form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion+SubVersion+SLINEBREAK+LabelBigBalance.Caption;
if FormSlots.Visible then UpdateSlotsGrid();
ConnectedRotor +=1; if ConnectedRotor>6 then ConnectedRotor := 0;
UpdateStatusBar;
if ( (UTCTime mod 3600=3590) and (LastBotClear<>UTCTimeStr) and (Form1.Server.Active) ) then ProcessLinesAdd('delbot all');
if ( (UTCTime mod 600>=570) and (UTCTime>NosoT_LastUpdate+599) ) then
   UpdateOffset(PArameter(GetNosoCFGString,2));
Form1.Latido.Enabled:=true;
end;

//procesa el cierre de la aplicacion
Procedure CerrarPrograma();
var
  counter: integer;
  GoAhead : boolean = false;
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
   if RestartNosoAfterQuit then CrearRestartfile();
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
   If Assigned(LogLines) then LogLines.Free;
   If Assigned(ExceptLines) then ExceptLines.Free;
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
   form1.Close;
   end;
End;

// Run time creation of form components
Procedure InicializarFormulario();
var
  contador : integer = 0;
Begin
// Make sure ALL tabs are set correct at startup
Form1.PageMain.ActivePage:= Form1.TabWallet;
Form1.TabWalletMain.ActivePage:= Form1.TabAddresses;
Form1.PageControl1.ActivePage:= Form1.TabOpt_Wallet;
Form1.PCMonitor.ActivePage:=form1.TabDebug_Log;

// Visual components

// Resize all grids at launch
Form1.GridPoSResize(form1);
Form1.GridPoS.Cells[0,0] := 'Stake size';//rs0063;
Form1.GridPoS.Cells[0,1] := 'MNs Earned';//rs0064;
Form1.GridPoS.Cells[0,2] := 'PoS Earned';//rs0065;
form1.GridPoS.FocusRectVisible:=false;

Form1.SG_MonitorResize(nil);


form1.DataPanel.DefaultRowHeight:=UserRowHeigth;
form1.DataPanel.Font.Size:=UserFontSize;
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

Form1.BQRCode.Parent:=form1.DireccionesPanel;
Form1.BDefAddr.Parent:=form1.DireccionesPanel;
form1.BCustomAddr.Parent:=form1.DireccionesPanel;
form1.BCopyAddr.Parent:=form1.DireccionesPanel;
Form1.BNewAddr.Parent:=form1.DireccionesPanel;

Form1.SGridSC.FocusRectVisible:=false;

form1.GridMyTxs.SelectedColor:=clLtGray;
form1.GridMyTxs.Options:= form1.GridMyTxs.Options+[goRowSelect]-[goRangeSelect];
form1.GridMyTxs.ColWidths[0]:= 60;
form1.GridMyTxs.ColWidths[1]:= 60;
form1.GridMyTxs.ColWidths[2]:= 100;
form1.GridMyTxs.ColWidths[3]:= 147;
form1.GridMyTxs.ColWidths[4]:= 0;
form1.GridMyTxs.ColWidths[5]:= 0;
form1.GridMyTxs.ColWidths[6]:= 0;
form1.GridMyTxs.ColWidths[7]:= 0;
form1.GridMyTxs.ColWidths[8]:= 0;
form1.GridMyTxs.ColWidths[9]:= 0;
form1.GridMyTxs.ColWidths[10]:= 0;
form1.GridMyTxs.FocusRectVisible:=false;

Form1.imagenes.GetBitMap(54,form1.ImgRotor.picture.BitMap);

form1.LabAbout.Caption:=CoinName+' project'+SLINEBREAK+'Designed by bermello'+SLINEBREAK+
'Crypto routines by Xor-el'+SLINEBREAK+
'Version '+ProgramVersion+subVersion+SLINEBREAK+'Protocol '+IntToStr(Protocolo)+SLINEBREAK+BuildDate;

form1.SG_Monitor.FocusRectVisible:=false;
form1.SG_Monitor.Options:= form1.GridMyTxs.Options+[goRowSelect]-[goRangeSelect];
form1.SG_Monitor.ColWidths[0]:= 142;form1.SG_Monitor.ColWidths[1]:= 73;
form1.SG_Monitor.ColWidths[2]:= 73;form1.SG_Monitor.ColWidths[3]:= 73;

//Elementos no visuales
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

form1.SystrayIcon := TTrayIcon.Create(form1);
form1.SystrayIcon.BalloonTimeout:=3000;
form1.SystrayIcon.BalloonTitle:=CoinName+' Wallet';
form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion+SubVersion;
form1.SysTrayIcon.OnDblClick:=@form1.DoubleClickSysTray;
form1.imagenes.GetIcon(48,form1.SystrayIcon.icon);

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

// Funciones del Servidor RPC

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
      ToExcLog('Error on Http server: '+E.Message);
   END; {TRY}
   AResponseInfo.ContentText:= ParseRPCJSON(PostString);
   StreamString.Free;
   end;
End;

// *****************************
// *** NODE SERVER FUNCTIONS ***
// *****************************

// returns the number of active connections
function TForm1.ClientsCount : Integer ;
var
  Clients : TList;
Begin
Clients:= server.Contexts.LockList;
   TRY
   Result := Clients.Count ;
   EXCEPT ON E:Exception do
      ToExcLog('Error getting server list count: '+E.Message);
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

// Trys to close a server connection safely
Procedure TForm1.TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
Begin
try
   if closemsg <>'' then
      Acontext.Connection.IOHandler.WriteLn(closemsg);
   AContext.Connection.Disconnect();
   Acontext.Connection.IOHandler.InputBuffer.Clear;
Except on E:Exception do
   ToExcLog(format(rs0042,[E.Message]));
   //ToExcLog('SERVER: Error trying close a server client connection ('+E.Message+')');
end;
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
Begin
GoAhead := true;
IPUser := AContext.Connection.Socket.Binding.PeerIP;
slot := GetSlotFromIP(IPUser);
if not SendDirectToPeer then
   begin
   REPEAT
   LineToSend := GetTextToSlot(slot);
   if LineToSend <> '' then
      begin
      TryMessageToNode(AContext,LineToSend);
      Inc(LinesSent);
      end;
   UNTIL LineToSend='' ;
   if LinesSent >0 then exit;
   end;
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
   ToExcLog(format(rs0045,[IPUser,E.Message]));
   //ToExcLog('SERVER: Can not read line from connection '+IPUser+'('+E.Message+')');
   GoAhead := false;
   end;
END{Try};
if GoAhead then
   begin
   conexiones[slot].IsBusy:=true;
   if GetCommand(LLine) = 'RESUMENFILE' then
      begin
      MemStream := TMemoryStream.Create;
      DownloadHeaders := true;
         TRY
         AContext.Connection.IOHandler.ReadStream(MemStream);
         GetFileOk := true;
         EXCEPT ON E:EXCEPTION do
            begin
            //ToExcLog(Format(rs0046,[E.Message])); //'SERVER: Server error receiving headers file ('+E.Message+')');
            TryCloseServerConnection(AContext);
            GetFileOk := false;
            end;
         END; {TRY}
      if GetfileOk then
         begin
         EnterCriticalSection(CSHeadAccess);
            TRY
            MemStream.SaveToFile(ResumenFilename);
            AddToLog('console',Format(rs0047,[copy(HashMD5File(ResumenFilename),1,5)]));//'Headers file received'
            EXCEPT ON E:EXCEPTION do
               ToExcLog('Error saving Headers received on server: '+E.Message)
            END; {TRY};
         LeaveCriticalSection(CSHeadAccess);
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
            //ToExcLog(Format(rs0048,[E.Message])); // Server error receiving block file ('+E.Message+')');
            GetFileOk := false;
            TryCloseServerConnection(AContext);
            end;
         END; {TRY}
      if GetFileOk then
         begin
         if UnzipBlockFile(BlockDirectory+'blocks.zip',true) then
            begin
            MyLastBlock := GetMyLastUpdatedBlock();
            LastTimeRequestBlock := 0;
            ToLog(format(rs0021,[IntToStr(MyLastBlock)])); //'Blocks received up to '+IntToStr(MyLastBlock));
            end
         end;
      MemStream.Free;
      DownLoadBlocks := false;
      end
   else if parameter(LLine,4) = '$GETRESUMEN' then
      begin
      MemStream := TMemoryStream.Create;
         TRY
         EnterCriticalSection(CSHeadAccess);
         MemStream.LoadFromFile(ResumenFilename);
         LeaveCriticalSection(CSHeadAccess);
         GetFileOk := true;
         EXCEPT on E:Exception do
            begin
            GetFileOk := false;
            //ToExcLog(Format(rs0049,[E.Message]));//SERVER: Error creating stream from headers: %s',[E.Message]));
            end;
         END; {TRY}
      if GetFileOk then
         begin
            TRY
            Acontext.Connection.IOHandler.WriteLn('RESUMENFILE');
            Acontext.connection.IOHandler.Write(MemStream,0,true);
            EXCEPT on E:Exception do
               begin
               Form1.TryCloseServerConnection(Conexiones[Slot].context);
               //ToExcLog(Format(rs0051,[E.Message]));
               end;
            END; {TRY}
         end;
      MemStream.Free;
      end
   else if parameter(LLine,4) = '$LASTBLOCK' then
      begin // START SENDING BLOCKS
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
         If GetFileOk then
            begin
               TRY
               Acontext.Connection.IOHandler.WriteLn('BLOCKZIP');
               Acontext.connection.IOHandler.Write(MemStream,0,true);
               ToLog(Format(rs0052,[IPUser,BlockZipName])); //SERVER: BlockZip send to '+IPUser+':'+BlockZipName);
               EXCEPT ON E:Exception do
                  begin
                  Form1.TryCloseServerConnection(Conexiones[Slot].context);
                  //ToExcLog(Format(rs0053,[E.Message])); //'SERVER: Error sending ZIP blocks file ('+E.Message+')');
                  end
               END; {TRY}
            end;
         MemStream.Free;
         Trydeletefile(BlockZipName); // safe function to delete files
         end
      end // END SENDING BLOCKS

      else if parameter(LLine,4) = '$GETGVTS' then
         begin
         MemStream := TMemoryStream.Create;
            TRY
            EnterCriticalSection(CSGVTsArray);
            MemStream.LoadFromFile(GVTsFilename);
            LeaveCriticalSection(CSGVTsArray);
            GetFileOk := true;
            EXCEPT on E:Exception do
               begin
               GetFileOk := false;
               //ToExcLog(Format(rs0049,[E.Message]));//SERVER: Error creating stream from headers: %s',[E.Message]));
               end;
            END; {TRY}
         if GetFileOk then
            begin
               TRY
               Acontext.Connection.IOHandler.WriteLn('GVTSFILE');
               Acontext.connection.IOHandler.Write(MemStream,0,true);
               EXCEPT on E:Exception do
                  begin
                  Form1.TryCloseServerConnection(Conexiones[Slot].context);
                  //ToExcLog(Format(rs0051,[E.Message]));
                  end;
               END; {TRY}
            end;
         MemStream.Free;
         end // SENDING GVTS FILE

   else if AnsiContainsStr(ValidProtocolCommands,Uppercase(parameter(LLine,4))) then
      begin
         TRY
         AddToIncoming(slot,LLine);
         EXCEPT
         On E :Exception do
            ToExcLog(Format(rs0054,[E.Message]));
            //ToExcLog('SERVER: Server error adding received line ('+E.Message+')');
         END; {TRY}
      end
   else
      begin
      TryCloseServerConnection(AContext);
      ToExcLog(Format(rs0055,[LLine]));
      //ToExcLog('SERVER: Got unexpected line: '+LLine);
      end;
   conexiones[slot].IsBusy:=false;
   end;
End;

// Un usuario intenta conectarse
procedure TForm1.IdTCPServer1Connect(AContext: TIdContext);
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
Begin
GoAhead := true;
ContextData := TServerTipo.Create;
ContextData.Slot:=0;
AContext.Data:=ContextData;
IPUser := AContext.Connection.Socket.Binding.PeerIP;
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
TRY
   LLine := AContext.Connection.IOHandler.ReadLn('',1000,-1,IndyTextEncoding_UTF8);
   if AContext.Connection.IOHandler.ReadLnTimedout then
      begin
      TryCloseServerConnection(AContext);
      ToExcLog(rs0056);
      //ToExcLog('SERVER: Timeout reading line from new connection');
      GoAhead := false;
      end;
EXCEPT on E:Exception do
   begin
   TryCloseServerConnection(AContext);
   ToExcLog(format(rs0057,[E.Message]));
   //ToExcLog('SERVER: Can not read line from new connection ('+E.Message+')');
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
   else if parameter(LLine,0) = 'BESTHASH' then
      begin
      if ( (not IsBlockOpen) and (not IsSeedNode(IPUSer)) ) then TryCloseServerConnection(AContext,'False '+GetNMSData.Diff+' 6')
      else TryCloseServerConnection(AContext,PTC_BestHash(LLine, IPUSer));
      end
   else if parameter(LLine,0) = 'NSLPEND' then
      TryCloseServerConnection(AContext,PendingRawInfo)
   else if parameter(LLine,0) = 'NSLBLKORD' then
      TryCloseServerConnection(AContext,GEtNSLBlkOrdInfo(LLine))
   else if parameter(LLine,0) = 'NSLTIME' then
      TryCloseServerConnection(AContext,UTCTimeStr)
   else if parameter(LLine,0) = 'NSLMNS' then
      TryCloseServerConnection(AContext,GetMN_FileText)
   else if parameter(LLine,0) = 'NSLCFG' then
      TryCloseServerConnection(AContext,GetNosoCFGString)

   else if parameter(LLine,0) = 'NSLGVT' then
      begin
      MemStream := TMemoryStream.Create;
      EnterCriticalSection(CSGVTsArray);
         TRY
         MemStream.LoadFromFile(GVTsFilename);
         GetFileOk := true;
         EXCEPT on E:Exception do
            begin
            GetFileOk := false;
            ToExcLog(Format(rs0091,[E.Message])); //'SERVER: Error creating stream from GVTs: %s',[E.Message]));
            end;
         END; {TRY}
      LeaveCriticalSection(CSGVTsArray);
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
   else if parameter(LLine,0) = 'GETZIPSUMARY' then  //
      begin
      MemStream := TMemoryStream.Create;
      EnterCriticalSection(CSSumary);
         TRY
         MemStream.LoadFromFile(ZipSumaryFileName);
         GetFileOk := true;
         EXCEPT on E:Exception do
            begin
            GetFileOk := false;
            ToExcLog(Format(rs0049,[E.Message])); //'SERVER: Error creating stream from headers: %s',[E.Message]));
            end;
         END; {TRY}
      LeaveCriticalSection(CSSumary);
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

   else if Copy(LLine,1,4) <> 'PSK ' then  // invalid protocol
      begin
      ToLog(format(rs0058,[IPUser])); //ToLog('SERVER: Invalid client->'+IPUser);
      TryCloseServerConnection(AContext,'WRONG_PROTOCOL');
      UpdateBotData(IPUser);
      end

   else if ((length(Peerversion) < 6) and (Mylastblock >= 40000)) then
      begin
      TryCloseServerConnection(AContext,GetPTCEcn+'OLDVERSION');
      end

   else if IPUser = MyPublicIP then
      begin
      ToLog(rs0059);
      //ToLog('SERVER: Own connected');
      TryCloseServerConnection(AContext);
      end

   else if ( (Abs(UTCTime-PeerUTC)>5) and (Mylastblock >= 70000) ) then
      begin
      TryCloseServerConnection(AContext,'WRONG_TIME');
      end

   else if BotExists(IPUser) then // known bot
      begin
      TryCloseServerConnection(AContext,'BANNED');
      end
   else if GetSlotFromIP(IPUser) > 0 then
      begin
      ToLog(Format(rs0060,[IPUser]));
      //ToLog('SERVER: Duplicated connection->'+IPUser);
      TryCloseServerConnection(AContext,GetPTCEcn+'DUPLICATED');
      UpdateBotData(IPUser);
      end
   else if Peerversion < VersionRequired then
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
         ToLog(format(rs0061,[IPUser])); //New Connection from:
         ContextData.Slot:=ThisSlot;
         AContext.Data:=ContextData;
         MyPublicIP := MiIp;
         U_DataPanel := true;
         ClearOutTextToSlot(ThisSlot);
         end;
      end
   else
      begin
      ToLog(Format(rs0062,[IPUser]));
      //ToLog('SERVER: Closed unhandled incoming connection->'+IPUser);
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
   CerrarSlot(ContextData.Slot);
End;

// Excepcion en el servidor
procedure TForm1.IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
Begin
CerrarSlot(GetSlotFromContext(AContext));
ToExcLog('Server Excepcion: '+AException.Message);    //Server Excepcion:
End;

// DOUBLE CLICK TRAY ICON TO RESTORE
Procedure TForm1.DoubleClickSysTray(sender: TObject);
Begin
SysTrayIcon.visible:=false;
Form1.WindowState:=wsNormal;
Form1.Show;
if FormState_Status = 0 then
   begin
   form1.Top:=FormState_Top;
   form1.Left:=FormState_Left;
   end;
End;

// Click en conectar
Procedure TForm1.ConnectCircleOnClick(sender: TObject);
Begin
if (CONNECT_Try) then
   ProcessLinesAdd('disconnect')
else
   begin
   ProcessLinesAdd('connect');
   end;
End;

// Mostrar los detalles de una transaccion
Procedure TForm1.GridMyTxsOnDoubleClick(sender: TObject);
var
  cont : integer;
  extratext :string = '';
  referencetoshow : string = '';
Begin
if GridMyTxs.Row>0 then
   begin
   PanelTrxDetails.visible := true;
   form1.MemoTrxDetails.Lines.Clear;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'TRFR' then
      Begin
      if GridMyTxs.Cells[10,GridMyTxs.Row] = 'YES' then // Own transaction'
        extratext :=' (OWN)'; //' (OWN)'
      if GridMyTxs.Cells[7,GridMyTxs.Row] <> 'null' then
         referencetoshow := GridMyTxs.Cells[7,GridMyTxs.Row];
      form1.MemoTrxDetails.Text:=
      GridMyTxs.Cells[4,GridMyTxs.Row]+SLINEBREAK+                    //order ID
      'Receiver : '+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+      //'Receiver : '
      'Ammount  : '+GridMyTxs.Cells[3,GridMyTxs.Row]+extratext+SLINEBREAK+  //'Ammount  : '
      'Reference : '+referencetoshow+SLINEBREAK+    //'reference  : '
      'Transfers: '+GridMyTxs.Cells[9,GridMyTxs.Row]+SLINEBREAK+      //'Transfers: '
      GetCommand(GridMyTxs.Cells[8,GridMyTxs.Row])+SLINEBREAK;
      if StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1)> 1 then // añadir mas trfids
         for cont := 2 to StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1) do
           form1.MemoTrxDetails.lines.add(parameter(GridMyTxs.Cells[8,GridMyTxs.Row],cont-1));
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'MINE' then
      Begin
      form1.MemoTrxDetails.Text:=
      'Mined    : '+GridMyTxs.Cells[0,GridMyTxs.Row]+SLINEBREAK+ //'Mined    : '
      'Receiver : '+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+   //'Receiver : '
      'Ammount  : '+GridMyTxs.Cells[3,GridMyTxs.Row];   //'Ammount  : '
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'CUSTOM' then
      Begin
      form1.MemoTrxDetails.Text:=
      'Address customization'+SLINEBREAK+                   //'Address customization'
      'Address  : '+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Hash+SLINEBREAK+//'Address  : '
      'Alias    : '+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Custom+SLINEBREAK+//'Alias    : '
      'Amount   : '+Int2Curr(Customizationfee);
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'FEE' then
      begin
      form1.MemoTrxDetails.Text:=
      'Maintenance fee'+SLINEBREAK+   //'Maintenance fee'
      'Address  : '+GridMyTxs.Cells[6,GridMyTxs.Row]+SLINEBREAK+  //'Address  : '
      'Interval : '+GridMyTxs.Cells[7,GridMyTxs.Row]+SLINEBREAK+  //'Interval : '
      'Ammount  : '+GridMyTxs.Cells[3,GridMyTxs.Row]; //'Ammount  : '
      if GridMyTxs.Cells[8,GridMyTxs.Row] = 'YES' then
        form1.MemoTrxDetails.Text:= form1.MemoTrxDetails.Text+' (Address deleted from summary)';//' (Address deleted from summary)'
      end;
   form1.MemoTrxDetails.SelStart:=0;
   end;

End;

Procedure TForm1.BitPosInfoOnClick (sender: TObject);
var
   PosRequired : int64;
Begin
PosRequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
PanelTrxDetails.visible := true;
MemoTrxDetails.Lines.Clear;
MemoTrxDetails.Lines.Add('PoS Statistics'+slinebreak+
                         'My history'+slinebreak+
                         'PoS payouts : '+IntToStr(G_PoSPayouts)+' payouts'+slinebreak+
                         'PoS earnings: '+Int2Curr(G_PoSEarnings)+' Nos'+Slinebreak+
                         'Mainnet'+Slinebreak+
                         'Next block required: '+Int2Curr(PosRequired)+' Nos'+Slinebreak+
                         'My PoS Addresses   : '+IntToStr(GetMyPosAddressesCount));
End;

// Fija como direccion default a la seleccionada
Procedure TForm1.BDefAddrOnClick(sender: TObject);
Begin
if DireccionesPanel.Row > 0 then
  ProcessLinesAdd('SETDEFAULT '+IntToStr(DireccionesPanel.Row-1));
End;

// Mostrar el panel de personalizacion
Procedure TForm1.BCustomAddrOnClick(sender: TObject);
var
  Address : string;
Begin
Address := DireccionesPanel.Cells[0,DireccionesPanel.Row];
if not IsValidHashAddress(address) then info('Address already customized')
else if AddressAlreadyCustomized(address) then info('Address already customized')
else if GetAddressBalance(Address)-GetAddressPendingPays(address)< Customizationfee then info('Insufficient funds')
else
   begin
   DireccionesPanel.Enabled:=false;
   PanelCustom.Visible := true;
   PanelCustom.BringToFront;
   EditCustom.SetFocus;
   end;
End;

// Leer la pulsacion de enter en la customizacion de una direccion
Procedure Tform1.EditCustomKeyUp(sender: TObject; var Key: Word; Shift: TShiftState);
Begin
if Key=VK_RETURN then
   begin
   ProcessLinesAdd('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
   PanelCustom.Visible := false;
   EditCustom.Text := '';
   end;
End;

// Aceptar la personalizacion
Procedure TForm1.BOkCustomClick(sender: TObject);
Begin
ProcessLinesAdd('Customize '+DireccionesPanel.Cells[0,DireccionesPanel.Row]+' '+EditCustom.Text);
PanelCustom.Visible := false;
EditCustom.Text := '';
End;

// Cerrar el panel de personalizacion cuando el boton sale de el
Procedure TForm1.PanelCustomMouseLeave(sender: TObject);
Begin
PanelCustom.Visible := false;
DireccionesPanel.Enabled:=true;
End;

// El boton para crear una nueva direccion
Procedure TForm1.BNewAddrOnClick(sender: TObject);
Begin
ProcessLinesAdd('newaddress');
End;

// Copia el hash de la direccion al portapapeles
Procedure TForm1.BCopyAddrClick(sender: TObject);
Begin
if ListaDirecciones[DireccionesPanel.Row-1].custom <> '' then
  Clipboard.AsText:= ListaDirecciones[DireccionesPanel.Row-1].custom
else Clipboard.AsText:= ListaDirecciones[DireccionesPanel.Row-1].Hash;
info('Copied to clipboard');//'Copied to clipboard'
End;

// Abre el panel para enviar coins
Procedure TForm1.BSendCoinsClick(sender: TObject);
Begin
PanelSend.Visible:=true;
End;

// Cerrar el panel de envio de dinero
Procedure Tform1.BCLoseSendOnClick(sender: TObject);
Begin
PanelSend.Visible:=false;
End;

// Cada miniciclo del infotimer
Procedure TForm1.InfoTimerEnd(sender: TObject);
Begin
InfoPanelTime := InfoPanelTime-50;
if InfoPanelTime <= 0 then
  begin
  InfoPanelTime := 0;
  InfoPanel.Caption:='';
  InfoPanel.sendtoback;
  end;
end;

// Procesa el hint a mostrar segun el control
Procedure TForm1.CheckForHint(sender:TObject);
Begin
Processhint(sender);
End;

// Pegar en el edit de destino de envio de coins
Procedure TForm1.SBSCPasteOnClick(sender:TObject);
Begin
EditSCDest.SetFocus;
EditSCDest.Text:=Clipboard.AsText;
EditSCDest.SelStart:=length(EditSCDest.Text);
End;

// Pegar el monto maximo en su edit
Procedure TForm1.SBSCMaxOnClick(sender:TObject);
Begin
if not WO_MultiSend then EditSCMont.Text:=Int2curr(GetMaximunToSend(GetWalletBalance))
else EditSCMont.Text:=Int2Curr(GetMaximunToSend(ListaDirecciones[0].Balance-ListaDirecciones[0].pending))
End;

// verifica el destino que marca para enviar coins
Procedure Tform1.EditSCDestChange(sender:TObject);
Begin
if EditSCDest.Text = '' then ImgSCDest.Picture.Clear
else
   begin
   EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
   if ((IsValidHashAddress(EditSCDest.Text)) or (AddressSumaryIndex(EditSCDest.Text)>=0)) then
     Form1.imagenes.GetBitmap(17,ImgSCDest.Picture.Bitmap)
   else Form1.imagenes.GetBitmap(14,ImgSCDest.Picture.Bitmap);
   end;

End;

// Modificar el monto a enviar
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

// Desactiva el menu popup de un control
Procedure TForm1.DisablePopUpMenu(sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
Handled := True;
End;

// Cancelar el envio
Procedure Tform1.SCBitCancelOnClick(sender:TObject);
Begin
EditSCDest.Enabled:=true;
EditSCMont.Enabled:=true;
MemoSCCon.Enabled:=true;
SCBitSend.Visible:=true;
SCBitConf.Visible:=false;
SCBitCancel.Visible:=false;
End;

// enviar el dinero
Procedure Tform1.SCBitSendOnClick(sender:TObject);
Begin
if ( ( ((AddressSumaryIndex(EditSCDest.Text)>=0) or (IsValidHashAddress(EditSCDest.Text))) ) and
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
Procedure Tform1.SCBitConfOnClick(sender:TObject);
Begin
ProcessLinesAdd('SENDTO '+EditSCDest.Text+' '+
                          StringReplace(EditSCMont.Text,'.','',[rfReplaceAll, rfIgnoreCase])+' '+
                          MemoSCCon.Text);
ResetearValoresEnvio(sender);
End;

// Resetear los valores de envio
Procedure TForm1.ResetearValoresEnvio(sender:TObject);
Begin
EditSCDest.Enabled:=true;EditSCDest.Text:='';
EditSCMont.Enabled:=true;EditSCMont.Text:='0.00000000';
MemoSCCon.Enabled:=true;MemoSCCon.Text:='';
SCBitSend.Visible:=true;
SCBitConf.Visible:=false;
SCBitCancel.Visible:=false;
End;

// Actualizar barra de estado
Procedure UpdateStatusBar();
Begin
if Form1.Server.Active then Form1.StaSerImg.Visible:=true
else Form1.StaSerImg.Visible:=false;
Form1.StaConLab.Caption:=IntToStr(GetTotalConexiones);
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

//******************************************************************************
// MAINMENU
//******************************************************************************

// Chequea el estado de todo para actualizar los botones del menu principal
Procedure Tform1.CheckMMCaptions(sender:TObject);
var
  contador: integer;
  version : string;
  MenuItem : TMenuItem;
Begin
if Form1.Server.Active then form1.MainMenu.Items[0].Items[0].Caption:=rs0077
else form1.MainMenu.Items[0].Items[0].Caption:=rs0076;
if CONNECT_Try then form1.MainMenu.Items[0].Items[1].Caption:=rs0079
else form1.MainMenu.Items[0].Items[1].Caption:=rs0078;
End;

// menu principal conexion
Procedure Tform1.MMConnect(sender:TObject);
Begin
if CONNECT_Try then ProcessLinesAdd('disconnect')
else ProcessLinesAdd('connect');
End;

// menu principal importar cartera
Procedure Tform1.MMImpWallet (sender:TObject);
Begin
ShowExplorer(GetCurrentDir,'Import Wallet','*.pkw','impwallet (-resultado-)',true);
End;

// menu principal exportar cartera
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

// Abrir pagina web
Procedure TForm1.MMVerWeb(sender:TObject);
Begin
OpenDocument('https://nosocoin.com');
End;

// Abrir form slots
Procedure TForm1.MMVerSlots(sender:TObject);
Begin
FormSlots.Visible:=true;
End;

//******************************************************************************
// ConsolePopUp
//******************************************************************************

// VErifica que mostrar en el consolepopup
Procedure TForm1.CheckConsolePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if MemoConsola.Text <> '' then ConsolePopUp2.Items[0].Enabled:= true
else ConsolePopUp2.Items[0].Enabled:= false;
if length(Memoconsola.SelText)>0 then ConsolePopUp2.Items[1].Enabled:= true
else ConsolePopUp2.Items[1].Enabled:= false;
End;

Procedure TForm1.ConsolePopUpClear(sender:TObject);
Begin
ProcessLinesAdd('clear');
End;

Procedure TForm1.ConsolePopUpCopy(sender:TObject);
Begin
Clipboard.AsText:= Memoconsola.SelText;
info('Copied to clipboard');
End;

//******************************************************************************
// LinePopUp
//******************************************************************************

// VErifica que mostrar en el consolepopup
Procedure TForm1.CheckConsoLinePopUp(sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if ConsoleLine.Text <> '' then ConsoLinePopUp2.Items[0].Enabled:= true
else ConsoLinePopUp2.Items[0].Enabled:= false;
if length(ConsoleLine.SelText)>0 then ConsoLinePopUp2.Items[1].Enabled:= true
else ConsoLinePopUp2.Items[1].Enabled:= false;
if length(Clipboard.AsText)>0 then ConsoLinePopUp2.Items[2].Enabled:= true
else ConsoLinePopUp2.Items[2].Enabled:= false;
End;

Procedure TForm1.ConsoLinePopUpClear(sender:TObject);
Begin
ConsoleLine.Text:='';
ConsoleLine.Setfocus;
End;

Procedure TForm1.ConsoLinePopUpCopy(sender:TObject);
Begin
Clipboard.AsText:= ConsoleLine.SelText;
info('Copied to clipboard');
End;

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

//******************************************************************************
// TrxDetails PopUp
//******************************************************************************

// Copy the Order ID to clipboard
Procedure TForm1.TrxDetailsPopUpCopyOrder(sender:TObject);
Begin
Clipboard.AsText:= GridMyTxs.Cells[4,GridMyTxs.row];
info('Order ID copied to clipboard');
End;


//******************************************************************************
// OPTIONS CONTROLS
//******************************************************************************

// WALLET

procedure TForm1.CB_WO_AutoConnectChange(sender: TObject);
begin
if not G_Launching then
  begin
   if CB_WO_AutoConnect.Checked then WO_AutoConnect := true
   else WO_AutoConnect := false ;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.CB_WO_ToTrayChange(sender: TObject);
begin
if not G_Launching then
   begin
   if CB_WO_ToTray.Checked then WO_ToTray := true
   else WO_ToTray := false ;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_MinPeersChange(sender: TObject);
begin
if not G_Launching then
   begin
   MinConexToWork := SE_WO_MinPeers.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_CTOTChange(sender: TObject);
begin
if not G_Launching then
   begin
   ConnectTimeOutTime := SE_WO_CTOT.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_RTOTChange(sender: TObject);
begin
if not G_Launching then
   begin
   ReadTimeOutTIme := SE_WO_RTOT.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_ShowOrdersChange(sender: TObject);
begin
if not G_Launching then
   begin
   ShowedOrders := SE_WO_ShowOrders.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_PosWarningChange(sender: TObject);
begin
if not G_Launching then
   begin
   WO_PosWarning := SE_WO_PosWarning.Value;
   U_DirPanel := true;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.CB_WO_AntiFreezeChange(sender: TObject);
begin
if not G_Launching then
   begin
   if CB_WO_AntiFreeze.Checked then
      begin
      WO_AntiFreeze := true;
      SE_WO_AntiFreezeTime.Enabled := true;
      end
   else
      begin
      WO_AntiFreeze := false ;
      SE_WO_AntiFreezeTime.Enabled := false;
      end;
   S_AdvOpt := true;
   end;
end;

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
      AddToLog('console','Warning: SSL files missed. Auto directive update will not work properly');

   {$ENDIF}
   end;
End;

procedure TForm1.CB_WO_MultisendChange(sender: TObject);
begin
if not G_Launching then
   begin
   if CB_WO_Multisend.Checked then WO_Multisend := true
   else WO_Multisend := false ;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_AntifreezeTimeChange(sender: TObject);
begin
if not G_Launching then
   begin
   WO_AntiFreezeTime := SE_WO_AntiFreezeTime.Value;
   S_AdvOpt := true;
   end;
end;

// RPC

procedure TForm1.CB_RPC_ONChange(sender: TObject);
begin
if not G_Launching then
   begin
   if CB_RPC_ON.Checked then SetRPCOn
   else SetRPCOff;
   end;
end;

procedure TForm1.CB_AUTORPCChange(sender: TObject);
begin
if not G_Launching then
   begin
   RPCAuto:= CB_AUTORPC.Checked;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.LE_Rpc_PortEditingDone(sender: TObject);
begin
if StrToIntDef(LE_Rpc_Port.Text,-1) <> RPCPort then
   begin
   SetRPCPort('SETRPCPORT '+LE_Rpc_Port.Text);
   LE_Rpc_Port.Text := IntToStr(RPCPort);
   S_AdvOpt := true;
   info ('New RPC port set');
   end;
end;

procedure TForm1.LE_Rpc_PassEditingDone(sender: TObject);
begin
if ((not G_Launching) and (LE_Rpc_Pass.Text<>RPCPass)) then
   begin
   setRPCpassword(LE_Rpc_Pass.Text);
   LE_Rpc_Pass.Text:=RPCPass;
   S_AdvOpt := true;
   info ('New RPC password set');
   end;
end;

procedure TForm1.CB_RPCFilterChange(sender: TObject);
begin
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
end;

procedure TForm1.ComboBoxLangChange(sender: TObject);
begin
Processlinesadd('lang '+ComboBoxLang.Text);
end;

// Draw item on combobox language
procedure TForm1.ComboBoxLangDrawItem(Control: TWinControl; Index: Integer;
  ARect: TRect; State: TOwnerDrawState);
begin
ComboBoxLang.Canvas.FillRect(ARect);
if ComboBoxLang.Items[Index] ='en' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'English');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 36);
   end;
if ComboBoxLang.Items[Index] ='es' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'Español');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 37);
   end;
if ComboBoxLang.Items[Index] ='pt' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'Português');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 61);
   end;
if ComboBoxLang.Items[Index] ='de' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'Deutsch');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 62);
   end;
if ComboBoxLang.Items[Index] ='zh' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, '中文');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 63);
   end;
if ComboBoxLang.Items[Index] ='ro' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'Română');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 65);
   end;
if ComboBoxLang.Items[Index] ='id' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'Bahasa Indonesia');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 66);
   end;
if ComboBoxLang.Items[Index] ='ru' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, 'Русский');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 67);
   end;
End;

// Adjust data panel when resizing
procedure TForm1.DataPanelResize(sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.DataPanel.Width;
form1.DataPanel.ColWidths[0]:= thispercent(20,GridWidth);
form1.DataPanel.ColWidths[1]:= thispercent(30,GridWidth);
form1.DataPanel.ColWidths[2]:= thispercent(20,GridWidth);
form1.DataPanel.ColWidths[3]:= thispercent(30,GridWidth);
end;

// Grid Addresses DrawCell
procedure TForm1.DireccionesPanelDrawCell(sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Bitmap    : TBitmap;
  myRect    : TRect;
  ColWidth : Integer;
Begin
if ( (aRow>0) and (aCol=0) and (AnsiContainsstr(GetMN_FileText,ListaDirecciones[aRow-1].Hash)) ) then
   begin
   ColWidth := (sender as TStringGrid).ColWidths[0];
   Bitmap:=TBitmap.Create;
   Imagenes.GetBitmap(68,Bitmap);
   myRect := Arect;
   myrect.Left:=ColWidth-20;
   myRect.Right := ColWidth-4;
   myrect.top:=myrect.Top+2;
   myrect.Bottom:=myrect.Top+18;
   (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
   Bitmap.free
   end;
End;

// adjust addresses grid when resizing
procedure TForm1.DireccionesPanelResize(sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.DireccionesPanel.Width;
form1.DireccionesPanel.ColWidths[0]:= thispercent(68,GridWidth);
form1.DireccionesPanel.ColWidths[1]:= thispercent(32,GridWidth, true);
end;

// adjust grid nodes when resizing
procedure TForm1.GridNodesResize(sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.GridNodes.Width;
form1.GridNodes.ColWidths[0]:= thispercent(36,GridWidth);
form1.GridNodes.ColWidths[1]:= thispercent(64,GridWidth,true);
form1.GridNodes.ColWidths[2]:= thispercent(0,GridWidth);
form1.GridNodes.ColWidths[3]:= thispercent(0,GridWidth);
form1.GridNodes.ColWidths[4]:= thispercent(0,GridWidth, true);

end;

// adjust LTC grid
procedure TForm1.GridExLTCResize(sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.GridExLTC.Width;
form1.GridExLTC.ColWidths[0]:= thispercent(34,GridWidth);
form1.GridExLTC.ColWidths[1]:= thispercent(33,GridWidth);
form1.GridExLTC.ColWidths[2]:= thispercent(33,GridWidth,true);
end;

procedure TForm1.SG_MonitorResize(sender: TObject);
var
  GridWidth : integer;
Begin
GridWidth := form1.SG_Monitor.Width;
form1.SG_Monitor.ColWidths[0]:= thispercent(40,GridWidth);
form1.SG_Monitor.ColWidths[1]:= thispercent(20,GridWidth);
form1.SG_Monitor.ColWidths[2]:= thispercent(20,GridWidth);
form1.SG_Monitor.ColWidths[3]:= thispercent(20,GridWidth,true);
End;

// Fill the transaction details when Tab is selected
procedure TForm1.TabHistoryShow(sender: TObject);
begin
GridMyTxsSelection(form1,GridMyTxs.Col,GridMyTxs.Row)
end;

// Load Masternode options when TAB is selected
procedure TForm1.TabNodeOptionsShow(sender: TObject);
begin
CBAutoIP.checked:=MN_AutoIP;
CheckBox4.Checked:=WO_AutoServer;
LabeledEdit5.Text:=MN_IP;
LabeledEdit5.visible:=not MN_AutoIP;
LabeledEdit6.Text:=MN_Port;
LabeledEdit8.Text:=MN_Funds;
LabeledEdit9.Text:=MN_Sign;
end;

procedure TForm1.TabSheet9Resize(sender: TObject);
begin
  ImageOptionsAbout.BorderSpacing.Left:=
    (TabSheet9.ClientWidth div 2) -
    (ImageOptionsAbout.Width div 2);
  BitBtnWeb.BorderSpacing.Left:=
    (TabSheet9.ClientWidth div 2) -
    (BitBtnWeb.Width div 2);
  BitBtnDonate.BorderSpacing.Left:=
    (TabSheet9.ClientWidth div 2) -
    (BitBtnDonate.Width div 2);
end;

// Save Node options
procedure TForm1.BSaveNodeOptionsClick(sender: TObject);
begin
WO_AutoServer:=CheckBox4.Checked;
MN_IP:=Trim(LabeledEdit5.Text);
MN_Port:=Trim(LabeledEdit6.Text);
MN_Funds:=Trim(LabeledEdit8.Text);
MN_Sign:=Trim(LabeledEdit9.Text);
MN_AutoIP:=CBAutoIP.Checked;
S_AdvOpt := true;
if not WO_AutoServer and form1.Server.Active then processlinesadd('serveroff');
if WO_AutoServer and not form1.Server.Active then processlinesadd('serveron');
info('Masternode options saved');
end;

// Test master node configuration
procedure TForm1.BTestNodeClick(sender: TObject);
var
  Client : TidTCPClient;
  LineResult : String = '';
  ServerActivated : boolean = false;
  IPToUse : String;
Begin
if DireccionEsMia(LabeledEdit9.Text) < 0 then
   begin
   info(rs0081); // Invalid sign address
   exit;
   end;
if GetAddressBalance(LabeledEdit8.Text) < GetStackRequired(MylastBlock) then
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
   ToExcLog('Error testing masternode: '+E.Message);
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

// Execute new doctor
procedure TForm1.ButStartDoctorClick(sender: TObject);
begin
StopDoctor := false;
ButStartDoctor.Visible:=false;
ButStopDoctor.Visible:=true;
NewDoctor;
end;

// Stop new doctor execution
procedure TForm1.ButStopDoctorClick(sender: TObject);
begin
StopDoctor := true;
end;

procedure TForm1.Button1Click(sender: TObject);
Begin
MemoLog.Lines.Clear;
End;

procedure TForm1.Button2Click(sender: TObject);
Begin
MemoExceptLog.Lines.Clear;
End;

procedure TForm1.CBRunNodeAloneChange(sender: TObject);
begin
WO_OmmitMemos:= CBRunNodeAlone.Checked;
end;

// Enable/Disable current job label
procedure TForm1.CB_CurrentjobChange(sender: TObject);
Begin
if Not CB_Currentjob.Checked then CB_Currentjob.Caption:='Disabled';
End;

// Set MN IP to Auto
procedure TForm1.CBAutoIPClick(sender: TObject);
Begin
if CBAutoIP.Checked then LabeledEdit5.Visible:=false
else LabeledEdit5.Visible:=true;
End;

// Enable/Disable download the whole blockchain
procedure TForm1.CB_FullNodeChange(sender: TObject);
Begin
if not G_Launching then
   begin
   if CB_FullNode.Checked then
      begin
      WO_FullNode := true;
      end
   else
      begin
      WO_FullNode := false ;
      end;
   S_AdvOpt := true;
   end;
End;

// adjust transactions history grid when resize
procedure TForm1.GridMyTxsResize(sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.GridMyTxs.Width;
form1.GridMyTxs.ColWidths[0]:= thispercent(20,GridWidth);
form1.GridMyTxs.ColWidths[1]:= thispercent(20,GridWidth);
form1.GridMyTxs.ColWidths[2]:= thispercent(25,GridWidth);
form1.GridMyTxs.ColWidths[3]:= thispercent(35,GridWidth,true);
end;

// Adjust grid with PoS information at resize
procedure TForm1.GridPoSResize(sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.GridPoS.Width;
form1.GridPoS.ColWidths[0]:= thispercent(50,GridWidth);
form1.GridPoS.ColWidths[1]:= thispercent(50,GridWidth);
End;

// Resize GVTs grid
procedure TForm1.GVTsGridResize(sender: TObject);
var
  GridWidth : integer;
Begin
GridWidth := form1.GVTsGrid.Width;
form1.GVTsGrid.ColWidths[0]:= thispercent(20,GridWidth);
form1.GVTsGrid.ColWidths[1]:= thispercent(80,GridWidth,true);
End;

// Update my GVTsList
Procedure UpdateMyGVTsList();
var
  counter : integer;
  Owned   : integer = 0;
Begin
form1.GVTsGrid.RowCount:=1;
EnterCriticalSection(CSGVTsArray);
for counter := 0 to length(ArrGVTs)-1 do
   begin
   if DireccionEsMia(ArrGVTs[counter].owner) >= 0 then
      begin
      form1.GVTsGrid.RowCount:=form1.GVTsGrid.RowCount+1;
      form1.GVTsGrid.Cells[0,form1.GVTsGrid.RowCount-1] := ArrGVTs[counter].number;
      form1.GVTsGrid.Cells[1,form1.GVTsGrid.RowCount-1] := ArrGVTs[counter].owner;
      Inc(Owned);
      end;
   end;
LeaveCriticalSection(CSGVTsArray);
Form1.TabGVTs.TabVisible:= Owned>0;
End;

// Transfer GVT button
procedure TForm1.SCBitSend1Click(sender: TObject);
Begin
if GVTsGrid.Row > 0 then
   ProcessLinesAdd('sendgvt '+GVTsGrid.Cells[0,GVTsGrid.Row]+' '+edit2.Text);
End;

// Adjust the trxdetails when a selection is done
procedure TForm1.GridMyTxsSelection(sender: TObject; aCol, aRow: Integer);
var
  cont : integer;
  extratext :string = '';
  referencetoshow : string = '';
Begin
if GridMyTxs.Row>0 then
   begin
   PanelTrxDetails.visible := true;
   MemoTrxDetails.Lines.Clear;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'TRFR' then
      Begin
      if GridMyTxs.Cells[10,GridMyTxs.Row] = 'YES' then // Own transaction'
        extratext :=' (OWN)'; //' (OWN)'
      if GridMyTxs.Cells[7,GridMyTxs.Row] <> 'null' then
         referencetoshow := GridMyTxs.Cells[7,GridMyTxs.Row];
      MemoTrxDetails.Text:=
      GridMyTxs.Cells[4,GridMyTxs.Row]+SLINEBREAK+                    //order ID
      'Receiver : '+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+      //'Receiver : '
      'Ammount  : '+GridMyTxs.Cells[3,GridMyTxs.Row]+extratext+SLINEBREAK+  //'Ammount  : '
      'Reference : '+referencetoshow+SLINEBREAK+    //'reference  : '
      'Transfers: '+GridMyTxs.Cells[9,GridMyTxs.Row]+SLINEBREAK+      //'Transfers: '
      GetCommand(GridMyTxs.Cells[8,GridMyTxs.Row])+SLINEBREAK;
      if StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1)> 1 then // añadir mas trfids
         for cont := 2 to StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1) do
           MemoTrxDetails.lines.add(parameter(GridMyTxs.Cells[8,GridMyTxs.Row],cont-1));
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'MINE' then
      Begin
      MemoTrxDetails.Text:=
      'Mined    : '+GridMyTxs.Cells[0,GridMyTxs.Row]+SLINEBREAK+ //'Mined    : '
      'Receiver : '+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+   //'Receiver : '
      'Ammount  : '+GridMyTxs.Cells[3,GridMyTxs.Row];   //'Ammount  : '
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'CUSTOM' then
      Begin
      MemoTrxDetails.Text:=
      'Address customization'+SLINEBREAK+                   //'Address customization'
      'Address  : '+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Hash+SLINEBREAK+//'Address  : '
      'Alias    : '+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Custom+SLINEBREAK+//'Alias    : '
      'Amount   : '+Int2Curr(Customizationfee);
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'FEE' then
      begin
      MemoTrxDetails.Text:=
      'Maintenance fee'+SLINEBREAK+   //'Maintenance fee'
      'Address  : '+GridMyTxs.Cells[6,GridMyTxs.Row]+SLINEBREAK+  //'Address  : '
      'Interval : '+GridMyTxs.Cells[7,GridMyTxs.Row]+SLINEBREAK+  //'Interval : '
      'Ammount  : '+GridMyTxs.Cells[3,GridMyTxs.Row]; //'Ammount  : '
      if GridMyTxs.Cells[8,GridMyTxs.Row] = 'YES' then
        MemoTrxDetails.Text:= MemoTrxDetails.Text+' (Address deleted from summary)';//' (Address deleted from summary)'
      end;
   MemoTrxDetails.SelStart:=0;
   end;
End;

procedure TForm1.MemoRPCWhitelistEditingDone(sender: TObject);
var
  newlist : string;
begin
if ( (not G_Launching) and (MemoRPCWhitelist.Text<>RPCWhitelist) ) then
   begin
   newlist := trim(MemoRPCWhitelist.Text);
   newlist := parameter(newlist,0);
   MemoRPCWhitelist.Text := newlist;
   RPCWhitelist := newlist;
   S_AdvOpt := true;
   end;
end;

Procedure TForm1.CheckClipboardForPays();
var
  Intexto : string = '';
Begin
Intexto := Clipboard.AsText;
If (parameter(InTexto,0)) ='<NOSOPAY>' then
   begin
   form1.PageMain.ActivePage := form1.tabwallet;
   form1.tabwalletmain.ActivePage:=form1.TabAddresses;
   EditSCDest.Text:=parameter(InTexto,1);
   EditSCMont.Text:=int2curr(StrToIntDef(parameter(InTexto,2),0));
   MemoSCCon.Text:=parameter(InTexto,3);;
   form1.BringToFront;
   Clipboard.AsText := '';
   end;
End;

END. // END PROGRAM

