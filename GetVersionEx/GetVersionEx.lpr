{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetVersionEx example'}

{$R GetVersionEx.Res}

program _GetVersionEx;
  { Win32 API function - GetVersionEx example                                 }

uses Windows, Messages, Resource, SysUtils;

const
  AppNameBase  = 'GetVersionEx';

  {$ifdef WIN64}
    Bitness64  = ' - 64bit';
    AppName    = AppNameBase + Bitness64;
  {$else}
    Bitness32  = ' - 32bit';
    AppName    = AppNameBase + Bitness32;
  {$endif}

  AboutBox   = 'AboutBox';
  APPICON    = 'APPICON';
  APPMENU    = 'APPMENU';

{-----------------------------------------------------------------------------}

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;
{$endif}

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

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  GetVersionEx_Call
    = 'GetVersionEx (var OSVersionInfo : TOSVERSIONINFO) : BOOL;';

  Labels : packed array[1..6] of pchar =
    (
     'dwOSVersionInfoSize : ',
     'dwMajorVersion : ',
     'dwMinorVersion : ',
     'dwBuildNumber : ',
     'dwPlatformId : ',
     'szCSDVersion : '
    );

  Values  : packed array[1..6] of packed array[0..255] of char =
    (#0, #0, #0, #0, #0, #0);

  MARGIN  = -35;                { to make the output look centered            }

var
  ps                 : TPAINTSTRUCT;
  ClientRect         : TRECT;
  Buf                : packed array[0..255] of char;
  TextSize           : TSIZE;

  { NOTE: GetVersionEx can use a TOSVERSIONINFOEX structure which has         }
  {       additional information about the Windows version but, it is         }
  {       questionable whether or not the additional information is useful.   }
  {       For that reason, TOSVERSIONINFO seems to be a better and simpler    }
  {       choice.                                                             }

  OSVersionInfo      : TOSVERSIONINFO;

  { we overlay the previous OSVersionInfo with an array of DWORDs so we can   }
  { format the first 4 values using a loop instead of individual statements.  }
  { The last two fields will be formatted separately.                         }

  OSVersionInfoTbl   : packed array[1..6] of DWORD absolute OSVersionInfo;

  I                  : DWORD; { to "walk" the above array                     }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { clearing the buffer passed to GetVersionEx is not required but can    }
      { make debugging easier.                                                }

      ZeroMemory(@OSVersionInfo, sizeof(OSVersionInfo));  { not required      }

      {-----------------------------------------------------------------------}
      { setting the dwOSVersionInfoSize field _is_ required before calling    }
      { GetVersionEx. The function will fail if the size is not as expected   }

      OsVersionInfo.dwOSVersionInfoSize := sizeof(OSVersionInfo);
      GetVersionEx(OsVersionInfo);

      {-----------------------------------------------------------------------}
      { format the values returned in the OSVersionInfo record. The last      }
      { three values of the array will be custom formatted separately.        }

      for I := low(OSVersionInfoTbl) to high(OSVersionInfoTbl) - 3 { last 3   }
       do StrFmt(Values[I], '%d', [OSVersionInfoTbl[I]]);

      { format the build number                                               }

      I := high(OSVersionInfoTbl) - 2;    { build number                      }
      with OSVersionInfo do
      begin
        StrFmt(Values[I],
               '%d.%d   %d',
               [HIBYTE(HIWORD(dwBuildNumber)),    { major version             }
                LOBYTE(HIWORD(dwBuildNumber)),    { minor version             }
                LOWORD(dwBuildNumber)]);          { actual build number       }
      end;

      { format the Platform id                                                }

      I := high(OSVersionInfoTbl) - 1;    { platform id                       }

      case OSVersionInfo.dwPlatformId of
        VER_PLATFORM_WIN32S:
            lstrcpy(Values[I], 'VER_PLATFORM_WIN32s');

        VER_PLATFORM_WIN32_WINDOWS:
            lstrcpy(Values[I], 'VER_PLATFORM_WIN32_WINDOWS');

        VER_PLATFORM_WIN32_NT:
            lstrcpy(Values[I], 'VER_PLATFORM_WIN32_NT');
      else
            lstrcpy(Values[I], 'VER_PLATFORM_UNKNOWN');
      end;

      { copy the additional info field into our values buffer                 }

      I := high(OSVersionInfoTbl);        { additional info field             }
      lstrcpy(Values[I], OSVersionInfo.szCSDVersion);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize); { get the font height   }

      {-----------------------------------------------------------------------}
      { output the labels and their corresponding values                      }

      SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);
      for I := low(Labels) to high(Labels) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - 4) * TextSize.cy,
                Labels[I],
                lstrlen(Labels[I]));
      end;

      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

      for I := low(Values) to high(Values) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - 4) * TextSize.cy,
                Values[I],
                lstrlen(Values[I]));
      end;

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      lstrcpy(Buf, GetVersionEx_Call);

      { calculate the size of the output string                               }

      TextOut(ps.hdc,
              ClientRect.Right div 2,
              ClientRect.Bottom - TextSize.cy,
              Buf,
              lstrlen(Buf));

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
  cls.cbSize          := sizeof(TWndClassEx);         { must be initialized   }

  if not GetClassInfoEx (hInstance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;            { qualify instance!     }
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, idc_arrow);
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
  else InitAppClass := true;
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
                        ws_visible,             { make showwindow unnecessary }
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        400,                    { window width                }
                        250,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        hInstance,              { instance handle             }
                        nil);                   { parameter sent to WM_CREATE }

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
