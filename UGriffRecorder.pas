unit UGriffRecorder;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  UInstrument;

type
  TfrmGriffRecorder = class(TForm)
    gbMidiSound: TGroupBox;
    lblKeyboard: TLabel;
    Label17: TLabel;
    lbVirtual: TLabel;
    cbxMidiOut: TComboBox;
    cbxMidiInput: TComboBox;
    btnResetMidi: TButton;
    cbxVirtual: TComboBox;
    gbInstrument: TGroupBox;
    Label13: TLabel;
    cbxTransInstrument: TComboBox;
    cbTransInstrument: TComboBox;
    Label1: TLabel;
    GroupBox1: TGroupBox;
    cbxShiftIsPush: TCheckBox;
    Label2: TLabel;
    procedure cbTransInstrumentChange(Sender: TObject);
    procedure cbxMidiInputChange(Sender: TObject);
    procedure cbxTransInstrumentChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure cbxMidiOutChange(Sender: TObject);
    procedure btnResetMidiClick(Sender: TObject);
    procedure cbxVirtualChange(Sender: TObject);
    procedure cbxShiftIsPushClick(Sender: TObject);
  private
    procedure MessageEvent(var Msg: TMsg; var Handled: Boolean);
  public
    Instrument: TInstrument;
    procedure OnMidiInData(aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer);
  end;

var
  frmGriffRecorder: TfrmGriffRecorder;

implementation

{$R *.dfm}

uses
  UAmpel, Midi, UVirtual, UMidiDataStream, UFormHelper, UGriffEvent;


procedure TfrmGriffRecorder.OnMidiInData(aDeviceIndex: integer; aStatus, aData1, aData2: byte; Timestamp: integer);
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
    if GriffEvent.SoundToGriff(Instrument) and
       (GriffEvent.InPush = Event.Push_) then
    begin
      Event.Row_ := GriffEvent.GetRow;
      Event.Index_ := GriffEvent.GetIndex;
      if (Event.Row_ > 0) and (Event.Index_ >= 0) then
      begin
        frmAmpel.AmpelEvents.NewEvent(Event);
        if (GetKeyState(vk_scroll) = 1) then //   numlock pause scroll
      // !!!    frmAmpel.GenerateNewNote(Event);
      end;
    end;
  end;
end;
procedure TfrmGriffRecorder.MessageEvent(var Msg: TMsg; var Handled: Boolean);
begin
  if ((Msg.message = WM_KEYDOWN) or (Msg.message = WM_KEYUP)) then
  begin
    //writeln(Msg.wParam, '  ', IntToHex(Msg.lParam));
    if frmAmpel.IsActive then
    begin
      if (Msg.lParam and $fff0000) = $0150000 then    // Z
        Msg.wParam := 90;
      if (Msg.lParam and $fff0000) = $02c0000 then    // Y
        Msg.wParam := 89;
      // 4. Reihe ' ^
      if (Msg.lParam and $fff0000) = $00c0000 then
        Msg.wParam := 219;
      if (Msg.lParam and $fff0000) = $00d0000 then
        Msg.wParam := 221;
      // 3. Reihe ü ¨
      if RunningWine then
      begin
        if (Msg.lParam and $fff0000) = $0600000 then
          Msg.wParam := 186;
      end else
      if (Msg.lParam and $fff0000) = $01a0000 then
        Msg.wParam := 186;
      if (Msg.lParam and $fff0000) = $01b0000 then
        Msg.wParam := 192;
      // 2. Reihe ö ä $
      if (Msg.lParam and $fff0000) = $0270000 then
        Msg.wParam := 222;
      if (Msg.lParam and $fff0000) = $0280000 then
        Msg.wParam := 220;
      if (Msg.lParam and $fff0000) = $02b0000 then
        Msg.wParam := 223;
      // 1. Reihe , . -
      if (Msg.lParam and $fff0000) = $0330000 then
        Msg.wParam := 188;
      if (Msg.lParam and $fff0000) = $0340000 then
        Msg.wParam := 190;
      if (Msg.lParam and $fff0000) = $0350000 then
        Msg.wParam := 189;
      if (Msg.lParam and $fff0000) = $0560000 then
        Msg.wParam := 226;
    end;
  end;
end;

procedure TfrmGriffRecorder.btnResetMidiClick(Sender: TObject);
begin
  ResetMidi;
end;

procedure TfrmGriffRecorder.cbTransInstrumentChange(Sender: TObject);
var
  s: string;
  index: integer;
begin
  if cbTransInstrument.ItemIndex < 0 then
    cbTransInstrument.ItemIndex := 0;
  s := cbTransInstrument.Items[cbTransInstrument.ItemIndex];
  cbTransInstrument.Text := s;

  index := InstrumentIndex(AnsiString(s));
  if index < 0 then
     index := 0;
  Instrument := InstrumentsList[index]^;
  cbxTransInstrumentChange(nil);

  frmAmpel.ChangeInstrument(@Instrument);
  if Instrument.Accordion then
    MidiInstr := $15  // Akkordeon
  else
    MidiInstr := $16; // Harmonika
  if Sender <> nil then
    Midi.OpenMidiMicrosoft;
end;

procedure TfrmGriffRecorder.cbxMidiInputChange(Sender: TObject);
begin
  Sustain_:= false;
  MidiInput.CloseAll;
  if cbxMidiInput.ItemIndex > 0 then
    MidiInput.Open(cbxMidiInput.ItemIndex - 1);
end;

procedure TfrmGriffRecorder.cbxMidiOutChange(Sender: TObject);
begin
  if cbxMidiOut.ItemIndex >= 0 then
  begin
    MidiOutput.Close(MicrosoftIndex);
    if iVirtualMidi <> cbxMidiOut.ItemIndex then
      MicrosoftIndex := cbxMidiOut.ItemIndex
    else
      cbxMidiOut.ItemIndex := MicrosoftIndex;

    OpenMidiMicrosoft;
  end;
end;

procedure TfrmGriffRecorder.cbxTransInstrumentChange(Sender: TObject);
var
  delta: integer;
begin
  if cbxTransInstrument.ItemIndex >= 0 then
  begin
    delta := cbxTransInstrument.ItemIndex - 11;
    delta := delta - Instrument.TransposedPrimes;
    Instrument.Transpose(delta);
  end;
end;

procedure TfrmGriffRecorder.cbxVirtualChange(Sender: TObject);
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

procedure TfrmGriffRecorder.cbxShiftIsPushClick(Sender: TObject);
begin
  shiftIsPush := cbxShiftIsPush.Checked;
end;

procedure TfrmGriffRecorder.FormCreate(Sender: TObject);
var
  i: integer;
begin
{$ifdef WIN64}
  Caption := Caption + ' (64)';
{$else}
  Caption := Caption + ' (32)';
{$endif}
  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList) do
    cbTransInstrument.Items.Add(string(InstrumentsList[i].Name));
{$if defined(CONSOLE)}
  if not RunningWine then
    ShowWindow(GetConsoleWindow, SW_SHOWMINIMIZED);
  SetConsoleTitle('MidiSequenzer - Trace Window');
{$endif}
  Application.OnMessage := MessageEvent;

  UVirtual.LoopbackName := 'MidiSequenzer loopback';
  InstallLoopback;
  Sleep(10);
  Application.ProcessMessages;
  MidiOutput.GenerateList;
  MidiInput.GenerateList;
end;

procedure TfrmGriffRecorder.FormShow(Sender: TObject);
var
  i: integer;
begin
//frmAmpel.Width := 100;
  frmAmpel.ChangeInstrument(@Instrument);
  frmAmpel.Show;
  cbTransInstrument.ItemIndex := 2; //2;// 8;
  cbTransInstrumentChange(nil);
  cbxMidiOut.Items.Assign(MidiOutput.DeviceNames);
  Midi.OpenMidiMicrosoft;
  cbxMidiOut.ItemIndex := MicrosoftIndex;
  MidiInput.OnMidiData := OnMidiInData;
  cbxMidiInput.Visible := MidiInput.DeviceNames.Count > 0;
  lblKeyboard.Visible := cbxMidiInput.Visible;
  if cbxMidiInput.Visible then
  begin
    cbxMidiInput.Items.Assign(MidiInput.DeviceNames);
    cbxMidiInput.Items.Insert(0, '');
    cbxMidiInput.ItemIndex := 0;
    for i := 0 to cbxMidiInput.Items.Count-1 do
      if cbxMidiInput.Items[i] = 'Mobile Keys 49'  then
        cbxMidiInput.ItemIndex := i;

    cbxMidiInputChange(nil);
  end;
  cbxVirtual.Items.Clear;
  cbxVirtual.Items.Add('');
  for i := 0 to MidiOutput.DeviceNames.Count-1 do
    cbxVirtual.Items.Append(MidiOutput.DeviceNames[i]);
  cbxVirtual.ItemIndex := 0;

end;

end.
