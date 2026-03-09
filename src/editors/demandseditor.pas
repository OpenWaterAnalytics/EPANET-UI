{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       demandseditor
 Description:  a dialog form that edits multiple demands at a node
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit demandseditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, StdCtrls, Math,
  lclIntf, ExtCtrls;

const
  MaxDemands = 10;

type

  { TDemandsEditorForm }

  TDemandsEditorForm = class(TForm)
    DemandsGrid: TStringGrid;
    OkBtn:       TButton;
    CancelBtn:   TButton;
    HelpBtn:     TButton;
    Panel1:      TPanel;

    procedure OkBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure DemandsGridButtonClick(Sender: TObject; aCol, aRow: Integer);
    procedure DemandsGridKeyPress(Sender: TObject; var Key: char);
    procedure DemandsGridSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
  private
    NodeIndex:     Integer;
    NumDemands:    Integer;
    NewNumDemands: Integer;
    Demands:       array[1..MaxDemands] of Single;
    Patterns:      array[1..MaxDemands] of string;
    Categories:    array[1..MaxDemands] of string;

    function UnloadDemands: Boolean;
    procedure SaveDemands;
    procedure ShowError(Msg: string; R: Integer; C: Integer);

  public
    HasChanged: Boolean;
    procedure LoadDemands(const Index: Integer);
    procedure GetPrimaryDemandInfo(var PrimaryDemand: string;
      var PrimaryPattern: string; var DemandCount: string);

  end;

var
  DemandsEditorForm: TDemandsEditorForm;

implementation

{$R *.lfm}

uses
  main, project, config, patterneditor, utils, epanet2, resourcestrings;

{ TDemandsEditorForm }

procedure TDemandsEditorForm.FormCreate(Sender: TObject);
begin
  Color := Config.ThemeColor;
  DemandsGrid.FixedColor := Color;
  Font.Size := Config.FontSize;
end;

procedure TDemandsEditorForm.OkBtnClick(Sender: TObject);
begin
  if UnloadDemands then
  begin
    SaveDemands;
    ModalResult := mrOK;
  end;
end;

procedure TDemandsEditorForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#demand_categories');
end;

procedure TDemandsEditorForm.DemandsGridButtonClick(Sender: TObject; aCol,
  aRow: Integer);
var
  OldPattern: string;
  NewPattern: string;
  PatternEditor: TPatternEditorForm;
begin
  with DemandsGrid do
    OldPattern := Cells[aCol, Row];
  NewPattern := OldPattern;
  PatternEditor := TPatternEditorForm.Create(Self);
  try
    PatternEditor.Setup(OldPattern);
    PatternEditor.ShowModal;
    if PatternEditor.ModalResult = mrOK then
      NewPattern := PatternEditor.SelectedName;
  finally
     PatternEditor.Free;
  end;
  if not SameText(NewPattern, OldPattern) then
  begin
    DemandsGrid.Cells[aCol,aRow] := NewPattern;
    HasChanged := true;
  end;
end;

procedure TDemandsEditorForm.DemandsGridKeyPress(Sender: TObject; var Key: char
  );
begin
  if DemandsGrid.Col = 2 then Key := #0;
end;

procedure TDemandsEditorForm.DemandsGridSetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: string);
begin
  HasChanged := true;
end;

procedure TDemandsEditorForm.LoadDemands(const Index: Integer);
var
  I: Integer;
  N: Integer;
  D: Single = 0;
  P: Integer = 0;
  C: array[0..EN_MAXID+1] of AnsiChar = '';
begin
  Caption := rsDemandCategories + project.GetID(ctNodes, Index);
  NodeIndex := Index;
  epanet2.ENgetnumdemands(NodeIndex, NumDemands);
  N := Min(NumDemands, MaxDemands);
  for I := 1 to N do
  begin
    epanet2.ENgetbasedemand(NodeIndex, I, D);
    DemandsGrid.Cells[1,I] := utils.Float2Str(D, 4);
    epanet2.ENgetdemandpattern(NodeIndex, I, P);
    DemandsGrid.Cells[2,I] := project.GetID(ctPatterns, P);
    epanet2.ENgetdemandname(NodeIndex, I, C);
    DemandsGrid.Cells[3,I] := C;
  end;
  HasChanged := false;
end;

function TDemandsEditorForm.UnloadDemands: Boolean;
var
  I: Integer;
  D: Single = 0;
  P: Integer;
  S1: string;
  S2: string;
  S3: string;
begin
  Result := false;
  NewNumDemands := 0;
  with DemandsGrid do
  begin
    for I := 1 to MaxDemands do
    begin
      // Skip blank row
      S1 := Trim(Cells[1,I]);
      S2 := Trim(Cells[2,I]);
      S3 := Trim(Cells[3,I]);
      if  (S1.Length = 0)
      and (S2.Length = 0)
      and (S3.Length = 0) then continue;

      // Retrieve base demand value
      if S1.Length = 0 then
        D := 0
      else if not Utils.Str2Float(S1, D) then
      begin
        ShowError(rsInvalidDemand + IntToStr(I), I, 1);
        Exit;
      end;

      // Check for valid pattern
      if S2.Length > 0 then
      begin
        P := project.GetItemIndex(ctPatterns, S2);
        if P = 0 then
        begin
          ShowError(rsInvalidPattern + IntToStr(I), I, 2);
          exit;
        end;
      end;

      // Add row to list of demands
      Inc(NewNumDemands);
      Demands[NewNumDemands] := D;
      Patterns[NewNumDemands] := S2;
      Categories[NewNumDemands] := S3;
    end;
  end;

  // If grid is empty add a zero demand to the list
  if NewNumDemands = 0 then
  begin
    NewNumDemands := 1;
    Demands[1] := 0;
    Patterns[1] := '';
    Categories[1] := '';
  end;
  Result := true;
end;

procedure TDemandsEditorForm.SaveDemands;
var
  I: Integer;
begin
  // Delete existing demands (keep removing the topmost one)
  for I := 1 to NumDemands do
    epanet2.ENdeletedemand(NodeIndex, 1);

  // Add each new demand to the project's data base
  for I := 1 to NewNumDemands do
    epanet2.ENadddemand(NodeIndex, Demands[I], PAnsiChar(Patterns[I]),
      PAnsiChar(Categories[I]));
end;

procedure TDemandsEditorForm.GetPrimaryDemandInfo(var PrimaryDemand: String;
          var PrimaryPattern: string; var DemandCount: string);
var
  N: Integer = 0;
  D1: Single = 0;
  P1: Integer = 0;
begin
  epanet2.ENgetbasedemand(NodeIndex, 1, D1);
  PrimaryDemand := utils.Float2Str(D1, 4);
  epanet2.ENgetdemandpattern(NodeIndex, 1, P1);
  PrimaryPattern := project.GetID(ctPatterns, P1);
  epanet2.ENgetnumdemands(NodeIndex, N);
  DemandCount := IntToStr(N);
end;

procedure TDemandsEditorForm.ShowError(Msg: String; R: Integer; C: Integer);
begin
  with DemandsGrid do
  begin
    Row := R;
    Col := C;
    utils.MsgDlg(rsInvalidData, Msg, mtError, [mbOK]);
    SetFocus;
  end;
end;

end.

