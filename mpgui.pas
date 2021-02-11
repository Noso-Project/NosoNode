unit mpGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpTime, graphics, strutils, forms, controls, grids,stdctrls,
  crt,ExtCtrls ;

type
  TFormInicio = class(Tform)
    procedure closeFormInicio(Sender: TObject; var CanClose: boolean);
    private
    public
    end;

  TFormLog = class(Tform)
    procedure closeFormLog(Sender: TObject; var CanClose: boolean);
    private
    public
    end;

  TFormAbout = class(Tform)
    //procedure closeFormLog(Sender: TObject; var CanClose: boolean);
    private
    public
    end;

  TFormMonitor = class(Tform)
    Procedure closeFormMonitor(Sender: TObject; var CanClose: boolean);
    private
    public
    end;



Procedure CreateFormInicio();
Procedure CreateFormLog();
Procedure CreateFormAbout();
Procedure CreateFormMilitime();
Procedure UpdateMiliTimeForm();
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

var
  FormInicio : TFormInicio;
    GridInicio : TStringgrid;
  FormLog : TFormLog;
    LogMemo : TMemo;
  FormAbout : TFormAbout;
    ImgAbout : TImage;
    LabelAbout : Tlabel;
  FormMonitor : TFormMonitor;
    GridMiTime : TStringgrid;
    GridMValues : TStringgrid;
    LabelCurrJob : TLabel;
implementation

Uses
  mpParser, mpDisk, mpRed, mpProtocol,mpcoin, mpblock;

// Crea el formulario para el inicio
Procedure CreateFormInicio();
Begin
FormInicio := TFormInicio.Createnew(form1);
FormInicio.caption := 'Noso Launcher';
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
if G_launching then
  begin
  canclose := false;
  exit;
  end;
forminicio.Visible:=false;
form1.Visible:=true;
End;

// Crear el formulario de log viewer
Procedure CreateFormLog();
Begin
FormLog := TFormLog.Createnew(form1);
FormLog.caption := 'Log Viewer';
FormLog.SetBounds(0, 0, 450, 200);
FormLog.BorderStyle := bssingle;
FormLog.Position:=poOwnerFormCenter;
FormLog.BorderIcons:=FormLog.BorderIcons-[biminimize];
FormLog.ShowInTaskBar:=sTAlways;
FormLog.OnCloseQuery:=@FormLog.closeFormLog;

LogMemo := TMemo.Create(FormLog);
LogMemo.Parent:=FormLog;
LogMemo.Left:=1;LogMemo.Top:=1;LogMemo.Height:=198;LogMemo.Width:=448;
LogMemo.Color:=clblack;LogMemo.Font.Color:=clwhite;LogMemo.ReadOnly:=true;
LogMemo.Font.Size:=10;LogMemo.Font.Name:='consolas';
LogMemo.Visible:=true;LogMemo.ScrollBars:=ssvertical;
End;

// Al cerrar el formulario de log viewer
Procedure TFormLog.closeFormLog(Sender: TObject; var CanClose: boolean);
Begin
FormLog.Visible:=false;
End;

// Crear el formulario de about
Procedure CreateFormAbout();
Begin
FormAbout := TFormAbout.Createnew(form1);
FormAbout.caption := 'About '+coinname;
FormAbout.SetBounds(0, 0, 200, 210);
FormAbout.BorderStyle := bssingle;
FormAbout.Position:=poOwnerFormCenter;
FormAbout.BorderIcons:=FormAbout.BorderIcons-[biminimize];
FormAbout.ShowInTaskBar:=sTAlways;
//FormAbout.OnCloseQuery:=@FormLog.closeFormLog;

ImgAbout:= TImage.Create(FormAbout);
ImgAbout.Parent := FormAbout;
ImgAbout.Width:= 100; ImgAbout.Height:= 100;
ImgAbout.Top:= 10; ImgAbout.Left:= 50;
ImgAbout.Picture:=form1.Image1.Picture;

LabelAbout := TLabel.Create(FormAbout);
LabelAbout.Parent := FormAbout;LabelAbout.AutoSize:=false;
LabelAbout.Width:= 200; LabelAbout.Height:= 90;
LabelAbout.Top:= 112; LabelAbout.Left:= 1;
LabelAbout.Caption:=CoinName+' project'+SLINEBREAK+'Designed by PedroJOR'+SLINEBREAK+
'Crypto routines by Xor-el'+SLINEBREAK+
'Version '+ProgramVersion+SLINEBREAK+'Protocol '+IntToStr(Protocolo)+SLINEBREAK+BuildDate;
LabelAbout.Alignment:=taCenter;
End;

// Crear el formulario del monitor
Procedure CreateFormMilitime();
Begin
FormMonitor := TFormMonitor.Createnew(form1);
FormMonitor.caption := CoinName+' Monitor';;
FormMonitor.SetBounds(0, 0, 400, 400);
FormMonitor.BorderStyle := bssingle;
//FormMonitor.Position:=poOwnerFormCenter;
FormMonitor.Top:=1;FormMonitor.Left:=1;
FormMonitor.BorderIcons:=FormMonitor.BorderIcons-[biminimize];
FormMonitor.ShowInTaskBar:=sTAlways;
FormMonitor.OnCloseQuery:=@FormMonitor.closeFormMonitor;

GridMiTime := TStringGrid.Create(FormMonitor);GridMiTime.Parent:=FormMonitor;
GridMiTime.Font.Name:='consolas'; GridMiTime.Font.Size:=10;
GridMiTime.Left:=1;GridMiTime.Top:=1;GridMiTime.Height:=200;GridMiTime.width:=300;
GridMiTime.FixedCols:=0;GridMiTime.FixedRows:=1;
GridMiTime.rowcount := 1;GridMiTime.ColCount:=4;
GridMiTime.ScrollBars:=ssVertical;
GridMiTime.FocusRectVisible:=false;
GridMiTime.Options:= GridMiTime.Options+[goRowSelect]-[goRangeSelect];
GridMiTime.ColWidths[0]:= 160;GridMiTime.ColWidths[1]:= 40;GridMiTime.ColWidths[2]:= 40;GridMiTime.ColWidths[3]:= 40;
GridMiTime.Enabled := true;
GridMiTime.Cells[0,0]:='Function';GridMiTime.Cells[1,0]:='Last';GridMiTime.Cells[2,0]:='Max';GridMiTime.Cells[3,0]:='Min';
GridMiTime.GridLineWidth := 1;

GridMValues := TStringGrid.Create(FormMonitor);GridMValues.Parent:=FormMonitor;
GridMValues.Font.Name:='consolas'; GridMValues.Font.Size:=8;
GridMValues.Left:=1;GridMValues.Top:=202;GridMValues.Height:=100;GridMValues.width:=190;
GridMValues.FixedCols:=0;GridMValues.FixedRows:=0;
GridMValues.rowcount := 5;GridMValues.ColCount:=2;
GridMValues.ScrollBars:=ssVertical;
GridMValues.FocusRectVisible:=false;
GridMValues.Options:= GridMValues.Options+[goRowSelect]-[goRangeSelect];
GridMValues.ColWidths[0]:= 100;GridMValues.ColWidths[1]:= 70;
GridMValues.Enabled := true;
GridMValues.GridLineWidth := 1;

LabelCurrJob := TLabel.Create(FormMonitor);
LabelCurrJob.Parent := FormMonitor;LabelCurrJob.AutoSize:=true;
LabelCurrJob.Top:= 304; LabelCurrJob.Left:= 1;
LabelCurrJob.Caption:='';
End;

// Actualizar el monitor
Procedure UpdateMiliTimeForm();
var
  count : integer;
Begin
if Length(MilitimeArray) < 1 then exit;
GridMiTime.RowCount:=Length(MilitimeArray)+1;
for count := 0 to Length(MilitimeArray)-1 do
   begin
   GridMiTime.Cells[0,count+1]:=MilitimeArray[count].Name;
   GridMiTime.Cells[1,count+1]:=IntToStr(MilitimeArray[count].duration);
   GridMiTime.Cells[2,count+1]:=IntToStr(MilitimeArray[count].maximo);
   GridMiTime.Cells[3,count+1]:=IntToStr(MilitimeArray[count].minimo);
   end;

GridMValues.Cells[0,0]:='InfoPanelTime';
  GridMValues.Cells[1,0]:=IntToStr(InfoPanelTime);
GridMValues.Cells[0,1]:='CriptoThread';
  GridMValues.Cells[1,1]:=IntToStr(length(CriptoOpsTipo));
GridMValues.Cells[0,2]:='MinerSeed';
  GridMValues.Cells[1,2]:=MINER_HashSeed;
GridMValues.Cells[0,3]:='MinerCounter';
  GridMValues.Cells[1,3]:=IntToStr(MINER_HashCounter);
GridMValues.Cells[0,4]:='MinerThreads';
  GridMValues.Cells[1,4]:=IntToStr(Length(Miner_Thread));
End;

// Al cerrar el formulario de log viewer
Procedure TFormMonitor.closeFormMonitor(Sender: TObject; var CanClose: boolean);
Begin
CheckMonitor := false;
End;

// Inicializa el grid donde se muestran los datos
Procedure InicializarGUI();
var
  contador : integer = 0;
Begin
// datapanel
DataPanel.Cells[0,0]:=LangLine(95);  //'Balance'
DataPanel.Cells[0,1]:=LangLine(96); //'Server'
DataPanel.Cells[0,2]:=LangLine(97);  //'Headers'
DataPanel.Cells[0,3]:=LangLine(98);  //'Connections'
DataPanel.Cells[0,4]:=LangLine(99);  //'Summary'
DataPanel.Cells[0,5]:=LangLine(100);  //'Blocks'
DataPanel.Cells[0,6]:=LangLine(101);  //'Public IP'
DataPanel.Cells[0,7]:=LangLine(102);  //'Pending'

DataPanel.Cells[2,0]:=LangLine(103);  //'Miner'
DataPanel.Cells[2,1]:=LangLine(104);  //'Hashing'
DataPanel.Cells[2,2]:=LangLine(105);  //'Target'
DataPanel.Cells[2,3]:=LangLine(106);  //'Reward'
DataPanel.Cells[2,4]:=LangLine(107);  //'Block Time'

GridMyTxs.Cells[0,0]:=LangLine(108);    //'Block'
GridMyTxs.Cells[1,0]:=LangLine(109);    //'Time'
GridMyTxs.Cells[2,0]:=LangLine(110);    //'Type'
GridMyTxs.Cells[3,0]:=LangLine(111);    //'Amount'

GridScrowSell.Cells[0,0]:=LangLine(112);  //'Method'
GridScrowSell.Cells[1,0]:=LangLine(111);  //'Amount'
GridScrowSell.Cells[2,0]:=LangLine(113);  //'Price'
GridScrowSell.Cells[3,0]:=LangLine(114);  //'Total'
GridScrowSell.Cells[4,0]:=LangLine(115);  //'Status'

SGridSC.Cells[0,0]:=LangLine(116);  //'Destination'
SGridSC.Cells[0,1]:=LangLine(111);  //'Amount'
SGridSC.Cells[0,2]:=LangLine(117);  //'Concept'

GridNodes.Cells[0,0]:='IP';
GridNodes.Cells[1,0]:='Port';

GridOptions.Cells[0,0]:='Language';
GridOptions.Cells[0,1]:='Port';
GridOptions.Cells[0,2]:='Max Peers';
GridOptions.Cells[0,3]:='Min Peers';
GridOptions.Cells[0,4]:='Miner CPUs';
GridOptions.Cells[0,5]:='GetNodes';
GridOptions.Cells[0,6]:='Autoserver';
GridOptions.Cells[0,7]:='Autoconnect';
GridOptions.Cells[0,8]:='AutoUpdate';
GridOptions.Cells[0,9]:='To Tray';

//Direccionespanel
Direccionespanel.RowCount:=length(listadirecciones)+1;
Direccionespanel.Cells[0,0] := LangLine(118);  //'Address'
Direccionespanel.Cells[1,0] := LangLine(95);  //'Balance'

for contador := 0 to length(ListaDirecciones)-1 do
   begin
   Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Hash;
   Direccionespanel.Cells[1,contador+1] := Int2Curr(ListaDirecciones[contador].Balance);
   end;
NetSumarioHash.Value:='?';
NetLastBlock.Value:='?';
NetResumenHash.Value:='?';
End;

// Ordena las salidas de informacion
Procedure OutText(Texto:String;inctime:boolean = false;canal : integer =0);
Begin
if inctime then texto := timetostr(now)+' '+texto;
if canal = 0 then Consolelines.Add(texto);
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
   Consolelines.Add(texto);
   info(texto);
   end;
End;

// Muestra las lineas en la consola
Procedure MostrarLineasDeConsola();
Begin
While ConsoleLines.Count > 0 do
   begin
   Memoconsola.Lines.Add(ConsoleLines[0]);
   ConsoleLines.Delete(0);
   end;
End;

// Actualiza los datos en el grid
Procedure ActualizarGUI();
var
  contador : integer = 0;
Begin
if U_DataPanel then
   begin
   DataPanel.Cells[1,1]:=Booltostr(form1.Server.Active, true)+'('+IntToStr(UserOptions.Port)+')';
   DataPanel.Cells[1,2]:=copy(myResumenHash,0,5)+'/'+copy(NetResumenHash.Value,0,5);
   DataPanel.Cells[1,4]:=Copy(MySumarioHash,28,5)+'/'+Copy(NetSumarioHash.Value,28,5);
   DataPanel.Cells[1,5]:=IntToStr(MyLastBlock)+'/'+NetLastBlock.Value;
   DataPanel.Cells[1,6]:=MyPublicIP;
   U_DataPanel := false;
   end;

if (Miner_IsOn) then
   Begin
   if MINER_HashCounter > Miner_UltimoRecuento then Miner_EsteIntervalo := MINER_HashCounter-Miner_UltimoRecuento
   else Miner_EsteIntervalo := MINER_HashCounter+900000000-Miner_UltimoRecuento;
   Miner_UltimoRecuento := MINER_HashCounter;
   DataPanel.Cells[3,0]:=BoolToStr(Miner_IsOn,true)+'('+IntToStr(Miner_DifChars)+') '+IntToStr(Miner_FoundedSteps)+'/'+IntToStr(Miner_Steps);
   DataPanel.Cells[3,1]:=IntToStr(G_MiningCPUs)+' CPU   '+IntToStr(Miner_EsteIntervalo*5 div 1000) +' k/s';
   DataPanel.Cells[3,2]:='['+IntToStr(Miner_Difficult)+'] '+copy(Miner_Target,1,Miner_DifChars);
   DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
   DataPanel.Cells[3,4]:='('+IntToStr(Lastblockdata.TimeLast20)+') '+TimeSinceStamp(LastblockData.TimeEnd);
   if MinerButton.Caption = '' then
      begin MinerButton.Caption := ' '; Form1.imagenes.GetBitmap(5,MinerButton.Glyph);end
   else if MinerButton.Caption = ' ' then
      begin MinerButton.Caption := '  ';Form1.imagenes.GetBitmap(11,MinerButton.Glyph);end
   else if MinerButton.Caption = '  ' then
      begin MinerButton.Caption := '   ';Form1.imagenes.GetBitmap(5,MinerButton.Glyph);end
   else if MinerButton.Caption = '   ' then
      begin MinerButton.Caption := '';Form1.imagenes.GetBitmap(4,MinerButton.Glyph);end;
   end
else
   begin
   DataPanel.Cells[3,0]:=BoolToStr(Miner_IsOn,true)+'('+IntToStr(Miner_DifChars)+') '+IntToStr(Miner_FoundedSteps)+'/'+IntToStr(Miner_Steps);
   DataPanel.Cells[3,1]:=LangLine(119); //'Not minning'
   DataPanel.Cells[3,2]:='['+IntToStr(Miner_Difficult)+'] '+copy(Miner_Target,1,Miner_DifChars);
   DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
   DataPanel.Cells[3,4]:='('+IntToStr(Lastblockdata.TimeLast20)+') '+TimeSinceStamp(LastblockData.TimeEnd);
   Form1.imagenes.GetBitmap(4,MinerButton.Glyph);
   end;

// Esta se muestra siempre aparte ya que la funcion GetTotalConexiones es la que permite
// verificar si los clientes siguen conectados

DataPanel.Cells[1,3]:=IntToStr(GetTotalConexiones)+' ('+IntToStr(MyConStatus)+') ['+IntToStr(G_TotalPings)+']';
DataPanel.Cells[1,7]:= IntToStr(Length(PendingTXs))+'/'+NetPendingTrxs.Value;
DataPanel.Cells[1,0]:= Int2Curr(GetWalletBalance)+' '+CoinSimbol;

if U_DirPanel then
   begin
   Direccionespanel.RowCount:=length(listadirecciones)+1;
   for contador := 0 to length(ListaDirecciones)-1 do
      begin
      if ListaDirecciones[contador].Custom<>'' then
        Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Custom
      else Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Hash;
      Direccionespanel.Cells[1,contador+1] := Int2Curr(ListaDirecciones[contador].Balance-ListaDirecciones[contador].pending);
      end;
   LabelBigBalance.Caption := DataPanel.Cells[1,0];
   U_DirPanel := false;
   end;

if U_Mytrxs then
   begin
   UpdateMyTrxGrid();
   U_Mytrxs := false;
   end;
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
number := Parameter(linea,1);
if number = '' then // mostrar la info
   begin
   Consolelines.add(LangLine(1)+CurrentLanguage);     //Current Language:
   Consolelines.add(LangLine(2)+IntToStr(LanguageLines));   // Lines:
   for contador := 0 to IdiomasDisponibles.Count- 1 do
      Disponibles := Disponibles+'['+IntToStr(contador)+'] '+IdiomasDisponibles[contador];
   Consolelines.Add(LangLine(5)+Disponibles);  //Available Languages:
   end
else
   begin
   if (strToIntDef(number,-1) > -1) and (strToIntDef(number,-1)<=IdiomasDisponibles.Count-1) then
      begin
      CargarIdioma(strToint(number));
      Outtext(LangLine(3)+IdiomasDisponibles[StrToInt(number)],false,2); //Language changed to:
      U_DataPanel := true;
      LangSelect.ItemIndex := StrToInt(number);
      end
   else consolelines.Add(LangLine(4));   //Invalid language number.
   end;
end;

// Muestra el numero de paskoshis como currency
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
if GridMyTxs.RowCount<= 1 then exit;
for cont := 1 to GridMyTxs.RowCount-1 do
   if GridMyTxs.Cells[4,cont] = OrderID then result := cont;
End;

// Actualiza el grid que contiene mis transacciones
Procedure UpdateMyTrxGrid();
var
  contador : integer;
  OrdIndex : integer;
  Linea : integer;
  PreMonto, nuevomonto : int64;
Begin
GridMyTxs.RowCount:=1;
if Length(ListaMisTrx)>1 then
   begin
   for contador := length(ListaMisTrx)-1 downto 1 do
      begin
      OrdIndex := OrderShowed(ListaMisTrx[contador].OrderID);
      if ((ListaMisTrx[contador].tipo='MINE') or (OrdIndex=0)) then // la orden no esta
         begin
         GridMyTxs.RowCount:=GridMyTxs.RowCount+1; Linea := GridMyTxs.RowCount-1;
         GridMyTxs.Cells[0,linea]:=IntToStr(ListaMisTrx[contador].block);     //bloque
         GridMyTxs.Cells[1,linea]:=TimeSinceStamp(ListaMisTrx[contador].time);// tiempo
         GridMyTxs.Cells[2,linea]:=ListaMisTrx[contador].tipo;                // tipo
         GridMyTxs.Cells[3,linea]:=Int2curr(ListaMisTrx[contador].monto);     //monto show
         GridMyTxs.Cells[4,linea]:=ListaMisTrx[contador].OrderID;             //orderID
         GridMyTxs.Cells[5,linea]:=IntToStr(ListaMisTrx[contador].monto);   //elmonto puro
         GridMyTxs.Cells[6,linea]:=ListaMisTrx[contador].receiver;           //address recibe
         GridMyTxs.Cells[7,linea]:=ListaMisTrx[contador].Concepto;           // conceptp
         GridMyTxs.Cells[8,linea]:=ListaMisTrx[contador].trfrID;            // trfrs ids
         GridMyTxs.Cells[9,linea]:='1';                                     //numero trfrs
         end
      else  // ya hubo otra transfer con este mismo id de orden
         begin
         PreMonto := StrToInt64Def(GridMyTxs.Cells[5,linea],0);
         nuevomonto := ListaMisTrx[contador].monto+Premonto;
         GridMyTxs.Cells[5,linea]:=IntToStr(NuevoMonto);
         GridMyTxs.Cells[3,linea]:=Int2curr(NuevoMonto);
         if not AnsiContainsStr(GridMyTxs.Cells[8,linea],ListaMisTrx[contador].trfrID) then
            begin
            GridMyTxs.Cells[8,linea]:=GridMyTxs.Cells[8,linea]+' '+ListaMisTrx[contador].trfrID;
            GridMyTxs.Cells[9,linea]:=IntToStr(StrToIntDef(GridMyTxs.Cells[9,linea],0)+1);
            end
         else GridMyTxs.Cells[10,linea]:='YES'; // Que si es una trfr propia
         end;
      end;
   end;
End;

// DEvuelve el alias de una direccion si existe o el mismo hash si no.
Function AddrText(hash:String):String;
var
  cont : integer;
Begin
Result := hash;
if length(listasumario) = 0 then exit;
for cont := 0 to length(listasumario)-1 do
   begin
   if ((hash = Listasumario[cont].hash) and (Listasumario[cont].Custom<>'')) then
      begin
      result := Listasumario[cont].Custom;
      exit;
      end;
   end;
End;

// Actualiza la informacion de la label info
Procedure Info(text:string);
Begin
InfoPanel.Caption:=copy(text,1,33);
InfoPanelTime := 1000;
InfoPanel.Visible:=true;
InfoPanel.BringToFront;
InfoPanel.Refresh;
if form1.InfoTimer.Enabled=false then form1.InfoTimer.Enabled:=true;
End;

// Fija el texto de hint
Procedure Processhint(sender:TObject);
var
  texto : string = '';
Begin
if sender=ConnectButton then
   begin
   if MyConStatus = 0 then texto:=LangLine(33); //'Disconnected'
   if MyConStatus = 1 then texto:=LangLine(34); //'Connecting...'
   if MyConStatus = 2 then texto:=LangLine(35); //'Connected'
   if MyConStatus = 3 then texto:=LangLine(122)+IntToStr(GetTotalConexiones)+LangLine(123); //'Updated with '+
   ConnectButton.Hint:=texto;
   end;
if sender=MinerButton then
   begin
   texto := LangLine(124); //'Not mining.'
   if ((Miner_IsON) and (Miner_Active)) then texto:=LangLine(108)+' '+IntToStr(Miner_BlockToMine)+SLINEBREAK+DataPanel.Cells[3,1];  //'Block'
   if ((not Miner_IsON) and (Miner_Active)) then texto := LangLine(125); //'Ready for mine'
   MinerButton.hint:= texto;
   end;
if sender=ImageInc then
   begin
   ImageInc.Hint:='Incoming: '+Int2curr(MontoIncoming);
   end;
if sender=ImageOut then
   begin
   ImageOut.Hint:='Outgoing: '+Int2curr(MontoOutgoing);
   end;
End;

// Mostrar el globo del trayicon
Procedure ShowGlobo(Titulo,texto:string);
Begin
if not Form1.SystrayIcon.Visible then exit;
form1.SystrayIcon.BalloonTitle:=Titulo;
Form1.SystrayIcon.BalloonHint:=Texto;
form1.SystrayIcon.BalloonTimeout:=3000;
form1.SystrayIcon.ShowBalloonHint;
End;

// El procemiento para llevar el control del monitoreo del tiempo
Procedure SetMiliTime(Name:string;tipo:integer);
var
  count : integer;
Begin
if not CheckMonitor then exit;
if ((tipo = 1) and (length(MilitimeArray)>0)) then // tipo iniciar
   begin
   for count := 0 to length(MilitimeArray) -1 do
      begin
      if name = MilitimeArray[count].Name then
        begin
        MilitimeArray[count].Start:=GetTickCount64;
        exit;
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
        if MilitimeArray[count].duration>MilitimeArray[count].Maximo then
          MilitimeArray[count].Maximo := MilitimeArray[count].duration;
        if MilitimeArray[count].duration<MilitimeArray[count].Minimo then
          MilitimeArray[count].Minimo := MilitimeArray[count].duration;
        exit;
        end;
      end;
   end;
setlength(MilitimeArray,length(MilitimeArray)+1);
MilitimeArray[length(MilitimeArray)-1].Name:=name;
MilitimeArray[length(MilitimeArray)-1].Start:=GetTickCount64;
End;

Procedure SetCurrentJob(CurrJob:String;status:boolean);
Begin
if status then
   currentjob := CurrentJob+'>'+CurrJob
else
   currentjob := StringReplace(currentjob,'>'+CurrJob,'',[rfReplaceAll, rfIgnoreCase]);
if CheckMonitor then
   begin
   LabelCurrJob.Caption := currentjob;
   LabelCurrJob.Refresh;
   end;
End;

END. // END UNIT

