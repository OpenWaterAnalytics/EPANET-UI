{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       timeseriesrpt
 Description:  A frame that displays a time series report
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit timeseriesrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, ExtCtrls, Menus, Grids, Buttons,
  TAGraph, TASeries, TATransformations, TAIntervalSources, TAGUIConnectorBGRA,
  TAChartUtils, LCLType, Types, Clipbrd, ComCtrls, StrUtils;

const
  MaxSeries = 6;

type

  // Properties of a data series to be displayed
  TDataSeries = record
    ObjType:  Integer;   // Node, Link, or System
    ObjIndex: Integer;   // Node/Link index
    ObjParam: Integer;   // Parameter to be plotted
    PlotAxis: Integer;   // Plot on left (0) or right (1) axis
    ObjID:    string;    // ID name of node/link
    Title:    string;    // Title used for data series
    Legend:   string;    // Legend text used for data series
  end;

  { TTimeSeriesFrame }

  TTimeSeriesFrame = class(TFrame)
    PageControl1:      TPageControl;
    ChartTabSheet:     TTabSheet;
    TableTabSheet:     TTabSheet;
    Chart1:            TChart;
    Chart1LineSeries1: TLineSeries;
    Chart1LineSeries2: TLineSeries;
    Chart1LineSeries3: TLineSeries;
    Chart1LineSeries4: TLineSeries;
    Chart1LineSeries5: TLineSeries;
    Chart1LineSeries6: TLineSeries;
    LeftChartAxisTransformationsAutoScaleAxisTransform: TAutoScaleAxisTransform;
    RightChartAxisTransformationsAutoScaleAxisTransform: TAutoScaleAxisTransform;
    RightChartAxisTransformations: TChartAxisTransformations;
    LeftChartAxisTransformations:  TChartAxisTransformations;
    ChartGUIConnectorBGRA1:        TChartGUIConnectorBGRA;
    DateTimeIntervalChartSource1:  TDateTimeIntervalChartSource;
    Panel1:            TPanel;
    DataGrid:          TDrawGrid;
    PopupMenu1:        TPopupMenu;
    DataMenuItem:      TMenuItem;
    SettingsMenuItem:  TMenuItem;
    Separator1:        TMenuItem;
    CopyMenuItem:      TMenuItem;
    SaveMenuItem:      TMenuItem;

    procedure CopyMenuItemClick(Sender: TObject);
    procedure DataGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DataGridPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure DataMenuItemClick(Sender: TObject);
    procedure SaveMenuItemClick(Sender: TObject);
    procedure SettingsMenuItemClick(Sender: TObject);

  private
    ShowingChart:  Boolean;
    PlotTimeOfDay: Boolean;
    Xstart:        TDateTime;
    Xstep:         TDateTime;
    Nseries:       Integer;
    DataSeries:    array[0..MaxSeries-1] of TDataSeries;

    procedure PlotSeries(I: Integer);
    function  GetDataGridValue(C: Integer; R: Integer): string;
    procedure GetDataGridContents(Slist: TStringList);
    procedure FillLineSeries(aLineSeries: TLineSeries; ObjType: Integer;
      ObjParam: Integer; ResultIndex: Integer);
    procedure SetupChart;
    procedure SaveChart;
    procedure SaveTable;

  public
    procedure InitReport;
    procedure CloseReport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure RefreshGrid;
    procedure ShowPopupMenu;
    procedure ShowTimeSeriesSelector;
    procedure SetDataSeries(NewDataSeries: array of TDataSeries;
      NewPlotTimeOfDay: Boolean; HasChanged: Boolean);
    function  GetObjStr(ObjType: Integer; Item: Integer): string;
    function  GetParamStr(ObjType: Integer; Param: Integer): string;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, mapthemes, results, sysresults, utils, chartoptions,
  reportviewer, resourcestrings;

const
  SeriesColors: array[1..MaxSeries] of TColor =
    ($E5B533, $CC66AA, $CC99, $33BBFF, $4444FF, clBlack);

{ TTimeSeriesFrame }

procedure TTimeSeriesFrame.InitReport;
var
  I, FontSize: Integer;
begin
  for I := 0 to High(DataSeries) do
  begin
    DataSeries[I].ObjType := -1;
    DataSeries[I].PlotAxis := 0;
  end;
  for I := 1 to MaxSeries do
  begin
    with FindComponent('Chart1LineSeries' + IntToStr(I)) as TLineSeries do
      SeriesColor := SeriesColors[I];
  end;
  FontSize := Font.Size;
  for I := 0 to 2 do
    Chart1.AxisList[I].Title.LabelFont.Size := FontSize;
  Chart1.Legend.Font.Size := FontSize;
  Nseries := 0;
  ShowingChart := true;
  PlotTimeOfDay := false;
  PageControl1.ActivePageIndex := 0;
  Chart1.Visible := true;
  ShowTimeSeriesSelector;
end;

procedure TTimeSeriesFrame.CloseReport;
var
  I: Integer;
begin
  for I := 1 to MaxSeries do
    with FindComponent('Chart1LineSeries' + IntToStr(I)) as TLineSeries do
      Clear;
  MainForm.TseriesSelectorFrame.Visible := false;
end;

procedure TTimeSeriesFrame.ShowTimeSeriesSelector;
begin
  ReportViewerForm.Hide;
  MainForm.HideHintPanelFrames;
  MainForm.TseriesSelectorFrame.Visible := true;
  MainForm.TseriesSelectorFrame.Init(DataSeries, PlotTimeOfDay);
end;

procedure TTimeSeriesFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  PopupMenu1.PopUp(P.x,P.y);
end;

procedure TTimeSeriesFrame.DataMenuItemClick(Sender: TObject);
begin
  ShowTimeSeriesSelector;
end;

procedure TTimeSeriesFrame.SaveMenuItemClick(Sender: TObject);
begin
  if ShowingChart then
    SaveChart
  else
    SaveTable;
end;

procedure TTimeSeriesFrame.SaveChart;
begin
  with MainForm.SaveDialog1 do
  begin
    FileName := '*.png';
    Filter := rsPngFile;
    DefaultExt := '*.png';
    if Execute then Chart1.SaveToFile(TPortableNetworkGraphic, FileName);
  end;
end;

procedure TTimeSeriesFrame.SaveTable;
var
  Slist: TStringList;
begin
  with MainForm.SaveDialog1 do begin
    FileName := '*.txt';
    Filter := rsTextFile;
    DefaultExt := '*.txt';
    if Execute then
    begin
      Slist := TStringList.Create;
      try
        GetDataGridContents(Slist);
        Slist.SaveToFile(FileName);
      finally
        Slist.Free;
      end;
    end;
  end;
end;

procedure TTimeSeriesFrame.SettingsMenuItemClick(Sender: TObject);
var
  I: Integer;
  aSeries: TLineSeries;
  OptionsForm: TChartOptionsForm;
begin
  OptionsForm := TChartOptionsForm.Create(self);
  with OptionsForm do
  try
    SetOptions(Chart1, Nseries);
    ShowModal;
    if ModalResult = mrOK then
    begin
      GetOptions(Chart1);
      for I := 0 to Nseries-1 do
      begin
        aSeries := TLineSeries(Chart1.Series[I]);
        DataSeries[I].Legend:= aSeries.Title;
      end;
    end;
  finally
    Free;
  end;
end;

procedure TTimeSeriesFrame.CopyMenuItemClick(Sender: TObject);
var
  Slist: TStringList;
begin
  if ShowingChart then
    Chart1.CopyToClipboardBitmap
  else
  begin
    Slist := TStringList.Create;
    try
      GetDataGridContents(Slist);
      Clipboard.AsText := Slist.Text;
    finally
      Slist.Free;
    end;
  end;
end;

procedure TTimeSeriesFrame.DataGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  S: string;
  H: Integer;
  N: Integer;
begin
  S := GetDataGridValue(aCol, aRow);
  with Sender as TDrawGrid do
  begin
    if aRow = 0 then
      N := 3
    else
      N := 1;
    H := (aRect.Height - N * Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(aRect, aRect.Left+2, aRect.Top + H, S);
  end;
end;

procedure TTimeSeriesFrame.DataGridPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  MyTextStyle := DataGrid.Canvas.TextStyle;
  MyTextStyle.Alignment := taCenter;
  MyTextStyle.SingleLine := false;
  DataGrid.Canvas.TextStyle := MyTextStyle;
end;

procedure TTimeSeriesFrame.SetDataSeries(NewDataSeries: array of TDataSeries;
  NewPlotTimeOfDay: Boolean; HasChanged: Boolean);
var
  I: Integer;
begin
  if NewDataSeries[0].ObjType < 0 then
  begin
    CloseReport;
    exit;
  end;
  if not HasChanged then
  begin
    if not Chart1.Visible then CloseReport;
    exit;
  end;
  for I := 0 to High(DataSeries) do
  begin
    DataSeries[I] := NewDataSeries[I];
    if DataSeries[I].ObjType >= 0 then with DataSeries[I] do
    begin
      if Length(Legend) = 0 then Legend := Title;
    end;
  end;
  PlotTimeOfDay := NewPlotTimeOfDay;
  SetupChart;
  RefreshReport;
end;

function TTimeSeriesFrame.GetObjStr(ObjType: Integer; Item: Integer): string;
begin
  if ObjType = ctSystem then
    Result := rsSystem
  else
    Result := project.GetObjectStr(ObjType, Item);
end;

function TTimeSeriesFrame.GetParamStr(ObjType: Integer; Param: Integer): string;
begin
  Result := '';
  case ObjType of
    ctNodes:
      Result := mapthemes.NodeThemes[Param].Name;
    ctLinks:
      Result := mapthemes.LinkThemes[Param].Name;
    ctSystem:
      Result := sysresults.SysParams[Param];
  end;
end;

procedure TTimeSeriesFrame.PlotSeries(I: Integer);
var
  ResultIndex: Integer = 0;
  aLineSeries: TLineSeries;
begin
  // Find order in which node/link object was written to results file
  if DataSeries[I].ObjType < 0 then exit;
  with DataSeries[I] do
  begin
    if ObjType <> ctSystem then
    begin
      ObjIndex:= project.GetItemIndex(ObjType, ObjID);
      if ObjIndex > 0 then
        ResultIndex := project.GetResultIndex(ObjType, ObjIndex);
      if ResultIndex = 0 then exit;
    end;
  end;

  // Add results to the LineSeries
  aLineSeries := FindComponent('Chart1LineSeries' + IntToStr(I+1)) as TLineSeries;
  if aLineSeries = nil then exit;
  ResultIndex := DataSeries[I].ObjIndex;
  FillLineSeries(aLineSeries, DataSeries[I].ObjType, DataSeries[I].ObjParam,
    ResultIndex);
  if aLineSeries.Count = 0 then exit;

  // Save which Y-axis (left or right) the series is plotted on
  if DataSeries[I].PlotAxis = 1 then
  begin
    Chart1.AxisList[2].Visible := true;
    aLineSeries.AxisIndexY := 2;
  end
  else
  begin
    Chart1.AxisList[0].Visible := true;
    aLineSeries.AxisIndexY := 0;
  end;
  Chart1.BottomAxis.Marks.Visible := (results.Nperiods > 1);

  // Add the data series title to the plot and activate it
  aLineSeries.Title := DataSeries[I].Legend;
  aLineSeries.Active := true;
  Chart1.Visible := true;
end;

procedure TTimeSeriesFrame.FillLineSeries(aLineSeries: TLineSeries;
    ObjType: Integer; ObjParam: Integer; ResultIndex: Integer);
var
  T: Integer;
  Y: Double = MISSING;
  X: TDateTime;
begin
  for T := 0 to results.Nperiods - 1 do
  begin
    X := Xstart + (T * Xstep);
    Y := MISSING;
    case ObjType of
      ctNodes:
        Y := mapthemes.GetNodeValue(ResultIndex, ObjParam, T);
      ctLinks:
        Y := mapthemes.GetLinkValue(ResultIndex, ObjParam, T);
      ctSystem:
        Y := sysresults.GetSysValue(ObjParam, T);
      else
        Y := MISSING;
    end;
    if Y = MISSING then continue;
    aLineSeries.AddXY(X, Y);
  end;

  // Adjustment for single period run
  if (aLineSeries.Count > 0)
  and (results.Nperiods = 1) then
  begin
    X := Xstart + Xstep;
    aLineSeries.AddXY(X, Y);
  end;
end;

procedure TTimeSeriesFrame.RefreshGrid;
begin
  with DataGrid do
  begin
    Clear;
    ColCount := Nseries + 2;
    RowCount := Results.Nperiods + 1;
    RowHeights[0] := (2 * DefaultRowHeight) + (DefaultRowHeight div 2);
    FixedColor := config.ThemeColor;
    Refresh;
  end;
end;

function TTimeSeriesFrame.GetDataGridValue(C: Integer; R: Integer): string;
var
  I: Integer;
  T: Integer;
begin
  // I is 0-based index into DataSeries array
  I := C - 2;

  // Column 0 displays time
  Result := '';
  if C = 0 then
  begin
    if R = 0 then
      Result := rsTimeHrs
    else
      Result := FloatToStrF((R - 1) * Xstep, ffFixed, 7, 2);
  end
  else if C = 1 then
  begin
    if R = 0 then
      Result := rsTimeOfDay
    else
    begin
      T := project.StartTime + (R-1) * results.Rstep + results.Rstart;
      Result := utils.TimeOfDayStr(T);
    end;
  end

  // Column C displays results for DataSeries[I]
  else if DataSeries[I].ObjType >= 0 then
  begin
    // Column header
    if R = 0 then
    begin
      Result := GetObjStr(DataSeries[I].ObjType, DataSeries[I].ObjIndex - 1) +
                LineEnding +
                GetParamStr(DataSeries[I].ObjType, DataSeries[I].ObjParam) +
                LineEnding;
      if DataSeries[I].ObjType = ctSystem then
        Result := Result + sysresults.GetSysParamUnits(DataSeries[I].ObjParam)
      else
        Result := Result +
          mapthemes.GetThemeUnits(DataSeries[I].ObjType, DataSeries[I].ObjParam);
    end

    // Time series value (previously stored in chart's LineSeries)
    else with FindComponent('Chart1LineSeries' + IntToStr(C-1)) as TLineSeries do
      Result := FloatToStrF(GetYValue(R-1), ffFixed, 7, config.DecimalPlaces) + '  ';
  end;
end;

procedure TTimeSeriesFrame.SetupChart;
var
  I: Integer;
  UnitsStr: string;
  LeftAxisTitle: string = '';
  RightAxisTitle: string = '';
begin
  for I := 0 to High(DataSeries) do
  begin
    with FindComponent('Chart1LineSeries' + IntToStr(I+1)) as TLineSeries do
    begin
      Clear;
      Active := false;
    end;
  end;

  Nseries := 0;
  for I := 0 to High(DataSeries) do
  begin
    if DataSeries[I].ObjType < 0 then break;
    Inc(Nseries);

    // Get the series' parameter units
    if DataSeries[I].ObjType = ctSystem then
      UnitsStr := sysresults.GetSysParamUnits(DataSeries[I].ObjParam)
    else
      UnitsStr := mapthemes.GetThemeUnits(DataSeries[I].ObjType,
        DataSeries[I].ObjParam);

    // If series uses a left axis
    if DataSeries[I].PlotAxis = 0 then
    begin
      if not AnsiContainsStr(LeftAxisTitle, UnitsStr) then
      begin
        if Length(LeftAxisTitle) = 0 then
          LeftAxisTitle := UnitsStr
        else
          LeftAxisTitle := LeftAxisTitle + ', ' + UnitsStr;
      end;
    end

    // Repeat above steps if series uses a right axis
    else if DataSeries[I].PlotAxis = 1 then
    begin
      if not AnsiContainsStr(RightAxisTitle, UnitsStr) then
      begin
        if Length(RightAxisTitle) = 0 then
          RightAxisTitle := UnitsStr
        else
          RightAxisTitle := RightAxisTitle + ', ' + UnitsStr;
      end;
    end;
  end;

  Chart1.AxisList[0].Title.Caption := LeftAxisTitle;
  Chart1.AxisList[2].Title.Caption := RightAxisTitle;
  Chart1.Legend.Visible := true;
  Chart1.Title.Visible := false;
end;

procedure TTimeSeriesFrame.GetDataGridContents(Slist: TStringList);
var
  I: Integer;
  R: Integer;
  S: string;
begin
  // Add a title to the contents' stringlist
  S := project.GetTitle(0);
  Slist.Add(S);
  S := rsTimeSeriesRpt;
  Slist.Add(S);
  Slist.Add('');

  // The DataGrid's header row contains text on 3 lines -- add each as
  // a separate row to the contents' stringlist
  with DataGrid do
  begin
    S := 'Elapsed   ' + #9 + 'Time      ';
    for I := 1 to Nseries do
      S := S + #9 +
        Format('%-20s',
          [GetObjStr(DataSeries[I-1].ObjType, DataSeries[I-1].ObjIndex - 1)]);
    Slist.Add(S);
    S := 'Time      ' + #9 + 'of        ';
    for I := 1 to Nseries do
      S := S + #9 +
        Format('%-20s',
          [GetParamStr(DataSeries[I-1].ObjType, DataSeries[I-1].ObjParam)]);
    Slist.Add(S);
    S := '(hrs)      ' + #9 + 'Day       ';
    for I := 1 to Nseries do
      S := S + #9 +
        Format('%-20s',
          [mapthemes.GetThemeUnits(DataSeries[I-1].ObjType, DataSeries[I-1].ObjParam)]);
    Slist.Add(S);
  end;

  // Then add each successive row of the DataGrid to the stringlist
  for R := 1 to DataGrid.RowCount - 1 do
  begin
    S := Format('%-10s', [GetDataGridValue(0,R)]);
    S := S + #9 + Format('%-10s', [GetDataGridValue(1,R)]);
    for I := 2 to DataGrid.ColCount-1 do
      S := S + #9 + Format('%-20s', [GetDataGridValue(I, R)]);
    Slist.Add(S);
  end;
end;

procedure TTimeSeriesFrame.ClearReport;
var
  I: Integer;
begin
  for I := 1 to MaxSeries do
    with FindComponent('Chart1LineSeries' + IntToStr(I)) as TLineSeries do
      Clear;
end;

procedure TTimeSeriesFrame.RefreshReport;
var
  I: Integer;
begin
  ClearReport;
  Xstart := results.Rstart / 3600;
  Xstep := results.Rstep / 3600;
  if PlotTimeOfDay then
  begin
    Chart1.BottomAxis.Marks.Style := smsLabel;
    Chart1.BottomAxis.Marks.Source := DateTimeIntervalChartSource1;
    Chart1.BottomAxis.Title.Visible := false;
    Xstart := (Xstart + project.StartTime / 3600) / 24;
    Xstep := Xstep / 24;
  end
  else
  begin
    Chart1.BottomAxis.Marks.Style := smsValue;
    Chart1.BottomAxis.Marks.Source := nil;
    Chart1.BottomAxis.Title.Visible := true;
  end;
  Chart1.AxisList[2].Visible := false;

  for I := 0 to Nseries-1 do PlotSeries(I);
  RefreshGrid;
end;

end.

