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
   PrintXY(0.02, 0.79,'                        Introduction');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'Direction Fields and Euler''s Methods          ';
      Row[2] := 'Runge-Kutta-Fehlberg 4/5 Tests                 ';
      Row[3] := 'Richardson''s Arms Race                        ';
      Row[4] := '            Return to the main menu                ';
      draw(0.17,0.65,4,n);
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
       1: BEGIN SwapVectors; Exec('D-Fields.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('RKFTests.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('ArmsRace.EXE', ''); SwapVectors; END;
       4: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.