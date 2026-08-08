{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       inifile
 Description:  saves and retrieves project settings to an inifile
 License:      see LICENSE
 Last Updated: 06/19/2026
====================================================================}

unit inifile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, IniFiles, Dialogs, StrUtils, Graphics, Forms,
  FileUtil, Types;

procedure ReadAppDefaults(FileName: string);
procedure WriteAppDefaults(FileName: string);
procedure ReadProjectDefaults(FileName: string; var WebMapSource: Integer);
procedure ReadProjectMapOptions(Ini: TIniFile; DS: Char);
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
  I:           Integer;
  Ini:         TIniFile;
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
  project.SetPressureUnits(Options[htPressUnits]);                                               
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
  Ini: TIniFile;
  I:   Integer;
  S:   string;
  DS:  Char;
begin
  WebMapSource := 0;
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

    // Web basemap provider code
    WebMapSource := Ini.ReadInteger('MAP', 'WEBMAPSOURCE', 0);

    // Map display options
    ReadProjectMapOptions(Ini, DS);
  finally
    Ini.Free;
  end;
end;

procedure ReadMapThemeIntervals(Ini: TIniFile; DS: Char);
var
  I,
  J,
  Code:   Integer;
  S:      string;
  V:      Single;
  Tokens: TStringArray;
begin
  // For each node theme (excluding quality themes)
  for I := 1 to mapthemes.FirstNodeQualTheme-1 do
  begin
    // Read concatenated list of intervals for theme I
    S := Ini.ReadString('THEMES', 'NODE' + IntToStr(I), '');
    if Length(S) = 0 then continue;

    // Split the intervals string into individual interval string values
    Tokens := SplitString(S, '-');

    // For each interval string value
    for J := 0 to Length(Tokens) - 1 do
    begin
      // Replace the string's decimal separator if necessary
      Tokens[J] := StringReplace(Tokens[J], '.', DS, []);

      // Convert the string value to a numerical value
      Val(Tokens[J], V, Code);
      if Code <> 0 then continue;

      // Replace the theme's NodeIntervals entries
      mapthemes.NodeIntervals[I].Labels[J+1] := Tokens[J];
      mapthemes.NodeIntervals[I].Values[J+1] := V;
    end;
  end;

  // Repeat the above process for Link themes
  for I := 1 to mapthemes.FirstLinkQualTheme-1 do
  begin
    S := Ini.ReadString('THEMES', 'LINK' + IntToStr(I), '');
    if Length(S) = 0 then continue;
    Tokens := SplitString(S, '-');
    for J := 0 to Length(Tokens) - 1 do
    begin
      Tokens[J] := StringReplace(Tokens[J], '.', DS, []);
      Val(Tokens[J], V, Code);
      if Code <> 0 then continue;
      mapthemes.LinkIntervals[I].Labels[J+1] := Tokens[J];
      mapthemes.LinkIntervals[I].Values[J+1] := V;
    end;
  end;
end;

procedure ReadProjectMapOptions(Ini: TIniFile; DS: Char);
var
  I:   Integer;
  P:   TPoint;
  S: string;
begin
  // Map drawing options
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

  // Map theme colors
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

  // Map legend positions
  P.X := Ini.ReadInteger('LEGENDS', 'NODE_LEFT', 0);
  P.Y := Ini.ReadInteger('LEGENDS', 'NODE_TOP', 0);
  MainForm.MapFrame.NodeLegend.SetLocation(P);
  MainForm.MapViewerFrame.NodeLegendBox.Checked :=
    Ini.ReadBool('LEGENDS', 'NODE_VISIBLE', false);
  MainForm.MapFrame.NodeLegend.Framed :=
    Ini.ReadBool('LEGENDS', 'NODE_FRAMED', true);
  P.X := Ini.ReadInteger('LEGENDS', 'LINK_LEFT', 0);
  P.Y := Ini.ReadInteger('LEGENDS', 'LINK_TOP', 10);
  MainForm.MapFrame.LinkLegend.SetLocation(P);
  MainForm.MapViewerFrame.LinkLegendBox.Checked :=
    Ini.ReadBool('LEGENDS', 'LINK_VISIBLE', false);
  MainForm.MapFrame.LinkLegend.Framed :=
    Ini.ReadBool('LEGENDS', 'LINK_FRAMED', true);

  // Map theme intervals
  ReadMapThemeIntervals(Ini, DS);
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
  I:   Integer;
  J:   Integer;
  P:   TPoint;
  S:   string;
  Lbl: string;
  DS:  char;
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

      P := MainForm.MapFrame.NodeLegend.GetLocation;
      Ini.WriteInteger('LEGENDS', 'NODE_LEFT', P.X);
      Ini.WriteInteger('LEGENDS', 'NODE_TOP', P.Y);
      Ini.WriteBool('LEGENDS', 'NODE_VISIBLE',
        MainForm.MapViewerFrame.NodeLegendBox.Checked);
      Ini.WriteBool('LEGENDS', 'NODE_FRAMED',
        MainForm.MapFrame.NodeLegend.Framed);

      P := MainForm.MapFrame.LinkLegend.GetLocation;
      Ini.WriteInteger('LEGENDS', 'Link_LEFT', P.X);
      Ini.WriteInteger('LEGENDS', 'Link_TOP', P.Y);
      Ini.WriteBool('LEGENDS', 'LINK_VISIBLE',
        MainForm.MapViewerFrame.LinkLegendBox.Checked);
      Ini.WriteBool('LEGENDS', 'LINK_FRAMED',
        MainForm.MapFrame.LinkLegend.Framed);

      DS := DefaultFormatSettings.DecimalSeparator;
      for I := 1 to mapthemes.FirstNodeQualTheme-1 do
      begin
        Lbl := mapthemes.NodeIntervals[I].Labels[1];
        S := StringReplace(Lbl, DS, '.', []);
        for J := 2 to mapthemes.MAXLEVELS do
        begin
          Lbl := mapthemes.NodeIntervals[I].Labels[J];
          S := S + '-' + StringReplace(Lbl, DS, '.', []);
        end;
        Ini.WriteString('THEMES', 'NODE' + IntToStr(I), S);
      end;

      for I := 1 to mapthemes.FirstLinkQualTheme-1 do
      begin
        Lbl := mapthemes.LinkIntervals[I].Labels[1];
        S := StringReplace(Lbl, DS, '.', []);
        for J := 2 to mapthemes.MAXLEVELS do
        begin
          Lbl := mapthemes.LinkIntervals[I].Labels[J];
          S := S + '-' + StringReplace(Lbl, DS, '.', []);
        end;
        Ini.WriteString('THEMES', 'LINK' + IntToStr(I), S);
      end;

    except
    end;

  finally
    Ini.Free;
  end;
end;

end.

