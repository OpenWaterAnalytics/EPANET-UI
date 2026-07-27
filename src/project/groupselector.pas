{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       groupselector
 Description:  a frame used to select a group of objects
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit groupselector;

{
 This frame appears in the top-left corner of the EPANET-UI workspace.
 It is used to select a group of objects from the network map. While active,
 selected objects are displayed in red while others are grayed-out. Objects
 (nodes or links) can be selected or deselected by clicking on them. Options
 are also available for selecting all objects or those with a specified Tag
 property or within a user-drawn polygon region on the map.

 The frame is invoked from either the GroupEditorFrame or the
 FireFlowSelectorFrame by calling the Open procedure and passing in ctNodes
 for selecting nodes or ctLinks for selecting links. The Close procedure
 deactivates the frame and returns the network map to its normal colored state.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Graphics, Dialogs,
  Buttons, mapcoords;

type

  TSelectionType = (   // Indicates how objects will be selected
    stIndividual = 1,  // one by one
    stByTag,           // by Tag property
    stByRegion,        // by user drawn region
    stAll);            // all selected

  { TGroupSelectorFrame }

  TGroupSelectorFrame = class(TFrame)
    DoRegionBtn: TButton;
    DoAllBtn: TButton;
    DoClearBtn: TButton;
    CancelBtn: TButton;
    ButtonPanel: TPanel;
    DoTagBtn: TButton;
    AcceptBtn: TButton;
    TagEdit: TEdit;
    SelectLabel: TLabel;
    TopPanel: TPanel;
    procedure AcceptBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure DoAllBtnClick(Sender: TObject);
    procedure DoClearBtnClick(Sender: TObject);
    procedure DoRegionBtnClick(Sender: TObject);
    procedure DoTagBtnClick(Sender: TObject);

  private
    ObjectType:        Integer;       // Either ctNodes or ctLinks
    Nobjects:          Integer;       // Number of nodes or links
    NodeLegendVisible: Boolean;
    LinkLegendVisible: Boolean;
    FCaller:           TFrame;        // Reference to calling frame
    FOnReturn:         TNotifyEvent;  // Callback event
    ReturnCode:        Integer;       // 0 if selection cancelled or
                                      // 1 if accepted
  public
    IsActive:       Boolean;          // When true, network drawn in red & gray
    SelectionState: TBytes;           // 1 if node/link selected, 0 if not

    procedure Open(ObjType: Integer; ACaller: TFrame);
    procedure Close;
    procedure Clear;
    procedure SelectObject(ObjType: Integer; Index: Integer);
    procedure SelectRegion(Poly: TPolygon; const Npts: Integer);
    function  GetSelectedNodeColor(NodeIndex: Integer): TColor;
    function  GetSelectedLinkColor(LinkIndex: Integer): TColor;
    function  GetReturnCode: Integer;
    function  GetSelectedCount: Integer;
    function  IsSelected(Index: Integer): Boolean;
    property  OnReturn: TNotifyEvent read FOnReturn write FOnReturn;

  end;

implementation

{$R *.lfm}

uses
  main, config, project, utils, resourcestrings;

procedure TGroupSelectorFrame.DoAllBtnClick(Sender: TObject);
//
//  Select all map nodes or links.
//
var
  I: Integer;
begin
  for I := 1 to Nobjects do SelectionState[I] := 1;
  MainForm.MapFrame.RedrawMap;
end;

procedure TGroupSelectorFrame.DoClearBtnClick(Sender: TObject);
//
//  Deselect all nodes or links.
//
begin
  Clear;
end;

procedure TGroupSelectorFrame.DoRegionBtnClick(Sender: TObject);
//
//  Begin defining a network map region for selecting nodes or links.
//
begin
  Hide;
  with MainForm do
  begin
    HintTitleLabel.Caption:= rsGroupSelection;
    HintTextLabel.Caption := rsToGroupSelect;
    HintPanel.Visible := True;
    MapFrame.EnterFenceLiningMode('GroupSelection');
  end;
end;

procedure TGroupSelectorFrame.DoTagBtnClick(Sender: TObject);
//
//  Select nodes or links with a specific Tag value.
//
var
  T: string;
  I: Integer;
begin
  T := Trim(TagEdit.Text);
  if Length(T) = 0 then
  begin
    utils.MsgDlg(rsInvalidData, rsBlankTag, mtError, [mbOk]);
    exit;
  end;
  for I := 1 to Nobjects do
  begin
    if SameText(T, project.GetTag(ObjectType, I)) then
      SelectionState[I] := 1;
  end;
  MainForm.MapFrame.RedrawMap;
end;

procedure TGroupSelectorFrame.CancelBtnClick(Sender: TObject);
//
//  Cancel all selections and invoke the calling frame's callback procedure.
//
begin
  Clear;
  Hide;
  ReturnCode := 0;
  if Assigned(FOnReturn) then FOnReturn(Self);
end;

procedure TGroupSelectorFrame.AcceptBtnClick(Sender: TObject);
//
//  Accept the selections and invoke the invoking frame's callback procedure.
//
begin
  if GetSelectedCount = 0 then
  begin
    utils.MsgDlg(rsInvalidSelect, rsNoneSelected, mtInformation, [mbOk], MainForm);
    exit;
  end;
  if Visible then Hide;
  ReturnCode := 1;
  if Assigned(FOnReturn) then FOnReturn(Self);
end;

procedure TGroupSelectorFrame.SelectObject(ObjType: Integer; Index: Integer);
//
//  This procedure is called from the MapBoxDown procedure of the main form's
//  MapFrame when a network object has been mouse clicked on the map.
//
var
  State: Byte;
begin
  if (ObjType <> ObjectType) then exit;
  State := SelectionState[Index];
  if State = 1 then State := 0 else State := 1;
  SelectionState[Index] := State;
  MainForm.MapFrame.RedrawMap;
end;

function  TGroupSelectorFrame.IsSelected(Index: Integer): Boolean;
//
//  Return whether a specific object (by Index) is selected or not.
//
begin
  if (Index >= 1) and (Index <= Nobjects) then
    Result := (SelectionState[Index] = 1)
  else
    Result := false;
end;

function TGroupSelectorFrame.GetSelectedNodeColor(NodeIndex: Integer): TColor;
//
//  Return the color used to draw a selected or unselected node on the map.
//
begin
  Result := clGray;
  if (ObjectType = ctNodes) and (NodeIndex <= Nobjects) then
  begin
    if SelectionState[NodeIndex] = 1 then Result := clRed;
  end;
end;

function TGroupSelectorFrame.GetSelectedLinkColor(LinkIndex: Integer): TColor;
//
//  Return the color used to draw a selected or unselected link on the map.
//
begin
  Result := clGray;
  if (ObjectType = ctLinks) and (LinkIndex <= Nobjects) then
  begin
    if SelectionState[LinkIndex] = 1 then Result := clRed;
  end;
end;

procedure TGroupSelectorFrame.SelectRegion(Poly: TPolygon; const Npts: Integer);
//
//  Called by the LeaveFenceLiningMode procedure of the main form's MapFrame
//  when the user completes drawing a polygon region. It then selects all
//  nodes or links that lie within the region.
//
var
  I:           Integer;
  N1:          Integer;
  N2:          Integer;
  Pt:          TDoublePoint = (X: 0; Y: 0);
  GroupBounds: TDoubleRect = (LowerLeft: (X: 0; Y: 0); UpperRight: (X: 0; Y: 0));
begin
  MainForm.HintPanel.Hide;
  Show;

  // Npts = -1 indicates that all network nodes were selected
  if Npts = -1 then
  begin
    DoAllBtnClick(self);
    exit;
  end;

  // Polygon must have at least 3 vertices
  if (Npts >= 0) and (Npts < 3) then
  begin
    utils.MsgDlg(rsInvalidSelect, rsBadPolygon, mtError, [mbOk], MainForm);
    exit;
  end;

  // Find polygon's bounding rectangle
  if Npts > 0 then
    GroupBounds := utils.PolygonBounds(Poly, Npts);

  // For nodes, add those within group bounds
  if ObjectType = ctNodes then
  begin
    for I := 1 to Nobjects do
    begin
      if not project.GetNodeCoord(I, Pt.X, Pt.Y) then continue;
      if utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then
      begin
        SelectionState[I] := 1;
      end;
    end;
  end

  // For links, add those with end nodes within bounds
  else
  begin
    for I := 1 to Nobjects do
    begin
      if not project.GetLinkNodes(I, N1, N2) then continue;
      if not project.GetNodeCoord(N1, Pt.X, Pt.Y) then continue;
      if not utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then continue;
      if not project.GetNodeCoord(N2, Pt.X, Pt.Y) then continue;
      if not utils.PointInPolygon(Pt, GroupBounds, Npts, Poly) then continue;
      SelectionState[I] := 1;
    end;
  end;
  MainForm.MapFrame.RedrawMap;
end;

function  TGroupSelectorFrame.GetSelectedCount: Integer;
//
//  Return the number of nodes or links that have been selected.
//
var
  I: Integer;
  N: Integer = 0;
begin
  for I := 1 to Nobjects do
    if SelectionState[I] = 1 then Inc(N);
  Result := N;
end;

function TGroupSelectorFrame.GetReturnCode: Integer;
//
//  Return the code set when either the Cancel or Next buttons were clicked.
//
begin
  Result := ReturnCode;
end;

procedure TGroupSelectorFrame.Open(ObjType: Integer; ACaller: TFrame);
//
//  Called from either the GroupEditorFrame or the FireFlowSelectorFrame
//  to activate this frame for node or link objects.
//
var
  I: Integer;
begin
  Color := clCream;
  config.SetHeaderColor(TopPanel);
  IsActive := true;
  ReturnCode := 0;

  ObjectType := ObjType;
  if ObjectType = ctNodes then
  begin
    SelectLabel.Caption := rsClickOnNodes;
    DoTagBtn.Caption := rsNodeTags;
    DoAllBtn.Caption := rsAllNodes;
    DoClearBtn.Caption := rsDelAllNodes;
  end
  else
  begin
    SelectLabel.Caption := rsClickOnLinks;
    DoTagBtn.Caption := rsLinkTags;
    DoAllBtn.Caption := rsAllLinks;
    DoClearBtn.Caption := rsDelAllLinks;
  end;
  FCaller := ACaller;

  // SelectionState indicates if an object by index (ranging from 1 to
  // Nobjects) has been selected (1) or not (0)
  Nobjects := project.GetItemCount(ObjectType);
  SetLength(SelectionState, Nobjects+1);
  for I := 1 to Nobjects do SelectionState[I] := 0;

  // Hide map legends
  NodeLegendVisible := MainForm.MapFrame.NodeLegend.Visible;
  LinkLegendVisible := MainForm.MapFrame.LinkLegend.Visible;
  MainForm.MapFrame.NodeLegend.Visible := false;
  MainForm.MapFrame.LinkLegend.Visible := false;
///  Show;
  MainForm.MapFrame.EnterSelectionMode;
  MainForm.MapFrame.RedrawMap;
end;

procedure TGroupSelectorFrame.Close;
//
//  Deactivate the frame and free memory allocated for the SelectionState.
//
//  Also called from the main form's FormClose procedure to prevent any
//  possible memory leak.
//
begin
  // Restore display of map legends
  MainForm.MapFrame.NodeLegend.Visible := NodeLegendVisible;
  MainForm.MapFrame.LinkLegend.Visible := LinkLegendVisible;

  // Inactivate this frame
  IsActive := false;
  SetLength(SelectionState, 0);
end;

procedure TGroupSelectorFrame.Clear;
//
//  Classify all nodes or links as not selected.
//
var
  I: Integer;
begin
  for I := 1 to Nobjects do SelectionState[I] := 0;
  MainForm.MapFrame.RedrawMap;
end;

end.

