unit epanetmsx;

{ Abridged set of API procedures from the EPANET-MSX TOOLKIT }

interface

const

{$MACRO ON}

{$ifdef MSWINDOWS}
  MsxLib = 'epanetmsx.dll';
  {$DEFINE cdecl := stdcall}
{$endif}

{$ifdef UNIX}
  {$ifdef DARWIN}
     MsxLib = 'libepanetmsx.dylib';
     {$linklib libepanetmsx}
  {$else}
     MsxLib = 'libepanetmsx.so';
  {$endif}
{$endif}

function MSXopen(Fname: PAnsiChar): Integer; cdecl; external MsxLib;
function MSXsolveH: Integer; cdecl; external MsxLib;
function MSXusehydfile(Fname: PAnsiChar): Integer; cdecl; external MsxLib;
function MSXsolveQ: Integer; cdecl; external MsxLib;
function MSXinit(SaveFlag: Integer): Integer; cdecl; external MsxLib;
function MSXstep(var T: Double; var Tleft: Double): Integer; cdecl; external MsxLib;
function MSXsaveoutfile(Fname: PAnsiChar): Integer; cdecl; external MsxLib;
function MSXsavemsxfile(Fname: PAnsiChar): Integer; cdecl; external MsxLib;
function MSXreport: Integer; cdecl; external MsxLib;
function MSXclose: Integer; cdecl; external MsxLib;

implementation

end.
