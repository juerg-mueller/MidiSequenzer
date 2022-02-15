//
// Copyright (C) 2022 Jürg Müller, CH-5524
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
unit USheetMusic;

interface

uses
  SysUtils, System.Zip,
  UGriffPartitur, UMyMemoryStream, UGriffEvent;

type
  TTieStatus = (tieOff, tieStart, tieMitte, tieStop);

  TSaveRec = record
    iEvent: integer;
    iEnd: integer;
    hasEvenGriff: boolean;
    hasSame: boolean;
    nextSame: boolean;
    t, t1: integer;
    tupletNr: integer;
    InPu: boolean;
    triole: integer;
    Len: integer;
    slen, sDur: string;
    dot: boolean;
    tie:  TTieStatus;
    tieFractions: string;  // z.B. 1/2
    tieMeasures: integer;

    Takt, TaktNr: integer;
    MeasureNr: integer;
    Offset: integer;
    MostRight: integer;
    t32takt: integer;
    appoggiatura: TTieStatus;
    appoggNr: integer;

    LastRepeat: TRepeat;
    Volta1Off, Volta2Off: integer;

    Aufrunden: boolean;

    procedure Clear;
    function LimitToTakt: boolean;
    function Rest(Delta: integer; UseIf: boolean): boolean;
    function SaveLen(Delta: integer): boolean;
    function GetLenS(var t32: integer; quarterNote: integer): string;
  end;


  TSheetMusicHelper = class helper for TGriffPartitur
    function GetBassLyrics(const SaveRec: TSaveRec): string;
    function SetTriolen(var SaveRec: TSaveRec): boolean;
    function IsAppoggiatura(var SaveRec: TSaveRec): boolean;
    procedure SetIEnd(var SaveRec: TSaveRec);
    function HasEvenGriff(var SaveRec: TSaveRec): boolean;
    procedure MakeSmallestNote;


    function IsTriole(iEvent: integer; Ticks: integer): boolean;
    function TriolenTest(iEvent: integer): integer;
    function LastChordEvent(iEvent: integer): integer;



//    function LoadFromMscx(FileName: string): boolean;
//    function SaveToMscx(const FileName: string): boolean;
    function MakeLilyPond(const Title: string): TMyMemoryStream;
    function LoadFromMusicXML(FileName: string): boolean;
    function SaveToMusicXML(const FileName: string; GriffOnly: boolean): boolean;

  end;


function GetLen(var t32: integer; var dot: boolean; t32Takt: integer): string;

implementation

uses
  UXmlNode, UXmlParser, UEventArray, UGriffArray,
  UMyMidiStream, UInstrument;


function GetLen(var t32: integer; var dot: boolean; t32Takt: integer): string;
var
  val: integer;
begin
  dot := false;
  val := GetLen_(t32, Dot, t32takt);
  if val = 0 then
    result := '?'
  else
    result := GetFraction_(32 div val);
end;

function TSaveRec.GetLenS(var t32: integer; quarterNote: integer): string;
var
  t, t1: integer;
begin
  t := 8*takt div quarterNote - t32Takt;
  if (t32 > t) and (t > 0) then
  begin
    t := 8*takt div quarterNote - t32Takt;
    t1 := t;
    result := GetLen(t, dot, t32Takt);
    dec(t32, t1 - t);
  end else
    result := GetLen(t32, dot, t32Takt);
end;

procedure TSaveRec.Clear;
begin
  iEvent := 0;
  iEnd := 0;
  hasEvenGriff := false;
  hasSame := false;
  nextSame := false;
  t := 0;
  t1 := 0;

  tupletNr := 0;
  InPu := false;
  triole := 0;
  Len := 0;
  slen := '';
  sDur := '';
  dot := false;
  tie := tieOff;
  tieFractions := '';
  tieMeasures := 0;

  Takt := 0;
  TaktNr := 0;
  MeasureNr := 1;
  Offset := 0;
  MostRight := 0;
  t32takt := 0;
  appoggiatura := tieOff;
  appoggNr := 0;

  LastRepeat := rRegular;
  Volta1Off := -1;
  Volta2Off := -1;

  Aufrunden := false;
end;

function TSaveRec.LimitToTakt: boolean;
begin
  if Len < 0 then
    result := false
  else
  result := (offset div Takt) <> ((offset + Len) div Takt);
  if result then
    Len := takt * ((offset div Takt) + 1) - offset;
end;

function TSaveRec.Rest(Delta: integer; UseIf: boolean): boolean;
begin
  result := (Delta > 0) and not UseIf;
  tie := tieOff;
  Len := Delta;
  if LimitToTakt then
    result := true;
end;

function TSaveRec.SaveLen(Delta: integer): boolean;
begin
  result := Delta > 0;
  Len := Delta;
end;


////////////////////////////////////////////////////////////////////////////////


procedure TSheetMusicHelper.MakeSmallestNote;
var
  iEvent, i: integer;
begin
  iEvent := 0;
  while iEvent < UsedEvents do
  begin
    if TriolenTest(iEvent) > 0 then
    begin
      for i := 1 to 3 do
      begin
        while GriffEvents[iEvent].NoteType <> ntDiskant do
          inc(iEvent);
        inc(iEvent);
      end;
      continue;
    end;
    // Triolen erkennen
    {
    if (iEvent + 2 < UsedEvents) and
       (abs(GriffEvents[iEvent+1].AbsRect.Left - GriffEvents[iEvent].AbsRect.Right) < 2) and
       (abs(GriffEvents[iEvent+2].AbsRect.Left - GriffEvents[iEvent+1].AbsRect.Right) < 2) then
    begin
      inc(iEvent, 3);
      continue;
    end;  }
    if GriffEvents[iEvent].AbsRect.Width < GriffHeader.Details.smallestNote then
      GriffEvents[iEvent].AbsRect.Width := GriffHeader.Details.smallestNote;
    GriffHeader.Details.SetRaster(GriffEvents[iEvent].AbsRect);
    inc(iEvent);
  end;
  SortEvents;
end;

function TSheetMusicHelper.GetBassLyrics(const SaveRec: TSaveRec): string;
var
  i: integer;
  Pitch: byte;
begin
  result := '';
  i := SaveRec.iEvent;
  while i <= SaveRec.iEnd do
  begin
    Pitch := GriffEvents[i].GriffPitch;
    if not Instrument.BassDiatonic then
    begin
      result := IntToStr(Pitch);
      break;
    end else
    if Pitch in [1..8] then
    begin
      if GriffEvents[i].Cross then
        result := result + string(SteiBass[6, Pitch])
      else
        result := result + string(SteiBass[5, Pitch]);
    end;
    inc(i);
  end;
end;

function TSheetMusicHelper.LastChordEvent(iEvent: integer): integer;
// In einer Triole.
begin
  while (iEvent < UsedEvents) and
        (GriffEvents[iEvent].NoteType <> ntDiskant) do
    inc(iEvent);
  result := iEvent;
  while (result + 1 < UsedEvents) and
        ((GriffEvents[result+1].NoteType <> ntDiskant) or
         GriffEvents[result+1].SameChord(GriffEvents[iEvent])) do
    inc(result);
  while (result > iEvent) and (GriffEvents[result].NoteType <> ntDiskant) do
    dec(result);
end;

function TSheetMusicHelper.IsTriole(iEvent: integer; Ticks: integer): boolean;

  function TestLen: boolean;
  begin
    result := (iEvent < UsedEvents) and
              (abs(3*GriffEvents[iEvent].AbsRect.Width - Ticks) < 25);
  end;

var
  Last, i: integer;
begin
  result := TestLen;
  for i := 1 to 2 do
  begin
    if not result then
      exit;
    Last := iEvent;
    iEvent := LastChordEvent(iEvent) + 1;
    while (iEvent+1 < UsedEvents) and
          (GriffEvents[iEvent].NoteType <> ntDiskant) do
      inc(iEvent);

    result := TestLen and
              (abs(GriffEvents[iEvent].AbsRect.Left - GriffEvents[Last].AbsRect.Right) < 15);
  end;
end;

function TSheetMusicHelper.TriolenTest(iEvent: integer): integer;
begin
  result := 0;
  if IsTriole(iEvent, 2*quarterNote) then
    result := 4
  else
  if IsTriole(iEvent, quarterNote) then
    result := 8
  else
  if IsTriole(iEvent, quarterNote div 2) then
    result := 16
  else
  if IsTriole(iEvent, quarterNote div 4) then
    result := 32;
end;

function TSheetMusicHelper.SetTriolen(var SaveRec: TSaveRec): boolean;
begin
  SaveRec.triole := TriolenTest(SaveRec.iEvent);

  SaveRec.sLen := GetFraction_(SaveRec.triole);
  result := SaveRec.triole > 0;
  if result then
    SaveRec.sDur := IntToStr(64 div SaveRec.triole);
end;

function TSheetMusicHelper.IsAppoggiatura(var SaveRec: TSaveRec): boolean;
var
  i: integer;
begin
  with SaveRec do
  begin
    t1 := t;
    result := (iEvent = iEnd) and
              GriffEvents[iEvent].IsAppoggiatura(GriffHeader);
    if result then
    begin
      appoggNr := 0;
      inc(iEnd);
      while (iEnd < UsedEvents) and
            ((GriffEvents[iEnd].NoteType <> ntDiskant) or
             ((GriffEvents[iEvent].AbsRect.Left = GriffEvents[iEnd].AbsRect.Left) and
              GriffEvents[iEnd].IsAppoggiatura(GriffHeader))) do
        inc(iEnd);
      while (iEnd < UsedEvents) and
            (GriffEvents[iEnd].NoteType <> ntDiskant) do
        inc(iEnd);
      i := iEnd;
      while (iEnd < UsedEvents-2) and
            ((GriffEvents[iEnd+1].NoteType <> ntDiskant) or
             (GriffEvents[i].AbsRect.Left = GriffEvents[iEnd+1].AbsRect.Left)) do
        inc(iEnd);

      while (iEnd > i) and (GriffEvents[iEnd].NoteType <> ntDiskant) do
        dec(iEnd);

      Len := GriffHeader.Details.GetRaster(GriffEvents[SaveRec.iEvent].AbsRect.Width + GriffEvents[SaveRec.iEnd].AbsRect.Width);
      t := 8*Len div quarterNote;
      t1 := t;
    end;
  end;
end;

procedure TSheetMusicHelper.SetIEnd(var SaveRec: TSaveRec);
begin
  with SaveRec do
  begin
    iEnd := iEvent;
    while (iEnd+1 < UsedEvents) and
          (GriffEvents[iEvent].AbsRect.Left = GriffEvents[iEnd+1].AbsRect.Left) and
          (GriffEvents[iEvent].SpecialBassWidth(GriffHeader) =
           GriffEvents[iEnd+1].SpecialBassWidth(GriffHeader)) do
    begin
      inc(iEnd);
      if GriffEvents[iEnd].Repeat_ >= rStart then
        LastRepeat := GriffEvents[iEnd].Repeat_;
    end;
    if GriffEvents[iEvent].NoteType = ntBass then
      while (iEnd > iEvent) and
            (GriffEvents[iEnd].NoteType <> ntBass) do
        dec(iEnd);
  end;
  HasEvenGriff(SaveRec);
end;

function TSheetMusicHelper.HasEvenGriff(var SaveRec: TSaveRec): boolean;
var
  i: integer;
  Line, l: integer;
begin
  result := false;
  SaveRec.hasSame := false;
  SaveRec.nextSame := false;
  for i := SaveRec.iEvent+1 to SaveRec.iEnd do
    if GriffEvents[i].GriffPitch = GriffEvents[i-1].GriffPitch then
    begin
      result := true;
      SaveRec.hasSame := true;
      exit;
    end;

  for i := SaveRec.iEvent to SaveRec.iEnd do
    if (GriffEvents[i].NoteType = ntDiskant) and
       not odd(GetPitchLine(GriffEvents[i].GriffPitch)) then
      result := true;
  if true then
  begin
    result := false;
    Line := GetPitchLine(GriffEvents[SaveRec.iEvent].GriffPitch);
    for i := SaveRec.iEvent+1 to SaveRec.iEnd do
      if (GriffEvents[i].NoteType = ntDiskant) then
      begin
        l := GetPitchLine(GriffEvents[i].GriffPitch);
        if abs(l - Line) < 2 then
          result := true;
        Line := l;
      end;
  end;
  SaveRec.hasEvenGriff := result;
end;



////////////////////////////////////////////////////////////////////////////////

{$I IMusicXmlHelper.pas}
{$I ILilyPondHelper.pas}


end.
