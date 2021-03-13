{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetModuleHandle example'}

{$R GetModuleHandleEx.Res}

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

{ function and constants missing in both Delphi 2 and FPC                     }

function GetModuleHandleEx(Flags      : DWORD;
                           ModuleName : pchar;
                       var Module     : HMODULE)
         : BOOL; stdcall; external 'kernel32' name 'GetModuleHandleExA';

const
  GET_MODULE_HANDLE_EX_FLAG_PIN                = $1;
  GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT = $2;
  GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS       = $4;

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
  GetModuleHandleEx_Call = 'GetModuleHandleEx (Flags : DWORD; '               +
                           'ModuleName : pchar; '                             +
                           'var Module : HMODULE) : HMODULE;';

  DllToLoad    : pchar = 'GetModuleHandleExDll';

  Labels       : packed array[1..3] of pchar
               = ('Address of DllFunction in dll : ',
                 'GetModuleHandleExDll''s address from LoadLibrary : ',
                 'GetModuleHandleExDll''s address from GetModuleHandleEx : ');

  Values       : packed array[1..3] of packed array[0..255] of char
               = (#0, #0, #0);

  MARGIN       = 110;           { estimate to make output look "centered"     }

var
  ModuleAddressA  : HMODULE;    { from LoadLibrary                            }
  ModuleAddressB  : HMODULE;    { from GetModuleHandleEx                      }

  FunctionAddress : pointer;    { address of DllFunction in supporting DLL    }

  ps              : TPAINTSTRUCT;
  ClientRect      : TRECT;
  Buf             : packed array[0..MAX_PATH] of char;
  TextSize        : TSIZE;

  I               : integer;    { "for" index                                 }

  LastError       : DWORD;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { load the supporting dll                                               }

      ModuleAddressA := LoadLibrary(DllToLoad);

      FunctionAddress := GetProcAddress(ModuleAddressA,
                                        pchar(DLL_FUNCTION_INDEX));

      { get the module address again but this time using the function address }

      if not GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS,
                               FunctionAddress,
                               ModuleAddressB) then
      begin
        LastError := GetLastError();

        MessageBox(Wnd,
                  'GetModuleHandleEx call failed in WM_CREATE',
                  'Main Window',
                   MB_ICONERROR or MB_OK);

        WndProc := -1;

        exit;
      end;

      { format and save the values obtained                                   }

      StrFmt(Values[1], ' %p', [FunctionAddress]);

      { the next two addresses should be the same                             }

      StrFmt(Values[2], ' %p', [pointer(ModuleAddressA)]);
      StrFmt(Values[3], ' %p', [pointer(ModuleAddressB)]);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      {-----------------------------------------------------------------------}
      { Display the Labels and their corresponding value                      }

      GetClientRect(Wnd, ClientRect);

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize); { get font's height     }

      SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);
      for I := low(Labels) to high(Labels) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - 2) * TextSize.cy,
                Labels[I],
                lstrlen(Labels[I]));
      end;

      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);
      for I := low(Values) to high(Values) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - 2) * TextSize.cy,
                Values[I],
                lstrlen(Values[I]));
      end;


      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      lstrcpy(Buf, GetModuleHandleEx_Call);

      { calculate the size of the output string                               }

      GetTextExtentPoint32(ps.hdc,
                           Buf,
                           lstrlen(Buf), TextSize);

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

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
        IDM_BYADDRESSANDPIN:
        begin
          if not GetModuleHandleEx(GET_MODULE_HANDLE_EX_FLAG_PIN,
                                   DllToLoad,
                                   ModuleAddressB) then
          begin
            LastError := GetLastError();

            MessageBox(Wnd,
                      'GetModuleHandleEx call failed in IDM_BYADDRESSANDPIN',
                      'Main Window',
                       MB_ICONERROR or MB_OK);

            WndProc := -1;

            exit;
          end;

          for i := 1 to 100 do FreeLibrary(ModuleAddressB);

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
                        600,                    { window width                }
                        300,                    { window height               }
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