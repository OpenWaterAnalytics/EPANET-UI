{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       projectmapdata
 Description:  reads/writes map data from/to an EPANET input file
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit projectmapdata;

{
 This unit reads/writes map data from/to an EPANET input file
 as the EPANET Toolkit does not support these actions.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Graphics, Dialogs;

procedure ReadMapData(Fname: string);
procedure SaveMapData(Fname: string);

implementation

uses
  main, project, mapframe, mapthemes, maplabel, mapcoords, utils;

const
  Labels = 1;
  Backdrop = 2;

  Keywords: array[0..3] of string =
    ('DIMENSIONS', 'UNITS', 'FILE', 'OFFSET');

var
  BasemapFileName: string;
  MapBounds:       TDoubleRect;
  HasMapBounds:    Boolean;

procedure ReadLabelData(S: string; Tokens: TStringList);
var
  I: Integer;
  X, Y: Double;
  MapLabel: TMapLabel;
begin
  Tokens.DelimitedText := S;
  if Tokens.Count < 3 then exit;
  try
    X := StrToFloat(Tokens[0]);
    Y := StrToFloat(Tokens[1]);
  except
    On EConvertError do exit;
  end;
  MapLabel := TMapLabel.Create;
  MapLabel.X := X;
  MapLabel.Y := Y;
  project.MapLabels.AddObject(Tokens[2], Maplabel);
  if (Tokens.Count >= 4) and (project.GetItemIndex(ctNodes, Tokens[3]) > 0) then
    MapLabel.AnchorNode := Tokens[3];
  if (Tokens.Count >= 5) then MapLabel.Font.Name := Tokens[4];
  if (Tokens.Count >= 6) then
  begin
    I := StrToIntDef(Tokens[5], 0);
    if I > 0 then MapLabel.Font.Size := I;
  end;
  if (Tokens.Count >= 7)
  and SameText(Tokens[6], 'YES') then
    with Maplabel.Font do Style := Style + [fsBold];
  if (Tokens.Count >= 8)
  and SameText(Tokens[7], 'YES') then
    with Maplabel.Font do Style := Style + [fsItalic];
end;

procedure ReadMapBounds(Tokens: TStringList);
var
  I: Integer;
  X: array [1..4] of Double;
begin
  if Tokens.Count < 5 then exit;
  for I := 1 to 4 do
  begin
    if not utils.Str2Float(Tokens[I], X[I]) then exit;
  end;
  MapBounds.LowerLeft := mapcoords.DoublePoint(X[1], X[2]);
  MapBounds.UpperRight := mapcoords.DoublePoint(X[3], X[4]);
  HasMapBounds := true;
end;

procedure ReadUnits(S: string);
begin
  project.MapUnits := AnsiIndexText(S, project.MapUnitsStr);
  if project.MapUnits < 0 then project.MapUnits := project.muNone;
end;

procedure ReadBackdropData(S: string; Tokens: TStringList);
begin
  Tokens.DelimitedText := S;
  if Tokens.Count < 2 then exit;
  if SameText(Tokens[0], Keywords[0]) then
    ReadMapBounds(Tokens)
  else if SameText(Tokens[0], Keywords[1]) then
  begin
    ReadUnits(Tokens[1]);
    if Tokens.Count > 2 then
    begin
      project.MapEPSG:= StrToIntDef(Tokens[2], 0);
    end;
  end
  else if SameText(Tokens[0], Keywords[2]) then
    BasemapFilename := Tokens[1];
end;

procedure WriteBackdropData(Lines: TStringList);
var
  S: string;
  DS: Char;
  Bounds: TDoubleRect;
begin
  Lines.Add('');
  Lines.Add('[BACKDROP]');
  DS := DefaultFormatSettings.DecimalSeparator;
  DefaultFormatSettings.DecimalSeparator := '.';
  with MainForm.MapFrame do
  begin
    if Map.Basemap.Picture.Bitmap.Width > 0 then
      Bounds := mapcoords.DoubleRect(Map.Basemap.LowerLeft, Map.Basemap.UpperRight)
    else
      Bounds := Map.Extent;
    with Bounds do
      S := Format('DIMENSIONS'#9'%.6f'#9'%.6f'#9'%.6f'#9'%.6f',
        [LowerLeft.X, LowerLeft.Y, UpperRight.X, UpperRight.Y]);
  end;
  DefaultFormatSettings.DecimalSeparator := DS;
  Lines.Add(S);
  Lines.Add('UNITS     ' + #9 + project.MapUnitsStr[project.MapUnits] +
    #9 + IntToStr(project.MapEPSG));
  Lines.Add('FILE      ' + #9 + '"' + MainForm.MapFrame.BasemapFile + '"');
end;

procedure  WriteLabelData(Lines: TStringList);
var
  I: Integer;
  MapLabel: TMapLabel;
  Anchor: string = '""';
  LabelText: string;
  FontName: string;
  FontBold: string;
  FontItalic: string;
begin
  if project.MapLabels.Count > 0 then
  begin
    Lines.Add('');
    Lines.Add('[LABELS]');
    for I := 0 to project.MapLabels.Count-1 do
    begin
      MapLabel := TMapLabel(project.MapLabels.Objects[I]);
      LabelText := '"' + project.MapLabels[I] + '"';
      FontName := '"' + MapLabel.Font.Name + '"';
      if Length(MapLabel.AnchorNode) = 0 then
        Anchor := '""'
      else
        Anchor := MapLabel.AnchorNode;
      if fsBold in MapLabel.Font.Style then
        FontBold := 'YES'
      else
        FontBold := 'NO';
      if fsItalic in MapLabel.Font.Style then
        FontItalic := 'YES'
      else
        FontItalic := 'NO';
      Lines.Add(Format('%14.6f  %14.6f  %s  %s  %s  %d  %s  %s',
        [MapLabel.X, MapLabel.Y, LabelText, Anchor, FontName, MapLabel.Font.Size,
         FontBold, FontItalic]));
    end;
  end;
end;

procedure AssignBasemapFile;
begin
  if not FileExists(BasemapFilename) then exit;
  with MainForm.MapFrame do
  begin
    if not Map.LoadBasemapFile(BasemapFilename) then exit;
    Map.Options.ShowBackdrop := true;
    HasBaseMap := true;
    BaseMapFile := BasemapFilename;
    if HasMapBounds then
    begin
      Map.Basemap.LowerLeft := MapBounds.LowerLeft;
      Map.Basemap.UpperRight := MapBounds.UpperRight;
    end;
  end;
  MainForm.MapViewerFrame.SetBasemapCheckBox(true);
end;

procedure ReadMapData(Fname: string);
var
  Tokens: TStringList;
  InpFile: TextFile;
  S: string;
  Section: Integer;
begin
  MapUnits := 0;
  HasMapBounds := false;
  BasemapFilename := '';
  Section := 0;
  Tokens := TStringList.Create;
  AssignFile(InpFile, Fname);
  try
    Tokens.Delimiter := #9;
    Tokens.QuoteChar := '"';
    Tokens.StrictDelimiter:= false;
    Reset(InpFile);
    while not eof(InpFile) do
    begin
      Readln(InpFile, S);
      S := TrimLeft(S);
      if AnsiStartsText(';', S) then continue;
      if AnsiStartsText('[', S) then
      begin
        if AnsiStartsText('[LABEL', S) then
          Section := Labels
        else
        begin
          if AnsiStartsText('[BACKDROP', S) then
            Section := Backdrop
          else
            Section := 0;
        end;
      end
      else if Section = Labels then
        ReadLabelData(S, Tokens)
      else if Section = Backdrop then
        ReadBackdropData(S, Tokens);
    end;
  finally
    CloseFile(InpFile);
    Tokens.Free;
  end;
  if project.MapEPSG = 4326 then MapUnits := muDegrees;
  project.MapUnits := MapUnits;
  if Length(BasemapFilename) > 0 then
    AssignBasemapFile;
end;

procedure SaveMapData(Fname: string);
var
  Lines: TStringList;
  InpFile: TextFile;
  aLine: string;
  Section: Integer;
begin
  Lines := TStringList.Create;
  try
    AssignFile(InpFile, Fname);
    try
      Reset(InpFile);
      Section := 0;
      while not eof(InpFile) do
      begin
        Readln(InpFile, aLine);
        if AnsiStartsText('[', aLine) then
        begin
          if AnsiStartsText('[END', aLine) then
            continue
          else if AnsiStartsText('[LABEL', aLine) then
            Section := Labels
          else if AnsiStartsText('[BACK', aLine) then
            Section := Backdrop
          else
            Section := 0;
        end;
        if Section = 0 then Lines.Add(aLine);
      end;
    finally
      CloseFile(InpFile);
    end;
    WriteLabelData(Lines);
    WriteBackdropData(Lines);
    Lines.SaveToFile(Fname);
  finally
    Lines.Free;
  end;
end;

end.

