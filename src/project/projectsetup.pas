{====================================================================
 project:      EPANET-UI
 Version:      1.0.0
 Module:       projectsetup
 Description:  form that edits project default settings
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit projectsetup;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls, StdCtrls,
  ValEdit, Grids, ExtCtrls, StrUtils, lclIntf, LCLtype, Math;

type

  { TProjectSetupForm }

  TProjectSetupForm = class(TForm)
    OkBtn:             TButton;
    CancelBtn:         TButton;
    HelpBtn:           TButton;
    CheckBox1:         TCheckBox;
    Label1:            TLabel;
    Panel1:            TPanel;
    HintPanel:         TPanel;
    RadioGroup1:       TRadioGroup;
    ValueListEditor1:  TValueListEditor;

    procedure OkBtnClick(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure RadioGroup1Click(Sender: TObject);
    procedure ValueListEditor1PickListSelect(Sender: TObject);
    procedure ValueListEditor1PrepareCanvas(sender: TObject; aCol,
      aRow: Integer; aState: TGridDrawState);
    procedure ValueListEditor1SelectCell(Sender: TObject; aCol, aRow: Integer;
      var CanSelect: Boolean);

  private
    PageIndex:     Integer;
    OldFlowUnits:  string;
    OldPressUnits: string;
    OldHlossModel: string;
    NewHlossModel: string;

    procedure EditIDPrefixes;
    procedure EditHydOptions;
    procedure EditProperties;
    procedure EditMapExtents;
    function  ValidateEditorValues: Boolean;
    procedure TransferEditorValues;
    procedure SetEditorContents;
    procedure SetUnitSystemLabel(FlowUnits: string);
    function  ConfirmChanges(var ConversionType: Integer): Boolean;
    procedure ConvertRoughness(ConversionType: Integer; NumLinks: Integer;
      var Roughness: array of Single);

  public
    SaveDefaults:  Boolean;
    RemoveResults: Boolean;

  end;

var
  ProjectSetupForm: TProjectSetupForm;

implementation

{$R *.lfm}

{ TProjectSetupForm }

uses
  main, project, config, utils, mapcoords, epanet2, resourcestrings;

const
  HintLabels: array[0..3] of string =
    (rsHydOptions, rsIDPrefixes, rsNewObjProps, rsMapDimensions);

  IDPrefixName: array[1..project.MAX_ID_PREFIXES] of string =
    (rsJunctions, rsReservoirs, rsTanks, rsPipes, rsPumps, rsValves,
     rsPatterns, rsCurves);

  PropertyName: array[1..project.MAX_DEF_PROPS] of string =
    (rsNodeElev, rsTankHeight, rsTankDiam, rsPipeLength, rsPipeDiam,
     rsPipeRough);

  HydOptionName: array[1..project.MAX_DEF_OPTIONS] of string =
    (rsFlowUnits, rsPressUnits, rsHlossFormula, rsSpGrav, rsSpViscos,
     rsMaxTrials, rsAccuracy, rsHeadTol, rsFlowTol);

  MapExtentsName: array[1..6] of string =
    (rsLowLeftX, rsLowLeftY, rsUpRightX, rsUpRightY, rsMapUnits, 'EPSG');

  mxMapUnits = 5;
  mxEpsg     = 6;

  FormulaConversion = 0;
  DefaultConversion = 1;
  NoConversion      = 2;

var
  TmpIDprefix:   array[1..project.MAX_ID_PREFIXES] of string;
  TmpDefProps:   array[1..project.MAX_DEF_PROPS] of string;
  TmpDefOptions: array[1..project.MAX_DEF_OPTIONS] of string;
  TmpMapExtents: array[1..High(MapExtentsName)] of string;
  MapExtentRect: TDoubleRect;

procedure TProjectSetupForm.FormCreate(Sender: TObject);
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
  ValueListEditor1.FixedColor := config.ThemeColor;
  ValueListEditor1.DefaultColWidth := ValueListEditor1.ClientWidth div 2;
  RadioGroup1.Color := config.ThemeColor;
end;

procedure TProjectSetupForm.FormShow(Sender: TObject);
begin
  MapExtentRect := MainForm.MapFrame.GetExtent;
  TmpMapExtents[1] := Utils.Float2Str(MapExtentRect.LowerLeft.X, 6);
  TmpMapExtents[2] := Utils.Float2Str(MapExtentRect.LowerLeft.Y, 6);
  TmpMapExtents[3] := Utils.Float2Str(MapExtentRect.UpperRight.X, 6);
  TmpMapExtents[4] := Utils.Float2Str(MapExtentRect.UpperRight.Y, 6);
  TmpMapExtents[5] := MapUnitsStr[project.MapUnits];
  TmpMapExtents[6] := IntToStr(project.MapEPSG);

  TmpIDprefix := project.IDprefix;
  TmpDefProps := project.DefProps;
  project.GetDefHydOptions(TmpDefOptions);

  OldFlowUnits := TmpDefOptions[htFlowUnits];
  OldPressUnits := TmpDefOptions[htPressUnits];
  OldHlossModel := TmpDefOptions[htHlossModel];
  SetUnitSystemLabel(TmpDefOptions[1]);

  HintPanel.Caption := HintLabels[0];
  RadioGroup1.ItemIndex := 0;
  PageIndex := 0;
  EditHydOptions;
  ValueListEditor1.Row := 1;
end;

procedure TProjectSetupForm.RadioGroup1Click(Sender: TObject);
begin
 ValueListEditor1.EditorMode := false;
 TransferEditorValues;
 PageIndex := RadioGroup1.ItemIndex;
 SetEditorContents;
 ValueListEditor1.Row := 1;
end;

procedure TProjectSetupForm.OkBtnClick(Sender: TObject);
//
//  Save edited values of project default settings.
//
var
  ConversionType: Integer = -1;
  NumLinks:       Integer = 0;
  I:              Integer;
  Roughness:      array of Single;
begin
  SetLength(Roughness, 0);
  ValueListEditor1.EditorMode := false;
  TransferEditorValues;
  if not ValidateEditorValues then exit;
  NewHlossModel := TmpDefOptions[htHlossModel];

  if ConfirmChanges(ConversionType) then
  begin
    // Save flow & pressure units
    project.SetFlowUnits(TmpDefOptions[htFlowUnits]);
    project.SetPressUnits(TmpDefOptions[htPressUnits]);

    // Save current pipe roughness values if head loss model has changed
    if ConversionType >= 0 then
    begin
      NumLinks := project.GetItemCount(ctLinks);
      SetLength(Roughness, NumLinks + 1);
      for I := 1 to NumLinks do
        epanet2.ENgetlinkvalue(I, EN_ROUGHNESS, Roughness[I]);
    end;

    // Update project with new setup choices
    project.IDprefix := TmpIDprefix;
    project.DefProps := TmpDefProps;
    project.SetDefHydOptions(TmpDefOptions);
    project.MapUnits := AnsiIndexStr(TmpMapExtents[mxMapUnits], project.MapUnitsStr);
    if Length(Trim(TmpMapExtents[mxEpsg])) = 0 then
      TmpMapExtents[mxEpsg] := '0';
    project.MapEPSG := StrToInt(TmpMapExtents[mxEpsg]);
    MainForm.MapFrame.ChangeExtent(MapExtentRect);

    // Convert pipe roughness values if head loss model has changed
    if ConversionType >= 0 then
    begin
      ConvertRoughness(ConversionType, NumLinks, Roughness);
      for I := 1 to NumLinks do
        epanet2.ENsetlinkvalue(I, EN_ROUGHNESS, Roughness[I]);
      SetLength(Roughness, 0);
    end;

    if (not project.HasChanged) and (not project.IsEmpty) then
      project.HasChanged := true;
    SaveDefaults := CheckBox1.Checked;
    ModalResult := mrOk;
  end;
end;

procedure TProjectSetupForm.HelpBtnClick(Sender: TObject);
begin
 MainForm.ViewHelp('#project_setup');
end;

procedure TProjectSetupForm.ValueListEditor1PickListSelect(Sender: TObject);
//
//  Change the Units System label when a new value for Flow Units selected.
//
begin
  if PageIndex = 0 then with ValueListEditor1 do
  begin
    if Row = 1 then
      SetUnitSystemLabel(Cells[1, Row]);
  end;
end;

procedure TProjectSetupForm.ValueListEditor1PrepareCanvas(sender: TObject;
  aCol, aRow: Integer; aState: TGridDrawState);
begin
  if aRow = 0 then
    ValueListEditor1.Canvas.Brush.Color := config.ThemeColor;
end;

procedure TProjectSetupForm.ValueListEditor1SelectCell(Sender: TObject; aCol,
  aRow: Integer; var CanSelect: Boolean);
//
//  Select cell in column 1 of the ValueListEditor when a column 0 cell is selected.
//
begin
  if aCol = 0 then
  begin
    CanSelect := false;
    ValueListEditor1.Row := aRow;
    ValueListEditor1.Col := 1;
  end
  else CanSelect := true;
end;

procedure TProjectSetupForm.EditIDPrefixes;
//
//  Set up the ValueListEditor to edit object ID prefixes.
//
var
  I: Integer;
begin
  with ValueListEditor1 do
  begin
    Clear;
    TitleCaptions[0] := rsObjectType;
    TitleCaptions[1] := rsIDPrefix;
    RowCount := 1;
    for I := 1 to 8 do
      InsertRow(IDPrefixName[I], TmpIDprefix[I], true);
    Show;
  end;
end;

procedure TProjectSetupForm.EditHydOptions;
//
//  Set up the ValueListeditor to edit hydraulic options.
//
var
  I: Integer;
  OptionList: TStringList;
begin
  OptionList := TStringList.Create;
  try
    with ValueListEditor1 do
    begin
      Clear;
      TitleCaptions[0] := rsHydOption;
      TitleCaptions[1] := rsValue;

      RowCount := 1;
      for I := 1 to project.MAX_DEF_OPTIONS do
        InsertRow(HydOptionName[I], TmpDefOptions[I], true);

      OptionList.AddStrings(project.FlowUnitsStr, true);
      with ItemProps[rsFlowUnits] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;

      OptionList.Clear;
      OptionList.AddStrings(project.PressUnitsStr, true);
      with ItemProps[rsPressUnits] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;

      OptionList.Clear;
      OptionList.AddStrings(project.HLossModelStr, true);
      with ItemProps[rsHlossFormula] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
     Show;
   end;
   finally
     OptionList.Free;
   end;
end;

procedure TProjectSetupForm.EditProperties;
//
//  Set up the ValueListEditor to edit node/link properties.
//
var
  I: Integer;
begin
 with ValueListEditor1 do
 begin
   Clear;
   TitleCaptions[0] := rsObjProperty;
   TitleCaptions[1] := rsValue;
   RowCount := 1;
   for I := 1 to 6 do
   begin
     InsertRow(PropertyName[I], TmpDefProps[I], true);
   end;
   Show;
 end;
end;

procedure TProjectSetupForm.EditMapExtents;
//
//  Set up the ValueListEditor to edit network map extents.
//
var
  I: Integer;
  OptionList: TStringList;
begin
 OptionList := TStringList.Create;
 try
   with ValueListEditor1 do
   begin
     Clear;
     TitleCaptions[0] := rsMapProperty;
     TitleCaptions[1] := rsValue;
     RowCount := 1;
     for I := 1 to 6 do
       InsertRow(MapExtentsName[I], TmpMapExtents[I], true);
     OptionList.AddStrings(project.MapUnitsStr, true);
     with ItemProps[rsMapUnits] do
     begin
       EditStyle := esPickList;
       PickList := OptionList;
       ReadOnly := true;
     end;
     if MainForm.MapFrame.HasWebBasemap then Enabled := false;
     Show;
   end;
 finally
   OptionList.Free;
 end;
end;

function TProjectSetupForm.ValidateEditorValues: Boolean;
var
  I:   Integer;
  Tab: Integer;
  Row: Integer;
  X:   Double;
  E:   array[1..4] of Double = (0,0,0,0);
  Msg: string = '';
begin
  Result := true;
  Tab := -1;
  Row := -1;

  // Object Properties
  for I := 1 to 6 do
  begin
    if not TryStrToFloat(TmpDefProps[I], X)
    or ((I > 1) and (X <= 0)) then
    begin
      Msg := TmpDefProps[I] + rsInvalidNumber;
      Tab := 2;
      Row := I;
      Result := false;
      break;
    end;
  end;

  // Map Properties
  if Result = true then for I := 1 to 4 do
  begin
    if not TryStrToFloat(TmpMapExtents[I], E[I]) then
    begin
      Msg := TmpMapExtents[I] + rsInvalidNumber;
      Tab := 3;
      Row := I;
      Result := false;
      break;
    end;
  end;
  if Result = true then
  begin
    MapExtentRect.LowerLeft := DoublePoint(E[1], E[2]);
    MapExtentRect.UpperRight := DoublePoint(E[3], E[4]);
    if SameText(TmpMapExtents[5], project.MapUnitsStr[muDegrees]) and
       (mapcoords.HasLatLonCoords(MapExtentRect) = false) then
    begin
      Msg := rsBadMapCoords;
      Tab := 3;
      Row := 1;
      Result := false;
    end;
  end;

  // Project Options
  if Result = true then for I := 4 to 9 do
  begin
    if not TryStrToFloat(TmpDefOptions[I], X) then
    begin
      Msg := TmpDefOptions[I] + rsInvalidNumber;
      Tab := 0;
      Row := I;
      Result := false;
      break;
    end;
  end;

  // ID Prefixes
  if Result = true then for I := 1 to 8 do
  begin
    if (Pos(' ', TmpIdPrefix[I]) > 0)
    or (Pos(';', TmpIdPrefix[I]) > 0) then
    begin
      Msg := rsBadID;
      Tab := 1;
      Row := I;
      Result := false;
      break;
    end;
  end;

  if Result = false then
  begin
    RadioGroup1.ItemIndex := Tab;
    SetEditorContents;
    ValueListEditor1.Row := Row;
    Utils.MsgDlg(rsValidError, Msg, mtError, [mbOK], self);
    ValueListEditor1.SetFocus;
  end;
end;

procedure TProjectSetupForm.TransferEditorValues;
//
//  Transfer current values in the ValueListEditor to the TmpDefaults array.
//
var
  I: Integer;
begin
 with ValueListEditor1 do
   case PageIndex of
     0:
       for I := 1 to RowCount - 1 do
          TmpDefOptions[I] := Cells[1, I];
     1:
       for I := 1 to RowCount - 1 do
          TmpIDprefix[I] := Cells[1, I];
     2:
       for I := 1 to RowCount - 1 do
          TmpDefProps[I] := Cells[1, I];
     3:
       for I := 1 to RowCount - 1 do
          TmpMapExtents[I] := Cells[1, I];
   end;
end;

procedure TProjectSetupForm.SetEditorContents;
begin
 ValueListEditor1.Enabled := true;
 case PageIndex of
   0:
     EditHydOptions;
   1:
     EditIDPrefixes;
   2:
     EditProperties;
   3:
     EditMapExtents;
 end;
 HintPanel.Caption := HintLabels[RadioGroup1.ItemIndex];
 if (PageIndex = 3)
 and MainForm.MapFrame.HasWebBasemap then
   HintPanel.Caption := rsWebDimensions;
end;

procedure TProjectSetupForm.SetUnitSystemLabel(FlowUnits: string);
//
//  Change the Unit System label for new choice of flow units.
//
begin
  if AnsiIndexText(FlowUnits, project.FlowUnitsStr) < 5 then
    Label1.Caption := rsUnitSystemUS
  else
    Label1.Caption := rsUnitSystemSI;
end;

function TProjectSetupForm.ConfirmChanges(var ConversionType: Integer): Boolean;
//
//  Use a TaskDialog to confirm project changes resulting from setup choices.
//
var
  Msg:               string = '';
  NewFlowUnits:      string;
  NewFlowIndex:      Integer;
  OldFlowIndex:      Integer;
  HlossModelChanged: Boolean = false;
  HasCMmodelChange:  Boolean = false;
begin
  // If project is empty then return true
  Result := true;
  RemoveResults := false;
  ConversionType := -1;
  if project.IsEmpty then exit;

  // Build up the TaskDialog's message indicating if choice of flow units,
  // pressure units or head loss model has changed.

  NewFlowUnits := TmpDefOptions[htFlowUnits];
  if not SameText(OldFlowUnits, NewFlowUnits) then
  begin
    Msg := rsFlowConvert + NewFlowUnits;
    OldFlowIndex := IndexText(OldFlowUnits, project.FlowUnitsStr);
    NewFlowIndex := IndexText(NewFlowUnits, project.FlowUnitsStr);
    // Index 5 is position in FlowUnitsStr array where metric flow units begin
    if (OldFlowIndex < 5) and (NewFlowIndex >= 5) then
      Msg := Msg + LineEnding + LineEnding + rsSIConvert
    else if (OldFlowIndex >= 5) and (NewFlowIndex < 5) then
      Msg := Msg + LineEnding + LineEnding + rsUSConvert;
  end;

  if not SameText(OldPressUnits, TmpDefOptions[htPressUnits]) then
  begin
    if Length(Msg) > 0 then Msg := Msg + LineEnding + LineEnding;
    Msg := Msg + rsPressConvert + TmpDefOptions[htPressUnits];
  end;

  if not SameText(OldHlossModel, NewHlossModel) then
  begin
    // Determine if project's head loss model was changed from/to C-M
    HlossModelChanged := true;
    if SameText(OldHlossModel, rsCM) or SameText(NewHlossModel, rsCM) then
      HasCMmodelChange := true;
    if Length(Msg) > 0 then Msg := Msg + LineEnding + LineEnding;
    Msg := Msg + rsHlossChanged + OldHlossModel + rsTo + NewHlossModel + '.' +
           LineEnding + rsChangeRough;
  end;

  if Length(Msg) = 0 then exit;
  Msg := rsSetupChanges + LineEnding + LineEnding + Msg;

  // Assign contents of the TaskDialog and execute it
  with TTaskDialog.Create(self) do
  try
    Caption := 'EPANET-UI';
    Title := rsConfirmSetup;
    Text := Msg;
    Flags := Flags + [tfPositionRelativeToWindow];
    MainIcon := tdiInformation;
    CommonButtons := [tcbOk, tcbCancel];
    DefaultButton := tcbOk;
    if project.HasResults then
      FooterText := rsResultsRemoved;

    // Create radio buttons for choosing how to change pipe roughness
    // values as a result of changing project's head loss model
    if HlossModelChanged then
    begin
      // Conversion formula option only applies to H-W and D-W models
      if not HasCMmodelChange then
        with RadioButtons.Add do
          Caption := rsConvertFormula;
      with RadioButtons.Add do
        Caption := rsDefaultRough + TmpDefProps[ptPipeRough];
      with RadioButtons.Add do
        Caption := rsNoRoughChange;
    end;

    if Execute then
    begin
      if ModalResult = mrOk then
      begin
        Result := true;
        RemoveResults := true;

        // Record how pipe roughness values should be changed
        // (adjusting for no conversion formula option for C-M model)
        if HlossModelChanged then
        begin
          ConversionType := RadioButton.Index;
          if HasCMmodelChange then Inc(ConversionType);
        end;
      end
      else Result := false;
    end;
  finally
    Free;
  end;
end;

procedure ConvertHWtoDW(NumLinks: Integer; var Roughness: array of Single);
//
//  Convert Hazen-Williams roughness coeffs. in Roughness to Darcy-Weisbach
//  coeffs. for each of NumLinks links.
//
var
  I:   Integer;
  X:   Single = 0;
  D:   Single = 0;   // Pipe diameter (meters)
  C:   Single;   // H-W C-Factor (dimensionless)
  E:   Single;   // D-W roughness height (meters)
  Dcf: Single;   // Pipe diameter units conversion factor
  Ecf: Single;   // D-W roughness units conversion factor
begin
  if GetUnitsSystem = usUS then
  begin
    Dcf := 0.0254;    // inches to meters
    Ecf := 39370;     // meters to millinches
  end
  else
  begin
    Dcf := 0.001;     // millimeters to meters
    Ecf := 1000;      // meters to millimeters
  end;

  for I := 1 to NumLinks do
  begin
    if project.GetLinkType(I) > ltPipe then continue;
    epanet2.ENgetlinkvalue(I, EN_DIAMETER, X);
    D := Dcf * X;
    C := Roughness[I];

    // Adams (2016) conversion formula (D & E in meters)
    E := (3.7 * D) * exp(-C * power(D, 0.068) / 13.9);
    Roughness[I] := E * Ecf;
  end;
end;

procedure ConvertDWtoHW(NumLinks: Integer; var Roughness: array of Single);
//
//  Convert Darcy-Weisbach roughness coeffs. in Roughness to Hazen-Williams
//  coeffs. for each of NumLinks links.
//
var
  I:   Integer;
  X:   Single = 0;
  D:   Single;   // Pipe diameter (meters)
  E:   Single;   // D-W roughness height (meters)
  C:   Single;   // H-W C-Factor (dimensionless)
  Ecf: Single;   // D-W roughness height conversion factor
  Dcf: Single;   // Pipe diameter units conversion factor
begin
  if GetUnitsSystem = usUS then
  begin
    Dcf := 25.4 * 0.001;  // inches to meters
    Ecf := Dcf / 1000;    // millinches to meters
  end
  else
  begin
    Dcf := 0.001;         // millimeters to meters
    Ecf := Dcf;
  end;

  for I := 1 to NumLinks do
  begin
    if project.GetLinkType(I) > ltPipe then continue;
    epanet2.ENgetlinkvalue(I, EN_DIAMETER, X);
    D := DCF * X;
    E := Roughness[I] * Ecf;

    // Adams (2016) conversion formula (D & E in meters)
    C := -13.9 * power(D, -0.068) * ln(E / 3.7 / D);
    Roughness[I] := C;
  end;
end;

procedure TProjectSetupForm.ConvertRoughness(ConversionType: Integer;
  NumLinks: Integer; var Roughness: array of Single);
//
//  Converts pipe roughness values from one head loss model to another.
//
//  Note: Conversion by formula is not available for a head loss model
//  change from/to the Chezy-Manning (C-M) model.
//
var
  I:                Integer;
  DefaultRoughness: Single;
begin
 if ConversionType = NoConversion then exit;

 if ConversionType = DefaultConversion then
 begin
   DefaultRoughness := StrToFloat(TmpDefProps[ptPipeRough]);
   for I := 1 to NumLinks do
     Roughness[I] := DefaultRoughness;
   exit;
 end;

 if ConversionType = FormulaConversion then
 begin
   if SameText(OldHlossModel, rsHW) and SameText(NewHlossModel, rsDW) then
     ConvertHWtoDW(NumLinks, Roughness)
   else if SameText(OldHlossModel, rsDW) and SameText(NewHlossModel, rsHW) then
     ConvertDWtoHW(NumLinks, Roughness);
 end;
end;

end.

