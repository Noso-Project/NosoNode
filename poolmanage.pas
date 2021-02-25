unit PoolManage;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdContext, IdGlobal;

procedure StartPoolServer(port:integer);
Procedure StopPoolServer();
function ConnectPoolClient(Ip:String;Port:Integer;password:string):boolean;
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

implementation

uses
  MasterPaskalForm, mpparser, mpminer, mpdisk;

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
   except
   on E : Exception do
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
   Except
   on E:Exception do
     begin
     result := false;
     consolelines.Add('Unable to connect to pool server');
     Tolog('Unable to connect to pool server');
     end;
   end;
End;

Procedure SendPoolMessage(mensaje:string);
Begin
try
if canalpool.Connected then canalpool.IOHandler.WriteLn(mensaje);
Except On E:Exception do
   ToLog('Error sending message to pool: '+E.Message);
end;
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
   S_PoolMembers := true;
   result := ArrayPoolMembers[length(ArrayPoolMembers)-1].Prefijo;
   end
End;

Procedure ReadPoolClientLines();
var
  linea : string;
Begin
if not canalpool.Connected then exit;
try
if canalpool.IOHandler.InputBufferIsEmpty then
   begin
   canalpool.IOHandler.CheckForDataOnSource(10);
   if canalpool.IOHandler.InputBufferIsEmpty then Exit;
   end;
While not canalpool.IOHandler.InputBufferIsEmpty do
   begin
   Linea := canalpool.IOHandler.ReadLn(IndyTextEncoding_UTF8);
   if parameter(linea,0) = 'JOINOK' then
      begin
      useroptions.PoolInfo:=parameter(linea,1)+' '+parameter(linea,2)+' '+
      parameter(linea,3)+' '+parameter(linea,4)+' '+parameter(linea,5)+' '+
      parameter(linea,6)+' '+parameter(linea,7);
      LoadMyPoolData;
      S_Options := true;
      ConnectPoolClient(MyPoolData.Ip,MyPoolData.port,MyPoolData.Password);
      ConsoleLines.Add('Joined the pool!');
      end;
   if parameter(linea,0) = 'STATUSOK' then
      begin
      if Parameter(Linea,1) = MyPoolData.MyAddress then
         begin
         MyPoolData.balance := StrToInt64(parameter(linea,2));
         MyPoolData.LastPago:= StrToInt64(parameter(linea,3));
         end;
      end;
   if parameter(linea,0) = 'PAYMENTOK' then
      begin
      ProcessLines.Add('RequestPoolStatus');
      end;
   if parameter(linea,0) = 'PASSFAILED' then
      begin
      Consolelines.Add('Wrong pool password');
      end;
   end;
Except On E:Exception do
   ToLog('Error reading pool client:'+E.Message);
end;
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
Miner_UsingPool := true;
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
   ToLog('Error pool status request:'+E.Message);
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
   ToLog('Error pool payment request:'+E.Message);
end;
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

Procedure SendPoolSolution(bloque:integer;seed:string;numero:int64);
Begin
try
if CanalPool.Connected then
   SendPoolMessage(MyPoolData.Password+' '+MyPoolData.MyAddress+' STEP '+IntToStr(bloque)+' '+seed+' '+IntToStr(numero))
else consolelines.Add('Can not send solution to pool');
Except On E:Exception do
   ToLog('Error sending solution:'+E.Message);
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
      if arraypoolmembers[contador].Direccion = direccion then arraypoolmembers[contador].Soluciones+=1;
      end;
   end;
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

END.

