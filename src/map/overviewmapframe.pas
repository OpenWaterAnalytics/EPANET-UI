{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       overviewmap.pas
 Description:  a frame with a full-scale outline of the network map
               with a rectangle drawn around the current view area.
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit overviewmapframe;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics, LCLIntf, Types,
  Buttons, map, Dialogs;

type

  { TOverviewMapFrame }

  TOverviewMapFrame = class(TFrame)
    CloseBtn: TSpeedButton;
    PaintBox1: TPaintBox;
    TopPanel: TPanel;
    procedure CloseBtnClick(Sender: TObject);
    procedure PaintBox1MouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1MouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure PaintBox1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure PaintBox1Paint(Sender: TObject);

  private
    Map      : Tmap;
    FocusRect: TRect;
    Moving   : Boolean;
    StartX   : Integer;
    StartY   : Integer;
    DragX    : Integer;
    DragY    : Integer;
    procedure PaintFocusRect;
    procedure SizeFocusRect;

  public
    procedure Init;
    procedure Close;
    procedure Redraw;
    procedure ShowMapExtent;

  end;

implementation

{$R *.lfm}

uses
  main, mapthemes, mapcoords, utils;

procedure TOverviewMapFrame.Init;
begin
  Map := TMap.Create;
  with Map.Options do
  begin
    ShowNodes := false;
    ShowPumps := false;
    ShowValves := false;
    ShowLabels := false;
    BackColor := clWhite;
  end;
  Map.MapRect := Parent.ClientRect;
  Map.CenterP := Map.MapRect.CenterPoint;
  Map.Bitmap.SetSize(Map.MapRect.Width, Map.MapRect.Height);
  Map.ZoomLevel := 0;
  FocusRect := Rect(-1,-1,-1,-1);
  Moving := false;
end;

procedure TOverviewMapFrame.Close;
begin
  Map.Free;
end;

procedure TOverviewMapFrame.Redraw;
var
  SavedLinkTheme: Integer;
begin
  if not MainForm.OverviewPanel.Visible then exit;
  SavedLinkTheme := mapthemes.LinkTheme;
  mapthemes.LinkTheme := 0;
  Map.Options.BackColor := MainForm.MapFrame.Map.Options.BackColor;
  Map.Extent := mapcoords.GetBounds(MainForm.MapFrame.GetExtent);
  Map.ZoomLevel := 0;
  Map.Rescale;
  Map.Redraw;
  mapthemes.LinkTheme := SavedLinkTheme;
  ShowMapExtent;
end;

procedure TOverviewMapFrame.ShowMapExtent;
begin
  if not MainForm.OverviewPanel.Visible then exit;
  SizeFocusRect;
  PaintBox1.Refresh;
end;

procedure TOverviewMapFrame.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0,0,Map.Bitmap);
  PaintFocusRect;
end;

procedure TOverviewMapFrame.PaintBox1MouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  PtInFocusRect: Boolean;
begin
  Moving := false;
  if (Button = mbLeft) then
  begin
    PtInFocusRect := (X >= FocusRect.Left) and
                     (X <= FocusRect.Right) and
                     (Y >= FocusRect.Bottom) and
                     (Y <= FocusRect.Top);
    if PtInFocusRect then
    begin
      StartX := X;
      StartY := Y;
      Moving := true;
      DragX := X;
      DragY := Y;
    end;
  end;
end;

procedure TOverviewMapFrame.CloseBtnClick(Sender: TObject);
begin
  MainForm.OverviewPanel.Hide;
  utils.FindTreeNode(MainForm.LegendTreeView, 'Overview Map').StateIndex := 0;
end;

procedure TOverviewMapFrame.PaintBox1MouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
begin
  if Moving then
  begin
    OffsetRect(FocusRect, X-DragX, Y-DragY);
    PaintBox1.Refresh;
    DragX := X;
    DragY := Y;
  end;
end;

procedure TOverviewMapFrame.PaintBox1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  MidPix: TPoint;
  Wx: Double;
  Wy: Double;
begin
  if Moving then
  begin
    Moving := false;

    // Pixel coords. of FocusRect center
    MidPix.X := (FocusRect.Left + FocusRect.Right) div 2;
    MidPix.Y := (FocusRect.Top + FocusRect.Bottom) div 2;

    // World coords. of FocusRect center
    Wx := Map.GetX(MidPix.X);
    Wy := Map.GetY(MidPix.Y);

    // New location of network map's center
    MainForm.MapFrame.SetMapCenter(Wx, Wy);
  end;
end;

procedure TOverviewMapFrame.SizeFocusRect;
var
  L: Integer;
  T: Integer;
  R: Integer;
  B: Integer;
  W1: TDoublePoint;
  W2: TDoublePoint;
begin
  // If no zoom-in, then don't display focus rectangle.
  if MainForm.MapFrame.Map.ZoomLevel <= 0 then
  begin
    FocusRect := Rect(-1,-1,-1,-1);
    exit;
  end;

  // Determine world coordinates of zoomed-in area.
  with MainForm.MapFrame.Map do
  begin
    W1 := ScreenToWorld(0, 0);
    W2 := ScreenToWorld(MapRect.Width, MapRect.Height);
  end;

  //Translate these coordinates to overview map scaling.
  with Map do
  begin
    L := GetXpix(W1.X);
    T := GetYpix(W2.Y);
    R := GetXpix(W2.X);
    B := GetYpix(W1.Y);
  end;
  FocusRect := Rect(L,T,R,B);
end;

procedure TOverviewMapFrame.PaintFocusRect;
begin
  with PaintBox1.Canvas do
  begin
    Pen.Width := 2;
    Pen.Color := clRed;
    Brush.Style := bsClear;
    with FocusRect do
      Rectangle(Left,Top,Right,Bottom);
  end;
end;

end.

