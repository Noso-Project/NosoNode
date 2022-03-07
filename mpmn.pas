unit mpMN;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpCripto, MasterPaskalform, mpcoin, mpgui, IdTCPClient, IdGlobal;

Type

   TThreadMNVerificator = class(TThread)
      private
        FSlot: Integer;
      protected
        procedure Execute; override;
      public
        constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
      end;

Procedure RunMNVerification();
Function GetMNCheckFromString(Linea:String):TMNCheck;

Function GetMNsChecksCount():integer;
Procedure ClearMNsChecks();
Function MnsCheckExists(Ip:String):Boolean;
Procedure AddMNCheck(Data:TMNCheck);
Procedure PTC_MNCheck(Linea:String);
Function GetStringFromMNCheck(Data:TMNCheck): String;
Procedure PTC_SendChecks(Slot:integer);


Function MNVerificationDone():Boolean;
Function ValidatorsCount():Integer;
Function IsValidator(Ip:String):boolean;
Function GetMNReportString():String;
Function GetStringFromMN(Node:TMNode):String;
Function GetMNsListLength():Integer;
function MyMNIsListed():boolean;
Function GetMNodeFromString(const StringData:String; out ToMNode:TMNode):Boolean;
Function IsLegitNewNode(ThisNode:TMNode):Boolean;
Procedure CheckMNRepo(LineText:String);
Procedure SendMNsList(Slot:Integer);
Procedure CleanMasterNodes(BlockNumber:Integer);
Function GetVerificationMNLine():String;

Procedure CreditMNVerifications();

Procedure SaveMNsFile();

var
  OpenVerificators : integer;
  MNsListCopy : array of TMnode;
  CurrSynctus : string;
  VerifiedNodes : String;
  CSVerNodes    : TRTLCriticalSection;
  CSMNsChecks   : TRTLCriticalSection;
  DecVerThreads : TRTLCriticalSection;

implementation

Uses
  mpParser, mpProtocol, mpDisk, mpRed;

constructor TThreadMNVerificator.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
end;

procedure TThreadMNVerificator.Execute;
var
  TCPClient : TidTCPClient;
  Linea : String;
  WasPositive : Boolean;
  IP : string;
  Port: integer;
  Success : boolean ;
  Trys :integer = 0;
Begin
Sleep(100);
{BIG}TRY
IP := MNsListCopy[FSlot].Ip;
Port := MNsListCopy[FSlot].Port;
TCPClient := TidTCPClient.Create(nil);
TCPclient.Host:=Ip;
TCPclient.Port:=Port;
TCPclient.ConnectTimeout:= 1000;
TCPclient.ReadTimeout:=1000;
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
   WasPositive := StrToBool(Parameter(Linea,0));
   if ( (WasPositive) and (Parameter(Linea,1)=CurrSynctus) ) then
      begin
      EnterCriticalSection(CSVerNodes);
      VerifiedNodes := VerifiedNodes+Ip+':';
      LeaveCriticalSection(CSVerNodes);
      end
   else
      begin

      end;
   end;
EXCEPT on E:Exception do
   ToExcLog('CRITICAL MNs VERIFICATION ('+Ip+'): '+E.Message);
END{BIG TRY};
EnterCriticalSection(DecVerThreads);
Dec(OpenVerificators);
LeaveCriticalSection(DecVerThreads);
End;

Procedure RunMNVerification();
var
  counter : integer;
  ThisThread : TThreadMNVerificator;
  Launched : integer = 0;
  WaitCycles : integer = 0;
  DataLine : String;

  Function NoVerificators():integer;
  Begin
  EnterCriticalSection(DecVerThreads);
  result := OpenVerificators;
  LeaveCriticalSection(DecVerThreads);
  End;

Begin
CurrSynctus := GetSyncTus;
VerifiedNodes := '';
setlength(MNsListCopy,0);
EnterCriticalSection(CSMNsArray);
MNsListCopy := copy(MNsList,0,length(MNsList));
LeaveCriticalSection(CSMNsArray);
for counter := 0 to length(MNsListCopy)-1 do
   begin
   if (( MNsListCopy[counter].ip <> MN_Ip) and (IsValidIp(MNsListCopy[counter].ip)) and (MNsListCopy[counter].First<>MyLastBlock)) then
      begin
      Inc(Launched);
      ThisThread := TThreadMNVerificator.Create(true,counter);
      ThisThread.FreeOnTerminate:=true;
      ThisThread.Start;
      end;
   end;
OpenVerificators := launched;
Repeat
  sleep(100);
  Inc(WaitCycles);
until ( (NoVerificators= 0) or (WaitCycles = 100) );
//ToLog('Finished MNs verification: '+launched.ToString+'->'+WaitCycles.ToString+slinebreak+VerifiedNodes);
DataLine := MN_IP+' '+MyLastBlock.ToString+' '+MN_Sign+' '+ListaDirecciones[DireccionEsMia(MN_Sign)].PublicKey+' '+
            VerifiedNodes+' '+GetStringSigned(VerifiedNodes,ListaDirecciones[DireccionEsMia(MN_Sign)].PrivateKey);
OutGoingMsjsAdd(ProtocolLine(MNCheck)+DataLine);
End;

Function GetMNCheckFromString(Linea:String):TMNCheck;
Begin
Result.ValidatorIP    :=Parameter(Linea,5);
Result.Block          :=StrToIntDef(Parameter(Linea,6),0);
Result.SignAddress    :=Parameter(Linea,7);
Result.PubKey         :=Parameter(Linea,8);
Result.ValidNodes     :=Parameter(Linea,9);
Result.Signature      :=Parameter(Linea,10);
End;

Function GetMNsChecksCount():integer;
Begin
EnterCriticalSection(CSMNsChecks);
result := Length(ArrMNChecks);
LeaveCriticalSection(CSMNsChecks);
End;

Procedure ClearMNsChecks();
Begin
EnterCriticalSection(CSMNsChecks);
SetLength(ArrMNChecks,0);
LeaveCriticalSection(CSMNsChecks);
End;

Function MnsCheckExists(Ip:String):Boolean;
var
  Counter : integer;
Begin
result := false;
EnterCriticalSection(CSMNsChecks);
For counter := 0 to length(ArrMNChecks)-1 do
   begin
   if ArrMNChecks[counter].ValidatorIP = IP then
      begin
      result := true;
      break;
      end;
   end;
LeaveCriticalSection(CSMNsChecks);
End;

Procedure AddMNCheck(Data:TMNCheck);
Begin
EnterCriticalSection(CSMNsChecks);
Insert(Data,ArrMNChecks,Length(ArrMNChecks));
LeaveCriticalSection(CSMNsChecks);
End;

Procedure PTC_MNCheck(Linea:String);
//ArrMNChecks
var
  CheckData : TMNCheck;
  StartPos : integer;
  ReportInfo : String;
  ErrorCode : integer = 0;
Begin
StartPos := Pos('$',Linea);
ReportInfo := copy (Linea,StartPos,length(Linea));
CheckData := GetMNCheckFromString(Linea);
if MnsCheckExists(CheckData.ValidatorIP) then exit;
if not IsValidator(CheckData.ValidatorIP) then ErrorCode := 1;
if CheckData.Block <> MyLastBlock then ErrorCode := 2;
if GetAddressFromPublicKey(CheckData.PubKey)<>CheckData.SignAddress then ErrorCode := 3;
if not VerifySignedString(CheckData.ValidNodes,CheckData.Signature,CheckData.PubKey) then ErrorCode := 4;
if ErrorCode = 0 then
   begin
   AddMNCheck(CheckData);
   outGOingMsjsAdd(GetPTCEcn+ReportInfo);
   ConsoleLinesAdd('Check received from '+CheckData.ValidatorIP);
   ToLog('Good check : (('+Linea+'))');
   end
else
   begin
   consolelinesadd('Wrong check from '+CheckData.ValidatorIP+'->'+ErrorCode.ToString);
   ToLog('Wrong MNCheck: (-('+Linea+')-)');
   end;
End;

{MN_IP+' '+MyLastBlock.ToString+' '+MN_Sign+' '+ListaDirecciones[DireccionEsMia(MN_Sign)].PublicKey+' '+
            VerifiedNodes+' '+GetStringSigned(VerifiedNodes,ListaDirecciones[DireccionEsMia(MN_Sign)].PrivateKey); }

Function GetStringFromMNCheck(Data:TMNCheck): String;
Begin
result := Data.ValidatorIP+' '+IntToStr(Data.Block)+' '+Data.SignAddress+' '+Data.PubKey+' '+
         Data.ValidNodes+' '+Data.Signature;
End;

Procedure PTC_SendChecks(Slot:integer);
var
  Counter : integer;
  Texto : string;
Begin
if GetMNsChecksCount>0 then
   begin
   EnterCriticalSection(CSMNsChecks);
   for counter := 0 to length(ArrMNChecks)-1 do
      begin
      Texto := ProtocolLine(MNCheck)+GetStringFromMNCheck(ArrMNChecks[counter]);
      PTC_SendLine(slot,Texto);
      end;
   LeaveCriticalSection(CSMNsChecks);
   end;
End;

Function MNVerificationDone():Boolean;
var
  counter : integer;
Begin
result := false;
EnterCriticalSection(CSMNsChecks);
for counter := 0 to length(ArrMNChecks)-1 do
   begin
   if ArrMNChecks[counter].ValidatorIP = MN_IP then
      begin
      result := true;
      break;
      end;
   end;
LeaveCriticalSection(CSMNsChecks);
End;

Function ValidatorsCount():Integer;
Begin
Result := length(ListaNodos);
End;

Function IsValidator(Ip:String):boolean;
Begin
result := false;
if IsSeedNode(IP) then result := true;
End;

Function GetMNReportString():String;
Begin
// {5}IP 6{Port} 7{SignAddress} 8{FundsAddress} 9{FirstBlock} 10{LastVerified}
//    11{TotalVerified} 12{BlockVerifys} 13{hash}
result := MN_IP+' '+MN_Port+' '+MN_Sign+' '+MN_Funds+' '+MyLastBlock.ToString+' '+MyLastBlock.ToString+' '+
   '0'+' '+'0'+' '+HashMD5String(MN_IP+MN_Port+MN_Sign+MN_Funds);
End;

Function GetStringFromMN(Node:TMNode):String;
Begin
result := Node.Ip+' '+Node.Port.ToString+' '+Node.Sign+' '+Node.Fund+' '+Node.First.ToString+' '+Node.Last.ToString+' '+
          Node.Total.ToString+' '+Node.Validations.ToString+' '+Node.Hash;
End;

Function GetMNsListLength():Integer;
Begin
EnterCriticalSection(CSMNsArray);
Result := Length(MNsList);
LeaveCriticalSection(CSMNsArray);
End;

function MyMNIsListed():boolean;
var
  counter : integer;
Begin
result := false;
if GetMNsListLength > 0 then
   begin
   EnterCriticalSection(CSMNsArray);
   for counter := 0 to length(MNsList)-1 do
      begin
      if MNsList[counter].Ip = MN_IP then
         begin
         result := true;
         break;
         end;
      end;
   LeaveCriticalSection(CSMNsArray);
   end;
End;

Function GetMNodeFromString(const StringData:String; out ToMNode:TMNode):Boolean;
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
else if ( (ToMNode.Port<0) or (ToMNode.Port>65535) ) then result := false
else if not IsValidHashAddress(ToMNode.Sign) then result := false
else if not IsValidHashAddress(ToMNode.Fund) then result := false
else if ToMNode.first < 0 then result := false
else if ToMNode.last < 0 then result := false
else if ToMNode.total <0 then result := false
else if ToMNode.validations < 0 then result := false
else if ToMNode.hash <> HashMD5String(ToMNode.Ip+IntToStr(ToMNode.Port)+ToMNode.Sign+ToMNode.Fund) then result := false;
End;

Function IsLegitNewNode(ThisNode:TMNode):Boolean;
var
  counter : integer;
Begin
result := true;
if GetMNsListLength>0 then
   begin
   EnterCriticalSection(CSMNsArray);
   For counter := 0 to length(MNsList)-1 do
      begin
      if ( (ThisNode.Ip = MNsList[counter].Ip) or
           (ThisNode.Sign = MNsList[counter].Sign) or
           (ThisNode.Fund = MNsList[counter].Fund) or
           (ThisNode.First>MyLastBlock) or
           (ThisNode.Last>MyLastBlock) or
           (ThisNode.Total<>0) or
           (GetAddressBalance(ThisNode.Fund) < GetStackRequired(MyLastBlock+1)) or
           (ThisNode.Validations<>0) ) then
              begin
              Result := false;
              break;
              end;
      end;
   LeaveCriticalSection(CSMNsArray);
   end;
End;

Procedure CheckMNRepo(LineText:String);
var
  StartPos   : integer;
  ReportInfo : string = '';
  NewNode    : TMNode;
  counter    : integer;
  Added      : boolean = false;
Begin
StartPos := Pos('$',LineText);
ReportInfo := copy (LineText,StartPos,length(LineText));
if GetMNodeFromString(ReportInfo,NewNode) then
   Begin
   if IsLegitNewNode(NewNode) then
      begin
      EnterCriticalSection(CSMNsArray);
      if LEngth(MNsList) = 0 then
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
      LeaveCriticalSection(CSMNsArray);
      outGOingMsjsAdd(GetPTCEcn+ReportInfo);
      U_MNsGrid := true;
      end;
   end;
End;

Procedure SendMNsList(Slot:Integer);
var
  Counter : integer;
  Texto : string;
Begin
if GetMNsListLength>0 then
   begin
   EnterCriticalSection(CSMNsArray);
   for counter := 0 to length(MNsList)-1 do
      begin
      Texto := GetPTCEcn+'$MNREPO '+GetStringFromMN(MNsList[counter]);
      PTC_SendLine(slot,Texto);
      end;
   LeaveCriticalSection(CSMNsArray);
   end;
End;

Procedure CleanMasterNodes(BlockNumber:Integer);
var
  counter        : integer = 1;
  Deleted        : boolean = false;
  TotalDeleted   : integer = 0;
  MinValidations : Integer;
Begin
MinValidations := (ValidatorsCount div 2) - 1;
EnterCriticalSection(CSMNsArray);
While Counter <= length(MNsList) do
   Begin
   Deleted := false;
   if ( (MNsList[counter-1].Last+3<BlockNumber) and (MNsList[counter-1].Validations<MinValidations) ) then
      begin
      Delete(MNsList,counter-1,1);
      Deleted := true;
      Inc(TotalDeleted);
      end;
   If not Deleted then Inc(Counter);
   end;
for counter := 0 to length(MNsList)-1 do
   begin
   if MNsList[counter].Validations >= MinValidations then
      Begin
      MNsList[counter].Last:=BlockNumber;
      MNsList[counter].Total:= +1;
      end;
   MNsList[counter].Validations := 0;
   end;

LeaveCriticalSection(CSMNsArray);
//ConsoleLinesAdd('Deleted MNs : '+TotalDeleted.toString);
U_MNsGrid := true;
End;

Function GetVerificationMNLine():String;
Begin
if IsAllSynced then Result := 'True '+GetSyncTus
else Result := 'False';
End;

Procedure SaveMNsFile();
var
  archivo : textfile;
  Counter : integer;
Begin
EnterCriticalSection(CSMNsArray);
   TRY
   Assignfile(archivo, MAsternodesfilename);
   rewrite(archivo);
   For counter := 0 to length(MNsList)-1 do
      begin
      WriteLn(archivo,MNsList[counter].Fund+' '+IntToStr(MNsList[counter].Last)+' '+IntToStr(MNsList[counter].Total));
      end;
   Closefile(archivo);
   EXCEPT on E:Exception do
      tolog ('Error Saving masternodes file');
   END {TRY};
LEaveCriticalSection(CSMNsArray);
End;

Procedure CreditMNVerifications();
var
  counter     : integer;
  NodesString : string;
  ThisIP      : string;
  IPIndex     : integer;

  Procedure AddCheckToIP(IP:String);
  var
    counter2 : integer;
  Begin
  For counter2 := 0 to length(MNsList)-1 do
     begin
     if MNsList[Counter2].Ip = IP then
        begin
        MNsList[Counter2].Validations:=MNsList[Counter2].Validations+1;
        Break;
        end;
     end;
  End;

Begin
EnterCriticalSection(CSMNsArray);
EnterCriticalSection(CSMNsChecks);
for counter := 0 to length(ArrMNChecks)-1 do
   begin
   NodesString := StringReplace(ArrMNChecks[counter].ValidNodes,':',' ',[rfReplaceAll]);
   IPIndex := 0;
   REPEAT
      begin
      ThisIP := Parameter(NodesString,IPIndex);
      if ThisIP <> '' then
         begin
         AddCheckToIP(ThisIP);
         end;
      Inc(IPIndex);
      end;
   UNTIL ThisIP = '';
   end;

LeaveCriticalSection(CSMNsChecks);
LeaveCriticalSection(CSMNsArray);
End;

Initialization
InitCriticalSection(CSVerNodes);
InitCriticalSection(DecVerThreads);
InitCriticalSection(CSMNsChecks);


Finalization
DoneCriticalSection(CSVerNodes);
DoneCriticalSection(DecVerThreads);
DoneCriticalSection(CSMNsChecks);

END. // End UNIT

