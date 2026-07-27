{====================================================================
 project:      EPANET-UI
 Version:      1.0.3
 Module:       projectloader
 Description:  form that loads an EPANET input file
 License:      see LICENSE
 Last Updated: 06/19/2026
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
  WebMapSource := 0;
  inifile.ReadProjectDefaults(ChangeFileExt(InpFileName, '.ini'), WebMapSource);
  if (WebMapSource > 0) then
  begin
    // Check for internet connection
    Panel1.Caption := rsLoadBasemap;
    if (not utils.HasInternetConnection()) then
      WebMapSource := 0

    // Set map CRS to WGS84 (EPSG 4326) if no CRS set and map units are degrees
    else if project.MapEPSG = 0 then
    begin
      if project.MapUnits <> muDegrees then
        WebMapSource := 0
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

