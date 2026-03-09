{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       labeleditor
 Description:  a borderless form for entering a line of text
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit labeleditor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls;

type

  { TLabelEditorForm }

  TLabelEditorForm = class(TForm)
    Edit1: TEdit;
    procedure Edit1KeyPress(Sender: TObject; var Key: char);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
  private

  public

  end;

//var
//  LabelEditorForm: TLabelEditorForm;

implementation

{$R *.lfm}

{ TLabelEditorForm }

uses
  config;

procedure TLabelEditorForm.FormCreate(Sender: TObject);
begin
  Font.Size := config.FontSize;
end;

procedure TLabelEditorForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  CloseAction := caFree;
end;

procedure TLabelEditorForm.Edit1KeyPress(Sender: TObject; var Key: char);
begin
  if Key = #13 then
  begin
    Key := #0;
    ModalResult := mrOK;
  end;
  if Key = #27 then
  begin
    Key := #0;
    ModalResult := mrCancel;
  end;
end;

end.

