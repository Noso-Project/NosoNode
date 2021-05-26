unit mpoptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ExtCtrls, Spin;

type

  { TForm2 }

  TForm2 = class(TForm)
    Button1: TButton;
    ButtonCancel: TButton;
    ButtonSave: TButton;
    CB_WO_AutoConnect: TCheckBox;
    CB_WO_ToTray: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    CheckBox9: TCheckBox;
    Edit1: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    LabeledEdit10: TLabeledEdit;
    LabeledEdit11: TLabeledEdit;
    LabeledEdit12: TLabeledEdit;
    LabeledEdit13: TLabeledEdit;
    LabeledEdit14: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    LabeledEdit4: TLabeledEdit;
    LabeledEdit5: TLabeledEdit;
    LabeledEdit6: TLabeledEdit;
    LabeledEdit7: TLabeledEdit;
    LabeledEdit8: TLabeledEdit;
    LabeledEdit9: TLabeledEdit;
    Memo1: TMemo;
    Memo2: TMemo;
    PageControl1: TPageControl;
    Panel1: TPanel;
    SE_WO_MinPeers: TSpinEdit;
    StaticText1: TStaticText;
    TabSheet1: TTabSheet;
    TabSheet2: TTabSheet;
    TabSheet3: TTabSheet;
    TabSheet4: TTabSheet;
    TabSheet5: TTabSheet;
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonSaveClick(Sender: TObject);
    Procedure LoadOptionsToForm();
  private

  public

  end;

var
  FormOptions: TForm2;

implementation

{$R *.lfm}

Uses
MasterPaskalForm;

Procedure TForm2.LoadOptionsToForm();
Begin
if WO_AutoConnect then CB_WO_AutoConnect.Checked:=true
else CB_WO_AutoConnect.Checked:=false;
if WO_ToTray then CB_WO_ToTray.Checked:= true
else CB_WO_ToTray.Checked:= false;
SE_WO_MinPeers.Value:=MinConexToWork;

End;

{ TForm2 }

// Saves the option to disk
procedure TForm2.ButtonSaveClick(Sender: TObject);
Begin
if CB_WO_AutoConnect.Checked then WO_AutoConnect := true
else WO_AutoConnect := false;
if CB_WO_ToTray.Checked then WO_ToTray:= true
else WO_ToTray:= false;
MinConexToWork := SE_WO_MinPeers.Value;

S_AdvOpt := true;
formOptions.Visible:=false;
End;

// Reloads the active options
procedure TForm2.ButtonCancelClick(Sender: TObject);
begin
LoadOptionsToForm;
end;


END.

