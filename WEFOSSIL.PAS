UNIT WEFossil;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}
{ -- Fossil Driver unit for WWIVEdit 2.4
  -- Provides a fossil driver interface for WWIVEdit 2.4
  -- }
INTERFACE
PROCEDURE FossilTransmit(ch1:char);
FUNCTION  FossilRecieve:char;
PROCEDURE FossilFlushComm;
FUNCTION  FossilCharWaiting:BOOLEAN;
FUNCTION  FossilCDetect:boolean;
PROCEDURE FossilInit(port:byte);

IMPLEMENTATION

USES DOS
{$IFDEF USE_EMS}
,WEMemory
{$ENDIF};

CONST
  Fossil=$14;

VAR
  thePort : word;
  Status  : word;
  busy:boolean;
  OldOutput : text;
CONST
  Initialized : boolean = False;


PROCEDURE SetPort(port:byte);
VAR
  r:registers;
BEGIN
  thePort:=port-1;
  IF port=0 THEN
    theport:=$00ff;
  r.ah:=4; r.dx:=theport; intr(FOSSIL,r);
  IF r.ax<>$1954 THEN
  BEGIN
    writeln('Fossil Driver failed initialization.');
{$IFDEF USE_EMS}
    MemCleanup;
{$ENDIF}
    halt(1);
  END;
END;

PROCEDURE CheckStatus;
VAR r:registers;
BEGIN
  IF Initialized THEN
  WITH r DO
  BEGIN
    ah:=3;
    dx:=theport;
    intr(FOSSIL,r);
    status:=ax;
  END;
END;


FUNCTION FossilCDetect:boolean;
VAR
  i: integer;
  carrier : boolean;
BEGIN
  IF Initialized THEN
  BEGIN
    FossilCDetect:=TRUE;
    IF theport=$00ff THEN Exit;
    FOR i:=1 TO 100 DO
    BEGIN
      CheckStatus;
      IF Status AND 128 > 0 THEN exit;
    END;
    FossilCDetect:=FALSE;
  END
  ELSE FossilCdetect:=TRUE;
END;


PROCEDURE FossilTransmit(ch1:char);
VAR
  r:registers;
BEGIN
  IF Initialized THEN
  WITH r DO
  BEGIN
    ah:=$1;
    al:=ord(ch1);
    dx:=thePort;
    intr(FOSSIL,r);
    status:=ax;
  END;
END;

FUNCTION FossilRecieve:char;
VAR
  r:registers;
BEGIN
  IF Initialized THEN
  WITH r DO
  BEGIN
    ah:=2;
    dx:=thePort;
    intr(FOSSIL,r);
    FossilRecieve:=chr(al);
  END;
END;


FUNCTION FossilCharWaiting:BOOLEAN;
VAR
  r:registers;
  waiting:boolean;
BEGIN
  IF Initialized THEN
  WITH r DO
  BEGIN
    ah:=$0c;
    dx:=theport;
    intr(FOSSIL,r);
    FossilCharWaiting:=not(ax=$ffff);
  END
  ELSE FossilCharWaiting:=FALSE;
END;

PROCEDURE FossilFlushComm;
VAR
  r:registers;
BEGIN
  IF Initialized THEN
  WITH r DO
  BEGIN
    r.dx:=theport;
    r.ah:=8;
    intr(FOSSIL,r);
  END;
END;

{$F+}
FUNCTION DoNothing(VAR f:TextRec):integer;
BEGIN
  DoNothing :=0;
END;

FUNCTION OutCh(VAR f:TextRec):integer;
VAR
  b:byte;
  ch : char;
BEGIN
  IF NOT FossilCdetect THEN
  BEGIN
{$IFDEF USE_EMS}
    MemCleanup;
{$ENDIF}
    halt;
  END;
  IF NOT Busy THEN
  BEGIN
    Busy:=TRUE;
    b:=0;
    WHILE f.BufPos>0 DO
    BEGIN
      ch:=F.BufPtr^[b];
      inc(b);
      dec(F.BufPos);
      FossilTransmit(ch);
      write(OldOutput,ch);
    END;
    OutCh := 0;
    Busy:=FALSE;
  END;
END;

PROCEDURE FossilInit(port:byte);
BEGIN
  SetPort(port);
  busy:=false;
  TextRec(OldOutput) := TextRec(OutPut);
  WITH TextRec(Output) DO
  BEGIN
    Mode:=fmOutput;
    InOutFunc := @OutCh;
    FlushFunc := @OutCh;
    UserData[1]:=0;
  END;
  Initialized:=True;
END;

END.
