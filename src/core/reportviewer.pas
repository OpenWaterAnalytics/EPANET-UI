{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       reportviewer
 Description:  a form that displays results of a network simulation.
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit reportviewer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  LCLtype, Buttons;

type

  // Types of reports
  TReportType = (rtStatus = 0,    // Simulation status report
                 rtPumping,       // Pumping report
                 rtCalib,         // Calibration report
                 rtNodes,         // Network nodes report
                 rtLinks,         // Network links report
                 rtTimeSeries,    // Time series report
                 rtProfile,       // Hyd. profile report
                 rtSysFlow,       // System flows report
                 rtEnergy,        // Energy balance report
                 rtPcntile,       // Variability report
                 rtFireFlow,      // Fire flow report
                 rtNone);

  { TReportViewerForm }

  { This is an auto-created, stay-on-top form used to display the results
    of a simulation in one of the formats listed above. It contains a top
    panel with a button used to popup menu of actions specific to each
    type of report.

    The form's Report variable is a TFrame that holds a reference to a
    report-specific TFrame responsible for generating the report's contents.

    The form is activated when one of the options from the Report item on
    the MainForm's MainMenuFrame is selected.
  }

  TReportViewerForm = class(TForm)
    MenuBtn: TSpeedButton;
    TopPanel: TPanel;
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure MenuBtnClick(Sender: TObject);
  private
    ReportType : TReportType;
    procedure CreateReport(RptType: TReportType);

  public
    Report: TFrame;
    procedure ShowReport(RptType: TReportType);
    procedure ChangeColor(aColor: TColor);
    procedure ChangeTimePeriod;
    procedure RefreshReport;
    procedure UpdateReport;
    procedure ClearReport;
    procedure CloseReport;
  end;

var
  ReportViewerForm: TReportViewerForm;

implementation

{$R *.lfm}

uses
  project, config, statusrpt, sysflowrpt, pumpingrpt, timeseriesrpt, networkrpt,
  energyrpt, pcntilerpt, profilerpt, calibrationrpt, fireflowrpt,
  resourcestrings;

const
  ReportTypeStr: array[0..10] of string =
    (rsStatusReport, rsPumpingReport, rsCalibReport, rsNodesReport,
     rsLinksReport, rsTseriesReport, rsProfileReport, rsSysFlowReport,
     rsEnergyReport, rsVariationReport, rsFireFlowReport);

{ TReportViewerForm }

procedure TReportViewerForm.FormCreate(Sender: TObject);
begin
  Font.Size := config.FontSize;
  ReportType := rtNone;
  Report := nil;
end;

procedure TReportViewerForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  CloseReport;
  Hide;
end;

procedure TReportViewerForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
//
//  Escape key closes the report.
//
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    CloseReport;
    Hide;
  end;
end;

procedure TReportViewerForm.MenuBtnClick(Sender: TObject);
begin
  if Report = nil then exit;
  case ReportType of
    rtStatus:
      TStatusRptFrame(Report).ShowPopupMenu;
    rtEnergy:
      TEnergyRptFrame(Report).ShowPopupMenu;
    rtPcntile:
      TPcntileRptFrame(Report).ShowPopupMenu;
    rtCalib:
      TCalibRptFrame(Report).ShowPopupMenu;
    rtSysFlow:
      TSysFlowFrame(Report).ShowPopupMenu;
    rtPumping:
      TPumpingRptFrame(Report).ShowPopupMenu;
    rtTimeSeries:
      TTimeSeriesFrame(Report).ShowPopupMenu;
    rtProfile:
      TProfileRptFrame(Report).ShowPopupmenu;
    rtNodes,
    rtLinks:
      TNetworkRptFrame(Report).ShowPopupMenu;
    rtFireFlow:
      TFireFlowFrame(Report).ShowPopupMenu;
  end;
end;

procedure TReportViewerForm.CreateReport(RptType: TReportType);
var
  HideForm: Boolean = false;
begin
  if Report <> nil then CloseReport;
  ReportType := RptType;
  case ReportType of
    rtStatus:
      begin
        Report := TStatusRptFrame.Create(self);
        TStatusRptFrame(Report).InitReport;
      end;
    rtEnergy:
      begin
        Report := TEnergyRptFrame.Create(self);
        TEnergyRptFrame(Report).InitReport;
      end;
    rtCalib:
      begin
        Report := TCalibRptFrame.Create(self);
        TCalibRptFrame(Report).InitReport;
      end;
    rtPcntile:
      begin
        Report := TPcntileRptFrame.Create(self);
        TPcntileRptFrame(Report).InitReport;
        HideForm := true;
      end;
    rtProfile:
      begin
        Report := TProfileRptFrame.Create(self);
        TProfileRptFrame(Report).InitReport;
        HideForm := true;
      end;
    rtSysFlow:
      Report := TSysFlowFrame.Create(self);
    rtPumping:
      begin
        Report := TPumpingRptFrame.Create(self);
        TPumpingRptFrame(Report).InitReport;
      end;
    rtTimeSeries:
      begin
        Report := TTimeSeriesFrame.Create(self);
        TTimeSeriesFrame(Report).InitReport;
        HideForm := true;
      end;
    rtNodes:
      begin
        Report := TNetworkRptFrame.Create(self);
      end;
    rtLinks:
      begin
        Report := TNetworkRptFrame.Create(self);
      end;
    rtFireFlow:
      begin
        Report := TFireFlowFrame.Create(self);
        TFireFlowFrame(Report).InitReport;
        HideForm := true;
      end;
  end;
  TopPanel.Caption := ReportTypeStr[QWord(ReportType)];
  Report.Parent := Self;
  Report.Align := alClient;

  // If HideForm is true then hide this form while the report's InitReport
  // procedure collects information on what to report.
  if HideForm then
    Hide
  else
    RefreshReport;
end;

procedure TReportViewerForm.ShowReport(RptType: TReportType);
begin
  // Report type hasn't changed
  if RptType = ReportType then
  begin
    // Show report content selector frames for following report types
    case ReportType of
      rtTimeSeries:
        TTimeSeriesFrame(Report).ShowTimeSeriesSelector;
      rtProfile:
        TProfileRptFrame(Report).ShowProfileSelector;
      rtPcntile:
        TPcntileRptFrame(Report).ShowPercentileSelector;
    end;
  end

  // Report type has changed so create it
  else
  begin
    CreateReport(RptType);
  end;
end;

procedure TReportViewerForm.ClearReport;
begin
  if Report = nil then exit;
  case ReportType of
    rtStatus:
      TStatusRptFrame(Report).ClearReport;
    rtCalib:
      TCalibRptFrame(Report).ClearReport;
    rtSysFlow:
      TSysFlowFrame(Report).ClearReport;
    rtTimeSeries:
      TTimeSeriesFrame(Report).ClearReport;
  end;
end;

procedure TReportViewerForm.RefreshReport;
begin
  if Report = nil then exit;
  case ReportType of
    rtStatus:
      TStatusRptFrame(Report).RefreshReport;
    rtEnergy:
      TEnergyRptFrame(Report).RefreshReport;
    rtPcntile:
      TPcntileRptFrame(Report).RefreshReport;
    rtCalib:
      TCalibRptFrame(Report).Refreshreport;
    rtSysFlow:
      TSysFlowFrame(Report).RefreshReport;
    rtPumping:
      TPumpingRptFrame(Report).RefreshReport;
    rtTimeSeries:
      TTimeSeriesFrame(Report).RefreshReport;
    rtProfile:
      TProfileRptFrame(Report).RefreshReport;
    rtNodes:
      begin
        TNetworkRptFrame(Report).InitReport(ctNodes);
        TNetworkRptFrame(Report).RefreshReport;
      end;
    rtLinks:
      begin
        TNetworkRptFrame(Report).InitReport(ctLinks);
        TNetworkRptFrame(Report).RefreshReport;
      end;
  end;
  if ReportType <> rtFireFlow then Show;
end;

procedure TReportViewerForm.UpdateReport;
begin
  if Report = nil then exit;
  if ReportType in [rtNodes, rtLinks] then
    TNetworkRptFrame(Report).RefreshGrid;
end;

procedure TReportViewerForm.ChangeColor(aColor: TColor);
//
//  Change the form's background color in response to a change in
//  Program Preferences.
//
begin
  Color := aColor;
  if Report = nil then exit;
  case ReportType of
    rtPumping:
      TPumpingRptFrame(Report).RefreshGrid;
    rtSysFlow:
      TSysFlowFrame(Report).RefreshGrid;
    rtTimeSeries:
      TTimeSeriesFrame(Report).RefreshGrid;
    rtNodes,
    rtLinks:
      TNetworkRptFrame(Report).RefreshGrid;
  end;
end;

procedure TReportViewerForm.ChangeTimePeriod;
//
//  Update time-dependent reports when a change in time period is
//  made on the View panel of the MainForm's MainMenuFrame.
//
begin
  if Report = nil then exit;
  if ReportType in [rtNodes, rtLinks] then
    TNetworkRptFrame(Report).RefreshReport
  else if ReportType = rtProfile then
    TProfileRptFrame(Report).RefreshReport;
end;

procedure TReportViewerForm.CloseReport;
begin
  if Report = nil then exit;
  case ReportType of
    rtStatus:
      TStatusRptFrame(Report).CloseReport;
    rtCalib:
      TCalibRptFrame(Report).CloseReport;
    rtPumping:
      TPumpingRptFrame(Report).CloseReport;
    rtTimeSeries:
      TTimeSeriesFrame(Report).CloseReport;
    rtPcntile:
      TPcntileRptFrame(Report).CloseReport;
    rtProfile:
      TProfileRptFrame(Report).CloseReport;
    rtFireFlow:
      TFireFlowFrame(Report).CloseReport;
  end;
  if Report is TNetworkRptFrame then
    TNetworkRptFrame(Report).CloseReport;
  FreeAndNil(Report);
  ReportType := rtNone;
end;

end.

