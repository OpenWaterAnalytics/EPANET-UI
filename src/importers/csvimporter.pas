{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       csvloader
 Description:  a wizard dialog form used to import a pipe network
               from a CSV text file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit csvimporter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, ComCtrls, Grids, FileCtrl, SpinEx;

type

  { TCsvImporterForm }

  TCsvImporterForm = class(TForm)
    Panel1:           TPanel;
    Panel2:           TPanel;
    Panel5:           TPanel;
    Panel3:           TPanel;
    Panel4:           TPanel;
    BtnPanel:         TPanel;
    BackBtn:          TButton;
    CancelBtn:        TButton;
    NextBtn:          TButton;
    ImportBtn:        TButton;
    HelpBtn:          TButton;
    ClearNodesBtn:    TBitBtn;
    ClearPipesBtn:    TBitBtn;
    NodesFileBtn:     TBitBtn;
    PipesFileBtn:     TBitBtn;
    Image1:           TImage;
    IntroLabel:       TLabel;
    Label1:           TLabel;
    Label4:           TLabel;
    Label6:           TLabel;
    Label8:           TLabel;
    NoDataLabel:      TLabel;
    ViewNodeCsvFile:  TLabel;
    ViewPipeCsvFile:  TLabel;
    NodesDataGrid:    TStringGrid;
    PipesDataGrid:    TStringGrid;
    ReviewGrid:       TStringGrid;
    NodesFileEdit:    TEdit;
    PipesFileEdit:    TEdit;
    PageControl1:     TPageControl;
    IntroTabSheet:    TTabSheet;
    NodesTabSheet:    TTabSheet;
    PipesTabSheet:    TTabSheet;
    ReviewTabSheet:   TTabSheet;

    procedure BackBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure ClearPipesBtnClick(Sender: TObject);
    procedure ClearNodesBtnClick(Sender: TObject);
    procedure FileBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure ImportBtnClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure ReviewGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure ViewPipeCsvFileClick(Sender: TObject);
    procedure ViewNodeCsvFileClick(Sender: TObject);
  private
    NodeFile:     string;      // Name of node CSV file
    PipeFile:     string;      // Name of pipe CSV file
    HasChanged:   Boolean;     // true if new data loaded
    HasCoords:    Boolean;     // true if node CSV file has node coords.
    NewHeaderRow: Integer;

    procedure ClearDataGrid(aGrid: TStringGrid);
    procedure SetButtonStates;
    function  ShowSummary: Boolean;
    function  LoadCsvFields(Fname: string; aGrid: TStringGrid): Boolean;
    function  HasCoordData: Boolean;
  public

  end;

var
  CsvImporterForm: TCsvImporterForm;

implementation

{$R *.lfm}

uses
  main, config, project, csvviewer, csvloader, resourcestrings;

const

  PipeProps: array[0..13] of string =
  (rsCsvPipeProp, 'Pipe ID', 'Start Node', 'End Node',
   'Description', 'Tag', 'Length', 'Diameter', 'Roughness',
   'Loss Coeff.', 'Bulk Coeff.', 'Wall Coeff', 'Leak Area',
   'Leak Expansion');
  PipeUnits: string = rsPipeUnits;

  NodeProps: array[0..9] of string =
  (rsCsvNodeProp, 'Node ID', 'X-coordinate', 'Y-coordinate',
  'Description', 'Tag', 'Elevation', 'Base Demand', 'Emitter Coeff.',
  'Initial Quality');
  NodeUnits: string = rsNodeUnits;

{ TCsvImporterForm }

procedure TCsvImporterForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  IntroLabel.Caption := rsCsvIntro;
  HasCoords := false;

  Panel4.Caption := rsCsvPanel4Text;
  Panel3.Caption := rsCsvPanel3Text;
  for I := Low(PipeProps) to High(PipeProps) do
    PipesDataGrid.Cells[0,I] := PipeProps[I];
  PipesDataGrid.Columns[1].PickList.AddCommaText(PipeUnits);
  PipesDataGrid.FixedColor := Color;
  for I := Low(NodeProps) to High(NodeProps) do
    NodesDataGrid.Cells[0,I] := NodeProps[I];
  NodesDataGrid.Columns[1].PickList.AddCommaText(NodeUnits);
  NodesDatagrid.FixedColor := Color;
  ReviewGrid.Cells[0,0] := rsCsvProperty;
  ReviewGrid.Cells[1,0] := rsCsvFileColumn;
  PageControl1.PageIndex := 0;

  BackBtn.Visible := false;
  ImportBtn.Left := NextBtn.Left;
  ImportBtn.Visible := false;
end;

procedure TCsvImporterForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#importing_from_text_files');
end;

procedure TCsvImporterForm.ImportBtnClick(Sender: TObject);
//
// Import node and link data from a CSV file into an EPANET project.
//
var
  CsvOptions: csvloader.TCsvOptions;
  R: Integer;
  S: string;
begin
  with CsvOptions do
  begin
    NodeFileName := NodeFile;
    PipeFileName := PipeFile;

    with PipesDataGrid do
    begin
      for R := 1 to RowCount-1 do
      begin
        S := Cells[1, R];
        PipeAttribs[R] := Columns[0].PickList.IndexOf(S) - 1;
        PipeUnits[R] := Cells[2,R];
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
  CsvOptions.HasCoordinates := HasCoordData;

  csvloader.LoadCsvFile(CsvOptions);
  Hide;
  ModalResult := mrOK;
end;

procedure TCsvImporterForm.NextBtnClick(Sender: TObject);
begin
  PageControl1.ActivePageIndex := PageControl1.ActivePageIndex + 1;
  SetButtonStates;
end;

procedure TCsvImporterForm.ReviewGridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if (aRow = 0)
  or (aRow = NewHeaderRow) then
    ReviewGrid.Font.Underline := true
  else
    ReviewGrid.Font.Underline := false;
end;

procedure TCsvImporterForm.ViewPipeCsvFileClick(Sender: TObject);
begin
  with TCsvViewerForm.Create(self) do
  try
    if ViewCsvFile(PipeFile) then ShowModal;
  finally
    Free;
  end;
end;

procedure TCsvImporterForm.ViewNodeCsvFileClick(Sender: TObject);
begin
  with TCsvViewerForm.Create(self) do
  try
    if ViewCsvFile(NodeFile) then ShowModal;
  finally
    Free;
  end;
end;

procedure TCsvImporterForm.CancelBtnClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TCsvImporterForm.BackBtnClick(Sender: TObject);
begin
  PageControl1.ActivePageIndex := PageControl1.ActivePageIndex - 1;
  SetButtonStates;
end;

procedure TCsvImporterForm.ClearPipesBtnClick(Sender: TObject);
begin
  PipeFile := '';
  PipesFileEdit.Text := '';
  ClearDataGrid(PipesDataGrid);
  ViewPipeCsvFile.Visible := false;
end;

procedure TCsvImporterForm.ClearNodesBtnClick(Sender: TObject);
begin
  NodeFile := '';
  NodesFileEdit.Text := '';
  ClearDataGrid(NodesDataGrid);
  ViewNodeCsvFile.Visible := false;
end;

procedure TCsvImporterForm.FileBtnClick(Sender: TObject);
var
  Fname: string = '';
begin
  with MainForm.OpenDialog1 do
  begin
    if PageControl1.ActivePage = PipesTabSheet then
      Title := rsPipesCsvFile
    else
      Title := rsNodesCsvFile;
    Filter := rsCsvFiles;
    Filename := '*.csv';
    if Execute then Fname := Filename else exit;
   end;

  if PageControl1.ActivePage = PipesTabSheet then
  begin
    if LoadCsvFields(Fname, PipesDataGrid) then
    begin
      PipesFileEdit.Text := MinimizeName(Fname, Canvas, PipesFileEdit.Width);
      if not SameText(Fname, PipeFile) then HasChanged := true;
      PipeFile := Fname;
      ViewPipeCsvFile.Visible := true;
    end
    else
      PipesFileEdit.Text := '';
  end;

  if PageControl1.ActivePage = NodesTabSheet then
  begin
    if LoadCsvFields(Fname, NodesDataGrid) then
    begin
      NodesFileEdit.Text := MinimizeName(Fname, Canvas, NodesFileEdit.Width);
      if not SameText(Fname, NodeFile) then HasChanged := true;
      NodeFile := Fname;
      ViewNodeCsvFile.Visible := true;
    end
    else
      NodesFileEdit.Text := '';
  end;
end;

procedure TCsvImporterForm.ClearDataGrid(aGrid: TStringGrid);
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

procedure TCsvImporterForm.SetButtonStates;
begin
  ImportBtn.Visible := false;
  BackBtn.Visible := true;
  BackBtn.Enabled := true;
  NextBtn.Visible := true;
  if PageControl1.ActivePage = NodesTabSheet then BackBtn.Enabled := false;
  if PageControl1.ActivePage = ReviewTabSheet then
  begin
    NextBtn.Visible := false;
    ImportBtn.Visible := true;
    ImportBtn.Enabled := false;
    if ShowSummary then ImportBtn.Enabled := true;
  end;
end;

function TCsvImporterForm.ShowSummary: Boolean;
var
  R, Count: Integer;
  S: string;
begin
  Result := false;
  NewHeaderRow := -1;
  ReviewGrid.RowCount := 1;
  ReviewGrid.Cells[0,0] := rsCsvNodeProp;
  ReviewGrid.Cells[1,0] := rsCsvFileColumn;
  Count := 1;
  with NodesDataGrid do
  begin
    for R := 1 to RowCount-1 do
    begin
      S := Cells[1, R];
      if Length(S) > 0 then
      begin
        Inc(Count);
        ReviewGrid.RowCount := Count;
        ReviewGrid.Cells[0,Count-1] := Cells[0, R];
        ReviewGrid.Cells[1,Count-1] := S;
        Result := true;
      end;
    end;
  end;
  ReviewGrid.RowCount := Count + 1;
  Inc(Count);
  ReviewGrid.Cells[0,Count-1] := '';
  ReviewGrid.Cells[1,Count-1] := '';
  NewHeaderRow := Count;
  Inc(Count);
  ReviewGrid.RowCount := Count;
  ReviewGrid.Cells[0,Count-1] := rsCsvPipeProp;
  ReviewGrid.Cells[1,Count-1] := rsCsvFileColumn;
  with PipesDataGrid do
  begin
    for R := 1 to RowCount-1 do
    begin
      S := Cells[1, R];
      if Length(S) > 0 then
      begin
        Inc(Count);
        ReviewGrid.RowCount := Count;
        ReviewGrid.Cells[0,Count-1] := Cells[0, R];
        ReviewGrid.Cells[1,Count-1] := S;
        Result := true;
      end;
    end;
  end;
  NoDataLabel.Visible := not Result;
end;

function TCsvImporterForm.LoadCsvFields(Fname: string; aGrid: TStringGrid): Boolean;
var
  F: TextFile;
  J: Integer;
  S: string = '';
  Fields: TStringList;
begin
  Result := false;
  aGrid.Columns[0].PickList.Clear;
  aGrid.Columns[0].PickList.Add('');
  Fields := TStringList.Create;
  AssignFile(F, Fname);
  try
    Reset(F);
    Readln(F, S);
    Fields.Delimiter := ',';
    Fields.DelimitedText := S;
    if Fields.Count > 0 then
    begin
      for J := 0 to Fields.Count - 1 do
          aGrid.Columns[0].PickList.Add(Fields[J]);
      Result := true;
    end;
  finally
    CloseFile(F);
    Fields.Free;
  end;
end;

function TCsvImporterForm.HasCoordData: Boolean;
begin
  Result := (Length(NodesDataGrid.Cells[1, nXcoord]) > 0) and
            (Length(NodesDataGrid.Cells[1,nYcoord]) > 0);
end;

end.

