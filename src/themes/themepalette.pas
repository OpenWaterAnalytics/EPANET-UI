{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       themepalette
 Description:  a dialog form that selects a color palette used
               to display a theme on the pipe network map
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit themepalette;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls;

const
  MAXSCHEME = 12;  // Highest index of available color schemes
  MAXCOLOR = 5;    // Highest index of colors in a color scheme

type

  { TThemePaletteForm }

  TThemePaletteForm = class(TForm)
    Box10: TShape;
    Box11: TShape;
    Box12: TShape;
    Box13: TShape;
    Box14: TShape;
    Box15: TShape;
    Box16: TShape;
    Box17: TShape;
    Box18: TShape;
    Box19: TShape;
    Box20: TShape;
    Box21: TShape;
    Box22: TShape;
    Box23: TShape;
    Box24: TShape;
    Box25: TShape;
    Box26: TShape;
    Box27: TShape;
    Box28: TShape;
    Box29: TShape;
    Box30: TShape;
    Box31: TShape;
    Box32: TShape;
    Box33: TShape;
    Box34: TShape;
    Box35: TShape;
    Box36: TShape;
    Box37: TShape;
    Box38: TShape;
    Box39: TShape;
    Box40: TShape;
    Box41: TShape;
    Box42: TShape;
    Box43: TShape;
    Box44: TShape;
    Box45: TShape;
    Box46: TShape;
    Box47: TShape;
    Box48: TShape;
    Box49: TShape;
    Box50: TShape;
    Box51: TShape;
    Box52: TShape;
    Box53: TShape;
    Box54: TShape;
    Box55: TShape;
    Box56: TShape;
    Box57: TShape;
    Box58: TShape;
    Box59: TShape;
    Box6: TShape;
    Box60: TShape;
    Box7: TShape;
    Box8: TShape;
    Box9: TShape;
    Button1: TButton;
    Button2: TButton;
    Box1: TShape;
    Box2: TShape;
    Box3: TShape;
    Box4: TShape;
    Box5: TShape;
    RadioButton1: TRadioButton;
    RadioButton10: TRadioButton;
    RadioButton11: TRadioButton;
    RadioButton12: TRadioButton;
    RadioButton2: TRadioButton;
    RadioButton3: TRadioButton;
    RadioButton4: TRadioButton;
    RadioButton5: TRadioButton;
    RadioButton6: TRadioButton;
    RadioButton7: TRadioButton;
    RadioButton8: TRadioButton;
    RadioButton9: TRadioButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private

  public
    Colors: array [1..MAXCOLOR] of TColor;
  end;

var
  ThemePaletteForm: TThemePaletteForm;

implementation

{$R *.lfm}

uses
  config;

const
   SchemeColors: array[1..MAXSCHEME, 1..MAXCOLOR] of TColor =
   (($BE9270, $EAD999, $1DE6B5, $0EC9FF, $277FFF),  //Default
    ($FF0000, $FFFF00, $FF00,   $FFFF,   $FF),      //Rainbow
    ($CECB94, $7DCDDC, $776AC2, $964A9F, $54297E),  //Muted
    ($E5B533, $CC66AA, $CC99,   $33BBFF, $4444FF),  //Android
    ($4466A3, $4E97A8, $F39C35, $F14C14, $B3080E),  //Opera
    ($CCCCFF, $8080FF, $FF,     $99,     $66),      //Red
    ($CEE4FF, $99CCFF, $3399FF, $66CC,   $3399),    //Orange
    ($CEFFCE, $99FF99, $FF00,   $9900,   $6600),    //Green
    ($F9F9F9, $F0E5D1, $DEC48E, $C3933A, $AB6510),  //Blue
    ($FFCCFF, $FF99FF, $FF00CC, $CC0099, $660066),  //Purple
    ($ECD9FF, $CC99FF, $CC33FF, $9900CC, $660099),  //Magenta
    ($F8F8F8, $C0C0C0, $808080, $424242, $0));      //Gray


{ TThemePaletteForm }

procedure TThemePaletteForm.FormCreate(Sender: TObject);
var
  I: Integer;
  J: Integer;
  K: Integer;
begin
  Font.Size := config.FontSize;
  Color := config.ThemeColor;
  for I := 1 to MAXSCHEME do
  begin
    K := MAXCOLOR * (I - 1);
    for J := 1 to MAXCOLOR do
      with FindComponent('Box' + IntToStr(K + J)) as TShape do
        Brush.Color := SchemeColors[I,J];
  end;
end;

procedure TThemePaletteForm.Button1Click(Sender: TObject);
var
  I: Integer;
  J: Integer;
begin
  for I := 1 to MAXSCHEME do
  begin
    with FindComponent('RadioButton' + IntToStr(I)) as TRadioButton do
    begin
      if Checked then
      begin
        for J := 1 to MAXCOLOR do Colors[J] := SchemeColors[I,J];
        exit;
      end;
    end;
  end;
end;

end.

