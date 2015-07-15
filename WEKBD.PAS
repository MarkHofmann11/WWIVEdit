UNIT WEKbd;
{$I WEGLOBAL.PAS}
{ -- This is the Low Level Keyboard Module for WWIVEdit 2.3
  -- Last Modified : 4/15/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This Code is Limited Public Domain (see WWIVEDIT.PAS for details)
  --
  -- Purpose : Provides low level, buffered keyboard input routines
  --
  -- Know Errors: Will lock up a computer if the user hangs up while
  --  seperate_local_input is on.  This only occurs during chat mode.
  --
  -- Planned Enhancements : Implementing fix described in WECHAT.PAS
  --
  -- }

INTERFACE


PROCEDURE Drain;
FUNCTION  ReadKey:char;
FUNCTION  KeyPressed:boolean;
FUNCTION  Empty:boolean;
PROCEDURE SeperateLocalInput;
PROCEDURE MergeLocalInput;
FUNCTION  KeyPressedL:boolean;
FUNCTION  ReadKeyL:char;
PROCEDURE StuffIn(s:string);
PROCEDURE Macro(ch:char);
PROCEDURE EnableInts; INLINE($FB);
PROCEDURE DisableInts; INLINE($FA);

IMPLEMENTATION

USES DOS,WEVars,WECom,WEFossil;

CONST
  BufferSize = 1024;

TYPE
  KeyBuffer = RECORD
    head : integer;
    tail : integer;
    Buffer : ARRAY[0..Buffersize-1] OF char;
  END;

CONST
  LKeyBuffer : KeyBuffer = (head: 0; tail:0);
  RKeyBuffer : KeyBuffer = (head: 0; tail:0);
  InstalledInt9: Boolean = FALSE;

VAR
  KbdHead : WORD ABSOLUTE $40:$1a;
  KbdTail : WORD ABSOLUTE $40:$1c;
  KbdMin : WORD ABSOLUTE $40:$80;
  KbdMax : WORD ABSOLUTE $40:$82;
  OldInt9 : pointer;


PROCEDURE Enque(VAR b:KeyBuffer; ch:char);
BEGIN
  WITH B DO BEGIN
    buffer[tail]:=ch;
    tail:=(tail+1) MOD BufferSize;
  END
END;

FUNCTION DeQue(VAR b:KeyBuffer):char;
BEGIN
  WITH B DO BEGIN
    DeQue:=buffer[head];
    head:=(head+1) MOD BufferSize
  END
END;

FUNCTION NoMoreKeys : boolean;
VAR
  empty:boolean;
  r : registers;
BEGIN
  r.ah:=$06;  r.dl:=$FF;
  msdos(r);
  Empty:=(r.flags AND FZero) >0;
  IF not Empty THEN Enque(RKeyBuffer,chr(r.al));
  IF Setting.Comport>0 THEN
  BEGIN
    Empty:=Empty OR NOT AsyncCharWaiting OR NOT FossilCharWaiting;
    IF AsyncCharWaiting THEN Enque(RKeyBuffer,AsyncRecieve);
    IF FossilCharWaiting THEN Enque(RKeyBuffer,FossilRecieve);
  END;
  NoMoreKeys := Empty;
END;

FUNCTION Critical(VAR B:KeyBuffer):boolean;
BEGIN
  Critical:=((b.tail+1) mod BufferSize) = b.head;
END;

PROCEDURE Drain;
BEGIN
  REPEAT
  UNTIL Critical(RKeyBuffer) OR NoMoreKeys;
END;

FUNCTION BufferEmpty(VAR B:KeyBuffer):boolean;
BEGIN
  BufferEmpty:=b.head=b.tail
END;

FUNCTION KeyPressedL:boolean;
BEGIN
  KeyPressedL:=NOT BufferEmpty(LKeyBuffer)
END;

FUNCTION ReadKeyL:char;
BEGIN
  REPEAT UNTIL KeyPressedL;
  ReadKeyL:=DeQue(LKeyBuffer);
END;

PROCEDURE NewInt9;
INTERRUPT;
BEGIN
  inline( $9C/ $FF/ $1E/ OldInt9 ); { Pushf / Call Far [OldInt9] }
  IF KbdHead<>KbdTail THEN
  BEGIN
    WITH LKeyBuffer DO BEGIN
      buffer[tail]:=chr(Mem[$40:KbdHead]);
      tail:=(tail+1) MOD BufferSize;
    END;
    IF Mem[$40:KbdHead]=0 THEN
    WITH LKeyBuffer DO BEGIN
      buffer[tail]:=chr(Mem[$40:KbdHead+1]);
      tail:=(tail+1) MOD BufferSize;
    END;
    KbdHead:=KbdHead+2;
    IF KbdHead=KbdMax THEN KbdHead:=KbdMin;
  END;
END;

PROCEDURE MergeLocalInput;
BEGIN
  IF InstalledInt9 THEN
  BEGIN
    SetIntVec(9,OldInt9);
    InstalledInt9:=FALSE;
  END;
END;


PROCEDURE SeperateLocalInput;
BEGIN
  IF NOT InstalledInt9 THEN
  BEGIN
    GetIntVec(9,OldInt9);
    SetIntVec(9,@NewInt9);
    InstalledInt9:=TRUE;
    LKeyBuffer.Head:=LKeyBuffer.Tail;
    RKeyBuffer.Head:=RKeyBuffer.Tail;
  END;
END;

FUNCTION empty : boolean;
BEGIN
  Drain;
  empty  :=  BufferEmpty(RKeyBuffer);
END;


FUNCTION KeyPressed : boolean;
BEGIN
  keypressed  := (not empty);
END;

PROCEDURE StuffIn(s:string);
VAR i:integer;
BEGIN
  FOR i:=1 TO length(s) DO
    Enque(RKeyBuffer,s[i]);
END;

PROCEDURE WriteKeyBuffer(ch:char; n:byte);
VAR
  r:registers;
BEGIN
  IF Setting.KeyBIOS THEN BEGIN
    r.ah:=5; r.cl:=ord(ch);
    r.ch:=n;
    intr($16,r);
  END
  ELSE BEGIN
    Mem[$40:KbdTail]:=ord(ch);
    Mem[$40:KbdTail+1]:=n;
    KbdTail:=KbdTail+2;
    IF KbdTail=KbdMax THEN KbdTail:=KbdMin;
  END;
END;

PROCEDURE Macro(ch:char);
VAR r:registers;
BEGIN
  IF (Setting.BBS=BBS_None) AND (Setting.WWIVEditMacrosOk)
  THEN CASE ch OF
    ^A : WriteKeyBuffer(#0,1);
    ^D : WriteKeyBuffer(#0,2);
    ^F : WriteKeyBuffer(#0,3);
  END
  ELSE IF (Setting.BBS=BBS_WWIV) THEN
  BEGIN
    WriteKeyBuffer(^P,0);
    WriteKeyBuffer(ch,0);
  END
END;

FUNCTION ReadKey : char;
VAR
  ch : char;
  r : registers;
BEGIN
  IF BufferEmpty(RKeyBuffer) THEN
  BEGIN
    IF Setting.Comport>0 THEN
    REPEAT UNTIL KeyPressed;
    IF FossilCharWaiting THEN Enque(RKeybuffer,FossilRecieve)
    ELSE IF AsyncCharWaiting THEN Enque(RKeybuffer,AsyncRecieve)
    ELSE BEGIN
      r.ah:=$07; msdos(r);
      Enque(RKeyBuffer,chr(r.al));
    END;
  END;
  ReadKey:=Deque(RKeyBuffer);
END;

END.