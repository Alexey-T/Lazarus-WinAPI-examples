{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - CreateCompatibleBitmap'}

//{$define USE_EXTTEXTOUT_IN_FLICKER_WINDOW}

{$R CreateCompatibleBitmap.res}

program _CreateCompatibleBitmap;
  { Win32 API function - CreateCompatibleBitmap example                       }

uses
  Windows,
  Messages,
  Resource,
  Sysutils
  ;

const
  AppNameBase    = 'CreateCompatibleBitmap';

  {$ifdef WIN64}
    Bitness64    = ' - 64bit';
    AppName      = AppNameBase + Bitness64;
  {$else}
    Bitness32    = ' - 32bit';
    AppName      = AppNameBase + Bitness32;
  {$endif}

  AboutBox       = 'AboutBox';
  APPICON        = 'APPICON';
  APPMENU        = 'APPMENU';

{-----------------------------------------------------------------------------}

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;
{$endif}

{-----------------------------------------------------------------------------}

{$ifdef VER90}
  { for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms   }
  { of GetWindowLong and SetWindowLong respectively.                          }

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
{$endif}

{-----------------------------------------------------------------------------}

const
  FlickerClass     = 'Flicker_Class';
  FlickerFreeClass = 'Flicker_Free_Class';

var
  TheFont        : HFONT = 0;

  WndFlicker     : HWND;
  WndFlickerFree : HWND;

  Count          : DWORD;
  CountStr       : packed array[0..31] of char;

{-----------------------------------------------------------------------------}

function FlickerWndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { window procedure for flicker window                                       }
var
  ps         : TPAINTSTRUCT;
  ClientRect : TRECT;

  TextSize   : TSIZE;

  x, y       : integer;

begin
  FlickerWndProc := 0;

  case Msg of
    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect (Wnd, ClientRect);
      SetBkMode (ps.hdc, TRANSPARENT);

      SelectObject(ps.hdc, TheFont);

      GetTextExtentPoint32(ps.hdc,
                           CountStr,
                           lstrlen(CountStr),
                           TextSize);

      SetTextColor(ps.hdc, GetSysColor(COLOR_WINDOWTEXT));
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

      x := ClientRect.Right div 2;
      y := ClientRect.Bottom - ((ClientRect.Bottom - TextSize.cy) div 2);

      {$ifndef USE_EXTTEXTOUT_IN_FLICKER_WINDOW}
        TextOut(ps.hdc,
                x,
                y,
                CountStr,
                lstrlen(CountStr));
      {$endif}

      {$ifdef USE_EXTTEXTOUT_IN_FLICKER_WINDOW}
        { NOTE: setting the ExtTextOut Options parameter (4th parameter) to   }
        {       ETO_OPAQUE requires the background color to be explicitly set }
        {       with SetBkMode(ps.hdc, GetSysColor(COLOR_WINDOW))             }

        { uncomment SetBkMode below if OPAQUE is specified in ExtTextOut      }

        // SetBkMode(ps.hdc, GetSysColor(COLOR_WINDOW))

        ExtTextOut(ps.hdc,
                   x,
                   y,
                   0,         { if set to OPAQUE then see above NOTE          }
                  @ClientRect,
                   CountStr,
                   lstrlen(CountStr),
                   nil);
      {$endif}

      EndPaint(Wnd, ps);

      exit;
    end;
  end;

  FlickerWndProc := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function InitFlickerClass: WordBool;
  { registers the flicker window class                                        }
var
  cls : TWndClass;

begin
  if not GetClassInfo(hInstance, FlickerClass, cls) then
  begin
    with cls do
    begin
      style           := CS_BYTEALIGNCLIENT or CS_HREDRAW or CS_VREDRAW;
      lpfnWndProc     := @FlickerWndProc;
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := System.hInstance;
      hIcon           := 0;
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := nil;
      lpszClassName   := FlickerClass;
    end; { with }

    InitFlickerClass  := WordBool(RegisterClass(cls));
  end
  else InitFlickerClass := TRUE;
end;

{-----------------------------------------------------------------------------}

procedure FlickerFreePaint (Wnd : HWND; var ps : TPAINTSTRUCT);
var
  ClientRect  : TRECT;
  MemDC       : HDC;
  Bitmap      : HBITMAP;                { we'll draw on this bitmap           }
  TextSize    : TSIZE;

begin
  GetClientRect (Wnd, ClientRect);      { get the size of the client area     }

  MemDC := CreateCompatibleDC(ps.hdc);  { create a compatible dc              }

  { create a bitmap the size of the client area                               }

  with ClientRect do
  begin
    BitMap := CreateCompatibleBitmap(ps.hdc, Right - Left, Bottom - Top);
  end;

  { replace the default bitmap in the compatible dc with ours                 }

  SelectObject(MemDC, Bitmap);

  { paint our bitmap the same color as the window background                  }

  FillRect(MemDC, ClientRect, GetClassLongPtr(Wnd, GCL_HBRBACKGROUND));

  { select the our font into our dc                                           }

  SelectObject (MemDc, TheFont);

  GetTextExtentPoint32(MemDC,
                       CountStr,
                       lstrlen(CountStr),
                       TextSize);

  { draw what we'd normally draw on the screen, on the bitmap                 }

  SetBkMode   (MemDC, TRANSPARENT);
  SetTextColor(MemDC, GetSysColor(COLOR_WINDOWTEXT));
  SetTextAlign(MemDC, TA_CENTER or TA_BOTTOM);

  TextOut(MemDC,
          ClientRect.Right div 2,
          ClientRect.Bottom - (ClientRect.Bottom - TextSize.cy) div 2,
          CountStr,
          lstrlen(CountStr));

  { copy the bitmap onto the window                                           }

  with ClientRect do
  begin
    BitBlt(ps.hdc, Left, Top, Right - Left, Bottom - Top, MemDC, 0, 0, SRCCOPY);
  end;

  DeleteDC     (MemDC);
  DeleteObject (BitMap);
end;

{-----------------------------------------------------------------------------}

function FlickerFreeWndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { window procedure for flicker free window                                  }
var
  ps  : TPAINTSTRUCT;

begin
  FlickerFreeWndProc := 0;

  case msg of
    WM_ERASEBKGND:
    begin
      { tell windows that we did erase the background even though we didn't   }

      FlickerFreeWndProc := 1;   { this is the key to preventing flicker      }
      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

        FlickerFreePaint(Wnd, ps);

      EndPaint(Wnd, ps);

      exit;
    end;
  end; { case }

  FlickerFreeWndProc := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function InitFlickerFreeClass: WordBool;
  { registers the no flicker window class                                     }
var
  cls : TWndClass;

begin
  if not GetClassInfo(hInstance, FlickerFreeClass, cls) then
  begin
    with cls do
    begin
      style           := CS_BYTEALIGNCLIENT or CS_VREDRAW or CS_HREDRAW;
      lpfnWndProc     := @FlickerFreeWndProc;
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := System.hInstance;
      hIcon           := 0;
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := nil;
      lpszClassName   := FlickerFreeClass;
    end; { with }

    InitFlickerFreeClass    := WordBool(RegisterClass (cls));
  end
  else InitFlickerFreeClass := TRUE;
end;

{-----------------------------------------------------------------------------}
{ ABOUT box                                                                   }

function About(DlgWnd : HWND; Msg : UINT; wParam, lParam : ptrint)
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
{ MAIN window functions and procedures                                        }

const
  WINDOW_MIN_WIDTH      = 320;       { main window minimum width              }
  WINDOW_MIN_HEIGHT     = 320;       {                     height             }


function MainWndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main window procedure - parent to the flicker/flickerfree child windows   }
const
  ID_FLICKER            = 10;
  ID_FLICKER_FREE       = 20;

  TIMER_ID              = 10;
  Timer       : ptruint = 0;

var
  ClientRect  : TRECT;


  MinMaxInfo  : PMinMaxInfo absolute lParam;


begin
  MainWndProc := 0;

  case msg of
    WM_CREATE:
    begin
      ZeroMemory(@CountStr, sizeof(CountStr));

      WndFlicker := CreateWindowEx(WS_EX_CLIENTEDGE,
                                   FlickerClass,
                                   nil,                      { no caption     }
                                   WS_CHILD        or
                                   WS_VISIBLE      or
                                   WS_CLIPSIBLINGS or
                                   WS_CLIPCHILDREN,
                                   0,
                                   0,
                                   0,
                                   0,
                                   Wnd,
                                   ID_FLICKER,
                                   hInstance,
                                   nil);

      if WndFlicker = 0 then
      begin
        MainWndProc := -1;
        exit
      end;

      WndFlickerFree := CreateWindowEx(WS_EX_CLIENTEDGE,
                                       FlickerFreeClass,
                                       nil,                  { no caption     }
                                       WS_CHILD        or
                                       WS_VISIBLE      or
                                       WS_CLIPSIBLINGS or
                                       WS_CLIPCHILDREN,
                                       0,
                                       0,
                                       0,
                                       0,
                                       Wnd,
                                       ID_FLICKER_FREE,
                                       hInstance,
                                       nil);

       if WndFlickerFree = 0 then
       begin
         MainWndProc := -1;
         exit
       end;

      { get a timer                                                           }

      Timer := SetTimer(Wnd, TIMER_ID, 50, nil);
      if Timer = 0 then
      begin
        MessageBox(Wnd,
                   'Couldn''t get a TIMER',
                   'SetTimer problem',
                   MB_OK);

        MainWndProc := -1;                           { abort window creation  }
        exit;
      end;

      exit;
    end;

    WM_SIZE:
    begin
      { the hiword and loword only contain 16 bit values.  GetClientRect      }
      { returns the full 32bit values.                                        }

      GetClientRect(Wnd, ClientRect);

      { resize the children and create a new appropriately sized font         }

      if TheFont <> 0 then DeleteObject(TheFont);

      TheFont := CreateFont (ClientRect.Bottom div 2,
                             0,
                             0,
                             0,
                             700,
                             0,
                             0,
                             0,
                             ANSI_CHARSET,
                             OUT_DEFAULT_PRECIS,
                             CLIP_DEFAULT_PRECIS,
                             PROOF_QUALITY,
                             DEFAULT_PITCH or FF_ROMAN,
                             nil);

      MoveWindow(WndFlicker,
                 0,
                 0,
                 ClientRect.Right,
                 ClientRect.Bottom div 2,
                 TRUE);

      MoveWindow(WndFlickerFree,
                 0,
                 ClientRect.Bottom div 2 + 1,
                 ClientRect.Right,
                 ClientRect.Bottom div 2 - 1,
                 TRUE);
      exit;
    end;

    WM_GETMINMAXINFO:
    begin
      { restrict the minimum and maximum size of the window                   }

      with MinMaxInfo^ do
      begin
        { control only the minimum width and height.  let Windows determine   }
        { the maximum and full screen values.                                 }

        ptMinTrackSize.x := WINDOW_MIN_WIDTH;    { minimum width              }
        ptMinTrackSize.y := WINDOW_MIN_HEIGHT;   {         height             }
      end;

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

      exit;
    end;

    WM_TIMER:
    begin
      Count := (Count + 1) mod 1000;         { increment the counter          }

      StrFmt(CountStr, '%d', [Count]);

      InvalidateRect (WndFlicker,     nil, TRUE);
      UpdateWindow(WndFlicker);

      InvalidateRect (WndFlickerFree, nil, TRUE);
      UpdateWindow(WndFlickerFree);

      exit;
    end;

    WM_DESTROY:
    begin
      if TheFont <> 0 then DeleteObject(TheFont);
      if Timer   <> 0 then KillTimer(Wnd, Timer);

      PostQuitMessage(0);
      exit;
    end;
  end; { case }

  MainWndProc := DefWindowProc(Wnd, msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function InitAppClass: WordBool;
  { registers the application's window classes                                }
var
  cls : TWndClassEx;

begin
  cls.cbSize            := sizeof(TWndClassEx);         { must be initialized }

  if not GetClassInfoEx(hInstance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @MainWndProc;
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := System.hInstance;              { qualify instance!   }
      hIcon           := LoadIcon(hInstance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := APPMENU;
      lpszClassName   := AppName;
      hIconSm         := LoadImage(hInstance,
                                   APPICON,
                                   IMAGE_ICON,
                                   16,
                                   16,
                                   LR_DEFAULTCOLOR);
    end; { with }

    InitAppClass  := WordBool(RegisterClassEx(cls));
  end
  else InitAppClass := true;
end;

{-----------------------------------------------------------------------------}

function WinMain : integer;
var
  Msg   : TMSG;
  Wnd   : HWND;

begin
  WinMain := 0;        { unnecessary but makes the compiler happy             }

  if not (InitAppClass and InitFlickerClass and InitFlickerFreeClass) then
  begin
    halt (255);        { a message box with an error message would be better  }
  end;

  { create the main window                                                    }

  Wnd := CreateWindowEx(WS_EX_WINDOWEDGE,
                        AppName,
                        AppName,
                        WS_OVERLAPPEDWINDOW or
                        WS_VISIBLE          or
                        WS_CLIPCHILDREN     or
                        WS_CLIPSIBLINGS,
                        20,
                        20,
                        WINDOW_MIN_WIDTH,
                        WINDOW_MIN_HEIGHT,
                        0,
                        0,
                        hInstance,
                        nil);

  if Wnd = 0 then exit;     { should present a message box with an error!     }

  while GetMessage (Msg, 0, 0, 0) do
  begin
    TranslateMessage(Msg);
    DispatchMessage(Msg);
  end;

  WinMain := Msg.wParam;
end;

begin
  WinMain;
end.