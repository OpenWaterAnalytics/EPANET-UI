{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       statusrpt
 Description:  a frame to display a simulation's status report
               or an opened project file's error/warning report
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit statusrpt;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ExtCtrls, StdCtrls, Buttons, StrUtils,
  Clipbrd, Menus;

type

  { TStatusRptFrame }

  TStatusRptFrame = class(TFrame)
    ExportMenu: TPopupMenu;
    Memo1: TMemo;
    MnuSave:    TMenuItem;
    MnuCopy:    TMenuItem;

    procedure MnuCopyClick(Sender: TObject);
    procedure MnuSaveClick(Sender: TObject);

  private
    function FindText(Txt: string; StartPos: SizeUint): Integer;

  public
    procedure InitReport;
    procedure CloseReport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure ShowPopupMenu;

  end;

implementation

{$R *.lfm}

uses
  main, project, config, resourcestrings;

procedure TStatusRptFrame.InitReport;
begin
  Memo1.Font.Name := config.MonoFont;
end;

procedure TStatusRptFrame.ClearReport;
begin
  Memo1.Clear;
end;

procedure TStatusRptFrame.CloseReport;
begin
  Memo1.Clear;
end;

procedure TStatusRptFrame.RefreshReport;
begin
  with Memo1 do
  begin
    Clear;
    if FileExists(project.AuxFile) then
    begin
      Lines.LoadFromFile(project.AuxFile);
      if project.SimStatus = ssWarning then
        FindText('WARNING:', 1)
      else
        Memo1.SelStart := 0;
    end;
  end;
end;

procedure TStatusRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  ExportMenu.PopUp(P.x,P.y);
end;

procedure TStatusRptFrame.MnuCopyClick(Sender: TObject);
begin
  Memo1.SelectAll;
  Memo1.CopyToClipboard;
  Memo1.SelLength := 0;
end;

procedure TStatusRptFrame.MnuSaveClick(Sender: TObject);
begin
  with MainForm.SaveDialog1 do
  begin
    FileName := '*.txt';
    Filter := rsTextFile;
    DefaultExt := '*.txt';
    if Execute then Memo1.Lines.SaveToFile(FileName);
  end;
end;

function TStatusRptFrame.FindText(Txt: string; StartPos: SizeUint): Integer;
begin
  Result := PosEx(Txt, Memo1.Text, StartPos);
  if Result > 0 then
  begin
    Memo1.SelStart := Result - 1;
    Memo1.SelLength := Length(Txt);
////    Memo1.SetFocus;
  end;
end;

end.

