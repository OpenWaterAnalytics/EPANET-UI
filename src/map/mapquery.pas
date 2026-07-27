{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mapquery
 Description:  a frame that highlights network objects that meet a
               specific criterion.
 License:      see LICENSE
 Last Updated: 06/19/2026
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
    CloseBtn:       TSpeedButton;
    FindCombo:      TComboBox;
    ParamCombo:     TComboBox;
    ConditionCombo: TComboBox;
    ValueEdit:      TEdit;
    Label1:         TLabel;
    Label2:         TLabel;
    ResultPanel:    TPanel;
    TopPanel:       TPanel;

    procedure CloseBtnClick(Sender: TObject);
    procedure FindComboChange(Sender: TObject);
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
    function  GetFilteredNodeColor(const NodeIndex: Integer): TColor;
    function  GetFilteredLinkColor(const LinkIndex: Integer): TColor;
  end;

implementation

{$R *.lfm}

uses
  main, project, mapframe, mapthemes, config, utils, resourcestrings;

{ TMapQueryFrame }

procedure TMapQueryFrame.Init;
begin
  FindCombo.ItemIndex := 0;
  ParamCombo.ItemIndex := 0;
  NodeQuery := true;
  LinkQuery := false;
end;

procedure TMapQueryFrame.Show;
begin
  Color := config.CreamTheme;
  config.SetHeaderColor(TopPanel);
  ValueEdit.Text := '';
  ResultPanel.Caption := '';
  NodeQuery := false;
  LinkQuery := false;
  FindComboChange(self);
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

procedure TMapQueryFrame.FindComboChange(Sender: TObject);
var
  I, N: Integer;
  MainViewCombo: TComboBox;
begin
  ParamCombo.Clear;
  if FindCombo.ItemIndex = 0 then
  begin
    NodeQuery := true;
    LinkQuery := false;
    MainViewCombo := MainForm.MapViewerFrame.ViewNodeCombo;
  end
  else
  begin
    NodeQuery := false;
    LinkQuery := true;
    MainViewCombo := MainForm.MapViewerFrame.ViewLinkCombo;
  end;
  N := MainViewCombo.Items.Count;
  for I := 1 to N-1 do
    ParamCombo.Items.Add(MainViewCombo.Items[I]);
  I := MainViewCombo.ItemIndex - 1;
  if I < 0 then I := 0;
  ParamCombo.ItemIndex := I;
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
    MainForm.MapViewerFrame.ViewNodeCombo.ItemIndex := ParamCombo.ItemIndex + 1;
    mapthemes.ChangeTheme(ctNodes, MainForm.MapViewerFrame.ViewNodeCombo.ItemIndex);
    for I := 1 to project.GetItemCount(project.ctNodes) do
      GetFilteredNodeColor(I);
  end;

  if LinkQuery then
  begin
    MainForm.MapViewerFrame.ViewLinkCombo.ItemIndex := ParamCombo.ItemIndex + 1;
    mapthemes.ChangeTheme(ctLinks, MainForm.MapViewerFrame.ViewLinkCombo.ItemIndex);
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
  Theme := ParamCombo.ItemIndex + 1;
  TimePeriod := mapthemes.TimePeriod;
  Value := mapthemes.GetNodeValue(NodeIndex, Theme, TimePeriod);
  if (Value <> MISSING) and IsFiltered(Value) then
  begin
    Inc(FilteredCount);
    Result := clRed;  //00277FFF;
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
  Theme := ParamCombo.ItemIndex + 1;
  TimePeriod := mapthemes.TimePeriod;
  Value := mapthemes.GetLinkValue(LinkIndex, Theme, TimePeriod);
  if Theme = ltFlow then Value := Abs(Value);
  if (Value <> MISSING) and IsFiltered(Value) then
  begin
    Inc(FilteredCount);
    Result := clRed;  //00277FFF;
  end;
end;

function TMapQueryFrame.IsFiltered(const Value: Single):Boolean;
begin
  Result := false;
  case ConditionCombo.ItemIndex of
  0: if Value < Target then Result := true;
  1: if Value = Target then Result := true;
  2: if Value > Target then Result := true;
  end;
end;

end.

