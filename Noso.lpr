program Noso;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, MasterPaskalForm, mpGUI, mpdisk, mpParser, mpRed, mpProtocol, mpBlock,
  mpCoin, mpsignerutils, mpRPC, translation, indylaz, sysutils, LCLTranslator,
  mpsyscheck, NosoTime, nosodebug, nosogeneral, nosocrypto, nosounit,
  nosoconsensus, nosopsos, nosowallcon, NosoHeaders, NosoNosoCFG, NosoBlock,
  NosoNetwork, NosoClient, nosogvts, nosomasternodes, nosoIPControl;

{$R *.res}

begin
  Application.Scaled:=True;
  Application.Initialize;

  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

