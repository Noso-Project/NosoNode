unit nosounit;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils,
  nosocrypto;

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

{Protocol utilitys}
Function CreateProtocolOrder(BlockN:integer;OrType,sender,receiver,signature:string;TimeStamp,Amount:int64):TOrderData;

Function LoadSummaryFromDisk(FileToLoad:String = ''):Boolean;
Function SaveSummaryToDisk(FileToSave:String = ''):Boolean;
Function FixSummary():TBlockOrdersArray;
Function OptimizeSummary(OnBlock:int64):Boolean;

Var
  {Overall variables}
  WorkingPath     : string = '';

  {Summary related}
  SummaryFileName : string = 'NOSODATA'+DirectorySeparator+'sumary.psk';
  Listasumario    : Array of TSummaryData;
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

Function LoadSummaryFromDisk(FileToLoad:String = ''):Boolean;
var
  MyStream   : TMemoryStream;
  ThisRecord : TSummaryData;
Begin
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
End;

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

Function FixSummary():TBlockOrdersArray;
var
  counter : integer;
Begin
  Setlength(Result,0);
  For counter := 0 to high(Listasumario) do
    begin

    end;
End;

Function OptimizeSummary(OnBlock:int64):Boolean;
var
  IsDone  : boolean = false;
  Counter : integer = 0;
Begin
  Result := true;
  Repeat
    if counter >= Length(Listasumario) then IsDone := true
    else
      begin
      if ( (ListaSumario[counter].Balance=0) and (ListaSumario[counter].score=0) and
         (ListaSumario[counter].custom='') )then
        Delete(Listasumario,counter,1)
      else inc(counter);
      end;
  until IsDone;
  SaveSummaryToDisk;
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_Summary);

FINALIZATION
DoneCriticalSection(CS_Summary);


END. {End unit}

