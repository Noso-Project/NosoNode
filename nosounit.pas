unit nosounit;

{
Nosounit 1.0
January 8th 2023
Noso project unit to handle summary
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, Zipper,
  nosocrypto, nosodebug, nosogeneral;

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
Procedure CreateNewSummaryFile(AddBlockZero:Boolean);
Function ZipSumary():boolean;
Function CreateSumaryIndex():int64;
Function GetSummaryAsMemStream(out LMs:TMemoryStream):int64;
Function GetZIPSummaryAsMemStream(out LMs:TMemoryStream):int64;
Function SaveSummaryToFile(Const LStream:TMemoryStream):Boolean;
Function CreateSumaryBackup():Boolean;
Function RestoreSumaryBackup():Boolean;
Function SumIndexLength():int64;
Procedure ResetBlockRecords();
Function GetIndexPosition(LText:String;out RecordData:TSummaryData; IsAlias:boolean = false):int64;
Function SummaryValidPay(Address:string;amount,blocknumber:int64):boolean;
Procedure SummaryPay(Address:string;amount,blocknumber:int64);
Procedure CreditTo(Address:String;amount,blocknumber:int64);
Function IsCustomizacionValid(address,custom:string;blocknumber:int64;forceCustom:boolean = false):Boolean;
Procedure UpdateSummaryChanges();
Function GetAddressBalanceIndexed(Address:string):int64;
Function GetAddressAlias(Address:String):string;
Function GetAddressLastOP(Address:String):int64;

// Summary hash related
Procedure SetSummaryHash();
Function MySumarioHash:String;

Var
  {Overall variables}
  WorkingPath     : string = '';

  {Summary related}
  SummaryFileName     : string = 'NOSODATA'+DirectorySeparator+'sumary.psk';
  ZipSumaryFileName   : string = 'NOSODATA'+DirectorySeparator+'sumary.zip';
  SummaryLastop       : int64;
  SummaryHashValue    : string = '';

IMPLEMENTATION

var
  IndexLength     : int64 = 10;
  SumaryIndex     : Array of TindexRecord;
  CS_SummaryDisk  : TRTLCriticalSection;   {Disk access to summary}
  BlockRecords    : array of TBlockRecords;
  CS_BlockRecs    : TRTLCriticalSection;
  CS_SummaryHashV : TRTLCriticalSection;

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

{Creates a new summary file}
Procedure CreateNewSummaryFile(AddBlockZero:Boolean);
var
  lFile : file;
Begin
  TRY
  assignfile(lFile,SummaryFileName);
  Rewrite(lFile);
  CloseFile(lFile);
  CreateSumaryIndex;
  if AddBlockZero then
    begin
    CreditTo('N4PeJyqj8diSXnfhxSQdLpo8ddXTaGd',1030390730000,0);
    UpdateSummaryChanges;
    ResetBlockRecords;
    SummaryLastop := 0;
    end;
  EXCEPT on E:Exception do

  END; {TRY}
  SetSummaryHash;
End;

{Create the zipped summary file}
{Must be replaced with new stream compression methods}
Function ZipSumary():boolean;
var
  MyZipFile: TZipper;
  archivename: String;
Begin
result := false;
MyZipFile := TZipper.Create;
MyZipFile.FileName := ZipSumaryFileName;
EnterCriticalSection(CS_SummaryDisk);
   TRY
   {$IFDEF WINDOWS}
   archivename:= StringReplace(SummaryFileName,'\','/',[rfReplaceAll]);
   {$ENDIF}
   {$IFDEF UNIX}
   archivename:= SummaryFileName;
   {$ENDIF}
   archivename:= StringReplace(archivename,'NOSODATA','data',[rfReplaceAll]);
   MyZipFile.Entries.AddFileEntry(SummaryFileName, archivename);
   MyZipFile.ZipAllFiles;
   result := true;
   EXCEPT ON E:Exception do
   END{Try};
MyZipFile.Free;
LeaveCriticalSection(CS_SummaryDisk);
End;

Function GetSummaryAsMemStream(out LMs:TMemoryStream):int64;
Begin
  Result := 0;
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    LMs.LoadFromFile(SummaryFileName);
    result:= LMs.Size;
    LMs.Position:=0;
    EXCEPT ON E:Exception do
    END{Try};
  LeaveCriticalSection(CS_SummaryDisk);
End;

Function GetZIPSummaryAsMemStream(out LMs:TMemoryStream):int64;
Begin
  Result := 0;
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    LMs.LoadFromFile(ZipSumaryFileName);
    result:= LMs.Size;
    LMs.Position:=0;
    EXCEPT ON E:Exception do
    END{Try};
  LeaveCriticalSection(CS_SummaryDisk);
End;

Function SaveSummaryToFile(Const LStream:TMemoryStream):Boolean;
Begin
  result := false;
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    LStream.SaveToFile(SummaryFileName);
    Result := true;
    EXCEPT ON E:Exception do
    END{Try};
  LeaveCriticalSection(CS_SummaryDisk);
  SetSummaryHash;
End;

Function CreateSumaryBackup():Boolean;
Begin
  EnterCriticalSection(CS_SummaryDisk);
  Result:= TryCopyFile(SummaryFileName,SummaryFileName+'.bak');
  LeaveCriticalSection(CS_SummaryDisk);
End;

Function RestoreSumaryBackup():Boolean;
Begin
  EnterCriticalSection(CS_SummaryDisk);
  Result := Trycopyfile(SummaryFileName+'.bak',SummaryFileName);
  LeaveCriticalSection(CS_SummaryDisk);
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

{Add a pointer to the summary index}
Procedure InsertIndexData(LRecord:TSummaryData;DiskPos:int64);
var
  IndexValue : int64;
Begin
  IndexValue := IndexFunction(LRecord.Hash,IndexLength);
  Insert(DiskPos,SumaryIndex[IndexValue],length(SumaryIndex[IndexValue]));
  if LRecord.Custom  <> '' then
    begin
    IndexValue := IndexFunction(LRecord.custom,IndexLength);
    Insert(DiskPos,SumaryIndex[IndexValue],length(SumaryIndex[IndexValue]));
    end;
End;

{Creates the summary index from the disk}
Function CreateSumaryIndex():int64;
var
  SumFile : File;
  ThisRecord : TSummaryData;
  CurrPos       : int64 = 0;
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
      InsertIndexData(ThisRecord,CurrPos);
      Inc(currpos);
      end;
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  Result := EndPerformance('CreateSumaryIndex');
  SummaryLastop := ReadSumaryRecordFromDisk(0).LastOp;
  SetSummaryHash;
End;

{Returns the summary index length}
Function SumIndexLength():int64;
Begin
  result := IndexLength;
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

{Returns the balance of a specific address}
Function GetAddressBalanceIndexed(Address:string):int64;
var
  IndexPos : integer;
  counter  : integer = 0;
  ThisRecord : TSummaryData;
Begin
result := 0;
IndexPos := IndexFunction(address,length(SumaryIndex));
If IndexPos > Length(SumaryIndex) then Exit;
if length(SumaryIndex[IndexPos])>0 then
   begin
   for counter := 0 to high(SumaryIndex[IndexPos]) do
     begin
     ThisRecord := ReadSumaryRecordFromDisk(SumaryIndex[IndexPos][counter]);
     if Thisrecord.Hash = address then
       Exit(ThisRecord.Balance)
     end;
   end;
End;

{Reset the block records}
Procedure ResetBlockRecords();
Begin
  EnterCriticalSection(CS_BlockRecs);
  SetLength(BlockRecords,0);
  LeaveCriticalSection(CS_BlockRecs);
End;

{Insert a block record}
Procedure InsBlockRecord(LRecord:TSummaryData;SLot:int64);
Begin
  EnterCriticalSection(CS_BlockRecs);
  SetLength(BlockRecords,Length(BlockRecords)+1);
  BlockRecords[Length(BlockRecords)-1].DiskSlot := SLot;
  BlockRecords[Length(BlockRecords)-1].VRecord  := LRecord;
  LeaveCriticalSection(CS_BlockRecs);
End;

{Verify if a sender address have enough funds}
Function SummaryValidPay(Address:string;amount,blocknumber:int64):boolean;
var
  counter     : integer;
  SendPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  Result := False;
  EnterCriticalSection(CS_BlockRecs);
  try
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
  finally
    LeaveCriticalSection(CS_BlockRecs);
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
      InsBlockRecord(ThisRecord,sendpos);
      Exit(true);
      end;
    end;
End;

Procedure SummaryPay(Address:string;amount,blocknumber:int64);
var
  counter     : integer;
  SendPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  EnterCriticalSection(CS_BlockRecs);
  try
    For counter := 0 to high(BlockRecords) do
    begin
    if BlockRecords[counter].VRecord.Hash = Address then
      begin
      Dec(BlockRecords[counter].VRecord.Balance,amount);
      BlockRecords[counter].VRecord.LastOP:=BlockNumber;
      Exit;
      end;
    end;
  finally
    LeaveCriticalSection(CS_BlockRecs);
  end;
  SendPos := GetIndexPosition(Address,ThisRecord);
  If SendPos < 0 then ThisRecord.Hash := address
  else
    begin
    Dec(ThisRecord.Balance,amount);
    ThisRecord.LastOP:=Blocknumber;
    InsBlockRecord(ThisRecord,sendpos);
    Exit;
    end;
End;

{Set an ammount to be credited to an specific address}
Procedure CreditTo(Address:String;amount,blocknumber:int64);
var
  counter     : integer;
  SummPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  EnterCriticalSection(CS_BlockRecs);
  try
    For counter := 0 to high(BlockRecords) do
      begin
      if BlockRecords[counter].VRecord.Hash = Address then
        begin
        Inc(BlockRecords[counter].VRecord.Balance,amount);
        BlockRecords[counter].VRecord.LastOP:=BlockNumber;
        Exit;
        end;
      end;
  finally
    LeaveCriticalSection(CS_BlockRecs);
  end;
  SummPos := GetIndexPosition(Address,ThisRecord);
  Inc(ThisRecord.Balance,amount);
  ThisRecord.LastOP :=BlockNumber;
  if SummPos < 0 then ThisRecord.Hash := Address;
  InsBlockRecord(ThisRecord,SummPos);
End;

{Process if an address customization is valid}
Function IsCustomizacionValid(address,custom:string;blocknumber:int64;forceCustom:boolean = false):Boolean;
var
  counter     : integer;
  SumPos     : int64;
  ThisRecord  : TSummaryData;
Begin
  Result := False;
  EnterCriticalSection(CS_BlockRecs);
  try
    For counter := 0 to high(BlockRecords) do
      begin
      if BlockRecords[counter].VRecord.Hash=Address then
        begin
        if ((BlockRecords[counter].VRecord.Custom<> '') and (not forceCustom)) then exit(false);
        if ((BlockRecords[counter].VRecord.Balance<25000) and (not forceCustom)) then Exit(false);
        BlockRecords[counter].VRecord.Custom := custom;
        Dec(BlockRecords[counter].VRecord.Balance,25000);
        exit(true);
        end;
      end;
  finally
    LeaveCriticalSection(CS_BlockRecs);
  end;
  SumPos := GetIndexPosition(Address,ThisRecord);
  if SumPos < 0 then Exit(False);
  if ((ThisRecord.Balance<25000) and (not forceCustom)) then Exit(false);
  if ((thisRecord.Custom<> '') and (not forceCustom)) then Exit(false);
  ThisRecord.Custom:=custom;
  Dec(ThisRecord.Balance,25000);
  ThisRecord.LastOP:=BlockNumber;
  InsBlockRecord(ThisRecord,SumPos);
  Result := true;
End;

{Process the changes of the block to the summary on disk}
Procedure UpdateSummaryChanges();
var
  counter     : integer;
  SumFile     : file;
Begin
  AssignFile(SumFile,SummaryFileName);
  EnterCriticalSection(CS_SummaryDisk);
    TRY
    Reset(SumFile,1);
      TRY
      For counter := 0 to high(BlockRecords) do
        begin
        if BlockRecords[counter].DiskSlot <0 then
          begin
          BlockRecords[counter].DiskSlot := FileSize(SumFile) div Sizeof(TSummaryData);
          InsertIndexData(BlockRecords[counter].VRecord,BlockRecords[counter].DiskSlot);
          end;
        seek(Sumfile,BlockRecords[counter].DiskSlot*(sizeof(TSummaryData)));
        blockwrite(sumfile,BlockRecords[counter].VRecord,sizeof(TSummaryData));
        end;
      EXCEPT
      END;{Try}
    CloseFile(SumFile);
    EXCEPT
    END;{Try}
  LeaveCriticalSection(CS_SummaryDisk);
  SummaryLastop := ReadSumaryRecordFromDisk(0).LastOp;
  SetSummaryHash;
End;

{Returns the address alias name if exists}
Function GetAddressAlias(Address:String):string;
var
  sumpos  : int64;
  LRecord : TSummaryData;
Begin
  Result := '';
  sumpos := GetIndexPosition(Address,LRecord);
  if ((sumpos>=0) and (LRecord.Custom <> '')) then result := LRecord.Custom;
End;

{Returns the address last operation block}
Function GetAddressLastOP(Address:String):int64;
var
  sumpos  : int64;
  LRecord : TSummaryData;
Begin
  Result := 0;
  sumpos := GetIndexPosition(Address,LRecord);
  if (sumpos>=0) then result := LRecord.LastOP;
End;

{$ENDREGION}

Procedure SetSummaryHash();
Begin
  EnterCriticalSection(CS_SummaryHashV);
  SummaryHashValue := HashMD5File(SummaryFileName);
  LeaveCriticalSection(CS_SummaryHashV);
End;

Function MySumarioHash:String;
Begin
  EnterCriticalSection(CS_SummaryHashV);
  Result := SummaryHashValue;
  LeaveCriticalSection(CS_SummaryHashV);
End;

INITIALIZATION
SetLength(SumaryIndex,0,0);
SetLength(BlockRecords,0);
InitCriticalSection(CS_SummaryDisk);
InitCriticalSection(CS_BlockRecs);
InitCriticalSection(CS_SummaryHashV);



FINALIZATION
DoneCriticalSection(CS_SummaryDisk);
DoneCriticalSection(CS_BlockRecs);
DoneCriticalSection(CS_SummaryHashV);


END. {End unit}

