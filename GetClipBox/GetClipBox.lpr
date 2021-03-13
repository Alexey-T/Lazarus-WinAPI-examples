{$APPTYPE GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - GetClipBox example'}

{$R GetClipBox.Res}

program _GetClipBox;
  { Win32 API function - GetClipBox example                                   }

  { On versions of Windows after Windows XP, GetClipBox only works as         }
  { expected when "Disable visual themes" is checked in the "Compatibility"   }
  { tab.  This also causes the window caption to be "unstyled" making it look }
  { like a Win9x window.                                                      }

  { Note that in spite of that, GetClipBox can be used to determine if a      }
  { window is fully covered/obscured by another window.  In that case         }
  { GetClipBox returns NULL_REGION even if "Disable visual styles" is not     }
  { checked.                                                                  }

  { Also, when "Disable visual styles" is not checked, the dimensions of the  }
  { clip box can be used to determine in most cases if the region is complex  }
  { or simple.  If the clip box equals the client rectangle then either the   }
  { window is fully uncovered or the region is complex.  Unfortunately, there }
  { is no simple way to tell which case is which (fully uncovered or partially}
  { covered creating a complex region.                                        }

  { NOTE: if this example is run from a network drive the setting of "Disable }
  {       visual styles" is ignored by the Windows installation running the   }
  {       program.                                                            }

uses
  Windows,
  Messages,
  Resource,
  SysUtils;

const
  AppNameBase    = 'GetClipBox Example';

  {$ifdef WIN64}
    Bitness64  = ' - 64bit';
    AppName    = AppNameBase + Bitness64;
  {$else}
    Bitness32  = ' - 32bit';
    AppName    = AppNameBase + Bitness32;
  {$endif}

  PopupName  = 'Popup Window';
  AboutBox   = 'AboutBox';
  APPICON    = 'APPICON';
  APPMENU    = 'APPMENU';
  POPUPMENU  = 'POPUPMENU';

{-----------------------------------------------------------------------------}

{$ifdef VER90} { Delphi 2.0 }
type
  ptrint  = longint;
  ptruint = dword;

  // for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms of
  // GetWindowLong and SetWindowLong respectively.

  function GetWindowLongPtr(Wnd   : HWND;
                            Index : ptrint)
           : ptruint; stdcall; external 'user32' name 'GetWindowLongA';

  function SetWindowLongPtr(Wnd     : HWND;
                            Index   : ptrint;
                            NewLong : ptruint)
           : ptruint; stdcall; external 'user32' name 'SetWindowLongA';

  function GetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint)
           : ptruint; stdcall; external 'user32' name 'GetClassLongA';

  function SetClassLongPtr(Wnd      : HWND;
                           Index    : ptrint;
                           NewLong  : ptruint)
           : ptruint; stdcall; external 'user32' name 'SetClassLongA';
{$endif}

{$ifdef FPC}
  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(Wnd : HWND; out Rect : TRECT)
           : BOOL; stdcall;    external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL; stdcall;    external user32 name 'GetMessageA';

  function CopyRect(out DestinationRect : TRECT;
               constref SourceRect      : TRECT)
           : BOOL; stdcall;    external user32;

  function SetRectEmpty(out Rect : TRECT)
           : BOOL; stdcall;    external user32;

  function GetTextExtentPoint32(dc      : HDC;
                                str     : pchar;
                                strlen  : integer;
                            out strsize : TSIZE)
           : BOOL; stdcall     external gdi32 name 'GetTextExtentPoint32A';

  function BeginPaint(    Wnd           : HWND;
                      out PaintStruct   : TPaintStruct)
           : HDC; stdcall;     external user32;
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

function About(DlgWnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
begin
  {$ifdef FPC}
    UNUSED_PARAMETER(lParam);           { "declare" lParam as unused          }
  {$endif}

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

function IsWindowFullyCovered(Wnd : HWND) : BOOL;
  { returns TRUE if the window is _fully_ covered by other windows            }

  { NOTE: for an example of how to use this function see the example          }
  {       IsWindowFullyCovered                                                }
var
  dc      : HDC;
  ClipBox : TRECT;

begin
  result  := FALSE;

  SetRectEmpty(ClipBox);

  dc      := GetWindowDC(Wnd);
  result  := GetClipBox(dc, ClipBox) = NULLREGION;

  ReleaseDC(Wnd, dc);
end;

{-----------------------------------------------------------------------------}

function PopupWndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { popup window handler                                                      }
const
  Timer              : DWORD   = 0;            { causes an unwanted hint      }
  TIMER_ID                     = 10;

  TIME_SPAN                    = 200;

  RegionType         : integer = 0;
  OwnerClipBox       : TRECT   = (Left:0; Top:0; Right:0; Bottom:0);
  OwnerRect          : TRECT   = (Left:0; Top:0; Right:0; Bottom:0);

  OwnerWnd           : HWND    = 0;

  { the initial value presumes the corresponding menu item is unchecked,      }
  { meaning, false.                                                           }

  FlickerMinimize    : boolean = false;

  NULL_REGION                  = 'NULL_REGION';
  SIMPLE_REGION                = 'SIMPLE_REGION';
  COMPLEX_REGION               = 'COMPLEX_REGION';
  ERROR_REGION                 = 'ERROR';

  RegionTypeText     : pchar   = NULL_REGION;

var
  ps                 : TPAINTSTRUCT;
  dc                 : HDC;

  ClientRect         : TRECT;
  ClearRect          : TRECT;

  Buf                : packed array[0..255] of char;
  TextSize           : TSIZE;

begin
  PopupWndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      Timer := SetTimer(Wnd, TIMER_ID, TIME_SPAN, nil);

      exit;
    end;

    WM_LBUTTONDOWN,
    WM_RBUTTONDOWN,
    WM_MBUTTONDOWN:
    begin
      { bring the owner window to the top (in case it's obscured              }

      BringWindowToTop(GetWindow(Wnd, GW_OWNER));
      SetForegroundWindow(Wnd);       { make the popup the active window      }

      exit;
    end;

    WM_TIMER:
    begin
      OwnerWnd := GetWindow(Wnd, GW_OWNER);

      dc         := GetWindowDC(OwnerWnd);
      RegionType := GetClipBox(dc, OwnerClipBox);

      ReleaseDC(OwnerWnd, dc);

      { specifying TRUE in InvalidateRect is what causes flicker but is       }
      { necessary to prevent the output from being garbled.  Change to FALSE  }
      { to see the effect.                                                    }

      InvalidateRect(Wnd, nil, TRUE);
      UpdateWindow(Wnd);

      exit;
    end;

    WM_ERASEBKGND:
    begin
      if FlickerMinimize then
      begin
        { we'll redraw the background in the WM_PAINT to minimize flicker     }

        PopupWndProc := 1; { tell windows the background has been erased.     }

        exit;
      end;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      GetClientRect(Wnd, ClientRect);

      SetTextAlign(ps.hdc, TA_BOTTOM or TA_CENTER);
      SetBkMode(ps.hdc, TRANSPARENT);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      { get the background brush which the Rectangle will use to erase the    }
      { background. NOTE: for this to work as expected, the hbrBackground     }
      { field of the class MUST use a real brush and NOT a simple color       }
      { constant such as COLOR_WINDOW                                         }

      SelectObject(ps.hdc, GetClassLongPtr(Wnd, GCL_HBRBACKGROUND));

      SelectObject(ps.hdc, GetStockObject(NULL_PEN));    { no rectangle frame }

      { get the size of characters in the current font                        }

      GetTextExtentPoint32(ps.hdc,
                           'A',
                           1,
                           TextSize);

      if FlickerMinimize then
      begin
        { erase whatever may be above the text                                }

        CopyRect(ClearRect, ClientRect);
        with ClearRect do
        begin
          { adjust the dimension of ClearRect to be the rectangle that is     }
          { above the text.                                                   }

          inc(Right, 1);                            { + 1 because of NULL_PEN }
          Bottom := Bottom div 2 - TextSize.cy + 1; { ditto                   }
        end;

        with ClearRect do
        begin
          Rectangle(ps.hdc,
                    0,                   { left                               }
                    0,                   { top                                }
                    Right,
                    Bottom);
        end;

        { and whatever may be below it                                        }

        CopyRect(ClearRect, ClientRect);
        with ClearRect do
        begin
                                              { left coordinate is unchanged  }
          Top := Top div 2 + TextSize.cy * 3; { skip the 3 lines of text      }
          inc(Right);
          inc(Bottom);
        end;

        with ClearRect do
        begin
          Rectangle(ps.hdc,
                    0,
                    Top,
                    Right,
                    Bottom);
        end;

        { and UNLIKE what would happen if windows had erased the background   }
        { do not erase the text currently shown.  The calls to TextOut below  }
        { will take care of that.                                             }
      end;

      { display our owner window clip region info                             }

      with OwnerRect do
      begin
        StrFmt(Buf,
               'WndBox (%d, %d) - (%d, %d)',
               [Left, Top, Right, Bottom]);
      end;

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              Buf,
              lstrlen(Buf));

      with OwnerClipBox do
      begin
        StrFmt(Buf,
               'ClipBox (%d, %d) - (%d, %d)',
               [Left, Top, Right, Bottom]);
      end;

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 + (1 * TextSize.cy),
              Buf,
              lstrlen(Buf));

      { output the current type of region                                     }

      RegionTypeText := ERROR_REGION; { initial value                         }

      case RegionType of
        NULLREGION:    RegionTypeText := NULL_REGION;

        SIMPLEREGION:  RegionTypeText := SIMPLE_REGION;

        COMPLEXREGION: RegionTypeText := COMPLEX_REGION;

        ERROR:         RegionTypeText := ERROR_REGION;
      end;

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2 + (2 * TEXTSIZE.CY),
              RegionTypeText,
              lstrlen(RegionTypeText));

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_FLICKER:
        begin
          { toggle the menu item and its corresponding flag, FlickerMinimize  }

          if GetMenuState(GetMenu(Wnd), IDM_FLICKER, MF_BYCOMMAND) <> 0 then
          begin
            { go from checked to unchecked - FlickerMinimize = false          }

            FlickerMinimize := FALSE;

            CheckMenuItem(GetMenu(Wnd),
                          IDM_FLICKER,
                          MF_BYCOMMAND or MF_UNCHECKED);
          end
          else
          begin
            { go from unchecked to checked - FlickerMinimize = true           }

            FlickerMinimize := TRUE;

            CheckMenuItem(GetMenu(Wnd),
                          IDM_FLICKER,
                          MF_BYCOMMAND or MF_CHECKED);
          end;
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
      KillTimer(Wnd, TIMER_ID);


      PostQuitMessage(0);

      exit;
    end; { WM_DESTROY }
  end; { case msg }

  PopupWndProc := DefWindowProc (Wnd, Msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  GetClipBox_Call    = 'GetClipBox (dc : HDC; var ClipRect : TRECT) : integer;';
var
  ps                 : TPAINTSTRUCT;
  ClientRect         : TRECT;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { following call present only to get rid of hint about the function     }
      { being unused.  See the IsWindowFullyCovered example for how to use.   }

      IsWindowFullyCovered(Wnd);    { do nothing with the result              }
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      {-----------------------------------------------------------------------}
      { Draw the function call label                                          }

      GetClientRect(Wnd, ClientRect);
      SetBkMode(ps.hdc, TRANSPARENT);
      SetTextAlign(ps.hdc, TA_CENTER or TA_BOTTOM);
      SelectObject(ps.hdc, GetStockObject(DEFAULT_GUI_FONT));

      TextOut(ps.hdc,
              ClientRect.Right  div 2,
              ClientRect.Bottom div 2,
              GetClipBox_Call,
              lstrlen(GetClipBox_Call));

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
    with cls do begin
      { cbSize has already been initialized as required above                 }

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
  else InitAppClass := True;
end;

{-----------------------------------------------------------------------------}

function InitPopupClass: WordBool;
  { registers the application's window classes                                }
var
  cls : TWndClassEx;

begin
  cls.cbSize            := sizeof(TWndClassEx);         { must be initialized }

  if not GetClassInfoEx (hInstance, PopupName, cls) then
  begin
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;
      lpfnWndProc     := @PopupWndProc;               { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;            { qualify instance!     }
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetSysColorBrush(COLOR_WINDOW);
      lpszMenuName    := POPUPMENU;                   { Menu name             }
      lpszClassName   := PopupName;                   { Window Class name     }
      hIconSm         := LoadImage(hInstance,
                                   APPICON,
                                   IMAGE_ICON,
                                   16,
                                   16,
                                   LR_DEFAULTCOLOR);
    end; { with }

    InitPopupClass := WordBool(RegisterClassEx(cls));
  end
  else InitPopupClass := True;
end;


Function WinMain : integer;
  { application entry point                                                   }
var
  Wnd : hWnd;
  Msg : TMsg;

begin
  if not InitAppClass   then Halt(255);   { register application's class      }
  if not InitPopupClass then Halt(255);   { the popup window                  }

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
                        400,                    { window width                }
                        225,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        hInstance,              { instance handle             }
                        Nil);                   { parameter sent to WM_CREATE }

  if Wnd = 0 then Halt;                         { could not create the window }

  Wnd := CreateWindowEx(WS_EX_CLIENTEDGE or WS_EX_TOPMOST,
                        PopupName,              { class name                  }
                        AppName,                { window caption text         }
                        ws_Popup            or  { window style                }
                        ws_Caption          or
                        ws_SysMenu          or
                        ws_MinimizeBox      or
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_visible,             { make showwindow unnecessary }
                        110,                    { x pos on screen             }
                        50,                     { y pos on screen             }
                        300,                    { window width                }
                        300,                    { window height               }
                        Wnd,                    { parent window handle        }
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
