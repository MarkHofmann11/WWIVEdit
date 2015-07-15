UNIT WECom;
{$I WEGLOBAL.PAS}
{ -- Asychronous communications routines for WWIVEdit 2.4
  -- }
INTERFACE

PROCEDURE AsyncTransmit(ch1:char);
FUNCTION  AsyncRecieve:char;
PROCEDURE AsyncFlushComm;
FUNCTION  AsyncCharWaiting:BOOLEAN;
FUNCTION  AsyncCDetect:boolean;
PROCEDURE AsyncInit(port:byte);
PROCEDURE AsyncShutdown;

IMPLEMENTATION

USES DOS
{$IFDEF USE_EMS}
,WEMemory
{$ENDIF};

CONST
  BufferSize = 1024;
  NoParity=0;
  OddParity=8;
  EvenParity=24;
  OneStop=0;
  TwoStop=4;
  SevenBits=2;
  EightBits=3;
  Space=64;
  Break=0;

  theParity = EightBits OR OneStop OR NoParity OR Break;

TYPE
  QPtr = ^Queue;
  Queue = RECORD
    Empty : boolean;
    Front,Rear : Word;
    Info  : ARRAY[0..BufferSize-1] OF Byte;
  END;

VAR
  thePort : word;
  Status  : word;
  busy:boolean;
  OldOutput : text;
  inp,outp: Qptr;
CONST
  Initialized : boolean = FALSE;

CONST
  ComInterrupt : ARRAY[1..2] OF BYTE = (12,11);
  P8259_0=$20; { Int control register                 }
  P8259_1=$21; { Int mask register                    }
  EndInt =$20; { non-specific EOI                     }
  RDAINT = 1;
  THREINT= 2;
  RLSINT = 4;
  MSINT  = 8;

  MCRALL = 11; { Modem Control Register, DTR,RTS,Out 2}
  MCROFF = 0;  { Modem Control Register, turn all off }

  IERALL = RDAINT+THREINT+RLSINT+MSINT;
  IEROFF = 0;

  THREOFF= $FD;

  MDMSTATUS = 0;
  TXREGEMPTY = 2;
  RXDATAREADY = 4;
  RLINESTATUS = 6;


VAR
  comport:word;
  IER,                 { Interrupt enable register }
  IIR,                 { Interrupt identification }
  LCR,                 { Line control register }
  MCR,                 { Modem control register }
  LSR,                 { Line status register }
  MSR     : word;      { Modem status register }
  IDM,                 { Interrupt disable mask }
  IEM     : byte;      { Interrupt enable mask }
  OldComInt : POINTER; { A pointer to the old com interrupt }
  IntMask : byte;
  ModemStat,LineStat : byte;


PROCEDURE DisableInt; INLINE($FA);
PROCEDURE EnableInt;  INLINE($FB);

FUNCTION DeQue(VAR Q:Queue):byte;
BEGIN
  WITH Q DO
  BEGIN
    DeQue:=Info[front];
    front:=(front+1) MOD BufferSize;
    Empty:=Front=Rear;
  END;
END;

PROCEDURE EnQue(VAR Q:Queue; c:byte);
BEGIN
 WITH Q DO
 BEGIN
   Empty:=false;
   Info[rear]:=c;
   rear:=(rear+1) MOD BufferSize;
 END;
END;

FUNCTION QueueEmpty(VAR Q:Queue):boolean;
BEGIN
  WITH Q DO
    QueueEmpty:=Q.Empty;
END;

PROCEDURE InitQue(VAR Q:Qptr);
BEGIN
  new(Q);
  Q^.Empty:=TRUE;
  Q^.Front:=0;
  Q^.Rear:=0
END;

PROCEDURE NewComInt;
INTERRUPT;
VAR
  IntID,IERVal : byte;
  c:byte;
BEGIN
  EnableInt;
  WHILE TRUE DO
  BEGIN
    IntID:=port[IIR] AND 7;
    IF (IntID AND 1) = 1 THEN
    BEGIN
      port[P8259_0]:=EndInt;
      exit;
    END;
    CASE IntID OF
      MdmStatus : ModemStat:=port[MSR];

      TXREGEmpty  : BEGIN
        IF NOT Outp^.Empty THEN
          Port[ComPort]:=Deque(Outp^)
        ELSE
          Port[IER]:=Port[IER] AND THREOFF;
      END;

      RXDataReady : BEGIN
        c:=port[comport];
        Enque(inp^,c);
      END;

      RLineStatus : LineStat:=port[LSR];
    END;
  END;
END;



PROCEDURE SetPort(aport:byte);
VAR
  r:registers;
BEGIN
  thePort:=aport-1;
  comport:=memw[$40:theport*2];
  IER:=comport+1;
  IIR:=comport+2;
  LCR:=comport+3;
  MCR:=comport+4;
  LSR:=comport+5;
  MSR:=comport+6;
  IDM:=(32 shr aport);
  IEM:=IDM xor $FF;
  InitQue(Inp);
  InitQue(Outp);
  GetIntVec(ComInterrupt[aPort],OldComInt);
  SetIntVec(ComInterrupt[aPort],@NewComInt);
  port[MCR]:=MCRALL;                  { Set up modem control register        }
  port[IER]:=IERALL;                  { Enable all interrups on serial card  }
  IntMask:=port[P8259_1] AND IEM;     { Read 8259A's interrupt mask and write}
  port[P8259_1]:=intmask;             { it back after ANDing it with IEM     }
END;

PROCEDURE CheckStatus;
BEGIN
  IF Initialized THEN
    ModemStat:=port[MSR];
END;


FUNCTION AsyncCDetect:boolean;
VAR
  i: integer;
  carrier : boolean;
BEGIN
  IF Initialized THEN
  BEGIN
    AsyncCDetect:=TRUE;
    IF theport=$00ff THEN Exit;
    FOR i:=1 TO 100 DO
    BEGIN
      CheckStatus;
      IF ModemStat AND 128 > 0 THEN exit;
    END;
    AsyncCDetect:=FALSE;
  END
  ELSE AsyncCdetect:=TRUE;
END;


PROCEDURE AsyncTransmit(ch1:char);
BEGIN
  IF Initialized THEN BEGIN
    Enque(outp^,ord(ch1));
    PORT[IER]:=PORT[IER] OR THREINT;
  END;
END;

FUNCTION AsyncRecieve:char;
BEGIN
  IF Initialized THEN
    AsyncRecieve:=chr(Deque(inp^));
END;


FUNCTION AsyncCharWaiting:BOOLEAN;
VAR
  waiting:boolean;
BEGIN
  IF Initialized THEN
    AsyncCharWaiting:=NOT QueueEmpty(inp^)
  ELSE AsyncCharWaiting:=FALSE;
END;

PROCEDURE AsyncFlushComm;
VAR
  r:registers;
BEGIN
  IF Initialized THEN
    WHILE NOT QueueEmpty(outp^) DO ;
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
  IF NOT AsyncCdetect THEN
  BEGIN
    AsyncShutdown;
{$IFDEF USE_EMS}
    MemCleanup;
{$ENDIF}
    halt(1);
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
      AsyncTransmit(ch);
      write(OldOutput,ch);
    END;
    OutCh := 0;
    Busy:=FALSE;
  END;
END;

PROCEDURE AsyncInit(port:byte);
BEGIN
  IF Port=0 THEN exit;
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

PROCEDURE AsyncShutdown;
BEGIN
  IF Initialized THEN
  BEGIN
    initialized:=false;
    DisableInt;
    SetIntVec(ComInterrupt[thePort+1],OldComInt);
    EnableInt;
  END;
END;


END.
