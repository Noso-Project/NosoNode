unit mpGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpTime, graphics, strutils, forms, controls, grids,stdctrls,
  ExtCtrls, buttons, editbtn , menus, Clipbrd, IdContext, LCLTranslator;

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

function ThisPercent(percent, thiswidth : integer;RestarBarra : boolean = false):integer;
Procedure CreateFormInicio();
Procedure CreateFormSlots();
Procedure UpdateSlotsGrid();
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
Function GetCurrentJob():String;
Procedure CloseAllForms();
Procedure UpdateRowHeigth();
Function HashrateToShow(speed:int64):String;

var
  FormInicio : TFormInicio;
    GridInicio : TStringgrid;
  LastUpdateMonitor : int64 = 0;

  FormSlots : TFormSlots;
    GridMSlots : TStringgrid;
    SlotsLastUpdate : int64 = 0;

implementation

Uses
  mpParser, mpDisk, mpRed, mpProtocol,mpcoin, mpblock, formexplore, translation, mpMN;

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
FormInicio.caption := 'Noso '+ProgramVersion+SubVersion;
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
  CompleteInicio;
  end
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
FormSlots.SetBounds(0, 0, 740, 410);
FormSlots.BorderStyle := bssingle;
//FormSlots.Position:=poOwnerFormCenter;
FormSlots.Top:=1;FormSlots.Left:=1;
FormSlots.BorderIcons:=FormSlots.BorderIcons-[biminimize];
FormSlots.ShowInTaskBar:=sTAlways;

GridMSlots := TStringGrid.Create(FormSlots);GridMSlots.Parent:=FormSlots;
GridMSlots.Font.Name:='consolas'; GridMSlots.Font.Size:=8;
GridMSlots.Left:=1;GridMSlots.Top:=1;GridMSlots.Height:=408;GridMSlots.width:=734;
GridMSlots.FixedCols:=0;GridMSlots.FixedRows:=1;
GridMSlots.rowcount := MaxConecciones+1;GridMSlots.ColCount:=19;
GridMSlots.ScrollBars:=ssVertical;
GridMSlots.FocusRectVisible:=false;
GridMSlots.Options:= GridMSlots.Options-[goRangeSelect];
GridMSlots.ColWidths[0]:= 20;GridMSlots.ColWidths[1]:= 80;GridMSlots.ColWidths[2]:= 25;
GridMSlots.ColWidths[3]:= 20;GridMSlots.ColWidths[4]:= 48;GridMSlots.ColWidths[5]:= 40;
GridMSlots.ColWidths[6]:= 40;GridMSlots.ColWidths[7]:= 25;GridMSlots.ColWidths[8]:= 25;
GridMSlots.ColWidths[9]:= 70;GridMSlots.ColWidths[10]:= 30;GridMSlots.ColWidths[11]:= 25;
GridMSlots.ColWidths[12]:= 40;GridMSlots.ColWidths[13]:= 25;GridMSlots.ColWidths[14]:= 29;
GridMSlots.ColWidths[15]:= 40;GridMSlots.ColWidths[16]:= 25;GridMSlots.ColWidths[17]:= 80;
GridMSlots.ColWidths[18]:= 25;
GridMSlots.Enabled := true;
GridMSlots.Cells[0,0]:='N';GridMSlots.Cells[1,0]:='IP';GridMSlots.Cells[2,0]:='T';
GridMSlots.Cells[3,0]:='Cx';GridMSlots.Cells[4,0]:='LBl';GridMSlots.Cells[5,0]:='LBlH';
GridMSlots.Cells[6,0]:='SumH';GridMSlots.Cells[7,0]:='Pen';GridMSlots.Cells[8,0]:='Pro';
GridMSlots.Cells[9,0]:='Ver';GridMSlots.Cells[10,0]:='LiP';GridMSlots.Cells[11,0]:='Off';
GridMSlots.Cells[12,0]:='HeaH';GridMSlots.Cells[13,0]:='Sta';GridMSlots.Cells[14,0]:='Ping';
GridMSlots.Cells[15,0]:='MNs';GridMSlots.Cells[16,0]:='#';GridMSlots.Cells[17,0]:='Besthash';
GridMSlots.Cells[18,0]:='MNC';
GridMSlots.GridLineWidth := 1;
GridMSlots.OnPrepareCanvas:= @FormSlots.GridMSlotsPrepareCanvas;
End;

Procedure UpdateSlotsGrid();
var
  contador : integer;
  CurrentUTC : int64;
Begin
setmilitime('UpdateSlotsGrid',1);
CurrentUTC := UTCTime.ToInt64;
if CurrentUTC>SlotsLastUpdate then
   begin
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
      GridMSlots.Cells[15,contador]:= Conexiones[contador].MNsHash;
      GridMSlots.Cells[16,contador]:= IntToStr(Conexiones[contador].MNsCount);
      GridMSlots.Cells[17,contador]:= Conexiones[contador].BestHashDiff;
      GridMSlots.Cells[18,contador]:= Conexiones[contador].MNChecksCount.ToString;
      end;
   SlotsLastUpdate := CurrentUTC;
   end;
setmilitime('UpdateSlotsGrid',2);
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

form1.DataPanel.Cells[2,0]:=rs0518;  //'Next Miner'
form1.DataPanel.Cells[2,1]:=rs0519;  //'Hashing'
form1.DataPanel.Cells[2,2]:=LangLine(105);  //'Target'
form1.DataPanel.Cells[2,3]:=LangLine(106);  //'Reward'
form1.DataPanel.Cells[2,4]:=LangLine(107);  //'Block Time'
form1.DataPanel.Cells[2,5]:='Next in';  //'Pool Balance'
form1.DataPanel.Cells[2,6]:='Masternodes';     //'mainnet Time'
form1.DataPanel.Cells[2,7]:='MNs #';     //'Masternodes'

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

// Nodes Grid
form1.GridNodes.Cells[0,0] := 'Node';
form1.GridNodes.Cells[1,0] := 'Funds';
form1.GridNodes.Cells[2,0] := 'Last';
form1.GridNodes.Cells[3,0] := 'Total';
form1.GridNodes.Cells[4,0] := 'Conf';
form1.GridNodes.FocusRectVisible:=false;


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
   sleep(1);
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
   if not WO_OmmitMemos then
      form1.Memoconsola.Lines.Add(ConsoleLines[0]);
   EnterCriticalSection(CSConsoleLines);
      TRY
      ConsoleLines.Delete(0);
      EXCEPT ON E:Exception do
         ToLog('Error showing lines to console');
      END; {TRY}
   LeaveCriticalSection(CSConsoleLines);
   end;
End;

// Actualiza los datos en el grid
Procedure ActualizarGUI();
var
  contador : integer = 0;
Begin
//Update Monitor Grid
if ( (form1.PCMonitor.ActivePage = Form1.TabMonitorMonitor) and (LastUpdateMonitor<>UTCTime.ToInt64) ) then
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
   LastUpdateMonitor := UTCTime.ToInt64;
   setmilitime('UpdateGUIMonitor',2);
   end;

if U_DataPanel then
   begin
   //form1.DataPanel.Cells[1,1]:=Booltostr(form1.Server.Active, true)+'('+IntToStr(Form1.Server.DefaultPort)+')';
   form1.DataPanel.Cells[1,1]:=NodeServerInfo;

   form1.DataPanel.Cells[1,3]:=copy(myResumenHash,0,5)+'/'+copy(NetResumenHash.Value,0,5)+'('+IntToStr(NetResumenHash.Porcentaje)+')';
   form1.DataPanel.Cells[1,4]:=Copy(MySumarioHash,0,5)+'/'+Copy(NetSumarioHash.Value,0,5)+'('+IntToStr(NetSumarioHash.Porcentaje)+')';
   form1.DataPanel.Cells[1,6]:=IntToStr(MyLastBlock)+'/'+NetLastBlock.Value+'('+IntToStr(NetLastBlock.Porcentaje)+')';
   form1.DataPanel.Cells[1,5]:=Copy(MyLastBlockHash,0,5)+'/'+copy(NetLastBlockHash.Value,0,5)+'('+IntToStr(NetLastBlockHash.Porcentaje)+')';
   U_DataPanel := false;
   end;

if U_PoSGrid then
   begin
   //form1.GridPoS.Cells[1,0]:=Int2Curr((GetSupply(MyLastBlock+1)*PosStackCoins) div 10000)+' '+coinsimbol;
   form1.GridPoS.Cells[1,0]:=Format('%s  (%d)',[Int2Curr((GetSupply(MyLastBlock+1)*PosStackCoins) div 10000),GetMyPosAddressesCount]);
   //form1.GridPoS.Cells[1,1]:=IntToStr(GetMyPosAddressesCount);
   form1.GridPoS.Cells[1,1]:=Int2Curr(G_MNsEarnings)+' '+CoinSimbol;
   form1.GridPoS.Cells[1,2]:=Int2Curr(G_PoSEarnings)+' '+CoinSimbol;
   U_PoSGrid := false;
   End;

form1.DataPanel.Cells[3,0]:=Copy(GetNMSData.Miner,1,10)+'...';
form1.DataPanel.Cells[3,1]:=BestHashReadeable(GetNMSData.Diff);
form1.DataPanel.Cells[3,2]:='';
form1.DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
form1.DataPanel.Cells[3,4]:='('+IntToStr(Lastblockdata.TimeLast20)+') '+BlockAge.ToString;


// update nodes grid
if ((U_MNsGrid) or (UTCTime.ToInt64>U_MNsGrid_Last+59)) then
   begin
   //{
   form1.GridNodes.RowCount:=1;
   if GetMNsListLength > 0 then
      begin
      for contador := 0 to length(MNsList)-1 do
         begin
         form1.GridNodes.RowCount := form1.GridNodes.RowCount+1;
         form1.GridNodes.Cells[0,1+contador] := MNsList[contador].Ip+':'+IntToStr(MNsList[contador].Port);
         form1.GridNodes.Cells[1,1+contador] := MNsList[contador].Fund;
         //form1.GridNodes.Cells[1,1+contador] := MNsList[contador].First.ToString;
         form1.GridNodes.Cells[2,1+contador] := MNsList[contador].Last.ToString;
         form1.GridNodes.Cells[3,1+contador] := MNsList[contador].Total.ToString;
         form1.GridNodes.Cells[4,1+contador] := MNsList[contador].Validations.ToString; ;
         end;
      end;
   //}
   U_MNsGrid_Last := UTCTime.ToInt64;
   form1.LabelNodesHash.Caption:='Count: '+GetMNsListLength.ToString;
   U_MNsGrid := false;
   end;

// Esta se muestra siempre aparte ya que la funcion GetTotalConexiones es la que permite
// verificar si los clientes siguen conectados
setmilitime('UpdateGUITime',1);
form1.DataPanel.Cells[1,2]:=IntToStr(GetTotalConexiones)+' ('+IntToStr(MyConStatus)+') ['+IntToStr(G_TotalPings)+']';
form1.DataPanel.Cells[1,7]:= format(rs0517,[length(ArrayCriptoOp),GetPendingCount,NetPendingTrxs.Value]);
form1.DataPanel.Cells[1,0]:= Int2Curr(GetWalletBalance)+' '+CoinSimbol;
form1.DataPanel.Cells[3,5]:= RemainingTillNextBlock;//IntToStr(OutgoingMsjs.Count);
form1.DataPanel.Cells[3,6]:= Copy(MyMNsHash,0,5)+'/'+NetMNsHash.Value;
form1.DataPanel.Cells[3,7]:= format('(%d)  %d/%s (%d)',[GetMNsChecksCount,GetMNsListLength,NetMNsCount.Value,LengthWaitingMNs]);
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
if not fileexists('locale'+DirectorySeparator+'Noso.'+number+'.po') then
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
         if MilitimeArray[count].duration>1000 then
            ToExcLog('Performance: Process '+name+' last '+IntToStr(MilitimeArray[count].duration));
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
   begin
   EnterCriticalSection(CSCurrentJob);
   currentjob := CurrentJob+'>'+CurrJob;
   LeaveCriticalSection(CSCurrentJob);
   end
else
   begin
   EnterCriticalSection(CSCurrentJob);
   currentjob := StringReplace(currentjob,'>'+CurrJob,'',[rfReplaceAll, rfIgnoreCase]);
   LeaveCriticalSection(CSCurrentJob);
   end;
if ( (form1.PCMonitor.ActivePage=Form1.TabMonitorMonitor) and (Form1.PageMain.ActivePage=form1.TabMonitor) and
     (form1.CB_Currentjob.Checked) ) then
   begin
   Form1.CB_Currentjob.Caption:=GetCurrentJob;
   Form1.CB_Currentjob.Update;
   end;
End;

Function GetCurrentJob():String;
Begin
EnterCriticalSection(CSCurrentJob);
Result := currentjob;
LeaveCriticalSection(CSCurrentJob);
End;

Procedure CloseAllForms();
Begin
   TRY
   formslots.Visible:=false;
   CloseExplorer;
   EXCEPT on E: Exception do
      begin

      end;
   END; {TRY}
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

Function HashrateToShow(speed:int64):String;
Begin
if speed>1000000000 then result := FormatFloat('0.00',speed/1000000000)+' Gh/s'
else if speed>1000000 then result := FormatFloat('0.00',speed/1000000)+' Mh/s'
else if speed>1000 then result := FormatFloat('0.00',speed/1000)+' Kh/s'
else result := speed.ToString+' h/s'
End;


END. // END UNIT

