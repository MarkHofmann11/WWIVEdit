{$F+,S-}
UNIT NewCRT;
{ Crt unit designed for use with WWIVEdit, although it should be complete
  enough to use for anything. }
INTERFACE

CONST
  Black        = 0;
  Blue         = 1;
  Green        = 2;
  Cyan         = 3;
  Red          = 4;
  Magenta      = 5;
  Brown        = 6;
  LightGray    = 7;
  DarkGray     = 8;
  LightBlue    = 9;
  LightGreen   = 10;
  LightCyan    = 11;
  LightRed     = 12;
  LightMagenta = 13;
  Yellow       = 14;
  White        = 15;
  Blink        = 128;

VAR
  TextAttr  : Byte;
  FillChar  : char;
  VSeg      : word;
  MaxL      : byte;

  OldOutput:text;

PROCEDURE InitNewCRT(color:boolean; maxlines:integer);
PROCEDURE GotoXY(x,y:byte);       { Set Cursor position }
PROCEDURE ClrScr;                 { Clear entire Screen }
PROCEDURE ClrEol;                 { Clear to end of current line }
PROCEDURE ClrEos;                 { Clear to end of the screen  }
PROCEDURE TextColor(n:byte);      { Set foreground color }
PROCEDURE TextBackground(n:byte); { Set background color }
PROCEDURE Color(f,b:byte);        { Set Both Foreground and Background at once }
FUNCTION  WhereX : byte;          { Returns the current X coord }
FUNCTION  WhereY : byte;          { Returns the Current Y Coord }
PROCEDURE BiosScrollWindowUp(x1,y1,x2,y2:byte);
PROCEDURE BiosScrollWindowDown(x1,y1,x2,y2:byte);
PROCEDURE Beep;

IMPLEMENTATION

USES DOS;

VAR
  cp        : word;
  busy      : boolean;

PROCEDURE BiosScrollWindowUp(x1,y1,x2,y2:byte);
VAR r:registers;
BEGIN
  WITH r DO
  BEGIN
    ax:=$601; {Scroll window up one line}
    ch:=y1-1; cl:=x1-1; dh:=y2-1; dl:=x2-1;
    bh:=7; { normal text attribute }
  END;
  intr($10,r);
END;

PROCEDURE BiosScrollWindowDown(x1,y1,x2,y2:byte);
VAR r:registers;
BEGIN
  WITH r DO
  BEGIN
    ax:=$701; {Scroll window up one line}
    ch:=y1-1; cl:=x1-1; dh:=y2-1; dl:=x2-1;
    bh:=7; { normal text attribute }
  END;
  intr($10,r);
END;

PROCEDURE FillWord(VAR x; count,w : word); assembler;
asm
  les  di, x
  mov  cx, count
  mov  ax, w
  cld
  repz stosw
end;

FUNCTION WhereX : byte;
BEGIN
  IF Not BUSY THEN Flush(Output);
asm
  mov  ax,[CP]
  mov  cl, 160
  div  cl
  mov  al, ah
  inc  al
  mov @result, al
end
END;

FUNCTION WhereY : byte;
BEGIN
  IF NOT Busy THEN Flush(Output);
asm
  mov  ax,[CP]
  mov  cl, 160
  div  cl
  inc  al
  mov @result, al
end
END;

PROCEDURE ShowCursor; assembler;
asm
  mov  ax, [cp]  { get current position}
  shr  ax, 1     { divide by two}
  mov  cl, 80
  div  cl
  mov  dx, ax
  xchg dh, dl
  xor  bh, bh
  mov  ah, 2
  int  10h
end;

PROCEDURE TextColor(n:byte);
BEGIN
  IF Not Busy THEN Flush(Output);
  TextAttr := (TextAttr AND $70) OR N
END;

PROCEDURE TextBackground(n:byte);
BEGIN
  IF Not BUSY THEN Flush(Output);
  TextAttr := (TextAttr AND $8F) OR (N shl 4);
END;

PROCEDURE GotoXY(x,y:byte);
BEGIN
  IF Not Busy THEN Flush(output);
  cp := ((y-1) * 80 + (x-1)) shl 1;
  ShowCursor;
END;

PROCEDURE ClrScr;
BEGIN
  IF NOT Busy THEN Flush(Output);
  FillWord(MemW[Vseg:0],80*MaxL,TextAttr shl 8 + ord(FillChar));
END;

PROCEDURE ClrEol;
BEGIN
  IF NOT Busy THEN Flush(Output);
  FillWord(MemW[Vseg:cp],(160 - cp mod 160) shr 1,TextAttr shl 8 + ord(FillChar));
END;

PROCEDURE ClrEos;
BEGIN
  IF NOT Busy THEN Flush(Output);
  FillWord(MemW[vseg:cp],82*MaxL-cp shr 1,TextAttr shl 8 + ord(FillChar))
END;


PROCEDURE Color(f,b:byte);
BEGIN
  TextAttr := b shl 4 + f;
END;

PROCEDURE Beep;
CONST
  Frequency=750;
  Cfreq = 1193280 DIV Frequency;
  Duration=50000;

VAR x:Word;
BEGIN
  port[$43]:=$B6;
  port[$42]:=Cfreq AND $FF;
  port[$42]:=(Cfreq AND $FF00) shr 8;
  port[$61]:=port[$61] OR 3;
  FOR x:=1 TO Duration DO ;
  port[$61]:=port[$61] AND 252;
END;


FUNCTION DoNothing(VAR f:TextRec):integer;
BEGIN
  DoNothing :=0;
END;

FUNCTION OutCh(VAR f:TextRec):integer;
VAR
  b:byte;
  ch : byte;
BEGIN
  IF NOT Busy THEN
  BEGIN
    Busy:=TRUE;
    b:=0;
    WHILE f.BufPos>0 DO
    BEGIN
      ch:=ord(F.BufPtr^[b]);
      inc(b);
      dec(F.BufPos);
      IF ch IN [1..255]-[7,8,9,10,13] THEN
      BEGIN
        MemW[Vseg:cp]:=TextAttr shl 8 + ch;
        inc(cp,2);
      END ELSE
      CASE Ch OF
        10 : BEGIN
               cp:=((cp mod 160) + (cp div 160 + 1)*160);
               WHILE cp>=80*MaxL*2 DO
                 BEGIN
                   cp:=cp-160;
                   BiosScrollWindowUp(1,1,80,MaxL);
                 END;
               END;
        12 : clrscr;
        13 : cp:=cp - (cp mod 160);
        7  : beep;
        8  : dec(cp,2);
        9  : BEGIN
               FillWord(MemW[vseg:cp],8,TextAttr shl 8 + ord(FillChar));
               inc(cp,16);
             END;
      END;
    END;
    ShowCursor;
    OutCh := 0;
    Busy:=FALSE;
  END;
END;

PROCEDURE InitNewCRT(color:boolean; maxlines:integer);
BEGIN
  cp:=0;
  busy:=false;
  FillChar := #32;
  TextAttr:=7;
  TextRec(OldOutput):=textrec(output);
  WITH TextRec(Output) DO
  BEGIN
    Mode:=fmOutput;
    InOutFunc := @OutCh;
    FlushFunc := @OutCh;
    UserData[1]:=0;
  END;
  IF Color THEN
    VSeg:=$B800
  ELSE
    VSeg:=$B000;
  maxl:=maxlines;
END;

END.
