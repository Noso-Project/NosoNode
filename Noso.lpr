program Noso;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, MasterPaskalForm, mpGUI, mpdisk, mpParser, mpRed, mpTime, mpCripto,
  mpProtocol, mpBlock, mpMiner, mpLang, mpCoin, mpsignerutils, PoolMAnage,
  mpRPC, translation, indylaz, sysutils, LCLTranslator, mpmn;

{$R *.res}
var
  language : string = '';
  FolderCreated : boolean = false;

begin

  if not directoryexists('locale'+DirectorySeparator) then
     begin
     CreateDir('locale'+DirectorySeparator);
     FolderCreated := true;
     end;
  //language := GetLanguage;
  if ((WO_LastPoUpdate<>Programversion+SubVersion) or (FolderCreated)) then ExtractPoFiles;
  WO_LastPoUpdate := Programversion+SubVersion;
  SetDefaultLang(language);
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Initialize;

  Application.CreateForm(TForm1, Form1);
  Application.Run;
end.

