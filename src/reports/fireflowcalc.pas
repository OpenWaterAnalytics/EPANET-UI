{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       fireflow.pas
 Description:  calculates fire flows for the project
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit fireflowcalc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Math, Grids;

type
  TFireFlowResult = record
    FireNode:        Integer;
    StaticPress:     Single;
    DesignFlowPress: Single;
    AvailableFlow:   Single;
    CriticalPress:   Single;
    CriticalNode:    Integer;
  end;

var
  FireFlowResults: array of TFireFlowResult;

procedure Open(DesignQ, DesignP: Single; Duration: Integer;
  FireNodes: array of Integer; PressZoneType: Integer);

procedure Close;

function FindAllFireFlows: Integer;

procedure FindFireFlow(I: Integer);

procedure SortResults(SortIndex: Integer; SortOrder: TSortOrder);

implementation

uses
  main, project, epanet2, reportviewer, fireflowrpt, fireflowprogress,
  resourcestrings;

// Definition of TimeType (seconds) depending on OS
{$I ..\timetype.txt}

const
  PressUcf: array[0..4] of Single =
    (1.0,
     6.894745,     // KPAperPSI
     0.70325,      // MperPSI
     0.06894745,   // BARperPSI
     2.306645);    // FTperPSI

var
  FireTime:         Integer;
  FireNodeIndex:    Integer;
  DesignFlow:       Single;
  DesignPressure:   Single;
  ResidualPressure: Single;
  CriticalPressure: Single;
  CriticalNode:     Integer;
  NumFireNodes:     Integer;
  PressZone:        Integer;
  StaticPressures:  array of Single;
  SavedDuration:    TimeType;
  SavedReporting:   TimeType;
  UcfFlow:          Single;
  UcfPressure:      Single;
  PatternFactor:    Single;

procedure SetPatternFactor;
var
  PatternIndex:  Integer = -1;
  PatternStep:   TimeType = 1;
  PatternStart:  TimeType = 0;
  PatternLength: Integer = 1;
  PatternPeriod: Integer;
  P:             Single = 0;
begin
  // Get index of primary demand pattern for fire flow node
  PatternFactor := 1.0;
  ENgetdemandpattern(FireNodeIndex, 1, PatternIndex);

  // If node has no pattern then get index of global default pattern
  if PatternIndex = 0 then
  begin
    ENgetoption(EN_DEMANDPATTERN, P);
    PatternIndex := Round(P);
  end;

  // If a demand pattern exists, find its factor for the time of the fire
  if PatternIndex > 0 then
  begin
    ENgettimeparam(EN_PATTERNSTEP, PatternStep);
    ENgettimeparam(EN_PATTERNSTART, PatternStart);
    ENgetpatternlen(PatternIndex, PatternLength);
    PatternPeriod := (FireTime + PatternStart) DIV PatternStep;
    PatternPeriod := (PatternPeriod mod PatternLength);

    // Pattern periods start at 1
    Inc(PatternPeriod);
    ENgetpatternvalue(PatternIndex, PatternPeriod, PatternFactor);
    if PatternFactor = 0 then
      PatternFactor := 1.0;
  end;
end;

function RunSolver(Q: Single): Integer;
//
// Run EPANET hydraulic solver up to time at which fire flow occurs
// at which point fire flow Q is added to fire node's base demand.
//
var
  T:           TimeType;         // Elapsed solution time
  Tstep:       TimeType;         // Next time step taken
  ErrorCode:   Integer = 0;
  SavedDemand: Single = 0;

begin
  // Save base demand for fire node
  Result := 0;
  if Q <> 0 then
    epanet2.ENgetbasedemand(FireNodeIndex, 1, SavedDemand);

  // Initialize EPANET's hydraulic solver
  epanet2.ENinitH(EN_NOSAVE);
  T := 0;
  Tstep := 0;

  // Solve for hydraulics up to the time when fire occurs
  try
    try
      repeat

        // Time for fire flow has been reached
        if T >= FireTime then
        begin
          // Add pattern adjusted fire flow to fire node's base demand
          if Q <> 0 then
            ENsetbasedemand(FireNodeIndex, 1, (SavedDemand + Q/Patternfactor));

          // Solve for network hydraulics
          ErrorCode := epanet2.ENrunH(T);

          // End simulation run
          break;
        end;

        // Haven't reached fire time yet; solve hydraulics for next time period
        ErrorCode := epanet2.ENrunH(T);
        if ErrorCode = 0 then
          ErrorCode := epanet2.ENnextH(Tstep);
      until (Tstep = 0)     // normal termination
      or (ErrorCode > 100); // fatal error occurred

      if ErrorCode > 100 then
      begin
        Result := ErrorCode;
        exit;
      end;


    except
      on E: Exception do
        Result := 110;  // "Cannot Solve Network Equations" error
    end;

  finally
    // Restore node's original base demand
    if Q <> 0 then
      ENsetbasedemand(FireNodeIndex, 1, SavedDemand);
  end;
end;

procedure SearchPressureZone;
var
  I:         Integer;
  N:         Integer;
  NodeIndex: Integer;
  Pressure:  Single = 0;
begin
  if PressZone = fireflowrpt.FireFlowSet then
    N := NumFireNodes
  else
    N := project.GetItemCount(ctNodes);
  for I := 0 to N-1 do
  begin
    if StaticPressures[I] < DesignPressure then continue;
    if PressZone = fireflowrpt.FireFlowSet then
      NodeIndex := FireFlowResults[I].FireNode
    else
    begin
      NodeIndex := I + 1;
      if project.GetNodeType(NodeIndex) <> ntJunction then
        continue;
    end;
    ENgetnodevalue(NodeIndex, EN_PRESSURE, Pressure);
    if Pressure < CriticalPressure then
    begin
      CriticalPressure := Pressure;
      CriticalNode := NodeIndex;
    end;
  end;
end;

function FindCriticalPressure(Q: Single): Integer;
var
  Pressure: Single = 0;
begin
  // Solve network hydraulics with fire flow Q
  Result := RunSolver(Q);
  if Result <> 0 then exit;

  // Find minimum pressure within fire flow pressure zone
  ENgetnodevalue(FireNodeIndex, EN_PRESSURE, Pressure);
  ResidualPressure := Pressure;
  CriticalPressure := Pressure;
  CriticalNode := FireNodeIndex;
  if PressZone <> fireflowrpt.NoPressZone then
    SearchPressureZone;
end;

// False Position Search (not used because slower than Ridder Search)
function FP_Search(Q1, Q2, P1, P2: Double; var Qavail: Double): Integer;
var
  Phi, Plow, Pnew, Qhi, Qlow, Qnew, Dq, Del: Double;
  J: Integer;
begin
  Result := 0;
  Qavail := 0;
  Plow := P2;
  Phi := P1;
  Qlow := Q2;
  Qhi := Q1;
  Dq := Qhi - Qlow;
  for J := 1 to 10 do
  begin
    Qnew := Qlow + Dq * Plow / (Plow - Phi);
    Result := FindCriticalPressure(Qnew);
    if Result > 0 then exit;
    Pnew := CriticalPressure - DesignPressure;
    if Pnew < 0 then
    begin
      Del := Qlow - Qnew;
      Qlow := Qnew;
      Plow := Pnew;
    end
    else
    begin
      Del := Qhi -Qnew;
      Qhi := Qnew;
      Phi := Pnew;
    end;
    Dq := Qhi - Qlow;
    if (abs(Del) < 1)
    or (abs(Pnew) < 0.1) then
    begin
      Qavail := Qnew;
      exit;
    end;
  end;
end;

function Search(Q1, Q2, P1, P2: Single; var Qavail: Single): Integer;
//
// For the current fire node, find its available fire flow Qavail between Q1
// and Q2 with residual pressures P1 and P2 that meet a minimum pressure limit
// using Ridder's method.
//
var
  Phi, Pmid, Plow, Pnew, S, Qhi, Qmid, Qlow, Qnew, Dq: Single;
  J: Integer;
begin
  Qlow := Q1;
  Qhi := Q2;
  Plow := P1;
  Phi := P2;
  Result := 0;
  Qavail := 0;
  for J := 1 to 10 do
  begin
    Qmid := 0.5 * (Qlow + Qhi);
    Result := FindCriticalPressure(Qmid);
    if Result > 0 then exit;
    Pmid := CriticalPressure - DesignPressure;
    if Abs(Pmid) < 0.1 then
    begin
      Qavail := Qmid;
      break;
    end;
    S := Pmid * Pmid - Plow * Phi;
    if S <= 0.0 then exit;
    S := Sqrt(S);
    Dq := (Qmid - Qlow) * Pmid / S;
    if Plow < Phi then Dq := -Dq;
    Qnew := Qmid + Dq;
    Qavail := Qnew;
    Result := FindCriticalPressure(Qnew);
    if Result > 0 then exit;
    Pnew := CriticalPressure - DesignPressure;
    if Abs(Pnew) < 0.1 then
    begin
      break;
    end;

    if Abs(Pmid) * Sign(Pnew) <> Pmid then
    begin
      Qlow := Qmid;
      Plow := Pmid;
      Qhi := Qnew;
      Phi := Pnew;
    end
    else if Abs(Plow) * Sign(Pnew) <> Plow then
    begin
      Qhi := Qnew;
      Phi := Pnew;
    end
    else if Abs(Phi) * Sign(Pnew) <> Phi then
    begin
      Qlow := Qnew;
      Plow := Pnew;
    end
    else
      break;
  end;
end;

function RunStaticAnalysis: Integer;
var
  I: Integer;
  J: Integer;
  P: Single = 0;
begin
  Result := RunSolver(0);
  if Result <> 0 then
    exit;

  for I := 0 to NumFireNodes - 1 do
  begin
    J := FireFlowResults[I].FireNode;
    ENgetnodevalue(J, EN_PRESSURE, P);
    FireFlowResults[I].StaticPress := P;
  end;

  if PressZone <> NoPressZone then
  begin
    for I := 0 to Length(StaticPressures) - 1 do
    begin
      if PressZone = FireFlowSet then
        J := FireFlowResults[I].FireNode
      else
        J := I + 1;
      ENgetnodevalue(J, EN_PRESSURE, P);
      StaticPressures[I] := P;
    end;
  end;
end;

function GetUcfFlow: Single;
begin
  if project.GetUnitsSystem = usUS then
     Result := project.FlowUcf[project.FlowUnits] / project.FlowUcf[EN_GPM]
  else
    Result := project.FlowUcf[project.FlowUnits] / project.FlowUcf[EN_LPM];
end;

function GetUcfPressure: Single;
begin
  Result := PressUcf[project.PressUnits]; // Pressure units per PSI
  if project.GetUnitsSystem = usSI then
    Result := Result / PressUcf[EN_KPA];  // Pressure units per kPa
end;

procedure Open(DesignQ, DesignP: Single; Duration: Integer;
  FireNodes: array of Integer; PressZoneType: Integer);
var
  I: Integer;
  Xrpt: Single = 0;
begin
  // Find unit conversion factors
  UcfFlow := GetUcfFlow;
  UcfPressure := GetUcfPressure;

  // Save fire flow selections
  DesignFlow := DesignQ * UcfFlow;
  DesignPressure := DesignP * UcfPressure;
  FireTime := Duration;
  PressZone := PressZoneType;

  // Save indices of nodes selected for fire flow analysis
  NumFireNodes := Length(FireNodes);
  SetLength(FireFlowResults, NumFireNodes);
  for I := 0 to NumFireNodes - 1 do
  begin
    FireFlowResults[I].FireNode := FireNodes[I];
  end;

  // Create array to hold static pressure of nodes in fire flow pressure zone
  if PressZone = FireFlowSet then
    SetLength(StaticPressures, NumFireNodes)
  else if PressZone = AllNodes then
    SetLength(StaticPressures, project.GetItemCount(ctNodes));

  // Change duration to some time after fire occurs
  ENgettimeparam(EN_DURATION, SavedDuration);
  ENsettimeparam(EN_DURATION, FireTime+3600);

  // Disable any status reporting
  ENgetoption(EN_STATUS_REPORT, Xrpt);
  SavedReporting := Integer(Xrpt);
  ENsetstatusreport(EN_NO_REPORT);
end;

procedure Close;
begin
  SetLength(StaticPressures, 0);
  SetLength(FireFlowResults, 0);
end;

procedure FindFireFlow(I: Integer);
var
  Pstatic: Single;
  AvailableFlow: Single = 0;
  ErrCode: Integer;
begin
  // Initialize results
  Pstatic := FireFlowResults[I].StaticPress;
  FireFlowResults[I].AvailableFlow := 0;
  FireFlowResults[I].DesignFlowPress := Pstatic;
  FireFlowResults[I].CriticalPress := Pstatic;
  FireFlowResults[I].CriticalNode := FireFlowResults[I].FireNode;

  // Exit if static pressure <= design pressure
  if Pstatic <= DesignPressure then exit;

  // Determine the time pattern factor for fire flow at the node
  FireNodeIndex := FireFlowResults[I].FireNode;
  SetPatternFactor();

  // Find Critical Pressure under full design fire flow
  ErrCode := FindCriticalPressure(DesignFlow);
  if ErrCode > 0 then
  begin
    TFireFlowFrame(ReportViewerForm.Report).WriteToLog(
      Format(rsSolverFailure, [project.GetID(ctNodes, FireNodeIndex), ErrCode]));
    exit;
  end;

  // See if design fire flow meets design pressure
  FireFlowResults[I].DesignFlowPress := ResidualPressure;
  if CriticalPressure >= DesignPressure then
  begin
    FireFlowResults[I].AvailableFlow := DesignFlow;
    FireFlowResults[I].CriticalPress := CriticalPressure;
  end

  // If not, then search for a lesser flow that does
  else
  begin
    ErrCode := Search(0, DesignFlow, Pstatic - DesignPressure,
      CriticalPressure - DesignPressure, AvailableFlow);
    if ErrCode > 0 then
    begin
      TFireFlowFrame(ReportViewerForm.Report).WriteToLog(
        Format(rsSearchFailure, [project.GetID(ctNodes, FireNodeIndex), ErrCode]));
      exit;
    end;
    FireFlowResults[I].AvailableFlow := AvailableFlow;
    FireFlowResults[I].CriticalPress := CriticalPressure;
  end;

  // Convert results back to std. fire flow units
  FireFlowResults[I].CriticalNode := CriticalNode;
  FireFlowResults[I].StaticPress /= UcfPressure;
  FireFlowResults[I].DesignFlowPress /= UcfPressure;
  FireFlowResults[I].AvailableFlow /= UcfFlow;
  FireFlowResults[I].CriticalPress /= UcfPressure;
end;

function FindAllFireFlows: Integer;
var
  ErrCode: Integer;
  FireFlowProgressForm: TFireFlowProgressForm;
begin
  // Open hydraulic solver
  Result := 0;
  ENopenH;

  // Run a static analysis (with no fire flow)
  ErrCode := RunStaticAnalysis;
  if ErrCode <> 0 then
    TFireFlowFrame(ReportViewerForm.Report).WriteToLog(
      Format(rsStaticFailure, [ErrCode]))

  else
  begin
    // Find fire flow for each designated node
    FireFlowProgressForm := TFireFlowProgressForm.Create(MainForm);
    with FireFlowProgressForm do
    try
      NodesToProcess := NumFireNodes;
      ShowModal;
      if NodesProcessed < NumFireNodes then
        SetLength(FireFlowResults, NodesProcessed);
      Result := NodesProcessed;
    finally
      Free;
    end;
  end;

  // Close hydraulic solver
  ENcloseH;

  // Reset project duration & remove temporary fire flow pattern
  ENsettimeparam(EN_DURATION, SavedDuration);
  ENsetstatusreport(SavedReporting);
end;

procedure Swap(J1, J2: Integer);
var
  Tmp: TFireFlowResult;
begin
  Tmp := FireFlowResults[J1];
  FireFlowResults[J1] := FireFlowResults[J2];
  FireFlowResults[J2] := Tmp;
end;

function Compare(J1, J2, SortIndex: Integer): Integer;
var
  K: Integer;
  S1, S2: string;
begin
  Result := 0;
  case SortIndex of
    0:
      begin
        K := FireFlowResults[J1].FireNode;
        S1 := project.GetID(ctNodes, K);
        K := FireFlowResults[J2].FireNode;
        S2 := project.GetID(ctNodes, K);
        Result := CompareText(S1, S2);
      end;
    1:
      Result := math.CompareValue(FireFlowResults[J1].StaticPress,
                                    FireFlowResults[J2].StaticPress);
    2:
      Result := 0;
    3:
      Result := math.CompareValue(FireFlowResults[J1].DesignFlowPress,
                                    FireFlowResults[J2].DesignFlowPress);
    4:
      Result := math.CompareValue(FireFlowResults[J1].AvailableFlow,
                                    FireFlowResults[J2].AvailableFlow);
    5:
      Result := math.CompareValue(FireFlowResults[J1].CriticalPress,
                                    FireFlowResults[J2].CriticalPress);
    6:
      begin
        K := FireFlowResults[J1].CriticalNode;
        S1 := project.GetID(ctNodes, K);
        K := FireFlowResults[J2].CriticalNode;
        S2 := project.GetID(ctNodes, K);
        Result := CompareText(S1, S2);
      end;
  end;
end;

procedure SortResults(SortIndex: Integer; SortOrder: TSortOrder);
var
  I, J, R: integer;
begin
  for I := 0 to Length(FireFlowResults) - 2 do
  begin
    for J := 0 to Length(FireFlowResults) - 2 - I do
    begin
      R := Compare(J, J+1, SortIndex);
      if SortOrder = soDescending then
        R := -R;
      if R > 0 then
        Swap(J, J+1);
    end;
  end;
end;

end.

