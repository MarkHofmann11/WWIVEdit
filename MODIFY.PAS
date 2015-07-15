PROGRAM Modify;
{ Program to modify the hard coded colormap in WWIVEdit 2.3 }
USES
  CRT,Cursors;

CONST
  K_Left = #128;
  K_Right= #129;
  K_Up   = #130;
  K_Down = #131;
  K_Home = #132;
  K_End  = #133;
  K_Ins  = #134;
  K_Del  = #135;
  K_F1   = #136;
  K_F2   = #137;
  K_F3   = #138;
  K_F4   = #139;
  K_F5   = #140;
  K_F6   = #141;
  K_F7   = #142;
  K_F8   = #143;
  K_F9   = #144;
  K_F10  = #145;
  K_None = #255;
  IDColorMap: string[9]='IDCLRMAP*';
  ColorMap : Array[0..255] OF Byte = (
    007,007,007,007,007,007,007,007,007,007, {  0..  9}
    007,007,007,007,007,007,007,007,007,007, { 10.. 19}
    007,007,007,007,007,007,007,007,007,007, { 20.. 29}
    007,007,007,007,007,007,007,007,007,007, { 30.. 39}
    007,007,007,007,007,007,007,007,007,011, { 40.. 49}
    014,005,031,002,140,009,007,007,007,007, { 50.. 59}
    007,007,007,007,007,007,007,007,007,007, { 60.. 69}
    007,007,007,007,007,007,007,007,007,007, { 70.. 79}
    007,007,007,007,007,007,007,007,007,007, { 80.. 89}
    007,007,007,007,007,007,007,007,007,007, { 90.. 99}
    007,007,007,007,007,007,007,007,007,007, {100..109}
    007,007,007,007,007,007,007,007,007,007, {110..119}
    007,007,007,007,007,007,007,007,007,007, {120..129}
    007,007,007,007,007,007,007,007,007,007, {130..139}
    007,007,007,007,007,007,007,007,007,007, {140..149}
    007,007,007,007,007,007,007,007,007,007, {150..159}
    007,007,007,007,007,007,007,007,007,007, {160..169}
    007,007,007,007,007,007,007,007,007,007, {170..179}
    007,007,007,007,007,007,007,007,007,007, {180..189}
    007,007,007,007,007,007,007,007,007,007, {190..199}
    007,007,007,007,007,007,007,007,007,007, {200..209}
    007,007,007,007,007,007,007,007,007,007, {210..219}
    007,007,007,007,007,007,007,007,007,007, {220..229}
    007,007,007,007,007,007,007,007,007,007, {230..239}
    007,007,007,007,007,007,007,007,007,007, {240..249}
    007,007,007,007,007,007                  {250..255}
  );

  BufSize=8000;

VAR
  buffer : ARRAY[0..BufSize] OF Byte;

FUNCTION GetKey:char;
VAR
  ch:char;
BEGIN
  ch:=readkey;
  IF ch<>#0 THEN GetKey:=ch
  ELSE BEGIN
    ch:=readkey;
    CASE ch OF
      #75 : GetKey:=K_Left;
      #77 : GetKey:=K_Right;
      #72 : GetKey:=K_Up;
      #80 : GetKey:=K_Down;
      #82 : GetKey:=K_INS;
      #71 : GetKey:=K_Home;
      #79 : GetKey:=K_End;
      #83 : GetKey:=K_Del;
      #59 : GetKey:=K_F1;
      #60 : GetKey:=K_F2;
      #61 : GetKey:=K_F3;
      #62 : GetKey:=K_F4;
      #63 : GetKey:=K_F5;
      #64 : GetKey:=K_F6;
      #65 : GetKey:=K_F7;
      #66 : GetKey:=K_F8;
      #67 : GetKey:=K_F9;
      #68 : GetKey:=K_F10;
    ELSE GetKey:=K_None;
    END;
  END;
END;

PROCEDURE FindID(VAR f:file; s:string);
VAR
  check : string;
  br,i : integer;
  Count:longint;
  done : boolean;
BEGIN
  count:=0;
  REPEAT
    write('.');
    blockread(f,buffer,sizeof(buffer),br);
    check:='';
    i:=0;
    WHILE (i<=BufSize) AND (Check<>S) DO
    BEGIN
      IF buffer[i]=length(s) THEN
        move(buffer[i],check,length(s)+1);
      inc(i);
    END;
    IF check<>s THEN count:=count+br
    ELSE count:=count+i-1;
  UNTIL (check=s) OR (br=0);
  seek(f,count);
  blockread(f,check,length(s)+1);
END;

PROCEDURE EditColor;
VAR
  fg,bg,blink:integer;
  ch,ch1:char;
  c:integer;
BEGIN
  c:=0;
  REPEAT
    fg:=Colormap[c] AND $f;
    bg:=(colormap[c] AND $70) div 16;
    blink:=colormap[c] AND $80;
    Gotoxy(1,24);
    TextAttr:=7;
    write('Current FG=',fg:2,' Current BG=',bg,' Blnk=');
    IF blink>0 THEN write('Y') ELSE write('N');
    writeln(' F1=FG- F2=FG+ F5=BG- F6=BG+ F9=Blnk F10=Res');
    REPEAT
    Gotoxy(1,24);
    TextAttr:=7;
    write('Current FG=',fg:2,' Current BG=',bg,' Blnk=');
    IF blink>0 THEN write('Y') ELSE write('N');
      Textcolor(fg+blink);
      Textbackground(bg);
      gotoxy(1,25);
      write('This is a TEST of the CURRENT CoLoR!');
      gotoxy((c mod 13)*6+4,c div 13+1);
      ch:=GetKey;
      CASE ch OF
         K_F1 : fg:=(fg-1) mod 16;
         K_F2 : fg:=(fg+1) mod 16;
         K_F5 : bg:=(bg-1) mod 8;
         K_F6 : bg:=(bg+1) mod 8;
         K_F9 : IF blink=128 THEN blink:=0 ELSE blink:=128;
         K_F10: BEGIN
                  fg:=ColorMap[c] AND $f;
                  bg:=(ColorMap[c] AND $70) DIV 16;
                  blink:=ColorMap[c] AND $80;
                END;
      END;
    UNTIL ch IN [#13,#27,K_Up,K_Down,K_Left,K_Right];
    ColorMap[c]:=blink+bg shl 4+fg;
    TextAttr:=7;
    gotoxy(1,25); clreol;
    gotoxy(1,24); clreol;
    gotoxy((c mod 13)*6+1,c div 13+1);
    textattr:=ColorMap[c];
    IF NOT (c IN [7,8,10,11,12,13]) THEN ch1:=chr(c) ELSE ch1:=#32;
    write(c:4,' ',ch1);
    CASE ch OF
      K_up: BEGIN
              c:=c-13;
              IF c<0 THEN c:=260+c;
            END;
      K_Down: BEGIN
              c:=c+13;
              IF c>255 THEN c:=260-c;
            END;
      K_Right:BEGIN
              inc(c);
              IF c>255 THEN c:=0;
            END;
      K_Left:BEGIN
              dec(c);
              IF c<0 THEN c:=255;
            END;
    END;
  UNTIL ch=#27;
END;


VAR
  f:file;
  p:longint;
  i:integer;
  ch:char;
  cc:integer;

BEGIN
  clrscr;
  assign(f,'WWIVEDIT.EXE');
  reset(f,1);
  write('Searching for color map');
  FindID(f,IDColorMap);
  p:=filepos(f);
  Blockread(f,ColorMap,Sizeof(colormap));
  clrscr;
  FOR i:=0 TO 255 DO
  BEGIN
    textattr:=colormap[i];
    IF NOT (i IN [7,8,10,11,12,13]) THEN ch:=chr(i) ELSE ch:=#32;
    write(i:4,' ',ch);
    IF (i+1) mod 13=0 THEN writeln;
  END;
  gotoxy(1,22);
  FOR i:=0 TO 15 DO
  BEGIN
    TextColor(i);
    write('ллллл');
  END;
  TextColor(7);
  TextBackground(0);
  FOR i:=0 TO 15 DO
    write(i:3,'  ');
  cc:=0;
  EditColor;
  clrscr;
  writeln('Saving color map...');
  seek(f,p);
  Blockwrite(f,colormap,sizeof(colormap));
END.
