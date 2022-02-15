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
unit UGriffPlayer;

interface

uses
  SysUtils, Types, Classes,
  UGriffPartitur;

type

  TGriffPlayer = class(TThread)
  public
    Event: TPlayRecord;

    GriffPartitur: TGriffPartitur;

    procedure Execute; override;
    procedure StopPlay;

    function Terminated_: boolean;
  end;


implementation

procedure TGriffPlayer.Execute;
begin
  try
    GriffPartitur.Play(Event);
  finally
    Terminate;
  end;
end;

procedure TGriffPlayer.StopPlay;
begin
  GriffPartitur.StopPlay := true;
end;

function TGriffPlayer.Terminated_: boolean;
begin
  result := Terminated;
end;


end.
