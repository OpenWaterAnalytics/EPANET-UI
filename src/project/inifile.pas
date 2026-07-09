{====================================================================
 Project:      EPANET-UI
 Version:      1.0.2
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
procedure ReadLegendIntervals(FileName: string);
procedure ReadBasemapStyle(FileName: string);

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
  I:           Integer;
  Ini:         TIniFile;
  Props:       TDefProps;
  BaseProps:   TDefProps;
  Options:     TDefOptions;
  BaseOptions: TDefOptions;
  DS:          Char;
begin
  // Adjust base defaults for decimal separator
  DS := DefaultFormatSettings.DecimalSeparator;
  BaseOptions := BaseDefOptions;
  for I := 1 to project.MAX_DEF_OPTIONS do
    BaseOptions[I] := StringReplace(BaseOptions[I], '.', DS, []);
  BaseProps := BaseDefProps;
  for I := 1 to project.MAX_DEF_PROPS do
    BaseProps[I] := StringReplace(BaseProps[I], '.', DS, []);

  // Set project defaults to base values if no INI file
  if not FileExists(FileName) then
  begin
    for I := 1 to project.MAX_ID_PREFIXES do
      project.IDprefix[I] := '';
    for I := 1 to project.MAX_DEF_PROPS do
      project.DefProps[I] := BaseProps[I];
    for I := 1 to project.MAX_DEF_OPTIONS do
      Options[I] := BaseOptions[I];
  end
  else

  // Read project defaults from INI file
  begin
    Ini := TIniFile.Create(FileName);
    try
      for I := 1 to project.MAX_ID_PREFIXES do
        project.IDprefix[I] := Ini.ReadString('ID_PREFIXES', IntToStr(I), '');

      for I := 1 to project.MAX_DEF_PROPS do
      begin
        project.DefProps[I] := Ini.ReadString('DEFAULTS', IntToStr(I), BaseDefProps[I]);
        project.DefProps[I] := StringReplace(project.DefProps[I], '.', DS, []);
      end;

      for I := 1 to project.MAX_DEF_OPTIONS do
      begin
        Options[I] := Ini.ReadString('OPTIONS', IntToStr(I), BaseDefOptions[I]);
        Options[I] := StringReplace(Options[I], '.', DS, []);
      end;
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
  Props:   TDefProps;
  Options: TDefOptions;
  DS:      Char;
begin
  if not FileExists(FileName) then exit;
  DS := DefaultFormatSettings.DecimalSeparator;
  Ini := TIniFile.Create(FileName);
  try
    for I := 1 to project.MAX_ID_PREFIXES do
      Ini.WriteString('ID_PREFIXES', IntToStr(I), project.IDprefix[I]);

    Props := project.DefProps;
    for I := 1 to project.MAX_DEF_PROPS do
    begin
      Props[I] := StringReplace(Props[I], DS, '.', []);
      Ini.WriteString('DEFAULTS', IntToStr(I), Props[I]);
    end;

    project.GetDefHydOptions(Options);
    for I := 1 to MAX_DEF_OPTIONS do
    begin
      Options[I] := StringReplace(Options[I], DS, '.', []);
      Ini.WriteString('OPTIONS', IntToStr(I), Options[I]);
    end;
  finally
    Ini.Free;
  end;
end;

procedure ReadProjectDefaults(FileName: string; var WebMapSource: Integer);
var
  I:   Integer;
  Ini: TIniFile;
  S:   string;
  DS:  Char;
begin
  WebMapSource := -1;
  if not FileExists(Filename) then exit;
  DS := DefaultFormatSettings.DecimalSeparator;
  Ini := TIniFile.Create(FileName);
  try
    // Project default settings
    for I := 1 to project.MAX_ID_PREFIXES do
      project.IDprefix[I] := Ini.ReadString('ID_PREFIXES', IntToStr(I),
        project.IDprefix[I]);
    for I := 1 to project.MAX_DEF_PROPS do
    begin
      project.DefProps[I] := Ini.ReadString('DEFAULTS', IntToStr(I),
        project.DefProps[I]);
      project.DefProps[I] := StringReplace(project.DefProps[I], '.', DS, []);
    end;

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
  I:     Integer;
  Ini:   TIniFile;
  Props: TDefProps;
  DS:    Char;
begin
  Ini := TIniFile.Create(FileName);
  try

    try
      // Project default settings
      for I := 1 to project.MAX_ID_PREFIXES do
        Ini.WriteString('ID_PREFIXES', IntToStr(I), project.IDprefix[I]);
      Props := project.DefProps;
      for I := 1 to project.MAX_DEF_PROPS do
      begin
        Props[I] := StringReplace(Props[I], DS, '.', []);
        Ini.WriteString('DEFAULTS', IntToStr(I), Props[I]);
      end;

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
  I, J: Integer;
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
      Ini.WriteBool('MAP', 'GRAYSCALE', MainForm.MapFrame.Map.Basemap.Grayscale);
      Ini.WriteInteger('MAP', 'BRIGHTNESS', MainForm.MapFrame.Map.Basemap.Brightness);

      for I := Low(mapthemes.NodeColors) to High(mapthemes.NodeColors) do
        Ini.WriteString('LEGENDS', 'NODE' + IntToStr(I),
          ColorToString(mapthemes.NodeColors[I]));
      for I := Low(mapthemes.LinkColors) to High(mapthemes.LinkColors) do
        Ini.WriteString('LEGENDS', 'LINK' + IntToStr(I),
          ColorToString(mapthemes.LinkColors[I]));

      // Legend interval thresholds (labels + values), one INI section per theme
      for I := 0 to Length(mapthemes.NodeIntervals)-1 do
        for J := 1 to mapthemes.MAXLEVELS do
        begin
          Ini.WriteString('NODE_INTERVALS_' + IntToStr(I),
            'LABEL' + IntToStr(J), mapthemes.NodeIntervals[I].Labels[J]);
          Ini.WriteFloat('NODE_INTERVALS_' + IntToStr(I),
            'VALUE' + IntToStr(J), mapthemes.NodeIntervals[I].Values[J]);
        end;
      for I := 0 to Length(mapthemes.LinkIntervals)-1 do
        for J := 1 to mapthemes.MAXLEVELS do
        begin
          Ini.WriteString('LINK_INTERVALS_' + IntToStr(I),
            'LABEL' + IntToStr(J), mapthemes.LinkIntervals[I].Labels[J]);
          Ini.WriteFloat('LINK_INTERVALS_' + IntToStr(I),
            'VALUE' + IntToStr(J), mapthemes.LinkIntervals[I].Values[J]);
        end;
    except
    end;

  finally
    Ini.Free;
  end;
end;

procedure ReadLegendIntervals(FileName: string);
//
// Restores legend interval thresholds and basemap grayscale style.
// Must be called AFTER mapthemes.InitThemes has already populated
// NodeIntervals/LinkIntervals with their default values, since this
// procedure only overwrites entries that already exist in those arrays.
//
var
  I, J: Integer;
  Ini: TIniFile;
begin
  if not FileExists(FileName) then exit;
  Ini := TIniFile.Create(FileName);
  try
    try
      for I := 0 to Length(mapthemes.NodeIntervals)-1 do
        for J := 1 to mapthemes.MAXLEVELS do
        begin
          mapthemes.NodeIntervals[I].Labels[J] := Ini.ReadString(
            'NODE_INTERVALS_' + IntToStr(I), 'LABEL' + IntToStr(J),
            mapthemes.NodeIntervals[I].Labels[J]);
          mapthemes.NodeIntervals[I].Values[J] := Ini.ReadFloat(
            'NODE_INTERVALS_' + IntToStr(I), 'VALUE' + IntToStr(J),
            mapthemes.NodeIntervals[I].Values[J]);
        end;
      for I := 0 to Length(mapthemes.LinkIntervals)-1 do
        for J := 1 to mapthemes.MAXLEVELS do
        begin
          mapthemes.LinkIntervals[I].Labels[J] := Ini.ReadString(
            'LINK_INTERVALS_' + IntToStr(I), 'LABEL' + IntToStr(J),
            mapthemes.LinkIntervals[I].Labels[J]);
          mapthemes.LinkIntervals[I].Values[J] := Ini.ReadFloat(
            'LINK_INTERVALS_' + IntToStr(I), 'VALUE' + IntToStr(J),
            mapthemes.LinkIntervals[I].Values[J]);
        end;
    except
    end;
  finally
    Ini.Free;
  end;
end;

procedure ReadBasemapStyle(FileName: string);
//
// Restores the basemap's grayscale/brightness display style.
// Must be called AFTER MapFrame.LoadBasemapFromWeb, since loading a
// basemap resets Grayscale to false and Brightness to 0 as part of
// its own initialization.
//
var
  Ini: TIniFile;
begin
  if not FileExists(FileName) then exit;
  Ini := TIniFile.Create(FileName);
  try
    try
      MainForm.MapFrame.Map.Basemap.Grayscale := Ini.ReadBool(
        'MAP', 'GRAYSCALE', MainForm.MapFrame.Map.Basemap.Grayscale);
      MainForm.MapFrame.Map.Basemap.Brightness := Ini.ReadInteger(
        'MAP', 'BRIGHTNESS', MainForm.MapFrame.Map.Basemap.Brightness);
      MainForm.MapFrame.Map.Basemap.NeedsRedraw := true;
    except
    end;
  finally
    Ini.Free;
  end;
end;

end.

