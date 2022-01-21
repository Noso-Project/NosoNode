unit mpMN;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

function MyMNIsListed():boolean;
Procedure ReportMyMN();

implementation

uses
  MasterPaskalform;

function MyMNIsListed():boolean;
var
  counter : integer;
Begin
result := false;
if length(MNsList) > 0 then
   begin
   for counter := 0 to length(MNsList)-1 do
      begin
      if MNsList[counter].Ip = MN_IP then
         begin
         result := true;
         break;
         end;
      end;
   end;
End;

Procedure ReportMyMN();
Begin

End;

END. // End UNIT

