{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       fireflowrpt
 Description:  A frame that displays results of a fire flow analysis
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit fireflowrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Grids, Menus, Types, Graphics,
  Dialogs, ComCtrls, StdCtrls, ExtCtrls, Buttons, Clipbrd, map;

const
  NoPressZone = 1;
  FireFlowSet = 2;
  AllNodes    = 3;

type

  { TFireFlowFrame }

  TFireFlowFrame = class(TFrame)
    PageControl1:  TPageControl;
    TabSheet1:     TTabSheet;
    TabSheet2:     TTabSheet;
    TabSheet3:     TTabSheet;
    TabSheet4:     TTabSheet;
    SummaryGrid:   TStringGrid;
    DetailsGrid:   TDrawGrid;
    FullExtentBtn: TToolButton;
    Label1:        TLabel;
    Label2:        TLabel;
    Label3:        TLabel;
    Label4:        TLabel;
    Label5:        TLabel;
    Label6:        TLabel;
    FlowLabel:     TLabel;
    PressLabel:    TLabel;
    LegendPanel:   TPanel;
    MapPanel:      TPanel;
    LogMemo:       TMemo;
    ExportMenu:    TPopupMenu;
    MnuCopy:       TMenuItem;
    MnuSave:       TMenuItem;
    MnuSettings:   TMenuItem;
    Separator1:    TMenuItem;
    PaintBox1:     TPaintBox;
    Panel1:        TPanel;
    Panel2:        TPanel;
    Panel3:        TPanel;
    Shape1:        TShape;
    Shape2:        TShape;
    Shape3:        TShape;
    Shape4:        TShape;
    Shape5:        TShape;
    ToolBar1:      TToolBar;
    ZoomInBtn:     TToolButton;
    ZoomOutBtn:    TToolButton;

    procedure DetailsGridClick(Sender: TObject);
    procedure DetailsGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DetailsGridHeaderClick(Sender: TObject; IsColumn: Boolean;
      Index: Integer);
    procedure DetailsGridPrepareCanvas(Sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure FullExtentBtnClick(Sender: TObject);
    procedure MapSheetResize(Sender: TObject);
    procedure MnuCopyClick(Sender: TObject);
    procedure MnuSaveClick(Sender: TObject);
    procedure MnuSettingsClick(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseWheelDown(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure PaintBox1MouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
    procedure PaintBox1Paint(Sender: TObject);
    procedure SummaryGridSelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);
    procedure ZoomInBtnClick(Sender: TObject);
    procedure ZoomOutBtnClick(Sender: TObject);

  private
    DesignFlow:     Single;
    DesignPress:    Single;
    NumFireNodes:   Integer;
    PressZone:      Integer;
    HasResults:     Boolean;
    FlowUnits:      string;
    PressUnits:     string;
    Map:            Tmap;
    MapOffset:      TPoint;
    MapPanStart:    TPoint;
    MapPanning:     Boolean;

    procedure RefreshSummary;
    procedure ShowFireFlowSelector(InitSelector: Boolean);
    function  GetGridColHeading(aCol: Integer): string;
    function  GetGridCellText(aCol: Integer; aRow: Integer): string;
    procedure SaveResults(FileName: string);
    procedure SaveSummaryGrid(Slist: TStringList);
    procedure SaveDetailsGrid(Slist: TStringList);

    procedure InitMap;
    procedure RedrawMap;
    procedure SaveMap(FileName: string);
    procedure DrawFireFlowNodes;
    function  GetNodeColor(Flow: Single): TColor;

  public
    function  IsEmpty: Boolean;
    procedure InitReport;
    procedure CloseReport;
    procedure RefreshReport;
    procedure ShowPopupMenu;
    procedure SetFireFlowSelection(DesignQ: Single; DesignP: Single;
      Duration: Integer; FireNodes: array of Integer; PressZoneType: Integer);
    procedure WriteToLog(Msg: string);

  end;

implementation

{$R *.lfm}

uses
  main, project, config, reportviewer, fireflowcalc, mapthemes, mapcoords,
  resourcestrings;

const
  SummaryLabels: array[0..6] of string =
    (rsFFsum1, rsFFsum2, rsFFsum3, rsFFsum4, rsFFsum5, rsFFsum6, rsFFsum7);

procedure TFireFlowFrame.WriteToLog(Msg: string);
begin
  LogMemo.Lines.Add(Msg);
end;

procedure TFireFlowFrame.InitReport;
var
  I: Integer;
begin
  NumFireNodes := 0;
  HasResults := false;
  if project.GetUnitsSystem = usUS then
  begin
    FlowUnits := rsGpm;
    PressUnits := rsPsi;
  end
  else
  begin
    FlowUnits := rsLpm;
    PressUnits := rsKpa;
  end;
  Color := config.ThemeColor;

  DetailsGrid.FixedColor := config.ThemeColor;
  DetailsGrid.Color := clWindow;
  DetailsGrid.SortOrder := soAscending;
  DetailsGrid.ColWidths[0] := 112;
  with SummaryGrid do
  begin
    ColWidths[0] := 175;
    ColWidths[1] := Width - ColWidths[0];
    for I := 0 to 6 do
      Cells[0,I] := SummaryLabels[I];
  end;
  InitMap;
  PageControl1.ActivePageIndex := 0;
  ShowFireFlowSelector(true);
  MainForm.EnableMainForm(false);
end;

procedure TFireFlowFrame.CloseReport;
begin
  fireflowcalc.Close;
  if Assigned(Map) then FreeAndNil(Map);
  MainForm.EnableMainForm(true);
  MainForm.FireFlowSelectorFrame.Visible := false;                                                  
end;

function TFireFlowFrame.IsEmpty: Boolean;
begin
  Result := DetailsGrid.RowCount <= 1;
end;

procedure TFireFlowFrame.RefreshReport;
var
  ResultsCount: Integer;
begin
  LogMemo.Clear;
  TabSheet4.TabVisible := false;
  HasResults := false;

  SummaryGrid.Left := (ClientRect.Width - SummaryGrid.Width) div 2;
  DetailsGrid.RowCount := NumFireNodes + 1;
  if NumFireNodes = 0 then exit;

  ResultsCount := fireflowcalc.FindAllFireFlows;
  if ResultsCount > 0 then
  begin
    HasResults := true;
    if ResultsCount < NumFireNodes then
      DetailsGrid.RowCount := ResultsCount + 1;
    with DetailsGrid do
      RowHeights[0] := (2 * DefaultRowHeight) + (DefaultRowHeight div 2);
    DetailsGrid.Refresh;
    RefreshSummary;
    RedrawMap;
  end;

  if LogMemo.Lines.Count > 0 then
  begin
    TabSheet4.TabVisible := true;
    LogMemo.SelStart := 0;
  end;

  PageControl1.ActivePageIndex := 0;
  ReportViewerForm.Show;
end;

procedure TFireFlowFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TFireFlowFrame.MnuSettingsClick(Sender: TObject);
begin
  ReportViewerForm.Hide;
  ShowFireFlowSelector(false);
end;

procedure TFireFlowFrame.MnuCopyClick(Sender: TObject);
begin
  if PageControl1.ActivePage = TabSheet3 then
    SaveMap('')
  else
    SaveResults('');
end;

procedure TFireFlowFrame.MnuSaveClick(Sender: TObject);
begin
  if PageControl1.ActivePage = TabSheet3 then
  begin
    with MainForm.SavePictureDialog1 do
    begin
      FileName := '*.png';
      DefaultExt := '.png';
      if Execute then SaveMap(FileName);
    end;
  end
  else with MainForm.SaveDialog1 do
  begin
    FileName := '*.txt';
    Filter := rsFFTextFile;
    DefaultExt := '*.txt';
    if Execute then
      SaveResults(FileName);
  end;
end;

procedure TFireFlowFrame.ShowFireFlowSelector(InitSelector: Boolean);
begin
  ReportViewerForm.Hide;
  MainForm.HideHintPanelFrames;
  MainForm.FireFlowSelectorFrame.Visible := true;
  if InitSelector then
    MainForm.FireFlowSelectorFrame.Init
  else
    MainForm.FireFlowSelectorFrame.ShowFirstPage;
end;

procedure TFireFlowFrame.SetFireFlowSelection(DesignQ: Single; DesignP: Single;
      Duration: Integer; FireNodes: array of Integer; PressZoneType: Integer);
begin
  DesignFlow := DesignQ;
  DesignPress := DesignP;
  NumFireNodes := Length(FireNodes);
  PressZone := PressZoneType;
  fireflowcalc.Open(DesignQ, DesignP, Duration, FireNodes, PressZone);
end;

procedure TFireFlowFrame.DetailsGridDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
  S: string;
  H: Integer;
  N: Integer;
begin
  S := GetGridCellText(aCol, aRow);
  with Sender as TDrawGrid do
  begin
    if aRow = 0 then
      N := 3
    else
      N := 1;
    H := (aRect.Height - N * Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(aRect, aRect.Left+2, aRect.Top + H, S);
  end;
end;

procedure TFireFlowFrame.DetailsGridClick(Sender: TObject);
var
  ItemIndex: Integer;
begin
  with DetailsGrid do
  begin
    if Row > 0 then
    begin
      ItemIndex := project.GetItemIndex(ctNodes, GetGridCellText(0, Row));
      MainForm.ProjectFrame.SelectItem(ctNodes, ItemIndex - 1);
    end;
  end;
end;

procedure TFireFlowFrame.DetailsGridHeaderClick(Sender: TObject;
  IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
  begin
    fireflowcalc.SortResults(Index, DetailsGrid.SortOrder);
    DetailsGrid.Invalidate;
  end;
end;

procedure TFireFlowFrame.DetailsGridPrepareCanvas(Sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  MyTextStyle := DetailsGrid.Canvas.TextStyle;
  if aRow = 0 then
  begin
    MyTextStyle.SingleLine := false;
    if aCol > 0 then
      MyTextStyle.Alignment := taCenter;
  end
  else if (aCol > 0) then
    MyTextStyle.Alignment := taCenter;
  DetailsGrid.Canvas.TextStyle := MyTextStyle;
end;

procedure TFireFlowFrame.SummaryGridSelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
begin
  CanSelect := false;
end;

function TFireFlowFrame.GetGridColHeading(aCol: Integer): string;
begin
  case aCol of
    0:
      Result := LineEnding + LineEnding + rsFFnode;
    1:
      Result := rsFFstatic + LineEnding + rsFFpress + LineEnding + PressUnits;
    2:
      Result := rsFFmax + LineEnding + rsFFflow + LineEnding + FlowUnits;
    3:
      Result := rsFFresid + LineEnding + rsFFpress + LineEnding + PressUnits;
    4:
      Result := rsFFavail + LineEnding + rsFFflow + LineEnding + FlowUnits;
    5:
      Result := rsFFcritical + LineEnding + rsFFpress + LineEnding + PressUnits;
    6:
      Result := LineEnding + rsFFcritical + LineEnding + rsFFnode;
    else Result := '';
  end;
end;

function TFireFlowFrame.GetGridCellText(aCol: Integer; aRow: Integer): string;
var
  I: Integer;
  J: Integer;
  Value: Single;
begin
  Result := '';
  if aRow = 0 then
  begin
    Result := GetGridColHeading(aCol)
  end
  else
  begin
    I := aRow - 1;
    if aCol = 0 then
    begin
      J := fireflowcalc.FireFlowResults[I].FireNode;
      Result := project.GetID(ctNodes, J);
    end
    else if aCol = 6 then
    begin
      J := fireflowcalc.FireFlowResults[I].CriticalNode;
      Result := project.GetID(ctNodes, J) + '  ';
    end
    else
    begin
      case aCol of
        1:
          Value := fireflowcalc.FireFlowResults[I].StaticPress;
        2:
          Value := DesignFlow;
        3:
          Value := fireflowcalc.FireFlowResults[I].DesignFlowPress;
        4:
          Value := fireflowcalc.FireFlowResults[I].AvailableFlow;
        5:
          Value := fireflowcalc.FireFlowResults[I].CriticalPress;
        else
          Value := 0;
      end;
      Result := FloatToStrF(Value, ffFixed, 7, 0) + '  ';
    end;
  end;
end;

procedure TFireFlowFrame.RefreshSummary;
var
  I: Integer;
  N: Integer;
  TargetMet: Integer = 0;
  AvgAvailFlow: Double = 0;
begin
  N := DetailsGrid.RowCount - 1;
  for I := 0 to N - 1 do
  begin
    if fireflowcalc.FireFlowResults[I].AvailableFlow >= DesignFlow - 0.5 then
      Inc(TargetMet);
    AvgAvailFlow += fireflowcalc.FireFlowResults[I].AvailableFlow;
  end;

  with SummaryGrid do
  begin
    Cells[1,0] := FloatToStrF(DesignFlow, ffFixed, 7, 0) + ' ' + FlowUnits;
    Cells[1,1] := FloatToStrF(DesignPress, ffFixed, 7, 0) + ' ' + PressUnits;
    Cells[1,2] := MainForm.FireFlowSelectorFrame.TimeOfDayCombo.Text;
    Cells[1,3] := IntToStr(DetailsGrid.RowCount - 1) + ' nodes';
    Cells[1,4] := MainForm.FireFlowSelectorFrame.Label17.Caption;
    if N = 0 then
    begin
      Cells[1,5] := 'N/A';
      Cells[1,6] := 'N/A';
    end
    else
    begin
      TargetMet := (100 * TargetMet) div N;
      Cells[1,5] := IntToStr(TargetMet) + ' %';
      AvgAvailFlow := AvgAvailFlow / N;
      Cells[1,6] := FloatToStrF(AvgAvailFlow, ffFixed, 7, 0) + ' ' + FlowUnits;
    end;
    FlowLabel.Caption := Cells[1,0];
    PressLabel.Caption := Cells[1,1];
  end;
end;

procedure TFireFlowFrame.InitMap;
begin
  Map := TMap.Create;
  with Map.Options do
  begin
    ShowNodes := false;
    ShowPumps := false;
    ShowValves := false;
    ShowLabels := false;
    BackColor := clWhite;
  end;
  Map.MapRect := PaintBox1.ClientRect;
  Map.CenterP := Map.MapRect.CenterPoint;
  Map.Bitmap.SetSize(Map.MapRect.Width, Map.MapRect.Height);
  Map.ZoomLevel := 0;
  MapOffset := Point(0, 0);
  MapPanning := False;
end;

procedure TFireFlowFrame.RedrawMap;
var
  SavedNodeTheme: Integer;
  SavedLinkTheme: Integer;
begin
  SavedNodeTheme := mapthemes.NodeTheme;
  SavedLinkTheme := mapthemes.LinkTheme;
  mapthemes.NodeTheme := 0;
  mapthemes.LinkTheme := 0;
  Map.Extent := mapcoords.GetBounds(MainForm.MapFrame.GetExtent);
  Map.Rescale;
  Map.Redraw;
  DrawFireFlowNodes;
  mapthemes.LinkTheme := SavedLinkTheme;
  mapthemes.NodeTheme := SavedNodeTheme;
  PaintBox1.Refresh;
end;

procedure TFireFlowFrame.DrawFireFlowNodes;
var
  I, J, N: Integer;
  Size:    Integer = 4;
  X:       Double = 0;
  Y:       Double = 0;
  P:       TPoint;
begin
  Map.Canvas.Pen.Color := clBlack;
  N := DetailsGrid.RowCount - 1;
  for J := 0 to N - 1 do
  begin
    I := fireflowcalc.FireFlowResults[J].FireNode;
    if not project.GetNodeCoord(I, X, Y) then continue;
    P := Map.WorldToScreen(X, Y);
    Map.Canvas.Brush.Color :=
      GetNodeColor(fireflowcalc.FireFlowResults[J].AvailableFlow);
    Map.Canvas.Ellipse(P.X - Size, P.Y - Size, P.X + Size, P.Y + Size);
  end;
end;

function TFireFlowFrame.GetNodeColor(Flow: Single): TColor;
var
  I: Integer;
  R: Single;
  Intervals: array[2 .. 5] of Single = (25, 50, 75, 100);
begin
  R := (Flow / DesignFlow * 100) + 0.5;
  for I := 5 downto 2 do
  begin
    if R >= Intervals[I] then
    begin
      with FindComponent('Shape' + IntToStr(I)) as TShape do
        Result := Brush.Color;
      exit;
    end;
  end;
  Result := Shape1.Brush.Color;
end;

procedure TFireFlowFrame.MapSheetResize(Sender: TObject);
begin
  if not Assigned(Map) then exit;
  Map.MapRect := PaintBox1.ClientRect;
  Map.CenterP := Map.MapRect.CenterPoint;
  Map.Bitmap.SetSize(Map.MapRect.Width, Map.MapRect.Height);
  Map.ZoomLevel := 0;
  RedrawMap;
end;

procedure TFireFlowFrame.PaintBox1Paint(Sender: TObject);
begin
  if Assigned(Map) then
  begin
    if MapPanning then
    begin
      PaintBox1.Canvas.Brush.Color := Map.GetBackColor;
      PaintBox1.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight))
    end;
    PaintBox1.Canvas.Draw(MapOffset.X, MapOffset.Y, Map.Bitmap);
  end;
end;

procedure TFireFlowFrame.PaintBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
 if Button = mbLeft then
 begin
   MapPanStart := Point(X, Y);
   MapPanning := true;
   PaintBox1.Cursor := crSizeAll;
 end;
end;

procedure TFireFlowFrame.PaintBox1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if MapPanning and (Shift = [ssLeft]) then
  begin
    MapOffset := Point(X - MapPanStart.X, Y - MapPanStart.Y);
    PaintBox1.Refresh;
  end;
end;

procedure TFireFlowFrame.PaintBox1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if MapPanning then
  begin
    MapPanning := false;
    PaintBox1.Cursor := crDefault;
    if (Abs(MapOffset.X) > 2)
    or (Abs(MapOffset.Y) > 2) then
    begin
      Map.AdjustOffset(MapOffset.X, MapOffset.Y);
      MapOffset := Point(0, 0);
      Map.Redraw;
      DrawFireFlowNodes;
      PaintBox1.Refresh;
    end;
  end;
end;

procedure TFireFlowFrame.PaintBox1MouseWheelDown(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  Map.ZoomOut(MousePos.x - (PaintBox1.ClientWidth div 2),
    MousePos.y - (PaintBox1.ClientHeight div 2));
  RedrawMap;
end;

procedure TFireFlowFrame.PaintBox1MouseWheelUp(Sender: TObject;
  Shift: TShiftState; MousePos: TPoint; var Handled: Boolean);
begin
  Map.ZoomIn(MousePos.x - (PaintBox1.ClientWidth div 2),
    MousePos.y - (PaintBox1.ClientHeight div 2));
  RedrawMap;
end;

procedure TFireFlowFrame.ZoomInBtnClick(Sender: TObject);
begin
  Map.ZoomIn(0, 0);
  RedrawMap;
end;

procedure TFireFlowFrame.ZoomOutBtnClick(Sender: TObject);
begin
  Map.ZoomOut(0, 0);
  RedrawMap;
end;

procedure TFireFlowFrame.FullExtentBtnClick(Sender: TObject);
begin
  Map.ZoomLevel := 0;
  RedrawMap;
end;

procedure TFireFlowFrame.SaveResults(FileName: string);
var
  Slist: TStringList;
  Line: string;
begin
  Slist := TStringList.Create;
  try
    Line := project.GetTitle(0);
    if Length(Trim(Line)) > 0 then
      Slist.Add(Line);
    Slist.Add('');
    SaveSummaryGrid(Slist);
    Slist.Add('');
    Slist.Add('');
    Slist.Add(rsFFDetails);
    Slist.Add('');
    SaveDetailsGrid(Slist);
    if Length(FileName) = 0 then
      Clipboard.AsText := Slist.Text
    else
        Slist.SaveToFile(FileName);
  finally
    Slist.Free;
  end;
end;

procedure TFireFlowFrame.SaveSummaryGrid(Slist: TStringList);
var
  R: Integer;
begin
  Slist.Add(rsFFSummary);
  Slist.Add('');
  with SummaryGrid do
  begin
    for R := 0 to RowCount - 1 do
      Slist.Add(Cells[0,R] + #9 + Cells[1,R]);
  end;
end;

procedure TFireFlowFrame.SaveDetailsGrid(Slist: TStringList);
var
  I: Integer;
  J: Integer;
  R: Integer;
  V: array[1..5] of Single;
  Line: string;
  Space: string = ' ';
  S0: string;
  S6: string;
begin
  Line := Format('%-20s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-20s',
    [Space, rsFFstatic, rsFFmax, rsFFresid, rsFFavail, rsFFresid, Space]);
  Slist.Add(Line);
  Line := Format('%-20s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-20s',
    [Space, rsFFpress, rsFFflow, rsFFpress, rsFFflow, rsFFpress, rsFFCritical]);
  Slist.Add(Line);
  Line := Format('%-20s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-12s'#9'%-20s',
    [rsFFnode, PressUnits, FlowUnits, PressUnits, FlowUnits, PressUnits, rsFFnode]);
  Slist.Add(Line);
  for R := 1 to DetailsGrid.RowCount - 1 do
  begin
    I := R - 1;
    J := fireflowcalc.FireFlowResults[I].FireNode;
    S0 := project.GetID(ctNodes, J);
    J := fireflowcalc.FireFlowResults[I].CriticalNode;
    S6 := project.GetID(ctNodes, J);
    V[1] := fireflowcalc.FireFlowResults[I].StaticPress;
    V[2] := DesignFlow;
    V[3] := fireflowcalc.FireFlowResults[I].DesignFlowPress;
    V[4] := fireflowcalc.FireFlowResults[I].AvailableFlow;
    v[5] := fireflowcalc.FireFlowResults[I].CriticalPress;
    Line := Format('%-20s'#9'%-12.0f'#9'%-12.0f'#9'%-12.0f'#9'%-12.0f'#9'%-12.0f'#9'%-20s',
      [S0, V[1], V[2], V[3], V[4], V[5], S6]);
    Slist.Add(Line);
  end;
end;

procedure TFireFlowFrame.SaveMap(FileName: string);
var
  Bitmap: TBitmap;
begin
  Bitmap := TBitmap.Create;
  Toolbar1.Hide;
  try
    Bitmap.SetSize(Panel3.Width, Panel3.Height);
    Panel3.PaintTo(Bitmap.Canvas, 0, 0);
    if Length(FileName) = 0 then
      Clipboard.Assign(Bitmap)
    else
      Bitmap.SaveToFile(FileName);
  finally
    Bitmap.Free;
    Toolbar1.Show;
  end;
end;

end.

