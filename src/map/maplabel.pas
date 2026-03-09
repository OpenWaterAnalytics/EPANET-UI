{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       maplabel
 Description:  a class representing a text label on the network map
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}
unit maplabel;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Types;

const
  MISSING = -1.E10;

type
  TMapLabel = class(TObject)
    X          : Double;
    Y          : Double;
    AnchorNode : string;
    Font       : TFont;
    Rotation   : Integer;
    Extent     : TSize;
    constructor Create;
    destructor Destroy; override;
    function GetRect(P: TPoint): TRect;
  end;

implementation

constructor TMaplabel.Create;
begin
  inherited Create;
  X := MISSING;
  Y := MISSING;
  AnchorNode := '';
  Font := TFont.Create;
  Font.Name := 'Arial';
  Font.Size := 10;
  Font.Style := [];

  {$ifndef WINDOWS}
    font.style := font.Style + [fsBold];
  {$endif}

  Font.Orientation := 0;
  Rotation := 0;
  Extent.cx := 0;
  Extent.cy := 0;
end;

destructor TMapLabel.Destroy;
begin
  Font.Free;
  inherited Destroy;
end;

function TMapLabel.GetRect(P: TPoint): TRect;
begin
  Result := Rect(P.X, P.Y, P.X + Extent.cx, P.Y + Extent.cy);
end;

end.

