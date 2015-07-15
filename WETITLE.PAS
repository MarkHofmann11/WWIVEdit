UNIT WETitle;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

INTERFACE

PROCEDURE FindTitle(VAR Title,Destination:string);

IMPLEMENTATION

USES WEVars, WEOutput, WEString, DOS;

TYPE
  BufferLine=String[80];
  heaparray = ARRAY[1..50] OF BufferLine;

FUNCTION WhereY:byte;
VAR
  r:registers;
BEGIN
  r.ah:=3; r.bh:=0; intr($10,r); Wherey:=r.dh+1;
END;

PROCEDURE FindTitleWWIV(VAR Title,Destination:string);
VAR
  i:integer;
  t:text;
  D: DirStr;
  N: NameStr;
  E: ExtStr;
  b: ^heaparray;
  topline : integer;

BEGIN
  Title:='';
  Destination:='';
  topline:=wherey;
  GetMem(b,TopLine*sizeof(BufferLine));
  FOR i:=1 TO TopLine DO
    b^[i]:='';
  {$V-}
  FOR i:=1 TO TopLine-1 DO
  BEGIN
    ReadScreen(B^[i],1,wherey-i);
    StripEndString(B^[i]);
  END;
  {$V+}
  FOR i:=TopLine DOWNTO 1 DO
  BEGIN
    IF CmpLeft(b^[i],'Title') THEN title:=b^[i];
    IF cmpLeft(b^[i],'E-mail') OR
       cmpLeft(b^[i],'Post')   OR
       cmpLeft(b^[i],'Multi')  OR
       cmpLeft(b^[i],'File')   OR
       cmpLeft(b^[i],'[')      OR
       cmpLeft(b^[i],'<')
    THEN
      Destination:=b^[i];
  END;
  IF cmpLeft(Destination,'<') THEN
  BEGIN
    StripEndC(Destination,'>');
    Delete(destination,1,1);
    Destination:='E-mailing '+Destination;  { cheap trick }
  END;
  IF title='' THEN Title:=b^[1];
  IF cmpLeft(title,'Title') THEN delete(title,1,7);
  IF      cmpLeft(Destination,'E-mail') THEN delete(Destination,1,10)
  ELSE IF cmpLeft(Destination,'Multi')  THEN Destination:='Multi-Mail'
  ELSE IF cmpLeft(Destination,'Post')   THEN
       BEGIN
         delete(Destination,1,8);
         StripEndC(Destination,'?');
       END
  ELSE IF cmpLeft(Destination,'File')   THEN
       BEGIN
         delete(Destination,1,10);
         Title:='Text File';
       END
  ELSE IF cmpLeft(Destination,'[') THEN
       BEGIN
         StripEndC(Destination,']');
         delete(Destination,1,1);
         i:=pos('[',Destination);
         IF i>0 THEN delete(Destination,1,i);
       END
  ELSE Destination:='Message Base';
  FreeMem(b,WhereY*sizeof(Line));
END;

PROCEDURE FindTitleTeleguard(VAR Title, Destination:string);
VAR
  i:integer;
  b: ^heaparray;
  topline : integer;
BEGIN
  Title:='';
  Destination:='';
  topline:=wherey;
  GetMem(b,TopLine*sizeof(BufferLine));
  FOR i:=1 TO TopLine DO
    b^[i]:='';
  {$V-}
  FOR i:=1 TO TopLine-1 DO
  BEGIN
    ReadScreen(B^[i],1,wherey-i);
    StripEndString(B^[i]);
  END;
  {$V+}
  Title:='Can''t Tell';
  Destination:='Can''t Tell';
  FOR i:=TopLine DOWNTO 1 DO
  BEGIN
    IF CmpLeft(b^[i],'Enter message') THEN
      title:=copy(b^[i-1],2,length(b^[i-1])-1)
    ELSE IF cmpLeft(b^[i],'To: ') THEN
      Destination:=Copy(b^[i],5,length(b^[i])-4)
    ELSE IF CmpLeft(B^[i],'Enter user') OR CmpLeft(B^[i],'Enter name') THEN
      Destination:=copy(b^[i-1],2,length(b^[i-1])-1);
  END;
  FreeMem(b,TopLine*sizeof(BufferLine));
END;

PROCEDURE FindTitle(VAR Title,Destination:string);
BEGIN
  CASE Setting.BBS OF
    0 : { This shouldn't ever happen };
    1 : FindTitleWWIV(Title,Destination);
    2 : FindTitleTeleguard(Title,Destination);
    3 : { This shouldn't ever happen };
  END;
END;

END.
