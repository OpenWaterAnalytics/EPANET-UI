{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       shpviewer
 Description:  displays a shapefile's attribute table and its prj
               file and draws its image to a bitmap
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit shpviewer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids, Types,
  LCLtype, ExtCtrls, StdCtrls, Math, shpapi;

type

  { TShpViewerForm }

  TShpViewerForm = class(TForm)
    AttributePage:  TPage;
    DrawGrid1:      TDrawGrid;
    Memo1:          TMemo;
    Notebook1:      TNotebook;
    ProjectionPage: TPage;

    procedure DrawGrid1DrawCell(Sender: TObject; aCol, aRow: Integer;
      aRect: TRect; aState: TGridDrawState);
    procedure DrawGrid1KeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);

  private
    Dbf:           DBFHandle;
    FieldName:     array of string;
    FieldDecimals: array of Integer;
    FieldType:     array of DBFFieldType;

    function GetTableCellValue(C, R: Integer): string;

  public
    function  ViewDbfFile(Filename: string): Boolean;
    procedure ViewPrjFile(Filename: string);

  end;

var
  ShpViewerForm: TShpViewerForm;

  function  ViewShpFile(LinkFile, NodeFile: string; var Bitmap: TBitmap): Boolean;

  procedure ScaleNetwork(LinkShp: SHPHandle; NodeShp: SHPHandle;
            Bitmap: TBitmap; var LinkCount: Integer; var NodeCount: Integer);

  procedure DrawLink(Shp: SHPHandle; I: Integer; var Bitmap: TBitmap);

  procedure DrawNode(Shp: SHPHandle; I: Integer; var Bitmap: TBitmap);

  function  GetPoint(const X: Double; const Y: Double):TPoint;

implementation

{$R *.lfm}

uses
  config, utils, resourcestrings;

{ TShpViewerForm }

var
   CenterP:    TPoint;      // Bitmap center point
   CenterWx:   Double;      // World center X point
   CenterWy:   Double;      // World center Y point
   WPP:        Double;      // World per pixel scaling

procedure TShpViewerForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
  Memo1.Font.Size := config.FontSize;
  Dbf := nil;
end;

procedure TShpViewerForm.FormClose(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  shpapi.DBFClose(Dbf);
end;

procedure TShpViewerForm.DrawGrid1DrawCell(Sender: TObject; aCol,
  aRow: Integer; aRect: TRect; aState: TGridDrawState);
var
  S: string;
begin
  S := GetTableCellValue(aCol, aRow);
  with Sender as TDrawGrid do
  begin
    Canvas.TextRect(aRect, aRect.Left+2, aRect.Top+2, S);
  end;
end;

procedure TShpViewerForm.DrawGrid1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

procedure TShpViewerForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

function TShpViewerForm.ViewDbfFile(Filename: string): Boolean;
var
  I, N:      Integer;
  Fwidth:    Integer = 0;
  Fdecimals: Integer = 0;
  Fname:     array[0..XBASE_FLDNAME_LEN_READ] of Char = '';
begin
  Caption := rsShapeAttrib;
  Notebook1.PageIndex := 0;
  Filename := ChangeFileExt(Filename, '.dbf');
  Dbf := shpapi.DBFOpen(PAnsiChar(Filename), 'rb');

  if Dbf = nil then
  begin
    utils.MsgDlg(rsFileError, rsNoShapeAttrib, mtInformation, [mbOK], self);
    Result := false;
    exit;
  end;

  // Store data field info
  N := shpapi.DBFGetFieldCount(Dbf);
  DrawGrid1.ColCount := N;
  SetLength(FieldName, N);
  SetLength(FieldDecimals, N);
  SetLength(FieldType, N);
  DrawGrid1.RowCount := 1 + shpapi.DBFGetRecordCount(Dbf);

  for I := 0 to N-1 do
  begin
    FieldType[I] := shpapi.DBFGetFieldInfo(Dbf, I, Fname, Fwidth, Fdecimals);
    FieldName[I] := Fname;
    FieldDecimals[I] := Fdecimals;
  end;
  Result := true;
end;

procedure TShpViewerForm.ViewPrjFile(Filename: string);
begin
  Caption := rsProjParams;
  Notebook1.PageIndex := 1;
  Memo1.Lines.LoadFromFile(Filename);
  Memo1.SelStart := 0;
end;

function TShpViewerForm.GetTableCellValue(C, R: Integer): string;
var
  X:   Double;
  Fmt: string;
begin
  Result := '';
  if Dbf = nil then exit;
  if R = 0 then
  begin
    Result := FieldName[C];
    exit;
  end;

  R := R - 1;
  if FieldType[C] = FTString then
    Result := shpapi.DBFReadStringAttribute(Dbf, R, C)

  else if FieldType[C] = FTInteger then
    Result := IntToStr(shpapi.DBFReadIntegerAttribute(Dbf, R, C))

  else if FieldType[C] = FTDouble then
  begin
    X := shpapi.DBFReadDoubleAttribute(Dbf, R, C);
    Fmt := '%.' + IntToStr(FieldDecimals[C]) + 'f';
    Result := Format(Fmt, [X]);
  end;
end;

function ViewShpFile(LinkFile, NodeFile: string; var Bitmap: TBitmap): Boolean;
var
  LinkShp:    shpapi.SHPHandle;
  NodeShp:    shpapi.SHPHandle;
  LinkCount:  Integer;
  NodeCount:  Integer;
  I:          Integer;
begin
  Result := false;
  if Bitmap = nil then exit;
  if (Bitmap.Width = 0)
  or (Bitmap.Height = 0) then
    exit;

  // Clear bitmap canvas
  with Bitmap.Canvas do
  begin
    Pen.Color := clBlack;
    Brush.Color := clWhite;
    Brush.Style := bsSolid;
    Rectangle(0, 0, Bitmap.Width, Bitmap.Height);
  end;

  // Open shape files
  LinkShp := nil;
  NodeShp := nil;
  try
    LinkShp := shpapi.SHPOpen(PAnsiChar(LinkFile), 'rb');
    NodeShp := shpapi.SHPOpen(PAnsiChar(NodeFile), 'rb');
    if (LinkShp = nil)
    and (NodeShp = nil) then
      exit;

    // Scale network within boundaries of link coordinates
    ScaleNetwork(LinkShp, NodeShp, Bitmap, LinkCount, NodeCount);

    // Draw each link on Bitmap
    with Bitmap.Canvas do
    begin
      Pen.Color := $00BE9270;
      Pen.Width := 2;
      Brush.Color := $00BE9270;
    end;
    if LinkShp <> nil then
      for I := 0 to LinkCount-1 do
        DrawLink(LinkShp, I, Bitmap);

    // Draw each node on Bitmap
    Bitmap.Canvas.Pen.Color := clBlack;
    Bitmap.Canvas.Pen.Width := 1;
    if NodeShp <> nil then
      for I := 0 to NodeCount-1 do
        DrawNode(NodeShp, I, Bitmap);
    Result := true;

  finally
    shpapi.SHPClose(LinkShp);
    shpapi.SHPClose(NodeShp);
  end;
end;

procedure ScaleNetwork(LinkShp: SHPHandle; NodeShp: SHPHandle;
  Bitmap: TBitmap; var LinkCount: Integer; var NodeCount: Integer);
var
   ShapeType:   Integer = 0;
   MinBound:    array [0..3] of Double = (0,0,0,0);
   MaxBound:    array [0..3] of Double = (0,0,0,0);
   Xmin, Ymin:  Double;
   Xmax, Ymax:  Double;
   WPPx, WPPy:  Double;
   Dx, Dy:      Double;
begin
  LinkCount := 0;
  NodeCount := 0;
  Xmin := 1.e20;
  Ymin := 1.e20;
  Xmax := -1.e20;
  Ymax := -1.e20;
  if LinkShp <> nil then
  begin
    shpapi.SHPGetInfo(LinkShp, LinkCount, ShapeType, MinBound, MaxBound);
    Xmin := MinBound[0];
    Ymin := MinBound[1];
    Xmax := MaxBound[0];
    Ymax := MaxBound[1];
  end;
  if NodeShp <> nil then
  begin
    shpapi.SHPGetInfo(NodeShp, NodeCount, ShapeType, MinBound, MaxBound);
    Xmin := Min(Xmin, MinBound[0]);
    Ymin := Min(Ymin, MinBound[1]);
    Xmax := Max(Xmax, MaxBound[0]);
    Ymax := Max(Ymax, MaxBound[1]);
  end;

  // Center of bounding rectangle
  Dx := Xmax - Xmin;
  Dy := Ymax - Ymin;
  CenterWx := Xmin + Dx/2.0;
  CenterWy := Ymin + Dy/2.0;
  CenterP := Point(Bitmap.Width div 2, Bitmap.Height div 2);

  // World distance units per pixel in the X & Y directions
  WPPx := Dx / Bitmap.Width;
  WPPy := Dy / Bitmap.Height;

  // Maintain a 1:1 aspect ratio
  if WPPy > WPPx then
    WPP := WPPy
  else
    WPP := WPPx;
end;

procedure DrawLink(Shp: SHPHandle; I: Integer; var Bitmap: TBitmap);
var
   ShpObj: shpapi.PShpObject;
   N:      Integer;
   K:      Integer;
   P:      TPoint;
begin
  ShpObj := shpapi.SHPReadObject(Shp, I);
  if ShpObj = nil then exit;
  N := ShpObj^.nVertices;
  if N > 1 then
  begin
    P := GetPoint(ShpObj^.padfX[0], ShpObj^.padfY[0]);
    Bitmap.Canvas.MoveTo(P.X, P.Y);
    for K := 1 to N - 1 do
      Bitmap.Canvas.LineTo(GetPoint(ShpObj^.padfX[K], ShpObj^.padfY[K]));
  end;
  shpapi.SHPDestroyObject(ShpObj);
end;

procedure DrawNode(Shp: SHPHandle; I: Integer; var Bitmap: TBitmap);
const
  Size: Integer = 4;
var
   ShpObj: shpapi.PShpObject;
   P:      TPoint;
begin
  ShpObj := shpapi.SHPReadObject(Shp, I);
  if ShpObj = nil then exit;
  P := GetPoint(ShpObj^.padfX[0], ShpObj^.padfY[0]);
  BitMap.Canvas.Ellipse(P.X - Size, P.Y - Size, P.X + Size, P.Y + Size);
  shpapi.SHPDestroyObject(ShpObj);
end;

function GetPoint(const X: Double; const Y: Double):TPoint;
begin
  Result.X := CenterP.X + Round((X - CenterWx) / WPP);
  Result.Y := CenterP.Y - Round((Y - CenterWy) / WPP);
end;

end.
