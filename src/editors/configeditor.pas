{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       configeditor
 Description:  a dialog form that edits program preferences
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit configeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  lclIntf, ExtCtrls;

type

  { TConfigForm }

  TConfigForm = class(TForm)
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    CheckBox3: TCheckBox;
    CheckBox4: TCheckBox;
    CheckBox5: TCheckBox;
    CheckBox6: TCheckBox;
    CheckBox7: TCheckBox;
    CheckBox8: TCheckBox;
    Label1: TLabel;
    OkBtn: TButton;
    CancelBtn: TButton;
    HelpBtn: TButton;
    Panel1: TPanel;
    SpinEdit1: TSpinEdit;
    procedure FormCreate(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
  private

  public
    procedure GetPreferences(var ClearFileList: Boolean);
    procedure SetPreferences;

  end;

var
  ConfigForm: TConfigForm;

implementation

{$R *.lfm}

uses
  main, config;

procedure TConfigForm.FormCreate(Sender: TObject);
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
end;

procedure TConfigForm.SetPreferences;
begin
  CheckBox1.Checked := config.MapHiliter;
  CheckBox2.Checked := config.MapHinting;
  CheckBox3.Checked := config.ConfirmDeletions;
  CheckBox4.Checked := config.ShowWelcomePage;
  CheckBox5.Checked := config.OpenLastFile;
  CheckBox6.Checked := config.BackupFile;
  CheckBox7.Checked := config.ThemeColor = BlueTheme;
  SpinEdit1.Value := config.DecimalPlaces;
end;

procedure TConfigForm.HelpBtnClick(Sender: TObject);
begin
  MainForm.ViewHelp('#program_preferences');
end;

procedure TConfigForm.GetPreferences(var ClearFileList: Boolean);
begin
  config.MapHiliter       := CheckBox1.Checked;
  config.MapHinting       := CheckBox2.Checked;
  config.ConfirmDeletions := CheckBox3.Checked;
  config.ShowWelcomePage  := CheckBox4.Checked;
  config.OpenLastFile     := CheckBox5.Checked;
  config.BackupFile       := CheckBox6.Checked;
  if CheckBox7.Checked then
    config.ThemeColor := BlueTheme
  else
    config.ThemeColor := GrayTheme;
  FormColor := ThemeColor;
  config.DecimalPlaces := SpinEdit1.Value;
  ClearFileList := CheckBox8.Checked;
end;

end.

