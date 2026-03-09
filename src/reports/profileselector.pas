{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       profileselector
 Description:  A frame used to select a path of links to include in
               a hydraulic profile plot
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit profileselector;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, Dialogs,
  Fgl;

type

  TIntegerList = specialize TFPGList<Integer>; // used to find profile path

  { TProfileSelectorFrame }

  TProfileSelectorFrame = class(TFrame)
    TopPanel:         TPanel;
    ViewBtn:          TButton;
    CancelBtn:        TButton;
    CloseBtn:         TSpeedButton;
    SpeedButton1:     TSpeedButton;
    SpeedButton2:     TSpeedButton;
    StartNodeEdit:    TEdit;
    EndNodeEdit:      TEdit;
    Label1:           TLabel;
    Label2:           TLabel;

    procedure CancelBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure SpeedButtonClick(Sender: TObject);
    procedure ViewBtnClick(Sender: TObject);

  private
    function FindProfilePath(StartNode, EndNode: Integer;
      PathList: TStringList): Boolean;

  public
    HasProfilePlot: Boolean;
    procedure Init;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, profilerpt, reportviewer, utils, resourcestrings;

{ TProfileSelectorFrame }

procedure TProfileSelectorFrame.Init;
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  StartNodeEdit.Clear;
  EndNodeEdit.Clear;
end;

procedure TProfileSelectorFrame.CloseBtnClick(Sender: TObject);
begin
  CancelBtnClick(Sender);
end;

procedure TProfileSelectorFrame.SpeedButtonClick(Sender: TObject);
var
  S: string;
  I: Integer;
begin
  if MainForm.ProjectFrame.CurrentCategory <> ctNodes then
  begin
    utils.MsgDlg(rsInvalidSelect, rsNotNode, mtInformation, [mbOk], MainForm);
    exit;
  end;
  I := MainForm.ProjectFrame.SelectedItem[ctNodes];
  S := project.GetItemID(ctNodes, I);
  with Sender As TSpeedButton do
  begin
    if Tag = 1 then
      StartNodeEdit.Text := S
    else
      EndNodeEdit.Text := S;
  end;
end;

procedure TProfileSelectorFrame.CancelBtnClick(Sender: TObject);
begin
  Visible := false;
  ReportViewerForm.WindowState := wsNormal;
  if not HasProfilePlot then
    ReportViewerForm.CloseReport
  else
    ReportViewerForm.Show;
end;

procedure TProfileSelectorFrame.ViewBtnClick(Sender: TObject);
var
  StartNode,
  EndNode:    Integer;
  PathList:   TStringList;
begin
  StartNode := project.GetItemIndex(ctNodes, StartNodeEdit.Text);
  if StartNode <= 0 then
  begin
    utils.msgdlg(rsMissingData, rsBadStartNode, mtInformation, [mbOk], MainForm);
    exit;
  end;
  EndNode := project.GetItemIndex(ctNodes, EndNodeEdit.Text);
  if EndNode <= 0 then
  begin
    utils.msgdlg(rsMissingData, rsBadEndNode, mtInformation, [mbOk], MainForm);
    exit;
  end;

  PathList := TStringList.Create;
  try
    if not FindProfilePath(StartNode, EndNode, PathList) then
    begin
      utils.msgdlg(rsInvalidSelect, rsNoPathFound, mtInformation, [mbOk], MainForm);
      exit;
    end;
    Visible := false;
    with ReportViewerForm.Report as TProfileRptFrame do
      SetProfileLinks(PathList);
    if ReportViewerForm.WindowState = wsMinimized then
      ReportViewerForm.WindowState := wsNormal;
    ReportViewerForm.Show;

  finally
    PathList.Free;
  end;
end;

procedure BuildAdjList(var AdjList: array of Integer; var AdjStart: array of Integer);
var
  I, J,
  Nnodes,
  Nlinks,
  N1, N2:   Integer;
  Degree:   array of Integer;
begin
  Nnodes := project.GetItemCount(ctNodes);
  Nlinks := project.GetItemCount(ctLinks);
  SetLength(Degree, Nnodes+1);

  // Find degree of each node (# links connected to it)
  for I := 1 to Nlinks do
  begin
    project.GetLinkNodes(I, N1, N2);
    Inc(Degree[N1]);
    Inc(Degree[N2]);
  end;

  // Set starting position of each node in the network's
  // packed adjacency list
  AdjStart[1] := 1;
  for I := 2 to Nnodes + 1 do
  begin
    AdjStart[I] := AdjStart[I-1] + Degree[I-1];
    Degree[I-1] := 0;
  end;

  // Add each link to its end nodes position in the linear
  // adjacency list
  for I := 1 to Nlinks do
  begin
    // Add link I to end node adjacency list sections
    project.GetLinkNodes(I, N1, N2);
    J := AdjStart[N1] + Degree[N1];
    AdjList[J] := I;
    Inc(Degree[N1]);
    J := AdjStart[N2] + Degree[N2];
    AdjList[J] := I;
    Inc(Degree[N2]);
  end;
end;

function GetOtherEndNode(L, N: Integer): Integer;
var
  N1, N2: Integer;
begin
  project.GetLinkNodes(L, N1, N2);
  if N = N1 then
    Result := N2
  else
    Result := N1;
end;

function TProfileSelectorFrame.FindProfilePath(StartNode, EndNode: Integer;
  PathList: TStringList):
  Boolean;
var
  I, L, N1, N2,
  Length,
  Nnodes,
  Nlinks:    Integer;
  MovedBack: Boolean;
  AdjList:   array of Integer;  // Indexes of links connected to each node
  AdjStart:  array of Integer;  // Starting index of each node in AdjList
  PathLen:   array of Integer;  // Length of path from StartNode to each node
  Marked:    array of Boolean;  // Indicator if a node has been visited
  NodeStack: TIntegerList;
begin
  // Build packed node adjacency list
  Result := false;
  Nnodes := project.GetItemCount(ctNodes);
  Nlinks := project.GetItemCount(ctLinks);
  SetLength(AdjList, 2*Nlinks + 1);
  SetLength(AdjStart, Nnodes + 2);
  BuildAdjList(AdjList, AdjStart);

  // Initialize path length to each node and link markers
  SetLength(PathLen, Nnodes + 1);
  SetLength(Marked, Nlinks + 1);
  for I := 1 to Nnodes do
  begin
    PathLen[I] := MAXINT;
    Marked[I] := false;
  end;
  PathLen[StartNode] := 0;

  // Create a stack to hold visited nodes
  NodeStack := TIntegerList.Create;
  try

    // Find path from StartNode to EndNode with fewest links
    NodeStack.Add(StartNode);
    while NodeStack.Count > 0 do
    begin
      // Get last node added to NodeStack
      N1 := NodeStack.Last;
      NodeStack.Remove(NodeStack.Last);

      // Examine each link connected to it
      for I := AdjStart[N1] to AdjStart[N1+1] - 1 do
      begin
        L := AdjList[I];
        if Marked[L] then continue;
        Marked[L] := true;
        N2 := GetOtherEndNode(L, N1);
        Length :=PathLen[N1] + 1;
        if Length < PathLen[N2] then
        begin
          if (PathLen[N2] = MAXINT)
          and (N2 <> EndNode) then
            NodeStack.Add(N2);
          PathLen[N2] := Length;
        end;
      end;
    end;
    if PathLen[EndNode] = MAXINT then exit;

    // Extract indexes of links along profile path
    MovedBack := false;
    N1 := EndNode;
    while N1 <> StartNode do
    begin
      for I := AdjStart[N1] to AdjStart[N1+1] - 1 do
      begin
        L := AdjList[I];
        if not Marked[L] then continue;
        Marked[L] := false;
        N2 := GetOtherEndNode(L, N1);
        if PathLen[N2] = PathLen[N1] - 1 then
        begin
          PathList.Add(project.GetID(ctLinks, L));
          N1 := N2;
          MovedBack := true;
          break;
        end;
      end;
      if not MovedBack then break;
    end;
    Result := true;

  finally
    NodeStack.Free;
  end;
end;

end.

