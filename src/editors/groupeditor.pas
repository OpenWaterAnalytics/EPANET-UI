{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       groupeditor
 Description:  a dialog form that changes a property for a group of
               objects or deletes them
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit groupeditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, StdCtrls, lclIntf,
  ExtCtrls, Dialogs, mapcoords;

type

  { TGroupEditorForm }

  TGroupEditorForm = class(TForm)
    Panel1:              TPanel;
    Panel2:              TPanel;
    Label1:              TLabel;
    Label2:              TLabel;
    InRegionLabel:       TLabel;
    ParamCombo:          TComboBox;
    ActionCombo:         TComboBox;
    FilterCheckBox:      TCheckBox;
    FilterParamCombo:    TComboBox;
    FilterRelationCombo: TComboBox;
    FilterValueEdit:     TEdit;
    ValueEdit:           TEdit;
    JunctionsRadioBtn:   TRadioButton;
    PipesRadioBtn:       TRadioButton;
    OkBtn:               TButton;
    CancelBtn:           TButton;

    procedure OkBtnClick(Sender: TObject);
    procedure FilterCheckBoxChange(Sender: TObject);
    procedure FilterParamComboChange(Sender: TObject);
    procedure ActionComboChange(Sender: TObject);
    procedure ParamComboChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure JunctionsRadioBtnChange(Sender: TObject);

  private
    ObjType:         Integer;
    FilterParam:     Integer;
    FilterRelation:  Integer;
    ChangeAction:    Integer;
    ChangeParam:     Integer;
    NumPolyPts:      Integer;
    FilterValue:     Single;
    FilterTag:       string;
    ChangeTag:       string;
    ChangeValue:     Single;
    GroupPoly:       TPolygon;
    GroupBounds:     TDoubleRect;

    procedure SetParamChoices(aComboBox: TComboBox; Choices: string);
    function  GoChangeValues: Boolean;
    function  ObjValueChanged(I: Integer): Boolean;
    function  PassesLocationFilter(I: Integer): Boolean;
    function  PassesTextFilter(I: Integer): Boolean;
    function  PassesNumericalFilter(I: Integer): Boolean;
    function  GetNewValue(Index: Integer): Single;

  public
    HasChanged: Boolean;
    procedure Init(Poly: TPolygon; NumPts: Integer);
    function  DeleteObjects: Boolean;

  end;

var
  GroupEditorForm: TGroupEditorForm;

implementation

{$R *.lfm}

uses
  main, project, config, utils, reportviewer, epanet2, resourcestrings;

{ TGroupEditorForm }

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

  BELOW = 0;
  EQUAL = 1;
  ABOVE = 2;
  FilterRelationsTxt: string = rsFilters;

  REPLACE = 0;
  MULTIPLY = 1;
  ADD = 2;
  ChangeActionsTxt: string = rsActions;

procedure TGroupEditorForm.FormCreate(Sender: TObject);
var
  Location: TPoint;
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
  FilterRelationCombo.Items.Text := FilterRelationsTxt;
  FilterRelationCombo.ItemIndex := EQUAL;
  ActionCombo.Items.Text := ChangeActionsTxt;
  ActionCombo.ItemIndex := REPLACE;
  JunctionsRadioBtnChange(Self);
  NumPolyPts := 0;
  HasChanged := false;

  Location := MainForm.LeftPanel.ClientOrigin;
  Left := Location.X;
  Top := Location.Y;
end;

procedure TGroupEditorForm.Init(Poly: TPolygon; NumPts: Integer);
begin
  GroupPoly := Poly;
  NumPolyPts := NumPts;
  GroupBounds := utils.PolygonBounds(Poly, NumPts);
  InRegionLabel.Visible := (NumPts > 0);
end;

procedure TGroupEditorForm.OkBtnClick(Sender: TObject);
begin
  if JunctionsRadioBtn.Checked then
    ObjType := ctNodes
  else
    ObjType := ctLinks;

  FilterParam := -1;
  if FilterCheckBox.Checked then
  begin
    FilterParam := FilterParamCombo.ItemIndex;
    if ObjType = ctNodes then
      FilterParam := JuncParamCode[FilterParam]
    else
      FilterParam := PipeParamCode[Filterparam];

    if FilterParam = EN_TAG then
      FilterTag := FilterValueEdit.Text
    else if (ObjType = ctNodes) and (FilterParam = EN_PATTERN) then
    begin
      FilterValue := project.GetItemIndex(ctPatterns, FilterValueEdit.Text);
      if FilterValue = 0 then
      begin
        utils.MsgDlg(rsInvalidData, rsBadPattern, mtError, [mbOk]);
        FilterValueEdit.SetFocus;
        exit;
      end;
    end
    else
    begin
      FilterRelation := FilterRelationCombo.ItemIndex;
      if not utils.Str2Float(FilterValueEdit.Text, FilterValue) then
      begin
        utils.MsgDlg(rsInvalidData, rsBadNumber, mtError, [mbOk]);
        FilterValueEdit.SetFocus;
        exit;
      end;
    end;
  end;

  ChangeAction := ActionCombo.ItemIndex;
  ChangeParam := ParamCombo.ItemIndex;
  if ObjType = ctNodes then
    ChangeParam := JuncParamCode[ChangeParam]
  else
    ChangeParam := PipeParamCode[ChangeParam];
  if (ObjType = ctNodes)
  and (ChangeParam = EN_PATTERN) then
  begin
    ChangeValue := project.GetItemIndex(ctPatterns, ValueEdit.Text);
    if ChangeValue = 0 then
    begin
      utils.MsgDlg(rsInvalidData, rsBadPattern, mtError, [mbOk]);
      ValueEdit.SetFocus;
      exit;
    end;
  end
  else if ChangeParam = EN_TAG then
  begin
    ChangeTag := ValueEdit.Text;
    if (Pos(' ', ChangeTag) > 0)
    or (Pos(';', ChangeTag) > 0) then
    begin
      utils.MsgDlg(rsInvalidData, rsBadTag, mtError, [mbOk]);
      ValueEdit.SetFocus;
      exit;
    end;
  end
  else if not utils.Str2Float(ValueEdit.Text, ChangeValue) then
  begin
    utils.MsgDlg(rsInvalidData, rsBadNumber, mtError, [mbOk]);
    ValueEdit.SetFocus;
    exit;
  end;
  if not GoChangeValues then ModalResult := mrOK;
end;

procedure TGroupEditorForm.FilterCheckBoxChange(Sender: TObject);
var
  WithEnabled: Boolean;
begin
  WithEnabled := FilterCheckBox.Checked;
  FilterParamCombo.Enabled := WithEnabled;
  FilterRelationCombo.Enabled := WithEnabled;
  FilterValueEdit.Enabled := WithEnabled;
  FilterParamComboChange(self);
end;

procedure TGroupEditorForm.FilterParamComboChange(Sender: TObject);
begin
  if SameText(FilterParamCombo.Text, 'Tag')
  or SameText(FilterParamCombo.Text, 'Demand Pattern') then
  begin
    FilterRelationCombo.ItemIndex := 1;
    FilterRelationCombo.Enabled := false;
  end
  else
    FilterRelationCombo.Enabled := true;
end;

procedure TGroupEditorForm.ActionComboChange(Sender: TObject);
begin
  if ActionCombo.ItemIndex = 0 then
    Label2.Caption := rsWith
  else
    Label2.Caption := rsBy;
end;

procedure TGroupEditorForm.ParamComboChange(Sender: TObject);
begin
  if SameText(ParamCombo.Text, 'Tag')
  or SameText(ParamCombo.Text, 'Demand Pattern') then
  begin
    ActionCombo.ItemIndex := 0;
    ActionCombo.Enabled := false;
    Label2.Caption := rsWith;
  end
  else
    ActionCombo.Enabled := true;
end;

procedure TGroupEditorForm.JunctionsRadioBtnChange(Sender: TObject);
begin
  if JunctionsRadioBtn.Checked then
  begin
    SetParamChoices(FilterParamCombo, JuncParamsTxt);
    SetParamChoices(ParamCombo, JuncParamsTxt);
  end
  else
  begin
    SetParamChoices(FilterParamCombo, PipeParamsTxt);
    SetParamChoices(ParamCombo, PipeParamsTxt);
    FilterRelationCombo.Enabled := true;
    ActionCombo.Enabled := true;
  end;
  FilterParamComboChange(self);
  ParamComboChange(self);
end;

procedure TGroupEditorForm.SetParamChoices(aComboBox: TComboBox; Choices: string);
begin
  with aComboBox do
  begin
    Clear;
    Items.Text := Choices;
    ItemIndex := 0;
  end;
end;

function TGroupEditorForm.GoChangeValues: Boolean;
var
  I: Integer;
  N: Integer = 0;
  Count: Integer = 0;
  Msg: string;
  Msg1: string = rsNoMatches;
  Msg2: string = rsObjsModified;
  Msg3: string = rsMoreEdits;
begin
  Result := true;
  if ObjType = ctNodes then
    epanet2.ENgetcount(EN_NODECOUNT, N)
  else
    epanet2.ENgetcount(EN_LINKCOUNT, N);
  for I := 1 to N do
  begin
    if ObjValueChanged(I) then Inc(Count);
  end;

  if Count = 0 then
    Msg := Msg1
  else
  begin
    MainForm.ProjectFrame.RefreshPropEditor;
    Msg := IntToStr(Count) + ' ' + Msg2;
    HasChanged := true;
  end;
  Msg := Msg + LineEnding + LineEnding + Msg3;
  if utils.MsgDlg(rsPleaseConfirm, Msg, mtConfirmation, [mbYes, mbNo]) = mrNo then
    Result := false;
end;

function TGroupEditorForm.ObjValueChanged(I: Integer): Boolean;
var
  NodeType: Integer = 0;
  LinkType: Integer = 0;
  X: Single;
begin
  Result := false;
  if ObjType = ctNodes then
  begin
    epanet2.ENgetnodetype(I, NodeType);
    if NodeType <> EN_JUNCTION then exit;
  end
  else
  begin
    epanet2.ENgetlinktype(I, LinkType);
    if LinkType <> EN_PIPE then exit;
  end;

  if (NumPolyPts > 0)
  and (not PassesLocationFilter(I)) then exit;
  if (FilterParam = EN_TAG)
  and (not PassesTextFilter(I)) then exit
  else if (FilterParam >= 0)
  and (not PassesNumericalFilter(I)) then exit;

  if ChangeParam = EN_TAG then
  begin
    if ObjType = ctNodes then
      epanet2.ENsettag(EN_NODE, I, PChar(ChangeTag))
    else
      epanet2.ENsettag(EN_LINK, I, PChar(ChangeTag));
  end
  else
  begin
    X := GetNewValue(I);
    if ObjType = ctNodes then
      epanet2.ENsetnodevalue(I, ChangeParam, X)
    else if ObjType = ctLinks then
      epanet2.ENsetlinkvalue(I, ChangeParam, X);
  end;
  Result := true;
end;

function TGroupEditorForm.PassesLocationFilter(I: Integer): Boolean;
var
  N1: Integer = 0;
  N2: Integer = 0;
  Pt: TDoublePoint;
begin
  Result := false;
  if ObjType = ctNodes then
  begin
    if not project.GetNodeCoord(I, Pt.X, Pt.Y) then exit;
    if not utils.PointInPolygon(Pt, GroupBounds, NumPolyPts, GroupPoly) then exit;
  end
  else if ObjType = ctLabels then
  begin
    if not project.GetLabelCoord(I, Pt.X, Pt.Y) then exit;
    if not utils.PointInPolygon(Pt, GroupBounds, NumPolyPts, GroupPoly) then exit;
  end
  else if ObjType = ctLinks then
  begin
    if not project.GetLinkNodes(I, N1, N2) then exit;
    if not project.GetNodeCoord(N1, Pt.X, Pt.Y) then exit;
    if not utils.PointInPolygon(Pt, GroupBounds, NumPolyPts, GroupPoly) then exit;
    if not project.GetNodeCoord(N2, Pt.X, Pt.Y) then exit;
    if not utils.PointInPolygon(Pt, GroupBounds, NumPolyPts, GroupPoly) then exit;
  end;
  Result := true;
end;

function TGroupEditorForm.PassesTextFilter(I: Integer): Boolean;
var
  S: string;
begin
  S := project.GetTag(ObjType, I);
  Result := (AnsiCompareStr(S, FilterTag) = 0);
end;

function TGroupEditorForm.PassesNumericalFilter(I: Integer): Boolean;
var
  X: Single;
begin
  if ObjType = ctNodes then
    epanet2.ENgetnodevalue(I, FilterParam, X)
  else
    epanet2.ENgetlinkvalue(I, FilterParam, X);
  case FilterRelation of
    BELOW:
      Result := (X <= FilterValue);
    EQUAL:
      Result := (Abs(X - FilterValue) < 0.0001);
    ABOVE:
      Result := (X >= FilterValue);
    else
      Result := false;
  end;
end;

function TGroupEditorForm.GetNewValue(Index: Integer): Single;
var
  X: Single;
begin
  if ChangeAction = REPLACE then
    Result := ChangeValue
  else
  begin
    if ObjType = ctNodes then
      epanet2.ENgetnodevalue(Index, ChangeParam, X)
    else
      epanet2.ENgetlinkvalue(Index, ChangeParam, X);
    if ChangeAction = MULTIPLY then
      Result := X * ChangeValue
    else if ChangeAction = ADD then
      Result := X + ChangeValue
    else
      Result := ChangeValue;
  end;
end;

function TGroupEditorForm.DeleteObjects: Boolean;
var
  I: Integer;
  N: Integer;
begin
  // Confirm deletion
  Result := false;
  if utils.MsgDlg(rsPleaseConfirm, rsDeleteAll, mtConfirmation,
    [mbYes, mbNo]) = mrNo then exit;

  // Delete nodes (which will also delete connecting links)
  ObjType := ctNodes;
  N := project.GetItemCount(ctNodes);
  for I := N downto 1 do
  begin
    if (NumPolyPts > 0)
    and (not PassesLocationFilter(I)) then continue;
    project.DeleteItem(ctNodes, I);
    Result := true;
  end;

  // Delete labels
  ObjType := ctLabels;
  N := project.GetItemCount(ctLabels);
  for I := N downto 1 do
  begin
    if (NumPolyPts > 0)
    and (not PassesLocationFilter(I)) then continue;
    project.DeleteItem(ctLabels, I);
    Result := true;
  end;

  // Adjust the network map's extent
  if Result then
  begin
    MainForm.MapFrame.Map.Extent := MapCoords.GetBounds(MainForm.MapFrame.GetExtent);
    MainForm.OverviewMapFrame.Redraw;
  end;

  // Update any report affected by deletions
  ReportViewerForm.UpdateReport;
end;

end.

