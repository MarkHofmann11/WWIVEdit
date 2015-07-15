UNIT WEMemory;
{$I WEGLOBAL.PAS}

INTERFACE

FUNCTION  malloc(size:word):pointer;
PROCEDURE MapPages;
PROCEDURE MemCleanup;

IMPLEMENTATION

USES ExecSwap;

CONST
  EMMInt = $67;

VAR
  count:word;
  Handle: word;
  PageFrame: word;
  BytesFree : LongInt;
  FreeBottom : pointer;

PROCEDURE MemCleanup;
BEGIN
  IF Count > 0 THEN
    DeallocateEmsHandle(Handle);
  Count:=0;
END;

FUNCTION GetUnallocPageCount : WORD;
BEGIN asm
  mov ah,$42
  int EMMInt
  mov @result,bx
end END;

FUNCTION Malloc(size:word):Pointer;
VAR
  x:pointer;
  Segx,Off: word;
  w : word;
BEGIN
  x:=NIL;
  IF BytesFree>=size THEN
  BEGIN
    BytesFree := BytesFree - size;
    x:=FreeBottom;
    Segx:=Seg(x^);
    Off:=Ofs(x^)+size;
    IF off > $f THEN BEGIN
      w:=Off div 16;
      Off:=Off mod 16;
      Segx := Segx + w;
      FreeBottom:=ptr(Segx,Off);
    END
  END ELSE
    GetMem(x,size);
  Malloc:=x;
END;

PROCEDURE MapPages;
BEGIN
  IF Count > 0 THEN
  asm
    mov ax,$4400
    xor bx,bx
    mov dx,handle
    int EMMInt
  end;
  IF Count > 1 THEN
  asm
    mov ax,$4401
    mov bx,1
    mov dx,handle
    int EMMInt
  end;
  IF Count > 2 THEN
  asm
    mov ax,$4402
    mov bx,2
    mov dx,handle
    int EMMInt
  end;
  IF Count > 3 THEN
  asm
    mov ax,$4403
    mov bx,3
    mov dx,handle
    int EMMInt
  end;
END;

BEGIN
  count:=0;
  BytesFree:=0;
{$IFDEF USE_EMS}
  IF EMSInstalled THEN
  BEGIN
    PageFrame:=EmsPageFrame;
    count:=GetUnallocPageCount;
    IF Count>4 THEN count:=4;
    IF Count>0 THEN
    BEGIN
      Handle:=AllocateEmsPages(count);
      FreeBottom:=ptr(PageFrame,0);
      BytesFree := count*LongInt(16384);
      MapPages;
    END ELSE BEGIN
      handle:=65535;
      BytesFree:=0;
    END;
  END;
{$ENDIF}
END.
