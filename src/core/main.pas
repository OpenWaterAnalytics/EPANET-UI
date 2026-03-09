{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       main
 Description:  main form of a graphical user interface for the
               EPANET water distribution system analysis engine
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
{
 The application's main form consists of several panels as shown
 below that are populated with different Frame components:
 ______________________________________________________________
 |                        MenuPanel                           |
 |____________________________________________________________|
 |               |                             |              |
 |  HintPanel    |                             |              |
 |_______________|         MapPanel            | ProjectPanel |
 |               |                             |              |
 |               |                             |              |
 |LegendTreeView |                             |              |
 |               |                             |              |
 |               |                             |              |
 |_______________|_____________________________|______________|
 |_________________________StatusPanel _______________________|

 MenuPanel - contains the MainMenuFrame used to select various program actions.

 ProjectPanel - contains the ProjectFrame used to navigate through an
 EPANET project's database and edit its properties.

 MapPanel - contains a MapFrame that displays a map of the EPANET pipe
 network being analyzed and handles user interaction with it.

 LeftPanel - contains a HintPanel and a LegendTreeView.

 HintPanel - shares space with several other pop-up panels that are normally
 hidden and are used to display progam instructions or implement map operations.

 LegendTreeView - shows the symbology used to colorize the themes displayed on
 the network map.

 StatusPanel - contains a StatusBarFrame that displays key project properties.
}

unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, ExtCtrls,
  Menus, StdCtrls, Buttons, LCLIntf, LCLtype, ExtDlgs, fileutil,
  ImgList, Themes, IniPropStorage, Math,

  // EPANET-UI units
  mainmenu, mrumanager, projectframe, mapframe, overviewmapframe, statusframe,
  mapgeoref, mapalign, maplocater, mapquery, mapexporter, tseriesselector,
  profileselector, pcntileselector, fireflowselector;

type

  // StatusBar sections
  TStatusBarIndex = (sbAutoLength = 1, sbFlowUnits, sbPressUnits, sbHeadLoss,
                     sbDemands, sbQuality, sbResults, sbXY);

  { TMainForm }

  TMainForm = class(TForm)
    EditingImageList:     TImageList;
    ImportImageList:      TImageList;
    IniPropStorage1:      TIniPropStorage;
    MarkerImageList:      TImageList;
    MaterialImageList:    TImageList;
    PopupImageList:       TImageList;
    MaterialToolbarList:  TImageList;
    LegendImageList:      TImageList;
    WindowImageList:      TImageList;

    MainPanel:            TPanel;
    LegendTitlePanel:     TPanel;
    MenuPanel:            TPanel;
    LeftSpacerPanel:      TPanel;
    MapPanel:             TPanel;
    OverviewPanel:        TPanel;
    StatusPanel:          TPanel;
    Leftpanel:            TPanel;
    HintPanel:            TPanel;
    ProjectPanel:         TPanel;

    HintTitleLabel:       TLabel;
    HintTextLabel:        TLabel;

    LegendTreeView:       TTreeView;
    Splitter2:            TSplitter;

    FontDialog1:          TFontDialog;
    OpenDialog1:          TOpenDialog;
    SaveDialog1:          TSaveDialog;
    SavePictureDialog1:   TSavePictureDialog;

    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDropFiles(Sender: TObject; const FileNames: array of string);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure PopupImageListGetWidthForPPI(Sender: TCustomImageList; AImageWidth,
      APPI: Integer; var AResultWidth: Integer);
    procedure LegendTreeViewSelectionChanged(Sender: TObject);
    procedure MRUMenuMgrRecentFile(Sender: TObject; const AFileName: String);
    procedure StatusPanelPaint(Sender: TObject);

  private
    IsActivated: Boolean;
    AppHelpFile: string;

    procedure CheckBounds;
    procedure CreateFrames;
    procedure InitStatusBar;
    function  GetCmndLineFile: string;
    procedure OpenFile(Filename: string);
    procedure SaveFile(Filename: string);
    function  SaveFileDlg: Integer;
    procedure SetMruFiles;
    procedure ShowWelcomePage;
    procedure StartNewProject;

  public
    MainMenuFrame:         TMainMenuFrame;
    MapFrame :             TMapFrame;
    OverviewMapFrame:      TOverviewMapFrame;
    GeoRefFrame:           TGeoRefFrame;
    MapAlignFrame:         TMapAlignFrame;
    LocaterFrame:          TMapLocaterFrame;
    QueryFrame:            TMapQueryFrame;
    ExporterFrame:         TMapExporterFrame;
    ProjectFrame:          TProjectFrame;
    StatusBarFrame:        TStatusBarFrame;
    ProfileSelectorFrame:  TProfileSelectorFrame;
    TseriesSelectorFrame:  TTseriesSelectorFrame;
    PcntileSelectorFrame:  TPcntileSelectorFrame;
    FireFlowSelectorFrame: TFireFlowSelectorFrame;
    MruMenuMgr:            TMRUMenuManager;
    AppIniFile:            string;

    procedure EnableMainForm(State: Boolean);
    procedure FileConfigure;
    procedure FileImport(FileType: String);
    procedure FileNew(ShowSetupForm: Boolean);
    procedure FileOpen;
    procedure FileQuit;
    procedure FileSave;
    procedure FileSaveAs;
    procedure HideHintPanel;
    procedure HideHintPanelFrames;
    procedure InitFormContents(Filename: String; WebMapSource: Integer);
    procedure ProjectSetup;
    procedure ShowHintPanel(Title: String; Content: String);
    procedure UpdateStatusBar(Index: TStatusBarIndex; S: String);
    procedure UpdateXYStatus(const X: Double; const Y: Double);
    procedure ViewHelp(Topic: String);

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  project, projectloader, projectbuilder, projectsetup, welcome,
  config, inifile, utils, reportviewer, mapthemes, resourcestrings;

{ TmainForm }

{------------------------------------------------------------------------------
  Form Procedures
------------------------------------------------------------------------------}

procedure TMainForm.FormCreate(Sender: TObject);
var
  AppIniDir: string;
begin
  IsActivated := false;
  project.Open;
  MainPanel.Align := alClient;
  MapPanel.Align := alClient;
  CreateFrames;

  Application.HintColor := $00E1FFFF; //00F9F4F0;
  Screen.HintFont.Color := clBlack;
  Screen.HintFont.Size := config.FontSize;
  Application.ShowButtonGlyphs := sbgNever;

  AppHelpFile := 'file:///' + ExtractFilePath(Application.ExeName) + 'manual.html';
  AppIniFile := '';
  AppIniDir := GetAppConfigDir(false);
  if ForceDirectories(AppIniDir) then
  begin
    AppIniFile := AppIniDir + ApplicationName + '.ini';
    config.ReadPreferences(AppIniFile);
  end;
  IniPropStorage1.IniFileName := AppIniFile;

  Font.Size := config.FontSize;
  HintTitleLabel.Font.Style := [fsBold];
  Color := config.ThemeColor;
  HintPanel.Color := $00E1FFFF;
  SetMruFiles;

  // Disable floating point exceptions
  SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide, exOverflow,
    exUnderflow, exPrecision]);
end;

procedure TMainForm.SetMruFiles;
begin
  MruMenuMgr := TMRUMenuManager.Create(self);
  with MruMenuMgr do begin
    MaxRecent := 8;
    PopupMenu := MainMenuFrame.MruMenu;
    MaxItemLength := 80;
    MenuCaptionMask := '%d. %s';
    OnRecentFile := @MRUMenuMgrRecentFile;
    LoadRecentFilesFromIni(AppIniFile, 'MRU_FILES');
  end;
end;

procedure TMainForm.CreateFrames;
begin
  if not Assigned(MainMenuFrame) then
  begin
    MainMenuFrame := TMainMenuFrame.Create(self);
    MainMenuFrame.Parent := MenuPanel;
    MainMenuFrame.Align := alClient;
    MainMenuFrame.Init;
  end;
  if not Assigned(MapFrame) then
  begin
    MapFrame := TMapFrame.Create(self);
    MapFrame.Parent := MapPanel;
    MapFrame.Align := alClient;
    MapFrame.Init;
  end;
  if not Assigned(OverviewMapFrame) then
  begin
    OverviewMapFrame := TOverviewMapFrame.Create(self);
    OverviewMapFrame.Parent := OverviewPanel;
    OverviewMapFrame.Align := alClient;
    OverviewMapFrame.Init;
  end;
  if not Assigned(ProjectFrame) then
  begin
    ProjectFrame := TProjectFrame.Create(self);
    ProjectFrame.Parent := ProjectPanel;
    ProjectFrame.Align := alClient;
  end;
  if not Assigned(StatusBarFrame) then
  begin
    StatusBarFrame := TStatusBarFrame.Create(self);
    StatusBarFrame.Parent := StatusPanel;
    StatusBarFrame.Align := alClient;
    StatusBarFrame.BorderSpacing.Right := 24;
  end;
  if not Assigned(GeoRefFrame) then
  begin
    GeoRefFrame := TGeoRefFrame.Create(self);
    GeoRefFrame.Parent := LeftPanel;
    GeoRefFrame.Align := alTop;
    GeoRefFrame.Visible := false;
  end;
  if not Assigned(MapAlignFrame) then
  begin
    MapAlignFrame := TMapAlignFrame.Create(self);
    MapAlignFrame.Parent := LeftPanel;
    MapAlignFrame.Align := alTop;
    MapAlignFrame.Visible := false;
  end;
  if not Assigned(LocaterFrame) then
  begin
    LocaterFrame := TMapLocaterFrame.Create(self);
    LocaterFrame.Parent := LeftPanel;
    LocaterFrame.Align := alTop;
    LocaterFrame.Visible := false;
  end;
  if not Assigned(QueryFrame) then
  begin
    QueryFrame := TMapQueryFrame.Create(self);
    QueryFrame.Parent := LeftPanel;
    QueryFrame.Align := alTop;
    QueryFrame.Init;
    QueryFrame.Visible := false;
  end;
  if not Assigned(ExporterFrame) then
  begin
    ExporterFrame := TMapExporterFrame.Create(self);
    ExporterFrame.Parent := LeftPanel;
    ExporterFrame.Align := alTop;
    ExporterFrame.Visible := false;
  end;
  if not Assigned(ProfileSelectorFrame) then
  begin
    ProfileSelectorFrame := TProfileSelectorFrame.Create(self);
    ProfileSelectorFrame.Parent := LeftPanel;
    ProfileSelectorFrame.Align := alTop;
    ProfileSelectorFrame.Visible := false;
  end;
  if not Assigned(TseriesSelectorFrame) then
  begin
    TseriesSelectorFrame := TTseriesSelectorFrame.Create(self);
    TseriesSelectorFrame.Parent := LeftPanel;
    TseriesSelectorFrame.Align := alTop;
    TseriesSelectorFrame.Visible := false;
  end;
  if not Assigned(PcntileSelectorFrame) then
  begin
    PcntileSelectorFrame := TPcntileSelectorFrame.Create(self);
    PcntileSelectorFrame.Parent := LeftPanel;
    PcntileSelectorFrame.Align := alTop;
    PcntileSelectorFrame.Visible := false;
  end;
  if not Assigned(FireFlowSelectorFrame) then
  begin
    FireFlowSelectorFrame := TFireFlowSelectorFrame.Create(self);
    FireFlowSelectorFrame.Parent := LeftPanel;
    FireFlowSelectorFrame.Align := alTop;
    FireFlowSelectorFrame.Visible := false;
  end;
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  W, H: Integer;
begin
  // Check that form fits within desktop area
  if self.WindowState <> wsMaximized then
    CheckBounds;

  // Center ReportViewerForm in MainForm
  W := (Self.Width - ReportViewerForm.Width) div 2;
  if W > 0 then
    ReportViewerForm.Left := Self.Left + W;
  H := (Self.Height - ReportViewerForm.Height) div 2;
  if H > 0 then
    ReportViewerForm.Top := Self.Top + H;
  ReportViewerForm.Color := config.ThemeColor;

  ProjectFrame.InitSplit;
  MapFrame.ResizeMap;
end;

procedure TMainForm.PopupImageListGetWidthForPPI(Sender: TCustomImageList;
  AImageWidth, APPI: Integer; var AResultWidth: Integer);
begin
  AResultWidth := AImageWidth * APPI div 96;
end;

procedure TMainForm.FormActivate(Sender: TObject);
var
  Filename: string;
begin
  if IsActivated then exit;
  IsActivated := true;
  StartNewProject;
  FileName := GetCmndLineFile;
  if (Length(Filename) > 0) and FileExists(Filename) then
    OpenFile(Filename)
  else if config.ShowWelcomePage then
    ShowWelcomePage
  else if config.OpenLastFile then
  begin
    if MRUMenuMgr.Recent.Count > 0 then
    begin
      Filename := MRUMenuMgr.Recent[0];
      if FileExists(FileName) then OpenFile(Filename);
    end;
  end;
end;

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  project.Close;
  MapFrame.Close;
  OverviewMapFrame.Close;
  ReportViewerForm.Close;
  if Length(AppIniFile) > 0 then
  begin
  MruMenuMgr.SaveRecentFilesToIni(AppIniFile, 'MRU_FILES');
    config.SavePreferences(AppIniFile);
  end;
  CloseAction := caFree;
  Self.Show;  //For MacOS
end;

procedure TMainForm.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  SetFocus;
  if SaveFileDlg = mrCancel then
    CanClose := false
  else
    CanClose := true;
end;

procedure TMainForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Key applies to Property Editor
  if ProjectFrame.PropEditor.Focused then
    ProjectFrame.PropEditorKeyPress(Key)

  // Key is a main menu hot key
  else if (Shift = [ssAlt]) and MainMenuFrame.Enabled then
    MainMenuFrame.SelectMenuItem(Key)

  // Key signals map object being moved using arrow keys
  else if Shift = [ssCtrl] then
    MapFrame.MoveObjectByPixel(Key)

  // Key applies to a map operation
  else
    MapFrame.GoKeyDown(Key, Shift);
end;

procedure TMainForm.FormDropFiles(Sender: TObject;
  const FileNames: array of string);
begin
  if SaveFileDlg = mrCancel then exit;
  OpenFile(FileNames[0]);
end;

procedure TMainForm.MRUMenuMgrRecentFile(Sender: TObject;
  const AFileName: String);
begin
  if SaveFileDlg = mrCancel then exit;
  if not FileExists(AFileName) then
    utils.MsgDlg(rsFileError, rsFileNoExists, mtInformation, [mbOK], Self)
  else
    OpenFile(AFileName);
end;

procedure TMainForm.StatusPanelPaint(Sender: TObject);
//
// Paint a resizing gripper symbol on the StatusPanel.
//
const
  GRIP_SIZE = 20;
var
  GripSize: Integer;
  R: TRect;
  Details: TThemedElementDetails;
begin
  GripSize := Scale96ToFont(GRIP_SIZE);
  R := Rect(StatusPanel.Width-GripSize, StatusPanel.Height-GripSize,
    StatusPanel.Width, StatusPanel.Height);
  Details := ThemeServices.GetElementDetails(tsGripper);
  ThemeServices.DrawElement(StatusPanel.Canvas.Handle, Details, R);
end;

procedure TMainForm.LegendTreeViewSelectionChanged(Sender: TObject);
begin
  MapFrame.ChangeMapLayer(LegendTreeView);
end;

procedure TMainForm.ShowHintPanel(Title: String; Content: String);
begin
  HideHintPanelFrames;
  HintTitleLabel.Caption:= Title;
  HintTextLabel.Caption := Content;
  HintPanel.Visible := True;
end;

procedure TMainForm.HideHintPanel;
begin
  HintPanel.Hide;
  with ReportViewerForm do
    if Report <> nil then Show;
end;

procedure TMainForm.HideHintPanelFrames;
begin
  GeoRefFrame.Hide;
  MapAlignFrame.Hide;
  LocaterFrame.Hide;
  QueryFrame.CloseBtnClick(Self);
  ExporterFrame.Hide;
  TseriesSelectorFrame.Hide;
  PcntileSelectorFrame.Hide;
  FireFlowSelectorFrame.Hide;
  ReportViewerForm.Hide;
end;

procedure TMainForm.CheckBounds;
var
  WorkArea: TRect;
begin
  // Get the current screen's work area (excludes taskbar)
  WorkArea := Screen.WorkAreaRect;

  // Validate Width
  if Width > WorkArea.Width then
    Width := WorkArea.Width;

  // Validate Height
  if Height > WorkArea.Height then
    Height := WorkArea.Height;

  // Adjust Left (if too far right or too far left)
  if Left + Width > WorkArea.Right then
    Left := WorkArea.Right - Width;
  if Left < WorkArea.Left then
    Left := WorkArea.Left;

  // Adjust Top (if too far down or too far up)
  if Top + Height > WorkArea.Bottom then
    Top := WorkArea.Bottom - Height;
  if Top < WorkArea.Top then
    Top := WorkArea.Top;
end;

{------------------------------------------------------------------------------
  File Menu Procedures
------------------------------------------------------------------------------}
procedure TMainForm.FileImport(FileType: String);
begin
  if SameText(FileType, 'shp') then
    projectBuilder.ImportShapeFile
  else if SameText(FileType, 'dxf') then
    projectBuilder.ImportDxfFile
  else if SameText(FileType, 'csv') then
    projectBuilder.ImportCsvFile;
end;

procedure TMainForm.FileNew(ShowSetupForm: Boolean);
begin
  if SaveFileDlg = mrCancel then exit;
  StartNewProject;
  if ShowSetupForm then ProjectSetup;
end;

procedure TMainForm.FileOpen;
begin
  if SaveFileDlg = mrCancel then exit;
  with OpenDialog1 do
  begin
    Title := rsSelectInpFile;
    Filter := rsInpFileOpen;
    Filename := '*.inp';
    if Execute then OpenFile(Filename);
  end;
end;

procedure TMainForm.FileQuit;
begin
  Close;
end;

procedure TMainForm.FileSaveAs;
begin
  with SaveDialog1 do
  begin
    Filter := rsInpFileOpen;
    if project.InpFile.Length > 0 then
    begin
      InitialDir := ExtractFileDir(project.InpFile);
      FileName := ExtractFileName(project.InpFile);
    end
    else FileName := '*.inp';
    if Execute then SaveFile(FileName);
  end;
end;

procedure TMainForm.SaveFile(FileName: String);
begin
  if project.Save(FileName) then
  begin
    inifile.WriteProjectDefaults(ChangeFileExt(FileName, '.ini'),
      MapFrame.GetWebBasemapSource);
    project.InpFile := FileName;
    Self.Caption := 'EPANET-UI: ' + ChangeFileExt(ExtractFileName(FileName), '');
    MruMenuMgr.AddToRecent(FileName);
  end;
end;

procedure TMainForm.FileSave;
begin
  if project.InpFile.Length > 0 then
  begin
    if project.Save(project.InpFile) then
      inifile.WriteProjectDefaults(ChangeFileExt(Project.InpFile, '.ini'),
        MapFrame.GetWebBasemapSource);
  end
  else
    FileSaveAs;
end;

function TMainForm.SaveFileDlg: Integer;
begin
  Result := mrNo;
  if project.HasChanged then
  begin
    Result := utils.MsgDlg(rsProjectSave, rsSaveChanges,
      mtConfirmation, [mbYes, mbNo, mbCancel], Self);
    if Result = mrYes then
    begin
      FileSave;
    end;
  end
  else if Length(project.InpFile) > 0 then
    inifile.WriteProjectMapOptions(ChangeFileExt(project.InpFile, '.ini'),
        MapFrame.GetWebBasemapSource);
end;

procedure TMainForm.FileConfigure;
var
  ClearFileList: Boolean;
begin
  ClearFileList := false;
  config.EditPreferences(ClearFileList);
  if ClearFileList then
  begin
    MruMenuMgr.Recent.Clear;
    MruMenuMgr.ShowRecentFiles;
  end;
end;

procedure TMainForm.ShowWelcomePage;
var
  StartupAction: Integer;
  StartupFile:   string;
  WelcomeForm:   TWelcomeForm;
begin
  WelcomeForm := TWelcomeForm.Create(Application);
  try
    WelcomeForm.ShowStartPageCB.Checked := config.ShowWelcomePage;
    WelcomeForm.ShowModal;
    WelcomeForm.Hide;
    StartupAction := WelcomeForm.SelectedAction;
    StartupFile := WelcomeForm.SelectedFile;
    config.ShowWelcomePage := WelcomeForm.ShowStartPageCB.Checked;
  finally
    WelcomeForm.Free;
  end;
  case StartupAction of
    saShowTutorial: MainMenuFrame.HelpTutorialBtnClick(self);
    saShowUserGuide: MainMenuFrame.HelpTopicsBtnClick(self);
    saNewProject: ProjectSetup;
    saOpenProject: FileOpen;
    saLoadRecent: MRUMenuMgrRecentFile(self, StartupFile);
  end;
end;

{------------------------------------------------------------------------------
  Status Panel Procedures
------------------------------------------------------------------------------}

procedure TMainForm.InitStatusBar;
begin
  StatusBarFrame.AutoLengthCheckBox.Checked := false;
  StatusBarFrame.SetPanelText(Ord(sbFlowUnits), rsFlowUnitsType + ' ' +
    project.FlowUnitsStr[FlowUnits]);
  StatusBarFrame.SetPanelText(Ord(sbPressUnits), rsPressUnitsType + ' ' +
    project.PressUnitsStr[PressUnits]);                                                                                                               
  StatusBarFrame.SetPanelText(Ord(sbHeadLoss), rsHlossType + ' ' +
    project.DefOptions[htHlossModel]);
  StatusBarFrame.SetPanelText(Ord(sbDemands), rsDemandsDDA);
  StatusBarFrame.SetPanelText(Ord(sbQuality), rsQualityNone);
  StatusBarFrame.SetPanelText(Ord(sbResults), rsNoResults);
  StatusBarFrame.SetPanelText(Ord(sbXY), rsXY);
  StatusBarFrame.SetPanelColor(Ord(sbAutoLength), config.ThemeColor);
  StatusBarFrame.SetPanelColor(Ord(sbResults), config.ThemeColor);
end;

procedure TMainForm.UpdateStatusBar(Index: TStatusBarIndex; S: String);
var
  Txt:    string;
  aColor: TColor;
begin
  case Index of

    sbFlowUnits:
      // Update units shown in LegendTreeView in case unit system changes
      begin
        Txt := rsFlowUnitsType + ' ' + S;
        mapthemes.ChangeTheme(LegendTreeView, ctNodes,
          MainMenuFrame.ViewNodeCombo.ItemIndex);
        mapthemes.ChangeTheme(LegendTreeView, ctLinks,
          MainMenuFrame.ViewLinkCombo.ItemIndex);
      end;

    sbPressUnits:
      begin
        Txt := rsPressUnitsType + ' ' + S;
        mapthemes.ChangeTheme(LegendTreeView, ctNodes,
          MainMenuFrame.ViewNodeCombo.ItemIndex);
      end;

    sbHeadLoss:
      Txt := rsHlossType + ' ' + S;

    sbDemands:
      Txt := rsDemands + ' ' + S;

    sbQuality:
      Txt := rsQuality + ' ' + S;

    sbResults:
      begin
        if SameText(S, rsResultsCurrent) then
          aColor := $001DE6B5
        else if SameText(S, rsNeedUpdating) then
          aColor := $000EC9FF
        else
          aColor := config.ThemeColor;
        StatusBarFrame.SetPanelColor(Ord(Index), aColor);
        Txt := S;
      end;

    else exit;
  end;
  StatusBarFrame.SetPanelText(Ord(Index), Txt);
end;

procedure TMainForm.UpdateXYStatus(const X: Double; const Y: Double);
var
  Lat,
  Lon: string;
  S:   string;
begin
  if project.MapUnits = muDegrees then
  begin
    if Y < 0 then
      Lat := Format('   %.6f°',[-Y]) + ' S, '
    else
      Lat := Format('   %.6f°',[Y]) + ' N, ';
    if X < 0 then
      Lon := Format('   %.6f°',[-X]) + ' W'
    else
      Lon := Format('   %.6f°',[X]) + ' E';
    StatusBarFrame.SetPanelText(Ord(sbXY), Lat + Lon);
  end
  else
  begin
    S := Format('   X, Y: %.6f, %.6f ', [X, Y]);
    if project.MapUnits = muFeet then
      S := S + rsFoot
    else if project.MapUnits = muMeters then
      S := S + rsMeter;
    StatusBarFrame.SetPanelText(Ord(sbXY), S);
  end;
end;

procedure TMainForm.StartNewProject;
var
  TreeNode: TTreeNode;
begin
  ReportViewerForm.CloseReport;
  ReportViewerForm.Hide;
  HideHintPanelFrames;
  project.Clear;
  MapFrame.InitMapOptions;
  MapPanel.Color:= MapFrame.Map.Options.BackColor;
  MapFrame.Clear;
  TreeNode := utils.FindTreeNode(LegendTreeView, rsBasemap);
  if TreeNode <> nil then
    TreeNode.Visible := false;
  OverviewPanel.Visible := false;
  project.Init;
  ProjectFrame.Init;
  InitStatusBar;
  inifile.ReadAppDefaults(AppIniFile);
  project.HasChanged := false;
  Caption := 'EPANET-UI';
  MainMenuFrame.Reset;
end;

procedure TMainForm.ProjectSetup;
var
  SetupForm: TProjectSetupForm;
begin
  SetupForm := TProjectSetupForm.Create(self);
  try
    SetupForm.ShowModal;
    if SetupForm.ModalResult = mrOK then
    begin
      if SetupForm.SaveDefaults then
        inifile.WriteAppDefaults(AppIniFile);
      if SetupForm.RemoveResults then
      begin
        ReportViewerForm.CloseReport;
        ReportViewerForm.Hide;
        project.RemoveResults;
        MapFrame.RedrawMap;
      end;
      with ProjectFrame do
      begin
        CurrentCategory := ctTitle;
        with ProjectTreeView do Select(Items[0]);
        SelectItem(ctTitle, 0);
      end;
    end;
  finally
    SetupForm.Free;
  end;
end;

procedure TMainForm.OpenFile(FileName: String);
var
  Result:     Integer;
  LoaderForm: TProjectLoaderForm;
begin
  StartNewProject;
  if config.BackupFile then
    CopyFile(FileName, FileName + '.bak');

  LoaderForm := TProjectLoaderForm.Create(self);
  try
    LoaderForm.InpFileName := FileName;
    LoaderForm.ShowModal;
    Result := LoaderForm.LoaderResult;
  finally
    LoaderForm.Free;
  end;

  // File opened with non-fatal errrors
  if (Result = 200) then
  begin
    utils.MsgDlg(rsFileError, rsLoadErrors, mtInformation, [mbOk], Self);
    ReportViewerForm.ShowReport(rtStatus);
  end

  // Could not open file
  else if Result > 0 then
  begin
    Caption := 'EPANET-UI';
    utils.MsgDlg(rsFileError, rsNoLoadProject, mtError, [mbOk], Self);
    ReportViewerForm.ShowReport(rtStatus);
  end;
  project.HasChanged := false;
end;

procedure TMainForm.InitFormContents(FileName: String; WebMapSource: Integer);
begin
  MapPanel.Color := MapFrame.Map.Options.BackColor;
  ProjectFrame.Init;

  Caption := 'EPANET-UI: ' + ChangeFileExt(ExtractFileName(FileName), '');
  UpdateStatusBar(sbFlowUnits, project.FlowUnitsStr[project.FlowUnits]);
  UpdateStatusBar(sbPressUnits, project.PressUnitsStr[project.PressUnits]);
  UpdateStatusBar(sbHeadLoss, project.GetHlossModelStr);
  UpdateStatusBar(sbDemands, project.GetDemandModelStr);
  UpdateStatusBar(sbQuality, project.GetQualModelStr);
  UpdateStatusBar(sbResults, rsNoResults);
  UpdateStatusBar(sbXY, '');

  MainMenuFrame.InitMapThemes;
  MruMenuMgr.AddToRecent(FileName);
  MapFrame.LoadBasemapFromWeb(WebMapSource, project.MapEPSG, project.MapUnits);
  MapFrame.DrawFullExtent;

end;

procedure TMainForm.EnableMainForm(State: Boolean);
begin
  MainMenuFrame.Enabled := State;
  ProjectFrame.Enabled := State;
  LegendTreeView.Enabled := State;
  if State then HideHintPanel;
end;

function TMainForm.GetCmndLineFile: string;
//
//  Gets the name of a startup project file on program's command line
//
var
  StartupFile: string = '';
begin
  if ParamCount > 0 then
  begin
    StartupFile := ParamStr(1);
    if Length(ExtractFileDir(StartupFile)) = 0 then
      StartupFile := GetCurrentDir + DirectorySeparator + StartupFile;
  end;
  Result := StartupFile;
end;

procedure TMainForm.ViewHelp(Topic: String);
var
  Url: string;
begin
  Url := AppHelpFile + Topic;
  OpenUrl(Url);
end;

end.
