{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       utils
 Description:  contains various utility functions
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit utils;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, StdCtrls, Dialogs, Math, Graphics, Controls, ComCtrls,
  GraphType, IntfGraphics, LCLType, LCLProc,  LCLIntf, DateUtils, System.UItypes,
  FPImage, fphttpclient, opensslsockets,

  // EPANET-UI unit
  mapcoords;

procedure AutoScale(var Zmin: Double; var Zmax: Double; var T: Double);
procedure BrightenBitmap(Bitmap: TBitmap; Brightness: Integer);
function  CreateTempFile(Prefix: string): string;

function  FindTreeNode(aTreeView: TTreeView; Text: string): TTreeNode;
function  Float2Str(const X: Double; const N: Integer): string;
procedure GetTextSize(const aText: string; aFont: TFont; var H, W: Integer);
procedure GrayscaleBitmap(Bitmap: TBitmap);

function  HasInternetConnection: Boolean;
function  Haversine(X1, Y1, X2, Y2: Double): Double;
function  HttpRequest(aUrl: string; var Str: string): Boolean;
procedure InvertBitmap(Bitmap: TBitmap);

function  MsgDlg(const Title: string; const Msg: string; DlgType: TMsgDlgType;
          Buttons: TMsgDlgButtons): Integer; overload;
function  MsgDlg(const Title: string; const Msg: string; DlgType: TMsgDlgType;
          Buttons: TMsgDlgButtons; F: TForm): Integer; overload;

function  PointInPolygon(const P: TDoublePoint; const Bounds: TDoubleRect;
          const Npts: Integer; Poly: TPolygon): Boolean;
function  PointOnLine(const P1: TPoint; const P2: TPoint;
          const P: TPoint; const Ptol: Integer): Boolean;
function  PolygonBounds(Poly: TPolygon; const Npts: Integer): TDoubleRect;
procedure ResizeControl(aControl:TControl;
          const ParentWidth, ParentHeight: Integer;
          const WidthRatio, HeightRatio: Integer;
          const WidthOffset, HeightOffset: Integer);

function  Str2Float(const S: string; var X: Single): Boolean; overload;
function  Str2Float(const S: string; var X: Double): Boolean; overload;
function  Str2Seconds(S: string): Integer;
procedure SwapListBoxLines(aListBox: TCustomListBox; Direction: Integer);
function  Time2Str(T: Integer): string;
function  TimeOfDayStr(T: Integer): string;

implementation

uses
  reportviewer;

type
  TMyHTTPRequest = class(TThread)
  protected
      procedure Execute; override;
  end;

var
  ConnectedToInternet: Boolean;

function TaskDlg(const Title: string; const Msg: string; DlgType: TMsgDlgType;
          DlgButtons: TMsgDlgButtons; F: TForm): Integer; forward;

procedure AutoScale(var Zmin: Double; var Zmax: Double; var T: Double);
//
// Find a nice scaling between Zmin and Zmax at intervals of T.
//
var
  M: Integer;
  Z: Longint;
  D: Double;
  Z1: Double;
  Z2: Double;
begin
  Z1 := Zmin;
  Z2 := Zmax;
  try
    D := Abs(Zmax-Zmin);
    if (D = 0.0)
    and (Zmin = 0.0) then
    begin
      Zmin := -1.0;
      Zmax := 1.0;
      T := 1.0;
      exit;
    end
    else if D < 0.01 then
    begin
      Zmin := Zmin - 0.5 * Abs(Zmin);
      Zmax := Zmax + 0.5 * Abs(Zmax);
    end;
    D := Abs(Zmax - Zmin);
    M := Trunc(Ln(D) / Ln(10.0));
    T := IntPower(10., M);
    if T > 0.5 * D then
      T := 0.2 * T
    else if T > 0.2 * D then
      T := 0.5*T;
    Z := Trunc(Zmax/T) + 1;
    Zmax := Z * T;
    Z := Trunc(Zmin / T);
    if Zmin < 0 then Z := Z - 1;
    Zmin := Z * T;
    if Zmin = Zmax then Zmax := Zmin + T;
    if Abs(Zmin-Zmax) / T > 10.0 then T := 2.0 * T;
  except
    Zmin := Z1;
    Zmax := Z2;
    T := Z2 - Z1;
  end;
end;

procedure BrightenBitmap(Bitmap: TBitmap; Brightness: Integer);
//
// Brighten the colors used in a bitmap image.
//
var
  X: Integer;
  Y: Integer;
  R: Byte;
  G: Byte;
  B: Byte;
  C: TColor;
  Fpc: TFPColor;
  IntfImage: TLazIntfImage;
begin
  IntfImage := Bitmap.CreateIntfImage;
  try
    for Y := 0 to IntfImage.Height - 1 do
    begin
      for X := 0 to IntfImage.Width - 1 do
      begin
        Fpc := IntfImage.Colors[X, Y];
        C := FPColorToTColor(Fpc);
        R := Red(C);
        G := Green(C);
        B := Blue(C);
        R := R + (Brightness*(255 - R) div 100);
        R := Min(255, R);
        G := G + (Brightness*(255 - G) div 100);
        G := Min(255, G);
        B := B + (Brightness*(255 - B) div 100);
        B := Min(255, B);
        C := RGBToColor(R, G, B);
        IntfImage.Colors[X, Y] := TColorToFPColor(C);
      end;
    end;
    Bitmap.LoadFromIntfImage(IntfImage);
  finally
    IntfImage.Free;
  end;
end;

function  CreateTempFile(Prefix: string): string;
//
//  Create a temporary file on disk.
//
var
  FileHandle: TLCLHandle;
begin
  Result := SysUtils.GetTempFileName('', Prefix);
  try
    FileHandle := FileCreate(Result);
    FileClose(FileHandle);
  except
  end;
end;

function FindTreeNode(aTreeView: TTreeView; Text: string): TTreeNode;
//
//  Find the node of a TreeView with a given text.
//
var
  TreeNode: TTreeNode;
begin
  Result := nil;
  TreeNode := aTreeView.Items[0];
  while TreeNode <> nil do
  begin
    if SameText(TreeNode.Text, Text) then
    begin
      Result := TreeNode;
      break;
    end;
    TreeNode := TreeNode.GetNext;
  end;
end;

function Float2Str(const X: Double; const N: Integer): String;
//
//  Represent a number X as a string with N decimal places.
//
begin
  Result := Format('%*.*f', [0, N, X]);
end;

procedure GetTextSize(const aText: String; aFont: TFont; var H, W: Integer);
//
//  Find the width and height in pixels of a given string.
//
var
  bmp: Graphics.TBitmap; // Graphics.TBitmap, not Windows.TBitmap
begin
  bmp := Graphics.TBitmap.Create;
  try
    bmp.Canvas.Font.Assign(aFont);
    H := bmp.Canvas.TextHeight(aText);
    W := bmp.Canvas.TextWidth(aText);
  finally
    bmp.Free;
  end;
end;

procedure GrayscaleBitmap(Bitmap: TBitmap);
//
//  Re-color a bitmap image in grayscale.
//
var
  X: Integer;
  Y: Integer;
  R: Byte;
  G: Byte;
  B: Byte;
  MonoByte: Byte;
  C: TColor;
  Fpc: TFPColor;
  IntfImage: TLazIntfImage;
begin
  IntfImage := Bitmap.CreateIntfImage;
  try
    for Y := 0 to IntfImage.Height - 1 do
    begin
      for X := 0 to IntfImage.Width - 1 do
      begin
        Fpc := IntfImage.Colors[X, Y];
        C := FPColorToTColor(Fpc);
        R := Red(C);
        G := Green(C);
        B := Blue(C);
        MonoByte := Round(0.2125 * R + 0.7154 * G + 0.0721 * B);
        C := RGBToColor(MonoByte, MonoByte, MonoByte);
        IntfImage.Colors[X, Y] := TColorToFPColor(C);
      end;
    end;
    Bitmap.LoadFromIntfImage(IntfImage);
  finally
    IntfImage.Free;
  end;
end;

function HasInternetConnection: Boolean;
//
//  Check if an internet connection exists.
//
var
  MyThread: TMyHTTPRequest;
begin
  ConnectedToInternet := false;
  MyThread := TMyHTTPRequest.Create(true);
  MyThread.FreeOnTerminate := true;
  MyThread.Start;
  Sleep(2000);
  Result := ConnectedToInternet;
end;

procedure TMyHTTPRequest.Execute;
var
  Client: TFPHttpClient;
begin
  Client := TFPHttpClient.Create(nil);
  try
    Client.ConnectTimeout := 2000;
    try
      Client.Get('http://www.example.com');
      ConnectedToInternet := true;
    except
      ConnectedToInternet := false;
    end;
  finally
    Client.Free;
  end;
end;

function Haversine(X1, Y1, X2, Y2: Double): Double;
//
// Find the distance in meters between two points on a spherical earth
// given their longitudes (X) and latitudes (Y) in decimal degrees.
//
var
  P: Double;
  Dy: Double;
  Dx: Double;
  SinDy: Double;
  SinDx: Double;
  A: Double;
  C: Double;
begin
  P := PI / 180.;   //degrees to radians
  Dy := (Y2 - Y1) * P;
  Dx := (X2 - X1) * P;
  SinDy := Sin(Dy / 2);
  SinDx := Sin(Dx / 2);
  A := (SinDy * SinDy) + (Cos(Y1 * P) * Cos(Y2 * P) * (SinDx * SinDx));
  C := 2 * ArcTan2(Sqrt(A), Sqrt(1-A));
  Result := 6371 * 1000 * C;   //6371 = avg. radius of earth in km
end;

function  HttpRequest(aUrl: string; var Str: string): Boolean;
//
// Retrieve a string from a HTTP REST request.
//
var
  Client: TFPHTTPClient;
  Response: TStringList;
begin
  Result := false;
  Response := TStringList.Create;
  Client := TFPHttpClient.Create(nil);
  try
    try
      try
        Client.IOTimeout := 4000;
        Client.AllowRedirect := true;
        Client.Get(aUrl, Response);
      except
        raise;
      end;

    finally
      Client.Free;
    end;
    Str := Response.Text;
    Result := true;
  finally
    Response.Free;
  end;
end;

procedure InvertBitmap(Bitmap: TBitmap);
//
// Invert the colors used in a bitmap image.
//
var
  X: Integer;
  Y: Integer;
  R: Byte;
  G: Byte;
  B: Byte;
  C: TColor;
  Fpc: TFPColor;
  IntfImage: TLazIntfImage;
begin
  IntfImage := Bitmap.CreateIntfImage;
  try
    for Y := 0 to IntfImage.Height - 1 do
    begin
      for X := 0 to IntfImage.Width - 1 do
      begin
        Fpc := IntfImage.Colors[X, Y];
        C := FPColorToTColor(Fpc);
        R := Red(C);
        G := Green(C);
        B := Blue(C);
        R := 255 - R;
        G := 255 - G;
        B := 255 - B;
        C := RGBToColor(R, G, B);
        IntfImage.Colors[X, Y] := TColorToFPColor(C);
      end;
    end;
    Bitmap.LoadFromIntfImage(IntfImage);
  finally
    IntfImage.Free;
  end;
end;

function  MsgDlg(const Title: string; const Msg: string; DlgType: TMsgDlgType;
          Buttons: TMsgDlgButtons): Integer; overload;
//
// Display a message dialog in center of currently active form.
//
begin
  Result := TaskDlg(Title, Msg, DlgType, Buttons, Screen.ActiveForm);
end;

function  MsgDlg(const Title: string; const Msg: string; DlgType: TMsgDlgType;
          Buttons: TMsgDlgButtons; F: TForm): Integer; overload;
//
// Display a message dialog in center of a specific form.
//
begin
  Result := TaskDlg(Title, Msg, DlgType, Buttons, F);
end;

function  PointInPolygon(const P: TDoublePoint; const Bounds: TDoubleRect;
          const Npts: Integer; Poly: TPolygon): Boolean;
//
// Determine if point is contained in a polygon.
//
// Adapted from https://wrfranklin.org/Research/Short_Notes/pnpoly.html.
//
// TDoublePoint, TDoubleRect, and TPolygon are defined in mapcoods.pas.

var
  I: Integer;
  J: Integer;
  T: Double;
begin
  Result := false;
  if (P.X < Bounds.LowerLeft.X)
  or (P.Y < Bounds.LowerLeft.Y)
  or (P.X > Bounds.UpperRight.X)
  or (P.Y > Bounds.UpperRight.Y) then exit;

  I := 0;
  J := Npts - 1;
  while I < Npts do
  begin
    if (Poly[I].Y > P.Y) <> (Poly[J].Y > P.Y) then
    begin
      T := (Poly[J].X - Poly[I].X) * (P.Y - Poly[I].Y) /
           (Poly[J].Y - Poly[I].Y) + Poly[I].X;
      if P.X < T then Result := not Result;
    end;
    J := I;
    Inc(I);
  end;
end;

function PointOnLine(const P1: TPoint; const P2: TPoint;
          const P: TPoint; const Ptol: Integer): Boolean;
//
//  Determine if point P is within Ptol distance of the line
//  between points P1 and P2.
//
var
  dx: Integer;
  dy: Integer;
  dx1: Integer;
  dy1: Integer;
  a: Integer;
  b: Integer;
  c: Integer;
begin
  Result := false;
  dx := P2.X - P1.X;
  dy := P2.Y - P1.Y;
  dx1 := P.X - P1.X;
  dy1 := P.Y - P1.Y;
  if (Abs(dx) > 0)
  and (Abs(dy) < Abs(dx)) then
  begin
    if (dx * dx1 >= 0)
    and (Abs(dx1) <= Abs(dx)) then
    begin
      a := (dy * dx1);
      b := (dx * dy1);
      c := Abs(dx * Ptol);
      if Abs(a - b) <= c then Result := true;
    end;
  end
  else if Abs(dy) > 0 then
  begin
    if (dy * dy1 >= 0)
    and (Abs(dy1) <= Abs(dy)) then
    begin
      a := (dx * dy1);
      b := (dy * dx1);
      c := Abs(dy * Ptol);
      if Abs(a - b) <= c then Result := true;
    end;
  end;
end;

function  PolygonBounds(Poly: TPolygon; const Npts: Integer): TDoubleRect;
//
//  Find the bounding rectangle of a polygon.
//
var
  I: Integer;
  Bmin: TDoublePoint = (X:0; Y:0);
  Bmax: TDoublePoint = (X:0; Y:0);
begin
  if Npts > 0 then
  begin
    Bmin.X := Poly[0].X;
    Bmin.Y := Poly[0].Y;
    Bmax.X := Bmin.X;
    Bmax.Y := Bmin.Y;
    for I := 1 to Npts-1 do
    begin
      Bmin.X := Math.Min(Bmin.X, Poly[I].X);
      Bmin.Y := Math.Min(Bmin.Y, Poly[I].Y);
      Bmax.X := Math.Max(Bmax.X, Poly[I].X);
      Bmax.Y := Math.Max(Bmax.Y, Poly[I].Y);
    end;
  end;
  Result.LowerLeft := Bmin;
  Result.UpperRight := Bmax;
end;

procedure ResizeControl(aControl:TControl;
          const ParentWidth, ParentHeight: Integer;
          const WidthRatio, HeightRatio: Integer;  // as percentages
          const WidthOffset, HeightOffset: Integer);
//
//  Resize a control to maintain a 2:1 width to height ratio.
//
var
  MinWidth: Integer;
  MinHeight: Integer;
begin
  MinWidth := ParentWidth - WidthOffset;
  aControl.Width := (ParentWidth * WidthRatio) div 100;
  aControl.Width := Min(MinWidth, aControl.Width);
  aControl.Left := (ParentWidth - aControl.Width) div 2;
  aControl.Top := HeightOffset;
  MinHeight := ParentHeight;
  aControl.Height := Min(MinHeight, (aControl.Width * HeightRatio) div 100);
end;

function  Str2Float(const S: string; var X: Single): Boolean; overload;
begin
  X := 0;
  Result := true;
  try
    X := StrToFloat(S);
  except
    On EConvertError do Result := false;
  end;
end;

function  Str2Float(const S: string; var X: Double): Boolean; overload;
begin
  X := 0;
  Result := true;
  try
    X := StrToFloat(S);
  except
    On EConvertError do Result := false;
  end;
end;

function  Str2Seconds(S: String): Integer;
//
//  Convert a time string to number of seconds.
//
var
  T: TDateTime;
begin
  try
    // If no ':' separator then S is a decimal number
    if (Pos(':', S) = 0) then
      Result := Round(StrToFloat(S) * 3600)
    else
    begin
      T := StrToTime(S);
      Result := (HourOf(T)*60*60) + (MinuteOf(T)*60) + SecondOf(T);
    end;
  except
    on EConvertError do Result := -1;
  end;
end;

procedure SwapListBoxLines(aListBox: TCustomListBox; Direction: Integer);
//
//  Exchange the currently selected item in a ListBox with the item above
//  or below it.
//
var
  I: Integer;
  K: Integer;
begin
  if Direction < 0 then
    K := -1
  else
    K := 1;
  I := aListBox.ItemIndex;
  if (K < 0)
  and (I <= 0) then exit;
  if (K > 0)
  and (I >= aListBox.Items.Count-1) then exit;
  aListBox.Items.Exchange(I, I + K);
  aListBox.Selected[I + K] := true;
  aListBox.ItemIndex := I + K;
end;

function TaskDlg(const Title: string; const Msg: string; DlgType: TMsgDlgType;
          DlgButtons: TMsgDlgButtons; F: TForm): Integer;
//
//  Display a TaskDialog of type DlgType with message Msg and dialog buttons
//  DlgButtons in the center of form F.
//
var
  TD: TTaskDialog;
  ShowReportForm: Boolean = false;
begin

  // If the ReportViewerForm is showing then hide it so this dialog
  // doesn't get hidden behind it
  if ReportViewerForm.Visible
  and (ReportViewerForm.WindowState <> wsMinimized) then
  begin
    ReportViewerForm.Hide;
    ShowReportForm := true;
  end;

  TD := TTaskDialog.Create(F);
  try
    TD.Caption := 'EPANET-UI';  //The dialog window caption
    if Length(Title) > 0 then
      TD.Title := Title;        //The large blue text
    TD.Text := Msg;             //The smaller black text
    TD.CommonButtons := [tcbOk];
    TD.DefaultButton := tcbOk;
    TD.Flags := TD.Flags + [tfPositionRelativeToWindow];
    if DlgType = mtError then
      TD.MainIcon := tdiError
    else if DlgType = mtInformation then
      TD.MainIcon := tdiInformation
    else if DlgType = mtConfirmation then
    begin
      TD.MainIcon := tdiQuestion;
      TD.CommonButtons := [];
      if mbOK in DlgButtons then
        TD.CommonButtons := TD.CommonButtons + [tcbOk];
      if mbYes in DlgButtons then
        TD.CommonButtons := TD.CommonButtons + [tcbYes];
      if mbNo in DlgButtons then
        TD.CommonButtons := TD.CommonButtons + [tcbNo];
      if mbCancel in DlgButtons then
        TD.CommonButtons := TD.CommonButtons + [tcbCancel];
    end
    else
      TD.MainIcon := tdiNone;
    if TD.Execute then Result := TD.ModalResult;
  finally
    if ShowReportForm then ReportViewerForm.Show;
    TD.Free;
  end;
end;

function Time2Str(T: Integer): string;
//
//  Convert a time in seconds to H:M;S format.
//
var
  H: Integer;
  M: Integer;
  S: Integer;
begin
  H := T div 3600;
  M := (T - H * 3600) div 60;
  S := T - (H * 3600) - (M * 60);
  if S = 0 then
    Result := Format('%.2d:%.2d', [H,M])
  else
    Result := Format('%.2d:%.2d:%.2d', [H,M,S])
end;

function TimeOfDayStr(T: Integer): string;
//
//  Convert the number of seconds since midnight to H:M:S am/pm format.
//
var
  H: Integer;
  M: Integer;
  S: Integer;
  PM: Boolean = false;
begin
  H := T div 3600;
  M := (T - H * 3600) div 60;
  S := T - (H * 3600) - (M * 60);
  H := H mod 24;
  if (H = 0)
  or (H = 24) then
    H := 12
  else if H = 12 then
    PM := true
  else if H > 12 then
  begin
    H := H - 12;
    PM := true;
  end;
  if S = 0 then
    Result := Format('%.2d:%.2d', [H,M])
  else
    Result := Format('%.2d:%.2d:%.2d', [H,M,S]);
  if not PM then
    Result := Result + ' am'
  else
    Result :=  Result + ' pm';
end;

end.

