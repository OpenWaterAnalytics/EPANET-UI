{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       config
 Description:  reads, saves and edits program preferences
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit config;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Graphics, SysUtils, Controls, Forms, IniFiles, ExtCtrls, LCLIntf;

const
  WinFontSize = 9;
  NixFontSize = 9;

  GrayTheme: Integer       = $00F3F3F3;
  BlueTheme: Integer       = $00FDEEE3;
  CreamTheme: Integer      = $00F0FBFF;
  GrayMenuColor: Integer   = $007E7969;
  GrayHeaderColor: Integer = $007E7969;
  BlueMenuColor: Integer   = $00BE6E10;
  BlueHeaderColor: Integer = $00BE6E10;

  MonoFonts: array[1..3] of string =
    ('Noto Mono', 'Liberation Mono', 'DejaVu Sans Mono');

var
  MapHiliter:        Boolean;
  MapHinting:        Boolean;
  ShowNotifiers:     Boolean;
  ConfirmDeletions:  Boolean;
  ShowWelcomePage:   Boolean;
  OpenLastFile:      Boolean;
  BackupFile:        Boolean;
  ThemeColor:        TColor;
  FormColor:         TColor;
  MenuColor:         TColor;
  HeaderColor:       TColor;
  AlternateColor:    TColor;
  DecimalPlaces:     Integer;
  FontSize:          Integer;
  MonoFont:          string;
  IconFamily:        string;

  procedure ReadPreferences(FileName: string);
  procedure SavePreferences(FileName: string);
  procedure EditPreferences(var ClearFileList: Boolean);
  procedure SetThemeColors;
  procedure SetHeaderColor(aHeader: TPanel);
  function  IsDefaultBrowserChromium: Boolean;

implementation

uses
  main, project, reportframe, configeditor;

function GetSysMonoFont: string;
var
  I: Integer;
begin
  Result := 'Monospace';
  for I := Low(MonoFonts) to High(MonoFonts) do
  begin
    if Screen.Fonts.IndexOf(MonoFonts[I]) >= 0 then
    begin
      Result := MonoFonts[I];
      exit;
    end;
  end;
end;

procedure ReadPreferences(FileName: string);
var
  Ini: TIniFile;
begin
  MapHiliter := true;
  MapHinting := true;
  ShowNotifiers := true;
  ConfirmDeletions := true;
  ShowWelcomePage := true;
  IconFamily := 'Material';
  OpenLastFile := true;
  BackupFile := false;
  ThemeColor := GrayTheme;
  MenuColor := GrayMenuColor;
  HeaderColor := GrayHeaderColor;
  FormColor := clWindow;
  AlternateColor := $00F6F6F3;
  DecimalPlaces := 2;

{$ifdef UNIX}
  MonoFont := GetSysMonoFont;
  FontSize := NixFontSize;
{$else}
  MonoFont := 'Courier New';
  FontSize := WinFontSize;
{$endif}

  if FileExists(FileName) then
  begin
    Ini := TIniFile.Create(FileName);
    try
      MapHiliter := Ini.ReadBool('Preferences', 'Map Hiliting', true);
      MapHinting := Ini.ReadBool('Preferences', 'Map Hinting', true);
      ConfirmDeletions := Ini.ReadBool('Preferences', 'Confirm Deletions', true);
      ShowWelcomePage := Ini.ReadBool('Preferences', 'Show Welcome Page', true);
      OpenLastFile := Ini.ReadBool('Preferences', 'Open Last File', true);
      BackupFile := Ini.ReadBool('Preferences', 'Backup File', false);
      DecimalPlaces := Ini.ReadInteger('Preferences', 'Decimal Places', 2);
      ThemeColor := Ini.ReadInteger('Preferences', 'Theme Color', ThemeColor);
    finally
      Ini.Free;
    end;
  end;
  SetThemeColors;
end;

procedure SavePreferences(FileName: string);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(FileName);
  try
    Ini.WriteBool('Preferences', 'Map Hiliting', MapHiliter);
    Ini.WriteBool('Preferences', 'Map Hinting', MapHinting);
    Ini.WriteBool('Preferences', 'Confirm Deletions', ConfirmDeletions);
    Ini.WriteBool('Preferences', 'Show Welcome Page', ShowWelcomePage);
    Ini.WriteBool('Preferences', 'Open Last File', OpenLastFile);
    Ini.WriteBool('Preferences', 'Backup File', BackupFile);
    Ini.WriteInteger('Preferences', 'Decimal Places', DecimalPlaces);
    Ini.WriteInteger('Preferences', 'Theme Color', ThemeColor);
  finally
    Ini.Free;
  end;
end;

procedure EditPreferences(var ClearFileList: Boolean);
//
//  Called by MainForm.FileConfigure which is called when
//  'Preferences' is selected from the FileMenuForm.
//
begin
  with TConfigForm.Create(MainForm) do
  try
    SetPreferences;
    ShowModal;
    if ModalResult = mrOK then
    begin
      GetPreferences(ClearFileList);
      if ChangeColorTheme then
      begin
        if ThemeColor = BlueTheme then
          ThemeColor := GrayTheme
        else
          ThemeColor := BlueTheme;
        SetThemeColors;
        MainForm.SetColorTheme;
      end;
    end;
  finally
    Free;
  end;
end;

procedure SetThemeColors;
begin
  if ThemeColor = BlueTheme then
  begin
    ThemeColor := BlueTheme;
    MenuColor := BlueMenuColor;
    HeaderColor := BlueHeaderColor;
  end
  else
  begin
    ThemeColor := GrayTheme;
    MenuColor := GrayMenuColor;
    HeaderColor := GrayHeaderColor;
  end;
end;

procedure SetHeaderColor(aHeader: TPanel);
begin
  aHeader.Color := HeaderColor;
  aHeader.BorderStyle := bsNone;
  aHeader.Font.Color := clWhite;
end;

function IsDefaultBrowserChromium: Boolean;
//
//  Determine if Windows default web browser is Chromium-based (Edge or Chrome)
//
var
  Path:   string;
  Params: string;
begin
  Result := false;
  FindDefaultBrowser(Path, Params);
  if (Pos('Edge', Path) > 0)
  or (Pos('MicrosoftEdge', Path) > 0)
  or (Pos('MSEdge', Path) > 0)
  or (Pos('Chrome', Path) > 0) then
    Result := True;
end;

end.
