{====================================================================
  Limited subset of the full Shapelib API modified to accommodate a
  64-bit compilation of the v.1.5.0 library.
=====================================================================}

Unit ShpAPI;

Interface

Const

// ----------------------------------------------------------------------------
// Current DLL release
// ----------------------------------------------------------------------------
{$MACRO ON}

{$ifdef MSWINDOWS}
  LibName = 'shplib.dll';
  {$DEFINE cdecl := stdcall}
{$endif}

{$ifdef UNIX}
  {$ifdef DARWIN}
     LibName = 'libshp.dylib';
     {$linklib libshp}
  {$else}
     LibName = 'libshp.so';
  {$endif}
{$endif}


// ----------------------------------------------------------------------------
// Configuration options.
// ----------------------------------------------------------------------------
// Should the DBFReadStringAttribute() strip leading and trailing white space?
// ----------------------------------------------------------------------------
{$DEFINE TRIM_DBF_WHITESPACE}
// ----------------------------------------------------------------------------
// Should we write measure values to the Multipatch object?
// Reportedly ArcView crashes if we do write it, so for now it is disabled.
// ----------------------------------------------------------------------------
{$DEFINE DISABLE_MULTIPATCH_MEASURE}

// ----------------------------------------------------------------------------
// Shape types
// ----------------------------------------------------------------------------
Const
  SHPT_NULL           = 0;
  SHPT_POINT          = 1;  //Node
  SHPT_ARC            = 3;  //Link
  SHPT_POLYGON        = 5;
  SHPT_MULTIPOINT     = 8;
  SHPT_POINTZ         = 11;
  SHPT_ARCZ           = 13;
  SHPT_POLYGONZ       = 15;
  SHPT_MULTIPOINTZ    = 18;
  SHPT_POINTM         = 21;
  SHPT_ARCM           = 23;
  SHPT_POLYGONM       = 25;
  SHPT_MULTIPOINTM    = 28;
  SHPT_MULTIPATCH     = 31;
  
// ----------------------------------------------------------------------------
// Part types - everything but SHPT_MULTIPATCH just uses SHPP_RING.
// ----------------------------------------------------------------------------
  SHPP_TRISTRIP      = 0;
  SHPP_TRIFAN        = 1;
  SHPP_OUTERRING     = 2;
  SHPP_INNERRING     = 3;
  SHPP_FIRSTRING     = 4;
  SHPP_RING          = 5;

Type
// ----------------------------------------------------------------------------
// SHPObject - represents a shape (without attributes) read from the .shp file.
// -1 is unknown/unassigned
// ----------------------------------------------------------------------------
  PShpObject = ^ShpObject;
  ShpObject = Record
    nSHPType:      Integer;
    nShapeId:      Integer;
    nParts:        Integer;
    panPartStart:  Array of Integer;
    panPartType:   Array of Integer;
    nVertices:     Integer;
    padfX:         Array Of Double;
    padfY:         Array Of Double;
    padfZ:         Array Of Double;
    padfM:         Array Of Double;
    dfXMin:        Double;
    dfYMin:        Double;
    dfZMin:        Double;
    dfMMin:        Double;
    dfXMax:        Double;
    dfYMax:        Double;
    dfZMax:        Double;
    dfMMax:        Double;
  End;

// ----------------------------------------------------------------------------
// Shape Handle
// ----------------------------------------------------------------------------
  SHPInfo = array[0..231] of Byte;
  SHPHandle = ^SHPInfo;

// ----------------------------------------------------------------------------
// SHP API Prototypes
// ----------------------------------------------------------------------------
Function SHPOpen
         (pszShapeFile:PChar; pszAccess:PChar): SHPHandle; cdecl; external LibName;

Procedure SHPGetInfo
          (hSHP: SHPHandle; var nEntities: Integer; var nShapeType: Integer;
           padfMinBound: PDouble; padfMaxBound: PDouble); cdecl; external LibName;

Function SHPReadObject
         (hSHP: SHPHandle; iShape: Integer): PShpObject; cdecl; external LibName;

Procedure SHPDestroyObject
          (psObject: PShpObject); cdecl; external LibName;

Procedure SHPClose
          (hSHP: SHPHandle); cdecl; external LibName;

Function SHPTypeName
         (nSHPType: Integer):PChar; cdecl; external LibName;

Function SHPPartTypeName
         (nPartType: Integer):PChar; cdecl; external LibName;

// ----------------------------------------------------------------------------
// DBF API Support
// ----------------------------------------------------------------------------

Type
  DBFInfo = array[0..215] of Byte;
  DBFHandle = ^DBFInfo;
  DBFFieldType = (FTString, FTInteger, FTDouble, FTLogical, FTDate, FTInvalid);

Const
  XBASE_FLDHDR_SZ = 32;
  XBASE_FLDNAME_LEN_READ = 11;
  XBASE_FLDNAME_LEN_WRITE = 10;
  XBASE_FLD_MAX_WIDTH = 255;

// ----------------------------------------------------------------------------
// DBF API Prototypes
// ----------------------------------------------------------------------------
  
Function DBFOpen
         (pszDBFFile:PChar; pszAccess:PChar): DBFHandle; cdecl; external LibName;

Function DBFGetFieldCount
         (psDBF: DBFHandle): Integer; cdecl; external LibName;

Function DBFGetRecordCount
         (psDBF: DBFHandle): Integer; cdecl; external LibName;

Function DBFGetFieldInfo
        (psDBF: DBFHandle; iField: Integer; pszFieldName:PChar;
         var pnWidth: Integer; var pnDecimals: Integer): DBFFieldType; cdecl; external LibName;
  
Function DBFGetFieldIndex
         (psDBF: DBFHandle; pszFieldName:PChar): Integer; cdecl; external LibName;
  
Function DBFReadIntegerAttribute
         (hDBF: DBFHandle; iShape: Integer; iField: Integer): Integer; cdecl; external LibName;
  
Function DBFReadDoubleAttribute
         (hDBF: DBFHandle; iShape: Integer; iField: Integer): Double; cdecl; external LibName;
  
Function DBFReadStringAttribute
         (hDBF: DBFHandle; iShape: Integer; iField: Integer): PChar; cdecl; external LibName;
  
Function DBFIsAttributeNULL
         (hDBF: DBFHandle; iShape: Integer; iField: Integer): Integer; cdecl; external LibName;
  
Function DBFReadTuple
         (psDBF: DBFHandle; hEntity: Integer):PChar; cdecl; external LibName;

Procedure DBFClose
          (hDBF: DBFHandle); cdecl; external LibName;

Function DBFGetNativeFieldType
         (hDBF: DBFHandle; iField: Integer): char; cdecl; external LibName;

Implementation

End.

