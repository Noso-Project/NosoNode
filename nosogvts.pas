unit nosogvts;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, nosodebug, nosocrypto;

type
  TGVT = packed record
    number   : string[2];
    owner    : string[32];
    Hash     : string[64];
    control  : integer;
    end;

  Function CreateGVTsFile():boolean;
  Function GetGVTsAsStream(out LStream:TMemoryStream):int64;
  Function SaveStreamAsGVTs(Const LStream:TMemoryStream):Boolean;
  Procedure GetGVTsFileData();
  Procedure SaveGVTs();
  Function ChangeGVTOwner(Lnumber:integer;OldOwner,NewOWner:String): integer;
  Function GetGVTIndex(Index:Integer):TGVT;
  Function GetGVTLength:integer;
  Function CountAvailableGVTs():Integer;
  Function GetGVTPrice(available:integer;ToSell:boolean = false):int64;

CONST
  GVTBaseValue     = 70000000000;

var
  GVTsFilename        : string= 'NOSODATA'+DirectorySeparator+'gvts.psk';
  FileGVTs            : file of TGVT;
  ArrGVTs             : array of TGVT;
  CSGVTsArray         : TRTLCriticalSection;
  CSGVTsFile          : TRTLCriticalSection;
  MyGVTsHash          : string = '';

IMPLEMENTATION

// Creates a GVTs file. If it already exists, rewrite a new empty one.
Function CreateGVTsFile():boolean;
var
  MyStream : TMemoryStream;
Begin
  Result := True;
  MyStream := TMemoryStream.Create;
  EnterCriticalSection(CSGVTsFile);
  TRY
    MYStream.SaveToFile(GVTsFilename);
  EXCEPT ON E:EXCEPTION DO
    begin
    Result := false;
    ToDeepDeb('NosoGVTs,CreateGVTsFile,'+E.Message);
    end;
  END;
  LeaveCriticalSection(CSGVTsFile);
  MyStream.Free;
End;

// Loads the GVTs file into a stream
Function GetGVTsAsStream(out LStream:TMemoryStream):int64;
Begin
  Result := 0;
  EnterCriticalSection(CSGVTsFile);
    TRY
    LStream.LoadFromFile(GVTsFilename);
    result:= LStream.Size;
    LStream.Position:=0;
    EXCEPT ON E:Exception do
      begin
      ToDeepDeb('NosoGVTs,GetGVTsAsStream,'+E.Message);
      end;
    END{Try};
  LeaveCriticalSection(CSGVTsFile);
End;

// Save a stream as the GVT file
Function SaveStreamAsGVTs(Const LStream:TMemoryStream):Boolean;
Begin
  result := false;
  EnterCriticalSection(CSGVTsFile);
    TRY
    LStream.SaveToFile(GVTsFilename);
    Result := true;
    EXCEPT ON E:Exception do
      begin
      ToDeepDeb('NosoGVTs,SaveStreamAsGVTs,'+E.Message);
      end;
    END{Try};
  LeaveCriticalSection(CSGVTsFile);
  MyGVTsHash := HashMD5File(GVTsFilename);
End;

Procedure GetGVTsFileData();
var
  counter : integer;
Begin
  EnterCriticalSection(CSGVTsFile);
  EnterCriticalSection(CSGVTsArray);
  Assignfile(FileGVTs, GVTsFilename);
  TRY
  reset(FileGVTs);
  Setlength(ArrGVTs,filesize(FileGVTs));
  For counter := 0 to filesize(FileGVTs)-1 do
    begin
    seek(FileGVTs,counter);
    read(FileGVTs,ArrGVTs[counter]);
    end;
  Closefile(FileGVTs);
  EXCEPT ON E:Exception do
    begin
    ToDeepDeb('NosoGVTs,GetGVTsFileData,'+E.Message);
    end;
  END;
  LeaveCriticalSection(CSGVTsArray);
  LeaveCriticalSection(CSGVTsFile);
  MyGVTsHash := HashMD5File(GVTsFilename);
End;

Procedure SaveGVTs();
var
  counter : integer;
Begin
  EnterCriticalSection(CSGVTsFile);
  EnterCriticalSection(CSGVTsArray);
  TRY
  rewrite(FileGVTs);
  For counter := 0 to length(ArrGVTs)-1 do
    begin
    seek(FileGVTs,counter);
    write(FileGVTs,ArrGVTs[counter]);
    end;
  Closefile(FileGVTs);
  EXCEPT ON E:Exception do
    ToDeepDeb('NosoGVTs,SaveGVTs,'+E.Message);
  END;
  LeaveCriticalSection(CSGVTsArray);
  LeaveCriticalSection(CSGVTsFile);
  MyGVTsHash := HashMD5File(GVTsFilename);
End;

Function GetGVTIndex(Index:Integer):TGVT;
Begin
  result := Default(TGVT);
  if index > GetGVTLength-1 then exit;
  EnterCriticalSection(CSGVTsArray);
  Result := ArrGVTs[index];
  LeaveCriticalSection(CSGVTsArray);
End;

Function GetGVTLength:integer;
Begin
  EnterCriticalSection(CSGVTsArray);
  Result := length(ArrGVTs);
  LeaveCriticalSection(CSGVTsArray);
End;

Function ChangeGVTOwner(Lnumber:integer;OldOwner,NewOWner:String): integer;
var
  LData : TGVT;
Begin
  result := 0;
  if LNumber > 99 then result := 1;
  LData := GetGVTIndex(Lnumber);
  if LData.owner <> OldOwner then result := 2;
  if not IsValidHashAddress(NewOWner) then result := 3;
  if result = 0 then
    begin
    EnterCriticalSection(CSGVTsArray);
    ArrGVTs[Lnumber].owner := NewOWner;
    LeaveCriticalSection(CSGVTsArray);
    end;
End;

Function CountAvailableGVTs():Integer;
var
  counter : integer;
Begin
  Result := 0;
  EnterCriticalSection(CSGVTsArray);
  for counter := 0 to length(ArrGVTs)-1 do
     if ArrGVTs[counter].owner = 'NpryectdevepmentfundsGE' then Inc(Result);
  LeaveCriticalSection(CSGVTsArray);
End;

Function GetGVTPrice(available:integer;ToSell:boolean = false):int64;
var
  counter   : integer;
Begin
  result   := GVTBaseValue;
  available:= 40-available;
  for counter := 1 to available do
     result := (result *110) div 100;
  if result < GVTBaseValue then result := GVTBaseValue;
  if ToSell then Result := (result *85) div 100;
End;

INITIALIZATION
InitCriticalSection(CSGVTsArray);
InitCriticalSection(CSGVTsFile);
SetLength(ArrGVTs,0);
Assignfile(FileGVTs,GVTsFilename);

FINALIZATION
DoneCriticalSection(CSGVTsArray);
DoneCriticalSection(CSGVTsFile);

END. // End unit

