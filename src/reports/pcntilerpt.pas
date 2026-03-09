{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       pcntilerpt
 Description:  a frame that plots percentile ranges
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit pcntilerpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Menus, Buttons, Dialogs,
  TAGraph, TASeries, TASources, TAStyles, TAGUIConnectorBGRA,
  Graphics, fgl, TACustomSeries, TATransformations, TAIntervalSources,
  TAChartUtils;

type
  TDoubleList = specialize TFPGList<Double>;

  { TPcntileRptFrame }

  TPcntileRptFrame = class(TFrame)
    Chart1:                       TChart;
    Chart1AreaSeries1:            TAreaSeries;
    Chart1LineSeries1:            TLineSeries;
    Chart1LineSeries2:            TLineSeries;
    ChartAxisTransformations1:    TChartAxisTransformations;
    ChartAxisTransformations1AutoScaleAxisTransform1: TAutoScaleAxisTransform;
    ChartGUIConnectorBGRA1:       TChartGUIConnectorBGRA;
    ChartStyles1:                 TChartStyles;
    DateTimeIntervalChartSource1: TDateTimeIntervalChartSource;
    ListChartSource1:             TListChartSource;
    Panel1:                       TPanel;
    ExportMenu:                   TPopupMenu;
    MnuSettings:                  TMenuItem;
    Separator1:                   TMenuItem;
    MnuCopy:                      TMenuItem;
    MnuSave:                      TMenuItem;

    procedure MnuCopyClick(Sender: TObject);
    procedure MnuSaveClick(Sender: TObject);
    procedure MnuSettingsClick(Sender: TObject);

  private
    PlotTimeOfDay:  Boolean;
    PlotParam:      Integer;
    ParamType:      Integer;
    Pmin:           Integer;
    Pmid:           Integer;
    Pmax:           Integer;
    Y1:             Double;
    Y2:             Double;
    Ymin:           Double;
    Ymax:           Double;
    Vlist:          TDoubleList;

    procedure SetupChartAxes;
    procedure GetPlotParamRange(T: Integer);
    function  GetNodeParamValue(I, T: Integer): Single;
    function  GetLinkParamValue(I, T: Integer): Single;
    function  GetListIndex(P, N: Integer): Integer;
    procedure PlotSinglePeriodResults;

  public
    ChartIsShowing: Boolean;

    procedure InitReport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure CloseReport;
    procedure ShowPopupMenu;
    procedure ShowPercentileSelector;
    procedure SetPlotParams(aParamType, aPlotParam, aPmin, aPmid, aPmax: Integer;
      aPlotTimeOfDay: Boolean);
  end;

implementation

{$R *.lfm}

uses
  main, project, mapthemes, results, resourcestrings;

{ TPcntileRptFrame }

function DoubleCompare(const A, B: Double): Integer;
begin
  if A > B then
    Result := 1
  else if A < B then
    Result := -1
  else
    result := 0;
end;

procedure TPcntileRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TPcntileRptFrame.MnuCopyClick(Sender: TObject);
begin
  Chart1.CopyToClipboardBitmap;
end;

procedure TPcntileRptFrame.MnuSaveClick(Sender: TObject);
begin
  with MainForm.SaveDialog1 do
  begin
    FileName := '*.png';
    Filter := rsPngFile;
    DefaultExt := '*.png';
    if Execute then Chart1.SaveToFile(TPortableNetworkGraphic, FileName);
  end;
end;

procedure TPcntileRptFrame.MnuSettingsClick(Sender: TObject);
begin
  ShowPercentileSelector;
end;

procedure TPcntileRptFrame.ShowPercentileSelector;
begin
  MainForm.HideHintPanelFrames;
  MainForm.PcntileSelectorFrame.Show;
  MainForm.PcntileSelectorFrame.Init(ParamType, PlotParam, Pmin, Pmid, Pmax,
    PlotTimeOfDay);
end;

procedure TPcntileRptFrame.SetPlotParams(aParamType, aPlotParam, aPmin, aPmid,
  aPmax: Integer; aPlotTimeOfDay: Boolean);
begin
  ParamType := aParamType;
  PlotParam := aPlotParam;
  Pmin := aPmin;
  Pmid := aPmid;
  Pmax := aPmax;
  PlotTimeOfDay := aPlotTimeOfDay;
end;

procedure TPcntileRptFrame.InitReport;
begin
  ChartIsShowing := false;
  SetPlotParams(ctNodes, ntPressure, 5, 50, 95, false);
  ShowPercentileSelector;
end;

procedure TPcntileRptFrame.CloseReport;
begin
  ClearReport;
  MainForm.PcntileSelectorFrame.Hide;
end;

procedure TPcntileRptFrame.ClearReport;
begin
  ListChartSource1.Clear;
  Chart1LineSeries1.Clear;
  Chart1LineSeries2.Clear;
end;

procedure TPcntileRptFrame.RefreshReport;
var
  T:      Integer;
  Dt:     Integer;
  X:      TDateTime;
  Xstart: TDateTime;
  Xstep:  TDateTime;
begin
  // Setup chart axes
  SetupChartAxes;

  // Generate full frequency plot for single period run
  if results.Nperiods = 1 then
  begin
    PlotSinglePeriodResults;
    exit;
  end;

  // Setup legend text
  Chart1.Legend.Visible := true;
  Chart1LineSeries1.Title := IntToStr(Pmin) + rsPercentile;
  Chart1LineSeries2.Title := IntToStr(Pmax) + rsPercentile;
  Chart1AreaSeries1.Title := IntToStr(50 - (Pmid div 2)) + rsThTo + ' ' +
                             IntToStr(50 + (Pmid div 2)) + rsPercentile;

  // Find number of reporting steps between each hour
  Dt := 1;
  if results.Duration > 6 * 3600 then
    Dt := 3600 div results.Rstep;
  if Dt < 1 then Dt := 1;

  // Set start time and report step to hours
  Xstart := results.Rstart / 3600;
  Xstep := results.Rstep / 3600;

  // Set to decimal days if plotting time of day
  if PlotTimeOfDay then
  begin
    Xstart := (Xstart + project.StartTime / 3600) / 24;
    Xstep := Xstep / 24;
  end;

  // Clear each data series
  MainForm.Cursor:= crHourglass;
  ClearReport;
  Chart1LineSeries1.LinePen.Style := psDash;

  // Create a list of doubles
  Vlist := TDoubleList.Create;
  try

    // Populate the chart with PlotParam's range for each hour
    T := 0;
    while T < results.Nperiods do
    begin
      Vlist.Clear;
      GetPlotParamRange(T);
      X := Xstart + (T * Xstep);
      with ListChartSource1 do AddXYList(X, [Y1, Y2]);
      Chart1LineSeries1.AddXY(X, Ymin);
      Chart1LineSeries2.AddXY(X, Ymax);
      T := T + Dt;
    end;
    ChartIsShowing := true;
  finally
    MainForm.Cursor := crDefault;
    Vlist.Free;
  end;
end;

procedure TPcntileRptFrame.SetupChartAxes;
var
  S: string;
begin
  // Assign chart title and left axis title
  if ParamType = ctNodes then
    S := mapthemes.NodeThemes[PlotParam].Name
  else
    S := mapthemes.LinkThemes[PlotParam].Name;
  Chart1.Title.Text.Clear;
  Chart1.Title.Text.Add(rsVariationIn + ' ' + S);
  Chart1.leftAxis.Title.Caption :=
    mapthemes.GetThemeUnits(ParamType, PlotParam);

  // For single period run
  if results.Nperiods = 1 then
  begin
    Chart1.BottomAxis.Marks.Style := smsValue;
    Chart1.BottomAxis.Marks.Source := nil;
    Chart1.BottomAxis.Title.Visible := true;
    Chart1.BottomAxis.Title.Caption := 'Percent of Network Less Than';
    exit;
  end;

  // Setup bottom axis
  Chart1.BottomAxis.Title.Caption := 'Hour';
  if PlotTimeOfDay then
  begin
    Chart1.BottomAxis.Marks.Style := smsLabel;
    Chart1.BottomAxis.Marks.Source := DateTimeIntervalChartSource1;
    Chart1.BottomAxis.Title.Visible := false;
  end
  else
  begin
    Chart1.BottomAxis.Marks.Style := smsValue;
    Chart1.BottomAxis.Marks.Source := nil;
    Chart1.BottomAxis.Title.Visible := true;
  end;
end;

procedure TPcntileRptFrame.PlotSinglePeriodResults;
const
  MAXPTS = 100;
var
  N: Integer;
  I: Integer;
  J: Integer;
  K: Integer;
  X: Double;
begin
  ClearReport;
  Chart1.Legend.Visible := false;
  Chart1LineSeries1.LinePen.Style := psSolid;
  Vlist := TDoubleList.Create;
  try
    GetPlotParamRange(0);
    N := Vlist.Count;
    K := (Vlist.Count div MAXPTS) + 1;
    for I := 0 to N - 1 do
    begin
      J := I + K - 1;
      if J < N then
      begin
        X := Double(J) / Double(N) * 100;
        Chart1LineSeries1.AddXY(X, Vlist[J]);
      end;
    end;
    Chart1AreaSeries1.AddXY(100, Vlist[N-1]);
    ChartIsShowing := true;
  finally
    Vlist.Free;
  end;
end;

procedure TPcntileRptFrame.GetPlotParamRange(T: Integer);
var
  I: Integer;
  N: Integer;
  P: Integer;
  V: Single;
begin

  // Add parameter value for each network object to the Vlist
  N := project.GetItemCount(ParamType);
  for I := 1 to N do
  begin
    if ParamType = ctNodes then
      V := GetNodeParamValue(I, T)
    else
      V := GetLinkParamValue(I, T);
    if V = MISSING then continue;
    Vlist.Add(V);
  end;

  // Sort the values in the Vlist
  Vlist.Sort(@DoubleCompare);

  // Locate the list values that form the desired percentile range
  N := Vlist.Count;
  P := 50 - (Pmid div 2);
  I := GetListIndex(P, N);
  Y1 := Vlist[I];
  P := 50 + (Pmid div 2);
  I := GetListIndex(P, N);
  Y2 := Vlist[I];
  Y2 := Y2 - Y1;
  I := GetListIndex(Pmin, N);
  Ymin := Vlist[I];
  I := GetListIndex(Pmax, N);
  Ymax := Vlist[I];
end;

function TPcntileRptFrame.GetListIndex(P, N: Integer): Integer;
begin
  Result := Round(P * N / 100);
  if Result < 0 then Result := 0;
  if Result >= N then Result := N - 1;
end;

function TPcntileRptFrame.GetNodeParamValue(I, T: Integer): Single;
begin
  // Only junction nodes with positive demand are considered
  Result := MISSING;
  if project.GetNodeType(I) <> ntJunction then exit;
  if mapthemes.GetNodeValue(I, mapthemes.ntDemand, T) < 0.01 then exit;
  Result := mapthemes.GetNodeValue(I, PlotParam, T);
end;

function TPcntileRptFrame.GetLinkParamValue(I, T: Integer): Single;
begin
  // Only pipe links are considered
  Result := MISSING;
  if project.GetLinkType(I) > ltPipe then exit;
  Result := mapthemes.GetLinkValue(I, PlotParam, T);
end;

end.

