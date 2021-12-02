unit FormExplore;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil,
  Forms, Controls, StdCtrls, Graphics, Buttons, Grids, ExtCtrls;

type
  TExplorerForm = class(TForm)
  private
    FPathPanel: TPanel;
    FEditPath: TEdit;
    FSBUpPath: TSpeedButton;

    FFilenamePanel: TPanel;
    FEditFilename: TEdit;
    FSBOkFile: TSpeedButton;

    FActiveDir: String;
    FGridFiles: TStringGrid;
    FilesDir: TStringList;
    FoldersDir: TStringList;

    procedure ResizeExplorer(Sender: TObject);
    procedure FSBOkFileOnClick(Sender: TObject);
    function OnlyName(const conpath: String): String;
    procedure FGridFilesDblClick(Sender: TObject);
    procedure FGridFilesSelection(Sender: TObject; aCol, aRow: Integer);
    procedure SBUpPathClick(Sender: TObject);
    procedure LoadDirectory(const Directory: String);
    procedure FGridFilesPrepareCanvas(sender: TObject; aCol, aRow: Integer;aState: TGridDrawState);
    procedure FGridFilesDrawCell(Sender: TObject; aCol, aRow: Integer;aRect: TRect; aState: TGridDrawState);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

  procedure ShowExplorer(const Directory: String; titulo,mascara,lineaaprocesar:string;fijarnombre:boolean);
  procedure CloseExplorer();

  var
    FResult : STring = '';
    FileMasK : String;
    LineaEjecutar : String;

implementation

Uses
  MasterPaskalForm, MpGUI;

var
  explorer: TExplorerForm = Nil;

procedure ShowExplorer(const Directory: String; titulo,mascara,lineaaprocesar:string;fijarnombre:boolean);
begin
  if not Assigned(explorer) then
    explorer := TExplorerForm.Create(Nil);
  explorer.Caption:=titulo;
  FileMask := Mascara;
  LineaEjecutar := lineaaprocesar;
  explorer.LoadDirectory(Directory);
  Explorer.FEditFilename.ReadOnly:=fijarnombre;
  explorer.Show;
  FResult := '';
  explorer.FGridFiles.ColWidths[0] := thispercent(100,explorer.FGridFiles.Width);
end;

Procedure CloseExplorer();
Begin
if Assigned(explorer) then explorer.Visible:=false;
End;

{ TExplorerForm }

constructor TExplorerForm.Create(TheOwner: TComponent);
begin
  inherited CreateNew(TheOwner);
  Caption := 'File Explorer';
  //SetBounds(0, 0, 450, 350);

  Constraints.MinWidth:= 450;
  // This hides the extra cols, remove if you want full resize
  //Constraints.MaxWidth:= 450;

  Constraints.MinHeight:= 350;
  // BY GUS
  // Remove this comment if you want to make it non resizable
  //BorderStyle := bssingle;
  Position := poOwnerFormCenter;
  BorderIcons := BorderIcons - [biminimize];
  ShowInTaskBar:=sTAlways;
  OnResize:=@ResizeExplorer;

  FilesDir := TStringList.Create;
  FoldersDir := TStringList.Create;

  FPathPanel:= TPanel.Create(Self);
  with FPathPanel do
    begin
      Parent:= Self;
      AutoSize:= True;
      Align:= alTop;
      Caption:='';
      BevelOuter:= bvNone;
    end;

  FEditPath := TEdit.Create(FPathPanel);
  with FEditPath do
    begin
      Parent:= FPathPanel;
      Align:= alLeft;
      Width:= FPathPanel.ClientWidth - 50;
      Anchors:= [akTop, akleft, akRight];
      Font.Name := 'consolas';
      Font.Size := 12;
      Font.Color := clWhite;
      Color := clBlack;
      Alignment := taLeftJustify;
      ReadOnly := True;
    end;

  FSBUpPath := TSpeedButton.Create(FPathPanel);
  with FSBUpPath do
    begin
      Parent := FPathPanel;
      Align:= alRight;
      Width:= 42;
      Anchors:= [akTop, akRight];
      Hint := 'Go up';
      ShowHint := True;
      OnClick := @SBUpPathClick;
    end;

  FGridFiles := TStringGrid.Create(explorer);
  with FGridFiles do
    begin
      Align:= alClient;
      Font.Name := 'consolas';
      Font.Size := 9;
      FixedCols := 0;
      FixedRows := 1;
      RowCount := 1;
      ColCount := 1;
      GridLineWidth := 0;
      ScrollBars := ssAutoVertical;
      Options := Options - [goRangeSelect];
      Cells[0,0] := 'Name';
      FocusRectVisible := False;
      OnDblClick := @FGridFilesDblClick;
      OnSelection := @FGridFilesSelection;
      OnPrepareCanvas := @FGridFilesPrepareCanvas;
      OnDrawCell := @FGridFilesDrawCell;
      Parent := Self;
    end;

  FFilenamePanel:= TPanel.Create(Self);
  with FFilenamePanel do
    begin
      Parent:= Self;
      AutoSize:= True;
      Align:= alBottom;
      Caption:='';
      BevelOuter:= bvNone;
    end;

  FEditFilename := TEdit.Create(FFilenamePanel);
  with FEditFilename do
    begin
      Parent := FFilenamePanel;
      Align:= alLeft;
      Width:= FFilenamePanel.ClientWidth - 50;
      Anchors:= [akTop, akleft, akRight];
      Font.Name := 'consolas';
      Font.Size := 12;
      Font.Color := clWhite;
      Color := clBlack;
      Alignment := taLeftJustify;
      ReadOnly := True;
    end;

  FSBOkFile := TSpeedButton.Create(FFilenamePanel);
  with FSBOkFile do
    begin
      Parent := FFilenamePanel;
      Align:= alRight;
      Width:= 42;
      Anchors:= [akTop, akRight];
      ShowHint := True;
      Hint := 'Accept';
      OnClick := @FSBOkFileOnClick;
    end;

Form1.imagenes.GetBitmap(17,FSBOkFile.Glyph);
Form1.imagenes.GetBitmap(40,FSBUpPath.Glyph);
end;

destructor TExplorerForm.Destroy;
begin
  FilesDir.Free;
  FoldersDir.Free;
  inherited Destroy;
end;

// Adjust grid when resizing
procedure TExplorerForm.ResizeExplorer(Sender: TObject);
var
  GridWidth : integer;
begin
GridWidth := FGridFiles.Width;
FGridFiles.ColWidths[0]:= thispercent(100,GridWidth);
end;

procedure TExplorerForm.FGridFilesDblClick(Sender: TObject);
begin
  if (FGridFiles.Row > 0) and (Copy(FGridFiles.Cells[0,FGridFiles.Row],1,3) = '   ' ) then
    begin
    FActiveDir := FActiveDir+DirectorySeparator+ Copy(FGridFiles.Cells[0,FGridFiles.Row],4,Length(FGridFiles.Cells[0,FGridFiles.Row]));
    LoadDirectory(FActiveDir);
    end;
  if (FGridFiles.Row > 0) and (Copy(FGridFiles.Cells[0,FGridFiles.Row],1,3) <> '   ' ) then
     begin
     FEditFilename.Text := FGridFiles.Cells[0,FGridFiles.Row];
     FSBOkFileOnClick(nil);
     end;
end;

procedure TExplorerForm.FGridFilesSelection(Sender: TObject; aCol, aRow: Integer);
begin
  FEditFilename.Text := FGridFiles.Cells[0,FGridFiles.Row];
  if Copy(FEditFilename.Text,1,3) = '   ' then FEditFilename.Text := '';
end;

procedure TExplorerForm.FSBOkFileOnClick(Sender: TObject);
begin
  if FEditFilename.Text = '' then
     begin
     explorer.visible := false;
     exit;
     end;
  FResult := FActiveDir+DirectorySeparator+FEditFilename.Text;
  FResult := StringReplace(FResult,' ','*',[rfReplaceAll, rfIgnoreCase]);
  ProcessLines.Add(StringReplace(LineaEjecutar,'(-resultado-)',FResult,[rfReplaceAll, rfIgnoreCase]));
  explorer.visible := false;
end;

procedure TExplorerForm.LoadDirectory(const Directory: String);
var
  cont: Integer;
begin
  FilesDir.Clear;
  FoldersDir.Clear;
  FGridFiles.RowCount := 1;
  FindAllFiles(FilesDir, Directory, FileMask, False);
  FindAllDirectories(FoldersDir, Directory, False);
  if FoldersDir.Count > 0 then
    for cont := 0 to FoldersDir.Count-1 do
      begin
        FGridFiles.RowCount := FGridFiles.RowCount+1;
        FGridFiles.Cells[0,cont+1] := '   ' + OnlyName(FoldersDir[cont]);
      end;
  if FilesDir.Count > 0 then
    for cont := 0 to FilesDir.Count-1 do
      begin
        FGridFiles.RowCount := FGridFiles.RowCount+1;
        FGridFiles.Cells[0,FGridFiles.RowCount-1] := OnlyName(FilesDir[cont]);
      end;
  FEditPath.Text := Directory;
  FActiveDir := Directory;
  FEditFilename.Text := FGridFiles.Cells[0,FGridFiles.Row];
  if Copy(FEditFilename.Text,1,3) = '   ' then FEditFilename.Text := '';
end;

function TExplorerForm.OnlyName(const conpath: String): String;
var
  cont: Integer;
begin
  result := '';
  for cont := Length(conpath) downto 1 do
   if conpath[cont] = DirectorySeparator then
     begin
       Result := Copy(conpath, cont+1, Length(conpath));
       Break;
     end;
end;

procedure TExplorerForm.FGridFilesPrepareCanvas(sender: TObject; aCol, aRow: Integer;
  aState: TGridDrawState);
begin
if ((arow = FGridFiles.Row) and (arow>0)) then
   begin
   (Sender as TStringGrid).Canvas.Brush.Color :=  clblue;
   (Sender as TStringGrid).Canvas.Font.Color:=clwhite
   end;
end;

procedure TExplorerForm.FGridFilesDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  Bitmap    : TBitmap;
  myRect    : TRect;
begin
if copy((sender as TStringGrid).Cells[0,arow],1,3) = '   ' then
   begin
   Bitmap:=TBitmap.Create;
   Form1.imagenes.GetBitmap(41,Bitmap);
   myRect := Arect;
   myrect.Left:=myRect.Left+6;
   myRect.Right := myrect.Left+16;
   myrect.Bottom:=myrect.Top+16;
   (sender as TStringGrid).Canvas.StretchDraw(myRect,bitmap);
   Bitmap.free
   end;
end;

procedure TExplorerForm.SBUpPathClick(Sender: TObject);
var
  contador : integer;
begin
for contador := length(FActiveDir) downto 1 do
   begin
   if FActiveDir[contador] = DirectorySeparator then
      begin
        FActiveDir := copy(FActiveDir,1,contador-1);
        LoadDirectory(FActiveDir);
        Break;
      end;
   end;
end;

finalization

  explorer.Free;
  explorer := Nil;

END.
