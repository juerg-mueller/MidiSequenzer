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
unit UfrmGriff;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Menus,
  Controls, Forms, Dialogs, Types,
  UGriffPartitur, UMyMidiStream, Midi, UGriffEvent, UAmpel;

type

  TCursorMovePos = (cmpLeft, cmpRight, cmpTop, cmpBottom, cmpDrag);

  PRubberProc = procedure (const Rect: TRect) of object;
  
  TfrmGriff = class(TForm)
    procedure FormPaint(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
    procedure FormActivate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    procedure GetClippedMousePos(var Pos : TPoint; X, Y : integer);
//    function GetKeyIndex(var Event: UAmpel.TMouseEvent; Key: word): boolean;

  public
    GriffPartitur: TGriffPartitur;
    IsActive: boolean;

    xRGB, yRGB : integer;

    sChangingCursor : set of TCursorMovePos;
    pDrag : TPoint;

    playLocation: integer;

    RubberChanges: PRubberProc; 
    SelectedChanges: PSelectedProc;
    procedure SetPlayRect(rect: TRect);
    procedure ShowSelected;
  end;

var
  frmGriff: TfrmGriff;

implementation

{$R *.dfm}

function OverLine(x, Left, Right, y, Top, Delta : integer) : boolean;
begin
  result:= (Left-Delta <= x) and (x <= Right+Delta) and
           (abs(Top - y) <= Delta);
end;

function OverPoint(x, y : integer; p : TPoint; Delta : integer) : boolean;
begin
  result:= (abs(p.X - x) <= Delta) and
           (abs(p.Y - y) <= Delta);
end;

procedure MakeOriginalRect(var rect : TRect); overload;
var r : integer;
begin
  if rect.Left > rect.Right then begin
    r:= rect.Left;
    rect.Left:= rect.Right;
    rect.Right:= r;
  end;
  if rect.Top > rect.Bottom then begin
    r:= rect.Top;
    rect.Top:= rect.Bottom;
    rect.Bottom:= r;
  end;
end;

procedure ClipRect(var rect : TRect; XMax, YMax : integer);
begin
  if rect.Left < 0 then
    rect.Left:= 0;
  if rect.Top < 0 then
    rect.Top:= 0;
  if rect.Right > XMax then
    rect.Right:= XMax;
  if rect.Bottom > YMax then
    rect.Bottom:= YMax;
end;

////////////////////////////////////////////////////////////////////////////////

procedure TfrmGriff.FormActivate(Sender: TObject);
begin
   IsActive := true;
end;

procedure TfrmGriff.FormCreate(Sender: TObject);
begin
  GriffPartitur := TGriffPartitur.Create;
  GriffPartitur.ColorNote := $ff0000;
  GriffPartitur.UseEllipses := false;
  playLocation := -1;
  MidiOutput.GenerateList;
  MidiInput.GenerateList;
  if (System.ParamCount = 1) and
     FileExists(System.ParamStr(1)) and
     (ExtractFileExt(System.ParamStr(1)) = '.griff') then
  begin
    if GriffPartitur.LoadFromGriffFile(System.ParamStr(1)) then
    begin
      Caption := ExtractFilename(System.ParamStr(1));
      Show;
    end;
  end;
end;

procedure TfrmGriff.FormDeactivate(Sender: TObject);
begin
  IsActive := false;
end;

procedure TfrmGriff.GetClippedMousePos(var Pos : TPoint; X, Y : integer);
var w, h : integer;
begin
{$ifdef UseBitmap}
  w:= bmPaint.Width;
  h:= bmPaint.Height;
{$else}
  if GriffPartitur.quarterNote = 0 then
  begin
    Pos := TPoint.Create(0, 0);
    exit;
  end;
  w:= Width + HorzScrollBar.Position - 20;
  h:= Height + VertScrollBar.Position;
{$endif}
  Pos.X := Max(0, Min(w, X));
  Pos.Y := Max(0, Min(h, Y));
end;

procedure TfrmGriff.ShowSelected;
var
  size, i, w: integer;
begin
  // HorzScrollBar anpassen
  i := GriffPartitur.UsedEvents - 10;
  if i < 0 then
    i := 0;
  Size := 0;
  while i < GriffPartitur.UsedEvents do
  begin
    if Size < GriffPartitur.GriffEvents[i].AbsRect.Right then
      Size := GriffPartitur.GriffEvents[i].AbsRect.Right;
    inc(i);
  end;
  HorzScrollBar.Range := GriffPartitur.TickToScreen(Size) + 8*pitch_width;

  // Selected soll sichtbar sein
  if GriffPartitur.Selected >= 0 then
  begin
    w := GriffPartitur.SelectedEvent.AbsRect.Right + GriffPartitur.quarterNote;
    if HorzScrollBar.Position + Width < GriffPartitur.TickToScreen(w) then
    begin
      HorzScrollBar.Position :=
        GriffPartitur.TickToScreen(GriffPartitur.SelectedEvent.AbsRect.Right) - 3*Width div 4;
    end else
    if HorzScrollBar.Position > GriffPartitur.TickToScreen(GriffPartitur.SelectedEvent.AbsRect.Left) then
    begin
      if HorzScrollBar.Position > Width div 4 then
        HorzScrollBar.Position := HorzScrollBar.Position - Width div 4
      else
        HorzScrollBar.Position := 0;
    end;
  end;
end;
  {
function TfrmGriff.GetKeyIndex(var Event: UAmpel.TMouseEvent; Key: word): boolean;
var
  i: integer;
  Row: byte;
begin
  result := false;
  Event.Clear;
  Event.Key := Key;
  Event.P := TPoint.Create(0, 0);
  if Key in [vk_F5 .. vk_F12] then
  begin
    if GetKeyState(vk_Control) < 0 then
      Event.Row_ := 5
    else
      Event.Row_ := 6;
    Event.Index_ := Key - vk_F5 + 1;
    Result := true;
  end else
  for Row := 1 to 4 do
    for i := 0 to High(TKeys) do
      if (TastKeys[Row][i] > #0) and (TastKeys[Row][i] = AnsiChar(Key)) then
      begin
        Event.Row_ := Row;
        Event.Index_ := 11-i;
        result := GriffPartitur.Instrument.Push.Col[Row][Event.Index_] > 0;
        break;
      end;
  if (Event.Row_ = 4) and (GriffPartitur.Instrument.Columns = 3) then
  begin
    Event.Row_ := 5;
    if Event.Index_>= 2  then
    begin
      dec(Event.Index_, 2);
      result := true;
    end;
  end;
end;
}
procedure TfrmGriff.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Event: UAmpel.TMouseEvent;
begin
  if (GetKeyState(vk_RMenu) < 0) and
     frmAmpel.GetKeyIndex(Event, Key) then
  begin
    frmAmpel.GenerateNewNote(Event);
    exit;
  end;
  if Key = 27 then
  begin
    with GriffPartitur do
    begin
      Unselect;
      if @RubberChanges <> nil then
        RubberChanges(rectRubberBand);
      Selected := -1;
    end;
    if @SelectedChanges <> nil then
      SelectedChanges(GriffPartitur.SelectedEvent);
    invalidate;
  end else
  if GriffPartitur.KeyDown(Key, Shift) then
  begin
    GriffPartitur.SortEvents;
    if @SelectedChanges <> nil then
      SelectedChanges(GriffPartitur.SelectedEvent);

    ShowSelected;

    if (GriffPartitur.SelectedEvent = nil) and
       not Griffpartitur.bRubberBand and not Griffpartitur.bRubberBandOk then
    begin
      sChangingCursor := [];
      Cursor:= crDefault;
    end;
    invalidate;
  end;
end;

procedure TfrmGriff.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//
end;

procedure TfrmGriff.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Pos, NotenPoint : TPoint;
  iEvent: integer;
begin
  if mbLeft = Button then begin
    GetClippedMousePos(Pos, X + HorzScrollBar.Position, Y + VertScrollBar.Position);
    GriffPartitur.ScreenToNotePoint(NotenPoint, Pos);
    pDrag := NotenPoint;

    Griffpartitur.bRubberBand:= false;
    Griffpartitur.bRubberBandOk:= false;
    if Cursor = crDefault then
    begin
      iEvent := GriffPartitur.SearchGriffEvent(NotenPoint);
      if GriffPartitur.Selected = iEvent then
      begin
        iEvent := -1;
        GriffPartitur.BackEvent := -1;
      end;
      GriffPartitur.Selected := iEvent;
      if (iEvent >= 0) and (GriffPartitur.BackEvent >= 0) then
      begin
        x := iEvent;
        y := GriffPartitur.BackEvent;
        if x < y then
        begin
          x := y;
          y := iEvent;
        end;
        with GriffPartitur do
        begin
          rectRubberBand.Top := 4*row_height;
          rectRubberBand.Height := 22*row_height;
          rectRubberBand.Left := TickToScreen(GriffEvents[y].AbsRect.Left) + 1;
          rectRubberBand.Right := TickToScreen(GriffEvents[x].AbsRect.Right) - 1;
          bRubberBand := false;
          bRubberBandOk := true;
          BackEvent := -1;
          Selected := -1;
        end;
      end else
      if @SelectedChanges <> nil then
        SelectedChanges(GriffPartitur.SelectedEvent);
      sChangingCursor := [];
      invalidate;
    end;
  end else
  if mbRight = Button then begin
    if sChangingCursor <> [] then begin
    end else begin
      with Griffpartitur do
      begin
        GetClippedMousePos(rectRubberBand.TopLeft, X + HorzScrollBar.Position,
                                                   Y + VertScrollBar.Position);
        rectRubberBand.Right:= rectRubberBand.Left;
        rectRubberBand.Bottom:= rectRubberBand.Top;
        bRubberBand:= true;
        bRubberBandOk:= false;
      end;
      GriffPartitur.Selected := -1;
      sChangingCursor:= [];
      Cursor:= crDefault;

      SetCaptureControl(self);
    end;
  end;

end;

procedure TfrmGriff.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
const Delta = 5;
var
  NotenPoint, Pos: TPoint;
  rect: TRect;
begin
  xRGB:= X + HorzScrollBar.Position;
  yRGB:= Y + VertScrollBar.Position;
  with GriffPartitur do
  begin
    if bRubberBand then begin
      GetClippedMousePos(rectRubberBand.BottomRight, xRGB, yRGB);
    //  writeln(rectRubberBand.Bottom);
      bRubberBandOk:= true;
      Rubber_In_Push := true;
      if @RubberChanges <> nil then
        RubberChanges(rectRubberBand);
      sChangingCursor:= [];
      Cursor:= crDefault;
      Invalidate;
    end else
    if bRubberBandOk then begin
      if ssRight in Shift then begin
        if sChangingCursor <> [] then begin
          if cmpTop in sChangingCursor then
            rectRubberBand.Top:=    Min(yRGB, rectRubberBand.Bottom-2);
          if cmpBottom in sChangingCursor then
            rectRubberBand.Bottom:= Max(yRGB, rectRubberBand.Top+2);
          if cmpLeft in sChangingCursor then
            rectRubberBand.Left:=   Min(xRGB, rectRubberBand.Right-2);
          if cmpRight in sChangingCursor then
            rectRubberBand.Right:=  Max(xRGB, rectRubberBand.Left+2);
          if [cmpDrag] = sChangingCursor then begin
            // Rechteck verschieben.
            xRGB:= pDrag.X - xRGB;
            yRGB:= pDrag.Y - yRGB;
            if rectRubberBand.Left - xRGB < 0 then
              xRGB:= rectRubberBand.Left;
            if rectRubberBand.Right - xRGB > HorzScrollBar.Range then
              xRGB:= rectRubberBand.Right - HorzScrollBar.Range;
            if rectRubberBand.Top - yRGB < 0 then
              yRGB:= rectRubberBand.Top;
            if rectRubberBand.Bottom - yRGB > VertScrollBar.Range then
              yRGB:= rectRubberBand.Bottom - VertScrollBar.Range;

            rectRubberBand.Offset(-xRGB, -yRGB);
            dec(pDrag.X, xRGB);
            dec(pDrag.Y, yRGB);
          end;
          invalidate;
        end;
      end else begin
        sChangingCursor:= [];
        if OverLine(xRGB, rectRubberBand.Left, rectRubberBand.Right, yRGB,
                    rectRubberBand.Top, Delta) then
          sChangingCursor:= sChangingCursor + [cmpTop];

        if OverLine(xRGB, rectRubberBand.Left, rectRubberBand.Right, yRGB,
                    rectRubberBand.Bottom-1, Delta) then
          sChangingCursor:= sChangingCursor + [cmpBottom];

        if OverLine(yRGB, rectRubberBand.Top, rectRubberBand.Bottom, xRGB,
                    rectRubberBand.Left, Delta) then
          sChangingCursor:= sChangingCursor + [cmpLeft];
        if OverLine(yRGB, rectRubberBand.Top, rectRubberBand.Bottom, xRGB,
                    rectRubberBand.Right-1, Delta) then
          sChangingCursor:= sChangingCursor + [cmpRight];

        pDrag.X:= xRGB;
        pDrag.Y:= yRGB;
        if (sChangingCursor = []) and
           rectRubberBand.Contains(pDrag) then
          sChangingCursor:= [cmpDrag];

        if ([cmpTop, cmpLeft] = sChangingCursor) or
           ([cmpBottom, cmpRight] = sChangingCursor) then begin
          Cursor:= crSizeNWSE;
        end else
        if ([cmpBottom, cmpLeft] = sChangingCursor) or
           ([cmpTop, cmpRight] = sChangingCursor) then begin
          Cursor:= crSizeNESW;
        end else
        if (cmpTop in sChangingCursor) or
           (cmpBottom in sChangingCursor) then begin
          Cursor:= crSizeNS;
        end else
        if (cmpLeft in sChangingCursor) or
           (cmpRight in sChangingCursor) then begin
          Cursor:= crSizeWE;
        end else
        if cmpDrag in sChangingCursor then
          Cursor:= crDrag
        else
          Cursor:= crDefault;
      end;
    end else begin
      Pos.X:= xRGB;
      Pos.Y:= yRGB;
      GriffPartitur.ScreenToNotePoint(NotenPoint, Pos);
      if (SelectedEvent <> nil) and (Shift = []) then
      begin
        rect := SelectedEvent.AbsRect;
        if rect.Contains(NotenPoint) then
        begin
          Cursor := crDrag;
          sChangingCursor := [cmpDrag];
          exit;
        end else
        if NotenPoint.Y = rect.Top then
        begin
          if (NotenPoint.X >= rect.Right) and (NotenPoint.X < rect.Right + 20) then
          begin
            Cursor := crSizeWE;
            sChangingCursor := [cmpRight];
            exit;
          end;
          if (NotenPoint.X < rect.Left) and (NotenPoint.X >= rect.Left - 20) then
          begin
            Cursor := crSizeWE;
            sChangingCursor := [cmpLeft];
            exit;
          end;
        end;
      end;
      Cursor:= crDefault;
    end;
  end;
end;

procedure TfrmGriff.FormMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Pos, NotenPoint: TPoint;
  Event: TGriffEvent;
  w, h: integer;
begin
  with GriffPartitur do
  begin
    if (mbRight = Button) and bRubberBand then begin
      bRubberBand:= false;
      MouseCapture:= false;
      GetClippedMousePos(rectRubberBand.BottomRight, X + HorzScrollBar.Position,
                                                     Y + VertScrollBar.Position);
      MakeOriginalRect(rectRubberBand);
      bRubberBandOk:= (rectRubberBand.Right > 1) and
                      (rectRubberBand.Bottom > 1) and
                      (rectRubberBand.Right > rectRubberBand.Left+1) and
                      (rectRubberBand.Bottom > rectRubberBand.Top+1);
      if @RubberChanges <> nil then
        RubberChanges(rectRubberBand);
      sChangingCursor:= [];
      Cursor:= crDefault;
      invalidate;
    end else
    if mbRight = Button then
    begin
        Cursor:= crDefault;
        sChangingCursor:= [];
    end else
    if (sChangingCursor <> []) and (Button = mbLeft) and (SelectedEvent <> nil) then
    begin
      GetClippedMousePos(Pos, X + HorzScrollBar.Position, Y + VertScrollBar.Position);
      GriffPartitur.ScreenToNotePoint(NotenPoint, Pos);
      w := NotenPoint.X - pDrag.X;
      w := GriffHeader.Details.GetRaster(w);
      h := NotenPoint.Y - pDrag.Y;
      Event := SelectedEvent^;
      if (w = 0) and (h = 0) then
      begin
        GriffPartitur.Selected := -1;
        if @SelectedChanges <> nil then
          SelectedChanges(GriffPartitur.SelectedEvent);
      end else
      if cmpDrag in sChangingCursor then
      begin
        if Event.NoteType = ntDiskant then
        begin
          Event.AbsRect.Top := NotenPoint.Y;
          Event.AbsRect.Height := 1;
        end else
          h := 0;
        if ChangeNote(@Event, h <> 0) then
        begin
          Event.AbsRect.Offset(w, 0);
          SelectedEvent^ := Event;
        end;
      end else begin
        if cmpLeft in sChangingCursor then
        begin
          w := -w;
          if Event.AbsRect.Width + w < GriffHeader.Details.smallestNote then
            w := GriffHeader.Details.smallestNote - Event.AbsRect.Width;
          SelectedEvent^.AbsRect.Offset(-w, 0);
          SelectedEvent^.AbsRect.Width := Event.AbsRect.Width + w;
        end else begin
          if Event.AbsRect.Width + w < GriffHeader.Details.smallestNote then
            w := GriffHeader.Details.smallestNote - Event.AbsRect.Width;
          SelectedEvent^.AbsRect.Width := Event.AbsRect.Width + w;
        end;
      end;
      if @SelectedChanges <> nil then
        SelectedChanges(GriffPartitur.SelectedEvent);
      sChangingCursor := [];
      GriffPartitur.SortEvents;
      invalidate;
      Cursor := crDefault;
    end;
  end;
end;

procedure TfrmGriff.FormPaint(Sender: TObject);
var rect, rectSource, rectFrame : TRect;
    w, h : integer;
begin
  if not GriffPartitur.PartiturLoaded then
    exit;
    
  Canvas.CopyMode:= cmSrcCopy;
  Canvas.Brush.Color:= Color;
  rectSource.Left:= 0;
  rectSource.Top:= 0;
  w:= width + HorzScrollBar.Position - 20;
  h:= row_height*(rows + 6);
  rectSource.Right:= w;
  rectSource.Bottom:= h;
  rectFrame:= rectSource;
  rect:= Canvas.ClipRect;
  inc(rectSource.Left, HorzScrollBar.Position + rect.Left);
  inc(rectSource.Top, VertScrollBar.Position + rect.Top);

  // Der Punkt rect.(Left, Top) entspricht dem Punkt rectSource.(Left, Top) in
  // der Bitmap.
  // Jetzt sollen die Rechtecke gleich gross gemacht werden.
  if rect.Right - rect.Left < rectSource.Right - rectSource.Left then begin
    rectSource.Right:= rectSource.Left + rect.Right - rect.Left;
  end else
    rect.Right:= rect.Left + rectSource.Right - rectSource.Left;
  if rect.Bottom - rect.Top < rectSource.Bottom - rectSource.Top then begin
    rectSource.Bottom:= rectSource.Top + rect.Bottom - rect.Top;
  end else
    rect.Bottom:= rect.Top + rectSource.Bottom - rectSource.Top;

  GriffPartitur.DrawGriff(canvas, canvas.ClipRect, HorzScrollBar.Position);

  if GriffPartitur.bRubberBandOk then begin
    // Das Band liegt auf den Punkten, die noch kopiert werden sollen.
    rect:= GriffPartitur.rectRubberBand;
    MakeOriginalRect(rect);
    ClipRect(rect, w, h);
    rect.Offset(-HorzScrollBar.Position, -VertScrollBar.Position);
    if (rect.Right >= 0) and (rect.Bottom >= 0) and
       ((rect.Left <> rect.Right) or (rect.Top <> rect.Bottom)) then begin
      Canvas.Brush.Color:= (not clBlack) and $ffffff;
      Canvas.DrawFocusRect(rect);
      Canvas.Brush.Color:= Color;
    end;
  end;
end;

procedure TfrmGriff.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
var
  KeyCode: word;
  Key: word;
  Shift: TShiftState;
begin
  if (Msg.KeyData and $40000000) <> 0 then // auto repeat
  begin
    Handled := true;
    exit;
  end;
  KeyCode := {Menus.}ShortCut(Msg.CharCode, KeyDataToShiftState(Msg.KeyData));
  Key := KeyCode and $ff;
  Shift := [];
  if (scShift and KeyCode) <> 0 then
    Shift := [ssShift];
  if (scCtrl and KeyCode) <> 0 then
    Shift := Shift + [ssCtrl];
  if (scAlt and KeyCode) <> 0 then
    Shift := Shift + [ssAlt];

//  if not GriffPartitur.PlayControl(Msg.CharCode, Msg.KeyData) then
    case Key of
      VK_TAB: FormKeyDown(self, Key, Shift);
      else begin
        //writeln(IntToHex(KeyCode));
        if KeyCode <> 32786 then
          Exit;
      end;
    end;

  Handled := true;
end;

procedure TfrmGriff.FormShow(Sender: TObject);
begin
  if GriffPartitur.PartiturLoaded then
  begin
 //   HorzScrollBar.Size := ClientWidth; //    Lazarus
    HorzScrollBar.Range := pitch_width*GriffPartitur.GetRelTotalDuration + 500
  end;
end;

procedure TfrmGriff.SetPlayRect(rect: TRect);
var
  p: integer;
begin
  if (rect.Left < HorzScrollBar.Position) then
  begin
    HorzScrollBar.Position := rect.Left - Width div 4;
    Invalidate;
  end else
  if rect.Right >= HorzScrollBar.Position + Width - {50} 2*pitch_width then
  begin
    p := GriffPartitur.GriffHeader.Details.MeasureFact*pitch_width;
    HorzScrollBar.Position := p*(rect.Left div p - 1);
    Invalidate;
  end else begin  
    rect.Offset(-HorzScrollBar.Position, 0);
    GriffPartitur.DrawGriff(canvas, rect, HorzScrollBar.Position);
  end;
end;


end.
