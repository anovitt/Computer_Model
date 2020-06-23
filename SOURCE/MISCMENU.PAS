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
   PrintXY(0.02, 0.97,'                     J.M.Anthony Danby');
   PrintXY(0.02, 0.90, '           Modelling: From Sports to Spaceflight');
   PrintXY(0.02, 0.83,'                       Bits and Pieces');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'Production and Exchange                        ';
      Row[2] := 'The Economics of Fishing                       ';
      Row[3] := 'The Motion of a Yoyo                           ';
      Row[4] := 'Action Between a Violin Bow and String         ';
      Row[5] := 'Landing an Aircraft on an Aircraft Carrier     ';
      Row[6] := 'Pitching and Rolling at Sea                    ';
      Row[7] := 'Motion of a Ball in a Rotating Circular Ring   ';
      Row[8] := 'The Swinging Atwood Machine                    ';
      Row[9] := 'A Chaotically Driven Wheel                     ';
      Row[10] := 'Bernoulli''s Problem: A Swinging Balance      ';
      Row[11] := '           Return to the main menu            ';
      draw(0.17,0.73,11,n);
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
       1: BEGIN SwapVectors; Exec('ProdExch.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('Fishing.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('Yoyo.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('Violin.EXE', ''); SwapVectors; END;
       5: BEGIN SwapVectors; Exec('Airplane.EXE', ''); SwapVectors; END;
       6: BEGIN SwapVectors; Exec('SeaSick.EXE', ''); SwapVectors; END;
       7: BEGIN SwapVectors; Exec('SpinHoop.EXE', ''); SwapVectors; END;
       8: BEGIN SwapVectors; Exec('Satwood.EXE', ''); SwapVectors; END;
       9: BEGIN SwapVectors; Exec('SprChaos.EXE', ''); SwapVectors; END;
       10: BEGIN SwapVectors; Exec('Bernouli.EXE', ''); SwapVectors; END;
       11: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.