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
  mpGui, mpDisk;

// Inicializa el tiempo para verificar que esta correcto
procedure InitTime();
var
  local : int64 = 0;
  Global : int64 = 0;
Begin
OutText('? Initializing time',false,1);
G_TIMELocalTimeOffset := GetLocalTimeOffset*60;
global := strtoint64Def(getSNTPStringTime,-1);
local := strtoint64Def(GetLocalTimestamp,-1);
if global = -1 then
   begin
   consolelines.Add(LangLine(59)); //Unable to connect to NTP servers. Check your internet connection
   gridinicio.RowCount:=gridinicio.RowCount-1;
   OutText('✗ Failed initializing time',false,1);
   G_TimeOffSet := 0;
   ToLog('Unable to synchronize time'+ sLineBreak +
   'Please, make sure your local time is correct');
   Exit;
   end;
G_TimeOffSet:= global-Local;
gridinicio.RowCount:=gridinicio.RowCount-1;
OutText('✓ Time initialized',false,1);
if Abs(G_TimeOffSet) > 5 then
   begin
   ToLog('Your time is incorrect by '+IntToStr(G_TimeOffSet)+' seconds'+ sLineBreak +
   'You should fix it before trying a connection to mainnet');
   end;
End;

// Returns mainnet timestamp
function UTCTime():string;
Begin
result := IntToStr(StrToInt64Def(GetLocalTimestamp,0)+G_TIMELocalTimeOffset+G_TimeOffSet);
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
   if counter > 10 then result := 'ERROR';
   end;
End;

// Hace la conexion al servidor NTP del host especificado
function GetNetworkTimestamp(hostname:string):String;
var
  NTPClient: TIdSNTP;
begin
NTPClient := TIdSNTP.Create(nil);
   TRY
   NTPClient.Host := hostname;
   NTPClient.Active := True;
   NTPClient.ReceiveTimeout:=500;
   result := IntToStr(DateTimeToUnix(NTPClient.DateTime));
   if StrToInt64Def(result,-1) < 0 then result := '';
   EXCEPT on E:Exception do
      begin
      result := '';
      end;
   END; {TRY}
NTPClient.Free;
end;

// Returns local UNIX time
function GetLocalTimestamp():string;
var
  resultado : int64;
Begin
result := IntToStr(DateTimeToUnix(now));
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
else result := IntToStr(diferencia div 31536000)+' Y';
end;

END. // END UNIT

