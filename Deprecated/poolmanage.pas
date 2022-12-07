unit PoolManage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdContext, IdGlobal, fileutil;

function PoolDataString(member:string):String;
function GetPoolEmptySlot():integer;
function GetMemberPrefijo(poolslot:integer):string;
function PoolAddNewMember(direccion:string):string;
Procedure LoadMyPoolData();
Procedure SaveMyPoolData();
function GetPoolMemberBalance(direccion:string):int64;
Procedure SetMinerUpdate(Rvalue:boolean;number:integer);
Procedure ResetPoolMiningInfo();
Procedure AdjustWrongSteps();
function GetPoolNumeroDePasos():integer;
Procedure DistribuirEnPool(cantidad:int64);
Function GetTotalPoolDeuda():Int64;
Procedure AcreditarPoolStep(direccion:string; value:integer);
function GetLastPagoPoolMember(direccion:string):integer;
Procedure ClearPoolUserBalance(direccion:string);
Procedure PoolUndoneLastPayment();
function SavePoolServerConnection(Ip,Prefijo,UserAddress,minerver:String;contexto:TIdContext):boolean;
function GetPoolTotalActiveConex ():integer;
function GetPoolContextIndex(AContext: TIdContext):integer;
Procedure BorrarPoolServerConex(AContext: TIdContext);
Procedure CalculatePoolHashrate();
function GetPoolMemberPosition(member:String):integer;
function IsPoolMemberConnected(address:string):integer;
Function NewSavePoolPayment(DataLine:string):boolean;
Function GetMinerHashrate(slot:integer):int64;
function PoolStatusString():String;
function StepAlreadyAdded(stepstring:string):Boolean;
Procedure RestartPoolSolution();
function KickPoolIP(IP:string):integer;
Procedure UpdateMinerPing(index:integer;Hashpower:int64 = -1);
Function IsMinerPinedOut(index:integer):boolean;

implementation

uses
  MasterPaskalForm, mpparser, mpminer, mpdisk, mptime, mpGUI, mpCoin;

//** Returns an array with all the information for miners
function PoolDataString(member:string):String;  // ThSa verified!
var
  MemberBalance : Int64;
  lastpago : integer;
  BlocksTillPayment : integer;
  allinfotext : string;
Begin
MemberBalance := GetPoolMemberBalance(member);
lastpago := GetLastPagoPoolMember(member);
EnterCriticalSection(CSPoolMiner);
BlocksTillPayment := MyLastBlock-(lastpago+PoolInfo.TipoPago);
allinfotext :=IntToStr(PoolMiner.Block)+' '+         // block target
              PoolMiner.Target+' '+                  // string target
              IntToStr(PoolMiner.DiffChars)+' '+     // target chars
              inttostr(PoolMiner.steps)+' '+         // founded steps
              inttostr(PoolMiner.Dificult)+' '+      // block difficult
              IntToStr(MemberBalance)+' '+           // member balance
              IntToStr(BlocksTillPayment)+' '+       // block payment
              IntToStr(PoolTotalHashRate)+' '+
              IntToStr(PoolStepsDeep);           // Pool Hash Rate
LeaveCriticalSection(CSPoolMiner);
Result := 'PoolData '+allinfotext;
End;

//** returns an empty slot in the pool
function GetPoolEmptySlot():integer; // ThSa verified!
var
  contador : integer;
Begin
result := -1;
Entercriticalsection(CSPoolMembers);
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if ArrayPoolMembers[contador].Direccion = '' then
         begin
         result := contador;
         break;
         end;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
End;

//** returns a valid prefix for the miner
function GetMemberPrefijo(poolslot:integer):string;
var
  firstchar, secondchar : integer;
  HashChars : integer;
Begin
HashChars :=  length(HasheableChars)-1;
firstchar := poolslot div HashChars;
secondchar := poolslot mod HashChars;
result := HasheableChars[firstchar+1]+HasheableChars[secondchar+1]+'0000000';
End;

//** Returns the prefix for a new connection or empty if pool is full
function PoolAddNewMember(direccion:string):string;  // ThSa verified!
var
  PoolSlot : integer;
  CurrPos : integer;
Begin
SetCurrentJob('PoolAddNewMember',true);
PoolSlot := GetPoolEmptySlot;
CurrPos := GetPoolMemberPosition(direccion);
EnterCriticalSection(CSPoolMembers);
setmilitime('PoolAddNewMember',1);
result := '';
if ( (length(ArrayPoolMembers)>0) and (CurrPos>=0) ) then
   begin
   result := ArrayPoolMembers[CurrPos].Prefijo;
   end
else if ( (length(ArrayPoolMembers)>0) and (PoolSlot >= 0) ) then
   begin
   ArrayPoolMembers[PoolSlot].Direccion:=direccion;
   ArrayPoolMembers[PoolSlot].Prefijo:=GetMemberPrefijo(PoolSlot);
   ArrayPoolMembers[PoolSlot].Deuda:=0;
   ArrayPoolMembers[PoolSlot].Soluciones:=0;
   ArrayPoolMembers[PoolSlot].LastPago:=MyLastBlock;
   ArrayPoolMembers[PoolSlot].TotalGanado:=0;
   ArrayPoolMembers[PoolSlot].LastSolucion:=0;
   ArrayPoolMembers[PoolSlot].LastEarned:=0;
   S_PoolMembers := true;
   result := ArrayPoolMembers[PoolSlot].Prefijo;
   end;
LeaveCriticalSection(CSPoolMembers);
setmilitime('PoolAddNewMember',2);
SetCurrentJob('PoolAddNewMember',false);
End;

Procedure LoadMyPoolData();
Begin
MyPoolData.Direccion:=Parameter(UserOptions.PoolInfo,0);
MyPoolData.Prefijo:=Parameter(UserOptions.PoolInfo,1);
MyPoolData.Ip:=Parameter(UserOptions.PoolInfo,2);
MyPoolData.port:=StrToIntDef(Parameter(UserOptions.PoolInfo,3),8082);
MyPoolData.MyAddress:=Parameter(UserOptions.PoolInfo,4);
MyPoolData.Name:=Parameter(UserOptions.PoolInfo,5);
MyPoolData.Password:=Parameter(UserOptions.PoolInfo,6);
MyPoolData.balance:=0;
MyPoolData.LastPago:=0;
//Miner_UsingPool := true;
End;

Procedure SaveMyPoolData();
Begin
UserOptions.PoolInfo:=MyPoolData.Direccion+' '+
                      MyPoolData.Prefijo+' '+
                      MyPoolData.Ip+' '+
                      IntToStr(MyPoolData.port)+' '+
                      MyPoolData.MyAddress+' '+
                      MyPoolData.Name+' '+
                      MyPoolData.Password;
S_Options := true;
End;

function GetPoolMemberBalance(direccion:string):int64; // ThSa verified!
var
  contador : integer;
Begin
result :=0;
Entercriticalsection(CSPoolMembers);
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         result := arraypoolmembers[contador].Deuda;
         break;
         end;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
End;

Procedure AdjustWrongSteps();  // ThSa verified!
var
  counter : integer;
Begin
EnterCriticalSection(CSMinersConex);
for counter := 0 to length(PoolServerConex)-1 do
   begin
   if PoolServerConex[counter].Address <> '' then
      begin
      PoolServerConex[counter].WrongSteps-=1;
      if PoolServerConex[counter].WrongSteps<0 then PoolServerConex[counter].WrongSteps := 0;
      end;
   end;
LeaveCriticalSection(CSMinersConex);
End;

Procedure SetMinerUpdate(Rvalue:boolean;number:integer); // ThSa verified!
var
  counter : integer;
Begin
if number = -1 then
   Begin
   EnterCriticalSection(CSMinersConex);
   for counter := 0 to length(PoolServerConex)-1 do
      PoolServerConex[counter].SendSteps:=Rvalue;
   LeaveCriticalSection(CSMinersConex);
   end
else
   begin
   EnterCriticalSection(CSMinersConex);
   PoolServerConex[number].SendSteps:=Rvalue;
   LeaveCriticalSection(CSMinersConex);
   end;
End;

Procedure ResetPoolMiningInfo();
Begin
EnterCriticalSection(CSPoolMiner);
PoolMiner.Block:=LastBlockData.Number+1;
PoolMiner.Solucion:='';
PoolMiner.steps:=0;
PoolMiner.Dificult:=LastBlockData.NxtBlkDiff;
PoolMiner.DiffChars:=GetCharsFromDifficult(PoolMiner.Dificult, PoolMiner.steps);
PoolMiner.Target:=MyLastBlockHash;
AdjustWrongSteps();
PoolMinerBlockFound := false;
SetLength(Miner_PoolSharedStep,0);
LeaveCriticalSection(CSPoolMiner);
SetMinerUpdate(true,-1);
End;

Function GetPoolMinningInfo():PoolMinerData;
Begin
EnterCriticalSection(CSPoolMiner);
result := PoolMiner;
LeaveCriticalSection(CSPoolMiner);
End;

Procedure SetPoolMinningInfo(NewData:PoolMinerData);
Begin
EnterCriticalSection(CSPoolMiner);
PoolMiner := NewData;
LeaveCriticalSection(CSPoolMiner);
End;

function GetPoolNumeroDePasos():integer; // ThSa verified!
var
  contador : integer;
Begin
result := 0;
Entercriticalsection(CSPoolMembers);
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      result := result + arraypoolmembers[contador].Soluciones;
   end;
Leavecriticalsection(CSPoolMembers);
End;

Function GetTotalPoolDeuda():Int64;   // ThSa verified!
var
  contador : integer;
Begin
Result := 0;
Entercriticalsection(CSPoolMembers);
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      Result := Result + arraypoolmembers[contador].Deuda;
   end;
Leavecriticalsection(CSPoolMembers);
End;

Procedure DistribuirEnPool(cantidad:int64);   // ThSa verified!
var
  numerodepasos: integer;
  PoolComision : int64;
  ARepartir, PagoPorStep, PagoPorPOS, MinersConPos: int64;
  contador : integer;
  RepartirShares : int64;
Begin
setmilitime('DistribuirEnPool',1);
ARepartir := Cantidad;
NumeroDePasos := GetPoolNumeroDePasos();
PoolComision := (cantidad* PoolInfo.Porcentaje) div 10000;
PoolInfo.FeeEarned:=PoolInfo.FeeEarned+PoolComision;
ARepartir := ARepartir-PoolComision;
RepartirShares := (ARepartir * PoolShare) div 100;
PagoPorStep := RepartirShares div NumeroDePasos;
// DISTRIBUTE SHARES
for contador := 0 to length(arraypoolmembers)-1 do
   begin
   Entercriticalsection(CSPoolMembers);
   if arraypoolmembers[contador].Soluciones > 0 then
      begin
      arraypoolmembers[contador].Deuda:=arraypoolmembers[contador].Deuda+
         (arraypoolmembers[contador].Soluciones*PagoPorStep);
      arraypoolmembers[contador].TotalGanado:=arraypoolmembers[contador].TotalGanado+
         (arraypoolmembers[contador].Soluciones*PagoPorStep);
      arraypoolmembers[contador].LastEarned:=(arraypoolmembers[contador].Soluciones*PagoPorStep);
      arraypoolmembers[contador].Soluciones := 0;
      end
   else
      begin
      arraypoolmembers[contador].LastEarned:=0;
      end;
   Leavecriticalsection(CSPoolMembers);
   end;
ConsoleLinesAdd('Pool Shares   : '+IntToStr(NumeroDePasos));
ConsoleLinesAdd('Pay per Share : '+Int2Curr(PagoPorStep));
PoolMembersTotalDeuda := GetTotalPoolDeuda();
S_PoolInfo := true;
setmilitime('DistribuirEnPool',2);
End;

Procedure AcreditarPoolStep(direccion:string; value:integer); // ThSa verified!
var
  contador : integer;
Begin
Entercriticalsection(CSPoolMembers);
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         arraypoolmembers[contador].Soluciones :=arraypoolmembers[contador].Soluciones+value;
         arraypoolmembers[contador].LastSolucion:=PoolMiner.Block;
         break;
         end;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
End;

function GetLastPagoPoolMember(direccion:string):integer;   // ThSa verified!
var
  contador : integer;
Begin
result :=-1;
entercriticalsection(CSPoolMembers);
if length(ArrayPoolMembers)>0 then
   begin

   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         result := arraypoolmembers[contador].LastPago;
         break;
         end;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
End;

Procedure ClearPoolUserBalance(direccion:string);  // ThSa verified!
var
  contador : integer;
Begin
entercriticalsection(CSPoolMembers);
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         arraypoolmembers[contador].Deuda:=0;
         arraypoolmembers[contador].LastPago:=MyLastBlock;
         break;
         end;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
S_PoolMembers := true;
S_PoolInfo := true;
PoolMembersTotalDeuda := GetTotalPoolDeuda();
End;

Procedure PoolUndoneLastPayment();  // ThSa verified!
var
  contador : integer;
  totalmenos : int64 = 0;
Begin
entercriticalsection(CSPoolMembers);
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      begin
      totalmenos := totalmenos+ arraypoolmembers[contador].LastEarned;
      arraypoolmembers[contador].Deuda :=arraypoolmembers[contador].Deuda-arraypoolmembers[contador].LastEarned;
      if arraypoolmembers[contador].deuda < 0 then arraypoolmembers[contador].deuda := 0;
      arraypoolmembers[contador].TotalGanado:=arraypoolmembers[contador].TotalGanado-arraypoolmembers[contador].LastEarned;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
S_PoolMembers := true;
ConsoleLinesAdd('Discounted last payment to pool members : '+Int2curr(totalmenos));
PoolMembersTotalDeuda := GetTotalPoolDeuda();
End;

function GetPoolSlotFromPrefjo(prefijo:string):Integer;   // ThSa verified!
var
  counter : integer;
Begin
result := -1;
Entercriticalsection(CSPoolMembers);
for counter := 0 to length(arraypoolmembers)-1 do
   begin
   if arraypoolmembers[counter].Prefijo = prefijo then
      begin
      result := counter;
      break;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
End;

function SavePoolServerConnection(Ip,Prefijo,UserAddress,minerver:String;contexto:TIdContext): boolean; // ThSa verified!
var
  newdato : PoolUserConnection;
  slot: integer;
Begin
result := false;
slot := GetPoolSlotFromPrefjo(Prefijo);
EnterCriticalSection(CSMinersConex);
if slot >= 0 then
   begin
   NewDato := Default(PoolUserConnection);
   NewDato.Ip:=Ip;
   NewDato.Address:=UserAddress;
   NewDato.Context:=Contexto;
   NewDato.slot:=slot;
   NewDato.Version:=minerver;
   NewDato.LastPing:=StrToInt64(UTCTime);
   PoolServerConex[slot] := NewDato;
   result := true;
   U_PoolConexGrid := true;
   end;
LeaveCriticalSection(CSMinersConex);
End;

function GetPoolTotalActiveConex ():integer;  // ThSa verified!
var
  cont:integer;
Begin
result := 0;
EnterCriticalSection(CSMinersConex);
if length(PoolServerConex) > 0 then
   begin
   for cont := 0 to length(PoolServerConex)-1 do
      if PoolServerConex[cont].Address<>'' then result := result + 1;
   end;
LeaveCriticalSection(CSMinersConex);
End;

function GetPoolContextIndex(AContext: TIdContext):integer;  // ThSa verified!
var
  contador : integer = 0;
Begin
result := -1;
EnterCriticalSection(CSMinersConex);
if length(PoolServerConex) > 0 then
   begin
   for contador := 0 to length(PoolServerConex)-1 do
      begin
      if Poolserverconex[contador].Context=AContext then
         begin
         result := contador;
         break;
         end;
      end;
   end;
LeaveCriticalSection(CSMinersConex);
End;

Procedure BorrarPoolServerConex(AContext: TIdContext); // ThSa verified!
var
  contador : integer = 0;
Begin
if G_ClosingAPP then exit;
setmilitime('BorrarPoolServerConex',1);
EnterCriticalSection(CSMinersConex);
if length(PoolServerConex) > 0 then
   begin
   for contador := 0 to length(PoolServerConex)-1 do
      begin
      if Poolserverconex[contador].Context=AContext then
         begin
         if AContext.Connection.Connected then
            TRY
            AContext.Connection.Disconnect;
            EXCEPT ON E:Exception do
               begin
               ToPoolLog('Error trying to RECLOSE pool member:'+E.Message);
               end;
            END;{Try}
         Poolserverconex[contador]:=Default(PoolUserConnection);
         U_PoolConexGrid := true;
         break
         end;
      end;
   end;
LeaveCriticalSection(CSMinersConex);
setmilitime('BorrarPoolServerConex',2);
End;

// VERIFY THE POOL CONECTIONS AND REFRESH POOL TOTAL HASHRATE
Procedure CalculatePoolHashrate();
var
  contador : integer;
  memberaddress : string;
Begin
PoolTotalHashRate := 0;
LastPoolHashRequest := StrToInt64(UTCTime);
if ( (Miner_OwnsAPool) and (length(PoolServerConex)>0) ) then
   begin
   for contador := 0 to length(PoolServerConex)-1 do
      begin
      TRY
      PoolTotalHashRate := PoolTotalHashRate + GetMinerHashrate(contador);
      EXCEPT on E:Exception do
         toPoollog('Error calculating pool hashrate: '+E.Message);
      END{Try};
      end;
   end;
if ( (POOL_LBS) and (poolminer.steps<=8) and (G_TotalPings>500) ) then
   ProcessLinesAdd('Restart');
End;

function GetPoolMemberPosition(member:String):integer;   // ThSa verified!
var
  contador : integer;
Begin
result := -1;
Entercriticalsection(CSPoolMembers);
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion= member then
         begin
         result := contador;
         break;
         end;
      end;
   end;
Leavecriticalsection(CSPoolMembers);
End;

function IsPoolMemberConnected(address:string):integer;  // ThSa verified!
var
  counter : integer;
Begin
result := -1;
EnterCriticalSection(CSMinersConex);
if length(PoolServerConex)>0 then
   begin
   for counter := 0 to length(PoolServerConex)-1 do
      if ((Address<>'') and (PoolServerConex[counter].Address=address)) then
         begin
         result := counter;
         break;
         end;
   end;
LeaveCriticalSection(CSMinersConex);
End;

Function NewSavePoolPayment(DataLine:string):boolean;  // ThSa verified!
var
  archivo : file of PoolPaymentData;
  ThisPay : PoolPaymentData;
Begin
result:= true;
ThisPay := Default(PoolPaymentData);
ThisPay.block:=StrToIntDef(Parameter(DataLine,0),0);
Thispay.address:=Parameter(DataLine,1);
Thispay.amount:=StrToIntDef(Parameter(DataLine,2),0);
Thispay.Order:=Parameter(DataLine,3);
Assignfile(archivo, PoolPaymentsFilename);
{$I-}
reset(archivo);
{$I+}
If IOResult = 0 then// File is open
   begin
   TRY
   seek(archivo,filesize(archivo));
   write(archivo,Thispay);
   insert(Thispay,ArrPoolPays,length(ArrPoolPays));
   EXCEPT ON E:Exception do
      begin
      result := false;
      Consolelinesadd('ERROR SAVING POOLPAYS FILE');
      end;
   END;{Try}
   Closefile(archivo);
   end
else result := false;
End;

Function GetMinerHashrate(slot:integer):int64;   // ThSa verified!
Begin
result := 0;
EnterCriticalSection(CSMinersConex);
result := PoolServerConex[slot].Hashpower;
LeaveCriticalSection(CSMinersConex);
End;

//STATUS 1{PoolHashRate} 2{PoolFee} 3{PoolShare} 4{blockdiff} 5{Minercount} 6{arrayofminers address:balance:blockstillopay:hashpower}
function PoolStatusString():String;          // ThSa verified!
var
  resString : string = '';
  counter : integer;
  miners : integer = 0;
Begin
Entercriticalsection(CSPoolMembers);
TRY
for counter := 0 to length(arraypoolmembers)-1 do
   begin
   if arraypoolmembers[counter].Direccion<>'' then
      begin
      resString := resString+arraypoolmembers[counter].Direccion+':'+IntToStr(arraypoolmembers[counter].Deuda)+':'+
         IntToStr(MyLastBlock-(arraypoolmembers[counter].LastPago+PoolInfo.TipoPago))+
         ':'+GetMinerHashrate(counter).ToString+' ';
      miners +=1;
      end;
   end;
EXCEPT ON E:Exception do
   begin
   ToExcLog('Error generating pool status string: '+E.Message);
   end
END{Try};
Leavecriticalsection(CSPoolMembers);
result:= 'STATUS '+IntToStr(PoolTotalHashRate)+' '+IntToStr(poolinfo.Porcentaje)+' '+
   IntToStr(PoolShare)+' '+IntToStr(PoolMiner.Dificult)+' '+IntToStr(miners)+' '+resString;
End;

function StepAlreadyAdded(stepstring:string):Boolean;   // ThSa verified!
var
  counter : integer;
Begin
result := false;
EnterCriticalSection(CSPoolMiner);
if length(Miner_PoolSharedStep) > 0 then
   begin
   for counter := 0 to length(Miner_PoolSharedStep)-1 do
      begin
      if stepstring = Miner_PoolSharedStep[counter] then
         begin
         result := true;
         break;
         end;
      end;
   end;
LeaveCriticalSection(CSPoolMiner);
end;

Procedure RestartPoolSolution();
var
  steps,counter : integer;
Begin
steps := StrToIntDef(parameter(Miner_RestartedSolution,1),0);
if ( (steps > 0) and  (steps < 10) ) then
   begin
   PoolMiner.steps := steps;
   PoolMiner.DiffChars:=GetCharsFromDifficult(PoolMiner.Dificult, PoolMiner.steps);
   for counter := 0 to steps-1 do
      begin
      PoolMiner.Solucion := PoolMiner.Solucion+Parameter(Miner_RestartedSolution,2+counter)+' ';
      end;
   end;
CrearRestartfile;
End;

function KickPoolIP(IP:string): integer;
var
  counter : integer;
  thiscontext : TIdContext;
Begin
result := 0;
for counter := 0 to length(PoolServerConex)-1 do
   begin
   if PoolServerConex[counter].Ip = Ip then
     begin
     thiscontext := PoolServerConex[counter].Context;
        TRY
        PoolServerConex[counter].Context.Connection.IOHandler.InputBuffer.Clear;
        PoolServerConex[counter].Context.Connection.Disconnect;
        result := result+1;
        BorrarPoolServerConex(thiscontext);
        EXCEPT ON E: Exception do
           begin
           ToPoolLog('Cant kick connection from: '+IP);
           end;
        end;
     end;
   end;
End;

// ***** New ThSa functions

Procedure UpdateMinerPing(index:integer;Hashpower:int64 = -1);
Begin
EnterCriticalSection(CSMinersConex);
PoolServerConex[index].LastPing:=UTCTime.ToInt64;
if hashpower > -1 then PoolServerConex[index].Hashpower:=Hashpower;
LeaveCriticalSection(CSMinersConex);
End;

Function IsMinerPinedOut(index:integer):boolean;
var
  LastPing : int64;
Begin
result := false;
EnterCriticalSection(CSMinersConex);
LastPing := PoolServerConex[index].LastPing;
LeaveCriticalSection(CSMinersConex);
if LastPing+15<UTCTime.ToInt64 then result := true;
End;

END. // END UNIT

