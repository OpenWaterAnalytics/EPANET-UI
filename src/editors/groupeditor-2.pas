unit groupeditor;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Dialogs,
  Graphics, ValEdit, mapcoords;

type

  TSelectionType = (   // Indicates how objects will be selected
    stIndividual = 1,  // one by one
    stByTag,           // by Tag property
    stByRegion,        // by user-defined region
    stAll);            // entire selected

  { TGroupEditorFrame }

  TGroupEditorFrame = class(TFrame)
    BackBtn:                TButton;
    EditingPage: TPage;
    EditingLabel: TLabel;
    MakeChangesBtn1: TButton;
    NextBtn:                TButton;
    RemoveBtn:              TButton;
    ClearBtn:               TButton;
    AllBtn:                 TRadioButton;
    IndividualBtn:          TRadioButton;
    TagBtn:                 TRadioButton;
    RegionBtn:              TRadioButton;
    CloseBtn:               TSpeedButton;
    NodesBox:               TCheckBox;
    LinksBox:               TCheckBox;
    TagEdit:                TEdit;
    Label2:                 TLabel;
    Label3:                 TLabel;
    SelectLabel:            TLabel;
    ListBox1:               TListBox;
    Notebook1:              TNotebook;
    SelectionPage:          TPage;
    SelectionTypePage:      TPage;
    TopPanel:               TPanel;
    NavigationPanel:        TPanel;
    ValueListEditor1: TValueListEditor;

    procedure BackBtnClick(Sender: TObject);
    procedure ClearBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure LinksBoxChange(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure NodesBoxChange(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);

  private
    ObjectType:        Integer;
    ObjectTypeTxt:     string;
    ObjectTypeChanged: Boolean;
    SelectionType:     TSelectionType;
    OldSelectionType:  TSelectionType;
    AllItemsSelected:  Boolean;
    FilterParam:       Integer;
    FilterRelation:    Integer;
    FilterValue:       Single;
    FilterTag:         string;
    ChangeAction:      Integer;
    ChangeParam:       Integer;
    ChangeTag:         string;
    ChangeValue:       Single;
    ResultsStatus:     string;

    procedure SetSelectionButtons;
    procedure SetParamChoices(aComboBox: TComboBox; Choices: string);
    procedure DoSelectionType;
    function  DoSelectByTag: Boolean;
    procedure DoSelectByRegion;
    procedure InitValueListEditor;
    procedure InitEditingPage;
    function  ObjectValueChanged(I: Integer): Boolean;
    function  PassesTextFilter(I: Integer): Boolean;
    function  PassesNumericalFilter(I: Integer): Boolean;
    function  GetNewValue(Index: Integer): Single;
    procedure MakeChanges;
    procedure CloseFrame;

  public
    procedure Init;
    procedure SelectObject(ObjType: Integer; Item: Integer);
    procedure SelectRegion(Poly: TPolygon; const Npts: Integer);

  end;

implementation

{$R *.lfm}

uses
  main, project, config, utils, resourcestrings, epanet2;

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

  SelectionTypeTxt: array[1..4] of string =
    (' selected individually', ' selected by Tag', ' selected by region', '');

  FilterTypeTxt: array[0..2] of string =
    ('below', 'equal to', 'above');
  ChangeTypeTxt: array[0..2] of string =
    ('replacing it with', 'adding to it', 'multiplying it');

  BELOW = 0;
  EQUAL = 1;
  ABOVE = 2;
  FilterRelationsTxt: string = rsFilters;

  REPLACE = 0;
  MULTIPLY = 1;
  ADD = 2;
  ChangeActionsTxt: string = rsActions;

procedure TGroupEditorFrame.BackBtnClick(Sender: TObject);
begin
  NextBtn.Caption := 'Next';
  if SameText(Notebook1.ActivePage, 'EditingPage') and AllItemsSelected then
    Notebook1.PageIndex := Notebook1.IndexOf(SelectionTypePage)
  else
    Notebook1.PageIndex := Notebook1.PageIndex - 1;
  BackBtn.Enabled := Notebook1.PageIndex > 0;
end;


procedure TGroupEditorFrame.ClearBtnClick(Sender: TObject);
begin
  ListBox1.Clear;
  SetSelectionButtons;
end;

procedure TGroupEditorFrame.CloseBtnClick(Sender: TObject);
begin
  CloseFrame;
end;

procedure TGroupEditorFrame.LinksBoxChange(Sender: TObject);
begin
  NodesBox.Checked := not LinksBox.Checked;
end;

procedure TGroupEditorFrame.NextBtnClick(Sender: TObject);
var
  S: string;
begin
  BackBtn.Enabled := true;
  if SameText(Notebook1.ActivePage, 'SelectionTypePage') then
  begin
    if NodesBox.Checked then
    begin
      ObjectType := ctNodes;
      ObjectTypeTxt := rsNodes;
    end
    else
    begin
      ObjectType := ctLinks;
      ObjectTypeTxt := rsLinks;
    end;
    DoSelectionType;
  end

  else if SameText(Notebook1.ActivePage, 'EditingPage') then
  begin
    CloseFrame;
    exit;
  end

  else
  begin
    Notebook1.PageIndex := Notebook1.PageIndex + 1;
  end;

  if SameText(Notebook1.ActivePage, 'EditingPage') then
  begin
    NextBtn.Caption := 'Close';
    S := 'For all ' + ObjectTypeTxt + SelectionTypeTxt[Ord(SelectionType)];
    EditingLabel.Caption := S;
    if ObjectTypeChanged then InitEditingPage;
  end;
end;

procedure TGroupEditorFrame.NodesBoxChange(Sender: TObject);
begin
  LinksBox.Checked := not NodesBox.Checked;
  ObjectTypeChanged := true;
end;

procedure TGroupEditorFrame.RemoveBtnClick(Sender: TObject);
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
  SetSelectionButtons;
end;

procedure TGroupEditorFrame.SetSelectionButtons;
var
  N: Integer;
begin
  if Notebook1.ActivePage = 'SelectionPage' then
  begin
    N := ListBox1.Count;
    ClearBtn.Enabled := N > 0;
    RemoveBtn.Enabled := N > 0;
  end;
end;

procedure TGroupEditorFrame.DoSelectionType;
begin
  if AllItemsSelected then
  begin
    AllItemsSelected := false;
    ListBox1.Clear;
  end;
  SelectLabel.Caption := 'Click ' + ObjectTypeTxt + ' on the map to select them.';
  if TagBtn.Checked then
  begin
    SelectionType := stByTag;
    if DoSelectByTag then
      Notebook1.PageIndex := Notebook1.PageIndex + 1;
  end
  else if RegionBtn.Checked then
  begin
    SelectionType := stByRegion;
    DoSelectByRegion;
  end
  else if AllBtn.Checked then
  begin
    AllItemsSelected := true;
    SelectionType := stAll;
    ListBox1.Clear;
    Notebook1.PageIndex := Notebook1.IndexOf(EditingPage);
  end
  else
  begin
    SelectionType := stIndividual;
    if OldSelectionType <> SelectionType then
    begin
      ListBox1.Clear;
      ListBox1.Enabled := true;
    end;
    Notebook1.PageIndex := Notebook1.PageIndex + 1;
    SetSelectionButtons;
  end;
  OldSelectionType := SelectionType;
end;

procedure TGroupEditorFrame.SelectObject(ObjType: Integer; Item: Integer);
var
  ItemIndex: Integer;
  ItemName: string = '';
begin
  if (Notebook1.ActivePage <> 'SelectionPage') then exit;
  if (ObjType <> ObjectType) then exit;

  ItemName := project.GetItemID(ObjectType, Item);
  if Length(ItemName) = 0 then exit;

  ItemIndex := ListBox1.Items.IndexOf(ItemName);
  if ItemIndex >= 0 then
    ListBox1.ItemIndex := ItemIndex
  else
  begin
    ListBox1.Items.Add(ItemName);
    ListBox1.ItemIndex := ListBox1.Count - 1;
    SetSelectionButtons;
  end;
end;

procedure TGroupEditorFrame.SelectRegion(Poly: TPolygon; const Npts: Integer);
var
  I:           Integer;
  N1:          Integer;
  N2:          Integer;
  Pt:          TDoublePoint = (X: 0; Y: 0);
  GroupBounds: TDoubleRect = (LowerLeft: (X: 0; Y: 0); UpperRight: (X: 0; Y: 0));
begin
  MainForm.HintPanel.Hide;
  Show;

  // Npts = -1 indicates that all network nodes were selected
  if Npts = -1 then
  begin
    AllBtn.Checked := true;
    DoSelectionType;
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

  // Add objects in polygon to object listbox
  ListBox1.Clear;
  ListBox1.Items.BeginUpdate;

  // For nodes, add those within group bounds
  if ObjectType = ctNodes then
  begin
    for I := 1 to project.GetItemCount(ctNodes) do
    begin
      if not project.GetNodeCoord(I, Pt.X, Pt.Y) then continue;
      if utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then
        ListBox1.Items.Add(project.GetID(ctNodes, I));
    end;
  end

  // For links, add those with end nodes within bounds
  else
  begin
    for I := 1 to project.GetItemCount(ctLinks) do
    begin
      if not project.GetLinkNodes(I, N1, N2) then continue;
      if not project.GetNodeCoord(N1, Pt.X, Pt.Y) then continue;
      if not utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then continue;
      if not project.GetNodeCoord(N2, Pt.X, Pt.Y) then continue;
      if not utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then continue;
      ListBox1.Items.Add(project.GetID(ctLinks, I));
    end;
  end;
  ListBox1.Items.EndUpdate;
  SelectLabel.Caption := ObjectTypeTxt + ' selected by region';
  ListBox1.Enabled := true;
  RemoveBtn.Enabled := false;
  ClearBtn.Enabled := false;
  Notebook1.PageIndex := Notebook1.IndexOf(SelectionPage);
end;

function TGroupEditorFrame.DoSelectByTag: Boolean;
var
  T1: string = '';
  T2: string;
  I: Integer;
  N: Integer;
begin
  Result := false;
  T1 := TagEdit.Text;
  N := 0;
  for I := 1 to project.GetItemCount(ObjectType) do
  begin
    T2 := project.GetTag(ObjectType, I);
    if SameText(T1, T2) then
    begin
      if N = 0 then
        ListBox1.Clear;
      ListBox1.Items.Add(project.GetID(ObjectType, I));
      Inc(N);
    end;
  end;
  if N = 0 then
  begin
    utils.MsgDlg(rsMissingData, rsNoTagNodes + T1, mtInformation, [mbOK], MainForm);
    exit;
  end
  else
  begin
    SelectLabel.Caption := ObjectTypeTxt + ' selected by Tag';
    ListBox1.Enabled := true;
    RemoveBtn.Enabled := false;
    ClearBtn.Enabled := false;
  end;
  Result := true;
end;

procedure TGroupEditorFrame.DoSelectByRegion;
begin
  Hide;
  with MainForm do
  begin
    HintTitleLabel.Caption:= 'Group Selection';
    HintTextLabel.Caption := rsToGroupSelect;
    HintPanel.Visible := True;
    MapFrame.EnterFenceLiningMode('GroupEditing');
  end;
end;

procedure TGroupEditorFrame.SetParamChoices(aComboBox: TComboBox; Choices: string);
begin
  with aComboBox do
  begin
    Clear;
    Items.Text := Choices;
    ItemIndex := 0;
  end;
end;

procedure TGroupEditorFrame.MakeChanges;
var
  I: Integer;
  J: Integer;
  N: Integer = 0;
  Count: Integer = 0;
  Msg: string;
  Msg1: string = rsNoMatches;
  Msg2: string = rsObjsModified;
  Msg3: string = rsMoreEdits;
begin
  if AllItemsSelected then
  begin
    if ObjectType = ctNodes then
      epanet2.ENgetcount(EN_NODECOUNT, N)
    else
      epanet2.ENgetcount(EN_LINKCOUNT, N);
    for I := 1 to N do
    begin
      if ObjectValueChanged(I) then Inc(Count);
    end;
  end

  else
  begin
    N := ListBox1.Items.Count;
    for J := 0 to N-1 do
    begin
      I := project.GetItemIndex(ObjectType, ListBox1.Items[J]);
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
  end;
  Msg := Msg + LineEnding + LineEnding + Msg3;
  if utils.MsgDlg(rsPleaseConfirm, Msg, mtConfirmation, [mbYes, mbNo]) = mrNo then
    CloseFrame;
end;

function TGroupEditorFrame.ObjectValueChanged(I: Integer): Boolean;
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

  if (FilterParam = EN_TAG)
  and (not PassesTextFilter(I)) then exit
  else if (FilterParam >= 0)
  and (not PassesNumericalFilter(I)) then exit;

  if ChangeParam = EN_TAG then
  begin
    if ObjectType = ctNodes then
      epanet2.ENsettag(EN_NODE, I, PChar(ChangeTag))
    else
      epanet2.ENsettag(EN_LINK, I, PChar(ChangeTag));
  end
  else
  begin
    X := GetNewValue(I);
    if ObjectType = ctNodes then
      epanet2.ENsetnodevalue(I, ChangeParam, X)
    else if ObjectType = ctLinks then
      epanet2.ENsetlinkvalue(I, ChangeParam, X);
  end;
  Result := true;
end;

function TGroupEditorFrame.PassesTextFilter(I: Integer): Boolean;
var
  S: string;
begin
  S := project.GetTag(ObjectType, I);
  Result := (AnsiCompareStr(S, FilterTag) = 0);
end;

function TGroupEditorFrame.PassesNumericalFilter(I: Integer): Boolean;
var
  X: Single;
begin
  if ObjectType = ctNodes then
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

function TGroupEditorFrame.GetNewValue(Index: Integer): Single;
var
  X: Single;
begin
  if ChangeAction = REPLACE then
    Result := ChangeValue
  else
  begin
    if ObjectType = ctNodes then
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

procedure TGroupEditorFrame.InitEditingPage;
begin
  ObjectTypeChanged := false;
  with ValueListEditor1.ItemProps[0] do
  begin
    if ObjectType = ctNodes then
      PickList.Assign(MainForm.MainMenuFrame.ViewNodeCombo.Items)
    else
      PickList.Assign(MainForm.MainMenuFrame.ViewLinkCombo.Items);
  end;
  with ValueListEditor1.ItemProps[3] do
  begin
    if ObjectType = ctNodes then
      PickList.Assign(MainForm.MainMenuFrame.ViewNodeCombo.Items)
    else
      PickList.Assign(MainForm.MainMenuFrame.ViewLinkCombo.Items);
  end;
end;

procedure TGroupEditorFrame.InitValueListEditor;
var
  I: Integer;
begin
  with ValueListEditor1 do
  begin
    FixedRows := 0;
    with ItemProps[0] do
    begin
      EditStyle := esPickList;
      ReadOnly := true;
    end;
    with ItemProps[1] do
    begin
      EditStyle := esPickList;
      ReadOnly := True;
      for I := 0 to 2 do PickList.Add(FilterTypeTxt[I]);
    end;
    with ItemProps[3] do
    begin
      EditStyle := esPickList;
      ReadOnly := true;
    end;
    with ItemProps[4] do
    begin
      EditStyle := esPickList;
      ReadOnly := True;
      for I := 0 to 2 do PickList.Add(ChangeTypeTxt[I]);
    end;
  end;
end;

procedure TGroupEditorFrame.Init;
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;

  ListBox1.Clear;
  BackBtn.Enabled := false;
  NextBtn.Enabled := true;
  NextBtn.Caption := 'Next';
  NodesBox.Checked := true;
  LinksBox.Checked := false;

  IndividualBtn.Checked := true;
  RemoveBtn.Enabled := false;
  ClearBtn.Enabled := false;

  ObjectType := ctNodes;
  SelectionType := stIndividual;
  OldSelectionType := stIndividual;
  AllItemsSelected := false;
  InitValueListEditor;

  ObjectTypeChanged := true;
  Notebook1.PageIndex := 0;
  with MainForm.StatusBarFrame do
  begin
    ResultsStatus := GetPanelText(Ord(sbResults));
    SetPanelText(Ord(sbResults), 'Group Editing');
    SetPanelColor(Ord(sbResults), clGradientActiveCaption);
  end;
  MainForm.EnableMainForm(false);

end;

procedure TGroupEditorFrame.CloseFrame;
begin
  Hide;
  MainForm.EnableMainForm(true);
  MainForm.MainMenuFrame.GroupEditBtn.Down := false;
  MainForm.UpdateStatusBar(sbResults, ResultsStatus);
end;

end.

