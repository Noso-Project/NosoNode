unit MasterPaskalForm;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, LCLType,
  Grids, ExtCtrls, Buttons, IdTCPServer, IdContext, IdGlobal, IdTCPClient,
  fileutil, Clipbrd, Menus, crt, formexplore, lclintf, ComCtrls, Spin,
  poolmanage, strutils, mpoptions, math, IdHTTPServer, IdCustomHTTPServer,
  fpJSON, Types, DefaultTranslator, LCLTranslator, translation, ubarcodes;

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

  TNobiexData = Packed Record
     Request : integer;        //1:CREATE, 2:DELETE, 3:ACCEPT, 4:CANCEL, 5:REPORT
     Id      : string[64];     //Unique ID
     FromAddress : String[50]; //Noso Address sending the request
     ToAddress   : String[50]; //Noso address buying
     Ammount : int64;
     Market : String[4];
     Price  : int64;
     Total  : int64;
     Fee    : int64;
     Locked : int64;            //Total nosos locked on selling address
     Wait : int64;              //Max number of blocks to wait for payment
     PayAddress : String[120];  //External crypto address receiving the payment
     Block : int64;
     PublicKey : string[120];
     Signature  : String[120];
     Status : integer;          //1:OPEN, 2:DEAL, 3: PAID, 4:DONE
     Verificator  : String[32]; //Unique ID of the escrow service
     end;

  BotData = Packed Record
     ip: string[15];
     LastRefused : string[17];
     end;

  TPoolBot = Packed Record
     ip: string[15];
     Last : int64;
     count : integer;
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
     Reference : String[64];
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
     reference : String[64];
     end;

  MilitimeData = Packed Record
     Name : string[255];
     Start : int64;
     finish : int64;
     duration : int64;
     Maximo : int64;
     Minimo : int64;
     Count : int64;
     Total : int64;
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
    BarcodeQR1: TBarcodeQR;
    BQRCode: TSpeedButton;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    BSaveNodeOptions: TBitBtn;
    BitBtnPending: TBitBtn;
    BitBtnBlocks: TBitBtn;
    CheckBox2: TCheckBox;
    ComboBoxLang: TComboBox;
    Label1: TLabel;
    Label7: TLabel;
    PanelBlocks: TPanel;
    PanelQRImg: TPanel;
    PanelPostOffer: TPanel;
    StaRPCimg: TImage;
    StaSerImg: TImage;
    StaConLab: TLabel;
    StaPoolSer: TImage;
    Imgs32: TImageList;
    ImgRotor: TImage;
    TextQRcode: TStaticText;
    StaTimeLab: TLabel;
    SCBitSend: TBitBtn;
    SCBitClea: TBitBtn;
    CB_AUTORPC: TCheckBox;
    CB_WO_AutoConnect: TCheckBox;
    CB_WO_ToTray: TCheckBox;
    CheckBox1: TCheckBox;
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
    Image2: TImage;
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
    LE_Rpc_Port: TLabeledEdit;
    LE_Rpc_Pass: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit8: TLabeledEdit;
    LabeledEdit9: TLabeledEdit;
    Latido : TTimer;
    InfoTimer : TTimer;
    InicioTimer : TTimer;
    CloseTimer : TTimer;
    ConnectButton: TSpeedButton;
    MainMenu: TMainMenu;
    MemoSCCon: TMemo;
    MemoTrxDetails: TMemo;
    MemoConsola: TMemo;
    DataPanel: TStringGrid;
    MenuItem1: TMenuItem;
    MenuItem10: TMenuItem;
    MenuItem11: TMenuItem;
    MenuItem12: TMenuItem;
    MenuItem13: TMenuItem;
    MenuItem14: TMenuItem;
    MenuItem15: TMenuItem;
    MenuItem16: TMenuItem;
    MenuItem17: TMenuItem;
    MenuItem18: TMenuItem;
    MenuItem19: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem20: TMenuItem;
    MenuItem21: TMenuItem;
    MenuItem22: TMenuItem;
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
    PoolPanelBlink: TPanel;
    PCPool: TPageControl;
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
    PoolServer : TIdTCPServer;
    RPCServer : TIdHTTPServer;
    SE_WO_AntifreezeTime: TSpinEdit;
    SE_WO_RTOT: TSpinEdit;
    SE_WO_MinPeers: TSpinEdit;
    SE_WO_CTOT: TSpinEdit;
    SE_WO_ShowOrders: TSpinEdit;
    SE_WO_PosWarning: TSpinEdit;
    SG_PoolMiners: TStringGrid;
    SG_PoolStats: TStringGrid;
    SG_Monitor: TStringGrid;
    GridExLTC: TStringGrid;
    SystrayIcon: TTrayIcon;
    tabOptions: TTabSheet;
    TabSheet1: TTabSheet;
    TabSheet10: TTabSheet;
    TabNodeOptions: TTabSheet;
    TabSheet3: TTabSheet;
    TabPoolLog: TTabSheet;
    TabPoolPays: TTabSheet;
    TabSheet5: TTabSheet;
    TabExchange: TTabSheet;
    TabMonitor: TTabSheet;
    tabExBuy: TTabSheet;
    TabSheet6: TTabSheet;
    TabSheet7: TTabSheet;
    TabSheet8: TTabSheet;
    TabMainPool: TTabSheet;
    TabPoolMiners: TTabSheet;
    TabPoolStats: TTabSheet;
    TabMonitorMonitor: TTabSheet;
    TabSheet9: TTabSheet;
    TabWallet: TTabSheet;
    TabConsole: TTabSheet;

    procedure BarcodeQR1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure BQRCodeClick(Sender: TObject);
    procedure BSaveNodeOptionsClick(Sender: TObject);
    procedure CB_RPCFilterChange(Sender: TObject);
    procedure ComboBoxLangChange(Sender: TObject);
    procedure ComboBoxLangDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure DataPanelResize(Sender: TObject);
    procedure DireccionesPanelResize(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormWindowStateChange(Sender: TObject);
    procedure GridMyTxsResize(Sender: TObject);
    procedure GridMyTxsSelection(Sender: TObject; aCol, aRow: Integer);
    procedure GridPoSResize(Sender: TObject);
    procedure LE_Rpc_PassEditingDone(Sender: TObject);
    Procedure LoadOptionsToPanel();
    procedure FormShow(Sender: TObject);
    Procedure InicoTimerEjecutar(Sender: TObject);
    procedure MemoRPCWhitelistEditingDone(Sender: TObject);
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
    procedure SE_WO_AntifreezeTimeChange(Sender: TObject);
    procedure GridExLTCResize(Sender: TObject);
    procedure TabHistoryShow(Sender: TObject);
    procedure TabNodeOptionsShow(Sender: TObject);
    Procedure TryCloseServerConnection(AContext: TIdContext; closemsg:string='');
    procedure IdTCPServer1Execute(AContext: TIdContext);
    procedure IdTCPServer1Connect(AContext: TIdContext);
    procedure IdTCPServer1Disconnect(AContext: TIdContext);
    procedure IdTCPServer1Exception(AContext: TIdContext;AException: Exception);
    Procedure DoubleClickSysTray(Sender: TObject);
    Procedure ConnectCircleOnClick(Sender: TObject);
    Procedure GridMyTxsOnDoubleClick(Sender: TObject);
    Procedure BitPosInfoOnClick (Sender: TObject);
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
    Procedure CheckClipboardForPays();
    // Pool
    Procedure TryClosePoolConnection(AContext: TIdContext; closemsg:string='');
    Procedure TryMessageToMiner(AContext: TIdContext;message:string);
    Function UpdatePoolBot(ipuser:string):integer;
    function PoolClientsCount : Integer ;
    procedure PoolServerConnect(AContext: TIdContext);
    procedure PoolServerExecute(AContext: TIdContext);
    procedure PoolServerDisconnect(AContext: TIdContext);
    procedure PoolServerException(AContext: TIdContext;AException: Exception);
    // RPC
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
    Procedure MMRestart(Sender:TObject);
    Procedure MMChangeLang(Sender:TObject);
    Procedure MMRunUpdate(Sender:TObject);
    Procedure MMImpLang(Sender:TObject);
    Procedure MMNewLang(Sender:TObject);
    Procedure MMVerConsola(Sender:TObject);
    Procedure MMVerWeb(Sender:TObject);
    Procedure MMVerSlots(Sender:TObject);
    Procedure MMVerPool(Sender:TObject);

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
    Procedure TrxDetailsPopUpCopyOrder(Sender:TObject);


    // OPTIONS
      // WALLET
    procedure CB_WO_AutoConnectChange(Sender: TObject);
    procedure CB_WO_ToTrayChange(Sender: TObject);
    procedure SE_WO_MinPeersChange(Sender: TObject);
    procedure SE_WO_CTOTChange(Sender: TObject);
    procedure SE_WO_RTOTChange(Sender: TObject);
    procedure SE_WO_ShowOrdersChange(Sender: TObject);
    procedure SE_WO_PosWarningChange(Sender: TObject);
    procedure CB_WO_AntiFreezeChange(Sender: TObject);
    procedure CB_WO_MultisendChange(Sender: TObject);
      // RPC
    procedure CB_RPC_ONChange(Sender: TObject);
    procedure CB_AUTORPCChange(Sender: TObject);
    procedure LE_Rpc_PortEditingDone(Sender: TObject);

  private

  public

  end;

Procedure InicializarFormulario();
Procedure CerrarPrograma();
Procedure UpdateStatusBar();
Procedure GenerateCode();

CONST
  HexAlphabet : string = '0123456789ABCDEF';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  ReservedWords : string = 'NULL,DELADDR';
  ValidProtocolCommands : string = '$PING$PONG$GETPENDING$NEWBL$GETRESUMEN$LASTBLOCK'+
                                   '$CUSTOMORDERADMINMSGNETREQ';
  HideCommands : String = 'CLEAR SENDPOOLSOLUTION SENDPOOLSTEPS POOLHASHRATE';
  CustomValid : String = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890@*+-_:';
  DefaultNodes : String = 'DefNodes '+
                            '45.146.252.103 '+
                            '194.156.88.117 '+
                            '192.210.226.118 '+
                            '107.172.5.8 '+
                            '185.239.239.184 '+
                            '109.230.238.240';
  ProgramVersion = '0.2.1';
  SubVersion = 'Jc7';
  OficialRelease = true;
  BuildDate = 'December 2021';
  ADMINHash = 'N4PeJyqj8diSXnfhxSQdLpo8ddXTaGd';
  AdminPubKey = 'BL17ZOMYGHMUIUpKQWM+3tXKbcXF0F+kd4QstrB0X7iWvWdOSrlJvTPLQufc1Rkxl6JpKKj/KSHpOEBK+6ukFK4=';
  HasheableChars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
  DefaultServerPort = 8080;
  MaxConecciones  = 50;
  Protocolo = 1;
  Miner_Steps = 10;
  Pool_Max_Members = 1000;
  DefaultDonation = 50;
  // Custom values for coin
  SecondsPerBlock = 600;            // 10 minutes
  PremineAmount = 1030390730000;    // 1030390730000;
  InitialReward = 5000000000;       // Initial reward
  BlockHalvingInterval = 210000;    // 210000;
  HalvingSteps = 10;                // total number of halvings
  Comisiontrfr = 10000;             // ammount/Comisiontrfr = 0.01 % of the ammount
  ComisionCustom = 200000;          // 0.05 % of the Initial reward
  CoinSimbol = 'NOSO';               // Coin 3 chars
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
  InitialBlockDiff = 60;            // Dificultad durante los 20 primeros bloques
  GenesysTimeStamp = 1615132800;    // 1615132800;
  FileFormatVer = 'NFF2';
  NPLS = '<NOS>';
  NPLE = '<END>';
  AvailableMarkets = '/LTC';

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
  WO_AutoServer    : boolean = false;
  WO_ToTray        : boolean = false;
  MinConexToWork   : integer = 1;
  WO_PosWarning    : int64 = 7;
  WO_AntiFreeze    : boolean = true;
  WO_MultiSend     : boolean = false;
  WO_AntifreezeTime: integer = 10;
  WO_Language      : string = 'en';
    WO_LastPoUpdate: string = ProgramVersion+Subversion;
  RPCFilter        : boolean = true;
  RPCWhitelist     : string = '127.0.0.1,localhost';
  RPCAuto          : boolean = false;
  MN_IP            : string = 'localhost';
  MN_Port          : string = '8080';
  MN_Funds         : string = '';
  MN_Sign          : string = '';

  SynchWarnings : integer = 0;
  ConnectedRotor : integer = 0;
  EngineLastUpdate : int64 = 0;

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
  //Memoconsola : Tmemo;
  //ConsoleLine : TEdit;
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
  //DataPanel : TStringGrid;
    U_DataPanel : boolean = true;
  //LabelBigBalance : TLabel;
    U_PoSGrid : Boolean = true;
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
  NewExclogLines : integer = 0;
  Conexiones : array [1..MaxConecciones] of conectiondata;
  SlotLines : array [1..MaxConecciones] of TStringList;
  CanalCliente : array [1..MaxConecciones] of TIdTCPClient;
    PoolClientLastPing : int64;
  PoolClientContext : TIdContext;
  ListadoBots :  array of BotData;
  ListaNodos : array of NodeData;
  ListaPoolBots : array of TPoolBot;
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
     LastTryServerOn : Int64 = 0;
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
  Miner_RestartedSolution : string = '';

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
  CSPoolStep    : TRTLCriticalSection; InsidePoolStep:Boolean;
  CSPoolPay     : TRTLCriticalSection;
  CSHeadAccess  : TRTLCriticalSection;
  CSBlocksAccess: TRTLCriticalSection;
  CSSumary      : TRTLCriticalSection;
  CSPending     : TRTLCriticalSection;
  CSCriptoThread: TRTLCriticalSection;
  CSPoolMembers : TRTLCriticalSection;
  CSMinerJoin   : TRTLCriticalSection; InsideMinerJoin:Boolean;
  CSLogLines    : TRTLCriticalSection;
  CSExcLogLines : TRTLCriticalSection;
  CSPoolShares  : TRTLCriticalSection;

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
  MarksDirectory : string = '';
  UpdatesDirectory : string = '';
  LanguagesDirectory : String = '';
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
  MontoIncoming : Int64 = 0;
  MontoOutgoing : Int64 = 0;
  U_Mytrxs: boolean = false;
  LastMyTrxTimeUpdate : int64;
  InfoPanelTime : integer = 0;
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
            ToExcLog(Format(rs0001,[conexiones[Fslot].ip]));
            //ToExcLog('TimeOut reading from slot: '+conexiones[Fslot].ip);
            TruncateLine := TruncateLine+LLine;
            Conexiones[fSlot].IsBusy:=false;
            continue;
            end;
         Except on E:Exception do
            begin
            ToExcLog(Format(rs0002,[IntToStr(Fslot)+slinebreak+E.Message]));
            //tolog ('Error Reading lines from slot: '+IntToStr(Fslot)+slinebreak+E.Message);
            Conexiones[fSlot].IsBusy:=false;
            continue;
            end;
         end;
      if continuar then
         begin
         if GetCommand(LLine) = 'RESUMENFILE' then
            begin
            EnterCriticalSection(CSHeadAccess);
            ConsoleLinesadd(rs0003);
            //ConsoleLinesadd('Receiving headers');
            DownloadHeaders := true;
               try
               AFileStream := TFileStream.Create(ResumenFilename, fmCreate);
               CanalCliente[FSlot].ReadTimeout:=0;
                  try
                  CanalCliente[FSlot].IOHandler.ReadStream(AFileStream);
                  Except on E:Exception do
                     begin
                     toExcLog(format(rs0004,[conexiones[fSlot].ip,E.Message]));
                     //toExcLog(format('Error Receiving headers from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                     consolelinesadd(format(rs0004,[conexiones[fSlot].ip,E.Message]));
                     //consolelinesadd(format('Error Receiving headers from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                     end;
                  end;
               finally
               AFileStream.Free;
               DownloadHeaders := false;
               LeaveCriticalSection(CSHeadAccess);
               end;
            consolelinesAdd(format(rs0005,[copy(HashMD5File(ResumenFilename),1,5)]));
            //consolelinesAdd(LAngLine(74)+': '+copy(HashMD5File(ResumenFilename),1,5)); //'Headers file received'
            LastTimeRequestResumen := 0;
            UpdateMyData();
            end
         else if LLine = 'BLOCKZIP' then
            begin
            ConsoleLinesadd(rs0006);
            //ConsoleLinesadd('Receiving blocks');
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
                     ConsoleLinesadd(format(rs0007,[conexiones[fSlot].ip,E.Message]));
                     //consolelinesadd(format('Error Receiving blocks from %s (%s)',[conexiones[fSlot].ip,E.Message]));
                     end;
                  end;
               finally
               AFileStream.Free;
               end;
            UnzipBlockFile(BlockDirectory+'blocks.zip',true);
            MyLastBlock := GetMyLastUpdatedBlock();
            ConsoleLinesadd(format(rs0021,[IntToStr(MyLastBlock)]));
            //consolelinesadd('Blocks received up to '+IntToStr(MyLastBlock));
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
             ToExclog(format(rs0008,[E.Message]));
            //ToExclog('Error sending outgoing message: '+E.Message);
         end;
      end;
   if OutgoingMsjs.Count > 0 then
      begin
      EnterCriticalSection(CSOutgoingMsjs);
         try
         OutgoingMsjs.Delete(0);
         Except on E:Exception do
            begin
            ToExcLog(format(rs0009,[E.Message]));
            //ToExcLog('ERROR: Deleting OutGoingMessage-> '+E.Message);
            end;
         end;
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
InitCriticalSection(CSLogLines);
InitCriticalSection(CSExcLogLines);
InitCriticalSection(CSPoolShares);

CreateFormInicio();
CreateFormSlots();
CreateFormPool();
Setlength(ListaPoolBots,0);
//SetLength(ListaMisTrx,0); destroy?
end;

// Form destroy
procedure TForm1.FormDestroy(Sender: TObject);
var
  contador : integer;
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
DoneCriticalSection(CSLogLines);
DoneCriticalSection(CSExcLogLines);
DoneCriticalSection(CSPoolShares);

form1.Server.Free;
form1.RPCServer.Free;
form1.PoolServer.free;

end;

// RESIZE MAIN FORM (Lot of things to add here)
procedure TForm1.FormResize(Sender: TObject);
begin
infopanel.Left:=(Form1.Width div 2)-150;
infopanel.Top:=((Form1.Height-560) div 2)+245;
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
StaTimeLab.Caption:=TimestampToDate(UTCTime)+' ('+IntToStr(UTCTime.ToInt64-EngineLastUpdate)+')';
//StaTimeLab.Update;
if ((UTCTime.ToInt64 > EngineLastUpdate+WO_AntiFreezeTime) and (WO_AntiFreeze)) then
   begin
   info(rs0010); //'Auto restart enabled'
   delay(100);
   CrearBatFileForRestart();
   info(rs0011); //'BAT file created'
   delay(100);
   AutoRestarted := true;
   CrearCrashInfo();
   info(rs0012); //'Crash info file created'
   delay(100);
   CrearRestartfile();
   info(rs0013); //'Data restart file created'
   delay(100);
   CloseAllforms();
   info(rs0014); //'All forms closed'
   delay(100);
   CerrarClientes();
   info(rs0015); //'Outgoing connections closed'
   //delay(100);
   //StopServer();
   //This line is for testing purposes
   //form1.Server.Free;
   info(rs0016); //'Node server closed'
   delay(100);
   info(rs0017); //'Closing pool server...'
   StopPoolServer();
   info(rs0018); //'Pool server closed'
   delay(100);
   if length(ArrayPoolMembers)>0 then
      begin
      GuardarPoolMembers();
      info(rs0019); //'Pool members file saved'
      delay(100);
      end;
   RunExternalProgram('nosolauncher.bat');
   info(rs0020); //'Noso launcher executed'
   delay(500);
   form1.close;
   end
else RestartTimer.Enabled:=true;
End;

// Ejecuta todo el proceso de carga y lo muestra en el form inicio
Procedure TForm1.EjecutarInicio();
var
  contador : integer;
  LastRelease : String = '';
Begin
// Check last release
OutText(rs0071,false,1); // Checking last release available...
LastRelease := GetLastRelease;
if lastrelease <> '' then // Data retrieved
   begin
   if Parameter(lastrelease,0)+Parameter(lastrelease,1) = ProgramVersion+Subversion then
      begin
      gridinicio.RowCount:=gridinicio.RowCount-1;
      OutText(rs0073,false,1);
      end
   else if Parameter(lastrelease,0)+Parameter(lastrelease,1) > ProgramVersion+Subversion then
      begin // new version available
      gridinicio.RowCount:=gridinicio.RowCount-1;
      OutText(rs0074,false,1);
      ShowMessage(rs0074);
      // If option is active, download the new release here
      end
   else
      begin
      gridinicio.RowCount:=gridinicio.RowCount-1;
      OutText(rs0075,false,1);
      end;
   end
else // Error retrieving last release data
   begin
   gridinicio.RowCount:=gridinicio.RowCount-1;
   OutText(rs0072,false,1);
   end;
InitCrossValues();
// A partir de aqui se inicializa todo
if not directoryexists('NOSODATA') then CreateDir('NOSODATA');
OutText(rs0022,false,1); //'✓ Data directory ok'
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
OutText(rs0023,false,1); //✓ GUI initialized
VerificarArchivos();
InicializarGUI();
InitTime();
UpdateMyData();
OutText(rs0024,false,1); //'✓ My data updated'
ResetMinerInfo();
OutText(rs0025,false,1); //'✓ Miner configuration set'
// Ajustes a mostrar
LoadOptionsToPanel();
form1.Caption:=coinname+format(rs0027,[ProgramVersion,SubVersion]);
Application.Title := coinname+format(rs0027,[ProgramVersion,SubVersion]);   // Wallet
OutText(format(rs0026,[IntToStr(IdiomasDisponibles.count)]),false,1); //'✓ %s languages available'
ConsoleLinesAdd(coinname+format(rs0027,[ProgramVersion,SubVersion]));
OutText(rs0066,false,1); // Rebuilding my transactions
RebuildMyTrx(MyLastBlock);
gridinicio.RowCount:=gridinicio.RowCount-1;
OutText(rs0067,false,1); // '✓ My transactions rebuilded';
UpdateMyTrxGrid();
OutText(rs0068,false,1); // '✓ My transactions grid updated';
if useroptions.JustUpdated then
   begin
   ConsoleLinesAdd(LangLine(19)+ProgramVersion);  // Update to version sucessfull:
   useroptions.JustUpdated := false;
   S_Options := true;
   OutText('✓ Just updated to a new version',false,1);
   end;
if fileexists('nosolauncher.bat') then
   begin
   Deletefile('nosolauncher.bat');
   OutText(rs0069,false,1); // '✓ Launcher file deleted';
   end;
if fileexists('restart.txt') then
   begin
   RestartConditions();
   OutText(rs0070,false,1); // '✓ Restart file deleted';
   end;
if GetEnvironmentVariable('NUMBER_OF_PROCESSORS') = '' then G_CpuCount := 1
else G_CpuCount := StrToIntDef(GetEnvironmentVariable('NUMBER_OF_PROCESSORS'),1);
G_CpuCount := 1;
G_MiningCPUs := G_CpuCount;
OutText(format(rs0028,[inttostr(G_CpuCount)]),false,1);
StringAvailableUpdates := AvailableUpdates();
Form1.Latido.Enabled:=true;
G_Launching := false;
OutText('Noso is ready',false,1);
//if UserOptions.AutoServer then ProcessLinesAdd('SERVERON');
//if UserOptions.AutoServer then KeepServerOn := true;
if WO_autoserver then KeepServerOn := true;
if WO_AutoConnect then ProcessLinesAdd('CONNECT');
//if RPCAuto then  ProcessLinesAdd('RPCON');
FormInicio.BorderIcons:=FormInicio.BorderIcons+[bisystemmenu];
FirstShow := true;
Setlength(CriptoOpsTipo,0);
Setlength(CriptoOpsOper,0);
Setlength(CriptoOpsResu,0);
Setlength(MilitimeArray,0);
Setlength(Miner_Thread,0);
SetLength(ArrayNetworkRequests,0);
SetLength(ArrPoolPays,0);

Tolog(rs0029); NewLogLines := NewLogLines-1; //'Noso session started'
info(rs0029);  //'Noso session started'
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
CB_WO_AntiFreeze.Checked:=WO_AntiFreeze;
CB_WO_Multisend.Checked:=WO_Multisend;
SE_WO_AntifreezeTime.value := WO_AntifreezeTime;
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
procedure TForm1.FormCloseQuery(Sender: TObject; var CanClose: boolean);
begin
G_CloseRequested := true;
CloseTimer.Enabled:=true;
canclose := false;
end;

// Button donate
procedure TForm1.BitBtn1Click(Sender: TObject);
begin
form1.PageMain.ActivePage := form1.TabWallet;
form1.TabWalletMain.ActivePage := form1.TabAddresses;
PanelSend.Visible:=true;
Form1.EditSCDest.Text:='devteam_donations';
Form1.EditSCMont.Text:=IntToStr(DefaultDonation)+'.00000000';
Form1.MemoSCCon.Text:='Donation';
end;

procedure TForm1.BarcodeQR1Click(Sender: TObject);
begin
form1.PanelQRImg.Visible:=false;
form1.DireccionesPanel.Enabled:=true;
end;

// visit web button
procedure TForm1.BitBtn2Click(Sender: TObject);
begin
OpenDocument('https://nosocoin.com');
end;

Procedure GenerateCode();
begin
form1.BarcodeQR1.Text:=form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
end;

procedure TForm1.BQRCodeClick(Sender: TObject);
begin
GenerateCode();
form1.DireccionesPanel.Enabled:=false;
form1.TextQRcode.caption := form1.Direccionespanel.Cells[0,form1.Direccionespanel.Row];
form1.PanelQRImg.Visible:=true;
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
   if LineText <> '' then ProcessLinesAdd(LineText);
   if Uppercase(Linetext) = 'EXIT' then
     begin
     CrearCrashInfo();
     form1.close;
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
CheckClipboardForPays();
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
if ( (KeepServerOn) and (not Form1.Server.Active) and (LastTryServerOn+5<StrToInt64(UTCTime))
      and (MyConStatus = 3) ) then
   ProcessLinesAdd('serveron');
if G_CloseRequested then CerrarPrograma();
if form1.SystrayIcon.Visible then
   form1.SystrayIcon.Hint:=Coinname+' Ver. '+ProgramVersion+SubVersion+SLINEBREAK+LabelBigBalance.Caption;
if FormSlots.Visible then UpdateSlotsGrid();
if FormPool.Visible then UpdatePoolForm();
ConnectedRotor +=1; if ConnectedRotor>6 then ConnectedRotor := 0;
UpdateStatusBar;
if ( (StrToInt64(UTCTime) mod 86400=0) and (LastBotClear<>UTCTime) and (Form1.Server.Active) ) then ProcessLinesAdd('delbot all');
Form1.Latido.Enabled:=true;
end;

//procesa el cierre de la aplicacion
Procedure CerrarPrograma();
var
  contador: integer;
Begin
CreateADV(false); // save advopt
Miner_IsOn := false;
Miner_KillThreads := true;
info(rs0030);  //   Closing wallet
if RestartNosoAfterQuit then CrearRestartfile();
CloseAllforms();
CerrarClientes();
StopServer();
StopPoolServer();
if length(ArrayPoolMembers)>0 then GuardarPoolMembers();
If Miner_IsOn then Miner_IsON := false;
//KillAllMiningThreads;
setlength(CriptoOpsTipo,0);
if RunDoctorBeforeClose then RunDiagnostico('rundiag fix');
if RestartNosoAfterQuit then restartnoso();
form1.Close;

StringListLang.Free;
ConsoleLines.Free;
DLSL.Free;
IdiomasDisponibles.Free;
LogLines.Free;
ExceptLines.Free;
ProcessLines.Free;
OutgoingMsjs.Free;
PoolPaysLines.free;
for contador := 1 to maxconecciones do
   SlotLines[contador].Free;

Halt;
End;

// Run time creation of form components
Procedure InicializarFormulario();
var
  contador : integer = 0;
Begin
// BY GUS: Make sure TabWallet is always the one shown at start
Form1.PageMain.ActivePage:= Form1.TabWallet;

// Visual components

// Resize all grids at launch
Form1.GridPoSResize(nil);
Form1.GridPoS.Cells[0,0] := rs0063;
Form1.GridPoS.Cells[0,1] := rs0064;
Form1.GridPoS.Cells[0,2] := rs0065;
form1.GridPoS.FocusRectVisible:=false;


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

// Pre-designed elements adjustments
form1.SG_PoolMiners.Font.Name:='consolas'; form1.SG_PoolMiners.Font.Size:=8;
form1.SG_PoolMiners.ScrollBars:=ssBoth;
form1.SG_PoolMiners.FocusRectVisible:=false;
form1.SG_PoolMiners.Options:= form1.SG_PoolMiners.Options+[goRowSelect]-[goRangeSelect];
form1.SG_PoolMiners.ColWidths[0]:= 50;form1.SG_PoolMiners.ColWidths[1]:= 24;
form1.SG_PoolMiners.ColWidths[2]:= 32;form1.SG_PoolMiners.ColWidths[3]:= 80;
form1.SG_PoolMiners.ColWidths[4]:= 30;form1.SG_PoolMiners.ColWidths[5]:= 50;
form1.SG_PoolMiners.ColWidths[6]:= 50;form1.SG_PoolMiners.ColWidths[7]:= 90;
form1.SG_PoolMiners.ColWidths[8]:= 50;
form1.SG_PoolMiners.Cells[0,0]:='Address';form1.SG_PoolMiners.Cells[1,0]:='Pre';
form1.SG_PoolMiners.Cells[2,0]:='Get';form1.SG_PoolMiners.Cells[3,0]:='Earned';
form1.SG_PoolMiners.Cells[4,0]:='Ping';form1.SG_PoolMiners.Cells[5,0]:='HRate';
form1.SG_PoolMiners.Cells[6,0]:='Ver';form1.SG_PoolMiners.Cells[7,0]:='IP';
form1.SG_PoolMiners.Cells[8,0]:='Buffer';
form1.SG_PoolMiners.Enabled := true;
form1.SG_PoolMiners.GridLineWidth := 1;
//GridPoolMembers.PopupMenu:=PoolMembersPopUp;
//GridPoolMembers.OnContextPopup:=@formpool.checkPoolMembersPopup;

form1.SG_Poolstats.FocusRectVisible:=false;

form1.LabAbout.Caption:=CoinName+' project'+SLINEBREAK+'Designed by PedroJOR'+SLINEBREAK+
'Crypto routines by Xor-el'+SLINEBREAK+
'Version '+ProgramVersion+subVersion+SLINEBREAK+'Protocol '+IntToStr(Protocolo)+SLINEBREAK+BuildDate;

form1.SG_Monitor.FocusRectVisible:=false;
form1.SG_Monitor.Options:= form1.SG_PoolMiners.Options+[goRowSelect]-[goRangeSelect];
form1.SG_Monitor.ColWidths[0]:= 160;form1.SG_Monitor.ColWidths[1]:= 62;
form1.SG_Monitor.ColWidths[2]:= 62;form1.SG_Monitor.ColWidths[3]:= 62;

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
//consolelinesadd(ARequestInfo.RemoteIP);
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
   StreamString.LoadFromStream(ARequestInfo.PostStream);

   //StreamString := ARequestInfo.PostStream;
   if assigned(StreamString) then
      begin
      StreamString.Position:=0;
      PostString := ReadStringFromStream(StreamString,-1,IndyTextEncoding_UTF8);
      end;
   AResponseInfo.ContentText:= ParseRPCJSON(PostString);
   //AResponseInfo.ContentText:= 'Ok';
   StreamString.Free;
   end;
End;

// DEPRECATED
{
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
            resultorder.reference+' '+resultorder.Receiver+' '+Int2curr(resultorder.AmmountTrf);
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
}

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
      ToExcLog(format(rs0031,[E.Message]));
      //ToExcLog('POOL: Error trying close a pool client connection ('+E.Message+')');
   end;
End;

// Try to send a message safely
Procedure TForm1.TryMessageToMiner(AContext: TIdContext;message:string);
Begin
   try
   Acontext.Connection.IOHandler.WriteLn(message);
   Except on E:Exception do
      ToExcLog(format(rs0032,[E.Message]));
      //ToExcLog('POOL: Error sending message to miner ('+E.Message+')');
   end;
End;

Function TForm1.UpdatePoolBot(ipuser:string):integer;
var
  counter: integer;
  modified : boolean = false;
Begin
if length(ListaPoolBots) > 0 then
   begin
   for counter := 0 to length(ListaPoolBots)-1 do
      begin
      if ListaPoolBots[counter].ip = ipuser then
         begin
         ListaPoolBots[counter].count+=1;
         ListaPoolBots[counter].Last:=UTCTime.ToInt64;
         modified := true;
         end;
      end;
   end;
if not modified then
   begin
   SetLength(ListaPoolBots,Length(ListaPoolBots)+1);
   ListaPoolBots[Length(ListaPoolBots)-1].ip:=IPUser;
   ListaPoolBots[Length(ListaPoolBots)-1].count:=1;
   ListaPoolBots[Length(ListaPoolBots)-1].Last:=UTCTime.ToInt64;
   end;
End;

// Pool server receives a line
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
if GetPoolContextIndex(AContext)<0 then
   begin
   TryClosePoolConnection(AContext);
   //ConsoleLinesAdd('Pool: Rejected unasigned context connection');
   exit;
   end;
IPUser := AContext.Connection.Socket.Binding.PeerIP;
Linea := '';
Linea := AContext.Connection.IOHandler.ReadLn('',ReadTimeOutTIme,-1,IndyTextEncoding_UTF8);
Password := Parameter(Linea,0);
if password <> Poolinfo.PassWord then exit;
UserDireccion := Parameter(Linea,1);
if IsPoolMemberConnected(UserDireccion)<0 then
   begin
   TryClosePoolConnection(AContext);
   ConsoleLinesAdd(rs0033);
   //ConsoleLinesAdd('Pool: Rejected not registered user');
   exit;
   end;
Comando := Parameter(Linea,2);
MemberBalance := GetPoolMemberBalance(UserDireccion);
// *** NEW MINER FORMAT ***
if comando = 'PING' then
   begin
      try
      Acontext.Connection.IOHandler.WriteLn('PONG '+PoolDataString(UserDireccion));
      PoolServerConex[IsPoolMemberConnected(UserDireccion)].Hashpower:=StrToIntDef(Parameter(linea,3),0);
      PoolServerConex[IsPoolMemberConnected(UserDireccion)].LastPing:=StrToInt64Def(UTCTime,0);
      Except on E:Exception do
         begin
         TryClosePoolConnection(Acontext);
         ToExclog(format(rs0034,[E.Message]));
         //ToExclog(Format('Pool: Error registerin a ping-> %s',[E.Message]));
         end;
      end;
   end
else if Comando = 'STEP' then
   begin
   PoolServerConex[IsPoolMemberConnected(UserDireccion)].LastPing:=UTCTime.ToInt64;
   bloqueStep := StrToIntDef(parameter(linea,3),0);
   SeedStep := parameter(linea,4);
   HashStep := parameter(linea,5);
   StepLength := StrToIntDef(parameter(linea,6),-1);
   StepBase := GetCharsFromDifficult(PoolMiner.Dificult, 0)-PoolStepsDeep; //Get the minimun steplength
   if StepLength<0 then StepLength := PoolMiner.DiffChars;
   StepValue := 16**(StepLength-Stepbase);
   Solucion := HashSha256String(SeedStep+PoolInfo.Direccion+HashStep);
   EnterCriticalSection(CSPoolStep);InsidePoolStep := true;
      try
      if ((StepLength>=StepBase) and (StepLength<PoolMiner.DiffChars) and
         (PoolMiner.steps<10) and (bloqueStep=PoolMiner.Block) ) then
         begin                                       // Proof of work solution
         if ( (AnsiContainsStr(Solucion,copy(PoolMiner.Target,1,StepLength))) and
            (GetPoolMemberBalance(UserDireccion)>-1) and (bloqueStep=PoolMiner.Block) and
            (PoolMiner.steps<10) and (not StepAlreadyAdded(SeedStep+HashStep)) ) then
            begin
            AcreditarPoolStep(UserDireccion, StepValue);
            TryMessageToMiner(Acontext,'STEPOK '+IntToStr(StepValue));
            //Acontext.Connection.IOHandler.WriteLn('STEPOK '+IntToStr(StepValue));
            EnterCriticalSection(CSPoolShares);
            insert(SeedStep+HashStep,Miner_PoolSharedStep,length(Miner_PoolSharedStep)+1);
            LeaveCriticalSection(CSPoolShares);
            end;
         end
      else if ( (AnsiContainsStr(Solucion,copy(PoolMiner.Target,1,PoolMiner.DiffChars))) and
          (GetPoolMemberBalance(UserDireccion)>-1) and (bloqueStep=PoolMiner.Block) and
          (IsValidStep(PoolMiner.Solucion,SeedStep+HashStep)) and (PoolMiner.steps<10) and
          (not StepAlreadyAdded(SeedStep+HashStep)) ) then
         begin
         AcreditarPoolStep(UserDireccion, StepValue);
         TryMessageToMiner(Acontext,'STEPOK '+IntToStr(StepValue));
         //Acontext.Connection.IOHandler.WriteLn('STEPOK '+IntToStr(StepValue));
         EnterCriticalSection(CSPoolShares);
         insert(SeedStep+HashStep,Miner_PoolSharedStep,length(Miner_PoolSharedStep)+1);
         LeaveCriticalSection(CSPoolShares);
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
               consolelinesAdd(rs0035);
               //consolelinesAdd('Pool solution verified!');
               OutgoingMsjsAdd(ProtocolLine(6)+BlockTime+' '+IntToStr(PoolMiner.Block)+' '+
                  PoolInfo.Direccion+' '+StringReplace(PoolMiner.Solucion,' ','_',[rfReplaceAll, rfIgnoreCase]));
               //ResetPoolMiningInfo();
               //SendNetworkRequests(blocktime,PoolInfo.Direccion,PoolMiner.Block);
               end
            else
               begin
               consolelinesAdd(format(rs0036,[IntToStr(PoolSolutionStep)]));
               //consolelinesAdd('Pool solution FAILED at step '+IntToStr(PoolSolutionStep));
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
         if ((bloqueStep=PoolMiner.Block) and (PoolMiner.steps<10)) then
            begin
            TryMessageToMiner(Acontext,'STEPFAIL');
            //Acontext.Connection.IOHandler.WriteLn('STEPFAIL');
            PoolServerConex[IsPoolMemberConnected(UserDireccion)].WrongSteps+=1;
            end;
         end;
      Except on E:Exception do
         begin
         TryClosePoolConnection(Acontext);
         ToExcLog(Format(rs0037,[E.Message]));
         //ToExclog(Format('Pool: Error inside CSPoolStep-> %s',[E.Message]));
         end;
      end;
   LeaveCriticalSection(CSPoolStep);InsidePoolStep := false;
   end
else if Comando = 'PAYMENT' then
   Begin
      {
      try
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
      Except on E:Exception do
         begin
         TryClosePoolConnection(Acontext);
         ToExclog(Format('Pool: Error Processing payment-> %s',[E.Message]));
         end;
      end;
      }
   end
else
   begin
   TryClosePoolConnection(Acontext);
   ToExcLog(Format(rs0038,[ipuser,linea]));
   //ToExcLog('POOL: Unexpected command from: '+ipuser+'->'+Linea);
   end;
End;

// Pool server receives a new connection
procedure TForm1.PoolServerConnect(AContext: TIdContext);
var
  IPUser,Linea,password, comando, minerversion, JoinPrefijo : String;
  UserDireccion : string = '';
  WasHandled : boolean = false;
  GoodJoin : boolean;
Begin
IPUser := AContext.Connection.Socket.Binding.PeerIP;
UpdatePoolBot(IPUser);
if PoolClientsCount > GetPoolTotalActiveConex+3 then
  begin
  TryClosePoolConnection(AContext);
  exit;
  end;
EnterCriticalSection(CSMinerJoin);InsideMinerJoin := true;
try
   Linea := AContext.Connection.IOHandler.ReadLn('',ReadTimeOutTIme,-1,IndyTextEncoding_UTF8);
   Password := Parameter(Linea,0);
   UserDireccion := Parameter(Linea,1);
   comando :=Parameter(Linea,2);
   minerversion :=Parameter(Linea,3);
   if AContext.Connection.IOHandler.ReadLnTimedout then
      TryClosePoolConnection(AContext)
   else if BotExists(IPUser) then
      TryClosePoolConnection(AContext,'BANNED')
   else if password <> Poolinfo.PassWord then  // WRONG PASSWORD.
      TryClosePoolConnection(AContext,'PASSFAILED')
   else if ( (not isvalidaddress(UserDireccion)) and (AddressSumaryIndex(UserDireccion)<0) ) then
      TryClosePoolConnection(AContext,'INVALIDADDRESS')
   else if IsPoolMemberConnected(UserDireccion)>=0 then   // ALREADY CONNECTED
      TryClosePoolConnection(AContext,'ALREADYCONNECTED')
   else if Comando = 'JOIN' then
      begin
      JoinPrefijo := PoolAddNewMember(UserDireccion);
      if JoinPrefijo<>'' then
         begin
         goodJoin := true;
            try
            Acontext.Connection.IOHandler.WriteLn('JOINOK '+PoolInfo.Direccion+' '+JoinPrefijo+' '+PoolDataString(UserDireccion));
            Except on E:Exception do
               goodJoin := false;
            end;
         if not SavePoolServerConnection(IpUser,JoinPrefijo, UserDireccion,minerversion,Acontext) then
            goodJoin := false;
         if not goodJoin then
            begin
            TryClosePoolConnection(AContext);
            BorrarPoolServerConex(Acontext);
            end;
         end
      else
         begin
         TryClosePoolConnection(AContext,'POOLFULL');
         end;
      end
   else if Comando = 'STATUS' then
      begin
      TryClosePoolConnection(AContext,PoolStatusString);
      ConsoleLinesAdd(Format(rs0039,[IPUser]));
      //consolelinesadd('POOL: Status requested from '+IPUser);
      end
   else if Comando = 'ADDRESSBAL' then
      // this is a deprected function user for the first web api
      begin
      {
      UserDireccion := Parameter(Linea,3);
      TryClosePoolConnection(AContext,'ADDRESSBAL '+UserDireccion+' '+IntToStr(GetAddressBalance(UserDireccion))+' '+
      IntToStr(GetAddressIncomingpays(UserDireccion))+' '+
      IntToStr(GetAddressPendingPays(UserDireccion))+' '+
      IntToStr(GetAddressBalance(UserDireccion)-GetAddressPendingPays(UserDireccion)));
      }
      end
   else
      begin
      TryClosePoolConnection(AContext,'INVALIDCOMMAND');
      ToExclog(Format(rs0040,[IPUser,comando]));
      //ToExclog(Format('Pool: closed incoming %s (%s)',[IPUser,comando]));
      end;
Except on E:Exception do
   ToExclog(Format(rs0041,[E.Message]));
   //ToExclog(Format('Pool: Error inside MinerJoin-> %s',[E.Message]));
end;
LeaveCriticalSection(CSMinerJoin);InsideMinerJoin := false;
End;

// A miner disconnects from pool server
procedure TForm1.PoolServerDisConnect(AContext: TIdContext);
var
  IPUser : string;
Begin
BorrarPoolServerConex(AContext);
End;

// Exception on pool server
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
  AFileStream : TFileStream;
  BlockZipName: string = '';
  GetFileOk : boolean = false;
  GoAhead : boolean;
Begin
GoAhead := true;
IPUser := AContext.Connection.Socket.Binding.PeerIP;
slot := GetSlotFromIP(IPUser);
if slot = 0 then
  begin
  ToExcLog(Format(rs0043,[IPUser]));
  //ToExcLog('SERVER: Received a line from a client without and assigned slot: '+IPUser);
  TryCloseServerConnection(AContext);
  GoAhead := false;
  end;
   try
   LLine := AContext.Connection.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   if AContext.Connection.IOHandler.ReadLnTimedout then
      begin
      TryCloseServerConnection(AContext);
      ToExcLog(rs0044);
      //ToExcLog('SERVER: Timeout reading line from connection');
      GoAhead := false;
      end;
   Except on E:Exception do
      begin
      TryCloseServerConnection(AContext);
      ToExcLog(format(rs0045,[IPUser,E.Message]));
      //ToExcLog('SERVER: Can not read line from connection '+IPUser+'('+E.Message+')');
      GoAhead := false;
      end;
   end;
if GoAhead then
   begin
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
               ToExcLog(Format(rs0046,[E.Message]));
               //ToExcLog('SERVER: Server error receiving headers file ('+E.Message+')');
               TryCloseServerConnection(AContext);
               GetFileOk := false;
               end;
            end;
         finally
         DownloadHeaders := false;
         AFileStream.Free;
         LeaveCriticalSection(CSHeadAccess);
         end;
      if GetFileOk then
         begin
         ConsoleLinesAdd(Format(rs0047,[copy(HashMD5File(ResumenFilename),1,5)]));
         //ConsoleLinesAdd(LAngLine(74)+': '+copy(HashMD5File(ResumenFilename),1,5)); //'Headers file received'
         LastTimeRequestResumen := 0;
         UpdateMyData();
         end;
      end
   else if LLine = 'BLOCKZIP' then
      begin
      BlockZipName := BlockDirectory+'blocks.zip';
      if FileExists(BlockZipName) then TryDeleteFile(BlockZipName);
      AFileStream := TFileStream.Create(BlockZipName, fmCreate);
      DownLoadBlocks := true;
         try
            try
            AContext.Connection.IOHandler.ReadStream(AFileStream);
            GetFileOk := true;
            except on E:Exception do
               begin
               ToExcLog(Format(rs0048,[E.Message]));
               //ToExcLog('SERVER: Server error receiving block file ('+E.Message+')');
               TryCloseServerConnection(AContext);
               GetFileOk := false;
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
         ResetMinerInfo();
         LastTimeRequestBlock := 0;
         end;
      end
   else if parameter(LLine,4) = '$GETRESUMEN' then
      begin
      EnterCriticalSection(CSHeadAccess);
         try
         AFileStream := TFileStream.Create(ResumenFilename, fmOpenRead + fmShareDenyNone);
         GetFileOk := true;
         Except on E:Exception do
            begin
            GetFileOk := false;
            AFileStream.Free;
            ToExcLog(Format(rs0049,[E.Message]));
            //ToExcLog(Format('SERVER: Error creating stream from headers: %s',[E.Message]));
            end;
         end;
      if GetFileOk then
         begin
            try
            Acontext.Connection.IOHandler.WriteLn('RESUMENFILE');
            Acontext.connection.IOHandler.Write(AFileStream,0,true);
            ConsoleLinesAdd(format(rs0050,[IPUser]));
            //ConsoleLinesAdd(LangLine(91)+': '+IPUser);//'Headers file sent'
            Except on E:Exception do
               begin
               Form1.TryCloseServerConnection(Conexiones[Slot].context);
               ToExcLog(Format(rs0051,[E.Message]));
               //ToExcLog('SERVER: Error sending headers file ('+E.Message+')');
               end;
            end;
         AFileStream.Free;
         end;
      LeaveCriticalSection(CSHeadAccess);
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
               ToLog(Format(rs0052,[IPUser,BlockZipName]));
               //ToLog('SERVER: BlockZip send to '+IPUser+':'+BlockZipName);
               Except on E:Exception do
                  begin
                  Form1.TryCloseServerConnection(Conexiones[Slot].context);
                  ToExcLog(Format(rs0053,[E.Message]));
                  //ToExcLog('SERVER: Error sending ZIP blocks file ('+E.Message+')');
                  end;
               end;
            finally
            AFileStream.Free;
            end;
         Trydeletefile(BlockZipName); // safe function to delete files
         end
      end
   else if AnsiContainsStr(ValidProtocolCommands,Uppercase(parameter(LLine,4))) then
      begin
         try
         SlotLines[slot].Add(LLine);
         Except
         On E :Exception do
            ToExcLog(Format(rs0054,[E.Message]));
            //ToExcLog('SERVER: Server error adding received line ('+E.Message+')');
         end;
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
  IPUser : string;
  LLine : String;
  MiIp: String = '';
  Peerversion : string = '';
  GoAhead : boolean;
Begin
GoAhead := true;
IPUser := AContext.Connection.Socket.Binding.PeerIP;
try
   LLine := AContext.Connection.IOHandler.ReadLn('',200,-1,IndyTextEncoding_UTF8);
   if AContext.Connection.IOHandler.ReadLnTimedout then
      begin
      TryCloseServerConnection(AContext);
      ToExcLog(rs0056);
      //ToExcLog('SERVER: Timeout reading line from new connection');
      GoAhead := false;
      end;
Except on E:Exception do
   begin
   TryCloseServerConnection(AContext);
   ToExcLog(format(rs0057,[E.Message]));
   //ToExcLog('SERVER: Can not read line from new connection ('+E.Message+')');
   GoAhead := false;
   end;
end;
MiIp := Parameter(LLine,1);
Peerversion := Parameter(LLine,2);
if GoAhead then
   begin
   if parameter(LLine,0) = 'NODESTATUS' then
      begin
      TryCloseServerConnection(AContext,'NODESTATUS '+GetNodeStatusString);
      end
   else if Copy(LLine,1,4) <> 'PSK ' then  // invalid protocol
      begin
      ToLog(format(rs0058,[IPUser]));
      //ToLog('SERVER: Invalid client->'+IPUser);
      TryCloseServerConnection(AContext);
      UpdateBotData(IPUser);
      end
   else if IPUser = MyPublicIP then
      begin
      ToLog(rs0059);
      //ToLog('SERVER: Own connected');
      TryCloseServerConnection(AContext);
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
   else if Peerversion < ProgramVersion then
      begin
      TryCloseServerConnection(AContext,GetPTCEcn+'OLDVERSION');
      end
   else if SaveConection('CLI',IPUser,Acontext) = 0 then
      begin
      TryCloseServerConnection(AContext);
      end
   else if Copy(LLine,1,4) = 'PSK ' then
      begin    // Se acepta la nueva conexion
      OutText(format(rs0061,[IPUser]));
      //OutText(LangLine(13)+IPUser,true);             //New Connection from:
      MyPublicIP := MiIp;
      U_DataPanel := true;
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

// Mostrar los detalles de una transaccion
Procedure TForm1.GridMyTxsOnDoubleClick(Sender: TObject);
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
        extratext :=LangLine(75); //' (OWN)'
      if GridMyTxs.Cells[7,GridMyTxs.Row] <> 'null' then
         referencetoshow := GridMyTxs.Cells[7,GridMyTxs.Row];
      form1.MemoTrxDetails.Text:=
      GridMyTxs.Cells[4,GridMyTxs.Row]+SLINEBREAK+                    //order ID
      LangLine(76)+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+      //'Receiver : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row]+extratext+SLINEBREAK+  //'Ammount  : '
      'Reference : '+referencetoshow+SLINEBREAK+    //'reference  : '
      LangLine(79)+GridMyTxs.Cells[9,GridMyTxs.Row]+SLINEBREAK+      //'Transfers: '
      GetCommand(GridMyTxs.Cells[8,GridMyTxs.Row])+SLINEBREAK;
      if StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1)> 1 then // añadir mas trfids
         for cont := 2 to StrToIntDef(GridMyTxs.Cells[9,GridMyTxs.Row],1) do
           form1.MemoTrxDetails.lines.add(parameter(GridMyTxs.Cells[8,GridMyTxs.Row],cont-1));
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'MINE' then
      Begin
      form1.MemoTrxDetails.Text:=
      LangLine(80)+GridMyTxs.Cells[0,GridMyTxs.Row]+SLINEBREAK+ //'Mined    : '
      LangLine(76)+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+   //'Receiver : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row];   //'Ammount  : '
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'CUSTOM' then
      Begin
      form1.MemoTrxDetails.Text:=
      LangLine(81)+SLINEBREAK+                   //'Address customization'
      LangLine(82)+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Hash+SLINEBREAK+//'Address  : '
      LangLine(83)+ListaDirecciones[DireccionEsMia(GridMyTxs.Cells[6,GridMyTxs.Row])].Custom+SLINEBREAK+//'Alias    : '
      'Amount   : '+Int2Curr(Customizationfee);
      end;
   if GridMyTxs.Cells[2,GridMyTxs.Row] = 'FEE' then
      begin
      form1.MemoTrxDetails.Text:=
      LangLine(84)+SLINEBREAK+   //'Maintenance fee'
      LangLine(82)+GridMyTxs.Cells[6,GridMyTxs.Row]+SLINEBREAK+  //'Address  : '
      LangLine(85)+GridMyTxs.Cells[7,GridMyTxs.Row]+SLINEBREAK+  //'Interval : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row]; //'Ammount  : '
      if GridMyTxs.Cells[8,GridMyTxs.Row] = 'YES' then
        form1.MemoTrxDetails.Text:= form1.MemoTrxDetails.Text+LangLine(86);//' (Address deleted from summary)'
      end;
   form1.MemoTrxDetails.SelStart:=0;
   end;

End;

Procedure TForm1.BitPosInfoOnClick (Sender: TObject);
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
   DireccionesPanel.Enabled:=false;
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
DireccionesPanel.Enabled:=true;
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
if not WO_MultiSend then EditSCMont.Text:=Int2curr(GetMaximunToSend(GetWalletBalance))
else EditSCMont.Text:=Int2Curr(GetMaximunToSend(ListaDirecciones[0].Balance-ListaDirecciones[0].pending))
End;

// verifica el destino que marca para enviar coins
Procedure Tform1.EditSCDestChange(Sender:TObject);
Begin
if EditSCDest.Text = '' then ImgSCDest.Picture.Clear
else
   begin
   EditSCDest.Text :=StringReplace(EditSCDest.Text,' ','',[rfReplaceAll, rfIgnoreCase]);
   if ((IsValidAddress(EditSCDest.Text)) or (AddressSumaryIndex(EditSCDest.Text)>=0)) then
     Form1.imagenes.GetBitmap(17,ImgSCDest.Picture.Bitmap)
   else Form1.imagenes.GetBitmap(14,ImgSCDest.Picture.Bitmap);
   end;

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
form1.BitBtnPending.Caption:=IntToStr(length(PendingTXs));
if form1.PoolServer.active then Form1.StaPoolSer.Visible:=true
else Form1.StaPoolSer.Visible:=false;
if form1.RPCServer.active then Form1.StaRPCimg.Visible:=true
else Form1.StaRPCimg.Visible:=false;
Form1.Imgs32.GetBitMap(ConnectedRotor,form1.ImgRotor.picture.BitMap);

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
if Form1.Server.Active then form1.MainMenu.Items[0].Items[0].Caption:=rs0077
else form1.MainMenu.Items[0].Items[0].Caption:=rs0076;
if CONNECT_Try then form1.MainMenu.Items[0].Items[1].Caption:=rs0079
else form1.MainMenu.Items[0].Items[1].Caption:=rs0078;
if Miner_Active then form1.MainMenu.Items[0].Items[2].Caption:='Stop mining'
else form1.MainMenu.Items[0].Items[2].Caption:='Mine';
form1.MainMenu.Items[1].Items[0].Clear;
form1.MainMenu.Items[1].Items[3].Clear;
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
//if fileexists(PoolInfoFilename) then MainMenu.Items[2].Items[5].Visible:=true
//else MainMenu.Items[2].Items[5].Visible:=false;
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
if MemoConsola.Text <> '' then ConsolePopUp2.Items[0].Enabled:= true
else ConsolePopUp2.Items[0].Enabled:= false;
if length(Memoconsola.SelText)>0 then ConsolePopUp2.Items[1].Enabled:= true
else ConsolePopUp2.Items[1].Enabled:= false;
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
if ConsoleLine.Text <> '' then ConsoLinePopUp2.Items[0].Enabled:= true
else ConsoLinePopUp2.Items[0].Enabled:= false;
if length(ConsoleLine.SelText)>0 then ConsoLinePopUp2.Items[1].Enabled:= true
else ConsoLinePopUp2.Items[1].Enabled:= false;
if length(Clipboard.AsText)>0 then ConsoLinePopUp2.Items[2].Enabled:= true
else ConsoLinePopUp2.Items[2].Enabled:= false;
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

// Copy the Order ID to clipboard
Procedure TForm1.TrxDetailsPopUpCopyOrder(Sender:TObject);
Begin
Clipboard.AsText:= GridMyTxs.Cells[4,GridMyTxs.row];
info('Order ID copied to clipboard');
End;


//******************************************************************************
// OPTIONS CONTROLS
//******************************************************************************

// WALLET

procedure TForm1.CB_WO_AutoConnectChange(Sender: TObject);
begin
if not G_Launching then
  begin
   if CB_WO_AutoConnect.Checked then WO_AutoConnect := true
   else WO_AutoConnect := false ;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.CB_WO_ToTrayChange(Sender: TObject);
begin
if not G_Launching then
   begin
   if CB_WO_ToTray.Checked then WO_ToTray := true
   else WO_ToTray := false ;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_MinPeersChange(Sender: TObject);
begin
if not G_Launching then
   begin
   MinConexToWork := SE_WO_MinPeers.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_CTOTChange(Sender: TObject);
begin
if not G_Launching then
   begin
   ConnectTimeOutTime := SE_WO_CTOT.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_RTOTChange(Sender: TObject);
begin
if not G_Launching then
   begin
   ReadTimeOutTIme := SE_WO_RTOT.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_ShowOrdersChange(Sender: TObject);
begin
if not G_Launching then
   begin
   ShowedOrders := SE_WO_ShowOrders.Value;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_PosWarningChange(Sender: TObject);
begin
if not G_Launching then
   begin
   WO_PosWarning := SE_WO_PosWarning.Value;
   U_DirPanel := true;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.CB_WO_AntiFreezeChange(Sender: TObject);
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

procedure TForm1.CB_WO_MultisendChange(Sender: TObject);
begin
if not G_Launching then
   begin
   if CB_WO_Multisend.Checked then WO_Multisend := true
   else WO_Multisend := false ;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.SE_WO_AntifreezeTimeChange(Sender: TObject);
begin
if not G_Launching then
   begin
   WO_AntiFreezeTime := SE_WO_AntiFreezeTime.Value;
   S_AdvOpt := true;
   end;
end;

// RPC

procedure TForm1.CB_RPC_ONChange(Sender: TObject);
begin
if not G_Launching then
   begin
   if CB_RPC_ON.Checked then SetRPCOn
   else SetRPCOff;
   end;
end;

procedure TForm1.CB_AUTORPCChange(Sender: TObject);
begin
if not G_Launching then
   begin
   RPCAuto:= CB_AUTORPC.Checked;
   S_AdvOpt := true;
   end;
end;

procedure TForm1.LE_Rpc_PortEditingDone(Sender: TObject);
begin
if StrToIntDef(LE_Rpc_Port.Text,-1) <> RPCPort then
   begin
   SetRPCPort('SETRPCPORT '+LE_Rpc_Port.Text);
   LE_Rpc_Port.Text := IntToStr(RPCPort);
   S_AdvOpt := true;
   info ('New RPC port set');
   end;
end;

procedure TForm1.LE_Rpc_PassEditingDone(Sender: TObject);
begin
if ((not G_Launching) and (LE_Rpc_Pass.Text<>RPCPass)) then
   begin
   setRPCpassword(LE_Rpc_Pass.Text);
   LE_Rpc_Pass.Text:=RPCPass;
   S_AdvOpt := true;
   info ('New RPC password set');
   end;
end;

procedure TForm1.CB_RPCFilterChange(Sender: TObject);
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

procedure TForm1.ComboBoxLangChange(Sender: TObject);
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
if ComboBoxLang.Items[Index] ='zn' then
   begin
   ComboBoxLang.Canvas.TextRect(ARect, 20, ARect.Top, '中文');
   Imagenes.Draw(ComboBoxLang.Canvas, ARect.Left + 1, ARect.Top + 1, 63);
   end;
End;

// Adjust data panel when resizing
procedure TForm1.DataPanelResize(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.DataPanel.Width;
form1.DataPanel.ColWidths[0]:= thispercent(20,GridWidth);
form1.DataPanel.ColWidths[1]:= thispercent(30,GridWidth);
form1.DataPanel.ColWidths[2]:= thispercent(20,GridWidth);
form1.DataPanel.ColWidths[3]:= thispercent(30,GridWidth);
end;

// adjust addresses grid when resizing
procedure TForm1.DireccionesPanelResize(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.DireccionesPanel.Width;
form1.DireccionesPanel.ColWidths[0]:= thispercent(68,GridWidth);
form1.DireccionesPanel.ColWidths[1]:= thispercent(32,GridWidth, true);
end;

// adjust LTC grid
procedure TForm1.GridExLTCResize(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.GridExLTC.Width;
form1.GridExLTC.ColWidths[0]:= thispercent(34,GridWidth);
form1.GridExLTC.ColWidths[1]:= thispercent(33,GridWidth);
form1.GridExLTC.ColWidths[2]:= thispercent(33,GridWidth,true);
end;

// Fill the transaction details when Tab is selected
procedure TForm1.TabHistoryShow(Sender: TObject);
begin
GridMyTxsSelection(nil,GridMyTxs.Col,GridMyTxs.Row)
end;

// Load Masternode options when TAB is selected
procedure TForm1.TabNodeOptionsShow(Sender: TObject);
begin
CheckBox4.Checked:=WO_AutoServer;
LabeledEdit5.Text:=MN_IP;
LabeledEdit6.Text:=MN_Port;
LabeledEdit8.Text:=MN_Funds;
LabeledEdit9.Text:=MN_Sign;
end;

// Save Node options
procedure TForm1.BSaveNodeOptionsClick(Sender: TObject);
begin
WO_AutoServer:=CheckBox4.Checked;
MN_IP:=LabeledEdit5.Text;
MN_Port:=LabeledEdit6.Text;
MN_Funds:=LabeledEdit8.Text;
MN_Sign:=LabeledEdit9.Text;
S_AdvOpt := true;
info('Masternode options saved');
end;

// adjust transactions history grid when resize
procedure TForm1.GridMyTxsResize(Sender: TObject);
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
procedure TForm1.GridPoSResize(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := form1.GridPoS.Width;
form1.GridPoS.ColWidths[0]:= thispercent(50,GridWidth);
form1.GridPoS.ColWidths[1]:= thispercent(50,GridWidth);
End;

// Adjust the trxdetails when a selection is done
procedure TForm1.GridMyTxsSelection(Sender: TObject; aCol, aRow: Integer);
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
        extratext :=LangLine(75); //' (OWN)'
      if GridMyTxs.Cells[7,GridMyTxs.Row] <> 'null' then
         referencetoshow := GridMyTxs.Cells[7,GridMyTxs.Row];
      MemoTrxDetails.Text:=
      GridMyTxs.Cells[4,GridMyTxs.Row]+SLINEBREAK+                    //order ID
      LangLine(76)+AddrText(GridMyTxs.Cells[6,GridMyTxs.Row])+SLINEBREAK+      //'Receiver : '
      LangLine(77)+GridMyTxs.Cells[3,GridMyTxs.Row]+extratext+SLINEBREAK+  //'Ammount  : '
      'Reference : '+referencetoshow+SLINEBREAK+    //'reference  : '
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
   MemoTrxDetails.SelStart:=0;
   end;

End;



procedure TForm1.MemoRPCWhitelistEditingDone(Sender: TObject);
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
   form1.PageMain.ActivePage := form1.TabWallet;
   PanelSend.Visible:=true;
   EditSCDest.Text:='devteam_donations';
   EditSCMont.Text:='1.00000000';
   MemoSCCon.Text:='WebpageDonation';
   form1.BringToFront;
   Clipboard.AsText := '';
   end;
End;

END. // END PROGRAM

