{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       shploader
 Description:  loads the contents of a shapefile into a project
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit shploader;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, StrUtils, Math;

type
  TShpOptions = record
    NodeFileName:     string;
    LinkFileName:     string;
    NodeAttribs:      array[1..6] of Integer;
    NodeUnits:        array[1..6] of string;
    LinkAttribs:      array[1..9] of Integer;
    LinkUnits:        array[1..9] of string;
    CoordUnits:       Integer;
    Epsg:             Integer;
    SnapTol:          Double;
    SnapUnits:        Integer;
    ComputeLengths:   Boolean;
  end;

const
  nID        = 1;
  nType      = 2;
  nDescrip   = 3;
  nTag       = 4;
  nElev      = 5;
  nDemand    = 6;

  lID        = 1;
  lType      = 2;
  lStartNode = 3;
  lEndNode   = 4;
  lDescrip   = 5;
  lTag       = 6;
  lLength    = 7;
  lDiam      = 8;
  lRough     = 9;

var
  ShpOptions: TShpOptions;

function LoadShapeFile(theShpOptions: TShpOptions): Boolean;

implementation

uses
  main, mapcoords, project, projectbuilder, shpapi, projtransform, utils,
  resourcestrings, epanet2;

const
  FlowPerCFS: array[0..10] of Double =
    (1.0, 448.831, 0.64632, 0.5382, 1.9837,  {CFS, GPM, MGD, IMGD, AFD per CFS}
     28.317, 1699.0, 2.4466, 101.94, 2446.6, {LPS, LPM, MLD, CMH, CMD per CFS}
     0.028317); {CMS per CFS}

var
  FieldType:            array of DBFFieldType;
  SrcEpsg,
  DstEpsg:              Integer;
  SnapTol:              Double;
  SnapUcf:              Double;
  HasDegreesUnits:      Boolean;
  NeedsProjTransform:   Boolean;
  ProjTrans:            TProjTransform;

function GetstringAttrib(Dbf: DBFHandle; I, J: Integer; var S: string): Boolean;
begin
  S := '';
  Result := false;
  if J < 0 then exit;
  if FieldType[J] <> FTstring then exit;
  S := shpapi.DBFReadstringAttribute(Dbf, I, J);
  Result := true;
end;

function GetNumericalAttrib(Dbf: DBFHandle; I, J: Integer; var V: Double): Boolean;
begin
  V := 0;
  Result := false;
  if J < 0 then exit;
  if FieldType[J] = FTInteger then
    V := shpapi.DBFReadIntegerAttribute(Dbf, I, J)
  else if FieldType[J] = FTDouble then
    V := shpapi.DBFReadDoubleAttribute(Dbf, I, J)
  else if FieldType[J] = FTstring then
    TryStrToFloat(shpapi.DBFReadstringAttribute(Dbf, I, J), V)
  else
    exit;
  Result := true;
end;

function GetID(Dbf: DBFHandle; I, J: Integer): string;
begin
  if FieldType[J] = FTstring then
    Result := shpapi.DBFReadstringAttribute(Dbf, I, J)
  else if FieldType[J] = FTInteger then
    Result := IntToStr(shpapi.DBFReadIntegerAttribute(Dbf, I, J))
  else
    Result := '';
end;

{==================== NODE FUNCTIONS =======================================}

function GetNodeID(Dbf: DBFHandle; NodeType: Integer; I: Integer;
  var Index: Integer): string;
var
  J:  Integer;
  ID: string;
begin
  // Try reading ID from dBase file
  ID := '';
  Index := 0;
  if Dbf <> nil then
  begin
    J := ShpOptions.NodeAttribs[nID];
    if J >= 0 then ID := GetID(Dbf, I, J);
  end;

  // Check if ID used by another node
  if Length(ID) > 0 then
    epanet2.ENgetnodeindex(PAnsiChar(ID), Index)
  else
    ID := projectbuilder.FindUnusedID(ctNodes, NodeType);
  Result := ID;
end;

function GetNodeType(Dbf: DBFHandle; I: Integer): Integer;
var
  J: Integer;
  K: Integer;
  S: string;
begin
  // Assume node type is a Junction
  Result := project.ntJunction;
  if Dbf <> nil then
  begin
    // J is the 0-based field index for node type in the dBase file
    J := ShpOptions.NodeAttribs[nType];
    if J >= 0 then
    begin
      // Node type appears as a string attribute
      if FieldType[J] = FTstring then
      begin
        S := shpapi.DBFReadstringAttribute(Dbf, I, J);
        // See if string S is a Reservoir or a Tank
        if StartsText('RES', S) then
          Result := project.ntReservoir
        else if StartsText('TANK', S) then
          Result := project.ntTank;
      end;

      // Node type appears as an integer type code
      if FieldType[J] = FTInteger then
      begin
        K := shpapi.DBFReadIntegerAttribute(Dbf, I, J);
        if K = project.ntReservoir then
          Result := K
        else if K = project.ntTank then
          Result := K;
      end;
    end;
  end;
end;

function NodeUcf(Attrib: Integer): Double;
//
// Return a units conversion factor for a given node attribute.
//
var
  S: string;
  I: Integer;
  J: Integer = 0;
begin
  // Find the units S that the user specified for the attribute
  Result := 1;
  S := ShpOptions.NodeUnits[Attrib];
  if Length(S) = 0 then exit;
  
  // Find the conversion factor for Elevation
  if Attrib = nElev then
  begin
    if SameText(S, 'METERS') and (project.GetUnitsSystem = usUS) then
      Result := 3.28084
    else if SameText(S, 'FEET') and (project.GetUnitsSystem = usSI) then
      Result := 1 / 3.28084;
  end;
  
  // Find the conversion factor for base Demand
  if Attrib = nDemand then
  begin
    I := AnsiIndexText(S, project.FlowUnitsStr); //Attrib flow units index
    epanet2.ENgetflowunits(J);                   //Project flow units index
    if I >= 0 then
      Result := FlowPerCFS[J] / FlowPerCFS[I];
  end;
end;

procedure SetNodeProps(Dbf: DBFHandle; I: Integer; NodeIndex: Integer);
//
// Set the properties of the project node with index NodeIndex to the
//  corresponding attributes stored in the I-th dBase file record.
//
var
  S: string = '';
  V: Double = 0;
begin
  // Node description comment
  if GetstringAttrib(Dbf, I, ShpOptions.NodeAttribs[nDescrip], S)
  and (Length(S) > 0) then
    epanet2.ENsetcomment(EN_NODE, NodeIndex, PAnsiChar(S));
  
  // Node elevation
  if GetNumericalAttrib(Dbf, I, ShpOptions.NodeAttribs[nElev], V) then
    epanet2.Ensetnodevalue(NodeIndex, EN_ELEVATION, NodeUcf(nElev)*V);

  // Node demand
  if GetNumericalAttrib(Dbf, I, ShpOptions.NodeAttribs[nDemand], V) then
    epanet2.Ensetnodevalue(NodeIndex, EN_BASEDEMAND, NodeUcf(nDemand)*V);
end;

function AddNode(Dbf: DBFHandle; I: Integer;  X,Y: Double): Integer;
//
// Add a new node to the project from the I-th record in a nodes shape file.
// (X,Y already transformed if needed.)
//
var
  ID:        string;
  NodeType:  Integer;
  NodeIndex: Integer;
begin
  Result := 0;
  NodeType := GetNodeType(Dbf, I);
  NodeIndex := 0;
  ID := GetNodeID(Dbf, NodeType, I, NodeIndex);
  if NodeIndex = 0 then
  begin
    if epanet2.ENaddnode(PAnsiChar(ID), NodeType, NodeIndex) = 0 then
    begin
      epanet2.ENsetnodevalue(NodeIndex, EN_ELEVATION,
        StrToFloatDef(project.DefProps[1], 0));
      if NodeType = ntTank then
      begin
        epanet2.ENsetnodevalue(NodeIndex, EN_MAXLEVEL,
          StrToFloatDef(project.DefProps[2], 0.0));
        epanet2.ENsetnodevalue(NodeIndex, EN_TANKDIAM,
          StrToFloatDef(project.DefProps[3], 0.0));
      end;
    end;
  end;
  if NodeIndex > 0 then
  begin
    epanet2.ENsetcoord(NodeIndex, X, Y);
    if (Dbf <> nil) then SetNodeProps(Dbf, I, NodeIndex);
  end;
  Result := NodeIndex;
end;

procedure GetFieldTypes(Dbf: DBFHandle);
var
  I:      Integer;
  N:      Integer;
  Fname:  array[0..XBASE_FLDNAME_LEN_READ] of Char = '';
  Fwidth: Integer = 0;
  Fdec:   Integer = 0;
begin
  N := shpapi.DBFGetFieldCount(Dbf);
  SetLength(FieldType, N);
  for I := 0 to N-1 do
    FieldType[I] := shpapi.DBFGetFieldInfo(Dbf, I, Fname, Fwidth, Fdec);
end;

procedure LoadNodes;
//
// Load contents of a Nodes shapefile and its dBase file into the project.
//
var
  Filename:   string;
  Shp:        SHPHandle;
  ShpObj:     PShpObject;
  Dbf:        DBFHandle;
  Count:      Integer;
  I:          Integer;
  ShapeType:  Integer;
  MinBound:   array [0..3] of Double;
  MaxBound:   array [0..3] of Double;
  X, Y:       Double;
begin
  with ShpOptions do
  begin
    if Length(NodeFileName) = 0 then exit;
    Filename := ChangeFileExt(NodeFileName, '.shp');
    Count := 0;
    Shp := nil;
    Dbf := nil;

    try
      // Open the shape file and its dBase file
      Shp := shpapi.SHPOpen(PAnsiChar(Filename), 'rb');
      if Shp = nil then exit;
      Filename := ChangeFileExt(NodeFileName, '.dbf');
      if FileExists(Filename) then
        Dbf := shpapi.DBFOpen(PAnsiChar(Filename), 'rb');

      // Save field type of each dBase attribute in FieldType array
      if Dbf <> nil then GetFieldTypes(Dbf);

      // Find the number of node objects (Count) in the file
      shpapi.SHPGetInfo(Shp, Count, ShapeType, MinBound, MaxBound);

      // Add each node in the file to the project
      for I := 0 to Count-1 do
      begin
        ShpObj := shpapi.SHPReadObject(Shp, I);
        if ShpObj = nil then continue;
        X := ShpObj^.padfX[0];
        Y := ShpObj^.padfY[0];
        if NeedsProjTransform then ProjTrans.Transform(X, Y);
        shpapi.SHPDestroyObject(ShpObj);
        AddNode(Dbf, I, X, Y);
      end;

    finally
      SetLength(FieldType, 0);
      shpapi.SHPClose(Shp);
      shpapi.DBFClose(Dbf);
    end;
  end;
end;

{==================== LINK FUNCTIONS =======================================}

function GetLinkType(Dbf: DBFHandle; I: Integer): Integer;
var
  J: Integer;
  K: Integer;
  S: string;
begin
  Result := project.ltPipe;
  if Dbf <> nil then
  begin
    J := ShpOptions.LinkAttribs[lType];
    if J >= 0 then
    begin
      if FieldType[J] = FTstring then
      begin
        S := shpapi.DBFReadstringAttribute(Dbf, I, J);
        if StartsText('PUMP', S) then
          Result := project.ltPump
        else if StartsText('VALVE', S) then
          Result := project.ltValve;
      end;
      if FieldType[J] = FTInteger then
      begin
        K := shpapi.DBFReadIntegerAttribute(Dbf, I, J);
        if K = project.ltPump then
          Result := K
        else if K = project.ltValve then
          Result := K;
      end;
    end;
  end;
end;

procedure AddLinkVertices(ShpObj: PShpObject; LinkIndex: Integer);
var
  X:      array[0..Project.MAX_VERTICES] of Double;
  Y:      array[0..Project.MAX_VERTICES] of Double;
  X0:     Double;
  Y0:     Double;
  X1:     Double;
  Y1:     Double;
  P:      TDoublePoint;
  J:      Integer;
  N:      Integer;
  Vcount: Integer;
begin
  N := Min(ShpObj^.nVertices, project.MAX_VERTICES);
  Vcount := 0;
  if N >= 3 then
  begin
    // Save the starting vertex coordinates
    X0 := ShpObj^.padfX[0];
    Y0 := ShpObj^.padfY[0];

    // Visit each vertex in the shape object (not including the ending one)
    for J := 1 to N-2 do
    begin
      // Retrieve the vertex coordinates from the shape object
      X1 := ShpObj^.padfX[J];
      Y1 := ShpObj^.padfY[J];

      // Check that this vertex doesn't lay on top of the previous one
      if (X1 = X0)
      or (Y1 = Y0) then
        continue;

      // Store the vertex's coordinates in the local arrays
      P := DoublePoint(X1, Y1);
      if NeedsProjTransform then ProjTrans.Transform(P.X, P.Y);
      X[Vcount] := P.X;
      Y[Vcount] := P.Y;
      Inc(Vcount);

      // Replace the previous vertex coordinates
      X0 := X1;
      Y0 := Y1;
    end;

    // Transfer the locally stored vertices to those for link LinkIndex
    if Vcount > 0 then
      epanet2.ENsetvertices(LinkIndex, X[0], Y[0], Vcount);
  end;
end;

function GetLinkValue(Dbf: DBFHandle; I: Integer; J: Integer): Single;
var
  V: Double = 0;
begin
  GetNumericalAttrib(Dbf, I, ShpOptions.LinkAttribs[J], V);
  Result := V;
end;

function LinkUcf(Attrib: Integer): Double;
//
// Compute a units conversion factor for an imported link attribute.
//
var
  V: Single = 0;
  S: string;
begin
  Result := 1;
  S := ShpOptions.LinkUnits[Attrib];
  if Length(S) = 0 then exit;

  // Unit conversion factor for length
  if Attrib = lLength then
  begin
    if SameText(S, 'METERS') and
    (project.GetUnitsSystem = usUS) then
      Result := 3.28084
    else if SameText(S, 'FEET')
    and (project.GetUnitsSystem = usSI) then
      Result := 1 / 3.28084;
  end;

  // Unit conversion factor for diameter
  if Attrib = lDiam then
  begin
    if SameText(S, 'MILLIMETERS')
    and (project.GetUnitsSystem = usUS) then
      Result := 0.03937
    else if SameText(S, 'INCHES')
    and (project.GetUnitsSystem = usSI) then
      Result := 25.4;
  end;

  // Unit conversion factor for D-W roughness
  if Attrib = lRough then
  begin
    epanet2.ENgetoption(EN_HEADLOSSFORM, V);
    if Round(V) = EN_DW then
    begin
      if SameText(S, 'MILLIMETERS')
      and (project.GetUnitsSystem = usUS) then
        Result := 39.37
      else if SameText(S, 'INCHES')
      and (project.GetUnitsSystem = usSI) then
        Result := 25.4
    end;
  end;
end;

procedure SetLinkProps(Dbf: DBFHandle; I: Integer; LinkType: Integer; LinkIndex: Integer);
//
// Set the properties of a link of type LinkType with index LinkIndex to the
// corresponding attributes stored in the I-th record of the dBase file.
//
var
  V:         Single;
  Len:       Single = 10;
  Diameter:  Single = 10;
  Roughness: Single = 0;
  S:         string = '';
begin
  // Only pipe links have assigned properties
  if LinkType <> ltPipe then exit;

  // Set link description
  GetstringAttrib(Dbf, I, ShpOptions.LinkAttribs[lDescrip], S);
  if Length(S) > 0 then epanet2.ENsetcomment(EN_Link, LinkIndex, PAnsiChar(S));

  // Get current pipe length
  epanet2.ENgetlinkvalue(LinkIndex, EN_LENGTH, Len);

  // Override default length if supplied in dBse file
  if ShpOptions.LinkAttribs[lLength] >= 0 then
  begin
    V := GetLinkValue(Dbf, I, lLength) * LinkUcf(lLength);
    if V > 0 then Len := V;
  end

  // Or compute it if that option was selected
  else if project.AutoLength
  or ShpOptions.ComputeLengths then
  begin
    V := project.FindLinkLength(LinkIndex) * LinkUcf(llength);
    if V > 0 then Len := V;
  end;

  // Retrieve pipe diameter
  ENgetlinkvalue(LinkIndex, EN_DIAMETER, Diameter);
  if ShpOptions.LinkAttribs[lDiam] >= 0 then
  begin
    V := GetLinkValue(Dbf, I, lDiam) * LinkUcf(lDiam);
    if V > 0 then Diameter := V;
  end;

  // Retrieve pipe roughness
  ENgetlinkvalue(LinkIndex, EN_ROUGHNESS, Roughness);
  if ShpOptions.LinkAttribs[lRough] >= 0 then
  begin
    V := GetLinkValue(Dbf, I, lRough) * LinkUcf(lRough);
    if V > 0 then Roughness := V;
  end;

  // Assign properties to the pipe (last argument is for minor loss coeff.)
  epanet2.ENsetpipedata(LinkIndex, Len, Diameter, Roughness, 0.0);
end;

function GetNearestNode(P: TDoublePoint): Integer;
//
//  Find the index of the project node closest to point P that is
//  within the snap tolerance. Return 0 if there is no such node.
//
var
  J:     Integer;
  Jmin:  Integer;
  D:     Double;
  Dmin:  Double;
  Pj:    TDoublePoint = (X: 0; Y: 0);
begin
  Jmin := 0;
  Dmin := 1.0e40;

  // Convert X,Y in degrees to meters
  if HasDegreesUnits then
    P := mapcoords.FromWGS84ToWebMercator(P);

  // Examine each project node
  for J := 1 to project.GetItemCount(ctNodes) do
  begin

    // Find Manhattan distance between point P and the node
    if not project.GetNodeCoord(J, Pj.X, Pj.Y) then continue;
    if HasDegreesUnits then
      Pj := mapcoords.FromWGS84ToWebMercator(Pj);
    D := mapcoords.ManhattanDistance(P, Pj);

    // Update minimum distance found
    if D < Dmin then
    begin
      Dmin := D;
      Jmin := J;
    end;
  end;

  // Check that minimum distance is within snap tolerance
  if Dmin * SnapUcf <= SnapTol then
    Result := Jmin
  else
    Result := 0;
end;

function GetEndNode(Dbf: DBFHandle; P: TDoublePoint; I: Integer;
  WhichEnd: Integer): string;
//
// Get the name of a node at one end of the I-th link read from a shape file.
//
var
  J: Integer;
begin
  // See if project already contains link's end node name
  Result := '';
  if Dbf <> nil then
  begin
    // Retrieve node name from links dBase file
    J := ShpOptions.LinkAttribs[WhichEnd];
    if J >= 0 then Result := GetID(Dbf, I, J);

    // Check that node name appears in the project
    if epanet2.ENgetnodeindex(PAnsiChar(Result), J) > 0 then Result := '';
  end;

  // Link's end node not already in project
  if Length(Result) = 0 then
  begin
    if NeedsProjTransform then
      ProjTrans.Transform(P.X, P.Y);

    // See if link's node is within snap tolerance of an existing node
    J := GetNearestNode(P);
    if J > 0 then
      Result := project.GetID(ctNodes, J)

    // Otherwise add a new node and return its assigned name
    else
    begin
      J := AddNode(Nil, I, P.X, P.Y);
      if J > 0 then
        Result := project.GetID(ctNodes, J);
    end;
  end;
end;

function GetLinkID(Dbf: DBFHandle; LinkType: Integer; I: Integer;
  var Index: Integer): string;
var
  J:  Integer;
  ID: string;
begin
  // Try reading ID from dBase file
  ID := '';
  Index := 0;
  if Dbf <> nil then
  begin
    J := ShpOptions.LinkAttribs[lID];
    if J >= 0 then ID := GetID(Dbf, I, J);
  end;

  // Check if ID used by another link
  if Length(ID) > 0 then
  begin
    epanet2.ENgetlinkindex(PAnsiChar(ID), Index);
  end
  else
    ID := projectbuilder.FindUnusedID(ctLinks, LinkType);
  Result := ID;
end;

procedure AddLink(ShpObj: PShpObject; Dbf: DBFHandle; I: Integer);
var
  StartNode:   string;
  EndNode:     string;
  LinkID:      string;
  LinkIndex:   Integer = 0;
  LinkType:    Integer;
  N:           Integer;
  P:           mapcoords.TDoublePoint;
begin
  N := ShpObj^.nVertices;
  if N < 2 then exit;
  LinkType := GetLinkType(Dbf, I);
  // Valve type assumed to be Throttle Control Valve (TCV)
  if LinkType = ltValve then LinkType := EN_TCV;
  LinkID := GetLinkID(Dbf, LinkType, I, LinkIndex);

  // If link doesn't exist then create it
  if LinkIndex = 0 then
  begin
    // Find start node of the link
    P.X := ShpObj^.padfX[0];
    P.Y := ShpObj^.padfY[0];
    StartNode := GetEndNode(Dbf, P, I, lStartNode);
    if Length(StartNode) = 0 then exit;

    // Find end node of the link
    P.X := ShpObj^.padfX[N-1];
    P.Y := ShpObj^.padfY[N-1];
    EndNode := GetEndNode(Dbf, P, I, lEndNode);
    if Length(EndNode) = 0 then exit;

    // Add the link to the project
    if epanet2.ENaddlink(Pchar(LinkID), LinkType, PChar(StartNode),
      PChar(EndNode), LinkIndex) > 0 then exit;
    ENsetpipedata(LinkIndex,
      StrToFloatDef(project.DefProps[4], 0.0),
      StrToFloatDef(project.DefProps[5], 0.0),
      StrToFloatDef(project.DefProps[6], 0.0), 0.0);
  end;

  // Assign properties and vertices to the link
  if LinkIndex > 0 then
  begin
    SetLinkProps(Dbf, I, LinkType, LinkIndex);
    AddLinkVertices(ShpObj, LinkIndex);
  end;
end;

procedure LoadLinks;
//
// Load contents of a Links shapefile and its dBase file into the project.
//
var
  Filename:    string;
  Shp:         SHPHandle;
  ShpObj:      PShpObject;
  Dbf:         DBFHandle;
  Count:       Integer;
  I:           Integer;
  ShapeType:   Integer;
  MinBound:    array [0..3] of Double;
  MaxBound:    array [0..3] of Double;
begin
  with ShpOptions do
  begin
    if Length(LinkFileName) = 0 then exit;
    Filename := ChangeFileExt(LinkFileName, '.shp');
    Count := 0;
    Shp := nil;
    Dbf := nil;
    try

      // Open the shapefile and its dBase file
      Shp := shpapi.SHPOpen(PAnsiChar(FileName), 'rb');
      if Shp = nil then exit;
      Filename := ChangeFileExt(LinkFileName, '.dbf');
      if FileExists(Filename) then
        Dbf := shpapi.DBFOpen(PAnsiChar(Filename), 'rb');

      // Save field type of each dBase attribute to FieldType array
      if Dbf <> nil then GetFieldTypes(Dbf);

      // Find the number of link objects (Count) in the file
      shpapi.SHPGetInfo(Shp, Count, ShapeType, MinBound, MaxBound);

      // Add each link in the file to the project
      for I := 0 to Count-1 do
      begin
        ShpObj := shpapi.SHPReadObject(Shp, I);
        if ShpObj = nil then continue;
        AddLink(ShpObj, Dbf, I);
        shpapi.SHPDestroyObject(ShpObj);
      end;

    finally
      SetLength(FieldType, 0);
      shpapi.SHPClose(Shp);
      shpapi.DBFClose(Dbf);
    end;
  end;
end;

procedure SetSnapParams;
var
  MapUnits: Integer;
begin
  SnapTol := ShpOptions.SnapTol + 0.0001;
  if ShpOptions.SnapUnits = muFeet then
    SnapTol := SnapTol * 0.3048;

  if NeedsProjTransform then
    MapUnits := project.MapUnits
  else
    MapUnits := ShpOptions.CoordUnits;

  SnapUcf := 1;
  HasDegreesUnits := false;
  if MapUnits = muFeet then
    SnapUcf := 0.3048
  else if MapUnits = muDegrees then
    HasDegreesUnits := true;
end;

function SetNeedsProjTransform: Boolean;
//
//  Check if shapefile coordinates need to be transformed to project
//  coordinates
//
var
  Extent: TDoubleRect;
begin
  Result := true;
  NeedsProjTransform := false;

  // Importing to an empty project -- no transform needed
  if project.IsEmpty then
  begin
    project.MapUnits := ShpOptions.CoordUnits;
    project.MapEPSG:= ShpOptions.Epsg;
    exit;
  end;

  // Set source & destination projection EPSGs
  SrcEpsg := ShpOptions.Epsg;
  DstEpsg := project.MapEpsg;
  if project.MapUnits = muDegrees then
    DstEpsg := 4036;

  // Check if projection transform not needed
  if SrcEpsg = DstEpsg then exit;

  // Check if projection transform can be made
  if (SrcEpsg > 0) and (DstEpsg > 0) then
  begin
    Extent := MainForm.MapFrame.Map.Extent;
    Result := CanProjectionTransform(
      IntToStr(SrcEpsg), IntToStr(DstEpsg), Extent);
  end
  else if (SrcEpsg > 0) or (DstEpsg > 0) then
    Result := false
  else
    exit;
  NeedsProjTransform := Result;

  // Display message if can't transform
  if Result = false then
    utils.MsgDlg(rsTransFail, rsNoShpTrans, mtInformation, [mbOk], MainForm);
end;

function LoadShapeFile(theShpOptions: TShpOptions): Boolean;
begin
  // See if coordinates need to be transformed
  Result := false;
  ShpOptions := theShpOptions;
  if SetNeedsProjTransform = false then exit;

  // Set parameters used with snap tolerance bewteen nodes
  SetSnapParams;

  ProjTrans := TProjTransform.Create;
  try
    // Set the projections required for coordinate transform
    if NeedsProjTransform then
      ProjTrans.SetProjections(IntToStr(SrcEPSG), IntToStr(DstEpsg));

    // Load contents of node & link shapefiles into project
    LoadNodes;
    LoadLinks;

    // Display the network map
    MainForm.MapFrame.SetExtent(MapCoords.GetBounds(MainForm.MapFrame.GetExtent));
    MainForm.MapFrame.DrawFullextent;

    // Update project's status
    project.HasChanged := true;
    project.UpdateResultsStatus;
    Result := true;

  finally
    ProjTrans.Free;
  end;
end;

end.
