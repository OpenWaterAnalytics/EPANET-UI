{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mapframe
 Description:  a frame that displays the pipe network and
               handles user interaction with it
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
unit mapframe;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, ExtCtrls, LCLtype,
  Graphics, Clipbrd, ExtDlgs, Types, Math, Dialogs, Menus,

  // EPANET-UI units
  project, map, mapcoords, mapoptions, projtransform;

const
  TICKDELAY    = 100;        //Delay before object can be moved
  MINPIXPAN    = 2;          //Minimum pixel movement for panning
  DELTA        = 2;          //Pixel distance for keyboard moving
  MAX_HILITE_COUNT = 10;

type

  TMapAction = (maSelecting = 1, maVertexing, maFenceLining, maPanning,
                maZooming, maDrawExtent, maAddingJunc, maAddingResv,
                maAddingTank, maAddingPipe, maAddingPump, maAddingValve,
                maAddingLabel);

  TPaintAction = (paNone, paMovingLine, paPolyLine, paPolygon, paRectangle,
                  paVertices, paHilite);

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
    procedure MapMenuItemClick(Sender: TObject);
    procedure HiliteTimerTimer(Sender: TObject);
    procedure MapBoxChangeBounds(Sender: TObject);
    procedure MapBoxClick(Sender: TObject);
    procedure MapBoxMouseDown(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);
    procedure MapBoxMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure MapBoxMouseUp(Sender: TObject; Button: TMouseButton;
              Shift: TShiftState; X, Y: Integer);
    procedure MapBoxMouseWheelDown(Sender: TObject; Shift: TShiftState;
              MousePos: TPoint; var Handled: Boolean);
    procedure MapBoxMouseWheelUp(Sender: TObject; Shift: TShiftState;
      MousePos: TPoint; var Handled: Boolean);
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

    Node1:            Integer;
    Label1:           Integer;
    Point1:           TPoint;
    Point2:           TPoint;
    Points:           array of TPoint;
    CurrentPoint:     TPoint;

    HiliteRect:       TRect;
    HiliteState:      Integer;
    HiliteCount:      Integer;
    HiliterIsOn:      Boolean;

    SelectedObjType:  Integer;
    SelectedObjIndex: Integer;
    NumVertices:      Integer;
    SelectedVertex:   Integer;
    OldTickCount:     QWORD;          //Used to measure a small time delay
    ProjTrans:        TProjTransform; // Basemap projection transformation

    function  StartLinking(const X: Integer; const Y: Integer): Boolean;
    procedure EndLinking(const X: Integer; const Y: Integer);

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
    function  WGS84Transform(Epsg: Integer; var Extent: TDoubleRect): Boolean;

    procedure HideHiliter;
    procedure ShowHiliter;
    procedure DrawHiliter;

  public
    Map:         TMap;
    HasBaseMap:  Boolean;
    BaseMapFile: string;
    Offset:      TPoint;
    CtrlPoint:   array[1..3] of TCtrlPoint;

    procedure AddNode(NodeType: Integer);
    procedure AddLink(LinkType: Integer);
    procedure AddLabel;
    procedure AddVertex;

    procedure ChangeExtent(NewExtent: TDoubleRect);
    procedure ChangeMapLayer(MapLegend: TTreeView);
    procedure Clear;
    procedure Close;

    procedure DrawFullExtent;

    procedure EditMapOptions;
    procedure EnterSelectionMode;
    procedure EnterVertexingMode;
    procedure EnterFenceLiningMode(aMenuAction: string);

    function  GetBasemapSize: TSize;
    function  GetExtent: TDoubleRect;
    function  GetMapRect: TRect;
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

    procedure UnloadBasemap;
    procedure UnloadWebBasemap;
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
  Map := TMap.Create;
  Offset := Point(0, 0);
  MapBox.OnShowHint := @ShowHint;

  HiliteTimer.Interval := 500;
  HiliteTimer.Enabled := false;
  HiliteRect := Rect(0, 0, 0, 0);
  HiliteState := 0;
  HiliterIsOn := false;

  MapAction := maSelecting;
  PaintAction := paNone;
  Linking := false;

  for I := 1 to 3 do
  begin
    CtrlPoint[I].Bitmap := TBitmap.Create;
    MainForm.MarkerImageList.GetBitmap(I-1, CtrlPoint[I].Bitmap);
    CtrlPoint[I].Visible := false;
  end;
  Setlength(Points, 0);
  ProjTrans := nil;
end;

procedure TMapFrame.Clear;
var
  I: Integer;
begin
  HideHiliter;
  FreeAndNil(ProjTrans);

  Map.Reset;
  Offset := Point(0, 0);

  SelectedObjType := -1;
  SelectedObjIndex := -1;

  HasBaseMap := false;
  BaseMapFile := '';
  for I := 1 to 3 do
    CtrlPoint[I].Visible := false;

  PaintAction := paNone;
  MapBox.Refresh;
end;

procedure TMapFrame.Close;
var
  I: Integer;
begin
  for I := 1 to 3 do
    CtrlPoint[I].Bitmap.Free;
  Map.Free;
  ProjTrans.Free;
  SetLength(Points, 0);
end;

procedure TMapFrame.DrawFullExtent;
begin
  Map.Extent := mapcoords.GetBounds(Map.Extent);
  Map.ZoomToExtent;
  RedrawMap;
  if MapAction = maVertexing then
    ShowVertices(SelectedObjIndex);
  HiliteObject(SelectedObjType, SelectedObjIndex);
  MainForm.OverviewMapFrame.ShowMapExtent;
end;

procedure TMapFrame.ResizeTimerTimer(Sender: TObject);
begin
  ResizeTimer.Enabled := false;
  ResizeMap;
end;

procedure TMapFrame.ResizeMap;
begin
  if Assigned(Map) then
  begin
    Map.Resize(Rect(0, 0, MapBox.ClientWidth, MapBox.ClientHeight));
    RedrawMap;
    HiliteObject(SelectedObjType, SelectedObjIndex);
  end;
end;

procedure TMapFrame.ChangeExtent(NewExtent: TDoubleRect);
var
  S1: TScalingInfo;
  S2: TScalingInfo;
begin
  S1 := Map.GetScalingInfo;
  Map.Extent := NewExtent;
  Map.Rescale;
  Map.SetBasemapBounds;
  S2 := Map.GetScalingInfo;
  MapCoords.DoScalingTransform(S1, S2);
  DrawFullExtent;
  MainForm.OverviewMapFrame.Redraw;
  if (not project.HasChanged)
  and (not project.IsEmpty) then
    project.HasChanged := true;
end;

procedure TMapFrame.SetMapCenter(X, Y: Double);
begin
  Map.SetCenter(X, Y);
  RedrawMap;
end;

procedure TMapFrame.HiliteTimerTimer(Sender: TObject);
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

procedure TMapFrame.MoveObject(W: TDoublePoint);
begin
  if SelectedObjType = ctNodes then
  begin
    project.SetNodeCoord(SelectedObjIndex, W.X, W.Y);
    project.AdjustLinkLengths(Node1);
  end
  else if SelectedObjType = ctLabels then
    project.SetLabelCoord(SelectedObjIndex, W.X, W.Y);
  if (not project.HasChanged)
  and (not project.IsEmpty) then
    project.HasChanged := true;
  RedrawMap;
  MainForm.OverviewMapFrame.Redraw;
end;

procedure TMapFrame.MoveObjectByPixel(Key: Word);
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
  MapBox.Cursor := crCross;
  MainForm.EnableMainForm(false);
  SetFocus;
end;

procedure TMapFrame.AddLink(LinkType: Integer);
begin
  case LinkType of
    ltPipe:
      MapAction := maAddingPipe;
    ltPump:
      MapAction := maAddingPump;
    ltValve:
      MapAction := maAddingValve;
  end;
  HideHiliter;
  ShowJunctions;
  MapBox.Cursor := crHandPoint;
  MainForm.EnableMainForm(false);
  SetFocus;
end;

procedure TMapFrame.AddLabel;
begin
  MapAction := maAddingLabel;
  HideHiliter;
  MapBox.Cursor := crCross;
  MainForm.EnableMainForm(false);
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
begin
  Linking := false;
  FenceLining := false;
  Moving := false;
  Node1 := 0;
  Label1 := 0;
  MapAction := maSelecting;
  PaintAction := paNone;
  Offset := Point(0, 0);
  MapBox.Refresh;
  MapBox.Cursor := crDefault;
end;

function TMapFrame.StartLinking(const X: Integer; const Y: Integer): Boolean;
var
  I: Integer;
begin
  I := Map.FindNodeHit(X, Y);
  if I > 0 then
  begin
    Node1 := I;
    SetLength(Points, 1);
    Points[0] := Point(X, Y);
    MapBox.Cursor := crCross;
    Result := true;
  end
  else Result := false;
end;

procedure TMapFrame.EndLinking(const X: Integer; const Y: Integer);
var
  Node2, I: Integer;
begin
  // Add current mouse position to link's vertex points
  SetLength(Points, Length(Points) + 1);
  Points[High(Points)] := Point(X, Y);
  CurrentPoint := Point(X, Y);

  // See if current point falls on a node
  Node2 := Map.FindNodeHit(X, Y);
  if Node2 > 0 then
  begin
    MapBox.Cursor := crHandPoint;

    // Link start and end nodes are different
    if Node1 <> Node2 then
    begin

      // Convert MapAction to project's Link type
      I :=  Ord(MapAction) - Ord(maAddingPipe) + 1;

      // Add link to project
      ProjectBuilder.AddLink(I, Node1, Node2);
      if I >= ltPipe then AddLink(I);

      // Quit Linking
      SetLength(Points, 0);
      Linking := false;
    end;
  end;
end;

procedure TMapFrame.EnterFenceLiningMode(aMenuAction: string);
begin
  HideHiliter;
  MenuAction := aMenuAction;
  MapAction := maFenceLining;
  FenceLining := false;
  SetLength(Points, 0);
  NumVertices := -1;
  MainForm.EnableMainForm(false);
  MapBox.Cursor := crCross;
end;

procedure TMapFrame.GoFenceLining(X: Integer; Y: Integer);
begin
  SetLength(Points, Length(Points) + 1);
  Points[High(Points)] := Point(X, Y);
  CurrentPoint := Point(X, Y);
  NumVertices := Length(Points);
  FenceLining := true;
end;

procedure TMapFrame.LeaveFenceLiningMode;
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
  FenceLining := false;
  SetLength(Points, 0);
  if MenuAction = 'GroupEditing' then
  begin
    MainForm.HideHintPanel;
    MainForm.ProjectFrame.GroupEdit(WorldPoly, N);
    MainForm.EnableMainForm(true);
  end
  else if MenuAction = 'FireFlowSelection' then
  begin
    MainForm.FireFlowSelectorFrame.GroupSelect(WorldPoly, N);
  end
  else
    MainForm.EnableMainForm(true);
  EnterSelectionMode;
end;

procedure TMapFrame.EnterVertexingMode;
begin
  HideHiliter;
  MapAction := maVertexing;
  if SelectedObjType = ctLinks then
  begin
    MainForm.EnableMainForm(false);
    SelectedVertex := 1;
    PaintAction := paVertices;
    MapBox.Refresh;
  end;
  MapBox.Cursor := crHandPoint;
end;

procedure TMapFrame.LeaveVertexingMode;
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
begin
  Map.Extent := E;
end;

function TMapFrame.GetExtent: TDoubleRect;
begin
  Result := Map.Extent;
end;

function TMapFrame.GetMapRect: TRect;
begin
  Result := Map.MapRect;
end;

procedure TMapFrame.RedrawMap;
begin
  HideHiliter;
  Map.Redraw;
  if MainForm.GeoRefFrame.Visible then
    DrawCtrlPoints;
  PaintAction := paNone;
  MapBox.Refresh;
  if MapAction = maSelecting then
    HiliteObject(SelectedObjType, SelectedObjIndex);
end;

procedure TMapFrame.DrawCtrlPoints;
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
begin
  if Map.Options.ShowLabels then RedrawMap;
end;

procedure TMapFrame.GoKeyDown(var Key: Word; Shift: TShiftState);
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

    else
      ShowVertices(SelectedObjIndex);
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

  else if MapAction in [maAddingJunc .. maAddingLabel] then
  begin
    if Key = VK_ESCAPE then
    begin
      Mainform.EnableMainForm(true);
      EnterSelectionMode;
    end;
  end;
end;

procedure TMapFrame.ChangeMapLayer(MapLegend: TTreeView);
var
  TreeNode:   TTreeNode;
  IsSelected: Boolean;
begin
  // Find the selected MapLegend Tree node
  TreeNode := MapLegend.Selected;
  if TreeNode = nil then exit;
  if TreeNode.StateIndex = -1 then exit;

  // Change the Checked/Unchecked state of the node
  TreeNode.StateIndex := 1 - TreeNode.StateIndex;
  IsSelected := (TreeNode.StateIndex = 1);
  MapLegend.Refresh;

  // Apply the new state to the network map's display options
  // (Note: Tree nodes representing display options were
  // assigned SelectedIndex values at design time.)
  case TreeNode.SelectedIndex of
    0:
      Map.Options.ShowNodes := IsSelected;
    1:
      Map.Options.ShowJunctions := IsSelected;
    2:
      Map.Options.ShowTanks := IsSelected;
    3:
      Map.Options.ShowLinks := IsSelected;
    4:
      Map.Options.ShowPumps := IsSelected;
    5:
      Map.Options.ShowValves := IsSelected;
    6:
      Map.Options.ShowLabels := IsSelected;
    7:
      begin
       Map.Options.ShowBackdrop := IsSelected;
       Map.Basemap.NeedsRedraw := IsSelected;
     end;
    8:
      begin
        MainForm.OverviewPanel.Visible := IsSelected;
        if IsSelected then MainForm.OverviewMapFrame.Redraw;
        MapLegend.Selected := nil;
        exit;
      end;
  end;

  // Redraw the network map
  MapLegend.Selected := nil;
  RedrawMap;
end;

procedure TMapFrame.ShowJunctions;
var
  TreeNode: TTreeNode;
begin
  // Redraw map with nodes displayed
  if (Map.Options.ShowNodes = false)
  or (Map.Options.ShowJunctions = false) then
  begin
    Map.Options.ShowNodes := true;
    Map.Options.ShowJunctions := true;
    RedrawMap;
  end;

  // Update the main form's map layers tree view
  for TreeNode in MainForm.LegendTreeView.Items do
  begin
    if TreeNode.Text = rsNodes then
    begin
      if TreeNode.StateIndex = 0 then TreeNode.StateIndex := 1;
    end
    else if TreeNode.Text = rsJunctions then
    begin
      if TreeNode.StateIndex = 0 then TreeNode.StateIndex := 1;
    end;
  end;
end;

procedure TMapFrame.InitMapOptions;
begin
  Map.Options := mapoptions.DefaultOptions;
end;

procedure TMapFrame.EditMapOptions;
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
begin
  with Sender as TMenuItem do
    MainForm.ProjectFrame.ConvertItem(Tag);
end;

//------------------------------------------------------------------------------
//  MapBox Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.MapBoxPaint(Sender: TObject);
var
  OldBrushStyle: TBrushStyle;
begin
  if not Assigned(Map) then exit;

  // Fill the entire MapBox area with the network map's bitmap
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
  if (PaintAction = paPolyLine)
  and (Length(Points) > 0) then with MapBox.Canvas do
  begin
    Pen.Style := psDot;
    Pen.Width := 2;
    if Length(Points) > 1 then
      PolyLine(Points);
    MoveTo(Points[High(Points)].X, Points[High(Points)].Y);
    LineTo(CurrentPoint.X, CurrentPoint.Y);
    Pen.Style := psSolid;
    Pen.Width := 1;
  end;

  // Used when moving a node or map label
  if PaintAction = paMovingLine then
  begin
    with MapBox.Canvas do
    begin
      Pen.Style := psDot;
      Pen.Width := 2;
      MoveTo(Point1.X, Point1.Y);
      LineTo(CurrentPoint.X, CurrentPoint.Y);
      Pen.Style := psSolid;
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
  if (PaintAction = paVertices)
  {or (MapAction = maVertexing)} then ShowVertices(SelectedObjIndex);
  PaintAction := paNone;
end;

procedure TMapFrame.MapBoxResize(Sender: TObject);
begin
  ResizeTimer.Enabled := true;
end;

procedure TMapFrame.MapBoxChangeBounds(Sender: TObject);
begin
  ResizeTimer.Enabled := false;
end;

procedure TMapFrame.MapBoxClick(Sender: TObject);
var
  I: Integer;
  W: TDoublePoint;
begin
  if MainForm.GeoRefFrame.Visible then
  begin
    W := Map.ScreenToWorld(Point1.X, Point1.Y);
    I := MainForm.GeoRefFrame.GetCtrlPointIndex(W);
    if I > 0 then
    begin
      CtrlPoint[I].Position := W;
      CtrlPoint[I].Visible := true;
      RedrawMap;
    end;
  end;
end;

procedure TMapFrame.MapBoxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  I: Integer;
begin
  Moving := false;

  if MapAction = maVertexing then
  begin
    if SelectVertex(X, Y)
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
      MainForm.ProjectFrame.SelectItem(ctNodes, I-1);
      Node1 := I;
      Point1 := Point(X, Y);
      Point2 := Point1;
      if Shift = [ssLeft, ssCtrl] then Moving := true;
      OldTickCount := GetTickCount64;
    end

    else
    begin
      I := Map.FindLinkHit(X, Y);
      if I > 0 then
        MainForm.ProjectFrame.SelectItem(ctLinks, I-1)
      else
      begin
        I := Map.FindLabelHit(X, Y);
        if I > 0 then
        begin
          MainForm.ProjectFrame.SelectItem(ctLabels, I-1);
          Label1 := I;
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

    if MainForm.MapAlignFrame.Visible then
      MainForm.MapAlignFrame.SetLocation(Map.ScreenToWorld(X, Y));

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
var
  XY: TDoublePoint;
begin
  if Assigned(Map) then
  begin
    XY := Map.ScreenToWorld(X, Y);
    if ProjTrans <> nil then ProjTrans.Transform(XY.X, XY.Y);
    MainForm.UpdateXYStatus(XY.X, XY.Y);
  end;

  if Moving then
  begin
    HideHiliter;
    if Moving then
    begin
      if (Shift <> [ssLeft, ssCtrl])
      or (GetTickCount64 - OldTickCount < TICKDELAY) then
        exit;
      OldTickCount := 0;
    end;
    PaintAction := paMovingLine;
    CurrentPoint := Point(X, Y);
    MapBox.Refresh;
  end

  else if Linking or FenceLining then
  begin
    CurrentPoint := Point(X, Y);
    PaintAction := paPolyline;
    MapBox.Refresh;
  end

  else if MapAction = maPanning then
  begin
    if Shift = [ssLeft] then
    begin
      if (GetTickCount64 - OldTickCount < TICKDELAY) then exit;
      OldTickCount := 0;
      HideHiliter;
      MapBox.Cursor := crSize;
      Offset := Point(X - Point1.X, Y - Point1.Y);
      if (Abs(Offset.X) > MINPIXPAN) or (Abs(Offset.Y) > MINPIXPAN) then
      begin
        PaintAction := paNone;
        MapBox.Refresh;
      end;
    end;
  end;
end;

procedure TMapFrame.MapBoxMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
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
    if MapAction = maVertexing then
    begin
      PaintAction := paVertices;
      MapBox.Cursor := crHandPoint;
    end
    else
    begin
      MapAction := maSelecting;
      MapBox.Cursor := crDefault;
    end;
    if (Abs(Offset.X) > MINPIXPAN) or (Abs(Offset.Y) > MINPIXPAN) then
    begin
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
    ProjectBuilder.AddNode(I, W.X, W.Y);
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
    ProjectBuilder.AddLabel(P, W.X, W.Y);
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

procedure TMapFrame.MapBoxMouseWheelDown(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if FenceLining then exit;
  ZoomOut(MousePos.x - (MapBox.ClientWidth div 2),
    MousePos.y - (MapBox.ClientHeight div 2));
end;

procedure TMapFrame.MapBoxMouseWheelUp(Sender: TObject; Shift: TShiftState;
  MousePos: TPoint; var Handled: Boolean);
begin
  if FenceLining then exit;
  ZoomIn(MousePos.x - (MapBox.ClientWidth div 2),
    MousePos.y - (MapBox.ClientHeight div 2));
end;

//------------------------------------------------------------------------------
//  Link Vertex Editing Procedures
//------------------------------------------------------------------------------

procedure TMapFrame.GetVertices(var X: array of Double; var Y: array of Double;
  var N: Integer);
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

procedure TMapFrame.HideHiliter;
begin
  if not HiliterIsOn then exit;
  begin
    HiliteTimer.Enabled := false;
    HiliteRect := Rect(0,0,0,0);
    HiliterIsOn := false;
    HiliteState := 0;
    PaintAction := paNone;
    MapBox.Refresh;
  end;
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
begin
  with OpenPictureDialog1 do
  begin
    if Execute then
    begin
      if not Map.LoadBasemapFile(Filename)then
        utils.MsgDlg(rsFileError, rsNoLoadImage, mtError, [mbOK], MainForm)
      else
      begin
        mapthemes.SetBaseMapVisible(true);
        Map.Options.ShowBackdrop := true;
        RedrawMap;
        HasBaseMap := true;
        BaseMapFile := Filename;
      end;
    end;
  end;
  MainForm.SetFocus;
end;

procedure TMapFrame.LoadBasemapFromWeb(MapSource, Epsg, Units: Integer);
var
  NorthEast:           TDoublePoint = (X: -60; Y: 52.5);
  SouthWest:           TDoublePoint = (X: -130; Y: 17.5);
  ShowLocationFinder:  Boolean = false;
begin
  // Change the source for an existing WebMap
  if MapSource < 0 then exit;
  if Map.Basemap.WebMap <> nil then
  begin
    Map.Basemap.WebMap.SetSource(MapSource);
    Map.Basemap.NeedsRedraw := true;
  end

  // Otherwise load a new WebMap with default extent (North America)
  else
  begin

    // If a network exists, replace default extent with network's
    FreeAndNil(ProjTrans);
    if not project.IsEmpty then
    begin

      // Transform coordinates to WGS84 if a different EPSG provided
      if (Epsg > 0) and (Epsg <> 4326) then
        if not WGS84Transform(Epsg, Map.Extent) then exit;

      // Check that (transformed) map extent has valid WGS84 coords.
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
  end;

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

function TMapFrame.WGS84Transform(Epsg: Integer; var Extent: TDoubleRect): Boolean;
var
  TmpExtent:   TDoubleRect;
  Transformed: Boolean = false;
begin
  // Check that current map extent can be transformed
  Result := false;
  TmpExtent := Extent;
  if mapcoords.CanProjectionTransform(IntToStr(Epsg), '4326', Extent) then
  begin
    MainForm.Cursor := crHourGlass;
    Transformed := mapcoords.DoProjectionTransform(IntToStr(Epsg),
      '4326', Extent);
     MainForm.Cursor := crDefault;
  end;
  if not Transformed then
  begin
    Extent := TmpExtent;
    utils.MsgDlg(rsTransFail, Format(rsNoTransform, [Epsg]), mtInformation, [mbOk]);
    exit;
  end;

  // Create a transform to re-project WGS84 to MapEPSG
  // (used when displaying coords. on main form's status bar.)
  if Epsg <> 4326 then
  begin
    ProjTrans := TProjTransform.Create;
    ProjTrans.SetProjections('4326', IntToStr(Epsg));
  end;
  Result := true;
end;

procedure TMapFrame.ShowWebBasemap;
begin
  mapthemes.SetBaseMapVisible(true);
  Map.Options.ShowBackdrop := true;
  HasBaseMap := true;
  RedrawMap;
  if not HasWebBasemap then
    UnloadBasemap;
end;

procedure TMapFrame.FindBasemapLocation(MapSource: Integer);
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

function TMapFrame.GetBasemapSize: TSize;
begin
  Result := Size(Map.Basemap.Picture.Width, Map.Basemap.Picture.Height);
end;

procedure TMapFrame.UnloadBasemap;
begin
  mapthemes.SetBaseMapVisible(false);
  if HasWebBasemap then UnloadWebBasemap;
  Map.ClearBasemap;
  RedrawMap;
  MainForm.OverviewMapFrame.ShowMapExtent;
  HasBaseMap := false;
end;

procedure TMapFrame.UnloadWebBasemap;
begin
  // Revert coord. projection to its original value
  FreeAndNil(ProjTrans);
  if (project.MapEPSG > 0)
  and (project.MapEPSG <> 4326) then
  begin
    mapcoords.DoProjectionTransform('4326', IntToStr(project.MapEPSG),
      Map.Extent);
  end;
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

