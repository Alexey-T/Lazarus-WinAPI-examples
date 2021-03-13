{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - RtlGetNtVersionNumbers example'}

{$R RtlGetNtVersionNumbers.Res}

program _RtlGetNtVersionNumbers;
  { Win32 API function - RtlGetNtVersionNumbers example (undocumented)        }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'RtlGetNtVersionNumbers';

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
{ define RtlGetNtVersionNumbers for Delphi 2 and FPC                          }

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;

  procedure RtlGetNtVersionNumbers(var MajorVersion : DWORD;
                                   var MinorVersion : DWORD;
                                   var Build        : DWORD);
            stdcall; external 'ntdll.dll';
{$endif}


{$ifdef FPC}
  procedure RtlGetNtVersionNumbers(out MajorVersion : DWORD;
                                   out MinorVersion : DWORD;
                                   out Build        : DWORD);
            stdcall; external 'ntdll.dll';
{$endif}

{-----------------------------------------------------------------------------}

const
  BUILD_FREE_VAL  = word($F000);

  BUILD_FREE_STR  = 'Free build';
  BUILD_CHKD_STR  = 'Checked build';

  BuildString     : pchar = BUILD_FREE_STR;

type
  TBuildRec = packed record
    br_BuildNumber     : word;
    br_FreeChecked     : word;                { indicates free or checked     }
  end;

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

type
  TVersionData = (vd_major, vd_minor, vd_build);  { prefix : vd_              }

const
  RtlGetNtVersionNumbers_Call
    = 'RtlGetNtVersionNumbers(var MajorVersion, MinorVersion, Build : DWORD);';


  Labels : packed array[ord(low(TVersionData))..ord(high(TVersionData)) + 1]
           of pchar = ('Windows Major Version : ',
                       'Windows Minor Version : ',
                       'Build number          : ',
                       'Free/Checked          : ');    { reason for the + 1   }


  { the first 3 values are returned by RtlGetNtVersionNumbers, the 4th value  }
  { is that of BuildString which is determined using the build number.        }

  Values : packed array[TVersionData] of DWORD = (0, 0, 0);

  MARGIN          = 35;                     { makes the output look centered  }
  OFFSET_FROM_TOP =  2;

var
  ps              : TPAINTSTRUCT;
  ClientRect      : TRECT;
  Buf             : packed array[0..255] of char;
  TextSize        : TSIZE;

  I               : DWORD;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      RtlGetNtVersionNumbers(Values[vd_major],
                             Values[vd_minor],
                             Values[vd_build]);

      { determine if it is the checked or free build                          }

       with TBuildRec(Values[vd_build]) do
       begin
         if br_FreeChecked <> BUILD_FREE_VAL then BuildString := BUILD_CHKD_STR;

         { get rid of the BUILD_FREE_VAL "flag"/indicator                     }

         Values[vd_build] := br_BuildNumber;
       end;

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }
      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize);   { get font height     }

      {-----------------------------------------------------------------------}
      { display the values returned by RtlGetNtVersionNumbers                 }

      SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);

      for I := low(Labels) to high(Labels) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - OFFSET_FROM_TOP) * TextSize.cy,
                Labels[I],
                lstrlen(Labels[I]));
      end;

      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

      for I := ord(low(TVersionData)) to ord(high(TVersionData)) do
      begin
        StrFmt(Buf, '%d', [Values[TVersionData(I)]]);
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - OFFSET_FROM_TOP) * TextSize.cy,
                Buf,
                lstrlen(Buf));
      end;

      { output the free/checked build indicator                               }

      i := high(Labels);

      TextOut(ps.hdc,
              ClientRect.Right  div 2 + MARGIN,
              ClientRect.Bottom div 2 + (I - OFFSET_FROM_TOP) * TextSize.cy,
              BuildString,
              lstrlen(BuildString));

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      lstrcpy(Buf, RtlGetNtVersionNumbers_Call);

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
