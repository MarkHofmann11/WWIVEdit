UNIT WEDictN;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{V-}
{ -- Dictionary module for WWIVEdit 2.4
  -- Written by:
  --   Adam Caldwell
  --
  -- This code is Copyright (c) 1991 Adam Caldwell
  --
  -- This code may be freely distributed so long as no fee is charged
  -- for it.
  -- }

INTERFACE
CONST
  MAX_Size = 1 shl 12;
  And_With = MAX_SIZE-1;
  MAX_Suggestions = 100;

TYPE
  TableType = ARRAY[0..And_With] OF LongInt;
  SuggArray = ARRAY[1..MAX_Suggestions] OF string[35];


PROCEDURE SpellCheck;
PROCEDURE MakeSuggestions(VAR Table:TableType; VAR s:string; VAR Suggestions:SuggArray);
PROCEDURE OpenDictionary(VAR Table:TableType);
FUNCTION  LookUp(VAR Table:TableType; s:string):boolean;

IMPLEMENTATION

USES WEComp, WEVars, WEString, WELine, WEKbd, WEInput, WEOutput,
     WEUser, WEMemory,WEEsm;

CONST
  MAXRoots = 10;
  BufSize = 384;
  Vowels = ['a','e','i','o','u'];

  try : ARRAY['a'..'z'] OF string[7] = (
     {a} 'eiousy',    {b} 'nv',       {c} 'xsvk',        {d} 'sfe',
     {e} 'aiouwry',   {f} 'dgpt',     {g} 'fh',          {h} 'gj',
     {i} 'aeoujyl',   {j} 'hki',      {k} 'jlc',         {l} 'ko',
     {m} 'n',         {n} 'bm',       {o} 'aeiup',       {p} 'olf',
     {q} 'asw',       {r} 'edst',     {s} 'adzce',       {t} 'ry',
     {u} 'ioaey',     {v} 'cb',       {w} 'qasde',       {x} 'czasd',
     {y} 'tugi',      {z} 'asxc');

TYPE
  WordRec = RECORD
    Flag : WORD;
    s: String[15];
  END;

VAR
  Buffer : ARRAY[0..BufSize] OF Byte;
  nsug : integer;
  BHval : Word;
  Dict : FILE;
  Roots : ARRAY[1..MaxRoots] OF String[35];
  nroots : integer;

PROCEDURE Click;
VAR
  al : byte;
  x  : byte;
  c  : Integer;
BEGIN
  FOR x:=1 TO 5 DO
  BEGIN
    al:=port[$61] AND $FC;
    port[$61]:=al;
    FOR c:=1 TO 10 DO;
    port[$61]:=al OR 2;
    FOR c:=1 TO 10 DO;
  END
END;

FUNCTION Clean(s:string):string;
{ -- Remove extraneous characters from string (replace them by blanks) -- }
VAR
  i:integer;
BEGIN
  FOR i:=1 TO length(s) DO
    IF pos(s[i],'-~`!@#$%^&*()_+|\=1234567890{}[]:";<>?,./'+
                     ^A^B^C^D^E^F^G^H^I^K^L^N^O^P^Q^R^S^T^U^V^W^X^Y^Z)>0
      THEN s[i]:=' ';
  Clean:=s;
END;

PROCEDURE CheckFail(s:string);
BEGIN
  IF IOResult<>0 THEN BEGIN
    XWrite(32);
    writeln(DictDir,s,'.');
    XWritelns(33,34);
    MemCleanup;
    ErrorLevel:=1;
    halt(ErrorLevel);
  END;
END;


PROCEDURE OpenDictionary(VAR Table:TableType);
VAR f:file;
BEGIN
  assign(f,DictDir+'HASH');
  {$I-} reset(f,1); {$I+}
  CheckFail('HASH');
  blockread(f,table,Sizeof(Table));
  close(f);
  assign(dict,DictDir+'WWIVEDIT.DIC');
  {$I-} reset(dict,1); {$I+}
  CheckFail('WWIVEDIT.DIC');
  bhval:=$ffff;
END;

FUNCTION Hash(VAR s:string):WORD;
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
  hash:=h shr 2 AND AND_With;
END;

FUNCTION Change(c:char;VAR s:string; suffix:string):boolean;
BEGIN
  IF s[length(s)] = c
    THEN BEGIN Change:=True; s:=copy(s,1,length(s)-1)+suffix END
    ELSE Change:=False;
END;

FUNCTION V_Flag(VAR s:string):string;
BEGIN
  IF Change('e',s,'ive')
    THEN V_Flag:=s
    ELSE V_Flag:=s+'ive';
END;

FUNCTION N_Flag(VAR s:string):string;
BEGIN
  IF Change('e',s,'ion') THEN N_Flag:=s
  ELSE IF Change('y',s,'ication') THEN N_Flag:=s
  ELSE N_Flag:=s+'en';
END;

FUNCTION X_Flag(VAR s:string):string;
BEGIN
  X_Flag:=N_Flag(s)+'s'
END;

FUNCTION H_Flag(VAR s:string):string;
BEGIN
  IF change('y',s,'ieth') THEN H_Flag:=s
  ELSE H_Flag:=s+'th';
END;

FUNCTION Y_Flag(VAR s:string):string;
BEGIN
  Y_Flag:=s+'ly';
END;

FUNCTION G_Flag(VAR s:string):string;
BEGIN
  IF Change('e',s,'ing') THEN G_Flag:=s
  ELSE g_flag:=s+'ing';
END;

FUNCTION J_Flag(VAR s:string):string;
BEGIN
  j_flag:=g_flag(s)+'s';
END;

FUNCTION D_Flag(s:string):string;
BEGIN
  IF Change('e',s,'ed') THEN BEGIN D_Flag:=s; exit; END;
  IF (s[length(s)]='y') AND NOT (s[length(s)-1] IN vowels) THEN
    s[length(s)]:='i';
  D_Flag:=s+'ed';
END;

FUNCTION T_Flag(s:string):string;
BEGIN
  IF Change('e',s,'est') THEN BEGIN T_Flag:=s; exit; END;
  IF (s[length(s)]='y') AND NOT (s[length(s)-1] IN vowels) THEN
    s[length(s)]:='i';
  T_Flag:=s+'est';
END;

FUNCTION R_Flag(s:string):string;
BEGIN
  IF Change('e',s,'er') THEN BEGIN R_Flag:=s; exit; END;
  IF (s[length(s)]='y') AND NOT (s[length(s)-1] IN vowels) THEN
    s[length(s)]:='i';
  R_Flag:=s+'er';
END;

FUNCTION Z_Flag(VAR s:string):string;
BEGIN
  Z_Flag:=R_Flag(s)+'s';
END;

FUNCTION S_Flag(VAR s:string):string;
VAR l:byte;
BEGIN
  l:=length(s);
  IF s[l]='y' THEN
    IF s[l-1] IN vowels THEN S_Flag:=copy(s,1,l-2)+'ies'
    ELSE s_Flag:=s+'s'
  ELSE IF s[l] IN ['s','x','z','h'] THEN S_Flag:=s+'es'
       ELSE S_Flag:=s+'s';
END;

FUNCTION P_Flag(VAR s:string):string;
VAR l:byte;
BEGIN
  l:=length(s);
  IF s[l]='y' THEN
    IF s[l-1] IN vowels THEN P_Flag:=copy(s,1,l-2)+'iness'
    ELSE p_flag:=s+'ness'
  ELSE p_flag:=s+'ness'
END;

FUNCTION M_Flag(VAR s:string):string;
BEGIN
  M_Flag:=s+'''s';
END;

FUNCTION Derivation(VAR root,check:string; flag:Word):boolean;
VAR
  isder : Boolean;
  s:string;
BEGIN
  Derivation:= (root=check)
       OR (Flag AND (1 shl 0)>0)  AND (V_Flag(root)=check)
       OR (Flag AND (1 shl 1)>0)  AND (N_Flag(root)=check)
       OR (Flag AND (1 shl 2)>0)  AND (X_Flag(root)=check)
       OR (Flag AND (1 shl 3)>0)  AND (H_Flag(root)=check)
       OR (Flag AND (1 shl 4)>0)  AND (Y_Flag(root)=check)
       OR (Flag AND (1 shl 5)>0)  AND (G_Flag(root)=check)
       OR (Flag AND (1 shl 6)>0)  AND (J_Flag(root)=check)
       OR (Flag AND (1 shl 7)>0)  AND (D_Flag(root)=check)
       OR (Flag AND (1 shl 8)>0)  AND (T_Flag(root)=check)
       OR (Flag AND (1 shl 9)>0)  AND (R_Flag(root)=check)
       OR (Flag AND (1 shl 10)>0) AND (Z_Flag(root)=check)
       OR (Flag AND (1 shl 11)>0) AND (S_Flag(root)=check)
       OR (Flag AND (1 shl 12)>0) AND (P_Flag(root)=check)
       OR (Flag AND (1 shl 13)>0) AND (M_Flag(root)=check);
END;

PROCEDURE FindRoot(VAR s:string);
  PROCEDURE Add(s:string);
  BEGIN
    inc(nroots);
    roots[nroots]:=s;
  END;
  FUNCTION Suffix(sx:string):boolean;
  BEGIN
    suffix:=rights(s,length(sx))=sx;
  END;
VAR
  l:byte;
  root:string;
BEGIN
  nroots:=0;
  l:=length(s);
  IF suffix('ication')  THEN add(lefts(s,l-7)+'y');
  IF suffix('ications') THEN add(lefts(s,l-8)+'y');
  IF suffix('ieth')     THEN add(lefts(s,l-4)+'y');
  IF suffix('ied')      THEN add(lefts(s,l-3)+'y');
  IF suffix('iest')     THEN add(lefts(s,l-3)+'y');
  IF suffix('ier')      THEN add(lefts(s,l-3)+'y');
  IF suffix('iers')     THEN add(lefts(s,l-4)+'y');
  IF suffix('ies')      THEN add(lefts(s,l-3)+'y');
  IF suffix('iness')    THEN add(lefts(s,l-5)+'y');
  IF suffix('ion')      THEN add(lefts(s,l-3)+'e');
  IF suffix('ions')     THEN add(lefts(s,l-4)+'e');
  IF suffix('ly')       THEN add(lefts(s,l-2));
  IF suffix('en')       THEN add(lefts(s,l-2));
  IF suffix('ens')      THEN add(lefts(s,l-3));
  IF suffix('th')       THEN add(lefts(s,l-2));
  IF suffix('es')       THEN add(lefts(s,l-2));
  IF suffix('s')        THEN add(lefts(s,l-1));
  IF suffix('''s')      THEN add(lefts(s,l-2));
  IF suffix('ness')     THEN add(lefts(s,l-4));
  IF suffix('ive')      THEN BEGIN Add(lefts(s,l-3)); Add(lefts(s,l-3)+'e'); END;
  IF suffix('ed')       THEN BEGIN Add(lefts(s,l-2)); Add(lefts(s,l-2)+'e'); END;
  IF suffix('er')       THEN BEGIN Add(lefts(s,l-2)); Add(lefts(s,l-2)+'e'); END;
  IF suffix('ing')      THEN BEGIN add(lefts(s,l-3)); add(lefts(s,l-3)+'e'); END;
  IF suffix('est')      THEN BEGIN add(lefts(s,l-3)); add(lefts(s,l-3)+'e'); END;
  IF suffix('ers')      THEN BEGIN add(lefts(s,l-3)); add(lefts(s,l-3)+'e'); END;
  IF suffix('ings')     THEN BEGIN add(lefts(s,l-4)); add(lefts(s,l-4)+'e'); END;
END;


FUNCTION BruteCheck(VAR Table:tableType; VAR s:string):boolean;
VAR
  p : integer;
  t : string;
  good,done : boolean;
  tmp : word;
BEGIN
{$IFDEF DEBUG}
  click;
{$ENDIF}
  tmp:=hash(s);
  Good:=false;
  IF (BHVal<>tmp) THEN
  BEGIN
    bhval:=tmp;
    seek(dict,table[tmp]);
    {$I-} blockread(dict,buffer,Sizeof(Buffer)); {$I+}
    tmp:=IOResult;
  END;
  p:=0;
  Done:=false;
  WHILE (NOT Good) AND (NOT Done) DO
  BEGIN
    done:=word(addr(buffer[p])^) AND $8000<>0;
    t:=unsquash(string(addr(buffer[p+2])^));
    p:=p+buffer[p+2]+3;
    Good:=t=s; {Derivation(t,s,word(addr(buffer[p])^));}
  END;
  BruteCheck:=Good;
END;

FUNCTION LookUp(VAR Table:TableType; s:string):boolean;
VAR
  good : boolean;
  i : integer;
BEGIN
  IF Length(s)>2 THEN
  BEGIN
    good:=brutecheck(Table,s);
    IF NOT Good THEN BEGIN
      s:=ToLower(s);
      Good:=brutecheck(Table,s);
    END;
    IF NOT Good THEN BEGIN
      FindRoot(s);
      FOR i:=1 TO nroots DO
        IF NOT Good THEN good:=brutecheck(Table,roots[i]);
    END;
    lookup:=good;
  END
  ELSE lookup:=true;
END;

PROCEDURE AddSug(VAR s:string; VAR Suggestions:SuggArray);
VAR
  i:integer;
  ok : boolean;
BEGIN
  i:=1;
  ok:=true;
  WHILE ok AND (i<=nsug) DO
  BEGIN
    ok:=s<>suggestions[i];
    inc(i);
  END;
  IF ok THEN
  BEGIN
    inc(nsug);
    suggestions[nsug]:=s;
  END;
END;

PROCEDURE WrongLetter(VAR Table:TableType; VAR s:string; VAR suggestions:SuggArray);
VAR
  i,j : integer;
  ch : char;
  t : string;
BEGIN
  FOR i:=1 TO length(s) DO
  BEGIN
    t:=s;
    IF s[i] IN ['a'..'z'] THEN
    FOR j:=1 TO length(try[s[i]]) DO
    BEGIN
      t[i]:=try[s[i]][j];
      IF LookUp(table,t) THEN AddSug(t,suggestions);
    END;
  END;
END;

PROCEDURE ExtraLetter(VAR Table:TableType; VAR s:string; VAR suggestions:SuggArray);
VAR
  t:string;
  i : integer;
BEGIN
  FOR i:=1 to length(s) DO
  BEGIN
    t:=s;
    delete(t,i,1);
    IF LookUp(Table,t) THEN AddSug(t,suggestions);
  END;
END;

PROCEDURE MissingLetter(VAR Table:TableType; VAR s:string; VAR suggestions:SuggArray);
CONST
  try : string = 'wertyuioplkhgfdsacbnm';
VAR
  i,j:integer;
  t : string;
BEGIN
  FOR i:=1 TO Length(s)-1 DO
  BEGIN
    t:=lefts(s,i)+' '+rights(s,length(s)-i);
    FOR j:=1 TO Length(try) DO
    BEGIN
      t[i+1]:=try[j];
      IF LookUp(table,t) THEN AddSug(t,suggestions);
    END;
  END;
END;

PROCEDURE TransposedLetter(VAR Table:TableType; VAR s:string; VAR suggestions:SuggArray);
VAR
  i:integer;
  t:string;
BEGIN
  FOR i:=1 TO Length(s)-1 DO
  BEGIN
    t:=s;
    t[i]:=t[i+1]; t[i+1]:=s[i];
    IF LookUp(table,t) THEN AddSug(t,suggestions);
  END;
END;


PROCEDURE MakeSuggestions(VAR Table:TableType; VAR s:string; VAR suggestions:SuggArray);
BEGIN
  nsug:=0;
  WrongLetter(table,s,suggestions);
  ExtraLetter(table,s,suggestions);
  MissingLetter(table,s,suggestions);
  TransposedLetter(table,s,suggestions);
END;

PROCEDURE AddToTemp(s,dname:string);
VAR
  t:text;
BEGIN
  assign(t,DictDir+dname+'.DIC');
  {$I-} append(t); {$I+}
  IF IOResult<>0 THEN rewrite(t);
  writeln(t,s);
  close(t);
END;

FUNCTION TempWord(s,dname:string):boolean;
VAR
  t:text;
  done:boolean;
  s1:string;
BEGIN
  assign(t,DictDir+dname+'.DIC');
  {$I-} reset(t) {$I+};
  IF IOResult<>0 THEN TempWord:=FALSE
  ELSE BEGIN
    done:=false;
    WHILE NOT Done AND NOT Eof(t) DO
    BEGIN
      readln(t,s1);
      done:=transformstring(s1)=transformstring(s);
    END;
    TempWord:=done;
    close(t);
  END;
END;


PROCEDURE SpellCheck;
{ Do the job of spell checking... What a pain... :-) }
VAR
  f : file;
  l : integer;
  Done,abort : boolean;
  p,i : integer;
  s,s1 : string;
  ch : char;
  Temp : LineType;
  t1 : LineType;
  CleanHigh : integer;
  Edited,dummy:boolean;
  scy, scx : integer;
  TempDictName : string[8];
  Table:TableType;
  suggestions:SuggArray;
BEGIN
  OpenDictionary(Table);
{ -- Setup New display -- }
  clrscr;
  IF Setting.PersonalDicAllowed
    THEN TempDictName:='U'+cstr(usernum)
    ELSE TempDictName:='TEMP';
  ansic('4'); writeln('WWIVEdit '+Version+' Spell Checker');
  XWritelns(35,36);
  l:=1;
  scy:=cy;
  scx:=cx;
  abort:=false;
  cy:=1;
  Done :=False;
{ -- Start Spell Checking -- }
  WHILE (l<Highline) AND (NOT Done) DO
  BEGIN
    IF KeyPressed THEN BEGIN
      ch:=upcase(Readkey);
      IF ch IN ['Q',' '] THEN BEGIN
        done:=true;
        abort:=true;
      END;
    END;
    p:=0;
    gotoxy(7,3);    Ansic('2');    write(l);
    cx:=1; cy:=l;
    s:=Clean(Line^[l]^.l);
    WHILE (cx<Length(s)) AND NOT Done DO
    BEGIN
      s1:=copy(s,cx,length(s)-cx+1);
      p:=pos(' ',s1);
      WHILE (p>0) AND (cx<length(s)) AND (p<2) DO
      BEGIN
        inc(cx);
        s1:=copy(s,cx,length(s)-cx+1);
        p:=pos(' ',s1);
      END;
      IF p=0 THEN p:=length(s)-cx+2;
      s1:=copy(s,cx,p-1);
      Edited:=False;
      IF length(s1)>1 THEN
      BEGIN
        IF (NOT LookUp(table,s1)) AND
           (NOT TempWord(s1,TempDictName)) AND
           (NOT TempWord(s1,'IGNORE')) THEN
        BEGIN
          ansic('1');
          gotoxy(1,4);
          write(C4+'Word :'+C0+' ');
          write(copy(Line^[cy]^.l,cx,length(s1)));
          clreol; nl;
          writeln(C5+'In Context:');
          ansic('0');
          write(Line^[cy]^.l); clreol; nl;
          CleanHigh:=7;
          gotoxy(1,7);
          write(C2+'Choice [S]> '+C1); clreol;
          ch:=ReadSet(['A','S','I','E','Q',EnterKey]);
          InitLine(t1);
          CASE ch OF
            'Q' : done:=true;
            'I' : BEGIN
                   nl;
                   Xwrite(37);
                   if yn THEN AddToTemp(s1,'IGNORE');
                   inc(cleanhigh);
                  END;
            'S',EnterKey :
                  BEGIN
                    nsug:=0;
                    gotoxy(1,8);
                    Xwriteln(38);
                    XWrite(39);
                    Gotoxy(1,9);
                    CleanHigh:=8;
                    MakeSuggestions(Table,s1,suggestions);
                    WHILE keypressed DO ch:=readkey;
                    clreol;
                    IF Nsug=0 THEN writeln(C2+'None'+C0);
                    FOR i:=1 TO Nsug DO
                    BEGIN
                      gotoxy(((i-1) DIV 15) * 40+1, i mod 15 + 7);
                      write(i:2,'. ',Suggestions[i]); clreol;
                      IF i mod 15 + 7 > cleanHigh THEN CleanHigh:= i mod 15 +7;
                    END;
                    inc(cleanhigh);
                    REPEAT
                      Gotoxy(1,CleanHigh);
                      inc(cleanhigh,2);
                      XWritelns(40,41);
                      XWrite(42); clreol;
                      InitLine(t1);
                      dummy:=LineEditor(t1,wherex,wherey,1,50,TRUE);
                      IF (value(t1.l)>0) AND (value(t1.l)<=nsug) THEN BEGIN
                        t1.l:=Suggestions[value(t1.l)];
                        t1.c:=copy(Line^[cy]^.c,cx,length(s1));
                        Edited:=False;
                      END ELSE Edited:=TRUE;
                    UNTIL (Edited AND (Value(t1.l)=0)) OR (Not Edited);
                    IF t1.l<>'' THEN
                    BEGIN nl;
                      XWrite(43);
                      writeln(t1.l);
                      XWrite(44);
                      IF NOT yn THEN t1.l:='';
                    END;
                    CleanHigh:=CleanHigh+3;
                  END;
            'E' : BEGIN
                    gotoxy(1,8);
                    CleanHigh:=9;
                    writeln(C2+'Edit spelling:');
                    t1.l:=copy(Line^[cy]^.l,cx,length(s1));
                    t1.c:=copy(Line^[cy]^.c,cx,length(s1));
                    CurrentColor:=#255;
                    FOR i:=1 TO Length(t1.l) DO
                    BEGIN
                      IF (currentColor<>t1.c[i]) THEN BEGIN
                        ansic(t1.c[i]);
                        currentcolor:=t1.c[i];
                      END;
                      write(t1.l[i]);
                    END;
                    dummy:=LineEditor(t1,1,9,length(t1.l)+1,50,TRUE);
                    Edited:=TRUE;
                  END;
            'A' : AddToTemp(s1,TempDictName);
          END;

          IF t1.l<>'' THEN BEGIN
            Line^[0]^.HardCR:=Line^[cy]^.HardCR;
            Line^[0]^.l:=copy(Line^[cy]^.l,cx,len(cy)-cx+1);
            Line^[0]^.c:=copy(Line^[cy]^.c,cx,len(cy)-cx+1);
            LDelete(cy,cx,len(cy)-cx+1);
            Line^[cy]^.HardCR:=FALSE;
            Ldelete(0,1,length(s1));
            IF len(0)+length(t1.l)>LineLen THEN BEGIN
              InsertLine(cy+1,Line^[0]^);
              InitLine(Line^[0]^);
              Temp.HardCR:=FALSE;
            END;
            IF Length(T1.c)>Length(T1.l) THEN
              Delete(T1.c,length(T1.l)+1,length(t1.l)-length(t1.c))
            ELSE IF Length(T1.c)<Length(T1.l) THEN
              T1.c:=T1.c+dup(T1.c[length(t1.c)],length(t1.l)-length(t1.c));
            LInsert(T1,0,1);
            InsertLine(cy+1,Line^[0]^);
            IF cx=1
              THEN DeleteLine(cy)
              ELSE Reformat(cy,true);
            s:=Clean(Line^[cy]^.l);
            IF (length(t1.l)<>length(s1)) AND NOT Edited THEN
              cx:=cx-length(s1)+length(t1.l)
          END;
          ansic('0');
          FOR i:=4 TO CleanHigh DO
          BEGIN
            gotoxy(1,i);
            clreol;
          END;

        END;
      END;
      IF Not Edited THEN
        cx:=cx+p
    END;
    inc(l);
  END;
{ -- Close Dictionary, restore Window, Force Redisplay -- }
  IF Abort THEN
  BEGIN
    cx:=scx;
    cy:=scy;
  END;
  BeforeNext:=DoNothing;
  AfterNext:=DoNothing;
  ForcedRedisplay;
END;

END.

