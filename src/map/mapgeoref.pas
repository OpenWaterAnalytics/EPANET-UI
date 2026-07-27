{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mapgeoref
 Description:  a frame used to georeference a basemap image
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}
{
  The mapgeoref frame contains a TNotebook with 5 pages that are
  accessed in wizard-type fashion:
  Page1 - selects whether to use distance or scale factor for
          georeferencing
  Page2 - selects two control points on the basemap and the
          distance between them
  Page3 - provides the world coordinates of a third control point
  Page4 - selects a scale factor and lower left coordinates
  Page5 - displays the bounding coordinates of the georeferenced basemap
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
    Label1:         TLabel;
    Label2:         TLabel;
    Label3:         TLabel;
    Label4:         TLabel;
    Label5:         TLabel;
    Label6:         TLabel;
    Label7:         TLabel;
    Label8:         TLabel;
    Label9:         TLabel;
    PointLabel1:    TLabel;
    PointLabel2:    TLabel;
    PointLabel3:    TLabel;
    XunitsLabel:    TLabel;
    YunitsLabel:    TLabel;
    Notebook1:      TNotebook;
    Page1:          TPage;
    Page2:          TPage;
    Page3:          TPage;
    Page4:          TPage;
    Page5:          TPage;
    TopPanel:       TPanel;
    MidPanel:       TPanel;
    BotPanel:       TPanel;
    HelpBtn:        TButton;
    BackBtn:        TButton;
    NextBtn:        TButton;
    WorldFileBtn:   TButton;
    CloseBtn:       TSpeedButton;
    WorldPerPixelEdit: TFloatSpinEditEx;
    LowerLeftEditX: TFloatSpinEditEx;
    LowerLeftEditY: TFloatSpinEditEx;
    UnitsCB:        TComboBox;
    UnitsRG:        TRadioGroup;
    MethodRG:       TRadioGroup;
    CtrlPtRB1:      TRadioButton;
    CtrlPtRB2:      TRadioButton;
    CtrlPtRB3:      TRadioButton;
    CtrlPtRB4:      TRadioButton;
    XanchorEdit:    TFloatSpinEditEx;
    YanchorEdit:    TFloatSpinEditEx;
    DistanceEdit:   TFloatSpinEditEx;
    BasemapGrid:    TStringGrid;

    procedure BackBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure CtrlPtRB1Click(Sender: TObject);
    procedure CtrlPtRB4Click(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure WorldFileBtnClick(Sender: TObject);

  private
    GeoRefMethod: Integer;
    MapUnits:     string;
    CtrlPt:       array[1..3] of mapcoords.TDoublePoint;
    AnchorPt:     mapcoords.TDoublePoint;
    Distance:     Double;
    ScaleInfo1:   mapcoords.TScalingInfo;
    ScaleInfo2:   mapcoords.TScalingInfo;

    procedure GetGeoRefMethod;
    procedure SetToolbarButtons;
    procedure LoadWorldFile;
    function  ReadWorldFile(Filename: string): Boolean;
    function  AcceptDistancePoints: Boolean;
    function  AcceptScalingFactor: Boolean;
    function  GetWorldPerPixel: Double;
    procedure FindNewScaling;
    procedure FindNewExtent;
    procedure TransformCoordinates;

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
  gmDistance = 0;
  gmScaling = 1;

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
  DS: Char;
begin
  // Set decimal separator for TFloatSpinEditEx controls
  DS := DefaultFormatSettings.DecimalSeparator;
  XanchorEdit.DecimalSeparator := DS;
  YanchorEdit.DecimalSeparator := DS;
  DistanceEdit.DecimalSeparator := DS;

  // Set frame colors
  Color := config.CreamTheme;
  config.SetHeaderColor(TopPanel);

  // Initialize georeferencing method and distance units
  Notebook1.PageIndex := 0;
  MethodRG.ItemIndex := 0;
  with UnitsRG do
  begin
    I := project.MapUnits;
    if I < Items.Count then ItemIndex := I else ItemIndex := 0;
    MapUnits := Items[ItemIndex];
    XunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
    YunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
  end;
  GeoRefMethod := gmDistance;

  // Populate the labels of the basemap extents grid
  for I := 0 to 3 do
  begin
    BasemapGrid.Cells[0,I] := ExtentsFields[I];
    BasemapGrid.Cells[1,I] := '';
  end;

  // Initialize the captions and edit controls used for
  // georeferencing with distance
  XanchorEdit.Value := 0;
  YanchorEdit.Value := 0;
  DistanceEdit.Value := 0;
  for I := 1 to 3 do
  begin
    with FindComponent('CtrlPtRB' + IntToStr(I)) as TRadioButton do
    begin
      Checked := false;
      Caption := rsLocatePoint  + ' ' + IntToStr(I);
    end;
    CtrlPtRB4.Checked := false;
    with FindComponent('PointLabel' + IntToStr(I)) as TLabel do
      Caption := '';
  end;

  // Initialize the frame's navigation buttons
  Visible := true;
  SetToolbarButtons;
end;

procedure TGeoRefFrame.Hide;
//
//  Hide the frame when the user clicks the close button in its top panel
//
var
  I: Integer;
begin

  // Hide the control point icons on the network map
  with MainForm.MapFrame do
    for I := Low(CtrlPoint) to High(CtrlPoint) do
      CtrlPoint[I].Visible := false;

  // Make the frame invisible and redraw the network map
  Visible := false;
  MainForm.MapFrame.RedrawMap;
end;

procedure TGeoRefFrame.NextBtnClick(Sender: TObject);
begin
  // Process choices made on current notebook page before moving to next page
  case Notebook1.PageIndex of

    0: // Page1 - set georeferencing method & units
      GetGeoRefMethod;

    1: // Page2 - set distance control points
      if AcceptDistancePoints then Notebook1.PageIndex := 2;

    2: // Page3 - set reference control point
      if Length(PointLabel3.Caption) = 0 then
        utils.MsgDlg(rsInvalidData, rsNoThirdPt, mtError, [mbOK])
      else
      begin
        AnchorPt.X := XanchorEdit.Value;
        AnchorPt.Y := YanchorEdit.Value;
        FindNewExtent;
        Notebook1.PageIndex := 4;
      end;

    3: // Page4 - process scaling factor & lower left coords.
      if AcceptScalingFactor then
      begin
        FindNewExtent;
        Notebook1.PageIndex := 4;
      end;

    4: // Transform coords. of network objects
      TransformCoordinates;
  end;
  SetToolbarButtons;
end;

procedure TGeoRefFrame.GetGeoRefMethod;
var
  I: Integer;
begin
  // Remove control point icons from network map if scaling georef method used
  if (GeoRefMethod = gmDistance)
  and (MethodRG.ItemIndex = gmScaling) then
  begin
    with MainForm.MapFrame do
      for I := Low(CtrlPoint) to High(CtrlPoint) do
        CtrlPoint[I].Visible := false;
    MainForm.MapFrame.RedrawMap;
  end;

  // Save selected georef method and map distance units
  GeoRefMethod := MethodRG.ItemIndex;
  with UnitsRG do
  begin
    MapUnits := Items[ItemIndex];
    XunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
    YunitsLabel.Caption := project.MapUnitsStr[ItemIndex];
  end;

  // Switch to next notebook page depending on method selected
  if GeoRefMethod = gmDistance then
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
        if GeoRefMethod = gmDistance then
          Notebook1.PageIndex := 2
        else
          Notebook1.PageIndex := 3;
      end;
  end;
  SetToolbarButtons;
end;

procedure TGeoRefFrame.WorldFileBtnClick(Sender: TObject);
//
// Use a World file to determine basemap scaling and origin.
//
begin
  LoadWorldFile;
end;

procedure TGeoRefFrame.CloseBtnClick(Sender: TObject);
begin
  Hide;
end;

procedure TGeoRefFrame.CtrlPtRB1Click(Sender: TObject);
//
// Shared by CtrlPtRB1, CtrlPtRB2, and CtrlPtRB3 where their
// Tag value determines which radio button was clicked.
//
var
  I: Integer = 0;
begin
  with Sender as TRadioButton do I := Tag;
  with FindComponent('CtrlPtRB' + IntToStr(I)) as TRadioButton do
  begin
    if Checked then
    begin
      Caption := rsClickPoint + ' ' + IntToStr(I);
      case I of
      1: CtrlPtRB2.Caption := rsLocatePoint + ' 2';
      2: CtrlPtRB1.Caption := rsLocatePoint + ' 1';
      3: CtrlPtRB4.Checked := false;
      end;
      MainForm.MapFrame.CtrlPoint[I].Visible := false;
      MainForm.MapFrame.RedrawMap;
    end;
  end;
end;

procedure TGeoRefFrame.CtrlPtRB4Click(Sender: TObject);
//
// User selects to place 3rd control point at lower left of basemap image.
//
var
  W: TDoublePoint;
begin
  // Uncheck the radio button used to select Control Point 3 from the map
  CtrlPtRb3.Checked := false;
  CtrlPtRb3.Caption := rsLocatePoint + ' 3';

  // Locate Control Point 3's icon at lower left corner of basemap
  with MainForm.MapFrame do
  begin
    CtrlPoint[3].Visible := true;
    CtrlPoint[3].Position := MainForm.MapFrame.Map.Basemap.LowerLeft;
    RedrawMap;
  end;

  // Assign the basemap's lower left location to Control Point 3
  W := MainForm.MapFrame.Map.Basemap.LowerLeft;
  PointLabel3.Caption := Format('%.6f, %.6f', [W.X, W.Y]);
  CtrlPt[3] := W;
  XanchorEdit.SetFocus;
end;

procedure TGeoRefFrame.SetToolbarButtons;
begin
  NextBtn.Caption := rsNext;
  BackBtn.Enabled := true;
  case Notebook1.PageIndex of
    0:
      begin
        BackBtn.Enabled := false;
        MethodRG.SetFocus;
      end;
    1:
      CtrlPtRb1.SetFocus;
    2:
      CtrlPtRb3.SetFocus;
    3:
      WorldFileBtn.SetFocus;
    4:
      NextBtn.Caption := rsAccept;
    end;
end;

function TGeoRefFrame.AcceptDistancePoints: Boolean;
//
//  Check that control points and distance between them are valid.
//
var
  Msg: string = '';
begin
  Result := false;
  if (Length(PointLabel1.Caption) = 0)
  or (Length(PointLabel2.Caption) = 0) then
    Msg := rsTwoPtsNeeded
  else if SameText(PointLabel1.Caption, PointLabel2.Caption) then
    Msg := rsSamePts
  else if DistanceEdit.Value <= 0 then
    Msg := rsBadDistance;
  if Length(Msg) > 0 then
    utils.MsgDlg(rsInvalidData, Msg, mtError, [mbOK])
  else
  begin
    Distance := DistanceEdit.Value;
    Result := true;
  end;
end;

function TGeoRefFrame.AcceptScalingFactor: Boolean;
//
// Convert user's scaling factor input to an equivalent distance input.
//
begin
  Result := false;
  if WorldPerPixelEdit.Value <= 0 then
    utils.MsgDlg(rsInvalidData, rsWorldPerPixel, mtError, [mbOK])
  else
  begin
    CtrlPt[1] := MainForm.MapFrame.Map.Basemap.LowerLeft;
    CtrlPt[2].X := MainForm.MapFrame.Map.Basemap.UpperRight.X;
    CtrlPt[2].Y := MainForm.MapFrame.Map.Basemap.LowerLeft.Y;
    CtrlPt[3] := CtrlPt[1];
    AnchorPt.X := LowerLeftEditX.Value;
    AnchorPt.Y := LowerLeftEditY.Value;
    Distance := WorldPerPixelEdit.Value * Abs((CtrlPt[2].X - CtrlPt[1].X));
    Result := true;
  end;
end;

procedure TGeoRefFrame.LoadWorldFile;
//
// Obtain the name of a World file to read scaling info from.
//
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
//
// Read the contents of a World file into the input fields on
// Page4 of Notebook1.
//
var
  Lines: TStringList;
  I: Integer;
  K: Integer;
  X: array[0..5] of Double;
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
        WorldPerPixelEdit.Value := X[0];
        LowerLeftEditX.Value := X[4];
        LowerLeftEditY.Value := X[5] -
          (X[0] * MainForm.MapFrame.Map.Basemap.Picture.Height);
        Result := true;
      end;
    end;
  finally
    Lines.Free;
  end;
end;

function TGeoRefFrame.GetCtrlPointIndex(W: TDoublePoint): Integer;
//
//  This function saves the coordinates W of a control point selected on
//  he network map. It is called by the MapFrame's MapBoxClick procedure
//  when the user clicks on the control point location. The return value
//  is used by the MapFrame to determine which control point icon to display.
//
var
  S: string;
begin
  Result := 0;
  S := Format('%.6f, %.6f', [W.X, W.Y]);

  // Control Point 3 was located
  if Notebook1.PageIndex = 2 then
  begin
    if CtrlPtRB3.Checked then
    begin
      PointLabel3.Caption := S;
      CtrlPt[3] := W;
      CtrlPtRB3.Checked := false;
      CtrlptRB3.Caption := rsLocatePoint  + ' 3';
      XanchorEdit.SetFocus;
      Result := 3;
    end;
  end

  // Control Point 1 was located
  else if CtrlPtRB1.Checked then
  begin
    PointLabel1.Caption := S;
    CtrlPt[1] := W;
    CtrlPtRB1.Checked := false;
    CtrlptRB1.Caption := rsLocatePoint  + ' 1';
    CtrlPtRB2.SetFocus;
    Result := 1;
  end

  // Control Point 2 was located
  else if CtrlPtRB2.Checked then
  begin
    PointLabel2.Caption := S;
    CtrlPt[2] := W;
    CtrlPtRB2.Checked := false;
    CtrlptRB2.Caption := rsLocatePoint  + ' 2';
    DistanceEdit.SetFocus;
    Result := 2;
  end;
end;

procedure TGeoRefFrame.FindNewExtent;
//
//  Use new map scaling to find the new coordinates of the basemap's extent.
//
var
  OldExtent: TDoubleRect;
  NewExtent: TDoubleRect;
begin
  // Determine new scaling
  FindNewScaling;

  // Get current basemap extent
  OldExtent.LowerLeft := MainForm.MapFrame.Map.Basemap.LowerLeft;
  OldExtent.UpperRight := MainForm.MapFrame.Map.Basemap.UpperRight;
  NewExtent := OldExtent;

  // Use new scaling to convert OldExtent to NewExtent
  mapcoords.DoExtentTransform(ScaleInfo1, ScaleInfo2, OldExtent, NewExtent);

  // Display extent in Notebook1's Page5
  with BasemapGrid do
  begin
    Cells[1,0] := Format('%.4f', [NewExtent.LowerLeft.X]);
    Cells[1,1] := Format('%.4f', [NewExtent.LowerLeft.Y]);
    Cells[1,2] := Format('%.4f', [NewExtent.UpperRight.X]);
    Cells[1,3] := Format('%.4f', [NewExtent.UpperRight.Y]);
  end;
end;

function TGeoRefFrame.GetWorldPerPixel: Double;
//
// Compute world distance per pixel from control points 1 and 2.
//
var
  S: TScalingInfo;
  P1: TPoint;
  P2: TPoint;
  DP: TDoublePoint;
  D: Double;
begin
  // Current full scale info:
  // S.CW = world coords. of map window center,
  // S.CP = pixel coords. of map window center
  // S.WP = world per pixel distance
  S := MainForm.MapFrame.Map.GetScalingInfo;

  // Find pixel coords. of control points at full scale
  P1.X := S.CP.X + Round((CtrlPt[1].X - S.CW.X) / S.WP);
  P2.X := S.CP.X + Round((CtrlPt[2].X - S.CW.X) / S.WP);
  P1.Y := S.CP.Y - Round((CtrlPt[1].Y - S.CW.Y) / S.WP);
  P2.Y := S.CP.Y - Round((CtrlPt[2].Y - S.CW.Y) / S.WP);

  // Find pixel distance between control points
  DP.X := P2.X - P1.X;
  DP.Y := P2.Y - P1.Y;
  D := Sqrt((DP.X * DP.X) + (DP.Y * DP.Y));

  // Return world distance per pixel
  Result := Distance / D;
end;

procedure TGeoRefFrame.FindNewScaling;
//
// Find scaling information for the georeferenced basemap:
//
// This information contains:
// CP = pixel coordinates of map center point
// CW = world coordinates of map center point
// WP = world distance per pixel
//
var
  P3: TPoint;        // pixel coords. of anchor point
begin
  // Current scaling info
  ScaleInfo1 := MainForm.MapFrame.Map.GetScalingInfo;

  // New scaling has same center pixel
  ScaleInfo2.CP := ScaleInfo1.CP;

  // New world per pixel scaling
  ScaleInfo2.WP := GetWorldPerPixel;

  // Pixel coords of anchor point (CtrlPt[3]) under current scaling
  P3.X := ScaleInfo1.CP.X + Round((CtrlPt[3].X - ScaleInfo1.CW.X) / ScaleInfo1.WP);
  P3.Y := ScaleInfo1.CP.Y - Round((CtrlPt[3].Y - ScaleInfo1.CW.Y) / ScaleInfo1.WP);

  // World coords. of center pixel under new scaling
  ScaleInfo2.CW.X := AnchorPt.X + (ScaleInfo2.CP.X - P3.X) * ScaleInfo2.WP;
  ScaleInfo2.CW.Y := AnchorPt.Y - (ScaleInfo2.CP.Y - P3.Y) * ScaleInfo2.WP;
end;

procedure TGeoRefFrame.TransformCoordinates;
//
//  Transform coordinates of network objects to reflect those of
//  the georeferenced basemap.
//
begin
  // Set map units
  project.MapUnits := UnitsRG.ItemIndex;

  // Transform all coordinates and redraw the map at full extent
  mapcoords.DoScalingTransform(ScaleInfo1, ScaleInfo2);
  MainForm.MapFrame.DrawFullExtent;
  MainForm.OverviewMapFrame.Redraw;

  // Update project's HasChanged status
  if (not project.HasChanged) and (not project.IsEmpty) then
    project.HasChanged := true;
  Hide;
end;

procedure TGeoRefFrame.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#georeferencing_a_basemap');
end;

end.

