unit mpCoin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm,mpgui;

function GetAddressBalance(address:string):int64;
function GetAddressPendingPays(Address:string):int64;
function TranxAlreadyPending(TrxHash:string):boolean;
function TrxExistsInLastBlock(trfrhash:String):boolean;
function AddPendingTxs(order:OrderData):boolean;
function AddressAlreadyCustomized(address:string):boolean;
function Restar(number:int64):int64;
function AddressSumaryIndex(Address:string):integer;
function GetFee(monto:int64):Int64;
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; concepto,
  ordertime:String;linea:integer):OrderData;
Procedure CheckForMyPending();
function HaveAddressAnyPending(Address:string):boolean;
function GetMaximunToSend():int64;
function cadtonum(cadena:string;pordefecto:int64;erroroutput:string):int64;



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
   if address = GetAddressFromPublicKey(PendingTXS[cont].Sender) then
     result := result+PendingTXS[cont].AmmountFee+PendingTXS[cont].AmmountTrf;
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
CheckForMyPending();
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
   if ((PendingTxs[cont].Sender=address) and (PendingTxs[cont].OrderType = 'CUSTOM')) then
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
OrderInfo.Receiver   := Destino;
OrderInfo.AmmountFee := ComisionTrfr;
OrderInfo.AmmountTrf := montotrfr;
OrderInfo.Signature  := GetStringSigned(ordertime+origen+destino+IntToStr(montotrfr)+
                     IntToStr(comisiontrfr)+IntToStr(linea),
                     ListaDirecciones[DireccionEsMia(origen)].PrivateKey);
OrderInfo.TrfrID     := GetTransferHash(ordertime+origen+destino+IntToStr(monto)+IntToStr(MyLastblock));
Result := OrderInfo;
End;

// verifica si en las transaccione pendientes hay alguna de nuestra cartera
Procedure CheckForMyPending();
var
  counter : integer = 0;
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
   if DireccionEsMia(GetAddressFromPublicKey(PendingTxs[counter].Sender))>=0 then
      MontoOutgoing := MontoOutgoing+PendingTxs[counter].AmmountFee+PendingTxs[counter].AmmountTrf;
   If DireccionEsMia(PendingTxs[counter].Receiver)>=0 then
      MontoIncoming := MontoIncoming+PendingTxs[counter].AmmountTrf;
   end;
if MontoIncoming>0 then ImageInc.Visible := true else ImageInc.Visible:= false;
if MontoOutgoing>0 then ImageOut.Visible := true else ImageOut.Visible:= false;
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
function GetMaximunToSend():int64;
var
  Disponible : int64;
  maximo : int64;
  comision : int64;
  Envio : int64;
  Diferencia : int64;
Begin
Disponible := GetWalletBalance;
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

END. // END UNIT


