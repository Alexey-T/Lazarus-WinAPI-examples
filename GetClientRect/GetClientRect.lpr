{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetClientRect example'}

{$R GetClientRect.Res}

program _GetClientRect;
  { Win32 API function - GetClientRect example                                }

uses Windows, Messages, Resource, SysUtils;

const
  AppNameBase  = 'GetClientRect Example';

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

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  GetClientRect_Call = 'GetClientRect (Wnd : HWND; var Rect : TRECT) : BOOL;';

  Pen                : HPEN = 0;      { deleted when the window is destroyed  }

  Hint = 'Press the Left mouse button anywhere in the client area';

  Tracking           : BOOL = FALSE;

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;
  OldPen             : HPEN;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      {-----------------------------------------------------------------------}
      { Using "not GetSysColor(COLOR_WINDOW)" guarantees that the pen will    }
      { be created using a color that will always be visible.  Note that      }
      { for this to be true, the value passed to GetSysColor must be the      }
      { same as the one passed when the class was registered.                 }

      { We AND with $00FFFFFF to make sure that the high byte is zero.        }
      { Windows uses this byte to select a palette which is not something     }
      { we want it to do in this occasion.                                    }

      Pen := CreatePen(PS_INSIDEFRAME,
                       3,
                       not GetSysColor(COLOR_WINDOW) and $00FFFFFF);
      exit;
    end;

    WM_LBUTTONDOWN:
    begin
      {-----------------------------------------------------------------------}
      { capture the mouse to make sure we always get the button up which      }
      { is the signal to refresh the client area.                             }

      SetCapture(Wnd);
      Tracking := TRUE;
      InvalidateRect(Wnd, nil, TRUE);

      exit;
    end;

    WM_LBUTTONUP:
    begin
      {-----------------------------------------------------------------------}
      { if the mouse was not captured then we don't have anything to do       }

      if Tracking then
      begin
        ReleaseCapture;                   { let the cat play with it          }

        Tracking := FALSE;
        InvalidateRect(Wnd, nil, TRUE);   { redraw the client area            }
      end;

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER);

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }

      if Tracking then
      begin
        {---------------------------------------------------------------------}
        { we have the mouse captured. we draw a frame around the client       }
        { rectangle and display its size.                                     }

        OldPen := SelectObject(ps.hdc, Pen);
        SelectObject(ps.hdc, GetStockObject(NULL_BRUSH));

        {---------------------------------------------------------------------}
        { draw a frame around the client area. This could be done using       }
        { the FrameRect API instead of Rectangle.                             }

        with ClientRect do
        begin
          Rectangle(ps.hdc, Left, Top, Right, Bottom);
        end;

        {---------------------------------------------------------------------}
        { draw the size of the client area                                    }

        SelectObject(ps.hdc, OldPen);

        with ClientRect do
        begin
          StrFmt(Buf,
                 '(Left, Top) (%d, %d) - (Right, Bottom) (%d, %d)',
                 [Left, Top, Right, Bottom]);
        end;

        { the code outside the if statement will output the buffer            }
      end
      else
      begin
        {---------------------------------------------------------------------}
        { we don't have the mouse captured.  we draw a string giving          }
        { the user a hint about what to do next.                              }

        lstrcpy(Buf, Hint);
      end;

      {-----------------------------------------------------------------------}
      { calculate the size of the output string currently in Buf              }

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf), TextSize);
      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 - TextSize.cy,
              Buf,
              lstrlen(Buf));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      lstrcpy(Buf, GetClientRect_Call);

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
      if Pen <> 0 then DeleteObject(Pen);


      PostQuitMessage(0);

      exit;
    end; { WM_DESTROY }
  end; { case msg }

  WndProc := DefWindowProc (Wnd, Msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function InitAppClass : WordBool;
  { registers the application's window classes                                }
var
  cls : TWndClassEx;

begin
  cls.cbSize          := sizeof(TWndClassEx);         { must be initialized   }

  if not GetClassInfoEx (hInstance, AppName, cls) then
  begin
    with cls do begin
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