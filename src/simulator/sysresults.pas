{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       sysresults
 Description:  computes time series of system-wide variables from
               simulation results saved to file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit sysresults;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, resourcestrings;

const
  SysEnergy     = 0;
  SysDemand     = 1;
  SysDemandDfct = 2;
  SysLeakage    = 3;
  SysStorage    = 4;
  SysPressure   = 5;
  SysParams: array[0..5] of string =
    (rsSysEnergy, rsSysDemand, rsSysDemandDfct, rsSysLeakage,
     rsSysStorage, rsSysPressure);

  function  GetSysParamUnits(SysParam: Integer): string;
  function  GetSysValue(SysParam: Integer; T: Integer): Double;

implementation

uses
  project, mapthemes, results;

function GetSysParamUnits(SysParam: Integer): string;
begin
  Result := '';
  case SysParam of
    SysEnergy:
      Result := 'kWh';
    SysDemandDfct:
      Result := '%';
    SysDemand,
    SysLeakage:
      Result := project.FlowUnitsStr[project.FlowUnits];
    SysStorage:
      if project.GetUnitsSystem = usSI then
        Result := rsMegaLiters
      else
        Result := rsMillionGallons;
    SysPressure:
      Result := project.PressUnitsStr[project.PressUnits];
  end;
end;

function GetSysEnergy(T: Integer): Double;
var
  I: Integer;
  Dt: Double;
  E: Double;
  V: Double;
begin
  // Time step (sec)
  Dt := results.Rstep;
  if results.Nperiods = 1 then Dt := 3600;

  // Accumulate energy usage by each pump link
  E := 0;
  for I := 1 to project.GetItemCount(ctLinks) do
  begin
    if project.GetLinkType(I) <> ltPump then continue;
    V := mapthemes.GetLinkValue(I, mapthemes.ltEnergy, T);
    E := E + V
  end;
  Result := E * Dt / 3600;
end;

function GetSysStorage(T: Integer): Double;
const
  V: Double = 0; // net change in stored volume in ft3
var
  I: Integer;
  D: Single;    // flow rate in user units
  Dt: Double;   // time step (sec)
  Qcf: Double;  // flow conversion factor
  Vcf: Double;  // volume conversion factor
begin
  Result := MISSING;
  Dt := results.Rstep;
  if results.Nperiods = 1 then Dt := 3600;
  Qcf := project.FlowUcf[project.FlowUnits]; // project flow units per cfs
  if project.GetUnitsSystem = usUS then
    Vcf := 0.000007480519                    // mil. gal per ft3
  else
    Vcf := 28.317e-6;                        // m3 per megaliter
  if T = 0 then V := results.InitStorage;    // ft3
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeType(I) = ntTank then
    begin
      D := mapthemes.GetNodeValue(I, mapthemes.ntDemand, T); // user units
      if D = MISSING then continue;
      V := V + D / Qcf * Dt;  // D converted to cfs
    end;
  end;
  Result := V * Vcf;
end;

function GetSysDemandDfct(T: Integer): Double;
var
  I:       Integer;
  P:       Integer;
  N:       Integer = 0;
  DmndSum: Double = 0;
  DfctSum: Double = 0;
  Dmnd:    Double;
  Dfct:    Double;
begin
  Result := 0;
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeType(I) <> ntJunction then continue;
    P := mapthemes.ntDemand;
    Dmnd := mapthemes.GetNodeValue(I, P, T);
    if Dmnd < 0.0 then continue;
    if Dmnd = MISSING then continue;
    P := mapthemes.ntDmndDfct;
    Dfct :=  mapthemes.GetNodeValue(I, P, T);
    if Dfct = MISSING then continue;
    DmndSum := DmndSum + Dmnd;
    DfctSum := DfctSum + Dfct * Dmnd / 100;
    Inc(N);
  end;
  if DmndSum > 0 then
    Result := DfctSum / DmndSum * 100;
  if Result > 100 then Result := 100;
end;

function GetSysPressure(T: Integer): Double;
var
  I:       Integer;
  P:       Integer;
  N:       Integer = 0;
  Y:       Double;
  Ysum:    Double = 0;
begin
  Result := 0;
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeType(I) <> ntJunction then continue;
    P := mapthemes.ntPressure;
    Y := mapthemes.GetNodeValue(I, P, T);
    if Y < 0.0 then continue;
    if Y = MISSING then continue;
    Ysum := Ysum + Y;
    Inc(N);
  end;
  Result := Ysum / N;
end;

function GetSysValue(SysParam: Integer; T: Integer): Double;
var
  I: Integer;
  P: Integer;
  Q: Single;
  Sum: Double;
begin
  Result := MISSING;
  if SysParam = SysEnergy then
    Result := GetSysEnergy(T)
  else if SysParam = SysStorage then
    Result := GetSysStorage(T)
  else if SysParam = SysDemandDfct then
    Result := GetSysDemandDfct(T)
  else if SysParam = SysPressure then
    Result := GetSysPressure(T)
  else
  begin
    case SysParam of
      SysDemand:
        P := mapthemes.ntDemand;
      SysLeakage:
        P := mapthemes.ntLeakage;
      else
        exit;
    end;
    Sum := 0;
    for I := 1 to project.GetItemCount(ctNodes) do
    begin
      if project.GetNodeType(I) <> ntJunction then continue;
      Q := mapthemes.GetNodeValue(I, P, T);
      if Q < 0.0 then continue;
      if Q <> MISSING then Sum := Sum + Q;
    end;
    Result := Sum;
  end;
end;

end.

