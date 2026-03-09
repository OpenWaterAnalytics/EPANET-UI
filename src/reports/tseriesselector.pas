{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       tseriesselector
 Description:  A frame used to select network objects and parameters
               to display in a time series report.
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit tseriesselector;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, Buttons, ExtCtrls, Dialogs,
  timeseriesrpt;

type

  { TTseriesSelectorFrame }

  TTseriesSelectorFrame = class(TFrame)
    Notebook1:        TNotebook;
    SeriesListPage:   TPage;
    SeriesSelectPage: TPage;
    SeriesListBox:    TListBox;
    ViewBtn:          TButton;
    CancelBtn1:       TButton;
    CancelBtn2:       TButton;
    AcceptBtn:        TButton;
    CloseBtn:         TSpeedButton;
    AddBtn:           TBitBtn;
    EditBtn:          TBitBtn;
    DeleteBtn:        TBitBtn;
    UpBtn:            TBitBtn;
    DnBtn:            TBitBtn;
    TimeOfDayBox:     TCheckBox;
    ObjectTypeCombo:  TComboBox;
    ParamCombo:       TComboBox;
    ObjectNameEdit:   TEdit;
    LegendLabelEdit:  TEdit;
    Label1:           TLabel;
    Label2:           TLabel;
    Label3:           TLabel;
    Label4:           TLabel;
    Label5:           TLabel;
    Label6:           TLabel;
    Label7:           TLabel;
    AxisLeftBtn:      TRadioButton;
    AxisRightBtn:     TRadioButton;
    TopPanel:         TPanel;

    procedure AcceptBtnClick(Sender: TObject);
    procedure AddBtnClick(Sender: TObject);
    procedure CancelBtn1Click(Sender: TObject);
    procedure CancelBtn2Click(Sender: TObject);
    procedure CloseBtnClick(Sender: TObject);
    procedure ObjectNameEditChange(Sender: TObject);
    procedure ObjectTypeComboChange(Sender: TObject);
    procedure DeleteBtnClick(Sender: TObject);
    procedure DnBtnClick(Sender: TObject);
    procedure EditBtnClick(Sender: TObject);
    procedure ParamComboChange(Sender: TObject);
    procedure ViewBtnClick(Sender: TObject);
    procedure UpBtnClick(Sender: TObject);

  private
    SeriesAction:  Integer;
    TimeOfDayPlot: Boolean;
    HasChanged:    Boolean;
    NoDataSeries:  Boolean;

    procedure SetActionButtons;
    procedure InitSeriesSelectPage;
    procedure SetDataSeriesProps(I: Integer);
    function  GetSelectedObjectDataSeries: TDataSeries;
    function  GetDataSeriesProps(I: Integer): Boolean;
    function  GetDataSeriesTitle: string;

  public
    procedure Init(DataSeries: array of TDataSeries; PlotTimeOfDay: Boolean);
    procedure SetSelectedObjectProps;

  end;

implementation

{$R *.lfm}

uses
  main, config, project, mapthemes, utils, reportviewer, sysresults,
  resourcestrings;

const
  Adding = 1;
  Editing = 2;

var
  TempDataSeries: array[0..timeseriesrpt.MaxSeries-1] of TDataSeries;

{ TTseriesSelectorFrame }


procedure TTseriesSelectorFrame.Init(DataSeries: array of TDataSeries;
  PlotTimeOfDay: Boolean);
var
  I: Integer;
begin
  // Clear the SeriesListBox
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  HasChanged := false;
  SeriesListBox.Clear;
  SeriesListBox.ItemIndex := -1;
  NoDataSeries := false;

  // Initialize the components on the SeriesSelectPage
  InitSeriesSelectPage;

  // Make a local copy of the Time Series Report's current data series
  for I := 0 to High(DataSeries) do
    TempDataSeries[I] := DataSeries[I];

  // If report currently has no data series then add one for the
  // project's currently selected object and theme
  if TempDataSeries[0].ObjType < 0 then
  begin
    NoDataSeries := true;
    TempDataSeries[0] := GetSelectedObjectDataSeries;
  end;
  if TempDataSeries[0].ObjType >= 0 then HasChanged := true;

  // Add description of each data series to the SeriesListPage's SeriesListBox
  for I := 0 to High(TempDataSeries) do
  begin
    if TempDataSeries[I].ObjType < 0 then break;
    SeriesListBox.Items.Add(TempDataSeries[I].Title);
  end;
  if SeriesListBox.Count > 0 then SeriesListBox.ItemIndex := 0;

  // Set the status of the SeriesListBox action buttons
  SetActionButtons;

  // Set state of TimeOfDayBox
  TimeOfDayPlot := PlotTimeOfDay;
  TimeOfDayBox.Checked := PlotTimeOfDay;
end;

procedure TTseriesSelectorFrame.InitSeriesSelectPage;
begin
  ObjectTypeCombo.ItemIndex := 0;
  ObjectNameEdit.Text := '';
  LegendLabelEdit.Text := '';
  ObjectTypeComboChange(Self);
  AxisLeftBtn.Checked := true;
end;

procedure TTseriesSelectorFrame.ObjectTypeComboChange(Sender: TObject);
var
  I: Integer;
begin
  ObjectNameEdit.Clear;
  ParamCombo.Clear;
  case ObjectTypeCombo.ItemIndex of
    0:
      begin
        ObjectNameEdit.Enabled := true;
        for I := FirstNodeResultTheme to NodeThemeCount - 1 do
          ParamCombo.Items.Add(mapthemes.NodeThemes[I].Name);
        ParamCombo.ItemIndex := ntPressure - FirstNodeResultTheme;
      end;
    1:
      begin
        ObjectNameEdit.Enabled := true;
        for I := FirstLinkResultTheme to LinkThemeCount - 1 do
          ParamCombo.Items.Add(mapthemes.LinkThemes[I].Name);
        ParamCombo.ItemIndex := ltFlow - FirstLinkResultTheme;
      end;
     2:
       begin
         ObjectNameEdit.Enabled := false;
         for I := 0 to High(SysParams) do
           ParamCombo.Items.Add(SysParams[I]);
         ParamCombo.ItemIndex := 0;
       end;
  end;
  LegendLabelEdit.Text := GetDataSeriesTitle;
end;

procedure TTseriesSelectorFrame.AddBtnClick(Sender: TObject);
begin
  SeriesAction := Adding;
  SetDataSeriesProps(-1);
  Notebook1.PageIndex := 1;
end;

procedure TTseriesSelectorFrame.CancelBtn1Click(Sender: TObject);
begin
  Visible := false;
  if NoDataSeries then
    ReportViewerForm.Close
  else
    ReportViewerForm.Show;
end;

procedure TTseriesSelectorFrame.CancelBtn2Click(Sender: TObject);
begin
  Notebook1.PageIndex := 0;
end;

procedure TTseriesSelectorFrame.CloseBtnClick(Sender: TObject);
begin
  CancelBtn1Click(Sender);
end;

procedure TTseriesSelectorFrame.ObjectNameEditChange(Sender: TObject);
begin
  LegendLabelEdit.Text := GetDataSeriesTitle;
end;

procedure TTseriesSelectorFrame.DeleteBtnClick(Sender: TObject);
var
  I: Integer;
  J: Integer;
begin
  I := SeriesListBox.ItemIndex;
  if I >= 0 then
  begin
    for J := I + 1 to MaxSeries-1 do
      TempDataSeries[J - 1] := TempDataSeries[J];
    TempDataSeries[MaxSeries-1].ObjType:= -1;
    SeriesListBox.DeleteSelected;
  end;
  SetActionButtons;
end;

procedure TTseriesSelectorFrame.DnBtnClick(Sender: TObject);
var
  I: Integer;
  Max: Integer;
  TmpSeries: TDataSeries;
begin
  Max := SeriesListBox.Items.Count;
  if Max > 0 then
  begin
    Dec(Max);
    I := SeriesListBox.ItemIndex;
    if I < Max then
    begin
      SeriesListBox.Items.Exchange(I, I + 1);
      SeriesListBox.Selected[I + 1]:= true;
      TmpSeries := TempDataSeries[I];
      TempDataSeries[I] := TempDataSeries[I + 1];
      TempDataSeries[I + 1] := TmpSeries;
      HasChanged := true;
    end;
  end;
end;

procedure TTseriesSelectorFrame.AcceptBtnClick(Sender: TObject);
begin
  if GetDataSeriesProps(SeriesListBox.ItemIndex) then
  begin
    HasChanged := true;
    Notebook1.PageIndex := 0;
    SetActionButtons;
  end;
end;

procedure TTseriesSelectorFrame.EditBtnClick(Sender: TObject);
begin
  SeriesAction := Editing;
  SetDataSeriesProps(SeriesListBox.ItemIndex);
  Notebook1.PageIndex := 1;
end;

procedure TTseriesSelectorFrame.ParamComboChange(Sender: TObject);
begin
    LegendLabelEdit.Text := GetDataSeriesTitle;
end;

procedure TTseriesSelectorFrame.ViewBtnClick(Sender: TObject);
begin
  Visible := false;
  if TimeOfDayBox.Checked <> TimeOfDayPlot then HasChanged := true;
  with ReportViewerForm.Report as TTimeSeriesFrame do
    SetDataSeries(TempDataSeries, TimeOfDayBox.Checked, HasChanged);
  if ReportViewerForm.WindowState = wsMinimized then
    ReportViewerForm.WindowState := wsNormal;
  ReportViewerForm.Show;
end;

procedure TTseriesSelectorFrame.UpBtnClick(Sender: TObject);
var
  I: Integer;
  TmpSeries: TDataSeries;
begin
  I := SeriesListBox.ItemIndex;
  if I > 0 then
  begin
    SeriesListBox.Items.Exchange(I, I - 1);
    SeriesListBox.Selected[I - 1]:= true;
    TmpSeries := TempDataSeries[I];
    TempDataSeries[I] := TempDataSeries[I - 1];
    TempDataSeries[I - 1] := TmpSeries;
    HasChanged := true;
  end;
end;

function TTseriesSelectorFrame.GetSelectedObjectDataSeries: TDataSeries;
//
// Gets data series properties for the project's currently selected node or link.
//
var
  Index: Integer;
  Param: Integer;
  ObjStr: string;
  ObjName: string;
  ParamStr: string;
begin
  // Default result is an empty data series
  Result.ObjType := -1;
  with MainForm.ProjectFrame do
  begin

    // The project's currently selected object is a node
    if CurrentCategory = ctNodes then
    begin
      Result.ObjType := ctNodes;
      Index := SelectedItem[ctNodes] + 1; //Indexes are 1-based
      Result.ObjIndex := Index;
      Param := mapthemes.NodeTheme;
      if Param < FirstNodeResultTheme then Param := ntPressure;
      Result.ObjParam := Param;
      ParamStr := mapthemes.NodeThemes[Param].Name;
    end

    // The project's currently selected object is a link
    else if CurrentCategory = ctLinks then
    begin
      Result.ObjType := ctLinks;
      Index := SelectedItem[ctLinks] + 1; //Indexes are 1-based
      Result.ObjIndex := Index;
      Param := mapthemes.LinkTheme;
      if Param < FirstLinkResultTheme then Param := ltFlow;
      Result.ObjParam := Param;
      ParamStr := mapthemes.LinkThemes[Param].Name;
    end

    // Currently selected object is neither a node nor a link
    else exit;
  end;

  // Default plot y-axis & legend title
  Result.PlotAxis := 0;
  ObjStr := project.GetItemTypeStr(Result.ObjType, Index - 1);
  ObjName := project.GetID(Result.ObjType, Index);
  Result.ObjID := ObjName;
  Result.Title := ObjStr + ObjName + ' ' + ParamStr;
  Result.Legend := Result.Title;
end;

function TTseriesSelectorFrame.GetDataSeriesProps(I: Integer): Boolean;
//
//  Transfer the entries on the SeriesSelectPage into a Data Series object.
//
var
  aSeries: TDataSeries;
begin
  Result := true;
  with aSeries do
  begin
    ObjParam := ParamCombo.ItemIndex;
    case ObjectTypeCombo.ItemIndex of
    0:  // Node object
      begin
        ObjType := ctNodes;
        ObjParam := mapthemes.FirstNodeResultTheme + ObjParam;
      end;
    1:  // Link object
      begin
        ObjType := ctLinks;
        ObjParam := mapthemes.FirstLinkResultTheme + ObjParam;
      end;
    2:  // System object
      begin
        ObjType := ctSystem;
      end;
    end;

    ObjIndex := 0;
    if (ObjType = ctNodes)
    or (ObjType = ctLinks) then
    begin
      ObjID := ObjectNameEdit.Text;
      ObjIndex := project.GetItemIndex(ObjType, ObjID);
      if ObjIndex = 0 then
      begin
        utils.MsgDlg(rsMissingData, rsNoSuchObject, mtError, [mbOK]);
        Result := false;
        exit;
      end;
    end;
  end;

  aSeries.Title := GetDataSeriesTitle;
  aSeries.Legend := LegendLabelEdit.Text;
  if AxisLeftBtn.Checked then
    aSeries.PlotAxis:= 0
  else
    aSeries.PlotAxis := 1;

  if SeriesAction = Editing then
  begin
    SeriesListBox.Items[I] := aSeries.Title;
    SeriesListBox.ItemIndex := I;
  end
  else
  begin
    SeriesListBox.Items.Add(aSeries.Title);
    SeriesListBox.ItemIndex := SeriesListBox.Count - 1;
    I := SeriesListBox.ItemIndex;
  end;
  TempDataSeries[I] := aSeries;
end;

procedure TTseriesSelectorFrame.SetDataSeriesProps(I: Integer);
var
  ObjType: Integer;
  ObjParam: Integer;
begin
  if I < 0 then
  begin
    ObjectNameEdit.Text := '';
    LegendLabelEdit.Text := '';
    exit;
  end;

  ObjType := TempDataSeries[I].ObjType;
  ObjParam := TempDataSeries[I].ObjParam;
  if ObjType = ctNodes then
    ObjectTypeCombo.ItemIndex := 0
  else if ObjType = ctLinks then
    ObjectTypeCombo.ItemIndex := 1
  else if ObjType = ctSystem then
    ObjectTypeCombo.ItemIndex := 2;
  ObjectTypeComboChange(Self);
  if ObjType = ctNodes then
    ParamCombo.ItemIndex := ObjParam - mapthemes.FirstNodeResultTheme
  else if ObjType = ctLinks then
    ParamCombo.ItemIndex := ObjParam - mapthemes.FirstLinkResultTheme
  else
    ParamCombo.ItemIndex := ObjParam;
  ObjectNameEdit.Text := TempDataSeries[I].ObjID;
  LegendLabelEdit.Text := TempDataSeries[I].Legend;

  if TempDataSeries[I].PlotAxis = 0 then
    AxisLeftBtn.Checked := true
  else
    AxisRightBtn.Checked := true;
end;

procedure TTseriesSelectorFrame.SetSelectedObjectProps;
var
  Index: Integer;
begin
  if Notebook1.PageIndex <> 1 then exit;
  with MainForm.ProjectFrame do
  begin

    if CurrentCategory = ctNodes then
    begin
      Index := SelectedItem[ctNodes] + 1; //Indexes are 1-based
      ObjectNameEdit.Text := project.GetID(ctNodes, Index);
      if ObjectTypeCombo.ItemIndex <> 0 then
      begin
        ObjectTypeCombo.ItemIndex := 0;
        ObjectTypeComboChange(self);
      end;
    end

    else if CurrentCategory = ctLinks then
    begin
      Index := SelectedItem[ctLinks] + 1; //Indexes are 1-based
      ObjectNameEdit.Text := project.GetID(ctLinks, Index);
      if ObjectTypeCombo.ItemIndex <> 1 then
      begin
        ObjectTypeCombo.ItemIndex := 1;
        ObjectTypeComboChange(self);
      end;
    end

    else exit;
  end;
end;

function TTseriesSelectorFrame.GetDataSeriesTitle: string;
var
  ObjType: Integer;
  ObjIndex: Integer;
  ObjStr: string;
begin
  // A system parameter was selected
  Result := '';
  if ObjectTypeCombo.ItemIndex = 2 then
  begin
    Result := rsSystem + ' ' + sysresults.SysParams[ParamCombo.ItemIndex];
    exit;
  end;

  // A node or link parameter was selected
  if Length(Trim(ObjectNameEdit.Text)) = 0 then exit;
  if ObjectTypeCombo.ItemIndex = 0 then
    ObjType := ctNodes
  else
    ObjType := ctLinks;
  ObjIndex := project.GetItemIndex(ObjType, ObjectNameEdit.Text);
  if ObjIndex <= 0 then exit;
  ObjStr := project.GetItemTypeStr(ObjType, ObjIndex-1);
  Result := ObjStr + ObjectNameEdit.Text + ' ' + ParamCombo.Text;
end;

procedure TTseriesSelectorFrame.SetActionButtons;
var
  N: Integer;
begin
  N := SeriesListBox.Count;
  AddBtn.Enabled := N < 6;
  EditBtn.Enabled := N > 0;
  DeleteBtn.Enabled := N > 0;
  UpBtn.Enabled := N > 1;
  DnBtn.Enabled := (N > 1) and (N < 6);
end;

end.

