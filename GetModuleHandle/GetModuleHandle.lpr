{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetModuleHandle example'}

{$R GetModuleHandle.Res}

program _GetModuleHandle;
  { Win32 API function - GetModuleHandle example                              }

uses Windows, Messages, Resource, SysUtils;

const
  AppNameBase  = 'GetModuleHandle';

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
  GetModuleHandle_Call = 'GetModuleHandle (ModuleName : pchar) : HMODULE;';

  { string for second menu item                                               }

  MenuItemKernel32         = '&Kernel32''s';
  MenuItemKernelBase       = '&KernelBase''s';

  GETMODULEHANDLE_MENUITEM = 1;       { 0 based index of GetMenuHandle popup  }

  { message displayed (varies depending on which module handle is selected    }

  TextThisProgram  = 'this program''s load address : ';

  TextKernel32     = 'kernel32''s load address : ';
  TextKernelBase   = 'KernelBase''s load address : ';

  TextMsg          : pchar = TextThisProgram;       { initial/default value   }

  { dlls to load - Kernel32 for 32 bit program, KernelBase for 64 bit program }

  Kernel32         = 'KERNEL32';
  KernelBase       = 'KERNELBASE';

  ModuleHandle     : HMODULE = 0;

var
  ps               : TPAINTSTRUCT;
  ClientRect       : TRECT;
  Buf              : packed array[0..MAX_PATH] of char;
  TextSize         : TSIZE;

  procedure BitnessError;
  begin
    MessageBox(Wnd,
              'Unable to properly set the program''s menu item choices',
              'Main Window',
               MB_ICONERROR or MB_OK);
  end;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      case sizeof(pointer) of
        4 :                                     { 32 bit program              }
        begin
          if not ModifyMenu(GetSubMenu(GetMenu(Wnd), GETMODULEHANDLE_MENUITEM),
                            IDM_KERNEL32,
                            MF_BYCOMMAND or MF_STRING,
                            IDM_KERNEL32,
                            MenuItemKernel32) then
          begin
            BitnessError();

            WndProc := -1;

            exit;
          end;

        end;

        8 :                                     { 64 bit program              }
        begin
          { running as 64 bit - use kernelbase instead of kernel32            }

          if not ModifyMenu(GetSubMenu(GetMenu(Wnd), GETMODULEHANDLE_MENUITEM),
                            IDM_KERNEL32,
                            MF_BYCOMMAND or MF_STRING,
                            IDM_KERNEL32,
                            MenuItemKernelBase) then
          begin
            BitnessError();

            WndProc := -1;

            exit;
          end;


        end;

        else                                    { neither 32 nor 64 bit       }
        begin
          { some bitness we are not ready to handle                           }

          MessageBox(Wnd,
                    'This program can only be run as a 32 or 64 bit program',
                    'Main Window',
                     MB_ICONERROR or MB_OK);

          WndProc := -1;

          exit;
        end;
      end;

      { initialize the ModuleHandle that will initially be shown              }

      PostMessage(Wnd, WM_COMMAND, IDM_THISPROGRAM, 0);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);

      { display the requested module handle                                   }

      StrFmt(Buf, '%s$%8.8x', [TextMsg, ModuleHandle]);

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetBkMode(ps.hdc, TRANSPARENT);

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      lstrcpy(Buf, GetModuleHandle_Call);

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
        IDM_THISPROGRAM:
        begin
          ModuleHandle := GetModuleHandle(nil);
          TextMsg      := TextThisProgram;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_THISPROGRAM,
                             IDM_KERNEL32,
                             IDM_THISPROGRAM,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_KERNEL32:
        begin
          case sizeof(pointer) of
            4 :
            begin
              ModuleHandle := GetModuleHandle(KERNEL32);
              TextMsg      := TextKernel32;
            end;

            8 :
            begin
              ModuleHandle := GetModuleHandle(KERNELBASE);
              TextMsg      := TextKernelBase;
            end;

            { cannot fail - any other bitness is caught during WM_CREATE      }
          end;

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_THISPROGRAM,
                             IDM_KERNEL32,
                             IDM_KERNEL32,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);

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