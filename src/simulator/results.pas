{====================================================================
 Project:      EPANET-UI
 Version:      1.0.1
 Module:       results
 Description:  retrieves the hydraulic and water quality results
               of a simulation that were saved to file
 License:      see LICENSE
 Last Updated: 03/13/2026
=====================================================================}

unit results;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, project;

var
  QualFlag:    Integer;
  TraceNode:   Integer;
  FlowFlag:    Integer;
  Nperiods:    Integer;
  Rstart:      Integer;
  Rstep:       Integer;
  Duration:    Integer;
  InitStorage: Double;  //(ft3)

  QualName  : string;
  QualUnits : string;

function  OpenOutFile(const Fname: string): TSimStatus;
procedure CloseOutFile;
function  OpenMsxOutFile(const Fname: string): TSimStatus;

function  GetNodeID(const I: Integer): string;
function  GetNodeValue(const I: Integer; const V: Integer; const T: Integer): Single;
function  GetDmndDfctValue(const I: Integer; const T: Integer): Single;
function  GetEmitterFlowValue(const I: Integer; const T: Integer): Single;
function  GetNodeLeakageValue(const I: Integer; const T: Integer): Single;
function  GetNodeMsxValue(const I: Integer; const V: Integer; const T: Integer): Single;

function  GetLinkID(const I: Integer): string;
function  GetLinkValue(const I: Integer; const V: Integer; const T: Integer): Single;
function  GetLinkLeakageValue(const I: Integer; const T: Integer): Single;
function  GetLinkEnergyValue(const I: Integer; const T: Integer): Single;
function  GetLinkMsxValue(const I: Integer; const V: Integer; const T: Integer): Single;

function  GetPumpEnergy(const I: Integer; var PumpEnergy: array of Single): Boolean;
function  GetPumpDemandCharge: Single;

function  GetQualCount: Integer;
function  GetQualName(const I: Integer): string;
function  GetQualUnits(const I: Integer): string;
procedure GetMsxSpecies;
procedure SetQualName;

function  GetTimeStr(const Period: Integer): string;
procedure GetDataOffsets;
procedure SetInitStorage;

implementation

uses
  utils, epanet2, resourcestrings;

const

//****************** EXTREMELY IMPORTANT CONSTANTS ******************
//
// These constants allow one to correctly read the results of a
// simulation saved to a binary output file by the network solver
// EPANET2.DLL.
  MagicNumber = 516114521; //File signature
  Version     = 20012;     //Solver version number
  RECORDSIZE  = 4;         //Byte size of each record
  IDSIZE      = 32;        //Size of ID strings
  NUM_NODE_VARS = 4;       //Num. of node variables reported on
  NUM_LINK_VARS = 8;       //Num. of link variables reported on

// These are the numbers of additional node/link variables
// saved to the simulator's binary Demands file.
  NUM_NODE_AUX_VARS = 3;   //Num. of auxilary node variables reported
  NUM_LINK_AUX_VARS = 2;   //Num. of auxilary link variables reported
//*******************************************************************

var
  Fout       : TFileStream;
  Fout2      : TFileStream;
  Fmsx       : TFileStream;
  Offset1    : Int64;       //File position where ID names begin
  Offset2    : Int64;       //File position where pump energy results begin
  Offset3    : Int64;       //File position where time series results begin
  MsxOffset  : Int64;
  BlockSize1 : Int64;
  BlockSize2 : Int64;
  BlockSize3 : Int64;
  BlockSize4 : Int64;
  Nlinks     : Integer;
  Npumps     : Integer;
  Nnodes     : Integer;
  MsxCount   : Integer;
  MsxSpecies : TStringList;
  MsxUnits   : TStringList;

function OpenOutFile(const Fname: string): TSimStatus;
var
  mfirst: Integer = 0;
  mlast:  Integer = 0;
  v:      Integer = 0;
  w:      Integer = 0;
begin
  // Initialize single species water quality parameters
  QualName := '';
  QualUnits := '';

  // Open binary output file & check for minimum size
  Result := ssError;
  Fout := TFileStream.Create(fname, fmOpenRead);
  if (Fout = nil)
  or (Fout.Size/RECORDSIZE < 21) then
  begin
    Result := ssError;
    CloseOutFile;
    exit;
  end;

  // Read # time periods, warning flag & magic number at end of file
  Fout.Seek(-3*RECORDSIZE, soEnd);
  Fout.Read(Nperiods, RECORDSIZE);
  Fout.Read(w, RECORDSIZE);
  Fout.Read(mlast, RECORDSIZE);

  // Read magic number & version number from start of file
  Fout.Seek(0, soBeginning);
  Fout.Read(mfirst, RECORDSIZE);
  Fout.Read(v, RECORDSIZE);

  // Check if EPANET run was completed
  if mlast <> MagicNumber then
    Result := ssError

  // Ckeck if results saved for 1 or more time periods
  else if Nperiods <= 0 then
    Result := ssError

  // Check if correct version of EPANET was used
  else if (mfirst <> MagicNumber)
  or (v <> Version) then
    Result := ssWrongVersion

  // Check if warning messages were generated
  else if w <> 0 then
    Result := ssWarning
  else
    Result := ssSuccess;

  // Close file if run was unsuccessful
  if Result in [ssFailed, ssWrongVersion, ssError] then CloseOutFile

  // Otherwise process file and open the secondary output file
  else
  begin
    SetQualName;
    GetDataOffsets;
    project.OutFileOpened := true;
    Fout2 := TFileStream.Create(project.OutFile2, fmOpenRead);
    project.OutFile2Opened := (Fout2 <> nil) and (Fout2.Size > 0);
  end;
end;

procedure GetDataOffsets;
var
  Ntanks:  Integer = 0;
  Nvalves: Integer = 0;
  dummy1:  Integer = 0;
  dummy2:  Integer = 0;
begin
  // Read number of network components
  Fout.Read(Nnodes, RECORDSIZE);
  Fout.Read(Ntanks, RECORDSIZE);
  Fout.Read(Nlinks, RECORDSIZE);
  Fout.Read(Npumps, RECORDSIZE);
  Fout.Read(Nvalves, RECORDSIZE);

  // Read other network data
  Fout.Read(QualFlag, RECORDSIZE);
  Fout.Read(TraceNode, RECORDSIZE);
  Fout.Read(FlowFlag, RECORDSIZE);
  Fout.Read(dummy1, RECORDSIZE);
  Fout.Read(dummy2,  RECORDSIZE);
  Fout.Read(Rstart, RECORDSIZE);
  Fout.Read(Rstep, RECORDSIZE);
  Fout.Read(Duration, RECORDSIZE);

  // File offset to where object ID names begin
  Offset1 := 15*RECORDSIZE           //Integer parameters
             + 3*80                  //Title lines
             + 2*260                 //File names
             + 2*IDSIZE;             //WQ parameter & units

  // File offset to where energy usage results begin
  Offset2 := Offset1 +
             + Nnodes*IDSIZE         //Node ID labels
             + Nlinks*IDSIZE         //Link ID labels
             + 3*Nlinks*RECORDSIZE   //Link end nodes & types
             + 2*Ntanks*RECORDSIZE   //Tank node indexes & x-areas
             + Nnodes*RECORDSIZE     //Node elevations
             + 2*Nlinks*RECORDSIZE;  //Link lengths & diameters

  // File offset to where network results for each time period begin
  Offset3 := Offset2
             + (7*Npumps+1)*RECORDSIZE; //Pump energy usage
  BlockSize1 := RECORDSIZE * (Nnodes * NUM_NODE_VARS + Nlinks * NUM_LINK_VARS);
  BlockSize2 := RECORDSIZE * Nnodes * NUM_NODE_VARS;
  BlockSize3 := RECORDSIZE * (Nnodes * NUM_NODE_AUX_VARS + Nlinks * NUM_LINK_AUX_VARS);
  BlockSize4 := RECORDSIZE * Nnodes * NUM_NODE_AUX_VARS;
end;

procedure SetInitStorage;
var
  I: Integer;
  V: Single = 0;
begin
  InitStorage := 0;
  for I := 1 to project.GetItemCount(ctNodes) do
  begin
    if project.GetNodeType(I) = ntTank then
    begin
      ENgetnodevalue(I, EN_INITVOLUME, V);
      InitStorage := InitStorage + V;
    end;
  end;
  // Convert cubic meters to cubic feet
  if project.GetUnitsSystem = usSI then
    InitStorage := InitStorage * 35.31467;
end;

function  OpenMsxOutFile(const Fname: string): TSimStatus;
var
  mfirst: Longint = 0;
  mlast:  Longint = 0;
  np:     Longint = 0;
  v:      Longint = 0;
  e:      Longint = 0;
  offset: Longint = 0;
begin
  // Open binary output file & check for minimum size
  Result := ssSuccess;
  MsxCount := 0;
  if not Assigned(MsxSpecies) then MsxSpecies := TStringList.Create;
  if not Assigned(MsxUnits) then MsxUnits := TStringList.Create;
  Fmsx := TFileStream.Create(Fname, fmOpenRead);
  if (Fmsx = nil)
  or (Fmsx.Size/RECORDSIZE < 6) then
  begin
    Result := ssError;
    CloseOutFile;
    exit;
  end;

  // Check for records at end of file
  Fmsx.Seek(-4*RecordSize, soEnd);
  Fmsx.Read(offset, sizeOf(offset));
  MsxOffset := offset;
  Fmsx.Read(np, SizeOf(np));
  Fmsx.Read(e, SizeOf(e));
  Fmsx.Read(mlast, SizeOf(mlast));

  // Read magic number & version number from start of file
  Fmsx.Seek(0, soBeginning);
  Fmsx.Read(mfirst, SizeOf(mfirst));
  Fmsx.Read(v, SizeOf(v));

  // Check if MSX run was completed
  if mlast <> MagicNumber then
  begin
    Result := ssError;
  end

  // Ckeck if number time periods matches Epanet result
  else if np <> Nperiods then
  begin
    Result := ssError;
  end

  // Check if file has correct magic number
  else if (mfirst <> MagicNumber) then
  begin
    Result := ssWrongVersion;
  end

  // Check if error messages were generated
  else if e <> 0 then
  begin
    Result := ssError;
  end;

  // Close file if run was unsuccessful
  if Result in [ssFailed, ssWrongVersion, ssError] then
    CloseOutFile
  else
  begin
    project.MsxFileOpened := true;
    GetMsxSpecies;
  end;
end;

procedure GetMsxSpecies;
var
  n:   Integer = 0;
  len: Integer = 0;
  S:   string;
  Buf: array[0..1024] of Char = '';
begin
  // Continue reading from MSX output file
  Fmsx.Read(n, Sizeof(n));  // # nodes
  Fmsx.Read(n, Sizeof(n));  // # links
  Fmsx.Read(n, Sizeof(n));  // # species
  QualFlag := n;
  MsxCount := n;
  Fmsx.Read(n, Sizeof(n));  // report step

  // Read name of each specie
  for n := 1 to MsxCount do
  begin
    Fmsx.Read(len, SizeOf(len));  //read #chars in name
    Fmsx.Read(buf, len);          //read name into buffer
    SetString(s, buf, len);       //convert buffer to string
    MsxSpecies.Add(s);            //add name to list
    Fmsx.Read(buf, 16);           //read units into buffer (fixed at 16 chars)
    SetString(s, buf, 16);        //convert buffer to string
    s := Trim(s);                 //strip off null chars
    MsxUnits.Add(s);              //add units to list
  end;
end;

function  GetNodeID(const I: Integer): string;
var
  ID: array[0..IDSIZE-1] of Char;
  P:  Int64;
begin
  ID[0] := char(0);
  P := Offset1 + (I - 1) * IDSIZE;
  Fout.Seek(P, soBeginning);
  Fout.Read(ID, IDSIZE);
  Result := string(ID);
  Result := Trim(Result);
end;

function  GetLinkID(const I: Integer): string;
var
  ID: array[0..IDSIZE-1] of Char;
  P:  Int64;
begin
  ID[0] := char(0);
  P := Offset1 + (Nnodes + I - 1) * IDSIZE;
  Fout.Seek(P, soBeginning);
  Fout.Read(ID, IDSIZE);
  Result := string(ID);
  Result := Trim(Result);
end;

function  GetNodeValue(const I: Integer; const V: Integer; const T: Integer): Single;
//
// I = node index (1 to Nnodes)
// V = index of variable in output file
// T = time period (0 to Nperiods - 1)
//
var
  P: Int64;
begin
  Result := 0;
  P := Offset3 + T * BlockSize1 + (V * Nnodes + (I-1)) * RECORDSIZE;
  Fout.Seek(P, soBeginning);
  Fout.Read(Result, RECORDSIZE);
end;

function  GetDmndDfctValue(const I: Integer; const T: Integer): Single;
var
  P: Int64;
begin
  Result := 0;
  if Fout2 = nil then exit;
  P := (T * BlockSize3) + ((I - 1) * RECORDSIZE);
  Fout2.Seek(P, soBeginning);
  Fout2.Read(Result, RECORDSIZE);
end;

function  GetEmitterFlowValue(const I: Integer; const T: Integer): Single;
var
  P: Int64;
begin
  Result := 0;
  if Fout2 = nil then exit;
  P := (T * BlockSize3) + ((Nnodes + I - 1) * RECORDSIZE);
  Fout2.Seek(P, soBeginning);
  Fout2.Read(Result, RECORDSIZE);
end;

function  GetNodeLeakageValue(const I: Integer; const T: Integer): Single;
var
  P: Int64;
begin
  Result := 0;
  if Fout2 = nil then exit;
  P := (T * BlockSize3) + ((2*Nnodes + I - 1) * RECORDSIZE);
  Fout2.Seek(P, soBeginning);
  Fout2.Read(Result, RECORDSIZE);
end;

function  GetLinkLeakageValue(const I: Integer; const T: Integer): Single;
var
  P: Int64;
begin
  Result := 0;
  if Fout2 = nil then exit;
  P := (T * BlockSize3) + BlockSize4 + ((I - 1) * RECORDSIZE);
  Fout2.Seek(P, soBeginning);
  Fout2.Read(Result, RECORDSIZE);
end;

function  GetLinkEnergyValue(const I: Integer; const T: Integer): Single;
var
  P: Int64;
begin
  Result := 0;
  if Fout2 = nil then exit;
  P := (T * BlockSize3) + BlockSize4 + ((Nlinks + I - 1) * RECORDSIZE);
  Fout2.Seek(P, soBeginning);
  Fout2.Read(Result, RECORDSIZE);
end;

function  GetNodeMsxValue(const I: Integer; const V: Integer; const T: Integer): Single;
//
// I = node index (1 to Nnodes)
// V = index of variable in MSX output file (0 to MsxCount - 1)
// T = time period (0 to Nperiods - 1)
//
var
  P: Int64;
begin
  Result := 0;
  P := MsxOffset +                               //Start of MSX results
       T*RECORDSIZE*(Nnodes + Nlinks)*MsxCount + //Results from prior periods
       V*Nnodes*RECORDSIZE +                     //Results for prior species
       (I-1)*RECORDSIZE;                         //Results for prior nodes
  Fmsx.Seek(P, soBeginning);
  Fmsx.Read(Result, SizeOf(Single));
end;

function  GetLinkValue(const I: Integer; const V: Integer; const T: Integer): Single;
//
// I = link index (1 to Nlinks)
// V = variable index (0 to NUM_LINK_VARS -1)
// T = time period (0 to Nperiods - 1)
//
var
  P: Int64;
begin
  Result := 0;
  P := Offset3 + T * BlockSize1 + BlockSize2 + (V * Nlinks + (I-1)) * RECORDSIZE;
  Fout.Seek(P, soBeginning);
  Fout.Read(Result, RECORDSIZE);
end;

function  GetLinkMsxValue(const I: Integer; const V: Integer; const T: Integer): Single;
//
// I = node index (1 to Nnodes)
// V = index of variable in MSX output file (0 to MsxCount - 1)
// T = time period (0 to Nperiods - 1)
//
var
  P: Int64;
begin
  Result := 0;
  P := MsxOffset +                               //Start of MSX results
       T*RECORDSIZE*(Nnodes + Nlinks)*MsxCount + //Results from prior periods
       Nnodes*MsxCount*RECORDSIZE +              //Results for nodes
       V*Nlinks*RECORDSIZE +                     //Results for prior species
       (I-1)*RECORDSIZE;                         //Results for prior links
  Fmsx.Seek(P, soBeginning);
  Fmsx.Read(Result, SizeOf(Single));
end;

function GetPumpEnergy(const I: Integer; var PumpEnergy: array of Single): Boolean;
//
// I = link index (1 to Nlinks)
// PumpEnergy = array of 6 energy usage statistics
//
var
  J: Integer;
  K: Integer = 0;
begin
  Result := true;
  Fout.Seek(Offset2, soBeginning);
  for J := 1 to Npumps do
  begin
    Fout.Read(K, RECORDSIZE);
    Fout.Read(PumpEnergy, 6 * RECORDSIZE);
    if K = I then exit;
  end;
  Result := false;
end;

function  GetPumpDemandCharge: Single;
var
  P: Int64;
begin
  Result := 0;
  P := Offset2 + (7 * Npumps) * RECORDSIZE;
  Fout.Seek(P, soBeginning);
  Fout.Read(Result, RECORDSIZE);
end;

function  GetTimeStr(const Period: Integer): string;
var
  Seconds: Integer;
begin
  Seconds := (Period * Rstep) + Rstart;
  Result := utils.Time2Str(Seconds) + ' ' + rsHrs;
end;

function  GetQualCount: Integer;
begin
  Result := 0;
  if MsxFlag then
    Result := MsxCount
  else if QualFlag > 0 then
    Result := 1;
end;

function  GetQualName(const I: Integer): string;
begin
  Result := '';
  if MsxFlag then
  begin
    if project.MsxFileOpened then
      Result := MsxSpecies[I];
  end
  else if project.OutFileOpened then
    Result := QualName;
end;

function GetQualUnits(const I: Integer): string;
begin
  Result := '';
  if MsxFlag then
  begin
    if project.MsxFileOpened then
      Result := MsxUnits[I];
  end
  else if project.OutFileOpened then
    Result := QualUnits;
end;

procedure SetQualName;
var
  QualType:   Integer = 0;
  ChemName:   array[0..EN_MAXID] of AnsiChar = '';
  Units:      array[0..EN_MAXID] of AnsiChar = '';
  TraceNode:  Integer = 0;
begin
  QualType := project.qtNone;
  if epanet2.ENgetqualinfo(QualType, ChemName, Units, TraceNode) > 0 then
    exit;
  if QualType = project.qtChem then
  begin
    QualName := string(ChemName);
    QualUnits := string(Units);
  end
  else if QualType = project.qtAge then
  begin
    QualName := rsWaterAge;
    QualUnits := rsHours;
  end
  else if QualType = project.qtTrace then
  begin
    QualName := rsTrace + ' ';
    if TraceNode > 0 then
      QualName := QualName + project.GetID(ctNodes, TraceNode);
    QualUnits := rsPcntSymbol;
  end;
end;

procedure CloseOutFile;
//
// Closes binary output results files.
//
begin
  FreeAndNil(Fout);
  FreeAndNil(Fout2);
  FreeAndNil(Fmsx);
  FreeAndNil(MsxSpecies);
  FreeAndNil(MsxUnits);
  project.OutFileOpened := false;
  project.OutFile2Opened := false;
  project.MsxFileOpened := false;
end;

end.

