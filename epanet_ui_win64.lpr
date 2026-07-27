program epanet_ui_win64;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  cLocale,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms, FrameViewer09, tachartlazaruspkg, tachartbgra, lazcontrols, main,
  about, config, epanet2, epanetmsx, ShpAPI, proj, mrumanager, utils, mapthemes,
  legendeditor, themepalette, maplegend, results, simulator, chartoptions,
  configeditor, controlseditor, demandseditor, editor, labeleditor, qualeditor,
  ruleseditor, sourceeditor, titleeditor, validator, inifile, project,
  projectbuilder, projectsetup, projectmapdata, projectframe, projectloader,
  projectsummary, projectviewer, properties, mapcoords, webmap, mapframe,
  maplabel, mapoptions, maprenderer, webmapfinder, map, welcome, statusrpt,
  sysflowrpt, timeseriesrpt, pumpingrpt, networkrpt, mapgeoref, calibrationrpt,
  energycalc, energyrpt, dxfimporter, dxfloader, dxfviewer, shpimporter,
  shploader, shpviewer, maplocater, mapquery, webmapserver, pcntilerpt,
  mainmenu, projtransform, curveeditor, patterneditor, curveviewer,
  tseriesselector, profilerpt, msxfileprocs, profileselector, statusframe,
  mapalign, csvimporter, csvviewer, csvloader, overviewmapframe, mapviewerframe,
  pcntileselector, resourcestrings, basemapmenu, sysresults,
  fireflowcalc, fireflowrpt, fireflowselector, fireflowprogress, filemenu,
  groupeditor, groupselector, reportframe;

{$R *.res}

begin
  //SetHeapTraceOutput('Trace.log');
  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Title:='EPANET-UI';
  Application.Initialize;
  Application.CreateForm(TmainForm, mainForm);
  Application.CreateForm(TControlsEditorForm, ControlsEditorForm);
  Application.CreateForm(TRulesEditorForm, RulesEditorForm);
  Application.Run;
end.

