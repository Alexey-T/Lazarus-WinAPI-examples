{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'CreateStatusWindow example - Quirk - StatusBar Text Length Limit'}

{$R StatusBar.Res}

program _StatusBar;
  { Quirk - StatusBar Text Length Limit                                       }

uses Windows, Messages, Resource, SysUtils, CommCtrl;

const
  AppNameBase  = 'CreateStatusWindow - StatusBar Text Length Limit Quirk';

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

  // for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms of
  // GetWindowLong and SetWindowLong respectively.

  // NOTE : FPC already defines these synonyms (see ascdef.inc)

  function GetWindowLongPtr(Wnd   : HWND;
                            Index : ptrint)
           : ptruint; stdcall; external 'user32' name 'GetWindowLongA';

  function SetWindowLongPtr(Wnd     : HWND;
                            Index   : ptrint;
                            NewLong : ptruint)
           : ptruint; stdcall; external 'user32' name 'SetWindowLongA';

  function GetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint)
           : ptruint; stdcall; external 'user32' name 'GetClassLongA';

  function SetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint;
                           NewLong  : ptruint)
           : ptruint; stdcall; external 'user32' name 'SetClassLongA';
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
  Listbox     : HWND = 0;   { note that Listbox is a "static" variable        }

  StatusText  =
    'This string should appear three times in the status bar. ';

  ID_LISTBOX  = 1010;
  ID_STATWIN  = 2000;

var
  ClientRect : TRECT;
  StatRect   : TRECT;
  Style      : ptruint;

  Buf        : packed array[0..255] of char;

  StatWnd    : HWND;        { note that StatWnd is a stack variable           }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      InitCommonControls;    { initialize the common controls library         }

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

      { make sure our status bar doesn't flicker when the parent window is    }
      { resized. To do this we remove the CS_VREDRAW and CS_HREDRAW styles    }

      Style := GetClassLongPtr(StatWnd, GCL_STYLE);    { get original style   }

      Style := Style and (not CS_VREDRAW);             { undesirable          }
      Style := Style and (not CS_HREDRAW);             { ditto                }

      SetClassLongPtr(StatWnd, GCL_STYLE, Style);      { set then new styles  }

      { we'll place the StatusText multiple times in the status bar           }

      GetClientRect(Wnd, ClientRect);   { calculate the listbox size          }
      GetClientRect(StatWnd, StatRect);

      Listbox  := CreateWindowEx(WS_EX_CLIENTEDGE or WS_EX_RIGHTSCROLLBAR,
                                'LISTBOX',
                                 nil,
                                 WS_CHILD        or WS_HSCROLL      or
                                 WS_VSCROLL      or WS_CLIPSIBLINGS or
                                 WS_CLIPCHILDREN or WS_VISIBLE      or
                                 LBS_NOSEL       or
                                 LBS_NOINTEGRALHEIGHT,
                                 0,
                                 0,
                                 ClientRect.Right,
                                 ClientRect.Bottom - StatRect.Bottom,
                                 Wnd,
                                 ID_LISTBOX,
                                 hInstance,
                                 nil);
      if Listbox = 0 then
      begin
        MessageBox(Wnd,
                   'Couldn''t create a child window', 'Main Window',
                   MB_OK);

        WndProc := -1;                           { abort window creation      }

        exit;
      end;

      { tell the listbox to use a nicer font than the default system font     }

      SendMessage(Listbox,
                  WM_SETFONT, GetStockObject(ANSI_FIXED_FONT), 0);

      { tell the status bar to display a string that is longer than 137       }
      { characters. (3 times the "normal" status text)                        }

      lstrcpy(Buf, StatusText);
      lstrcat(Buf, StatusText);
      lstrcat(Buf, StatusText);

      SendMessage(StatWnd, SB_SETTEXT, 0, ptruint(@Buf));

      { to determine if the status bar saved the entire string, retrieve the  }
      { text from the status bar                                              }

      SendMessage(StatWnd, SB_GETTEXT, 0, ptruint(@Buf));

      { show the retrieved text in the listbox                                }

      SendMessage(Listbox, LB_ADDSTRING,              0, ptruint(@Buf));
      SendMessage(Listbox, LB_SETHORIZONTALEXTENT, 1400, 0);

      exit;
    end;

    WM_SIZE:
    begin
      { tell the status window to resize itself                               }

      { since StatWnd is a stack variable we have to retrieve the status bar's}
      { window handle.                                                        }

      { NOTE: GetDlgItem retrieves the window handle of the child window with }
      {       the specified id.  It would have probably been more appropriate }
      {       to name this API "GetChildItem" since it operates on any        }
      {       window's children not just on dialog children.  See MSDN.       }

      StatWnd := GetDlgItem(Wnd, ID_STATWIN);   { StatWnd is a stack var      }
      SendMessage(StatWnd, WM_SIZE, 0, 0);

      { resize the Listbox.  The size of the listbox is the size of the       }
      { main window's client area minus the status bar's client area.         }

      GetClientRect(StatWnd, StatRect);

      MoveWindow(Listbox,
                 0,
                 0,
                 LOWORD(lParam),
                 HIWORD(lParam) - StatRect.Bottom,
                 TRUE);

      { work around the listbox bug that causes its display to be garbled     }
      { if the scroll bar is not at the origin and the window is resized.     }

      { NOTE : in this program it is extremely unlikely that is bug can show  }
      {        up since only one line is displayed in the listbox.            }

      if GetScrollPos(Listbox, SB_HORZ) <> 0 then
      begin
        InvalidateRect(Listbox, nil, TRUE);
        UpdateWindow(Listbox);
      end;

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
      hInstance       := system.hInstance;
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
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

  Wnd := CreateWindowEx(0,
                        AppName,                { class name                  }
                        AppName,                { window caption text         }
                        ws_OverlappedWindow or  { window style                }
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        800,                    { window width                }
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
