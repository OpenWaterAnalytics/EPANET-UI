{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       pcntileselector
 Description:  A frame used to select a variable and its percentile
               range to display in a Percentile Plot
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit pcntileselector;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Spin, Buttons;

type

  { TPcntileSelectorFrame }

  TPcntileSelectorFrame = class(TFrame)
    TopPanel:     TPanel;
    CancelBtn:    TButton;
    ViewBtn:      TButton;
    CloseBtn:     TSpeedButton;
    Label1:       TLabel;
    Label2:       TLabel;
    Label3:       TLabel;
    Label4:       TLabel;
    Label5:       TLabel;
    NodeBtn:      TRadioButton;
    LinkBtn:      TRadioButton;
    SpinEdit1:    TSpinEdit;
    SpinEdit2:    TSpinEdit;
    SpinEdit3:    TSpinEdit;
    ParamCombo:   TComboBox;
    TimeOfDayBox: TCheckBox;

    procedure CancelBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure NodeBtnChange(Sender: TObject);
    procedure ViewBtnClick(Sender: TObject);

  private

  public
    procedure Init(ParamType, PlotParam, Pmin, Pmid, Pmax: Integer;
          PlotTimeOfDay: Boolean);

  end;

implementation

{$R *.lfm}

uses
  project, config, mapthemes, reportviewer, pcntilerpt;

procedure TPcntileSelectorFrame.CloseBtnClick(Sender: TObject);
begin
  CancelBtnClick(Sender);
end;

procedure TPcntileSelectorFrame.NodeBtnChange(Sender: TObject);
var
  I: Integer;
  J: Integer;
  K: Integer;
begin
  J := ParamCombo.ItemIndex;
  ParamCombo.Clear;
  if NodeBtn.Checked then
  begin
    for I := FirstNodeResultTheme to NodeThemeCount - 1 do
      ParamCombo.Items.Add(MapThemes.NodeThemes[I].Name);
    K := ntPressure - FirstNodeResultTheme
  end
  else
  begin
    for I := FirstLinkResultTheme to LinkThemeCount - 1 do
      ParamCombo.Items.Add(MapThemes.LinkThemes[I].Name);
    K := ltFlow - FirstLinkResultTheme;
  end;
  if (J < 0)
  or (J >= ParamCombo.Items.Count) then
    ParamCombo.ItemIndex := K
  else
    ParamCombo.ItemIndex := J;
end;

procedure TPcntileSelectorFrame.ViewBtnClick(Sender: TObject);
var
  ParamType:     Integer;
  PlotParam:     Integer;
  Pmin:          Integer;
  Pmid:          Integer;
  Pmax:          Integer;
  PlotTimeOfDay: Boolean;
begin
  if NodeBtn.Checked then
  begin
    ParamType := ctNodes;
    PlotParam := ParamCombo.ItemIndex + FirstNodeResultTheme;
  end
  else
  begin
    ParamType := ctLinks;
    PlotParam := ParamCombo.ItemIndex + FirstLinkResultTheme;
  end;
  Pmin := SpinEdit1.Value;
  Pmid := SpinEdit2.Value;
  Pmax := SpinEdit3.Value;
  PlotTimeOfDay := TimeOfDayBox.Checked;
  with ReportViewerForm.Report as TPcntileRptFrame do
  begin
    SetPlotParams(ParamType, PlotParam, Pmin, Pmid, Pmax, PlotTimeOfDay);
    RefreshReport;
  end;
  Hide;
  if ReportViewerForm.WindowState = wsMinimized then
    ReportViewerForm.WindowState := wsNormal;
  ReportViewerForm.Show;
end;

procedure TPcntileSelectorFrame.CancelBtnClick(Sender: TObject);
begin
  Visible := false;
  with ReportViewerForm.Report as TPcntileRptFrame do
  begin
    if ChartIsShowing then
      ReportViewerForm.Show
    else
      ReportViewerForm.Close;
  end;
end;

procedure TPcntileSelectorFrame.Init(ParamType, PlotParam, Pmin, Pmid, Pmax: Integer;
      PlotTimeOfDay: Boolean);
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  if ParamType = ctNodes then
    NodeBtn.Checked := true
  else
    LinkBtn.Checked := true;
  if ParamType = ctNodes then
    ParamCombo.ItemIndex := PlotParam - FirstNodeResultTheme
  else
    ParamCombo.ItemIndex := PlotParam - FirstLinkResultTheme;
  SpinEdit1.Value := Pmin;
  SpinEdit2.Value := Pmid;
  SpinEdit3.Value := Pmax;
  TimeOfDayBox.Checked := PlotTimeOfDay;
end;

end.

