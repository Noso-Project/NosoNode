unit NosoHeaders;

{
nosoHeaders 1.1
Jan 31th, 2024
Stand alone unit to control headers file.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Nosodebug,nosocrypto, nosogeneral;

Type

  ResumenData = Packed Record
    block : integer;
    blockhash : string[32];
    SumHash : String[32];
  end;

Procedure SetResumenHash();
function GetResumenHash():String;
Function SetHeadersFileName(Filename:String):Boolean;
Function CreateHeadersFile():boolean;
Function AddRecordToHeaders(BlockNumber:int64;BlockHash,SumHash:String):boolean;
Function RemoveHeadersLastRecord():Boolean;
Function GetHeadersHeigth():integer;
Function GetHeadersLastBlock():Integer;
Function GetHeadersAsMemStream(var LMs:TMemoryStream):int64;
Function SaveStreamAsHeaders(var LStream:TMemoryStream):Boolean;
Function LastHeadersString(FromBlock:integer):String;



var
  FileResumen     : file of ResumenData;
  MyResumenHash   : String = '';
  ResumenFilename : string = {'NOSODATA'+DirectorySeparator+}'blchhead.nos';
  CS_HeadersFile  : TRTLCriticalSection;

IMPLEMENTATION

{$REGION Headers file access}

// Sets the hash value
Procedure SetResumenHash();
Begin
  EnterCriticalSection(CS_HeadersFile);
  MyResumenHash := HashMD5File(ResumenFilename);
  LeaveCriticalSection(CS_HeadersFile);
End;

// Returns the hash of the file
function GetResumenHash():String;
Begin
  EnterCriticalSection(CS_HeadersFile);
  result := MyResumenHash;
  LeaveCriticalSection(CS_HeadersFile);
End;

// Sets the headers file path and name
Function SetHeadersFileName(Filename:String):Boolean;
Begin
  Result := true;
  ResumenFilename := Filename;
  assignfile(FileResumen,ResumenFilename);
  if not Fileexists(ResumenFilename) then CreateEmptyFile(ResumenFilename);
  SetResumenHash();
End;

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
  filemode := 2;
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
  filemode := 2;
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
var
  Opened         : boolean = false;
  PorperlyClosed : boolean = false;
Begin
  Result := -1;
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    Opened := true;
    Result := filesize(fileResumen)-1;
    closefile(FileResumen);
    PorperlyClosed := true;
  EXCEPT on E:Exception do
    begin
    ToDeepDeb('NosoHeaders,GetHeadersHeigth,'+E.Message);
    end;
  END;
  if ( (opened) and (not PorperlyClosed) ) then closefile(FileResumen);
  LeaveCriticalSection(CS_HeadersFile);
End;

// Returns the block number of the last record on headers
Function GetHeadersLastBlock():Integer;
var
  ThisData : ResumenData;
  Opened         : boolean = false;
  PorperlyClosed : boolean = false;
Begin
  Result := 0;
  ThisData := Default(ResumenData);
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    Opened := true;
    if filesize(FileResumen)>0 then
      begin
      seek(fileResumen,filesize(FileResumen)-1);
      Read(fileResumen,ThisData);
      result := ThisData.block;
      end;
    CloseFile(FileResumen);
    PorperlyClosed := true;
  EXCEPT on E:Exception do
    begin
    ToDeepDeb('NosoHeaders,GetHeadersLastBlock,'+E.Message);
    end;
  END;
  if ( (opened) and (not PorperlyClosed) ) then closefile(FileResumen);
  LeaveCriticalSection(CS_HeadersFile);
End;

// Returns the headers file as a STREAM
Function GetHeadersAsMemStream(var LMs:TMemoryStream):int64;
Begin
  Result := 0;
  BeginPerformance('GetHeadersAsMemStream');
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
  EndPerformance('GetHeadersAsMemStream');
End;

// Save a provided stream as the headers file
Function SaveStreamAsHeaders(var LStream:TMemoryStream):Boolean;
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
  Opened         : boolean = false;
  PorperlyClosed : boolean = false;
Begin
  result := '';
  if FromBlock<GetHeadersLastBlock-1008 then exit;
  EnterCriticalSection(CS_HeadersFile);
  TRY
    reset(FileResumen);
    Opened := true;
    ThisData := Default(ResumenData);
    seek(fileResumen,FromBlock-100);
    While not Eof(fileResumen) do
      begin
      Read(fileResumen,ThisData);
      Result := Result+ThisData.block.ToString+':'+ThisData.blockhash+':'+ThisData.SumHash+' ';
      end;
    closefile(FileResumen);
    PorperlyClosed := true;
  EXCEPT on E:Exception do
    begin
    ToDeepDeb('NosoHeaders,LastHeadersString,'+E.Message);
    end;
  END;
  //if ( (opened) and (not PorperlyClosed) ) then closefile(FileResumen);
  LeaveCriticalSection(CS_HeadersFile);
  Result := Trim(Result);
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_HeadersFile);
assignfile(FileResumen,ResumenFilename);

FINALIZATION
DoneCriticalSection(CS_HeadersFile);

END.

