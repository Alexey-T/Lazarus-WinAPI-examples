{$LONGSTRINGS    OFF}
{$WRITEABLECONST ON}
{$DESCRIPTION    'Win32 API function - LoadLibraryEx example'}

{ NOTE:  Delphi 2.0 assigns a default image base of $0040000 to all modules   }
{        including DLLs.  The result is that all Delphi DLLs will have to have}
{        their relocation records applied in order to load.  This makes the   }
{        load time longer.                                                    }
{                                                                             }
{        To make the module load faster specify an image base that is around  }
{        $00860000.  This is where most Delphi processes have the largest     }
{        block of free memory and few, if any, Windows DLLs try to load there.}
{        Note however that this is still no guarantee that the DLL will load  }
{        at an optimum address (another DLL might want to load there as well.)}
{-----------------------------------------------------------------------------}

{$IMAGEBASE $00970000}          { best low address for this module            }

Library _GetModuleHandleExDll;
  { Win32 API function - GetModuleHandleEx example supporting dll             }


uses
  Resource
  ;

function DllFunction(Variable : integer) : integer;
begin
  result := Variable * Variable;
end;


exports DllFunction index DLL_FUNCTION_INDEX;  { see resource.pas             }

begin
  { process attach code - none in this case                                   }
end.
