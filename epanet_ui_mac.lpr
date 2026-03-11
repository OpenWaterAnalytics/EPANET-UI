program epanet_ui_mac;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,
  {$ENDIF}
  {$IFDEF HASAMIGA}
  athreads,
  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  SysUtils, Forms, FrameViewer09, tachartlazaruspkg, tachartbgra, lazcontrols,
  main, about, config, epanet2, epanetmsx, ShpAPI, proj, mrumanager,
  utils, mapthemes, legendeditor, themepalette, results, simulator,
  chartoptions, configeditor, controlseditor, demandseditor,
  editor, labeleditor, qualeditor, ruleseditor, sourceeditor,
  titleeditor, validator, inifile, project, projectbuilder, projectsetup,
  projectmapdata, projectframe, projectloader, projectsummary, projectviewer,
  properties, mapcoords, webmap, mapframe, maplabel, mapoptions, maprenderer,
  webmapfinder, map, welcome, statusrpt, sysflowrpt, timeseriesrpt,
  pumpingrpt, networkrpt, mapgeoref, calibrationrpt, energycalc, energyrpt,
  dxfimporter, dxfloader, dxfviewer, shpimporter, shploader, shpviewer,
  maplocater, mapquery, webmapserver, pcntilerpt, mainmenu, basemapmenu,
  mapexporter, projtransform, curveeditor, patterneditor, curveviewer,
  tseriesselector, profilerpt, msxfileprocs, groupeditor, profileselector,
  statusframe, mapalign, csvimporter, csvviewer, csvloader,
  overviewmapframe, pcntileselector, resourcestrings, reportviewer, sysresults,
  fireflowcalc, fireflowrpt, fireflowselector, fireflowprogress;

{$R *.res}

begin
  //SetHeapTraceOutput('Trace.log');

  // Set CWD to the system temp directory so the EPANET library's
  // internal temp files (created via mkstemp with a relative path)
  // are written to a writable location when running as a .app bundle.
  SetCurrentDir(GetTempDir);

  RequireDerivedFormResource:=True;
  Application.Scaled:=True;
  Application.Title:='EPANET-UI';
  Application.Initialize;
  Application.CreateForm(TmainForm, mainForm);
  Application.CreateForm(TReportViewerForm, ReportViewerForm);
  Application.CreateForm(TControlsEditorForm, ControlsEditorForm);
  Application.CreateForm(TRulesEditorForm, RulesEditorForm);
  Application.Run;
end.

