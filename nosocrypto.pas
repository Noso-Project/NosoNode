UNIT nosocrypto;

{
Unit nosocrypto 1.3
December 4th, 2023
Noso Unit for crypto functions
Requires: cryptohashlib , mpsignerutils
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, strutils,
  HlpHashFactory, md5,
  ClpConverters,ClpBigInteger,SbpBase58,
  mpsignerutils, base64, NosoDebug;

Type

  DivResult = packed record
   cociente : string[255];
   residuo : string[255];
   end;

{Hashing functions}
function HashSha256String(StringToHash:string):string;
function HashMD160String(StringToHash:string):String;
Function HashMD5String(StringToHash:String):String;
Function HashMD5File(FileToHash:String):String;

{General functions}
Function IsValid58(base58text:string):boolean;
Function GetStringSigned(StringtoSign, PrivateKey:String):String;
Function VerifySignedString(StringToVerify,B64String,PublicKey:String):boolean;
function GetAddressFromPublicKey(PubKey:String):String;
function NewGetAddressFromPublicKey(PubKey:String):String;
function FutureGetAddressFromPublicKey(const PubKey: String): String;
Function GenerateNewAddress(out pubkey:String;out privkey:String):String;
Function IsValidHashAddress(Address:String):boolean;
Function GetTransferHash(TextLine:string):String;
function GetOrderHash(TextLine:string):String;
Function GetCertificateChecksum(certificate:String):String;
Function GetCertificate(Pubkey,privkey,currtime:string):string;
Function CheckCertificate(certificate:string;out TimeStamp:String):string;
Function CheckHashDiff(Target,ThisHash:String):string;

{New base conversion functions}
function B10ToB16(const sVal: String): String;
Function B10ToB58(const sVal: String): String;
Function B16ToB10(const sHex: String): String;
Function B16ToB36(const sHex: String): String;
Function B16ToB58(const sHex: String): String;

Function B16ToB58Lite1_60(const sHex: String): String;

Function B58ToB10(const sVal: String): String;
Function B58ToB16(const sVal: String): String;
Function ChecksumBase58(const S: String): integer;
Function BMB58resumenNew(numero58:string):string;
Function BMB58resumen(numero58:string):string;
Function BMB58resumenInt(numero58:string):integer;

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
function BMDecTo58(numero:string):string;
function BMDecToHex(numero:string):string;

Const
  HexAlphabet : string = '0123456789ABCDEF';
  B36Alphabet : string = '0123456789abcdefghijklmnopqrstuvwxyz';
  B58Alphabet : string = '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz';

IMPLEMENTATION

{$REGION Internal utility methods}
function GetAlphabet(const Base: Byte): String; {$ifopt D-}inline;{$endif}
begin
  case Base of
    36:  Result := B36Alphabet;
    58:  Result := B58Alphabet;
    else Result := '';
  end;
end;

function IsValidInput(const S: String): Boolean; {$ifopt D-}inline;{$endif}
begin
  Result := (Length(S) <> 0) and (S <> '0');
end;

function EncodeBaseN(const bytes: TBytes; const sAlphabet: String; iBase: Int32 = 0): String;
const
  growthPercentage = Int32(154);
var
  bytesLen, numZeroes, outputLen, Length, carry, i, resultLen: Int32;
  inputPtr, pInput, pEnd, outputPtr, pOutputEnd, pDigit, pOutput: PByte;
  alphabetPtr, resultPtr, pResult: PChar;
  ZeroChar: Char;
  output: TBytes;
  Value: String;
begin
  result := '';
  bytesLen := System.Length(bytes);
  if (bytesLen = 0) then
  begin
    Exit;
  end;
  inputPtr := PByte(bytes);
  Value := sAlphabet;
  alphabetPtr := PChar(Value);
  pInput := inputPtr;
  pEnd := inputPtr + bytesLen;
  while ((pInput <> pEnd) and (pInput^ = 0)) do
  begin
    System.Inc(pInput);
  end;
  numZeroes := Int32(pInput - inputPtr);
  ZeroChar := alphabetPtr^;
  if (pInput = pEnd) then
  begin
    result := StringOfChar(ZeroChar, numZeroes);
    Exit;
  end;
  outputLen := bytesLen * growthPercentage div 100 + 1;
  Length := 0;
  System.SetLength(output, outputLen);
  outputPtr := PByte(output);
  pOutputEnd := outputPtr + outputLen - 1;
  while (pInput <> pEnd) do
  begin
    carry := pInput^;
    i := 0;
    pDigit := pOutputEnd;
    while (((carry <> 0) or (i < Length)) and (pDigit >= outputPtr)) do
    begin
      carry := carry + (256 * pDigit^);
      pDigit^ := Byte(carry mod iBase);
      carry := carry div iBase;
      System.Dec(pDigit);
      System.Inc(i);
    end;
    Length := i;
    System.Inc(pInput);
  end;
  System.Inc(pOutputEnd);
  pOutput := outputPtr;
  while ((pOutput <> pOutputEnd) and (pOutput^ = 0)) do
  begin
    System.Inc(pOutput);
  end;
  resultLen := {numZeroes +} Int32(pOutputEnd - pOutput);
  result := StringOfChar(ZeroChar, resultLen);
  resultPtr := PChar(result);
  pResult := resultPtr {+ numZeroes};
  while (pOutput <> pOutputEnd) do
  begin
    pResult^ := alphabetPtr[pOutput^];
    System.Inc(pOutput);
    System.Inc(pResult);
  end;
end;
{$ENDREGION}

{Returns the hash Sha2-256 of a string}
Function HashSha256String(StringToHash:string):string;
Begin
  result := THashFactory.TCrypto.CreateSHA2_256().ComputeString(StringToHash, TEncoding.UTF8).ToString();
End;

{Returns the hash RIPMED-160 of a string}
Function HashMD160String(StringToHash:string):String;
Begin
  result := THashFactory.TCrypto.CreateRIPEMD160().ComputeString(StringToHash, TEncoding.UTF8).ToString();
End;

{Returns the hash MD5 of a string}
Function HashMD5String(StringToHash:String):String;
Begin
  result := Uppercase(MD5Print(MD5String(StringToHash)));
End;

{Returns the hash MD5 of a file on disk}
Function HashMD5File(FileToHash:String):String;
Begin
  result := Uppercase('d41d8cd98f00b204e9800998ecf8427e');
  TRY
  result := UpperCase(MD5Print(MD5File(FileToHash)));
  EXCEPT ON E:Exception do
  END;
End;

{Verify if a string is a valid Base58 one}
function IsValid58(base58text:string):boolean;
var
  counter : integer;
Begin
  result := true;
  if Length(base58text) = 0 then Exit(False);
  for counter := 1 to length(base58text) do
    if pos (base58text[counter],B58Alphabet) = 0 then
      Exit(false);
End;

{Signs a message with the given privatekey}
Function GetStringSigned(StringtoSign, PrivateKey:String):String;
var
  Signature, MessageAsBytes: TBytes;
Begin
  Result := '';
  TRY
  MessageAsBytes :=StrToByte(DecodeStringBase64(StringtoSign));
  Signature := TSignerUtils.SignMessage(MessageAsBytes, StrToByte(DecodeStringBase64(PrivateKey)),TKeyType.SECP256K1);
  Result := EncodeStringBase64(ByteToString(Signature));
 EXCEPT Exit;
 END{Try};
End;

{Verify if a signed message is valid}
Function VerifySignedString(StringToVerify,B64String,PublicKey:String):boolean;
var
  Signature, MessageAsBytes: TBytes;
Begin
  result := false;
  TRY
  MessageAsBytes := StrToByte(DecodeStringBase64(StringToVerify));
  Signature := StrToByte(DecodeStringBase64(B64String));
  Result := TSignerUtils.VerifySignature(Signature, MessageAsBytes,StrToByte(DecodeStringBase64(PublicKey)), TKeyType.SECP256K1);
  EXCEPT Exit;
  END{Try};
End;

// Generates the public hash from the public key
function GetAddressFromPublicKey(PubKey:String):String;
var
  PubSHAHashed,Hash1,Hash2,clave:String;
  sumatoria : string;
Begin
PubSHAHashed := HashSha256String(PubKey);
Hash1 := HashMD160String(PubSHAHashed);
hash1 := BMHexTo58(Hash1,58);
sumatoria := BMB58resumen(Hash1);
clave := BMDecTo58(sumatoria);
hash2 := hash1+clave;
Result := 'N'+hash2;
End;

function NewGetAddressFromPublicKey(PubKey:String):String;
var
  PubSHAHashed,Hash1,Hash2,clave:String;
  sumatoria : string;
Begin
PubSHAHashed := HashSha256String(PubKey);
Hash1 := HashMD160String(PubSHAHashed);
hash1 := B16toB58(Hash1);
sumatoria := BMB58resumen(Hash1);
clave := B10toB58(sumatoria);
hash2 := hash1+clave;
Result := 'N'+hash2;
End;

function FutureGetAddressFromPublicKey(const PubKey: String): String;
var
  s_data, s_cksum, s_cksum_hex: AnsiString;
  hashSHA256: String;
  hashRMD160: TBytes;
begin
  Result := EmptyStr;
  if PubKey.IsEmpty then
    Exit;
  { SHA256 PubKey string hash }
  hashSHA256 := THashFactory.TCrypto.CreateSHA2_256
    .ComputeString(PubKey, TEncoding.ANSI)
    .ToString;
  { RIPEMD160 hash of SHA256 PubKey hash }
  hashRMD160 := THashFactory.TCrypto.CreateRIPEMD160
    .ComputeString(hashSHA256, TEncoding.ANSI)
    .GetBytes;
  // Quitar ceros al string aqui
  { Encode RIPEMD160 hash as Base58 string }
  s_data := TBase58.BitCoin.Encode(hashRMD160);
  if s_data[1]='1' then delete(s_Data,1,1);
  { Get s_data checksum in HEX }
  s_cksum_hex := HexStr(ChecksumBase58(s_data), 4);
  { Encode checksum as Base58 string }
  s_cksum := TBase58.BitCoin.Encode(
    TConverters.ConvertHexStringToBytes(s_cksum_hex)
  );
  { Concat all }
  Result := Concat('N', s_data, s_cksum);
end;

{Generates a new keys pair and returns the hash}
Function GenerateNewAddress(out pubkey:String;out privkey:String):String;
var
  KeysPair : TKeyPair;
  IsDone   : boolean = false;
  HashAdd  : String;
Begin
  Result := '';
  Repeat
    KeysPair := TSignerUtils.GenerateECKeyPair(TKeyType.SECP256K1);
    HashAdd := GetAddressFromPublicKey(Keyspair.PublicKey);
    if length(HashAdd) >= 20 then
      begin
      pubkey   := Keyspair.PublicKey;
      PrivKey  := KeysPair.PrivateKey;
      Result   := HashAdd;
      IsDone   := true;
      end;
  until IsDone;
End;

{Checks if a string is a valid address hash}
Function IsValidHashAddress(Address:String):boolean;
var
  OrigHash : String;
Begin
  result := false;
  if ((length(address)>20) and (address[1] = 'N')) then
    begin
    OrigHash := Copy(Address,2,length(address)-3);
    if IsValid58(OrigHash) then
      if 'N'+OrigHash+(B10toB58(BMB58resumen(OrigHash))) = Address then
        result := true;
    end
End;

{Returns a transfer hash, base58}
Function GetTransferHash(TextLine:string):String;
var
  Resultado : String = '';
Begin
  Resultado := HashSHA256String(TextLine);
  Resultado := B16toB58(Resultado);
  Result := 'tR'+Resultado+ B10toB58(BMB58resumen(Resultado)) ;
End;

{Returns the Order hash, base36}
function GetOrderHash(TextLine:string):String;
Begin
  Result := HashSHA256String(TextLine);
  Result := 'OR'+B16ToB36(Result);
End;

{Returns the Address certificate for the submitted data}
Function GetCertificate(Pubkey,privkey,currtime:string):string;
var
  Certificate : String;
  Address     : String;
  Signature   : String;
  Checksum    : String;
Begin
  Result      := '';
  TRY
    Address     := GetAddressFromPublicKey(Pubkey);
    Signature   := GetStringSigned('OWN'+Address+currtime,PrivKey);
    Certificate := 'OWN:'+Pubkey+':'+Currtime+':'+signature;
    //ToLog('console','To encode: '+certificate);
    Certificate := UPPERCASE(XorEncode(HashSha256String('noso'),certificate));
    //ToLog('console','Encoded: '+certificate);
    result      :=  B16ToB58('1'+Certificate);
    Checksum    :=  GetCertificateChecksum(Result);
    //ToLog('console','Checksum: '+Checksum);
    Result      := Result+Checksum;
  EXCEPT Exit;
  END; {TRY}
End;

{Verify if a given certificate is valid and returns the address and timestamp}
Function CheckCertificate(certificate:string;out TimeStamp:String):string;
var
  DataArray    : array of string;
  Address      : String;
  CertTime     : String;
  Signature    : String;
  CheckSum     : string;
Begin
  Result      := '';
  TRY
    Checksum    := copy(Certificate,length(certificate)-2,3);
    Certificate := copy(Certificate,1,length(certificate)-3);
    if CheckSum <> GetCertificateChecksum(Certificate) then exit;
    Certificate := B58toB16(certificate);
    Certificate := copy(Certificate,2,length(certificate));
    //ToLog('console','To decode: '+certificate);
    Certificate := XorDecode(HashSha256String('noso'), Certificate);
    //ToLog('console','Decoded: '+certificate);
    DataArray   := SplitString(Certificate,':');
    Address     := GetAddressFromPublicKey(DataArray[1]);
    CertTime    := DataArray[2];
    Signature   := DataArray[3];
    if VerifySignedString('OWN'+Address+CertTime,Signature,DataArray[1]) then
      {Verified certificate}
      begin
      TimeStamp := CertTime;
      Result    := Address;
      end;
  EXCEPT Exit;
  END; {TRY}
End;

{Verify the difference between MD5 hashes}
Function CheckHashDiff(Target,ThisHash:String):string;
var
   counter : integer;
   ValA, ValB, Diference : Integer;
   ResChar : String;
   Resultado : String = '';
Begin
result := 'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF';
if Length(Target) < 32 then SetLength(Target,32);
if Length(ThisHash) < 32 then SetLength(ThisHash,32);
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

{** New base conversion functions **}
Function TrimLeadingCeros(const S: String): String;
Begin
  Result := S.Trim;
  if Result[1] = '0' then
    Result := Result.TrimLeft('0');
End;

function B10ToB16(const sVal: String): String;
var
  S: String;
Begin
  Result := '0';
  S := sVal.Trim;
  if (Length(S) = 0) then
    Exit;
  try
    Result := TConverters.ConvertBytesToHexString(TBigInteger.Create(S).ToByteArrayUnsigned,False);
    Result := TrimLeadingCeros(Result);
  except
    Exit; { convert or Parser Errors }
  end;
End;

Function B10ToB58(const sVal: String): String;
var
  S: String;
Begin
  Result := '1';
  S := sVal.Trim;
  if (Length(S) = 0) then
    Exit;
  Result := TBase58.BitCoin.Encode(TBigInteger.Create(S).ToByteArrayUnsigned);
End;

Function B16ToB10(const sHex: String): String;
var
  bytes: TBytes;
  S: String;
Begin
  Result := '0';
  S := sHex.Trim;
  if (Length(S) = 0) then
    Exit;
  if (Length(S) mod 2) <> 0 then
    S := Concat('0', S);
  try
    bytes := TConverters.ConvertHexStringToBytes(S);
  except
    Exit { invalid HEX input }
  end;
  Result := TBigInteger.Create(1, bytes).ToString;
End;

Function B16ToB36(const sHex: String): String;
const
  baseLength = 36;
var
  bytes: TBytes;
  S: String;
Begin
  Result  := '';
  S := sHex.Trim;
  if not IsValidInput(S) then
    Exit('0');
  if (Length(S) mod 2) <> 0 then
    S := Concat('0', S);
  try
    bytes := TConverters.ConvertHexStringToBytes(S);
  except
    Exit('0') { invalid HEX input }
  end;
  Result := EncodeBaseN(bytes, GetAlphabet(baseLength), baseLength);
End;

Function B16ToB58(const sHex: String): String;
var
  bytes: TBytes;
  S: String;
Begin
  Result := '1';
  S := sHex.Trim;
  if (Length(S) = 0) then
    Exit;
  if (Length(S) mod 2) <> 0 then
    S := Concat('0', S);
  try
    bytes := TConverters.ConvertHexStringToBytes(S);
  except
    Exit { invalid HEX input }
  end;
  Result := TBase58.BitCoin.Encode(TBigInteger.Create(bytes).ToByteArrayUnsigned);
End;

Function B16ToB58Lite1_60(const sHex: String): String;
var
  bytes: TBytes;
  S: String;
Begin
  Result := '1';
  S := sHex.Trim;
  if (Length(S) = 0) then
    Exit;
  if (Length(S) mod 2) <> 0 then
    S := Concat('0', S);
  try
    bytes := TConverters.ConvertHexStringToBytes(S);
  except
    Exit { invalid HEX input }
  end;
  Result := TBase58.BitCoin.Encode(TBigInteger.Create(bytes).ToByteArrayUnsigned);
End;

Function B58ToB10(const sVal: String): String;
var
  bytes: TBytes;
  S: String;
Begin
  Result := '0';
  S := sVal.Trim;
  if (Length(S) = 0) then
    Exit;
  try
    bytes := TBase58.BitCoin.Decode(S);
  except Exit
  end;
  Result := TBigInteger.Create(1, bytes).ToString;
End;

Function B58ToB16(const sVal: String): String;
var
  bytes: TBytes;
  S: String;
Begin
  Result := '0';
  S := sVal.Trim;
  if (Length(S) = 0) then
    Exit;
  try
    bytes := TBase58.BitCoin.Decode(S);
  except Exit
  end;
  Result := TConverters.ConvertBytesToHexString(TBigInteger.Create(1, bytes).ToByteArrayUnsigned,False);
  Result := TrimLeadingCeros(Result);
End;

Function ChecksumBase58(const S: String): integer;
var
  C: Char;
  Total: integer = 0;
Begin
  for C in S do
    Inc(Total, Pos(C, B58Alphabet)-1);
  Result := Total;
End;

Function GetCertificateChecksum(certificate:String):String;
Begin
  Result := BMB58resumenNew(Certificate);
  Result := B10ToB58(Result);
  if Length(Result) < 3 then AddChar('1',Result,3);
End;

// RETURN THE SUMATORY OF A BASE58
Function BMB58resumenNew(numero58:string):string;
var
  counter, total : integer;
Begin
total := 0;
for counter := 1 to length(numero58) do
   begin
   total := total+Pos(numero58[counter],B58Alphabet)-1;
   end;
Total := Total + length(numero58);
result := IntToStr(total);
End;


// RETURN THE SUMATORY OF A BASE58
Function BMB58resumen(numero58:string):string;
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

// RETURN THE SUMATORY OF A BASE58
Function BMB58resumenInt(numero58:string):integer;
var
  counter, total : integer;
Begin
total := 0;
for counter := 1 to length(numero58) do
   begin
   total := total+Pos(numero58[counter],B58Alphabet)-1;
   end;
result := total;
End;

{$REGION Big maths}

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
result := TotalSuma;//ClearLeadingCeros(TotalSuma);
End;

// DIVIDES TWO NUMBERS
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

// Hex to base 58
function BMHexTo58(numerohex:string;alphabetnumber:integer):string;
var
  decimalvalue : string;
  restante : integer;
  ResultadoDiv : DivResult;
  Resultado : string = '';
  AlpahbetUsed : String;
Begin
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

{$ENDREGION BigMaths}

END.{Unit}

