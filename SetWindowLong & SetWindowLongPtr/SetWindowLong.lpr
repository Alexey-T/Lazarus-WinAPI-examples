{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - SetWindowLong/Ptr example'}

{$R SetWindowLong.Res}

program _SetWindowLong;
  { Win32 API function - SetWindowLong and SetWindowLongPtr example           }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'SetWindowLong and SetWindowLongPtr Example';

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


{$ifdef VER90}
  { for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms   }
  { of GetWindowLong and SetWindowLong respectively.                          }

  { FPC already does this                                                     }

  function GetWindowLongPtr(hWnd  : HWND;
                            Index : ptrint)
           : DWORD; stdcall; external 'user32' name 'GetWindowLongA';

  function SetWindowLongPtr(hWnd    : HWND;
                            Index   : ptrint;
                            NewLong : ptruint)
           : DWORD; stdcall; external 'user32' name 'SetWindowLongA';
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
  SETWINDOWLONG_CALL =
  'SetWindowLong/Ptr (Wnd : HWND; Index : integer; NewValue : longint) ' +
  ': longint;';

  MenuID    : longint = 0;              { the Window's menu handle            }
  StyleOrg  : longint = 0;              { the Window's original style         }

  Hint  = 'Double click anywhere in the client area';

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { get the menu handle and save it in a static variable                  }

      MenuId   := GetMenu(Wnd);
      StyleOrg := GetWindowLongPtr(Wnd, GWL_STYLE);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }

      {-----------------------------------------------------------------------}
      { output the hint centered in the client area                           }

      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Hint,
              lstrlen(Hint));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }


      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      lstrcpy(Buf, SetWindowLong_Call);

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

    WM_NCHITTEST:
    begin
      { if the window has no caption then dragging the client area drags      }
      { the whole window.  Note that returning HTCAPTION for a hit in the     }
      { client area also has the effect of converting any subsequent double   }
      { click into a NON CLIENT double click (because Windows will think      }
      { that it occurred in the caption instead of in the client area.)       }

      wParam := DefWindowProc(Wnd, Msg, wParam, lParam);

      if (GetWindowLongPtr(Wnd, GWL_ID) = 0) and (wParam = HTCLIENT) then
      begin
        WndProc := HTCAPTION;
        exit;
      end;


      WndProc := wParam;
      exit;
    end;

    WM_LBUTTONDBLCLK:
    begin
      { route the event to the menu option.  We get this message when the     }
      { menu is showing (we don't lie about the client area being the         }
      { window's caption.)                                                    }

      PostMessage(Wnd, WM_COMMAND, IDM_CHANGEFRAME, 0);

      exit;
    end;

    WM_NCLBUTTONDBLCLK:
    begin
      { when the window has no caption a double click in the client area      }
      { will produce this message because windows thinks that the client      }
      { area is the caption and, a double click in the caption produces an    }
      { NCLBUTTONDBLCLK not an WM_LBUTTONDBLCLK.                              }

      { to prevent a double click in the caption to cause a change in frame   }
      { we use the current window id which will be zero when the window has   }
      { no caption and not zero when it does.                                 }

      if GetWindowLongPtr(Wnd, GWL_ID) = 0 then
      begin
        PostMessage(Wnd, WM_COMMAND, IDM_CHANGEFRAME, 0);
        exit;
      end;

      { otherwise let DefWindowProc handle the message                        }
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_CHANGEFRAME:
        begin
          if GetWindowLongPtr(Wnd, GWL_ID) = 0 then
          begin
            { the menu is not being shown at this time.  Restore the          }
            { menu and the window frame.                                      }

            SetWindowLongPtr(Wnd, GWL_STYLE, StyleOrg);

            { to avoid flicker, use SetWindowLong instead of SetMenu          }
            { the window will be redrawn which will cause the new             }
            { menu id to have effect.                                         }

            SetWindowLongPtr(Wnd, GWL_ID, MenuId);
          end
          else
          begin
            { the menu is showing, remove the menu and the caption            }

            SetWindowLongPtr(Wnd,
                             GWL_STYLE, WS_DLGFRAME);
            SetWindowLongPtr(Wnd,
                             GWL_ID, 0);
          end;

          { redraw the window                                                 }

          SetWindowPos(Wnd,
                       0,                  { z order not affected             }
                       0,                  { position not affected            }
                       0,
                       0,                  { size not affected                }
                       0,
                       SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
                       SWP_FRAMECHANGED or SWP_SHOWWINDOW);

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
    with cls do begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT or CS_DBLCLKS;
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
                        500,                    { window width                }
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