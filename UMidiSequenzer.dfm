object frmSequenzer: TfrmSequenzer
  Left = 0
  Top = 0
  HorzScrollBar.Smooth = True
  HorzScrollBar.Tracking = True
  ActiveControl = btnOpen
  Caption = 'MIDI Griffschrift-Sequenzer'
  ClientHeight = 510
  ClientWidth = 898
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  KeyPreview = True
  Position = poDesigned
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShortCut = FormShortCut
  OnShow = FormShow
  TextHeight = 13
  object gbLoadSave: TGroupBox
    Left = 0
    Top = 400
    Width = 898
    Height = 110
    Align = alBottom
    Caption = 'Load/Save Midi Partitur'
    TabOrder = 0
    DesignSize = (
      898
      110)
    object Label12: TLabel
      Left = 574
      Top = 33
      Width = 92
      Height = 13
      Anchors = [akTop, akRight]
      Caption = 'Transpose (Primes)'
      ExplicitLeft = 590
    end
    object btnOpen: TButton
      Left = 759
      Top = 60
      Width = 99
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Choose mid-File'
      TabOrder = 0
      OnClick = btnOpenClick
    end
    object btnLoadPartitur: TButton
      Left = 759
      Top = 28
      Width = 99
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Load Partitur'
      TabOrder = 1
      OnClick = btnLoadPartiturClick
    end
    object btnSaveMidi: TButton
      Left = 24
      Top = 60
      Width = 100
      Height = 25
      Caption = 'Save Midi-Partitur'
      TabOrder = 2
      OnClick = btnSaveMidiClick
      OnEnter = edtStopEnter
    end
    object cbxLoadAsGriff: TCheckBox
      Left = 336
      Top = 34
      Width = 148
      Height = 17
      Alignment = taLeftJustify
      Anchors = [akTop, akRight]
      Caption = 'Load as Griff Partitur'
      TabOrder = 3
    end
    object cbxTranspose: TComboBox
      Left = 688
      Top = 30
      Width = 61
      Height = 21
      Style = csDropDownList
      Anchors = [akTop, akRight]
      ItemIndex = 11
      TabOrder = 4
      Text = '0'
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
        '11'
        '12'
        '13'
        '14'
        '15')
    end
    object edtMidiFile: TComboBox
      Left = 336
      Top = 62
      Width = 413
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 5
    end
    object btnRealSound: TButton
      Left = 150
      Top = 59
      Width = 100
      Height = 25
      Caption = 'Save Griff-Partitur'
      TabOrder = 6
      Visible = False
      OnClick = btnSaveMidiClick
      OnEnter = edtStopEnter
    end
    object btnSaveTest: TButton
      Left = 150
      Top = 19
      Width = 100
      Height = 25
      Caption = 'Save Test-Partitur'
      TabOrder = 7
      OnClick = btnSaveTestClick
      OnEnter = edtStopEnter
    end
  end
  object gbGriffEvent: TGroupBox
    Left = 0
    Top = 0
    Width = 250
    Height = 400
    Align = alLeft
    Caption = 'Selected Griff Event'
    Enabled = False
    TabOrder = 1
    object Label1: TLabel
      Left = 24
      Top = 50
      Width = 56
      Height = 13
      Caption = 'Sound Pitch'
    end
    object Label2: TLabel
      Left = 24
      Top = 77
      Width = 47
      Height = 13
      Caption = 'Griff Pitch'
    end
    object Label3: TLabel
      Left = 24
      Top = 150
      Width = 43
      Height = 13
      Caption = 'Griff Line'
    end
    object Label4: TLabel
      Left = 24
      Top = 177
      Width = 28
      Height = 13
      Caption = 'Index'
    end
    object Label9: TLabel
      Left = 24
      Top = 231
      Width = 28
      Height = 13
      Caption = 'Width'
    end
    object Label10: TLabel
      Left = 24
      Top = 204
      Width = 59
      Height = 13
      Caption = 'Left Position'
    end
    object Label14: TLabel
      Left = 24
      Top = 258
      Width = 35
      Height = 13
      Caption = 'Repeat'
    end
    object Label15: TLabel
      Left = 24
      Top = 22
      Width = 24
      Height = 13
      Caption = 'Type'
    end
    object edtSoundPitch: TEdit
      Left = 102
      Top = 47
      Width = 121
      Height = 21
      TabOrder = 0
      OnExit = edtSoundPitchExit
      OnKeyPress = edtKeyPress
    end
    object edtGriffPitch: TEdit
      Left = 102
      Top = 74
      Width = 121
      Height = 21
      Enabled = False
      TabOrder = 1
      OnExit = edtGriffPitchExit
      OnKeyPress = edtKeyPress
    end
    object cbxCross: TCheckBox
      Left = 24
      Top = 101
      Width = 91
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Cross'
      TabOrder = 2
      OnExit = cbxCrossClick
      OnMouseUp = cbxCrossMouseUp
    end
    object cbxPush: TCheckBox
      Left = 24
      Top = 124
      Width = 91
      Height = 17
      Alignment = taLeftJustify
      Caption = 'Push'
      TabOrder = 3
      OnExit = cbxPushClick
      OnMouseUp = cbxPushMouseUp
    end
    object edtGriffLine: TEdit
      Left = 102
      Top = 147
      Width = 121
      Height = 21
      Enabled = False
      TabOrder = 4
      OnExit = edtGriffPitchExit
      OnKeyPress = edtKeyPress
    end
    object edtIndex: TEdit
      Left = 102
      Top = 174
      Width = 121
      Height = 21
      Enabled = False
      TabOrder = 5
      OnExit = edtGriffPitchExit
      OnKeyPress = edtKeyPress
    end
    object edtLeftPos: TEdit
      Left = 102
      Top = 201
      Width = 121
      Height = 21
      TabOrder = 6
      OnExit = edtLeftPosExit
      OnKeyPress = edtKeyPress
    end
    object edtWidth: TEdit
      Left = 102
      Top = 228
      Width = 121
      Height = 21
      TabOrder = 7
      OnExit = edtWidthExit
      OnKeyPress = edtKeyPress
    end
    object cbxVolta: TComboBox
      Left = 102
      Top = 255
      Width = 121
      Height = 21
      TabOrder = 8
      Text = 'regular'
      OnExit = cbxVoltaChange
      OnKeyUp = cbxVoltaKeyUp
      Items.Strings = (
        'regular'
        'start repeat'
        'stop repeat'
        'start volta 1'
        'stop volta 1'
        'start volta 2'
        'stop volta 2')
    end
    object cbxNoteType: TComboBox
      Left = 102
      Top = 20
      Width = 121
      Height = 21
      ItemIndex = 0
      TabOrder = 9
      Text = 'Diskant'
      OnExit = cbxNoteTypeChange
      Items.Strings = (
        'Diskant'
        'Bass'
        'Rest'
        'Repeat')
    end
  end
  object gbOptimize: TGroupBox
    Left = 748
    Top = 0
    Width = 150
    Height = 400
    Align = alRight
    Caption = 'Optimization'
    TabOrder = 2
    DesignSize = (
      150
      400)
    object btnBassSynch: TButton
      Left = 27
      Top = 275
      Width = 99
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'Bass Synch.'
      TabOrder = 0
      OnClick = btnBassSynchClick
      OnEnter = edtStopEnter
    end
    object btnSmallest: TButton
      Left = 27
      Top = 337
      Width = 99
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'Optimize'
      TabOrder = 1
      OnClick = btnSmallestClick
      OnEnter = edtStopEnter
    end
    object btnLongerPitches: TButton
      Left = 27
      Top = 306
      Width = 99
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'Longer Pitches'
      TabOrder = 2
      OnClick = btnLongerPitchesClick
      OnEnter = edtStopEnter
    end
    object btnPurgeBass: TButton
      Left = 27
      Top = 27
      Width = 100
      Height = 25
      Caption = 'Remove Bass'
      TabOrder = 3
      OnClick = btnPurgeBassClick
      OnEnter = edtStopEnter
    end
    object Button1: TButton
      Left = 27
      Top = 119
      Width = 100
      Height = 25
      Caption = 'Check Push/Pull'
      TabOrder = 4
      Visible = False
      OnClick = Button1Click
      OnEnter = edtStopEnter
    end
    object btnRemoveSmall: TButton
      Left = 27
      Top = 368
      Width = 99
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'Remove Small'
      TabOrder = 5
      OnClick = btnRemoveSmallClick
      OnEnter = edtStopEnter
    end
    object Button2: TButton
      Left = 27
      Top = 244
      Width = 99
      Height = 25
      Anchors = [akLeft, akBottom]
      Caption = 'B'#228'sse gleichlang'
      TabOrder = 6
      OnClick = Button2Click
      OnEnter = edtStopEnter
    end
  end
  object Panel1: TPanel
    Left = 250
    Top = 0
    Width = 498
    Height = 400
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 3
    object gbHeader: TGroupBox
      Left = 0
      Top = 0
      Width = 498
      Height = 141
      Align = alTop
      Caption = 'Partitur Header'
      TabOrder = 0
      object Label5: TLabel
        Left = 24
        Top = 32
        Width = 41
        Height = 13
        Caption = 'Measure'
      end
      object Label6: TLabel
        Left = 24
        Top = 85
        Width = 109
        Height = 13
        Caption = 'Ticks per Quarter Note'
      end
      object Label7: TLabel
        Left = 24
        Top = 57
        Width = 65
        Height = 13
        Caption = 'Smallest Note'
      end
      object Label8: TLabel
        Left = 24
        Top = 112
        Width = 81
        Height = 13
        Caption = 'Beats per Minute'
      end
      object cbxViertel: TComboBox
        Left = 219
        Top = 29
        Width = 70
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 1
        Text = 'Quarter'
        OnChange = cbxViertelChange
        OnEnter = edtStopEnter
        Items.Strings = (
          'Quarter'
          '8-th')
      end
      object cbxTakt: TComboBox
        Left = 143
        Top = 29
        Width = 70
        Height = 21
        Style = csDropDownList
        ItemIndex = 2
        TabOrder = 0
        Text = '4'
        OnChange = cbxTaktChange
        OnEnter = edtStopEnter
        Items.Strings = (
          '2'
          '3'
          '4'
          '5'
          '6'
          '7'
          '8'
          '9'
          '10'
          '11'
          '12')
      end
      object edtDeltaTimeTicks: TEdit
        Left = 143
        Top = 82
        Width = 70
        Height = 21
        Alignment = taRightJustify
        TabOrder = 3
        Text = '192'
        OnEnter = edtStopEnter
        OnExit = edtDeltaTimeTicksExit
        OnKeyPress = edtKeyPress
      end
      object cbxSmallestNote: TComboBox
        Left = 143
        Top = 56
        Width = 70
        Height = 21
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 2
        Text = '8th'
        OnChange = cbxSmallestNoteChange
        OnEnter = edtStopEnter
        Items.Strings = (
          '8th'
          '16th'
          '32th')
      end
      object cbxTrimNote: TCheckBox
        Left = 24
        Top = 140
        Width = 132
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Trim Note'
        TabOrder = 5
        Visible = False
        OnClick = cbxTrimNoteClick
      end
      object edtBPM: TEdit
        Left = 143
        Top = 109
        Width = 70
        Height = 21
        Alignment = taRightJustify
        TabOrder = 4
        Text = '120'
        OnEnter = edtStopEnter
        OnExit = edtBPMExit
        OnKeyPress = edtKeyPress
      end
    end
    object gbMidiSound: TGroupBox
      Left = 0
      Top = 141
      Width = 498
      Height = 187
      Align = alClient
      Caption = 'Midi / Sound'
      TabOrder = 1
      DesignSize = (
        498
        187)
      object Label11: TLabel
        Left = 219
        Top = 61
        Width = 74
        Height = 13
        Caption = 'Play Delay (ms)'
      end
      object lblKeyboard: TLabel
        Left = 134
        Top = 34
        Width = 78
        Height = 13
        Caption = 'Keyboard/'#214'rgeli'
      end
      object Label17: TLabel
        Left = 134
        Top = 88
        Width = 56
        Height = 13
        Caption = 'Synthesizer'
      end
      object lbVirtual: TLabel
        Left = 134
        Top = 122
        Width = 65
        Height = 13
        Caption = 'Virtual Device'
        Visible = False
      end
      object lbBegleitung: TLabel
        Left = 24
        Top = 153
        Width = 69
        Height = 13
        Caption = 'Volume output'
      end
      object cbxMidiOut: TComboBox
        Left = 219
        Top = 85
        Width = 156
        Height = 21
        Style = csDropDownList
        TabOrder = 0
        OnChange = cbxMidiOutChange
      end
      object edtPlayDelay: TEdit
        Left = 308
        Top = 58
        Width = 67
        Height = 21
        Alignment = taRightJustify
        TabOrder = 1
        Text = '0'
        OnEnter = edtStopEnter
        OnExit = edtPlayDelayExit
        OnKeyPress = edtKeyPress
      end
      object cbxMuteBass: TCheckBox
        Left = 24
        Top = 87
        Width = 90
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Mute Bass'
        TabOrder = 4
        OnClick = cbxMuteBassClick
      end
      object cbxNoSound: TCheckBox
        Left = 24
        Top = 33
        Width = 90
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Mute'
        TabOrder = 2
        OnClick = cbxNoSoundClick
      end
      object btnPlay: TButton
        Left = 383
        Top = 56
        Width = 100
        Height = 25
        Caption = 'Play Partitur'
        TabOrder = 5
        OnClick = btnPlayClick
      end
      object cbxMidiInput: TComboBox
        Left = 219
        Top = 31
        Width = 156
        Height = 21
        Style = csDropDownList
        TabOrder = 6
        OnChange = cbxMidiInputChange
      end
      object cbxMuteTreble: TCheckBox
        Left = 24
        Top = 60
        Width = 90
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Mute Descant'
        TabOrder = 3
        OnClick = cbxMuteTrebleClick
      end
      object btnResetMidi: TButton
        Left = 383
        Top = 83
        Width = 100
        Height = 25
        Caption = 'Clear Synth.'
        TabOrder = 7
        OnClick = btnResetMidiClick
      end
      object cbxVirtual: TComboBox
        Left = 219
        Top = 119
        Width = 156
        Height = 21
        Style = csDropDownList
        TabOrder = 8
        Visible = False
        OnChange = cbxVirtualChange
      end
      object sbVolumeOut: TScrollBar
        Left = 136
        Top = 151
        Width = 226
        Height = 17
        Anchors = [akLeft, akTop, akRight]
        Max = 120
        Min = 20
        PageSize = 0
        Position = 100
        TabOrder = 9
        OnChange = sbVolumeOutChange
      end
      object cbxTurboSound: TCheckBox
        Left = 24
        Top = 118
        Width = 90
        Height = 17
        Alignment = taLeftJustify
        Caption = 'Turbo Sound'
        TabOrder = 10
        Visible = False
      end
    end
    object gbInstrument: TGroupBox
      Left = 0
      Top = 328
      Width = 498
      Height = 72
      Align = alBottom
      Caption = 'Schwyzer'#246'rgeli / Steirische Harmonika'
      TabOrder = 2
      object Label13: TLabel
        Left = 24
        Top = 34
        Width = 92
        Height = 13
        Caption = 'Transpose (Primes)'
      end
      object cbxTransInstrument: TComboBox
        Left = 127
        Top = 31
        Width = 46
        Height = 21
        Style = csDropDownList
        ItemIndex = 11
        TabOrder = 0
        Text = '0'
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
        Left = 219
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
  end
  object FileOpenDialog1: TOpenDialog
    Filter = 
      'Midi Files|*.mid;*.midi|All Files|*.*|Griff Filles|*.griff|MuseS' +
      'core Files|*.mscx;*.mscz'
    Left = 576
    Top = 22
  end
  object SaveDialog1: TSaveDialog
    Filter = 
      'Midi File|*.mid|MuseScore|*.mscz; *.mscx|LilyPond|*.ly|Standard ' +
      'MusicXML|*.xml;*.musicxml|new Midi File|*.mid|Sequenzer Noten|*.' +
      'zip'
    Left = 624
    Top = 83
  end
end
