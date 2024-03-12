unit nosomasternodes;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils,IdTCPClient, IdGlobal,
  NosoDebug,NosoTime,NosoGeneral,nosocrypto,nosounit;

Type

  TThreadMNVerificator = class(TThread)
    private
      FSlot: Integer;
    protected
      procedure Execute; override;
    public
      constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
    end;

  TMNode = Packed Record
    Ip           : string[15];
    Port         : integer;
    Sign         : string[40];
    Fund         : string[40];
    First        : integer;
    Last         : integer;
    Total        : integer;
    Validations  : integer;
    Hash         : String[32];
    end;

  TMNCheck = Record
    ValidatorIP  : string;
    Block        : integer;
    SignAddress  : string;
    PubKey       : string;
    ValidNodes   : string;
    Signature    : string;
    end;

  TMNsData  = Packed Record
    ipandport  : string;
    address    : string;
    age        : integer;
    end;

  Procedure SetLocalIP(NewValue:String);
  Procedure SetMN_Sign(SignAddress,lPublicKey,lPrivateKey:String);
  Function GetMNReportString(block:integer):String;
  Function VerifyThreadsCount:integer;
  function RunMNVerification(Block:integer;LocSynctus:String;LocalIP:String;publicK,privateK:String):String;

  Function GetMNsListLength():Integer;
  Procedure ClearMNsList();
  Function IsIPMNAlreadyProcessed(OrderText:string):Boolean;
  Procedure ClearMNIPProcessed();
  function IsMyMNListed(LocalIP:String):boolean;
  Function IsLegitNewNode(ThisNode:TMNode;block:integer):Boolean;
  Function CheckMNReport(LineText:String;block:integer):String;
  Function GetMNodeFromString(const StringData:String; out ToMNode:TMNode):Boolean;
  Function GetStringFromMN(Node:TMNode):String;
  Function FillMnsListArray(out LDataArray:TStringArray) : Boolean;
  Function GetMNsAddresses(Block:integer):String;
  Procedure CreditMNVerifications();

  Function GetMNsChecksCount():integer;
  Function GetValidNodesCountOnCheck(StringNodes:String):integer;


  Function GetMNAgeCount(TNode:TMNode):string;

var
  MasterNodesFilename : string= 'NOSODATA'+DirectorySeparator+'masternodes.txt';
  MNsListCopy         : array of TMnode;
  CurrSynctus         : string;
  LocalMN_IP          : string = '';
  LocalMN_Port        : string = '8080';
  LocalMN_Sign        : string = '';
  LocalMN_Funds       : string = '';
  LocalMN_Public      : string = '';
  LocalMN_Private     : string = '';
  UnconfirmedIPs      : integer;

  VerifiedNodes       : String;
  CSVerNodes          : TRTLCriticalSection;

  OpenVerificators    : integer;
  CSVerifyThread      : TRTLCriticalSection;

  MNsList             : array of TMnode;
  CSMNsList           : TRTLCriticalSection;

  ArrayIPsProcessed   : array of string;
  CSMNsIPProc         : TRTLCriticalSection;

  ArrMNChecks         : array of TMNCheck;
  CSMNsChecks         : TRTLCriticalSection;

  ArrayMNsData        : array of TMNsData;

IMPLEMENTATION

Procedure SetLocalIP(NewValue:String);
Begin
  LocalMN_IP := NewValue;
End;

Procedure SetMN_Sign(SignAddress,lPublicKey,lPrivateKey:String);
Begin
  LocalMN_Sign    := SignAddress;
  LocalMN_Public  := lPublicKey;
  LocalMN_Private := lPrivateKey;
End;

// Returns the string to send the own MN report
Function GetMNReportString(block:integer):String;
Begin
  // {5}IP 6{Port} 7{SignAddress} 8{FundsAddress} 9{FirstBlock} 10{LastVerified}
  //    11{TotalVerified} 12{BlockVerifys} 13{hash}
  result := LocalMN_IP+' '+LocalMN_Port+' '+LocalMN_Sign+' '+LocalMN_Funds+' '+block.ToString+' '+block.ToString+' '+
  '0'+' '+'0'+' '+HashMD5String(LocalMN_IP+LocalMN_Port+LocalMN_Sign+LocalMN_Funds);
End;

{$REGION ThreadVerificator}

constructor TThreadMNVerificator.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
end;

procedure TThreadMNVerificator.Execute;
var
  TCPClient : TidTCPClient;
  Linea : String = '';
  WasPositive : Boolean;
  IP : string;
  Port: integer;
  Success : boolean ;
  Trys :integer = 0;
Begin
  AddNewOpenThread('VerifyMN '+FSlot.ToString,UTCTime);
  Sleep(1000);
  TRY {BIG}
    IP := MNsListCopy[FSlot].Ip;
    Port := MNsListCopy[FSlot].Port;
    TCPClient := TidTCPClient.Create(nil);
    TCPclient.Host:=Ip;
    TCPclient.Port:=Port;
    TCPclient.ConnectTimeout:= 1000;
    TCPclient.ReadTimeout:= 1000;
    REPEAT
      Inc(Trys);
      TRY
        TCPclient.Connect;
        TCPclient.IOHandler.WriteLn('MNVER');
        Linea := TCPclient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
        TCPclient.Disconnect();
        Success := true;
      EXCEPT on E:Exception do
        begin
        Success := false;
        end;
      END{try};
    UNTIL ((Success) or (trys = 3));
    TCPClient.Free;
    if success then
      begin
      WasPositive := StrToBoolDef(Parameter(Linea,0),false);
      if ( (WasPositive) and (Parameter(Linea,1)=CurrSynctus) ) then
        begin
        EnterCriticalSection(CSVerNodes);
        VerifiedNodes := VerifiedNodes+Ip+';'+Port.ToString+':';
        LeaveCriticalSection(CSVerNodes);
        end
      else if ( (WasPositive) and (Parameter(Linea,1)<>CurrSynctus) ) then
        begin
        // Wrong synctus returned
        end
      else
        begin
        // Was not possitive
        end;
      end;
    If Parameter(Linea,3) <> LocalMN_IP then Inc(UnconfirmedIPs);
  EXCEPT on E:Exception do
    begin
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'CRITICAL MNs VERIFICATION ('+Ip+'): '+E.Message);
    end;
  END{BIG TRY};
  EnterCriticalSection(CSVerifyThread);
  Dec(OpenVerificators);
  LeaveCriticalSection(CSVerifyThread);
  CloseOpenThread('VerifyMN '+FSlot.ToString);
End;

Function VerifyThreadsCount:integer;
Begin
  EnterCriticalSection(CSVerifyThread);
  Result := OpenVerificators;
  LeaveCriticalSection(CSVerifyThread);
End;

{$ENDREGION ThreadVerificator}

function RunMNVerification(Block:integer;LocSynctus:String;LocalIP:String;publicK,privateK:String):String;
var
  counter : integer;
  ThisThread : TThreadMNVerificator;
  Launched : integer = 0;
  WaitCycles : integer = 0;
  DataLine : String;
Begin
  BeginPerformance('RunMNVerification');
  Result := '';
  CurrSynctus := LocSynctus;
  SetLocalIP(LocalIP);
  VerifiedNodes := '';
  setlength(MNsListCopy,0);
  EnterCriticalSection(CSMNsList);
  MNsListCopy := copy(MNsList,0,length(MNsList));
  LeaveCriticalSection(CSMNsList);
  UnconfirmedIPs := 0;
  for counter := 0 to length(MNsListCopy)-1 do
    begin
    if (( MNsListCopy[counter].ip <> LocalIP) and (IsValidIp(MNsListCopy[counter].ip)) ) then
      begin
      Inc(Launched);
      ThisThread := TThreadMNVerificator.Create(true,counter);
      ThisThread.FreeOnTerminate:=true;
      ThisThread.Start;
      end;
    end;
  EnterCriticalSection(CSVerifyThread);
  OpenVerificators := Launched;
  LeaveCriticalSection(CSVerifyThread);
  Repeat
    sleep(100);
    Inc(WaitCycles);
  until ( (VerifyThreadsCount= 0) or (WaitCycles = 250) );
  ToDeepDeb(Format('MNs verification finish: %d launched, %d Open, %d cycles',[Launched,VerifyThreadsCount,WaitCycles ]));
  ToDeepDeb(Format('Unconfirmed IPs: %d',[UnconfirmedIPs ]));
  if VerifyThreadsCount>0 then
    begin
    EnterCriticalSection(CSVerifyThread);
    OpenVerificators := 0;
    LeaveCriticalSection(CSVerifyThread);
    end;
  Result := LocalIP+' '+Block.ToString+' '+LocalMN_Sign+' '+publicK+' '+
            VerifiedNodes+' '+GetStringSigned(VerifiedNodes,privateK);
  EndPerformance('RunMNVerification');
End;

{$REGION MNsList handling}

// Returns the count of reported MNs
Function GetMNsListLength():Integer;
Begin
  EnterCriticalSection(CSMNsList);
  Result := Length(MNsList);
  LeaveCriticalSection(CSMNsList);
End;

Procedure ClearMNsList();
Begin
  EnterCriticalSection(CSMNsList);
  SetLength(MNsList,0);
  LeaveCriticalSection(CSMNsList);
  EnterCriticalSection(CSMNsIPProc);
  Setlength(ArrayIPsProcessed,0);
  LeaveCriticalSection(CSMNsIPProc);
End;

// Verify if an IP was already processed
Function IsIPMNAlreadyProcessed(OrderText:string):Boolean;
var
  ThisIP : string;
  counter : integer;
Begin
  result := false;
  ThisIP := parameter(OrderText,5);
  EnterCriticalSection(CSMNsIPProc);
  if length(ArrayIPsProcessed) > 0 then
    begin
    for counter := 0 to length(ArrayIPsProcessed)-1 do
      begin
      if ArrayIPsProcessed[counter] = ThisIP then
        begin
        result := true;
        break
        end;
      end;
    end;
  if result = false then Insert(ThisIP,ArrayIPsProcessed,length(ArrayIPsProcessed));
  LeaveCriticalSection(CSMNsIPProc);
End;

Procedure ClearMNIPProcessed();
Begin
  EnterCriticalSection(CSMNsIPProc);
  Setlength(ArrayIPsProcessed,0);
  LeaveCriticalSection(CSMNsIPProc);
End;

function IsMyMNListed(LocalIP:String):boolean;
var
  counter : integer;
Begin
  result := false;
  if GetMNsListLength > 0 then
    begin
    EnterCriticalSection(CSMNsList);
    for counter := 0 to length(MNsList)-1 do
      begin
      if MNsList[counter].Ip = LocalIP then
        begin
        result := true;
        break;
        end;
      end;
   LeaveCriticalSection(CSMNsList);
   end;
End;

Function IsLegitNewNode(ThisNode:TMNode;block:integer):Boolean;
var
  counter : integer;
Begin
  result := true;
  if GetMNsListLength>0 then
    begin
    EnterCriticalSection(CSMNsList);
    For counter := 0 to length(MNsList)-1 do
      begin
      if ( (ThisNode.Ip = MNsList[counter].Ip) or
           (ThisNode.Sign = MNsList[counter].Sign) or
           (ThisNode.Fund = MNsList[counter].Fund) or
           //(ThisNode.First>MyLastBlock) or
           //(ThisNode.Last>MyLastBlock) or
           //(ThisNode.Total<>0) or
           (GetAddressBalanceIndexed(ThisNode.Fund) < GetStackRequired(block+1)) or
           (ThisNode.Validations<>0) ) then
      begin
        Result := false;
        break;
      end;
    end;
    LeaveCriticalSection(CSMNsList);
  end;
End;

Function CheckMNReport(LineText:String;block:integer):String;
var
  StartPos   : integer;
  ReportInfo : string = '';
  NewNode    : TMNode;
  counter    : integer;
  Added      : boolean = false;
Begin
  Result := '';
  StartPos := Pos('$',LineText);
  ReportInfo := copy (LineText,StartPos,length(LineText));
  if GetMNodeFromString(ReportInfo,NewNode) then
    begin
    if IsLegitNewNode(NewNode,block) then
      begin
      EnterCriticalSection(CSMNsList);
      if Length(MNsList) = 0 then
         Insert(NewNode,MNsList,0)
      else
         begin
         for counter := 0 to length(MNsList)-1 do
            begin
            if NewNode.Ip<MNsList[counter].ip then
               begin
               Insert(NewNode,MNsList,counter);
               Added := true;
               break;
               end;
            end;
         if not Added then Insert(NewNode,MNsList,Length(MNsList));
         end;
      LeaveCriticalSection(CSMNsList);
      Result := reportinfo;
      end
    else
      begin
      //No legit masternode
      end;
    end
  else
    begin
    //Invalid masternode
    end;
End;

// Converts a String into a MNNode data
Function GetMNodeFromString(const StringData:String; out ToMNode:TMNode):Boolean;
var
  ErrCode : integer = 0;
Begin
  Result := true;
  ToMNode := Default(TMNode);
  ToMNode.Ip          := Parameter(StringData,1);
  ToMNode.Port        := StrToIntDef(Parameter(StringData,2),-1);
  ToMNode.Sign        := Parameter(StringData,3);
  ToMNode.Fund        := Parameter(StringData,4);
  ToMNode.First       := StrToIntDef(Parameter(StringData,5),-1);
  ToMNode.Last        := StrToIntDef(Parameter(StringData,6),-1);
  ToMNode.Total       := StrToIntDef(Parameter(StringData,7),-1);
  ToMNode.Validations := StrToIntDef(Parameter(StringData,8),-1);
  ToMNode.hash        := Parameter(StringData,9);
  If Not IsValidIP(ToMNode.Ip) then result := false
  else if ( (ToMNode.Port<0) or (ToMNode.Port>65535) ) then ErrCode := 1
  else if not IsValidHashAddress(ToMNode.Sign) then ErrCode := 2
  else if not IsValidHashAddress(ToMNode.Fund) then ErrCode := 3
  else if ToMNode.first < 0 then ErrCode := 4
  else if ToMNode.last < 0 then ErrCode := 5
  else if ToMNode.total <0 then ErrCode := 6
  else if ToMNode.validations < 0 then ErrCode := 7
  else if ToMNode.hash <> HashMD5String(ToMNode.Ip+IntToStr(ToMNode.Port)+ToMNode.Sign+ToMNode.Fund) then ErrCode := 8;
  if ErrCode>0 then
    begin
    Result := false;
    //Invalid Masternode
    end;
End;

// Converst a MNNode data into a string
Function GetStringFromMN(Node:TMNode):String;
Begin
  result := Node.Ip+' '+Node.Port.ToString+' '+Node.Sign+' '+Node.Fund+' '+Node.First.ToString+' '+Node.Last.ToString+' '+
          Node.Total.ToString+' '+Node.Validations.ToString+' '+Node.Hash;
End;

// Fills the given array with the nodes reports to be sent to another peer
Function FillMnsListArray(out LDataArray:TStringArray) : Boolean;
var
  ThisLine  : string;
  counter   : integer;
Begin
  result := false;
  SetLength(LDataArray,0);
  if GetMNsListLength>0 then
    begin
    EnterCriticalSection(CSMNsList);
    for counter := 0 to length(MNsList)-1 do
      begin
      ThisLine := GetStringFromMN(MNsList[counter]);
      Insert(ThisLine,LDataArray,length(LDataArray));
      end;
    result := true;
    LeaveCriticalSection(CSMNsList);
    end;
End;

// Returns the string to be stored on the masternodes.txt file
Function GetMNsAddresses(Block:integer):String;
var
  MinValidations : integer;
  Counter        : integer;
  Resultado      : string = '';
  AddAge         : string = '';
Begin
  MinValidations := (GetMNsChecksCount div 2) - 1;
  Resultado := Block.ToString+' ';
  EnterCriticalSection(CSMNsList);
  For counter := 0 to length(MNsList)-1 do
    begin
    if MNsList[counter].Validations>= MinValidations then
      begin
      AddAge := GetMNAgeCount(MNsList[counter]);
      Resultado := Resultado + MNsList[counter].Ip+';'+MNsList[counter].Port.ToString+':'+MNsList[counter].Fund+AddAge+' ';
      end;
    end;
  LeaveCriticalSection(CSMNsList);
  SetLength(Resultado, Length(Resultado)-1);
  result := Resultado;
End;

Procedure CreditMNVerifications();
var
  counter     : integer;
  NodesString : string;
  ThisIP      : string;
  IPIndex     : integer = 0;
  CheckNodes  : integer;

  Procedure AddCheckToIP(IP:String);
  var
    counter2 : integer;
  Begin
  For counter2 := 0 to length(MNsList)-1 do
     begin
     if MNsList[Counter2].Ip = IP then
        begin
        MNsList[Counter2].Validations := MNsList[Counter2].Validations+1;
        Break;
        end;
     end;
  End;

Begin
  EnterCriticalSection(CSMNsList);
  EnterCriticalSection(CSMNsChecks);
  for counter := 0 to length(ArrMNChecks)-1 do
    begin
    NodesString := ArrMNChecks[counter].ValidNodes;
    NodesString := StringReplace(NodesString,':',' ',[rfReplaceAll]);
    CheckNodes  := 0;
    IPIndex     := 0;
    REPEAT
      begin
      ThisIP := Parameter(NodesString,IPIndex);
      ThisIP := StringReplace(ThisIP,';',' ',[rfReplaceAll]);
      ThisIP := Parameter(ThisIP,0);
      if ThisIP <> '' then
        begin
        AddCheckToIP(ThisIP);
        Inc(CheckNodes);
        end;
      Inc(IPIndex);
      end;
    UNTIL ThisIP = '';
    //ToLog('Console',ArrMNChecks[counter].ValidatorIP+': '+Checknodes.ToString);
    end;
  LeaveCriticalSection(CSMNsChecks);
  LeaveCriticalSection(CSMNsList);
End;

{$ENDREGION MNsList handling}

{$REGION MNs check handling}

// Returns the number of MNs checks
Function GetMNsChecksCount():integer;
Begin
  EnterCriticalSection(CSMNsChecks);
  result := Length(ArrMNChecks);
  LeaveCriticalSection(CSMNsChecks);
End;

Function GetValidNodesCountOnCheck(StringNodes:String):integer;
var
  ThisIP  : string;
  IPIndex : integer = 0;
Begin
  Result := 0;
  StringNodes := StringReplace(StringNodes,':',' ',[rfReplaceAll]);
  IPIndex     := 0;
  REPEAT
    begin
    ThisIP := Parameter(StringNodes,IPIndex);
    if ThisIP <> '' then Inc(Result);
    Inc(IPIndex);
    end;
  UNTIL ThisIP = '';
End;

{$ENDREGION MNs check handling}

{$REGION MNs FileData handling}

Function GetMNAgeCount(TNode:TMNode):string;
var
  TIpandPort : string;
  counter    : integer;
  Number     : integer=0;
Begin
  result := '';
  TIpandPort := TNode.Ip+';'+IntToStr(TNode.Port);
  for counter := 0 to length(ArrayMNsData)-1 do
    begin
    if ( (TIpandPort = ArrayMNsData[counter].ipandport) and (TNode.Fund=ArrayMNsData[counter].address) ) then
      begin
      Number := ArrayMNsData[counter].age;
      break;
      end;
    end;
  result := ':'+IntToStr(number+1);
End;

{$ENDREGION MNs FileData handling}


INITIALIZATION
SetLength(MNsListCopy,0);
SetLength(MNsList,0);
SetLength(ArrayIPsProcessed,0);
SetLength(ArrMNChecks,0);
SetLength(ArrayMNsData,0);
InitCriticalSection(CSMNsIPProc);
InitCriticalSection(CSMNsList);
InitCriticalSection(CSVerNodes);
InitCriticalSection(CSVerifyThread);
InitCriticalSection(CSMNsChecks);

FINALIZATION
DoneCriticalSection(CSMNsIPProc);
DoneCriticalSection(CSMNsList);
DoneCriticalSection(CSVerNodes);
DoneCriticalSection(CSVerifyThread);
DoneCriticalSection(CSMNsChecks);


END. // End unit

