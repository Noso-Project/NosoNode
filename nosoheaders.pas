unit NosoHeaders;

{
nosoHeaders 1.0
Dec 7th, 2023
Stand alone unit to control headers file.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Nosodebug;

Type

  ResumenData = Packed Record
    block : integer;
    blockhash : string[32];
    SumHash : String[32];
  end;

Function CreateHeadersFile():boolean;
Function AddRecordToHeaders():boolean;

var
  FileResumen     : file of ResumenData;
  ResumenFilename : string = 'NOSODATA'+DirectorySeparator+'blchhead.nos';
  CS_HeadersFile  : TRTLCriticalSection;

IMPLEMENTATION

// Creates a headers file. If it already exists, rewrite a new empty one.
Function CreateHeadersFile():boolean;
var
  MyStream : TMemoryStream;
Begin
  Result := True;
  MyStream := TMemoryStream.Create;
  EnterCriticalSection(CS_HeadersFile);
  TRY
    MYStream.SaveToFile(ResumenFilename);
  EXCEPT ON E:EXCEPTION DO
    begin
    Result := false;
    ToDeepDeb('NosoHeaders,CreateHeadersFile,'+E.Message);
    end;
  END;
  LeaveCriticalSection(CS_HeadersFile);
  MyStream.Free;
End;

Function AddRecordToHeaders():boolean;
Begin

End;

INITIALIZATION
InitCriticalSection(CS_HeadersFile);

FINALIZATION
DoneCriticalSection(CS_HeadersFile);

END.

