{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       curveeditor
 Description:  a form that manages a project's set of Data Curves
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit curveeditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Grids,
  LCLtype, ExtCtrls, TAGraph, TASeries;

type

  { TCurveEditorForm }

  TCurveEditorForm = class(TForm)
    Notebook1:    TNotebook;
    Page1:        TPage;
    Page2:        TPage;
    AddBtn:       TButton;
    OkBtn:        TButton;
    AcceptBtn:    TButton;
    CancelBtn1:   TButton;
    CancelBtn2:   TButton;
    ClearBtn:     TButton;
    DeleteBtn:    TButton;
    EditBtn:      TButton;
    HelpBtn1:     TButton;
    HelpBtn2:     TButton;
    CurvesGrid:   TStringGrid;
    DataGrid:     TStringGrid;
    IdEdit:       TEdit;
    DescripEdit:  TEdit;
    TypeCombo:    TComboBox;
    Label1:       TLabel;
    Label2:       TLabel;
    Label3:       TLabel;
    Label4:       TLabel;
    PreviewChart: TChart;
    DataSeries1:  TLineSeries;

    procedure AcceptBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CancelBtn2Click(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure DataGridValidateEntry(Sender: TObject; aCol, aRow: Integer;
      const OldValue: string; var NewValue: String);
    procedure DeleteBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HelpBtn1Click(Sender: TObject);
    procedure IdEditChange(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure CancelBtn1Click(Sender: TObject);
    procedure CurvesGridClick(Sender: TObject);
    procedure CurvesGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure TypeComboChange(Sender: TObject);

  private
    CurveIndex:   Integer;
    CurveType:    Integer;
    HasChanged2:  Boolean;
    OldId:        string;

    procedure EditCurveData;
    function  GetCurveData: Boolean;
    procedure PlotCurve;
    procedure ShowCurveProperties(I: Integer);

    function  CurveNameValid(ID: string): Boolean;
    function  CurveDataValid(X: array of Single; Y: array of Single;
              N: Integer): Boolean;
    procedure ExtractCurveData(var X: array of Single; var Y: array of Single;
              var N: Integer);

  public
    HasChanged: Boolean;
    SelectedName: string;
    SelectedIndex: Integer;
    procedure Setup(ItemName: string);

  end;

var
  CurveEditorForm: TCurveEditorForm;

implementation

{$R *.lfm}

uses
  main, project, projectbuilder, curveviewer, config, utils, epanet2,
  resourcestrings;

const
  XLabel: array[0..5] of string =
    (rsDepth, rsFlow, rsFlow, rsFlow, rsX, rsPcntOpen);

  YLabel: array[0..5] of string =
    (rsVolume, rsHead, rsEfficiency, rsHead_Loss, rsY, rsPcntFullFlow);

{ TCurveEditorForm }

procedure TCurveEditorForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  CurvesGrid.FixedColor := Color;
  Font.Size := config.FontSize;
  TypeCombo.Items.AddStrings(Project.CurveTypeStr, true);
  with DataGrid do
  begin
    Cells[0,0] := XLabel[ctGeneric];
    Cells[1,0] := YLabel[ctGeneric];
  end;
end;

procedure TCurveEditorForm.CurvesGridClick(Sender: TObject);
var
  I: Integer;
begin
  I := CurvesGrid.Row - 1;
  EditBtn.Enabled := I > 0;
  DeleteBtn.Enabled := I > 0;
end;

procedure TCurveEditorForm.CurvesGridPrepareCanvas(Sender: TObject; aCol,
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

procedure TCurveEditorForm.HelpBtn1Click(Sender: TObject);
begin
  MainForm.ViewHelp('#data_curves');
end;

procedure TCurveEditorForm.OkBtnClick(Sender: TObject);
begin
  with CurvesGrid do
  begin
    if Row > 1 then
    begin
      SelectedName := Cells[0, Row];
      SelectedIndex := Row - 1;  //Adjust for <blank> row 1
    end;
  end;
  ModalResult := mrOK;
end;

procedure TCurveEditorForm.CancelBtn1Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TCurveEditorForm.EditBtnClick(Sender: TObject);
begin
  // Convert selected grid row value to EPANET curve index
  CurveIndex := CurvesGrid.Row - 1;

  // Call Curve editor if selected row greater than first "blank" row
  if CurveIndex >= 1 then EditCurveData;
end;

procedure TCurveEditorForm.AddBtnClick(Sender: TObject);
begin
  // Edit data for non-existent curve - it will
  // create the curve and return its index if not cancelled
  CurveIndex := -1;
  EditCurveData;
end;

procedure TCurveEditorForm.DeleteBtnClick(Sender: TObject);
var
  Msg: string;
  ItemName: string;
begin
  // EPANET index corresponding to current selected row of CurvesGrid
  // (1-based and accounting for <blank> 1st row)
  CurveIndex := CurvesGrid.Row - 1;
  if CurveIndex < 1 then exit;
  ItemName := CurvesGrid.Cells[0,CurveIndex];

  // Verify deletion using 0-based index
  if config.ConfirmDeletions then
  begin
    Msg := Format(rsWishToDelete,
      [project.GetItemTypeStr(ctCurves, CurveIndex - 1),
       project.GetItemID(ctCurves, CurveIndex - 1)]);
    if utils.MsgDlg(rsConfirmDelete, Msg, mtConfirmation,
      [mbYes, mbNo]) = mrNo then exit;
  end;

  // Delete item from project and update CurvesGrid
  project.DeleteItem(ctCurves, CurveIndex);
  HasChanged := true;
  Setup(ItemName);
end;

procedure TCurveEditorForm.Setup(ItemName: string);
var
  I: Integer;
  StartRow: Integer;
begin
  SelectedName := '';
  SelectedIndex := 0;
  StartRow := 0;
  with CurvesGrid do
  begin
    RowCount := project.GetItemCount(project.ctCurves) + 2;
    Cells[0,1] := rsBlank;
    for I := 2 to RowCount - 1 do
    begin
      ShowCurveProperties(I);
      if Cells[0,I] = ItemName then StartRow := I
    end;
    Row := StartRow;
  end;
end;

procedure TCurveEditorForm.ShowCurveProperties(I: Integer);
var
  Ctype: Integer;
begin
  // I is a row index in the CurvesGrid whose Row 1 is reserved for
  // no curve. Hence I-1 is the 1-based index of the curve in that
  // row while I-2 is its 0-based item index.
  with CurvesGrid do
  begin
    Cells[0,I] := project.GetItemID(project.ctCurves, I - 2);
    Ctype := project.GetCurveType(I - 1);
    Cells[1,I] := project.CurveTypeStr[Ctype];
    Cells[2,I] := project.GetComment(project.ctCurves, I - 1);
  end;
end;

////////  Notebook1 Page2 Procedures  ////////

procedure TCurveEditorForm.AcceptBtnClick(Sender: TObject);
begin
  // Retrieve edited curve data and update its display in the CurvesGrid
  if GetCurveData then
  begin
    ShowCurveProperties(CurveIndex + 1);
    CurvesGrid.Row := CurveIndex + 1;
    if HasChanged2 then HasChanged := true;
    Caption := 'Data Curve Selector';
    Notebook1.PageIndex := 0;
    CurvesGrid.SetFocus;
  end;
end;

procedure TCurveEditorForm.CancelBtn2Click(Sender: TObject);
begin
  Caption := 'Data Curve Selector';
  Notebook1.PageIndex := 0;
  CurvesGrid.SetFocus;
end;

procedure TCurveEditorForm.ClearBtnClick(Sender: TObject);
begin
  DataGrid.Clean([gzNormal, gzFixedCells]);
  DataGrid.RowCount := 2;
  DataGrid.Row := 1;
  DataGrid.Col := 0;
  PlotCurve;
  DataGrid.SetFocus;
end;

procedure TCurveEditorForm.IdEditChange(Sender: TObject);
begin
  HasChanged2 := true;
end;

procedure TCurveEditorForm.TypeComboChange(Sender: TObject);
begin
  CurveType := TypeCombo.ItemIndex;
  with DataGrid do
  begin
    Cells[0,0] := XLabel[CurveType];
    Cells[1,0] := YLabel[CurveType];
  end;
  PlotCurve;
  HasChanged2 := true;
end;

procedure TCurveEditorForm.DataGridValidateEntry(Sender: TObject; aCol,
  aRow: Integer; const OldValue: string; var NewValue: String);
var
  S: string;
  Y: Single;
begin
  Y := 0;
  S := Trim(NewValue);
  if Length(S) > 0 then
  begin
    if utils.Str2Float(S, Y) then PlotCurve
    else
    begin
      utils.MsgDlg(rsInvalidData, S + rsInvalidNumber, mtError, [mbOK]);
      NewValue := OldValue;
      exit;
    end;
  end
  else
    PlotCurve;
  if NewValue <> OldValue then HasChanged2 := true;
end;

procedure TCurveEditorForm.EditCurveData;
var
  I : Integer;
  N : Integer;
  X : Single;
  Y : Single;
begin
  N := 0;
  X := 0;
  Y := 0;
  Notebook1.PageIndex := 1;

  // Editing a new curve
  if CurveIndex < 0 then
  begin
    OldId := projectbuilder.FindUnusedID(ctCurves, 0);
    IdEdit.Text := OldId;
    DescripEdit.Text := '';
    ClearBtnClick(self);
    TypeCombo.ItemIndex := ctGeneric;
    TypeComboChange(self);
  end

  // Editing an existing curve
  else
  begin
    epanet2.ENgetcurvelen(CurveIndex, N);
    epanet2.ENgetcurvetype(CurveIndex, CurveType);
    OldId:= project.GetID(ctCurves, CurveIndex);
    IdEdit.Text := OldId;
    TypeCombo.ItemIndex := CurveType;
    DescripEdit.Text:= project.GetComment(ctCurves, CurveIndex);
    with DataGrid do
    begin
      BeginUpdate;
      RowCount := N + 2;
      Cells[0,0] := XLabel[CurveType];
      Cells[1,0] := YLabel[CurveType];
      for I := 1 to N do
      begin
        epanet2.ENgetcurvevalue(CurveIndex, I, X, Y);
        Cells[0,I] := Float2Str(X, 4);
        Cells[1,I] := Float2Str(Y, 4);
      end;
      EndUpdate;
    end;
  end;

  PlotCurve;
  HasChanged2 := false;
  Caption := 'Data Curve Editor';
  IdEdit.SetFocus;
end;

function TCurveEditorForm.GetCurveData: Boolean;
var
  X : array of Single;
  Y : array of Single;
  N : Integer;
  ID: string;
begin
  // Check for valid curve ID
  Result := false;
  ID := Trim(IdEdit.Text);
  if not CurveNameValid(ID) then exit;

  // Extract X, Y values from grid's cells
  N := DataGrid.RowCount - 1;
  SetLength(X, N);
  SetLength(Y, N);
  ExtractCurveData(X, Y, N);
  if not CurveDataValid(X, Y, N) then exit;

  // Create new curve if not editing an existing curve
  if CurveIndex < 0 then
  begin
    if epanet2.ENaddcurve(PChar(ID)) > 0 then
    begin
      utils.MsgDlg(rsCreateFail, rsNoAddCurve, mtError, [mbOK]);
      exit;
    end;
    CurveIndex := project.GetItemCount(project.ctCurves);
    CurvesGrid.RowCount := CurvesGrid.RowCount + 1;
    HasChanged2 := true;
  end;

  // Assign curve properties
  project.SetItemID(ctCurves, CurveIndex, ID);
  epanet2.ENsetcurve(CurveIndex, X[0], Y[0], N);
  epanet2.ENsetcurvetype(CurveIndex, TypeCombo.ItemIndex);
  epanet2.ENsetcomment(EN_CURVE, CurveIndex, PAnsiChar(DescripEdit.Text));
  Result := true;
end;

function TCurveEditorForm.CurveNameValid(ID: string): Boolean;
var
  Msg: string;
begin
  Result := true;
  if ID <> OldID then
  begin
    Msg := project.GetIdError(ctCurves, ID);
    if Length(Msg) > 0 then
      utils.MsgDlg(rsInvalidData, Msg, mtError, [mbOK]);
    Result := false;
   end;
end;

procedure TCurveEditorForm.ExtractCurveData(var X: array of Single;
  var Y: array of Single; var N: Integer);
var
  XX: Single;
  YY: Single;
  I:  Integer;
begin
  XX := 0;
  YY := 0;
  N := 0;
  with DataGrid do
  begin
    for I := 1 to RowCount-1 do
    begin
      if utils.Str2Float(Cells[0,I], XX)
      and utils.Str2Float(Cells[1,I], YY) then
      begin
        X[N] := XX;
        Y[N] := YY;
        Inc(N);
      end;
    end;
  end;
end;

function TCurveEditorForm.CurveDataValid(X: array of Single; Y: array of Single;
  N: Integer): Boolean;
var
  I: Integer;
begin
  // Check for at least one data point
  Result := false;
  if N = 0 then
  begin
    utils.MsgDlg(rsMissingData, rsCurveNodata, mtError, [mbOK]);
    exit;
  end;

  // Check for valid X-values
  for I := 1 to N-1 do
  begin
    if X[I-1] > X[I] then
    begin
      DataGrid.Row := I;
      utils.MsgDlg(rsInvalidData, rsInvalidCurve, mtError, [mbOK]);
      exit;
    end;
  end;
  Result := true;
end;

procedure TCurveEditorForm.PlotCurve;
var
  X: array of Double;
  Y: array of Double;
  A: Single;
  B: Single;
  I: Integer;
  N: Integer;
begin
  PreviewChart.BottomAxis.Title.Caption := XLabel[CurveType];
  PreviewChart.LeftAxis.Title.Caption := YLabel[CurveType];
  N := DataGrid.RowCount - 1;
  SetLength(X, N);
  SetLength(Y, N);
  N := 0;
  with DataGrid do for I := 1 to RowCount - 1 do
  begin
    if Utils.Str2Float(Cells[0,I], A)
    and Utils.Str2Float(Cells[1,I], B) then
    begin
      X[N] := A;
      Y[N] := B;
      Inc(N);
    end;
  end;
  curveviewer.PlotCurve(PreviewChart, CurveType, X, Y, N);
  SetLength(X, 0);
  Setlength(Y, 0);
end;

end.

