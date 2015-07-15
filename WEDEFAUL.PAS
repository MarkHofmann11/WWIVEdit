UNIT WEDefaul;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{ -- User Defaults Module for WWIVEdit 2.3
  -- Purpose: Allow a user to set up ceartain defaults
  -- }
INTERFACE

PROCEDURE EditDefaults;

IMPLEMENTATION

USES WEVars, WEOutput, WEInput, WEString, WEFunc, WEInit, DOS,
     WEUser, WEMouse, WEESM;

CONST
  Nfields=7;
  NStates=5;
  MaxKeyFiles = 50;
  NReply=2;
  ReplyType : ARRAY[0..NReply] OF String[12] = (
    'Never','E-Mail Only','Always');

FUNCTION Element(from:string; n:integer):String;
VAR
  p:integer;
BEGIN
  WHILE n>1 DO
  BEGIN
    p:=pos('/',from);
    dec(n);
    delete(from,1,p);
  END;
  p:=pos('/',from);
  IF p>0 THEN delete(from,p,length(from)-p+1);
  Element:=from;
END;

PROCEDURE GetScreenState;
VAR
  i:integer;
  ch:char;
  s:string;
BEGIN
  NL;
  s:=GetS(XSTR+14);
  FOR i:=1 TO NStates DO
    writeln(C2+'<'+C1+chr(i+64)+C2+'>'+c5+' '+Element(s,i));
  writeln(C2+'<'+C1+'Q'+C2+'>'+C5+'uit');
  NL;
  write(C2+'Choice > [ABCDEQ] ');
  ch:=ReadSet(['A'..'E','Q']);
  IF ch<>'Q' THEN
  BEGIN
    ScreenState:=ord(ch)-65;
    SetTopScreen(ScreenState);
    info.screenstate:=screenstate;
  END;
END;

PROCEDURE GetScreenHeight;
VAR s:string;
BEGIN
  nl;
  XWrite(15);
  writeln(C1+cstr(ScreenHeight)+C5+' rows high.');
  XWrite(16);
  write(' ['+cstr(ScreenHeight)+'] ');
  SimpleInput(s,2);
  info.screenheight:=value(s);
  IF info.screenheight=0 THEN info.screenheight:=ScreenHeight;
  ScreenHeight:=info.screenheight;
  SetTopScreen(ScreenState);        { Forces some things to be recalculated }
END;

PROCEDURE GetInsertMode;
BEGIN
  info.insertmode:=NOT info.insertmode;
  insertmode:=NOT info.insertmode;
END;

PROCEDURE GetTimingConstant;
VAR
  s:string;
BEGIN
  nl;
  XWritelns(0,3);
  XWrite(4);
  writeln(Setting.Ticks DIV 100,'.');
  nl;
  XWrite(5);
  SimpleInput(s,3);
  IF s<>'' THEN
    IF (value(s)>=0) AND (value(s)<256) THEN
    BEGIN
      info.ticks:=value(s);
      ESC_ticks:=info.ticks*100;
      IF ESC_ticks=0 THEN ESC_ticks:=setting.ticks;
    END;
END;

FUNCTION Usable(FileInfo:KeyInfoRec):boolean;
VAR
  ok : boolean;
BEGIN
  ok:=(thisuser.sl>=FileInfo.Min_SL);
  IF (FileInfo.Local_Only AND NOT Setting.Local) THEN OK:=false;
  Usable:=ok;
END;

PROCEDURE GetKeyName;
VAR
  sr : SearchRec;
  f  : File;
  Des: KeyInfoRec;
  nfound : integer;
  Map: ARRAY[1..MaxKeyFiles] OF String[8];
  s  : string;
  choice : integer;
  okset: charset;
  i : integer;
  ch:char;

BEGIN
  writeln;
  XWriteln(6);
  nfound:=0;
  FindFirst(ConfigDir+'*'+keyExt,0,sr);
  WHILE DOSError=0 DO
  BEGIN
    assign(f,ConfigDir+sr.name);
    reset(f,1);
    blockread(f,des,sizeof(des));
    close(f);
    IF Usable(des) THEN
    BEGIN
      inc(nfound);
      writeln(C1+Cstr(nfound)+'. '+C2+LJustify(FName(sr.Name),8)+
            C3+' - '+C1+des.description);
      Map[nfound]:=Fname(sr.name);
    END;
    FindNext(sr);
  END;
  write(C2,'Choice > [');
  okset:=['Q'];
  FOR i:=1 TO Nfound DO
  BEGIN
    okset:=okset+[chr(i+ord('0'))];
    write(chr(i+ord('0')));
  END;
  write('Q] '+C1);
  ch:=readset(okset);
  choice:=ord(ch)-ord('0');
  IF (choice>0) AND (choice<=nfound) THEN
  BEGIN
    info.KeyFile:=Map[choice];
    KeyName:=info.KeyFile;
    LoadKeyBindings(KeyName);
  END;
END;

PROCEDURE GetReplyStatus;
VAR
  i:integer;
  okset:charset;
  ch:char;
BEGIN
  writeln;
  XWritelns(7,10);
  FOR i:=0 TO NReply DO
    writeln(C1,i+1,C3,'. ',c5,ReplyType[i]);
  writeln;
  XWrite(11);
  writeln(Info.AskReply+1);
  write(C2+'Choice [');
  okset:=['Q'];
  FOR i:=0 TO NReply DO
  BEGIN
    write(chr(i+ord('1')));
    okset:=okset+[chr(i+ord('1'))];
  END;
  write('Q] ');
  ch:=readset(okset);
  IF ch<>'Q' THEN Info.AskReply:=ord(ch)-ord('1');
END;

PROCEDURE EditDefaults;
VAR
  i : integer;
  ch : char;
  s:string;
BEGIN
  REPEAT
    clrscr;
    IF Setting.Mouse AND MouseInstalled THEN HideMouse;
    XWrite(12);
    write(C1+VERSION);
    XWriteln(13);
    NL;
    FOR i:=1 TO NFields DO
    BEGIN
      s:=GetS(Xdefaults+i-1);
      s:=s+dup(' ',25-length(s));
      write(C2+'<'+C1+chr(i+64)+C2+'>'+c5+' '+s+' '+C3+': '+C1);
      CASE i OF
        1 : writeln(Element(GetS(XSTR+14),info.ScreenState+1));
        2 : BEGIN
              write(info.screenheight);
              IF info.screenheight=0 THEN write(' (',ScreenHeight,')');
              NL;
            END;
        3 : IF NOT info.InsertMode
              THEN XWriteln(17)
              ELSE XWriteln(18);
        4 : IF Info.ticks>0
              THEN writeln(Info.ticks)
              ELSE writeln(Setting.ticks);
        5 : writeln(TransformString(KeyName));
        6 : writeln(ReplyType[Info.AskReply]);
        7 : IF info.asktag
              THEN writeln('Yes')
              ELSE writeln('No');
      END;
    END;
    IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
    writeln(C2+'<'+C1+'Q'+C2+'>'+C5+'uit');
    NL;
    write(C2+'Choice > ');
    ch:=ReadSet(['A'..'G','Q']);
    NL;
    CASE CH OF
      'A' : GetScreenState;
      'B' : GetScreenHeight;
      'C' : GetInsertMode;
      'D' : GetTimingConstant;
      'E' : GetKeyName;
      'F' : GetReplyStatus;
      'G' : Info.AskTag:=NOT Info.AskTag;
    END;
  UNTIL ch='Q';
END;

END.
