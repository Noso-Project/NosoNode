unit mpBlock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm, mpCripto, mpMiner, fileutil, mpcoin, dialogs,poolmanage,
  mptime;

Procedure CrearBloqueCero();
Procedure CrearNuevoBloque(Numero,TimeStamp: Int64; TargetHash, Minero, Solucion:String);
function GetDiffForNextBlock(UltimoBloque,Last20Average,lastblocktime,previous:integer):integer;
function GetLast20Time(LastBlTime:integer):integer;
function GetBlockReward(BlNumber:int64):Int64;
Procedure GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;Ordenes:array of OrderData);
function LoadBlockDataHeader(BlockNumber:integer):BlockHeaderData;
function GetBlockTrxs(BlockNumber:integer):BlockOrdersArray;
Procedure UndoneLastBlock();
function GetBlockWork(solucion:string):int64;

implementation

Uses
  mpDisk,mpProtocol, mpGui, mpparser;

// Crea el bloque CERO con los datos por defecto
Procedure CrearBloqueCero();
Begin
CrearNuevoBloque(0,GenesysTimeStamp,'',adminhash,'');
if G_Launching then ConsoleLinesAdd(LangLine(88)); //'Block 0 created.'
if G_Launching then OutText('✓ Block 0 created',false,1);
End;

// Crea un bloque nuevo con la informacion suministrada
Procedure CrearNuevoBloque(Numero,TimeStamp: int64; TargetHash, Minero, Solucion:String);
var
  BlockHeader : BlockHeaderData;
  StartBlockTime : int64 = 0;
  MinerFee : int64 = 0;
  ListaOrdenes : Array of OrderData;
  IgnoredTrxs  : Array of OrderData;
  Filename : String;
  Contador : integer = 0;
  OperationAddress : string = '';
  PoScount : integer = 0;
  PosRequired, PosReward : int64;

  // Variables para la inclusion de Feecomision
  {FeeCom : int64 = 0;
  FeeOrder : OrderData;
  DelAddr : String = '';
  LastOP : integer = 0;}
  PoSAddressess : array of string[32];
Begin
if ((numero>0) and (Timestamp < lastblockdata.TimeEnd)) then
   begin
   ConsoleLinesAdd('New block '+IntToStr(numero)+' : Invalid timestamp');
   ConsoleLinesAdd('Blocks can not be added until '+TimestampToDate(IntToStr(GenesysTimeStamp)));
   exit;
   end;
if Numero = 0 then StartBlockTime := 1531896783
else StartBlockTime := LastBlockData.TimeEnd+1;
FileName := BlockDirectory + IntToStr(Numero)+'.blk';
SetLength(ListaOrdenes,0);
SetLength(IgnoredTrxs,0);
// CREAR COPIA DEL SUMARIO
if fileexists(SumarioFilename+'.bak') then deletefile(SumarioFilename+'.bak');
copyfile(SumarioFilename,SumarioFilename+'.bak');
// PROCESAR LAS TRANSACCIONES EN LISTAORDENES
for contador := 0 to length(pendingTXs)-1 do
   begin
   if PendingTXs[contador].TimeStamp+60 > TimeStamp then
      begin
      insert(PendingTXs[contador],IgnoredTrxs,length(IgnoredTrxs));
      continue;
      end;
   if PendingTXs[contador].OrderType='CUSTOM' then
      begin
      minerfee := minerfee+PendingTXs[contador].AmmountFee;
      OperationAddress := GetAddressFromPublicKey(PendingTXs[contador].Sender);
      if not SetCustomAlias(OperationAddress,PendingTXs[contador].Receiver) then
         begin
         // CRITICAL ERROR: NO SE PUDO ASIGNAR EL ALIAS
         end;
      UpdateSumario(OperationAddress,Restar(PendingTXs[contador].AmmountFee),0,IntToStr(Numero));
      PendingTXs[contador].Block:=numero;
      PendingTXs[contador].Sender:=OperationAddress;
      insert(PendingTXs[contador],ListaOrdenes,length(listaordenes));
      end;
   if PendingTXs[contador].OrderType='TRFR' then
      begin
      OperationAddress := GetAddressFromPublicKey(PendingTXs[contador].Sender);
      // nueva adicion para que no incluya las transacciones invalidas
      if GetAddressBalance(OperationAddress) < (PendingTXs[contador].AmmountFee+PendingTXs[contador].AmmountTrf) then continue;
      minerfee := minerfee+PendingTXs[contador].AmmountFee;
      // restar transferencia y comision de la direccion que envia
      UpdateSumario(OperationAddress,Restar(PendingTXs[contador].AmmountFee+PendingTXs[contador].AmmountTrf),0,IntToStr(Numero));
      // sumar transferencia al receptor
      UpdateSumario(PendingTXs[contador].Receiver,PendingTXs[contador].AmmountTrf,0,IntToStr(Numero));
      PendingTXs[contador].Block:=numero;
      PendingTXs[contador].Sender:=OperationAddress;
      insert(PendingTXs[contador],ListaOrdenes,length(listaordenes));
      end;
   end;

// PoS payment
//SetLength(PoSAddressess,0);
//PosRequired := (GetSupply*PosStackCoins) div 10000;
//for contador := 1 to length(ListaSumario)-1 do
//   begin
//   if listasumario[contador].Balance > PosRequired then
//      begin
//      PoScount +=1;
//      Insert(listasumario[contador].Hash,PoSAddressess,length(PoSAddressess));
//      end;
//   end;
//PosReward := ((GetBlockReward(Numero)+MinerFee)*PoSPercentage) div 10000;
//Consolelines.Add('PoS stack    : '+Int2curr(PosRequired));
//ConsoleLines.Add('PoS addresses: '+IntToStr(PoScount));
//ConsoleLines.Add('PoS reward   : '+Int2curr(PosReward div PoScount));
//tolog('PoS addresses at block: '+inttostr(Numero));
//for contador := 0 to length(PoSAddressess)-1 do
//   tolog(PoSAddressess[contador]);

//** Fin del procesado de las operaciones Pending
{
// Procesar si hay que descontar comisiones por inactividad
if ((numero>0) and (Numero mod ComisionBlockCheck = 0)) then
   begin
   for contador := 1 to length(ListaSumario)-1 do
      begin
      LastOP := ListaSumario[contador].LastOP;
      FeeCom := ((Numero-LastOP) div ComisionBlockCheck)*DeadAddressFee;
      // Si hay comision, si la direccion no tiene pendientes ni es el minero
      if (FeeCom>0) and (not HaveAddressAnyPending(ListaSumario[contador].Hash)and
         (ListaSumario[contador].Hash<>Minero)) then
         begin
         deladdr := 'NO';
         if ((ListaSumario[contador].Balance>0) and (ListaSumario[contador].Balance<FeeCom)) then
           feeCom := ListaSumario[contador].Balance
         else if ListaSumario[contador].Balance = 0 then
            begin
            deladdr := 'YES';
            FeeCom := 0;
            end;
         FeeOrder := Default(OrderData);
         FeeOrder.Block:=numero;
         FeeOrder.OrderID:=GetOrderHash('FEE'+IntToStr(numero)+ListaSumario[contador].Hash+InttoStr(FeeCom));
         FeeOrder.OrderLines:=1;
         FeeOrder.OrderType:='FEE';
         FeeOrder.TimeStamp:=TimeStamp;
         FeeOrder.Concept:=IntToStr(LastOp)+' to '+IntToStr(numero)+' ('+
                           IntToStr((Numero-LastOP) div ComisionBlockCheck)+')';
         FeeOrder.TrxLine:=1;
         FeeOrder.Sender:=ListaSumario[contador].Hash;
         FeeOrder.Receiver:='null';
         FeeOrder.AmmountFee:=FeeCom;
         FeeOrder.AmmountTrf:=0;
         FeeOrder.Signature:=deladdr;
         FeeOrder.TrfrID:=deladdr;
         minerfee := minerFee+FeeCom;
         insert(FeeOrder,ListaOrdenes,length(listaordenes));
         UpdateSumario(FeeOrder.Sender,Restar(feecom),0,IntToStr(LastOP));
         if DelAddr = 'YES' then
            begin
            Delete(ListaSumario,AddressSumaryIndex(FeeOrder.Sender),1);
            ConsoleLinesAdd('Deleted '+FeeOrder.Sender);
            end
         end;
      end;
   end;
//** Fin comisiones por inactividad
}
// Pago del minero
UpdateSumario(Minero,GetBlockReward(Numero)+MinerFee,0,IntToStr(numero));
// Actualizar el ultimo bloque añadido al sumario
ListaSumario[0].LastOP:=numero;
// Guardar el sumario
GuardarSumario();
// Limpiar las pendientes
SetLength(PendingTXs,0);
PendingTXs := copy(IgnoredTrxs,0,length(IgnoredTrxs));
for contador := 0 to length(ListaDirecciones)-1 do
   ListaDirecciones[contador].Pending:=0;
// Definir la cabecera del bloque *****
BlockHeader := Default(BlockHeaderData);
BlockHeader.Number := Numero;
BlockHeader.TimeStart:= StartBlockTime;
BlockHeader.TimeEnd:= timeStamp;
BlockHeader.TimeTotal:= TimeStamp - StartBlockTime;
BlockHeader.TimeLast20:=GetLast20Time(BlockHeader.TimeTotal);
BlockHeader.TrxTotales:=length(ListaOrdenes);
if numero = 0 then BlockHeader.Difficult:= InitialBlockDiff
else BlockHeader.Difficult:= LastBlockData.NxtBlkDiff;
BlockHeader.TargetHash:=TargetHash;
BlockHeader.Solution:= Solucion;
if numero = 0 then BlockHeader.LastBlockHash:='NOSO GENESYS BLOCK'
else BlockHeader.LastBlockHash:=MyLastBlockHash;
BlockHeader.NxtBlkDiff:=GetDiffForNextBlock(numero,BlockHeader.TimeLast20,BlockHeader.TimeTotal,BlockHeader.Difficult);
BlockHeader.AccountMiner:=Minero;
BlockHeader.MinerFee:=MinerFee;
BlockHeader.Reward:=GetBlockReward(Numero);
// Fin de la cabecera -----
// Guardar bloque al disco
GuardarBloque(FileName,BlockHeader,ListaOrdenes);
// Actualizar informacion
MyLastBlock := Numero;
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MySumarioHash := HashMD5File(SumarioFilename);
// Actualizar el arvhivo de cabeceras
AddBlchHead(Numero,MyLastBlockHash,MySumarioHash);
MyResumenHash := HashMD5File(ResumenFilename);
ResetMinerInfo();
ResetPoolMiningInfo();
copyfile (PoolMembersFilename,PoolMembersFilename+'.bak');
if ((Miner_OwnsAPool) and (PoolExpelBlocks>0)) then ExpelPoolInactives();
if minero = PoolInfo.Direccion then
   begin
   ConsoleLinesAdd('Your pool solved the block '+inttoStr(numero));
   DistribuirEnPool(GetBlockReward(Numero)+MinerFee);
   end;
if minero = RPC_MinerInfo then
   begin
   RPC_MinerReward := GetBlockReward(Numero)+MinerFee;
   end;
if Numero>0 then
   begin
   OutgoingMsjs.Add(ProtocolLine(6)+IntToStr(timeStamp)+' '+IntToStr(Numero)+
   ' '+Minero+' '+StringReplace(Solucion,' ','_',[rfReplaceAll, rfIgnoreCase]));
   OutgoingMsjs.Add(ProtocolLine(ping));
   end;
OutText(LangLine(89)+IntToStr(numero),true);  //'Block builded: '
if Numero > 0 then RebuildMyTrx(Numero);
CheckForMyPending;
if DIreccionEsMia(Minero)>-1 then showglobo('Miner','Block found!');
U_DataPanel := true;
End;

// Devuelve cuantos caracteres compondran el targethash del siguiente bloque
function GetDiffForNextBlock(UltimoBloque,Last20Average, lastblocktime,previous:integer):integer;
Begin
result := previous;
if UltimoBloque < 21 then result := InitialBlockDiff
else
   begin
   if Last20Average < SecondsPerBlock then
      begin
      if lastblocktime<SecondsPerBlock then result := Previous+1
      end
   else if Last20Average > SecondsPerBlock then
      begin
      if lastblocktime>SecondsPerBlock then result := Previous-1
      end
   else result := previous;
   end;
End;

// Hace el calculo del tiempo promedio empleado en los ultimos 20 bloques
function GetLast20Time(LastBlTime:integer):integer;
var
  Part1, Part2 : integer;
Begin
if LastBlockData.Number<21 then result := SecondsPerBlock
else
   begin
   Part1 := LastBlockData.TimeLast20 * 19 div 20;
   Part2 := LastBlTime div 20;
   result := Part1 + Part2;
   end;
End;

// RETURNS THE MINING REWARD FOR A BLOCK
function GetBlockReward(BlNumber:int64):Int64;
var
  NumHalvings : integer;
Begin
if BlNumber = 0 then result := PremineAmount
else if ((BlNumber > 0) and (blnumber < BlockHalvingInterval*(HalvingSteps+1))) then
   begin
   numHalvings := BlNumber div BlockHalvingInterval;
   result := InitialReward div StrToInt64(BMExponente('2',IntToStr(numHalvings)));
   end
else result := 0;
End;

// Guarda el archivo de bloque en disco
Procedure GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;Ordenes:array of OrderData);
var
  MemStr: TMemoryStream;
  NumeroOrdenes : int64;
  counter : integer;
Begin
NumeroOrdenes := Cabezera.TrxTotales;
MemStr := TMemoryStream.Create;
   try
   MemStr.Write(Cabezera,Sizeof(Cabezera));
   for counter := 0 to NumeroOrdenes-1 do
      MemStr.Write(Ordenes[counter],Sizeof(Ordenes[Counter]));
   MemStr.SaveToFile(NombreArchivo);
   MemStr.Free;
   Except
   On E :Exception do ConsoleLinesAdd(LangLine(20));           //Error saving block to disk
   end;
End;

// Carga la informacion del bloque
function LoadBlockDataHeader(BlockNumber:integer):BlockHeaderData;
var
  MemStr: TMemoryStream;
  Header : BlockHeaderData;
  ArchData : String;
Begin
Header := Default(BlockHeaderData);
ArchData := BlockDirectory+IntToStr(BlockNumber)+'.blk';
MemStr := TMemoryStream.Create;
   try
   MemStr.LoadFromFile(ArchData);
   MemStr.Position := 0;
   MemStr.Read(Header, SizeOf(Header));
   finally
   MemStr.Free;
   end;
Result := header;
End;

// Devuelve las transacciones del bloque
function GetBlockTrxs(BlockNumber:integer):BlockOrdersArray;
var
  ArrTrxs : BlockOrdersArray;
  MemStr: TMemoryStream;
  Header : BlockHeaderData;
  ArchData : String;
  counter : integer;
  TotalTrxs : integer;
Begin
Setlength(ArrTrxs,0);
ArchData := BlockDirectory+IntToStr(BlockNumber)+'.blk';
MemStr := TMemoryStream.Create;
   try
   MemStr.LoadFromFile(ArchData);
   MemStr.Position := 0;
   MemStr.Read(Header, SizeOf(Header));
   TotalTrxs := header.TrxTotales;
   SetLength(ArrTrxs,TotalTrxs);
   For Counter := 0 to TotalTrxs-1 do
      MemStr.Read(ArrTrxs[Counter],Sizeof(ArrTrxs[Counter])); // read each record
   Except on E: Exception do // nothing, the block is not founded
   end;
MemStr.Free;
Result := ArrTrxs;
End;

// Deshacer el ultimo bloque
Procedure UndoneLastBlock();
var
  blocknumber : integer;
  ArrayOrders : BlockOrdersArray;
  cont : integer;
Begin
blocknumber:= MyLastBlock;
// recuperar el sumario
if fileexists(SumarioFilename) then deletefile(SumarioFilename);
copyfile(SumarioFilename+'.bak',SumarioFilename);
CargarSumario();
// Actualizar la cartera
UpdateWalletFromSumario();
// actualizar el archivo de cabeceras
DelBlChHeadLast();
// Recuperar transacciones
ArrayOrders := Default(BlockOrdersArray);
ArrayOrders := GetBlockTrxs(MyLastBlock);
for cont := 0 to length(ArrayOrders)-1 do
   addpendingtxs(ArrayOrders[cont]);
if LastBlockData.AccountMiner = PoolInfo.Direccion then // El bloque deshecho fue minado por mi pool
   PoolUndoneLastPayment();
// Borrar archivo del ultimo bloque
deletefile(BlockDirectory +IntToStr(MyLastBlock)+'.blk');
// Actualizar mi informacion
MyLastBlock := GetMyLastUpdatedBlock;
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MyResumenHash := HashMD5File(ResumenFilename);
ResetMinerInfo();
ConsoleLinesAdd('****************************');
ConsoleLinesAdd(LAngLine(90)+IntToStr(blocknumber)); //'Block undone: '
ConsoleLinesAdd('****************************');
Tolog('Block Undone: '+IntToStr(blocknumber));
End;

// devuelve la suma de los valores de la solucion de un bloque (eliminar?)
function GetBlockWork(solucion:string):int64;
var
  contador : integer;
  paso: string;
Begin
result := 0;
for contador := 0 to Miner_Steps-1 do
   begin
   paso := Parameter(solucion,contador);
   paso := copy(paso,10,9);
   result += CadToNum(paso,0,'**CRITICAL: Error reading value of block solution.');
   end;
End;


END. // END UNIT

