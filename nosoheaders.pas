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
Function AddRecordToHeaders(BlockNumber:int64;BlockHash,SumHash:String):boolean;
Function RemoveHeadersLastRecord():Boolean;
Function GetHeadersHeigth():integer;
Function FixHeaders(LastBlock:integer = -1):integer;

var
  FileResumen     : file of ResumenData;
  ResumenFilename : string = 'NOSODATA'+DirectorySeparator+'blchhead.nos';
  CS_HeadersFile  : TRTLCriticalSection;

IMPLEMENTATION

{$REGION Headers file access}

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

Function AddRecordToHeaders(BlockNumber:int64;BlockHash,SumHash:String):boolean;
var
  NewData : ResumenData;
Begin
  Result := true;
  NewData           := Default(ResumenData);
  NewData.block     := BlockNumber;
  NewData.blockhash := BlockHash;
  NewData.SumHash   := SumHash;
  assignfile(FileResumen,ResumenFilename);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    seek(fileResumen,filesize(fileResumen));
    write(fileResumen,NewData);
    closefile(FileResumen);
  EXCEPT ON E:EXCEPTION DO
    begin
    ToDeepDeb('NosoHeaders,AddRecordToHeaders,'+E.Message);
    Result := false;
    end;
  END;
  LeaveCriticalSection(CS_HeadersFile);
End;

Function RemoveHeadersLastRecord():Boolean;
Begin
  Result := true;
  assignfile(FileResumen,ResumenFilename);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    seek(fileResumen,filesize(fileResumen)-1);
    truncate(fileResumen);
    closefile(FileResumen);
  EXCEPT ON E:EXCEPTION DO
    begin
    ToDeepDeb('NosoHeaders,RemoveHeadersLastRecord,'+E.Message);
    Result := false;
    end;
  END;
  LeaveCriticalSection(CS_HeadersFile);
End;

Function GetHeadersHeigth():integer;
Begin
  Result := -1;
  assignfile(FileResumen,ResumenFilename);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    Result := filesize(fileResumen)-1;
    closefile(FileResumen);
  EXCEPT on E:Exception do
    begin
    ToDeepDeb('NosoHeaders,GetHeadersHeigth,'+E.Message);
    end;
  END;
  LeaveCriticalSection(CS_HeadersFile);
End;

Function FixHeaders(LastBlock:integer = -1):integer;
var
  TempArray : array of ResumenData;
  Counter   : integer = 0;
  ThisData  : ResumenData;
Begin
  result := 0;
  assignfile(FileResumen,ResumenFilename);
  SetLength(TempArray,0);
  reset(FileResumen);
  if LastBlock = -1 then SetLength(TempArray,Filesize(FileResumen))
  else SetLength(TempArray,LastBlock+1);
  While not eof(FileResumen) do
    begin
    seek(FileResumen, Counter);
    Read(FileResumen, ThisData);
    if ( (ThisData.block>0) and (ThisData.Block <length(TempArray)) ) then
      begin
      TempArray[ThisData.block] := ThisData;
      end;
    Inc(counter);
    end;
  for counter := 0 to length(TempArray)-1 do
    begin
    if TempArray[counter].block <> counter then
      begin
      TempArray[counter].block := counter;
      TempArray[counter].blockhash:='MISS';
      TempArray[counter].SumHash:='MISS';
      Inc(Result);
      end;
    seek(FileResumen,counter);
    write(fileresumen,TempArray[counter]);
    end;
  closefile(FileResumen);
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_HeadersFile);

FINALIZATION
DoneCriticalSection(CS_HeadersFile);

END.

