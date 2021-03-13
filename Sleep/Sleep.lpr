{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - Sleep example'}

{$R Sleep.Res}

program _Sleep;
  { Win32 API function - Sleep example                                        }

  { NOTE: This example should be run with the Windows System Monitor up and   }
  {       showing the amount of Kernel processor usage.                       }

  {       Also, it is important not to call Delphi/Pascal library function in }
  {       a thread that is created using CreateThread.  This is because when  }
  {       a thread is created this way, the Delphi/Pascal library is unaware  }
  {       that the program is multithreaded and does not take the necessary   }
  {       measures to make the library functions multi thread safe.           }
  {---------------------------------------------------------------------------}

//{$DEFINE NOPAINT }  { define to prevent displaying the counter              }

uses Windows, Messages, Resource, SysUtils, CommCtrl;

const
  AppNameBase  = 'Sleep';

  {$ifdef WIN64}
    Bitness64  = ' - 64bit';
    AppName    = AppNameBase + Bitness64;
  {$else}
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

var
  SleepTime    : DWORD = 0;     { set by the main thread                      }
  Counter      : DWORD = 0;     { incremented by the counter thread           }

{-----------------------------------------------------------------------------}
{ counter thread function                                                     }

function CounterThread(Wnd : DWORD) : DWORD; stdcall;
const
  FONT_HEIGHT = 20;

var
  ClientRect  : TRECT;

begin
  CounterThread := 0;           { failure code                                }

  if Wnd = 0 then exit;

  { invalidate only the area that must be updated.  This prevents unnecessary }
  { flicker.                                                                  }

  GetClientRect(Wnd, ClientRect);
  with ClientRect do
  begin
    Top    := ClientRect.Bottom div 2 - FONT_HEIGHT;
    Bottom := Top + FONT_HEIGHT;
  end;

  while TRUE do
  begin
    inc(Counter);

    InvalidateRect(Wnd, @ClientRect, TRUE);

    Sleep(SleepTime);           { worked hard, take a nap                     }
  end;

  CounterThread := 1;           { success code                                }
end;

{-----------------------------------------------------------------------------}
{ main window procedure executed by the initial thread                        }

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }

const
  SLEEP_CALL  = 'Sleep (Milliseconds : DWORD);';

var
  ps          : TPAINTSTRUCT;
  Buf         : packed array[0..255] of char;
  ClientRect  : TRECT;
  TextSize    : TSIZE;

  ThreadId    : DWORD;
  Thread      : THANDLE;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { set the initial value of the sleep time and its corresponding menu    }
      { item.                                                                 }

      PostMessage(Wnd, WM_COMMAND, IDM_ZERO, 0);

      {-----------------------------------------------------------------------}
      { create the counter thread                                             }

      Thread :=
        CreateThread(nil,              { no thread security attributes        }
                     0,                { default stack size                   }
                     @CounterThread,   { the thread code to be executed       }
                     pointer(Wnd),     { pass the window to the counter       }
                     0,                { default creation flags               }
                     ThreadId);

      { we don't need the Thread handle so we close it                        }

      CloseHandle(Thread);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      {$IFDEF NOPAINT } { don't paint anything }
         EndPaint(Wnd, ps);
         exit;
      {$ENDIF}

      GetClientRect(Wnd, ClientRect);

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetTextAlign(ps.hdc, TA_BOTTOM or TA_CENTER);

      StrFmt(Buf, '%d', [Counter]);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      {-----------------------------------------------------------------------}
      { draw the function call label                                          }

      lstrcpy(Buf, SLEEP_CALL);

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf),
                           TextSize);

      TextOut(ps.hdc,
              ClientRect.Right div 2,
              ClientRect.Bottom - TextSize.cy,
              Buf,
              lstrlen(Buf));

      {-----------------------------------------------------------------------}
      { we're done drawing                                                    }

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_ZERO..IDM_TWENTY:
        begin
          { note that the sleep time value has been embedded in the           }
          { menu id as (100 + SleepTime).                                     }

          SleepTime := LOWORD(wParam) - IDM_ZERO;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_ZERO,
                             IDM_TWENTY,
                             LOWORD(wParam),
                             MF_BYCOMMAND);
          exit;
        end;

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