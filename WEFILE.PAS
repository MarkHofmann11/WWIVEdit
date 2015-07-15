UNIT WEFile;
{$I WEGLOBAL.PAS}
{ -- File handler for WWIVEdit 2.4
  -- Handles saving and loading of files
  -- }

INTERFACE
PROCEDURE WriteOutputFile(Filename:string; VAR ReturnCode:integer; Quiet:boolean);
PROCEDURE ReadInputFile(StartLine:integer; FileName:String);
PROCEDURE SaveLines(VAR t:text; x1,x2:integer);
PROCEDURE EraseF(filename:string);
FUNCTION Exists(s:string):boolean;

IMPLEMENTATION

USES DOS,WEVars,WEString,WEOutput,WEInput,WELine,WEKbd,WETag,WEUser,WEMemory;

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

PROCEDURE EraseF(filename:string);
VAR
  t:text;
BEGIN
  assign(t,filename);
  {$I-} erase(t); {$I+}
  IF IOResult<>0 THEN ;
END;

FUNCTION CheckDest(filename:string;typ:integer):boolean;
VAR
  t:text;
  s:string;
  ok :boolean;
BEGIN
  ok:=TRUE;
  IF FileName<>'' THEN
  BEGIN
    Assign(t,StartUpDir+filename);
    {$I-} reset(t); {$I+}
    IF IOResult=0 THEN
    BEGIN
      WHILE (NOT EOF(t)) AND OK DO
      BEGIN
        Readln(t,s);
        IF s[1]='"' THEN BEGIN
          Delete(s,1,1);
          Delete(s,length(s),1)
        END;
        IF pos(s,Destination)>0 THEN ok:=FALSE;
      END;
      close(t);
    END;
  END;
  IF ((EditInfoFlags AND 1)>0) AND (Setting.BoardEditDisable<>Typ) THEN
    Ok:=FALSE;
  IF Ok AND (Setting.BoardEditDisable<>Typ) THEN { Something for WWIV 4.21a }
  BEGIN
    assign(t,'DISABLE.TAG');
    {$I-} reset(t); {$I+}
    IF IOResult=0 THEN
    BEGIN
      ok:=false;
      close(t);
    END;
  END;
  CheckDest:=OK;
END;

PROCEDURE SaveLines(VAR t:text; x1,x2:integer);
{ Save lines X1 to X2 to the given text file }
VAR
  s:string;
  i,j:integer;
BEGIN
  FOR i:=x1 TO x2 DO
  BEGIN
    s:=TransformString(Line^[i]^.l);
    IF NOT ((length(s)>0) AND (length(s)<10) AND (s[1]='\') AND ((s[2]='S') OR (s[3]='S'))) THEN
    BEGIN
      LineToString(Line^[i]^,s);
      write(t,s);
      j:=length(s);
      WHILE (j>0) AND (s[j]<>^C) DO
        dec(j);
      IF (j>0) AND (s[j+1]<>'0') THEN
        write(t,C0);
      IF Line^[i]^.hardCR
        THEN writeln(t)
        ELSE BEGIN
          IF Setting.BBS IN [BBS_WWIV, BBS_Eclipse] THEN
            writeln(t,^A)
          ELSE IF Setting.BBS IN [BBS_Telegard] THEN
            write(t,chr(141))
          ELSE writeln(t);
        END
    END;
  END;
END;


PROCEDURE WriteOutputFile(Filename:string; VAR ReturnCode:integer; Quiet:boolean);
{ Writes output file... could use some color optimizations }
VAR
  t, t1:text;
  l,x,i:integer;
  ch:char;
  ccol : integer;
  curcolor : char;
  plural:string[1];
  ignore : integer;
  s,s1:string;
  BBSTag:Text;
  dummy : integer;
  sr : SearchRec;
  Nfound : integer;
  UserTagLine : String;
BEGIN
  dummy:=returncode;
  nfound :=0;
  assign(t,Filename);
  l:=MaxLines;
  WHILE (l>0) AND (StripEndS(Line^[l]^.l)='') DO
    dec(l);
  s:=TransformString(Line^[l]^.L);
  IF (length(s)>2) AND cmpleft(s,'/ES') THEN
     Delete(s,2,1);  { Remove the E }
  IF s='/SN' THEN ReturnCode := NonAnonymousReturnCode
  ELSE IF s='/SY' THEN ReturnCode := AnonymousReturnCode
  ELSE ReturnCode:=NormalReturnCode;
  IF cmpLeft(s,'/S') THEN dec(l);
  IF l>1
    THEN plural:='s'
    ELSE plural:='';
  IF l>0 THEN
  BEGIN
    nl;
    s:=C7+'Saving '+C1+cstr(l)+C7+' line'+plural+'... '+C0;
    IF NOT Quiet THEN
      IF (dummy=0)
        THEN write(s)
        ELSE StatusLine3(s);
    clreol;
    CurColor:='0';
    ignore:=0;
    rewrite(t);
    SaveLines(t,1,l);

    UserTagline:=GetUserTagLine;
    IF (UserTagline<>'') AND (NOT Setting.DisableUserTag) AND (NOT FileThere)
       AND (ReturnCode <> AnonymousReturnCode)
       AND  CheckDest(Setting.NoTagPersonal,1) THEN
    BEGIN
      IF NOT Quiet THEN
        write(C2+'Writing Personal Tag Line... '+C0);
      FindFirst(StartupDir+Setting.Divider,0,sr);
      IF Setting.BBS IN [BBS_WWIV,BBS_Eclipse] THEN
        write(t,^D+'9');
      IF (DOSError<>0) OR (Setting.Divider='') THEN
        writeln(t,'-----')
      ELSE BEGIN
        assign(t1,StartUpDir+Setting.Divider);
        reset(t1);
        readln(t1,s);
        writeln(t,s);
        close(t1);
      END;
      IF Setting.BBS IN [BBS_WWIV,BBS_Eclipse] THEN
        write(t,^D+'9');
      ccol:=1;
      WHILE ccol<length(UserTagLine)-3 DO
      BEGIN
        IF copy(TransformString(UserTagLine),ccol,3)='/C:' THEN
        BEGIN
          delete(UserTagLine,ccol,3);
          insert(^B,UserTagLine,ccol);
        END;
        inc(ccol);
      END;
      ccol:=1;
      FOR i:=1 TO Length(UserTagLine) DO
      WITH info DO
      BEGIN
        IF UserTagLine[i]=^M THEN
        BEGIN
          writeln(t);
          IF (i<>length(UserTagLine)) AND
            (Setting.BBS IN [BBS_WWIV,BBS_Eclipse]) THEN
            write(t,^D+'9');
          ccol:=1;
        END
        ELSE IF UserTagLine[i]=^N THEN
        BEGIN
          write(t,^H);
          dec(ccol)
        END
        ELSE IF UserTagLine[i] IN [^P,^C] THEN
        BEGIN
          write(t,^C);
          CurColor:=UserTagLine[i+1];
          dec(ccol,1);
        END ELSE IF UserTagLine[i] IN [^B,#32..#255]-[#127] THEN
        BEGIN
          write(t,UserTagLine[i]);
          inc(ccol)
        END
      END;
      IF ccol<>1 THEN writeln(t);
    END;
    IF (NOT Setting.DisableBBSTag) AND
       (NOT FileThere) AND
       CheckDest(Setting.NoTagBBS,2) THEN
    BEGIN
      findfirst(StartupDir+'BBS*.TAG', 0, sr);
      WHILE DOSError=0 DO
      BEGIN
        inc(nfound);
        FindNext(sr);
      END;
      IF nfound>0 THEN
      BEGIN
        nfound:=random(nfound);
        IF NOT Quiet THEN
          write(c5+'Writing BBS tagline... '+c0);
        findfirst(StartupDir+'BBS*.TAG', 0, sr);
        WHILE nfound>0 DO
        BEGIN
          dec(nfound);
          FindNext(sr);
        END;
        writeln(t);
        assign(bbstag,StartupDir+sr.name);
        reset(bbstag);
        x:=8;
        WHILE not EOF(bbsTag) DO
        BEGIN
          readln(bbsTag,s);
          IF Setting.BBS IN [BBS_WWIV,BBS_Eclipse] THEN
          BEGIN
            write(t,^D+chr(x+ord('0')));
            dec(x);
            if (x<1) THEN x:=1;
          END;
          writeln(t,s)
        END;
        close(bbstag);
      END;
    END;
    close(t);
  END;
  IF dummy<>0 THEN statusline3(C0);
  IF (l=0) AND FileThere THEN BEGIN
    nl;
    clreol;
    writeln(c2+'File erased'+C0);
    erase(t);
  END
  ELSE IF l=0 THEN
  BEGIN
    nl;
    clreol;
    writeln(c0+'Aborted');
  END;
END;


FUNCTION FSize(s:string):LongInt;
VAR
  f:file of byte;
BEGIN
  assign(f,s);
{$I-} reset(f); {$I+}
  IF IOResult<>0 THEN Fsize:=0
  ELSE BEGIN
    FSize:=FileSize(f);
    close(f);
  END;
END;

PROCEDURE ReadInputFile(StartLine:Integer; FileName:String);
{ Reads in an input file at the given line number
  Assumes that the filename is valid... if not, aborts program }
VAR t:text;
  ccol:integer;
  ch:char;
  i:integer;
  CurColor:char;
  s:string;
  f:file of byte;
  BytesRead:LongInt;
  Step : LongInt;
  printed,Line : integer;
  l : LineType;
  b:boolean;
BEGIN
  assign(t,Filename);
  {$I-} reset(t); {$I+}
  i:=ioresult;
  IF i=3 THEN BEGIN
    writeln(Filename,' is not a valid filename, Check the command line!');
    MemCleanup;
    ErrorLevel:=1;
    halt(ErrorLevel);
  END
  ELSE IF i=5 THEN BEGIN
    writeln('Unable to read from "',Filename,'".');
    writeln('Access was denied by DOS.  Check your command line to make');
    writeln('sure %1 is the first parameter.');
    MemCleanup;
    ErrorLevel:=1;
    halt(ErrorLevel);
  END ELSE IF I<>0 THEN exit;
  Line:=StartLine;
  BytesRead:=0; CurColor:='0'; ccol:=1;  Printed:=0;
  Step := FSize(FileName) DIV 20;
  IF Step>0 THEN
  BEGIN
    write(C2+'Loading File '+C3+': '+C0+dup('°',20));
    MoveLeft(20);
  END;
  ansic('1');
  WHILE (NOT EOF(t)) AND (HighLine<MaxLines-2) DO
  BEGIN
    Drain;
    readln(t,s);
    BytesRead:=BytesRead+Length(s)+1;
    IF Step<>0 THEN
    WHILE BytesRead DIV Step >= Printed DO
    BEGIN
      write('Û');
      inc(Printed);
    END;
    s:=StringToLine(s,l);
    WHILE s<>'' DO        { Just in case of a *really* long line }
    BEGIN
      b:=l.HardCR;
      l.HardCR:=FALSE;
      InsertLine(line,l);
      s:=StringToLine(s,l);
      l.HardCR:=b;
      inc(line);
    END;
    InsertLine(line,l);
    inc(line);
  END;
  close(t);
  ansic('0');
END;

END.
