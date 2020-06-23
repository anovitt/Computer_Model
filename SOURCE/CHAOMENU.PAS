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
   SetTextStyle(1, HorizDir, 2);
   PrintXY(0.02, 0.95,'                     J.M.Anthony Danby');
   PrintXY(0.02, 0.87, '           Modelling: From Sports to Spaceflight');
   PrintXY(0.02, 0.79,'                           Chaos');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'Poincare Maps: The Model of Henon and Heiles   ';
      Row[2] := 'Lorenz'' Equations                             ';
      Row[3] := 'The Forced Pendulum                            ';
      Row[4] := 'Difference Equations: First Order              ';
      Row[5] := 'Difference Equations: Second Order             ';
      Row[6] := 'Difference Equations: Newton''s Method         ';
      Row[7] := '            Return to the main menu                ';
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
       1: BEGIN SwapVectors; Exec('Hen-Heil.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('Lorenz.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('ForcePen.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('OneDMap.EXE', ''); SwapVectors; END;
       5: BEGIN SwapVectors; Exec('TwoDMap.EXE', ''); SwapVectors; END;
       6: BEGIN SwapVectors; Exec('Newton2D.EXE', ''); SwapVectors; END;
       7: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.