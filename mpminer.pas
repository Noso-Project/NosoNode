unit mpMiner;

{$mode objfpc}{$H+}

interface

uses
  Classes,SysUtils, MasterPaskalForm, mpCripto, StrUtils, dialogs, NosoTime;

Procedure VerifyMiner();
Procedure KillAllMiningThreads();
Procedure ResetMinerInfo();
function GetCharsFromDifficult(Dificult,step:integer):integer;
function EjecutarMinero(aParam:Pointer):PtrInt;
function IsValidStep(solucion,step:string):boolean;
Procedure IncreaseHashSeed();
Function IsValidASCII(TextLine:String):boolean;
function VerifySolutionForBlock(Dificultad:integer; objetivo,Direccion, Solucion:string):integer;
function TruncateBlockSolution(solucion:string;step:integer):string;

implementation

uses
  mpRed, mpParser,mpProtocol, mpGui, mpBlock, mpdisk;

// Verifica la situacion del minero
Procedure VerifyMiner();
var
  blocktime : string;
Begin
if MyConStatus = 3 then
   begin
   if ((Miner_Active) and (not Miner_IsOn) and (not Miner_BlockFound)) then
      begin
      ConsoleLinesAdd(LangLine(39)+IntToStr(Miner_BlockToMine));  //Mining block number:
      Miner_IsOn := true;
      while Length(Miner_Thread) < G_MiningCPUs do
        begin
        SetLength(Miner_Thread,Length(Miner_Thread)+1);
        Miner_Thread[Length(Miner_Thread)-1] := Beginthread(tthreadfunc(@EjecutarMinero));
        end;
      end;
   end;
if ((Miner_BlockFOund) and (not Miner_SolutionVerified)) then
   begin
   KillAllMiningThreads;
   if VerifySolutionForBlock(Miner_Difficult, Miner_Target, Miner_Address, Miner_Solution)=0 then
      begin
      if not UserOptions.UsePool then
         begin
         blocktime := UTCTimeStr;
         ConsoleLinesAdd(LangLine(40)+IntToStr(Miner_BlockToMine));  //Miner solution found and Verified for block
         Miner_SolutionVerified := true;
         OutgoingMsjsAdd(ProtocolLine(6)+blocktime+' '+IntToStr(Miner_BlockToMine)+' '+
         Miner_Address+' '+StringReplace(Miner_Solution,' ','_',[rfReplaceAll, rfIgnoreCase]));
         Miner_Waiting := StrToInt64(UTCTimeStr);
         //SendNetworkRequests(blocktime,Miner_Address,Miner_BlockToMine);
         end
      else ResetMinerInfo;
      end
   else
      begin
      ConsoleLinesAdd(LangLine(132)); //'Miner solution invalid?'
      ResetMinerInfo;
      end;
   end;
If ((Miner_Waiting>-1) and (Miner_Waiting+10<StrToInt64(UTCTimeStr))) then
   ResetMinerInfo();
End;

Procedure KillAllMiningThreads();
Var
  Counter : integer;
Begin
for counter := 0 to Length(Miner_Thread)-1 do
   begin
      Try
      KillThread(Miner_Thread[counter]);
      except on E:Exception do
         begin
         // do nothing
         end;
      end;
   end;
Miner_KillThreads := true;
sleep(200);
Miner_KillThreads := false;
SetLength(Miner_Thread,0);
End;

// Resetea la informacion para uso del minero
Procedure ResetMinerInfo();
Begin
   TRY
   Miner_Waiting := -1;
   Miner_BlockToMine := LastBlockData.Number+1;
   Miner_Difficult := LastBlockData.NxtBlkDiff;
   MINER_FoundedSteps := 0;
   Miner_DifChars := GetCharsFromDifficult(Miner_Difficult, MINER_FoundedSteps);
   Miner_Target := copy(MyLastBlockHash,1,Miner_DifChars);
   MINER_HashCounter := 100000000;
   if UserOptions.UsePool then MINER_HashSeed := MyPoolData.Prefijo
   else MINER_HashSeed := '!!!!!!!!!';
   if UserOptions.UsePool then Miner_Address := MyPoolData.Direccion
   else Miner_Address := ListaDirecciones[0].Hash;
   Miner_BlockFOund := False;
   Miner_Solution := '';
   Miner_SolutionVerified := false;
   Miner_PoolHashRate := 0;
   EXCEPT ON E:Exception do
      ToExcLog('Error reseting miner info');
   END;{TRY}
End;

// Obtiene el nivel de dificultad de un bloque
function GetCharsFromDifficult(Dificult,step:integer):integer;
Begin
result := Dificult div 10;
if (Dificult mod 10) > step then result := result + 1;
End;

// La ejecucion del minero
function EjecutarMinero(aParam:Pointer):PtrInt;
var
  Solucion : string = '';
  MSeed : string; Mnumber : int64;
Begin
while ( (Miner_IsON) and (not Miner_KillThreads) ) do
   begin
   Miner_LastHashRate := Miner_EsteIntervalo*5 div 1000;
   Mseed := MINER_HashSeed;Mnumber := MINER_HashCounter;
   Solucion := HashSha256String(Mseed+Miner_Address+inttostr(Mnumber));
   if ( (AnsiContainsStr(Solucion,copy(Miner_Target,1,Miner_DifChars))) and
      (IsValidStep(Miner_Solution,Mseed+IntToStr(Mnumber))) ) then
      begin
      if UserOptions.UsePool then ProcessLinesAdd('SENDPOOLSOLUTION '+IntToStr(Miner_BlockToMine)+' '+Mseed+' '+IntToStr(Mnumber));
      MINER_FoundedSteps := MINER_FoundedSteps+1;
      Miner_DifChars := GetCharsFromDifficult(Miner_Difficult, MINER_FoundedSteps);
      Miner_Solution := Miner_Solution+Mseed+IntToStr(Mnumber)+' ';
      if Miner_Steps = MINER_FoundedSteps then
         begin
         Miner_BlockFOund := true;
         SetLength(Miner_Solution,length(Miner_Solution)-1);
         Miner_IsON := false;
         end;
      end;
   MINER_HashCounter:=MINER_HashCounter+1;
   if MINER_HashCounter > 999999999 then
      begin
      IncreaseHashSeed;
      MINER_HashCounter := 100000000;
      end;
   end;
Result := 1;
try
if length(Miner_Thread)>0 then Setlength(Miner_Thread,length(Miner_Thread)-1);
Except on E:Exception do
   begin
   ConsoleLinesAdd ('Error deleting minning threads');
   end;
end;
End;

// Indica si un step ya ha sido añadido a la solucion
function IsValidStep(solucion,step:string):boolean;
var
  counter : integer;
Begin
result := true;
for counter := 1 to length(solucion) do
   if ((Ord(solucion[counter])>126) or (Ord(solucion[counter])<32)) then result := false;
if AnsiContainsStr(solucion,step) then result := false;
End;

// Incrementa paso a paso el seed del minero
Procedure IncreaseHashSeed();
var
  LastChar : integer;
  contador: integer;
Begin
LastChar := Ord(MINER_HashSeed[9])+1;
MINER_HashSeed[9] := chr(LastChar);
for contador := 9 downto 1 do
   begin
   if Ord(MINER_HashSeed[contador])>126 then
      begin
      MINER_HashSeed[contador] := chr(33);
      MINER_HashSeed[contador-1] := chr(Ord(MINER_HashSeed[contador-1])+1);
      end;
   end;
End;

Function IsValidASCII(TextLine:String):boolean;
var
  counter : integer;
Begin
setmilitime('IsValidASCII',1);
result := true;
for counter := 1 to length(TextLine) do
   if ((Ord(TextLine[counter])>126) or (Ord(TextLine[counter])<32)) then
      begin
      result := false;
      break;
      end;
setmilitime('IsValidASCII',2);
End;

// Verifica una solucion para un bloque
function VerifySolutionForBlock(Dificultad:integer; objetivo,Direccion, Solucion:string):integer;
var
  ListaSoluciones : TStringList;
  contador : integer = 1;
  HashSolucion : String = '';
  AllSolutions : String = '';
Begin
result:= 0;
ListaSoluciones := TStringList.Create;
ListaSoluciones.Add(GetCommand(Solucion));
AllSolutions := AllSolutions+GetCommand(Solucion);
for contador := 1 to Miner_Steps-1 do
   begin
   ListaSoluciones.Add(Parameter(Solucion,contador));
   AllSolutions := AllSolutions+Parameter(Solucion,contador);
   end;
for contador := 0 to ListaSoluciones.Count-1 do
   Begin
   if not IsValidASCII(ListaSoluciones[contador]) then
      begin
      OutText('Not valid ASCII chars on step: '+IntToStr(contador+1)+': '+ListaSoluciones[contador]);
      result := contador+1;
      break;
      end;
   AllSolutions := StringReplace(AllSolutions,ListaSoluciones[contador],'',[]);
   if AnsiContainsStr(AllSolutions,ListaSoluciones[contador]) then
      begin
      OutText('Duplicated solution for block step '+IntToStr(contador+1)+': '+ListaSoluciones[contador]);
      result := contador+1;
      break;
      end;
   objetivo := copy(objetivo,1,GetCharsFromDifficult(dificultad,contador));
   HashSolucion := HashSha256String(copy(ListaSoluciones[contador],1,9)+Direccion+copy(ListaSoluciones[contador],10,9));
   if not AnsiContainsStr(HashSolucion,objetivo) then
      begin
      result := contador+1;
      ConsoleLinesAdd(LangLine(133)+IntToStr(contador)+' '+copy(ListaSoluciones[contador],1,9)+  //'Failed block verification step: '
      Direccion+copy(ListaSoluciones[contador],10,9)+' not '+objetivo);
      break;
      end;
   end;
ListaSoluciones.Free;
End;

// Trunca la solucion de un bloque asumiendo que el step dado es el incorrecto
function TruncateBlockSolution(solucion:string;step:integer):string;
var
  caracteres : integer;
Begin
caracteres := 19*(step-1);
result := copy(solucion,1,caracteres);
End;

END. // END UNIT

