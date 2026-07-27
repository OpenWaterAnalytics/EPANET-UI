{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       titleeditor
 Description:  a dialog form that edits a project's title
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit titleeditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TTitleEditorForm }

  TTitleEditorForm = class(TForm)
    OkBtn: TButton;
    CancelBtn: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure OkBtnClick(Sender: TObject);
    procedure Edit1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private

  public
    HasChanged: Boolean;

  end;

var
  TitleEditorForm: TTitleEditorForm;

implementation

{$R *.lfm}

uses
  project, config;

{ TTitleEditorForm }

procedure TTitleEditorForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  Edit1.Font.Size := Font.Size;
  Edit2.Font.Size := Font.Size;
  Edit3.Font.Size := Font.Size;
end;

procedure TTitleEditorForm.FormShow(Sender: TObject);
var
  I: Integer;
begin
  for I := 1 to 3 do
  begin
    with findComponent('Edit' + IntToStr(I)) as TEdit do
    begin
      Text := project.GetTitle(I-1);
    end;
  end;
  HasChanged := false;
end;

procedure TTitleEditorForm.OkBtnClick(Sender: TObject);
var
  I: Integer;
  Lines: array[1..3] of string;
begin
  for I := 1 to 3 do
  begin
    with findComponent('Edit' + IntToStr(I)) as TEdit do
    begin
      Lines[I] := Text;
    end;
  end;
  Project.SetTitle(Lines[1], Lines[2], Lines[3]);
end;

procedure TTitleEditorForm.Edit1Change(Sender: TObject);
begin
  HasChanged := true;
end;

end.

