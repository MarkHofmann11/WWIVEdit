UNIT Cursors;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

INTERFACE

TYPE
  CursorStates = (On, Off, FullBlock, BottomHalf, TopHalf, UnderScore);

PROCEDURE Cursor(State:CursorStates);
PROCEDURE PushCursor;
PROCEDURE PopCursor;

IMPLEMENTATION

USES DOS;

CONST
  Init: Boolean = FALSE;

TYPE
   CsrStackPtr = ^CsrStack;
   CsrStack = RECORD
                state : word;
                next  : CsrStackPtr;
              END;
VAR
  CSR_START,CSR_END:byte;
  CSR_BOTTOM : byte;
  CursorStack:CsrStackPtr;

PROCEDURE InitCursor;
VAR r:Registers;
BEGIN
  WITH r DO
  BEGIN
    ah:=3;
    intr($10,r);
    CSR_START:=ch;
    CSR_END:=cl;
    CSR_BOTTOM:=cl;
  END;
  CursorStack:=NIL;
  Init:=TRUE;
END;

PROCEDURE PushCursor;
VAR r:Registers;
    temp:CsrStackPtr;
BEGIN
  IF NOT Init THEN InitCursor;
  r.ah:=3;
  intr($10,r);
  new(temp);
  temp^.next:=CursorStack;
  temp^.state:=r.cx;
  CursorStack:=temp;
END;

PROCEDURE PopCursor;
VAR r:Registers;
    temp:CsrStackPtr;
BEGIN
  r.ah:=1;
  r.cx:=CursorStack^.state;
  intr($10,r);
  temp:=CursorStack;
  CursorStack:=CursorStack^.next;
  dispose(temp);
END;


PROCEDURE Cursor(State:CursorStates);
VAR r:Registers;
BEGIN
  IF NOT Init THEN InitCursor;
  CASE State OF
    On        : BEGIN
                  r.ah:=1;
                  r.ch:=CSR_START;
                  r.cl:=CSR_END;
                  intr($10,r)
                END;
    Off       : BEGIN
                  r.ah:=1;
                  r.ch:=32;
                  intr($10,r)
                END;
    FullBlock : BEGIN
                  r.ah:=1;
                  r.ch:=0;
                  r.cl:=CSR_BOTTOM;
                  CSR_START:=r.ch;
                  CSR_END:=r.cl;
                  intr($10,r)
                END;
    Underscore: BEGIN
                  r.ah:=1;
                  r.ch:=CSR_BOTTOM-1;
                  r.cl:=CSR_BOTTOM;
                  CSR_START:=r.ch;
                  CSR_END:=r.cl;
                  intr($10,r)
                END;
    TopHalf   : BEGIN
                  r.ah:=1;
                  r.ch:=0;
                  r.cl:=CSR_BOTTOM DIV 2;
                  CSR_START:=r.ch;
                  CSR_END:=r.cl;
                  intr($10,r)
                END;
    BottomHalf: BEGIN
                  r.ah:=1;
                  r.ch:=(CSR_BOTTOM+1) DIV 2;
                  r.cl:=CSR_BOTTOM;
                  CSR_START:=r.ch;
                  CSR_END:=r.cl;
                  intr($10,r)
                END;
  END;
END;

END.
