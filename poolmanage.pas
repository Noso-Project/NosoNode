unit PoolManage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdContext, IdGlobal;

procedure StartPoolServer(port:integer);
Procedure StopPoolServer();
function ConnectPoolClient(Ip:String;Port:Integer;password:string):boolean;
Procedure DisconnectPoolClient();
Procedure SendPoolMessage(mensaje:string);
function PoolAddNewMember(direccion:string):string;
Procedure ReadPoolClientLines();
Procedure LoadMyPoolData();
Procedure PoolRequestMyStatus();
Procedure PoolRequestPayment();
function GetPoolMemberBalance(direccion:string):int64;
Procedure SendPoolSolution(bloque:integer;seed:string;numero:int64);
Procedure ResetPoolMiningInfo();
function GetPoolNumeroDePasos():integer;
Procedure DistribuirEnPool(cantidad:int64);
Procedure AcreditarPoolStep(direccion:string);
function GetLastPagoPoolMember(direccion:string):integer;
Procedure ClearPoolUserBalance(direccion:string);
Procedure PoolUndoneLastPayment();

implementation

uses
  MasterPaskalForm, mpparser, mpminer, mpdisk, mptime, mpGUI;

// Activa el servidor del pool
procedure StartPoolServer(port:integer);
Begin
if Form1.PoolServer.Active then
   begin
   ConsoleLines.Add('Pool server already active'); //'Server Already active'
   exit;
   end;
try
   Form1.PoolServer.Bindings.Clear;
   Form1.PoolServer.DefaultPort:=port;
   Form1.PoolServer.Active:=true;
   ConsoleLines.Add('Pool server enabled at port: '+IntToStr(port));   //Server ENABLED. Listening on port
except on E : Exception do
   ConsoleLines.Add('Unable to start pool server: '+E.Message);       //Unable to start Server
end;
end;

// Detiene el servidor del pool
Procedure StopPoolServer();
Begin
if Form1.PoolServer.Active then Form1.PoolServer.Active:=false;
End;

function ConnectPoolClient(Ip:String;Port:Integer;password:string):boolean;
Begin
result := true;
if canalpool.Connected then exit;
CanalPool.Host:=Ip;
CanalPool.Port:=Port;
canalpool.ConnectTimeout:=300;
try
   canalpool.Connect;
   canalpool.IOHandler.WriteLn(password);
Except on E:Exception do
   begin
   result := false;
   consolelines.Add('Unable to connect to pool server');
   Tolog('Unable to connect to pool server: '+E.Message);
   end;
end;
End;

Procedure DisconnectPoolClient();
Begin
TRY
   canalpool.IOHandler.InputBuffer.Clear;
   canalpool.Disconnect;
EXCEPT on E:Exception do
   begin
   tolog('Error disconnecting pool client: '+E.Message);
   end;
END;
End;

Procedure SendPoolMessage(mensaje:string);
Begin
try
   if canalpool.Connected then
      begin
      canalpool.IOHandler.WriteLn(mensaje);
      PoolClientLastPing := StrToInt64(UTCTime);
      end;
Except On E:Exception do
   ToLog('Error sending message to pool: '+E.Message);
end;
End;

Procedure PoolRequestMyStatus();
Begin
try
   if CanalPool.Connected then
      begin
      SendPoolMessage(MyPoolData.Password+' '+MyPoolData.MyAddress+' STATUS');
      consolelines.Add('Pool status request sent')
      end
   else consolelines.Add('Can not connect to pool server');
Except On E:Exception do
   ToLog('Error pool status request: '+E.Message);
end;
End;

Procedure PoolRequestPayment();
Begin
try
   if CanalPool.Connected then
      begin
      SendPoolMessage(MyPoolData.Password+' '+MyPoolData.MyAddress+' PAYMENT');
      consolelines.Add('Payment request sent')
      end
   else consolelines.Add('Pool channel is not connected');
Except On E:Exception do
   ToLog('Error pool payment request: '+E.Message);
end;
End;

Procedure SendPoolSolution(bloque:integer;seed:string;numero:int64);
Begin
try
   if CanalPool.Connected then
      SendPoolMessage(MyPoolData.Password+' '+MyPoolData.MyAddress+' STEP '+IntToStr(bloque)+' '+seed+' '+IntToStr(numero))
   else consolelines.Add('Can not send solution to pool');
Except On E:Exception do
   ToLog('Error sending solution: '+E.Message);
end;
End;

Procedure ReadPoolClientLines();
var
  linea : string;
Begin
if not canalpool.Connected then exit;
SetCurrentJob('ReadPoolClientLines',true);
try
   if canalpool.IOHandler.InputBufferIsEmpty then
      begin
      canalpool.IOHandler.CheckForDataOnSource(10);
      if canalpool.IOHandler.InputBufferIsEmpty then
         begin
         SetCurrentJob('ReadPoolClientLines',false);
         Exit;
         end;
      end;
   While not canalpool.IOHandler.InputBufferIsEmpty do
      begin
      TRY
         canalpool.ReadTimeout:=10;
         Linea := canalpool.IOHandler.ReadLn(IndyTextEncoding_UTF8);
      EXCEPT on E:Exception do
         begin
         tolog('Error reading pool client');
         SetCurrentJob('ReadPoolClientLines',false);
         exit;
         end;
      END;
      if parameter(linea,0) = 'JOINOK' then
         begin
         useroptions.PoolInfo:=parameter(linea,1)+' '+parameter(linea,2)+' '+
         parameter(linea,3)+' '+parameter(linea,4)+' '+parameter(linea,5)+' '+
         parameter(linea,6)+' '+parameter(linea,7);
         LoadMyPoolData;
         UserOptions.UsePool := true;
         S_Options := true;
         ConsoleLines.Add('Joined the pool!');
         DisconnectPoolClient();
         end
      else if parameter(linea,0) = 'STATUSOK' then
         begin
         if Parameter(Linea,1) = MyPoolData.MyAddress then
            begin
            MyPoolData.balance := StrToInt64(parameter(linea,2));
            MyPoolData.LastPago:= StrToInt64(parameter(linea,3));
            end;
         end
      else if parameter(linea,0) = 'PAYMENTOK' then
         begin
         PoolRequestMyStatus();
         end
      else if parameter(linea,0) = 'PASSFAILED' then
         begin
         Consolelines.Add('Wrong pool password');
         end
      else ConsoleLines.Add('Unknown messsage from pool server: '+Linea);
      end;
Except On E:Exception do
   begin
   ToLog('Error reading pool client: '+E.Message);
   Consolelines.Add('Pool channel disconnected');
   canalpool.IOHandler.InputBuffer.Clear;
   canalpool.Disconnect;
   end;
end;
SetCurrentJob('ReadPoolClientLines',false);
End;

function PoolAddNewMember(direccion:string):string;
var
  contador : integer;
Begin
result := '';
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion= direccion then
         begin
         result := ArrayPoolMembers[contador].Prefijo;
         exit;
         end;
      end;
   end;
if length(ArrayPoolMembers) < PoolInfo.MaxMembers then
   begin
   SetLength(ArrayPoolMembers,length(ArrayPoolMembers)+1);
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Direccion:=direccion;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Prefijo:=chr(32+length(ArrayPoolMembers))+'!!!!!!!!';
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Deuda:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].Soluciones:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].LastPago:=MyLastBlock;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].TotalGanado:=0;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].LastSolucion:=PoolMiner.Block;
   ArrayPoolMembers[length(ArrayPoolMembers)-1].LastEarned:=0;
   S_PoolMembers := true;
   result := ArrayPoolMembers[length(ArrayPoolMembers)-1].Prefijo;
   end
End;

Procedure LoadMyPoolData();
Begin
MyPoolData.Direccion:=Parameter(UserOptions.PoolInfo,0);
MyPoolData.Prefijo:=Parameter(UserOptions.PoolInfo,1);
MyPoolData.Ip:=Parameter(UserOptions.PoolInfo,2);
MyPoolData.port:=StrToInt(Parameter(UserOptions.PoolInfo,3));
MyPoolData.MyAddress:=Parameter(UserOptions.PoolInfo,4);
MyPoolData.Name:=Parameter(UserOptions.PoolInfo,5);
MyPoolData.Password:=Parameter(UserOptions.PoolInfo,6);
MyPoolData.balance:=0;
MyPoolData.LastPago:=0;
//Miner_UsingPool := true;
End;

function GetPoolMemberBalance(direccion:string):int64;
var
  contador : integer;
Begin
result :=-1;
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         result := arraypoolmembers[contador].Deuda;
         break;
         end;
      end;
   end;
End;

Procedure ResetPoolMiningInfo();
Begin
PoolMiner.Block:=LastBlockData.Number+1;
PoolMiner.Solucion:='';
PoolMiner.steps:=0;
PoolMiner.Dificult:=LastBlockData.NxtBlkDiff;
PoolMiner.DiffChars:=GetCharsFromDifficult(PoolMiner.Dificult, PoolMiner.steps);
PoolMiner.Target:=MyLastBlockHash;
end;

function GetPoolNumeroDePasos():integer;
var
  contador : integer;
Begin
result := 0;
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      result := result + arraypoolmembers[contador].Soluciones;
   end;
End;

Procedure DistribuirEnPool(cantidad:int64);
var
  numerodepasos: integer;
  PoolComision : int64;
  ARepartir, PagoPorStep: int64;
  contador : integer;
Begin
ARepartir := Cantidad;
NumeroDePasos := GetPoolNumeroDePasos();
PoolComision := (cantidad* PoolInfo.Porcentaje) div 10000;
PoolInfo.FeeEarned:=PoolInfo.FeeEarned+PoolComision;
ARepartir := ARepartir-PoolComision;
PagoPorStep := ARepartir div NumeroDePasos;
for contador := 0 to length(arraypoolmembers)-1 do
   begin
   if arraypoolmembers[contador].Soluciones > 0 then
      begin
      arraypoolmembers[contador].Deuda:=arraypoolmembers[contador].Deuda+
      (arraypoolmembers[contador].Soluciones*PagoPorStep);
      arraypoolmembers[contador].TotalGanado:=arraypoolmembers[contador].TotalGanado+
      (arraypoolmembers[contador].Soluciones*PagoPorStep);
      arraypoolmembers[contador].LastEarned:=(arraypoolmembers[contador].Soluciones*PagoPorStep);
      arraypoolmembers[contador].Soluciones := 0;
      end;
   end;
S_PoolMembers := true;
GuardarArchivoPoolInfo();
End;

Procedure AcreditarPoolStep(direccion:string);
var
  contador : integer;
Begin
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         arraypoolmembers[contador].Soluciones+=1;
         arraypoolmembers[contador].LastSolucion:=PoolMiner.Block;
         end;
      end;
   end;
S_PoolMembers := true;
End;

function GetLastPagoPoolMember(direccion:string):integer;
var
  contador : integer;
Begin
result :=-1;
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         result := arraypoolmembers[contador].LastPago;
         break;
         end;
      end;
   end;
End;

Procedure ClearPoolUserBalance(direccion:string);
var
  contador : integer;
Begin
if length(ArrayPoolMembers)>0 then
   begin
   for contador := 0 to length(ArrayPoolMembers)-1 do
      begin
      if arraypoolmembers[contador].Direccion = direccion then
         begin
         arraypoolmembers[contador].Deuda:=0;
         arraypoolmembers[contador].LastPago:=MyLastBlock;
         break;
         end;
      end;
   end;
S_PoolMembers := true;
GuardarArchivoPoolInfo;
End;

Procedure PoolUndoneLastPayment();
var
  contador : integer;
  totalmenos : int64 = 0;
Begin
if length(arraypoolmembers)>0 then
   begin
   for contador := 0 to length(arraypoolmembers)-1 do
      begin
      totalmenos := totalmenos+ arraypoolmembers[contador].LastEarned;
      arraypoolmembers[contador].Deuda :=arraypoolmembers[contador].Deuda-arraypoolmembers[contador].LastEarned;
      if arraypoolmembers[contador].deuda < 0 then arraypoolmembers[contador].deuda := 0;
      arraypoolmembers[contador].TotalGanado:=arraypoolmembers[contador].TotalGanado-arraypoolmembers[contador].LastEarned;
      end;
   end;
S_PoolMembers := true;
consolelines.Add('Discounted last payment to pool members : '+Int2curr(totalmenos));
End;

END.

