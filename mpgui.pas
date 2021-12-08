unit mpGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpTime, graphics, strutils, forms, controls, grids,stdctrls,
  crt,ExtCtrls, buttons, editbtn , menus, Clipbrd, IdContext, LCLTranslator;

type
  TFormInicio = class(Tform)
    procedure closeFormInicio(Sender: TObject; var CanClose: boolean);
    private
    public
    end;

  TFormSlots = class(Tform)
    procedure GridMSlotsPrepareCanvas(sender: TObject; aCol, aRow: Integer;aState: TGridDrawState);
    private
    public
    end;

  TFormPool = class(Tform)
    // poolmembers popup
    Procedure checkPoolMembersPopup(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
    Procedure checkPoolConexPopup(Sender: TObject;MousePos: TPoint;var Handled: Boolean);

    Procedure CopyPoolMemberAddres(Sender:TObject);
    Procedure PoolExpelPaying(Sender:TObject);
    Procedure PoolExpelNotPay(Sender:TObject);
    Procedure BPayuserOnClick(Sender: TObject);
    Procedure SeePoolConex(Sender: TObject);
    Procedure KickBanOnClick(Sender: TObject);

    private
    public
    end;

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Procedure CreateFormInicio();
Procedure CreateFormSlots();
Procedure UpdateSlotsGrid();
Procedure CreateFormPool();
Procedure UpdatePoolForm();
Procedure InicializarGUI();
Procedure OutText(Texto:String;inctime:boolean = false;canal : integer =0);
Procedure MostrarLineasDeConsola();
Procedure ActualizarGUI();
function LangLine(linea:integer):string;
Procedure language(linea:string);
function Int2Curr(Value: int64): string;
function OrderShowed(OrderID:String):integer;
Function AddrText(hash:String):String;
Procedure UpdateMyTrxGrid();
Procedure Info(text:string);
Procedure Processhint(sender:TObject);
Procedure ShowGlobo(Titulo,texto:string);
Procedure SetMiliTime(Name:string;tipo:integer);
Procedure SetCurrentJob(CurrJob:String;status:boolean);
Procedure CloseAllForms();
Procedure UpdateRowHeigth();

var
  FormInicio : TFormInicio;
    GridInicio : TStringgrid;

  FormSlots : TFormSlots;
    GridMSlots : TStringgrid;
  FormPool : TformPool;
    LabelPoolData : TLabel;
    GridPoolMembers : TStringgrid;
    LabelPoolMiner : Tlabel;
    LabelPoolMiner2 : Tlabel;
    GridPoolConex : TStringgrid;
    EdBuFee : TLabel;
    EdMaxMem : TLabel;
    EdPayRate : TLabel;
    EdPooExp : TLabel;
    EdShares: TLabel;

    MenuItem : TMenuItem;
    PoolMembersPopUp : TPopupMenu;
    PoolConexPopUP : TPopupMenu;

    IpToBan : String = '';

implementation

Uses
  mpParser, mpDisk, mpRed, mpProtocol,mpcoin, mpblock, formexplore, poolmanage, translation;

// Returns the X percentage of a specified number
function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Begin
result := (percent*thiswidth) div 100;
if RestarBarra then result := result-20;
End;

// Crea el formulario para el inicio
Procedure CreateFormInicio();
Begin
FormInicio := TFormInicio.Createnew(form1);
FormInicio.caption := rs0500;
FormInicio.SetBounds(0, 0, 350, 200);
FormInicio.BorderStyle := bssingle;
FormInicio.Position:=poOwnerFormCenter;
FormInicio.BorderIcons:=FormInicio.BorderIcons-[biminimize]-[bisystemmenu];
forminicio.ShowInTaskBar:=sTAlways;
forminicio.OnCloseQuery:=@FormInicio.closeFormInicio;

GridInicio := TStringGrid.Create(forminicio);GridInicio.Parent:=forminicio;
GridInicio.Font.Name:='consolas'; GridInicio.Font.Size:=10;
GridInicio.Left:=1;GridInicio.Top:=1;GridInicio.Height:=198;GridInicio.width:=348;
GridInicio.FixedCols:=0;GridInicio.FixedRows:=0;
GridInicio.rowcount := 0;GridInicio.ColCount:=1;
GridInicio.ScrollBars:=ssAutoVertical;
GridInicio.Options:= GridInicio.Options-[goRangeSelect];
GridInicio.ColWidths[0]:= 298;
GridInicio.FocusRectVisible:=false;
GridInicio.Enabled := true;
GridInicio.GridLineWidth := 0;
End;

// Al cerrar el formulario de inicio
Procedure TFormInicio.closeFormInicio(Sender: TObject; var CanClose: boolean);
Begin
if G_launching then canclose := false
else if RunningDoctor then canclose := false
else
   begin
   forminicio.Visible:=false;
   form1.Visible:=true;
   end;
End;

// Color the conections form
procedure TFormSlots.GridMSlotsPrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
Begin
if ( (Arow>0) and (conexiones[Arow].IsBusy) ) then
  begin
  (Sender as TStringGrid).Canvas.Brush.Color :=  clmoneygreen;
  end;
End;

// Crea el formulario de monitorizacion de los slots
Procedure CreateFormSlots();
Begin
FormSlots := TFormSlots.Createnew(form1);
FormSlots.caption := coinname+' Slots Monitor';
FormSlots.SetBounds(0, 0, 530, 410);
FormSlots.BorderStyle := bssingle;
//FormSlots.Position:=poOwnerFormCenter;
FormSlots.Top:=1;FormSlots.Left:=1;
FormSlots.BorderIcons:=FormSlots.BorderIcons-[biminimize];
FormSlots.ShowInTaskBar:=sTAlways;

GridMSlots := TStringGrid.Create(FormSlots);GridMSlots.Parent:=FormSlots;
GridMSlots.Font.Name:='consolas'; GridMSlots.Font.Size:=8;
GridMSlots.Left:=1;GridMSlots.Top:=1;GridMSlots.Height:=408;GridMSlots.width:=528;
GridMSlots.FixedCols:=0;GridMSlots.FixedRows:=1;
GridMSlots.rowcount := MaxConecciones+1;GridMSlots.ColCount:=15;
GridMSlots.ScrollBars:=ssVertical;
GridMSlots.FocusRectVisible:=false;
GridMSlots.Options:= GridMSlots.Options-[goRangeSelect];
GridMSlots.ColWidths[0]:= 20;GridMSlots.ColWidths[1]:= 80;GridMSlots.ColWidths[2]:= 25;
GridMSlots.ColWidths[3]:= 20;GridMSlots.ColWidths[4]:= 48;GridMSlots.ColWidths[5]:= 40;
GridMSlots.ColWidths[6]:= 40;GridMSlots.ColWidths[7]:= 25;GridMSlots.ColWidths[8]:= 25;
GridMSlots.ColWidths[9]:= 35;GridMSlots.ColWidths[10]:= 30;GridMSlots.ColWidths[11]:= 25;
GridMSlots.ColWidths[12]:= 40;GridMSlots.ColWidths[13]:= 25;;GridMSlots.ColWidths[14]:= 29;
GridMSlots.Enabled := true;
GridMSlots.Cells[0,0]:='N';GridMSlots.Cells[1,0]:='IP';GridMSlots.Cells[2,0]:='T';
GridMSlots.Cells[3,0]:='Cx';GridMSlots.Cells[4,0]:='LBl';GridMSlots.Cells[5,0]:='LBlH';
GridMSlots.Cells[6,0]:='SumH';GridMSlots.Cells[7,0]:='Pen';GridMSlots.Cells[8,0]:='Pro';
GridMSlots.Cells[9,0]:='Ver';GridMSlots.Cells[10,0]:='LiP';GridMSlots.Cells[11,0]:='Off';
GridMSlots.Cells[12,0]:='HeaH';GridMSlots.Cells[13,0]:='Sta';GridMSlots.Cells[14,0]:='Ping';
GridMSlots.GridLineWidth := 1;
GridMSlots.OnPrepareCanvas:= @FormSlots.GridMSlotsPrepareCanvas;
End;

Procedure UpdateSlotsGrid();
var
  contador : integer;
Begin
setmilitime('UpdateSlotsGrid',1);
for contador := 1 to MaxConecciones do
   begin
   GridMSlots.Cells[0,contador]:= inttostr(contador);
   GridMSlots.Cells[1,contador]:= Conexiones[contador].ip;
   GridMSlots.Cells[2,contador]:= Conexiones[contador].tipo;
   GridMSlots.Cells[3,contador]:= IntToStr(Conexiones[contador].Connections);
   GridMSlots.Cells[4,contador]:= Conexiones[contador].Lastblock;
   GridMSlots.Cells[5,contador]:= copy(Conexiones[contador].LastblockHash,0,5);
   GridMSlots.Cells[6,contador]:= copy(Conexiones[contador].SumarioHash,0,5);
   GridMSlots.Cells[7,contador]:= IntToStr(Conexiones[contador].Pending);
   GridMSlots.Cells[8,contador]:= IntToStr(Conexiones[contador].Protocol);
   GridMSlots.Cells[9,contador]:= Conexiones[contador].Version;
   GridMSlots.Cells[10,contador]:= IntToStr(Conexiones[contador].ListeningPort);
   GridMSlots.Cells[11,contador]:= IntToStr(Conexiones[contador].offset);
   GridMSlots.Cells[12,contador]:= copy(Conexiones[contador].ResumenHash,0,5);
   GridMSlots.Cells[13,contador]:= IntToStr(Conexiones[contador].ConexStatus);
   GridMSlots.Cells[14,contador]:= IntToStr(UTCTime.ToInt64-StrToInt64Def(Conexiones[contador].lastping,UTCTime.ToInt64));
   end;
setmilitime('UpdateSlotsGrid',2);
End;

Procedure CreateFormPool();
Begin
FormPool := TFormPool.Createnew(form1);
FormPool.caption := 'Mining Pool';
FormPool.SetBounds(0, 0, 430, 230);
FormPool.BorderStyle := bssingle;
FormPool.Position:=poOwnerFormCenter;
FormPool.BorderIcons:=FormPool.BorderIcons-[biminimize];
FormPool.ShowInTaskBar:=sTAlways;

LabelPoolData := TLabel.Create(FormPool);
LabelPoolData.Parent := FormPool;LabelPoolData.AutoSize:=true;
LabelPoolData.Font.Name:='consolas'; LabelPoolData.Font.Size:=8;
LabelPoolData.Top:= 1; LabelPoolData.Left:= 1;
LabelPoolData.Caption:='';

PoolMembersPopUp := TPopupMenu.Create(Formpool);

MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'Expel';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  PoolMembersPopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'Pay';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  PoolMembersPopUp.Items[0].Add(MenuItem);
MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'Yes';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @formpool.PoolExpelPaying;PoolMembersPopUp.Items[0].Items[0].Add(MenuItem);
MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'No';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @formpool.PoolExpelNotPay;PoolMembersPopUp.Items[0].Items[0].Add(MenuItem);
MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'Copy Addres';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @formpool.CopyPoolMemberAddres;PoolMembersPopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'Pay';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @formpool.BPayuserOnClick;PoolMembersPopUp.Items.Add(MenuItem);
MenuItem := TMenuItem.Create(PoolMembersPopUp);MenuItem.Caption := 'Connection';//Form1.imagenes.GetBitmap(7,MenuItem.Bitmap);
  MenuItem.OnClick := @formpool.SeePoolConex;PoolMembersPopUp.Items.Add(MenuItem);

GridPoolMembers := TStringGrid.Create(FormPool);GridPoolMembers.Parent:=FormPool;
GridPoolMembers.Font.Name:='consolas'; GridPoolMembers.Font.Size:=8;
GridPoolMembers.Left:=1;GridPoolMembers.Top:=60;GridPoolMembers.Height:=149;GridPoolMembers.width:=558;
GridPoolMembers.FixedCols:=0;GridPoolMembers.FixedRows:=1;
GridPoolMembers.rowcount := 1;GridPoolMembers.ColCount:=6;
GridPoolMembers.ScrollBars:=ssVertical;
GridPoolMembers.FocusRectVisible:=false;
GridPoolMembers.Options:= GridPoolMembers.Options+[goRowSelect]-[goRangeSelect];
GridPoolMembers.ColWidths[0]:= 200;GridPoolMembers.ColWidths[1]:= 80;
GridPoolMembers.ColWidths[2]:= 50;GridPoolMembers.ColWidths[3]:= 80;
GridPoolMembers.ColWidths[4]:= 80;GridPoolMembers.ColWidths[5]:= 46;
GridPoolMembers.Cells[0,0]:='Address';GridPoolMembers.Cells[1,0]:='Prefix';
GridPoolMembers.Cells[2,0]:='Shares';GridPoolMembers.Cells[3,0]:='Earned';
GridPoolMembers.Cells[4,0]:='Session';GridPoolMembers.Cells[5,0]:='Last';
GridPoolMembers.Enabled := true;
GridPoolMembers.GridLineWidth := 1;
GridPoolMembers.PopupMenu:=PoolMembersPopUp;
GridPoolMembers.OnContextPopup:=@formpool.checkPoolMembersPopup;


LabelPoolMiner := TLabel.Create(FormPool);
LabelPoolMiner.Parent := FormPool;LabelPoolMiner.AutoSize:=true;
LabelPoolMiner.Font.Name:='consolas'; LabelPoolMiner.Font.Size:=8;
LabelPoolMiner.Top:= 211; LabelPoolMiner.Left:= 1;
LabelPoolMiner.Caption:='';

LabelPoolMiner2 := TLabel.Create(FormPool);
LabelPoolMiner2.Parent := FormPool;LabelPoolMiner2.AutoSize:=true;
LabelPoolMiner2.Font.Name:='consolas'; LabelPoolMiner2.Font.Size:=8;
LabelPoolMiner2.Top:= 221; LabelPoolMiner2.Left:= 1;
LabelPoolMiner2.Caption:='';

PoolConexPopUP := TPopupMenu.Create(Formpool);

MenuItem := TMenuItem.Create(PoolConexPopUP);MenuItem.Caption := 'Ban IP';
  MenuItem.OnClick := @formpool.KickBanOnClick;
  PoolConexPopUP.Items.Add(MenuItem);

GridPoolConex := TStringGrid.Create(FormPool);GridPoolConex.Parent:=FormPool;
GridPoolConex.Font.Name:='consolas'; GridPoolConex.Font.Size:=8;
GridPoolConex.Left:=1;GridPoolConex.Top:=232;GridPoolConex.Height:=155;GridPoolConex.width:=472;
GridPoolConex.FixedCols:=0;GridPoolConex.FixedRows:=1;
GridPoolConex.rowcount := 1;GridPoolConex.ColCount:=6;
GridPoolConex.ScrollBars:=ssVertical;
GridPoolConex.FocusRectVisible:=false;
GridPoolConex.Options:= GridPoolConex.Options+[goRowSelect]-[goRangeSelect];
GridPoolConex.ColWidths[0]:= 90;GridPoolConex.ColWidths[1]:= 200;
GridPoolConex.ColWidths[2]:= 50;GridPoolConex.ColWidths[3]:= 50;GridPoolConex.ColWidths[4]:= 30;
GridPoolConex.ColWidths[5]:= 30;
GridPoolConex.Cells[0,0]:='Ip';GridPoolConex.Cells[1,0]:='Address';
GridPoolConex.Cells[2,0]:='HRate';GridPoolConex.Cells[3,0]:='Ver';GridPoolConex.Cells[4,0]:='Ping';
GridPoolConex.Cells[5,0]:='Bad';
GridPoolConex.Enabled := true;
GridPoolConex.GridLineWidth := 1;
GridPoolConex.PopupMenu:=PoolConexPopUP;
GridPoolConex.OnContextPopup:=@formpool.checkPoolConexPopup;

EdBuFee := TLabel.Create(FormPool); EdBuFee.Parent:=FormPool;
EdBuFee.Left:=480;EdBuFee.top:=232;
EdBuFee.Height:=18;EdBuFee.Width:=75;
EdBuFee.Font.Name:='consolas';EdBuFee.Font.Size:=UserFontSize;
EdBuFee.Caption:='Pool Fee: ';EdBuFee.Alignment:=taLeftJustify;
EdBuFee.Visible:=true;

EdMaxMem := TLabel.Create(FormPool); EdMaxMem.Parent:=FormPool;
EdMaxMem.Left:=480;EdMaxMem.top:=247;
EdMaxMem.Height:=18;EdMaxMem.Width:=75;
EdMaxMem.Caption:='Members: ';EdMaxMem.Alignment:=taLeftJustify;
EdMaxMem.Font.Name:='consolas';EdMaxMem.Font.Size:=UserFontSize;
EdMaxMem.Visible:=true;

EdPayRate := TLabel.Create(FormPool); EdPayRate.Parent:=FormPool;
EdPayRate.Left:=480;EdPayRate.top:=262;
EdPayRate.Height:=18;EdPayRate.Width:=75;
EdPayRate.Caption:='Interval: ';EdPayRate.Alignment:=taLeftJustify;
EdPayRate.Font.Name:='consolas';EdPayRate.Font.Size:=UserFontSize;
EdPayRate.Visible:=true;

EdPooExp := TLabel.Create(FormPool); EdPooExp.Parent:=FormPool;
EdPooExp.Left:=480;EdPooExp.top:=277;
EdPooExp.Height:=18;EdPooExp.Width:=75;
EdPooExp.Caption:='Expel: ';EdPooExp.Alignment:=taLeftJustify;
EdPooExp.Font.Name:='consolas';EdPooExp.Font.Size:=UserFontSize;
EdPooExp.Visible:=true;

EdShares := TLabel.Create(FormPool); EdShares.Parent:=FormPool;
EdShares.Left:=480;EdShares.top:=292;
EdShares.Height:=18;EdShares.Width:=75;
EdShares.Caption:='Shares: ';EdShares.Alignment:=taLeftJustify;
EdShares.Font.Name:='consolas';EdShares.Font.Size:=UserFontSize;
EdShares.Visible:=true;

End;

Procedure UpdatePoolForm();
var
  contador : integer;
  ActiveConex : integer;
Begin
LabelPoolData.Caption:='ConnectTo: '+MyPoolData.Ip+':'+IntToStr(MyPoolData.port)+' MyAddress: '+MyPoolData.MyAddress+slinebreak+
                       'MineAddres: '+MyPoolData.Direccion+' Prefix: '+MyPoolData.Prefijo+slinebreak+
                       'Balance: '+Int2curr(MyPoolData.balance)+' ('+IntToStr(MyPoolData.LastPago)+') Password: '+MyPoolData.Password+' HashRate: '+IntToStr(Miner_PoolHashRate);
if Miner_OwnsAPool then
   begin
   //EnterCriticalSection(CSPoolMembers);
   GridPoolMembers.RowCount:=length(ArrayPoolMembers)+1;
   if length(ArrayPoolMembers) > 0 then
      begin
      for contador := 0 to length(ArrayPoolMembers)-1 do
         begin
         try
         GridPoolMembers.Cells[0,contador+1]:=ArrayPoolMembers[contador].Direccion;
         GridPoolMembers.Cells[1,contador+1]:=ArrayPoolMembers[contador].Prefijo;
         GridPoolMembers.Cells[2,contador+1]:=IntToStr(ArrayPoolMembers[contador].Soluciones);
         GridPoolMembers.Cells[3,contador+1]:=Int2curr(ArrayPoolMembers[contador].Deuda);
         GridPoolMembers.Cells[4,contador+1]:=Int2curr(ArrayPoolMembers[contador].TotalGanado);
         GridPoolMembers.Cells[5,contador+1]:=IntToStr(ArrayPoolMembers[contador].LastSolucion);
         Except on E:Exception do
            begin
            Tolog('Error showing pool members data');
            end;
         end;
         end;
      end;

   ActiveConex := GetPoolTotalActiveConex;
   LabelPoolMiner.Caption:='Block: '+IntToStr(PoolMiner.Block)+' Diff: '+IntToStr(poolminer.Dificult)+
                           ' DiffChars: '+IntToStr(Poolminer.DiffChars)+' Steps: '+IntToStr(PoolMiner.steps)+
                           ' Earned: '+Int2Curr(PoolInfo.FeeEarned)+' '+booltostr(form1.PoolServer.Active,true);
   LabelPoolMiner2.Caption:='Members: '+IntToStr(length(ArrayPoolMembers))+' Total Debt: '+Int2Curr(PoolMembersTotalDeuda)+
                                      ' Connected: '+IntToStr(GetPoolTotalActiveConex)+'/'+IntToStr(form1.PoolClientsCount)+' Hashrate: '+
                                      IntToStr(PoolTotalHashRate);
   //LeaveCriticalSection(CSPoolMembers);
   if (ActiveConex>0)  then
      begin
      if U_PoolConexGrid then
         begin
         for contador := 0 to length(PoolServerConex)-1 do
         begin
            try
               GridPoolConex.Cells[0,contador+1]:=PoolServerConex[contador].Ip;
               GridPoolConex.Cells[1,contador+1]:=PoolServerConex[contador].Address;
               GridPoolConex.Cells[2,contador+1]:=IntToStr(PoolServerConex[contador].Hashpower);
               GridPoolConex.Cells[3,contador+1]:=PoolServerConex[contador].version;
               GridPoolConex.Cells[4,contador+1]:=IntToStr(StrToInt64(UTCTime)-PoolServerConex[contador].LastPing);
               GridPoolConex.Cells[5,contador+1]:=IntToStr(PoolServerConex[contador].WrongSteps);
            Except on E:Exception do
               begin
               //toexclog('Error showing pool connections data, slot '+IntToStr(contador));
               end;
            end;
            end;
         U_PoolConexGrid := true;
         end;
      end;
   end;
End;

// Inicializa el grid donde se muestran los datos
Procedure InicializarGUI();
var
  contador : integer = 0;
Begin
// datapanel
form1.DataPanel.Cells[0,0]:=rs0504;  //'Balance'
form1.DataPanel.Cells[0,1]:=rs0505; //'Server'
form1.DataPanel.Cells[0,2]:=rs0506;  //'Connections'
form1.DataPanel.Cells[0,3]:=rs0507;  //'Headers'
form1.DataPanel.Cells[0,4]:=rs0508;  //'Summary'
form1.DataPanel.Cells[0,5]:=rs0509;  //Lastblock
form1.DataPanel.Cells[0,6]:=rs0510;  //'Blocks'
form1.DataPanel.Cells[0,7]:=rs0511;  //'Pending'

form1.DataPanel.Cells[2,0]:=LangLine(103);  //'Miner'
form1.DataPanel.Cells[2,1]:=LangLine(104);  //'Hashing'
form1.DataPanel.Cells[2,2]:=LangLine(105);  //'Target'
form1.DataPanel.Cells[2,3]:=LangLine(106);  //'Reward'
form1.DataPanel.Cells[2,4]:=LangLine(107);  //'Block Time'
form1.DataPanel.Cells[2,5]:='PoolBalance';  //'Pool Balance'
form1.DataPanel.Cells[2,6]:='Net Time';     //'mainnet Time'

form1.GridMyTxs.Cells[0,0]:=LangLine(108);    //'Block'
form1.GridMyTxs.Cells[1,0]:=LangLine(109);    //'Time'
form1.GridMyTxs.Cells[2,0]:=LangLine(110);    //'Type'
form1.GridMyTxs.Cells[3,0]:=LangLine(111);    //'Amount'

Form1.SGridSC.Cells[0,0]:=rs0501;  //'Destination'
Form1.SGridSC.Cells[0,1]:=rs0502;  //'Amount'
Form1.SGridSC.Cells[0,2]:=rs0503;  //'reference'

//Direccionespanel
form1.Direccionespanel.RowCount:=length(listadirecciones)+1;
form1.Direccionespanel.Cells[0,0] := rs0514;  //'Address'
form1.Direccionespanel.Cells[1,0] := rs0515;  //'Balance'

for contador := 0 to length(ListaDirecciones)-1 do
   begin
   form1.Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Hash;
   form1.Direccionespanel.Cells[1,contador+1] := Int2Curr(ListaDirecciones[contador].Balance);
   end;
NetSumarioHash.Value:='?';
NetLastBlock.Value:='?';
NetResumenHash.Value:='?';
End;

// Ordena las salidas de informacion
Procedure OutText(Texto:String;inctime:boolean = false;canal : integer =0);
Begin
if inctime then texto := timetostr(now)+' '+texto;
if canal = 0 then ConsoleLinesAdd(texto);
if canal = 1 then  // Salida al grid de inicio
   begin
   gridinicio.RowCount:=gridinicio.RowCount+1;
   gridinicio.Cells[0,gridinicio.RowCount-1]:=Texto;
   gridinicio.TopRow:=gridinicio.RowCount;
   Application.ProcessMessages;
   Delay(1);
   end;
if canal = 2 then // A consola y label info
   begin
   ConsoleLinesAdd(texto);
   info(texto);
   end;
End;

// Show lines to Console
Procedure MostrarLineasDeConsola();
Begin
While ConsoleLines.Count > 0 do
   begin
   form1.Memoconsola.Lines.Add(ConsoleLines[0]);
   EnterCriticalSection(CSConsoleLines);
      try
         try
         ConsoleLines.Delete(0);
         Except on E:Exception do
            ToLog('Error showing lines to console');
         end;
      finally
      LeaveCriticalSection(CSConsoleLines);
      end;
   end;
End;

// Actualiza los datos en el grid
Procedure ActualizarGUI();
var
  contador : integer = 0;
Begin
// UPDATE POOL MINERS GRID
if form1.PCPool.ActivePage = Form1.TabPoolMiners then
   begin
   //EnterCriticalSection(CSPoolMembers);
   if length(ArrayPoolMembers) > 0 then
      begin
      for contador := 0 to length(ArrayPoolMembers)-1 do
         begin
         try
         Form1.SG_PoolMiners.Cells[0,contador+1]:=Copy(ArrayPoolMembers[contador].Direccion,0,5);
         Form1.SG_PoolMiners.Cells[1,contador+1]:=Copy(ArrayPoolMembers[contador].Prefijo,0,2);
         Form1.SG_PoolMiners.Cells[2,contador+1]:=IntToStr(ArrayPoolMembers[contador].Soluciones);
         Form1.SG_PoolMiners.Cells[3,contador+1]:=Int2curr(ArrayPoolMembers[contador].Deuda);
         if PoolServerConex[contador].LastPing = 0 then
            Form1.SG_PoolMiners.Cells[4,contador+1]:= ''
         else Form1.SG_PoolMiners.Cells[4,contador+1]:=IntToStr(UTCTime.ToInt64-PoolServerConex[contador].LastPing);
         if Form1.SG_PoolMiners.Cells[4,contador+1]= '' then
            Form1.SG_PoolMiners.Cells[5,contador+1]:= ''
         else Form1.SG_PoolMiners.Cells[5,contador+1]:= IntToStr(PoolServerConex[contador].Hashpower);
         if PoolServerConex[contador].LastPing = 0 then
            Form1.SG_PoolMiners.Cells[6,contador+1]:= ''
         else Form1.SG_PoolMiners.Cells[6,contador+1]:= PoolServerConex[contador].version;
         if PoolServerConex[contador].LastPing = 0 then
            Form1.SG_PoolMiners.Cells[7,contador+1]:= ''
         else Form1.SG_PoolMiners.Cells[7,contador+1]:= PoolServerConex[contador].Ip;
         if PoolServerConex[contador].LastPing = 0 then
            Form1.SG_PoolMiners.Cells[8,contador+1]:= ''
         else Form1.SG_PoolMiners.Cells[8,contador+1]:= IntToStr(PoolServerConex[contador].Context.Connection.IOHandler.InputBuffer.Size);
         Except on E:Exception do
            begin
            ToExclog('Error showing pool members data: '+E.Message);
            end;
         end;
         end;
      end;
   //LeaveCriticalSection(CSPoolMembers);
   end;

// Update poolstats grid
if form1.PCPool.ActivePage = Form1.TabPoolStats then
   begin
   if form1.PoolServer.Active then
      begin
      if form1.PoolPanelBlink.Visible then form1.PoolPanelBlink.Visible := false
      else form1.PoolPanelBlink.Visible := true;
      end;
      try
      Form1.SG_PoolStats.Cells[1,0] := booltostr(form1.PoolServer.Active,true);
      Form1.SG_PoolStats.Cells[1,1] := IntToStr(PoolMiner.Block);
      Form1.SG_PoolStats.Cells[1,2] := IntToStr(poolminer.Dificult);
      Form1.SG_PoolStats.Cells[1,3] := IntToStr(Poolminer.DiffChars);
      Form1.SG_PoolStats.Cells[1,4] := IntToStr(PoolMiner.steps);
      Form1.SG_PoolStats.Cells[1,5] := IntToStr(length(ArrayPoolMembers));
      Form1.SG_PoolStats.Cells[1,6] := IntToStr(GetPoolTotalActiveConex)+'/'+IntToStr(form1.PoolClientsCount);
      Form1.SG_PoolStats.Cells[1,7] := Int2Curr(PoolMembersTotalDeuda);
      Form1.SG_PoolStats.Cells[1,8] := ShowHashrate(PoolTotalHashRate);
      Form1.SG_PoolStats.Cells[1,9] := Int2Curr(PoolInfo.FeeEarned);
      Form1.SG_PoolStats.Cells[1,10] := '('+IntToStr(Lastblockdata.TimeLast20)+') '+TimeSinceStamp(LastblockData.TimeEnd);
      Form1.SG_PoolStats.Cells[1,11] := IntToStr(Length(Miner_PoolSharedStep));
      Except on E:Exception do
         begin
         ToExclog('Error showing pool stats data: '+E.Message);
         end;
      end;
   end;

//Update Monitor Grid
if form1.PCMonitor.ActivePage = Form1.TabMonitorMonitor then
   begin
   setmilitime('UpdateGUIMonitor',1);
   if length(MilitimeArray)>0 then
      begin
      Form1.SG_Monitor.RowCount:=Length(MilitimeArray)+1;
      for contador := 0 to Length(MilitimeArray)-1 do
         begin
            try
            Form1.SG_Monitor.Cells[0,contador+1]:=MilitimeArray[contador].Name;
            Form1.SG_Monitor.Cells[1,contador+1]:=IntToStr(MilitimeArray[contador].Count);
            Form1.SG_Monitor.Cells[2,contador+1]:=IntToStr(MilitimeArray[contador].maximo);
            Form1.SG_Monitor.Cells[3,contador+1]:=IntToStr(MilitimeArray[contador].Total div MilitimeArray[contador].Count);
            Except on E:Exception do
               begin
               ToExcLog(format('Error showing milimite data(%s): %s',[MilitimeArray[contador].Name,E.Message]));
               end;
            end;
         end;
      end;
   setmilitime('UpdateGUIMonitor',2);
   end;

if U_DataPanel then
   begin
   form1.DataPanel.Cells[1,1]:=Booltostr(form1.Server.Active, true)+'('+IntToStr(UserOptions.Port)+')';
   form1.DataPanel.Cells[1,3]:=copy(myResumenHash,0,5)+'/'+copy(NetResumenHash.Value,0,5)+'('+IntToStr(NetResumenHash.Porcentaje)+')';
   form1.DataPanel.Cells[1,4]:=Copy(MySumarioHash,0,5)+'/'+Copy(NetSumarioHash.Value,0,5)+'('+IntToStr(NetSumarioHash.Porcentaje)+')';
   form1.DataPanel.Cells[1,6]:=IntToStr(MyLastBlock)+'/'+NetLastBlock.Value+'('+IntToStr(NetLastBlock.Porcentaje)+')';
   form1.DataPanel.Cells[1,5]:=Copy(MyLastBlockHash,0,5)+'/'+copy(NetLastBlockHash.Value,0,5)+'('+IntToStr(NetLastBlockHash.Porcentaje)+')';
   U_DataPanel := false;
   end;

if U_PoSGrid then
   begin
   form1.GridPoS.Cells[1,0]:=Int2Curr((GetSupply(MyLastBlock+1)*PosStackCoins) div 10000)+' '+coinsimbol;
   form1.GridPoS.Cells[1,1]:=IntToStr(GetMyPosAddressesCount);
   form1.GridPoS.Cells[1,2]:=Int2Curr(G_PoSEarnings)+' '+CoinSimbol;
   U_PoSGrid := false;
   End;

if (Miner_IsOn) then
   Begin
   if MINER_HashCounter > Miner_UltimoRecuento then Miner_EsteIntervalo := MINER_HashCounter-Miner_UltimoRecuento
   else Miner_EsteIntervalo := MINER_HashCounter+900000000-Miner_UltimoRecuento;
   Miner_UltimoRecuento := MINER_HashCounter;
   form1.DataPanel.Cells[3,0]:=BoolToStr(Miner_IsOn,true)+'('+IntToStr(Miner_DifChars)+') '+IntToStr(Miner_FoundedSteps)+'/'+IntToStr(Miner_Steps);
   form1.DataPanel.Cells[3,1]:=IntToStr(G_MiningCPUs)+' CPU   '+IntToStr(Miner_EsteIntervalo*5 div 1000) +' k/s';
   form1.DataPanel.Cells[3,2]:='['+IntToStr(Miner_Difficult)+'] '+copy(Miner_Target,1,Miner_DifChars);
   form1.DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
   form1.DataPanel.Cells[3,4]:='('+IntToStr(Lastblockdata.TimeLast20)+') '+TimeSinceStamp(LastblockData.TimeEnd)
   end
else
   begin
   form1.DataPanel.Cells[3,0]:=BoolToStr(Miner_IsOn,true)+'('+IntToStr(Miner_DifChars)+') '+IntToStr(Miner_FoundedSteps)+'/'+IntToStr(Miner_Steps);
   form1.DataPanel.Cells[3,1]:=LangLine(119); //'Not minning'
   form1.DataPanel.Cells[3,2]:='['+IntToStr(Miner_Difficult)+'] '+copy(Miner_Target,1,Miner_DifChars);
   form1.DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
   form1.DataPanel.Cells[3,4]:='('+IntToStr(Lastblockdata.TimeLast20)+') '+TimeSinceStamp(LastblockData.TimeEnd);
   end;

if UserOptions.UsePool then form1.DataPanel.Cells[3,5]:=Int2curr(MyPoolData.balance)
else form1.DataPanel.Cells[3,5]:='No Pool';

// Esta se muestra siempre aparte ya que la funcion GetTotalConexiones es la que permite
// verificar si los clientes siguen conectados
setmilitime('UpdateGUITime',1);
form1.DataPanel.Cells[1,2]:=IntToStr(GetTotalConexiones)+' ('+IntToStr(MyConStatus)+') ['+IntToStr(G_TotalPings)+']';
form1.DataPanel.Cells[1,7]:= IntToStr(Length(PendingTXs))+'/'+NetPendingTrxs.Value+'('+IntToStr(NetPendingTrxs.Porcentaje)+')';
form1.DataPanel.Cells[1,0]:= Int2Curr(GetWalletBalance)+' '+CoinSimbol;
form1.DataPanel.Cells[3,6]:= TimestampToDate(UTCTime);
setmilitime('UpdateGUITime',2);

if U_DirPanel then
   begin
   setmilitime('UpdateDirPanel',1);
   form1.Direccionespanel.RowCount:=length(listadirecciones)+1;
   for contador := 0 to length(ListaDirecciones)-1 do
      begin
      if ListaDirecciones[contador].Custom<>'' then
        form1.Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Custom
      else form1.Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Hash;
      form1.Direccionespanel.Cells[1,contador+1] := Int2Curr(ListaDirecciones[contador].Balance-ListaDirecciones[contador].pending);
      end;
   form1.LabelBigBalance.Caption := form1.DataPanel.Cells[1,0];
   U_DirPanel := false;
   setmilitime('UpdateDirPanel',2);
   end;

if U_Mytrxs then
   begin
   UpdateMyTrxGrid();
   U_Mytrxs := false;
   end;
// Actualizar el tiempo de las transacciones ralentiza mucho el GUI
//if LastMyTrxTimeUpdate+60<StrToInt64(UTCTime) then UpdateMyTrxGrid();
End;

// Devuelve Una linea del idioma
function LangLine(linea:integer):string;
Begin
if ((linea <= LanguageLines-1) and (StringListLang[linea]<>'')) then
   begin
   result := StringListLang[linea];
   end
else result := 'ErrLng: '+IntToStr(linea);
End;

// Carga el idioma espeficicado o muestra la informacion del idioma  activo
Procedure language(linea:string);
var
  number : string;
  contador : integer = 0;
  Disponibles : string = '';
Begin
number := Lowercase(parameter(linea,1));
if not fileexists('locale'+DirectorySeparator+'noso.'+number+'.po') then
   ConsoleLinesadd(format(rs0512,[number]))
else
   Begin
   SetDefaultLang(number);
   outtext(rs0513,false,2);
   WO_Language := number;
   S_AdvOpt := true;
   end;
{// DEPRECATED LANGUAGE SYSTEM
number := Parameter(linea,1);
if number = '' then // mostrar la info
   begin
   ConsoleLinesAdd(LangLine(1)+CurrentLanguage);     //Current Language:
   ConsoleLinesAdd(LangLine(2)+IntToStr(LanguageLines));   // Lines:
   for contador := 0 to IdiomasDisponibles.Count- 1 do
      Disponibles := Disponibles+'['+IntToStr(contador)+'] '+IdiomasDisponibles[contador];
   ConsoleLinesAdd(LangLine(5)+Disponibles);  //Available Languages:
   end
else
   begin
   if (strToIntDef(number,-1) > -1) and (strToIntDef(number,-1)<=IdiomasDisponibles.Count-1) then
      begin
      CargarIdioma(strTointDef(number,0));
      Outtext(LangLine(3)+IdiomasDisponibles[StrToIntDef(number,0)],false,2); //Language changed to:
      U_DataPanel := true;
      end
   else ConsoleLinesAdd(LangLine(4));   //Invalid language number.
   end;
   }
end;

// Muestra el numero de notoshis como currency
function Int2Curr(Value: int64): string;
begin
Result := IntTostr(Abs(Value));
result :=  AddChar('0',Result, 9);
Insert('.',Result, Length(Result)-7);
If Value <0 THen Result := '-'+Result;
end;

// Devuelve la linea donde la orden ya se esta mostrando, o cero si aun no aparece
function OrderShowed(OrderID:String):integer;
var
  cont : integer;
Begin
result := 0;
if form1.GridMyTxs.RowCount> 1 then
   begin
   for cont := 1 to form1.GridMyTxs.RowCount-1 do
      if form1.GridMyTxs.Cells[4,cont] = OrderID then result := cont;
   end;
End;

// Actualiza el grid que contiene mis transacciones
Procedure UpdateMyTrxGrid();
var
  contador : integer;
  OrdIndex : integer;
  Linea : integer;
  PreMonto, nuevomonto : int64;
  LastToshow : integer;
Begin
setmilitime('UpdateMyTrxGrid',1);
SetCurrentJob('UpdateMyTrxGrid',true);
form1.GridMyTxs.RowCount:=1;
if Length(ListaMisTrx)>1 then
   begin
   LastToshow := length(ListaMisTrx)-1- ShowedOrders;
   if  LastToshow<1 then LastToshow := 1;
   for contador := length(ListaMisTrx)-1 downto LastToshow do
      begin
      OrdIndex := OrderShowed(ListaMisTrx[contador].OrderID);
      if ((ListaMisTrx[contador].tipo='MINE') or (OrdIndex=0)) then // la orden no esta
         begin
         form1.GridMyTxs.RowCount:=form1.GridMyTxs.RowCount+1; Linea := form1.GridMyTxs.RowCount-1;
         form1.GridMyTxs.Cells[0,linea]:=IntToStr(ListaMisTrx[contador].block);     //bloque
         form1.GridMyTxs.Cells[1,linea]:=TimeSinceStamp(ListaMisTrx[contador].time);// tiempo
         form1.GridMyTxs.Cells[2,linea]:=ListaMisTrx[contador].tipo;                // tipo
         form1.GridMyTxs.Cells[3,linea]:=Int2curr(ListaMisTrx[contador].monto);     //monto show
         form1.GridMyTxs.Cells[4,linea]:=ListaMisTrx[contador].OrderID;             //orderID
         form1.GridMyTxs.Cells[5,linea]:=IntToStr(ListaMisTrx[contador].monto);   //elmonto puro
         form1.GridMyTxs.Cells[6,linea]:=ListaMisTrx[contador].receiver;           //address recibe
         form1.GridMyTxs.Cells[7,linea]:=ListaMisTrx[contador].reference;           // reference
         form1.GridMyTxs.Cells[8,linea]:=ListaMisTrx[contador].trfrID;            // trfrs ids
         form1.GridMyTxs.Cells[9,linea]:='1';                                     //numero trfrs
         end
      else  // ya hubo otra transfer con este mismo id de orden
         begin
         PreMonto := StrToInt64Def(form1.GridMyTxs.Cells[5,linea],0);
         nuevomonto := ListaMisTrx[contador].monto+Premonto;
         form1.GridMyTxs.Cells[5,linea]:=IntToStr(NuevoMonto);
         form1.GridMyTxs.Cells[3,linea]:=Int2curr(NuevoMonto);
         if not AnsiContainsStr(form1.GridMyTxs.Cells[8,linea],ListaMisTrx[contador].trfrID) then
            begin
            form1.GridMyTxs.Cells[8,linea]:=form1.GridMyTxs.Cells[8,linea]+' '+ListaMisTrx[contador].trfrID;
            form1.GridMyTxs.Cells[9,linea]:=IntToStr(StrToIntDef(form1.GridMyTxs.Cells[9,linea],0)+1);
            end
         else form1.GridMyTxs.Cells[10,linea]:='YES'; // Que si es una trfr propia
         end;
      end;
   end;
LastMyTrxTimeUpdate := StrToInt64(UTCTime);
SetCurrentJob('UpdateMyTrxGrid',false);
setmilitime('UpdateMyTrxGrid',2);
End;

// Returns alias or hash if address is not aliased
Function AddrText(hash:String):String;
var
  cont : integer;
Begin
Result := hash;
if length(listasumario) > 0 then
   begin
   for cont := 0 to length(listasumario)-1 do
      begin
      if ((hash = Listasumario[cont].hash) and (Listasumario[cont].Custom<>'')) then
         begin
         result := Listasumario[cont].Custom;
         break;
         end;
      end;
   end;
End;

// Actualiza la informacion de la label info
Procedure Info(text:string);
Begin
Form1.InfoPanel.Caption:=copy(text,1,40);
InfoPanelTime := Length(text)*50;If InfoPanelTime<1000 then InfoPanelTime:= 1000;
Form1.InfoPanel.Visible:=true;
Form1.InfoPanel.BringToFront;
Form1.InfoPanel.Refresh;
if form1.InfoTimer.Enabled=false then form1.InfoTimer.Enabled:=true;
End;

// Fija el texto de hint
Procedure Processhint(sender:TObject);
var
  texto : string = '';
Begin
if sender=form1.ConnectButton then
   begin
   if MyConStatus = 0 then texto:=LangLine(33); //'Disconnected'
   if MyConStatus = 1 then texto:=LangLine(34); //'Connecting...'
   if MyConStatus = 2 then texto:=LangLine(35); //'Connected'
   if MyConStatus = 3 then texto:=LangLine(122)+IntToStr(GetTotalConexiones)+LangLine(123); //'Updated with '+
   form1.ConnectButton.Hint:=texto;
   end;
if sender=form1.ImageInc then
   begin
   form1.ImageInc.Hint:='Incoming: '+Int2curr(MontoIncoming);
   end;
if sender=form1.ImageOut then
   begin
   form1.ImageOut.Hint:='Outgoing: '+Int2curr(MontoOutgoing);
   end;
End;

// Mostrar el globo del trayicon
Procedure ShowGlobo(Titulo,texto:string);
Begin
if Form1.SystrayIcon.Visible then
   begin
   form1.SystrayIcon.BalloonTitle:=Titulo;
   Form1.SystrayIcon.BalloonHint:=Texto;
   form1.SystrayIcon.BalloonTimeout:=3000;
   form1.SystrayIcon.ShowBalloonHint;
   end;
End;

// El procemiento para llevar el control del monitoreo del tiempo
Procedure SetMiliTime(Name:string;tipo:integer);
var
  count : integer;
  addnew : boolean = true;
Begin
if ((tipo = 1) and (length(MilitimeArray)>0)) then // tipo iniciar
   begin
   for count := 0 to length(MilitimeArray) -1 do
      begin
      if name = MilitimeArray[count].Name then
         begin
         MilitimeArray[count].Start:=GetTickCount64;
         MilitimeArray[count].Count+=1;
         addnew := false;
         break;
         end;
      end;
   end;
if tipo= 2 then
   begin
   for count := 0 to length(MilitimeArray) -1 do
      begin
      if name = MilitimeArray[count].Name then
         begin
         MilitimeArray[count].finish:=GetTickCount64;
         MilitimeArray[count].duration:=MilitimeArray[count].finish-MilitimeArray[count].Start;
         MilitimeArray[count].Total:=MilitimeArray[count].Total+MilitimeArray[count].duration;
         if MilitimeArray[count].duration>MilitimeArray[count].Maximo then
            MilitimeArray[count].Maximo := MilitimeArray[count].duration;
         if MilitimeArray[count].duration<MilitimeArray[count].Minimo then
            MilitimeArray[count].Minimo := MilitimeArray[count].duration;
         addnew := false;
         break;
         end;
      end;
   end;
if addnew then
   begin
   setlength(MilitimeArray,length(MilitimeArray)+1);
   MilitimeArray[length(MilitimeArray)-1] := default(MilitimeData);
   MilitimeArray[length(MilitimeArray)-1].Name:=name;
   MilitimeArray[length(MilitimeArray)-1].Minimo:=9999;
   MilitimeArray[length(MilitimeArray)-1].Start:=GetTickCount64;
   MilitimeArray[length(MilitimeArray)-1].Count:=1;
   end;
End;

// Fija el valor de la variable con el proceso actual
Procedure SetCurrentJob(CurrJob:String;status:boolean);
Begin
if status then
   currentjob := CurrentJob+'>'+CurrJob
else
   currentjob := StringReplace(currentjob,'>'+CurrJob,'',[rfReplaceAll, rfIgnoreCase]);
End;

Procedure CloseAllForms();
Begin
   try
   formslots.Visible:=false;
   CloseExplorer;
   Except on E: Exception do
      begin

      end;
   end;
End;

Procedure UpdateRowHeigth();
var
  contador : integer;
Begin
form1.DataPanel.Font.Size:=UserFontSize;
for contador := 0 to form1.datapanel.RowCount-1 do
   begin
   form1.DataPanel.RowHeights[contador]:=UserRowHeigth;
   end;
End;

// POOLMEMBERS POPUP

Procedure TFormPool.checkPoolMembersPopup(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if MyLastBlock-(GetLastPagoPoolMember(ArrayPoolMembers[GridPoolMembers.Row-1].Direccion)+PoolInfo.TipoPago) > 0 then
      begin
      PoolMembersPopUp.Items[2].Enabled:=true;
      PoolMembersPopUp.Items[2].Caption:='Pay '+Int2curr(GetPoolMemberBalance(ArrayPoolMembers[GridPoolMembers.Row-1].Direccion));
      end
   else
      begin
      PoolMembersPopUp.Items[2].Enabled:=false;
      PoolMembersPopUp.Items[2].Caption:=IntToStr(MyLastBlock-(GetLastPagoPoolMember(ArrayPoolMembers[GridPoolMembers.Row-1].Direccion)+PoolInfo.TipoPago));
      end;
if IsPoolMemberConnected(GridPoolMembers.Cells[0,GridPoolMembers.Row])>=0 then
   begin
   PoolMembersPopUp.Items[3].Enabled:=true;
   PoolMembersPopUp.Items[0].Enabled:=false;
   PoolMembersPopUp.Items[3].Caption:='Connection';
   end
else
   begin
   PoolMembersPopUp.Items[3].Enabled:=false;
   PoolMembersPopUp.Items[0].Enabled:=true;
   PoolMembersPopUp.Items[3].Caption:='Not connected';
   end;
End;

// Copy pool member address to clipbloard
Procedure TFormPool.CopyPoolMemberAddres(Sender:TObject);
Begin
if GridPoolMembers.Row >0 then
  Clipboard.AsText:= GridPoolMembers.Cells[0,GridPoolMembers.Row];
End;

// Expel member paying
Procedure TFormPool.PoolExpelPaying(Sender:TObject);
Begin
ProcessLinesAdd('POOLEXPEL '+GridPoolMembers.Cells[0,GridPoolMembers.Row]+' YES');
End;

// Expel member without pay
Procedure TFormPool.PoolExpelNotPay(Sender:TObject);
Begin
ProcessLinesAdd('POOLEXPEL '+GridPoolMembers.Cells[0,GridPoolMembers.Row]);
End;

// pay user
Procedure TFormPool.BPayuserOnClick(Sender: TObject);
var
  userdireccion : string;
  MemberBalance : Int64;
Begin
userdireccion := ArrayPoolMembers[GridPoolMembers.Row-1].Direccion;
MemberBalance := GetPoolMemberBalance(UserDireccion);
ProcessLinesAdd('sendto '+UserDireccion+' '+IntToStr(GetMaximunToSend(MemberBalance))+' POOLPAYMENT_'+PoolInfo.Name);
ClearPoolUserBalance(UserDireccion);
ConsoleLinesAdd('Pool payment sent: '+inttoStr(GetMaximunToSend(MemberBalance)));
tolog('Pool payment sent: '+inttoStr(GetMaximunToSend(MemberBalance)));
End;

// Go to active connection
Procedure TFormPool.SeePoolConex(Sender: TObject);
Begin
if IsPoolMemberConnected(GridPoolMembers.Cells[0,GridPoolMembers.Row])>=0 then
   try
   GridPoolConex.Row := IsPoolMemberConnected(GridPoolMembers.Cells[0,GridPoolMembers.Row])+1;
   finally
   end;
End;

// *** POOL CONECTIONS POPUP ***

Procedure TFormPool.checkPoolConexPopup(Sender: TObject;MousePos: TPoint;var Handled: Boolean);
Begin
if GridPoolConex.Row>0 then
   begin
   PoolConexPopUp.Items[0].Enabled:=true;
   PoolConexPopUp.Items[0].Caption:='Kick && Ban '+GridPoolConex.Cells[0,GridPoolConex.Row];
   IpToBan :=  GridPoolConex.Cells[0,GridPoolConex.Row];
   end
else
   begin
   PoolConexPopUp.Items[0].Enabled:=false;
   PoolConexPopUp.Items[0].Caption:='Kick && Ban';
   end;
End;

// Kick and bans a miner IP
Procedure TFormPool.KickBanOnClick(Sender: TObject);
var
  counter : integer;
  thiscontext : TIdContext;
Begin
UpdateBotData(IpToBan);
for counter := 0 to length(PoolServerConex)-1 do
   begin
   if PoolServerConex[counter].Ip = IpToBan then
     begin
     thiscontext := PoolServerConex[counter].Context;
        try
        PoolServerConex[counter].Context.Connection.IOHandler.InputBuffer.Clear;
        PoolServerConex[counter].Context.Connection.Disconnect;
        finally
        BorrarPoolServerConex(thiscontext);
        end;
     end;
   end;

End;


END. // END UNIT

