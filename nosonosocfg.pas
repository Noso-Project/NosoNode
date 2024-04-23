unit NosoNosoCFG;

{
NosoNosoCFG 1.1
March 23, 2024
Stand alone unit to control nosocfg file and functionalitys
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, strutils,
  nosodebug, nosogeneral, nosotime, nosocrypto;

Procedure SetCFGHash();
Function GetCFGHash():String;

Procedure SetCFGFilename(Fname:String);
Function SaveCFGToFile(Content:String):Boolean;
Procedure GetCFGFromFile();
Procedure SetCFGDataStr(Content:String);
Function GetCFGDataStr(LParam:integer=-1):String;
Procedure AddCFGData(DataToAdd:String;CFGIndex:Integer);
Procedure RemoveCFGData(DataToRemove:String;CFGIndex:Integer);
Procedure SetCFGData(DataToSet:String;CFGIndex:Integer);
Procedure RestoreCFGData();
Procedure ClearCFGData(Index:string);
Function IsSeedNode(IP:String):boolean;

var
  CFGFilename       : string= 'nosocfg.psk';
  CFGFile           : Textfile;
  MyCFGHash         : string = '';
  CS_CFGFile        : TRTLCriticalSection;
  CS_CFGData        : TRTLCriticalSection;
  CS_CFGHash        : TRTLCriticalSection;
  NosoCFGString     : string = '';
  LasTimeCFGRequest : int64 = 0;
  DefaultNosoCFG    : String = // CFG parameters
                            {0 Mainnet mode}'NORMAL '+
                            {1 Seed nodes  }'20.199.50.27;8080:107.173.210.55;8080:5.230.55.203;8080:141.11.192.215;8080:4.233.61.8;8080:84.247.143.153;8080:23.95.216.80;8080:64.69.43.225;8080:142.171.231.9;8080: '+
                            {2 NTP servers }'ts2.aco.net:hora.roa.es:time.esa.int:time.stdtime.gov.tw:stratum-1.sjc02.svwh.net:ntp1.sp.se:1.de.pool.ntp.org:ntps1.pads.ufrj.br:utcnist2.colorado.edu:tick.usask.ca:ntp1.st.keio.ac.jp: '+
                            {3 DEPRECATED  }'null: '+
                            {4 DEPRECATED  }'null: '+
                            {5 FREZZED     }'NpryectdevepmentfundsGE:';


IMPLEMENTATION

{$REGION CFG hash}

Procedure SetCFGHash();
Begin
  EnterCriticalSection(CS_CFGHash);
  MyCFGHash := HashMD5String(GetCFGDataStr);
  LeaveCriticalSection(CS_CFGHash);
End;

Function GetCFGHash():String;
Begin
  EnterCriticalSection(CS_CFGHash);
  Result := MyCFGHash;
  LeaveCriticalSection(CS_CFGHash);
End;

{$ENDREGION CFG hash}

{$REGION File access}

Procedure SetCFGFilename(Fname:String);
var
  defseeds : string = '';
Begin
  CFGFilename := Fname;
  AssignFile(CFGFile, CFGFilename);
  if not fileexists(CFGFilename) then
    begin
    SaveCFGToFile(DefaultNosoCFG);
    GetCFGFromFile;
    Defseeds := SendApiRequest('https://raw.githubusercontent.com/Noso-Project/NosoWallet/main/defseeds.nos');
    if defseeds <> '' then
      begin
      SetCFGData(Defseeds,1);
      Tolog('console','Defaults seeds downloaded from trustable source');
      end
    else
      begin
      ToLog('console','Unable to download default seeds. Please, use a fallback');
      end;
    end;
  GetCFGFromFile;
  SetCFGHash();
End;

Function SaveCFGToFile(Content:String):Boolean;
Begin
  EnterCriticalSection(CS_CFGFile);
  Result := SaveTextToDisk(CFGFilename,Content);
  SetCFGDataStr(Content);
  LeaveCriticalSection(CS_CFGFile);
End;

Procedure GetCFGFromFile();
Begin
  EnterCriticalSection(CS_CFGFile);
  SetCFGDataStr(LoadTextFromDisk(CFGFilename));
  LeaveCriticalSection(CS_CFGFile);
End;

{$ENDREGION File access}

{$REGION Data access}

Procedure SetCFGDataStr(Content:String);
Begin
  EnterCriticalSection(CS_CFGData);
  NosoCFGString := Content;
  LeaveCriticalSection(CS_CFGData);
  SetCFGHash;
End;

Function GetCFGDataStr(LParam:integer=-1):String;
Begin
  EnterCriticalSection(CS_CFGData);
  if LParam<0 then Result := NosoCFGString
  else Result := Parameter(NosoCFGString,LParam);
  LeaveCriticalSection(CS_CFGData);
End;

{$ENDREGION Data access}

{$REGION Management}

Procedure AddCFGData(DataToAdd:String;CFGIndex:Integer);
var
  LCFGstr    : String;
  LArrString : Array of string;
  DataStr    : String;
  thisData   : string;
  Counter    : integer = 0;
  FinalStr   : string = '';
Begin
  if DataToAdd[Length(DataToAdd)] <> ':' then
    DataToAdd := DataToAdd+':';
  LCFGStr := GetCFGDataStr();
  SetLength(LArrString,0);
  Repeat
    ThisData := Parameter(LCFGStr,counter);
    if ThisData <> '' then
      Insert(ThisData,LArrString,LEngth(LArrString));
    Inc(Counter);
  until thisData = '';
  if CFGIndex+1 > LEngth(LArrString) then
    begin
    repeat
      Insert('',LArrString,LEngth(LArrString));
    until CFGIndex+1 = LEngth(LArrString);
    end;
  DataStr := LArrString[CFGIndex];
  DataStr := DataStr+DataToAdd;
  LArrString[CFGIndex] := DataStr;
  For counter := 0 to length(LArrString)-1 do
    FinalStr := FinalStr+' '+LArrString[counter];
  If FinalStr[1] = ' ' then delete(FinalStr,1,1);
  SaveCFGToFile(FinalStr);
  LasTimeCFGRequest:= UTCTime+5;
End;

Procedure RemoveCFGData(DataToRemove:String;CFGIndex:Integer);
var
  LCFGstr    : String;
  LArrString : Array of string;
  DataStr    : String;
  thisData   : string;
  Counter    : integer = 0;
  FinalStr   : string = '';
Begin
  if ( (Length(DataToRemove)>0) and (DataToRemove[Length(DataToRemove)] <> ':') ) then
    DataToRemove := DataToRemove+':';
  LCFGStr := GetCFGDataStr();
  SetLength(LArrString,0);
  Repeat
    ThisData := Parameter(LCFGStr,counter);
    if ThisData <> '' then
      begin
      Insert(ThisData,LArrString,LEngth(LArrString));
      end;
    Inc(Counter);
  until thisData = '';
  DataStr := LArrString[CFGIndex];
  DataStr := StringReplace(DataStr,DataToRemove,'',[rfReplaceAll, rfIgnoreCase]);
  LArrString[CFGIndex] := DataStr;
  For counter := 0 to length(LArrString)-1 do
    FinalStr := FinalStr+' '+LArrString[counter];
  FinalStr := Trim(FinalStr);
  If FinalStr[1] = ' ' then delete(FinalStr,1,1);
  LasTimeCFGRequest:= UTCTime+5;
  SaveCFGToFile(FinalStr);
End;

Procedure SetCFGData(DataToSet:String;CFGIndex:Integer);
var
  LCFGstr    : String;
  LArrString : Array of string;
  DataStr    : String;
  thisData   : string;
  Counter    : integer = 0;
  FinalStr   : string = '';
Begin
  if ( (Length(DataToSet)>0) and (DataToSet[Length(DataToSet)] <> ':') and (CFGIndex>0) ) then
     DataToSet := DataToSet+':';
  if ((CFGIndex = 0) and (DatatoSet = '') ) then exit;
  LCFGStr := GetCFGDataStr();
  SetLength(LArrString,0);
  Repeat
    ThisData := Parameter(LCFGStr,counter);
    if ThisData <> '' then
      begin
      Insert(ThisData,LArrString,LEngth(LArrString));
      end;
    Inc(Counter);
  until thisData = '';
  LArrString[CFGIndex] := DataToSet;
  For counter := 0 to length(LArrString)-1 do
    FinalStr := FinalStr+' '+LArrString[counter];
  FinalStr := Trim(FinalStr);
  LasTimeCFGRequest:= UTCTime+5;
  SaveCFGToFile(FinalStr);
End;

Procedure RestoreCFGData();
Begin
  LasTimeCFGRequest:= UTCTime+5;
  SaveCFGToFile(DefaultNosoCFG);
End;

Procedure ClearCFGData(Index:string);
var
  LIndex : integer;
Begin
  LIndex := StrToIntDef(Index,-1);
  If LIndex <= 0 then exit;
  SetCFGData('null:',LIndex);
End;

{$ENDREGION Management}

{$REGION Information}

// If the specified IP a seed node
Function IsSeedNode(IP:String):boolean;
var
  SeedNodesStr : string;
Begin
  Result := false;
  SeedNodesStr := ':'+GetCFGDataStr(1);
  if AnsiContainsStr(SeedNodesStr,':'+ip+';') then result := true;
End;

{$REGION Information}

INITIALIZATION
InitCriticalSection(CS_CFGFile);
InitCriticalSection(CS_CFGData);
InitCriticalSection(CS_CFGHash);


FINALIZATION
DoneCriticalSection(CS_CFGFile);
DoneCriticalSection(CS_CFGData);
DoneCriticalSection(CS_CFGHash);

END.

