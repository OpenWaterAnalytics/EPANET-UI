{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       qualeditor
 Description:  a dialog form that edits single species Water
               Quality options
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit qualeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  LCLIntf, SpinEx;

type

  { TQualEditorForm }

  TQualEditorForm = class(TForm)
    QualTolEdit:         TFloatSpinEditEx;
    BulkOrderEdit:       TFloatSpinEditEx;
    ConcenLimitEdit:     TFloatSpinEditEx;
    DiffusEdit:          TFloatSpinEditEx;
    TankOrderEdit:       TFloatSpinEditEx;
    QualNameEdit:        TEdit;
    Label1:              TLabel;
    Label10:             TLabel;
    Label2:              TLabel;
    Label3:              TLabel;
    Label4:              TLabel;
    Label5:              TLabel;
    Label7:              TLabel;
    Label8:              TLabel;
    Label9:              TLabel;
    UnitsLabel:          TLabel;
    OkBtn:               TButton;
    CancelBtn:           TButton;
    HelpBtn:             TButton;
    MainPanel:           TPanel;
    ChemOptionsPanel:    TPanel;
    GeneralOptionsPanel: TPanel;
    BtnPanel:            TPanel;
    QualTypeCombo:       TComboBox;
    UnitsCombo:          TComboBox;
    WallOrderCombo:      TComboBox;

    procedure QualNameEditChange(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure QualTypeComboChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    function EntriesAreValid: Boolean;
    procedure SetQualOptions;

  public
    HasChanged: Boolean;

  end;

var
  QualEditorForm: TQualEditorForm;

implementation

{$R *.lfm}

uses
  main, project, utils, config, epanet2, resourcestrings;

const
  ChemHint: string = rsChemHint;
  TraceHint: string = rsTraceHint;

var
  QualType:       Integer;
  TraceNodeIndex: Integer = 0;
  ChemName:       array[0..EN_MAXID] of AnsiChar;
  QualUnits:      array[0..EN_MAXID] of AnsiChar;
  QualTraceNode:  array[0..EN_MAXID] of AnsiChar;

{ TQualEditorForm }

procedure TQualEditorForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
  for I := 0 to High(project.QualModelStr) do
    QualTypeCombo.Items.Add(project.QualModelStr[I]);
  QualNameEdit.MaxLength := EN_MAXID;
  UnitsLabel.Left := UnitsCombo.Left;
  UnitsLabel.Top := Label4.Top;
end;

procedure TQualEditorForm.FormShow(Sender: TObject);
var
  I: Integer;
  X: Single = 0;
begin
  epanet2.ENgetqualinfo(QualType, ChemName, QualUnits, TraceNodeIndex);
  QualTypeCombo.ItemIndex := QualType;
  if QualType = Project.qtChem then
  begin
    QualNameEdit.Text := ChemName;
  end
  else
    ChemName := '';
  QualTraceNode := '';
  if TraceNodeIndex > 0 then
    epanet2.ENgetnodeID(TraceNodeIndex, QualTraceNode);
  epanet2.ENgetoption(EN_TOLERANCE, X);
  QualTolEdit.Value := X;
  epanet2.ENgetoption(EN_BULKORDER, X);
  BulkOrderEdit.Value := X;
  epanet2.ENgetoption(EN_TANKORDER, X);
  TankOrderEdit.Value := X;
  epanet2.ENgetoption(EN_WALLORDER, X);
  I := Round(X);
  WallOrderCombo.ItemIndex := I;
  epanet2.ENgetoption(EN_CONCENLIMIT, X);
  ConcenLimitEdit.Value := X;
  epanet2.ENgetoption(EN_SP_DIFFUS, X);
  DiffusEdit.Value := X;
  QualTypeComboChange(Sender);
  QualTypeCombo.SetFocus;
  HasChanged := false;
end;

procedure TQualEditorForm.OkBtnClick(Sender: TObject);
begin
  if EntriesAreValid then
  begin
    SetQualOptions;
    ModalResult := mrOk;
  end;
end;

procedure TQualEditorForm.QualNameEditChange(Sender: TObject);
//
// OnChange handler shared by all edit controls
//
begin
  HasChanged := true;
end;

procedure TQualEditorForm.QualTypeComboChange(Sender: TObject);
begin
  Label2.Caption := rsConstitName;
  Label2.Hint := '';
  QualNameEdit.Enabled := false;
  QualTolEdit.Enabled := true;
  if QualTypeCombo.ItemIndex = qtChem then
  begin
    ChemOptionsPanel.Visible := true;
    UnitsLabel.Visible := false;
    UnitsCombo.Visible := true;
  end
  else
  begin
    ChemOptionsPanel.Visible := false;
    UnitsLabel.Visible := true;
    UnitsCombo.Visible := false;
  end;
  case QualTypeCombo.ItemIndex of
    qtNone:
      begin
        QualNameEdit.Text := '';
        QualTolEdit.Enabled := False;
        UnitsLabel.Caption := '';
      end;
    qtChem:
      begin
        QualNameEdit.Text := ChemName;
        QualNameEdit.Enabled := True;
        Label2.Hint := ChemHint;
       end;
    qtAge:
      begin
        QualNameEdit.Text := rsAge;
        UnitsLabel.Caption := rsHours;
      end;
    qtTrace:
      begin
        Label2.Caption := rsTraceFrom;
        Label2.Hint := TraceHint;
        QualNameEdit.Enabled := True;
        QualNameEdit.Text := QualTraceNode;
        UnitsLabel.Caption := rsPercent;
      end;
  end;
  HasChanged := true;
end;

function TQualEditorForm.EntriesAreValid: Boolean;
begin
  Result := false;
  QualType := QualTypeCombo.ItemIndex;

  QualTraceNode := '';
  if QualType = qtTrace then
  begin
    QualTraceNode := QualNameEdit.Text;
    if epanet2.ENgetnodeindex(QualTraceNode, TraceNodeIndex) > 0 then
    begin
      utils.MsgDlg(rsMissingData, rsNoTraceNode, mtError, [mbOK]);
      QualNameEdit.SetFocus;
      exit;
    end;
  end;
  Result := true;
end;

procedure TQualEditorForm.SetQualOptions;
var
  X: Single;
  ChemStr: string;
begin
  ChemStr := '';
  QualUnits := '';
  if QualType = qtChem then
  begin
    ChemStr := Trim(QualNameEdit.Text);
    if Length(ChemStr) = 0 then ChemStr := rsChemical;
    QualUnits := UnitsCombo.Text;
  end;
  if epanet2.ENsetqualtype(QualType, PChar(ChemStr), PChar(QualUnits),
    PChar(QualTraceNode)) > 0 then
  begin
    utils.MsgDlg(rsInvalidSelect, rsNoQualOptions, mtInformation, [mbOk]);
    exit;
  end;
  X := QualTolEdit.Value;
  epanet2.ENsetoption(EN_TOLERANCE, X);
  if QualType = qtChem then
  begin
    X := BulkOrderEdit.Value;
    epanet2.ENsetoption(EN_BULKORDER, X);
    X := TankOrderEdit.Value;
    epanet2.ENsetoption(EN_TANKORDER, X);
    X := WallOrderCombo.ItemIndex;
    epanet2.ENsetoption(EN_WALLORDER, X);
    X := ConcenLimitEdit.Value;
    epanet2.ENsetoption(EN_CONCENLIMIT, X);
    X := DiffusEdit.Value;
    epanet2.ENsetoption(EN_SP_DIFFUS, X);
  end;
end;

procedure TQualEditorForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#single_species_quality');
end;

end.

