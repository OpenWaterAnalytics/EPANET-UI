{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       maplocator
 Description:  a frame that locates objects on the network map
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit maplocater;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Dialogs, LCLtype, ExtCtrls, StdCtrls,
  Buttons, Types, Math;

type

  // Types of objects to locate (ftNode & ftLink) or to list
  TFindType = (ftNode, ftLink, ftTanks, ftReservoirs, ftSources,
               ftPumps, ftValves);

  { TMapLocaterFrame }

  TMapLocaterFrame = class(TFrame)
    CloseBtn:     TSpeedButton;
    FindCombo:    TComboBox;
    NameEdit:     TEdit;
    ResultsLabel: TLabel;
    NamedLabel:   TLabel;
    FindLabel:    TLabel;
    ItemsListbox: TListBox;
    TopPanel:     TPanel;

    procedure CloseBtnClick(Sender: TObject);
    procedure FindComboChange(Sender: TObject);
    procedure NameEditChange(Sender: TObject);
    procedure NameEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ItemsListboxClick(Sender: TObject);

  private
    procedure FindObject(FindType: TFindType);
    procedure FindObjects(FindType:TFindType);
    procedure GetAdjacentObjects(FoundObjType, FoundObjIndex: Integer);
    procedure PanMapToObject(ObjType, ObjIndex: Integer);

  public
    procedure Clear;
    procedure Show;
    procedure Hide;
  end;

implementation

{$R *.lfm}

uses
  main, project, config, utils, resourcestrings;

const
  ResultsLabelCaption: array[0..6] of string =
    (rsAdjacentLinks, rsAdjacentNodes, rsTankNodes, rsReservNodes,
     rsWQSourceNodes, rsPumpLinks, rsValveLinks);

{ TMapLocaterFrame }

procedure TMapLocaterFrame.Clear;
begin
  NameEdit.Text := '';
  ItemsListbox.Clear;
  FindCombo.ItemIndex := 0;
end;

procedure TMapLocaterFrame.Show;
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  Visible := true;
  Clear;
  FindComboChange(Self);
end;

procedure TMapLocaterFrame.Hide;
begin
  Visible := false;
end;

procedure TMapLocaterFrame.FindObject(FindType: TFindType);
var
  ID: string;
  FoundObjType: Integer;
  FoundObjIndex: Integer;
begin
  // Place map in Object Selection mode
  MainForm.MapFrame.EnterSelectionMode;

  // Search project for specified node/link ID
  ID := NameEdit.Text;
  ItemsListbox.Clear;
  if (FindType = ftNode) then
    FoundObjType := ctNodes
  else
    FoundObjType := ctLinks;
  FoundObjIndex := project.GetItemIndex(FoundObjType, ID);

  // If object exists then select it and list its adjacent objects
  if FoundObjIndex > 0 then
  begin
    GetAdjacentObjects(FoundObjType, FoundObjIndex);
    PanMapToObject(FoundObjType, FoundObjIndex);
    MainForm.ProjectFrame.SelectItem(FoundObjType,FoundObjIndex - 1)
  end
  else
    utils.MsgDlg(rsMissingData, rsNoSuchObject, mtInformation, [mbOK], MainForm);

  // Return focus to the NameEdit control
  NameEdit.SetFocus;
  NameEdit.SelectAll;
end;

procedure TMapLocaterFrame.NameEditChange(Sender: TObject);
begin
  ItemsListbox.Clear;
end;

procedure TMapLocaterFrame.CloseBtnClick(Sender: TObject);
begin
  Hide;
end;

procedure TMapLocaterFrame.FindComboChange(Sender: TObject);
var
  EnableNameEdt: Boolean;
begin
  // NameEdit visible only when we want to locate a specific node or link
  EnableNameEdt := TFindType(FindCombo.ItemIndex) in [ftNode, ftLink];
  NamedLabel.Visible := EnableNameEdt;
  NameEdit.Clear;
  NameEdit.Enabled := EnableNameEdt;
  ResultsLabel.Caption := ResultsLabelCaption[FindCombo.ItemIndex];
  ItemsListbox.Clear;
  if not NameEdit.Enabled then
    FindObjects(TFindType(FindCombo.ItemIndex))
  else
    NameEdit.SetFocus;
end;

procedure TMapLocaterFrame.NameEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  FindType: TFindType;
begin
  if Key = VK_RETURN then
  begin
    ItemsListbox.Clear;
    FindType := TFindType(FindCombo.ItemIndex);
    if FindType in [ftNode, ftLink] then FindObject(FindType)
  end;
end;

procedure TMapLocaterFrame.ItemsListboxClick(Sender: TObject);
var
  ID: string;
  ObjType: Integer;
  ObjIndex: Integer;
  FoundType: TFindType;
begin
  // Get ID of selected item
  if ItemsListbox.Items.Count = 0 then exit;
  if ItemsListbox.ItemIndex < 0 then exit;
  ID := ItemsListbox.Items[ItemsListbox.ItemIndex];

  // Set type of object to find on network map
  FoundType := TFindType(FindCombo.ItemIndex);
  if FoundType in [ftLink, ftTanks, ftReservoirs, ftSources] then
    ObjType := ctNodes
  else
    ObjType := ctLinks;

  // Get object's index in the network database
  ObjIndex := project.GetItemIndex(ObjType, ID);

  // If object exists then make it the current selected object which
  // will highlight it on the network map
  if ObjIndex > 0 then
    MainForm.ProjectFrame.SelectItem(ObjType, ObjIndex - 1);
end;

procedure TMapLocaterFrame.GetAdjacentObjects(FoundObjType, FoundObjIndex: Integer);
var
  I: Integer;
  Node1: Integer = 0;
  Node2: Integer = 0;
begin
  if FoundObjType = ctLinks then
  begin
    project.GetLinkNodes(FoundObjIndex, Node1, Node2);
    ItemsListbox.Items.Add(project.GetID(ctNodes, Node1));
    ItemsListbox.Items.Add(project.GetID(ctNodes, Node2));
  end
  else if FoundObjType = ctNodes then
  begin
    for I := 1 to project.GetItemCount(ctLinks) do
    begin
      project.GetLinkNodes(I, Node1, Node2);
      if (Node1 = FoundObjIndex) or (Node2 = FoundObjIndex) then
        ItemsListbox.Items.Add(project.GetID(ctLinks, I));
    end;
  end;
end;

procedure TMapLocaterFrame.FindObjects(FindType:TFindType);
var
  I: Integer;
  N: Integer;
  Imax: Integer;
  ObjClass: Integer;
  Found: Boolean;
begin
  // Which class of object are we looking for
  if FindType in [ftTanks .. ftSources] then
  begin
    ObjClass := ctNodes;
    Imax := project.GetItemCount(ctNodes);
  end
  else
  begin
    ObjClass := ctLinks;
    Imax := project.GetItemCount(ctLinks);
  end;

  // Loop through each object in the class (Nodes or Links)
  N := 0;
  for I := 1 to Imax do
  begin
    // Check if the object is of the type being searched for
    Found := false;
    case FindType of
      ftTanks:
        if project.GetNodeType(I) = ntTank then Found := true;
      ftReservoirs:
        if project.GetNodeType(I) = ntReservoir then Found := true;
      ftSources:
        if project.GetSourceQual(I) > 0 then Found := true;
      ftPumps:
        if project.GetLinkType(I) = ltPump then Found := true;
      ftValves:
        if project.GetLinkType(I) = ltValve then Found := true;
    end;

    // if it is then add its ID to the items in the ItemsListbox
    if Found then
    begin
      Inc(N);
      ItemsListbox.Items.Add(project.GetID(ObjClass, I));
    end;
  end;

  // Message posted if no items of type searched for are found
  if N = 0 then
    utils.MsgDlg(rsMissingData, rsNoObjectType, mtInformation, [mbOK], MainForm);
end;

procedure TMapLocaterFrame.PanMapToObject(ObjType, ObjIndex: Integer);
//  Pan the map so that a given object is in view
const
  Buffer: Integer = 30;
var
  X1: Double = 0;
  Y1: Double = 0;
  X2: Double = 0;
  Y2: Double = 0;
  P1: TPoint = (X:0; Y:0);
  P2: TPoint = (X:0; Y:0);
  Pmin, Pmax: TPoint;
  N1: Integer = 0;
  N2: Integer = 0;
  Dx: Integer = 0;
  Dy: Integer = 0;
begin
  // Find the world coordinates of the object's end nodes
  if ObjType = ctNodes then
  begin
    if not project.GetNodeCoord(ObjIndex, X1, Y1) then exit;
    X2 := X1;
    Y2 := Y1;
  end
  else if ObjType = ctLinks then
  begin
    if not project.GetLinkNodes(ObjIndex, N1, N2) then exit;
    project.GetNodeCoord(N1, X1, Y1);
    project.GetNodeCoord(N2, X2, Y2);
  end
  else exit;

  with MainForm.MapFrame do
  begin
    // Convert the object's world coords. to pixels
    P1 := Map.WorldToScreen(X1, Y1);
    P2 := Map.WorldToScreen(X2, Y2);

    // If the object is already in veiw then exit
    if PtInRect(Map.MapRect, P1) and PtInRect(Map.MapRect, P2) then exit;

    // Find the extents of the object's nodes
    Pmin.X := Min(P1.X, P2.X);
    Pmin.Y := Min(P1.Y, P2.Y);
    Pmax.X := Max(P1.X, P2.X);
    Pmax.Y := Max(P1.Y, P2.Y);

    // Find pixel distance in X direction to bring object in view
    if Pmin.X < Map.MapRect.Left then
      Dx := Map.MapRect.Left - Pmin.X + Buffer
    else if Pmax.X > Map.MapRect.Right then
      Dx := Map.MapRect.Right - Pmax.X - Buffer;

    // Find pixel distance in Y direction to bring object in view
    if Pmax.Y > Map.MapRect.Bottom then
      Dy := Map.MapRect.Bottom - Pmax.Y - Buffer
    else if Pmin.Y < Map.MapRect.Top then
      Dy := (Map.MapRect.Top - Pmin.Y) + Buffer;

    // Shift the network's viewport by this distance and redraw it
    Map.AdjustOffset(Dx, Dy);
    Offset := Point(0, 0);
    RedrawMap;
    MainForm.OverviewMapFrame.ShowMapExtent;
  end;
end;

end.

