unit NosoNosoCFG;

{
NosoNosoCFG 1.1
Febraury 1, 2024
Stand alone unit to control nosocfg file and functionalitys
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, nosodebug, nosogeneral;

Function SaveCFGToFile(Content:String):Boolean;
Procedure GetCFGFromFile();
Procedure SetCFGDataStr(Content:String);
Function GetCFGDataStr(LParam:integer=-1):String;

var
  CFGFilename     : string= 'NOSODATA'+DirectorySeparator+'nosocfg.psk';
  CFGFile         : Textfile;
  CS_CFGFile      : TRTLCriticalSection;
  CS_CFGData      : TRTLCriticalSection;
  NosoCFGString   : string = '';
  DefaultNosoCFG  : String = // CFG parameters
                            {0 Mainnet mode}'NORMAL '+
                            {1 Seed nodes  }'63.227.69.162;8080:20.199.50.27;8080:107.172.21.121;8080:107.172.214.53;8080:198.23.134.105;8080:107.173.210.55;8080:5.230.55.203;8080:141.11.192.215;8080:4.233.61.8;8080: '+
                            {2 NTP servers }'ts2.aco.net:hora.roa.es:time.esa.int:time.stdtime.gov.tw:stratum-1.sjc02.svwh.net:ntp1.sp.se:1.de.pool.ntp.org:ntps1.pads.ufrj.br:utcnist2.colorado.edu:tick.usask.ca:ntp1.st.keio.ac.jp: '+
                            {3 DEPRECATED  }'null: '+
                            {4 DEPRECATED  }'null: '+
                            {5 FREZZED     }'NpryectdevepmentfundsGE:';


IMPLEMENTATION

{$REGION File access}

Function SaveCFGToFile(Content:String):Boolean;
Begin
  EnterCriticalSection(CS_CFGFile);
  Result := SaveTextToDisk(CFGFilename,Content);
  SetCFGDataStr(Content);
  LeaveCriticalSection(CS_CFGFile);
End;

Procedure GetCFGFromFile();
Begin
  EnterCriticalSection(CS_CFGFile);
  SetCFGDataStr(LoadTextFromDisk(CFGFilename));
  LeaveCriticalSection(CS_CFGFile);
End;

{$ENDREGION}

{$REGION Data access}

Procedure SetCFGDataStr(Content:String);
Begin
  EnterCriticalSection(CS_CFGData);
  NosoCFGString := Content;
  LeaveCriticalSection(CS_CFGData);
End;

Function GetCFGDataStr(LParam:integer=-1):String;
Begin
  EnterCriticalSection(CS_CFGData);
  if LParam<0 then Result := NosoCFGString
  else Result := Parameter(NosoCFGString,LParam);
  LeaveCriticalSection(CS_CFGData);
End;

{$ENDREGION}

INITIALIZATION
InitCriticalSection(CS_CFGFile);
InitCriticalSection(CS_CFGData);

FINALIZATION
DoneCriticalSection(CS_CFGFile);
DoneCriticalSection(CS_CFGData);

END.

