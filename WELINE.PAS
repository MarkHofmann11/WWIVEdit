UNIT WELine;
{$I WEGLOBAL.PAS}
{ -- This is the Line Handling unit for WWIVEdit 2.3
  -- Last Modified : 8/11/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is limited public domain (see WWIVEDIT.PAS for details)
  --
  -- Known errors: None
  --
  -- Planned Enhancements: None
  --
  --}

INTERFACE

USES WEVars;

PROCEDURE MakeString(VAR s:LineType; ch,col:char);
FUNCTION  Len(LineNum : integer):byte;
FUNCTION  Character(lineNum,Column:integer):char;
PROCEDURE LDelete(LineNum,index,length:integer);
PROCEDURE LDeleteL(VAR s:Linetype; index,length:integer);
FUNCTION  Color(VAR s:linetype; p:integer):char;
PROCEDURE LInsert(VAR s:LineType; LineNum, index:integer);
PROCEDURE LinsertL(VAR s:LineType; VAR s1:LineType; index:integer);
PROCEDURE StripEnd(LineNum:integer);
PROCEDURE StripEndL(VAR s:LineType);
PROCEDURE WordWrap(VAR s1:linetype; VAR s2:linetype; minx:integer);
PROCEDURE InsertLine(before:integer; VAR s:linetype);
PROCEDURE DeleteLine(n:integer);
FUNCTION  FirstDiff(VAR s1,s2:LineType):integer;
FUNCTION  NumDiff(VAR s1,s2:LineType):integer;
PROCEDURE Reformat(n:integer; movecursor:boolean);
PROCEDURE InitLine(VAR s:LineType);


FUNCTION StringToLine(s:string; VAR l:LineType):string;
PROCEDURE LineToString(VAR l:LineType; VAR s:string);

IMPLEMENTATION

USES WEString,WEKbd;

PROCEDURE InitLine(VAR s:LineType);
{ Initializes a line to an empty string and sets the color attributes to 0 }
VAR x:integer;
BEGIN
  s.l:='';
  s.c:='';
  s.HardCR:=TRUE;
END;


PROCEDURE MakeString(VAR s:LineType; ch,col:char);
{ Makes a "Line" of one charcter with the given color attribute }
BEGIN
  s.l[0]:=#1;
  s.c[0]:=#1;
  s.l[1]:=ch;
  s.c[1]:=col;
END;


FUNCTION Len(LineNum : integer):byte;
{ Returns the length of the given LineNum }
BEGIN
  Len:=length(Line^[lineNum]^.l)
END;


FUNCTION Character(lineNum,Column:integer):char;
{ Returns the Character at the given Column on the Given Line }
BEGIN
  IF len(LineNum)>0 THEN Character:=Line^[LineNum]^.l[column] ELSE Character:=#0
END;


PROCEDURE LDeleteL(VAR s:LineType; index,length:integer);
{ Deletes from s, starting at index, length # of characters }
VAR
  x: integer;
BEGIN
  delete(s.l,index,length);
  delete(s.c,index,length);
END;

PROCEDURE LDelete(LineNum,index,length:integer);
{ Deletes from the given LineNum starting at index, length # of characters }
VAR
  x: integer;
BEGIN
  delete(Line^[LineNum]^.l,index,length);
  delete(Line^[LineNum]^.c,index,length);
END;

FUNCTION Color(VAR s:linetype; p:integer):char;
{ Returns the color attribute of the p'th character on the "line" S }
BEGIN
  Color := s.c[p]
END;



PROCEDURE LInsertL(VAR s:LineType; VAR s1:LineType; index:integer);
{ inserts the given string onto the given LineNum at the given index }
VAR
  x:integer;
  t:LineType;
  clr : char;
BEGIN
{ Pad the line with blanks if needed }
  IF NOT InsertMode
    THEN x:=index+length(s.l)-1
    ELSE x:=index-1;
  WHILE (x>length(s1.l)) DO
  BEGIN
    IF length(s1.l)<1
      THEN clr:=CurrentColor
      ELSE clr:=Color(s1,Length(s1.l));
    MakeString(t,' ',clr);
    insert(t.c,s1.c,length(s1.c)+1);
    insert(t.l,s1.l,length(s1.c)+1);
  END;

  IF InsertMode THEN
  BEGIN
    insert(s.l,s1.l,index);
    insert(s.c,s1.c,index);
  END
  ELSE
    FOR x:=index TO index+length(s.l)-1 DO
    BEGIN
      s1.l[x]:=s.l[x-index+1];
      s1.c[x]:=s.c[x-index+1];
    END;
END;

PROCEDURE LInsert(VAR s:LineType; LineNum, index:integer);
{ inserts the given string onto the given LineNum at the given index }
VAR
  x:integer;
  t:LineType;
  clr : char;
BEGIN
{ Pad the line with blanks if needed }
  IF NOT InsertMode
    THEN x:=index+length(s.l)-1
    ELSE x:=index-1;
  WHILE (x>len(LineNum)) DO
  BEGIN
    IF len(LineNum)<1
      THEN clr:=CurrentColor
      ELSE clr:=Color(Line^[LineNum]^,Len(LineNum));
    MakeString(t,' ',clr);
    insert(t.c,Line^[LineNum]^.c,length(Line^[LineNum]^.c)+1);
    insert(t.l,Line^[LineNum]^.l,length(Line^[LineNum]^.c)+1);
  END;

  IF InsertMode THEN
  BEGIN
    insert(s.l,Line^[LineNum]^.l,index);
    insert(s.c,Line^[LineNum]^.c,index);
  END
  ELSE
    FOR x:=index TO index+length(s.l)-1 DO
    BEGIN
      Line^[LineNum]^.l[x]:=s.l[x-index+1];
      Line^[LineNum]^.c[x]:=s.c[x-index+1];
    END;
END;


PROCEDURE StripEndL(VAR s:LineType);
{ Strips off the end of the given LineNum }
BEGIN
  WHILE (length(s.l)>0) AND (s.l[length(s.l)]=' ') DO
    LDeleteL(s,length(s.l),1);
END;

PROCEDURE StripEnd(LineNum:integer);
{ Strips off the end of the given LineNum }
BEGIN
  WHILE Character(LineNum,len(LineNum))=' ' DO
    LDelete(LineNum,len(LineNum),1);
END;

PROCEDURE WordWrap(VAR s1:linetype; VAR s2:linetype; minx:integer);
{ strips off the last word(s) in s1 and stores it in S2 }
VAR i,x:integer;
BEGIN
  IF minx>=Length(s1.l) THEN minx:=0;
  x:=length(s1.l);                         { point X to the end of the orignal line }
  IF x>LineLen THEN x:=LineLen;            { Make sure that all extra is taken off }
  WHILE (x>minx) AND (NOT (s1.l[x]=' ')) DO   { Go until it finds a space or there's nothing left }
    dec(x);
  IF x=0 THEN x:=LineLen;
  s2.l := copy(s1.l,x+1,length(s1.l)-x);   { copy the string part of it }
  s2.c := copy(s1.c,x+1,length(s1.c)-x);   { copy the color part of it  }
  delete(s1.l,length(s1.l)-length(s2.l)+1,length(s2.l));
  delete(s1.c,length(s1.c)-length(s2.c)+1,length(s2.c));
END;



PROCEDURE InsertLine(before:integer; VAR s:linetype);
{ inserts the line s on the line before the line pointed to by before }
VAR
  x,t:integer;
  p: pointer;
BEGIN
  IF Before>MaxLines THEN BEGIN
    Before:=MaxLines;
    IF cy>MaxLines THEN cy:=MaxLines;
    exit;
  END;
  IF HighLine=MaxLines THEN exit;
  IF before<=BlockStart THEN inc(blockStart);
  IF before<=BlockEnd THEN inc(blockEnd);
  IF Before<=HighLine THEN
  BEGIN
    t:=HighLine+1;
    IF t>MaxLines THEN t:=MaxLines;
    p:=Line^[HighLine+1];
    FOR x:=t DOWNTO before DO
      Line^[x]:=Line^[x-1];
    Line^[Before]:=p;
  END;
  Line^[before]^:=s;
  inc(HighLine);
END;

FUNCTION FirstDiff(VAR s1,s2:LineType):integer;
{ Compares the two lines until it finds a difference in either the characters
  or the colors }
VAR
  x:integer;
  EndPoint:integer;
BEGIN
  IF (s1.l='') or (s2.l='') THEN FirstDiff:=1
  ELSE BEGIN
    IF length(s1.l)>length(s2.l) THEN EndPoint:=length(s2.l)
    ELSE EndPoint := length(s1.l);
    x:=1;
    WHILE (x<=EndPoint) AND (s1.l[x]=s2.l[x]) AND (s1.c[x]=s2.c[x]) DO
      inc(x);
    FirstDiff:=x;
  END
END;

FUNCTION NumDiff(VAR s1,s2:LineType):integer;
{ Compares the two lines counting the number of differences }
VAR
  x,n:integer;
  EndPoint:integer;
BEGIN
  IF s1.l='' THEN NumDiff:=Length(s2.l)
  ELSE IF s2.l='' THEN NumDiff:=Length(s1.l)
  ELSE BEGIN
    IF length(s1.l)>length(s2.l) THEN EndPoint:=length(s2.l)
    ELSE EndPoint := length(s1.l);
    n:=abs(length(s1.l)-length(s2.l));
    x:=1;
    WHILE (x<=EndPoint) DO
    BEGIN
      IF NOT ((s1.l[x]=s2.l[x]) AND (s1.c[x]=s2.c[x])) THEN
        inc(n);
      inc(x);
    END;
    NumDiff:=n;
  END
END;

PROCEDURE DeleteLine(n:integer);
{ Removes the given line number }
VAR
  x:integer;
  Temp : pointer;
BEGIN
  IF n<BlockStart THEN Dec(BlockStart);
  IF n<BlockEnd THEN Dec(BlockEnd);
  temp:=Line^[n];
  FOR x:=n TO MaxLines-1 DO
    Line^[x]:=Line^[x+1];
  Line^[MaxLines]:=temp;
  InitLine(Line^[MaxLines]^);
  dec(HighLine);
END;



PROCEDURE Reformat(n:integer; MoveCursor:boolean);
{ Reformats the text, starting at the given line. }
{ -- Majorly changed in 2.2 to take into account where the hard Carriage
     returns are. }
VAR
  flag : boolean;
  t : LineType;
  l : integer;

BEGIN
  InitLine(t);            { Initialize a temporary line }
  flag:=MoveCursor;
  IF Len(n)>LineLen THEN  { Split off last word onto new line }
  BEGIN
    flag:=cx>LineLen;
    StripEnd(n);          { Erase any blank characters at the end of the line }
    InsertLine(n+1,t);    { Insert a blank line }
    IF Len(n)>LineLen THEN{ If this line is too long, then wordwrap }
    BEGIN
      WordWrap(Line^[n]^,Line^[n+1]^,cx);
      StripEnd(n);
    END;
    IF flag THEN BEGIN
      inc(cy);
      cx:=len(cy);
    END ELSE Line^[n+1]^.hardCR:=false;
    Line^[n]^.HardCR:=false;
    inc(n);
  END;
  WHILE NOT Line^[n]^.HardCR DO
  BEGIN
    flag:=Line^[n]^.l[len(n)]<>' '; { True if line will need space attached }
    l:=LineLen-Len(n);             { Number of character this line can accept }
    IF flag THEN dec(l);
    IF (l>Len(n+1)) AND (Len(n+1)>0) THEN BEGIN { If the next line is less characters than }
      IF flag THEN                 { can fit, then just add the whole line   }
        LInsert(Line^[n+1]^,n,len(n)+2)
      ELSE
        LInsert(Line^[n+1]^,n,len(n)+1);
      Line^[n]^.HardCR:=Line^[n+1]^.HardCR;
      DeleteLine(n+1);             { Delete that old part that was just added }
    END
    ELSE BEGIN                     { otherwise, add one word at a time }
      WHILE (l>0) AND (Line^[n+1]^.l[l]<>' ') DO
        dec(l);
      t.l:=copy(Line^[n+1]^.l,1,l-1);
      t.c:=copy(Line^[n+1]^.c,1,l-1);
      Ldelete(n+1,1,l);
      IF t.l<>'' THEN
        IF flag THEN
          Linsert(t,n,len(n)+2)
        ELSE
          Linsert(t,n,len(n)+1);
      inc(n);
    END;
  END;
END;


FUNCTION StringToLine(s:string; VAR l:LineType):String;
VAR
  i,ln,j:integer;
  cc:char;
BEGIN
  InitLine(l);
  cc:='0';
  i:=0;
  j:=1;
  IF s[1]=^B THEN BEGIN
    l.l:='/C:';
    l.c:='000';
    delete(s,1,1);
    j:=4;
  END;
  ln:=length(s);
  IF s[ln]=^A THEN BEGIN
    L.HardCR:=FALSE;
    delete(s,ln,1);
    dec(ln);
    IF s[ln]=' ' THEN BEGIN
      delete(s,ln,1);
      dec(ln);
    END;
  END;
  WHILE (i<ln) AND (j<=LineLen) DO
  BEGIN
    Inc(i);
    IF s[i]=^C THEN BEGIN
      cc:=s[i+1];
      inc(i);
    END ELSE BEGIN
      l.l[j]:=s[i];
      l.c[j]:=cc;
      inc(j);
    END;
  END;
  l.l[0]:=chr(j-1);
  l.c[0]:=chr(j-1);
  delete(s,1,i);
  StringToLine:=s;
END;

PROCEDURE LineToString(VAR l:LineType; VAR s:string);
VAR
  i,i1 : integer;
  cc : char;
BEGIN
  cc := '0';
  IF CmpLeftI(l.l,'/C:') THEN
  BEGIN
    s:=^B;
    i1:=4
  END
  ELSE BEGIN
    s:='';
    i1:=1;
  END;
  FOR i:=i1 TO Length(l.l) DO
  BEGIN
    IF cc<>l.c[i] THEN BEGIN
      cc:=l.c[i];
      IF Setting.BBS IN [BBS_None,BBS_WWIV,BBS_Eclipse] THEN
        s:=s+^C+cc
      ELSE IF Setting.BBS IN [BBS_Telegard] THEN
        s:=s+^C+chr(ord(cc)-ord('0'));
    END;
    s:=s+l.l[i];
  END;
END;

END.
