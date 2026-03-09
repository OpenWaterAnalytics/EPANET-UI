{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       projectsummary
 Description:  a form that displays a summary of a project's objects
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit projectsummary;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, LCLtype,
  ComCtrls;

{$I ..\timetype.txt}

type

  { TSummaryForm }

  TSummaryForm = class(TForm)
    TreeView1: TTreeView;
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
  private
    procedure ShowNodeCount;
    procedure ShowLinkCount;
    procedure ShowCurveCount;
    procedure ShowPatternCount;
    procedure ShowControlCount;

  public

  end;

var
  SummaryForm: TSummaryForm;

implementation

{$R *.lfm}

uses
  epanet2, project, utils, config, resourcestrings;

{ TSummaryForm }

procedure TSummaryForm.FormShow(Sender: TObject);
var
  I: Integer = 0;
  S: string = '';
  T: TimeType = 0;
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
  ShowNodeCount;
  ShowLinkCount;
  ShowCurveCount;
  ShowPatternCount;
  ShowControlCount;
  epanet2.ENgetflowunits(I);
  epanet2.ENgettimeparam(EN_DURATION, T);
  with TreeView1 do
  begin
    Items[29].Text := project.FlowUnitsStr[I] + ' ' + rsProjFlowUnits;
    Items[30].Text := project.GetHlossModelStr + ' ' + rsProjHlossModel;
    Items[31].Text := project.GetDemandModelStr + ' ' + rsProjDmndModel;
    S := project.GetQualModelStr;
    if not SameText(S, 'No Quality') then
      S := S + ' ' + rsProjQualModel
    else
      S := S + ' ' + rsProjModel;
    Items[32].Text := S;
    Items[33].Text := utils.Time2Str(T) + ' ' + rsProjDuration ;
  end;

end;

procedure TSummaryForm.ShowNodeCount;
var
  I:         Integer;
  J:         Integer;
  Count:     Integer = 0;
  JuncCount: Integer = 0;
  ResvCount: Integer = 0;
  TankCount: Integer = 0;
begin
  epanet2.ENgetcount(EN_NODECOUNT, Count);
  TreeView1.Items[1].Text := IntToStr(Count) + ' ' + rsNodes;
  for I := 1 to Count do
  begin
    J := GetNodeType(I);
    case J of
      ntJunction: Inc(JuncCount);
      ntReservoir: Inc(ResvCount);
      ntTank: Inc(TankCount);
    end;
  end;
  with TreeView1 do
  begin
    Items[2].Text := IntToStr(JuncCount) + ' ' + rsJunctions;
    Items[3].Text := IntToStr(ResvCount) + ' ' + rsReservoirs;
    Items[4].Text := IntToStr(TankCount) + ' ' + rsTanks;
  end;
end;

procedure TSummaryForm.ShowLinkCount;
var
  I:          Integer;
  J:          Integer;
  K:          Integer = 0;
  Count:      Integer = 0;
  PipeCount:  Integer = 0;
  PumpCount:  Integer = 0;
  ValveCount: Integer = 0;
  ValveTypeCount: array[0..6] of Integer = (0,0,0,0,0,0,0);
begin
  epanet2.ENgetcount(EN_LINKCOUNT, Count);
  TreeView1.Items[5].Text := IntToStr(Count) + ' ' + rsLinks;
  for I := 1 to Count do
  begin
    J := GetLinkType(I);
    case J of
      ltPipe:
        Inc(PipeCount);
      ltPump:
        Inc(PumpCount);
      ltValve:
        Inc(ValveCount);
    end;
    if J = ltValve then
    begin
      epanet2.ENgetlinktype(I, K);
      K := K - EN_PRV;
      Inc(ValveTypeCount[K]);
    end;
  end;
  with TreeView1 do
  begin
    Items[6].Text := IntToStr(PipeCount) + ' ' + rsPipes;
    Items[7].Text := IntToStr(PumpCount) + ' ' + rsPumps;
    Items[8].Text := IntToStr(ValveCount) + ' ' + rsValves;
    for K := 0 to 6 do
    begin
      Items[9+K].Text := IntToStr(ValveTypeCount[K]) + ' ' +
        ValveTypeStr[K] + rsS;
    end;
  end;
end;

procedure TSummaryForm.ShowCurveCount;
var
  I:     Integer;
  K:     Integer = 0;
  Count: Integer = 0;
  CurveTypeCount: array[0..5] of Integer = (0,0,0,0,0,0);
begin
  epanet2.ENgetcount(EN_CURVECOUNT, Count);
  TreeView1.Items[17].Text := IntToStr(Count) + ' ' + rsDataCurves;
  for I := 1 to Count do
  begin
    epanet2.ENgetcurvetype(I, K);
    Inc(CurveTypeCount[K]);
  end;
  for K := 0 to 5 do
  begin
    TreeView1.Items[18+K].Text := IntToStr(CurveTypeCount[K]) + ' ' +
      CurveTypeStr[K] + ' ' + rsCurves;
  end;
end;

procedure TSummaryForm.ShowPatternCount;
var
  Count: Integer = 0;
begin
  epanet2.ENgetcount(EN_PATCOUNT, Count);
  TreeView1.Items[24].Text := IntToStr(Count) + ' ' + rsTimePatterns;
end;

procedure TSummaryForm.ShowControlCount;
var
  SimpleCount: Integer = 0;
  RuleCount:   Integer = 0;
begin
  epanet2.ENgetcount(EN_CONTROLCOUNT, SimpleCount);
  epanet2.ENgetcount(EN_RULECOUNT, RuleCount);
  TreeView1.Items[25].Text := IntToStr(SimpleCount+RuleCount) + ' ' + rsLinkControls;
  TreeView1.Items[26].Text := IntToStr(SimpleCount) + ' ' + rsSimpleControls;
  TreeView1.Items[27].Text := IntToStr(RuleCount) + ' ' + rsRuleControls;
end;

procedure TSummaryForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

end.

