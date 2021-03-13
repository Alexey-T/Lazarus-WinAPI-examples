{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetNativeSystemInfo example'}

{$R GetNativeSystemInfo.Res}

program _GetNativeSystemInfo;
  { Win32 API function - GetNativeSystemInfo example                          }

uses Windows, Messages, Resource, SysUtils;

const
  AppNameBase  = 'GetNativeSystemInfo';

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

{ this function is missing in both Delphi 2 and FPC v3.0.4                    }

procedure GetNativeSystemInfo(var SystemInfo : TSYSTEMINFO);
          stdcall; external kernel32;

const
  { constants used with GetNativeSystemInfo missing in Delphi 2.0             }

  PROCESSOR_ARCHITECTURE_INTEL   =     0;
  PROCESSOR_ARCHITECTURE_MIPS    =     1;
  PROCESSOR_ARCHITECTURE_ALPHA   =     2;
  PROCESSOR_ARCHITECTURE_PPC     =     3;
  PROCESSOR_ARCHITECTURE_ARM     =     5;
  PROCESSOR_ARCHITECTURE_IA64    =     6;
  PROCESSOR_ARCHITECTURE_AMD64   =     9;
  PROCESSOR_ARCHITECTURE_ARM64   =    12;
  PROCESSOR_ARCHITECTURE_UNKNOWN = $FFFF;

const
  { processor type constants (there are more of these.  See MSDN)             }

  PROCESSOR_INTEL_386            =   386;
  PROCESSOR_INTEL_486            =   486;
  PROCESSOR_INTEL_PENTIUM        =   586;
  PROCESSOR_INTEL_IA64           =  2200;

  PROCESSOR_AMD_X8664            =  8664;

  PROCESSOR_MIPS_R4000           =  4000;
  PROCESSOR_ALPHA_21064          = 21064;

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
{ this function is used to obtain a string from bit masks                     }

function BinaryD(Dest : pchar; D : DWORD) : pchar;
  { convert a 32 bit value into its binary string representation (0s and 1s)  }
  { NOTE: ntdll's _itoa can replace this function                             }
const
  Digits : packed array[0..1] of char = '01';

var
  I : DWORD;

begin
  BinaryD := Dest;

  for I := sizeof(DWORD) * 8 - 1 downto 0 do
  begin
    Dest^ := Digits[DWORD((D and DWORD(1 shl I)) <> 0)];
    inc(Dest);
  end;

  Dest^ := #0;     { null terminate the resulting string                      }
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  GetNativeSystemInfo_Call
    = 'GetNativeSystemInfo (var SystemInfo : TSYSTEMINFO);';

  Labels             : packed array[1..11] of pchar
    = ('Processor Architecture : ',
       'Reserved : ',
       'Page Size : ',
       'Minimum Application Address : ',
       'Maximum Application Address : ',
       'Active Processor Mask : ',
       'Number of Processors : ',
       'Processor Type : ',
       'Allocation Granularity : ',
       'Processor Level : ',
       'Processor Revision : ');

  Values             : packed array[1..11] of packed array[0..63] of char
    = (#0, #0, #0, #0, #0, #0, #0, #0, #0, #0, #0);

  MARGIN        = -30;              { to make things look centered            }

var
  ps            : TPAINTSTRUCT;
  ClientRect    : TRECT;
  SystemInfo    : TSYSTEMINFO;
  Buf           : packed array[0..255] of char;
  TextSize      : TSIZE;
  I             : DWORD;

  Architecture  : pchar;
  Processor     : pchar;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      ZeroMemory(@SystemInfo, sizeof(SystemInfo));   { profilactic            }

      GetNativeSystemInfo(SystemInfo);

      { format the values in SystemInfo and save them in the Values array     }

      with SystemInfo do
      begin
        case wProcessorArchitecture of
          PROCESSOR_ARCHITECTURE_INTEL:
            Architecture := 'PROCESSOR_ARCHITECTURE_INTEL';
          PROCESSOR_ARCHITECTURE_MIPS:
            Architecture := 'PROCESSOR_ARCHITECTURE_MIPS';
          PROCESSOR_ARCHITECTURE_ALPHA:
            Architecture := 'PROCESSOR_ARCHITECTURE_ALPHA';
          PROCESSOR_ARCHITECTURE_PPC:
            Architecture := 'PROCESSOR_ARCHITECTURE_PPC';
          PROCESSOR_ARCHITECTURE_ARM:
            Architecture := 'PROCESSOR_ARCHITECTURE_ARM';
          PROCESSOR_ARCHITECTURE_IA64:
            Architecture := 'PROCESSOR_ARCHITECTURE_IA64';
          PROCESSOR_ARCHITECTURE_AMD64:
            Architecture := 'PROCESSOR_ARCHITECTURE_AMD64';
          PROCESSOR_ARCHITECTURE_ARM64:
            Architecture := 'PROCESSOR_ARCHITECTURE_ARM64';
          PROCESSOR_ARCHITECTURE_UNKNOWN:
            Architecture := 'PROCESSOR_ARCHITECTURE_UNKNOWN';
        else
            Architecture := 'PROCESSOR_ARCHITECTURE_UNKNOWN_F';
        end; { case }

        lstrcpy(Values[1], Architecture);

        StrFmt(Values[2], '%4.4x', [wReserved]);
        StrFmt(Values[3], '%.0n',  [dwPageSize + 0.0]);
        StrFmt(Values[4], '$%p',   [lpMinimumApplicationAddress]);
        StrFmt(Values[5], '$%p',   [lpMaximumApplicationAddress]);
        BinaryD(Values[6], dwActiveProcessorMask);
        StrFmt(Values[7], '%d',    [dwNumberOfProcessors]);

        case dwProcessorType of
          PROCESSOR_INTEL_386:
            Processor := 'PROCESSOR_INTEL_386';
          PROCESSOR_INTEL_486:
            Processor := 'PROCESSOR_INTEL_486';
          PROCESSOR_INTEL_PENTIUM:
            Processor := 'PROCESSOR_INTEL_PENTIUM';
          PROCESSOR_INTEL_IA64:
            Processor := 'PROCESSOR_INTEL_IA64';
          PROCESSOR_AMD_X8664:
            Processor := 'PROCESSOR_AMD_X8664';
          PROCESSOR_MIPS_R4000:
            Processor := 'PROCESSOR_MIPS_R4000';
          PROCESSOR_ALPHA_21064:
            Processor := 'PROCESSOR_ALPHA_21064';
        else
            Processor := 'PROCESSOR_UNKNOWN_F';
        end;

        lstrcpy(Values[8], Processor);

        { use %.0n to get commas in the number formatting                     }

        StrFmt(Values[9],  '%.0n', [dwAllocationGranularity + 0.0]);
        StrFmt(Values[10],   '%d', [wProcessorLevel]);
        StrFmt(Values[11],   '%d', [wProcessorRevision]);
      end;

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize);

      {-----------------------------------------------------------------------}
      { display the labels and their values                                   }

      SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);

      for I := low(Labels) to high(Labels) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - 6) * TextSize.cy,
                Labels[I],
                lstrlen(Labels[I]));
      end;

      SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

      for I := low(Values) to high(Values) do
      begin
        TextOut(ps.hdc,
                ClientRect.Right  div 2 + MARGIN,
                ClientRect.Bottom div 2 + (I - 6) * TextSize.cy,
                Values[I],
                lstrlen(Values[I]));
      end;

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      lstrcpy(Buf, GetNativeSystemInfo_Call);

      { calculate the size of the output string                               }

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
  cls.cbSize            := sizeof(TWndClassEx);         { must be initialized }

  if not GetClassInfoEx (hInstance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above               }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @WndProc;                    { window class handler}
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;            { qualify instance!   }
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, idc_arrow);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := APPMENU;                     { Menu name           }
      lpszClassName   := AppName;                     { Window Class name   }
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
                        450,                    { window width                }
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