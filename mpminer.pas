unit mpMiner;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, MasterPaskalForm, mpCripto, StrUtils, mpTime, dialogs;

Procedure VerifyMiner();
Procedure ResetMinerInfo();
function GetCharsFromDifficult(texto:string):integer;
function GetStepsFromDifficult(texto:string):integer;
function EjecutarMinero(aParam:Pointer):PtrInt;
Procedure IncreaseHashSeed();
function VerifySolutionForBlock(objetivo:String; pasos: integer; Direccion, Solucion:string):boolean;

implementation

uses
  mpRed, mpParser,mpProtocol, mpGui, mpBlock;

// Verifica la situacion del minero
Procedure VerifyMiner();
Begin
if MyConStatus = 3 then
   begin
   if ((Miner_Active) and (not Miner_IsOn) and (not Miner_BlockFound)) then
      begin
      ConsoleLines.Add(LangLine(39)+IntToStr(Miner_BlockToMine));  //Mining block number:
      Miner_IsOn := true;
      Miner_Thread := Beginthread(tthreadfunc(@EjecutarMinero));
      end;
   end;
if ((Miner_BlockFOund) and (not Miner_SolutionVerified)) then
   begin
   KillThread(Miner_Thread);
   if VerifySolutionForBlock(Miner_Target, Miner_Steps, Miner_Address, Miner_Solution) then
      begin
      consoleLines.Add(LangLine(40)+IntToStr(Miner_BlockToMine));  //Miner solution found and Verified for block
      Miner_SolutionVerified := true;
      OutgoingMsjs.Add(ProtocolLine(6)+UTCTime+' '+IntToStr(Miner_BlockToMine)+' '+
         Miner_Address+' '+StringReplace(Miner_Solution,' ','_',[rfReplaceAll, rfIgnoreCase]));
      end
   else
      begin
      consolelines.Add(LangLine(132)); //'Miner solution invalid?'
      ResetMinerInfo;
      end;
   end;
End;

// Resetea la informacion para uso del minero
Procedure ResetMinerInfo();
Begin
Miner_BlockToMine := LastBlockData.Number+1;
Miner_Difficult := LastBlockData.NxtBlkDiff;
Miner_DifChars := GetCharsFromDifficult(Miner_Difficult);
Miner_Steps := GetStepsFromDifficult(Miner_Difficult);
Miner_Target := copy(MyLastBlockHash,1,Miner_DifChars);
MINER_FoundedSteps := 0;
MINER_HashCounter := 100000000;
MINER_HashSeed := '!!!!!!';
Miner_Address := ListaDirecciones[0].Hash;
Miner_BlockFOund := False;
Miner_Solution := '';
Miner_SolutionVerified := false;
End;

// Obtiene el nivel de dificultad de un bloque
function GetCharsFromDifficult(texto:string):integer;
Begin
result := StrToInt(GetCommand(texto));
End;

// obtiene la cantidad de steps necesarios para el minado de un bloque
function GetStepsFromDifficult(texto:string):integer;
Begin
result := StrToInt(Parameter(texto,1));
End;

// La ejecucion del minero
function EjecutarMinero(aParam:Pointer):PtrInt;
var
  Solucion : string = '';
Begin
while Miner_IsON do
   begin
   Solucion := HashSha256String(MINER_HashSeed+Miner_Address+inttostr(MINER_HashCounter));
   if AnsiContainsStr(Solucion,Miner_Target) then
      begin
      MINER_FoundedSteps := MINER_FoundedSteps+1;
      Miner_Solution := Miner_Solution+MINER_HashSeed+IntToStr(MINER_HashCounter)+' ';
      if Miner_Steps = MINER_FoundedSteps then
         begin
         Miner_BlockFOund := true;
         SetLength(Miner_Solution,length(Miner_Solution)-1);
         Miner_IsON := false;
         end;
      end;
   MINER_HashCounter := MINER_HashCounter+1;
   if MINER_HashCounter > 999999999 then
      begin
      IncreaseHashSeed;
      MINER_HashCounter := 100000000;
      end;
   end;
Result := 0;
End;

// Incrementa paso a paso el seed del minero
Procedure IncreaseHashSeed();
var
  LastChar : integer;
  contador: integer;
Begin
LastChar := Ord(MINER_HashSeed[6])+1;
MINER_HashSeed[6] := chr(LastChar);
for contador := 6 downto 1 do
   begin
   if Ord(MINER_HashSeed[contador])>126 then
      begin
      MINER_HashSeed[contador] := chr(33);
      MINER_HashSeed[contador-1] := chr(Ord(MINER_HashSeed[contador-1])+1);
      end;
   end;
End;

// Verifica una solucion para un bloque
function VerifySolutionForBlock(objetivo:String; pasos: integer; Direccion, Solucion:string):boolean;
var
  ListaSoluciones : TStringList;
  contador : integer = 1;
  HashSolucion : String = '';
Begin
result:= true;
ListaSoluciones := TStringList.Create;
ListaSoluciones.Add(GetCommand(Solucion));
for contador := 1 to pasos-1 do
   ListaSoluciones.Add(Parameter(Solucion,contador));
for contador := 0 to ListaSoluciones.Count-1 do
   Begin
   HashSolucion := HashSha256String(copy(ListaSoluciones[contador],1,6)+Direccion+copy(ListaSoluciones[contador],7,9));
   if not AnsiContainsStr(HashSolucion,objetivo) then
      begin
      result := false;
      consolelines.Add(LangLine(133)+copy(ListaSoluciones[contador],1,6)+  //'Failed block verification step: '
      copy(ListaSoluciones[contador],7,9));
      end;
   end;
ListaSoluciones.Free;
End;


END. // END UNIT

