unit confirmsetup;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

type

  { TConfirmSetupForm }

  TConfirmSetupForm = class(TForm)
    AcceptBtn: TButton;
    CancelBtn: TButton;
    FlowCheckBox: TCheckBox;
    PressCheckBox: TCheckBox;
    Image1: TImage;
    Label1: TLabel;
    Label4: TLabel;
    RoughLabel: TLabel;
    Label6: TLabel;
    ResultsLabel: TLabel;
    Panel1: TPanel;
    Panel2: TPanel;
    FlowPanel: TPanel;
    PressPanel: TPanel;
    RoughPanel: TPanel;
    RadioButton1: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    TitlePanel: TPanel;
    FlowLabel: TLabel;
    PressLabel: TLabel;
  private

  public
    procedure Setup(FlowLabelTxt, FlowCheckBoxTxt, PressLabelTxt,
      PressCheckBoxTxt, RoughLabelTxt: string);

  end;

var
  ConfirmSetupForm: TConfirmSetupForm;

implementation

{$R *.lfm}

{ TConfirmSetupForm }

procedure TConfirmSetupForm.Setup(FlowLabelTxt, FlowCheckBoxTxt, PressLabelTxt,
  PressCheckBoxTxt, RoughLabelTxt: string);
begin
  if Length(FlowLabelTxt) > 0 then
  begin
    FlowLabel.Caption := FlowLabelTxt;
    FlowCheckBox.Caption:= FlowCheckBoxTxt;
  end
  else
  begin
    FlowPanel.Visible := false;
    Height := Height - FlowPanel.Height;
  end;
  if Length(PressLabelTxt) > 0 then
  begin
    PressLabel.Caption := PressLabelTxt;
    PressCheckBox.Caption:= PressCheckBoxTxt;
  end
  else
  begin
    PressPanel.Visible := false;
    Height := Height - PressPanel.Height;
  end;
  if Length(RoughLabelTxt) > 0 then
    RoughLabel.Caption := RoughLabelTxt
  else
  begin
    RoughPanel.Visible := false;
    Height := Height - RoughPanel.Height;
  end;
end;

end.

