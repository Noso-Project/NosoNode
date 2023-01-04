unit mpMN;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalform, mpcoin, mpgui, IdTCPClient, IdGlobal,
  strutils, nosodebug, nosogeneral, nosocrypto, nosotime, nosounit;

Type

   TThreadMNVerificator = class(TThread)
      private
        FSlot: Integer;
      protected
        procedure Execute; override;
      public
        constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
      end;

Function NoVerificators():integer;
Function RunMNVerification():String;
Function GetMNCheckFromString(Linea:String):TMNCheck;

Function GetMNsChecksCount():integer;
Procedure ClearMNsChecks();
Function MnsCheckExists(Ip:String):Boolean;
Procedure AddMNCheck(ThisData:TMNCheck);
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
Procedure ClearMNsList();
Function GetMNodeFromString(const StringData:String; out ToMNode:TMNode):Boolean;
Function IsLegitNewNode(ThisNode:TMNode):Boolean;
Procedure CheckMNRepo(LineText:String);
Procedure SendMNsList(Slot:Integer);
Function GetVerificationMNLine(ToIp:String):String;

Procedure CreditMNVerifications();

Function GetMNsAddresses():String;
Function GetMNsFileData():String;
Procedure FillMNsArray(TValue:String);
Procedure SetMN_FileText(Tvalue:String);
Function GetMN_FileText():String;
Procedure SaveMNsFile(GotText:string);
Procedure PTC_MNFile(Linea:String);

// Waiting MNs

Function LengthWaitingMNs():Integer;
Function IsIPMNAlreadyProcessed(OrderText:string):Boolean;
Function GetMNSignature():string;
Procedure AddWaitingMNs(Linea:String);
Function GetWaitingMNs():String;

var
  ArrayIPsProcessed : array of string;
  OpenVerificators : integer;
  MNsListCopy : array of TMnode;
  CurrSynctus : string;
  VerifiedNodes : String;
  UnconfirmedIPs : integer;
  CSVerNodes    : TRTLCriticalSection;
  CSMNsChecks   : TRTLCriticalSection;
  DecVerThreads : TRTLCriticalSection;
  CSMNsFile     : TRTLCriticalSection;
  CSMNsIPCheck  : TRTLCriticalSection;
  CSMN_FileText : TRTLCriticalSection;

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
If Parameter(Linea,3) <> MN_Ip then Inc(UnconfirmedIPs);
EXCEPT on E:Exception do
   begin
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'CRITICAL MNs VERIFICATION ('+Ip+'): '+E.Message);
   end;
END{BIG TRY};
EnterCriticalSection(DecVerThreads);
Dec(OpenVerificators);
LeaveCriticalSection(DecVerThreads);
CloseOpenThread('VerifyMN '+FSlot.ToString);
End;

Function NoVerificators():integer;
Begin
EnterCriticalSection(DecVerThreads);
result := OpenVerificators;
LeaveCriticalSection(DecVerThreads);
End;

function RunMNVerification():String;
var
  counter : integer;
  ThisThread : TThreadMNVerificator;
  Launched : integer = 0;
  WaitCycles : integer = 0;
  DataLine : String;

Begin
Result := '';
CurrSynctus := GetSyncTus;
VerifiedNodes := '';
setlength(MNsListCopy,0);
EnterCriticalSection(CSMNsArray);
MNsListCopy := copy(MNsList,0,length(MNsList));
LeaveCriticalSection(CSMNsArray);
UnconfirmedIPs := 0;
for counter := 0 to length(MNsListCopy)-1 do
   begin
   if (( MNsListCopy[counter].ip <> MN_Ip) and (IsValidIp(MNsListCopy[counter].ip)) ) then
      begin
      Inc(Launched);
      ThisThread := TThreadMNVerificator.Create(true,counter);
      ThisThread.FreeOnTerminate:=true;
      ThisThread.Start;
      end;
   end;
EnterCriticalSection(DecVerThreads);
OpenVerificators := Launched;
LeaveCriticalSection(DecVerThreads);
AddLineToDebugLog('events',TimeToStr(now)+Format('MNs verification Launched: %d to verify',[Launched]));
Repeat
  sleep(100);
  Inc(WaitCycles);
until ( (NoVerificators= 0) or (WaitCycles = 150) );
AddLineToDebugLog('events',TimeToStr(now)+Format('MNs verification finish: %d launched, %d Open, %d cycles',[Launched,NoVerificators,WaitCycles ]));
AddLineToDebugLog('events',TimeToStr(now)+Format('Unconfirmed IPs: %d',[UnconfirmedIPs ]));
if NoVerificators>0 then
   begin
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'*****CRITICAL****'+slinebreak+'Open verificators : '+NoVerificators.ToString);
   EnterCriticalSection(DecVerThreads);
   OpenVerificators := 0;
   LeaveCriticalSection(DecVerThreads);
   end;
DataLine := MN_IP+' '+MyLastBlock.ToString+' '+MN_Sign+' '+ListaDirecciones[DireccionEsMia(MN_Sign)].PublicKey+' '+
            VerifiedNodes+' '+GetStringSigned(VerifiedNodes,ListaDirecciones[DireccionEsMia(MN_Sign)].PrivateKey);
OutGoingMsjsAdd(ProtocolLine(MNCheck)+DataLine);
Result := Launched.ToString+':'+VerifiedNodes
End;

// Converts a string into a TMNChekc data
Function GetMNCheckFromString(Linea:String):TMNCheck;
Begin
Result.ValidatorIP    :=Parameter(Linea,5);
Result.Block          :=StrToIntDef(Parameter(Linea,6),0);
Result.SignAddress    :=Parameter(Linea,7);
Result.PubKey         :=Parameter(Linea,8);
Result.ValidNodes     :=Parameter(Linea,9);
Result.Signature      :=Parameter(Linea,10);
End;

// Returns the number of MNs checks
Function GetMNsChecksCount():integer;
Begin
EnterCriticalSection(CSMNsChecks);
result := Length(ArrMNChecks);
LeaveCriticalSection(CSMNsChecks);
End;

// Clears all the MNS checks
Procedure ClearMNsChecks();
Begin
EnterCriticalSection(CSMNsChecks);
SetLength(ArrMNChecks,0);
LeaveCriticalSection(CSMNsChecks);
End;

// Verify if an IP already sent a verification
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

// Adds a new MNCheck
Procedure AddMNCheck(ThisData:TMNCheck);
Begin
EnterCriticalSection(CSMNsChecks);
Insert(ThisData,ArrMNChecks,Length(ArrMNChecks));
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
   //AddLineToDebugLog('events',TimeToStr(now)+CheckData.ValidNodes);
   if form1.Server.Active then
      outGOingMsjsAdd(GetPTCEcn+ReportInfo);
   //AddLineToDebugLog('console','Check received from '+CheckData.validnodes);
   //AddLineToDebugLog('events',TimeToStr(now)+'Good check : (('+Linea+'))');
   end
else
   begin
   //AddLineToDebugLog('console','Wrong check from '+CheckData.ValidatorIP+'->'+ErrorCode.ToString);
   //AddLineToDebugLog('events',TimeToStr(now)+'Wrong MNCheck: (-('+Linea+')-)');
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

// Verify is there are a masternode verification from the user
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

// Returns the string to send the own MN report
Function GetMNReportString():String;
var
  IpToUse : string;
  IPTrys  : integer = 0;
Begin
// {5}IP 6{Port} 7{SignAddress} 8{FundsAddress} 9{FirstBlock} 10{LastVerified}
//    11{TotalVerified} 12{BlockVerifys} 13{hash}
if MN_AutoIP then
   begin
   REPEAT
   Inc(IPTrys);
   IpToUse := GetMiIP;
   sleep(1);
   until ( (IsValidIP(IpToUse)) or (IPTrys=5) );
   if IPToUse = '' then IpToUse := MN_IP;
   end
else IpToUse := MN_IP;
if IPToUse <> MN_IP then
   begin
   MN_IP := IPToUse;
   S_AdvOpt := true;
   end;
result := IpToUse+' '+MN_Port+' '+MN_Sign+' '+MN_Funds+' '+MyLastBlock.ToString+' '+MyLastBlock.ToString+' '+
   '0'+' '+'0'+' '+HashMD5String(IpToUse+MN_Port+MN_Sign+MN_Funds);
End;

// Converst a MNNode data into a string
Function GetStringFromMN(Node:TMNode):String;
Begin
result := Node.Ip+' '+Node.Port.ToString+' '+Node.Sign+' '+Node.Fund+' '+Node.First.ToString+' '+Node.Last.ToString+' '+
          Node.Total.ToString+' '+Node.Validations.ToString+' '+Node.Hash;
End;

// Returns the count of reported MNs
Function GetMNsListLength():Integer;
Begin
EnterCriticalSection(CSMNsArray);
Result := Length(MNsList);
LeaveCriticalSection(CSMNsArray);
End;

// Clears all the reported MNs
Procedure ClearMNsList();
Begin
EnterCriticalSection(CSMNsArray);
SetLength(MNsList,0);
LeaveCriticalSection(CSMNsArray);
EnterCriticalSection(CSMNsIPCheck);
Setlength(ArrayIPsProcessed,0);
LeaveCriticalSection(CSMNsIPCheck);
End;

// Returns if the user MN is already reported
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
   //AddLineToDebugLog('console','MASTERNODE REJECTED ERROR: '+ErrCode.ToString);
   end;
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
           (GetAddressBalanceIndexed(ThisNode.Fund) < GetStackRequired(MyLastBlock+1)) or
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
      if form1.Server.Active then outGOingMsjsAdd(GetPTCEcn+ReportInfo);
      U_MNsGrid := true;
      end
   else
      begin
      //AddLineToDebugLog('console','NO LEGIT Masternode: '+Reportinfo);
      end;
   end
else
   begin
   //AddLineToDebugLog('console','REJECTED Masternode: '+Reportinfo);
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

{Returns the response to the validators request}
Function GetVerificationMNLine(ToIp:String):String;
Begin
if IsAllSynced=0 then
   begin
   Result := 'True '+GetSyncTus+' '+MN_Funds+' '+ToIp;
   Inc(G_MNVerifications);
   end
else Result := 'False';
End;

Function GetMNAgeCount(TNode:TMNode):string;
var
  TIpandPort : string;
  counter    : integer;
  Number     : integer=0;
Begin
result := '';
//if MyLastBlock < 65500 then exit;
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

Function GetMNsAddresses():String;
var
  MinValidations : integer;
  Counter        : integer;
  Resultado      : string = '';
  AddAge         : string = '';
Begin
MinValidations := (GetMNsChecksCount div 2) - 1;
Resultado := MyLastBlock.ToString+' ';
EnterCriticalSection(CSMNsArray);
For counter := 0 to length(MNsList)-1 do
      begin
      if MNsList[counter].Validations>= MinValidations then
         begin
         AddAge := GetMNAgeCount(MNsList[counter]);
         Resultado := Resultado + MNsList[counter].Ip+';'+MNsList[counter].Port.ToString+':'+MNsList[counter].Fund+
            AddAge+' ';
         end;
      end;
LeaveCriticalSection(CSMNsArray);
SetLength(Resultado, Length(Resultado)-1);
result := Resultado;
End;

Function GetMNsFileData():String;
var
  archivo : textfile;
  Linea   : string = '';
Begin
EnterCriticalSection(CSMNsFile);
TRY
Assignfile(archivo, MAsternodesfilename);
reset(archivo);
Readln(Archivo,Linea);
Closefile(archivo);
EXCEPT on E:Exception do
   begin
   AddLineToDebugLog('events',TimeToStr(now)+'Error Saving masternodes file');
   Linea := '';
   end;
END {TRY};
LeaveCriticalSection(CSMNsFile);
if AnsiContainsStr(Linea,MN_IP) then
   begin
   Form1.imagenes.GetBitMap(68,Form1.StaSerImg.Picture.Bitmap);
   Form1.StaSerImg.Hint:='Masternode Earning!';
   end
else
   begin
   Form1.imagenes.GetBitMap(27,Form1.StaSerImg.Picture.Bitmap);
   Form1.StaSerImg.Hint:='Check your Masternode config';
   end;
SetMN_FileText(linea);
Result := Linea;
MyMNsHash     := HashMD5File(MasterNodesFilename);
//MyMNsHash     := HashMD5File(GetMN_FileText);
End;

Procedure FillMNsArray(TValue:String);
var
  counter   : integer = 1;
  count2    : integer = 0;
  ThisData  : string  = '';
  ThisMN    : TMNsData;
  TempArray : array of TMNsData;
  Added     : boolean = false;
Begin
BeginPerformance('FillMNsArray');
SetLength(ArrayMNsData,0);
SetLength(TempArray,0);
Repeat
   ThisData := Parameter(Tvalue,counter);
   if ThisData <> '' then
      begin
      ThisData := StringReplace(ThisData,':',' ',[rfReplaceAll]);
      ThisMN.ipandport:=Parameter(ThisData,0);
      ThisMN.address  :=Parameter(ThisData,1);
      ThisMN.age      :=StrToIntDef(Parameter(ThisData,2),1);
      Insert(ThisMN,TempArray,length(TempArray));
      end;
   inc(counter);
until thisData = '';
for counter := 0 to length(TempArray)-1 do
   begin
   ThisMN := TempArray[counter];
   Added := false;
   if length(ArrayMNsData) = 0 then
      Insert(ThisMN,ArrayMNsData,0)
   else
      begin
      for count2 := 0 to length(ArrayMNsData)-1 do
         begin
         if ThisMN.age > ArrayMNsData[count2].age then
            begin
            Insert(ThisMN,ArrayMNsData,count2);
            added := true;
            break;
            end;
         end;
      if not added then Insert(ThisMN,ArrayMNsData,length(ArrayMNsData));
      end;
   end;
EndPerformance('FillMNsArray');
End;

Procedure SetMN_FileText(Tvalue:String);
Begin
EnterCriticalSection(CSMN_FileText);
MN_FileText := Tvalue;
FillMNsArray(TValue);
LeaveCriticalSection(CSMN_FileText);
End;

Function GetMN_FileText():String;
Begin
EnterCriticalSection(CSMN_FileText);
Result := MN_FileText;
LeaveCriticalSection(CSMN_FileText);
End;

Procedure SaveMNsFile(GotText:string);
var
  archivo        : textfile;
Begin
EnterCriticalSection(CSMNsFile);
TRY
Assignfile(archivo, MAsternodesfilename);
rewrite(archivo);
write(Archivo,GotText,#13#10);
Closefile(archivo);
SetMN_FileText(GotText);
EXCEPT on E:Exception do
   begin
   AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error Saving masternodes file');
   SetMN_FileText('');
   end;
END {TRY};
LeaveCriticalSection(CSMNsFile);
MyMNsHash     := HashMD5File(MasterNodesFilename);
if AnsiContainsStr(GotText,MN_IP) then
   begin
   Form1.imagenes.GetBitMap(68,Form1.StaSerImg.Picture.Bitmap);
   Form1.StaSerImg.Hint:='Masternode Earning!';
   end
else
   begin
   Form1.imagenes.GetBitMap(27,Form1.StaSerImg.Picture.Bitmap);
   Form1.StaSerImg.Hint:='Check your Masternode config';
   end;
End;

Procedure PTC_MNFile(Linea:String);
var
  startpos : integer;
  content : string;
Begin
startpos := Pos('$',Linea);
Content := Copy(Linea,Startpos+1,Length(linea));
SaveMNsFile(content);
end;

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
        MNsList[Counter2].Validations := MNsList[Counter2].Validations+1;
        Break;
        end;
     end;
  End;

Begin
EnterCriticalSection(CSMNsArray);
EnterCriticalSection(CSMNsChecks);
for counter := 0 to length(ArrMNChecks)-1 do
   begin
   NodesString := ArrMNChecks[counter].ValidNodes;
   NodesString := StringReplace(NodesString,':',' ',[rfReplaceAll]);
   //AddLineToDebugLog('console',NodesString);
   IPIndex := 0;
   REPEAT
      begin
      ThisIP := Parameter(NodesString,IPIndex);
      ThisIP := StringReplace(ThisIP,';',' ',[rfReplaceAll]);
      ThisIP := Parameter(ThisIP,0);
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

Function LengthWaitingMNs():Integer;
Begin
EnterCriticalSection(CSWaitingMNs);
result := Length(WaitingMNs);
LeaveCriticalSection(CSWaitingMNs);
End;

Function IsIPMNAlreadyProcessed(OrderText:string):Boolean;
var
  ThisIP : string;
  counter : integer;
Begin
result := false;
ThisIP := parameter(OrderText,5);
EnterCriticalSection(CSMNsIPCheck);
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
LeaveCriticalSection(CSMNsIPCheck);
End;

// Returns the signature for the masternode report
Function GetMNSignature():string;
var
  TextToSign : string = '';
  SignAddressIndex : integer;
  PublicKey : string;
  CurrentTime : string;
  ReportHash : string;
Begin
BeginPerformance('GetMNSignature');
result := '';
CurrentTime := UTCTimeStr;
TextToSign := CurrentTime+' '+MN_IP+' '+MyLastBlock.ToString+' '+MyLastBlockHash;
ReportHash := HashMD5String(TextToSign);
SignAddressIndex := DireccionEsMia(MN_Sign);
if SignAddressIndex<0 then result := ''
else
   begin
   PublicKey := ListaDirecciones[SignAddressIndex].PublicKey;
   result := CurrentTime+' '+PublicKey+' '+GetStringSigned(TextToSign,ListaDirecciones[SignAddressIndex].PrivateKey)+' '+ReportHash;
   end;
EndPerformance('GetMNSignature');
End;

Procedure AddWaitingMNs(Linea:String);
Begin
EnterCriticalSection(CSWaitingMNs);
Insert(Linea,WaitingMNs,Length(WaitingMNs));
LeaveCriticalSection(CSWaitingMNs);
End;

Function GetWaitingMNs():String;
Begin
result := '';
EnterCriticalSection(CSWaitingMNs);
if length(WaitingMNs)>0 then
   begin
   Result := WaitingMNs[0];
   Delete(WaitingMNs,0,1);
   end;
LeaveCriticalSection(CSWaitingMNs);
End;

Initialization
InitCriticalSection(CSVerNodes);
InitCriticalSection(DecVerThreads);
InitCriticalSection(CSMNsChecks);
InitCriticalSection(CSMNsFile);
InitCriticalSection(CSMNsIPCheck);
InitCriticalSection(CSMN_FileText);

SetLength(ArrayIPsProcessed,0);

Finalization
DoneCriticalSection(CSVerNodes);
DoneCriticalSection(DecVerThreads);
DoneCriticalSection(CSMNsChecks);
DoneCriticalSection(CSMNsFile);
DoneCriticalSection(CSMNsIPCheck);
DoneCriticalSection(CSMN_FileText);

END. // End UNIT

