unit nosodebug;

{
Nosodebug 1.0
December 8th, 2022
Unit to implement debug functionalities on noso project apps.
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils;

type
  Tperformance = Record
    tag      : string;
    Start    : int64;
    Average  : int64;
    Max      : int64;
    Min      : int64;
    Count    : int64;
    Total    : int64;
    end;

  TLogND = record
    tag      : string;
    Count    : integer;
    ToDisk   : boolean;
    Filename : string;
    end;

Procedure BeginPerformance(Tag:String);
Procedure EndPerformance(Tag:String);
Procedure CreateNewLog(LogName: string; LogFileName:String = '');
Procedure AddLineToDebugLog(LogTag,NewLine : String);
Function GetLogLine(LogTag:string):String;

var
  ArrPerformance : array of TPerformance;
  NosoDebug_UsePerformance : boolean = false;
  ArrNDLogs  : Array of TLogND;
  ArrNDCSs   : array of TRTLCriticalSection;
  ArrNDSLs   : array of TStringList;

IMPLEMENTATION

Procedure BeginPerformance(Tag:String);
var
  counter : integer;
  NewData : TPerformance;
Begin
  if not NosoDebug_UsePerformance then exit;
  for counter := 0 to high(ArrPerformance) do
    begin
    if Tag = ArrPerformance[counter].tag then
      begin
      ArrPerformance[counter].Start:=GetTickCount64;
      Inc(ArrPerformance[counter].Count);
      exit;
      end;
    end;
  NewData := default(TPerformance);
  NewData.tag   :=tag;
  NewData.Min    :=99999;
  NewData.Start  :=GetTickCount64;
  NewData.Count  :=1;
  Insert(NewData,ArrPerformance,length(ArrPerformance));
End;

Procedure EndPerformance(Tag:String);
var
  counter  : integer;
  duration : int64;
Begin
  if not NosoDebug_UsePerformance then exit;
  for counter := 0 to high(ArrPerformance) do
    begin
    if tag = ArrPerformance[counter].tag then
      begin
      duration :=GetTickCount64-ArrPerformance[counter].Start;
      ArrPerformance[counter].Total  := ArrPerformance[counter].Total+Duration;
      ArrPerformance[counter].Average:=ArrPerformance[counter].Total div ArrPerformance[counter].Count;
      if duration>ArrPerformance[counter].Max then
        ArrPerformance[counter].Max := duration;
      if duration < ArrPerformance[counter].Min then
        ArrPerformance[counter].Min := duration;
      break;
      end;
    end;
End;

Procedure InitializeLogFile(Filename:String);
var
  LFile : textfile;
Begin
  if not fileexists(Filename) then
    begin
      TRY
      Assignfile(LFile, Filename);
      rewrite(LFile);
      Closefile(LFile);
      EXCEPT on E:Exception do

      END; {Try}
    end;
End;

Procedure SaveTextToDisk(TextLine, Filename:String);
var
  LFile  : textfile;
  IOCode : integer;
Begin
  Assignfile(LFile, Filename);
  {$I-}Append(LFile){$I+};
  IOCode := IOResult;
  If IOCode = 0 then
    begin
      TRY
        Writeln(LFile, TextLine);
      Except on E:Exception do

      END; {Try}
    Closefile(LFile);
    end
  else if IOCode = 5 then
   {$I-}Closefile(LFile){$I+};
End;

Procedure CreateNewLog(LogName: string; LogFileName:String = '');
var
  NewData : TLogND;
Begin
  NewData := Default(TLogND);
  NewData.tag:=Uppercase(Logname);
  NewData.Filename:=LogFileName;
  SetLength(ArrNDCSs,length(ArrNDCSs)+1);
  InitCriticalSection(ArrNDCSs[length(ArrNDCSs)-1]);
  SetLEngth(ArrNDSLs,length(ArrNDSLs)+1);
  ArrNDSLs[length(ArrNDSLs)-1] := TStringlist.Create;
  if LogFileName <> '' then
    begin
    InitializeLogFile(LogFileName);
    NewData.ToDisk:=true;
    end;
  Insert(NewData,ArrNDLogs,length(ArrNDLogs));
End;

Procedure AddLineToDebugLog(LogTag,NewLine : String);
var
  counter : integer;
Begin
  for counter := 0 to length(ArrNDLogs)-1 do
    begin
    if ArrNDLogs[counter].tag = Uppercase(LogTag) then
      begin
      EnterCriticalSection(ArrNDCSs[counter]);
      ArrNDSLs[counter].Add(NewLine);
      Inc(ArrNDLogs[counter].Count);
      LeaveCriticalSection(ArrNDCSs[counter]);
      end;
    end;
End;

Function GetLogLine(LogTag:string):String;
var
  counter : integer;
Begin
  Result:= '';
  For counter := 0 to length(ArrNDLogs)-1 do
    begin
    if ArrNDLogs[counter].tag = Uppercase(LogTag) then
      begin
      if ArrNDSLs[counter].Count>0 then
        begin
        EnterCriticalSection(ArrNDCSs[counter]);
        result := ArrNDSLs[counter][0];
        ArrNDSLs[counter].Delete(0);
        if ArrNDLogs[counter].ToDisk then SaveTextToDisk(result,ArrNDLogs[counter].Filename);
        LeaveCriticalSection(ArrNDCSs[counter]);
        break;
        end;
      end;
    end;
End;

{Free all data at close}
Procedure FreeAllLogs;
var
  counter : integer;
Begin
  for counter := 0 to length(ArrNDLogs)-1 do
    begin
    ArrNDSLs[counter].Free;
    DoneCriticalsection(ArrNDCSs[counter]);
    end;
End;

INITIALIZATION
  Setlength(ArrPerformance,0);
  Setlength(ArrNDLogs,0);
  Setlength(ArrNDCSs,0);
  Setlength(ArrNDSLs,0);

FINALIZATION
  FreeAllLogs;

END. {END UNIT}

