unit mpCoin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm,mpgui;

function GetAddressBalance(address:string):int64;
function GetAddressPendingPays(Address:string):int64;
function GetAddressIncomingpays(Address:string):int64;
function TranxAlreadyPending(TrxHash:string):boolean;
function TrxExistsInLastBlock(trfrhash:String):boolean;
function AddPendingTxs(order:OrderData):boolean;
Procedure VerifyIfPendingIsMine(order:orderdata);
function AddressAlreadyCustomized(address:string):boolean;
function Restar(number:int64):int64;
function AddressSumaryIndex(Address:string):integer;
function GetFee(monto:int64):Int64;
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; concepto,
  ordertime:String;linea:integer):OrderData;
Procedure CheckForMyPending();
function HaveAddressAnyPending(Address:string):boolean;
function GetMaximunToSend(monto:int64):int64;
function cadtonum(cadena:string;pordefecto:int64;erroroutput:string):int64;
Function IsValidIP(IpString:String):boolean;
function GetCurrentStatus(mode:integer):String;
function GetSupply():int64;



implementation

Uses
  mpblock, Mpred, mpcripto, mpparser,mpdisk, mpProtocol;

// Devuelve el saldo en sumario de una direccion/alias
function GetAddressBalance(address:string):int64;
var
  cont : integer;
Begin
Result := 0;
for cont := 0 to length(ListaSumario)-1 do
   begin
   if ((address = ListaSumario[cont].Hash) or (address = ListaSumario[cont].Custom)) then
      begin
      result := ListaSumario[cont].Balance;
      break;
      end;
   end;
End;

// Devuelve el saldo que una direccion ya tiene comprometido en pendientes
function GetAddressPendingPays(Address:string):int64;
var
  cont : integer;
Begin
Result := 0;
for cont := 0 to length(PendingTXs)-1 do
   begin
   if address = PendingTXS[cont].address then
      result := result+PendingTXS[cont].AmmountFee+PendingTXS[cont].AmmountTrf;
   end;
End;

// Returns the pending incomings for the specified address**ONLY HASH ACCEPTED
function GetAddressIncomingpays(Address:string):int64;
var
  cont : integer;
Begin
Result := 0;
for cont := 0 to length(PendingTXs)-1 do
   begin
   if address = PendingTXS[cont].receiver then
      result := result+PendingTXS[cont].AmmountTrf;
   end;
End;

//Devuelve si una transaccion ya se encuentra pendiente
function TranxAlreadyPending(TrxHash:string):boolean;
var
  cont : integer;
Begin
Result := false;
for cont := 0 to length(PendingTXs)-1 do
   begin
   if TrxHash = PendingTXS[cont].TrfrID then
      begin
      result := true;
      break;
      end;
   end;
End;

// Devuelve si una transaccion existe en el ultimo bloque
function TrxExistsInLastBlock(trfrhash:String):boolean;
var
  ArrayLastBlockTrxs : BlockOrdersArray;
  cont : integer;
Begin
Result := false;
ArrayLastBlockTrxs := Default(BlockOrdersArray);
ArrayLastBlockTrxs := GetBlockTrxs(MyLastBlock);
for cont := 0 to length(ArrayLastBlockTrxs)-1 do
   begin
   if ArrayLastBlockTrxs[cont].TrfrID = trfrhash then
     begin
     result := true ;
     break
     end;
   end;
End;

// Añade la transaccion pendiente en su lugar
function AddPendingTxs(order:OrderData):boolean;
var
  cont : integer = 0;
  insertar : boolean = false;
  resultado : integer = 0;
Begin
setmilitime('AddPendingTxs',1);
if order.OrderType='FEE' then exit;
if TranxAlreadyPending(order.TrfrID) then exit;
while cont < length(PendingTxs) do
  begin
  if order.TimeStamp < PendingTxs[cont].TimeStamp then
     begin
     insertar := true;
     resultado := cont;
     break;
     end
  else if order.TimeStamp = PendingTxs[cont].TimeStamp then
     begin
     if order.OrderID < PendingTxs[cont].OrderID then
        begin
        insertar := true;
        resultado := cont;
        break;
        end
     else if order.OrderID = PendingTxs[cont].OrderID then
        begin
        if order.TrxLine < PendingTxs[cont].TrxLine then
           begin
           insertar := true;
           resultado := cont;
           break;
           end;
        end;
     end;
  cont := cont+1;
  end;
if not insertar then resultado := length(pendingTXs);
Insert(order,PendingTxs,resultado);
result := true;
VerifyIfPendingIsMine(order);
setmilitime('AddPendingTxs',2);
End;

// Verifica si una orden especifica es del usuario
Procedure VerifyIfPendingIsMine(order:orderdata);
var
  DireccionEnvia: string;
Begin
DireccionEnvia := order.address;
if DireccionEsMia(DireccionEnvia)>=0 then
   begin
   ListaDirecciones[DireccionEsMia(DireccionEnvia)].Pending:=ListaDirecciones[DireccionEsMia(DireccionEnvia)].Pending+
      Order.AmmountFee+order.AmmountTrf;
   montooutgoing := montooutgoing+Order.AmmountFee+order.AmmountTrf;
   if not ImageOut.Visible then ImageOut.Visible:= true;
   end;
if DireccionEsMia(Order.Receiver)>=0 then
   begin
   montoincoming := montoincoming+order.AmmountTrf;
   ShowGlobo('Incoming transfer',Int2curr(order.AmmountTrf));
   if not ImageInc.Visible then ImageInc.Visible:= true;
   end;
U_DirPanel := true;
End;

// Devuelve si una direccion ya posee un alias
function AddressAlreadyCustomized(address:string):boolean;
var
  cont : integer;
Begin
Result := false;
for cont := 0 to length(ListaSumario) -1 do
   begin
   if ((ListaSumario[cont].Hash = Address) and (ListaSumario[cont].Custom <> '')) then
      begin
      result := true;
      exit;
      end;
   end;
for cont := 0 to length(PendingTXs)-1 do
   begin
   if ((PendingTxs[cont].Address=address) and (PendingTxs[cont].OrderType = 'CUSTOM')) then
      begin
      result := true;
      exit;
      end;
   end;
End;

// Regresa el valor en negativo para las actualizaciones de saldo
function Restar(number:int64):int64;
Begin
if number > 0 then Result := number-(Number*2)
else Result := number;
End;

// Devuelve el indice de la direccion en el sumario, o -1 si no existe
function AddressSumaryIndex(Address:string):integer;
var
  cont : integer = 0;
Begin
result := -1;
if address = '' then exit;
for cont := 0 to length(ListaSumario)-1 do
   begin
   if ((listasumario[cont].Hash=address) or (Listasumario[cont].Custom=address)) then
      begin
      result:= cont;
      break;
      end;
   end;
End;

// Devuelve la comision por un monto
function GetFee(monto:int64):Int64;
Begin
Result := monto div Comisiontrfr;
if result < MinimunFee then result := MinimunFee;
End;

// Obtiene una orden de envio de fondos desde una direccion
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; concepto,
  ordertime:String; linea:integer):OrderData;
var
  MontoDisponible, Montotrfr, comisionTrfr : int64;
  OrderInfo : orderdata;
Begin
setmilitime('SendFundsFromAddress',1);
MontoDisponible := ListaDirecciones[DireccionEsMia(origen)].Balance;
if MontoDisponible>comision then ComisionTrfr := Comision
else comisiontrfr := montodisponible;
if montodisponible>monto+comision then montotrfr := monto
else montotrfr := montodisponible-comision;
if montotrfr <0 then montotrfr := 0;
OrderInfo := Default(OrderData);
OrderInfo.OrderID    := '';
OrderInfo.OrderLines := 1;
OrderInfo.OrderType  := 'TRFR';
OrderInfo.TimeStamp  := StrToInt64(OrderTime);
OrderInfo.Concept    := concepto;
OrderInfo.TrxLine    := linea;
OrderInfo.Sender     := ListaDirecciones[DireccionEsMia(origen)].PublicKey;
OrderInfo.Address    := ListaDirecciones[DireccionEsMia(origen)].Hash;
OrderInfo.Receiver   := Destino;
OrderInfo.AmmountFee := ComisionTrfr;
OrderInfo.AmmountTrf := montotrfr;
OrderInfo.Signature  := GetStringSigned(ordertime+origen+destino+IntToStr(montotrfr)+
                     IntToStr(comisiontrfr)+IntToStr(linea),
                     ListaDirecciones[DireccionEsMia(origen)].PrivateKey);
OrderInfo.TrfrID     := GetTransferHash(ordertime+origen+destino+IntToStr(monto)+IntToStr(MyLastblock));
Result := OrderInfo;
setmilitime('SendFundsFromAddress',2);
End;

// verifica si en las transaccione pendientes hay alguna de nuestra cartera
Procedure CheckForMyPending();
var
  counter : integer = 0;
  DireccionEnvia : string;
Begin
MontoIncoming := 0;
MontoOutgoing := 0;
if length(PendingTxs) = 0 then
   begin
   ImageInc.Visible:=false;
   ImageOut.Visible:=false;
   exit;
   end;
for counter := 0 to length(PendingTXs)-1 do
   begin
   DireccionEnvia := PendingTxs[counter].Address;
   if DireccionEsMia(DireccionEnvia)>=0 then
      begin
      MontoOutgoing := MontoOutgoing+PendingTxs[counter].AmmountFee+PendingTxs[counter].AmmountTrf;
      ListaDirecciones[DireccionEsMia(DireccionEnvia)].Pending:=
        ListaDirecciones[DireccionEsMia(DireccionEnvia)].Pending+
        PendingTxs[counter].AmmountFee+PendingTxs[counter].AmmountTrf;
      end;
   If DireccionEsMia(PendingTxs[counter].Receiver)>=0 then
      MontoIncoming := MontoIncoming+PendingTxs[counter].AmmountTrf;
   end;
if MontoIncoming>0 then ImageInc.Visible := true else ImageInc.Visible:= false;
if MontoOutgoing>0 then ImageOut.Visible := true else ImageOut.Visible:= false;
U_DirPanel := true;
End;

// Verifica si la direccion posee transacciones pendientes
function HaveAddressAnyPending(Address:string):boolean;
var
  cont : integer;
Begin
result := false;
for cont := 0 to length(PendingTXs)-1 do
   begin
   if ((GetAddressFromPublicKey(PendingTXs[cont].Sender)=address) or
      (GetAddressFromPublicKey(PendingTXs[cont].Receiver)=address)) then
      result := true;
   end;
End;

// Retorna cuanto es lo maximo que se puede enviar
function GetMaximunToSend(monto:int64):int64;
var
  Disponible : int64;
  maximo : int64;
  comision : int64;
  Envio : int64;
  Diferencia : int64;
Begin
Disponible := monto;
maximo := (Disponible * Comisiontrfr) div (Comisiontrfr+1);
comision := maximo div Comisiontrfr;
Envio := maximo + comision;
Diferencia := Disponible-envio;
result := maximo+diferencia;
End;

// Convierte una cadena a un numero y devuelve un error si se llega a generar
function cadtonum(cadena:string;pordefecto:int64;erroroutput:string):int64;
Begin
   try
   result := strtoint64(cadena)
   Except on E:Exception do
      begin
      result := pordefecto;
      tolog(erroroutput);
      if copy(erroroutput,1,9) = '**CRITICAL:' then
         raise exception.Create(erroroutput+SLINEBREAK+'We recomend to restart the program after this');
      end;
   end;
End;

Function IsValidIP(IpString:String):boolean;
var
  valor1,valor2,valor3,valor4: integer;
Begin
result := true;
IPString := StringReplace(IPString,'.',' ',[rfReplaceAll, rfIgnoreCase]);
valor1 := StrToIntDef(GetCommand(IPString),-1);
valor2 := StrToIntDef(Parameter(IPString,1),-1);
valor3 := StrToIntDef(Parameter(IPString,2),-1);
valor4 := StrToIntDef(Parameter(IPString,3),-1);
if ((valor1 <0) or (valor1>255)) then result := false;
if ((valor2 <0) or (valor2>255)) then result := false;
if ((valor3 <0) or (valor3>255)) then result := false;
if ((valor4 <0) or (valor4>255)) then result := false;
End;

function GetCurrentStatus(mode:integer):String;
var
  Resultado : string = '';
Begin
resultado := resultado+'ServerON: '+BoolToStr(Form1.Server.Active,true)+' ';
resultado := resultado+'CONNECT_Try: '+BoolToStr(CONNECT_Try,true)+' ';
if mode = 1 then
   begin
   resultado := resultado+'MyConStatus: '+IntToStr(myConStatus)+' ';
   Resultado := resultado+'CurrentJob: '+CurrentJob+' ';
   Resultado := resultado+'MinerActive: '+BoolToStr(Miner_Active,true)+' ';
   Resultado := resultado+'MinerIsOn: '+BoolToStr(Miner_IsON,true)+' ';
   Resultado := resultado+'CPUs: '+IntToStr(G_CpuCount)+' ';
   Resultado := resultado+'MinerThreads: '+IntToStr(Length(Miner_Thread)) +' ';
   Resultado := resultado+'OS: '+OSVersion +' ';
   Resultado := resultado+'WalletVer: '+ProgramVersion+SubVersion+' ';
   Resultado := resultado+'Minerhashcount: '+IntToStr(MINER_HashCounter)+' ';
   Resultado := resultado+'Minerhashseed: '+MINER_HashSeed;
   end;
result := resultado;
End;

function GetSupply():int64;
Begin
result := (Mylastblock*5000000000)+1030390730000;
End;

END. // END UNIT


