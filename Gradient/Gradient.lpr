{$ifdef FPC}
  {$MODESWITCH OUT}
{$endif}

{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API Example - Background Gradient'}

{$R Gradient.Res}

program _Gradient;
  { Win32 API example - Shows how to create a smooth background gradient      }

  { NOTES: Applications that use background gradients should generally not    }
  {        allow their windows with such a background to be resized.  This is }
  {        because the gradient is generally proportional to the window size  }
  {        causing the gradient (and whatevery is on the client area) to be   }
  {        redrawn every time the size changes. This causes a lot of flicker. }
  {                                                                           }
  {        If you really have to allow the window to be resized then you will }
  {        have to include the CS_HREDRAW and CS_VREDRAW styles to the class  }
  {        (assuming that your gradient is proportional to the window size.)  }
  {        Also, to avoid flicker you should draw the gradient when processing}
  {        the WM_ERASEBKGND message as this example does, otherwise the      }
  {        flicker is _very_ noticeable and unappealing.  In spite of this,   }
  {        if you don't take other precautions, whatever else is drawn on the }
  {        gradient will flicker.                                             }
  {                                                                           }
  {        note the presence of CS_HREDRAW and CS_VREDRAW in the window class }
  {---------------------------------------------------------------------------}

uses
  Windows,
  Messages,
  Resource
  ;

const
  AppNameBase  = 'Background Gradient';

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

const
  kernel32     = 'kernel32';
  user32       = 'user32';
  gdi32        = 'gdi32';

{-----------------------------------------------------------------------------}

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;
{$endif}

{$ifdef FPC}
  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(Wnd : HWND; out Rect : TRECT)
           : BOOL;    stdcall; external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL;    stdcall; external user32 name 'GetMessageA';

  { "override" some FPC definitions with better parameter names               }

  function DeleteObject(GdiObject : HGDIOBJ)
           : BOOL;    stdcall; external gdi32;

  function CreateSolidBrush(Color : COLORREF)
           : HBRUSH;  stdcall; external gdi32;

  function GetDC(Wnd : HWND)
           : HDC;     stdcall; external user32;

  function ReleaseDC(Wnd : HWND; dc : HDC)
           : longint; stdcall; external user32;

  function MulDiv(Multiplicand : longint;
                  Multiplier   : longint;
                  Divisor      : longint)
           : longint; stdcall; external kernel32;

  { original definition of FillRect passes Rect as a "const" which conflicts  }
  { with the documentation stating that "const" cannot be assumed to pass a   }
  { parameter a certain way (reference in this case.)                         }

  { there are a fair number of API definitions that assumes "const" is the    }
  { same (has the same effect) as "constref".                                 }

  function FillRect(dc : HDC;
         constref Rect : TRECT;
                 Brush : HBRUSH)
           : longint; stdcall; external user32;
{$endif}

{-----------------------------------------------------------------------------}

{ define an empty inline procedure, which FPC will remove, to remove a        }
{ potentially large number of hints about unused parameters.  Since the       }
{ procedure is "inline" and empty, a call to it will _not_ generate any code  }
{ and the presence of UNUSED_PARAMETER(someparameter) is much more self       }
{ documenting and general than using a Lazarus IDE specific directive.        }

{ overloading UNUSED_PARAMETER allows consolidating all unused hints in just  }
{ a few messages which should appear together if all such procedures are      }
{ declared together as well.                                                  }

{$ifdef FPC}
  procedure UNUSED_PARAMETER(UNUSED_PARAMETER : ptrint); inline; begin end;
{$endif}

{-----------------------------------------------------------------------------}

function About(DlgWnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
begin
  {$ifdef FPC}
    UNUSED_PARAMETER(lParam);           { "declare" lParam as unused          }
  {$endif}

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

procedure GradientHorizontal(Wnd                  : HWND;
                             WndDC                : HDC;
                             StartColor, EndColor : TCOLORREF);
  { draws a horizontal gradient from StartColor to EndColor                   }
const
  BAND_CNT    = 510;   { increase to make the gradient smoother               }

type
  TCOLOR      = (clRed, clGreen, clBlue, clFlags);

var
  StartColorB : packed array[TColor] of byte absolute StartColor;
  EndColorB   : packed array[TColor] of byte absolute EndColor;

  ColorDiff   : packed array[TColor] of integer;

  ColorBand   : TCOLORREF;
  ColorBandB  : packed array[TColor] of byte absolute ColorBand;

  i           : integer;
  t           : TCOLOR;

  Rect        : TRECT;
  ClientRect  : TRECT;             { client area coordinates                  }
  ClientHeight: integer;           { client area height                       }

  dc          : HDC;
  Brush       : HBRUSH;

begin
  { if a dc wasn't given then get one otherwise use the supplied one.         }
  { NOTE: in this program the WndDC parameter should never be zero.           }

  if WndDC = 0 then dc := GetDC(Wnd) else dc := WndDC;

  GetClientRect(Wnd, ClientRect);       { to calculate rectangle to be filled }

  { initialize the Fill rectangle values that remain constant                 }

  Rect.Left    := ClientRect.Left;
  Rect.Right   := ClientRect.Right  - ClientRect.Left;

  ClientHeight := ClientRect.Bottom - ClientRect.Top;

  { calculate the color variation from StartColor to EndColor for each of the }
  { color components (R, G, B)                                                }

  for t := low(TColor) to high(TColor) do
  begin
    ColorDiff[t] := EndColorB[t] - StartColorB[t];
  end;

  ZeroMemory(@ColorBand, sizeof(ColorBand));

  { draw the gradient                                                         }

  for  i := 0 to BAND_CNT do
  begin
    { calculate the Top and Bottom coordinates of the rectangle to be filled  }

    Rect.Top    := MulDiv(i,     ClientHeight, BAND_CNT);
    Rect.Bottom := MulDiv(i + 1, ClientHeight, BAND_CNT);

    { calculate the color to be used to fill the above rectangle              }

    for t := low(TColor) to high(TColor) do
    begin
      ColorBandB[t] := StartColorB[t] + MulDiv(i, ColorDiff[t], BAND_CNT);
    end;

    { create the brush to fill the rectangle with                             }

    Brush := CreateSolidBrush(ColorBand);

    FillRect(dc, Rect, Brush);
    DeleteObject(Brush);
  end;

  if WndDC = 0 then ReleaseDC(Wnd, dc);
end;

{-----------------------------------------------------------------------------}

procedure GradientVertical(Wnd                  : hWnd;
                           WndDC                : HDC;
                           StartColor, EndColor : TCOLORREF);
  { This procedure is pretty much the same thing as GradientHorizontal, when- }
  { ever the horizontal gradient dealt with the height, Left or Right this    }
  { procedure deals with the Width, Top and Bottom instead.                   }

  { it would easy to combine the two procedure and add a parameter to indicate}
  { which type of gradient horizontal or vertical should be generated.        }
const
  BAND_CNT    = 64;    { increase to make the gradient smoother               }

type
  TCOLOR      = (clRed, clGreen, clBlue, clFlags);

var
  StartColorB : packed array[TColor] of byte absolute StartColor;
  EndColorB   : packed array[TColor] of byte absolute EndColor;

  ColorDiff   : packed array[TColor] of integer;

  ColorBand   : TCOLORREF;
  ColorBandB  : packed array[TColor] of byte absolute ColorBand;

  i           : integer;
  t           : TCOLOR;

  Rect        : TRECT;
  ClientRect  : TRECT;             { client area coordinates                  }
  ClientWidth : integer;           { client area width                        }

  dc          : HDC;
  Brush       : HBRUSH;

begin
  { if a dc wasn't given then get one otherwise use the supplied one.         }
  { NOTE: in this program the WndDC parameter should never be zero.           }

  if WndDC = 0 then dc := GetDC(Wnd) else dc := WndDC;

  GetClientRect(Wnd, ClientRect);       { to calculate rectangle to be filled }

  { initialize the Fill rectangle values that remain constant                 }

  Rect.Top    := ClientRect.Top;
  Rect.Bottom := ClientRect.Bottom  - ClientRect.Top;

  ClientWidth := ClientRect.Right - ClientRect.Left;

  { calculate the color variation from StartColor to EndColor for each of the }
  { color components (R, G, B)                                                }

  for t := low(TColor) to high(TColor) do
  begin
    ColorDiff[t] := EndColorB[t] - StartColorB[t];
  end;

  ZeroMemory(@ColorBand, sizeof(ColorBand));

  { draw the gradient                                                         }

  for  i := 0 to BAND_CNT do
  begin
    { calculate the left and right coordinates of the rectangle to be filled  }

    Rect.Left   := MulDiv(i,     ClientWidth, BAND_CNT);
    Rect.Right  := MulDiv(i + 1, ClientWidth, BAND_CNT);

    { calculate the color to be used to fill the above rectangle              }

    for t := low(TColor) to high(TColor) do
    begin
      ColorBandB[t] := StartColorB[t] + MulDiv(i, ColorDiff[t], BAND_CNT);
    end;

    { create the brush to fill the rectangle with                             }

    Brush := CreateSolidBrush(ColorBand);

    FillRect(dc, Rect, Brush);
    DeleteObject(Brush);
  end;

  if WndDC = 0 then ReleaseDC(Wnd, dc);
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
Type
  GradientProc = procedure (Wnd                  : HWND;
                            WndDC                : HDC;
                            StartColor, EndColor : TCOLORREF);
const
  ColorStart : DWORD        = 0;
  ColorEnd   : DWORD        = 0;

  { FPC requires the @ (addressof operator) while Delphi does not             }

  Gradient   : GradientProc = {$IFDEF FPC} @ {$ENDIF} GradientHorizontal;

var
  dc         : HDC absolute wParam;   { wParam in WM_ERASEBKGND               }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { start with the gray horizontal gradient                               }

      PostMessage(Wnd, WM_COMMAND, IDM_GRAY,       0);
      PostMessage(Wnd, WM_COMMAND, IDM_HORIZONTAL, 0);

      exit;
    end;

    WM_ERASEBKGND:
    begin
      { note the absence of WM_PAINT in this WndProc                          }

      Gradient(Wnd, dc { wParam }, ColorStart, ColorEnd);

      WndProc := 1;         { let's Windows know we "erased" the background   }
      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_GRAY:
        begin
          ColorStart := RGB(80, 80, 80);
          ColorEnd   := RGB(240, 240, 240);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_GRAY,
                             IDM_BLUE,
                             IDM_GRAY,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_BLUE:
        begin
          ColorEnd   := RGB(40, 40, 100);
          ColorStart := RGB(200, 200, 255);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_GRAY,
                             IDM_BLUE,
                             IDM_BLUE,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);
          exit;
        end;

        IDM_VERTICAL:
        begin
          Gradient := @GradientVertical;
          InvalidateRect(Wnd, nil, TRUE);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_VERTICAL,
                             IDM_HORIZONTAL,
                             IDM_VERTICAL,
                             MF_BYCOMMAND);

          exit;
        end;

        IDM_HORIZONTAL:
        begin
          Gradient := @GradientHorizontal;
          InvalidateRect(Wnd, nil, TRUE);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_VERTICAL,
                             IDM_HORIZONTAL,
                             IDM_HORIZONTAL,
                             MF_BYCOMMAND);
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
  cls.cbSize          := sizeof(TWndClassEx);           { must be initialized }

  if not GetClassInfoEx (hInstance, AppName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT or CS_HREDRAW or CS_VREDRAW;
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