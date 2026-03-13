{====================================================================
 Project:      EPANET-UI
 Version:      1.0.1
 Module:       about
 Description:  'About EPANET' form
 License:      see LICENSE
 Last Updated: 03/13/2026
=====================================================================}

unit about;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  LCLtype, StdCtrls, LclIntf, ComCtrls, HtmlView, HtmlGlobals;

resourcestring

  rsIcons = 'Icons by <a href="https://icons8.com">icons8</a>.';

  rsLicense =
    '<p>MIT License</p>' +
    '<p>Copyright (c) 2026, the Authors</p>' +
    '<p>Permission is hereby granted, free of charge, to any person obtaining a copy '+
    'of this software and associated documentation files (the "Software"), to deal '+
    'in the Software without restriction, including without limitation the rights '+
    'to use, copy, modify, merge, publish, distribute, sublicense, and/or sell '+
    'copies of the Software, and to permit persons to whom the Software is '+
    'furnished to do so, subject to the following conditions:</p>'+
    '<p>The above copyright notice and this permission notice shall be included '+
    'in all copies or substantial portions of the Software.</p>'+
    '<p>THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR '+
    'IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, '+
    'FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE '+
    'AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER '+
    'LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, '+
    'OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE '+
    'SOFTWARE.</p>';
  rsAcknowledgements =
    '<p>These are the third-party libraries used by EPANET-UI:</p>'+
    '<p><a href="https://github.com/openwateranalytics/epanet">OWA-EPANET 2.3</a><br>'+
    'MIT license<br>'+
    'Copyright (c) 2019 by the <a href="https://github.com/OpenWaterAnalytics/'+
    'EPANET/blob/dev/AUTHORS">Authors</a></p>'+
    '<p><a href="https://github.com/USEPA/EPANETMSX">EPA EPANET-MSX 2.0</a><br>'+
    'MIT license<br>'+
    'Copyright (c) 2022 by the <a href="https://github.com/USEPA/EPANETMSX/'+
    'blob/master/Doc/AUTHORS">Authors</a></p>'+
    '<p><a href="http://shapelib.maptools.org/">Shapefile C Library 1.5</a><br>'+
    'MIT license<br>'+
    'Copyright (c) 1999, Frank Warmerdam<br></p>'+
    '<p><a href="https://github.com/OrdnanceSurvey/proj.4">Proj.4 4.4</a><br>'+
    'MIT license<br>'+
    'Copyright (c) 2000, Frank Warmerdam</p>'+
    '<p>Icons provided by <a href="https://icons8.com">icons8</a></p>';

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Image1: TImage;
    Label2: TLabel;
    PageControl1: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Panel3: TPanel;
    Panel4: TPanel;
    TabSheet1:    TTabSheet;
    TabSheet2:    TTabSheet;
    TabSheet3:    TTabSheet;
    HtmlViewer2:  THtmlViewer;
    HtmlViewer3:  THtmlViewer;

    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure HtmlViewer3HotSpotClick(Sender: TObject; const SRC: ThtString;
      var Handled: Boolean);
    procedure PageControl1Change(Sender: TObject);
  private

  public

  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

{ TAboutForm }

uses
  config, resourcestrings;

procedure TAboutForm.FormCreate(Sender: TObject);
begin
  Color := Config.ThemeColor;
  Font.Size := config.FontSize;
  Panel3.Caption := rsAbout;
  Panel4.Caption := rsVersions;
  HtmlViewer2.DefFontSize := config.FontSize;
  HtmlViewer2.LoadFromString(rsLicense);
  HtmlViewer3.DefFontSize := config.FontSize;
  HtmlViewer3.LoadFromString(rsAcknowledgements);
  PageControl1.ActivePageIndex := 0;
end;

procedure TAboutForm.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then Close;
end;

procedure TAboutForm.HtmlViewer3HotSpotClick(Sender: TObject;
  const SRC: ThtString; var Handled: Boolean);
begin
  OpenUrl(SRC);
end;

procedure TAboutForm.PageControl1Change(Sender: TObject);
begin
  if PageControl1.ActivePage = TabSheet3 then
    HtmlViewer3.SetFocus;
end;

end.

