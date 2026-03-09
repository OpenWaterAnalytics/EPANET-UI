{====================================================================
 project:      EPANET-UI
 Version:      1.0.0
 Module:       projectloader
 Description:  form that loads an EPANET input file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit projectloader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls;

type
  { TProjectLoaderForm }

  TProjectLoaderForm = class(TForm)
    Panel1: TPanel;
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private
    function GetWebMapSource: Integer;
    procedure SetMsxFlag;

  public
    InpFileName: string;
    LoaderResult: Integer;
  end;

var
  ProjectLoaderForm: TProjectLoaderForm;

implementation

{$R *.lfm}

uses
  main, project, config, inifile, utils, resourcestrings;

{ TProjectLoaderForm }

procedure TProjectLoaderForm.FormActivate(Sender: TObject);
var
  WebMapSource: Integer;
begin
  Application.ProcessMessages;
  LoaderResult := project.Load(InpFileName);
  if LoaderResult in [0, 200] then
  begin
    WebMapSource := GetWebMapSource;
    SetMsxFlag;
    MainForm.InitFormContents(InpFileName, WebMapSource);
  end;
  ModalResult := mrOK;
end;

procedure TProjectLoaderForm.FormCreate(Sender: TObject);
begin
  Font.Size := config.FontSize;
end;

function TProjectLoaderForm.GetWebMapSource: Integer;
var
  WebMapSource: Integer;  // Web map service provider code (see webmap.pas)
begin
  // Check for valid web basemap source
  WebMapSource := -1;
  inifile.ReadProjectDefaults(ChangeFileExt(InpFileName, '.ini'), WebMapSource);
  if (WebMapSource >= 0) then
  begin
    Panel1.Caption := rsLoadBasemap;
    Application.ProcessMessages;
    if (not utils.HasInternetConnection()) then
      WebMapSource := -1

    else if project.MapEPSG = 0 then
    begin
      if project.MapUnits <> muDegrees then
        WebMapSource := -1
      else
        project.MapEPSG := 4326;
    end;
  end;
  Result := WebMapSource;
end;

procedure TProjectLoaderForm.SetMsxFlag;
begin
  if SameText(project.GetQualModelStr, rsNoQuality)
  and FileExists(project.MsxInpFile) then
    project.MsxFlag := true;
end;

end.

