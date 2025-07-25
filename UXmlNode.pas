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
unit UXmlNode;

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

interface

uses
  SysUtils, Classes, Zip,
  UMyMemoryStream;

type

  KXmlAttr = class
    Name: string;
    Value: WideString;
  end;


  KXmlNode = class
    ChildNodes: array of KXmlNode;
    Attrs: array of KXmlAttr;
    Value: WideString;
    Name: string;   // = '': Text

    destructor Destroy; override;


    function AppendChildNode(Name_: string; Value_: WideString = ''): KXmlNode; overload;
    function AppendChildNode(Name_: string; Value_: integer): KXmlNode; overload;
    function AddChild(Name_: string; Value_: WideString = ''): KXmlNode;

    procedure InsertChildNode(Index: integer; Child_: KXmlNode);
    procedure AppendChildNode(Child_: KXmlNode); Overload;
    function ChildNodesCount: integer;

    procedure AppendAttr(Name_: string; Value_: WideString); overload;
    procedure AppendAttr(Name_: string; Value_: integer); overload;
    function SaveToXmlFile(const FileName: string; Header: string = ''): boolean;
    function SaveToStream(const Header: string): TMyMemoryStream;
  {$ifdef dcc}
    function SaveToMsczFile(FileName: string): boolean;
  {$endif}
    procedure BuildStream(Stream: TMyMemoryStream; Level: integer; Wln: boolean);
    procedure RemoveChild(Child: KXmlNode);
    function GetChildIndex(Child: KXmlNode): integer;
    procedure PurgeChild(Index: integer);
    function HasChild(Name_: string): KXmlNode;
    function DeleteAttribute(Attribute: string): boolean;
    function AttributeIdx(Attribute: string): integer;
    function HasAttribute(Attribute: string): boolean;
    function GetAttribute(const Idx: string): WideString;
    procedure SetAttributes(const Idx: string; const Value: WideString);
    function LastNode: KXmlNode;
    function GetXmlValue: AnsiString;
    function GetChild(Name: string; var Child: KXmlNode): boolean;
    function GetChildNode(Idx: integer): KXmlNode;
    function CopyTree: KXmlNode;
    function GetFirstIndex(Nam: string): integer;

    //MuseScore
    procedure MergeStaff(var Staff3: KXmlNode);
    function ExtractVoice(VoiceIndex: integer; StaffId: integer): KXmlNode;

    class function BuildMemoryStream(Root: KXmlNode): TMyMemoryStream;


    property Attributes[const Name: string]: WideString read GetAttribute write SetAttributes;
    property Count: integer read ChildNodesCount;
    property XmlValue: AnsiString read GetXmlValue;
    property Child[Idx: integer]: KXmlNode read GetChildNode; default;
  end;

const
  // Unicode
  // https://de.wikipedia.org/wiki/Unicodeblock_Notenschriftzeichen
  dotRest =         119149;

  doubleWholeRest = 119098;
  wholeRest =       119099;
  halfRest =        119100;
  quarterRest =     119101;

  wholeNoteHead =   119133;
  halfNoteHead =    119127;
  quarterNoteHead = 119128;

  function NewXmlAttr(Name_: string; Value_: WideString = ''): KXmlAttr;
  function NewXmlNode(Name_: string; Value_: WideString = ''): KXmlNode;

implementation


function NewXmlAttr(Name_: string; Value_: WideString = ''): KXmlAttr;
begin
  result := KXmlAttr.Create;
  result.Name := Name_;
  result.Value := Value_;
end;

destructor KXmlNode.Destroy;
var
  i: integer;
begin
  for i := 0 to Length(ChildNodes)-1 do
    ChildNodes[i].Free;
  Value := '';
  Name := '';

  inherited;
end;

function NewXmlNode(Name_: string; Value_: WideString = ''): KXmlNode;
begin
  result := KXmlNode.Create;
  SetLength(result.ChildNodes, 0);
  SetLength(result.Attrs, 0);
  result.Value := Value_;
  result.Name := Name_;
end;

procedure KXmlNode.InsertChildNode(Index: integer; Child_: KXmlNode);
var
  i: integer;
begin
  if (Index >= 0) and (Index <= Count) then
  begin
    SetLength(ChildNodes, Length(ChildNodes)+1);
    for i := Length(ChildNodes)-2 downto Index do
      ChildNodes[i+1] := ChildNodes[i];
    ChildNodes[Index] := Child_;
  end;
end;

procedure KXmlNode.AppendChildNode(Child_: KXmlNode);
begin
  InsertChildNode(Count, Child_);
end;

function KXmlNode.ChildNodesCount: integer;
begin
  result := Length(ChildNodes);
end;

function KXmlNode.AppendChildNode(Name_: string; Value_: WideString = ''): KXmlNode;
begin
  result := NewXmlNode(Name_, Value_);
  SetLength(ChildNodes, Length(ChildNodes) + 1);
  ChildNodes[Length(ChildNodes)-1] :=result;
end;

function KXmlNode.AppendChildNode(Name_: string; Value_: integer): KXmlNode;
begin
  result := AppendChildNode(Name_, IntToStr(Value_));
end;

function KXmlNode.AddChild(Name_: string; Value_: WideString = ''): KXmlNode;
begin
  result := AppendChildNode(Name_, Value_);
end;

procedure KXmlNode.AppendAttr(Name_: string; Value_: WideString);
var
  Attr_: KXmlAttr;
begin
  Attr_ := NewXmlAttr(Name_, Value_);
  SetLength(Attrs, Length(Attrs)+1);
  Attrs[Length(Attrs)-1] := Attr_;
end;

procedure KXmlNode.AppendAttr(Name_: string; Value_: integer);
begin
  AppendAttr(Name_, IntToStr(Value_));
end;

function KXmlNode.GetChildIndex(Child: KXmlNode): integer;
begin
  if Child = nil then
  begin
    result := -1;
    exit;
  end;
  result := Length(ChildNodes)-1;
  while (result >= 0) and (ChildNodes[result] <> Child) do
    dec(result);
end;

procedure KXmlNode.RemoveChild(Child: KXmlNode);
begin
  PurgeChild(GetChildIndex(Child));
end;

procedure KXmlNode.PurgeChild(Index: integer);
var
  i: integer;
begin
  if (0 <= Index) and (Index < Count) then
  begin
    ChildNodes[Index].Free;
    for i := Index+1 to Count-1 do
      ChildNodes[i-1] := ChildNodes[i];
    SetLength(ChildNodes, Count-1);
  end;
end;

function KXmlNode.HasChild(Name_: string): KXmlNode;
var
  i: integer;
begin
  result := nil;
  for i := 0 to Count-1 do
  begin
    if ChildNodes[i].Name = Name_ then
    begin
      result := ChildNodes[i];
      break;
    end;
  end;
end;

function KXmlNode.AttributeIdx(Attribute: string): integer;
begin
  result := Length(Attrs)-1;
  while (result >= 0) and (Attrs[result].Name <> Attribute) do
    dec(result);
end;

function KXmlNode.HasAttribute(Attribute: string): boolean;
begin
  result := AttributeIdx(Attribute) >= 0;
end;

function KXmlNode.GetAttribute(const Idx: string): WideString;
var
  i: integer;
begin
  result := '';
  i := AttributeIdx(Idx);
  if i >= 0 then
    result := Attrs[i].Value;
end;

function KXmlNode.DeleteAttribute(Attribute: string): boolean;
var
  i: integer;
begin
  result := false;
  i := 0;
  while (i < Length(Attrs)) and not result do
    if Attrs[i].Name = Attribute then
    begin
      Attrs[i].Free;
      result := true;
      while i < Length(Attrs)-1 do
      begin
        Attrs[i] := Attrs[i+1];
        inc(i);
      end;
      SetLength(Attrs, Length(Attrs)-1);
    end else
      inc(i);
end;

procedure KXmlNode.SetAttributes(const Idx: string; const Value: WideString);
var
  i: integer;
begin
  i := AttributeIdx(Idx);
  if i >= 0 then
    Attrs[i].Value := Value
  else
    AppendAttr(Idx, Value);
end;

function KXmlNode.LastNode: KXmlNode;
begin
  result := nil;
  if High(ChildNodes) >= 0 then
    result := ChildNodes[High(ChildNodes)];
end;

procedure KXmlNode.BuildStream(Stream: TMyMemoryStream; Level: integer; Wln: boolean);
var
  i: integer;

  function Special: boolean;
  begin
    result := (name <> 'text') and (name <> 'appoggiatura');
  end;

begin
  if Wln then
    for i := 0 to Level-1 do
      Stream.WriteString('  ');

  Stream.WriteString('<');
  if Name = '' then
  begin
    Stream.WriteString('!-- ' + Value + ' -->');
    if Wln then
      Stream.Writeln;
  end else begin
    Stream.WriteString(Name);

    for i := 0 to Length(Attrs)-1 do
    begin
      Stream.WriteString(' ');
      Stream.WriteString(Attrs[i].Name);
      Stream.WriteString('="');
      Stream.WriteString(Attrs[i].Value);
      Stream.WriteString('"');
    end;

    if (Length(ChildNodes) > 0) or (Value <> '') {or
       ((Length(Attrs) = 0) and (Name <> 'startRepeat'))} then
    begin
      Stream.WriteString('>');
      if Wln and (Value = '') and Special then
        Stream.Writeln;

      for i := 0 to Length(ChildNodes)-1 do
      begin
        ChildNodes[i].BuildStream(Stream, Level+1, Wln and Special);
      end;
      if (Value <> '') then
        Stream.WriteString(Value)
      else
      if Wln and Special then
        for i := 0 to Level do
          Stream.WriteString('  ');
      Stream.WriteString('</');
      Stream.WriteString(Name);
    end else
      Stream.WriteString('/');
    Stream.WriteString('>');
    if Wln then
      Stream.Writeln;
  end;
end;

class function KXmlNode.BuildMemoryStream(Root: KXmlNode): TMyMemoryStream;
var
  Stream: TMyMemoryStream;

begin
  result := TMyMemoryStream.Create;
  Stream := result;
  Stream.Size := 10000000;
  while (Root.Name = '') and (Root.Count > 0) do
    Root := Root.ChildNodes[0];

  Root.BuildStream(Stream, 0, true);
  Stream.Size := Stream.Position;
end;

function KXmlNode.SaveToXmlFile(const FileName: string; Header: string): boolean;
var
  Stream: TMyMemoryStream;
begin
  result := false;
  Stream := SaveToStream(Header);
  if Stream <> nil then
  begin
    Stream.SaveToFile(FileName);
    Stream.Free;
    result := true;
  end;
end;

function KXmlNode.SaveToStream(const Header: string): TMyMemoryStream;
var
  i, l: integer;
begin
  result := BuildMemoryStream(self);
  if result = nil then
    exit;

  l := Length(Header);
  if l > 0 then
  begin
    result.Size := result.Size + l;
    for i := result.Size - 1 downto 0 do
      PAnsiChar(result.Memory)[i+l] := PAnsiChar(result.Memory)[i];
    for i := 1 to l do
      PAnsiChar(result.Memory)[i-1] := AnsiChar(Header[i]);
  end;
end;

{$ifdef dcc}
function KXmlNode.SaveToMsczFile(FileName: string): boolean;
var
  container, child: KXmlNode;
  Stream: TMyMemoryStream;
  conStr: TMyMemoryStream;
  Zip: TZipFile;
begin
  result := false;
  Stream := BuildMemoryStream(self);
  if Stream <> nil then
  begin
    SetLength(FileName, Length(FileName)-Length(ExtractFileExt(FileName)));
    container := KXmlNode.Create;
    container.Name := 'container';
    child := container.AppendChildNode('rootfiles');
    child := child.AppendChildNode('rootfile');
    child.AppendAttr('full-path', ExtractFileName(FileName) + '.mscx');
    conStr := container.SaveToStream('<?xml version="1.0" encoding="UTF-8"?>'#13#10);
    Zip := TZipFile.Create;
    Zip.Open(FileName + '.mscz', zmWrite);
    Zip.Add(Stream.MakeBytes, ExtractFileName(FileName) + '.mscx');
    Zip.Add(conStr.MakeBytes, 'META-INF/container.xml');
    Zip.Free;
    Stream.Free;
    conStr.Free;
    result := true;
  end;
end;
{$endif}

function KXmlNode.GetXmlValue: AnsiString;
var
  s: string;

  procedure Change(from, to_: string);
  var
    p: integer;
  begin
    repeat
      p := Pos(from, s);
      if p > 0 then
      begin
        Delete(s, p, Length(from));
        Insert(to_, s, p);
      end;
    until p = 0;
  end;

begin
  s := Value;
  Change('&amp;', '&');
  Change('&lt;', '<');
  Change('&gt;', '>');
  result := UTF8encode(s);
end;

function KXmlNode.GetChild(Name: string; var Child: KXmlNode): boolean;
var
  k: integer;
begin
  k := 0;
  result := false;
  Child := nil;

  while not result and (k < Count) do
  begin
    Child := ChildNodes[k];
    inc(k);
    result := Child.Name = Name;
  end;
end;

function KXmlNode.GetChildNode(Idx: integer): KXmlNode;
begin
  result := nil;
  if (Idx >= 0) and (Idx < Count) then
    result := ChildNodes[Idx];
end;

function KXmlNode.CopyTree: KXmlNode;
var
  i: integer;
begin
  result := KXmlNode.Create;
  result.Name := Name;
  result.Value := Value;
  for i := 0 to Length(Attrs)-1 do
    result.AppendAttr(Attrs[i].Name, Attrs[i].Value);
  for i := 0 to Count-1 do
    result.AppendChildNode(ChildNodes[i].CopyTree)
end;

function KXmlNode.GetFirstIndex(Nam: string): integer;
var
  i: integer;
begin
  result := -1;
  for i := 0 to Count-1 do
    if Child[i].Name = Nam then
    begin
      result := i;
      break;
    end;
end;

///////////////////////////// MuseScore ////////////////////////////////////////

procedure KXmlNode.MergeStaff(var Staff3: KXmlNode);
var
  mea1, mea3, p: integer;
  Child: KXmlNode;
begin
  if (Name <> 'Staff') or (Staff3.Name <> 'Staff') then
    exit;

  mea1 := -1;
  mea3 := -1;
  while (mea1 < Count) and (mea3 < Staff3.Count) do
  begin
    inc(mea1);
    while (mea1 < Count) and (ChildNodes[mea1].Name <> 'Measure') do
      inc(mea1);
    inc(mea3);
    while (mea3 < Staff3.Count) and (Staff3.ChildNodes[mea3].Name <> 'Measure') do
      inc(mea3);
    if (mea1 < Count) and (mea3 < Staff3.Count) then
    begin
      Child := Staff3.ChildNodes[mea3]; // measure
      // startRepeat und endRepeat überspringen
      p := Child.Count-1;
      while (p > 0) and (Child.ChildNodes[p].Name <> 'voice') do
        dec(p);
      ChildNodes[mea1].AppendChildNode(Child.ChildNodes[p]);
      Child.ChildNodes[p] := nil;
    end;
  end;
end;

function KXmlNode.ExtractVoice(VoiceIndex: integer; StaffId: integer): KXmlNode;
var
  i, iMeasure: integer;
  j, iVoice: integer;
  Voice: KXmlNode;
  Mea: KXmlNode;
  Ok: boolean;
begin
  Ok := false;
  result := NewXmlNode('Staff');
  result.AppendAttr('id', IntToStr(StaffId));
  iMeasure := 1;
  for i := 0 to Count-1 do
    if ChildNodes[i].Name = 'Measure' then
    begin
      result.AppendChildNode('', 'Measure ' + IntToStr(iMeasure));
      mea := result.AppendChildNode('Measure');
      inc(iMeasure);
      iVoice := -1;
      for j := 0 to ChildNodes[i].Count-1 do
      begin
        Voice := ChildNodes[i].ChildNodes[j];
        if Voice.Name = 'voice' then
          inc(iVoice);
        if iVoice = VoiceIndex then
        begin
          Mea.AppendChildNode(Voice);
          ChildNodes[i].ChildNodes[j] := nil;
          ChildNodes[i].PurgeChild(j);
          Ok := true;
          break;
        end;
      end;
    end;
  if not Ok then
    FreeAndNil(result);
end;

end.

