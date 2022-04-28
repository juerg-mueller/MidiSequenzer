object frmGriffRecorder: TfrmGriffRecorder
  Left = 0
  Top = 0
  Caption = 'Virtuelle Steirische Harmonica'
  ClientHeight = 273
  ClientWidth = 458
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object gbMidiSound: TGroupBox
    Left = 0
    Top = 0
    Width = 458
    Height = 145
    Align = alTop
    Caption = 'Midi / Sound'
    TabOrder = 0
    object lblKeyboard: TLabel
      Left = 25
      Top = 34
      Width = 64
      Height = 13
      Caption = 'Sustain Pedal'
    end
    object Label17: TLabel
      Left = 25
      Top = 67
      Width = 56
      Height = 13
      Caption = 'Synthesizer'
    end
    object lbVirtual: TLabel
      Left = 25
      Top = 101
      Width = 65
      Height = 13
      Caption = 'Virtual Device'
    end
    object cbxMidiOut: TComboBox
      Left = 114
      Top = 64
      Width = 156
      Height = 21
      Style = csDropDownList
      TabOrder = 0
      OnChange = cbxMidiOutChange
    end
    object cbxMidiInput: TComboBox
      Left = 114
      Top = 31
      Width = 156
      Height = 21
      Style = csDropDownList
      TabOrder = 1
      OnChange = cbxMidiInputChange
    end
    object btnResetMidi: TButton
      Left = 278
      Top = 62
      Width = 100
      Height = 25
      Caption = 'Reset Synth.'
      TabOrder = 2
      OnClick = btnResetMidiClick
    end
    object cbxVirtual: TComboBox
      Left = 114
      Top = 98
      Width = 156
      Height = 21
      Style = csDropDownList
      TabOrder = 3
      OnChange = cbxVirtualChange
    end
  end
  object gbInstrument: TGroupBox
    Left = 0
    Top = 145
    Width = 458
    Height = 72
    Align = alTop
    Caption = 'Schwyzer'#246'rgeli / Steirische Harmonika'
    TabOrder = 1
    ExplicitTop = 260
    ExplicitWidth = 498
    object Label13: TLabel
      Left = 286
      Top = 33
      Width = 92
      Height = 13
      Caption = 'Transpose (Primes)'
      Visible = False
    end
    object Label1: TLabel
      Left = 25
      Top = 33
      Width = 53
      Height = 13
      Caption = 'Instrument'
    end
    object cbxTransInstrument: TComboBox
      Left = 399
      Top = 30
      Width = 46
      Height = 21
      Style = csDropDownList
      ItemIndex = 11
      TabOrder = 0
      Text = '0'
      Visible = False
      OnChange = cbxTransInstrumentChange
      Items.Strings = (
        '-11'
        '-10'
        '-9'
        '-8'
        '-7'
        '-6'
        '-5'
        '-4'
        '-3'
        '-2'
        '-1'
        '0'
        '1'
        '2'
        '3'
        '4'
        '5'
        '6'
        '7'
        '8'
        '9'
        '10'
        '11')
    end
    object cbTransInstrument: TComboBox
      Left = 114
      Top = 30
      Width = 156
      Height = 21
      Style = csDropDownList
      ItemIndex = 0
      TabOrder = 1
      Text = 'B-'#214'rgeli'
      OnChange = cbTransInstrumentChange
      Items.Strings = (
        'B-'#214'rgeli'
        'A-'#214'rgeli')
    end
  end
  object GroupBox1: TGroupBox
    Left = 0
    Top = 216
    Width = 458
    Height = 57
    Caption = 'Push Indicator'
    TabOrder = 2
    object Label2: TLabel
      Left = 25
      Top = 26
      Width = 57
      Height = 13
      Caption = 'Shift Button'
    end
    object cbxShiftIsPush: TCheckBox
      Left = 114
      Top = 25
      Width = 33
      Height = 17
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = cbxShiftIsPushClick
    end
  end
end
