{$APPTYPE GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetCharacterPlacement example'}

{$R GetCharacterPlacement.Res}

program _GetCharacterPlacement;
  { Win32 API function - GetCharacterPlacement example                        }

uses Windows, Messages, Resource;

const
  AppNameBase  = 'GetCharacterPlacement Example';

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

{ NOTE: the parameter _names_ and the structure name present in the following }
{       definition differ from those in the MSDN definition.                  }

type
  TGCP_RESULTSA = TGCPResults;       { the original name is "ugly"            }

function GetCharacterPlacement(dc                   : HDC;
                               Str                  : pchar;
                               CharCount            : integer;
                               MaxExtent            : integer;
                           var PlacementResults     : TGCP_RESULTSA;
                               PlacementFlags       : DWORD)
          : DWORD; stdcall; external gdi32 name 'GetCharacterPlacementA';

{-----------------------------------------------------------------------------}
{ this kernel32 function is forwarded to NTDLL RtlZeroMemory                  }

procedure RtlZeroMemory(Address   : pointer;
                        ByteCount : DWORD);
          stdcall; external kernel32;

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

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  GetCharacterPlacement_Call
    = 'GetCharacterPlacement (dc : HDC; str : pchar; '                        +
      'CharCount, MaxExtent : integer; '                                      +
      'var PlacementResults : TGCP_RESULTS; PlacementFlags : DWORD) : DWORD;';

  Text          = 'FFFFFFFF';
  WidthInPixels = 200;                  { if changed, change Info msg below   }

  Info  = 'The string '                                                       +
          Text + ' '                                                          +
          'spread over ' + { WidthInPixels } '200 pixels '                    +
          'as calculated by GetCharacterPlacement '                           +
          'and output by ExtTextOut';

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;
  Placement          : TGCP_RESULTSA;
  StringFit          : packed array[0..2047] of char;
  DistancesX         : packed array[0..2047] of integer;

begin
  WndProc := 0;

  case Msg of
    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      { draw the information line                                             }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize);{ to get font height     }
      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 - (3 * TextSize.cy),
              Info,
              lstrlen(Info));

      { calculate the placement of the text string over the WidthInPixels     }
      { desired.                                                              }

      RtlZeroMemory(@Placement, sizeof(Placement));
      with Placement do
      begin
        lStructSize := sizeof(Placement);
        lpOutString := @StringFit[0];
        lpDx        := @DistancesX;
        nGlyphs     := sizeof(StringFit);
        nMaxFit     := 0;
      end;

      GetCharacterPlacement(ps.hdc,
                            Text,
                            8,
                            WidthInPixels,
                            Placement,
                            GCP_JUSTIFY or GCP_MAXEXTENT);

      ExtTextOut(ps.hdc,
                 ClientRect.Right  div 2,
                 ClientRect.Bottom div 2,
                 ETO_OPAQUE,
                 nil,
                 Text,
                 8,
                 @DistancesX);

      { --------------------------------------------------------------------- }
      { draw the function call                                                }

      lstrcpy(Buf, GetCharacterPlacement_Call);  { not really necessary       }

      TextOut(ps.hdc,
              ClientRect.Right div 2,
              ClientRect.Bottom - TextSize.cy,
              Buf,                               { could use Get..._Call here }
              lstrlen(Buf));                     { and here instead of Buf    }

      { --------------------------------------------------------------------- }
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
  cls   : TWndClassEx;

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
  else InitAppClass := True;
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
                        50,                     { x pos on screen             }
                        50,                     { y pos on screen             }
                        860,                    { window width                }
                        200,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        hInstance,              { instance handle             }
                        Nil);                   { parameter sent to WM_CREATE }

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
