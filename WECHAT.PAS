UNIT WEChat;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{$V-}
{ -- Chat module for WWIVEdit 2.4
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is limited Public Domain.  See WWIVEDIT.PAS for more details.
  --
  -- Purpose: To do what was previously un-doable... Create a two
  -- way (split screen) color chat, using the BBS I/O routines (and some
  -- fancy programming).
  -- }

INTERFACE
PROCEDURE Chat(LineLen,ScreenHeight:integer);

IMPLEMENTATION

USES WEKbd, WEString, WEOutput, WEVars, WEInput,WEESM;



PROCEDURE TwoWayChat(Title:string; LineLen,ScreenHeight:integer);
TYPE
  stringl=STRING[81];

VAR
  ch:char;
  x:integer;
  s:string;
  lastlocal:boolean;
  RemoteTop : integer;
  lx,ly,rx,ry : integer;
  RemoteBottom : integer;
  temp : string;

  PROCEDURE WordWrap(VAR s1:StringL; VAR s2:string);
  VAR
    i,x:integer;
  BEGIN
    s2:='';
    x:=length(s1);
    WHILE (x>0) AND (NOT (s1[x]=' ')) DO
      dec(x);
    IF x<>0 THEN
    BEGIN
      s2 := copy(s1,x+1,length(s1)-x);
      moveleft(length(s1)-x);
      clreol;
      system.delete(s1,x+1,length(s2));
    END;
    writeln;
  END;


  PROCEDURE IncRY;
  VAR x:integer;
  BEGIN
    inc(ry);
    rx:=1;
    IF ry>RemoteBottom THEN
    BEGIN
      FOR x:=1 TO 4 DO
      BEGIN
        Screen[RemoteTop+x-1].l:=Screen[RemoteBottom-4+x].l;
        gotoxy(1,RemoteTop+x-1);
        write(screen[remoteTop+x-1].l);
        clreol;
      END;
      FOR x:=RemoteTop+4 TO RemoteBottom DO
      BEGIN
        Screen[x].l:='';
        gotoxy(1,x);
        clreol;
      END;
      ry:=RemoteTop+4;
      rx:=1;
    END;
    gotoxy(rx,ry);
  END;

  PROCEDURE IncLY;
  VAR x:integer;
  BEGIN
    inc(ly);
    lx:=1;
    IF ly>RemoteTop-2 THEN
    BEGIN
      FOR x:=1 TO 4 DO
      BEGIN
        Screen[x].l:=Screen[RemoteTop-6+x].l;
        gotoxy(1,x);
        write(Screen[x].l);
        clreol;
      END;
      FOR x:=5 TO RemoteTop-2 DO
      BEGIN
        gotoxy(1,x);
        Screen[x].l:='';
        clreol;
      END;
      ly:=5;
      lx:=1;
    END;
    gotoxy(lx,ly);
  END;

  PROCEDURE ControlX(l:integer);
  BEGIN
    Screen[l].l:='';
    gotoxy(1,l);
    clreol;
  END;

  PROCEDURE ControlW(l:integer; VAR x:integer);
  BEGIN
    WHILE (x>0) AND (screen[l].l[x]<>' ') DO
    BEGIN
      write(#8#32#8);
      dec(x);
    END;
    screen[l].l[0]:=chr(x);
    inc(x);
  END;

BEGIN
  FOR x:=1 TO MaxPhyLines DO
    screen[x].l:='';
  clrscr;
  lastlocal:=true;
  RemoteTop:=ScreenHeight DIV 2;
  RemoteBottom := ScreenHeight-2;
  lx:=1; ly:=2;
  rx:=1; ry:=13;
  SeperateLocalInput;
  Ansic('7');
  write('Chat mode:');
  gotoxy(1,RemoteTop-1);
  ansic('3');
  writeln(dup('=',(LineLen-length(title)) div 2)+c4+Title+c3+dup('=',(LineLen-length(title)) div 2));
  ansic('2');
  gotoxy(lx,ly);
  s:='';
  REPEAT
    REPEAT UNTIL KeyPressedL OR KeyPressed;

    IF KeyPressedL THEN
    BEGIN
      ch:=readkeyL;
      IF not LastLocal THEN
      BEGIN
        gotoxy(lx,ly);
        ansic('2');
        LastLocal:=true;
      END;
      IF NOT (ch IN [#0..#31]) THEN
      BEGIN
        Screen[ly].l:=Screen[ly].l+ch;
        write(ch);
        inc(lx);
        IF lx>=LineLen THEN
        BEGIN
          wordwrap(screen[ly].l,temp);
          IncLY;
          screen[ly].l:=temp;
          write(temp);
          lx:=length(temp)+1;
        END;
      END
      ELSE IF ch=^X THEN BEGIN ControlX(ly); lx:=1; END
      ELSE IF ch=^W THEN ControlW(ly,lx)
      ELSE IF ch=#13 THEN IncLY
      ELSE IF ch=#27 THEN ch:=#255
      ELSE IF ch=#0 THEN BEGIN
        ch:=readkeyL;
        IF ch=#68 THEN ch:=#255 ELSE ch:=#0;
      END
      ELSE IF ch=#8 THEN
        IF lx>1 THEN BEGIN
          dec(lx);
          write(#8#32#8);
          delete(Screen[ly].l,lx,1);
        END
    END
    ELSE IF KeyPressed THEN
    BEGIN
      ch:=readkey;
      IF lastlocal THEN
      BEGIN
        gotoxy(rx,ry);
        ansic('1');
        LastLocal:=false;
      END;
      IF NOT (Ch IN [#0..#31,#255]) THEN
      BEGIN
        Screen[ry].l:=Screen[ry].l+ch;
        write(ch);
        inc(rx);
        IF rx>=LineLen THEN
        BEGIN
          wordwrap(screen[ry].l,temp);
          incRY;
          screen[ry].l:=temp;
          write(temp);
          rx:=length(temp)+1;
        END;
      END
      ELSE IF ch=^X THEN BEGIN ControlX(ry); rx:=1; END
      ELSE IF ch=^W THEN ControlW(ry,rx)
      ELSE IF ch=#13 THEN IncRY
      ELSE IF ch=#8 THEN
        IF rx>1 THEN BEGIN
          dec(rx);
          write(#8#32#8);
          delete(screen[ry].l,rx,1);
        END
    END
  UNTIL ch=#255;

  MergeLocalInput;
END;

PROCEDURE SafeChat(LineLen:integer);
VAR
  ch:char;
  done:boolean;
BEGIN
  clrscr;
  writeln(C7+'Chat Mode:');
  Ansic('0');
  REPEAT
    ch:=readkey;
    CASE ch OF
      #13 : write(#13#10);
      #8  : write(#8#32);
    END;
    IF ch=#0 THEN BEGIN
      ch:=readkey;
      done:=ch=#68;
    END ELSE
    IF ch=#27 THEN BEGIN
      ch:=GetKey(True);
      IF ch=#0 Then Done:=true
      ELSE ch:=Readkey;
    END
    ELSE IF NOT (ch IN [#27,#13,#10]) THEN write(ch);
  UNTIL done;
END;


PROCEDURE Chat(LineLen,ScreenHeight:integer);
{ Calls TwoWayChat, and then restores the screen afterwards }
VAR
  ch:char;
BEGIN
  ch:=DisplayColor;
  IF (ScreenSize Div 160<27) AND (ScreenHeight>24) THEN ScreenHeight:=24;
  IF Setting.ChatMode=0 THEN
    TwoWayChat(Gets(XSTR+26),LineLen,ScreenHeight)
  ELSE
    SafeChat(LineLen);
  ansic(ch);
  ForcedRedisplay;
END;

END.