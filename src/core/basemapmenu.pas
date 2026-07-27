{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       basemapmenu
 Description:  a form with a visual menu of basemap sources
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit basemapmenu;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, Buttons,
  StdCtrls, ExtCtrls, LCLtype, LCLintf, HtmlView, HtmlGlobals;

type

  { TBasemapMenuForm }

  TBasemapMenuForm = class(TForm)
    ImageFileBtn:       TBitBtn;
    BitBtn2:            TBitBtn;
    BitBtn3:            TBitBtn;
    BitBtn4:            TBitBtn;
    BitBtn5:            TBitBtn;
    Notebook1:          TNotebook;
    Notebook2:          TNotebook;
    Page1:              TPage;
    Page2:              TPage;
    Page3:              TPage;
    Page4:              TPage;
    Timer1:             TTimer;
    UnitsComboBox:      TComboBox;
    EpsgEdit:           TEdit;
    ImageFileBox:       TGroupBox;
    WebMapBox:          TGroupBox;
    Label1:             TLabel;
    InternetLabel:      TLabel;
    Label3:             TLabel;
    HelpBtn:            TSpeedButton;
    ImageList1:         TImageList;
    ImageList2:         TImageList;
    EpsgHelpViewer:     THtmlViewer;
    EpsgHelpCloseLabel: TLabel;
    EpsgHelpClosePanel: TPanel;
    WebMapPanel:        TPanel;

    procedure ImageFileBtnClick(Sender: TObject);
    procedure EpsgEditExit(Sender: TObject);
    procedure EpsgHelpCloseLabelClick(Sender: TObject);
    procedure EpsgEditChange(Sender: TObject);
    procedure EpsgHelpViewerHotSpotClick(Sender: TObject; const SRC: ThtString;
      var Handled: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);

  private
    procedure EnableUnitsComboBox;

  public
    MapSelection:      Integer;
    HasInternet:       Boolean;
    procedure Setup;
    function  GetEpsg:  Integer;
    function  GetUnits: Integer;
  end;

var
  BasemapMenuForm: TBasemapMenuForm;

implementation

{$R *.lfm}

uses
  main, project, config, utils, resourcestrings;

const
  EpsgHelp: String = rsEpsgHelp;

{ TBasemapMenuForm }

procedure TBasemapMenuForm.FormCreate(Sender: TObject);
begin
  Font.Size := config.FontSize;
  {$IFDEF LINUX}
  Color := clWindow;
  {$ENDIF}
  {$IFDEF WINDOWS}
  Color := config.ThemeColor;
  {$ENDIF}
  MapSelection := -1;
  WebMapPanel.Enabled := False;
  Notebook1.PageIndex := 0;

  // Display checking internet connection label
  if not MainForm.MapFrame.HasWebBasemap then
  begin
    Notebook1.PageIndex := 1;
    InternetLabel.Caption := rsCheckInternet;
  end;

  // Set up the contents of the help viewer
  EpsgHelpViewer.DefFontSize := config.FontSize;
  EpsgHelpViewer.DefBackground := $00E0FFFF;
  EpsgHelpViewer.LoadFromString(EpsgHelp);
  EpsgHelpClosePanel.Color := $00E0FFFF;
  HasInternet := False;
end;

procedure TBasemapMenuForm.Setup;
begin
  // Check for internet connection
  if not MainForm.MapFrame.HasWebBasemap then
  begin
    HasInternet := utils.HasInternetConnection;
    if not HasInternet then
    begin
      Notebook1.PageIndex := 1;
      InternetLabel.Caption := rsNoInternet;
      exit;
    end;
  end;

  // Project is empty - EPSG & units are fixed
  Notebook1.PageIndex := 0;
  if project.IsEmpty then
  begin
    WebMapPanel.Enabled := True;
    EpsgEdit.Enabled := False;
    EpsgEdit.Text := '4326';
    UnitsComboBox.Enabled := False;
    UnitsComboBox.ItemIndex := muDegrees;
  end

  // Project not empty -- user can assign EPSG & units if no web basemap
  else
  begin
    if project.MapEPSG > 0 then
       EpsgEdit.Text := IntToStr(project.MapEPSG);
    if project.MapUnits <> muNone then
      UnitsComboBox.ItemIndex := project.MapUnits
    else
      UnitsComboBox.ItemIndex := 0;
    if MainForm.MapFrame.HasWebBasemap = false then
    begin
      if (project.MapUnits = muDegrees) and (project.MapEPSG = 0) then
        EpsgEdit.Text := '4326';
    end;
    EpsgEdit.Enabled := True;
    UnitsComboBox.Enabled := True;
  end;
  EnableUnitsComboBox;
end;

procedure TBasemapMenuForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    if Notebook2.PageIndex = 1 then
      Notebook2.PageIndex := 0
    else
      ModalResult := mrOK;
  end;
end;

procedure TBasemapMenuForm.FormShow(Sender: TObject);
//
// Create a short pause before the Setup procedure is called.
//
begin
  Timer1.Enabled := true;
end;

procedure TBasemapMenuForm.HelpBtnClick(Sender: TObject);
begin
  with Notebook2 do
    if PageIndex = 0 then
      PageIndex := 1
    else
      PageIndex := 0;
end;

procedure TBasemapMenuForm.Timer1Timer(Sender: TObject);
begin
  Timer1.Enabled := false;
  Setup;
end;

procedure TBasemapMenuForm.ImageFileBtnClick(Sender: TObject);
begin
  with Sender as TBitBtn do MapSelection := Tag;
  ModalResult := mrOK;
end;

procedure TBasemapMenuForm.EpsgHelpCloseLabelClick(Sender: TObject);
begin
  Notebook2.PageIndex := 0;
end;

function TBasemapMenuForm.GetEpsg: Integer;
begin
  Result := StrToIntDef(EpsgEdit.Text, 0);
end;

function TBasemapMenuForm.GetUnits: Integer;
begin
  if UnitsComboBox.ItemIndex < 0 then
    Result := muNone
  else
    Result := UnitsComboBox.ItemIndex;
end;

procedure TBasemapMenuForm.EpsgEditExit(Sender: TObject);
begin
  WebMapPanel.Enabled := Length(EpsgEdit.Text) > 0;
  EnableUnitsComboBox;
end;

procedure TBasemapMenuForm.EpsgEditChange(Sender: TObject);
begin
  WebMapPanel.Enabled := Length(EpsgEdit.Text) > 0;
  EnableUnitsComboBox;
end;

procedure TbasemapMenuForm.EnableUnitsComboBox;
begin
  if SameText(EpsgEdit.Text, '4326') then
  begin
    UnitsComboBox.ItemIndex := muDegrees;
    UnitsComboBox.Enabled := false;
  end
  else
    UnitsComboBox.Enabled := true;
end;

procedure TBasemapMenuForm.EpsgHelpViewerHotSpotClick(Sender: TObject;
  const SRC: ThtString; var Handled: Boolean);
begin
  OpenUrl('https://spatialreference.org/');
end;

end.

