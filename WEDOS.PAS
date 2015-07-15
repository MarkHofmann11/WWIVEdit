UNIT WEDos;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{ -- Dos Module for WWIVEdit 2.4
  -- Provides an interface between the ExecSwap unit and the rest of
  -- the program.
  -- }
INTERFACE

PROCEDURE JumpDos;
FUNCTION InitSwap:boolean;
PROCEDURE Execute(s:string);
PROCEDURE EndSwap;

IMPLEMENTATION

USES ExecSwap,DOS, WEVars, WEOutput,WEMemory;

VAR
  x,y:integer;

FUNCTION InitSwap:boolean;
VAR
  ok:boolean;
BEGIN
  ok:=InitExecSwap(HeapEnd,'WWIVEDIT.SWP');
  IF OK THEN
  BEGIN
    x:=WhereX; y:=WhereY;
    SaveDisplay;
    ClrScr;
  END;
  InitSwap:=ok;
END;

PROCEDURE Execute(s:string);
VAR
  p:string;

BEGIN
  GetDir(0,p);
  IF s<>'' THEN
  BEGIN
    writeln('Swapping....');
    IF ExecWithSwap(GetEnv('COMSPEC'),'/C '+s)=0 THEN
  END
  ELSE BEGIN
    writeln('DOS Shell... Type EXIT to return to WWIVEdit...');
    IF ExecWithSwap(GetEnv('COMSPEC'),'')=0 THEN
  END;
  chdir(p);
END;

PROCEDURE EndSwap;
VAR f:file;
BEGIN
  ShutDownExecSwap;
  Move(Display^, SaveScreen^, ScreenSize);
  RestoreDisplay;
  Gotoxy(x,y);
  {$I-}
  assign(f,'WWIVEDIT.SWP');
  SetFAttr(f,0);
  IF IOResult=0 THEN
    erase(f);
  IF IOResult=0 THEN ;
  {$I+}
  MapPages;
END;

PROCEDURE JumpDos;
BEGIN
  IF InitSwap THEN
  BEGIN
    Execute('');
    EndSwap;
  END;
END;

END.

