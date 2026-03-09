{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       curveviewer
 Description:  displays an EPANET Data Curve in a TChart component
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit curveviewer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, TAGraph, TASeries, Math;

procedure PlotCurve(aChart: TChart; CurveType: Integer;
  X, Y: array of double; N: Integer);

implementation

uses
  project, utils, resourcestrings;

const
  TINY: Double = 1.e-6;

var
  DataSeries: TLineSeries;

function FindPumpCurveCoeffs(Q: array of Double; H: array of Double;
  var A: Double; var B: Double; var C: Double): Boolean;
var
  H4: Double;
  H5: Double;
//  A1: Double;
//  Iter: Integer;
begin
  Result := false;
  if (H[0] < TINY)
  or (H[0] - H[1] < TINY)
  or (H[1] - H[2] < TINY)
  or (Q[1] < TINY) or (Q[2] - Q[1] < TINY) then exit;

  A  := H[0];
  H4 := H[0] - H[1];
  H5 := H[0] - H[2];
  C  := Ln(H5 / H4) / Ln(Q[2] / Q[1]);
  if (C <= 0.0) or (C > 20.0) then exit;
  B := -H4 / Q[1]**C;
  if B >= 0 then exit;
{
// This code can be used to estimate A when Q[0] <> 0
  A := H[0];
  B := 0;
  C := 1.0;
  for Iter := 1 to 5 do
  begin
    H4 := A - H[1];
    H5 := A - H[2];
    C := Ln(H5 / H4) / Ln(Q[2] / Q[1]);
    if (C <= 0.0) or (C > 20.0) then break;
    B := -H4 / Power(Q[1], C);
    if B > 0.0 then break;
    A1 := H[0] - B * Power(Q[0], C);
    if Abs(A1 - A) < 0.01 then
    begin
      Result := true;
      break;
    end;
    A := A1;
  end;
}
  Result := true;
end;

function AddPumpCurvePts(Q: array of Double; H: array of Double):
  Boolean;
var
  Dx: Double;
  A: Double;
  B: Double;
  C: Double;
  Qmax: Double;
  X: Double;
  Y: Double;
  I: Integer;
begin
  Result := true;
  A := 0;
  B := 0;
  C := 0;
  if not FindPumpCurveCoeffs(Q, H, A, B, C) then
  begin
    Utils.MsgDlg(rsInvalidData, rsBadPumpCurve, mtInformation, [mbOK]);
    Result := false;
  end
  else
  begin
    Qmax := (-A/B)**(1/C);
    Dx := Qmax / 25.;
    with DataSeries do
    begin
      ShowPoints := false;
      AddXY(0.0, A);
      X := 0.0;
      for I := 1 to 24 do
      begin
        X := X + Dx;
        Y := A + B * X ** C;
        AddXY(X, Y);
      end;
      AddXY(Qmax, 0.0);
    end;
  end;
end;

function Plot1PointPumpCurve(X0, Y0: Double): Boolean;
var
  H: array[0..2] of Double;
  Q: array[0..2] of Double;
begin
  Q[1] := X0;
  H[1] := Y0;
  Q[0] := 0;
  H[0] := 1.33334 * H[1];
  Q[2] := 2 * Q[1];
  H[2] := 0;
  Result := AddPumpCurvePts(Q, H);
end;

function Plot3PointPumpCurve(X, Y: array of Double): Boolean;
var
  H: array[0..2] of Double;
  Q: array[0..2] of Double;
  I: Integer;
begin
  for I := 0 to 2 do
  begin
    Q[I] := X[I];
    H[I] := Y[I];
  end;
  Result := AddPumpCurvePts(Q, H);
end;

procedure FindEfficCurveCoeffs(Qstar: Double; Estar: Double;
  var Qmax: Double; var A: Double; var B: Double; var C: Double);
var
  Denom: Double;
  Qstar2: Double;
begin
  if (Qstar > 2.0/3.0 * Qmax) then Qmax := 3 * Qstar / 2;
  Qstar2 := Qstar * Qstar;
  Denom := -Qstar2 * (Qmax - Qstar) * (Qmax - Qstar);
  A := (Estar * (2.0 * Qstar - Qmax)) / Denom;
  B := -Estar * (3.0 * Qstar2 - (Qmax * Qmax)) / Denom;
  C := (Estar * Qstar * Qmax * (3.0 * Qstar - 2.0 * Qmax)) / Denom;
end;

procedure AddEfficCurvePts(Qmax: Double; A: Double; B: Double;
  C: Double);
var
  X: Double;
  Y: Double;
  Dx: Double;
  I: Integer;
begin
  Dx := Qmax / 25.;
  with DataSeries do
  begin
    ShowPoints := false;
    AddXY(0.0, 0.0);
    X := 0.0;
    for I := 1 to 24 do
    begin
      X := X + Dx;
      Y := (C + X * (B + A * X)) * X;
      if Y < 0 then exit;
      AddXY(X, Y);
    end;
    AddXY(Qmax, 0.0);
  end;
end;

function PlotEfficCurve(X, Y: array of Double; N: Integer): Boolean;
var
  Qstar: Double;
  Estar: Double;
  Qmax: Double;
  A: Double = 0;
  B: Double = 0;
  C: Double = 0;
begin
  Result := false;
  if N = 1 then
  begin
    if (X[0] = 0)
    or (Y[0] = 0) then
      exit;
    Qstar := X[0];
    Estar := Y[0];
    Qmax := 2 * Qstar;
  end
  else if N = 2 then
  begin
    if (X[0] = 0)
    or (Y[0] = 0)
    or (Y[1] <> 0) then
      exit;
    Qstar := X[0];
    Estar := Y[0];
    Qmax := X[1];
  end
  else
    exit;
  FindEfficCurveCoeffs(Qstar, Estar, Qmax, A, B, C);
  AddEfficCurvePts(Qmax, A, B, C);
  Result := true;
end;

procedure PlotCurve(aChart: TChart; CurveType: Integer;
  X, Y: array of double; N: Integer);
var
  I: Integer;
  FunctionPlot: Boolean;
begin
  // Add points to the chart's LineSeries
  if not aChart.Series[0].ClassNameIs('TLineSeries') then exit;
  DataSeries := TLineSeries(aChart.Series[0]);
  with DataSeries do
  begin
    Clear;
    Active := false;
    BeginUpdate;
    FunctionPlot := false;

    // Plot functional pump curve
    if (CurveType = ctPump)
    and (N = 1) and (X[0] > 0) then
      FunctionPlot := Plot1PointPumpCurve(X[0], Y[0])
    else if (CurveType = ctPump)
    and (N = 3) and (X[0] = 0) then
      FunctionPlot := Plot3PointPumpCurve(X, Y)

    // Plot constant efficiency curve
    else if (CurveType = ctEffic)
    and (N = 1) then
    begin
      FunctionPlot := true;
      AddXY(0, Y[0], '');
      AddXY(2*X[0], Y[0], '');
    end;

    // Plot piece-wise linear curve
    if not FunctionPlot then for I := 0 to N - 1 do
        AddXY(X[I], Y[I], '');

    EndUpdate;
    Active := true;
  end;
end;

end.

