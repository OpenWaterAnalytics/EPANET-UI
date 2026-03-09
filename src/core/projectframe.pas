{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       projectframe
 Description:  displays and edits the properties of project objects
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit projectframe;

{ The ProjectFrame, appearing in the left side panel of the MainForm,
  serves as a project explorer / property editor. Its main
  components are the ProjectTreeView which lists EPANET object
  categories, and the PropEditor (a TValueListEditor) used to edit
  the properties of individual objects.

  The frame keeps track of the user's currently selected object category
  (CurentCategory) and the 0-base index of the currently selected item
  within that category (SelectedItem[CurrentCategory]).
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, ComCtrls, Grids,
  Dialogs, Graphics, ValEdit, LCLtype, LCLIntf, Buttons,

  // EPANET-UI units
  project, mapcoords;

type

  { TProjectFrame }

  TProjectFrame = class(TFrame)
    Notebook1:          TNotebook;
    TitlePage:          TPage;
    PropertyPage:       TPage;
    TitleBox:           TGroupBox;
    NotesBox:           TGroupBox;
    Panel1:             TPanel;
    Panel2:             TPanel;
    TopPanel:           TPanel;
    HintPanel:          TPanel;
    ItemPanel:          TPanel;
    ExplorerPanel:      TPanel;
    PropertyPanel:      TPanel;
    EditTitleBtn:       TSpeedButton;
    NextItemBtn:        TSpeedButton;
    PrevItemBtn:        TSpeedButton;
    NotesLabel:         TLabel;
    TitleLabel:         TLabel;
    PropEditor:         TValueListEditor;
    FrameSplitter:      TSplitter;
    ProjectTreeView:    TTreeView;

    procedure EditTitleBtnClick(Sender: TObject);
    procedure ItemBtnsClick(Sender: TObject);
    procedure PropEditorEditingDone(Sender: TObject);
    procedure PropEditorPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
              aState: TGridDrawState);
    procedure PropEditorSelectCell(Sender: TObject; aCol,
              aRow: Integer; var CanSelect: Boolean);
    procedure PropEditorButtonClick(Sender: TObject; aCol, aRow: Integer);
    procedure PropEditorValidateEntry(Sender: TObject; aCol, aRow: Integer;
              const OldValue: string; var NewValue: string);
    procedure ProjectTreeViewChange(Sender: TObject; Node: TTreeNode);
    procedure ProjectTreeViewClick(Sender: TObject);

  private
    procedure ShowHelpTopic;
    procedure ShowTitle;
    procedure UpdatePropEditor(aItem: Integer);                                               
    procedure UpdateDeleteBtn;

  public
    CopiedCategory:    Integer;
    CopiedType:        Integer;
    CurrentCategory:   Integer;
    PreviousRow:       Integer;
    SelectedItem:      array [0..project.ctLabels] of Integer;
    ValidationNeeded:  Boolean;

    procedure CopyItem;
    procedure ConvertItem(ToType: Integer);
    procedure DeleteItem;
    procedure GroupEdit(GroupPoly: TPolygon; NumPolyPts: Integer);
    procedure Init;
    procedure InitSplit;
    procedure PasteItem;
    procedure PropEditorKeyPress(Key: Word);
    procedure RefreshPropEditor;
    procedure SelectItem(aCategory: Integer; aItem: Integer);
    procedure ShowItemID(aItem: Integer);
    procedure UpdateResultsDisplay;

  end;

implementation

{$R *.lfm}

uses
  main, editor, properties, groupeditor, mapthemes, config, utils,
  reportviewer, resourcestrings;

const
  // Maps project object categories to their index in ProjectTreeView
  TreeIndex: array[ctTitle..ctCurves] of Integer =
    (0, 1, 7, 8, 11, 14, 9, 10);

{ TProjectFrame }

procedure TProjectFrame.Init;
var
  I: Integer;
begin
  // Set component colors
  Color := config.ThemeColor;
  Panel2.Color := Color;
  PropEditor.FixedColor:= Color;
  PropEditor.Color := clWindow;

  // Set enabled state of Project Explorer's treeview items
  for I := 0 to ctCurves do
  begin
    SelectedItem[I] := -1;
    ProjectTreeView.Items[TreeIndex[I]].Enabled := true;
  end;
  for I in [ctNodes, ctLinks, ctLabels] do
  begin
    if project.GetItemCount(I) > 0 then
      SelectedItem[I] := 0
    else
      ProjectTreeView.Items[TreeIndex[I]].Enabled := false;
  end;

  // Set initial selected data category
  CurrentCategory := ctTitle;
  with ProjectTreeView do Select(Items[0]);
  SelectItem(ctTitle, 0);
  PreviousRow := 0;
  CopiedCategory := 0;
  CopiedType := -1;
  ValidationNeeded := true;
  PropEditor.FastEditing := false;
  {$ifdef MSWINDOWS}
  PropEditor.Options := PropEditor.Options + [goAlwaysShowEditor];
  {$endif}
end;

procedure TProjectFrame.InitSplit;
begin
  ExplorerPanel.Height := Panel1.ClientHeight div 2;
end;

//------------------------------------------------------------------------------
//  Project Explorer Events
//------------------------------------------------------------------------------

procedure TProjectFrame.ProjectTreeViewChange(Sender: TObject; Node: TTreeNode);
//
//  Takes an action when a node of the ProjectTreeView is selected.
//
var
  aCategory: Integer;
  aItem:     Integer;
begin
  // Get data category from treeview's selected node
  if not Assigned(ProjectTreeView.Selected) then exit;
  aCategory := ProjectTreeView.Selected.SelectedIndex;

  // Expand tree if Analysis Options chosen
  if (aCategory = ctOptions) then
  begin
    ProjectTreeView.Selected.Expand(false);
    exit;
  end;

  // Title/Notes chosen
  if aCategory = ctTitle then
    aItem := 0

  // Sub-category of Analysis Options selected
  else if (aCategory >= 10)
  and (aCategory < 20) then
  begin
    // Display name of sub-category
    ItemPanel.Caption := rsAnalysisOpts + ProjectTreeView.Selected.Text;
    // Convert sub-category to an options index
    aItem := aCategory - 10;
    aCategory := ctOptions;
  end

  // Nodes, Links, or Map Labels selected
  else if aCategory in [ctNodes, ctLinks, ctLabels] then
  begin
    aItem := SelectedItem[aCategory];
  end

  // Time patterns or curves selected
  else if aCategory = ctPatterns then
  begin
    ItemPanel.Caption := '';
    SelectItem(ctPatterns, -1);
    editor.Edit(ctPatterns, -1);
    exit;
  end
  else if aCategory = ctCurves then
  begin
    ItemPanel.Caption := '';
    SelectItem(ctCurves, -1);
    editor.Edit(ctCurves, -1);
    exit;
  end

  // Control Actions selected
  else if aCategory = ctControls then
  begin
    ProjectTreeView.Selected.Expand(false);
    exit;
  end

  // Sub-category of Control Actions selected
  else if aCategory > 20 then
  begin
    ItemPanel.Caption := '';
    SelectItem(ctControls, -1);
    editor.Edit(ctControls, aCategory - 21);
    exit;
  end

  else
    exit;

  // Setup the Property Editor page
  SelectItem(aCategory, aItem);
end;

procedure TProjectFrame.ProjectTreeViewClick(Sender: TObject);
begin
  ProjectTreeViewChange(Sender, ProjectTreeView.Selected);
end;

procedure TProjectFrame.SelectItem(aCategory: Integer; aItem: Integer);
//
//  Select an item into the frame's property editor (PropEditor).
//
begin
  // Display the project's Title/Notes
  CurrentCategory := aCategory;
  if CurrentCategory = ctTitle then
  begin
    ShowTitle;
    exit;
  end;

  // Make the PropertyPage of the lower panel visible
  Notebook1.PageIndex := 1;
  EditTitleBtn.Visible := false;
  PrevItemBtn.Visible := CurrentCategory in [ctNodes, ctLinks, ctLabels];
  NextItemBtn.Visible := PrevItemBtn.Visible;
  MainForm.MainMenuFrame.UpdateEditMenuBtns;
  PreviousRow := PropEditor.Row;

  // Update the category's selected item
  SelectedItem[CurrentCategory] := aItem;
  if CurrentCategory in [ctNodes, ctLinks, ctLabels] then
    ProjectTreeView.Selected := ProjectTreeView.Items[TreeIndex[Currentcategory]];

  // Hide the property editor if the selected category has no items
  if aItem < 0 then
    PropertyPanel.Visible := false
  else
  begin
    ProjectTreeView.Items[TreeIndex[CurrentCategory]].Enabled := true;
    // Need to reset goAlwaysShowEditor so that GridEditor properties
    // get displayed properly
    //PropEditor.Options := PropEditor.Options - [goAlwaysShowEditor];
    UpdatePropEditor(aItem);
    UpdateDeleteBtn;
    MainForm.MapFrame.HiliteObject(CurrentCategory, aItem + 1);
    //PropEditor.Options := PropEditor.Options + [goAlwaysShowEditor];
  end;

  // If a time series selector frame is visible, inform it of selected object
  with MainForm.TseriesSelectorFrame do
    if Visible then SetSelectedObjectProps;

  // If a basemap alignment frame is visible, tell it which node was selected
  with MainForm.MapAlignFrame do
    if Visible and (CurrentCategory = ctNodes) then SetNode(aItem);

  // If a fire flow selector frame is visible, tell it which node was selected
  with MainForm.FireFlowSelectorFrame do
    if Visible and (CurrentCategory = ctNodes) then SelectNode(aItem);
end;

procedure TProjectFrame.UpdateDeleteBtn;
//
//  Update the state of the Delete button on the MainMenuFrame when
//  a new category in the ProjectTreeView is selected.
//
begin
  with MainForm.MainMenuFrame.ProjectDeleteBtn do
  begin
    // These categories don't have items that can be deleted
    if CurrentCategory in
      [ctTitle, ctOptions, ctControls, ctPatterns, ctCurves] then
      Enabled := false

    // Can't delete items from an empty category
    else if project.GetItemCount(CurrentCategory) = 0 then
      Enabled := false
    else
      Enabled := true;
  end;
end;

procedure TProjectFrame.DeleteItem;
//
//  Delete the currently selected object from the project.
//
var
  Nitems: Integer;
  aItem:  Integer;
  Msg:    string;
begin
  // Confirm item deletion
  aItem := SelectedItem[CurrentCategory];
  if config.ConfirmDeletions then
  begin
    Msg := rsWishToRemove + ' ' +
           project.GetItemTypeStr(CurrentCategory, aItem) +
           project.GetItemID(CurrentCategory, aItem);
    if CurrentCategory = ctNodes then
      Msg := Msg + ' ' + rsConnectedLinks;
    Msg := Msg + '?';
    if utils.MsgDlg(rsConfirmDelete, Msg, mtConfirmation, [mbYes, mbNo])
      = mrNo then exit;
  end;

  // Delete item from project (DeleteItem takes 1-based index as argument)
  project.DeleteItem(CurrentCategory, aItem + 1);

  // Update ProjectTreeView if deleting a node results in no more links
  if (Currentcategory = ctNodes)
  and (project.GetItemCount(ctLinks) = 0) then
  begin
    SelectedItem[ctLinks] := -1;
    ProjectTreeView.Items[TreeIndex[ctLinks]].Enabled := false;
  end;

  // Get remaining number of items for current category
  Nitems := project.GetItemCount(CurrentCategory);

  // No more items remain - disable category in ProjectTreeView
  if Nitems = 0 then
  begin
    SelectedItem[CurrentCategory] := -1;
    MainForm.MapFrame.HiliteObject(CurrentCategory, aItem);
    ProjectTreeView.Items[TreeIndex[CurrentCategory]].Enabled := false;
    ProjectTreeView.Select(ProjectTreeView.Items[0]);
  end

  // Shift selected item for the current object category
  else begin
    if aItem = Nitems then Dec(aItem);
    SelectItem(CurrentCategory, aItem);
  end;

  // Disable MainMenuFrame's Delete button
  UpdateDeleteBtn;

  // Update any report affected by this item deletion
  ReportViewerForm.UpdateReport;
end;

procedure TProjectFrame.ConvertItem(ToType: Integer);
//
//  Convert the currently selected object to a different type.
//
var
  aItem: Integer;
begin
  if CurrentCategory <> ctLinks then exit;
  aItem := SelectedItem[CurrentCategory];
  if project.ConvertLink(aItem+1, ToType) then
  begin
    project.HasChanged := true;
    project.UpdateResultsStatus;
    MainForm.MapFrame.RedrawMap;
    SelectItem(CurrentCategory, aItem);
  end;
end;

procedure TProjectFrame.CopyItem;
//
//  Copy the properties of the currently selected node or link to
//  the project's CopiedProperties stringlist.
//
var
  I: Integer;
begin
  // Initialize info on item being copied
  CopiedCategory := 0;
  CopiedType := -1;

  // A node is being copied (junction, reservoir or tank)
  if CurrentCategory = ctNodes then
  begin
    CopiedCategory := ctNodes;
    CopiedType := project.GetNodeType(SelectedItem[ctNodes] + 1);
  end

  // A link is being copied (pipe, pump or valve)
  else if CurrentCategory = ctLinks then
  begin
    CopiedCategory := ctLinks;
    CopiedType := project.GetLinkType(SelectedItem[ctLinks] + 1);
  end

  // Can't copy other categories of objects
  else
    exit;

  // Save the properties of the item being copied
  project.CopiedProperties.Clear;
  with PropEditor do
    for I := 0 to RowCount do
      project.CopiedProperties.Add(Cells[1, I]);
end;

procedure TProjectFrame.PasteItem;
//
//  Paste copied properties into the currently selected object.
//
var
  Item: Integer;
begin
  Item := SelectedItem[CurrentCategory];
  if project.CanPasteItem(Item, CopiedCategory, CopiedType) then
  begin
    Editor.PasteProperties(CurrentCategory, CopiedType, Item);
    UpdatePropEditor(Item);
  end
  else
    Utils.MsgDlg(rsInvalidSelect, rsNotSameType, mtInformation, [mbOK]);
end;

procedure TProjectFrame.GroupEdit(GroupPoly: TPolygon; NumPolyPts: Integer);
//
//  Edits or deletes a group of objects lying within a polygon region.
//
var
  ProjectUpdated: Boolean = false;
begin
  MainForm.HintPanel.Hide;

  // NumPolyPts of -1 means entire network was selected
  if (NumPolyPts = -1) or (NumPolyPts >= 3) then
  with TGroupEditorForm.Create(MainForm) do
  try
    Init(GroupPoly, NumPolyPts);
    if MainForm.MainMenuFrame.GroupDeleteBtn.Down then
      ProjectUpdated := DeleteObjects
    else
    begin
      ShowModal;
      if (ModalResult = mrOk) then
        ProjectUpdated := HasChanged;
    end;
    if ProjectUpdated then
    begin
      project.HasChanged := true;
      RefreshPropEditor;
      project.UpdateResultsStatus;
      MainForm.MapFrame.RedrawMap;
    end;
  finally
    Free;
  end
  else
    utils.MsgDlg('', rsNoSelect, mtInformation, [mbOK], MainForm);
  MainForm.MainMenuFrame.GroupEditBtn.Down := false;
  MainForm.MainMenuFrame.GroupDeleteBtn.Down := false;
end;

procedure TProjectFrame.ItemBtnsClick(Sender: TObject);
//
// OnClick handler for the < and > buttons on the Property Editor.
//
var
  CurrentItem: Integer;
  MoveTo:      Integer;
begin
  // Tag for NextItemBtn is +1, for PrevItemBtn is -1
  with Sender as TSpeedButton do
    MoveTo := Tag;

  // Change the current item depending on which button pressed
  CurrentItem := SelectedItem[CurrentCategory];
  if (MoveTo = 1)
  and (CurrentItem < project.GetItemCount(CurrentCategory) - 1) then
    Inc(CurrentItem)
  else if (MoveTo = -1)
  and (CurrentItem > 0) then
    Dec(CurrentItem)
  else
    exit;

  // Update the Property Editor
  SelectedItem[CurrentCategory] := CurrentItem;
  UpdatePropEditor(SelectedItem[CurrentCategory]);

  // Hilite new item on map (using item's 1-based indexing)
  MainForm.MapFrame.HiliteObject(CurrentCategory, CurrentItem + 1);
end;

procedure TProjectFrame.EditTitleBtnClick(Sender: TObject);
//
//  OnClick handler for editing the project's Title/Notes
//
begin
  editor.EditTitleText;
  ShowTitle;
end;

procedure TProjectFrame.PropEditorEditingDone(Sender: TObject);
begin
  //showmessage('Editing done');  // for debugging
end;

procedure TProjectFrame.ShowTitle;
//
//  Adjust what's shown in the property editor panel when
//  the Title/Notes category is selected from the ProjectTreeView.
//
begin
  ItemPanel.Caption:= rsTitleNotes;
  PrevItemBtn.Visible := false;
  NextItemBtn.Visible := false;
  EditTitleBtn.Visible := true;
  Notebook1.PageIndex := 0;
  TitleLabel.Caption := project.GetTitle(0);
  NotesLabel.Caption := project.GetTitle(1) + ' ' + project.GetTitle(2);
end;

procedure TProjectFrame.UpdatePropEditor(aItem: Integer);
//
//  Update the property editor when a new item for the current object
//  category is selected.
//
begin
  ShowItemID(aItem);
  if PropEditor.Row > 0 then
    PreviousRow := PropEditor.Row;
  PropertyPanel.Visible := true;
  ValidationNeeded := false;
  editor.Edit(CurrentCategory, aItem);
  ValidationNeeded := true;
end;

procedure TProjectFrame.RefreshPropEditor;
//
//  Refresh contents of the property editor for a specific object.
//
begin
  editor.Edit(CurrentCategory, SelectedItem[CurrentCategory]);
end;

procedure TProjectFrame.ShowItemID(aItem: Integer);
//
//  Display selected object's ID in header above the property editor.
//
begin
  if CurrentCategory in [ctNodes, ctLinks] then
    ItemPanel.Caption := ' ' + project.GetItemTypeStr(CurrentCategory, aItem) +
      ' ' + project.GetItemID(CurrentCategory, aItem)
  else if CurrentCategory = ctLabels then
    ItemPanel.Caption := rsMapLabels;
end;

procedure TProjectFrame.UpdateResultsDisplay;
//
//  Update display of computed results in the property editor.
//
begin
  if CurrentCategory in [ctNodes, ctLinks] then
    editor.Edit(CurrentCategory, SelectedItem[CurrentCategory]);
end;

{-------------------------------------------------------------------------------
  Property Editor Events
-------------------------------------------------------------------------------}

procedure TProjectFrame.PropEditorPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if not (sender is TValueListEditor) then exit;

  // Header row color
  if (aRow = 0) then PropEditor.Canvas.Brush.Color := config.ThemeColor;

  // Color used for cells that display simulation results
  if (aCol = 1) then
  begin
    if (Editor.FirstResultRow > 0) and
      (aRow >= Editor.FirstResultRow) then
        PropEditor.Canvas.Brush.Color := $00E1FFFF;
  end;
end;

procedure TProjectFrame.PropEditorKeyPress(Key: Word);
//
//  Called by MainForm's OnKeyPress procedure
//
begin
  // Return key press activates an ellipsis button in the editor
  if Key = VK_RETURN then with PropEditor do
  begin
    if ItemProps[Cells[0,Row]].EditStyle = esEllipsis then
      PropEditorButtonClick(PropEditor, 1, Row);
  end

  // F1 key press brings up Help
  else if Key = VK_F1 then
    ShowHelpTopic;
end;

procedure TProjectFrame.PropEditorButtonClick(Sender: TObject; aCol,
  aRow: Integer);
//
//  Launch a custom editor when an ellipsis button in the property
//  editor is clicked.
//
begin
  editor.ButtonClick(CurrentCategory, SelectedItem[CurrentCategory], aRow);
end;

procedure TProjectFrame.PropEditorSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
//
//  Restrict which cells in the property editor can be edited.
//
begin
  // Can't select cells that display simulation results
  if (editor.FirstResultRow > 0)
  and (aRow >= editor.FirstResultRow) then
    CanSelect := false

  // Can't select cells in column 0 that display property names
  else if aCol = 0 then
  begin
    CanSelect := false;
    PropEditor.Row := aRow;
    PropEditor.Col := 1;
  end
  else
    CanSelect := true;
end;

procedure TProjectFrame.PropEditorValidateEntry(sender: TObject; aCol,
  aRow: Integer; const OldValue: string; var NewValue: string);
//
//  OnValidate handler for items in the property editor.
//
begin
  if ValidationNeeded then
  begin
    if not editor.Validate(CurrentCategory, SelectedItem[CurrentCategory],
      aRow, OldValue, NewValue) then
      PropEditor.SetFocus;
  end;
end;

procedure TProjectFrame.ShowHelpTopic;
var
  Topic: string;
begin
  Topic := '';
  case CurrentCategory of
    ctOptions:
      case SelectedItem[ctOptions] of
        otHydraul:
          Topic := '#hydraulic_options';
        otDemands:
          Topic := '#demand_options';
        otQuality:
          Topic := '#water_quality_options';
        otTimes:
          Topic := '#time_options';
        otEnergy:
          Topic := '#energy_options';
      end;
    ctNodes:
      case project.GetNodeType(SelectedItem[ctNodes]+1) of
        ntJunction:
          Topic := '#junction_properties';
        ntReservoir:
          Topic := '#reservoir_properties';
        ntTank:
          Topic := '#tank_properties';
      end;
    ctLinks:
      case project.GetLinkType(SelectedItem[ctLinks]+1) of
        ltPipe:
          Topic := '#pipe_properties';
        ltPump:
          Topic := '#pump_properties';
        ltValve:
          Topic := '#valve_properties';
      end;
    ctLabels:
      Topic := '#label_properties';
  end;
  if Length(Topic) > 0 then MainForm.ViewHelp(Topic);
end;

end.

