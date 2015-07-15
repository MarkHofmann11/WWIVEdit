UNIT WEInput;
{$I WEGLOBAL.PAS}
{ -- This is the Input Module of WWIVEdit 2.3
  -- Last Modified: 4/15/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is limited Public Domain (see WWIVEDIT.PAS for more details)
  --
  -- Purpose : Encapsulate as much of the input as possible
  --
  -- Known Errors : None
  --
  -- Planned Enhancements : None
  -- }
INTERFACE

USES DOS,WEVars;

VAR
  actual:boolean; {Very hacky way of doing something}
FUNCTION GetKey(QuickTimeout:BOOLEAN):char;
FUNCTION GetControlLine:String;
FUNCTION ReadSet(s:charset):char;
FUNCTION ReadSet1(s:charset):char;
FUNCTION GetArrow : Edfun;
FUNCTION GetFun(VAR s:string; VAR F:edfun; VAR any:boolean):boolean;
FUNCTION Yn : boolean;
PROCEDURE SimpleInput(VAR s:string;{ Allows user to input a string of         }
               maxlength:integer); { MaxLength Characters                     }
FUNCTION CheckAbort:boolean;       { Returns True if SPACE is pressed, will   }
                                   { pause if P or Ctrl-S is pressed          }

PROCEDURE WWIVEditMacro(ch:char);


FUNCTION LineEditor(VAR l:Linetype;
                        x,y,cx,maxlen:integer;
                        AllowColorChange:boolean):boolean;
PROCEDURE pausescr;

IMPLEMENTATION

USES WETime, WEKbd, WEOutput, WEDos, WEString, WELine, WEChat, WEFunc,
     WEMemory, WEMouse,WEEsm;

FUNCTION CheckAbort:Boolean;
VAR
  cc:char;
BEGIN
  IF KeyPressed THEN
  BEGIN
    cc:=upcase(ReadKey);
    IF (cc = 'P') OR (cc = ^S) THEN
    BEGIN
      cc  :=  readkey;
      cc  :=  #0;
    END;
    CheckAbort:=(CC=' ');
  END
  ELSE CheckAbort:=FALSE;
END;



PROCEDURE SimpleInput(VAR s : string; maxlength : integer);
VAR
  ch : char;

BEGIN
  s:='';
  REPEAT
    REPEAT
      LocationOverride:=FALSE;
      ch := GetKey(False);
    UNTIL NOT LocationOverride;
    IF (ch IN [#32..#255]-[#127]) AND (length(s)<=maxlength) THEN
    BEGIN
      s:=s+ch;
      write(ch);
    END
    ELSE
    CASE ch OF
      #8,#127 : IF Length(s)>0 THEN
                BEGIN
                  write(#8#32#8);
                  delete(s,length(s),1);
                END;
      ^X, ^U  : WHILE s<>'' DO
                BEGIN
                  write(#8#32#8);
                  delete(s,length(s),1);
                END;
    END;
 UNTIL (ch = #13);
 nl;
END;


FUNCTION GetFun(VAR s:string; VAR F:edfun; VAR any:boolean):boolean;
VAR
  i:integer;
  c : integer;
  l : integer;
  p : integer;
BEGIN
  c:=0;
  any:=false;
  l:=length(s);
  p:=1;
  f:=None;
  FOR i:=1 to NBindings DO
  BEGIN
    IF s = copy(KeyBindingP(@KeyBindings^[p])^.keys,1,l) THEN
    BEGIN
      inc(c);
      any:=true;
      IF l = Length(KeyBindingP(@KeyBindings^[p])^.keys) THEN
      BEGIN
        F:=KeyBindingP(@KeyBindings^[p])^.Fun;
      END
    END;
    p:=p+sizeof(EdFun)+Length(KeyBindingP(@KeyBindings^[p])^.keys)+1;
  END;
  IF Setting.mouse AND MouseInstalled AND LocationOverride THEN BEGIN
    Any:=TRUE;
    F:=Mouse;
    c:=1;
  END;
  IF (any=FALSE) AND (l=1) THEN BEGIN
    F:=InsertChar;
    GetFun:=True;
  END
  ELSE IF (c=1) THEN GetFun:=True
  ELSE GetFun:=False;
END;



procedure release_timeslice;
var regs : registers;
begin
     Inline(
                               {      ; DESQview PAUSE function}
        $53                  {      PUSH BX}
        /$BB/$00/$10    {      MOV BX,$1000}
        /$50                   {      PUSH AX}
        /$B8/$1A/$10           {      MOV AX,$101A}
        /$CD/$15               {      INT $15}
        /$89/$D8               {      MOV AX,BX}
        /$CD/$15               {      INT $15}
        /$B8/$25/$10           {      MOV AX,$1025}
        /$CD/$15               {      INT $15}
        /$58                   {      POP AX}
        /$5B                   {      POP BX}
      );
    regs.ax:=$1680;
    intr($2f,regs);
    {intr($f4,regs);}
    intr($28,regs);
end;




FUNCTION GetKey(QuickTimeout:boolean):CHAR;
VAR
  warned : boolean;
  ch : char;
  Ticks : integer;
  Mouse,count,x,y : word;

BEGIN
  IF NOT QuickTimeout THEN BeforeNext;
  Ticks:=0;
  mouse:=0;
  actual:=true;
  LastKey := timer;
  Warned:=false;
  count:=0;
  IF NOT KeyPressed THEN
  REPEAT
    inc(ticks);
release_timeslice;  { Added by Mark Hofmann for multi-tasking aware } 
    IF (Setting.ChatMask<>0) AND
       ((KeyStatusFlag AND Setting.ChatMask)=Setting.ChatMask) THEN
    BEGIN
      Chat(LineLen,ScreenHeight);
      LastKey:=Timer;
      Warned:=False;
    END;
    IF (Setting.DosMask<>0) AND
       ((KeyStatusFlag AND Setting.DosMask)=Setting.DOSMask) THEN
      JumpDos;
    IF LastKey>Timer THEN LastKey:=0;     {Special case for midnight       }
    IF (Not warned) AND (setting.warntime>0) AND (Timer-Lastkey>Setting.WarnTime) THEN
    BEGIN
      warned := TRUE;
      write(#7#7#7);
    END;
    IF Setting.Mouse AND MouseInstalled THEN Mouse:=MousePress(0,count,x,y);
  UNTIL (KeyPressed) OR
        (QuickTimeout AND (Ticks>ESC_ticks)) OR
        (count<>0) OR (Mouse<>0) OR
        (Setting.DisconnectTime>0) AND (Timer-Lastkey>Setting.DisconnectTime);
  IF (count>0) OR (Mouse<>0) THEN BEGIN
    IF (Mouse=1) AND (count=0) THEN
      Mouse:=MousePosition(X,Y);
      LocationOverride:=TRUE;
      LocationOverride_X:=x;
      LocationOverride_Y:=y;
      GetKey:=screenbuff(Display^)[y][x].c;
  END
  ELSE IF KeyPressed THEN
    GetKey:=ReadKey
  ELSE IF QuickTimeout THEN
  BEGIN  
    GetKey:=#0;
    actual:=false;
  END
  ELSE BEGIN
    clrscr;
    XWriteln(55);
    MemCleanup;
    Halt
  END;
  IF NOT QuickTimeout THEN AfterNext;
END;

FUNCTION GetControlLine:String;
{ Allows user to input a line, and shows all "control" characters as inverted }
VAR
  s:string;
  ch:char;
BEGIN
  s:='';
  StatusLine2(C0);
  REPEAT
    ch:=GetKey(false);
    IF not (ch in [^H,^Z]) THEN
    BEGIN
      s:=s+ch;
      IF ch<#32
        THEN WriteControl(ch)
        ELSE write(ch);
    END
    ELSE IF (length(s)>0) AND (ch=^H) THEN
    BEGIN
      delete(s,length(s),1);
      write(#8#32#8);
    END;
  UNTIL (ch=^Z) OR (length(s)=80);
  GetControlLine:=s;
END;

FUNCTION ReadSet(s:charset):char;
{ Waits for a key from user, until user presses a key in the set S }
VAR
  ch:char;
BEGIN
  ch:=ReadSet1(s);
  IF ch IN [#32..#127] THEN write(ch);
  ReadSet:=ch;
END;

FUNCTION ReadSet1(s:charset):char;
{ Waits for a key from user, until user presses a key in the set S }
VAR
  ch:char;
  Mouse,count,x,y:word;
BEGIN
  REPEAT
    ch:=upcase(GetKey(false));
    IF LocationOverride THEN
    BEGIN
      REPEAT
        LocationOverride:=False;
        Mouse:=MouseRelease(0,count,x,y);
      UNTIL Count>0;
      ch:=upcase(Screenbuff(Display^)[y][x].c)
    END;
  UNTIL Ch IN s;
  ReadSet1:=ch;
END;

FUNCTION GetArrow:EdFun;
VAR
  s:string;
  ch:char;
  Fun : Edfun;
  any,done:boolean;
BEGIN
  REPEAT
    s:='';
    REPEAT
      IF (length(s)>0) AND (pos(s[1],Escaped)>0) THEN
      BEGIN
        ch:=GetKey(TRUE);
        IF (Actual) then s:=s+ch;
        Done:=GetFun(s,fun,any) OR ((NOT Actual) AND (Fun<>None));
      END ELSE BEGIN
        ch:=GetKey(FALSE);
        s:=s+ch;
        Done := GetFun(s,fun,any);
      END;
      IF (Not Any) THEN    s:=''
    UNTIL Done;
    s:='';
  UNTIL (NOT (Fun IN [InsertChar,None])) OR NOT Any AND ((ch='Q') or (ch='q'));
  GetArrow:=Fun;
END;


FUNCTION yn : boolean;
VAR c : char;
BEGIN
  ansic('1');
  c:=ReadSet(['Y','N',#13]);
  IF (c = 'Y') OR (c=#13) THEN
  BEGIN
    IF c='Y' THEN writeln('es') ELSE writeln('Yes');
    yn  :=  true;
  END ELSE
  BEGIN
    writeln('o');
    yn  :=  false;
  END;
END;

PROCEDURE pausescr;
VAR
  ch:char;
  mouse,count,x,y:word;
BEGIN
  write(C3+PausePrompt);
  MoveLeft(lengthw(PausePrompt));
  ch:=GetKey(False);
  IF LocationOverride THEN
  REPEAT
    LocationOverride:=False;
    Mouse:=MouseRelease(0,count,x,y);
  UNTIL Count>0;
  clreol;
END;


PROCEDURE WWIVEditMacro(ch:char);
VAR
  s,s1:string;
  r:ExtTrans;
  t,t1:text;
  i:integer;
BEGIN
  reset(transtable);
  seek(transtable,ord(ch));
  read(transtable,r);
  close(transtable);
  s:='';
  IF r[1]<>#0 THEN
  BEGIN
    s:=s+r[1]+r[2]+r[3];
    IF r[2]=#0 THEN s[0]:=#1
    ELSE if r[3]=#0 THEN s[0]:=#2;
  END;
  IF s<>'' THEN
  BEGIN
    assign(t,StartupDir+'MACROS.LCL');
    reset(t);
    WHILE (NOT EOF(t)) AND (s1<>s+':') AND (s1<>s+';') AND (s1<>s+'"') DO
      readln(t,s1);
    IF s1=s+';' THEN
    BEGIN
      IF InitSwap THEN
      BEGIN
        assign(t1,'TEMP$$$$.BAT');
        rewrite(t1);
        readln(t,s1);
        WHILE s1<>':'+s DO
        BEGIN
          writeln(t1,s1);
          readln(t,s1);
        END;
        close(t1);
        Execute('TEMP$$$$.BAT');
        erase(t1);
        EndSwap;
      END;
    END
    ELSE IF s1=s+':' THEN
    REPEAT
      readln(t,s1);
      IF (length(s1)>0) AND (s1[1]=^B) THEN BEGIN
        s1[1]:='/';
        system.insert('C:',s1,2)
      END;
      IF (length(s1)>0) AND (s1[1]='~') THEN
        system.delete(s1,1,1);
      IF s1[length(s1)]<>'~'
        THEN s1:=s1+^M
        ELSE system.delete(s1,length(s1),1);
      FOR i:=1 TO length(s1) DO
        CASE s1[i] OF
          ^C : s1[i]:=^P;
          ^H : s1[i]:=^N;
        END;
      IF s1<>':'+s+^M THEN StuffIn(s1);
    UNTIL s1=':'+s+^M
    ELSE IF s1=s+'"' THEN
    REPEAT
      readln(t,s1);
      IF (length(s1)>0) AND (s1[1]='~') THEN
        system.delete(s1,1,1);
      IF s1[length(s1)]<>'~'
        THEN s1:=s1+^M
        ELSE system.delete(s1,length(s1),1);
      IF s1<>':'+s+^M THEN
      FOR i:=1 TO length(s1) DO
        IF s1[i]<>^M THEN
          DoFun(InsertChar,s1[i])
        ELSE
          DoFun(Enter,^M);
      IF NOT Keypressed THEN redisplay;
    UNTIL s1=':'+s+^M;
    close(t);
  END;
END;

FUNCTION LineEditor(VAR l:Linetype;
                    x,y,cx,maxlen:integer;
                    AllowColorChange:boolean):boolean;
VAR
  s:string;
  ch:char;
  fun : edfun;
  done, any : boolean;
  tmp : LineType;
  shorter : boolean;
  i,p : integer;
  cc  : char;
  scc : char;
BEGIN
  scc:=currentcolor;
  tmp:=l;
  cc:='0';
  ansic(cc);
  CurrentColor:=cc;
  REPEAT
    IF (tmp.l<>l.l) OR (tmp.c<>l.c) THEN
    BEGIN
      shorter:=length(l.l)<length(tmp.l);
      p:=FirstDiff(tmp,l);
      FOR i:=p TO length(l.l) DO
        IF (i>length(tmp.l)) OR (l.c[i]<>tmp.c[i]) OR (l.l[i]<>tmp.l[i]) THEN
        BEGIN
          IF wherex<>x+i-1 THEN gotoxy(x+i-1,y);
          IF l.c[i]<>cc THEN BEGIN
            cc:=l.c[i];
            ansic(cc);
          END;
          write(l.l[i]);
        END;
      IF shorter THEN BEGIN
        gotoxy(x+length(l.l),y);
        ansic('0');
        clreol;
        ansic(cc);
      END;
    END;
    IF cc<>CurrentColor THEN Ansic(CurrentColor);
    cc:=CurrentColor;
    tmp:=l;
    gotoxy(x+cx-1,y);
    s:='';
    REPEAT
      IF (length(s)>0) AND (pos(s[1],Escaped)>0) THEN
      BEGIN
        ch:=GetKey(TRUE);
        IF (Actual) then s:=s+ch;
        Done:=GetFun(s,fun,any) OR ((NOT Actual) AND (Fun<>None));
      END ELSE BEGIN
        ch:=GetKey(FALSE);
        s:=s+ch;
        Done := GetFun(s,fun,any);
      END;
      IF (Not Any) THEN
      BEGIN
        IF (s[1]=#0) AND Setting.WWIVEditMacrosOk
          THEN WWIVEditMacro(s[2]);
        s:=''
      END
    UNTIL Done;
    s:='';
    LineEdit(l,fun,ch,MaxLen,cx,AllowColorChange);
  UNTIL fun IN [Enter,AbortPost,NormalExit];
  currentcolor:=scc;
  ansic(scc);
  LineEditor:=fun=Enter; { Return True if Enter exited }
END;


END.
