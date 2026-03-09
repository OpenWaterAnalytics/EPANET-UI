{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       map
 Description:  a class that manages drawing the pipe network and
               its basemap on a bitmap
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit map;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, LCLIntf, Math,

  // EPANET-UI units
  mapoptions, mapcoords, webmap;

const
  PIXTOL   = 5;      // Pixel tolerance in detecting a mouse hit on an object
  MIN_ZOOM = -10;    // Minimum power of 2 when zooming out on the map
  MAX_ZOOM = 20;     // Maximum power of 2 when zooming in on the map

type
  // Base map image over which the pipe network is drawn
  // (Can be either a static image file or a dynamic web mapping service)
  TBaseMap = record
    Filename   : string;          // File containing basemap image
    Picture    : TPicture;        // Base map's image picture
    LowerLeft  : TDoublePoint;    // Lower left world coordinate
    UpperRight : TDoublePoint;    // Upper right world coordinate
    Brightness : Integer;         // Degree of image brightening (0 - 100)
    Grayscale  : Boolean;         // true if base map in grayscale
    Visible    : Boolean;         // true if base map is visible
    ZoomLevel0 : Integer;         // Zoom level at full extent
    WebMap     : TWebMap;         // Base map provided by web service
    NeedsRedraw: Boolean;         // Base map needs to be redrawn
  end;

  // Map class
  TMap = class(TObject)
    Canvas    : TCanvas;         // Display canvas
    Bitmap    : TBitmap;         // Bitmap containing the full map image
    Basemap   : TBasemap;        // Base map image
    Options   : TMapOptions;     // Display options (see mapoptions.pas)
    WPP0      : Double;          // World per pixel scaling at 0 zoom
    WPP       : Double;          // World per pixel scaling at current zoom
    CenterW0  : TDoublePoint;    // World center point at full extent
    CenterW   : TDoublePoint;    // World center point
    CenterP   : TPoint;          // Pixel center point
    MapRect   : TRect;           // Bounding rectangle in pixels
    Extent    : TDoubleRect;     // World map boundary at full extent
    ZoomLevel : Integer;         // Current zoom level
    CharHeight: Integer;         // Max. character height
    constructor Create;
    destructor  Destroy; override;

    function  LoadBasemapFile(Filename: string): Boolean;
    function  CreateWebBasemap(MapSource: Integer; NorthEast: TDoublePoint;
              SouthWest: TDoublePoint): Boolean;
    procedure SetBasemapBounds;
    procedure ScaleMapToBasemap;
    procedure ClearBasemap;
    procedure DrawBasemap;
    procedure DrawWebBasemap;
    procedure DrawBitmap(aBitmap: TBitmap; aPosition: TDoublePoint);

    procedure Clear;
    procedure Redraw;
    procedure Rescale;
    procedure Reset;
    procedure Resize(Rect: TRect);
    procedure SetCenter(X, Y: Double);
    procedure AdjustOffset(Dx: Integer; Dy: Integer);
    procedure ZoomIn(Dx: Integer; Dy: Integer);
    procedure ZoomOut(Dx: Integer; Dy: Integer);
    procedure ZoomToExtent;

    procedure GetLinkMidSegment(LinkIndex: Integer; var P1: TPoint;
      var P2: TPoint);
    function  FindNodeHit(MouseX: Integer; MouseY: Integer):Integer;
    function  FindLinkHit(MouseX: Integer; MouseY: Integer): Integer;
    function  FindLabelHit(MouseX: Integer; MouseY: Integer): Integer;
    function  FindLabelPoint(LabelIndex: Integer): TPoint;
    function  GetLinkEndPoints(LinkIndex: Integer; var P1: TPoint;
              var P2: TPoint):Boolean;
    function  MouseIsOverLink(LinkIndex: Integer; Pmouse: TPoint): Boolean;

    function  GetScalingInfo: TScalingInfo;
    function  GetBackColor: TColor;
    function  GetXpix(const X: Double):Integer;
    function  GetYpix(const Y: Double):Integer;
    function  GetX(const X: Integer): Double;
    function  GetY(const Y: Integer): Double;
    function  WorldToScreen(X,Y: Double): TPoint;
    function  ScreenToWorld(X, Y: Integer): TDoublePoint;

    procedure DrawBoundingRect;

  end;

implementation

uses
  project, maprenderer, maplabel, utils;

//------------------------------------------------------------------------------
//  Map constructor and destructor
//------------------------------------------------------------------------------
constructor TMap.Create;
begin
  inherited Create;

  // Create the bitmap on which the pipe network is drawn
  Bitmap := TBitmap.Create;
  if Bitmap <> nil then
  begin
    Canvas := Bitmap.Canvas;
    Bitmap.Canvas.AntialiasingMode := amOn;
  end;
  Bitmap.PixelFormat := pf24Bit;

  // Create a basemap layer
  Basemap.Filename := '';
  BaseMap.Picture := TPicture.Create;
  BaseMap.Picture.Bitmap.PixelFormat := pf24Bit;
  Basemap.Brightness := 0;
  Basemap.Grayscale := false;
  Basemap.WebMap := nil;
  Basemap.NeedsRedraw := false;

  // Default world coordinates of map's extent
  Extent.LowerLeft.X := 0;
  Extent.LowerLeft.Y := 0;
  Extent.UpperRight.X := 10000;
  Extent.UpperRight.Y := 10000;

  // Default display options
  Options := mapoptions.DefaultOptions;
  Zoomlevel := 0;
  CharHeight := 8;
end;

destructor TMap.Destroy;
begin
  Bitmap.Free;
  Basemap.Picture.Free;
  Basemap.WebMap.Free;
  inherited Destroy;
end;

//------------------------------------------------------------------------------
// Map Rendering
//------------------------------------------------------------------------------

function  TMap.GetBackColor: TColor;
begin
  Result := Options.BackColor;
end;

procedure TMap.Clear;
begin
  with Bitmap.Canvas do
  begin
    Brush.Color := Options.BackColor;
    Brush.Style := bsSolid;
    FillRect(MapRect);
  end;
end;

procedure TMap.DrawBoundingRect;
var
  P1: TPoint;
  P2: Tpoint;
begin
  P1 := WorldToScreen(Extent.LowerLeft.X, Extent.LowerLeft.Y);
  P2 := WorldToScreen(Extent.UpperRight.X, Extent.UpperRight.Y);
  Bitmap.Canvas.Brush.Style := bsClear;
  Bitmap.Canvas.Rectangle(P1.X, P1.Y, P2.X, P2.Y);
end;

procedure TMap.Redraw;
begin
  if Basemap.Visible then
    DrawBasemap
  else
    Clear;
  MapRenderer.DrawNetwork(self);

  //DrawBoundingRect; //For debugging only
end;

procedure TMap.DrawBitmap(aBitmap: TBitmap; aPosition: TDoublePoint);
var
  Xpix: Integer;
  Ypix: Integer;
begin
  Xpix := GetXpix(aPosition.X) - (aBitmap.Width div 2);
  Ypix := GetYpix(aPosition.Y) - (aBitmap.Height);
  Bitmap.Canvas.Draw(Xpix, Ypix, aBitmap);
end;

//------------------------------------------------------------------------------
// Map Resizing and Rescaling
//------------------------------------------------------------------------------

procedure TMap.Resize(Rect: TRect);
begin
  MapRect := Rect;
  CenterP := Rect.CenterPoint;
  Bitmap.SetSize(MapRect.Width, MapRect.Height);
  Rescale;
  Basemap.NeedsRedraw := true;
end;

procedure TMap.Reset;
begin
  Extent := DoubleRect(DoublePoint(0, 0), DoublePoint(10000, 10000));
  ZoomLevel := 0;
  Rescale;
  ClearBasemap;
  Clear;
end;

procedure TMap.Rescale;
var
  Dx: Double;
  Dy: Double;
  WPPx: Double;
  WPPy: Double;
begin
  // Find world distance units per pixel in the X & Y directions
  Dx := Extent.UpperRight.X - Extent.LowerLeft.X;
  Dy := Extent.UpperRight.Y - Extent.LowerLeft.Y;
  if MapRect.Width <= 0 then MapRect.Width := 10000;
  if MapRect.Height <= 0 then MapRect.Height := 10000;
  WPPx := Dx / MapRect.Width;
  WPPy := Dy / MapRect.Height;

  // Maintain a 1:1 aspect ratio
  if WPPy > WPPx then
    WPP0 := WPPy
  else
    WPP0 := WPPx;
  WPP := WPP0 / power(2, ZoomLevel);

  // Location of map center at full scale
  CenterW0 := DoublePoint(Extent.LowerLeft.X + Dx/2.0, Extent.LowerLeft.Y + Dy/2.0);
  if ZoomLevel = 0 then CenterW := CenterW0;
end;

function TMap.GetScalingInfo: TScalingInfo;
// TScalingInfo is defined in mapcoords unit
begin
  Result.CW := CenterW0;
  Result.CP := CenterP;
  Result.WP := WPP0;
end;

procedure TMap.ScaleMapToBasemap;        // Not currently used
var
  Pwidth: Integer;
  Pheight: Integer;
  Dpx: Integer;
  Dpy: Integer;
  Xwpp: Double;
  Ywpp: Double;
  BasemapExtent: TDoubleRect;
begin
  BaseMapExtent.LowerLeft := Basemap.LowerLeft;
  BasemapExtent.UpperRight := Basemap.UpperRight;
  Pwidth := Basemap.Picture.Width;
  Pheight := Basemap.Picture.Height;
  Dpx := (MapRect.Width - Pwidth) div 2;
  Dpy := (MapRect.Height - Pheight) div 2;
  with Basemap do
  begin
    Xwpp := (UpperRight.X - LowerLeft.X) / Pwidth;
    Ywpp := (UpperRight.Y - LowerLeft.Y) / Pheight;
    Extent.LowerLeft.X := LowerLeft.X - Xwpp * Dpx;
    Extent.UpperRight.X := UpperRight.X + Xwpp * Dpx;
    Extent.LowerLeft.Y := LowerLeft.Y - Ywpp * Dpy;
    Extent.UpperRight.Y := UpperRight.Y + Ywpp * Dpy;
  end;
  mapcoords.DoAffineTransform(Extent, BasemapExtent);
  Rescale;
end;

//------------------------------------------------------------------------------
// Basemap Procedures
//------------------------------------------------------------------------------

function TMap.LoadBasemapFile(Filename: string): Boolean;
//
//  Loads a static base map image from local file system
//
begin
  ClearBasemap;
  Result := true;
  try
    Basemap.Picture.LoadFromFile(Filename);
  except
    Result := false;
    exit;
  end;
  ZoomToExtent;
  SetBasemapBounds;
  with Basemap do
  begin
    Visible := true;
    Brightness := 0;
    Grayscale := false;
    NeedsRedraw := true;
  end;
end;

function TMap.CreateWebBasemap(MapSource: Integer; NorthEast: TDoublePoint;
          SouthWest: TDoublePoint): Boolean;
//
//  Creates a dynamic base map provided by a web map service
//
begin
  ClearBasemap;
  Basemap.WebMap := TWebMap.Create(Basemap.Picture.Bitmap);
  Result := Basemap.WebMap <> nil;
  if Result = false then exit;
  Basemap.WebMap.SetSource(MapSource);
  Basemap.WebMap.InitZoomLevel(NorthEast, SouthWest, MapRect);
  Basemap.Visible := Result;
  Basemap.NeedsRedraw := true;
end;

procedure TMap.SetBasemapBounds;
var
  R:    Double;
  Wpic: Double;
  Hpic: Double;
  Wwin: Double;
  Hwin: Double;
  Dx:   Integer;
  Dy:   Integer;
  Dw:   Integer;
  Dh:   Integer;
begin
  // Do nothing if basemap doesn't exist
  if Basemap.Picture.Bitmap.Width = 0 then exit;

  // Compute picture & window width & height in world coords.
  Wpic := Basemap.Picture.Width;
  Hpic := Basemap.Picture.Height;
  Wwin := MapRect.Width;
  Hwin := MapRect.Height;

  // Re-scale if picture is wider or taller than map window
  R := min(Wwin / Wpic, Hwin / Hpic);
  Wpic := R * Wpic;
  Hpic := R * Hpic;
  Dx := Round(Wwin - Wpic) div 2;
  Dy := Round(Hwin - Hpic) div 2;
  Dw := Round(Wpic);
  Dh := Round(Hpic);

  with Basemap do
  begin
    LowerLeft := ScreenToWorld(Dx, Dy + Dh);
    UpperRight := ScreenToWorld(Dx + Dw, Dy);
  end;
end;

procedure TMap.ClearBasemap;
begin
  with Basemap do
  begin
    if Assigned(WebMap) then FreeAndNil(WebMap);
    Picture.Bitmap.SetSize(0, 0);
    Visible := false;
    Brightness := 0;
    Grayscale := false;
    NeedsRedraw := false;
  end;
  Options.ShowBackdrop := false;
  Extent := mapcoords.GetBounds(Extent);
  ZoomLevel := 0;
  Rescale;
end;

procedure TMap.DrawBasemap;
var
  R: TRect;
begin
  if Basemap.Visible = false then exit;
  if Basemap.WebMap <> nil then
    DrawWebBasemap
  else
  begin
    if Options.ShowBackdrop = false then
    begin
      Clear;
      exit;
    end;
    with Basemap do
      R := Rect(GetXpix(LowerLeft.X), GetYpix(UpperRight.Y),
                GetXpix(UpperRight.X), GetYpix(LowerLeft.Y));
    with Bitmap do
    begin
      Canvas.AntiAliasingMode := amOn;
      Canvas.Brush.Color := Options.BackColor;
      Canvas.FillRect(0, 0, Width, Height);
      Canvas.StretchDraw(R, Basemap.Picture.Graphic);
    end;
  end;
  if Basemap.Grayscale then
    utils.GrayscaleBitmap(Bitmap);
  if Basemap.Brightness > 0 then
    utils.BrightenBitmap(Bitmap, Basemap.Brightness);
end;

procedure TMap.DrawWebBasemap;
begin
  if Basemap.NeedsRedraw then
  begin
    // Set bounding world coords. of base map
    Basemap.WebMap.SetBoundsRect(MapRect.Width, MapRect.Height);

    // If basemap layer should be shown
    if Options.ShowBackdrop then
    begin
      if Basemap.WebMap.ZoomLevel > webmap.MaxZoomLevel then
        Clear

      // Retrieve basemap image from server
      else if not Basemap.WebMap.GetImage(MapRect.Width, MapRect.Height) then
      begin
        // No image retreived so clear the map's background
        ClearBasemap;
        Clear;
        exit;
      end

      // Image retrieved -- draw it onto map's bitmap
      else
        Bitmap.Canvas.Draw(0, 0, Basemap.Picture.Bitmap);
    end

    // Basemap layer should not be shown so clear map's bitmap
    else
      Clear;

    // Rescale the network to the web map's extent
    // (to account for any zooming action)
    Extent := Basemap.WebMap.BoundsRect;
    Rescale;
    Basemap.NeedsRedraw := false;
  end

  // Basemap doesn't need to be refreshed so draw it
  // onto map's bitmap if it should be displayed
  else if Options.ShowBackdrop then
    Bitmap.Canvas.Draw(0, 0, Basemap.Picture.Graphic)
  else
    Clear;
end;

//------------------------------------------------------------------------------
// Map Zooming & Scrolling
//------------------------------------------------------------------------------

procedure TMap.AdjustOffset(Dx: Integer; Dy: Integer);
//
//  Moves map center by Dx, Dy pixels.
//
begin
  CenterW.X := CenterW.X - WPP * Dx;
  CenterW.Y := CenterW.Y + WPP * Dy;
  if Basemap.WebMap <> nil then Basemap.WebMap.AdjustOffset(Dx, Dy);
  Basemap.NeedsRedraw := true;
end;

procedure TMap.SetCenter(X, Y: Double);
begin
  CenterW.X := X;
  CenterW.Y := Y;
  if Basemap.WebMap <> nil then
    Basemap.WebMap.SetCenter(X,Y);
  Basemap.NeedsRedraw := true;
end;

procedure TMap.ZoomIn(Dx: Integer; Dy: Integer);
//
//  Dx, Dy are offsets from map center where user zooms in from.
//
var
  ZoomFactor: Double;
begin
  // Check if max zoom level reached
  if ZoomLevel = MAX_ZOOM then exit;

  // Adjust world coordinates of map center
  CenterW.X := CenterW.X + Dx * WPP / 2;
  CenterW.Y := CenterW.Y - Dy * WPP / 2;

  // Increment zoom level and scale factor
  Inc(ZoomLevel);
  ZoomFactor := power(2, ZoomLevel);
  WPP := WPP0 / ZoomFactor;

  // Adjust zoom level of web service base map
  if Basemap.WebMap <> nil then
    Basemap.WebMap.AdjustZoomLevel(1, Dx, Dy);
  Basemap.NeedsRedraw := true;
end;

procedure TMap.ZoomOut(Dx: Integer; Dy: Integer);
//
//  Dx, Dy are offsets from map center where user zooms out from.
//
begin
  // Check if min zoom level reached
  if ZoomLevel = MIN_ZOOM then exit;

  // Adjust world coordinates of map center
  CenterW.X := CenterW.X - Dx * WPP;
  CenterW.Y := CenterW.Y + Dy * WPP;

  // Decrement zoom level and scale factor
  Dec(ZoomLevel);
  WPP := WPP0 / power(2, ZoomLevel);

  // Adjust zoom level of web service base map
  if Basemap.WebMap <> nil then
    Basemap.WebMap.AdjustZoomLevel(-1, Dx, Dy);
  Basemap.NeedsRedraw := true;
end;

procedure TMap.ZoomToExtent;
begin
  // Determine the zoom level at full extent of a web service base map if used
  if Basemap.WebMap <> nil then
  begin
    if project.GetItemCount(ctNodes) > 0 then
      Extent := mapcoords.GetBounds(Extent);
    Basemap.WebMap.InitZoomLevel(Extent.UpperRight, Extent.LowerLeft, MapRect);
  end;

  // Re-scale the network to display at full scale
  ZoomLevel := 0;
  Rescale;
  Basemap.NeedsRedraw := true;
end;

//------------------------------------------------------------------------------
// Locating Selected Objects
//------------------------------------------------------------------------------

function TMap.FindNodeHit(MouseX: Integer; MouseY: Integer): Integer;
//
//  Finds the index of a network node that mouse is clicked on.
//
var
  I: Integer;
  P: TPoint;
  Pmouse: TPoint;
  R: TRect;
  X: Double = 0;
  Y: Double = 0;
begin
  Result := 0;
  Pmouse := Point(MouseX, MouseY);
  for I := 1 to project.GetItemCount(project.ctNodes) do
  begin
    if not project.GetNodeCoord(I, X, Y) then continue;
    P := WorldToScreen(X, Y);
    R := Rect(P.X - PIXTOL, P.Y - PIXTOL, P.X + PIXTOL, P.Y + PIXTOL);
    if PtInRect(R, Pmouse) then
    begin
      Result := I;
      break;
    end;
  end;
end;

function TMap.FindLabelPoint(LabelIndex: Integer): TPoint;
var
  MapLabel: TMapLabel;
  N: Integer;
  Xa: Double = 0;
  Ya: Double = 0;
begin
  Maplabel := TMapLabel(project.Maplabels.Objects[LabelIndex-1]);
  if (Length(Maplabel.AnchorNode) = 0)
  or (ZoomLevel = 0) then
    Result := WorldToScreen(Maplabel.X, MapLabel.Y)
  else
  begin
    N := project.GetItemIndex(ctNodes, MapLabel.AnchorNode);
    if project.GetNodeCoord(N, Xa, Ya) then
    begin
      Result := WorldToScreen(Xa, Ya);
      Result.X := Result.X + Round( (Maplabel.X - Xa) / WPP0);
      Result.Y := Result.Y - Round( (MapLabel.Y - Ya) / WPP0);
    end
    else
      Result := Point(GetXpix(MapLabel.X), GetYpix(MapLabel.Y));
  end;
end;

function TMap.FindLabelHit(MouseX: Integer; MouseY: Integer): Integer;
//
//  Finds the index of a map label that mouse is clicked on.
//
var
  I: Integer;
  P: TPoint;
  Pmouse: TPoint;
  R: TRect;
begin
  Result := 0;
  Pmouse := Point(MouseX, MouseY);
  for I := 1 to project.MapLabels.Count do
  begin
    P := FindLabelPoint(I);
    R := TMapLabel(project.MapLabels.Objects[I-1]).GetRect(P);
    if PtInRect(R, Pmouse) then
    begin
      Result := I;
      break;
    end;
  end;
end;

function TMap.GetLinkEndPoints(LinkIndex: Integer; var P1: TPoint;
  var P2: TPoint):Boolean;
//
//  Finds the screen pixel coordinates of a link's end points.
//
var
  N1: Integer = 0;
  N2: Integer = 0;
  X: Double = 0;
  Y: Double = 0;
begin
  Result := false;
  if not project.GetLinkNodes(LinkIndex, N1, N2) then exit;
  if not project.GetNodeCoord(N1, X, Y) then exit;
  P1 := WorldToScreen(X, Y);
  if not project.GetNodeCoord(N2, X, Y) then exit;
  P2 := WorldToScreen(X, Y);
  Result := true;
end;

function TMap.MouseIsOverLink(LinkIndex: Integer; Pmouse: TPoint): Boolean;
//
//  Checks if mouse point Pmouse is over link with index LinkIndex.
//
var
  V: Integer;
  P1: TPoint = (x:0; y:0);
  P2: TPoint = (x:0; y:0);
  P3: TPoint;
  X: Double = 0;
  Y: Double = 0;
begin
  // First get the pixel coordinates of the link's endpoints
  Result := true;
  if GetLinkEndPoints(LinkIndex, P1, P2) then
  begin
    // Then examine each interior line segment between the link's vertices
    for V := 1 to project.GetVertexCount(LinkIndex) do
    begin
      // Make vertex be the endpoint of current line segment
      if not project.GetVertexCoord(LinkIndex, V, X, Y) then continue;
      P3 := WorldToScreen(X, Y);

      // Mouse is over line segment so exit with TRUE result
      if utils.PointOnLine(P1, P3, Pmouse, PIXTOL) then exit;

      // Set starting point of next line segment
      P1 := P3;
    end;

    // If link has no vertices then check line between endpoints
    if utils.PointOnLine(P1, P2, Pmouse, PIXTOL) then exit;
  end;

  // Wind up here if mouse not over the link
  Result := false;
end;

function TMap.FindLinkHit(MouseX: Integer; MouseY: Integer): Integer;
//
//  Finds the index of a network link that mouse is clicked on.
//
var
  LinkIndex: Integer;
begin
  Result := 0;
  for LinkIndex := 1 to project.GetItemCount(project.ctLinks) do
    if MouseIsOverLink(LinkIndex, Point(MouseX, MouseY)) then
    begin
      Result := LinkIndex;
      exit;
    end;
end;

procedure TMap.GetLinkMidSegment(LinkIndex: Integer; var P1: TPoint;
  var P2: TPoint);
var
  N: Integer;
  Node1: Integer = 0;
  Node2: Integer = 0;
  X: Double = 0;
  Y: Double = 0;
begin
  N := project.GetVertexCount(LinkIndex);
  if N < 2 then
  begin
    project.GetLinkNodes(LinkIndex, Node1, Node2);
    project.GetNodeCoord(Node1, X, Y);
    P1 := WorldToScreen(X, Y);

    // Link has no vertices - use end nodes as mid-segment
    if N = 0 then
      project.GetNodeCoord(Node2, X, Y)
    // Link has one vertex - use start node and vertex as mid-segment
    else
      project.GetVertexCoord(LinkIndex, N, X, Y);
    P2 := WorldToScreen(X, Y);
  end else

  // Link has 2 or more vertices - use midpoint vertices as mid-segment
  begin
    N := (N div 2);
    project.GetVertexCoord(LinkIndex, N, X, Y);
    P1 := WorldToScreen(X, Y);
    project.GetVertexCoord(LinkIndex, N+1, X, Y);
    P2 := WorldToScreen(X, Y);
  end;
end;

//-----------------------------------------------
// Conversions Between World & Screen Coodinates
//-----------------------------------------------

function TMap.WorldToScreen(X,Y: Double): TPoint;
begin
  if Assigned(Basemap.WebMap) then
  begin
    Result := Basemap.WebMap.FromLatLonToPixel(DoublePoint(X, Y));
    Result.X := (MapRect.Width div 2) + (Result.X - Basemap.WebMap.CenterPixel.X);
    Result.Y := (MapRect.Height div 2) + (Result.Y - Basemap.WebMap.CenterPixel.Y);
  end
  else
    Result := Point(GetXpix(X), GetYpix(Y));
end;

function TMap.ScreenToWorld(X, Y: Integer): TDoublePoint;
begin
  if Assigned(Basemap.WebMap) then
  begin
    X := Basemap.WebMap.CenterPixel.X + (X - MapRect.Width div 2);
    Y := Basemap.WebMap.CenterPixel.Y + (Y - MapRect.Height div 2);
    Result := Basemap.WebMap.FromPixelToLatLon(Point(X, Y))
  end
  else
    Result := DoublePoint(GetX(X), GetY(Y));
end;

function TMap.GetXpix(const X: Double):Integer;
//
//  Convert world coordinate X to a screen pixel value.
//
begin
  Result := CenterP.X + Round((X - CenterW.X) / WPP);
end;

function TMap.GetYpix(const Y: Double):Integer;
//
//  Convert world coordinate Y to a screen pixel value.
//
begin
  Result := CenterP.Y - Round((Y - CenterW.Y) / WPP);
end;

function  TMap.GetX(const X: Integer): Double;
//
//  Convert a screen pixel location to an X world coordinate value.
//
begin
  Result := CenterW.X + (X - CenterP.X) * WPP;
end;

function  TMap.GetY(const Y: Integer): Double;
//
//  Convert a screen pixel location to a Y world coordinate value.
//
begin
  Result := CenterW.Y + (CenterP.Y - Y) * WPP;
end;

end.

