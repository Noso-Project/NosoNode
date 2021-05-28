unit PoolManage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdContext, IdGlobal, fileutil;

procedure StartPoolServer(port:integer);
Procedure StopPoolServer();
function PoolDataString(member:string):String;
function GetPoolEmptySlot():integer;
function GetMemberPrefijo(poolslot:integer):string;
function PoolAddNewMember(direccion:string):string;
Procedure LoadMyPoolData();
Procedure SaveMyPoolData();
function GetPoolMemberBalance(direccion:string):int64;
Procedure ResetPoolMiningInfo();
Procedure AdjustWrongSteps();
function GetPoolNumeroDePasos():integer;
Procedure DistribuirEnPool(cantidad:int64);
Function GetTotalPoolDeuda():Int64;
Procedure AcreditarPoolStep(direccion:string; value:integer);
function GetLastPagoPoolMember(direccion:string):integer;
Procedure ClearPoolUserBalance(direccion:string);
Procedure PoolUndoneLastPayment();
function GetPoolConexFreeSlot():integer;
function SavePoolServerConnection(Ip,UserAddress,minerver:String;contexto:TIdContext):boolean;
function GetPoolTotalActiveConex ():integer;
Procedure BorrarPoolServerConex(AContext: TIdContext);
Procedure SendPoolStepsInfo(steps:integer);
Procedure SendPoolHashRateRequest();
function GetPoolMemberPosition(member:String):integer;
function IsPoolMemberConnected(address:string):integer;
function GetPoolSlotFromContext(context:TIdContext):integer;
Procedure ExpelPoolInactives();
function PoolStatusString():String;
function StepAlreadyAdded(stepstring:string):Boolean;

implementation

uses
  MasterPaskalForm, mpparser, mpminer, mpdisk, mptime, mpGUI;

// Activa el servidor del pool
procedure StartPoolServer(port:integer);
Begin
if Form1.PoolServer.Active then
   begin
   ConsoleLinesAdd('Pool server already active'); //'Server Already active'
   exit;
   end;
try
   Form1.PoolServer.Bindings.Clear;
   Form1.PoolServer.DefaultPort:=port;
   Form1.PoolServer.Active:=true;
   ConsoleLinesAdd('Pool server enabled at port: '+IntToStr(port));   //Server ENABLED. Listening on port
except on E : Exception do
   ConsoleLinesAdd('Unable to start pool server: '+E.Message);       //Unable to start Server
end;
end;

// Detiene el servidor del pool
Procedure StopPoolServer();
Begin
if Form1.PoolServer.Active then Form1.PoolServer.Active:=false;
End;

//** Returns an array with all the information for miners
function PoolDataString(member:string):String;
var
  MemberBalance : Int64;
  BlocksTillPayment : integer;
  allinfotext : string;
Begin
MemberBalance := GetPoolMemberBalance(member);
BlocksTillPayment := MyLastBlock-(GetLastPagoPoolMember(member)+PoolInfo.TipoPago);
allinfotext :=IntToStr(PoolMiner.Block)+' '+         // block target
              PoolMiner.Target+' '+                  // string target
              IntToStr(PoolMiner.DiffChars)+' '+     // target chars
              inttostr(PoolMiner.steps)+' '+         // founded steps
              inttostr(PoolMiner.Dificult)+' '+      // block difficult
              IntToStr(MemberBalance)+' '+           // member balance
              IntToStr(BlocksTillPayment)+' '+       // block payment
              IntToStr(PoolTotalHashRate)+' '+
              IntToStr(PoolStepsDeep);           // Pool Hash Rate
Result := 'PoolData '+allinfotext;
End;

//** returns an empty slot in the pool
function GetPoolEmptySlot():integer;
var
  contador : integer;
Begin
result := -1;
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
//resultado := chr(33+firstchar)+chr(33+secondchar)+'!!!!!!!';
//resultado := StringReplace(resultado,'(','~',[rfReplaceAll, rfIgnoreCase]);
//resultado := StringReplace(resultado,'%','|',[rfReplaceAll, rfIgnoreCase]);
//result := StringReplace(resultado,'_','}',[rfReplaceAll, rfIgnoreCase])
result := HasheableChars[firstchar+1]+HasheableChars[secondchar+1]+'0000000';
End;

//** Returns the prefix for a new connection or empty if pool is full
function PoolAddNewMember(direccion:string):string;
var
  PoolSlot : integer;
Begin
EnterCriticalSection(CSPoolMembers);
result := '';
if length(ArrayPoolMembers)>0 then
   begin
   if GetPoolMemberPosition(direccion)>=0 then
      begin
      result := ArrayPoolMembers[GetPoolMemberPosition(direccion)].Prefijo;
      LeaveCriticalSection(CSPoolMembers);
      exit;
      end;
   end;
PoolSlot := GetPoolEmptySlot;
if ( (length(ArrayPoolMembers)>0) and (PoolSlot >= 0) ) then
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
   LeaveCriticalSection(CSPoolMembers);
   exit;
   end;
if length(ArrayPoolMembers) < PoolInfo.MaxMembers then
   begin
   SetLength(ArrayPoolMembers,length(ArrayPoolMembers)+1);
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Direccion:=direccion;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Prefijo:=GetMemberPrefijo(length(ArrayPoolMembers)-1);
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Deuda:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Soluciones:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].LastPago:=MyLastBlock;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].TotalGanado:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].LastSolucion:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].LastEarned:=0;
   S_PoolMembers := true;
   result := ArrayPoolMembers[length(ArrayPoolMembers)-1].Prefijo;
   end;
LeaveCriticalSection(CSPoolMembers);
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

function GetPoolMemberBalance(direccion:string):int64;
var
  contador : integer;
Begin
result :=-1;
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
End;

Procedure AdjustWrongSteps();
var
  counter : integer;
Begin
for counter := 0 to length(PoolServerConex)-1 do
   begin
   if PoolServerConex[counter].Address <> '' then
      begin
      PoolServerConex[counter].WrongSteps-=1;
      if PoolServerConex[counter].WrongSteps<0 then PoolServerConex[counter].WrongSteps := 0;
      end;
   end;
End;

Procedure ResetPoolMiningInfo();
Begin
PoolMiner.Block:=LastBlockData.Number+1;
PoolMiner.Solucion:='';
PoolMiner.steps:=0;
PoolMiner.Dificult:=LastBlockData.NxtBlkDiff;
PoolMiner.DiffChars:=GetCharsFromDifficult(PoolMiner.Dificult, PoolMiner.steps);
PoolMiner.Target:=MyLastBlockHash;
AdjustWrongSteps();
SetLength(Miner_PoolSharedStep,0);
ProcessLinesAdd('SENDPOOLSTEPS 0');
end;

function GetPoolNumeroDePasos():integer;
var
  contador : integer;
Begin
result := 0;
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      result := result + arraypoolmembers[contador].Soluciones;
   end;
End;

Function GetTotalPoolDeuda():Int64;
var
  contador : integer;
  resultado : int64 = 0;
Begin
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      resultado := resultado + arraypoolmembers[contador].Deuda;
   end;
result := resultado;
End;

Procedure DistribuirEnPool(cantidad:int64);
var
  numerodepasos: integer;
  PoolComision : int64;
  ARepartir, PagoPorStep, PagoPorPOS, MinersConPos: int64;
  contador : integer;
  RepartirShares : int64;

  function GetValidMinersForShare():integer;
  var
    count : integer;
  Begin
  result := 0;
  for count := 0 to length(arraypoolmembers)-1 do
     if ( (IsPoolMemberConnected(arraypoolmembers[count].Direccion)>=0) and
        (arraypoolmembers[count].LastSolucion+10000>=PoolMiner.Block) ) then result +=1;
  End;

Begin
ARepartir := Cantidad;
NumeroDePasos := GetPoolNumeroDePasos();
PoolComision := (cantidad* PoolInfo.Porcentaje) div 10000;
PoolInfo.FeeEarned:=PoolInfo.FeeEarned+PoolComision;
ARepartir := ARepartir-PoolComision;
RepartirShares := (ARepartir * PoolShare) div 100;
ARepartir := ARepartir - RepartirShares;
PagoPorStep := RepartirShares div NumeroDePasos;
// DISTRIBUTE SHARES
for contador := 0 to length(arraypoolmembers)-1 do
   begin
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
   end;
ConsoleLinesAdd('Pool Shares   : '+IntToStr(NumeroDePasos));
ConsoleLinesAdd('Pay per Share : '+IntToStr(PagoPorStep));
// DISTRIBUTE PART
MinersConPos := GetValidMinersForShare;
if ((ARepartir>0) and (MinersConPos>0)) then
   begin
   PagoPorPOS := ARepartir div MinersConPos;
   for contador := 0 to length(arraypoolmembers)-1 do
      begin
      if ( (IsPoolMemberConnected(arraypoolmembers[contador].Direccion)>=0) and
        (arraypoolmembers[contador].LastSolucion+10000>=PoolMiner.Block) ) then
         begin
         arraypoolmembers[contador].Deuda:=arraypoolmembers[contador].Deuda+PagoPorPOS;
         arraypoolmembers[contador].TotalGanado:=arraypoolmembers[contador].TotalGanado+PagoPorPOS;
         arraypoolmembers[contador].LastEarned:=arraypoolmembers[contador].LastEarned+PagoPorPOS;
         end;
      end;
   ConsoleLinesAdd('POOL POP: '+IntToStr(MinersConPos)+' members, each= '+Int2Curr(PagoPorPOS));
   end;
PoolMembersTotalDeuda := GetTotalPoolDeuda();
S_PoolMembers := true;
S_PoolInfo := true;
End;

Procedure AcreditarPoolStep(direccion:string; value:integer);
var
  contador : integer;
Begin
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         arraypoolmembers[contador].Soluciones :=arraypoolmembers[contador].Soluciones+value;
         arraypoolmembers[contador].LastSolucion:=PoolMiner.Block;
         end;
      end;
   end;
S_PoolMembers := true;
End;

function GetLastPagoPoolMember(direccion:string):integer;
var
  contador : integer;
Begin
result :=-1;
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
End;

Procedure ClearPoolUserBalance(direccion:string);
var
  contador : integer;
Begin
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
S_PoolMembers := true;
S_PoolInfo := true;
PoolMembersTotalDeuda := GetTotalPoolDeuda();
End;

Procedure PoolUndoneLastPayment();
var
  contador : integer;
  totalmenos : int64 = 0;
Begin
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
S_PoolMembers := true;
ConsoleLinesAdd('Discounted last payment to pool members : '+Int2curr(totalmenos));
PoolMembersTotalDeuda := GetTotalPoolDeuda();
End;

function GetPoolConexFreeSlot():integer;
var
  cont: integer;
begin
result := -1;
for cont := 0 to length(PoolServerConex)-1 do
   if PoolServerConex[cont].Address = '' then
      begin
      result := cont;
      break;
      end;
end;

function SavePoolServerConnection(Ip,UserAddress,minerver:String;contexto:TIdContext): boolean;
var
  newdato : PoolUserConnection;
  slot: integer;
Begin
result := false;
slot := GetPoolConexFreeSlot;
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
End;

function GetPoolTotalActiveConex ():integer;
var
  cont:integer;
  resultado : integer = 0;
Begin
result := 0;
if length(PoolServerConex) > 0 then
   begin
   for cont := 0 to length(PoolServerConex)-1 do
      if PoolServerConex[cont].Address<>'' then resultado := resultado + 1;
   end;
result := resultado;
End;

Procedure BorrarPoolServerConex(AContext: TIdContext);
var
  contador : integer = 0;
Begin
if length(PoolServerConex) > 0 then
   begin
   for contador := 0 to length(PoolServerConex)-1 do
      begin
      if Poolserverconex[contador].Context=AContext then
         begin
         Poolserverconex[contador]:=Default(PoolUserConnection);
           try
           Acontext.Connection.IOHandler.InputBuffer.Clear;
           AContext.Connection.Disconnect;
           Except on E:Exception do
           begin
           ConsoleLinesAdd('Error closing pool connection');
           end;
         end;
         U_PoolConexGrid := true;
         break
         end;
      end;
   end;
End;

Procedure SendPoolStepsInfo(steps:integer);
var
  contador : integer;
Begin
if length(PoolServerConex)>0 then
   begin
   for contador := 0 to length(PoolServerConex)-1 do
      begin
      try
      if PoolServerConex[contador].Address<>'' then
         begin
         PoolServerConex[contador].context.Connection.IOHandler.WriteLn('POOLSTEPS '+
            PoolDataString(PoolServerConex[contador].Address));
         end;
      except on E:Exception do
         begin
         tolog('Error sending pool steps, slot '+IntToStr(contador));
         end;
      end;
      end;
   end;
End;

// VERIFY THE POOL CONECTIONS AND REFRESH POOL TOTAL HASHRATE
Procedure SendPoolHashRateRequest();
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
      try
      memberaddress := PoolServerConex[contador].Address;
      if memberaddress <> '' then
         begin
         PoolTotalHashRate := PoolTotalHashRate+PoolServerConex[contador].Hashpower;
         if PoolServerConex[contador].LastPing+15<StrToInt64Def(UTCTime,0) then
            BorrarPoolServerConex(PoolServerConex[contador].Context);
         end;
      except on E:Exception do
         begin
         tolog('Error verifyng pool conex: '+IntToStr(contador));
         end;
      end;
      end;
   end;
End;

function GetPoolMemberPosition(member:String):integer;
var
  contador : integer;
Begin
result := -1;
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
End;

function IsPoolMemberConnected(address:string):integer;
var
  counter : integer;
Begin
result := -1;
if length(PoolServerConex)>0 then
   begin
   for counter := 0 to length(PoolServerConex)-1 do
      if ((Address<>'') and (PoolServerConex[counter].Address=address)) then
         begin
         result := counter;
         break;
         end;
   end;
End;

// Especifica la posicion de una conexion en el array
function GetPoolSlotFromContext(context:TIdContext):integer;
var
  counter : integer;
Begin
result := -1;
if length(PoolServerConex)>0 then
   begin
   for counter := 0 to length(PoolServerConex)-1 do
      if PoolServerConex[counter].Context=context then
         result := counter;
   end;
End;

Procedure ExpelPoolInactives();
var
  counter : integer;
  expelled : integer = 0;
Begin
if length(arraypoolmembers)>0 then
   begin
   for counter := 0 to length(arraypoolmembers)-1 do
      begin
      if arraypoolmembers[counter].LastSolucion+PoolExpelBlocks<PoolMiner.Block then
         begin
         if ( (IsPoolMemberConnected(arraypoolmembers[counter].Direccion)<0) and
             (arraypoolmembers[counter].Direccion<>'')) then
            begin
            ProcessLinesAdd('POOLEXPEL '+arraypoolmembers[counter].Direccion+' YES');
            expelled +=1;
            end;
         end;
      // include auto pool payments
      end;
   end;
ConsoleLinesAdd('Pool expels: '+IntToStr(expelled));
End;

function PoolStatusString():String;
var
  resString : string = '';
  counter : integer;
  miners : integer = 0;
Begin
for counter := 0 to length(arraypoolmembers)-1 do
   begin
   if arraypoolmembers[counter].Direccion<>'' then
      begin
      resString := resString+arraypoolmembers[counter].Direccion+':'+IntToStr(arraypoolmembers[counter].Deuda)+':'+
         IntToStr(MyLastBlock-(arraypoolmembers[counter].LastPago+PoolInfo.TipoPago))+' ';
      miners +=1;
      end;
   end;
result:= 'STATUS '+IntToStr(PoolTotalHashRate)+' '+IntToStr(poolinfo.Porcentaje)+' '+
   IntToStr(PoolShare)+' '+IntToStr(miners)+' '+resString;
End;

function StepAlreadyAdded(stepstring:string):Boolean;
var
  counter : integer;
Begin
result := false;
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

end;

END. // END UNIT

