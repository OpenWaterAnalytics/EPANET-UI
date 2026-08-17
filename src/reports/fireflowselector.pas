{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       fireflowselector.pas
 Description:  a frame that selects options for a fire flow analysis
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit fireflowselector;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Dialogs,
  ComCtrls, SpinEx;

type
  TIntegerArray = array of Integer;

  { TFireFlowSelectorFrame }

  TFireFlowSelectorFrame = class(TFrame)
    HelpBtn: TButton;
    TopPanel:           TPanel;
    SelectNodesBtn:     TButton;
    ComputeBtn:         TButton;
    CloseBtn:           TSpeedButton;
    TimeOfDayCombo:     TComboBox;
    PressureZoneGroup:  TRadioGroup;
    FlowEdit:           TEdit;
    PressureEdit:       TEdit;
    FlowUnitsLabel:     TLabel;
    PressureUnitsLabel: TLabel;
    SelectedLabel:      TLabel;
    Label1:             TLabel;
    Label2:             TLabel;
    Label3:             TLabel;

    procedure ComputeBtnClick(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure SelectNodesBtnClick(Sender: TObject);

  private
    procedure InitFireFlowTargets;
    procedure FillTimeOfDayCombo;
    function  GetSelections: Boolean;
    procedure GetSelectedFireNodes(var FireNodes: TIntegerArray);
    procedure GroupSelectorReturned(Sender: TObject);

  public
    procedure Init;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, groupselector, reportframe, fireflowrpt, utils,
  epanet2, resourcestrings;

// Definition of TimeType (seconds) depending on OS
{$I ..\timetype.txt}

const
  DefaultFireFlowGpm = 500;
  DefaultFireFlowLpm = 2000;
  DefaultPressurePsi = 20;
  DefaultPressureKpa = 138;

{ TFireFlowSelectorFrame }

procedure TFireFlowSelectorFrame.Init;
begin
  config.SetHeaderColor(TopPanel);
  InitFireFlowTargets;
  FillTimeOfDayCombo;
  MainForm.GroupSelectorFrame.OnReturn := @GroupSelectorReturned;
  MainForm.GroupSelectorFrame.Open(ctNodes, self);
end;

procedure TFireFlowSelectorFrame.InitFireFlowTargets;
var
  V: Single;
begin
  if Length(FlowEdit.Text) = 0 then
  begin
    if project.GetUnitsSystem = usUs then
      FlowEdit.Text := DefaultFireFlowGpm.ToString
    else
      FlowEdit.Text := DefaultFireFlowLpm.ToString;
  end
  else
  begin
    V := StrToFloat(FlowEdit.Text);
    if (project.GetUnitsSystem = usUs)
    and (FlowUnitsLabel.Caption = rsLpm)
    then
      V := V / 3.785
    else if (project.GetUnitsSystem = usSI)
    and (FlowUnitsLabel.Caption = rsGpm)
    then
      V := V * 3.785;
    FlowEdit.Text := Round(V).ToString;
  end;

  if Length(PressureEdit.Text) = 0 then
  begin
    if project.GetUnitsSystem = usUs then
      PressureEdit.Text := DefaultPressurePsi.ToString
    else
      PressureEdit.Text := DefaultPressureKpa.ToString;
  end
  else
  begin
    V := StrToFloat(PressureEdit.Text);
    if (project.GetUnitsSystem = usUs)
    and (PressureUnitsLabel.Caption = rsKpa)
    then
      V := V / 6.9
    else if (project.GetUnitsSystem = usSI)
    and (PressureUnitsLabel.Caption = rsPsi)
    then
      V := V * 6.9;
    PressureEdit.Text := Round(V).ToString;
  end;

  if project.GetUnitsSystem = usUs then
  begin
    FlowUnitsLabel.Caption := rsGpm;
    PressureUnitsLabel.Caption := rsPsi;
  end
  else
  begin
    FlowUnitsLabel.Caption := rsLpm;
    PressureUnitsLabel.Caption := rsKpa;
  end;

end;

procedure TFireFlowSelectorFrame.FillTimeOfDayCombo;
var
  Duration: TimeType = 0;
  StartTime: TimeType = 0;
  Hour: TimeType = 0;
  Seconds: TimeType = 0;
begin
  TimeOfDayCombo.Clear;
  ENgettimeparam(EN_DURATION, Duration);
  ENgettimeparam(EN_STARTTIME, StartTime); // Clock time at start of reporting
  ENgettimeparam(EN_REPORTSTART, Seconds); // Time until reporting starts

  Hour := (StartTime div 3600);
  TimeOfDayCombo.Items.Add(utils.TimeOfDayStr(Hour*3600));
  while (Seconds < Duration)
  and (TimeOfDayCombo.Items.Count < 24) do
  begin
    Hour := Hour + 1;
    if Hour = 24 then Hour := 0;
    TimeOfDayCombo.Items.Add(utils.TimeOfDayStr(Hour*3600));
    Seconds := Seconds + 3600;
  end;

  TimeOfDayCombo.ItemIndex := 0;
end;

procedure TFireFlowSelectorFrame.CloseBtnClick(Sender: TObject);
begin
  MainForm.ReportFrame.CloseBtnClick(Sender);
end;

procedure TFireFlowSelectorFrame.SelectNodesBtnClick(Sender: TObject);
begin
  Hide;
  MainForm.GroupSelectorFrame.Show;
  MainForm.ShowPage(MainForm.MapPage);
end;

procedure TFireFlowSelectorFrame.GroupSelectorReturned(Sender: TObject);
var
  ReturnCode: Integer;
  NodeCount:  Integer;
begin
  // GroupSelector returned with objects selected
  ReturnCode := MainForm.GroupSelectorFrame.GetReturnCode;
  NodeCount := MainForm.GroupSelectorFrame.GetSelectedCount;
  if (ReturnCode = 1) and (NodeCount > 0) then
  begin
    SelectedLabel.Caption:= IntToStr(NodeCount) + ' selected';
  end;
  MainForm.ShowPage(MainForm.ReportPage);
  MainForm.GroupSelectorFrame.Hide;
  Show;
end;

procedure TFireFlowSelectorFrame.ComputeBtnClick(Sender: TObject);
begin
  if GetSelections = false then exit;
  MainForm.ReportFrame.Show;
  with MainForm.ReportFrame.Report as TFireFlowFrame do
    RefreshReport;
end;

procedure TFireFlowSelectorFrame.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#fire_flow_analysis');
end;

function TFireFlowSelectorFrame.GetSelections: Boolean;
var
  TargetFlow:       Single;
  TargetPressure:   Single;
  FireTime:         Integer;
  RptStart:         TimeType = 0;
  PressureZoneType: Integer;
  FireNodes:        TIntegerArray;
begin
  Result := false;
  SetLength(FireNodes, 0);
  TargetFlow := StrToFloat(FlowEdit.Text);
  TargetPressure := StrToFloat(PressureEdit.Text);
  PressureZoneType := PressureZoneGroup.ItemIndex + 1;
  ENgettimeparam(EN_REPORTSTART, RptStart);
  FireTime := RptStart + TimeOfDayCombo.ItemIndex * 3600;
  GetSelectedFireNodes(FireNodes);

  if Length(FireNodes) = 0 then
  begin
    MsgDlg(rsMissingData, rsNoNodesSelected, mtError, [mbOk], MainForm);
    exit;
  end;

  with MainForm.ReportFrame.Report as TFireFlowFrame do
    SetFireFlowSelection(TargetFlow, TargetPressure, FireTime, FireNodes,
      PressureZoneType);

  SetLength(FireNodes, 0);
  Result := true;
end;

procedure TFireFlowSelectorFrame.GetSelectedFireNodes(
  var FireNodes: TIntegerArray);
var
  I: Integer;
  M: Integer;
  N: Integer;
begin
  // Size FireNodes to hold number of selected nodes
  N := MainForm.GroupSelectorFrame.GetSelectedCount;
  SetLength(FireNodes, N);

  // Loop through each node to add index of selected
  // junction nodes to the FireNodes array
  M := 0;
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if (MainForm.GroupSelectorFrame.IsSelected(I))
    and (project.GetNodeType(I) = ntJunction) then
    begin
      FireNodes[M] := I;
      Inc(M);
    end;
  end;

  // Resize FireNodes to number of selected junction nodes
  SetLength(FireNodes,M);
end;

end.

