{$APPTYPE GUI}

{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - BitBlt example'}

{$R BitBlt.res}

program _BitBlt;
  { Win32 API function - BitBlt example                                       }

  { Note that this example uses a null brush to paint the background.  The    }
  { effect of this is roughly the same as telling Windows the background has  }
  { been erased when in reality it has not.                                   }
  {                                                                           }
  { using a null brush to paint the client area background implies that the   }
  { _entire_ image (including any background) will be painted when processing }
  { the WM_PAINT message.  (Doing otherwise will let areas of windows behind  }
  { it show through.)                                                         }
  {                                                                           }
  { Note also the window class DOES NOT include the styles CS_VREDRAW and     }
  { CS_HREDRAW because what is painted in the client area does NOT depend on  }
  { the size of the window (unlike in the GRADIENT example where it does.)    }
  {---------------------------------------------------------------------------}

uses
  Windows,
  Messages,
  SysUtils,
  Resource
  ;

const
  AppNameBase  = 'BitBlt Example';

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
{ NOTE: Delphi 2 does not have a DWORD type (unsigned 32 bit)                 }

{$ifdef VER90}        { Delphi 2.0 }
type
  ptrint  = longint;  { or integer }
  ptruint = DWORD;
  UINT    = DWORD;
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

function WndProc (Wnd : hWnd; Msg : UINT; wParam, lParam : ptrint)
         : ptrint; stdcall;
  { main application/window handler function                                  }
const
  Bitmap        : HBITMAP = 0;    { bitmap to be painted on the client area   }
  BitmapStrs    : packed array[1..2] of pchar =
    ('CHIP', 'EARTH');            { the bitmaps to select from                }

var
  ps            : TPAINTSTRUCT;   { needed to process the WM_PAINT message    }

  BitmapDC      : HDC;
  BitmapInfo    : TBITMAP;

  ClientRect    : TRECT;

  x, y          : integer;

begin
  WndProc := 0;

  case Msg of
    WM_CREATE:
    begin
      { load the bitmap that we'll paint in the client area. We'll delete     }
      { this bitmap when processing the WM_DESTROY message.  This way we      }
      { don't have to LoadBitmap and DeleteBitmap every time a WM_PAINT is    }
      { received.                                                             }

      Bitmap := LoadBitmap(hInstance, BitmapStrs[1]);

      CheckMenuRadioItem(GetMenu(Wnd),
                         IDM_CHIP,
                         IDM_EARTH,
                         IDM_CHIP,
                         MF_BYCOMMAND);


      exit;
    end;

    WM_PAINT:
    begin
      BeginPaint(Wnd, ps);

      if Bitmap = 0 then       { there is no bitmap to paint                  }
        begin
          EndPaint(Wnd, ps);

          exit;
        end;

      BitmapDC := CreateCompatibleDC(ps.hdc);       { create a DC             }
      SelectObject(BitmapDC, Bitmap);               { put the bitmap in it    }

      { get the bitmap's dimensions                                           }

      GetObject(Bitmap, sizeof(BitmapInfo), @BitmapInfo);

      GetClientRect(Wnd, ClientRect);  { get the client area dimensions       }

      { BitBlt the bitmap on the client area as many times as necessary to    }
      { cover the entire client area.                                         }

      y := 0;
      repeat

        x := 0;
        repeat
          BitBlt(ps.hdc,               { destination dc                       }
                 x,                    { x coordinate of destination rect     }
                 y,                    { y coordinate of destination rect     }
                 BitmapInfo.bmWidth,   { width of destination rectangle       }
                 BitmapInfo.bmHeight,  { height of destination rectangle      }
                 BitmapDC,             { dc containing source bitmap          }
                 0,                    { source bitmap x coordinate           }
                 0,                    { source bitmap y coordinate           }
                 SRCCOPY);             { copy the source area to the dest     }

          inc(x, BitmapInfo.bmWidth);  { go thru the x axis                   }
        until (x > ClientRect.Right);

        inc(y, BitmapInfo.bmHeight);   { go thru the y axis                   }
      until (y > ClientRect.Bottom);

      DeleteDC(BitmapDC);

      EndPaint(Wnd, ps);

      exit;
    end;

    WM_COMMAND:
    begin
      case LOWORD(wParam) of
        IDM_CHIP,
        IDM_EARTH:
            begin
              { Delete the previous bitmap from the pool of objects kept      }
              { for us by GDI.                                                }

              if Bitmap <> 0 then DeleteObject(Bitmap);
              Bitmap := 0;             { invalidate the value in Bitmap       }

              { load the new bitmap                                           }

              if LOWORD(wParam) = IDM_CHIP then
              begin
                Bitmap := LoadBitmap(hInstance, BitmapStrs[1]);

                CheckMenuRadioItem(GetMenu(Wnd),
                                   IDM_CHIP,
                                   IDM_EARTH,
                                   IDM_CHIP,
                                   MF_BYCOMMAND);
              end
              else
              begin
                Bitmap := LoadBitmap(hInstance, BitmapStrs[2]);

                CheckMenuRadioItem(GetMenu(Wnd),
                                   IDM_CHIP,
                                   IDM_EARTH,
                                   IDM_EARTH,
                                   MF_BYCOMMAND);
              end;

              if Bitmap = 0 then
              begin
                MessageBox(Wnd,
                           'The requested bitmap couldn''t be loaded',
                           'For your information',
                           MB_ICONERROR or MB_OK);
              end;

              InvalidateRect(Wnd, nil, TRUE);  { update the client area       }

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
      { Now is the time to Delete the bitmap that we created during the       }
      { WM_CREATE message.                                                    }

      if Bitmap <> 0 then DeleteObject(Bitmap);


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
    with cls do
    begin
      { cbSize has already been initialized as required above                 }

      style           := CS_BYTEALIGNCLIENT;          { no CS_HREDRAW/VREDRAW }
      lpfnWndProc     := @WndProc;                    { window class handler  }
      cbClsExtra      := 0;
      cbWndExtra      := 0;
      hInstance       := system.hInstance;            { qualify instance!     }
      hIcon           := LoadIcon (hInstance, APPICON);
      hCursor         := LoadCursor(0, IDC_ARROW);
      hbrBackground   := GetStockObject(NULL_BRUSH);  { reduces flicker       }
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
  Wnd : HWND;
  Msg : TMSG;

begin
  if not InitAppClass then Halt (255);  { register application's class        }

  { Create the main application window                                        }

  Wnd := CreateWindowEx(WS_EX_CLIENTEDGE,
                        AppName,                { class name                  }
                        AppName,                { window caption text         }
                        ws_OverlappedWindow or  { window style                }
                        ws_ClipSiblings     or
                        ws_ClipChildren     or  { don't affect children       }
                        ws_Visible,             { make showwindow unnecessary }
                        50,                     { x pos on screen             }
                        50,                     { y pos on screen             }
                        400,                    { window width                }
                        300,                    { window height               }
                        0,                      { parent window handle        }
                        0,                      { menu handle 0 = use class   }
                        hInstance,              { instance handle             }
                        nil);                   { parameter sent to WM_CREATE }

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