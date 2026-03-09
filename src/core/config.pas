{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       config
 Description:  reads, saves and edits program preferenecs
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit config;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, Graphics, SysUtils, Controls, Forms, IniFiles;

const
  WinFontSize = 9;
  NixFontSize = 9;
  GrayTheme: Integer = $00F0F0F0;  //00F8F8F8; //$00EEEEEE;  //$00F9F4F0;
  BlueTheme: Integer =  $00FDEEE3;  //Pale Blue
  CreamTheme: Integer = $00F0FBFF;
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
  AlternateColor:    TColor;
  DecimalPlaces:     Integer;
  FontSize:          Integer;
  MonoFont:          string;
  IconFamily:        string;

  procedure ReadPreferences(FileName: string);
  procedure SavePreferences(FileName: string);
  procedure EditPreferences(var ClearFileList: Boolean);

implementation

uses
  main, project, reportviewer, configeditor;

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
  FormColor := GrayTheme;  //clWindow;
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
      FormColor := ThemeColor;
    finally
      Ini.Free;
    end;
  end;
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
var
  OldThemeColor: TColor;
begin
  OldThemeColor := ThemeColor;
  with TConfigForm.Create(MainForm) do
  try
    SetPreferences;
    ShowModal;
    if ModalResult = mrOK then
    begin
      GetPreferences(ClearFileList);
      if OldThemeColor <> ThemeColor then
      begin
        with MainForm do
        begin
          Color := ThemeColor;
          MainMenuFrame.SetColorTheme;
          if not project.HasResults then
            StatusBarFrame.SetPanelColor(Ord(sbResults), Color);
        end;
        ReportViewerForm.ChangeColor(ThemeColor);
      end;
    end;
  finally
    Free;
  end;
end;

end.
