{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetShellWindow example'}

{$R GetShellWindow.Res}

program _GetShellWindow;
  { Win32 API function - GetShellWindow example                               }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'GetShellWindow Example';

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

{ Not defined in FPC nor Delphi                                               }

function GetShellWindow : HWND; stdcall; external user32;

{-----------------------------------------------------------------------------}

function About(DlgWnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
begin
  About := ord(TRUE);

  case msg of

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

procedure DrawWindowFrame(Wnd : HWND);
  { Draws a frame around the parameter Wnd                                    }
var
  dc         : HDC;
  WindowRect : TRECT;

  Pen        : HPEN;
  OldPen     : HPEN;

begin
  { a 5 pixel wide pen is a reasonable choice. Some windows are "tucked" under}
  { other child windows and a thin frame won't be visible because it falls    }
  { under the "tucked" area.                                                  }

  Pen:= CreatePen(PS_INSIDEFRAME, 5, RGB(255, 0, 255));

  GetWindowRect(Wnd, WindowRect);              { the window rectangle         }

  {---------------------------------------------------------------------------}
  { convert the coordinates in WindowRect to be relative to the upper left    }
  { corner of the window.  At this time they are relative to the upper left   }
  { corner of the screen.  After the conversion the (Left, Top) coordinate in }
  { WindowRect will be (0, 0) which matches the preset (Left, Top) coordinate }
  { the window dc.                                                            }

  with WindowRect do OffsetRect(WindowRect, - Left, - Top);

  {---------------------------------------------------------------------------}
  { we need a dc that doesn't clip the output to the client area and that can }
  { be used to update a locked window (the window to be framed is locked).    }

  dc :=  GetDCEx(Wnd,
                 0,                      { no region                          }
                 DCX_WINDOW       or
                 DCX_CACHE        or
                 DCX_EXCLUDERGN   or     { excludes nothing because region = 0}
                 DCX_CLIPSIBLINGS or
                 DCX_LOCKWINDOWUPDATE);

  { select the pen and the brush used by the Rectangle API                    }

  OldPen := SelectObject(dc, Pen);
  SelectObject(dc, GetStockObject(NULL_BRUSH));  { only the frame gets drawn  }

  { select a raster op that causes the original pixels to be restored when the}
  { rectangle is drawn the second time.                                       }

  SetROP2(dc, R2_NOTXORPEN);

  {---------------------------------------------------------------------------}
  { draw a frame around (inside) the window rectangle                         }

  with WindowRect do
  begin
    Rectangle(dc, Left, Top, Right, Bottom);
  end;

  SelectObject(dc, OldPen);          { restore the original pen               }
  ReleaseDC(Wnd, dc);

  DeleteObject(Pen);                 { get rid of the pen                     }
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  IdxHandle    =  0;
  IdxProcessId =  1;
  IdxThreadId  =  2;

  VALUES_WIDTH = 50;  { this value should be calculated, not hard coded       }

type
  TOutputRange = IdxHandle..IdxThreadId;

const
  GetShellWindow_Call = 'GetShellWindow : HWND;';

  ShellWindow      : HWND  = 0;
  ShellProcessId   : DWORD = 0;
  ShellThreadId    : DWORD = 0;

  Labels             : packed array[TOutputRange] of pchar =
    ('Shell Window handle : ',
     'Process id : ',
     'Thread id : ');

  Values             : packed array[TOutputRange] of
                       packed array[0..63] of char = (#0, #0, #0);

  HexIndicator       : pchar = '$';

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;

  i                  : TOutputRange;
  k                  : integer;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      ShellWindow   := GetShellWindow();

      ShellThreadId := GetWindowThreadProcessId(ShellWindow,
                                               @ShellProcessId);

      StrFmt(Buf, '%s%x', [HexIndicator,  ShellWindow]);
      StrFmt(Values[IdxHandle],    '%8s', [Buf]);

      StrFmt(Values[IdxProcessId], '%8d', [ShellProcessId]);


      StrFmt(Buf, '%s%x', [HexIndicator,  ShellThreadId]);
      StrFmt(Values[IdxThreadId],  '%8s', [Buf]);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);

      GetTextExtentPoint32(ps.hdc,
                           Values[IdxHandle],     { any of the values will do }
                           lstrlen(Values[IdxHandle]),
                           TextSize);

      for i := low(i) to high(i) do
      begin
        { output the label                                                    }

        TextOut(ps.hdc,
                ClientRect.Right div 2 + VALUES_WIDTH,
                ClientRect.Top   + (ord(i) + 6) * TextSize.cy,
                Labels[i],
                lstrlen(Labels[i]));

        { output the value                                                    }

        TextOut(ps.hdc,
                ClientRect.Right div 2 + 2 * VALUES_WIDTH,
                ClientRect.Top   + (ord(i) + 6) * TextSize.cy,
                Values[i],
                lstrlen(Values[i]));
      end;

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      lstrcpy(Buf, GetShellWindow_Call);

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
        IDM_HIGHLIGHT_SHELL_WINDOW:
        begin
          for k := 1 to 10 do    { MUST be an EVEN number of times            }
          begin
            DrawWindowFrame(ShellWindow);
            sleep(100);
          end;

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
  cls.cbSize            := sizeof(TWndClassEx);         { must be initialized }

  if not GetClassInfoEx (hInstance, AppName, cls) then
    begin
      with cls do begin
        { cbSize has already been initialized as required above               }

        style           := CS_BYTEALIGNCLIENT;
        lpfnWndProc     := @WndProc;                    { window class handler}
        cbClsExtra      := 0;
        cbWndExtra      := 0;
        hInstance       := system.hInstance;            { qualify instance!   }
        hIcon           := LoadIcon (hInstance, APPICON);
        hCursor         := LoadCursor(0, idc_arrow);
        hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
        lpszMenuName    := APPMENU;                     { Menu name           }
        lpszClassName   := AppName;                     { Window Class name   }
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
                        50,                     { x pos on screen             }
                        50,                     { y pos on screen             }
                        400,                    { window width                }
                        300,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        hInstance,              { instance handle             }
                        Nil);                   { parameter sent to WM_CREATE }

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