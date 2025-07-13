program MidiSequenzer;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
{$ifdef unix}
  cthreads,
  pthreads,
{$endif}
{$if defined(fpc) or defined(darwin)}
  Interfaces,
{$endif}
  Forms,
  UMidiSequenzer in 'UMidiSequenzer.pas' {frmSequenzer},
  UInstrument in 'UInstrument.pas',
  UMyMidiStream in 'UMyMidiStream.pas',
  UfrmGriff in 'UfrmGriff.pas' {frmGriff},
  UGriffPartitur in 'UGriffPartitur.pas',
  umidi,
{$ifdef mswindows}
  Midi in 'Midi.pas',
  teVirtualMIDIdll in 'teVirtual\teVirtualMIDIdll.pas',
  UVirtual in 'UVirtual.pas',
{$else}
  urtmidi,
{$endif}
  UMidiDataStream in 'UMidiDataStream.pas',
  UAmpel in 'UAmpel.pas' {frmAmpel},
  UMyMemoryStream in 'UMyMemoryStream.pas',
  UEventArray in 'UEventArray.pas',
  UGriffEvent in 'UGriffEvent.pas',
  UGriffPlayer in 'UGriffPlayer.pas',
  UGriffArray in 'UGriffArray.pas',
  UXmlNode in 'UXmlNode.pas',
  UXmlParser in 'UXmlParser.pas',
  USheetMusic in 'USheetMusic.pas',
  UMuseScore in 'UMuseScore.pas',
  UFormHelper in 'UFormHelper.pas',
  UMidiEvent in 'UMidiEvent.pas';


{$if defined(DEBUG) and defined(dcc)}
//  {$APPTYPE CONSOLE}
{$endif}

{$R *.res}

var
  w, h: integer;
  l, m: integer;

begin
  Application.Initialize;
{$ifdef dcc}
  Application.MainFormOnTaskbar := True;
{$endif}
  Application.CreateForm(TfrmSequenzer, frmSequenzer);
  Application.CreateForm(TfrmGriff, frmGriff);
  Application.CreateForm(TfrmAmpel, frmAmpel);
  h := screen.Height;
  w := screen.Width;
  l := frmGriff.Width +  frmAmpel.Width + 10;
  if w > l then
  begin
    m := 0;
 //   if (w - l) div 2 > 200 then
 //     m := 200;
    frmAmpel.Left := (w - l) div 2 - m;
    frmGriff.Left := (w + l) div 2 - frmGriff.Width - m;
    frmSequenzer.Left := (w + l) div 2 - (frmSequenzer.Width +  frmGriff.Width) div 2 - m;
  end;
  l := frmGriff.Height + frmSequenzer.Height + 10;
  if h > l then
  begin
    l := (h - l) div 2 - 50;
    if l < 0 then
      l := 0;
    frmAmpel.Top := l + 100;
    frmGriff.Top := l;
    frmSequenzer.Top := frmGriff.Top + frmGriff.Height + 10;
  end;
  Application.Run;
end.
