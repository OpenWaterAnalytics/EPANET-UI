{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       fireflowprogress
 Description:  form that displays progress of a fire flow analysis
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit fireflowprogress;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ComCtrls;

type

  { TFireFlowProgressForm }

  TFireFlowProgressForm = class(TForm)
    Button1:      TButton;
    Label1:       TLabel;
    ProgressBar1: TProgressBar;

    procedure Button1Click(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);

  private

  public
    NodesToProcess: Integer;
    NodesProcessed: Integer;
    IsCancelled:    Boolean;
    procedure UpdateProgress(Percent: Integer);

  end;

var
  FireFlowProgressForm: TFireFlowProgressForm;

implementation

{$R *.lfm}

uses
  config, fireflowcalc, resourcestrings;

{ TFireFlowProgressForm }

procedure TFireFlowProgressForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  IsCancelled := false;
end;

procedure TFireFlowProgressForm.Button1Click(Sender: TObject);
begin
  IsCancelled := true;
end;

procedure TFireFlowProgressForm.FormActivate(Sender: TObject);
var
  I: Integer;
  OldProgress: Integer = 0;
  Progress: Integer;
begin
  NodesProcessed := 0;
  for I := 0 to NodesToProcess - 1 do
  begin
    if IsCancelled then
      break
    else
    begin
      fireflowcalc.FindFireFlow(I);
      Inc(NodesProcessed);
      Progress := Round(I / (NodesToProcess-1) * 100);
      if Progress > OldProgress then
      begin
        UpdateProgress(Progress);
        Application.ProcessMessages;
        OldProgress := Progress;
      end;
    end;
  end;
  ModalResult := mrOk;
end;

procedure TFireFlowProgressForm.UpdateProgress(Percent: Integer);
begin
  Label1.Caption := IntToStr(Percent) + rsPcntCompleted;
  ProgressBar1.Position := Percent;
end;

end.

