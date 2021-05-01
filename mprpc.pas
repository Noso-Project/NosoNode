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
   ConsoleLinesAdd('Invalid value');
   end
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



END.

