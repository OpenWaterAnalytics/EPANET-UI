{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       energycalc
 Description:  calculates an energy balance for the project
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit energycalc;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Dialogs;

const
  eInflows  = 1;
  ePumping  = 2;
  eTankOut  = 3;
  eDemands  = 4;
  eLeakage  = 5;
  eFriction = 6;
  eTankIn   = 7;
  eMinUse   = 8;

var
  Energy:   array[eInflows..eMinUse] of Double;
  Preq:     Single;
  PreqStr:  string;
  Tsum:     Integer;

  procedure Start;
  procedure Update(T: Integer; Dt: Integer);
  procedure Finish;

implementation

uses
  project, epanet2, resourcestrings;

const
  SECperHR  = 3600;
  SECperDAY = 86400;
  MperFT = 0.3048;

var
  SpGrav: Single;

procedure Start;
var
  I: Integer;
  DmndModel: Integer = 0;
  Pmin: Single = 0;
  Pexp: Single = 0;
  Punits: Single = 0;
begin
  Tsum := 0;
  SpGrav := 1;
  for I := eInflows to eMinuse do Energy[I] := 0;
  epanet2.ENgetdemandmodel(DmndModel, Pmin, Preq, Pexp);
  epanet2.ENgetoption(EN_PRESS_UNITS, Punits);
  epanet2.ENgetoption(EN_SP_GRAVITY, SpGrav);
  PreqStr := Format('%.1f', [Preq]);

  // Preq is the service pressure used by a Pressure Dependent
  // Demand model. It is used here to determine the minimum energy
  // required to meet demands at that pressure. It is converted to
  // feet if using US units or the meters for SI units.
  case Round(Punits) of
    EN_PSI:
      begin
        Preq := Preq / 0.4333;
        PreqStr := PreqStr + ' ' + rsPsi;
      end;
    EN_KPA:
      begin
        Preq := Preq * 0.334553;
        PreqStr := PreqStr + ' ' + rsKpa;
      end;
    EN_METERS:
      begin
        Preq := Preq / MperFT;
        PreqStr := PreqStr + ' ' + rsMeter;
      end;
    EN_BAR:
      begin
        Preq := Preq * 33.4553;
        PreqStr := PreqStr + ' ' + rsBar;
      end;
    EN_FEET:
      PreqStr := PreqStr + ' ' + rsFeet;
  end;

  // Convert Preq to meters if using SI units
  if project.GetUnitsSystem = usSI then
    Preq := Preq * MperFt;
  Preq := Preq / SpGrav;
end;

procedure UpdateNodeEnergy(Dt: Integer);
var
  I:    Integer;
  N:    Integer;
  E:    Single;
  Qd:   Single = 0;
  Ql:   Single = 0;
  H:    Single = 0;
  El:   Single = 0;
  Hmin: Single = 0;
begin
  // Hmin is the lowest negative head in the network
  N := project.GetItemCount(ctNodes);
  for I := 1 to N do
  begin
    epanet2.ENgetnodevalue(I, EN_HEAD, H);
    if H < Hmin then Hmin := H;
  end;

  // Analyze each network node
  for I := 1 to N do
  begin

    // Retrieve node's elevation, head, demand & leakage
    epanet2.ENgetnodevalue(I, EN_ELEVATION, El);
    epanet2.ENgetnodevalue(I, EN_HEAD, H);
    epanet2.ENgetnodevalue(I, EN_DEMAND, Qd);
    epanet2.ENgetnodevalue(I, EN_LEAKAGEFLOW, Ql);

    // Subtract leakage to find consumer demand
    Qd := Qd - Ql;

    // Adjust heads so there are no negative values
    H := H - Hmin;

    // Find energy content of demand flow over the time step
    E := Abs(Qd * H * Dt);

    case project.GetNodeType(I) of
      ntJunction:
        begin
          // Update energy required to meet demend at pressure Preq
          Energy[eMinUse] := Energy[eMinUse] +
              Abs(Qd * (El + Preq - Hmin) * Dt);

          // Update energy in demand flow
          if Qd > 0 then
             Energy[eDemands] := Energy[eDemands] + E
          else
            Energy[eInflows] := Energy[eInflows] + E;

          // Update energy in leakage flow
          if Ql > 0 then
            Energy[eLeakage] := Energy[eLeakage] + (Ql * H * Dt)
          else
            Energy[eInflows] := Energy[eInflows] - (Ql * H * Dt);
        end;

      ntReservoir: // Qd < 0 for outflow, > 0 for inflow
        begin
          if Qd < 0 then
            Energy[eInflows] := Energy[eInflows] + E
          else
            Energy[eDemands] := Energy[eDemands] + E;
        end;

      ntTank: // Qd > 0 for inflow, < 0 for outflow
        if Qd > 0 then
          Energy[eTankIn] := Energy[eTankIn] + E
        else
          Energy[eTankOut] := Energy[eTankOut] + E;
    end;
  end;
end;

procedure UpdateLinkEnergy(Dt: Integer);
var
  I:  Integer;
  N:  Integer;
  N1: Integer = 0;
  N2: Integer = 0;
  Q:  Single = 0;
  H1: Single = 0;
  H2: Single = 0;
  P:  Single;
begin
  N := project.GetItemCount(ctLinks);
  for I := 1 to N do
  begin
    if not project.GetLinkNodes(I, N1, N2) then continue;
    epanet2.ENgetlinkvalue(I, EN_FLOW, Q);
    epanet2.ENgetnodevalue(N1, EN_HEAD, H1);
    epanet2.ENgetnodevalue(N2, EN_HEAD, H2);
    P := Abs((H1 - H2) * Q) * Dt;
    if project.GetLinkType(I) = ltPump then
      Energy[ePumping] := Energy[ePumping] + P
    else
      Energy[eFriction] := Energy[eFriction] + P;
  end;
end;

procedure Update(T: Integer; Dt: Integer);
begin
  if Dt = 0 then
  begin
    if T = 0 then
      Dt := SECperDAY
    else
      exit;
  end;
  UpdateNodeEnergy(Dt);
  UpdateLinkEnergy(Dt);
  Tsum := Tsum + Dt;
end;

procedure Finish;
var
  I: Integer;
  Ecf: Double;
  Tcf: Double;
begin
  // Ecf converts H*Q from user units to (ft)*(gpm)/5310 = kw
  Ecf := project.FlowUcf[EN_GPM] / project.FlowUcf[project.FlowUnits] / 5310;
  if project.GetUnitsSystem = usSI then Ecf := Ecf / MperFt;

  // Tcf adjusts from kw-sec to kw-hr/day
  Tcf := SECperDAY / SECperHR / Tsum;

  // Energy used by each category in kwh/day
  for I := eInflows to eMinUse do
    Energy[I] := Ecf * Tcf * Energy[I];
end;

end.

