{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetEnvironmentStrings example'}

{$R GetEnvironmentStrings.Res}

program _GetEnvironmentStrings;
  { Win32 API function - GetEnvironmentStrings example                        }

uses Windows, Messages, Resource, SysUtils, CommCtrl;

const
  AppNameBase  = 'GetEnvironmentStrings';

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
  GetEnvironmentStrings_Call = 'GetEnvironmentStrings : pchar;';

  ID_LISTBOX    = 1010;
  ID_STATWIN    = 1020;
  ID_STATWINTOP = 1030;

  MARGIN        = 1;

var
  ClientRect         : TRECT;
  StatRect           : TRECT;

  Buf                : packed array[0..MAX_PATH] of char;

  ListBox            : HWND;
  StatWnd            : HWND;
  StatWndTop         : HWND;

  EnvPtr             : pchar;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      InitCommonControls;    { initialize the common controls library         }

      { create the status window that is located at the bottom                }

      StatWnd := CreateStatusWindow(WS_CHILD   or    { must be a child        }
                                    WS_VISIBLE or    { make it visible        }
                                    WS_CLIPSIBLINGS,
                                    nil,             { text in status bar     }
                                    Wnd,             { parent window          }
                                    ID_STATWIN);

      if StatWnd = 0 then
      begin
        MessageBox(Wnd,
                   'Failed to create the status bar',
                   'Main Window',
                   MB_ICONERROR or MB_OK);

        WndProc := -1;

        exit;
      end;

      { make the status bar show the function call label                      }

      lstrcpy(Buf, GetEnvironmentStrings_Call);

      SendMessage(StatWnd, SB_SETTEXT, 0, ptruint(@Buf));

      { create the status window that is located at the top                   }

      StatWndTop := CreateStatusWindow(WS_CHILD   or    { must be a child     }
                                       WS_VISIBLE or    { make it visible     }
                                       CCS_TOP    or    { at the top          }
                                       WS_CLIPSIBLINGS,
                                       nil,             { no text             }
                                       Wnd,             { parent window       }
                                       ID_STATWINTOP);
      if StatWndTop = 0 then
      begin
        MessageBox(Wnd,
                   'Failed to create the top status bar',
                   'Main Window',
                   MB_ICONERROR or MB_OK);

        WndProc := -1;
        exit;
      end;

      { make the top status bar show GetEnvironmentString's return value      }

      StrFmt(Buf,
             'GetEnvironmentStrings : $%p',
             [pointer(GetEnvironmentStrings)]);

      SendMessage(StatWndTop, SB_SETTEXT, 0, ptruint(@Buf));

      { Create a listbox to show the environment strings                      }

      GetClientRect(Wnd, ClientRect);          { client total area size       }
      GetClientRect(StatWnd, StatRect);

      ListBox := CreateWindowEx(WS_EX_CLIENTEDGE,
                                'listbox',
                                nil,
                                WS_CHILD             or
                                WS_VSCROLL           or
                                WS_HSCROLL           or
                                WS_VISIBLE           or
                                LBS_NOINTEGRALHEIGHT or
                                LBS_NOSEL,
                                ClientRect.Left,
                                ClientRect.Top    +
                                  (StatRect.Bottom + MARGIN),

                                ClientRect.Right,
                                ClientRect.Bottom -
                                  (2 * StatRect.Bottom + MARGIN),
                                Wnd,
                                ID_LISTBOX,
                                hInstance,
                                nil);

      { use a nicer font for the list of elements in the listbox              }

      SendMessage(ListBox,
                  WM_SETFONT,
                  GetStockObject(ANSI_VAR_FONT), ord(FALSE));

      { fill the listbox with the environment strings                         }

      SendMessage(ListBox, WM_SETREDRAW,         ord(FALSE), 0);

      { NOTE: the proper horizontal extent should be a calculated value based }
      {       on the width of the widest string that has been added.  This    }
      {       ensure the horizontal scroll bar can show the entire text       }
      {       which may not be the case when the horizontal extent is simply  }
      {       set to a "reasonable guess", which is what this example does.   }

      SendMessage(ListBox, LB_SETHORIZONTALEXTENT, 1200,       0);

      EnvPtr := GetEnvironmentStrings;

      { "walk" the strings and add them to the listbox                        }

      while (EnvPtr <> nil) and (EnvPtr^ <> #0) do
      begin
        SendMessage(ListBox, LB_ADDSTRING, 0, ptruint(EnvPtr));

        { advance to the end of the string                                    }

        inc(EnvPtr, lstrlen(EnvPtr));    { advance to the end of the string   }
        inc(EnvPtr);                     { skip the null terminator           }
      end;

      SendMessage(ListBox, WM_SETREDRAW, ord(TRUE), 0);

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
      hbrBackground   := COLOR_3DFACE + 1;
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

  Wnd := CreateWindowEx(WS_EX_WINDOWEDGE,
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
                        800,                    { window width                }
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