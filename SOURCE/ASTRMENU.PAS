{$M 32768, 0, 65536}
PROGRAM Contents;   {Chapters for computer programs}

USES DOS, GRAPH, CUPSMupp, CUPS, CUPSgui;

VAR
  LeaveMenu : Boolean;
  n : integer;

FUNCTION ProgramChosen : integer;
VAR BarMenu : TBarMenu;
BEGIN
   CUPSInit;
   BarMenu.Init;
   ClearMUPPETPort;
   SetColor(Yellow);
   SetTextStyle(1, HorizDir, 2);
   PrintXY(0.02, 0.95,'                     J.M.Anthony Danby');
   PrintXY(0.02, 0.87, '           Modelling: From Sports to Spaceflight');
   PrintXY(0.02, 0.78,'               Space-Flight and Astronomy');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'A Trip to the Moon                             ';
      Row[2] := 'The Descent of Skylab                          ';
      Row[3] := 'The Range of an ICBM                           ';
      Row[4] := 'Jupiter and a Comet                            ';
      Row[5] := 'Motion Close to L4                             ';
      Row[6] := 'Aero-braking a Space-craft                     ';
      Row[7] := '           Return to the main menu             ';
      draw(0.17,0.67,7,n);
   END;
   n := BarMenu.chosen;
   ProgramChosen := n;
   ClearMUPPETPort;
   CloseGraph;
   CUPSDone;
END;

BEGIN
   LeaveMenu := False;
   n := 1;
   ShowCursor;
   REPEAT
      CASE ProgramChosen of
       1: BEGIN SwapVectors; Exec('MoonTrip.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('SkyLab.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('ICBM.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('Comet.EXE', ''); SwapVectors; END;
       5: BEGIN SwapVectors; Exec('L4.EXE', ''); SwapVectors; END;
       6: BEGIN SwapVectors; Exec('Aerobrak.EXE', ''); SwapVectors; END;
       7: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.