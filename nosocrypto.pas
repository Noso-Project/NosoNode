UNIT nosocrypto;

{
Unit nosocrypto 1.2
December 18th, 2022
Noso Unit for crypto functions
Requires: cryptohashlib , mpsignerutils
}

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils, strutils,
  HlpHashFactory, md5,
  ClpConverters,ClpBigInteger,SbpBase58,
  mpsignerutils, base64;

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
Function GenerateNewAddress(out pubkey:String;out privkey:String):String;
Function IsValidHashAddress(Address:String):boolean;
Function GetTransferHash(TextLine:string):String;
function GetOrderHash(TextLine:string):String;
Function GetCertificate(Pubkey,privkey,currtime:string):string;
Function CheckCertificate(certificate:string;out TimeStamp:String):string;
Function CheckHashDiff(Target,ThisHash:String):string;
Function NosoHash(source:string):string;

{New base conversion functions}
function B10ToB16(const sVal: String): String;
Function B10ToB58(const sVal: String): String;
Function B16ToB10(const sHex: String): String;
Function B16ToB36(const sHex: String): String;
Function B16ToB58(const sHex: String): String;
Function B58ToB10(const sVal: String): String;
Function B58ToB16(const sVal: String): String;
Function ChecksumBase58(const S: String): string;
Function BMB58resumen(numero58:string):string;

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

{Returns the hash address from the provided publickey}
function GetAddressFromPublicKey(PubKey:String):String;
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

{Generates a new keys pair and returns the hash}
Function GenerateNewAddress(out pubkey:String;out privkey:String):String;
var
  KeysPair: TKeyPair;
Begin
  KeysPair := TSignerUtils.GenerateECKeyPair(TKeyType.SECP256K1);
  pubkey   := Keyspair.PublicKey;
  PrivKey  := KeysPair.PrivateKey;
  Result   := GetAddressFromPublicKey(pubkey);
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
       This58 := B16ToB58(ThisTramo);
       Result := Result+This58+'0';
       end;
   End;

Begin
  Result      := '';
  TRY
    Address     := GetAddressFromPublicKey(Pubkey);
    Signature   := GetStringSigned('I OWN THIS ADDRESS '+Address+currtime,PrivKey);
    Certificate := Pubkey+':'+Currtime+':'+signature;
    Certificate := UPPERCASE(XorEncode(HashSha256String('noso'),certificate));
    result      := SplitCertificate(certificate);
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

   Function UnSplitCertificate(TextData:String):String;
   var
     counter   :integer;
     TrunkStr  :string = '';
   Begin
     result := '';
     for counter := 1 to length(TextData) do
       begin
       if TextData[counter]<>'0' then TrunkStr := TrunkStr+TextData[counter]
       else
         begin
         TrunkStr := B58toB16(TrunkStr);
         Delete(TrunkStr,1,1);
         Result := result+TrunkStr;
         TrunkStr := '';
         end;
       end;
   End;

Begin
  Result      := '';
  TRY
    Certificate := UnSplitCertificate(certificate);
    Certificate := XorDecode(HashSha256String('noso'), Certificate);
    DataArray   := SplitString(Certificate,':');
    Address     := GetAddressFromPublicKey(DataArray[0]);
    CertTime    := DataArray[1];
    Signature   := DataArray[2];
    if VerifySignedString('I OWN THIS ADDRESS '+Address+CertTime,Signature,DataArray[0]) then
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

{Returns the nosohash of the specified address}
Function NosoHash(source:string):string;
var
  counter : integer;
  FirstChange : array[1..128] of string;
  finalHASH : string;
  ThisSum : integer;
  charA,charB,charC,charD:integer;
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

Function ChecksumBase58(const S: String): string;
var
  C: Char;
  Total: integer = 0;
Begin
  for C in S do
    Inc(Total, Pos(C, B58Alphabet)-1);
  Result := IntToStr(Total);
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

END.{Unit}

