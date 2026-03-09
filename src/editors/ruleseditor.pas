{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       ruleseditor
 Description:  a form that edits a project's rule-based controls
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit ruleseditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, StrUtils,
  lclIntf, LCLtype, Grids, ExtCtrls, Buttons;

type

  { TRulesEditorForm }

  TRulesEditorForm = class(TForm)
    TopPanel:       TPanel;
    EditorPanel:    TPanel;
    BottomPanel:    TPanel;
    BottomBtnPanel: TPanel;
    CommandPanel:   TPanel;
    AcceptPanel:    TPanel;
    RuleGrid:       TStringGrid;
    RuleMemo:       TMemo;
    InsertBtn:      TBitBtn;
    EditBtn:        TBitBtn;
    DeleteBtn:      TBitBtn;
    MoveDnBtn:      TBitBtn;
    MoveUpBtn:      TBitBtn;
    RuleFormatBtn:  TButton;
    AcceptEditsBtn: TButton;
    CancelEditsBtn: TButton;
    HelpBtn:        TButton;
    OkBtn:          TButton;
    CancelBtn:      TButton;

    procedure AcceptEditsBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure CancelEditsBtnClick(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure InsertBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure MoveDnBtnClick(Sender: TObject);
    procedure MoveUpBtnClick(Sender: TObject);
    procedure RuleFormatBtnClick(Sender: TObject);
    procedure RuleGridCheckboxToggled(Sender: TObject; aCol, aRow: Integer;
      aState: TCheckboxState);
    procedure RuleGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure RuleGridSelection(Sender: TObject; aCol, aRow: Integer);
    procedure OkBtnClick(Sender: TObject);
    procedure RuleMemoChange(Sender: TObject);

  private
    NewRules:        TStringList;
    OldRules:        TStringList;
    OldRulesEnabled: TStringList;
    EditAction:      Integer;
    RuleChanged:     Boolean;
    HasChanged:      Boolean;
    Shown:           Boolean;

    procedure GetObjectInfo(ObjIndex: Integer; ObjCode: Integer;
      var ObjType: Integer; var ObjID: string);
    function  GetRuleAsString(R: Integer): string;
    procedure GetPremises(R: Integer; N: Integer; var Rule: string);
    procedure GetActions(R: Integer; nThenActions: Integer; nElseActions: Integer;
      var Rule: string);
    function  GetAnAction(LinkIndex: Integer; Status: Integer; Setting: Single): string;
    procedure DeleteRules;
    function  ReplaceRules(var BadRuleIndex: Integer): Integer;
    procedure RestoreRules;
    procedure SetButtonStates;
    procedure ShowRule(I: Integer);
    function  GetRuleID(Rule: string): string;
    procedure EditRule(Rule: string);
    procedure ReplaceRule(Rule: string);
    procedure ClearEditorPanel;
    procedure ClearAll;

  public
    procedure LoadRules;
  end;

var
  RulesEditorForm: TRulesEditorForm;

implementation

{$R *.lfm}

uses
  main, project, config, utils, epanet2, resourcestrings;

const
  LogWord:  array[1..5] of string =
    ('IF    ', 'AND   ', 'OR    ', 'THEN  ', 'ELSE  ');
  VarWord: array[0..12] of string =
    ('DEMAND', 'HEAD', 'GRADE', 'LEVEL', 'PRESSURE', 'FLOW', 'STATUS',
     'SETTING', 'POWER', 'TIME', 'CLOCKTIME', 'FILLTIME', 'DRAINTIME');
  ObjWord: array[0..8] of string =
    ('JUNCTION', 'RESERVOIR', 'TANK', 'PIPE', 'PUMP', 'VALVE', 'NODE',
     'LINK', 'SYSTEM');
  RelWord: array[0..9] of string =
    ('=', '<>', '<=', '>=', '<', '>', 'IS', 'NOT', 'BELOW', 'ABOVE');
  StatusWord: array[1..3] of string =
    ('OPEN', 'CLOSED', 'ACTIVE');

  Editing = 1;
  Inserting = 2;

{ TRulesEditorForm }

procedure TRulesEditorForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  RuleGrid.Font.Name := config.MonoFont;
  RuleMemo.Font.Name := config.MonoFont;
  NewRules := TStringList.Create;
  OldRules := TStringList.Create;
  OldRulesEnabled := TStringList.Create;
  ClearEditorPanel;
  Shown := false;
end;

procedure TRulesEditorForm.FormDestroy(Sender: TObject);
begin
  NewRules.Free;
  OldRules.Free;
  OldRulesEnabled.Free;
end;

procedure TRulesEditorForm.FormShow(Sender: TObject);
var
  Location: TPoint;
begin
  Color := config.ThemeColor;
  RuleGrid.FixedColor := Color;
  if not Shown then
  begin
    Location := MainForm.LeftPanel.ClientOrigin;
    Left := Location.X;
    Top := Location.Y;
    Shown := true;
  end;
  if RuleGrid.RowCount > 1 then
  begin
    RuleGrid.Row := 1;
    ShowRule(0);
  end;
  RuleGrid.SetFocus;
end;

procedure TRulesEditorForm.OkBtnClick(Sender: TObject);
var
  Err: Integer = 0;
  BadRuleIndex: Integer = 0;
  ErrMsg: string = '';
begin
  if HasChanged then Err := ReplaceRules(BadRuleIndex);
  if Err = 0 then
  begin
    if HasChanged then
    begin
      project.HasChanged := true;
      project.UpdateResultsStatus;
    end;
    ClearAll;
  end
  else
  begin
    ErrMsg := Format(rsRuleError, [Err, RuleGrid.Cells[1,BadRuleIndex]]);
    utils.MsgDlg(rsInvalidData, ErrMsg, mtError, [mbOK], self);
    RestoreRules;
  end;
end;

procedure TRulesEditorForm.RuleMemoChange(Sender: TObject);
begin
  RuleChanged := true;
end;

procedure TRulesEditorForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#rule_based_controls_editor');
end;

procedure TRulesEditorForm.SetButtonStates;
var
  Status: Boolean;
begin
  Status := true;
  if RuleGrid.RowCount = 1 then Status := false;
  EditBtn.Enabled := Status;
  DeleteBtn.Enabled := Status;
  MoveUpBtn.Enabled := Status;
  MoveDnBtn.Enabled := Status;
  if RuleGrid.Row = 1 then MoveUpBtn.Enabled := false;
  if RuleGrid.Row >= RuleGrid.RowCount-1 then MoveDnBtn.Enabled := false;
end;

procedure TRulesEditorForm.InsertBtnClick(Sender: TObject);
begin
  EditAction := Inserting;
  EditRule('');
end;

procedure TRulesEditorForm.EditBtnClick(Sender: TObject);
begin
  EditAction := Editing;
  EditRule(RuleMemo.Text);
end;

procedure TRulesEditorForm.MoveDnBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  HasChanged := true;
  Index := RuleGrid.Row;
  RuleGrid.MoveColRow(false, Index, Index + 1);
  NewRules.Exchange(Index - 1, Index);
  RuleGrid.Row := Index + 1;
  ShowRule(Index);
  RuleGrid.SetFocus;
end;

procedure TRulesEditorForm.MoveUpBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  HasChanged := true;
  Index := RuleGrid.Row - 1;
  RuleGrid.MoveColRow(false, Index, Index + 1);
  NewRules.Exchange(Index - 1, Index);
  RuleGrid.Row := Index;
  ShowRule(Index - 1);
  RuleGrid.SetFocus;
end;

procedure TRulesEditorForm.RuleFormatBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#rule_format');
end;

procedure TRulesEditorForm.RuleGridCheckboxToggled(Sender: TObject; aCol,
  aRow: Integer; aState: TCheckboxState);
begin
  HasChanged := true;
end;

procedure TRulesEditorForm.DeleteBtnClick(Sender: TObject);
var
  Index: Integer;
begin
  HasChanged := true;
  Index := RuleGrid.Row;
  if Index = 0 then exit;
  RuleGrid.DeleteRow(Index);
  NewRules.Delete(Index - 1);
  Index := RuleGrid.Row;
  ShowRule(Index - 1);
  SetButtonStates;
  RuleGrid.SetFocus;
end;

procedure TRulesEditorForm.AcceptEditsBtnClick(Sender: TObject);
var
  Rule: string;
begin
  Rule := RuleMemo.Text;
  if Length(GetRuleID(Rule)) = 0 then
  begin
    utils.MsgDlg(rsMissingID, rsNoIDAssigned, mtError, [mbOK], self);
    exit;
  end;
  ClearEditorPanel;
  if RuleChanged then ReplaceRule(Rule);
  RuleGrid.SetFocus;
end;

procedure TRulesEditorForm.CancelBtnClick(Sender: TObject);
begin
  ClearAll;
end;

procedure TRulesEditorForm.CancelEditsBtnClick(Sender: TObject);
begin
  ClearEditorPanel;
  ShowRule(RuleGrid.Row-1);
  RuleGrid.SetFocus;
end;

procedure TRulesEditorForm.ClearEditorPanel;
begin
  TopPanel.Enabled := true;
  AcceptPanel.Visible := false;
  RuleMemo.ReadOnly := true;
  RuleMemo.Color:= clInfoBk;
  BottomBtnPanel.Enabled := true;
end;

procedure TRulesEditorForm.ClearAll;
begin
  NewRules.Clear;
  OldRules.Clear;
  OldRulesEnabled.Clear;
  RuleGrid.Clear;
  RuleMemo.Clear;
  Visible := false;
  MainForm.EnableMainForm(true);
end;

procedure TRulesEditorForm.EditRule(Rule: string);
begin
  TopPanel.Enabled := false;
  BottomBtnPanel.Enabled := false;
  AcceptPanel.Visible := true;
  RuleMemo.ReadOnly := false;
  RuleMemo.Color:= clWindow;
  if Length(Rule) = 0 then
  begin
    RuleMemo.Clear;
    RuleMemo.Lines.Add('RULE  ');
    RuleMemo.Lines.Add('IF    ');
    RuleMemo.Lines.Add('THEN  ');
  end;
  RuleMemo.SelStart := 6;
  RuleChanged := false;
  RuleMemo.SetFocus;
end;

procedure TRulesEditorForm.ReplaceRule(Rule: string);
var
  Index: Integer;
begin
 Index := RuleGrid.Row;
 if EditAction = Editing then
  begin
    NewRules[Index - 1] := Rule;
    RuleGrid.Cells[1, Index] := GetRuleID(Rule);
  end;
  if EditAction = Inserting then
  begin
    Index := RuleGrid.Row + 1;
    NewRules.Insert(Index - 1, Rule);
    RuleGrid.InsertRowWithValues(Index, ['1', GetRuleID(Rule)]);
    RuleGrid.Row := Index;
  end;
  ShowRule(Index - 1);
  HasChanged := true;
  SetButtonStates;
end;

procedure TRulesEditorForm.RuleGridPrepareCanvas(Sender: TObject; aCol,
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

procedure TRulesEditorForm.RuleGridSelection(Sender: TObject; aCol,
  aRow: Integer);
const
  OldRow: Integer = 0;
begin
  if (aRow <> OldRow)
  and (aRow >= 1) then
  begin
    OldRow := aRow;
    ShowRule(aRow - 1);
  end;
end;

procedure TRulesEditorForm.GetObjectInfo(ObjIndex: Integer; ObjCode: Integer;
      var ObjType: Integer; var ObjID: string);
begin
  ObjID := '';
  if ObjCode = EN_R_NODE then
  begin
    epanet2.ENgetnodetype(ObjIndex, ObjType);
    ObjID := project.GetID(ctNodes, ObjIndex);
  end
  else if ObjCode = EN_R_LINK then
  begin
    epanet2.ENgetlinktype(ObjIndex, ObjType);
    if ObjType < EN_PIPE then
      ObjType := EN_PIPE
    else if ObjType > EN_PUMP then
      ObjType := EN_PUMP + 1;
    ObjType := EN_TANK + ObjType;
    ObjID := project.GetID(ctLinks, ObjIndex);
  end
  else
    ObjType := 8;
end;

procedure TRulesEditorForm.LoadRules;
var
  nRules: Integer;
  R: Integer;
  ID: array[0..EN_MAXID+1] of AnsiChar = '';
  Rule: string;
  EnabledCode: Integer = 1;
begin
  nRules := 0;
  epanet2.ENgetcount(EN_RULECOUNT, nRules);
  RuleGrid.RowCount := nRules + 1;
  for R := 1 to nRules do
  begin
    epanet2.ENgetruleID(R, ID);
    RuleGrid.Cells[1,R] := ID;
    epanet2.ENgetruleenabled(R, EnabledCode);
    RuleGrid.Cells[0,R] := IntToStr(EnabledCode);
    Rule := GetRuleAsString(R);
    NewRules.Add(Rule);
    OldRules.Add(Rule);
    OldRulesEnabled.Add(RuleGrid.Cells[0,R]);
  end;
  if nRules > 0 then ShowRule(0);
  SetButtonStates;
  HasChanged := false;
end;

procedure TRulesEditorForm.ShowRule(I: Integer);
var
  Rule: string;
begin
  RuleMemo.Clear;
  if I < 0 then exit;
  Rule := NewRules[I];
  RuleMemo.Text := Rule;
  SetButtonStates;
end;

function TRulesEditorForm.GetRuleAsString(R: Integer): string;
var
  nPremises: Integer = 0;
  nThenActions: Integer = 0;
  nElseActions: Integer = 0;
  priority: Single = 0;
  id: array[0..EN_MAXID+1] of AnsiChar = '';
  Rule: string;
begin
  Rule := 'Rule  ';
  epanet2.ENgetruleID(R, id);
  Rule := Rule + id;
  epanet2.ENgetrule(R, nPremises, nThenActions, nElseActions, priority);
  GetPremises(R, nPremises, Rule);
  GetActions(R, nThenActions, nElseActions, Rule);
  if priority > 0 then
    Rule := Rule + sLineBreak + Format('Priority %0.0f', [priority]);
  Result := Rule;
end;

function TRulesEditorForm.GetRuleID(Rule: string): string;
var
  RuleList: TStringList;
begin
  RuleList := TStringList.Create;
  try
    RuleList.Text := Trim(Rule);
    Result := RuleList[0];
    Result := Trim(StringReplace(Result, 'RULE', '', [rfIgnoreCase]));
  finally
    RuleList.Free;
  end;
end;

procedure TRulesEditorForm.GetPremises(R: Integer; N: Integer; var Rule: string);
var
  line: string;
  p: Integer;
  logop: Integer = 0;
  objCode: Integer = 0;
  objType: Integer = 0;
  objIndex: Integer = 0;
  objID: string;
  varCode: Integer = 0;
  relop: Integer = 0;
  status: Integer = 0;
  setting: Single = 0;
begin
  objID := '';
  for p := 1 to N do
  begin
    epanet2.ENgetpremise(R, p, logop, objCode, objIndex, varCode, relop,
      status, setting);
    if p = 1 then logop := 1;
    line := LogWord[logop];
    GetObjectInfo(objIndex, objCode, objType, objID);
    line := line + ObjWord[objType] + ' ' + objID + ' ' + VarWord[varCode] +
            ' ' + RelWord[relop] + ' ';
    if setting <= EN_MISSING then
      line := line + StatusWord[status]
    else
      line := line + Format('%0.4f', [setting]);
    Rule := Rule + sLineBreak + line;
  end;
end;

procedure TRulesEditorForm.GetActions(R: Integer; nThenActions: Integer;
  nElseActions: Integer; var Rule: string);
var
  i: Integer;
  linkIndex: Integer = 0;
  status: Integer = 0;
  setting: Single = 0;
  line: string;
begin
  for i := 1 to nThenActions do
  begin
    epanet2.ENgetthenaction(R, i, linkIndex, status, setting);
    if i = 1 then
      line := 'THEN  '
    else
      line := 'AND   ';
    line := line + GetAnAction(linkIndex, status, setting);
    Rule := Rule + sLineBreak + line;
  end;
  for i := 1 to nElseActions do
  begin
    epanet2.ENgetelseaction(R, i, linkIndex, status, setting);
    if i = 1 then line := 'ELSE  ' else line := 'AND   ';
    line := line + GetAnAction(linkIndex, status, setting);
    Rule := Rule + sLineBreak + line;
  end;
end;

function TRulesEditorForm.GetAnAction(LinkIndex: Integer; Status: Integer;
  Setting: Single): string;
var
  objType: Integer = 0;
  objID: string;
begin
  Result := '';
  epanet2.ENgetlinktype(linkIndex, objType);
  if objType < EN_PIPE then
    objType := EN_PIPE
  else if objType > EN_PUMP then
    objType := EN_PUMP + 1;
  objType := EN_TANK + objType;
  objID := project.GetID(ctLinks, linkIndex);
  Result := Result + ObjWord[objType] + ' ' + objID;
  if setting <= EN_MISSING then
    Result := Result + ' STATUS = ' + StatusWord[status]
  else
    Result := Result + Format(' SETTING = %0.4f', [setting]);
end;

procedure TRulesEditorForm.DeleteRules;
var
  nRules: Integer;
  R: Integer;
begin
  nRules := 0;
  epanet2.ENgetcount(EN_RULECOUNT, nRules);
  for R := nRules downto 1 do epanet2.ENdeleterule(R);
end;

function TRulesEditorForm.ReplaceRules(var BadRuleIndex: Integer): Integer;
var
  I: Integer;
  N: Integer;
  Rule: string;
begin
  Result := 0;
  DeleteRules;
  Rule := '';
  BadRuleIndex := 0;
  N := NewRules.Count;
  for I := 1 to N do
  begin
    Rule := NewRules[I-1];
    Result := epanet2.ENaddrule(PAnsiChar(Rule));
    if Result > 0 then
    begin
      BadRuleIndex := I;
      exit;
    end;
    if SameText(RuleGrid.Cells[0,I], '0') then
      epanet2.ENsetruleenabled(I, 0);
  end;
end;

procedure TRulesEditorForm.RestoreRules;
var
  I: Integer;
  N: Integer;
  Rule: string;
begin
  DeleteRules;
  N := OldRules.Count;
  for I := 0 to N-1 do
  begin
    Rule := OldRules[I];
    epanet2.ENaddrule(PAnsiChar(Rule));
    if SameText(OldRulesEnabled[I], '0') then
      epanet2.ENsetruleenabled(I+1, 0);
  end;
end;

end.
