{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       webmap
 Description:  class that retrieves an image from a web map service
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

// Uses the TMapServer component in the webmapserver unit to
// retrieve a street map image from an internet map tile service.

unit webmap;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LCLType, lclintf, Graphics, Math, Dialogs, Controls,
  mapcoords, webmapserver;

const
  // Zoom level limits
  MinZoomLevel = 4;
  MaxZoomLevel = 18;

  // Map provider codes
  WorldStreets     = 1;
  OpenStreetMap    = 2;
  BingRoadsMap     = 3;
  BingSatelliteMap = 4;

  // Map provider names
  MapProviders: array[1..4] of string =
    ('ArcGIS World Street Map',
     'OpenStreetMap Standard',
     'Virtual Earth Bing',
     'Virtual Earth Aerial');

type
  TWebMap = class(TObject)
    Public
      MapSource:    Integer;
      ZoomLevel:    Integer;
      BoundsRect:   TDoubleRect;
      CenterLatLon: TDoublePoint;
      CenterPixel:  TPoint;

      constructor Create(aBitmap: TBitmap);
      destructor  Destroy; override;

      function  GetImage(W: Integer; H: Integer): Boolean;
      procedure AdjustOffset(Dx: Integer; Dy: Integer);
      procedure InitZoomLevel(NorthEast: TDoublePoint; SouthWest: TDoublePoint;
        MapRect: TRect);
      procedure AdjustZoomLevel(Dz: Integer; Dx: Integer; Dy: Integer);
      function  FromLatLonToPixel(LatLon: TDoublePoint): TPoint;
      function  FromPixelToLatLon(Pixel: TPoint): TDoublePoint;
      function  GetBoundingBox(W: Integer; H: Integer): TDoubleRect;
      procedure SetBoundsRect(W: Integer; H: Integer);
      procedure SetCenter(X, Y: Double);
      procedure SetSource(aMapSource: Integer);

    Private
      MapSize:   Integer;
      Bitmap:    TBitmap;
      MapServer: TMapServer;
  end;

implementation

uses
  main;

constructor TWebMap.Create(aBitmap: TBitmap);
begin
  inherited Create;
  Bitmap := aBitmap;
  MapServer := TMapServer.Create(MainForm.MapFrame);
end;

destructor TWebMap.Destroy;
begin
  if Assigned(MapServer) then FreeAndNil(MapServer);
  inherited Destroy;
end;

function TWebMap.GetImage(W: Integer; H: Integer): Boolean;
begin
  Result := false;
  if (MapSource < 1)
  or (MapSource > High(Mapproviders)) then
    exit;
  if MapServer = nil then exit;
  try
    MapServer.GetMapImage(CenterLatLon.X, CenterLatLon.Y, W, H, ZoomLevel, Bitmap);
    Result := true;
  except
  end;
end;

procedure TWebMap.SetCenter(X, Y: Double);
begin
  CenterLatLon.X := X;
  CenterLatLon.Y := Y;
  CenterPixel := FromLatLonToPixel(CenterLatLon);
end;

procedure TWebMap.SetSource(aMapSource: Integer);
begin
  if (aMapSource >= 1)
  and (aMapSource <= 4) then
  begin
    MapSource := aMapSource;
    if MapServer <> nil then MapServer.SetMapProvider(MapProviders[MapSource]);
  end;
end;

procedure TWebMap.AdjustOffset(Dx: Integer; Dy: Integer);
begin
  CenterPixel.X := CenterPixel.X - Dx;
  CenterPixel.Y := CenterPixel.y - Dy;
  CenterLatLon := FromPixelToLatLon(CenterPixel);
end;

procedure TWebMap.InitZoomlevel(NorthEast: TDoublePoint; SouthWest: TDoublePoint;
        MapRect: TRect);
begin
  ZoomLevel := mapcoords.GetZoomlevel(NorthEast, SouthWest, MapRect);
  CenterLatLon := DoublePoint( (NorthEast.X + SouthWest.X)/2,
                               (NorthEast.Y + SouthWest.Y)/2 );
end;

procedure TWebMap.AdjustZoomLevel(Dz: Integer; Dx: Integer; Dy: Integer);
begin
  ZoomLevel := ZoomLevel + Dz;
  if Dz > 0 then
    AdjustOffset(-Dx div 2, -Dy div 2)
  else
    AdjustOffset(Dx div 2, Dy div 2);
end;

procedure TWebMap.SetBoundsRect(W: Integer; H: Integer);
begin
  MapSize := 256 * (2 ** ZoomLevel);
  CenterPixel := FromLatLonToPixel(CenterLatLon);
  BoundsRect := GetBoundingBox(W, H);
end;

function TWebMap.GetBoundingBox(W: Integer; H: Integer): TDoubleRect;
var
  PixelPoint: TPoint;
  LowerLeft : TDoublePoint;
  UpperRight: TDoublePoint;
begin
  PixelPoint.X := CenterPixel.X - W div 2;
  PixelPoint.Y := CenterPixel.Y + H div 2;
  LowerLeft := FromPixelToLatLon(PixelPoint);
  PixelPoint.X := CenterPixel.X + W div 2;
  PixelPoint.Y := CenterPixel.Y - H div 2;
  UpperRight := FromPixelToLatLon(PixelPoint);
  Result := MapCoords.DoubleRect(LowerLeft, UpperRight);
end;

function TWebMap.FromLatLonToPixel(LatLon: TDoublePoint): TPoint;
var
  X, Y, F: Double;
begin
  X := (LatLon.X + 180) / 360;
  F := Sin(LatLon.Y * PI / 180);
  F := Min( Max(F, -0.9999), 0.9999);
  Y := 0.5 - Ln((1 + F) / (1 - F)) / (4 * PI);
  Result.X := Round((X * MapSize) + 0.5);
  Result.Y := Floor((Y * MapSize) + 0.5);
end;

function TWebMap.FromPixelToLatLon(Pixel: TPoint): TDoublePoint;
var
  X, Y: Double;
begin
  X := (Pixel.X / MapSize) - 0.5;
  Y := 0.5 - (Pixel.Y / MapSize);
  Result.X := 360 * X;
  Result.Y := 90 - 360 * Arctan(Exp(-Y*2*PI)) / PI;
end;

end.

