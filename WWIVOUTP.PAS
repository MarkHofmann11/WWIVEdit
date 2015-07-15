UNIT WWIVOutp;
{$I WEGLOBAL.PAS}
INTERFACE
{ -- Output unit for WWIVEdit 2.3.  This should be generic enough to use with
  -- any WWIV on liner.  It provides an interface to the output portion of the
  -- Fossil and NewCrt units.
}
USES NewCrt;


CONST
  C0 = ^C'0';
  C1 = ^C'1';
  C2 = ^C'2';
  C3 = ^C'3';
  C4 = ^C'4';
  C5 = ^C'5';
  C6 = ^C'6';
  C7 = ^C'7';

  ESC = #27;

  working: boolean=FALSE;

  IDColorMap: string[9]='IDCLRMAP*';
  ColorMap : Array[0..255] OF Byte = (
    007,007,007,007,007,007,007,007,007,007, {  0..  9}
    007,007,007,007,007,007,007,007,007,007, { 10.. 19}
    007,007,007,007,007,007,007,007,007,007, { 20.. 29}
    007,007,007,007,007,007,007,007,007,007, { 30.. 39}
    007,007,007,007,007,007,007,007,007,011, { 40.. 49}
    014,005,031,002,140,009,007,007,007,007, { 50.. 59}
    007,007,007,007,007,007,007,007,007,007, { 60.. 69}
    007,007,007,007,007,007,007,007,007,007, { 70.. 79}
    007,007,007,007,007,007,007,007,007,007, { 80.. 89}
    007,007,007,007,007,007,007,007,007,007, { 90.. 99}
    007,007,007,007,007,007,007,007,007,007, {100..109}
    007,007,007,007,007,007,007,007,007,007, {110..119}
    007,007,007,007,007,007,007,007,007,007, {120..129}
    007,007,007,007,007,007,007,007,007,007, {130..139}
    007,007,007,007,007,007,007,007,007,007, {140..149}
    007,007,007,007,007,007,007,007,007,007, {150..159}
    007,007,007,007,007,007,007,007,007,007, {160..169}
    007,007,007,007,007,007,007,007,007,007, {170..179}
    007,007,007,007,007,007,007,007,007,007, {180..189}
    007,007,007,007,007,007,007,007,007,007, {190..199}
    007,007,007,007,007,007,007,007,007,007, {200..209}
    007,007,007,007,007,007,007,007,007,007, {210..219}
    007,007,007,007,007,007,007,007,007,007, {220..229}
    007,007,007,007,007,007,007,007,007,007, {230..239}
    007,007,007,007,007,007,007,007,007,007, {240..249}
    007,007,007,007,007,007                  {250..255}
  );

PROCEDURE GotoXY(x,y:integer);
PROCEDURE ClrScr;
PROCEDURE ClrEol;
FUNCTION  WhereX : byte;
FUNCTION  WhereY : byte;
PROCEDURE InitOutp(MaxX,MaxY:integer; SetDirectVideo,SetComm,SetFossil,color,IS_WWIV:Boolean; port:byte);
PROCEDURE MoveLeft(n:integer);
PROCEDURE ReverseVideoOn;
PROCEDURE ReverseVideoOff;
PROCEDURE BiosScrollWindowUp(x1,y1,x2,y2:byte);
PROCEDURE BiosScrollWindowDown(x1,y1,x2,y2:byte);

IMPLEMENTATION

USES WECom,WEFossil, DOS;

TYPE
  Translation = (None, Bios, DirectVideo, ANSI);
  DisplayRec = RECORD
{    Txt : POINTER;  { pointer to the text part of the display }
{    Clr : POINTER;  { pointer to the color part of the display }
    x,y : byte;     { Current X and Y coords }
    mx,my: byte;    { Max X and Y coords }
  END;

CONST
  Translate : Translation = DirectVideo;


VAR
  OldOutput : text;
  CenterString : string;
  D : DisplayRec;          { The primary dispay }
  FG, BG : Byte;           { The foreground and background colors }
  CurrentColor : Char;
  IS_WWIV : boolean;

PROCEDURE BiosScrollWindowUp(x1,y1,x2,y2:byte);
BEGIN
  NewCRT.BiosScrollWindowUp(x1,y1,x2,y2);
END;

PROCEDURE BiosScrollWindowDown(x1,y1,x2,y2:byte);
BEGIN
  NewCRT.BiosScrollWindowDown(x1,y1,x2,y2);
END;


FUNCTION Pos:word;
BEGIN
  WITH d do
    Pos:=(y-1)+MX+x-1;
END;

FUNCTION  WhereX : byte;
BEGIN
  flush(output);
  WhereX:=d.x;
END;


FUNCTION  WhereY : byte;
BEGIN
  flush(output);
  WhereY:=d.Y;
END;

PROCEDURE GotoXY(x,y:integer);
BEGIN
  flush(output);
  d.x:=x; d.y:=y;
  IF Translate=DirectVideo THEN
    NewCrt.gotoxy(x,y)
  ELSE write(oldoutput,ESC,'[',y,';',x,'H');
END;

PROCEDURE ClrScr;
BEGIN
  flush(output);
  gotoxy(1,1);
  IF Translate=DirectVideo THEN
    NewCrt.ClrScr
  ELSE write(oldoutput,ESC,'[2J');
END;

PROCEDURE ClrEol;
BEGIN
  flush(output);
  IF Translate=DirectVideo THEN
    NewCrt.ClrEol
  ELSE write(oldoutput,ESC,'[K');
END;

PROCEDURE Color(F,B:integer);
BEGIN
  fg:=f; bg:=b;
  newcrt.textcolor(f);
  newcrt.textbackground(b);
END;


PROCEDURE DoColor(ch:char);
CONST
  AnsiTr : ARRAY[0..7] OF Byte = (0, 4, 2, 6, 1, 5, 3, 7);
VAR
  s:string;
  tmp:string[5];
BEGIN
  CurrentColor:=ch;
  IF Translate=DirectVideo THEN
  BEGIN
    Flush(output);
    TextAttr:=ColorMap[ord(ch)];
    Fg:=TextAttr AND $F;
    BG:=(TextAttr AND $70) div 16;
  END ELSE IF (IS_WWIV) THEN write(oldoutput,^C+ch)
  ELSE
  BEGIN
    TextAttr:=ColorMap[ord(ch)];
    Fg:=TextAttr AND $F;
    BG:=(TextAttr AND $70) div 16;
    s:=#27+'[0m';
    write(OldOutput,s);
    s:=#27+'[';
    IF FG>7 THEN s:=s+'1;';
    str(30+ansitr[fg mod 8],tmp);
    s:=s+tmp+';';
    str(40+ansitr[bg],tmp);
    s:=s+tmp;
    IF TextAttr AND $80 >0 THEN
      s:=s+';5';
    s:=s+'m';
    write(oldoutput,s);
  END;
END;


PROCEDURE ReverseVideoOn;
BEGIN
  flush(output);
  IF Translate=DirectVideo THEN
    Color(bg,fg)
  ELSE
    write(oldoutput,ESC+'[7m');
END;

PROCEDURE ReverseVideoOff;
BEGIN
  flush(output);
  IF Translate=DirectVideo THEN
    Color(bg,fg)
  ELSE BEGIN
    write(oldoutput,ESC+'[0m');
    DoColor(CurrentColor);
  END;
END;

PROCEDURE Center(VAR s:string);
VAR
  i,l : integer;
BEGIN
  l:=0;
  FOR i:=1 TO length(s) DO
  BEGIN
    inc(l);
    IF s[i]=^C THEN dec(l,2);
  END;
  FOR i:=1 TO 40-(l div 2) DO
    write(OldOutput,' ');
  WHILE s<>'' DO
    IF s[1]<>^C THEN
    BEGIN
      write(OldOutput,s[1]);
      delete(s,1,1);
    END
    ELSE BEGIN
      DoColor(s[2]);
      delete(s,1,2);
    END;
END;

{$F+}
FUNCTION DoNothing(VAR f:TextRec):integer;
BEGIN
  DoNothing :=0;
END;

VAR
  inverseon:boolean;

PROCEDURE MoveLeft(n:integer);
BEGIN
  flush(output);
  IF d.x>n THEN d.x:=d.x-n ELSE d.x:=1;
  IF Translate=DirectVideo THEN gotoxy(d.x,d.y)
  ELSE write(oldoutput,ESC,'[',n,'D');
END;

FUNCTION TranslateOutput(VAR f:TextRec):integer;
VAR
  i:integer;
  ch : char;
  p : integer;
  x, y, e : integer;
  s:string;
BEGIN
  IF NOT working AND (f.Bufpos>0) THEN
  WITH f DO
  BEGIN
    working:=true;
    s:='';
    FOR i:=0 TO BufPos-1 DO
    BEGIN
      ch :=BufPtr^[i];
      CASE UserData[1] OF
        0 : BEGIN
              IF ch=^M THEN
                d.x:=0
              ELSE IF ch=^J THEN
              BEGIN
                 dec(d.x);
                 inc(d.y);
              END
              ELSE IF (ch=^H) AND (d.x>1) THEN dec(d.x,2);
              IF ch=^C THEN
                UserData[1]:=1
              ELSE
              IF ch=^L THEN BEGIN
                s:='';
                clrscr
              END
              ELSE IF (ch=^B) AND (d.x=1) THEN
                UserData[1]:=2
              ELSE
                BEGIN
                  inc(d.x);
                  IF d.x>d.mx THEN
                  BEGIN
                    d.x:=1;
                    inc(d.y);
                  END;
                  s:=s+ch;
                  {write(OldOutput,ch);}
                END
            END;
        1 : BEGIN
              write(OldOutput,s);
              s:='';
              DoColor(ch);
              UserData[1]:=0;
            END;
        2 : IF ch<>^M THEN
              CenterString := CenterString + ch
            ELSE BEGIN
              Center(CenterString);
              UserData[1]:=0;
              write(OldOutput,^M);
              CenterString := '';
            END;
      END;
    END;
    write(oldoutput,s);
    s:='';
    f.BufPos:=0;
    working:=false;
  END;
  TranslateOutput:=0;
END;

PROCEDURE InitOutp(MaxX,MaxY:integer;
                  SetDirectVideo,SetComm,SetFossil,color,IS_WWIV:Boolean; port:byte);
BEGIN
(* THE NEXT TWO LINES ARE NEEDED IF YOU WANT TO MODIFY THE COLORMAP EXTERNALLY*)
  CenterString:=IdColorMap;
  CenterString:=chr(colormap[0]);
  CenterString:='';
  WWIVOUTP.IS_WWIV:=IS_WWIV;
  IF SetDirectVideo THEN InitNewCrt(color,MaxY)
  ELSE IF SetFossil THEN FossilInit(port)
  ELSE IF SetComm THEN AsyncInit(port);

  IF SetDirectVideo THEN
    Translate:=DirectVideo
  ELSE
    Translate:=None;
  TextRec(OldOutput) := TextRec(OutPut);
  WITH TextRec(Output) DO
  BEGIN
    Mode:=fmOutput;
    InOutFunc := @TranslateOutput;
    FlushFunc := @TranslateOutput;
    GetMem(BufPtr,128);
    UserData[1]:=0;
  END;
  WITH D DO
  BEGIN
{    GetMem(Txt,MaxX*MaxY);
    GetMem(Clr,MaxX*MaxY);}
    x:=1; y:=1;
    mx:=maxx; my:=maxy;
  END;
END;


{$F-}

END.
