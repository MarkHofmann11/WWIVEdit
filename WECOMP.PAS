UNIT WEComp;
{$DEFINE CAN_OVERLAY}
{$I WEGLOBAL.PAS}

{ --
  -- Compression Module for WWIVEdit 2.4
  -- This code is Copyright (c) 1991-1992 Adam Caldwell
  -- It may be freely distributed so long as no fee is charged for it.
  --
  -- }

INTERFACE
FUNCTION Squash(s:string):string;
FUNCTION UnSquash(s:string):string;

IMPLEMENTATION

TYPE
  StringTable = ARRAY[0..255] OF String[4];

CONST
  ST : StringTable =
('''','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O',
'P','Q','R','S','T','U','V','W','X','Y','Z','&','.',',',':',';',
'"','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o',
'p','q','r','s','t','u','v','w','x','y','z','!','~',' ','-','?',
'mi','om','ni','ho','ce','as','ha','di','ur','pe','na','ac','il','ea','ia','lo',
'ol','nd','ve','th','ca','ll','ou','si','me','io','ng','ch','to','et','se','us',
'he','tr','el','ta','es','ma','ne','li','it','is','de','la','co','ro','ic','nt',
'ri','or','al','st','ti','ra','ar','at','re','le','en','te','on','an','in','er',
'met','ran','cha','den','han','ind','mon','ica','rea','ary','che','ack','ite','lle','ria','nte',
'one','rin','ers','par','tan','age','der','ari','ten','ish','art','ere','mat','tat','son','nce',
'ber','eri','ome','ect','sto','tro','pre','ina','lat','int','ort','nti','ast','era','gra','com',
'min','ess','ide','ard','ell','lin','tin','ton','ric','all','lan','ian','sti','str','ill','sta',
'tri','rat','res','ver','pro','ist','men','est','ste','the','ive','per','abl','ran','tor','her',
'man','tra','tic','and','ati','ine','con','tio','ous','ant','ble','ter','ion','ent','ing','ate',
'inte','ttin','ator','cont','olog','stra','nter','tric','ress','ater','tory','tran','tati','land','nate','ance',
'ment','enti','ting','comp','tive','ight','ible','late','ious','ster','ther','sion','rate','atio','able','tion');

  Start : ARRAY[0..4] OF byte= ( 0,16*4-1,16*8-1,16*14-1,255);


FUNCTION Squash1(s:string):string;
VAR
  Temp : String;
  i:integer;
BEGIN
  Temp:='';
  REPEAT
    i:=length(s);
    IF i>4 THEN i:=4;
    i:=start[i];
    WHILE copy(s,1,length(st[i]))<>st[i] DO
      dec(i);
    temp:=temp+chr(i);
    delete(s,1,length(st[i]));
  UNTIL s='';
  Squash1:=Temp;
END;

FUNCTION Squash2(s:string):string;
VAR
  Temp : String;
  i:integer;
BEGIN
  Temp:='';
  REPEAT
    i:=length(s);
    IF i>4 THEN i:=4;
    i:=start[i];
    WHILE copy(s,length(s)-length(st[i])+1,length(st[i]))<>st[i] DO
      dec(i);
    temp:=chr(i)+temp;
    delete(s,length(s)-length(st[i])+1,length(st[i]));
  UNTIL s='';
  Squash2:=Temp;
END;

FUNCTION Squash3(s:string):string;
{ -- String replacement based on random replacement... On my test data, this
  -- algorithm only provided a smaller result on a few pieces of data, hence
  -- I have ignored it to get better performance }
VAR
  Temp : String;
  i, j,p :integer;
  t : ARRAY[1..100] OF integer;
  cleft : integer;
BEGIN
  FOR i:=1 TO length(s) DO
    t[i]:=-1;
  cleft:=length(s);
  REPEAT
    i:=255;
    WHILE pos(st[i],s)=0 DO
      dec(i);
    p:=pos(st[i],s);
    t[p]:=i;
    FOR j:=p TO p+length(st[i])-1 DO
    BEGIN
      s[j]:=#0;
      dec(cleft);
    END;
  UNTIL cleft=0;
  temp:='';
  FOR i:=1 TO length(s) DO
    IF t[i]>=0 THEN temp:=temp+chr(t[i]);
  Squash3:=temp;
END;

FUNCTION Squash(s:string):string;
VAR
  s1,s2:string;

BEGIN
  s1:=squash1(s);
  s2:=squash2(s);
  IF length(s1)<=length(s2)
    THEN squash:=s1
    ELSE squash:=s2;
END;


FUNCTION UnSquash(s:string):string;
{ -- A Lesson in speed... This procedure can be shortened (more or less) to:
  --
  -- FOR i:=1 TO length(s) DO
  --   temp:=temp+st[ord(s[i])];
  --
  -- However, the lower bit of code is approximately 37% faster
  -- For 31,000 runs uncompressing "stattion" [a non-sense word], the above
  -- algorithm took 24 seconds on my test machine.  The code below took only
  -- 15 seconds.
  -- }
VAR
  Temp : String;
  i : integer;
  len, ind,bytes : integer;
BEGIN
  len:=0;
  FOR i:=1 TO length(s) DO
  BEGIN
    ind:=ord(s[i]);
    bytes:=ord(st[ind][0]);
    Move(st[ind][1],Temp[len+1],bytes);
    len:=len+bytes;
  END;
  temp[0]:=chr(len);
  UnSquash:=Temp;
END;

END.
