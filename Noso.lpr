program Noso;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}{$IFDEF UseCThreads}
  cthreads,
  {$ENDIF}{$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, indylaz, MasterPaskalForm, mpGUI, mpdisk, mpParser, mpRed, mpTime,
  mpCripto, mpProtocol, mpBlock, mpMiner, mpLang, mpCoin, mpsignerutils,
  PoolMAnage, mpRPC
  { you can add units after this };

{$R *.res}

begin
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

