unit mpCoin;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm,mpgui,Clipbrd, strutils, nosodebug,nosogeneral,
  nosocrypto, nosounit;

function GetAddressAvailable(address:string):int64;
function GetAddressPendingPays(Address:string):int64;
function GetAddressIncomingpays(Address:string):int64;
function TranxAlreadyPending(TrxHash:string):boolean;
function TrxExistsInLastBlock(trfrhash:String):boolean;
function AddPendingTxs(order:TOrderData):boolean;
function DireccionEsMia(direccion:string):integer;
Procedure VerifyIfPendingIsMine(order:Torderdata);
function AddressAlreadyCustomized(address:string):boolean;
Function GVTAlreadyTransfered(NumberStr:String):boolean;
function AliasAlreadyExists(Addalias:string):boolean;
function AddressSumaryIndex(Address:string):integer;
//function GetFee(monto:int64):Int64;
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; reference,
  ordertime:String;linea:integer):TOrderData;
Procedure CheckForMyPending();
//function GetMaximunToSend(monto:int64):int64;
function GetCurrentStatus(mode:integer):String;
function GetMyPosAddressesCount():integer;
function GetBlockHeaders(numberblock:integer):string;
function ValidRPCHost(hoststr:string):boolean;
function PendingRawInfo():String;
Function GetPendingCount():integer;
Procedure ClearAllPending();
//Function GetDevPercentage(block:integer):integer;
//Function GetPoSPercentage(block:integer):integer;
//Function GetMNsPercentage(block:integer):integer;
//Function GetStackRequired(block:integer):int64;

implementation

Uses
  mpblock, Mpred, mpparser,mpdisk, mpProtocol;

function GetAddressAvailable(address:string):int64;
Begin
result := GetAddressBalanceIndexed(address)-GetAddressPendingPays(address);
End;

// Devuelve el saldo que una direccion ya tiene comprometido en pendientes
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
   CopyPendings := copy(PendingTxs,0,length(PendingTxs));
   LeaveCriticalSection(CSPending);
   for cont := 0 to length(CopyPendings)-1 do
      begin
      if address = CopyPendings[cont].address then
         result := result+CopyPendings[cont].AmmountFee+CopyPendings[cont].AmmountTrf;
      end;
   end;
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
   CopyPendings := copy(PendingTxs,0,length(PendingTxs));
   LeaveCriticalSection(CSPending);
   for cont := 0 to length(CopyPendings)-1 do
      begin
      if address = PendingTXS[cont].receiver then
         result := result+PendingTXS[cont].AmmountTrf;
      end;
   end;
End;

//Devuelve si una transaccion ya se encuentra pendiente
function TranxAlreadyPending(TrxHash:string):boolean;
var
  cont : integer;
Begin
Result := false;
for cont := 0 to GetPendingCount-1 do
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

// Añade la transaccion pendiente en su lugar
function AddPendingTxs(order:TOrderData):boolean;
var
  cont : integer = 0;
  insertar : boolean = false;
  resultado : integer = 0;
Begin
BeginPerformance('AddPendingTxs');
//if order.OrderType='FEE' then exit;
if order.TimeStamp < LastBlockData.TimeStart then exit;
if TrxExistsInLastBlock(order.TrfrID) then exit;
if not TranxAlreadyPending(order.TrfrID) then
   begin
   EnterCriticalSection(CSPending);
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
   LeaveCriticalSection(CSPending);
   result := true;
   VerifyIfPendingIsMine(order);
   end;
EndPerformance('AddPendingTxs');
End;

// Verifica si la direccion enviada esta en la cartera del usuario
function DireccionEsMia(direccion:string):integer;
var
  contador : integer = 0;
Begin
Result := -1;
if ((direccion ='') or (length(direccion)<5)) then exit;
for contador := 0 to length(Listadirecciones)-1 do
   begin
   if ((ListaDirecciones[contador].Hash = direccion) or (ListaDirecciones[contador].Custom = direccion )) then
      begin
      result := contador;
      break;
      end;
   end;
if ( (not IsValidHashAddress(direccion)) and (AddressSumaryIndex(direccion)<0) ) then result := -1;
End;

// Verifica si una orden especifica es del usuario
Procedure VerifyIfPendingIsMine(order:Torderdata);
var
  DireccionEnvia: string;
Begin
DireccionEnvia := order.address;
if DireccionEsMia(DireccionEnvia)>=0 then
   begin
   ListaDirecciones[DireccionEsMia(DireccionEnvia)].Pending:=ListaDirecciones[DireccionEsMia(DireccionEnvia)].Pending+
      Order.AmmountFee+order.AmmountTrf;
   montooutgoing := montooutgoing+Order.AmmountFee+order.AmmountTrf;
   if not form1.ImageOut.Visible then form1.ImageOut.Visible:= true;
   end;
if DireccionEsMia(Order.Receiver)>=0 then
   begin
   montoincoming := montoincoming+order.AmmountTrf;
   ShowGlobo('Incoming transfer',Int2curr(order.AmmountTrf));
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
for cont := 0 to length(ListaSumario) -1 do
   begin
   if ((ListaSumario[cont].Hash = Address) and (ListaSumario[cont].Custom <> '')) then
      begin
      result := true;
      break;
      end;
   end;
if result = false then
   begin
   for cont := 0 to GetPendingCount-1 do
      begin
      if ((PendingTxs[cont].Address=address) and (PendingTxs[cont].OrderType = 'CUSTOM')) then
         begin
         result := true;
         break;
         end;
      end;
   end;
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
   if ((PendingTxs[counter].reference=NumberStr) and (PendingTxs[counter].OrderType = 'SNDGVT')) then
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
Begin
Result := false;
for cont := 0 to length(ListaSumario) -1 do
   begin
   if (ListaSumario[cont].custom = Addalias)  then
      begin
      result := true;
      break;
      end;
   end;
if not result then
   begin
   for cont := 0 to GetPendingCount-1 do
      begin
      if ((PendingTxs[cont].OrderType='CUSTOM') and (PendingTxs[cont].Receiver = Addalias)) then
         begin
         result := true;
         break;
         end;
      end;
   end;
End;

// Devuelve el indice de la direccion o alias en el sumario, o -1 si no existe
function AddressSumaryIndex(Address:string):integer;
var
  cont : integer = 0;
Begin
result := -1;
if ((address <> '') and (length(ListaSumario) > 0)) then
   begin
   for cont := 0 to length(ListaSumario)-1 do
      begin
      if ((listasumario[cont].Hash=address) or (Listasumario[cont].Custom=address)) then
         begin
         result:= cont;
         break;
         end;
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
Function SendFundsFromAddress(Origen, Destino:String; monto, comision:int64; reference,
  ordertime:String; linea:integer):TOrderData;
var
  MontoDisponible, Montotrfr, comisionTrfr : int64;
  OrderInfo : Torderdata;
Begin
BeginPerformance('SendFundsFromAddress');
MontoDisponible := ListaDirecciones[DireccionEsMia(origen)].Balance-GetAddressPendingPays(Origen);
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
OrderInfo.sender     := ListaDirecciones[DireccionEsMia(origen)].PublicKey;
OrderInfo.Address    := ListaDirecciones[DireccionEsMia(origen)].Hash;
OrderInfo.Receiver   := Destino;
OrderInfo.AmmountFee := ComisionTrfr;
OrderInfo.AmmountTrf := montotrfr;
OrderInfo.Signature  := GetStringSigned(ordertime+origen+destino+IntToStr(montotrfr)+
                     IntToStr(comisiontrfr)+IntToStr(linea),
                     ListaDirecciones[DireccionEsMia(origen)].PrivateKey);
OrderInfo.TrfrID     := GetTransferHash(ordertime+origen+destino+IntToStr(monto)+IntToStr(MyLastblock));
Result := OrderInfo;
EndPerformance('SendFundsFromAddress');
End;

// verifica si en las transaccione pendientes hay alguna de nuestra cartera
Procedure CheckForMyPending();
var
  counter : integer = 0;
  DireccionEnvia : string;
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
if ( (disponible < MinimunFee) or (Disponible<0) ) then
   begin
   result := 0;
   exit;
   end;
maximo     := (Disponible * Comisiontrfr) div (Comisiontrfr+1);
comision   := maximo div Comisiontrfr;
if Comision < MinimunFee then Comision := MinimunFee;
Envio      := maximo + comision;
Diferencia := Disponible-envio;
result     := maximo+diferencia;
End;

function GetCurrentStatus(mode:integer):String;
var
  Resultado : string = '';
Begin
resultado := resultado+'ServerON: '+BoolToStr(Form1.Server.Active,true)+' ';
resultado := resultado+'CONNECT_Try: '+BoolToStr(CONNECT_Try,true)+slinebreak;
if mode = 1 then
   begin
   resultado := resultado+'Date        : '+FormatDateTime('dd MMMM YYYY HH:MM:SS.zzz', Now)+slinebreak;
   resultado := resultado+'MyConStatus : '+IntToStr(myConStatus)+slinebreak;
   Resultado := resultado+'OS          : '+OSVersion +slinebreak;
   Resultado := resultado+'WalletVer   : '+ProgramVersion+SubVersion+slinebreak;
   end;
result := resultado;
End;

function GetMyPosAddressesCount():integer;
var
   PosRequired : int64;
   Contador : integer;
Begin
result := 0;
PosRequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
for contador := 0 to length(ListaDirecciones)-1 do
   if ListaDirecciones[contador].Balance > PosRequired then result +=1;
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
function PendingRawInfo():String;
var
  CopyPendingTXs : Array of TOrderData;
  counter : integer;
  ThisPending : string;
Begin
result := '';
if Length(PendingTXs) > 0 then
   begin
   EnterCriticalSection(CSPending);
   SetLength(CopyPendingTXs,0);
   CopyPendingTXs := copy(PendingTXs,0,length(PendingTXs));
   LeaveCriticalSection(CSPending);
   for counter := 0 to Length(CopyPendingTXs)-1 do
      begin
      ThisPending:=CopyPendingTXs[counter].OrderType+','+
                   CopyPendingTXs[counter].Address+','+
                   CopyPendingTXs[counter].Receiver+','+
                   CopyPendingTXs[counter].AmmountTrf.ToString+','+
                   CopyPendingTXs[counter].AmmountFee.ToString{+','+CopyPendingTXs[counter].TimeStamp.ToString};
      result := result+ThisPending+' ';
      end;
   Trim(result);
   end;
End;

// Returns the length of the pending transactions array safely
Function GetPendingCount():integer;
Begin
EnterCriticalSection(CSPending);
result := Length(PendingTXs);
LeaveCriticalSection(CSPending);
End;

// Clear the pending transactions array safely
Procedure ClearAllPending();
Begin
EnterCriticalSection(CSPending);
SetLength(PendingTXs,0);
LeaveCriticalSection(CSPending);
End;

Function GetDevPercentage(block:integer):integer;
Begin
result := 0;
if block >= PoSBlockEnd then result := 1000;
End;

// Returns the PoS percentage for the specified block (0 to 10000)
Function GetPoSPercentage(block:integer):integer;
Begin
result := 0;
if ((block > 8424) and (block < 40000)) then result := PoSPercentage; // 1000
if block >= 40000 then
   begin
   result := PoSPercentage + (((block-39000) div 1000) * 100);
   if result > 2000 then result := 2000;
   end;
if block >= PoSBlockEnd then result := 0;
End;

// Returns the MNs percentage for the specified block (0 to 10000)
Function GetMNsPercentage(block:integer):integer;
Begin
result := 0;
if block >= MNBlockStart then
   begin
   result := MNsPercentage + (((block-MNBlockStart) div 4000) * 100); // MNsPercentage := 2000
   if block >= PoSBlockEnd then Inc(Result,1000);
   if result > 6000 then result := 6000;
   end;
End;

Function GetStackRequired(block:integer):int64;
Begin
result := (GetSupply(block)*PosStackCoins) div 10000;
End;


END. // END UNIT


