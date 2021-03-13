{$APPTYPE        GUI}

{$IFDEF FPC }
  {$ASMMODE INTEL }
{$ENDIF}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - IsDebuggerPresent example'}

{$R IsDebuggerPresent.Res}

program _IsDebuggerPresent;
  { Win32 API function - IsDebuggerPresent example                            }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'IsDebuggerPresent()';

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

{ neither Delphi 2 nor FPC v3.0.4 define IsDebuggerPresent() and Delphi 2     }
{ does NOT allow an open/close parentheses indicating an empty parameter list }

function IsDebuggerPresent                      { no () because of Delphi 2   }
         : BOOL; stdcall; external kernel32;


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
  IsDebuggerPresent_Call = 'IsDebuggerPresent() : BOOL;';

  Information            = 'IsDebuggerPresent() :  ';
  Instructions           = 'Use the IsDebuggerPresent() menu to cause a '     +
                           'break into the debugger (only if there is one.)';

  Yes                    = 'TRUE/Yes';
  No                     = 'FALSE/No';

var
  ps          : TPAINTSTRUCT;
  ClientRect  : TRECT;
  Buffer      : packed array[0..255] of char;

  TextSize    : TSIZE;
  YesNoString : pchar;

begin
  WndProc := 0;

  case Msg of
    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      { determine the height of the text to output (used for spacing)         }

      GetTextExtentPoint32(ps.hdc,
                           Information,
                           lstrlen(Information),
                           TextSize);

      {-----------------------------------------------------------------------}
      { output the Information and the Instructions                           }

      lstrcpy(Buffer, Information);

      YesNoString := No;
      if IsDebuggerPresent then YesNoString := Yes;
      lstrcat(Buffer, YesNoString);

      TextOut(ps.hdc,                       { the result of IsDebuggerPresent }
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 - TextSize.cy,
              Buffer,
              lstrlen(Buffer));

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 + TextSize.cy,
              Instructions,
              lstrlen(Instructions));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      lstrcpy(Buffer, IsDebuggerPresent_Call);

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
        IDM_ISDEBUGGERPRESENT:
        begin
          { if we are running under a debugger, break into it with an INT 3   }

          if IsDebuggerPresent() then DebugBreak();   { debugger stop here    }

          { the above statement can also be implemented as :                  }

          if IsDebuggerPresent() then
          begin
            asm int 3 end;       { same as DebugBreak() but "inline"          }
          end;

          exit;                  { debugger will stop here after the int 3    }
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
                        600,                    { window width                }
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
