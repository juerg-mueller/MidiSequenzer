unit UGrifftabelle;

{$ifndef fpc}
  {$mode Delphi}
{$endif}


interface

uses
  Classes, SysUtils, Types, Variants, Graphics,
  UInstrument, UMyMemoryStream, UMyMidiStream, UEventArray,
  UGriffEvent;

function SaveToPdf(const FileName: string): boolean;

implementation

uses
  UGriffPartitur;

function SaveToPdf(const FileName: string): boolean;
var
  radius: integer;
  rand: integer;
  xRand: integer;
  LinesPerPage: integer = 4;
  abstand: integer;
  h: integer;
  w: integer;
  xAbstand: integer;
  yAbstand: integer;

var
  bitmaps: array of TBitmap;
  l, j: integer;
  Takt: integer;
  Pt: TPoint;
  _16telProZeile: integer;
  iPage: integer;
  bitKreis, bitRing: TBitmap;

  function makeRectOergeli(index, row: integer): TRect;
  var
    l, t: double;
  begin
    if row = 1 then
      index := 10 - index
    else
      index := 9 - index;
    row := 2 - row;
    l := h / 2 + (index-5) * abstand;
    t := w / 2;
    if row <> 1 then
      l := l + abstand/2;
    if row = 0 then
      t := t - abstand*1.732/2
    else
    if row = 2 then
      t := t + abstand * 1.732/2;
    result.Left := round(t - radius);
    result.Top := round(l - radius);
    result.Width := 2*radius;
    result.Height := 2*radius;
  end;

  function makeRectSteirisch(index, row: integer): TRect;
  const
    wurzel = 1.732/2;
  var
    l, t: double;
  begin
    t := w / 2 + 1.5*abstand*wurzel;
    t := t - row*abstand*wurzel;

    l := h / 2 - (index-6) * abstand;
    if odd(row) then
      l := l - abstand*wurzel/2;

    result.Left := round(t - radius);
    result.Top := round(l - radius);
    result.Width := 2*radius;
    result.Height := 2*radius;
  end;

  function makeRect(index, row: integer): TRect;
  begin
    if GriffPartitur_.Instrument.BassDiatonic then
      result := makeRectSteirisch(index, row)
    else
      result := makeRectOergeli(index, row);
  end;

  // Für jede Viertelsnote eine Tabelle
  function TabellenPoint(index, zeile: integer): TPoint;
  begin
    iPage := zeile div LinesPerPage;
    zeile := zeile mod LinesPerPage;
    result.X := index*xAbstand + xRand;
    result.Y := zeile*yAbstand + 100;
  end;

  function TabellenPoint_(left: integer): TPoint;
  var
    index, zeile: integer;
  begin
    index := (left mod _16telProZeile) div 4;
    zeile := (left div _16telProZeile);
    result := TabellenPoint(index, zeile);
  end;

  procedure DrawBass(x, y: integer; Gross, Klein: string; InPush: boolean);
  var
    t: string;
    diatonic: boolean;
  begin
    diatonic := GriffPartitur_.Instrument.BassDiatonic;
    with bitmaps[iPage] do
    begin
      Canvas.Brush.Color := $ffffff;
      if not diatonic then
        Canvas.Font.Color := $000000
      else
      if InPush then
        Canvas.Font.Color := $0000ff
      else
        Canvas.Font.Color := $ff0000;
      if diatonic then
        Canvas.Font.Height := 3*radius
      else
        Canvas.Font.Height := 2*radius;
      if (Gross <> '') and (Klein <> '') then
      begin
        t := Klein;
        Canvas.TextOut(x + w div 2 - Canvas.TextWidth(t) div 2,
                            y + h + rand + 4*radius, t);
      end;
      if Gross <> '' then
      begin
        Canvas.Font.Height := 3*radius;
        if not diatonic then
          Canvas.Font.Bold := true;
        t := Gross;
      end else begin
        t := Klein;
        if not diatonic then
          Canvas.Font.Height := 2*radius;
      end;
      Canvas.TextOut(x + w div 2 - Canvas.TextWidth(t) div 2,
                          y + h + rand, t);
      Canvas.Font.Bold := false;
      Canvas.Font.Color := $000000;
    end;
  end;

  function GetTastenRect(left: integer; index, row: integer): TRect;
  var
    Pt: TPoint;
    t: integer;
  begin
    Pt := TabellenPoint_(left);
    result := makeRect(index, row);
    result.offset(Pt.X, Pt.Y);
  end;

  function GenerateKreis(Brush, Pen: TColor): TBitmap;
  begin
    result := TBitmap.Create;
    result.SetSize(2*radius, 2*radius);
    result.Canvas.Brush.Color := $ffffff;
    result.Canvas.FillRect(0, 0, 2*radius, 2*radius);
    result.Canvas.Font.Name := 'Sans';
    result.Canvas.Brush.Color := Brush;
    result.Canvas.Pen.Color := Pen;
  end;
{
  procedure DrawDiskant_(rect: TRect; push: boolean);
  begin
    with bitmaps[iPage] do
    begin
      if Push then
      begin
        Canvas.Pen.Width := 2;
        Canvas.Pen.Color := $0000ff;
        Canvas.Brush.Color := $0000ff
      end else begin
        Canvas.Pen.Width := 6;
        Canvas.Pen.Color := $ff0000;
        Canvas.Brush.Color := $ffffff;
        rect.Offset(2, 2);
        rect.Width := rect.Width  - 4;
        rect.Height := rect.Height - 4;
      end;
      canvas.Ellipse(rect);
      Canvas.Pen.Width := 2;
    end;
  end;
}
  function DrawDiskant(rect: TRect; links: integer; dur: integer; push: boolean): integer;
  const
    delta = 1;
  var
    source: TRect;
    linksMod4: integer;
    Pt: TPoint;

    procedure Draw;
    begin
      with bitmaps[iPage] do
        if Push then
          Canvas.CopyRect(rect, bitKreis.Canvas, source)
        else
          Canvas.CopyRect(rect, bitRing.Canvas, source);
    end;

  begin
    Pt.X := rect.Left;
    Pt.Y := rect.Top;
    linksMod4 := links mod 4;
    case linksMod4 of
      0: if dur < 4 then
           result := dur
         else
           result := 4;
      1: if dur < 3 then
           result := dur
         else
           result := 3;
      2: if dur < 2 then
           result := dur
         else
           result := 2;
      3: result := 1;
    end;
    if result = 4 then
    begin
      source := TRect.Create(0, 0, 2*radius, 2*radius);
      Draw;
      exit;
    end;
    if linksMod4 < 2 then   // in linker Häfte
    begin
      source := TRect.Create(0, 0, radius-delta, 2*radius);
      rect.Width := radius-delta;
      if (result = 1) or (linksMod4 = 1) then
      begin
        source.Height := radius-delta;
        rect.Height := radius-delta;
        // 16. Note
        if linksMod4 = 0 then // unten
        begin
          source.Offset(0, radius+delta);
          rect.Offset(0, radius+delta);
        end;
      end;
      Draw;
    end;
    if (links mod 4) + dur > 2 then // in der rechten Hälfte
    begin
      source := TRect.Create(radius+delta, 0, 2*radius, 2*radius);
      rect.Width := radius-delta;
      rect.Offset(radius+delta, 0);
      if (linksMod4 + dur >= 4) and (linksMod4 < 3) then
      begin
        // Achtel
      end else begin
        rect.Height := radius-delta;
        source.Height := radius-delta;
        if (linksMod4 = 0) and (result = 3) then // punktierter Achtel
        begin
          with bitmaps[iPage] do
          begin
            Canvas.Pen.Width := 6;

            if push then
              Canvas.Pen.Color := $0000ff
            else
              Canvas.Pen.Color := $ff0000;
            Canvas.MoveTo(Pt.X + radius div 2, Pt.Y + 3);
            Canvas.LineTo(Pt.X + radius div 2 + 3, Pt.Y + 3);
          end;
        end else
        if linksMod4 = 3 then     // unten
        begin
          Source.Offset(0, radius+delta);
          rect.Offset(0, radius+delta);
        end;
      end;
      Draw;
    end;
  end;

  procedure DrawBoxSteirisch(x, y: integer; Takt: integer);
  var
    i, k, ecke, delta: integer;
    rect: TRect;
  begin
    delta := radius div 3;
    ecke := 3*radius;

    rect.Left := 0;
    rect.Top := 0;
    rect.Right := w;
    rect.Bottom := h;
    rect.Offset(x, y);
    with bitmaps[iPage] do
    begin
      Canvas.Pen.Color := 0;
      Canvas.Pen.Width := 2;

      Canvas.MoveTo(rect.Right - 2*ecke,  rect.Top);
      Canvas.LineTo(rect.Right,           rect.Top);
      Canvas.LineTo(rect.Right,           rect.Bottom);
      Canvas.LineTo(rect.Right - 2*ecke,  rect.Bottom);
      Canvas.LineTo(rect.Left,            rect.Bottom - 3*radius);  // ok
      Canvas.LineTo(rect.Left,            rect.Top + 3*radius);
      Canvas.LineTo(rect.Right - 2*ecke,   rect.Top);
      Canvas.LineTo(rect.Right - 2*ecke,  rect.Top);
      if Takt > 0 then
      begin
        Canvas.Pen.Width := 4;
        Canvas.MoveTo(rect.Left - 2*rand, rect.Top - 4*rand);
        Canvas.LineTo(rect.Left - 2*rand, rect.Top + 6*rand);
        Canvas.Font.Height := 2*radius;
        Canvas.TextOut(rect.Left, rect.Top - 6*rand, IntToStr(Takt));
      end;
      Canvas.Pen.Width := 2;
      Canvas.Font.Bold := false;
      for k := 0 to 3 do
        for i := 0 to 12-k do
          begin
            rect := makeRect(i + k div 2, k);
            rect.Offset(x, y);
            canvas.Ellipse(rect);
            if (k = 1) and (i = 5) then // Kreuz
            begin
              Canvas.MoveTo(rect.Left + delta, rect.Top + delta);
              Canvas.LineTo(rect.Right - delta, rect.Bottom - delta);
              Canvas.MoveTo(rect.Left + delta, rect.Bottom - delta);
              Canvas.LineTo(rect.Right - delta, rect.Top + delta);
            end;
          end;
    end;
  end;

  procedure DrawBoxOergeli(x, y: integer; Takt: integer);
  var
    i, k, ecke, delta: integer;
    rect: TRect;
  begin
    delta := radius div 3;
    ecke := radius;

    rect.Left := 0;
    rect.Top := 0;
    rect.Right := w;
    rect.Bottom := h;
    rect.Offset(x, y);
    with bitmaps[iPage] do
    begin
      Canvas.Pen.Color := 0;
      Canvas.Pen.Width := 2;

      Canvas.MoveTo(rect.Left + ecke,  rect.Top);
      Canvas.LineTo(rect.Right - ecke, rect.Top);
      Canvas.LineTo(rect.Right,        rect.Top + ecke);
      Canvas.LineTo(rect.Right,        rect.Bottom - ecke);
      Canvas.LineTo(rect.Right - ecke, rect.Bottom);
      Canvas.LineTo(rect.Left + ecke,  rect.Bottom);
      Canvas.LineTo(rect.Left,         rect.Bottom - ecke);
      Canvas.LineTo(rect.Left,         rect.Top + ecke);
      Canvas.LineTo(rect.Left + ecke,  rect.Top);
      if Takt > 0 then
      begin
        Canvas.Pen.Width := 4;
        Canvas.MoveTo(rect.Left - 2*rand, rect.Top - 4*rand);
        Canvas.LineTo(rect.Left - 2*rand, rect.Top + 6*rand);
        Canvas.Font.Height := 2*radius;
        Canvas.TextOut(rect.Left, rect.Top - 6*rand, IntToStr(Takt));
      end;
      Canvas.Pen.Width := 2;
      Canvas.Font.Bold := false;
      for k := 0 to 2 do
        for i := 0 to 10 do
          if (i < 10) or (k = 1) then
          begin
            rect := makeRect(i, k);
            rect.Offset(x, y);
            canvas.Ellipse(rect);
            if (k = 1) and (i = 5) then // Kreuz
            begin
              Canvas.MoveTo(rect.Left + delta, rect.Top + delta);
              Canvas.LineTo(rect.Right - delta, rect.Bottom - delta);
              Canvas.MoveTo(rect.Left + delta, rect.Bottom - delta);
              Canvas.LineTo(rect.Right - delta, rect.Top + delta);
            end;
          end;
    end;
  end;

  procedure DrawBogen(const rect1, rect2: TRect; InPush: boolean);
  var
    rect: TRect;
  begin
    rect.Left := rect1.Left + rect1.Width div 2;
    rect.Right := rect2.Left + rect2.Width div 2;
    rect.Top := rect1.Top - 40;
    rect.Bottom := rect1.Top + 3;

    with bitmaps[iPage] do
    begin
      Canvas.Pen.Width := 6;
      if InPush then
        Canvas.Pen.Color := $0000ff
      else
        Canvas.Pen.Color := $ff0000;
      Canvas.Brush.Color := $ffffff;
      Canvas.MoveTo(rect.Left + 5, rect.Bottom);
      Canvas.LineTo(rect.Right - 6, rect.Bottom);
      {Canvas.Arc(rect.Left, rect.Top,
                      rect.Right, rect.Bottom,
                      rect.Right, rect.Bottom,
                      rect.Left, rect.Bottom); }
      Canvas.Pen.Width := 2;
    end;
  end;

  function GetBass(var event: TGriffEvent): string;
  begin
    if GriffPartitur_.Instrument.BassDiatonic then
      result := event.GetSteiBass
    else
      result := IntToStr(Event.GriffPitch);
  end;

var
  dur, _16tel, lines, Fact: integer;
  rect, rect1, rect2: TRect;
  iEvent: integer;
  index, row: integer;
  event: TGriffEvent;
  left: integer;
  iPageRight: integer;
  TicksPer16tel: integer;
  PtBass: TPoint;
  sBass, sBassTief, s: string;
  goOn: boolean;
  pages: integer;
  rep: TRepeat;
begin
  Fact := GriffPartitur_.GriffHeader.Details.measureFact;
 { if (GriffPartitur_.GriffHeader.Details.measureDiv <> 4) or
     not (Fact in [2, 3, 4]) then;
  begin
    result := false;
    exit;
  end;   }

  radius := 10;
  rand := radius div 2;
  xRand := 4*rand;
  if GriffPartitur_.Instrument.BassDiatonic then
  begin
    LinesPerPage := 3;
    abstand := radius*4;
    h := 13*abstand + 2*rand;
    w := round(4*abstand*1.732/2) + 2*rand;
    xAbstand := (w+ 4*rand);
    yAbstand := (h + 26*rand) + 2;
    if Fact = 4 then
      _16telProZeile := 16
    else
      _16telProZeile := 24;
  end else begin
    LinesPerPage := 4;
    abstand := radius*3;
    h := 11*abstand + 2*rand;
    w := round(3*abstand*1.732/2) + 2*rand;
    xAbstand := (w+ 4*rand);
    yAbstand := (h + 26*rand) + 2;
    if Fact = 3 then
      _16telProZeile := 36
    else
      _16telProZeile := 32;
  end;

  rect := TRect.Create(0, 0, 2*radius, 2*radius);
  bitKreis := GenerateKreis($0000ff, $0000ff);
  bitKreis.Canvas.Pen.Width := 2;
  bitKreis.Canvas.Ellipse(rect);

  rect := TRect.Create(0, 0, 2*radius-4, 2*radius-4);
  bitRing := GenerateKreis($ffffff, $ff0000);
  bitRing.Canvas.Pen.Width := 6;
  rect.Offset(2, 2);
  bitRing.Canvas.Ellipse(rect);



  dur := GriffPartitur_.GetTotalDuration;
  TicksPer16tel := GriffPartitur_.GriffHeader.Details.TicksPerQuarter div 4;
  _16tel := (dur + TicksPer16tel - 1) div TicksPer16tel;
  lines := (_16tel + _16telProZeile - 1) div _16telProZeile;
  Pt := TabellenPoint(_16telProZeile, LinesPerPage);
  pages := (lines + LinesPerPage - 1) div LinesPerPage + 1;
  SetLength(bitmaps, pages);

  rect := TRect.Create(0, 0, 1300, 2000);
  for j := 0 to pages-1 do
  begin
    bitmaps[j] := TBitmap.Create;
    bitmaps[j].SetSize(rect.Right, rect.Bottom);
    bitmaps[j].Canvas.Brush.Color := $ffffff;
    bitmaps[j].Canvas.FillRect(0, 0, rect.Right, rect.Bottom);
    bitmaps[j].Canvas.Font.Name := 'Sans';
  end;
  for j := 0 to lines-1 do
    for l := 0 to _16telProZeile div 4 - 1 do
    begin
      Takt := j*_16telProZeile div 4 + l;
      if (Takt mod Fact) = 0 then
        Takt := Takt div Fact + 1
      else
        Takt := -1;
      Pt := TabellenPoint(l, j);
      if not GriffPartitur_.Instrument.BassDiatonic then
        DrawBoxOergeli(Pt.X, Pt.Y, Takt)
      else
        DrawBoxSteirisch(Pt.X, Pt.Y, Takt);
    end;

  PtBass.X := -1;
  iEvent := 0;
  while iEvent < GriffPartitur_.UsedEvents do
  begin
    event := GriffPartitur_.GriffEvents[iEvent];
    if event.Repeat_ = rStart then
    begin
      //  ||:   Zeichen setzen
      left := Event.AbsRect.Left div TicksPer16tel;
      Pt := TabellenPoint_(left);
      with bitmaps[iPage] do
      begin
        Canvas.Pen.Width := 3;
        Canvas.Pen.Color := 0;
        Canvas.Brush.Color := $ffffff;
        Canvas.MoveTo(Pt.X, Pt.Y - 30);
        Canvas.LineTo(Pt.X, Pt.Y - 60);
        Canvas.MoveTo(Pt.X + 7, Pt.Y - 30);
        Canvas.LineTo(Pt.X + 7, Pt.Y - 60);
        rect.Left := Pt.X + 15;
        rect.Top := Pt.Y - 40;
        rect.Width := 6;
        rect.Height := 6;
        Canvas.Brush.Color := 0;
        Canvas.Ellipse(rect);
        rect.Offset(0, -15);
        Canvas.Ellipse(rect);
      end;
    end else
    if event.Repeat_ in [rStop, rVolta1Stop] then
    begin
      //  :||  Zeichen setzen
      left := (Event.AbsRect.Right-4) div TicksPer16tel; // vorletzter Viertel
      Pt := TabellenPoint_(left);
      inc(Pt.X, xAbstand);
      with bitmaps[iPage] do
      begin
        Canvas.Pen.Width := 3;
        Canvas.Pen.Color := 0;
        Canvas.Brush.Color := $ffffff;
        Canvas.MoveTo(Pt.X - 24, Pt.Y - 30);
        Canvas.LineTo(Pt.X - 24, Pt.Y - 60);
        Canvas.MoveTo(Pt.X - 31, Pt.Y - 30);
        Canvas.LineTo(Pt.X - 31, Pt.Y - 60);
        rect.Left := Pt.X - 41;
        rect.Top := Pt.Y - 40;
        rect.Width := 6;
        rect.Height := 6;
        Canvas.Brush.Color := 0;
        Canvas.Ellipse(rect);
        rect.Offset(0, -15);
        Canvas.Ellipse(rect);
      end;
    end;
    if event.Repeat_ in [rVolta1Start, rVolta2Start] then
    begin
      // Voltabogen setzen
      if event.Repeat_ = rVolta1Start then
        rep := rVolta1Stop
      else
        rep := rVolta2Stop;
      j := iEvent + 1;
      // rVolta1/2Stop suchen
      while (j < GriffPartitur_.UsedEvents) and (GriffPartitur_.GriffEvents[j].Repeat_ <> rep) do
        inc(j);
      if j < GriffPartitur_.UsedEvents then // bei "j" ist VoltaStop
      begin
        left := Event.AbsRect.Left div TicksPer16tel;
        dur := (GriffPartitur_.GriffEvents[j].AbsRect.Right div TicksPer16tel) - left;
        with bitmaps[iPage] do
        begin
          Canvas.Pen.Width := 3;
          Canvas.Pen.Color := 0;
          Canvas.Brush.Color := $ffffff;
          Canvas.Font.Size := 25;
          Canvas.Font.Bold := true;
          Pt := TabellenPoint_(left);
          if event.Repeat_ = rVolta1Start then
            s := '1.'
          else
            s := '2.';
          Canvas.TextOut(Pt.X + 35, Pt.Y - 65, s);
          Canvas.Font.Bold := false;
          Canvas.MoveTo(Pt.X, Pt.Y - 60); // senkrechter Anfangsstrich
          Canvas.LineTo(Pt.X, Pt.Y - 30);
          while dur > 0 do
          begin
            j := left mod _16telProZeile;
            l := _16telProZeile - j;
            if l > dur then
              l := dur;
            Pt := TabellenPoint_(left);
            bitmaps[iPage].Canvas.MoveTo(Pt.X, Pt.Y - 60);
            bitmaps[iPage].Canvas.LineTo(Pt.X + l*xAbstand div 4 - 4*rand - 5, Pt.Y - 60);
            if (dur = l) and (event.Repeat_ = rVolta2Start) then
            begin
              bitmaps[iPage].Canvas.LineTo(Pt.X + l*xAbstand div 4 - 4*rand - 5, Pt.Y - 30);
            end;
            inc(left, l);
            dec(dur, l);
          end;
        end;
      end;
    end;
    if event.NoteType in [ntBass, ntDiskant] then
    begin
      dur := event.AbsRect.Width div TicksPer16tel;
      left := event.AbsRect.Left div TicksPer16tel;
      index := event.GetIndex;
      if (dur <= 0) and (event.NoteType = ntDiskant) then
      begin
      end else
      if (event.NoteType = ntDiskant) then                // Diskant
      begin
        row := event.GetRow - 1;
        if not GriffPartitur_.Instrument.BassDiatonic then
          if row in [0, 2] then
            dec(index);
        rect := GetTastenRect(left, index, row);
        rect1 := rect;
        j := DrawDiskant(rect, left, dur, event.InPush);
        dec(dur, j);
        inc(left, j);
        rect1.Offset(1, 0);
        goOn := false;
        while dur > 0 do
        begin
          if (((left mod _16telProZeile) <> 0) and
             ((left mod _16telProZeile) + dur <= _16telProZeile)) or GoOn then
          begin
            rect1 := GetTastenRect(left, index, row);
            DrawDiskant(rect1, left, dur, event.InPush);
            if rect1.Left < rect.Left then
              left :=  left;
            DrawBogen(rect, rect1, event.InPush);
            dur := 0;
          end else begin
            j := left mod _16telProZeile;
            if (j > 0) then
            begin
              l := _16telProZeile - j;
              if l > dur then
                l := dur;
              inc(left, l);
              dec(dur, l);
              // -1: sonst ist es auf der nächsten Zeile
              rect1 := GetTastenRect(left-1, index, row);
            end;
            j := 0;
            if Row <> 1 then
              j := round(abstand*1.73/2);
            if Row = 0 then
              j := -j;

            rect1.Offset(w + j, 0);
            if rect1.Left < rect.Left then
              left :=  left;
            DrawBogen(rect, rect1, event.InPush);

            rect := GetTastenRect(left, index, row);
            rect.Offset(-w + j, 0);
            goOn := true;
          end;
        end;
      end else begin                               // Bass
       Pt := TabellenPoint_(left);
       if (left mod 4) >= 2  then
         inc(Pt.X, 3*radius);
       if event.Cross then
       begin
         sBass := GetBass(event);
         if Pt <> PtBass then
           DrawBass(Pt.X, Pt.Y, '', sBass, event.InPush)
       end else begin
         sBass := '';
         sBassTief := GetBass(event);
         j := iEvent + 1;
         while (j < GriffPartitur_.UsedEvents) and (Event.AbsRect.Left = GriffPartitur_.GriffEvents[j].AbsRect.Left) do
         begin
           if (GriffPartitur_.GriffEvents[j].NoteType = ntBass) and (GriffPartitur_.GriffEvents[j].Cross) then
           begin
             PtBass := Pt;
             sBass := GetBass(GriffPartitur_.GriffEvents[j]);
             break;
           end;
           inc(j);
         end;
         DrawBass(Pt.X, Pt.Y, sBassTief, sBass, event.InPush);
       end;
      end;
    end;
    inc(iEvent);
  end;

  s := Filename;
  SetLength(s, Length(s) - Length(ExtractFileExt(s)));
  for j := 0 to Pages-1 do
  begin
    bitmaps[j].Canvas.Font.Size := 30;
    bitmaps[j].Canvas.Font.Color := $0;
    bitmaps[j].Canvas.Brush.Color := $ffffff;
    //bitmaps[j].Canvas.TextOut(50, 30, ExtractFileName(s) + ' ' + IntToStr(i+1));
    bitmaps[j].SaveToFile(s + '_' + IntToStr(j+1) + '.bmp');
    bitmaps[j].Free;
  end;
  SetLength(bitmaps, 0);
  result := true;
end;


end.

