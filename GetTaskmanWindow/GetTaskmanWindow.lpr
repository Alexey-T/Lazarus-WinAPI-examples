{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetTaskmanWindow example'}

{$R GetTaskmanWindow.Res}

program _GetTaskmanWindow;
  { Win32 API function - GetTaskmanWindow example                             }

uses Windows, Messages, Resource, Sysutils;

const
  AppNameBase  = 'GetTaskmanWindow';

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


{ undocumented.  Missing in both FPC and Delphi                               }

function GetTaskmanWindow : HWND; stdcall; external user32;

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

procedure DrawWindowFrame(Wnd : HWND);
  { Draws a frame around the Wnd parameter                                    }
var
  dc         : HDC;
  WindowRect : TRECT;

  Pen        : HPEN;
  OldPen     : HPEN;

begin
  { a 5 pixel wide pen is a reasonable choice. Some windows are "tucked" under}
  { other child windows and a thin frame won't be visible because it falls    }
  { under the "tucked" area.                                                  }

  Pen := CreatePen(PS_INSIDEFRAME, 5, RGB(255, 0, 255));

  GetWindowRect(Wnd, WindowRect);              { the window rectangle         }

  {---------------------------------------------------------------------------}
  { convert the coordinates in WindowRect to be relative to the upper left    }
  { corner of the window.  At this time they are relative to the upper left   }
  { corner of the screen.  After the conversion the (Left, Top) coordinate in }
  { WindowRect will be (0, 0) which matches the preset (Left, Top) coordinate }
  { the window dc.                                                            }

  with WindowRect do OffsetRect(WindowRect, - Left, - Top);

  {---------------------------------------------------------------------------}
  { we need a dc that doesn't clip the output to the client area and that can }
  { be used to update a locked window (the window to be framed is locked).    }

  dc :=  GetDCEx(Wnd,
                 0,                      { no region                          }
                 DCX_WINDOW       or
                 DCX_CACHE        or
                 DCX_EXCLUDERGN   or     { excludes nothing because region = 0}
                 DCX_CLIPSIBLINGS or
                 DCX_LOCKWINDOWUPDATE);

  { select the pen and the brush used by the Rectangle API                    }

  OldPen := SelectObject(dc, Pen);
  SelectObject(dc, GetStockObject(NULL_BRUSH));  { only the frame gets drawn  }

  { select a raster op that causes the original pixels to be restored when the}
  { rectangle is drawn the second time.                                       }

  SetROP2(dc, R2_NOTXORPEN);

  {---------------------------------------------------------------------------}
  { draw a frame around (inside) the window rectangle                         }

  with WindowRect do
  begin
    Rectangle(dc, Left, Top, Right, Bottom);
  end;

  SelectObject(dc, OldPen);          { restore the original pen               }
  ReleaseDC(Wnd, dc);

  DeleteObject(Pen);                 { get rid of the pen                     }
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  GetTaskmanWindow_CALL = 'GetTaskmanWindow : HWND;';

  TaskmanWindow         : HWND = 0;

var
  ps          : TPAINTSTRUCT;
  ClientRect  : TRECT;
  Buffer      : packed array[0..255] of char;

  TextSize    : TSIZE;

  i           : integer;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      TaskmanWindow := GetTaskmanWindow();

      if TaskmanWindow = 0 then
      begin
        MessageBox(Wnd,
                   'failed to retrieve the task manager window',
                   'GetTaskmanWindow - WM_CREATE',
                   MB_ICONINFORMATION or MB_OK or MB_APPLMODAL);

        WndProc := -1;                            { abort window creation     }
        exit;
      end;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      { display the value of the task manager window                          }

      StrFmt(Buffer,
             'The task manager window handle is : $%x',
             [TaskmanWindow]);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Buffer,
              lstrlen(Buffer));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      lstrcpy(Buffer, GetTaskmanWindow_Call);

      GetTextExtentPoint32(ps.hdc,
                           Buffer,
                           lstrlen(Buffer),
                           TextSize);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom - TextSize.cy,
              Buffer,
              lstrlen(Buffer));

      {-----------------------------------------------------------------------}
      { we're done painting                                                   }

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_GETTASKMANWINDOW:
        begin
          for i := 1 to 10 do    { MUST be an EVEN number of times            }
          begin
            { cannot use FlashWindow because in "modern" versions of Windows  }
            { the task manager window does _not_ have a caption which is what }
            { FlashWindow alters.                                             }

            { the internal DrawWindowFrame will work for any window           }

            DrawWindowFrame(TaskmanWindow);
            sleep(100);                    { for "flash" effect               }
          end;

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
  ZeroMemory(@cls, sizeof(cls));

  cls.cbSize          := sizeof(TWndClassEx);           { must be initialized }

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