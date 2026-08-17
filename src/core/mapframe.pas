{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mapframe
 Description:  a frame that displays the pipe network and
               handles user interaction with it.
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit mapframe;

{
 This frame is placed on the MapPanel of EPANET-UI's main form. It
 contains a PaintBox named MapBox on which the pipe network is displayed.
 A public TMap object (Map) is declared which is responsible for drawing
 the network and any associated basemap on an offscreen bitmap. This
 bitmap is drawn onto the PaintBox's Canvas in its OnPaint method. The
 frame also handles all user interactions with the network map, such as
 zooming, panning, selecting objects, adding objects, drawing fencelines,
 and reshaping links.
}

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, ExtCtrls, LCLtype,
  Graphics, Clipbrd, ExtDlgs, Types, Math, Dialogs, Menus, StdCtrls,

  // EPANET-UI units
  project, map, mapcoords, mapoptions, maplegend;

const
  TICKDELAY    = 200;        // Delay before object can be moved
  MINPIXPAN    = 2;          // Minimum pixel movement for panning
  DELTA        = 1;          // Pixel distance for keyboard moving
  MAX_HILITE_COUNT = 10;

type

  TMapAction = (maSelecting = 1,  // Selecting an object
                maVertexing,      // Editing link vertices
                maFenceLining,    // Drawing a fencelined polygon
                maPanning,        // Panning the map
                maZooming,        // Zooming the map
                // Adding objects to the map
                maAddingJunc, maAddingResv, maAddingTank,
                maAddingPipe, maAddingPump, maAddingValve,
                maAddingLabel);

  TPaintAction = (paNone,         // No action
                  paMovingLine,   // Dotted line when moving an object
                  paPolyLine,     // Dotted line when linking nodes or fencelining
                  paPolygon,      // Fill selected polygon region
                  paVertices,     // Show link vertices
                  paHilite);      // Show object highlighter

  // Control point used for basemap georeferencing
  TCtrlPoint = Record
    Bitmap:   TBitmap;
    Position: TDoublePoint;
    Visible:  Boolean;
  end;

  { TMapFrame }

  TMapFrame = class(TFrame)
    MapBox:             TPaintBox;
    HiliteTimer:        TTimer;
    ResizeTimer:        TTimer;
    DebounceTimer:      TTimer;
    MapPopupMenu:       TPopupMenu;
    CopyMenuItem:       TMenuItem;
    DeleteMenuItem:     TMenuItem;
    ConvertMenuItem:    TMenuItem;
    ValveMenuItem:      TMenuItem;
    PumpMenuItem:       TMenuItem;
    PipeMenuItem:       TMenuItem;
    ReshapeMenuItem:    TMenuItem;
    ReverseMenuItem:    TMenuItem;
    Separator1:         TMenuItem;
    PasteMenuItem:      TMenuItem;
    OpenPictureDialog1: TOpenPictureDialog;

    procedure ConvertMenuItemClick(Sender: TObject);
    procedure DebounceTimerTimer(Sender: TObject);
    procedure MapBoxDblClick(Sender: TObject);
    procedure MapBoxMouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure MapMenuItemClick(Sender: TObject);
    procedure HiliteTimerTimer(Sender: TObject);
    procedure MapBoxChangeBounds(Sender: TObject);
    procedure MapBoxClick(Sender: TObject);
    procedure MapBoxMouseDown(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);
    procedure MapBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MapBoxMouseUp(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);
    procedure MapBoxPaint(Sender: TObject);
    procedure MapBoxResize(Sender: TObject);
    procedure ResizeTimerTimer(Sender: TObject);
    procedure ShowHint(Sender: TObject; HintInfo:PHintInfo);

  private
    MapAction:        TMapAction;
    PaintAction:      TPaintAction;
    MenuAction:       string;
    Linking:          Boolean;
    FenceLining:      Boolean;
    Moving:           Boolean;

    StartNode:        Integer;
    Point1:           TPoint;
    Point2:           TPoint;
    Points:           array of TPoint;
    CurrentPoint:     TPoint;
    ZoomToPoint:      TPoint;

    HiliteRect:       TRect;
    HiliteState:      Integer;
    HiliteCount:      Integer;
    HiliterIsOn:      Boolean;

    SelectedObjType:  Integer;
    SelectedObjIndex: Integer;
    NumVertices:      Integer;
    SelectedVertex:   Integer;

    OldTickCount:     QWORD;          // Measures a small time delay
    DeltaZoom:        Integer;        // Number of mouse wheel zooms

    function  StartLinking(const X: Integer; const Y: Integer): Boolean;
    procedure EndLinking(const X: Integer; const Y: Integer);
    procedure CancelLinking;

    procedure GoFenceLining(X: Integer; Y: Integer);
    procedure LeaveFenceLiningMode;

    procedure MoveObject(W: TDoublePoint);
    procedure MoveVertex(X: Integer; Y: Integer);
    procedure MoveVertexByPixel(Key: Word);

    function  SelectVertex(X: Integer; Y: Integer): Boolean;
    procedure ShowVertex(I: Integer; J: Integer; C: TColor);
    procedure ShowVertices(I: Integer);
    procedure DeleteVertex;
    procedure DeleteAllVertices;
    procedure LeaveVertexingMode;

    procedure DrawCtrlPoints;
    procedure ShowJunctions;
    procedure ShowWebBasemap;
    procedure ShowPopupMenu;
    procedure FindBasemapLocation(MapSource: Integer);

    procedure HideHiliter;
    procedure ShowHiliter;
    procedure DrawHiliter;

  public
    Map:         TMap;
    HasBasemap:  Boolean;
    BasemapFile: string;
    NodeLegend:  TMapLegendFrame;
    LinkLegend:  TMapLegendFrame;
    Offset:      TPoint;
    Aligning:    Boolean;
    CtrlPoint:   array[1..3] of TCtrlPoint;

    procedure AddNode(NodeType: Integer);
    procedure AddLink(LinkType: Integer);
    procedure AddLabel;
    procedure AddVertex;

    procedure ChangeExtent(NewExtent: TDoubleRect);
    procedure Clear;
    procedure Close;

    procedure DrawFullExtent;

    procedure EditMapOptions;
    procedure EnterSelectionMode;
    procedure EnterVertexingMode;
    procedure EnterFenceLiningMode(aMenuAction: string);

    procedure GetVertices(var X: array of Double; var Y: array of Double;
              var N: Integer);
    function  GetWebBasemapSource: Integer;
    procedure GoKeyDown(var Key: Word; Shift: TShiftState);

    function  HasWebBasemap: Boolean;
    procedure HiliteObject(const Objtype: Integer; const ObjIndex: Integer);

    procedure Init;
    procedure InitMapOptions;

    procedure LoadBasemapFromFile;
    procedure LoadBasemapFromWeb(MapSource, Epsg, Units: Integer);

    procedure MoveObjectByPixel(Key: Word);

    procedure RedrawMap;
    procedure RedrawMapLabels;
    procedure ResizeMap;

    procedure SetBasemapBrightness(Brightness: Integer);
    procedure SetExtent(E: TDoubleRect);
    procedure SetMapCenter(X, Y: Double);
    procedure ShowLayer(LayerType: Integer; ShowIt: Boolean);
    procedure TransformExtent(var ExtentRect: TDoubleRect);


    procedure UnloadBasemap;
    procedure ZoomIn(Dx: Integer; Dy: Integer);
    procedure ZoomOut(Dx: Integer; Dy: Integer);

  end;

implementation

{$R *.lfm}

uses
  main, projectbuilder, mapthemes, maplabel, webmapfinder, overviewmapframe,
  config, utils, resourcestrings;

//------------------------------------------------------------------------------
//  MapFrame procedures
//------------------------------------------------------------------------------

procedure TMapFrame.Init;
var
  I: Integer;
begin
  // Create a TMap object on which the pipe network is drawn
  Map := TMap.Create;
  Offset := Point(0, 0);
  MapBox.OnShowHint := @ShowHint;

  // Initialize how a selected map object is highlighted
  HiliteTimer.Interval := 500;
  HiliteTimer.Enabled := false;
  HiliteRect := Rect(0, 0, 0, 0);
  HiliteState := 0;
  HiliterIsOn := false;

  // Initialize any map actions taken
  MapAction := maSelecting;
  PaintAction := paNone;
  Linking := false;
  Aligning := false;
  DeltaZoom := 0;
  DebounceTimer.Enabled := false;

  // Create the markers used when georeferencing a basemap image
  for I := 1 to 3 do
  begin
    CtrlPoint[I].Bitmap := TBitmap.Create;
    MainForm.MarkerImageList.GetBitmap(I-1, CtrlPoint[I].Bitmap);
    CtrlPoint[I].Visible := false;
  end;
  Setlength(Points, 0);

  // Create a Node legend for the map display
  NodeLegend := TMapLegendFrame.Create(self);
  NodeLegend.Parent := self;
  NodeLegend.Name := '';
  NodeLegend.Left := 2;
  NodeLegend.Top := 2;
  NodeLegend.SetShapes(stCircle);
  NodeLegend.ObjType := ctNodes;
  NodeLegend.Framed := true;
  NodeLegend.Visible := true;

  // Create a Link legend for the map display
  LinkLegend := TMapLegendFrame.Create(self);
  LinkLegend.Parent := self;
  LinkLegend.Left := 2;
  LinkLegend.Top := 2 + NodeLegend.Height + 2;
  LinkLegend.SetShapes(stRectangle);
  LinkLegend.ObjType := ctLinks;
  LinkLegend.Framed := true;
  LinkLegend.Visible := true;
end;

procedure TMapFrame.Clear;
//
// Clear the network map display when a new project is started.
//
var
  I: Integer;
begin
  HideHiliter;
  Map.Reset;
  Offset := Point(0, 0);
  Aligning := false;

  SelectedObjType := -1;
  SelectedObjIndex := -1;

  HasBasemap := false;
  BasemapFile := '';
  for I := 1 to 3 do
    CtrlPoint[I].Visible := false;

  PaintAction := paNone;
  MapBox.Refresh;
end;

procedure TMapFrame.Close;
//
// Free allocated memory when application is closed.
//
var
  I: Integer;
begin
  for I := 1 to 3 do
    CtrlPoint[I].Bitmap.Free;
  Map.Free;
  SetLength(Points, 0);
end;

procedure TMapFrame.DrawFullExtent;
//
//  Display the network map at its full extent.
//
begin
  Map.Extent := Map.GetBounds;
  Map.ZoomToExtent;
  RedrawMap;
  if MapAction = maVertexing then
    ShowVertices(SelectedObjIndex);
  HiliteObject(SelectedObjType, SelectedObjIndex);
  MainForm.OverviewMapFrame.ShowMapExtent;
end;

procedure TMapFrame.ResizeTimerTimer(Sender: TObject);
//
// Delays redrawing a resized map to avoid flicker.
//
begin
  ResizeTimer.Enabled := false;
  ResizeMap;
end;

procedure TMapFrame.ResizeMap;
//
// Redraw the network map after the main form has been resized.
//
begin
  if Assigned(Map) then
  begin
    Map.Resize(Rect(0, 0, MapBox.ClientWidth, MapBox.ClientHeight));
    RedrawMap;
    HiliteObject(SelectedObjType, SelectedObjIndex);
  end;
end;

procedure TMapFrame.ChangeExtent(NewExtent: TDoubleRect);
//
//  Re-scale the coordinates of the network map's objects and redraw
//  the map when the coordinates of its bounding rectangle change.
//
var
  S1: TScalingInfo;
  S2: TScalingInfo;
begin
  S1 := Map.GetScalingInfo;
  Map.Extent := NewExtent;
  Map.Rescale;
  Map.SetBasemapBounds;
  S2 := Map.GetScalingInfo;
  mapcoords.DoScalingTransform(S1, S2);
  DrawFullExtent;
  MainForm.OverviewMapFrame.Redraw;
  if (not project.HasChanged)
  and (not project.IsEmpty) then
    project.HasChanged := true;
end;

procedure TMapFrame.SetMapCenter(X, Y: Double);
//
// Set the map's center to world coordinates X, Y.
//
begin
  // If a web basemap is being used then convert X,Y to lat, lon
  if Map.Basemap.WebMap <> nil then Map.NativeToWGS84(X, Y);
  Map.SetCenter(X, Y);
  RedrawMap;
end;

procedure TMapFrame.ShowLayer(LayerType: Integer; ShowIt: Boolean);
//
// Toggle the display of map objects.
//
begin
  case LayerType of
    ntJunction:
      Map.Options.ShowJunctions := ShowIt;
    ntReservoir:
      Map.Options.ShowTanks := ShowIt;
    ltPipe + 10:
      Map.Options.ShowLinks := ShowIt;
    ltPump + 10:
      Map.Options.ShowPumps := ShowIt;
    ltValve + 10:
      Map.Options.ShowValves := ShowIt;
    ctLabels:
      Map.Options.ShowLabels := ShowIt;
  end;
  RedrawMap;
end;

procedure TMapFrame.MoveObject(W: TDoublePoint);
//
// Move a selected map object to new world coordinates W.
//
begin
  // If moving a node, adjust connecting pipe lengths under AutoLength
  if SelectedObjType = ctNodes then
  begin
    project.SetNodeCoord(SelectedObjIndex, W.X, W.Y);
    project.AdjustLinkLengths(StartNode);
  end
  else if SelectedObjType = ctLabels then
    project.SetLabelCoord(SelectedObjIndex, W.X, W.Y);

  // Update project's HasChanged state
  if (not project.HasChanged) and (not project.IsEmpty) then
    project.HasChanged := true;

  // Redraw network & overview maps
  RedrawMap;
  MainForm.OverviewMapFrame.Redraw;
end;

procedure TMapFrame.MoveObjectByPixel(Key: Word);
//
// Move a selected object by DELTA pixels when an arrow key was pressed.
//
var
  Dx:    Integer;
  Dy:    Integer;
  PixPt: TPoint;
  X:     Double;
  Y:     Double;
  W:     TDoublePoint;
begin
  // If Vertexing then move selected vertex
  if MapAction = maVertexing then
  begin
    MoveVertexByPixel(Key);
    exit;
  end;

  // Object must be highlighted
  if not HiliterIsOn then exit;

  // Determine which direction a DELTA pixel move occurs
  Dx := 0;
  Dy := 0;
  case Key of
    VK_UP:
      Dy := -DELTA;
    VK_DOWN:
      Dy := DELTA;
    VK_LEFT:
      Dx := -DELTA;
    VK_RIGHT:
      Dx := DELTA;
    else
      exit;
  end;

  // Get world coords of object to be moved
  if SelectedObjType = ctNodes then
  begin
    if not project.GetNodeCoord(SelectedObjIndex, X, Y) then exit
  end
  else if SelectedObjType = ctLabels then
  begin
    if not project.GetLabelCoord(SelectedObjIndex, X, Y) then exit;
  end
  else
    exit;

  // Add DELTA pixels to object's pixel coords and convert back to world coords
  PixPt := Map.WorldToScreen(X, Y);
  if not PtInRect(Map.MapRect, PixPt) then exit;
  W := Map.ScreenToWorld(PixPt.X + Dx, PixPt.Y + Dy);

  // Move the object
  MoveObject(W);
end;

procedure TMapFrame.ShowHint(Sender: TObject; HintInfo:PHintInfo);
//
// Display object ID and theme value as flyover hint if mouse is over an object.
//
var
  I: Integer;
  X: Integer;
  Y: Integer;
  V: Single;
  S: string;
begin
  // Do nothing if flyover hints are turned off
  if config.MapHinting = false then exit;

  // Get mouse's position
  S := '';
  X := HintInfo^.CursorPos.X;
  Y := HintInfo^.CursorPos.Y;

  // Check if mouse is over a node
  I := Map.FindNodeHit(X, Y);
  if I > 0 then
  begin
    // Construct the string to display in the hint
    S := project.GetItemTypeStr(ctNodes, I-1) + project.GetItemID(ctNodes, I-1);
    if mapthemes.NodeTheme > 0 then
    begin
      V := mapthemes.GetCurrentThemeValue(ctNodes, I);
      if V = MISSING then
        S := S + LineEnding + 'N/A'
      else
        S := S + LineEnding + FloatToStrF(V, ffFixed, 7, config.DecimalPlaces);
    end;
  end

  // Check if mouse is over a link
  else
  begin
    I := Map.FindLinkHit(X, Y);
    if I > 0 then
    begin
      // Contruct the string to display in the hint
      S := project.GetItemTypeStr(ctLinks, I-1) + project.GetItemID(ctLinks, I-1);
      if mapthemes.LinkTheme > 0 then
      begin
        V := mapthemes.GetCurrentThemeValue(ctLinks, I);
        if V = MISSING then
          S := S + LineEnding + 'N/A'
        else
          S := S + LineEnding + FloatToStrF(V, ffFixed, 7, config.DecimalPlaces);
      end;
    end;
  end;

  // Display the flyover hint (will not appear if S is blank)
  HintInfo^.HintStr := S;
end;

procedure TMapFrame.AddNode(NodeType: Integer);
//
// Prepare map for adding a node of type NodeType to the project.
//
begin
  case NodeType of
    ntJunction:
      MapAction := maAddingJunc;
    ntReservoir:
      MapAction := maAddingResv;
    ntTank:
      MapAction := maAddingTank;
  end;
  HideHiliter;
  ShowJunctions;
  MainForm.EnableMainForm(false);
  MapBox.Cursor := crCross;
  SetFocus;
end;

procedure TMapFrame.AddLink(LinkType: Integer);
//
// Prepare map for adding a link of type LinkType to the project.
//
begin
  case LinkType of
    ltPipe:
      MapAction := maAddingPipe;
    ltPump:
      MapAction := maAddingPump;
    ltValve:
      MapAction := maAddingValve;
  end;
  ShowJunctions;
  MainForm.EnableMainForm(false);
  MapBox.Cursor := crCross;
  SetFocus;
end;

procedure TMapFrame.AddLabel;
//
// Prepare map for adding a map label to the project.
//
begin
  MapAction := maAddingLabel;
  HideHiliter;
  MainForm.EnableMainForm(false);
  MapBox.Cursor := crCross;
  SetFocus;
end;

procedure TMapFrame.ZoomIn(Dx: Integer; Dy: Integer);
var
  TmpMapAction: TMapAction;
begin
  TmpMapAction := MapAction;
  MapAction := maZooming;
  Map.ZoomIn(Dx, Dy);
  RedrawMap;
  MapAction := TmpMapAction;
  MainForm.OverviewMapFrame.ShowMapExtent;
  if MapAction = maVertexing then
    ShowVertices(SelectedObjIndex)
  else
    HiliteObject(SelectedObjType, SelectedObjIndex);
end;

procedure TMapFrame.ZoomOut(Dx: Integer; Dy: Integer);
var
  TmpMapAction: TMapAction;
begin
  TmpMapAction := MapAction;
  MapAction := maZooming;
  Map.ZoomOut(Dx, Dy);
  RedrawMap;
  MapAction := TmpMapAction;
  MainForm.OverviewMapFrame.ShowMapExtent;
  if MapAction = maVertexing then
    ShowVertices(SelectedObjIndex)
  else
    HiliteObject(SelectedObjType, SelectedObjIndex);
end;

procedure TMapFrame.EnterSelectionMode;
//
// Prepare map for selecting objects via mouse click.
//
begin
  Linking := false;
  FenceLining := false;
  Moving := false;
  StartNode := 0;
  MapAction := maSelecting;
  PaintAction := paNone;
  Offset := Point(0, 0);
  MapBox.Refresh;
  MapBox.Cursor := crDefault;
end;

function TMapFrame.StartLinking(const X: Integer; const Y: Integer): Boolean;
//
// Put map in linking mode that will connect two nodes with a new link.
//
var
  I: Integer;
begin
  I := Map.FindNodeHit(X, Y);
  HideHiliter;
  if I > 0 then
  begin
    MapBox.Cursor := crPen;
    StartNode := I;
    SetLength(Points, 1);
    Points[0] := Point(X, Y);
    Result := true;
  end
  else Result := false;
end;

procedure TMapFrame.EndLinking(const X: Integer; const Y: Integer);
//
// Process a mouse click on map when in linking mode.
//
var
  EndNode, I: Integer;
begin
  // Add current mouse position to link's vertex points
  SetLength(Points, Length(Points) + 1);
  Points[High(Points)] := Point(X, Y);
  CurrentPoint := Point(X, Y);

  // See if current point falls on a node
  EndNode := Map.FindNodeHit(X, Y);
  if EndNode > 0 then
  begin
    // Link start and end nodes are different
    if StartNode <> EndNode then
    begin

      // Convert MapAction to project's Link type
      I :=  Ord(MapAction) - Ord(maAddingPipe) + 1;

      // Add link to project
      projectbuilder.AddLink(I, StartNode, EndNode);
      if I >= ltPipe then AddLink(I);

      // Quit Linking
      SetLength(Points, 0);
      Linking := false;
      HideHiliter;
      MapBox.Cursor := crCross;
    end;
  end;
end;

procedure TMapFrame.CancelLinking;
begin
  Linking := false;
  MapBox.Refresh;
  MapBox.Cursor := crCross;
end;

procedure TMapFrame.EnterFenceLiningMode(aMenuAction: string);
//
// Begin drawing a fencelined polygon on the map.
//
begin
  HideHiliter;
  MenuAction := aMenuAction;
  MapAction := maFenceLining;
  FenceLining := false;
  SetLength(Points, 0);
  NumVertices := -1;
  MainForm.EnableMainForm(false);
  MapBox.Cursor := crPen;
end;

procedure TMapFrame.GoFenceLining(X: Integer; Y: Integer);
//
// Process a mouse click while in fencelining mode.
//
begin
  SetLength(Points, Length(Points) + 1);
  Points[High(Points)] := Point(X, Y);
  CurrentPoint := Point(X, Y);
  NumVertices := Length(Points);
  FenceLining := true;
end;

procedure TMapFrame.LeaveFenceLiningMode;
//
// Called when drawing a fenceline polygon is completed.
//
var
  I:              Integer;
  N:              Integer;
  WorldPoly:      TPolygon;
begin
  // A valid fence line polygon was constructed
  Setlength(WorldPoly, 0);
  N := Length(Points);
  if N >= 3 then
  begin
    // Display filled polygon on map
    PaintAction := paPolygon;
    MapBox.Refresh;

    // Convert polygon from screen to world coordinates
    Inc(N);
    SetLength(Points, N);
    Points[High(Points)] := Points[0];
    SetLength(WorldPoly, Length(Points));
    for I := 0 to Length(Points) - 1 do
      WorldPoly[I] := Map.ScreenToWorld(Points[I].X, Points[I].Y);
  end

  // NumVertices = -1 means entire network was selected
  else if NumVertices = -1 then N := -1;

  // Pass the polygon to the menu action that requested it
  MapBox.Cursor := crDefault;
  FenceLining := false;
  SetLength(Points, 0);
  if MenuAction = 'GroupSelection' then
  begin
    MainForm.GroupSelectorFrame.SelectRegion(WorldPoly, N);
  end
  else if MenuAction = 'GroupDeletion' then
  begin
    MainForm.GroupEditorFrame.DeleteGroup(WorldPoly, N);
  end
  else
    MainForm.EnableMainForm(true);
  EnterSelectionMode;
end;

procedure TMapFrame.EnterVertexingMode;
//
// Prepare for editing a link's vertices.
//
begin
  if SelectedObjType <> ctLinks then exit;
  HideHiliter;
  MainForm.EnableMainForm(false);
  SelectedVertex := 1;
  MapAction := maVertexing;
  PaintAction := paVertices;
  MapBox.Refresh;
end;

procedure TMapFrame.LeaveVertexingMode;
//
// Finish editing a link's vertices.
//
begin
  if MapAction = maVertexing then
  begin
    MainForm.MainMenuFrame.EditVertexBtn.Down := false;
    if project.AutoLength
    and (project.GetLinkType(SelectedObjIndex) <= ltPipe) then
      project.SetPipeLength(SelectedObjIndex);
    MainForm.EnableMainForm(true);
    EnterSelectionMode;
  end;
end;

procedure TMapFrame.SetExtent(E: TDoubleRect);
//
// Reset the map's bounding rectangle to world coordinates E.
//
begin
  Map.Extent := E;
end;

procedure TMapFrame.RedrawMap;
//
// Redraw the network map in response to some change.
//
begin
  // Redraw basemap and all network objects on offscreen bitmap
  HideHiliter;
  Map.Redraw;

  // Add control point images to map if georeferencing a basemap image
  if MainForm.GeoRefFrame.Visible then
    DrawCtrlPoints;

  // Transfer offscreen bitmap to screen via MapBox's OnPaint method
  PaintAction := paNone;
  MapBox.Refresh;

  // Re-highlight any selected map object
  if (MapAction = maSelecting) then
    HiliteObject(SelectedObjType, SelectedObjIndex);
end;

procedure TMapFrame.DrawCtrlPoints;
//
// Draw control point images, used when georeferencing a basemap,
// on map's offscreen bitmap.
var
  I: Integer;
begin
  for I := Low(CtrlPoint) to High(CtrlPoint) do
  begin
    if CtrlPoint[I].Visible then
      Map.DrawBitmap(CtrlPoint[I].Bitmap, CtrlPoint[I].Position);
  end;
end;

procedure TMapFrame.RedrawMapLabels;
//
// Redraw map when a label has changed.
//
begin
  if Map.Options.ShowLabels then RedrawMap;
end;

procedure TMapFrame.GoKeyDown(var Key: Word; Shift: TShiftState);
//
// Process a keyboard key press depending on map action.
//
begin
  if MapAction =  maVertexing then
  begin
    if (Key = VK_INSERT)
    or (Key = VK_OEM_PLUS)
    or (Key = VK_ADD) then
      AddVertex

    else if (Shift = [ssShift])
    and  (Key = VK_DELETE) then
      DeleteAllVertices

    else if (Key = VK_DELETE)
    or (Key = VK_BACK) then
      DeleteVertex

    else if Key = VK_ESCAPE then
      LeaveVertexingMode

    else if Key = VK_SPACE then
      begin
        PaintAction := paVertices;
        MapBox.Refresh;
      end;
  end

  else if MapAction = maFenceLining then
  begin
    if Key = VK_RETURN then
    begin
      Key := 0;
      LeaveFenceLiningMode;
    end
    else if Key = VK_ESCAPE then
    begin
      Key := 0;
      SetLength(Points, 0);
      NumVertices := 0;
      LeaveFenceLiningMode;
    end;
  end

  else if Linking and (Key = VK_ESCAPE) then
    CancelLinking

  else if MapAction in [maAddingJunc .. maAddingLabel] then
  begin
    if Key = VK_ESCAPE then
    begin
      Mainform.EnableMainForm(true);
      EnterSelectionMode;
    end;
  end;
end;

procedure TMapFrame.ShowJunctions;
//
// Redraw map with Junction nodes displayed.
//
begin
  // Redraw map with nodes displayed
  if (Map.Options.ShowNodes = false)
  or (Map.Options.ShowJunctions = false) then
  begin
    Map.Options.ShowNodes := true;
    Map.Options.ShowJunctions := true;
    RedrawMap;
  end;
  MainForm.MapViewerFrame.JunctionsBox.Checked := true;
end;

procedure TMapFrame.InitMapOptions;
//
// Initialize map display options to their default values.
//
begin
  Map.Options := mapoptions.DefaultOptions;
end;

procedure TMapFrame.EditMapOptions;
//
// Edit map display options.
//
begin
  if MapOptions.Edit(Map.Options) then
  begin
    RedrawMap;
    MainForm.OverviewMapFrame.Redraw;
  end;
end;

//------------------------------------------------------------------------------
//  Popup Menu Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.ShowPopupmenu;
//
// Set the items displayed in a popup menu when a node or link is right-clicked.
//
var
  ShowLinkItems: Boolean;
  Item,
  Category,
  ObjType:       Integer;
begin
  ShowLinkItems := (SelectedObjType = ctLinks);
  with MapPopupMenu do
  begin
    PasteMenuItem.Enabled := MainForm.MainmenuFrame.EditPasteBtn.Enabled;
    Separator1.Visible := ShowLinkItems;
    ReverseMenuItem.Visible := ShowLinkItems;
    ReshapeMenuItem.Visible := ShowLinkItems;
    ConvertMenuItem.Visible := ShowLinkItems;
    Category := MainForm.ProjectFrame.CurrentCategory;
    Item := MainForm.ProjectFrame.SelectedItem[Category];
    ObjType := project.GetLinkType(Item + 1);
    if ObjType = ltCVPipe then ObjType := ltPipe;
    PipeMenuItem.Visible := ObjType <> ltPipe;
    PumpMenuItem.Visible := ObjType <> ltPump;
    ValveMenuItem.Visible := ObjType <> ltValve;
    Popup;
  end;
end;

procedure TMapFrame.MapMenuItemClick(Sender: TObject);
//
// OnClick handler shared by the MapPopupMenu's menu items where
// the menu item's Tag property indicates what action to take.
//
begin
  with Sender as TMenuItem do
  begin
    case Tag of
      0:
        MainForm.MainMenuFrame.EditCopyBtnClick(Sender);
      1:
        MainForm.MainMenuFrame.EditPasteBtnClick(Sender);
      2:
        MainForm.MainMenuFrame.ProjectDeleteBtnClick(Sender);
      3:
        MainForm.MainMenuFrame.EditReverseBtnClick(Sender);
      4:
        MainForm.MainMenuFrame.EditVertexBtnClick(Sender);
    end;
  end;
end;

procedure TMapFrame.ConvertMenuItemClick(Sender: TObject);
//
// OnClick handler for menu items under the MapPopupMenu | ConvertMenuItem
// that determine what type of link a selected link should be converted to.
//
begin
  with Sender as TMenuItem do
    MainForm.ProjectFrame.ConvertItem(Tag);
end;

procedure TMapFrame.DebounceTimerTimer(Sender: TObject);
//
// This timer prevents excessive map redraws when the mouse wheel is
// used for zooming.
//
begin
  DebounceTimer.Enabled := false;
  if DeltaZoom > 0 then
    ZoomIn(ZoomToPoint.X - (MapBox.ClientWidth div 2),
      ZoomToPoint.Y - (MapBox.ClientHeight div 2))
  else if DeltaZoom < 0 then
    ZoomOut(ZoomToPoint.X - (MapBox.ClientWidth div 2),
      ZoomToPoint.Y - (MapBox.ClientHeight div 2));
  DeltaZoom := 0;
end;

//------------------------------------------------------------------------------
//  MapBox Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.MapBoxPaint(Sender: TObject);
//
// OnPaint handler for the MapBox TPaintBox that displays the network map.
//
var
  OldBrushStyle: TBrushStyle;
begin
  if not Assigned(Map) then exit;

  // When panning, draw the network map's bitmap on the MapBox at the
  // panned offset, filling any empty space with the map's background color
  if MapAction = maPanning then
  begin
    MapBox.Canvas.Brush.Color := Map.GetBackColor;
    MapBox.Canvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight))
  end;
  MapBox.Canvas.Draw(Offset.X, Offset.Y, Map.Bitmap);

  // Used when highlighting an object on the network map
  if PaintAction = paHilite then
  begin
    DrawHiliter;
    exit;
  end;

  // Used when drawing a polygon region or when linking two nodes
  if (PaintAction = paPolyLine) and (Length(Points) > 0) then
  begin
    with MapBox.Canvas do
    begin
      Pen.Style := psDot;
      Pen.Mode := pmNotXor;
      Pen.Width := 2;
      if Length(Points) > 1 then PolyLine(Points);
      MoveTo(Points[High(Points)].X, Points[High(Points)].Y);
      LineTo(CurrentPoint.X, CurrentPoint.Y);
      Pen.Style := psSolid;
      Pen.Mode := pmCopy;
      Pen.Width := 1;
    end;
  end;

  // Used when moving a node or map label
  if PaintAction = paMovingLine then
  begin
    with MapBox.Canvas do
    begin
      Pen.Style := psDot;
      Pen.Mode := pmNotXor;
      Pen.Width := 2;
      MoveTo(Point1.X, Point1.Y);
      LineTo(CurrentPoint.X, CurrentPoint.Y);
      Pen.Style := psSolid;
      Pen.Mode := pmCopy;
      Pen.Width := 1;
    end;
  end;

  // Used when drawing a polygon region is completed
  if PaintAction = paPolygon then with MapBox.Canvas do
  begin
    OldBrushStyle := Brush.Style;
    Brush.Style:= bsFDiagonal;
    Brush.Color := clRed;
    Polygon(Points);
    Brush.Style := OldBrushStyle;
  end;

  // Used to display a link's vertices
  if (PaintAction = paVertices) then
  begin
    ShowVertices(SelectedObjIndex);
  end;
  MapBox.Canvas.Pen.Color := clBlack;
  PaintAction := paNone;
end;

procedure TMapFrame.MapBoxResize(Sender: TObject);
//
// Introduces a short delay to redrawing the map when it is resized.
//
begin
  ResizeTimer.Enabled := true;
end;

procedure TMapFrame.MapBoxChangeBounds(Sender: TObject);
//
// Removes the delay after the map has been resized.
//
begin
  ResizeTimer.Enabled := false;

  if Assigned(NodeLegend) then
    NodeLegend.SetLocation(NodeLegend.GetLocation);
  if Assigned(LinkLegend) then
    LinkLegend.SetLocation(LinkLegend.GetLocation);
end;

procedure TMapFrame.MapBoxClick(Sender: TObject);
//
// Used to place a control point image at the map location clicked on
// when georeferencing a basemap image.
//
var
  I: Integer;
  W: TDoublePoint;
begin
  // Check that user is georeferencing the basemap
  if not MainForm.GeoRefFrame.Visible then exit;

  // Determine the world coords. where map was clicked on
  W := Map.ScreenToWorld(Point1.X, Point1.Y);

  // Find out which control point (index I) should be displayed
  I := MainForm.GeoRefFrame.GetCtrlPointIndex(W);

  // Display the I-th control point at coords. W
  if I > 0 then
  begin
    CtrlPoint[I].Position := W;
    CtrlPoint[I].Visible := true;
    RedrawMap;
  end;
end;

procedure TMapFrame.MapBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//
// Implement MapAction when a mouse button is pressed.
//
var
  I: Integer;
begin
  Moving := false;
  if MapAction = maVertexing then
  begin
    if Shift = [ssRight] then
      LeaveVertexingMode
    else if SelectVertex(X, Y)
    and (Shift = [ssLeft, ssCtrl]) then
    begin
      Moving := true;
      Point1 := Point(X, Y);
      Point2 := Point1;
    end
    else
    begin
      Point1 := Point(X, Y);
    end;
  end

  else if Linking and (Shift = [ssRight]) then
  begin
    CancelLinking;
  end

  else if MapAction = maFenceLining then
  begin
    GoFenceLining(X, Y);
  end

  else if MapAction = maSelecting then
  begin
    I := 0;
    I := Map.FindNodeHit(X, Y);
    if I > 0 then
    begin

      with MainForm.GroupSelectorFrame do
        if Visible then SelectObject(ctNodes, I);

      MainForm.ProjectFrame.SelectItem(ctNodes, I-1);
      StartNode := I;
      Point1 := Point(X, Y);
      Point2 := Point1;
      if Shift = [ssLeft, ssCtrl] then Moving := true;
      OldTickCount := GetTickCount64;
    end

    else
    begin
      I := Map.FindLinkHit(X, Y);
      if I > 0 then
      begin
        with MainForm.GroupSelectorFrame do
          if Visible then SelectObject(ctLinks, I);
        MainForm.ProjectFrame.SelectItem(ctLinks, I-1)
      end
      else
      begin
        I := Map.FindLabelHit(X, Y);
        if I > 0 then
        begin
          MainForm.ProjectFrame.SelectItem(ctLabels, I-1);
          Point1 := Point(X, Y);
          Point2 := Point1;
          if Shift = [ssLeft, ssCtrl] then Moving := true;
          OldTickCount := GetTickCount64;
        end;
      end;
    end;
    if I = 0 then HideHiLiter;

    if (Shift = [ssRight]) then
    begin
      if I > 0 then ShowPopupMenu else EditMapOptions;
      exit;
    end;

    if not Moving then
    begin
      MapAction := maPanning;
      Point1 := Point(X, Y);
    end;
  end

  else if Shift = [ssRight] then
  begin
    Mainform.EnableMainForm(true);
    EnterSelectionMode;
  end;
end;

procedure TMapFrame.MapBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
//
// Implement MapAction when the mouse is moved over the map.
//
var
  XY: TDoublePoint;
begin
  // Display the current mouse position in world coordinates on the
  // main form's status bar
  if Assigned(Map) then
  begin
    XY := Map.ScreenToWorld(X, Y);
    MainForm.UpdateXYStatus(XY.X, XY.Y);
  end;

  // A node or label is being moved with left button and Ctrl key pressed
  if Moving then
  begin
    HideHiliter;
    if (Shift <> [ssLeft, ssCtrl])
    or (GetTickCount64 - OldTickCount < TICKDELAY) then
      exit;
    OldTickCount := 0;
    PaintAction := paMovingLine;
    CurrentPoint := Point(X, Y);
    MapBox.Refresh;
  end

  // A link or fenceline is being drawn
  else if Linking or FenceLining then
  begin
    CurrentPoint := Point(X, Y);
    PaintAction := paPolyline;
    MapBox.Refresh;
  end

  // The map is being panned
  else if MapAction = maPanning then
  begin
    if (ssLeft in Shift) then
    begin
      // Check for slight delay in mouse movement
      if (GetTickCount64 - OldTickCount < TICKDELAY) then exit;

      // Find amount of movement from previous mouse point
      OldTickCount := 0;
      HideHiliter;
      MapBox.Cursor := crSize;
      Offset := Point(X - Point1.X, Y - Point1.Y);

      // Take action if movement not negligible
      if (Abs(Offset.X) > MINPIXPAN) or (Abs(Offset.Y) > MINPIXPAN) then
      begin

        // Action is aligning - move basemap relative to network
        if Aligning then
        begin
          Map.ShiftBasemap(Offset.X, Offset.Y);
          Point1.X := X;
          Point1.Y := Y;
          Offset := Point(0, 0);  //Allows Map to be copied correctly into MapBox
          RedrawMap;
        end

        // Action is panning - move entire map
        else
        begin
          PaintAction := paNone;
          MapBox.Refresh;
        end;
      end;
    end;
  end;
end;

procedure TMapFrame.MapBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
//
// Implement MapAction when a mouse button is released.
//
var
  P: TPoint;
  W: TDoublePoint;
  I: Integer;
begin
  if MapAction = maVertexing then
  begin
    if Moving then MoveVertex(X, Y)
  end

  else if MapAction = maPanning then
  begin
    begin
      MapAction := maSelecting;
      MapBox.Cursor := crDefault;
    end;
    if (Abs(Offset.X) > MINPIXPAN) or (Abs(Offset.Y) > MINPIXPAN) then
    begin
      if Aligning then
        Map.ShiftBasemap(Offset.X, Offset.Y)
      else
        Map.AdjustOffset(Offset.X, Offset.Y);
      Offset := Point(0, 0);  //Allows Map to be copied correctly into MapBox
      RedrawMap;
      MainForm.OverviewMapFrame.ShowMapExtent;
    end;
  end

  else if (FenceLining) then
  begin
    if Button = mbRight then LeaveFenceLiningMode;
  end

  else if MapAction in [maAddingJunc .. maAddingTank] then
  begin
    W := Map.ScreenToWorld(X, Y);
    I := ord(MapAction) - ord(maAddingJunc);
    projectbuilder.AddNode(I, W.X, W.Y);
    if I >= ntJunction then AddNode(I);
  end

  else if MapAction in [maAddingPipe .. maAddingValve] then
  begin
    if Linking = true then
      EndLinking(X,Y)
    else
      Linking := StartLinking(X,Y);
  end

  else if MapAction = maAddingLabel then
  begin
    P := ClientToScreen(Point(X,Y));
    W := Map.ScreenToWorld(X, Y);
    projectbuilder.AddLabel(P, W.X, W.Y);
  end

  else if Moving
  and (GetTickCount64 - OldTickCount > TICKDELAY) then
  begin
    OldTickCount := 0;
    W := Map.ScreenToWorld(X, Y);
    MoveObject(W);
    EnterSelectionMode;
  end;

end;

procedure TMapFrame.MapBoxDblClick(Sender: TObject);
//
//  Double clicking on a Map Label allows it to be edited.
//
var
  I: Integer;
  P: TPoint;
begin
  // Check that current map action allows for label editing
  if MapAction in [maSelecting, maPanning] then
  begin

    // Get the pixel location of mouse pointer
    P := MapBox.ScreenToClient(Mouse.CursorPos);

    // A map label is at that location
    I := Map.FindLabelHit(P.X, P.Y) - 1;
    if I >= 0 then
    begin

      // Hide the highlighting rectangle over the label
      HideHiliter;

      // Edit the label's text
      projectbuilder.EditLabelText(I, ClientToScreen(P));

      // Re-select the label so that it gets updated in the Property Editor
      MainForm.ProjectFrame.SelectItem(ctLabels, I);

      // Redraw the map so the label gets updated on it
      RedrawMap;
    end;
  end;
end;

procedure TMapFrame.MapBoxMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
//
// Collects zooms to the network map using the mouse wheel and delays
// acting on them until the DebounceTimer delay is complete.
//
begin
  if FenceLining then exit;
  ZoomToPoint := MousePos;
  DeltaZoom := DeltaZoom + WheelDelta;
  DebounceTimer.Enabled := false;
  DebounceTimer.Enabled := true;
  Handled := true;
end;

//------------------------------------------------------------------------------
//  Link Vertex Editing Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.GetVertices(var X: array of Double; var Y: array of Double;
  var N: Integer);
//
// Retrieve world coordinates of a link's interior vertex points whose
// screen coordinates have been placed in the private Points array.
//
var
  I: Integer;
  W: TDoublePoint;
begin
  // Number of link interior points
  N := Length(Points) - 2;

  // Copy world coords. of interior points to X & Y arrays
  for I := 1 to N do
  begin
    W := Map.ScreenToWorld(Points[I].X, Points[I].Y);
    X[I-1] := W.X;
    Y[I-1] := W.Y;
  end;
end;

procedure TMapFrame.ShowVertices(I: Integer);
//
// Display interior vertex points for Link I.
//
var
  J: Integer;
begin
  MapBox.Canvas.Pen.Color := clBlack;
  NumVertices := project.GetVertexCount(I);
  if NumVertices > 0 then
    for J := 1 to NumVertices do ShowVertex(I, J, clWhite)
  else
  begin
    ShowVertex(I, 0, clWhite);
    SelectedVertex := 0;
  end;
  if Selectedvertex > 0 then ShowVertex(I, SelectedVertex, clBlack);
end;

procedure TMapFrame.ShowVertex(I: Integer; J: Integer; C: TColor);
//
// Draws the J-th vertex point for Link I with color C on the MapBox canvas.
//
var
  X: Double = 0;
  Y: Double = 0;
  P: TPoint;
  R: TRect;
  S: Integer;
begin
  S := 3 +  Map.Options.LinkSize;
  if J > 0 then
    project.GetVertexCoord(I, J, X, Y)
  else
    project.GetLinkCoord(I, X, Y);
  P := Map.WorldToScreen(X, Y);
  R := Rect(P.x-S, P.y-S, P.x+S, P.y+S);
  MapBox.Canvas.Brush.Color := C;
  MapBox.Canvas.Rectangle(R);
end;

function TMapFrame.SelectVertex(X: Integer; Y: Integer): Boolean;
//
// Find which vertex of a link has been clicked on.
//
var
  Vx: Double = 0;
  Vy: Double = 0;
  P:  TPoint;
  R:  TRect;
  I,
  J,
  S: Integer;
begin
  Result := false;
  I := SelectedObjIndex;
  if NumVertices = 0 then exit;
  S := 3 +  Map.Options.LinkSize;
  for J := 1 to NumVertices do
  begin
    project.GetVertexCoord(I, J, Vx, Vy);
    P := Map.WorldToScreen(Vx, Vy);
    R := Rect(P.X-S, P.Y-S, P.X+S, P.Y+S);
    if PtInRect(R, Point(X, Y)) then
    begin
      SelectedVertex := J;
      PaintAction := paVertices;
      MapBox.Refresh;
      Result := true;
      exit;
    end;
  end;
end;

procedure TMapFrame.MoveVertex(X: Integer; Y: Integer);
//
// Move the currently selected vertex of a link to screen position X, Y.
//
var
  W: TDoublePoint;
begin
  if SelectedVertex = 0 then exit;
  W := Map.ScreenToWorld(X, Y);
  project.SetVertexCoord(SelectedObjIndex, SelectedVertex, W.X, W.Y);
  RedrawMap;
  PaintAction := paVertices;
  MapBox.Refresh;
end;

procedure TMapFrame.MoveVertexByPixel(Key: Word);
//
// Move a link vertex by DELTA pixels when an arrow key was pressed.
//
var
  Vx: Double = 0;
  Vy: Double = 0;
  Dx: Integer = 0;
  Dy: Integer = 0;
  P:  TPoint;
begin
  if SelectedVertex = 0 then exit;
  if not project.GetVertexCoord(SelectedObjIndex, SelectedVertex, Vx, Vy) then
    exit;
  case Key of
    VK_UP:
      Dy := -DELTA;
    VK_DOWN:
      Dy := DELTA;
    VK_LEFT:
      Dx := -DELTA;
    VK_RIGHT:
      Dx := DELTA;
    else
      exit;
  end;
  P := Map.WorldToScreen(Vx, Vy);
  P.Offset(Dx, Dy);
  MoveVertex(P.X, P.Y);
end;

procedure TMapFrame.AddVertex;
var
  I,
  J,
  V:    Integer;
  N1:   Integer = 0;
  N2:   Integer = 0;
  X:    Double = 0;
  Y:    Double = 0;
  X1:   Double = 0;
  Y1:   Double = 0;
  X2:   Double = 0;
  Y2:   Double = 0;
  Xv:   array[0..project.MAX_VERTICES] of Double;
  Yv:   array[0..project.MAX_VERTICES] of Double;
begin
  I := SelectedObjIndex;
  V := SelectedVertex;

  // Find location midway between selected vertex and next higher one
  if V = 0 then
    project.GetLinkCoord(I, X, Y)
  else
  begin
    project.GetVertexCoord(I, V, X1, Y1);
    if V < NumVertices then
      project.GetVertexCoord(I, V+1, X2, Y2)
    else
    begin
      project.GetLinkNodes(I, N1, N2);
      project.GetNodeCoord(N2, X2, Y2);
    end;
    X := (X1 + X2) / 2;
    Y := (Y1 + Y2) / 2;
  end;

  // Insert new vertex at that location
  Xv[0] := 0;
  Yv[0] := 0;
  for J := 1 to V do
    project.GetVertexCoord(I, J, Xv[J-1], Yv[J-1]);
  for J := NumVertices downto V + 1 do
    project.GetVertexCoord(I, J, Xv[J], Yv[J]);
  Inc(NumVertices);
  Xv[V] := X;
  Yv[V] := Y;
  project.SetVertexCoords(I, Xv, Yv, NumVertices);

  // Redraw vertex pts. with new vertex selected
  SelectedVertex := V + 1;
  PaintAction := paVertices;
  MapBox.Refresh;
end;

procedure TMapFrame.DeleteVertex;
var
  I:  Integer;
  J:  Integer;
  K:  Integer;
  Xv: array[0..project.MAX_VERTICES] of Double;
  Yv: array[0..project.MAX_VERTICES] of Double;
begin
  if SelectedVertex = 0 then exit;
  I := SelectedObjIndex;
  Xv[0] := 0;
  Yv[0] := 0;
  K := 0;
  for J := 1 to NumVertices do
  begin
    if J <> SelectedVertex then
    begin
      project.GetVertexCoord(I, J, Xv[K], Yv[K]);
      Inc(K);
    end;
  end;
  Dec(NumVertices);
  project.SetVertexCoords(I, Xv, Yv, NumVertices);
  if SelectedVertex > 1 then Dec(SelectedVertex);
  RedrawMap;
  PaintAction := paVertices;
  MapBox.Refresh;
end;

procedure TMapFrame.DeleteAllVertices;
var
  Xv: array of Double;
  Yv: array of Double;
begin
  SetLength(Xv, 0);
  SetLength(Yv, 0);
  if SelectedVertex = 0 then exit;
  project.SetVertexCoords(SelectedObjIndex, Xv, Yv, 0);
  SelectedVertex := 0;
  RedrawMap;
  PaintAction := paVertices;
  MapBox.Refresh;
end;

//------------------------------------------------------------------------------
//  Object Highlighting Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.HiliteTimerTimer(Sender: TObject);
//
//
begin
  if config.MapHiliter then ShowHiliter;
end;

procedure TMapFrame.HiliteObject(const ObjType: Integer; const ObjIndex: Integer);
var
  RectSize: Integer;
  X:        Double = 0;
  Y:        Double = 0;
  P:        TPoint = (X:0; Y:0);
begin
  // Turn off highlighter if no object selected
  if ObjIndex <= 0 then
  begin
    HideHiliter;
    SelectedObjIndex := -1;
    HiliteRect := Rect(0,0,0,0);
    exit;
  end;

  // Get the world coordinates of the selected object
  RectSize := 5;
  if ObjType = ctNodes then
  begin
    if not project.GetNodeCoord(ObjIndex, X, Y) then exit;
    RectSize := Max(Map.Options.LinkSize, Map.Options.NodeSize) + 2;
  end
  else if ObjType = ctLinks then
  begin
    if not project.GetLinkCoord(ObjIndex, X, Y) then exit;
    RectSize := Map.Options.LinkSize + 4;
  end
  else if ObjType = ctLabels then
    P := Map.FindLabelPoint(ObjIndex)
  else
  begin
    SelectedObjType := -1;
    SelectedObjIndex := -1;
    exit;
  end;

  // Save the selected object's type and index (within the type)
  SelectedObjType := ObjType;
  SelectedObjIndex := ObjIndex;

  // Get the selected object's highlighted rectangle
  if ObjType = ctLabels then
    HiliteRect := TMapLabel(project.MapLabels.Objects[ObjIndex-1]).GetRect(P)
  else
  begin
    P := Map.WorldToScreen(X, Y);
    HiliteRect := Rect(P.X - RectSize, P.Y - RectSize, P.X + RectSize, P.Y + RectSize);
  end;
  InflateRect(HiliteRect, 4, 4);

  // Refresh the Hiliter
  HiliteCount := 0;
  HiliteState := 1;
  HiliteTimer.Enabled := true;
  ShowHiliter;
end;

procedure TMapFrame.HideHiliter;
begin
  if not HiliterIsOn then exit;
  HiliteTimer.Enabled := false;
  HiliteRect := Rect(0,0,0,0);
  HiliterIsOn := false;
  HiliteState := 0;
  PaintAction := paNone;
  MapBox.Refresh;
end;

procedure TMapFrame.ShowHiliter;
begin
  HiliterIsOn := true;
  PaintAction := paNone;
  if HiliteState = 1 then PaintAction := paHilite;
  MapBox.Refresh;
  if (HiliteCount >= MAX_HILITE_COUNT)
  and (HiliteState = 1) then
  begin
    HiliteState := 0;
    HiliteTimer.Enabled := false;
  end
  else
  begin
    HiliteState := 1 - HiliteState;
    Inc(HiliteCount);
  end;
end;

procedure TMapFrame.DrawHiliter;
begin
  with MapBox.Canvas do
  begin
    Pen.Color := clRed;
    Pen.Width := 2;
    with HiliteRect do
    begin
      MoveTo(Left,Top);
      LineTo(Right,Top);
      LineTo(Right,Bottom);
      LineTo(Left,Bottom);
      LineTo(Left,Top);
    end;
    Pen.Color := clBlack;
  end;
end;

//------------------------------------------------------------------------------
//  Basemap Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.LoadBasemapFromFile;
//
// Use an image file as a basemap behind the network map.
//
begin
  with OpenPictureDialog1 do
  begin
    if Execute then
    begin
      if not Map.LoadBasemapFile(Filename)then
        utils.MsgDlg(rsFileError, rsNoLoadImage, mtError, [mbOK], MainForm)
      else
      begin
        MainForm.MapViewerFrame.SetBaseMapCheckBox(true);
        Map.Options.ShowBackdrop := true;
        RedrawMap;
        HasBasemap := true;
        BasemapFile := Filename;
      end;
    end;
  end;
  MainForm.SetFocus;
end;

procedure TMapFrame.LoadBasemapFromWeb(MapSource, Epsg, Units: Integer);
//
// Use a WebMap basemap (from an internet mapping service) for the project.
//
var
  TmpExtent:           TDoubleRect;
  NorthEast:           TDoublePoint = (X: -60; Y: 52.5);
  SouthWest:           TDoublePoint = (X: -130; Y: 17.5);
  ShowLocationFinder:  Boolean = false;
begin
  // Change the source for an existing WebMap
  if MapSource <= 0 then exit;
  if Map.Basemap.WebMap <> nil then
  begin
    Map.Basemap.WebMap.SetSource(MapSource);
    Map.Basemap.NeedsRedraw := true;
    RedrawMap;
    exit;
  end;

  // If a network exists, replace default extent with network's
  if not project.IsEmpty then
  begin
    // Create a projection transform for map coords.
    TmpExtent := Map.Extent;
    if Epsg <> 4326 then
    begin
      if not Map.CreateProjTrans(IntToStr(Epsg)) then
      begin
        utils.MsgDlg(rsTransFail, Format(rsNoTransform, [Epsg]), mtInformation,
          [mbOk]);
        Map.Extent := TmpExtent;
        exit;
      end;
    end;
    if mapcoords.HasLatLonCoords(Map.Extent) then
    begin
      NorthEast := Map.Extent.UpperRight;
      SouthWest := Map.Extent.LowerLeft;
    end
    else
    begin
      utils.MsgDlg(rsInvalidData, rsInDegrees, mtInformation, [mbOk]);
      exit;
    end;
  end

  // If no network then ask that the location finder form be shown
  else
    ShowLocationFinder := true;

  // Create a Web Basemap
  Map.CreateWebBasemap(MapSource, NorthEast, SouthWest);

  // Apply the Webmap as a backdrop for the network map
  // (If the web basemap can't be loaded it will be set to nil.)
  ShowWebBasemap;
  if HasWebBasemap then
  begin
    if ShowLocationFinder then
      FindBasemapLocation(MapSource);
    project.MapEPSG := Epsg;
    project.MapUnits := Units;
  end;
end;

procedure TMapFrame.TransformExtent(var ExtentRect: TDoubleRect);
begin
  with ExtentRect do
  begin
    Map.WGS84ToNative(LowerLeft.X, LowerLeft.Y);
    Map.WGS84ToNative(UpperRight.X, UpperRight.Y);
  end;
end;

procedure TMapFrame.ShowWebBasemap;
//
// Display the current Web basemap.
//
begin
  HasBasemap := true;
  MainForm.MapViewerFrame.SetBasemapCheckBox(true);
  Map.Options.ShowBackdrop := true;
  RedrawMap;
  if not HasWebBasemap then
    UnloadBasemap;
end;

procedure TMapFrame.FindBasemapLocation(MapSource: Integer);
//
// Create a Web basemap for a new project centered at user's choice of location.
//
var
  NorthEast: TDoublePoint;
  SouthWest: TDoublePoint;
begin
  if not project.IsEmpty then
    utils.MsgDlg(rsInvalidSelect, rsEmptyNetworks, mtInformation, [mbOk])

  else with TWebMapFinderForm.Create(MainForm) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      NorthEast.X := Lon + 0.125;
      NorthEast.Y := Lat + 0.125;
      SouthWest.X := Lon - 0.125;
      SouthWest.Y := Lat - 0.125;
      Map.CreateWebBasemap(MapSource, NorthEast, SouthWest);
      ShowWebBasemap;
    end;
  finally
    Free;
  end;
end;

procedure TMapFrame.UnloadBasemap;
begin
  if HasWebBasemap then Map.DeleteProjTrans;
  Map.ClearBasemap;
  BasemapFile := '';
  HasBasemap := false;
  Map.Basemap.Visible := false;
  RedrawMap;
  MainForm.OverviewMapFrame.ShowMapExtent;
  MainForm.MapViewerFrame.SetBasemapCheckBox(false);
end;

procedure TMapFrame.SetBasemapBrightness(Brightness: Integer);
begin
  Map.Basemap.Brightness := Brightness;
  RedrawMap;
end;

function  TMapFrame.HasWebBasemap: Boolean;
begin
  Result := Assigned(Map.Basemap.WebMap);
end;

function  TMapFrame.GetWebBasemapSource: Integer;
begin
  if Map.Basemap.WebMap <> nil then
    Result := Map.Basemap.WebMap.MapSource
  else
    Result := -1;
end;

end.

