{$APPTYPE        CONSOLE}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - NtDll - RtlGetVersionNumbers example'}

{$R RtlGetNtVersionNumbers.res}

program _RtlGetVersionNumbers;


uses Windows,
     Messages,                           { required by CONSOLE.INC below      }
     Resource
     ;

const
  AppNameBase = 'RtlGetVersionNumbers';

  {$ifdef WIN64}
    Bitness64  = ' - 64bit';
    AppName    = AppNameBase + Bitness64;
  {$else}
    Bitness32  = ' - 32bit';
    AppName    = AppNameBase + Bitness32;
  {$endif}


const
  BUILD_FREE_VAL = word($F000);

  BUILD_FREE_STR = 'Free build';
  BUILD_CHKD_STR = 'Checked build';

  BuildString    : pchar = BUILD_FREE_STR;


var
  MajorVersion   : DWORD;
  MinorVersion   : DWORD;
  BuildNumberRec : packed record
                     BuildNumber : word;
                     Build       : word;
                   end;
  Build          : DWORD absolute BuildNumberRec;

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;

  procedure RtlGetNtVersionNumbers(var MajorVersion : DWORD;
                                   var MinorVersion : DWORD;
                                   var Build        : DWORD);
            stdcall; external 'ntdll.dll';
{$endif}


{$ifdef FPC}
  procedure RtlGetNtVersionNumbers(out MajorVersion : DWORD;
                                   out MinorVersion : DWORD;
                                   out Build        : DWORD);
            stdcall; external 'ntdll.dll';
{$endif}

const
  { constants required by CONSOLE.INC below                                   }

  AboutBox       = 'AboutBox';
  APPICON        = 'APPICON';

  ABOUT_STRING   = 'About RtlGetVersionNumbers ...';

{$include CONSOLE.INC}

begin
  SetupConsoleWindow(TRUE);

  RtlGetNtVersionNumbers(MajorVersion, MinorVersion, Build);

  writeln;
  writeln('Major version : ', MajorVersion);
  writeln('Minor version : ', MinorVersion);
  writeln('Build  number : ', BuildNumberRec.BuildNumber);

  if BuildNumberRec.Build <> BUILD_FREE_VAL then BuildString := BUILD_CHKD_STR;
  writeln('Free/Checked  : ', BuildString);

  writeln;
  writeln('Press ENTER/RETURN to end this program');
  readln;

  SetupConsoleWindow(FALSE);
end.