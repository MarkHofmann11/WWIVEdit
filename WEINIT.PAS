UNIT WEInit;
{$I WEGLOBAL.PAS}
{ -- This is the Initialization Module for WWIVEdit 2.2
  -- Last Modified 4/14/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This Code is limited Public Domain (see WWIVEDIT.PAS for details
  --
  -- Known Errors: None
  --
  -- Planned Enhancements: None
  -- }

INTERFACE

PROCEDURE Initialize;
PROCEDURE LoadKeyBindings(KeyName:string);
PROCEDURE LoadSettings(SettingName:string);
FUNCTION  Newer(f1,f2:string):boolean;

IMPLEMENTATION

USES DOS,WEVars, WEString, WELine, WEOutput, WEInput, WEFunc, WEEsm,
     WESetup, WEKbd, WWIVOutp, WEUser, WETitle, WEMouse, WEMemory;

FUNCTION Newer(f1,f2:string):boolean;
{ returns true if f2 is newer than f1 }
VAR s1,s2:searchrec;
BEGIN
  FindFirst(f1,0,s1);
  IF DOSError<>0 THEN s1.time:=0;
  FindFirst(f2,0,s2);
  IF DOSError<>0 THEN s2.time:=0;
  Newer:=s2.time>s1.time;
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

PROCEDURE HandleCommandLine;
VAR
  x:integer;
  s:string;
BEGIN
{  FOR x:=1 TO ParamCount DO
  BEGIN
    s:=TransformString(ParamStr(x));
  END;}
END;


FUNCTION CommandLine(s:string):string;
VAR
  i:integer;
  t:string;
  res:string;
BEGIN
  res:='';
  FOR i:=1 TO ParamCount DO
  BEGIN
    t:=ParamStr(i);
    IF (t[1]='/') OR (t[1]='-') THEN
    BEGIN
      delete(t,1,1);
      IF CmpLeftI(t,s+':') THEN res:=RightS(t,length(t)-length(s)-1);
    END;
  END;
  commandline:=res;
END;

PROCEDURE LoadKeyBindings(KeyName:string);
VAR
  f:file;
  i:integer;
BEGIN
{$I-}
  IF Newer(ConfigDir+KeyName+KeyExt,ConfigDir+KeyName+BindingExt) THEN
    Compile_KEY(KeyName);
  assign(f,ConfigDir+KeyName+KeyExt);
  reset(f,1);
  IF IOResult<>0 THEN BEGIN
    writeln(ConfigDir+KeyName+KeyExt+' not found.');
    IF TransformString(KeyName)<>'DEFAULT' THEN
    BEGIN
      XWritelns(48,50);
      pausescr;
      LoadKeyBindings('DEFAULT');
      exit;
    END
    ELSE BEGIN
      MemCleanup;
      halt(1);
    END
  END;
  blockread(f,Key_Description,Sizeof(key_description));
  IF BindingSize>0 THEN
    FreeMem(KeyBindings,BindingSize);
  blockread(f,nbindings,sizeof(integer));
  blockread(f,BindingSize,sizeof(integer));
  GetMem(KeyBindings,BindingSize);
  blockread(f,KeyBindings^,BindingSize);
  close(f);
{$I+}
  Escaped:='';
  FOR i:=1 TO Key_description.NEscaped DO
    Escaped:=Escaped+Key_description.Escaped_Keys[i];
END;

PROCEDURE LoadSettings(SettingName:string);
VAR
  f : file;
  res : integer;
BEGIN
  IF Newer(ConfigDir+SettingName+SettingExt,ConfigDir+SettingName+DefExt) THEN
    Compile_DEF(SettingName);
  assign(f,ConfigDir+SettingName+SettingExt);
  {$I-} reset(f,sizeof(settingrec));
  IF IOResult<>0 THEN
  BEGIN
    writeln(ConfigDir+SettingName+settingExt+' not found.');
    MemCleanup;
    halt(1);
  END;
  blockread(f,setting,1,res);
  close(f);
  {$I+}
END;
TYPE wcp = PROCEDURE(s:string);

PROCEDURE Do_Wildcard(wc:string; f:wcp);
VAR sr:SearchRec;
BEGIN
  FindFirst(wc,0,sr);
  WHILE DOSError=0 DO
  BEGIN
    IF Verbose THEN writeln;
    writeln('Working on ',sr.name);
    IF Verbose THEN writeln;
    f(copy(sr.Name,1,pos('.',sr.name)-1));
    FindNext(sr);
  END;
END;



PROCEDURE Initialize;
VAR ch:char;
  st:string;
  x:integer;
  res : word;
  sr:searchrec;
  r:registers;
  f:file;
BEGIN
  ConfigDir:=StartupDir+'CONFIG\';
  DictDir:=StartupDir+'DICT\';
  IF (ParamCount=1) THEN BEGIN
    st:=TransformString(ParamStr(1));
    IF (st='-F') OR (st='/F') THEN
    BEGIN
      writeln;
      writeln;
      XWriteln(51);
      writeln;
      XWrite(52);
      writeln(configdir);
      writeln;
      XWrite(53);
      REPEAT
        r.ah:=7; msdos(r);
        ch:=upcase(chr(r.al));
      UNTIL ch in ['Y','N'];
      writeln(ch);
      Verbose:=ch='Y';
      Do_WildCard(StartUpDir+'CONFIG\*.DEF',Compile_Def);
      Do_Wildcard(StartupDir+'CONFIG\*.KEY',Compile_Key);
      writeln;
      writeln('Done!');
      MemCleanup;
      halt(0);
    END
  END;
  Randomize;
(**** Allocate Memory - If you need to use the heap, save space here ****)
  GetMem(SaveScreen,ScreenSize); { Save same space for screen swapping }
{  GetMem(SaveScreen1,ScreenSize);{ And this one is for page flipping }

(**** Initialize Records ****)
  FillChar(info,SizeOf(Info),0);

(**** Get Settings ******)
  SettingName:=CommandLine('SET');
  IF SettingName='' THEN SettingName:='DEFAULT';
  KeyName:=CommandLine('KEY');
  IF KeyName='' THEN KeyName:='DEFAULT';

  LoadSettings(SettingName);

  IF setting.DictDir<>'' THEN
    DictDir:=Setting.dictdir;


  ESC_Ticks:=setting.ticks;

(**** Initialize Strings ****)
  FileName:=ParamStr(1);

(**** Get User Information ****)
  InitInfo; Drain;
  IF Setting.SetupType IN [1,3] THEN
    FindTitle(Title,Destination);
  IF info.ticks>0 THEN ESC_Ticks:=info.ticks*100;
  IF Setting.ResultType=2 THEN
    AllowTitleChange:=TRUE;

  IF Info.KeyFile<>'' THEN KeyName:=Info.KeyFile;
  LoadKeyBindings(KeyName);

(**** Initialize Integers ****)
  LineLen:=value(ParamStr(2));
  IF LineLen>79 THEN LineLen:=79;
  IF LineLen=0 THEN LineLen:=79;
  ScreenHeight:=value(ParamStr(3));
  IF (screenHeight<30) AND (ScreenHeight>25) THEN ScreenHeight:=25;
  IF ScreenHeight=0 THEN ScreenHeight:=ScreenSize DIV 160;
  IF ScreenHeight>=60 THEN ScreenHeight:=60
  ELSE IF ScreenHeight>=50 THEN ScreenHeight:=50
  ELSE IF ScreenHeight>=43 THEN ScreenHeight:=43
  ELSE ScreenHeight:=25;
  IF info.ScreenHeight>0 THEN ScreenHeight:=info.ScreenHeight;
  ScreenState:=info.ScreenState;

  MaxLines:=value(ParamStr(4));
  IF MaxLines>AbsoluteMaxLines THEN MaxLines:=AbsoluteMaxLines-1;
  IF MaxLines=0 THEN MaxLines:=AbsoluteMaxLines-1;

  SetTopScreen(ScreenState);

(**** Initialize Procedure variables ****)
  AfterNext:=DoNothing;
  BeforeNext:=DoNothing;

(**** Initialize Arrays ****)
  IF Setting.mono=3 THEN
    IF Mem[0:$449]=7 THEN Setting.Mono:=1 ELSE Setting.Mono:=0;
  IF setting.mono=1 THEN
    Display:=ptr($b000,0);
  Move(Display^, SaveScreen^, ScreenSize); { Save Original Display }

  new(Line);
  new(Line^[0]);
  InitLine(Line^[0]^);

(**** Initialize macro info ****)
  assign(transtable,StartupDir+'WWIVEDIT.KEY');

(**** Initialize Tagline Info ****)
  FindFirst(FileName,0,sr);
  FileThere:=DosError=0;
  IF CmpLeftI(Filename,'BBS') AND
     (RightS(TransformString(FileName),4)='.TAG') THEN
    FileThere:=TRUE;

  IF Setting.BBS=BBS_Telegard THEN Filename:='MSGTMP';

  IF Filename='' THEN BEGIN
    Xwriteln(54);
    MemCleanup;
    halt(1);
  END;

  x:=thisuser.SL DIV 10;
  IF x=0 THEN x:=1
  ELSE IF x>11 THEN x:=11;

  IF setting.lines[x]>0 THEN MaxLines:=setting.lines[x]
  ELSE IF setting.lines[x]<0 THEN MaxLines:=AbsoluteMaxLines;

  FOR x:=1 TO AbsoluteMaxLines DO
    Line^[x]:=NIL;

  IF (setting.comport>0) AND (CommandLine('B')='0') THEN Setting.Comport:=0;
  InitOutp(80,ScreenHeight,Setting.DirectVideo,Setting.Comport>0,Setting.Fossil AND (Setting.ComPort>0),
           Setting.Mono=0,Setting.BBS=BBS_WWIV,Setting.Comport);

  x:=1;
  WHILE (x<=MaxLines) AND (MaxAvail>2*sizeof(LineType)+4*1024) DO
  BEGIN
    Line^[x]:=Malloc(sizeof(LineType));
    Line^[x]^:=Line^[0]^;
    inc(x);
  END;
  MaxLines:=x-1;

  FOR x:=1 TO MaxPhyLines DO
    initline(screen[x]);
  InsertMode:=NOT info.insertmode;

  IF Setting.Mouse AND MouseInstalled THEN
  BEGIN
    SetMouseXY(1,1,80,ScreenHeight);
    SetMousePosition(80,1);
    ShowMouse;
  END;
  IF Setting.TabStop<>0 THEN TabStop:=Setting.TabStop;
  IF Setting.BBS=BBS_Telegard THEN Ansic('1');
END; { Initialize }


END.
