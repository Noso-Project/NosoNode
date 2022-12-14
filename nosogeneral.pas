UNIT nosogeneral;

{
nosogeneral 1.0
December 11th, 2022
Noso Unit for general functions
Requires: Not dependencyes
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, process;

Function Parameter(LineText:String;ParamNumber:int64;de_limit:string=' '):String;
Function IsValidIP(IpString:String):boolean;
Function GetSupply(block:integer):int64;
Function Restar(number:int64):int64;
Function HashrateToShow(speed:int64):String;
Procedure RunExternalProgram(ProgramToRun:String);

IMPLEMENTATION

{Returns a specific parameter number of text}
Function Parameter(LineText:String;ParamNumber:int64;de_limit:string=' '):String;
var
  Temp : String = '';
  ThisChar : Char;
  Contador : int64 = 1;
  WhiteSpaces : int64 = 0;
  parentesis : boolean = false;
Begin
  while contador <= Length(LineText) do
    begin
    ThisChar := Linetext[contador];
    if ((thischar = '(') and (not parentesis)) then parentesis := true
    else if ((thischar = '(') and (parentesis)) then
      begin
      result := '';
      exit;
      end
    else if ((ThisChar = ')') and (parentesis)) then
      begin
      if WhiteSpaces = ParamNumber then
        begin
        result := temp;
        exit;
        end
    else
      begin
      parentesis := false;
      temp := '';
      end;
    end
    else if ((ThisChar = de_limit) and (not parentesis)) then
      begin
      WhiteSpaces := WhiteSpaces +1;
      if WhiteSpaces > Paramnumber then
        begin
        result := temp;
        exit;
        end;
      end
    else if ((ThisChar = de_limit) and (parentesis) and (WhiteSpaces = ParamNumber)) then
      begin
      temp := temp+ ThisChar;
      end
    else if WhiteSpaces = ParamNumber then temp := temp+ ThisChar;
    contador := contador+1;
    end;
  if temp = de_limit then temp := '';
  Result := Temp;
End;

{Verify if a string is valid IPv4 address}
Function IsValidIP(IpString:String):boolean;
var
  valor1,valor2,valor3,valor4: integer;
Begin
  result := true;
  //IPString := StringReplace(IPString,'.',' ',[rfReplaceAll, rfIgnoreCase]);
  valor1 := StrToIntDef(Parameter(IPString,0,'.'),-1);
  valor2 := StrToIntDef(Parameter(IPString,1,'.'),-1);
  valor3 := StrToIntDef(Parameter(IPString,2,'.'),-1);
  valor4 := StrToIntDef(Parameter(IPString,3,'.'),-1);
  if ((valor1 <0) or (valor1>255)) then result := false;
  if ((valor2 <0) or (valor2>255)) then result := false;
  if ((valor3 <0) or (valor3>255)) then result := false;
  if ((valor4 <0) or (valor4>255)) then result := false;
  if ((valor1=192) and (valor2=168)) then result := false;
  if ((valor1=127) and (valor2=0)) then result := false;
End;

{Returns the circulating supply on the specified block}
Function GetSupply(block:integer):int64;
Begin
  if block < 210000 then
    result := (block*5000000000)+1030390730000;
End;

{Convert any positive integer in negative}
Function Restar(number:int64):int64;
Begin
  if number > 0 then Result := number-(Number*2)
  else Result := number;
End;

{Converts a integer in a human readeaeble format for hashrate}
Function HashrateToShow(speed:int64):String;
Begin
  if speed>1000000000 then result := FormatFloat('0.00',speed/1000000000)+' Gh/s'
  else if speed>1000000 then result := FormatFloat('0.00',speed/1000000)+' Mh/s'
  else if speed>1000 then result := FormatFloat('0.00',speed/1000)+' Kh/s'
  else result := speed.ToString+' h/s'
End;

{Runs an external program}
Procedure RunExternalProgram(ProgramToRun:String);
var
  Process: TProcess;
  I: Integer;
Begin
  Process := TProcess.Create(nil);
    TRY
    Process.InheritHandles := False;
    Process.Options := [];
    Process.ShowWindow := swoShow;
    for I := 1 to GetEnvironmentVariableCount do
      Process.Environment.Add(GetEnvironmentString(I));
    {$IFDEF UNIX}
    process.Executable := 'bash';
    process.Parameters.Add(ProgramToRun);
    {$ENDIF}
    {$IFDEF WINDOWS}
    Process.Executable := ProgramToRun;
    {$ENDIF}
    Process.Execute;
    EXCEPT ON E:Exception do

    END; {TRY}
  Process.Free;
End;

END.{UNIT}

