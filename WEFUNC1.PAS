UNIT WEFUNC1;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{ -- Overlaid editing functions for WWIVEdit 2.4
  -- }

INTERFACE

PROCEDURE DoCenterLine(VAR cy:integer);
PROCEDURE ShowBlockStatus;
PROCEDURE DoDeleteBlock(startline,endline:integer);
PROCEDURE DoBlockCopy(VAR startline,endline:integer; toline:integer);
PROCEDURE DoBlockMove(VAR BlockStart,BlockEnd:integer; ToLine:integer);
PROCEDURE DoInsertFile;
PROCEDURE DoSaveAndContinue;
PROCEDURE DoJump;
FUNCTION Search(VAR cx,cy:integer; S,Ops:string):boolean;
PROCEDURE SearchLast;
PROCEDURE DoSearch;
PROCEDURE DoSearchAndReplace;
PROCEDURE DoToggleWhere;
PROCEDURE DoSaveBlock(BlockStart,BlockEnd:Integer);

IMPLEMENTATION
USES WEVars,WELine,WEFunc,WEInput,WEOutput,WEString,WEHelp,DOS,WEFile;

PROCEDURE DoCenterLine(VAR cy:integer);
{ Places the centering code at the beginning of the line }
VAR
  Space:LineType;
  ins : boolean;
BEGIN
  Ins:=InsertMode;
  InsertMode:=true;
  Space.l:='/C:';
  Space.c:='000';

  IF (Len(cy)>0) AND (Len(cy)<LineLen-3) THEN
    LInsert(Space,cy,1);

  cx:=1;
  IF cy<MaxLines THEN inc(cy);
  InsertMode:=ins;
END;


PROCEDURE ShowBlockStatus;
BEGIN
  StatusLine3('Block Begin Line '+cstr(BlockStart)+', Block Ending Line '+cstr(BlockEnd));
  AfterNext:=ClrStatLine3;
END;


PROCEDURE DoDeleteBlock(startline,endline:integer);
VAR
  i:integer;
BEGIN
  IF EndLine>=StartLine THEN
  FOR i:=0 TO endline-startline DO
    DeleteLine(Startline);
END;

PROCEDURE DoBlockCopy(VAR startline,endline:integer; toline:integer);
VAR
  x:integer;
  o : integer;
  i : integer;
BEGIN
  IF (ToLine+EndLine-StartLine<MaxLines) AND (startline>0) AND
     (startline<=endline) AND ((toline>endline) OR (toline<=startline)) THEN
  FOR i:=0 TO EndLine-StartLine DO
  BEGIN
    InsertLine(toline,Line^[i+StartLine]^);
    inc(toline);
  END;
END;

PROCEDURE DoBlockMove(VAR BlockStart,BlockEnd:integer; ToLine:integer);
VAR x:integer;
BEGIN
  x:=BlockStart;
  IF ToLine>BlockStart
    THEN x:=ToLine-BlockEnd+BlockStart-1
    ELSE x:=ToLine;
  DoBlockCopy(BlockStart,BlockEnd,ToLine);
  DoDeleteBlock(BlockStart,BlockEnd);
  BlockEnd:=x+BlockEnd-BlockStart;
  BlockStart:=x;
  ShowBlockStatus;
END;

FUNCTION SelectWildCard(select:string):PathStr;
VAR
  s : String;
  sr: SearchRec;
  count: integer;
  Files: StringArray;
  Which : integer;
  Dir : DirStr;
  Name: NameStr;
  Ext : ExtStr;
BEGIN
  Count:=0;
  FindFirst(select,0,sr);
  WHILE (DOSError=0) AND (Count<80) DO
  BEGIN
    inc(count);
    Files[Count]:=sr.Name;
    FindNext(sr);
  END;
  Which:=ChooseString(files,count,1,C5+'Choose a file to insert.');
  IF Which=-1 THEN SelectWildCard:=''
  ELSE BEGIN
    FSplit(select,Dir,Name,Ext);
    SelectWildCard:=Dir+Files[which];
  END;
END;

PROCEDURE DoInsertFile;
{ Prompt for a file name and then read it in at the end of the current
  Text Buffer }
VAR
  s : string;
  sr: SearchRec;
  l : LineType;
  x : integer;
  Dir : DirStr;
  Name: NameStr;
  Ext : ExtStr;
  p   : string;
BEGIN
  s:=setting.insertdir;
  IF s='' THEN
    GetDir(0,s);
  IF (s[length(s)]<>'\') AND (pos('*',s)=0) AND (pos('?',s)=0) THEN
    s:=s+'\';
  StringToLine(S,l);
  StatusLine3(C2+'File Name read in > '+C0);
  x:=wherex;
  write(s);
  IF LineEditor(l,x,wherey,Length(l.l)+1,65,False) THEN
  BEGIN
    LineToString(l,s);
    StatusLine3(C0);
    FindFirst(s,0,sr);
    IF DosError<>0 THEN
    BEGIN
      StatusLine3(c1+'File not found.');
      AfterNext:=ClrStatLine3;
      Exit;
    END
    ELSE BEGIN
      FindNext(sr);
      IF DosError=0 THEN BEGIN
        p:=SelectWildCard(s);
        ForcedRedisplay;
        StatusLine3('');
      END
      ELSE BEGIN
        FSplit(s,Dir,Name,Ext);
        p:=Dir+sr.Name;
      END;
      IF p<>'' THEN
        ReadInputFile(cy,p);
    END
  END;
  StatusLine3('');
END;



PROCEDURE DoSaveAndContinue;
VAR dummy:integer;
BEGIN
  dummy:=-1;
  WriteOutputFile(Filename,dummy,false);
END;

PROCEDURE DoJump;
{ Prompts for a line to jump to, and then changes cursor position accordingly }
VAR
  s:string;
  line:integer;
BEGIN
  StatusLine3(C2+'Jump to which line? > '+c4+'    '+#8#8#8#8);
  SimpleInput(s,4);
  line:=value(s);
  IF (line>0) AND (line<MaxLines) THEN
  BEGIN
    cy:=line;
    cx:=1;
    ViewTop:=cy;
    ViewBottom:=cy+WindowHeight;
    IF ViewBottom>MaxLines THEN BEGIN
      ViewBottom:=MaxLines;
      ViewTop:=ViewBottom-WindowHeight
    END;
  END;
  ansic('0');
  StatusLine3('');
END;

FUNCTION Search(VAR cx,cy:integer; S,Ops:string):boolean;
{ performs a search from the given coordinates }
VAR
  i:integer;
  found:boolean;
  l:string;
BEGIN
  IF pos('U',ops)>0 THEN S:=TransformString(S);
  Found:=false;
  i:=cy;
  WHILE NOT Found AND (i<MaxLines) Do
  BEGIN
    IF pos('U',ops)>0
      THEN l:=TransformString(Line^[i]^.l)
      ELSE l:=Line^[i]^.l;
    IF i=cy THEN FillChar(l[1],cx,#0);
    IF (pos(s,l)<>0) THEN
    BEGIN
      cx:=pos(s,l);
      cy:=i;
      Found:=true;
    END
    ELSE inc(i);
  END;
  Search:=Found;
END;

PROCEDURE SearchLast;
{ Repeats last Search }
BEGIN
  IF (Searchstring='') OR (NOT Search(cx,cy,SearchString,SearchOps)) THEN
  BEGIN
    StatusLine3('No match found');
    AfterNext:=ClrStatLine3;
  END;
END;


PROCEDURE DoSearch;
{ Prompts for something to search for, and then does the search }
VAR
  x:integer;
  l : LineType;
BEGIN
  StatusLine3(C2+'Search for > '+C0);
  x:=wherex;
  StringToLine(SearchString,l);
  write(SearchString);
  IF LineEditor(l,X,WhereY,Length(l.l)+1,60,FALSE) THEN
  BEGIN
    LineToString(l,SearchString);
    Ansic('0');
{  StatusLine3(C2+'Options > '+C4+'     '+#8#8#8#8#8);
    InputUp(SearchOps,5); }
    SearchOps:='U';
    ansic('0');
    StatusLine3('');
    IF NOT Search(cx,cy,SearchString,SearchOps) THEN BEGIN
      StatusLine3('No match found');
      AfterNext:=ClrStatLine3;
    END;
  END ELSE StatusLine3('');
END;

PROCEDURE DoSearchAndReplace;
{ Prompts for something to search for, something to replace and then does it }
VAR
  x:integer;
  l : LineType;
  ch: char;
  Done : boolean;
  i : integer;
BEGIN
  StatusLine3(C2+'Search for > '+C0);
  x:=wherex;
  StringToLine(SearchString,l);
  write(SearchString);
  IF LineEditor(l,X,WhereY,Length(l.l)+1,60,FALSE) THEN
  BEGIN
    LineToString(l,SearchString);
    Ansic('0');
    SearchOps:='U';
    ansic('0');
    StatusLine3('');
    ch:=' ';
    StatusLine3(C2+'Replace with > '+C0);
    x:=wherex;
    write(ReplaceString);
    StringToLine(ReplaceString,l);
    IF LineEditor(l,X,WhereY,Length(l.l)+1,60,TRUE) THEN
    REPEAT
      LineToString(l,ReplaceString);
      IF ch=' ' THEN dec(cx);
      Done:=NOT Search(cx,cy,SearchString,SearchOps);
      IF Done THEN
      BEGIN
        IF ch=' ' THEN BEGIN
          inc(cx);
          StatusLine3(C0+'No match found');
          AfterNext:=ClrStatLine3;
        END
        ELSE StatusLine3(C0);
      END ELSE
      BEGIN
        IF ch<>'A' THEN
        BEGIN
          StatusLine3(C2+'Replace'+C6+'?'+c2+' [YNAQ] ');
          ResetViewPort;
          Redisplay;
          ch:=readset1(['Y','N','A','Q',#27]);
        END;
        CASE ch OF
          'Y','A' : BEGIN
                      FOR i:=1 TO Length(SearchString) DO
                        doFun(DelChar,' ');
                      FOR i:=1 TO Length(l.l) DO
                      BEGIN
                        CurrentColor:=l.c[i];
                        doFun(InsertChar,l.l[i]);
                      END;
                    END;
          'Q',#27 : Done:=TRUE;
        END;
        StatusLine3('');
      END;
    UNTIL Done
    ELSE StatusLine3('');
  END ELSE StatusLine3('');
END;

PROCEDURE DoToggleWhere;
{ Installs/uninstalls The ShowWhere procedure into the BeforeNext procedure }
BEGIN
  IF @BeforeNext=@DoNothing THEN
  BEGIN
    BeforeNext:=ShowWhere;
    lx:=-1;
  END
  ELSE BEGIN
    BeforeNext:=DoNothing;
    StatusLine3(C0);
  END;
END;

PROCEDURE DoSaveBlock(BlockStart,BlockEnd:Integer);
VAR
  t:text;
  l:linetype;
  done,alreadythere : boolean;
  s:string;
  x:integer;
  ch:char;
BEGIN
  GetDir(0,s);
  s:=s+'\';
  REPEAT
    Done:=true;
    StatusLine3(C2+'Save as: '+C0);
    StringToLine(S,l);
    x:=wherex;
    write(s);
    IF LineEditor(l,x,wherey,Length(l.l)+1,65,False) THEN
    BEGIN
      LineToString(l,s);
      assign(t,s);
      {$I-}
      reset(t);
      AlreadyThere:=IOResult=0;
      IF AlreadyThere THEN close(t);
      IF AlreadyThere THEN BEGIN
        StatusLine3(C2+'File already exists, Overwrite, Append, New name, or Quit? ');
        ch:=readset(['O','A','N','Q']);
        IF ch='N' THEN Done:=False;
      END;
    END ELSE BEGIN StatusLine3(C0); exit; END;
  UNTIL Done;
  StatusLine3(C0);
  IF AlreadyThere THEN
  BEGIN
    IF ch='O' THEN rewrite(t)
    ELSE IF ch='A' THEN append(t)
    ELSE exit;
  END
  ELSE rewrite(t);
  SaveLines(t,BlockStart,BlockEnd);
  close(t);
END;

END.