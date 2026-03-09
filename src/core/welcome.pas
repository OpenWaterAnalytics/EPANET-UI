{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       welcome
 Description:  a form presenting a welcome screen to EPANET users
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit welcome;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, Buttons, LCLtype, LazFileUtils;

type

  { TWelcomeForm }

  TWelcomeForm = class(TForm)
    DevelopBtn1: TSpeedButton;
    DevelopBtn2: TSpeedButton;
    GetStartedBtn1: TSpeedButton;
    GetStartedBtn2: TSpeedButton;
    Image2: TImage;
    ImageList2: TImageList;
    Label4: TLabel;
    Label6: TLabel;
    NoRecentProjectsLbl: TLabel;
    Label2: TLabel;
    Label5: TLabel;
    Panel2: TPanel;
    RecentFileBtn0: TSpeedButton;
    RecentFileBtn1: TSpeedButton;
    RecentFileBtn2: TSpeedButton;
    RecentFileBtn3: TSpeedButton;
    RecentFileBtn4: TSpeedButton;
    RecentFileBtn5: TSpeedButton;
    RecentFileBtn6: TSpeedButton;
    RecentFileBtn7: TSpeedButton;
    ShowStartPageCB: TCheckBox;
    procedure DevelopBtn1Click(Sender: TObject);
    procedure DevelopBtn2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure GetStartedBtn1Click(Sender: TObject);
    procedure GetStartedBtn2Click(Sender: TObject);
    procedure RecentFileBtnClick(Sender: TObject);
  private
    RecentFileCount: Integer;
    RecentFileNames: array [0..7] of String;
    procedure LoadRecentProjects;
  public
    SelectedFile: String;
    SelectedAction: Integer;
  end;

const
  // Startup actions
  saNoAction       = 1;
  saShowTutorial   = 2;
  saShowUserGuide  = 3;
  saNewProject     = 4;
  saOpenProject    = 5;
  saLoadSample     = 6;
  saLoadRecent     = 7;

var
  WelcomeForm: TWelcomeForm;

implementation

{$R *.lfm}

uses
  main, config;

{ TWelcomeForm }

procedure TWelcomeForm.FormCreate(Sender: TObject);
begin
  Color := ThemeColor;
  Font.Size := config.FontSize;

  // The 'No Recent Projects' label shares space with the first
  // Recent File speed button
  NoRecentProjectsLbl.Left := Label4.Left;
  NoRecentProjectsLbl.Top := RecentFileBtn0.Top;
  NoRecentProjectsLbl.Visible := False;

  LoadRecentProjects;
  SelectedAction := saNoAction;
end;

procedure TWelcomeForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ModalResult := mrOK;
  Hide;
end;

procedure TWelcomeForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrOK;
end;

procedure TWelcomeForm.FormShow(Sender: TObject);
begin
  if Screen.PixelsPerInch > 96 then
    Image2.Stretch := true;
end;

procedure TWelcomeForm.GetStartedBtn1Click(Sender: TObject);
begin
  SelectedAction := saShowTutorial;
  ModalResult := mrOK;
end;

procedure TWelcomeForm.GetStartedBtn2Click(Sender: TObject);
begin
  SelectedAction := saShowUserGuide;
  ModalResult := mrOK;
end;

procedure TWelcomeForm.RecentFileBtnClick(Sender: TObject);
begin
 with Sender as TSpeedButton do
  begin
    SelectedFile := RecentFileNames[Tag];
  end;
  SelectedAction := saLoadRecent;
  ModalResult := mrOK;
end;

procedure TWelcomeForm.DevelopBtn1Click(Sender: TObject);
begin
  SelectedAction := saNewProject;
  ModalResult := mrOK;
end;

procedure TWelcomeForm.DevelopBtn2Click(Sender: TObject);
begin
  SelectedAction := saOpenProject;
  ModalResult := mrOK;
end;

procedure TWelcomeForm.LoadRecentProjects;
var
  I: Integer;
  J: Integer;
  S: string;
  SpeedBtn: TSpeedButton;
begin
  J := 0;
  RecentFileCount := 0;
  for I := 0 to MainForm.MruMenuMgr.Recent.Count - 1 do
  begin
    S := MainForm.MruMenuMgr.Recent[I];
    if Length(S) = 0 then break;
    if  not FileExists(S) then continue;
    SpeedBtn := Self.FindComponent('RecentFileBtn' + IntToStr(J)) as TSpeedButton;
    SpeedBtn.Caption := ExtractFilename(S);
    SpeedBtn.Visible := True;
    SpeedBtn.ShowHint := True;
    SpeedBtn.Hint := S;
    RecentFileNames[J] := S;
    Inc(RecentFileCount);
    if J = High(RecentFileNames) then break;
    Inc(J);
  end;
  NoRecentProjectsLbl.Visible := (RecentFileCount = 0);
end;

end.

