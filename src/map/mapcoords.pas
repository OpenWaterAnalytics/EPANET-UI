{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mapcoords
 Description:  utility functions for map coordinates
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit mapcoords;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Math;

type
  TDoublePoint = record
    X: Double;
    Y: Double;
  end;

  TDoubleRect = record
    LowerLeft: TDoublePoint;
    UpperRight: TDoublePoint;
  end;

  TPolygon = array of TDoublePoint;

  TScalingInfo = record
    CW: TDoublePoint;  // world coordinates of map center
    CP: TPoint;        // pixel coordinates of map center
    WP: Double;        // world distance per pixel
  end;

function  DoublePoint(X, Y: Double): TDoublePoint;

function  DoubleRect(LowerLeft, UpperRight: TDoublePoint): TDoubleRect;

function  GetBounds(Bounds: TDoubleRect): TDoubleRect;

function  GetZoomLevel(NorthEast: TDoublePoint; SouthWest: TDoublePoint;
            MapRect: TRect): Integer;

function  HasLatLonCoords(MapExtent: TDoubleRect): Boolean;

function  InBounds(W: TDoublePoint; Bounds: TDoubleRect): Boolean;

procedure DoAffineTransform(FromRect, ToRect: TDoubleRect);

procedure DoAffineTransform(Axx, Bxx, Cxx, Ayy, Byy, Cyy: Double);

procedure DoScalingTransform(FromScaling, ToScaling: TScalingInfo);

function  DoProjectionTransform(FromProj, ToProj: string;
            var Bounds: TDoubleRect): Boolean;

function  CanProjectionTransform(FromProj, ToProj: string;
            Bounds: TDoubleRect): Boolean;

function  FromWGS84ToWebMercator(LatLng: TDoublePoint): TDoublePoint;

function  ManhattanDistance(P1, P2: TDoublePoint): Double;

// Caches each node's coordinates in the project's native (non-WGS84)
// coordinate system, taken BEFORE any transform to WGS84 for basemap
// display happens. This lets Save() write out the pristine original
// coordinates every time, instead of round-tripping through PROJ on
// every save (which accumulates rounding drift).
procedure CacheNativeNodeCoords;

function  HasCachedNodeCoords: Boolean;

procedure GetCachedNodeCoord(Index: Integer; var X, Y: Double);

function  GetCachedVertexCount(LinkIndex: Integer): Integer;

procedure GetCachedVertexCoord(LinkIndex, VertexIndex: Integer; var X, Y: Double);

procedure GetCachedLabelCoord(Index: Integer; var X, Y: Double);

implementation

uses
  project, projtransform;

const
  ScalingTransform = 0;
  AffineTransform = 1;
  ProjectionTransform = 2;

var
  S1: TScalingInfo;
  S2: TScalingInfo;               // Used for scaling transform
  CachedNodeX: array of Double;   // Cached native-CRS node X coords
  CachedNodeY: array of Double;   // Cached native-CRS node Y coords
  CachedVertexX: array of array of Double;  // [LinkIndex][VertexIndex]
  CachedVertexY: array of array of Double;
  CachedVertexCount: array of Integer;      // [LinkIndex]
  CachedLabelX: array of Double;
  CachedLabelY: array of Double;
  NodeCoordsCached: Boolean = false;
  Ax: Double;                     // Used for affine transform
  Ay: Double;
  Bx: Double;
  By: Double;
  Cx: Double;
  Cy: Double;
  ProjTrans: TProjTransform;      // Used for projection transform

function  DoublePoint(X, Y: Double): TDoublePoint;
begin
  Result.X := X;
  Result.Y := Y;
end;

function  DoubleRect(LowerLeft, UpperRight: TDoublePoint): TDoubleRect;
begin
  Result.LowerLeft := LowerLeft;
  Result.UpperRight := UpperRight;
end;

function GetBounds(Bounds: TDoubleRect): TDoubleRect;
var
  Xmin : Double = 1.e50;
  Ymin : Double = 1.e50;
  Xmax : Double = -1.e50;
  Ymax : Double = -1.e50;
  X : Double= 0;
  Y : Double= 0;
  Bufr: Double;
  I: Integer;
  NumNodes: Integer;
  NumLabels: Integer;
begin
  // Get number of nodes & labels
  NumNodes := project.GetItemCount(ctNodes);
  NumLabels := project.GetItemCount(ctLabels);

  // If no nodes and labels return the current bounding rectangle
  Result := Bounds;
  if (NumNodes = 0)
  and (NumLabels = 0) then
    exit;

  // Find min/max X,Y coords.
  for I := 1 to NumNodes do
  begin
    if project.GetNodeCoord(I, X, Y) then
    begin
      Xmin := Min(Xmin, X);
      Ymin := Min(Ymin, Y);
      Xmax := Max(Xmax, X);
      Ymax := Max(Ymax, Y);
    end;
  end;
  for I := 1 to NumLabels do
  begin
    if project.GetLabelCoord(I, X, Y) then
    begin
      Xmin := Min(Xmin, X);
      Ymin := Min(Ymin, Y);
      Xmax := Max(Xmax, X);
      Ymax := Max(Ymax, Y);
    end;
  end;
  if (Xmin = 1.e50)
  and (Ymin = 1.e50) then
    exit;

  // Expand bounds by a 5% buffer
  Bufr := 0.05 * (Xmax - Xmin);
  if Bufr = 0 then Bufr := 10;
  Xmin := Xmin - Bufr;
  Xmax := Xmax + Bufr;
  Bufr := 0.05 * (Ymax - Ymin);
  if Bufr = 0 then Bufr := 10;
  Ymin := Ymin - Bufr;
  Ymax := Ymax + Bufr;

  // Build a bounding rectangle from the min/max points
  Result.LowerLeft := DoublePoint(Xmin, Ymin);
  Result.UpperRight := DoublePoint(Xmax, Ymax);
end;

function InBounds(W: TDoublePoint; Bounds: TDoubleRect): Boolean;
begin
  Result := true;
  if (W.X < Bounds.LowerLeft.X)
  or (W.X > Bounds.UpperRight.X)
  or (W.Y < Bounds.LowerLeft.Y)
  or (W.Y > Bounds.UpperRight.Y) then
    Result := false;
end;

function  HasLatLonCoords(MapExtent: TDoubleRect): Boolean;
var
  Delta: Double;
begin
  Result := false;
  with MapExtent do
  begin
    if Max(Abs(LowerLeft.X), Abs(UpperRight.X)) > 180 then exit;
    if Max(Abs(LowerLeft.Y), Abs(UpperRight.Y)) > 90 then exit;
    Delta := Abs(LowerLeft.X - UpperRight.X);
    if Delta < 1e-6 then exit;
    Delta := Abs(LowerLeft.Y - UpperRight.Y);
    if Delta < 1e-6 then exit;
  end;
  Result := true;
end;

function ApplyScalingTransform(X, Y: Double): TDoublePoint;
var
  P: TPoint;
  Z: Double;
begin
  Z := (X - S1.CW.X) / S1.WP;
  P.X := S1.CP.X + Round(Z);
  X := S2.CW.X + (P.X - S2.CP.X) * S2.WP;
  Z := (Y - S1.CW.Y) / S1.WP;
  P.Y := S1.CP.Y - Round(Z);
  Y := S2.CW.Y + (S2.CP.Y - P.Y) * S2.WP;
  Result.X := X;
  Result.Y := Y;
end;

function ApplyAffineTransform(X, Y: Double): TDoublePoint;
begin
  Result.X := Ax*X + Bx*Y + Cx;
  Result.Y := Ay*X + By*Y + Cy;
end;

function ApplyProjectionTransform(var X, Y: Double): TDoublePoint;
var
  OrigX, OrigY: Double;
begin
  // Keep a copy of the original coordinates. PROJ's pj_transform can
  // write HUGE_VAL (Infinity) directly into X/Y *even when it fails*,
  // so we cannot trust X/Y after a failed call - restore the originals.
  OrigX := X;
  OrigY := Y;
  if (not ProjTrans.Transform(X,Y))
  or IsInfinite(X) or IsInfinite(Y) or IsNan(X) or IsNan(Y) then
  begin
    X := OrigX;
    Y := OrigY;
  end;
  Result.X := X;
  Result.Y := Y;
end;

function ApplyTransform(TransformType: Integer; X, Y: Double): TDoublePoint;
begin
  Result := DoublePoint(0,0);
  case TransformType of
    AffineTransform:
      Result := ApplyAffineTransform(X, Y);
    ScalingTransform:
      Result := ApplyScalingTransform(X, Y);
    ProjectionTransform:
      Result := ApplyProjectionTransform(X, Y);
  end;
end;

procedure TransformNodeCoords(TransformType: Integer);
var
  I: Integer;
  X: Double = 0;
  Y: Double = 0;
  DP: TDoublePoint;
begin
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeCoord(I, X, Y) then
    begin
      DP := ApplyTransform(TransformType, X, Y);
      project.SetNodeCoord(I, DP.X, DP.Y);
    end;
  end;
end;

procedure TransformVertexCoords(TransformType: Integer);
var
  I:         Integer;
  J:         Integer;
  X:         Double = 0;
  Y:         Double = 0;
  DP:        TDoublePoint;
  Vx:        array of Double;
  Vy:        array of Double;
  Vcount:    Integer;
  MaxVcount: Integer;
begin
  MaxVcount := 0;
  SetLength(Vx, 0);
  SetLength(Vy, 0);
  for I := 1 to project.GetItemCount(ctLinks) do
  begin
    Vcount := project.GetVertexCount(I);
    if Vcount > 0 then
    begin
      if Vcount > MaxVcount then
      begin
        SetLength(Vx, Vcount);
        SetLength(Vy, Vcount);
        MaxVcount := Vcount;
      end;
      for J := 1 to Vcount do
      begin
        project.GetVertexCoord(I, J, X, Y);
        DP := ApplyTransform(TransformType, X, Y);
        Vx[J-1] := DP.X;
        Vy[J-1] := DP.Y;
      end;
      project.SetVertexCoords(I, Vx, Vy, Vcount);
    end;
  end;
  SetLength(Vx, 0);
  SetLength(Vy, 0);
end;

procedure TransformLabelCoords(TransformType: Integer);
var
  I:  Integer;
  X:  Double = 0;
  Y:  Double = 0;
  DP: TDoublePoint;
begin
  for I := 1 to project.GetItemCount(ctLabels) do
  begin
    if project.GetLabelCoord(I, X, Y) then
    begin
      DP := ApplyTransform(TransformType, X, Y);
      Project.SetLabelCoord(I, DP.X, DP.Y);
    end;
  end;
end;

procedure DoAffineTransform(FromRect, ToRect: TDoubleRect);
var
  LL1: TDoublePoint;
  LL2: TDoublePoint;
  UR1: TDoublePoint;
  UR2: TDoublePoint;
begin
  // Lower left coordinates of both rectangles
  LL1 := FromRect.LowerLeft;
  UR1 := FromRect.UpperRight;
  LL2 := ToRect.LowerLeft;
  UR2 := ToRect.UpperRight;

  // Affine transform coeffs.
  // (Xto = Ax * Xfrom + Bx * Yfrom + Cx)
  Ax := (LL2.X - UR2.X) / (LL1.X - UR1.X);
  Cx := LL2.X - Ax * LL1.X;
  By := (LL2.Y - UR2.Y) / (LL1.Y - UR1.Y);
  Cy := LL2.Y - By * LL1.Y;
  Bx := 0;
  Ay := 0;

  // Apply affine transform to all network objects
  TransformNodeCoords(AffineTransform);
  TransformVertexCoords(AffineTransform);
  TransformLabelCoords(AffineTransform);
end;

procedure DoAffineTransform(Axx, Bxx, Cxx, Ayy, Byy, Cyy: Double);
begin
  Ax := Axx;
  Bx := Bxx;
  Cx := Cxx;
  Ay := Ayy;
  By := Byy;
  Cy := Cyy;
  TransformNodeCoords(AffineTransform);
  TransformVertexCoords(AffineTransform);
  TransformLabelCoords(AffineTransform);
end;

procedure DoScalingTransform(FromScaling, ToScaling: TScalingInfo);
begin
  // Assign scaling info to global variables S1 & S2 for convenience
  S1 := FromScaling;
  S2 := ToScaling;

  // Transform all node, link vertex & map label coordinates
  TransformNodeCoords(ScalingTransform);
  TransformVertexCoords(ScalingTransform);
  TransformLabelCoords(ScalingTransform);
end;

function PointsEqual(P1, P2: TDoublePoint): Boolean;
const
  AbsTol = 0.1;
  RelTol = 0.001;
begin
  Result := False;
  if Abs(P1.X - P2.X) > AbsTol + RelTol * Abs(P2.X) then exit;
  if Abs(P1.Y - P2.Y) > AbsTol + RelTol * Abs(P2.Y) then exit;
  Result := true;
end;

function  CanProjectionTransform(FromProj, ToProj: string;
  Bounds: TDoubleRect): Boolean;
var
  ToBounds: TDoubleRect;
begin
  Result := false;
  ProjTrans := TProjTransform.Create;
  try

    // Check that coords. of current bounding rectangle can be transformed
    if ProjTrans.SetProjections(FromProj, ToProj) then
    begin
      ToBounds := Bounds;
      ApplyProjectionTransform(ToBounds.LowerLeft.X, ToBounds.LowerLeft.Y);
      ApplyProjectionTransform(ToBounds.UpperRight.X, ToBounds.UpperRight.Y);
      if SameText(ToProj, '4326') then
      begin
        if not HasLatLonCoords(ToBounds) then exit;
      end;
    end;

    // Check that a reverse transform can be made
    if ProjTrans.SetProjections(ToProj, FromProj) then
    begin
      ApplyProjectionTransform(ToBounds.LowerLeft.X, ToBounds.LowerLeft.Y);
      if not PointsEqual(ToBounds.LowerLeft, Bounds.LowerLeft) then exit;
      ApplyProjectionTransform(ToBounds.UpperRight.X, ToBounds.UpperRight.Y);
      if not PointsEqual(ToBounds.UpperRight, Bounds.UpperRight) then exit;
    end;
    Result := true;

  finally
    ProjTrans.Free;
  end;
end;

function DoProjectionTransform(FromProj, ToProj: string;
  var Bounds: TDoubleRect): Boolean;
begin
  // Create a Projection Transform object
  Result := false;
  ProjTrans := TProjTransform.Create;
  try

    if ProjTrans.SetProjections(FromProj, ToProj) then
    begin
      // Transform coords. of bounding rectangle
      ApplyProjectionTransform(Bounds.LowerLeft.X, Bounds.LowerLeft.Y);
      ApplyProjectionTransform(Bounds.UpperRight.X, Bounds.UpperRight.Y);

      // Transform coords. for all map objects
      TransformNodeCoords(ProjectionTransform);
      TransformVertexCoords(ProjectionTransform);
      TransformLabelCoords(ProjectionTransform);
      Result := true;
    end;

  finally
    ProjTrans.Free;
  end;
end;

function GetZoomLevel(NorthEast: TDoublePoint; SouthWest: TDoublePoint;
  MapRect: TRect): Integer;
//
//  Find zoom level for a tiled web map bounded by Northeast and
//  SouthWest lat/lon coordinates displayed in a MapRect screen window
//
const
  WORLD_DIM = 256;
  ZOOM_MAX = 21;

  function LatRad(Lat: Double): Double;
  var
    a, radX2: Double;
  begin
    a := Sin(Lat * PI / 180);
    radX2 := Ln((1 + a) / (1 - a)) / 2;
    Result := Max(Min(radX2, PI), -PI) / 2;
  end;

  function zoom(mapPx: Integer; worldPx: Integer; fraction: Double): Integer;
  begin
    Result := Floor(Ln(mapPx / worldPx / fraction) / Ln(2));
  end;

var
  latFraction: Double;
  lonDiff:     Double;
  lonFraction: Double;
  latZoom:     Integer;
  lonZoom:     Integer;
begin
  latFraction := (LatRad(NorthEast.Y) - LatRad(SouthWest.Y)) / PI;
  latFraction := Abs(latFraction);
  lonDiff := NorthEast.X - SouthWest.X;
  if lonDiff < 0 then lonDiff := lonDiff + 360;
  lonFraction := lonDiff / 360;
  latZoom := zoom(MapRect.Height, WORLD_DIM, latFraction);
  lonZoom := zoom(MapRect.Width, WORLD_DIM, lonFraction);
  Result := Min(latZoom, lonZoom);
  Result := Min(Result, ZOOM_MAX);
end;

function FromWGS84ToWebMercator(LatLng: TDoublePoint): TDoublePoint;
//
//  Convert point LatLng from WGS84 projection to Web Mercator projection
//
var
  A: Double;
begin
  if (Abs(LatLng.X) > 180)
  or (Abs(LatLng.Y) > 90)
  then
    Result := LatLng
  else
  begin
    Result.X := 6378137.0 * LatLng.X * 0.017453292519943295;
    A := Sin(LatLng.Y * 0.017453292519943295);
    Result.Y := 3189068.5 * Ln((1.0 + A) / (1.0 - A));
  end;
end;

function  ManhattanDistance(P1, P2: TDoublePoint): Double;
//
//  Find the Manhattan distance between two points
//
begin
  Result := Abs(P2.X - P1.X) + Abs(P2.Y - P1.Y);
end;

procedure CacheNativeNodeCoords;
var
  I, J:    Integer;
  N:       Integer;
  Vcount:  Integer;
  X, Y:    Double;
begin
  // Nodes
  N := project.GetItemCount(ctNodes);
  SetLength(CachedNodeX, N+1);
  SetLength(CachedNodeY, N+1);
  for I := 1 to N do
  begin
    if project.GetNodeCoord(I, X, Y) then
    begin
      CachedNodeX[I] := X;
      CachedNodeY[I] := Y;
    end;
  end;

  // Link vertices (interior bend points)
  N := project.GetItemCount(ctLinks);
  SetLength(CachedVertexX, N+1);
  SetLength(CachedVertexY, N+1);
  SetLength(CachedVertexCount, N+1);
  for I := 1 to N do
  begin
    Vcount := project.GetVertexCount(I);
    CachedVertexCount[I] := Vcount;
    SetLength(CachedVertexX[I], Vcount+1);
    SetLength(CachedVertexY[I], Vcount+1);
    for J := 1 to Vcount do
      project.GetVertexCoord(I, J, CachedVertexX[I][J], CachedVertexY[I][J]);
  end;

  // Map labels
  N := project.GetItemCount(ctLabels);
  SetLength(CachedLabelX, N+1);
  SetLength(CachedLabelY, N+1);
  for I := 1 to N do
  begin
    if project.GetLabelCoord(I, X, Y) then
    begin
      CachedLabelX[I] := X;
      CachedLabelY[I] := Y;
    end;
  end;

  NodeCoordsCached := true;
end;

function  HasCachedNodeCoords: Boolean;
begin
  Result := NodeCoordsCached and (Length(CachedNodeX) > 0);
end;

procedure GetCachedNodeCoord(Index: Integer; var X, Y: Double);
begin
  if NodeCoordsCached and (Index >= 0) and (Index <= High(CachedNodeX)) then
  begin
    X := CachedNodeX[Index];
    Y := CachedNodeY[Index];
  end;
end;

function  GetCachedVertexCount(LinkIndex: Integer): Integer;
begin
  Result := 0;
  if NodeCoordsCached and (LinkIndex >= 0) and (LinkIndex <= High(CachedVertexCount)) then
    Result := CachedVertexCount[LinkIndex];
end;

procedure GetCachedVertexCoord(LinkIndex, VertexIndex: Integer; var X, Y: Double);
begin
  if NodeCoordsCached and (LinkIndex >= 0) and (LinkIndex <= High(CachedVertexX))
  and (VertexIndex >= 0) and (VertexIndex <= High(CachedVertexX[LinkIndex])) then
  begin
    X := CachedVertexX[LinkIndex][VertexIndex];
    Y := CachedVertexY[LinkIndex][VertexIndex];
  end;
end;

procedure GetCachedLabelCoord(Index: Integer; var X, Y: Double);
begin
  if NodeCoordsCached and (Index >= 0) and (Index <= High(CachedLabelX)) then
  begin
    X := CachedLabelX[Index];
    Y := CachedLabelY[Index];
  end;
end;

end.
