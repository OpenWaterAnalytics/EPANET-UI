{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       csvloader
 Description:  views the contents of a CSV text file
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit csvviewer;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, Grids;

type

  { TCsvViewerForm }

  TCsvViewerForm = class(TForm)
    StringGrid1: TStringGrid;
    procedure FormCreate(Sender: TObject);
  private

  public
    function  ViewCsvFile(Filename: string): Boolean;
  end;

var
  CsvViewerForm: TCsvViewerForm;

implementation

{$R *.lfm}

uses
  config, utils, resourcestrings;

{ TCsvViewerForm }

procedure TCsvViewerForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
end;

function TCsvViewerForm.ViewCsvFile(Filename: string): Boolean;
begin
  Result := true;
  try
    StringGrid1.LoadFromCSVFile(Filename);
  except
    utils.MsgDlg(rsFileError, rsNoCsvDisplay, mtInformation, [mbOK]);
    Result := false;
  end;
end;

end.

