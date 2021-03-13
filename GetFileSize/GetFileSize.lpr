{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetFileSize example'}

{$R GetFileSize.Res}

program _GetFileSize;
  { Win32 API function - GetFileSize example                                  }

  { NOTE: GetFileSize is NOT a reliable method of obtaining the file size.    }
  {       See MSDN for caveats on this function.                              }

  { Use GetFileSizeEx instead.                                                }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'GetFileSize';

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
  GetFileSize_Call
    = 'GetFileSize (File : THANDLE; DwordPtrSizeHigh : PDWORD) : DWORD;';

  FileHandle  : THANDLE = 0;

var
  ps          : TPAINTSTRUCT;
  ClientRect  : TRECT;
  Buf         : packed array[0..MAX_PATH] of char;
  TextSize    : TSIZE;

  Filename    : packed array[0..MAX_PATH] of char;
  FileSize    : DWORD;

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

      GetClientRect(Wnd, ClientRect);

      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      FileSize := GetFileSize(FileHandle, nil);   { get the file size         }

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

      StrFmt(Buf, '%s %d', ['Size: ', FileSize]);
      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 + TextSize.cy,
              Buf,
              lstrlen(Buf));


      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      lstrcpy(Buf, GetFileSize_Call);

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