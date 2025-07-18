//
// Copyright (C) 2020 J�rg M�ller, CH-5524
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

unit UInstrument;

interface

{$define _InstrumentsList}
{$define GenerateA_Oergeli}

{$IFDEF FPC}
  {$MODE Delphi}
{$ENDIF}

uses
  SysUtils, Classes,
  Ujson;

type
  TPitchArray = array [0..15] of byte; 
  PPitchArray = ^TPitchArray;
  TBassArray = array [boolean] of TPitchArray;
  TColArray = array[1..4] of TPitchArray;

  TVocalArray =
    record
      Col: TColArray;
      procedure Transpose(delta: integer);
      function IsDouble(Pitch: byte; var Index1, Index2: integer): boolean;
      function SoundCount: integer;
      function IsCross(Pitch: byte): boolean;
      procedure CopyJson(Node: Tjson);
    end;
  PVocalArray = ^TVocalArray;

  TInstrument =
    record
      Name: String[64];
      Sharp: boolean;
      TransposedPrimes: SmallInt;
      BassDiatonic: boolean;
      Accordion: boolean;
      Columns: integer;
      Push: TVocalArray;
      Pull: TVocalArray;
      Bass: TBassArray;
      PullBass: TBassArray;

      function GriffToSound(Pitch: byte; const VocalArr: TVocalArray; Cross: boolean) : integer; overload;
      function SoundToGriff(const Pitch: byte; const VocalArr: TVocalArray; var iCol, Index: integer): integer; overload;
//      function _SoundToGriffBass(Pitch: byte; var InPush, Sixth: boolean): integer;
      function RowIndexToSound(Row, Index: byte; Push_: boolean): byte;
      function GriffToSound(Pitch: byte; Push: boolean; Cross: boolean) : integer; overload;
      function SoundToGriff(const Pitch: byte; Push: boolean; var iCol, Index: integer): integer; overload;
      function IsDouble(Pitch: byte; isPush: boolean; var Index1, Index2: integer): boolean;
      procedure Transpose(delta: integer);
      function GetRowIndex(var Row, Index: integer; var Push: boolean; Pitch: byte): boolean;
      function GetPitch(Row, Index: Integer; Push_: boolean): byte;
      function GetMaxIndex(var Row: byte): integer;
      function GetMinIndex(var Row: byte): integer;
      function bigInstrument: boolean;
      function GetAccordion: string;
      function UseJson(Root: Tjson): boolean;
    end;
  pInstrument = ^TInstrument;

function cDurLine(GriffPitch: byte; Sharp: boolean): byte;
function RowIndexToGriff(Row, Index: byte): byte;
function IndexToGriff(index: byte): byte;
function GetPitchLine(pitch: byte): integer;


{$if defined(GenerateA_Oergeli)}
var
  a_Oergeli : TInstrument;
  g_Oergeli : TInstrument;
  gis_Oergeli : TInstrument;
  h_Oergeli : TInstrument;
  c_Oergeli : TInstrument;
  cis_Oergeli : TInstrument;

  SteirischeFBEsAs: TInstrument;
  SteirischeFisHEA: TInstrument;
  SteirischeGCFB: TInstrument;
  SteirischeGisCisFisH: TInstrument;
  SteirischeADGC: TInstrument;
  SteirischeHEAD: TInstrument;
  SteirischeCFBEs: TInstrument;
{$endif}

type
  TSteiBass = array [5..6,1..8] of String[4];

const
  OergeliBassZusatz : array [1..9, 0..1] of integer =
    (
      (63-71, 66-71),
      (61-66, 70-66),
      (65-61, 68-61),
      (60-68, 63-68),
      (67-63, 70-63),
      (62-70, 65-70),
      (60-65, 69-65),
      (64-60, 67-60),
      (62-67, 71-67)
    );

                                // e ist die tiefste Diskant-Note
  CDur : array [0..6] of byte = (52,53,55,57,59,60,62); // e, f, g, a, h, c, d

  zwei = #178;
  // D und d sind in den beiden Systemen unterschiedlich!

  SteiBass : TSteiBass =
    (('g','G','d','D','e','E','g','G'),
     ('a','A','b','B','c','C','f','F'));

  SteiBass2015 : TSteiBass =
    (('a'+zwei, 'A'+zwei, 'b'+zwei, 'B'+zwei, 'c'+zwei, 'C'+zwei, 'd'+zwei, 'D'+zwei),
     ('a','A','b','B','c','C','d','D'));

  b_Oergeli : TInstrument = (
    Name: ('b-Oergeli');
    Sharp: (false);
    TransposedPrimes: 0;
    Accordion: true;
    Columns: (3);
    Push: (
      // Oben -> Unten [absolute height of the note (MIDI).Tonal Pitch Classes]
      // Schwyzer�rgeli normal, 31 Tasten, A/D/G/C                                            B4
      // doubles: 58 (B3: 3 - 3), 70 (B4: 6 - 6), 82 (B5: 9 - 9),   oben/Kopf                                            unten/Fuss
      Col: (( 0,50,53,58,62,65,70,74,77,82,86, 0, 0, 0, 0, 0),  //   D3   F3   B3   D4   F4   B4   D5   F5   B5   D6
            (64,55,58,63,67,70,75,79,82,87,91, 0, 0, 0, 0, 0),  //   E4   G3   B3  Es4   G4   B4  Es5   G5   B5  Es6   G6
            ( 0,66,71,61,72,68,73,80,84,85,83, 0, 0, 0, 0, 0),  // Ges3   H4 Des4   C5  As4 Des5  As5   C6 Des6   H5
            ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
           );
          );
    Pull: (
      // doubles: 72 (C5: 7 - 6),
      Col: (( 0,53,57,60,63,67,69,72,75,79,81, 0, 0, 0, 0, 0),  //   F3   A3   C4  Es4   G4   A4   C5  Es5   G5   A5
            (64,58,62,65,68,72,74,77,80,84,86, 0, 0, 0, 0, 0),  //   E4   B3   D4   F4  As4   C5   D5   F5  As5   C6   D6
            ( 0,61,71,56,66,73,70,78,82,85,76, 0, 0, 0, 0, 0),  // Des3   H4  As3 Ges4 Des5   B4 Ges5   B5 Des6   E6
            ( 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)
           );
          );
               // g   c   f   b  es  as des ges   h
    Bass: (
           ( 0,43,36,41,46,39,44,37,42,47, 0, 0, 0, 0, 0, 0),
           ( 0,67,60,65,70,63,68,61,66,71, 0, 0, 0, 0, 0, 0)
          );
  );

  SteirischeBEsAsDes : TInstrument = (
    Name: ('Steirische BEsAsDes');
    Sharp: (false);
    BassDiatonic: (true);
    Accordion: false;
    Columns: (4);
    Push: (
      // doubles: 58 (B3: 3 - 2), 70 (B4: 6 - 5), 82 (B5: 9 - 8),
      // 94 (B6: 12 - 11), 65 (F4: 5 - 2), 77 (F5: 8 - 5), 89 (F6: 11 - 8),
      // 63 (Dis4: 3 - 3), 75 (Dis5: 6 - 6), 87 (Dis6: 9 - 9),
      // 68 (Gis4: 4 - 3), 80 (Gis5: 7 - 6), 92 (Gis6: 10 - 9),
      Col: ((46,50,53,58,62,65,70,74,77,82,86,89,94, 0, 0, 0),  //   H2   D3   F3   B3   D4   F4   B4   D5   F5   B5   D6   F6   B6
            (51,55,58,63,67,70,75,79,82,87,91,94, 0, 0, 0, 0),  // Dis3   G3   B3 Dis4   G4   B4 Dis5   G5   B5 Dis6   G6   B6
            ( 0,56,60,63,68,72,75,80,84,87,92,96, 0, 0, 0, 0),  // Gis3   C4 Dis4 Gis4   C5 Dis5 Gis5   C6 Dis6 Gis6   C7
            ( 0,61,65,68,73,77,80,85,89,92,97, 0, 0, 0, 0, 0)   // Cis4   F4 Gis4 Cis5   F5 Gis5 Cis6   F6 Gis6 Cis7
           );
          );
    Pull: (
      // doubles: 84 (C6: 11 - 9), 63 (Dis4: 4 - 2), 67 (G4: 5 - 3),
      // 75 (Dis5: 8 - 6), 79 (G5: 9 - 7), 72 (C5: 7 - 3), 75 (Dis5: 8 - 4),
      // 84 (C6: 11 - 7), 87 (Dis6: 12 - 8), 70 (B4: 5 - 4), 89 (F6: 11 - 10),
      // 68 (Gis4: 4 - 2), 80 (Gis5: 8 - 6), 84 (C6: 9 - 7), 75 (Dis5: 6 - 4),
      Col: ((51,53,57,60,63,67,69,72,75,79,81,84,87, 0, 0, 0),  //   E3   F3   A3   C4 Dis4   G4   A4   C5 Dis5   G5   A5   C6 Dis6
            (56,58,62,65,68,70,74,77,80,84,86,89, 0, 0, 0, 0),  // Gis3   B3   D4   F4 Gis4   B4   D5   F5 Gis5   C6   D6   F6
            ( 0,61,63,67,70,73,75,79,82,85,89,91, 0, 0, 0, 0),  // Cis4 Dis4   G4   B4 Cis5 Dis5   G5   B5 Cis6   F6   G6
            ( 0,66,68,72,75,78,80,84,87,90,94, 0, 0, 0, 0, 0)   // Fis4 Gis4   C5 Dis5 Fis5 Gis5   C6 Dis6 Fis6   B6
           );
          );

    Bass: ((  0,53,41,55,43,48,36,53,41, 0, 0, 0, 0, 0, 0, 0),  // F g G c C f F              5. Reihe
           (  0,58,46,51,39,56,44,49,37, 0, 0, 0, 0, 0, 0, 0)   // b B es Es as As des Des    6. Reihe
           );
    PullBass:
          ((  0,48,36,56,44,49,37,54,42, 0, 0, 0, 0, 0, 0, 0),  // f F b B es Es as As
           (  0,53,41,58,46,51,39,56,44, 0, 0, 0, 0, 0, 0, 0 )  // C as As des Des ges Ges
           );
  );

var
  InstrumentsList_: array of TInstrument;

function InstrumentIndex(const Name: AnsiString): integer;
function SoundToGriff_(Pitch: byte; const Bass: TBassArray; var Sixth: boolean): integer;
function GetPitchIndex(Pitch: byte; const arr: TPitchArray): integer;

implementation

uses
  {$ifndef FPC}
    AnsiStrings,
  {$endif}
  UMyMemoryStream, UMyMidiStream, UFormHelper;


function TInstrument.GetAccordion: string;
begin
//  if Accordion then
    result := 'accordion'
//  else
//    result := 'harmonica';
end;

function TInstrument.bigInstrument: boolean;
begin
  result := Columns = 4;
end;

function TInstrument.GetMaxIndex(var Row: byte): integer;
var
  i: integer;
begin
  row := 0;
  result := 6;
  for i := 1 to 4 do
    while Push.Col[i, result+1] > 0 do
    begin
      inc(result);
      row := i;
    end;
end;

function TInstrument.GetMinIndex(var Row: byte): integer;
var
  i: integer;
begin
  row := 0;
  result := 6;
  for i := 1 to 4 do
    while (result > 0) and (Push.Col[i, result-1] > 0) do
    begin
      dec(result);
      row := i;
    end;
end;

function TInstrument.GetPitch(Row, Index: Integer; Push_: boolean): byte;
begin
  result := 0;
  if (Row > 6) or (Index > High(Push.Col[1])) or (Index < 0) then
    exit;
  if (Row >= 5) and (Index > High(TPitchArray)) then
    exit;

  if not BassDiatonic and (Row >= 5) then
    Push_ := true;

  case Row of
    1..4: if Push_ then
            result := Push.Col[Row, Index]
          else
            result := Pull.Col[Row, Index];

    5, 6: if Push_ then
            result := Bass[Row = 6, Index]
          else
            result := PullBass[Row = 6, Index];
  end;
end;

function InstrumentIndex(const Name: AnsiString): integer;
begin
  result := High(InstrumentsList_);
  while (result >= 0) and (InstrumentsList_[result].Name <> Name) do
    dec(result); 
end;

procedure TransposeBass(var Bass: TPitchArray; delta: integer);
var i: integer;
begin
  for i := Low(TPitchArray) to High(TPitchArray) do
    if Bass[i] > 0 then
      Bass[i] := Bass[i] + delta;
end;

procedure TVocalArray.Transpose(delta: integer);
var i, k: integer;
begin
  for k := low(Col) to High(Col) do
    for i := Low(TPitchArray) to High(TPitchArray) do
      if Col[k][i] > 0 then
        Col[k][i] := Col[k][i] + delta;
end;

procedure TVocalArray.CopyJson(Node: Tjson);
var
  i, max: integer;

  function GetPitch(Note: AnsiString): integer;
  var
    i: integer;
  begin
  {$ifdef FPC}
    Note := LowerCase(Note);
  {$else}
    Note := AnsiStrings.LowerCase(Note);
  {$endif}
    if Note = '' then
    begin
      result := 0;
    end else begin
      case AnsiChar(Note[1]) of
        'c': result := 0;
        'd': result := 2;
        'e': result := 4;
        'f': result := 5;
        'g': result := 7;
        'a': result := 9;
        'b': result := 11;
        else result := 0;
      end;
      if Copy(Note, 2, 2) = 'es' then
        dec(result)
      else
      if Copy(Note, 2, 2) = 'is' then
        inc(result);
      inc(result, 48);
      i := Length(Note);
      while (i > 0) and (AnsiChar(Note[i]) in ['''', ',']) do
      begin
        if Note[i] = '''' then
          inc(result, 12)
        else
          dec(result, 12);
        dec(i);
      end;
    end;
  end;

  procedure FillPitchArray(var Arr: TPitchArray; Values: Tjson);
  var
    i, max: integer;
  begin
    if Values = nil then
      max := -1
    else
      max := Length(Values.List)-1;
    if max > 15 then
      max := 15;
    for i := 0 to max do
      Arr[i] := GetPitch(Values.List[i].Value);
    for i := max + 1 to 15 do
      Arr[i] := 0;
  end;

begin
  max := Length(Node.List);
  if max > 4 then
    max := 4;
  for i := 1 to max do
    FillPitchArray(Col[i], Node.List[i-1]);
//  for i := max+1 to 5 do
//    FillPitchArray(Col[i], nil);
end;

function TVocalArray.SoundCount: integer; 

  procedure CountPitchArray(const PitchArray: TPitchArray);
  var 
    i: integer;
  begin
    for i:= Low(PitchArray) to High(PitchArray) do
      if PitchArray[i] > 0 then
        inc(result);
  end;
  
var
  k: Integer;
begin
  result := 0;

  for k := low(Col) to High(Col) do
    CountPitchArray(col[k]);
end;

function TVocalArray.IsCross(Pitch: byte): boolean; 
begin
  result := GetPitchIndex(Pitch, Col[3]) >= 0;
end;

function TVocalArray.IsDouble(Pitch: byte; var Index1, Index2: integer): boolean;  
begin
  Index1 := High(Col[1]);
  while (Index1 >= 0) and (Col[1][Index1] <> Pitch) do
    dec(Index1);
  Index2 := High(Col[2]);
  while (Index2 >= 0) and (Col[2][Index2] <> Pitch) do
    dec(Index2); 

  result := (Index1 >= 0) and (Index2 >= 0);
end;

function TInstrument.UseJson(Root: Tjson): boolean;
var
  Node: Tjson;
begin
  result := false;
  Node := Root.FindInList('steirDescription');
  if Node <> nil then
    Name := Node.Value;
  Node := Root.FindInList('steirMapping');
  if (Node <> nil) and (Length(Node.List) = 2) then
  begin
    Columns := Length(Node.List[0].List);
    Push.CopyJson(Node.List[1]);
    Pull.CopyJson(Node.List[0]);
    result := true;
  end;
end;

procedure TInstrument.Transpose(delta: integer);
begin
  Push.Transpose(delta);
  Pull.Transpose(delta);
  TransposeBass(Bass[false], delta);
  TransposeBass(Bass[true], delta);
  TransposeBass(PullBass[false], delta);
  TransposeBass(PullBass[true], delta);
  inc(TransposedPrimes, delta);
end;

function GetPitchIndex(pitch: byte; const arr: TPitchArray): integer;
begin
  result := 0;
  while (result >= 0) and (result <= High(arr)) do
  begin 
    if pitch = arr[result] then
      break;
    inc(result);
  end;
  if result > High(arr) then
    result := -1;
end;

function TInstrument.GriffToSound(Pitch: byte; Push: boolean; Cross: boolean): integer;
begin
  if Push then
    result := GriffToSound(Pitch, self.Push, Cross)
  else
    result := GriffToSound(Pitch, self.Pull, Cross);
end;

function TInstrument.GriffToSound(Pitch: byte; const VocalArr: TVocalArray; Cross: boolean) : integer;
var
  Line, index: integer;
begin
  result := -1;
  if Pitch = 0 then
    exit;

  Line := GetPitchLine(Pitch);
  index := Line div 2;
  if (index > High(VocalArr.Col[2])) or (Pitch = 0) then
    exit;
    
  if odd(Line) then
  begin
    if Cross and (Columns = 4) then
      result := VocalArr.Col[4][index]
    else
      result := VocalArr.Col[2][index]
  end else
  if Cross then
    result := VocalArr.Col[3][index]
  else
    result := VocalArr.Col[1][index];
end;

function TInstrument.RowIndexToSound(Row, Index: byte; Push_: boolean): byte;
begin
  result := 0;
  if Row in [5, 6] then
  begin
    if Index in [Low(TPitchArray) .. High(TPitchArray)] then
    begin
      if not Push_ and BassDiatonic then
        result := PullBass[Row = 6, Index]
      else
        result := Bass[Row = 6, Index];
    end;
    exit;
  end;

  if not (Row in [low(TColArray)..high(TColArray)]) or
     not (Index in [low(TPitchArray)..High(TPitchArray)]) then
    exit;

  if Push_ then
    result := Push.Col[Row][index]
  else
    result := Pull.Col[Row][index];
end;

function TInstrument.SoundToGriff(const Pitch: byte; Push: boolean; var iCol, Index: integer): integer;
begin
  iCol := -1;
  Index := -1;
  if Push then
    result := SoundToGriff(Pitch, self.Push, iCol, Index)
  else
    result := SoundToGriff(Pitch, self.Pull, iCol, Index);
end;

function TInstrument.GetRowIndex(var Row, Index: integer; var Push: boolean; Pitch: byte): boolean;
var
  Griff: integer;
  Sixth: boolean;
  P: boolean;
begin
  Griff := SoundToGriff(Pitch, Push, Row, Index);
  if Griff < 0 then
  begin
    P := not Push;
    Griff := SoundToGriff(Pitch, P, Row, Index);
    if Griff > 0 then
      Push := not Push;
  end;
  if Griff < 0 then
  begin
    Sixth := false;
    Index := -1; // _SoundToGriffBass(Pitch, Push, Sixth);
    if Index > 0 then
    begin
      if Sixth then
        Row := 6
      else
        Row := 5;
    end
  end;
  result := Index >= 0;
end;

function IndexToGriff(index: byte): byte;
begin
  result := CDur[index mod 7] + 12*(index div 7);
end;

function RowIndexToGriff(Row, Index: byte): byte;
begin
  result := 0;
  if not (Row in [low(TColArray)..high(TColArray)]) or not (Index in [low(TPitchArray)..High(TPitchArray)]) then
    exit;

  Index := 2*Index;
  if not odd(Row) then
    inc(Index);

  result := IndexToGriff(index);
end;

function GetPitchLine(pitch: byte): integer;
begin
  result := 0;
  if pitch < cDur[0] then
    exit;

  dec(pitch, cDur[0]);  // Index = 0 f�r pitch 50 (d)
  while pitch >= 12 do
  begin
    inc(result, 7);
    dec(pitch, 12);
  end;

  case pitch of
    0: begin end;           // d
    1, 2: inc(result, 1);   // es, e
    3:    inc(result, 2);   // f
    4, 5: inc(result, 3);   // ges, g
    6, 7: inc(result, 4);   // as, a
    8, 9: inc(result, 5);   // b, h
    10:   inc(result, 6);   // c
    11:   inc(result, 7);   // des
    else begin end;
  end;
end;

function TInstrument.SoundToGriff(const Pitch: byte; const VocalArr: TVocalArray; var iCol, Index: integer): integer;
begin
  iCol := 0;
  result := -1;

  index := GetPitchIndex(Pitch, VocalArr.Col[2]);
  if (index >= 0) then
  begin
    result := IndexToGriff(2*index+1);
    iCol := 2;
    exit;
  end;

  index := GetPitchIndex(Pitch, VocalArr.Col[1]);
  if (index >= 0) then
  begin
    result := IndexToGriff(2*index);
    iCol := 1;
    exit;
  end;

  index := GetPitchIndex(Pitch, VocalArr.Col[3]);
  if (index >= 0) then
  begin
    result := IndexToGriff(2*index);
    iCol := 3;
    exit;
  end;

  if Columns = 4 then
  begin
    index := GetPitchIndex(Pitch, VocalArr.Col[4]);
    if (index >= 0) then
    begin
      result := IndexToGriff(2*index+1);
      iCol := 4;
      exit;
    end;
  end;
end;

function SoundToGriff_(Pitch: byte; const Bass: TBassArray; var Sixth: boolean): integer;
begin
  result := GetPitchIndex(Pitch, Bass[Sixth]);
 { if result > 0 then
    exit;

  result := GetPitchIndex(Pitch, Bass[not Sixth]);
  if result > 0 then
    Sixth := not Sixth;}
end;
{
function TInstrument._SoundToGriffBass(Pitch: byte; var InPush, Sixth: boolean): integer;
var
  Index: integer;
  s: boolean;
begin
  Index := 0;
  s := Sixth;
  if BassDiatonic then
  begin
    index := SoundToGriff_(Pitch, PullBass, s);
    if (Index > 0) and not InPush then
    begin
      result := Index;
      Sixth := s;
      exit;
    end;
  end else
    InPush := false;

  result := SoundToGriff_(Pitch, Bass, Sixth);
  if result > 0 then
  begin
    if bassDiatonic then
      InPush := true;
    exit;
  end;

  if BassDiatonic and (Index > 0) then
  begin
    InPush := false;
    result := Index;
    Sixth := s;
  end;
end;
}

function TInstrument.IsDouble(Pitch: byte; isPush: boolean; var Index1, Index2: integer): boolean;
begin
  if isPush then
    result := Push.IsDouble(Pitch, Index1, Index2)
  else
    result := Pull.IsDouble(Pitch, Index1, Index2)  
end;

function absC_DurLine(GriffPitch: byte; Sharp: boolean): byte;
begin
  result := 7*(GriffPitch div 12);
  if Sharp then
  begin
    case GriffPitch mod 12 of
      1:  dec(result);  // cis
      3:  dec(result);  // dis
      6:  dec(result);  // fis
      8:  dec(result);  // gis
      10: dec(result);  // ais
      else begin end;
    end;  
  end else begin
    case GriffPitch mod 12 of
      1, 2: inc(result, 1);  // des, d
      3, 4: inc(result, 2);  // es, e
      5:    inc(result, 3);  // f
      6, 7: inc(result, 4);  // ges, g
      8, 9: inc(result, 5);  // as, a
      10, 11: inc(result, 6);// b, h
      else begin end;
    end;
  end;
 // dec(result, 4*7 + 3); // Pos. von E
end;

function cDurLine(GriffPitch: byte; Sharp: boolean): byte;
begin
  result := absC_DurLine(GriffPitch, Sharp) - absC_DurLine(53, Sharp);
end;
   

{$if defined(InstrumentsList)}

const
  FlatNotes  : array [0..11] of string = ('C', 'Des', 'D', 'Es', 'E', 'F', 'Ges', 'G', 'As', 'A', 'B', 'H');
  SharpNotes : array [0..11] of string = ('C', 'Cis', 'D', 'Dis', 'E', 'F', 'Fis', 'G', 'Gis', 'A', 'B', 'H');

function MidiOnlyNote(Pitch: byte; Sharp: boolean): string;
begin
  if Sharp then
    result := Format('%s%d', [SharpNotes[Pitch mod 12], Pitch div 12])
  else
    result := Format('%s%d', [FlatNotes[Pitch mod 12], Pitch div 12])
end;

procedure PrintInstrument(var stream: TMyMemoryStream; Instrument: TInstrument);
var
  j: integer;

  procedure PrintPitchArr(const Arr: TPitchArray; const gap: string);
  var
    i: integer;
  begin
    for i := 0 to High(Arr) do
    begin                                                      
      stream.WriteString(Format('%2d', [Arr[i]]));
      if i < High(Arr) then
        stream.WriteString(',');
    end;
    stream.WriteString(gap);
    for i := 0 to High(Arr) do
      if Arr[i] >= 12 then
        stream.WriteString(Format('%5s', [MidiOnlyNote(Arr[i], Instrument.Sharp)]));
    stream.writeln;
  end;

  procedure PrintBassArr(Bass: TBassArray);
  var
    i, k: integer;
  begin
    stream.WritelnString('(');
    for k := 1 to 2 do
    begin
      stream.WriteString('          (');
      for i := Low(Bass[true]) to High(Bass[false]) do
      begin
        stream.WriteString(Format('%2d', [Bass[k=1, i]]));
        if i < High(Bass[false]) then
          stream.WriteString(',');
      end;
      stream.WriteString(')');
      if k = 1 then
        stream.WriteString(',');
      stream.Writeln;
    end;
    stream.WritelnString('         );');
  end;

  procedure PrintDouble(const Arr: TVocalArray);
  var
    i, k: integer;
    c1, c2: integer;
    len: integer;
    Double: array [0..20] of byte; 
  begin
    len := 0;
    stream.WriteString('      // doubles:');
    for c1 := 1 to Instrument.Columns-1 do
      for c2 := c1+1 to Instrument.Columns do
        for i := 0 to High(TPitchArray) do
          for k := 0 to High(TPitchArray) do
            with Arr do
              if (Col[c1][i] = Col[c2][k]) and (Col[c1][i] <> 0) then
                stream.WriteString(Format(' %d (%s: %d - %d),',
                  [Col[c1][i], MidiOnlyNote(Col[c1][i], Instrument.Sharp), i, k]));
    stream.Writeln;
  end;
  
  procedure PrintVocal(const Vocal: TVocalArray);
  begin
    PrintDouble(Vocal);
    stream.WriteString(  '      Col: (('); PrintPitchArr(Vocal.Col[1], '),  //');
    stream.WriteString(  '            ('); PrintPitchArr(Vocal.Col[2], '),  //'); 
    stream.WriteString(  '            ('); PrintPitchArr(Vocal.Col[3], '),  //');
    stream.WriteString(  '            ('); PrintPitchArr(Vocal.Col[4], ')   //');
    stream.WritelnString('           );');
    stream.WritelnString('          );');  
  end;

  function Bool(b: boolean): string;
  begin
    if b then
      result := 'true'
    else
      result := 'false';
  end;
  
begin
  stream.Writeln;
  stream.WritelnString(Format('  %s : TInstrument = (', [Instrument.Name]));
  stream.WritelnString(Format('    Name: (''%s'');', [Instrument.Name]));
  stream.WritelnString('    Sharp: (' + Bool(Instrument.Sharp) + ');');
  stream.WritelnString('    BassDiatonic: (' + Bool(Instrument.BassDiatonic) + ');');
  stream.WritelnString('    Accordion: (' + Bool(Instrument.Accordion) + ');');
  stream.WritelnString('    Columns: (' + IntToStr(Instrument.Columns) + ');');
  stream.WritelnString('    Push: ('); PrintVocal(Instrument.Push);
  stream.WritelnString('    Pull: ('); PrintVocal(Instrument.Pull);
  stream.WriteString('    Bass:');    PrintBassArr(Instrument.Bass);
  stream.WriteString('    PullBass:'); PrintBassArr(Instrument.PullBass);
  stream.WritelnString('           );');
//  stream.WritelnString('    BassDiatonic: (' + 'true' + ')');
//  stream.Writeln;
  stream.WritelnString('  );');
end;

procedure GenerateInstrumentsList;
var
  inst: integer;
  stream: TMyMemoryStream;
begin
  stream:= TMyMemoryStream.Create;
  stream.SetSize(10000);

  stream.WritelnString('const');
  for inst := 0 to High(InstrumentsList) do
    PrintInstrument(stream, InstrumentsList[inst]^);

  stream.SetSize(stream.Position);
  stream.SaveToFile('InstrumentsList.pas');
  stream.Free;
end;
  
{$endif}
////////////////////////////////////////////////////////////////////////////////

procedure AddInstr(const Instr: TInstrument);
begin
  if Instr.Name <> '' then
  begin
    SetLength(InstrumentsList_, Length(InstrumentsList_)+1);
    InstrumentsList_[Length(InstrumentsList_)-1] := Instr;
  end;
end;

var
  NewInstrument: TInstrument;

procedure AddInstrument(FileName: string);
var
  Root: Tjson;
  Instrument: TInstrument;
begin
  if TjsonParser.LoadFromJsonFile(FileName, Root) then
  begin
    Instrument := NewInstrument;
    if Instrument.UseJson(Root) then
      AddInstr(Instrument);
  end;
end;

procedure ReadInstruments(Path: string);
var
  SR      : TSearchRec;
  DirList : TStringList;
  i: integer;
begin
  SetLength(InstrumentsList_, 0);
  DirList := TStringList.Create;
  if FindFirst(Path + '*.json', faNormal, SR) = 0 then
  begin
    repeat
      DirList.Add(SR.Name); //Fill the list
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  for i := 0 to DirList.Count-1 do
    AddInstrument(Path + DirList[i]);

  DirList.Free;
end;


initialization

  // Json Files
  if DirectoryExists('../../instruments') then
    ReadInstruments('../../instruments/')
  else
    ReadInstruments('instruments/');

{$if defined(GenerateA_Oergeli)}
  SteirischeFBEsAs := SteirischeBEsAsDes;
  SteirischeFBEsAs.Transpose(-5);
  SteirischeFBEsAs.TransposedPrimes := 0;
  SteirischeFBEsAs.Sharp := false;
  SteirischeFBEsAs.Name := 'Steirische FBEsAs';
  AddInstr(SteirischeFBEsAs);

  SteirischeFisHEA := SteirischeBEsAsDes;
  SteirischeFisHEA.Transpose(-4);
  SteirischeFisHEA.TransposedPrimes := 0;
  SteirischeFisHEA.Sharp := false;
  SteirischeFisHEA.Name := 'Steirische FisHEA';
  AddInstr(SteirischeFisHEA);

  SteirischeGCFB := SteirischeBEsAsDes;
  SteirischeGCFB.Transpose(-3);
  SteirischeGCFB.TransposedPrimes := 0;
  SteirischeGCFB.Sharp := true;
  SteirischeGCFB.Name := 'Steirische GCFB';
  AddInstr(SteirischeGCFB);

  AddInstr(SteirischeBEsAsDes);

  SteirischeADGC := SteirischeBEsAsDes;
  SteirischeADGC.Transpose(-1);
  SteirischeADGC.TransposedPrimes := 0;
  SteirischeADGC.Sharp := true;
  SteirischeADGC.Name := 'Steirische ADGC';
  AddInstr(SteirischeADGC);

  SteirischeGisCisFisH := SteirischeBEsAsDes;
  SteirischeGisCisFisH.Transpose(-2);
  SteirischeGisCisFisH.TransposedPrimes := 0;
  SteirischeGisCisFisH.Sharp := false;
  SteirischeGisCisFisH.Name := 'Steirische GisCisFisH';
  AddInstr(SteirischeGisCisFisH);

  SteirischeHEAD := SteirischeBEsAsDes;
  SteirischeHEAD.Transpose(1);
  SteirischeHEAD.TransposedPrimes := 0;
  SteirischeHEAD.Sharp := false;
  SteirischeHEAD.Name := 'Steirische HEAD';
  AddInstr(SteirischeHEAD);

  SteirischeCFBEs := SteirischeBEsAsDes;
  SteirischeCFBEs.Transpose(2);
  SteirischeCFBEs.TransposedPrimes := 0;
  SteirischeCFBEs.Sharp := false;
  SteirischeCFBEs.Name := 'Steirische CFBEs';
  AddInstr(SteirischeCFBEs);

  gis_Oergeli := b_Oergeli;
  gis_Oergeli.Transpose(-5);
  gis_Oergeli.TransposedPrimes := 0;
  gis_Oergeli.Sharp := true;
  gis_Oergeli.Name := 'f-Oergeli';
  AddInstr(gis_Oergeli);

  gis_Oergeli := b_Oergeli;
  gis_Oergeli.Transpose(-4);
  gis_Oergeli.TransposedPrimes := 0;
  gis_Oergeli.Sharp := true;
  gis_Oergeli.Name := 'fis-Oergeli';
  AddInstr(gis_Oergeli);

  gis_Oergeli := b_Oergeli;
  gis_Oergeli.Transpose(-3);
  gis_Oergeli.TransposedPrimes := 0;
  gis_Oergeli.Sharp := true;
  gis_Oergeli.Name := 'g-Oergeli';
  AddInstr(gis_Oergeli);

  gis_Oergeli := b_Oergeli;
  gis_Oergeli.Transpose(-2);
  gis_Oergeli.TransposedPrimes := 0;
  gis_Oergeli.Sharp := true;
  gis_Oergeli.Name := 'gis-Oergeli';
  AddInstr(gis_Oergeli);

  a_Oergeli := b_Oergeli;
  a_Oergeli.Transpose(-1);
  a_Oergeli.TransposedPrimes := 0;
  a_Oergeli.Sharp := true;
  a_Oergeli.Name := 'a-Oergeli';
  AddInstr(a_Oergeli);

  AddInstr(b_Oergeli);

  h_Oergeli := b_Oergeli;
  h_Oergeli.Transpose(1);
  h_Oergeli.TransposedPrimes := 0;
  h_Oergeli.Sharp := true;
  h_Oergeli.Name := 'h-Oergeli';
  AddInstr(h_Oergeli);

  c_Oergeli := b_Oergeli;
  c_Oergeli.Transpose(2);
  c_Oergeli.TransposedPrimes := 0;
  c_Oergeli.Sharp := true;
  c_Oergeli.Name := 'c-Oergeli';
  AddInstr(c_Oergeli);

  cis_Oergeli := b_Oergeli;
  cis_Oergeli.Transpose(3);
  cis_Oergeli.TransposedPrimes := 0;
  cis_Oergeli.Sharp := true;
  cis_Oergeli.Name := 'cis-Oergeli';
  AddInstr(cis_Oergeli);
{$endif}

{$if defined(InstrumentsList)}
  {$if defined(CONSOLE)}
    writeln('Generate List');
  {$endif}
  GenerateInstrumentsList;
{$endif}

finalization

end.

