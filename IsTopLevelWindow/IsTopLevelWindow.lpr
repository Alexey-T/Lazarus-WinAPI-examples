{$APPTYPE        GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - IsTopLevelWindow example'}

{$R IsTopLevelWindow.Res}

program _IsTopLevelWindow;
  { Win32 API function - IsTopLevelWindow example (undocumented)              }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'IsTopLevelWindow Example - UNDOCUMENTED';

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

function IsTopLevelWindow(Wnd : HWND)
         : BOOL; stdcall; external 'user32';

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
  { the window dc.                                                            }

  with WindowRect do OffsetRect(WindowRect, - Left, - Top);

  {---------------------------------------------------------------------------}
  { we need a dc that doesn't clip the output to the client area and that can }
  { be used to update a locked window (the window to be framed is locked)     }

  dc :=  GetDCEx(Wnd,
                 0,                      { no region                          }
                 DCX_WINDOW       or
                 DCX_CACHE        or
                 DCX_EXCLUDERGN   or     { excludes nothing because region = 0}
                 DCX_CLIPSIBLINGS or
                 DCX_LOCKWINDOWUPDATE);  { allow output to locked windows     }

  { select the pen and the brush used by the Rectangle API                    }

  OldPen := SelectObject(dc, Pen);
  SelectObject(dc, GetStockObject(NULL_BRUSH));  { only the frame gets drawn  }

  { select a raster op that causes the original pixels to be restored when the}
  { rectangle is drawn the second time.                                       }

  SetROP2(dc, R2_NOTXORPEN);

  {---------------------------------------------------------------------------}
  { draw a frame around (inside) the window rectangle                         }

  with WindowRect do Rectangle(dc, Left, Top, Right, Bottom);

  SelectObject(dc, OldPen);          { restore the original pen               }
  ReleaseDC(Wnd, dc);

  DeleteObject(Pen);                 { get rid of the pen                     }
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  IsTopLevelWindow_Call = 'IsTopLevelWindow (Wnd : HWND) : BOOL;';

  FramedWindow         : HWND = 0;

  Tracking             : BOOL = FALSE;

  Hint = 'Press the left mouse button - here - then move the mouse around';

  LINE_CNT             = 2;  { number of lines to be output                   }

  {---------------------------------------------------------------------------}
  { put the labels into an array - we'll calculate the length of the labels   }
  { - given a specific font - when processing the WM_CREATE message           }

  LabelsArray          : packed array[1..LINE_CNT] of pchar =
    (
     'Window Handle : ',
     'IsTopLevelWindow : '
    );

  YES                  = 'Yes';
  NO                   = 'No' ;
  EMPTY                = '';

  LabelsLenMax         : integer = 0;      { largest label in above array     }

  {---------------------------------------------------------------------------}
  { reserve space for the data and turn it into an array.  This array should  }
  { be the same size as the LabelsArray.                                      }

  DataBuf      : packed array[1..LINE_CNT] of packed array[0..127] of char
    = (#0, #0);

  {$ifdef VER90}
    DataArray  : packed array[1..LINE_CNT] of pchar
      = (DataBuf[1], DataBuf[2]);
  {$endif}

  {$ifdef FPC}
    { the address of operator should not be necessary and, it is arguably     }
    { incorrect but FPC requires it.                                          }

    DataArray  : packed array[1..LINE_CNT] of pchar
      = (@DataBuf[1], @DataBuf[2]);

  {$endif}


  DataLenMax : integer = 0;                { largest datum in above array     }

  {---------------------------------------------------------------------------}
  { the heigth of the font used to output the above arrays.                   }

  FontHeight           : integer = 0;

var
  ps                 : TPAINTSTRUCT;

  ClientRect         : TRECT;

  Buf                : packed array[0..1023] of char;

  TextSize           : TSIZE;

  MouseOnWindow      : HWND;
  TopWindow          : HWND;
  MousePt            : TPOINT;

  dc                 : HDC;
  I                  : integer;
  TotalLenMax        : integer;

  p                  : pchar;   { pointer to either yes, no, empty            }

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { we precalculate the length of the labels here so we don't have to     }
      { repeat this calculation every time a WM_PAINT is received.            }

      dc := GetDC(Wnd);

      { we need to select the same font that will be used in the WM_PAINT     }
      { otherwise the measurements won't be valid.                            }

      SelectObject(dc, GetStockObject(DEFAULT_GUI_FONT));

      for I := low(LabelsArray) to high(LabelsArray) do
      begin
        GetTextExtentPoint32(dc,
                             LabelsArray[I],
                             lstrlen(LabelsArray[I]),
                             TextSize);

        if TextSize.cx > LabelsLenMax then LabelsLenMax := TextSize.cx;
      end;

      FontHeight := TextSize.cy;       { save the font height                 }

      ReleaseDC(Wnd, dc);

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
      { Failing to do this can cause the frame to be drawn only on the part   }
      { of the window that is uncovered thus causing additional calls to      }
      { DrawWindowFrame to leave a frame around the portion that was initially}
      { obscured.                                                             }

      SetWindowPos(Wnd,
                   HWND_TOPMOST,
                   0, 0, 0, 0,
                   SWP_NOMOVE or SWP_NOSIZE or SWP_DRAWFRAME);
      UpdateWindow(Wnd);

      { we should be on top - (_almost_ always true, when it isn't, it doesn't}
      { matter, the drawing will be correct anyway.)                          }

      DrawWindowFrame(Wnd);
      FramedWindow := Wnd;

      Tracking := TRUE;                   { we are tracking the mouse         }

      InvalidateRect(Wnd, nil, TRUE);
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

      { Windows captures the mouse when dragging a window (and in other       }
      { occasions too.)                                                       }

      if Tracking then
      begin
        ReleaseCapture;                   { let the cat play with it          }

        DrawWindowFrame(FramedWindow);    { erase the frame                   }

        FramedWindow := INVALID_HANDLE_VALUE;
        Tracking     := FALSE;

        LockWindowUpdate(0);              { unlock                            }

        SetWindowPos(Wnd,
                     HWND_NOTOPMOST,
                     0, 0, 0, 0,
                     SWP_NOMOVE or SWP_NOSIZE or SWP_DRAWFRAME);

        InvalidateRect(Wnd, nil, TRUE);   { redraw the client area            }
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

      GetCursorPos(MousePt);

      { get the handle of the window under the cursor                         }

      MouseOnWindow := WindowFromPoint(MousePt);

      if MouseOnWindow = FramedWindow then exit;  { previously framed         }

      { The mouse is on a new window. Erase the previous frame                }

      DrawWindowFrame(FramedWindow);
      LockWindowUpdate(0);             { unlock it                            }
      UpdateWindow(FramedWindow);      { let any pending updates thru         }

      {-----------------------------------------------------------------------}
      { check that the window handle obtained is valid.  Just in case this    }
      { is one of these windows that "come and go" (timed popups and such)    }

      { NOTE: Windows 9x only: strictly speaking we should acquire the        }
      {       Win16Mutex to make sure that the window isn't going to disappear}
      {       before we attempt to frame it.                                  }

      if not IsWindow(MouseOnWindow) then
      begin
        FramedWindow := INVALID_HANDLE_VALUE;
        exit;
      end;

      { Windows 9x only :                                                     }
      { draw the frame around the window. Because we did not acquire the      }
      { Win16Mutex there is a _very_ slim chance that the window handle       }
      { may no longer be valid.  We'll live with that possibility for this    }
      { example.                                                              }

      { tell the window to update itself before we lock it.  This prevents    }
      { framing half painted windows. Unfortunately this produces flicker     }
      { when the mouse is on windows that paint themselves periodically       }
      { such as the System Monitor.  The flicker can be eliminated by         }
      { always locking the Top Level window instead of the child window.      }

      TopWindow := MouseOnWindow;
      while GetParent(TopWindow) <> 0 do TopWindow := GetParent(TopWindow);

      UpdateWindow(MouseOnWindow);

      if MouseOnWindow <> Wnd then LockWindowUpdate(TopWindow);    { lock it  }
      DrawWindowFrame(MouseOnWindow);                              { frame it }

      { Win9x only: release the Win16Mutex here if we had obtained it.        }
      {-----------------------------------------------------------------------}

      { keep track of the currently framed window.                            }

      FramedWindow := MouseOnWindow;

      { update our display to reflect the window size of the new window       }

      InvalidateRect(Wnd, nil, TRUE);

      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);

      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      if Tracking then
      begin
        {---------------------------------------------------------------------}
        { show the window handle the mouse is currently on                    }

        DataBuf[1] := #0;        { initialize                                 }
        DataBuf[2] := #0;
        p          := EMPTY;

        if FramedWindow <> INVALID_HANDLE_VALUE then
        begin
          StrFmt(DataArray[1], '$%8.8X', [FramedWindow]);

          p := NO;
          if IsTopLevelWindow(FramedWindow) then p := YES;

          StrFmt(DataArray[2], '%s', [p]);
        end;

        { calculate the largest size of the data strings                      }

        DataLenMax := 0;
        for I := low(DataArray) to high(DataArray) do
        begin
          GetTextExtentPoint32(ps.hdc,
                               DataArray[I],
                               lstrlen(DataArray[I]),
                               TextSize);

          if TextSize.cx > DataLenMax then DataLenMax := TextSize.cx;
        end;

        { calculate the length of the largest label plus the largest string   }

        TotalLenMax := LabelsLenMax + DataLenMax;

        { with TotalLenMax we can output the strings nicely centered and      }
        { justified at the same time.                                         }

        for I := low(LabelsArray) to high(LabelsArray) do
        begin
          SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);
          TextOut(ps.hdc,
                  (ClientRect.Right - TotalLenMax) div 2 + LabelsLenMax,
                  (ClientRect.Bottom div 2) + (I - 2) * FontHeight,
                  LabelsArray[I],
                  lstrlen(LabelsArray[I]));

          SetTextAlign(ps.hdc, TA_LEFT or TA_BOTTOM);
          TextOut(ps.hdc,
                  (ClientRect.Right - TotalLenMax) div 2 + LabelsLenMax,
                  (ClientRect.Bottom div 2) + (I - 2) * FontHeight,
                  DataArray[I],
                  lstrlen(DataArray[I]));

        end;
      end
      else
      begin
        {---------------------------------------------------------------------}
        { give the user a hint about what to do next                          }

        lstrcpy(Buf, Hint);

        SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
        TextOut(ps.hdc,
                ClientRect.Right  div 2,
                ClientRect.Bottom div 2,
                Buf,
                lstrlen(Buf));
      end;


      {-----------------------------------------------------------------------}
      { draw the function call                                                }

      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      lstrcpy(Buf, IsTopLevelWindow_Call);

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
  else InitAppClass   := TRUE;
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
                        600,                    { window width                }
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

  WinMain := Msg.wParam;                        { terminate with return code  }
end;

begin
  WinMain;
end.