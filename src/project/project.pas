{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       project
 Description:  sets, saves and retrieves project data
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

{
  Pipe network data is stored and accessed using the EPANET Toolkit
  API.
}

unit project;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, StrUtils, FileUtil, resourcestrings;

{$I ..\timetype.txt}

type
  TSimStatus = (ssSuccess, ssWarning, ssError, ssWrongVersion,
                ssFailed, ssShutdown, ssCancelled, ssNone);

const
  FlowUnitsStr: array[0..10] of string =
    (rsCFS, rsGPM, rsMGD, rsIMGD, rsAFD,
     rsLPS, rsLPM, rsMLD, rsCMH, rsCMD, rsCMS);

  FlowUcf: array[0..10] of Double =
    (1.0,         // CFS
     448.831,     // GPMperCFS
     0.64632,     // MGDperCFS
     0.5382,      // IMGDperCFS
     1.9837,      // AFDperCFS
     28.317,      // LPSperCFS
     1699.0,      // LPMperCFS
     2.4466,      // MLDperCFS
     101.94,      // CMHperCFS
     2446.6,      // CMDperCFS
     0.028317);   // CMSperCFS

  PressUnitsStr: array[0..4] of string =
    (rsPsi, rsKpa, rsMeters, rsBar, rsFeet);

  HlossModelStr: array[0..2] of string =
    (rsHW, rsDW, rsCM);

  DemandModelStr: array[0..1] of string =
    (rsDDA, rsPDA);

  QualModelStr: array[0..3] of string =
    (rsNoQuality, rsChemical, rsWaterAge, rsSourceTrace);

  MixingModelStr: array[0..3] of string =
    ('Mixed', '2Comp', 'FIFO', 'LIFO');

  MassUnitsStr: array[0..1] of string = ('mg/L', 'ug/L');

  MapUnitsStr: array[0..3] of string = (rsFeet, rsMeters, rsDegrees, rsNone);

  OptionsStr: array[0..4] of string =
    (rsHydraulics, rsDemands, rsQuality, rsTimes, rsEnergy);

  ControlsStr: array[0..1] of string =
    (rsSimple, rsRuleBased);

  StatusStr: array[0..2] of string =
    (rsClosed, rsOpen, 'CV');

  ValveTypeStr: array[0..6] of string =
    ('PRV', 'PSV', 'PBV', 'FCV', 'TCV', 'GPV', 'PCV');

  ValveStatusStr: array[0..2] of string =
    (rsClosed, rsOpen, rsNone);

  CurveTypeStr: array[0..5] of string =
    (rsVolume, rsPump, rsEfficiency, rsHeadLoss, rsGeneric, rsValve);

  StatusRptStr: array[0..2] of string =
    (rsNone, rsNormal, rsFull);

  StatisticStr: array[0..4] of string =
    (rsNone, rsAverages, rsMinima, rsMaxima, rsRanges);
    
  NoYesStr: array[0..1] of string = (rsNo, rsYes);

  // Object category types
  ctTitle    = 0;
  ctOptions  = 1;
  ctNodes    = 2;
  ctLinks    = 3;
  ctControls = 4;
  ctLabels   = 5;
  ctPatterns = 6;
  ctCurves   = 7;
  ctSystem   = 8;

  // Option types
  otHydraul = 0;
  otDemands = 1;
  otQuality = 2;
  otTimes   = 3;
  otEnergy  = 4;

  // Node types
  ntJunction  = 0;
  ntReservoir = 1;
  ntTank      = 2;

  // Link types
  ltCVPipe    = 0;
  ltPipe      = 1;
  ltPump      = 2;
  ltValve     = 3;

  // Curve types
  ctVolume   = 0;
  ctPump     = 1;
  ctEffic    = 2;
  ctHloss    = 3;
  ctGeneric  = 4;
  ctValve    = 5;

  // Head loss model types
  htHW       = 0;  // Hazen-Williams
  htDW       = 1;  // Darcy-Weisbach
  htCM       = 2;  // Chezy-Manning

  // Hydraulic option types
  htFlowUnits  = 1;
  htPressUnits = 2;
  htHlossModel = 3;
  htSpGravity  = 4;
  htSpViscos   = 5;
  htMaxTrials  = 6;
  htAccuracy   = 7;
  htHeadTol    = 8;
  htFlowTol    = 9;

  // Default property types
  ptNodeElev  = 1;
  ptTankHt    = 2;
  ptTankDiam  = 3;
  ptPipeLen   = 4;
  ptPipeDiam  = 5;
  ptPipeRough = 6;

  // Single species quality
  qtNone     = 0;
  qtChem     = 1;
  qtAge      = 2;
  qtTrace    = 3;

  //Quality models
  qmNone     = 0;
  qmSingle   = 1;
  qmMulti    = 2;

  //Map coordinates units
  muFeet     = 0;
  muMeters   = 1;
  muDegrees  = 2;
  muNone     = 3;

  //Unit system
  usUS       = 0;
  usSI       = 1;

  //Results status
  rsNotAvailable  = 0;
  rsUpToDate      = 1;
  rsNeedsUpdating = 2;

  //Results types
  rtNone   = 0;
  rtMinima = 1;
  rtMaxima = 2;
  rtRanges = 3;

  MAX_VERTICES = 100;    // Maximum vertices per link
  MAX_ID_PREFIXES = 8;   // Objects with ID prefixes
  MAX_DEF_OPTIONS = 9;   // Default hydraulic options
  MAX_DEF_PROPS = 6;     // Default node/link properties

type
  TIDprefix =   array[1..MAX_ID_PREFIXES] of string;
  TDefOptions = array[1..MAX_DEF_OPTIONS] of string;
  TDefProps =   array[1..MAX_DEF_PROPS] of string;

var
  InpFile:    string;        // Name of input file
  RptFile:    string;        // Name of report file
  OutFile:    string;        // Name of binary output file
  OutFile2:   string;        // Name of second binary output file
  AuxFile:    string;        // Name of a temporary auxilary file
  MsxInpFile: string;        // Name of MSX input file
  MsxOutFile: string;        // Name of temporary MSX output file
  MsxHydFile: string;        // Name of temporary MSX hydraulics file

  FlowUnits:     Integer;    // Units code of all flow rates
  PressUnits:    Integer;    // Units code of node pressure
  MapUnits:      Integer;    // Units code of map coordinates
  MapEPSG:       Integer;    // Current map EPSG code
  StatusRptType: Integer;    // Type of status report to produce
  ResultsStatus: Integer;    // Status of most current results
  StartTime:     Integer;    // Simulation start time of day (sec)

  SimStatus:        TSimStatus;  // Status of a simulation run
  MapLabels:        TStringList; // List of map label objects
  Properties:       TStringList; // List of an object's properties
  CopiedProperties: TStringList; // List of copied object's properties

  HasChanged:     Boolean;   // True if project data have changed
  AutoLength:     Boolean;   // True if pipe lengths found from map
  HasResults:     Boolean;   // True if simulation results available
  OutFileOpened:  Boolean;   // True if simulation output file is open
  OutFile2Opened: Boolean;   // True if demand output file is open
  MsxFileOpened:  Boolean;   // True if multi-species output file is open
  MsxFlag:        Boolean;   // True for multi-species analysis

  IDprefix:    TIDprefix;    // Prefixes for object ID names
  DefOptions:  TDefOptions;  // Default hydraulic options
  DefProps:    TDefProps;    // Default object property values

procedure Open;
procedure Init;
procedure Clear;
procedure Close;

{**********************************************************************
 NOTE: An 'Item' argument indexes items in the network data base
       starting from 0 while an 'Index' argument indexes them starting
       from 1 which is the convention used in the EPANET API functions.
***********************************************************************}

function  GetItemID(Category: Integer; Item: Integer): string;
function  GetItemTypeStr(Category: Integer; Item: Integer): string;
function  GetItemIndex(Category: Integer; ID: String): Integer;
function  GetItemCount(Category: Integer): Integer;
function  IsEmpty: Boolean;

function  GetTitle(Item: Integer): string;
function  GetID(Category: Integer; Index: Integer): string;
function  GetIdError(Category: Integer; ID: string): string;
function  GetComment(Category: Integer; Index: Integer): string;
function  GetTag(Category: Integer; Index: Integer): string;

function  GetNodeType(Index: Integer): Integer;
function  GetLinkType(Index: Integer): Integer;
function  GetLinkNodes(Link: Integer; var Node1, Node2: Integer): Boolean;
function  FindLinkLength(LinkIndex: Integer): Single;
procedure AdjustLinkLengths(NodeIndex: Integer);
procedure SetPipeLength(PipeIndex: Integer);
procedure ReverseLinkNodes(Link: Integer);
procedure SetFlowUnits(Units: string);
procedure SetPressUnits(Units: string);
procedure SetDemandModel(NewModel: Integer);

function  GetPatternNames: string;
function  GetCurveNames(aCurveType: Integer): string;
function  GetCurveType(CurveIndex: Integer): Integer;

function  GetNodeParam(NodeIndex: Integer; Param: Integer): Single;
function  GetLinkParam(LinkIndex: Integer; Param: Integer): Single;
function  GetSourceQual(NodeIndex: Integer): Single;
function  GetPumpResultsCount: Integer;
function  GetUnitsSystem: Integer;
function  GetResultIndex(Category: Integer; Index: Integer): Integer;
function  GetStatisticsType: Integer;
function  GetHlossModelStr: string;
function  GetDemandModelStr: string;
function  GetQualModelStr: string;
function  GetObjectStr(Category: Integer; Item: Integer): string;

function  GetNodeCoord(NodeIndex: Integer; var X, Y: Double): Boolean;
procedure SetNodeCoord(NodeIndex: Integer; X: Double; Y: Double);
function  GetLinkCoord(LinkIndex: Integer; var X, Y: Double): Boolean;
function  GetLabelCoord(LabelIndex: Integer; var X, Y: Double): Boolean;
procedure SetLabelCoord(LabelIndex: Integer; X: Double; Y: Double);
function  GetVertexCoord(LinkIndex: Integer; Vertex: Integer; var X, Y: Double):
          Boolean;
function  SetVertexCoord(LinkIndex: Integer; Vertex: Integer; X, Y: Double):
          Boolean;
function  GetVertexCount(LinkIndex: Integer): Integer;
procedure SetVertexCoords(LinkIndex: Integer; X: array of Double;
          Y: array of Double; Count: Integer);

procedure SetTitle(Line1: string; Line2: string; Line3: string);
procedure SetItemID(Category: Integer; Index: Integer; ID: string);
procedure SetDefHydOptions(const Options: TDefOptions);
procedure GetDefHydOptions(var Options: TDefOptions);

function  ConvertLink(Index: Integer; LinkType: Integer): Boolean;
procedure DeleteItem(Category: Integer; Index: Integer);
procedure DeleteLabelAnchors(NodeID: string);
function  CanPasteItem(Item: Integer; CopiedCategory: Integer;
          CopiedType: Integer):Boolean;

function  Load(FileName: string): Integer;
function  Save(FileName: string): Boolean;
procedure RemoveResults;
procedure UpdateResultsStatus;

implementation

uses
  main, mapcoords, maplabel, mapthemes, results, projectmapdata, utils, epanet2;

procedure Open;
begin
  RptFile := utils.CreateTempFile('EN_Rpt_');
  OutFile := utils.CreateTempFile('EN_Out_');
  OutFile2 := utils.CreateTempFile('EN_Out2_');
  AuxFile := utils.CreateTempFile('EN_Aux_');
  MsxOutFile := utils.CreateTempFile('EN_Msx_');
  MsxHydFile := utils.CreateTempFile('EN_Hyd_');
  Properties := TStringList.Create;
  CopiedProperties := TStringList.Create;
  MapLabels := TStringList.Create;
  Init;
end;

procedure Init;
begin
  InpFile := '';
  MsxInpFile := '';
  Properties.Clear;
  MapLabels.Clear;
  epanet2.ENinit(PAnsiChar(RptFile), PAnsiChar(OutFile), epanet2.EN_GPM,
    epanet2.EN_HW);
  AutoLength := false;
  MapUnits := muNone;
  MapEPSG := 0;
  HasChanged := false;
  HasResults := false;
  SimStatus := ssNone;
  ResultsStatus := rsNotAvailable;
  OutFileOpened := false;
  OutFile2Opened := false;
  MsxFileOpened := false;
  MsxFlag := false;
  StatusRptType := epanet2.EN_NORMAL_REPORT;
  CopiedProperties.Clear;
end;

procedure Clear;
var
  I: Integer;
begin
  Results.CloseOutFile;
  DeleteFile(project.AuxFile);
  epanet2.ENclose;
  for I := 0 to MapLabels.Count - 1 do
    MapLabels.Objects[I].Free;
  MapLabels.Clear;
  InpFile := '';
  HasChanged := false;
  HasResults := false;
end;

procedure Close;
begin
  Clear;
  SysUtils.DeleteFile(OutFile);
  SysUtils.DeleteFile(OutFile2);
  SysUtils.DeleteFile(RptFile);
  SysUtils.DeleteFile(AuxFile);
  SysUtils.DeleteFile(MsxOutFile);
  SysUtils.DeleteFile(MsxHydFile);
  Properties.Free;
  CopiedProperties.Free;
  MapLabels.Free;
end;

function GetItemCount(Category: Integer): Integer;
begin
  Result := 0;
  case Category of
    ctTitle:
      Result := 3;   //The EPANET API restricts titles to 3 lines.
    ctOptions:
      Result := High(OptionsStr)+1;
    ctNodes:
      epanet2.ENgetcount(EN_NODECOUNT, Result);
    ctLinks:
      epanet2.ENgetcount(EN_LINKCOUNT, Result);
    ctControls:
      Result := 2;   //Simple & rule-based controls
    ctLabels:
      Result := MapLabels.Count;
    ctPatterns:
      epanet2.ENgetcount(EN_PATCOUNT, Result);
    ctCurves:
      epanet2.ENgetcount(EN_CURVECOUNT, Result);
  end;
end;

function IsEmpty: Boolean;
begin
  Result := true;
  if (GetItemCount(ctNodes) > 0)
  or (Maplabels.Count > 0) then
    Result := false;;
end;

function GetItemID(Category: Integer; Item: Integer): string;
begin
  Result := '';
  if Item < 0 then exit;
  case Category of
    ctTitle:
      Result := GetTitle(Item);
    ctOptions:
      Result := OptionsStr[Item];
    ctControls:
      Result := ControlsStr[Item];
    ctLabels:
      Result := MapLabels[Item];
    else
      Result := GetID(Category, Item+1);
  end;
end;

function  GetItemIndex(Category: Integer; ID: string): Integer;
var
  Index: Integer;
  pID: PAnsiChar;
begin
  Index := 0;
  pID := PAnsiChar(ID);
  case Category of
    ctNodes:
      epanet2.ENgetnodeindex(pID, Index);
    ctLinks:
      epanet2.ENgetlinkindex(pID, Index);
    ctPatterns:
      epanet2.ENgetpatternindex(pID, Index);
    ctCurves:
      epanet2.ENgetcurveindex(pID, Index);
    ctLabels:
      Index := MapLabels.IndexOf(ID);
  end;
  Result := Index;
end;

function  GetID(Category: Integer; Index: Integer): string;
var
  ID: array[0..EN_MAXID+1] of AnsiChar;
begin
  ID := '';
  case Category of
    ctNodes:    epanet2.ENgetnodeid(Index, ID);
    ctLinks:    epanet2.ENgetlinkid(Index, ID);
    ctPatterns: epanet2.ENgetpatternid(Index, ID);
    ctCurves:   epanet2.ENgetcurveid(Index, ID);
  end;
  Result := ID;
end;

function GetIdError(Category: Integer; ID: string): string;
var
  N: Integer;
begin
  Result := '';
  N := Length(ID);
  if (Pos(' ', ID) > 0)
  or (Pos(';', ID) > 0) then
    Result := rsBadID
  else if (N > EN_MAXID)
  or (N = 0) then
    Result := Format(rsBlankID, [EN_MAXID])
  else if Project.GetItemIndex(Category, ID) > 0 then
    Result := rsUsedID;
end;

function GetTitle(Item: Integer): string;
var
  Lines: array[0..2] of string;
  I: Integer;
begin
  for I := 0 to 2 do
    Lines[I] := StringOfChar(#0, EN_MAXMSG+1);
  epanet2.ENgettitle(PAnsiChar(Lines[0]), PAnsiChar(Lines[1]), PAnsiChar(Lines[2]));
  for I := 0 to 2 do
    SetLength(Lines[I], Pos(#0, Lines[I]) - 1);
  Result := Lines[Item];
end;

function  GetComment(Category: Integer; Index: Integer): string;
var
  Comment: AnsiString;
begin
  Result := '';
  Comment := StringOfChar(#0, EN_MAXMSG+1);
  case Category of
    ctNodes:    Category := EN_NODE;
    ctLinks:    Category := EN_LINK;
    ctPatterns: Category := EN_TIMEPAT;
    ctCurves:   Category := EN_CURVE;
    else exit;
  end;
  epanet2.ENgetcomment(Category, Index, PAnsiChar(Comment));
  SetLength(Comment, Pos(#0, Comment) - 1);
  Result := Comment;
end;

function  GetTag(Category: Integer; Index: Integer): string;
var
  Tag: AnsiString;
begin
  Result := '';
  Tag := StringOfChar(#0, EN_MAXMSG+1);
  case Category of
    ctNodes: Category := EN_NODE;
    ctLinks: Category := EN_LINK;
    else exit;
  end;
  epanet2.ENgettag(Category, Index, PAnsiChar(Tag));
  SetLength(Tag, Pos(#0, Tag) - 1);
  Result := Tag;
end;

function  GetItemTypeStr(Category: Integer; Item: Integer): string;
var
  I: Integer = 0;
begin
  Result := '';
  case Category of
    ctNodes:
      begin
        epanet2.ENgetnodetype(Item+1, I);
        if I = EN_RESERVOIR then
          Result := rsReservoir + ' '
        else if I = EN_TANK then
          Result := rsTank + ' '
        else
          Result := rsJunction + ' ';
      end;
    ctLinks:
      begin
        epanet2.ENgetlinktype(Item+1, I);
        if I = EN_PUMP then
          Result := rsPump + ' '
        else if I >= EN_PRV then
          Result := rsValve + ' '
        else
          Result := rsPipe + ' ';
      end;
    ctPatterns:
      Result := rsPattern + ' ';
    ctCurves:
      Result := rsCurve + ' ';
  end;
end;

function GetNodeType(Index: Integer): Integer;
var
  NodeType: Integer = 0;
begin
  epanet2.ENgetnodetype(Index, NodeType);
  Result := NodeType;
end;

function  GetLinkType(Index: Integer): Integer;
var
  LinkType: Integer = 0;
begin
  epanet2.ENgetlinktype(Index, LinkType);
  if LinkType > ltPump then LinkType := ltValve;
  Result := LinkType;
end;

function ConvertLink(Index: Integer; LinkType: Integer): Boolean;
var
  ID: string;
  NewIndex: Integer;
  Length: Single;
begin
  // Get ID of link being converted
  Result := false;
  ID := GetID(ctLinks, Index);

  // Call Epanet API function to convert link to LinkType
  if epanet2.ENsetlinktype(Index, LinkType, EN_UNCONDITIONAL) <> 0 then exit;

  // If new type is a pipe then assign it default properties
  if LinkType = ltPipe then
  begin
    NewIndex := GetItemIndex(ctLinks, ID);
    if NewIndex > 0 then
    begin
      if AutoLength then
        Length := FindLinkLength(NewIndex)
      else
        Length := StrToFloatDef(DefProps[4], 0.0);
      epanet2.ENsetpipedata(NewIndex, Length, StrToFloatDef(DefProps[5],
        0.0), StrToFloatDef(DefProps[6], 0.0), 0.0);
    end;
  end;
  Result := true;
end;

function GetLinkNodes(Link: Integer; var Node1, Node2: Integer): Boolean;
begin
  if epanet2.ENgetlinknodes(Link, Node1, Node2) = 0 then
    Result := true
  else
    Result := false;
end;

procedure ReverseLinkNodes(Link: Integer);
var
  I: Integer;
  J: Integer;
  N: Integer;
  Node1: Integer = 0;
  Node2: Integer = 0;
  X: array of Double;
  Y: array of Double;
begin
  // Get node indices at each end of link
  if epanet2.ENgetlinknodes(Link, Node1, Node2) = 0 then
  begin
    // Switch end nodes
    epanet2.ENsetlinknodes(Link, Node2, Node1);

    // Reverse order of link's vertices
    N := GetVertexCount(Link);
    if N > 0 then
    begin
      // Set size of X & Y arrays to hold vertex coords.
      SetLength(X, N);
      SetLength(Y, N);

      // Load vertices into X,Y in reverse order
      for I := 1 to N do
      begin
        J := N - I;
        GetVertexCoord(Link, I, X[J], Y[J]);
      end;

      // Set link's vertex coords. to contents of X & Y
      SetVertexCoords(Link, X, Y, N);
      SetLength(X, 0);
      SetLength(Y, 0);
    end;
    HasChanged := true;
  end;
end;

function  GetSourceQual(NodeIndex: Integer): Single;
begin
  Result := 0;
  epanet2.ENgetnodevalue(NodeIndex, EN_SOURCEQUAL, Result);
end;

function GetNodeCoord(NodeIndex: Integer; var X, Y: Double): Boolean;
begin
  X := EN_MISSING;
  Y := EN_MISSING;
  if epanet2.ENgetcoord(NodeIndex, X, Y) = 0 then
    Result := true
  else
    Result := false;
end;

procedure SetNodeCoord(NodeIndex: Integer; X: Double; Y: Double);
begin
  epanet2.ENsetcoord(NodeIndex, X, Y);
end;

function GetLinkCoord(LinkIndex: Integer; var X, Y: Double): Boolean;
var
  N: Integer;
  N1: Integer = 0;
  N2: Integer = 0;
  X1: Double = 0;
  Y1: Double = 0;
  X2: Double = 0;
  Y2: Double = 0;
begin
  // Link has vertices - use middle vertex
  N := GetVertexCount(LinkIndex);
  if N > 0 then
  begin
    // N is index of middle vertex
    if Odd(N) then
      N := (N div 2) + 1
    else
      N := N div 2;
    Result := GetVertexCoord(LinkIndex, N, X, Y);
  end

  // Link has no vertices - use mid-point of end nodes
  else
  begin
    Result := GetLinkNodes(LinkIndex, N1, N2);
    if Result then
      Result := GetNodeCoord(N1, X1, Y1);
    if Result then
      Result := GetNodeCoord(N2, X2, Y2);
    if Result then
    begin
      X := (X1 + X2) / 2.;
      Y := (Y1 + Y2) / 2;
    end;
  end;
end;

function  GetLabelCoord(LabelIndex: Integer; var X, Y: Double): Boolean;
var
  I: Integer;
  MapLabel: TMapLabel;
begin
  Result := true;
  I := LabelIndex - 1;  // Make index be 0-based
  MapLabel := TMapLabel(MapLabels.Objects[I]);
  if MapLabel = nil then
    Result := false
  else
  begin
    X := MapLabel.X;
    Y := MapLabel.Y;
  end;
end;

procedure SetLabelCoord(LabelIndex: Integer; X: Double; Y: Double);
var
  I: Integer;
  MapLabel: TMapLabel;
begin
  I := LabelIndex - 1;  // Make index be 0-based
  MapLabel := TMapLabel(MapLabels.Objects[I]);
  if MapLabel <> nil then
  begin
    MapLabel.X := X;
    MapLabel.Y := Y;
  end;
end;

function  GetNodeParam(NodeIndex: Integer; Param: Integer): Single;
begin
  Result := 0;
  epanet2.ENgetnodevalue(NodeIndex, Param, Result);
end;

function  GetLinkParam(LinkIndex: Integer; Param: Integer): Single;
begin
  Result := 0;
  epanet2.ENgetlinkvalue(LinkIndex, Param, Result);
end;

function  GetPumpResultsCount: Integer;
var
  I: Integer;
  LinkType: Integer = 0;
begin
  Result := 0;
  for I := 1 to GetItemCount(ctLinks) do
  begin
    epanet2.ENgetlinktype(I, LinkType);
    if LinkType <> EN_PUMP then continue;
    if GetResultIndex(ctLinks, I) > 0 then Inc(Result);
  end;
end;

function GetVertexCount(LinkIndex: Integer): Integer;
var
  Count: Integer = 0;
begin
  Result := 0;
  if epanet2.ENgetvertexcount(LinkIndex, Count) = 0 then Result := Count;
  if Result > MAX_VERTICES then Result := MAX_VERTICES;
end;

function GetVertexCoord(LinkIndex: Integer; Vertex: Integer;
          var X, Y: Double): Boolean;
begin
  if epanet2.ENgetvertex(LinkIndex, Vertex, X, Y) > 0 then
    Result := false
  else
    Result := true;
end;

function SetVertexCoord(LinkIndex: Integer; Vertex: Integer; X, Y: Double):
          Boolean;
begin
  if epanet2.ENsetvertex(LinkIndex, Vertex, X, Y) > 0 then
    Result := false
  else
    Result := true;
  HasChanged := true;
end;

procedure SetVertexCoords(LinkIndex: Integer; X: array of Double;
          Y: array of Double; Count: Integer);
begin
  epanet2.ENsetvertices(LinkIndex, X[0], Y[0], Count);
  HasChanged := true;
end;

function GetPatternNames: String;
var
  I: Integer;
  N: Integer;
begin
  Result := '';
  N := GetItemCount(ctPatterns);
  if N > 0 then
    for I := 1 to N do
      Result := Result + #13 + GetID(ctPatterns, I);
end;

function  GetCurveNames(aCurveType: Integer): String;
var
  I: Integer;
  N: Integer;
  CurveType: Integer;
begin
  Result := '';
  N := GetItemCount(ctCurves);
  if N > 0 then
  begin
    for I := 1 to N do
    begin
      CurveType := ctGeneric;
      ENgetcurvetype(I, CurveType);
      if (CurveType = aCurveType)
      or (CurveType = ctGeneric) then
        Result := Result + #13 + GetID(ctCurves, I);
    end;
  end;
end;

function GetCurveType(CurveIndex: Integer): Integer;
var
  CurveType : Integer = ctGeneric;
begin
  if ENgetcurvetype(CurveIndex, CurveType) = 0 then
    Result := curveType
  else
    Result := ctGeneric;
end;

function GetUnitsSystem: Integer;
var
  I: Integer = 0;
begin
  epanet2.ENgetflowunits(I);
  if I >= EN_LPS then
    Result := usSI
  else
    Result := usUS;
end;

procedure SetFlowUnits(Units: string);
var
  I: Integer;
begin
  I := AnsiIndexText(Units, FlowUnitsStr);
  if (I >= 0) and (I <> FlowUnits) then
  begin
    epanet2.ENsetflowunits(I);
    FlowUnits := I;
    MainForm.UpdateStatusBar(sbFlowUnits, FlowUnitsStr[FlowUnits]);
  end;
end;

procedure SetPressUnits(Units: string);
var
  I:      Integer;
begin
  I := AnsiIndexText(Units, PressUnitsStr);
  if (I >= 0) and (I <> PressUnits) then
  begin
    ENsetoption(EN_PRESS_UNITS, I);
    PressUnits := I;
    MainForm.UpdateStatusBar(sbPressUnits, PressUnitsStr[PressUnits]);
    mapthemes.ChangeTheme(MainForm.LegendTreeView, ctNodes,
          MainForm.MainMenuFrame.ViewNodeCombo.ItemIndex);
  end;
end;

procedure SetDemandModel(NewModel: Integer);
var
  OldModel: Integer = 0;
  Pmin:     Single = 0;
  Preq:     Single = 0;
  Pexp:     Single = 0;
begin
  if (NewModel < Low(DemandModelStr))
  or (NewModel > High(DemandModelStr)) then exit;
  epanet2.ENgetdemandmodel(OldModel, Pmin, Preq, Pexp);
  if OldModel = NewModel then exit;
  epanet2.ENsetdemandmodel(NewModel, Pmin, Preq, Pexp);
  MainForm.UpdateStatusBar(sbDemands, DemandModelStr[NewModel]);
  if (not HasChanged) and (not IsEmpty) then HasChanged := true;
end;

procedure DeleteItem(Category: Integer; Index: Integer);
var
  R: Integer;
  S: string;
begin
  case Category of
    ctNodes:
      begin
        S := GetID(ctNodes, Index);
        DeleteLabelAnchors(S);
        R := epanet2.ENdeletenode(Index, EN_UNCONDITIONAL);
        if R > 0 then
        begin
          if R = 260 then  // cannot delete a WQ source tracing node
            utils.MsgDlg(rsDeleteFail, Format(rsNoDelSource, [S]),
              mtInformation, [mbOK], MainForm)
          else
            utils.MsgDlg(rsDeleteFail, Format(rsNoDelNode, [R,S]),
              mtInformation, [mbOK], MainForm)
        end;
      end;
    ctLinks:
      epanet2.ENdeletelink(Index, EN_UNCONDITIONAL);
    ctPatterns:
      epanet2.ENdeletepattern(Index);
    ctCurves:
      epanet2.ENdeletecurve(Index);
    ctLabels:
      begin
        MapLabels.Objects[Index-1].Free;
        MapLabels.Delete(Index-1);
      end;
  end;
  HasChanged := true;
  UpdateResultsStatus;
end;

procedure DeleteLabelAnchors(NodeID: string);
var
  I: Integer;
  MapLabel: TMapLabel;
begin
  for I := 0 to MapLabels.Count - 1 do
  begin
    MapLabel := TMapLabel(MapLabels.Objects[I]);
    if MapLabel.AnchorNode = NodeID then MapLabel.AnchorNode := '';
  end;
end;

function CanPasteItem(Item: Integer; CopiedCategory: Integer;
  CopiedType: Integer): Boolean;
var
  Index:         Integer;
  FromValveType: Integer;
  ToValveType:   Integer = 0;
begin
  Result := false;
  Index := Item + 1;

  // Copied and pasted node types are the same
  if (CopiedCategory = ctNodes)
  and (CopiedType = GetNodeType(Index)) then
    Result := true

  // Check if copied and pasted link types are the same
  else if (CopiedCategory = ctLinks) then
  begin

    // Check if copied valve properties being pasted into same valve type
    if CopiedType = ltValve then
    begin
      FromValveType := EN_PRV + AnsiIndexText(CopiedProperties[7], ValveTypeStr);
      epanet2.ENgetLinkType(Index, ToValveType);
      if FromValveType = ToValveType then Result := true;
    end

    // Check for other link types (pipes & pumps)
    else if CopiedType = GetLinkType(Index) then
      Result := true
  end;
end;

function Load(FileName: string): Integer;
var
  Extent: TDoubleRect;
  X:      Single = 0;
begin
  // Read contents of input file
  Clear;
  Result := epanet2.ENopenX(PAnsiChar(FileName), PAnsiChar(RptFile),
    PAnsiChar(OutFile));

  // Input file was read successfully
  if (Result = 0) or (Result = 200) then
  begin
    InpFile := FileName;
    epanet2.ENgetflowunits(FlowUnits);
    epanet2.ENgetoption(EN_PRESS_UNITS, X);
    PressUnits := Round(X);

    // Read map-related data in input file not read by ENopenX
    projectmapdata.ReadMapData(InpFile);

    // Find the coordinates of the rectangle that bounds all network objects
    Extent := MapCoords.GetBounds(MainForm.MapFrame.GetExtent);
    MainForm.MapFrame.SetExtent(Extent);
  end

  // Input file failed to be read -- start a new empty project
  else
    Init;

  // Copy the input reader's error report to program's auxilary file
  epanet2.ENcopyreport(PAnsiChar(AuxFile));
end;

function Save(FileName: string): Boolean;
var
  ErrCode: Integer;
begin
  with MainForm.MapFrame do
    if HasWebBasemap then UnloadWebBasemap;
  ErrCode := epanet2.ENsaveinpfile(PAnsiChar(FileName));
  Result := (ErrCode = 0);
  if Result then
  begin
    projectmapdata.SaveMapData(FileName);
    HasChanged := false;
  end;
end;

procedure SetTitle(Line1: string; Line2: string; Line3: string);
begin
  epanet2.ENsettitle(PAnsiChar(Line1), PAnsiChar(Line2), PAnsiChar(Line3));
end;

function  GetResultIndex(Category: Integer; Index: Integer): Integer;
//
//  Get the position to which the results for a given node or link was
//  written to the output file.
//
begin
  Result := 0;
  if Category = ctNodes then
    epanet2.ENgetresultindex(EN_NODE, Index, Result)
  else if Category = ctLinks then
    epanet2.ENgetresultindex(EN_LINK, Index, Result)
end;

procedure SetItemID(Category: Integer; Index: Integer; ID: String);
var
  pID: PAnsiChar;
begin
  pID := PAnsiChar(ID);
  case Category of
    ctNodes:
      epanet2.ENsetnodeid(Index, pID);
    ctLinks:
      epanet2.ENsetlinkid(Index, pID);
    ctPatterns:
      epanet2.ENsetpatternid(Index, pID);
    ctCurves:
      epanet2.ENsetcurveid(Index, pID);
    ctLabels:
      MapLabels[Index] := ID;
  end;
end;

procedure GetDefHydOptions(var Options: TDefOptions);
var
  I: Integer = 0;
  X: Single = 0;
begin
  epanet2.ENgetflowunits(I);
  Options[htFlowUnits] := FlowUnitsStr[I];

  epanet2.ENgetoption(EN_PRESS_UNITS, X);
  Options[htPressUnits] := PressUnitsStr[Round(X)];

  epanet2.ENgetoption(EN_HEADLOSSFORM, X);
  Options[htHlossModel] := HLossModelStr[Round(X)];

  epanet2.ENgetoption(EN_SP_GRAVITY, X);
  Options[htSpGravity] := utils.Float2Str(X, 3);

  epanet2.ENgetoption(EN_SP_VISCOS, X);
  Options[htSpViscos] := utils.Float2Str(X, 3);

  epanet2.ENgetoption(EN_TRIALS, X);
  Options[htMaxTrials] := IntToStr(Round(X));

  epanet2.ENgetoption(EN_ACCURACY, X);
  Options[htAccuracy] := utils.Float2Str(X, 8);

  epanet2.ENgetoption(EN_HEADERROR, X);
  Options[htHeadTol] := utils.Float2Str(X, 8);

  epanet2.ENgetoption(EN_FLOWCHANGE, X);
  Options[htFlowTol] := utils.Float2Str(X, 8);
end;

procedure SetDefHydOptions(const Options: TDefOptions);
var
  I: Integer;
begin
  I := AnsiIndexText(Options[htPressUnits], PressUnitsStr);
  if I >= 0 then
    epanet2.ENsetoption(EN_PRESS_UNITS, I);

  I := AnsiIndexText(Options[htHlossModel], HlossModelStr);
  if I >= 0 then
  begin
    epanet2.ENsetoption(EN_HEADLOSSFORM, I);
    MainForm.UpdateStatusBar(sbHeadLoss, HlossModelStr[I]);
  end;

  epanet2.ENsetoption(EN_SP_GRAVITY, StrToFloat(Options[htSpGravity]));
  epanet2.ENsetoption(EN_SP_VISCOS, StrToFloat(Options[htSpViscos]));
  epanet2.ENsetoption(EN_TRIALS, StrToFloat(Options[htMaxTrials]));
  epanet2.ENsetoption(EN_ACCURACY, StrToFloat(Options[htAccuracy]));
  epanet2.ENsetoption(EN_HEADERROR, StrToFloat(Options[htHeadTol]));
  epanet2.ENsetoption(EN_FLOWCHANGE, StrToFloat(Options[htFlowTol]));
end;

function  GetHlossModelStr: string;
var
  Value: Single = 0;
begin
  epanet2.ENgetoption(EN_HEADLOSSFORM, Value);
  Result := HlossModelStr[Round(Value)];
end;

function  GetDemandModelStr: string;
var
  I:    Integer = 0;
  Pmin: Single = 0;
  Preq: Single = 0;
  Pexp: Single = 0;
begin
  epanet2.ENgetdemandmodel(I, Pmin, Preq, Pexp);
  Result := DemandModelStr[I];
end;

function  GetQualModelStr: string;
var
  QualCode:       Integer = 0;
  ChemName:       array[0..EN_MAXID] of AnsiChar = '';
  QualUnits:      array[0..EN_MAXID] of AnsiChar = '';
  TraceNodeIndex: Integer = 0;
begin

  // For multi-species analysis
  if MsxFlag then
    Result := 'Multi-Species'

  // For single-species analysis
  else
  begin
    epanet2.ENgetqualinfo(QualCode, ChemName, QualUnits, TraceNodeIndex);
    Result := QualModelStr[QualCode];
    if (QualCode = qtChem)
    and (Length(ChemName) > 0) then
      Result := ChemName;
  end;
end;

function  GetObjectStr(Category: Integer; Item: Integer): string;
begin
  Result := '';
  if Category = ctNodes then
    Result := rsNode
  else if Category = ctLinks then
    Result := rsLink
  else
    exit;
  Result := Result + ' ' + GetItemID(Category, Item);
end;

function MapDistance(X1, Y1, X2, Y2: Double): Single;
var
  Distance: Double = 0;
  Dx: Double;
  Dy: Double;
begin
  if MapUnits = muDegrees then
    Distance := utils.Haversine(X1, Y1, X2, Y2)
  else
  begin
    Dx := X2 - X1;
    Dy := Y2 - Y1;
    Distance := Sqrt(Dx*Dx + Dy*Dy);
  end;
  Result := Single(Distance);
end;

function  FindLinkLength(LinkIndex: Integer): Single;
var
  J:     Integer;
  Node1: Integer = 0;
  Node2: Integer = 0;
  Units: Integer = 0;
  X1:    Double = 0;
  Y1:    Double = 0;
  X2:    Double = 0;
  Y2:    Double = 0;
begin
  // Length is 0 for non-pipe links
  Result := 0;
  if GetLinkType(LinkIndex) > ltPipe then exit;

  // Get coordinates of pipe's start node
  if epanet2.ENgetlinknodes(LinkIndex, Node1, Node2) <> 0 then exit;
  if not GetNodeCoord(Node1, X1, Y1) then exit;

  // Add length between each pipe vertex to total length
  for J := 1 to GetVertexCount(LinkIndex) do
  begin
    if not GetVertexCoord(LinkIndex, J, X2, Y2) then continue;
    Result := Result + MapDistance(X1, Y1, X2, Y2);
    X1 := X2;
    Y1 := Y2;
  end;

  // Add length to pipe's end node to total length
  if GetNodeCoord(Node2, X2, Y2) then
    Result := Result + MapDistance(X1, Y1, X2, Y2);

  // Apply proper unit conversion to result
  Units := GetUnitsSystem;
  if (MapUnits = muFeet)
  and (Units = usSI) then
    Result := Result * 0.3048
  else if (MapUnits = muMeters)
  and (Units = usUS) then
    Result := Result / 0.3048
  else if (MapUnits = muDegrees)
  and (Units = usUS) then
    Result := Result / 0.3048;
end;

procedure AdjustLinkLengths(NodeIndex: Integer);
var
  I:      Integer;
  Node1:  Integer = 0;
  Node2:  Integer = 0;
  Length: Single;
begin
  if not AutoLength then exit;
  for I := 1 to GetItemCount(ctLinks) do
  begin
    if GetLinkType(I) > ltPipe then continue;
    if epanet2.ENgetlinknodes(I, Node1, Node2) <> 0 then continue;
    if (Node1 = NodeIndex)
    or (Node2 = NodeIndex) then
    begin
      Length := FindLinkLength(I);
      if Length > 0 then
        epanet2.ENsetlinkvalue(I, EN_LENGTH, Length);
    end;
  end;
end;

procedure SetPipeLength(PipeIndex: Integer);
var
  NewLength: Single;
begin
  NewLength := FindLinkLength(PipeIndex);
  epanet2.ENsetlinkvalue(PipeIndex, EN_LENGTH, NewLength);
  with MainForm.ProjectFrame.PropEditor do
  begin
    EditorMode := false;
    Cells[1,6] := Float2Str(NewLength, 4);
    EditorMode := true;
  end;
end;

function  GetStatisticsType: Integer;
var
  T: TimeType = 0;
begin
  epanet2.ENgettimeparam(EN_STATISTIC, T);
  Result := Integer(T);
end;

procedure RemoveResults;
begin
  results.CloseOutFile;
  SysUtils.DeleteFile(AuxFile);
  HasResults := false;
  SimStatus := ssNone;
  ResultsStatus := rsNotAvailable;
  MainForm.UpdateStatusBar(sbResults, rsNoResults);
end;

procedure UpdateResultsStatus;
begin
  if (ResultsStatus = rsUpToDate)
  and HasChanged then
  begin
    ResultsStatus := rsNeedsUpdating;
    MainForm.UpdateStatusBar(sbResults, rsNeedUpdating);
  end;
end;

end.


