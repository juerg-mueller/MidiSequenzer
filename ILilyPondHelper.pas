
function TSheetMusicHelper.MakeLilyPond(const Title: string): TMyMemoryStream;
const
  PushColor = '#black';
  PullColor = '#blue';
var
  SaveRec: TSaveRec;
  wln: boolean;
  tie_: string;

  function GetLen(var t32: integer): string;
  var
    Dot: boolean;
    val: integer;
  begin
    val := GetLen_(t32, Dot, 0);
    if val = 0 then
      result := '?'
    else
      result := IntToStr(32 div val);
    if Dot then
      result := result + '.';
  end;

  function GetNote(Pitch: byte): string;
  var
    n: string;
  begin
    case (Pitch div 12) of
      0..2: result := ',,';
      3: result := ',';
      4: result := '';
      5: result := '''';
      6: result := '''''';
      7: result := '''''''';
      8: result := '''''''''';
      else result := '';
    end;
    if Instrument.Sharp then
      n := LowerCase(SharpNotes[Pitch mod 12])
    else
      n := LowerCase(FlatNotes[Pitch mod 12]);
    if n = 'b' then
      n := 'bes'
    else
    if n = 'h' then
      n := 'b';
    result := n + result;
  end;

  procedure NeuerTakt;
  begin
    with SaveRec do
    begin
      if LastRepeat = rStart then
      begin
        if not wln then
          result.Writeln;
        result.WritelnString(' \repeat volta 2 {');
        LastRepeat := rRegular;
      end else
      if LastRepeat = rVolta1Start then
      begin
        if not wln then
          result.Writeln;
        result.WritelnString(' } \alternative { {');
        LastRepeat := rRegular;
      end;

      if TaktNr < offset div Takt then
      begin
  {$if defined(CONSOLE)}
        if t32takt*quarterNote <> 8*Takt then
          writeln('falsche Taktlänge Takt ', TaktNr);
  {$endif}
        t32takt := 0;
        TaktNr := offset div Takt;
        if not wln then
          result.Writeln;
        result.WritelnString(' | % ' + IntToStr(TaktNr+1));

        if LastRepeat = rStop then
        begin
          result.WritelnString(' }');
          LastRepeat := rRegular;
        end else
        if LastRepeat = rVolta1Stop then
        begin
          result.WritelnString(' } {');
          LastRepeat := rRegular;
        end else
        if LastRepeat = rVolta2Stop then
        begin
          result.WritelnString(' }');
          result.WritelnString(' }');
          LastRepeat := rRegular;
        end;
        wln := true;
      end;
    end;
  end;

  procedure AddRest(Len: integer; Lyrics: boolean);
  begin
    with SaveRec do
    begin
      tie_ := '';
      t := 8*Len div quarterNote;
      while t > 0 do
      begin
        t1 := t;
        if Lyrics then
        begin
          SaveRec.dot := false;
          if ((GriffHeader.Details.measureDiv = 8) or not SaveRec.Aufrunden) and
             (t >= 4) then
          begin
            SaveRec.sLen := '\APause ';
            dec(t, 4);
          end else
          if (t >= 8) then
          begin
            SaveRec.sLen := '\VPause ';
            dec(t, 8);
          end else
            SaveRec.sLen := GetLen(t);
        end else
          SaveRec.sLen := 'r' + GetLen(t) + ' ';
        result.WriteString(SaveRec.sLen);
        inc(t32takt, t1 - t);
      end;
      inc(offset, Len);
      wln := false;
      NeuerTakt;
    end;
  end;

  function IsChord(NoteType: TNoteType): boolean;
  var
    i: integer;
  begin
    result := false;
    with SaveRec do
    begin
      i := iEvent+1;
      while i <= iEnd do
      begin
        if GriffEvents[i].NoteType = NoteType then
        begin
          result := true;
          exit;
        end;
        inc(i);
      end;
    end;
  end;

  procedure AddLyrics;
  var
    s: string;
  begin
    if not Instrument.BassDiatonic then
    begin
      s := '\markup \fontsize ';
      if GriffEvents[SaveRec.iEvent].Cross then
        s := s + '#-2 '
      else
        s := s + '#1 ';
    end else begin
      s := '\markup \with-color ';
      if GriffEvents[SaveRec.iEvent].InPush then
        s := s + PushColor + ' '
      else
        s := s + PullColor + ' ';
    end;
    s := s + GetBassLyrics(SaveRec) + ' ';
    SaveRec.iEvent := SaveRec.iEnd;
    result.WritelnString(s);
  end;

  procedure AppendStaff(UseGriff, Lyrics: boolean; nt: TNoteType);
  var
    InP: boolean;
    i: integer;
    Pitch: byte;
    UseChord: boolean;
    BassPolyphon: boolean;
  begin
    with result, SaveRec do
    begin
      InP := false;
      SaveRec.Clear;
      Takt := GriffHeader.Details.TicksPerMeasure;
      if Lyrics then
        SaveRec.Aufrunden := AufViertelnotenAufrunden;

      if Lyrics then
      begin
        WritelnString(' mylyrics = \lyricmode {');
      end else
      if nt = ntBass then
      begin
        WriteString('bass = ');
        WritelnString('\absolute {');
        WritelnString('\time ' + IntToStr(GriffHeader.Details.measureFact) + '/' +
          IntToStr(GriffHeader.Details.measureDiv));
        WritelnString('\clef bass');
        WritelnString('\set Staff.midiInstrument = "accordion"');
        if Instrument.Sharp then
          WritelnString('\key g \major')
        else
          WritelnString('\key f \minor');
//        WritelnString('\hideNotes');
      end else
      if UseGriff then
      begin
        WriteString('griff = ');
        WritelnString('\absolute {');
        WritelnString('\time ' + IntToStr(GriffHeader.Details.measureFact) + '/' +
          IntToStr(GriffHeader.Details.measureDiv));
        //WritelnString('\clef tab');
        WritelnString('\override Staff.Clef.stencil = ##f'); // kein Notenschlüssel
      end else begin
        WriteString('noten = ');
        WritelnString('\absolute {');
        WritelnString('\set Staff.midiInstrument = "' + 'accordion' + '"');
        WritelnString('\tempo 4 = ' + IntToStr(GriffHeader.Details.QuarterPerMin));
        WritelnString('\time ' + IntToStr(GriffHeader.Details.measureFact) + '/' +
          IntToStr(GriffHeader.Details.measureDiv));
        if Instrument.Sharp then
          WritelnString('\key g \major')
        else
          WritelnString('\key f \minor');
        WritelnString('\override NoteHead.color = #black');
      end;

      wln := true;
      while iEvent < UsedEvents do
      begin
        NeuerTakt;
        if SaveRec.MostRight < GriffEvents[SaveRec.iEvent].AbsRect.Right then
          SaveRec.MostRight := GriffEvents[SaveRec.iEvent].AbsRect.Right;

        with GriffEvents[SaveRec.iEvent] do
        begin
          if (NoteType > ntBass)  then
          begin
            if GriffEvents[iEvent].Repeat_ <> rRegular then
              LastRepeat := GriffEvents[iEvent].Repeat_;
            NeuerTakt;
            if NoteType = ntRest then
            begin
              Len := GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Right - offset);
              dot := false;
              AddRest(Len, Lyrics);
              LastRepeat := rRegular;
            end;
          end else begin
            // Pausen einfügen
            while (SaveRec.Rest(GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Left - offset), NoteType <> nt)) do
              AddRest(Len, Lyrics);

            if GriffEvents[iEvent].Repeat_ <> rRegular then
              LastRepeat := GriffEvents[iEvent].Repeat_;

            NeuerTakt;

            if NoteType = nt then
            begin
              if not Lyrics then
              begin
                if UseGriff and (InP <> InPush) then
                begin
                  InP := InPush;
                  if not wln then
                    Writeln;
                  WriteString('\override NoteHead.color = ');
                  if InP then
                    WritelnString(PushColor)
                  else
                    WritelnString(PullColor);
                  wln := true;
                end;

                triole := 0;
                if nt = ntDiskant then
                  triole := TriolenTest(iEvent);
                if triole > 0 then
                begin
                  // \tuplet 3/2 { b4 a g }
                  // chors in "<  >"
                  WriteString(' \tuplet 3/2 { ');
                  for i := 1 to 3 do
                  begin
                    WriteString('< ');

                    iEnd := LastChordEvent(iEvent);
                    while iEvent <= iEnd do
                    begin
                      if GriffEvents[iEvent].NoteType = ntDiskant then
                      begin
                        if UseGriff and GriffEvents[iEvent].Cross then
                          WriteString('\xNote ');
                        if UseGriff then
                          Pitch := GriffEvents[iEvent].GriffPitch
                        else
                          Pitch := GriffEvents[iEvent].SoundPitch;
                        WriteString(GetNote(Pitch) + ' ');
                      end;
                      inc(iEvent);
                    end;
                    WriteString('>' + IntToStr(triole) + ' ');
                  end;
                  WriteString(' } ');
                  inc(offset, 8*quarterNote div triole);
                  inc(t32takt, 64 div triole);

                  wln := false;
                  if t32takt*quarterNote >= 8*Takt then
                    NeuerTakt;

                  continue;
                end;
              end;

              SetIEnd(SaveRec);

              tie := tieOff;
              tieFractions := '';
              while SaveRec.SaveLen(GriffHeader.Details.GetRaster(GriffEvents[iEvent].AbsRect.Right - offset)) do
              begin
                if nt = ntBass then
                begin
                  if Len < QuarterNote div 2 then
                    Len := QuarterNote div 2;
                  if Lyrics and Aufrunden and (Len < QuarterNote) then
                  begin
                    // auf Viertelnoten aufrunden
                    Len := QuarterNote;
                  end;
                end;

                tie_ := '';
                if SaveRec.LimitToTakt then
                  tie_ := '~';

                // http://lilypond.org/doc/v2.18/Documentation/notation/note-heads.de.html
                t := 8*Len div quarterNote;
                while t > 0 do
                begin
                  i := iEvent;
                  BassPolyphon := false;
                  with GriffEvents[iEvent] do
                    if not Instrument.BassDiatonic and
                       (nt = ntBass) then
                      BassPolyphon := true;
                  UseChord := IsChord(nt) or BassPolyphon;

                  if UseChord then
                    WriteString('<');
                  t1 := t;
                  slen := GetLen(t);
                  if (nt = ntBass) and (sLen = '8') and (tie_ = '') then
                    sLen := sLen + '\staccato ';
                  inc(t32takt, t1 - t);
                  while i <= iEnd do
                  begin
                    if Lyrics then
                    begin
                      AddLyrics;
                    end else
                    if GriffEvents[i].NoteType = nt then
                    begin
                      if UseGriff and GriffEvents[i].Cross then
                        WriteString('\xNote ');
                      if UseGriff then
                        Pitch := GriffEvents[i].GriffPitch
                      else
                        Pitch := GriffEvents[i].SoundPitch;
                      WriteString(GetNote(Pitch));
                      if not UseChord then
                        WriteString(slen + tie_);
                      WriteString(' ');
                      if BassPolyphon and (GriffEvents[i].NoteType = ntBass) then
                      begin
                        if  GriffEvents[i].Cross then
                        begin
                          WriteString(GetNote(Pitch+4) + ' ');
                          WriteString(GetNote(Pitch+7) + ' ');
                        end else
                        if iEvent = iEnd then
                          WriteString(GetNote(Pitch+12) + ' ');
                      end;
                    end;
                    inc(i);
                  end;
                  if UseChord then
                    WriteString('>' + slen + tie_ + ' ');
                end;
                inc(offset, Len);
                wln := false;
                if t32takt*quarterNote >= 8*Takt then
                  NeuerTakt;
              end;
            end;
          end;
          inc(iEvent);
        end;
      end;
      if UseGriff then
        WritelnString('  \override NoteHead.color = #black');
      WritelnString('}');
    end;
  end;

 ////////////////////////////////////////////////////////////////////////////////

  procedure AddLyrics_;
  var
    s: string;
    n: integer;
    IsOergeli: boolean;
  begin
    with result, SaveRec do
    begin
      Clear;
      n := 0;
      IsOergeli := not Instrument.BassDiatonic;
      WritelnString(' mylyrics = \lyricmode {');
      while iEvent < UsedEvents do
      begin
        if GriffEvents[iEvent].NoteType = ntBass then
        begin
          SetIEnd(SaveRec);
          if IsOergeli then
          begin
            s := '\markup \fontsize ';
            if GriffEvents[iEvent].Cross then
              s := s + '#-2 '
            else
              s := s + '#1 ';
          end else begin
            s := '\markup \with-color ';
            if GriffEvents[iEvent].InPush then
              s := s + PushColor + ' '
            else
              s := s + PullColor + ' ';
          end;
          s := s + GetBassLyrics(SaveRec) + ' ';
          iEvent := iEnd + 1;
          WritelnString(s);
          inc(n);
          if n >= 10 then
          begin
            //Writeln;
            n := 0;
          end;
        end else
          inc(iEvent);
      end;
      //Writeln;
      WritelnString('  }');
    end;
  end;

var
  s: string;
  p: integer;
begin
  result := TMyMemoryStream.Create;
  with result do
  begin
    Writeln;
    WritelnString('\version "2.20.0"');
    WritelnString('\header {');
    s := title;
    p := system.Pos(' - ', title);
    if p > 1 then
      Delete(s, p, length(s));
    WriteUTF8String('  title = "' + s + '"');
    Writeln;
    if p > 1 then
    begin
      s := title;
      Delete(s, 1, p + 2);
      WriteUTF8String('  subtitle = "' + s + '"');
      Writeln;
    end;
    WritelnString(string('composer = "' + Instrument.Name + '"'));
    WritelnString('}');
    Writeln;
    WritelnString('SPause = \markup { \musicglyph #"rests.4" } %% Sechzehntelpause');
    WritelnString('APause = \markup { \musicglyph #"rests.3" } %% Achtelpause');
    WritelnString('VPause = \markup { \musicglyph #"rests.2" } %% Viertelpause');
    WritelnString('HPause = \markup { \musicglyph #"rests.1" } %% Halbe Pause');
    WritelnString('GPause = \markup { \musicglyph #"rests.0" } %% Ganze Pause');
    Writeln;
    AppendStaff(false, false, ntDiskant);
    AppendStaff(true, false, ntDiskant);
    AppendStaff(false, false, ntBass);
//    AddLyrics;
    AppendStaff(true, true, ntBass);
    Writeln;
    WritelnString('\score {');
    WritelnString('  <<');
    WritelnString('    \context Staff = "griff" {');
    WritelnString('      \griff');
    WritelnString('    }');
    WritelnString('    \new Lyrics \mylyrics');
    WritelnString('  >>');
    WritelnString('  \layout {');
    WritelnString('    \override LyricText.font-name = #"arial"');
    WritelnString('  }');
    WritelnString('}');
    Writeln;
    WritelnString('\score {');
    WritelnString('  <<');
    WritelnString('    \context Staff = "noten" {');
    WritelnString('      \noten');
    WritelnString('    }');
    WritelnString('    \context Staff = "bass" {');
    WritelnString('      \bass');
    WritelnString('    }');
    WritelnString('  >>');
    WritelnString('  \midi {}');
    WritelnString('}');

    // Bass: http://lilypond.org/doc/v2.22/Documentation/notation/figured-bass
  end;
end;


