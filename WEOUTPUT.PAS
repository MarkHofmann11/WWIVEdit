UNIT WEOutput;
{$I WEGLOBAL.PAS}
{ -- This is the Output Unit of WWIVEdit 2.4
  -- Last Updated : 11/28/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This Code is Limited Public Domain (see WWIVEdit.pas for details)
  --
  -- Purpose : Does the main output of WWIVEdit
  --
  -- Know Errors: None
  --
  -- }

INTERFACE

CONST
    c0 = ^C'0'; c1 = ^C'1'; c2 = ^C'2'; c3 = ^C'3';
    c4 = ^C'4'; c5 = ^C'5'; c6 = ^C'6'; c7 = ^C'7';
    ESC= #27;

TYPE
  ScreenLine = ARRAY[1..80] OF RECORD
           c : char;
           a : byte;
         END;

  ScreenBuff = ARRAY[1..50] OF ScreenLine;

CONST
  PausePrompt : String[7] = '[PAUSE]';

VAR
  DisplayColor:char;
  lx : integer;

PROCEDURE ClrScr;
PROCEDURE ClrEOL;
PROCEDURE ReverseVideoOn;
PROCEDURE ReverseVideoOff;
PROCEDURE Ansic(c:char);
PROCEDURE GotoXY(x,y:byte);
FUNCTION  WhereY:integer;
FUNCTION  WhereX:integer;
PROCEDURE MoveLeft(n:integer);
PROCEDURE Center(s:string);
PROCEDURE nl;
PROCEDURE ReadScreen(VAR s:string; x,y:integer);
PROCEDURE WriteScreen(s:string; x,y,at:integer);
PROCEDURE WriteControl(ch:char);
PROCEDURE Redisplay;
PROCEDURE ForcedRedisplay;
PROCEDURE ShowHeader;
PROCEDURE ShowMaxLines;
PROCEDURE StatusLine1(s:string);
PROCEDURE StatusLine2(s:string);
PROCEDURE StatusLine3(s:string);
PROCEDURE ClrStatLine3;
PROCEDURE ClrStatLine2;
PROCEDURE PrintControlLine(s:string);
PROCEDURE ShowOtherScreen;
PROCEDURE ShowWhere;
PROCEDURE ScrollWindowUp(x1,y1,x2,y2:byte);
PROCEDURE ScrollWindowDown(x1,y1,x2,y2:byte);
PROCEDURE ResetViewport;
PROCEDURE SaveDisplay;
PROCEDURE RestoreDisplay;

IMPLEMENTATION

USES DOS, WEString, WEKbd, WEVars, WELine, WETime,WWIVOutp, WEUser,WEMouse,
     WEFunc,WEESM;

VAR
  Inverse : boolean;

CONST
  snum : integer = 0;

PROCEDURE SaveDisplay;
VAR
  f:file;
BEGIN
  inc(snum);
  assign(f,StartUpDir+'SCREEN.'+ZExpand(snum,3));
  rewrite(f,ScreenSize);
  blockwrite(f,Display^,1);
  close(f);
END;

PROCEDURE RestoreDisplay;
VAR
  f:file;
BEGIN
  assign(f,StartupDir+'SCREEN.'+ZExpand(snum,3));
  reset(f,ScreenSize);
  blockRead(f,Display^,1);
  close(f);
  erase(f);
  dec(snum);
END;

PROCEDURE ScrollWindowUp(x1,y1,x2,y2:byte);
VAR i:integer;
BEGIN
  IF setting.mouse AND MouseInstalled THEN HideMouse;
  FOR i:=ViewTop TO ViewBottom-1 DO
    Screen[i-ViewTop+1]:=Screen[i-ViewTop+2];
  InitLine(Screen[ViewBottom-ViewTop+1]);
  inc(ViewTop);
  inc(ViewBottom);
  BiosScrollWindowUp(x1,y1,x2,y2);
  IF setting.mouse AND MouseInstalled THEN ShowMouse;
END;

PROCEDURE ScrollWindowDown(x1,y1,x2,y2:byte);
VAR
  i:integer;
BEGIN
  IF setting.mouse AND MouseInstalled THEN HideMouse;
  FOR i:=ViewBottom DOWNTO ViewTop+1 DO
    Screen[i-ViewTop+1]:=Screen[i-ViewTop];
  InitLine(Screen[1]);
  dec(ViewTop);
  dec(ViewBottom);
  BiosScrollWindowDown(x1,y1,x2,y2);
  IF setting.mouse AND MouseInstalled THEN ShowMouse;
END;

PROCEDURE ResetViewport;
BEGIN
  IF cy>ViewBottom THEN          { "Scroll" the viewport down if needed    }
  BEGIN
    ViewTop:=cy-3;
    ViewBottom:=ViewTop+WindowHeight;
    IF ViewBottom>MaxLines THEN
    BEGIN
      ViewBottom:=MaxLines;
      ViewTop:=ViewBottom-WindowHeight;
    END;
  END;
  IF cy<ViewTop THEN             { "Scroll" the viewport up if needed      }
  BEGIN
    ViewBottom:=cy+3;
    ViewTop:=ViewBottom-WindowHeight;
    IF ViewTop<1 THEN
    BEGIN
      ViewTop:=1;
      ViewBottom:=ViewTop+WindowHeight;
    END;
  END;
END;

PROCEDURE MoveLeft;
BEGIN
  wwivoutp.moveleft(n);
END;

PROCEDURE ReverseVideoOn;
BEGIN
  inverse:=true;
  wwivoutp.reversevideoon;
END;

PROCEDURE ReverseVideoOff;
BEGIN
  inverse:=false;
  wwivoutp.reversevideooff;
END;

PROCEDURE Ansic(c:char);
{ New version of ANSIC requires a CHAR instead of an Int... it simplifies
  using all the Color Mods out there }
BEGIN
  IF Inverse THEN ReverseVideoOff;
  write(^C+C);
  DisplayColor:=c;
END;

PROCEDURE WriteControl(ch:char);
{ Writes Ch in inverted colors... should be in the range [#0..#31] }
BEGIN
  ReverseVideoOn;
  Write(chr(ord(ch)+ord('@'))); { prints out H for ^H, etc }
  ReverseVideoOff;
END;

PROCEDURE ClrEol;
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  wwivoutp.clreol;
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;

PROCEDURE Center(s:string);
BEGIN
  writeln(' ':40-(lengthw(s) div 2),s);
END;


PROCEDURE nl;
BEGIN
  write(#13#10);
END;

PROCEDURE ClrScr;
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  WWIVOutp.Clrscr;
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;

FUNCTION WhereX;
BEGIN
  WhereX:=WWIVOutP.WhereX
END;

FUNCTION WhereY;
BEGIN
  WhereY:=WWIVOutP.WhereY
END;

PROCEDURE Gotoxy;
BEGIN
  wwivoutp.gotoxy(x,y)
END;

PROCEDURE WriteScreen(s:string; x,y,at:integer);
VAR
  i:integer;
BEGIN
  i:=x;
  WHILE (i<80) AND (i-x+1<=length(s)) DO
  WITH screenbuff(display^)[y][i] DO
  BEGIN
    c:=s[i-x+1];
    a:=at;
    inc(i);
  END;
END;


PROCEDURE ReadScreen(VAR s:string; x,y:integer);
VAR
  i:integer;
BEGIN
  s:='';
  FOR i:=x TO 80 DO
    s:=s+screenbuff(display^)[y][i].c;
END;

PROCEDURE Redisplay;
{ This updates the physical display, does a pretty good job of not doing
  more than it has to, but occasionally does...                          }
VAR
  y, i   : integer;
  p      : integer;
  Shorter: boolean;
  cc     : char;
  vp, py : integer;

BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  cc := DisplayColor;
  IF cy<ViewTop THEN BEGIN
    ViewTop:=cy;
    SetTopScreen(ScreenState);
  END ELSE IF cy>ViewBottom THEN BEGIN
    ViewTop:=cy-WindowHeight;
    SetTopScreen(ScreenState);
  END;
  FOR y := ViewTop TO ViewBottom DO
  IF y <= MaxLines THEN                             { If its a legal line and }
  IF (Line^[y]^.l <> screen[y - ViewTop + 1].l) OR   { either the color or text}
     (Line^[y]^.c <> screen[y - viewtop + 1].c) THEN { has changed, then       }
  BEGIN                                             { display the changes     }
    vp := y - ViewTop + 1;          { The line corresponding to y in Screen[] }
    py := y + WindowTop - ViewTop;                  { The physical screen line}
    shorter:=length(Screen[vp].l) > length(Line^[y]^.l);       { used later on }
    p := firstdiff(screen[vp], Line^[y]^);           { Find position of first  }
    gotoxy(p,py);
    IF numdiff(screen[vp],Line^[y]^)>1 THEN
    FOR i := p TO len(y) DO
    BEGIN
       IF cc<>Line^[y]^.c[i] THEN
       BEGIN
         ansic(Line^[y]^.c[i]);
         cc:=Line^[y]^.c[i];
       END;
       IF character(y,i) IN [#32..#255]            { write character }
         THEN write(character(y,i))
         ELSE WriteControl(character(y,i));
    END { for loop }
    ELSE IF NOT Shorter THEN
    BEGIN
      ansic(Line^[y]^.c[p]);
      cc:=Line^[y]^.c[p];
      IF character(y,p) IN [#32..#255]            { write character }
        THEN write(character(y,p))
        ELSE WriteControl(character(y,p));
    END;
    IF shorter THEN                         { If the line is shorter }
    BEGIN
      IF (wherex <> len(y) + 1) OR (wherey <> py) THEN
        gotoxy(len(y) + 1, py);             { move to the end of it }
      cc:='0';                              { Set Color to 0 }
      Ansic('0');                           { Clear to end of line }
      clreol;
    END;
    screen[vp] := Line^[y]^;                 { update screen array }
  END;
  IF DisplayColor <> CurrentColor THEN      { Change color if needed }
    Ansic(currentColor);
  IF NOT ((wherex=cx) AND                   { reposition if needed }
          (Wherey=cy+WindowTop-ViewTop)) THEN
    gotoxy(cx,cy+WindowTop-ViewTop);
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;

PROCEDURE ForcedRedisplay;
{ This will make sure that the screen is redisplayed }
VAR x:integer;
BEGIN
  ansic('0');
  FOR x:=1 TO MaxPhyLines DO
    initline(screen[x]);
  clrscr;
  ShowHeader;
  Redisplay;
END;

PROCEDURE ShowHeader;
{ Prints the message header and also the Max Lines }
VAR
  i:integer;
  s:string;
BEGIN
  ShowMaxLines;
  IF ScreenState IN [0,2,3] THEN
  BEGIN
    gotoxy(1,1);
    clreol;  writeln(Gets(XSTR+27),copy(Title,1,70));
  END;
  IF ScreenState=0 THEN
  BEGIN
      clreol;  writeln(Gets(XSTR+28),copy(destination,1,70));
      clreol; write(Gets(XSTR+29),time);
      gotoxy(40,wherey);
      XWriteln(30);
  END;
  IF ScreenState IN [0,2,4] THEN
  BEGIN
    IF ScreenState=4 THEN gotoxy(1,1);
    clreol;
    s:='[';
    s[0]:=chr(LineLen);
    FOR i:=2 TO LineLen-1 DO
      IF i mod 10=0 THEN s[i]:=chr(i div 10+ord('0'))
        ELSE IF i mod 5 =0 THEN s[i]:='|'
          ELSE s[i]:='.';
    s[LineLen]:=']';
    writeln(s);
  END;
END;

FUNCTION wy:integer;
VAR
  r:registers;
BEGIN
  r.ah:=3; r.bh:=0;
  intr($10,r);
  wy:=r.dh+1;
END;

PROCEDURE ShowMaxLines;
VAR s:string;
BEGIN
  s:=Gets(XSTR+31)+' '+cstr(MaxLines)+'  '+C4;
  IF InsertMode THEN s:=s+Gets(XStr+17) ELSE s:=s+Gets(XSTR+18);
  StatusLine2(s+C0);
  IF Info.username <> '' THEN
    WriteScreen(Info.UserName+'  '+thisuser.name+' #'+
      cstr(usernum),WhereX+2,WY,7)
  ELSE WriteScreen(Gets(XSTR+56)+SettingName,WhereX+2,WY,7);
END;

PROCEDURE StatusLine1(s:string);
VAR wx,wy:integer;
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  wx:=WhereX; wy:=Wherey;
  gotoxy(1,WindowBottom+2);
  clreol; write(s);
  Gotoxy(wx,wy);
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;

PROCEDURE StatusLine2(s:string);
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  Gotoxy(1,WindowBottom+2);
  clreol; write(s);
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;

PROCEDURE StatusLine3(s:string);
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  Gotoxy(1,WindowBottom+1);
  clreol; write(s);
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;
VAR
 savep_sx,savep_sy : byte;
PROCEDURE SaveP;
BEGIN
  savep_sx:=wherex;
  Savep_sy:=wherey;
END;
PROCEDURE RestoreP;
BEGIN
  Gotoxy(savep_sx,savep_sy);
END;

PROCEDURE PrintControlLine(s:string);
VAR i:integer;
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  ansic('0');
  FOR i:=1 TO length(s) DO
    IF s[i] IN [#32..#255]
      THEN write(s[i])
      ELSE WriteControl(s[i]);
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
END;

PROCEDURE ShowOtherScreen;
VAR
  ch:char;
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  SaveDisplay;
  Move(SaveScreen^,Display^,ScreenSize);
  REPEAT
    ch:=Readkey;
  UNTIL NOT KeyPressed;
  RestoreDisplay;
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
END;

{$F+}
VAR ly:integer;
PROCEDURE ShowWhere;
{ Procedure Called by GetKey (as the BeforeNext procedure) to display the
  cursor position.  It must be activated (by ^KW) }
VAR x,y:byte;
BEGIN
  IF (lx<>cx) OR (ly<>cy) THEN
  BEGIN
    x:=wherex; y:=wherey;
    statusline3(c0+cstr(cx)+':'+cstr(cy));
    Gotoxy(x,y);
  END;
  lx:=cx; ly:=cy;
END;
{$F-}



{$F+} PROCEDURE ClrStatLine3; BEGIN SaveP; StatusLine3(C0); AfterNext:=DoNothing; RestoreP END; {$F+}
{$F+} PROCEDURE ClrStatLine2; BEGIN SaveP; StatusLine2(C0); AfterNext:=DoNothing; RestoreP END; {$F+}

END.
