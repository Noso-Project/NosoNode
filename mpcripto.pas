unit mpCripto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, process, strutils, MD5, DCPsha256,
  mpsignerutils, base64, HlpHashFactory, mpcoin, mptime, translation;

function CreateNewAddress(): WalletData;
Function GetPublicKeyFromPem():String;
Function GetPrivateKeyFromPem():String;
function GetAddressFromPublicKey(PubKey:String):String;
function HashSha256String(StringToHash:string):string;
function HashMD160String(StringToHash:string):String;
Function HashMD5String(StringToHash:String):String;
procedure NuevaDireccion(linetext:string);
Function HashMD5File(FileToHash:String):String;
function IsValidHashAddress(Address:String):boolean;
function IsValid58(base58text:string):boolean;
function DireccionEsMia(direccion:string):integer;
Procedure RunExternalProgram(ProgramToRun:String);
function GetStringSigned(StringtoSign, PrivateKey:String):String;
function VerifySignedString(StringToVerify,B64String,PublicKey:String):boolean;
function GetTransferHash(TextLine:string):String;
Function GetTrfrHashText(Order:OrderData):String;
function GetOrderHash(TextLine:string):String;
Procedure AddCriptoOp(tipo:integer;proceso, resultado:string);
Procedure StartCriptoThread();
Procedure DeleteCriptoOp();
Function ProcessCriptoOP(aParam:Pointer):PtrInt;
function Recursive256(incomingtext:string):string;
Function GetMNSignature():string;
function NodeVerified(ThisNode:TMasterNode):boolean;
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
  mpParser, mpGui, mpProtocol, mpdisk;

// Crea una nueva direecion
function CreateNewAddress():WalletData;
var
  //PublicKey, PrivateKey : String;
  MyData: WalletData;
  Address: String;
  KeysPair: TKeyPair;
Begin
setmilitime('CreateNewAddress',1);
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
Result := MyData;
setmilitime('CreateNewAddress',2);
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
      ConsoleLinesAdd(LangLine(26));     //Public key file not found
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
      ConsoleLinesAdd(LangLine(26));     //Public key file not found
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
begin
result :=
THashFactory.TCrypto.CreateSHA2_256().ComputeString(StringToHash, TEncoding.UTF8).ToString();
end;

// RETURNS HASH MD160 OF A STRING
function HashMD160String(StringToHash:string):String;
Begin
result :=
THashFactory.TCrypto.CreateRIPEMD160().ComputeString(StringToHash, TEncoding.UTF8).ToString();
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
result := Uppercase('d41d8cd98f00b204e9800998ecf8427e');  // empty string
TRY
result := UpperCase(MD5Print(MD5File(FileToHash)));
EXCEPT ON E:Exception do
   ToExcLog('File not found for MD5 hash: '+filetohash);
END;
End;

function IsValid58(base58text:string):boolean;
var
  counter : integer;
Begin
result := true;
if length(base58text) > 0 then
   begin
   for counter := 1 to length(base58text) do
      begin
      if pos (base58text[counter],B58Alphabet) = 0 then
         begin
         result := false;
         break;
         end;
      end;
   end
else result := false;
End;

// Checks if a string is a valid address hash
function IsValidHashAddress(Address:String):boolean;
var
  OrigHash : String;
  Clave:String;
Begin
result := false;
if ((length(address)>20) and (address[1] = 'N')) then
   begin
   OrigHash := Copy(Address,2,length(address)-3);
   if IsValid58(OrigHash) then
      begin
      Clave := BMDecTo58(BMB58resumen(OrigHash));
      OrigHash := CoinChar+OrigHash+clave;
      if OrigHash = Address then result := true else result := false;
      end;
   end
End;

// Verifica si la direccion enviada esta en la cartera del usuario
function DireccionEsMia(direccion:string):integer;
var
  contador : integer = 0;
Begin
Result := -1;
if ((direccion ='') or (length(direccion)<5)) then exit;
for contador := 0 to length(Listadirecciones)-1 do
   begin
   if ((ListaDirecciones[contador].Hash = direccion) or (ListaDirecciones[contador].Custom = direccion )) then
      begin
      result := contador;
      break;
      end;
   end;
if ( (not IsValidHashAddress(direccion)) and (AddressSumaryIndex(direccion)<0) ) then result := -1;
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
   {$IFDEF Linux}
   process.Executable := 'bash';
   process.Parameters.Add(ProgramToRun);
   {$ENDIF}
   {$IFDEF WINDOWS}
   Process.Executable := ProgramToRun;
   {$ENDIF}
   Process.Execute;
   finally
   Process.Free;
   end;
End;

// SIGNS A MESSAGE WITH THE GIVEN PRIVATE KEY
function GetStringSigned(StringtoSign, PrivateKey:String):String;
var
  Signature, MessageAsBytes: TBytes;
Begin
Result := '';
TRY
MessageAsBytes :=StrToByte(DecodeStringBase64(StringtoSign));
Signature := TSignerUtils.SignMessage(MessageAsBytes, StrToByte(DecodeStringBase64(PrivateKey)),
      TKeyType.SECP256K1);
Result := EncodeStringBase64(ByteToString(Signature));
EXCEPT ON E:Exception do
   begin
   ToExcLog('ERROR Signing message');
   end;
END{Try};
End;

// VERIFY IF A SIGNED STRING IS VALID
function VerifySignedString(StringToVerify,B64String,PublicKey:String):boolean;
var
  Signature, MessageAsBytes: TBytes;
Begin
result := false;
TRY
MessageAsBytes := StrToByte(DecodeStringBase64(StringToVerify));
Signature := StrToByte(DecodeStringBase64(B64String));
Result := TSignerUtils.VerifySignature(Signature, MessageAsBytes,
      StrToByte(DecodeStringBase64(PublicKey)), TKeyType.SECP256K1);
EXCEPT ON E:Exception do
   begin
   ToExcLog('ERROR Verifying signature');
   end;
END{Try};
End;

// Returns a transfer gasg
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

Function GetTrfrHashText(Order:OrderData):String;
Begin
Result := '';
End;

// Devuelve el hash de una orden
function GetOrderHash(TextLine:string):String;
Begin
Result := HashSHA256String(TextLine);
Result := 'OR'+BMHexTo58(Result,36);
End;

// Añade una operacion a la espera de cripto
Procedure AddCriptoOp(tipo:integer;proceso, resultado:string);
var
  NewOp: TArrayCriptoOp;
Begin
NewOp.tipo := tipo;
NewOp.data:=proceso;
NewOp.result:=resultado;
EnterCriticalSection(CSCriptoThread);
TRY
Insert(NewOp,ArrayCriptoOp,length(ArrayCriptoOp));

EXCEPT ON E:Exception do
   ToExcLog('Error adding Operation to crypto thread:'+proceso);
END{Try};
LeaveCriticalSection(CSCriptoThread);
End;

// Indica que se pueden empezar a realizar las operaciones del cripto thread
Procedure StartCriptoThread(); // deprecated
Begin

End;

// Elimina la operacion cripto
Procedure DeleteCriptoOp();
Begin
EnterCriticalSection(CSCriptoThread);
if Length(ArrayCriptoOp) > 0 then
   begin
   TRY
   Delete(ArrayCriptoOp,0,1);
   EXCEPT ON E:Exception do
      begin
      ToExcLog('Error removing Operation from crypto thread:'+E.Message);
      end;
   END{Try};
   end;
LeaveCriticalSection(CSCriptoThread);
End;

// Procesa las operaciones criptograficas en segundo plano
Function ProcessCriptoOP(aParam:Pointer):PtrInt;
var
  NewAddrss : integer = 0;
  PosRef : integer; cadena,claveprivada,firma, resultado:string;
Begin
Repeat
   begin
   if ArrayCriptoOp[0].tipo = 0 then // actualizar balance
      begin
      //MyCurrentBalance := GetWalletBalance();
      end
   else if ArrayCriptoOp[0].tipo = 1 then // Crear direccion
      begin
      SetLength(ListaDirecciones,Length(ListaDirecciones)+1);
      ListaDirecciones[Length(ListaDirecciones)-1] := CreateNewAddress;
      S_Wallet := true;
      U_DirPanel := true;
      NewAddrss := NewAddrss + 1;
      end
   else if ArrayCriptoOp[0].tipo = 2 then // customizar
      begin
      posRef := pos('$',ArrayCriptoOp[0].data);
      cadena := copy(ArrayCriptoOp[0].data,1,posref-1);
      claveprivada := copy (ArrayCriptoOp[0].data,posref+1,length(ArrayCriptoOp[0].data));
      firma := GetStringSigned(cadena,claveprivada);
      resultado := StringReplace(ArrayCriptoOp[0].result,'[[RESULT]]',firma,[rfReplaceAll, rfIgnoreCase]);
      OutgoingMsjsAdd(resultado);
      OutText('Customization sent',false,2);
      end
    else if ArrayCriptoOp[0].tipo = 3 then // enviar fondos
      begin
      TRY
      Sendfunds(ArrayCriptoOp[0].data);
      EXCEPT ON E:Exception do
         ToExclog(format(rs2501,[E.Message]));
      END{Try};
      end
    else if ArrayCriptoOp[0].tipo = 4 then // recibir customizacion
      begin
      TRY
      PTC_Custom(ArrayCriptoOp[0].data);
      EXCEPT ON E:Exception do
         ToExclog(format(rs2502,[E.Message]));
      END{Try};
      end
    else if ArrayCriptoOp[0].tipo = 5 then // recibir transferencia
      begin
      TRY
      PTC_Order(ArrayCriptoOp[0].data);
      EXCEPT ON E:Exception do
         ToExclog(format(rs2503,[E.Message]));
      END{Try};
      end;
   DeleteCriptoOp();
   end;
until length(ArrayCriptoOp) = 0;
if NewAddrss > 0 then OutText(IntToStr(NewAddrss)+' new addresses',false,2);
CriptoThreadRunning := false;
ProcessCriptoOP := 0;
End;

function Recursive256(incomingtext:string):string;
var
  Resultado : string;
  contador : integer;

  function ReOrderHash(entrada : string):string;
  var
    counter : integer;
    resultado2 : string = '';
    chara,charb, charf : integer;
  Begin
  for counter := 1 to length(entrada) do
     begin
     chara := Hex2Dec(entrada[counter]);
     if counter < Length(entrada) then charb := Hex2Dec(entrada[counter+1])
     else charb := Hex2Dec(entrada[1]);
     charf := chara+charb; if charf>15 then charf := charf-16;
     resultado2 := resultado2+inttohex(charf,1);
     end;
  result := resultado2
  End;

Begin
setmilitime('Recursive256',1);
Resultado := HashSha256String(incomingtext);
for contador := 1 to 5 do
   Begin
   resultado := resultado+ReOrderHash(Resultado);
   end;
result := HashSha256String(resultado);
//result := resultado;
setmilitime('Recursive256',2);
End;

// Returns the signature for the masternode report
Function GetMNSignature():string;
var
  TextToSign : string = '';
  SignAddressIndex : integer;
  PublicKey : string;
  CurrentTime : string;
  ReportHash : string;
Begin
setmilitime('GetMNSignature',1);
result := '';
CurrentTime := UTCTime;
TextToSign := CurrentTime+' '+MN_IP+' '+MyLastBlock.ToString+' '+MyLastBlockHash;
ReportHash := HashMD5String(TextToSign);
SignAddressIndex := DireccionEsMia(MN_Sign);
if SignAddressIndex<0 then result := ''
else
   begin
   PublicKey := ListaDirecciones[SignAddressIndex].PublicKey;
   result := CurrentTime+' '+PublicKey+' '+GetStringSigned(TextToSign,ListaDirecciones[SignAddressIndex].PrivateKey)+' '+ReportHash;
   end;
setmilitime('GetMNSignature',2);
End;

function NodeVerified(ThisNode:TMasterNode):boolean;
var
  StringToSign : string;
  PosRequired : int64;
  FilterOn : boolean = false;
Begin
setmilitime('NodeVerified',1);
result := false;
if uppercase(ThisNode.Ip) = 'LOCALHOST' then FilterOn:= true;
if not IsValidIP(ThisNode.Ip) then FilterOn:= true;
if ( (ThisNode.FundAddress='') or (ThisNode.Ip='') or (ThisNode.PublicKey='') or (ThisNode.SignAddress='') or
   (Thisnode.BlockHash='') or (thisnode.ReportHash='') or (thisnode.Signature='') or (thisnode.Time='')) then FilterOn:= true;
if GetAddressFromPublicKey(thisnode.PublicKey) <> thisnode.SignAddress then FilterOn:= true;
If Thisnode.Block <> MyLastBlock then FilterOn:= true;
if FilterOn then
   begin
   setmilitime('NodeVerified',2);
   exit;
   end;
StringToSign := Thisnode.Time+' '+Thisnode.Ip+' '+ThisNode.Block.ToString+' '+thisnode.BlockHash;
if VerifySignedString(StringToSign,thisnode.Signature,thisnode.PublicKey) then
   begin
   PosRequired := (GetSupply(MyLastBlock+1)*PosStackCoins) div 10000;
   if MyLastBlock+1 < MNBlockStart then PosRequired := 0;
   if listasumario[AddressSumaryIndex(ThisNode.FundAddress)].Balance >= PosRequired then
      result := true;
   end
else ToExcLog('ERROR: Node not verified: '+GetTextFromMN(ThisNode));
setmilitime('NodeVerified',2);
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
if numero2 = '1' then result := numero1
else if numero2 = '0' then result := '1'
else
   begin
   resultado := numero1;
   for count := 2 to StrToInt(numero2) do
      resultado := BMMultiplicar(resultado,numero1);
   result := resultado;
   end;
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
