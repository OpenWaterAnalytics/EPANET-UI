{====================================================================
 project:      EPANET-UI
 Version:      1.0.3
 Module:       projectbuilder
 Description:  Adds new objects to a project
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit projectbuilder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls, Forms, Dialogs;

function  FindUnusedID(Category: Integer; SubCategory: Integer): string;
procedure AddNode(NodeType: Integer; Xcoord: Double; Ycoord: Double);
procedure AddLink(LinkType: Integer; Node1: Integer; Node2: Integer);
procedure AddPattern;
procedure AddCurve;
procedure AddLabel(Location: TPoint; Xcoord: Double; Ycoord: Double);
procedure EditLabelText(LabelIndex: Integer; Location: TPoint);

procedure ImportShapeFile;
procedure ImportDxfFile;
procedure ImportCsvFile;

implementation

uses
  main, project, projectframe, mapframe, maplabel, labeleditor,
  utils, shpimporter, dxfimporter, csvimporter, epanet2, resourcestrings;


function FindUnusedID(Category: Integer; SubCategory: Integer): string;
var
  I: Integer;
  N: Integer;
begin
  // IDprefix array contains prefixes for Junctions, Reservoirs, Tanks,
  // Pipes, Pumps, Valves, Patterns, and Curves in that order.
  case Category of
    ctNodes:
      I := 1 + SubCategory;
    ctLinks:
      I := 3 + SubCategory;
    ctPatterns:
      I := 7;
    ctCurves:
      I := 8;
    else
      I := 0;
  end;
  N := 0;
  while true do
  begin
    Inc(N);
    Result := project.IDprefix[I] + IntToStr(N);
    if project.GetItemIndex(Category, Result) = 0 then
      break;
  end;
end;

procedure AddNode(NodeType: Integer; Xcoord: Double; Ycoord: Double);
var
  ID:        string;
  NodeIndex: Integer = 0;
  Err:       Integer;
begin
  ID := FindUnusedID(ctNodes, NodeType);
  Err := epanet2.ENaddnode(PChar(ID), NodeType, NodeIndex);
  if Err = 0 then
  begin
    epanet2.ENsetcoord(NodeIndex, Xcoord, Ycoord);
    epanet2.ENsetnodevalue(NodeIndex, EN_ELEVATION,
      StrToFloatDef(project.DefProps[ptNodeElev], 0));
    if NodeType = ntTank then
    begin
      epanet2.ENsetnodevalue(NodeIndex, EN_MAXLEVEL,
        StrToFloatDef(project.DefProps[ptTankHt], 0.0));
      epanet2.ENsetnodevalue(NodeIndex, EN_TANKDIAM,
        StrToFloatDef(project.DefProps[ptTankDiam], 0.0));
    end;
    MainForm.MapFrame.RedrawMap;
    MainForm.ProjectFrame.SelectItem(ctNodes, NodeIndex-1);
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end
  else
    utils.MsgDlg(rsCreateFail, rsNoAddNode, mtError, [mbOK]);
end;

procedure AddLinkVertices(LinkIndex: Integer);
var
  X: array[0..project.MAX_VERTICES] of Double;
  Y: array[0..project.MAX_VERTICES] of Double;
  N: Integer = 0;
begin
  MainForm.MapFrame.GetVertices(X, Y, N);
  if N > 0 then
  begin
    epanet2.ENsetvertices(LinkIndex, X[0], Y[0], N);
    project.HasChanged := true;
  end;
end;

procedure AddLink(LinkType: Integer; Node1: Integer; Node2: Integer);
var
  LinkID:     string;
  FromNodeID: string;
  ToNodeID:   string;
  LinkIndex:  Integer = 0;
  Length:     Single = 0;
  Err:        Integer;
begin
  LinkID := FindUnusedID(ctLinks, LinkType);
  FromNodeID := project.GetID(ctNodes, Node1);
  ToNodeID := project.GetID(ctNodes, Node2);
  if LinkType = ltValve then LinkType := EN_TCV;
  Err := epanet2.ENaddlink(Pchar(LinkID), LinkType, PChar(FromNodeID),
    PChar(ToNodeID), LinkIndex);
  if Err = 0 then
  begin
    AddLinkVertices(LinkIndex);
    if LinkType = ltPipe then
    begin
      if project.AutoLength then
        Length := project.FindLinkLength(LinkIndex)
      else
        Length := StrToFloatDef(project.DefProps[ptPipeLen], 0.0);
      ENsetpipedata(LinkIndex, Length,
        StrToFloatDef(project.DefProps[ptPipeDiam], 0.0),
        StrToFloatDef(project.DefProps[ptPipeRough], 0.0), 0.0);
    end;
    MainForm.MapFrame.RedrawMap;
    MainForm.OverviewMapFrame.Redraw;
    MainForm.ProjectFrame.SelectItem(ctLinks, LinkIndex-1);
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end
  else
    utils.MsgDlg(rsCreateFail, rsNoAddLink, mtError, [mbOK]);
end;

procedure AddPattern;
var
  ID:  string;
  Err: Integer;
begin
  ID := FindUnusedID(ctPatterns, 0);
  Err := epanet2.ENaddpattern(PChar(ID));
  if Err = 0 then with MainForm.ProjectFrame do
  begin
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end
  else
    utils.MsgDlg(rsCreateFail, rsNoAddPattern, mtError, [mbOK]);
end;

procedure AddCurve;
var
  ID:  string;
  Err: Integer;
begin
  ID := FindUnusedID(ctCurves, 0);
  Err := epanet2.ENaddcurve(PChar(ID));
  if Err = 0 then with MainForm.ProjectFrame do
  begin
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end
  else
    utils.MsgDlg(rsCreateFail, rsNoAddCurve, mtError, [mbOK]);
end;

function GetLabelText(Location: TPoint; Text: string): string;
var
  LabelEditorForm: TLabelEditorForm;
begin
  Result := '';
  LabelEditorForm := TLabelEditorForm.Create(MainForm.MapFrame);
  with LabelEditorForm do
  try
    Left := Location.X;
    Top := Location.Y;
    Width := 200;
    Edit1.Text := Text;
    if ShowModal = mrOK then Result := Edit1.Text;
  finally
    Free;
  end;
end;

procedure AddLabel(Location: TPoint; Xcoord: Double; Ycoord: Double);
var
  S:        string = '';
  MapLabel: TMapLabel;
begin
  S := GetLabelText(Location, S);
  if Length(S) = 0 then exit;
  MapLabel := TMapLabel.Create;
  MapLabel.X := Xcoord;
  MapLabel.Y := Ycoord;
  project.MapLabels.AddObject(S, Maplabel);
  MainForm.MapFrame.RedrawMap;
  MainForm.ProjectFrame.SelectItem(ctLabels, project.MapLabels.Count-1);
  project.HasChanged := true;
end;

procedure EditLabelText(LabelIndex: Integer; Location: TPoint);
var
  S1, S2: string;
  P: TPoint;
  MapLabel: TMapLabel;
begin
  MapLabel := TMapLabel(MapLabels.Objects[LabelIndex]);
  if MapLabel = nil then exit;
  P.X := MainForm.MapFrame.Map.GetXpix(MapLabel.X);
  P.Y := MainForm.MapFrame.Map.GetYpix(MapLabel.Y);
  P := MainForm.MapFrame.MapBox.ClientToScreen(P);
  S1 := project.MapLabels[LabelIndex];
  S2 := GetLabelText(P, S1);
  if (Length(S2) > 0) and (S2 <> S1) then
  begin
    project.MapLabels[LabelIndex] := S2;
    project.HasChanged := true;
  end;
end;

procedure ImportShapeFile;
begin
  with TShpImporterForm.Create(MainForm) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure ImportDxfFile;
begin
  with TDxfImporterForm.Create(MainForm) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

procedure ImportCsvFile;
begin
  with TCsvImporterForm.Create(MainForm) do
  try
    ShowModal;
  finally
    Free;
  end;
end;

end.

