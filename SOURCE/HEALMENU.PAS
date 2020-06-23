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
   PrintXY(0.02, 0.79,'                     Sickness and Health');
   SetTextStyle(0, HorizDir, 1);
   With BarMenu do
   begin
      Row[1] := 'The Spread of Disease                          ';
      Row[2] := 'The Spread of Malaria                          ';
      Row[3] := 'The Spread of Gonorrhea                        ';
      Row[4] := 'Zeeman''s Model for the Hearbeat               ';
      Row[5] := '            Return to the main menu            ';
      draw(0.17,0.67,5,n);
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
       1: BEGIN SwapVectors; Exec('Disease.EXE', ''); SwapVectors; END;
       2: BEGIN SwapVectors; Exec('Malaria.EXE', ''); SwapVectors; END;
       3: BEGIN SwapVectors; Exec('Gonorhea.EXE', ''); SwapVectors; END;
       4: BEGIN SwapVectors; Exec('HeartBea.EXE', ''); SwapVectors; END;
       5: LeaveMenu := true;
      END;
   UNTIL LeaveMenu;
END.