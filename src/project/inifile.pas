{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       inifile
 Description:  saves and retrieves project settings to an inifile
 License:      see LICENSE
 Last Updated: 03/07/2026
====================================================================}

unit inifile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Dialogs, StrUtils, Graphics, Forms,
  FileUtil;

procedure ReadAppDefaults(FileName: string);
procedure WriteAppDefaults(FileName: string);
procedure ReadProjectDefaults(FileName: string; var WebMapSource: Integer);
procedure WriteProjectDefaults(FileName: string; WebMapSource: Integer);
procedure WriteProjectMapOptions(FileName: string; WebMapSource:Integer);

implementation

uses
  project, main, mapoptions, mapthemes, epanet2;

const
  BaseDefProps: TDefProps =
    ('0', '20', '50',      // Node elevation, Tank height & diameter
     '1000', '12', '130'); // Pipe length, diameter & roughness

  BaseDefOptions: TDefOptions =
    ('gpm', 'psi', 'H-W',       // Flow & pressure units, head loss model
     '1.0', '1.0', '50',        // Sp. gravity & viscosity, max trials,
     '0.001', '0', '0');        // convergence tolerances

procedure ReadAppDefaults(FileName: string);
var
  I:       Integer;
  Ini:     TIniFile;
  Options: TDefOptions;
begin
  if not FileExists(FileName) then
  begin
    for I := 1 to project.MAX_ID_PREFIXES do
      project.IDprefix[I] := '';
    for I := 1 to project.MAX_DEF_PROPS do
      project.DefProps[I] := BaseDefProps[I];
    for I := 1 to project.MAX_DEF_OPTIONS do
      Options[I] := BaseDefOptions[I];
  end
  else
  begin
    Ini := TIniFile.Create(FileName);
    try
      for I := 1 to project.MAX_ID_PREFIXES do
        project.IDprefix[I] := Ini.ReadString('ID_PREFIXES', IntToStr(I), '');
      for I := 1 to project.MAX_DEF_PROPS do
        project.DefProps[I] := Ini.ReadString('DEFAULTS', IntToStr(I), BaseDefProps[I]);
      for I := 1 to project.MAX_DEF_OPTIONS do
        Options[I] := Ini.ReadString('OPTIONS', IntToStr(I), BaseDefOptions[I]);
    finally
      Ini.Free;
    end;
  end;
  project.SetFlowUnits(Options[htFlowUnits]);
  project.SetPressUnits(Options[htPressUnits]);                                               
  project.SetDefHydOptions(Options);
  epanet2.ENsetoption(EN_STATUS_REPORT, EN_NORMAL_REPORT);
end;

procedure WriteAppDefaults(FileName: string);
var
  I:       Integer;
  Ini:     TIniFile;
  Options: TDefOptions;
begin
  if not FileExists(FileName) then exit;
  Ini := TIniFile.Create(FileName);
  try
    for I := 1 to project.MAX_ID_PREFIXES do
      Ini.WriteString('ID_PREFIXES', IntToStr(I), project.IDprefix[I]);
    for I := 1 to project.MAX_DEF_PROPS do
      Ini.WriteString('DEFAULTS', IntToStr(I), project.DefProps[I]);
    project.GetDefHydOptions(Options);
    for I := 1 to MAX_DEF_OPTIONS do
      Ini.WriteString('OPTIONS', IntToStr(I), Options[I]);
  finally
    Ini.Free;
  end;
end;

procedure ReadProjectDefaults(FileName: string; var WebMapSource: Integer);
var
  I:   Integer;
  Ini: TIniFile;
  S:   string;
begin
  WebMapSource := -1;
  if not FileExists(Filename) then exit;
  Ini := TIniFile.Create(FileName);
  try
    // Project default settings
    for I := 1 to project.MAX_ID_PREFIXES do
      project.IDprefix[I] := Ini.ReadString('ID_PREFIXES', IntToStr(I),
        project.IDprefix[I]);
    for I := 1 to project.MAX_DEF_PROPS do
      project.DefProps[I] := Ini.ReadString('DEFAULTS', IntToStr(I),
        project.DefProps[I]);

    // MSX file name
    S := Ini.ReadString('MSX', 'FILE', '');
    S := AnsiReplaceStr(S, '"', '');
    if Length(S) = 0 then
      project.MsxInpFile := ''
    else if Length(ExtractFilePath(S)) > 0 then
      project.MsxInpFile := S
    else
      project.MsxInpFile := ExtractFilePath(project.InpFile) + S;
    if not FileExists(project.MsxInpFile) then
      project.MsxInpFile := '';

    // Map display options
    with MainForm.MapFrame.Map.Options do
    begin
      NodeSize := Ini.ReadInteger('MAP', 'NODESIZE', DefaultOptions.NodeSize);
      ShowNodesBySize := Ini.ReadBool('MAP', 'SHOWNODESBYSIZE', DefaultOptions.ShowNodesBySize);
      ShowNodeBorder := Ini.ReadBool('MAP', 'SHOWNODEBORDER', DefaultOptions.ShowNodeBorder);
      LinkSize := Ini.ReadInteger('MAP', 'LINKSIZE', DefaultOptions.LinkSize);
      ShowLinksBySize := Ini.ReadBool('MAP', 'SHOWLINKSBYSIZE', DefaultOptions.ShowLinksBySize);
      ShowLinkBorder := Ini.ReadBool('MAP', 'SHOWLINKBORDER', DefaultOptions.ShowLinkBorder);
      S := ColorToString(DefaultOptions.BackColor);
      BackColor := StringToColor(Ini.ReadString('MAP', 'BACKCOLOR', S));
    end;
    WebMapSource := Ini.ReadInteger('MAP', 'WEBMAPSOURCE', -1);

    for I := Low(mapthemes.NodeColors) to High(mapthemes.NodeColors) do
    begin
      S := ColorToString(mapthemes.DefLegendColors[I]);
      mapthemes.NodeColors[I] := StringToColor(
        Ini.ReadString('LEGENDS', 'NODE' + IntToStr(I), S));
    end;
    for I := Low(mapthemes.LinkColors) to High(mapthemes.LinkColors) do
    begin
      S := ColorToString(mapthemes.DefLegendColors[I]);
      mapthemes.LinkColors[I] := StringToColor(
        Ini.ReadString('LEGENDS', 'LINK' + IntToStr(I), S));
    end;
  finally
    Ini.Free;
  end;
  UpdateLegendMarkers(ctNodes, mapthemes.NodeColors);
  UpdateLegendMarkers(ctLinks, mapthemes.LinkColors);
end;

procedure WriteProjectDefaults(FileName: string; WebMapSource: Integer);
var
  I:   Integer;
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
  try

    try
      // Project default settings
      for I := 1 to project.MAX_ID_PREFIXES do
        Ini.WriteString('ID_PREFIXES', IntToStr(I), project.IDprefix[I]);
      for I := 1 to project.MAX_DEF_PROPS do
        Ini.WriteString('DEFAULTS', IntToStr(I), project.DefProps[I]);

      // MSX file name
      if project.MsxFlag then
      begin
        if SameText(ExtractFilePath(project.MsxInpFile),
          ExtractFilePath(project.InpFile))
        then Ini.WriteString('MSX', 'FILE', '"' +
          ExtractFileName(project.MsxInpFile) + '"')
        else Ini.WriteString('MSX', 'FILE', '"' + project.MsxInpFile + '"');
      end
      else
        Ini.WriteString('MSX', 'FILE', '""');
    except
    end;

  finally
    Ini.Free;
  end;

  // Map display options
  WriteProjectMapOptions(FileName, WebMapSource);

end;

procedure WriteProjectMapOptions(FileName: string; WebMapSource:Integer);
var
  I:   Integer;
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
  try

    try
      with MainForm.MapFrame.Map.Options do
      begin
        Ini.WriteInteger('MAP', 'NODESIZE', NodeSize);
        Ini.WriteBool('MAP', 'SHOWNODESBYSIZE', ShowNodesBySize);
        Ini.WriteBool('MAP', 'SHOWNODEBORDER', ShowNodeBorder);
        Ini.WriteInteger('MAP', 'LINKSIZE', LinkSize);
        Ini.WriteBool('MAP', 'SHOWLINKSBYSIZE', ShowLinksBySize);
        Ini.WriteBool('MAP', 'SHOWLINKBORDER', ShowLinkBorder);
        Ini.WriteString('MAP', 'BACKCOLOR', ColorToString(BackColor));
      end;
      Ini.WriteInteger('MAP', 'WEBMAPSOURCE', WebMapSource);

      for I := Low(mapthemes.NodeColors) to High(mapthemes.NodeColors) do
        Ini.WriteString('LEGENDS', 'NODE' + IntToStr(I),
          ColorToString(mapthemes.NodeColors[I]));
      for I := Low(mapthemes.LinkColors) to High(mapthemes.LinkColors) do
        Ini.WriteString('LEGENDS', 'LINK' + IntToStr(I),
          ColorToString(mapthemes.LinkColors[I]));
    except
    end;

  finally
    Ini.Free;
  end;
end;

end.

