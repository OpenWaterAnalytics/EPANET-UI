{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       maplegend
 Description:  a frame that displays a legend for color-coded nodes
               and links on the network map
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit maplegend;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Graphics, Buttons;

type

  { TMapLegendFrame }

  TMapLegendFrame = class(TFrame)
    LegendPanel:    TPanel;
    Label1:         TLabel;
    Label2:         TLabel;
    Label3:         TLabel;
    Label4:         TLabel;
    Label5:         TLabel;
    ThemeNameLabel: TLabel;
    Shape1:         TShape;
    Shape2:         TShape;
    Shape3:         TShape;
    Shape4:         TShape;
    Shape5:         TShape;

    procedure LegendPanelDblClick(Sender: TObject);
    procedure LegendPanelMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure LegendPanelMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure LegendPanelMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    FMouseOffset: TPoint;
    FRelativePos: TPoint;
    FIsDragging:  Boolean;
    procedure ConstrainToBoundaries;

  public
    Framed:  Boolean;
    ObjType: Integer;
    procedure SetShapes(ShapeType: TShapeType);
    procedure DrawLegend(Colors: array of TColor; Intervals: array of string;
      ThemeName: string; ThemeUnits: string);
    procedure SetTextColor;
    procedure SetLocation(P: TPoint);
    function  GetLocation: TPoint;
  end;

implementation

{$R *.lfm}

uses
  main, project, config, mapoptions, mapthemes;

procedure TMapLegendFrame.SetShapes(ShapeType: TShapeType);
//
// Set the legend's colored marks to either circles (for nodes)
// or rectangles (for links).
//
// Called from the main form's MapFrame.Init procedure when creating
// the Node and Link legends.
//
var
  I: Integer;
begin
  for I := 1 to 5 do
  begin
    with FindComponent('Shape' + IntToStr(I)) as TShape do
    begin
      Shape := ShapeType;
      if ShapeType = stRectangle then Width := 9;
      if ShapeType = stCircle then Width := 12;
    end;
  end;
  Framed := true;
  FRelativePos.X := (Left * 100) div Parent.ClientWidth;
  FRelativePos.Y := (Top * 100) div Parent.ClientHeight;
end;

procedure TMapLegendFrame.LegendPanelMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FMouseOffset.X := X;
    FMouseOffset.Y := Y;
    FIsDragging := True;
    LegendPanel.Cursor := crDrag;
  end;
end;

procedure TMapLegendFrame.LegendPanelDblClick(Sender: TObject);
begin
  if ObjType = project.ctNodes then
    MainForm.MapViewerFrame.NodeLegendBox.Checked := false
  else if ObjType = project.ctLinks then
    MainForm.MapViewerFrame.LinkLegendBox.Checked := false;
end;

procedure TMapLegendFrame.LegendPanelMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
   if FIsDragging then
   begin
     Left := Left + (X - FMouseOffset.X);
     Top := Top + (Y - FMouseOffset.Y);
     ConstrainToBoundaries;
   end;
end;

procedure TMapLegendFrame.LegendPanelMouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
  begin
    if ObjType = project.ctNodes then
    begin
      if mapthemes.EditNodeLegend then
        MainForm.MapFrame.RedrawMap;
    end
    else if ObjType = project.ctLinks then
    begin
      if mapthemes.EditLinkLegend then
        MainForm.MapFrame.RedrawMap;
    end;
    exit;
  end;

  if FIsDragging then
    FIsDragging := False;
  LegendPanel.Cursor := crDefault;
  FRelativePos.X := (Left * 100) div Parent.ClientWidth;
  FRelativePos.Y := (Top * 100) div Parent.ClientHeight;
end;

procedure TMapLegendFrame.DrawLegend(Colors: array of TColor;
  Intervals: array of string; ThemeName: string; ThemeUnits: string);
//
// Called from mapthemes.UpdateLegend when a legend needs to be redrawn.
//
var
  I: Integer;
  S: string;
begin
  for I := 1 to 5 do
  begin
    with FindComponent('Shape' + IntToStr(I)) as TShape do
      Brush.Color := Colors[I-1];
  end;
  Label1.Caption := '< ' + Intervals[0];
  Label2.Caption := Intervals[0] + ' - ' + Intervals[1];
  Label3.Caption := Intervals[1] + ' - ' + Intervals[2];
  Label4.Caption := Intervals[2] + ' - ' + Intervals[3];
  Label5.Caption := '> ' + Intervals[3];

  S := ThemeName;
  if Length(ThemeUnits) > 0 then
    S := S + ' (' + ThemeUnits + ')';
  ThemeNameLabel.Caption:= S;
  SetTextColor;
  if Framed then
    LegendPanel.BorderStyle := bsSingle
  else
    LegendPanel.BorderStyle := bsNone;
end;

procedure TMapLegendFrame.SetTextColor;
//
// Adjust the legend's font color depending on map background color.
//
begin
  if Color = mapoptions.DarkColor then
  begin
    Font.Color := clWhite;
  end
  else
  begin
    Font.Color := clBlack;
  end;
end;

procedure  TMapLegendFrame.ConstrainToBoundaries;
//
// Adjust a legend's position if it falls outside its parent's boundaries.
//
begin
   if Left < 0 then Left := 0;
   if Top < 0 then Top := 0;
   if Left + Width > Parent.ClientWidth then
      Left := Parent.ClientWidth - Width;
   if Top + Height > Parent.ClientHeight then
      Top := Parent.ClientHeight - Height;
end;

function TMapLegendFrame.GetLocation: TPoint;
begin
  Result := FRelativePos;
end;

procedure TMapLegendFrame.SetLocation(P: TPoint);
begin
  FRelativePos := P;
  Left := (FRelativePos.X * Parent.ClientWidth) div 100;
  Top := (FRelativePos.Y * Parent.ClientHeight) div 100;
  ConstrainToBoundaries;
end;

end.

