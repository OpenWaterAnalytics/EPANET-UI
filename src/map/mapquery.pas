{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mapquery
 Description:  a frame that locates network objects that meet a
               specific criterion.
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
unit mapquery;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, ExtCtrls, Graphics,
  LCLtype, Dialogs;

type

  { TMapQueryFrame }

  TMapQueryFrame = class(TFrame)
    CloseBtn:     TSpeedButton;
    FindCbx:      TComboBox;
    ParamCbx:     TComboBox;
    ConditionCbx: TComboBox;
    ValueEdit:    TEdit;
    Label1:       TLabel;
    Label2:       TLabel;
    ResultPanel:  TPanel;
    TopPanel:     TPanel;

    procedure CloseBtnClick(Sender: TObject);
    procedure FindCbxChange(Sender: TObject);
    procedure ValueEditChange(Sender: TObject);
    procedure ValueEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    Target:        Single;
    FilteredCount: Integer;
    function IsFiltered(const Value: Single): Boolean;

  public
    NodeQuery: Boolean;
    LinkQuery: Boolean;
    procedure Init;
    procedure Show;
    procedure Hide;
    procedure UpdateResults;
    function GetFilteredNodeColor(const NodeIndex: Integer): TColor;
    function GetFilteredLinkColor(const LinkIndex: Integer): TColor;
  end;

implementation

{$R *.lfm}

uses
  main, project, mapframe, mapthemes, config, utils, resourcestrings;

{ TMapQueryFrame }

procedure TMapQueryFrame.Init;
begin
  FindCbx.ItemIndex := 0;
  ParamCbx.ItemIndex := 0;
  NodeQuery := true;
  LinkQuery := false;
end;

procedure TMapQueryFrame.Show;
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  ValueEdit.Text := '';
  ResultPanel.Caption := '';
  NodeQuery := false;
  LinkQuery := false;
  FindCbxChange(self);
  Visible := true;
end;

procedure TMapQueryFrame.Hide;
begin
  Visible := false;
end;

procedure TMapQueryFrame.CloseBtnClick(Sender: TObject);
begin
  Hide;
  NodeQuery := false;
  LinkQuery := false;
  MainForm.MapFrame.RedrawMap;
end;

procedure TMapQueryFrame.FindCbxChange(Sender: TObject);
var
  I, N: Integer;
  MainViewCombo: TComboBox;
begin
  ParamCbx.Clear;
  if FindCbx.ItemIndex = 0 then
  begin
    NodeQuery := true;
    LinkQuery := false;
    MainViewCombo := MainForm.MainMenuFrame.ViewNodeCombo;
  end
  else
  begin
    NodeQuery := false;
    LinkQuery := true;
    MainViewCombo := MainForm.MainMenuFrame.ViewLinkCombo;
  end;
  N := MainViewCombo.Items.Count;
  for I := 1 to N-1 do
    ParamCbx.Items.Add(MainViewCombo.Items[I]);
  I := MainViewCombo.ItemIndex - 1;
  if I < 0 then I := 0;
  ParamCbx.ItemIndex := I;
end;

procedure TMapQueryFrame.ValueEditChange(Sender: TObject);
begin
  ResultPanel.Caption := '';
end;

procedure TMapQueryFrame.ValueEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then UpdateResults;
end;

procedure TMapQueryFrame.UpdateResults;
var
  I: Integer;
begin
  ResultPanel.Caption := '';
  Target := 0;
  if Length(ValueEdit.Text) = 0 then exit;
  if not utils.Str2Float(ValueEdit.Text, Target) then
  begin
    MsgDlg(rsInvalidData, ValueEdit.Text + rsInvalidNumber, mtError, [mbOK], MainForm);
    exit;
  end;

  FilteredCount := 0;
  if NodeQuery then
  begin
    MainForm.MainMenuFrame.ViewNodeCombo.ItemIndex := ParamCbx.ItemIndex + 1;
    mapthemes.ChangeTheme(MainForm.LegendTreeView, ctNodes,
      MainForm.MainMenuFrame.ViewNodeCombo.ItemIndex);
    for I := 1 to project.GetItemCount(project.ctNodes) do
      GetFilteredNodeColor(I);
  end;

  if LinkQuery then
  begin
    MainForm.MainMenuFrame.ViewLinkCombo.ItemIndex := ParamCbx.ItemIndex + 1;
    mapthemes.ChangeTheme(MainForm.LegendTreeView, ctLinks,
      MainForm.MainMenuFrame.ViewLinkCombo.ItemIndex);
    for I := 1 to project.GetItemCount(project.ctLinks) do
      GetFilteredLinkColor(I);
  end;
  ResultPanel.Caption := IntToStr(FilteredCount) + ' ' + rsItemsFound;
  FilteredCount := 0;
  MainForm.MapFrame.RedrawMap;
end;

function TMapQueryFrame.GetFilteredNodeColor(const NodeIndex: Integer): TColor;
var
  Value: Single;
  Theme: Integer;
  TimePeriod: Integer;
begin
  Result := clNone;
  if not NodeQuery then exit;
  Theme := ParamCbx.ItemIndex + 1;
  TimePeriod := mapthemes.TimePeriod;
  Value := mapthemes.GetNodeValue(NodeIndex, Theme, TimePeriod);
  if (Value <> MISSING) and IsFiltered(Value) then
  begin
    Inc(FilteredCount);
    Result := $00277FFF;
  end;
end;

function TMapQueryFrame.GetFilteredLinkColor(const LinkIndex: Integer): TColor;
var
  Value: Single;
  Theme: Integer;
  TimePeriod: Integer;
begin
  Result := clGray;
  if not LinkQuery then exit;
  Theme := ParamCbx.ItemIndex + 1;
  TimePeriod := mapthemes.TimePeriod;
  Value := mapthemes.GetLinkValue(LinkIndex, Theme, TimePeriod);
  if Theme = ltFlow then Value := Abs(Value);
  if (Value <> MISSING) and IsFiltered(Value) then
  begin
    Inc(FilteredCount);
    Result := $00277FFF;
  end;
end;

function TMapQueryFrame.IsFiltered(const Value: Single):Boolean;
begin
  Result := false;
  case ConditionCbx.ItemIndex of
  0: if Value < Target then Result := true;
  1: if Value = Target then Result := true;
  2: if Value > Target then Result := true;
  end;
end;

end.

