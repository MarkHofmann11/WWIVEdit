UNIT WEESM;
{$I WEGLOBAL.PAS}
{ -- External string management functions for WWIVEdit 2.4
  -- }

INTERFACE

FUNCTION GetS(n:integer):String;
FUNCTION PadS(n,pad:integer):string;

{ These numbers are relative to XSTR }
PROCEDURE XWriteln(n:integer);
PROCEDURE XWritelns(l1,l2:integer);
PROCEDURE XWrite(n:integer);

IMPLEMENTATION

USES WEString,WEVars,WEInit;

CONST
  StringFile = 'WWIVEDIT.STR';
  IndexFile  = 'WWIVEDIT.IDX';
  Initialized: Boolean = False;
  WaitStr = 'Indexing... Please Wait...';

TYPE
  IndexRec = RECORD
    Pos : word;
    Length : Byte;
  END;

VAR
  Index : FILE OF IndexRec;
  Strings: FILE;

FUNCTION GetS(n:integer):String;
VAR
  ch : char;
  ind : IndexRec;
  FoundEOL : Boolean;
  s:string;
  t:text;
  pos:word;
BEGIN
  IF NOT Initialized THEN
  BEGIN
    assign(Index,StartupDir+IndexFile);
    assign(Strings,StartupDir+StringFile);
    IF Newer(StartupDir+IndexFile,StartupDir+StringFile) THEN
    BEGIN
      {$I-}
      pos:=0;
      assign(t,StartupDir+StringFile);
      reset(t);
      IF IOResult<>0 THEN BEGIN
        writeln('Could not find ',StartupDir+StringFile);
        writeln('Program aborted.');
        halt;
      END;
      rewrite(Index);
      IF IOResult<>0 THEN BEGIN
        writeln('Could not write to ',StartupDir+IndexFile);
        writeln('Program aborted.');
        halt;
      END;
      {$I+}
      write(WaitStr);
      WHILE NOT EOF(t) DO
      BEGIN
        Ind.Pos := Pos;
        readln(t,s);
        Pos:=pos+length(s)+2;
        Ind.Length:=length(s);
        write(Index,Ind);
      END;
      close(Index);
      close(t);
      write(dup(#8,length(waitstr)),dup(#32,length(waitstr)),dup(#8,length(waitstr)));
    END;
    reset(Index);
    reset(strings,1);
    Initialized:=True;
  END;
  seek(Index,n);
  read(Index,ind);
  s[0]:=chr(Ind.length);
  seek(strings,ind.pos);
  blockread(strings,s[1],ind.length);
  GetS := s;
END;

FUNCTION Pads(n,pad:integer):string;
VAR
  s: string;
BEGIN
  s:=GetS(n);
  s:=s+dup(' ',pad-length(s));
  PadS:=s;
END;

PROCEDURE XWriteln(n:integer);
BEGIN
  writeln(GetS(XSTR+n));
END;

PROCEDURE XWrite(n:integer);
BEGIN
  write(GetS(XSTR+n),' ');
END;

PROCEDURE XWritelns(l1,l2:integer);
VAR x:integer;
BEGIN
  FOR x:=l1 TO l2 DO
    XWriteln(x);
END;

END.
