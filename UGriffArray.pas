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
  SysUtils, Types,
  umidi,
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
                                       BassDiatonic: boolean);
    class function MakeStreamFromGriffEvents(const GriffEvents: TGriffEventArray;
                                   const Instrument: TInstrument;
                                   const DetailHeader: TDetailHeader;
                                   realGriffschrift: boolean): TMidiSaveStream;
    class function MakeNewStreamFromGriffEvents(const GriffEvents: TGriffEventArray;
                                      const Instrument: TInstrument;
                                      const DetailHeader: TDetailHeader): TMidiSaveStream;

    class function CorrectSoundPitch(var GriffEvents: TGriffEventArray;
                                     const Instrument: TInstrument): boolean;
    class function MakeSimpleGriff(const GriffEvents: TGriffEventArray; DiatonicBass: boolean): TSimpleDataStream;
    class function MakeGriffEvents(var SimpleGriffEvents: TSimpleDataStream; DiatonicBass: boolean = false): TGriffEventArray;
    class function Compare(const Griff1, Griff2: TGriffEventArray): integer;
  end;

implementation


class procedure TGriffArray.SortGriffEvents(var GriffEvents: TGriffEventArray; var Selected: integer);

  procedure Exchange(i, j: integer);
  var
    Event: TGriffEvent;
  begin
    if i = j then
      exit;

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
  i, k, j, n: integer;
  UsedEvents: integer;
  RepeatStart, RepeatStop: TRepeat;
begin
  UsedEvents := Length(GriffEvents);
  for i := 0 to UsedEvents-2 do
    for k := i + 1 to UsedEvents-1 do
    begin
      if (GriffEvents[i].AbsRect.Left > GriffEvents[k].AbsRect.Left) or      // beginnt später
         ((GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and    // ist länger
          (GriffEvents[i].AbsRect.Right > GriffEvents[k].AbsRect.Right)) or
         ((GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and    // ist höher
          (GriffEvents[i].AbsRect.Right = GriffEvents[k].AbsRect.Right) and
          (GriffEvents[i].AbsRect.Top > GriffEvents[k].AbsRect.Top)) then    // Bass ist mit -1 am Anfang
      begin
        Exchange(i, k);
      end;
    end;

  i := 0;
  while (i < UsedEvents-1) do
  begin
    k := i+1;
    while (k < UsedEvents) and
          (GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) and
          (GriffEvents[i].AbsRect.Right = GriffEvents[k].AbsRect.Right) do
      inc(k);

    // tiefer Bass vor hohem (Cross) Bass
    j := i;
    while (j < k) do
      if (GriffEvents[j].NoteType = ntBass) and not GriffEvents[j].Cross then
      begin
        Exchange(i, j);
        inc(i);
        break;
      end else
        inc(j);

    // innerhalb von i bis (k-1) verschieben (ordnen)
    while i < k do
    begin
      for j := i+1 to k-1 do
        if (GriffEvents[i].GriffPitch > GriffEvents[j].GriffPitch) and
           (GriffEvents[j].NoteType = ntDiskant) then
        begin
          Exchange(i, j);
        end;
      inc(i);
    end;
    // i = k
  end;

  i := 0;
  while i < UsedEvents-1 do
  begin
    // Noten mit gleichem Left ermitteln
    k := i+1;
    while (k < UsedEvents) and
          (GriffEvents[i].AbsRect.Left = GriffEvents[k].AbsRect.Left) do
      inc(k);

    // i bis k-1: left gleich
    j := i;
    while j < k-1 do
      if GriffEvents[j].Repeat_ in [rStart, rVolta1Start, rVolta2Start] then
        break
      else
        inc(j);

    if (j <> i) and (j < k) then
    begin
      GriffEvents[i].Repeat_ := GriffEvents[j].Repeat_;
      GriffEvents[j].Repeat_ := rRegular;
    end;
    i := k;
  end;

  i := 0;
  while i < UsedEvents do
  begin
    if GriffEvents[i].Repeat_ in [rStop, rVolta1Stop, rVolta2Stop] then
    begin
      // Noten mit gleichem Right ermitteln
      k := i;
      j := i + 1;
      while (j < UsedEvents) and (GriffEvents[j].AbsRect.Left < GriffEvents[i].AbsRect.Right)  do
      begin
        if GriffEvents[i].AbsRect.Right = GriffEvents[j].AbsRect.Right then
          k := j;
        inc(j);
      end;
      if k <> i then // k: Index zum letzten Right
      begin
        GriffEvents[k].Repeat_ := GriffEvents[i].Repeat_;
        GriffEvents[i].Repeat_ := rRegular;
      end;
      i := k + 1;
    end else
      inc(i);
  end;
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
  PushPullUndef: boolean;

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
        if (Off[r, i] > 0) and (pos >= Off[r, i]) then
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

  PushPullUndef := true;

  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    GriffEvent := GriffEvents[iEvent];

    // Im Bass-Track sind nur Bassnoten
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
      MidiEvent.Clear;
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
      if (GriffEvent.InPush <> IsInPush) or PushPullUndef then
      begin
        IsInPush := GriffEvent.InPush;
        if Bass then
          MidiEvent.command := $b1
        else
          MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull;
        MidiEvent.d2 := 0;
        if IsInPush then
          MidiEvent.d2 := 127;
        AppendMidiEvent;
        PushPullUndef := false;
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
                                       BassDiatonic: boolean);
var
  Off: array [1..6, 0..127] of integer;
  Offset: integer;
  i, k: integer;
  smallest: integer;
  Ok, IsInPush, FirstPushPull: boolean;
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
    Found := false;
    iM := iMidi;
    for r := 1 to 6 do
      for i := 0 to 127 do
        if (Off[r, i] > 0) and (pos >= Off[r, i]) then
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
    offset := pos;
  end;

begin
  for k := 1 to 6 do
    for i := 0 to 127 do
      Off[k, i] := 0;

  Offset := 0;
  MidiEvent.Clear;
  iMidi := 0;
  AppendMidiEvent;

  IsInPush := true;
  FirstPushPull := true;
  MidiEvent.command := $b0;

  for iEvent := 0 to Length(GriffEvents)-1 do
  begin
    GriffEvent := GriffEvents[iEvent];
    AmpelRect := GriffEvent.GetAmpelRec;

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

    if (GriffEvent.NoteType > ntBass) then  // ntRest, ntRepeat
    begin
      MidiEvent.command := $b0;
      MidiEvent.d1 := ControlPushPull + 4;
      MidiEvent.d2 := ord(GriffEvent.NoteType);
      if GriffEvents[iEvent].NoteType = ntRest then
      begin
        MidiEvent.var_len := GriffEvent.AbsRect.Width;
        Offset := GriffEvent.AbsRect.Right;
      end;
      AppendMidiEvent;
      continue;
    end;

    // bereits aktiver Pitch? (sollte nicht vorkommen)
    h := GriffEvent.SoundPitch;
    if (GriffEvent.NoteType <= ntBass) and
       (Off[AmpelRect.row, h] > 0) then
    begin
      MidiEvent.command := $80 + AmpelRect.row;  // Off
      MidiEvent.d1 := h;
      MidiEvent.d2 := $40;
      Off[AmpelRect.row, h] := 0;
      AppendMidiEvent;
    end;

    // Balg-Notation ändert?
    if (GriffEvent.NoteType = ntDiskant) or BassDiatonic then
    begin
      if (GriffEvent.InPush <> IsInPush) or FirstPushPull then
      begin
        IsInPush := GriffEvent.InPush;
        MidiEvent.command := $b0;
        MidiEvent.d1 := ControlPushPull;
        MidiEvent.d2 := 0;
        if IsInPush then
          MidiEvent.d2 := 127;
        AppendMidiEvent;
        FirstPushPull := false;
      end;
    end;

    MidiEvent.command := $90 + AmpelRect.row;
    MidiEvent.d1 := GriffEvent.SoundPitch;
    if GriffEvent.NoteType = ntBass then
      MidiEvent.d2 := $7f
    else
      MidiEvent.d2 := $6f;

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

  result.SetHead(DetailHeader.TicksPerQuarter);
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
                                i = 1, Instrument.BassDiatonic, realGriffschrift);

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
  MidiEvents: TMidiEventArray;
  i, j, l, h: integer;
  MidiEvent: TMidiEvent;
begin
  result := TMidiSaveStream.Create;

  result.SetHead(DetailHeader.TicksPerQuarter);
  result.AppendTrackHead;

  MidiEvent.MakeMetaEvent(2, CopyrightNewGriff);
  result.AppendEvent(MidiEvent);

  result.AppendHeaderMetaEvents(DetailHeader);

  result.AppendTrackEnd(false);

  TGriffArray.CopyGriffToNewMidi(MidiEvents, GriffEvents, Instrument.BassDiatonic);

  result.AppendTrackHead(MidiEvents[0].var_len);

  MidiEvent.MakeMetaEvent(4, Instrument.Name);
  result.AppendEvent(MidiEvent);
  MidiEvent.Clear;                // Instrumente für die ersten acht Kanäle
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

  for i := 1 to Length(MidiEvents)-1 do
    result.AppendEvent(MidiEvents[i]);

  result.AppendTrackEnd(true);

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


class function TGriffArray.MakeSimpleGriff(const GriffEvents: TGriffEventArray; DiatonicBass: boolean): TSimpleDataStream;
var
  i: integer;
  PushPull: boolean;


  function Duration: AnsiString;
  begin
    with GriffEvents[i]  do
      result := Format('Duration %4d', [AbsRect.Right - AbsRect.left]);
  end;

  procedure AppendRepeat(Rep: TRepeat; Event: TGriffEvent);
  begin
    result.WriteAnsiString('Repeat ' + IntToStr(ord(rep)) + '  ' + Duration);
    result.writeln;
    result.WriteAnsiString(Format('%7d  ', [Event.AbsRect.Left]));
 end;

begin
  result := TSimpleDataStream.Create;
  PushPull := false;
  for i := 0 to Length(GriffEvents)-1 do
  begin
    result.WriteAnsiString(Format('%7d  ', [GriffEvents[i].AbsRect.Left]));
    with GriffEvents[i] do
     case NoteType of
     ntDiskant, ntBass:
       begin
         if Repeat_ <> rRegular then
           AppendRepeat(Repeat_, GriffEvents[i]);

         if ((NoteType = ntDiskant) or DiatonicBass) and
            (InPush <> PushPull) then
         begin
           if InPush then
             result.WritelnAnsiString('Push')
           else
             result.WritelnAnsiString('Pull');
           PushPull := InPush;
           result.WriteAnsiString(Format('%7d  ', [AbsRect.Left]));
         end;

         if (NoteType = ntDiskant) then
           result.WriteAnsiString('Sound')
         else
           result.WriteAnsiString('Bass ');
         result.WriteAnsiString(Format(' %2d  Griff %2d  Cross %d  %5s, %6d',
           [SoundPitch, GriffPitch, ord(Cross), Duration, i]));
         result.Writeln;
       end;
    ntRepeat: AppendRepeat(rStart, GriffEvents[i]);
    ntRest:
      begin
        if Repeat_ <> rRegular then
           AppendRepeat(Repeat_, GriffEvents[i]);
        result.WritelnAnsiString(Format('Rest   %s  Top %d', [Duration, AbsRect.Top]));
      end;
    end;
  end;
  result.SetSize(result.Position);
end;

class function TGriffArray.MakeGriffEvents(var SimpleGriffEvents: TSimpleDataStream;
                                             DiatonicBass: boolean): TGriffEventArray;
var
  GriffEvent: TGriffEvent;
  Push: boolean;
  s: AnsiString;
  n: integer;
  i, k: integer;
  rect1, rect2: TRect;

  procedure AppendEvent;
  begin
    SetLength(result, Length(Result)+1);
    result[Length(Result)-1] := GriffEvent;
  end;

begin
  SetLength(result, 0);
  SimpleGriffEvents.Position := 0;
  repeat
    GriffEvent.Clear;
    GriffEvent.AbsRect.Left := SimpleGriffEvents.ReadNumber;
    s := SimpleGriffEvents.ReadString;
    if s = 'Pull' then
      Push := false
    else
    if s = 'Push' then
      Push := true
    else begin
      if (s = 'Bass') or (s = 'Sound') then
      begin
        if s = 'Bass' then
        begin
          GriffEvent.NoteType := ntBass;
          if DiatonicBass then
            GriffEvent.InPush := Push
          else
            GriffEvent.InPush := true;
        end else begin
          GriffEvent.NoteType := ntDiskant;
          GriffEvent.InPush := Push;
        end;
        GriffEvent.SoundPitch := SimpleGriffEvents.ReadNumber;
        SimpleGriffEvents.ReadString; // 'Griff'
        GriffEvent.GriffPitch := SimpleGriffEvents.ReadNumber;
        SimpleGriffEvents.ReadString; // 'Cross'
        n := SimpleGriffEvents.ReadNumber;
        if n = 1 then
          GriffEvent.Cross := true;
        SimpleGriffEvents.ReadString; // 'Duration'
        n := SimpleGriffEvents.ReadNumber;
        GriffEvent.AbsRect.Right := GriffEvent.AbsRect.Left + n;

        if GriffEvent.NoteType = ntDiskant then
        begin
          n := GetPitchLine(GriffEvent.GriffPitch);
          GriffEvent.AbsRect.Top := n;
        end else
          GriffEvent.AbsRect.Top := -1;
      end else
      if s = 'Repeat' then
      begin
        GriffEvent.NoteType := ntRepeat;
        GriffEvent.Repeat_ := TRepeat(SimpleGriffEvents.ReadNumber);
        SimpleGriffEvents.ReadString; // 'Duration'
        n := SimpleGriffEvents.ReadNumber;
        GriffEvent.AbsRect.Right := GriffEvent.AbsRect.Left + n;
      end else
      if s = 'Rest' then
      begin
        GriffEvent.NoteType := ntRest;
        SimpleGriffEvents.ReadString; // 'Duration'
        n := SimpleGriffEvents.ReadNumber;
        GriffEvent.AbsRect.Right := GriffEvent.AbsRect.Left + n;
        SimpleGriffEvents.ReadString; // 'Top'
        n := SimpleGriffEvents.ReadNumber;
        GriffEvent.AbsRect.Top := n;
        GriffEvent.AbsRect.Height := 1;
      end;
      GriffEvent.AbsRect.Height := 1;

      AppendEvent;
    end;
    SimpleGriffEvents.ReadLine;
  until SimpleGriffEvents.EOF;

  i := 0;
  k := 0;
  while i < Length(result) do
  begin
    // Repeat_ von Repeat beim Nachfolger einsetzen
    if (result[i].NoteType = ntRepeat) and
       (i < Length(result)-1) then
    begin
      rect1 := result[i].AbsRect;
      rect2 := result[i+1].AbsRect;
      if (rect1.left = rect2.Left) and (rect1.right = rect2.right) then
      begin
        inc(i);
        result[i].Repeat_:= result[i-1].Repeat_;
      end;
    end;
    result[k] := result[i];
    inc(i);
    inc(k);
  end;
  SetLength(result, k);
end;

class function TGriffArray.Compare(const Griff1, Griff2: TGriffEventArray): integer;

  function Comp(const Event1, Event2: TGriffEvent): boolean;
  begin
    result := Event1.IsEqual(Event2);
    if not result then
      result := (Event1.NoteType = ntRest) and (Event2.NoteType = ntRest) and
                (Event1.AbsRect.left = Event2.AbsRect.left) and
                (Event1.AbsRect.right = Event2.AbsRect.right);
  end;

begin
  result := 0;
  while (result < Length(Griff1)) and (result < Length(Griff2)) and
        Comp(Griff1[result], Griff2[result]) do
    inc(result);

  if (result = Length(Griff1)) and (result = Length(Griff2)) then
    result := -1;

end;

end.


