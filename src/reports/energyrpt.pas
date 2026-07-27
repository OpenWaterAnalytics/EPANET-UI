{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       energyrpt
 Description:  a frame to report a simulation's energy balance
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit energyrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Menus, Buttons,
  Dialogs, Graphics, Math, Clipbrd, ComCtrls, Types, TAGraph, TASeries,
  TASources, TAGUIConnectorBGRA;

type

  { TEnergyRptFrame }

  TEnergyRptFrame = class(TFrame)
    Memo1: TMemo;
    PageControl1:           TPageControl;
    Panel2: TPanel;
    TabSheet1:              TTabSheet;
    TabSheet2:              TTabSheet;
    Chart1:                 TChart;
    Chart1PieSeries1:       TPieSeries;
    ListChartSource1:       TListChartSource;
    ChartGUIConnectorBGRA1: TChartGUIConnectorBGRA;
    ExportMenu:             TPopupMenu;
    MnuCopy:                TMenuItem;
    MnuSave:                TMenuItem;
    Panel1:                 TPanel;

    procedure MnuCopyClick(Sender: TObject);
    procedure MnuSaveClick(Sender: TObject);

  private

  public
    procedure Initreport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure ShowPopupMenu;

  end;

implementation

{$R *.lfm}

uses
  main, config, energycalc, resourcestrings;

procedure TEnergyRptFrame.InitReport;
begin
  Memo1.Font.Name := config.MonoFont;
  PageControl1.ActivePageIndex := 0;
end;

procedure TEnergyRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TEnergyRptFrame.MnuCopyClick(Sender: TObject);
begin
  if PageControl1.ActivePageIndex = 0 then
    Chart1.CopyToClipboardBitmap
  else begin
    Memo1.SelectAll;
    Clipboard.AsText := Memo1.Text;
    Memo1.SelLength := 0;
  end;
end;

procedure TEnergyRptFrame.MnuSaveClick(Sender: TObject);
begin
  if PageControl1.ActivePageIndex = 0 then with MainForm.SaveDialog1 do
  begin
    FileName := '*.png';
    Filter := rsPngFile;
    DefaultExt := '*.png';
    if Execute then Chart1.SaveToFile(TPortableNetworkGraphic, FileName)
  end
  else with MainForm.SaveDialog1 do
  begin
    FileName := '*.txt';
    Filter := rsTextFile;
    DefaultExt := '*.txt';
    if Execute then
    begin
      Memo1.Lines.SaveToFile(FileName);
    end;
  end;
end;

procedure TEnergyRptFrame.ClearReport;
begin
  Chart1PieSeries1.Clear;
end;

procedure TEnergyRptFrame.RefreshReport;
var
  I:       Integer;
  Einput:  Double;
  Eoutput: Double;
  Efactor: Double;
  E:       Double;
  Metric: array[0..5] of string;
  Eunits: string;
begin
  // Total energy input and output
  Einput := energycalc.Energy[eInflows] + energycalc.Energy[ePumping] +
            energycalc.Energy[eTankOut];
  Eoutput := energycalc.Energy[eDemands] + energycalc.Energy[eLeakage] +
             energycalc.Energy[eFriction] + energycalc.Energy[eTankIn];

  // Choose between Kwh and MwH units
  if (Einput > 1000) or (Eoutput > 1000) then
  begin
    Efactor := 1000;
    Eunits := rsMwHperDay;
  end
  else
  begin
    Efactor := 1;
    Eunits := rsKwHperDay;
  end;

  // Assign energy values to chart
  for I := eInflows to eTankIn do
  begin
    E := energycalc.Energy[I] / Efactor;
    if E = 0 then E := NAN;
    ListChartSource1[I-1]^.Y := E;
  end;

  // Update chart title
  Chart1.Title.Text.Clear;
  Chart1.Title.Text.Add(rsEnergyBalance + ' (' + Eunits + ')');

  // Update chart footer
  Chart1.Foot.Text.Clear;
  Chart1.Foot.Text.Add(Format(rsEnergySupplied, [Einput / Efactor, Eunits]));
  Chart1.Foot.Text.Add(Format(rsEnergyConsumed, [Eoutput / Efactor, Eunits]));
  Chart1.Refresh;

  // Assign performance metrics
  Memo1.Clear;
  for I := 0 to 5 do Metric[I] := rsNA;
  if Einput > 0 then
  begin
    Metric[0] := Format('%.2f', [energycalc.Energy[eDemands] / Einput]);
    Metric[1] := Format('%.2f', [energycalc.Energy[eFriction] / Einput]);
    Metric[2] := Format('%.2f', [energycalc.Energy[eLeakage] / Einput]);
  end;
  if energycalc.Energy[eMinUse] > 0 then
  begin
    Metric[3] := Format('%.2f', [Einput / energycalc.Energy[eMinUse]]);
    Metric[4] := Format('%.2f', [energycalc.Energy[eDemands] /
                                 energycalc.Energy[eMinUse]]);
    Metric[5] := Format('%.2f', [energycalc.Energy[eMinUse] / Efactor]);
  end;

  with Memo1.Lines do
  begin
    Add('');
    Add('  ' + rsMetricsHeading);
    Add('  ' + rsHeading4);
    Add('');
    Add('  ' + rsMetricsText1 + '     ' + Metric[0]);
    Add('');
    Add('  ' + rsMetricsText2 + '     ' + Metric[1]);
    Add('');
    Add('  ' + rsMetricsText3 + '     ' + Metric[2]);
    Add('');
    Add('  ' + rsMetricsText4 + '     ' + Metric[3]);
    Add('');
    Add('  ' + rsMetricsText5 + '     ' + Metric[4]);
    Add('');
    Add('  ' + Format(rsMetricsText6, [Eunits]) + '    ' + Metric[5]);
    Add('  ' + Format(rsToMeetDemand, [energycalc.PreqStr]));
  end;

end;

end.

