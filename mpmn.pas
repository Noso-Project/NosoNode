unit mpMN;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpCripto, MasterPaskalform, mpcoin, mpgui;

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

implementation

Uses
  mpParser, mpProtocol, mpDisk;

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
var
  Texto : string = '';
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
  counter : integer = 1;
  Deleted : boolean = false;
  TotalDeleted : integer = 0;
Begin
EnterCriticalSection(CSMNsArray);
While Counter <= length(MNsList) do
   Begin
   Deleted := false;
   if ( (MNsList[counter-1].Last+3<BlockNumber) and (MNsList[counter-1].Validations=0) ) then
      begin
      Delete(MNsList,counter-1,1);
      Deleted := true;
      Inc(TotalDeleted);
      end;
   If not Deleted then Inc(Counter);
   end;
LeaveCriticalSection(CSMNsArray);
ConsoleLinesAdd('Deleted MNs : '+TotalDeleted.toString);
U_MNsGrid := true;
End;

END. // End UNIT

