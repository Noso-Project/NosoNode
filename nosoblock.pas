unit NosoBlock;

{
NosoNosoCFG 1.1
Febraury 5, 2024
All block related controls
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, FileUtil, NosoDebug, NosoUnit, Nosocrypto,nosogeneral;

Type
  TDBRecord = record
    block    : integer;
    orderID  : integer;
    Source   : integer;
    Target   : integer;
    end;

  BlockHeaderData = Packed Record
    Number         : Int64;
    TimeStart      : Int64;
    TimeEnd        : Int64;
    TimeTotal      : integer;
    TimeLast20     : integer;
    TrxTotales     : integer;
    Difficult      : integer;
    TargetHash     : String[32];
    Solution       : String[200]; // 180 necessary
    LastBlockHash  : String[32];
    NxtBlkDiff     : integer;
    AccountMiner   : String[40];
    MinerFee       : Int64;
    Reward         : Int64;
    end;

  IntArray = array of integer;

Procedure SetBlockDirectory(NewFolder:String);

Procedure CreateDBFile();
Function GetDBRecords():Integer;
Function AddRecordToDBFile(block,order,source,target:integer):boolean;
Function GetDBLastBlock():Integer;
Function UpdateBlockDatabase():Boolean;
Function InsertToIndex(LData:TDBRecord):boolean;
Function CreateOrderIDIndex():Boolean;
Function GetBlockFromOrder(OrderID:string):integer;
Function GetOrderFromDB(OrderID:String; out OrderInfo:TOrderData):boolean;

function GetMyLastUpdatedBlock():int64;
function GetBlockTrxs(BlockNumber:integer):TBlockOrdersArray;
function LoadBlockDataHeader(BlockNumber:integer):BlockHeaderData;

Function SaveStreamAsZipBlocks(Const LStream:TMemoryStream):boolean;

var
  BlockDirectory      : string = 'NOSODATA'+DirectorySeparator+'BLOCKS'+DirectorySeparator;
  BlocksZipFile       : string = 'blocks.zip';
  DBDirectory         : string = 'DB'+DirectorySeparator;
  DataBaseFilename    : string = 'blocks_db.nos';
  DBFile              : file of TDBRecord;
  CSDBFile            : TRTLCriticalSection;
  CSDBIndex           : TRTLCriticalSection;
  OrderIDIndex        : Array of TindexRecord;

IMPLEMENTATION

Procedure SetBlockDirectory(NewFolder:String);
Begin
  BlockDirectory := NewFolder;
  Assignfile(DBFile,BlockDirectory+DBDirectory+DataBaseFilename);
End;

{$REGION blocks database}

// Creates an empty DB file
Procedure CreateDBFile();
Begin
  TRY
  Rewrite(DBFile);
  Closefile(DBFile);
  EXCEPT ON E:EXCEPTION do
    begin
    TodeepDeb('NosoBlock,CreateDBFile,'+E.Message);
    end;
  END;
End;

// Returns the records count on file
Function GetDBRecords():Integer;
var
  opened : boolean = false;
  Closed : boolean = false;
Begin
  Result := 0;
  EnterCriticalSection(CSDBFile);
    TRY
    Reset(DBFile);
    opened := true;
    Result := Filesize(DBFile);
    Closefile(DBFile);
    Closed := true;
    EXCEPT ON E:EXCEPTION do
      begin
      end;
    END;
  if ( (opened) and (not closed) ) then Closefile(DBfile);
  LeaveCriticalSection(CSDBFile);
End;

// Add a new record to the File and also to the index
Function AddRecordToDBFile(block,order,source,target:integer):boolean;
var
  NewData : TDBRecord;
  opened : boolean = false;
  Closed : boolean = false;
Begin
  Result := true;
  NewData := Default(TDBRecord);
  NewData.block:=Block;
  NewData.orderID:=order;
  NewData.Source:=source;
  NewData.Target:=target;
  EnterCriticalSection(CSDBFile);
    TRY
    Reset(DBFile);
    opened := true;
    Seek(DBFile,Filesize(DBFile));
    Write(DBFile,NewData);
    Closefile(DBFile);
    Closed := true;
    EXCEPT ON E:EXCEPTION do
      begin
      Result := false;
      end;
    END;
  if ( (opened) and (not closed) ) then Closefile(DBfile);
  LeaveCriticalSection(CSDBFile);
  InsertToIndex(NewData);
End;

// Returns the last block on file
Function GetDBLastBlock():Integer;
var
  NewData : TDBRecord;
  opened : boolean = false;
  Closed : boolean = false;
Begin
  Result := -1;
  EnterCriticalSection(CSDBFile);
    TRY
    Reset(DBFile);
    opened := true;
    Result := 0;
    if Filesize(DBFile)>0 then
      begin
      Seek(DBFile,Filesize(DBFile)-1);
      Read(DBFile,NewData);
      Result := NewData.Block;
      end;
    Closefile(DBFile);
    Closed := true;
    EXCEPT ON E:EXCEPTION do
      begin

      end;
    END;
  if ( (opened) and (not closed) ) then Closefile(DBfile);
  LeaveCriticalSection(CSDBFile);
End;

// Calculates the integer for the value
Function DBIndex(Text:string):integer;
var
  SubStr : string;
Begin
  Text := Hashmd5String(Text);
  Text := B16toB58(Text);
  SubStr := copy(Text,2,6);
  result := StrToInt64(b58toB10(SubStr)) mod 100000;
End;

// updates file and database to most recent block on disk
Function UpdateBlockDatabase():Boolean;
var
  LastUpdated : integer;
  UntilBlock  : integer;
  counter, counter2     : integer;
  ArrayOrders : TBlockOrdersArray;
  ThisOrder   : TOrderData;
Begin
  Result := true;
  LastUpdated := GetDBLastBlock;
  UntilBlock  := LastUpdated+1000;
  if untilblock >  GetMyLastUpdatedBlock then untilblock := GetMyLastUpdatedBlock;
  for counter := LastUpdated+1 to untilblock do
    begin
    ArrayOrders := Default(TBlockOrdersArray);
    ArrayOrders := GetBlockTrxs(counter);
    for counter2 := 0 to length(ArrayOrders)-1 do
      begin
      ThisOrder := ArrayOrders[counter2];
      if ThisOrder.OrderType<> '' then
        begin
        AddRecordToDBFile(Counter,DBIndex(ThisOrder.OrderID),DBIndex(ThisOrder.Address),DBIndex(ThisOrder.Receiver));
        end;
      end;
    end;
End;

// Insert a value on index
Function InsertToIndex(LData:TDBRecord):boolean;
Begin
  Result := true;
  EnterCriticalSEction(CSDBIndex);
  Insert(LData.block,OrderIDIndex[LData.orderID],length(OrderIDIndex[LData.orderID]));
  LeaveCriticalSEction(CSDBIndex);
End;

// Creates the INDEX from the file
Function CreateOrderIDIndex():Boolean;
var
  ThisData : TDBRecord;
Begin
  BeginPerformance('CreateOrderIDIndex');
  SetLength(OrderIDIndex,0,0);
  SetLength(OrderIDIndex,100000);
    TRY
    Reset(DBFile);
    While not eof(DBFile) do
      begin
      ThisData := Default(TDBRecord);
      Read(DBFile,ThisData);
      Insert(ThisData.block,OrderIDIndex[ThisData.orderID],length(OrderIDIndex[ThisData.orderID]));
      end;
    EXCEPT ON E:EXCEPTION do
      begin

      end;
    END;
  EndPerformance('CreateOrderIDIndex');
End;

// Returns the array of integer of the specified index value
Function GetDBArray(value:integer;out LArray: IntArray):Boolean;
Begin
  result := false;
  SetLength(LArray,0);
  EnterCriticalSection(CSDBIndex);
  if length(OrderIDIndex[value]) > 0 then
    begin
    LArray := copy(OrderIDIndex[value],0,length(OrderIDIndex[value]));
    Result := true;
    end;
  LeaveCriticalSection(CSDBIndex);
End;

// Returns the block number where the order is found, or -1 if none
Function GetBlockFromOrder(OrderID:string):integer;
var
  LValue      : integer;
  ThisArray   : IntArray;
  counter     : integer;
  counter2    : integer;
  ArrayOrders : TBlockOrdersArray;
Begin
  Result := -1;
  LValue := DBIndex(OrderID);
  if GetDBArray(LValue,ThisArray) then
    begin
    for counter := 0 to length(ThisArray)-1 do
      begin
      ArrayOrders := Default(TBlockOrdersArray);
      ArrayOrders := GetBlockTrxs(ThisArray[counter]);
      for counter2 := 0 to length(ArrayOrders)-1 do
        begin
        if Arrayorders[counter2].OrderID = OrderID then
          begin
          Exit(Arrayorders[counter2].Block);
          end;
        end;
      end;
    end;
End;

// Returns the order data from its orderID
Function GetOrderFromDB(OrderID:String; out OrderInfo:TOrderData):boolean;
var
  IndexValue        : integer;
  Counter, counter2 : integer;
  ThisArray         : IntArray;
  ArrayOrders       : TBlockOrdersArray;
Begin
  Result := False;
  OrderInfo := Default(TOrderData);
  IndexValue := DBIndex(OrderID);
  if GetDBArray(IndexValue,ThisArray) then
  //if length(OrderIDIndex[IndexValue]) > 0 then
    begin
    for counter := 0 to length(ThisArray)-1 do
      begin
      ArrayOrders := Default(TBlockOrdersArray);
      ArrayOrders := GetBlockTrxs(ThisArray[counter]);
      for counter2 := 0 to length(ArrayOrders)-1 do
        begin
        if Arrayorders[counter2].OrderID = OrderID then
          begin
          OrderInfo := Arrayorders[counter2];
          Exit(True);
          end;
        end;
      end;
    end;
End;

{$ENDREGION blocks database}

{$REGION Blocks Information}

// Returns the last downloaded block
function GetMyLastUpdatedBlock():int64;
Var
  BlockFiles   : TStringList;
  contador     : int64 = 0;
  LastBlock    : int64 = 0;
  OnlyNumbers  : String;
  IgnoredChars : integer;
Begin
  IgNoredChars := Length(BlockDirectory)+1;
  BlockFiles := TStringList.Create;
    TRY
    FindAllFiles(BlockFiles, BlockDirectory, '*.blk', true);
    while contador < BlockFiles.Count do
      begin
      OnlyNumbers := copy(BlockFiles[contador], IgNoredChars, length(BlockFiles[contador])-(ignoredchars+3));
      if StrToInt64Def(OnlyNumbers,0) > Lastblock then
         LastBlock := StrToInt64Def(OnlyNumbers,0);
      Inc(contador);
      end;
    Result := LastBlock;
    EXCEPT on E:Exception do
      begin
      //
      end;
    END; {TRY}
  BlockFiles.Free;
End;

// Return the array containing orders in the specified block
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
    TRY
     MemStr.LoadFromFile(ArchData);
     MemStr.Position := 0;
     MemStr.Read(Header, SizeOf(Header));
     TotalTrxs := header.TrxTotales;
     SetLength(ArrTrxs,TotalTrxs);
     For Counter := 0 to TotalTrxs-1 do
       MemStr.Read(ArrTrxs[Counter],Sizeof(ArrTrxs[Counter])); // read each record
     Except on E: Exception do
       begin
       ToDeepDeb('Nosoblock,GetBlockTrxs,'+E.Message);
       end;
     END;
  MemStr.Free;
  Result := ArrTrxs;
End;

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

{$ENDREGION Blocks Information}

{$REGION Blocks Files management}

Function SaveStreamAsZipBlocks(Const LStream:TMemoryStream):boolean;
Begin
  result := false;
  TRY
    LStream.SaveToFile(BlockDirectory+BlocksZipFile);
    Result := true;
  EXCEPT ON E:Exception do
    begin
    ToDeepDeb('NosoBlock,SaveStreamAsZipBlocks,'+E.Message);
    end;
  END{Try};
End;

{$ENDREGION Blocks Files management}

INITIALIZATION
Assignfile(DBFile,BlockDirectory+DBDirectory+DataBaseFilename);
InitCriticalSection(CSDBFile);
InitCriticalSection(CSDBIndex);
SetLength(OrderIDIndex,0,0);
SetLength(OrderIDIndex,100000);

FINALIZATION
DoneCriticalSection(CSDBFile);
DoneCriticalSection(CSDBIndex);

END.

