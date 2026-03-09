{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       patterneditor
 Description:  a form that manages a project's set of Time Patterns
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit patterneditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  LCLtype, ExtCtrls, TAGraph, TASeries, TACustomSeries;

type

  { TPatternEditorForm }

  TPatternEditorForm = class(TForm)
    Notebook1:        TNotebook;
    Page1:            TPage;
    Page2:            TPage;
    AddBtn:           TButton;
    EditBtn:          TButton;
    DeleteBtn:        TButton;
    OkBtn:            TButton;
    AcceptBtn:        TButton;
    CancelBtn1:       TButton;
    CancelBtn2:       TButton;
    HelpBtn1:         TButton;
    HelpBtn2:         TButton;
    LoadBtn:          TButton;
    SaveBtn:          TButton;
    IdEdit:           TEdit;
    DescripEdit:      TEdit;
    DiurnalPatLabel:  TLabel;
    Label1:           TLabel;
    Label2:           TLabel;
    Label3:           TLabel;
    Chart1:           TChart;
    Chart2:           TChart;
    Chart1AreaSeries: TAreaSeries;
    Chart2AreaSeries: TAreaSeries;
    PatternsGrid:     TStringGrid;
    DataGrid:         TStringGrid;
    ClearBtn: TButton;

    procedure AcceptBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CancelBtn1Click(Sender: TObject);
    procedure CancelBtn2Click(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure DataGridKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure DataGridValidateEntry(Sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
    procedure DeleteBtnClick(Sender: TObject);
    procedure DiurnalPatLabelClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure HelpBtn1Click(Sender: TObject);
    procedure IdEditChange(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure PatternsGridClick(Sender: TObject);
    procedure PatternsGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure SaveBtnClick(Sender: TObject);

  private
    PatternIndex: Integer;
    HasChanged2:  Boolean;
    OldId:        string;

    procedure InitDataGrid;
    procedure ShowPatternProperties(I: Integer);
    procedure EditPatternData;
    procedure LoadPatternData(Filename: string);
    procedure SavePatternData(Filename: string);
    procedure SetMultipliers;
    procedure GetMultipliers;
    function  GetPatternData: Boolean;
    procedure PlotPattern(PatIndex: Integer);
    procedure PlotPattern2;

  public
    SelectedName: string;
    SelectedIndex: Integer;
    HasChanged: Boolean;
    procedure Setup(ItemName: string);
  end;

var
  PatternEditorForm: TPatternEditorForm;

implementation

{$R *.lfm}

uses
  main, project, projectbuilder, config, utils, epanet2, resourcestrings;

const
  MAXPERIODS = 24;

  DiurnalPattern: array[0..23] of Single =
    (0.7,0.6,0.5,0.5,0.5,0.6,0.8,1.0,1.1,1.25,1.28,1.2,
     1.18,1.16,1.1,1.0,1.08,1.15,1.3,1.6,1.4,1.25,0.9,0.85);

// Definition of TimeType (seconds) depending on OS
{$I ..\timetype.txt}

{ TPatternEditorForm }

procedure TPatternEditorForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  PatternsGrid.FixedColor := Color;
  Font.Size := config.FontSize;
  SelectedName := '';
  DataGrid.FixedColor := Color;
  InitDataGrid;
  HasChanged := false;
end;

procedure TPatternEditorForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if HasChanged then
  begin
    Project.HasChanged := true;
    Project.UpdateResultsStatus;
  end;
end;

procedure TPatternEditorForm.PatternsGridClick(Sender: TObject);
var
  I: Integer;
begin
  I := PatternsGrid.Row - 1;
  EditBtn.Enabled := I > 0;
  DeleteBtn.Enabled := I > 0;
  if I > 0 then
    PlotPattern(I)
  else
    Chart1AreaSeries.Clear;
end;

procedure TPatternEditorForm.PatternsGridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if aRow > 0 then with Sender as TStringGrid do
  begin
    if gdSelected in aState then
    begin
      Canvas.Brush.Color := $00FFE8CD;
      Canvas.Font.Color := clBlack;
    end;
  end;
end;

procedure TPatternEditorForm.AddBtnClick(Sender: TObject);
begin
  // Edit data for non-existent pattern - it will
  // create the pattern and return its index if not cancelled
  PatternIndex := -1;
  EditPatternData;
end;

procedure TPatternEditorForm.EditBtnClick(Sender: TObject);
begin
  // EPANET API pattern index corresponding to current selected row
  // of PatternsGrid (1-based and accounting for <blank> 1st row)
  PatternIndex := PatternsGrid.Row - 1;

  // Call Pattern editor if selected row is greater than first "blank" row
  if PatternIndex >= 1 then EditPatternData;
end;

procedure TPatternEditorForm.DeleteBtnClick(Sender: TObject);
var
  Msg: string;
  ItemName: string;
begin
  // EPANET API pattern index corresponding to current selected row
  // of PatternsGrid (1-based and accounting for <blank> 1st row)
  PatternIndex := PatternsGrid.Row - 1;
  if PatternIndex < 1 then exit;
  ItemName := PatternsGrid.Cells[0, PatternIndex];

  // Verify deletion
  if config.ConfirmDeletions then
  begin
    Msg := Format(rsWishToDelete,
      [project.GetItemTypeStr(ctPatterns, 0),
      PatternsGrid.Cells[0, PatternIndex+1]]);
    if utils.MsgDlg(rsConfirmDelete, Msg, mtConfirmation,
      [mbYes, mbNo]) = mrNo then exit;
  end;

  // Delete item from project and update PatternsGrid
  project.DeleteItem(ctPatterns, PatternIndex);
  HasChanged := true;
  Setup(ItemName);
end;

procedure TPatternEditorForm.HelpBtn1Click(Sender: TObject);
begin
  MainForm.ViewHelp('#time_patterns');
end;

procedure TPatternEditorForm.IdEditChange(Sender: TObject);
begin
  HasChanged2 := true;
end;

procedure TPatternEditorForm.OkBtnClick(Sender: TObject);
begin
  if PatternsGrid.Row > 1 then
  begin
    SelectedName := PatternsGrid.Cells[0, PatternsGrid.Row];
    SelectedIndex := PatternsGrid.Row - 1;  //Adjust for <blank> row 1
  end;
  ModalResult := mrOK;
end;

procedure TPatternEditorForm.CancelBtn1Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TPatternEditorForm.Setup(ItemName: string);
var
  I: Integer;
  StartRow: Integer;
begin
  SelectedName := '';
  SelectedIndex := 0;
  StartRow := 0;
  PatternsGrid.RowCount := project.GetItemCount(project.ctPatterns) + 2;
  PatternsGrid.Cells[0,1] := rsBlank;
  for I := 2 to PatternsGrid.RowCount - 1 do
  begin
    ShowPatternProperties(I);
    if PatternsGrid.Cells[0,I] = ItemName then StartRow := I;
  end;
  PatternsGrid.Row := StartRow;
end;

procedure TPatternEditorForm.ShowPatternProperties(I: Integer);
var
  ID: string;
  Comment: string;
begin
  // I is PatternsGrid row index where first two rows are for header
  // and the blank pattern
  ID := project.GetItemID(project.ctPatterns, I - 2);
  Comment := project.GetComment(project.ctPatterns, I - 1);
  PatternsGrid.Cells[0,I] := ID;
  PatternsGrid.Cells[1,I] := Comment;
end;

procedure TPatternEditorForm.PlotPattern(PatIndex: Integer);
var
  I:  Integer;
  N:  Integer;
  X:  Single = 0;
  Y:  Single = 0;
  T:  TimeType = 3600;
  DT: Single;
begin
  // Get pattern length
  epanet2.ENgetpatternlen(PatIndex, N);

  // Get pattern time interval in hours
  epanet2.ENgettimeparam(EN_PATTERNSTEP, T);
  DT := T / 3600.;

  // Add time, multiplier pairs to chart data series
  Chart1AreaSeries.Clear;
  Chart1AreaSeries.Active := false;
  X := 0;
  for I := 1 to N do
  begin
    epanet2.ENgetpatternvalue(PatIndex, I, Y);
    Chart1AreaSeries.AddXY(X, Y, '');
    X := X + DT;
  end;

  // Repeat final point
  if N > 0 then Chart1AreaSeries.AddXY(X, Y, '');
  Chart1AreaSeries.Active := true;
end;

////////  Notebook1 Page2 Procedures  ////////

procedure TPatternEditorForm.AcceptBtnClick(Sender: TObject);
begin
  // Retrieve edited curve data and update its display in the CurvesGrid
  if GetPatternData then
  begin
    ShowPatternProperties(PatternIndex + 1);
    PlotPattern(PatternIndex);
    PatternsGrid.Row := PatternIndex + 1;
    if HasChanged2 then HasChanged := true;
    Caption := 'Time Pattern Selector';
    Notebook1.PageIndex := 0;
    PatternsGrid.SetFocus;
  end;
end;

procedure TPatternEditorForm.CancelBtn2Click(Sender: TObject);
begin
  Caption := 'Time Pattern Selector';
  Notebook1.PageIndex := 0;
  PatternsGrid.SetFocus;
end;

procedure TPatternEditorForm.ClearBtnClick(Sender: TObject);
begin
  if utils.MsgDlg(rsPleaseConfirm, rsClearAll, mtConfirmation,
    [mbYes, mbNo], self) = mrYes then
  begin
    InitDataGrid;
    PlotPattern2;
    DataGrid.Col := 1;
    DataGrid.SetFocus;
  end;
end;

procedure TPatternEditorForm.DataGridKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if DataGrid.Col < DataGrid.ColCount - 1 then exit;
  if Key = VK_RIGHT then with DataGrid do
  begin
    ColCount := ColCount + 1;
    Cells[ColCount-1,0] := IntToStr(ColCount-1);
    Refresh;
    Col := ColCount - 1;
  end;
end;

procedure TPatternEditorForm.DataGridValidateEntry(Sender: TObject; aCol,
  aRow: Integer; const OldValue: string; var NewValue: String);
var
  S: string;
  Y: Single = 0;
begin
  S := Trim(NewValue);
  if Length(S) > 0 then
  begin
    if utils.Str2Float(S, Y) then
      PlotPattern2
    else
    begin
       utils.MsgDlg(rsInvalidData, S + rsInvalidNumber, mtError, [mbOK]);
      NewValue := OldValue;
      exit;
    end;
  end
  else
    PlotPattern2;
  if NewValue <> OldValue then HasChanged2 := true;
end;

procedure TPatternEditorForm.LoadBtnClick(Sender: TObject);
begin
  with MainForm.OpenDialog1 do
  begin
    Filter := rsPatternFiles;
    Filename := '*.pat';
    if Execute then LoadPatternData(Filename);
  end;
end;

procedure TPatternEditorForm.SaveBtnClick(Sender: TObject);
begin
  with MainForm.SaveDialog1 do
  begin
    Filter := rsPatternFiles;
    Filename := '*.pat';
    if Execute then SavePatternData(Filename);
  end;
end;

procedure TPatternEditorForm.EditPatternData;
begin
  if PatternIndex < 0 then
  begin
    OldId := projectbuilder.FindUnusedID(ctPatterns, 0);
    IdEdit.Text := OldId;
    DescripEdit.Text := '';
    InitDataGrid;
  end
  else
  begin
    OldId:= project.GetID(ctPatterns, PatternIndex);
    IdEdit.Text := OldId;
    DescripEdit.Text:= project.GetComment(ctPatterns, PatternIndex);
    SetMultipliers;
  end;
  PlotPattern2;
  HasChanged2 := false;
  Caption := 'Time Pattern Editor';
  Notebook1.PageIndex := 1;
  IdEdit.SetFocus;
end;

procedure TPatternEditorForm.SetMultipliers;
var
  I: Integer;
  Imax: Integer = 0;
  V: Single;
begin
  if PatternIndex > 0 then
  begin
    epanet2.ENgetpatternlen(PatternIndex, Imax);
    with DataGrid do
    begin
      BeginUpdate;
      if Imax > MAXPERIODS then ColCount := Imax + 1;
      for I := 1 to ColCount - 1 do
        Cells[I,0] := IntToStr(I);
      for I := 1 to Imax do
      begin
        V := 0;
        epanet2.ENgetpatternvalue(PatternIndex, I, V);
        Cells[I,1] := Float2Str(V, 4);
      end;
      EndUpdate;
    end;
  end;
end;

procedure TPatternEditorForm.GetMultipliers;
var
  Multipliers: array of Single;
  I: Integer;
  N: Integer;
begin
  N := Chart2AreaSeries.Count;
  if N <= 0 then
  begin
    N := 1;
    SetLength(Multipliers, N);
    Multipliers[0] := 1.0;
  end
  else
  begin
    SetLength(Multipliers, N);
    for I := 0 to N -1 do
    begin
      Multipliers[I] := Single(Chart2AreaSeries.GetYValue(I));
    end;
  end;
  ENsetpattern(PatternIndex, Multipliers, N);
end;

procedure TPatternEditorForm.InitDataGrid;
var
  I: Integer;
begin
  with DataGrid do
  begin
    BeginUpdate;
    ColCount := MAXPERIODS + 1;
    RowCount := 2;
    Cells[0,0] := rsPeriod;
    Cells[0,1] := rsMultiplier;
    for I := 1 to ColCount-1 do
    begin
      Cells[I,0] := IntToStr(I);
      Cells[I,1] := '';
    end;
    Cells[1,1] := '1.0';
    EndUpdate;
  end;
end;

function TPatternEditorForm.GetPatternData: Boolean;
var
  ID: string;
  Msg: string;
begin
  Result := False;
  ID := Trim(IdEdit.Text);
  if ID <> OldID then
  begin
    Msg := project.GetIdError(ctPatterns, ID);
    if Length(Msg) > 0 then
    begin
      utils.MsgDlg(rsInvalidData, Msg, mtError, [mbOK]);
      exit;
    end;
  end;

  if PatternIndex < 0 then
  begin
    if epanet2.ENaddpattern(PChar(ID)) > 0 then
    begin
      utils.MsgDlg(rsCreateFail, rsNoAddPattern, mtError, [mbOK]);
      exit;
    end;
    PatternIndex := project.GetItemCount(project.ctPatterns);
    PatternsGrid.RowCount := PatternsGrid.RowCount + 1;
    HasChanged2 := true;
  end;

  project.SetItemID(ctPatterns, PatternIndex, ID);
  epanet2.ENsetcomment(EN_TIMEPAT, PatternIndex, PAnsiChar(DescripEdit.Text));
  GetMultipliers;
  Result := true;
end;

procedure TPatternEditorForm.PlotPattern2;
var
  I: Integer;
  X: Single = 0;
  Y: Single = 0;
  T: TimeType = 3600;
  DT: Single;
begin
  // Get time interval in hours
  epanet2.ENgettimeparam(EN_PATTERNSTEP, T);
  DT := T / 3600.;

  // Set bottom axis label
  Chart2.BottomAxis.Title.Caption := rsTimePeriod +
    Format('%.2f ', [DT]) + rsHrs + ')';

  // Add time, multiplier pairs to chart data series
  with Chart2AreaSeries do
  begin
    Clear;
    Active := False;
    BeginUpdate;
    X := 0;
    with DataGrid do
    begin
      for I := 1 to ColCount-1 do
      begin
        if Length(Trim(Cells[I,1])) > 0 then
        begin
          Y := StrToFloatDef(Cells[I,1], 0);
          AddXY(X, Y, '');
          X := X + DT;
        end;
      end;
    end;

    // Repeat final point
    if Count > 0 then
    begin
      AddXY(X, Y, '');
      Active := True;
    end;
    EndUpdate;
  end;
end;

procedure TPatternEditorForm.DiurnalPatLabelClick(Sender: TObject);
var
  M, N, J:   Integer;
  I1, I2:    Integer;
  PatStep:   TimeType;
  Ratio:     Single;
  SrcIndex:  Single;
  Fraction:  Single;
  V, V1, V2: Single;
begin
  epanet2.ENgettimeparam(EN_PATTERNSTEP, PatStep);
  M := (24 * 3600) div PatStep;
  N := 24;
  Ratio := (N-1) / (M-1);
  DataGrid.ColCount := M + 1;
  DataGrid.BeginUpdate;
  for J := 0 to M - 1 do
  begin
    SrcIndex := J * Ratio;
    I1 := Trunc(SrcIndex);
    Fraction := SrcIndex - I1;
    if I1 < 0 then I1 := 0;
    if I1 >= N then
    begin
      V := DiurnalPattern[N-1];
    end
    else
    begin
      I2 := I1 + 1;
      V1 := DiurnalPattern[I1];
      V2 := DiurnalPattern[I2];
      V := V1 + (V2 - V1) * Fraction;
    end;
    DataGrid.Cells[J+1,0] := IntToStr(J+1);
    DataGrid.Cells[J+1,1] := FloatToStrF(V, ffFixed, 7, 2);
  end;
  DataGrid.EndUpdate;
  PlotPattern2;
  HasChanged2 := true;
end;

procedure TPatternEditorForm.LoadPatternData(Filename: string);
var
  I: Integer;
  J: Integer;
  K: Integer;
  Y: Single;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(Filename);
    K := Lines.Count - 2;  //1st two lines are a header & description
    if K > 0 then
    begin
      DescripEdit.Text := Lines[1];
      with DataGrid do
      begin
        BeginUpdate;
        ColCount := K + 1;  //Account for header column
        J := 2;             //Index of 1st multiplier in file
        for I := 1 to K do
        begin
          Cells[I, 0] := IntToStr(I);
          if not utils.Str2Float(Lines[J], Y) then
            Cells[I, 1] := '0.0000'
          else
            Cells[I, 1] := Lines[J];
          Inc(J);
        end;
        EndUpdate;
      end;
    end;
    PlotPattern2;
    HasChanged2 := true;
  finally
    Lines.Free;
  end;
end;

procedure TPatternEditorForm.SavePatternData(Filename: string);
var
  I: Integer;
  Lines: TStringList;
begin
  Lines := TStringList.Create;
  try
    Lines.Add(rsPatternHeader);
    Lines.Add(DescripEdit.Text);
    with DataGrid do
    begin
      for I := 1 to ColCount - 1 do
        Lines.Add(Cells[I,1]);
    end;
    Lines.SaveToFile(Filename);
  finally
    Lines.Free;
  end;
end;


end.

