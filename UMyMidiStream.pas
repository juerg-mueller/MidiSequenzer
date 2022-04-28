//
// Copyright (C) 2020 Jürg Müller, CH-5524
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation version 3 of the License.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU Lesser General Public License for more details.
//
// You should have received a copy of the GNU Lesser General Public License
// along with this program. If not, see http://www.gnu.org/licenses/ .
//

unit UMyMidiStream;

interface

uses
  SysUtils, Classes, Types,
  UMyMemoryStream, UMidiEvent;
{
Const
  cSimpleHeader = AnsiString('Header');
  cSimpleTrackHeader = AnsiString('New_Track');
  cSimpleMetaEvent = AnsiString('Meta-Event');
  cPush = AnsiString('Push');
  cPull = AnsiString('Pull');

  PushTest = true;
  CrossTest = true;

  HexOutput = true;

  MidiC0 = 12;
  FlatNotes  : array [0..11] of string = ('C', 'Des', 'D', 'Es', 'E', 'F', 'Ges', 'G', 'As', 'A', 'B', 'H');
  SharpNotes : array [0..11] of string = ('C', 'Cis', 'D', 'Dis', 'E', 'F', 'Fis', 'G', 'Gis', 'A', 'B', 'H');

  Dur: array [-6..6] of string = ('Ges', 'Des','As', 'Es', 'B', 'F', 'C', 'G', 'D', 'A', 'E', 'H', 'Fis');

//  SustainPitch    = 26;
  ControlSustain  = $1f;   // + 3 für TRepeat

type
  TInt4 = array [0..3] of integer;

  eTranslate = (nothing, toGriff, toSound); 

  TPushPullSet = set of (push, pull);


  TMidiEvent = record
    command: byte;
    d1, d2: byte;
    var_len: integer;
    bytes: array of byte;

    constructor Create(a, b, c, l: integer);
    procedure Clear;
    function Event: byte;
    function Channel: byte;
    function IsSustain: boolean;
    function MakeNewSustain: boolean;
    function IsPush: boolean;
    procedure MakeSustain(Push: boolean);
    function IsEndOfTrack: boolean;
    function IsEqualEvent(const Event: TMidiEvent): boolean;
    procedure SetEvent(c, d1_, d2_: integer);
    procedure AppendByte(b: byte);
    procedure MakeMetaEvent(EventNr: byte; b: AnsiString);
    procedure FillBytes(const b: AnsiString);
    function GetBytes: string;
    function GetAnsi: AnsiString;
    function GetInt: cardinal;
    function GetAnsiChar(Idx: integer): AnsiChar;

    property str: String read GetBytes;
    property ansi: AnsiString read GetAnsi;
    property int: cardinal read GetInt;
    property char_[Idx: integer]: Ansichar read GetAnsiChar; default;
  end;
  PMidiEvent = ^TMidiEvent;

  TDetailHeader = record
    IsSet: boolean;
    // delta-time ticks pro Viertelnote
    DeltaTimeTicks: word;
    // Beats/min.  Viertelnoten/Min.
    beatsPerMin: integer;
    smallestFraction: integer;
    measureFact: integer;
    measureDiv: integer;
    CDur: integer;  // f-Dur: -1; g-Dur: +1
    Minor: boolean;

    procedure Clear;
    function GetMeasureDiv: double;
    function GetRaster(p: integer): integer;
    procedure SetRaster(var rect: TRect);
    function GetTicks: double;
    function GetSmallestTicks: integer;
    function MsDelayToTicks(MsDelay: integer): integer;
    function TicksPerMeasure: integer;
    function TicksToSec(Ticks: integer): integer;
    function TicksToString(Ticks: integer): string;
    function SetTimeSignature(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function SetBeatsPerMin(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function SetDurMinor(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function SetParams(const Event: TMidiEvent; const Bytes: array of byte): boolean;
    function GetMetaBeats51: AnsiString;
    function GetMetaMeasure58: AnsiString;
    function GetMetaDurMinor59: AnsiString;
    function GetDur: string;
    function GetChordTicks(duration, dots: string): integer;

    property smallestNote: integer read GetSmallestTicks;
  end;
  PDetailHeader = ^TDetailHeader;

  TMidiHeader = record
    FileFormat: word;
    TrackCount: word;
    Details: TDetailHeader;
    procedure Clear;
  end;

  TTrackHeader = record
    ChunkSize: cardinal;
    DeltaTime: cardinal;
  end;
  }
type

  TMyMidiStream = class(TMyMemoryStream)
  public
    time: TDateTime;
    MidiHeader: TMidiHeader;
    ChunkSize: Cardinal;
    InPull: boolean;

    function ReadByte: byte;
    procedure StartMidi;
    procedure MidiWait(Delay: integer);
  {$if defined(CONSOLE)}
    function Compare(Stream: TMyMidiStream): integer;
  {$endif}
    class function IsEndOfTrack(const d: TInt4): boolean;
  end;

implementation

uses
  UGriffEvent;

procedure TMyMidiStream.MidiWait(Delay: integer);
var
  NewTime: TDateTime;
begin
  if (Delay > 0) and (MidiHeader.Details.DeltaTimeTicks > 0) then
  begin
    Delay := trunc(2*Delay*192.0 / MidiHeader.Details.DeltaTimeTicks);
    if Delay > 2000 then
      Delay := 1000;
{$if false}
  if Delay > 16 then
      dec(Delay, 16)
    else
      Delay := 1;  
    
    Sleep(Delay);
{$else}
    NewTime := time + round(Delay/(24.0*3600*1000.0));
    while now < NewTime do
      Sleep(1);
    time := NewTime;
{$endif}
  end;
end;

procedure TMyMidiStream.StartMidi;
begin
  time := now;
end;

function TMyMidiStream.ReadByte: byte;
begin
  result := inherited;
  if ChunkSize > 0 then
    dec(ChunkSize);  
end;

{$if defined(CONSOLE)}
function TMyMidiStream.Compare(Stream: TMyMidiStream): integer;
var
  b1, b2: byte;
  Err: integer;
begin
  result := 0;
  Err := 0;
  repeat
    if (result >= Size) and (result >= Stream.Size) then
      break;
    b1:= GetByte(result);
    b2 := Stream.GetByte(result);
    if (b1 <> b2) then
    begin
      system.writeln(Format('%x (%d): %d   %d', [result, result, b1, b2]));
      inc(Err);
    end;
     // break;
    inc(result);
  until false;
  system.writeln('Err: ', Err);
end;
{$endif}

class function TMyMidiStream.IsEndOfTrack(const d: TInt4): boolean;
begin
  result :=  (d[1] = $ff) and (d[2] = $2f) and (d[3] = 0);
end;


end.

