unit mpBlock;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,MasterPaskalForm, fileutil, mpcoin, dialogs, math,
  nosotime, nosodebug,nosogeneral,nosocrypto, nosounit, strutils,
  nosopsos,nosowallcon,nosoheaders, nosoblock,nosonosocfg,nosonetwork,nosogvts,
  nosomasternodes;

Procedure CrearBloqueCero();
Procedure BuildNewBlock(Numero,TimeStamp: Int64; TargetHash, Minero, Solucion:String);
//Function GetDiffHashrate(bestdiff:String):integer;
//Function BestHashReadeable(BestDiff:String):string;
//function GetDiffForNextBlock(UltimoBloque,Last20Average,lastblocktime,previous:integer):integer;
//function GetLast20Time(LastBlTime:integer):integer;
function GetBlockReward(BlNumber:int64):Int64;
Function GuardarBloque(NombreArchivo:string;Cabezera:BlockHeaderData;Ordenes:array of TOrderData;
                        PosPay:Int64;PoSnumber:integer;PosAddresses:array of TArrayPos;
                        MNsPay:int64;MNsNumber:Integer;MNsAddresses:array of TArrayPos):boolean;
{function LoadBlockDataHeader(BlockNumber:integer):BlockHeaderData;}
{function GetBlockTrxs(BlockNumber:integer):TBlockOrdersArray;}
Procedure UndoneLastBlock();
Function GetBlockPoSes(BlockNumber:integer): BlockArraysPos;
Function GetBlockMNs(BlockNumber:integer): BlockArraysPos;
Function RemoveBlocks(UpToBlock:int64):integer;
Function GEtNSLBlkOrdInfo(LineText:String):String;

implementation

Uses
  mpDisk,mpProtocol, mpGui, mpparser, mpRed;

Function CreateDevPaymentOrder(number:integer;timestamp,amount:int64):TOrderData;
Begin
Result := Default(TOrderData);
Result.Block      := number;
//Result.OrderID    :='';
Result.OrderLines := 1;
Result.OrderType  := 'PROJCT';
Result.TimeStamp  := timestamp-1;
Result.Reference  := 'null';
Result.TrxLine    := 1;
Result.sender     := 'COINBASE';
Result.Address    := 'COINBASE';
Result.Receiver   := 'NpryectdevepmentfundsGE';
Result.AmmountFee := 0;
Result.AmmountTrf := amount;
Result.Signature  := 'COINBASE';
Result.TrfrID     := GetTransferHash(Result.TimeStamp.ToString+'COINBASE'+'NpryectdevepmentfundsGE'+IntToStr(amount)+IntToStr(MyLastblock));
Result.OrderID    := {GetOrderHash(}'1'+Result.TrfrID{)};
End;

Function CreateNosoPayOrder(number:integer;AddSend,AddReceive:string;timestamp,amount:int64):TOrderData;
Begin
Result := Default(TOrderData);
Result.Block      := number;
Result.OrderLines := 1;
Result.OrderType  := 'TRFR';
Result.TimeStamp  := timestamp-1;
Result.Reference  := 'null';
Result.TrxLine    := 1;
Result.sender     := AddSend;
Result.Address    := AddSend;
Result.Receiver   := AddReceive;
Result.AmmountFee := 0;
Result.AmmountTrf := amount;
Result.Signature  := 'Directive';
Result.TrfrID     := GetTransferHash(Result.TimeStamp.ToString+'TRFR'+AddSend+IntToStr(amount)+IntToStr(MyLastblock));
Result.OrderID    := GetOrderHash('1'+Result.TrfrID);
End;

// Build the default block 0
Procedure CrearBloqueCero();
Begin
BuildNewBlock(0,GenesysTimeStamp,'',adminhash,'');
if G_Launching then ToLog('console','Block GENESYS (0) created.'); //'Block 0 created.'
if G_Launching then OutText('✓ Block 0 created',false,1);
End;

// Crea un bloque nuevo con la informacion suministrada
Procedure BuildNewBlock(Numero,TimeStamp: int64; TargetHash, Minero, Solucion:String);
var
  BlockHeader : BlockHeaderData;
  StartBlockTime : int64 = 0;
  MinerFee : int64 = 0;
  ListaOrdenes : Array of TOrderData;
  IgnoredTrxs  : Array of TOrderData;
  Filename : String;
  Contador : integer = 0;
  OperationAddress : string = '';
  errored : boolean = false;
  PoWTotalReward : int64;
  ArrayLastBlockTrxs : TBlockOrdersArray;
  ExistsInLastBlock : boolean;
  Count2 : integer;
  NewMNs, ExpiredMNs : integer;

  DevsTotalReward : int64 = 0;
  DevOrder        : TOrderData;

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
  NosoPayData    : string = '';
    NPDOrder     : TOrderData;
    NPDBlock     : integer;
    NPDSource    : string;
    NPDTarget    : string;
    NPDAmount    : int64;


Begin
if GetCFGDataStr(0) = 'STOP' then
   begin
   ClearAllPending;
   exit;
   end;
if AnsiContainsStr(GetCFGDataStr(0),'EMPTY') then ClearAllPending;
BuildingBlock := Numero;
BeginPerformance('BuildNewBlock');
if ((numero>0) and (Timestamp < lastblockdata.TimeEnd)) then
   begin
   ToLog('console','New block '+IntToStr(numero)+' : Invalid timestamp');
   ToLog('console','Blocks can not be added until '+TimestampToDate(GenesysTimeStamp));
   errored := true;
   end;
if TimeStamp > UTCTime+5 then
   begin
   ToLog('console','New block '+IntToStr(numero)+' : Invalid timestamp');
   ToLog('console','Timestamp '+IntToStr(TimeStamp)+' is '+IntToStr(TimeStamp-UTCTime)+' seconds in the future');
   errored := true;
   end;
if not errored then
   begin
   if Numero = 0 then StartBlockTime := 1531896783
   else StartBlockTime := LastBlockData.TimeEnd+1;
   FileName := BlockDirectory + IntToStr(Numero)+'.blk';
   SetLength(ListaOrdenes,0);
   SetLength(IgnoredTrxs,0);
   // Generate summary copy
   CreateSumaryBackup();

   // Generate GVT copy
   EnterCriticalSection(CSGVTsArray);
   trydeletefile(GVTsFilename+'.bak');
   copyfile(GVTsFilename,GVTsFilename+'.bak');
   LeaveCriticalSection(CSGVTsArray);

   // Processs pending orders
   EnterCriticalSection(CSPending);
   BeginPerformance('NewBLOCK_PENDING');
   ArrayLastBlockTrxs := Default(TBlockOrdersArray);
   ArrayLastBlockTrxs := GetBlockTrxs(MyLastBlock);
   ResetBlockRecords;
   for contador := 0 to length(ArrayPoolTXs)-1 do
      begin
      // Version 0.2.1Ga1 reverification starts
      if ArrayPoolTXs[contador].TimeStamp < LastBlockData.TimeStart then
         continue;
      //{
      ExistsInLastBlock := false;
      for count2 := 0 to length(ArrayLastBlockTrxs)-1 do
         begin
         if ArrayLastBlockTrxs[count2].TrfrID = ArrayPoolTXs[contador].TrfrID then
            begin
            ExistsInLastBlock := true ;
            break;
            end;
         end;
      if ExistsInLastBlock then continue;
      if ArrayPoolTXs[contador].TimeStamp+60 > TimeStamp then
         begin
         if ArrayPoolTXs[contador].TimeStamp < TimeStamp+600 then
            insert(ArrayPoolTXs[contador],IgnoredTrxs,length(IgnoredTrxs));
         continue;
         end;
      if ArrayPoolTXs[contador].OrderType='CUSTOM' then
         begin
         OperationAddress := GetAddressFromPublicKey(ArrayPoolTXs[contador].sender);
         if IsCustomizacionValid(OperationAddress,ArrayPoolTXs[contador].Receiver,numero) then
            begin
            minerfee := minerfee+ArrayPoolTXs[contador].AmmountFee;
            ArrayPoolTXs[contador].Block:=numero;
            ArrayPoolTXs[contador].sender:=OperationAddress;
            insert(ArrayPoolTXs[contador],ListaOrdenes,length(listaordenes));
            end;
         end;
      if ArrayPoolTXs[contador].OrderType='TRFR' then
         begin
         OperationAddress := ArrayPoolTXs[contador].Address;
         if SummaryValidPay(OperationAddress,ArrayPoolTXs[contador].AmmountFee+ArrayPoolTXs[contador].AmmountTrf,numero) then
            begin
            minerfee := minerfee+ArrayPoolTXs[contador].AmmountFee;
            CreditTo(ArrayPoolTXs[contador].Receiver,ArrayPoolTXs[contador].AmmountTrf,numero);
            ArrayPoolTXs[contador].Block:=numero;
            ArrayPoolTXs[contador].sender:=OperationAddress;
            insert(ArrayPoolTXs[contador],ListaOrdenes,length(listaordenes));
            end;
         end;
      if ( (ArrayPoolTXs[contador].OrderType='SNDGVT') and ( ArrayPoolTXs[contador].sender = AdminPubKey) ) then
         begin
         OperationAddress := GetAddressFromPublicKey(ArrayPoolTXs[contador].sender);
         if GetAddressBalanceIndexed(OperationAddress)< ArrayPoolTXs[contador].AmmountFee then continue;
         if ChangeGVTOwner(StrToIntDef(ArrayPoolTXs[contador].Reference,100),OperationAddress,ArrayPoolTXs[contador].Receiver)=0 then
            begin
            minerfee := minerfee+ArrayPoolTXs[contador].AmmountFee;
            Inc(GVTsTransfered);
            SummaryValidPay(OperationAddress,ArrayPoolTXs[contador].AmmountFee,numero);
            ArrayPoolTXs[contador].Block:=numero;
            ArrayPoolTXs[contador].sender:=OperationAddress;
            insert(ArrayPoolTXs[contador],ListaOrdenes,length(listaordenes));
            end;
         end;
      end;
   // Proyect payments
   if GetCFGDataStr(6) <>'' then
      begin
      NosoPayData := GetCFGDataStr(6);
      NosoPayData :=StringReplace(NosoPayData,':','',[rfReplaceAll, rfIgnoreCase]);
      NosoPayData :=StringReplace(NosoPayData,',',' ',[rfReplaceAll, rfIgnoreCase]);
      NPDBlock := StrToIntdef(Parameter(NosoPayData,0),0);
      if NPDBlock = numero then
         begin
         NPDSource := Parameter(NosoPayData,1);
         NPDTarget := Parameter(NosoPayData,2);
         if ( (IsValidHashAddress(NPDTarget)) and (IsValidHashAddress(NPDSource)) ) then
            begin
            NPDAmount := StrToInt64def(Parameter(NosoPayData,3),0);
            if NPDAmount > 0 then
               begin
               if SummaryValidPay(NPDSource,NPDamount,NPDBlock) then
                  begin
                  CreditTo(NPDTarget,NPDAmount,NPDBlock);
                  NPDOrder := CreateNosoPayOrder(NPDBlock,NPDSource,NPDTarget,TimeStamp,NPDAmount);
                  insert(NPDOrder,ListaOrdenes,length(listaordenes));
                  RemoveCFGData(GetCFGDataStr(6),6);
                  end;
               end;
            end;
         end;
      end;
   // Project funds payment
   if numero >= PoSBlockEnd then
      begin
      DevsTotalReward := ((GetBlockReward(Numero)+MinerFee)*GetDevPercentage(Numero)) div 10000;
      DevORder := CreateDevPaymentOrder(numero,TimeStamp,DevsTotalReward);
      CreditTo('NpryectdevepmentfundsGE',DevsTotalReward,numero);
      insert(DevORder,ListaOrdenes,length(listaordenes));
      end;
   if GVTsTransfered>0 then
      begin
      SaveGVTs;
      UpdateMyGVTsList;
      end;
   TRY
      SetLength(ArrayPoolTXs,0);
      ArrayPoolTXs := copy(IgnoredTrxs,0,length(IgnoredTrxs));
   EXCEPT on E:Exception do
      begin
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error asigning pending to Ignored');
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
         PoScount := length(PoSAddressess);
         PosTotalReward := ((GetBlockReward(Numero)+MinerFee)*GetPoSPercentage(Numero)) div 10000;
         PosReward := PosTotalReward div PoScount;
         PosTotalReward := PoSCount * PosReward;
         //pay POS
         for contador := 0 to length(PoSAddressess)-1 do
            CreditTo(PoSAddressess[contador].address,PosReward,numero);
         end;
      end;
   EndPerformance('NewBLOCK_PoS');
   // Masternodes processing
   BeginPerformance('NewBLOCK_MNs');
   CreditMNVerifications();
   MNsFileText := GetMNsAddresses(MyLastBlock);
   SaveMNsFile(MNsFileText);
   FillNodeList;
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
      MNsTotalReward := ((GetBlockReward(Numero)+MinerFee)*GetMNsPercentage(Numero,GetCFGDataStr(0))) div 10000;
      if MNsCount>0 then MNsReward := MNsTotalReward div MNsCount
      else MNsReward := 0;
      MNsTotalReward := MNsCount * MNsReward;
      NewMNs := 0;
      For contador := 0 to length(MNsAddressess)-1 do
         begin
         CreditTo(MNsAddressess[contador].address,MNsReward,numero);
         if AddLockedMM(MNsAddressess[contador].address,numero) then Inc(NewMNs);
         end;
      EndPerformance('NewBLOCK_MNs');
      end;// End of MNS payment procecessing

   // ***END MASTERNODES PROCESSING***

   // Reset Order hashes received
   ClearReceivedOrdersIDs;

   // Miner payment
   PoWTotalReward := (GetBlockReward(Numero)+MinerFee)-PosTotalReward-MNsTotalReward-DevsTotalReward;
   CreditTo(Minero,PoWTotalReward,numero);
   // Update summary lastblock
   CreditTo(AdminHash,0,numero);
   // Save summary file
   BeginPerformance('NewBLOCK_SaveSum');
   UpdateSummaryChanges();
   EndPerformance('NewBLOCK_SaveSum');
   SummaryLastop := numero;
   // Limpiar las pendientes
   ClearWallPendings;
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
   BlockHeader.Solution:= Solucion+' '+{GetNMSData.Diff}'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF1'+' '+PoWTotalReward.ToString+' '+MNsTotalReward.ToString+' '+PosTotalReward.ToString;
   if numero = 0 then BlockHeader.Solution:='';
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
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'*****CRITICAL*****'+slinebreak+'Error building block: '+numero.ToString);

   BuildNMSBlock := 0;
   ZipSumary;

   SetLength(ListaOrdenes,0);
   SetLength(PoSAddressess,0);
   // Actualizar informacion
   MyLastBlock := Numero;
   MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
   LastBlockData := LoadBlockDataHeader(MyLastBlock);
   SetSummaryHash;
   SetMNsHash;
   // Actualizar el arvhivo de cabeceras
   AddRecordToHeaders(Numero,MyLastBlockHash,MySumarioHash);
   SetResumenHash;
   if ( (Numero>0) and (form1.Server.Active) ) then
      begin
      OutgoingMsjsAdd(ProtocolLine(ping));
      end;
   CheckForMyPending;

   U_DirPanel := true;
   ExpiredMNs := ClearExpiredLockedMNs(numero);
   SavePSOFileToDisk(Numero);
   OutText(format('Block built: %d (%d ms) MNs: + %d / - %d',[numero,EndPerformance('BuildNewBlock'),NewMNs, ExpiredMNs]),true);
   end
else
   begin
   OutText('Failed to build the block',true);
   end;
BuildingBlock := 0;
U_DataPanel := true;
End;

{
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
}
{
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
}
{
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
}
{
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
}
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
                        Ordenes:array of TOrderData;
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
      ToLog('console','Error saving block to disk: '+E.Message);
      result := false;
      end;
   END{Try};
MemStr.Free;
EndPerformance('GuardarBloque');
End;

{
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
      ToLog('console','Error loading Header from block '+IntToStr(BlockNumber)+':'+E.Message);
      end;
   END{Try};
MemStr.Free;
Result := header;
End;
}

{
// Devuelve las transacciones del bloque
function GetBlockTrxs(BlockNumber:integer):TBlockOrdersArray;
var
  ArrTrxs : TBlockOrdersArray;
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
}

Function GetBlockPoSes(BlockNumber:integer): BlockArraysPos;
var
  resultado : BlockArraysPos;
  ArrTrxs : TBlockOrdersArray;
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
  ArrTrxs : TBlockOrdersArray;
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
      ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'EXCEPTION on MNs file data:'+E.Message)
   END; {TRY}
MemStr.Free;
Result := resultado;
end;

// Deshacer el ultimo bloque
Procedure UndoneLastBlock();
Const
  Highest : integer = 0;
var
  blocknumber : integer;
Begin
blocknumber:= MyLastBlock;
if BlockNumber < Highest then
   begin
   ToLog('Console','Can not undo block '+mylastblock.ToString);
   exit;
   end
else Highest := BlockNumber;
if BlockNumber = 0 then exit;
if MyConStatus = 3 then
   begin
   MyConStatus := 2;
   //if Form1.Server.Active then Form1.Server.Active := false;
   ClearMNsChecks();
   ClearMNsList();
   ClearAllPending;
   ClearReceivedOrdersIDs;
   end;
// recover summary
RestoreSumaryBackup();

CreateSumaryIndex;
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
  RemoveHeadersLastRecord;
// Borrar archivo del ultimo bloque
trydeletefile(BlockDirectory +IntToStr(MyLastBlock)+'.blk');
// Actualizar mi informacion
MyLastBlock := GetMyLastUpdatedBlock;
MyLastBlockHash := HashMD5File(BlockDirectory+IntToStr(MyLastBlock)+'.blk');
LastBlockData := LoadBlockDataHeader(MyLastBlock);
SetResumenHAsh;
ToLog('console','****************************');
ToLog('console','Block undone: '+IntToStr(blocknumber)); //'Block undone: '
ToLog('console','****************************');
ToLog('events',TimeToStr(now)+'Block Undone: '+IntToStr(blocknumber));
ToDeepDeb('Block undone: '+Blocknumber.ToString);
U_DataPanel := true;
End;

Function RemoveBlocks(UpToBlock:int64):integer;
var
  Last : int64;
Begin
  Result := 0;
  Repeat
    Last := GetMyLastUpdatedBlock;
    If Last >=  UpToBlock then
      begin
      trydeletefile(BlockDirectory +IntToStr(Last)+'.blk');
      Inc(Result);
      end;
  until Last < UpToBlock;
  MyLastBlock := GetMyLastUpdatedBlock;
End;

Function GEtNSLBlkOrdInfo(LineText:String):String;
var
  ParamBlock  : String;
  BlkNumber   : integer;
  OrdersArray : TBlockOrdersArray;
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
   OrdersArray := Default(TBlockOrdersArray);
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

