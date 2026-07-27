{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       mapalign
 Description:  a frame used to align a network with a basemap image
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit mapalign;

{
 This frame contains two controls used to align a network and basemap:
 - CheckBox1 is used to put the main form's MapFrame into Aligning mode
   where moving the mouse with left button pressed will move the basemap
   image while keeping the network layout fixed.
 - Trackbar1 is used to shrink or expand the scaling of the network
   layout while the basemap image remains fixed.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons,
  Dialogs, ComCtrls;

type

  { TMapAlignFrame }

  TMapAlignFrame = class(TFrame)
    CancelBtn:    TButton;
    AcceptBtn:    TButton;
    CheckBox1:    TCheckBox;
    CloseBtn:     TSpeedButton;
    Label1:       TLabel;
    Label2:       TLabel;
    Label3:       TLabel;
    Label4:       TLabel;
    TopPanel:     TPanel;
    TrackBar1:    TTrackBar;

    procedure AcceptBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure TrackBar1Change(Sender: TObject);
    procedure TrackBar1KeyUp(Sender: TObject; var Key: Word; Shift: TShiftState
      );
    procedure TrackBar1MouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);

  private
    procedure ChangeScaling;

  public
    procedure Show;

  end;

implementation

{$R *.lfm}

uses
  main, project, mapcoords, config;

var
  LowerLeft:      TDoublePoint;
  UpperRight:     TDoublePoint;
  S1, S2:         TScalingInfo;
  ScalingChanged: Boolean;

procedure TMapAlignFrame.CloseBtnClick(Sender: TObject);
begin
  CancelBtnClick(Sender);
end;

procedure TMapAlignFrame.TrackBar1Change(Sender: TObject);
begin
  ScalingChanged := true;
end;

procedure TMapAlignFrame.TrackBar1KeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  ScalingChanged := true;
  ChangeScaling;
end;

procedure TMapAlignFrame.TrackBar1MouseUp(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if ScalingChanged then ChangeScaling;
end;

procedure TMapAlignFrame.ChangeScaling;
var
  SF : Double;
begin
  ScalingChanged := false;
  mapcoords.DoScalingTransform(S2, S1, false);
  SF := 1 + (TrackBar1.Position / 100);
  S2.WP := SF * S1.WP;
  mapcoords.DoScalingTransform(S1, S2, false);
  MainForm.MapFrame.DrawFullExtent;
end;

procedure TMapAlignFrame.CancelBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.Aligning := false;
  MainForm.MapFrame.Map.Basemap.LowerLeft := LowerLeft;
  MainForm.MapFrame.Map.Basemap.UpperRight := UpperRight;
  mapcoords.DoScalingTransform(S2, S1, false);
  MainForm.MapFrame.DrawFullExtent;
  Visible := false;
end;

procedure TMapAlignFrame.CheckBox1Change(Sender: TObject);
begin
  MainForm.MapFrame.Aligning := CheckBox1.Checked;
  Label1.Enabled := CheckBox1.Checked;
end;

procedure TMapAlignFrame.AcceptBtnClick(Sender: TObject);
begin
  MainForm.MapFrame.Aligning := false;
  Visible := false;
  if (MainForm.MapFrame.Map.Basemap.LowerLeft.X <> LowerLeft.X)
  or (MainForm.MapFrame.Map.Basemap.LowerLeft.Y <> LowerLeft.Y)
  or (MainForm.MapFrame.Map.Basemap.UpperRight.X <> UpperRight.X)
  or (MainForm.MapFrame.Map.Basemap.UpperRight.Y <> UpperRight.Y)
  or (S2.WP <> S1.WP) then
  begin
    MainForm.MapFrame.DrawFullExtent;
    project.HasChanged := true;
  end;
end;

procedure TMapAlignFrame.Show;
begin
  Color := config.CreamTheme;
  config.SetHeaderColor(TopPanel);
  CheckBox1.Checked := false;
  Label1.Enabled := false;
  TrackBar1.Position := 0;
  LowerLeft := MainForm.MapFrame.Map.Basemap.LowerLeft;
  UpperRight := MainForm.MapFrame.Map.Basemap.UpperRight;
  S1 := MainForm.MapFrame.Map.GetScalingInfo;
  S2 := S1;
  Visible := true;
end;

end.

