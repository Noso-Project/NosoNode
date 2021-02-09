unit mpCripto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, process, strutils, MD5, DCPsha256, dcpRipemd160,
  mpsignerutils, base64;

function CreateNewAddress(): WalletData;
Procedure CreateKeysPair();
Function GetPublicKeyFromPem():String;
Function GetPrivateKeyFromPem():String;
function GetAddressFromPublicKey(PubKey:String):String;
function HashSha256String(StringToHash:string):string;
function HashMD160String(StringToHash:string):String;
Function HashMD5String(StringToHash:String):String;
procedure NuevaDireccion(linetext:string);
Function HashMD5File(FileToHash:String):String;
function IsValidAddress(Address:String):boolean;
function DireccionEsMia(direccion:string):integer;
Procedure RunExternalProgram(ProgramToRun:String);
function RunOpenSSLCommand(textline:String):boolean;
function GetStringSigned(StringtoSign, PrivateKey:String):String;
function GetBase64TextFromFile(fileb64:string):string;
function VerifySignedString(StringToVerify,B64String,PublicKey:String):boolean;
function GetTransferHash(TextLine:string):String;
function GetOrderHash(TextLine:string):String;
Procedure AddCriptoOp(tipo:integer;proceso, resultado:string);
Procedure StartCriptoThread();
Procedure DeleteCriptoOp();
Function ProcessCriptoOP(aParam:Pointer):PtrInt;
// Big Maths
function ClearLeadingCeros(numero:string):string;
function BMAdicion(numero1,numero2:string):string;
Function PonerCeros(numero:String;cuantos:integer):string;
Function BMMultiplicar(Numero1,Numero2:string):string;
Function BMDividir(Numero1,Numero2:string):DivResult;
Function BMExponente(Numero1,Numero2:string):string;
function BMHexToDec(numerohex:string):string;
function BMHexTo58(numerohex:string;alphabetnumber:integer):string;
function BMB58resumen(numero58:string):string;
function BMDecTo58(numero:string):string;



implementation

uses
  mpParser, mpGui, mpProtocol;

// Crea una nueva direecion
function CreateNewAddress():WalletData;
var
  //PublicKey, PrivateKey : String;
  MyData: WalletData;
  Address: String;
  KeysPair: TKeyPair;
Begin
setmilitime('CreateNewAddress',1);
{CreateKeysPair();
PublicKey := GetPublicKeyFromPem();
Privatekey := GetPrivateKeyFromPem();}
KeysPair := TSignerUtils.GenerateECKeyPair(TKeyType.SECP256K1);
Address := GetAddressFromPublicKey(KeysPair.PublicKey);
MyData.Hash:=Address;
Mydata.Custom:='';
Mydata.PublicKey:=KeysPair.PublicKey;
MyData.PrivateKey:=KeysPair.PrivateKey;
MyData.Balance:=0;
MyData.Pending:=0;
MyData.Score:=0;
MyData.LastOP:= 0;
{
Deletefile('private.pem');
Deletefile('public.pem');
}
Result := MyData;
setmilitime('CreateNewAddress',2);
End;

// Crea las claves publicas y privadas
Procedure CreateKeysPair();
var
  MyProcess, MyProcess2 : TProcess;
Begin
//Generates the private
MyProcess:= TProcess.Create(nil);
MyProcess.Executable := UserOptions.SSLPath;
MyProcess.Parameters.Add('ecparam');
MyProcess.Parameters.Add('-name');
MyProcess.Parameters.Add('secp256k1');
MyProcess.Parameters.Add('-genkey');
MyProcess.Parameters.Add('-noout');
MyProcess.Parameters.Add('-out');
MyProcess.Parameters.Add('private.pem');
MyProcess.Options := MyProcess.Options + [poWaitOnExit, poUsePipes, poNoConsole];
MyProcess.Execute;
// Extract public key
MyProcess2:= TProcess.Create(nil);
MyProcess2.Executable := UserOptions.SSLPath;
MyProcess2.Parameters.Add('ec');
MyProcess2.Parameters.Add('-in');
MyProcess2.Parameters.Add('private.pem');
MyProcess2.Parameters.Add('-pubout');
MyProcess2.Parameters.Add('-out');
MyProcess2.Parameters.Add('public.pem');
MyProcess2.Options := MyProcess2.Options + [poWaitOnExit, poUsePipes, poNoConsole];
MyProcess2.Execute;
MyProcess.Free;MyProcess2.Free;
End;

// RETURNS THE PUBLIC KEY WHEN CREATED
Function GetPublicKeyFromPem():String;
var
  KeyFile: TextFile;
  LineText, Resultado : String;
Begin
Resultado := '';
AssignFile(KeyFile,'public.pem');
   Try
   reset(Keyfile);
   while not eof(KeyFile) do
      begin
      readln(KeyFile, LineText);
      If AnsiContainsStr(LineText,'-----') = false then
         Resultado := Resultado + LineText;
      end;
   Closefile(Keyfile);
   except
   on E: EInOutError do
      Consolelines.add(LangLine(26));     //Public key file not found
   end;
if Resultado <>'' then Result := Resultado
else result := 'Err';
end;

// RETURNS THE PRIVATE KEY WHEN CREATED
Function GetPrivateKeyFromPem():String;
var
  KeyFile: TextFile;
  LineText, Resultado : String;
Begin
Resultado := '';
AssignFile(KeyFile,'private.pem');
   Try
   reset(Keyfile);
   while not eof(KeyFile) do
      begin
      readln(KeyFile, LineText);
      If AnsiContainsStr(LineText,'-----') = false then
         Resultado := Resultado + LineText;
      end;
   Closefile(Keyfile);
   except
   on E: EInOutError do
      Consolelines.add(LangLine(26));     //Public key file not found
   end;
if Resultado <>'' then Result := Resultado
else result := 'Err';
end;

// RETURNS AN ADDRESS FROM A PUBLIC LEY
function GetAddressFromPublicKey(PubKey:String):String;
var
  PubSHAHashed,Hash1,Hash2,clave:String;
  sumatoria : string;
Begin
setmilitime('GetAddressFromPublicKey',1);
PubSHAHashed := HashSha256String(PubKey);
Hash1 := HashMD160String(PubSHAHashed);
hash1 := BMHexTo58(Hash1,58);
sumatoria := BMB58resumen(Hash1);
clave := BMDecTo58(sumatoria);
hash2 := hash1+clave;
Result := CoinChar+hash2;
setmilitime('GetAddressFromPublicKey',2);
End;

// RETURNS THE SHA256 OF A STRING
function HashSha256String(StringToHash:string):string;
var
  Hash: TDCP_sha256;
  Digest: array[0..31] of byte;  // sha256 produces a 256bit digest (32bytes)
  Source: string;
  i: integer;
  str1: string;
begin
Source:= StringToHash;  // here your string for get sha256
if Source <> '' then
   begin
   Hash:= TDCP_sha256.Create(nil);  // create the hash
   Hash.Init;                        // initialize it
   Hash.UpdateStr(Source);
   Hash.Final(Digest);               // produce the digest
   str1:= '';
   for i:= 0 to 31 do
   str1:= str1 + IntToHex(Digest[i],2);
   Result:=UpperCase(str1);         // display the digest in capital letter
   Hash.Free;
   end;
end;

// RETURNS HASH MD160 OF A STRING
function HashMD160String(StringToHash:string):String;
var
  Hash: TDCP_ripemd160;
  Digest: array[0..19] of byte;
  Source: string;
  i: integer;
  str1: string;
Begin
Source:= StringToHash;
if Source <> '' then
   begin
   Hash:= TDCP_ripemd160.Create(nil);
   Hash.Init;
   Hash.UpdateStr(Source);
   Hash.Final(Digest);
   str1:= '';
   for i:= 0 to 19 do
   str1:= str1 + IntToHex(Digest[i],2);
   Result:=UpperCase(str1);
   Hash.Free;
   end;
End;

// RETURNS THE MD5 HASH OF A STRING
Function HashMD5String(StringToHash:String):String;
Begin
result := Uppercase(MD5Print(MD5String(StringToHash)));
end;

// Crea una nueva direccion y la añade a listadirecciones
procedure NuevaDireccion(linetext:string);
var
  cantidad : integer;
  cont : integer;
Begin
cantidad := StrToIntDef(parameter(linetext,1),1);
if cantidad > 100 then cantidad := 100;
for cont := 1 to cantidad do
   begin
   AddCRiptoOp(1,'','');
   end;
StartCriptoThread();
End;

// Devuelve el hash MD5 de un archivo
Function HashMD5File(FileToHash:String):String;
Begin
result := UpperCase(MD5Print(MD5File(FileToHash)));
End;

// Verifica si una direccion tiene un formato valido
function IsValidAddress(Address:String):boolean;
var
  OrigHash : String;
  Clave:String;
Begin
OrigHash := Copy(Address,2,length(address)-3);
Clave := BMDecTo58(BMB58resumen(OrigHash));
OrigHash := CoinChar+OrigHash+clave;
If OrigHash = Address then result := true else result := false;
End;

// Verifica si la direccion enviada esta en la cartera del usuario
function DireccionEsMia(direccion:string):integer;
var
  contador : integer = 0;
Begin
Result := -1;
for contador := 0 to length(Listadirecciones)-1 do
   begin
   if ((ListaDirecciones[contador].Hash = direccion) or (ListaDirecciones[contador].Custom = direccion )) then
      begin
      result := contador;
      break;
      end;
   end;
End;

// Ejecuta el autoupdater
Procedure RunExternalProgram(ProgramToRun:String);
var
  Process: TProcess;
  I: Integer;
begin
Process := TProcess.Create(nil);
   try
   Process.InheritHandles := False;
   Process.Options := [];
   Process.ShowWindow := swoShow;
   for I := 1 to GetEnvironmentVariableCount do
     Process.Environment.Add(GetEnvironmentString(I));
   Process.Executable := ProgramToRun;
   Process.Execute;
   finally
   Process.Free;
   end;
End;

function RunOpenSSLCommand(textline:String):boolean;
var
  ArrParameters : Array of string;
  contador : integer = 1;
  ThisParam : String = '';
  MoreParam: boolean = true;
  MyProcess : TProcess;
  Resultado, Errores : TStringList;
Begin
result := false;
Resultado := TStringList.Create;
Errores := TStringList.Create;
SetLength(ArrParameters,0);
while MoreParam do
   begin
   ThisParam := Parameter(textline,contador);
   if thisparam = '' then MoreParam := false
   else
     begin
     SetLength(ArrParameters,length(ArrParameters)+1);
     ArrParameters[length(ArrParameters)-1] := ThisParam;
     end;
   contador := contador+1;
   end;
MyProcess:= TProcess.Create(nil);
MyProcess.Executable := UserOptions.SSLPath;
For contador := 0 to length(ArrParameters)-1 do
  MyProcess.Parameters.Add(ArrParameters[contador]);
MyProcess.Options := MyProcess.Options + [poWaitOnExit, poUsePipes, poNoConsole];
MyProcess.Execute;
Resultado.LoadFromStream(MyProcess.Output);
Errores.LoadFromStream(MyProcess.stderr);
if ((Resultado.Count>0) and (Resultado[0] = 'Verified OK')) then result := true;
while Resultado.Count > 0 do
   begin
   //ConsoleLines.Add(Resultado[0]);
   Resultado.Delete(0);
   end;
if Errores.Count > 0 then
   begin
   ConsoleLines.Add('ERRORS');
   while Errores.Count > 0 do
      begin
      ConsoleLines.Add(Errores[0]);
      Errores.Delete(0);
      end;
   end;
MyProcess.Free;Resultado.Free; Errores.Free;
end;

// Regresa la firma de la cadena especificada usando la clave privada
function GetStringSigned(StringtoSign, PrivateKey:String):String;
var
  //FileToSign :Textfile;
  //FilePrivate : TextFile;
  Signature, MessageAsBytes: TBytes;
Begin
MessageAsBytes :=StrToByte(DecodeStringBase64(StringtoSign));
Signature := TSignerUtils.SignMessage(MessageAsBytes, StrToByte(DecodeStringBase64(PrivateKey)),
      TKeyType.SECP256K1);
Result := EncodeStringBase64(ByteToString(Signature));
{
//creates the file with the string to be signed
AssignFile(FileToSign, 'temp_string.txt');
rewrite(FileToSign);
write(FileToSign,StringtoSign);
CloseFile(FileToSign);
//creates the file with the private key
AssignFile(FilePrivate, 'temp_priv.pem');
rewrite(FilePrivate);
writeln(FilePrivate,'-----BEGIN EC PRIVATE KEY-----');
writeln(FilePrivate,copy(PrivateKey,1,64));
writeln(FilePrivate,copy(PrivateKey,65,64));
writeln(FilePrivate,copy(PrivateKey,129,64));
writeln(FilePrivate,'-----END EC PRIVATE KEY-----');
CloseFile(FilePrivate);
RunOpenSSLCommand('openssl dgst -sha1 -out temp_test.bin -sign temp_priv.pem temp_string.txt');
RunOpenSSLCommand('openssl base64 -in temp_test.bin -out temp_test.b64');
result := GetBase64TextFromFile('temp_test.b64');
Deletefile('temp_string.txt');
Deletefile('temp_priv.pem');
DeleteFile('temp_test.bin');
Deletefile('temp_test.b64');
}
End;

// RETURNS THE BASE64 STRING FROM A FILE
function GetBase64TextFromFile(fileb64:string):string;
var
  KeyFile: TextFile;
  LineText, Resultado : String;
Begin
Resultado := '';
AssignFile(KeyFile,fileb64);
   Try
   reset(Keyfile);
   while not eof(KeyFile) do
      begin
      readln(KeyFile, LineText);
      If AnsiContainsStr(LineText,'-----') = false then
         Resultado := Resultado + LineText;
      end;
   Closefile(Keyfile);
   except
   on E: EInOutError do
      ConsoleLines.Add(LAngLine(25));         //Base64 file not found
   end;
Result := Resultado;
end;

// VERIFY IF A SIGNED STRING IS VALID
function VerifySignedString(StringToVerify,B64String,PublicKey:String):boolean;
var
  //FileToSign :Textfile;
  //FilePublic : TextFile;
  //FileB64 : Textfile;
  Signature, MessageAsBytes: TBytes;
Begin
MessageAsBytes := StrToByte(DecodeStringBase64(StringToVerify));
Signature := StrToByte(DecodeStringBase64(B64String));
Result := TSignerUtils.VerifySignature(Signature, MessageAsBytes,
      StrToByte(DecodeStringBase64(PublicKey)), TKeyType.SECP256K1);
{
//creates the file with the string to be verified
AssignFile(FileToSign, 'temp_string.txt');
rewrite(FileToSign);
write(FileToSign,StringToVerify);
CloseFile(FileToSign);
//creates the file with the private key
AssignFile(FilePublic, 'temp_pub.pem');
rewrite(FilePublic);
writeln(FilePublic,'-----BEGIN PUBLIC KEY-----');
writeln(FilePublic,copy(PublicKey,1,64));
writeln(FilePublic,copy(PublicKey,65,64));
writeln(FilePublic,'-----END PUBLIC KEY-----');
CloseFile(FilePublic);
//creates the file containing the base64 data
AssignFile(FileB64, 'temp_test.b64');
rewrite(FileB64);
writeln(FileB64,copy(B64String,1,64));
writeln(FileB64,copy(B64String,65,64));
CloseFile(FileB64);
//get the binary file from base64
RunOpenSSLCommand('openssl base64 -d -in temp_test.b64 -out temp_test.bin');
if RunOpenSSLCommand('openssl dgst -sha1 -verify temp_pub.pem -signature temp_test.bin temp_string.txt') then
   begin
   result := true;
   //ConsoleLines.Add(LangLine(27));     //Signed Verification Ok
   end
else
   begin
   result := false;                     //Signed Verification FAILED
   //ConsoleLines.Add(LangLine(28));
   end;
Deletefile('temp_string.txt');
Deletefile('temp_pub.pem');
DeleteFile('temp_test.bin');
Deletefile('temp_test.b64');
}
End;

// Devuelve el hash para una trx
function GetTransferHash(TextLine:string):String;
var
  Resultado : String = '';
  Sumatoria, clave : string;
Begin
Resultado := HashSHA256String(TextLine);
Resultado := BMHexTo58(Resultado,58);
sumatoria := BMB58resumen(Resultado);
clave := BMDecTo58(sumatoria);
Result := 'tR'+Resultado+clave;
End;

// Devuelve el hash de una orden
function GetOrderHash(TextLine:string):String;
Begin
Result := HashSHA256String(TextLine);
Result := 'OR'+BMHexTo58(Result,36);
End;

// Añade una operacion a la espera de cripto
Procedure AddCriptoOp(tipo:integer;proceso, resultado:string);
Begin
SetLength(CriptoOpsTipo,length(CriptoOpsTipo)+1);
CriptoOpsTipo[length(CriptoOpsTipo)-1] := tipo;
SetLength(CriptoOpsOper,length(CriptoOpsOper)+1);
CriptoOpsOper[length(CriptoOpsOper)-1] := proceso;
SetLength(CriptoOpsResu,length(CriptoOpsResu)+1);
CriptoOpsResu[length(CriptoOpsResu)-1] := resultado;
End;

// Indica que se pueden empezar a realizar las operaciones del cripto thread
Procedure StartCriptoThread();
Begin
if not CriptoThreadRunning then CriptoOPsThread := Beginthread(tthreadfunc(@ProcessCriptoOP));
End;

// Elimina la operacion cripto
Procedure DeleteCriptoOp();
Begin
Delete(CriptoOpsTipo,0,1);
Delete(CriptoOpsOper,0,1);
Delete(CriptoOpsResu,0,1);
End;

// Procesa las operaciones criptograficas en segundo plano
Function ProcessCriptoOP(aParam:Pointer):PtrInt;
var
  NewAddrss : integer = 0;
  PosRef : integer; cadena,claveprivada,firma, resultado:string;
Begin
CriptoThreadRunning := true;
Repeat
   begin
   if CriptoOpsTipo[0] = 0 then // actualizar balance
      begin
      MyCurrentBalance := GetWalletBalance();
      end
   else if CriptoOpsTipo[0] = 1 then // Crear direccion
      begin
      SetLength(ListaDirecciones,Length(ListaDirecciones)+1);
      ListaDirecciones[Length(ListaDirecciones)-1] := CreateNewAddress;
      S_Wallet := true;
      U_DirPanel := true;
      NewAddrss := NewAddrss + 1;
      end
   else if CriptoOpsTipo[0] = 2 then // customizar
      begin
      posRef := pos('$',CriptoOpsOper[0]);
      cadena := copy(CriptoOpsOper[0],1,posref-1);
      claveprivada := copy (CriptoOpsOper[0],posref+1,length(CriptoOpsOper[0]));
      firma := GetStringSigned(cadena,claveprivada);
      resultado := StringReplace(CriptoOpsResu[0],'[[RESULT]]',firma,[rfReplaceAll, rfIgnoreCase]);
      OutgoingMsjs.Add(resultado);
      OutText('Customization sent',false,2);
      end
    else if CriptoOpsTipo[0] = 3 then // enviar fondos
      begin
      Sendfunds(CriptoOpsOper[0]);
      end
    else if CriptoOpsTipo[0] = 4 then // recibir customizacion
      begin
      PTC_Custom(CriptoOpsOper[0]);
      end
    else if CriptoOpsTipo[0] = 5 then // recibir transferencia
      begin
      PTC_Order(CriptoOpsOper[0]);
      end;
   DeleteCriptoOp();
   end;
until length(CriptoOpsTipo) = 0;
if NewAddrss > 0 then OutText(IntToStr(NewAddrss)+' new addresses',false,2);
CriptoThreadRunning := false;
ProcessCriptoOP := 0;
End;

// *****************************************************************************
// ***************************FUNCTIONS OF BIGMATHS*****************************
// *****************************************************************************

// REMOVES LEFT CEROS
function ClearLeadingCeros(numero:string):string;
var
  count : integer = 0;
  movepos : integer = 0;
Begin
result := '';
if numero[1] = '-' then movepos := 1;
for count := 1+movepos to length(numero) do
   begin
   if numero[count] <> '0' then result := result + numero[count];
   if ((numero[count]='0') and (length(result)>0)) then result := result + numero[count];
   end;
if result = '' then result := '0';
if ((movepos=1) and (result <>'0')) then result := '-'+result;
End;

// ADDS 2 NUMBERS
function BMAdicion(numero1,numero2:string):string;
var
  longitude : integer = 0;
  count: integer = 0;
  carry : integer = 0;
  resultado : string = '';
  thiscol : integer;
  ceros : integer;
Begin
longitude := length(numero1);
if length(numero2)>longitude then
   begin
   longitude := length(numero2);
   ceros := length(numero2)-length(numero1);
   while count < ceros do
      begin
      numero1 := '0'+numero1;
      count := count+1;
      end;
   end
else
   begin
   ceros := length(numero1)-length(numero2);
      while count < ceros do
      begin
      numero2 := '0'+numero2;
      count := count+1;
      end;
   end;
for count := longitude downto 1 do
   Begin
   thiscol := StrToInt(numero1[count]) + StrToInt(numero2[count])+carry;
   carry := 0;
   if thiscol > 9 then
      begin
      thiscol := thiscol-10;
      carry := 1;
      end;
   resultado := inttoStr(thiscol)+resultado;
   end;
if carry > 0 then resultado := '1'+resultado;
result := resultado;
End;

// DRAW CEROS FOR MULTIPLICATION
Function PonerCeros(numero:String;cuantos:integer):string;
var
  contador : integer = 0;
  NewNumber : string;
Begin
NewNumber := numero;
while contador < cuantos do
   begin
   NewNumber := NewNumber+'0';
   contador := contador+1;
   end;
result := NewNumber;
End;

// MULTIPLIER
Function BMMultiplicar(Numero1,Numero2:string):string;
var
  count,count2 : integer;
  sumandos : array of string;
  thiscol : integer;
  carry: integer = 0;
  cantidaddeceros : integer = 0;
  TotalSuma : string = '0';
Begin
setlength(sumandos,length(numero2));
for count := length(numero2) downto 1 do
   begin
   for count2 := length(numero1) downto 1 do
      begin
      thiscol := (StrToInt(numero2[count]) * StrToInt(numero1[count2])+carry);
      carry := thiscol div 10;
      ThisCol := ThisCol - (carry*10);
      sumandos[cantidaddeceros] := IntToStr(thiscol)+ sumandos[cantidaddeceros];
      end;
   if carry > 0 then sumandos[cantidaddeceros] := IntToStr(carry)+sumandos[cantidaddeceros];
   carry := 0;
   sumandos[cantidaddeceros] := PonerCeros(sumandos[cantidaddeceros],cantidaddeceros);
   cantidaddeceros := cantidaddeceros+1;
   end;
for count := 0 to length(sumandos)-1 do
   TotalSuma := BMAdicion(Sumandos[count],totalsuma);
result := ClearLeadingCeros(TotalSuma);
End;

// DIVIDES TO NUMBERS
Function BMDividir(Numero1,Numero2:string):DivResult;
var
  counter : integer;
  cociente : string = '';
  long : integer;
  Divisor : Int64;
  ThisStep : String = '';
Begin
long := length(numero1);
Divisor := StrToInt64(numero2);
for counter := 1 to long do
   begin
   ThisStep := ThisStep + Numero1[counter];
   if StrToInt(ThisStep) >= Divisor then
      begin
      cociente := cociente+IntToStr(StrToInt(ThisStep) div Divisor);
      ThisStep := (IntToStr(StrToInt(ThisStep) mod Divisor));
      end
   else cociente := cociente+'0';
   end;
result.cociente := ClearLeadingCeros(cociente);
result.residuo := ClearLeadingCeros(thisstep);
End;

// CALCULATES A EXPONENTIAL NUMBER
Function BMExponente(Numero1,Numero2:string):string;
var
  count : integer = 0;
  resultado : string = '';
Begin
if numero2 = '1' then
   begin
   result := numero1;
   exit;
   end;
if numero2 = '0' then
   begin
   result := '1';
   exit;
   end;
resultado := numero1;
for count := 2 to StrToInt(numero2) do
   resultado := BMMultiplicar(resultado,numero1);
result := resultado;
End;

// HEX TO DECIMAL
function BMHexToDec(numerohex:string):string;
var
  DecValues : array of integer;
  ExpValues : array of string;
  MultipliValues : array of string;
  counter : integer;
  Long : integer;
  Resultado : string = '0';
Begin
Long := length(numerohex);
numerohex := uppercase(numerohex);
setlength(DecValues,0);
setlength(ExpValues,0);
setlength(MultipliValues,0);
setlength(DecValues,Long);
setlength(ExpValues,Long);
setlength(MultipliValues,Long);
for counter := 1 to Long do
   DecValues[counter-1] := Pos(NumeroHex[counter],HexAlphabet)-1;
for counter := 1 to long do
   ExpValues[counter-1] := BMExponente('16',IntToStr(long-counter));
for counter := 1 to Long do
   MultipliValues[counter-1] := BMMultiplicar(ExpValues[counter-1],IntToStr(DecValues[counter-1]));
for counter := 1 to long do
   Resultado := BMAdicion(resultado,MultipliValues[counter-1]);
result := resultado;
End;

// Hex a base 58
function BMHexTo58(numerohex:string;alphabetnumber:integer):string;
var
  decimalvalue : string;
  restante : integer;
  ResultadoDiv : DivResult;
  Resultado : string = '';
  AlpahbetUsed : String;
Begin
setmilitime('BMHexTo58',1);
AlpahbetUsed := B58Alphabet;
if alphabetnumber=36 then AlpahbetUsed := B36Alphabet;
decimalvalue := BMHexToDec(numerohex);
while length(decimalvalue) >= 2 do
   begin
   ResultadoDiv := BMDividir(decimalvalue,IntToStr(alphabetnumber));
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := AlpahbetUsed[restante+1]+resultado;
   end;
if StrToInt(decimalValue) >= alphabetnumber then
   begin
   ResultadoDiv := BMDividir(decimalvalue,IntToStr(alphabetnumber));
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := AlpahbetUsed[restante+1]+resultado;
   end;
if StrToInt(decimalvalue) > 0 then resultado := AlpahbetUsed[StrToInt(decimalvalue)+1]+resultado;
result := resultado;
setmilitime('BMHexTo58',2);
End;

// RETURN THE SUMATORY OF A BASE58
function BMB58resumen(numero58:string):string;
var
  counter, total : integer;
Begin
total := 0;
for counter := 1 to length(numero58) do
   begin
   total := total+Pos(numero58[counter],B58Alphabet)-1;
   end;
result := IntToStr(total);
End;

// CONVERTS A DECIMAL VALUE TO A BASE58 STRING
function BMDecTo58(numero:string):string;
var
  decimalvalue : string;
  restante : integer;
  ResultadoDiv : DivResult;
  Resultado : string = '';
Begin
decimalvalue := numero;
while length(decimalvalue) >= 2 do
   begin
   ResultadoDiv := BMDividir(decimalvalue,'58');
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := B58Alphabet[restante+1]+resultado;
   end;
if StrToInt(decimalValue) >= 58 then
   begin
   ResultadoDiv := BMDividir(decimalvalue,'58');
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := B58Alphabet[restante+1]+resultado;
   end;
if StrToInt(decimalvalue) > 0 then resultado := B58Alphabet[StrToInt(decimalvalue)+1]+resultado;
result := resultado;
End;

END. // END UNIT

