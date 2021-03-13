{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - EnumChildWindows example'}


{ the following define is to remove extraneous bits in the high DWORD of a    }
{ window handle.  The reason for the presence of these extraneous bits is     }
{ unknown.  When present they have been observed to be $FFFFFFFF.             }

{$define TRUNCATE_EXTRANEOUS_DWORD_IN_WINDOW_HANDLE}

{ NOTE: the presence of non zero bits in the high DWORD of a window handle    }
{       causes the formatting to get messed up.                               }
{                                                                             }
{       it is also worth noting that setting the high DWORD of a window       }
{       handle to $FFFFFFFF does not cause any apparent problems.             }
{                                                                             }
{       MS spy++ also shows those extraneous bits in the window handle when   }
{       the window "properties" are requested.                                }


{$R EnumChildWindows.Res}

{ uncomment the following defines to test error handling code                 }

//{$DEFINE FAIL_STATUSBAR}
//{$DEFINE FAIL_LISTBOX}

program _EnumChildWindows;
  { Win32 API function - EnumChildWindows example                             }

uses
  Windows,
  Messages,
  Resource,
  CommCtrl,
  SysUtils
  ;

const
  AppNameBase  = 'EnumChildWindows Example';

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

const
  user32       = 'user32';

{-----------------------------------------------------------------------------}

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;

  { for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms   }
  { of GetWindowLong and SetWindowLong respectively.                          }

  function GetWindowLongPtr(Wnd   : HWND;
                            Index : ptrint)
           : ptruint; stdcall; external user32 name 'GetWindowLongA';

  function SetWindowLongPtr(Wnd     : HWND;
                            Index   : ptrint;
                            NewLong : ptruint)
           : ptruint; stdcall; external user32 name 'SetWindowLongA';

  function GetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint)
           : ptruint; stdcall; external user32 name 'GetClassLongA';

  function SetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint;
                           NewLong  : ptruint)
           : ptruint; stdcall; external user32 name 'SetClassLongA';

  { Declaration of GetAncestor is missing in Delphi 2                         }

  function GetAncestor(Wnd : HWND; AncestorFlags : DWORD)
           : HWND;    stdcall; external  user32;

const
  GA_PARENT    = 1;
  GA_ROOT      = 2;
  GA_ROOTOWNER = 3;
{$endif}

{$ifdef FPC}
  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(Wnd : HWND; out Rect : TRECT)
           : BOOL; stdcall; external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL; stdcall; external user32 name 'GetMessageA';

  { "override" some FPC definitions with better parameter names               }

  function EnumWindows(EnumerationFunction : ENUMWINDOWSPROC;
                       lParam              : ptrint)
           : BOOL; stdcall; external user32;

  function EnumChildWindows(WndParent           : HWND;
                            EnumerationFunction : ENUMWINDOWSPROC;
                            lParam              : ptrint)
           : BOOL; stdcall; external user32;
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

function EnumChildrenProc(Wnd : HWND; ListBoxInt : ptrint) : BOOL; stdcall;
  { EnumChildWindows callback                                                 }
const
  MAX_LEVEL = 64;   { for safety only                                         }

var
  ListBox  : HWND absolute ListBoxInt;

  Buf      : packed array[0..511] of char;

  Level    : DWORD;
  Ancestor : HWND;
  Desktop  : HWND;                    { desktop is level zero                 }

begin
  result   := TRUE;

  Level    := 1;                      { children are all greater than zero    }
  Ancestor := Wnd;
  Desktop  := GetDesktopWindow();

  while TRUE do
  begin
    Ancestor := GetAncestor(Ancestor, GA_PARENT);

    if (Ancestor = Desktop) or (Level >= MAX_LEVEL) then break;

    inc(Level);
  end;

  { for some unknown reason Windows occasionally (quite rarely) returns a     }
  { window handle that is greater than what fits in a DWORD.  In that case,   }
  { the high DWORD is high(DWORD) (all $F).  The presence of the "extraneous" }
  { bits does not seem to cause any problems nor does removing them.          }

  {$ifdef TRUNCATE_EXTRANEOUS_DWORD_IN_WINDOW_HANDLE}
    if Wnd > high(DWORD) then Wnd := DWORD(Wnd);  { zero out high DWORD       }
  {$endif}

  StrFmt(Buf, '%*s  %8x, %4d', [2 * Level, ' ', Wnd, Level]);

  SendMessage(ListBox, LB_ADDSTRING, 0, ptruint(@Buf));  { output in listbox  }
end;

{-----------------------------------------------------------------------------}

function EnumWindowsProc(Wnd : HWND; ListBoxInt : ptrint) : BOOL; stdcall;
  { EnumWindows callback. It fills the listbox with the window's handle and   }
  { their caption text.                                                       }

const
  VisibleYes = 'Y';
  VisibleNo  = ' ';

var
  ListBox    : HWND absolute ListBoxInt;

  WindowText : packed array[0..511] of char;
  Buf        : packed array[0..511] of char;

  ProcessId  : DWORD;
  ThreadId   : DWORD;

  Visible    : pchar;


begin
  EnumWindowsProc := TRUE;       { continue enumerating until no more windows }

  { for some unknown reason Windows occasionally (quite rarely) returns a     }
  { window handle that is greater than what fits in a DWORD.  In that case,   }
  { the high DWORD is high(DWORD) (all $F).  The presence of the "extraneous" }
  { bits does not seem to cause any problems nor does removing them.          }

  {$ifdef TRUNCATE_EXTRANEOUS_DWORD_IN_WINDOW_HANDLE}
    if Wnd > high(DWORD) then Wnd := DWORD(Wnd);  { zero out high DWORD       }
  {$endif}

  ThreadId        := GetWindowThreadProcessId(Wnd, @ProcessId);

  Visible         := VisibleNo;
  if IsWindowVisible(Wnd) then Visible := VisibleYes;

  GetWindowText(Wnd, WindowText, sizeof(WindowText));
  StrFmt(Buf, '%8x   %8d   %8d   %s         %s', [Wnd,
                                                  ProcessId,
                                                  ThreadId,
                                                  Visible,
                                                  WindowText]);

  SendMessage(ListBox, LB_ADDSTRING, 0, ptruint(@Buf));

  EnumChildWindows(Wnd, @EnumChildrenProc, ListBoxInt);
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }

  { WARNING: MS defines wParam as a UINT which is unsigned.  There are very   }
  { few occasions where the difference matters BUT there are some.            }

const
  EnumChildWindows_Call
    = '  EnumChildWindows (WndParent : HWND; EnumerationFunction : '            +
        'EnumWindowsProc; lParam : ptrint) : BOOL;';

  ListboxHeader : pchar = '  Window    Process     Thread  Visible    Caption';

  ID_LISTBOX    = 1010;
  ID_STATWIN    = 1020;

  MessageCaption  = 'Main Window - WM_CREATE';

  BLANK_LINE      : pchar = '';

var
  ClientRect      : TRECT;
  StatRect        : TRECT;

  Listbox         : HWND;
  StatWnd         : HWND;

  Style           : ptruint;

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
      {$IFDEF FAIL_STATUSBAR} ; {$ENDIF}
      begin
        MessageBox(Wnd,
                   'Failed to create the status bar',
                   MessageCaption,
                   MB_ICONERROR or MB_OK);

        WndProc := -1;
        exit;
      end;

      { make sure our status bar doesn't flicker when the parent window is    }
      { resized. To do this we remove the CS_VREDRAW and CS_HREDRAW styles    }

      Style := GetClassLongPtr(StatWnd, GCL_STYLE);    { get original style   }

      Style := Style and (not CS_VREDRAW);             { undesirable          }
      Style := Style and (not CS_HREDRAW);             { ditto                }

      SetClassLongPtr(StatWnd, GCL_STYLE, Style);      { set the new styles   }

      { make the status bar show the EnumWindows call                         }

      SendMessage(StatWnd,
                  SB_SETTEXT, 0, ptruint(pchar(EnumChildWindows_Call)));

      { create a listbox that will contain the result of EnumWindows and      }
      { EnumChildWindows.                                                     }

      GetClientRect(Wnd,     ClientRect);      { client total area size       }
      GetClientRect(StatWnd, StatRect);

      Listbox := CreateWindowEx(WS_EX_CLIENTEDGE,
                                'listbox',
                                nil,
                                WS_CHILD             or
                                WS_VSCROLL           or
                                WS_HSCROLL           or
                                WS_VISIBLE           or
                                LBS_NOINTEGRALHEIGHT or
                                LBS_NOSEL,
                                ClientRect.Left,
                                ClientRect.Top,
                                ClientRect.Right,
                                ClientRect.Bottom - StatRect.Bottom,
                                Wnd,
                                ID_LISTBOX,
                                hInstance,
                                nil);

      if Listbox = 0 then
      {$IFDEF FAIL_LISTBOX} ; {$ENDIF}
      begin
        MessageBox(Wnd,
                   'Failed to create the listbox',
                   MessageCaption,
                   MB_ICONERROR or MB_OK);

        WndProc := -1;                           { abort window creation      }
        exit;
      end;

      { use a nicer font for the list of elements in the listbox              }

      SendMessage(ListBox,
                  WM_SETFONT,
                  GetStockObject(ANSI_FIXED_FONT), ptruint(FALSE));

      { allow scrolling a reasonable amount.  The exact amount should be      }
      { calculated based on the length of the longest string in the listbox   }
      { given the font it's using.  For this example we'll just use a         }
      { "reasonable" value.                                                   }

      SendMessage(Listbox, LB_SETHORIZONTALEXTENT, 1200, 0);

      SendMessage(Listbox, LB_ADDSTRING, 0, ptruint(ListboxHeader));
      SendMessage(Listbox, LB_ADDSTRING, 0, ptruint(BLANK_LINE));

      { populate it with the window handles and their caption text            }

      EnumWindows(@EnumWindowsProc,  ListBox); { pass the ListBox handle      }

      exit;
    end;

    WM_SIZE:
    begin
      { tell the status window to resize itself                               }

      StatWnd := GetDlgItem(Wnd, ID_STATWIN);   { StatWnd is a stack var      }
      SendMessage(StatWnd, WM_SIZE, 0, 0);

      { resize the Listbox.  The size of the listbox is the size of the main  }
      { window's client area minus the status bar's client area.              }

      GetClientRect(StatWnd, StatRect);

      Listbox := GetDlgItem(Wnd, ID_LISTBOX);
      MoveWindow(Listbox,
                 0,
                 0,
                 LOWORD(lParam),
                 HIWORD(lParam) - StatRect.Bottom,
                 TRUE);

      { work around the listbox bug that causes its display to be garbled     }
      { if the scroll bar is not at the origin and the window is resized.     }

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
      hInstance       := system.hInstance;            { qualify instance!     }
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

  Wnd := CreateWindowEx(0,
                        AppName,                { class name                  }
                        AppName,                { window caption text         }
                        ws_OverlappedWindow or  { window style                }
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        50,                     { x pos on screen             }
                        50,                     { y pos on screen             }
                        800,                    { window width                }
                        600,                    { window height               }
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

  WinMain := msg.wParam;                        { terminate with return code  }
end;

begin
  WinMain;
end.
