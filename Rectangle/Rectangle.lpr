{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - Rectangle example'}

{$R Rectangle.Res}

program _Rectangle;
  { Win32 API function - Rectangle example                                    }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'Rectangle Example';

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

  function GetClientRect(Wnd : HWND; out Rect : TRECT)
           : BOOL; stdcall;    external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL; stdcall;    external user32 name 'GetMessageA';

  function GetTextExtentPoint32(dc      : HDC;
                                str     : pchar;
                                strlen  : integer;
                            out strsize : TSIZE)
           : BOOL; stdcall     external gdi32 name 'GetTextExtentPoint32A';

  function BeginPaint(    Wnd           : HWND;
                      out PaintStruct   : TPaintStruct)
           : HDC; stdcall;     external user32;
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
  Rect       : TRECT  = (Left:0; Top:0; Right:0; Bottom:0);

  RectBrush  : HBRUSH = 0;
  RectPen    : HPEN   = 0;

  TEXT_OFFSET         =  5;       { distance from point to text label         }

  { enclosing rectangle coordinate labels                                     }

  RECT_TOPLEFT                    = '(Left, Top)';

  RECT_BOTTOMRIGHT_PEN_NULL_TRUE  = '(Right - 1, Bottom - 1)';
  RECT_BOTTOMRIGHT_PEN_NULL_FALSE = '(Right, Bottom)';

  RectBottomCoordinate            : pchar = nil; { pen_null_true or false     }

  { the function call label                                                   }

  RECTANGLE_CALL  =
    'Rectangle (dc : HDC; Left, Top, Right, Bottom : integer) : BOOL;';

var
  ps           : TPAINTSTRUCT;

  Buf          : packed array[0..127] of char;
  ClientRect   : TRECT;
  TextSize     : TSIZE;

begin
  WndProc := 0;

  case Msg of
  WM_CREATE:
     begin
       { set the initial brush and pen used to draw the rectangle             }

       PostMessage(Wnd, WM_COMMAND, IDM_PEN_NULL,    0);
       RectBottomCoordinate := RECT_BOTTOMRIGHT_PEN_NULL_TRUE;

       PostMessage(Wnd, WM_COMMAND, IDM_BRUSH_BLACK, 0);
       PostMessage(Wnd, WM_COMMAND, IDM_CLIENT_HALF, 0);

       exit;
     end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      {-----------------------------------------------------------------------}
      { draw the rectangle using the rectangle function                       }

      SelectObject(ps.hdc, RectPen);
      SelectObject(ps.hdc, RectBrush);

      with Rect do
      begin
        Rectangle(ps.hdc, Left, Top, Right, Bottom);
      end;

      {-----------------------------------------------------------------------}
      { The code from here on down is to take care of the cosmetic aspects    }
      { of this example.  It is not required to create a rectangle.           }

      { draw the parameter names next to their points.                        }

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      with Rect do
      begin
        TextOut(ps.hdc,
                Left,
                Top   - TEXT_OFFSET,
                RECT_TOPLEFT,
                lstrlen(RECT_TOPLEFT));
      end;

      { repeat the above steps for the rectangle's bottom right               }

      SetTextAlign(ps.hdc, TA_CENTER or TA_TOP);
      with Rect do
      begin
        TextOut(ps.hdc,
                Right,
                Bottom + TEXT_OFFSET,
                RectBottomCoordinate,
                lstrlen(RectBottomCoordinate));
      end;

      {-----------------------------------------------------------------------}
      { draw the Rectangle call                                               }

      lstrcpy(Buf, RECTANGLE_CALL);
      GetClientRect(Wnd, ClientRect);

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf), TextSize);

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      with ClientRect do
      begin
        TextOut(ps.hdc,
                Right div 2,
                Bottom - TextSize.cy,
                Buf,
                lstrlen(Buf));
      end;

      {-----------------------------------------------------------------------}
      { we're done drawing                                                    }

      EndPaint(Wnd, ps);

      exit;
    end;

    { NOTE: in the code that follows DeleteObject may be called to delete     }
    {       a standard brush (the NULL brush) or a standard pen (the NULL pen)}
    {       Windows ignores the request to delete a standard GDI object thus  }
    {       the call to DeleteObject causes no harm.                          }

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        {---------------------------------------------------------------------}
        { Brush menu ids                                                      }

        IDM_BRUSH_BLUE:
        begin
          if RectBrush <> 0 then DeleteObject(RectBrush);

          RectBrush := CreateSolidBrush(RGB(0, 0, 255));

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BRUSH_BLUE,
                             IDM_BRUSH_NULL,
                             IDM_BRUSH_BLUE,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_BRUSH_GREEN:
        begin
          if RectBrush <> 0 then DeleteObject(RectBrush);

          RectBrush := CreateSolidBrush(RGB(0, 255, 0));

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BRUSH_BLUE,
                             IDM_BRUSH_NULL,
                             IDM_BRUSH_GREEN,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_BRUSH_BLACK:
        begin
          if RectBrush <> 0 then DeleteObject(RectBrush);

          RectBrush := GetStockObject(BLACK_BRUSH);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BRUSH_BLUE,
                             IDM_BRUSH_NULL,
                             IDM_BRUSH_BLACK,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_BRUSH_NULL:
        begin
          if RectBrush <> 0 then DeleteObject(RectBrush);

          RectBrush := GetStockObject(NULL_BRUSH);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BRUSH_BLUE,
                             IDM_BRUSH_NULL,
                             IDM_BRUSH_NULL,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        {---------------------------------------------------------------------}
        { Pen menu ids                                                        }

        IDM_PEN_BLACK:
        begin
          RectBottomCoordinate := RECT_BOTTOMRIGHT_PEN_NULL_FALSE;

          if RectPen <> 0 then DeleteObject(RectPen);

          RectPen := GetStockObject(BLACK_PEN);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_PEN_CYAN,
                             IDM_PEN_NULL,
                             IDM_PEN_BLACK,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_PEN_CYAN:
        begin
          RectBottomCoordinate := RECT_BOTTOMRIGHT_PEN_NULL_FALSE;

          if RectPen <> 0 then DeleteObject(RectPen);

          RectPen := CreatePen(PS_SOLID, 0, RGB(0, 255, 255));

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_PEN_CYAN,
                             IDM_PEN_NULL,
                             IDM_PEN_CYAN,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_PEN_RED:
        begin
          RectBottomCoordinate := RECT_BOTTOMRIGHT_PEN_NULL_FALSE;

          if RectPen <> 0 then DeleteObject(RectPen);

          RectPen := CreatePen(PS_SOLID, 0, RGB(255, 0, 0));

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_PEN_CYAN,
                             IDM_PEN_NULL,
                             IDM_PEN_RED,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_PEN_NULL:
        begin
          RectBottomCoordinate := RECT_BOTTOMRIGHT_PEN_NULL_TRUE;

          if RectPen <> 0 then DeleteObject(RectPen);

          RectPen := GetStockObject(NULL_PEN);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_PEN_CYAN,
                             IDM_PEN_NULL,
                             IDM_PEN_NULL,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        {---------------------------------------------------------------------}
        { Rectangle area menu ids                                             }

        IDM_CLIENT:
        begin
          GetClientRect(Wnd, Rect);   { entire client area                    }

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_CLIENT,
                             IDM_CLIENT_HALF,
                             IDM_CLIENT,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_CLIENT_HALF:
        begin
          { calculate the size of the rectangle half the client area and      }
          { centered.                                                         }

          GetClientRect(Wnd, Rect);

          { shrink and move the rectangle to be in the middle of the client   }

          with Rect do
          begin
            Dec(Bottom, Bottom div 2);                        { shrink        }
            Dec(Right,  Right  div 2);

            OffsetRect(Rect, Right div 2, Bottom div 2);      { center        }
          end;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_CLIENT,
                             IDM_CLIENT_HALF,
                             IDM_CLIENT_HALF,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;


        {---------------------------------------------------------------------}
        { miscellaneous menu ids                                              }

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
      if RectBrush <> 0 then DeleteObject(RectBrush);
      if RectPen   <> 0 then DeleteObject(RectPen);


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
  else InitAppClass := True;
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

  WinMain := msg.wParam;                        { terminate with return code  }
end;

begin
  WinMain;
end.
