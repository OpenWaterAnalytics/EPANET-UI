{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       sysflowrpt
 Description:  a frame that reports system inflow, outflow and storage
               volumes in each time period of a simulation
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit sysflowrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Buttons, Graphics, Menus,
  ComCtrls, Grids, TAGraph, TASeries, TASources, TAStyles, TAGUIConnectorBGRA,
  TACustomSeries, TAIntervalSources, TATransformations, TAChartUtils, Types,
  Clipbrd;

type

  { TSysFlowFrame }

  TSysFlowFrame = class(TFrame)
    Notebook1:              TNotebook;
    ChartPage:              TPage;
    DataPage:               TPage;
    Chart1:                 TChart;
    DataGrid:               TDrawGrid;
    Chart1AreaSeries1:      TAreaSeries;
    ListChartSource1:       TListChartSource;
    ChartGUIConnectorBGRA1: TChartGUIConnectorBGRA;
    ChartStyles1:           TChartStyles;
    DateTimeIntervalChartSource1: TDateTimeIntervalChartSource;
    ExportMenu:             TPopupMenu;
    MnuChart:               TMenuItem;
    MnuData:                TMenuItem;
    MnuTimeOfDay:           TMenuItem;
    ProgressBar1: TProgressBar;
    Separator1:             TMenuItem;
    MnuCopy:                TMenuItem;
    MnuSave:                TMenuItem;

    procedure DataGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DataGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure MnuChartClick(Sender: TObject);
    procedure MnuCopyClick(Sender: TObject);
    procedure MnuDataClick(Sender: TObject);
    procedure MnuSaveClick(Sender: TObject);
    procedure MnuTimeOfDayClick(Sender: TObject);

  private
    Produced: Double;
    Consumed: Double;
    Stored:   Double;
    Dcf:      Double;
    Vcf:      Double;
    Dt:       Double;

    procedure GetSystemFlowVolumes(T: Integer);
    function  GetDataGridValue(C: Integer; R: Integer): string;
    procedure GetDataGridContents(Slist: TStringList);
    procedure SaveChart;
    procedure SaveTable;

  public
    procedure ClearReport;
    procedure RefreshReport;
    procedure RefreshGrid;
    procedure SetColors;
    procedure ShowPopupMenu;
  end;

implementation

{$R *.lfm}

uses
  main, project, config, mapthemes, results, utils, resourcestrings;

procedure TSysFlowFrame.ClearReport;
begin
  ListChartSource1.Clear;
  DataGrid.Clear;
end;

procedure TSysFlowFrame.RefreshReport;
var
  T:      Integer;
  X:      TDateTime;
  Xstart: TDateTime;
  Xstep:  TDateTime;
begin
  // Flow units conversion factor to CFS,
  // volume units conversion (ft3 -> MG or ft3 -> ML)
  Dcf := project.FlowUcf[project.FlowUnits];
  Vcf := 0.000007480519;
  if project.GetUnitsSystem = usSI then Vcf := 28.317e-6;

  // Reporting time step (in sec)
  Dt := results.Rstep;

  // Adjustment for single period run
  if results.Nperiods = 1 then Dt := 3600;

  // Set start time and report step to hours
  Xstart := results.Rstart / 3600;
  Xstep := results.Rstep / 3600;

  // Setup bottom axis
  if MnuTimeOfDay.Checked then
  begin
    Xstart := (Xstart + project.StartTime / 3600) / 24;
    Xstep := Xstep / 24;
    Chart1.BottomAxis.Marks.Style := smsLabel;
    Chart1.BottomAxis.Marks.Source := DateTimeIntervalChartSource1;
    Chart1.BottomAxis.Title.Visible := False;
  end
  else
  begin
    Chart1.BottomAxis.Marks.Style := smsValue;
    Chart1.BottomAxis.Marks.Source := nil;
    Chart1.BottomAxis.Title.Visible := True;
  end;
  Chart1.BottomAxis.Marks.Visible := (results.Nperiods > 1);

  // Assign left axis title with proper units
  if project.GetUnitsSystem = usSI then
    Chart1.LeftAxis.Title.Caption := rsMegaLiters
  else
    Chart1.LeftAxis.Title.Caption := rsMillionGallons;

  // Get initial volume stored in tanks (in ft3)
  Stored := results.InitStorage;

  // Populate the chart with flow volumes in each reporting period
  Notebook1.PageIndex := 0;
  ListChartSource1.Clear;
  ProgressBar1.Visible := true;
  ProgressBar1.Position := 0;
  ProgressBar1.Max := results.Nperiods;
  Repaint;
  Application.ProcessMessages;
  ListChartSource1.BeginUpdate;
  try

    for T := 0 to results.Nperiods - 1 do
    begin
      ProgressBar1.Position := T;
      GetSystemFlowVolumes(T);
      if (T*results.Rstep) mod 3600 < 1 then
      begin
        X := Xstart + (T * Xstep);
        with ListChartSource1 do begin
          AddXYList(X, [Stored*Vcf, Produced*Vcf, Consumed*Vcf]);
        end;
      end;
    end;

  finally
    ListChartSource1.EndUpdate;
  end;
  ProgressBar1.Visible := false;

  // Adjustment for single period run
  if results.Nperiods = 1 then with ListChartSource1 do
      AddXYList(1, [Stored*Vcf, Produced*Vcf, Consumed*Vcf]);
  RefreshGrid;
////  Notebook1.PageIndex := 0;
end;

procedure TSysFlowFrame.RefreshGrid;
begin
  SetColors;
  with DataGrid do
  begin
    Clear;
    RowCount := ListChartSource1.Count + 1;
    RowHeights[0] := (2 * DefaultRowHeight) + (DefaultRowHeight div 2);
    Refresh;
  end;
end;

procedure TSysFlowFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TSysFlowFrame.SetColors;
begin
  Color := config.ThemeColor;
  DataGrid.FixedColor := config.ThemeColor;
end;

procedure TSysFlowFrame.MnuTimeOfDayClick(Sender: TObject);
begin
  MnuTimeOfDay.Checked := not MnuTimeOfDay.Checked;
  RefreshReport;
end;

procedure TSysFlowFrame.MnuCopyClick(Sender: TObject);
var
  Slist: TStringList;
begin
  if Notebook1.ActivePage = 'ChartPage' then
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

procedure TSysFlowFrame.MnuDataClick(Sender: TObject);
begin
  Notebook1.PageIndex := 1;
end;

procedure TSysFlowFrame.DataGridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  MyTextStyle := DataGrid.Canvas.TextStyle;
  if (aRow = 0) then MyTextStyle.SingleLine := false;
  MyTextStyle.Alignment := taCenter;
  DataGrid.Canvas.TextStyle := MyTextStyle;
end;

procedure TSysFlowFrame.MnuChartClick(Sender: TObject);
begin
  Notebook1.PageIndex := 0;
end;

procedure TSysFlowFrame.DataGridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  S: string;
  H: Integer;
  N: Integer;
begin
  with Sender as TDrawGrid do
  begin
    S := GetDataGridValue(aCol, aRow);
    if aRow = 0 then
      N := 3
    else
      N := 1;
    H := (aRect.Height - N * Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(aRect, aRect.Left+2, aRect.Top + H, S);
  end;
end;

function TSysFlowFrame.GetDataGridValue(C: Integer; R: Integer): string;
var
  I: Integer;
  T: Integer;
  Y: Double;
begin
  Result := '';
  if C = 0 then
  begin
    if R = 0 then
      Result := rsTimeHrs
    else
      Result := FloatToStrF(R - 1, ffFixed, 7, 2);
  end
  else if C = 1 then
  begin
    if R = 0 then
      Result := rsTimeOfDay
    else
    begin
      T := project.StartTime + (R-1) * 3600 + results.Rstart;
      Result := utils.TimeOfDayStr(T);
    end;
  end
  else
  begin
    I := C - 2;
    if R = 0 then
      Result := rsVolume + LineEnding + ChartStyles1.Styles[I].Text +
        LineEnding + Chart1.LeftAxis.Title.Caption
    else
    begin
      Y := Chart1AreaSeries1.GetYValues(R-1, I);
      Result := FloatToStrF(Y, ffFixed, 7, config.DecimalPlaces) + ' ';
    end;
  end;
end;

procedure TSysFlowFrame.MnuSaveClick(Sender: TObject);
begin
  if Notebook1.ActivePage = 'ChartPage' then
    SaveChart
  else
    SaveTable;
end;

procedure TSysFlowFrame.SaveChart;
begin
  with MainForm.SaveDialog1 do
  begin
    FileName := '*.png';
    Filter := rsPngFile;
    DefaultExt := '*.png';
    if Execute then
      Chart1.SaveToFile(TPortableNetworkGraphic, FileName);
  end;
end;

procedure TSysFlowFrame.SaveTable;
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

procedure TSysFlowFrame.GetDataGridContents(Slist: TStringList);
var
  C: Integer;
  R: Integer;
  S: string;
begin
  // Add a title to the contents' stringlist
  S := project.GetTitle(0);
  Slist.Add(S);
  Slist.Add('');
  S := rsSysFlowReport;
  Slist.Add(S);
  Slist.Add('');

  // Add each line of header text as separate rows

  S := rsElapsed + '   ' + #9 + rsRptTime + '      ' +  #9 + rsVolume + '    ' +
       #9 +  rsVolume + '    ' + #9 + rsVolume + '    ';
  Slist.Add(S);

  S := rsRptTime + '      ' + #9 + rsOf + '        ' + #9 + rsStored + '    ' +
       #9  + rsProduced + '  ' + #9 + rsConsumed +'  ';
  Slist.Add(S);

  S := Chart1.LeftAxis.Title.Caption;
  S := '(' + rsHrs + ')     ' + #9 +  rsDay + '       ' + #9 + S + '        ' +
       #9 + S + '        ' + #9 + S + '        ';
  Slist.Add(S);

  // Add each row of the DataGrid to the stringlist
  with DataGrid do
  begin
    for R := 1 to RowCount-1 do
    begin
      S := Format('%-10S', [GetDataGridValue(0, R)]);
      for C := 1 to ColCount-1 do
        S := S + #9 + Format('%-10S', [GetDataGridValue(C, R)]);
      Slist.Add(S);
    end;
  end;
end;

procedure TSysFlowFrame.GetSystemFlowVolumes(T: Integer);
var
  I: Integer;
  D: Single;
begin
  Produced := 0;
  Consumed := 0;

  // Visit each network node
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    // Get the node's demand volume over report time step in ft3
    D := mapthemes.GetNodeValue(I, mapthemes.ntDemand, T);
    if D = MISSING then continue;
    D := D / Dcf * Dt;

    // Update stored volume if node is a Tank
    if project.GetNodeType(I) = ntTank then
      Stored := Stored + D

    // Otherwise add to volume consumed for demand > 0
    // or to volume produced for demand < 0
    else if D > 0 then
      Consumed := Consumed + D
    else
      Produced := Produced - D;
  end;
end;

end.

