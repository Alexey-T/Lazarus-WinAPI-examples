{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - Flicker example'}

{ the following define is used to determine which method will be used to      }
{ invalidate the client area.  When INVALIDATERECT_IN_WM_SIZE is defined, the }
{ window class does NOT include CS_HREDRAW and CS_VREDRAW, to accomplish what }
{ they do, the client area is invalidated in the WM_SIZE message.             }

{$define INVALIDATERECT_IN_WM_SIZE}


{$R FlickerMin.Res}

program _FlickerMin;
  { Win32 Techniques - Flicker minimized when repainting                      }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'FlickerMin';

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

{$ifdef FPC}
  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(    Wnd  : HWND;
                         out Rect : TRECT)
           : BOOL; stdcall;    external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL; stdcall;    external user32 name 'GetMessageA';

  function CopyRect(out DestinationRect : TRECT;
               constref SourceRect      : TRECT)
           : BOOL; stdcall;    external user32;

  function GetTextExtentPoint32(dc      : HDC;
                                str     : pchar;
                                strlen  : integer;
                            out strsize : TSIZE)
           : BOOL; stdcall     external gdi32 name 'GetTextExtentPoint32A';

  function BeginPaint(    Wnd           : HWND;
                      out PaintStruct   : TPAINTSTRUCT)
           : HDC;  stdcall;    external user32;
{$endif}

{-----------------------------------------------------------------------------}

{ define an empty inline procedure, which FPC will remove, to remove a        }
{ potentially large number of hints about unused parameters.  Since the       }
{ procedure is "inline" and empty, a call to it will _not_ generate any code  }
{ and the presence of UNUSED_PARAMETER(someparameter) is much more self       }
{ documenting and general than using a Lazarus IDE specific directive.        }

{ overloading UNUSED_PARAMETER allows consolidating all unused hints in just  }
{ a few messages which should appear together if all such procedures are      }
{ declared together as well.                                                  }

{$ifdef FPC}
  procedure UNUSED_PARAMETER(UNUSED_PARAMETER : ptrint); inline; begin end;
{$endif}

{-----------------------------------------------------------------------------}

function About(DlgWnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
begin
  {$ifdef FPC}
    UNUSED_PARAMETER(lParam);           { "declare" lParam as unused          }
  {$endif}

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
  FlickerText  = 'Flicker minimized when repainting';

  Brush        : HBRUSH = 0;
  BrushRed     : HBRUSH = 0;

  PenRed       : HPEN   = 0;
  PenWindow    : HPEN   = 0;
  Pen          : HPEN   = 0;

var
  ps           : TPAINTSTRUCT;
  ClientRect   : TRECT;
  Buffer       : packed array[0..255] of char;

  TextSize     : TSIZE;

  TextRect     : TRECT;      { the rectangle where the text will be drawn     }

  ClearRect    : TRECT;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      BrushRed  := CreateSolidBrush(RGB(255,0,0));

      PenRed    := CreatePen(PS_SOLID, 1, RGB(255, 0, 0));
      PenWindow := CreatePen(PS_SOLID, 1, GetSysColor(COLOR_WINDOW));

      PostMessage(Wnd, WM_COMMAND, IDM_RED, 0);

      exit;
    end;

    {$ifdef INVALIDATERECT_IN_WM_SIZE}
      WM_SIZE:
      begin
        { invalidate the entire client area, this will allow WM_PAINT to draw }
        { anywhere in it.  We need to do this because the window class does   }
        { not include the CS_VREDRAW and CS_HREDRAW styles.                   }

        { NOTE: when the entire client area needs to be invalidated as a      }
        {       result of sizing the window, it is better to simply include   }
        {       the CS_VREDRAW and CS_HREDRAW styles when registering the     }
        {       class.                                                        }

        { there are cases when excluding the CS_VREDRAW and CS_HREDRAW styles }
        { allows the WM_SIZE (or other related message) to keep the invalid   }
        { area to a minimum thus optimizing the repaint speed and minimizing  }
        { flicker potential.                                                  }

        GetClientRect(Wnd, ClientRect);

        { NOTE: specifying FALSE or TRUE in the InvalidateRect call, IN THIS  }
        {       CASE it makes little to no difference.                        }

        InvalidateRect(Wnd, @ClientRect, FALSE);

        exit;
      end;
    {$endif}


    WM_ERASEBKGND:
    begin
      { tell Windows we erased the background                                 }

      WndProc := 1;

      exit;
    end;


    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);

      SelectObject(ps.hdc, GetStockObject(SYSTEM_FONT));
      SetBkColor(ps.hdc, GetSysColor(COLOR_WINDOW));

      SelectObject(ps.hdc, Pen);
      SelectObject(ps.hdc, Brush);

      lstrcpy(Buffer, FlickerText);

      GetTextExtentPoint32(ps.hdc,
                           Buffer,
                           lstrlen(Buffer),
                           TextSize);

      {-----------------------------------------------------------------------}
      { calculate the coordinates where the text will be written              }

      CopyRect(TextRect, ClientRect);
      with TextRect do
      begin
        { left and right are the entire width of the client area              }

        Bottom := ClientRect.Bottom - TextSize.cy;
        Top    := Bottom            - TextSize.cy;
      end;

      {-----------------------------------------------------------------------}
      { clear the rectangles above and below the text                         }

      { this could have been done when processing the WM_ERASEBKGND message   }
      { but it's more convenient to do here.                                  }

      CopyRect(ClearRect, ClientRect);

      { clear the rectangle above the text                                    }

      with ClearRect do
      begin
        { Left, Right and Top are already set                                 }

        Bottom := TextRect.Top;
        Rectangle(ps.hdc, Left, Top, Right, Bottom);
      end;

      { clear the rectangle below the text                                    }

      with ClearRect do
      begin
        { Left and Right are already set                                      }

        Top    := TextRect.Bottom;
        Bottom := ClientRect.Bottom;

        Rectangle(ps.hdc, Left, Top, Right, Bottom);
      end;


      {-----------------------------------------------------------------------}
      { draw the text                                                         }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      ExtTextOut(ps.hdc,
                 ClientRect.Right div 2,
                 ClientRect.Bottom - TextSize.cy,
                 ETO_OPAQUE,
                 @TextRect,
                 FlickerText,
                 lstrlen(FlickerText),
                 nil);


      {-----------------------------------------------------------------------}
      { we're done painting                                                   }

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_RED:
        begin
          Brush := BrushRed;
          Pen   := PenRed;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_RED,
                             IDM_COLOR_WINDOW,
                             IDM_RED,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);        { repaint the client area    }
          UpdateWindow(Wnd);

          exit;
        end;

        IDM_COLOR_WINDOW:
        begin
          Brush := GetSysColorBrush(COLOR_WINDOW);
          Pen   := PenWindow;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_RED,
                             IDM_COLOR_WINDOW,
                             IDM_COLOR_WINDOW,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);        { repaint the client area    }
          UpdateWindow(Wnd);

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
         if BrushRed <> 0 then DeleteObject(BrushRed);
         if PenRed   <> 0 then DeleteObject(PenRed);

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

      {$ifndef INVALIDATERECT_IN_WM_SIZE}
        { add the CS_HREDRAW and CS_VREDRAW to the class style                }

        Style         := Style or CS_HREDRAW or CS_VREDRAW;
      {$endif}

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
                        ws_OverlappedWindow or  { window style                }
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        600,                    { window width                }
                        400,                    { window height               }
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