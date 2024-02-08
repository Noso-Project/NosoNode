unit nosodebug;

{
Nosodebug 1.3
September 22th, 2023
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

  TCoreManager = record
    ThName   : string;
    ThStart  : int64;
    ThLast   : int64;
    end;

  TFileManager = Record
    FiType   : string;
    FiFile   : string;
    FiPeer   : string;
    FiLast   : int64;
  end;

  TProcessCopy = array of TCoreManager;
  TFileMCopy   = array of TFileManager;

Procedure BeginPerformance(Tag:String);
Function EndPerformance(Tag:String):int64;
Function PerformanceToFile(Destination:String):boolean;

Procedure CreateNewLog(LogName: string; LogFileName:String = '');
Procedure ToLog(LogTag,NewLine : String);
Function GetLogLine(LogTag:string;out LineContent:string):boolean;

Procedure AddNewOpenThread(ThName:String;TimeStamp:int64);
Procedure UpdateOpenThread(ThName:String;TimeStamp:int64);
Procedure CloseOpenThread(ThName:String);
Function GetProcessCopy():TProcessCopy;

Procedure AddFileProcess(FiType, FiFile, FiPeer:String;TimeStamp:int64);
Function CloseFileProcess(FiType, FiFile, FiPeer:String;TimeStamp:int64):int64;
Function GetFileProcessCopy():TFileMCopy;

Procedure InitDeepDeb(LFileName:String;SysInfo:String='');
Procedure ToDeepDeb(LLine:String);
Function GetDeepDebLine(out LineContent:string):boolean;

var
  ArrPerformance : array of TPerformance;
  NosoDebug_UsePerformance : boolean = false;
  ArrNDLogs      : Array of TLogND;
  ArrNDCSs       : array of TRTLCriticalSection;
  ArrNDSLs       : array of TStringList;
  ArrProcess     : Array of TCoreManager;
  CS_ThManager   : TRTLCriticalSection;

  ArrFileMgr     : Array of TFileManager;
  CS_FileManager : TRTLCriticalSection;

  SLDeepDebLog   : TStringList;
  CS_DeepDeb     : TRTLCriticalSection;
  DeepDebFilename: String = '';

IMPLEMENTATION

{$REGION Performance}

{Starts a performance measure}
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

{Ends a performance}
Function EndPerformance(Tag:String):int64;
var
  counter  : integer;
  duration : int64 = 0;
Begin
  result := 0;
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
  Result := duration;
End;

Function PerformanceToFile(Destination:String):boolean;
var
  counter  : integer;
  Lines    : TStringList;
  ThisLine : String;
  Tag,count,max,average : string;
Begin
  Result := true;
  Lines := TStringlist.Create;
  Lines.Add('TAG                                           Count        Max    Average');
  for counter := 0 to high(ArrPerformance) do
    begin
    Tag := Format('%0:-40s',[ArrPerformance[counter].tag]);
    Count   := Format('%0:10s',[IntToStr(ArrPerformance[counter].Count)]);
    Max     := Format('%0:10s',[IntToStr(ArrPerformance[counter].Max)]);
    Average := Format('%0:10s',[IntToStr(ArrPerformance[counter].Average)]);
    ThisLine := Format('%s %s %s %s',[Tag,count,max,average]);
    Lines.Add(ThisLine);
    end;
  Lines.SaveToFile(Destination);
  Lines.Free;
End;

{$ENDREGION}

{$REGION Logs}

{private: verify that the file for the log exists}
Function InitializeLogFile(Filename:String;OptionText:string = ''):boolean;
var
  LFile : textfile;
Begin
  Result := true;
  if not fileexists(Filename) then
    begin
      TRY
      Assignfile(LFile, Filename);
      rewrite(LFile);
      if OptionText <> '' then
        Writeln(LFile,OptionText);
      Closefile(LFile);
      EXCEPT on E:Exception do
        begin
        ToDeepDeb('Nosodebug,InitializeLogFile,'+E.Message);
        Result := false;
        end;
      END; {Try}
    end;
End;

{private: if enabled, saves the line to the log file}
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
        ToDeepDeb('Nosodebug,SaveTextToDisk,'+E.Message);
      END; {Try}
    Closefile(LFile);
    end
  else if IOCode = 5 then
   {$I-}Closefile(LFile){$I+};
End;

{Creates a new log and assigns an optional file to save it}
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

{Adds one line to the specified log}
Procedure ToLog(LogTag,NewLine : String);
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

{Retireves the oldest line in the specified log, assigning value to LineContent}
Function GetLogLine(LogTag:string;out LineContent:string):boolean;
var
  counter : integer;
Begin
  Result:= False;
  For counter := 0 to length(ArrNDLogs)-1 do
    begin
    if ArrNDLogs[counter].tag = Uppercase(LogTag) then
      begin
      if ArrNDSLs[counter].Count>0 then
        begin
        EnterCriticalSection(ArrNDCSs[counter]);
        LineContent := ArrNDSLs[counter][0];
        Result := true;
        ArrNDSLs[counter].Delete(0);
        if ArrNDLogs[counter].ToDisk then SaveTextToDisk(LineContent,ArrNDLogs[counter].Filename);
        LeaveCriticalSection(ArrNDCSs[counter]);
        break;
        end;
      end;
    end;
End;

{Private: Free all data at close}
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

{$ENDREGION}

{$REGION Thread manager}

Procedure AddNewOpenThread(ThName:String;TimeStamp:int64);
var
  NewValue : TCoreManager;
Begin
  NewValue := Default(TCoreManager);
  NewValue.ThName  := ThName;
  NewValue.ThStart := TimeStamp;
  NewValue.ThLast  := TimeStamp;
  EnterCriticalSection(CS_ThManager);
  Insert(NewValue,ArrProcess,Length(ArrProcess));
  LeaveCriticalSection(CS_ThManager);
End;

Procedure UpdateOpenThread(ThName:String;TimeStamp:int64);
var
  counter : integer;
Begin
  EnterCriticalSection(CS_ThManager);
  for counter := 0 to High(ArrProcess) do
    begin
    if UpperCase(ArrProcess[counter].ThName) = UpperCase(ThName) then
      begin
      ArrProcess[counter].ThLast:=TimeStamp;
      Break;
      end;
    end;
  LeaveCriticalSection(CS_ThManager);
End;

Procedure CloseOpenThread(ThName:String);
var
  counter : integer;
Begin
  EnterCriticalSection(CS_ThManager);
  for counter := 0 to High(ArrProcess) do
    begin
    if UpperCase(ArrProcess[counter].ThName) = UpperCase(ThName) then
      begin
      Delete(ArrProcess,Counter,1);
      Break;
      end;
    end;
  LeaveCriticalSection(CS_ThManager);
End;

Function GetProcessCopy():TProcessCopy;
Begin
  Setlength(Result,0);
  EnterCriticalSection(CS_ThManager);
  Result := copy(ArrProcess,0,length(ArrProcess));
  LeaveCriticalSection(CS_ThManager);
End;

{$ENDREGION}

{$REGION Files manager}

Procedure AddFileProcess(FiType, FiFile, FiPeer:String;TimeStamp:int64);
var
  NewValue : TFileManager;
Begin
  NewValue := Default(TFileManager);
  NewValue.FiType  := FiType;
  NewValue.FiFile  := FiFile;
  NewValue.FiPeer  := FiPeer;
  NewValue.FiLast  := TimeStamp;
  EnterCriticalSection(CS_FileManager);
  Insert(NewValue,ArrFileMgr,Length(ArrFileMgr));
  LeaveCriticalSection(CS_FileManager);
End;

Function CloseFileProcess(FiType, FiFile, FiPeer:String;TimeStamp:int64):int64;
var
  counter : integer;
Begin
  Result := 0;
  EnterCriticalSection(CS_FileManager);
  for counter := 0 to High(ArrFileMgr) do
    begin
    if ( (UpperCase(ArrFileMgr[counter].FiType) = UpperCase(FiType)) and
         (UpperCase(ArrFileMgr[counter].FiFile) = UpperCase(FiFile)) and
         (UpperCase(ArrFileMgr[counter].FiPeer) = UpperCase(FiPeer)) ) then
      begin
      Result := TimeStamp - ArrFileMgr[counter].FiLast;
      Delete(ArrFileMgr,Counter,1);
      Break;
      end;
    end;
  LeaveCriticalSection(CS_FileManager);
End;

Function GetFileProcessCopy():TFileMCopy;
Begin
  Setlength(Result,0);
  EnterCriticalSection(CS_FileManager);
  Result := copy(ArrFileMgr,0,length(ArrFileMgr));
  LeaveCriticalSection(CS_FileManager);
End;

{$ENDREGION}

{$REGION Deep debug control}

Procedure InitDeepDeb(LFileName:String;SysInfo:String='');
Begin
  if DeepDebFilename<>'' then Exit;
  if InitializeLogFile(LFileName,SysInfo) then
    begin
    DeepDebFilename := LFileName;
    //ToDeepDeb(SysInfo);
    end;
End;


Procedure ToDeepDeb(LLine:String);
Begin
  EnterCriticalSection(CS_DeepDeb);
  SLDeepDebLog.Add(LLine);
  LeaveCriticalSection(CS_DeepDeb);
End;

Function GetDeepDebLine(out LineContent:string):boolean;
Begin
  result := false;
  if SLDeepDebLog.Count>0 then
    begin
    EnterCriticalSection(CS_DeepDeb);
    LineContent := SLDeepDebLog[0];
    SLDeepDebLog.Delete(0);
    Result := true;
    if DeepDebFilename<>'' then SaveTextToDisk(DateTimeToStr(Now)+' '+LineContent,DeepDebFilename);
    LeaveCriticalSection(CS_DeepDeb);
    end;
End;

{$ENDREGION}

INITIALIZATION
  SLDeepDebLog := TStringList.Create;
  Setlength(ArrPerformance,0);
  Setlength(ArrNDLogs,0);
  Setlength(ArrNDCSs,0);
  Setlength(ArrNDSLs,0);
  Setlength(ArrProcess,0);
  Setlength(ArrFileMgr,0);
  InitCriticalSection(CS_ThManager);
  InitCriticalSection(CS_FileManager);
  InitCriticalSection(CS_DeepDeb);


FINALIZATION
  DoneCriticalSection(CS_ThManager);
  DoneCriticalSection(CS_FileManager);
  DoneCriticalSection(CS_DeepDeb);
  FreeAllLogs;
  SLDeepDebLog.Free;

END. {END UNIT}

