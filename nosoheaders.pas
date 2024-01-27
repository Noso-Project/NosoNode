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
Function GetHeadersLastBlock():Integer;
Function GetHeadersAsMemStream(out LMs:TMemoryStream):int64;
Function SaveStreamAsHeaders(Const LStream:TMemoryStream):Boolean;
Function LastHeadersString(FromBlock:integer):String;

// For tests
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
  NewData        : ResumenData;
  Opened         : boolean = false;
  PorperlyClosed : boolean = false;
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
    Opened := true;
    seek(fileResumen,filesize(fileResumen));
    write(fileResumen,NewData);
    closefile(FileResumen);
    PorperlyClosed := true;
  EXCEPT ON E:EXCEPTION DO
    begin
    ToDeepDeb('NosoHeaders,AddRecordToHeaders,'+E.Message);
    Result := false;
    end;
  END;
  if ( (opened) and (not PorperlyClosed) ) then closefile(FileResumen);
  LeaveCriticalSection(CS_HeadersFile);
End;

Function RemoveHeadersLastRecord():Boolean;
var
  Opened         : boolean = false;
  PorperlyClosed : boolean = false;
Begin
  Result := true;
  assignfile(FileResumen,ResumenFilename);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    Opened := true;
    seek(fileResumen,filesize(fileResumen)-1);
    truncate(fileResumen);
    closefile(FileResumen);
    PorperlyClosed := true;
  EXCEPT ON E:EXCEPTION DO
    begin
    ToDeepDeb('NosoHeaders,RemoveHeadersLastRecord,'+E.Message);
    Result := false;
    end;
  END;
  if ( (opened) and (not PorperlyClosed) ) then closefile(FileResumen);
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

// Returns the block number of the last record on headers
Function GetHeadersLastBlock():Integer;
var
  ThisData : ResumenData;
Begin
  Result := 0;
  ThisData := Default(ResumenData);
  assignfile(FileResumen,ResumenFilename);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    if filesize(FileResumen)>0 then
      begin
      seek(fileResumen,filesize(FileResumen)-1);
      Read(fileResumen,ThisData);
      result := ThisData.block;
      end;
    CloseFile(FileResumen);
  EXCEPT on E:Exception do
    begin
    ToDeepDeb('NosoHeaders,GetHeadersLastBlock,'+E.Message);
    end;
  END;
  LeaveCriticalSection(CS_HeadersFile);
End;

// Returns the headers file as a STREAM
Function GetHeadersAsMemStream(out LMs:TMemoryStream):int64;
Begin
  Result := 0;
  EnterCriticalSection(CS_HeadersFile);
    TRY
      LMs.LoadFromFile(ResumenFilename);
      result:= LMs.Size;
      LMs.Position:=0;
    EXCEPT ON E:Exception do
      begin
      ToDeepDeb('NosoHeaders,GetHeadersAsMemStream,'+E.Message);
      end;
    END;
  LeaveCriticalSection(CS_HeadersFile);
End;

// Save a provided stream as the headers file
Function SaveStreamAsHeaders(Const LStream:TMemoryStream):Boolean;
Begin
  result := false;
  EnterCriticalSection(CS_HeadersFile);
    TRY
    LStream.SaveToFile(ResumenFilename);
    Result := true;
    EXCEPT ON E:Exception do
      begin
      ToDeepDeb('NosoHeaders,SaveStreamAsHeaders,'+E.Message);
      end;
    END{Try};
  LeaveCriticalSection(CS_HeadersFile);
End;

// Returns the string for headers updates
Function LastHeadersString(FromBlock:integer):String;
var
  ThisData : ResumenData;
Begin
  result := '';
  if FromBlock<GetHeadersLastBlock-1008 then exit;
  assignfile(FileResumen,ResumenFilename);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    ThisData := Default(ResumenData);
    seek(fileResumen,FromBlock-100);
    While not Eof(fileResumen) do
      begin
      Read(fileResumen,ThisData);
      Result := Result+ThisData.block.ToString+':'+ThisData.blockhash+':'+ThisData.SumHash+' ';
      end;
    closefile(FileResumen);
  EXCEPT on E:Exception do
    begin
    ToDeepDeb('NosoHeaders,LastHeadersString,'+E.Message);
    end;
  END;
  LeaveCriticalSection(CS_HeadersFile);
  Result := Trim(Result);
End;

// Only a test function; should be removed
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

