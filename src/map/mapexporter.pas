{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       mapexporter
 Description:  a frame that exports the pipe network map to the
               clipboard or to a file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit mapexporter;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, StdCtrls, ExtCtrls, Buttons,
  ComCtrls, Graphics, Clipbrd;

type

  { TMapExporterFrame }

  TMapExporterFrame = class(TFrame)
    ExportBtn:      TBitBtn;
    IncludeLgndCB:  TCheckBox;
    CloseBtn:       TSpeedButton;
    Label1:         TLabel;
    ToClipbrdRB:    TRadioButton;
    ToFileRB:       TRadioButton;
    TopPanel:       TPanel;

    procedure Init;
    procedure CloseBtnClick(Sender: TObject);
    procedure ExportBtnClick(Sender: TObject);

  private
    procedure ExportMapToFile(IncludeLegend: Boolean);
    procedure CopyMap(FileName: string; IncludeLegend: Boolean);

  public

  end;

implementation

{$R *.lfm}

uses
  main, project, config, utils;

{ TMapExporterFrame }

procedure TMapExporterFrame.Init;
begin
  Color := config.CreamTheme;
  TopPanel.Color := config.ThemeColor;
  ToClipbrdRB.Checked := true;
  IncludeLgndCB.Checked := false;
end;

procedure TMapExporterFrame.ExportBtnClick(Sender: TObject);
var
  IncludeLgnd: Boolean;
begin
  IncludeLgnd := IncludeLgndCB.Checked;
  if ToFileRB.Checked then
    ExportMapToFile(IncludeLgnd)
  else
    CopyMap('', IncludeLgnd);
  Hide;
end;

procedure TMapExporterFrame.CloseBtnClick(Sender: TObject);
begin
  Visible := false;
end;

procedure TMapExporterFrame.ExportMapToFile(IncludeLegend: Boolean);
begin
  with MainForm.SavePictureDialog1 do
  begin
    if project.InpFile.Length > 0 then
    begin
      InitialDir := ExtractFileDir(project.InpFile);
      FileName := ChangeFileExt(ExtractFileName(project.InpFile), '.png');
    end;
    if Execute then CopyMap(FileName, IncludeLegend);
  end;
end;

procedure TMapExporterFrame.CopyMap(FileName: string; IncludeLegend: Boolean);
//
//  Paints the network map & its legend onto a bitmap which is either
//  copied to the clipboard or saved to a file.
//
var
  H2,
  W1,
  W2:        Integer;
  R:         TRect;
  Bitmap:    TBitmap;
  TreeNode:  TTreeNode = nil;
begin
  // To get accurate dimensions for the map legend, hide this frame
  // which sits above it
  Visible := false;

  // Get dimensions of the map legend (displayed in the main form's
  // LegendTreeView) and of the network map (displayed in the main
  // form's MapFrame)
  with MainForm do
  begin
    W1 := LegendTreeView.Width - 30;
    if not IncludeLegend then W1 := 0;
    H2 := MapFrame.MapBox.Height;
    W2 := MapFrame.MapBox.Width;
  end;

  // Create a bitmap that will contain the exorted map
  Bitmap := TBitmap.Create;
  try

    // Size the exported bitmap and its bounding rectangle
    Bitmap.SetSize(W1 + W2, H2);
    R := Rect(0, 0, W1 + W2, H2);

    // Fill the exported bitmap with the color of the main form's legend
    with Bitmap.Canvas do
    begin
      Brush.Color := MainForm.LegendTreeView.Color;
      Brush.Style := bsSolid;
      FillRect(R);
    end;

    // Add the main form's legend to the exported bitmap
    if IncludeLegend then
    begin

      // Do not include the 'Layers' portion of the legend
      TreeNode := utils.FindTreeNode(MainForm.LegendTreeView, 'Layers');
      if TreeNode <> nil then
      begin
        TreeNode.Visible := false;
      end;

      // Paint the legend onto the exported bitmap
      MainForm.LegendTreeView.PaintTo(Bitmap.Canvas, 10, 10);
    end;

    // Copy the network map's bitmap image into the exported bitmap
    R := Rect(W1, 0, W1 + W2, H2);
    Bitmap.Canvas.CopyRect(R, MainForm.MapFrame.Map.Bitmap.Canvas,
      Rect(0, 0, W2, H2));

    // Draw a line separating the legend & the map
    if IncludeLegend then
      Bitmap.Canvas.Line(W1, 0, W1, H2);

    // Draw a frame around the exported bitmap
    R := Rect(0, 0, W1 + W2, H2);
    Bitmap.Canvas.Brush.Style := bsClear;
    Bitmap.Canvas.Rectangle(0, 0, W1+W2, H2);

    // Send the exported bitmap to either the clipboard or to a file
    if Length(FileName) = 0 then
    begin
      Clipboard.Assign(Bitmap);
    end
    else
      Bitmap.SaveToFile(FileName);

  finally
    // Free the exported bitmap and restore the full legend display
    Bitmap.Free;
    if TreeNode <> nil then
      TreeNode.Visible := true;
  end;
end;

end.

