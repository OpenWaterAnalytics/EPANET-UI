{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       networkrpt
 Description:  A frame that displays a table of computed results
               for all network nodes or links
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit networkrpt;

{  This unit contains a frame that displays simulation results for all
   network nodes or links in a table that can be sorted and filtered.

   A TNotebook has a TablePage to display the results in a TDrawGrid
   and a FilterPage to define filters to limit the results shown in
   the TablePage.
}

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, Grids, ComCtrls, Menus, Types, LCLtype, Clipbrd, Fgl;

type
TFilter = record
  Param:    Integer;
  Relation: Integer;
  Value:    Single;
  ValueStr: string;
  Text:     string;
end;

  TIntegerList = specialize TFPGList<Integer>;  // an integer list

  { TNetworkRptFrame }

  TNetworkRptFrame = class(TFrame)
    Notebook1:         TNotebook;
    TablePage:         TPage;
    FilterPage:        TPage;
    DataGrid:          TDrawGrid;
    Label1:            TLabel;
    Panel1:            TPanel;
    BottomPanel:       TPanel;
    GroupBox1:         TGroupBox;
    ParamCheckGroup:   TCheckGroup;
    ParamComboBox:     TComboBox;
    RelationComboBox:  TComboBox;
    ParamValueEdit:    TEdit;
    FiltersListBox:    TListBox;
    FiltersAcceptBtn:  TButton;
    FiltersAddBtn:     TButton;
    FiltersCancelBtn:  TButton;
    FiltersDeleteBtn:  TButton;
    PopupMenu1:        TPopupMenu;
    MenuSave:          TMenuItem;
    MnuFilters:        TMenuItem;
    MenuCopy:          TMenuItem;
    ExportToClipboard: TMenuItem;
    ExportToFile:      TMenuItem;

    procedure DataGridClick(Sender: TObject);
    procedure DataGridDrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DataGridHeaderClick(Sender: TObject; IsColumn: Boolean;
      Index: Integer);
    procedure DataGridPrepareCanvas(sender: TObject; aCol, aRow: Integer;
      aState: TGridDrawState);
    procedure FiltersAcceptBtnClick(Sender: TObject);
    procedure FiltersAddBtnClick(Sender: TObject);
    procedure FiltersCancelBtnClick(Sender: TObject);
    procedure FiltersDeleteBtnClick(Sender: TObject);
    procedure FiltersListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure MenuCopyClick(Sender: TObject);
    procedure MenuSaveClick(Sender: TObject);
    procedure MnuFiltersClick(Sender: TObject);

  private
    procedure SetupTable;
    function  GetTableCellValue(C: LongInt; R: LongInt): string;
    function  GetParamIndex(ColIndex: Integer): Integer;
    function  SetFilter(I: Integer; X: Single; S: string): string;
    function  Filtered(Index: Integer): Boolean;
    function  FilterCompare(Index, Param: Integer; CompValue: Single;
              CompStr: string): Integer;
    procedure GetDataGridContents(Slist: TStringList);

  public
    procedure InitReport(aReportType: Integer);
    procedure CloseReport;
    procedure ClearReport;
    procedure RefreshReport;
    procedure ShowPopupMenu;
    procedure RefreshGrid;

  end;

implementation

{$R *.lfm}

uses
  project, main, mapthemes, results, config, utils, reportviewer,
  epanet2, resourcestrings;

const
  rtBelow = 0;
  rtEqual = 1;
  rtAbove = 2;

var
  TimePeriod:    Integer;       // Time period being viewed
  TableType:     Integer;       // Either Nodes or Links
  IndexList:     TIntegerList;  // List of table indices for nodes/links
  SortIndex:     Integer;       // Index of parameter being sorted
  SortOrder:     TSortOrder;    // Either ascending or descending
  NumFilters:    Integer;       // Number of table filter conditions
  NumTmpFilters: Integer;       // Number of temporary filter conditions
  Filters:       array[0..4] of TFilter; // Table filter conditions
  TmpFilters:    array[0..4] of TFilter; // Temporary filter conditions

function GetObjectType(Index: Integer): string;
//
//  Return the type of object at grid row Index as a string
//
var
  I: Integer = 0;
  E: Integer = 0;
begin
  Result := '';
  if TableType = ctNodes then
    // Convert object index (1-based) to item (0-based)
    Result := Trim(project.GetItemTypeStr(TableType, Index-1))
  else
  begin
    E := epanet2.ENgetlinktype(Index, I);
    if E > 0 then exit;
    if I <= EN_PIPE then
      Result := rsPipe
    else if I = EN_PUMP then
      Result := rsPump
    else
      // I is in the range EN_PRV to EN_PCV
      Result := project.ValveTypeStr[I-EN_PRV];
  end;
end;

function CompareFloat(X1, X2: Single): Integer;
begin
  if X1 < X2 then Result := -1
  else if Abs(X1 - X2) < 0.001 then Result := 0
  else Result := 1;
end;

function Compare(const Index1: LongInt; const Index2: LongInt): LongInt;
//
// Compare function used when grid is being sorted
//
var
  X1: Single;
  X2: Single;
  S1: string;
  S2: string;
begin
  Result := 0;

  // Sorting object type
  if SortIndex = 0 then
  begin
    S1 := GetObjectType(Index1);
    S2 := GetObjectType(Index2);
    Result := CompareStr(S1, S2);
  end

  // Sorting links
  else if TableType = ctLinks then
  begin
    // Get parameter values for the two objects being compared
    X1 := MapThemes.GetLinkValue(Index1, SortIndex, TimePeriod);
    X2 := MapThemes.GetLinkValue(Index2, SortIndex, TimePeriod);

    // Do string comparison for link status
    if SortIndex = ltStatus then
    begin
      S1 := mapthemes.GetStatusStr(Round(X1));
      S2 := mapthemes.GetStatusStr(Round(X2));
      Result := CompareStr(S1, S2);
    end
    else
      Result := CompareFloat(X1, X2);
  end

  // Sorting nodes
  else if TableType = ctNodes then
  begin
    X1 := mapthemes.GetNodeValue(Index1, SortIndex, TimePeriod);
    X2 := mapthemes.GetNodeValue(Index2, SortIndex, TimePeriod);
    Result := CompareFloat(X1, X2);
  end;
  if SortOrder = soDescending then Result := -Result;
end;

procedure TNetworkRptFrame.InitReport(aReportType: Integer);
begin
//  DataGrid.AlternateColor := config.AlternateColor;
//  DataGrid.FixedColor := $00F2E4D7;
  TableType := ctNodes;
  if aReportType = ctLinks then TableType := ctLinks;
  TimePeriod := mapthemes.TimePeriod;
  Notebook1.PageIndex := 0;
  IndexList := TIntegerList.Create;
  ClearReport;
  SetupTable;
end;

procedure TNetworkRptFrame.CloseReport;
begin
  ClearReport;
  IndexList.Free;
end;

procedure TNetworkRptFrame.ClearReport;
begin
  DataGrid.Clear;
  ParamCheckGroup.Items.Clear;
  ParamComboBox.Items.Clear;
  FiltersListBox.Items.Clear;
  IndexList.Clear;
  SortIndex := -1;
  NumFilters := 0;
end;

procedure TNetworkRptFrame.RefreshReport;
var
  S: string;
begin
  // Add a header row to the grid
  DataGrid.RowCount := 1;
  DataGrid.RowHeights[0] := 2 * DataGrid.DefaultRowHeight -
    (DataGrid.DefaultRowHeight div 2);

  // Set the time period to display
  TimePeriod := mapthemes.TimePeriod;

  // Set caption of report's top panel
  if TableType = ctNodes then
    S := rsNodeResults
  else
    S := rsLinkResults;
  if results.Nperiods > 1 then
    S := S + Format(rsAtTimePeriod, [results.GetTimeStr(TimePeriod)]);
  ReportViewerForm.TopPanel.Caption := S;

  // Display network results at specified time period
  RefreshGrid;
end;

procedure TNetworkRptFrame.RefreshGrid;
var
  I: Integer;
  S: string;
begin
  // Set visibility of grid columns
  DataGrid.FixedColor:= config.ThemeColor;
  FilterPage.Color:= config.ThemeColor;
  for I := 0 to DataGrid.Columns.Count - 1 do
    DataGrid.Columns[I].Visible := ParamCheckGroup.Checked[I];

  // Add filtered results to the grid
  IndexList.Clear;
  DataGrid.BeginUpdate;
  for I := 1 to project.GetItemCount(TableType) do
  begin
    if (NumFilters = 0) or Filtered(I) then IndexList.Add(I);
  end;
  DataGrid.RowCount := IndexList.Count + 1;

  // Sort the grid if called for
  if (SortIndex >= 0) then IndexList.Sort(@Compare);
  DataGrid.EndUpdate(true);

  // Display number of table entries
  if NumFilters = 0 then
    S := ' ' + rsUnfiltered + ' '
  else
    S := ' ' + rsFiltered + ' ';
  BottomPanel.Caption := S + IntToStr(DataGrid.RowCount - 1) + ' ' + rsItems;
end;

procedure TNetworkRptFrame.SetupTable;
var
  I:          Integer;
  ThemeCount: Integer;
  ParamName:  string = '';
  ParamStr:   string = '';
begin
  // Add a column for object type
  DataGrid.Columns.Clear;
  DataGrid.Columns.Add;
  DataGrid.Columns[0].Title.Caption := rsType;
  ParamComboBox.Items.Add(rsType);
  ParamCheckGroup.Items.Add(rsType);

  // Add a column for each theme viewable on the network map
  if TableType = ctNodes then
    ThemeCount := NodeThemeCount - 1
  else
    // Include link Status & Setting which are not map viewable
    ThemeCount := LinkThemeCount + 2 - 1;
  for I := 1 to ThemeCount do DataGrid.Columns.Add;

  // Assign header names to each of the  columns
  for I := 1 to ThemeCount do
  begin
    if TableType = ctNodes then
    begin
      ParamName := mapthemes.NodeThemes[I].Name;
      ParamStr := ParamName + LineEnding + mapthemes.GetThemeUnits(ctNodes, I)
    end
    else if TableType = ctLinks then
    begin
      // For map viewable themes
      if I <= ThemeCount - 2 then
      begin
        ParamName := mapthemes.LinkThemes[I].Name;
        ParamStr := ParamName + LineEnding + mapthemes.GetThemeUnits(ctLinks, I);
      end

      // For link Status & Setting
      else if I < ThemeCount then
      begin
        ParamName := rsStatus;
        ParamStr := ParamName;
      end
      else
      begin
        ParamName := rsSetting;
        ParamStr := ParamName;
      end;
    end;
    ParamComboBox.Items.Add(ParamName);
    ParamCheckGroup.Items.Add(ParamName);
    DataGrid.Columns[I].Title.Caption := ParamStr;
  end;
  ParamComboBox.ItemIndex := 0;

  // Select which parameters (i.e., columns) to display initially
  for I := 0 to ThemeCount do
  begin
    ParamCheckGroup.Checked[I] := true;
    if (TableType = ctNodes)
    and (I in [ntElevation, ntBaseDemand, ntEmittance, ntLeakage]) then
    begin
      ParamCheckGroup.Checked[I] := false
    end
    else if (TableType = ctLinks)
    and (I in [ltDiameter, ltLength, ltRoughness]) then
    begin
      ParamCheckGroup.Checked[I] := false;
    end;
  end;
end;

procedure TNetworkRptFrame.DataGridPrepareCanvas(sender: TObject; aCol,
  aRow: Integer; aState: TGridDrawState);
var
  MyTextStyle: TTextStyle;
begin
  MyTextStyle := DataGrid.Canvas.TextStyle;
  if aRow = 0 then
  begin
    MyTextStyle.SingleLine := false;
    if aCol > 0 then
      MyTextStyle.Alignment := taCenter;
    DataGrid.Canvas.TextStyle := MyTextStyle;
  end
  else if aCol > 0 then
  begin
    MyTextStyle.Alignment := taCenter;
    DataGrid.Canvas.TextStyle := MyTextStyle;
  end;
end;

procedure TNetworkRptFrame.FiltersAcceptBtnClick(Sender: TObject);
//
// Transfer the filters defined on the FilterPage to the actual filters
// used to display results on the TablePage.
//
var
  I: Integer;
begin
  NumFilters := NumTmpFilters;
  for I := 0 to NumFilters - 1 do
    Filters[I] := TmpFilters[I];
  NoteBook1.PageIndex := 0;
  RefreshGrid;
  DataGrid.SetFocus;
end;

procedure TNetworkRptFrame.FiltersAddBtnClick(Sender: TObject);
//
// Add the filter entered into the FilterPage's controls to the list
// of filters.
//
var
  Filter:    string;
  ParamStr:  string;
  S:         string = '';
  X:         Single = 0;
begin
  S := Trim(ParamValueEdit.Text);
  ParamStr := ParamComboBox.Text;
  if (not SameText(ParamStr, 'Type')) and
     (not SameText(ParamStr, 'Status')) then
  begin
    if not utils.Str2Float(S, X) then
    begin
      Utils.MsgDlg(rsInvalidData, ParamValueEdit.Text + rsInvalidNumber,
        mtError, [mbOk]);
      exit;
    end;
  end;
  Filter := SetFilter(NumTmpFilters, X, S);
  FiltersListBox.Items.Add(Filter);
  FiltersListBox.ItemIndex := FiltersListBox.Count - 1;
  FiltersAddBtn.Enabled := FiltersListBox.Count < Length(Filters);
  FiltersDeleteBtn.Enabled := true;
  Inc(NumTmpFilters);
  ParamComboBox.SetFocus;
end;

procedure TNetworkRptFrame.FiltersCancelBtnClick(Sender: TObject);
begin
  Notebook1.PageIndex := 0;
end;

procedure TNetworkRptFrame.FiltersDeleteBtnClick(Sender: TObject);
var
  I: Integer;
  J: Integer;
begin
  I := FiltersListBox.ItemIndex;
  if I < NumTmpFilters - 1 then
  begin
    for J := I to NumTmpFilters - 2 do
      TmpFilters[J] := TmpFilters[J+1];
  end;
  FiltersListBox.Items.Delete(I);
  Dec(NumTmpFilters);
  if I > 0 then Dec(I);
  if FiltersListBox.Count = 0 then
    FiltersDeleteBtn.Enabled := false
  else
    FiltersListBox.ItemIndex := I;
end;

procedure TNetworkRptFrame.FiltersListBoxSelectionChange(Sender: TObject;
  User: boolean);
var
  I: Integer;
begin
  I := FiltersListBox.ItemIndex;
  ParamComboBox.ItemIndex := TmpFilters[I].Param ;
  RelationComboBox.ItemIndex := TmpFilters[I].Relation;
  ParamValueEdit.Text := TmpFilters[I].ValueStr;
end;

procedure TNetworkRptFrame.ShowPopupMenu;
var
  P : TPoint;
begin
  P := Self.ClientToScreen(Point(0, 0));
  PopupMenu1.PopUp(P.x,P.y);
end;

procedure TNetworkRptFrame.MenuCopyClick(Sender: TObject);
//
//  Copy contents of DataGrid to the Clipboard.
//
var
  Slist: TStringList;
begin
  Slist := TStringList.Create;
  try
    GetDataGridContents(Slist);
    Clipboard.AsText := Slist.Text;
  finally
    Slist.Free;
  end;
end;

procedure TNetworkRptFrame.MenuSaveClick(Sender: TObject);
//
//  Save contents of DataGrid to a file.
//
var
  Slist: TStringList;
begin
  with MainForm.SaveDialog1 do
  begin
    FileName := '*.txt';
    Filter := rsTextFile;
    DefaultExt := '*.txt';
    if Execute then
    begin
      Slist := TStringList.Create;
      try
        GetDataGridContents(Slist);
        Slist.SaveToFile(FileName);
      finally
        Slist.Free;
      end;
    end;
  end;
end;

procedure TNetworkRptFrame.MnuFiltersClick(Sender: TObject);
//
//  Switch to the FilterPage of Notebook1.
//
var
  I: Integer;
  EnableBtns: Boolean = false;
begin
  FiltersListBox.Clear;
  for I := 0 to High(TmpFilters) do
  begin
    TmpFilters[I].Param := -1;
    TmpFilters[I].Text := '';
  end;
  for I := 0 to NumFilters - 1 do
  begin
    FiltersListBox.Items.Add(Filters[I].Text);
    TmpFilters[I] := Filters[I];
  end;
  NumTmpFilters := NumFilters;

  if NumFilters > 0 then
  begin
    FiltersListBox.ItemIndex := 0;
    EnableBtns := true;
  end;
  FiltersDeleteBtn.Enabled := EnableBtns;
  if NumFilters > 0 then
     FiltersListBoxSelectionChange(Sender, false)
  else
  begin
    ParamComboBox.ItemIndex := 0;
    RelationComboBox.ItemIndex := 0;
    ParamValueEdit.Text := '';
  end;
  Notebook1.PageIndex := 1;
  ParamCheckGroup.SetFocus;
end;

function TNetworkRptFrame.GetParamIndex(ColIndex: Integer): Integer;
//
//  Find the index of the parameter displayed in the DataGrid's
//  ColIndex column.
//
var
  S: string;
begin
  Result := ColIndex - 1;
  if TableType = ctLinks then
  begin
    S := self.DataGrid.Columns[ColIndex-1].Title.Caption;
    if SameText(S, rsStatus) then
      Result := ltStatus
    else if SameText(S, rsSetting) then
      Result := ltSetting;
  end;
end;

procedure TNetworkRptFrame.DataGridHeaderClick(Sender: TObject;
  IsColumn: Boolean; Index: Integer);
begin
  if IsColumn then
  begin
    SortIndex := GetParamIndex(Index);
    SortOrder := DataGrid.SortOrder;
    RefreshGrid;
  end;
end;

procedure TNetworkRptFrame.DataGridDrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  S: string;
  H: Integer;
  N: Integer;
begin
  S := GetTableCellValue(aCol, aRow);
  with Sender as TDrawGrid do
  begin
    if aRow = 0 then
      N := 2
    else
      N := 1;
    H := (aRect.Height - N * Canvas.TextHeight(S)) div 2;
    Canvas.TextRect(aRect, aRect.Left+2, aRect.Top + H, S);
  end;
end;

procedure TNetworkRptFrame.DataGridClick(Sender: TObject);
//
//  Make the object selected in the DataGrid also selected on the network
//  map and in the ProjectFrame's Property Editor.
//
var
  ItemIndex: Integer;
begin
  with DataGrid do
  begin
    if Row > 0 then
    begin
      ItemIndex := project.GetItemIndex(TableType, GetTableCellValue(0, Row));
      MainForm.ProjectFrame.SelectItem(TableType, ItemIndex - 1);
    end;
  end;
end;


function TNetworkRptFrame.GetTableCellValue(C: LongInt; R: LongInt): string;
var
  X: Single;
  S: string;
  Index: Integer = 0;
  Param: Integer = 0;
begin
  // Find the index of the node/link displayed in DataGrid's row R
  Result := '';
  if R >= 1 then Index := IndexList[R-1];

  // Column is 0 -- return either column header or object's ID
  if C = 0 then
  begin
    if R = 0 then
    begin
      if TableType = ctNodes then
         Result := LineEnding + rsNode
      else
        Result := LineEnding + rsLink;
    end
    else
      Result := project.GetID(TableType, Index);
    exit;
  end;

  // For non-header rows
  if R > 0 then
  begin
    // Get header text for Column object associated with grid column C
    X := MISSING;
    S := DataGrid.Columns[C-1].Title.Caption;

    // Column displays object type
    if SameText(S, rsType) then
    begin
      Result := GetObjectType(Index);
      exit;
    end;

    // Column displays a node/link parameter
    Param := GetParamIndex(C);
    if TableType = ctNodes then
      X := mapthemes.GetNodeValue(Index, Param, TimePeriod)
    else
      X := mapthemes.GetLinkValue(Index, Param, TimePeriod);

    // Convert retrieved numerical value to a string
    if X = MISSING then
      Result := rsNA + '  '
    else if (TableType = ctLinks) and (Param = ltStatus) then
      Result := mapthemes.GetStatusStr(Round(X))
    else
      Result := FloatToStrF(X, ffFixed, 7, config.DecimalPlaces) + '  ';
  end;
end;

function TNetworkRptFrame.SetFilter(I: Integer; X: Single; S: string): string;
//
// Transfer the entries in the FilterPage's editing controls to
// a string representation of a filter.
//
begin
  Result := ParamComboBox.Text + ' '  + RelationComboBox.Text + ' ' +
            ParamValueEdit.Text;

  // Convert from combobox item index to grid column index
  TmpFilters[I].Param := ParamComboBox.ItemIndex + 1;

  TmpFilters[I].Relation := RelationComboBox.ItemIndex;
  TmpFilters[I].Value := X;
  TmpFilters[I].ValueStr := S;
  TmpFilters[I].Text := Result;
end;

function TNetworkRptFrame.Filtered(Index: Integer): Boolean;
//
// Determine if the result for a given node or link meets the
// filtering crieria or not.
//
var
  I:        Integer;
  ObjIndex: Integer;
  Param:    Integer;
  Comp:     Integer;
begin
  Result := false;
  ObjIndex := project.GetResultIndex(TableType, Index);
  if ObjIndex = 0 then exit;

  for I := 0 to NumFilters - 1 do
  begin
    Param := GetParamIndex(Filters[I].Param);
    Comp := FilterCompare(ObjIndex, Param, Filters[I].Value, Filters[I].ValueStr);
    case Filters[I].Relation of
      rtBelow:
        if Comp >= 0 then exit;
      rtEqual:
        if Comp <> 0 then exit;
      rtAbove:
        if Comp <= 0 then exit;
    end;
  end;
  Result := true;
end;

function TNetworkRptFrame.FilterCompare(Index, Param: Integer; CompValue: Single;
  CompStr: string): Integer;
//
//  Comparison function (returning -1, 0, or +1) for a node/link with index
//  Index and parameter Param appearing in a table filter.
//
var
  X: Single;
  ObjType: string;
begin
  // Parameter is node/link type
  Result := 0;
  if Param = 0 then
  begin
    ObjType := GetObjectType(Index);
    Result := CompareText(ObjType, CompStr)
  end

  // For Links table
  else if TableType = ctLinks then
  begin
    // Get parameter value
    X := mapthemes.GetLinkValue(Index, Param, TimePeriod);
    // Use abs value for flow
    if Param = ltFlow then X := abs(X);
    // Do string comparison for link status
    if Param = ltStatus then
      Result := CompareText(mapthemes.GetStatusStr(Round(X)), CompStr)
    // Otherwise do numerical comparison
    else
      Result := CompareFloat(X, CompValue);
  end

  // For Node table, all parameters are numerical
  else if TableType = ctNodes then
  begin
    X := mapthemes.GetNodeValue(Index, Param, TimePeriod);
    Result := CompareFloat(X, CompValue);
  end;
end;

procedure TNetworkRptFrame.GetDataGridContents(Slist: TStringList);
var
  I: Integer;
  R: Integer;
  S: string;
  ColName: string;
begin
  with DataGrid do
  begin
    // Add title lines to the Slist
    S := project.GetTitle(0);
    Slist.Add(S);
    if TableType = ctNodes then
      S := rsNodesReport
    else
      S := rsLinksReport;
    S := S + Format(rsAtTimePeriod, [Results.GetTimeStr(TimePeriod)]);
    Slist.Add(S);
    Slist.Add('');

    // Add first line of each visible column
    S := '                    ';
    for I := 0 to Columns.Count - 1 do
    begin
      if not Columns[I].Visible then continue;
      if TableType = ctNodes then
        ColName := mapthemes.NodeThemes[I+1].Name
      else
        ColName := mapthemes.LinkThemes[I+1].Name;
      S := S + #9 + Format('%20s', [ColName]);
    end;
    Slist.Add(S);

    // Add second line of each visible column
    S := Format('%-20s', [GetTableCellValue(0, 0)]);
    for I := 0 to Columns.Count - 1 do
    begin
      if not Columns[I].Visible then continue;
      S := S + #9 + Format('%20s', [mapthemes.GetThemeUnits(TableType, I+1)]);
    end;
    Slist.Add(S);

    // Add contents of each row
    for R := 1 to RowCount - 1 do
    begin
      S := Format('%-22s', [GetTableCellValue(0, R)]);
      for I := 1 to Columns.Count-1 do
      begin
        if not Columns[I].Visible then continue;
        S := S + #9 + Format('%20s', [GetTableCellValue(I+1, R)]);
      end;
      Slist.Add(S);
    end;
  end;
end;

end.

