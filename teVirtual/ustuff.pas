{*  teVirtualMIDI Delphi interface
 *
 * Copyright 2009-2019, Tobias Erichsen
 * All rights reserved, unauthorized usage & distribution is prohibited.
 *
 *
 * File: uStuff.pas
 *
 * This file contains auxiliary functions for use in DLL-interface
 * and test-program.
 *}
unit uStuff;

interface

uses windows;

function BinToStr(data: pbyte; len: DWORD): string;
function IsGerman: boolean;
{$IFDEF CONSOLE}
Function ReadKey:Char;
{$ENDIF}

implementation

uses sysutils;

{$IFDEF CONSOLE}
Function ReadKey:Char;
Var buffer : TInputRecord;
    count  : Cardinal;
Begin
  Result:=#0;
  Repeat
    ReadConsoleInput(GetStdHandle(STD_INPUT_HANDLE),buffer,1,count);
    If (count=1) And (buffer.EventType=1) And (buffer.Event.KeyEvent.bKeyDown) And (buffer.Event.KeyEvent.AsciiChar<>#0) Then
      begin
         Result:=char(ord(buffer.Event.KeyEvent.AsciiChar));
      end;
  Until Result<>#0;
End;
{$ENDIF}

function BinToStr(data: pbyte; len: DWORD): string;
var i: dword;
begin
  result:='';
  for i := 1 to len do
    begin
      result:=result+inttohex(ord(data^),2);
      inc( data );
      if ( i < len ) then
        result := result+':';
    end;
end;

function IsGerman: boolean;
begin
  result:=(GetUserDefaultLangID() and $3ff)=7;
end;


end.
