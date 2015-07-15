UNIT WEUser;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

INTERFACE

USES WEVars;

TYPE
{ -- Programmer's Note on INFOREC --
  -- If you add anything to this, add it after the reserved bytes,
  -- and decrement the reserved bytes accordingly.  Future version of
  -- WWIVEdit will add new things before Reserved, and decrement the bytes
  -- accordingly... So to be the most compatible with future version,
  -- Add after the Reserved
  -- }
  InfoRec = RECORD
    UserName : string[20];
    TagLine  : ARRAY[1..3] OF String[80];
    Selected : Byte;  { Which was last attached }
    Method   : Byte;  { 0=No Tag Line, 1, 2, 3=Always use #1, #2, or #3,
                        4=Rotate, 5=Random, 6=Method=Selected on next use }
    ScreenState : Byte;
    ScreenHeight : Byte;
    InsertMode : Boolean;
    KeyFile  : String[8];
    AskReply : byte;
    ticks    : byte;
    AskTag   : Boolean;
    Reserved : ARRAY[1..119] OF byte;
  END;

  userrec = record
    name     : string[30];     { User's Handle   }
    realname : string[20];     { User's Real Name}
    sl       : byte;           { Security Level  }
  END;

VAR
  thisuser    : userrec;        { Contains all pertinent user info          }
  Info        : InfoRec;

CONST
  usernum   : integer = 0;                 { Current user's number   }
  infopos : word = 0;                      { Used for saving }
  EditInfoFlags : word = 0;


PROCEDURE SaveInfo;
PROCEDURE InitInfo;

IMPLEMENTATION

USES WEString;

TYPE
  InfoF = FILE of InfoRec;

VAR
  InfoFile : InfoF;

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

FUNCTION Hash2(VAR s:string):WORD;
VAR
  h:word;
  i,l:integer;
BEGIN
  h:=0;
  i:=1;
  l:=length(s);
  WHILE (i+1<=l) DO
  BEGIN
    h:=h XOR (ord(s[i+1]) shl 8) + ord(s[i]); { backwards from above }
    i:=i+2;
  END;
  IF i=l THEN h:=h XOR ord(s[i]);
  hash2:=h;
  IF h=0 THEN hash2:=1;
END;

PROCEDURE GetUserRec(s:string; h2:word);
TYPE
  Secondary = RECORD
    hashval : word; { secondary hash value of this record }
    next    : word; { next index in file for primary hash value }
    index   : word; { Index into USER.TAG }
  END;
  ind2 = FILE of Secondary;

VAR
  f:file OF LongInt;
  index2 : ind2;
  h1:WORD;
  i,l:word;
  p:longint;
  sh:Secondary;
  fi:file;
  ptr : pointer;

CONST size=$800*4;
BEGIN
  h1:=hash1(s);
  fillchar(info,sizeof(inforec),#0);
  fillchar(sh,sizeof(sh),#0);
  sh.hashval:=0; sh.next:=1;
  p:=0;
  assign(f,StartupDir+'INDEX1.TAG');
  assign(index2,StartupDir+'INDEX2.TAG');
  {$I-} reset(f); {$I+}
  IF IOResult<>0 THEN
  BEGIN
  { - for speed, use a big block and write it all at once }
    assign(fi,StartupDir+'INDEX1.TAG'); rewrite(fi,SIZE); getmem(ptr,SIZE);
    fillchar(ptr^,SIZE,#0);  blockwrite(fi,ptr^,1); close(fi); freemem(ptr,SIZE);
    reset(f);
    rewrite(index2);
    write(index2,sh);
    close(index2);
    rewrite(infofile);
    write(infofile,info);
    close(infofile);
  END;
  info.UserName:=thisuser.RealName;
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
  close(f);
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
  infopos:=sh.index;
  seek(infofile,infopos);
  read(infofile,info);
  close(infofile);
END;

FUNCTION CommandLine(s:string):string;
VAR
  i,j:integer;
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
      IF (length(res)>0) AND (res[1]='"') THEN
      BEGIN
        IF res[length(res)]<>'"' THEN
        BEGIN
          j:=i;
          WHILE (j+1<=ParamCount) DO
          BEGIN
            inc(j);
            res:=res+' '+ParamStr(j);
            IF pos('"',ParamStr(j))>0 THEN j:=ParamCount+1;
          END;
        END;
        res:=copy(res,2,length(res)-2);
      END;
    END;
  END;
  commandline:=res;
END;


PROCEDURE SaveInfo;
BEGIN
  IF setting.SetupType=0 THEN InfoPos:=0;
  reset(InfoFile);
  seek(InfoFile,InfoPos);
  write(InfoFile,Info);
  close(InfoFile);
END;

PROCEDURE InitInfo;
VAR
  i : integer;
  t : text;
BEGIN
  assign(infofile,StartupDir+'USER.TAG');
  CASE Setting.SetupType OF
    0 : BEGIN
          Title:=Filename;
          Destination:=StartupDir;
          usernum:=1;
          thisuser.name:='';
          thisuser.realname:='';
          thisuser.sl:=1;
        END;
    1 : BEGIN
          assign(t,ParameterFileName);
          {$I-} reset(t); {$I+}
          IF IOResult<>0 THEN BEGIN
            assign(t,StartupDir+ParameterFileName);
            {$I-} reset(t); {$I+}
          END;
          IF IOResult = 0 THEN BEGIN
            readln(t,usernum);
            readln(t,thisuser.name);
            readln(t,thisuser.realname);
            FOR i:=1 TO 7 DO
              readln(t);
            readln(t,thisuser.sl);
            readln(t); readln(t); readln(t);
            readln(t,i);
            incom  :=  (i = 1);
            IF InCom AND Setting.Local THEN
            BEGIN
              usernum:=1;
              thisuser.name:='';
              thisuser.realname:='';
              thisuser.sl:=255;
            END;
            close(t);
          END
          ELSE BEGIN
            writeln('Could not find CHAIN.TXT');
            writeln('Edit ',SettingName+DefExt,' to make WWIVEdit look for something else.');
            halt;
          END
        END;
    2 : BEGIN
          assign(t,'EDITOR.INF');
          {$I-} reset(t); {$I+}
          IF IOResult=0 THEN
          BEGIN
            readln(t,title);
            readln(t,Destination);
            readln(t,usernum);
            readln(t,thisuser.name);
            readln(t,thisuser.realname);
            readln(t,thisuser.sl);
            IF NOT EOF(t) THEN readln(t,EditInfoFlags);
            close(t);
            AllowTitleChange:=True;
          END
          ELSE BEGIN
            writeln('Could not find EDITOR.INF.');
            writeln('Edit ',ConfigDir+settingName+DefExt,
                    ' to make WWIVEdit look for something else.');
            halt;
          END
        END;
    3 : BEGIN
          thisuser.name:=CommandLine('H');
          thisuser.realname:=CommandLine('N');
          i:=pos('#',thisuser.name);
          usernum:=value(RightS(thisuser.name,length(thisuser.name)-i));
          delete(thisuser.name,i-1,length(thisuser.name)-i+2);
        END;
  END;
  IF Setting.SetupType>0 THEN
  BEGIN
    IF UserNum=0 THEN UserNum:=Hash2(thisuser.realname);
    GetUserRec(thisuser.realname,usernum);
  END ELSE BEGIN
    {$I-} reset(InfoFile); {$I+}
    IF IOResult=0 THEN BEGIN
      Read(InfoFile,Info);
      close(InfoFile);
    END;
  END
END;

END.
