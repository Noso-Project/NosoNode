unit nosounit;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils,
  nosocrypto, nosodebug;

Type
  TSummaryData = Packed Record
    Hash    : String[40];  {Public hash}
    Custom  : String[40];  {Custom alias}
    Balance : int64;       {Noso balance}
    Score   : int64;       {token balance}
    LastOP  : int64;       {Last operation block}
    end;

  TOrderGroup = Packed Record
    Block      : integer;
    TimeStamp  : Int64;
    OrderID    : string[64];
    OrderType  : String[6];
    OrderLines : Integer;
    Reference  : String[64];
    sender     : string;
    Receiver   : String[40];
    AmmountFee : Int64;
    AmmountTrf : Int64;
    end;

  TOrderData = Packed Record
    Block      : integer;
    OrderID    : String[64];
    OrderLines : Integer;
    OrderType  : String[6];
    TimeStamp  : Int64;
    Reference  : String[64];
      TrxLine    : integer;
      sender     : String[120];
      Address    : String[40];
      Receiver   : String[40];
      AmmountFee : Int64;
      AmmountTrf : Int64;
      Signature  : String[120];
      TrfrID     : String[64];
    end;

  TBlockOrdersArray = Array of TOrderData;
  TIndexRecord      = array of integer;

{Protocol utilitys}
Function CreateProtocolOrder(BlockN:integer;OrType,sender,receiver,signature:string;TimeStamp,Amount:int64):TOrderData;

{Sumary management}
Function LoadSummaryFromDisk(FileToLoad:String = ''):Boolean;
Function SaveSummaryToDisk(FileToSave:String = ''):Boolean;
Function CreateSumaryIndex():int64;
Function GetAddressBalanceIndexed(Address:string):int64;

Var
  {Overall variables}
  WorkingPath     : string = '';

  {Summary related}
  SummaryFileName : string = 'NOSODATA'+DirectorySeparator+'sumary.psk';
  Listasumario    : Array of TSummaryData;
  SumaryIndex     : Array of TindexRecord;
  CS_Summary      : TRTLCriticalSection;

IMPLEMENTATION

{$REGION Protocol utilitys}

Function CreateProtocolOrder(BlockN:integer;OrType,sender,receiver,signature:string;TimeStamp,Amount:int64):TOrderData;
Begin
  Result := Default(TOrderData);
  Result.Block      := BlockN;
  Result.OrderLines := 1;
  Result.OrderType  := OrType;
  Result.TimeStamp  := TimeStamp;
  Result.Reference  := 'null';
  Result.TrxLine    := 1;
  Result.sender     := sender;
  Result.Address    := sender;
  Result.Receiver   := receiver;
  Result.AmmountFee := 0;
  Result.AmmountTrf := amount;
  Result.Signature  := Signature;
  Result.TrfrID     := GetTransferHash(Result.TimeStamp.ToString+Sender+Receiver+IntToStr(amount)+IntToStr(BlockN-1));
  Result.OrderID    := GetOrderHash('1'+Result.TrfrID);
End;

{$ENDREGION}

{$REGION Sumary management}

{Loads the summary from file to the memory array}
Function LoadSummaryFromDisk(FileToLoad:String = ''):Boolean;
var
  MyStream   : TMemoryStream;
  ThisRecord : TSummaryData;
Begin
  Beginperformance('LoadSummaryFromDisk');
  result := true;
  if FileToLoad = '' then FileToLoad := SummaryFileName;
  MyStream := TMemoryStream.Create;
  TRY
  MyStream.LoadFromFile(FileToLoad);
  MyStream.Position := 0;
  Setlength(Listasumario,0);
  While MyStream.Position < MyStream.Size do
    begin
    MyStream.Read(ThisRecord.Hash, SizeOf(ThisRecord.Hash));
    MyStream.Read(ThisRecord.Custom, SizeOf(ThisRecord.Custom));
    MyStream.Read(ThisRecord.Balance, SizeOf(ThisRecord.Balance));
    MyStream.Read(ThisRecord.Score, SizeOf(ThisRecord.Score));
    MyStream.Read(ThisRecord.LastOP, SizeOf(ThisRecord.LastOp));
    Insert(ThisRecord,Listasumario,length(Listasumario));
    end;
  EXCEPT
    result := false;
  END;
  MyStream.Free;
  Endperformance('LoadSummaryFromDisk');
  CreateSumaryIndex;
End;

{Save the summary array to the disk}
Function SaveSummaryToDisk(FileToSave:String = ''):Boolean;
var
  MyStream   : TMemoryStream;
  counter    : integer;
Begin
  result := true;
  if FileToSave = '' then FileToSave := SummaryFileName;
  MyStream := TMemoryStream.Create;
  TRY
  for counter := 0 to high(Listasumario) do
    begin
    MyStream.Write(Listasumario[counter],Sizeof(Listasumario[counter]));
    end;
  MyStream.SaveToFile(FileToSave);
  EXCEPT
    result := false;
  END;
  MyStream.Free;;
End;

Function GetIndexSize(LRecords:integer):integer;
Begin
result := 10;
Repeat
  Result := Result*10;
until result > Lrecords;
Result := result div 10;
End;

Function IndexFunction(LAddressHash:string; indexsize:int64):int64;
var
  SubStr : string;
Begin
  LAddressHash := Hashmd5String(LAddressHash);
  LAddressHash := B16toB58(LAddressHash);
  SubStr := copy(LAddressHash,2,6);
  result := StrToInt64(b58toB10(SubStr)) mod indexsize;
End;

{Creates the summary hash from the disk}
Function CreateSumaryIndex():int64;
var
  SumFile : File;
  Readed : integer = 0;
  ThisRecord : TSummaryData;
  IndexSize  : int64;
  IndexPosition : int64;
  CurrPos       : int64 = 0;
Begin
  beginperformance('CreateSumaryIndex');
  AssignFile(SumFile,SummaryFileName);
    TRY
    Reset(SumFile,1);
    IndexSize := GetIndexSize(FileSize(SumFile) div Sizeof(TSummaryData));
    SetLength(SumaryIndex,IndexSize);
    While not eof(SumFile) do
      begin
      blockread(sumfile,ThisRecord,sizeof(ThisRecord));
      IndexPosition := IndexFunction(ThisRecord.Hash,indexsize);
      Insert(CurrPos,SumaryIndex[IndexPosition],length(SumaryIndex[IndexPosition]));
      if ThisRecord.Custom  <> '' then
        begin
        IndexPosition := IndexFunction(ThisRecord.custom,indexsize);
        Insert(CurrPos,SumaryIndex[IndexPosition],length(SumaryIndex[IndexPosition]));
        end;
      Inc(currpos);
      end;
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  Result := EndPerformance('CreateSumaryIndex');
End;

function ReadSumaryRecordFromDisk(index:integer):TSummaryData;
var
  SumFile : File;
Begin
  Result := Default(TSummaryData);
  AssignFile(SumFile,SummaryFileName);
    TRY
    Reset(SumFile,1);
    seek(Sumfile,index*(sizeof(result)));
    blockread(sumfile,result,sizeof(result));
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
End;

Function GetAddressBalanceIndexed(Address:string):int64;
var
  IndexPos : integer;
  counter  : integer = 0;
  ThisRecord : TSummaryData;
Begin
result := 0;
IndexPos := IndexFunction(address,length(SumaryIndex));
if length(SumaryIndex[IndexPos])>0 then
   begin
   for counter := 0 to high(SumaryIndex[IndexPos]) do
     begin
     ThisRecord := ReadSumaryRecordFromDisk(SumaryIndex[IndexPos][counter]);
     if Thisrecord.Hash = address then
        begin
        result := ThisRecord.Balance;
        break;
        end;
     end;
   end;
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_Summary);

FINALIZATION
DoneCriticalSection(CS_Summary);


END. {End unit}

