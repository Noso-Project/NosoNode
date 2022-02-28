unit mpBlock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm, mpCripto, mpMiner, fileutil, mpcoin, dialogs,poolmanage,
  mptime;

Procedure CrearBloqueCero();
Procedure CrearNuevoBloque(Numero,TimeStamp: Int64; TargetHash, Minero, Solucion:String);
Function GetDiffHashrate(bestdiff:String):integer;
function GetDiffForNextBlock(UltimoBloque,Last20Average,lastblocktime,previous:integer):integer;
function GetLast20Time(LastBlTime:integer):integer;
function GetBlockReward(BlNumber:int64):Int64;
Function GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;Ordenes:array of OrderData;
                        PosPay:Int64;PoSnumber:integer;PosAddresses:array of TArrayPos):boolean;
function LoadBlockDataHeader(BlockNumber:integer):BlockHeaderData;
function GetBlockTrxs(BlockNumber:integer):BlockOrdersArray;
Procedure UndoneLastBlock();
Function GetBlockPoSes(BlockNumber:integer): BlockArraysPos;
Function BlockAge():integer;
Function NextBlockTimeStamp():Int64;
Function RemainingTillNextBlock():String;

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
  PosRequired, PosReward: int64;
  PoSTotalReward : int64 = 0;
  PoSAddressess : array of TArrayPos;
  errored : boolean = false;
Begin
BuildingBlock := Numero;
setmilitime('CrearNuevoBloque',1);
SetCurrentJob('CrearNuevoBloque',true);
if ((numero>0) and (Timestamp < lastblockdata.TimeEnd)) then
   begin
   ConsoleLinesAdd('New block '+IntToStr(numero)+' : Invalid timestamp');
   ConsoleLinesAdd('Blocks can not be added until '+TimestampToDate(IntToStr(GenesysTimeStamp)));
   errored := true;
   end;
if TimeStamp > UTCTime.ToInt64+5 then
   begin
   ConsoleLinesAdd('New block '+IntToStr(numero)+' : Invalid timestamp');
   ConsoleLinesAdd('Timestamp '+IntToStr(TimeStamp)+' is '+IntToStr(TimeStamp-UTCTime.ToInt64)+' seconds in the future');
   errored := true;
   end;
if not errored then
   begin
   if Numero = 0 then StartBlockTime := 1531896783
   else StartBlockTime := LastBlockData.TimeEnd+1;
   FileName := BlockDirectory + IntToStr(Numero)+'.blk';
   SetLength(ListaOrdenes,0);
   SetLength(IgnoredTrxs,0);
   // CREAR COPIA DEL SUMARIO
   trydeletefile(SumarioFilename+'.bak');
   copyfile(SumarioFilename,SumarioFilename+'.bak');

   // PROCESAR LAS TRANSACCIONES EN LISTAORDENES
   EnterCriticalSection(CSPending);
   SetCurrentJob('NewBLOCK_PENDING',true);
   setmilitime('NewBLOCK_PENDING',1);
   for contador := 0 to length(pendingTXs)-1 do
      begin
      // Version 0.2.1Ga1 reverification starts
      if PendingTXs[contador].TimeStamp < LastBlockData.TimeStart then
         continue;
      if TrxExistsInLastBlock(PendingTXs[contador].TrfrID) then
         continue;
      // Version 0.2.1Ga1 reverification ends
      if PendingTXs[contador].TimeStamp+60 > TimeStamp then
         begin
         insert(PendingTXs[contador],IgnoredTrxs,length(IgnoredTrxs));
         continue;
         end;
      if PendingTXs[contador].OrderType='CUSTOM' then
         begin
         minerfee := minerfee+PendingTXs[contador].AmmountFee;
         OperationAddress := GetAddressFromPublicKey(PendingTXs[contador].Sender);
         if not SetCustomAlias(OperationAddress,PendingTXs[contador].Receiver,Numero) then
            begin
            // CRITICAL ERROR: NO SE PUDO ASIGNAR EL ALIAS
            end
         else
            begin
            UpdateSumario(OperationAddress,Restar(PendingTXs[contador].AmmountFee),0,IntToStr(Numero));
            PendingTXs[contador].Block:=numero;
            PendingTXs[contador].Sender:=OperationAddress;
            insert(PendingTXs[contador],ListaOrdenes,length(listaordenes));
            end;
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
   try
      SetLength(PendingTXs,0);
      PendingTXs := copy(IgnoredTrxs,0,length(IgnoredTrxs));
   Except on E:Exception do
      begin
      ToExcLog('Error asigning pending to Ignored');
      end;
   end;
   SetLength(IgnoredTrxs,0);
   setmilitime('NewBLOCK_PENDING',2);
   SetCurrentJob('NewBLOCK_PENDING',false);
   LeaveCriticalSection(CSPending);

   //PoS payment
   SetCurrentJob('NewBLOCK_PoS',true);
   setmilitime('NewBLOCK_PoS',1);
   if numero >= PoSBlockStart then
      begin
      SetLength(PoSAddressess,0);
      PosRequired := (GetSupply(numero)*PosStackCoins) div 10000;
      EnterCriticalSection(CSSumary);
      for contador := 0 to length(ListaSumario)-1 do
         begin
         if listasumario[contador].Balance >= PosRequired then
            begin
            SetLength(PoSAddressess,length(PoSAddressess)+1);
            PoSAddressess[length(PoSAddressess)-1].address:=listasumario[contador].Hash;
            end;
         end;
      ListaSumario[0].LastOP:=numero;  // Actualizar el ultimo bloque añadido al sumario
      LeaveCriticalSection(CSSumary);
      PoScount := length(PoSAddressess);
      PosTotalReward := ((GetBlockReward(Numero)+MinerFee)*GetPoSPercentage(Numero)) div 10000;
      PosReward := PosTotalReward div PoScount;
      PosTotalReward := PoSCount * PosReward;
      //pay POS
      for contador := 0 to length(PoSAddressess)-1 do
         UpdateSumario(PoSAddressess[contador].address,PosReward,0,IntToStr(Numero));
      end;
   setmilitime('NewBLOCK_PoS',2);
   SetCurrentJob('NewBLOCK_PoS',false);

   EnterCriticalSection(CSIdsProcessed);
   Setlength(ArrayOrderIDsProcessed,0);
   LeaveCriticalSection(CSIdsProcessed);

   // Pago del minero
   UpdateSumario(Minero,GetBlockReward(Numero)+MinerFee-PosTotalReward,0,IntToStr(numero));
   // Actualizar el ultimo bloque añadido al sumario
   // Guardar el sumario
   setmilitime('NewBLOCK_SaveSum',1);
   GuardarSumario();
   setmilitime('NewBLOCK_SaveSum',2);
   // Limpiar las pendientes
   for contador := 0 to length(ListaDirecciones)-1 do
      ListaDirecciones[contador].Pending:=0;
   // Definir la cabecera del bloque *****
   SetCurrentJob('NewBLOCK_Headers',true);
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
   //if protocolo = 1 then BlockHeader.Solution:= Solucion
   BlockHeader.Solution:= Solucion+' '+GetNMSData.Diff;
   if numero = 0 then BlockHeader.LastBlockHash:='NOSO GENESYS BLOCK'
   else BlockHeader.LastBlockHash:=MyLastBlockHash;
   BlockHeader.NxtBlkDiff:=GetDiffForNextBlock(numero,BlockHeader.TimeLast20,BlockHeader.TimeTotal,BlockHeader.Difficult);
   BlockHeader.AccountMiner:=Minero;
   BlockHeader.MinerFee:=MinerFee;
   BlockHeader.Reward:=GetBlockReward(Numero);
   SetCurrentJob('NewBLOCK_Headers',false);
   // Fin de la cabecera -----
   // Guardar bloque al disco
   if not GuardarBloque(FileName,BlockHeader,ListaOrdenes,PosReward,PosCount,PoSAddressess) then
      ToExcLog('*****CRITICAL*****'+slinebreak+'Error building block: '+numero.ToString);

   SetNMSData('','','');
   BuildNMSBlock := 0;

   SetLength(ListaOrdenes,0);
   SetLength(PoSAddressess,0);
   // Actualizar informacion
   MyLastBlock := Numero;
   MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
   LastBlockData := LoadBlockDataHeader(MyLastBlock);
   MySumarioHash := HashMD5File(SumarioFilename);
   // Actualizar el arvhivo de cabeceras
   AddBlchHead(Numero,MyLastBlockHash,MySumarioHash);
   MyResumenHash := HashMD5File(ResumenFilename);
   if ( (Numero>0) and (form1.Server.Active) ) then
      begin
      OutgoingMsjsAdd(ProtocolLine(ping));
      end;
   OutText(LangLine(89)+IntToStr(numero),true);  //'Block builded: '

   if Numero > 0 then RebuildMyTrx(Numero);
   CheckForMyPending;
   if DIreccionEsMia(Minero)>-1 then showglobo('Miner','Block found!');
   U_DataPanel := true;
   SetCurrentJob('CrearNuevoBloque',false);
   setmilitime('CrearNuevoBloque',2);
   end;
BuildingBlock := 0;
End;

Function GetDiffHashrate(bestdiff:String):integer;
var
  counter, number:integer;

Begin
repeat
  counter := counter+1;
until bestdiff[counter]<> '0';
Result := (Counter-1)*100;
if bestdiff[counter]='1' then Result := Result+50;
if bestdiff[counter]='2' then Result := Result+25;
if bestdiff[counter]='3' then Result := Result+12;
if bestdiff[counter]='4' then Result := Result+6;
if bestdiff[counter]='5' then Result := Result+3;
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
Function GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;
                        Ordenes:array of OrderData;PosPay:Int64;PoSnumber:integer;PosAddresses:array of TArrayPos):boolean;
var
  MemStr: TMemoryStream;
  NumeroOrdenes : int64;
  counter : integer;
Begin
result := true;
SetCurrentJob('GuardarBloque',true);
setmilitime('GuardarBloque',1);
NumeroOrdenes := Cabezera.TrxTotales;
MemStr := TMemoryStream.Create;
   TRY
   MemStr.Write(Cabezera,Sizeof(Cabezera));
   for counter := 0 to NumeroOrdenes-1 do
      MemStr.Write(Ordenes[counter],Sizeof(Ordenes[Counter]));
   if Cabezera.Number>=PoSBlockStart then
      begin
      MemStr.Write(PosPay,Sizeof(PosPay));
      MemStr.Write(PoSnumber,Sizeof(PoSnumber));
      for counter := 0 to PoSnumber-1 do
         MemStr.Write(PosAddresses[counter],Sizeof(PosAddresses[Counter]));
      end;
   MemStr.SaveToFile(NombreArchivo);
   EXCEPT On E :Exception do
      begin
      ConsoleLinesAdd(LangLine(20));           //Error saving block to disk
      result := false;
      end;
   END{Try};
MemStr.Free;
setmilitime('GuardarBloque',2);
SetCurrentJob('GuardarBloque',false);
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
TRY
   try
   MemStr.LoadFromFile(ArchData);
   MemStr.Position := 0;
   MemStr.Read(Header, SizeOf(Header));
   Except on E:Exception do
      begin
      ConsoleLinesAdd('Error loading Header from block '+IntToStr(BlockNumber)+':'+E.Message);
      end;
   end;
FINALLY
MemStr.Free;
Result := header;
END{Try};
End;

// Devuelve las transacciones del bloque
function GetBlockTrxs(BlockNumber:integer):BlockOrdersArray;
var
  ArrTrxs : BlockOrdersArray;
  MemStr: TMemoryStream;
  Header : BlockHeaderData;
  ArchData : String;
  counter : integer;
  TotalTrxs, totalposes : integer;
  posreward : int64;
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

Function GetBlockPoSes(BlockNumber:integer): BlockArraysPos;
var
  resultado : BlockArraysPos;
  ArrTrxs : BlockOrdersArray;
  ArchData : String;
  MemStr: TMemoryStream;
  Header : BlockHeaderData;
  TotalTrxs, totalposes : integer;
  posreward : int64;
  counter : integer;
Begin
Setlength(resultado,0);
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
   MemStr.Read(posreward, SizeOf(int64));
   MemStr.Read(totalposes, SizeOf(integer));
   SetLength(resultado,totalposes);
   For Counter := 0 to totalposes-1 do
      MemStr.Read(resultado[Counter].address,Sizeof(resultado[Counter]));
   SetLength(resultado,totalposes+1);
   resultado[length(resultado)-1].address := IntToStr(posreward);
   Except on E: Exception do // nothing, the block is not founded
   end;
MemStr.Free;
Result := resultado;
end;

// Deshacer el ultimo bloque
Procedure UndoneLastBlock();
var
  blocknumber : integer;
Begin
blocknumber:= MyLastBlock;
if BlockNumber = 0 then exit;
// recuperar el sumario
Trydeletefile(SumarioFilename);
Trycopyfile(SumarioFilename+'.bak',SumarioFilename);
CargarSumario();
// Actualizar la cartera
UpdateWalletFromSumario();
// actualizar el archivo de cabeceras
DelBlChHeadLast(blocknumber);
// Borrar archivo del ultimo bloque
trydeletefile(BlockDirectory +IntToStr(MyLastBlock)+'.blk');
// Actualizar mi informacion
MyLastBlock := GetMyLastUpdatedBlock;
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
MyResumenHash := HashMD5File(ResumenFilename);
ConsoleLinesAdd('****************************');
ConsoleLinesAdd(LAngLine(90)+IntToStr(blocknumber)); //'Block undone: '
ConsoleLinesAdd('****************************');
Tolog('Block Undone: '+IntToStr(blocknumber));
U_DataPanel := true;
End;

Function BlockAge():integer;
Begin
Result := (UTCtime.ToInt64-LastBlockData.TimeEnd+1) mod 600;
End;

Function NextBlockTimeStamp():Int64;
var
  currTime : int64;
  Remains : int64;
Begin
CurrTime := UTCTime.ToInt64;
Remains := 600-(CurrTime mod 600);
Result := CurrTime+Remains;
End;

Function RemainingTillNextBlock():String;
Begin
if BuildNMSBlock = 0 then Result := 'Unknown'
else result := IntToStr(BuildNMSBlock-UTCTime.ToInt64);
End;

END. // END UNIT

