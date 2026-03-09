{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mapgeoref
 Description:  a frame used to georeference a basemap image
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
{
  The mapgeoref frame contains a TNotebook with 5 pages that are
  accessed in wizard-type fashion:
  Page1 - selects whether to use control points or a world file
          for georeferencing
  Page2 - selects two control points on the basemap and the
          distance between them
  Page3 - provides the world coordinates of a third control point
  Page4 - displays the contents of an opened world file
  Page5 - displays the world coordinates for the georeferenced basemap
}

unit mapgeoref;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, ComCtrls, StdCtrls, SpinEx,
  Buttons, Dialogs, Grids, Types, mapcoords;

type

  { TGeoRefFrame }

  TGeoRefFrame = class(TFrame)
    Notebook1:      TNotebook;
    Page1:          TPage;
    Page2:          TPage;
    Page3:          TPage;
    Page4:          TPage;
    Page5:          TPage;
    TopPanel:       TPanel;
    MidPanel:       TPanel;
    BotPanel:       TPanel;
    BackBtn:        TButton;
    NextBtn:        TButton;
    WorldFileBtn:   TButton;
    CloseBtn:       TSpeedButton;
    Label1:         TLabel;
    Label2:         TLabel;
    Label3:         TLabel;
    Label16:        TLabel;
    Label17:        TLabel;
    RP1Label:       TLabel;
    RP2Label:       TLabel;
    RP3Label:       TLabel;
    XunitsLabel:    TLabel;
    YunitsLabel:    TLabel;
    UnitsCB:        TComboBox;
    UnitsRG:        TRadioGroup;
    MethodRG:       TRadioGroup;
    CtrlPt2RB:      TRadioButton;
    CtrlPt3RB:      TRadioButton;
    CtrlPt1RB:      TRadioButton;
    WorldFileGrid:  TStringGrid;
    ExtentsGrid:    TStringGrid;
    LowLeftXEdit:   TFloatSpinEditEx;
    LowLeftYEdit:   TFloatSpinEditEx;
    DistanceEdit:   TFloatSpinEditEx;

    procedure BackBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure WorldFileBtnClick(Sender: TObject);

  private
    GeoRefMethod: Integer;
    MapUnits:     string;
    Lowerleft:    mapcoords.TDoublePoint;
    UpperRight:   mapcoords.TDoublePoint;
    CtrlPt:       array[1..3] of mapcoords.TDoublePoint;

    procedure GetGeoRefMethod;
    procedure SetToolbarButtons;
    procedure LoadWorldFile;
    procedure FindExtentFromControlPoints;
    procedure FillExtentsGrid;
    procedure SetBasemapExtent;
    function  AcceptDistancePoints: Boolean;
    function  AcceptReferencePoint: Boolean;
    function  ReadWorldFile(Filename: string): Boolean;

  public
    procedure Show;
    procedure Hide;
    function  GetCtrlPointIndex(W: TDoublePoint): Integer;
  end;

implementation

{$R *.lfm}

uses
  main, project, config, utils, resourcestrings;

const
  gmControlPts = 0;
  gmWorldFile = 1;

  WorldFileFields: array[0..3] of string =
    (rsWorldXpix, rsWorldYpix, rsTopLeftX, rsTopLeftY);

  ExtentsFields: array[0..3] of string =
    (rsLowLeftX, rsLowLeftY, rsUpRightX, rsUpRightY);

{ TGeoRefFrame }

procedure TGeoRefFrame.Show;
//
//  Initialize the frame's contents when made visible by user
//  selecting the Georeference item on the main form's Basemap menu
//
var
  I: Integer;
begin
  // Initialize georeferencing method and distance units
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  Notebook1.PageIndex := 0;
  MethodRG.ItemIndex := 0;
  with UnitsRG do
  begin
    ItemIndex := project.MapUnits;
    MapUnits := Items[ItemIndex];
    XunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
    YunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
  end;
  GeoRefMethod := gmControlPts;

  // Populate the labels used to display world file information
  // and the extents of the basemap
  for I := 0 to 3 do
  begin
    WorldFileGrid.Cells[0,I] := WorldFileFields[I];
    WorldFileGrid.Cells[1,I] := '';
    ExtentsGrid.Cells[0,I] := ExtentsFields[I];
    ExtentsGrid.Cells[1,I] := '';
  end;

  // Initialize the captions and edit controls used for
  // georeferencing with control points
  RP1Label.Caption := '';
  RP2Label.Caption := '';
  RP3Label.Caption := '';
  LowLeftXEdit.Value := 0;
  LowLeftYEdit.Value := 0;
  DistanceEdit.Value := 0;
  CtrlPt1RB.Checked := false;
  CtrlPt2RB.Checked := false;
  CtrlPt3RB.Checked := false;

  // Initialize the wizard's navigation buttons
  SetToolbarButtons;
  Visible := true;
end;

procedure TGeoRefFrame.Hide;
//
//  Hide the frame when the user clicks the close button in its top panel
//
var
  I: Integer;
begin
  with MainForm.MapFrame do
    for I := Low(CtrlPoint) to High(CtrlPoint) do CtrlPoint[I].Visible := false;
  Visible := false;
  MainForm.MapFrame.RedrawMap;
end;

procedure TGeoRefFrame.NextBtnClick(Sender: TObject);
begin
  case Notebook1.PageIndex of
    0: // Page1 - select method & units
      GetGeoRefMethod;

    1:  // Page2 - select distance control points
      if AcceptDistancePoints then Notebook1.PageIndex := 2;

    2:  // Page3 - select reference control point
      begin
        if AcceptReferencePoint then
        begin
          FindExtentFromControlPoints;
          Notebook1.PageIndex := 4;
        end;
      end;

    3:  // Page4 - display world file extents
      Notebook1.PageIndex := 4;

    4: // Page5 - accept georeferenced extents
      SetBasemapExtent;
  end;
  SetToolbarButtons;
end;

procedure TGeoRefFrame.GetGeoRefMethod;
var
  I: Integer;
begin
  if (GeoRefMethod = gmControlPts)
  and (MethodRG.ItemIndex = gmWorldFile) then
  begin
    with MainForm.MapFrame do
      for I := Low(CtrlPoint) to High(CtrlPoint) do
        CtrlPoint[I].Visible := false;
    MainForm.MapFrame.RedrawMap;
  end;

  GeoRefMethod := MethodRG.ItemIndex;
  with UnitsRG do
  begin
    MapUnits := Items[ItemIndex];
    XunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
    YunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
  end;

  if GeoRefMethod = gmControlPts then
    Notebook1.PageIndex := 1
  else
    Notebook1.PageIndex := 3;
end;

procedure TGeoRefFrame.BackBtnClick(Sender: TObject);
begin
  case Notebook1.PageIndex of
    1:
      Notebook1.PageIndex := 0;
    2:
      Notebook1.PageIndex := 1;
    3:
      Notebook1.PageIndex := 0;
    4:
      begin
        if GeoRefMethod = gmControlPts then
          Notebook1.PageIndex := 2
        else
          Notebook1.PageIndex := 3;
      end;
  end;
  SetToolbarButtons;
end;

procedure TGeoRefFrame.WorldFileBtnClick(Sender: TObject);
begin
  LoadWorldFile;
end;

procedure TGeoRefFrame.CloseBtnClick(Sender: TObject);
begin
  Hide;
end;

procedure TGeoRefFrame.SetToolbarButtons;
begin
  NextBtn.Caption := rsNext;
  BackBtn.Enabled := true;
  case Notebook1.PageIndex of
    0:
      BackBtn.Enabled := false;
    4:
      NextBtn.Caption := rsAccept;
    end;
end;

function TGeoRefFrame.AcceptDistancePoints: Boolean;
begin
  Result := false;
  if DistanceEdit.Value <= 0 then
    utils.MsgDlg(rsInvalidData, rsBadDistance, mtError, [mbOK])

  else if (RP1Label.Caption = '') or (RP2Label.Caption = '') then
    utils.MsgDlg(rsMissingData, rsTwoPtsNeeded, mtError, [mbOK])

  else if RP1Label.Caption = RP2Label.Caption then
    utils.MsgDlg(rsInvalidData, rsSamePts, mtError, [mbOK])

  else
    Result := true;
end;

function TGeoRefFrame.AcceptReferencePoint: Boolean;
begin
  Result := false;
  if (RP3Label.Caption = '') then
    utils.MsgDlg(rsMissingData, rsNoThirdPt, mtError, [mbOK])
  else
    Result := true;
end;

procedure TGeoRefFrame.LoadWorldFile;
begin
  begin
    with MainForm.OpenDialog1 do
    begin
      FileName := '*.wld';
      Filter := rsWorldFile;
      if Execute then
      begin
        if not ReadWorldFile(Filename) then
          Utils.MsgDlg(rsFileError, rsNoWorldFile, mtError, [mbOk], MainForm);
      end;
    end;
  end;
end;

function TGeoRefFrame.ReadWorldFile(Filename: string): Boolean;
var
  Lines: TStringList;
  I: Integer;
  K: Integer;
  X: array[0..5] of Double;
  BasemapSize: TSize;
begin
  Result := false;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(Filename);
    if Lines.Count >= 6 then
    begin
      K := 0;
      for I := 0 to 5 do
        if Utils.Str2Float(Lines[I], X[I]) then Inc(K);
      if K = 6 then
      begin
        BasemapSize := MainForm.MapFrame.GetBasemapSize;
        LowerLeft.X := X[4];
        LowerLeft.Y := X[5] + X[3] * BasemapSize.Height;
        UpperRight.X := X[4] + X[0] * BasemapSize.Width;
        UpperRight.Y := X[5];
        with WorldFileGrid do
        begin
          Cells[1,0] := Lines[0];
          Cells[1,1] := Lines[3];
          Cells[1,2] := Lines[4];
          Cells[1,3] := Lines[5];
        end;
        FillExtentsGrid;
        Result := true;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TGeoRefFrame.GetCtrlPointIndex(W: TDoublePoint): Integer;
var
  S: string;
begin
  Result := 0;
  S := Format('%.6f, %.6f', [W.X, W.Y]);
  if Notebook1.PageIndex = 2 then
  begin
    if CtrlPt3RB.Checked then
    begin
      RP3Label.Caption := S;
      CtrlPt[3] := W;
      CtrlPt3RB.Checked := false;
      Result := 3;
    end;
  end
  else if CtrlPt1RB.Checked then
  begin
    RP1Label.Caption := S;
    CtrlPt[1] := W;
    CtrlPt1RB.Checked := false;
    Result := 1;
  end
  else if CtrlPt2RB.Checked then
  begin
    RP2Label.Caption := S;
    CtrlPt[2] := W;
    CtrlPt2RB.Checked := false;
    Result := 2;
  end;
end;

procedure TGeoRefFrame.FindExtentFromControlPoints;
var
  I: Integer;
  SW: TDoublePoint;
  NE: TDoublePoint;
  DP: TDoublePoint;
  Wwidth: Double;
  Wheight: Double;
  WPP: Double;
  Psize: TSize;
  P: array[1..3] of TDoublePoint;
begin
  // Get current basemap extent (SW, NW) in world coordinates and
  // basemap image width and height (Psize) in pixels
  with MainForm.MapFrame do
  begin
    SW := Map.Basemap.LowerLeft;
    NE := Map.Basemap.UpperRight;
    Psize := GetBasemapSize;
  end;
  Wwidth := NE.X - SW.X;
  Wheight := NE.Y - SW.Y;

  // Find pixel position of each control point within the basemap image
  for I := 1 to 3 do
  begin
    P[I].X := (CtrlPt[I].X - SW.X) / Wwidth * Psize.Width;
    P[I].Y := (CtrlPt[I].Y - SW.Y) / Wheight * Psize.Height;
  end;

  // Use distance between control points 1 and 2 to find world per pixel value (WPP)
  DP.X := P[1].X - P[2].X;
  DP.Y := P[1].Y - P[2].Y;
  WPP := Sqrt(DP.X*DP.X + DP.Y*DP.Y);
  WPP := DistanceEdit.Value / WPP;

  // Use control point 3 to find lower left of new extent
  LowerLeft.X := LowLeftXEdit.Value;
  LowerLeft.Y := LowLeftYEdit.Value;
  UpperRight.X := LowerLeft.X + (WPP * Psize.Width);
  UpperRight.Y := LowerLeft.Y + (WPP * Psize.Height);

  // Display extent in the ExtentsGrid
  FillExtentsGrid;
end;

procedure TGeoRefFrame.FillExtentsGrid;
begin
  with ExtentsGrid do
  begin
    Cells[1,0] := Format('%.6f',[LowerLeft.X]);
    Cells[1,1] := Format('%.6f',[LowerLeft.Y]);
    Cells[1,2] := Format('%.6f',[UpperRight.X]);
    Cells[1,3] := Format('%.6f',[UpperRight.Y]);
  end;
end;

procedure TGeoRefFrame.SetBasemapExtent;
//  Change the dimensions of the network map to encompass the basemap.
var
  NewExtent:     TDoubleRect;
  BasemapSize:   TSize;
  MapRect:       TRect;
  BasemapWidth:  Double;
  BasemapHeight: Double;
  Delta:         Double;
  WPP:           Double;
begin
  // Width & height of map window and basemap in pixels
  MapRect := MainForm.MapFrame.GetMapRect;
  BaseMapSize := MainForm.MapFrame.GetBasemapSize;

  // Width & height of basemap in world units
  BasemapWidth := UpperRight.X - LowerLeft.X;
  BasemapHeight := UpperRight.Y - LowerLeft.Y;
  if (BasemapWidth = 0)
  or (BasemapHeight = 0) then
  begin
    Utils.MsgDlg(rsInvalidData, rsBadExtents, mtError, [mbOk], MainForm);
    exit;
  end;

  // Basemap extents in world units
  NewExtent.LowerLeft := LowerLeft;
  NewExtent.UpperRight := UpperRight;

  // Map window is wider than basemap
  if MapRect.Width > BasemapSize.Width then
  begin
    // World per pixel of basemap
    WPP := BasemapWidth / BasemapSize.Width;

    // Extend extents width to fill map window
    Delta := WPP * (MapRect.Width - BasemapSize.Width) / 2;
    NewExtent.LowerLeft.X := LowerLeft.X - Delta;
    NewExtent.UpperRight.X := UpperRight.X + Delta;
  end;

  // Map window is taller than basemap
  if MapRect.Height > BasemapSize.Height then
  begin
    // World per pixel of basemap
    WPP := BasemapHeight / BasemapSize.Height;

    // Extend extents height to fill map window
    Delta := WPP * (MapRect.Height - BasemapSize.Height) / 2;
    NewExtent.LowerLeft.Y := LowerLeft.Y - Delta;
    NewExtent.UpperRight.Y := UpperRight.Y + Delta;
  end;

  // Replace full map extents with the georeferenced one
  MainForm.MapFrame.ChangeExtent(NewExtent);
  project.MapUnits := UnitsRG.ItemIndex;
  Hide;
end;

end.

