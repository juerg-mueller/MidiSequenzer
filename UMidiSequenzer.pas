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
unit UMidiSequenzer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
{$IFnDEF FPC}
  ShellApi, Windows,
{$ELSE}
  LCLIntf, LCLType, LMessages,
{$ENDIF}
  Messages, SysUtils, Variants, Classes, Graphics, Menus,
  Controls, Forms, Dialogs, ExtCtrls, StdCtrls,  
  UInstrument, UMyMidiStream, UGriffPartitur,
  UMyMemoryStream,
  UGriffEvent;

type

  { TfrmSequenzer }

  TfrmSequenzer = class(TForm)
    gbLoadSave: TGroupBox;
    btnOpen: TButton;
    btnLoadPartitur: TButton;
    gbHeader: TGroupBox;
    gbGriffEvent: TGroupBox;
    Label1: TLabel;
    edtSoundPitch: TEdit;
    Label2: TLabel;
    edtGriffPitch: TEdit;
    cbxCross: TCheckBox;
    cbxPush: TCheckBox;
    edtGriffLine: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    edtIndex: TEdit;
    cbxViertel: TComboBox;
    cbxTakt: TComboBox;
    edtDeltaTimeTicks: TEdit;
    cbxSmallestNote: TComboBox;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    cbxTrimNote: TCheckBox;
    Label8: TLabel;
    edtBPM: TEdit;
    FileOpenDialog1: TOpenDialog;
    btnSaveMidi: TButton;
    SaveDialog1: TSaveDialog;
    Label9: TLabel;
    Label10: TLabel;
    edtLeftPos: TEdit;
    edtWidth: TEdit;
    cbxTranspose: TComboBox;
    Label12: TLabel;
    gbMidiSound: TGroupBox;
    cbxMidiOut: TComboBox;
    btnPlay: TButton;
    edtPlayDelay: TEdit;
    cbxMuteBass: TCheckBox;
    cbxNoSound: TCheckBox;
    Label11: TLabel;
    gbOptimize: TGroupBox;
    btnBassSynch: TButton;
    btnSmallest: TButton;
    btnLongerPitches: TButton;
    Panel1: TPanel;
    btnPurgeBass: TButton;
    cbxMidiInput: TComboBox;
    gbInstrument: TGroupBox;
    Label13: TLabel;
    cbxTransInstrument: TComboBox;
    cbTransInstrument: TComboBox;
    cbxMuteTreble: TCheckBox;
    Label14: TLabel;
    cbxVolta: TComboBox;
    cbxNoteType: TComboBox;
    Label15: TLabel;
    btnResetMidi: TButton;
    lblKeyboard: TLabel;
    Label17: TLabel;
    Button1: TButton;
    edtMidiFile: TComboBox;
    btnRealSound: TButton;
    cbxVirtual: TComboBox;
    lbVirtual: TLabel;
    btnRemoveSmall: TButton;
    btnSaveTest: TButton;
    Button2: TButton;
    sbVolumeOut: TScrollBar;
    lbBegleitung: TLabel;
    cbxTurboSound: TCheckBox;
    procedure cbxCrossChange(Sender: TObject);
    procedure cbxPushChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnLoadPartiturClick(Sender: TObject);
    procedure btnShowGriffClick(Sender: TObject);
    procedure edtSoundPitchExit(Sender: TObject);
    procedure edtGriffPitchExit(Sender: TObject);
    procedure btnPlayClick(Sender: TObject);
    procedure btnSmallestClick(Sender: TObject);
    procedure cbxSmallestNoteChange(Sender: TObject);
    procedure edtDeltaTimeTicksExit(Sender: TObject);
    procedure cbxTaktChange(Sender: TObject);
    procedure cbxViertelChange(Sender: TObject);
    procedure cbxNoSoundClick(Sender: TObject);
    procedure cbxTrimNoteClick(Sender: TObject);
    procedure cbxMidiOutChange(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormKeyPress(Sender: TObject; var Key: char);
    procedure FormKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormMouseLeave(Sender: TObject);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure edtBPMExit(Sender: TObject);
    procedure btnSaveMidiClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbTransInstrumentChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure edtPlayDelayExit(Sender: TObject);
    procedure cbxNoteTypeChange(Sender: TObject);
    procedure btnLongerPitchesClick(Sender: TObject);
    procedure edtWidthExit(Sender: TObject);
    procedure edtLeftPosExit(Sender: TObject);
    procedure btnBassSynchClick(Sender: TObject);
    procedure edtKeyPress(Sender: TObject; var Key: Char);
    procedure cbxMuteBassClick(Sender: TObject);
    procedure btnPurgeBassClick(Sender: TObject);
    procedure edtStopEnter(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
  {$ifdef fpc}
    procedure FormShortCut(var Msg: TLMKey; var Handled: Boolean);
  {$else}
    procedure FormShortCut(var Msg: TWMKey; var Handled: Boolean);
  {$endif}
    procedure btnRealSoundClick(Sender: TObject);
    procedure cbxTransInstrumentChange(Sender: TObject);
    procedure cbxMuteTrebleClick(Sender: TObject);
    procedure cbxVoltaChange(Sender: TObject);
    procedure btnResetMidiClick(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure cbxVoltaKeyUp(Sender: TObject; var Key: Word; Shift: TShiftState);
  {$ifdef dcc}
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
  {$endif}
    procedure cbxVirtualChange(Sender: TObject);
    procedure btnRemoveSmallClick(Sender: TObject);
    procedure btnSaveTestClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure sbVolumeOutChange(Sender: TObject);
  private
    InitDone: boolean;
    procedure SelectedChanges(SelectedEvent: PGriffEvent);
    function ChangeNote(Event: PGriffEvent; WithSound: boolean): boolean;
    procedure MessageEvent(var Msg: TMsg; var Handled: Boolean);
  public
    procedure btnSaveGriffClick(Sender: TObject);

    procedure AktualizeHeader;
    procedure OnMidiInData(aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer);
  end;

var
  frmSequenzer: TfrmSequenzer;

implementation

{$IFnDEF FPC}
  {$R *.dfm}
{$ELSE}
  {$R *.lfm}
{$ENDIF}

uses
  UfrmGriff,
  umidi,
{$ifdef dcc}
  UVirtual,
{$endif}
{$ifdef mswindows}
  Midi,
{$else}
  urtmidi,
{$endif}
  UAmpel, UMidiDataStream, UEventArray, UGriffPlayer,
  UGriffArray, UXmlNode, UXmlParser,
  USheetMusic, UMuseScore, UFormHelper, UMidiEvent,
  UGrifftabelle;

procedure InsertList(Combo: TComboBox; const arr: array of string);
var
  i: integer;
begin
  Combo.Items.Clear;
  for i := 0 to Length(arr)-1 do
    Combo.AddItem(arr[i], nil);
  Combo.Items.Insert(0, '');
  Combo.ItemIndex := 0;
end;

{$ifdef dcc}
function GetConsoleWindow: HWND; stdcall; external kernel32;

procedure TfrmSequenzer.WMDropFiles(var Msg: TWMDropFiles);
var
  DropH: HDROP;               // drop handle
  DroppedFileCount: Integer;  // number of files dropped
  FileNameLength: Integer;    // length of a dropped file name
  FileName: string;           // a dropped file name
  Ext: string;
begin
  inherited;

  DropH := Msg.Drop;
  try
    DroppedFileCount := DragQueryFile(DropH, $FFFFFFFF, nil, 0);
    if (DroppedFileCount > 0) and
       (btnPlay.Caption = 'Play Partitur') then
    begin
      FileNameLength := DragQueryFile(DropH, 0, nil, 0);
      SetLength(FileName, FileNameLength);
      DragQueryFile(DropH, 0, PChar(FileName), FileNameLength + 1);

      Ext := ExtractFileExt(FileName);
      if (Ext = '.griff') or
         (Ext = '.xml') or (Ext = '.musicxml') or
         (Ext = '.mscx') or
         (Ext = '.mid') or (Ext = '.midi') then
      begin
        if not GriffPartitur_.PartiturLoaded or
           (Warning('Die Partitur wird überschrieben. Wollen Sie das?') = IDYES )then
        begin
          FileOpenDialog1.FileName := FileName;
          edtMidiFile.Text := FileName;
          btnLoadPartiturClick(nil);
        end;
      end;
    end;
  finally
    DragFinish(DropH);
  end;
  // Note we handled message
  Msg.Result := 0;
end;
{$endif}

procedure TfrmSequenzer.OnMidiInData(aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer);
var
  Event: TMouseEvent;
  Key: word;
  GriffEvent: TGriffEvent;
begin
  Event.Clear;
  Event.Pitch := aData1;
  Event.Row_ := 1;
  Event.Index_ := -1;
  Event.Push_ := ShiftUsed;
  if (aStatus = $b0) and (aData1 = 64) then
  begin
    Sustain_ := aData2 > 0;
    Key := 0;
    frmAmpel.FormKeyDown(self, Key, []);
  end else
  if aStatus = $80 then
  begin
    frmAmpel.AmpelEvents.EventOff(Event);
  end else
  if aStatus = $90 then
  begin
    GriffEvent.Clear;
    GriffEvent.InPush := Event.Push_;
    GriffEvent.SoundPitch := aData1;
    if GriffEvent.SoundToGriff(GriffPartitur_.Instrument) and
       (GriffEvent.InPush = Event.Push_) then
    begin
      Event.Row_ := GriffEvent.GetRow;
      Event.Index_ := GriffEvent.GetIndex;
      if (Event.Row_ > 0) and (Event.Index_ >= 0) then
      begin
        frmAmpel.AmpelEvents.NewEvent(Event);
        if (GetKeyState(vk_scroll) = 1) then //   numlock pause scroll
          frmGriff.GenerateNewNote(Event);
      end;
    end;
  end;
end;

procedure TfrmSequenzer.sbVolumeOutChange(Sender: TObject);
var
  s: string;
  p: double;
begin
  with Sender as TScrollBar do
  begin
    s := Format('Vol. Synth.  (%d %%)', [Position]);
    p := Position / 100.0;
  end;
  if Sender = sbVolumeOut then begin
    lbBegleitung.Caption := s;
    VolumeOut := p;
  end;
end;

procedure TfrmSequenzer.btnLoadPartiturClick(Sender: TObject);
const
  scoreMusic: AnsiString = '<score-partwise';
  scoreMS:    AnsiString = '<museScore';
var
  i, p: integer;
  PartiturFileName: string;
  ext: string;
  Ok: boolean;
  Index: integer;
  Partitur: TEventArray;
  s: string;
  SaveStream: TMidiSaveStream;

  procedure PrepareFinally;
  begin
    with GriffPartitur_ do
    begin
      SortEvents;
      edtDeltaTimeTicks.Text := IntToStr(quarterNote);
      if GriffHeader.Details.IsSet then
      begin
        edtBPM.Text := IntToStr(GriffHeader.Details.QuarterPerMin);
        cbxTakt.ItemIndex := GriffHeader.Details.MeasureFact - 2;
        if GriffHeader.Details.MeasureDiv = 8 then
          cbxViertel.ItemIndex := 1
        else
          cbxViertel.ItemIndex := 0;
      end else begin
        edtDeltaTimeTicksExit(nil);
        cbxTaktChange(nil);
        cbxViertelChange(nil);
      end;
    end;
    cbxSmallestNoteChange(nil);
    edtPlayDelayExit(nil);

    AktualizeHeader;

    frmGriff.HorzScrollPos := 0;
    frmGriff.Show;
    frmGriff.Caption := ExtractFilename(PartiturFileName);
    GriffPartitur_.PartiturFileName := PartiturFileName;
    GriffPartitur_.PlayEvent.Clear;

    SetLength(PartiturFileName, Length(PartiturFileName) - Length(ExtractFileExt(PartiturFileName)));
  end;

  procedure ChangeInstrument(Name: AnsiString);
  begin
    i := InstrumentIndex(Name);
    if (i >= 0) and (cbTransInstrument.ItemIndex <> i) and
       (i < cbTransInstrument.Items.Count) then
    begin
      cbTransInstrument.ItemIndex := i;
      cbTransInstrumentChange(nil);
    end;

  end;

begin
  frmGriff.Hide;
  GriffPartitur_.Clear;
  SelectedChanges(nil);

  if edtMidiFile.Text = '' then
    btnOpenClick(Sender);

  PartiturFileName := FileOpenDialog1.FileName;
  edtMidiFile.Text := PartiturFileName;
  if PartiturFileName = '' then
    exit;
  if not FileExists(PartiturFileName) then
    raise Exception.Create('File does not exist!');

  ext := LowerCase(ExtractFileExt(PartiturFileName));

  if ext = '.griff' then
  begin
    GriffPartitur_.LoadFromGriffFile(PartiturFileName);
    PrepareFinally;
    ChangeInstrument(GriffPartitur_.Instrument.Name);
    Index := 11 + GriffPartitur_.Instrument.TransposedPrimes;
    if (Index  >= 0) and (Index < cbxTransInstrument.Items.Count) then
      cbxTransInstrument.ItemIndex := Index;
    PrepareFinally;
    exit;
  end;

  if (ext = '.xml') or (ext = '.musicxml') or (ext = '.mxl') or
     (ext = '.mscx') or (ext = '.mscz') then
  begin
    cbxTransInstrument.ItemIndex := 11;
    if (ext = '.mscx') or (ext = '.mscz') then
      Ok := LoadFromMscx(GriffPartitur_, PartiturFileName)
    else
      Ok := GriffPartitur_.LoadFromMusicXML(PartiturFileName);
    if Ok then
    begin
      PrepareFinally;
      frmGriff.Show;
      frmGriff.Invalidate;
    end else
      Application.MessageBox(PChar('Datei "' + PartiturFileName + '" nicht gelesen!'), 'Fehler');
    exit;
  end;

  Partitur := TEventArray.Create;
  try
   // GriffPartitur_.SetInstrument(InstrumentsList[cbTransInstrument.ItemIndex].Name);
    Partitur.DetailHeader := GriffPartitur_.GriffHeader.Details;

    if ext = '.txt' then
    begin
      Ok := Partitur.LoadMidiFromSimpleFile(PartiturFileName, false);
    end else
    begin
      Ok := Partitur.LoadMidiFromFile(PartiturFileName, false);
    end;
    if not Ok then
    begin
      Application.MessageBox(PChar('Datei "' + PartiturFileName + '" nicht gelesen!'), 'Fehler');
      Partitur.Free;
      exit;
    end;

  {$ifdef DEBUG}
    SaveStream := Partitur.SaveMidiToStream(Partitur.TrackArr, Partitur.DetailHeader, false) as TMidiSaveStream;
    if SaveStream <> nil then
    begin
      s := ExtractFilePath(ParamStr(0)) + 'test.mid';
      SaveStream.SaveToFile(s);
      s := ExtractFilePath(ParamStr(0)) + 'test.txt';
      TSimpleDataStream.SaveMidiToSimpleFile(s, SaveStream);
      SaveStream.Free;
    end;
  {$endif}

    ChangeInstrument(Partitur.Instrument);
    Partitur.Repair;
  {$ifdef DEBUG}
    SaveStream := Partitur.SaveMidiToStream(Partitur.TrackArr, Partitur.DetailHeader, false) as TMidiSaveStream;
    if SaveStream <> nil then
    begin
      s := ExtractFilePath(ParamStr(0)) + 'repair.txt';
      TSimpleDataStream.SaveMidiToSimpleFile(s, SaveStream);
      SaveStream.Free;
    end;
  {$endif}

    Partitur.Transpose(cbxTranspose.ItemIndex - 11);
    cbxSmallestNoteChange(nil);

    GriffPartitur_.GriffHeader.Details := Partitur.DetailHeader;
    GriffPartitur_.LoadFromEvents(Partitur, Partitur.GetCopyright);
    //GriffPartitur_.RepeatToRest;

    if not TGriffArray.CorrectSoundPitch(GriffPartitur_.GriffEvents, GriffPartitur_.Instrument) then
    begin
    {$ifdef CONSOLE}
      writeln('Fehler beim Einlesen entdeckt!');
    {$endif}
    end;

    PrepareFinally;

  {$ifndef DEBUG}
    s := ExtractFilePath(ParamStr(0)) + 'GriffPartitur.mid';
    if GriffPartitur_.PartiturLoaded then
    begin
      GriffPartitur_.SaveToNewMidiFile(s);
      if Partitur.MakeNewSingleTrack then
      begin

      end;
    end;
  {$endif}
  finally
    Partitur.Free;
  end;
end;

procedure TfrmSequenzer.btnLongerPitchesClick(Sender: TObject);
begin
  GriffPartitur_.MakeLongerPitches;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.btnOpenClick(Sender: TObject);
var
  s: string;
begin
  FileOpenDialog1.FileName := edtMidiFile.Text;
  if FileOpenDialog1.Execute then
  begin
    if not FileExists(FileOpenDialog1.FileName) then
      raise Exception.Create('File does not exist.');

    s := FileOpenDialog1.FileName;
    FileOpenDialog1.InitialDir := ExtractFilePath(s);
    if edtMidiFile.Items.IndexOf(s) < 0 then
    begin
      edtMidiFile.Items.Insert(0, s);
      edtMidiFile.ItemIndex := 0;
    end;
    btnLoadPartiturClick(Sender);
  end;
end;

procedure TfrmSequenzer.btnPlayClick(Sender: TObject);
var
  iEvent, i: integer;
  Player: TGriffPlayer;
begin
  if btnPlay.Caption = 'Play Partitur' then
  begin
    if not GriffPartitur_.PartiturLoaded then
      exit;

    frmAmpel.Hide;
    frmAmpel.WindowState := wsNormal;
    frmAmpel.Show;
    frmGriff.Hide;
    frmGriff.Show;
    ProcessMessages;
    sleep(100);
    ProcessMessages;

    cbxNoSound.Enabled := false;
    cbxMuteBass.Enabled := false;
    btnPlay.Caption := 'Stop Play';
    iEvent := GriffPartitur_.Selected;
    if iEvent >= 0 then
    begin
      GriffPartitur_.PlayEvent.Clear;
      GriffPartitur_.PlayEvent.iEvent := iEvent;
    end;
    GriffPartitur_.iAEvent := -1;
    GriffPartitur_.iBEvent := -1;
//    GriffPartitur_.Volume := 1.0;
//    repeat
      if iEvent < GriffPartitur_.UsedEvents then
        for i := 0 to iEvent-1 do
          if (GriffPartitur_.GriffEvents[i].AbsRect.Right >
              GriffPartitur_.GriffEvents[iEvent].AbsRect.Left) then
          begin
            iEvent := i;
            break;
          end;
      GriffPartitur_.StopPlay := false;
      GriffPartitur_.iSkipAmpelEvent := -1;
      GriffPartitur_.iSkipPlayEvent := -1;
      frmGriff.Invalidate;
      GriffPartitur_.StartPlay;
      Player := TGriffPlayer.Create(true);
      Player.GriffPartitur := GriffPartitur_;
      Player.Event := GriffPartitur_.PlayEvent;
      Player.Resume;
      GriffPartitur_.IsPlaying := true;
      try
        GriffPartitur_.PlayAmpel(GriffPartitur_.PlayEvent,
                                 StrToIntDef(edtPlayDelay.Text, 0));
        while not Player.Terminated_ do
        begin
          ProcessMessages;
          sleep(10);
        end;
      finally
        GriffPartitur_.IsPlaying := false;
        Player.Free;
      end;
//    until GriffPartitur_.iSkipPlayEvent < 0;
    btnPlay.Caption := 'Play Partitur';
    frmGriff.Repaint;
  end else begin
    GriffPartitur_.StopPlay := true;
    Sleep(100);
    ProcessMessages;
    btnPlay.Caption := 'Play Partitur';
  end;
  cbxNoSound.Enabled := true;
  cbxMuteBass.Enabled := true;

  ProcessMessages;
end;

procedure TfrmSequenzer.btnPurgeBassClick(Sender: TObject);
begin
  GriffPartitur_.PurgeBass;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.btnRealSoundClick(Sender: TObject);
begin
//  GriffPartitur_.DelayBass(StrToInt(edtPlayDelay.Text));
end;

procedure TfrmSequenzer.btnResetMidiClick(Sender: TObject);
begin
  ResetMidiOut;
end;

procedure TfrmSequenzer.btnSaveGriffClick(Sender: TObject);
var
  FileName, ext: string;
  n: integer;
begin
  if not GriffPartitur_.PartiturLoaded then
    exit;

  FileName := FileOpenDialog1.FileName;
  ext := ExtractFileExt(FileName);
  SetLength(FileName, Length(FileName) - Length(ext));
  with GriffPartitur_ do
  begin
    n := 1;
    while FileExists(FileName + '_' + IntToStr(n) + '.griff') do
      inc(n);
    if SaveToGriffFile(FileName + '_' + IntToStr(n) + '.griff') then
    begin
    {$if defined(CONSOLE)}
      writeln(FileName + '_' + IntToStr(n) + '.griff: saved');
    {$endif}
    end;
  end;
end;

procedure TfrmSequenzer.btnSaveMidiClick(Sender: TObject);
var
  s, s1: string;
  realSound: boolean;
  ext, ext1: string;
  Stream: TMyMemoryStream;
  Ok: boolean;
begin
  if not GriffPartitur_.PartiturLoaded then
    exit;

  realSound := Sender = btnRealSound;
  s := SaveDialog1.FileName;
  if s = '' then
    s := edtMidiFile.Text;
  SaveDialog1.FileName := {ExtractFilePath(s) +} ExtractFilename(edtMidiFile.Text);
{$ifdef fpc}
  if SaveDialog1.Execute then
{$else}
  if SaveDialog1.Execute(Handle) then
{$endif}
  begin
    s := SaveDialog1.FileName;
    SaveDialog1.InitialDir := ExtractFilePath(s);
    ext := LowerCase(ExtractFileExt(s));
    ext1 := '';
    case SaveDialog1.FilterIndex of
    {$ifdef dcc}
      2: if (ext <> '.mscx') and (ext <> '.mscz') then
           ext1 := '_.mscz';
    {$else}
      2: if (ext <> '.mscx') then
           ext1 := '_.mscx';
    {$endif}
      3: ext1 := '.ly';
      4: if (ext <> '.xml') and (ext <> '.musicxml') then
           ext1 := '.musicxml';
      6: begin
           ext1 := '.bmp';
         end;
      7: ext1 := '.bmp';
      else
         if ext <> '.mid' then
           ext1 := '.mid';
    end;
    if ext1 <> '' then
    begin
      SetLength(s, Length(s) - Length(ext));
      s := s + ext1;
    end;
    if FileExists(s) and (SaveDialog1.FilterIndex <> 7) then
      if Warning('File "' + s + '" existiert. Überschreiben?') <> IDYES then
        exit;

    case SaveDialog1.FilterIndex of
      2: Ok := SaveToMscx(GriffPartitur_, s);
      3: begin
           s1 := ExtractFileName(s);
           SetLength(s1, Length(s1)-Length(ExtractFileExt(s1)));
           Stream := GriffPartitur_.MakeLilyPond(s1);
           ok := (Stream <> nil) and (Stream.Size > 10);
           if ok then
           begin
             Stream.SaveToFile(s);
           end;
           Stream.Free;
         end;
      4: ok := GriffPartitur_.SaveToMusicXML(s, true);
      5: ok := GriffPartitur_.SaveToMidiFile(s, realSound);
      6: ok := GriffPartitur_.SaveToBmp(s);
      7: ok := UGrifftabelle.SaveToPdf(s);
      else begin
         ok := GriffPartitur_.SaveToNewMidiFile(s);
      end;
    end;
    if ok and (SaveDialog1.FilterIndex in [1, 5]) then
      frmGriff.Caption := ExtractFilename(s);
    if not ok then
      Warning('File "' + s + '" nicht gespeichert')
    else begin
{$if defined(CONSOLE)}
      writeln('File saved: ', s);
{$endif}
    end;
  end;
end;

procedure TfrmSequenzer.btnSaveTestClick(Sender: TObject);
const
  Filename = 'savetest.txt';
begin
  if GriffPartitur_.SaveTest(Filename) then
    writeln('File "', Filename, '" saved');
end;

procedure TfrmSequenzer.btnShowGriffClick(Sender: TObject);
begin
  if frmGriff.Visible then
  begin
    frmGriff.Hide;
    frmAmpel.Hide;
  end else begin
    frmAmpel.Show;
    frmGriff.Show;
  end;
end;

procedure TfrmSequenzer.btnSmallestClick(Sender: TObject);
begin
  GriffPartitur_.MakeSmallestNote;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.Button1Click(Sender: TObject);
begin
  GriffPartitur_.CheckSustain;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.Button2Click(Sender: TObject);
begin
  GriffPartitur_.BassGleichlang;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.btnRemoveSmallClick(Sender: TObject);
begin
  GriffPartitur_.RemoveSmallestNote;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.btnBassSynchClick(Sender: TObject);
var
  t, d1, d2: double;
begin
  d1 := StrToIntDef(edtDeltaTimeTicks.text, 192);
  d2 := StrToIntDef(edtBPM.text, 120);
  t := GriffPartitur_.TrimTakt; //BassSynch;
  edtDeltaTimeTicks.text := IntToStr(round(t));
  edtBPM.text := IntToStr(round(d1*d2/t));
  edtDeltaTimeTicksExit(Sender);
  edtBPMExit(Sender);
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.cbTransInstrumentChange(Sender: TObject);
var
  s: string;
begin
  edtStopEnter(nil);
  GriffPartitur_.LoadChanges;
  if cbTransInstrument.ItemIndex < 0 then
    cbTransInstrument.ItemIndex := 0;
  s := cbTransInstrument.Items[cbTransInstrument.ItemIndex];
  cbTransInstrument.Text := s;
  GriffPartitur_.SetInstrument(AnsiString(s));
  cbxTransInstrumentChange(nil);

  frmAmpel.ChangeInstrument(@GriffPartitur_.Instrument);
  if Sender <> nil then
    OpenMidiMicrosoft;

  SelectedChanges(nil);
end;

procedure TfrmSequenzer.cbxTransInstrumentChange(Sender: TObject);
var
  delta: integer;
begin
  edtStopEnter(nil);
  if cbxTransInstrument.ItemIndex >= 0 then
  begin
    delta := cbxTransInstrument.ItemIndex - 11;
    GriffPartitur_.TransposeInstrument(delta);
  end;
end;

procedure TfrmSequenzer.cbxNoteTypeChange(Sender: TObject);
var
  Index: integer;
  Event: PGriffEvent;
  Instrument: PInstrument;
begin
  Event := GriffPartitur_.SelectedEvent;
  Instrument := @GriffPartitur_.Instrument;
  if (Event <> nil) and (Instrument <> nil) then
  begin
    with Event^ do
      case cbxNoteType.ItemIndex of
        ord(ntDiskant):
          if NoteType = ntBass then begin
            NoteType := ntDiskant;
            Cross := false;
            InPush := false;
            Index := trunc(22*(GriffPitch)/8.0);
            if Instrument.bigInstrument then
            begin
              if (Index > MaxGriffIndex) then
                Index := MaxGriffIndex;
              if Index < 0 then
                Index := 0;
            end else begin
              if (Index > MaxGriffIndex-2) then
                Index := MaxGriffIndex-2;
              if Index < 2 then
                Index := 2;
            end;
            AbsRect.Top := Index;
            AbsRect.Height := 1;
            if odd(Index) then
            begin
              SoundPitch := Instrument^.RowIndexToSound(2, Index div 2, InPush);
              GriffPitch := RowIndexToGriff(2, Index div 2);
            end else begin
              GriffPitch := RowIndexToGriff(1, Index div 2);
              SoundPitch := Instrument^.RowIndexToSound(1, Index div 2, InPush);
            end;
          end;
        ord(ntBass):
          begin
            NoteType := ntBass;
            InPush := false;
            Cross := false;
            GriffPitch := trunc(8*AbsRect.Top/22.0) + 1;
            if GriffPitch > 8 then
              GriffPitch := 8;
            if GriffPitch < 1 then
              GriffPitch := 1;
            SoundPitch := Instrument.Bass[false, GriffPitch];
            AbsRect.Top := -1;
            AbsRect.Height := 1;
            AbsRect.Width := GriffPartitur_.quarterNote div 3;
          end;
        ord(ntRest):
          NoteType := ntRest;
        ord(ntRepeat):
          NoteType := ntRepeat;
      end;
    frmGriff.Invalidate;
    SelectedChanges(Event);
  end;
end;

procedure TfrmSequenzer.cbxMidiInputChange(Sender: TObject);
begin
  Sustain_:= false;
  MidiInput.CloseAll;
  if cbxMidiInput.ItemIndex > 0 then
    MidiInput.Open(cbxMidiInput.ItemIndex - 1);
end;

procedure TfrmSequenzer.cbxMidiOutChange(Sender: TObject);
begin
  edtStopEnter(nil);
  if cbxMidiOut.ItemIndex >= 0 then
  begin
    MidiOutput.Close(MicrosoftIndex);
    if iVirtualMidi <> cbxMidiOut.ItemIndex then
      MicrosoftIndex := cbxMidiOut.ItemIndex-1
    else
      cbxMidiOut.ItemIndex := MicrosoftIndex-1;

    OpenMidiMicrosoft;
  end;
end;

procedure TfrmSequenzer.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
var
  Msg: TMsg;
  Handled: boolean;
begin
{$ifdef fpc}
  Handled := false;
  Msg.message := WM_KEYDOWN;
  Msg.wParam := Key;
  MessageEvent(Msg, Handled);
{$endif}
end;

procedure TfrmSequenzer.FormKeyPress(Sender: TObject; var Key: char);
begin
  //
end;

procedure TfrmSequenzer.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  //
end;

procedure TfrmSequenzer.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  //
end;

procedure TfrmSequenzer.FormMouseLeave(Sender: TObject);
begin
  //
end;

procedure TfrmSequenzer.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  //
end;

procedure TfrmSequenzer.cbxMuteBassClick(Sender: TObject);
begin
  GriffPartitur_.noBass := cbxMuteBass.Checked;
end;

procedure TfrmSequenzer.cbxMuteTrebleClick(Sender: TObject);
begin
  GriffPartitur_.noTreble := cbxMuteTreble.Checked;
end;

procedure TfrmSequenzer.cbxNoSoundClick(Sender: TObject);
begin
  GriffPartitur_.noSound := cbxNoSound.Checked;
end;

procedure TfrmSequenzer.cbxSmallestNoteChange(Sender: TObject);
begin
  with GriffPartitur_ do
  begin
    if not PartiturLoaded then
      exit;
    case cbxSmallestNote.ItemIndex of
      0: GriffHeader.Details.smallestFraction := 8;
      1: GriffHeader.Details.smallestFraction := 16;
      2: GriffHeader.Details.smallestFraction := 32;
      else GriffHeader.Details.smallestFraction := 8;
    end;
    if (GriffHeader.Details.smallestNote = 0) and (Sender <> nil) then
    begin
      case quarterNote of
        1..3: cbxSmallestNote.ItemIndex := 0;
        4..7: cbxSmallestNote.ItemIndex := 1;
        else  cbxSmallestNote.ItemIndex := 2;
      end;
      cbxSmallestNoteChange(nil);
    end;
  end;
end;

procedure TfrmSequenzer.cbxTaktChange(Sender: TObject);
begin
  GriffPartitur_.GriffHeader.Details.MeasureFact := cbxTakt.ItemIndex + 2;
  frmGriff.Invalidate;
end;


procedure TfrmSequenzer.cbxTrimNoteClick(Sender: TObject);
begin
  GriffPartitur_.trimNote := cbxTrimNote.Checked;
end;

procedure TfrmSequenzer.cbxViertelChange(Sender: TObject);
var
  q: integer;
begin
//  q := GriffPartitur_.quarterNote;
  case cbxViertel.ItemIndex of
    0: q := 4;
    1: q := 8;
    else q := 4;
  end;
  GriffPartitur_.GriffHeader.Details.MeasureDiv :=  q;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.cbxVirtualChange(Sender: TObject);
begin
  with GriffPartitur_ do
  begin
    if iVirtualMidi >= 0 then
      MidiOutput.Close(iVirtualMidi);
    iVirtualMidi := CbxVirtual.ItemIndex - 1;
    if cbxMidiOut.ItemIndex = iVirtualMidi then
    begin
      iVirtualMidi := -1;
      CbxVirtual.ItemIndex := 0;
    end;
    if iVirtualMidi >= 0 then
    begin
      MidiOutput.Open(iVirtualMidi);
    end;
  end;
end;

procedure TfrmSequenzer.cbxVoltaChange(Sender: TObject);
var
  Event: PGriffEvent;
begin
  with GriffPartitur_ do
  begin
    Event := SelectedEvent;
    if Event <> nil then
    begin
      case cbxVolta.ItemIndex of
        1: Event.Repeat_ := rStart;
        2: Event.Repeat_ := rStop;
        3: Event.Repeat_ := rVolta1Start;
        4: Event.Repeat_ := rVolta1Stop;
        5: Event.Repeat_ := rVolta2Start;
        6: Event.Repeat_ := rVolta2Stop;
        else Event.Repeat_ := rRegular;
      end;
      if ord(Event.Repeat_) > 0 then
        cbxVolta.Color := $00ffff
      else
        cbxVolta.Color := $ffffff;
    end;
  end;
end;

procedure TfrmSequenzer.cbxVoltaKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
//  cbxVoltaChange(Sender);
end;

procedure TfrmSequenzer.edtBPMExit(Sender: TObject);
var
  b: integer;
begin
  b := StrToIntDef(edtBPM.Text, 0);
  if b >= 20 then
    GriffPartitur_.GriffHeader.Details.QuarterPerMin := b;
end;

procedure TfrmSequenzer.edtDeltaTimeTicksExit(Sender: TObject);
begin
  GriffPartitur_.GriffHeader.Details.TicksPerQuarter := StrToInt(edtDeltaTimeTicks.Text);
  cbxSmallestNoteChange(Sender);
  cbxViertelChange(Sender);
end;

procedure TfrmSequenzer.edtKeyPress(Sender: TObject;
  var Key: Char);
begin
  if Key = #13 then
  begin
    Key := #0;
    self.SelectNext(Sender as TWinControl, true, true);
  end;
end;

procedure TfrmSequenzer.AktualizeHeader;
begin
  with GriffPartitur_.GriffHeader.Details do
  begin
    edtDeltaTimeTicks.Text := IntToStr(TicksPerQuarter);
    edtBPM.Text := IntToStr(QuarterPerMin);
  end;
end;

procedure TfrmSequenzer.edtGriffPitchExit(Sender: TObject);
var
  Event: PGriffEvent;
  Index: integer;
begin
  Event := GriffPartitur_.SelectedEvent;
  if (Event <> nil) and
     (Event.NoteType in [ntDiskant, ntBass]) then
    with Event^ do
     if NoteType = ntBass then
     begin
       Index := StrToIntDef(edtGriffPitch.Text, 6);
       if Index < 1 then
         Index := 1;
       if Index > 8 then
         Index := 8;
       GriffPitch := Index;
       edtGriffPitch.Text := IntToStr(Index);
       ChangeNote(Event, true);
       SelectedChanges(Event);
     end;
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.edtLeftPosExit(Sender: TObject);
var
  l, w: integer;
  Event: PGriffEvent;
begin
  l := StrToIntDef(edtLeftPos.Text, -1);
  Event := GriffPartitur_.SelectedEvent;
  if (Event <> nil) and (l >= 0) then
  begin
    if abs(l - Event.AbsRect.Left) < 200 then
    begin
      w := Event.AbsRect.Width;
      Event.AbsRect.Left := l;
      Event.AbsRect.Width := w;
      GriffPartitur_.SortEvents;
    end;
  end;
  SelectedChanges(Event);
end;

procedure TfrmSequenzer.edtStopEnter(Sender: TObject);
begin
  GriffPartitur_.StopPlay := true;
  Sleep(100);
end;

procedure TfrmSequenzer.edtPlayDelayExit(Sender: TObject);
begin
  GriffPartitur_.PlayDelay := StrToIntDef(edtPlayDelay.Text, 0);
  edtPlayDelay.Text := IntToStr(GriffPartitur_.PlayDelay);
end;

procedure TfrmSequenzer.edtSoundPitchExit(Sender: TObject);
var
  Event: PGriffEvent;
  Event1: TGriffEvent;
  Pitch1, Pitch2, Col1, Col2, Index: integer;
  sPitch: integer;
  s: string;
begin
  Event := GriffPartitur_.SelectedEvent;
  if Event = nil then
    exit;

  s := edtSoundPitch.Text;
  s := Trim(s);
  if Pos(' ', s) > 0 then
    SetLength(s, Pos(' ', s) - 1);
  sPitch := StrToInt(s);
  with GriffPartitur_ do
  begin
    Event1 := Event^;
    if Event1.GriffToSound(Instrument) and
       (Event1.SoundPitch = sPitch) then
      // Korrektes Pitch nicht verwärfen!
    else
      with Event^ do
      begin
        Pitch1 := Instrument.SoundToGriff(sPitch, InPush, Col1, Index);
        Pitch2 := Instrument.SoundToGriff(sPitch, not InPush, Col2, Index);
        if (Pitch1 >= 0) or (Pitch2 >= 0) then
        begin
          SoundPitch := sPitch;
          if Pitch1 >= 0 then
          begin
            Cross := Col1 >= 3;
            GriffPitch := Pitch1;
          end else begin
            InPush := not InPush;
            Cross := Col2 >= 3;
            GriffPitch := Pitch2;
          end;
          AbsRect.Top := GetPitchLine(GriffPitch);
        end;
      end;
  end;
  SelectedChanges(Event);
  frmGriff.Invalidate;
end;

procedure TfrmSequenzer.edtWidthExit(Sender: TObject);
var
  w: integer;
begin
  if GriffPartitur_.SelectedEvent <> nil then
  begin
    w := StrToIntDef(edtWidth.Text, 0);
    if w > 10 then
    begin
      GriffPartitur_.SelectedEvent.AbsRect.Width := w;
      GriffPartitur_.SortEvents;
    end;
    SelectedChanges(GriffPartitur_.SelectedEvent);
  end else
    edtWidth.Text := '';
end;

{$ifdef fpc}
procedure TfrmSequenzer.FormShortCut(var Msg: TLMKey; var Handled: Boolean);
{$else}
procedure TfrmSequenzer.FormShortCut(var Msg: TWMKey; var Handled: Boolean);
{$endif}
var
  KeyCode: word;
begin
  if GriffPartitur_.PlayControl(Msg.CharCode, Msg.KeyData) then
  begin
    Handled := true;
    exit;
  end;

// KeyCode := {Menus.}ShortCut(Msg.CharCode, KeyDataToShiftState(Msg.KeyData));
//  writeln(IntToHex(Keycode));
  //Handled := KeyCode = 32786;   }
end;

procedure TfrmSequenzer.FormShow(Sender: TObject);
var
  i: integer;
begin
  if InitDone then
    exit;

  frmGriff.SelectedChanges := SelectedChanges;
  GriffPartitur_.DoPlay := btnPlayClick;
  GriffPartitur_.DoSave := btnSaveGriffClick;
  GriffPartitur_.DoPlayRect := frmGriff.SetPlayRect;
  GriffPartitur_.SetInstrument(InstrumentsList_[cbTransInstrument.ItemIndex].Name);

  i := cbTransInstrument.Items.IndexOf('b-Oergeli');
  if i >= 0 then
    cbTransInstrument.ItemIndex := i;
  cbTransInstrumentChange(nil);
  frmAmpel.PlayControl := GriffPartitur_.PlayControl;
  frmAmpel.SelectedChanges := SelectedChanges;
  frmAmpel.Show;
  frmAmpel.KeyDown := frmGriff.FormKeyDown;

  InsertList(cbxMidiOut, MidiOutput.DeviceNames);
  OpenMidiMicrosoft;
  if MicrosoftIndex > 0 then
    cbxMidiOut.ItemIndex := MicrosoftIndex;
  MidiInput.OnMidiData := frmAmpel.OnMidiInData;

  InsertList(cbxVirtual, MidiOutput.DeviceNames);

  InsertList(cbxMidiInput, MidiInput.DeviceNames);
  cbxMidiInputChange(nil);

  InitDone := true;
end;

procedure TfrmSequenzer.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  GriffPartitur_.StopPlay := true;
  MidiInput.OnMidiData := nil;
end;

procedure TfrmSequenzer.FormCreate(Sender: TObject);
var
  i: integer;
begin
{$if defined(CPU64) or defined(WIN64)}
  {$ifdef fpc}
    Caption := Caption + ' (Lazarus 64)';
  {$else}
    Caption := Caption + ' (64)';
  {$endif}
{$else}
  {$ifdef fpc}
    Caption := Caption + ' (Lazarus 32)';
  {$else}
    Caption := Caption + ' (32)';
  {$endif}
{$endif}
  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList_) do
    cbTransInstrument.Items.Add(string(InstrumentsList_[i].Name));
  cbTransInstrument.ItemIndex := 0; //2;// 8;
  if FileExists('UMidiSequenzer.pas') then
  begin
//    if not RunningWine then
//      edtPlayDelay.Text := '350';
//    btnLongerPitches.Visible := true;
//    btnBassSynch.Visible := true;
//    cbxLoadAsGriff.Visible := true;
//    btnRealSound.Visible := true;
  end;
{$ifdef dcc}
{$if defined(CONSOLE)}
//  if not RunningWine then
//    ShowWindow(GetConsoleWindow, SW_SHOWMINIMIZED);
  SetConsoleTitle('MidiSequenzer - Trace Window');
{$endif}
  Application.OnMessage := MessageEvent;
  DragAcceptFiles(Self.Handle, true);

  UVirtual.LoopbackName := 'MidiSequenzer loopback';
  InstallLoopback;
  Sleep(10);
{$endif}
  Application.ProcessMessages;
  sbVolumeOutChange(sbVolumeOut);
end;

procedure TfrmSequenzer.cbxPushChange(Sender: TObject);
var
  Event: PGriffEvent;
begin
  Event := GriffPartitur_.SelectedEvent;
  if (Event <> nil) and
     (Event.NoteType in [ntDiskant, ntBass]) then
  begin
    with Event^ do
      if (NoteType = ntBass) and not GriffPartitur_.Instrument.BassDiatonic then
        cbxPush.Checked := false
      else
      if (InPush <> cbxPush.Checked) then
      begin
        InPush := not InPush;
        ChangeNote(Event, true);
        SelectedChanges(Event);
      end;
  end;
end;

procedure TfrmSequenzer.cbxCrossChange(Sender: TObject);
var
  Event: PGriffEvent;
begin
  Event := GriffPartitur_.SelectedEvent;
  if Event <> nil then
  begin
    with Event^ do
      if (NoteType in [ntDiskant, ntBass]) and
         (cbxCross.Checked <> Cross) then
      begin
        if NoteType = ntBass then
        begin
          Cross := cbxCross.Checked
        end else
        if (GriffPartitur_.Instrument.Columns < 4) and odd(AbsRect.Top) then
          cbxCross.Checked := false
        else begin
          Cross := cbxCross.Checked;
        end;
        ChangeNote(Event, true);
        SelectedChanges(Event);
      end;
  end;
end;

procedure TfrmSequenzer.MessageEvent(var Msg: TMsg; var Handled: Boolean);
begin
{$ifdef dcc}
  if (Msg.message = WM_KEYDOWN) and
     GriffPartitur_.PlayControl(Msg.wParam, Msg.lParam) then
  begin
    Handled := true;
    exit;
  end;
{$endif}
  frmAmpel.KeyMessageEvent(Msg, Handled);

  // keine messages für die console
  if (Msg.message = WM_KEYDOWN) and
     (Msg.wParam in [vk_f1..vk_f4]) then
  begin
    case Msg.wParam of
      vk_F1:
        begin
          if GriffPartitur_.PartiturLoaded then
            if Warning('Die Partitur wird überschrieben. Wollen Sie das?') <> IDYES then
            begin
              frmGriff.Show;
              exit;
            end;
          frmGriff.Caption := 'unbekannt';
          GriffPartitur_.Clear;
          GriffPartitur_.PartiturLoaded := true;
          edtDeltaTimeTicksExit(self);
          cbxTaktChange(self);
          cbxViertelChange(Self);
          edtBPMExit(nil);
          cbTransInstrumentChange(nil);
          GriffPartitur_.InsertNewEvent(-1);
          GriffPartitur_.Selected := 0;
          frmGriff.HorzScrollPos := 0;
          frmGriff.HorzScrollRange := 0;
          SelectedChanges(GriffPartitur_.SelectedEvent);
          frmGriff.Show;
        end;
      vk_F2:
        begin
          if GriffPartitur_.UsedEvents = 0 then
            GriffPartitur_.InsertNewEvent(0, false);
          if frmGriff.Visible then
          begin
            if frmGriff.IsActive then
            begin
              Hide;
              Show;
            end;
            frmGriff.Hide;
          end else
            frmGriff.Show;
        end;
      vk_F3:
        if frmAmpel.Visible then
        begin
          if frmAmpel.IsActive then
          begin
            Hide;
            Show;
          end;
          frmAmpel.Hide
        end else
          frmAmpel.Show;
  {$if defined(CONSOLE) and defined(dcc)}
      vk_F4: begin
               ShowWindow(GetConsoleWindow, SW_SHOWNORMAL);
            {   Application.ProcessMessages;
               Hide;
               Show;

               BringToFront; }
             end;
  {$endif}
    end;
    Handled := true;
  end;

end;

procedure TfrmSequenzer.FormDestroy(Sender: TObject);
begin
{$ifdef dcc}
  DragAcceptFiles(Self.Handle, false);
  Application.OnMessage := nil;
{$endif}
  MidiInput.CloseAll;
end;

function TfrmSequenzer.ChangeNote(Event: PGriffEvent; WithSound: boolean): boolean;
begin
  GriffPartitur_.ChangeNote(Event, WithSound);
  frmGriff.Invalidate;
  result := true;
end;

procedure TfrmSequenzer.SelectedChanges(SelectedEvent: PGriffEvent);
var
  Sharp: boolean;
  Sound: byte;
  s: string;
begin
  if SelectedEvent = nil then
  begin
    gbGriffEvent.Enabled := false;
    edtSoundPitch.Text := '';
    edtGriffPitch.Text := '';
    cbxNoteType.ItemIndex := -1;
    cbxCross.Checked := false;
    cbxPush.Checked := false;
    edtGriffLine.Text := '';
    edtIndex.Text := '';
    edtLeftPos.Text := '';
    edtWidth.Text := '';
    cbxVolta.ItemIndex := -1;
    cbxVolta.Color := $ffffff;
  end else
  with SelectedEvent^ do
  begin
    Sharp := GriffPartitur_.Instrument.Sharp;
    edtGriffPitch.Enabled := NoteType = ntBass;
    gbGriffEvent.Enabled := true;
    Sound := SoundPitch; // GetSoundPitch(GriffPartitur_.Instrument);
    cbxNoteType.ItemIndex := ord(NoteType);
    if NoteType = ntBass then
    begin
      edtSoundPitch.Text := IntToStr(Sound) + '  $' + IntToHex(Sound) + '  ' + MidiOnlyNote(Sound, Sharp);
      s := IntToStr(GriffPitch);
      if GriffPartitur_.Instrument.BassDiatonic and
         (GriffPitch in [1..8]) then
      begin
        if Cross then
          s := s + '  ' + string(SteiBass[6, GriffPitch])
        else
          s := s + '  ' + string(SteiBass[5, GriffPitch]);
      end;
      edtGriffPitch.Text := s;
    end else begin
      edtSoundPitch.Text := IntToStr(Sound) + '  $' + IntToHex(Sound) + '  ' + MidiOnlyNote(Sound, Sharp);
      edtGriffPitch.Text := IntToStr(GriffPitch) + '  $' + IntToHex(GriffPitch) + '  ' + MidiOnlyNote(GriffPitch, Sharp);
    end;
    cbxCross.Checked := SelectedEvent.Cross;
    cbxPush.Checked := SelectedEvent.InPush;
    edtGriffLine.Text := IntToStr(AbsRect.Top);
    if GriffPartitur_.SelectedEvent = SelectedEvent then
    begin
      edtIndex.Text := IntToStr(GriffPartitur_.Selected);
      edtLeftPos.Text := IntToStr(AbsRect.Left);
      edtWidth.Text := IntToStr(AbsRect.Width);
      cbxVolta.ItemIndex := ord(Repeat_);
      if ord(Repeat_) > 0 then
        cbxVolta.Color := $00ffff
      else
        cbxVolta.Color := $ffffff;
    end;
  end;
end;

begin
//  writeln('TGriffEvent ', sizeof(TGriffEvent));
end.

