unit mpTime;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IdSNTP, DateUtils, MasterPaskalForm, Dialogs, Forms;

procedure InitTime();
function UTCTime():string;
function getSNTPStringTime(): String;
function GetNetworkTimestamp(hostname:string):String;
function GetLocalTimestamp():string;
function TimestampToDate(timestamp:string):String;
function TimeSinceStamp(value:int64):string;



implementation

uses
  mpGui;

// Inicializa el tiempo para verificar que esta correcto
procedure InitTime();
var
  local : int64 = 0;
  Global : int64 = 0;
Begin
OutText('? Initializing time',false,1);
global := strtoint64Def(getSNTPStringTime,-1);
local := strtoint64Def(GetLocalTimestamp,-1);
if global = -1 then
   begin
   consolelines.Add(LangLine(59)); //Unable to connect to NTP servers. Check your internet connection
   gridinicio.RowCount:=gridinicio.RowCount-1;
   OutText('✗ Failed initializing time',false,1);
   G_TimeOffSet := 0;
   Exit;
   end;
G_TimeOffSet:= global-Local;
gridinicio.RowCount:=gridinicio.RowCount-1;
OutText('✓ Time initialized',false,1);
if Abs(G_TimeOffSet) > 5 then
   begin
   ShowMessage('Your time is incorrect by '+IntToStr(G_TimeOffSet)+' seconds'+ sLineBreak +'Noso will close automatically'+ sLineBreak +'Fix it and try again');
   Application.Terminate;
   end;
End;

// Devuelve el tiempo de la red
function UTCTime():string;
Begin
result := IntToStr(StrToInt64Def(GetLocalTimestamp,0)+(GetLocalTimeOffset*60)+G_TimeOffSet);
End;

// Intenta en los servidores hasta obtener un valor valido
function getSNTPStringTime(): String;
var
  counter : integer = 0;
Begin
result := '';
while result = '' do
   begin
   G_NTPServer := ListaNTP[counter].Host;
   result := GetNetworkTimestamp(ListaNTP[counter].Host);
   Inc(counter);
   if counter > 9 then result := 'ERROR';
   end;
End;

// Hace la conexion al servidor NTP del host especificado
function GetNetworkTimestamp(hostname:string):String;
var
  NTPClient: TIdSNTP;
begin
NTPClient := TIdSNTP.Create(nil);
   try
   NTPClient.Host := hostname;
   NTPClient.Active := True;
   NTPClient.ReceiveTimeout:=500;
   result := IntToStr(DateTimeToUnix(NTPClient.DateTime));
   if StrToInt64Def(result,-1) < 0 then result := '';
   Except on E:Exception do
      begin
      result := '';
      end;
   end;
NTPClient.Free;
end;

// Regresa el timestamp del reloj de la computadora
function GetLocalTimestamp():string;
Begin
GetLocalTimestamp := inttostr(Trunc((Now - EncodeDate(1970, 1 ,1)) * 24 * 60 * 60));
end;

// Convierte un timestamp en una fecha legible
function TimestampToDate(timestamp:string):String;
var
  AsInteger: integer;
  Fecha : TDateTime;
begin
AsInteger := StrToInt64def(timestamp,-1);
fecha := UnixToDateTime(AsInteger);
result := DateTimeToStr(fecha);
end;

// Muestra el tiempo transcurrido desde el timestamp proporcionado
function TimeSinceStamp(value:int64):string;
var
CurrStamp : Int64 = 0;
Diferencia : Int64 = 0;
Begin
CurrStamp := StrToInt64Def(UTCTime,0);
Diferencia := CurrStamp - value;
if diferencia div 60 < 1 then result := '<1m'
else if diferencia div 3600 < 1 then result := IntToStr(diferencia div 60)+'m'
else if diferencia div 86400 < 1 then result := IntToStr(diferencia div 3600)+'h'
else if diferencia div 2592000 < 1 then result := IntToStr(diferencia div 86400)+'d'
else if diferencia div 31536000 < 1 then result := IntToStr(diferencia div 2592000)+'M'
else result := IntToStr(diferencia div 31536000)+' Y'
end;

END. // END UNIT

