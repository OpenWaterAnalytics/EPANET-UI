{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       projtransform
 Description:  transforms one map projection to another
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

{
  This unit contains a TProjTransform class used to transform
  geospatial coordinates from one coordinate reference system
  (CRS) to another. It uses:
    1. the Proj.4 library whose Pascal API declarations are
       contained in proj.pas.
    2. the restclient.pas unit used to make a web request for
       the Proj.4 projection string for a given CRS EPSG code.

  Typical usage to transform coordinates X and Y from a
  coordinate system with EPSG code SrcEPSG to one with code DstEPSG:

  function Transform(SrcEPSG, DstEPSG: string; var X, Y: Double): Boolean;
  var
    ProjTrans: TProjTransform;
  begin
    Result := false;
    ProjTrans := TProjTransform.Create;
    try
      if not ProjTrans.SetProjections(SrcEPSG, DstEPSG) then exit;
      ProjTrans.Transform(X, Y);
      Result := true;
    finally
      ProjTrans.Free;
    end;
  end;
==================================================================}

unit projtransform;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, utils, proj;

type
  TProjTransform = class(TObject)
    private
      SrcProj, DstProj: proj.ProjHandle;
      IsSrcLatLong, IsDstLatLong: Integer;
      function GetProjHandle(EPSGcode: string): proj.ProjHandle;
    public
      constructor Create;
      destructor Destroy; override;
      function SetProjections(SrcEPSG, DstEPSG: string): Boolean;
      function Transform(var X, Y: Double): Boolean;
  end;
implementation

constructor TProjTransform.Create;
begin
  inherited Create;
  SrcProj := 0;
  DstProj := 0;
  IsSrcLatLong := 0;
  IsDstLatLong := 0;
end;

destructor TProjTransform.Destroy;
begin
  if SrcProj <> 0 then proj.pj_free(SrcProj);
  if DstProj <> 0 then proj.pj_free(DstProj);
  inherited Destroy;
end;

function TProjTransform.GetProjHandle(EPSGcode: string): proj.ProjHandle;
var
  Url: string;
  ProjStr: string;
begin
  // Obtain the projection's string from its EPSG code
  Result := 0;
  ProjStr := '';
  Url := 'https://epsg.io/' + EPSGcode + '.proj4';
  try
    if utils.HttpRequest(Url, ProjStr) then
      Result := proj.pj_init_plus(PAnsiChar(ProjStr));
  except
    On E: Exception do
      Result := 0;
  end;
end;

function TProjTransform.SetProjections(SrcEPSG, DstEPSG: string): Boolean;
begin
  // Free current source & destination projection handles
  Result := false;
  if SrcProj <> 0 then proj.pj_free(SrcProj);
  if DstProj <> 0 then proj.pj_free(DstProj);

  // Create handle for source projection
  SrcProj := GetProjHandle(SrcEPSG);
  if SrcProj <> 0 then
    IsSrcLatLong := proj.pj_is_latlong(SrcProj)
  else
    exit;

  // Create handle for destination projection
  DstProj := GetProjHandle(DstEPSG);
  if DstProj <> 0 then
    IsDstLatLong := proj.pj_is_latlong(DstProj)
  else
    exit;

  Result := true;
end;

function TProjTransform.Transform(var X, Y: Double): Boolean;
var
  Z: Double = 0;
begin
  Result := false;
  if (SrcProj = 0)
  or (DstProj = 0) then
    exit;
  if IsSrcLatLong = 1 then
  begin
    X := X * DEG_TO_RAD;
    Y := Y * DEG_TO_RAD;
  end;
  if proj.pj_transform(SrcProj, DstProj, 1, 1, X, Y, Z) <> 0 then exit;
  if IsDstLatLong = 1 then
  begin
    X := X * RAD_TO_DEG;
    Y := Y * RAD_TO_DEG;
  end;
  Result := true;
end;

end.

