# Griffschrift-MIDI-Sequenzer
Griffschrift-Midi-Sequenzer (Steirische Harmonika &amp; Schwyzerörgeli)

read Sequenzer-Doku.txt

examples in "Noten"

Für die Verwendung von virtuellen MIDI-Schnittstellen kann die Software von Tobias Erichsen eingebunden werden:
https://www.tobias-erichsen.de/wp-content/uploads/2020/01/teVirtualMIDISDKSetup_1_3_0_43.zip

teVirtualMIDI funktioniert auf einem MAC M1 mit Parallels nicht!

Stand 1. Juni 2025
------------------

Branch 2.0 gesetzt.

Leider funktioniert Delphi in einer virtuellen Maschine von VMWare nicht mehr zufriedenstellend: Es blockiert die VM durch zu hohe Aktivitäten.
Deshalb habe ich mich entschlossen, meine Projekte mit Lazarus weiter zu entwickeln.

Nachteile:

- Die Belegung der PC-Tastatur kann ich nicht mehr beinflussen. "y" und "z" sind für US-Tastaturen vertaucht.

- Auch andere Funktionen sind noch eingeschränkt.

- teVirtualMIDI funktioniert nicht mehr.


Vorteile

- Mit Lazarus ist ein Cross-Compiling möglich, d.h. ich kann Window '.exe'-Files auf meinem Linux System generieren.

- Ebenso kann der Sequenzer auch für Linux und für den MAC generiert werden. Dazu ist für die MIDI-Schnittstelle jeweils
eine Dynamische Library notwendig (https://github.com/thestk/rtmidi).

Erweiterung Juli 2025
---------------------

Beim Speichern des Stücks konnte man bisher Notenblätter für MuseScore 3.6 und eingeschränkt
für LillyPond und MusicXML generieren.

Neu kann man auch Grifftabellen erstellen. Für jedes Blatt wird eine Bitmap-Datei (.bmp) abgespeichert. 16-tel Noten gehen
dabei verloren.
