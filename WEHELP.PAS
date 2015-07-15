UNIT WEHelp;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{ -- Help unit for WWIVEdit 2.4
  -- Provides a user interface for the help section
  -- }
INTERFACE

TYPE StringArray = ARRAY[1..80] OF String[20];

PROCEDURE Help;
FUNCTION ChooseString(Topics:StringArray;
                      NFound,StartAt:integer;
                      Header:string):Integer;

IMPLEMENTATION

USES WEVars,WEOutput,WEInput,WEString,WEMouse,WEMemory,WEEsm;

PROCEDURE Expand(VAR s:string);
VAR
  i,l:integer;
  id : string;
BEGIN
  i:=pos('%',s);
  l:=pos('%',copy(s,i+1,length(s)-i))-1;
  id:=TransformString(copy(s,i+1,l));
  delete(s,i,l+2);
  IF id='VERSION' THEN insert(VER_ID,s,i)
  ELSE BEGIN
    writeln('Problem with help file');
    MemCleanup;
    halt;
  END;
END;

FUNCTION ChooseString(Topics:StringArray;
                      NFound,StartAt:integer;
                      Header:string):Integer;
  PROCEDURE GotoP(x:integer);
  BEGIN
    gotoxy(20*((x-1) mod 4)+1,((x-1) div 4) +2);
  END;
VAR
  ch:char;
  x:integer;
  lasttop,top : integer;
  fun : EdFun;
  Count,MX,MY,MouseB : word;
BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  LastTop:=StartAt;
  top:=StartAt;
  clrscr;
  writeln(Header);
  FOR x:=1 TO Nfound DO
  BEGIN
    GotoP(x);
    IF x=top
      THEN ansic('4')
      ELSE ansic('0');
    write(Topics[x]);
  END;
  GotoP(top);
  REPEAT
    IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
    fun:=GetArrow;
    IF Setting.Mouse AND MouseInstalled THEN HideMouse;
    IF fun IN [Up,Down,Left,Right,Mouse] THEN
    BEGIN
      CASE fun OF
        Up   : Dec(Top,4);
        Down : Inc(Top,4);
        Left : Dec(Top);
        Right: Inc(Top);
        Mouse: BEGIN
                 LocationOverride:=FALSE;
                 IF LocationOverride_Y>1 THEN
                 BEGIN
                   Top:=(LocationOverride_X div 20)+((LocationOverride_Y-2)*4)+1;
                   MouseB:=MouseRelease(0,Count,MX,MY);
                   IF (Count=1) AND ((Mx DIV 20+(My-2)*4+1)=Top) AND (Top<=NFound)
                     THEN Fun:=Enter;
                 END
                 ELSE Fun:=NormalExit;
                 IF Top>NFound THEN Top:=LastTop;
               END;
      END;
      IF Top<1 THEN Top:=Top+NFound
      ELSE IF Top>NFound THEN Top:=Top-NFound;
      IF Top<>LastTop THEN
      BEGIN
        ansic('0');
        write(Topics[LastTop]);
        GotoP(top);
        ansic('4');
        write(Topics[Top]);
        LastTop:=Top;
      END;
      GotoP(top);
    END;
    IF fun=InsertChar THEN Fun:=NormalExit;
  UNTIL Fun IN [Enter,NormalExit];
  IF fun=NormalExit
    THEN ChooseString:= -1
    ELSE ChooseString:=Top;
END;

PROCEDURE Help;
{ Prints out the Help file and then causes a redisplay afterward }
VAR
  ch:char;
  x:integer;
  top : integer;
  s,topic : string;
  fun : EdFun;
  t:text;
  topics : StringArray;
  nfound : integer;
  Count,MX,MY,MouseB : word;
BEGIN
  ansic('0');
  assign(t,StartupDir+'WWIVEDIT.HLP');
  topic:='';
  nfound := 0;
  {$I-} reset(t); {$I+}
  IF IOResult=0 THEN
  BEGIN
    REPEAT
      readln(t,s);
    UNTIL s='START';
    REPEAT
      readln(t,s);
      IF s<>'END' THEN BEGIN
        inc(nfound);
        topics[nfound]:=s;
      END;
    UNTIL s='END';
    IF Setting.Local THEN
    BEGIN
      REPEAT
        readln(t,s);
      UNTIL s='LOCAL';
      REPEAT
        readln(t,s);
        IF s<>'END' THEN BEGIN
          inc(nfound);
          Topics[nfound]:=s;
        END;
      UNTIL s='END'
    END;
  END;
  top:=1;
  IF Nfound<>0 THEN
  REPEAT
    Top:=ChooseString(Topics,NFound,Top, GetS(XStr+45));
    IF Top=-1 THEN Topic:=''
    ELSE Topic:=Topics[Top];
    Topic:=TransformString(Topic);
    IF Topic<>'' THEN
    BEGIN
      reset(t);
      gotoxy(1,22);
      write(C2+'Searching...');
      REPEAT
        readln(t,s);
      UNTIL (s='EOF') OR (s=Topic+':') OR ((s=Topic+';') AND Setting.Local);
      IF s='EOF' THEN writeln(C6+'Topic Not Found'+C0)
      ELSE BEGIN
        REPEAT
          readln(t,s);
        UNTIL s='SOT';
        clrscr;
        writeln(c7+'Topic '+c3+': '+c1+Topic);
        REPEAT
          readln(t,s);
          IF s[length(s)]=^A THEN delete(s,length(s),1);
          IF s[length(s)]=' ' THEN delete(s,length(s),1);
          IF pos('%',s)>0 THEN Expand(s);
          IF s='.P' THEN BEGIN
            PauseScr;
            ClrScr;
          END
          ELSE IF s='.COLORTABLE' THEN
          BEGIN
            count:=0;
            FOR ch:=#0 TO #255 DO
              IF ch IN Setting.Colors THEN
              BEGIN
                ansic(ch);
                IF ch IN [#32..#255] THEN write(ch) ELSE write(' ');
                write('(',ord(ch):3,') ');
                inc(count);
                IF count=10 THEN BEGIN
                  writeln;
                  count:=0;
                END;
              END;
            ansic('0');
            writeln;
          END
          ELSE IF cmpleft(s,^B) THEN Center(RightS(s,Length(s)-1))
          ELSE IF s<>'EOT' THEN
            writeln(C0+s);
        UNTIL (s='EOT') OR CheckAbort;
      END;
      close(t);
    END;
  UNTIL topic=''
  ELSE BEGIN
    XWritelns(46,47);
    ch:=GetKey(False);
  END;
  IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
  ForcedRedisplay;
END;


END.
