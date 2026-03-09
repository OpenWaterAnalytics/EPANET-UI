{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       csvloader
 Description:  loads the contents of a CSV text file into a project
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit csvloader;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, StrUtils;

const
  nID        = 1;
  nXcoord    = 2;
  nYcoord    = 3;
  nDescrip   = 4;
  nTag       = 5;
  nElev      = 6;
  nDemand    = 7;
  nEmitter   = 8;
  nQuality   = 9;
  nNodeProps = 9;

  pID        = 1;
  pStartNode = 2;
  pEndNode   = 3;
  pDescrip   = 4;
  pTag       = 5;
  pLength    = 6;
  pDiam      = 7;
  pRough     = 8;
  pCloss     = 9;
  pCbulk     = 10;
  pCwall     = 11;
  pAleak     = 12;
  pEleak     = 13;
  nPipeProps = 13;

type
  TCsvOptions = record
    NodeFileName:     string;
    PipeFileName:     string;
    NodeAttribs:      array[1..nNodeProps] of Integer;
    NodeUnits:        array[1..nNodeProps] of string;
    PipeAttribs:      array[1..nPipeProps] of Integer;
    PipeUnits:        array[1..nPipeProps] of string;
    CoordUnits:       Integer;
    HasCoordinates:   Boolean;
  end;

var
  CsvOptions: TCsvOptions;

procedure LoadCsvFile(theCsvOptions: TCsvOptions);

implementation

uses
  main, mapcoords, project, projectbuilder, epanet2;

const
  FlowPerCFS: array[0..10] of Single =
    (1.0, 448.831, 0.64632, 0.5382, 1.9837,  {CFS, GPM, MGD, IMGD, AFD per CFS}
     28.317, 1699.0, 2.4466, 101.94, 2446.6, {LPS, LPM, MLD, CMH, CMD per CFS}
     0.028317); {CMS per CFS}

var
  NodeUcf: array[1..nNodeProps] of Single;   //Node units conversion factors
  PipeUcf: array[1..nPipeProps] of Single;   //Pipe units conversion factors

procedure SetNodeUcfs(CsvOptions: TCsvOptions);
//
// Assign units conversion factors for node attributes.
//
var
  Units: string;
  I:     Integer;
  J1:    Integer;
  J2:    Integer = 0;
begin
  // Initialize all Ucfs
  for I := Low(NodeUcf) to High(NodeUcf) do NodeUcf[I] := 1.0;

  // Examine each node attribute
  for I := Low(CsvOptions.NodeAttribs) to High(CsvOptions.NodeAttribs) do
  begin
    // Units that the user specified for attribute I
    Units := CsvOptions.NodeUnits[I];
    if Length(Units) = 0 then continue;

    // Conversion factor for Elevation
    if I = nElev then
    begin
      if SameText(Units, 'METERS')
      and (project.GetUnitsSystem = usUS) then
        NodeUcf[I] := 3.28084
      else if SameText(Units, 'FEET')
      and (project.GetUnitsSystem = usSI) then
        NodeUcf[I] := 1 / 3.28084;
    end;

    // Conversion factor for Base Demand
    if I = nDemand then
    begin
      J1 := AnsiIndexText(Units, project.FlowUnitsStr); //Attrib flow units index
      epanet2.ENgetflowunits(J2);                       //Project flow units index
      if J1 >= 0 then
        NodeUcf[I] := FlowPerCFS[J2] / FlowPerCFS[J1];
    end;

    // Conversion factor for Emitter Coeff.
    if I = nEmitter then
    begin
      epanet2.ENgetflowunits(J2);
      if SameText(Units, 'gpm/psi') then
      begin
        NodeUcf[I] := FlowPerCfs[J2] / FlowPerCfs[1];  //Convert from gpm
        if project.GetUnitsSystem = usSI then
          NodeUcf[I] := NodeUcf[I] / 1.42;             //Convert 1/psi to 1/m
      end
      else if SameText(Units, 'lps/m') then
      begin
        NodeUcf[I] := FlowPerCfs[J2] / FlowPerCfs[5];  //Convert from lps
        if project.GetUnitsSystem = usUS then
          NodeUcf[I] := NodeUcf[I] * 1.42;             //Convert 1/m to 1/psi
      end;
    end;
  end;
end;

procedure SetPipeUcfs(CsvOptions: TCsvOptions);
//
// Assign units conversion factors for pipe attributes.
//
var
  Units:      string;
  I:          Integer;
  HlossModel: Single = 0;
begin
  // Initialize all Ucfs
  for I := Low(PipeUcf) to High(PipeUcf) do PipeUcf[I] := 1.0;

  // Examine each pipe attribute
  for I := Low(CsvOptions.PipeAttribs) to High(CsvOptions.PipeAttribs) do
  begin
    // Units that the user specified for attribute I
    Units := CsvOptions.PipeUnits[I];
    if Length(Units) = 0 then continue;

    // Conversion factor for Length
    if I = pLength then
    begin
      if SameText(Units, 'METERS')
      and (project.GetUnitsSystem = usUS) then
        PipeUcf[I] := 3.28084
      else if SameText(Units, 'FEET')
      and (project.GetUnitsSystem = usSI) then
        PipeUcf[I] := 1 / 3.28084;
    end;

    // Conversion factor for Diameter
    if I = pDiam then
    begin
      if SameText(Units, 'MILLIMETERS')
      and (project.GetUnitsSystem = usUS) then
        PipeUcf[I] := 1/25.4
      else if SameText(Units, 'INCHES')
      and (project.GetUnitsSystem = usSI) then
        PipeUcf[I] := 25.4;
    end;

    // Conversion factor for D-W roughness height
    if I = pRough then
    begin
      ENgetoption(EN_HEADLOSSFORM, HlossModel);
      if round(HlossModel) = EN_DW then
      begin
        if SameText(Units, 'MILLIMETERS')
        and (project.GetUnitsSystem = usUS) then
          PipeUcf[I] := 3.28
        else if SameText(Units, 'MILLIFEET')
        and (project.GetUnitsSystem = usSI) then
          PipeUcf[I] := 1/3.28;
      end;
    end;

    // Conversion factor for water quality reaction rate coeffs.
    if (I = pCbulk)
    or (I = pCwall) then
    begin
      if SameText(Units, '1/hrs') then PipeUcf[I] := 24;
    end;
  end;
end;

procedure SetNodeProps(Fields: TStringList; NodeIndex: Integer);
var
  I: Integer;
  J: Integer;
  S: string;
  V: Single = 0;
begin
  // Examine each node property
  for I := nDescrip to nQuality do
  begin
    // J is the column in the CSV file containing the property
    J := CsvOptions.NodeAttribs[I];
    if J < 0 then continue;

    // Convert the file's string entry to a numerical value for
    // for numerical properties
    S := Fields[J];
    if I >= nElev then
    begin
      if not TryStrToFloat(S, V) then continue;
      V := V * NodeUcf[I];
    end;

    // Assign the property value to the node
    case I of
      nDescrip:
        ENsetcomment(EN_NODE, NodeIndex, PChar(S));
      nTag:
        ENsettag(EN_NODE, NodeIndex, PChar(S));
      nElev:
        ENsetnodevalue(NodeIndex, EN_ELEVATION, V);
      nDemand:
        ENsetnodevalue(NodeIndex, EN_BASEDEMAND, V);
      nEmitter:
        ENsetnodevalue(NodeIndex, EN_EMITTER, V);
      nQuality:
        ENsetnodevalue(NodeIndex, EN_INITQUAL, V);
    end;
  end;
end;

procedure SetPipeProps(Fields: TStringList; PipeIndex: Integer);
var
  I: Integer;
  J: Integer;
  S: string;
  V: Single = 0;
begin
  // Examine each pipe property
  for I := pDescrip to pEleak do
  begin
    // J is the column in the CSV file containing the property
    J := CsvOptions.PipeAttribs[I];
    if J < 0 then continue;

    // Convert the file's string entry to a numerical value for
    // for numerical properties
    S := Fields[J];
    if I >= pLength then
    begin
      if not TryStrToFloat(S, V) then continue;
      V := V * PipeUcf[I];
    end;

    // Assign the property value to the pipe
    case I of
      pDescrip:
        ENsetcomment(EN_LINK, PipeIndex, PChar(S));
      pTag:
        ENsettag(EN_LINK, PipeIndex, PChar(S));
      pLength:
        if V > 0 then ENsetlinkvalue(PipeIndex, EN_LENGTH, V);
      pDiam:
        if V > 0 then ENsetlinkvalue(PipeIndex, EN_DIAMETER, V);
      pRough:
        if V > 0 then ENsetlinkvalue(PipeIndex, EN_ROUGHNESS, V);
      pCloss:
        if V >= 0 then ENsetlinkvalue(PipeIndex, EN_MINORLOSS, V);
      pCbulk:
        ENsetlinkvalue(PipeIndex, EN_KBULK, V);
      pCwall:
        ENsetlinkvalue(PipeIndex, EN_KWALL, V);
      pAleak:
        if V >= 0 then ENsetlinkvalue(PipeIndex, EN_LEAK_AREA, V);
      pEleak:
        if V >= 0 then ENsetlinkvalue(PipeIndex, EN_LEAK_EXPAN, V);
    end;
  end;
end;

procedure AddNode(Fields: TStringList);
var
  NodeIndex: Integer;
  IdIndex:   Integer;
  Xindex:    Integer;
  Yindex:    Integer;
  X:         Double = 0;
  Y:         Double = 0;
  Id:        string;
  HasCoords: Boolean;
begin
  // Get indexes of node ID and coords. in Fields list
  IdIndex := CsvOptions.NodeAttribs[nID];
  Xindex := CsvOptions.NodeAttribs[nXcoord];
  Yindex := CsvOptions.NodeAttribs[nYcoord];

  // Get node ID
  Id := '';
  if IdIndex >= 0 then Id := Fields[IdIndex];

  // Get node coords.
  HasCoords := false;
  if (Xindex >= 0) and (Yindex >= 0) then
  begin
    if (tryStrToFloat(Fields[Xindex], X) = true)
    and (tryStrToFloat(Fields[Yindex], Y) = true) then
      HasCoords := true;
  end;

  // Get node's index if already in project
  NodeIndex := 0;
  if Length(ID) > 0 then
    epanet2.ENgetnodeindex(PChar(ID), NodeIndex)

  // Or assign it a default ID if it has coords.
  else if HasCoords then
    ID := projectbuilder.FindUnusedID(ctNodes, ntJunction);

  // Add new node if ID not in project and it has coords.
  if (NodeIndex = 0) then
  begin
    if HasCoords then
    begin
      if epanet2.ENaddnode(PChar(ID), ntJunction, NodeIndex) = 0 then
        epanet2.ENsetnodevalue(NodeIndex, EN_ELEVATION,
          StrToFloatDef(project.DefProps[1], 0))
      else
        exit;
    end;
  end;

  // Assign node properties contained in the Fields list
  if HasCoords then epanet2.ENsetcoord(NodeIndex, X, Y);
  SetNodeProps(Fields, NodeIndex);
end;

procedure AddPipe(Fields: TStringList);
var
  PipeIndex:  Integer;
  IdIndex:    Integer;
  Node1Index: Integer;
  Node2Index: Integer;
  Id:         string;
  Node1:      string = '';
  Node2:      string = '';
  HasNodes:   Boolean;
begin
  // Get indexes of pipe ID and start/end nodes in Fields list
  IdIndex := CsvOptions.PipeAttribs[pID];
  Node1Index := CsvOptions.PipeAttribs[pStartNode];
  Node2Index := CsvOptions.PipeAttribs[pEndNode];

  // Get pipe ID
  Id := '';
  if IdIndex >= 0 then Id := Fields[IdIndex];

  // Get indexes of pipe's start and end nodes in project
  HasNodes := false;
  if (Node1Index >= 0)
  and (Node2Index >= 0) then
  begin
    Node1 := Fields[Node1Index];
    Node2 := Fields[Node2Index];
    if (ENgetnodeindex(PChar(Node1), Node1Index) = 0)
    and (ENgetnodeindex(PChar(Node2), Node2Index) = 0) then
      HasNodes := true;
  end;

  // Get pipe's index if already in project
  PipeIndex := 0;
  if Length(ID) > 0 then
    epanet2.ENgetlinkindex(PChar(ID), PipeIndex)

  // Or assign it a default ID if it has end nodes
  else if HasNodes then
    ID := projectbuilder.FindUnusedID(ctLinks, ltPipe)
  else
    exit;

  // Pipe has end nodes
  if HasNodes then
  begin
    // Add it to project if it doesn't already exist
    if (PipeIndex = 0) then
    begin
      if epanet2.ENaddlink(Pchar(ID), ltPipe, PChar(Node1), PChar(Node2),
        PipeIndex) <> 0 then exit;
    end
    // Or simply update its end nodes if it exists
    else
      epanet2.ENsetlinknodes(PipeIndex, Node1Index, Node2Index);
  end;

  // Assign pipe properties contained in the Fields list
  SetPipeProps(Fields, PipeIndex);
end;

procedure LoadNodes;
//
// Load contents of a Nodes CSV file into the project.
//
var
  Filename: string;
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  with CsvOptions do
  begin
    if Length(NodeFileName) = 0 then exit;
    Filename := ChangeFileExt(NodeFileName, '.csv');
  end;
  Fields := TStringList.Create;
  AssignFile(F, Filename);
  try
    Fields.Delimiter := ',';

    // Skip 1st line containing field names
    Reset(F);
    Readln(F, Line);

    // Read remaining lines
    while not eof(F) do
    begin
      Readln(F, Line);
      Fields.DelimitedText := Line;
      AddNode(Fields);
    end;

  finally
    CloseFile(F);
    Fields.Free;
  end;
end;

procedure LoadPipes;
//
// Load contents of a Pipes CSV file into the project.
//
var
  Filename: string;
  F: TextFile;
  Line: string;
  Fields: TStringList;
begin
  with CsvOptions do
  begin
    if Length(PipeFileName) = 0 then exit;
    Filename := ChangeFileExt(PipeFileName, '.csv');
  end;
  Fields := TStringList.Create;
  AssignFile(F, Filename);
  try
    Fields.Delimiter := ',';

    // Skip 1st line containing field names
    Reset(F);
    Readln(F, Line);

    // Read remaining lines
    while not eof(F) do
    begin
      Readln(F, Line);
      Fields.DelimitedText := Line;
      AddPipe(Fields);
    end;

  finally
    CloseFile(F);
    Fields.Free;
  end;
end;

procedure LoadCsvFile(theCsvOptions: TCsvOptions);
//
// Load node and link data from CSV files into the current project.
//
begin
  CsvOptions := theCsvOptions;
  SetNodeUcfs(theCsvOptions);
  SetPipeUcfs(theCsvOptions);
  LoadNodes;
  LoadPipes;
  MainForm.MapFrame.SetExtent(MapCoords.GetBounds(MainForm.MapFrame.GetExtent));
  MainForm.MapFrame.DrawFullextent;
  project.HasChanged := true;
  project.UpdateResultsStatus;
end;

end.

