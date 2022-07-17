unit mpSysCheck;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, mpcripto, mpdisk;

Type
  TThreadHashtest = class(TThread)
    protected
      procedure Execute; override;
    public
      Constructor Create(CreateSuspended : boolean);
    end;

Function Sys_HashSpeed(cores:integer=4):int64;
Function AllocateMem():int64;

var
  OpenHashThreads : integer;

implementation

constructor TThreadHashtest.Create(CreateSuspended : boolean);
Begin
  inherited Create(CreateSuspended);
End;

procedure TThreadHashtest.Execute;
var
  counter : integer;
Begin
for counter := 1 to 10000 do
   HashSha256String(IntToStr(counter));
Dec(OpenHashThreads);
End;

Function Sys_HashSpeed(cores:integer=4):int64;
var
  counter    : integer;
  StartTime, EndTime : int64;
  ThisThread : TThreadHashtest;
Begin
OpenHashThreads := cores;
for counter := 1 to cores do
   begin
   ThisThread := TThreadHashtest.Create(true);
   ThisThread.FreeOnTerminate:=true;
   ThisThread.Start;
   end;
StartTime := GetTickCount64;
Repeat
   sleep(1);
until OpenHashThreads=0;
EndTime := GetTickCount64;
Result := (cores*10000) div (EndTime-StartTime);
End;

Function AllocateMem():int64;
var
  counter  : integer;
  MemMb    : array of pointer;
  Finished : boolean = false;
Begin
result := 0;
counter := 0;
SetLength(MemMb,0);
repeat
   SetLength(MemMb,length(MemMb)+1);
      TRY
      GetMem(MemMb[counter],1048576);
      FillChar (MemMb[counter]^,1048576,' ');
      EXCEPT ON E:Exception do
         begin
         finished := true;
         ToLog(E.Message);
         end;
      END;
   inc(counter);
until ( (finished) or (counter >=2048));
result := counter;
{
for counter := 0 to length(MemMB)-1 do
   FreeMem (MemMb[counter],1048576);
}

End;

END. // END UNIT

