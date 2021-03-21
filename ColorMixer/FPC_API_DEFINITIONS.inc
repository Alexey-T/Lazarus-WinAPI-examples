

  { "override" some FPC definitions to get rid of useless hints               }

  function GetClientRect(Wnd : HWND; out Rect : TRECT)
           : BOOL;     stdcall; external user32;

  function GetMessage(out Msg                        : TMSG;
                          Wnd                        : HWND;
                          MsgFilterMin, MsgFilterMax : UINT)
           : BOOL;     stdcall; external user32 name 'GetMessageA';

  function GetTextExtentPoint32(dc      : HDC;
                                str     : pchar;
                                strlen  : integer;
                            out strsize : TSIZE)
           : BOOL;     stdcall  external gdi32 name 'GetTextExtentPoint32A';

  function BeginPaint(Wnd         : HWND;
                  out PaintStruct : TPaintStruct)
           : HDC;      stdcall; external user32;

  function CopyRect(out DestinationRect : TRECT;
               constref SourceRect      : TRECT)
           : BOOL;     stdcall; external user32;


  { "override" some FPC definitions with better parameter names.  It's nice   }
  { have the Lazarus CODETOOLS show descriptive parameter names.              }

  function EndDialog(DlgWnd    : HWND;
                     DlgResult :longint)
           : BOOL;     stdcall; external user32;

  function SetFocus(Wnd : HWND)
           : HWND;     stdcall; external user32;

  function CreateWindowEx(StyleEx             : DWORD;
                    const ClassName           : pchar;
                    const WindowName          : pchar;
                          Style               : DWORD;
                          X                   : longint;
                          Y                   : longint;
                          Width               : longint;
                          Height              : longint;
                          ParentWnd           : HWND;
                          MenuHandleOrChildId : HMENU;     { THANDLE          }
                          Instance            : HINST;     { THANDLE          }
                          CreateData          : pointer)
           : HWND;     stdcall; external user32 name 'CreateWindowExA';

  function MessageBox(Wnd                : HWND;
                      MessageText        : pchar;
                      CaptionText        : pchar;
                      ButtonAndIconFlags : DWORD)
           : longint;  stdcall; external user32 name 'MessageBoxA';

  function SetScrollInfo(Wnd           : HWND;
                         ScrollBarType : integer;
                constref ScrollInfo    : TSCROLLINFO;
                         Redraw        : BOOL)
           : integer;  stdcall; external user32;

  function CreateSolidBrush(Color : COLORREF)
           : HBRUSH;   stdcall; external gdi32;

  function MoveWindow(Wnd     : HWND;
                      X       : longint;
                      Y       : longint;
                      Width   : longint;
                      Height  : longint;
                      Repaint : BOOL)
           : BOOL;     stdcall; external user32;

  function InvalidateRect(Wnd   : HWND;
                 constref Rect  : TRECT;                   { when not nil     }
                          Erase : BOOL)
           : BOOL;     stdcall; external user32;

  function InvalidateRect(Wnd   : HWND;
                          Rect  : PRECT;                   { when nil         }
                          Erase : BOOL)
           : BOOL;     stdcall; external user32;

  function GetWindowLongPtr(Wnd                    : HWND;
                            IndexOfValueToRetrieve : longint)
           : ptrint;   stdcall; external user32 name 'GetWindowLongA';

  function SetScrollPos(Wnd           : HWND;
                        ScrollBarType : longint;
                        Position      : longint;
                        Redraw        : BOOL)
           : longint;  stdcall; external user32;

  function SelectObject(dc              : HDC;
                        GdiObjectHandle : HGDIOBJ)
           : HGDIOBJ;  stdcall; external gdi32;

  function SetBkMode(dc   : HDC;
                     Mode : longint)
           : longint;  stdcall; external gdi32;

  function SetTextAlign(dc : HDC;
                        AlignmentFlags : DWORD)
           : DWORD;    stdcall; external gdi32;

  { MapWindowPoints should be overloaded to account for the fact that the     }
  { second parameter is an array containing a variable number of points.      }

  function MapWindowPoints(WndFrom, WndTo : HWND;
                       var Point          : TPOINT;     { single point        }
                           PointCount     : DWORD)
           : integer;  stdcall; external user32;

  function MapWindowPoints(WndFrom, WndTo : HWND;
                       var Points         : TRECT;      { two points          }
                           PointCount     : DWORD)
           : integer;  stdcall; external user32;

  function MapWindowPoints(WndFrom, WndTo : HWND;
                           Points         : PPOINT;     { array of points     }
                           PointCount     : DWORD)      { points in array     }
           : integer;  stdcall; external user32;


  function CreateRectRgnIndirect(constref Rect : TRECT)
           : HRGN;     stdcall; external gdi32;

  function TextOut(dc             : HDC;
                   X              : integer;
                   Y              : integer;
                   Text           : pchar;
                   CharacterCount : integer)
           : BOOL;     stdcall; external gdi32 name 'TextOutA';

  function ExtTextOut(dc             : HDC;
                      X              : integer;
                      Y              : integer;
                      OptionFlags    : DWORD;
                      OptionalRect   : PRECT;
                      Text           : pchar;
                      CharacterCount : DWORD;
                      DistancesX     : PINTEGER)
           : BOOL;     stdcall; external gdi32 name 'ExtTextOutA';


const
  { returned by ExtSelectClipRgn, ExcludeClipRect, GetClipBox and others. See }
  { MSDN for full list of region functions.                                   }

  NULLREGION    = 1;
  SIMPLEREGION  = 2;
  COMPLEXREGION = 3;
  ERROR         = 0;

  RGN_NULL      = 1;             { just better names for the above constants  }
  RGN_SIMPLE    = 2;
  RGN_COMPLEX   = 3;
  RGN_ERROR     = 0;

  function ExtSelectClipRgn(dc          : HDC;
                            Region      : HRGN;
                            CombineMode : integer)
           : integer;  stdcall; external gdi32;

  function SelectClipRgn(dc     : HDC;
                         Region : HRGN)
           : integer;  stdcall; external gdi32;


  function Rectangle(dc : HDC;
                     Left   : integer;
                     Top    : integer;
                     Right  : integer;
                     Bottom : integer)
           : BOOL;     stdcall; external gdi32;

  function SetTextColor(dc    : HDC;
                        Color : COLORREF)
           : COLORREF; stdcall; external gdi32;

  function FrameRect(dc    : HDC;
            constref Rect  : TRECT;
                     Brush : HBRUSH)
           : integer;  stdcall; external user32;



  { macro definitions                                                         }

  function CreateWindow(                                   { no StyleEx       }
                    const ClassName           : pchar;
                    const WindowName          : pchar;
                          Style               : DWORD;
                          X                   : longint;
                          Y                   : longint;
                          Width               : longint;
                          Height              : longint;
                          ParentWnd           : HWND;      { THANDLE          }
                          MenuHandleOrChildId : HMENU;     { THANDLE          }
                          Instance            : HINST;     { THANDLE          }
                          CreateData          : pointer)
           : HWND; inline;
  begin
    CreateWindow := CreateWindowEx(0,
                                   ClassName          ,
                                   WindowName         ,
                                   Style              ,
                                   X                  ,
                                   Y                  ,
                                   Width              ,
                                   Height             ,
                                   ParentWnd          ,
                                   MenuHandleOrChildId,
                                   Instance           ,
                                   CreateData);
  end;
