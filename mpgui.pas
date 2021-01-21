unit mpGUI;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpTime, graphics, strutils;

Procedure InicializarGUI();
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

implementation

Uses
  mpParser, mpDisk, mpRed, mpProtocol,mpcoin, mpblock;

// Inicializa el grid donde se muestran los datos
Procedure InicializarGUI();
var
  contador : integer = 0;
Begin
// datapanel
DataPanel.Cells[0,0]:=LangLine(95);  //'Balance'
DataPanel.Cells[0,1]:=LangLine(96); //'Server'
DataPanel.Cells[0,2]:=LangLine(97);  //'Resumen'
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
   DataPanel.Cells[3,1]:=IntToStr(Miner_EsteIntervalo*5 div 1000) +' KHs/sec';
   DataPanel.Cells[3,2]:=Miner_Target;
   DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
   DataPanel.Cells[3,4]:=TimeSinceStamp(LastblockData.TimeEnd);
   if MinerButton.Caption = '' then
      begin MinerButton.Caption := ' '; Form1.imagenes.GetBitmap(5,MinerButton.Glyph);end
   else if MinerButton.Caption = ' ' then
      begin MinerButton.Caption := '  ';Form1.imagenes.GetBitmap(11,MinerButton.Glyph);end
   else if MinerButton.Caption = '  ' then
      begin MinerButton.Caption := '   ';Form1.imagenes.GetBitmap(5,MinerButton.Glyph);end
   else if MinerButton.Caption = '   ' then
      begin MinerButton.Caption := '';Form1.imagenes.GetBitmap(4,MinerButton.Glyph);end;
   DataPanel.Cells[3,5]:=MINER_HashSeed+IntToStr(MINER_HashCounter);
   end
else
   begin
   DataPanel.Cells[3,0]:=BoolToStr(Miner_IsOn,true)+'('+IntToStr(Miner_DifChars)+') '+IntToStr(Miner_FoundedSteps)+'/'+IntToStr(Miner_Steps);
   DataPanel.Cells[3,1]:=LangLine(119); //'Not minning'
   DataPanel.Cells[3,2]:=Miner_Target;
   DataPanel.Cells[3,3]:=Int2curr(GetBlockReward(Mylastblock+1));
   DataPanel.Cells[3,4]:=TimeSinceStamp(LastblockData.TimeEnd);
   Form1.imagenes.GetBitmap(4,MinerButton.Glyph);
   end;

// Esta se muestra siempre aparte ya que la funcion GetTotalConexiones es la que permite
// verificar si los clientes siguen conectados
DataPanel.Cells[1,3]:=IntToStr(GetTotalConexiones)+' ('+IntToStr(MyConStatus)+') ['+IntToStr(G_TotalPings)+']';
DataPanel.Cells[1,0]:= Int2Curr(GetWalletBalance)+' '+CoinSimbol;
DataPanel.Cells[1,7]:= IntToStr(Length(PendingTXs))+'/'+NetPendingTrxs.Value;

if U_DirPanel then
   begin
   Direccionespanel.RowCount:=length(listadirecciones)+1;
   for contador := 0 to length(ListaDirecciones)-1 do
      begin
      if ListaDirecciones[contador].Custom<>'' then
        Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Custom
      else Direccionespanel.Cells[0,contador+1] := ListaDirecciones[contador].Hash;
      Direccionespanel.Cells[1,contador+1] := Int2Curr(ListaDirecciones[contador].Balance-GetAddressPendingPays(ListaDirecciones[contador].hash));
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
else result := 'ErrLine: '+IntToStr(linea);
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
      ConsoleLines.Add(LangLine(3)+IdiomasDisponibles[StrToInt(number)]); //Language changed to:
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
InfoPanel.Visible:=true;
InfoPanel.BringToFront;
InfoPanel.Refresh;
InfoPanel.Caption:=copy(text,1,33);
InfoPanelTime := 1000;
if not form1.InfoTimer.Enabled then form1.InfoTimer.Enabled := true;
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

END. // END UNIT

