{$define DEBUG}

{$ifdef  DEBUG} {$APPTYPE        CONSOLE} {$endif}
{$ifndef DEBUG} {$APPTYPE        GUI}     {$endif}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API functions - GetParent and GetAncestor example'}

{$R GetParent&GetAncestor.res}

//{$define CREATE_POPUP_AFTER_MAIN}

{ the following defines only make a difference when CREATE_POPUP_AFTER_MAIN   }
{ is not defined. ONLY ONE of them should be defined.                         }

//{$define POPUP_OWNER_IS_GRANDCHILD}
//{$define POPUP_OWNER_IS_TOPLEVELWINDOW}


{ EXECUTION NOTES:                                                            }
{                                                                             }
{ compile and run the program with each of the defines above set and not set. }
{ pay particular attention to the how this affects the window handle for      }
{ GW_OWNER.                                                                   }

{ NOTE about compiling and debugging this example with FPC.  Likely due to a  }
{ bug in v3.0.4 (and possibly later versions too), the error/hint messages    }
{ are off by one (1).   Debugging this example under Lazarus also suffers     }
{ from this problem, execution stops on the line that FOLLOWS the breakpoint  }
{ instead of the line where the breakpoint is set.                            }


program _GetParentAndGetAncestor;
  { shows the effects of GetParent and GetAncestor with various options       }

uses
  Windows,
  Messages,
  Resource,
  SysUtils
  ;

const
  AppNameBase  = 'GetParent & GetAncestor';

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

const
  kernel32 = 'kernel32';
  user32   = 'user32';
  gdi32    = 'gdi32';

{$ifdef VER90}
  // for Delphi 2.0 define GetWindowLongPtr and SetWindowLongPtr as synonyms of
  // GetWindowLong and SetWindowLong respectively.

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


  { definitions missing in Delphi 2                                           }

  function GetConsoleWindow
           : HWND;  stdcall; external kernel32;

  function GetConsoleProcessList(ProcessList : PDWORD; ProcessCount : DWORD)
           : DWORD; stdcall; external kernel32;

  function GetAncestor(Wnd : HWND; AncestorFlags : DWORD)
           : HWND;  stdcall; external user32;

const
  { constants used by the GetAncestor API                                     }

  GA_PARENT    = 1;
  GA_ROOT      = 2;
  GA_ROOTOWNER = 3;
{$endif}

{$ifdef FPC}
  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(Wnd : HWND; out Rect : TRECT)
           : BOOL; stdcall;    external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL; stdcall;    external user32 name 'GetMessageA';

  { "override" some FPC definitions with better parameter names               }

  function GetDC(Wnd : HWND)
           : HDC; stdcall;     external user32;

  function ReleaseDC(Wnd : HWND; dc : HDC)
           : longint; stdcall; external user32;

  function GetTextExtentPoint32(dc      : HDC;
                                str     : pchar;
                                strlen  : integer;
                            out strsize : TSIZE)
           : BOOL; stdcall     external gdi32 name 'GetTextExtentPoint32A';

  function BeginPaint(Wnd         : HWND;
                  out PaintStruct : TPaintStruct)
           : HDC; stdcall;     external user32;

  function GetWindowRect(Wnd  : HWND;
                     out Rect : TRECT)
           : BOOL; stdcall;    external user32;
{$endif}


{ the following functions are missing in both FPC and Delphi 2                }

function IsDebuggerPresent                      { no () because of Delphi 2   }
         : BOOL; stdcall;      external kernel32;


{ in addition to missing, the following functions are undocumented            }

function GetTopLevelWindow(Wnd : HWND)
         : HWND; stdcall;      external user32;


{ used only to indicate if the "current" window is a top level window         }

function IsTopLevelWindow(Wnd : HWND)
         : BOOL; stdcall;      external user32;

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
  { used to identify the window being created when processing the WM_CREATE   }

  TWINDOWS_ID              =
  (
    wi_window_none,        { identifies "no window"                           }

    wi_window_main,
    wi_window_child,
    wi_window_grandchild,

    wi_window_popup
  );

const
  MainWnd                  : HWND = 0;
  PopupWnd                 : HWND = 0;

  ConsoleWnd               : HWND = 0;  { set only if we have our own console }

  MAIN_WINDOW_WIDTH        = 550;
  MAIN_WINDOW_HEIGHT       = 900;

  CAPTION_CHILD            = 'Child Window';
  CAPTION_GRANDCHILD       = 'Grand Child Window';
  CAPTION_POPUP            = 'Popup Window';

  {$ifdef DEBUG}
    DebugBuffer            : packed array[0..511] of char = #0;
  {$endif}

{-----------------------------------------------------------------------------}

type
  { IMPORTANT: the following enumeration must be zero based because the       }
  { LabelsArray is also zero based.  This is because they share an indexing   }
  { variable.                                                                 }

  TWINDOW_HANDLES_LIST =
  (
    wh_desktop,
    wh_toplevel,
    wh_window,
    wh_window_istoplevel,             { does NOT index to a window handle     }
    wh_parent,
    wh_ancestor_parent,
    wh_ancestor_root,
    wh_ancestor_rootowner,
    wh_window_owner                   { from GetWindow(..., GW_OWNER)         }
  );

{-----------------------------------------------------------------------------}

const
  HANDLE_WIDEST_VAL = '$DDDDDDDD';    { widest possible hex string            }

  MARGIN_TOP   = 20;
  MARGIN_LEFT  = 20;                  { also used as a right margin           }

  MARGIN_RIGHT = 3 * MARGIN_LEFT;

  FONT_ALL     = DEFAULT_GUI_FONT;    { MUST be a stock font                  }

  LINE_CNT     = 14;
  BLANK_LINE   = #0;

  LabelsArray  : packed array[0..LINE_CNT - 1] of pchar =
  (
    'Desktop window handle : ',
    BLANK_LINE,
    'Top level window handle : ',
    BLANK_LINE,
    'This window handle : ',
    'Is this window top level ? : ',      { indexed by wh_window_istoplevel   }
    BLANK_LINE,
    'GetParent(ThisWindowHandle) : ',
    BLANK_LINE,
    'GetAncestor(ThisWindowHandle, GA_PARENT) : ',
    'GetAncestor(ThisWindowHandle, GA_ROOT) : ',
    'GetAncestor(ThisWindowHandle, GA_ROOTOWNER) : ',
    BLANK_LINE,
    'GetWindow(ThisWindowHandle, GW_OWNER) : '
  );

  LabelsLenMax : DWORD = 0;    { maximum width of labels in LabelsArray       }
  LabelsHeight : DWORD = 0;    { total height of all labels in LabelsArray    }

  FontHeight   : DWORD = 0;
  WidestValue  : DWORD = 0;    { width of HANDLE_WIDEST_VAL                   }

  ValuesArray  : packed array[TWINDOW_HANDLES_LIST] of HWND =
  (
    0,         { wh_desktop             }
    0,         { wh_toplevel            }
    0,         { wh_window              }
    0,         { wh_window_istoplevel   }     { a pointer, not a handle       }
    0,         { wh_parent              }
    0,         { wh_ancestor_parent     }
    0,         { wh_ancestor_root       }
    0,         { wh_ancestor_rootowner  }
    0          { wh_window_owner        }
  );

{-----------------------------------------------------------------------------}

procedure CalculateOutputHeightAndWidth(Wnd : HWND);
  { sets LabelsHeight and LabelsLenMax                                        }
var
  dc          : HDC;
  i           : integer;

  TextSize    : TSIZE;

begin
  dc := GetDC(Wnd);       { if we can't get a DC, Windows is in bad shape     }

  { calculate the total height of the text to output                          }

  SelectObject(dc, GetStockObject(FONT_ALL));
  GetTextExtentPoint32(dc,
                       HANDLE_WIDEST_VAL,
                       lstrlen(HANDLE_WIDEST_VAL),
                       TextSize);

  with TextSize do
  begin
    FontHeight   := cy;                    { save the font height             }
    LabelsHeight := cy * LINE_CNT;

    WidestValue  := cx;                    { width of HANDLE_WIDEST_VAL       }
  end;

  { calculate the width of every output line and save the maximum width       }

  for i := low(LabelsArray) to high(LabelsArray) do
  begin
    GetTextExtentPoint32(dc,
                         LabelsArray[i],
                         lstrlen(LabelsArray[i]),
                         TextSize);

    if TextSize.cx > LabelsLenMax then LabelsLenMax := TextSize.cx;
  end;

  if (ReleaseDC(Wnd, dc) = 0) and IsDebuggerPresent() then
  begin
    asm int 3; end            { could use DebugBreak() too                    }
  end;
end;

{-----------------------------------------------------------------------------}

procedure OnPaint(Wnd : HWND);
const
  YES                      : pchar = 'Yes';
  NO                       : pchar = 'No';

  FORMAT_HANDLE            : pchar = '$%x';
  FORMAT_STRING            : pchar = '%s';

var
  ps                       : TPAINTSTRUCT;
  ClientRect               : TRECT;

  Buf                      : packed array[0..511] of char;

  x                        : DWORD;                { x coordinate             }

  i                        : DWORD;                { index into Labels array  }
  v                        : TWINDOW_HANDLES_LIST; { index into Values array  }

  Format                   : pchar; { either FORMAT_HANDLE or FORMAT_STRING   }

begin
  BeginPaint(Wnd, ps);

  GetClientRect(Wnd, ClientRect);

  SetBkMode(ps.hdc, TRANSPARENT);
  SelectObject(ps.hdc, GetStockObject(FONT_ALL));

  { get the Desktop window handle                                             }

  ValuesArray[wh_desktop]  := GetDesktopWindow();

  { get the top level window                                                  }

  ValuesArray[wh_toplevel] := GetTopLevelWindow(Wnd);

  { set the value of "this window handle"                                     }

  ValuesArray[wh_window]   := Wnd;

  { determine if the window is a top level window. NOTE: this value is NOT a  }
  { window handle, it is a string.  This has to be "accounted for" when       }
  { outputting the values.                                                    }

  ValuesArray[wh_window_istoplevel] := THANDLE(NO);
  if IsTopLevelWindow(Wnd) then ValuesArray[wh_window_istoplevel]:=THANDLE(YES);

  { get the window's parent                                                   }

  ValuesArray[wh_parent]   := GetParent(Wnd);

  { get the ancestor using the possible flags                                 }

  ValuesArray[wh_ancestor_parent]    := GetAncestor(Wnd, GA_PARENT);
  ValuesArray[wh_ancestor_root]      := GetAncestor(Wnd, GA_ROOT);
  ValuesArray[wh_ancestor_rootowner] := GetAncestor(Wnd, GA_ROOTOWNER);

  { get the owner window                                                      }

  ValuesArray[wh_window_owner]       := GetWindow(Wnd, GW_OWNER);

  { output the labels and their corresponding values                          }

  SetTextAlign(ps.hdc, TA_RIGHT or TA_BOTTOM);

  v := low(ValuesArray);                 { index into values array            }

  for i := low(LabelsArray) to high(LabelsArray) do
  begin
    { NOTE: dereferencing the LabelsArray when comparing to BLANK_LINE is     }
    {       necessary to avoid the conversion of the null terminated array    }
    {       into a pascal string followed by a subsequent call to a pascal    }
    {       string compare function. (remove the dereference and look at the  }
    {       resulting assembly code to see the difference.)                   }

    if LabelsArray[i]^ = BLANK_LINE then continue;  { skip blank lines        }

    x := MARGIN_LEFT + LabelsLenMax;     { output x coordinate for labels     }

    TextOut(ps.hdc,                      { the label                          }
            x,
            MARGIN_TOP + (i * FontHeight),
            LabelsArray[i],
            lstrlen(LabelsArray[i]));

    { format and output the value that matches the label                      }

    { the value for the wh_window_istoplevel is not a handle.  the formatting }
    { for it is therefore different.                                          }

    Format := FORMAT_HANDLE;
    if v = wh_window_istoplevel then
    begin
      Format := FORMAT_STRING;

      StrFmt(Buf, Format, [pchar(ValuesArray[v])]);  { typecast is needed !!  }
    end
    else StrFmt(Buf, Format, [ValuesArray[v]]);

    inc(x, WidestValue);                 { output x coordinate for values     }

    TextOut(ps.hdc,                      { the value                          }
            x,
            MARGIN_TOP + (i * FontHeight),
            Buf,
            lstrlen(Buf));

    v := succ(v);                        { index of next value to output      }
  end;

  { we are done painting.                                                     }

  EndPaint(Wnd, ps);
end;

{-----------------------------------------------------------------------------}

function WndProc (Wnd : HWND; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  FAIL_CREATE_CHILD               = 'Couldn''t create the child window';
  FAIL_CREATE_GRANDCHILD          = 'Couldn''t create the grandchild window';
  FAIL_CREATE_POPUP               = 'Couldn''t create the popup window';

  FAIL_CAPTION                    = 'WM_CREATE failure';

  FailText               : pchar  = nil;

var
  CreateParameter        : PDWORD absolute lParam;

  CreateStyle            : DWORD   {$ifdef FPC } =   0 {$endif} ;
  CreateCaption          : pchar   {$ifdef FPC } = nil {$endif} ;
  CreateWindowId         : DWORD   {$ifdef FPC } =   0 {$endif} ;

  CreateX                : integer {$ifdef FPC } =   0 {$endif} ;
  CreateY                : integer {$ifdef FPC } =   0 {$endif} ;
  CreateHeight           : integer {$ifdef FPC } =   0 {$endif} ;
  CreateWidth            : integer {$ifdef FPC } =   0 {$endif} ;

  CreatedWindow          : HWND    {$ifdef FPC } =   0 {$endif} ;
  ParentOrOwnerWindow    : HWND    {$ifdef FPC } =   0 {$endif} ;

  LastError              : DWORD   {$ifdef FPC } =   0 {$endif} ;

  function ChildWindowStyle : DWORD;
    { returns the window style used by child windows                          }
  begin
    result := ws_Child        or    { the important one!                      }
              ws_Visible      or
              ws_SysMenu      or
              ws_MinimizeBox  or
              ws_ClipSiblings or
              ws_ClipChildren or
              ws_Sizebox      or
              ws_Caption;
  end;
begin
  WndProc := 0;

  case msg of
    WM_CREATE:                      { it would be better to have an OnCreate  }
    begin
      { NOTE: the height of the child, grand child and popup windows are      }
      { "ballparked"                                                          }

      case CreateParameter^ of               { alias of lParam                }
        DWORD(wi_window_main) :
        begin
          { calculate the height and width of labels (only needs to be done   }
          { once when the main window is created.)                            }

          CalculateOutputHeightAndWidth(Wnd);

          { the main window has to create a child                             }

          CreateStyle         := ChildWindowStyle;

          CreateCaption       := CAPTION_CHILD;
          CreateX             := MARGIN_LEFT;
          CreateY             := MARGIN_TOP + LabelsHeight;

          CreateWidth         := MAIN_WINDOW_WIDTH  - MARGIN_RIGHT;
          CreateHeight        := 3 * CreateY;

          ParentOrOwnerWindow := Wnd;

          CreateWindowId      := DWORD(wi_window_child);

          FailText            := FAIL_CREATE_CHILD;

          {$ifdef DEBUG}
            writeln;
            StrFmt(DebugBuffer,
                   'Parent window(1)    : %8x',
                   [ptruint(ParentOrOwnerWindow)]);
            writeln(DebugBuffer);
          {$endif}
        end;

        DWORD(wi_window_child) :
        begin
          { the child window has to create a grandchild                       }

          CreateStyle         := ChildWindowStyle;

          CreateCaption       := CAPTION_GRANDCHILD;
          CreateX             := MARGIN_LEFT;
          CreateY             := MARGIN_TOP + LabelsHeight;

          CreateWidth         := MAIN_WINDOW_WIDTH - 2 * MARGIN_RIGHT;
          CreateHeight        := CreateY + CreateY div 2;

          ParentOrOwnerWindow := Wnd;

          CreateWindowId      := DWORD(wi_window_grandchild);

          FailText            := FAIL_CREATE_GRANDCHILD;

          {$ifdef DEBUG}
            StrFmt(DebugBuffer,
                   'Parent window(2)    : %8x',
                   [ptruint(ParentOrOwnerWindow)]);
            writeln(DebugBuffer);
          {$endif}
        end;

        {$ifndef CREATE_POPUP_AFTER_MAIN}
          DWORD(wi_window_grandchild) :
          begin
            { the grandchild window creates the popup window                  }

            CreateStyle         := ws_Popup            or
                                   ws_SizeBox          or
                                   ws_Caption          or
                                   ws_SysMenu          or
                                   ws_MinimizeBox      or
                                   ws_ClipSiblings     or
                                   ws_ClipChildren     or
                                   ws_Visible;

            CreateCaption       := CAPTION_POPUP;
            CreateX             := MARGIN_LEFT  + MAIN_WINDOW_WIDTH;
            CreateY             := MARGIN_TOP;

            CreateWidth         := LabelsLenMax + WidestValue + 3 * MARGIN_LEFT;
            CreateHeight        := LabelsHeight + LabelsHeight div 2;

            { setting the owner to MainWnd will not produce the expected      }
            { result because MainWnd is zero due to its creation not yet      }
            { being complete.                                                 }

            ParentOrOwnerWindow   := 0;

            {$ifdef POPUP_OWNER_IS_GRANDCHILD}
              ParentOrOwnerWindow := Wnd;        { won't end up as owner      }
            {$endif}

            {$ifdef POPUP_OWNER_IS_TOPLEVELWINDOW}
              { in this case the owner will be the main window as expected    }

              ParentOrOwnerWindow := GetTopLevelWindow(Wnd);
            {$endif}

            CreateWindowId      := 0;

            FailText            := FAIL_CREATE_POPUP;

            {$ifdef DEBUG}
              writeln;
              StrFmt(DebugBuffer,
                     'Owner window        : %8x',
                     [ptruint(ParentOrOwnerWindow)]);
              writeln(DebugBuffer);
            {$endif}
          end;
        {$endif}

        else exit;
      end;

      CreatedWindow := CreateWindowEx(0,                     { extended style }
                                      AppName,               { class name     }
                                      CreateCaption,
                                      CreateStyle,
                                      CreateX,
                                      CreateY,
                                      CreateWidth,
                                      CreateHeight,
                                      ParentOrOwnerWindow,
                                      CreateWindowId,
                                      hInstance,
                                      pointer(CreateWindowId));
      if CreatedWindow = 0 then
      begin
        LastError := GetLastError();  { find out what happened                }

        MessageBox(Wnd,
                   FailText,
                   FAIL_CAPTION,
                   MB_OK);

        WndProc := -1;                { abort window creation                 }
        exit;
      end;

      if CreateParameter^ = DWORD(wi_window_grandchild) then
      begin
        { save the popup window handle                                        }

        PopupWnd := CreatedWindow;
      end;

      exit;
    end;

    WM_PAINT:
    begin
      OnPaint(Wnd);
      exit;
    end;

    WM_ACTIVATE:
    begin
      if LOWORD(wParam) <> 0 then    { window is being activated              }
      begin
        if Wnd = MainWnd then
        begin
          { the main window is being activated, make the popup window visible }

          SetWindowPos(PopupWnd,
                       HWND_TOP,
                       0,
                       0,
                       0,
                       0,
                       SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

          if ConsoleWnd <> 0 then
          begin
            { NOTE: with consoles SetWindowPos works only MOST of the time.   }
            {       the reason why it doesn't work all the time is unknown.   }

            SetWindowPos(ConsoleWnd,
                         HWND_TOP,
                         0,
                         0,
                         0,
                         0,
                         SWP_ASYNCWINDOWPOS or
                         SWP_NOACTIVATE     or SWP_NOMOVE or SWP_NOSIZE);
          end;

          exit;
        end;

        if Wnd = PopupWnd then
        begin
          { the popup window is being activated, make the main window visible }

          SetWindowPos(MainWnd,
                       HWND_TOP,
                       0,
                       0,
                       0,
                       0,
                       SWP_NOACTIVATE or SWP_NOMOVE or SWP_NOSIZE);

          if ConsoleWnd <> 0 then
          begin
            { NOTE: with consoles SetWindowPos works only MOST of the time.   }
            {       the reason why it doesn't work all the time is unknown.   }

            SetWindowPos(ConsoleWnd,
                         HWND_TOP,
                         0,
                         0,
                         0,
                         0,
                         SWP_ASYNCWINDOWPOS or
                         SWP_NOACTIVATE     or SWP_NOMOVE or SWP_NOSIZE);
          end;

          exit;
        end;
      end;
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
      { NOTE: since this window procedure is shared by all windows in this    }
      {       program, closing ANY of the windows, including child windows,   }
      {       causes the program to terminate.                                }

      PostQuitMessage(0);

      exit;
    end; { WM_DESTROY }
  end; { case msg }

  WndProc := DefWindowProc(Wnd, Msg, wParam, lParam);
end;

{-----------------------------------------------------------------------------}

function InitWindowClass: WordBool;
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

    InitWindowClass := WordBool(RegisterClassEx (cls));
  end
  else InitWindowClass := TRUE;
end;

{-----------------------------------------------------------------------------}

procedure PositionDebugConsole(Wnd : HWND);
  { positions the console window to ensure it is not obscured by this         }
  { program's main window or its popup.  NOTE: this procedure is NOT general  }
  { it uses knowledge of the total height of the text output in the windows.  }
var
  ProcessCount : DWORD;
  ProcessList  : array[1..10] of DWORD;

  WindowRect   : TRECT;
  ConsoleRect  : TRECT;

begin
  { if the main window has not yet been created, there is no need to move the }
  { console window.                                                           }

  if Wnd = 0 then exit;

  { the main window exists, figure out if we need to move the console         }

  if GetConsoleWindow() = 0 then
  begin
    { there is no console, therefore there is nothing to position             }

    exit;
  end;

  ZeroMemory(@ProcessList, sizeof(ProcessList));

  ProcessCount := 0;
  ProcessCount := GetConsoleProcessList(@ProcessList, high(ProcessList));

  if ProcessCount > 1 then
  begin
    { we were started from a pre-existing console, not from a console we own  }
    { therefore, don't alter the position of the console, it would not be     }
    { "polite" to move a pre-existing console.                                }

    exit;         { existing console remains whereever it currently is        }
  end;

  { we own the console, move it to be right next to our window and below the  }
  { popup.                                                                    }

  ConsoleWnd := GetConsoleWindow();         { save the handle to the console  }

  GetWindowRect(Wnd,        WindowRect);
  GetWindowRect(ConsoleWnd, ConsoleRect);

  with ConsoleRect do
  begin
    MoveWindow(ConsoleWnd,                  { our dedicated console window    }
               WindowRect.Right,            { x snug to the main window       }
               2 * LabelsHeight,            { below the popup window          }
               Right  - Left,               { no change in width              }
               Bottom - Top,                { no change in height             }
               TRUE);                       { repaint it                      }
  end;
end;

{-----------------------------------------------------------------------------}

function WinMain : integer;
  { application entry point                                                   }
var
  Wnd : HWND absolute MainWnd;          { synonym for global MainWnd          }
  Msg : TMsg;

begin
  if not InitWindowClass then           { register application's class        }
  begin
   {$ifdef DEBUG}
     writeln('failed to register the window class');
     writeln('press ENTER/RETURN to end this program');
     readln;
   {$endif}

   halt(255);
  end;

  { Create the main application window                                        }

  Wnd := CreateWindow (AppName,                 { class name                  }
                       AppName,                 { window caption text         }
                       ws_OverlappedWindow or   { window style                }
                       ws_SysMenu          or
                       ws_MinimizeBox      or
                       ws_ClipSiblings     or
                       ws_ClipChildren     or   { don't affect children       }
                       ws_Visible,              { make showwindow unnecessary }
                       MARGIN_LEFT,             { x pos on screen             }
                       MARGIN_TOP,              { y pos on screen             }
                       MAIN_WINDOW_WIDTH,       { window width                }
                       MAIN_WINDOW_HEIGHT,      { window height               }
                       0,                       { parent window handle        }
                       0,                       { menu handle 0 = use class   }
                       hInstance,               { instance handle             }
                       pointer(wi_window_main));{ parameter sent to WM_CREATE }

  {$ifdef DEBUG}
    writeln;
    StrFmt(DebugBuffer, 'Main  window handle : %8x', [ptruint(Wnd)]);
    writeln(DebugBuffer);
  {$endif}

  if Wnd = 0 then
  begin
    { could not create the main window                                        }

    {$ifdef DEBUG}
      writeln('CreateWindow failed to create the program''s main window');
      writeln('press ENTER/RETURN to end this program');
      readln;
    {$endif}

    halt(254);
  end;

  {$ifdef DEBUG}
    { position the console window such that it is NOT obscured by the main    }
    { window or the popup window.                                             }

    PositionDebugConsole(Wnd);
  {$endif}

  {$ifdef CREATE_POPUP_AFTER_MAIN}
    PopupWnd    := CreateWindowEx(0,
                                  AppName,                { class name        }
                                  CAPTION_POPUP,
                                  ws_Popup            or
                                  ws_SizeBox          or
                                  ws_Caption          or
                                  ws_SysMenu          or
                                  ws_MinimizeBox      or
                                  ws_ClipSiblings     or
                                  ws_ClipChildren     or
                                  ws_Visible,
                                  MARGIN_LEFT  + MAIN_WINDOW_WIDTH,
                                  MARGIN_TOP,
                                  LabelsLenMax + WidestValue + 3 * MARGIN_LEFT,
                                  LabelsHeight + LabelsHeight div 2,
                                  Wnd,
                                  0,
                                  hInstance,
                                  nil);

    {$ifdef DEBUG}
      StrFmt(DebugBuffer, 'Popup window handle : %8x', [ptruint(PopupWnd)]);
      writeln(DebugBuffer);
    {$endif}

    if PopupWnd = 0 then
    begin
      { could not create the popup window                                     }

    {$ifdef DEBUG}
      writeln('CreateWindow failed to create the program''s popup window');
      writeln('press ENTER/RETURN to end this program');
      readln;
    {$endif}

      halt(253);
    end;
  {$endif}

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
