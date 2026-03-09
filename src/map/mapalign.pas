{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mapalign
 Description:  a frame used to align a network with a basemap image
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit mapalign;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Grids,
  Dialogs, mapcoords;

type

  { TMapAlignFrame }

  TMapAlignFrame = class(TFrame)
    CancelBtn:    TButton;
    GoAlignBtn:   TButton;
    CloseBtn:     TSpeedButton;
    Label1:       TLabel;
    StringGrid1:  TStringGrid;
    TaskDialog1:  TTaskDialog;
    TopPanel:     TPanel;

    procedure GoAlignBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);

  private
    function DataIsValid: Boolean;
    function ConfirmAlignment: Boolean;
    procedure DoInverseTransform(ax, bx, cx, ay, by, cy: Double);

  public
    procedure Show;
    procedure SetNode(aItem: Integer);
    procedure SetLocation(XY: TDoublePoint);

  end;

implementation

{$R *.lfm}

uses
  main, project, config, utils, resourcestrings;

const
  MAX_ROWS = 6;
  MAX_COLS = 7;     // max rows + 1 for augmented matrix
  EPSILON  = 1E-10; // Small value for floating-point comparisons

type
  TMatrix = array[1..MAX_ROWS, 1..MAX_COLS] of Double;

var
  Xnode: array[1..3] of Double;
  Ynode: array[1..3] of Double;
  Xbmap: array[1..3] of Double;
  Ybmap: array[1..3] of Double;
  A: TMatrix;

function SolveLinearEquations(var matrix: TMatrix;
  rows, cols: Integer): Boolean; forward;

procedure TMapAlignFrame.CloseBtnClick(Sender: TObject);
begin
  Visible := false;
end;

procedure TMapAlignFrame.CancelBtnClick(Sender: TObject);
begin
  Visible := false;
end;

procedure TMapAlignFrame.GoAlignBtnClick(Sender: TObject);
var
  I: Integer;
  J: Integer;
begin
  // Check that data points are valid
  if not DataIsValid then
  begin
    utils.MsgDlg(rsInvalidSelect, rsManualAlign, mtInformation, [mbOk]);
    exit;
  end;

  // Zero-out coeff. matrix
  for I := 1 to 6 do
    for J := 1 to 7 do
      A[I,J] := 0;

  // Add data point coords. to coeff. matrix
  for I := 1 to 3 do
  begin
    A[I,1] := Xnode[I];
    A[I,2] := Ynode[I];
    A[I,3] := 1;
    A[I,7] := Xbmap[I];
    J := I + 3;
    A[J,4] := Xnode[I];
    A[J,5] := Ynode[I];
    A[J,6] := 1;
    A[J,7] := Ybmap[I];
  end;

  // Solve for affine transform coeffs.
  if not SolveLinearEquations(A, 6, 7) then
  begin
    utils.MsgDlg(rsTransFail, rsNoAlign, mtInformation, [mbOk]);
    exit;
  end;
  mapcoords.DoAffineTransform(A[1,7], A[2,7], A[3,7], A[4,7], A[5,7], A[6,7]);
  MainForm.MapFrame.DrawFullExtent;
  if not ConfirmAlignment then
  begin
    DoInverseTransform(A[1,7], A[2,7], A[3,7], A[4,7], A[5,7], A[6,7]);
    MainForm.MapFrame.DrawFullExtent;
  end;
  Visible := false;
end;

function TMapAlignFrame.DataIsValid: Boolean;
var
  I: Integer;
begin
  Result := false;
  for I := 1 to 3 do
  begin
    if Length(StringGrid1.Cells[0,I]) = 0 then exit;
    if Length(StringGrid1.Cells[1,I]) = 0 then exit;
  end;
  Result := true;
end;

function TMapAlignFrame.ConfirmAlignment: Boolean;
begin
  Result := false;
  if TaskDialog1.Execute then
      if TaskDialog1.ModalResult = 100 then
        Result := true;
end;

procedure TMapAlignFrame.DoInverseTransform(ax, bx, cx, ay, by, cy: Double);
var
  D: Double;
  Axx: Double;
  Bxx: Double;
  Cxx: Double;
  Ayy: Double;
  Byy: Double;
  Cyy: Double;
begin
  D := (ax * by) - (bx * ay);
  Axx := by / D;
  Bxx := -bx / D;
  Cxx := (bx*cy - by*cx) / D;
  Ayy := -ay / D;
  Byy := ax / D;
  Cyy := (ay*cx - ax*cy) / D;
  mapcoords.DoAffineTransform(Axx, Bxx, Cxx, Ayy, Byy, Cyy);
end;

procedure TMapAlignFrame.Show;
var
  I: Integer;
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  StringGrid1.FixedColor := Color;
  StringGrid1.ColWidths[1] := 2 * StringGrid1.ColWidths[0] - 2;
  StringGrid1.Clean;
  StringGrid1.Cells[0,0] := rsNode;
  StringGrid1.Cells[1,0] := rsNewLocation;
  StringGrid1.Row := 0;
  StringGrid1.Col := 0;
  Visible := true;
  StringGrid1.SetFocus;
  for I := 1 to 3 do
  begin
    Xnode[I] := 0;
    Ynode[I] := 0;
    Xbmap[I] := 0;
    Ybmap[I] := 0;
  end;
end;

procedure TMapAlignFrame.SetNode(aItem: Integer);
var
  R: Integer;
begin
  if StringGrid1.Col = 0 then
  begin
    R := StringGrid1.Row;
    StringGrid1.Cells[0, R] := project.GetItemID(ctNodes, aItem);
    project.GetNodeCoord(aItem+1, Xnode[R], Ynode[R]);
    StringGrid1.Cells[1, R] := '';
  end;
end;

procedure TMapAlignFrame.SetLocation(XY: TDoublePoint);
var
  R: Integer;
begin
  if StringGrid1.Col = 1 then
  begin
    R := StringGrid1.Row;
    if Length(StringGrid1.Cells[0, R]) = 0 then exit;
    StringGrid1.Cells[1,R] := Format('%.4f , %.4f',[XY.X, XY.Y]);
    Xbmap[R] := XY.X;
    Ybmap[R] := XY.Y;
  end
  else StringGrid1.Col := 1;
end;

function SolveLinearEquations(var Matrix: TMatrix; Rows, Cols: Integer): Boolean;
var
  I:      Integer;
  J:      Integer;
  K:      Integer;
  Pivot:  Double;
  Factor: Double;
begin
  // Gaussian elimination with partial pivoting
  for I := 1 to Rows do
  begin
    // Partial pivoting
    for J := I + 1 to Rows do
    begin
      if Abs(Matrix[J, I]) > Abs(Matrix[I, I]) then
      begin
        for K := I to Cols do
        begin
          Pivot := Matrix[I, K];
          Matrix[I, K] := Matrix[J, K];
          Matrix[J, K] := Pivot;
        end;
      end;
    end;

    // Check for near-zero pivot
    if Abs(Matrix[I, I]) < EPSILON then
    begin
      exit(false);
    end;

    // Eliminate column
    for J := I + 1 to Rows do
    begin
      Factor := Matrix[J, I] / Matrix[I, I];
      for K := I to Cols do
        Matrix[J, K] := Matrix[J, K] - Factor * Matrix[I, K];
    end;
  end;

  // Back substitution
  for I := Rows downto 1 do
  begin
    Matrix[I, Cols] := Matrix[I, Cols] / Matrix[I, I];
    for J := I - 1 downto 1 do
      Matrix[J, Cols] := Matrix[J, Cols] - Matrix[J, I] * Matrix[I, Cols];
  end;

  Result := true;
end;

end.

