{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetFileSizeEx example'}

{$R GetFileSizeEx.Res}

program _GetFileSizeEx;
  { Win32 API function - GetFileSizeEx example                                }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'GetFileSizeEx';

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

  TLARGE_INTEGER = record
    LowPart         : DWORD;
    HighPart        : longint;
  end;
  PLARGE_INTEGER = ^TLARGE_INTEGER;

  LARGE_INTEGER  = TLARGE_INTEGER;
{$endif}


{-----------------------------------------------------------------------------}
{ this function is missing in Delphi 2 and FPC v3.0.4                         }

function GetFileSizeEx(FileHandle : THANDLE; var FileSize : LARGE_INTEGER)
         : BOOL; stdcall; external kernel32;


{-----------------------------------------------------------------------------}
{ we use this function from ntdll to format the large integers returned by    }
{ GetFileSizeEx.  (Delphi 2 does not provide means to format large integers)  }

const
  ntdll = 'ntdll';

function  _i64toa      (value       : LARGE_INTEGER;
                        Destination : pchar;
                        Base        : integer)
          : pchar; cdecl; external ntdll;

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
  GetFileSizeEx_Call
    = 'GetFileSizeEx (File : THANDLE; var FileSize : LARGE_INTEGER) : BOOL;';

  FileHandle  : THANDLE = 0;

  BASE10                = 10;  { to let _i64toa that we want base 10 value    }

var
  ps          : TPAINTSTRUCT;
  ClientRect  : TRECT;
  Buf         : packed array[0..MAX_PATH] of char;
  TextSize    : TSIZE;

  Filename    : packed array[0..MAX_PATH] of char;
  FileSize    : LARGE_INTEGER;
  FileSizeChar: packed array[0..63] of char;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      GetModuleFileName(GetModuleHandle(nil), Filename, sizeof(Filename));

      { open the file to get a useable file handle                            }

      FileHandle := CreateFile(Filename,
                               0,
                               FILE_SHARE_READ,
                               nil,
                               OPEN_EXISTING,
                               0,
                               0);

      { NOTE: in this example we get the filesize every time we process a     }
      {       WM_PAINT message.  This is not very efficient, time consuming   }
      {       operations (such as file operations) are better not performed   }
      {       in a WM_PAINT.  It is done in this example only to show that    }
      {       while not desirable, it can be done if necessary.               }

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      GetFileSizeEx(FileHandle, FileSize);

      GetModuleFileName(0, Filename, sizeof(Filename));
      StrFmt(Buf, '%s%s', ['File: ', Filename]);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      SelectObject(ps.hdc, GetStockObject(SYSTEM_FONT));

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf),
                           TextSize);

      _i64toa(FileSize, FileSizeChar, BASE10);  { format 64 bit integer       }

      StrFmt(Buf, '%s %s', ['Size: ', FileSizeChar]);
      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 + TextSize.cy,
              Buf,
              lstrlen(Buf));


      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      lstrcpy(Buf, GetFileSizeEx_Call);

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
      if FileHandle <> 0 then CloseHandle(FileHandle);

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
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        500,                    { window width                }
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