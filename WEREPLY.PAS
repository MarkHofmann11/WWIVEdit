UNIT WEReply;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

INTERFACE

FUNCTION HandleReply:Boolean;

IMPLEMENTATION

USES WELine, WEVars, WEInput, WEOutput,WEUser,WEEsm;

FUNCTION HandleReply:Boolean;
VAR
  l:LineType;
  s:string;
  typ:integer;
  ch:char;
BEGIN
  Typ:=Info.AskReply;
  IF Typ>Setting.ReplyType THEN Typ:=Setting.ReplyType;

  IF (typ=2) OR
     ((typ=1) AND ((pos('@',Destination)>0) OR (pos('#',Destination)>0))) THEN
  BEGIN
    StatusLine3(Gets(XSTR+57));
    REPEAT
      ch:=ReadSet(['Y','N','M','Q','D','?',#27,#13]);
      IF ch='?' THEN
        statusline3(Gets(XSTR+58))
      ELSE IF (ch='Q') OR (ch=#27) THEN BEGIN
        HandleReply:=FALSE;
        StatusLine3('');
      END ELSE BEGIN
        s:=Gets(XSTR+59);
        IF ch='Y' THEN s:=s+Gets(XStr+60)
        ELSE IF ch='N' THEN s:=s+Gets(XSTR+61)
        ELSE IF ch='M' THEN s:=s+Gets(XSTR+62)
        ELSE s:='';
        IF s<>'' THEN
        BEGIN
          StringToLine(s,l);
          InsertLine(1,l);
          InitLine(l);
          InsertLine(2,l);
        END;
        HandleReply:=TRUE;
      END;
    UNTIL ch<>'?';
  END;
END;

END.
