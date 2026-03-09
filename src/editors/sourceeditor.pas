{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       sourceeditor
 Description:  a dialog form that edits a Water Quality source
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit sourceeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  lclIntf, EditBtn, SpinEx;

type

  { TSourceEditorForm }

  TSourceEditorForm = class(TForm)
    CancelBtn:       TButton;
    HelpBtn:         TButton;
    Label1:          TLabel;
    Label2:          TLabel;
    Label3:          TLabel;
    OkBtn:           TButton;
    Panel1:          TPanel;
    Panel2:          TPanel;
    PatternEdit:     TEditButton;
    SourceTypeCombo: TComboBox;
    StrengthEdit:    TFloatSpinEditEx;

    procedure PatternEditButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure PatternComboChange(Sender: TObject);
    procedure StrengthEditChange(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
  private
    NodeIndex: Integer;
  public
    HasChanged: Boolean;
    procedure LoadSource(const Index: Integer);
    function  GetSourceStrength: string;
  end;

var
  SourceEditorForm: TSourceEditorForm;

implementation

{$R *.lfm}

uses
  main, project, utils, config, patterneditor, epanet2, resourcestrings;

procedure TSourceEditorForm.FormCreate(Sender: TObject);
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
end;

procedure TSourceEditorForm.OkBtnClick(Sender: TObject);
var
  T: Integer;
  P: Integer;
  V: Single;
  Pattern: string;
begin
  Pattern := Trim(PatternEdit.Text);
  if Length(Pattern) = 0 then
    P := 0
  else
  begin
    P := project.GetItemIndex(ctPatterns, Pattern);
    if P = 0 then
    begin
      utils.MsgDlg(rsMissingData, Format(rsNoPattern, [Pattern]), mtError, [mbOK]);
      PatternEdit.SetFocus;
      exit;
    end;
  end;

  T := SourceTypeCombo.ItemIndex;
  V := StrengthEdit.Value;
  epanet2.ENsetnodevalue(NodeIndex, EN_SOURCETYPE, T);
  epanet2.ENsetnodevalue(NodeIndex, EN_SOURCEQUAL, V);
  epanet2.ENsetnodevalue(NodeIndex, EN_SOURCEPAT, P);
  ModalResult := mrOK;
end;


procedure TSourceEditorForm.PatternEditButtonClick(Sender: TObject);
var
  S: string;
begin
  S := PatternEdit.Text;
  with TPatternEditorForm.Create(self) do
  try
    Setup(S);
    ShowModal;
    if ModalResult = mrOK then
      PatternEdit.Text := SelectedName;
  finally
    Free;
  end;
end;

procedure TSourceEditorForm.PatternComboChange(Sender: TObject);
begin
  HasChanged := true;
end;

procedure TSourceEditorForm.StrengthEditChange(Sender: TObject);
begin
  HasChanged := true;
end;

procedure TSourceEditorForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#source_quality');
end;

procedure TSourceEditorForm.LoadSource(const Index: Integer);
var
  V: Single = 0;
begin
  NodeIndex := Index;
  SourceTypeCombo.ItemIndex := 0;
  if epanet2.ENgetnodevalue(Index, EN_SOURCETYPE, V) = 0 then
  begin
    SourceTypeCombo.ItemIndex := Round(V);
    epanet2.ENgetnodevalue(Index, EN_SOURCEQUAL, V);
    StrengthEdit.Value := V;
    epanet2.ENgetnodevalue(Index, EN_SOURCEPAT, V);
    PatternEdit.Text := project.GetID(ctPatterns, Round(V));
  end;
  HasChanged := false;
end;

function TSourceEditorForm.GetSourceStrength: string;
begin
  Result := utils.Float2Str(StrengthEdit.Value, 4);
end;

end.

