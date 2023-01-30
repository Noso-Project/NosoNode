unit mpRPC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpgui, FPJSON, jsonparser, mpCoin, mpRed, mpBlock,nosodebug,
  nosogeneral, nosocrypto, nosounit;

Procedure SetRPCPort(LineText:string);
Procedure setRPCpassword(newpassword:string);
Procedure SetRPCOn();
Procedure SetRPCOff();

// *** RPC PARSE FUNCTIONS ***

function IsValidJSON (MyJSONstring:string):boolean;
Function GetJSONErrorString(ErrorCode:integer):string;
function GetJSONErrorCode(ErrorCode, JSONIdNumber:integer):string;
function GetJSONResponse(ResultToSend:string;JSONIdNumber:integer):string;
function ParseRPCJSON(jsonreceived:string):string;

function ObjectFromString(MyString:string): string;

function RPC_AddressBalance(NosoPParams:string):string;
function RPC_OrderInfo(NosoPParams:string):string;
function RPC_Blockinfo(NosoPParams:string):string;
function RPC_Mininginfo(NosoPParams:string):string;
function RPC_Mainnetinfo(NosoPParams:string):string;
function RPC_PendingOrders(NosoPParams:string):string;
function RPC_GetPeers(NosoPParams:string):string;
function RPC_BlockOrders(NosoPParams:string):string;
function RPC_Blockmns(NosoPParams:string):string;
function RPC_NewAddress(NosoPParams:string):string;
function RPC_SendFunds(NosoPParams:string):string;


implementation

Uses
  MasterPaskalForm,mpparser, mpDisk, mpProtocol;

// Sets RPC port
Procedure SetRPCPort(LineText:string);
var
  value : integer;
Begin
value := StrToIntDef(parameter(LineText,1),0);
if ((value <=0) or (value >65535)) then
   begin
   AddLineToDebugLog('console','Invalid value');
   end
else if Form1.RPCServer.Active then
   AddLineToDebugLog('console','Can not change the RPC port when it is active')
else
   begin
   RPCPort := value;
   AddLineToDebugLog('console','RPC port set to: '+IntToStr(value));
   S_AdvOpt := true;
   end;
End;

Procedure setRPCpassword(newpassword:string);
var
  counter : integer;
  oldpassword : string;
Begin
oldpassword := RPCPass;
trim(newpassword);
RPCPass := newpassword;
End;

// Turn on RPC server
Procedure SetRPCOn();
Begin
if not Form1.RPCServer.Active then
   begin
      TRY
      Form1.RPCServer.Bindings.Clear;
      Form1.RPCServer.DefaultPort:=RPCPort;
      Form1.RPCServer.Active:=true;
      G_Launching := true;
      form1.CB_RPC_ON.Checked:=true;
      G_Launching := false;
      AddLineToDebugLog('console','RPC server ENABLED');
      EXCEPT on E:Exception do
         begin
         AddLineToDebugLog('console','Unable to start RPC port');
         G_Launching := true;
         form1.CB_RPC_ON.Checked:=false;
         G_Launching := false;
         end;
      END; {TRY}
   end
else AddLineToDebugLog('console','RPC server already ENABLED');
End;

// Turns off RPC server
Procedure SetRPCOff();
Begin
if Form1.RPCServer.Active then
   begin
   Form1.RPCServer.Active:=false;
   AddLineToDebugLog('console','RPC server DISABLED');
   G_Launching := true;
   form1.CB_RPC_ON.Checked:=false;
   G_Launching := false;
   end
else AddLineToDebugLog('console','RPC server already DISABLED');
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
   Mydata.free;
   except on E:ejsonparser do
      result := false;
   end;
end;

// Returns the string of each error code
Function GetJSONErrorString(ErrorCode:integer):string;
Begin
if ErrorCode = 400 then result := 'Bad Request'
else if ErrorCode = 401 then result := 'Invalid JSON request'
else if ErrorCode = 402 then result := 'Invalid method'
else if ErrorCode = 407 then result := 'Send funds failed'
else if ErrorCode = 498 then result := 'Not authorized'
else if ErrorCode = 499 then result := 'Unexpected error'

{...}
else result := 'Unknown error code';
End;

// Returns a valid error JSON String
function GetJSONErrorCode(ErrorCode, JSONIdNumber:integer):string;
var
  JSONResultado,JSONErrorObj: TJSONObject;
Begin
  result := '';
JSONResultado := TJSONObject.Create;
JSONErrorObj  := TJSONObject.Create;
   TRY
   JSONResultado.Add('jsonrpc', TJSONString.Create('2.0'));
   JSONErrorObj.Add('code', TJSONIntegerNumber.Create(ErrorCode));
   JSONErrorObj.Add('message', TJSONString.Create(GetJSONErrorString(ErrorCode)));
   JSONResultado.Add('error',JSONErrorObj);
   JSONResultado.Add('id', TJSONIntegerNumber.Create(JSONIdNumber));
   EXCEPT ON E:Exception do
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on GetJSONErrorCode: '+E.Message)
   END; {TRY}
result := JSONResultado.AsJSON;
JSONResultado.Free;
End;

// Returns a valid response JSON string
function GetJSONResponse(ResultToSend:string;JSONIdNumber:integer):string;
var
  JSONResultado, Resultado: TJSONObject;
  paramsarray :  TJSONArray;
  myParams: TStringArray;
  counter : integer;
  Errored : boolean = false;
Begin
result := '';
paramsarray := TJSONArray.Create;
if length(ResultToSend)>0 then myParams:= ResultToSend.Split(' ');
JSONResultado := TJSONObject.Create;
   TRY
   JSONResultado.Add('jsonrpc', TJSONString.Create('2.0'));
   if length(myparams) > 0 then
      for counter := low(myParams) to high(myParams) do
         if myParams[counter] <>'' then
            begin
            paramsarray.Add(GetJSON(ObjectFromString(myParams[counter])));
            end;
   SetLength(MyParams, 0);
   JSONResultado.Add('result', paramsarray);
   JSONResultado.Add('id', TJSONIntegerNumber.Create(JSONIdNumber));
   EXCEPT ON E:Exception do
      begin
      result := GetJSONErrorCode(499,JSONIdNumber);
      JSONResultado.Free;
      paramsarray.Free;
      Errored := true;
      AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'Error on GetJSONResponse: '+E.Message);
      end;
   END; {TRY}
if not errored then result := JSONResultado.AsJSON;
JSONResultado.Free;
End;

function ObjectFromString(MyString:string): string;
var
  resultado: TJSONObject;
  orderobject : TJSONObject;
  objecttype : string;
  blockorders, Newaddresses : integer;
  ordersarray : TJSONArray;
  counter : integer;
Begin
resultado := TJSONObject.Create;
MyString := StringReplace(MyString,#127,' ',[rfReplaceAll, rfIgnoreCase]);
objecttype := parameter(mystring,0);
if objecttype = 'test' then
   begin
   resultado.Add('result','testok');
   end
else if objecttype = 'balance' then
   begin
   resultado.Add('valid',StrToBool(parameter(mystring,1)));
   resultado.Add('address', TJSONString.Create(parameter(mystring,2)));
   if parameter(mystring,3)='null' then resultado.Add('alias',TJSONNull.Create)
   else resultado.Add('alias',parameter(mystring,3));
   resultado.Add('balance', TJSONInt64Number.Create(StrToInt64(parameter(mystring,4))));
   resultado.Add('incoming', TJSONInt64Number.Create(StrToInt64(parameter(mystring,5))));
   resultado.Add('outgoing', TJSONInt64Number.Create(StrToInt64(parameter(mystring,6))));
   end
else if objecttype = 'orderinfo' then
   begin
   resultado.Add('valid',StrToBool(parameter(mystring,1)));
   if StrToBool(parameter(mystring,1)) then
      begin
      orderobject := TJSONObject.Create;
         orderobject.Add('orderid',parameter(mystring,2));
         orderobject.Add('timestamp',StrToInt64(parameter(mystring,3)));
         orderobject.Add('block',StrToInt64(parameter(mystring,4)));
         orderobject.Add('type',parameter(mystring,5));
         orderobject.Add('trfrs',StrToInt(parameter(mystring,6)));
         orderobject.Add('receiver',parameter(mystring,7));
         orderobject.Add('amount',StrToInt64(parameter(mystring,8)));
         orderobject.Add('fee',StrToInt64(parameter(mystring,9)));
         if parameter(mystring,10)='null' then orderobject.Add('reference',TJSONNull.Create)
         else orderobject.Add('reference',parameter(mystring,10));
         orderobject.Add('sender',parameter(mystring,11));
      resultado.Add('order',orderobject)
      end
   else resultado.Add('order',TJSONNull.Create)
   end
else if objecttype = 'blockinfo' then
   begin
   resultado.Add('valid',StrToBool(parameter(mystring,1)));
   resultado.Add('number',StrToIntDef(parameter(mystring,2),-1));
   resultado.Add('timestart',StrToInt64Def(parameter(mystring,3),-1));
   resultado.Add('timeend',StrToInt64Def(parameter(mystring,4),-1));
   resultado.Add('timetotal',StrToIntDef(parameter(mystring,5),-1));
   resultado.Add('last20',StrToIntDef(parameter(mystring,6),-1));
   resultado.Add('totaltransactions',StrToIntDef(parameter(mystring,7),-1));
   resultado.Add('difficulty',StrToIntDef(parameter(mystring,8),-1));
   resultado.Add('target',parameter(mystring,9));
   resultado.Add('solution',parameter(mystring,10));
   resultado.Add('lastblockhash',parameter(mystring,11));
   resultado.Add('nextdifficult',StrToIntDef(parameter(mystring,12),-1));
   resultado.Add('miner',parameter(mystring,13));
   resultado.Add('feespaid',StrToInt64Def(parameter(mystring,14),-1));
   resultado.Add('reward',StrToInt64Def(parameter(mystring,15),-1));
   resultado.Add('hash',parameter(mystring,16));
   end
else if objecttype = 'mininginfo' then
   begin
   resultado.Add('block',StrToInt(parameter(mystring,1)));
   resultado.Add('target',parameter(mystring,2));
   resultado.Add('miner',parameter(mystring,3));
   resultado.Add('diff',parameter(mystring,4));
   resultado.Add('hash',parameter(mystring,5));
   end
else if objecttype = 'pendingorders' then
   begin
   counter := 1;
   ordersarray := TJSONArray.Create;
   while parameter(mystring,counter) <> '' do
      begin
      ordersarray.Add(parameter(mystring,counter));
      Inc(Counter);
      end;
   resultado.Add('pendings',ordersarray);
   end
else if objecttype = 'peers' then
   begin
   counter := 1;
   ordersarray := TJSONArray.Create;
   while parameter(mystring,counter) <> '' do
      begin
      ordersarray.Add(parameter(mystring,counter));
      Inc(Counter);
      end;
   resultado.Add('peers',ordersarray);
   end

else if objecttype = 'mainnetinfo' then
   begin
   resultado.Add('lastblock',StrToIntDef(parameter(mystring,1),0));
   resultado.Add('lastblockhash',parameter(mystring,2));
   resultado.Add('headershash',parameter(mystring,3));
   resultado.Add('sumaryhash',parameter(mystring,4));
   resultado.Add('pending',StrToInt(parameter(mystring,5)));
   resultado.Add('supply',StrToInt64Def(parameter(mystring,6),0));
   end
else if objecttype = 'blockorder' then
   begin
   resultado.Add('valid',StrToBool(parameter(mystring,1)));
   resultado.Add('block',StrToIntDef(parameter(mystring,2),-1));
   blockorders := StrToIntDef(parameter(mystring,3),0);
   ordersarray := TJSONArray.Create;
   if blockorders>0 then
      begin
      for counter := 0 to blockorders-1 do
         begin
         orderobject:=TJSONObject.Create;
         orderobject.Add('orderid',parameter(mystring,4+(counter*10)));
         orderobject.Add('timestamp',StrToIntDef(parameter(mystring,5+(counter*10)),0));
         orderobject.Add('block',StrToIntDef(parameter(mystring,6+(counter*10)),0));
         orderobject.Add('type',parameter(mystring,7+(counter*10)));
         orderobject.Add('trfrs',StrToIntDef(parameter(mystring,8+(counter*10)),0));
         orderobject.Add('receiver',parameter(mystring,9+(counter*10)));
         orderobject.Add('amount',StrToInt64Def(parameter(mystring,10+(counter*10)),0));
         orderobject.Add('fee',StrToIntDef(parameter(mystring,11+(counter*10)),0));
         orderobject.Add('reference',parameter(mystring,12+(counter*10)));
         orderobject.Add('sender',parameter(mystring,13+(counter*10)));
         ordersarray.Add(orderobject);
         end;
      end;
   resultado.Add('orders',ordersarray);
   end
else if objecttype = 'blockmns' then
   begin
   resultado.Add('valid',StrToBool(parameter(mystring,1)));
   resultado.Add('block',StrToIntDef(parameter(mystring,2),-1));
   resultado.Add('count',StrToIntDef(parameter(mystring,3),-1));
   resultado.Add('reward',StrToInt64Def(parameter(mystring,4),-1));
   resultado.Add('total',StrToInt64Def(parameter(mystring,5),-1));
   resultado.Add('addresses',parameter(mystring,6));
   end

else if objecttype = 'newaddress' then
   begin
   //resultado.Add('valid',StrToBool(parameter(mystring,1)));
   Newaddresses := StrToIntDef(parameter(mystring,2),1);
   //resultado.Add('number',Newaddresses);
   ordersarray := TJSONArray.Create;
   for counter := 1 to Newaddresses do
      begin
      ordersarray.Add(parameter(mystring,2+counter));
      end;
   resultado.Add('addresses',ordersarray);
   end
else if objecttype = 'sendfunds' then
   begin
   if parameter(mystring,1) = 'ERROR' then
      resultado.Add('result','Failed')
   else
      resultado.Add('result',parameter(mystring,1));
   end;
result := resultado.AsJSON;
resultado.free;
End;

// Parses a incoming JSON string
function ParseRPCJSON(jsonreceived:string):string;
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
      try
      jObject := TJSONObject(jData);
      method := jObject.Strings['method'];
      params := jObject.Arrays['params'];
      jsonid := jObject.Integers['id'];
      for counter := 0 to params.Count-1 do
         NosoPParams:= NosoPParams+' '+params[counter].AsString;
      NosoPParams:= Trim(NosoPParams);
      //AddLineToDebugLog('console',jsonreceived);
      //AddLineToDebugLog('console','NosoPParams: '+NosoPParams);
      if method = 'test' then result := GetJSONResponse('test',jsonid)
      else if method = 'getaddressbalance' then result := GetJSONResponse(RPC_AddressBalance(NosoPParams),jsonid)
      else if method = 'getorderinfo' then result := GetJSONResponse(RPC_OrderInfo(NosoPParams),jsonid)
      else if method = 'getblocksinfo' then result := GetJSONResponse(RPC_Blockinfo(NosoPParams),jsonid)
      else if method = 'getmininginfo' then result := GetJSONResponse(RPC_Mininginfo(NosoPParams),jsonid)
      else if method = 'getmainnetinfo' then result := GetJSONResponse(RPC_Mainnetinfo(NosoPParams),jsonid)
      else if method = 'getpendingorders' then result := GetJSONResponse(RPC_PendingOrders(NosoPParams),jsonid)
      else if method = 'getpeers' then result := GetJSONResponse(RPC_GetPeers(NosoPParams),jsonid)
      else if method = 'getblockorders' then result := GetJSONResponse(RPC_BlockOrders(NosoPParams),jsonid)
      else if method = 'getblockmns' then result := GetJSONResponse(RPC_BlockMNs(NosoPParams),jsonid)
      else if method = 'getnewaddress' then result := GetJSONResponse(RPC_NewAddress(NosoPParams),jsonid)
      else if method = 'sendfunds' then result := GetJSONResponse(RPC_SendFunds(NosoPParams),jsonid)
      else result := GetJSONErrorCode(402,-1);
      Except on E:Exception do
         AddLineToDebugLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'JSON RPC error: '+E.Message);
      end;
   jData.Free;
   end;
End;

// GET DATA FUNCTIONS

function RPC_AddressBalance(NosoPParams:string):string;
var
  ThisAddress: string;
  counter : integer = 0;
  Balance, incoming, outgoing : int64;
  addalias : string = '';
  sumposition : integer;
  valid : string;
  LRecord : TSummaryData;
Begin
result := '';
if NosoPParams <> '' then
   begin
   Repeat
   ThisAddress := parameter(NosoPParams,counter);
   if IsValidHashAddress(ThisAddress) then sumposition := GetIndexPosition(ThisAddress,LRecord)
   else sumposition := GetIndexPosition(ThisAddress,LRecord,true);
   ThisAddress := LRecord.Hash;
   if ThisAddress <>'' then
      begin
      if sumposition<0 then
         begin
         balance :=-1;incoming := -1;outgoing := -1;
         addalias := 'null'; valid := 'false';
         end
      else
         begin
         Balance := GetAddressBalanceIndexed(ThisAddress);
         incoming := GetAddressIncomingpays(ThisAddress);
         outgoing := GetAddressPendingPays(ThisAddress);
         addalias := LRecord.Custom;
         if addalias = '' then addalias := 'null';
         valid := 'true';
         end;
      result := result+format('balance'#127'%s'#127'%s'#127'%s'#127'%d'#127'%d'#127'%d ',[valid,ThisAddress,addalias,balance,incoming,outgoing]);
      end;
   counter+=1;
   until ThisAddress = '';
   trim(result);
   end;
End;

function RPC_OrderInfo(NosoPParams:string):string;
var
  thisOr : TOrderGroup;
  validID : string = 'true';
Begin
AddLineToDebugLog('events',TimeToStr(now)+'GetOrderDetails requested: '+NosoPParams);
NosoPParams := Trim(NosoPParams);
ThisOr := Default(TOrderGroup);
if NosoPParams='' then
   begin
   validID := 'false';
   result := format('orderinfo'#127'%s'#127'%s'#127+
                 '%d'#127'%d'#127'%s'#127+
                 '%d'#127'%s'#127'%d'#127+
                 '%d'#127'%s'#127'%s'#127,
                [validid,NosoPParams,
                thisor.timestamp,thisor.block,thisor.OrderType,
                thisor.OrderLines,thisor.Receiver,thisor.AmmountTrf,
                thisor.AmmountFee,thisor.reference,thisor.sender]);
   exit;
   end;
thisor := GetOrderDetails(NosoPParams);
if thisor.OrderID = '' then validID := 'false';
result := format('orderinfo'#127'%s'#127'%s'#127+
                 '%d'#127'%d'#127'%s'#127+
                 '%d'#127'%s'#127'%d'#127+
                 '%d'#127'%s'#127'%s'#127,
                [validid,NosoPParams,
                thisor.timestamp,thisor.block,thisor.OrderType,
                thisor.OrderLines,thisor.Receiver,thisor.AmmountTrf,
                thisor.AmmountFee,thisor.reference,thisor.sender]);
End;

function RPC_Blockinfo(NosoPParams:string):string;
var
  thisblock : string;
  counter : integer = 0;
Begin
result := '';
if NosoPParams <> '' then
   begin
   Repeat
   thisblock := parameter(NosoPParams,counter);
   if thisblock <>''  then
      begin
      if ((StrToIntDef(thisblock,-1)>=0) and (StrToIntDef(thisblock,-1)<=MyLastblock)) then
         begin
         result := result+'blockinfo'#127'true'#127+GetBlockHeaders(StrToIntDef(thisblock,-1))+' ';
         end
      else result := result+'blockinfo'#127'false'#127+thisblock+#127'-1'#127'-1'#127'-1'#127'-1'#127'-1'#127'-1'#127'-1'#127'null'#127'null'#127'null'#127'-1'#127'null'#127'-1'#127'-1'#127'null ';
      end;
   counter+=1;
   until thisblock = '';
   trim(result);
   end;
End;

function RPC_Mininginfo(NosoPParams:string):string;
Begin
result := format('mininginfo'#127'%d'#127'%s'#127'%s'#127'%s'#127'%s'#127,[mylastblock+1,MyLastBlockHash,GetNMSData.miner,GetNMSData.Diff, GetNMSData.Hash]);
//AddLineToDebugLog('console','Resultado:'+result);
End;

function RPC_Mainnetinfo(NosoPParams:string):string;
Begin
result := format('mainnetinfo'#127'%s'#127'%s'#127'%s'#127'%s'#127'%s'#127'%d',
       [NetLastBlock.Value,NetLastBlockHash.Value,NetResumenHash.Value,NetSumarioHash.Value,NetPendingTrxs.Value,GetSupply(StrToIntDef(NetLastBlock.Value,0))]);
End;

function RPC_PendingOrders(NosoPParams:string):string;
var
  LData : String;
Begin
LData :=PendingRawInfo;
LData := StringReplace(LData,' ',#127,[rfReplaceAll, rfIgnoreCase]);
result := format('pendingorders'#127'%s',[LData]);
End;

function RPC_GetPeers(NosoPParams:string):string;
var
  LData : String;
Begin
LData := GetConnectedPeers;
LData := StringReplace(LData,' ',#127,[rfReplaceAll, rfIgnoreCase]);
result := format('peers'#127'%s',[LData]);
End;

function RPC_BlockOrders(NosoPParams:string):string;
var
  blocknumber : integer;
  ArraTrxs : TBlockOrdersArray;
  counter : integer;
  Thisorderinfo : string;
  arrayOrds : array of TOrderGroup;

  Procedure AddOrder(order:TOrderData);
  var
    cont : integer;
    existed : boolean = false;
  begin
  if length(arrayOrds)>0 then
     begin
     for cont := 0 to length(arrayOrds)-1 do
        begin
        if arrayords[cont].OrderID = order.OrderID then
           begin
           arrayords[cont].AmmountTrf:=arrayords[cont].AmmountTrf+order.AmmountTrf;
           arrayords[cont].AmmountFee:=arrayords[cont].AmmountFee+order.AmmountFee;
           arrayords[cont].sender    :=arrayords[cont].sender+
              format('[%s,%d,%d]',[order.Address,order.AmmountTrf,order.AmmountFee]);
           arrayords[cont].OrderLines+=1;
           existed := true;
           break;
           end;
        end;
     end;
  if not Existed then
     begin
     setlength(arrayords,length(arrayords)+1);
     arrayords[length(arrayords)-1].OrderID:=order.OrderID;
     arrayords[length(arrayords)-1].TimeStamp:=order.TimeStamp;
     arrayords[length(arrayords)-1].Block:=order.Block;
     arrayords[length(arrayords)-1].OrderType:=order.OrderType;
     arrayords[length(arrayords)-1].OrderLines:=1;
     arrayords[length(arrayords)-1].Receiver:=order.Receiver;
     arrayords[length(arrayords)-1].AmmountTrf:=order.AmmountTrf;
     arrayords[length(arrayords)-1].AmmountFee:=order.AmmountFee;
     arrayords[length(arrayords)-1].Reference:=order.Reference;
     if order.OrderLines=1 then
        arrayords[length(arrayords)-1].sender:=order.sender
     else arrayords[length(arrayords)-1].sender:=arrayords[length(arrayords)-1].sender+
          format('[%s,%d,%d]',[order.Address,order.AmmountTrf,order.AmmountFee]);
     end;
  end;

Begin
result := '';
setlength(arrayOrds,0);
blocknumber := StrToIntDef(NosoPParams,-1);
if ((blocknumber<0) or (blocknumber>MyLastblock)) then
   result := 'blockorder'#127'false'#127+NosoPParams+#127'0'
else
   begin
   ArraTrxs := GetBlockTrxs(BlockNumber);
   result := 'blockorder'#127'true'#127+NosoPParams+#127;
   if length(ArraTrxs) > 0 then
      begin
      for counter := 0 to length(ArraTrxs)-1 do
         AddOrder(ArraTrxs[counter]);
      result := result+IntToStr(length(arrayOrds))+#127;
      for counter := 0 to length(arrayOrds)-1 do
         begin
         thisorderinfo := format('%s'#127'%d'#127'%d'#127'%s'#127'%d'#127'%s'#127'%d'#127'%d'#127'%s'#127'%s'#127,
            [ arrayOrds[counter].OrderID,arrayOrds[counter].TimeStamp,arrayOrds[counter].Block,
            arrayOrds[counter].OrderType,arrayOrds[counter].OrderLines,arrayOrds[counter].Receiver,
            arrayOrds[counter].AmmountTrf,arrayOrds[counter].AmmountFee,arrayOrds[counter].Reference,
            arrayOrds[counter].sender]);
         result := result+thisorderinfo;
         end;
      end
   else result := result+'0'#127;
   trim(result);
   end;
End;

function RPC_Blockmns(NosoPParams:string):string;
var
  blocknumber : integer;
  ArrayMNs : BlockArraysPos;
  MNsReward : int64;
  MNsCount, Totalpaid : int64;
  counter : integer;
  AddressesString : string = '';
Begin
result := '';
blocknumber := StrToIntDef(NosoPParams,-1);
if ((blocknumber<48010) or (blocknumber>MyLastblock)) then
   result := 'blockmns'#127'false'#127+NosoPParams+#127'0'#127'0'#127'0'
else
   begin
   ArrayMNs := GetBlockMNs(blocknumber);
   MNsReward := StrToInt64Def(ArrayMNs[length(ArrayMNs)-1].address,0);
   SetLength(ArrayMNs,length(ArrayMNs)-1);
   MNSCount := length(ArrayMNs);
   TotalPAid := MNSCount * MNsReward;
   for counter := 0 to MNsCount-1 do
      AddressesString := AddressesString+ArrayMNs[counter].address+' ';
   AddressesString := Trim(AddressesString);
   AddressesString := StringReplace(AddressesString,' ',',',[rfReplaceAll, rfIgnoreCase]);
   result := 'blockmns'#127'true'#127+blocknumber.ToString+#127+MNSCount.ToString+#127+
              MNsReward.ToString+#127+TotalPAid.ToString+#127+AddressesString;
   end;

End;

function RPC_NewAddress(NosoPParams:string):string;
var
  TotalNumber : integer;
  counter : integer;
  NewAddress : WalletData;
  PubKey,PriKey : string;
Begin
TotalNumber := StrToIntDef(NosoPParams,1);
if TotalNumber > 100 then TotalNumber := 100;
//AddLineToDebugLog('console','TotalNewAddresses: '+IntToStr(TotalNumber));
result := 'newaddress'#127'true'#127+IntToStr(TotalNumber)+#127;
for counter := 1 to totalnumber do
   begin
   SetLength(ListaDirecciones,Length(ListaDirecciones)+1);
   NewAddress := Default(WalletData);
   NewAddress.Hash:=GenerateNewAddress(PubKey,PriKey);
   NewAddress.PublicKey:=pubkey;
   NewAddress.PrivateKey:=PriKey;
   ListaDirecciones[Length(ListaDirecciones)-1] := NewAddress;
   Result := result+NewAddress.Hash+#127;
   end;
trim(result);
S_Wallet := true;
U_DirPanel := true;
//AddLineToDebugLog('console',result);
End;

function RPC_SendFunds(NosoPParams:string):string;
var
  destination,  reference : string;
  amount : int64;
  resultado : string;
Begin
destination := Parameter(NosoPParams,0);
amount := StrToInt64Def(Parameter(NosoPParams,1),0);
reference := Parameter(NosoPParams,2); if reference = '' then reference := 'null';
//AddLineToDebugLog('console','Send to '+destination+' '+int2curr(amount)+' with reference: '+reference);
Resultado := SendFunds('sendto '+destination+' '+IntToStr(amount)+' '+Reference);
if resultado = '' then
   begin
   result := 'sendfunds'#127'ERROR';
   end
else
   begin
   result := 'sendfunds'#127+resultado;
   end;
End;


END.  // END UNIT

