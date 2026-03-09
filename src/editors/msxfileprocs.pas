{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       msxfileprocs
 Description:  procedures for reading and writing a MSX data file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

{ This unit references the properties of components
  appearing on the MsxEditorForm in msxeditor.pas.}

unit msxfileprocs;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, Forms, Controls, ExtCtrls, StdCtrls,
  Grids, SpinEx, msxeditor,    Dialogs;

procedure ReadMsxFile(MsxEditorForm: TMsxEditorForm; Filename: string);
procedure WriteMsxFile(MsxEditorForm: TMsxEditorForm; Filename: string);

implementation

uses
  project, epanet2;

const

  // To detect sections when reading a MSX data file
  ReadSections: array[0..12] of string =
    ('[TITLE', '[OPTIONS', '[SPECIES', '[PIPE', '[TANK', '[TERM', '[COEFF',
      '[PARAM', '[QUAL', '[SOURCE', '[PATTERN', '[DIFFUS', '[REPORT');

  // Section names for writing a MSX data file
  WriteSections: array[0..11] of string =
  ('[TITLE]', '[OPTIONS]', '[SPECIES]', '[PIPES]', '[TANKS]', '[TERMS]',
   '[COEFFICIENTS]', '[PARAMETERS]', '[QUALITY]', '[SOURCES]', '[PATTERNS]',
   '[DIFFUSIVITY]');

  // MSX options with values from a list of choices
  ListOptions: array[0..4] of string =
    ('AREA_UNITS', 'RATE_UNITS', 'SOLVER', 'COUPLING', 'COMPILER');

  // MSX options with numerical values
  ValueOptions: array[0..4] of string =
    ('TIMESTEP', 'ATOL', 'RTOL', 'SEGMENTS', 'PECLET');

var
  EditorForm: TMsxEditorForm;
  Comment: string;
  PrevPatnID: string;
  PatnStr: string;
  Patterns: TStringList;

function  FindSection(S: string): Integer;
var
  I: Integer;
begin
  Result := -1;
  for I := 0 to High(ReadSections) do
  begin
    if AnsiStartsText(ReadSections[I], S) then
    begin
      Result := I;
      if Length(PatnStr) > 0 then
      begin
        Patterns.Add(PatnStr);
        PatnStr := '';
      end;
      exit;
    end;
  end;
end;

procedure ParseOption(Tokens: TStringlist);
var
  I: Integer;
  S: string;
  V: Double;
begin
  if Tokens.Count < 2 then exit;
  S := UpperCase(Tokens[1]);
  I := AnsiIndexText(Tokens[0], ListOptions);
  if I >= 0 then
  begin
    with EditorForm.FindComponent('ComboBox' + IntToStr(I+1)) as TComboBox do
      Text := S
  end
  else
  begin
    I := AnsiIndexText(Tokens[0], ValueOptions);
    if (I >= 0)
    and TryStrToFloat(S, V) then
      with EditorForm.FindComponent('FloatSpinEditEx' + IntToStr(I+1))
        as TFloatSpinEditEx do Value := V;
  end;
end;

procedure ParsePattern(Tokens: TStringlist);
var
  PatnID: string;
  I: Integer;
begin
  // A new pattern begins -- save previous one
  PatnID := Tokens[0];
  if not SameText(PatnID, PrevPatnID) then
  begin
    if Length(PatnStr) > 0 then Patterns.Add(PatnStr);
    PatnStr := PatnID + ' , ' + Comment;
    PrevPatnID := PatnID;
  end;

  // Add multipliers on to PatnStr
  for I := 1 to Tokens.Count - 1 do
    PatnStr := PatnStr + ' , ' + Tokens[I];
end;

procedure AddPatternsToProject;
var
  I: Integer;
  J: Integer;
  N: Integer;
  aID: string;
  aComment: string;
  aIndex: Integer;
  aPattern: TStringList;
  X: Single;
  Multipliers: array of Single;
begin
  // aPattern holds the data for a comma delimited pattern
  aPattern := TStringList.Create;

  try
    // Examine each pattern created by reading the MSX file
    aPattern.StrictDelimiter := true;
    for I := 0 to Patterns.Count - 1 do
    begin
      // aPattern is the delimited pattern data
      aPattern.CommaText := Patterns[I];

      // Retrieve the pattern's ID name and comment
      aID := Trim(aPattern[0]);
      aComment := Trim(aPattern[1]);

      // See if the pattern already appears in the EPANET project
      if project.GetItemIndex(ctPatterns, aID) > 0 then continue;

      // Create a new pattern in the EPANET project
      if epanet2.ENaddpattern(PChar(aID)) > 0 then continue;
      aIndex := project.GetItemCount(ctPatterns);
      if Length(aComment) > 0 then
        epanet2.ENsetcomment(EN_TIMEPAT, aIndex, PAnsiChar(aComment));

      // Store aPattern's multiplier strings in an array of floats
      N := aPattern.Count - 2;
      SetLength(Multipliers, N);
      for J := 2 to aPattern.Count - 1 do
      begin
        if TryStrToFloat(aPattern[J], X) then
          Multipliers[J - 2] := X
        else
          Multipliers[J - 2] := 1.0;
      end;

      // Add the multipliers to the EPANET project's pattern
      epanet2.ENsetpattern(aIndex, Multipliers[0], N);
    end;

  finally
    aPattern.Free;
  end;
end;

procedure ParseDiffusivity(Tokens: TStringList);
var
  R: Integer;
  Grid: TStringGrid;
begin
  // Diffusivity is added into the Editor's StringGrid1 for Species
  Grid := EditorForm.StringGrid1;

  // Find which row of Grid is for this specie's diffusivity
  for R := 1 to Grid.RowCount - 1 do
  begin
    // Row is found so insert diffusivity value into column 5
    if SameText(Trim(Grid.Cells[1,R]), Tokens[0]) then
    begin
      Grid.Cells[5, R] := Tokens[1];
      exit;
    end;
  end;
end;

procedure ParseLine(Section: Integer; Grid: TStringGrid; Tokens: TStringlist);
var
  I: Integer;
  J: Integer;
  N: Integer;
  M: Integer;
  S: string;
begin
  J := Grid.RowCount - 1;
  N := Tokens.Count;
  if Section = 2 then  //Species section
  begin
    M := 2;
    if N < 3 then M := N - 1;
    for I := 0 to M do Grid.Cells[I,J] := Tokens[I];
    if N > 3 then Grid.Cells[3,J] := Tokens[3];
    if N > 4 then Grid.Cells[4,J] := Tokens[4];
  end
  else if Section = 5 then //Terms section
  begin
    Grid.Cells[0,J] := Tokens[0];
    S := '';
    for I := 1 to N-1 do S := S + Tokens[I] + ' ';
    Grid.Cells[1,J] := S;
  end
  else if Section in [3,4] then //Pipes or Tanks sections
  begin
    Grid.Cells[0,J] := Tokens[0];
    if N > 1 then Grid.Cells[1,J] := Tokens[1];
    S := '';
    for I := 2 to N-1 do S := S + Tokens[I] + ' ';
    Grid.Cells[2,J] := S;
  end
  else for I := 0 to N-1 do Grid.Cells[I,J] := Tokens[I];
  if Length(Comment) > 0 then Grid.Cells[Grid.ColCount-1,J] := Comment;
end;

procedure ReadMsxFile(MsxEditorForm: TMsxEditorForm; Filename: string);
var
  Tokens: TStringList;
  F: TextFile;
  S: string;
  Section: Integer;
  I: Integer;
  Grid: TStringGrid;
begin
  EditorForm := MsxEditorForm;
  Section := 0;
  Comment := '';
  PrevPatnID := '';
  PatnStr := '';
  Tokens := TStringList.Create;
  Patterns := TStringList.Create;
  AssignFile(F, Filename);
  try
    // Define properties used to tokenize each line of file
    Tokens.Delimiter := #9;
    Tokens.QuoteChar := '"';
    Tokens.StrictDelimiter:= false;

    Reset(F);
    while not eof(F) do
    begin

      // Read a line from the file into S
      Readln(F, S);
      S := TrimLeft(S);
      if Length(S) = 0 then continue;

      // Extract comment if line begins with semicolon
      if AnsiStartsText(';', S) then
      begin
        Comment := Copy(S, 2, Length(S));
        continue;
      end;

      // Check if line begins a new data section
      if AnsiStartsText('[', S) then
      begin
        Section := FindSection(S);
        continue;
      end;

      // [TITLE] section
      if Section = 0 then
      begin
        EditorForm.TitleEdit.Text := S;
        continue;
      end;

      // [REPORT] section is not used
      if Section = 12 then continue;

      // Extract any comment from the end of line S
      I := Pos(';',S);
      if I > 0 then
      begin
       Comment := Copy(S, I+1, Length(S));
       Delete(S, I, Length(S));
      end;

      // Tokenize the remaining portion of S
      Tokens.DelimitedText := S;
      if Tokens.Count = 0 then continue;

      // Assign tokens to MSX Options if in [OPTIONS] section
      if Section = 1 then
        ParseOption(Tokens)

      // Assign tokens to time patterns if in [PATTERNS] section
      else if Section = 10 then
        ParsePattern(Tokens)

      // Assign diffusivity values to species if in [DIFFUSIVITY] section
      else if Section = 11 then
        ParseDiffusivity(Tokens)

      // For all other sections, assign tokens to the cells of the
      // StringGrid in the MSXEditor form used for the section
      else
      begin
        Grid := EditorForm.FindComponent('StringGrid' + IntToStr(Section-1))
          as TStringGrid;
        Grid.RowCount := Grid.RowCount + 1;
        ParseLine(Section, Grid, Tokens);
      end;
      Comment := '';
    end;

    // Add time pattern data to current EPANET project
    AddPatternsToProject;

  finally
    CloseFile(F);
    Tokens.Free;
    Patterns.Free;
  end;
end;

procedure WriteOptions(Slist: TStringList);
var
  Tstep: Double;
begin
  Slist.Add('[OPTIONS]');
  Slist.Add('AREA_UNITS  ' + EditorForm.ComboBox1.Text);
  Slist.Add('RATE_UNITS  ' + EditorForm.ComboBox2.Text);
  Slist.Add('SOLVER      ' + EditorForm.ComboBox3.Text);
  Slist.Add('COUPLING    ' + EditorForm.ComboBox4.Text);
  Tstep := EditorForm.FloatSpinEditEx1.Value;
  if Frac(Tstep) = 0 then
    Slist.Add('TIMESTEP    ' + Format('%0.0f',[Tstep]))
  else
    Slist.Add('TIMESTEP    ' + Format('%0.3f',[Tstep]));
  Slist.Add('ATOL        ' + Format('%0.5f',[EditorForm.FloatSpinEditEx2.Value]));
  Slist.Add('RTOL        ' + Format('%0.5f',[EditorForm.FloatSpinEditEx3.Value]));
  Slist.Add('COMPILER    ' + EditorForm.ComboBox5.Text);
  Slist.Add('SEGMENTS    ' + Format('%0.0f',[EditorForm.FloatSpinEditEx4.Value]));
  Slist.Add('PECLET      ' + Format('%0.0f',[EditorForm.FloatSpinEditEx5.Value]));
  Slist.Add('');
end;

procedure WriteSection(I: Integer; Slist: TStringList);
var
  R: Integer;
  N: Integer;
  S: string;
begin
  Slist.Add(WriteSections[I]);
  with EditorForm.FindComponent('StringGrid' + IntToStr(I-1)) as TStringGrid do
  begin
    for R := 1 to RowCount-1 do
    begin
      if Length(Trim(Cells[1,R])) = 0 then continue;
      S := '';
      case I of
        2:
          S := Format('%-11s %-14s %-7s %-13s %-13s',
                 [Cells[0,R], Cells[1,R], Cells[2,R], Cells[3,R], Cells[4,R]]);
        3,
        4:
          S := Format('%-11s %-14s %-35s', [Cells[0,R], Cells[1,R], Cells[2,R]]);
        5:
          S := Format('%-11s %-35s', [Cells[0,R], Cells[1,R]]);
        6:
          S := Format('%-11s %-14s %-14s', [Cells[0,R], Cells[1,R], Cells[2,R]]);
        7,
        8:
          S := Format('%-11s %-14s %-14s %-14s',
                 [Cells[0,R], Cells[1,R], Cells[2,R], Cells[3,R]]);
        9:
          S := Format('%-11s %-14s %-14s %-14s %-14s',
                [Cells[0,R], Cells[1,R], Cells[2,R], Cells[3,R], Cells[4,R]]);
      end;          
      N := ColCount-1;
      if Length(Trim(Cells[N,R])) <> 0 then S := S + '  ;' + Cells[N,R];
      Slist.Add(S);
    end;
  end;
  Slist.Add('');
end;

procedure WritePattern(Slist: TStringList; Pattern: string);
var
  I: Integer;
  M: Integer;
  PatternIndex: Integer;
  PatternLength: Integer;
  PatternValue: Single;
  PatternComment: string;
  Line: string;
begin
  // Check that pattern exists
  PatternIndex := project.GetItemIndex(ctPatterns, Pattern);
  if PatternIndex < 1 then exit;

  // Add any comment to Slist
  PatternComment := project.GetComment(ctPatterns, PatternIndex);
  if Length(PatternComment) > 0 then Slist.Add(';' + PatternComment);

  // Get pattern length (i.e., number of multipliers)
  ENgetpatternlen(PatternIndex, PatternLength);

  // Begin a new line of text containing up to 6 multipliers
  M := 0;
  Line := '';

  // Add each multiplier to current line
  for I := 1 to PatternLength do
  begin
    ENgetpatternvalue(PatternIndex, I, PatternValue);
    Line := Line + Format('  %12.4f', [PatternValue]);
    Inc(M);

    // Limit of 6 multipliers per Line has been reached
    if M mod 6 = 0 then
    begin
      // Add Line to Slist prepended by pattern name
      Slist.Add(Format('%-14s ', [Pattern]) + Line);

      // Begin a new Line
      Line := '';
      M := 0;
    end;
  end;

  // Add Line with remaining multipliers to Slist
  if M > 0 then Slist.Add(Format('%-16s', [Pattern]) + Line);
end;


procedure WritePatterns(Slist: TStringList);
var
  R: Integer;
  Pattern: string;
  Grid: TStringGrid;
  Patterns: TStringList;
begin
  Slist.Add('[PATTERNS]');
  Grid := EditorForm.StringGrid8;
  Patterns := TStringList.Create;
  try
    for R := 1 to Grid.RowCount - 1 do
    begin
      Pattern := Grid.Cells[4, R];
      if Length(Pattern) > 0 then
      begin
        if Patterns.IndexOf(Pattern) >= 0 then continue;
        Patterns.Add(Pattern);
        WritePattern(Slist, Pattern);
      end;
    end;
  finally
    Patterns.Free;
  end;
  Slist.Add('');
end;

procedure WriteDiffusivity(Slist: TStringList);
var
  R: Integer;
  S: string;
begin
  Slist.Add('[DIFFUSIVITY]');
  with EditorForm.StringGrid1 do
  begin
    for R := 1 to RowCount-1 do
    begin
      if Length(Trim(Cells[1, R])) = 0 then continue;
      if Length(Trim(Cells[5, R])) = 0 then continue;
      S := Format('%-14s %-14s',[Cells[1, R],Cells[5, R]]);
      Slist.Add(S);
    end;
  end;
end;

procedure WriteMsxFile(MsxEditorForm: TMsxEditorForm; Filename: string);
var
  Slist: TStringList;
  S: string;
  I: Integer;
begin
  EditorForm := MsxEditorForm;
  Slist := TStringList.Create;
  try
    Slist.Add('[TITLE]');
    S := EditorForm.TitleEdit.Text;
    if Length(S) > 0 then Slist.Add(S);
    Slist.Add('');
    WriteOptions(Slist);
    for I := 2 to 9 do WriteSection(I, Slist);
    WritePatterns(Slist);
    WriteDiffusivity(Slist);
    Slist.SaveToFile(Filename);
  finally
    Slist.Free;
  end;
end;

end.

