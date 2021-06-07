unit mpRPC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpgui, FPJSON, jsonparser, mpCripto, mpCoin;

Procedure SetRPCPort(LineText:string);
Procedure SetRPCOn();
Procedure SetRPCOff();

// *** RPC PARSE FUNCTIONS ***

function IsValidJSON (MyJSONstring:string):boolean;
Function GetJSONErrorString(ErrorCode:integer):string;
function GetJSONErrorCode(ErrorCode, JSONIdNumber:integer):TJSONStringType;
function GetJSONResponse(ResultToSend:string;JSONIdNumber:integer):TJSONStringType;
function ParseRPCJSON(jsonreceived:string):TJSONStringType;

function RPC_AddressBalance(NosoPParams:string):string;


implementation

Uses
  MasterPaskalForm,mpparser;

// Sets RPC port
Procedure SetRPCPort(LineText:string);
var
  value : integer;
Begin
value := StrToIntDef(parameter(LineText,1),0);
if ((value <=0) or (value >65535)) then
   begin
   ConsoleLinesAdd('Invalid value');
   end
else if Form1.RPCServer.Active then
   consolelinesadd('Can not change the RPC port when it is active')
else
   begin
   RPCPort := value;
   ConsoleLinesAdd('RPC port set to: '+IntToStr(value));
   S_AdvOpt := true;
   end;
End;

// Turn on RPC server
Procedure SetRPCOn();
Begin
if not Form1.RPCServer.Active then
   begin
      try
      Form1.RPCServer.Bindings.Clear;
      Form1.RPCServer.DefaultPort:=RPCPort;
      Form1.RPCServer.Active:=true;
      ConsoleLinesAdd('RPC server ENABLED');
      Except on E:Exception do
         begin
         ConsoleLinesAdd('Unable to start RPC port');
         G_Launching := true;
         form1.CB_RPC_ON.Checked:=false;
         G_Launching := false;
         end;
      end;
   end
else ConsoleLinesAdd('RPC server already ENABLED');
End;

// Turns off RPC server
Procedure SetRPCOff();
Begin
if Form1.RPCServer.Active then
   begin
   Form1.RPCServer.Active:=false;
   ConsoleLinesAdd('RPC server DISABLED');
   end
else ConsoleLinesAdd('RPC server already DISABLED');
End;

// ***************************
// *** RPC PARSE FUNCTIONS ***
// ***************************

// Returns if a string is a valid JSON data
function IsValidJSON (MyJSONstring:string):boolean;
var
  MyData: TJSONData;
begin
result := true;
   Try
   MyData := GetJSON(MyJSONstring);
   except on E:ejsonparser do
      result := false;
   end;
Mydata.free;
end;

// Returns the string of each error code
Function GetJSONErrorString(ErrorCode:integer):string;
Begin
if ErrorCode = 400 then result := 'Bad Request'
else if ErrorCode = 401 then result := 'Invalid JSON request'
else if ErrorCode = 402 then result := 'Invalid method'
else if ErrorCode = 499 then result := 'Unexpected error'
{...}
else result := 'Unknown error code';
End;

// Returns a valid error JSON String
function GetJSONErrorCode(ErrorCode, JSONIdNumber:integer):TJSONStringType;
var
  JSONResultado,JSONErrorObj: TJSONObject;
Begin
  result := '';
JSONResultado := TJSONObject.Create;
JSONErrorObj  := TJSONObject.Create;
   try
   JSONResultado.Add('jsonrpc', TJSONString.Create('2.0'));
   JSONErrorObj.Add('code', TJSONIntegerNumber.Create(ErrorCode));
   JSONErrorObj.Add('message', TJSONString.Create(GetJSONErrorString(ErrorCode)));
   JSONResultado.Add('error',JSONErrorObj);
   JSONResultado.Add('id', TJSONIntegerNumber.Create(JSONIdNumber));
   finally
   result := JSONResultado.AsJSON;
   JSONResultado.Free;
   end;
End;

// Returns a valid response JSON string
function GetJSONResponse(ResultToSend:string;JSONIdNumber:integer):TJSONStringType;
var
  JSONResultado: TJSONObject;
  paramsarray :  TJSONArray;
  myParams: TStringArray;
  counter : integer;
Begin
paramsarray := TJSONArray.Create;
if length(ResultToSend)>0 then myParams:= ResultToSend.Split(' ');
JSONResultado := TJSONObject.Create;
   try
      try
      JSONResultado.Add('jsonrpc', TJSONString.Create('2.0'));
      if length(myparams) > 0 then
         for counter := low(myParams) to high(myParams) do
            if myParams[counter] <>'' then paramsarray.Add(myParams[counter]);
      JSONResultado.Add('result', paramsarray);
      JSONResultado.Add('id', TJSONIntegerNumber.Create(JSONIdNumber));
      Except on E:Exception do
         begin
         result := GetJSONErrorCode(499,JSONIdNumber);
         JSONResultado.Free;
         paramsarray.Free;
         exit;
         end;
      end;
   finally
   result := JSONResultado.AsJSON;
   //paramsarray.Free;
   JSONResultado.Free;
   end;
End;

function ObjectFromString(MyString:string): TJSONObject;
Begin

End;

// Parses a incoming JSON string
function ParseRPCJSON(jsonreceived:string):TJSONStringType;
var
  jData : TJSONData;
  jObject : TJSONObject;
  method : string;
  params: TJSONArray;
  jsonID : integer;
  NosoPParams: String = '';
  counter : integer;
Begin
Result := '';
if not IsValidJSON(jsonreceived) then result := GetJSONErrorCode(401,-1)
else
   begin
   jData := GetJSON(jsonreceived);
   jObject := TJSONObject(jData);
   method := jObject.Strings['method'];
   params := jObject.Arrays['params'];
   jsonid := jObject.Integers['id'];
   for counter := 0 to params.Count-1 do
      NosoPParams:= NosoPParams+' '+params[counter].AsString;
   NosoPParams:= Trim(NosoPParams);
   consolelinesadd(jsonreceived);
   consolelinesadd(NosoPParams);
   if method = 'test' then result := GetJSONResponse('testok',jsonid)
   else if method = 'getbalance' then result := GetJSONResponse(int2curr(GetWalletBalance),jsonid)
   else if method = 'getaddressbalance' then result := GetJSONResponse(RPC_AddressBalance(NosoPParams),jsonid)

   else result := GetJSONErrorCode(402,-1);
   end;
End;

function RPC_AddressBalance(NosoPParams:string):string;
var
  ThisAddress: string;
  counter : integer = 0;
  Balance, incoming, outgoing : int64;
Begin
result := '';
if NosoPParams <> '' then
   begin
   Repeat
   ThisAddress := parameter(NosoPParams,counter);
   if ThisAddress <>'' then
      begin
      Balance := GetAddressBalance(ThisAddress);
      incoming := GetAddressIncomingpays(ThisAddress);
      outgoing := GetAddressPendingPays(ThisAddress);
      result := result+format('balance,%s,%d,%d,%d ',[ThisAddress,balance,incoming,outgoing]);
      end;
   counter+=1;
   until ThisAddress = '';
   trim(result);
   end;
End;

END.  // END UNIT

