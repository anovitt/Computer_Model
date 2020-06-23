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
   PrintXY(0.02, 0.99,'                     J.M.Anthony Danby');
   PrintXY(0.02, 0.91, '           Modelling: From Sports to Spaceflight');
   PrintXY(0.02, 0.83, '                     Table of Contents');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'Welcome                                        ';
      Row[2] := 'Introduction                                   ';
      Row[3] := 'Chaos                                          ';
      Row[4] := 'Predator-Prey Models                           ';
      Row[5] := 'Sickness and Health                            ';
      Row[6] := 'Sports                                         ';
      Row[7] := 'Space Flight and Astronomy                     ';
      Row[8] := 'Pendulums                                      ';
      Row[9] := 'Bits and Pieces                                ';
      Row[10] := '                Leave the program             ';
      draw(0.17,0.72,10,n);
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
       1: BEGIN SwapVectors; Exec('Firework.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('IntrMenu.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('ChaoMenu.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('PredPrey.EXE', ''); SwapVectors; END;
       5: BEGIN SwapVectors; Exec('HealMenu.EXE', ''); SwapVectors; END;
       6: BEGIN SwapVectors; Exec('SporMenu.EXE', ''); SwapVectors; END;
       7: BEGIN SwapVectors; Exec('AstrMenu.EXE', ''); SwapVectors; END;
       8: BEGIN SwapVectors; Exec('PendMenu.EXE', ''); SwapVectors; END;
       9: BEGIN SwapVectors; Exec('MiscMenu.EXE', ''); SwapVectors; END;
       10: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.