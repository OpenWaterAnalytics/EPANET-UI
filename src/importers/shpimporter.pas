{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       shpimporter
 Description:  a wizard dialog form used to import a pipe network
               from a shapefile
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit shpimporter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls, Grids, SpinEx, FileCtrl;

type

  { TShpImporterForm }

  TShpImporterForm = class(TForm)
    BackBtn:             TButton;
    CancelBtn:           TButton;
    NextBtn:             TButton;
    ImportBtn:           TButton;
    ClearLinksBtn:       TBitBtn;
    ClearNodesBtn:       TBitBtn;
    LinksFileBtn:        TBitBtn;
    NodesFileBtn:        TBitBtn;
    ComputeLengthsCB:    TCheckBox;
    LinksFileEdit:       TEdit;
    NodesFileEdit:       TEdit;
    EpsgEdit:            TEdit;
    FeetRB:              TRadioButton;
    MetersRB:            TRadioButton;
    Image1:              TImage;
    Label1:              TLabel;
    Label4:              TLabel;
    Label6:              TLabel;
    Label7:              TLabel;
    Label13:             TLabel;
    Label14:             TLabel;
    Label17:             TLabel;
    Label19:             TLabel;
    IntroLabel:          TLabel;
    ViewLinkAttribLabel: TLabel;
    ViewNodeAttribLabel: TLabel;
    PrjFileLabel:        TLabel;
    LinksDataGrid:       TStringGrid;
    NodesDataGrid:       TStringGrid;
    Notebook1:           TNotebook;
    Page1:               TPage;
    Page2:               TPage;
    PaintBox1:           TPaintBox;
    Panel1:              TPanel;
    BtnPanel:            TPanel;
    Panel9:              TPanel;
    Panel10:             TPanel;
    Panel2:              TPanel;
    Panel3:              TPanel;
    Panel4:              TPanel;
    Panel6:              TPanel;
    Panel7:              TPanel;
    Shape10:             TShape;
    Shape11:             TShape;
    Shape12:             TShape;
    Shape13:             TShape;
    Shape7:              TShape;
    Shape8:              TShape;
    Shape9:              TShape;
    SnapTolEdit:         TFloatSpinEditEx;
    UnitsCombo:          TComboBox;
    PageControl1:        TPageControl;
    LinksTabSheet:       TTabSheet;
    NodesTabSheet:       TTabSheet;
    OptionsTabSheet:     TTabSheet;
    PreviewTabSheet:     TTabSheet;

    procedure ImportBtnClick(Sender: TObject);
    procedure BackBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure ClearLinksBtnClick(Sender: TObject);
    procedure ClearNodesBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure PrjFileLabelClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure FileBtnClick(Sender: TObject);
    procedure ViewLinkAttribLabelClick(Sender: TObject);
    procedure ViewNodeAttribLabelClick(Sender: TObject);
  private
    NodeFile:   string;      // Name of node shape file
    LinkFile:   string;      // Name of link shape file
    HasChanged: Boolean;     // true if new data loaded
    Bitmap:     TBitMap;     // Bitmap used to preview network
    function  LoadDbfFields(Fname: string; aGrid: TStringGrid): Boolean;
    procedure ClearDataGrid(aGrid: TStringGrid);
    procedure SetButtonStates;
    function  ReadPrjFile: Boolean;
    function  ReadEpsg(Prj: string): string;
    function  ReadUnits(Prj: string): string;
  public

  end;

var
  ShpImporterForm: TShpImporterForm;

implementation

{$R *.lfm}

uses
  main, config, project, utils, shpviewer, shploader, shpapi, resourcestrings;

{ TShpImporterForm }

const

  LinkProps: array[0..9] of string =
  (rsShpLinkProp, 'Link ID', 'Link Type', 'Start Node', 'End Node',
   'Description', 'Tag', 'Length', 'Diameter', 'Roughness');

  NodeProps: array[0..6] of string =
  (rsShpNodeProp, 'Node ID', 'Node Type', 'Description', 'Tag',
   'Elevation', 'Base Demand');

procedure TShpImporterForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  ViewLinkAttribLabel.Font.Size := config.FontSize;
  ViewNodeAttribLabel.Font.Size := config.FontSize;
  PrjFileLabel.Font.Size := config.FontSize;

  IntroLabel.Caption := rsShpIntro;
  Panel3.Caption := rsShpPanel3Text;
  Panel6.Caption := rsShpPanel6Text;
  Panel10.Caption := rsShpPanel10Text;

  for I := Low(LinkProps) to High(LinkProps) do
    LinksDataGrid.Cells[0,I] := LinkProps[I];
  LinksDataGrid.FixedColor := Color;
  for I := Low(NodeProps) to High(NodeProps) do
    NodesDataGrid.Cells[0,I] := NodeProps[I];
  NodesDatagrid.FixedColor := Color;

  BackBtn.Visible := false;
  ImportBtn.Left := NextBtn.Left;
  ImportBtn.Visible := false;

  UnitsCombo.ItemIndex := project.MapUnits;
  if project.MapEPSG > 0 then
    EpsgEdit.Text := IntToStr(project.MapEPSG);

  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf24Bit;
  Bitmap.Canvas.Brush.Color := clWhite;
  Bitmap.Canvas.Brush.Style := bsSolid;

  Notebook1.PageIndex := 0;
  PageControl1.ActivePageIndex := 0;
end;

procedure TShpImporterForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  Bitmap.Free;
end;

procedure TShpImporterForm.CancelBtnClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TShpImporterForm.ClearLinksBtnClick(Sender: TObject);
begin
  LinkFile := '';
  LinksFileEdit.Text := '';
  ClearDataGrid(LinksDataGrid);
  ViewLinkAttribLabel.Visible := false;
end;

procedure TShpImporterForm.ClearNodesBtnClick(Sender: TObject);
begin
  NodeFile := '';
  NodesFileEdit.Text := '';
  ClearDataGrid(NodesDataGrid);
  ViewNodeAttribLabel.Visible := false;
end;

procedure TShpImporterForm.BackBtnClick(Sender: TObject);
begin
  with PageControl1 do
  begin
    if ActivePageIndex > 0 then
      ActivePageIndex := ActivePageIndex - 1;
  end;
  SetButtonStates;
end;

procedure TShpImporterForm.NextBtnClick(Sender: TObject);
begin
  if Notebook1.PageIndex = 0 then
    Notebook1.PageIndex := 1
  else with PageControl1 do
  begin
    if ActivePageIndex < 3 then
      ActivePageIndex := ActivePageIndex + 1;
  end;
  SetButtonStates;
end;

procedure TShpImporterForm.ImportBtnClick(Sender: TObject);
var
  ShpOptions: shploader.TShpOptions;
  R:          Integer;
  Code:       Integer;
  S:          string;
begin
  with ShpOptions do
  begin
    NodeFileName := NodeFile;
    LinkFileName := LinkFile;
    CoordUnits := UnitsCombo.ItemIndex;
    Epsg := 0;
    if Length(Trim(EpsgEdit.Text)) > 0 then
      Val(EpsgEdit.Text, Epsg, Code);
    SnapTol := SnapTolEdit.Value;
    if FeetRB.Checked then
      SnapUnits := 1
    else
      SnapUnits := 2;
    ComputeLengths := ComputeLengthsCB.Checked;
    
    with LinksDataGrid do
    begin
      for R := 1 to RowCount-1 do
      begin
        S := Cells[1, R];
        LinkAttribs[R] := Columns[0].PickList.IndexOf(S) - 1;
        LinkUnits[R] := Cells[2,R];
      end;
    end;
    
    with NodesDataGrid do
    begin
      for R := 1 to RowCount-1 do
      begin
        S := Cells[1, R];
        NodeAttribs[R] := Columns[0].PickList.IndexOf(S) - 1;
        NodeUnits[R] := Cells[2,R];
      end;
    end;
  end;
  
  if not shploader.LoadShapeFile(ShpOptions) then
    BackBtnClick(self)
  else
  begin
    Hide;
    ModalResult := mrOK;
  end;
end;

procedure TShpImporterForm.PrjFileLabelClick(Sender: TObject);
var
  S: string;
begin
  if ReadPrjFile then exit;
  if utils.MsgDlg(rsMissingData, rsNoProjData, mtConfirmation, [mbYes, mbNo],
    self) = mrNo then exit;
  with MainForm.OpenDialog1 do
  begin
    S := Title;
    Title := rsSelectProjFile;
    Filter := rsProjFiles;
    Filename := '*.prj';
    if Execute then
    begin
      with TShpViewerForm.Create(self) do
      try
        ViewPrjFile(Filename);
        ShowModal;
      finally
        Free;
      end;
    end;
    Title := S;
  end;
end;

procedure TShpImporterForm.FileBtnClick(Sender: TObject);
var
  Fname: string = '';
begin
  with MainForm.OpenDialog1 do
  begin
    if PageControl1.ActivePage = LinksTabSheet then
      Title := rsLinksShpFile
    else
      Title := rsNodesShpFile;
    Filter := rsShpFiles;
    Filename := '*.shp';
    if Execute then Fname := Filename else exit;
   end;

  if PageControl1.ActivePage = LinksTabSheet then
  begin
    if LoadDbfFields(Fname, LinksDataGrid) then
    begin
      LinksFileEdit.Text := MinimizeName(Fname, Canvas, LinksFileEdit.Width);
      if not SameText(Fname, LinkFile) then HasChanged := true;
      LinkFile := Fname;
    end
    else
      LinksFileEdit.Text := '';
  end;

  if PageControl1.ActivePage = NodesTabSheet then
  begin
    if LoadDbfFields(Fname, NodesDataGrid) then
    begin
      NodesFileEdit.Text := MinimizeName(Fname, Canvas, NodesFileEdit.Width);
      if not SameText(Fname, NodeFile) then HasChanged := true;
      NodeFile := Fname;
    end
    else
      NodesFileEdit.Text := '';
  end;
end;

procedure TShpImporterForm.ViewLinkAttribLabelClick(Sender: TObject);
begin
  with TShpViewerForm.Create(self) do
  try
    if ViewDbfFile(LinkFile) then ShowModal;
  finally
    Free;
  end;
end;

procedure TShpImporterForm.ViewNodeAttribLabelClick(Sender: TObject);
begin
  with TShpViewerForm.Create(self) do
  try
    if ViewDbfFile(NodeFile) then ShowModal;
  finally
    Free;
  end;
end;

procedure TShpImporterForm.PageControl1Change(Sender: TObject);
begin
  SetButtonStates;
end;

procedure TShpImporterForm.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0, 0, Bitmap);
end;

procedure TShpImporterForm.SetButtonStates;
begin
  ImportBtn.Visible := false;
  BackBtn.Visible := true;
  BackBtn.Enabled := true;
  NextBtn.Visible := true;
  PreviewTabSheet.TabVisible := false;
  if PageControl1.ActivePageIndex = 0 then BackBtn.Enabled := false;
  if PageControl1.ActivePageIndex = 3 then
  begin
    NextBtn.Visible := false;
    ImportBtn.Visible := true;
    ImportBtn.Enabled := false;
    PreviewTabSheet.TabVisible := true;
    if HasChanged then
    begin
      ImportBtn.Enabled := true;
      Bitmap.SetSize(PaintBox1.Width, PaintBox1.Height);
      Bitmap.Canvas.Rectangle(0, 0, Bitmap.Width, Bitmap.Height);
      if shpviewer.ViewShpFile(LinkFile, NodeFile, Bitmap) = true then
        HasChanged := false;
      PaintBox1.Refresh;
    end;
  end;
end;

function TShpImporterForm.LoadDbfFields(Fname: string; aGrid: TStringGrid): Boolean;
//
// Load fields in a Node/Link dBase file Fname into aGrid's column 0 PickList.
//
var
  ShapeType: Integer;
  MinBound: array [0..3] of Double;
  MaxBound: array [0..3] of Double;
  FieldName: array[0..XBASE_FLDNAME_LEN_READ] of Char;
  Count: Integer;
  FieldWidth: Integer;
  FieldDecimals: Integer;
  Shp: SHPHandle;
  Dbf: DBFHandle;
  I: Integer;
begin
  Result := false;
  Shp := nil;
  Dbf := nil;

  try
    // Clear list of imported data fields
    aGrid.Columns[0].PickList.Clear;
    aGrid.Columns[0].PickList.Add('');

    // Open the shape file
    Shp := SHPOpen(PAnsiChar(Fname), 'rb');
    if Shp = Nil then
    begin
      utils.MsgDlg(rsFileError, rsNotShpFile, mtError, [mbOk], self);
      exit;
    end;
    shpapi.SHPGetInfo(Shp, Count, ShapeType, MinBound, MaxBound);

    // Check that shape file is of the correct type
    if PageControl1.ActivePage = LinksTabSheet then
    begin
      if ShapeType <> SHPT_ARC then
      begin
        utils.MsgDlg(rsFileError, rsNotLinkFile, mtError, [mbOk], self);
        exit;
      end;
    end
    else
    begin
      if ShapeType <> SHPT_POINT then
      begin
        utils.MsgDlg(rsFileError, rsNotNodeFile, mtError, [mbOk], self);
        exit;
      end;
    end;

    // Open the shape file's corresponding dBase file
    Fname := ChangeFileExt(Fname, '.dbf');
    Dbf := shpapi.DBFOpen(PAnsiChar(Fname), 'rb');

    // Load data fields into grid's first column
    if Dbf <> Nil then
    begin
      Count := shpapi.DBFGetFieldCount(Dbf);
      for I := 0 to Count-1 do
      begin
        shpapi.DBFGetFieldInfo(Dbf, I, FieldName, FieldWidth, FieldDecimals);
        aGrid.Columns[0].PickList.Add(FieldName);
      end;
      if PageControl1.ActivePage = LinksTabSheet then
        ViewLinkAttribLabel.Visible := true
      else
        ViewNodeAttribLabel.Visible:= true;
    end;
    Result := true;

  // Close the shape and Dbase files
  finally
    shpapi.DBFClose(Dbf);
    shpapi.SHPClose(Shp);
  end;
end;

procedure TShpImporterForm.ClearDataGrid(aGrid: TStringGrid);
var
  I: Integer;
  J: Integer;
begin
  with aGrid do
  begin
    for I := 1 to ColCount-1 do
    begin
      for J := 1 to RowCount-1 do Cells[I,J] := '';
    end;
  end;
end;

function TShpImporterForm.ReadPrjFile: Boolean;
//
// Read the EPSG code and coordinate units from a .prj file.
//
var
  Fname: string;
  F: TextFile;
  S: string;
  Units: string;
  Epsg: string;
begin
  Result := false;
  Fname := ChangeFileExt(LinkFile, '.prj');
  if not FileExists(Fname) then
    Fname := ChangeFileExt(NodeFile, '.prj');
  if not FileExists(Fname) then exit;
  S := '';
  AssignFile(F, Fname);
  Reset(F);
  while not Eof(F) do
  begin
    Readln(F, S);
  end;
  CloseFile(F);
  S := UpperCase(S);
  Units := ReadUnits(S);
  Epsg := ReadEpsg(S);
  if (Length(Units) > 0)
  or (Length(Epsg) > 0) then
  begin
    S := Format(rsProjData, [Epsg, Units]);
    if utils.MsgDlg('', S, mtConfirmation, [mbYes, mbNo], self) = mrYes then
    begin
      UnitsCombo.ItemIndex := UnitsCombo.Items.IndexOf(Units);
      EpsgEdit.Text := Epsg;
      Result := true;
    end
    else
      exit;
  end;
end;

function TShpImporterForm.ReadEpsg(Prj: string): string;
//
// Parse an EPSG code from string Prj.
//
const
  EpsgSubStr: string = 'AUTHORITY["EPSG","';
var
  N1: Integer;
  N2: Integer;
begin
  Result := '';
  if Length(Prj) = 0 then exit;
  N1 := Prj.LastIndexOf(EpsgSubStr);
  if (N1 > 0) then
  begin
    N1 := N1 + Length(EpsgSubStr) + 1;
    N2 := LastDelimiter('"', Prj);
    Result := Copy(Prj, N1, N2 - N1);
  end;
end;

function TShpImporterForm.ReadUnits(Prj: string): string;
//
// Parse the units of the shapefile coordinates from string Prj
//
const
  UnitSubStr: string = ',UNIT["';
var
  N1: Integer;
  N2: Integer;
  S: string;
begin
  Result := 'Unknown';
  if Length(Prj) = 0 then exit;
  N1 := Prj.LastIndexOf(UnitSubStr);
  if N1 > 0 then
  begin
    N1 := N1 + Length(UnitSubStr) + 1;
    N2 := Pos('"', Prj, N1);
    if N2 <= N1 then exit;
    S := Upcase(Copy(Prj, N1, N2-N1));
    if Pos('DEG',S) > 0 then
      Result := 'Degrees'
    else if Pos('FEET', S) > 0 then
      Result := rsFeet
    else if Pos('FOOT', S) > 0 then
      Result := rsFeet
    else if Pos('MET', S) > 0 then
      Result := rsMeters;
  end;
end;

end.
