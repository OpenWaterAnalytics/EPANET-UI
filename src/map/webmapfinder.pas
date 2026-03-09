{====================================================================
 Project:      EPANET-UI
 Version:      1.0.0
 Module:       webmapfinder
 Description:  a form that finds the geographic coords of an address
 License:      see LICENSE
 Last Updated: 03/07/2026
=====================================================================}

unit webmapfinder;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  LCLtype, StrUtils, fphttpclient, opensslsockets;

type

  { TWebMapFinderForm }

  TWebMapFinderForm = class(TForm)
    Edit1: TEdit;
    Label1: TLabel;
    procedure Edit1KeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);

  private
    procedure GetLatLon(Address: string);
    function  GetLocation(Address: string; var Location: string): Boolean;
    function  ParseLatLon(Location: string): Boolean;
    function  GetString(aUrl: string; var Str: string): Boolean;

  public
    Lat: Double;
    Lon: Double;
  end;

var
  WebMapFinderForm: TWebMapFinderForm;

implementation

uses
  config, utils, resourcestrings;

{$R *.lfm}

{ TWebMapFinderForm }

procedure TWebMapFinderForm.FormCreate(Sender: TObject);
begin
  Color := config.ThemeColor;
  Font.Size := config.FontSize;
end;

procedure TWebMapFinderForm.Edit1KeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    ModalResult := mrCancel
  else if Key = VK_RETURN then
    GetLatLon(Edit1.Text);
end;

procedure TWebMapFinderForm.GetLatLon(Address: string);
var
  Location: string = '';
  Found: Boolean = false;
begin
  if ParseLatLon(Address) then
    Found := true
  else if GetLocation(Address, Location) then
    Found := ParseLatLon(Location);
  if not Found then
  begin
    Utils.MsgDlg(rsInvalidSelect, rsNoFind + ' ' + Address, mtError, [mbOk]);
  end
  else
  begin
    ModalResult := mrOK;
  end;
end;

function TWebMapFinderForm.GetLocation(Address: string; var Location: string): Boolean;
//
// Use the Open Street Map Nominatim rest service to find the latitude &
// longitude of a place name or street address returned in 'Location'.
//
var
  Url: AnsiString = '';
  Str: string;
  I1: Integer;
  I2: Integer;
begin
  Result := false;
  Location := '';
  Address := ReplaceStr(Address, ' ', '%20');

  Url := 'https://nominatim.openstreetmap.org/search?q=' + Address +
         '&format=json&limit=1&email=hydrotools22@gmail.com';

  try
    Str := '';
    Result := GetString(Url, Str)

  except on E: Exception do
    utils.MsgDlg(rsConnectFail, rsNoConnect + LineEnding + E.Message, mtError, [mbOK]);
  end;
  if Result = false then exit;

  I1 := Pos('"lat":"', Str) + Length('"lat":"');
  I2 := PosEx('"', Str, I1+1);
  Location := MidStr(Str, I1, I2-I1-1);
  I1 := Pos('"lon":"', Str) + Length('"lon":"');
  I2 := PosEx('"', Str, I1+1);
  Location := Location + ',' + MidStr(Str, I1, I2-I1-1);
end;

function TWebMapFinderForm.ParseLatLon(Location: string): Boolean;
//
// Extract latitude, longitude values from a string with format 'lat,lon'.
//
var
  Tokens: TStringList;
begin
  Result := true;
  Tokens := TStringList.Create;
  try
    Tokens.Delimiter := ',';
    Tokens.DelimitedText := Location;
    if Tokens.Count < 2 then Result := false
    else
    try
      Lat := StrToFloat(Tokens[0]);
      Lon := StrToFloat(Tokens[1]);
    except
      on E: Exception do Result := false;
    end;
  finally
    Tokens.Free;
  end;
end;

function TWebMapFinderForm.GetString(aUrl: string; var Str: string): Boolean;
var
  Client: TFPHTTPClient;
  Response: TStringList;
begin
  Result := false;
  Response := TStringList.Create;
  Client := TFPHttpClient.Create(Nil);
  try
    try
      try
        Client.IOTimeout := 4000;
        Client.AllowRedirect := true;
        Client.AddHeader('user-agent','epanet-ui/1.0.0');
        Client.Get(aUrl, Response);
      except
        raise;
      end;

    finally
      Client.Free;
    end;
    Str := Response.Text;
    Result := true;
  finally
    Response.Free;
  end;
end;

end.

