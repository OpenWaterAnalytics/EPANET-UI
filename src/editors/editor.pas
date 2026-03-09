{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       editor
 Description:  edits the properties of a project's objects
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
{
 This unit works directly with the PropEditor control that appears on
 the main form's ProjectFrame.
}

unit editor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, ValEdit, Controls, LCLIntf, LCLtype, FileUtil;

var
  FirstResultRow: Integer;  // Row of the PropEditor where results are listed

procedure Edit(const Category: Integer; Item: Integer);
procedure EditTitleText;
procedure ButtonClick(const Category: Integer; const Item: Integer;
          const Prop: Integer);
function  Validate(const Category: Integer; const Item: Integer;
          const Prop: Integer; const OldValue: string; var NewValue: string): Boolean;
procedure PasteProperties(const Category: Integer; const ItemType: Integer;
          const Item: Integer);
procedure AdjustValveProperties(S: string);

implementation

uses
  main, project, projectframe, titleeditor, demandseditor, sourceeditor,
  controlseditor, ruleseditor, curveeditor, patterneditor, qualeditor,
  msxeditor, labeleditor, maplabel, mapthemes, properties, validator, epanet2,
  resourcestrings;

procedure EditDemands(const Index: Integer); forward;
procedure EditSourceQuality(const Index: Integer; const Row: Integer); forward;
procedure EditSimpleControls; forward;
procedure EditRuleControls; forward;
procedure EditLabelFont(const Item: Integer); forward;

procedure EditOptions(const Item: Integer); forward;
procedure EditHydraulOptions; forward;
procedure EditDemandOptions; forward;
procedure EditQualityOptions; forward;
procedure EditSingleSpecieQuality; forward;
procedure EditMultiSpeciesQuality; forward;
procedure EditTimeOptions; forward;
procedure EditEnergyOptions; forward;

procedure EditNode(const Item: Integer); forward;
procedure EditJunction(const Index: Integer); forward;
procedure EditReservoir(const Index: Integer); forward;
procedure EditTank(const Index: Integer); forward;

procedure EditLink(const Item: Integer); forward;
procedure EditPipe(const Index: Integer); forward;
procedure EditPump(const Index: Integer); forward;
procedure EditValve(const Index: Integer); forward;

procedure EditPatterns; forward;
procedure EditCurves; forward;
procedure EditControls(const Item: Integer); forward;
procedure EditLabel(const Item: Integer); forward;

function  GetDescription(S: string): string; forward;

procedure OptionButtonClick(const Item: Integer; const Prop: Integer); forward;
procedure NodeButtonClick(const Item: Integer; const Prop: Integer); forward;
procedure LinkButtonClick(const Item: Integer; const Prop: Integer); forward;
function  GetPatternSelection(PropIndex: Integer; PropValue: string): Integer; forward;
function  GetCurveSelection(PropIndex: Integer; PropValue: string): Integer; forward;

procedure ShowEditor(State: Boolean);
begin
  MainForm.ProjectFrame.PropertyPanel.Visible := State;
end;

procedure Edit(const Category: Integer; Item: Integer);
begin
  FirstResultRow := 0;
  case Category of
    ctOptions:
      EditOptions(Item);
    ctNodes:
      EditNode(Item);
    ctLinks:
      EditLink(Item);
    ctControls:
      EditControls(Item);
    ctPatterns:
      EditPatterns;
    ctCurves:
      EditCurves;
    ctLabels:
      EditLabel(Item);
    else
      ShowEditor(false);
  end;
end;

procedure ButtonClick(const Category: Integer; const Item: Integer;
          const Prop: Integer);
//
// Selects a specialized editor to launch when an ellipsis button
// in the PropEditor is clicked.
//
begin
  case Category of
    ctNodes:
      NodeButtonClick(Item, Prop);
    ctLinks:
      LinkButtonClick(Item, Prop);
    ctControls:
      if Prop = 1 then
        EditSimpleControls
      else
        EditRuleControls;
    ctLabels:
      EditLabelFont(Item);
    ctOptions:
      OptionButtonClick(Item, Prop);
  end;

  // Move to next row of Property Editor after done with specialized editor
  with MainForm.ProjectFrame.PropEditor do
  begin
    if Prop = RowCount -1 then
      Row := Prop-1
    else
      Row := Prop+1;
  end;
end;

procedure OptionButtonClick(const Item: Integer; const Prop: Integer);
var
  I: Integer;
  S: string;
  PropName: string;
begin
  PropName := MainForm.ProjectFrame.PropEditor.Cells[0,Prop];
  if PropName = rsPricePattern then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetPatternSelection(Prop, S);
    if I >= 0 then ENsetoption(EN_GLOBALPATTERN, I);
  end
  else if PropName = rsDefPattern then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetPatternSelection(Prop, S);
    if I >= 0 then ENsetoption(EN_DEMANDPATTERN, I);
  end
  else if Item = otQuality then
  begin
    if PropName = rsSingleSpecies then EditSingleSpecieQuality;
    if PropName = rsMultiSpecies then  EditMultiSpeciesQuality;
    MainForm.UpdateStatusBar(sbQuality, project.GetQualModelStr);
  end;
end;

procedure NodeButtonClick(const Item: Integer; const Prop: Integer);
var
  I: Integer;
  PropName: string;
  S: string;
begin
  PropName := MainForm.ProjectFrame.PropEditor.Cells[0,Prop];

  if PropName = rsDescription then
  begin
    with MainForm.ProjectFrame.PropEditor do
    begin
      S := Cells[1,Prop];
      S := GetDescription(S);
      if Cells[1,Prop] <> S then
      begin
        EditorMode := false;
        Cells[1,Prop] := S;
        EditorMode := true;
        ENsetcomment(EN_NODE, Item+1, PAnsiChar(S));
        project.HasChanged := true;
      end;
    end;
  end;

  if PropName = rsDmndCategories then
    EditDemands(Item+1)
  else if PropName = rsSourceQuality then
    EditSourceQuality(Item+1, Prop)
  else if PropName = rsVolumeCurve then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetCurveSelection(Prop, S);
    if I >= 0 then ENsetnodevalue(Item+1, EN_VOLCURVE, I);
  end
  else if (PropName = rsDemandPattern) or (PropName = rsElevPattern) then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetPatternSelection(Prop, S);
    if I >= 0 then ENsetnodevalue(Item+1, EN_PATTERN, I);
  end;
end;

procedure LinkButtonClick(const Item: Integer; const Prop: Integer);
var
  I: Integer;
  S: string;
  PropName: string;
begin
  PropName := MainForm.ProjectFrame.PropEditor.Cells[0,Prop];
  if PropName = rsDescription then
  begin
    with MainForm.ProjectFrame.PropEditor do
    begin
      S := Cells[1,Prop];
      S := GetDescription(S);
      if Cells[1,Prop] <> S then
      begin
        EditorMode := false;
        Cells[1,Prop] := S;
        EditorMode := true;
        ENsetcomment(EN_Link, Item+1, PAnsiChar(S));
        project.HasChanged := true;
      end;
    end;
  end;
  if PropName = rsPumpCurve then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetCurveSelection(Prop, S);
    if I >= 0 then ENsetlinkvalue(Item+1, EN_PUMP_HCURVE, I);
  end
  else if PropName = rsSpeedPattern then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetPatternSelection(Prop, S);
    if I >= 0 then ENsetlinkvalue(Item+1, EN_LINKPATTERN, I);
  end
  else if PropName = rsEfficCurve then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetCurveSelection(Prop, S);
    if I >= 0 then ENsetlinkvalue(Item+1, EN_PUMP_ECURVE, I);
  end
  else if PropName = rsPricePattern then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetPatternSelection(Prop, S);
    if I >= 0 then ENsetlinkvalue(Item+1, EN_PUMP_EPAT, I);
  end
  else if PropName = rsPcvCurve then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetCurveSelection(Prop, S);
    if I >= 0 then ENsetlinkvalue(Item+1, EN_PCV_CURVE, I);
  end
  else if PropName = rsGpvCurve then
  begin
    S := MainForm.ProjectFrame.PropEditor.Cells[1,Prop];
    I := GetCurveSelection(Prop, S);
    if I >= 0 then ENsetlinkvalue(Item+1, EN_GPV_CURVE, I);
  end;
end;

procedure EditCurves;
var
  CurveEditorForm: TCurveEditorForm;
begin
  CurveEditorForm := TCurveEditorForm.Create(MainForm);
  try
    CurveEditorForm.Setup('');
    CurveEditorForm.ShowModal;
  finally
    CurveEditorForm.Free;
  end;
end;

function GetCurveSelection(PropIndex: Integer; PropValue: string): Integer;
var
  CurveEditorForm: TCurveEditorForm;
begin
  Result := -1;
  CurveEditorForm := TCurveEditorForm.Create(MainForm);
  try
    CurveEditorForm.Setup(PropValue);
    CurveEditorForm.ShowModal;
    if CurveEditorForm.ModalResult = mrOK then
    begin
      with MainForm.ProjectFrame.PropEditor do
      begin
        if Cells[1,PropIndex] <> CurveEditorForm.SelectedName then
        begin
          EditorMode := false;
          Cells[1,PropIndex] := CurveEditorForm.SelectedName;
          EditorMode := true;
          project.HasChanged := true;
        end;
      end;
      Result := CurveEditorForm.SelectedIndex;
    end;
  finally
    CurveEditorForm.Free;
  end;
end;

procedure EditPatterns;
var
  PatternEditorForm: TPatternEditorForm;
begin
  PatternEditorForm := TPatternEditorForm.Create(MainForm);
  try
    PatternEditorForm.Setup('');
    PatternEditorForm.ShowModal;
  finally
    PatternEditorForm.Free;
  end;
end;

function GetPatternSelection(PropIndex: Integer; PropValue: string): Integer;
var
  PatternEditorForm: TPatternEditorForm;
begin
  Result := -1;
  PatternEditorForm := TPatternEditorForm.Create(MainForm);
  try
    PatternEditorForm.Setup(PropValue);
    PatternEditorForm.ShowModal;
    if PatternEditorForm.ModalResult = mrOK then
    begin
      with MainForm.ProjectFrame.PropEditor do
      begin
        if Cells[1,PropIndex] <> PatternEditorForm.SelectedName then
        begin
          EditorMode := false;
          Cells[1,PropIndex] := PatternEditorForm.SelectedName;
          EditorMode := true;
          project.HasChanged := true;
        end;
      end;
      Result := PatternEditorForm.SelectedIndex;
    end;
  finally
    PatternEditorForm.Free;
  end;
end;

function Validate(const Category: Integer; const Item: Integer;
  const Prop: Integer; const OldValue: string; var NewValue: string): Boolean;
begin
  Result := true;
  if NewValue = OldValue then exit;
  validator.HasChanged := true;
  validator.IsValid := true;
  case Category of
    ctOptions:
      validator.ValidateOption(Item, Prop, OldValue, NewValue);
    ctNodes:
      validator.ValidateNode(Item, Prop, OldValue, NewValue);
    ctLinks:
      validator.ValidateLink(Item, Prop, OldValue, NewValue);
    ctLabels:
      validator.ValidateLabel(Item, Prop, OldValue, NewValue);
  end;
  if validator.HasChanged then
  begin
    project.HasChanged := true;
    if Category <> ctLabels then project.UpdateResultsStatus;
  end;
  Result := validator.IsValid;
end;

procedure EditTitleText;
begin
  with TTitleEditorForm.Create(MainForm) do
  try
    ShowModal;
    if (ModalResult = mrOk)
    and HasChanged then
      project.HasChanged := true;
  finally
    Free;
  end;
end;

procedure EditDemands(const Index: Integer);
var
  Count: string = '';
  D1: string = '';
  P1: string = '';
begin
  with TDemandsEditorForm.Create(MainForm) do
  try
    LoadDemands(Index);
    ShowModal;
    if (ModalResult = mrOk)
    and hasChanged then
    begin
      project.HasChanged := true;
      project.UpdateResultsStatus;
    end;

    // After editing, update the cells of the PropEditor that
    // contain the primary demand, that demand's time pattern and
    // the total number of demands
    with MainForm.ProjectFrame.PropEditor do
    begin
      EditorMode := false;
      GetPrimaryDemandInfo(D1, P1, Count);
      Cells[1,5] := D1;
      Cells[1,6] := P1;
      Cells[1,7] := Count;
      EditorMode := true;
    end;
  finally
    Free;
  end;
end;

procedure EditSingleSpecieQuality;
var
  QualType: Integer = 0;
  ChemName: array[0..EN_MAXID] of AnsiChar;
  ChemUnits: array[0..EN_MAXID] of AnsiChar;
  TraceNodeIndex: Integer = 0;
begin
  with TQualEditorForm.Create(MainForm) do
  try
    ShowModal;
    if ModalResult = mrOK then
    begin
      epanet2.ENgetqualinfo(QualType, ChemName, ChemUnits, TraceNodeIndex);
      with MainForm.ProjectFrame.PropEditor do
      begin
        EditorMode := False;
        if QualType = 0 then
          Cells[1,1] := rsNo
        else
          Cells[1,1] := project.QualModelStr[QualType];
        Cells[1,2] := rsNo;
        EditorMode := True;
        if HasChanged then
        begin
          project.HasChanged := true;
          project.UpdateResultsStatus;
        end;
      end;
      if project.MsxFlag then
        project.HasChanged := true;
      project.MsxFlag := false;
    end;
  finally
    Free;
  end;
end;

procedure EditMultiSpeciesQuality;
var
  MsxFile:     string;
  ChangesMade: Boolean = false;
begin
  with TMsxEditorForm.Create(MainForm) do
  try
    SetMsxFile(project.MsxInpFile);
    ShowModal;
    if ModalResult = mrOK then
    begin
      // MsxFile is empty - switch to single species
      GetMsxFile(MsxFile);
      if (Length(MsxFile) = 0) then
      begin
        if MsxFlag then ChangesMade := true;
        MsxFlag := false;
        MsxInpFile := MsxFile;
      end

      // MsxFile <> MsxInpFile or edits were made
      else if (not SameText(MsxFile, MsxInpFile)) or HasChanged then
      begin
        MsxInpFile := MsxFile;
        ChangesMade := true;
        MsxFlag := true;
      end;

      // Update project's HasChanged status
      if ChangesMade then
      begin
        project.HasChanged := true;
        project.UpdateResultsStatus;
      end;

      // Update property editor
      with MainForm.ProjectFrame.PropEditor do
      begin
        EditorMode := false;
        if MsxFlag then
        begin
          Cells[1,1] := rsNo;
          Cells[1,2] := rsYes;
        end
        else
        begin
          Cells[1,1] := rsNo;
          Cells[1,2] := rsNo;
        end;
        EditorMode := true;
      end;

      // If in MSX mode then remove any single species choice
      if MsxFlag then epanet2.ENsetqualtype(0, '', '', '');
    end;
  finally
    Free;
  end;
end;

procedure EditSourceQuality(const Index: Integer; const Row: Integer);
begin
  with TSourceEditorForm.Create(MainForm) do
  try
    LoadSource(Index);
    ShowModal;
    if (ModalResult = mrOk) then
    begin
      if HasChanged then
      begin
        project.HasChanged := true;
        project.UpdateResultsStatus;
      end;

      // After editing, update the cell of the Property Editor that
      // displays the source's strength
      with MainForm.ProjectFrame.PropEditor do
      begin
        EditorMode := false;
        Cells[1,Row] := GetSourceStrength;
        EditorMode := true;
      end;
    end;
  finally
    Free;
  end;
end;

procedure EditOptions(const Item: Integer);
begin
  case Item of
    otHydraul:
      EditHydraulOptions;
    otDemands:
      EditDemandOptions;
    otQuality:
      EditQualityOptions;
    otTimes:
      EditTimeOptions;
    otEnergy:
      EditEnergyOptions;
  end;
end;

procedure EditHydraulOptions;
var
  I: Integer;
  OptionList: TStringList;
begin
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      Clear;
      properties.GetHydProps;
      RowCount := 1;
      for I := 1 to High(HydOptionsProps) do
      begin
        Strings.AddPair(HydOptionsProps[I], project.Properties[I]);
      end;
      OptionList.Clear;
      OptionList.Add(rsStop);
      OptionList.Add(rsContinue);
      with ItemProps[rsUnbalanced] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      OptionList.AddStrings(project.StatusRptStr, true);
      with ItemProps[rsStatusRpt] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      Row := 1;
      Show;
    end;
  finally
    OptionList.Free;
  end;
end;

procedure EditQualityOptions;
var
  I: Integer;
begin
  with MainForm.ProjectFrame.PropEditor do
  begin
    properties.GetQualProps;
    Clear;
    RowCount := 1;
    for I := 1 to High(properties.QualOptionsProps) do
    begin
      Strings.AddPair(properties.QualOptionsProps[I], project.Properties[I]);
    end;
    with ItemProps[rsSingleSpecies] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    with ItemProps[rsMultiSpecies] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    Row := 1;
  end;
end;

procedure EditDemandOptions;
var
  I: Integer;
  OptionList: TStringList;
begin
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      properties.GetDemandProps;
      Clear;
      RowCount := 1;
      for I := 1 to High(properties.DemandOptionsProps) do
      begin
        Strings.AddPair(properties.DemandOptionsProps[I], project.Properties[I]);
      end;
      OptionList.Add(rsDDA);
      OptionList.Add(rsPDA);
      with ItemProps[rsProjDmndModel] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      with ItemProps[rsDefPattern] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      OptionList.AddStrings(project.NoYesStr, true);
      with ItemProps[rsEmitBackFlow] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      Row := 1;
      Show;
   end;
  finally
    OptionList.Free;
  end;
end;

procedure EditTimeOptions;
var
  I: Integer;
  OptionList: TStringList;
begin
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      properties.GetTimeProps;
      Clear;
      RowCount := 1;
      for I := 1 to High(properties.TimeOptionsProps) do
      begin
        Strings.AddPair(properties.TimeOptionsProps[I], project.Properties[I]);
      end;
      OptionList.AddStrings(project.StatisticStr, true);
      with ItemProps[rsStatistic] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      Row := 1;
      Show;
    end;
  finally
    OptionList.Free;
  end;
end;

procedure EditEnergyOptions;
var
  I: Integer;
begin
  with MainForm.ProjectFrame.PropEditor do
  begin
    properties.GetEnergyProps;
    Clear;
    RowCount := 1;
    for I := 1 to High(properties.EnergyOptionsProps) do
    begin
      Strings.AddPair(properties.EnergyOptionsProps[I], project.Properties[I]);
    end;
    with ItemProps[rsPricePattern] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    Row := 1;
    Show;
  end;
end;

procedure EditNode(const Item: Integer);
var
  NodeType: Integer;
  Index: Integer;
  CurrentRow: Integer;
begin
  MainForm.ProjectFrame.PropEditor.Hide;
  CurrentRow := MainForm.ProjectFrame.PreviousRow;
  Index := Item+1;
  NodeType := project.GetNodeType(Index);
  case NodeType of
    ntJunction:
      EditJunction(Index);
    ntReservoir:
      EditReservoir(Index);
    ntTank:
      EditTank(Index);
  end;
  with MainForm.ProjectFrame.PropEditor do
  begin
    if RowCount >= CurrentRow then
      Row := CurrentRow
    else
      Row := 1;
    Show;
  end;
end;

procedure EditJunction(const Index: Integer);
var
  I: Integer;
begin
  FirstResultRow := properties.FirstJuncResultIndex;
  with MainForm.ProjectFrame.PropEditor do
  begin
    properties.GetJuncProps(Index);
    Clear;
    RowCount := 1;
    for I := 1 to High(properties.JunctionProps) do
    begin
      Strings.AddPair(properties.JunctionProps[I], project.Properties[I]);
    end;
    with ItemProps[rsDescription] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    with ItemProps[rsDemandPattern] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    with ItemProps[rsDmndCategories] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    with ItemProps[rsSourceQuality] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    for I := FirstResultRow to High(properties.JunctionProps) do
      ItemProps[properties.JunctionProps[I]].ReadOnly := true;
  end;
end;

procedure EditReservoir(const Index: Integer);
var
  I: Integer;
begin
  FirstResultRow := properties.FirstResvResultIndex;
  with MainForm.ProjectFrame.PropEditor do
  begin
    properties.GetResvProps(Index);
    Clear;
    RowCount := 1;
    for I := 1 to High(properties.ReservoirProps) do
    begin
      Strings.AddPair(properties.ReservoirProps[I], project.Properties[I]);
    end;
    with ItemProps[rsDescription] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    with ItemProps[rsElevPattern] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    with ItemProps[rsSourceQuality] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
    for I := FirstResultRow to High(properties.ReservoirProps) do
      ItemProps[properties.ReservoirProps[I]].ReadOnly := true;
  end;
end;

procedure EditTank(const Index: Integer);
var
  I: Integer;
  OptionList: TStringList;
begin
  FirstResultRow := properties.FirstTankResultIndex;
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      properties.GetTankProps(Index);
      Clear;
      RowCount := 1;
      for I := 1 to High(properties.TankProps) do
      begin
        Strings.AddPair(properties.TankProps[I], project.Properties[I]);
      end;
    with ItemProps[rsDescription] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
      with ItemProps[rsVolumeCurve] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      OptionList.AddStrings(project.NoYesStr, true);
      with ItemProps[rsCanOverflow] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      OptionList.AddStrings(project.MixingModelStr, true);
      with ItemProps[rsMixingModel] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      with ItemProps[rsSourceQuality] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      for I := FirstResultRow to High(properties.TankProps) do
        ItemProps[properties.TankProps[I]].ReadOnly := true;;
    end;
  finally
    OptionList.Free;
  end;
end;

procedure EditLink(const Item: Integer);
var
  LinkType: Integer;
  Index: Integer;
  CurrentRow: Integer;
begin
  MainForm.ProjectFrame.PropEditor.Hide;
  CurrentRow := MainForm.ProjectFrame.PreviousRow;
  Index := Item+1;
  LinkType := project.GetLinkType(Index);
  case LinkType of
    ltCVPipe,
    ltPipe:
      EditPipe(Index);
    ltPump:
      EditPump(Index);
    ltValve:
      EditValve(Index);
  end;
  with MainForm.ProjectFrame.PropEditor do
  begin
    if RowCount >= CurrentRow then
      Row := CurrentRow
    else
      Row := 1;
    Show;
  end;
end;

procedure EditPipe(const Index: Integer);
var
  I: Integer;
  OptionList: TStringList;
begin
  FirstResultRow := properties.FirstPipeResultIndex;
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      properties.GetPipeProps(Index);
      Clear;
      RowCount := 1;
      for I := 1 to High(properties.PipeProps) do
      begin
        Strings.AddPair(properties.PipeProps[I], project.Properties[I]);
      end;
      OptionList.AddStrings(project.StatusStr, true);
      with ItemProps[rsDescription] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      with ItemProps[rsInitialStatus] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      for I := FirstResultRow to High(properties.PipeProps) do
      begin
        ItemProps[properties.PipeProps[I]].ReadOnly := true;
      end;
    end;
  finally
    OptionList.Free;
  end;
end;

procedure EditPump(const Index: Integer);
var
  I: Integer;
  OptionList: TStringList;
begin
  FirstResultRow := properties.FirstPumpResultIndex;
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      properties.GetPumpProps(Index);
      Clear;
      RowCount := 1;
      for I := 1 to High(properties.PumpProps) do
      begin
        Strings.AddPair(properties.PumpProps[I], project.Properties[I]);
      end;
      with ItemProps[rsDescription] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      with ItemProps[rsPumpCurve] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      with ItemProps[rsSpeedPattern] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      OptionList.Add(project.StatusStr[0]);
      OptionList.Add(project.StatusStr[1]);
      with ItemProps[rsInitialStatus] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      with ItemProps[rsEfficCurve] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      with ItemProps[rsPricePattern] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      for I := FirstResultRow to High(properties.PumpProps) do
      begin
        ItemProps[properties.PumpProps[I]].ReadOnly := true;
      end;
    end;
  finally
    OptionList.Free;
  end;
end;

procedure EditValve(const Index: Integer);
var
  I: Integer;
  OptionList: TStringList;
begin
  FirstResultRow := properties.FirstValveResultIndex;
  OptionList := TStringList.Create;
  try
    with MainForm.ProjectFrame.PropEditor do
    begin
      properties.GetValveProps(Index);
      Clear;
      RowCount := 1;
      for I := 1 to High(properties.ValveProps) do
      begin
        Strings.AddPair(properties.ValveProps[I], project.Properties[I]);
      end;
      ItemProps[rsSetting].ReadOnly := SameText(project.Properties[7], 'GPV');
      OptionList.AddStrings(project.ValveTypeStr, true);
      with ItemProps[rsDescription] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      with ItemProps[rsValveType] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      OptionList.AddStrings(project.ValveStatusStr, true);
      with ItemProps[rsFixedStatus] do
      begin
        EditStyle := esPickList;
        PickList := OptionList;
        ReadOnly := true;
      end;
      with ItemProps[rsPcvCurve] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      with ItemProps[rsGpvCurve] do
      begin
        EditStyle := esEllipsis;
        ReadOnly := true;
      end;
      for I := FirstResultRow to High(properties.ValveProps) do
      begin
        ItemProps[properties.ValveProps[I]].ReadOnly := true;
      end;
    end;
    AdjustValveProperties(project.Properties[7]);
  finally
    OptionList.Free;
  end;
end;

procedure AdjustValveProperties(S: string);
begin
  with MainForm.ProjectFrame.PropEditor do
  begin
    EditorMode := false;
    if SameText(S, 'GPV') then
    begin
      Cells[1,8] := rsSeeGPVCurve;
      ItemProps[rsSetting].ReadOnly := true;
    end
    else
    begin
      Cells[1,8] := project.Properties[8];
      ItemProps[rsSetting].ReadOnly := false;
    end;
    EditorMode := true;
  end;
end;

procedure EditControls(const Item: Integer);
begin
  case Item of
    0:
      EditSimpleControls;
    1:
      EditRuleControls;
  end;
end;

procedure EditSimpleControls;
begin
  with ControlsEditorForm do
  begin
    LoadControls;
    Show;
  end;
end;

procedure EditRuleControls;
begin
  with RulesEditorForm do
  begin
    LoadRules;
    Show;
  end;
end;

procedure EditLabel(const Item: Integer);
var
  I: Integer;
begin
  with MainForm.ProjectFrame.PropEditor do
  begin
    properties.GetLabelProps(Item);
    Clear;
    RowCount := 1;
    for I := 1 to High(properties.LabelProps) do
    begin
      Strings.AddPair(properties.LabelProps[I], project.Properties[I]);
    end;
    with ItemProps[rsFont] do
    begin
      EditStyle := esEllipsis;
      ReadOnly := true;
    end;
  end;
end;

function GetDescription(S: string): string;
var
  LabelEditorForm: TLabelEditorForm;
  L:               Integer;        // Left of LabelEditorForm
  T:               Integer;        // Top of LabelEditorForm
  W:               Integer = 400;  // Width of LabelEditorForm
  Wsb:             Integer = 0;    // Width of scrollbar
  P:               TPoint;
begin
  // Default result
  Result := S;

  // Get width of PropEditor's scroll bar if visible
  with MainForm.ProjectFrame.PropEditor do
  begin
    if DefaultRowHeight * RowCount > ClientHeight then
      Wsb := GetSystemMetrics(SM_CXVSCROLL);
      T := (Row - TopRow +1) * DefaultRowHeight;
  end;

  // Position LabelEditorForm so it ends at right side of the PropEditor
  with MainForm.ProjectFrame do
    P := ClientToScreen(Point(Width, 0));
  L := P.X - W - Wsb;

  // Position LabelEditorForm so it starts at top point T of the PropEditor
  P := MainForm.ProjectFrame.PropEditor.ClientToScreen(Point(0, T));
  T := P.Y;

  // Create borderless TLabelEditorForm
  LabelEditorForm := TLabelEditorForm.Create(MainForm.MapFrame);
  with LabelEditorForm do
  try
    // Position the form so it overlays the PropEditor's Description field
    Left := L;
    Top := T;
    Width := W;

    // Initialize the contents of the form's Edit1 control
    Edit1.MaxLength := epanet2.EN_MAXMSG;
    Edit1.Text := S;

    // Get user's input
    if ShowModal = mrOK then Result := Edit1.Text;
  finally
    Free;
  end;
end;

procedure EditLabelFont(const Item: Integer);
var
  MapLabel : TMapLabel;
begin
  MapLabel := TMapLabel(project.MapLabels.Objects[Item]);
  if Maplabel <> nil then with MainForm.FontDialog1 do
  begin
    Font.Assign(MapLabel.Font);
    if Execute then
    begin
      if MapLabel.Font <> Font then project.HasChanged := True;
      MapLabel.Font.Assign(Font);
      MainForm.MapFrame.RedrawMapLabels;
    end;
  end;
end;

procedure PasteProperties(const Category: Integer; const ItemType: Integer;
  const Item: Integer);
begin
  if Category = ctNodes then
  begin
    properties.PasteNodeProps(Item + 1, ItemType);
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end
  else if Category = ctLinks then
  begin
    properties.PasteLinkProps(Item + 1, ItemType);
    project.HasChanged := true;
    project.UpdateResultsStatus;
  end;
end;

end.

