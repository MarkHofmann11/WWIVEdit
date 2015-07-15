UNIT WEString;
{$I WEGLOBAL.PAS}
{ -- This is the Low Level Strings unit of WWIVEdit 2.2
  -- Last Updated : 3/22/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is Public Domain
  --
  -- Purpose : Provide Low level string manipulation routines
  --
  -- Know Errors: None
  --
  -- Planned Enhancements : Improvement of Go_Left and Go_Right
  --
  -- }

INTERFACE

FUNCTION  cstr(i:longint):string;   { Converts a number to a string            }
FUNCTION  ZExpand(i:LongInt;        { Converts an integer into a string and    }
                len : byte):string;{ and adds enough zeros at the beginning   }
                                   { to make is LEN characters long           }
FUNCTION  Dup(c:char; n:integer)    { Returns a string of length "n" full of   }
               : string;           { character "c"                            }
FUNCTION  value(I : string) : integer;
FUNCTION  TransformString(s:string):string;
PROCEDURE StripEndString(VAR s:string);
FUNCTION  StripEndS(s:string):string;
FUNCTION  GoLeft(s:string; i:byte):byte;
FUNCTION  GoRight(s:string; i:byte):byte;
FUNCTION  LengthW(s:string):integer;
FUNCTION  LeftS(s:string; n:integer):string; {Returns the Left N characters }
FUNCTION  RightS(s:string; n:integer):string;{Returns the Right N characters }
FUNCTION  CmpLeft(source, Target:string):boolean;
FUNCTION  CmpLeftI(source,target:string):boolean;
FUNCTION  ToLower(s:string):String;
FUNCTION  LJustify(s:string; width:integer):string;
FUNCTION  Fname(s:string):string;
PROCEDURE StripEndC(VAR s:string; ch:char);
FUNCTION HexStr(n:LongInt; Len:Byte):string;
FUNCTION HexVal(s:string):longint;
FUNCTION WCopy(s:string; len:integer):string;

IMPLEMENTATION

FUNCTION Fname(s:string):string;
VAR
  p:byte;
BEGIN
  p:=pos('.',s);
  IF p>0 THEN
    Fname:=copy(s,1,pos('.',s)-1)
  ELSE
    Fname:=s;
END;

FUNCTION LJustify(s:string; width:integer):string;
VAR
  t:string;
  i:integer;
BEGIN
  t:=dup(#32,width);
  FOR i:=1 TO length(s) DO
    t[i]:=s[i];
  LJustify:=t;
END;



FUNCTION CmpLeft(source,target:string):boolean;
BEGIN
  CmpLeft:=LeftS(source,Length(target))=target;
END;

FUNCTION CmpLeftI(source,target:string):boolean;
BEGIN
  CmpLeftI:=CmpLeft(TransformString(source),TransformString(target));
END;

FUNCTION LeftS(s:string; n:integer):string;
BEGIN
  LeftS:=copy(s,1,n);
END;

FUNCTION RightS(s:string; n:integer):string;
BEGIN
  RightS:=copy(s,length(s)-n+1,n);
END;

FUNCTION value(I : string) : integer;
VAR n,n1 : integer;
BEGIN
  val(i,n,n1);
  IF n1 <> 0 THEN BEGIN
    i  :=  copy(i,1,n1-1);
    val(i,n,n1)
  END;
  value  :=  n;
END;


FUNCTION TransformString(s:string):string;
VAR x:integer;
BEGIN
  StripEndString(s);
  FOR x:=1 TO Length(s) DO
    s[x]:=upcase(s[x]);
  TransformString:=s;
END;

FUNCTION ToLower(s:string):String;
VAR x:integer;
BEGIN
  FOR x:=1 TO Length(s) DO
    IF s[x] IN ['A'..'Z'] THEN
      s[x]:=chr(ord(s[x])+32);
  ToLower:=s;
END;

PROCEDURE StripEndString(VAR s:string);
{ Strips off the end of a string }
BEGIN
  WHILE (length(s)>0) AND (s[length(s)]=' ') DO
    delete(s,length(s),1);
END;

FUNCTION StripEndS(s:string):string;
{ Strips off the end of a string }
BEGIN
  WHILE (length(s)>0) AND (s[length(s)]=' ') DO
    delete(s,length(s),1);
  StripEndS:=s;
END;

FUNCTION cstr(i : longint) : string;
VAR c : string;
BEGIN
  str(i,c);
  cstr  :=  c;
END;


FUNCTION ZExpand(i:LongInt; len:byte):string;
VAR
  negative:boolean;
  result:string;
  x:byte;

BEGIN
  Negative:=i<0;
  IF negative then i:=-i;
  result:=cstr(i);
  FOR x:=length(result) TO len-1 DO
    result:='0'+result;
  IF negative THEN result[1]:='-';
  ZExpand:=Result
END;

FUNCTION Dup(c:char; n:integer):string;
VAR
  s:string;
BEGIN
  IF n IN [1..255] THEN
  BEGIN
    FillChar(s[1],n,c);
    s[0]:=chr(n);
    Dup:=s;
  END ELSE dup:='';
END;

FUNCTION GoLeft(s:string; i:byte):byte;
{ A simple word left function... needs improvement }
BEGIN
  IF i>length(s) THEN i:=length(s);
  IF i>2 THEN
  REPEAT
    dec(i);
  UNTIL (i=1) OR (s[i-1] = ' ')
  ELSE i:=1;
  GoLeft:=i;
END;



FUNCTION GoRight(s:string; i:byte):byte;
{ A very simple Word Right function... Could be improved }
BEGIN
  IF i<=length(s) THEN
  REPEAT
    inc(i)
  UNTIL (i=length(s)) OR (s[i] =' ');
  GoRight:=i+1
END;

FUNCTION LengthW(s:string):integer;
VAR l,i:integer;
BEGIN
  l:=0;
  FOR i:=1 TO Length(s) DO
  BEGIN
    l:=l+1;
    IF s[i]=^C THEN l:=l-2
    ELSE IF s[i]=^H THEN l:=l-2
  END;
  Lengthw:=l;
END;

FUNCTION WCopy(s:string; len:integer):string;
VAR
  i:byte;
  cc:char;
BEGIN
  i:=1;
  cc:='0';
  WHILE ((len>1) AND (i<=length(s))) DO
  BEGIN
    IF s[i] IN [^C,^H] THEN inc(len,2);
    IF s[i]=^C THEN cc:=s[i+1];
    dec(len);
    inc(i);
  END;
  s:=copy(s,1,i);
  IF cc<>'0' THEN s:=s+^C'0';
  WCopy:=s
END;

PROCEDURE StripEndC(VAR s:string; ch:char);
VAR
  i:integer;
BEGIN
  i:=length(s);
  WHILE (i>1) AND (s[i]<>ch) DO
    dec(i);
  Delete(s,i,length(s)-i+1);
END;

FUNCTION HexStr(n:LongInt; Len:Byte):string;
CONST
  HexDigit : ARRAY[0..15] OF CHAR =
   ('0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F');
VAR
  s:string;
  zero:string;
  done:boolean;
BEGIN
  s:='';
  Done:=false;
  WHILE NOT Done DO
  BEGIN
    s:=Hexdigit[n mod 16]+s;
    n:=(n-(n mod 16)) div 16;
    done:=n=0;
  END;
  IF len=0 THEN zero:='' ELSE BEGIN
    fillchar(zero[1],len-Length(S),'0');
    zero[0]:=chr(len-Length(s));
  END;
  HexStr:=Zero+s;
END;

FUNCTION HexVal(s:string):LongInt;
VAR
  result:LongInt;
  dig : byte;
  x:byte;

BEGIN
  result:=0;
  FOR x:=1 TO length(s) DO
  BEGIN
    IF (s[x]>='0') AND (s[x]<='9') THEN
      dig := ord(s[x])-ord('0')
    ELSE IF (upcase(s[x])>='A') AND (upcase(s[x])<='F') THEN
      dig := ord(upcase(s[x])) - ord('A') + 10
    ELSE BEGIN
      writeln('Hex Error!');
      halt;
    END;
    result:=result * 16 + dig;
  END;
  HexVal:=Result;
END;

END.
