{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       statusframe
 Description:  set of panels appearing in the main form's StatusPanel
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit statusframe;

{
 This frame consists of 8 panels whose contents are as follows:
 Panel1: checkbox to toggle AutoLength on/off
 Panel2: project's flow rate units
 Panel3: project's pressure units
 Panel4: project's head loss model
 Panel5: project's demand model
 Panel6: project's water quality model
 Panel7: status of simulation results
 Panel8: network map coordinates

 Clicking on panels 2 thru 6 allows the user to change the
 project options they display.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, Graphics, StdCtrls, ComCtrls;

type

  { TStatusBarFrame }

  TStatusBarFrame = class(TFrame)
    AutoLengthCheckBox: TCheckBox;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    Panel5: TPanel;
    Panel6: TPanel;
    Panel7: TPanel;
    Panel8: TPanel;
    procedure AutoLengthCheckBoxChange(Sender: TObject);
    procedure Panel2Click(Sender: TObject);
    procedure Panel3Click(Sender: TObject);
    procedure Panel4Click(Sender: TObject);
    procedure Panel5Click(Sender: TObject);
    procedure Panel6Click(Sender: TObject);
  private
    function GetPanel(PanelIndex: Integer): TPanel;

  public
    procedure SetPanelText(PanelIndex: Integer; Txt: string);
    procedure SetPanelColor(PanelIndex: Integer; aColor: TColor);
    function  GetPanelText(PanelIndex: Integer): string;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, utils;

procedure TStatusBarFrame.AutoLengthCheckBoxChange(Sender: TObject);
begin
  with AutoLengthCheckBox do
  begin
    project.AutoLength := Checked;
    if Checked then Panel1.Color := $00E0FFFF
    else Panel1.Color := config.ThemeColor;
  end;
end;

procedure TStatusBarFrame.Panel2Click(Sender: TObject);
begin
  MainForm.ProjectSetup;
end;

procedure TStatusBarFrame.Panel3Click(Sender: TObject);
begin
  MainForm.ProjectSetup;
end;

procedure TStatusBarFrame.Panel4Click(Sender: TObject);
begin
  MainForm.ProjectSetup;
end;

procedure TStatusBarFrame.Panel5Click(Sender: TObject);
var
  DemandsNode: TTreeNode;
begin
  with MainForm.ProjectFrame do
  begin
    DemandsNode := utils.FindTreeNode(ProjectTreeView, 'Demands');
    ProjectTreeView.Select(DemandsNode);
  end;
end;

procedure TStatusBarFrame.Panel6Click(Sender: TObject);
var
  QualityNode: TTreeNode;
begin
  with MainForm.ProjectFrame do
  begin
    QualityNode := utils.FindTreeNode(ProjectTreeView, 'Quality');
    ProjectTreeView.Select(QualityNode);
  end;
end;

function TStatusBarFrame.GetPanel(PanelIndex: Integer): TPanel;
begin
  Result := TPanel(FindComponent('Panel' + IntToStr(PanelIndex)));
end;

procedure TStatusBarFrame.SetPanelText(PanelIndex: Integer; Txt: string);
var
  StatusPanel: TPanel;
begin
  StatusPanel := GetPanel(PanelIndex);
  if Assigned(StatusPanel) then
    StatusPanel.Caption := Txt;
end;

procedure TStatusBarFrame.SetPanelColor(PanelIndex: Integer; aColor: TColor);
var
  StatusPanel: TPanel;
begin
  StatusPanel := GetPanel(PanelIndex);
  if Assigned(StatusPanel) then
    StatusPanel.Color := aColor;
end;

function TStatusBarFrame.GetPanelText(PanelIndex: Integer): string;
var
  StatusPanel: TPanel;
begin
  Result := '';
  StatusPanel := GetPanel(PanelIndex);
  if Assigned(StatusPanel) then
    Result := StatusPanel.Caption;
end;

end.

