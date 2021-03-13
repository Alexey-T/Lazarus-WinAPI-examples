unit resource;
  { resource IDs for the window clipping example                              }

{-----------------------------------------------------------------------------}
INTERFACE
{-----------------------------------------------------------------------------}

const
 IDM_EXIT           = 100;
 IDM_ABOUT          = 300;

 { main window menu constants                                                 }

 IDM_MWHREDRAW      = 210;
 IDM_MWVREDRAW      = 220;

 IDM_MWCLIPSIBLINGS = 230;
 IDM_MWCLIPCHILDREN = 240;

 IDM_MWWRITE        = 250;


 { child window menu constants                                                }

 IDM_CWHREDRAW      = 310;
 IDM_CWVREDRAW      = 320;

 IDM_CWCLIPSIBLINGS = 330;
 IDM_CWCLIPCHILDREN = 340;

 IDM_CWWRITE        = 350;


 { grand child window menu constants                                          }

 IDM_GCHREDRAW      = 410;
 IDM_GCVREDRAW      = 420;

 IDM_GCCLIPSIBLINGS = 430;
 IDM_GCCLIPCHILDREN = 440;

 IDM_GCWRITE        = 450;

{-----------------------------------------------------------------------------}
IMPLEMENTATION
{-----------------------------------------------------------------------------}

end.