unit mpCripto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, process, strutils, MD5, DCPsha256,
  mpsignerutils, base64, HlpHashFactory, mpcoin, nosotime, translation, SbpBase58,
  SbpBase58Alphabet, ClpConverters, nosodebug;

function CreateNewAddress(): WalletData;
function GetAddressFromPublicKey(PubKey:String):String;
function GetAddressFromPubKey_New(const PubKey: String): String;
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
Function GetMNSignature():string;
Function EncodeCertificate(certificate:string):string;
Function DecodeCertificate(certificate:string):string;
Function NosoHash(source:string):string;
Function CheckHashDiff(Target,ThisHash:String):string;
// Big Maths
function ClearLeadingCeros(numero:string):string;
function BMAdicion(numero1,numero2:string):string;
Function PonerCeros(numero:String;cuantos:integer):string;
Function BMMultiplicar(Numero1,Numero2:string):string;
Function BMDividir(Numero1,Numero2:string):DivResult;
Function BMExponente(Numero1,Numero2:string):string;
function BMHexToDec(numerohex:string):string;
Function BM58ToDec(number58:string):String;
function BMHexTo58(numerohex:string;alphabetnumber:integer):string;
function BMB58resumen(numero58:string):string;
function ChecksumBase58(S: String): Int32;
function BMDecTo58(numero:string):string;
function BMDecToHex(numero:string):string;




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
BeginPerformance('CreateNewAddress');
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
EndPerformance('CreateNewAddress');
End;

// RETURNS AN ADDRESS FROM A PUBLIC LEY
function GetAddressFromPublicKey(PubKey:String):String;
var
  PubSHAHashed,Hash1,Hash2,clave:String;
  sumatoria : string;
Begin
BeginPerformance('GetAddressFromPublicKey');
PubSHAHashed := HashSha256String(PubKey);
Hash1 := HashMD160String(PubSHAHashed);
hash1 := BMHexTo58(Hash1,58);
//hash1 := TBase58.BitCoin.Encode(StrToByte(BMHexToDec(hash1)));
sumatoria := BMB58resumen(Hash1);
clave := BMDecTo58(sumatoria);
hash2 := hash1+clave;
Result := CoinChar+hash2;
EndPerformance('GetAddressFromPublicKey');
End;

function GetAddressFromPubKey_New(const PubKey: String): String;
var
  s_data, s_cksum, s_cksum_hex: AnsiString;
  hashSHA256: String;
  hashRMD160: TBytes;
begin
  Result := EmptyStr;

  if Length(PubKey) = 0 then
    Exit;

  { SHA256 PubKey string hash }
  hashSHA256 := THashFactory.TCrypto.CreateSHA2_256
    .ComputeString(PubKey, TEncoding.ANSI)
    .ToString;
  { RIPEMD160 hash of SHA256 PubKey hash }
  hashRMD160 := THashFactory.TCrypto.CreateRIPEMD160
    .ComputeString(hashSHA256, TEncoding.ANSI)
    .GetBytes;
  { Encode RIPEMD160 hash as Base58 string }
  s_data := TBase58.BitCoin.Encode(hashRMD160);
  { Get s_data checksum in HEX }
  s_cksum_hex := HexStr(ChecksumBase58(s_data), 4);
  { Encode checksum as Base58 string }
  s_cksum := TBase58.BitCoin.Encode(
    TConverters.ConvertHexStringToBytes(s_cksum_hex)
  );
  { Concat all }
  Result := Concat('N', s_data, s_cksum);
end;

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
      ToExcLog('Error RunExternalProgram='+ProgramToRun+' Error:'+E.Message);
   END; {TRY}
Process.Free;
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

// Returns the signature for the masternode report
Function GetMNSignature():string;
var
  TextToSign : string = '';
  SignAddressIndex : integer;
  PublicKey : string;
  CurrentTime : string;
  ReportHash : string;
Begin
BeginPerformance('GetMNSignature');
result := '';
CurrentTime := UTCTimeStr;
TextToSign := CurrentTime+' '+MN_IP+' '+MyLastBlock.ToString+' '+MyLastBlockHash;
ReportHash := HashMD5String(TextToSign);
SignAddressIndex := DireccionEsMia(MN_Sign);
if SignAddressIndex<0 then result := ''
else
   begin
   PublicKey := ListaDirecciones[SignAddressIndex].PublicKey;
   result := CurrentTime+' '+PublicKey+' '+GetStringSigned(TextToSign,ListaDirecciones[SignAddressIndex].PrivateKey)+' '+ReportHash;
   end;
EndPerformance('GetMNSignature');
End;

Function EncodeCertificate(certificate:string):string;

   Function SplitCertificate(TextData:String):String;
   var
     InpuntLength, Tramos, counter: integer;
     ThisTramo, This58 : string;
   Begin
   result :='';
   InpuntLength := length(TextData);
   if InpuntLength < 100 then exit;
   Tramos := InpuntLength div 32;
   if InpuntLength mod 32 > 0 then tramos := tramos+1;
   for counter := 0 to tramos-1 do
      begin
      ThisTramo := '1'+Copy(TextData,1+(counter*32),32);
      This58 := BMHexTo58(ThisTramo,58);
      Result := Result+This58+'0';
      end;
   End;

Begin
BeginPerformance('EncodeCert');
Certificate := UPPERCASE(XorEncode(HashSha256String('noso'),certificate));
result := SplitCertificate(certificate);
EndPerformance('EncodeCert');
End;

Function DecodeCertificate(certificate:string):string;

   Function UnSplitCertificate(TextData:String):String;
   var
     counter:integer;
     Tramo : integer = 1;
     Thistramo :string = '';
     ToDec, ToHex : string;
   Begin
   result := '';
   for counter := 1 to length(TextData) do
      begin
      if TextData[counter]<>'0' then Thistramo := thistramo+TextData[counter]
      else
         begin
         ToDec := BM58Todec(Thistramo);
         ToHex := BMDecToHex(ToDec);
         Delete(ToHex,1,1);
         Result := result+ToHex;
         ThisTramo := ''; Tramo := tramo+1;
         end;
      end;
   End;

Begin
BeginPerformance('DecodeCert');
Certificate := UnSplitCertificate(certificate);
result := XorDecode(HashSha256String('noso'), Certificate);
EndPerformance('DecodeCert');
End;

Function NosoHash(source:string):string;
var
  counter : integer;
  FirstChange : array[1..128] of string;
  finalHASH : string;
  ThisSum : integer;
  charA,charB,charC,charD, CharE, CharF, CharG, CharH:integer;
  Filler : string = '%)+/5;=CGIOSYaegk';

  Function GetClean(number:integer):integer;
  Begin
  result := number;
  if result > 126 then
     begin
     repeat
       result := result-95;
     until result <= 126;
     end;
  End;

  function RebuildHash(incoming : string):string;
  var
    counter : integer;
    resultado2 : string = '';
    chara,charb, charf : integer;
  Begin
  for counter := 1 to length(incoming) do
     begin
     chara := Ord(incoming[counter]);
       if counter < Length(incoming) then charb := Ord(incoming[counter+1])
       else charb := Ord(incoming[1]);
     charf := chara+charb; CharF := GetClean(CharF);
     resultado2 := resultado2+chr(charf);
     end;
  result := resultado2
  End;

Begin
result := '';
for counter := 1 to length(source) do
   if ((Ord(source[counter])>126) or (Ord(source[counter])<33)) then
      begin
      source := '';
      break
      end;
if length(source)>63 then source := '';
repeat source := source+filler;
until length(source) >= 128;
source := copy(source,0,128);
FirstChange[1] := RebuildHash(source);
for counter := 2 to 128 do FirstChange[counter]:= RebuildHash(firstchange[counter-1]);
finalHASH := FirstChange[128];
for counter := 0 to 31 do
   begin
   charA := Ord(finalHASH[(counter*4)+1]);
   charB := Ord(finalHASH[(counter*4)+2]);
   charC := Ord(finalHASH[(counter*4)+3]);
   charD := Ord(finalHASH[(counter*4)+4]);
   thisSum := CharA+charB+charC+charD;
   ThisSum := GetClean(ThisSum);
   Thissum := ThisSum mod 16;
   result := result+IntToHex(ThisSum,1);
   end;
Result := HashMD5String(Result);
End;

Function CheckHashDiff(Target,ThisHash:String):string;
var
   ThisChar : string = '';
   counter : integer;
   ValA, ValB, Diference : Integer;
   ResChar : String;
   Resultado : String = '';
Begin
result := 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
for counter := 1 to 32 do
   begin
   ValA := Hex2Dec(ThisHash[counter]);
   ValB := Hex2Dec(Target[counter]);
   Diference := Abs(ValA - ValB);
   ResChar := UPPERCASE(IntToHex(Diference,1));
   Resultado := Resultado+ResChar
   end;
Result := Resultado;
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

Function BM58ToDec(number58:string):String;
var
  long,counter : integer;
  Resultado : string = '0';
  DecValues : array of integer;
  ExpValues : array of string;
  MultipliValues : array of string;
Begin
Long := length(number58);
setlength(DecValues,0);
setlength(ExpValues,0);
setlength(MultipliValues,0);
setlength(DecValues,Long);
setlength(ExpValues,Long);
setlength(MultipliValues,Long);
for counter := 1 to Long do
   DecValues[counter-1] := Pos(number58[counter],B58Alphabet)-1;
for counter := 1 to long do
   ExpValues[counter-1] := BMExponente('58',IntToStr(long-counter));
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
BeginPerformance('BMHexTo58');
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
EndPerformance('BMHexTo58');
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

function ChecksumBase58(S: String): Int32;
var C: Char;
begin
  Result := 0;
  for C in S do
    Inc(Result, Pos(C, TBase58Alphabet.BitCoin.ToString)-1);
end;

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

// CONVERTS A DECIMAL VALUE TO A HEX STRING
function BMDecToHex(numero:string):string;
var
  decimalvalue : string;
  restante : integer;
  ResultadoDiv : DivResult;
  Resultado : string = '';
Begin
decimalvalue := numero;
while length(decimalvalue) >= 2 do
   begin
   ResultadoDiv := BMDividir(decimalvalue,'16');
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := HexAlphabet[restante+1]+resultado;
   end;
if StrToInt(decimalValue) >= 16 then
   begin
   ResultadoDiv := BMDividir(decimalvalue,'16');
   DecimalValue := Resultadodiv.cociente;
   restante := StrToInt(ResultadoDiv.residuo);
   resultado := HexAlphabet[restante+1]+resultado;
   end;
if StrToInt(decimalvalue) > 0 then resultado := HexAlphabet[StrToInt(decimalvalue)+1]+resultado;
result := resultado;
End;

END. // END UNIT
