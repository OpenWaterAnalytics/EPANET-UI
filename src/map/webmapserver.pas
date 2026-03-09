{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       webmapserver
 Description:  a component that retrieves street map images
               from an internet map tile service
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit webmapserver;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, IntfGraphics, FileUtil, LazFileUtils, Dialogs,

  // These units are part of the lazMapViewerPkg package
  mvengine, mvdrawingengine, mvtypes, mvcache;

type
  TMapServer = class(TComponent)
  private
    Width: Integer;
    Height: Integer;
    Engine: TMapViewerEngine;
    DrawingEngine: TMvCustomDrawingEngine;
    BuiltinDrawingEngine: TMvCustomDrawingEngine;
  protected
    procedure DoDrawTile(const TileId: TTileId; X, Y: Integer;
      TileImg: TPictureCacheItem);
  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure SetMapProvider(aValue: string);
    procedure GetMapImage(Lon, Lat: Double; W, H, Z: Integer; var aBitmap: TBitmap);
    procedure LonLatToScreen(Lon, Lat:Double; var aPt: TPoint);
    procedure ScreenToLonLat(aPt: TPoint; var Lon, Lat: Double);
  end;

implementation

uses
 mvde_intfgraphics, mvdlefpc; // Additional units in lazMapViewerPkg

constructor TMapServer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Width := 300;
  Height := 300;
  Engine := TMapViewerEngine.Create(self);
  Engine.CachePath := SysUtils.GetTempDir(false) + 'cache/';
  Engine.CacheOnDisk := true;
  Engine.UseThreads := true;
  Engine.MapProvider:= 'OpenStreetMap Standard';
  Engine.OnDrawTile := @DoDrawTile;
  Engine.DrawTitleInGuiThread := false;
  Engine.DownloadEngine := TMvDEFpc.Create(self);
  Engine.DownloadEngine.Name := 'BuiltInDLE';
  BuiltinDrawingEngine := TMvIntfGraphicsDrawingEngine.Create(self);
  BuiltinDrawingEngine.Name := 'BuiltInDE';
  BuiltinDrawingEngine.CreateBuffer(Width, Height);
  DrawingEngine := BuiltinDrawingEngine;
  Engine.CacheItemClass := BuiltinDrawingEngine.GetCacheItemClass;
end;

destructor TMapServer.Destroy;
begin
  if DeleteDirectory(Engine.CachePath, true) then
    RemoveDirUTF8(Engine.CachePath);
  Engine.Free;
  inherited Destroy;
end;

procedure TMapServer.DoDrawTile(const TileId: TTileId; X, Y: integer;
  TileImg: TPictureCacheItem);
begin
  if Assigned(TileImg) then
    DrawingEngine.DrawCacheItem(X, Y, TileImg)
  else
    DrawingEngine.FillPixels(X, Y, X + TileSize.CX, Y + TileSize.CY, clWhite)
end;

procedure TMapServer.SetMapProvider(aValue: string);
begin
  try
    Engine.MapProvider := aValue;
  except
    raise;
  end;
end;

procedure TMapServer.GetMapImage(Lon, Lat: Double; W, H, Z: Integer;
  var aBitmap:TBitmap);
var
  LonLat: TRealPoint;
  TmpBitmap: TBitmap;
begin
  if aBitmap = nil then exit;
  Engine.Active := false;
  Engine.Zoom := Z;
  LonLat.Lon := Lon;
  LonLat.Lat := Lat;
  Engine.Center := LonLat;
  Engine.SetSize(W, H);
  DrawingEngine.CreateBuffer(W, H);
  Engine.Active := true;
  Engine.Jobqueue.WaitAllJobTerminated(Engine);
  Engine.Redraw;
  TmpBitmap := DrawingEngine.SaveToImage(TBitmap) as TBitmap;
  Engine.Active := false;
  with aBitmap do
  begin
    if (Width <> W) or (Height <> H) then SetSize(W, H);
    Canvas.Draw(0,0,TmpBitmap);
  end;
  TmpBitmap.Free;
end;

procedure TMapServer.LonLatToScreen(Lon, Lat:Double; var aPt: TPoint);
var
  LonLat: TRealPoint;
begin
  LonLat.Lon := Lon;
  LonLat.Lat := Lat;
  aPt := Engine.LatLonToScreen(LonLat);
end;

procedure TMapServer.ScreenToLonLat(aPt: TPoint; var Lon, Lat: Double);
var
  LonLat: TRealPoint;
begin
  LonLat := Engine.ScreenToLatLon(aPt);
  Lon := LonLat.Lon;
  Lat := LonLat.Lat;
end;

end.

