unit UMidi;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  Classes, SysUtils,
{$ifdef FPC}
  Urtmidi;
{$else}
  Midi;
{$endif}

type
  TChannels = set of 0..15;

var
  TrueMicrosoftIndex: integer = -1;
  MidiInstrDiskant: byte = $15; // Akkordeon
  MidiBankDiskant: byte = 0;
  MidiInstrBass: byte = $15;
  MidiBankBass: byte = 0;
  pipFirst: byte =  37;   // 59
  pipSecond: byte = 69;       // 76
  pipChannel: byte = 9;

  VolumeDiscant: double = 1.0;
  VolumeBass: double = 1.0;
  VolumeMetronom: double = 0.8;
  VolumeOut: double = 0.8;
  NurTakt: boolean = false;
  OhneBlinker: boolean = true;

  MidiInstr: byte = $1e;

procedure ChangeBank(Index, Channel, Bank, Instr: byte);
procedure VolumeChange(vol: double; channels: TChannels);
procedure ResetMidiOut;
procedure OpenMidiMicrosoft;
procedure SendMidi(Status, Data1, Data2: byte);
procedure DoSoundPitch(Pitch: byte; On_: boolean);

implementation

procedure DoSoundPitch(Pitch: byte; On_: boolean);
begin
  if MicrosoftIndex >= 0 then
  begin
    if On_ then
      MidiOutput.Send(MicrosoftIndex, $90, Pitch, $4f)
    else
      MidiOutput.Send(MicrosoftIndex, $80, Pitch, 64)
  end;
end;

procedure ResetMidiOut;
var
  i: integer;
begin
  if MicrosoftIndex >= 0 then
  begin
    for i := 0 to 15 do
    begin
      Sleep(5);
      MidiOutput.Send(MicrosoftIndex, $B0 + i, 120, 0);  // all sound off
    end;
    Sleep(5);
  end;
end;


procedure ChangeBank(Index, Channel, Bank, Instr: byte);
begin

  MidiOutput.Send(Index, $b0 + Channel, 0, Bank);
  MidiOutput.Send(Index, $c0 + Channel, Instr, 0);
end;

procedure OpenMidiMicrosoft;
begin
  if MicrosoftIndex >= 0 then
  begin
    MidiOutput.Open(MicrosoftIndex);
    try
      ResetMidiOut;
      ChangeBank(MicrosoftIndex, 0, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 1, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 2, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 3, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 4, MidiBankDiskant, MidiInstrDiskant);
      ChangeBank(MicrosoftIndex, 5, MidiBankBass, MidiInstrBass);
      ChangeBank(MicrosoftIndex, 6, MidiBankBass, MidiInstrBass);
      ChangeBank(MicrosoftIndex, 7, MidiBankBass, MidiInstrBass);
    finally
    end;
  end;
end;

procedure SendMidi(Status, Data1, Data2: byte);
begin
  if (MicrosoftIndex >= 0) then
    MidiOutput.Send(MicrosoftIndex, Status, Data1, Data2);
end;

procedure VolumeChange(vol: double; channels: TChannels);
var
  v: byte;
  i: integer;
begin
  if MicrosoftIndex >= 0 then
  begin
    vol := 127*vol*0.75 + 32;
    if vol > 127 then
      vol := 127;
    v := trunc(vol);
    for i := 0 to 15 do
      if i in channels then
      begin
        MidiOutput.Send(MicrosoftIndex, $B0 + i, 7, v);
        MidiOutput.Send(MicrosoftIndex, $B0 + i, 11, 127);
        Sleep(10);
      end;
  end;
end;


end.

