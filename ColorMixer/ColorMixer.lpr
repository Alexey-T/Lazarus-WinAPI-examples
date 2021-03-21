//{$define SHOW_RECTANGLE_COORDINATES}   { outputs coordinates on a console   }

{$ifdef SHOW_RECTANGLE_COORDINATES}
  {$APPTYPE      CONSOLE}
{$else}
  {$APPTYPE      GUI}
{$endif}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API Utility - Color mixer'}


{$R Colormixer.Res}


{-----------------------------------------------------------------------------}
{ manifests needed to get better looking scroll bars                          }

{$ifdef WIN32}
  {$R Manifest32.res}
{$endif}

{$ifdef WIN64}
  {$R Manifest64.res}
{$endif}


{-----------------------------------------------------------------------------}

//{$define SHOW_TEXT_FRAME} { activate to draw a frame around the sample text }

{ the sample text overwrites the frame drawn when SHOW_TEXT_FRAME is active.  }
{ to see the frame deactivate SHOW_SAMPLE_TEXT.  In other words, either the   }
{ frame is visible or the sample text is visible, both cannot be visible at   }
{ the same time.                                                              }

{$define SHOW_SAMPLE_TEXT}

{ define NO_SAMPLE_TEXT_FLICKER to eliminate flicker when the sample text is  }
{ drawn/painted.  When this define is not active, the sample text will        }
{ occasionally flicker when the color is changed using the scroll bars.       }

{$define NO_SAMPLE_TEXT_FLICKER}

{ the "default"/normal/desirable settings for the above defines are :         }
{                                                                             }
{ SHOW_TEXT_FRAME               commented out/inactive                        }
{ SHOW_SAMPLE_TEXT              defined                                       }
{ NO_SAMPLE_TEXT_FLICKER        defined                                       }

{-----------------------------------------------------------------------------}


program _Color;
  { Win32 API Utility - Color mixer                                           }

uses
  Windows,
  Messages,
  Sysutils,
  Resource
  ;

const
  AppNameBase  = 'Color mixer';

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
  ptruint = DWORD;          { NOTE: there is no true DWORD in Delphi 2        }
  UINT    = DWORD;
{$endif}


{$ifdef VER90}
  { for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms   }
  { if GetWindowLong and SetWindowLong respectively.                          }

  function GetWindowLongPtr(Wnd   : HWND;
                            Index : ptrint)
           : ptruint; stdcall; external user32 name 'GetWindowLongA';

  function SetWindowLongPtr(Wnd     : HWND;
                            Index   : ptrint;
                            NewLong : ptruint)
           : ptruint; stdcall; external user32 name 'SetWindowLongA';

  function GetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint)
           : ptruint; stdcall; external user32 name 'GetClassLongA';

  function SetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint;
                           NewLong  : ptruint)
           : ptruint; stdcall; external user32 name 'SetClassLongA';

const
  { better/clearer constant names than those specified in MSDN                }

  RGN_NULL      = 1;
  RGN_SIMPLE    = 2;
  RGN_COMPLEX   = 3;
  RGN_ERROR     = 0;
{$endif}

type
  { the following definitions are needed to make Delphi and FPC happy with    }
  { CallWindowProc.                                                           }

  TWNDPROC = function (Wnd            : HWND;
                       Msg            : DWORD;
                       wParam         : ptruint;     { instead of WPARAM      }
                       lParam         : ptrint)      { instead of LPARAM      }
             : ptrint; stdcall;

  function CallWindowProc(PrevWndProc : TWNDPROC;    { TWNDPROC not WNDPROC   }
                          Wnd         : HWND;
                          Msg         : DWORD;
                          wParam      : ptruint;
                          lParam      : ptrint)
           : ptrint;   stdcall; external user32 name 'CallWindowProcA';

{$ifdef FPC}
  { better API definitions to improve what's shown by CODETOOLS               }

  {$include FPC_API_DEFINITIONS}
{$endif}

{-----------------------------------------------------------------------------}

function Min(a, b : ptrint) : ptrint;
begin
  result := b;
  if a < b then result := a;
end;

{-----------------------------------------------------------------------------}

function Max(a, b : ptrint) : ptrint;
begin
  result := b;
  if a > b then result := a;
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

type
  TCOLORS             = (red, green, blue);

const
  SCROLLBAR_ID_BASE   = 100;

  ColorBars           : array[TCOLORS] of HWND   { scrollbar windows          }
                      = (0, 0, 0);

  ColorBarIdFocused   : ptrint                   { scrollbar id that has the  }
                      = ord(low(TCOLORS));       { focus                      }

  ColorBarWndProcPrev : pointer
                      = nil;

{-----------------------------------------------------------------------------}

function ColorBarWndProc (Wnd : HWND;
                          Msg : UINT; wParam : ptruint; lParam : ptrint)
         : ptrint; stdcall;
var
  ColorBarIdNext : ptrint;
  ColorBarIdPrev : ptrint;

begin
  ColorBarWndProc := 0;

  if (Msg = WM_KEYDOWN) and (wParam = VK_TAB) then
  begin
    { determine which scrollbar should get the focus                          }

    ColorBarIdNext := ColorBarIdFocused + 1;
    if ColorBarIdNext > ord(high(TCOLORS)) then
    begin
      ColorBarIdNext := ord(low(TCOLORS));
    end;

    ColorBarIdPrev := ColorBarIdFocused - 1;
    if ColorBarIdPrev < ord(low(TCOLORS)) then
    begin
      ColorBarIdPrev := ord(high(TCOLORS));
    end;

    { determine which colorbar will get the focus depending on the state of   }
    { the shift key.                                                          }

    ColorBarIdFocused := ColorBarIdNext;
    if (GetKeyState(VK_SHIFT) shr 1) <> 0 then
    begin
      ColorBarIdFocused := ColorBarIdPrev;
    end;

    SetFocus(ColorBars[TCOLORS(ColorBarIdFocused)]);
  end;

  if Msg = WM_SETFOCUS then
  begin
    { keep track of which scrollbar has the focus                             }

    ColorBarIdFocused := GetWindowLongPtr(Wnd, GWL_ID) - SCROLLBAR_ID_BASE;
  end;

  { let the previous class window handler have a look at the message too      }

  result := CallWindowProc(TWNDPROC(ColorBarWndProcPrev),
                           Wnd,
                           Msg,
                           wParam,
                           lParam);
end;

{-----------------------------------------------------------------------------}

const
  WINDOW_MIN_WIDTH     = 400;
  WINDOW_MIN_HEIGHT    = 340;


function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  WINDOW_MAX_WIDTH     = 1000;
  WINDOW_MAX_HEIGHT    = 1000;

  WINDOW_X_MAXIMIZED   =   20;      { coordinates of the "maximized" window   }
  WINDOW_Y_MAXIMIZED   =   20;

  SCROLL_PAGE          =   15;      { a page up or down changes the color by  }
                                    { this amount.                            }

  MARGIN_X             =   40;


const
  COLOR_BAR_WIDTH      = 20;
  COLOR_BAR_SEPARATION = 20;

  COLOR_BAR_MARGIN_Y   = 30;

const
  COLOR_RANGE_LO  =   0;
  COLOR_RANGE_HI  = $FF;

  PrimaryColors   : array[TCOLORS] of TCOLORREF
                  = (0, 0, 0);

  ColorLabels     : array[TCOLORS] of pchar
                  = ('red', 'green', 'blue');

  ColorValues     : array[TCOLORS] of TCOLORREF
                  = (0, 0, 0);

  ColorBrushes    : array[TCOLORS] of HBRUSH
                  = (0, 0, 0);

  ColorCurrent    : HBRUSH = 0;

const
  SampleText      = 'Sample TEXT';

  { set during WM_SIZE                                                        }

  SampleTextRect  : TRECT = (Left:0; Top:0; Right:0; Bottom:0);

var
  ps              : TPAINTSTRUCT;

  ClientRect      : TRECT;
  LeftRect        : TRECT;
  RightRect       : TRECT;
  ScrollRect      : TRECT;

  SampleTextRgn   : HRGN;


  Buffer          : packed array[0..255] of char;

  TextSize        : TSIZE;

  i               : TCOLORS;

  ColorBarId      : ptruint;

  MinMaxInfo      : PMinMaxInfo absolute lParam;

  ScrollInfo      : TSCROLLINFO;

  TextPos         : TPOINT;

  CoordinateX     : integer;    { used for the scroll bars                    }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      GetClientRect(Wnd, ClientRect);

      PrimaryColors[red]   := RGB(255,   0,   0);
      PrimaryColors[green] := RGB(  0, 255,   0);
      PrimaryColors[blue]  := RGB(  0,   0, 255);

      { create the scrollbars                                                 }

      for i := low(ColorBars) to high(ColorBars) do
      begin
        { NOTE: various parts of the program depend on the fact that the      }
        {       scroll bar ids are consecutive.                               }

        ColorBars[i] := CreateWindow('scrollbar',
                                     '',                         { caption    }
                                     WS_CHILD   or
                                     WS_VISIBLE or
                                     WS_TABSTOP or
                                     SBS_VERT,
                                     0,
                                     0,
                                     0,
                                     0,
                                     Wnd,                        { parent     }
                                     SCROLLBAR_ID_BASE + ord(i), { consecutive}
                                     GetModuleHandle(nil),
                                     nil);

        if ColorBars[i] = 0 then
        begin
          MessageBox(Wnd,
                     'failed to create a scrollbar child window'              +
                     #10#13                                                   +
                     #10#13                                                   +
                     'program will terminate',
                     'Colors - WM_CREATE',
                     MB_ICONERROR or MB_APPLMODAL or MB_OK);

          WndProc := -1;                                     { abort          }
          exit;
        end;

        ZeroMemory(@ScrollInfo, sizeof(ScrollInfo));
        with ScrollInfo do
        begin
          cbSize := sizeof(ScrollInfo);

          fMask  := SIF_RANGE or SIF_POS;

          nMin   := COLOR_RANGE_LO;
          nMax   := COLOR_RANGE_HI;

          nPos   := 0;
        end;
        SetScrollInfo(ColorBars[i], SB_CTL, ScrollInfo, FALSE);

        ColorBrushes[i] := CreateSolidBrush(PrimaryColors[i]);

        { since all the scrollbars are of the same window class they all      }
        { originally have the same WindowProc, therefore we only need to keep }
        { one of them since they are all the same.                            }

        ptruint(ColorBarWndProcPrev)
               := SetWindowLongPtr(ColorBars[i],
                                   GWL_WNDPROC,
                                   ptruint(@ColorBarWndProc));
      end;

      SetFocus(ColorBars[TCOLORS(ColorBarIdFocused)]);

      ColorCurrent := CreateSolidBrush(RGB(ColorValues[red],
                                           ColorValues[green],
                                           ColorValues[blue]));
      exit;
    end;

    WM_SIZE:
    begin
      GetClientRect(Wnd, ClientRect);

      CoordinateX := MARGIN_X;
      for i := low(ColorBars) to high(ColorBars) do
      begin
        MoveWindow(ColorBars[i],
                   CoordinateX,
                   COLOR_BAR_MARGIN_Y,
                   COLOR_BAR_WIDTH,
                   ClientRect.Bottom - (4 * COLOR_BAR_MARGIN_Y),
                   TRUE);

        inc(CoordinateX, COLOR_BAR_SEPARATION + COLOR_BAR_WIDTH);
      end;

      InvalidateRect(Wnd, nil, FALSE); { causes a tolerable amount of flicker }

      SetFocus(Wnd);    { prevents a caret from appearing in the scrollbars   }

      exit;
    end;

    WM_SETFOCUS :
    begin
      SetFocus(ColorBars[TCOLORS(ColorBarIdFocused)]);
      exit;
    end;

    WM_GETMINMAXINFO:
    begin
      { restrict the minimum and maximum size of the window                   }

      with MinMaxInfo^ do
      begin
        ptMinTrackSize.x := WINDOW_MIN_WIDTH;    { minimum                    }
        ptMinTrackSize.y := WINDOW_MIN_HEIGHT;

        ptMaxTrackSize.x := WINDOW_MAX_WIDTH;    { maximum                    }
        ptMaxTrackSize.y := WINDOW_MAX_HEIGHT;

        ptMaxPosition.x  := WINDOW_X_MAXIMIZED;  { location when maximized    }
        ptMaxPosition.y  := WINDOW_Y_MAXIMIZED;
      end;

      exit;
    end;

    WM_ERASEBKGND:
    begin
      WndProc := 1;
      exit;
    end;

    WM_CTLCOLORSCROLLBAR:
    begin
      { wParam = handle to the scrollbar's device context                     }
      { lParam = scrollbar window handle                                      }

      { get the child id                                                      }

      ColorBarId := GetWindowLongPtr(lParam, GWL_ID);

      { pass the brush to windows for it to use it to color the scrollbar     }

      WndProc := ColorBrushes[TCOLORS(ColorBarId - SCROLLBAR_ID_BASE)];

      exit;
    end;

    WM_VSCROLL:
    begin
      { determine which child caused the WM_VSCROLL message, lParam has the   }
      { child's window handle.                                                }

      ColorBarId := GetWindowLongPtr(lParam, GWL_ID);

      i          := TCOLORS(ColorBarId - SCROLLBAR_ID_BASE); { id to TCOLOR   }

      { process the key                                                       }

      case LOWORD(wParam) of
        SB_TOP           :
        begin
          ColorValues[i] := 0;
        end;

        SB_BOTTOM        :
        begin
          ColorValues[i] := $FF;
        end;

        SB_PAGEDOWN      :
        begin
          ColorValues[i] := ColorValues[i] + SCROLL_PAGE;
        end;

        SB_PAGEUP        :
        begin
          { avoid wrap-around here because subtracting SCROLL_PAGE from a     }
          { number that is less than SCROLL_PAGE will result in a very large  }
          { number which will be truncated to $FF causing the scroll thumb to }
          { wrap around, which is not what we want.                           }

          if ColorValues[i] < SCROLL_PAGE then
          begin
            ColorValues[i] := 0;      { no wrap around to $FF/255             }
          end
          else
          begin
            ColorValues[i] := ColorValues[i] - SCROLL_PAGE;
          end;
        end;

        SB_LINEDOWN      :
        begin
          ColorValues[i] := ColorValues[i] + 1;
        end;

        SB_LINEUP        :
        begin
          { see comment in SB_PAGEUP - same problem occurs here               }

          if ColorValues[i] < 1 then
          begin
            ColorValues[i] := 0;      { no wrap around to $FF/255             }
          end
          else
          begin
            ColorValues[i] := ColorValues[i] - 1;
          end;
        end;

        SB_THUMBPOSITION,
        SB_THUMBTRACK    :
        begin
          ColorValues[i] := HIWORD(wParam);
        end;
      end;

      { ensure the color value is in the range 0..255                         }

      ColorValues[i] := min(ColorValues[i], $FF);
      ColorValues[i] := max(ColorValues[i], 0);

      { delete the brush we were using until now                              }

      if ColorCurrent <> 0 then DeleteObject(ColorCurrent);

      ColorCurrent := CreateSolidBrush(RGB(ColorValues[red],
                                           ColorValues[green],
                                           ColorValues[blue]));
      { update the scroll bar                                                 }

      SetScrollPos(ColorBars[i], SB_CTL, ColorValues[i], TRUE);

      InvalidateRect(Wnd, nil, TRUE);
      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      { set up the dc                                                         }

      GetClientRect(Wnd, ClientRect);

      {$ifdef SHOW_RECTANGLE_COORDINATES}
         with ClientRect do
         begin
          writeln;
          writeln;
          writeln('ClientRect     : Left : ',    Left  :3,
                                   ' Top : ',    Top   :3,
                                   '  ',
                                   ' Right : ',  Right :3,
                                   ' Bottom : ', Bottom:3);
        end;
      {$endif}

      SelectObject(ps.hdc, GetStockObject(DEVICE_DEFAULT_FONT));
      GetTextExtentPoint32(ps.hdc, 'A', 1, TextSize);
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      SelectObject(ps.hdc, GetStockObject(NULL_PEN));

      { determine the coordinates of the rectangles we'll be using            }

      { first the left rectangle.  start by getting the coordinates of the    }
      { last scroll bar. (the last scroll bar should be for the blue color)   }

      GetClientRect(ColorBars[blue], LeftRect);

      { convert the LeftRect into coordinates relative to the main window's   }
      { client area.                                                          }

      MapWindowPoints(ColorBars[blue], Wnd, LeftRect, 2);

      with LeftRect do
      begin
        Left   := 0;
        Top    := 0;

        Right  := Right             + MARGIN_X;
        Bottom := ClientRect.Bottom + 1;            { because of null pen     }

        {$ifdef SHOW_RECTANGLE_COORDINATES}
          writeln;
          writeln('LeftRect       : Left : ',    Left  :3,
                                   ' Top : ',    Top   :3,
                                   '  ',
                                   ' Right : ',  Right :3,
                                   ' Bottom : ', Bottom:3);
        {$endif}
      end;

      { now the right rectangle                                               }

      CopyRect(RightRect, ClientRect);
      with RightRect do
      begin
        Left   := LeftRect.Right    - 1; { because of the null pen            }
        Top    := 0;

        Right  := Right             + 1; { because of the null pen            }
        Bottom := ClientRect.Bottom + 1;

        {$ifdef SHOW_RECTANGLE_COORDINATES}
          writeln;
          writeln('RightRect      : Left : ',    Left  :3,
                                   ' Top : ',    Top   :3,
                                   '  ',
                                   ' Right : ',  Right :3,
                                   ' Bottom : ', Bottom:3);
        {$endif}
      end;

      { now the sample text rectangle                                         }

      with SampleTextRect do
      begin
        Left   := MARGIN_X;
        Top    := ClientRect.Bottom - 3 * TextSize.cy;
        Right  := RightRect.Left    - MARGIN_X;
        Bottom := Top               + TextSize.cy;

        {$ifdef SHOW_RECTANGLE_COORDINATES}
          writeln;
          writeln('SampleTextRect : Left : ',    Left  :3,
                                   ' Top : ',    Top   :3,
                                   '  ',
                                   ' Right : ',  Right :3,
                                   ' Bottom : ', Bottom:3);
        {$endif}
      end;

      SampleTextRgn := RGN_NULL;

      {$ifdef NO_SAMPLE_TEXT_FLICKER}
        { turn the SampleTextRect into a region that will be excluded from    }
        { the area that is erased.  This minimizes flicker when repainting    }
        { the sample text.                                                    }

        SampleTextRgn := CreateRectRgnIndirect(SampleTextRect);
        if SampleTextRgn <> RGN_NULL then
        begin
          ExtSelectClipRgn(ps.hdc, SampleTextRgn, RGN_DIFF);
        end;
      {$endif}

      { erase the background of the client area's left side                   }

      with LeftRect do
      begin
        SelectObject(ps.hdc, GetClassLongPtr(Wnd, GCL_HBRBACKGROUND));
        Rectangle(ps.hdc, Left, Top, Right, Bottom);
      end;

      { now erase the right side of the client area using the current color   }
      { brush                                                                 }

      with RightRect do
      begin
        SelectObject(ps.hdc, ColorCurrent);
        Rectangle(ps.hdc, Left, Top, Right, Bottom);
      end;

      {-----------------------------------------------------------------------}
      { write the numeric value of the scrollbars, use the position of the    }
      { first scrollbar to determine where the text goes                      }

      GetClientRect(ColorBars[red],   ScrollRect);
      MapWindowPoints(ColorBars[red], Wnd, ScrollRect, 2);

      with ScrollRect do
      begin
        TextPos.x := Left   + (Right - Left) div 2;
        TextPos.y := Bottom + 2 * TextSize.cy;
      end;

      for i := low(ColorLabels) to high(ColorLabels) do
      begin
        StrFmt(Buffer, '%d', [ColorValues[i]]);

        SetTextColor(ps.hdc, PrimaryColors[i]);

        TextOut(ps.hdc,
                TextPos.x + ord(i) * (COLOR_BAR_SEPARATION + COLOR_BAR_WIDTH),
                TextPos.y,
                Buffer,
                lstrlen(Buffer));
      end;

      {-----------------------------------------------------------------------}
      { write the sample text using the current color (the current alignmet   }
      { is presumed to _still_ be (TA_CENTER or TA_BOTTOM)                    }

      { place the SampleTextRegion back into the dc's clipping region         }

      if SampleTextRgn <> RGN_NULL then
      begin
        SelectClipRgn(ps.hdc, SampleTextRgn);
      end;

      SetTextColor(ps.hdc, RGB(ColorValues[red],
                               ColorValues[green],
                               ColorValues[blue]));

      {$ifdef SHOW_TEXT_FRAME}
        with SampleTextRect do
        begin
          SelectObject(ps.hdc, NULL_PEN);
          SelectObject(ps.hdc, GetSysColorBrush(COLOR_WINDOW));

          FrameRect(ps.hdc, SampleTextRect, ColorCurrent);
          Rectangle(ps.hdc, Left + 1, Top + 1, Right, Bottom);
        end;
      {$endif}

      SetTextAlign(ps.hdc, TA_CENTER or TA_TOP);

      {$ifdef SHOW_SAMPLE_TEXT}
        ExtTextOut(ps.hdc,
                   (SampleTextRect.Right + SampleTextRect.Left) div 2,
                   SampleTextRect.Top,
                   ETO_CLIPPED or ETO_OPAQUE,
                   @SampleTextRect,
                   SampleText,
                   lstrlen(SampleText),
                   nil);
      {$endif}

      if SampleTextRgn <> RGN_NULL then
      begin
        DeleteObject(SampleTextRgn);
      end;


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
         if ColorCurrent <> 0 then DeleteObject(ColorCurrent);

         for i := low(TCOLORS) to high(TCOLORS) do
         begin
           if ColorBrushes[i] <> 0 then DeleteObject(ColorBrushes[i]);
         end;

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
                        ws_OverlappedWindow or  { window style                }
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        20,                     { x pos on screen             }
                        20,                     { y pos on screen             }
                        WINDOW_MIN_WIDTH,       { window width                }
                        WINDOW_MIN_HEIGHT,      { window height               }
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