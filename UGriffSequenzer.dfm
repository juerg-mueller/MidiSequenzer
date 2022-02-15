object frmSequenzer: TfrmSequenzer
  Left = 0
  Top = 0
  HorzScrollBar.Smooth = True
  HorzScrollBar.Tracking = True
  Caption = 'Sequenzer'
  ClientHeight = 366
  ClientWidth = 716
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object lbResult: TLabel
    Left = 64
    Top = 328
    Width = 3
    Height = 13
  end
  object GroupBox1: TGroupBox
    Left = 24
    Top = 120
    Width = 657
    Height = 153
    Caption = 'GroupBox1'
    TabOrder = 0
    object cbTransInstrument: TComboBox
      Left = 36
      Top = 73
      Width = 145
      Height = 21
      ItemIndex = 0
      TabOrder = 0
      Text = 'B-'#214'rgeli'
      Items.Strings = (
        'B-'#214'rgeli'
        'A-'#214'rgeli')
    end
    object edtMidiFile: TEdit
      Left = 212
      Top = 73
      Width = 320
      Height = 21
      TabOrder = 1
    end
    object btnOpen: TButton
      Left = 538
      Top = 69
      Width = 84
      Height = 25
      Caption = 'Choose mid-File'
      TabOrder = 2
      OnClick = btnOpenClick
    end
    object btnLoadPartitur: TButton
      Left = 538
      Top = 38
      Width = 84
      Height = 25
      Caption = 'Load Partitur'
      TabOrder = 3
      OnClick = btnLoadPartiturClick
    end
  end
  object FileOpenDialog1: TFileOpenDialog
    FavoriteLinks = <>
    FileTypes = <
      item
        DisplayName = 'Midi Files'
        FileMask = '*.mid; *.txt'
      end
      item
        DisplayName = 'All Files'
        FileMask = '*.*'
      end>
    OkButtonLabel = 'Open'
    Options = []
    Left = 294
    Top = 56
  end
end
