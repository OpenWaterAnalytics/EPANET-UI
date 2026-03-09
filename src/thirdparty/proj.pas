unit proj;

{
  Declarations of functions imported from the proj.4 library
  that transforms geospatial coordinates from one coordinate
  reference system to another.
}
{ NOTE: THIS IS FOR 64-BIT PLATFORMS ONLY }

interface

const

  RAD_TO_DEG = 57.29577951308232;
  DEG_TO_RAD = 0.0174532925199432958;
  
{$MACRO ON}

{$ifdef MSWINDOWS}
  ProjLib = 'proj.dll';
{$endif}

{$ifdef UNIX}
  {$ifdef DARWIN}
     ProjLib = 'proj.dylib';
     {$linklib libproj}
  {$else}
    ProjLib = 'libproj.so';
  {$endif}
{$endif}

type
  ProjHandle = Int64;

function  pj_init_plus(args: PAnsiChar): ProjHandle; cdecl; external ProjLib;
function  pj_transform(src, dst: ProjHandle; pt_count: Int64; pt_offset: Integer;
                       var x, y, z: Double): Integer; cdecl; external ProjLib;
function  pj_is_latlong(proj: ProjHandle): Integer; cdecl; external ProjLib;
procedure pj_free(proj: ProjHandle); cdecl; external ProjLib;

implementation

end.
