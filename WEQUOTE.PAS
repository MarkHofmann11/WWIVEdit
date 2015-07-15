UNIT WEQuote;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

INTERFACE

FUNCTION PerformQuote(OutF:string; MaxLines:Integer):Boolean;

IMPLEMENTATION

USES WEOutput,WEInput,WEKbd,WEVars,WEString;

VAR
  RangeLo, RangeHi:integer;
  Lines:Integer;

PROCEDURE SkipHeader(VAR t:text);
BEGIN
  readln(t);
  readln(t);
END;

FUNCTION CleanLine(s:string):string;
{ Takes all control codes out of a line }
VAR
  i : integer;
BEGIN
  i:=1;
  WHILE i<=length(s) DO
  BEGIN
    IF (s[i]=^C) AND (Setting.QuoterOption AND StripColor>0) THEN delete(s,i,2)
    ELSE IF (s[i]=^H) AND (i>1) THEN delete(s,i-1,2)
    ELSE IF s[i] IN [#0..#31]-[^C] THEN delete(s,i,1)
    ELSE inc(i);
  END;
  CleanLine:=s;
END;

FUNCTION GetNum(default,min,max : integer) : integer;
VAR
  s:string;
  i,e:integer;
BEGIN
  SimpleInput(s,10);
  IF s='' THEN GetNum:=Default
  ELSE BEGIN
    val(s,i,e);
    IF i<Min THEN i:=Min
    ELSE IF i>Max THEN i:=Max;
    GetNum:=i;
  END
END;

FUNCTION LineOK(VAR s:string):boolean;
BEGIN
  IF Length(s)=0 THEN LineOk:=TRUE
  ELSE IF s[1]=^D THEN LineOK:=FALSE
  ELSE IF pos(^[,s)>0 THEN LineOK:=FALSE
  ELSE LineOK:=TRUE;
END;

FUNCTION LineCount(VAR t:text):integer;
VAR
  Lines:integer;
  s:string;
BEGIN
  reset(t);
  SkipHeader(t);
  Lines:=0;
  WHILE NOT Eof(t) DO
  BEGIN
    readln(t,s);
    IF LineOK(s) THEN
      inc(Lines);
  END;
  reset(t);
  LineCount:=Lines;
END;

FUNCTION DigitsOf(x:integer):integer;
VAR
  i : integer;
BEGIN
  i:=0;
  IF x=0 THEN i:=1;
  WHILE x>0 DO
  BEGIN
    inc(i);
    x:=x DIV 10;
  END;
  DigitsOf:=i;
END;

PROCEDURE GetRange(VAR RangeLo,RangeHi:integer; msg:string);
BEGIN
  write(C2,'First line ',msg,': ',C3,'[',C1,RangeLo,C3,'] ',C1);
  RangeLo:=GetNum(RangeLo,1,Lines);
  write(C2,'Last line ',msg,': ',C3,'[',C1,Lines,C3,'] ',C1);
  RangeHi:=GetNum(Lines,RangeLo,Lines);
END;

PROCEDURE ViewRange(VAR t:text; RangeLo,RangeHi:integer);
VAR
  Line : integer;
  digits : integer;
  ch : char;
  s : string;
BEGIN
  digits:=DigitsOf(Lines);
  reset(t);
  SkipHeader(t);
  Line:=1;
  WHILE NOT EOF(t) DO
  BEGIN
    readln(t,s);
    IF LineOK(s) THEN
    BEGIN
      IF (Line>=RangeLo) AND (Line<=RangeHi) THEN
        writeln(Line:digits,':',WCopy(CleanLine(s),78-digits));
      inc(Line);
      IF (Line>RangeHi) THEN Exit
      ELSE IF (KeyPressed) THEN
      BEGIN
        ch:=readkey;
        exit;
      END;
    END;
  END;
END;

PROCEDURE QuoteLines(VAR Infile,Outfile:text; RangeLo,RangeHi:integer; prefix:string);
VAR
  Line : Integer;
  s : string;
BEGIN
  rewrite(OutFile);
  reset(infile);
  SkipHeader(infile);
  Line:=1;
  WHILE NOT EOF(infile) DO
  BEGIN
    readln(infile,s);
    IF LineOK(s) THEN
    BEGIN
      IF (Line>=RangeLo) AND (Line<=RangeHi) THEN
        writeln(OutFile,Prefix,Wcopy(CleanLine(s),79-lengthW(Prefix)));
      inc(Line);
    END;
  END;
  close(outfile);
END;

FUNCTION PerformQuote(OutF:string; MaxLines:integer):Boolean;
VAR
  InFile,OutFile : Text;
BEGIN
  clrscr;
  assign(InFile,QuoteFile);
  assign(OutFile,OutF);
  {$I+} reset(InFile); {$I-}
  IF IOResult<>0 THEN { Nothing to quote }
  BEGIN
    PerformQuote:=False;
    exit;
  END;
  Lines:=LineCount(InFile);
  RangeLo:=1; RangeHi:=Lines;
  writeln(C2+'There are ',C1,Lines,C2,' lines available for quoting.');
  writeln;
  write(C5+'Would you like to see them with line numbers? ');
  IF YN THEN
  BEGIN
    writeln;
    GetRange(RangeLo,RangeHi,'to list');
    ViewRange(Infile,RangeLo,RangeHi);
  END;
  writeln;
  GetRange(RangeLo,RangeHi,'to quote');
  if (RangeHi-Rangelo+1>MaxLines) THEN
  BEGIN
    writeln('You may only quote ',Maxlines,' lines.');
    RangeHi:=RangeLo+MaxLines;
    writeln('Last line adjusted accordingly.');
  END;
  writeln;
  write(C5,'Quote lines ',C1,RangeLo,C3,'-',C1,RangeHi,C5,'? ');
  IF Setting.Prefix='' THEN Setting.Prefix:='0>';
  IF YN THEN
  BEGIN
    QuoteLines(Infile,Outfile,RangeLo,RangeHi,Setting.Prefix);
    PerformQuote:=TRUE;
  END
  ELSE PerformQuote:=FALSE;
  close(infile);
END;

END.
