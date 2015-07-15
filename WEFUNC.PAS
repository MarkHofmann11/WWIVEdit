UNIT WEFunc;
{$I WEGLOBAL.PAS}
{ -- Function encapsulation for WWIVEdit 2.4
  -- All of the "editing" functions are in this file (hopefully)
  -- except for non-common ones (overlay)
  -- }
INTERFACE

USES WEVars;

PROCEDURE DoFun(fun:edfun; ch:char);
PROCEDURE LineEdit(VAR Line:LineType;
                       fun:edfun;
                       ch:char;
                       maxLen:integer;
                   VAR cx:integer;
                       AllowColorChange:boolean);
PROCEDURE SetTopScreen(SetTo:integer);


IMPLEMENTATION

USES WEKbd, WEString, WEInput, WEOutput, WELine,WEHelp, WEFile, DOS,
     WEQuote, Cursors,WEFunc1;
{V-}

PROCEDURE ToggleInsertMode;
BEGIN
  InsertMode:=NOT InsertMode;
  IF Setting.ChangeCursor THEN
  BEGIN
    IF InsertMode THEN Cursor(Underscore)
    ELSE Cursor(FullBlock);
  END;
END;


PROCEDURE DoBackspace;
{ All this just because the user hits the Backspace (or Delete) }
VAR
  temp:LineType;
  Ins:boolean;
BEGIN
  Ins:=InsertMode;                { Save the current InsertMode State }
  InsertMode:=True;               { Set insert mode on }
  IF cx > 1 THEN BEGIN            { If we aren't in the first column, things are easy }
    LDelete(cy,cx-1,1);           { Just delete the character to the left of }
    dec(cx);                      { the cursor and back up }
    reformat(cy,false);
  END
  ELSE IF len(cy)=0 THEN BEGIN    { Special case for if there isn't anything }
    DeleteLine(cy);               { On the line we are backspacing from }
    dec(cy);
    cx:=Len(cy)+1;
  END
  ELSE IF cy>1 THEN BEGIN         { Otherwise, the user wants to join two lines }
    dec(cy);                      { Back up one line }
    cx:=len(cy)+1;                { move to the end of it }
    IF (cx=1) THEN
      DeleteLine(cy)
    ELSE BEGIN
      Line^[cy]^.hardCR:=false;
      Reformat(cy,false);         { Reformat everything now to shorten the line }
    END;
  END;
  InsertMode:=Ins;                { Go back to current insert state }
END;


PROCEDURE DoEnter;
BEGIN
  IF cx<=Len(cy) THEN
  BEGIN
    Line^[0]^.l:=copy(Line^[cy]^.l,cx,len(cy)-cx+1);
    Line^[0]^.c:=copy(Line^[cy]^.c,cx,len(cy)-cx+1);
    LDelete(cy,cx,len(cy)-cx+1);
    inc(cy);
    InsertLine(cy,Line^[0]^);
    InitLine(Line^[0]^);
    cx:=1;
    Line^[cy]^.HardCR:=Line^[cy-1]^.hardCR;
    Reformat(cy,false);
  END
  ELSE BEGIN
    inc(cy);
    cx:=1;
    InitLine(Line^[0]^);
    InsertLine(cy,Line^[0]^);
  END;
  Line^[cy-1]^.HardCR := TRUE;
END;


PROCEDURE DoDelChar;
BEGIN
  inc(cx);
  IF cx>Len(cy)+1 THEN
  BEGIN
    dec(cx);
    IF Len(cy+1)=0 THEN
      DeleteLine(cy+1)
    ELSE BEGIN
      Line^[cy]^.HardCR:=False;
      Reformat(cy,false);
    END;
  END
  ELSE DoBackspace;
END;

PROCEDURE DoTab;
VAR
  Temp : LineType;
BEGIN
  IF cx < LineLen - TabStop THEN
  REPEAT
    IF InsertMode THEN
    BEGIN
      MakeString(temp,' ',CurrentColor);
      LInsert(Temp,cy,cx);
      Reformat(cy,False);
    END;
    inc(cx);
  UNTIL (cx-1) mod TabStop =0;
END;

PROCEDURE SetTopScreen(SetTo:integer);
BEGIN
  ScreenState:=SetTo;
  CASE SetTo OF
    0 : BEGIN
          WindowTop:=5;
          WindowBottom:=ScreenHeight-2;
        END;
    1 : BEGIN
          WindowTop:=1;
          WindowBottom:=ScreenHeight-2;
        END;
    2 : BEGIN
          WindowTop:=3;
          WindowBottom:=ScreenHeight-2;
        END;
    3,4 : BEGIN
          WindowTop:=2;
          WindowBottom:=ScreenHeight-2;
        END;
  END;
  WindowHeight:=WindowBottom-WindowTop;
  ViewBottom:=ViewTop+WindowHeight;
END;


PROCEDURE DoMouse;
BEGIN
  LocationOverride:=false;
  IF (LocationOverride_Y>=WindowTop) AND (LocationOverride_Y<=WindowBottom) THEN
  BEGIN
    cx:=LocationOverride_X;
    cy:=ViewTop+LocationOverride_Y-WindowTop;
  END
END;

PROCEDURE ScrollWindowDown;
{ Moves the viewport down on the Text Buffer }
VAR x:integer;
BEGIN
  IF cy>MaxLines THEN cy:=MaxLines-1;
  x:=cy-ViewTop;
  cy:=cy+WindowHeight-MinScrollLeft;
  ViewTop:=cy-x;
  ViewBottom:=ViewTop + WindowHeight;
  IF viewBottom>MaxLines THEN BEGIN
    ViewBottom:=MaxLines-1;
    ViewTop:=ViewTop-WindowHeight;
    cy:=ViewBottom;
  END;
END;



PROCEDURE ScrollWindowUp;
VAR x:integer;
{ Moves the Viewport Up on the Text Buffer }
BEGIN
  IF cy<1 THEN cy:=1;
  x:=cy-ViewTop;
  cy:=cy-WindowHeight+MinScrollLeft;
  ViewTop:=cy-x;
  ViewBottom:=ViewTop+WindowHeight;
  IF ViewTop<1 THEN BEGIN
    ViewTop:=1;
    cy:=1;
    ViewBottom:=ViewTop + WindowHeight;
  END;
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


PROCEDURE LineEdit(VAR Line:LineType;
                       fun:edfun;
                       ch:char;
                       maxLen:integer;
                   VAR cx:integer;
                       AllowColorChange:boolean);
VAR
  done : boolean;
  temp : linetype;
BEGIN
  REPEAT
    done:=true;
    CASE fun OF
      BackSpace   : IF (cx>1) THEN
                    BEGIN
                      LDeleteL(Line,cx-1,1); { Just delete the character to the }
                      dec(cx);               { left of the cursor and back up }
                    END;
      DelChar     : IF (cx<=Length(line.l)) THEN
                      LDeleteL(Line,cx,1);
      DelEOL      : LDeleteL(Line,cx,length(line.l)-cx+1);
      DelLine     : BEGIN cx:=1; InitLine(Line); END;
      DelSOL      : BEGIN
                      LDeleteL(Line,1,cx-1);
                      cx:=1;
                    END;
      DisplayAlt  : ShowOtherScreen;
      _end        : cx:=length(Line.l)+1;
      Enter       : ;
      EraseWordLeft:BEGIN
                      WHILE (cx>1) AND (Line.l[cx-1]=' ') DO {Delete Spaces}
                      BEGIN
                        LDeleteL(Line,cx-1,1);
                        dec(cx);
                      END;
                      WHILE (cx>1) AND (Line.l[cx-1]<>' ') DO {Delete Word}
                      BEGIN
                        LDeleteL(Line,cx-1,1);
                        dec(cx);
                      END;
                    END;
      EraseWordRight:BEGIN
                      WHILE (cx<=Length(Line.l)) AND (Line.l[cx-1]=' ') DO {Delete Spaces}
                        LDeleteL(Line,cx,1);
                      WHILE (cx<=Length(Line.l)) AND (Line.l[cx-1]<>' ') DO {Delete Word}
                        LDeleteL(Line,cx,1);
                    END;
      GetHelp     : Help;
      GoBack      : BEGIN
                      fun:=InsertChar;
                      done:=false;
                      ch:=^H;
                    END;
      Home        : cx:=1;
      InsertChar,
      InsertMCI   : IF length(line.l)+1<=MaxLen THEN
                    BEGIN
                      IF (Fun=InsertMCI) AND (length(line.l)+2<=MaxLen) THEN
                      BEGIN
                        MakeString(Temp,^C,CurrentColor);
                        LinsertL(Temp,Line,cx);
                        inc(cx);
                      END;
                      MakeString(Temp,ch,CurrentColor);
                      LinsertL(Temp,Line,cx);      { Insert it                               }
                      inc(cx);                     { move cursor right                       }
                    END;
      InsertLiteral:
                    BEGIN
                      done:=false;
                      fun:=insertchar;
                      ch:=GetKey(false);
                    END;
      Left        : IF cx>1 THEN dec(cx);
      RedisplayAll: ForcedRedisplay;
      Right       : IF (cx<=Length(line.l)) AND (cx<=MaxLen) THEN
                      inc(cx);
      ToggleInsert: ToggleInsertMode;
      WordLeft    : Cx:=GoLeft(Line.l,cx);
      WordRight   : cx:=GoRight(Line.l,cx);
      WWIVColor   : IF AllowColorChange THEN
                    BEGIN
                      ch:=GetKey(false);
                      IF ch IN setting.mci THEN
                      BEGIN
                        fun:=InsertMCI;
                        done:=false;
                      END
                      ELSE
                        IF ch IN Setting.Colors THEN
                          CurrentColor:=ch
                    END;
      WWIVMacro1  : Macro(^D);
      WWIVMacro2  : Macro(^F);
      WWIVMacro3  : Macro(^A);
    END;
  UNTIL Done;
END;

PROCEDURE DoFun(fun:edfun; ch:char);
VAR
  done:boolean;
  temp : linetype;
BEGIN
  REPEAT
    done:=true;
    CASE fun OF
      BackSpace   : IF ((cy=1) AND (cx>1)) OR (cy>1) THEN
                      DoBackspace;
      Bottom      : cy:=highline+1;
      BottomPage  : cy:=ViewBottom;
      CenterLine  : DoCenterLine(cy);
      CopyBlock   : DoBlockCopy(BlockStart,BlockEnd,cy);
      DelChar     : DoDelChar;
      DelEOL      : LDelete(cy,cx,len(cy)-cx+1);
      DeleteBlock : BEGIN
                      cy:=BlockStart;
                      DoDeleteBlock(BlockStart,BlockEnd);
                    END;
      DelLine     : BEGIN cx:=1; DeleteLine(cy); END;
      DelSOL      : BEGIN
                      LDelete(cy,1,cx-1);
                      cx:=1;
                    END;
      DisplayAlt  : ShowOtherScreen;
      Down        : IF cy<MaxLines THEN
                      inc(cy);
      _end        : cx:=len(cy)+1;
      Enter       : DoEnter;
      EraseWordLeft:BEGIN
                      WHILE (cx>1) AND (character(cy,cx-1)=' ') DO
                        DoBackspace;
                      WHILE (cx>1) AND (character(cy,cx-1)<>' ') DO
                        DoBackspace;
                    END;
      EraseWordRight:BEGIN
                      WHILE (cx<=len(cy)) AND (character(cy,cx)=' ') DO
                        Ldelete(cy,cx,1);
                      WHILE (cx<=len(cy)) AND (character(cy,cx)<>' ') DO
                        Ldelete(cy,cx,1);
                      WHILE (cx<=len(cy)) AND (character(cy,cx)=' ') DO
                        Ldelete(cy,cx,1);
                    END;
      Find        : DoSearch;
      FindAndReplace: DoSearchAndReplace;
      FindLast    : SearchLast;
      GetHelp     : Help;
      GoBack      : BEGIN
                      fun:=InsertChar;
                      done:=false;
                      ch:=^H;
                    END;
      Home        : cx:=1;
      InsertChar,
      InsertMCI :   BEGIN
                      IF cx<=len(cy) THEN  { Strip off trailing blanks if they don't have a color }
                        WHILE (character(cy,len(cy))=' ') AND (Color(Line^[cy]^,len(cy))='0') AND (len(cy)>cx) DO
                          LDelete(cy,len(cy),1);
                      IF Fun=InsertMCI THEN
                      BEGIN
                        MakeString(Temp,^C,CurrentColor);
                        Linsert(Temp,cy,cx);
                        Reformat(cy,true);
                        inc(cx);
                      END;
                      MakeString(Temp,ch,CurrentColor);
                      Linsert(Temp,cy,cx);         { Insert it                               }
                      Reformat(cy,true);
                      inc(cx);                     { move cursor right                       }
                    END;
      InsertFile  : DoInsertFile;
      InsertLiteral:
                    BEGIN
                      done:=false;
                      fun:=insertchar;
                      ch:=GetKey(false);
                    END;
      InsLine     : insertLine(cy,Line^[0]^);
      InsLineAfter: insertLine(cy+1,Line^[0]^);
      InvokeQuoter: IF Exists(QuoteFile) THEN
                    BEGIN
                      IF MaxLines-Highline<=5 THEN
                      BEGIN
                        StatusLine3('You don''t have enough lines left.');
                        AfterNext:=ClrStatLine3;
                      END ELSE BEGIN
                        IF PerformQuote(QuoteTmp,MaxLines-Highline-5) THEN
                        BEGIN
                          ReadInputFile(cy,QuoteTmp);
                          clrscr;
                          cy:=HighLine+1;
                          cx:=1;
                          ViewTop:=cy-3;
                          IF ViewTop<1 THEN ViewTop:=1;
                          ViewBottom:=ViewTop+WindowHeight;
                          IF ViewBottom>MaxLines THEN
                          BEGIN
                            ViewBottom:=MaxLines;
                            ViewTop:=ViewBottom-WindowHeight
                          END;
                          EraseF(QuoteTmp);
                        END;
                        ForcedRedisplay
                      END
                    END
                    ELSE BEGIN
                      StatusLine3('No text available for quoting.');
                      AfterNext:=ClrStatLine3;
                    END;
      Jump        : DoJump;
      Left        : BEGIN
                      dec(cx);
                      IF (cx=0) AND (cy>1) THEN
                      BEGIN
                        cx:=len(cy-1)+1;
                        dec(cy)
                      END
                      ELSE IF cx=0 THEN cx:=1
                    END;
      MarkEnd     : BEGIN BlockEnd   := cy; ShowBlockStatus END;
      MarkStart   : BEGIN BlockStart := cy; ShowBlockStatus END;
      Mouse       : DoMouse;
      MoveBlock   : DoBlockMove(BlockStart,BlockEnd,cy);
      PgDn        : ScrollWindowDown;
      PgUp        : ScrollWindowUp;
      RedisplayAll: ForcedRedisplay;
      Right       : BEGIN
                      inc(cx);
                      IF cx>LineLen+1 THEN
                      BEGIN
                        inc(cy);
                        cx:=1
                      END;
                    END;
      SaveAndContinue: DoSaveAndContinue;
      SaveAs      : DoSaveBlock(1,HighLine);
      SaveBlock   : DoSaveBlock(BlockStart,BlockEnd);
      ShowBlockStat:ShowBlockStatus;
      Tab         : DoTab;
      ToggleInsert: BEGIN ToggleInsertMode; ShowMaxLines; END;
      ToggleFullScreen :
                    BEGIN
                       SetTopScreen((ScreenState+1) MOD (MAX_STATES+1));
                       ForcedRedisplay;
                    END;
      ToggleWhere : DoToggleWhere;
      Top         : BEGIN cy:=1; ViewTop:=1; SetTopScreen(ScreenState); END;
      TopPage     : cy:=ViewTop;
      Up          : IF cy>1 THEN dec(cy);
      WordLeft    : Cx:=GoLeft(Line^[cy]^.l,cx);
      WordRight   : cx:=GoRight(Line^[cy]^.l,cx);
      WWIVColor   : BEGIN
                      ch:=GetKey(false);
                      IF ch in setting.mci THEN
                      BEGIN
                        fun:=InsertMCI;
                        done:=false;
                      END
                      ELSE
                        IF ch IN Setting.Colors THEN
                          CurrentColor:=ch
                    END;
      WWIVMacro1  : Macro(^D);
      WWIVMacro2  : Macro(^F);
      WWIVMacro3  : Macro(^A);
    END;
  UNTIL Done;
END;


END.
