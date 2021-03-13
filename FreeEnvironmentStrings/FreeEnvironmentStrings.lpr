{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - FreeEnvironmentStrings example'}

{$R FreeEnvironmentStrings.Res}

program _FreeEnvironmentStrings;
  { Win32 API function - FreeEnvironmentStrings example                       }

  { NOTE:                                                                     }
  {                                                                           }
  { In the retail version of Windows 95 this function validates its parameter }
  { and returns.  If the parameter is valid it returns TRUE otherwise it      }
  { returns FALSE.  In other words, under Windows 95, it does _not_ free the  }
  { environment block.  Also, the parameter passed to this function _must_ be }
  { the value returned by GetEnvironmentStrings, passing a pointer to a copy  }
  { of the environment block will cause the function to fail and the block to }
  { remain allocated.                                                         }
  {                                                                           }
  { ADDITIONAL INFORMATION:                                                   }
  {                                                                           }
  { See Windows 95 System Programming Secrets, page 120 for more information. }
  {                                                                           }
  { REFERENCES: Windows 95 System Programming Secrets, Matt Pietrek,          }
  {             ISBN: 1-56884-318-6                                           }
  {                                                                           }
  { Under later versions of Windows this function does free a block of memory }
  { that contains the environment strings.                                    }
  {---------------------------------------------------------------------------}

uses Windows, Messages, Resource;

const
  AppNameBase  = 'FreeEnvironmentStrings';

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

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  FreeEnvironmentStrings_Call
    = 'FreeEnvironmentStrings (EnvironmentPointer : pchar) : BOOL;';

  CallLabel          = 'FreeEnvironmentStrings (GetEnvironmentStrings) : ';

var
  ps                 : TPAINTSTRUCT;
  ClientRect         : TRECT;
  Buf                : packed array[0..255] of char;
  TextSize           : TSIZE;

  EnvironmentStrings : pchar;

begin
  WndProc := 0;

  case Msg of
    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);

      {-----------------------------------------------------------------------}
      { setup the dc                                                          }

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize);  { get font's height    }

      {-----------------------------------------------------------------------}
      { call FreeEnvironmentStrings and display its return value.             }

      lstrcpy(Buf, CallLabel);
      EnvironmentStrings := GetEnvironmentStrings;  { get the strings         }
      if FreeEnvironmentStrings(EnvironmentStrings) { now free them           }
      then lstrcat(Buf, 'TRUE')
      else lstrcat(Buf, 'FALSE');

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      lstrcpy(Buf, FreeEnvironmentStrings_Call);

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
                        ws_Overlapped       or  { window style                }
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        400,                    { window width                }
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