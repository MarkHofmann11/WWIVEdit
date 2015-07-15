{{$DEFINE DEBUG}       { Remove first comment symbol to make actually define it }
{{$DEFINE BETA}
{$DEFINE DISTRIBUTION}
{$DEFINE OVERLAY}      { UnDefine if you don't want overlays }
{$DEFINE VERSION_2_5}  { Doesn't do anything... Just there so you know what version it is }

{$IFNDEF DISTRIBUTION}
{$DEFINE P286}
{$ELSE}
{$UNDEF DEBUG}
{$ENDIF}

{$M 32000,0,655360}

{$IFDEF P286}{$G+}{$ENDIF}

{$IFDEF DEBUG}
{$R+,V-,S+,B-,E-,N-,D+,L+,X+} { These were used to find a bunch of little bugs :-)  }
{$ELSE}
{$R-,V-,S-,B-,E-,N-,D-,L-,X+} { These Optomize things as much as possible }
{$ENDIF}

{$IFDEF BETA}{$S+}{$ENDIF}

{$IFDEF CAN_OVERLAY}
{$O+}
{$ENDIF}
{$DEFINE USE_EMS}