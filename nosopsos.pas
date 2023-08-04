unit nosopsos;

{
nosopsos 1.0
May 30th, 2023
Stand alone unit to handle all PSOs (active and expired) on noso mainnet.
Required: Nosogeneral
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, Nosogeneral, nosocrypto, nosodebug;

Type

  TPSOData = Record
    Mode    : integer;
    Hash    : string;
    owner   : string;
    Expire  : integer;
    Members : string;
    Params  : string;
  end;

  TMNsLock = Record
    address : string[32];
    expire  : integer;
  end;

  TPSOHeader = record
    Block    : integer;
    MNsLock  : integer;
    count    : integer;
  end;

  TPSOsArray = Array of TPSOData;

  // File access
Function GEtPSOHEadersFromFile:Boolean;
Function LoadPSOFileFromDisk():boolean;
Function SavePSOFileToDisk(BlockNumber : integer):boolean;
Function GetPSOsAsMemStream(out LMs:TMemoryStream):int64;
Function SavePSOsToFile(Const LStream:TMemoryStream):Boolean;

// Locked Masternodes control
Function AddLockedMM(Address:string;block:integer):Boolean;
Function ClearExpiredLockedMNs(BlockNumber:integer):integer;
Function IsLockedMN(Address:String):Boolean;

// PSOHeaders control
Function GetPSOHeaders():TPSOHeader;
Procedure SetPSOHeaders(NewData:TPSOHeader);

Function GetPSOValue(LValue:string;LParams:String):String;

Function AddNewPSO(LMode:Integer;LOwner:String;LExpire:integer;LParams:String):Boolean;
Function GetPSOsCopy():TPSOsArray;

CONST
  PSOsFileName       : string = 'NOSODATA'+DirectorySeparator+'psos.dat';
  MNsLockExpireLapse : integer = 2016;
  PSOTimestamp       : string = '1';
  PSOBlock           : string = '2';
  PSOAction          : string = '3';
  PSOFee             : string = '4';
  PSODuration        : string = '5';
  PSOTarget          : string = '6';
  PSOMinSize         : string = '7';
  PSOMaxSize         : string = '8';
  PSOOverfill        : string = '9';
  PSOSource          : string = '10';

var
  PSOsArray    : Array of TPSOData;
  MNSLockArray : Array of TMNsLock;
  PSOHeader    : TPSOHeader;
  PSOFileHash  : String = '';
  CS_PSOsArray : TRTLCriticalSection;
  CS_PSOFile   : TRTLCriticalSection;
  CS_LockedMNs : TRTLCriticalSection;
  CS_PSOHeaders: TRTLCriticalSection;

IMPLEMENTATION

{$REGION Internal functions}

{$ENDREGION}

{$REGION File access}

Function GEtPSOHEadersFromFile:Boolean;
var
  MyStream   : TMemoryStream;
  counter    : integer;
  MNData     : TMNsLock;
  LPSOHeader : TPSOHeader;
Begin
  MyStream := TMemoryStream.Create;
  MyStream.LoadFromFile(PSOsFileName);
  SetLEngth(MNSLockArray,0);
  MyStream.Position := 0;
  MyStream.ReadBuffer(LPSOHeader, SizeOf(PSOHeader));
  SetPSOHeaders(LPSOHeader);
  for counter := 0 to GetPSOHeaders.MNsLock-1 do
    begin
    MNData := Default(TMNsLock);
    MyStream.Read(MNData,sizeof(MNData));
    AddLineToDebugLog('console',counter.ToString+' '+MNData.address+' '+MNData.expire.ToString );
    Insert(MNData,MNSLockArray,length(MNSLockArray));
    end;
  MyStream.Free;
End;

Function LoadPSOFileFromDisk():boolean;
var
  MyStream  : TMemoryStream;
  Counter   : integer;
  NewRec    : TPSOData;
  MNData    : TMNsLock;
  StrSize   : int64;
  NewHeader : TPSOHeader;
Begin
  Result := false;
  MyStream := TMemoryStream.Create;
  PSOHeader := Default(TPSOHeader);
  SetLength(PSOsArray,0);
  SetLength(MNSLockArray,0);
  StrSize := GetPSOsAsMemStream(MyStream);
  If StrSize > 0 then
    begin
    MyStream.Position := 0;
    MyStream.Read(NewHeader, SizeOf(NewHeader));
    SetPSOHeaders(NewHeader);
    EnterCriticalSection(CS_LockedMNs);
    for counter := 0 to NewHeader.MNsLock-1 do
      begin
      MNData := Default(TMNsLock);
      MyStream.Read(MNData,sizeof(MNData));
      Insert(MNData,MNSLockArray,length(MNSLockArray));
      end;
    LeaveCriticalSection(CS_LockedMNs);
    EnterCriticalSection(CS_PSOsArray);
    for Counter := 0 to NewHeader.count-1 do
      begin
      NewRec.Mode    := MyStream.ReadWord;
      NewRec.Hash    := MyStream.GetString;
      NewRec.Owner   := MyStream.GetString;
      NewRec.Expire  := MyStream.ReadDWord;
      NewRec.Members := MyStream.GetString;
      NewRec.Params  := MyStream.GetString;
      Insert(NewRec,PSOsArray,Length(PSOsArray));
      end;
    LeaveCriticalSection(CS_PSOsArray);
    end;
  MyStream.Free;
  Result := true;
  If not fileExists(PSOsFileName) then SavePSOFileToDisk(PSOHeader.Block)
  else PSOFileHash := HashMD5File(PSOsFileName);
End;

Function SavePSOFileToDisk(BlockNumber:integer):boolean;
var
  MyStream  : TMemoryStream;
  counter   : integer ;
  NewHeader : TPSOHeader;
Begin
  Result := false;
  MyStream := TMemoryStream.Create;
  NewHeader := GetPSOHeaders;
  NewHeader.Block   :=BlockNumber;
  NewHeader.count   :=Length(PSOsArray);
  NewHeader.MNsLock :=Length(MNSLockArray);
  SetPSOHeaders(NewHeader);
  EnterCriticalSection(CS_PSOsArray);

  TRY
    MyStream.Write(NewHeader,Sizeof(PSOHeader));
    EnterCriticalSection(CS_LockedMNs);
    For counter := 0 to NewHeader.MNsLock-1 do
        MyStream.Write(MNSLockArray[counter],Sizeof(MNSLockArray[counter]));
    LeaveCriticalSection(CS_LockedMNs);
    EnterCriticalSection(CS_PSOsArray);
    For counter := 0 to Length(PSOsArray)-1 do
      begin
      MyStream.WriteWord(PSOsArray[counter].Mode);
      MyStream.SetString(PSOsArray[counter].hash);
      MyStream.SetString(PSOsArray[counter].owner);
      MyStream.WriteDWord(PSOsArray[counter].Expire);
      MyStream.SetString(PSOsArray[counter].Members);
      MyStream.SetString(PSOsArray[counter].Params);
      end;
    LeaveCriticalSection(CS_PSOsArray);
  EXCEPT ON EXCEPTION DO
  END;
  SavePSOsToFile(MyStream);
  MyStream.Free;
  Result := true;
  PSOFileHash := HashMD5File(PSOsFileName);
End;

Function GetPSOsAsMemStream(out LMs:TMemoryStream):int64;
Begin
  Result := 0;
  EnterCriticalSection(CS_PSOFile);
    TRY
    LMs.LoadFromFile(PSOsFileName);
    result:= LMs.Size;
    LMs.Position:=0;
    EXCEPT ON E:Exception do
    END{Try};
  LeaveCriticalSection(CS_PSOFile);
End;

Function SavePSOsToFile(Const LStream:TMemoryStream):Boolean;
Begin
  result := false;
  EnterCriticalSection(CS_PSOFile);
    TRY
    LStream.SaveToFile(PSOsFileName);
    Result := true;
    EXCEPT ON E:Exception do
    END{Try};
  LeaveCriticalSection(CS_PSOFile);
End;

{$ENDREGION}

{$REGION Locked Masternodes}

Function AddLockedMM(Address:string;block:integer):Boolean;
var
  counter : integer;
  Exists  : boolean = false;
  NewRec  : TMNsLock;
Begin
  result := false;
  EnterCriticalSection(CS_LockedMNs);
  for counter := 0 to length(MNSLockArray)-1 do
    begin
    if MNSLockArray[counter].address=Address then
      begin
      Exists := true;
      Break;
      end;
    end;
  If Not Exists then
    begin
    NewRec.address:=address;
    NewRec.expire:=Block+MNsLockExpireLapse;
    Insert(NewRec,MNSLockArray,length(MNSLockArray));
    Result := true;
    end;
  LeaveCriticalSection(CS_LockedMNs);
End;

Function ClearExpiredLockedMNs(BlockNumber:integer):integer;
var
  counter : integer = 0;
  IsDone  : boolean = false;
Begin
  Result :=0;
  EnterCriticalSection(CS_LockedMNs);
  Repeat
   if Counter >= Length(MNSLockArray) then IsDOne := true
   else
      begin
      if MNSLockArray[counter].expire <= blocknumber then
         begin
         Delete(MNSLockArray,counter,1);
         Inc(Result);
         end
      else Inc(Counter);
      end;
  until IsDone;
  LeaveCriticalSection(CS_LockedMNs);
End;

Function IsLockedMN(Address:String):Boolean;
var
  counter : integer;
Begin
  Result :=False;
  EnterCriticalSection(CS_LockedMNs);
  For counter := 0 to length(MNSLockArray)-1 do
    begin
    if MNSLockArray[counter].address= address then
       begin
       result := true;
       break;
       end;
    end;
  LeaveCriticalSection(CS_LockedMNs);
End;

{$ENDREGION}

{$REGION PSOHeaders control}

Function GetPSOHeaders():TPSOHeader;
Begin
  EnterCriticalSection(CS_PSOHeaders);
  Result := PSOHeader;
  LeaveCriticalSection(CS_PSOHeaders);
End;

Procedure SetPSOHeaders(NewData:TPSOHeader);
Begin
  EnterCriticalSection(CS_PSOHeaders);
  PSOHeader := NewData;
  LeaveCriticalSection(CS_PSOHeaders);
End;

{$ENDREGION}

{$REGION PSOs control}

Function GetPSOValue(LValue:String;LParams:String):string;
var
  counter  : integer = 0;
  ThisItem : String;
  ILabel   : String;
  IValue   : string;
Begin
  Result := '';
  LParams := StringReplace(LParams,';',' ',[rfReplaceAll, rfIgnoreCase]);
  repeat
    ThisItem := Parameter(LParams,Counter);
    If ThisItem <> '' then
      begin
      ThisItem := StringReplace(ThisItem,':',' ',[rfReplaceAll, rfIgnoreCase]);
      ILabel   :=  Parameter(ThisItem,0);
      IValue   :=  Parameter(ThisItem,1);
      If ILabel = LValue then Exit(IValue);
      end;
    Inc(counter);
  until thisItem = '' ;
End;

Function AddNewPSO(LMode:Integer;LOwner:String;LExpire:integer;LParams:String):Boolean;
var
  Counter  : integer;
  NewRec   : TPSOData;
Begin
  NewRec := Default(TPSOData);
  NewRec.Mode :=Lmode;
  NewRec.owner:=LOwner;
  NewRec.Expire:=LExpire;
  NewRec.Hash:=HashMD5String(LOwner+LParams+IntToStr(LMode));
  NewRec.Members:='';
  NewRec.Params:=LParams;
  EnterCriticalSection(CS_PSOsArray);
  Insert(NewRec,PSOsArray,Length(PSOsArray));
  LeaveCriticalSection(CS_PSOsArray);
End;

Function GetPSOsCopy():TPSOsArray;
Begin
  SetLength(Result,0);
  EnterCriticalSection(CS_PSOsArray);
  Result := copy(PSOsArray,0,length(PSOsArray));
  LeaveCriticalSection(CS_PSOsArray);
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_PSOsArray);
InitCriticalSection(CS_PSOFile);
InitCriticalSection(CS_LockedMNs);
InitCriticalSection(CS_PSOHeaders);



FINALIZATION
DoneCriticalSection(CS_PSOsArray);
DoneCriticalSection(CS_PSOFile);
DoneCriticalSection(CS_LockedMNs);
DoneCriticalSection(CS_PSOHeaders);



END. {END UNIT}

