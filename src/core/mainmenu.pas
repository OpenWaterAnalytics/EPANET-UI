{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mainmenu
 Description:  a frame containing the program's main menu
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit mainmenu;

{
 This frame is placed on the main form's MenuPanel and serves as the
 application's main menu. Its layout looks as follows:
  __________________________________________________________
 |            |            |      MenuBarPanel             |
 | MenuPanel1 | MenuPanel2 | etc.                          |
 |____________|____________|_______________________________|
 |                                                         |
 |                MenuNotebook                             |
 |_________________________________________________________|

 The MenuBarPanel contains a collection of panels (MenuPanel1 ..
 MenuPanel6) that activate a page of MenuNotebook when clicked on.

 The MenuNotebook contains a collection of pages corresponding to each top
 level menu panel (Page1 for MenuPanel1, Page2 for MenuPanel2, etc.).

 Each MenuNotebook page contains a toolbar (EditToolbar, MapToolbar, etc.)
 with toolbuttons for the menu commands belonging to its coresponding top
 level menu panel.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ComCtrls, ExtCtrls, Buttons,
  Menus, LCLintf, LCLtype, Dialogs, Graphics, ImgList, Clipbrd;

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
    EditConvertBtn:       TToolButton;
    EditCopyBtn:          TToolButton;
    EditPasteBtn:         TToolButton;
    EditReverseBtn:       TToolButton;
    EditSep1:             TToolButton;
    EditSep2:             TToolButton;
    EditToolBar:          TToolBar;
    EditVertexBtn:        TToolButton;
    ExportMapToClipboard: TMenuItem;
    ExportMapToFile:      TMenuItem;
    BasemapAlignItem:     TMenuItem;
    ConvertMenuItem1:     TMenuItem;
    ConvertMenuItem2:     TMenuItem;
    ConvertMenuItem3:     TMenuItem;
    DxfFileMenuItem:      TMenuItem;
    ExportMenu:           TPopupMenu;
    FilePanel:            TPanel;
    GroupDeleteBtn:       TToolButton;
    GroupEditBtn:         TToolButton;
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
    MapSep2:              TToolButton;
    MapToFileMenuItem:    TMenuItem;
    MapToClipbrdMenuItem: TMenuItem;
    MapToolBar:           TToolBar;
    MapZoomInBtn:         TToolButton;
    MapZoomOutBtn:        TToolButton;
    MenuBarPanel:         TPanel;
    MenuNotebook:         TNotebook;
    MenuPanel1:           TPanel;
    MenuPanel2:           TPanel;
    MenuPanel3:           TPanel;
    MenuPanel4:           TPanel;
    MenuPanel5:           TPanel;
    Page1:                TPage;
    Page2:                TPage;
    Page3:                TPage;
    Page4:                TPage;
    Page5:                TPage;
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
    SpeedBar:             TToolBar;
    SpeedPanel:           TPanel;
    TextFileMenuItem:     TMenuItem;
    ShapefileMenuItem:    TMenuItem;
    LinksMenuItem:        TMenuItem;
    NodesMenuItem:        TMenuItem;
    ImportMenu:           TPopupMenu;
    MruMenu:              TPopupMenu;
    GroupEditMenu:        TPopupMenu;
    ToolButton1:          TToolButton;
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
    Panel1:               TPanel;
    ConvertMenu:          TPopupMenu;
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
    Separator2:           TMenuItem;
    Separator3:           TMenuItem;
    Separator4:           TMenuItem;
    Separator5:           TMenuItem;
    Separator6:           TMenuItem;
    Separator7:           TMenuItem;
    Separator8:           TMenuItem;

    procedure AddLabelItemClick(Sender: TObject);
    procedure AddLinkItemClick(Sender: TObject);
    procedure AddNodeItemClick(Sender: TObject);

    procedure BasemapAlignItemClick(Sender: TObject);
    procedure BasemapGeorefItemClick(Sender: TObject);
    procedure BasemapGrayscaleItemClick(Sender: TObject);
    procedure BasemapLightenItemClick(Sender: TObject);
    procedure BasemapLoadItemClick(Sender: TObject);
    procedure BasemapMenuPopup(Sender: TObject);
    procedure BasemapUnloadItemClick(Sender: TObject);
    procedure ConvertMenuItemClick(Sender: TObject);
    procedure ConvertMenuPopup(Sender: TObject);

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
    procedure LinksMenuItemClick(Sender: TObject);

    procedure MapExtentsBtnClick(Sender: TObject);
    procedure MapOptionsBtnClick(Sender: TObject);
    procedure MapQueryBtnClick(Sender: TObject);
    procedure MapToFileMenuItemClick(Sender: TObject);
    procedure MapZoomInBtnClick(Sender: TObject);
    procedure MapZoomOutBtnClick(Sender: TObject);

    procedure MenuPanel1MouseEnter(Sender: TObject);
    procedure MenuPanel1MouseLeave(Sender: TObject);
    procedure MenuPanelClick(Sender: TObject);
    procedure MenuMeasureItem(Sender: TObject; ACanvas: TCanvas;
      var AWidth, AHeight: Integer);
    procedure NodesMenuItemClick(Sender: TObject);
    procedure ObjectMenuPopup(Sender: TObject);

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
    procedure MapToClipbrdMenuItemClick(Sender: TObject);
    procedure ToolButton1Click(Sender: TObject);

  private
    MenuPanel: TPanel;
    procedure ExportMap(FileName: string);

  public
    procedure Init;
    procedure Reset;
    procedure SelectMenuItem(Key: Word);
    procedure SelectProjectMenu;
    procedure SetColorTheme;
    procedure UpdateEditMenuBtns;
  end;

implementation

{$R *.lfm}

uses
  main, filemenu, basemapmenu, project, projectsummary, projectviewer, config,
  mapthemes, simulator, results, reportframe, about, resourcestrings;

const
  MenuPanelHoverColor: TColor =  clHighlight; //00804C23 00D1B499

{ TMainMenuFrame }

procedure TMainMenuFrame.Init;
begin
  Color := clWindow;
  MenuBarPanel.Color := config.MenuColor;
  Font.Size := config.FontSize;
  
  // Start with Project menu
  MenuPanel := MenuPanel4;
  MenuPanelClick(MenuPanel);
end;

procedure TMainMenuFrame.Reset;
//
//  Reset frame contents when a new project is started.
//
begin
  BasemapGrayscaleItem.Checked := false;
  BasemapLightenItem.Checked := false;
  mapthemes.InitThemes;

  ProjectDeleteBtn.Enabled := false;
  EditCopyBtn.Enabled := false;
  EditPasteBtn.Enabled := false;
  EditVertexBtn.Enabled := false;
  EditReverseBtn.Enabled := false;
  EditConvertBtn.Enabled := false;
  MenuPanelClick(MenuPanel4);
end;

procedure TMainMenuFrame.MenuPanel1MouseEnter(Sender: TObject);
//
//  Shared by MenuPanel1 to MenuPanel5
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
//  Shared by MenuPanel1 to MenuPanel5
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
// MenuPanel1 thru MenuPanel5 clicked.
//
var
  NewMenuPanel: TPanel;
begin
  if Assigned(MainForm.FileMenuFrame) then
    MainForm.FileMenuFrame.Visible := false;
  with Sender As TPanel do
    NewMenuPanel := TPanel(Sender);
  MenuPanel.Color := MenuBarPanel.Color;
  MenuPanel.Font.Color := clWhite;
  MenuPanel := NewMenuPanel;
  MenuPanel.Color := MenuNotebook.Color;
  MenuPanel.Font.Color := clBlack;
  MenuNotebook.PageIndex := MenuPanel.Tag;

  // MenuPanel1 is for the File menu, which is displayed in a separate frame
  if MenuPanel.Tag = 0 then
    MainForm.FileMenuFrame.ShowFrame;

  // Show Map page if Edit or Map menu chosen
  case MenuPanel.Tag of
    1, 2: MainForm.ShowPage(MainForm.MapPage);
  end;
end;

procedure TMainMenuFrame.MenuMeasureItem(Sender: TObject;
  ACanvas: TCanvas; var AWidth, AHeight: Integer);
//
// Sets the height of items displayed in a popup menu.
//
begin
  ACanvas.Font.Name := MainForm.Font.Name;
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
    VK_M:
      MenuPanelClick(MenuPanel3);
    VK_P:
      MenuPanelClick(MenuPanel4);
    VK_H:
      MenuPanelClick(MenuPanel5);
  end;
end;

procedure TMainMenuFrame.SelectProjectMenu;
begin
  MenuPanelClick(MenuPanel4);
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
var
  HintStr: string;
begin
  EditVertexBtn.Down := True;
  {$IFDEF Unix}
  HintStr := rsToShowVertices + rsToShapeLink;
  {$ELSE}
  HintStr := rsToShapeLink;
  {$ENDIF}
  MainForm.ShowHintPanel(rsShapingLink, HintStr);
  MainForm.MapFrame.EnterVertexingMode;
end;

procedure TMainMenuFrame.GroupEditBtnClick(Sender: TObject);
begin
  if GroupEditBtn.Down then exit;
end;

procedure TMainMenuFrame.NodesMenuItemClick(Sender: TObject);
begin
  GroupEditBtn.Down := True;
  MainForm.HideHintPanelFrames;
  MainForm.GroupEditorFrame.Init(ctNodes);
end;

procedure TMainMenuFrame.ObjectMenuPopup(Sender: TObject);
begin
  MainForm.ShowPage(MainForm.MapPage);
end;

procedure TMainMenuFrame.LinksMenuItemClick(Sender: TObject);
begin
  GroupEditBtn.Down := True;
  MainForm.HideHintPanelFrames;
  MainForm.GroupEditorFrame.Init(ctLinks);
end;

procedure TMainMenuFrame.GroupDeleteBtnClick(Sender: TObject);
begin
  GroupDeleteBtn.Down := True;
  MainForm.ShowHintPanel(rsGroupSelect, rsToGroupSelect);
  MainForm.MapFrame.EnterFenceLiningMode('GroupDeletion');
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
//  Map menu actions
//---------------------------------------------------------

procedure TMainMenuFrame.MapExtentsBtnClick(Sender: TObject);
var
  StartTime, Elapsed: QWord;
begin
  StartTime := GetTickCount64();
  MainForm.MapFrame.DrawFullExtent;
  Elapsed := GetTickCount64() - StartTime;
//  showmessage(IntToStr(Elapsed) + ' ms');
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
  MainForm.MapViewerFrame.AnimateBtn.Checked := false;
  MainForm.MapViewerFrame.AnimateBtn.Enabled := false;
  MainForm.MapViewerFrame.AnimationTimer.Enabled := false;
  SF := TSimulationForm.Create(Self);
  try
    SF.ShowModal;
    mapthemes.ResetThemes;
    if project.HasResults then
    begin
      project.ResultsStatus := rsUpToDate;
      MainForm.UpdateStatusBar(sbResults, rsResultsCurrent);
      MainForm.MapViewerFrame.InitTimeGroupBox(results.Nperiods);
      mapthemes.ChangeTimePeriod(0);
      if project.SimStatus <> ssWarning then
        MainForm.ReportFrame.RefreshReport;
    end
    else
    begin
      MainForm.MapViewerFrame.InitTimeGroupBox(0);
      project.ResultsStatus := rsNotAvailable;
      MainForm.UpdateStatusBar(sbResults, rsNoResults);
    end;
    MainForm.ProjectFrame.UpdateResultsDisplay;
    if project.SimStatus in [ssFailed, ssError, ssWarning] then
    begin
      MainForm.ReportFrame.CloseReport;
      MainForm.ReportFrame.ShowReport(rtStatus);
    end;
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
  Url := 'file://' + ExtractFilePath(Application.ExeName) + 'tutorial.html';
  {$IFDEF Windows}
  if config.IsDefaultBrowserChromium then
  begin
    Url := '"' + Url + '"';
  end;
  {$ENDIF}
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
  MainForm.ReportFrame.ShowReport(rtCalib);
end;

procedure TMainMenuFrame.RptEnergyItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtEnergy);
end;

procedure TMainMenuFrame.RptFireFlowItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtFireFlow);
end;

procedure TMainMenuFrame.RptNetLinksItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtLinks);
end;

procedure TMainMenuFrame.RptNetNodesItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtNodes);
end;

procedure TMainMenuFrame.RptPercentileItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtPcntile);
end;

procedure TMainMenuFrame.RptProfileItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtProfile);
end;

procedure TMainMenuFrame.RptPumpItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtPumping);
end;

procedure TMainMenuFrame.RptStatusItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtStatus);
end;

procedure TMainMenuFrame.RptSysFlowItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtSysFlow);
end;

procedure TMainMenuFrame.RptTseriesItemClick(Sender: TObject);
begin
  MainForm.ReportFrame.ShowReport(rtTimeSeries);
end;

procedure TMainMenuFrame.ToolButton1Click(Sender: TObject);
//
// This event handler is shared by all buttons on SpeedToolbar1.
//
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

//---------------------------------------------------------
//  ExportMenu actions
//---------------------------------------------------------

procedure TMainMenuFrame.MapToClipbrdMenuItemClick(Sender: TObject);
begin
  ExportMap('');
end;

procedure TMainMenuFrame.MapToFileMenuItemClick(Sender: TObject);
begin
  with MainForm.SavePictureDialog1 do
  begin
    if project.InpFile.Length > 0 then
    begin
      InitialDir := ExtractFileDir(project.InpFile);
      FileName := ChangeFileExt(ExtractFileName(project.InpFile), '.png');
    end;
    if Execute then ExportMap(FileName);
  end;
end;

procedure TMainMenuFrame.ExportMap(FileName: string);
//
//  Paints the network map & its legend onto a bitmap which is either
//  copied to the clipboard or saved to a file.
//
var
  W, H:      Integer;
  Bitmap:    TBitmap;
begin
  with MainForm do
  begin
    H := MapFrame.Height;
    W := MapFrame.Width;
  end;

  // Create a bitmap that will contain the exported map
  Bitmap := TBitmap.Create;
  try
    // Copy the network map's bitmap image into the exported bitmap
    Bitmap.SetSize(W, H);
    MainForm.MapFrame.PaintTo(Bitmap.Canvas, 0, 0);

    // Draw a frame around the exported bitmap
    Bitmap.Canvas.Brush.Style := bsClear;
    Bitmap.Canvas.Rectangle(0, 0, W, H);

    // Send the exported bitmap to either the clipboard or to a file
    if Length(FileName) = 0 then
      Clipboard.Assign(Bitmap)
    else
      Bitmap.SaveToFile(FileName);
  finally
    Bitmap.Free;
  end;
end;

procedure TMainMenuFrame.SetColorTheme;
var
  I: Integer;
begin
  MenuPanel.Color := MenuBarPanel.Color;
  MenuPanel.Font.Color := clWhite;
  for I := 1 to 5 do
  begin
    with FindComponent('MenuPanel' + IntToStr(I)) as TPanel do
      Color := config.MenuColor;
  end;
  MenuBarPanel.Color := config.MenuColor;
  MenuPanelClick(MenuPanel);
end;

procedure TMainMenuFrame.UpdateEditMenuBtns;
//
//  Updates the state of menu items when user selects a network object.
//
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
