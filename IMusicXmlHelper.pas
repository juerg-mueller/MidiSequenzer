function TSheetMusicHelper.SaveToMusicXML(const FileName: string; GriffOnly: boolean): boolean;
const
  UseColors = true;
var
  MeasureNode: KXmlNode;
  SaveRec: TSaveRec;

  function AddMeasure(Nr: integer; StaffNode: KXmlNode): KXmlNode;
  begin
    StaffNode.AppendChildNode('', Format(' measure %d ', [Nr]));
    result := StaffNode.AppendChildNode('measure');
    result.AppendAttr('number', IntToStr(Nr));
  end;

  procedure NeuerTakt(PartNode: KXmlNode);
  var
    Child, Child1: KXmlNode;
  begin
    with SaveRec do
      begin
      if SaveRec.TaktNr < SaveRec.offset div SaveRec.Takt then
      begin
  {$if defined(CONSOLE)}
        if t32takt*quarterNote <> 8*Takt then
          writeln('falsche Taktlänge Takt ', TaktNr);
  {$endif}
        if LastRepeat = rStop then
          LastRepeat := rVolta1Stop;
        if LastRepeat in [rVolta1Stop, rVolta2Stop, rStop] then
        begin
          Child := MeasureNode.AddChild('barline');
          Child.Attributes['location'] := 'right';
          Child1 := Child.AddChild('bar-style');
          if LastRepeat = rVolta2Stop then
            Child1.Value := 'light-light'
          else
            Child1.Value := 'light-heavy';
          Child1 := Child.AddChild('ending');
          if LastRepeat <> rStop then
          begin
            if LastRepeat = rVolta1Stop then
              Child1.Attributes['number'] := '1'
            else
              Child1.Attributes['number'] := '2';
          end;
          if LastRepeat = rVolta2Stop then
            Child1.Attributes['type'] := 'discontinue'
          else
            Child1.Attributes['type'] := 'stop';
          if LastRepeat = rVolta1Stop then
          begin
            Child1 := Child.AddChild('repeat');
            Child1.Attributes['direction'] := 'backward';
          end;
          LastRepeat := rRegular;
        end;
        t32takt := 0;
        inc(MeasureNr);
        MeasureNode := AddMeasure(MeasureNr, PartNode);
        TaktNr := offset div Takt;
      end;

      if {(t32takt = 0) and} (LastRepeat in [rStart, rVolta1Start, rVolta2Start]) {and
         (MeasureNode.ChildNodes.Count = 0)} then
      begin
        Child := MeasureNode.AddChild('barline');
        Child.Attributes['location'] := 'left';
        if LastRepeat = rStart then
        begin
          Child1 := Child.AddChild('bar-style');
          Child1.Value := 'heavy-light';
          Child1 := Child.AddChild('repeat');
          Child1.Attributes['direction'] := 'forward';
        end else begin
          Child1 := Child.AddChild('ending');
          if LastRepeat = rVolta1Start then
            Child1.Attributes['number'] := '1'
          else
            Child1.Attributes['number'] := '2';
          Child1.Attributes['type'] := 'start';
        end;
        LastRepeat := rRegular;
      end;
    end;
  end;

  procedure AppendStaff(UseGriff: boolean; PartNode: KXmlNode);

    procedure SetColor(NoteNode: KXmlNode; const GriffEvent: TGriffEvent);
    var
      Child: KXmlNode;
    begin
      with GriffEvent do
      begin
      //  Child := NoteNode.AddChild('accidental');
      //  Child.Value := 'double-sharp';
        Child := NoteNode.AddChild('notehead');
        if Cross then
          Child.Value := 'x'
        else
          Child.Value := 'normal';
        if not UseColors then
          Child.Attributes['color'] := '#000000'
        else
        if InPush then
//          Child.Attributes['color'] := '#000000'
        else
          Child.Attributes['color'] := '#0000FF';
      end;
    end;

    procedure SetNote(NoteNode: KXmlNode; UseChord, dot: boolean;
                      sLen, sDur: string;  const GriffEvent: TGriffEvent);
    const
      stepSharp: array [0..11] of char = ('C', 'C', 'D', 'D', 'E', 'F',
                                          'F', 'G', 'G', 'A', 'B', 'B');
      stepFlat:  array [0..11] of char = ('C', 'D', 'D', 'E', 'E', 'F',
                                          'G', 'G', 'A', 'A', 'B', 'B');
    var
      Child, Child1: KXmlNode;
    begin
      with GriffEvent, SaveRec do
      begin
        if UseChord then
          NoteNode.AddChild('chord');
        if (appoggiatura = tieStart) and (appoggNr = 0) then
        begin
          NoteNode.AddChild('grace');
          inc(appoggNr);
        end;
        Child := NoteNode.AddChild('pitch');
        Child1 := Child.AddChild('step');
        if UseGriff then
          Child1.Value := stepSharp[griffPitch mod 12]
        else begin
          if Instrument.Sharp then
            Child1.Value := stepSharp[soundPitch mod 12]
          else
            Child1.Value := stepFlat[soundPitch mod 12];
          if (soundPitch mod 12) in [1, 3, 6, 8, 10] then
          begin
            Child1 := Child.AddChild('alter');
            if Instrument.Sharp then
              Child1.Value := '+1'
            else
              Child1.Value := '-1';
          end;
        end;
        Child1 := Child.AddChild('octave');
        if UseGriff then
          Child1.Value := IntToStr(griffPitch div 12 - 1)
        else
          Child1.Value := IntToStr(soundPitch div 12 - 1);
        if (appoggiatura = tieOff) or (appoggNr <> 1) then
        begin
          Child := NoteNode.AddChild('duration');
          Child.Value := sDur;
          Child := NoteNode.AddChild('type');
          Child.Value := sLen;
          if dot then
            NoteNode.AddChild('dot');
        end else begin
          Child := NoteNode.AddChild('type');
          Child.Value := sLen;
        end;
      end;
    end;

    procedure ShowPedal(Push: boolean);
    var
      Child, Child1, Child2: KXmlNode;
    begin
      Child := MeasureNode.AddChild('direction');
      Child.Attributes['placement'] := 'below';
      Child1 := Child.AddChild('direction-type');
      Child2 := Child1.AddChild('pedal');
      if Push then
        Child2.Attributes['type'] := 'start'
      else
        Child2.Attributes['type'] := 'stop';
      Child2.Attributes['line'] := 'yes';
      Child2.Attributes['default-y'] := '-80.00';
    end;

    procedure AddRest(Len: integer);
    var
      RestNode, Child: KXmlNode;
    begin
      with SaveRec do
      begin
        t := 8*Len div quarterNote;
        while t > 0 do
        begin
          t1 := t;
          RestNode := MeasureNode.AddChild('note');
          RestNode.AddChild('rest');
          sLen := GetLen(t, dot, t32takt);
          Child := RestNode.AddChild('duration');
          if dot then
            RestNode.AddChild('dot');
          Child.Value := IntToStr(3*(t1-t));
          inc(t32takt, t1 - t);
        end;
        inc(offset, Len);
        NeuerTakt(PartNode);
      end;
    end;

  var
    i: integer;
    AttrNode, NoteNode, Child, Child1, Child2: KXmlNode;
  begin
    SaveRec.Clear;
    with SaveRec do
    begin
    MeasureNr := 1;
    MeasureNode := AddMeasure(MeasureNr, PartNode);
    AttrNode := MeasureNode.AddChild('attributes');
    Child := AttrNode.AddChild('divisions');
    Child.Value := '24';
    if not UseGriff and
       ((Instrument.Name = 'Steirische BEsAsDes') or (Instrument.Name = 'b-Oergeli')) then
    begin
      Child := AttrNode.AddChild('key');
      Child1 := Child.AddChild('fifths');
      Child1.Value := '-3';
      Child1 := Child.AddChild('mode');
      Child1.Value := 'minor';
    end;
    if not UseGriff then
    begin
      Child := AttrNode.AddChild('time');
      Child1 := Child.AddChild('beats');
      Child1.Value := IntToStr(GriffHeader.Details.measureFact);
      Child1 := Child.AddChild('beat-type');
      Child1.Value := IntToStr(GriffHeader.Details.measureDiv);

      Child := MeasureNode.AddChild('direction');
      Child.Attributes['directive'] := 'yes';
      Child.Attributes['placement'] := 'above';
      Child1 := Child.AddChild('direction-type');
      Child2 := Child1.AddChild('metronome');
      Child1 := Child2.AddChild('beat-unit');
      Child1.Value := 'quarter';
      Child1 := Child2.AddChild('per-minute');
      Child1.Value := IntToStr(GriffHeader.Details.beatsPerMin);
      Child1 := Child.AddChild('sound');
      Child1.Attributes['tempo'] := IntToStr(GriffHeader.Details.beatsPerMin);
    end;

    Takt := GriffHeader.Details.DeltaTimeTicks;
    if GriffHeader.Details.measureDiv = 8 then
      Takt := Takt div 2;
    Takt := GriffHeader.Details.measureFact*Takt;

    TaktNr := 0;
    Offset := 0;
    LastRepeat := rRegular;
    iEvent := 0;
    while iEvent < UsedEvents do
      if (GriffEvents[iEvent].NoteType = ntDiskant) or
         (GriffEvents[iEvent].Repeat_ <> rRegular) then
      begin
        offset := GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Left);
        break;
      end else
        inc(iEvent);

    t32takt := 8*(offset mod Takt) div quarterNote;
    while iEvent < UsedEvents do
    begin
      NeuerTakt(PartNode);
      if GriffEvents[iEvent].NoteType > ntBass then
      begin
        if GriffEvents[iEvent].Repeat_ <> rRegular then
          LastRepeat := GriffEvents[iEvent].Repeat_;
        NeuerTakt(PartNode);
        if GriffEvents[iEvent].NoteType = ntRest then
        begin
          Len := GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Right - offset);
          dot := false;
          if GriffEvents[iEvent].Repeat_ in [rStop, rVolta1Stop, rVolta2Stop] then
            LastRepeat := GriffEvents[iEvent].Repeat_;
          AddRest(Len);
        end;
      end else
      if GriffEvents[iEvent].NoteType in [ntDiskant, ntBass] then
      begin
        // Pausen einfügen
        while (SaveRec.Rest(GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Left - offset), true)) do
              AddRest(Len);

        if GriffEvents[iEvent].Repeat_ <> rRegular then
          LastRepeat := GriffEvents[iEvent].Repeat_;
        if GriffEvents[iEvent].NoteType = ntDiskant then
        begin
          // Push-Striche
          if UseGriff and (InPu <> GriffEvents[iEvent].InPush) then
          begin
            ShowPedal(GriffEvents[iEvent].InPush);
            InPu := GriffEvents[iEvent].InPush;
          end;

          if SetTriolen(SaveRec) then
          begin
            t := offset;
            tupletNr := 1;
            while (tupletNr <= 3) and (iEvent < UsedEvents) do
            begin
              if GriffEvents[iEvent].NoteType = ntDiskant then
              begin
                NoteNode := MeasureNode.AddChild('note');
                SetNote(NoteNode, false, false, sLen, sDur, GriffEvents[iEvent]);
                Child := NoteNode.AddChild('time-modification');
                Child1 := Child.AddChild('actual-notes');
                Child1.Value := '3';
                Child1 := Child.AddChild('normal-notes');
                Child1.Value := '2';
                if UseGriff then
                  SetColor(NoteNode, GriffEvents[iEvent]);
                Child := NoteNode.AddChild('beam');
                Child.Attributes['number'] := '1';
                case tupletNr of
                  1: Child.Value := 'begin';
                  2: Child.Value := 'continue';
                  3: Child.Value := 'end';
                end;
                Child := NoteNode.AddChild('notations');
                if tupletNr in [1, 3] then
                begin
                  Child1 := Child.AddChild('tuplet');
                  Child1.Attributes['number'] := '1';
                  if tupletNr = 1 then
                    Child1.Attributes['type'] := 'start'
                  else
                    Child1.Attributes['type'] := 'stop';
                end;
                if tupletNr = 3 then
                begin
                  offset := GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Right);
                  inc(t32takt, 8*offset div quarterNote);
                end;
                inc(tupletNr);
              end;
              inc(iEvent);
            end;
            NeuerTakt(PartNode);
            continue;
          end;

          SetIEnd(SaveRec);

          tie := tieOff;
          while GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Right - offset) > 0 do
          begin
            Len := GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Right - offset);
            t1 := Len;
            tieMeasures := 0;
            if SaveRec.LimitToTakt and (t1 > Len) then
            begin
              tieMeasures := 1;
              case Tie of
                tieOff: Tie := tieStart;
                tieStart: Tie := tieMitte;
              end;
            end else
            if Tie <> tieOff then
              tie := tieStop;

            t := 8*Len div quarterNote;
            while t > 0 do
            begin
              i := iEvent;
              t1 := t;
              self.IsAppoggiatura(SaveRec);

              sLen := GetLen(t, dot, t32takt);
              sDur := IntToStr(3*(t1-t));
              inc(t32takt, t1 - t);

              while i <= iEnd do
              begin
                if GriffEvents[i].NoteType = ntDiskant then
                begin
                  NoteNode := MeasureNode.AddChild('note');
                  SetNote(NoteNode, i > iEvent, dot, sLen, sDur, GriffEvents[i]);
                 { if appoggiatura then
                  begin
                    if (appoggNr <= 2) then
                    begin
                      tie := true;
                      if (appoggNr = 1) then
                        tieStop := false
                      else
                        tieStop := true;
                      inc(appoggNr);
                    end else
                      tie := false;
                  end; }
                  if UseGriff then
                    SetColor(NoteNode, GriffEvents[i]);
            {      if Tie <> tieOff then
                  begin
                    Child := NoteNode.AddChild('notations');
                    if appoggiatura then
                      Child := child.AddChild('slur')
                    else
                      Child := child.AddChild('tied');
                    if tieStop then
                      Child.Attributes['type'] := 'stop'
                    else
                      Child.Attributes['type'] := 'start';
                    if appoggiatura then
                    begin
                      Child.Attributes['number'] := '1';
                    end;
                  end;
                  if (i > iEvent) and appoggiatura then
                  begin
                    appoggiatura := false;
                    tie := tieOff;
                  end;}
                end;
                inc(i);
              end;
            end;
            inc(offset, Len);
            if t32takt*quarterNote >= 8*Takt then
              NeuerTakt(PartNode);
          end;
        end;
      end;
      inc(iEvent);
    end;
    if UseGriff and InPu then
      ShowPedal(false);
    end;
  end;

var
  Root, Child, Child1, Child2, Child3: KXmlNode;
  s: string;
begin

  Root := NewXmlNode('score-partwise');
  Root.Attributes['version'] := '3.1';
  Child := Root.AddChild('work');
  Child := Child.AddChild('work-title');
  s := ExtractFilename(FileName);
  SetLength(s, Length(s) - Length(ExtractFileExt(s)));
  Child.Value := s;

  Child := Root.AddChild('identification');
  Child1 := Child.AddChild('creator');
  Child1.Attributes['type'] := 'composer';
  Child1.Value := String(Instrument.Name);
  Child1 := Child.AddChild('encoding');
  Child2 := Child1.AddChild('software');
  Child2.Value := 'MidiSequenzer';

  Child := Root.AddChild('part-list');

  Child1 := Child.AddChild('score-part');
  Child1.Attributes['id'] := 'P1';
  Child2 := Child1.AddChild('part-name');
  Child2.Value := 'klingend';
  Child2 := Child1.AddChild('part-abbreviation');
  Child2.Value := 'kl.';
  Child2 := Child1.AddChild('score-instrument');
  Child2.Attributes['id'] := 'P1-I1';
  Child3 := Child2.AddChild('instrument-name');
  Child3.Value := 'accordion';
  Child2 := Child1.AddChild('midi-device');
  Child2.Attributes['id'] := 'P1-I1';
  Child2.Attributes['port'] := '1';
  Child2 := Child1.AddChild('midi-instrument');
  Child2.Attributes['id'] := 'P1-I1';
  Child3 := Child2.AddChild('midi-channel');
  Child3.Value := '1';
  Child3 := Child2.AddChild('midi-program');
  Child3.Value := '22';
  Child3 := Child2.AddChild('volume');
  Child3.Value := '80';

  if not GriffOnly then
  begin
    Child1 := Child.AddChild('score-part');
    Child1.Attributes['id'] := 'P2';
    Child2 := Child1.AddChild('part-name');
    Child2.Value := 'Griffschrift';
    Child2 := Child1.AddChild('part-abbreviation');
    Child2.Value := 'Gr.';
    Child2 := Child1.AddChild('score-instrument');
    Child2.Attributes['id'] := 'P2-I1';
    Child3 := Child2.AddChild('instrument-name');
    Child3.Value := 'accordion';
    Child2 := Child1.AddChild('midi-device');
    Child2.Attributes['id'] := 'P2-I1';
    Child2.Attributes['port'] := '2';
    Child2 := Child1.AddChild('midi-instrument');
    Child2.Attributes['id'] := 'P2-I1';
    Child3 := Child2.AddChild('midi-channel');
    Child3.Value := '2';
    Child3 := Child2.AddChild('midi-program');
    Child3.Value := '2';
    Child3 := Child2.AddChild('volume');
    Child3.Value := '0';
  end;

  ////////////////////////////// part

  if not GriffOnly then
  begin
    Child := Root.AddChild('part');
    Child.Attributes['id'] := 'P1';
    AppendStaff(false, Child);

    Child := Root.AddChild('part');
    Child.Attributes['id'] := 'P2';
    AppendStaff(true, Child);
  end else begin
    Child := Root.AddChild('part');
    Child.Attributes['id'] := 'P1';
    AppendStaff(true, Child);
  end;

  result := Root.SaveToXmlFile(FileName,
      '<?xml version="1.0" encoding="UTF-8" standalone="no"?>'#13#10 +
      '<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 2.0 Partwise//EN" "http://www.musicxml.org/dtds/partwise.dtd">'#13#10
     );
end;

function TSheetMusicHelper.LoadFromMusicXML(FileName: string): boolean;
const
  cdur: string = 'C.D.EF.G.AB.';
var
  i, k, l, m, o, q: integer;
  Offset, delta: integer;
  default_x, x: double;
  name, step, octave: string;
  chord, tieStop: boolean;
  Root, Part, Measure, Note, Child, Child1: KXmlNode;
  event: TGriffEvent;
  NextRepeat: TRepeat;
  repStop: boolean;
  repForward: (repNo, repForw, repBackw);
  Volta: integer;
  Outp: TBytes;
  Ok: boolean;
{$ifdef mswindows}
  Zip_: System.Zip.TZipFile;
{$endif}

  procedure DoChord(x: double);
  begin
    inc(offset, delta);
    delta := 0;
    default_x := x;
  end;

begin
  Root := nil;
{$ifdef dcc}
  if ExtractFileExt(Filename) = '.mxl' then
  begin
    Zip_ := TZipFile.Create;
    try
      Zip_.Open(Filename, zmRead);
      SetLength(Filename, Length(Filename)-3);
      FileName := FileName + 'xml';
      Zip_.Read(ExtractFileName(FileName), Outp);
    finally
      Zip_.Free;
    end;
    Ok := KXmlParser.ParseStream(Outp, Root);
    SetLength(Outp, 0);
  end else
{$endif}
    Ok := KXmlParser.ParseFile(FileName, Root);
  if not Ok then
    exit;

  Clear;

  // score-partwise
  // identification
  // defaults
  // credit
  // credit
  // part-list
  // part
  // part
  // part
  i := 0;
  while Root.ChildNodes[i].Name <> 'part' do
    inc(i);
  if i + 3 <= Root.ChildNodesCount then // stammtischmusik.at
    inc(i);

  GriffHeader.Details.IsSet := true;

//  while i < Root.ChildNodes.Count do
  begin
    Part := Root.ChildNodes[i];
    inc(i);
    DoChord(0);
    NextRepeat := rRegular;
    default_x := 0.0;
    for k := 0 to Part.ChildNodesCount-1 do
    begin
      Measure := Part.ChildNodes[k];
      if Measure.Name = 'measure' then
      begin
        DoChord(0);
        for l := 0 to Measure.ChildNodesCount-1 do
        begin
          Note := Measure.ChildNodes[l];
          if Note.Name = 'note' then
          begin
            event.Clear;
            event.InPush := false;
            chord := false;
            tieStop := false;
            if Note.HasAttribute('default-x') then
            begin
              x := StrToFloatDef(Note.Attributes['default-x'], 0);
              if abs(x - default_x) > 20 then
              begin
                DoChord(x);
              end;
            end;
            for m := 0 to Note.ChildNodesCount-1 do
            begin
              Child := Note.ChildNodes[m];
              name := Child.Name;
              if name = 'chord' then
              begin
                chord := true;
              end else
              if name = 'pitch' then
              begin
                 step := '';
                 octave := '';
                 for o := 0 to Child.ChildNodesCount-1 do
                   with Child.ChildNodes[o] do
                     if Name = 'step' then
                       step := Value
                     else
                     if Name = 'octave' then
                       octave := Value;
                 event.GriffPitch := 12*(StrToIntDef(octave, 0) + 1);
                 if Length(step) = 1 then
                   for q := 1 to Length(cdur) do
                     if cdur[q] = step[1] then
                     begin
                       inc(event.GriffPitch, q-1);
                       break;
                     end;
              end else
              if name = 'duration' then
              begin
                event.AbsRect.Left := offset;
                event.AbsRect.Width := StrToIntDef(Child.Value, 0);
                if event.AbsRect.Width > delta then
                  delta := event.AbsRect.Width;
              end else
              if name = 'notehead' then
              begin
                if Child.HasAttribute('color') and
                   (Child.Attributes['color'] = '#0000FF') then
                  event.InPush := true;
                if Child.Value = 'x' then
                  event.Cross := true;
              end else

              if name = 'tie' then
              begin
                if Child.HasAttribute('type') then
                  tieStop := Child.Attributes['type'] = 'stop';
              end else
              if name = 'rest' then
              begin
                DoChord(0);
                for o := 0 to Note.ChildNodesCount-1 do
                  with Note.ChildNodes[o] do
                    if Name = 'duration' then
                      inc(offset, StrToIntDef(Value, 0));
                break;
              end;
            end;
            if event.GriffPitch > 0 then
            begin
              event.AbsRect.Top := GetPitchLine(event.GriffPitch);
              event.AbsRect.Height := 1;
              if tieStop then
              begin
                o := UsedEvents-1;
                tieStop := false;
                while (o >= 0) and
                      (GriffEvents[o].AbsRect.Right = offset) do
                  with GriffEvents[o] do
                    if (GriffPitch = event.GriffPitch) and
                       (Cross = event.Cross) and
                       (InPush = event.InPush) then
                    begin
                      AbsRect.Right := event.AbsRect.Right;
                      tieStop := true;
                      break;
                    end else
                      dec(o);
              end;
              if not tieStop then
              begin
                if NextRepeat <> rRegular then
                  event.Repeat_ := NextRepeat;
                NextRepeat := rRegular;
                AppendEvent(event);
              end;
            end;
            if chord then
            begin
              DoChord(0);
              chord := false;
            end;
          end else
          if Note.Name = 'barline' then
          begin
            Volta := 0;
            repForward := repNo;
            repStop := false;
            for o := 0 to Note.ChildNodesCount-1 do
            begin
              Child := Note.ChildNodes[o];
              if Child.Name = 'repeat' then
              begin
                if Child.HasAttribute('direction') then
                begin
                  if Child.Attributes['direction'] = 'forward' then
                    repForward := repForw
                  else
                  if Child.Attributes['direction'] = 'backward' then
                    repForward := repBackw;
                end;
              end else
              if Child.Name = 'ending' then
              begin
                if Child.HasAttribute('number') then
                  Volta := StrToIntDef(Child.Attributes['number'], 0);
                if Child.HasAttribute('type') then
                  repStop := Child.Attributes['type'] = 'stop';
              end;
            end;
            if repForward = repForw then
              NextRepeat := rStart
            else
            if (repForward = repBackw) and (Volta < 1) then
              NextRepeat := rStop
            else begin
              if Volta = 1 then
              begin
                if not repStop then
                  NextRepeat := rVolta1Start
                else
                  NextRepeat := rVolta1Stop;
              end else
              if Volta = 2 then
              begin
                if not repStop then
                  NextRepeat := rVolta2Start
                else
                  NextRepeat := rVolta2Stop;
              end;
              if (UsedEvents > 0) and (NextRepeat in [rStop, rVolta1Stop, rVolta2Stop]) then
              begin
                GriffEvents[UsedEvents-1].Repeat_ := NextRepeat;
                NextRepeat := rRegular;
              end;
            end;
          end else
          if Note.Name = 'attributes' then
          begin
            for o := 0 to Note.ChildNodesCount-1 do
            begin
              Child := Note.ChildNodes[o];
              if (Child.Name = 'divisions') then
                GriffHeader.Details.DeltaTimeTicks := StrToIntDef(Child.Value, 192)
              else
              if (Child.Name = 'time') then
              begin
                for q := 0 to Child.ChildNodesCount-1 do
                begin
                  Child1 := Child.ChildNodes[q];
                  if Child1.Name = 'beats' then
                    GriffHeader.Details.measureFact := StrToIntDef(Child1.Value, 4)
                  else
                  if Child1.Name = 'beat-type' then
                    GriffHeader.Details.measureDiv := StrToIntDef(Child1.Value, 4);
              end;
            end;
          end;
        end;
        end
      end;
    end;

  end;
  SortEvents;
  for i := 0 to UsedEvents-1 do
    GriffEvents[i].GriffToSound(Instrument);

  result := UsedEvents > 0;
  PartiturLoaded := result;
end;


