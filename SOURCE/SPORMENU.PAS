{$M 32768, 0, 65536}
PROGRAM Sports;   {Chaptes for computer programs}

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
   PrintXY(0.02, 0.79,'                           Sports');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'Pitching at Baseball                           ';
      Row[2] := 'Driving at Golf                                ';
      Row[3] := 'Serving at Tennis                              ';
      Row[4] := 'Bowling at Cricket                             ';
      Row[5] := 'Serving at Badminton                           ';
      Row[6] := 'Throwing a Discus                              ';
      Row[7] := 'Throwing a Javelin                             ';
      Row[8] := '            Return to the main menu            ';
      draw(0.17,0.67,8,n);
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
       1: BEGIN SwapVectors; Exec('Pitch.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('Golf.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('Tennis.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('Bowl.EXE', ''); SwapVectors; END;
       5: BEGIN SwapVectors; Exec('Badmintn.EXE', ''); SwapVectors; END;
       6: BEGIN SwapVectors; Exec('Discus.EXE', ''); SwapVectors; END;
       7: BEGIN SwapVectors; Exec('Javelin.EXE', ''); SwapVectors; END;
       8: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.