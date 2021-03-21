{ enable the DEBUG define to verify the rectangle coordinates used to erase   }
{ the client area.                                                            }

{$define         DEBUG}

{$ifdef DEBUG}
  {$APPTYPE      CONSOLE}
{$else}
  {$APPTYPE      GUI}
{$endif}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - ExtTextOut example'}

{$R ExtTextOut.Res}

program _ExtTextOut;
  { Win32 API function - ExtTextOut example                                   }

uses
  Windows,
  Messages,
  Resource
  ;

const
  AppNameBase  = 'ExtTextOut';

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
  ExtTextOut_Call
    = 'ExtTextOut (dc : HDC; x, y : integer; Options : UINT; Rect : PRECT; '  +
      'Characters : pchar; CharCount : UINT; DistancesX : PIntegerArray) '    +
      ': BOOL;';

  VerticallyCenteredText = 'Example to show ExtTextOut clipping behavior';

  WINDOW_MIN_WIDTH          = 720;  { it's usually best to calculate what     }
  WINDOW_MIN_HEIGHT         = 160;  { these values should be.                 }

  Pen           : HPEN      = 0;

  Clip          : DWORD     = 0;    { MSDN says UINT, same as DWORD           }

var
  ps            : TPAINTSTRUCT;

  ClientRect    : TRECT;
  TextRect      : TRECT;

  TextSize      : TSIZE;

  MinMaxInfo    : PMinMaxInfo absolute lParam;  { meaning of lParam           }


begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { set the initial menu state - this could have also been done in the    }
      { resource file instead of here.                                        }

      PostMessage(Wnd, WM_COMMAND, IDM_CLIP_RIGHT_SIDE_OUT, 0);

      exit;
    end;

    WM_SIZE:
    begin
      { invalidate (but don't erase/clear) the client area                    }

      InvalidateRect(Wnd, nil, FALSE);

      exit;
    end;

    WM_GETMINMAXINFO:
    begin
      { restrict the minimum and maximum size of the window                   }

      with MinMaxInfo^ do
      begin
        ptMinTrackSize.x := WINDOW_MIN_WIDTH;
        ptMinTrackSize.y := WINDOW_MIN_HEIGHT;
      end;

      exit;
    end;

    WM_ERASEBKGND:
    begin
      { tell windows we erased the client area.                               }

      WndProc := 1;
      exit;
    end;

    WM_PAINT:
    begin
      { since we did not erase the background to prevent flicker, we must     }
      { update all the invalid parts of the client area.                      }

      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);

      { setup the DC                                                          }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT)); { text font     }
      SetBkColor(ps.hdc, GetSysColor(COLOR_WINDOW));          {  " background }
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);           {  " alignment  }

      GetTextExtentPoint32(ps.hdc,               { get the text dimensions    }
                           ExtTextOut_Call,
                           lstrlen(ExtTextOut_Call),
                           TextSize);

      {-----------------------------------------------------------------------}
      { draw the text that is centered vertically and horizontally            }

      CopyRect(TextRect, ClientRect);
      TextRect.Bottom := ClientRect.Bottom div 2;

      SelectObject(ps.hdc, GetStockObject(NULL_PEN));       { rectangle pen   }
      SelectObject(ps.hdc, GetSysColorBrush(COLOR_WINDOW)); {     "     brush }

      { since we did not erase the background, erase the rectangle on the     }
      { right or left side depending on the current menu item selection (Clip)}

      case Clip of
        IDM_CLIP_RIGHT_SIDE_OUT         :
        begin
         TextRect.Right := TextRect.Right div 2;

         { we must "manually" clear the right hand side. We have to add 1 to  }
         { rectangle dimensions because we are using a null pen               }

         with ClientRect do
         begin
           Rectangle(ps.hdc,
                     Right div 2,
                     Top,
                     Right        + 1,        { + 1 because of null pen       }
                     Bottom div 2 + 1);       { ditto                         }
         end;
        end;

        IDM_CLIP_LEFT_SIDE_OUT          :
        begin
          TextRect.Left  := TextRect.Right div 2;

          { we must "manually" clear the left hand side                       }

          with ClientRect do
          begin
            Rectangle(ps.hdc,
                      Left,
                      Top,
                      Right  div 2 + 1,       { + 1 because of null pen       }
                      Bottom div 2 + 1);      { ditto                         }
          end;
        end;

        IDM_CLIP_NONE :
        begin
          { ExtTextOut will erase and draw the text, therefore in this case   }
          { there is no manual erasing necessary.                             }

        end;

        else
        begin
          { this would be a bug because every clip option should be handled   }
        end;
      end;

      {$ifdef DEBUG}
        with TextRect do
        begin
          writeln;
          writeln('---------------------------');
          writeln('WM_PAINT - Top ClipRect');
          writeln('                 Top : ', Top);
          writeln('                Left : ', Left);
          writeln('              Bottom : ', Bottom);
          writeln('               Right : ', Right);
        end;
      {$endif}

      ExtTextOut(ps.hdc,
                 ClientRect.Right  div 2,
                 ClientRect.Bottom div 2,
                 ETO_OPAQUE or ETO_CLIPPED,
                 @TextRect,
                 VerticallyCenteredText,
                 lstrlen(VerticallyCenteredText),
                 nil);

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      with TextRect do
      begin
        Left   := 0;
        Top    := Bottom;
        Bottom := ClientRect.Bottom;
        Right  := ClientRect.Right;
      end;

      {$ifdef DEBUG}
        with TextRect do
        begin
          writeln;
          writeln('WM_PAINT - Bottom ClipRect');
          writeln('                 Top : ', Top);
          writeln('                Left : ', Left);
          writeln('              Bottom : ', Bottom);
          writeln('               Right : ', Right);
        end;
      {$endif}

      ExtTextOut(ps.hdc,
                 ClientRect.Right div 2,
                 ClientRect.Bottom - TextSize.cy,
                 ETO_OPAQUE,
                 @TextRect,
                 ExtTextOut_Call,
                 lstrlen(ExtTextOut_Call),
                 nil);

      {-----------------------------------------------------------------------}
      { we're done painting                                                   }

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_CLIP_RIGHT_SIDE_OUT     :
        begin
          Clip := IDM_CLIP_RIGHT_SIDE_OUT;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_CLIP_RIGHT_SIDE_OUT,
                             IDM_CLIP_NONE,
                             IDM_CLIP_RIGHT_SIDE_OUT,
                             MF_CHECKED);

          InvalidateRect(Wnd, nil, FALSE);

          exit;
        end;

        IDM_CLIP_LEFT_SIDE_OUT      :
        begin
          Clip := IDM_CLIP_LEFT_SIDE_OUT;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_CLIP_RIGHT_SIDE_OUT,
                             IDM_CLIP_NONE,
                             IDM_CLIP_LEFT_SIDE_OUT,
                             MF_CHECKED);

          InvalidateRect(Wnd, nil, FALSE);

          exit;
        end;


        IDM_CLIP_NONE               :
        begin
          Clip := IDM_CLIP_NONE;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_CLIP_RIGHT_SIDE_OUT,
                             IDM_CLIP_NONE,
                             IDM_CLIP_NONE,
                             MF_CHECKED);

          InvalidateRect(Wnd, nil, FALSE);

          exit;
        end;

        IDM_ABOUT:
        begin
          DialogBox(GetModuleHandle(nil), ABOUTBOX, Wnd, @About);

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
  cls      : TWndClassEx;
  Instance : THANDLE;

begin
  cls.cbSize          := sizeof(TWndClassEx);           { must be initialized }

  Instance            := GetModuleHandle(nil);

  if not GetClassInfoEx (Instance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := Instance;
      hIcon           := LoadIcon (Instance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := APPMENU;                     { Menu name             }
      lpszClassName   := AppName;                     { Window Class name     }
      hIconSm         := LoadImage(Instance,
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
  Wnd : HWND;
  Msg : TMSG;

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
                        800,                    { window width                }
                        300,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        GetModuleHandle(nil),   { instance handle             }
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