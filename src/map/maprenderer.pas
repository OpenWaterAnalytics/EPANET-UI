{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       maprenderer
 Description:  draws the pipe network on the Canvas of a TMap object
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit maprenderer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Math, Dialogs,
  map;

const
  VERTEX_TOL = 10;  // Pixel tolerance between drawn link vertices

procedure DrawNetwork(Map: TMap);

implementation

uses
  project, mapthemes, mapoptions, maplabel, config;

var
  LabelColor:    TColor;
  ArrowColor:    TColor;
  NotationColor: TColor;
  OutlineColor:  TColor;

procedure DrawArrowHead(Map: TMap; X: Integer; Y: Integer; Size: Integer;
  Color: TColor; Direction: Integer; Asin: Double; Acos: Double);
var
  X1:   Integer;
  X2:   Integer;
  Y1:   Integer;
  Y2:   Integer;
  S:    Double;
  Z:    Double;
  Poly: array[0..2] of TPoint;
begin
  S := Size * Direction;
  Z := (-Acos + Asin)*S;
  X1 := X + Round(Z);
  Z := (Asin + Acos)*S;
  Y1 := Y - Round(Z);
  Z := (-Acos - Asin)*S;
  X2 := X + Round(Z);
  Z := (Asin - Acos)*S;
  Y2 := Y - Round(Z);
  Poly[0] := Point(X, Y);
  Poly[1] := Point(X1, Y1);
  Poly[2] := Point(X2, Y2);
  with Map.Canvas do
  begin
    Pen.Width := 1;
    Pen.Color := OutlineColor;
    Brush.Color := Color;
    Polygon(Poly);
  end;
end;

procedure DrawPump(Map: TMap; X: Integer; Y: Integer; Size: Integer; Color: TColor;
      Direction: Integer; Asin: Double; Acos: Double);
var
  Poly: array[0..3] of TPoint;
  Xi:   Integer;
  Yi:   Integer;
  R:    Integer;
begin
  R := 2*Size;
  Poly[0] := Point(X, Y);
  Xi := X + Round(Acos*R);
  Yi := Y + Round(Asin*R);
  Poly[1] := Point(Xi, Yi);
  Xi := X + Round((Acos + 0.5*Asin*Direction)*R);
  Yi := Y + Round((Asin - 0.5*Acos*Direction)*R);
  Poly[2] := Point(Xi, Yi);
  Xi := X + Round(+0.5*Asin*R*Direction);
  Yi := Y + Round(-0.5*Acos*R*Direction);
  Poly[3] := Point(Xi, Yi);
  with Map.Canvas do
  begin
    Pen.Width := 1;
    Pen.Color := OutlineColor;
    Brush.Color := Color;
    Polygon(Poly);
    Ellipse(X-Size, Y-Size, X+Size, Y+Size);
  end;
end;

procedure DrawValve(Map: TMap; X: Integer; Y: Integer; Size: Integer; Color: TColor;
      Asin: Double; Acos: Double);
begin
  DrawArrowHead(Map, X, Y, Size, Color, 1, Asin, Acos);  // First half of valve
  DrawArrowHead(Map, X, Y, Size, Color, -1, Asin, Acos); // Second half of valve
end;

procedure DrawLink(Map: TMap; LinkIndex: Integer; P1: TPoint; P2: TPoint);
var
  J: Integer;
  X: Double = 0;
  Y: Double = 0;
  P: TPoint;
begin
  Map.Canvas.MoveTo(P1.X, P1.Y);
  for J := 1 to project.GetVertexCount(LinkIndex) do
  begin
    if not project.GetVertexCoord(LinkIndex, J, X, Y) then continue;
    P := Map.WorldToScreen(X, Y);
    if (abs(P.x - P1.x) > VERTEX_TOL)
    or (abs(P.y - P1.y) > VERTEX_TOL) then
    begin
      Map.Canvas.LineTo(P.X, P.Y);
      P1 := P;
    end;
  end;
  Map.Canvas.LineTo(P2.X, P2.Y);
end;

function  ShowLinkSymbol(Map: TMap; LinkType: Integer): Boolean;
begin
  Result := false;
  if Map.Options.ShowLinkArrows then
    Result := true
  else if (LinkType = ltPump) and Map.Options.ShowPumps then
    Result := true
  else if (LinkType = ltValve) and Map.Options.ShowValves then
    Result := true;
end;

procedure DrawLinkSymbol(Map: TMap; LinkIndex: Integer; LinkType: Integer;
      P1: TPoint; P2: TPoint; Size: Integer; Color: TColor);
var
  P:    TPoint;
  Dx:   Double;
  Dy:   Double;
  Asin: Double;
  Acos: Double;
begin
  // Link midpoint pixel
  P := Point((P1.X + P2.X) div 2, (P1.Y + P2.Y) div 2);

  // Sine & cosine of link's angle of inclination
  Dx := (P2.X - P1.X);
  Dy := (P2.Y - P1.Y);
  SinCos(arctan2(Dy, Dx), Asin, Acos);

  // Draw link symbol
  if (Map.Options.ShowPumps) and (LinkType = ltPump) then
    DrawPump(Map, P.X, P.Y, Size, Color, Sign(Dx), Asin, Acos)
  else if (Map.Options.ShowValves) and (LinkType = ltValve) then
    DrawValve(Map, P.X, P.Y, Size, Color, Asin, Acos);
  if Map.Options.ShowLinkArrows then
  begin
    DrawArrowHead(Map, P.X, P.Y, Map.Options.ArrowSize, ArrowColor,
      mapthemes.GetFlowDir(LinkIndex), Asin, Acos);
  end;
end;

function ShowLinkNotation(Map: TMap): Boolean;
begin
  Result := false;
  if Map.ZoomLevel < Map.Options.NotationZoom then exit;
  if Map.Options.ShowLinkIDs or Map.Options.ShowLinkValues then
    Result := true;
end;

procedure DrawLinkID(Map:TMap; LinkIndex: Integer; P1: TPoint; P2: TPoint;
      Size: Integer);
var
  S: string;
  X: Integer;
  Y: Integer;
begin
  S := project.GetID(ctLinks, LinkIndex);
  X := (P1.X + P2.X) div 2;
  Y := (P1.Y + P2.Y) div 2;
  if (Abs(P2.Y - P1.Y) < Size) then
  begin
    X := X - (Map.Canvas.TextWidth(S) div 2);
    Y := Y - Size - Map.CharHeight;
  end
  else
  begin
    X := X - Map.Canvas.TextWidth(S) - Size;
    if (P1.Y < P2.Y) and (P1.X < P2.X) then
      Y := Y + Size
    else
      Y := Y - Size - Map.CharHeight;
  end;
  Map.Canvas.TextOut(X, Y, S);
end;

procedure DrawLinkValue(Map:TMap; LinkIndex: Integer; P1: TPoint; P2: TPoint;
      Size: Integer);
var
  S: string;
  V: Single;
  X: Integer;
  Y: Integer;
begin
  // Retrieve link value as a string
  V := mapthemes.GetCurrentThemeValue(ctLinks, LinkIndex);
  if V = MISSING then
    S := 'N/A'
  else
    S := FloatToStrF(V, ffFixed, 7, config.DecimalPlaces);

  // Find mid-point of link
  X := (P1.X + P2.X) div 2;
  Y := (P1.Y + P2.Y) div 2;

  // Find offset from mid-point
  if (Abs(P2.Y - P1.Y) < Size) then
  begin
    X := X - (Map.Canvas.TextWidth(S) div 2);
    Y := Y + Size;
  end
  else
  begin
    X := X + Size;
    if ((P1.Y < P2.Y) and (P1.X < P2.X)) then
      Y := Y - Size - Map.CharHeight
    else
      Y := Y + Size;
  end;
  Map.Canvas.TextOut(X+2, Y+2, S);
end;

procedure DrawLinkNotation(Map: TMap; LinkIndex: Integer; P1: TPoint;
      P2: TPoint; Size: Integer);
var
  SavedColor: TColor;
begin
  with Map.Canvas do
  begin
    SavedColor := Brush.Color;
    Brush.Color := Map.Options.BackColor;
    Font.Color := NotationColor;
    if not Map.Options.NotationOpaque then Brush.Style := bsClear;
  end;
  if Map.Options.ShowLinkIDs then
    DrawLinkID(Map, LinkIndex, P1, P2, Size);
  if Map.Options.ShowLinkValues and (MapThemes.LinkTheme > 0) then
    DrawLinkValue(Map, LinkIndex, P1, P2, Size);
  Map.Canvas.Brush.Color := SavedColor;
  Map.Canvas.Brush.Style := bsSolid;
end;

procedure DrawReservoir(Map: TMap; X: Integer; Y: Integer; Size: Integer);
var
  Poly: array[0..3] of TPoint;
  W:    Integer;
begin
  if (Map.Options.ShowTanks) then
  begin
    W := Size + 3;
    Poly[0] := Point(X - W, Y - W);
    Poly[1] := Point(X - W, Y + Size + 1);
    Poly[2] := Point(X + W + 1, Y + Size + 1);
    Poly[3] := Point(X + W + 1, Y - W - 1);
    Map.Canvas.PolyLine(Poly);
    Map.Canvas.Rectangle(X - W, Y - Size, X + W + 2, Y + Size + 2);
  end
  else
    Map.Canvas.Rectangle(X - Size, Y - Size, X + Size + 1, Y + Size + 1);
end;

procedure DrawTank(Map: TMap; X: Integer; Y: Integer; Size: Integer);
var
  W: Integer;
begin
  if (Map.Options.ShowTanks) then
  begin
    W := Size + 3;
    Map.Canvas.Rectangle(X - Size, Y, X + Size + 1, Y + W + 1);
    Map.Canvas.RoundRect(X - W, Y - W, X + W + 1, Y + 1, 3, 3);
  end
  else
    Map.Canvas.Rectangle(X - Size, Y - Size, X + Size + 1, Y + Size + 1);
end;

procedure DrawNodeID(Map: TMap; NodeIndex: Integer; NodeType: Integer;
      P: TPoint; Size: Integer);
var
  Offset:   Integer;
  LinkSize: Integer;
begin
  Offset := Size + Map.CharHeight + 1;
  LinkSize := Map.Options.LinkSize;
  if Map.Options.ShowLinkBorder then LinkSize := LinkSize + 2;
  if (Map.Options.ShowTanks)
  and (NodeType <> ntJunction) then
  begin
    if NodeType = ntReservoir then
      Offset := Offset + Size + 1
    else if NodeType = ntTank then
      Offset := Offset + Size + 3;
  end;
  Map.Canvas.TextOut(P.X+LinkSize, P.Y-Offset, project.GetID(ctNodes, NodeIndex));
end;

procedure DrawNodeValue(Map: TMap; NodeIndex: Integer; NodeType: Integer;
      P: TPoint; Size: Integer);
var
  Offset:   Integer;
  LinkSize: Integer;
  V:        Single;
  S:        string;
begin
  V := mapthemes.GetCurrentThemeValue(ctNodes, NodeIndex);
  if V = MISSING then
    S := 'N/A'
  else
    S := FloatToStrF(V, ffFixed, 7, config.DecimalPlaces);
  LinkSize := Map.Options.LinkSize;
  if Map.Options.ShowLinkBorder then LinkSize := LinkSize + 2;
  if NodeType = ntTank then
    Offset := Size + 6
  else
    Offset := Size + 3;
  Map.Canvas.TextOut(P.X+LinkSize, P.Y+Offset, S);
end;

procedure DrawAllLinks(Map: TMap);
var
  I:            Integer;
  N1:           Integer = 0;
  N2:           Integer = 0;
  X1:           Double = 0;
  Y1:           Double = 0;
  X2:           Double = 0;
  Y2:           Double = 0;
  P1, P2:       TPoint;
  LinkSize:     Integer;
  LinkType:     Integer;
  ColorIndex:   Integer = 0;
  LinkColor:    TColor;
  DrawSymbols:  Boolean;
  DrawNotation: Boolean;
begin
  for I := 1 to project.GetItemCount(project.ctLinks) do
  begin
    // Get link's start and end node coords.
    if not project.GetLinkNodes(I, N1, N2) then continue;
    if not project.GetNodeCoord(N1, X1, Y1) then continue;
    if not project.GetNodeCoord(N2, X2, Y2) then continue;

    // Convert coords. to screen pixels
    P1 := Map.WorldToScreen(X1, Y1);
    P2 := Map.WorldToScreen(X2, Y2);

    // Determine link size and color
    LinkSize := Map.Options.LinkSize;
    LinkColor := mapthemes.GetLinkColor(I, ColorIndex);
    if Map.Options.ShowLinksBySize then
      LinkSize := LinkSize + ColorIndex;

    // Draw link border
    if Map.Options.ShowLinkBorder then
    begin
      Map.Canvas.Pen.Color := OutlineColor;
      if LinkSize = 4 then
        LinkSize := 3
      else if LinkSize = 5 then
        LinkSize := 6;
      Map.Canvas.Pen.Width := LinkSize + 2;
      DrawLink(Map, I, P1, P2);
    end;

    // Draw link interior
    Map.Canvas.Pen.Width := LinkSize;
    Map.Canvas.Pen.Color := LinkColor;
    Map.Canvas.Brush.Color := LinkColor;
    DrawLink(Map, I, P1, P2);

    // Draw link symbol & notation
    LinkType := project.GetLinkType(I);
    DrawSymbols := ShowLinkSymbol(Map, LinkType);
    DrawNotation := ShowLinkNotation(Map);
    if DrawSymbols or DrawNotation then
    begin
      P1 := Point(0,0);
      P2 := Point(0,0);
      Map.GetLinkMidSegment(I, P1, P2);
      if DrawSymbols then
        DrawLinkSymbol(Map, I, LinkType, P1, P2, LinkSize + 4, LinkColor);
      if DrawNotation then
        DrawLinkNotation(Map, I, P1, P2, LinkSize);
    end;
  end;
end;

procedure DrawAllNodes(Map: TMap);
var
  I, Size:    Integer;
  C:          TColor;
  ColorIndex: Integer = 0;
  X:          Double = 0;
  Y:          Double = 0;
  P:          TPoint;
begin
  Map.Canvas.Pen.Width := 1;
  for I := 1 to project.GetItemCount(project.ctNodes) do
  begin
    if not project.GetNodeCoord(I, X, Y) then continue;
    P := Map.WorldToScreen(X, Y);

    Map.Canvas.Pen.Color := OutlineColor;
    C := mapthemes.GetNodeColor(I, ColorIndex);
    if (C < 0) or (C = clNone) then continue;
    Map.Canvas.Brush.Color := C;
    if Map.Options.ShowNodesBySize then
      Size := Map.Options.NodeSize + ColorIndex
    else
      Size := Map.Options.NodeSize;
    if not Map.Options.ShowNodeBorder then
      Map.Canvas.Pen.Color := Map.Canvas.Brush.Color;

    case project.GetNodeType(I) of
      ntJunction:
        if Map.Options.ShowJunctions then
        begin
          Map.Canvas.Ellipse(P.X - Size, P.Y - Size, P.X + Size, P.Y + Size);
        end;
      ntReservoir:
        DrawReservoir(Map, P.X, P.Y, Size);
      ntTank:
        DrawTank(Map, P.X, P.Y, Size);
    end;
  end;
end;

procedure DrawAllLabels(Map: TMap);
var
  I:         Integer;
  P:         TPoint;
  MapLabel:  TMapLabel;
  SavedFont: TFont;
  Text:      string;
begin
  if Map.Options.NotationOpaque then
  begin
    Map.Canvas.Brush.Style := bsSolid;
    Map.Canvas.Brush.Color := Map.Options.BackColor;
  end
  else  Map.Canvas.Brush.Style := bsClear;
  SavedFont := TFont.Create;
  try
    SavedFont.Assign(Map.Canvas.Font);
    for I := 1 to project.MapLabels.Count do
    begin
      P := Map.FindLabelPoint(I);
      MapLabel := TMapLabel(project.MapLabels.Objects[I-1]);
      Map.Canvas.Font.Assign(MapLabel.Font);
      Map.Canvas.Font.Color := LabelColor;
      Text := project.MapLabels[I-1];
      Map.Canvas.TextOut(P.X, P.Y, Text);
      MapLabel.Extent := Map.Canvas.TextExtent(Text);
    end;
    Map.Canvas.Font.Assign(SavedFont);
  finally
    Map.Canvas.Brush.Style := bsSolid;
    SavedFont.Free;
  end;
end;

procedure DrawAllNodeNotations(Map: TMap);
var
  I:          Integer;
  Size:       Integer;
  T:          Integer;
  ColorIndex: Integer = 0;
  X:          Double = 0;
  Y:          Double = 0;
  P:          TPoint;
  SavedColor: TColor;
begin
  with Map.Canvas do
  begin
    SavedColor := Brush.Color;
    Brush.Color := Map.Options.BackColor;
    Font.Color := NotationColor;
    if not Map.Options.NotationOpaque then Brush.Style := bsClear;
  end;

  for I := 1 to project.GetItemCount(project.ctNodes) do
  begin
    if not project.GetNodeCoord(I, X, Y) then continue;
    P := Map.WorldToScreen(X, Y);
    T := project.GetNodeType(I);
    mapthemes.GetNodeColor(I, ColorIndex);
    if Map.Options.ShowNodesBySize then
      Size := Map.Options.NodeSize + ColorIndex
    else
      Size := Map.Options.NodeSize;
    if Map.Options.ShowNodeIDs then
      DrawNodeID(Map, I, T, P, Size);
    if Map.Options.ShowNodeValues and (mapthemes.NodeTheme > 0) then
      DrawNodeValue(Map, I, T, P, Size);
  end;

  Map.Canvas.Brush.Color := SavedColor;
  Map.Canvas.Brush.Style := bsSolid;
end;

procedure Setup(Map: TMap);
begin
  // Set Canvas's font for object ID/Value labeling
  Map.Canvas.Font.Name := 'Arial';
  Map.Canvas.Font.Size := Map.Options.NotationSize;
  Map.Canvas.Font.Style := [];
  Map.CharHeight := Map.Canvas.TextHeight('[');

  // Assign colors to drawing features
  if (Map.Options.BackColor = mapoptions.DarkColor) then
  begin
    LabelColor := clWhite;
    ArrowColor := clWhite;
    NotationColor := $F8F8F8;
  end else
  begin
    LabelColor := clBlack;
    ArrowColor := clBlack;
    NotationColor := mapoptions.DarkColor;
  end;
  OutlineColor := clBlack;
end;

procedure DrawNetwork(Map: TMap);
var
  ShowNodeNotation: Boolean;
begin
  // Assign colors and character height
  Setup(Map);

  // Draw all links (including symbols & notation)
  Map.Canvas.Pen.JoinStyle := pjsBevel;
  if Map.Options.ShowLinks then DrawAllLinks(Map);
  Map.Canvas.Pen.Width := 1;
  Map.Canvas.Pen.Cosmetic := true;

  // Draw all nodes
  if Map.Options.ShowNodes then
  begin
    DrawAllNodes(Map);
    ShowNodeNotation := false;
    if (Map.ZoomLevel >= Map.Options.NotationZoom) then
    begin
      if Map.Options.ShowNodeIDs then
        ShowNodeNotation := true
      else if Map.Options.ShowNodeValues
      and (mapthemes.NodeTheme > 0) then
        ShowNodeNotation := true;
    end;
    if ShowNodeNotation then DrawAllNodeNotations(Map);
  end;

  // Draw map labels
  if Map.Options.ShowLabels then DrawAllLabels(Map);
end;

end.

