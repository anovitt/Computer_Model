Program Aerobraking;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 4;

type
   vector = array[1..neq] of real;

VAR
   y                           : Vector;
   BrakeMenu                   : TMenu;
   HotKeys                     : THotKeys;
   Sliders                     : TSliders;
   Input                       : TInputScreen;
   Key                         : Byte;
   Radius, PlanetMass          : Real;
   Rho0, ScaleHeight           : Real;
   CrossSection                : Real;
   SpaceCraftMass              : Real;
   Time, StepSize              : Real;
   Drag                        : Real;
   Mu                          : Real;
   x0, y0, vx0                 : Real;
   xOld, yOld                  : Real;
   xLow, xHigh, yLow, yHigh    : Real;
   Lag                         : Integer;
   ExitRequest                 : Boolean;
   LightMenu                   : Boolean;
   Action                      : Boolean;
   DeBug                       : Boolean;

{---------------------------------------------------------------------------}

PROCEDURE Hello(FName, HName : String);
VAR
   envir   : TEnvironment;
   image   : TImage;
   x1, y1 : Real;
   x,y,dx,dy,h,i,size,color : word;
BEGIN
   envir.Save;
   envir.Standardize;
   SetColor(White);
   SetRGBPalette(green, $00, $18, $7);
   SetFillStyle(SolidFill,green);
   SetLineStyle(solidLn, 0,thickWidth);
   dx:= round(0.64 *GetMaxX);
   IF GraphMode=VGAMed THEN dy:= round(0.14 *GetMaxY)
   ELSE dy:= round(0.1 *GetMaxY);
   x1 := 0.18;
   y1 := 0.06;
   x := round(x1*GetMaxX);
   y := round(y1*GetMaxY);
   IF (x<0) OR (x+dx>GetMaxX) THEN x := (GetMaxX-dx) DIV 2;
   IF (y<0) OR (y+dy>GetMaxY) THEN y := (GetMaxY-dy) DIV 2;
   SetViewPort(x, y, x+dx, y+dy, clipOn);
   HideMouse;
   Bar(0,0,dx,dy);
   rectangle(1,1,dx-1,dy-1);
   h := 3 * TextHeight('O') DIV 2;
   i := 1; OutTextXY(5,(i-1)*h + 5, '    I thank John Wiley & Sons, Inc for their');
   i := 2; OutTextXY(5,(i-1)*h + 5, '    permission to use the CUPS utilities, ');
   i := 3; OutTextXY(5,(i-1)*h + 5, '    in the programming of this module.  ');
   ShowMouse;
   ShowHelp(FName, HName);
   ClearMuppetPort;
   envir.reset;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpBrakeMenu;
VAR
   I      : Integer;
BEGIN
   With BrakeMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About the program');
       row(1,2, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'The model');
       row(2,2, 'Atmospheric drag');
       row(2,3, 'Running the program');
       row(2,4, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Parameters for the planet');
       row(3,2, 'Parameters for the space-craft');
       row(3,3, 'Parameters for the start');
       row(3,4, 'See animation');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   BrakeMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Run';
      Key[3] := 'F3-KeyStart';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;


{------------------------------------------------------------------------}

FUNCTION PlanetInput : Boolean;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.14, 0.86, 0.15, 0.9);
      LoadLine('');
      LoadLine('              Input for the Planet');
      LoadLine('');
      LoadLine('     The mass of the planet is in units of the mass');
      LoadLine('  of the Earth. Enter a number for this mass:');
      LoadLine('              Mass = {       } Earth masses.');
      LoadLine('     Enter the radius of the planet in km:');
      LoadLine('            Radius = {       } km.');
      LoadLine('     Enter the density of the atmosphere at ground');
      LoadLine('  level:      Rho0 = {       } Kg/m^3.');
      LoadLine('     The density at altitude A is Rho where');
      LoadLine('                Rho = Rho0*Exp(-A/H),');
      LoadLine('  where H is the scale height. Enter a value for H:');
      LoadLine('  Scale height = H = {       } km.');
      LoadLine('');
      LoadLine('        [ Help ]     [  OK  ]     [Cancel]');
      SetHelpFile('HelpAstr.Hlp', 'ABrakeInputHelp');
      SetNumber(1, PlanetMass);
      SetNumber(2, Radius);
      SetNumber(3, Rho0);
      SetNumber(4, ScaleHeight);
      REPEAT
         AcceptScreen;
         PlanetInput := NOT Canceled;
         PlanetMass := GetNumber(1);
         Radius := GetNumber(2);
         Rho0 := GetNumber(3);
         ScaleHeight := GetNumber(4);
         IF (PlanetMass <= 0) OR (Radius <= 0) OR
           (Rho0 <= 0) OR (ScaleHeight <= 0)
         THEN Announce('They must all be positive. Try again!');
      UNTIL (PlanetMass > 0) AND (Radius > 0) AND
               (Rho0 > 0) AND (ScaleHeight > 0) OR Canceled;
      Done;
   END;
   Mu := 398618.0*PlanetMass;
END;

{------------------------------------------------------------------------}

FUNCTION SpaceCraftInput : Boolean;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.20, 0.75);
      LoadLine('');
      LoadLine('         Input for the Space-craft');
      LoadLine('');
      LoadLine('     Enter values of the mass and the ');
      LoadLine('  cross-sectional area of the space craft.');
      LoadLine('  The drag is proportional to the ratio');
      LoadLine('  Area/Mass.');
      LoadLine('           Mass = {       } Kg');
      LoadLine('           Area = {       } m^2');
      LoadLine('');
      LoadLine('         [  OK  ]          [Cancel]');
      SetNumber(1, SpaceCraftMass);
      SetNumber(2, CrossSection);
      REPEAT
         AcceptScreen;
         SpaceCraftInput := NOT Canceled;
         SpaceCraftMass := GetNumber(1);
         CrossSection := GetNumber(2);
         IF (SpaceCraftMass <= 0) OR (CrossSection <= 0) THEN
          Announce('They must all be positive. Try again!');
      UNTIL (SpaceCraftMass > 0) AND (CrossSection > 0) OR Canceled;
      Done;
   END;
   Drag := CrossSection*1000.0/(2*SpaceCraftMass);
END;

{------------------------------------------------------------------------}

FUNCTION StartInput : Boolean;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.18, 0.82, 0.1, 0.9);
      LoadLine('');
      LoadLine('     Input for the Starting Conditions');
      LoadLine('');
      LoadLine('     The motion is in the x-y plane, with ');
      LoadLine('  origin at the center of the planet. ');
      LoadLine('  Initially the space-craft is at (x0, y0).');
      LoadLine('  The velocity, parallel to the x-axis,');
      LoadLine('  has magnitude vx0. Enter values for these.');
      LoadLine('  They must all be positive. While running');
      LoadLine('  animation, you will be able to change y0');
      LoadLine('  and vx0, but not x0. Make x0 at least ten');
      LoadLine('  times the planet''s radius, '+NumStr(Radius, 6, 0));
      LoadLine('  y0 and vx0 must be postive.');
      LoadLine('');
      LoadLine('    x0 = {       } km,   y0 = {       } km');
      LoadLine('              vx0 = {       } km/sec');
      LoadLine('');
      LoadLine('            [  OK  ]      [Cancel]');
      SetNumber(1, x0);
      SetNumber(2, y0);
      SetNumber(3, vx0);
      REPEAT
         AcceptScreen;
         StartInput := NOT Canceled;
         x0 := GetNumber(1);
         y0 := GetNumber(2);
         vx0 := GetNumber(3);
         IF (x0 < 10*Radius) OR (y0 <= 0) OR (vx0 <= 0) THEN
            Announce('x0 is too small or y0 or vx0 are negative. Try again!');
      UNTIL (x0 > 10*Radius) AND (y0 > 0) AND (vx0 > 0) OR Canceled;
      IF NOT Canceled THEN
      BEGIN
         y[1] := x0;
         y[3] := y0;
         y[2] := - vx0;
         y[4] := 0;
         xOld := y[1];
         yOld := y[3];
         Time := 0;
         StepSize := 10;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
VAR
   r, rrr           : Extended;
   v, Density, Altitude: Real;
   Term : Real;
BEGIN
   r := sqrt(y[1]*y[1] + y[3]*y[3]);
   Term := Mu/r;
   Term := Term/r;
   Term := Term/r;
   v := sqrt(y[2]*y[2] + y[4]*y[4]);
   z[1] := y[2]; z[3] := y[4];
   Altitude := r - Radius;
   IF Altitude < 10*ScaleHeight THEN
      Density := Rho0*exp(- Altitude/ScaleHeight)
      ELSE Density := 0;
   z[2] := - Term*y[1] - Drag*Density*v*y[2];
   z[4] := - Term*y[3] - Drag*Density*v*y[4];
END;

{------------------------------------------------------------------------}

Procedure Step(xin, hin, tol: real; yin: Vector;
               VAR xout, hout: real; VAR yout: Vector);

VAR
   a, ch, ct:                      array[1..6] of real;
   b:                              array[1..6,1..5] of real;
   f:                              array[1..6] of vector;
   y, ytemp, te:                          Vector;
   x, xtemp, h, htemp, temax:                   real;
   k, l, n:                        integer;

begin
{Parameters for the Runge-Kutta-Fehlberg method of
order 4/5.}
   a[1]   := 0     ;    a[2]   := 2/9     ;    a[3]   := 1/3;
   a[4]   := 3/4   ;    a[5]   := 1       ;    a[6]   := 5/6;
   ch[1]  := 47/450;    ch[2]  := 0       ;    ch[3]  := 12/25;
   ch[4]  := 32/225;    ch[5]  := 1/30    ;    ch[6]  := 6/25;
   ct[1]  := -1/150;    ct[2]  := 0       ;    ct[3]  := 3/100;
   ct[4]  := -16/75;    ct[5]  := -1/20   ;    ct[6]  := 6/25;
   b[2,1] := 2/9   ;    b[3,1] := 1/12    ;    b[3,2] := 1/4;
   b[4,1] := 69/128;    b[4,2] := -243/128;    b[4,3] := 135/64;
   b[5,1] := -17/12;    b[5,2] := 27/4    ;    b[5,3] := -27/5;
   b[5,4] := 16/15 ;    b[6,1] := 65/432  ;    b[6,2] := -5/16;
   b[6,3] := 13/16 ;    b[6,4] := 4/27    ;    b[6,5] := 5/144;

   xtemp := xin;
   h := hin;
   Fun(xin, yin, f[1]);
   ytemp := yin;
   repeat {until temax < tol}
      for k := 2 to 6 do
         begin
            x := xtemp + a[k]*h;
            y := ytemp;
            for n := 1 to neq do
               begin
                  for l := 1 to k-1 do
                      y[n] := y[n] + h*b[k,l]*f[l,n];
               end;
            Fun(x, y, f[k]);
         end; {k loop}
      y := ytemp;
      for n := 1 to neq do
         begin
            te[n] := 0;
               for k := 1 to 6 do
                  begin
                     y[n] := y[n] + h*ch[k]*f[k,n];
                     te[n] := te[n] + h*ct[k]*f[k,n];
                  end;  {k loop}
               te[n] := abs(te[n]);
         end; {n loop}
      temax := Tol/100000;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveSpaceCraft;
BEGIN
   Delay(Lag);
   IF StepSize > 20 THEN StepSize := 20;
 {  RuboutXY(0.5, 0.9, 30, Black);
   PrintXY(0.5, 0.9, NumStr(StepSize, 10, 8));
   RuboutXY(0.5, 0.8, 30, Black);
   PrintXY(0.5, 0.8, NumStr(Sqrt(y[1]*y[1]+y[3]*y[3]), 15, 0)); }
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF Sqrt(y[1]*y[1] + y[3]*y[3])>119480 THEN DeBug := True;
   PlotLine(xOld, yOld, y[1], y[3]);
   xOld := y[1];
   yOld := y[3];
   {IF (y[1]*y[2] + y[3]*y[4] > 0) AND
      (y[2]*y[2]+y[4]*y[4] > 2*Mu/Sqrt(y[1]*y[1] + y[3]*y[3]))}
   IF Abs(y[1]) + Abs(y[3]) > 5*(x0 + y0)
   THEN
   BEGIN
      Action := False;
      WITH HotKeys DO Key[2] := 'F2-Run';
      HotKeys.BackColor := Red;
      HotKeys.Display;
      Announce('You are going to escape');
   END;
   IF y[1]*y[1] + y[3]*y[3] < Radius*Radius THEN
   BEGIN
      Action := False;
      WITH HotKeys DO Key[2] := 'F2-Run';
      HotKeys.BackColor := Red;
      HotKeys.Display;
      Announce('You have crashed');
   END;

END;

{-------------------------------------------------------------------------}

PROCEDURE PlotAnimationScreen;
BEGIN
   ClearMuppetPort;
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   OpenViewPort(1);
   SelectScale(1);
   Axis(0, 0, 10000, 1000);
   SetColor(LightBlue);
   SetFillStyle(SolidFill, LightBlue);
   FillEllipse(MapX(0), MapY(0),
               MapX(Radius)-MapX(0), -MapY(Radius)+MapY(0));
   SetColor(White);
   PlotLine(x0, -9*y0, x0, 9*y0);
   Sliders.Create(1, 0, 10, vx0, 0.05, 0.12, 0.95, 3,
                    '0', '10', 'vx0 km/sec', False);
   Sliders.Create(2, Radius, yHigh, y0, 0.05, 0.2, 0.95, 0,
                    NumStr(Radius, 6, 0), NumStr(yHigh, 6, 0), 'y0', False);
   Sliders.DrawAll;
   SetUpHotKeys;
   Action := False;
   LightMenu := False;
   y[1] := x0;
   y[3] := y0;
   y[2] := - vx0;
   y[4] := 0;
   xOld := y[1];
   yOld := y[3];
   Time := 0;
   StepSize := 10;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpAnimationScreen;
BEGIN
   xLow := -x0/2;
   xHigh := 1.05*x0;
   yLow := -2*y0;
   yHigh := 2*y0;
   PlotAnimationScreen;
END;

{-------------------------------------------------------------------------}

PROCEDURE KeyInput;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.23, 0.77, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Enter new values for y0 and v.');
      LoadLine('');
      LoadLine('    '+NumStr(Radius, 6, 0)+' < y0 = {       } < '
                     +NumStr(yHigh, 6, 0));
      LoadLine('       0 <= vx0 = {       } <= 10');
      LoadLine('');
      LoadLine('               [  OK  ]');
      SetNumber(1, y0);
      SetNumberLimits(1, Radius, yHigh);
      SetNumber(2, vx0);
      SetNumberLimits(2, 0, 10);
      AcceptScreen;
      y0 := GetNumber(1);
      vx0 := GetNumber(2);
      y[1] := x0;
      y[3] := y0;
      y[2] := - vx0;
      y[4] := 0;
      xOld := y[1];
      yOld := y[3];
      Time := 0;
      StepSize := 10;
      Done;
   END;
   Sliders.Create(1, 0, 10, vx0, 0.05, 0.12, 0.95, 3,
                    '0', '10', 'vx0 km/sec', False);
   Sliders.Create(2, Radius, yHigh, y0, 0.05, 0.2, 0.95, 0,
                    NumStr(Radius, 6, 0), NumStr(yHigh, 6, 0), 'y0', False);
   Sliders.DrawAll;
END;

{-------------------------------------------------------------------------}

PROCEDURE ReScale;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Enter extreme values for the display:');
      LoadLine('');
      LoadLine('  Minimum x = {       } < '+NumStr(-Radius, 6, 0));
      LoadLine('  Maximum x = {       } > '+NumStr(Radius, 6, 0));
      LoadLine('  Minimum y = {       } < '+NumStr(-Radius, 6, 0));
      LoadLine('  Maximum y = {       } > Minimum y');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, xLow);
      SetNumberLimits(1, -10000000, - Radius);
      SetNumber(2, xHigh);
      SetNumberLimits(2, Radius, 10000000);
      SetNumber(3, yLow);
      SetNumberLimits(3, -10000000, - Radius);
      SetNumber(4, yHigh);
      REPEAT
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         yLow := GetNumber(3);
         yHigh := GetNumber(4);
         IF yLow >= yHigh THEN
           Announce('You have confused lower and upper limits. Try again.');
      UNTIL yLow < yHigh;
      Done;
   END;
   PlotAnimationScreen;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   vx0 := Sliders.Value(1);
   y0 := Sliders.Value(2);
   y[1] := x0;
   y[3] := y0;
   y[2] := - vx0;
   y[4] := 0;
   xOld := y[1];
   yOld := y[3];
   Time := 0;
   StepSize := 10;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleBrakeMenu;
BEGIN
   With BrakeMenu DO
      CASE ColChosen OF
         1: CASE RowChosen OF
               1: ShowHelp('HelpAstr.Hlp', 'ABrakeAboutProgram');
               2: AboutCUPS;
               3: Configuration;
               4: ExitRequest := True;
            END;
         2: CASE RowChosen OF
               1: ShowHelp('HelpAstr.Hlp', 'ABrakeAboutModel');
               2: ShowHelp('HelpAstr.Hlp', 'ABrakeDragHelp');
               3: ShowHelp('HelpAstr.Hlp', 'ABrakeRunProgram');
               4: ShowHelp('WalkThru.hlp', 'AeroBrake');
            END;
         3: CASE RowChosen OF
               1: IF NOT PlanetInput THEN LightMenu := True
                  ELSE
                  IF NOT SpaceCraftInput THEN LightMenu := True
                  ELSE
                  IF StartInput THEN SetUpAnimationScreen;
               2: IF NOT SpaceCraftInput THEN LightMenu := True;
               3: IF NOT StartInput THEN LightMenu := True;
               4: SetUpAnimationScreen;
         END;
      END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HelpAstr.Hlp','ABrakeHotKeysHelp');
      2: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Action := True;
               WITH HotKeys DO Key[2] := 'F2-Stop';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
         END;
      3: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            KeyInput;
         END;
      4: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            ReScale;
         END;
      5: BEGIN
            Action := False;
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.1, 0.95, 0.3, 0.9);
   PlanetMass := 1;
   Radius := 6000;
   Rho0 := 1;
   ScaleHeight := 10;
   SpaceCraftMass := 10000;
   CrossSection := 100;
   x0 := 200000;
   y0 := 14830.2;
   vx0 := 5.07895;
   y[1] := x0;
   y[3] := y0;
   y[2] := - vx0;
   y[4] := 0;
   xOld := y[1];
   yOld := y[3];
   Time := 0;
   StepSize := 10;
   SetUpBrakeMenu;
   ExitRequest := False;
   LightMenu := True;
   Action := False;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   BrakeMenu.Init;
   Sliders.Init;
   Hello('HelpAstr.Hlp', 'ABrakeAboutProgram');
   GetSetUp;
   IF NOT PlanetInput THEN LightMenu := True
   ELSE
   IF NOT SpaceCraftInput THEN LightMenu := True
   ELSE
   IF StartInput THEN SetUpAnimationScreen;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Action THEN MoveSpaceCraft;
      IF (NOT Action) AND Sliders.Changed THEN HandleSliders;
      IF LightMenu THEN IF BrakeMenu.Chosen THEN HandleBrakeMenu;
   UNTIL ExitRequest;
   CUPSDone;
   BrakeMenu.Done;
   Sliders.Done;
END.