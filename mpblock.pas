unit mpBlock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm, fileutil, mpcoin, dialogs, math,
  nosotime, mpMN, nosodebug,nosogeneral,nosocrypto;

Procedure CrearBloqueCero();
Procedure BuildNewBlock(Numero,TimeStamp: Int64; TargetHash, Minero, Solucion:String);
Function GetDiffHashrate(bestdiff:String):integer;
Function BestHashReadeable(BestDiff:String):string;
function GetDiffForNextBlock(UltimoBloque,Last20Average,lastblocktime,previous:integer):integer;
function GetLast20Time(LastBlTime:integer):integer;
function GetBlockReward(BlNumber:int64):Int64;
Function GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;Ordenes:array of OrderData;
                        PosPay:Int64;PoSnumber:integer;PosAddresses:array of TArrayPos;
                        MNsPay:int64;MNsNumber:Integer;MNsAddresses:array of TArrayPos):boolean;
function LoadBlockDataHeader(BlockNumber:integer):BlockHeaderData;
function GetBlockTrxs(BlockNumber:integer):BlockOrdersArray;
Procedure UndoneLastBlock();
Function GetBlockPoSes(BlockNumber:integer): BlockArraysPos;
Function GetBlockMNs(BlockNumber:integer): BlockArraysPos;
Function GEtNSLBlkOrdInfo(LineText:String):String;

implementation

Uses
  mpDisk,mpProtocol, mpGui, mpparser, mpRed;

Function CreateDevPaymentOrder(number:integer;timestamp,amount:int64):OrderData;
Begin
Result := Default(OrderData);

Result.Block      := number;
//Result.OrderID    :='';
Result.OrderLines := 1;
Result.OrderType  := 'PROJCT';
Result.TimeStamp  := timestamp-1;
Result.Reference  := 'null';
Result.TrxLine    :=1;
Result.sender     := 'COINBASE';
Result.Address    := 'COINBASE';
Result.Receiver   := 'NpryectdevepmentfundsGE';
Result.AmmountFee := 0;
Result.AmmountTrf := amount;
Result.Signature  := 'COINBASE';
Result.TrfrID     := GetTransferHash(Result.TimeStamp.ToString+'COINBASE'+'NpryectdevepmentfundsGE'+IntToStr(amount)+IntToStr(MyLastblock));
Result.OrderID    := '1'+Result.TrfrID;
End;

// Build the default block 0
Procedure CrearBloqueCero();
Begin
BuildNewBlock(0,GenesysTimeStamp,'',adminhash,'');
if G_Launching then AddLineToDebugLog('console','Block GENESYS (0) created.'); //'Block 0 created.'
if G_Launching then OutText('✓ Block 0 created',false,1);
End;

// Crea un bloque nuevo con la informacion suministrada
Procedure BuildNewBlock(Numero,TimeStamp: int64; TargetHash, Minero, Solucion:String);
var
  BlockHeader : BlockHeaderData;
  StartBlockTime : int64 = 0;
  MinerFee : int64 = 0;
  ListaOrdenes : Array of OrderData;
  IgnoredTrxs  : Array of OrderData;
  Filename : String;
  Contador : integer = 0;
  OperationAddress : string = '';
  errored : boolean = false;
  PoWTotalReward : int64;
  ArrayLastBlockTrxs : BlockOrdersArray;
  ExistsInLastBlock : boolean;
  Count2 : integer;

  DevsTotalReward : int64 = 0;
  DevOrder        : OrderData;

  PoScount : integer = 0;
  PosRequired, PosReward: int64;
  PoSTotalReward : int64 = 0;
  PoSAddressess : array of TArrayPos;


  MNsCount       : integer;
  MNsReward      : int64;
  MNsTotalReward : int64 =0;
  MNsAddressess : array of TArrayPos;
  ThisParam : String;

  MNsFileText   : String = '';
  GVTsTransfered : integer = 0;

  ArrayPays : array of TBlockSumTrfr;

  Function AddArrayPay(address:string;amount,score:int64):boolean;
  var
    counter : integer;
    added : boolean = false;
  Begin
  for counter := 0 to length(ArrayPays)-1 do
     begin
     if ArrayPays[counter].address = address then
        begin
        ArrayPays[counter].amount:=ArrayPays[counter].amount+amount;
        ArrayPays[counter].score:=ArrayPays[counter].score+score;
        added := true;
        break;
        end;
     end;
  if not added then
     begin
     SetLEngth(ArrayPays,length(ArrayPays)+1);
     ArrayPays[Length(ArrayPays)-1].address:=address;
     ArrayPays[Length(ArrayPays)-1].amount:=amount;
     ArrayPays[Length(ArrayPays)-1].score:=score;
     end;
  End;

  Procedure ProcessArrPays(block:string);
  var
    counter : integer;
  Begin
  for counter := 0 to length(ArrayPays)-1 do
     begin
     UpdateSumario(ArrayPays[counter].address,ArrayPays[counter].amount,ArrayPays[counter].score,block);
     end;
  End;

Begin
BuildingBlock := Numero;
BeginPerformance('BuildNewBlock');
if ((numero>0) and (Timestamp < lastblockdata.TimeEnd)) then
   begin
   AddLineToDebugLog('console','New block '+IntToStr(numero)+' : Invalid timestamp');
   AddLineToDebugLog('console','Blocks can not be added until '+TimestampToDate(GenesysTimeStamp));
   errored := true;
   end;
if TimeStamp > UTCTime+5 then
   begin
   AddLineToDebugLog('console','New block '+IntToStr(numero)+' : Invalid timestamp');
   AddLineToDebugLog('console','Timestamp '+IntToStr(TimeStamp)+' is '+IntToStr(TimeStamp-UTCTime)+' seconds in the future');
   errored := true;
   end;
if not errored then
   begin
   if Numero = 0 then StartBlockTime := 1531896783
   else StartBlockTime := LastBlockData.TimeEnd+1;
   FileName := BlockDirectory + IntToStr(Numero)+'.blk';
   SetLength(ListaOrdenes,0);
   SetLength(IgnoredTrxs,0);
   SetLength(ArrayPays,0);
   // Generate summary copy
   EnterCriticalSection(CSSumary);
   trydeletefile(SumarioFilename+'.bak');
   copyfile(SumarioFilename,SumarioFilename+'.bak');
   LeaveCriticalSection(CSSumary);

   // Generate GVT copy
   EnterCriticalSection(CSGVTsArray);
   trydeletefile(GVTsFilename+'.bak');
   copyfile(GVTsFilename,GVTsFilename+'.bak');
   LeaveCriticalSection(CSGVTsArray);

   // Processs pending orders
   EnterCriticalSection(CSPending);
   BeginPerformance('NewBLOCK_PENDING');
   ArrayLastBlockTrxs := Default(BlockOrdersArray);
   ArrayLastBlockTrxs := GetBlockTrxs(MyLastBlock);
   for contador := 0 to length(pendingTXs)-1 do
      begin
      // Version 0.2.1Ga1 reverification starts
      if PendingTXs[contador].TimeStamp < LastBlockData.TimeStart then
         continue;
      //{
      ExistsInLastBlock := false;
      for count2 := 0 to length(ArrayLastBlockTrxs)-1 do
         begin
         if ArrayLastBlockTrxs[count2].TrfrID = PendingTXs[contador].TrfrID then
            begin
            ExistsInLastBlock := true ;
            break;
            end;
         end;
      if ExistsInLastBlock then continue;
      //}
      {
      if TrxExistsInLastBlock(PendingTXs[contador].TrfrID) then
         continue;
      }
      // Version 0.2.1Ga1 reverification ends
      if PendingTXs[contador].TimeStamp+60 > TimeStamp then
         begin
         if PendingTXs[contador].TimeStamp < TimeStamp+600 then
            insert(PendingTXs[contador],IgnoredTrxs,length(IgnoredTrxs));
         continue;
         end;
      if PendingTXs[contador].OrderType='CUSTOM' then
         begin
         minerfee := minerfee+PendingTXs[contador].AmmountFee;
         OperationAddress := GetAddressFromPublicKey(PendingTXs[contador].sender);
         if not SetCustomAlias(OperationAddress,PendingTXs[contador].Receiver,Numero) then
            begin
            // CRITICAL ERROR: NO SE PUDO ASIGNAR EL ALIAS
            end
         else
            begin
            UpdateSumario(OperationAddress,Restar(PendingTXs[contador].AmmountFee),0,IntToStr(Numero));
            PendingTXs[contador].Block:=numero;
            PendingTXs[contador].sender:=OperationAddress;
            insert(PendingTXs[contador],ListaOrdenes,length(listaordenes));
            end;
         end;
      if PendingTXs[contador].OrderType='TRFR' then
         begin
         //OperationAddress := GetAddressFromPublicKey(PendingTXs[contador].sender);
         OperationAddress := PendingTXs[contador].Address;
         //OperationAddress := GetAddressFromPubKey_New(PendingTXs[contador].sender);
         // nueva adicion para que no incluya las transacciones invalidas
         if GetAddressBalance(OperationAddress) < (PendingTXs[contador].AmmountFee+PendingTXs[contador].AmmountTrf) then continue;
         minerfee := minerfee+PendingTXs[contador].AmmountFee;
         // restar transferencia y comision de la direccion que envia
         AddArrayPay(OperationAddress,Restar(PendingTXs[contador].AmmountFee+PendingTXs[contador].AmmountTrf),0);
            //UpdateSumario(OperationAddress,Restar(PendingTXs[contador].AmmountFee+PendingTXs[contador].AmmountTrf),0,IntToStr(Numero));
         // sumar transferencia al receptor
         AddArrayPay(PendingTXs[contador].Receiver,PendingTXs[contador].AmmountTrf,0);
            //UpdateSumario(PendingTXs[contador].Receiver,PendingTXs[contador].AmmountTrf,0,IntToStr(Numero));
         PendingTXs[contador].Block:=numero;
         PendingTXs[contador].sender:=OperationAddress;
         insert(PendingTXs[contador],ListaOrdenes,length(listaordenes));
         end;
      if ( (PendingTXs[contador].OrderType='SNDGVT') and ( PendingTXs[contador].sender = AdminPubKey) ) then
         begin
         OperationAddress := GetAddressFromPublicKey(PendingTXs[contador].sender);
         if GetAddressBalance(OperationAddress) < PendingTXs[contador].AmmountFee then continue;
         minerfee := minerfee+PendingTXs[contador].AmmountFee;
         if ChangeGVTOwner(StrToIntDef(PendingTXs[contador].Reference,100),OperationAddress,PendingTXs[contador].Receiver)>0 then
            begin
            // Change GVT ownerfailed
            end
         else
            begin
            Inc(GVTsTransfered);
            UpdateSumario(OperationAddress,Restar(PendingTXs[contador].AmmountFee),0,IntToStr(Numero));
            PendingTXs[contador].Block:=numero;
            PendingTXs[contador].sender:=OperationAddress;
            insert(PendingTXs[contador],ListaOrdenes,length(listaordenes));
            end;
         end;
      end;
   // Project funds payment
   if numero >= PoSBlockEnd then
      begin
      DevsTotalReward := ((GetBlockReward(Numero)+MinerFee)*GetDevPercentage(Numero)) div 10000;
      DevORder := CreateDevPaymentOrder(numero,TimeStamp,DevsTotalReward);
      UpdateSumario('NpryectdevepmentfundsGE',DevsTotalReward,0,IntToStr(Numero));
      insert(DevORder,ListaOrdenes,length(listaordenes));
      end;
   ProcessArrPays(IntToStr(Numero));
   if GVTsTransfered>0 then
      begin
      SaveGVTs;
      UpdateMyGVTsList;
      end;
   TRY
      SetLength(PendingTXs,0);
      PendingTXs := copy(IgnoredTrxs,0,length(IgnoredTrxs));
   EXCEPT on E:Exception do
      begin
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error asigning pending to Ignored');
      end;
   END; {TRY}
   SetLength(IgnoredTrxs,0);
   EndPerformance('NewBLOCK_PENDING');
   LeaveCriticalSection(CSPending);

   //PoS payment
   BeginPerformance('NewBLOCK_PoS');
   if numero >= PoSBlockStart then
      begin
      SetLength(PoSAddressess,0);
      PoSReward := 0;
      PosCount := 0;
      PosTotalReward := 0;
      if numero < PosBlockEnd then
         begin
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
      end;
   EndPerformance('NewBLOCK_PoS');
   // Masternodes processing
   BeginPerformance('NewBLOCK_MNs');
   CreditMNVerifications();
   MNsFileText := GetMNsAddresses();
   SaveMNsFile(MNsFileText);
   ClearMNsChecks();
   ClearMNsList();
   if numero >= MNBlockStart then
      begin
      SetLength(MNsAddressess,0);
      Contador := 1;
      Repeat
         begin
         ThisParam := Parameter(MNsFileText,contador);
         if ThisParam<> '' then
            begin
            ThisParam := StringReplace(ThisParam,':',' ',[rfReplaceAll]);
            ThisParam := Parameter(ThisParam,1);
            SetLength(MNsAddressess,length(MNsAddressess)+1);
            MNsAddressess[length(MNsAddressess)-1].address:=ThisParam;
            end;
         Inc(contador);
         end;
      until ThisParam = '';

      MNsCount := Length(MNsAddressess);
      MNsTotalReward := ((GetBlockReward(Numero)+MinerFee)*GetMNsPercentage(Numero)) div 10000;
      if MNsCount>0 then MNsReward := MNsTotalReward div MNsCount
      else MNsReward := 0;
      MNsTotalReward := MNsCount * MNsReward;
      For contador := 0 to length(MNsAddressess)-1 do
         begin
         UpdateSumario(MNsAddressess[contador].address,MNsReward,0,IntToStr(Numero));
         end;
      EndPerformance('NewBLOCK_MNs');
      end;// End of MNS payment procecessing

   // ***END MASTERNODES PROCESSING***

   // Reset Order hashes received
   ClearReceivedOrdersIDs;

   // Pago del minero
   PoWTotalReward := (GetBlockReward(Numero)+MinerFee)-PosTotalReward-MNsTotalReward-DevsTotalReward;
   UpdateSumario(Minero,PoWTotalReward,0,IntToStr(numero));
   // Actualizar el ultimo bloque añadido al sumario
   // Guardar el sumario
   BeginPerformance('NewBLOCK_SaveSum');
   GuardarSumario();
   EndPerformance('NewBLOCK_SaveSum');
   // Limpiar las pendientes
   for contador := 0 to length(ListaDirecciones)-1 do
      ListaDirecciones[contador].Pending:=0;
   // Definir la cabecera del bloque *****
   BlockHeader := Default(BlockHeaderData);
   BlockHeader.Number := Numero;
   BlockHeader.TimeStart:= StartBlockTime;
   BlockHeader.TimeEnd:= timeStamp;
   BlockHeader.TimeTotal:= TimeStamp - StartBlockTime;
   BlockHeader.TimeLast20:=0;//GetLast20Time(BlockHeader.TimeTotal);
   BlockHeader.TrxTotales:=length(ListaOrdenes);
   if numero = 0 then BlockHeader.Difficult:= InitialBlockDiff
   else if ( (numero>0) and (numero<53000) ) then BlockHeader.Difficult:= 0
   else BlockHeader.Difficult := PoSCount;
   BlockHeader.TargetHash:=TargetHash;
   //if protocolo = 1 then BlockHeader.Solution:= Solucion
   BlockHeader.Solution:= Solucion+' '+GetNMSData.Diff+' '+PoWTotalReward.ToString+' '+MNsTotalReward.ToString+' '+PosTotalReward.ToString;
   if numero = 0 then BlockHeader.LastBlockHash:='NOSO GENESYS BLOCK'
   else BlockHeader.LastBlockHash:=MyLastBlockHash;
   if numero<53000 then BlockHeader.NxtBlkDiff:= 0{MNsReward}//GetDiffForNextBlock(numero,BlockHeader.TimeLast20,BlockHeader.TimeTotal,BlockHeader.Difficult);
   else BlockHeader.NxtBlkDiff := MNsCount;
   BlockHeader.AccountMiner:=Minero;
   BlockHeader.MinerFee:=MinerFee;
   BlockHeader.Reward:=GetBlockReward(Numero);
   // Fin de la cabecera -----
   // Guardar bloque al disco
   if not GuardarBloque(FileName,BlockHeader,ListaOrdenes,PosReward,PosCount,PoSAddressess,
                        MNsReward, MNsCount,MNsAddressess) then
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'*****CRITICAL*****'+slinebreak+'Error building block: '+numero.ToString);

   SetNMSData('','','','','','');
   BuildNMSBlock := 0;

   SetLength(ListaOrdenes,0);
   SetLength(PoSAddressess,0);
   // Actualizar informacion
   MyLastBlock := Numero;
   MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
   LastBlockData := LoadBlockDataHeader(MyLastBlock);
   MySumarioHash := HashMD5File(SumarioFilename);
   MyMNsHash     := HashMD5File(MasterNodesFilename);
   // Actualizar el arvhivo de cabeceras
   AddBlchHead(Numero,MyLastBlockHash,MySumarioHash);
   MyResumenHash := HashMD5File(ResumenFilename);
   if ( (Numero>0) and (form1.Server.Active) ) then
      begin
      OutgoingMsjsAdd(ProtocolLine(ping));
      end;
   CheckForMyPending;
   if DIreccionEsMia(Minero)>-1 then showglobo('Miner','Block found!');
   U_DataPanel := true;
   OutText(format('Block built: %d (%d ms)',[numero,EndPerformance('BuildNewBlock')]),true);  //'Block builded: '
   //EndPerformance('BuildNewBlock');
   end
else
   begin
   OutText('Failed to build the block',true);
   end;
BuildingBlock := 0;
End;

Function GetDiffHashrate(bestdiff:String):integer;
var
  counter :integer= 0;
Begin
repeat
  counter := counter+1;
until bestdiff[counter]<> '0';
Result := (Counter-1)*100;
if bestdiff[counter]='1' then Result := Result+50;
if bestdiff[counter]='2' then Result := Result+25;
if bestdiff[counter]='3' then Result := Result+12;
if bestdiff[counter]='4' then Result := Result+6;
//if bestdiff[counter]='5' then Result := Result+3;
End;

Function BestHashReadeable(BestDiff:String):string;
var
  counter :integer = 0;
Begin
if bestdiff = '' then BestDiff := 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
repeat
  counter := counter+1;
until bestdiff[counter]<> '0';
Result := (Counter-1).ToString+'.';
if counter<length(BestDiff) then Result := Result+bestdiff[counter];
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
  NumHalvings : int64;
Begin
if BlNumber = 0 then result := PremineAmount
else if ((BlNumber > 0) and (blnumber < BlockHalvingInterval*(HalvingSteps+1))) then
   begin
   numHalvings := BlNumber div BlockHalvingInterval;
   result := InitialReward div ( 2**NumHalvings );
   end
else result := 0;
End;

// Guarda el archivo de bloque en disco
Function GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;
                        Ordenes:array of OrderData;
                        PosPay:Int64;PoSnumber:integer;PosAddresses:array of TArrayPos;
                        MNsPay:int64;MNsNumber:Integer;MNsAddresses:array of TArrayPos):boolean;
var
  MemStr: TMemoryStream;
  NumeroOrdenes : int64;
  counter : integer;
Begin
result := true;
BeginPerformance('GuardarBloque');
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
   if Cabezera.Number>=MNBlockStart then
      begin
      MemStr.Write(MNsPay,Sizeof(MNsPay));
      MemStr.Write(MNsnumber,Sizeof(MNsnumber));
      for counter := 0 to MNsNumber-1 do
         begin
         MemStr.Write(MNsAddresses[counter],Sizeof(MNsAddresses[Counter]));
         end;
      end;
   MemStr.SaveToFile(NombreArchivo);
   EXCEPT On E :Exception do
      begin
      AddLineToDebugLog('console','Error saving block to disk: '+E.Message);
      result := false;
      end;
   END{Try};
MemStr.Free;
EndPerformance('GuardarBloque');
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
   MemStr.LoadFromFile(ArchData);
   MemStr.Position := 0;
   MemStr.Read(Header, SizeOf(Header));
   EXCEPT ON E:Exception do
      begin
      AddLineToDebugLog('console','Error loading Header from block '+IntToStr(BlockNumber)+':'+E.Message);
      end;
   END{Try};
MemStr.Free;
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
   Except on E: Exception do // nothing, the block is not found
   end;
MemStr.Free;
Result := resultado;
end;

Function GetBlockMNs(BlockNumber:integer): BlockArraysPos;
var
  resultado : BlockArraysPos;
  ArrayPos    : BlockArraysPos;
  ArrTrxs : BlockOrdersArray;
  ArchData : String;
  MemStr: TMemoryStream;
  Header : BlockHeaderData;
  TotalTrxs, totalposes, totalMNs : integer;
  posreward,MNreward : int64;
  counter : integer;
Begin
Setlength(resultado,0);
Setlength(ArrayPos,0);
if blocknumber <MNBlockStart then
   begin
   result := resultado;
   exit;
   end;
ArchData := BlockDirectory+IntToStr(BlockNumber)+'.blk';
MemStr := TMemoryStream.Create;
   TRY
   // HEADERS
   MemStr.LoadFromFile(ArchData);
   MemStr.Position := 0;
   MemStr.Read(Header, SizeOf(Header));
   // TRXS LIST
   TotalTrxs := header.TrxTotales;
   SetLength(ArrTrxs,TotalTrxs);
   For Counter := 0 to TotalTrxs-1 do
      MemStr.Read(ArrTrxs[Counter],Sizeof(ArrTrxs[Counter])); // read each record
   // POS INFO
   MemStr.Read(posreward, SizeOf(int64));
   MemStr.Read(totalposes, SizeOf(integer));
   SetLength(ArrayPos,totalposes);
   For Counter := 0 to totalposes-1 do
      MemStr.Read(ArrayPos[Counter].address,Sizeof(ArrayPos[Counter]));
   // MNS INFO
   MemStr.Read(MNReward, SizeOf(MNReward));
   MemStr.Read(totalMNs, SizeOf(totalMNs));
   SetLength(resultado,totalMNs);
   For Counter := 0 to totalMNs-1 do
      begin
      MemStr.Read(resultado[Counter].address,Sizeof(resultado[Counter]));
      end;
   SetLength(resultado,totalMNs+1);
   resultado[length(resultado)-1].address := IntToStr(MNReward);
   EXCEPT on E: Exception do // nothing, the block is not founded
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'EXCEPTION on MNs file data:'+E.Message)
   END; {TRY}
MemStr.Free;
Result := resultado;
end;

// Deshacer el ultimo bloque
Procedure UndoneLastBlock();
var
  blocknumber : integer;
Begin
if BlockUndoneTime+30>UTCTime then exit;
blocknumber:= MyLastBlock;
if BlockNumber = 0 then exit;
if MyConStatus = 3 then
   begin
   MyConStatus := 2;
   //if Form1.Server.Active then Form1.Server.Active := false;
   ClearMNsChecks();
   ClearMNsList();
   SetNMSData('','','','','','');
   ClearAllPending;
   ClearReceivedOrdersIDs;
   end;
// recover summary
EnterCriticalSection(CSSumary);
Trydeletefile(SumarioFilename);
Trycopyfile(SumarioFilename+'.bak',SumarioFilename);
LeaveCriticalSection(CSSumary);
LoadSumaryFromFile();
// recover GVTs file
EnterCriticalSection(CSGVTsArray);
trydeletefile(GVTsFilename);
copyfile(GVTsFilename+'.bak',GVTsFilename);
LeaveCriticalSection(CSGVTsArray);
GetGVTsFileData();
UpdateMyGVTsList;

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
AddLineToDebugLog('console','****************************');
AddLineToDebugLog('console','Block undone: '+IntToStr(blocknumber)); //'Block undone: '
AddLineToDebugLog('console','****************************');
AddLineToDebugLog('events',TimeToStr(now)+'Block Undone: '+IntToStr(blocknumber));
U_DataPanel := true;
BlockUndoneTime := UTCTime;
End;

Function GEtNSLBlkOrdInfo(LineText:String):String;
var
  ParamBlock  : String;
  BlkNumber   : integer;
  OrdersArray : BlockOrdersArray;
  Cont     : integer;
  ThisOrder   : string  = '';
Begin
Result := 'NSLBLKORD ';
ParamBlock := UpperCase(Parameter(LineText,1));
If paramblock = 'LAST' then BlkNumber := MyLastBlock
else BlkNumber := StrToIntDef(ParamBlock,-1);
if ( (BlkNumber<0) or (BlkNumber<MyLastBlock-4000) or (BlkNumber>MyLastBlock) ) then Result := Result+'ERROR'
else
   begin
   Result := Result+BlkNumber.ToString+' ';
   OrdersArray := Default(BlockOrdersArray);
   OrdersArray := GetBlockTrxs(BlkNumber);
   if Length(OrdersArray)>0 then
      begin
      For Cont := 0 to LEngth(OrdersArray)-1 do
         begin
         if OrdersArray[cont].OrderType='TRFR' then
            begin
            ThisOrder := ThisOrder+OrdersArray[Cont].sender+':'+OrdersArray[Cont].Receiver+':'+OrdersArray[Cont].AmmountTrf.ToString+':'+
                         OrdersArray[Cont].Reference+':'+OrdersArray[Cont].OrderID+' ';
            end;
         end;
      end;
   Result := Result+ThisOrder;
   Result := Trim(Result)
   end;
End;

END. // END UNIT

