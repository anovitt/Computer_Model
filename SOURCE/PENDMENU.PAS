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
   PrintXY(0.02, 0.79,'                        Pendulums');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'The Simple Pendulum                            ';
      Row[2] := 'A Magnetic Pendulum                            ';
      Row[3] := 'A Child on a Swing                             ';
      Row[4] := 'A Spring Pendulum                              ';
      Row[5] := 'The Double-Pendulum                            ';
      Row[6] := 'The Dumbbell Satellite                         ';
      Row[7] := 'The Motion of a Swinging Censer                ';
      Row[8] := 'The Pit and the Pendulum                       ';
      Row[9] := '           Return to the main menu             ';
      draw(0.17,0.67,9,n);
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
       1: BEGIN SwapVectors; Exec('Pendulum.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('MagPend2.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('Swing.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('SprPend.EXE', ''); SwapVectors; END;
       5: BEGIN SwapVectors; Exec('DoubPend.EXE', ''); SwapVectors; END;
       6: BEGIN SwapVectors; Exec('DumbBell.EXE', ''); SwapVectors; END;
       7: BEGIN SwapVectors; Exec('Censer.EXE', ''); SwapVectors; END;
       8: BEGIN SwapVectors; Exec('Pit-Pend.EXE', ''); SwapVectors; END;
       9: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.