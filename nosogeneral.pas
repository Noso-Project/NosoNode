UNIT nosogeneral;

{
nosogeneral 1.1
December 15th, 2022
Noso Unit for general functions
Requires: Not dependencyes
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, Process, StrUtils;

Function Parameter(LineText:String;ParamNumber:int64;de_limit:string=' '):String;
Function IsValidIP(IpString:String):boolean;
Function GetSupply(block:integer):int64;
Function Restar(number:int64):int64;
Function HashrateToShow(speed:int64):String;
Function Int2Curr(LValue: int64): string;
Procedure RunExternalProgram(ProgramToRun:String);
Function GetStackRequired(block:integer):int64;
Function GetMNsPercentage(block:integer):integer;
Function GetPoSPercentage(block:integer):integer;
Function GetDevPercentage(block:integer):integer;
Function GetMinimumFee(amount:int64):Int64;
Function GetMaximunToSend(amount:int64):int64;

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
  Result := 0;
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

{Converts a integer in a human readeaeble format for currency}
Function Int2Curr(LValue: int64): string;
Begin
  Result := IntTostr(Abs(LValue));
  result :=  AddChar('0',Result, 9);
  Insert('.',Result, Length(Result)-7);
  If LValue <0 THen Result := '-'+Result;
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

{Returns the required noso stack size}
Function GetStackRequired(block:integer):int64;
Begin
  result := (GetSupply(block)*20) div 10000;
End;

{Returns the MNs percentage for the specified block (0 to 10000)}
Function GetMNsPercentage(block:integer):integer;
Begin
  result := 0;
  if block >= 48010{MNBlockStart} then
    begin
    result := 2000{MNsPercentage} + (((block-48010{MNBlockStart}) div 4000) * 100);
    if block >= 88400{PoSBlockEnd} then Inc(Result,1000);
    if result > 6000 then result := 6000;
    end;
End;

{Returns the PoS percentage for the specified block (0 to 10000)}
Function GetPoSPercentage(block:integer):integer;
Begin
  result := 0;
  if ((block > 8424) and (block < 40000)) then result := 1000{PoSPercentage};
  if block >= 40000 then
    begin
    result := 1000{PoSPercentage} + (((block-39000) div 1000) * 100);
    if result > 2000 then result := 2000;
    end;
  if block >= 88400{PoSBlockEnd} then result := 0;
End;

{Returns the Project percentage for the specified block}
Function GetDevPercentage(block:integer):integer;
Begin
  result := 0;
  if block >= 88400{PoSBlockEnd} then result := 1000;
End;

{Returns the minimum fee to be paid for the specified amount}
Function GetMinimumFee(amount:int64):Int64;
Begin
  Result := amount div 10000{Comisiontrfr};
  if result < 10{MinimunFee} then result := 10{MinimunFee};
End;

{Returns the maximum that can be sent from the specified amount}
Function GetMaximunToSend(amount:int64):int64;
var
  maximo     : int64;
  comision   : int64;
  Envio      : int64;
  Diferencia : int64;
Begin
  if amount < 10{MinimunFee} then
    exit(0);
  maximo     := (amount * 10000{Comisiontrfr}) div (10000{Comisiontrfr}+1);
  comision   := maximo div 10000{Comisiontrfr};
  if Comision < 10{MinimunFee} then Comision := 10{MinimunFee};
  Envio      := maximo + comision;
  Diferencia := amount-envio;
  result     := maximo+diferencia;
End;


END.{UNIT}

