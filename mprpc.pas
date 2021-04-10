unit mpRPC;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpgui;

Procedure SetRPCPort(LineText:string);
Procedure SetRPCOn();
Procedure SetRPCOff();


implementation

Uses
  MasterPaskalForm,mpparser;

// Sets RPC port
Procedure SetRPCPort(LineText:string);
var
  value : integer;
Begin
value := StrToIntDef(parameter(LineText,1),0);
if ((value <=0) or (value >65536)) then
   begin
   consolelines.Add('Invalid value');
   end
else
   begin
   RPCPort := value;
   consolelines.Add('RPC port set to: '+IntToStr(value));
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
   ConsoleLines.Add('RPC server ENABLED');
   end
else ConsoleLines.Add('RPC server already ENABLED');
End;

// Turns off RPC server
Procedure SetRPCOff();
Begin
if Form1.RPCServer.Active then
   begin
   Form1.RPCServer.Active:=false;
   ConsoleLines.Add('RPC server DISABLED');
   end
else ConsoleLines.Add('RPC server already DISABLED');
End;



END.

