UNIT WETag;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL}
{ -- This is the Tag Lines unit of WWIVEdit 2.4
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is limited public domain.  See WWIVEDIT.PAS for details.
  --
  -- Purpose : Input/Manipulate the Taglines
  -- }

INTERFACE

FUNCTION  GetUserTagline:String;
PROCEDURE EditTaglines;

IMPLEMENTATION

USES WEVars, WEInput, WEOutput, WEString, WEInit, WEUser,WEMouse,WEEsm;

FUNCTION GetUserTagline:string;
VAR
  Map : ARRAY[1..3] OF Byte;
  i, n : integer;
BEGIN
  GetUserTagline:='';
  IF info.method=0 THEN exit;
  IF info.method=6 THEN
  BEGIN
    info.method:=info.selected;
    GetUserTagline:='';
    exit;
  END;
  i:=0;
  IF info.method=4 THEN
  BEGIN
    REPEAT
      inc(info.selected);
      IF info.selected>3 THEN info.selected:=1;
      inc(i);
    UNTIL (i>3) OR (info.tagline[info.selected]<>'');
    GetUserTagline:=info.tagline[info.selected];
    Exit;
  END;
  IF (info.method=5) THEN
  BEGIN
    n:=0;
    fillchar(map,sizeof(map),#0);
    FOR i:=1 TO 3 DO
      IF info.tagline[i]<>'' THEN
      BEGIN
        inc(n);
        map[n]:=i;
      END;
    Info.Selected:=Map[random(n)+1];
    GetUserTagline:=info.tagline[info.selected];
    IF n=0 THEN GetUserTagline:='';
    Exit;
  END;
  GetUserTagline:=info.tagline[info.method];
END;

PROCEDURE EditTaglines;
{ Edit and Select Taglines }
CONST
  NMethods = 6;
VAR
  i  : integer;
  ch : char;
  s : string;
  TagS:string;
  fun:edfun;
  changed:boolean;
  t:inforec;

BEGIN
  IF Setting.Mouse AND MouseInstalled THEN HideMouse;
  t:=info;
  changed:=false;
  ClrScr;
  FOR i:=1 TO 3 DO
  BEGIN
    write(C5+'Tagline number '+C2);
    CASE i OF
      1 : writeln('one:');
      2 : writeln('two:');
      3 : writeln('three:');
    END;
    ansic('0');
    IF info.Tagline[i]<>'' THEN BEGIN
      PrintControlLine(info.TagLine[i]);
      nl;
    END
    ELSE
      Xwriteln(64);
    nl;
  END;
  FOR i:=0 TO NMethods DO
  BEGIN
    IF info.Method = i THEN Ansic('4') ELSE Ansic('1');
    write(Pads(XTags+i,40));
    ansic('0');
    IF info.Method = i
      THEN XWriteln(63)
      ELSE nl;
  END;
  REPEAT
    StatusLine3(Gets(XSTR+65));
    IF Setting.Mouse AND MouseInstalled THEN ShowMouse;
    ch:=ReadSet(['M','E','Q','C',ESC]);
    IF LocationOverride THEN LocationOverride:=FALSE;
    IF ch='E' THEN BEGIN
      StatusLine3(Gets(XSTR+66));
      ch:=readset(['1'..'3','A',ESC,'Q']);
      IF ch IN ['1'..'3'] THEN BEGIN
        info.Tagline[ord(ch)-ord('0')]:='';
        StatusLine2(c5+'Tagline '+c1+ch+c5+' erased');
        gotoxy(1,3*(ord(ch)-ord('0')-1)+2);
        ClrEol;
        Xwriteln(64);
        changed:=true;
        AfterNext:=ClrStatLine2;
      END;
    END;
    IF ch='C' THEN BEGIN
      i:=info.method;
      REPEAT
        GotoXY(1,10+i);
        fun:=GetArrow;
        ansic('1');
        IF Fun IN [up,down,Mouse] THEN
          write(Pads(XTags+i,40));
        CASE Fun OF
          Up : dec(i);
          Down : inc(i);
          Mouse: LocationOverride :=False;
        END;
        IF i<0 THEN i:=NMethods
        ELSE IF i>NMethods THEN i:=0;
        IF fun IN [Up,Down,Mouse] THEN
        BEGIN
          GotoXY(1,10+i);
          ansic('4');
          write(Pads(Xtags+i,40));
        END;
      UNTIL fun IN [Enter,NormalExit];
      IF fun=Enter THEN BEGIN
        if info.method<>i THEN changed:=true;
        gotoxy(40,10+info.method);
        clreol;
        IF i=6 THEN info.selected:=info.method;
        info.method:=i;
        gotoxy(1,10+i);
        writeln(C4+Pads(Xtags+i,40),C0,Gets(XSTR+63));
      END
      ELSE if i<>info.method THEN
      BEGIN
        writeln(c0+Pads(Xtags+i,40));
        gotoxy(1,10+info.method);
        writeln(c4+Pads(Xtags+info.method,40)+c0);
      END;
    END;
    IF ch='M' THEN BEGIN
      StatusLine3(Gets(XStr+67));
      TagS:=GetControlLine;
      StatusLine2(c0);
      PrintControlLine(TagS);
      StatusLine3(Gets(XStr+68));
      ch:=ReadSet(['1'..'3','Q']);
      IF ch='Q' THEN BEGIN
        StatusLine2(C2+'Nothing Saved...');
        AfterNext:=ClrStatLine2;
        ch:=#0;
      END
      ELSE BEGIN
        changed:=true;
        i:=Value(ch);
        gotoxy(1,3*(i-1)+2);
        PrintControlLine(TagS);
        ClrEol;
        info.Tagline[i]:=TagS;
        StatusLine2(C0);
      END;
    END;
  UNTIL ch IN ['Q',ESC];
  IF changed THEN BEGIN
    IF Info.method=5 THEN BEGIN
        info.selected:=Random(3)+1;
        IF Info.Tagline[info.selected]='' THEN BEGIN
          FOR i:=1 TO 3 DO
            IF info.tagline[i]<>'' THEN info.selected:=i;
        END;
    END
    ELSE IF Info.method=4 THEN
    BEGIN
      Info.selected:=1;
      FOR i:=3 DOWNTO 1 DO
        IF info.tagline[i]<>'' THEN info.selected:=i;
    END ELSE IF info.method<4 THEN
      info.selected:=info.method;

    IF (Info.method IN [4,5]) AND (info.tagline[info.selected]='') THEN
      info.selected:=1;
    StatusLine3(Gets(XSTR+69));
    IF yn THEN BEGIN
      SaveInfo;
      StatusLine3(c5+'Saved.');
    END ELSE BEGIN
      StatusLine3(c2+'Not Saved.');
      info:=t;
    END;
  END;
  AfterNext:=ClrStatLine3;
END;

END.
