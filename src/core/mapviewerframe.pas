{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mapviewerframe
 Description:  selects themes, time periods, and layers to view on
               the pipe network map.
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit mapviewerframe;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, ComCtrls, LCLtype,
  Graphics, Buttons;

type

  { TMapViewerFrame }

  TMapViewerFrame = class(TFrame)
    MapViewerPanel:     TPanel;
    MapViewerScrollBox: TScrollBox;
    FlowPanel1:         TFlowPanel;
    AnimateTrackBar: TTrackBar;
    ViewGroupBox:       TGroupBox;
    ThemesGroupBox:     TGroupBox;
    TimeGroupBox:       TGroupBox;
    LayersGroupBox:     TGroupBox;
    Label1:             TLabel;
    Label2:             TLabel;
    NodeUnitsLabel:     TLabel;
    LinkUnitsLabel:     TLabel;
    TimeLabel:      TLabel;
    MapRadioButton:     TRadioButton;
    ReportRadioButton:  TRadioButton;
    EditLinkLegendBtn:  TSpeedButton;
    EditNodeLegendBtn:  TSpeedButton;
    BasemapBox:         TCheckBox;
    JunctionsBox:       TCheckBox;
    LinkLegendBox:      TCheckBox;
    MapLabelsBox:       TCheckBox;
    NodeLegendBox:      TCheckBox;
    OverviewMapBox:     TCheckBox;
    PipesBox:           TCheckBox;
    PumpsBox:           TCheckBox;
    TanksBox:           TCheckBox;
    ValvesBox:          TCheckBox;
    ViewLinkCombo:      TComboBox;
    ViewNodeCombo:      TComboBox;
    TimeTrackBar:       TTrackBar;
    AnimateBtn:     TToggleBox;
    AnimationTimer:     TTimer;

    procedure AnimationTimerTimer(Sender: TObject);
    procedure BasemapBoxChange(Sender: TObject);
    procedure JunctionsBoxChange(Sender: TObject);
    procedure LinkLegendBoxChange(Sender: TObject);
    procedure LinkLegendLabelClick(Sender: TObject);
    procedure MapRadioButtonClick(Sender: TObject);
    procedure NodeLegendBoxChange(Sender: TObject);
    procedure NodeLegendLabelClick(Sender: TObject);
    procedure OverviewMapBoxChange(Sender: TObject);
    procedure AnimateTrackBarChange(Sender: TObject);
    procedure AnimateBtnChange(Sender: TObject);
    procedure ViewLinkComboChange(Sender: TObject);
    procedure ViewNodeComboChange(Sender: TObject);
    procedure TimeTrackBarChange(Sender: TObject);
    procedure TimeTrackBarKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TimeTrackBarKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure TimeTrackBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure TimeTrackBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    function GetViewTime(Period: Integer): string;

  public
    procedure Init;
    procedure InitMapThemes;
    procedure ResetMapThemes;
    procedure InitTimeGroupBox(const N: Integer);
    procedure EnableLegend(LegendType: Integer; State: Boolean);
    procedure SetBasemapCheckBox(BasemapVisible: Boolean);

  end;

implementation

{$R *.lfm}

uses
  main, config, project, mapthemes, results, reportframe, utils,
  resourcestrings;

const
  AnimationSpeed: array[1..5] of Integer = (1500, 1250, 1000, 750, 500);

procedure TMapViewerFrame.AnimateBtnChange(Sender: TObject);
begin
  AnimationTimer.Enabled := AnimateBtn.Checked;
end;

procedure TMapViewerFrame.AnimationTimerTimer(Sender: TObject);
begin
  with TimeTrackBar do
  begin
    if Position = Max then
      Position := 0
    else
      Position := Position + 1;
  end;
  mapthemes.ChangeTimePeriod(TimeTrackBar.Position);
  MainForm.ProjectFrame.UpdateResultsDisplay;
  MainForm.ReportFrame.ChangeTimePeriod;
end;

procedure TMapViewerFrame.BasemapBoxChange(Sender: TObject);
begin
  MainForm.MapFrame.Map.Options.ShowBackdrop := BasemapBox.Checked;
  if BasemapBox.Checked then
    MainForm.MapFrame.Map.Basemap.NeedsRedraw := true;
  MainForm.MapFrame.RedrawMap;
end;

procedure TMapViewerFrame.JunctionsBoxChange(Sender: TObject);
begin
  with Sender as TCheckBox do
  begin
    MainForm.MapFrame.ShowLayer(Tag, Checked);
  end;
end;

procedure TMapViewerFrame.LinkLegendBoxChange(Sender: TObject);
begin
  MainForm.MapFrame.LinkLegend.Visible := LinkLegendBox.Checked;
end;

procedure TMapViewerFrame.LinkLegendLabelClick(Sender: TObject);
begin
  if mapthemes.EditLinkLegend then
    MainForm.MapFrame.RedrawMap;
end;

procedure TMapViewerFrame.MapRadioButtonClick(Sender: TObject);
begin
  if MapRadioButton.Checked then
    MainForm.Notebook1.PageIndex := 0
  else
    MainForm.Notebook1.PageIndex := 1;
end;

procedure TMapViewerFrame.NodeLegendBoxChange(Sender: TObject);
begin
  MainForm.MapFrame.NodeLegend.Visible := NodeLegendBox.Checked;
end;

procedure TMapViewerFrame.NodeLegendLabelClick(Sender: TObject);
begin
  if mapthemes.EditNodeLegend then
    MainForm.MapFrame.RedrawMap;
end;

procedure TMapViewerFrame.OverviewMapBoxChange(Sender: TObject);
begin
  MainForm.OverviewPanel.Visible := OverviewMapBox.Checked;
  if OverviewMapBox.Checked then
    MainForm.OverviewMapFrame.Redraw;
end;

procedure TMapViewerFrame.AnimateTrackBarChange(Sender: TObject);
begin
  AnimationTimer.Interval := AnimationSpeed[AnimateTrackBar.Position];
end;

procedure TMapViewerFrame.ViewLinkComboChange(Sender: TObject);
begin
  mapthemes.ChangeTheme(ctLinks, ViewLinkCombo.ItemIndex);
  MainForm.MapFrame.RedrawMap;
  EditLinkLegendBtn.Enabled := (ViewLinkCombo.ItemIndex > 0);
  LinkLegendBox.Enabled := EditLinkLegendBtn.Enabled;
end;

procedure TMapViewerFrame.ViewNodeComboChange(Sender: TObject);
begin
  mapthemes.ChangeTheme(ctNodes, ViewNodeCombo.ItemIndex);
  MainForm.MapFrame.RedrawMap;
  EditNodeLegendBtn.Enabled := (ViewNodeCombo.ItemIndex > 0);
  NodeLegendBox.Enabled := EditNodeLegendBtn.Enabled;
end;

procedure TMapViewerFrame.TimeTrackBarChange(Sender: TObject);
begin
  if project.HasResults then
  begin
     TimeLabel.Caption := GetViewTime(TimeTrackBar.Position);
     if TimeTrackBar.Tag = 1 then
     begin
       TimeTrackBar.Tag := 0;
       mapthemes.ChangeTimePeriod(TimeTrackBar.Position);
       MainForm.ProjectFrame.UpdateResultsDisplay;
       MainForm.ReportFrame.ChangeTimePeriod;
     end;
  end;
end;

procedure TMapViewerFrame.TimeTrackBarKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key in
    [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT]
  then TimeTrackBar.Tag := 0;
end;

procedure TMapViewerFrame.TimeTrackBarKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key in
    [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT]
  then
  begin
    TimeTrackBar.Tag := 1;
    TimeTrackBarChange(Sender);
  end;
end;

procedure TMapViewerFrame.TimeTrackBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TimeTrackBar.Tag := 0;
end;

procedure TMapViewerFrame.TimeTrackBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  TimeTrackBar.Tag := 1;
  TimeTrackBarChange(Sender);
end;

procedure TMapViewerFrame.Init;
var
  I: Integer;
begin
  mapthemes.InitThemes;
  ViewNodeCombo.Clear;
  for I := 0 to High(mapthemes.NodeThemes) do
    ViewNodeCombo.Items.Add(mapthemes.NodeThemes[I].Name);
  ViewLinkCombo.Clear;
  for I := 0 to High(mapthemes.LinkThemes) do
    ViewLinkCombo.Items.Add(mapthemes.LinkThemes[I].Name);
  InitMapThemes;

  MainForm.MapFrame.NodeLegend.Visible := false;
  MainForm.MapFrame.LinkLegend.Visible := false;
  NodeLegendBox.Checked := false;
  LinkLegendBox.Checked := false;
  EditNodeLegendBtn.Enabled := true;
  EditLinkLegendBtn.Enabled := true;

  TimeLabel.Caption := '';
  InitTimeGroupBox(0);

  JunctionsBox.Checked := true;
  TanksBox.Checked := true;
  PipesBox.Checked := true;
  PumpsBox.Checked := true;
  ValvesBox.Checked := true;
  MapLabelsBox.Checked := true;
  OverviewMapBox.Checked := false;
  BasemapBox.Checked := false;
  BasemapBox.Enabled := false;
end;

procedure TMapViewerFrame.InitTimeGroupBox(const N: Integer);
// N = number of time periods in simulation
var
  I: Integer;
begin
  mapthemes.TimePeriod := 0;
  TimeTrackBar.Position:=0;
  TimeLabel.Caption := '';
  AnimateBtn.Enabled := false;
  TimeGroupBox.Enabled := false;
  TimeGroupBox.Visible := false;

  // Simulation results were converted to a summary statistic
  I := project.GetStatisticsType;
  if I <> 0 then
  begin
    TimeGroupBox.Visible := true;
    TimeLabel.Caption := rsThemesAre + project.StatisticStr[I];
  end

  // Simulation results are extended period time series
  else if N > 1 then
  begin
    TimeGroupBox.Visible := true;
    TimeGroupBox.Enabled := true;
    TimeTrackBar.Enabled := true;
    TimeTrackBar.Max := N - 1;
    AnimateBtn.Enabled := (N > 1);
    TimeLabel.Caption := GetViewTime(0);
  end

  // Simulation was a snapshot analysis
  else
  begin
    TimeGroupBox.Visible := false;
  end;
end;

procedure TMapViewerFrame.InitMapThemes;
begin
  ViewNodeCombo.ItemIndex := ntElevation;
  EditNodeLegendBtn.Enabled := true;
  ViewLinkCombo.ItemIndex := ltDiameter;
  EditLinkLegendBtn.Enabled := true;
  mapthemes.SetInitialTheme(ctNodes, ntElevation);
  mapthemes.SetInitialTheme(ctLinks, ltDiameter);
end;

procedure TMapViewerFrame.ResetMapThemes;
var
  I: Integer;
  J: Integer;
begin
  J := ViewNodeCombo.ItemIndex;
  if J >= NodeThemeCount then J := 0;
  ViewNodeCombo.Items.Clear;
  for I := 0 to NodeThemeCount - 1 do
    ViewNodeCombo.Items.Add(mapthemes.NodeThemes[I].Name);
  ViewNodeCombo.ItemIndex := J;

  J := ViewLinkCombo.ItemIndex;
  if J >= LinkThemeCount then J := 0;
  ViewLinkCombo.Items.Clear;
  for I := 0 to LinkThemeCount - 1 do
    ViewLinkCombo.Items.Add(mapthemes.LinkThemes[I].Name);
  ViewLinkCombo.ItemIndex := J;

  mapthemes.ChangeTheme(ctNodes, ViewNodeCombo.ItemIndex);
  mapthemes.ChangeTheme(ctLinks, ViewLinkCombo.ItemIndex);
end;

procedure TMapViewerFrame.EnableLegend(LegendType: Integer; State: Boolean);
begin
  if LegendType = ctNodes then
  begin
    NodeLegendBox.Enabled := State;
    EditNodeLegendBtn.Enabled := State;
  end
  else if LegendType = ctLinks then
  begin
    LinkLegendBox.Enabled := State;
    EditLinkLegendBtn.Enabled := State;
  end
end;

procedure TMapViewerFrame.SetBasemapCheckBox(BasemapVisible: Boolean);
begin
  if MainForm.MapFrame.HasBasemap then
  begin
    BasemapBox.Enabled := true;
    BasemapBox.Checked := BasemapVisible;
  end
  else
  begin
    BasemapBox.Enabled := false;
    BasemapBox.Checked := BasemapVisible;
  end;
end;

function TMapViewerFrame.GetViewTime(Period: Integer): string;
var
  T: Integer;
begin
  Result := results.GetTimeStr(Period);
  T := project.StartTime + (Period * results.Rstep) + results.Rstart;
  Result := Result + '  (' + utils.TimeOfDayStr(T) + ')';
end;

end.

