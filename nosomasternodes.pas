unit nosomasternodes;

{$mode ObjFPC}{$H+}

INTERFACE

uses
  Classes, SysUtils,IdTCPClient, IdGlobal,
  NosoDebug,NosoTime,NosoGeneral;

Type

  TThreadMNVerificator = class(TThread)
    private
      FSlot: Integer;
    protected
      procedure Execute; override;
    public
      constructor Create(const CreatePaused: Boolean; const ConexSlot:Integer);
    end;

  TMNode = Packed Record
    Ip           : string[15];
    Port         : integer;
    Sign         : string[40];
    Fund         : string[40];
    First        : integer;
    Last         : integer;
    Total        : integer;
    Validations  : integer;
    Hash         : String[32];
    end;

  Procedure SetLocalIP(NewValue:String);
  Function VerifyThreadsCount:integer;
  function RunMNVerification(CurrSynctus:String;LocalIP:String):String;

var
  MasterNodesFilename : string= 'NOSODATA'+DirectorySeparator+'masternodes.txt';
  MNsListCopy         : array of TMnode;
  CurrSynctus         : string;
  LocalIP             : string = '';
  UnconfirmedIPs      : integer;

  VerifiedNodes       : String;
  CSVerNodes          : TRTLCriticalSection;

  OpenVerificators    : integer;
  CSVerifyThread      : TRTLCriticalSection;

  MNsList             : array of TMnode;
  CSMNsList           : TRTLCriticalSection;

IMPLEMENTATION

Procedure SetLocalIP(NewValue:String);
Begin
  LocalIP := NewValue;
End;

{$REGION ThreadVerificator}

constructor TThreadMNVerificator.Create(const CreatePaused: Boolean; const ConexSlot:Integer);
begin
  inherited Create(CreatePaused);
  FSlot:= ConexSlot;
end;

procedure TThreadMNVerificator.Execute;
var
  TCPClient : TidTCPClient;
  Linea : String = '';
  WasPositive : Boolean;
  IP : string;
  Port: integer;
  Success : boolean ;
  Trys :integer = 0;
Begin
  AddNewOpenThread('VerifyMN '+FSlot.ToString,UTCTime);
  Sleep(1000);
  TRY {BIG}
    IP := MNsListCopy[FSlot].Ip;
    Port := MNsListCopy[FSlot].Port;
    TCPClient := TidTCPClient.Create(nil);
    TCPclient.Host:=Ip;
    TCPclient.Port:=Port;
    TCPclient.ConnectTimeout:= 1000;
    TCPclient.ReadTimeout:= 1000;
    REPEAT
      Inc(Trys);
      TRY
        TCPclient.Connect;
        TCPclient.IOHandler.WriteLn('MNVER');
        Linea := TCPclient.IOHandler.ReadLn(IndyTextEncoding_UTF8);
        TCPclient.Disconnect();
        Success := true;
      EXCEPT on E:Exception do
        begin
        Success := false;
        end;
      END{try};
    UNTIL ((Success) or (trys = 3));
    TCPClient.Free;
    if success then
      begin
      WasPositive := StrToBoolDef(Parameter(Linea,0),false);
      if ( (WasPositive) and (Parameter(Linea,1)=CurrSynctus) ) then
        begin
        EnterCriticalSection(CSVerNodes);
        VerifiedNodes := VerifiedNodes+Ip+';'+Port.ToString+':';
        LeaveCriticalSection(CSVerNodes);
        end
      else if ( (WasPositive) and (Parameter(Linea,1)<>CurrSynctus) ) then
        begin
        // Wrong synctus returned
        end
      else
        begin
        // Was not possitive
        end;
      end;
    If Parameter(Linea,3) <> LocalIP then Inc(UnconfirmedIPs);
  EXCEPT on E:Exception do
    begin
    ToLog('exceps',FormatDateTime('dd mm YYYY HH:MM:SS.zzz', Now)+' -> '+'CRITICAL MNs VERIFICATION ('+Ip+'): '+E.Message);
    end;
  END{BIG TRY};
  EnterCriticalSection(CSVerifyThread);
  Dec(OpenVerificators);
  LeaveCriticalSection(CSVerifyThread);
  CloseOpenThread('VerifyMN '+FSlot.ToString);
End;

Function VerifyThreadsCount:integer;
Begin
  EnterCriticalSection(CSVerifyThread);
  Result := OpenVerificators;
  LeaveCriticalSection(CSVerifyThread);
End;

{$ENDREGION ThreadVerificator}

function RunMNVerification(CurrSynctus:String;LocalIP:String):String;
var
  counter : integer;
  ThisThread : TThreadMNVerificator;
  Launched : integer = 0;
  WaitCycles : integer = 0;
  DataLine : String;
Begin
  Result := '';
  SetLocalIP(LocalIP);
  VerifiedNodes := '';
  setlength(MNsListCopy,0);
  EnterCriticalSection(CSMNsList);
  MNsListCopy := copy(MNsList,0,length(MNsList));
  LeaveCriticalSection(CSMNsList);
  UnconfirmedIPs := 0;
  for counter := 0 to length(MNsListCopy)-1 do
    begin
    if (( MNsListCopy[counter].ip <> LocalIP) and (IsValidIp(MNsListCopy[counter].ip)) ) then
      begin
      Inc(Launched);
      ThisThread := TThreadMNVerificator.Create(true,counter);
      ThisThread.FreeOnTerminate:=true;
      ThisThread.Start;
      end;
    end;
  EnterCriticalSection(CSVerifyThread);
  OpenVerificators := Launched;
  LeaveCriticalSection(CSVerifyThread);
  Repeat
    sleep(100);
    Inc(WaitCycles);
  until ( (VerifyThreadsCount= 0) or (WaitCycles = 150) );
  ToDeepDeb(Format('MNs verification finish: %d launched, %d Open, %d cycles',[Launched,VerifyThreadsCount,WaitCycles ]));
  ToDeepDeb(Format('Unconfirmed IPs: %d',[UnconfirmedIPs ]));
  if VerifyThreadsCount>0 then
    begin
    EnterCriticalSection(CSVerifyThread);
    OpenVerificators := 0;
    LeaveCriticalSection(CSVerifyThread);
    end;
  DataLine := LocalIP+' '+MyLastBlock.ToString+' '+MN_Sign+' '+GetWallArrIndex(WallAddIndex(MN_Sign)).PublicKey+' '+
            VerifiedNodes+' '+GetStringSigned(VerifiedNodes,GetWallArrIndex(WallAddIndex(MN_Sign)).PrivateKey);
  OutGoingMsjsAdd(ProtocolLine(MNCheck)+DataLine);
  Result := Launched.ToString+':'+VerifiedNodes
End;

INITIALIZATION
SetLength(MNsListCopy,0);
SetLength(MNsList,0);
InitCriticalSection(CSMNsList);
InitCriticalSection(CSVerNodes);
InitCriticalSection(CSVerifyThread);

FINALIZATION
DoneCriticalSection(CSMNsList);
DoneCriticalSection(CSVerNodes);
DoneCriticalSection(CSVerifyThread);


END. // End unit

