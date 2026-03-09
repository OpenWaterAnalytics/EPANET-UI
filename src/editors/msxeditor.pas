{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       msxeditor
 Description:  a form used to edit EPANET-MSX input data
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
{
 The MsxEditorForm consists of a MenuPanel used to select a
 category of MSX input to edit, a MainPanel that contains a
 Notebook with pages used to edit each MSX data category, a
 normally hidden SymbolsPanel used to list reserved variable
 names that can be used in reaction expressions, and a
 ButtonPanel that contains various action buttons.
 ________________________________________________________
 |            |                          |              |
 |  MenuPanel |         MainPanel        | SymbolsPanel |
 |            |                          |              |
 |            |                          |              |
 |            |                          |              |
 |____________|__________________________|______________|
 |                     ButtonPanel                      |
 |______________________________________________________|

Main Panel Notebook Pages:
  Overview: brief description of the editor and its commands
  Options: MSX analysis options
  Species: names species to analyze in StringGrid1
  Pipes:   edits pipe reaction expressions in StringGrid2
  Tanks:   edits tank reaction expressions in StringGrid3
  Terms:   edits terms used in reaction expressions in StringGrid4
  Coeffs:  edits coefficients used in terms & reactions in StringGrid5
  Params:  assigns coefficient values to specific pipes in StringGrid6
  Quality: assigns initial quality to nodes in StrinGrid7
  Sources: assigns WQ sources to nodes in StringGrid8
}

unit msxeditor;

{$mode objfpc}{$H+}
{$modeswitch nestedprocvars}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Grids, Menus, ComCtrls, Buttons, HtmlView, SpinEx, lclintf,
  Clipbrd, HTMLUn2, HtmlGlobals, LCSVUtils, FileUtil;

type

  { TMsxEditorForm }

  TMsxEditorForm = class(TForm)
    ComboBox1:         TComboBox;
    ComboBox2:         TComboBox;
    ComboBox3:         TComboBox;
    ComboBox4:         TComboBox;
    ComboBox5:         TComboBox;
    EditingToolBar:    TToolBar;
    SymbolsBtn:        TToolButton;
    InsertBtn:         TToolButton;
    RemoveBtn:         TToolButton;
    CopyBtn:           TToolButton;
    CutBtn:            TToolButton;
    PasteBtn:          TToolButton;
    MoveDnBtn:         TToolButton;
    MoveUpBtn:         TToolButton;
    CloseBtn:          TButton;
    CancelBtn:         TButton;
    LoadBtn:           TButton;
    SaveAsBtn:         TButton;
    ClearBtn:          TButton;
    HelpBtn:           TButton;
    TitleEdit:         TEdit;
    FloatSpinEditEx1:  TFloatSpinEditEx;
    FloatSpinEditEx2:  TFloatSpinEditEx;
    FloatSpinEditEx3:  TFloatSpinEditEx;
    FloatSpinEditEx4:  TFloatSpinEditEx;
    FloatSpinEditEx5:  TFloatSpinEditEx;
    HtmlViewer1b:      THtmlViewer;
    HtmlViewer1a:      THtmlViewer;
    HtmlViewer2:       THtmlViewer;
    OfficeImageList:   TImageList;
    MaterialImageList: TImageList;
    Label1:            TLabel;
    Label10:           TLabel;
    Label11:           TLabel;
    Label2:            TLabel;
    Label3:            TLabel;
    Label4:            TLabel;
    Label5:            TLabel;
    Label6:            TLabel;
    Label7:            TLabel;
    Label8:            TLabel;
    Label9:            TLabel;
    Panel3:            TPanel;
    InstructPanel:     TPanel;
    IntroPanel:        TPanel;
    InstructTextPanel: TPanel;
    ButtonPanel:       TPanel;
    MainPanel:         TPanel;
    SymbolsPanel:      TPanel;
    TitlePanel:        TPanel;
    ImagePanel:        TPanel;
    MenuPanel:         TPanel;
    Panel2:            TPanel;
    Image1:            TImage;
    ImageList1:        TImageList;
    OpenDialog1:       TOpenDialog;
    SaveDialog1:       TSaveDialog;
    SectionListBox:    TListBox;
    Notebook1:         TNotebook;
    Options:           TPage;
    Overview:          TPage;
    Coeffs:            TPage;
    Params:            TPage;
    Pipes:             TPage;
    Quality:           TPage;
    Sources:           TPage;
    Species:           TPage;
    Tanks:             TPage;
    Terms:             TPage;
    StringGrid1:       TStringGrid;
    StringGrid5:       TStringGrid;
    StringGrid4:       TStringGrid;
    StringGrid2:       TStringGrid;
    StringGrid3:       TStringGrid;
    StringGrid8:       TStringGrid;
    StringGrid7:       TStringGrid;
    StringGrid6:       TStringGrid;

    procedure ClearBtnClick(Sender: TObject);
    procedure CopyBtnClick(Sender: TObject);
    procedure CutBtnClick(Sender: TObject);
    procedure TitleEditChange(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure HelpBtnClick(Sender: TObject);
    procedure HtmlViewer1bHotSpotClick(Sender: TObject; const SRC: ThtString;
      var Handled: Boolean);
    procedure InsertBtnClick(Sender: TObject);
    procedure MoveDnBtnClick(Sender: TObject);
    procedure MoveUpBtnClick(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure LoadBtnClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure PasteBtnClick(Sender: TObject);
    procedure RemoveBtnClick(Sender: TObject);
    procedure SaveAsBtnClick(Sender: TObject);
    procedure SectionListBoxClick(Sender: TObject);
    procedure StringGrid1ColRowInserted(Sender: TObject; IsColumn: Boolean;
      sIndex, tIndex: Integer);
    procedure StringGrid1SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid1SetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
    procedure StringGrid5SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid2SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid3SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid8EditButtonClick(Sender: TObject);
    procedure StringGrid8SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid7SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure StringGrid6SelectEditor(Sender: TObject; aCol, aRow: Integer;
      var Editor: TWinControl);
    procedure SymbolsBtnClick(Sender: TObject);

  private
    MsxFile:     string;
    FocusedGrid: TStringGrid;
    procedure ClearAll;
    procedure SelectionSetText(TheText: string);
    procedure ReadMsxFile(Filename: string);
    function  GetNewMsxFile: string;

  public
    HasChanged: Boolean;
    procedure SetMsxFile(FileName: string);
    procedure GetMsxFile(var FileName: string);

  end;

var
  MsxEditorForm: TMsxEditorForm;

implementation

{$R *.lfm}

uses
  project, config, msxfileprocs, patterneditor, utils;

resourcestring
  rsSaveMsg        = 'Please save your newly created MSX model.';
  rsShowSymbolsMsg = 'Show Reserved Symbols Panel';
  rsHideSymbolsMsg = 'Hide Reserved Symbols Panel';
  rsReplaceMsg     = 'Do you wish to replace all current MSX data with';
  rsRemoveMsg      = 'Do you wish to remove all current MSX data from the project.';

// File msxtext.txt contains text for the following String variables:
// IntroA, IntroB, Instructs, and Symbols.
{$I msxtext.txt}

const

  // Default choices for ComboBox1 to ComboBox5
  DefListOptions: array[1..5] of Integer =
    (0, 2, 0, 0, 0);

  // Default values for FloatSpinEditEx1 to FloatSpinEditEx5
  DefValueOptions: array[1..5] of Double =
    (300, 0.01000, 0.01000, 5000, 1000);

  ShowSymbolsImageIndex = 7;
  HideSymbolsImageIndex = 8;

{ TMsxEditorForm }

procedure TMsxEditorForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Color := config.ThemeColor;
  TitlePanel.Color := Color;
  Font.Size := config.FontSize;

  // Set platform-specific mono-spaced font for all StringGrids
  for I := 1 to 8 do
  begin
    with FindComponent('StringGrid' + IntToStr(I)) as TStringGrid do
    begin
      Font.Name := config.MonoFont;
      FixedColor := config.ThemeColor;
    end;
  end;

  // HtmlViewers used to display an introduction to the editor
  HtmlViewer1a.DefFontColor := clBlack;
  HtmlViewer1b.DefFontColor := clBlack;
  HtmlViewer1a.DefFontSize := 10;  //Font.Size;
  HtmlViewer1b.DefFontSize := 10;  //Font.Size;
  HtmlViewer1a.DefBackground := $00E0FFFF;  //clCream
  HtmlViewer1b.DefBackground := $00E0FFFF;  //clCream
  HtmlViewer1a.LoadFromString(IntroA);
  HtmlViewer1b.LoadFromString(IntroB);

  // HtmlViewer2 displays reserved variable names in the SymbolsPanel
  HtmlViewer2.DefFontSize := Font.Size;
  HtmlViewer2.LoadFromString(Symbols);
  SymbolsPanel.Visible := false;

  SectionListBox.ItemIndex := 0;
  Notebook1.PageIndex := 0;
  InstructPanel.Visible := false;

  // Initialize the editing toolbar used with StringGrids
  if SameText(config.IconFamily, 'Material') then
    EditingToolBar.Images := MaterialImageList
  else
    EditingToolBar.Images := OfficeImageList;
  EditingToolBar.Visible := false;
  Clipboard.Clear;
  Clipboard.asText := '';

  // Clear all data entry fields
  MsxFile := '';
  ClearAll;
  HasChanged := false;
  FocusedGrid := nil;
end;

procedure TMsxEditorForm.SetMsxFile(FileName: string);
begin
  if FileExists(FileName) then
  begin
    MsxFile := Filename;
    Caption := 'Msx Editor - ' + MsxFile;
  end
  else
    MsxFile := '';
end;

procedure TMsxEditorForm.GetMsxFile(var FileName: string);
begin
  FileName := MsxFile;
end;

function TMsxEditorForm.GetNewMsxFile: string;
var
  CurrentMsxFile: string;
  CurrentMsxDir: string;
begin
  Result := '';
  CurrentMsxFile := MsxFile;
  CurrentMsxDir := ExtractFileDir(CurrentMsxFile);
  if Length(CurrentMsxDir) = 0 then
    CurrentMsxDir := ExtractFileDir(project.InpFile);
  with SaveDialog1 do
  begin
    if Length(CurrentMsxFile) > 0 then
      FileName := CurrentMsxFile
    else
      FileName := '*.msx';
    if Length(CurrentMsxDir) > 0 then
      InitialDir := CurrentMsxDir;
    Filter := 'EPANET MSX Files|*.msx|All Files|*.*';
    if Execute then
      Result := FileName;
  end;
end;

procedure TMsxEditorForm.FormShow(Sender: TObject);
begin
  if FileExists(MsxFile) then
    ReadMsxFile(MsxFile);
end;

procedure TMsxEditorForm.HtmlViewer1bHotSpotClick(Sender: TObject;
  const SRC: ThtString; var Handled: Boolean);
begin
  OpenUrl('https://epanetmsx2manual.readthedocs.io/en/latest/1_introduction.html');
end;

procedure TMsxEditorForm.TitleEditChange(Sender: TObject);
// Shared by all input controls on the Options page
begin
  HasChanged := true;
end;

//------------------------------------------------------------------------------
//  ButtonPanel Procedures
//------------------------------------------------------------------------------

procedure TMsxEditorForm.CancelBtnClick(Sender: TObject);
begin
  Close;
end;

procedure TMsxEditorForm.LoadBtnClick(Sender: TObject);
var
  R: Integer;
  NewFileName: string;
begin
  // Get the name of the new MSX file to load
  NewFileName := '';
  with OpenDialog1 do
  begin
    Filter := 'MSX Files|*.msx';
    FileName := '*.msx';
    if Execute then NewFileName := FileName;
  end;
  if Length(NewFileName) = 0 then exit;

  // Ask if all existing editor contents should be replaced
  if HasChanged or (Length(MsxFile) > 0 )then
  begin
    R := utils.MsgDlg(
      '', rsReplaceMsg + LineEnding +
        ExtractFileName(NewFileName), mtConfirmation, [mbYes, mbNo]);
    if R <> mrYes then exit;
  end;

  // Clear the editor's contents and load the new MSX file
  ClearAll;
  MsxFile := NewFileName;
  ReadMsxFile(MsxFile);
  Caption := 'MSX Editor - ' + MsxFile;
  HasChanged := true;
end;

procedure TMsxEditorForm.ReadMsxFile(Filename: string);
begin
  msxfileprocs.ReadMsxFile(self, Filename);
  SectionListBox.ItemIndex := 1;
  SectionListBoxClick(self);
end;

procedure TMsxEditorForm.SaveAsBtnClick(Sender: TObject);
var
  NewMsxFile: string;
begin
  NewMsxFile := GetNewMsxFile;
  if Length(NewMsxFile) > 0 then
  begin
    MsxFile := NewMsxFile;
    msxfileprocs.WriteMsxFile(self, MsxFile);
    Caption := 'Msx Editor - ' + MsxFile;
    HasChanged := true;
  end;
end;

procedure TMsxEditorForm.CloseBtnClick(Sender: TObject);
begin
  if Length(MsxFile) = 0 then
  begin
    if HasChanged then
    begin
      SaveAsBtnClick(Sender);
      if Length(MsxFile) = 0 then exit;
    end
    else ModalResult := mrOK;
  end
  else if HasChanged then
    msxfileprocs.WriteMsxFile(self, MsxFile);
  ModalResult := mrOK;
end;

procedure TMsxEditorForm.HelpBtnClick(Sender: TObject);

const
  HelpTopics: array[1..9] of string =
    ('#options','#species','#pipes','#tanks','#terms','#coefficients',
     '#parameters','#quality','#sources');
var
  I: Integer;
  Url: string = 'https://epanetmsx2manual.readthedocs.io/en/latest/';
begin
  I := SectionListBox.ItemIndex;
  if I = 0 then
    Url := Url + '1_introduction.html'
  else
    Url := Url + '4_inputformat.html' + HelpTopics[I];
  OpenUrl(Url);
end;

procedure TMsxEditorForm.ClearBtnClick(Sender: TObject);
var
  R: Integer;
begin
  R := utils.MsgDlg('', rsRemoveMsg, mtConfirmation, [mbYes, mbNo]);
  if R = mrYes then
  begin
    ClearAll;
    MsxFile := '';
    Caption := 'MSX Editor';
  end;
end;

procedure TMsxEditorForm.ClearAll;
var
  I: Integer;
begin
  // Initialize the StringGrid editors
  for I := 1 to 8 do
  begin
    with FindComponent('StringGrid' + IntToStr(I)) as TStringGrid do
    begin
      FastEditing := false;
      RowCount := 1;  // The header row
    end;
  end;

  // Initialize contents of Notebook1's Options page
  TitleEdit.Text := '';
  for I := 1 to 5 do
  begin
    with FindComponent('ComboBox' + IntToStr(I)) as TComboBox do
      ItemIndex := DefListOptions[I];
  end;
  for I := 1 to 5 do
  begin
    with FindComponent('FloatSpinEditEx' + IntToStr(I)) as TFloatSpinEditEx do
      Value := DefValueOptions[I];
  end;
  HasChanged := false;
end;

//------------------------------------------------------------------------------
//  StringGrid Procedures
//------------------------------------------------------------------------------

procedure TMsxEditorForm.SectionListBoxClick(Sender: TObject);
var
  I: Integer;
begin
  I := SectionListBox.ItemIndex;
  Notebook1.PageIndex := I;
  if I > 0 then
  begin
    InstructPanel.Visible := true;
    InstructTextPanel.Caption := Instructs[I];
  end
  else
    InstructPanel.Visible := false;
  if I > 1 then
  begin
    EditingToolBar.Visible := true;
    FocusedGrid := FindComponent('StringGrid' + IntToStr(I-1)) as TStringGrid;
  end
  else
  begin
    EditingToolBar.Visible := false;
    FocusedGrid := nil;
  end;
  SymbolsPanel.Visible := false;
  SymbolsBtn.Visible := (I in [3,4,5]);
  SymbolsBtn.Hint := rsShowSymbolsMsg;
  SymbolsBtn.ImageIndex := ShowSymbolsImageIndex;
end;

procedure TMsxEditorForm.StringGrid1ColRowInserted(Sender: TObject; IsColumn: Boolean;
  sIndex, tIndex: Integer);
//
// Initialize the selection in a PickList column when a new row is inserted
// into a StringGrid -- shared handler for all of the editor's StringGrids.
//
var
  C: Integer;
  R: Integer;
begin
  with Sender as TStringGrid do
  begin
    R := RowCount - 1;
    for C := 0 to ColCount-1 do
    begin
      if Columns[C].PickList.Count > 0 then
        Cells[C,R] := Columns[C].PickList[0];
    end;
  end;
end;

procedure TMsxEditorForm.StringGrid1SetEditText(Sender: TObject; ACol,
  ARow: Integer; const Value: string);
begin
  HasChanged := true;
end;

procedure TMsxEditorForm.StringGrid1SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if (aCol = 0)
  or (aCol = 2) then
  begin
    Editor := StringGrid1.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid2SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if aCol = 0 then
  begin
    Editor := StringGrid2.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid3SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if aCol = 0 then
  begin
    Editor := StringGrid3.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid5SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if aCol = 0 then
  begin
    Editor := StringGrid5.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid6SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if aCol = 0 then
  begin
    Editor := StringGrid6.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid7SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if aCol = 0 then
  begin
    Editor := StringGrid7.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid8SelectEditor(Sender: TObject; aCol,
  aRow: Integer; var Editor: TWinControl);
begin
  if aCol = 0 then
  begin
    Editor := StringGrid8.EditorByStyle(cbsPickList);
    if Editor is TCustomComboBox then
      with Editor as TCustomComboBox do Style := csDropDownList;
  end;
end;

procedure TMsxEditorForm.StringGrid8EditButtonClick(Sender: TObject);
var
  S: string;
  PatSelector: TPatternEditorForm;
begin
  with StringGrid8 do S := Cells[Col,Row];
  PatSelector := TPatternEditorForm.Create(self);
  try
    PatSelector.Setup(S);
    PatSelector.ShowModal;
    if PatSelector.ModalResult = mrOK then
    begin
      with StringGrid8 do Cells[Col,Row] := PatSelector.SelectedName;
      if not SameText(PatSelector.SelectedName, S) then HasChanged := true;
    end;
  finally
    PatSelector.Free;
  end;
end;

//------------------------------------------------------------------------------
// EditingToolbar Procedures
//------------------------------------------------------------------------------

procedure TMsxEditorForm.CopyBtnClick(Sender: TObject);
begin
  if Assigned(FocusedGrid) then with FocusedGrid do
  begin
    CopyToClipboard(true);
  end;
end;

procedure TMsxEditorForm.CutBtnClick(Sender: TObject);
begin
  if Assigned(FocusedGrid) then with FocusedGrid do
  begin
    CopyToClipboard(true);
    Clean(TRect(Selection), [gzNormal]);
  end;
end;

procedure TMsxEditorForm.PasteBtnClick(Sender: TObject);
begin
  if FocusedGrid <> nil then with FocusedGrid do
  begin
     SelectionSetText(Clipboard.AsText);
  end;
end;

procedure TMsxEditorForm.SelectionSetText(TheText: string);
// Used to paste text from the clipboard into the StringGrid that has focus
var
  StartCol: Integer;
  StartRow: Integer;
  Stream: TStringStream;

  ///// Nested procedure ////
  procedure LoadTSV(Fields: TStringList);
  var
    I: Integer;
    aCol: Integer;
    aRow: Integer;
    NewValue: string;
  begin
    if StartRow < FocusedGrid.RowCount then
    begin
      aRow := StartRow;
      for I := 0 to Fields.Count - 1 do
      begin
        aCol := StartCol + I;
        if aCol < FocusedGrid.ColCount then
        begin
          NewValue := Fields[I];
          FocusedGrid.Cells[aCol, aRow] := NewValue;
        end;
      end;
      Inc(StartRow);
    end;
  end;
  //////////////////////////

begin
  Stream := TStringStream.Create(TheText);
  try
    StartCol := FocusedGrid.Selection.left;
    StartRow := FocusedGrid.Selection.Top;
    LCSVUtils.LoadFromCSVStream(Stream, @LoadTSV, #9);
  finally
    Stream.Free;
  end;
end;

procedure TMsxEditorForm.InsertBtnClick(Sender: TObject);
begin
  if Assigned(FocusedGrid) then with FocusedGrid do
  begin
    RowCount := RowCount + 1;
  end;
end;

procedure TMsxEditorForm.RemoveBtnClick(Sender: TObject);
begin
  if FocusedGrid <> nil then with FocusedGrid do
  begin
    if RowCount > 1 then DeleteRow(Selection.Top);
  end;
end;

procedure TMsxEditorForm.MoveDnBtnClick(Sender: TObject);
begin
  if Assigned(FocusedGrid) then with FocusedGrid do
  begin
    if (RowCount > 1) then MoveColRow(false, Row, Row+1);
  end;
end;

procedure TMsxEditorForm.MoveUpBtnClick(Sender: TObject);
begin
  if Assigned(FocusedGrid) then with FocusedGrid do
  begin
    if (RowCount > 1) then MoveColRow(false, Row, Row-1);
  end;
end;

procedure TMsxEditorForm.SymbolsBtnClick(Sender: TObject);
begin
  if SymbolsBtn.ImageIndex = ShowSymbolsImageIndex then
  begin
    SymbolsPanel.Visible := true;
    SymbolsBtn.ImageIndex := HideSymbolsImageIndex;
    SymbolsBtn.Hint := rsHideSymbolsMsg;
  end
  else
  begin
    SymbolsPanel.Visible := false;
    SymbolsBtn.ImageIndex := ShowSymbolsImageIndex;
    SymbolsBtn.Hint := rsShowSymbolsMsg;
  end;
end;

end.

