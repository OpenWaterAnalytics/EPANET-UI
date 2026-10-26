{====================================================================
 Project:      EPANET-UI
 Version:      1.0.5
 Module:       dxviewer
 Description:  draws pipe network from a DXF file onto a bitmap.
 License:      see LICENSE
 Last Updated: 10/17/2026
=====================================================================}

unit dxfviewer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Math,  Dialogs;

function  ViewDxfFile(DxfFileName: string; Layers: TStringList;
            var Bitmap: TBitmap): Boolean;

implementation

uses
  project, dxfloader;

var
  Xmin:     Double;
  Xmax:     Double;  // Horizontal world extent
  Ymin:     Double;
  Ymax:     Double;  // Vertical world extent
  CenterWx: Double;  // World center X point
  CenterWy: Double;  // World center Y point
  WPP:      Double;  // World per pixel scaling
  CenterP:  TPoint;  // Bitmap center point

function GetPoint(const X: Double; const Y: Double):TPoint;
begin
  Result.X := CenterP.X + Round((X - CenterWx) / WPP);
  Result.Y := CenterP.Y - Round((Y - CenterWy) / WPP);
end;

procedure DrawLink(var Bitmap: TBitmap; var Vx: array of Double;
            var Vy: array of Double; Vcount: Integer);
var
  P: TPoint;
  I: Integer;
begin
  if Vcount < 2 then exit;
  P := GetPoint(Vx[0], Vy[0]);
  Bitmap.Canvas.MoveTo(P);
  for I := 1 to Vcount-1 do
  begin
    P := GetPoint(Vx[I], Vy[I]);
    Bitmap.Canvas.LineTo(P);
  end;
end;

procedure ScaleBitmap(var Bitmap: TBitmap);
var
  Dx: Double;
  Dy: Double;
  WPPx: Double;
  WPPy: Double;
begin
  // Center of bounding rectangle
  Dx := Double(Xmax - Xmin);
  Dy := Double(Ymax - Ymin);
  CenterWx := Xmin + Dx/2.0;
  CenterWy := Ymin + Dy/2.0;
  CenterP := Point(Bitmap.Width div 2, Bitmap.Height div 2);

  // World distance units per pixel in the X & Y directions
  WPPx := Dx / Bitmap.Width;
  WPPy := Dy / Bitmap.Height;

  // Maintain a 1:1 aspect ratio
  if WPPy > WPPx then WPP := WPPy
  else WPP := WPPx;
end;

function GetExtents(var F: TextFile; Layers: TStringList): Boolean;
var
  Vx: array[0..Project.MAX_VERTICES] of Double;
  Vy: array[0..Project.MAX_VERTICES] of Double;
  Vcount: Integer;
  I: Integer;
  Bufr: Double;
begin
  // Locate ENTITIES section in the DXF file
  Result := false;
  if not dxfloader.FindEntitiesSection(F) then exit;

  // Initialize extents
  Xmin := math.MaxDouble;
  Ymin := Xmin;
  Xmax := -math.MaxDouble;
  Ymax := Xmax;

  // Read coordinates of each vertex point
  while not Eof(F) do
  begin
    dxfloader.GetLinkVertices(F, Layers, Vx, Vy, Vcount);

    // Update extents
    for I := 0 to Vcount - 1 do
    begin
      Xmin := Min(Xmin, Vx[I]);
      Ymin := Min(Ymin, Vy[I]);
      Xmax := Max(Xmax, Vx[I]);
      Ymax := Max(Ymax, Vy[I]);
    end;
  end;

  // Expand extents by a 5% buffer
  Bufr := 0.05 * (Xmax - Xmin);
  if Bufr = 0 then Bufr := 10;
  Xmin := Xmin - Bufr;
  Xmax := Xmax + Bufr;
  Bufr := 0.05 * (Ymax - Ymin);
  if Bufr = 0 then Bufr := 10;
  Ymin := Ymin - Bufr;
  Ymax := Ymax + Bufr;
  Result := true;
end;

function  ViewDxfFile(DxfFileName: string; Layers: TStringList;
  var Bitmap: TBitmap): Boolean;
var
  F: TextFile;
  Vx: array[0..Project.MAX_VERTICES] of Double;
  Vy: array[0..Project.MAX_VERTICES] of Double;
  Vcount: Integer;
begin
  // Check for valid bitmap object
  Result := false;
  if Bitmap = nil then exit;
  if (Bitmap.Width = 0)
  or (Bitmap.Height = 0) then
    exit;

  // Process the DXF file
  AssignFile(F, DxfFileName);
  try
    // Get drawing extents
    Reset(F);
    if not GetExtents(F, Layers) then exit;

    // Locate ENTITIES section of file
    Reset(F);
    if not dxfloader.FindEntitiesSection(F) then exit;

    // Scale Bitmap pixels to drawing extents
    ScaleBitmap(Bitmap);

    // Prepare Bitmap's canvas
    with Bitmap.Canvas do
    begin
      Pen.Color := clBlack;
      Brush.Color := clWhite;
      Brush.Style := bsSolid;
      Rectangle(0, 0, Bitmap.Width, Bitmap.Height);
    end;

    // Extract vertices of each network link and draw it on bitmap
    while not Eof(F) do
    begin
      dxfloader.GetLinkVertices(F, Layers, Vx, Vy, Vcount);
      DrawLink(Bitmap, Vx, Vy, Vcount);
    end;
    Result := true;
  finally
    CloseFile(F);
  end;
end;

end.
