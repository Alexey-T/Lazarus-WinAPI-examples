{$APPTYPE        GUI}

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

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;
{$endif}

{-----------------------------------------------------------------------------}

{ NOTE: the parameter _names_ and the structure name present in the following }
{       definition differ from those in the MSDN definition.                  }

type
  TGCP_RESULTSA = TGCPResults;       { the original name is "ugly"            }

function GetCharacterPlacement(dc              : HDC;
                               StringText      : pchar;
                               CharCount       : integer;
                               MaxExtent       : integer;
                           var PlacementResult : TGCP_RESULTSA;
                               PlacementFlags  : DWORD)
         : DWORD; stdcall; external gdi32 name 'GetCharacterPlacementA';

{-----------------------------------------------------------------------------}

{ NOTE: kernel32's RtlZeroMemory is forwarded to NTDLL's RtlZeroMemory        }

procedure RtlZeroMemory(DestinationAddress : pointer;
                        ByteCount          : ptruint);
          stdcall; external kernel32;

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
  GetCharacterPlacement_Call
    = 'GetCharacterPlacement (dc : HDC; str : pchar; '                        +
      'CharCount, MaxExtent : integer; '                                      +
      'var PlacementResults : TGCP_RESULTS; PlacementFlags : DWORD) : DWORD;';


  CHARACTER_COUNT =  8;                  { 8 characters in each Text string   }
  MAX_EXTENT      = 64;                  { up to 64 device units (pixels in   }
                                         { this example.)                     }

  TOP_MARGIN      =  4;                  { * TextSize.cy                      }

  Text  : packed array[0..18] of pchar =
    ('00000000', '11111111', '22222222', '33333333', '44444444',
     '55555555', '66666666', '77777777', '88888888', '99999999',
     'AAAAAAAA', 'BBBBBBBB', 'CCCCCCCC', 'DDDDDDDD', 'EEEEEEEE',
     'FFFFFFFF', '81718280', '81718D10', '8171D7FC');

  { use the different distances below to see the effects of those arrays      }
  { in the output.                                                            }

  TestDistanceB : packed array[0..9] of integer =
    ($6, $6, $6, $6, $6, $6, $6, $6, $6, $6);

  TestDistanceA : packed array[0..9] of integer =
    ($7, $7, $7, $7, $7, $7, $7, $7, $7, $7);

  TestDistanceActive : packed array[0..9] of integer =      { active set      }
    ($8, $8, $8, $8, $8, $8, $8, $8, $8, $8);

  TestDistanceD : packed array[0..9] of integer =
    ($9, $9, $9, $9, $9, $9, $9, $9, $9, $9);

  TestDistanceE : packed array[0..9] of integer =
    ($A, $A, $A, $A, $A, $A, $A, $A, $A, $A);

  TestDistanceF : packed array[0..9] of integer =
    ($10, $10, $10, $10, $10, $10, $10, $10, $0, $0);

  TestDistanceG : packed array[0..9] of integer =
    ($1B, $1B, $1B, $1B, $1B, $1B, $1B, $1B, $0, $0);

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;
  Placement          : TGCP_RESULTSA;                  { ASCII version        }
  StringFit          : packed array[0..2047] of char;
  Distance           : packed array[0..2047] of integer;

  I                  : integer;

  CoordinateY        : integer;

  Height             : integer;

begin
  WndProc := 0;

  case Msg of
    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);       { we'll use this quite often      }
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

      { use a proportionally spaced font                                      }

      SelectObject(ps.hdc, GetStockObject(ANSI_VAR_FONT));

      { calculate the size of the function definition string.  We can use the }
      { height of the string for coordinate calculations.                     }

      GetTextExtentPoint32(ps.hdc,
                           GetCharacterPlacement_Call,
                           lstrlen(GetCharacterPlacement_Call), TextSize);

      Height := TextSize.cy;

      for I := low(Text) to high(Text) do
      begin
        RtlZeroMemory(@Placement, sizeof(Placement));

        with Placement do
        begin
          lStructSize := sizeof(Placement);
          lpOutString := @StringFit[0];
          lpDx        := @Distance;        { array of distances for ExtTextOut}
          nGlyphs     := sizeof(StringFit);
          nMaxFit     := 0;
        end;

        GetCharacterPlacement(ps.hdc,
                              Text[I],
                              CHARACTER_COUNT,
                              MAX_EXTENT,
                              Placement,   { make the string fit MAX_EXTENT   }
                              GCP_JUSTIFY or GCP_MAXEXTENT);

        { NOTE: (Height+2) to increase the spacing between lines by 2 pixels  }
        {       (strictly cosmetic)                                           }

        CoordinateY := ClientRect.Top + (I * (Height+2)) + TOP_MARGIN * Height;

        SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);
        ExtTextOut(ps.hdc,
                   ClientRect.Right div 3,
                   CoordinateY,
                   ETO_OPAQUE,
                   nil,
                   Text[I],
                   CHARACTER_COUNT,
                   @TestDistanceActive);   { change to test other distances   }

        SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);
        ExtTextOut(ps.hdc,
                   ClientRect.Right - ClientRect.Right div 3,
                   CoordinateY,
                   ETO_OPAQUE,
                   nil,
                   Text[I],
                   CHARACTER_COUNT,
                   nil);                   { nil to use the font's distances  }

      end;

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      lstrcpy(Buf, GetCharacterPlacement_Call);
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
    with cls do begin
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
                        50,                     { x pos on screen             }
                        50,                     { y pos on screen             }
                        860,                    { window width                }
                        450,                    { window height               }
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