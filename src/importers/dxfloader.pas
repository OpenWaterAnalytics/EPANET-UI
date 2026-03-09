{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       dxfloader
 Description:  reads contents of a DXF file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit dxfloader;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Graphics, StrUtils, Dialogs;

type
  TDxfOptions = record
    CoordUnits:       Integer;
    SnapTol:          Double;
    ComputeLengths:   Boolean;
  end;

const
  MISSING = -1.0E40;
  _POLYLINE   = 0;
  _LWPOLYLINE = 1;
  _LINE       = 2;
  _VERTEX     = 3;
  _SEQEND     = 4;

  IN_NONE     = 0;
  IN_POLYLINE = 1;
  IN_LINE     = 2;
  IN_VERTEX   = 3;

  luFEET   = 1;
  luMETERS = 2;

  Keywords: array[0..4] of string =
    ('POLYLINE', 'LWPOLYLINE', 'LINE', 'VERTEX', 'SEQEND');

procedure LoadDxfFile(DxfFileName: string; Layers: TStringList;
            DxfOptions: TDxfOptions);

function  FindEntitiesSection(var F: TextFile): Boolean;

procedure GetLinkVertices(var F: TextFile; Layers: TStringList;
            var Vx: array of Double; var Vy: array Of Double; var Vcount: Integer);

implementation

uses
  main, project, projectbuilder, mapcoords, utils, epanet2;

var
  X:              Double;
  Y:              Double;   // Current coordinates being processed
  SnapTol:        Double;
  LengthUcf:      Double;
  StatusCode:     Integer;  // Current status of reading the DXF file
  CoordCount:     Integer;  // Count of processed link coordinates
  ComputeLengths: Boolean;

function FindEntitiesSection(var F: TextFile): Boolean;
var
  Code: Integer;
  Value: string;
begin
  Result := true;
  while not Eof(F) do
  begin
    ReadLn(F, Code);
    ReadLn(F, Value);
    if (Code = 2)
    and SameText(Value, 'ENTITIES') then
      exit;
  end;
  Result := false;
end;

procedure DoKeyWord(Kw: Integer);
begin
  case Kw of
    _POLYLINE,
    _LWPOLYLINE:
      begin
        StatusCode := IN_POLYLINE;
        CoordCount := 0;
      end;
    _LINE:
      begin
        StatusCode := IN_LINE;
        CoordCount := 0;
      end;
    _VERTEX:
      begin
        if StatusCode <> IN_NONE then StatusCode := IN_VERTEX;
      end;
    _SEQEND:
      begin
        StatusCode := IN_NONE;
        CoordCount := 0;
      end;
  end;
end;

procedure AddVertex(Code: Integer; V: Double; var Vx: array of Double;
            var Vy: array Of Double; var Vcount: Integer);
begin
  Inc(CoordCount);
  case Code of
    10:
        X := V;
    20:
        Y := V;
    11:
        X := V;
    21:
        Y := V;
  end;
  if not Odd(CoordCount) then
  begin
    Vx[Vcount] := X;
    Vy[Vcount] := Y;
    if Vcount < Project.MAX_VERTICES then Inc(Vcount);
  end;
end;

procedure GetLinkVertices(var F: TextFile; Layers: TStringList;
            var Vx: array of Double; var Vy: array Of Double; var Vcount: Integer);
var
  Code: Integer;
  S:    string;
  V:    Double = 0;
begin
  // Initialize status variables
  StatusCode := IN_NONE;
  CoordCount := 0;
  Vcount := 0;

  // Read pairs of lines from DXF file
  while not Eof(F) do
  begin
    Readln(F,Code);
    Readln(F,S);

    // Check if reached end of current link being processed
    if SameText(S, 'SEQEND')
    and (StatusCode in [IN_LINE, IN_VERTEX]) then
      exit;

    // Process DXF code
    case Code of
      0: // Key word text
        DoKeyWord(AnsiIndexText(S, Keywords));


      8: // Layer name
        if (StatusCode in [IN_LINE,IN_POLYLINE])
        and (Layers.Count > 0) then
        begin
          if (Layers.IndexOf(S) < 0) then StatusCode := IN_NONE;
        end;


      10, 11, 20, 21: // Coordinate vertex value
        begin
          utils.Str2Float(S, V);
          if (StatusCode = IN_LINE)
          or (StatusCode = IN_VERTEX) then
            AddVertex(Code,V,Vx,Vy,Vcount);
        end;
    end;
  end;
end;

function GetNearestNode(P: TDoublePoint): Integer;
var
  J:    Integer;
  Jmin: Integer;
  D:    Double;
  Dmin: Double;
  Pj:   TDoublePoint = (X: 0; Y: 0);
begin
  Jmin := 0;
  Dmin := 1.0e40;

  // Examine each project node
  for J := 1 to project.GetItemCount(ctNodes) do
  begin

    // Find Manhattan distance between point P and the node point Pj
    if not project.GetNodeCoord(J, Pj.X, Pj.Y) then continue;
    D := mapcoords.ManhattanDistance(P, Pj);

    // Update minimum distance found
    if D < Dmin then
    begin
      Dmin := D;
      Jmin := J;
    end;
  end;

  // Check that minimum distance is within snap tolerance
  if Dmin <= SnapTol then
    Result := Jmin
  else
    Result := 0;
end;

function AddNode(P: TDoublePoint): Integer;
var
  ID:        string;
  Err:       Integer;
  NodeIndex: Integer = 0;
begin
  Result := 0;
  ID := projectbuilder.FindUnusedID(ctNodes, project.ntJunction);
  Err := epanet2.ENaddnode(PAnsiChar(ID), EN_JUNCTION, NodeIndex);
  if Err = 0 then
  begin
    epanet2.ENsetcoord(NodeIndex, P.X, P.Y);
    epanet2.ENsetnodevalue(NodeIndex, EN_ELEVATION,
      StrToFloatDef(project.DefProps[1], 0));
    Result := NodeIndex;
  end;
end;

function GetEndNode(P: TDoublePoint): string;
var
  J: Integer;
begin
  // Link node is within snap tolerance of an existing node
  Result := '';
  J := GetNearestNode(P);
  if J > 0 then
    Result := project.GetID(ctNodes, J)

  // Otherwise add a new node
  else
  begin
    J := AddNode(P);
    if J > 0 then Result := project.GetID(ctNodes, J);
  end;
end;

procedure SetLinkProps(LinkIndex: Integer);
var
  Len: Single;
  Diameter: Single;
  Roughness: Single;
begin
  Len := StrToFloatDef(project.DefProps[4], 0.0);
  if project.AutoLength
  or ComputeLengths then
    Len := project.FindLinkLength(LinkIndex) * LengthUcf;
  Diameter := StrToFloatDef(project.DefProps[5], 0.0);
  Roughness := StrToFloatDef(project.DefProps[6], 0.0);
  epanet2.ENsetpipedata(LinkIndex, Len, Diameter, Roughness, 0.0);
end;

function NewLink(StartNode: string; EndNode: string): Integer;
var
  LinkIndex: Integer = 0;
  Err:       Integer;
  LinkID:    string;
begin
  Result := 0;
  LinkID := projectbuilder.FindUnusedID(ctLinks, EN_PIPE);
  Err := epanet2.ENaddlink(Pchar(LinkID), EN_PIPE, PChar(StartNode),
    PChar(EndNode), LinkIndex);
  if Err = 0 then
  begin
    SetLinkProps(LinkIndex);
    Result := LinkIndex;
  end;
end;

procedure AddLink(var Vx: array of Double; var Vy: array Of Double;
            Vcount: Integer);
var
  StartNode: string;
  EndNode: string;
  LinkIndex: Integer;
  P: TDoublePoint;
begin
  // Must have at least 2 vertices
  if Vcount < 2 then exit;

  // Find start node of the link
  P.X := Vx[0];
  P.Y := Vy[0];
  StartNode := GetEndNode(P);
  if Length(StartNode) = 0 then exit;

  // Find end node of the link
  P.X := Vx[Vcount-1];
  P.Y := Vy[Vcount-1];
  EndNode := GetEndNode(P);
  if Length(EndNode) = 0 then exit;

  // Add the link and its vertices to the project
  LinkIndex := NewLink(StartNode, EndNode);
  if (LinkIndex > 0)
  and (Vcount > 2) then
    epanet2.ENsetvertices(LinkIndex, Vx[1], Vy[1], Vcount-2);
end;

procedure LoadDxfFile(DxfFileName: string; Layers: TStringList;
            DxfOptions: TDxfOptions);
var
  F: TextFile;
  Vx: array[0..project.MAX_VERTICES] of Double;
  Vy: array[0..project.MAX_VERTICES] of Double;
  Vcount: Integer;
begin
  SnapTol := DxfOptions.SnapTol;
  ComputeLengths := DxfOptions.ComputeLengths;
  LengthUcf := 1.0;
  if (DxfOptions.CoordUnits = luMETERS)
  and (project.GetUnitsSystem = usUS) then
    LengthUcf := 3.28084
  else if (DxfOptions.CoordUnits = luFEET)
  and (project.GetUnitsSystem = usSI) then
    LengthUcf := 1 / 3.28084;

  AssignFile(F, DxfFileName);
  try
    Reset(F);
    if not FindEntitiesSection(F) then exit;
    while not Eof(F) do
    begin
      Vcount := 0;
      GetLinkVertices(F, Layers, Vx, Vy, Vcount);
      AddLink(Vx, Vy, Vcount);
    end;
    MainForm.MapFrame.SetExtent(mapcoords.GetBounds(MainForm.MapFrame.GetExtent));
    MainForm.MapFrame.DrawFullextent;
    Project.HasChanged := true;
    Project.UpdateResultsStatus;
  finally
    CloseFile(F);
  end;
end;

end.

