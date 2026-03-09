{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       dxfimporter
 Description:  a wizard dialog form used to import network data
               from a DXF file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit dxfimporter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, SpinEx, FileCtrl, CheckLst, EditBtn;

type

  { TDxfImporterForm }

  TDxfImporterForm = class(TForm)
    BackBtn:            TButton;
    CancelBtn:          TButton;
    NextBtn:            TButton;
    ImportBtn:          TButton;
    LayersCheckListBox: TCheckListBox;
    AddToProjectCB:     TCheckBox;
    ComputeLengthsCB:   TCheckBox;
    Image1:             TImage;
    Label1:             TLabel;
    Label3:             TLabel;
    Label4:             TLabel;
    Label5:             TLabel;
    Label7:             TLabel;
    Label14:            TLabel;
    Label17:            TLabel;
    Label19:            TLabel;
    IntroLabel:         TLabel;
    DxfFileEdit:        TEdit;
    DxfFileBtn:         TBitBtn;
    Notebook1:          TNotebook;
    Page1:              TPage;
    Page2:              TPage;
    Page3:              TPage;
    Page4:              TPage;
    PaintBox1:          TPaintBox;
    BtnPanel:           TPanel;
    Panel2:             TPanel;
    Panel3:             TPanel;
    Shape10:            TShape;
    Shape11:            TShape;
    Shape12:            TShape;
    Shape13:            TShape;
    Shape7:             TShape;
    Shape8:             TShape;
    Shape9:             TShape;
    SnapTolEdit:        TFloatSpinEditEx;
    UnitsCombo:         TComboBox;

    procedure BackBtnClick(Sender: TObject);
    procedure CancelBtnClick(Sender: TObject);
    procedure DxfFileBtnClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure LayersCheckListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure ImportBtnClick(Sender: TObject);
    procedure NextBtnClick(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
  private
    DxfFileName: string;      // Name of DXF file
    Layers:      TStringList; // List of link drawing layers
    HasChanged:  Boolean;     // true if new data loaded
    Bitmap:      TBitMap;     // Bitmap used to preview network

    procedure SetButtonStates;
    function  LoadLayers(Fname: string): Boolean;
    procedure GetSelectedLayers;
  public
  end;

var
  DxfImporterForm: TDxfImporterForm;

implementation

{$R *.lfm}

uses
  main, config, utils, project, dxfviewer, dxfloader, resourcestrings;

const
  IntroTxt:        string = rsDxfIntro;
  SelectLayersTxt: string = rsSelectLayers;

{ TDxfImporterForm }


procedure TDxfImporterForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  IntroLabel.Caption := IntroTxt;
  BackBtn.Visible := false;
  ImportBtn.Left := NextBtn.Left;
  ImportBtn.Visible := false;
  UnitsCombo.ItemIndex := 0;
  Bitmap := TBitmap.Create;
  Bitmap.PixelFormat := pf24Bit;
  Notebook1.PageIndex := 0;
  Layers := TStringList.Create;
end;

procedure TDxfImporterForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  Bitmap.Free;
  Layers.Free;
end;

procedure TDxfImporterForm.ImportBtnClick(Sender: TObject);
var
  DxfOptions: dxfloader.TDxfOptions;
begin
  if not AddToProjectCB.Checked then
  begin
    MainForm.FileNew(false);
  end;
  with DxfOptions do
  begin
    ComputeLengths := ComputeLengthsCB.Checked;
    SnapTol := SnapTolEdit.Value;
    CoordUnits := UnitsCombo.ItemIndex;
  end;
  dxfloader.LoadDxfFile(DxfFileName, Layers, DxfOptions);
  Hide;
  ModalResult := mrOK;
end;

procedure TDxfImporterForm.BackBtnClick(Sender: TObject);
begin
  with Notebook1 do
  begin
    if PageIndex > 1 then PageIndex := PageIndex - 1;
  end;
  SetButtonStates;
end;

procedure TDxfImporterForm.NextBtnClick(Sender: TObject);
begin
  if Notebook1.PageIndex = 0 then
    Notebook1.PageIndex := 1
  else if Notebook1.PageIndex = 1 then
  begin
    GetSelectedLayers;
    if Layers.Count = 0 then
      utils.MsgDlg(rsMissingData, SelectLayersTxt, mtWarning, [mbOk], self)
    else
      Notebook1.PageIndex := Notebook1.PageIndex + 1;
  end
  else with Notebook1 do
  begin
    if PageIndex < 4 then PageIndex := PageIndex + 1;
  end;
  SetButtonStates;
end;

procedure TDxfImporterForm.CancelBtnClick(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TDxfImporterForm.DxfFileBtnClick(Sender: TObject);
var
  Fname: string = '';
begin
  with MainForm.OpenDialog1 do
  begin
    Title := rsSelectDxfFile;
    Filter := rsDxfFiles;
    Filename := '*.dxf';
    if Execute then Fname := Filename else exit;
  end;
  if LoadLayers(Fname) then
  begin
    DxfFileEdit.Text := MinimizeName(Fname, Canvas, DxfFileEdit.Width);
    if not SameText(Fname, DxfFileName) then HasChanged := true;
    DxfFileName := Fname;
    LayersCheckListBox.Enabled := true;
    NextBtn.Enabled := true;
  end
  else
  begin
    DxfFileEdit.Text := '';
    LayersCheckListBox.Enabled := false;
  end;
end;

procedure TDxfImporterForm.LayersCheckListBoxSelectionChange(Sender: TObject;
  User: boolean);
begin
  HasChanged := true;
end;

procedure TDxfImporterForm.PaintBox1Paint(Sender: TObject);
begin
  PaintBox1.Canvas.Draw(0, 0, Bitmap);
end;

procedure TDxfImporterForm.SetButtonStates;
begin
  ImportBtn.Visible := false;
  BackBtn.Visible := true;
  BackBtn.Enabled := true;
  NextBtn.Visible := true;
  NextBtn.Enabled := true;
  if Notebook1.PageIndex <= 1 then BackBtn.Enabled := false;
  if (Notebook1.PageIndex = 1)
  and (Length(Trim(DxfFileEdit.Text)) = 0)
  and (LayersCheckListBox.SelCount = 0) then
    NextBtn.Enabled := false;
  if Notebook1.PageIndex = 3 then
  begin
    NextBtn.Visible := false;
    ImportBtn.Visible := true;
    if HasChanged then
    begin
      GetSelectedLayers;
      if Layers.Count > 0 then
      begin
        Bitmap.SetSize(PaintBox1.Width, PaintBox1.Height);
        if dxfviewer.ViewDxfFile(DxfFileName, Layers, Bitmap) then
          HasChanged := false;
      end;
      PaintBox1.Refresh;
    end;
  end;
end;

function TDxfImporterForm.LoadLayers(Fname: string): Boolean;
var
  F: TextFile;
  Code: Integer;
  Value: string;
  Flag: Boolean;
begin
  Result := false;
  Flag := false;
  LayersCheckListBox.Clear;
  AssignFile(F, Fname);
  try
    Reset(F);
    while not Eof(F) do
    begin
      ReadLn(F, Code);
      ReadLn(F, Value);

      // Check if we have reached the Entities section
      if (Code = 2)
      and (CompareText(Value,'Entities') = 0) then
        break;

      // If a new layer has been found then add it to the list
      if (Code = 0)
      and (CompareText(Value,'Layer') = 0) then
        Flag := true;
      if (Code = 2)
      and Flag then
      begin
        LayersCheckListBox.Items.Add(Value);
        Flag := false;
      end;
    end;
    Result := true;
  finally
    CloseFile(F);
  end;
end;

procedure TDxfImporterForm.GetSelectedLayers;
var
  I: Integer;
begin
  Layers.Clear;
  with LayersCheckListBox do
  begin
    for I := 0 to Items.Count-1 do
      if Checked[I] then Layers.Add(Items[I]);
  end;
end;

end.
