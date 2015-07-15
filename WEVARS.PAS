UNIT WEVars;
{$I WEGLOBAL.PAS}
{ -- This is the Global Variables and Types unit of WWIVEdit 2.4
  -- Last updated : 8/10/92
  -- Written By:
  --   Adam Caldwell
  --
  -- This code is Public Domain.
  --
  -- }

INTERFACE

TYPE
  EdFun = Byte;
{ These are the Editor functions that I have defined so far
  If you want to add another one, do the following:
    1. Give it an identifier (below)
    2. In WESETUP, in the function FINDFUN(), add a "description" of it
       that will be used in the .KEY files
    3. In WEFUNCT, in DoFun(), add into the CASE statement code to handle
       your new function.
    4. (optional) also in WEFUNCT, in LineEdit(), add the same code
       This will allow your new function to be used in places where only
       a line is being edited (<E>dit in spell checker, Insert File, etc)
}
CONST { Next = 63 }
{ -- Internal  Functions -- }
  None           = 0;
  InsertChar     = 1;
  InsertMCI      = 2;
{ -- Cursor movement -- }
  Up             = 3;
  Down           = 4;
  Left           = 5;
  Right          = 6;
  WordLeft       = 7;
  WordRight      = 8;
  TopPage        = 9;
  BottomPage     = 10;
  Home           = 11;
  _End           = 12;
  Top            = 13;
  Bottom         = 14;
  PgUp           = 15;
  PgDn           = 16;
  Jump           = 17;
{ -- Text Deletion -- }
  BackSpace      = 18;
  DelChar        = 19;
  DelLine        = 20;
  DelSOL         = 21;
  DelEOL         = 22;
  EraseWordLeft  = 23;
  EraseWordRight = 24;
{ -- Text Insertion and formatting -- }
  InsertLiteral  = 25;
  Tab            = 26;
  InsLine        = 27;
  InsLineAfter   = 28;
  Enter          = 29;
  CenterLine     = 30;
  InsertFile     = 31;
  ToggleInsert   = 32;
  FindAndReplace = 33;
{ -- Block Functions -- }
  MarkStart      = 34;
  MarkEnd        = 35;
  DeleteBlock    = 36;
  MoveBlock      = 37;
  CopyBlock      = 38;
  ShowBlockStat  = 39;
  SaveBlock      = 40;
{ -- Information Functions --}
  FindLast       = 41;
  RedisplayAll   = 42;
  ToggleFullScreen=43;
  DisplayAlt     = 44;
  GetHelp        = 45;
  Find           = 46;
  ToggleWhere    = 47;
{ -- Control Functions --}
  QuietExitAndSaveAnony = 48;
  AbortPost      = 49;
  ExitAndSave    = 50;
  NormalExit     = 51;
  QuietExitAndSave = 52;
  QuietExitAndSaveNonAnony = 53;
  SaveAndContinue = 54;
  Mouse          = 55;
  SaveAs         = 62;
{ -- WWIV Specific things -- }
  WWIVColor      = 56;
  WWIVMacro1     = 57;
  WWIVMacro2     = 58;
  WWIVMacro3     = 59;
  GoBack         = 60;
  InvokeQuoter   = 61;
{ -- End of Editing Functions -- }
  LastDefined    = 62;
  XDefaults = LastDefined+1;
  XTags     = LastDefined+8;
  XStr = LastDefined+15;

  VERSION    = 'Version 3.00';
  VER_ID     = '3.00';
  QuoteFile  = 'QUOTES.TXT';
  QuoteTmp   = 'QUOTES.OUT';
  DefExt     = '.DEF'; { Definitions file extention     }
  SettingExt = '.SET'; { Binary Settings file extention }
  BindingExt = '.KEY'; { Key bindindings Extention      }
  KeyExt     = '.KBD'; { Binary key bindings exetention }
  BindingMaxLength = 15;{ Maximum length for a key binding }
  MAX_STATES = 4;
{$IFDEF DEBUG}
  AbsoluteMaxLines = 4000;
  MaxPhyLines= 25;
{$ELSE}
  AbsoluteMaxLines = 4000;
  MaxPhyLines= 50;
{$ENDIF}
  MaxLineLen = 80;
  NormalReturnCode       = 0;   { The result code for '/ES' and ESC-S }
  NonAnonymousReturnCode = -1;  { The result code for '/ESN' }
  AnonymousReturnCode    = 1;   { The result code for '/ESY' }

  IO_DOS = 0;
  IO_Direct = 1;
  IO_Fossil = 2;
  IO_Interrupt = 3;

  BBS_None      = 0;
  BBS_WWIV      = 1;
  BBS_Telegard  = 2;
  BBS_Eclipse   = 3;
  BBS_Waffle    = 4;
  BBS_VBBS      = 5;

  StripColor = 1;

  EnterKey = ^M;

TYPE
  strng = string[MaxLineLen+1];
  linetype = RECORD  { Each line has a color map and a text part }
    l      : strng;
    HardCR : Boolean;
    c      : strng;
  END;

  tbuffer = ARRAY[0..AbsoluteMaxLines] OF ^linetype;

  textbuffer = ^tbuffer; { The Text buffer is allocated from the heap }
  screenbuffer = ARRAY[0..MaxPhyLines] OF linetype;

  ExtTrans = array[1..3] OF char;
  TransFile = FILE of ExtTrans;
  CharSet = SET of Char;
  PROC = PROCEDURE;

  CharFunction = FUNCTION : char;

  KeyInfoRec = RECORD
    Description : String[80];
    NEscaped    : Byte;
    Escaped_Keys: ARRAY[1..5] OF Char;
    Local_only  : BOOLEAN;
    Min_SL      : word;
  END;

  KeyBindingP= ^KeyBinding;
  KeyBinding = RECORD
    Fun  : EdFun;
    Keys : string[BindingMaxLength];
  END;

  SettingRec = RECORD
    Version : String[4];
    Local,
    DisableUserTag,
    DirectVideo,
    KeyBios,
    Mouse,
    Fossil,
    WWIVEditMacrosOk,
    AllowColorChangeInTitle,
    SmoothScroll,
    ChangeCursor,
    DisableBBSTag, PersonalDicAllowed : BOOLEAN;
    Colors,MCI : CharSet;
    Lines : ARRAY[1..11] OF integer;
    Ticks : Integer;
    ChatMask, TabStop, BoardEditDisable, mono,
    BBS, DOSMask, Comport, ChatMode  : Byte;
    Divider,
    NoTagBBS, NoTagPersonal : STRING[12];
    ResultType, SetupType, AddSL, ReplyType, Quoter : Byte;
    WarnTime, DisconnectTime : integer;
    DictDir : String[80];
    InsertDir:String[80];
    QuoterOption : WORD;
    Prefix : String[10];
  END;

  KeyBindingArray = ARRAY[1..3000] OF Byte;

CONST { These are pre-initialized Variables, not Constants }
  SaveScreen : POINTER = NIL;
  SearchString  : string[80] = '';         { The last search string }
  ReplaceString : string[80] = '';         { The replace string }
  SearchOps : String[4] = '';              { The last search options }
  ParameterFileName:string[12]='CHAIN.TXT';
  TabStop:byte = 5;      { Tab Stops (+1) are divisible by this number }
  BlockStart: integer = 0;                 { Block Marker Start (line number)}
  BlockEnd  : integer = 0;                 { Block Marker End (line number)  }
  cx : integer = 1;
  cy : Integer = 1;      { The x and y coords of the cursor }
  ScreenState : Byte=0;  { 0=With header and Maxlines, 1= Nothing on screen }
  WindowTop : integer=5; { defines the Window Top -- physical screen line }
  ViewTop : integer=1;   { defines the Viewport Top -- physical Text line }
  CurrentColor: char='0';{ the color attribute to assign to the current character }
  Display : POINTER = ptr($b800,0);
  HighLine : integer=0;  { The highest line currently in use }
  InsertMode : boolean = TRUE;  { Whether or not we are in insert mode }
  DisplayColor : char = '0'; { The current state of ANSIC }

  IOType : byte = IO_DOS;
  MinScrollLeft : byte = 3; { Defines the minimum number of lines of the last }
                            { "page" to be left when scrolling }

  NBindings : integer = 0;  { The number of key bindings.  This MUST be initialized
                              to 0 }
  BindingSize : integer =0;

  TitleChanged : boolean = false;
  LocationOverride : boolean = false;
  LocationOverride_X : integer =0;
  LocationOverride_Y : integer =0;
  ErrorLevel : integer=0;



VAR
  screen : ScreenBuffer; { An image of what should appear on the screen }
  line : TextBuffer;     { The physical text }
  MaxLines : integer;    { The Maximum number of lines as passed on command line }
  LineLen : integer;     { The Maximum line length as passed on command line }
  WindowBottom : integer;{ defines the Window Bottom -- physical screen line }
  ViewBottom : integer;  { defines the Viewport Bottom -- physical Text line }
  WindowHeight:integer;  { how tall the physical window is }
  ScreenHeight:byte;     { the maximum height of the screen }
  FileName : string;     { the name of the input/output file }
  Title : string;        { the title of the mesage }
  Destination : string;  { where the message is going }
  LastKey  : LongInt;    { used to time-out the editor }
  TransTable : TransFile;{ Used for Local Extended Key Macros }
  FileThere : Boolean;   { If a file got loaded in at the beginning.  If so, then no tag lines are added }
  AfterNext : PROC;      { This is a hook into the ReadKey procedure.  This
                           procedure will be executed after the next keystroke
                           is accepted.  This is used to Clear the statline, but
                           can have other functions }
  BeforeNext: PROC;


  incom       : boolean; { TRUE if user is calling remotely          }

  FG, BG      : byte;    { Foreground and Background colors          }
  StartupDir  : string;  { The directory of the program }
  ConfigDir   : string;
  DictDir     : string;
  AllowTitleChange : Boolean;

  Setting : SettingRec;
  KeyBindings : ^KeyBindingArray;

  KeyStatusFlag : BYTE ABSOLUTE $40:$17;
  ScreenSize : WORD ABSOLUTE $40:$4C;

  SettingName:string;
  KeyName:string;
  Key_Description : KeyInfoRec;

  ESC_Ticks : Word;
  Escaped : string[5];

PROCEDURE DoNothing;

IMPLEMENTATION

PROCEDURE DoNothing; BEGIN END;

END.

