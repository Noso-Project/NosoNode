unit mpCoin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm,mpgui,Clipbrd, strutils, nosodebug,nosogeneral,
  nosocrypto, nosounit,nosotime,nosopsos,nosowallcon, nosoblock,nosonetwork;

function GetAddressAvailable(address:string):int64;
function GetAddressPendingPays(Address:string):int64;
function GetAddressIncomingpays(Address:string):int64;
//function TranxAlreadyPending(TrxHash:string):boolean;
//function TrxExistsInLastBlock(trfrhash:String):boolean;
//function GetLastPendingTime():int64;
//function AddArrayPoolTXs(order:TOrderData):boolean;
Procedure VerifyIfPendingIsMine(order:Torderdata);
function AddressAlreadyCustomized(address:string):boolean;
Function GVTAlreadyTransfered(NumberStr:String):boolean;
function AliasAlreadyExists(Addalias:string):boolean;
//function GetFee(monto:int64):Int64;
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; reference,
  ordertime:String;linea:integer):TOrderData;
Procedure CheckForMyPending();
//function GetMaximunToSend(monto:int64):int64;
function GetCurrentStatus(mode:integer):String;
function GetBlockHeaders(numberblock:integer):string;
function ValidRPCHost(hoststr:string):boolean;
function PendingRawInfo(ForRPC : boolean = true):String;
{
Function GetPendingCount():integer;
Procedure ClearAllPending();
}

implementation

Uses
  mpblock, Mpred, mpparser,mpdisk, mpProtocol;

function GetAddressAvailable(address:string):int64;
Begin
result := GetAddressBalanceIndexed(address)-GetAddressPendingPays(address);
End;

// Returns the balance an address already have committed to be paid.
function GetAddressPendingPays(Address:string):int64;
var
  cont : integer;
  CopyPendings : array of Torderdata;
Begin
Result := 0;
if Address = '' then exit;
if GetPendingCount>0 then
   begin
   EnterCriticalSection(CSPending);
   SetLength(CopyPendings,0);
   CopyPendings := copy(ArrayPoolTXs,0,length(ArrayPoolTXs));
   LeaveCriticalSection(CSPending);
   for cont := 0 to length(CopyPendings)-1 do
      begin
      if address = CopyPendings[cont].address then
         result := result+CopyPendings[cont].AmmountFee+CopyPendings[cont].AmmountTrf;
      end;
   end;
if MyLastBlock >= Update050Block then
   if IsLockedMN(Address) then Inc(Result,1050000000000);
End;

// Returns the pending incomings for the specified address**ONLY HASH ACCEPTED
function GetAddressIncomingpays(Address:string):int64;
var
  cont : integer;
  CopyPendings : array of Torderdata;
Begin
result := 0;
if GetPendingCount>0 then
   begin
   EnterCriticalSection(CSPending);
   SetLength(CopyPendings,0);
   CopyPendings := copy(ArrayPoolTXs,0,length(ArrayPoolTXs));
   LeaveCriticalSection(CSPending);
   for cont := 0 to length(CopyPendings)-1 do
      begin
      if address = ArrayPoolTXs[cont].receiver then
         result := result+ArrayPoolTXs[cont].AmmountTrf;
      end;
   end;
End;

{
//Devuelve si una transaccion ya se encuentra pendiente
function TranxAlreadyPending(TrxHash:string):boolean;
var
  cont : integer;
Begin
Result := false;
for cont := 0 to GetPendingCount-1 do
   begin
   if TrxHash = ArrayPoolTXs[cont].TrfrID then
      begin
      result := true;
      break;
      end;
   end;
End;
}

{
// Devuelve si una transaccion existe en el ultimo bloque
function TrxExistsInLastBlock(trfrhash:String):boolean;
var
  ArrayLastBlockTrxs : TBlockOrdersArray;
  cont : integer;
Begin
Result := false;
ArrayLastBlockTrxs := Default(TBlockOrdersArray);
ArrayLastBlockTrxs := GetBlockTrxs(MyLastBlock);
for cont := 0 to length(ArrayLastBlockTrxs)-1 do
   begin
   if ArrayLastBlockTrxs[cont].TrfrID = trfrhash then
     begin
     result := true ;
     break
     end;
   end;
SetLength(ArrayLastBlockTrxs,0);
End;
}

{
function GetLastPendingTime():int64;
Begin
  result := 0;
  EnterCriticalSection(CSPending);
  if length(ArrayPoolTXs) > 0 then result := ArrayPoolTXs[length(ArrayPoolTXs)-1].TimeStamp;
  LeaveCriticalSection(CSPending);
End;
}

{
// Añade la transaccion pendiente en su lugar
function AddArrayPoolTXs(order:TOrderData):boolean;
var
  cont : integer = 0;
  insertar : boolean = false;
  resultado : integer = 0;
Begin
BeginPerformance('AddArrayPoolTXs');
//if order.OrderType='FEE' then exit;
if order.TimeStamp < LastBlockData.TimeStart then exit;
if TrxExistsInLastBlock(order.TrfrID) then exit;
if ((BlockAge>585) and (order.TimeStamp < LastBlockData.TimeStart+540) ) then exit;
if not TranxAlreadyPending(order.TrfrID) then
   begin
   EnterCriticalSection(CSPending);
   while cont < length(ArrayPoolTXs) do
     begin
     if order.TimeStamp < ArrayPoolTXs[cont].TimeStamp then
        begin
        insertar := true;
        resultado := cont;
        break;
        end
     else if order.TimeStamp = ArrayPoolTXs[cont].TimeStamp then
        begin
        if order.OrderID < ArrayPoolTXs[cont].OrderID then
           begin
           insertar := true;
           resultado := cont;
           break;
           end
        else if order.OrderID = ArrayPoolTXs[cont].OrderID then
           begin
           if order.TrxLine < ArrayPoolTXs[cont].TrxLine then
              begin
              insertar := true;
              resultado := cont;
              break;
              end;
           end;
        end;
     cont := cont+1;
     end;
   if not insertar then resultado := length(ArrayPoolTXs);
   Insert(order,ArrayPoolTXs,resultado);
   LeaveCriticalSection(CSPending);
   result := true;
   VerifyIfPendingIsMine(order);
   end;
EndPerformance('AddArrayPoolTXs');
End;
}

// Verifica si una orden especifica es del usuario
Procedure VerifyIfPendingIsMine(order:Torderdata);
var
  DireccionEnvia: string;
  SendIndex     : integer;
Begin
  DireccionEnvia := order.address;
  SendIndex      := WallAddIndex(DireccionEnvia);
  if SendIndex>=0 then
    begin
    SetPendingForAddress(SendIndex,GetWallArrIndex(SendIndex).Pending+Order.AmmountFee+order.AmmountTrf);
    montooutgoing := montooutgoing+Order.AmmountFee+order.AmmountTrf;
    if not form1.ImageOut.Visible then form1.ImageOut.Visible:= true;
    end;
  if WallAddIndex(Order.Receiver)>=0 then
    begin
    montoincoming := montoincoming+order.AmmountTrf;
    if not form1.ImageInc.Visible then form1.ImageInc.Visible:= true;
    end;
  U_DirPanel := true;
End;

// Devuelve si una direccion ya posee un alias
function AddressAlreadyCustomized(address:string):boolean;
var
  cont : integer;
Begin
Result := false;
if GetAddressAlias(address) <> '' then Exit(True);
for cont := 0 to GetPendingCount-1 do
   if ((ArrayPoolTXs[cont].Address=address) and (ArrayPoolTXs[cont].OrderType = 'CUSTOM')) then
      exit(true);
End;

Function GVTAlreadyTransfered(NumberStr:String):boolean;
var
  number  : integer;
  counter : integer;
Begin
result := false;
Number := StrToIntDef(NumberStr,-1);
if number < 0 then
   begin
   result := true;
   exit;
   end;
for counter := 0 to GetPendingCount-1 do
   begin
   if ((ArrayPoolTXs[counter].reference=NumberStr) and (ArrayPoolTXs[counter].OrderType = 'SNDGVT')) then
         begin
         result := true;
         break;
         end;
   end;
End;

// verify if an alias is already registered
function AliasAlreadyExists(Addalias:string):boolean;
var
  cont : integer;
  LRecord : TSummaryData;
Begin
Result := false;
if GetIndexPosition(AddAlias,LRecord,True) >= 0 then Exit(True);
for cont := 0 to GetPendingCount-1 do
   if ((ArrayPoolTXs[cont].OrderType='CUSTOM') and (ArrayPoolTXs[cont].Receiver = Addalias)) then
      Exit(True);
End;

// Devuelve la comision por un monto
function GetFee(monto:int64):Int64;
Begin
Result := monto div Comisiontrfr;
if result < MinimunFee then result := 1000000;//MinimunFee;
End;

// Obtiene una orden de envio de fondos desde una direccion
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; reference,
  ordertime:String; linea:integer):TOrderData;
var
  MontoDisponible, Montotrfr, comisionTrfr : int64;
  OrderInfo : Torderdata;
Begin
BeginPerformance('SendFundsFromAddress');
MontoDisponible := GetAddressBalanceIndexed(GetWallArrIndex(WallAddIndex(origen)).Hash)-GetAddressPendingPays(Origen);
if MontoDisponible>comision then ComisionTrfr := Comision
else comisiontrfr := montodisponible;
if montodisponible>monto+comision then montotrfr := monto
else montotrfr := montodisponible-comision;
if montotrfr <0 then montotrfr := 0;
OrderInfo := Default(TOrderData);
OrderInfo.OrderID    := '';
OrderInfo.OrderLines := 1;
OrderInfo.OrderType  := 'TRFR';
OrderInfo.TimeStamp  := StrToInt64(OrderTime);
OrderInfo.reference    := reference;
OrderInfo.TrxLine    := linea;
OrderInfo.sender     := GetWallArrIndex(WallAddIndex(origen)).PublicKey;
OrderInfo.Address    := GetWallArrIndex(WallAddIndex(origen)).Hash;
OrderInfo.Receiver   := Destino;
OrderInfo.AmmountFee := ComisionTrfr;
OrderInfo.AmmountTrf := montotrfr;
OrderInfo.Signature  := GetStringSigned(ordertime+origen+destino+IntToStr(montotrfr)+
                     IntToStr(comisiontrfr)+IntToStr(linea),
                     GetWallArrIndex(WallAddIndex(origen)).PrivateKey);
OrderInfo.TrfrID     := GetTransferHash(ordertime+origen+destino+IntToStr(monto)+IntToStr(MyLastblock));
Result := OrderInfo;
EndPerformance('SendFundsFromAddress');
End;

// verifica si en las transaccione pendientes hay alguna de nuestra cartera
Procedure CheckForMyPending();
var
  counter : integer = 0;
  DireccionEnvia : string;
  AddIndex       : integer;
Begin
MontoIncoming := 0;
MontoOutgoing := 0;
if GetPendingCount = 0 then
   begin
   form1.ImageInc.Visible:=false;
   form1.ImageOut.Visible:=false;
   end
else
   begin
   for counter := 0 to GetPendingCount-1 do
      begin
      DireccionEnvia := ArrayPoolTXs[counter].Address;
      AddIndex := WallAddIndex(DireccionEnvia);
      if AddIndex >= 0 then
         begin
         MontoOutgoing := MontoOutgoing+ArrayPoolTXs[counter].AmmountFee+ArrayPoolTXs[counter].AmmountTrf;
         SetPendingForAddress(AddIndex,GetWallArrIndex(AdDIndex).Pending+ArrayPoolTXs[counter].AmmountFee+ArrayPoolTXs[counter].AmmountTrf);
         //WalletArray[WallAddIndex(DireccionEnvia)].Pending:=WalletArray[WallAddIndex(DireccionEnvia)].Pending+ArrayPoolTXs[counter].AmmountFee+ArrayPoolTXs[counter].AmmountTrf;
         end;
      If WallAddIndex(ArrayPoolTXs[counter].Receiver)>=0 then
         MontoIncoming := MontoIncoming+ArrayPoolTXs[counter].AmmountTrf;
      end;
   if MontoIncoming>0 then form1.ImageInc.Visible := true else form1.ImageInc.Visible:= false;
   if MontoOutgoing>0 then form1.ImageOut.Visible := true else form1.ImageOut.Visible:= false;
   U_DirPanel := true;
   end;
End;

// Retorna cuanto es lo maximo que se puede enviar
function GetMaximunToSend(monto:int64):int64;
var
  Disponible : int64;
  maximo     : int64;
  comision   : int64;
  Envio      : int64;
  Diferencia : int64;
Begin
Disponible := monto;
if ( (disponible < 1000000{MinimunFee}) or (Disponible<0) ) then
   begin
   result := 0;
   exit;
   end;
maximo     := (Disponible * Comisiontrfr) div (Comisiontrfr+1);
comision   := maximo div Comisiontrfr;
if Comision < 1000000{MinimunFee} then Comision := 1000000{MinimunFee};
Envio      := maximo + comision;
Diferencia := Disponible-envio;
result     := maximo+diferencia;
End;

function GetCurrentStatus(mode:integer):String;
var
  Resultado : string = '';
Begin
resultado := resultado+   'ServerON    : '+BoolToStr(Form1.Server.Active,true)+' ';
if mode = 1 then
   begin
   resultado := resultado+'Date        : '+FormatDateTime('dd MMMM YYYY HH:MM:SS.zzz', Now)+slinebreak;
   resultado := resultado+'MyConStatus : '+IntToStr(myConStatus)+slinebreak;
   Resultado := resultado+'OS          : '+OSVersion +slinebreak;
   Resultado := resultado+'WalletVer   : '+MainnetVersion+NodeRelease+slinebreak;
   end;
result := resultado;
End;

function GetBlockHeaders(numberblock:integer):string;
var
  Header : BlockHeaderData;
  blockhash : string;
Begin
Header := default (BlockHeaderData);
if fileexists(BlockDirectory+IntToStr(numberblock)+'.blk') then
   begin
   Header := LoadBlockDataHeader(numberblock);
   blockhash := HashMD5File(BlockDirectory+IntToStr(numberblock)+'.blk');
   Header.Solution := StringReplace(Header.Solution,' ',#0,[rfReplaceAll, rfIgnoreCase]);
   Header.LastBlockHash := StringReplace(Header.LastBlockHash,' ','',[rfReplaceAll, rfIgnoreCase]);
   result :=(format('%d'#127'%d'#127'%d'#127'%d'#127'%d'#127'%d'#127'%d'#127'%s'#127'%s'#127'%s'#127'%d'#127'%s'#127'%d'#127'%d'#127'%s',
                    [Header.Number,Header.TimeStart,Header.TimeEnd,Header.TimeTotal,
                    Header.TimeLast20,Header.TrxTotales,Header.Difficult,Header.TargetHash,
                    Header.Solution,Header.LastBlockHash,Header.NxtBlkDiff,Header.AccountMiner,
                    Header.MinerFee,Header.Reward,blockhash]));
   end
End;

function ValidRPCHost(hoststr:string):boolean;
var
  HostIP : string;
  whitelisted : string;
  thiswhitelist : string;
  counter : integer = 0;
Begin
result := false;
HostIP := StringReplace(hoststr,':',' ',[rfReplaceAll, rfIgnoreCase]);
HostIP := parameter(HostIP,0);
whitelisted := StringReplace(RPCWhiteList,',',' ',[rfReplaceAll, rfIgnoreCase]);
   repeat
   thiswhitelist := parameter(whitelisted,counter);
   if thiswhitelist = HostIP then result := true;
   counter+=1;
   until thiswhitelist = '';
End;

// Returns the basic info of the pending orders
function PendingRawInfo(ForRPC : boolean = true):String;
var
  CopyArrayPoolTXs : Array of TOrderData;
  counter : integer;
  ThisPending : string;
Begin
result := '';
if Length(ArrayPoolTXs) > 0 then
   begin
   EnterCriticalSection(CSPending);
   SetLength(CopyArrayPoolTXs,0);
   CopyArrayPoolTXs := copy(ArrayPoolTXs,0,length(ArrayPoolTXs));
   LeaveCriticalSection(CSPending);
   for counter := 0 to Length(CopyArrayPoolTXs)-1 do
      begin
      if ForRPC then
         begin
         ThisPending:=CopyArrayPoolTXs[counter].OrderID+','+
                      CopyArrayPoolTXs[counter].TimeStamp.ToString+','+
                      CopyArrayPoolTXs[counter].OrderType+','+
                      CopyArrayPoolTXs[counter].Address+','+
                      CopyArrayPoolTXs[counter].Receiver+','+
                      CopyArrayPoolTXs[counter].AmmountTrf.ToString+','+
                      CopyArrayPoolTXs[counter].AmmountFee.ToString+','+
                      CopyArrayPoolTXs[counter].Reference{+','+CopyArrayPoolTXs[counter].TimeStamp.ToString};

         end
      else
         begin
         ThisPending:=CopyArrayPoolTXs[counter].OrderType+','+
                      CopyArrayPoolTXs[counter].Address+','+
                      CopyArrayPoolTXs[counter].Receiver+','+
                      CopyArrayPoolTXs[counter].AmmountTrf.ToString+','+
                      CopyArrayPoolTXs[counter].AmmountFee.ToString{+','+CopyArrayPoolTXs[counter].TimeStamp.ToString};
         end;
      result := result+ThisPending+' ';
      end;
   Trim(result);
   end;
End;

{
// Returns the length of the pending transactions array safely
Function GetPendingCount():integer;
Begin
EnterCriticalSection(CSPending);
result := Length(ArrayPoolTXs);
LeaveCriticalSection(CSPending);
End;

// Clear the pending transactions array safely
Procedure ClearAllPending();
Begin
EnterCriticalSection(CSPending);
SetLength(ArrayPoolTXs,0);
LeaveCriticalSection(CSPending);
End;
}

END. // END UNIT


