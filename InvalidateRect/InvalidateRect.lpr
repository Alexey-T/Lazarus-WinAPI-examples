{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - InvalidateRect example'}


{$R InvalidateRect.Res}

program _InvalidateRect;
  { Win32 API function - InvalidateRect example                               }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'InvalidateRect Example';

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
  InvalidateRect_Call
  = 'InvalidateRect (Wnd : HWND; Rect : PRECT; Erase : BOOL) : BOOL;';

  FramedWindow         : HWND = 0;

  Tracking             : BOOL = FALSE;

  Hint = 'Press the left mouse button - here - then move the mouse around';

  {---------------------------------------------------------------------------}
  { allocate an array for the lines that we'll be outputting                  }

  LINE_CNT           =  4;

  LineArray          : packed array[1..LINE_CNT] of
                       packed record
                         TextLabel : pchar;
                         DataBuf   : pchar;   { allocated during WM_CREATE    }
                         Pt        : TPOINT;
                         Window    : HWND;
                       end =
    ((TextLabel: 'Cursor Position relative to  ';
      DataBuf  : nil;                                   { unused              }
      Pt:(x:0; y:0);                                    { unused              }
      Window:0),                                        { unused              }
     (TextLabel: 'Desktop window :';
      DataBuf  : nil;
      Pt:(x:0; y:0);
      Window:0),
     (TextLabel: 'This window :';
      DataBuf  : nil;
      Pt:(x:0; y:0);
      Window:0),
     (TextLabel: 'Highlighted window :';
      DataBuf  : nil;
      Pt:(x:0; y:0);
      Window:0));

  CENTER             = 30; { to make the entire block of text appear centered }
                           { NOTE: this value should be calculated, instead   }
                           {       of "estimated".                            }

  FontHeight         : integer = 0;

  { the point that will be mapped relative to various windows                 }

  MousePt            : TPOINT = (x: 0; y: 0);

  { the coordinates of the rectangle that contains the data                   }

  CoordinateRect     : TRECT = (Left: 0; Top: 0; Right: 0; Bottom:0);

  { the maximum size - font relative - of the strings in the Line Array       }

  LabelLenMax        : integer = 0;  { longest/widest label                   }
  DataLenMax         : integer = 0;  { longest data                           }

  { the current update rectangle as chosen in the menu                        }

  UpdateRect         : TRECT = (Left: 0; Top: 0; Right: 0; Bottom:0);

  { flag that indicates if we frame the invalidated rectangle selected or not }

  ShowRect           : BOOL  = FALSE;   { initialized later to the opposite   }
  Pen                : HPEN  = 0;       { pen used to outline UpdateRect      }

  FONT_ALL           = DEFAULT_GUI_FONT;

  { Borland forgot this definition in the Delphi 2.0 files                    }

  HEAP_ZERO_MEMORY = DWORD($00000008);

var
  ps                 : TPAINTSTRUCT;
  OldPen             : HPEN;

  ClientRect         : TRECT;

  Buf                : packed array[0..255] of char;

  TextSize           : TSIZE;

  MouseOnWindow      : HWND;
  TopWindow          : HWND;

  dc                 : HDC;
  i                  : integer;

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

      { NOTE: there will still be a slight and noticeable amount of flicker   }
      {       in the rectangle that hosts the coordinate.                     }

      SetRectEmpty(CoordinateRect);
      GetClientRect(Wnd, ClientRect);

      dc := GetDC(Wnd);

      { we need to select the same font that will be used in the WM_PAINT     }
      { otherwise the measurements won't be valid.                            }

      SelectObject(dc, GetStockObject(FONT_ALL));
      GetTextExtentPoint32(dc,
                           ' (0000, 0000) ',  { widest coordinate             }
                           14,                { length of above string        }
                           TextSize);
      ReleaseDC(Wnd, dc);

      FontHeight := TextSize.cy;

      with CoordinateRect do
      begin
        Left  := 0;
        Top   := FontHeight;                    { exclude the first line      }
        Right := TextSize.cx;
        Bottom:= LINE_CNT * TextSize.cy;
      end;

      OffsetRect(CoordinateRect,
                 ClientRect.Right   div 2  + CENTER,
                 (ClientRect.Bottom div 2) - (LINE_CNT * FontHeight));

      { we don't allocate memory for the first element because the first      }
      { element is only a title, there is no window value associated with it. }
      { This means LineArray[low(LineArray)] equals nil.  WM_PAINT depends on }
      { this to display the values correctly.                                 }

      for i := low(LineArray) + 1 to high(LineArray) do
      begin
        LineArray[I].DataBuf := HeapAlloc(GetProcessHeap,
                                          HEAP_ZERO_MEMORY,
                                          64);       { more than enough       }
      end;


      { initialize the Desktop window handle and this window's handle in      }
      { the Line array.                                                       }

      LineArray[2].Window := GetDesktopWindow();
      LineArray[3].Window := Wnd;

      { the last one, LineArray[4], will be set during the WM_PAINT message   }

      { create a pen to frame the invalid rectangle selection.                }

      Pen := CreatePen(PS_DOT, 0, RGB(255, 0, 0));

      { send ourselves a message to update the menu option and the current    }
      { invalid rectangle selection.                                          }

      PostMessage(Wnd, WM_COMMAND, IDM_ENTIRE,   0);
      PostMessage(Wnd, WM_COMMAND, IDM_SHOWRECT, 0);

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

      InvalidateRect(Wnd, nil, TRUE);

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

        InvalidateRect(Wnd, nil, TRUE); { redraw the client area              }
      end;

      exit;
    end;

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
      InvalidateRect(Wnd, @UpdateRect, TRUE);

      if MouseOnWindow = FramedWindow then exit;  { previously framed         }

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
      SelectObject(ps.hdc, GetStockObject(FONT_ALL));
      SelectObject(ps.hdc, GetStockObject(NULL_BRUSH));

      if ShowRect then
      begin
        OldPen := SelectObject(ps.hdc, Pen);
        with UpdateRect do Rectangle(ps.hdc, Left, Top, Right + 1, Bottom + 1);
        SelectObject(ps.hdc, OldPen);
      end;

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

        for I := low(LineArray) + 1 to high(LineArray) do
        with LineArray[I] do
        begin
          CopyMemory(@Pt, @MousePt, sizeof(Pt));
          MapWindowPoints(0,          { from window / 0 = screen = desktop    }
                          Window,
                          Pt,
                          1);
          StrFmt(DataBuf, ' (%d, %d)', [Pt.x, Pt.y]);
        end;

        for I := low(LineArray) to high(LineArray) do
        with LineArray[I] do
        begin
          SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);
          TextOut(ps.hdc,
                  ClientRect.Right div 2 + CENTER,
                  (ClientRect.Bottom div 2) -
                                         ((LINE_CNT - I) * FontHeight),
                  TextLabel,
                  lstrlen(TextLabel));

          SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);
          TextOut(ps.hdc,
                  ClientRect.Right div 2 + CENTER,
                  (ClientRect.Bottom div 2) -
                                         ((LINE_CNT - I) * FontHeight),
                  DataBuf,
                  lstrlen(DataBuf));
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

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      lstrcpy(Buf, InvalidateRect_Call);

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
        IDM_ENTIRE:
        begin
          GetClientRect(Wnd, UpdateRect);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_ENTIRE,
                             IDM_COORDINATE,
                             IDM_ENTIRE,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_COORDINATE:
        begin
          CopyRect(UpdateRect, CoordinateRect);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_ENTIRE,
                             IDM_COORDINATE,
                             IDM_COORDINATE,
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_SHOWRECT:
        begin
          { note that because IDM_SHOWRECT is a toggled option, putting a     }
          { checkmark instead of treating it as a radio item would probably   }
          { be more appropriate.                                              }

          if   ShowRect
          then ShowRect := FALSE
          else ShowRect := BOOL(IDM_SHOWRECT);

          CheckMenuRadioItem(GetMenu(Wnd),
                             IDM_SHOWRECT,
                             IDM_SHOWRECT,
                             integer(ShowRect),
                             MF_BYCOMMAND);

          InvalidateRect(Wnd, nil, TRUE);

          exit;
        end;

        IDM_ABOUT:
        begin
          DialogBox(GetModuleHandle(nil), ABOUTBOX, Wnd, @About);

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
      if Pen <> 0 then DeleteObject(Pen);

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
  cls      : TWndClassEx;

  Instance : THANDLE;

begin
  cls.cbSize          := sizeof(TWndClassEx);    { must be initialized        }

  Instance            := GetModuleHandle(nil);   { same as system.hInstance   }

  if not GetClassInfoEx (Instance, AppName, cls) then
  begin
    with cls do begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := Instance;
      hIcon           := LoadIcon (Instance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := APPMENU;                     { Menu name             }
      lpszClassName   := AppName;                     { Window Class name     }
      hIconSm         := LoadImage(Instance,
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
                        600,                    { window width                }
                        300,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        GetModuleHandle(nil),   { instance handle             }
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