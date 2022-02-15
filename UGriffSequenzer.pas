unit UGriffSequenzer;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, UGriffImage, Vcl.StdCtrls, UMap, 
  UMidiPartitur, UInstrument, UfrmGriff;

type


  TfrmSequenzer = class(TForm)
    FileOpenDialog1: TFileOpenDialog;
    GroupBox1: TGroupBox;
    cbTransInstrument: TComboBox;
    edtMidiFile: TEdit;
    btnOpen: TButton;
    btnLoadPartitur: TButton;
    lbResult: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnOpenClick(Sender: TObject);
    procedure btnLoadPartiturClick(Sender: TObject);
  private  
  public
    GriffImage: TGriffImage;
    Partitur: TMidiPartitur;
  end;

  


var
  frmSequenzer: TfrmSequenzer;

implementation

{$R *.dfm}

uses
  UGriffPartitur, UMyMidiStream;

{$define _UseBitmap}

procedure TfrmSequenzer.btnLoadPartiturClick(Sender: TObject);
var
  Partitur: TMidiPartitur;
  PartiturFileName: string;
  Ok: boolean;
begin
  lbResult.Caption := '';

  PartiturFileName := FileOpenDialog1.FileName;
  if not FileExists(PartiturFileName) then
    raise Exception.Create('File does not exist!');
    
  if ExtractFileExt(PartiturFileName) = '.txt' then
    Ok := Partitur.LoadSimpleFromFile(PartiturFileName) 
  else
  begin
    Ok := Partitur.LoadMidiFromFile(PartiturFileName);
  end;
  if not Ok then
    raise Exception.Create('File not read!');

  Partitur.SetInstrumentInMidi(InstrumentsList[cbTransInstrument.ItemIndex]^);

  lbResult.Caption := 'Loaded';

  frmGriff.GriffPartitur.LoadFromMidiPartitur(Partitur);
end;

procedure TfrmSequenzer.btnOpenClick(Sender: TObject);
begin
  FileOpenDialog1.FileName := edtMidiFile.Text;
  if FileOpenDialog1.Execute then
  begin
    edtMidiFile.Text := FileOpenDialog1.FileName;
    if not FileExists(FileOpenDialog1.FileName) then
      raise Exception.Create('File does not exist.');
  end;
end;

procedure TfrmSequenzer.FormCreate(Sender: TObject);
var
  i: integer;
begin
  GriffImage := TGriffImage.Create;

  cbTransInstrument.Items.Clear;
  for i := 0 to High(InstrumentsList) do
    cbTransInstrument.Items.Add(InstrumentsList[i].Name);
  cbTransInstrument.ItemIndex := 0;  
end;

procedure TfrmSequenzer.FormDestroy(Sender: TObject);
begin              
  GriffImage.Free;
end;

procedure TfrmSequenzer.FormShow(Sender: TObject);
begin
{
  imgGriff.Width := GriffImage.Width;
  imgGriff.Height := GriffImage.Height;
  GriffImage.SetDIBitsToDevice(imgGriff.Canvas.Handle, 0, 0, GriffImage.Width, GriffImage.Height, 0, 0);
}
  HorzScrollBar.Size := ClientWidth;
  HorzScrollBar.Range := GriffImage.Width;
end;


end.
