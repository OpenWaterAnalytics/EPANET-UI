{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       pumpingrpt
 Description:  a frame that displays a pumping report
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit pumpingrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Grids, Buttons,
  Graphics, Menus, Clipbrd, Math, Dialogs;

type

  { TPumpingRptFrame }

  TPumpingRptFrame = class(TFrame)
    ExportMenu:  TPopupMenu;
    MnuCopy:     TMenuItem;
    MnuSave:     TMenuItem;
    Label1:      TLabel;
    Panel1:      TPanel;
    Panel2:      TPanel;
    StringGrid1: TStringGrid;

    procedure MnuCopyClick(Sender: TObject);
    procedure StringGrid1Click(Sender: TObject);
    procedure StringGrid1CompareCells(Sender: TObject; ACol, ARow, BCol,
      BRow: Integer; var Result: integer);
    procedure StringGrid1PrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);

  private
    TotalCost: Single;
    DmndCharge: Single;
    procedure RefreshTable;
    procedure GetReportContents(Slist: TStringList);

  public
    procedure InitReport;
    procedure CloseReport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure RefreshGrid;
    procedure ShowPopupMenu;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, results, utils, resourcestrings;

const
  ColHeading: array[0..6] of string =
    (rsPump, rsPcntUtilized, rsEfficiency, '', rsAvgKw, rsPeakKw, rsCostPerDay);

procedure TPumpingRptFrame.StringGrid1CompareCells(Sender: TObject; ACol, ARow,
  BCol, BRow: Integer; var Result: integer);
var
  F1: Extended;
  F2: Extended;
begin
  Result := 0;
  with StringGrid1 do
  begin
    if Acol = 0 then Result := CompareText(Cells[ACol, ARow], Cells[BCol, BRow])
    else
      if TryStrToFloat(StringGrid1.Cells[ACol, ARow], F1)
      and TryStrToFloat(StringGrid1.Cells[BCol, BRow], F2) then
        Result := Math.CompareValue(F1, F2);
    if SortOrder = soDescending then Result := -Result;
  end;
end;

procedure TPumpingRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TPumpingRptFrame.MnuCopyClick(Sender: TObject);
var
  Slist: TStringList;
begin
  Slist := TStringList.Create;
  try
    GetReportContents(Slist);
    Clipboard.AsText := Slist.Text;
  finally
    Slist.Free;
  end;
end;

procedure TPumpingRptFrame.StringGrid1Click(Sender: TObject);
var
  ItemIndex: Integer;
begin
  with StringGrid1 do
  begin
    if Row > 0 then
    begin
      ItemIndex := project.GetItemIndex(ctLinks, Cells[0, Row]);
      MainForm.ProjectFrame.SelectItem(ctLinks, ItemIndex - 1);
    end;
  end;
end;

procedure TPumpingRptFrame.StringGrid1PrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  MyTextStyle := StringGrid1.Canvas.TextStyle;
  if aCol > 0 then MyTextStyle.Alignment := taCenter;
  StringGrid1.Canvas.TextStyle := MyTextStyle;
end;

procedure TPumpingRptFrame.InitReport;
var
  I: Integer;
begin
  with StringGrid1 do
  begin
    TitleFont := Font;
    ColWidths[0] := 128;
    for I := 0 to ColCount - 1 do
      Cells[I,0] := ColHeading[I];
  end;
end;

procedure TPumpingRptFrame.ClearReport;
begin
  StringGrid1.Clear;
end;

procedure TPumpingRptFrame.CloseReport;
begin

end;

procedure TPumpingRptFrame.RefreshGrid;
begin
  RefreshReport;
end;

procedure TPumpingRptFrame.RefreshReport;
var
  KwHrsPerFlow: string;
begin
  StringGrid1.FixedColor := config.ThemeColor;
  if project.GetUnitsSystem = 0 then
    KwHrsPerFlow := rsKwHrsPerMgal
  else
     KwHrsPerFlow := rsKwHrsPerM3;
  StringGrid1.Cells[3, 0] := KwHrsPerFlow;
  RefreshTable;
  if StringGrid1.RowCount = 1 then
    Panel1.Caption := rsNoPumps;;
end;

procedure TPumpingRptFrame.RefreshTable;
var
  I: Integer;
  J: Integer;
  K: Integer;
  L: Integer;
  N: Integer;
  X: array[0..5] of Single;  // Holds a pump's energy usage results
begin
  TotalCost := 0;
  DmndCharge := 0;
  J := 0;
  N := project.GetPumpResultsCount;
  StringGrid1.RowCount := N + 1;
  for I := 0 to 5 do X[I] := 0;
  if N = 0 then exit;

  for I := 1 to project.GetItemCount(ctLinks) do
  begin
    if project.GetLinkType(I) <> ltPump then continue;

    // Column 0 contains pump ID
    Inc(J);
    StringGrid1.Cells[0, J] := project.GetID(ctLinks, I);

    // Place energy usage results into columns 1 to 6
    L := project.GetResultIndex(ctLinks, I);
    if results.GetPumpEnergy(L, X) then
    begin
      TotalCost := TotalCost + X[5];
      for K := 1 to 6 do
        StringGrid1.Cells[K, J] := Utils.Float2Str(X[K-1], 2);
    end
    else for K := 1 to 6 do
    begin
      StringGrid1.Cells[K, J] := 'N/A';
    end;
  end;
  DmndCharge := results.GetPumpDemandCharge;
  Panel1.Caption := '  ' + rsTotalCost + '  ' + Utils.Float2Str(TotalCost, 2) +
                    '  ' + rsDemandCost + '  ' + Utils.Float2Str(DmndCharge, 2);
end;

procedure TPumpingRptFrame.GetReportContents(Slist: TStringList);
var
  I: Integer;
  J: Integer;
  S: string;
begin
  with StringGrid1 do
  begin
    S := project.GetTitle(0);
    Slist.Add(S);
    S := rsPumpingReport;
    Slist.Add(S);
    Slist.Add('');
    for I := 0 to StringGrid1.RowCount - 1 do
    begin
      S := Format('%-20s', [Cells[0, I]]);
      for J := 1 to ColCount - 1 do
        S := S + Format('%20s', [Cells[J, I]]);
      Slist.Add(S);
    end;
  end;
  Slist.Add('');
  Slist.Add(rsTotalCost + Format('%.2f', [TotalCost]));
  Slist.Add(rsDemandCost + Format('%.2f', [DmndCharge]));
end;

end.

