UNIT WEMouse;
{$I WEGlobal.PAS}

{ -- Implementation of a Text Mouse Cursor for WWIVEdit 2.3
  -- It should be general enough to be used in other Text Based applications
  -- simply by removing the $I WEGlobal.pas at the top
  --
  -- Written by Adam Caldwell
  -- Last Modified 4/15/92
  -- }

INTERFACE

USES DOS;

VAR
  Mouse_Reg        : Registers;
  MouseInstalled  : Boolean;
  Mouse_Error      : Word;

FUNCTION InitMouse : Word;
PROCEDURE ShowMouse;
PROCEDURE HideMouse;
FUNCTION MousePosition(var MouseX,MouseY : Word) : Word;
PROCEDURE setmouseposition(mousex, mousey: Word);
FUNCTION mousepress(button: Word; var count, lastx, lasty: Word): Word;
FUNCTION mouserelease(button: Word; var count, lastx, lasty: Word): Word;
PROCEDURE setmousexy(x1,y1,x2,y2: Word);

IMPLEMENTATION

FUNCTION InitMouse : Word;
{ Initialize mouse software and hardware }
BEGIN
  with Mouse_Reg do
    Ax := 0;
  Intr($33,Mouse_Reg);
  InitMouse := Mouse_Reg.Ax;
  Mouse_Error := Mouse_Reg.Ax;
  MouseInstalled := Mouse_Reg.AX = 65535;
END;

PROCEDURE ShowMouse;
{ show mouse cursor }
BEGIN
  Mouse_Reg.Ax := 1;
  Intr($33,Mouse_Reg);
END;

PROCEDURE HideMouse;
{ hide mouse cursor }
BEGIN
  Mouse_Reg.AX := 2;
  Intr($33,Mouse_Reg);
END;

FUNCTION MousePosition(var MouseX,MouseY : Word) : Word;
{ return mouse position and button status }
BEGIN
  Mouse_Reg.Ax := 3;
  Intr($33,Mouse_Reg);
  with Mouse_Reg do BEGIN
    MouseX := Cx div 8 +1;
    MouseY := Dx div 8 +1;
    MousePosition := Bx;
  END;
END;

PROCEDURE setmouseposition(mousex, mousey: Word);
{ sets mouse position  }
BEGIN
  Mouse_Reg.ax:=4;
  Mouse_Reg.cx:=(mousex-1)*8;
  Mouse_Reg.dx:=(mousey-1)*8;
  intr($33,Mouse_Reg);
END;

FUNCTION mousepress(button: Word; var count, lastx, lasty: Word): Word;
{ gets button press information  }
BEGIN
  Mouse_Reg.ax:=5;
  Mouse_Reg.bx:=button;
  intr($33,Mouse_Reg);
  mousepress:=Mouse_Reg.ax;
  count:=Mouse_Reg.bx;
  lastx:=Mouse_Reg.cx div 8 +1;
  lasty:=Mouse_Reg.dx div 8 +1;
END;

FUNCTION mouserelease(button: Word; var count, lastx, lasty: Word): Word;
{ gets button release information  }
BEGIN
  Mouse_Reg.ax:=6;
  Mouse_Reg.bx:=button;
  intr($33,Mouse_Reg);;
  mouserelease:=Mouse_Reg.ax;
  count:=Mouse_Reg.bx;
  lastx := Mouse_Reg.cx div 8 +1;
  lasty := Mouse_Reg.dx div 8 +1;
END;

PROCEDURE setmousexy(x1,y1,x2,y2: Word);
{ sets min/max values for horizontal/vertical  }
BEGIN
  Mouse_Reg.ax:=7;
  Mouse_Reg.cx:=x1*8 -1;
  Mouse_Reg.dx:=x2*8 -1;
  intr($33,Mouse_Reg);
  Mouse_Reg.ax:=8;
  Mouse_Reg.cx:=y1*8 -1;
  Mouse_Reg.dx:=y2*8 -1;
  intr($33,Mouse_Reg);
END;

END.
