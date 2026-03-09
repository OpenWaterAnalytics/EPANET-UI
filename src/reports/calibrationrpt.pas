{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       calibrationrpt
 Description:  A frame that displays a calibration report
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit calibrationrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, ComCtrls, StdCtrls, Grids,
  Buttons, Menus, TAGraph, TASeries, TALegend, TATypes, TAChartUtils, Math,
  Graphics, Dialogs;

type

  TSums = record
    N: Integer;
    SumX: Double;
    SumY: Double;
    SumX2: Double;
    SumY2: Double;
    SumXY: Double;
    SumE: Double;
    SumE2: Double;
  end;

  { TCalibRptFrame }

  TCalibRptFrame = class(TFrame)
    PageControl1:          TPageControl;
    TabSheet1:             TTabSheet;
    TabSheet2:             TTabSheet;
    TabSheet3:             TTabSheet;
    TabSheet4:             TTabSheet;
    Panel1:                TPanel;
    LocationsHeader:       TPanel;
    LocationsPanel:        TPanel;
    TimeSeriesPanel:       TPanel;
    CorrelationChartPanel: TPanel;
    TimeSeriesChartPanel:  TPanel;
    ClearBtn:              TBitBtn;
    LoadBtn:               TBitBtn;
    SaveBtn:               TBitBtn;
    Exportmenu:            TPopupMenu;
    CopyMnuItem:           TMenuItem;
    SaveMnuItem:           TMenuItem;
    TimeSeriesChart:       TChart;
    CorrelationPlot:       TChart;
    ComputedSeries:        TLineSeries;
    MeasuredSeries:        TLineSeries;
    DataGrid:              TStringGrid;
    ErrorStatsMemo:        TMemo;
    LocationsListBox:      TListBox;
    VariableCombo:         TComboBox;
    Label1:                TLabel;
    Label2:                TLabel;

    procedure ClearBtnClick(Sender: TObject);
    procedure CopyMnuItemClick(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure LocationsListBoxClick(Sender: TObject);
    procedure PageControl1Change(Sender: TObject);
    procedure PageControl1Changing(Sender: TObject; var AllowChange: Boolean);
    procedure SaveBtnClick(Sender: TObject);
    procedure SaveMnuItemClick(Sender: TObject);
    procedure TabSheet1Exit(Sender: TObject);
    procedure VariableComboChange(Sender: TObject);

  private
    ObjectType:     Integer;
    LocationIndex:  Integer;
    VariableIndex:  Integer;
    DataHasChanged: Boolean;

    procedure SetDataGridHeadings;
    procedure LoadCalibData(Fname: string);
    procedure GetLocationsList(LocationsList: TStringList);
    procedure FillLocationsListBox(LocationsList: TStringList);
    procedure LoadMeasuredData(aSeries: TLineSeries; aLocation: string);
    procedure RefreshTimeSeriesPlot;
    procedure RefreshErrorStats;
    procedure InitCorrelationPlot;
    procedure FinalizeCorrelationPlot(Rcoeff: Double);
    function  GetSimulatedValue(T: Single): Single;
    function  ReadDataGrid: Boolean;
    procedure InitSums(var Sums: TSums);
    procedure UpdateSums(X, Y: Double; var Sums: TSums);
    function  FindCorrelCoeff(Sums: TSums): Double;
    procedure DisplayErrorStats(Sums: array of TSums);
    procedure SaveChartToFile(aChart: TChart);
    function  GetFileName(Fname: string; Ftypes: string; DefType: string): string;

  public
    procedure InitReport;
    procedure CloseReport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure ShowPopupMenu;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, mapthemes, results, utils, resourcestrings;

const
    MarkerColors : array[0..14] of TColor =
    (clBlack, clRed, clPurple, clLime, clBlue, clFuchsia, clAqua,
     clGray, clGreen, clMaroon, clYellow, clTeal, clSilver, clNavy,
     clOlive);

procedure TCalibRptFrame.LoadBtnClick(Sender: TObject);
begin
  with MainForm.OpenDialog1 do
  begin
    FileName := '*.dat';
    Filter := rsDataFile;
    DefaultExt := '*.dat';
    if Execute then LoadCalibData(FileName);
  end;
end;

procedure TCalibRptFrame.ClearBtnClick(Sender: TObject);
begin
  DataGrid.Clean;
  DataGrid.RowCount := 2;
  LocationsListBox.Clear;
  SetDataGridHeadings;
  DataHasChanged := true;
end;

procedure TCalibRptFrame.CopyMnuItemClick(Sender: TObject);
begin
  case PageControl1.ActivePageIndex of
    0:
      DataGrid.CopyToClipboard;
    1:
      TimeSeriesChart.CopyToClipboardBitmap;
    2:
      CorrelationPlot.CopyToClipboardBitmap;
    3:
      with ErrorStatsMemo do
      begin
        SelectAll;
        CopyToClipboard;
        SelLength := 0;
      end;
  end;
end;

procedure TCalibRptFrame.LocationsListBoxClick(Sender: TObject);
begin
  RefreshTimeSeriesPlot;
end;

procedure TCalibRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TCalibRptFrame.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePageIndex = 0 then
  begin
    DataHasChanged := false;
    DataGrid.Modified := false;
  end
  else
  begin
    if DataHasChanged then RefreshReport;
  end;
end;

procedure TCalibRptFrame.PageControl1Changing(Sender: TObject;
  var AllowChange: Boolean);
begin
  // If on Calibration Data page, check if allowed to select a new tab
  if (PageControl1.ActivePageIndex = 0)
  and DataHasChanged then
    AllowChange := ReadDataGrid
  else
    AllowChange := true;
end;

procedure TCalibRptFrame.SaveBtnClick(Sender: TObject);
var
  Fname: string;
begin
  Fname := GetFileName('*.dat', rsCalibFile, 'dat');
  if Length(Fname) > 0 then
    DataGrid.SaveToCSVFile(Fname, ' ', false);
end;

procedure TCalibRptFrame.SaveMnuItemClick(Sender: TObject);
var
  Fname: string;
begin
  case PageControl1.ActivePageIndex of
    0:
      SaveBtnClick(Sender);
    1:
      SaveChartToFile(TimeSeriesChart);
    2:
      SaveChartToFile(CorrelationPlot);
    3:
      begin
        Fname := GetFileName('*.txt', rsTextFile, 'txt');
        if Length(Fname) > 0 then
          ErrorStatsMemo.Lines.SaveToFile(Fname);
       end;
  end;
end;

procedure TCalibRptFrame.TabSheet1Exit(Sender: TObject);
begin
  if DataGrid.Modified then DataHasChanged := true;
  if DataHasChanged then RefreshReport;
  DataGrid.Modified := false;
end;

procedure TCalibRptFrame.VariableComboChange(Sender: TObject);
begin
  ObjectType := project.ctNodes;
  if VariableCombo.ItemIndex in [2,3] then
    ObjectType := project.ctLinks;
  with VariableCombo do
  begin
    case VariableCombo.ItemIndex of
      0:
        VariableIndex := mapthemes.ntHead;
      1:
        VariableIndex := mapthemes.ntPressure;
      2:
        VariableIndex := mapthemes.ltFlow;
      3:
        VariableIndex := mapthemes.ltVelocity;
      else
        VariableIndex := mapthemes.FirstNodeQualTheme + ItemIndex - 4;
    end;
  end;
  SetDataGridHeadings;
  DataHasChanged := true;
end;

procedure TCalibRptFrame.SetDataGridHeadings;
begin
  with DataGrid do
  begin
    if ObjectType = ctNodes then
      Cells[0,0] := rsNodeID
    else
      Cells[0,0] := rsLinkID;
    Cells[1,0] := rsTimeInHours;
    Cells[2,0] := VariableCombo.Text;
  end;
end;

procedure TCalibRptFrame.LoadCalibData(Fname: string);
var
  DataList: TStringList;
  Tokens: TStringArray;
  I: Integer;
  J: Integer;
  S: string;
begin
  DataGrid.Clear;
  J := 1;
  DataList := TStringList.Create();
  try
    DataList.LoadFromFile(Fname);
    DataGrid.RowCount := DataList.Count + 1;
    SetDataGridHeadings;
    for I := 0 to DataList.Count - 1 do
    begin
      S := Trim(DataList[I]);
      if S.StartsWith(';') then continue;
      Tokens := S.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
      if Length(Tokens) = 2 then
      begin
        DataGrid.Cells[0,J] := DataGrid.Cells[0,J-1];
        DataGrid.Cells[1,J] := Tokens[0];
        DataGrid.Cells[2,J] := Tokens[1];
      end
      else if Length(Tokens) = 3 then
      begin
        DataGrid.Cells[0,J] := Tokens[0];
        DataGrid.Cells[1,J] := Tokens[1];
        DataGrid.Cells[2,J] := Tokens[2];
      end
      else
        continue;
      Inc(J);
    end;
    DataGrid.Modified := true;
  finally
    DataList.Free;
  end;
end;

procedure TCalibRptFrame.GetLocationsList(LocationsList: TStringList);
var
  S: string;
  S1: string;
  I: Integer;
begin
  // Set the text of the previous location to blank
  S1 := '';

  with DataGrid do
  begin
    // Start with row 1 since row 0 is the header
    for I := 1 to RowCount-1 do
    begin
      // Skip over current row if it has no location or its
      // location is the same as the row above it
      S := Trim(Cells[0, I]);
      if Length(S) = 0 then continue;
      if SameText(S, S1) then continue;
      if LocationsList.IndexOf(S) >= 0 then continue;

      // Check that location exists
      if project.GetItemIndex(ObjectType, S) <= 0 then continue;

      // Add the location to the list
      LocationsList.Add(S);
      S1 := S;
    end;
  end;
end;

procedure TCalibRptFrame.FillLocationsListBox(LocationsList: TStringList);
var
  OldLocation: string;
  NewIndex: Integer;
begin
  OldLocation := '';
  with LocationsListBox do
    if Items.Count > 0 then OldLocation := Items[ItemIndex];
  LocationsListBox.Clear;
  LocationsListBox.Items.Assign(LocationsList);
  NewIndex := LocationsListBox.Items.IndexOf(OldLocation);
  if NewIndex < 0 then NewIndex := 0;
  LocationsListBox.ItemIndex := NewIndex;
end;

procedure TCalibRptFrame.LoadMeasuredData(aSeries: TLineSeries;
  aLocation: string);
var
  X: Single = 0;
  Y: Single = 0;
  I: Integer;
begin
  // Loop through each row of the DataGrid
  with DataGrid do
  begin
    for I := 1 to RowCount - 1 do
    begin
      // The row's location value matches the target location
      if SameText(Cells[0,I], aLocation) then
      begin
        X := utils.Str2Seconds(Cells[1,I]) / 3600.0;
        if (X >= 0)
        and utils.Str2Float(Cells[2,I], Y) then
          aSeries.AddXY(X, Y);
      end;
    end;
  end;
end;

procedure TCalibRptFrame.RefreshTimeSeriesPlot;
var
  T: Integer;
  X: Double;
  Y: Double;
  Location: string;
begin
  // Get location's index
  with LocationsListBox do Location := Items[ItemIndex];
  LocationIndex := project.GetItemIndex(ObjectType, Location);
  TimeSeriesChart.Title.Text[0] := VariableCombo.Text + ' ' + rsFor + ' ' +
    LocationsHeader.Caption + ' '  + Location;

  // Load computed results into ComputedSeries line series
  ComputedSeries.Clear;
  ComputedSeries.Active := false;
  for T := 0 to Results.Nperiods - 1 do
  begin
    X := (Results.Rstart + T * Results.Rstep) / 3600.;
    with ComputedSeries do
    begin
      if ObjectType = ctNodes then
        Y := MapThemes.GetNodeValue(LocationIndex, VariableIndex, T)
      else
        Y := MapThemes.GetLinkValue(LocationIndex, VariableIndex, T);
      if Y <> MISSING then AddXY(X, Y);
    end;
  end;
  ComputedSeries.Active := true;

  // Load measured values into MeasuredSeries point series
  MeasuredSeries.Clear;
  MeasuredSeries.Active := false;
  LoadMeasuredData(MeasuredSeries, Location);
  MeasuredSeries.Active := true;
end;

procedure TCalibRptFrame.RefreshErrorStats;
var
  I:           Integer;
  N:           Integer;
  SeriesIndex: Integer;
  Location:    string;
  X:           Single = 0;
  Y:           Single = 0;
  T:           Single = 0;
  Sums:        array of TSums;
  Rcoeff:      Double;
begin
  // Initialize
  InitCorrelationPlot;
  N := LocationsListBox.Items.Count + 1;
  SetLength(Sums, N);
  for I := 0 to N - 1 do InitSums(Sums[I]);

  // Retrieve values for each measured and corresponding simulated result
  with DataGrid do
  begin
    for I := 1 to RowCount - 1 do
    begin
      Location := Cells[0,I];
      SeriesIndex := LocationsListBox.Items.IndexOf(Location) + 1;
      if SeriesIndex < 1 then continue;
      LocationIndex := project.GetItemIndex(ObjectType, Location);
      if LocationIndex < 1 then continue;
      if not utils.Str2Float(Cells[1,I], T) then continue;
      if not utils.Str2Float(Cells[2,I], X) then continue;
      Y := GetSimulatedValue(T);
      if Y = MISSING then continue;

      // Update correlation plot
      with CorrelationPlot.Series[SeriesIndex] as TLineSeries do
        AddXY(X, Y);

      // Update correlation statistics
      UpdateSums(X, Y, Sums[0]);
      UpdateSums(X, Y, Sums[SeriesIndex]);
    end;
  end;

  // Finalize correlation plot
  Rcoeff := FindCorrelCoeff(Sums[0]);
  FinalizeCorrelationPlot(Rcoeff);

  // Display error statistics
  DisplayErrorStats(Sums);
  SetLength(Sums, 0);
end;

procedure TCalibRptFrame.InitCorrelationPlot;
var
  I: Integer;
  aSeries: TLineSeries;
  ColorIndex: Integer;
begin
  // Free any existing data series on the CorrelationPlot
  with CorrelationPlot do
    while SeriesCount > 0 do Series[0].Free;
  CorrelationPlot.Title.Text[0] := rsCorrelPlot + ' ' + VariableCombo.Text;

  // Create a series for the perfect correlation line
  aSeries := TLineSeries.Create(CorrelationPlot.Owner);
  with aSeries as TLineSeries do
  begin
    ShowInLegend := false;
    CorrelationPlot.AddSeries(aSeries);
  end;

  // Create a line series for each measurement location
  ColorIndex := -1;
  for I := 0 to LocationsListBox.Items.Count - 1 do
  begin
    Inc(ColorIndex);
    if ColorIndex > High(MarkerColors) then
      ColorIndex := 0;
    aSeries := TLineSeries.Create(CorrelationPlot.Owner);
    with aSeries as TLineSeries do
    begin
      Title := LocationsListBox.Items[I];
      ShowPoints := true;
      ShowLines := false;
      LineType := ltNone;
      Pointer.Style := psDiagCross;
      Pointer.Pen.Width := 2;
      Pointer.Pen.Color := MarkerColors[ColorIndex];
      SeriesColor := MarkerColors[ColorIndex];
      CorrelationPlot.AddSeries(aSeries);
    end;
  end;
end;

procedure TCalibRptFrame.FinalizeCorrelationPlot(Rcoeff: Double);
var
  Z1: Double;
  Z2: Double;
  Extent: TDoubleRect;
begin
  // Add perfect correlation line to plot as Series 0
  Extent := CorrelationPlot.GetFullExtent;
  Z1 := Extent.a.X;
  Z1 := Min(Z1, Extent.a.Y);
  Z2 := Extent.b.X;
  Z2 := Max(Z2, Extent.b.Y);
  with CorrelationPlot.Series[0] as TLineSeries do
  begin
    AddXY(Z1, Z1);
    AddXY(Z2, Z2);
  end;

  // Add correlation coefficient to plot
  CorrelationPlot.Foot.Text[0] := Format(rsCorrelCoeff, [Rcoeff]);
end;

function TCalibRptFrame.GetSimulatedValue(T: Single): Single;
var
  P1: Integer;
  P2: Integer;
  Y1: Single;
  Y2: Single;
  T1: Single;
begin
  // Default result is MISSING
  Result := MISSING;

  // Convert time from hours to seconds
  T := T * 3600.0;

  // Find reporting periods that contains time T
  P1 := Floor((T - results.Rstart) / results.Rstep);
  if (P1 < 0) then exit;
  if P1 = results.Nperiods then
    P2 := P1
  else
    P2 := P1 + 1;

  // Find simulated results for these periods
  if ObjectType = ctNodes then
  begin
    Y1 := MapThemes.GetNodeValue(LocationIndex, VariableIndex, P1);
    Y2 := MapThemes.GetNodeValue(LocationIndex, VariableIndex, P2);
  end
  else begin
    Y1 := MapThemes.GetLinkValue(LocationIndex, VariableIndex, P1);
    Y2 := MapThemes.GetLinkValue(LocationIndex, VariableIndex, P2);
  end;
  if (Y1 = MISSING)
  or (Y2 = MISSING) then
    exit;

  // Interpolate to find Y at time T
  T1 := P1 * results.Rstep;
  Result := Y1 + (Y2 - Y1) * (T - T1) / results.Rstep;
end;

function TCalibRptFrame.ReadDataGrid: Boolean;
var
  LocationsList: TStringList;
begin
  // Place object type in LocationsHeader
  if ObjectType = ctNodes then
    LocationsHeader.Caption := rsNode
  else
    LocationsHeader.Caption := rsLink;

  // Get a list of measurement locations
  LocationsList := TStringList.Create;
  try
    GetLocationsList(LocationsList);

    // Issue error message if no locations
    if LocationsList.Count = 0 then
    begin
      utils.MsgDlg(rsMissingData, rsNoCalibData, mtInformation, [mbOk]);
      Result := false;
    end

    // Otherwise fill the LocationListBox on the Time Series Plot page
    else
    begin
      FillLocationsListBox(LocationsList);
      Result := true;
    end;
  finally
    LocationsList.Free;
  end;
end;

procedure TCalibRptFrame.InitSums(var Sums: TSums);
begin
  with Sums do
  begin
    N := 0;
    SumX := 0;
    SumY := 0;
    SumX2 := 0;
    SumY2 := 0;
    SumXY := 0;
    SumE := 0;
    SumE2 := 0;
  end;
end;

procedure TCalibRptFrame.UpdateSums(X, Y: Double; var Sums: TSums);
var
  E: Double;
begin
  with Sums do
  begin
    Inc(N);
    SumX := SumX + X;
    SumY := SumY + Y;
    SumX2 := SumX2 + (X*X);
    SumY2 := SumY2 + (Y*Y);
    SumXY := SumXY + (X*Y);
    E := Abs(X - Y);
    SumE := SumE + E;
    SumE2 := SumE2 + (E*E);
  end;
end;

function TCalibRptFrame.FindCorrelCoeff(Sums: TSums): Double;
var
  T1: Double;
  T2: Double;
  T3: Double;
  T4: Double;
begin
  with Sums do
  begin
    T1 := N * SumX2 - (SumX * SumX);
    T2 := N * SumY2 - (SumY * SumY);
    T3 := N * SumXY - (SumX * SumY);
    T4 := T1 * T2;
    if T4 <= 0 then
      Result := 0.0
    else
      Result := T3 / Sqrt(T4);
  end;
end;

procedure TCalibRptFrame.DisplayErrorStats(Sums: array of TSums);
var
  Location: string;
  N:        Double;
  Xmean:    Double;
  Ymean:    Double;
  Rcoeff:   Double;
  I:        Integer;
  MeanSums: TSums = (N: 0; SumX: 0; SumY: 0; SumX2: 0; SumY2: 0; SumXY: 0;
                     SumE: 0; SumE2: 0);
begin
  InitSums(MeanSums);
  with ErrorStatsMemo.Lines do
  begin
    Clear;
    Add ('');
    with VariableCombo do
      Add(' ' + rsCalibReportFor + ' ' + Items[ItemIndex]);
    Add('');
    Add(rsHeading1);
    Add(rsHeading2);
    Add(rsHeading3);
    for I := 1 to Length(Sums)-1 do
    begin
      Location := LocationsListBox.Items[I-1];
      N := Sums[I].N;
      Xmean := Sums[I].SumX / N;
      Ymean := Sums[I].SumY / N;
      Add(Format('  %-14s%3.0f%12.2f%12.2f%8.3f%8.3f',
        [Location, N, Xmean, Ymean, Sums[I].SumE/N, Sqrt(Sums[I].SumE2/N)]));
      UpdateSums(Xmean, Ymean, MeanSums);
    end;
    Add(rsHeading3);
    Location := rsNetwork;
    N := Sums[0].N;
    Add(Format('  %-14s%3.0f%12.2f%12.2f%8.3f%8.3f',
      [Location, N, Sums[0].SumX/N, Sums[0].SumY/N, Sums[0].SumE/N,
      Sqrt(Sums[0].SumE2/N)]));
    Rcoeff := FindCorrelCoeff(MeanSums);
    Add('');
    Add('  ' + rsCorrelation + ' ' + Format('%.3f',[Rcoeff]));
  end;
  ErrorStatsMemo.SelStart := 0;
end;

procedure TCalibRptFrame.SaveChartToFile(aChart: TChart);
var
  Fname: string;
begin
  Fname := GetFileName('*.png', rsPngFile, 'png');
  if Length(Fname) > 0 then
    aChart.SaveToFile(TPortableNetworkGraphic, Fname);
end;

function TCalibRptFrame.GetFileName(Fname: string; Ftypes: string;
  DefType: string): string;
begin
  Result := '';
  with MainForm.SaveDialog1 do begin
    FileName := Fname;
    Filter := Ftypes;
    DefaultExt := DefType;
    if Execute then Result := FileName;
  end;
end;

procedure TCalibRptFrame.InitReport;
var
  I: Integer;
begin
  ErrorStatsMemo.Font.Name := config.MonoFont;

  // Fill the VariableCombo combobox with the names of
  // variables that can be calibrated to
  with VariableCombo.Items do
  begin
    Add(rsHead);
    Add(rsPressure);
    Add(rsFlow);
    Add(rsVelocity);
    for I := mapthemes.FirstNodeQualTheme to mapthemes.NodeThemeCount -1 do
      Add(mapthemes.NodeThemes[I].Name);
  end;
  VariableCombo.ItemIndex := 1;
  VariableComboChange(self);
  PageControl1.ActivePageIndex := 0;
end;

procedure TCalibRptFrame.CloseReport;
begin
  ClearReport;
end;

procedure TCalibRptFrame.ClearReport;
begin
  DataGrid.Clear;
  LocationsListBox.Items.Clear;
  ComputedSeries.Clear;
  MeasuredSeries.Clear;
  with CorrelationPlot do
    while SeriesCount > 0 do Series[0].Free;
  ErrorStatsMemo.Clear;
end;

procedure TCalibRptFrame.RefreshReport;
begin
  if LocationsListBox.Items.Count = 0 then exit;
  RefreshTimeSeriesPlot;
  RefreshErrorStats;
  DataHasChanged := false;
end;

end.

