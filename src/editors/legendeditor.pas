{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       legendeditor
 Description:  a dialog form that edits the legend used to
               display a theme on the pipe network map
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit legendeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, Menus, lclIntf, SpinEx, LclType, mapthemes;

type

  { TLegendEditorForm }

  TLegendEditorForm = class(TForm)
    ApplyBtn: TButton;
    Cancel2Btn: TButton;
    CancelBtn: TButton;
    ColorDialog1: TColorDialog;
    ColorPaletteBtn: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Edit4: TEdit;
    HelpBtn: TButton;
    IntervalScaleBtn: TButton;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    MaxEdit: TFloatSpinEditEx;
    MinEdit: TFloatSpinEditEx;
    Notebook1: TNotebook;
    OkBtn: TButton;
    Page1: TPage;
    Page2: TPage;
    ReverseColorsBtn: TButton;
    Shape1: TShape;
    Shape2: TShape;
    Shape3: TShape;
    Shape4: TShape;
    Shape5: TShape;

    procedure ApplyBtnClick(Sender: TObject);
    procedure Cancel2BtnClick(Sender: TObject);
    procedure ColorPaletteBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HelpBtnClick(Sender: TObject);
    procedure IntervalScaleBtnClick(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);
    procedure ReverseColorsBtnClick(Sender: TObject);
    procedure Shape1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    LegendType: Integer;
    procedure SetLegendIntervals(Vmin, Vmax: Double);

  public
    Modified: Boolean;
    procedure LoadData(aType: Integer; aCaption: string; Colors: array of TColor;
      Intervals: TLegendIntervals);
    procedure UnloadData(var Colors: array of TColor; var Intervals: TLegendIntervals);

  end;

var
  LegendEditorForm: TLegendEditorForm;

implementation

{$R *.lfm}

uses
  main, themepalette, project, config, utils, resourcestrings;

{ TLegendEditorForm }

procedure TLegendEditorForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
end;

procedure TLegendEditorForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_ESCAPE) and (Notebook1.PageIndex = 1) then
    Notebook1.PageIndex := 0;
end;

procedure TLegendEditorForm.OkBtnClick(Sender: TObject);
var
  I: Integer;
  X1: Single;
  X2: Single;
  S: string;
begin
  X1 := -1e50;
  X2 := 0;
  for I := 1 to 4 do
  begin
    with FindComponent('Edit' + IntToStr(I)) as TEdit do S := Text;
    if not Utils.Str2Float(S, X2) then
    begin
      utils.MsgDlg(rsInvalidData, '"' + S + '"' + rsInvalidNumber, mtError, [mbOk], self);
      exit;
    end
    else if X2 < X1 then
    begin
      utils.MsgDlg(rsInvalidData, rsOutOfOrder, mtError, [mbOk], self);
      exit;
    end
    else
      X1 := X2;
  end;
  ModalResult := mrOk;
end;

procedure TLegendEditorForm.ReverseColorsBtnClick(Sender: TObject);
var
  TmpColors: array [1..5] of TColor;
  I: Integer;
begin
  for I := 1 to 5 do
    with FindComponent('Shape' + IntToStr(I)) as TShape do
      TmpColors[6 - I] := Brush.Color;
  for I := 1 to 5 do
    with FindComponent('Shape' + IntToStr(I)) as TShape do
      Brush.Color := TmpColors[I];
end;

procedure TLegendEditorForm.ColorPaletteBtnClick(Sender: TObject);
var
  I: Integer;
  ThemePaletteForm: TThemePaletteForm;
begin
  ThemePaletteForm := TThemePaletteForm.Create(self);
  try
    ThemePaletteForm.ShowModal;
    if ThemePaletteForm.ModalResult = mrOK then
    begin
      for I := 1 to 5 do
      begin
        with FindComponent('Shape' + IntToStr(I)) as TShape do
          Brush.Color := ThemePaletteForm.Colors[I];
      end;
    end;
  finally
    ThemePaletteForm.Free;
  end;
end;

procedure TLegendEditorForm.ApplyBtnClick(Sender: TObject);
var
  Vmin: Double = 0;
  Vmax: Double = 0;
begin
  Vmin := MinEdit.Value;
  Vmax := MaxEdit.Value;
  if Vmin >= Vmax then
  begin
    utils.MsgDlg(rsInvalidData, rsInvalidRange, mtError, [mbOk], self);
    exit;
  end;
  SetLegendIntervals(Vmin, Vmax);
  Notebook1.PageIndex := 0;
end;

procedure TLegendEditorForm.Cancel2BtnClick(Sender: TObject);
begin
  Notebook1.PageIndex := 0;
end;

procedure TLegendEditorForm.IntervalScaleBtnClick(Sender: TObject);
var
  Vmin: Double = 0;
  Vmax: Double = 0;
begin
  if not mapthemes.GetMinMaxValues(LegendType, Vmin, Vmax) then
  begin
    utils.MsgDlg(rsMissingData, rsNoThemeValues, mtInformation, [mbOk], self);
    exit;
  end;
  MaxEdit.Value := Vmax;
  MinEdit.Value := Vmin;
  Notebook1.PageIndex := 1;
  MinEdit.SetFocus;
end;

procedure TLegendEditorForm.SetLegendIntervals(Vmin, Vmax: Double);
var
  I: Integer;
  Vinterval: Double;
begin
  Vinterval := (Vmax - Vmin) / 5;
  utils.AutoScale(Vmin, Vmax, Vinterval);
  for I := 1 to 4 do
  begin
    with FindComponent('Edit' + IntToStr(I)) as TEdit do
      Text := FloatToStr(Vmin + I * Vinterval);
  end;
end;

procedure TLegendEditorForm.Shape1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    ColorDialog1.Color := TShape(Sender).Brush.Color;
    if ColorDialog1.Execute then
    begin
      TShape(Sender).Brush.Color := ColorDialog1.Color;
      Modified := true;
    end;
  end;
end;

procedure TLegendEditorForm.LoadData(aType: Integer; aCaption: string;
  Colors: array of TColor; Intervals: TLegendIntervals);
var
  I: Integer;
begin
  Modified := false;
  LegendType := aType;
  IntervalScaleBtn.Enabled := project.GetItemCount(aType) > 0;
  Label1.Caption := aCaption;
  Label6.Caption := aCaption;
  for I := 1 to 5 do
    with FindComponent('Shape' + IntToStr(I)) as TShape do
      Brush.Color := Colors[I - 1];
  for I := 1 to 4 do
    with FindComponent('Edit' + IntToStr(I)) as TEdit do
      Text := Intervals.Labels[I];
end;

procedure TLegendEditorForm.UnloadData(var Colors: array of TColor;
  var Intervals: TLegendIntervals);
var
  I: Integer;
  S: string;
begin
  for I := 1 to 5 do
    with FindComponent('Shape' + IntToStr(I)) as TShape do
      Colors[I - 1] := Brush.Color;
  for I := 1 to 4 do
    with FindComponent('Edit' + IntToStr(I)) as TEdit do
    begin
      S := Trim(Text);
      Intervals.Labels[I] := S;
      utils.Str2Float(S, Intervals.Values[I]);
    end;
end;

procedure TLegendEditorForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#map_legend');
end;

end.

