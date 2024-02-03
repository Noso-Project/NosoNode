unit nosoconsensus;

{
nosoconsensus 1.0
January 20th, 2023
Noso Unit to get a consensus
Requires: nosodebug, nosotime, nosogeneral
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, strutils,
  nosodebug, nosotime, nosogeneral, nosocrypto;

Type

  TThreadNodeStatus = class(TThread)
    private
      Slot: Integer;
    protected
      procedure Execute; override;
    public
      constructor Create(const CreatePaused: Boolean;TSlot:Integer);
    end;

  TThreadAutoConsensus = class(TThread)
    protected
      Procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

  TConsensus = array of string[32];

  TNodeConsensus = record
    host    : string;
    port    : integer;
    Data    : string;
    ConStr  : string[32];
    Block   : integer;
    Peers   : integer;
    end;

  TConsensusData = record
    Value : string;
    count : integer;
    end;

Function OpenThreadsValue():integer;

Function CalculateConsensus(NodesList:string = ''):TConsensus;
Function GetConsensus(LData : integer = 0): string;
Function GetRandonNode():String;
Function GetConHash(ILine:String):String;
Procedure SetNodesArray(NodesList:string);
Function GetNodesArrayIndex(LIndex:integer):TNodeConsensus;
Function GetNodesArrayCount():Integer;

Procedure StartAutoConsensus();
Procedure StopAutoConsensus();

Const
  cLastBlock = 2;
  cHeaders   = 5;
  cMNsHash   = 8;
  cMNsCount  = 9;
  cLBHash    = 10;
  cLBTimeEnd = 12;
  cSumHash   = 17;
  cGVTsHash  = 18;
  cCFGHash   = 19;

var
  Consensus : TConsensus;
  NConsensus : array[0..20] of string = ({0}'Resume','Peers','LBlock','Pending','Delta',
                                         {5}'Headers','Version','UTCTime','MNsHash','MNsCount',
                                         {10}'LBHash','BestDiff','LBTimeEnd','LBMiner','ChecksCount',
                                         {15}'LBPoW','LBDiff','Summary','GVTs','NosoCFG',
                                         {20}'PSOHash');
  Css_TotalNodes    : integer = 0;
  Css_ReachedNodes  : integer = 0;
  Css_ValidNodes    : Integer = 0;
  Css_Percentage    : Integer = 0;
  Css_Completed     : boolean = false;
  LastConsensusTime : int64 = 0;

IMPLEMENTATION

var
  NodesArray        : array of TNodeConsensus;
  CSNodesArray      : TRTLCriticalSection;
  OpenThreads       : integer;
  ReachedNodes      : integer;
  CSOpenThreads     : TRTLCriticalSection;
  CSConsensus       : TRTLCriticalSection;
  KeepAutoCon       : Boolean = false;
  RunningConsensus  : boolean = false;
  ActiveRound       : int64 = 0;

{$REGION Thread auto update}

Procedure StartAutoConsensus();
var
  AutoThread : TThreadAutoConsensus;
Begin
  if KeepAutoCon then exit;
  Keepautocon := true;
  AutoThread := TThreadAutoConsensus.Create(true);
  AutoThread.FreeOnTerminate:=true;
  AutoThread.Start;
End;

Procedure StopAutoConsensus();
Begin
  Keepautocon := false;
End;

Constructor TThreadAutoConsensus.Create(CreateSuspended : boolean);
Begin
  inherited Create(CreateSuspended);
End;

Procedure TThreadAutoConsensus.Execute;
Begin
  Repeat
    if ((BlockAge>=0) and (BlockAge<5)) then LastConsensusTime := 0;
    if ( ((BlockAge>=5) and (BlockAge<585)) and (LastConsensusTime+60<UTCTime) )then
      begin
      LastConsensusTime := UTCTime;
      CalculateConsensus();
      end;
    Sleep(100);
  until ((terminated) or (Not KeepAutoCon));
End;

{$ENDREGION}

{$REGION Open threads}

Procedure DecOpenThreads(Reached : boolean);
Begin
  EnterCriticalSection(CSOpenThreads);
  Dec(OpenThreads);
  if reached then Inc(ReachedNodes);
  LeaveCriticalSection(CSOpenThreads);
End;

Function OpenThreadsValue():integer;
Begin
  EnterCriticalSection(CSOpenThreads);
  Result := OpenThreads;
  LeaveCriticalSection(CSOpenThreads);
End;

Function GetNodeIndex(index:integer):TNodeConsensus;
Begin
  EnterCriticalSection(CSNodesArray);
  Result := NodesArray[index];
  LeaveCriticalSection(CSNodesArray);
End;

{$ENDREGION}

{$REGION Thread consulting node}

Constructor TThreadNodeStatus.Create(const CreatePaused: Boolean; TSlot:Integer);
Begin
  inherited Create(CreatePaused);
  Slot := TSlot;
  FreeOnTerminate := True;
End;

Procedure TThreadNodeStatus.Execute;
var
  ThisNode   : TNodeConsensus;
  ReadedLine : string;
  Reached    : boolean = false;
  ConHash    : string = '';
  MyRound    : int64;
Begin
  MyRound := ActiveRound;
  ThisNode := GetNodeIndex(slot);
  ReadedLine := RequestLineToPeer(ThisNode.host,ThisNode.port,'NODESTATUS');
  if copy(ReadedLine,1,10) = 'NODESTATUS' then
    begin
    ConHash := GetConHash(ReadedLine);
    ReadedLine := StringReplace(ReadedLine,'NODESTATUS',ConHash,[rfReplaceAll, rfIgnoreCase]);
    ThisNode.Data:= ReadedLine;
    ThisNode.ConStr:=ConHash;
    ThisNode.Peers:=StrToIntDef(Parameter(ReadedLine,1),0);
    ThisNode.Block:=StrToIntDef(Parameter(ReadedLine,2),0);
    reached := true;
    end
  else
    begin
    ThisNode.Data:= '';
    ThisNode.ConStr:='';
    ThisNode.Peers:= 0;
    ThisNode.Block:= 0;
    end;
  if MyRound = ActiveRound then
    begin
    EnterCriticalSection(CSNodesArray);
    NodesArray[slot] := ThisNode;
    LeaveCriticalSection(CSNodesArray);
    DecOpenThreads(Reached);
    end;
End;

{$ENDREGION}

Function GetConHash(ILine:String):String;
Begin
  Result := '';
  Result := HashMD5String(Parameter(ILine,2)+copy(Parameter(ILine,5),0,5)+copy(Parameter(ILine,8),0,5)+
                          copy(Parameter(ILine,10),0,5)+copy(Parameter(ILine,17),0,5)+
                          copy(Parameter(ILine,18),0,5)+copy(Parameter(ILine,19),0,5));
End;

{Gets a random ip and port node}
Function GetRandonNode():String;
var
  LNumber : integer;
Begin
  result := '';
  EnterCriticalSection(CSNodesArray);
  LNumber := random(length(NodesArray));
  Result := Format('%s %d',[NodesArray[LNumber].host,NodesArray[LNumber].port]);
  LeaveCriticalSection(CSNodesArray);
End;

{Set the values for the array of nodes}
Procedure SetNodesArray(NodesList:string);
var
  counter : integer;
  MyArray : array of string;
Begin
  Repeat
    sleep(1);
  until not RunningConsensus;
  setlength(NodesArray,0);
  NodesList := Trim(StringReplace(NodesList,':',' ',[rfReplaceAll, rfIgnoreCase]));
  MyArray := SplitString(NodesList,' ');
  EnterCriticalSection(CSNodesArray);
  for counter := 0 to high(MyArray) do
    begin
    MyArray[counter] := StringReplace(MyArray[counter],';',' ',[rfReplaceAll, rfIgnoreCase]);
    Setlength(NodesArray,length(NodesArray)+1);
    NodesArray[length(NodesArray)-1].host   := Parameter(MyArray[counter],0) ;
    NodesArray[length(NodesArray)-1].port   := StrToIntDef(Parameter(MyArray[counter],1),8080);
    NodesArray[length(NodesArray)-1].data   := '';
    NodesArray[length(NodesArray)-1].ConStr := '';
    NodesArray[length(NodesArray)-1].Block  := 0;
    NodesArray[length(NodesArray)-1].peers  := 0;
    end;
  LeaveCriticalSection(CSNodesArray);
  LastConsensusTime := 0;
End;

Function GetNodesArrayIndex(LIndex:integer):TNodeConsensus;
Begin
  result := default(TNodeConsensus);
  EnterCriticalSection(CSNodesArray);
  if LIndex < length(NodesArray) then
    result := NodesArray[LIndex];
  LeaveCriticalSection(CSNodesArray);
End;

Function GetNodesArrayCount():Integer;
Begin
  EnterCriticalSection(CSNodesArray);
  Result := length(NodesArray);
  LeaveCriticalSection(CSNodesArray);
End;

Function CalculateConsensus(NodesList:string = ''):TConsensus;
var
  counter     : integer;
  count2      : integer;
  ParamNumber : integer = 1;
  ThisThread  : TThreadNodeStatus;
  isFinished  : boolean = false;
  ArrayCon    : array of TConsensusData;
  ThisHigh    : string;
  ConHash     : string;
  ValidNodes  : integer = 0;
  EndTime   : int64;

  Procedure AddValue(Tvalue:String);
  var
    counter   : integer;
    ThisItem  : TConsensusData;
  Begin
    for counter := 0 to length(ArrayCon)-1 do
      begin
      if Tvalue = ArrayCon[counter].Value then
        begin
        ArrayCon[counter].count+=1;
        Exit;
        end;
      end;
  ThisItem.Value:=Tvalue;
  ThisItem.count:=1;
  Insert(ThisITem,ArrayCon,length(ArrayCon));
  End;

  Function GetHighest():string;
  var
    maximum : integer = 0;
    counter : integer;
    MaxIndex : integer = 0;
  Begin
    result := '';
    if length(ArrayCon) > 0 then
      begin
      for counter := 0 to high(ArrayCon) do
        begin
        if ArrayCon[counter].count> maximum then
          begin
          maximum := ArrayCon[counter].count;
          MaxIndex := counter;
          end;
        end;
      result := ArrayCon[MaxIndex].Value;
      end;
  End;
Begin
  BeginPerformance('CalculateConsensus');
  RunningConsensus := true;
  SetLength(Result,0);
  if NodesList <> '' then SetNodesArray(NodesList);
  OpenThreads := length(NodesArray);
  ReachedNodes := 0;
  ActiveRound := UTCTime;
  for counter := 0 to high(NodesArray) do
    begin
    ThisThread := TThreadNodeStatus.Create(True,counter);
    ThisThread.FreeOnTerminate:=true;
    ThisThread.Start;
    Sleep(1);
    end;
  EndTime := UTCTime+5;
  Repeat
    sleep(1);
  until ( (OpenThreadsValue<= 0) or (UTCTime >= EndTime) );
  ActiveRound := 0;
  // Get the consensus hash
  SetLength(ArrayCon,0);
  for counter := 0 to high(NodesArray) do
    begin
    if Parameter(NodesArray[counter].Data,0) <> '' then
      AddValue(Parameter(NodesArray[counter].Data,0));
    end;
  ConHash := GetHighest;
  if conhash = '' then
    begin
    for count2 := 0 to length(NConsensus)-1 do
      begin
      insert('',result,0);
      end;
    Css_TotalNodes := length(NodesArray);
    Css_ReachedNodes := Reachednodes;
    Css_ValidNodes := ValidNodes;
    if ReachedNodes >0 then Css_Percentage := (ValidNodes * 100) div ReachedNodes
    else Css_Percentage := 0;
    EnterCriticalSection(CSConsensus);
    setlength(consensus,0);
    Consensus := copy(result,0,length(result));
    LeaveCriticalSection(CSConsensus);
    Css_Completed := false;
    RunningConsensus := false;
    Dec(LastConsensusTime,50);
    EndPerformance('CalculateConsensus');
    exit;
    end;
  insert(ConHash,result,0);
  // Fill the consensus
  Repeat
    SetLength(ArrayCon,0);
    for counter := 0 to high(NodesArray) do
      begin
      if Parameter(NodesArray[counter].Data,0) = ConHash then
        begin
        AddValue(Parameter(NodesArray[counter].Data,paramnumber));
        if ParamNumber = 1 then Inc(ValidNodes);
        end;
      end;
    ThisHigh := GetHighest;
    if thishigh = '' then isFinished := true
    else insert(ThisHigh,result,length(Result));
    Inc(ParamNumber);
  until isFinished;
  Css_TotalNodes := length(NodesArray);
  Css_ReachedNodes := Reachednodes;
  Css_ValidNodes := ValidNodes;
  if ReachedNodes >0 then Css_Percentage := (ValidNodes * 100) div ReachedNodes
  else Css_Percentage := 0;
  EnterCriticalSection(CSConsensus);
  setlength(consensus,0);
  Consensus := copy(result,0,length(result));
  LeaveCriticalSection(CSConsensus);
  Css_Completed := true;
  RunningConsensus := false;
  EndPerformance('CalculateConsensus');
End;

Function GetConsensus(LData : integer = 0): string;
Begin
  Result := '';
  EnterCriticalSection(CSConsensus);
  TRY
    Result := Consensus[LData];
  EXCEPT on E:Exception do
    begin

    end;
  END;
  LeaveCriticalSection(CSConsensus);
End;

INITIALIZATION
  Randomize;
  setlength(NodesArray,0);
  InitCriticalSection(CSNodesArray);
  InitCriticalSection(CSOpenThreads);
  InitCriticalSection(CSConsensus);


FINALIZATION
  DoneCriticalSection(CSNodesArray);
  DoneCriticalSection(CSOpenThreads);
  DoneCriticalSection(CSConsensus);

END. {END UNIT}

