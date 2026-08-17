{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       reportframe
 Description:  a frame that displays results of a network simulation.
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit reportframe;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Buttons, Graphics;

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


  { TReportFrame }

  TReportFrame = class(TFrame)
    CloseBtn: TSpeedButton;
    MainPanel: TPanel;
    MenuBtn: TSpeedButton;
    ReportPanel: TPanel;
    TopPanel: TPanel;
    procedure CloseBtnClick(Sender: TObject);
    procedure MenuBtnClick(Sender: TObject);

  private
    ReportType : TReportType;
    procedure CreateReport(RptType: TReportType);

  public
    Report: TFrame;
    procedure Init;
    procedure ShowReport(RptType: TReportType);
    procedure ChangeColor;
    procedure ChangeTimePeriod;
    procedure RefreshReport;
    procedure ClearReport;
    procedure CloseReport;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, statusrpt, sysflowrpt, pumpingrpt, timeseriesrpt,
  networkrpt, energyrpt, pcntilerpt, profilerpt, calibrationrpt, fireflowrpt,
  resourcestrings;

const
  ReportTypeStr: array[0..10] of string =
    (rsStatusReport, rsPumpingReport, rsCalibReport, rsNodesReport,
     rsLinksReport, rsTseriesReport, rsProfileReport, rsSysFlowReport,
     rsEnergyReport, rsPcntilesReport, rsFireFlowReport);

procedure TReportFrame.MenuBtnClick(Sender: TObject);
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

procedure TReportFrame.CloseBtnClick(Sender: TObject);
begin
  CloseReport;
  MainForm.MapViewerFrame.ReportRadioButton.Enabled := false;
  MainForm.ShowPage(MainForm.MapPage);
end;

procedure TReportFrame.CreateReport(RptType: TReportType);
var
  HideReport: Boolean = false;
begin
  if Report <> nil then CloseReport;
  ReportType := RptType;
  case ReportType of
    rtStatus:
      begin
        Report := TStatusRptFrame.Create(self);
        TStatusRptFrame(Report).InitReport;
        Show;
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
        HideReport := true;
      end;
    rtProfile:
      begin
        Report := TProfileRptFrame.Create(self);
        TProfileRptFrame(Report).InitReport;
        HideReport := true;
      end;
    rtSysFlow:
      begin
        Report := TSysFlowFrame.Create(self);
      end;
    rtPumping:
      begin
        Report := TPumpingRptFrame.Create(self);
        TPumpingRptFrame(Report).InitReport;
      end;
    rtTimeSeries:
      begin
        Report := TTimeSeriesFrame.Create(self);
        TTimeSeriesFrame(Report).InitReport;
        HideReport := true;
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
      end;
  end;
  TopPanel.Caption := ReportTypeStr[QWord(ReportType)];
  Report.Parent := ReportPanel;
  Report.Align := alClient;

  // If HideReport is true then hide the report while its InitReport
  // procedure collects information on what to report.
  if HideReport then
  begin
    MainForm.ShowPage(MainForm.MapPage);
  end
  else
  begin
    MainForm.MapViewerFrame.ReportRadioButton.Enabled := true;
    MainForm.ShowPage(MainForm.ReportPage);
    RefreshReport;
  end;
end;

procedure TReportFrame.Init;
begin
  {$IFDEF UNIX}
  ReportPanel.BevelOuter := bvSpace;
  {$ENDIF}
  Color := config.ThemeColor;
  config.SetHeaderColor(TopPanel);
  Font.Size := config.FontSize;
  ReportType := rtNone;
  Report := nil;

  Visible := false;
end;

procedure TReportFrame.ShowReport(RptType: TReportType);
//
//  Show a results report of type RptType. Called from a choice made
//  on the MainForm's MainMenuFrame Report menu.
//
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
    end;
  end

  // Report type has changed so create it
  else
  begin
    CreateReport(RptType);
  end;
end;

procedure TReportFrame.ChangeColor;
//
//  Change the frame's color theme in response to a change in
//  Program Preferences.
//
begin
  Color := config.ThemeColor;
  config.SetHeaderColor(TopPanel);
  if Report = nil then exit;
  case ReportType of
    rtCalib:
      TCalibRptFrame(Report).SetColors;
    rtPumping:
      TPumpingRptFrame(Report).SetColors;
    rtSysFlow:
      TSysFlowFrame(Report).SetColors;
    rtTimeSeries:
      TTimeSeriesFrame(Report).SetColors;
    rtNodes,
    rtLinks:
      TNetworkRptFrame(Report).SetColors;
  end;
end;

procedure TReportFrame.ChangeTimePeriod;
//
//  Update time-dependent reports when a change in time period is
//  made on the View panel of the MainForm's MapViewerFrame.
//
begin
  if Report = nil then exit;
  if ReportType in [rtNodes, rtLinks] then
    TNetworkRptFrame(Report).RefreshReport
  else if ReportType = rtProfile then
    TProfileRptFrame(Report).RefreshReport;
end;

procedure TReportFrame.RefreshReport;
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
      begin
        Show;
        TSysFlowFrame(Report).RefreshReport;
      end;
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
  Show;
  MainForm.ShowPage(MainForm.ReportPage);
end;

procedure TReportFrame.ClearReport;
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

procedure TReportFrame.CloseReport;
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
  Hide;
  MainForm.ShowPage(MainForm.MapPage);
end;

end.

