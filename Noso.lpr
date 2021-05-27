program Noso;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, indylaz, MasterPaskalForm, mpGUI, mpdisk, mpParser, mpRed, mpTime,
  mpCripto, mpProtocol, mpBlock, mpMiner, mpLang, mpCoin, mpsignerutils,
  PoolMAnage, mpRPC;

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;

  Application.CreateForm(TForm1, Form1);
  //Application.CreateForm(TForm2, FormOptions);
  Application.Run;
end.

