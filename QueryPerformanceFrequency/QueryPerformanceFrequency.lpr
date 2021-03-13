{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - QueryPerformanceFrequency example'}

{$R QueryPerformanceFrequency.Res}

program _QueryPerformanceFrequency;
  { Win32 API function - QueryPerformanceFrequency example                    }

uses Windows, Messages, Resource, SysUtils;

const
  AppNameBase  = 'QueryPerformanceFrequency';

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

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }

const
  QueryPerformanceFrequency_Call
    = 'QueryPerformanceFrequency (PerfFrequency : TLargeInteger) : BOOL;';

  Supported              : BOOL          = FALSE;

  {$ifdef VER90} { Delphi 2 }
    PerformanceFrequency : TLargeInteger = (QuadPart:0);
  {$endif}

  {$ifdef FPC}
    PerformanceFrequency : TLargeInteger = 0;
  {$endif}

  MARGIN                                 = 60;

var
  ps         : TPAINTSTRUCT;
  ClientRect : TRECT;
  Buf        : packed array[0..255] of char;
  TextSize   : TSIZE;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { get the current value of the performance counter frequency            }

      Supported := QueryPerformanceFrequency(PerformanceFrequency);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      {-----------------------------------------------------------------------}
      { display the value of the performance counter frequency                }

      GetClientRect(Wnd, ClientRect);

      SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);
      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      { write out the labels                                                  }

      lstrcpy(Buf, 'Performance Counter supported : ');
      TextOut(ps.hdc,
              ClientRect.Right  div 2 + MARGIN,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      GetTextExtentPoint32(ps.hdc, Buf, lstrlen(Buf), TextSize);

      lstrcpy(Buf, 'Performance Counter Frequency : ');
      TextOut(ps.hdc,
              ClientRect.Right  div 2 + MARGIN,
              ClientRect.Bottom div 2 + TextSize.cy,
              Buf,
              lstrlen(Buf));

      { write out the values                                                  }

      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

      if Supported
         then lstrcpy(Buf, ' TRUE')
         else lstrcpy(Buf, ' FALSE');

      TextOut(ps.hdc,
              ClientRect.Right  div 2 + MARGIN,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      { formatting the value as a float (%.0n) causes the appearance of a     }
      { thousands separator.                                                  }

      {$ifdef VER90} { Delphi 2 }
        StrFmt(Buf, '%.0n', [PerformanceFrequency.QuadPart]);
      {$endif}

      {$ifdef FPC}
        StrFmt(Buf, '%.0n', [PerformanceFrequency + 0.0]);
      {$endif}

      TextOut(ps.hdc,
              ClientRect.Right  div 2 + MARGIN,
              ClientRect.Bottom div 2 + TextSize.cy,
              Buf,
              lstrlen(Buf));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      lstrcpy(Buf, QueryPerformanceFrequency_Call);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      { calculate the size of the output string                               }

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf), TextSize);
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