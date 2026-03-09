{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       properties
 Description:  retrieves property values of a project's objects
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit properties;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Dialogs, FileUtil, resourcestrings;

{$I ..\timetype.txt}

const
  HydOptionsProps: array[1..9] of string =
    (rsMaxTrials, rsAccuracy, rsHeadTol, rsFlowTol, rsUnbalanced, rsStatusRpt,
     'CHECKFREQ', 'MAXCHECK', 'DAMPLIMIT');

  DemandOptionsProps: array[1..8] of string =
    (rsProjDmndModel, rsDefPattern, rsDemandMult, rsServicePress,
     rsMinPressure, rsPressureExpon, rsEmitterExpon, rsEmitBackflow);

  QualOptionsProps: array[1..2] of string =
    (rsSingleSpecies, rsMultiSpecies);

  TimeOptionsProps: array[1..10] of string =
    (rsDuration, rsHydStep, rsQualStep, rsPatternStep, rsPatternStart,
     rsReportStep, rsReportStart, rsRuleStep, rsClockStart, rsStatistic);

  EnergyOptionsProps: array[1..4] of string =
    (rsPumpEfficiency, rsEnergyPrice, rsPricePattern, rsDemandCharge);

  JunctionProps: array[1..16] of string =
    (rsJunctionID, rsDescription, rsTag, rsElevation, rsBaseDemand,
     rsDemandPattern, rsDmndCategories, rsEmitterCoeff, rsInitQuality,
     rsSourceQuality, rsTotalDemand, rsDemandDeficit, rsEmitterFlow,
     rsLeakage, rsHydraulicHead, rsPressure);

  FirstJuncResultIndex = 11;

  ReservoirProps: array[1..9] of string =
    (rsReservoirID, rsDescription, rsTag, rsElevation, rsElevPattern,
     rsInitQuality, rsSourceQuality, rsOutflowRate, rsHydraulicHead);

  FirstResvResultIndex = 8;

  TankProps: array[1..19] of string =
     (rsTankID, rsDescription, rsTag, rsElevation, rsInitialDepth,
      rsMinimumDepth, rsMaximumDepth, rsDiameter, rsMinimumVolume,
      rsVolumeCurve, rsCanOverflow, rsMixingModel, rsMixingFraction,
      rsReactionCoeff, rsInitQuality, rsSourceQuality, rsInflowRate,
      rsHydraulicHead, rsWaterDepth);

  FirstTankResultIndex = 17;

  PipeProps: array[1..18] of string =
     (rsPipeID, rsStartNode, rsEndNode, rsDescription, rsTag, rsLength,
      rsDiameter, rsRoughness, rsLossCoeff, rsInitialStatus, rsBulkCoeff,
      rsWallCoeff, rsLeakArea, rsLeakExpansion, rsFlowRate, rsVelocity,
      rsHeadLoss, rsLeakage);

  FirstPipeResultIndex = 15;

  PumpProps: array[1..17] of string =
     (rsPumpID, rsStartNode, rsEndNode, rsDescription, rsTag, rsPumpCurve,
      rsPower, rsInitialSpeed, rsSpeedPattern, rsInitialStatus, rsEfficCurve,
      rsEnergyPrice, rsPricePattern, rsFlowRate, rsHeadAdded, rsSpeed,
      rsStatus);

  FirstPumpResultIndex = 14;

  ValveProps: array[1..16] of string =
     (rsValveID, rsStartNode, rsEndNode, rsDescription, rsTag, rsDiameter,
      rsValveType, rsInitialSetting, rsLossCoeff, rsPcvCurve, rsGpvCurve,
      rsFixedStatus, rsFlowRate, rsHeadLoss, rsSetting, rsStatus);

  FirstValveResultIndex = 13;

  LabelProps: array[1..4] of string =
     (rsText, rsFont, rsRotation, rsAnchorNode);

procedure GetHydProps;
procedure GetDemandProps;
procedure GetQualProps;
procedure GetTimeProps;
procedure GetEnergyProps;
procedure GetJuncProps(Index: Integer);
procedure GetResvProps(Index: Integer);
procedure GetTankProps(Index: Integer);
procedure GetPipeProps(Index: Integer);
procedure GetPumpProps(Index: Integer);
procedure GetValveProps(Index: Integer);
procedure GetLabelProps(Item: Integer);

procedure PasteNodeProps(const Index: Integer; const NodeType: Integer);
procedure PasteLinkProps(const Index: Integer; const LinkType: Integer);

procedure AddNodeResults(Index: Integer);
procedure AddPipeResults(Index: Integer);

implementation

uses
  project, config, maplabel, mapthemes, results, utils, epanet2;

procedure GetHydProps;
var
  X: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    epanet2.ENgetoption(EN_TRIALS, X);
    Add(IntToStr(Round(X)));

    epanet2.ENgetoption(EN_ACCURACY, X);
    Add(Float2Str(X, 8));

    epanet2.ENgetoption(EN_HEADERROR, X);
    Add(Float2Str(X, 8));

    epanet2.ENgetoption(EN_FLOWCHANGE, X);
    Add(Float2Str(X, 8));

    epanet2.ENgetoption(EN_EXTRA_ITER, X);
    if (X < 0) then Add(rsStop) else Add(rsContinue);

    epanet2.ENgetoption(EN_STATUS_REPORT, X);
    Add(StatusRptStr[Round(X)]);

    epanet2.ENgetoption(EN_CHECKFREQ, X);
    Add(IntToStr(Round(X)));

    epanet2.ENgetoption(EN_MAXCHECK, X);
    Add(IntToStr(Round(X)));

    epanet2.ENgetoption(EN_DAMPLIMIT, X);
    Add(Float2Str(X, 8));
  end;
end;

procedure GetQualProps;
var
  QualType: Integer = 0;
  ChemName: array[0..EN_MAXID] of AnsiChar = '';
  ChemUnits: array[0..EN_MAXID] of AnsiChar = '';
  TraceNodeIndex: Integer = 0;
  QualParam: AnsiString;
begin
  with project.Properties do
  begin
    Clear;
    Add('');
    epanet2.ENgetqualinfo(QualType, ChemName, ChemUnits, TraceNodeIndex);
    QualParam := project.QualModelStr[QualType];
    if MsxFlag then
    begin
      Add(rsNo);
      Add(rsYes);
    end
    else
    begin
      if QualType = 0 then
        Add(rsNo)
      else
        Add(QualParam);
      Add(rsNo);
    end;
  end;
end;

procedure GetDemandProps;
var
  X: Single = 0;
  DemandModel: Integer = 0;
  Pmin: Single = 0;
  Pmax: Single = 0;
  Pexp: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    epanet2.ENgetdemandmodel(DemandModel, Pmin, Pmax, Pexp);
    if DemandModel = 0 then Add('DDA') else Add('PDA');

    epanet2.ENgetoption(EN_DEMANDPATTERN, X);
    Add(project.GetID(ctPatterns, Round(X)));

    epanet2.ENgetoption(EN_DEMANDMULT, X);
    Add(Float2Str(X, 4));
    Add(Float2Str(Pmax, 4));
    Add(Float2Str(Pmin, 4));
    Add(Float2Str(Pexp, 4));

    epanet2.ENgetoption(EN_EMITEXPON, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetoption(EN_EMITBACKFLOW, X);
    if Round(X) = 0 then Add(rsNo) else Add(rsYes);
  end;
end;

procedure GetTimeProps;
var
  I: Integer;
  T: TimeType = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');
    for I := EN_DURATION to EN_RULESTEP do
    begin
      epanet2.ENgettimeparam(I, T);
      Add(Time2Str(T));
    end;
    epanet2.ENgettimeparam(EN_STARTTIME, T);
    Add(Time2Str(T));
    epanet2.ENgettimeparam(EN_STATISTIC, T);
    project.Properties.Add(project.StatisticStr[Round(T)]);
  end;
end;

procedure GetEnergyProps;
var
  X: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    epanet2.ENgetoption(EN_GLOBALEFFIC, X);
    Add(Float2Str(X, 2));

    epanet2.ENgetoption(EN_GLOBALPRICE, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetoption(EN_GLOBALPATTERN, X);
    Add(project.GetID(ctPatterns, Round(X)));

    epanet2.ENgetoption(EN_DEMANDCHARGE, X);
    Add(Float2Str(X, 4));
  end;
end;

procedure GetJuncProps(Index: Integer);
var
  I: Integer = 0;
  X: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    Add(project.GetID(ctNodes, Index));
    Add(project.GetComment(ctNodes, Index));
    Add(project.GetTag(ctNodes, Index));

    epanet2.ENgetnodevalue(Index, EN_ELEVATION, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_BASEDEMAND, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_PATTERN, X);
    Add(project.GetID(ctPatterns, Round(X)));

    epanet2.ENgetnumdemands(Index, I);
    Add(IntToStr(I));

    epanet2.ENgetnodevalue(Index, EN_EMITTER, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_INITQUAL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_SOURCEQUAL, X);
    Add(Float2Str(X, 4));

    AddNodeResults(Index);
  end;
end;

procedure GetResvProps(Index: Integer);
var
  X: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    Add(project.GetID(ctNodes, Index));
    Add(project.GetComment(ctNodes, Index));
    Add(project.GetTag(ctNodes, Index));

    epanet2.ENgetnodevalue(Index, EN_ELEVATION, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_PATTERN, X);
    Add(project.GetID(ctPatterns, Round(X)));

    epanet2.ENgetnodevalue(Index, EN_INITQUAL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_SOURCEQUAL, X);
    Add(Float2Str(X, 4));

    AddNodeResults(Index);
  end;
end;

procedure GetTankProps(Index: Integer);
var
  X: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');
    Add(project.GetID(ctNodes, Index));
    Add(project.GetComment(ctNodes, Index));
    Add(project.GetTag(ctNodes, Index));

    epanet2.ENgetnodevalue(Index, EN_ELEVATION, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_TANKLEVEL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_MINLEVEL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_MAXLEVEL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_TANKDIAM, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_MINVOLUME, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_VOLCURVE, X);
    Add(project.getID(ctCurves, Round(X)));
    
    epanet2.ENgetnodevalue(Index, EN_CANOVERFLOW, X);
    if (X = 1) then
      Add(project.NoYesStr[1])
    else
      Add(project.NoYesStr[0]);

    epanet2.ENgetnodevalue(Index, EN_MIXMODEL, X);
    Add(project.MixingModelStr[Round(X)]);

    epanet2.ENgetnodevalue(Index, EN_MIXFRACTION, X);
    if X < 0 then X := 0;
    if X > 1 then X := 1;
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_TANK_KBULK, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_INITQUAL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetnodevalue(Index, EN_SOURCEQUAL, X);
    Add(Float2Str(X, 4));

    AddNodeResults(Index);
  end;
end;

procedure AddNodeResults(Index: Integer);
var
  I: Integer;
  J: Integer;
  X: Single;
begin
  // Get the type of node (ntJunction, ntReservoir, or ntTank)
  J := project.GetNodeType(Index);

  // Loop through each result variable
  for I := mapthemes.FirstNodeResultTheme to
           mapthemes.FirstNodeQualTheme-1 do
  begin

    // Skip results that don't apply to non-Junction nodes
    if (J <> ntJunction)
    and (I in [ntDmndDfct, ntEmittance, ntLeakage]) then
      continue;

    // Retrieve the result value
    X := mapthemes.GetNodeValue(Index, I, mapthemes.TimePeriod);

    // Add the value to the properties displayed in the Property Editor
    with project.Properties do
    begin
      if X = MISSING then
        Add('N/A')
      else
      begin
        // Convert Tank pressure value to a water depth in feet
        if (project.GetUnitsSystem = usUS)
        and  (J = ntTank)
        and (I = ntPressure) then
        begin
          X := X / 0.4333
        end

        // Convert Reservoir demand to an outflow
        else if (J = ntReservoir)
        and (I = ntDemand) then
        begin
          X := -X;
        end;

        // Add the value as a string to the properties list
        Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));
      end;
    end;
  end;
end;

procedure GetPipeProps(Index: Integer);
var
  I: Integer = 0;
  J: Integer = 0;
  K: Integer;
  X: Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    Add(project.GetID(ctLinks, Index));
    project.GetLinkNodes(Index, I, J);
    Add(project.GetID(ctNodes, I));
    Add(project.GetID(ctNodes, J));
    Add(project.GetComment(ctLinks, Index));
    Add(project.GetTag(ctLinks, Index));

    epanet2.ENgetlinkvalue(Index, EN_LENGTH, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_DIAMETER, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_ROUGHNESS, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_MINORLOSS, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinktype(Index, K);
    if K = EN_CVPIPE then
      K := AnsiIndexText('CV', project.StatusStr)
    else
    begin
      epanet2.ENgetlinkvalue(Index, EN_INITSTATUS, X);
      K := Round(X);
    end;
    Add(project.StatusStr[K]);

    epanet2.ENgetlinkvalue(Index, EN_KBULK, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_KWALL, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_LEAK_AREA, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_LEAK_EXPAN, X);
    Add(Float2Str(X, 4));

    AddPipeResults(Index);
  end;
end;

procedure GetPumpProps(Index: Integer);
var
  I:    Integer = 0;
  J:    Integer = 0;
  X:    Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    Add(project.GetID(ctLinks, Index));
    project.GetLinkNodes(Index, I, J);
    Add(project.GetID(ctNodes, I));
    Add(project.GetID(ctNodes, J));
    Add(project.GetComment(ctLinks, Index));
    Add(project.GetTag(ctLinks, Index));

    epanet2.ENgetlinkvalue(Index, EN_PUMP_HCURVE, X);
    Add(project.GetID(ctCurves, Round(X)));

    epanet2.ENgetlinkvalue(Index, EN_PUMP_POWER, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_INITSETTING, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_LINKPATTERN, X);
    Add(project.GetID(ctPatterns, Round(X)));

    epanet2.ENgetlinkvalue(Index, EN_INITSTATUS, X);
    Add(project.StatusStr[Round(X)]);

    epanet2.ENgetlinkvalue(Index, EN_PUMP_ECURVE, X);
    Add(project.GetID(ctCurves, Round(X)));

    epanet2.ENgetlinkvalue(Index, EN_PUMP_ECOST, X);
    Add(Float2Str(X, 4));

    epanet2.ENgetlinkvalue(Index, EN_PUMP_EPAT, X);
    Add(project.GetID(ctPatterns, Round(X)));

    X := mapthemes.GetLinkValue(Index, ltFlow, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));

    X := mapthemes.GetLinkValue(Index, ltHeadloss, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(FloatToStrF(-X, ffFixed, 7, config.DecimalPlaces));

    X := mapthemes.GetLinkValue(Index, ltSetting, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));

    X := mapthemes.GetLinkValue(Index, ltStatus, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(mapthemes.GetStatusStr(Round(X)));

  end;
end;

procedure GetValveProps(Index: Integer);
var
  I:         Integer = 0;
  J:         Integer = 0;
  Status:    Integer;
  X:         Single = 0;
  Setting:   Single = 0;
begin
  with project.Properties do
  begin
    Clear;
    Add('');

    // Add valve ID, end nodes, comment & tag
    Add(project.GetID(ctLinks, Index));
    project.GetLinkNodes(Index, I, J);
    Add(project.GetID(ctNodes, I));
    Add(project.GetID(ctNodes, J));
    Add(project.GetComment(ctLinks, Index));
    Add(project.GetTag(ctLinks, Index));

    // Add diameter
    epanet2.ENgetlinkvalue(Index, EN_DIAMETER, X);
    Add(Float2Str(X, 4));

    // Add valve type
    epanet2.ENgetlinktype(Index, I);
    Add(project.ValveTypeStr[I-EN_PRV]);

    // Retrieve valve's setting and fixed status
    epanet2.ENgetlinkvalue(Index, EN_INITSETTING, Setting);
    epanet2.ENgetlinkvalue(Index, EN_INITSTATUS, X);
    Status := Round(X);

    // Add setting
    Add(Float2Str(Setting, 4));

    // Add minor loss coeff.
    epanet2.ENgetlinkvalue(Index, EN_MINORLOSS, X);
    Add(Float2Str(X, 4));

    // Add PCV curve
    if I = EN_PCV then
    begin
      epanet2.ENgetlinkvalue(Index, EN_PCV_CURVE, X);
      if X <= 0 then
        Add('')
      else
        Add(project.GetID(ctCurves, Round(X)));
    end
    else
      Add('');

    // Add GPV curve
    if I = EN_GPV then
    begin
      epanet2.ENgetlinkvalue(Index, EN_GPV_CURVE, X);
      if X <= 0 then
        Add('')
      else
        Add(project.GetID(ctCurves, Round(X)));
    end
    else
      Add('');

    // Add valve fixed status
    Add(project.ValveStatusStr[Status]);

    X := mapthemes.GetLinkValue(Index, ltFlow, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));

    X := mapthemes.GetLinkValue(Index, ltHeadloss, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));

    X := mapthemes.GetLinkValue(Index, ltSetting, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));

    X := mapthemes.GetLinkValue(Index, ltStatus, mapthemes.TimePeriod);
    if X = MISSING then
      Add(rsNA)
    else
      Add(mapthemes.GetStatusStr(Round(X)));

  end;
end;

procedure AddPipeResults(Index: Integer);
var
  I: Integer;
  X: Single;
begin

  for I := mapthemes.FirstLinkResultTheme to
           mapthemes.FirstLinkQualTheme-1 do
  begin
    X := mapthemes.GetLinkValue(Index, I, mapthemes.TimePeriod);
    with project.Properties do
    begin
      if X = MISSING then
        Add(rsNA)
      else
        Add(FloatToStrF(X, ffFixed, 7, config.DecimalPlaces));
     end;
  end;
end;

procedure GetLabelProps(Item: Integer);
var
  MapLabel: TMapLabel;
begin
  MapLabel := TMapLabel(project.MapLabels.Objects[Item]);
  with project.Properties do
  begin
    Clear;
    Add('');
    Add(project.MapLabels[Item]);
    Add(rsEdit);
    Add(IntToStr(MapLabel.Rotation));
    Add(MapLabel.AnchorNode);
  end;
end;

procedure PasteNodeProps(const Index: Integer; const NodeType: Integer);
var
  I: Integer;
  X: Single;
begin
  case NodeType of
    ntJunction:
      begin
        if utils.Str2Float(project.CopiedProperties[4], X) then
          epanet2.ENsetnodevalue(Index, EN_ELEVATION, X);
        if utils.Str2Float(project.CopiedProperties[5], X) then
          epanet2.ENsetnodevalue(Index, EN_BASEDEMAND, X);
        I := project.GetItemIndex(ctPatterns, project.CopiedProperties[6]);
        if I < 0 then I := 0;
        epanet2.ENsetdemandpattern(Index, 1, I);
        if utils.Str2Float(project.CopiedProperties[8], X) then
          epanet2.ENsetnodevalue(Index, EN_EMITTER, X);
        if utils.Str2Float(project.CopiedProperties[9], X) then
          epanet2.ENsetnodevalue(Index, EN_INITQUAL, X);
      end;

    ntReservoir:
      begin
        if utils.Str2Float(project.CopiedProperties[4], X) then
          epanet2.ENsetnodevalue(Index, EN_ELEVATION, X);
        I := project.GetItemIndex(ctPatterns, project.CopiedProperties[5]);
        if I < 0 then I := 0;
        epanet2.ENsetnodevalue(Index, EN_PATTERN, I);
        if utils.Str2Float(project.CopiedProperties[6], X) then
          epanet2.ENsetnodevalue(Index, EN_INITQUAL, X);
        end;

    ntTank:
      begin
        if utils.Str2Float(project.CopiedProperties[4], X) then
          epanet2.ENsetnodevalue(Index, EN_ELEVATION, X);
        if utils.Str2Float(project.CopiedProperties[5], X) then
          epanet2.ENsetnodevalue(Index, EN_TANKLEVEL, X);
        if utils.Str2Float(project.CopiedProperties[6], X) then
          epanet2.ENsetnodevalue(Index, EN_MINLEVEL, X);
        if utils.Str2Float(project.CopiedProperties[7], X) then
          epanet2.ENsetnodevalue(Index, EN_MAXLEVEL, X);
        if utils.Str2Float(project.CopiedProperties[8], X) then
          epanet2.ENsetnodevalue(Index, EN_DIAMETER, X);
        if utils.Str2Float(project.CopiedProperties[9], X) then
          epanet2.ENsetnodevalue(Index, EN_MINVOLUME, X);
        I := project.GetItemIndex(ctCurves, project.CopiedProperties[10]);
        if I < 0 then I := 0;
        epanet2.ENsetlinkvalue(Index, EN_VOLCURVE, I);
        I := AnsiIndexText(project.CopiedProperties[11], project.MixingModelStr);
        if I < 0 then I := 0;
        epanet2.ENsetnodevalue(Index, EN_MIXMODEL, I);
        if utils.Str2Float(project.CopiedProperties[12], X) then
          epanet2.ENsetnodevalue(Index, EN_MIXFRACTION, X);
        if utils.Str2Float(project.CopiedProperties[13], X) then
          epanet2.ENsetnodevalue(Index, EN_TANK_KBULK, X);
        if utils.Str2Float(project.CopiedProperties[14], X) then
          epanet2.ENsetnodevalue(Index, EN_INITQUAL, X);
      end;
  end;
end;

procedure PasteLinkProps(const Index: Integer; const LinkType: Integer);
var
  I: Integer;
  J: Integer;
  X: Single;
begin
  case LinkType of
    ltPipe:
      begin
        if utils.Str2Float(project.CopiedProperties[6], X) then
          epanet2.ENsetlinkvalue(Index, EN_LENGTH, X);
        if utils.Str2Float(project.CopiedProperties[7], X) then
          epanet2.ENsetlinkvalue(Index, EN_DIAMETER, X);
        if utils.Str2Float(project.CopiedProperties[8], X) then
          epanet2.ENsetlinkvalue(Index, EN_ROUGHNESS, X);
        if utils.Str2Float(project.CopiedProperties[9], X) then
          epanet2.ENsetlinkvalue(Index, EN_MINORLOSS, X);
        if utils.Str2Float(project.CopiedProperties[11], X) then
          epanet2.ENsetlinkvalue(Index, EN_KBULK, X);
        if utils.Str2Float(project.CopiedProperties[12], X) then
          epanet2.ENsetlinkvalue(Index, EN_KWALL, X);
        if utils.Str2Float(project.CopiedProperties[13], X) then
          epanet2.ENsetlinkvalue(Index, EN_LEAK_AREA, X);
        if utils.Str2Float(project.CopiedProperties[14], X) then
          epanet2.ENsetlinkvalue(Index, EN_LEAK_EXPAN, X);
      end;

    ltPump:
      begin
        if utils.Str2Float(project.CopiedProperties[7], X) then
          epanet2.ENsetlinkvalue(Index, EN_PUMP_POWER, X);
        if utils.Str2Float(project.CopiedProperties[8], X) then
          epanet2.ENsetlinkvalue(Index, EN_INITSETTING, X);
        if utils.Str2Float(project.CopiedProperties[12], X) then
          epanet2.ENsetlinkvalue(Index, EN_PUMP_ECOST, X);
        I := project.GetItemIndex(ctCurves, project.CopiedProperties[6]);
        if I < 0 then I := 0;
        epanet2.ENsetlinkvalue(Index, EN_PUMP_HCURVE, I);
        I := project.GetItemIndex(ctPatterns, project.CopiedProperties[9]);
        if I < 1 then I := 0;
        epanet2.ENsetlinkvalue(Index, EN_LINKPATTERN, I);
        I := project.GetItemIndex(ctCurves, project.CopiedProperties[11]);
        if I < 0 then I := 0;
        epanet2.ENsetlinkvalue(Index, EN_PUMP_ECURVE, I);
        I := project.GetItemIndex(ctCurves, project.CopiedProperties[13]);
        if I < 0 then I := 0;
        epanet2.ENsetlinkvalue(Index, EN_PUMP_EPAT, I);
      end;

    ltValve:
      begin
        if utils.Str2Float(project.CopiedProperties[6], X) then
          epanet2.ENsetlinkvalue(Index, EN_DIAMETER, X);
        I := EN_PRV + AnsiIndexText(project.CopiedProperties[7], project.ValveTypeStr);
        if I = EN_GPV then
        begin
          J := project.GetItemIndex(ctCurves, project.CopiedProperties[8]);
          if J < 0 then J := 0;
          epanet2.ENsetlinkvalue(Index, EN_INITSETTING, I);
        end
        else
        begin
          if utils.Str2Float(project.CopiedProperties[8], X) then
            epanet2.ENsetlinkvalue(Index, EN_INITSETTING, X);
        end;
        if utils.Str2Float(project.CopiedProperties[9], X) then
          epanet2.ENsetlinkvalue(Index, EN_MINORLOSS, X);
      end;
  end;
end;

end.

