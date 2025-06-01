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
unit UGriffArray;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils,
  umidi,
{$ifdef mswindows}
{$else}
  urtmidi,
{$endif}
  UMyMidiStream, UGriffEvent, UEventArray, UInstrument, UMidiEvent, UMidiDataStream;

type

  TGriffArray = class
    class procedure SortGriffEvents(var GriffEvents: TGriffEventArray; var Selected: integer);
    class procedure ReduceBass(var GriffEvents: TGriffEventArray); overload;
    class procedure ReduceBass(var MidiEvents: TMidiEventArray; Channel: integer); overload;
    class procedure DeleteDoubles(var GriffEvents: TGriffEventArray);
    class procedure DeleteGriffEvent(var GriffEvents: TGriffEventArray; Index: integer);
    class procedure SplitBass(var DiskantGriffEvents, BassGriffEvents: TGriffEventArray;
                              const GriffEvents: TGriffEventArray);
    class procedure CopyGriffToMidi(var MidiEvents: TMidiEventArray;
                                    const GriffEvents: TGriffEventArray;
                                    Bass, BassDiatonic: boolean;
                                    realGriffschrift: boolean);
    class procedure CopyGriffToNewMidi(var MidiEvents: TMidiEventArray;
                                       const GriffEvents: TGriffEventArray;
                                       Bass, BassDiatonic: boolean);
    class function MakeStreamFromGriffEvents(const GriffEvents: TGriffEventArray;
                                   const Instrument: TInstrument;
                                   const DetailHeader: TDetailHeader;
                                   realGriffschrift: boolean): TMidiSaveStream;
    class function MakeNewStreamFromGriffEvents(const GriffEvents: TGriffEventArray;
                                      const Instrument: TInstrument;
                                      const DetailHeader: TDetailHeader): TMidiSaveStream;

    class function MakeSimpleFromDataStream(const GriffEvents: TGriffEventArray;
                                         const Instrument: TInstrument;
                                         const DetailHeader: TDetailHeader;
                                         realGriffschrift: boolean): TSimpleDataStream;

    class function CorrectSoundPitch(var GriffEvents: TGriffEventArray;
                                     const Instrument: TInstrument): boolean;
  end;

implementation


{$ifdef mswindows}
uses
  Midi;
{$endif}

class procedure TGriffArray.SortGriffEvents(var GriffEvents: TGriffEventArray; var Selected: integer);

  procedure Exchange(i, j: integer);
  var
    Event: TGriffEvent;
  begin
    if i = Selected then
      Selected := j
    else
    if j = Selected then
      Selected := i;

    Event := GriffEvents[i];
    GriffEvents[i] := GriffEvents[j];
    GriffEvents[j] := Event;
  end;

var
  i, k, j: integer;
  UsedEvents: integer;
  RepeatStart, RepeatStop: TRepeat;
begin
  UsedEvents := Length(GriffEvents);
  for i := 0 to UsedEvents-2 do
    for k := i + 1 to UsedEvents-1 do
    begin
      if (GriffEvents[i].AbsRect.Left > GriffEvents[k].AbsRect.Left) or
         ((GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right > GriffEvents[k].AbsRect.Right)) or
         ((GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right = GriffEvents[k].AbsRect.Right) and
          (GriffEvents[i].AbsRect.Top > GriffEvents[k].AbsRect.Top)) then
      begin
        Exchange(i, k);
      end;
    end;

  // tiefer Bass vor hohem (Cross) Bass
  i := 0;
  while (i < UsedEvents-1) do
  begin
    while (i < UsedEvents-1) and
          (GriffEvents[i].NoteType <> ntBass) do
      inc(i);
    k := i;
    while (k < UsedEvents - 1) and
          (GriffEvents[k+1].NoteType = ntBass) do
    begin
      if (GriffEvents[i].AbsRect.Left = GriffEvents[k+1].AbsRect.Left) and
         (GriffEvents[i].AbsRect.Right = GriffEvents[k+1].AbsRect.Right) then
        inc(k)
      else
        break;
    end;

    while k > i do
    begin
      for j := i+1 to k do
        if GriffEvents[i].SoundPitch > GriffEvents[j].SoundPitch then
        begin
          Exchange(i, j);
        end;
      inc(i);
    end;
    inc(i);
  end;

{$if true}
  i := 0;
  while i < UsedEvents-1 do
  begin
    k := i;
    RepeatStart := rRegular;
    RepeatStop := rRegular;
    while (k < UsedEvents) and
          (GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) do
    begin
      if GriffEvents[k].Repeat_ in [rStart, rVolta1Start, rVolta2Start] then
        RepeatStart := GriffEvents[k].Repeat_
      else
      if GriffEvents[k].Repeat_ in [rStop, rVolta1Stop, rVolta2Stop] then
        RepeatStop := GriffEvents[k].Repeat_;
      inc(k);
    end;
    dec(k);

    if (RepeatStart <> rRegular) or (RepeatStop <> rRegular) then
    begin
{$if defined(CONSOLE)}
      if (i = k) and (RepeatStart <> rRegular) and (RepeatStop <> rRegular) then
        writeln('Error repeat event: ', i);
{$endif}
      if i < k then
      begin
        GriffEvents[i].Repeat_ := RepeatStart;
        GriffEvents[k].Repeat_ := RepeatStop;
        for j := i + 1 to k - 1 do
          GriffEvents[j].Repeat_ := rRegular;
      end;
    end;
    i := k + 1;
  end;
{$endif}
end;

class procedure TGriffArray.DeleteDoubles(var GriffEvents: TGriffEventArray);
var
  i, k: integer;
begin
  i := 0;
  k := 0;
  while (i < Length(GriffEvents)-1) do
  begin
    if not GriffEvents[i].IsEqual(GriffEvents[i+1]) then
    begin
      if i <> k then
        GriffEvents[k] := GriffEvents[i];
      inc(k);
    end;
    inc(i);
  end;
  GriffEvents[k] := GriffEvents[i];
  inc(k);
  SetLength(GriffEvents, k);
end;

class procedure TGriffArray.DeleteGriffEvent(var GriffEvents: TGriffEventArray; Index: integer);
var
  i: integer;
begin
  if (Index >= 0) and (Index < Length(GriffEvents)) then
  begin
    for i := Index to Length(GriffEvents)-2 do
      GriffEvents[i] := GriffEvents[i+1];
    SetLength(GriffEvents, Length(GriffEvents)-1);
  end;
end;

class procedure TGriffArray.ReduceBass(var GriffEvents: TGriffEventArray);
var
  i, j, l, n: integer;
  BassDone: boolean;
  Pitch: byte;
begin
  n := -1;
  SortGriffEvents(GriffEvents, n);
  DeleteDoubles(GriffEvents);

  i := 0;
  while (i < Length(GriffEvents)) do
  begin
    if (GriffEvents[i].NoteType <> ntBass) then
    begin
      inc(i);
      continue;
    end;
    if i > 800 then
      i := i;

    j := i + 1;
    while (j < Length(GriffEvents)) and
          (GriffEvents[j].NoteType = ntBass) and
          (GriffEvents[i].AbsRect.Left = GriffEvents[j].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right = GriffEvents[j].AbsRect.Right) do
      inc(j);
    dec(j);

    BassDone := false;
    for l := i to j do
      if GriffEvents[i].SoundPitch + 12 = GriffEvents[l].SoundPitch then
      begin
        if GriffEvents[i].SoundPitch > 44 then
          dec(GriffEvents[i].SoundPitch, 12);
        if j - i < 2 then
          DeleteGriffEvent(GriffEvents, l);
        inc(i);
        BassDone := true;
        break;
      end;
    if BassDone then
      continue;

    if j - i >= 2 then
    begin
      Pitch := GriffEvents[i].SoundPitch;
      if ((GriffEvents[i].SoundPitch + 4 = GriffEvents[i+1].SoundPitch) and
          (GriffEvents[i+1].SoundPitch + 3 = GriffEvents[i+2].SoundPitch)) or
         ((GriffEvents[i].SoundPitch + 3 = GriffEvents[i+1].SoundPitch) and
          (GriffEvents[i+1].SoundPitch + 5 = GriffEvents[i+2].SoundPitch)) or
         ((GriffEvents[i].SoundPitch + 5 = GriffEvents[i+1].SoundPitch) and
          (GriffEvents[i+1].SoundPitch + 4 = GriffEvents[i+2].SoundPitch)) then
      begin
        if (GriffEvents[i+0].SoundPitch + 3 = GriffEvents[i+1].SoundPitch) and (GriffEvents[i+1].SoundPitch + 5 = GriffEvents[i+2].SoundPitch) then
          dec(Pitch, 4)
        else
        if (GriffEvents[i+0].SoundPitch + 5 = GriffEvents[i+1].SoundPitch) and (GriffEvents[i+1].SoundPitch + 4 = GriffEvents[i+2].SoundPitch) then
          Pitch := GriffEvents[i+1].SoundPitch;
        if Pitch > 56 then
          dec(Pitch, 12);

        DeleteGriffEvent(GriffEvents, i+2);
        DeleteGriffEvent(GriffEvents, i+1);

        GriffEvents[i].SoundPitch := Pitch;
        inc(i);
        BassDone := true;
      end
    end;
    if not BassDone then
    begin
      inc(i);
    end;
  end;
end;

class procedure TGriffArray.ReduceBass(var MidiEvents: TMidiEventArray; Channel: integer);
var
  GriffEvents: TGriffEventArray;
begin
//  CopyToGriff(GriffEvents, MidiEvents);
  ReduceBass(GriffEvents);
//  CopyToMidi(MidiEvents, GriffEvents, Channel);
end;


class procedure TGriffArray.SplitBass(var DiskantGriffEvents, BassGriffEvents: TGriffEventArray;
                                      const GriffEvents: TGriffEventArray);
var
  iEvent, iBass, iDiskant: integer;
  Event: TGriffEvent;
begin
  SetLength(DiskantGriffEvents, Length(GriffEvents));
  SetLength(BassGriffEvents, Length(GriffEvents));
  iBass := 0;
  iDiskant := 0;
  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    Event := GriffEvents[iEvent];
    if Event.NoteType = ntBass then
    begin
  {    if Event.Repeat_<> rRegular then
      begin
        Event.NoteType := ntRepeat;
        DiskantGriffEvents[iDiskant] := Event;
        inc(iDiskant);
        Event.NoteType := ntBass;
        Event.Repeat_ := rRegular;
      end;}
      BassGriffEvents[iBass] := Event;
      inc(iBass);
    end else begin
      DiskantGriffEvents[iDiskant] := Event;
      inc(iDiskant);
    end;
  end;
  SetLength(DiskantGriffEvents, iDiskant);
  SetLength(BassGriffEvents, iBass);
end;

class procedure TGriffArray.CopyGriffToMidi(var MidiEvents: TMidiEventArray;
                                            const GriffEvents: TGriffEventArray;
                                            Bass, BassDiatonic: boolean;
                                            realGriffschrift: boolean);
var
  Off: array [1..6, 0..127] of integer;
  RestOff: integer;
  Offset: integer;
  i, k: integer;
  smallest: integer;
  Ok, IsInPush: boolean;
  D: integer;
  AmpelRect: TAmpelRec;

  iEvent, iMidi: integer;
  MidiEvent: TMidiEvent;
  GriffEvent: TGriffEvent;

  function GetSmallest: integer;
  var
    i, r: integer;
  begin
    result := -1;
    if RestOff > 0 then
      result := RestOff;
    for r := 1 to 6 do
      for i := 0 to High(Off[r]) do
        if (Off[r, i] > 0) and
           ((Off[r, i] < result) or (result = -1)) then
        begin
          result := Off[r, i];
        end;
  end;

  procedure AppendMidiEvent;
  begin
    SetLength(MidiEvents, iMidi+1);
    MidiEvents[iMidi] := MidiEvent;
    inc(iMidi);
    MidiEvent.Clear;
  end;

  procedure GenerateStops(pos: integer);
  var
    i, r: integer;
    Found: boolean;
    iM: integer;
  begin
    Found := RestOff = Pos;
    iM := iMidi;
    for r := 1 to 6 do
      for i := 0 to High(Off[r]) do
        if (Off[r, i] > 0) and (pos <= Off[r, i]) then
        begin
          if Bass then
            MidiEvent.command := $81
          else
            MidiEvent.command := $80;
          MidiEvent.d1 := i;
          MidiEvent.d2 := $40;
          Off[r, i] := 0;
          Found := true;
          AppendMidiEvent;
        end;
    if Found then
    begin
      inc(MidiEvents[iM-1].var_len, pos - offset);
    end;
    if RestOff = Pos then
      RestOff := 0;
    offset := pos;
  end;

begin
  for k := 1 to 6 do
    for i := 0 to 127 do
      Off[k, i] := 0;
  RestOff := 0;

  Offset := 0;
  MidiEvent.Clear;
  iMidi := 0;
  AppendMidiEvent;

  IsInPush := true;
  if not Bass or BassDiatonic then
  begin
    MidiEvent.command := $b0;
    MidiEvent.d1 := ControlPushPull;
    MidiEvent.d2 := 0;
    if IsInPush then
      MidiEvent.d2 := 127;
    AppendMidiEvent;
  end;

  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    GriffEvent := GriffEvents[iEvent];

    if Bass <> (GriffEvent.NoteType = ntBass) then
      continue;

    repeat
      smallest := GetSmallest;
      Ok := (smallest > 0) and
            (smallest <= GriffEvent.AbsRect.Left);
      if Ok then
        GenerateStops(smallest);
    until not Ok;

    if (Offset < GriffEvent.AbsRect.Left) then  // Pause
    begin
      inc(MidiEvents[iMidi-1].var_len, GriffEvent.AbsRect.Left - Offset);
      Offset := GriffEvent.AbsRect.Left;
    end;

    // Wiederholungen
    if (GriffEvent.Repeat_ > rRegular) then
    begin
      MidiEvent.command := $b0;
      if Bass then
        inc(MidiEvent.command);
      MidiEvent.d1 := ControlPushPull + 3;
      MidiEvent.d2 := ord(GriffEvent.Repeat_);
      AppendMidiEvent;
    end;

    if (GriffEvent.NoteType > ntBass) then
    begin
      MidiEvent.command := $b0;
      MidiEvent.d1 := ControlPushPull + 4;
      MidiEvent.d2 := ord(GriffEvent.NoteType);
      if GriffEvents[iEvent].NoteType = ntRest then
      begin
        MidiEvent.var_len := GriffEvent.AbsRect.Width;
        Offset := GriffEvent.AbsRect.Right;
        AppendMidiEvent;
        MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull + 4;
        MidiEvent.d2 := ord(GriffEvent.NoteType);
      end;
      AppendMidiEvent;
      continue;
    end;

    // bereits aktiver Pitch?
    AmpelRect := GriffEvent.GetAmpelRec;
    if realGriffschrift then
    begin
      D := GriffEvent.GriffPitch
    end else begin
      D := GriffEvent.SoundPitch;
    end;
    if (GriffEvent.NoteType <= ntBass) and
       (Off[AmpelRect.row, D] > 0) then
    begin
      if Bass then
        MidiEvent.command := $81
      else
        MidiEvent.command := $80;
      MidiEvent.d1 := D;
      MidiEvent.d2 := $40;
      Off[AmpelRect.row, D] := 0;
      AppendMidiEvent;
    end;
    if (GriffEvent.NoteType > ntBass) then
      continue;

    // Balg-Notation ändert?
    if (not Bass or BassDiatonic) and
       not realGriffschrift then
    begin
      if GriffEvent.InPush <> IsInPush then
      begin
        IsInPush := not IsInPush;
        if Bass then
          MidiEvent.command := $b1
        else
          MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull;
        MidiEvent.d2 := 0;
        if IsInPush then
          MidiEvent.d2 := 127;
        AppendMidiEvent;
      end;
    end;

    if GriffEvent.Cross or
       (GriffEvent.GriffPitch <> GriffEvent.SoundPitch) then
    begin
      if not realGriffschrift then
      begin
        if Bass then
          MidiEvent.command := $b1
        else
          MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull + 1;
        if GriffEvent.Cross then
          inc(MidiEvent.d1);
        if realGriffschrift then
          MidiEvent.d2 := GriffEvents[iEvent].SoundPitch
        else
          MidiEvent.d2 := GriffEvents[iEvent].GriffPitch;
        AppendMidiEvent;
      end;
    end;

    if Bass then
    begin
      MidiEvent.command := $91;
      MidiEvent.d2 := $7f;
    end else begin
      MidiEvent.command := $90;
      MidiEvent.d2 := $6f;
    end;
    if realGriffschrift then
    begin
      MidiEvent.d1 := GriffEvent.GriffPitch
    end else begin
      MidiEvent.d1 := GriffEvent.SoundPitch;
    end;
    AmpelRect := GriffEvent.GetAmpelRec;
    Off[AmpelRect.row, MidiEvent.d1] := GriffEvent.AbsRect.Right;
    AppendMidiEvent;
  end;
  repeat
    smallest := GetSmallest;
    if smallest >= 0 then
      GenerateStops(smallest);
  until smallest < 0;
end;

class procedure TGriffArray.CopyGriffToNewMidi(var MidiEvents: TMidiEventArray;
                                       const GriffEvents: TGriffEventArray;
                                       Bass, BassDiatonic: boolean);
var
  Off: array [1..6, 0..127] of integer;
  RestOff: integer;
  Offset: integer;
  i, k: integer;
  smallest: integer;
  Ok, IsInPush: boolean;
  h: integer;
  AmpelRect: TAmpelRec;

  iEvent, iMidi: integer;
  MidiEvent: TMidiEvent;
  GriffEvent: TGriffEvent;

  function GetSmallest: integer;
  var
    i, r: integer;
  begin
    result := -1;
    if RestOff > 0 then
      result := RestOff;
    for r := 1 to 6 do
      for i := 0 to 127 do
        if (Off[r, i] > 0) and
           ((Off[r, i] < result) or (result = -1)) then
        begin
          result := Off[r, i];
        end;
  end;

  procedure AppendMidiEvent;
  begin
    SetLength(MidiEvents, iMidi+1);
    MidiEvents[iMidi] := MidiEvent;
    inc(iMidi);
    MidiEvent.Clear;
  end;

  procedure GenerateStops(pos: integer);
  var
    i, r: integer;
    Found: boolean;
    iM: integer;
  begin
    Found := RestOff = Pos;
    iM := iMidi;
    for r := 1 to 6 do
      for i := 0 to 127 do
        if (Off[r, i] > 0) and (pos <= Off[r, i]) then
        begin
          MidiEvent.command := $80 + r;
          MidiEvent.d1 := i;
          MidiEvent.d2 := $40;
          Off[r, i] := 0;
          Found := true;
          AppendMidiEvent;
        end;
    if Found then
    begin
      inc(MidiEvents[iM-1].var_len, pos - offset);
    end;
    if RestOff = Pos then
      RestOff := 0;
    offset := pos;
  end;

begin
  for k := 1 to 6 do
    for i := 0 to 127 do
      Off[k, i] := 0;
  RestOff := 0;

  Offset := 0;
  MidiEvent.Clear;
  iMidi := 0;
  AppendMidiEvent;

  IsInPush := true;
  MidiEvent.command := $b0;
  MidiEvent.d1 := ControlPushPull;
  MidiEvent.d2 := 0;
  if IsInPush then
    MidiEvent.d2 := 127;
  AppendMidiEvent;

  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    GriffEvent := GriffEvents[iEvent];

    if Bass <> (GriffEvent.NoteType = ntBass) then
      continue;

    repeat
      smallest := GetSmallest;
      Ok := (smallest > 0) and
            (smallest <= GriffEvent.AbsRect.Left);
      if Ok then
        GenerateStops(smallest);
    until not Ok;

    if (Offset < GriffEvent.AbsRect.Left) then  // Pause
    begin
      inc(MidiEvents[iMidi-1].var_len, GriffEvent.AbsRect.Left - Offset);
      Offset := GriffEvent.AbsRect.Left;
    end;

    // Wiederholungen
    if (GriffEvent.Repeat_ > rRegular) then
    begin
      MidiEvent.command := $b0;
      MidiEvent.d1 := ControlPushPull + 3;
      MidiEvent.d2 := ord(GriffEvent.Repeat_);
      AppendMidiEvent;
    end;

    if (GriffEvent.NoteType > ntBass) then
    begin
      MidiEvent.command := $b0;
      MidiEvent.d1 := ControlPushPull + 4;
      MidiEvent.d2 := ord(GriffEvent.NoteType);
      if GriffEvents[iEvent].NoteType = ntRest then
      begin
        MidiEvent.var_len := GriffEvent.AbsRect.Width;
        Offset := GriffEvent.AbsRect.Right;
        AppendMidiEvent;
        MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull + 4;
        MidiEvent.d2 := ord(GriffEvent.NoteType);
      end;
      AppendMidiEvent;
      continue;
    end;

    // bereits aktiver Pitch? (sollte nicht vorkommen)
    AmpelRect := GriffEvent.GetAmpelRec;
    h := GriffEvent.SoundPitch;
    if (GriffEvent.NoteType <= ntBass) and
       (Off[AmpelRect.row, h] > 0) then
    begin
      MidiEvent.command := $80 + AmpelRect.row;
      MidiEvent.d1 := h;
      MidiEvent.d2 := $40;
      Off[AmpelRect.row, h] := 0;
      AppendMidiEvent;
    end;

    if (GriffEvent.NoteType > ntBass) then
      continue;

    // Balg-Notation ändert?
    if (GriffEvent.NoteType = ntDiskant) or BassDiatonic then
    begin
      if GriffEvent.InPush <> IsInPush then
      begin
        IsInPush := not IsInPush;
        MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull;
        MidiEvent.d2 := 0;
        if IsInPush then
          MidiEvent.d2 := 127;
        AppendMidiEvent;
      end;
    end;

    if GriffEvent.NoteType = ntBass then
    begin
      if GriffEvent.Cross then
        MidiEvent.command := $96
      else
        MidiEvent.command := $95;
      MidiEvent.d2 := $7f;
    end else begin
      MidiEvent.command := $90 + AmpelRect.row;
      MidiEvent.d2 := $6f;
    end;
    MidiEvent.d1 := GriffEvent.SoundPitch;

    AmpelRect := GriffEvent.GetAmpelRec;
    Off[AmpelRect.row, MidiEvent.d1] := GriffEvent.AbsRect.Right;
    AppendMidiEvent;
  end;
  repeat
    smallest := GetSmallest;
    if smallest >= 0 then
      GenerateStops(smallest);
  until smallest < 0;
end;

class function TGriffArray.MakeStreamFromGriffEvents(
  const GriffEvents: TGriffEventArray; const Instrument: TInstrument;
  const DetailHeader: TDetailHeader; realGriffschrift: boolean): TMidiSaveStream;
var
  MidiEvents: TMidiEventArray;
  i: integer;
  MidiEvent: TMidiEvent;
  Header: TDetailHeader;
  MidiTracks: TTrackEventArray;
  k, q: integer;
begin
  result := TMidiSaveStream.Create;

  result.SetHead(DetailHeader.DeltaTimeTicks);
  result.AppendTrackHead;

  if realGriffschrift then
    MidiEvent.MakeMetaEvent(2, Copyrightreal)
  else
    MidiEvent.MakeMetaEvent(2, CopyrightGriff);
  result.AppendEvent(MidiEvent);

  Header := DetailHeader;
  if realGriffschrift then
  begin
    Header.CDur := 0;
    Header.Minor := false;
  end;
  result.AppendHeaderMetaEvents(Header);

  result.AppendTrackEnd(false);

  SetLength(MidiTracks, 2);
  for i := 0 to 1 do
  begin
    TGriffArray.CopyGriffToMidi(MidiEvents, GriffEvents,
                                i = 1, Instrument.BassDiatonic or (i = 0), realGriffschrift);

    // chromatischer Bass: alle Push/Pulls entfernen
    if (i = 1) and not Instrument.BassDiatonic then
    begin
      k := 0;
      while k < Length(MidiEvents)-1 do
      begin
        if MidiEvents[k].IsPushPull then
          TEventArray.RemoveIndex(k, MidiEvents)
        else
          inc(k);
      end;
    end;
    TEventArray.MakeNice(MidiEvents);

    MidiTracks[i] := MidiEvents;
    if (i = 0) or (Length(MidiEvents) > 1) then
    begin
      result.AppendTrackHead(MidiEvents[0].var_len);
      MidiEvents[0].var_len := 0;

      if i = 1 then
        MidiEvent.MakeMetaEvent(3, 'Bass')
      else
        MidiEvent.MakeMetaEvent(3, 'Melodie');
      result.AppendEvent(MidiEvent);
      if i = 0 then
      begin
        MidiEvent.command := $c0;
        MidiEvent.d1 := MidiInstrDiskant;
      end else begin
        MidiEvent.command := $c1;
        MidiEvent.d1 := MidiInstrBass;
      end;
      result.AppendEvent(MidiEvent);

      if Instrument.Name <> '' then
      begin
        MidiEvent.MakeMetaEvent(4, Instrument.Name);
        result.AppendEvent(MidiEvent);
      end;
      result.AppendEvents(MidiEvents);
      result.AppendTrackEnd(false);
    end
  end;
  result.Size := result.Position;
end;

class function TGriffArray.MakeNewStreamFromGriffEvents(
  const GriffEvents: TGriffEventArray;
  const Instrument: TInstrument;
  const DetailHeader: TDetailHeader): TMidiSaveStream;
var
  MidiEvents: array [0..1] of TMidiEventArray;
  i, j, l, h: integer;
  MidiEvent: TMidiEvent;
begin
  result := TMidiSaveStream.Create;

  result.SetHead(DetailHeader.DeltaTimeTicks);
  result.AppendTrackHead;

  MidiEvent.MakeMetaEvent(2, CopyrightNewGriff);
  result.AppendEvent(MidiEvent);

  result.AppendHeaderMetaEvents(DetailHeader);

  result.AppendTrackEnd(false);

  for i := 0 to 1 do
    TGriffArray.CopyGriffToNewMidi(MidiEvents[i], GriffEvents, i=1, Instrument.BassDiatonic);
  TEventArray.MergeTracks(MidiEvents[0], MidiEvents[1]);
  TEventArray.MakeNice(MidiEvents[0]);

  result.AppendTrackHead(MidiEvents[0][0].var_len);

  MidiEvent.MakeMetaEvent(4, Instrument.Name);
  result.AppendEvent(MidiEvent);
  MidiEvent.Clear;
  MidiEvent.command := $c0;
  for i := 0 to 7 do
  begin
    if i < 5 then
      MidiEvent.d1 := MidiInstrDiskant
    else
      MidiEvent.d1 := MidiInstrBass;
    result.AppendEvent(MidiEvent);
    inc(MidiEvent.command);
  end;

  for i := 1 to Length(MidiEvents[0])-1 do
    result.AppendEvent(MidiEvents[0][i]);

  result.AppendTrackEnd(true);

  {      for j := l to h do
      begin
        MidiEvent.command := $c0 + j;
        MidiEvent.d1 := MidiInstr;
        result.AppendEvent(MidiEvent);
      end;

      if Instrument.Name <> '' then
      begin
        MidiEvent.MakeMetaEvent(4, Instrument.Name);
        result.AppendEvent(MidiEvent);
      end;
      result.AppendEvents(MidiEvents);
      result.AppendTrackEnd(false);
    end
  end;      }
end;

class function TGriffArray.MakeSimpleFromDataStream(
  const GriffEvents: TGriffEventArray;
  const Instrument: TInstrument;
  const DetailHeader: TDetailHeader;
  realGriffschrift: boolean): TSimpleDataStream;
var
  Stream: TMidiSaveStream;
begin
  result := nil;
  Stream := MakeStreamFromGriffEvents(GriffEvents, Instrument, DetailHeader, realGriffschrift);
  if Stream <> nil then
  try
    result := TSimpleDataStream.MakeSimpleDataStream(Stream);
  finally
    Stream.Free;
  end;
end;


class function TGriffArray.CorrectSoundPitch(var GriffEvents: TGriffEventArray;
                                             const Instrument: TInstrument): boolean;
var
  i, p: integer;
begin
  result := true;
  for i := 0 to Length(GriffEvents)-1 do
    if GriffEvents[i].NoteType in [ntDiskant, ntBass] then
    begin
      p := GriffEvents[i].GetSoundPitch(Instrument);
      if p <> GriffEvents[i].SoundPitch then
        result := false;
      if p > 0 then
        GriffEvents[i].SoundPitch := p;
    end;
end;

end.


