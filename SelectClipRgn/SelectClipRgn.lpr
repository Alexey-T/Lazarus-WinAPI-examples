{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - SelectClipRgn example'}

{$R SelectClipRgn.RES}

program _SelectClipRgn;
  { Win32 API function - SelectClipRgn example                               }

  { NOTE:  This example uses a NULL_BRUSH as the background brush.  Any app  }
  {        that does this must ensure that it always redraws the entire      }
  {        client area when processing either the WM_ERASEBKGND or WM_PAINT  }
  {        messages.  In this example we do everything in the WM_PAINT.      }
  {--------------------------------------------------------------------------}

uses Windows, Messages, Resource;

const
  AppNameBase  = 'SelectClipRgn (dc : HDC; Region : HRGN) : integer;';

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
{ procedure that draws the "background" gradient                              }

procedure GradientHorizontal(Wnd                  : hWnd;
                             WndDC                : hdc;
                             Rect                 : TRECT;
                             StartColor, EndColor : TCOLORREF);
  { draws a horizontal gradient from StartColor to EndColor                   }
const
  BAND_CNT    = 255;

type
  TCOLOR      = (clRed, clGreen, clBlue, clFlags);

var
  StartColorB : packed array[TColor] of byte absolute StartColor;
  EndColorB   : packed array[TColor] of byte absolute EndColor;

  ColorDiff   : packed array[TColor] of integer;

  ColorBand   : TCOLORREF;
  ColorBandB  : packed array[TColor] of byte absolute ColorBand;

  i           : integer;
  T           : TCOLOR;

  RectHeight  : integer;           { Rectangle's height                       }
  RectTop     : integer;           { Rectangle's Top coordinate               }

  dc          : hdc;
  Brush       : HBRUSH;

begin
  { if a dc wasn't given then get one otherwise use the supplied one          }

  if WndDC = 0 then dc := GetDC(Wnd) else dc := WndDC;

  { in this example, the rectangle where the text resides is of constant      }
  { width and height while the window is being painted.  This is also true of }
  { the window's entire client area (which is used when the client area       }
  { gradient is painted.)                                                     }

  RectHeight := Rect.Bottom - Rect.Top;
  RectTop    := Rect.Top;

  { calculate the color variation from StartColor to EndColor for each of the }
  { color components (R, G, B)                                                }

  for T := low(TColor) to high(TColor) do
  begin
    ColorDiff[T] := EndColorB[T] - StartColorB[T];
  end;

  ZeroMemory(@ColorBand, sizeof(ColorBand));

  { draw the gradient                                                         }

  for  i := 0 to BAND_CNT do
  begin
    { calculate the Top and Bottom coordinates of the rectangle to be filled  }

    Rect.Top    := RectTop + ( i      * RectHeight) div BAND_CNT;
    Rect.Bottom := RectTop + ((i + 1) * RectHeight) div BAND_CNT;

    { calculate the color to be used to fill the above rectangle              }

    for T := low(TColor) to high(TColor) do
      begin
        ColorBandB[T] := StartColorB[T] + (i * ColorDiff[T]) div BAND_CNT;
      end;

    { create the brush to fill the rectangle with                             }

    Brush := CreateSolidBrush(ColorBand);

    FillRect(dc, Rect, Brush);
    DeleteObject(Brush);
  end;
end;

{-----------------------------------------------------------------------------}

const
  { constants to control the minimum window width and height                  }

  WINDOW_MIN_WIDTH       = 620;
  WINDOW_MIN_HEIGHT      = 200;

{-----------------------------------------------------------------------------}
{ Main (and only) window procedure                                            }

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  Font           : HFONT = 0;
  TextA                  = 'Colorful characters';
  Flicker        : BOOL  = FALSE;                   { no flicker              }

  RegionClip     : HRGN  = 0;

  OFFSET_X               = 36;
  OFFSET_Y               = 36;         { font size div 2                      }


var
  ps             : TPAINTSTRUCT;
  dc             : HDC;

  RegionBox      : TRECT;

  ClientRect     : TRECT;

  MinMaxInfo     : PMinMaxInfo absolute lParam;     { redefines lParam        }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { since the text that is displayed does NOT change at any time we can   }
      { pre-calculate the region it occupies and offset that region as        }
      { necessary when the window is resized.                                 }

      { Create a font that we use to create a Clip path                       }

      Font := CreateFont(72,
                          0,
                          0,
                          0,
                          FW_BOLD,
                          0,
                          0,
                          0,
                          ANSI_CHARSET,
                          OUT_DEFAULT_PRECIS,
                          CLIP_DEFAULT_PRECIS,
                          PROOF_QUALITY,
                          DEFAULT_PITCH or FF_DONTCARE,
                          'Times New Roman');         { standard Windows font }
      if Font = 0 then
      begin
        MessageBox(Wnd,
                   'Font creation failed',
                   'Main Window',
                   MB_ICONERROR or MB_OK);

        WndProc := -1;
        exit;
      end;

      {-----------------------------------------------------------------------}
      { Create the clipping region                                            }

      dc := GetDC(Wnd);

      SelectObject(dc, Font);
      SetTextAlign(dc, TA_LEFT or TA_TOP);
      SetBkMode(dc, TRANSPARENT);

      { create the clipping region from the TextA string                      }

      BeginPath(dc);
        TextOut(dc,
                0,
                0,
                TextA,
                lstrlen(TextA));
      EndPath(dc);

      { convert the path into a region                                        }

      RegionClip := PathToRegion(dc);

      ReleaseDC(Wnd, dc);

      { we no longer need the font because WM_PAINT will use the region, not  }
      { the font to output the text.                                          }

      DeleteObject(Font);

      { now that we've released all the resources, check that we have a       }
      { valid region (used for both, clipping and to paint into.)             }

      if RegionClip = 0 then
      begin
        MessageBox(Wnd,
                   'Couldn''t create clipping region',
                   'Main Window',
                   MB_ICONERROR or MB_OK);

        WndProc := -1;
        exit;
      end;

      { initialize the flicker mode and its corresponding menu item           }

      PostMessage(Wnd, WM_COMMAND, IDM_EXCLUDE, 0);   { no flicker            }

      exit;
    end;

    WM_GETMINMAXINFO:
    begin
      { restrict the minimum and maximum size of the window                   }

      with MinMaxInfo^ do
      begin
        ptMinTrackSize.x := WINDOW_MIN_WIDTH;    { minimum                    }
        ptMinTrackSize.y := WINDOW_MIN_HEIGHT;
      end;

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);
      GetClientRect(Wnd, ClientRect);

      {-----------------------------------------------------------------------}
      { draw the gradient, excluding the RegionClip which we'll draw          }
      { separately.  We exclude the RegionClip to eliminate flicker, if it    }
      { were not excluded the gradient would draw over that area which        }
      { will later be drawn again when the text string region is colored.     }
      { This would produce noticeable flicker.                                }

      GetRgnBox(RegionClip, RegionBox);
      OffsetRgn(RegionClip, - RegionBox.Left, - RegionBox.Top);  { 0, 0       }
      with ClientRect do
      begin
        OffsetRgn(RegionClip,
                  OFFSET_X,
                  (Bottom - OFFSET_Y) div 2);
      end;

      if not Flicker then ExtSelectClipRgn(ps.hdc, RegionClip, RGN_DIFF);

      { draw the "background" gradient                                        }

      GradientHorizontal(Wnd,
                         ps.hdc,
                         ClientRect,
                         RGB(120, 120, 180), RGB(220, 220, 220));

      {-----------------------------------------------------------------------}
      { finally we draw the text excluding any area of the screen that is     }
      { not inside the characters.                                            }

      SelectClipRgn(ps.hdc, RegionClip);
      GetRgnBox(RegionClip, RegionBox);
      GradientHorizontal(Wnd,
                         ps.hdc,
                         RegionBox,
                         RGB(255, 0, 0), RGB(100, 127, 255));

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_EXCLUDE:
        begin
          Flicker := FALSE;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_EXCLUDE,
                             IDM_INCLUDE,
                             IDM_EXCLUDE,
                             MF_BYCOMMAND);
          exit;
        end;

        IDM_INCLUDE:
        begin
          Flicker := TRUE;
          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_EXCLUDE,
                             IDM_INCLUDE,
                             IDM_INCLUDE,
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
      if RegionClip <> 0 then DeleteObject(RegionClip);

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

      style           := CS_BYTEALIGNCLIENT or CS_HREDRAW or CS_VREDRAW;
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;            { qualify instance!     }
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetStockObject(NULL_BRUSH);  { no background erase!  }
      lpszMenuName    := APPMENU;                     { Menu name             }
      lpszClassName   := AppName;                     { Window Class name     }
      hIconSm         := LoadImage(hInstance,
                                   APPICON,
                                   IMAGE_ICON,
                                   16,
                                   16,
                                   LR_DEFAULTCOLOR);
    end; { with }

    InitAppClass := WordBool(RegisterClassEx (cls));
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

  Wnd:= CreateWindowEx(WS_EX_CLIENTEDGE,
                       AppName,                 { class name                  }
                       AppName,                 { window caption text         }
                       ws_OverlappedWindow or   { window style                }
                       ws_ClipSiblings     or
                       ws_ClipChildren     or   { don't affect children       }
                       ws_Visible,              { make showwindow unnecessary }
                       50,                      { x pos on screen             }
                       50,                      { y pos on screen             }
                       WINDOW_MIN_WIDTH,        { window width                }
                       WINDOW_MIN_HEIGHT,       { window height               }
                       0,                       { parent window handle        }
                       0,                       { menu handle 0 = use class   }
                       hInstance,               { instance handle             }
                       nil);                    { parameter sent to WM_CREATE }

  if Wnd = 0 then halt;                         { could not create the window }

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