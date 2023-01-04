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

  TBlockRecords = record
    DiskSlot : int64;
    VRecord  : TSummaryData;
    end;

{Protocol utilitys}
Function CreateProtocolOrder(BlockN:integer;OrType,sender,receiver,signature:string;TimeStamp,Amount:int64):TOrderData;

{Sumary management}
{Old system}
Function LoadSummaryFromDisk(FileToLoad:String = ''):Boolean;
Function SaveSummaryToDisk(FileToSave:String = ''):Boolean;
{New system}
Function CreateSumaryIndex():int64;
Function SumIndexLength():int64;
Procedure ResetBlockRecords();
Function GetIndexPosition(LText:String;out RecordData:TSummaryData; IsAlias:boolean = false):int64;
Function SummaryValidPay(Address:string;amount,blocknumber:int64):boolean;
Procedure CreditTo(Address:String;amount,blocknumber:int64);
Function IsCustomizacionValid(address,custom:string;blocknumber:int64):Boolean;
Procedure UpdateSummaryChanges();
Function GetAddressBalanceIndexed(Address:string):int64;

Var
  {Overall variables}
  WorkingPath     : string = '';

  {Summary related}
  SummaryFileName : string = 'NOSODATA'+DirectorySeparator+'sumary.psk';
  SummaryLastop   : int64;
  Listasumario    : Array of TSummaryData;

IMPLEMENTATION

var
  IndexLength     : int64;
  SumaryIndex     : Array of TindexRecord;
  CS_SummaryDisk  : TRTLCriticalSection;   {Disk access to summary}
  BlockRecords    : array of TBlockRecords;
  CS_BlockRecs    : TRTLCriticalSection;

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

{$REGION Old system}

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
  MyStream.Free;
End;

{$ENDREGION}

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

{Reads a specific summary record position from disk}
function ReadSumaryRecordFromDisk(index:integer):TSummaryData;
var
  SumFile : File;
Begin
  Result := Default(TSummaryData);
  AssignFile(SumFile,SummaryFileName);
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    Reset(SumFile,1);
      TRY
      seek(Sumfile,index*(sizeof(result)));
      blockread(sumfile,result,sizeof(result));
      EXCEPT
      END;{Try}
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  LeaveCriticalSection(CS_SummaryDisk);
End;

{Creates the summary index from the disk}
Function CreateSumaryIndex():int64;
var
  SumFile : File;
  Readed : integer = 0;
  ThisRecord : TSummaryData;
  IndexPosition : int64;
  CurrPos       : int64 = 0;
  IsRecordZero  : boolean = true;
Begin
  beginperformance('CreateSumaryIndex');
  AssignFile(SumFile,SummaryFileName);
  SetLength(SumaryIndex,0,0);
    TRY
    Reset(SumFile,1);
    IndexLength := GetIndexSize(FileSize(SumFile) div Sizeof(TSummaryData));
    SetLength(SumaryIndex,IndexLength);
    While not eof(SumFile) do
      begin
      blockread(sumfile,ThisRecord,sizeof(ThisRecord));
      IndexPosition := IndexFunction(ThisRecord.Hash,IndexLength);
      Insert(CurrPos,SumaryIndex[IndexPosition],length(SumaryIndex[IndexPosition]));
      if ThisRecord.Custom  <> '' then
        begin
        IndexPosition := IndexFunction(ThisRecord.custom,IndexLength);
        Insert(CurrPos,SumaryIndex[IndexPosition],length(SumaryIndex[IndexPosition]));
        end;
      Inc(currpos);
      end;
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  Result := EndPerformance('CreateSumaryIndex');
  SummaryLastop := ReadSumaryRecordFromDisk(0).LastOp;
End;

Function SumIndexLength():int64;
Begin
  result := IndexLength;
End;

Procedure WriteSummaryRecordToDisk(index:int64;LRecord:TSummaryData);
var
  SumFile : File;
Begin
  AssignFile(SumFile,SummaryFileName);
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    Reset(SumFile,1);
      TRY
      if index<0 then index := FileSize(SumFile) div Sizeof(TSummaryData);
      seek(Sumfile,index*(sizeof(LRecord)));
      blockwrite(sumfile,LRecord,sizeof(LRecord));
      EXCEPT
      END;{Try}
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  LeaveCriticalSection(CS_SummaryDisk);
End;

{If found, returns the record}
Function GetIndexPosition(LText:String;out RecordData:TSummaryData; IsAlias:boolean = false):int64;
var
  IndexPos : int64;
  counter  : integer = 0;
  ThisRecord : TSummaryData;
Begin
  result := -1;
  RecordData := Default(TSummaryData);
  IndexPos := IndexFunction(LText,IndexLength);
  if length(SumaryIndex[IndexPos])>0 then
    begin
    for counter := 0 to high(SumaryIndex[IndexPos]) do
      begin
      ThisRecord := ReadSumaryRecordFromDisk(SumaryIndex[IndexPos][counter]);
      if (((Thisrecord.Hash = LText) and (not isAlias)) or ((ThisRecord.Custom = LText)and (IsAlias)))then
        begin
        RecordData := ThisRecord;
        Result := SumaryIndex[IndexPos][counter];
        break;
        end;
      end;
    end;
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

Procedure ResetBlockRecords();
Begin
  SetLength(BlockRecords,0);
End;

{Verify if a sender address have enough funds}
Function SummaryValidPay(Address:string;amount,blocknumber:int64):boolean;
var
  counter     : integer;
  SendPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  Result := False;
  For counter := 0 to high(BlockRecords) do
    begin
    if BlockRecords[counter].VRecord.Hash = Address then
      begin
      if BlockRecords[counter].VRecord.Balance<amount then Exit(false)
      else
        begin
        Dec(BlockRecords[counter].VRecord.Balance,amount);
        BlockRecords[counter].VRecord.LastOP:=BlockNumber;
        Exit(true);
        end;
      end;
    end;
  SendPos := GetIndexPosition(Address,ThisRecord);
  If SendPos < 0 then exit(false)
  else
    begin
    if ThisRecord.Balance<amount then Exit(false)
    else
      begin
      Dec(ThisRecord.Balance,amount);
      ThisRecord.LastOP:=Blocknumber;
      SetLength(BlockRecords,Length(BlockRecords)+1);
      BlockRecords[Length(BlockRecords)-1].DiskSlot := SendPos;
      BlockRecords[Length(BlockRecords)-1].VRecord  := ThisRecord;
      Exit(true);
      end;
    end;
End;

Procedure CreditTo(Address:String;amount,blocknumber:int64);
var
  counter     : integer;
  SendPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  For counter := 0 to high(BlockRecords) do
    begin
    if BlockRecords[counter].VRecord.Hash = Address then
      begin
      Inc(BlockRecords[counter].VRecord.Balance,amount);
      BlockRecords[counter].VRecord.LastOP:=BlockNumber;
      Exit;
      end;
    end;
  SendPos := GetIndexPosition(Address,ThisRecord);
  Inc(ThisRecord.Balance,amount);
  ThisRecord.LastOP :=BlockNumber;
  if SendPos < 0 then ThisRecord.Hash   :=Address;
    begin
    Setlength(BlockRecords,length(BlockRecords)+1);
    BlockRecords[length(BlockRecords)-1].DiskSlot:= SendPos;
    BlockRecords[length(BlockRecords)-1].VRecord := ThisRecord;
    end;
End;

Function IsCustomizacionValid(address,custom:string;blocknumber:int64):Boolean;
var
  counter     : integer;
  SumPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  Result := False;
  For counter := 0 to high(BlockRecords) do
    begin
    if BlockRecords[counter].VRecord.Hash=Address then
      begin
      if BlockRecords[counter].VRecord.Custom<> '' then exit(false);
      if BlockRecords[counter].VRecord.Balance<25000 then Exit(false);
      BlockRecords[counter].VRecord.Custom := Address;
      Dec(BlockRecords[counter].VRecord.Balance,25000);
      exit(true);
      end;
    end;
  SumPos := GetIndexPosition(Address,ThisRecord);
  if SumPos < 0 then Exit(False);
  if ThisRecord.Balance<25000 then Exit(false);
  ThisRecord.Custom:=address;
  Dec(ThisRecord.Balance,25000);
  ThisRecord.LastOP:=BlockNumber;
  SetLength(BlockRecords,Length(BlockRecords)+1);
  BlockRecords[Length(BlockRecords)-1].DiskSlot := SumPos;
  BlockRecords[Length(BlockRecords)-1].VRecord  := ThisRecord;
  Exit(true);
End;

Procedure UpdateSummaryChanges();
var
  counter     : integer;
  Position    : integer;
  SumFile     : file;
Begin
  AssignFile(SumFile,SummaryFileName);
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    Reset(SumFile,1);
      TRY
      For counter := 0 to high(BlockRecords) do
        begin
        if BlockRecords[counter].DiskSlot <0 then BlockRecords[counter].DiskSlot := FileSize(SumFile) div Sizeof(TSummaryData);
        seek(Sumfile,BlockRecords[counter].DiskSlot*(sizeof(TSummaryData)));
        blockwrite(sumfile,BlockRecords[counter].VRecord,sizeof(TSummaryData));
        end;
      EXCEPT
      END;{Try}
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  LeaveCriticalSection(CS_SummaryDisk);
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_SummaryDisk);
InitCriticalSection(CS_BlockRecs);


FINALIZATION
DoneCriticalSection(CS_SummaryDisk);
DoneCriticalSection(CS_BlockRecs);


END. {End unit}

