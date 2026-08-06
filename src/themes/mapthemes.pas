{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mapthemes
 Description:  Manages the display of node and link themes on
               the pipe network map
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit mapthemes;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, ComCtrls, Graphics, Dialogs, Controls, Math;

const

  // Node themes
  ntElevation  = 1;
  ntBaseDemand = 2;
  ntDemand     = 3;
  ntDmndDfct   = 4;
  ntEmittance  = 5;
  ntLeakage    = 6;
  ntHead       = 7;
  ntPressure   = 8;
  FirstNodeResultTheme = 3;
  FirstNodeQualTheme = 9;

  // Link Themes
  ltDiameter   = 1;
  ltLength     = 2;
  ltRoughness  = 3;
  ltFlow       = 4;
  ltVelocity   = 5;
  ltHeadloss   = 6;
  ltLeakage    = 7;
  FirstLinkResultTheme = 4;
  FirstLinkQualTheme = 8;

  // Additional link themes
  ltEnergy  = 99;
  ltStatus  = 98;
  ltSetting = 97;

  MISSING = -1.E10;   // Missing value
  MAXLEVELS = 4;      // Number of color-coded theme levels

  DefLegendColors: array[0..MAXLEVELS] of TColor =  //order is BB GG RR
    ($00BE9270, $00EAD999, $001DE6B5, $000EC9FF, $00277FFF);

//  Viridis Scale
//  ($00540144, $008b513b, $008d9021, $0063c85c, $0025e7fd); //

type
  TMapTheme = record
    Name:         string;                 // Theme name
    SourceIndex:  Integer;                // Index used by data source
    DefIntervals: array[1..MAXLEVELS] of string;  // Default display intervals
end;

  TLegendIntervals = record
    Labels: array[1..MAXLEVELS] of string;
    Values: array[1..MAXLEVELS] of Single;
  end;

var
  LinkColors:       array[0..MAXLEVELS] of TColor;
  LinkIntervals:    array of TLegendIntervals;
  LinkTheme:        Integer;
  LinkThemes:       array of TMapTheme;
  LinkThemeCount:   Integer;
  NodeColors:       array[0..MAXLEVELS] of TColor;
  NodeIntervals:    array of TLegendIntervals;
  NodeTheme:        Integer;
  NodeThemes:       array of TMapTheme;
  NodeThemeCount:   Integer;
  QualThemeCount:   Integer;
  QualThemeUnits:   string;
  TimePeriod:       Integer;

procedure ChangeTimePeriod(NewTimePeriod: Integer);
procedure ChangeTheme(ThemeType: Integer; NewTheme: Integer);

function  EditNodeLegend: Boolean;
function  EditLinkLegend: Boolean;

function  GetCurrentThemeValue(ObjType: Integer; ObjIndex: Integer): Single;
function  GetFlowDir(LinkIndex: Integer): Integer;
function  GetLinkColor(LinkIndex: Integer; var ColorIndex: Integer): TColor;
function  GetLinkValue(LinkIndex, aTheme, aTimePeriod: Integer): Single;
function  GetMinMaxValues(ObjType: Integer; var Vmin: Double; var Vmax: Double): Boolean;
function  GetNodeColor(NodeIndex: Integer; var ColorIndex: Integer): TColor;
function  GetNodeValue(NodeIndex: Integer; aTheme: Integer;  aTimePeriod: Integer): Single;
function  GetStatusStr(Status: Integer): String;
function  GetThemeUnits(ThemeType: Integer; aTheme: Integer): string;

procedure InitColors;
procedure InitThemes;

procedure ResetThemes;
procedure SetInitialTheme(ThemeType: Integer; aTheme: Integer);
procedure UpdateLegend(ThemeType: Integer; ThemeIndex: Integer;
  ThemeName: string; ThemeUnits: string);

implementation

uses
  main, project, groupeditor, legendeditor, results, utils, resourcestrings;

const
  BaseNodeThemes: array[0..ntPressure] of TMapTheme =
  (
    (Name:rsNone;
     SourceIndex:-1;
     DefIntervals:('','','','')),

    (Name:rsElevation;
     SourceIndex:0;    // = EN_ELEVATION
     DefIntervals:('25','50','75','100')),

    (Name:rsBaseDemand;
     SourceIndex:1;    // = EN_BASEDEMAND
     DefIntervals:('25','50','75','100')),

    (Name:rsTotalDemand;
     SourceIndex:0;
     DefIntervals:('25','50','75','100')),

     (Name:rsDemandDeficit;
      SourceIndex:100;
      DefIntervals:('25','50','75','100')),

      (Name:rsEmitterFlow;
       SourceIndex:100;
       DefIntervals:('5','10','20','50')),

     (Name:rsLeakage;
      SourceIndex:100;
      DefIntervals:('5','10','20','50')),

    (Name:rsHydraulicHead;
     SourceIndex:1;
     DefIntervals:('25','50','75','100')),

    (Name:rsPressure;
     SourceIndex:2;
     DefIntervals:('25','50','75','100'))
  );

  BaseLinkThemes: array[0..7] of TMapTheme =
  (
    (Name:rsNone;
     SourceIndex:-1;
     DefIntervals:('','','','')),

    (Name:rsDiameter;
     SourceIndex:0;    // = EN_DIAMETER
     DefIntervals:('6','12','24','36')),

    (Name:rsLength;
     SourceIndex:1;    // = EN_LENGTH
     DefIntervals:('100','500','1000','5000')),

    (Name:rsRoughness;
     SourceIndex:2;    // = EN_ROUGHNESS
     DefIntervals:('50','75','100','125')),

    (Name:rsFlowRate;
     SourceIndex:0;
     DefIntervals:('25','50','75','100')),

    (Name:rsVelocity;
     SourceIndex:1;
     DefIntervals:('0.01','0.1','1.0','2.0')),

    (Name:rsHeadLoss;
     SourceIndex:2;
     DefIntervals:('0.025','0.05','0.075','0.1')),

    (Name:rsLeakage;
     SourceIndex:200;
     DefIntervals:('5','10','20','50'))
  );

  DefQualIntervalLabels:  array[1..MAXLEVELS] of string =
    ('1', '10', '50', '80');
  DefQualIntervalValues: array[1..MAXLEVELS] of Single =
    (1, 10, 50, 80);

function GetCurrentThemeValue(ObjType: Integer; ObjIndex: Integer): Single;
begin
  if ObjType = ctNodes then
    Result := GetNodeValue(ObjIndex, NodeTheme, TimePeriod)
  else if ObjType = ctLinks then
    Result := GetLinkValue(ObjIndex, LinkTheme, TimePeriod)
  else
    Result := MISSING;
end;

function  GetNodeValue(NodeIndex: Integer; aTheme: Integer;
  aTimePeriod: Integer): Single;
var
  ParamIndex:   Integer;
  ResultIndex:  Integer;
begin
  if aTheme <= 0 then
    Result := MISSING
  else
  begin
    // Theme is a design parameter
    if aTheme < FirstNodeResultTheme then
    begin
      ParamIndex := NodeThemes[aTheme].SourceIndex;
      Result := project.GetNodeParam(NodeIndex, ParamIndex)
    end

    // Project has no simulation results
    else if not project.HasResults then
      Result := MISSING

    // Project has results
    else
    begin
      // Find index of node in results file
      ParamIndex := NodeThemes[aTheme].SourceIndex;
      ResultIndex := project.GetResultIndex(ctNodes, NodeIndex);
      if ResultIndex < 1 then
        Result := MISSING
      else
      begin

        // Theme results reside in the MSX (multi-species) output file
        if MsxFileOpened
        and (aTheme >= FirstNodeQualTheme) then
          Result := results.GetNodeMsxValue(ResultIndex, ParamIndex, aTimePeriod)

        // Theme results reside in the secondary output file
        else if (aTheme = ntDmndDfct) then
        begin
          if OutFile2Opened then
            Result := results.GetDmndDfctValue(ResultIndex, aTimePeriod)
          else
            Result := MISSING
        end
        else if (aTheme = ntEmittance) then
        begin
          if OutFile2Opened then
            Result := results.GetEmitterFlowValue(ResultIndex, aTimePeriod)
          else
            Result := MISSING
        end
        else if (aTheme = ntLeakage) then
        begin
          if OutFile2Opened then
            Result := results.GetNodeLeakageValue(ResultIndex, aTimePeriod)
          else
            Result := MISSING
        end

        // Theme results reside in the primary output file
        else if OutFileOpened then
        begin
          Result := results.GetNodeValue(ResultIndex, ParamIndex, aTimePeriod);
        end
        else
          Result := MISSING;
      end;
    end;
  end;
end;

function GetLinkResultFromFile(ResultIndex, aTheme, aTimePeriod: Integer): Single;
var
  ParamIndex: Integer = -1;
begin
  // Theme results reside in the MSX output file
  Result := MISSING;
  if MsxFileOpened
  and (aTheme >= FirstLinkQualTheme)
  and (aTheme < FirstLinkQualTheme + QualThemeCount) then
  begin
    ParamIndex := LinkThemes[aTheme].SourceIndex;
    Result := results.GetLinkMsxValue(ResultIndex, ParamIndex, aTimePeriod);
    exit;
  end;

  // Theme results reside in the secondary output file
  if aTheme = ltLeakage then
  begin
    if OutFile2Opened then
    begin
      Result := results.GetLinkLeakageValue(ResultIndex, aTimePeriod);
      exit;
    end;
  end;
  if aTheme = ltEnergy then
  begin
    if OutFile2Opened then
      Result := results.GetLinkEnergyValue(ResultIndex, aTimePeriod);
      exit;
    end;

  // Theme results reside in the primary output file
  if OutFileOpened then
  begin
    if aTheme = FirstLinkQualTheme then
      ParamIndex := FirstLinkQualTheme - FirstLinkResultTheme - 1
    else if aTheme = ltStatus then
      ParamIndex := 4
    else if aTheme = ltSetting then
      ParamIndex := 5
    else if aTheme < LinkThemeCount then
      ParamIndex := LinkThemes[aTheme].SourceIndex;
    if ParamIndex >= 0 then
      Result := results.GetLinkValue(ResultIndex, ParamIndex, aTimePeriod);
  end;
end;

function  GetLinkValue(LinkIndex, aTheme, aTimePeriod: Integer): Single;
var
  ResultIndex: Integer;
begin
  Result := MISSING;
  if aTheme <= 0 then exit;

  // Theme is a design parameter (diameter, length, etc.)
  if aTheme < FirstLinkResultTheme then
  begin
    Result := project.GetLinkParam(LinkIndex, LinkThemes[aTheme].SourceIndex);
    exit;
  end;

  // Theme is a simulation result but no results exist
  if not project.HasResults then exit;

  // Find index of link in the output file
  ResultIndex := project.GetResultIndex(ctLinks, LinkIndex);
  if ResultIndex < 1 then exit;

  // Lookup link result from the appropriate output file
  Result := GetLinkResultFromFile(ResultIndex, aTheme, aTimePeriod);
end;

function GetFlowDir(LinkIndex: Integer): Integer;
//
// Find a link's flow direction (+1 or -1).
//
var
  FlowIndex: Integer;
  ResultIndex: Integer;
begin
  Result := 1;
  if project.HasResults then
  begin
    FlowIndex := LinkThemes[ltFlow].SourceIndex;
    ResultIndex := project.GetResultIndex(ctLinks, LinkIndex);
    if (ResultIndex >= 1)
    and (results.GetLinkValue(ResultIndex, FlowIndex, TimePeriod) < 0) then
      Result := -1;
  end;
end;

procedure InitThemes;
//
// Initialize the main form's  MapViewerFrame.
//
var
  I:        Integer;
  J:        Integer;
  S:        string;
begin
  QualThemeCount := 0;
  TimePeriod := 0;

  // Load base node themes
  NodeThemeCount := ntPressure + 1;
  SetLength(NodeThemes, NodeThemeCount);
  for I := 0 to NodeThemeCount-1 do
    NodeThemes[I] := BaseNodeThemes[I];

  // Assign default legend intervals for node themes
  SetLength(NodeIntervals, NodeThemeCount);
  for I := 1 to NodeThemeCount-1 do
  begin
    for J := 1 to MAXLEVELS do
    begin
      S := NodeThemes[I].DefIntervals[J];
      NodeIntervals[I].Labels[J] := S;
      utils.Str2Float(S, NodeIntervals[I].Values[J]);
    end;
  end;

  // Load base link themes
  LinkThemeCount := ltLeakage + 1;
  SetLength(LinkThemes, LinkThemeCount);
  for I := 0 to LinkThemeCount-1 do
    LinkThemes[I] := BaseLinkThemes[I];

  // Assign default legend intervals for link themes
  SetLength(LinkIntervals, LinkThemeCount);
  for I := 1 to LinkThemeCount-1 do
  begin
    for J := 1 to MAXLEVELS do
    begin
      S := LinkThemes[I].DefIntervals[J];
      LinkIntervals[I].Labels[J] := S;
      utils.Str2Float(S, LinkIntervals[I].Values[J]);
    end;
  end;
  InitColors;
end;

procedure InitColors;
var
  I: Integer;
begin
  for I := 0 to High(DefLegendColors) do
  begin
    NodeColors[I] := DefLegendColors[I];
    LinkColors[I] := DefLegendColors[I];
  end;
end;

procedure ResetThemes;
var
  I, J:                   Integer;
  OldThemeCount:          Integer;
  OldQualThemeCount:      Integer;
  LastNonQualSourceIndex: Integer;
begin
  if project.HasResults then
  begin
    OldQualThemeCount := QualThemeCount;
    QualThemeCount := results.GetQualCount;

    OldThemeCount := NodeThemeCount;
    NodeThemeCount := ntPressure + QualThemeCount + 1;
    if NodeThemeCount <> OldThemeCount then
    begin
      SetLength(NodeThemes, NodeThemeCount);
      SetLength(NodeIntervals, NodeThemeCount);
    end;

    LastNonQualSourceIndex := NodeThemes[FirstNodeQualTheme-1].SourceIndex;
    for I := FirstNodeQualTheme to NodeThemeCount - 1 do
    begin
      J := I - FirstNodeQualTheme;
      if MsxFlag then
        NodeThemes[I].SourceIndex := J
      else
        NodeThemes[I].SourceIndex := LastNonQualSourceIndex + J + 1;
      NodeThemes[I].Name := GetQualName(J);
      if J > OldQualThemeCount - 1 then
      begin
        NodeIntervals[I].Labels := DefQualIntervalLabels;
        NodeIntervals[I].Values := DefQualIntervalValues;
      end;
    end;

    OldThemeCount := LinkThemeCount;
    LinkThemeCount := ltLeakage + QualThemeCount + 1;
    if LinkThemeCount <> OldThemeCount then
    begin
      SetLength(LinkThemes, LinkThemeCount);
      SetLength(LinkIntervals, LinkThemeCount);
    end;
    for I := FirstLinkQualTheme to LinkThemeCount - 1 do
    begin
      J := I - FirstLinkQualTheme;
      if MsxFlag then
        LinkThemes[I].SourceIndex := J
      else
        LinkThemes[I].SourceIndex := I - FirstLinkResultTheme;
      LinkThemes[I].Name := GetQualName(J);
      if J > OldQualThemeCount - 1 then
      begin
        LinkIntervals[I].Labels := DefQualIntervalLabels;
        LinkIntervals[I].Values := DefQualIntervalValues;
      end;
    end;
  end
  else
  begin
    OldThemeCount := NodeThemeCount;
    NodeThemeCount := ntPressure + 1;
    if NodeThemeCount <> OldThemeCount then
    begin
      SetLength(NodeThemes, NodeThemeCount);
      SetLength(NodeIntervals, NodeThemeCount);
    end;
    OldThemeCount := LinkThemeCount;
    LinkThemeCount := ltLeakage + 1;
    if LinkThemeCount <> OldThemeCount then
    begin
      SetLength(LinkThemes, LinkThemeCount);
      SetLength(LinkIntervals, LinkThemeCount);
    end;
  end;

  MainForm.MapViewerFrame.ResetMapThemes;
  MainForm.MapFrame.RedrawMap;
end;

procedure ChangeTheme(ThemeType: Integer; NewTheme: Integer);
var
  ThemeName:     string;
  ThemeUnits:    string;
begin
  // Select theme's parameters
  if ThemeType = ctNodes then
  begin
    ThemeName := NodeThemes[NewTheme].Name;
    NodeTheme := NewTheme;
  end
  else if ThemeType = ctLinks then
  begin
    ThemeName := LinkThemes[NewTheme].Name;
    LinkTheme := NewTheme;
  end
  else
    exit;

  // Update theme's units label on the MapViewerFrame
  ThemeUnits := GetThemeUnits(ThemeType, NewTheme);
  if ThemeType = ctNodes then
    MainForm.MapViewerFrame.NodeUnitsLabel.Caption := ThemeUnits
  else if ThemeType = ctLinks then
    MainForm.MapViewerFrame.LinkUnitsLabel.Caption := ThemeUnits;

  // Update the theme's legend
  UpdateLegend(ThemeType, NewTheme, ThemeName, ThemeUnits);

end;

procedure UpdateLegend(ThemeType: Integer; ThemeIndex: Integer;
  ThemeName: string; ThemeUnits: string);
begin
  if ThemeType = ctNodes then
  begin
    if ThemeIndex = 0 then
    begin
      MainForm.MapFrame.NodeLegend.Visible := false;
      MainForm.MapViewerFrame.EnableLegend(ctNodes, false);
    end
    else
    begin

      MainForm.MapViewerFrame.EnableLegend(ctNodes, true);
      MainForm.MapFrame.NodeLegend.DrawLegend(NodeColors,
        NodeIntervals[ThemeIndex].Labels, ThemeName, ThemeUnits);
      if MainForm.MapViewerFrame.NodeLegendBox.Checked then
        MainForm.MapFrame.NodeLegend.Visible := true;

    end;
  end;

  if ThemeType = ctLinks then
  begin
    if ThemeIndex = 0 then
    begin
      MainForm.MapFrame.LinkLegend.Visible := false;
      MainForm.MapViewerFrame.EnableLegend(ctLinks, false);
    end
    else
    begin

      MainForm.MapViewerFrame.EnableLegend(ctLinks, true);
//      IsFramed := MainForm.MapFrame.LinkLegend.Framed;
      MainForm.MapFrame.LinkLegend.DrawLegend(LinkColors,
        LinkIntervals[ThemeIndex].Labels, ThemeName, ThemeUnits); //, IsFramed);
      if MainForm.MapViewerFrame.LinkLegendBox.Checked then
        MainForm.MapFrame.LinkLegend.Visible := true;

    end;
  end;

end;

function EditNodeLegend: Boolean;
var
  IsFramed: Boolean;
begin
  Result := false;
  IsFramed := MainForm.MapFrame.NodeLegend.Framed;
  with TLegendEditorForm.Create(MainForm) do
  try
    LoadData(ctNodes, NodeThemes[NodeTheme].Name, NodeColors,
      NodeIntervals[NodeTheme], IsFramed);
    ShowModal;
    if ModalResult = mrOk then
    begin
      UnloadData(NodeColors, NodeIntervals[NodeTheme], IsFramed);
      MainForm.MapFrame.NodeLegend.Framed := IsFramed;
      ChangeTheme(ctNodes, NodeTheme);
      Result := true;
    end;
  finally
    Free;
  end;
end;

function EditLinkLegend: Boolean;
var
  IsFramed: Boolean;
begin
  Result := false;
  IsFramed := MainForm.MapFrame.LinkLegend.Framed;
  with TLegendEditorForm.Create(MainForm) do
  try
    LoadData(ctLinks, LinkThemes[LinkTheme].Name, LinkColors,
      LinkIntervals[LinkTheme], IsFramed);
    ShowModal;
    if ModalResult = mrOk then
    begin
      UnloadData(LinkColors, LinkIntervals[LinkTheme], IsFramed);
      MainForm.MapFrame.LinkLegend.Framed := IsFramed;
      ChangeTheme(ctLinks, LinkTheme);
      Result := true;
    end;
  finally
    Free;
  end;
end;

procedure ChangeTimePeriod(NewTimePeriod: Integer);
begin
  TimePeriod := NewTimePeriod;
  if (LinkTheme >= FirstLinkResultTheme)
  or (NodeTheme >= FirstNodeResultTheme) then
  begin
    if MainForm.QueryFrame.Visible then
      MainForm.QueryFrame.UpdateResults
    else
      MainForm.MapFrame.RedrawMap;
  end;
end;

function GetNodeColor(NodeIndex: Integer; var ColorIndex: Integer): TColor;
var
  Value: Single;
  K:     Integer;
begin
  ColorIndex := 0;
  if MainForm.QueryFrame.Visible then
    Result := MainForm.QueryFrame.GetFilteredNodeColor(NodeIndex)
  else if MainForm.GroupSelectorFrame.IsActive then
    Result := MainForm.GroupSelectorFrame.GetSelectedNodeColor(NodeIndex)
  else if NodeTheme <= 0 then
    Result := clGray
  else
  begin
    Value := GetCurrentThemeValue(ctNodes, NodeIndex);
    if Value = MISSING then
      Result := clGray
    else
    begin
      for K := 1 to MAXLEVELS do
      begin
        if Value < NodeIntervals[NodeTheme].Values[K] then
        begin
          ColorIndex := K-1;
          break;
        end;
        ColorIndex := K;
      end;
      Result := NodeColors[ColorIndex];
    end;
  end;
end;

function GetLinkColor(LinkIndex: Integer; var ColorIndex: Integer): TColor;
var
  Value: Single;
  K:     Integer;
begin
  ColorIndex := 0;
  if MainForm.QueryFrame.Visible then
    Result := MainForm.QueryFrame.GetFilteredLinkColor(LinkIndex)
  else if MainForm.GroupSelectorFrame.IsActive then
    Result := MainForm.GroupSelectorFrame.GetSelectedLinkColor(LinkIndex)
  else if LinkTheme <= 0 then
    Result := clGray
  else
  begin
    Value := GetCurrentThemeValue(ctLinks, LinkIndex);
    if Value = MISSING then
      Result := clGray
    else
    begin
      Value := Abs(Value);
      for K := 1 to MAXLEVELS do
      begin
        if Value < LinkIntervals[LinkTheme].Values[K] then
        begin
          ColorIndex := K-1;
          break;
        end;
        ColorIndex := K;
      end;
      Result := LinkColors[ColorIndex];
    end;
  end;
end;

function GetMinMaxValues(ObjType: Integer; var Vmin: Double;
  var Vmax: Double): Boolean;
//
// Find the range of values for an object's current theme.
//
var
  I: Integer;
  N: Integer;
  V: Double;
begin
  Vmax := -1.e50;
  Vmin := 1.e50;
  Result := false;

  if not project.HasResults then
  begin
    if (ObjType = ctNodes)
    and (NodeTheme >= FirstNodeResultTheme) then
      exit;
    if (ObjType = ctLinks)
    and (LinkTheme >= FirstLinkResultTheme) then
      exit;
  end;

  N := project.GetItemCount(ObjType);
  if N = 0 then exit;
  for I := 1 to N do
  begin
    V := GetCurrentThemeValue(ObjType, I);
    if V <> MISSING then
    begin
      if (ObjType = ctNodes) then
      begin
        if GetNodeType(I) in [ntReservoir, ntTank] then continue;
        if NodeTheme in [ntBaseDemand, ntDemand] then V := Abs(V);
        if NodeTheme = ntPressure then V := Max(V, 0.01);
      end;
      if (ObjType = ctLinks) then
      begin
        if LinkTheme in [ltFlow, ltVelocity, ltHeadloss] then V := Abs(V);
      end;
      Vmax := Max(Vmax, V);
      Vmin := Min(Vmin, V);
    end;
  end;
  if (Vmax < Vmin) then exit;
  Result := true;
end;

procedure SetInitialThemeIntervals(ThemeType: Integer;
  var Intervals: TLegendIntervals);
var
  I:         Integer;
  Vmin:      Double = 0;
  Vmax:      Double = 0;
  Vinterval: Double;
begin
  if GetMinMaxValues(ThemeType, Vmin, Vmax) then
  begin
    Vinterval := (Vmax - Vmin) / (MAXLEVELS + 1);
    utils.AutoScale(Vmin, Vmax, Vinterval);
    for I := 1 to MAXLEVELS do
    begin
      Intervals.Values[I] := Single(Vmin + I * Vinterval);
      Intervals.Labels[I] := FloatToStr(Intervals.Values[I]);
    end;
  end;
end;

procedure SetInitialTheme(ThemeType: Integer; aTheme: Integer);
var
  Intervals: TLegendIntervals;
begin
  if ThemeType = ctNodes then
  begin
    NodeTheme := aTheme;
    Intervals := NodeIntervals[NodeTheme]
  end
  else if ThemeType = ctLinks then
  begin
    LinkTheme := aTheme;
    Intervals := LinkIntervals[LinkTheme]
  end
  else
    exit;
  SetInitialThemeIntervals(ThemeType, Intervals);
  if ThemeType = ctNodes then
    NodeIntervals[aTheme] := Intervals;
  if ThemeType = ctLinks then
    LinkIntervals[aTheme] := Intervals;
  ChangeTheme(ThemeType, aTheme);
end;

function  GetThemeUnits(ThemeType: Integer; aTheme: Integer): string;
begin
  Result := '';
  if ThemeType = ctNodes then case aTheme of
    ntElevation,
    ntHead:
      if project.GetUnitsSystem = usUS then
        Result := rsFoot
      else
        Result := rsMeters;
    ntBaseDemand,
    ntDemand:
      Result := project.FlowUnitsStr[project.FlowUnits];
    ntDmndDfct:
      Result := rsPcntSymbol;
    ntEmittance, ntLeakage:
      Result := project.FlowUnitsStr[project.FlowUnits];
    ntPressure:
      Result := project.PressureUnitsStr[project.PressureUnits];
    else
      Result := results.GetQualUnits(aTheme - ntPressure - 1);
  end

  else if ThemeType = ctLinks then case aTheme of
    ltDiameter:
      if project.GetUnitsSystem = usUS then
        Result := rsInch
      else
        Result := rsMillimeter;
    ltLength:
      if project.GetUnitsSystem = usUS then
        Result := rsFoot
      else
        Result := rsMeters;
    ltRoughness:
      Result := '';
    ltFlow:
      Result := project.FlowUnitsStr[project.FlowUnits];
    ltVelocity:
      if project.GetUnitsSystem = usUS then
        Result := rsFeetPerSec
      else
        Result := rsMetersPerSec;
    ltHeadloss:
      if project.GetUnitsSystem = usUS then
        Result := rsFtPerKiloFt
      else
        Result := rsMetersPerKm;
    ltLeakage:
      Result := project.FlowUnitsStr[project.FlowUnits];
    ltStatus,
    ltSetting:
      Result := '';
    else
      Result := results.GetQualUnits(aTheme - FirstLinkQualTheme);
  end;
end;

function GetStatusStr(Status: Integer): String;
begin
  if Status in [0..2] then Result := 'Closed'
  else if Status = 4 then Result := 'Active'
  else Result := 'Open';
end;

end.
