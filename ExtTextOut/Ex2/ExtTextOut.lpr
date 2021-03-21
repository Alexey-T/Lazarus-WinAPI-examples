//{$define DEBUG}

{$ifdef DEBUG}
  {$APPTYPE        CONSOLE}
{$else}
  {$APPTYPE        GUI}
{$endif}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - ExtTextOut example'}


{$R ExtTextOut.Res}

program _ExtTextOut;
  { Win32 API function - ExtTextOut example                                   }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'ExtTextOut Example';

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

procedure DrawWindowFrame(Wnd : HWND);
  { Draws a frame around the parameter Wnd                                    }
var
  dc         : HDC;
  WindowRect : TRECT;

  Pen        : HPEN;
  OldPen     : HPEN;
begin
  { a 5 pixel wide pen is a reasonable choice. Some windows are "tucked" under}
  { other child windows and a thin frame won't be visible because it falls    }
  { in the "tucked" area.                                                     }

  Pen := CreatePen(PS_INSIDEFRAME, 5, RGB(255, 0, 255));

  GetWindowRect(Wnd, WindowRect);              { the window rectangle         }

  {---------------------------------------------------------------------------}
  { convert the coordinates in WindowRect to be relative to the upper left    }
  { corner of the window.  At this time they are relative to the upper left   }
  { corner of the screen.  After the conversion the (Left, Top) coordinate in }
  { WindowRect will be (0, 0) which matches the preset (Left, Top) coordinate }
  { of the window dc.                                                         }

  with WindowRect do OffsetRect(WindowRect, - Left, - Top);

  {---------------------------------------------------------------------------}
  { we need a dc that doesn't clip the output to the client area and that can }
  { be used to update a locked window (the window to be framed is locked).    }

  dc :=  GetDCEx(Wnd,
                 0,                      { no region                          }
                 DCX_WINDOW       or
                 DCX_CACHE        or
                 DCX_EXCLUDERGN   or     { excludes nothing because region = 0}
                 DCX_CLIPSIBLINGS or
                 DCX_LOCKWINDOWUPDATE);

  { select the pen and the brush used by the Rectangle API                    }

  OldPen := SelectObject(dc, Pen);
  SelectObject(dc, GetStockObject(NULL_BRUSH));  { only the frame gets drawn  }

  { select a raster op that causes the original pixels to be restored when    }
  { the rectangle is drawn the second time.                                   }

  SetROP2(dc, R2_NOTXORPEN);

  {---------------------------------------------------------------------------}
  { draw a frame around (inside) the window rectangle                         }

  with WindowRect do
  begin
    Rectangle(dc, Left, Top, Right, Bottom);
  end;

  SelectObject(dc, OldPen);          { restore the original pen               }
  ReleaseDC(Wnd, dc);

  DeleteObject(Pen);                 { get rid of the pen                     }
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  ExtTextOut_Call
  = 'ExtTextOut (dc : HDC; x, y : integer; Options : UINT; Rect : PRECT; ' +
    'Characters : pchar; CharCount : UINT; DistancesX : PIntegerArray) '   +
    ': BOOL;';

  FramedWindow         : HWND = 0;

  Tracking             : BOOL = FALSE;

  Hint = 'Press the left mouse button - here - then move the mouse around';

  {---------------------------------------------------------------------------}
  { allocate an array for the lines that we'll be outputting                  }

  LINE_CNT           = 4;

  LineArray          : packed array[1..LINE_CNT] of
                       packed record
                         TextLabel : pchar;
                         DataBuf   : pchar;   { allocated during WM_CREATE    }
                         Pt        : TPOINT;
                         Window    : HWND;
                       end =
    ((TextLabel: 'Cursor Position relative to:';
      DataBuf  : nil;                                   { unused              }
      Pt:(x:0; y:0);                                    { unused              }
      Window:0),                                        { unused              }
     (TextLabel: 'Desktop window:';
      DataBuf  : nil;
      Pt:(x:0; y:0);
      Window:0),
     (TextLabel: 'This window:';
      DataBuf  : nil;
      Pt:(x:0; y:0);
      Window:0),
     (TextLabel: 'Highlighted window:';
      DataBuf  : nil;
      Pt:(x:0; y:0);
      Window:0));

  CENTER             = 30; { to make the entire block of text appear centered }
                           { NOTE: this value should be calculated, instead   }
                           {       of "estimated".                            }

  FontHeight         : integer = 0;

  { area from the bottom of the client area to NOT invalidate                 }

  Exclude            : integer = 0;

  { the point that will be mapped relative to various windows                 }

  MousePt            : TPOINT = (x: 0; y: 0);

  { the coordinates of the rectangle that contains the data                   }

  CoordinateRect     : TRECT = (Left: 0; Top: 0; Right: 0; Bottom:0);

  { flag that indicates if we frame the invalidated rectangle selected or not }

  PenRed             : HPEN  = 0;       { pen used to outline UpdateRect      }

  FONT_ALL                   = DEFAULT_GUI_FONT;

  { Borland forgot this definition in the Delphi 2.0 files                    }

  HEAP_ZERO_MEMORY = DWORD($00000008);

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;

  MouseOnWindow      : HWND;
  TopWindow          : HWND;

  dc                 : HDC;
  i                  : integer;

  ClipRect           : TRECT;           { the clipping rectangle for each     }
                                        { line output by ExtTextOut.          }

  OutputCoordinateY  : ptrint;          { the Y coordinate where lines are    }
                                        { output when tracking                }

  MenuItemState      : DWORD;           { MSDN says UINT, same as DWORD       }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { we calculate the size of the rectangle where we'll be drawing the     }
      { values.  This is the rectangle that we'll invalidate when a           }
      { a repaint is needed due to a new window being hilited.  We do this    }
      { to avoid the noticeable flicker that results from invalidating the    }
      { entire client area.                                                   }

      SetRectEmpty(CoordinateRect);
      GetClientRect(Wnd, ClientRect);

      dc := GetDC(Wnd);

      { we need to select the same font that will be used in the WM_PAINT     }
      { otherwise the measurements won't be valid.                            }

      SelectObject(dc, GetStockObject(FONT_ALL));
      GetTextExtentPoint32(dc,
                           ' (00000, 00000) ',  { widest coordinate           }
                           14,                  { length of above string      }
                           TextSize);
      ReleaseDC(Wnd, dc);

      FontHeight := TextSize.cy;
      Exclude    := 2 * FontHeight;

      with CoordinateRect do
      begin
        Left  := 0;
        Top   := FontHeight;                    { exclude the first line      }
        Right := TextSize.cx;
        Bottom:= LINE_CNT * TextSize.cy;
      end;

      OffsetRect(CoordinateRect,
                 ClientRect.Right  div 2  + CENTER,
                (ClientRect.Bottom div 2) - (LINE_CNT * FontHeight));

      { we don't allocate memory for the first element because the first      }
      { element is only a title, there is no window value associated with it. }
      { This means LineArray[low(LineArray)] equals nil.  WM_PAINT depends on }
      { this to display the values correctly.                                 }

      for i := low(LineArray) + 1 to high(LineArray) do
      begin
        LineArray[i].DataBuf := HeapAlloc(GetProcessHeap,
                                          HEAP_ZERO_MEMORY,
                                          64);       { more than enough       }
      end;


      { initialize the Desktop window handle and this window's handle in      }
      { the Line array.                                                       }

      LineArray[2].Window := GetDesktopWindow();
      LineArray[3].Window := Wnd;

      { the last one, LineArray[4], will be set during the WM_PAINT message   }

      { create a pen with which we'll use to frame the output rectangle       }

      PenRed   := CreatePen(PS_DOT, 0, RGB(255,  0, 0));  { outer rectangle   }

      exit;
    end;


    WM_LBUTTONDOWN:
    begin
      {-----------------------------------------------------------------------}
      { capture the mouse to make sure we always get the button up which      }
      { is the signal to refresh the client area.                             }

      SetCapture(Wnd);

      {-----------------------------------------------------------------------}
      { if the window is partially covered by another window (like a menu)    }
      { we want to make sure the window is fully uncovered before we draw     }
      { the frame.  We do this using SetWindowPos and UpdateWindow.           }

      SetWindowPos(Wnd,
                   HWND_TOPMOST,
                   0, 0, 0, 0,
                   SWP_NOMOVE or SWP_NOSIZE or SWP_DRAWFRAME);
      UpdateWindow(Wnd);

      { we should be on top - (_almost_ always true, when it isn't it doesn't }
      { matter, the drawing will be correct anyway.)                          }

      DrawWindowFrame(Wnd);
      FramedWindow := Wnd;

      Tracking := TRUE;                   { we are tracking the mouse         }

      {-----------------------------------------------------------------------}
      { NOTE: same exact MenuItemState handling appears in WM_LBUTTONUP       }
      {       therefore it should be a nested function.                       }

      { exclude the bottom part of the window that contains the prototype of  }
      { ExtTextOut if the menu item to prevent it from flickering is selected }

      MenuItemState := GetMenuState(GetMenu(Wnd), IDM_EXCLUDE, MF_BYCOMMAND);

      case MenuItemState <> 0 of
        true  :
        begin
          { menu item is checked, exclude the bottom of the client area       }

          GetClientRect(Wnd, ClientRect);

          ClientRect.Bottom := ClientRect.Bottom - Exclude;
          InvalidateRect(Wnd, @ClientRect, TRUE);
        end;

        false :
        begin
          { menu item is unchecked, invalidate the entire client area         }

          InvalidateRect(Wnd, nil, TRUE);
        end;
      end;

      {-----------------------------------------------------------------------}

      { send ourselves a WM_MOUSEMOVE so the mouse position is updated        }

      SendMessage(Wnd,
                  WM_MOUSEMOVE,
                  0,                      { we don't use the x value          }
                  0);                     { nor the y value                   }
      exit;
    end;


    WM_LBUTTONUP:
    begin
      {-----------------------------------------------------------------------}
      { Note that using "if GetCapture = Wnd" to find out if we are           }
      { tracking the mouse can be a source of problems.  In some instances    }
      { Windows (thru DefWindowProc) will capture the mouse for us, so        }
      { having the mouse captured does not necessarily mean that we should    }
      { draw or erase a frame.                                                }

      if Tracking then
      begin
        ReleaseCapture();               { let the cat play with it            }

        DrawWindowFrame(FramedWindow);  { erase the frame                     }
        FramedWindow := INVALID_HANDLE_VALUE;

        Tracking     := FALSE;

        LockWindowUpdate(0);
        SetWindowPos(Wnd,
                     HWND_NOTOPMOST,
                     0, 0, 0, 0,
                     SWP_NOMOVE or SWP_NOSIZE or SWP_DRAWFRAME);

      {-----------------------------------------------------------------------}
      { NOTE: same exact MenuItemState handling appears in WM_LBUTTONDOWN     }
      {       therefore it should be a nested function.                       }

      { exclude the bottom part of the window that contains the prototype of  }
      { ExtTextOut if the menu item to prevent it from flickering is selected }

      MenuItemState := GetMenuState(GetMenu(Wnd), IDM_EXCLUDE, MF_BYCOMMAND);

      case MenuItemState <> 0 of
        true  :
        begin
          { menu item is checked, exclude the bottom of the client area       }

          GetClientRect(Wnd, ClientRect);

          ClientRect.Bottom := ClientRect.Bottom - Exclude;
          InvalidateRect(Wnd, @ClientRect, TRUE);
        end;

        false :
        begin
          { menu item is unchecked, invalidate the entire client area         }

          InvalidateRect(Wnd, nil, TRUE);
        end;
      end;

      {-----------------------------------------------------------------------}

      end; { if Tracking }

      exit;
    end; { WM_LBUTTONUP }


    WM_MOUSEMOVE:
    begin
      { if we are not tracking the mouse then there's nothing to do           }

      if not Tracking then exit;

      { we don't use the coordinates stored in the lParam because they are    }
      { in client coordinates and may not reflect the current position of     }
      { the mouse if the user moved it after this message was received.       }

      { in addition to that, the WM_LBUTTONDOWN sends a WM_MOUSEMOVE message  }
      { with coordinates 0, 0 regardless of the actual mouse location.        }

      GetCursorPos(MousePt);

      { get the handle of the window under the cursor                         }

      MouseOnWindow := WindowFromPoint(MousePt);
      InvalidateRect(Wnd, @CoordinateRect, FALSE);  { NO background erase!    }

      if MouseOnWindow = FramedWindow then exit;    { previously framed       }

      { The mouse is on a new window. Erase the previous frame                }

      DrawWindowFrame(FramedWindow);
      LockWindowUpdate(0);             { unlock it                            }
      UpdateWindow(FramedWindow);      { let any pending updates thru         }

      {-----------------------------------------------------------------------}
      { check that the window handle obtained is valid.  Just in case this    }
      { is one of these windows that "come and go" (timed popups and such)    }

      if not IsWindow(MouseOnWindow) then
      begin
        FramedWindow := INVALID_HANDLE_VALUE;
        exit;
      end;

      { draw the frame around the window.                                     }

      { tell the window to update itself before we lock it.  This prevents    }
      { framing half painted windows. Unfortunately this produces flicker     }
      { when the mouse is on windows that paint themselves periodically       }
      { such as the System Monitor.  The flicker can be eliminated by         }
      { always locking the Top Level window instead of the child window.      }

      TopWindow := MouseOnWindow;
      while GetParent(TopWindow) <> 0 do TopWindow := GetParent(TopWindow);

      UpdateWindow(MouseOnWindow);

      if MouseOnWindow <> Wnd then LockWindowUpdate(TopWindow);   { lock it   }
      DrawWindowFrame(MouseOnWindow);                             { frame it  }

      {-----------------------------------------------------------------------}

      { keep track of the currently framed window.                            }

      FramedWindow := MouseOnWindow;

      exit;
    end;


    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);

      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(NULL_BRUSH));
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      { draw the rectangle that ENCLOSES the rectangle ExtTextOut will be     }
      { writing in.                                                           }

      SelectObject(ps.hdc, PenRed);

      { since we want a frame that encloses the entire rectangle, we subtract }
      { 1 from Left, Top and add 1 to Right, Bottom.  This is important       }
      { because the call to ExtTextOut that uses the CoordinateRect uses      }
      { ETO_OPAQUE.  if the rectangle drawn isn't _around_ the rectangle used }
      { by ExtTextOut, the ETO_OPAQUE will cause the edges of the rectangle   }
      { to be erased by ExtTextOut.                                           }

      with CoordinateRect
        do Rectangle(ps.hdc, Left - 1, Top - 1, Right + 1, Bottom + 1);

      SelectObject(ps.hdc, GetStockObject(BLACK_PEN)); { get the red pen out  }

      if Tracking then
      begin
        {---------------------------------------------------------------------}
        { show the window point translated to the window currently framed     }

        { the screen relative mouse position is always the same as the        }
        { desktop relative mouse position, this is because the origin of      }
        { the desktop and the screen always match.  We do the mapping         }
        { here just for the sake of the example, the point will be            }
        { returned unchanged.                                                 }

        LineArray[4].Window := FramedWindow;

        CopyRect(ClipRect, CoordinateRect);

        for i := low(LineArray) + 1 to high(LineArray) do
        with LineArray[i] do
        begin
          CopyMemory(@Pt, @MousePt, sizeof(Pt));
          MapWindowPoints(0,          { from window / 0 = screen = desktop    }
                          Window,
                          Pt,
                          1);
          StrFmt(DataBuf, ' (%d, %d)', [Pt.x, Pt.y]);
        end;

        for i := low(LineArray) to high(LineArray) do
        with LineArray[i] do
        begin
          { output the labels                                                 }

          SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);

          { calculate the Y coordinate of the line                            }

          OutputCoordinateY := CoordinateRect.Top                 +
                               ((i - low(LineArray)) * FontHeight);

          TextOut(ps.hdc,
                  CoordinateRect.Left,
                  OutputCoordinateY,
                  TextLabel,
                  lstrlen(TextLabel));

          { output the values.  if there is no value to display then skip the }
          { line.                                                             }

          if LineArray[i].DataBuf = nil then continue;

          SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);

          { calculate the clipping rectangle for the value of i               }

          with ClipRect do
          begin
            Bottom := OutputCoordinateY;
            Top    := Bottom - FontHeight;
          end;

          { to make the absence of flicker completely obvious use a different }
          { color for the text background.                                    }

          SetBkColor(ps.hdc, RGB(220, 220, 220));     { a light grey color    }
          ExtTextOut(ps.hdc,
                     CoordinateRect.Left,
                     OutputCoordinateY,
                     ETO_CLIPPED or ETO_OPAQUE,
                     @ClipRect,
                     DataBuf,
                     lstrlen(DataBuf),
                     nil);                      { not interested in distances }
        end;
      end
      else
      begin
        {---------------------------------------------------------------------}
        { give the user a hint about what to do next                          }

        lstrcpy(Buf, Hint);
        SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);

        TextOut(ps.hdc,
                ClientRect.Right   div 2,
                ClientRect.Bottom  div 2,
                Buf,
                lstrlen(Buf));
      end;

      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      lstrcpy(Buf, ExtTextOut_Call);

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
        IDM_EXCLUDE                 :
        begin
          { toggle the menu                                                   }

          MenuItemState := GetMenuState(GetMenu(Wnd),
                                        IDM_EXCLUDE,
                                        MF_BYCOMMAND);

          case MenuItemState <> 0 of
            true  :  { menu item is checked   } MenuItemState := MF_UNCHECKED;
            false :  { menu item is unchecked } MenuItemState := MF_CHECKED;
          end;

          CheckMenuItem(GetMenu(Wnd),
                        IDM_EXCLUDE,
                        MF_BYCOMMAND or MenuItemState);
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
      if PenRed <> 0 then DeleteObject(PenRed);

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
      { cbSize has already been initialized as required                       }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;            { qualify instance!     }
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
                        ws_Overlapped       or  { window style                }
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        50,                     { x pos on screen             }
                        50,                     { y pos on screen             }
                        740,                    { window width                }
                        300,                    { window height               }
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

  WinMain := Msg.wParam;                        { terminate with return code  }
end;

begin
  WinMain;
end.