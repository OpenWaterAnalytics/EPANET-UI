{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mainmenu
 Description:  a frame containing the program's main menu
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
{
The layout of EPANET's main menu frame is as follows:
 __________________________________________________________
|            |            |      MenuBarPanel             |
| MenuPanel1 | MenuPanel2 | etc.                          |
|____________|____________|_______________________________|
|                                                         |
|                MenuNotebook                             |
|_________________________________________________________|

The MenuBarPanel (housed in Panel2) contains a collection of panels
(MenuPanel1 .. MenuPanel6) that activate a page of MenuNotebook when
clicked on.

The MenuNotebook contains a collection of pages corresponding
to each top level menu panel (Page1 for MenuPanel1, Page2 for
MenuPanel2, etc.).

Each MenuNotebook page contains a toolbar (EditToolbar, MapToolbar, etc.)
with toolbuttons for the menu commands belonging to its coresponding top
level menu panel. An exception is the File menu (MenuPanel1) which displays
its own FileMenu form when selected.
}

unit mainmenu;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, ExtCtrls, Buttons,
  Menus, LCLintf, LCLtype, Dialogs, Graphics, ImgList;

type

  { TMainMenuFrame }

  TMainMenuFrame = class(TFrame)
    AddJuncItem:          TMenuItem;
    AddLabelItem:         TMenuItem;
    AddPipeItem:          TMenuItem;
    AddPumpItem:          TMenuItem;
    AddResvItem:          TMenuItem;
    AddTankItem:          TMenuItem;
    AddValveItem:         TMenuItem;
    AnimationTimer:       TTimer;
    BasemapGeorefItem:    TMenuItem;
    BasemapGrayscaleItem: TMenuItem;
    BasemapLightenItem:   TMenuItem;
    BasemapLoadItem:      TMenuItem;
    BasemapMenu:          TPopupMenu;
    BasemapUnloadItem:    TMenuItem;
    FileSaveAsBtn:        TToolButton;
    EditCopyBtn:          TToolButton;
    FileNewBtn:           TToolButton;
    EditPasteBtn:         TToolButton;
    FileOpenBtn:          TToolButton;
    EditReverseBtn:       TToolButton;
    FileSaveBtn:          TToolButton;
    EditSep1:             TToolButton;
    EditSep2:             TToolButton;
    FileSep1:             TToolButton;
    FileSep2:             TToolButton;
    EditToolBar:          TToolBar;
    FileToolBar:          TToolBar;
    EditVertexBtn:        TToolButton;
    ExportMapToClipboard: TMenuItem;
    ExportMapToFile:      TMenuItem;
    FilePanel:            TPanel;
    FilePreferencesBtn:   TToolButton;
    GroupEditBtn:         TToolButton;
    FileImportBtn:        TToolButton;
    HelpAboutBtn:         TToolButton;
    HelpErrorsBtn:        TToolButton;
    HelpSep1:             TToolButton;
    HelpToolBar:          TToolBar;
    HelpTopicsBtn:        TToolButton;
    HelpTutorialBtn:      TToolButton;
    HelpUnitsBtn:         TToolButton;
    MapBasemapBtn:        TToolButton;
    MapCopyMapBtn:        TToolButton;
    MapExtentsBtn:        TToolButton;
    MapOptionsBtn:        TToolButton;
    MapQueryBtn:          TToolButton;
    MapSep1:              TToolButton;
    MapSep3:              TToolButton;
    BasemapAlignItem:     TMenuItem;
    MapToolBar:           TToolBar;
    MapZoomInBtn:         TToolButton;
    MapZoomOutBtn:        TToolButton;
    ConvertMenuItem1:     TMenuItem;
    ConvertMenuItem2:     TMenuItem;
    ConvertMenuItem3:     TMenuItem;
    ImportMenu:           TPopupMenu;
    DxfFileMenuItem:      TMenuItem;
    MruMenu:              TPopupMenu;
    TextFileMenuItem:     TMenuItem;
    ShapefileMenuItem:    TMenuItem;
    SpeedPanel:           TPanel;
    SpeedBar:             TToolBar;
    ToolButton1:          TToolButton;
    FileQuitBtn:          TToolButton;
    FileSep3: TToolButton;
    ToolButton2:          TToolButton;
    ToolButton3:          TToolButton;
    ToolButton4:          TToolButton;
    ToolButton5:          TToolButton;
    ToolButton6:          TToolButton;
    ToolButton7:          TToolButton;
    ToolButton8:          TToolButton;
    ToolButton9:          TToolButton;
    ToValveMenuItem:      TMenuItem;
    ToPumpMenuItem:       TMenuItem;
    ToPipeMenuItem:       TMenuItem;
    MenuPanel2:           TPanel;
    MenuPanel3:           TPanel;
    MenuPanel4:           TPanel;
    MenuPanel5:           TPanel;
    MenuPanel6:           TPanel;
    MenuNotebook:         TNotebook;
    Page1:                TPage;
    Page2:                TPage;
    Page3:                TPage;
    Page4:                TPage;
    Page5:                TPage;
    Page6:                TPage;
    Panel1:               TPanel;
    Panel2:               TPanel;
    MenuBarPanel:         TPanel;
    MenuPanel1:           TPanel;
    ConvertMenu:          TPopupMenu;
    ProjectAddBtn:        TToolButton;
    ProjectAnalyzeBtn:    TToolButton;
    ProjectDeleteBtn:     TToolButton;
    ProjectDetailsBtn:    TToolButton;
    ProjectFindBtn:       TToolButton;
    ProjectReportBtn:     TToolButton;
    ProjectSep1:          TToolButton;
    ProjectSep2:          TToolButton;
    ProjectSetupBtn:      TToolButton;
    ProjectSummaryBtn:    TToolButton;
    ProjectToolBar:       TToolBar;
    RptProfileItem:       TMenuItem;
    ObjectMenu:           TPopupMenu;
    ReportMenu:           TPopupMenu;
    RptCalibItem:         TMenuItem;
    RptEnergyItem:        TMenuItem;
    RptNetLinksItem:      TMenuItem;
    RptNetNodesItem:      TMenuItem;
    RptPercentileItem:    TMenuItem;
    RptPumpItem:          TMenuItem;
    RptStatusItem:        TMenuItem;
    RptSysFlowItem:       TMenuItem;
    RptTseriesItem:       TMenuItem;
    RptFireFlowItem:      TMenuItem;
    Separator1:           TMenuItem;
    Separator11:          TMenuItem;
    Separator3:           TMenuItem;
    Separator4:           TMenuItem;
    Separator5:           TMenuItem;
    Separator6:           TMenuItem;
    Separator7:           TMenuItem;
    Separator8:           TMenuItem;
    GroupDeleteBtn:       TToolButton;
    EditConvertBtn:       TToolButton;
    ViewAnimateBtn:       TSpeedButton;
    ViewBevel1:           TBevel;
    ViewBevel2:           TBevel;
    ViewLinkCombo:        TComboBox;
    ViewLinkLbl:          TLabel;
    ViewLinkLegendBtn:    TSpeedButton;
    ViewNodeCombo:        TComboBox;
    ViewNodeLbl:          TLabel;
    ViewNodeLegendBtn:    TSpeedButton;
    ViewPanel:            TPanel;
    ViewTimePanel:        TPanel;
    ViewTrackBar:         TTrackBar;

    procedure AddLabelItemClick(Sender: TObject);
    procedure AddLinkItemClick(Sender: TObject);
    procedure AddNodeItemClick(Sender: TObject);
    procedure AnimationTimerTimer(Sender: TObject);

    procedure BasemapAlignItemClick(Sender: TObject);
    procedure BasemapGeorefItemClick(Sender: TObject);
    procedure BasemapGrayscaleItemClick(Sender: TObject);
    procedure BasemapLightenItemClick(Sender: TObject);
    procedure BasemapLoadItemClick(Sender: TObject);
    procedure BasemapMenuPopup(Sender: TObject);
    procedure BasemapUnloadItemClick(Sender: TObject);

    procedure ConvertMenuItemClick(Sender: TObject);
    procedure ConvertMenuPopup(Sender: TObject);
    procedure DxfFileMenuItemClick(Sender: TObject);
    procedure FileNewBtnClick(Sender: TObject);
    procedure FileOpenBtnClick(Sender: TObject);
    procedure FilePreferencesBtnClick(Sender: TObject);
    procedure FileQuitBtnClick(Sender: TObject);
    procedure FileSaveAsBtnClick(Sender: TObject);
    procedure FileSaveBtnClick(Sender: TObject);
    procedure MenuMeasureItem(Sender: TObject; ACanvas: TCanvas;
      var AWidth, AHeight: Integer);

    procedure EditCopyBtnClick(Sender: TObject);
    procedure EditPasteBtnClick(Sender: TObject);
    procedure EditReverseBtnClick(Sender: TObject);
    procedure EditVertexBtnClick(Sender: TObject);
    procedure GroupEditBtnClick(Sender: TObject);
    procedure GroupDeleteBtnClick(Sender: TObject);

    procedure HelpAboutBtnClick(Sender: TObject);
    procedure HelpErrorsBtnClick(Sender: TObject);
    procedure HelpTopicsBtnClick(Sender: TObject);
    procedure HelpTutorialBtnClick(Sender: TObject);
    procedure HelpUnitsBtnClick(Sender: TObject);

    procedure MapCopyMapBtnClick(Sender: TObject);
    procedure MapExtentsBtnClick(Sender: TObject);
    procedure MapOptionsBtnClick(Sender: TObject);
    procedure MapQueryBtnClick(Sender: TObject);
    procedure MapZoomInBtnClick(Sender: TObject);
    procedure MapZoomOutBtnClick(Sender: TObject);

    procedure MenuPanel1MouseEnter(Sender: TObject);
    procedure MenuPanel1MouseLeave(Sender: TObject);
    procedure MenuPanelClick(Sender: TObject);

    procedure ProjectAnalyzeBtnClick(Sender: TObject);
    procedure ProjectDeleteBtnClick(Sender: TObject);
    procedure ProjectDetailsBtnClick(Sender: TObject);
    procedure ProjectFindBtnClick(Sender: TObject);
    procedure ProjectSetupBtnClick(Sender: TObject);
    procedure ProjectSummaryBtnClick(Sender: TObject);

    procedure ReportMenuPopup(Sender: TObject);
    procedure RptCalibItemClick(Sender: TObject);
    procedure RptEnergyItemClick(Sender: TObject);
    procedure RptFireFlowItemClick(Sender: TObject);
    procedure RptNetLinksItemClick(Sender: TObject);
    procedure RptNetNodesItemClick(Sender: TObject);
    procedure RptPercentileItemClick(Sender: TObject);
    procedure RptProfileItemClick(Sender: TObject);
    procedure RptPumpItemClick(Sender: TObject);
    procedure RptStatusItemClick(Sender: TObject);
    procedure RptSysFlowItemClick(Sender: TObject);
    procedure RptTseriesItemClick(Sender: TObject);
    procedure ShapefileMenuItemClick(Sender: TObject);
    procedure TextFileMenuItemClick(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);

    procedure ViewAnimateBtnClick(Sender: TObject);
    procedure ViewLinkComboChange(Sender: TObject);
    procedure ViewLinkLegendBtnClick(Sender: TObject);
    procedure ViewNodeComboChange(Sender: TObject);
    procedure ViewNodeLegendBtnClick(Sender: TObject);
    procedure ViewTrackBarChange(Sender: TObject);
    procedure ViewTrackBarKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ViewTrackBarKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ViewTrackBarMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ViewTrackBarMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    MenuPanel: TPanel;
    function GetViewTime(Period: Integer): string;

  public
    procedure Init;
    procedure InitMapThemes;
    procedure InitViewTimeTrackBar(const N: Integer);
    procedure Reset;
    procedure SelectMenuItem(Key: Word);
    procedure SelectProjectMenu;
    procedure ResetMapThemes;
    procedure SetColorTheme;
    procedure UpdateEditMenuBtns;
  end;

implementation

{$R *.lfm}

uses
  main, basemapmenu, project, projectsummary, projectviewer, config,
  mapthemes, simulator, results, reportviewer, about, utils, resourcestrings;

const
  MenuPanelHoverColor: TColor = clHighlight; //00D1B499

{ TMainMenuFrame }

procedure TMainMenuFrame.Init;
var
  I: Integer;
begin
  Color := config.ThemeColor;
  MenuBarPanel.Color := $00745146;     //0068370F;  //009C6D4E;

  Font.Size := config.FontSize;
  MenuPanel := MenuPanel5;  // "Project" menu panel
  MenuPanelClick(MenuPanel);

  // Initialize contents of the main form's LegendTreeView
  mapthemes.InitThemes(MainForm.LegendTreeView);
  mapthemes.InitColors;

  // Initialize contents of the controls on the View menu panel
  for I := 0 to High(mapthemes.NodeThemes) do
    ViewNodeCombo.Items.Add(mapthemes.NodeThemes[I].Name);
  for I := 0 to High(mapthemes.LinkThemes) do
    ViewLinkCombo.Items.Add(mapthemes.LinkThemes[I].Name);
  ViewNodeCombo.ItemIndex := 0;
  ViewLinkCombo.ItemIndex := 0;
  ViewNodeLegendBtn.Enabled := false;
  ViewLinkLegendBtn.Enabled := false;
end;

procedure TMainMenuFrame.Reset;
//
//  Reset frame contents when a new project is started.
//
var
  I: Integer;
begin
  Color := config.ThemeColor;
  BasemapGrayscaleItem.Checked := false;
  BasemapLightenItem.Checked := false;
  InitViewTimeTrackBar(0);
  mapthemes.InitThemes(MainForm.LegendTreeView);

  ViewNodeCombo.Items.Clear;
  ViewLinkCombo.Items.Clear;
  for I := 0 to mapthemes.NodeThemeCount - 1 do
    ViewNodeCombo.Items.Add(mapthemes.NodeThemes[I].Name);
  for I := 0 to mapthemes.LinkThemeCount - 1 do
    ViewLinkCombo.Items.Add(mapthemes.LinkThemes[I].Name);
  ViewNodeCombo.ItemIndex := 1;
  ViewNodeComboChange(self);
  ViewLinkCombo.ItemIndex := 1;
  ViewLinkComboChange(self);
  ViewAnimateBtn.Down := false;
  ViewAnimateBtn.Enabled := false;
  AnimationTimer.Enabled := false;

  ProjectDeleteBtn.Enabled := false;
  EditCopyBtn.Enabled := false;
  EditPasteBtn.Enabled := false;
  EditVertexBtn.Enabled := false;
  EditReverseBtn.Enabled := false;
  EditConvertBtn.Enabled := false;
  MenuPanelClick(MenuPanel5);
end;

procedure TMainMenuFrame.MenuPanel1MouseEnter(Sender: TObject);
//
//  Shared by MenuPanel1 to MenuPanel6
//
var
  EnteredMenuPanel: TPanel;
begin
  with Sender As TPanel do
    EnteredMenuPanel := TPanel(Sender);
  if EnteredMenuPanel <> MenuPanel then
    EnteredMenuPanel.Color := MenuPanelHoverColor;
end;

procedure TMainMenuFrame.MenuPanel1MouseLeave(Sender: TObject);
//
//  Shared by MenuPanel1 to MenuPanel6
//
var
  LeftMenuPanel: TPanel;
begin
  with Sender As TPanel do
    LeftMenuPanel := TPanel(Sender);
  if LeftMenuPanel <> MenuPanel then
    LeftMenuPanel.Color := MenuBarPanel.Color;
end;

procedure TMainMenuFrame.MenuPanelClick(Sender: TObject);
//
// MenuPanel1 thru MenuPanel6 clicked.
//
var
  NewMenuPanel: TPanel;
begin
  with Sender As TPanel do
    NewMenuPanel := TPanel(Sender);
  MenuPanel.Color := MenuBarPanel.Color;   //config.ThemeColor;
  MenuPanel.Font.Color := clWhite;
  MenuPanel := NewMenuPanel;
  MenuPanel.Color := MenuNotebook.Color;
  MenuPanel.Font.Color := clBlack;
  MenuNotebook.PageIndex := MenuPanel.Tag;
end;

procedure TMainMenuFrame.MenuMeasureItem(Sender: TObject;
  ACanvas: TCanvas; var AWidth, AHeight: Integer);
//
// Sets the height of items displayed in a popup menu.
//
begin
  ACanvas.Font.Name := 'Segoe UI';
  ACanvas.Font.Size := config.FontSize;
  with Sender as TMenuItem do
  begin
    // Distinguish between an item with text and a separator line
    if Caption = '-' then
      aHeight := Scale96ToFont(8)
    else
      aHeight := Scale96ToFont(32);
  end;
end;

procedure TMainMenuFrame.SelectMenuItem(Key: Word);
//
//  Menu hot keys
//
begin
  case Key of
    VK_F:
      MenuPanelClick(MenuPanel1);
    VK_E:
      MenuPanelClick(MenuPanel2);
    VK_V:
      MenuPanelClick(MenuPanel3);
    VK_M:
      MenuPanelClick(MenuPanel4);
    VK_P:
      MenuPanelClick(MenuPanel5);
    VK_H:
      MenuPanelClick(MenuPanel6);
  end;
end;

procedure TMainMenuFrame.SelectProjectMenu;
begin
  MenuPanelClick(MenuPanel5);
end;

//---------------------------------------------------------
//  File menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.FileNewBtnClick(Sender: TObject);
begin
  MainForm.FileNew(True);
end;

procedure TMainMenuFrame.FileOpenBtnClick(Sender: TObject);
begin
  MainForm.FileOpen;
end;

procedure TMainMenuFrame.FilePreferencesBtnClick(Sender: TObject);
begin
  MainForm.FileConfigure;
end;

procedure TMainMenuFrame.FileQuitBtnClick(Sender: TObject);
begin
  MainForm.FileQuit;
end;

procedure TMainMenuFrame.FileSaveAsBtnClick(Sender: TObject);
begin
  MainForm.FileSaveAs;
end;

procedure TMainMenuFrame.FileSaveBtnClick(Sender: TObject);
begin
  MainForm.FileSave;
end;

procedure TMainMenuFrame.ShapefileMenuItemClick(Sender: TObject);
begin
  MainForm.FileImport('shp');
end;

procedure TMainMenuFrame.DxfFileMenuItemClick(Sender: TObject);
begin
  MainForm.FileImport('dxf');
end;

procedure TMainMenuFrame.TextFileMenuItemClick(Sender: TObject);
begin
  MainForm.FileImport('csv');
end;

//---------------------------------------------------------
//  Edit menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.EditCopyBtnClick(Sender: TObject);
begin
  MainForm.ProjectFrame.CopyItem;
  EditPasteBtn.Enabled := True;
end;

procedure TMainMenuFrame.EditPasteBtnClick(Sender: TObject);
begin
  MainForm.ProjectFrame.PasteItem;
end;

procedure TMainMenuFrame.EditReverseBtnClick(Sender: TObject);
var
  Item: Integer;
begin
  Item := MainForm.ProjectFrame.SelectedItem[ctLinks];
  project.ReverseLinkNodes(Item + 1);
  MainForm.ProjectFrame.RefreshPropEditor;
  MainForm.MapFrame.RedrawMap;
end;

procedure TMainMenuFrame.EditVertexBtnClick(Sender: TObject);
begin
  EditVertexBtn.Down := True;
  if config.ShowNotifiers then
    MainForm.ShowHintPanel(rsShapingLink, rsToShapeLink);
  MainForm.MapFrame.EnterVertexingMode;
end;

procedure TMainMenuFrame.GroupEditBtnClick(Sender: TObject);
begin
  GroupEditBtn.Down := True;
  if config.ShowNotifiers then
    MainForm.ShowHintPanel(rsGroupSelect, rsToGroupSelect);
  MainForm.MapFrame.EnterFenceLiningMode('GroupEditing');
end;

procedure TMainMenuFrame.GroupDeleteBtnClick(Sender: TObject);
begin
  GroupDeleteBtn.Down := True;
  if config.ShowNotifiers then
    MainForm.ShowHintPanel(rsGroupSelect, rsToGroupSelect);
  MainForm.MapFrame.EnterFenceLiningMode('GroupEditing');
end;

procedure TMainMenuFrame.ConvertMenuPopup(Sender: TObject);
var
  Item: Integer;
  Category: Integer;
  ObjType: Integer;
begin
  Category := MainForm.ProjectFrame.CurrentCategory;
  Item := MainForm.ProjectFrame.SelectedItem[Category];
  ObjType := project.GetLinkType(Item + 1);
  if ObjType = ltCVPipe then ObjType := ltPipe;
  ToPipeMenuItem.Visible := ObjType <> ltPipe;
  ToPumpMenuItem.Visible := ObjType <> ltPump;
  ToValveMenuItem.Visible := ObjType <> ltValve;
end;

procedure TMainMenuFrame.ConvertMenuItemClick(Sender: TObject);
begin
  with Sender as TMenuItem do
    MainForm.ProjectFrame.ConvertItem(Tag);
end;

//---------------------------------------------------------
//  View menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.ViewAnimateBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.HiliteObject(0, 0);
  AnimationTimer.Enabled := ViewAnimateBtn.Down
end;

procedure TMainMenuFrame.ViewLinkComboChange(Sender: TObject);
begin
  mapthemes.ChangeTheme(MainForm.LegendTreeView, ctLinks, ViewLinkCombo.ItemIndex);
  MainForm.MapFrame.RedrawMap;
  ViewLinkLegendBtn.Enabled := (ViewLinkCombo.ItemIndex > 0);
end;

procedure TMainMenuFrame.ViewLinkLegendBtnClick(Sender: TObject);
begin
  if mapthemes.EditLinkLegend then
  begin
    MainForm.LegendTreeView.Refresh;
    MainForm.MapFrame.RedrawMap;
  end;
end;

procedure TMainMenuFrame.ViewNodeComboChange(Sender: TObject);
begin
  mapthemes.ChangeTheme(MainForm.LegendTreeView, ctNodes, ViewNodeCombo.ItemIndex);
  MainForm.MapFrame.RedrawMap;
  ViewNodeLegendBtn.Enabled := (ViewNodeCombo.ItemIndex > 0);
end;

procedure TMainMenuFrame.ViewNodeLegendBtnClick(Sender: TObject);
begin
  if mapthemes.EditNodeLegend then
  begin
    MainForm.LegendTreeView.Refresh;
    MainForm.MapFrame.RedrawMap;
  end;
end;

procedure TMainMenuFrame.ViewTrackBarChange(Sender: TObject);
begin
  if project.HasResults then
  begin
     ViewTimePanel.Caption := GetViewTime(ViewTrackBar.Position);
     if ViewTrackBar.Tag = 1 then
     begin
       ViewTrackBar.Tag := 0;
       mapthemes.ChangeTimePeriod(ViewTrackBar.Position);
       MainForm.ProjectFrame.UpdateResultsDisplay;
       ReportViewerForm.ChangeTimePeriod;
     end;
  end;
end;

procedure TMainMenuFrame.ViewTrackBarKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
    if Key in
      [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT]
    then ViewTrackBar.Tag := 0;
end;

procedure TMainMenuFrame.ViewTrackBarKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key in
    [VK_LEFT, VK_RIGHT, VK_UP, VK_DOWN, VK_HOME, VK_END, VK_PRIOR, VK_NEXT]
  then
  begin
    ViewTrackBar.Tag := 1;
    ViewTrackBarChange(Sender);
  end;
end;

procedure TMainMenuFrame.ViewTrackBarMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ViewTrackBar.Tag := 0;
end;

procedure TMainMenuFrame.ViewTrackBarMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ViewTrackBar.Tag := 1;
  ViewTrackBarChange(Sender);
end;

procedure TMainMenuFrame.InitViewTimeTrackBar(const N: Integer);
// N = number of time periods in simulation
var
  I: Integer;
begin
  mapthemes.TimePeriod := 0;
  ViewTrackBar.Position:=0;
  ViewTrackBar.Visible := false;
  ViewTimePanel.Caption := '';
  ViewAnimateBtn.Visible := false;
  if N > 0 then
  begin
    I := project.GetStatisticsType;
    if I = 0 then
    begin
      if N > 1 then
      begin
        ViewTrackBar.Visible := True;
        ViewTrackBar.Max := N - 1;
        ViewAnimateBtn.Visible := (N > 1);
        ViewTimePanel.Caption := GetViewTime(0);
      end;
    end
    else
      ViewTimePanel.Caption := rsThemesAre + project.StatisticStr[I];
  end;
end;

procedure TMainMenuFrame.AnimationTimerTimer(Sender: TObject);
begin
  with ViewTrackBar do
  begin
    if Position = Max then
      Position := 0
    else
      Position := Position + 1;
  end;
  mapthemes.ChangeTimePeriod(ViewTrackBar.Position);
  MainForm.ProjectFrame.UpdateResultsDisplay;
  ReportViewerForm.ChangeTimePeriod;
end;

function TMainMenuFrame.GetViewTime(Period: Integer): string;
var
  T: Integer;
begin
  Result := rsTime + results.GetTimeStr(Period);
  T := project.StartTime + (Period * results.Rstep) + results.Rstart;
  Result := Result + '  (' + utils.TimeOfDayStr(T) + ')';
end;

//---------------------------------------------------------
//  Map menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.MapCopyMapBtnClick(Sender: TObject);
begin
  MainForm.HideHintPanelFrames;
  MainForm.ExporterFrame.Init;
  MainForm.ExporterFrame.Show;
end;

procedure TMainMenuFrame.MapExtentsBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.DrawFullExtent;
end;

procedure TMainMenuFrame.MapOptionsBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.EditMapOptions;
end;

procedure TMainMenuFrame.MapQueryBtnClick(Sender: TObject);
begin
  MainForm.HideHintPanelFrames;
  MainForm.QueryFrame.Show;
end;

procedure TMainMenuFrame.MapZoomInBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.ZoomIn(0, 0)
end;

procedure TMainMenuFrame.MapZoomOutBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.ZoomOut(0, 0);
end;

//---------------------------------------------------------
//  Project menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.ProjectAnalyzeBtnClick(Sender: TObject);
var
  SF: TSimulationForm;
begin
  ViewAnimateBtn.Down := false;
  ViewAnimateBtn.Enabled := false;
  AnimationTimer.Enabled := false;
  SF := TSimulationForm.Create(Self);
  try
    SF.ShowModal;
    mapthemes.ResetThemes;
    if project.HasResults then
    begin
      project.ResultsStatus := rsUpToDate;
      MainForm.UpdateStatusBar(sbResults, rsResultsCurrent);
      InitViewTimeTrackBar(results.Nperiods);
      ViewAnimateBtn.Enabled := (results.Nperiods > 1);
      mapthemes.ChangeTimePeriod(0);
      ReportViewerForm.RefreshReport;
    end
    else
    begin
      InitViewTimeTrackBar(0);
      project.ResultsStatus := rsNotAvailable;
      MainForm.UpdateStatusBar(sbResults, rsNoResults);
    end;
    MainForm.ProjectFrame.UpdateResultsDisplay;
    if project.SimStatus in [ssFailed, ssError, ssWarning] then
      ReportViewerForm.ShowReport(rtStatus);
  finally
    SF.Free;
  end;
end;

procedure TMainMenuFrame.ProjectDeleteBtnClick(Sender: TObject);
begin
  MainForm.ProjectFrame.DeleteItem;
  MainForm.MapFrame.RedrawMap;
  MainForm.OverviewMapFrame.Redraw;
  if MainForm.LocaterFrame.Visible then
    MainForm.LocaterFrame.ItemsListbox.Clear;
end;

procedure TMainMenuFrame.ProjectDetailsBtnClick(Sender: TObject);
var
  TmpHasChanged: Boolean;
  ProjectViewer: TProjectViewerForm;
begin
  TmpHasChanged := Project.HasChanged;
  ProjectViewer := TProjectViewerForm.Create(self);
  try
    ProjectViewer.ShowModal;
  finally
    ProjectViewer.Free;
  end;
  Project.HasChanged := TmpHasChanged;
end;

procedure TMainMenuFrame.ProjectFindBtnClick(Sender: TObject);
begin
  if not MainForm.LocaterFrame.Visible then
  begin
    MainForm.HideHintPanelFrames;
    MainForm.LocaterFrame.Show;
  end;
end;

procedure TMainMenuFrame.ProjectSetupBtnClick(Sender: TObject);
begin
  MainForm.ProjectSetup;
end;

procedure TMainMenuFrame.ProjectSummaryBtnClick(Sender: TObject);
var
  ProjectSummarizer: TSummaryForm;
begin
  ProjectSummarizer := TSummaryForm.Create(self);
  try
    ProjectSummarizer.ShowModal;
  finally
    ProjectSummarizer.Free;
  end;
end;

//---------------------------------------------------------
//  Help menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.HelpAboutBtnClick(Sender: TObject);
var
  AboutForm: TAboutForm;
begin
  AboutForm := TAboutForm.Create(self);
  try
    AboutForm.ShowModal;
  finally
    AboutForm.Free;
  end;
end;

procedure TMainMenuFrame.HelpErrorsBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#error_codes');
end;

procedure TMainMenuFrame.HelpTopicsBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('');
end;

procedure TMainMenuFrame.HelpTutorialBtnClick(Sender: TObject);
var
  Url: string;
begin
  Url := 'file:///' + ExtractFilePath(Application.ExeName) + 'tutorial.html';
  OpenUrl(Url);
end;

procedure TMainMenuFrame.HelpUnitsBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#measurement_units');
end;

//---------------------------------------------------------
//  ReportMenu actions
//---------------------------------------------------------

procedure TMainMenuFrame.ReportMenuPopup(Sender: TObject);
begin
  RptPumpItem.Enabled := project.HasResults;
  RptPercentileItem.Enabled := project.HasResults;
  RptEnergyItem.Enabled := project.HasResults;
  RptTseriesItem.Enabled := project.HasResults;
  RptProfileItem.Enabled := project.HasResults;
  RptSysFlowItem.Enabled := project.HasResults;
  RptNetNodesItem.Enabled := project.HasResults;
  RptNetLinksItem.Enabled := project.HasResults;
  RptCalibItem.Enabled := project.HasResults;
  RptFireFlowItem.Enabled := project.HasResults;
end;

procedure TMainMenuFrame.RptCalibItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtCalib);
end;

procedure TMainMenuFrame.RptEnergyItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtEnergy);
end;

procedure TMainMenuFrame.RptFireFlowItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtFireFlow);
end;

procedure TMainMenuFrame.RptNetLinksItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtLinks);
end;

procedure TMainMenuFrame.RptNetNodesItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtNodes);
end;

procedure TMainMenuFrame.RptPercentileItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtPcntile);
end;

procedure TMainMenuFrame.RptProfileItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtProfile);
end;

procedure TMainMenuFrame.RptPumpItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtPumping);
end;

procedure TMainMenuFrame.RptStatusItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtStatus);
end;

procedure TMainMenuFrame.RptSysFlowItemClick(Sender: TObject);
begin
 ReportViewerForm.ShowReport(rtSysFlow);
end;

procedure TMainMenuFrame.RptTseriesItemClick(Sender: TObject);
begin
  ReportViewerForm.ShowReport(rtTimeSeries);
end;

procedure TMainMenuFrame.ToolButton1Click(Sender: TObject);
// This event handler is shared by all buttons on SpeedToolbar1.
begin
  with Sender as TToolButton do
  case Tag of
    1:
      MainForm.FileNew(True);
    2:
      MainForm.FileOpen;
    3:
      MainForm.FileSave;
    4:
      MapExtentsBtnClick(Sender);
    5:
      ProjectAnalyzeBtnClick(Sender);
    // ToolButton6 has a dropdown menu attached to it
    7:
      HelpTopicsBtnClick(Sender);
    8:
      MapZoomInBtnClick(Sender);
    9:
      MapZoomOutBtnClick(Sender);
  end;
end;

//---------------------------------------------------------
//  ObjectMenu actions
//---------------------------------------------------------

procedure TMainMenuFrame.AddNodeItemClick(Sender: TObject);
var
  NodeType: Integer;
begin
  with Sender as TComponent do
    NodeType := Tag;
  if NodeType >= 0 then
  begin
    if config.ShowNotifiers then
      MainForm.ShowHintPanel(rsAddNode, rsToAddNode);
    MainForm.MapFrame.AddNode(NodeType);
  end;
end;

procedure TMainMenuFrame.AddLinkItemClick(Sender: TObject);
var
  LinkType: Integer;
begin
  with Sender as TComponent do
    LinkType := Tag;
  if LinkType >= 0 then
  begin
    if config.ShowNotifiers then
      MainForm.ShowHintPanel(rsAddLink, rsToAddLink);
    MainForm.MapFrame.AddLink(LinkType);
  end;
end;

procedure TMainMenuFrame.AddLabelItemClick(Sender: TObject);
begin
  if config.ShowNotifiers then
    MainForm.ShowHintPanel(rsAddLabel, rsToAddLabel);
  MainForm.MapFrame.Addlabel;
end;

//---------------------------------------------------------
//  BasemapMenu actions
//---------------------------------------------------------

procedure TMainMenuFrame.BasemapMenuPopup(Sender: TObject);
begin
  with MainForm.MapFrame do
  begin
    BasemapUnloadItem.Enabled := HasBaseMap;
    BasemapGeorefItem.Enabled := HasBaseMap and (Length(BaseMapFile) > 0);
    BasemapAlignItem.Enabled := BasemapGeorefItem.Enabled;
    BasemapLightenItem.Enabled := HasBaseMap;
    BasemapGrayscaleItem.Enabled := HasBaseMap;
  end;
end;

procedure TMainMenuFrame.BasemapGeorefItemClick(Sender: TObject);
begin
  MainForm.HideHintPanelFrames;
  MainForm.GeoRefFrame.Show;
end;

procedure TMainMenuFrame.BasemapAlignItemClick(Sender: TObject);
begin
  MainForm.HideHintPanelFrames;
  MainForm.MapAlignFrame.Show;
end;

procedure TMainMenuFrame.BasemapGrayscaleItemClick(Sender: TObject);
begin
  MainForm.MapFrame.Map.Basemap.Grayscale := BasemapGrayscaleItem.Checked;
  MainForm.MapFrame.RedrawMap;
end;

procedure TMainMenuFrame.BasemapLightenItemClick(Sender: TObject);
begin
  with BasemapLightenItem do
  begin
   if Checked then
     MainForm.MapFrame.SetBasemapBrightness(50)
   else
     MainForm.MapFrame.SetBasemapBrightness(0);
  end;
end;

procedure TMainMenuFrame.BasemapLoadItemClick(Sender: TObject);
var
  BMF: TBasemapMenuForm;
begin
  BMF := TBasemapMenuForm.Create(MainForm);
  try
    BMF.ShowModal;
    BMF.Hide;
    if BMF.MapSelection = 0 then
      MainForm.MapFrame.LoadBasemapFromFile
    else if BMF.MapSelection > 0 then
    begin
      MainForm.MapFrame.LoadBasemapFromWeb(
        BMF.MapSelection, BMF.GetEpsg, BMF.GetUnits);
    end;
  finally
    BMF.Free;
  end;
end;

procedure TMainMenuFrame.BasemapUnloadItemClick(Sender: TObject);
begin
  MainForm.MapFrame.UnloadBasemap;
  BasemapGeorefItem.Enabled := false;
  BasemapAlignItem.Enabled := false;
  BasemapLightenItem.Checked := false;
  BasemapGrayscaleItem.Checked := false;
end;

procedure TMainMenuFrame.SetColorTheme;
var
  MenuBarPanelColor: TColor;
begin
  MenuBarPanelColor := MenuBarPanel.Color;
  Color := config.ThemeColor;
  MenuBarPanel.Color := MenuBarPanelColor;
  MenuPanel.Color := MenuNotebook.Color;
end;

procedure TMainMenuFrame.ResetMapThemes;
var
  I: Integer;
  J: Integer;
begin
  J := ViewNodeCombo.ItemIndex;
  if J >= NodeThemeCount then J := 0;
  ViewNodeCombo.Items.Clear;
  for I := 0 to NodeThemeCount - 1 do
    ViewNodeCombo.Items.Add(mapthemes.NodeThemes[I].Name);
  ViewNodeCombo.ItemIndex := J;

  J := ViewLinkCombo.ItemIndex;
  if J >= LinkThemeCount then J := 0;
  ViewLinkCombo.Items.Clear;
  for I := 0 to LinkThemeCount - 1 do
    ViewLinkCombo.Items.Add(mapthemes.LinkThemes[I].Name);
  ViewLinkCombo.ItemIndex := J;

  mapthemes.ChangeTheme(MainForm.LegendTreeView, ctNodes, ViewNodeCombo.ItemIndex);
  ViewNodeLegendBtn.Enabled := (ViewNodeCombo.ItemIndex > 0);
  mapthemes.ChangeTheme(MainForm.LegendTreeView, ctLinks, ViewLinkCombo.ItemIndex);
  ViewLinkLegendBtn.Enabled := (ViewLinkCombo.ItemIndex > 0);
end;

procedure TMainMenuFrame.InitMapThemes;
begin
  ViewNodeCombo.ItemIndex := ntElevation;
  ViewNodeLegendBtn.Enabled := true;
  ViewLinkCombo.ItemIndex := ltDiameter;
  ViewLinkLegendBtn.Enabled := true;
  mapthemes.SetInitialTheme(ctNodes, ntElevation);
  mapthemes.SetInitialTheme(ctLinks, ltDiameter);
  SelectProjectMenu;
end;

procedure TMainMenuFrame.UpdateEditmenuBtns;
var
  BtnEnabled: Boolean;
begin
  BtnEnabled := MainForm.ProjectFrame.CurrentCategory in [ctNodes, ctLinks];
  EditCopyBtn.Enabled := BtnEnabled;
  EditPasteBtn.Enabled := BtnEnabled and
    (MainForm.ProjectFrame.CurrentCategory = MainForm.ProjectFrame.CopiedCategory);

  BtnEnabled := (MainForm.ProjectFrame.CurrentCategory = ctLinks);
  EditVertexBtn.Enabled := BtnEnabled;
  EditReverseBtn.Enabled := BtnEnabled;
  EditConvertBtn.Enabled := BtnEnabled;
end;

end.
