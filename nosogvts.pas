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

INITIALIZATION
InitCriticalSection(CSGVTsArray);
InitCriticalSection(CSGVTsFile);
SetLength(ArrGVTs,0);
Assignfile(FileGVTs,GVTsFilename);

FINALIZATION
DoneCriticalSection(CSGVTsArray);
DoneCriticalSection(CSGVTsFile);

END. // End unit

