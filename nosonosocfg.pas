unit NosoNosoCFG;

{
NosoNosoCFG 1.0
Dec 14, 2023
Stand alone unit to control nosocfg file and functionalitys
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, nosodebug, nosogeneral;

Function CreateCFGFile():Boolean;
Function SaveCFGToFile(Content:String):Boolean;
Procedure GetCFGFromFile();
Procedure SetCFGData(Content:String);
Function GetCFGData(LParam:integer=-1):String;

var
  CFGFilename     : string= 'NOSODATA'+DirectorySeparator+'nosocfg.psk';
  CFGFile         : Textfile;
  CS_CFGFile      : TRTLCriticalSection;
  CS_CFGData      : TRTLCriticalSection;
  NosoCFGString   : string = '';


IMPLEMENTATION

Function CreateCFGFile():Boolean;
Begin

End;

Function SaveCFGToFile(Content:String):Boolean;
Begin
  EnterCriticalSection(CS_CFGFile);
  Result := SaveTextToDisk(CFGFilename,Content);
  LeaveCriticalSection(CS_CFGFile);
End;

Procedure GetCFGFromFile();
Begin
  EnterCriticalSection(CS_CFGFile);
  SetCFGData(LoadTextFromDisk(CFGFilename));
  LeaveCriticalSection(CS_CFGFile);
End;

Procedure SetCFGData(Content:String);
Begin
  EnterCriticalSection(CS_CFGData);
  NosoCFGString := Content;
  LeaveCriticalSection(CS_CFGData);
End;

Function GetCFGData(LParam:integer=-1):String;
Begin
  EnterCriticalSection(CS_CFGData);
  if LParam<0 then Result := NosoCFGString
  else Result := Parameter(NosoCFGString,LParam);
  LeaveCriticalSection(CS_CFGData);
End;

INITIALIZATION
InitCriticalSection(CS_CFGFile);
InitCriticalSection(CS_CFGData);

FINALIZATION
DoneCriticalSection(CS_CFGFile);
DoneCriticalSection(CS_CFGData);

END.

