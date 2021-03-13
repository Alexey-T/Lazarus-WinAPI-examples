{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - SetTextAlign example'}

{$R SetTextAlign.Res}

program _SetTextAlign;
  { Win32 API function - SetTextAlign example                                 }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'SetTextAlign Example';

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
  SETTEXTALIGN_CALL = 'SetTextAlign (dc : HDC; Alignment : UINT) : UINT;';

  Text                         = 'SetTextAlign';
  Mode              : integer = TA_CENTER;

  Pen               : HPEN    = 0;

  CROSS_LEN                   = 10;

var
  ps                : TPAINTSTRUCT;

  ClientRect        : TRECT;

  Buf               : packed array[0..255] of char;

  TextSize          : TSIZE;
  OldPen            : HPEN;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      Pen := CreatePen(PS_DOT, 0, RGB(255, 0, 0));

      { set the default menu option                                           }

      PostMessage(Wnd, WM_COMMAND, IDM_CENTERED, 0);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }
      SetBkMode(ps.hdc, TRANSPARENT);

      {-----------------------------------------------------------------------}
      { set the requested alignment mode and output the text                  }

      SetTextAlign(ps.hdc, Mode);

      GetTextExtentPoint32(ps.hdc,
                           Text,
                           lstrlen(Text), TextSize);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 - TextSize.cy,
              Text,
              lstrlen(Text));

      {-----------------------------------------------------------------------}
      { draw the point where we requested the text to be output               }

      OldPen := SelectObject(ps.hdc, Pen);

      MoveToEx(ps.hdc,
               (ClientRect.Right  div 2) - CROSS_LEN,
               (ClientRect.Bottom div 2) - TextSize.cy,
               nil);
      LineTo(ps.hdc,
             (ClientRect.Right  div 2) + CROSS_LEN,
             (ClientRect.Bottom div 2) - TextSize.cy);
      MoveToEx(ps.hdc,
               (ClientRect.Right  div 2),
               (ClientRect.Bottom div 2) - TextSize.cy - CROSS_LEN,
               nil);
      LineTo(ps.hdc,
             (ClientRect.Right  div 2),
             (ClientRect.Bottom div 2) - TextSize.cy + CROSS_LEN);

      SelectObject(ps.hdc, OldPen);

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      lstrcpy(Buf, SETTEXTALIGN_CALL);

      { calculate the size of the output string                               }

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf), TextSize);

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
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
        IDM_BASELINE:
        begin
          Mode := TA_BASELINE;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_BASELINE,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_CENTERED:
        begin
          Mode := TA_CENTER;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_CENTERED,
                             MF_BYCOMMAND);
          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_BOTTOM:
        begin
          Mode := TA_BOTTOM;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_BOTTOM,
                             MF_BYCOMMAND);
          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_LEFT:
        begin
          Mode := TA_LEFT;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_LEFT,
                             MF_BYCOMMAND);
          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_RIGHT:
        begin
          Mode := TA_RIGHT;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_RIGHT,
                             MF_BYCOMMAND);
          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_TOP:
        begin
          Mode := TA_TOP;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_TOP,
                             MF_BYCOMMAND);
          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_BOTCENTER:
        begin
          Mode := TA_CENTER or TA_BOTTOM;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_BASELINE,
                             IDM_TOP,
                             IDM_BOTCENTER,
                             MF_BYCOMMAND);
          InvalidateRect(Wnd, nil, TRUE);

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
      if Pen <> 0 then DeleteObject(Pen);


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
