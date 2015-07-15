UNIT WETime;
{$I WEGLOBAL.PAS}
{ -- This is the Low Level Time Unit of WWIVEdit 2.2
  -- Last Updated : 8/13/91
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is Public Domain
  --
  -- Purpose : Provide Time Functions
  --
  -- Known Errors : None
  --
  -- Planned Enhancements : None
  --
  -- }

INTERFACE

FUNCTION timer:LongInt;            { Returns number of seconds past midnight  }
FUNCTION time:string;              { returns the time of day in 24 hr Format  }

IMPLEMENTATION

USES WEString, DOS;

FUNCTION timer : LongInt;
{ Returns the number of seconds after midnight }
VAR
  h,m,s,s100 : word;

BEGIN
  gettime(h,m,s,s100);
  timer  :=  h*longint(3600)+longint(60)*m+longint(1)*s;
END;

FUNCTION Time:String;
VAR
  h,m,s,s100:word;
  ampm:string[2];
BEGIN
  GetTime(h,m,s,s100);
  IF h>=12
    THEN ampm:='PM'
    ELSE ampm:='AM';
  IF h>12 THEN dec(h,12)
  ELSE IF h=0 THEN h:=12;
  Time:=cstr(h)+':'+ZExpand(m,2)+':'+ZExpand(s,2)+' '+ampm;
END;

END.