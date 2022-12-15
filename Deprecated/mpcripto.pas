unit mpCripto;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, process, strutils, MD5,
  mpsignerutils, base64, HlpHashFactory, mpcoin, nosotime, translation, SbpBase58,SbpBase64,
  SbpBase58Alphabet, ClpConverters, nosodebug, nosogeneral, nosocrypto, HlpConverters,ClpBigInteger;

//function GetTransferHash(TextLine:string):String;
//function GetOrderHash(TextLine:string):String;

//Function EncodeCertificate(certificate:string):string;
//Function DecodeCertificate(certificate:string):string;
//Function NosoHash(source:string):string;
//Function CheckHashDiff(Target,ThisHash:String):string;

Procedure RunNewCryptoTest();

implementation

uses
  mpParser, mpGui, mpProtocol, mpdisk;

// Returns a transfer hash
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
      This58 := B16ToB58(ThisTramo);
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
         //ToDec := BM58Todec(Thistramo);
         //ToHex := BMDecToHex(ToDec);
         ToHex := B58toB16(Thistramo);
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

Procedure RunNewCryptoTest();
var
  counter     : integer;
  starttime   : int64;
  CertExample : string = 'ZMqURv3vWnToqhDaxrQ6Kj0f6V36uNFmyBD3Dwq8WJVUy0mDRKiPZUrTBUD3hDxuJFhZ0j2Z1bBPSYFdw1UVwmPH6yu0nNoRPRGiQ61AuDBXC13rDe0oMbHZhZzDymuGUZPFBYmYK0ZQufcW68GuvLVYT5WoyAhm0ZPzfvcdpiPQje7jcnGtgr10b77W5BwHjjVjWbLR2Vow4T0mdjvUzgHU8PnXnzo8h547Y0a7WLdRbWUZnRtrETr6BGSh0gfrwTFrJ9a7Ef5gSR8G4RJ07ubdH60';
Begin
AddLineToDebugLog('console','Decimal to Hexadecimal');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   BMDecToHex(counter.ToString);
   end;
AddLineToDebugLog('console','  BMDecToHex: '+(GetTickCount64-StartTime).ToString+' ms');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   B10toB16(counter.ToString);
   end;
AddLineToDebugLog('console','  B10toB16: '+(GetTickCount64-StartTime).ToString+' ms');

AddLineToDebugLog('console','Decimal to Base58Bitcoin');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   BMDecTo58(counter.ToString);
   end;
AddLineToDebugLog('console','  BMDecTo58: '+(GetTickCount64-StartTime).ToString+' ms');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   B10toB58(counter.ToString);
   end;
AddLineToDebugLog('console','  B10toB58: '+(GetTickCount64-StartTime).ToString+' ms');

AddLineToDebugLog('console','Hexadecimal to Base58Bitcoin');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   BMHexTo58(counter.ToString,58);
   end;
AddLineToDebugLog('console','  BMHexTo58: '+(GetTickCount64-StartTime).ToString+' ms');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   B16toB58(counter.ToString);
   end;
AddLineToDebugLog('console','  B16toB58: '+(GetTickCount64-StartTime).ToString+' ms');

AddLineToDebugLog('console','Hexadecimal to Decimal');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   BMHexToDec(counter.ToString);
   end;
AddLineToDebugLog('console','  BMHexToDec: '+(GetTickCount64-StartTime).ToString+' ms');
starttime := GetTickCount64;
for counter := 100000000 to 100030000 do
   begin
   B16toB10(counter.ToString);
   end;
AddLineToDebugLog('console','  B16toB10: '+(GetTickCount64-StartTime).ToString+' ms');

AddLineToDebugLog('console','Base58Bitcoin to Decimal');
starttime := GetTickCount64;
for counter := 1 to 30000 do
   begin
   BM58ToDec('abcdeabcde');
   end;
AddLineToDebugLog('console','  BM58ToDec: '+(GetTickCount64-StartTime).ToString+' ms');
starttime := GetTickCount64;
for counter := 1 to 30000 do
   begin
   B58toB10('abcdeabcde');
   end;
AddLineToDebugLog('console','  B58toB10: '+(GetTickCount64-StartTime).ToString+' ms');

AddLineToDebugLog('console','Base58Bitcoin to Hexadecimal');
starttime := GetTickCount64;
for counter := 1 to 30000 do
   begin
   BM58toHex('abcdeabcde');
   end;
AddLineToDebugLog('console','  BM58toHex: '+(GetTickCount64-StartTime).ToString+' ms');
starttime := GetTickCount64;
for counter := 1 to 30000 do
   begin
   B58toB16('abcdeabcde');
   end;
AddLineToDebugLog('console','  B58toB16: '+(GetTickCount64-StartTime).ToString+' ms');

AddLineToDebugLog('console','Certificates');
starttime := GetTickCount64;
for counter := 1 to 1000 do
   begin
   DecodeCertificate(CertExample);
   end;
AddLineToDebugLog('console','  certificates: '+(GetTickCount64-StartTime).ToString+' ms');

End;



END. // END UNIT
