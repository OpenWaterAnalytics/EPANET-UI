{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       controlseditor
 Description:  a form that edits a project's set of simple controls
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
{
 This unit edits a project's set of Simple Control statements (not to
 be confused with Lazarus components/controls). They have the format:
   LINK linkID action IF NODE nodeID ABOVE/BELOW value
   LINK linkID action AT TIME time
   LINK linkID action AT CLOCKTIME clocktime

The ControlsEditorForm is auto-created and stay-on-top with layout
_____________________________________________
|                                            | <--- TopPanel
|                                            |
|               ControlsGrid                 |
|                                            |
|____________________________________________|
|                BtnPanel                    |
|____________________________________________|
|                                            | <--- EditorNotebook
|         EditorPage1 & EditorPage2          |
|                                            |
|____________________________________________|
|              BottomBtnPanel                | <--- BottomPanel
|____________________________________________|

 where:
  ControlsGrid   - a list of the project's control statements
  BtnPanel       - contains Insert, Edit, Delete, etc. buttons applied to
                   the current selection in the ControlsGrid
  EditorPage1    - shows a blank panel when no control is being edited
  EditorPage2    - contains an EditPanel with components for editing a control
  BottomBtnPanel - contains OK and Cancel buttons
}

unit controlseditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, lclIntf,
  Buttons, ExtCtrls, LCLtype, Grids;

type

  { TControlsEditorForm }

  TControlsEditorForm = class(TForm)
    BottomBtnPanel: TPanel;
    TopPanel:       TPanel;
    BottomPanel:    TPanel;
    BtnPanel:       TPanel;
    Panel1:         TPanel;
    EditPanel:      TPanel;
    EditorNotebook: TNotebook;
    EditorPage1:    TPage;
    EditorPage2:    TPage;
    ControlsGrid:   TStringGrid;
    InsertBtn:      TBitBtn;
    EditBtn:        TBitBtn;
    DeleteBtn:      TBitBtn;
    UpBtn:          TBitBtn;
    DownBtn:        TBitBtn;
    LinkLabel:      TLabel;
    NodeLabel:      TLabel;
    LinkComboBox:   TComboBox;
    LevelComboBox:  TComboBox;
    LinkBtn:        TSpeedButton;
    NodeBtn:        TSpeedButton;
    IfBtn:          TRadioButton;
    AtBtn:          TRadioButton;
    LevelEdit:      TEdit;
    LinkEdit:       TEdit;
    NodeEdit:       TEdit;
    HelpBtn:        TButton;
    CancelBtn:      TButton;
    OkBtn:          TButton;
    AcceptEditBtn:  TButton;
    CancelEditBtn:  TButton;

    procedure AcceptEditBtnClick(Sender: TObject);
    procedure InsertBtnClick(Sender: TObject);
    procedure CancelEditBtnClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure LinkBtnClick(Sender: TObject);
    procedure NodeBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure ControlsGridCheckboxToggled(Sender: TObject; aCol, aRow: Integer;
      aState: TCheckboxState);
    procedure ControlsGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure DeleteBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure IfBtnChange(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure UpBtnClick(Sender: TObject);

  private
    HasChanged: Boolean;
    IsEditing:  Boolean;
    Shown:      Boolean;

    function ControlToStr(const I: Integer): string;
    function StrToControl(const sControl: string; var aType: Integer;
      var aLink: Integer; var aNode: Integer; var aSetting: Single;
      var aLevel: Single): Boolean;
    procedure SetButtonStates;
    procedure ClearEditor;
    procedure EditControl(const sControl: string);
    function  PropertiesToStr: string;
    function  ValidateControl: Boolean;
    procedure SetControlProperties(const aControl: string);
    procedure ReplaceControl(NewControl: string);

  public
    procedure LoadControls;

  end;

var
  ControlsEditorForm: TControlsEditorForm;

implementation

{$R *.lfm}

uses
  main, epanet2, project, utils, config, resourcestrings;

const
  LevelTypeItems: string = 'BELOW,ABOVE';
  TimeTypeItems: string = 'TIME,CLOCKTIME';

{ TControlsEditorForm }

procedure TControlsEditorForm.FormCreate(Sender: TObject);
begin
  Color := Config.ThemeColor;
  Font.Size := Config.FontSize;
  ControlsGrid.Font.Name := config.MonoFont;
  ControlsGrid.RowCount := 1;
  EditorNotebook.PageIndex := 0;
  Shown := false;
end;

procedure TControlsEditorForm.FormShow(Sender: TObject);
var
  Location: TPoint;
begin
  Color := config.ThemeColor;
  ControlsGrid.FixedColor := Color;
  if not Shown then
  begin
    Location := MainForm.LeftPanel.ClientOrigin;
    Left := Location.X;
    Top := Location.Y;
    Shown := true;
  end;
  if ControlsGrid.RowCount > 1 then
  begin
    ControlsGrid.Row := 1;
  end;
  ControlsGrid.SetFocus;
end;

procedure TControlsEditorForm.OkBtnClick(Sender: TObject);
//
//  Updates the project's set of Simple Control statements when the
//  form's OkBtn is clicked.
//
var
  I: Integer;
  S: string;
  Ncontrols: Integer = 0;
  UseControl: Integer;
  aType: Integer;
  aLink: Integer;
  aNode: Integer;
  aSetting: Single;
  aLevel: Single;
  Index: Integer = 0;
begin
  // Remove all currrent controls from the project
  epanet2.ENgetcount(EN_CONTROLCOUNT, Ncontrols);
  for I := Ncontrols downto 1 do epanet2.ENdeletecontrol(I);

  // Add all control statements in the ControlsGrid to the project
  for I := 1 to ControlsGrid.RowCount-1 do
  begin
    S := ControlsGrid.Cells[1,I];
    StrToControl(S, aType, aLink, aNode, aSetting, aLevel);
    epanet2.ENaddcontrol(aType, aLink, aSetting, aNode, aLevel, Index);
    UseControl := 1;
    if SameText(ControlsGrid.Cells[0,I], '0') then UseControl := 0;
    epanet2.ENsetcontrolenabled(I, UseControl);
  end;

  // Update project status
  if HasChanged then
  begin
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end;

  // Hide this form and re-enable the MainForm
  TopPanel.Enabled := true;
  EditorNotebook.PageIndex := 0;
  Visible := false;
  MainForm.EnableMainForm(true);
end;

procedure TControlsEditorForm.CancelBtnClick(Sender: TObject);
//
//  Hides this form with no changes made when the CancelBtn is clicked.
//
begin
  EditorNotebook.PageIndex := 0;
  TopPanel.Enabled := true;
  ControlsGrid.RowCount := 1;
  Visible := false;
  MainForm.EnableMainForm(true);
end;

procedure TControlsEditorForm.LinkBtnClick(Sender: TObject);
//
//  Places the ID name of the currently selected network link
//  into the LinkEdit component when the LinkBtn is clicked.
//
var
  S: string;
  I: Integer;
begin
  if MainForm.ProjectFrame.CurrentCategory <> ctLinks then
  begin
    utils.MsgDlg(rsInvalidSelect, rsNotLink, mtInformation, [mbOk], self);
    exit;
  end;
  I := MainForm.ProjectFrame.SelectedItem[ctLinks];
  S := project.GetItemID(ctLinks, I);
  LinkEdit.Text := S;
end;

procedure TControlsEditorForm.NodeBtnClick(Sender: TObject);
//
//  Places the ID name of the currently selected network node
//  into the NodeEdit component when the NodeBtn is clicked.
//
var
  S: string;
  I: Integer;
begin
  if MainForm.ProjectFrame.CurrentCategory <> ctNodes then
  begin
    utils.MsgDlg(rsInvalidSelect, rsNotNode, mtInformation, [mbOk], self);
    exit;
  end;
  I := MainForm.ProjectFrame.SelectedItem[ctNodes];
  S := project.GetItemID(ctNodes, I);
  NodeEdit.Text := S;
end;

procedure TControlsEditorForm.AcceptEditBtnClick(Sender: TObject);
//
//  Replaces (or inserts) a control into the form's ControlsGrid
//  after the user finishes editing it.
//
var
  EditedControl: string;
begin
  if not ValidateControl then exit;
  EditedControl := PropertiesToStr;
  ReplaceControl(EditedControl);
  EditorNotebook.PageIndex := 0;
  TopPanel.Enabled := true;
  BottomBtnPanel.Enabled := true;
  SetButtonStates;
  ControlsGrid.SetFocus;
end;

procedure TControlsEditorForm.CancelEditBtnClick(Sender: TObject);
//
//  Actions taken when the user cancels editing a control by clicking
//  the CancelEditBtn.
//
begin
  EditorNotebook.PageIndex := 0;
  TopPanel.Enabled := true;
  BottomBtnPanel.Enabled := true;
  ControlsGrid.SetFocus;
end;

procedure TControlsEditorForm.ControlsGridCheckboxToggled(Sender: TObject;
  aCol, aRow: Integer; aState: TCheckboxState);
begin
  HasChanged := true;
end;

procedure TControlsEditorForm.ControlsGridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
begin
  if aRow > 0 then with Sender as TStringGrid do
  begin
    if gdSelected in aState then
    begin
      Canvas.Brush.Color := $00FFE8CD;
      Canvas.Font.Color := clBlack;
    end;
  end;
end;

procedure TControlsEditorForm.InsertBtnClick(Sender: TObject);
begin
  IsEditing := false;
  EditControl('');
end;

procedure TControlsEditorForm.EditBtnClick(Sender: TObject);
begin
  with ControlsGrid do
  begin
    if RowCount = 1 then exit;
    IsEditing := true;
    EditControl(Cells[1,Row]);
  end;
end;

procedure TControlsEditorForm.DeleteBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  with ControlsGrid do
  begin
    if Row > 0 then
    begin
      Index := Row;
      DeleteRow(Row);
      if Index >= RowCount then Index := RowCount - 1;
      Row := Index;
      HasChanged := true;
    end;
  end;
  SetButtonStates;
end;

procedure TControlsEditorForm.UpBtnClick(Sender: TObject);
//
// Shared by both the UpBtn and DownBtn BitBtn components.
//
var
  I: Integer;
  K: Integer;
begin
  if (Sender as TBitBtn).Name = 'UpBtn' then
    K := -1
  else
    K := 1;
  with ControlsGrid do
  begin
    I := Row;
    if (K = -1)
    and (I <= 1) then exit;
    if (K = 1)
    and (I >= RowCount-1) then exit;
    MoveColRow(False, I, I + K);
    HasChanged := true;
  end;
end;

procedure TControlsEditorForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#simple_controls_editor');
end;

procedure TControlsEditorForm.IfBtnChange(Sender: TObject);
//
//  Changes the type of control being edited between a Level-Based
//  and Time-Based control.
//
begin
  LevelComboBox.Clear;
  LevelEdit.Clear;

  // IfBtn checked means we're editing a Level-Based control
  if IfBtn.Checked then
  begin
    NodeLabel.Visible := true;
    NodeEdit.Visible := true;
    NodeBtn.Visible := true;
    LevelComboBox.Items.AddCommaText(LevelTypeItems);
  end

  // Otherwise we're editing a Time-Based control
  else
  begin
    NodeLabel.Visible := false;
    NodeEdit.Visible := false;
    NodeBtn.Visible := false;
    LevelComboBox.Items.AddCommaText(TimeTypeItems);
  end;
  LevelComboBox.ItemIndex := 0;
end;

procedure TControlsEditorForm.SetButtonStates;
//
//  Changes the state of the buttons on the BtnPanel when the contents
//  of the ControlsGrid changes.
//
var
  State: Boolean;
begin
  State := ControlsGrid.RowCount > 1;
  DeleteBtn.Enabled := State;
  EditBtn.Enabled := State;
  State := ControlsGrid.RowCount > 2;
  UpBtn.Enabled := State;
  DownBtn.Enabled := State;
end;

procedure TControlsEditorForm.EditControl(const sControl: string);
begin
  TopPanel.Enabled := false;
  BottomBtnPanel.Enabled := false;
  SetControlProperties(sControl);
  EditorNotebook.PageIndex := 1;
end;

procedure TControlsEditorForm.ReplaceControl(NewControl: string);
var
  Index: Integer;
begin
  if Length(NewControl) = 0 then exit;
  Index := ControlsGrid.Row;
  if IsEditing then
    ControlsGrid.Cells[1, Index] := NewControl
  else
  begin
    Index := Index + 1;
    ControlsGrid.InsertRowWithValues(Index, ['1', NewControl]);
    ControlsGrid.Row := Index;
  end;
  HasChanged := true;
end;

procedure TControlsEditorForm.LoadControls;
//
//  Loads the project's set of Simple Controls into the ControlsGrid
//  when called by EditSimpleControls in the editor.pas unit.
//
var
  Ncontrols: Integer;
  I: Integer;
  ControlStr: string;
  UseControl: Integer;
begin
  // Find number of controls currently in the project
  EditorNotebook.PageIndex := 0;
  Ncontrols := 0;
  epanet2.ENgetcount(EN_CONTROLCOUNT, Ncontrols);

  // Add each control to the ControlsGrid
  ControlsGrid.RowCount := Ncontrols + 1;
  for I := 1 to Ncontrols do
  begin
    ControlStr := ControlToStr(I);
    UseControl := 1;
    epanet2.ENgetcontrolenabled(I, UseControl);
    ControlsGrid.Cells[0,I] := IntToStr(UseControl);
    ControlsGrid.Cells[1,I] := ControlStr;
  end;

  // Select the first control in the ControlsGrid
  if Ncontrols > 0 then ControlsGrid.Row := 1;
  SetButtonStates;
  HasChanged := false;
end;

function TControlsEditorForm.ControlToStr(const I: Integer): string;
//
//  Converts the contents of the project's I-th Simple Control into
//  a string.
//
var
  aType: Integer;
  aLink: Integer;
  aNode: Integer;
  aSetting: Single;
  aLevel: Single;
  sLink: string;
  sNode: string;
  sSetting: string;
  aTime: Integer;
  LinkType: Integer;
begin
  // Get the control's properties
  epanet2.ENgetcontrol(I, aType, aLink, aSetting, aNode, aLevel);

  // The controlled link's ID
  sLink := project.GetID(ctLinks, aLink);

  // The controlled link's setting
  epanet2.ENgetlinktype(aLink, LinkType);
  if aSetting = EN_SET_CLOSED then
    sSetting := 'CLOSED'
  else if aSetting = EN_SET_OPEN then
    sSetting := 'OPEN'
  else if (LinkType = EN_PIPE)
  or (LinkType = EN_PUMP) then
  begin
    if aSetting = 0 then
      sSetting := 'CLOSED'
    else if aSetting = 1 then
      sSetting := 'OPEN'
    else
      sSetting := utils.Float2Str(aSetting, 4); // Pump speed
  end
  else
    sSetting := utils.Float2Str(aSetting, 4); // Numerical valve setting

  // The link ID & its setting portion of the control string
  Result := 'LINK ' + sLink + ' ' + sSetting;

  // The conditional elements of the control added its string format
  case aType of
  EN_LOWLEVEL:
    begin
      sNode := project.GetID(ctNodes, aNode);
      Result := Result + ' IF NODE ' + sNode + ' BELOW ' + utils.Float2Str(aLevel, 4);
    end;
  EN_HILEVEL:
    begin
      sNode := project.GetID(ctNodes, aNode);
      Result := Result + ' IF NODE ' + sNode + ' ABOVE ' + utils.Float2Str(aLevel, 4);
    end;
  EN_TIMER:
    begin
      aTime := Round(aLevel);
      Result := Result + ' AT TIME ' + utils.Time2Str(aTime);
    end;
  EN_TIMEOFDAY:
    begin
      aTime := Round(aLevel);
      Result := Result + ' AT CLOCKTIME ' + utils.Time2Str(aTime);
    end;
  end;
end;

function TControlsEditorForm.StrToControl(const sControl: string;
  var aType: Integer; var aLink: Integer; var aNode: Integer;
  var aSetting: Single; var aLevel: Single): Boolean;
//
//  Parses the string representation of a control listed in the ControlsGrid
//  into its set of properties prior to adding it the project.
//
var
  sList: TStringList;
begin
  Result := true;
  sList := TStringList.Create;
  try
    sList.DelimitedText := sControl;
    if sList.Count >= 6 then
    begin
      aNode := 0;
      aLink := project.GetItemIndex(ctLinks, sList[1]);
      if aLink = 0 then Result := false;
      if SameText(sList[2], 'OPEN') then
        aSetting := EN_SET_OPEN
      else if SameText(sList[2], 'CLOSED') then
        aSetting := EN_SET_CLOSED
      else if not Str2Float(sList[2], aSetting) then
        Result := false;
      if SameText(sList[4], 'NODE') then
      begin
        aNode := project.GetItemIndex(ctNodes, sList[5]);
        if aNode = 0 then Result := false;
        if SameText(sList[6], 'BELOW') then
          aType := EN_LOWLEVEL
        else if SameText(sList[6], 'ABOVE') then
          aType := EN_HILEVEL
        else Result := false;
        if not Str2Float(sList[7], aLevel) then Result := false;
      end
      else if SameText(sList[4], 'Time') then
      begin
        aType := EN_TIMER;
        aLevel := utils.Str2Seconds(sList[5]);
      end
      else if SameText(sList[4], 'ClockTime') then
      begin
        aType := EN_TIMEOFDAY;
        aLevel := utils.Str2Seconds(sList[5]);
      end
      else
        Result := false;
    end
    else
      Result := false;
  finally
    sList.Free;
  end;
end;

procedure TControlsEditorForm.SetControlProperties(const aControl: string);
//
//  Takes the string representation of a control listed in the ControlsGrid
//  and loads it set of properties into the components in the EditPanel.
//
var
  aList: TStringList;
begin
  if Length(aControl) = 0 then
  begin
    ClearEditor;
    exit;
  end;
  aList := TStringList.Create;
  try
    aList.DelimitedText := aControl;
    LinkEdit.Text := aList[1];
    LinkComboBox.Text := aList[2];
    if SameText(aList[4], 'NODE') then
    begin
      NodeLabel.Visible := true;
      NodeEdit.Visible := true;
      IfBtn.Checked := true;
      LevelComboBox.Items.Clear;
      LevelComboBox.Items.AddCommaText(LevelTypeItems);
      NodeEdit.Text := aList[5];
      LevelComboBox.Text := aList[6];
      LevelEdit.Text := aList[7];
    end
    else
    begin
      NodeLabel.Visible := false;
      NodeEdit.Visible := false;
      AtBtn.Checked := true;
      LevelComboBox.Items.Clear;
      LevelComboBox.Items.AddCommaText(TimeTypeItems);
      if SameText(aList[4], 'TIME') then
        LevelComboBox.ItemIndex := 0
      else
        LevelComboBox.ItemIndex := 1;
      LevelEdit.Text := aList[5];
    end;
  finally
    aList.Free;
  end;
end;

function TControlsEditorForm.PropertiesToStr: string;
//
//  Converts the set of properties of a control being edited in
//  the EditPanel into its string representation.
//
begin
  Result := '';
  Result := 'LINK ' + LinkEdit.Text + ' ' + LinkComboBox.Text;
  if IfBtn.Checked then
    Result := Result + ' IF NODE ' + NodeEdit.Text + ' '
  else
    Result := Result + ' AT ';
  Result := Result + LevelComboBox.Text + ' ' + LevelEdit.Text;
end;

function TControlsEditorForm.ValidateControl: Boolean;
var
  X: Single = 0;
begin
  Result := false;
  if project.GetItemIndex(ctLinks, LinkEdit.Text) <= 0 then
  begin
    utils.MsgDlg(rsMissingData, Format(rsNoLink, [LinkEdit.Text]), mtError, [mbOK]);
    LinkEdit.SetFocus;
    exit;
  end;
  with LinkComboBox do
  begin
    if (ItemIndex = 2)
    and (utils.Str2Float(Text, X) = false) then
    begin
      utils.MsgDlg(rsInvalidData, rsBadSetting, mtError, [mbOK]);
      SetFocus;
      exit;
    end;
  end;

  if NodeEdit.Visible then
  begin
    if project.GetItemIndex(ctNodes, NodeEdit.Text) <= 0 then
    begin
      utils.MsgDlg(rsMissingData, Format(rsNoNode, [NodeEdit.Text]), mtError, [mbOK]);
      NodeEdit.SetFocus;
      exit;
    end;
    with LevelEdit do
    begin
      if (utils.Str2Float(Text, X) = false) then
      begin
        utils.MsgDlg(rsInvalidData, rsBadNodeLevel, mtError, [mbOK]);
        SetFocus;
        exit;
      end;
    end;
  end

  else with LevelEdit do
  begin
    if (utils.Str2Float(Text, X) = false) and (utils.Str2Seconds(Text) < 0) then
    begin
      utils.MsgDlg(rsInvalidData, rsBadTimeValue, mtError, [mbOK]);
      SetFocus;
      exit;
    end;
  end;
  Result := true;
end;

procedure TControlsEditorForm.ClearEditor;
begin
  LinkEdit.Text := '';
  LinkComboBox.ItemIndex := 0;
  IfBtn.Checked := true;
  NodeEdit.Text := '';
  LevelComboBox.ItemIndex := 0;
  LevelEdit.Text := '';
end;

end.

