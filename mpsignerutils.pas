//
//  Thanks to Xor-el for this library!
//

unit mpSignerUtils;

{$IFDEF FPC}
{$MODE DELPHI}
{$ENDIF FPC}

interface

uses
  Base64,
  TypInfo,
  SysUtils,
  ClpISigner,
  ClpBigInteger,
  ClpISecureRandom,
  ClpSecureRandom,
  ClpSignerUtilities,
  ClpIX9ECParameters,
  ClpIECPublicKeyParameters,
  ClpIECPrivateKeyParameters,
  ClpIAsymmetricCipherKeyPair,
  ClpGeneratorUtilities,
  ClpCustomNamedCurves,
  ClpECPrivateKeyParameters,
  ClpECPublicKeyParameters,
  ClpIECDomainParameters,
  ClpECDomainParameters,
  ClpECKeyGenerationParameters,
  ClpIECKeyGenerationParameters,
  ClpIAsymmetricCipherKeyPairGenerator;

type
  TKeyPair = record
    PublicKey: string;
    PrivateKey: string;
  end;

type
{$SCOPEDENUMS ON}
  TKeyType = (SECP256K1, SECP384R1, SECP521R1, SECT283K1);
{$SCOPEDENUMS OFF}

type
  TSignerUtils = class sealed(TObject)

  strict private

  const

    SigningAlgorithm = 'SHA-1withECDSA';

    class var FSecureRandom: ISecureRandom;

    class function GetCurveFromKeyType(AKeyType: TKeyType): IX9ECParameters;
      static; inline;

    class function GetSecureRandom: ISecureRandom; static; inline;
    class property SecureRandom: ISecureRandom read GetSecureRandom;
  private
    class function GetSigner(): ISigner; static;
    class function GetCurve(keyType: TKeyType): IX9ECParameters; static;
    class function GetDomain(curve: IX9ECParameters)
      : IECDomainParameters; static;
  public
    class function GenerateECKeyPair(AKeyType: TKeyType): TKeyPair; static;

    class function SignMessage(const &message: TBytes; const PrivateKey: TBytes;
      AKeyType: TKeyType): TBytes; static;

    class function VerifySignature(const signature: TBytes;
      const &message: TBytes; const PublicKey: TBytes; AKeyType: TKeyType)
      : Boolean; static;
  end;

  function ByteToString(const Value: TBytes): String;
  function StrToByte(const Value: String): TBytes;

implementation

class function TSignerUtils.GetCurveFromKeyType(AKeyType: TKeyType)
  : IX9ECParameters;
var
  CurveName: string;
begin
  CurveName := GetEnumName(TypeInfo(TKeyType), Ord(AKeyType));
  Result := TCustomNamedCurves.GetByName(CurveName);
end;

class function TSignerUtils.GetCurve(keyType: TKeyType): IX9ECParameters;
begin
  Result := GetCurveFromKeyType(keyType);
end;

class function TSignerUtils.GetDomain(curve: IX9ECParameters)
  : IECDomainParameters;
begin
  Result := TECDomainParameters.Create(curve.curve, curve.G, curve.N, curve.H,
    curve.GetSeed);
end;

class function TSignerUtils.GetSecureRandom: ISecureRandom;
begin
  if FSecureRandom <> Nil then
  begin
    Result := FSecureRandom
  end
  else
  begin
    FSecureRandom := TSecureRandom.Create();
    Result := FSecureRandom;
  end;
end;

class function TSignerUtils.GetSigner(): ISigner;
begin
  Result := TSignerUtilities.GetSigner(SigningAlgorithm);
end;

class function TSignerUtils.SignMessage(const message: TBytes;
  const PrivateKey: TBytes; AKeyType: TKeyType): TBytes;
var
  LSigner: ISigner;
  LRecreatedPrivKey: IECPrivateKeyParameters;
  LCurve: IX9ECParameters;
  domain: IECDomainParameters;
begin
  LCurve := GetCurve(AKeyType);
  domain := GetDomain(LCurve);
  LRecreatedPrivKey := TECPrivateKeyParameters.Create('ECDSA',
    TBigInteger.Create(1, PrivateKey), domain);
  LSigner := GetSigner();
  LSigner.Init(True, LRecreatedPrivKey);
  LSigner.BlockUpdate(&message, 0, System.Length(&message));
  Result := LSigner.GenerateSignature();
end;

class function TSignerUtils.VerifySignature(const signature: TBytes;
  const &message: TBytes; const PublicKey: TBytes; AKeyType: TKeyType): Boolean;
var
  LSigner: ISigner;
  LRecreatedPubKey: IECPublicKeyParameters;
  LCurve: IX9ECParameters;
  domain: IECDomainParameters;
begin
  LCurve := GetCurve(AKeyType);
  domain := GetDomain(LCurve);
  LRecreatedPubKey := TECPublicKeyParameters.Create('ECDSA',
    LCurve.curve.DecodePoint(PublicKey), domain);
  LSigner := GetSigner();
  LSigner.Init(False, LRecreatedPubKey);
  LSigner.BlockUpdate(&message, 0, System.Length(&message));
  Result := LSigner.VerifySignature(signature);
end;

class function TSignerUtils.GenerateECKeyPair(AKeyType: TKeyType): TKeyPair;
var
  LCurve: IX9ECParameters;
  domain: IECDomainParameters;
  KeyPairGeneratorInstance: IAsymmetricCipherKeyPairGenerator;
  askp: IAsymmetricCipherKeyPair;
  Publickey : TBytes;
  PrivateKey : TBytes;
begin
  LCurve := GetCurve(AKeyType);
  domain := GetDomain(LCurve);
  KeyPairGeneratorInstance := TGeneratorUtilities.GetKeyPairGenerator('ECDSA');
  KeyPairGeneratorInstance.Init(TECKeyGenerationParameters.Create(domain,
    SecureRandom) as IECKeyGenerationParameters);
  askp := KeyPairGeneratorInstance.GenerateKeyPair();
  Publickey:= (askp.Public as IECPublicKeyParameters).Q.GetEncoded();
  Result.PublicKey := EncodeStringBase64(ByteToString(PublicKey));
  PrivateKey := (askp.Private as IECPrivateKeyParameters).D.ToByteArrayUnsigned;
  Result.PrivateKey := EncodeStringBase64(ByteToString(PrivateKey));
end;

function ByteToString(const Value: TBytes): String;
var
  I: integer;
  S : String;
  Letra: char;
begin
S := '';
for I := Length(Value)-1 Downto 0 do
   begin
   letra := Chr(Value[I]);
   S := letra + S;
   end;
Result := S;
end;

function StrToByte(const Value: String): TBytes;
var
  I: integer;
begin
SetLength(Result, Length(Value));
   for I := 0 to Length(Value) - 1 do
      Result[I] := ord(Value[I + 1]);
end;

end.
