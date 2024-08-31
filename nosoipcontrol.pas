unit NosoIPControl;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, nosotime;

type
  IPControl = record
    IP : String;
    Count : integer;
  end;

Function AddIPControl(ThisIP:String):integer;
Procedure ClearIPControls();

var
  ArrCont      : Array of IPControl;
  CS_ArrCont   : TRTLCriticalSection;
  LastIPsClear : int64 = 0;

IMPLEMENTATION

Function AddIPControl(ThisIP:String):integer;
var
  counter : integer;
  Added : boolean = false;
Begin
  EnterCriticalSection(CS_ArrCont);
  For counter := 0 to length(ArrCont)-1 do
    begin
    if ArrCont[Counter].IP = ThisIP then
      begin
      Inc(ArrCont[Counter].count);
      Result := ArrCont[Counter].count;
      Added := true;
      Break
      end;
    end;
  if not added then
    begin
    Setlength(ArrCont,length(ArrCont)+1);
    ArrCont[length(ArrCont)-1].IP := thisIP;
    ArrCont[length(ArrCont)-1].count := 1;
    Result := 1;
    end;
  LeaveCriticalSection(CS_ArrCont);
End;

Procedure ClearIPControls();
Begin
  EnterCriticalSection(CS_ArrCont);
  Setlength(ArrCont,0);
  LeaveCriticalSection(CS_ArrCont);
  LAstIPsClear := UTCTime;
End;

INITIALIZATION
  SetLength(ArrCont,0);
  InitCriticalSection(CS_ArrCont);

FINALIZATION
  DoneCriticalSection(CS_ArrCont);

END.

