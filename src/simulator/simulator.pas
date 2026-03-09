{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       simulator
 Description:  a form that runs a simulation for the project
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit simulator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  FileUtil;

{$I ..\timetype.txt} //Defines C's 'long' data type for different platforms

type

  { TSimulationForm }

  TSimulationForm = class(TForm)
    CancelBtn:   TButton;
    OkBtn:       TButton;
    StatusLabel: TPanel;

    procedure CancelBtnClick(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure OkBtnClick(Sender: TObject);

  private
    ErrorCode: Integer;
    procedure RunSimulation;
    procedure ShowRunStatus;
    procedure RunSolver;
    procedure RunHydraulics;
    procedure RunQuality;
    procedure RunMsxQuality;
    procedure SaveDemandDeficit(var F: TFileStream; var Deficits: array of Single;
      var Demands: array of Single);
    procedure SaveEmitterFlow(var F: TFileStream; var Flows: array of Single);
    procedure SaveNodeLeakage(var F: TFileStream; var Leakages: array of Single);
    procedure SavePipeLeakage(var F: TFileStream; var Leakages: array of Single);
    procedure SaveLinkEnergy(var F: TFileStream; var Energy: array of Single);

  public

  end;

var
  SimulationForm: TSimulationForm;

implementation

{$R *.lfm}

uses
  project, config, results, energycalc, epanet2, epanetmsx, resourcestrings;

{ TSimulationForm }

procedure TSimulationForm.FormCreate(Sender: TObject);
begin
  // Position the OK button on top of the Cancel button
   Font.Size := config.FontSize;
  OkBtn.Visible := false;
  OkBtn.Top := CancelBtn.Top;
  OkBtn.Left := CancelBtn.Left;
end;

procedure TSimulationForm.CancelBtnClick(Sender: TObject);
begin
  SimStatus := ssCancelled;
end;

procedure TSimulationForm.FormActivate(Sender: TObject);
begin
  RunSimulation;
  CancelBtn.Visible := false;
  OkBtn.Visible := true;
  OkBtn.SetFocus;
end;

procedure TSimulationForm.OkBtnClick(Sender: TObject);
begin
  Hide;
end;

procedure TSimulationForm.RunSimulation;
begin
  // Prepare the project for a new simulation
  project.SimStatus := ssNone;
  project.HasResults := false;
  results.CloseOutFile;
  ErrorCode := 0;
  ENclearreport;

  // Run the EPANET hydraulic and water quality solvers
  RunSolver;
  ShowRunStatus;

  // Copy EPANET's status report to the project's auxilary file
  ENcopyreport(PAnsiChar(AuxFile));
end;

procedure TSimulationForm.ShowRunStatus;
var
  MsxSimStatus: TSimStatus;
begin
  // Open EPANET's binary output file to retrieve simulation status
  if not (SimStatus in [ssCancelled, ssShutdown]) then
  begin
    if ErrorCode > 0 then
      SimStatus := ssError
    else if not FileExists(project.OutFile) then
      SimStatus := ssFailed
    else
      SimStatus := results.OpenOutFile(project.OutFile);

    // Open the MSX output file
    if MsxFlag
    and (SimStatus in [ssSuccess, ssWarning]) then
    begin
      if not FileExists(project.MsxOutFile) then
      begin
        SimStatus := ssFailed;
      end
      else
      begin
        MsxSimStatus := results.OpenMsxOutFile(project.MsxOutFile);
        if MsxSimStatus <> ssSuccess then
        begin
          SimStatus := MsxSimStatus;
        end;
      end;
    end;
  end;

  // Display run status message
  case SimStatus of
    ssShutdown:
      StatusLabel.Caption := rsStatusShutdown;
    ssNone:
      StatusLabel.Caption := rsStatusNone;
    ssWrongVersion:
      StatusLabel.Caption := rsStatusVersion;
    ssFailed:
      StatusLabel.Caption := rsStatusFailed;
    ssError:
      StatusLabel.Caption := rsStatusError;
    ssWarning:
      StatusLabel.Caption := rsStatusWarning;
    ssSuccess:
      StatusLabel.Caption := rsStatusSuccess;
    ssCancelled:
      StatusLabel.Caption := rsStatusCanceled;
  end;
  if SimStatus in [ssSuccess, ssWarning] then
    project.HasResults := true;
end;

procedure TSimulationForm.RunSolver;
var
  StartTime: TimeType = 0;
begin
  // Retrieve and save starting time of day in sec
  epanet2.ENgettimeparam(EN_STARTTIME, StartTime);
  project.StartTime := StartTime;

  // Run EPANET's hydraulics solver
  ErrorCode := 0;
  RunHydraulics;

  // Run EPANET's water quality solver
  if (ErrorCode < 100)
  and (SimStatus <> ssCancelled) then
  begin
    if MsxFlag then
      RunMsxQuality
    else
      RunQuality;
  end;
end;

procedure TSimulationForm.RunHydraulics;
var
  t:         TimeType;
  tstep:     TimeType;
  rptStep:   TimeType;
  F:         TFileStream;
  N:         Integer;
  NodeFlows: array of Single;
  LinkArray: array of Single;
  DmndDefs:  array of Single;
begin
  // Create arrays to hold node flows and pipe leakage flow
  epanet2.ENgetcount(EN_NODECOUNT, N);
  setLength(NodeFlows,N);
  setLength(DmndDefs, N);
  epanet2.ENgetcount(EN_LINKCOUNT, N);
  setLength(LinkArray, N);

  // Create a file stream to save demand deficit, emitter flow,
  // and leakage flows since the current EPANET solver doesn't
  // save these in its output file
  F := TFileStream.Create(project.OutFile2, fmCreate);
  try
    // Initialize energy calculation
    energycalc.Start;
    results.SetInitStorage;

   // Open EPANET's hydraulics solver
    epanet2.ENgettimeparam(EN_REPORTSTEP, rptStep);
    ErrorCode := epanet2.ENopenH();
    if ErrorCode = 0 then
    begin

      // Initialize hydraulics solver to save its results to file
      epanet2.ENinitH(EN_SAVE);
      t := 0;

      // Solve hydraulics in each period
      repeat
        // Update display of simulation progress
        if t mod 3600 = 0 then
        begin
          StatusLabel.Caption := rsSolvingHydraul + ' ' + IntToStr(t div 3600);
          Application.ProcessMessages;
        end;

        // Solve hydraulics at current time
        ErrorCode := epanet2.ENrunH(t);

        // If at a reporting time, save results that the EPANET solver
        // doesn't include in its binary output file
        if t mod rptStep = 0 then
        begin
          SaveDemandDeficit(F, NodeFlows, DmndDefs);
          SaveEmitterFlow(F, NodeFlows);
          SaveNodeLeakage(F, NodeFlows);
          SavePipeLeakage(F, LinkArray);
          SaveLinkEnergy(F, LinkArray);
        end;

        // Determine size of next hydraulic time step
        tstep := 0;
        if ErrorCode <= 100 then
          ErrorCode := epanet2.ENnextH(tstep);

        // Update system energy usage over the time step
        energycalc.Update(Integer(t), Integer(tstep));
      until (tstep = 0)
      or (ErrorCode > 100)
      or (SimStatus = ssCancelled);
    end;

    // Close hydraulics solver
    energycalc.Finish;
    epanet2.ENcloseH();

    // Save hydraulic results for use by MSX solver
    if (ErrorCode <= 100)
    and (SimStatus <> ssCancelled)
    and MsxFlag then
    begin
      epanet2.ENsaveH;
      epanet2.ENsavehydfile(PAnsiChar(MsxHydFile));
    end;

    // Ignore any warning code
    if ErrorCode <= 100 then ErrorCode := 0;
  finally
    F.Free;
  end;
end;

procedure TSimulationForm.RunQuality;
var
  t:     TimeType;
  tstep: TimeType;
begin
  // Open quality solver
  ErrorCode := epanet2.ENopenQ();
  if ErrorCode = 0 then
  begin

    // Initialize WQ solver
    epanet2.ENinitQ(EN_SAVE);
    t := 0;

    //  Solve WQ in each period
    repeat
      if t mod 3600 = 0 then
      begin
        StatusLabel.Caption := rsSolvingQuality + ' ' + IntToStr(t div 3600);
        Application.ProcessMessages;
      end;
      ErrorCode := epanet2.ENrunQ(t);
      tstep := 0;
      if ErrorCode <= 100 then
        ErrorCode := epanet2.ENnextQ(tstep);
    until (tstep = 0)
    or (ErrorCode > 100)
    or (SimStatus = ssCancelled);
  end;

  // Close WQ solver
  epanet2.ENcloseQ();
end;

procedure TSimulationForm.RunMsxQuality;
var
  t:       Double = 0;
  tleft:   Double = 0;
  OldHour: Int64;
  NewHour: Int64;
begin
  // Open MSX solver and make saved hydraulic results available to it
  ErrorCode := epanetmsx.MSXopen(PAnsiChar(MsxInpFile));
  if ErrorCode = 0 then
    ErrorCode := epanetmsx.MSXusehydfile(PAnsiChar(MsxHydFile));
  if ErrorCode = 0 then
  begin
    // Initialize Water Quality solver
    ErrorCode := epanetmsx.MSXinit(1);
    t := 0;
    tleft := 0;
    OldHour := -1;
    NewHour := 0;

    // Solve Water Quality in each period
    repeat
      if NewHour > OldHour then
      begin
        OldHour := NewHour;
        StatusLabel.Caption := rsSolvingQuality + ' ' + IntToStr(NewHour);
        Application.ProcessMessages;
      end;
      ErrorCode := epanetmsx.MSXstep(t, tleft);
      NewHour := Trunc(t/3600);
    until (tleft = 0)
    or (ErrorCode > 0)
    or (SimStatus = ssCancelled);
  end;

  // Save Water Quality results and close MSX solver
  if (tleft = 0)
  and (ErrorCode = 0)
  and (SimStatus <> ssCancelled) then
  begin
    ErrorCode := epanetmsx.MSXsaveoutfile(PAnsiChar(MsxOutFile));
  end;
  epanetmsx.MSXclose;
end;

procedure TSimulationForm.SaveDemandDeficit(var F: TFileStream;
  var Deficits: array of Single; var Demands: array of Single);
var
  I:          Integer;
  N:          Integer = 0;
  ByteCount: Integer;
begin
  if F = nil then exit;
  ENgetcount(EN_NODECOUNT, N);
  ByteCount := N * sizeof(Single);
  epanet2.ENgetnodevalues(EN_DEMANDDEFICIT, Deficits);
  epanet2.ENgetnodevalues(EN_FULLDEMAND, Demands);
  for I := 0 to N-1 do
  begin
    if (Demands[I] > 0.0)
    and (Deficits[I] > 0.0) then
      Deficits[I] := Deficits[I] / Demands[I] * 100.
    else
      Deficits[I] := 0.0;
  end;
  F.Write(Deficits[0], ByteCount);
end;

procedure TSimulationForm.SaveEmitterFlow(var F: TFileStream;
  var Flows: array of Single);
var
  N:         Integer = 0;
  ByteCount: Integer;
begin
  if F = nil then exit;
  epanet2.ENgetcount(EN_NODECOUNT, N);
  ByteCount := N * sizeof(Single);
  epanet2.ENgetnodevalues(EN_EMITTERFLOW, Flows);
  F.Write(Flows[0], ByteCount);
end;

procedure TSimulationForm.SaveNodeLeakage(var F: TFileStream;
  var Leakages: array of Single);
var
  N:         Integer = 0;
  ByteCount: Integer;
begin
  if F = nil then exit;
  epanet2.ENgetcount(EN_NODECOUNT, N);
  ByteCount := N * sizeof(Single);
  epanet2.ENgetnodevalues(EN_LEAKAGEFLOW, Leakages);
  F.Write(Leakages[0], ByteCount);
end;

procedure TSimulationForm.SavePipeLeakage(var F: TFileStream;
  var Leakages: array of Single);
var
  N:         Integer = 0;
  ByteCount: Integer;
begin
  if F = nil then exit;
  epanet2.ENgetcount(EN_LINKCOUNT, N);
  ByteCount := N * sizeof(Single);
  epanet2.ENgetlinkvalues(EN_LINK_LEAKAGE, Leakages);
  F.Write(Leakages[0], ByteCount);
end;

procedure TSimulationForm.SaveLinkEnergy(var F: TFileStream;
  var Energy: array of Single);
var
  N:         Integer = 0;
  ByteCount: Integer;
begin
  if F = nil then exit;
  epanet2.ENgetcount(EN_LINKCOUNT, N);
  ByteCount := N * sizeof(Single);
  epanet2.ENgetlinkvalues(EN_ENERGY, Energy);
  F.Write(Energy[0], ByteCount);
end;

end.

