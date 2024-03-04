UNIT nosogeneral;

{
nosogeneral 1.2
December 27th, 2022
Noso Unit for general functions
Requires: Not dependencyes
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, Process, StrUtils, IdTCPClient, IdGlobal, fphttpclient,
  opensslsockets, fileutil, nosodebug, Zipper;

type
  TStreamHelper = class helper for TStream
    procedure SetString(const S: string);
    function  GetString: String;
  end;

  TStringArray = Array of String;

{Generic}
Function Parameter(LineText:String;ParamNumber:int64;de_limit:string=' '):String;
Function IsValidIP(IpString:String):boolean;
Function GetSupply(block:integer):int64;
Function Restar(number:int64):int64;
Function HashrateToShow(speed:int64):String;
Function Int2Curr(LValue: int64): string;
Procedure RunExternalProgram(ProgramToRun:String);
Function GetStackRequired(block:integer):int64;
Function GetMNsPercentage(block:integer;MainnetMode:String='NORMAL'):integer;
Function GetPoSPercentage(block:integer):integer;
Function GetDevPercentage(block:integer):integer;
Function GetMinimumFee(amount:int64):Int64;
Function GetMaximunToSend(amount:int64):int64;

{Network}
Function RequestLineToPeer(host:String;port:integer;command:string):string;
Function RequestToPeer(hostandPort,command:string):string;
Function SendApiRequest(urltocheck:string):String;

{File handling}
function SaveTextToDisk(const aFileName: TFileName; const aText: String): Boolean;
Function LoadTextFromDisk(const aFileName: TFileName): string;
function TryCopyFile(Source, destination:string):boolean;
function TryDeleteFile(filename:string):boolean;
Function MixTxtFiles(ListFiles : array of string;Destination:String;DeleteSources:boolean=true):boolean ;
Function SendFileViaTCP(filename,message,host:String;Port:integer):Boolean;
Function UnzipFile(filename:String;delFile:boolean):boolean;


IMPLEMENTATION

{$REGION Stream helper}

procedure TStreamHelper.SetString(const S: String);
var
  LSize: Word;
begin
  LSize := Length(S);
  WriteBuffer(LSize, SizeOf(LSize));
  WriteBuffer(Pointer(S)^, LSize);
end;

function TStreamHelper.GetString: String;
var
  LSize: Word = 0;
  P: PByte;
begin
  ReadBuffer(LSize, SizeOf(LSize));
  SetLength(Result, LSize);
  if LSize > 0 then
  begin
    ReadBuffer(Pointer(Result)^, LSize);
    P := Pointer(Result) + LSize;
    P^ := 0;
  end;
end;

{$ENDREGION}

{$REGION Generic}

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
    result := (block*5000000000)+1030390730000
  else if ((block >= 210000) and (block < 420000)) then
    begin
    Inc(result,(209999*5000000000)+1030390730000);
    Inc(result,(block-209999)*5000000000);
    end;
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
  if result > 1100000000000 then result := 1100000000000;
  if block > 110000 then result := 1050000000000;
End;

{Returns the MNs percentage for the specified block (0 to 10000)}
Function GetMNsPercentage(block:integer;MainnetMode:String='NORMAL'):integer;
Begin
  result := 0;
  if block >= 48010{MNBlockStart} then
    begin
    result := 2000{MNsPercentage} + (((block-48010{MNBlockStart}) div 4000) * 100);
    if block >= 88400{PoSBlockEnd} then Inc(Result,1000);
    if result > 6000 then result := 6000;
    if AnsiContainsStr(MainnetMode,'MNSONLY') then result := 9000;
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
  if result < 1000000{MinimunFee} then result := 1000000{MinimunFee};
End;

{Returns the maximum that can be sent from the specified amount}
Function GetMaximunToSend(amount:int64):int64;
var
  maximo     : int64;
  comision   : int64;
  Envio      : int64;
  Diferencia : int64;
Begin
  if amount < 1000000{MinimunFee} then
    exit(0);
  maximo     := (amount * 10000{Comisiontrfr}) div (10000{Comisiontrfr}+1);
  comision   := maximo div 10000{Comisiontrfr};
  if Comision < 1000000{MinimunFee} then Comision := 1000000{MinimunFee};
  Envio      := maximo + comision;
  Diferencia := amount-envio;
  result     := maximo+diferencia;
End;

{$ENDREGION}

{$REGION Network}

Function RequestLineToPeer(host:String;port:integer;command:string):string;
var
  Client   : TidTCPClient;
Begin
  Result := '';
  Client := TidTCPClient.Create(nil);
  Client.Host:=host;
  Client.Port:=Port;
  Client.ConnectTimeout:= 1000;
  Client.ReadTimeout:=1000;
  TRY
  Client.Connect;
  Client.IOHandler.WriteLn(Command);
  client.IOHandler.MaxLineLength:=Maxint;
  Result := Client.IOHandler.ReadLn();
  EXCEPT on E:Exception do

  END;{Try}
  if client.Connected then Client.Disconnect();
  client.Free;
End;

Function RequestToPeer(hostandPort,command:string):string;
var
  Client   : TidTCPClient;
Begin
  Result := '';
  Client := TidTCPClient.Create(nil);
  Client.Host:=Parameter(hostandPort,0);
  Client.Port:=StrToIntDef(Parameter(hostandPort,1),8080);
  Client.ConnectTimeout:= 1000;
  Client.ReadTimeout:=1000;
  TRY
  Client.Connect;
  Client.IOHandler.WriteLn(Command);
  client.IOHandler.MaxLineLength:=Maxint;
  Result := Client.IOHandler.ReadLn();
  EXCEPT on E:Exception do

  END;{Try}
  if client.Connected then Client.Disconnect();
  client.Free;
End;

Function SendApiRequest(urltocheck:string):String;
var
  Conector : TFPHttpClient;
Begin
  Result := '';
  Conector := TFPHttpClient.Create(nil);
  conector.ConnectTimeout:=3000;
  conector.IOTimeout:=3000;
    TRY
    result := Trim(Conector.SimpleGet(urltocheck));
    EXCEPT on E: Exception do

    END;//TRY
Conector.Free;
End;

{$ENDREGION}

{$REGION File handling}

Function SaveTextToDisk(const aFileName: TFileName; const aText: String): Boolean;
var
  LStream: TStringStream;
Begin
  Result := true;
  LStream := TStringStream.Create(aText);
    TRY
    LStream.SaveToFile(aFileName);
    EXCEPT On E:Exception do
      begin
      result := false;
      ToDeepDeb('NosoGeneral,SaveTextToDisk,'+E.Message);
      end;
    END;{Try}
  LStream.Free;
End;

Function LoadTextFromDisk(const aFileName: TFileName): string;
var
  LStream: TStringStream;
Begin
  Result := '';
  LStream := TStringStream.Create;
    TRY
    LStream.LoadFromFile(aFileName);
    Result := LStream.DataString;
    EXCEPT On E:Exception do
      begin
      result := '';
      ToDeepDeb('NosoGeneral,LoadTextFromDisk,'+E.Message);
      end;
    END;{Try}
  LStream.Free;
End;

function TryCopyFile(Source, destination:string):boolean;
Begin
  result := true;
    TRY
    copyfile (source,destination,[cffOverwriteFile],true);
    EXCEPT on E:Exception do
      begin
      result := false;
      ToDeepDeb('NosoGeneral,TryCopyFile,'+E.Message);
      end;
    END; {TRY}
End;

{Try to delete a file safely}
function TryDeleteFile(filename:string):boolean;
Begin
  result := deletefile(filename);
End;

Function MixTxtFiles(ListFiles : array of string;Destination:String;DeleteSources:boolean=true):boolean ;
var
  count      : integer = 0;
  FinalFile  : TStringList;
  ThisFile   : TStringList;
  Added      : integer = 0;
  Index      : integer;
Begin
  Result := true;
  FinalFile := TStringList.Create;
  ThisFile := TStringList.Create;
  while count < Length(Listfiles) do
    begin
    if FileExists(ListFiles[count]) then
      begin
      ThisFile.Clear;
      ThisFile.LoadFromFile(ListFiles[count]);
      FinalFile.Add('-----> '+ListFiles[count]);
      Index := 0;
      While Index < ThisFile.count do
        begin
        FinalFile.Add(ThisFile[index]);
        inc(index);
        end;
      Inc(added);
      end;
    if DeleteSources then TryDeletefile(ListFiles[count]);
    Inc(Count);
    end;
  if Added > 0 then
    FinalFile.SaveToFile(Destination);
  FinalFile.Free;
  ThisFile.Free;
  Result := true;
End;

Function SendFileViaTCP(filename,message,host:String;Port:integer):Boolean;
var
  Client   : TidTCPClient;
  MyStream : TMemoryStream;
Begin
  Result := true;
  if not fileExists(filename) then exit(false);
  MyStream := TMemoryStream.Create;
  MyStream.LoadFromFile(filename);
  Client := TidTCPClient.Create(nil);
  Client.Host:=host;
  Client.Port:=Port;
  Client.ConnectTimeout:= 1000;
  Client.ReadTimeout:=1000;
  TRY
    Client.Connect;
    Client.IOHandler.WriteLn(message);
    Client.IOHandler.Write(MyStream,0,true);
  EXCEPT on E:Exception do
    begin
    Result := false;
    ToDeepDeb('NosoGeneral,SendFile,'+E.Message);
    end;
  END;{Try}
  if client.Connected then Client.Disconnect();
  client.Free;
  MyStream.Free;
End;

// Unzip a zip file and (optional) delete it
Function UnzipFile(filename:String;delFile:boolean):boolean;
var
  UnZipper: TUnZipper;
Begin
  Result := true;
  UnZipper := TUnZipper.Create;
    TRY
    UnZipper.FileName := filename;
    UnZipper.OutputPath := '';
    UnZipper.Examine;
    UnZipper.UnZipAllFiles;
    EXCEPT on E:Exception do
      begin
      Result := false;
      ToDeepDeb('NosoGeneral,UnzipFile,'+E.Message);
      end;
    END; {TRY}
  if delfile then Trydeletefile(filename);
  UnZipper.Free;
End;

{$ENDREGION}


END.{UNIT}

