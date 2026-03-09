{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       fireflowselector.pas
 Description:  a frame that selects options for a fire flow analysis
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit fireflowselector;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Dialogs,
  ComCtrls, SpinEx, mapcoords;

type
  TIntegerArray = array of Integer;

  TSelectionType = (   // Indicates how fire flow nodes will be selected
    stIndividual = 1,  // one by one
    stByTag,           // by Tag property
    stByRegion,        // by user-defined region
    stAll);            // all nodes selected

  { TFireFlowSelectorFrame }

  TFireFlowSelectorFrame = class(TFrame)
    Notebook1:          TNotebook;
    DesignPage:         TPage;
    SelectionTypePage:  TPage;
    FireNodesPage:      TPage;
    PressureZonePage:   TPage;
    SummaryPage:        TPage;
    BackBtn:            TButton;
    NextBtn:            TButton;
    RemoveBtn:          TButton;
    ClearBtn:           TButton;
    ComputeBtn:         TButton;
    HelpBtn:            TSpeedButton;
    CloseBtn:           TSpeedButton;
    TagEdit:            TEdit;
    FlowEdit:           TEdit;
    PressureEdit:       TEdit;
    Label1:             TLabel;
    Label10:            TLabel;
    Label11:            TLabel;
    Label12:            TLabel;
    Label13:            TLabel;
    Label14:            TLabel;
    Label15:            TLabel;
    Label16:            TLabel;
    Label17:            TLabel;
    Label21:            TLabel;
    Label2:             TLabel;
    Label3:             TLabel;
    Label4:             TLabel;
    Label5:             TLabel;
    Label6:             TLabel;
    Label7:             TLabel;
    Label8:             TLabel;
    Label9:             TLabel;
    FlowUnitsLabel:     TLabel;
    PressureUnitsLabel: TLabel;
    PressureZoneBtn1:   TRadioButton;
    PressureZoneBtn2:   TRadioButton;
    PressureZoneBtn3:   TRadioButton;
    IndividualBtn:      TRadioButton;
    TagBtn:             TRadioButton;
    RegionBtn:          TRadioButton;
    AllBtn:             TRadioButton;
    TimeOfDayCombo:     TComboBox;
    ListBox1:           TListBox;
    TopPanel:           TPanel;
    NavigationPanel:    TPanel;

    procedure ClearBtnClick(Sender: TObject);
    procedure ComputeBtnClick(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure BackBtnClick(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);

  private
    AllNodesForFireFlow: Boolean;
    PressureZoneType:    Integer;

    procedure InitFireFlowTargets;
    procedure FillTimeOfDayCombo;
    procedure SetActionButtons;
    procedure ShowSelections;
    procedure AcceptSelections;
    function  GetPressureZoneChoice: string;
    function  GetSelections: Boolean;
    procedure DoSelectionType;
    function  DoSelectByTag: Boolean;
    procedure DoSelectByRegion;
    procedure GetSelectedFireNodes(var FireNodes: TIntegerArray);

  public
    procedure Init;
    procedure ShowFirstPage;
    procedure SelectNode(Item: Integer);
    procedure GroupSelect(Poly: TPolygon; const Npts: Integer);

  end;

implementation

{$R *.lfm}

uses
  main, project, config, reportviewer, fireflowrpt, utils, epanet2,
  resourcestrings;

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
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  ListBox1.Clear;
  BackBtn.Enabled := false;
  NextBtn.Enabled := true;
  AllNodesForFireFlow := false;
  Notebook1.PageIndex := 0;
  InitFireFlowTargets;
  FillTimeOfDayCombo;
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

procedure TFireFlowSelectorFrame.ShowFirstPage;
begin
  Notebook1.PageIndex := 0;
  BackBtn.Enabled := false;
  NextBtn.Enabled := true;
  if RegionBtn.Checked then IndividualBtn.Checked := true;
end;

procedure TFireFlowSelectorFrame.SelectNode(Item: Integer);
var
  ItemIndex: Integer;
  NodeName: string;
begin
  if Notebook1.ActivePage <> 'FireNodesPage' then exit;
  if project.GetNodeType(Item+1) <> ntJunction then
  begin
    utils.MsgDlg(rsInvalidSelect, rsNotJunction, mtInformation, [mbOK], MainForm);
    exit;
  end;
  NodeName := project.GetItemID(ctNodes, Item);
  if Length(NodeName) = 0 then exit;

  ItemIndex := ListBox1.Items.IndexOf(NodeName);
  if ItemIndex >= 0 then
    ListBox1.ItemIndex := ItemIndex
  else
  begin
    ListBox1.Items.Add(NodeName);
    ListBox1.ItemIndex := ListBox1.Count - 1;
    SetActionButtons;
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
  ENgettimeparam(EN_STARTTIME, StartTime); //Clock time at start of reporting
  ENgettimeparam(EN_REPORTSTART, Seconds); //Time until reporting starts

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

procedure TFireFlowSelectorFrame.AcceptSelections;
begin
  if GetSelections = false then exit;
  Visible := false;
  if ReportViewerForm.WindowState = wsMinimized then
    ReportViewerForm.WindowState := wsNormal;
  with ReportViewerForm.Report as TFireFlowFrame do
    RefreshReport;
end;

procedure TFireFlowSelectorFrame.CloseBtnClick(Sender: TObject);
begin
  Hide;
  if Assigned(ReportViewerForm.Report) then
  with ReportViewerForm.Report as TFireFlowFrame do
  begin
    if IsEmpty then
    begin
      ReportViewerForm.CloseReport;
      ReportViewerForm.Hide;                            
    end
    else
    begin
      ReportViewerForm.WindowState := wsNormal;
      ReportViewerForm.Show;
    end;
  end;
end;

procedure TFireFlowSelectorFrame.DoSelectionType;
begin
  if AllNodesForFireFlow then
  begin
    AllNodesForFireFlow := false;
    ListBox1.Clear;
  end;
  if TagBtn.Checked then
  begin
    if DoSelectByTag then
      Notebook1.PageIndex := Notebook1.PageIndex + 1;
  end
  else if RegionBtn.Checked then
  begin
    DoSelectByRegion;
  end
  else if AllBtn.Checked then
  begin
    AllNodesForFireFlow := true;
    Notebook1.PageIndex := Notebook1.IndexOf(PressureZonePage)
  end
  else
    Notebook1.PageIndex := Notebook1.PageIndex + 1;
end;

procedure TFireFlowSelectorFrame.DoSelectByRegion;
begin
  Hide;
  with MainForm do
  begin
    HintTitleLabel.Caption:= rsFireFlowSelect;
    HintTextLabel.Caption := rsToGroupSelect;
    HintPanel.Visible := True;
    MapFrame.EnterFenceLiningMode('FireFlowSelection');
  end;
end;

function TFireFlowSelectorFrame.DoSelectByTag: Boolean;
var
  T1: string = '';
  T2: string;
  I: Integer;
  N: Integer;
begin
  Result := false;
  T1 := TagEdit.Text;
  N := 0;
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeType(I) <> ntJunction then continue;
    T2 := project.GetTag(0, I);
    if SameText(T1, T2) then
    begin
      if N = 0 then
        ListBox1.Clear;
      ListBox1.Items.Add(project.GetID(ctNodes, I));
      Inc(N);
    end;
  end;
  if N = 0 then
  begin
    utils.MsgDlg(rsMissingData, rsNoTagNodes + T1, mtInformation, [mbOK], MainForm);
    exit;
  end;
  Result := true;
end;

procedure TFireFlowSelectorFrame.BackBtnClick(Sender: TObject);
begin
  if Notebook1.ActivePage = 'PressureZonePage' then
  begin
    if AllNodesForFireFlow then
      Notebook1.PageIndex := Notebook1.PageIndex - 2
    else
      Notebook1.PageIndex := Notebook1.PageIndex - 1;
  end
  else
    Notebook1.PageIndex := Notebook1.PageIndex - 1;
  BackBtn.Enabled := Notebook1.PageIndex > 0;
  NextBtn.Enabled := true;
end;

procedure TFireFlowSelectorFrame.RemoveBtnClick(Sender: TObject);
var
  I: Integer;
begin
  I := ListBox1.ItemIndex;
  ListBox1.Items.Delete(I);
  if ListBox1.Items.Count > 0 then
  begin
    if I > 0 then I := I - 1;
    ListBox1.ItemIndex := I;
  end;
  SetActionButtons;
end;

procedure TFireFlowSelectorFrame.NextBtnClick(Sender: TObject);
begin
  BackBtn.Enabled := true;
  NextBtn.Enabled := true;

  if Notebook1.ActivePage = 'DesignPage' then
  begin
    if (Length(FlowEdit.Text) = 0)
    or (Length(PressureEdit.Text) = 0) then
    begin
      utils.MsgDlg(rsInvalidData, rsBlankEntries, mtError, [mbOK], MainForm);
      BackBtn.Enabled := false;
    end
    else
      Notebook1.PageIndex := Notebook1.PageIndex + 1;
  end

  else if Notebook1.ActivePage = 'SelectionTypePage' then
    DoSelectionType

  else
  begin
    Notebook1.PageIndex := Notebook1.PageIndex + 1;
    if Notebook1.ActivePage = 'SummaryPage' then
    begin
      NextBtn.Enabled := false;
      ShowSelections;
    end;
  end;
end;

procedure TFireFlowSelectorFrame.ClearBtnClick(Sender: TObject);
begin
  ListBox1.Clear;
  SetActionButtons;
end;

procedure TFireFlowSelectorFrame.ComputeBtnClick(Sender: TObject);
begin
  AcceptSelections;
end;

procedure TFireFlowSelectorFrame.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#fire_flow_analysis');
end;

procedure TFireFlowSelectorFrame.SetActionButtons;
var
  N: Integer;
begin
  if Notebook1.ActivePage = 'FireNodesPage' then
  begin
    N := ListBox1.Count;
    ClearBtn.Enabled := N > 0;
    RemoveBtn.Enabled := N > 0;
  end;
end;

procedure TFireFlowSelectorFrame.GroupSelect(Poly: TPolygon; const Npts: Integer);
var
  I:           Integer;
  Pt:          TDoublePoint = (X: 0; Y: 0);
  GroupBounds: TDoubleRect = (LowerLeft: (X: 0; Y: 0); UpperRight: (X: 0; Y: 0));
begin
  MainForm.HintPanel.Hide;
  Show;

  // Npts = -1 indicates that all network nodes were selected
  if Npts = -1 then
  begin
    AllNodesForFireFlow := true;
    Notebook1.PageIndex := Notebook1.IndexOf(PressureZonePage);
    exit;
  end;

  // Polygon must have at least 3 vertices
  if (Npts >= 0) and (Npts < 3) then
  begin
    utils.MsgDlg(rsInvalidSelect, rsBadPolygon, mtError, [mbOk], MainForm);
    exit;
  end;

  // Find polygon's bounding rectangle
  if Npts > 0 then
    GroupBounds := utils.PolygonBounds(Poly, Npts);

  // Add nodes in polygon to page's listbox
  ListBox1.Clear;
  ListBox1.Items.BeginUpdate;
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeType(I) <> ntJunction then continue;
    if not project.GetNodeCoord(I, Pt.X, Pt.Y) then continue;
    if utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then
      ListBox1.Items.Add(project.GetID(ctNodes, I));
  end;
  ListBox1.Items.EndUpdate;
  Notebook1.PageIndex := Notebook1.IndexOf(FireNodesPage);
end;

procedure TFireFlowSelectorFrame.ShowSelections;
//
// Displays Fire Flow Analysis selections on SummaryPage of Selector frame
//
var
  S: string;
begin
  S := Trim(FlowEdit.Text);
  if Length(S) > 0 then
    S := S + ' ' + FlowUnitsLabel.Caption;
  Label13.Caption := S;
  S := Trim(PressureEdit.Text);
  if Length(S) > 0 then
    S := S + ' ' + PressureUnitsLabel.Caption;
  Label14.Caption := S;
  Label15.Caption := TimeOfDayCombo.Text;
  if AllNodesForFireFlow then
    S := rsAllNodes
  else
    S := IntToStr(ListBox1.Items.Count);
  Label16.Caption := S;
  Label17.Caption := GetPressureZoneChoice;
end;

function TFireFlowSelectorFrame.GetSelections: Boolean;
var
  TargetFlow:     Single;
  TargetPressure: Single;
  FireTime:       Integer;
  RptStart:       TimeType = 0;
  FireNodes:      TIntegerArray;
begin
  Result := false;
  SetLength(FireNodes, 0);
  TargetFlow := StrToFloat(FlowEdit.Text);
  TargetPressure := StrToFloat(PressureEdit.Text);
  ENgettimeparam(EN_REPORTSTART, RptStart);
  FireTime := RptStart + TimeOfDayCombo.ItemIndex * 3600;
  GetSelectedFireNodes(FireNodes);

  if Length(FireNodes) = 0 then
  begin
    MsgDlg(rsMissingData, rsNoNodesSelected, mtError, [mbOk], MainForm);
    Notebook1.PageIndex := Notebook1.IndexOf(SelectionTypePage);
    exit;
  end;

  with ReportViewerForm.Report as TFireFlowFrame do
    SetFireFlowSelection(TargetFlow, TargetPressure, FireTime, FireNodes,
      PressureZoneType);

  SetLength(FireNodes, 0);
  Result := true;
end;

function  TFireFlowSelectorFrame.GetPressureZoneChoice: string;
var
  I: Integer;
begin
  Result := '';
  for I := 1 to 3 do
  begin
    with FindComponent('PressureZoneBtn' + IntToStr(I)) as TRadioButton do
    begin
      if Checked then
      begin
        PressureZoneType := I;
        Result := Caption;
        break;
      end;
    end;
  end;
end;

procedure TFireFlowSelectorFrame.GetSelectedFireNodes(
  var FireNodes: TIntegerArray);
var
  I: Integer;
  M: Integer;
  N: Integer;
begin
  if AllNodesForFireFlow then
  begin
    N := project.GetItemCount(ctNodes);
    SetLength(FireNodes, N);
    M := 0;
    for I := 1 to N do
    begin
      if project.GetNodeType(I) = ntJunction then
      begin
        FireNodes[M] := I;
        Inc(M);
      end;
    end;
    if M < N then SetLength(FireNodes, M);
  end
  else
  begin
    N := ListBox1.Items.Count;
    SetLength(FireNodes, N);
    for I := 0 to N - 1 do
      FireNodes[I] := project.GetItemIndex(ctNodes, ListBox1.Items[I]);
  end;
end;

end.

