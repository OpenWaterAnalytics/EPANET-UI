{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       statusframe
 Description:  a frame containing a status panel
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit statusframe;

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

  public
    procedure SetPanelText(PanelIndex: Integer; Txt: string);
    procedure SetPanelColor(PanelIndex: Integer; aColor: TColor);

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

  procedure TStatusBarFrame.SetPanelText(PanelIndex: Integer; Txt: string);
  begin
    with FindComponent('Panel' + IntToStr(PanelIndex)) as TPanel do
      Caption := Txt;
  end;

  procedure TStatusBarFrame.SetPanelColor(PanelIndex: Integer; aColor: TColor);
  begin
    with FindComponent('Panel' + IntToStr(PanelIndex)) as TPanel do
      Color := aColor;
  end;

end.

