{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - CS_HREDRAW and CS_VREDRAW example'}

{$R HREDRAW_VREDRAW.Res}

program _FlickerMin;
  { Win32 Techniques - CS_HREDRAW and CS_VREDRAW effects                      }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'CS_HREDRAW and CS_VREDRAW';

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

const
  user32  = 'user32';

{$ifdef VER90}
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
{$endif}

{$ifdef FPC}
  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(    Wnd  : HWND;
                         out Rect : TRECT)
           : BOOL; stdcall; external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL; stdcall; external user32 name 'GetMessageA';

  function GetTextExtentPoint32(dc      : HDC;
                                str     : pchar;
                                strlen  : integer;
                            out strsize : TSIZE)
           : BOOL; stdcall  external gdi32 name 'GetTextExtentPoint32A';

  function BeginPaint(    Wnd           : HWND;
                      out PaintStruct   : TPAINTSTRUCT)
           : HDC;  stdcall; external user32;
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
  Poem : packed array[1..16] of packed array[0..79] of char =
    (
     '   Vision                                                              ',
     '                                                                       ',
     '   Joyce Kilmer, 1886 - 1918                                           ',
     '                                                                       ',
     '   (for Aline)                                                         ',
     '                                                                       ',
     '   Homer, they tell us, was blind and could not see the beautiful faces',
     '   Looking up into his own and reflecting the joy of his dream,        ',
     '      Yet did he seem                                                  ',
     '   Gifted with eyes that could follow the gods to their holiest places.',
     '                                                                       ',
     '   I have no vision of gods, not of Eros with love-arrows laden,       ',
     '   Jupiter thundering death or of Juno his white-breasted queen,       ',
     '      Yet I have seen                                                  ',
     '   All of the joy of the world in the innocent heart of a maiden.      ',
     '                                                                       '
    );

var
  ps           : TPAINTSTRUCT;
  ClientRect   : TRECT;

  TextSize     : TSIZE;

  MenuState    : integer;
  Style        : ptruint;


  r            : integer;    { repetitions of poem                            }
  i            : integer;    { index of poem lines                            }

  y            : integer;    { y coordinates                                  }

const
  REPETITIONS  =    5;       { number of repetitions                          }
  SEPARATION   =   50;       { whitespace between repetitions                 }

  MARGIN_X     =   20;
  MARGIN_Y     =   20;

  COLUMN_2     =  500;
  COLUMN_3     = 1000;

begin
  WndProc := 0;

  case Msg of
    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);

      SelectObject(ps.hdc, GetStockObject(SYSTEM_FONT));
      SetBkMode(ps.hdc, TRANSPARENT);

      GetTextExtentPoint32(ps.hdc,
                           Poem[low(Poem)],
                           lstrlen(Poem[low(Poem)]),
                           TextSize);

      {-----------------------------------------------------------------------}
      { draw the text                                                         }

      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

      y := MARGIN_Y;
      for r := 1 to REPETITIONS do
      begin
        for i := low(Poem) to high(Poem) do
        begin
          TextOut(ps.hdc,                      { 1st column                   }
                  MARGIN_X,                    { x coordinate                 }
                  y + i * TextSize.cy,         { y    ""                      }
                  Poem[i],
                  lstrlen(Poem[i]));

          TextOut(ps.hdc,                      { 2nd column                   }
                  MARGIN_X + COLUMN_2,         { x coordinate                 }
                  y + i * TextSize.cy,         { y    ""                      }
                  Poem[i],
                  lstrlen(Poem[i]));

          TextOut(ps.hdc,                      { 3rd column                   }
                  MARGIN_X + COLUMN_3,         { x coordinate                 }
                  y + i * TextSize.cy,         { y    ""                      }
                  Poem[i],
                  lstrlen(Poem[i]));
        end;

        y := r * high(Poem) * TextSize.cy + SEPARATION;
      end;


      {-----------------------------------------------------------------------}
      { we're done painting                                                   }

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_TOGGLE_STYLE:
        begin
          { toggle the main window's CS_HREDRAW and CS_REDRAW class style     }

          MenuState := GetMenuState(GetMenu(Wnd),
                                    IDM_TOGGLE_STYLE, MF_BYCOMMAND);

          Style := GetClassLongPtr(Wnd, GCL_STYLE);

          if (MenuState and MF_CHECKED) <> 0 then
          begin
            { remove the class styles from the class and uncheck the          }
            { menu item.                                                      }

            Style := Style and (not (CS_HREDRAW or CS_VREDRAW));
            SetClassLongPtr(Wnd, GCL_STYLE, Style);

            CheckMenuItem(GetMenu(Wnd),
                          IDM_TOGGLE_STYLE,
                          MF_BYCOMMAND or MF_UNCHECKED);
          end
          else
          begin
            { include the class styles in the class and check the menu        }
            { item.                                                           }

            Style := Style or CS_HREDRAW or CS_VREDRAW;
            SetClassLongPtr(Wnd, GCL_STYLE, Style);

            CheckMenuItem(GetMenu(Wnd),
                          IDM_TOGGLE_STYLE,
                          MF_BYCOMMAND or MF_CHECKED);
          end;
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
  cls.cbSize          := sizeof(TWndClassEx);           { must be initialized }

  if not GetClassInfoEx (hInstance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;    // or CS_HREDRAW or CS_VREDRAW;
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