PROGRAM FireworksDisplay;

USES crt, Graph, CUPSMupp, CUPS, CupsGui;


type
   vector = array[1..6] of Real;

VAR
   vx, vy, vz, fac                     : Real;
   InitialSpeed, Time, DT              : Real;
   Gravity, Resistance                 : Real;
   x, y, z, XS, YS                     : Extended;
   Fireworks                           : Array[1..501] OF Vector;
   FireworksStart                      : Array[1..501] OF Vector;
   Visible                             : Array[1..500] OF Boolean;
   xStart, yStart                      : Array[1..10] OF Real;
   Active                              : Array[1..10] OF Boolean;
   Bursting                            : Array[1..10] OF Boolean;
   NFirework                           : Integer;
   Lag                                 : Integer;
   FireworkMenu                        : TMenu;
   HotKeys                             : THotKeys;
   ExitRequest, LightMenu              : Boolean;
   Firework                            : Boolean;
   UseMouse                            : Boolean;
   Key                                 : Byte;

{------------------------------------------------------------------------}

PROCEDURE SetUpFireworkMenu;
BEGIN
   With FireworkMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'Hello');
       row(1,2, 'About the CUPS utilities');
       row(1,3, 'If you don''t have a mouse...');
       row(1,4, '<Configuration> help');
       row(1,5, 'Play with fireworks');
       row(1,6, 'Leave the program');
      AutoChecking(1,1);
   END;
   FireworkMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(3);
      Key[1] := 'F3-Faster';
      Key[2] := 'F4-Slower';
      Key[3] := 'F10-Menu';
   END;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE Parameters;
  BEGIN
     Vx := 1; Vy := 0; Vz := -1;
     Fac := Sqrt(Vx*Vx + Vy*Vy + Vz*Vz);
     Vx := Vx/Fac; Vy := Vy/Fac; Vz := Vz/Fac;
     Fac := 1/SQRT(Vx*Vx + Vy*Vy);
     InitialSpeed := 5;
     Time := 0;
     DT := 0.2;
     Gravity := 1;
     Resistance := 0.1;
  END;

{------------------------------------------------------------------------}

PROCEDURE InitialConditions;
VAR
   i, j, k           : Integer;
   Theta             : Real;
   R                 : Real;
BEGIN
   FOR I := 1 TO 10 DO
   BEGIN
      Active[I] := False;
      Bursting[I] := False;
   END;
   FOR I := 1 to 501 DO
   BEGIN
      FOR J := 1 TO 6 DO
      BEGIN
         Fireworks[I, J] := 0;
         FireworksStart[I, J] := 0;
      END;
   END;
   FOR J := 1 TO 500 DO
   BEGIN
      Fireworks[j, 1] := 0;
      Fireworks[j, 2] := 0;
      R := Random;
      Fireworks[j, 4] := R;
      Fireworks[j, 3] := SQRT(1 - R*R)*InitialSpeed;
      R := Random;
      IF R > 0.5 THEN Fireworks[j, 4] := - Fireworks[j, 4];
      R := Random;
      Theta := 2*Pi*R;
      Fireworks[j, 5] := Cos(Theta);
      Fireworks[j, 6] := Sin(Theta);
      FOR i := 1 TO 6 DO
         FireworksStart[j,i] := Fireworks[j,i];
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Forces(z: vector; var f: vector);
BEGIN
   f[1] := z[3];
   f[2] := z[4];
   f[3] := - Resistance*z[3]*Sqrt(z[3]*z[3] + z[4]*z[4]);
   f[4] := - Gravity + Resistance*z[4]*Sqrt(z[3]*z[3] + z[4]*z[4]);
end;

{------------------------------------------------------------------------}

PROCEDURE PlotFirework(FireworkNumber: Integer; NColor: Integer);
VAR
   i, j             : Integer;
   z1, z2, yy       : Vector;
   VisibleCount     : Integer;
BEGIN
   SetColor(NColor);
   VisibleCount := 50;
   FOR j := 50*(FireworkNumber-1)+1 to 50*(FireworkNumber-1)+50 DO
   BEGIN
      IF Visible[j] THEN
      BEGIN
         Forces(Fireworks[j], z1);
         FOR i := 1 to 4 do
               yy[i] := Fireworks[j, i] + dt*z1[i];
         Forces(yy, z2);
         FOR i := 1 to 4 do
               Fireworks[j, i] := Fireworks[j, i] + 0.5*dt*(z1[i] + z2[i]);
         z := Fireworks[j, 2];
         x := Fireworks[j, 1]*Fireworks[j, 5];
         y := Fireworks[j, 1]*Fireworks[j, 6];
         XS := FAC*(Y*VX - X*VY);
         YS := -FAC*(Z - VZ*(X*VX + Y*VY + Z*VZ));
         XS := xStart[FireworkNumber] + XS;
         YS := yStart[FireworkNumber] - YS;
         IF YS > 0 THEN BEGIN Delay(Lag); PlotSymbol(XS, YS, '.'); END
         ELSE
         BEGIN
            Visible[j] := False;
            VisibleCount := VisibleCount - 1;
         END;
      END
      ELSE VisibleCount := VisibleCount - 1;
   END;
   IF VisibleCount < 1 THEN
   BEGIN
      IF Bursting[FireworkNumber]
      THEN Bursting[FireworkNumber] := False
      ELSE
         BEGIN
            NFirework := NFirework - 1;
            RuboutXY(0.82, 0.982, 5, Blue);
            SetColor(White);
            PrintXY(0.82, 0.982, NumStr(NFirework, 2, 0));
            Active[FireworkNumber] := False;
         END;
      FOR j := 50*(FireworkNumber-1)+1 to 50*(FireworkNumber-1)+50 DO
      BEGIN
         Visible[j] := True;
         FOR i := 1 TO 6 DO
            Fireworks[j,i] := FireworksStart[j,i];
      END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key : Byte);
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 1;
      CASE Key OF
          1: IF Lag - DelLag > 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
          2: Lag := Lag + DelLag;
          3: BEGIN
               HotKeys.Clear;
               Firework := False;
               LightMenu := True;
            END;
      END;
END;

{-----------------------------------------------------------------------}

PROCEDURE MouseOrAuto;
VAR
   Input   : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.3, 0.7, 0.7, 0.9);
      LoadLine('');
      LoadLine('  Use the mouse to start: #1');
      LoadLine('    Press a key to start: #1');
      LoadLine('          [  OK  ] ');
      IF UseMouse THEN SetRadioButton('1', 1) ELSE SetRadioButton('1', 2);
      AcceptScreen;
      IF GetRadioButton('1') = 1 THEN
             UseMouse := True ELSE UseMouse := False;
      Done;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE RunFireworks;
VAR
   I, J                                : Integer;
   x0, y0, Button                      : Integer;
   Inside                              : Boolean;
   NewFirework                         : Boolean;
BEGIN
    LightMenu := False;
    MouseOrAuto;
    IF NOT UseMouse THEN HideMouse;
    Firework := True;
    NFirework := 0;
    IF UseMouse THEN
    Message('Click at a point to start a firework. Maximum of ten. Currently,'
            )
    ELSE
    Message('   Press a key to start a firework. Maximum of ten.  Currently,'
            );
    PrintXY(0.82, 0.982, NumStr(NFirework, 2, 0));
    OpenViewPort(1);
    SelectScale(1);
    SetUpHotKeys;
    InitialConditions;
    FOR j := 1 TO 500 DO Visible[j] := True;
    Time := 0;

    REPEAT
       CheckForEvents;
       IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
       IF NFirework < 10 THEN
       BEGIN
          Delay(10);
          IF UseMouse THEN
          BEGIN
             MouseGlobalPosn(x0, y0, Button);
             IF (Button <> 0) OR
              (MouseClicked(x0, y0)) THEN
             BEGIN
                NFirework := NFirework + 1;
                RuboutXY(0.82, 0.982, 5, Blue); SetColor(White);
                PrintXY(0.82, 0.982, NumStr(NFirework, 2, 0));
                i := 0;
                REPEAT
                   i := i + 1;
                UNTIL Active[i] = False;
                Active[i] := True;
                Bursting[i] := True;
                MousePosn(xStart[i], yStart[i], 1, 1, Inside);
             END;
          END
          ELSE
          BEGIN
             IF KeyPressed THEN
             BEGIN
                NFirework := NFirework + 1;
                RuboutXY(0.82, 0.982, 5, Blue); SetColor(White);
                PrintXY(0.82, 0.982, NumStr(NFirework, 2, 0));
                i := 0;
                REPEAT
                   i := i + 1;
                UNTIL Active[i] = False;
                Active[i] := True;
                Bursting[i] := True;
                xStart[i] := 10+Random*80;
                yStart[i] := 30+Random*60;
                ClearMKBuffers;
             END;
          END;
       END;
          IF NFirework > 0 THEN
          BEGIN
             Time := Time + Dt;
             FOR i := 1 TO 10 DO
             BEGIN
                IF Active[i] THEN
                   IF Bursting[i] THEN PlotFirework(i, i)
                                  ELSE
                                  PlotFirework(i, GraphBackColor);
             END;
          END;
    UNTIL Firework = False;
    IF NOT USeMouse THEN ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleFireworkMenu;
BEGIN
   With FireworkMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HlpIntro.hlp', 'Hello1');
                  ShowHelp('HlpIntro.hlp', 'Hello2');
                  ShowHelp('HlpIntro.hlp', 'Hello3');
               END;
            2: BEGIN
                  ShowHelp('HlpIntro.hlp', 'CUPSUtilities1');
                  ShowHelp('HlpIntro.hlp', 'CUPSUtilities2');
               END;
            3: BEGIN
                  ShowHelp('HlpIntro.hlp', 'NoMouseHelp1');
                  ShowHelp('HlpIntro.hlp', 'NoMouseHelp2');
               END;
            4: BEGIN
                  ShowHelp('HlpIntro.hlp', 'ConfigurationHelp1');
                  ShowHelp('HlpIntro.hlp', 'ConfigurationHelp2');
               END;
            5: BEGIN
                  ShowHelp('HlpIntro.hlp', 'AboutFireworks');
                  RunFireworks;
               END;
            6: ExitRequest := True;
         END;
   END;
END;

{------------------------------------------------------------------------}


BEGIN
    CUPSInit;
    DefineViewPort(1, 0.05, 0.95, 0.07, 0.95);
    DefineScale(1, 0, 100, 0, 100);
    Lag := 1;
    Lightmenu := True;
    UseMouse := True;
    Parameters;
    GraphBackColor := Black;
    ShowHelp('HlpIntro.hlp', 'Hello1');
    ShowHelp('HlpIntro.hlp', 'Hello2');
    ShowHelp('HlpIntro.hlp', 'Hello3');
    SetUpFireworkMenu;
    REPEAT
       CheckForEvents;
       IF LightMenu AND FireworkMenu.Chosen THEN HandleFireworkMenu;
    UNTIL ExitRequest;
    CUPSDone;
END.