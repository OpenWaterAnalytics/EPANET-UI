{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       groupeditor
 Description:  a frame that edits properties for a group of objects
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

{
 This frame is used to:
  a) select a group of nodes or links
  b) change a property value for the selected Junction nodes or Pipe
     links that pass an optional filter condition.

  It is invoked from the application's MainMenuFrame when the
  Edit > Group Edit menu item is selected, by calling the Init
  procedure.

  It is also used to implement the Edit > Group Delete menu option after
  the user has drawn a polygon area on the network map. The
  LeaveFenceLiningMode procedure of the main form's MapFrame calls this
  unit's DeleteGroup procedure to delete the objects within the polygon.
}

unit groupeditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Dialogs,
  Graphics, mapcoords;

type

  TFilterAction = record
    Parameter:   Integer;
    Relation:    Integer;
    Value:       Single;
    Tag:         string;
  end;

  TEditAction = record
    Action:      Integer;
    Parameter:   Integer;
    Value:       Single;
    Tag:         string;
  end;

  { TGroupEditorFrame }

  TGroupEditorFrame = class(TFrame)
    TopPanel:            TPanel;
    ButtonPanel:         TPanel;
    FilterGroupBox:      TGroupBox;
    EditGroupBox:        TGroupBox;
    FilterCheckBox:      TCheckBox;
    ParamCombo:          TComboBox;
    ActionCombo:         TComboBox;
    FilterParamCombo:    TComboBox;
    FilterRelationCombo: TComboBox;
    WithLabel:           TLabel;
    FilterValueEdit:     TEdit;
    ValueEdit:           TEdit;
    CloseBtn:            TSpeedButton;
    CloseFrameBtn:       TButton;
    BackBtn:             TButton;
    MakeChangesBtn:      TButton;

    procedure ActionComboChange(Sender: TObject);
    procedure BackBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure FilterCheckBoxChange(Sender: TObject);
    procedure FilterParamComboChange(Sender: TObject);
    procedure MakeChangesBtnClick(Sender: TObject);
    procedure CloseFrameBtnClick(Sender: TObject);
    procedure ParamComboChange(Sender: TObject);

  private
    ObjectType:    Integer;
    FilterAction:  TFilterAction;
    EditAction:    TEditAction;

    procedure SetParamChoices(aComboBox: TComboBox; Choices: string);
    function  GetFilterAction: Boolean;
    function  GetEditAction: Boolean;
    function  ObjectValueChanged(I: Integer): Boolean;
    function  PassesTextFilter(I: Integer): Boolean;
    function  PassesNumericalFilter(I: Integer): Boolean;
    function  GetNewValue(Index: Integer): Single;
    procedure MakeChanges;
    procedure CloseFrame;
    procedure GroupSelectorReturned(Sender: TObject);

  public
    procedure Init(ObjType: Integer);
    procedure DeleteGroup(GroupPoly: TPolygon; NumPolyPts: Integer);

  end;

implementation

{$R *.lfm}

uses
  main, project, config, groupselector, reportframe, utils, resourcestrings,
  epanet2;

const
  EN_TAG = -999;

  // EN_xxx are EPANET constants defined in the epanet2.pas file
  JuncParamCode: array[0 .. 5] of Integer =
    ( EN_TAG, EN_ELEVATION, EN_BASEDEMAND, EN_PATTERN, EN_EMITTER, EN_INITQUAL);
  JuncParamsTxt: string = rsJuncParams;

  PipeParamCode: array[0..8] of Integer =
    ( EN_TAG, EN_DIAMETER, EN_LENGTH, EN_ROUGHNESS, EN_MINORLOSS,
      EN_KBULK, EN_KWALL, EN_LEAK_AREA, EN_LEAK_EXPAN);
  PipeParamsTxt: string = rsPipeParams;

  EQUAL = 0;
  BELOW = 1;
  ABOVE = 2;
  FilterRelationsTxt: string = rsFilters;

  REPLACE = 0;
  MULTIPLY = 1;
  ADD = 2;
  EditActionsTxt: string = rsActions;

procedure TGroupEditorFrame.BackBtnClick(Sender: TObject);
//
//  Re-displays the GroupSelectorFrame to allow selection of a different
//  group of objects to edit.
//
begin
  Hide;
  MainForm.GroupSelectorFrame.Show;
end;

procedure TGroupEditorFrame.CloseFrameBtnClick(Sender: TObject);
//
//  Closes this frame.
//
begin
  CloseFrame;
end;

procedure TGroupEditorFrame.GroupSelectorReturned(Sender: TObject);
//
//  Callback procedure invoked when the GroupSelectorFrame has finished
//  selecting the objects to be edited.
//
var
  ReturnCode: Integer;
begin
  ReturnCode := MainForm.GroupSelectorFrame.GetReturnCode;
  if (ReturnCode = 1)
  and (MainForm.GroupSelectorFrame.GetSelectedCount > 0) then
    Show
  else
    CloseFrame
end;

procedure TGroupEditorFrame.ActionComboChange(Sender: TObject);
//
// Changes the preposition used to construct an editng action.
//
begin
  if ActionCombo.ItemIndex = REPLACE then
    WithLabel.Caption := rsWith
  else
    WithLabel.Caption := rsBy;
end;

procedure TGroupEditorFrame.CloseBtnClick(Sender: TObject);
//
//  Closes the frame when the "X" button on the top panel is clicked.
//
begin
  CloseFrame;
end;

procedure TGroupEditorFrame.FilterCheckBoxChange(Sender: TObject);
//
// Changes the enabled state of the controls used to specify a filter
// condition when the FilterCheckBox is clicked.
//
var
  WithEnabled: Boolean;
begin
  WithEnabled := FilterCheckBox.Checked;
  FilterParamCombo.Enabled := WithEnabled;
  FilterRelationCombo.Enabled := WithEnabled;
  FilterValueEdit.Enabled := WithEnabled;
  FilterParamComboChange(self);
end;

procedure TGroupEditorFrame.FilterParamComboChange(Sender: TObject);
//
//  Forces a filter relation on an object's Tag or Demand Pattern
//  to be "Equal To".
//
begin
  if SameText(FilterParamCombo.Text, 'Tag')
  or SameText(FilterParamCombo.Text, 'Demand Pattern') then
  begin
    FilterRelationCombo.ItemIndex := EQUAL;
    FilterRelationCombo.Enabled := false;
  end
  else
    FilterRelationCombo.Enabled := true;
end;


procedure TGroupEditorFrame.MakeChangesBtnClick(Sender: TObject);
//
// Executes the specified filter action and editing action when the
// MakeChangesBtn is clicked.
//
begin
  if GetFilterAction and GetEditAction then MakeChanges
end;


procedure TGroupEditorFrame.ParamComboChange(Sender: TObject);
//
//  Forces the action for a Tag or Demand Pattern property
//  to be "Equal To".
//
begin
  if SameText(ParamCombo.Text, 'Tag')
  or SameText(ParamCombo.Text, 'Demand Pattern') then
  begin
    ActionCombo.ItemIndex := REPLACE;
    ActionCombo.Enabled := false;
    WithLabel.Caption := rsWith;
  end
  else
    ActionCombo.Enabled := true;
end;

procedure TGroupEditorFrame.SetParamChoices(aComboBox: TComboBox; Choices: string);
//
// Loads either node or link properties into the parameter combo boxes of
// of the FilterGroupBox and the EditGroupBox.
//
begin
  with aComboBox do
  begin
    Clear;
    Items.Text := Choices;
    ItemIndex := 0;
  end;
end;

function TGroupEditorFrame.GetFilterAction: Boolean;
//
// Populates the fields of the FilterAction record from the contents of
// the controls in the FilterGroupBox.
//
begin
  Result := false;
  FilterAction.Parameter := -1;
  if FilterCheckBox.Checked then
  begin
    FilterAction.Parameter := FilterParamCombo.ItemIndex;
    if ObjectType = ctNodes then
      FilterAction.Parameter := JuncParamCode[FilterAction.Parameter]
    else
      FilterAction.Parameter := PipeParamCode[FilterAction.Parameter];

    if FilterAction.Parameter = EN_TAG then
      FilterAction.Tag := FilterValueEdit.Text
    else if (ObjectType = ctNodes) and (FilterAction.Parameter = EN_PATTERN) then
    begin
      FilterAction.Value := project.GetItemIndex(ctPatterns, FilterValueEdit.Text);
      if FilterAction.Value = 0 then
      begin
        utils.MsgDlg(rsInvalidData, rsBadPattern, mtError, [mbOk]);
        FilterValueEdit.SetFocus;
        exit;
      end;
    end
    else
    begin
      FilterAction.Relation := FilterRelationCombo.ItemIndex;
      if not utils.Str2Float(FilterValueEdit.Text, FilterAction.Value) then
      begin
        utils.MsgDlg(rsInvalidData, rsBadNumber, mtError, [mbOk]);
        FilterValueEdit.SetFocus;
        exit;
      end;
    end;
  end;
  Result := true;
end;

function TGroupEditorFrame.GetEditAction: Boolean;
//
// Populates the fields of the EditAction record with the contents of
// the controls within the EditGroupBox.
//
begin
  Result := false;
  EditAction.Action := ActionCombo.ItemIndex;
  EditAction.Parameter := ParamCombo.ItemIndex;
  if ObjectType = ctNodes then
    EditAction.Parameter := JuncParamCode[EditAction.Parameter]
  else
    EditAction.Parameter := PipeParamCode[EditAction.Parameter];
  if (ObjectType = ctNodes)
  and (EditAction.Parameter = EN_PATTERN) then
  begin
    EditAction.Value := project.GetItemIndex(ctPatterns, ValueEdit.Text);
    if EditAction.Value = 0 then
    begin
      utils.MsgDlg(rsInvalidData, rsBadPattern, mtError, [mbOk]);
      ValueEdit.SetFocus;
      exit;
    end;
  end
  else if EditAction.Parameter = EN_TAG then
  begin
    EditAction.Tag := ValueEdit.Text;
    if (Pos(' ', EditAction.Tag) > 0)
    or (Pos(';', EditAction.Tag) > 0) then
    begin
      utils.MsgDlg(rsInvalidData, rsBadTag, mtError, [mbOk]);
      ValueEdit.SetFocus;
      exit;
    end;
  end
  else if not utils.Str2Float(ValueEdit.Text, EditAction.Value) then
  begin
    utils.MsgDlg(rsInvalidData, rsBadNumber, mtError, [mbOk]);
    ValueEdit.SetFocus;
    exit;
  end;
  Result := true;
end;

procedure TGroupEditorFrame.MakeChanges;
//
// Applies the FilterAction and EditAction to all selected nodes or links.
//
var
  I: Integer;
  N: Integer = 0;
  Count: Integer = 0;
  Msg: string;
  Msg1: string = rsNoMatches;
  Msg2: string = rsObjsModified;
  Msg3: string = rsMoreEdits;
begin
  if ObjectType = ctNodes then
    epanet2.ENgetcount(EN_NODECOUNT, N)
  else
    epanet2.ENgetcount(EN_LINKCOUNT, N);

  for I := 1 to N do
  begin
    if MainForm.GroupSelectorFrame.IsSelected(I) then
    begin
      if ObjectValueChanged(I) then Inc(Count);
    end;
  end;

  if Count = 0 then
    Msg := Msg1
  else
  begin
    MainForm.ProjectFrame.RefreshPropEditor;
    Msg := IntToStr(Count) + ' ' + Msg2;
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end;
  Msg := Msg + LineEnding + LineEnding + Msg3;
  if utils.MsgDlg(rsPleaseConfirm, Msg, mtConfirmation, [mbYes, mbNo]) = mrNo then
    CloseFrame;
end;

function TGroupEditorFrame.ObjectValueChanged(I: Integer): Boolean;
//
// Applies the EditAction to a specific node or link if it passes
// the FilterAction.
//
var
  NodeType: Integer = 0;
  LinkType: Integer = 0;
  X: Single;
begin
  Result := false;
  if ObjectType = ctNodes then
  begin
    epanet2.ENgetnodetype(I, NodeType);
    if NodeType <> EN_JUNCTION then exit;
  end
  else
  begin
    epanet2.ENgetlinktype(I, LinkType);
    if LinkType <> EN_PIPE then exit;
  end;

  if (FilterAction.Parameter = EN_TAG)
  and (not PassesTextFilter(I)) then exit
  else if (FilterAction.Parameter >= 0)
  and (not PassesNumericalFilter(I)) then exit;

  if EditAction.Parameter = EN_TAG then
  begin
    if ObjectType = ctNodes then
      epanet2.ENsettag(EN_NODE, I, PChar(EditAction.Tag))
    else
      epanet2.ENsettag(EN_LINK, I, PChar(EditAction.Tag));
  end
  else
  begin
    X := GetNewValue(I);
    if ObjectType = ctNodes then
      epanet2.ENsetnodevalue(I, EditAction.Parameter, X)
    else if ObjectType = ctLinks then
      epanet2.ENsetlinkvalue(I, EditAction.Parameter, X);
  end;
  Result := true;
end;

function TGroupEditorFrame.PassesTextFilter(I: Integer): Boolean;
//
// Checks if a FilterAction on a node or link Tag is satisfied.
//
var
  S: string;
begin
  S := project.GetTag(ObjectType, I);
  Result := (AnsiCompareStr(S, FilterAction.Tag) = 0);
end;

function TGroupEditorFrame.PassesNumericalFilter(I: Integer): Boolean;
//
// Checks if a FilterAction on a node or link numerical parameter is satisfied.
//
var
  X: Single;
begin
  if ObjectType = ctNodes then
    epanet2.ENgetnodevalue(I, FilterAction.Parameter, X)
  else
    epanet2.ENgetlinkvalue(I, FilterAction.Parameter, X);
  case FilterAction.Relation of
    BELOW:
      Result := (X <= FilterAction.Value);
    EQUAL:
      Result := (Abs(X - FilterAction.Value) < 0.0001);
    ABOVE:
      Result := (X >= FilterAction.Value);
    else
      Result := false;
  end;
end;

function TGroupEditorFrame.GetNewValue(Index: Integer): Single;
//
// Applies the EditAction's Action and Value to a node or link parameter
// to give it a new value.
//
var
  X: Single;
begin
  if EditAction.Action = REPLACE then
    Result := EditAction.Value
  else
  begin
    if ObjectType = ctNodes then
      epanet2.ENgetnodevalue(Index, EditAction.Parameter, X)
    else
      epanet2.ENgetlinkvalue(Index, EditAction.Parameter, X);
    if EditAction.Action = MULTIPLY then
      Result := X * EditAction.Value
    else if EditAction.Action = ADD then
      Result := X + EditAction.Value
    else
      Result := EditAction.Value;
  end;
end;

procedure TGroupEditorFrame.Init(ObjType: Integer);
//
// Initializes the GroupEditorFrame and displays the GroupSelectorFrame
// for the object type (nodes or links) passed in, setting the latter's
// callback procedure to GroupSelectorReturned.
//
begin
  Color := clCream;
  config.SetHeaderColor(TopPanel);
  ObjectType := ObjType;
  if not ObjectType in [ctNodes, ctLinks] then exit;

  FilterRelationCombo.Items.Text := FilterRelationsTxt;
  FilterRelationCombo.ItemIndex := EQUAL;
  FilterValueEdit.Text := '';
  ActionCombo.Items.Text := EditActionsTxt;
  ActionCombo.ItemIndex := REPLACE;
  ValueEdit.Text := '';

  if ObjectType = ctNodes then
  begin
    SetParamChoices(FilterParamCombo, JuncParamsTxt);
    SetParamChoices(ParamCombo, JuncParamsTxt);
  end
  else
  begin
    SetParamChoices(FilterParamCombo, PipeParamsTxt);
    SetParamChoices(ParamCombo, PipeParamsTxt);
  end;
  FilterParamComboChange(self);
  ParamComboChange(self);

  // Disable the main form while the GroupEditorFrame is active
  MainForm.EnableMainForm(false);

  // Assign the GroupSelectorFrame an OnReturn callback procedure
  // and display it.
  MainForm.GroupSelectorFrame.OnReturn := @GroupSelectorReturned;
  MainForm.GroupSelectorFrame.Open(ObjectType, self);
  MainForm.GroupSelectorFrame.Show;
end;

procedure TGroupEditorFrame.CloseFrame;
//
// Close the frame and make the main form enabled again.
//
begin
  Hide;
  MainForm.GroupSelectorFrame.Close;
  MainForm.EnableMainForm(true);
  MainForm.MainMenuFrame.GroupEditBtn.Down := false;
  MainForm.MapFrame.RedrawMap;
end;

procedure TGroupEditorFrame.DeleteGroup(GroupPoly: TPolygon; NumPolyPts: Integer);
//
// This procedure is called after a polygon area is drawn on the network map
// and proceeds to delete all objects that lie within the area.
//
var
  GroupBounds: TDoubleRect;
  Pt:          TDoublePoint;
  I, N:        Integer;
  HasChanged:  Boolean = false;
begin
  MainForm.HideHintPanel;
  MainForm.EnableMainForm(true);
  MainForm.MainMenuFrame.GroupDeleteBtn.Down := false;

  if (NumPolyPts = -1) or (NumPolyPts >= 3) then
  begin
    GroupBounds := utils.PolygonBounds(GroupPoly, NumPolyPts);
    if utils.MsgDlg(rsPleaseConfirm, rsDeleteAll, mtConfirmation,
      [mbYes, mbNo]) = mrNo then exit;

    // Delete nodes (which will also delete connecting links)
    N := project.GetItemCount(ctNodes);
    for I := N downto 1 do
    begin
      if (NumPolyPts > 0) then
      begin
        if not project.GetNodeCoord(I, Pt.X, Pt.Y) then continue;
        if not utils.PointInPolygon(Pt, GroupBounds, NumPolyPts, GroupPoly) then
          continue;
      end;
      project.DeleteItem(ctNodes, I);
      HasChanged := true;
    end;

    // Delete labels
    N := project.GetItemCount(ctLabels);
    for I := N downto 1 do
    begin
      if (NumPolyPts > 0) then
      begin
        if not project.GetLabelCoord(I, Pt.X, Pt.Y) then continue;
        if not utils.PointInPolygon(Pt, GroupBounds, NumPolyPts, GroupPoly) then
          continue;
      end;
      project.DeleteItem(ctLabels, I);
      HasChanged := true;
    end;

    // Adjust the network map's extent
    if HasChanged then
    begin
      MainForm.MapFrame.Map.Extent := MainForm.MapFrame.Map.GetBounds;
      MainForm.MapFrame.RedrawMap;
      MainForm.OverviewMapFrame.Redraw;
      MainForm.ReportFrame.RefreshReport;
    end;
  end;
end;

end.

