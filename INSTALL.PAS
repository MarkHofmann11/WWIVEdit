PROGRAM Install;
{{$DEFINE UPGRADE}

USES Dos,CRT,WEString,CURSORS,WEUser,WEVars;

TYPE PROC=PROCEDURE;

CONST InstallDir='';

CONST
{$IFDEF UPGRADE}
  NumFiles=19;
{$ELSE}
  NumFiles=21;
{$ENDIF}
  FileList : ARRAY[1..NumFiles] OF RECORD sname:String[12]; dname:string END = (
    (sname:'WWIVEDIT.EXE'; dname:'WWIVEDIT.EXE'),
    (sname:'WWIVEDIT.KEY'; dname:'WWIVEDIT.KEY'),
    (sname:'WWIVEDIT.HLP'; dname:'WWIVEDIT.HLP'),
    (sname:'LOCAL.DEF';    dname:'CONFIG\LOCAL.DEF'),
    (sname:'LOCAL.KEY';    dname:'CONFIG\LOCAL.KEY'),
    (sname:'OTHER.KEY';    dname:'CONFIG\OTHER.KEY'),
    (sname:'DEFAULT.DEF';  dname:'CONFIG\DEFAULT.DEF'),
    (sname:'DEFAULT.KEY';  dname:'CONFIG\DEFAULT.KEY'),
    (sname:'ECLIPSE.DEF';  dname:'CONFIG\ECLIPSE.DEF'),
    (sname:'DOS.DEF';      dname:'CONFIG\DOS.DEF'),
    (sname:'FOSSIL.DEF';   dname:'CONFIG\FOSSIL.DEF'),
    (sname:'COM.DEF';      dname:'CONFIG\COM.DEF'),
    (sname:'REGISTER.DOC'; dname:'DOC\REGISTER.DOC'),
    (sname:'LICENSE.DOC';  dname:'DOC\LICENSE.DOC'),
    (sname:'KEY.DOC';      dname:'DOC\KEY.DOC'),
    (sname:'WWIVEDIT.DOC'; dname:'DOC\WWIVEDIT.DOC'),
    (sname:'WWIVEDIT.STR'; dname:'WWIVEDIT.STR'),
    (sname:'EMP-HANG.MOD'; dname:'DOC\EMP-HANG.MOD'),
{$IFNDEF UPGRADE}
    (sname:'WWIVEDIT.DIC'; dname:'DICT\WWIVEDIT.DIC'),
    (sname:'HASH';         dname:'DICT\HASH'),
{$ENDIF}
    (sname:'CONFIG.DOC';   dname:'DOC\CONFIG.DOC')
  );
  NeededFiles=19;
  NeededList : ARRAY[1..NeededFiles] OF String[12] = (
    'WWIVEDIT.EXE','WWIVEDIT.KEY','WWIVEDIT.HLP',
    'LOCAL.DEF','LOCAL.KEY','DEFAULT.DEF','DEFAULT.KEY',
    'MACROS.LCL','REGISTER.DOC','LICENSE.DOC','KEY.DOC',
    'NOTAG.BBS','ECLIPSE.DEF','WWIVEDIT.DOC','CONFIG.DOC','FOSSIL.DEF',
    'DOS.DEF', 'OTHER.KEY','WWIVEDIT.STR'
  );

  NumOptional=2;
  OptionalList: ARRAY[1..NumOptional] OF RECORD sname:String[12]; dname:string END = (
    (sname:'NOTAG.BBS';    dname:'NOTAG.BBS'),
    (sname:'MACROS.LCL';   dname:'MACROS.LCL'));

  NumErase=8;
  EraseList : ARRAY[1..NumErase] OF String = (
    'CONFIG\DEFAULT.SET',
    'CONFIG\DEFAULT.KBD',
    'CONFIG\LOCAL.SET',
    'CONFIG\LOCAL.KBD',
    'CONFIG\ECLIPSE.SET',
    'CONFIG\FOSSIL.SET',
    'CONFIG\DOS.SET',
    'CONFIG\OTHER.KEY');


CONST
  InsertMode : boolean = TRUE;

  K_Left = #128;
  K_Right= #129;
  K_Up   = #130;
  K_Down = #131;
  K_Home = #132;
  K_End  = #133;
  K_Ins  = #134;
  K_Del  = #135;
  K_None = #255;

TYPE
  Cstring81=ARRAY[1..81] OF Char;
  Cstring21=ARRAY[1..21] OF Char;
  EditorRec = RECORD
    description, filename : CString81;
    config : LongInt;
    FilenameCon : Cstring81;
    reserved : ARRAY[1..119] OF Byte;
  END;

  ConfigRec = RECORD
    	newuserpw,systempw : Cstring21;
	msgsdir,gfilesdir,datadir,dloadsdir   : Cstring81;
        { rest of record not needed }
  END;

  EditorsFile = FILE of EditorRec;
  ConfigFile = FILE of ConfigRec;

  Secondary = RECORD
    hashval : word; { secondary hash value of this record }
    next    : word; { next index in file for primary hash value }
    index   : word; { Index into USER.TAG }
  END;
  ind2 = FILE of Secondary;


VAR
  Buffer : ARRAY[1..1024*5] OF Byte;
  Path:string;
  WWIVDir : string;
  ToDir : string;
  i : integer;
  ch : char;
  f:file;
  ok:boolean;
  dodelete:boolean;
  Infofile,inf1 : file of inforec;


CONST size=$800*4;

FUNCTION Hash1(VAR s:string):WORD;
VAR
  h:word;
  i,l:integer;
BEGIN
  h:=0;
  i:=1;
  l:=length(s);
  WHILE (i+1<=l) DO
  BEGIN
    h:=h XOR (ord(s[i]) shl 8) + ord(s[i+1]);
    i:=i+2;
  END;
  IF i=l THEN h:=h XOR ord(s[i]);
  hash1:=h shr 2 AND $7ff;
  IF (h shr 2 AND $7ff)=0 THEN hash1:=1;
END;


PROCEDURE Convert;
VAR
  s:string;
  f:file OF LongInt;
  index2 : ind2;
  h2,h1:WORD;
  i,l:word;
  p:longint;
  sh:Secondary;
  fi:file;
  ptr : pointer;
BEGIN
  usernum:=1;
  fillchar(info,sizeof(inforec),#0);
  fillchar(sh,sizeof(sh),#0);
  sh.hashval:=0; sh.next:=1;
  assign(inf1,ToDir+'\TAGLINES.CMN');
  reset(inf1);
  assign(f,ToDir+'\INDEX1.TAG');
  assign(index2,ToDir+'\INDEX2.TAG');
  assign(infofile,ToDir+'\USER.TAG');
  {$I-} reset(f); {$I+}
  IF IOResult<>0 THEN
  BEGIN
  { - for speed, use a big block and write it all at once }
    assign(fi,ToDir+'\INDEX1.TAG'); rewrite(fi,SIZE); getmem(ptr,SIZE);
    fillchar(ptr^,SIZE,#0);  blockwrite(fi,ptr^,1); close(fi); freemem(ptr,SIZE);
    reset(f);
    rewrite(index2);
    write(index2,sh);
    close(index2);
    rewrite(infofile);
    write(infofile,info);
    close(infofile);
  END;

  read(inf1,info);
  REPEAT
    h2:=usernum;
    read(inf1,info);
    s:=info.username;
    write(usernum);
    IF s<>'No Name' THEN
    BEGIN
      write('*');
      h1:=hash1(s);
      p:=0;
      reset(index2);
      reset(infofile);
      seek(f,h1);
      read(f,p);
      IF p=0 THEN { new user }
      BEGIN
        p:=filesize(index2);
        seek(f,h1);
        write(f,p);
        sh.hashval:=h2;
        sh.next:=0;
        sh.index:=filesize(infofile);
        seek(index2,filesize(index2));
        write(index2,sh);
        reset(index2);
        seek(infofile,sh.index);
        write(infofile,info);
        reset(infofile);
      END;
      seek(index2,p);
      read(index2,sh);
      WHILE sh.hashval<>h2 DO
      BEGIN
        IF sh.next=0 THEN
        BEGIN
          seek(index2,filepos(index2)-1);
          sh.next:=filesize(index2);
          write(index2,sh);
          sh.hashval:=h2;
          sh.next:=0;
          sh.index:=filesize(infofile);
          seek(index2,filesize(index2));
          write(index2,sh);
          seek(infofile,sh.index);
          write(infofile,info);
          reset(infofile);
        END ELSE BEGIN
          seek(index2,sh.next);
          read(index2,sh);
        END
      END;
    END;
    writeln;
    inc(usernum);
  UNTIL eof(inf1);
  close(infofile);
  close(inf1);
  close(f);
  close(index2);
END;


PROCEDURE Beep;
BEGIN
  sound(300);
  delay(100);
  sound(500);
  delay(25);
  sound(200);
  delay(100);
  nosound;
END;

PROCEDURE Erase(s:string);
VAR f:file;
BEGIN
{$I-}
  assign(f,s);
  System.erase(f);
  IF IOResult=0 THEN ;
{$I+}
END;


PROCEDURE Color(F,B:integer);
BEGIN
  TextColor(f);
  TextBackground(b);
END;

PROCEDURE OpenWindow(x1,y1,x2,y2,fore,back,bf,bb,tf,tb:integer; title:string);
VAR
  i:integer;
BEGIN
  window(x1,y2,x2+1,y2+1);
  WindMax:=y2*256+x2;
  Color(fore,back);
  clrscr;
  Color(bf,bb);
  write('…',dup('Õ',x2-x1-1),'ª');
  FOR i:=2 TO y2-y1 DO
  BEGIN
    gotoxy(1,i);
    write('∫');
    gotoxy(x2-x1+1,i);
    write('∫');
  END;
  gotoxy(1,y2-y1+1);
  write('»',dup('Õ',x2-x1-1),'º');
  Color(tf,tb);
  gotoxy(((x1+x2) div 2) - length(title) DIV 2,1);
  write(title);
  Color(fore,back);
  window(x1+2,y1+2,x2-2,y2-2);
END;

FUNCTION GetKey:char;
VAR
  ch:char;
BEGIN
  ch:=readkey;
  IF ch<>#0 THEN GetKey:=ch
  ELSE BEGIN
    ch:=readkey;
    CASE ch OF
      #75 : GetKey:=K_Left;
      #77 : GetKey:=K_Right;
      #82 : GetKey:=K_INS;
      #71 : GetKey:=K_Home;
      #79 : GetKey:=K_End;
      #83 : GetKey:=K_Del;
    ELSE GetKey:=K_None;
    END;
  END;
END;

PROCEDURE UpdateCursor;
BEGIN
  IF InsertMode
    THEN Cursor(UnderScore)
    ELSE Cursor(FullBlock);
END;


FUNCTION GetString(VAR s:string):boolean;
VAR
  AnythingYet : boolean;
  x,y,cx : integer;
  ch:char;
BEGIN
  UpdateCursor;
  x:=wherex; y:=wherey;
  AnythingYet := s='';
  cx:=1;
  IF NOT AnythingYet THEN
    Color(White,Red)
  ELSE
    Color(White,Blue);
  write(s);
  gotoxy(x,y);
  REPEAT
    ch:=GetKey;
    IF (NOT AnythingYet) AND (ch<>K_None) THEN
    BEGIN
      AnythingYet:=TRUE;
      Color(White,Blue);
      IF ch IN [#32..#127] THEN
      BEGIN
        s:='';
        clreol;
      END
      ELSE BEGIN
        write(s);
        gotoxy(x,y);
      END;
    END;
    CASE ch OF
      #8    : IF CX>1 THEN
              BEGIN
                dec(cx);
                delete(s,cx,1);
                gotoxy(x+cx-1,y);
                write(copy(s,cx,length(s)-cx+1),' ');
              END;
      K_INS : BEGIN
                InsertMode:=NOT InsertMode;
                UpdateCursor;
              END;
      K_LEFT: IF cx>1 THEN dec(cx);
      K_RIGHT: IF cx<=length(s) THEN inc(cx);
      K_HOME: cx:=1;
      K_END:  cx:=length(s)+1;
      K_DEL : IF cx<=length(s) THEN
              BEGIN
                delete(s,cx,1);
                write(copy(s,cx,length(s)-cx+1),' ');
              END;
    END;
    IF ch IN [#32..#127] THEN
    BEGIN
      IF InsertMode THEN
      BEGIN
        Insert(ch,s,cx);
        write(copy(s,cx,length(s)-cx+1));
      END
      ELSE IF cx<length(s) THEN
      BEGIN
        s[cx]:=ch;
        write(ch);
      END
      ELSE
      BEGIN
        s:=s+ch;
        write(ch);
      END;
      inc(cx);
    END;
    gotoxy(x+cx-1,y);
  UNTIL (ch=#13) OR (ch=#27);
  GetString:=ch=#13;
END;

PROCEDURE CopyFile(src,dst:string);
VAR
  f1,f2:file;
  BytesRead : Word;
  TBlocks : integer;
  BLeft : integer;
  i : integer;
  Stamp : LongInt;
BEGIN
  IF FExpand(src)=FExpand(dst) THEN
  BEGIN
    writeln(src,' already in correct place.');
    exit;
  END;
  writeln('Copying ',src,' to ',dst);
  assign(f1,src);
  assign(f2,dst);
  {$I-} reset(f1,1); {$I+}
  IF IOResult<>0 THEN
  BEGIN
    beep;
    TextColor(LightRed);
    writeln('ERROR: Could not open ',src,' for reading.');
    TextColor(White);
    exit;
  END;
  {$I-} rewrite(f2,1); {$I+}
  IF IOResult<>0 THEN
  BEGIN
    beep;
    TextColor(LightRed);
    writeln('ERROR: Could not open ',dst,' for writing.');
    TextColor(White);
    exit;
  END;
  TBlocks:=FileSize(f1) div sizeof(buffer) +1;
  BLeft:=TBlocks;
  write(dup('∞',TBlocks));
  gotoxy(1,wherey);
  REPEAT
    Blockread(f1,buffer,sizeof(buffer),bytesread);
    Blockwrite(f2,buffer,bytesread);
    write('€');
  UNTIL BytesRead<>Sizeof(Buffer);
  writeln;
  GetFTime(f1,stamp);
  close(f1);
  reset(f2);
  SetFTime(f2,stamp);
  close(f2);
  IF DoDelete THEN BEGIN
    system.erase(f1);
    writeln('Deleted ',src);
  END;
END;

PROCEDURE Abort;
BEGIN
  Color(LightGray,Black);
  Window(1,1,80,25);
  clrscr;
  TextColor(LightRed+Blink);
  writeln('Installation Aborted!');
  TextColor(LightGray);
  Cursor(On);
  halt;
END;

PROCEDURE Make(dir:string);
BEGIN
{$I-}
  mkdir(Dir);
  IF IOResult<>0
    THEN writeln(Dir,' already exists.')
    ELSE writeln(Dir,' created');
{$I+}
END;

PROCEDURE MakeTree(ToDir:string);
BEGIN
  Make(ToDir);
  Make(ToDir+'\CONFIG');
  Make(ToDir+'\DICT');
  Make(ToDir+'\DOC');
END;

FUNCTION CStr2Str(cs:cstring81):string;
VAR
  s:string;
  i:integer;
BEGIN
  i:=1;
  WHILE cs[i]<>#0 DO
  BEGIN
    s[i]:=cs[i];
    inc(i);
  END;
  s[0]:=chr(i-1);
  Cstr2str:=s;
END;

PROCEDURE Str2Cstr(s:string; VAR cs:cstring81);
BEGIN
  move(s[1],cs,length(s));
  cs[length(s)+1]:=#0;
END;

PROCEDURE SetupInit;
VAR
  cfg : ConfigFile;
  er  : EditorsFile;
  ed : editorrec;
  done:boolean;
  config : ConfigRec;
  DataDir:string;
  s:string;
BEGIN
  assign(cfg,WWIVDIR+'\CONFIG.DAT');
  reset(cfg);
  read(cfg,config);
  close(cfg);
  DataDir:=WWIVDir+'\'+Cstr2Str(Config.DataDir);
  {$I-} chdir(copy(datadir,1,length(datadir)-1)); {$I+}
  IF IOResult<>0 THEN DataDir:=cstr2str(Config.DataDir);
  chdir(Path);
  assign(er,DataDir+'EDITORS.DAT');
  {$I-} reset(er); {$I+}
  IF IOResult<>0 THEN rewrite(er);
  done:=false;
  WHILE NOT EOF(er) AND NOT Done DO
  BEGIN
    read(er,ed);
    done:=pos('WWIVEDIT',transformstring(cstr2str(ed.filename)))<>0;
  END;
  IF done THEN BEGIN
    TextColor(White);
    writeln('A WWIVEdit entry was found in the editors list.');
    write('Would you like to edit that entry or add a new one? [EA] ');
    REPEAT
      ch:=upcase(readkey);
    UNTIL ch IN ['E','A',#27];
    IF ch=#27 THEN abort;
    IF ch='E' THEN writeln('Edit') ELSE writeln('Add');
    writeln;
  END ELSE ch:='A';
  IF ch='A' THEN
  BEGIN
    fillchar(ed,sizeof(ed),#0);
    str2cstr('WWIVEdit -- Highly Recommended',ed.description);
    seek(er,FileSize(er));
  END ELSE seek(er,filepos(er)-1);
  str2cstr(ToDir+'\WWIVEDIT %1 %2 %3 %4',ed.filename);
  str2cstr(ToDir+'\WWIVEDIT %1 %2 %3 %4 -key:local -set:local',ed.filenamecon);
  writeln('Description to be displayed to users:');
  s:=cstr2str(ed.description);
  IF GetString(s) THEN str2cstr(s,ed.description);
  writeln; writeln;

  writeln('Command line to run REMOTELY');
  s:=cstr2str(ed.filename);
  IF GetString(s) THEN str2cstr(s,ed.filename);
  writeln; writeln;
  writeln('Command line to run LOCALLY');
  s:=cstr2str(ed.filenamecon);
  IF GetString(s) THEN str2cstr(s,ed.filenamecon);
  writeln; writeln;

  writeln('Description:');
  writeln('  ',cstr2str(ed.description));
  writeln('Remote command line:');
  writeln('  ',cstr2str(ed.filename));
  writeln('Local command line:');
  writeln('  ',cstr2str(ed.filenamecon));
  writeln;

  TextColor(Yellow);
  write('Save entry to disk? ');
  REPEAT
    ch:=upcase(readkey);
  UNTIL ch IN ['Y','N',#27];
  IF ch='Y'
    THEN writeln('Yes')
    ELSE writeln('No');
  writeln;
  IF ch='Y' THEN write(er,ed);
  close(er);
END;

FUNCTION Exists(s:string):boolean;
VAR
  t:text;
  ok:boolean;
BEGIN
{$I-}
  assign(t,s);
  reset(t);
  ok:=IOResult=0;
  IF ok THEN close(t);
{$I+}
  Exists:=ok;
END;

BEGIN
  OpenWindow(1,1,80,25,White,Blue,Yellow,Blue,Yellow,Blue,
              'µWWIVEdit '+Version+' Installation Program∆');
  {$I-}
  ok:=true;
  FOR i:=1 TO NeededFiles DO
  BEGIN
    assign(f,InstallDir+NeededList[i]);
    reset(f);
    IF IOResult<>0 THEN
    BEGIN
      ok:=FALSE;
      TextColor(LightRed);
      writeln('ERROR: Could not find ',NeededList[i]);
    END ELSE
      close(f);
  END;
  IF NOT Ok THEN
  BEGIN
    beep;
    TextColor(White);
    writeln;
    writeln('One or more files is missing from the distribution file.');
    writeln('All files should be present for installation to proceed.');
    writeln('If you did not recieve the complete archive, please get it before');
    writeln('attempting to install WWIVEdit.');
    writeln;
    TextColor(Yellow);
    write('Do you want to continue with installation? ');
    ch:=upcase(readkey);
    IF ch<>'Y' THEN abort;
    writeln('Yes');
    writeln;
  END;

  {$I+}

  GetDir(0,Path);
  WWIVDir:=copy(Path,1,3)+'WWIV';

  REPEAT
    writeln('Where is your BBS directory?');
    write('   ');
    IF NOT GetString(WWIVDir) THEN abort;
    WWIVDir:=TransformString(WWIVDir);
    writeln;
    {$I-} chdir(WWIVDir); {$I+}
    ok:=IOResult=0;
    chdir(Path);
    IF NOT Ok THEN
    BEGIN
      writeln(WWIVDir,' is not a valid directory.');
      beep;
    END;
    writeln;
  UNTIL ok;
  writeln('Where do you want to install WWIVEdit?');
  ToDir:=WWIVDir+'\WWIVEDIT';
  write('   ');
  IF NOT GetString(ToDir) THEN Abort;
  Todir:=TransformString(ToDir);
  writeln;
  IF Exists(ToDir+'\TAGLINES.CMN') THEN
  BEGIN
    writeln('The file '+ToDir+'\TAGLINES.CMN is no longer needed.');
    writeln('This version of WWIVEdit uses a newer file.');
    write('Would you like to convert this file now? ');
    REPEAT
      ch:=upcase(readkey);
    UNTIL ch IN ['Y','N',#27];
    IF ch='Y'
      THEN writeln('Yes')
      ELSE writeln('No');
    IF ch='Y' THEN Convert;
    writeln;
  END;
  write('Would you like me to delete each file as it is copied to save space? ');
  REPEAT
    ch:=upcase(readkey);
  UNTIL ch IN ['Y','N',#27];
  IF ch='Y'
    THEN writeln('Yes')
    ELSE writeln('No');
  dodelete:=ch='Y';
  writeln;
  PushCursor;
  Cursor(Off);
  writeln;
  writeln;
  MakeTree(ToDir);
  writeln;
  writeln;
  FOR i:=1 TO NumFiles DO
  BEGIN
    IF Keypressed THEN BEGIN
      ch:=readkey;
      IF ch=#27 THEN abort;
    END;
    CopyFile(InstallDir+FileList[i].sname,ToDir+'\'+FileList[i].dname);
  END;

  FOR i:=1 TO NumErase DO
    Erase(ToDir+'\'+EraseList[i]);

  Cursor(On);
  FOR i:=1 TO NumOptional DO
  BEGIN
    IF Exists(ToDir+'\'+OptionalList[i].dname) THEN
    BEGIN
      writeln('A previous version of ',OptionalList[i].sname,' was found.');
      write('Do you want to overwrite it? ');
      REPEAT
        ch:=upcase(readkey);
      UNTIL ch IN ['Y','N',#27];
      IF ch='Y'
        THEN writeln('Yes')
        ELSE writeln('No');
      writeln;
      IF ch='Y' THEN CopyFile(InstallDIr+OptionalList[i].sname,ToDir+'\'+OptionalList[i].dname);
    END ELSE CopyFile(InstallDir+OptionalList[i].sname,ToDir+'\'+OptionalList[i].dname);
  END;

  TextColor(Yellow);
  writeln;
  write('Would you like INSTALL to setup the WWIVEDIT command lines for you? ');

  REPEAT
    ch:=upcase(readkey);
  UNTIL ch IN ['Y','N',#27];
  IF ch='Y'
    THEN writeln('Yes')
    ELSE writeln('No');
  writeln;
  IF ch='Y' THEN SetupInit;

  Cursor(Off);
  clrscr;
  TextColor(White);
  writeln('Basic installation complete.');
  writeln('Please be sure to read all of the documentation included in');
  writeln('the directory ',ToDir+'\DOC');
  writeln;
  writeln('Also browse through the *.DEF files in ',ToDir,'\CONFIG');
  writeln('and verify the settings in them.  This is especially important if');
  writeln('you are not running WWIV 4.21a+.');
  writeln;
  writeln('And don''t forget to register!');
  writeln;
  writeln('Installation Complete!');
  TextColor(Yellow);
  write('Press any key to exit to DOS.');
  beep;
  ch:=readkey;
  PopCursor;
  Color(LightGray,Black);
  Window(1,1,80,25);
  clrscr;
  TextColor(LightGray);
  chdir(ToDir);
  writeln('WWIVEdit has been set up with the optimal settings for WWIV 4.21a+.');
  writeln('You will have to edit CONFIG\LOCAL.DEF and CONFIG\DEFAULT.DEF if you');
  writeln('are not running it.');
  writeln;
  writeln('To be safe, type:');
  writeln('WWIVEDIT -F');
  writeln('To force the .DEF abd .KEY files to be compiled.');
  writeln('This can be done at any time, however it is recommended that you');
  writeln('do it right now.');
  writeln;
  writeln('If you recieved a warning saying WWIVEDIT.DIC and HASH were missing');
  writeln('you need to get WEDICT.ZIP and unzip it into your DICT\ dir.');
  writeln;
END.

