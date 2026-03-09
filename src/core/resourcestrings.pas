{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       resourcestrings
 Description:  contains text for internationalizing all project strings
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit resourcestrings;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils;

resourcestring
  // main.pas
  rsSelectInpFile = 'Select an EPANET Input File';
  rsFileNoExists  = 'Input file no longer exists.';
  rsInpFileOpen   = 'EPANET INP Files|*.inp|All Files|*.*';
  rsSaveChanges   = 'Save changes made to current project?';
  rsSaveMsxChanges = 'Save changes made to Multi-Species data?';
  rsAutoLengthOff = 'Auto-Length: Off';
  rsAutoLengthOn  = 'Auto-Length: On';
  rsFlowUnitsType = 'Flow:';
  rsPressUnitsType = 'Pressure:';                                 
  rsHlossType     = 'Head Loss:';
  rsDemandsDDA    = 'Demands: DDA';
  rsQualityNone   = 'Quality: None';
  rsNoResults     = 'No Results';
  rsXY            = '   X,Y:';
  rsDemands       = 'Demands:';
  rsQuality       = 'Quality:';
  rsFoot          = 'ft';
  rsMeter         = 'm';
  rsBasemap       = 'Basemap';
  rsLoadingFile   = 'Loading project file ...';
  rsLoadErrors    = 'There were errors found in the project file that ' +
                    'may have prevented all data from being loaded. ' +
                    LineEnding + LineEnding +
                    'Check the Status Report for details.';
  rsNoLoadProject = 'Could not load project file.';

  // filemenu.pas
  rsExitMenu      = '  Exit this menu.';
  rsNewProject    = '  Start a new project.';
  rsOpenProject   = '  Open a previously saved project.';
  rsSaveProject   = '  Save the project under its current name.';
  rsSaveProjectAs = '  Save the project under a new name.';
  rsImportData    = '  Import project data in other formats.';
  rsConfigure     = '  Configure program settings.';
  rsExitProgram   = '  Exit the program.';
  rsImport        = 'Import';
  rsOpen          = 'Open';
  rsRecentProj    = ' Recent Projects';
  rsImportFrom    = ' Import Network Data From';

  // menuframe.pas
  rsShapingLink   = 'Reshaping a Link';
  rsToShapeLink   = 'Left-click on a vertex to select it.' +
                    LineEnding + ' ' + LineEnding +
                    'With the Ctrl key pressed, drag' + LineEnding +
                    'it to a new location using ' + LineEnding +
                    'the mouse or the arrow keys.' +
                    LineEnding + ' ' + LineEnding +
                    'Press Insert to add a new vertex.' + LineEnding +
                    'Press Delete to delete a vertex.' + LineEnding +
                    'Shift-Delete deletes all vertices.' + LineEnding + LineEnding +
                    'Press Escape to quit editing.';
  rsGroupSelect   = 'Group Selection';
  rsToGroupSelect = 'Press Enter to select the entire' + LineEnding +
                    'network or draw a polygon' + LineEnding +
                    'that encloses the objects' + LineEnding +
                    'to be selected.' + LineEnding + ' ' + LineEnding +
                    'Left-click at each polygon vertex.' + LineEnding +
                    'Right-click to close the polygon.' + LineEnding +
                    'Press Escape to cancel.';
  rsAddNode       = 'To Add a Node:';
  rsToAddNode     = 'Move the pointer to the location of the new node ' +
                    'and left-click. ' + LineEnding + ' ' + LineEnding +
                    'Repeat to add more nodes.' + LineEnding + ' ' +LineEnding +
                    'Press Escape or right-click to exit.';
  rsAddLink       = 'To Add a Link:';
  rsToAddLink     = 'Left-click on the start node of the link, move the ' +
                    'pointer to the end node and left-click again.' +
                    LineEnding + ' ' + LineEnding + 'Left-click at ' +
                    'intermediate points to shape the link. ' + LineEnding +
                    ' ' + LineEnding +
                    'Repeat to add more links.' + LineEnding + ' ' + LineEnding +
                    'Press Escape or right-click to exit.';
  rsAddLabel      = 'To Add a Label:';
  rsToAddLabel    = 'Left-click at the label''s location.' + LineEnding + ' ' +
                    LineEnding + 'Type in the label''s text and press Enter.' +
                    LineEnding + ' ' + LineEnding +
                    'Repeat to add more labels.' + LineEnding + ' ' +LineEnding +
                    'Press Escape to exit.';
  rsResultsCurrent= 'Results are Current';
  rsNoPumps       = 'There are no pumps with results to report on.';
  rsTime          = 'Time: ';
  rsHrs           = 'hrs';
  rsThemesAre     = 'Themes are ';

  // basemapmenu.pas
  rsCheckInternet = 'Checking internet connection ...';
  rsNoInternet    = 'There is no internet connection.';
  rsEpsgHelp      = '<p><b>CRS EPSG</b></p>' +
                    '<p>New projects that utilize an internet basemap will '+
                    'be assigned geographic coordinates (latitude, longitude; '+
                    'EPSG:4326) by default. If an existing project uses some '+
                    'other coordinate reference system, such as State Plane '+
                    'or UTM, then its EPSG code must be provided so that the '+
                    'network map can be displayed correctly over the basemap.</p>' +
                    '<p>EPSG codes for different Coordinate Reference ' +
                    'Systems can be found ' +
                    '<a href="https://spatialreference.org/">here</a>.</p>';

  // curveeditor.pas
  rsWishToDelete  = 'Do you wish to delete %s %s ?';
  rsBlank         = '<blank>';
  rsDepth         = 'Depth';
  rsFlow          = 'Flow';
  rsX             = 'X';
  rsPcntOpen      = '% Open';
  rsVolume        = 'Volume';
  rsHead          = 'Head';
  rsEfficiency    = 'Efficiency';
  rsHead_Loss     = 'Head Loss';
  rsY             = 'Y';
  rsPcntFullFlow  = '% Full Flow';
  rsDataCurveEdit = 'Data Curve Editor';
  rsCurveNodata   = 'Curve has no data points.';
  rsInvalidCurve  = 'Invalid curve data - X values must be in ascending order.';
  rsNoAddCurve    = 'Unable to add a new curve.';

  // demandseditor.pas
  rsDemandCategories = 'Demand Categories for Junction ';
  rsInvalidDemand    = 'Invalid Demand value in row ';
  rsInvalidPattern   = 'Invalid Pattern name in row ';

  // patterneditor.pas
  rsPatternFiles  = 'Pattern files (*.PAT)|*.PAT|All files|*.*';
  rsPatternHeader = 'EPANET Pattern Data';
  rsPeriod        = 'Period';
  rsMultiplier    = 'Multiplier';
  rsNoAddPattern  = 'Unable to add a new pattern.';
  rsInvalidNumber = ' is not a valid number.';
  rsTimePeriod    = 'Time (Time Period = ';
  rsClearAll      = 'Do you wish to clear all pattern multipliers?';

  // qualeditor.pas
  rsChemHint      = 'Optional name of the chemical to analyze.';
  rsTraceHint     = 'ID name of the node to trace from.';
  rsConstitName   = 'Constituent Name';
  rsAge           = 'Age';
  rsHours         = 'Hours';
  rsTraceFrom     = 'Node to Trace From';
  rsPercent       = 'Percent';
  rsNoTraceNode   = 'Tracing source node does not exist.';
  rsChemical      = 'Chemical';
  rsNoQualOptions = 'Was not able to set water quality options.';

  // ruleseditor.pas
  rsMissingID     = 'Missing Rule ID';
  rsNoIDAssigned  = 'A valid rule must have an ID name assigned to it.';
  rsRuleError     = 'Error %d occurred in Rule %s.' + LineEnding + LineEnding +
                    'Continue editing.';

  // sourceeditor.pas
  rsNoPattern     = 'Pattern %s does not exist.';

  // validator.pas
  rsNoNode        = 'Node %s does not exist.';
  rsBadServPress  = 'Service pressure must be greater than minimum pressure.';
  rsBadMinPress   = 'Minimum pressure must be less than service pressure.';
  rsBadTime       = 'Invalid time value.';
  rsDecimalTime   = 'Use decimal values for durations >= 24 hrs.';
  rsBadEfficiency = ' is not a valid efficiency value.';
  rsNegativeValue = 'Value less than 0 not allowed.';
  rsBadTankLevels = 'Inconsistent tank levels.';
  rsNoCurve       = 'Curve %s does not exist.';
  rsBadMixModel   = 'Invalid mixing model.';
  rsBadValue      = 'Value <= 0 not allowed.';
  rsBadTankConnect= 'Illegal connection of a %s to a Tank.';
  rsBadValveConnect = 'Illegal connection of a %s to another valve.';
  rsBadRotation   = 'Rotation must be between 0 and 360.';

  // groupeditor.pas
  rsJuncParams    = 'Tag'#13'Elevation'#13'Base Demand'#13'Demand Pattern'#13+
                    'Emitter Coeff.'#13'Initial Quality';
  rsPipeParams    = 'Tag'#13'Diameter'#13'Length'#13'Roughness'#13'Loss Coeff.'#13 +
                    'Bulk Coeff.'#13'Wall Coeff.'#13'Leak Area'#13'Leak Expansion';
  rsFilters       = 'Below'#13'Equal To'#13'Above';
  rsActions       = 'Replace'#13'Multiply'#13'Add To';
  rsBadPattern    = 'Invalid Patten ID';
  rsBadNumber     = 'Invalid number.';
  rsBadTag        = 'Tags cannot contain spaces or semi-colons.';
  rsWith          = 'with';
  rsBy            = 'by';
  rsNoMatches     = 'No objects match your criteria';
  rsObjsModified  = 'object(s) have been modified.';
  rsMoreEdits     = 'Do you wish to make more edits?';
  rsNoSelect      = 'No objects were selected for editing';
  rsDeleteAll     = 'Do you wish to delete all objects in the selected region?';

  // controledit.pas
  rsNoLink        = 'Link %s does not exist.';
  rsBadSetting    = 'Invalid link setting.';
  rsBadNodeLevel  = 'Invalid node level.';
  rsBadTimeValue  = 'Invalid time value.';

  // dxfimporter.pas
  rsDxfIntro      = 'The following pages will step you' + LineEnding + ' ' +
                    LineEnding + 'through the process of importing' +
                    LineEnding + ' ' + LineEnding + 'a CAD network drawing ' +
                    'stored in' + LineEnding + ' ' + LineEnding +
                    'a DXF file into EPANET-UI.';
  rsSelectLayers  = 'Please select one or more layers.';
  rsSelectDxfFile = 'Select a DXF File';
  rsDxfFiles      = 'DXF Files|*.dxf';

  // shpimporter.pas
  rsShpIntro      = 'The following pages will step you' + LineEnding + ' ' +
                    LineEnding + 'through the process of importing' +
                    LineEnding + ' ' + LineEnding + 'georeferenced node ' +
                    'and link data' +  LineEnding + ' ' + LineEnding +
                    'from GIS shapefiles into EPANET-UI.';
  rsShpLinkProp   = 'Link Property';
  rsShpNodeProp   = 'Node Property';
  rsShpPanel3Text = 'Select a shapefile containing georeferenced link data ' +
                    'and assign its attributes to their corresponding ' +
                    'EPANET link properties. Properties with no assigned ' +
                    'attribute will have default values. Skip this page '+
                    'if no link data will be imported.';
  rsShpPanel6Text = 'Select a shapefile containing georeferenced node data ' +
                    'and assign its attributes to their corresponding ' +
                    'EPANET node properties. Properties with no assigned ' +
                    'attribute will have default values. Skip this page '+
                    'if no node data will be imported.';
  rsShpPanel10Text= 'A preview of the imported network layout is displayed ' +
                    'below. Click the Import button to begin importing data ' +
                    'from the selected shapefiles into the project.';
  rsNoProjData    = 'No projection data were found.' + LineEnding +
                    'Would you like to search yourself?';
  rsSelectProjFile= 'Select a Projection File';
  rsLinksShpFile  = 'Select a Links Shape File';
  rsNodesShpFile  = 'Select a Nodes Shape File';
  rsProjFiles     = 'Projection Files|*.prj';
  rsShpFiles      = 'Shape Files|*.shp';
  rsNotShpFile    = 'File is not a valid shape file.';
  rsNotLinkFile   = 'File does not contain link data.';
  rsNotNodeFile   = 'File does not contain node data.';
  rsProjData      = 'The following projection data were found:' + LineEnding +
                    'EPSG: %s' + LineEnding + 'Units: %s' + LineEnding +
                    LineEnding + 'Do you wish to use these?';
  rsAccept        = 'Accept';
  rsFeet          = 'feet';
  rsMeters        = 'meters';

  // shpviewer.pas
  rsShapeAttrib   = 'Shape File Attribute Table';
  rsNoShapeAttrib = 'Could not open shapefile attribute file.';
  rsProjParams    = 'Projection Parameters';

  // shploader.pas
  rsNoShpTrans    = 'Unable to transform shapefile coordinates to project '+
                    'coodinates.' + LineEnding + LineEnding +
                    'Please make sure you have an internet connection ' +
                    'and the correct EPSG code.';

  // csvimporter.pas
  rsCsvIntro      = 'The following pages will step you' +
                    LineEnding + ' ' + LineEnding +
                    'through the process of importing' +
                    LineEnding + ' ' + LineEnding +
                    'network node and pipe data from' +
                    LineEnding + ' ' + LineEnding +
                    'comma separated value (CSV)' +
                    LineEnding + ' ' + LineEnding +
                    'text files whose first line' +
                    LineEnding + ' ' + LineEnding +
                    'contains data field names.';
  rsCsvPanel4Text = 'Select a CSV text file containing network node data ' +
                    'and assign its column headings to their corresponding ' +
                    'EPANET node properties. Specify units if they differ ' +
                    'from the project''s units. Skip this page if no node ' +
                    'data will be imported.';
  rsCsvPanel3Text = 'Select a CSV text file containing network pipe data and ' +
                    'assign its column headings to their corresponding ' +
                    'EPANET pipe properties. Specify units if they differ ' +
                    'from the project''s units. Skip this page if no pipe ' +
                    'data will be imported.';
  rsCsvPipeProp   = 'EPANET Pipe Property';
  rsCsvNodeProp   = 'EPANET Node Property';
  rsPipeUnits     = ' ,feet,meters,inches,millimeters,millifeet,1/hrs,1/days';
  rsNodeUnits     = ' ,feet,meters,cfs,gpm,mgd,imgd,afd,lps,lpm,mld,cmh,' +
                    'cmd,cms,gpm/psi,lps/m,mg/L,ug/L';
  rsCsvProperty   = 'EPANET Property';
  rsCsvFileColumn = 'CSV File Column';
  rsCsvFiles      = 'CSV Files|*.csv';
  rsNodesCsvFile  = 'Select a Nodes CSV File';
  rsPipesCsvFile  = 'Select a Pipes CSV File';

  // csvviewer.pas
  rsNoCsvDisplay  = 'Unable to display CSV file.';

  // mapframe.pas
  rsNodes         = 'Nodes';
  rsJunctions     = 'Junctions';
  rsNoLoadImage   = 'Was not able to load the image file.';
  rsNoTransform   = 'Could not transform EPSG %d coordinates for basemap viewing.' +
                    LineEnding + LineEnding +'Make sure you specify the ' +
                    'correct EPSG code for your network.';
  rsInDegrees     = 'Map coordinates must be in decimal degrees.';
  rsEmptyNetworks = 'This feature is only available for empty networks.';

  // mapoptions.pas
  rsWhite         = 'White';
  rsCream         = 'Cream';
  rsYellow        = 'Yellow';
  rsGreen         = 'Green';
  rsCyan          = 'Cyan';
  rsGray          = 'Gray';
  rsBlue          = 'Blue';
  rsBlack         = 'Black';

  // webmapfinder.pas
  rsNoFind        = 'Could not find';
  rsNoConnect     = 'Unable to connect to server.';

  // mapgeoref.pas
  rsWorldXPix     = 'World X / Pixel';
  rsWorldYPix     = 'World Y / Pixel';
  rsTopLeftX      = 'Top Left X';
  rsTopLeftY      = 'Top Left Y';
  rsLowLeftX      = 'Lower Left X';
  rsLowLeftY      = 'Lower Left Y';
  rsUpRightX      = 'Upper Right X';
  rsUpRightY      = 'Upper Right Y';
  rsNext          = 'Next';
  rsBadDistance   = 'Distance must be > 0.';
  rsTwoPtsNeeded  = 'Two control points must be selected.';
  rsSamePts       = 'Both control points cannot be the same.';
  rsNoThirdPt     = 'No 3rd control point was selected.';
  rsWorldFile     = 'World File|*.wld|JPG World File|*.jgw|' +
                    'PNG World File|*.pgw|All Files|*.*';
  rsNoWorldFile   = 'Could not read World file.';
  rsBadExtents    = 'Basemap extents are invalid.';

  // maplocater.pas
  rsNoSuchObject   = 'There is no such object in the project.';
  rsNoObjectType   = 'There are no objects of that type in the project.';
  rsAdjacentLinks  = 'Adjacent Links';
  rsAdjacentNodes  = 'Adjacent Nodes';
  rsTankNodes      = 'Tank Nodes';
  rsReservNodes    = 'Reservoir Nodes';
  rsWQSourceNodes  = 'WQ Source Nodes';
  rsPumpLinks      = 'Pump Links';
  rsValveLinks     = 'Valve Links';

  // mapquery.pas
  rsItemsFound    = 'items found.';

  // mapalign.pas
  rsManualAlign   = 'You must manually align three nodes';
  rsNoAlign       = 'Unable to solve for alignment coefficients.';
  rsNode          = 'Node';
  rsNewLocation   = 'New Location';

  // project.pas
  rsCFS           = 'cfs';
  rsGPM           = 'gpm';
  rsMGD           = 'mgd';
  rsIMGD          = 'imgd';
  rsAFD           = 'afd';
  rsLPS           = 'lps';
  rsLPM           = 'lpm';
  rsMLD           = 'mld';
  rsCMH           = 'cmh';
  rsCMD           = 'cmd';
  rsCMS           = 'cms';

  rsPsi           = 'psi';
  rsKpa           = 'kPa';
  rsBar           = 'bar';

  rsHW            = 'H-W';
  rsDW            = 'D-W';
  rsCM            = 'C-M';

  rsDDA           = 'DDA';
  rsPDA           = 'PDA';

  rsNoQuality     = 'No Quality';
  rsWaterAge      = 'Water Age';
  rsSourceTrace   = 'Source Trace';
  rsDegrees       = 'degrees';
  rsHydraulics    = 'Hydraulics';
  rsTimes         = 'Times';
  rsEnergy        = 'Energy';
  rsSimple        = 'Simple';
  rsRuleBased     = 'Rule-Based';
  rsClosed        = 'Closed';
  rsGeneric       = 'Generic';
  rsNormal        = 'Normal';
  rsFull          = 'Full';
  rsAverages      = 'Averages';
  rsMinima        = 'Minima';
  rsMaxima        = 'Maxima';
  rsRanges        = 'Ranges';
  rsNo             = 'No';
  rsYes            = 'Yes';
  rsBadID         = 'ID names cannot contain spaces or semi-colons.';
  rsBlankID       = 'ID names cannot be blank or exceed %d characters.';
  rsUsedID        = 'ID name already in use.';
  rsNoDelSource   = 'Cannot delete Node %s  because it is a source tracing node.';
  rsNoDelNode     = 'Error %d deleting Node %s';

  rsJunction      = 'Junction';
  rsReservoir     = 'Reservoir';
  rsTank          = 'Tank';
  rsPipe          = 'Pipe';
  rsPump          = 'Pump';
  rsValve         = 'Valve';
  rsPattern       = 'Pattern';
  rsCurve         = 'Curve';
  rsType          = 'Type';
  rsNeedUpdating  = 'Results Need Updating';

  // projectbuilder.pas
  rsNoAddNode     = 'Unable to add a new node.';
  rsNoAddLink     = 'Unable to add a new link.';

  // projectloader.pas
  rsLoadBasemap   = 'Loading basemap ...';

  // projectsetup.pas
  rsReservoirs    = 'Reservoirs';
  rsTanks         = 'Tanks';
  rsPipes         = 'Pipes';
  rsPumps         = 'Pumps';
  rsValves        = 'Valves';
  rsPatterns      = 'Patterns';
  rsCurves        = 'Curves';

  rsNodeElev      = 'Node Elevation';
  rsTankHeight    = 'Tank Height';
  rsTankDiam      = 'Tank Diameter';
  rsPipeLength    = 'Pipe Length';
  rsPipeDiam      = 'Pipe Diameter';
  rsPipeRough     = 'Pipe Roughness';

  rsFlowUnits     = 'Flow Units';
  rsPressUnits    = 'Pressure Units';
  rsHlossFormula  = 'Head Loss Formula';
  rsSpGrav        = 'Specific Gravity';
  rsSpViscos      = 'Specific Viscosity';
  rsMapUnits      = 'Map Units';

  rsHydOptions    = ' Project hydraulic options';
  rsIDPrefixes    = ' ID prefixes for new objects';
  rsNewObjProps   = ' Properties for new objects';
  rsMapDimensions = ' Map dimensions and units';
  rsWebDimensions = ' Map extent set by internet map provider';
  rsOptions       = 'Options';
  rsIDlabels      = 'ID Labels';
  rsProperties    = 'Properties';
  rsMap           = 'Map';

  rsObjectType    = 'Object Type';
  rsIDPrefix      = 'ID Prefix';
  rsHydOption     = 'Project Option';
  rsValue         = 'Value';
  rsObjProperty   = 'Object Property';
  rsMapProperty   = 'Map Property';

  rsBadMapCoords  = 'Map coordinates must be between -180 and 180 degrees.';
  rsUnitSystemUS  = 'Unit System (determined by Flow Units):  US';
  rsUnitSystemSI  = 'Unit System (determined by Flow Units):  SI';

  rsConfirmSetup   = 'Confirm Setup Actions';
  rsSetupChanges   = 'Setup will modify your project data as follows:';
  rsFlowConvert    = '- all flow data will be converted to ';
  rsSIConvert      = '- all other data will be converted to SI units';
  rsUSConvert      = '- all other data will be converted to US units';
  rsPressConvert   = '- all pressure data will be converted to ';
  rsHlossChanged   = 'The project''s head loss formula was changed from ';
  rsTo             = ' to ';
  rsChangeRough    = 'Select how pipe roughness should be changed:';
  rsConvertFormula = 'Use a built-in conversion formula';
  rsDefaultRough   = 'Use the default roughness value of ';
  rsNoRoughChange  = 'Do not make any roughness changes';
  rsResultsRemoved = 'Because of these changes, simulation results will be removed.';

  // projectframe.pas
  rsNA             = 'N/A';
  rsAnalysisOpts   = 'Analysis Options - ';
  rsWishToRemove   = 'Do you wish to remove ';
  rsConnectedLinks = 'and all of its connecting links';
  rsNotSameType    = 'Source and destination objects are not the same type.';
  rsTitleNotes     = '  Title / Notes';
  rsMapLabels      = ' Map Labels';

  // projectsummary.pas
  rsProjFlowUnits  = 'Flow Units';
  rsProjHlossModel = 'Head Loss Model';
  rsProjDmndModel  = 'Demand Model';
  rsProjQualModel  = 'Quality Model';
  rsProjModel      = 'Model';
  rsProjDuration   = 'Hour Duration';
  rsS              = 's';   // To make a word plural
  rsLinks          = 'Links';
  rsDataCurves     = 'Data Curves';
  rsTimePatterns   = 'Time Patterns';
  rsLinkControls   = 'Link Controls';
  rsSimpleControls = 'Simple Controls';
  rsRuleControls   = 'Rule Based Controls';

  // curveviewer.pas
  rsBadPumpCurve   = 'Cannot compute a valid pump curve.';

  // properties.pas
  rsMaxTrials      = 'Maximum Trials';
  rsAccuracy       = 'Accuracy';
  rsHeadTol        = 'Head Tolerance';
  rsFlowTol        = 'Flow Tolerance';
  rsUnbalanced     = 'If Unbalanced';
  rsStatusRpt      = 'Status Reporting';
  rsDefPattern     = 'Default Pattern';
  rsDemandMult     = 'Demand Multiplier';
  rsServicePress   = 'Service Pressure';
  rsMinPressure    = 'Minimum Pressure';
  rsPressureExpon  = 'Pressure Exponent';
  rsEmitterExpon   = 'Emitter Exponent';
  rsEmitBackFlow   = 'Emitter Backflow';

  rsSingleSpecies  = 'Single-Species';
  rsMultiSpecies   = 'Multi-Species';

  rsDuration       = 'Duration';
  rsHydStep        = 'Hydraulic Step';
  rsQualStep       = 'Quality Step';
  rsPatternStep    = 'Pattern Step';
  rsPatternStart   = 'Pattern Start';
  rsReportStep     = 'Report Step';
  rsReportStart    = 'Report Start';
  rsRuleStep       = 'Rule Step';
  rsClockStart     = 'Clock Start';
  rsStatistic      = 'Statistic';

  rsPumpEfficiency = 'Pump Efficiency (%)';
  rsEnergyprice    = 'Energy Price / kwh';
  rsPricePattern   = 'Price Pattern';
  rsDemandCharge   = 'Demand Charge';

  rsJunctionID     = 'Junction ID';
  rsDescription    = 'Description';
  rsTag            = 'Tag';
  rsElevation      = 'Elevation';
  rsBaseDemand     = 'Base Demand';
  rsDemandPattern  = 'Demand Pattern';
  rsDmndCategories = 'Demand Categories';
  rsEmitterCoeff   = 'Emitter Coeff.';
  rsInitQuality    = 'Initial Quality';
  rsSourceQuality  = 'Source Quality';
  rsTotalDemand    = 'Total Demand';
  rsDemandDeficit  = 'Demand Deficit';
  rsEmitterFlow    = 'Emitter Flow';
  rsHydraulicHead  = 'Head';
  rsPressure       = 'Pressure';
  rsReservoirID    = 'Reservoir ID';
  rsElevPattern    = 'Elev. Pattern';
  rsOutflowRate    = 'Outflow Rate';

  rsTankID         = 'Tank ID';
  rsInitialDepth   = 'Initial Depth';
  rsMinimumDepth   = 'Minimum Depth';
  rsMaximumDepth   = 'Maximum Depth';
  rsDiameter       = 'Diameter';
  rsMinimumVolume  = 'Minimum Volume';
  rsVolumeCurve    = 'Volume Curve';
  rsCanOverflow    = 'Can Overflow';
  rsMixingModel    = 'Mixing Model';
  rsMixingFraction = 'Mixing Fraction';
  rsReactionCoeff  = 'Reaction Coeff.';
  rsInflowRate     = 'Inflow Rate';
  rsWaterDepth     = 'Water Depth';

  rsPipeID         = 'Pipe ID';
  rsStartNode      = 'Start Node';
  rsEndNode        = 'End Node';
  rsLength         = 'Length';
  rsRoughness      = 'Roughness';
  rsLossCoeff      = 'Loss Coeff.';
  rsInitialStatus  = 'Initial Status';
  rsBulkCoeff      = 'Bulk Coeff.';
  rsWallCoeff      = 'Wall Coeff.';
  rsLeakArea       = 'Leak Area';
  rsLeakExpansion  = 'Leak Expansion';
  rsFlowRate       = 'Flow Rate';
  rsVelocity       = 'Velocity';
  rsHeadLoss       = 'Head Loss';
  rsLeakage        = 'Leakage';

  rsPumpID         = 'Pump ID';
  rsPumpCurve      = 'Pump Curve';
  rsPower          = 'Power';
  rsInitialSpeed   = 'Initial Speed';
  rsSpeed          = 'Speed';
  rsStatus         = 'Status';
  rsSpeedPattern   = 'Speed Pattern';
  rsEfficCurve     = 'Effic. Curve';
  rsHeadAdded      = 'Head Added';

  rsValveID        = 'Valve ID';
  rsValveType      = 'Valve Type';
  rsInitialSetting = 'Initial Setting';
  rsSetting        = 'Setting';
  rsPcvCurve       = 'PCV Curve';
  rsGpvCurve       = 'GPV Curve';
  rsFixedStatus    = 'Fixed Status';

  rsText           = 'Text';
  rsFont           = 'Font';
  rsRotation       = 'Rotation';
  rsAnchorNode     = 'Anchor Node';

  rsStop           = 'Stop';
  rsContinue       = 'Continue';
  rsEdit           = '<Edit>';

  // editor.pas
  rsSeeGpvCurve    = 'See GPV Curve';

  // chartoptions.pas
  rsTopLeft        = 'Top Left';
  rsCenterLeft     = 'Center Left';
  rsBottomLeft     = 'Bottom Left';
  rsTopCenter      = 'Top Center';
  rsBottomCenter   = 'Bottom Center';
  rsTopRight       = 'Top Right';
  rsCenterRight    = 'Center Right';
  rsBottomRight    = 'Bottom Right';
  rsSolid          = 'Solid';
  rsDash           = 'Dash';
  rsDot            = 'Dot';
  rsDashDot        = 'Dash Dot';
  rsDashDotDot     = 'Dash Dot Dot';
  rsNoPoint        = 'None';
  rsRectangle      = 'Rectangle';
  rsCircle         = 'Circle';
  rsCross          = 'Cross';
  rsDiagonalCross  = 'Diagonal Cross';
  rsStar           = 'Star';
  rsLowBracket     = 'Low Bracket';
  rsHighBracket    = 'High Bracket';
  rsLeftBracket    = 'Left Bracket';
  rsRightBracket   = 'Right Bracket';
  rsDiamond        = 'Diamond';
  rsTriangle       = 'Triangle';
  rsPanel          = 'Panel';
  rsPastelBlue     = 'Pastel Blue';
  rsPastelPurple   = 'Pastel Purple';
  rsPastelGreen    = 'Pastel Green';
  rsPastelOrange   = 'Pastel Orange';
  rsPastelRed      = 'Pastel Red';
  rsSeries         = 'Series';

  // reportviewer.pas
  rsStatusReport   = 'Status Report';
  rsPumpingReport  = 'Pumping Report';
  rsCalibReport    = 'Calibration Report';
  rsNodesReport    = 'Network Nodes Report';
  rsLinksReport    = 'Network Links Report';
  rsTseriesReport  = 'Time Series Report';
  rsProfileReport  = 'Hydraulic Profile Plot';
  rsSysFlowReport  = 'System Flow Report';
  rsEnergyReport   = 'Energy Report';
  rsVariationReport= 'Variability Report';
  rsFireFlowReport = 'Fire Flow Report';
  rsMaximize       = 'Maximize';
  rsRestore        = 'Restore';

  // statusrpt.pas
  rsTextFile       = 'Text File|*.txt|All Files|*.*';

  // sysflowrpt.pas
  rsElapsed        = 'Elapsed';
  rsOf             = 'of';
  rsDay            = 'Day';
  rsStored         = 'Stored';
  rsProduced       = 'Produced';
  rsConsumed       = 'Consumed';
  rsImageFiles     = 'PNG File|*.png|JPEG File|*.jpg|BMP File|*.bmp';
  rsMegaLiters     = 'ML';
  rsMillionGallons = 'MG';
  rsPngFile        = 'Portable Network Graphic File|*.png';

  // timeseriesrpt.pas
  rsTimeHrs        = 'Elapsed' + LineEnding + 'Time' + LineEnding +'(hrs)';
  rsTimeOfDay      = 'Time' + LineEnding + 'of' + LineEnding + 'Day';
  rsTimeSeriesRpt  = 'Time Series Report';
  rsTimeWithSpaces = 'Time      ';

  // pumpingrpt.pas
  rsPcntUtilized   = '% Utilized';
  rsAvgKw          = 'Avg. Kw';
  rsPeakKw         = 'Peak Kw';
  rsCostPerDay     = 'Cost/day';
  rsDemandCost     = 'Demand Charge: ';
  rsTotalCost      = 'Total Cost: ';
  rsKwHrsPerM3     = 'Kw-hrs/m3';
  rsKwHrsPerMgal   = 'Kw-hrs/Mgal';

  // networkrpt.pas
  rsNodeResults    = 'Node Results';
  rsLinkResults    = 'Link Results';
  rsAtTimePeriod   = ' at %s';
  rsFiltered       = 'Filtered:';
  rsUnfiltered     = 'Unfiltered:';
  rsItems          = 'items';
  rsLink           = 'Link';

  // calibrationrpt.pas
  rsCalibReportFor = 'Calibration Report for';
  rsCorrelPlot     = 'Correlation Plot for';
  rsCorrelation    = 'Correlation Between Means:';
  rsDataFile       = 'Data File|*.dat|All Files|*.*';
  rsCalibFile      = 'Calibration File|*.dat|';
  rsNodeID         = 'Node ID';
  rsLinkID         = 'Link ID';
  rsTimeInHours    = 'Time (Hrs)';
  rsFor            = 'for';
  rsCorrelCoeff    = 'Correlation Coeff. = %.2f';
  rsNoCalibData    = 'There are no calibration data to process.';
  rsNetwork        = 'Network';
  rsHeading1 = '                Num    Observed    Computed    Mean     RMS';
  rsHeading2 = '  Location      Obs        Mean        Mean   Error   Error';
  rsHeading3 = '  ---------------------------------------------------------';

  // energyrpt.pas
  rsMetricsHeading = 'Performance Metrics';
  rsHeading4       = '-------------------';
  rsMetricsText1   = 'Efficiency Index    (Ed/Es)';
  rsMetricsText2   = 'Friction Loss Index (Ef/Es)';
  rsMetricsText3   = 'Leakage Loss Index  (El/Es)';
  rsMetricsText4   = 'Excess Supply Index (Es/Em)';
  rsMetricsText5   = 'Excess Usage Index  (Ed/Em)';
  rsMetricsText6   = 'Minimum Energy (Em, %s)';
  rsToMeetDemand   = 'to meet demand at %s';
  rsMwHperDay      = 'MwH/Day';
  rsKwHperDay      = 'KwH/Day';
  rsEnergyBalance  = 'System Energy Balance';
  rsEnergySupplied = 'Total Energy Supplied (Es):   %.1f %s';
  rsEnergyConsumed = 'Total Energy Consumed:       %.1f %s';

  // pcntilerpt.pas
  rsPercentile     ='-th Percentile';
  rsThTo           = '-th to';
  rsVariationIn    = 'Variation in System';

  // hydprofilerpt.pas
  rsDistance       = 'Distance';
  rsHydProfile     = 'Hydraulic Profile';

  // profileselector.pas
  rsNotNode        = 'Selected object is not a Node.';
  rsNotLink        = 'Selected object is not a Link.';
  rsBadStartNode   = 'Start node doesn''t exist.';
  rsBadEndNode     = 'End node doesn''t exist.';
  rsNoPathFound    = 'Unable to find a connected path between start and end nodes';

  // fireflowrpt.pas
  rsFFnode     = 'Node';
  rsFFstatic   = 'Static';
  rsFFpress    = 'Pressure';
  rsFFmax      = 'Target';
  rsFFavail    = 'Available';
  rsFFflow     = 'Fire Flow';
  rsFFresid    = 'Residual';
  rsFFcritical = 'Critical';

  rsFFsum1     = '  Target Fire Flow      ';
  rsFFsum2     = '  Target Pressure       ';
  rsFFsum3     = '  Time of Day           ';
  rsFFsum4     = '  Fire Flow Set         ';
  rsFFsum5     = '  Pressure Zone Set     ';
  rsFFsum6     = '  Nodes Meeting Target  ';
  rsFFsum7     = '  Average Available Flow';

  rsFFSummary  = 'Fire Flow Analysis: Summary Results';
  rsFFDetails  = 'Fire Flow Analysis: Detailed Results';
  rsFFTextFile = 'Text File|*.txt|All Files|*.*';

  // fireflowselector.pas
  rsFireFlowSelect    = 'Fire Flow Selection';
  rsSelectByTag       = 'Select all nodes whose Tag is';
  rsNotJunction       = 'Selected object is not a Junction node.';
  rsDuplicateNode     = 'Junction has already been selected.';
  rsBadPolygon        = 'Polygon region is incomplete.';
  rsNoTagNodes        = 'There were no nodes with Tag ';
  rsAllNodesSelected  = 'All nodes selected';
  rsAllNodes          = 'All nodes';
  rsBlankEntries      = 'Blank entries are not allowed.';
  rsNoNodesSelected   = 'No nodes were selected to be analyzed.';

  // fireflowcalc.pas
  rsSolverFailure  = 'Solver failure for Design Fire Flow at node %s, Error Code = %d';
  rsSearchFailure  = 'Solver failure during fire flow search at node %s, Error Code = %d';
  rsStaticFailure  = 'Solver failure analyzing static pressures, Error Code = %d';

  // fireflowprogress.pas
  rsPcntCompleted  = '% Completed';

  // results.pas
  rsTrace          = 'Trace';
  rsPcntSymbol     = '%';

  // simulator.pas
  rsStatusNone     = 'Unable to run simulator.';
  rsStatusVersion  = 'Run was unsuccessful.' + LineEnding +
                     'Wrong version of simulator.';
  rsStatusFailed   = 'Run was unsuccessful' + LineEnding + 'due to system error.';
  rsStatusError    = 'Run was unsuccessful.' + LineEnding +
                     'See Status Report for reasons.';
  rsStatusWarning  = 'Warning messages were generated.' + LineEnding +
                     'See Status Report for details.';
  rsStatusSuccess  = 'Run was successful.';
  rsStatusShutdown = 'Simulator performed an illegal' + LineEnding +
                     'operation and was shut down.';
  rsStatusCanceled = 'Run cancelled by user.';
  rsSolvingHydraul = 'Solving hydraulics at hour ';
  rsSolvingQuality = 'Solving quality at hour ';

  // systemcalc.pas
  rsSystem         = 'System';
  rsSysEnergy      = 'Energy Usage';
  rsSysDemand      = 'Demand';
  rsSysDemandDfct  = 'Demand Deficit';
  rsSysLeakage     = 'Leakage';
  rsSysStorage     = 'Storage';
  rsSysPressure    = 'Avg. Pressure';

  // mapthemes.pas
  rsNone           = 'None';
  rsOverviewMap    = 'Overview Map';
  rsInch           = 'in';
  rsMillimeter     = 'mm';
  rsFeetPerSec     = 'ft/s';
  rsMetersPerSec   = 'm/s';
  rsFtPerKiloFt    = 'ft/Kft';
  rsMetersPerKm    = 'm/km';

  // themelegend.pas
  rsOutOfOrder     = 'Values must be in ascending order.';
  rsNoThemeValues  = 'No values exist for selected map theme.';

  // themerange.pas
  rsInvalidRange   = 'Range values are invalid.';

  // TaskDialog Titles
  rsMissingData    = 'Missing Data';
  rsInvalidData    = 'Invalid Data';
  rsInvalidSelect  = 'Invalid Selection';
  rsFileError      = 'File Error';
  rsValidError     = 'Validation Error';
  rsConnectFail    = 'Connection Failure';
  rsDeleteFail     = 'Deletion Failure';
  rsCreateFail     = 'Creation Failure';
  rsTransFail      = 'Transform Failure';
  rsConfirmDelete  = 'Confirm Deletion';
  rsPleaseConfirm  = 'Please Confirm';
  rsProjectSave    = 'Save Project';
  rsMsxSave        = 'Save Msx Data';

  // about.pas
  rsVersions       = 'EPANET-UI Version 1.0.0' + LineEnding + LineEnding +
                     'OWA-EPANET Version 2.3.5' + LineEnding + LineEnding +
                     'EPANET-MSX Version 2.0';
  rsAbout          = 'A graphical user interface for the Open Water Analytics' +
                     LineEnding +
                     'version of the EPANET water distribution system simulator.';

implementation

end.

