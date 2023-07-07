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
  Classes, SysUtils, Nosogeneral, nosocrypto;

Type

  TPSOData = Record
    Mode    : integer;
    Hash    : string[32];
    owner   : string[32];
    Expire  : integer;
    Members : string;
    Params  : string;
  end;

  TPSOHeader = record
    Block : integer;
    count : integer;
  end;

  TPSOsArray = Array of TPSOData;

Function LoadPSOFileFromDisk():boolean;
Function SavePSOFileToDisk(BlockNumber : integer):boolean;
Function GetPSOsAsMemStream(out LMs:TMemoryStream):int64;
Function SavePSOsToFile(Const LStream:TMemoryStream):Boolean;

Function GetPSOValue(LValue:string;LParams:String):String;

Function AddNewPSO(LMode:Integer;LOwner:String;LExpire:integer;LParams:String):Boolean;
Function GetPSOsCopy():TPSOsArray;

CONST
  PSOsFileName : string = 'NOSODATA'+DirectorySeparator+'psos.dat';
  PSOTimestamp : string = '1';
  PSOBlock     : string = '2';
  PSOAction    : string = '3';
  PSOFee       : string = '4';
  PSODuration  : string = '5';
  PSOTarget    : string = '6';
  PSOMinSize   : string = '7';
  PSOMaxSize   : string = '8';
  PSOOverfill  : string = '9';
  PSOSource    : string = '10';

var
  PSOsArray    : Array of TPSOData;
  PSOHeader    : TPSOHeader;
  CS_PSOsArray : TRTLCriticalSection;

IMPLEMENTATION

{$REGION Internal functions}

{$ENDREGION}

Function LoadPSOFileFromDisk():boolean;
var
  MyStream : TMemoryStream;
  Counter  : integer;
  NewRec   : TPSOData;
Begin
  Result := false;
  MyStream := TMemoryStream.Create;
  EnterCriticalSection(CS_PSOsArray);
  PSOHeader := Default(TPSOHeader);
  SetLength(PSOsArray,0);
  If fileExists(PSOsFileName) then
    begin
    TRY
      MyStream.LoadFromFile(PSOsFileName);
      MyStream.Position := 0;
      MyStream.Read(PSOHeader, SizeOf(PSOHeader));
    EXCEPT ON E:Exception do
    END;
    if PSOHeader.count > 0 then
      begin
      For Counter := 1 to PSOHeader.count do
        begin
        NewRec   := Default(TPSOData);
        MyStream.Read(NewRec.Mode,Sizeof(NewRec.Mode));
        MyStream.Read(NewRec.Hash,Sizeof(NewRec.Hash));
        MyStream.Read(NewRec.owner,Sizeof(NewRec.Owner));
        MyStream.Read(NewRec.Expire,Sizeof(NewRec.Expire));
        NewRec.Members:=MyStream.GetString;;
        NewRec.Params:=MyStream.GetString;
        Insert(NewRec,PSOsArray,Length(PSOsArray));
        end;
      end;
    end;
  MyStream.Free;
  LeaveCriticalSection(CS_PSOsArray);
  Result := true;
  If not fileExists(PSOsFileName) then SavePSOFileToDisk(PSOHeader.Block);
End;

Function SavePSOFileToDisk(BlockNumber:integer):boolean;
var
  MyStream : TMemoryStream;
  counter  : integer ;
Begin
  Result := false;
  MyStream := TMemoryStream.Create;
  PSOHeader.Block:=BlockNumber;
  EnterCriticalSection(CS_PSOsArray);
  TRY
    PSOHeader.count:=Length(PSOsArray);
    MyStream.Write(PSOHeader,Sizeof(PSOHeader));
    if PSOHeader.count > 0 then
      begin
      For counter := 0 to Length(PSOsArray)-1 do
        begin
        MyStream.Write(PSOsArray[counter].Mode,sizeof(PSOsArray[counter].Mode));
        MyStream.Write(PSOsArray[counter].hash,sizeof(PSOsArray[counter].hash));
        MyStream.Write(PSOsArray[counter].Owner,sizeof(PSOsArray[counter].Owner));
        MyStream.Write(PSOsArray[counter].Expire,sizeof(PSOsArray[counter].Expire));
        MyStream.SetString(PSOsArray[counter].Members);
        MyStream.SetString(PSOsArray[counter].Params);
        end;
      end;
  EXCEPT ON EXCEPTION DO
  END;
  LeaveCriticalSection(CS_PSOsArray);
  MyStream.SaveToFile(PSOsFileName);
  MyStream.Free;
  Result := true;
End;

Function GetPSOsAsMemStream(out LMs:TMemoryStream):int64;
Begin
  Result := 0;
  //EnterCriticalSection();
    TRY
    LMs.LoadFromFile(PSOsFileName);
    result:= LMs.Size;
    LMs.Position:=0;
    EXCEPT ON E:Exception do
    END{Try};
  //LeaveCriticalSection();
End;

Function SavePSOsToFile(Const LStream:TMemoryStream):Boolean;
Begin
  result := false;
  //EnterCriticalSection();
    TRY
    LStream.SaveToFile(PSOsFileName);
    Result := true;
    EXCEPT ON E:Exception do
    END{Try};
  //LeaveCriticalSection();
End;

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

INITIALIZATION
InitCriticalSection(CS_PSOsArray);
LoadPSOFileFromDisk;


FINALIZATION
DoneCriticalSection(CS_PSOsArray);



END. {END UNIT}

