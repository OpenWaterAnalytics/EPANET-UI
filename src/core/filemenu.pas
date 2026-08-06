{====================================================================
 Project:      EPANET-UI
 Version:      1.0.3
 Module:       filemenu
 Description:  a frame that presents file-related menu choices
 Authors:      see AUTHORS
 Copyright:    see AUTHORS
 License:      see LICENSE
 Last Updated: 06/19/2026
=====================================================================}

unit filemenu;

{
 This frame consists of a left and right panel. The left panel contains
 a MenuListBox that lists menu options. The right panel contains a
 Notebook control with two pages. Page1 contains a FilesListBox that
 displays a list of most recently used project files. Page2 lists
 import options and is only displayed when the Import option is
 selected from the MenuListBox.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls,
  ExtCtrls, LCLtype, ComCtrls, Menus, Types, FileCtrl;

type

  { TFileMenuFrame }

  TFileMenuFrame = class(TFrame)
    Bevel1:            TBevel;
    FilesListBox:      TListBox;
    HintPanel:         TPanel;
    ImportImageList:   TImageList;
    ImportListBox:     TListBox;
    MaterialImageList: TImageList;
    MenuListBox:       TListBox;
    Notebook1:         TNotebook;
    Page1:             TPage;
    Page2:             TPage;
    Panel1:            TPanel;
    Panel2:            TPanel;
    Panel3:            TPanel;

    procedure FilesListBoxClick(Sender: TObject);
    procedure FilesListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure FilesListBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FilesListBoxMouseEnter(Sender: TObject);
    procedure FilesListBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure FilesListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure ImportListBoxClick(Sender: TObject);
    procedure ImportListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure ImportListBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure ImportListBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MenuListBoxClick(Sender: TObject);
    procedure MenuListBoxDrawItem(Control: TWinControl; Index: Integer;
      ARect: TRect; State: TOwnerDrawState);
    procedure MenuListBoxKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure MenuListBoxMouseEnter(Sender: TObject);
    procedure MenuListBoxMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure MenuListBoxSelectionChange(Sender: TObject; User: boolean);
  private
    IconImageList: TImageList;
    procedure ShowRecentProjects;
    procedure ShowImportMenu;
    procedure ShowHintText(Index: Integer);

  public
    procedure Init;
    procedure ShowFrame;
    procedure HideFrame;
  end;

implementation

{$R *.lfm}

uses
  main, config, resourcestrings;

const
  MenuHints: array[0..7] of string =
    (rsExitMenu, rsNewProject, rsOpenProject, rsSaveProject,
     rsSaveProjectAs, rsImportData, rsConfigure, rsExitProgram);

  SelectionColor: TColor = $00ffe8cc;  //clHighlight;


procedure TFileMenuFrame.MenuListBoxClick(Sender: TObject);
begin
  if MenuListBox.ItemIndex < 0 then exit;

  // Import option selected - show the import menu
  if MenuListBox.ItemIndex = 5 then
  begin
    ShowImportMenu;
    exit;
  end;

  // Return focus to MainForm
  HideFrame;

  // Implement the selected option
  case MenuListBox.ItemIndex of
    1:
      MainForm.FileNew(True);
    2:
      MainForm.FileOpen;
    3:
      MainForm.FileSave;
    4:
      MainForm.FileSaveAs;
    6:
      MainForm.FileConfigure;
    7:
      MainForm.FileQuit;
  end;
//  HideFrame;
end;

procedure TFileMenuFrame.FilesListBoxClick(Sender: TObject);
var
  FileName: String;
begin
  if FilesListBox.ItemIndex < 0 then exit;
  HideFrame;
  MainForm.SetFocus;
  FileName := MainForm.MRUMenuMgr.Recent[FilesListBox.ItemIndex];
  MainForm.MRUMenuMgrRecentFile(Sender, FileName);
end;

procedure TFileMenuFrame.FilesListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
begin
  C := (Control As TListBox).Canvas;
  C.Brush.Color := FilesListBox.Color;
  C.Font.Color := clBlack;
  if Control.Focused and (odSelected in State) then
  begin
    C.Brush.Color := SelectionColor;
  end;
  if Control is TListBox then
  begin
    C.FillRect(ARect);
    C.TextOut(ARect.Left+2, ARect.Top+4, FilesListBox.Items[Index]);
  end;
end;

procedure TFileMenuFrame.FilesListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_LEFT then
  begin
    with MenuListBox do
    begin
      SetFocus;
      ShowHintText(ItemIndex);
      Key := 0;
    end
  end
  else if Key = VK_RETURN then FilesListBoxClick(Sender);
end;

procedure TFileMenuFrame.FilesListBoxMouseEnter(Sender: TObject);
begin
  FilesListBox.SetFocus;
end;

procedure TFileMenuFrame.FilesListBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  Index := FilesListBox.GetIndexAtXY(X, Y);
  if Index >= 0 then
  begin
    FilesListBox.ItemIndex := Index;
  end;
end;

procedure TFileMenuFrame.FilesListBoxSelectionChange(Sender: TObject;
  User: boolean);
var
  Index: Integer;
begin
  Index := FilesListBox.ItemIndex;
  if Index >= 0 then ShowHintText(Index);
end;

procedure TFileMenuFrame.ImportListBoxClick(Sender: TObject);
begin
  HideFrame;
  case ImportListBox.ItemIndex of
  0:
    MainForm.FileImport('shp');
  1:
    MainForm.FileImport('dxf');
  2:
    MainForm.FileImport('csv');
  end;
end;

procedure TFileMenuFrame.ImportListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
var
  C: TCanvas;
begin
  C := (Control as TListBox).Canvas;
  C.Brush.Color := ImportListBox.Color;
  C.Font.Color := clBlack;
  if (odSelected in State) then
  begin
    C.Brush.Color := SelectionColor;
  end;
  if Control is TListBox then
  begin
    C.FillRect(ARect);
    ImportImageList.Draw(C, ARect.Left + 8, ARect.Top+16, Index);
    C.TextOut(ARect.Left+48, ARect.Top+24, ImportListBox.Items[Index]);
  end;
end;

procedure TFileMenuFrame.ImportListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_LEFT) or (Key = VK_ESCAPE) then
  begin
    Key := 0;
    ShowRecentProjects;
    MenuListBox.SetFocus;
  end
  else if Key = VK_RETURN then
    ImportListBoxClick(Sender);
end;

procedure TFileMenuFrame.ImportListBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  Index := ImportListBox.GetIndexAtXY(X, Y);
  ImportListBox.ItemIndex := Index;
end;

procedure TFileMenuFrame.MenuListBoxDrawItem(Control: TWinControl;
  Index: Integer; ARect: TRect; State: TOwnerDrawState);
//
//  Draw an item (with icon image) on the Canvas of the MenuListBox.
//
var
  C: TCanvas;
  Yoffset: Integer;
  S: string;
begin
  C := (Control as TListBox).Canvas;
  C.Brush.Color := MenuListBox.Color;
  C.Font.Color := clBlack;
  if Control.Focused and (odSelected in State) then
  begin
    C.Brush.Color := SelectionColor;
  end;
  C.FillRect(ARect);
  Yoffset := (ARect.Height - IconImageList.Height) div 2;
  IconImageList.Draw(C, ARect.Left + 8, ARect.Top+Yoffset, Index);
  S := MenuListBox.Items[Index];
  Yoffset := (ARect.Height - C.TextHeight(S)) div 2;
  C.TextOut(ARect.Left+50, ARect.Top+Yoffset, S);
  Yoffset := (ARect.Height - C.TextHeight('>')) div 2;
end;

procedure TFileMenuFrame.MenuListBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    if Notebook1.PageIndex = 1 then
      ShowRecentProjects
    else
      HideFrame;
  end

  else if Key = VK_RETURN then
    MenuListBoxClick(Sender)

  else if Key = VK_RIGHT then
  begin
    Key := 0;
    if MenuListBox.ItemIndex = 5 then
      ShowImportMenu
    else if MenuListBox.ItemIndex = 2 then
    begin
      with FilesListBox do
      begin
        FilesListBox.SetFocus;
        if ItemIndex >= 0 then ShowHintText(ItemIndex);
      end;
    end;
  end;
end;

procedure TFileMenuFrame.MenuListBoxMouseEnter(Sender: TObject);
begin
  ShowRecentProjects;
  MenuListBox.SetFocus;
end;

procedure TFileMenuFrame.MenuListBoxMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  Index := MenuListBox.GetIndexAtXY(X, Y);
  if Index >= 0 then
  begin
    MenuListBox.ItemIndex := Index;
    HintPanel.Caption := MenuHints[Index];
  end;
end;

procedure TFileMenuFrame.MenuListBoxSelectionChange(Sender: TObject;
  User: boolean);
var
  Index: Integer;
begin
  Index := MenuListBox.ItemIndex;
  if Index >= 0 then HintPanel.Caption := MenuHints[Index];
end;

procedure TFileMenuFrame.Init;
begin
  IconImageList := MaterialImageList;
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
end;

procedure TFileMenuFrame.ShowFrame;
var
  I: Integer;
begin
  MainForm.EnableMainForm(false);
  MainForm.MapFrame.Enabled := false;
  Visible := true;
  Color := config.ThemeColor;
  MenuListBox.Color := Color;
  FilesListBox.Clear;

  if MainForm.MRUMenuMgr.Recent.Count > 0 then
  begin
    FilesListBox.Enabled := True;
    for I := 0 to MainForm.MRUMenuMgr.Recent.Count - 1 do
    begin
      FilesListBox.Items.Add(Format('%0:d.  %1:s',
        [I+1, ExtractFileName(MainForm.MRUMenuMgr.Recent[I])]));
    end;
    FilesListBox.ItemIndex := 0;
  end
  else
    FilesListBox.Enabled := False;

  ImportListBox.ItemIndex := 0;
  MenuListBox.ItemIndex := 0;
  MenuListBox.SetFocus;

end;

procedure TFileMenuFrame.HideFrame;
begin
  MainForm.EnableMainForm(true);
  MainForm.MapFrame.Enabled := true;
  Hide;
  MainForm.MainMenuFrame.SelectProjectMenu;
end;

procedure TFileMenuFrame.ShowRecentProjects;
begin
  Panel3.Caption := rsRecentProj;
  Notebook1.PageIndex := 0;
  MenuListBox.SetFocus;
end;

procedure TFileMenuFrame.ShowImportMenu;
begin
  Panel3.Caption := rsImportFrom;
  Notebook1.PageIndex := 1;
  ImportListBox.SetFocus;
end;

procedure TFileMenuFrame.ShowHintText(Index: Integer);
var
  Fname: string;
begin
  if MenuListBox.Focused then
    HintPanel.Caption := MenuHints[Index]
  else
  begin
    Fname := MainForm.MRUMenuMgr.Recent[Index];
    HintPanel.Caption := MinimizeName(Fname, HintPanel.Canvas, HintPanel.Width);
  end;
end;

end.

