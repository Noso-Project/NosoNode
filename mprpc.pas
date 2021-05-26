unit mpRPC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpgui, FPJSON, jsonparser;

Procedure SetRPCPort(LineText:string);
Procedure SetRPCOn();
Procedure SetRPCOff();

// *** RPC PARSE FUNCTIONS ***

function IsValidJSON (MyJSONstring:string):boolean;
Function GetJSONErrorString(ErrorCode:integer):string;
function GetJSONErrorCode(ErrorCode, JSONIdNumber:integer):TJSONStringType;
function GetJSONResponse(ResultToSend:string;JSONIdNumber:integer):TJSONStringType;
function ParseRPCJSON(jsonreceived:string):TJSONStringType;


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
   end;
S_AdvOpt := true;
End;

// Turn on RPC server
Procedure SetRPCOn();
Begin
if not Form1.RPCServer.Active then
   begin
   Form1.RPCServer.Bindings.Clear;
   Form1.RPCServer.DefaultPort:=RPCPort;
   Form1.RPCServer.Active:=true;
   ConsoleLinesAdd('RPC server ENABLED');
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
Begin
JSONResultado := TJSONObject.Create;
   try
   JSONResultado.Add('jsonrpc', TJSONString.Create('2.0'));
   JSONResultado.Add('result', TJSONString.Create(ResultToSend));
   JSONResultado.Add('id', TJSONIntegerNumber.Create(JSONIdNumber));
   finally
   result := JSONResultado.AsJSON;
   JSONResultado.Free;
   end;
End;

// Parses a incoming JSON string
function ParseRPCJSON(jsonreceived:string):TJSONStringType;
var
  jData : TJSONData;
  jObject : TJSONObject;
  method, params : string;
  jsonID : integer;
Begin
Result := '';
if not IsValidJSON(jsonreceived) then result := GetJSONErrorCode(401,-1)
else
   begin
   jData := GetJSON(jsonreceived);
   jObject := TJSONObject(jData);
   method := jObject.Get('method');
   params := jObject.Get('params');
   jsonid := jObject.Get('id');
   if method = 'test' then result := GetJSONResponse('TestOk',jsonid)
   else if method = 'getbalance' then result := GetJSONResponse(int2curr(GetWalletBalance),jsonid)

   else result := GetJSONErrorCode(402,-1);
   end;
End;

END.

