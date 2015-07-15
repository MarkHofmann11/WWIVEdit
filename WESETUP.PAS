UNIT WESetup;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

INTERFACE

CONST
  verbose : BOOLEAN = FALSE;

PROCEDURE Compile_DEF(Filename:string);
PROCEDURE Compile_KEY(Filename:string);

IMPLEMENTATION

USES WeString, WEVars,DOS,WEMemory,WEESM;

TYPE Keyarray=ARRAY[1..1000] OF KeyBinding;

VAR
  LinesRead : integer;
  KeyBindings : ^KeyArray;

FUNCTION Param(s:string):string;
BEGIN
  Param:=Copy(s,pos('[',s)+1,pos(']',s)-pos('[',s)-1);
END;

FUNCTION GetLine(VAR t:text):string;
VAR s:string;
BEGIN
  inc(LinesRead);
  readln(t,s);
  GetLine:=s;
END;

FUNCTION Trans(s:string):string;
VAR
  out:string;
  t:string;
BEGIN
  out:='';
  WHILE s<>'' DO
  BEGIN
    IF s[1]='^' THEN
    BEGIN
      out:=out+chr(ord(upcase(s[2]))-ord('@'));
      delete(s,1,2);
    END
    ELSE IF s[1]='#' THEN
    BEGIN
      t:='';
      delete(s,1,1);
      WHILE (s<>'') AND (s[1] IN ['0'..'9']) DO
      BEGIN
        t:=t+s[1];
        delete(s,1,1);
      END;
      out:=out+chr(value(t));
    END
    ELSE BEGIN
      out:=out+s[1];
      delete(s,1,1);
    END;
  END;
  Trans:=out;
END;



FUNCTION FindFun(s:string):edfun;
{ This may look ugly, but its actually a little more speed effiecient
  than my first attempt, and a lot more space efficient.              }
VAR
  f:edfun;
BEGIN
  f:=0;
  WHILE (f<=LastDefined) AND (GetS(f)<>s) DO
    inc(f);
  IF f>LastDefined THEN f:=None;
  FindFun:=f;
END;


PROCEDURE Handle(VAR t:text; name:string);
VAR
  s:string;
  fun:edfun;
  Special:string;
  i:integer;
BEGIN
  fun:=FindFun(TransformString(name));
  IF (fun=none) AND (TransformString(name)<>'NONE') THEN
  BEGIN
    writeln('Error in Definition file.');
    writeln('Error on Line ',linesread,' Invalid descriptor :',name);
    writeln('Ignoring it.');
    exit;
  END;
  IF verbose THEN write('Handling : ',name,'  ');
  IF Pos('[',name)>0 THEN
  BEGIN
    Special:=Trans(Param(name));
    IF verbose THEN write('Param [',param(name),'] ');
  END;
  i:=1;
  REPEAT
    s:=Trans(Getline(t));
    IF Length(s)>BindingMaxLength THEN
    BEGIN
      writeln('Error! Definition too long on line ',linesread);
      writeln('Under heading of ',Name);
      writeln('Program halted.');
      MemCleanup;
      halt(1);
    END;
    IF s<>'' THEN
    BEGIN
      IF verbose THEN write(i,'...');
      inc(i);
      inc(nbindings);
      KeyBindings^[nbindings].keys:=s;
      KeyBindings^[nbindings].fun:=fun;
    END;
  UNTIL s='';
  IF verbose THEN writeln;
END;


FUNCTION Ok(s:string):boolean;
BEGIN
  Ok:=(Param(s)='1') OR (TransformString(Param(s))='Y');
END;

FUNCTION KeyBiosCheck(s:string):boolean;
VAR
  r:registers;
BEGIN
  KeyBiosCheck:=(Param(s)='1') OR (TransformString(s)='Y');
  IF Param(s)='2' { gotta auto detect } THEN
  BEGIN
    r.ah:=5;
    r.cx:=1;
    intr($16,r);
    r.ah:=$b;
    msdos(r);
    KeyBiosCheck:=(r.al=$ff);
    IF r.al=$ff THEN
    BEGIN
      r.ah:=$07;
      msdos(r);
    END
  END;
END;

FUNCTION Int(s:string):integer;
BEGIN
  int:=value(param(s));
END;

FUNCTION StripChar(VAR s:string):char;
VAR s1:string;
BEGIN
  IF s[1]='#' THEN BEGIN
    delete(s,1,1);
    s1:='';
    WHILE (s<>'') AND (s[1] IN ['0'..'9']) DO
    BEGIN
      s1:=s1+s[1];
      delete(s,1,1);
    END;
    StripChar:=chr(value(s1));
  END ELSE BEGIN
    StripChar:=s[1];
    delete(s,1,1);
  END;
END;

FUNCTION GetNext(VAR s:string):string;
VAR p:byte;
BEGIN
  p:=pos(',',s);
  IF p=0 THEN p:=length(s)+1;
  GetNext:=copy(s,1,p-1);
  delete(s,1,p);
END;


PROCEDURE HandleSet(VAR cset:charset; s:string);
VAR ch,rs,re:char;
BEGIN
  WHILE s<>'' DO
  BEGIN
    rs:=StripChar(s);
    IF s[1]='-' THEN BEGIN
      delete(s,1,1);
      re:=StripChar(s)
    END
    ELSE
      re:=rs;
    FOR ch:=rs TO re DO
      setting.colors:=Cset+[ch];
    IF (s<>'') AND (s[1]=',') THEN
      delete(s,1,1);
  END;
END;

PROCEDURE SetDefaults;
VAR
  i : integer;
  ch : char;
BEGIN
  FillChar(Setting,Sizeof(setting),#0);
  WITH Setting DO
  BEGIN
    IF Mem[0:$449]=7 THEN Mono:=1 ELSE Mono:=0;
    MCI       := [];
    Mouse     := TRUE;
    DisableUserTag := FALSE;
    AllowColorChangeInTitle:=TRUE;
    KeyBios   := FALSE;
    DisableBBSTag :=FALSE;
    Colors:=[];
    AddSL := 30;
    Version:=VER_ID;
    WarnTime:=90;
    DisconnectTime:=180;
  END
END;

PROCEDURE HandleLines(s:string);
VAR
  t : string;
  i : integer;
BEGIN
  FOR i:=1 TO 11 DO
  BEGIN
     IF s='' THEN BEGIN
       writeln('LINES setting requires 11 parameters exactly');
       MemCleanup;
       halt(1);
     END;
     Setting.Lines[i]:=value(getnext(s));
     IF Verbose THEN
       write(setting.lines[i],'...');
  END;
  IF s<>'' THEN BEGIN
     writeln('LINES setting requires 11 parameters exactly');
     MemCleanup;
     halt(1);
  END;
END;


PROCEDURE Get_Escaped(s:string);
BEGIN
  s:=param(s);
  with key_description do
  WHILE s<>'' DO BEGIN
    inc(nescaped);
    Escaped_keys[nescaped]:=stripchar(s);
    IF (s<>'') AND (s[1]=',') THEN delete(s,1,1);
  END;
END;


FUNCTION HandleMaskKeys(s:string):byte;
CONST
  Mask = 'RLCA';
VAR
  i : integer;
  msk : byte;
BEGIN
  s:=transformstring(s);
  msk:=0;
  FOR i:=1 TO Length(s) DO
  BEGIN
    IF pos(s[i],mask)=0 THEN BEGIN
      writeln('Error in parameter:');
      writeln(S[i],' is not a valid choice, ignoring.');
    END
    ELSE
      Msk:=Msk OR (1 shl (pos(s[i],mask)-1));
  END;
  IF msk=0 THEN msk:=$ff;
  IF verbose THEN writeln('=',msk);
  HandleMaskKeys := Msk;
END;


PROCEDURE HandleSetting(s:string);
VAR
  Name : string;
  p:integer;
BEGIN
  p:=pos(';',s);
  IF p>0 THEN delete(s,p,length(s)-p+1);
  Name := TransformString(copy(s,1,pos(':',s)-1));
  IF Name='' THEN Exit;
  IF verbose THEN writeln('Handling "',Name,'" - Param [',param(s),']');
  WITH Setting DO
       IF Name='ABORTTIME'  THEN DisconnectTime := int(s)
  ELSE IF Name='BBS'        THEN BBS:=int(s)
  ELSE IF Name='ADDSL'      THEN AddSL:=Int(s)
  ELSE IF Name='BBSTAG'     THEN DisableBBSTag:=ok(s)
  ELSE IF Name='BBSDISABLE' THEN BoardEditDisable:=int(s)
  ELSE IF Name='CHATKEY'    THEN ChatMask:=HandleMaskKeys(Param(s))
  ELSE IF Name='COLORS'     THEN HandleSet(Setting.Colors,Param(s))
  ELSE IF Name='COLORTITLE' THEN AllowColorChangeInTitle:=ok(s)
  ELSE IF Name='COMPORT'    THEN Comport:=Int(s)
  ELSE IF Name='CURSOR'     THEN ChangeCursor := ok(s)
  ELSE IF Name='FOSSIL'     THEN Fossil:=ok(s)
  ELSE IF Name='DICTDIR'    THEN DictDir:=Param(s)
  ELSE IF Name='DIRECTVIDEO' THEN DirectVideo:=ok(s)
  ELSE IF Name='DIVIDER'    THEN Divider:=Param(s)
  ELSE IF Name='DOSKEY'     THEN DosMask:=HandleMaskKeys(Param(s))
  ELSE IF Name='ESCTICKS'   THEN Ticks := int(s)
  ELSE IF Name='INSDIR'     THEN InsertDir:=Param(s)
  ELSE IF Name='KEYBOARD'   THEN KeyBios:=KeyBiosCheck(s)
  ELSE IF Name='NOPERSON'   THEN NoTagPersonal:=Param(s)
  ELSE IF Name='NOTAG'      THEN NoTagBBS:=Param(s)
  ELSE IF Name='MCI'        THEN HandleSet(Setting.Colors,Param(s))
  ELSE IF Name='LINES'      THEN HandleLines(Param(s))
  ELSE IF Name='LOCAL'      THEN Local:=ok(s)
  ELSE IF Name='MONO'       THEN BEGIN IF int(s)<>2 THEN Mono:=int(s); END
  ELSE IF Name='PERSONALDICT' THEN PersonalDicAllowed := ok(s)
  ELSE IF Name='PREFIX'     THEN BEGIN
                                   s:=Param(s);
                                   IF length(s)>10 THEN writeln('Prefix too long... 10 char max.')
                                   ELSE Prefix:=s;
                                 END
  ELSE IF Name='QUOTER'     THEN Quoter := int(s)
  ELSE IF Name='REPLY'      THEN ReplyType:=int(s)
  ELSE IF Name='RESULT'     THEN ResultType:=Int(s)
  ELSE IF Name='SCROLL'     THEN SmoothScroll:=ok(s)
  ELSE IF Name='SETUP'      THEN SetupType:=int(s)
  ELSE IF Name='TABSTOP'    THEN TabStop:=int(s)
  ELSE IF Name='TAG'        THEN DisableUserTag:=ok(s)
  ELSE IF Name='WARNTIME'   THEN WarnTime :=int(s)
  ELSE IF Name='WWIVEDITMACROS' THEN  WWIVEditMacrosOk := ok(s)
  ELSE IF Name='CHATMODE' THEN Chatmode:=int(s)
  ELSE IF Name='MOUSE'      THEN Mouse:=OK(s)
  ELSE BEGIN
    writeln('ERROR!  Unknown Setting "',Name,'"');
    writeln('Ignoring it.');
  END;
END;

PROCEDURE Compile_DEF(Filename:string);
VAR
  t:text;
  i:integer;
  s:string;
  ch : char;
  f:file;
BEGIN
  IF Verbose THEN
    writeln('Loading Defaults...');
  setdefaults;

  assign(t,ConfigDir+Filename+DefExt);
  reset(t);
  WHILE Not EOF(t) DO
  BEGIN
    s:=getline(t);
    IF pos(':',s)<>0 THEN
      HandleSetting(s);
  END;

  close(t);
  assign(f,ConfigDir+Filename+SettingExt);
  rewrite(f,1);
  blockwrite(f,Setting,sizeof(setting));
  close(f);
END;

PROCEDURE Compile_KEY(Filename:string);
VAR
  t:text;
  i,size:integer;
  s,s1:string;
  ch : char;
  f:file;

BEGIN
  FillChar(Key_Description,sizeof(Key_Description),#0);
  New(KeyBindings);
  nbindings:=0;
  IF Verbose THEN
    writeln('Loading key bindings...');
  ASSIGN(t,ConfigDir+Filename+BindingExt);
  reset(t);
  WHILE NOT Eof(t) DO
  BEGIN
    REPEAT
      s:=getline(t);
    UNTIL EOF(t) OR (s<>'') AND (s[1]<>'#');
    IF (copy(s,1,1)=':') AND (copy(s,length(s),1)=':') THEN
      handle(t,copy(s,2,length(s)-2))
    ELSE IF pos(':',s)>0 THEN BEGIN
      s1:=TransformString(copy(s,1,pos(':',s)-1));
           IF s1='DESCRIPTION' THEN Key_Description.Description:=Param(s)
      ELSE IF s1='ESCAPED_KEYS' THEN Get_Escaped(s)
      ELSE IF s1='LOCALONLY' THEN Key_Description.local_only:=ok(s)
      ELSE IF s1='MINSL' THEN Key_Description.min_sl:=value(param(s))
      ELSE BEGIN
        writeln('Error in key bindings file.');
        writeln('Unknown configurable parameter "',s1,'"');
        writeln('Ignoring...');
      END;
    END;
  END;
  IF Verbose THEN
    writeln('Saving bindings...');
  assign(f,ConfigDir+Filename+KeyExt);
  rewrite(f,1);
  blockwrite(f,Key_Description,Sizeof(Key_Description));
  blockwrite(f,nbindings,sizeof(integer));
  size:=0;
  FOR i:=1 TO NBindings DO
    size:=size+sizeof(edfun)+length(KeyBindings^[i].keys)+1;
  blockwrite(f,size,sizeof(integer));
  FOR i:=1 TO NBindings DO
    blockwrite(f,KeyBindings^[i],sizeof(edfun)+length(KeyBindings^[i].keys)+1);
  IF Verbose THEN
  BEGIN
    writeln('  Total Bindings: ',nbindings);
    writeln('  Size: ',Size);
  END;
  close(f);
  Dispose(KeyBindings);
  NBindings:=0;
END;


END.

