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
  AchtelProZeile: integer;
  iPage: integer;
  bitRechts, bitLinks, bitRechtsRing, bitLinksRing: TBitmap;

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
    index := (left mod AchtelProZeile) div 2;
    zeile := (left div AchtelProZeile);
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
        Canvas.Font.Color := $ff0000
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

  function GenerateAchtel(Brush, Pen: TColor): TBitmap;
  begin
    result := TBitmap.Create;
    result.SetSize(radius, 2*radius);
    result.Canvas.Brush.Color := $ffffff;
    result.Canvas.FillRect(0, 0, radius, 2*radius);
    result.Canvas.Font.Name := 'Sans';
    result.Canvas.Brush.Color := Brush;
    result.Canvas.Pen.Color := Pen;
  end;

  procedure DrawDiskant(rect: TRect; push: boolean);
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

  procedure DrawDiskantLinks(rect: TRect; push: boolean);
  var
    source: TRect;
  begin
    source := TRect.Create(0, 0, radius-2, 2*radius);
    rect.Width := radius - 2;
    with bitmaps[iPage] do
      if Push then
        Canvas.CopyRect(rect, bitLinks.Canvas, source)
      else
        Canvas.CopyRect(rect, bitLinksRing.Canvas, source);
  end;

  procedure DrawDiskantRechts(rect: TRect; push: boolean);
  var
    source: TRect;
  begin
    source := TRect.Create(2, 0, radius, 2*radius);
    rect.Width := radius-2;
    rect.Offset(radius+2, 0);
    with bitmaps[iPage] do
      if Push then
        Canvas.CopyRect(rect, bitRechts.Canvas, source)
      else
        Canvas.CopyRect(rect, bitRechtsRing.Canvas, source);
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
      Canvas.MoveTo(rect.Left + 4, rect.Bottom);
      Canvas.LineTo(rect.Right - 4, rect.Bottom);
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
  dur, eighth, lines, Fact: integer;
  rect, rect1, rect2: TRect;
  iEvent: integer;
  index, row: integer;
  event: TGriffEvent;
  left, right: integer;
  iPageRight: integer;
  TicksPerEighth: integer;
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
      AchtelProZeile := 8
    else
      AchtelProZeile := 12;
  end else begin
    LinesPerPage := 4;
    abstand := radius*3;
    h := 11*abstand + 2*rand;
    w := round(3*abstand*1.732/2) + 2*rand;
    xAbstand := (w+ 4*rand);
    yAbstand := (h + 26*rand) + 2;
    if Fact = 3 then
      AchtelProZeile := 18
    else
      AchtelProZeile := 16;
  end;


  bitRechts := GenerateAchtel($0000ff, $0000ff);
  bitLinks := GenerateAchtel($0000ff, $0000ff);
  rect := TRect.Create(0, 0, 2*radius, 2*radius);
  bitLinks.Canvas.Ellipse(rect);
  rect.Offset(-radius, 0);
  bitRechts.Canvas.Ellipse(rect);

  bitLinksRing := GenerateAchtel($ffffff, $ff0000);
  bitLinksRing.Canvas.Pen.Width := 6;
  rect := TRect.Create(0, 0, 2*radius-4, 2*radius-4);
  rect.Offset(2, 2);
  bitLinksRing.Canvas.Ellipse(rect);

  bitRechtsRing := GenerateAchtel($ffffff, $ff0000);
  rect.Offset(-radius, 0);
  bitRechtsRing.Canvas.Pen.Width := 6;
  bitRechtsRing.Canvas.Ellipse(rect);


  dur := GriffPartitur_.GetTotalDuration;
  TicksPerEighth := GriffPartitur_.GriffHeader.Details.TicksPerQuarter div 2;
  eighth := (dur + TicksPerEighth - 1) div TicksPerEighth;
  lines := (eighth + AchtelProZeile - 1) div AchtelProZeile;
  Pt := TabellenPoint(AchtelProZeile, LinesPerPage);
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
    for l := 0 to AchtelProZeile div 2 - 1 do
    begin
      Takt := j*AchtelProZeile div 2 + l;
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
      left := Event.AbsRect.Left div TicksPerEighth;
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
      left := Event.AbsRect.Left div TicksPerEighth;
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
      if j < GriffPartitur_.UsedEvents then
      begin
        right := GriffPartitur_.GriffEvents[j].AbsRect.Right div TicksPerEighth;
        left := Event.AbsRect.Left div TicksPerEighth;
        dur := right - left;
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
            j := left mod AchtelProZeile;
            l := AchtelProZeile - j;
            if l > dur then
              l := dur;
            Pt := TabellenPoint_(left);
            Canvas.MoveTo(Pt.X, Pt.Y - 60);
            Canvas.LineTo(Pt.X + l*xAbstand div 2 - 4*rand - 5, Pt.Y - 60);
            if (dur = l) and (event.Repeat_ = rVolta2Start) then
            begin
              Canvas.LineTo(Pt.X + l*xAbstand div 2 - 4*rand - 5, Pt.Y - 30);
            end;
            inc(left, l);
            dec(dur, l);
          end;
        end;
      end;
    end;
    if event.NoteType in [ntBass, ntDiskant] then
    begin
      dur := event.AbsRect.Width div TicksPerEighth;
      left := event.AbsRect.Left div TicksPerEighth;
      index := event.GetIndex;
      if (dur <= 0) and (event.NoteType = ntDiskant) then
      begin
      end else
      if (event.NoteType = ntDiskant) then
      begin
        row := event.GetRow - 1;
        if row in [0, 2] then
          dec(index);
        rect := GetTastenRect(left, index, row);

        rect1 := rect;
        if (dur = 1) or odd(left) then
        begin
          if odd(left) then
            DrawDiskantRechts(rect, event.InPush)
          else
            DrawDiskantLinks(rect, event.InPush);
          dec(dur);
          inc(left);
          rect1.Offset(1, 0);
        end else begin
          DrawDiskant(rect, event.InPush);
          dec(dur, 2);
          inc(left, 2);
          rect1.Offset(2, 0);
        end;
        goOn := false;
        while dur > 0 do
        begin
          if (((left mod AchtelProZeile) <> 0) and
             ((left mod AchtelProZeile) + dur <= AchtelProZeile)) or GoOn then
          begin
            inc(left, dur);
            if not odd(dur) then
              dec(left);
            rect1 := GetTastenRect(left, index, row);
            if odd(dur) then
              DrawDiskantLinks(rect1, event.InPush)
            else
              DrawDiskant(rect1, event.InPush);
            if rect1.Left < rect.Left then
              left :=  left;
            DrawBogen(rect, rect1, event.InPush);
            dur := 0;
          end else begin
            j := left mod AchtelProZeile;
            if (j > 0) then
            begin
              l := AchtelProZeile - j;
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
       if odd(left) then
         inc(Pt.X, 3*radius);
       //event.TestBass;
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

