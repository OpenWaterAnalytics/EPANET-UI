{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       projectviewer
 Description:  a form that displays all project data
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit projectviewer;

{ Displays all project data in a read-only table, one section at a time. }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, FileUtil, Forms, Controls, Graphics,
  Dialogs, ExtCtrls, StdCtrls, Grids, LCLType;

type

  { TProjectViewerForm }

  TProjectViewerForm = class(TForm)
    ListBox1:    TListBox;
    Panel1:      TPanel;
    Panel2:      TPanel;
    Panel3:      TPanel;
    Panel4:      TPanel;
    StringGrid1: TStringGrid;

    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShow(Sender: TObject);
    procedure ListBox1Click(Sender: TObject);
    procedure StringGrid1GetCellHint(Sender: TObject; ACol, ARow: Integer;
      var HintText: string);

  private
    { private declarations }
    procedure RefreshGrid;
    procedure SetGridColCount;
    function  StartOfDataSection(SectionName: string): Integer;
    function  LinesInDataSection(StartLine: Integer): Integer;
    procedure FillGridRow(Row: Integer; Value: string);

  public
    { public declarations }
  end;

var
  ProjectViewerForm: TProjectViewerForm;

implementation

{$R *.lfm}

uses
  main, project, config;

const
  Sections: array[0..22] of string =
    ('[TITLE]',    '[JUNCTIONS]', '[RESERVOIRS]', '[TANKS]',    '[PIPES]',
     '[PUMPS]',    '[VALVES]',    '[TAGS]',       '[DEMANDS]',  '[EMITTERS]',
     '[LEAKAGE]',  '[STATUS]',   '[PATTERNS]',  '[CURVES]',     '[QUALITY]',
     '[SOURCES]',  '[MIXING]',   '[CONTROLS]',  '[RULES]',      '[REACTIONS]',
     '[ENERGY]',   '[TIMES]',    '[OPTIONS]');

  Headings: array[0..22] of string =
    ('',
     'ID'#9'Elev',
     'ID'#9'Head'#9'Pattern',
     'ID'#9'Elev'#9'InitLvl'#9'MinLvl'#9'MaxLvl'#9'Diam'#9'MinVol'#9'Curve'#9'Overflow',
     'ID'#9'Node1'#9'Node2'#9'Length'#9'Diam'#9'Roughness'#9'Mloss'#9'Status',
     'ID'#9'Node1'#9'Node2',
     'ID'#9'Node1'#9'Node2'#9'Diam'#9'Type'#9'Setting'#9'Mloss',
     'Object'#9'ID'#9'Tag',
     'Junction'#9'Demand'#9'Pattern',
     'Junction'#9'Coeff',
     'Pipe'#9'Area'#9'Expansion',
     'Link'#9'Status',
     'ID'#9'Factors',
     'ID'#9'X-Value'#9'Y-Value',
     'Node'#9'Quality',
     'Node'#9'Type'#9'Strength'#9'Pattern',
     'Tank'#9'Model'#9'MixFrac',
     '',  //Controls
     '',  //Rules
     '',  //Reactions
     '',  //Energy
     '',  //Times
     ''); //Options


var
  S: TStringList;
  Line: TStringList;
  Section: Integer;

{ TProjectViewerForm }

procedure TProjectViewerForm.FormCreate(Sender: TObject);
var
  I: Integer;
begin
  Color := config.FormColor;
  Font.Size := config.FontSize;
  StringGrid1.Font.Name := config.MonoFont;
  StringGrid1.AlternateColor := config.AlternateColor;
  StringGrid1.FixedColor := config.ThemeColor;
  Panel3.Color := config.ThemeColor;
  ListBox1.Font.Name := config.MonoFont;

  Left := MainForm.Left + 4;
  Top := MainForm.MainPanel.ClientToScreen(Point(0,0)).Y;
  Width := MainForm.Width - MainForm.ProjectPanel.Width - 8;
  Height := MainForm.MainPanel.Height - MainForm.StatusPanel.Height;

  // S stores the project's data in input file format
  S := TStringList.Create;
  Line := TStringList.Create;
  Line.Delimiter := ' ';
  for I := 0 to High(Sections) do
    ListBox1.Items.Add(Sections[I]);
end;

procedure TProjectViewerForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then ModalResult := mrOK;
end;

procedure TProjectViewerForm.FormShow(Sender: TObject);
begin
  // Export the project's data to string list S
  project.Save(project.AuxFile);
  S.LoadFromFile(project.AuxFile);
  SysUtils.DeleteFile(project.AuxFile);

  // Initialize the current data section and list box selection
  Section := -1;
  ListBox1.ItemIndex := 0;

  // Force the list box to display data for the first section
  ListBox1Click(Self);
  ListBox1.SetFocus;
end;

procedure TProjectViewerForm.ListBox1Click(Sender: TObject);
begin
  with ListBox1 do
  begin
    // Display selected section of project data in the string grid
    if ItemIndex <> Section then
    begin
      Section := ItemIndex;
      RefreshGrid;
      StringGrid1.Row := 1;
      StringGrid1.Col := 0;
    end;
  end;
end;

procedure TProjectViewerForm.StringGrid1GetCellHint(Sender: TObject; ACol,
  ARow: Integer; var HintText: string);
begin
  HintText := StringGrid1.Cells[ACol, ARow];
end;

procedure TProjectViewerForm.FormClose(Sender: TObject; var CloseAction: TCloseAction
  );
begin
  Line.Free;
  S.Free;
end;

procedure TProjectViewerForm.RefreshGrid;
var
  I: Integer;
  K: Integer;
  N: Integer;
begin
  SetGridColCount;
  I := StartOfDataSection(Listbox1.Items[Section]);
  N := LinesInDataSection(I);
  StringGrid1.RowCount := StringGrid1.FixedRows + N;
  FillGridRow(0, Headings[Section]);
  if N > 0 then
  begin
    N := 0;
    for K := I + 1 to S.Count - 1 do
    begin
      // Stop when next section encountered
      if AnsiLeftStr(S[K], 1) = '[' then break;
      if Length(S[K]) = 0 then continue;
      if AnsiLeftStr(S[K], 2) = ';;' then continue;
      Inc(N);
      if (StringGrid1.ColCount = 1)
      // Place comment in first column
      or (AnsiLeftStr(S[K], 1) = ';')  then
        StringGrid1.Cells[0, N] := S[K]
      else
        FillGridRow(N, S[K]);
    end;
  end;
end;

procedure TProjectViewerForm.SetGridColCount;
begin
  with StringGrid1 do
  begin
    Clear;
    if (Section = 0)
    or (Section > 13) then
    begin
      ColCount := 1;
      Options := Options - [goHorzLine];
    end
    else
    begin
      ColCount := 9;
      Options := Options + [goHorzLine];
    end;
  end;
end;

function TProjectViewerForm.StartOfDataSection(SectionName: string): Integer;
var
  J: Integer;
begin
  Result := -1;
  for J := 0 to S.Count-1 do
  begin
    if AnsiStartsStr(SectionName, S[J]) then
    begin
      Result := J;
      break;
    end;
  end;
end;

function TProjectViewerForm.LinesInDataSection(StartLine: Integer): Integer;
var
  K: Integer;
begin
  Result := 0;
  if (StartLine >= 0) then
  begin
    for K := StartLine + 1 to S.Count - 1 do
    begin
      if AnsiLeftStr(S[K], 2) = ';;' then continue;
      if Length(S[K]) = 0 then continue;
      if AnsiLeftStr(S[K], 1) = '[' then break;
      Inc(Result);
    end;
  end;
end;

procedure TProjectViewerForm.FillGridRow(Row: Integer; Value: string);
var
  Col : Integer;
begin
  Line.DelimitedText := Value;
  for Col := 0 to StringGrid1.ColCount - 1 do
    if Col < Line.Count then
      StringGrid1.Cells[Col, Row] := Line[Col];
end;

end.

