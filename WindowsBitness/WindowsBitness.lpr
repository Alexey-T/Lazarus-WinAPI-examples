{$define         DEBUG}     { to cause a breakpoint in WM_CREATE handler      }

{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - WindowsBitness example'}

{$R WindowsBitness.Res}

program _WindowsBitness;
  { Win32 technique - WindowsBitness example                                  }

uses Windows,
     Messages,
     Resource
     ;

const
  AppNameBase  = 'WindowsBitness';

  {$ifdef WIN64}                         { heading for 64 bit                 }
    Bitness64  = ' - 64bit';
    AppName    = AppNameBase + Bitness64;
  {$else}                                { heading for 32 bit                 }
    Bitness32  = ' - 32bit';
    AppName    = AppNameBase + Bitness32;
  {$endif}

  AboutBox     = 'AboutBox';
  APPICON      = 'APPICON';
  APPMENU      = 'APPMENU';

{-----------------------------------------------------------------------------}

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;
{$endif}

{$include ImageHeaders.inc}

function IsDebuggerPresent                      { missing in Delphi 2         }
         : BOOL; stdcall; external 'kernel32';

const
  LOAD_LIBRARY_AS_IMAGE_RESOURCE = $20;         { missing in FPC and Delphi 2 }

{-----------------------------------------------------------------------------}

function About(DlgWnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
begin
  About := ord(TRUE);

  case Msg of

    WM_INITDIALOG: exit;

    WM_COMMAND:
    begin
      if (LOWORD(wParam) = IDOK) or (LOWORD(wParam) = IDCANCEL) then
      begin
        EndDialog(DlgWnd, ord(TRUE));

        exit;
      end;
    end;
  end;

  About := ord(FALSE);
end;

{-----------------------------------------------------------------------------}

function GetModuleBitness(Module : HMODULE) : integer;
var
  DosHeader      : PIMAGE_DOS_HEADER;
  NtHeader       : PIMAGE_NT_HEADERS;
  OptionalHeader : PIMAGE_OPTIONAL_HEADER;

begin
  result := 0;

  HMODULE(DosHeader) := Module;

  { ensure we got a valid PE file                                             }

  if IsBadReadPtr(DosHeader, sizeof(DosHeader^))           then exit;
  if DosHeader^.Signature <> IMAGE_DOS_SIGNATURE           then exit;

  pointer(NtHeader) := pchar(DosHeader) + DosHeader^.OffsetToNewExecutable;

  if IsBadReadPtr(NtHeader, sizeof(NtHeader^))             then exit;

  OptionalHeader := @NtHeader^.OptionalHeader;

  if IsBadReadPtr(OptionalHeader, sizeof(OptionalHeader^)) then exit;

  case OptionalHeader^.Magic of
    IMAGE_NT_OPTIONAL_HDR32_MAGIC : result := 32;
    IMAGE_NT_OPTIONAL_HDR64_MAGIC : result := 64;

    { otherwise leave it at zero                                              }
  end;
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  WindowBitness_Call     = 'Windows bitness';

  Bitness32              = 'This is a 32 bit Windows installation';
  Bitness64              = 'This is a 64 bit Windows installation';

  BitnessUnknown         = 'failed to determine this Windows installation '   +
                           'bitness';

  { initialize to "unknown" until we determine the Windows bitness            }

  Bitness                : pchar = BitnessUnknown;

  CSRSS                  = 'csrss.exe';
  BACKSLASH              = '\';

  _64BIT_POINTER_SIZE    = 8;

  ALIGN64K               = $FFFF0000;

var
  ps                     : TPAINTSTRUCT;
  ClientRect             : TRECT;

  TextSize               : TSIZE;

  CsrssFullpath : packed array[0..511] of char;

  i                      : DWORD;
  CsrssLoadAddress       : HMODULE;
  LoadAddress            : HMODULE;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      {$ifdef DEBUG}
        if IsDebuggerPresent() then DebugBreak();
      {$endif}


      { when using FPC and compiling for 32 bit, ignore the unreachable code  }
      { warning.                                                              }

      if sizeof(pointer) = _64BIT_POINTER_SIZE then
      begin
        { we are a running 64bit program, therefore the Windows installation  }
        { must be 64bit.  Not much to do in this case.                        }

        Bitness := Bitness64;

        exit;                               { we are done!                    }
      end;

      { if we are a 32bit program, we need to find out if this is a 32bit or  }
      { 64bit windows installation.                                           }

      ZeroMemory(@CsrssFullpath, sizeof(CsrssFullpath));
      GetSystemDirectory(CsrssFullpath,
                         sizeof(CsrssFullpath));

      { append CSRSS to the system directory and a backslash if needed        }

      i := lstrlen(CsrssFullpath);

      if CsrssFullpath[i - 1] <> BACKSLASH then
      begin
        { append the backslash                                                }

        lstrcat(CsrssFullpath, BACKSLASH);
      end;

      lstrcat(CsrssFullpath, CSRSS);             { path to CSRSS              }

      { load CSRSS as a data file. At this time, Windows will not apply file  }
      { system redirection when the call to LoadLibraryEx is to load a file   }
      { as a data file.  Therefore csrss.exe should have been found, if it    }
      { wasn't then we are dealing with an unexpected situation in which case }
      { we declare the attempt to determine the O/S as having failed.         }

      { csrss.exe can also be load as an image resource                       }

      CsrssLoadAddress := LoadLibraryEx(CsrssFullpath,
                                        0,
                                        LOAD_LIBRARY_AS_IMAGE_RESOURCE);

      if CsrssLoadAddress = 0 then
      begin
        exit;
      end;

      { because we specified LOAD_LIBRARY_AS_DATAFILE the load address        }
      { returned isn't "quite right".  When LOAD_LIBRARY_AS_DATAFILE is used  }
      { the address points one (1) byte past the actual load address.  We     }
      { need the "real" address, therefore we subtract one (1) from the       }
      { address returned in this case.                                        }

      { when loaded as an image resource the address points two (2) bytes     }
      { past the actual load address.                                         }

      { since Windows aligns all loaded modules to a 64K address, the safest  }
      { way is to get a 64K aligned address is to zero out the lower 16 bits  }

      LoadAddress := CsrssLoadAddress and ALIGN64K;

      { presuming there are only two versions of Windows, a 32 bit version    }
      { and a 64 bit version, the module bitness should be 32 bit, if it      }
      { isn't then we must be running under an unexpected version that is     }
      { neither 32 nor 64 bit.  In that case, the Bitness is left as "unknown"}

      case GetModuleBitness(LoadAddress) of
        32 : Bitness := Bitness32;
        64 : Bitness := Bitness64;
      end;

      FreeLibrary(CsrssLoadAddress);  { we no longer need it                  }

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      {-----------------------------------------------------------------------}
      { output the bitness of this Windows installation as determined during  }
      { WM_CREATE.                                                            }

      GetClientRect(Wnd, ClientRect);

      GetTextExtentPoint32(ps.hdc,
                           Bitness32,               { any text will do        }
                           lstrlen(Bitness32),
                           TextSize);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Bitness,
              lstrlen(Bitness));


      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom - TextSize.cy,
              WindowBitness_Call,
              lstrlen(WindowBitness_Call));

      {-----------------------------------------------------------------------}
      { we're done painting                                                   }

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_ABOUT:
        begin
          DialogBox(hInstance, ABOUTBOX, Wnd, @About);

          exit;
        end; { IDM_ABOUT }

        IDM_EXIT:
        begin
          DestroyWindow(Wnd);

          exit;
        end; { IDM_EXIT }
      end; { case LOWORD(wParam) }
    end; { WM_COMMAND }

    WM_DESTROY:
    begin
      PostQuitMessage(0);

      exit;
    end; { WM_DESTROY }
  end; { case msg }

  WndProc := DefWindowProc (Wnd, Msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function InitAppClass: WordBool;
  { registers the application's window classes                                }
var
  cls : TWndClassEx;

begin
  cls.cbSize          := sizeof(TWndClassEx);           { must be initialized }

  if not GetClassInfoEx (hInstance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := APPMENU;                     { Menu name             }
      lpszClassName   := AppName;                     { Window Class name     }
      hIconSm         := LoadImage(hInstance,
                                   APPICON,
                                   IMAGE_ICON,
                                   16,
                                   16,
                                   LR_DEFAULTCOLOR);
    end; { with }

    InitAppClass := WordBool(RegisterClassEx(cls));
  end
  else InitAppClass := TRUE;
end;

{-----------------------------------------------------------------------------}

function WinMain : integer;
  { application entry point                                                   }
var
  Wnd : hWnd;
  Msg : TMsg;

begin
  if not InitAppClass then Halt (255);  { register application's class        }

  { Create the main application window                                        }

  Wnd := CreateWindowEx(WS_EX_CLIENTEDGE,
                        AppName,                { class name                  }
                        AppName,                { window caption text         }
                        ws_Overlapped       or  { window style                }
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        400,                    { window width                }
                        200,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        hInstance,              { instance handle             }
                        nil);                   { parameter sent to WM_CREATE }

  { a message box indicating failure and the reason for it would be more      }
  { desirable.                                                                }

  if Wnd = 0 then Halt;                         { could not create the window }

  while GetMessage (Msg, 0, 0, 0) do            { wait for message            }
  begin
    TranslateMessage (Msg);                     { key conversions             }
    DispatchMessage  (Msg);                     { send to window procedure    }
  end;

  WinMain := Msg.wParam;                        { terminate with return code  }
end;

begin
  WinMain;
end.
