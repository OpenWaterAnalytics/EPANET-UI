{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       hydprofilerpt
 Description:  A frame that displays a hydraulic profile plot
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit profilerpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, TAGraph, TASeries,
  TAGUIConnectorBGRA, TACustomSeries, TASources, TAStyles,
  Buttons, Dialogs, Menus, Graphics, Math;

type

  { TProfileRptFrame }

  TProfileRptFrame = class(TFrame)
    Chart1:                 TChart;
    Chart1AreaSeries1:      TAreaSeries;
    ChartStyles1:           TChartStyles;
    ListChartSource1:       TListChartSource;
    ChartGUIConnectorBGRA1: TChartGUIConnectorBGRA;
    ExportMenu:             TPopupMenu;
    MnuNodeLabels:          TMenuItem;
    MnuElevProfile:         TMenuItem;
    MnuProfilePath:         TMenuItem;
    MnuCopy:                TMenuItem;
    MnuSave:                TMenuItem;
    Separator1:             TMenuItem;
    Panel1:                 TPanel;

    procedure Chart1AreaSeries1GetMark(out AFormattedMark: string;
      AIndex: Integer);
    procedure MnuCopyClick(Sender: TObject);
    procedure MnuElevProfileClick(Sender: TObject);
    procedure MnuNodeLabelsClick(Sender: TObject);
    procedure MnuProfilePathClick(Sender: TObject);
    procedure MnuSaveClick(Sender: TObject);

  private
    Nlinks:    Integer;
    LinksList: TStringList;
    NodesList: TStringList;
    PlotEmpty: Boolean;
    procedure AddToPlot(X: Double; I, T: Integer);

  public
    HasProfilePlot: Boolean;
    procedure InitReport;
    procedure CloseReport;
    procedure RefreshReport;
    procedure ShowPopupMenu;
    procedure ShowProfileSelector;
    procedure SetProfileLinks(ProfileLinks: TStrings);

  end;

implementation

{$R *.lfm}

uses
  main, project, profileselector, mapthemes, results, epanet2, reportviewer,
  resourcestrings;

{ TProfileRptFrame }

procedure TProfileRptFrame.InitReport;
var
  S: string;
begin
  LinksList := TStringList.Create;
  NodesList := TStringList.Create;
  Nlinks := 0;
  if project.GetUnitsSystem = usUS then
    S := rsFoot
  else
    S := rsMeter;
  with Chart1.BottomAxis do
  begin
    Title.Caption := rsDistance + ' (' + S + ')';
    Intervals.MaxLength := 100;
  end;
  Chart1.LeftAxis.Title.Caption := S;

  // Bring up the Profile Selector frame
  PlotEmpty := true;
  ShowProfileSelector;
end;

procedure TProfileRptFrame.CloseReport;
begin
  LinksList.Free;
  NodesList.Free;
  MainForm.ProfileSelectorFrame.HasProfilePlot := false;
  MainForm.ProfileSelectorFrame.Init;
  MainForm.ProfileSelectorFrame.Visible := false;
end;

procedure TProfileRptFrame.SetProfileLinks(ProfileLinks: TStrings);
var
  I: Integer;
begin
  LinksList.Clear;
  for I := ProfileLinks.Count - 1 downto 0 do
    LinksList.Add(ProfileLinks[I]);
  RefreshReport;
end;

procedure TProfileRptFrame.RefreshReport;
var
  I: Integer;
  N0: Integer;
  N1: Integer;
  N2: Integer;
  N3: Integer;
  N4: Integer;
  T: Integer;
  LinkIndex: Integer;
  X: Double;
  D: Single;
  Xstart: Double;
  Xend: Double;

begin
  // Clear the current profile plot
  ListChartSource1.Clear;
  NodesList.Clear;
  X := 0;

  // Must have at least one link in a profile
  Nlinks := LinksList.Count;
  if Nlinks < 1 then exit;

  // Set time period to current period shown on network map
  T := mapthemes.TimePeriod;
  Chart1.Foot.Text.Clear;
  Chart1.Foot.Text.Add(results.GetTimeStr(T));
  Chart1AreaSeries1.Marks.Visible:= MnuNodeLabels.Checked;
  Chart1AreaSeries1.Legend.Visible := MnuElevProfile.Checked;

  // Determine the profile's initial starting node N0
  LinkIndex := project.GetItemIndex(ctLinks, LinksList[0]);
  if not project.GetLinkNodes(LinkIndex, N1, N2) then exit;
  N0 := N1;
  if Nlinks > 1 then
  begin
    LinkIndex := project.GetItemIndex(ctLinks, LinksList[1]);
    if project.GetLinkNodes(LinkIndex, N3, N4) then
    begin
      if (N1 = N3)
      or (N1 = N4) then
        N0 := N2 else N0 := N1;
    end;
  end;
  Xstart := 0;

  // Examine each link in the profile
  for I := 0 to Nlinks - 1 do
  begin
    // Add the current starting node to the plot
    AddToPlot(X, N0, T);

    // Update plot distance
    LinkIndex := project.GetItemIndex(ctLinks, LinksList[I]);
    Epanet2.ENgetlinkvalue(LinkIndex, EN_LENGTH, D);
    if D <= 0 then D := 10;
    X := X +  D;

    // Find the next starting node
    if not project.GetLinkNodes(LinkIndex, N1, N2) then continue;
    if N1 = N0 then
      N0 := N2
    else
      N0 := N1;
  end;

  // Add the last node to the plot
  AddToPlot(X, N0, T);
  Xend := 0;

  // Invert X-axis if profile path is from right to left
  if Xstart > Xend then Chart1.BottomAxis.Inverted := true;

  // Add title to plot
  Chart1.Title.Text.Clear;
  Chart1.Title.Text.Add(rsHydProfile + ': ' + rsNode +
      ' ' + NodesList[0] + ' - ' + NodesList[NodesList.Count - 1]);
  PlotEmpty := false;
end;

procedure TProfileRptFrame.AddToPlot(X: Double; I, T: Integer);
var
  E, H: Double;
begin
  E := project.GetNodeParam(I, EN_ELEVATION);
  H := mapthemes.GetNodeValue(I, ntHead, T);
  if MnuElevProfile.Checked = false then
    with ListChartSource1 do AddXYList(X, [NaN, H])
  else
    with ListChartSource1 do AddXYList(X, [E, H-E]);
  NodesList.Add(project.GetID(ctNodes, I));
end;

procedure TProfileRptFrame.ShowProfileSelector;
begin
  ReportViewerForm.Hide;
  MainForm.HideHintPanelFrames;
  MainForm.ProfileSelectorFrame.Visible := true;
  MainForm.ProfileSelectorFrame.HasProfilePlot:= not PlotEmpty;
  if PlotEmpty then MainForm.ProfileSelectorFrame.Init;
end;

procedure TProfileRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TProfileRptFrame.MnuCopyClick(Sender: TObject);
begin
  Chart1.CopyToClipboardBitmap;
end;

procedure TProfileRptFrame.MnuElevProfileClick(Sender: TObject);
begin
  MnuElevProfile.Checked := not MnuElevProfile.Checked;
  RefreshReport;
end;

procedure TProfileRptFrame.MnuNodeLabelsClick(Sender: TObject);
begin
  MnuNodeLabels.Checked := not MnuNodeLabels.Checked;
  RefreshReport;
end;

procedure TProfileRptFrame.MnuProfilePathClick(Sender: TObject);
begin
  ShowProfileSelector;
end;

procedure TProfileRptFrame.MnuSaveClick(Sender: TObject);
begin
  with MainForm.SaveDialog1 do
  begin
    FileName := '*.png';
    Filter := rsPngFile;
    DefaultExt := '*.png';
    if Execute then Chart1.SaveToFile(TPortableNetworkGraphic, FileName);
  end;
end;

procedure TProfileRptFrame.Chart1AreaSeries1GetMark(out AFormattedMark: string;
  AIndex: Integer);
begin
  AFormattedMark := NodesList[aIndex];
end;

end.

