

{$ifdef VER90}
  { the following definitions are missing in Delphi 2.0                       }

const
  ICON_SMALL            = 0;
  ICON_BIG              = 1;

  function GetConsoleWindow : HWND; stdcall; external kernel32;

  function GetConsoleProcessList(ProcessList : PDWORD; ProcessCount : DWORD)
           : DWORD; stdcall; external 'kernel32';
{$endif}


{-----------------------------------------------------------------------------}
{ unlike Delphi, FPC does not automatically reset the console handles when    }
{ a new console is created.  ConsoleCreate and ConsoleDestroy keep the        }
{ FPC RTL "informed" to the existence or non-existence of a console.          }

function ConsoleCreate: boolean;
begin
  result := AllocConsole();

  if not result then exit;

  { let the FPC RTL know there is a console                                   }

  {$ifdef FPC}
    StdInputHandle  := 0;
    StdOutputHandle := 0;
    StdErrorHandle  := 0;
    IsConsole       := TRUE;

    SysInitStdIO;

    IsConsole       := FALSE;
  {$endif}
end;

{-----------------------------------------------------------------------------}

procedure ConsoleDestroy;
begin
  { let the FPC RTL know there is no longer a console                         }

  {$ifdef FPC}
    SysFlushStdIO;
  {$endif}

  FreeConsole;

  {$ifdef FPC}
    SysInitStdIO;
  {$endif}
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

function CursorPosThread(ThreadId : DWORD) : DWORD; stdcall;
  { thread to determine if the "about ..." menu item in the system menu was   }
  { selected.                                                                 }

const
  MENU_CLASS                = '#32768';

  ItemSize        : TSIZE   = (cx:0; cy:0);
  MenuItemHeight  : ptrint  = 0;

var
  MenuWindowRect  : TRECT;

  CursorPos       : TPOINT;

  MenuWindow      : HWND;

  MenuFrameWidth  : ptrint;
  MenuFrameHeight : ptrint;

  AboutRect       : TRECT;

  dc              : HDC;

begin
  CursorPosThread := 0;           { failure code                              }

  ZeroMemory(@CursorPos, sizeof(CursorPos));

  while TRUE do
  begin
    MenuWindow := FindWindow(MENU_CLASS, nil);

    if MenuWindow <> 0 then
    begin
      with ItemSize do      { get the dimensions of the "About ..." string    }
      if (cx = 0) or (cy = 0) or (MenuItemHeight = 0) then
      begin
        dc := GetWindowDC(MenuWindow);
        GetTextExtentPoint32(dc,
                             ABOUT_STRING,
                             lstrlen(ABOUT_STRING),
                             ItemSize);

        ReleaseDC(MenuWindow, dc);
      end;

      MenuFrameHeight := GetSystemMetrics(SM_CYFIXEDFRAME);
      MenuFrameWidth  := GetSystemMetrics(SM_CXFIXEDFRAME);

      MenuItemHeight  := GetSystemMetrics(SM_CYMENUSIZE);

      GetWindowRect(MenuWindow, MenuWindowRect);
      CopyRect(AboutRect, MenuWindowRect);

      { calculate the rectangle dimensions of the "about ..." menu item       }

      with AboutRect do
      begin
        Left   := MenuWindowRect.Left   + MenuFrameWidth;
        Right  := MenuWindowRect.Right  - MenuFrameWidth;
        Bottom := MenuWindowRect.Bottom - MenuFrameHeight;

        { the "About ..." menu item is presumed to be the last item           }

        Top    := Bottom                - MenuItemHeight;
      end;

      GetCursorPos(CursorPos);
    end
    else
    begin
      if (CursorPos.x = 0) and (CursorPos.y = 0) then
      begin
        { do nothing                                                          }
      end
      else
      begin
        { determine if the about menu item was selected                       }

        if PtInRect(AboutRect, CursorPos) then
        begin
          DialogBox(hInstance, ABOUTBOX, GetConsoleWindow(), @About);
        end;

        CursorPos.x := 0;
        CursorPos.y := 0;
      end;
    end;

    Sleep(5);                     { don't hog the CPU                         }
  end;

  CursorPosThread := 1;           { success code                              }
end;

{-----------------------------------------------------------------------------}

procedure SetupConsoleWindow(Initialize : boolean);
const
  IconPrev    : HICON = 0;  { handle of _original_ CLI icon                   }

  ModePrev    : DWORD = 0;

var
  Wnd         : HWND;
  Icon        : HICON;
  Menu        : HMENU;

  Thread      : THANDLE;
  ThreadId    : DWORD;

  ProcessList : array[1..10] of DWORD;  { 10 should be enough                 }
  WindowRect  : TRECT;

begin
  Wnd      := GetConsoleWindow();
  ThreadId := 0;

  if Initialize then
  begin
    { if we were started from an existing console, we don't want to move it,  }
    { doing so would be impolite. if we have our own console then place it at }
    { the "standard" location on the screen.                                  }

    if GetConsoleProcessList(@ProcessList, high(ProcessList)) = 1 then
    begin
      GetWindowRect(Wnd, WindowRect);
      MoveWindow(Wnd,
                 20,
                 20,
                 WindowRect.Right  - WindowRect.Left,
                 WindowRect.Bottom - WindowRect.Top,
                 TRUE);
    end;

    { get the icon the console is currently using.                            }

    IconPrev := SendMessage(Wnd,
                            WM_GETICON,
                            ICON_SMALL,
                            0);                 { can pass zero for DPI       }

    { TCCLE and (possibly other command line shells) returns 0 for the above  }
    { SendMessage but return a valid handle for ICON_BIG.  NOTE: cmd.exe      }
    { returns a valid handle for ICON_SMALL.                                  }

    if IconPrev = 0 then         { maybe using TCCLE instead of cmd.exe       }
    begin
      IconPrev := SendMessage(Wnd,
                              WM_GETICON,
                              ICON_BIG,
                              0);               { can pass zero for DPI       }
    end;

    { load the small icon we want the console to display                      }

    Icon := LoadImage(GetModuleHandle(nil),
                      APPICON,
                      IMAGE_ICON,
                      16,
                      16,
                      LR_DEFAULTCOLOR);

    { tell the console to use our small icon                                  }

    SendMessage(Wnd, WM_SETICON, ICON_SMALL, Icon);

    { change the title to reflect the usage.  NOTE that we don't need to save }
    { and restore the original title, the console resets its title when the   }
    { program ends. NOTE: for some unknown reason cmd.exe resets its title in }
    { caps instead of lowercase.  Not our concern!.                           }

    SetConsoleTitle(AppName);

    { save the current/original console mode just in case the code changes it }

    GetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), ModePrev);

    { append the "About..." to the system menu                                }

    Menu := GetSystemMenu(Wnd, FALSE);
    AppendMenu (Menu, MF_SEPARATOR, 0        ,  nil);
    AppendMenu (Menu, MF_STRING,    IDM_ABOUT, ABOUT_STRING);

    {-------------------------------------------------------------------------}
    { create the cursor position thread.  NOTE: that normally Delphi and FPC  }
    { programs should use BeginThread to let their RTL know this is a multi   }
    { threaded program.                                                       }

    Thread := CreateThread(nil,              { no thread security attributes  }
                           0,                { default stack size             }
                           @CursorPosThread, { the thread code to be executed }
                           nil,              { pass the window to the counter }
                           0,                { no fancy flags/options needed  }
                           ThreadId);

    {-------------------------------------------------------------------------}
    { close the thread handle, we don't need it anymore as we                 }
    { won't be manipulating the thread created above.                         }

    CloseHandle(Thread);

    exit;                                       { intialization is done       }
  end;

  { presumably a call to restore the console the way it was. Ensure a call to }
  { initialize it was made before a call to restore it the way it was.        }

  { the values of IconPrev and ModePrev should not be zero if a previous call }
  { to this routine was made.                                                 }

  if (IconPrev = 0) or (ModePrev = 0) then
  begin
    exit;                                       { no previous call, exit      }
  end;

  { restore the console to the way it was                                     }

  SetConsoleMode(GetStdHandle(STD_INPUT_HANDLE), ModePrev);

  { clear the input buffer                                                    }

  FlushConsoleInputBuffer(GetStdHandle(STD_INPUT_HANDLE));

  { tell the console to use its original icon again                           }

  SendMessage(Wnd, WM_SETICON, ICON_SMALL, IconPrev);

  GetSystemMenu(Wnd, TRUE);                     { revert to the original menu }
end;