PROGRAM DumbbellSatellite;

USES Dos, Crt, Graph, CUPSMupp, CUPS, CupsGui;

CONST
   neq = 3;

TYPE
   vector = array[1..neq] of real;

VAR
   DumbBellDat: TInputScreen;
   y:                              vector;
   Ecc, Theta, ThetaDot: Real;

   DumbbellMenu                    : TMenu;
   HotKeys                         : THotKeys;
   PHotKeys                        : THotKeys;
   SolHotKeys                      : THotKeys;
   Key                             : Byte;
   Time                            : Real;
   TidalFriction                   : Real;
   Phi, PhiDot                     : Real;
   DelPhi                          : Real;
   NonSphere                       : Real;
   Lag                             : Integer;
   Num, Denom                      : Integer;
   Pause, Action, PlotOrbit        : Boolean;
   LightMenu                       : Boolean;
   ExitRequest                     : Boolean;
   PhasePlot                       : Boolean;
   Animate                         : Boolean;
   Poincare                        : Boolean;
   PlotOrbits                      : Boolean;
   StartOK                         : Boolean;
   SolutionPlot                    : Boolean;
   PlotSine                        : Boolean;
   MouseInput                      : Boolean;
   SeeDumbbell                     : Boolean;
   xOld, yOld, xNew, yNew          : Real;
   xOld1, yOld1                    : Real;
   OldAngle, NewAngle              : Real;
   h                               : Real;
   RotationRatio                   : Real;
   xLow, xHigh, yLow, yHigh        : Real;
   pxLow, pxHigh, pyLow, pyHigh    : Real;
   xStart, xpStart                 : Real;
   PoincareColor                   : Word;
   xScreenRatio, yScreenRatio      : Real;

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

PROCEDURE SetUpDumbBellMenu;
VAR
   I      : Integer;
BEGIN
   With DumbBellMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About the program');
       row(1,2, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Parameters');
       row(2,3, 'The phase-plane');
       row(2,4, 'Poincare maps');
       row(2,5, 'Elliptic orbit demo');
       row(2,6, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Animate the motion');
       row(3,3, 'Phase-plane');
       row(3,4, 'Poincare map');
       row(3,5, 'Plot Phi vs time');
       row(3,6, 'Plot Sin(Phi) vs time');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
  { DumbBellMenu.Display;}
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(4);
      Key[1] := 'F2-Pause';
      Key[2] := 'F4-Faster';
      Key[3] := 'F5-Slower';
      Key[4] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
   Lag := 200;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(5);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-CleanUp';
      Key[4] := 'F5-New E';
      Key[5] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Red;
   PHotKeys.HotKeyColor := Yellow;
   PHotKeys.Display;
   Pause := True;
   StartOK := False;
   Lag := 100;
END;

{-------------------------------------------------------------------------}

FUNCTION GetDumbBellData: Boolean;
BEGIN
   WITH DumbBellDat DO
   BEGIN
      Init;
      DefineInputPort(0.65, 1, 0.05, 0.95);
      LoadLine('  A DumbBell Satellite.');
      LoadLine(' Enter the eccentricity');
      LoadLine('of the orbit; 0 <= e < 0.9:');
      LoadLine('   e = {         }');
      LoadLine(' (e = 0 for a circle)');
      LoadLine(' The motion starts at');
      LoadLIne(' Pericenter. Enter the');
      LoadLine(' initial deflection of');
      LoadLIne(' the satellite;');
      LoadLine('  -90 < Theta < 90:');
      LoadLine('Theta = {         } deg');
      LoadLine(' Enter its rate of change');
      LoadLine(' in degrees per unit time:');
      LoadLine('        {         }');
      LoadLine(' Note: The average orbital');
      LoadLine(' angular rate is 57.29578.');
      LoadLine(' Enter a coefficient for');
      LoadLine(' the resisting force:');
      LoadLine('        {         }');
      LoadLine('');
      LoadLine('[ Help ] [  OK  ] [Cancel]');
      SetHelpFile('HelpPend.Hlp', 'DBellInputHelp');
      SetNumber(1, Ecc);
      SetNumberLimits(1, 0, 0.9);
      SetNumber(2, Theta);
      SetNumberLimits(2, -90, 90);
      SetNumber(3, ThetaDot);
      SetNumber(4, TidalFriction);
      SetNumberLimits(4, 0, 10);
      AcceptScreen;
      GetDumbBellData := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
      Ecc := GetNumber(1);
      Theta := GetNumber(2);
      ThetaDot := GetNumber(3);
      y[1] := Pi*Theta/180;
      y[2] := Pi*ThetaDot/180;
      y[3] := 0;
      TidalFriction := GetNumber(4);
      DefineScale(1, -0.5-(1 + Ecc), 0.5+(1 - Ecc),
          -(5/7)*1.5, (5/7)*1.5);
      Done;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE GetNonSphereValue;
VAR
   Input   : TInputScreen;
BEGIN
   ClearMuppetPort;
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.16, 0.84, 0.2, 0.8);
      LoadLine('');
      LoadLine('     If we consider a satellite in place of the ');
      LoadLine('  dumbbell pendulum then the torque must be');
      LoadLine('  reduced. Let the satellite have principal');
      LoadLine('  moments of inertia A, B, C, with A < B < C.');
      LoadLine('  A corresponds to the longest axis, which might');
      LoadLine('  point toward the planet. Then the torque of the');
      LoadLine('  dumbell pendulum must be reduced by the factor:');
      LoadLine('              p = (B - A)/C.');
      LoadLine('     Enter a value for p:');
      LoadLine('              0 < p = {      } <= 1. ');
      LoadLIne('');
      LoadLine('                     [  OK  ]');
      SetNumber(1, NonSphere);
      SetNumberLimits(1, 0, 1);
      AcceptScreen;
      NonSphere := GetNumber(1);
      Done;
   END;
END;

{-----------------------------------------------------------------------}

FUNCTION XDisp(Delta : Integer) : Integer;
BEGIN
   XDisp := Trunc(Delta*xScreenRatio);
END;

FUNCTION YDisp(Delta : Integer) : Integer;
BEGIN
   YDisp := Trunc(Delta*yScreenRatio);
END;

{------------------------------------------------------------------------}

PROCEDURE ShowParameters;
VAR
   xSc, ySc, xSc2, ySc2: Integer;
   Radius: Integer;
   x1, y1, x2, y2: Real;
   i: Integer;
BEGIN
   DefineViewPort(3, 0, 0.65, 0.05, 0.95);
   DefineScale(3, -4.5, 3.5, -4, 4);
   HideCursor;
   GraphBackColor := DarkGray;
   OpenViewPort(3);
   SelectScale(3);
   Map(0, 0, xSc, ySc);
   Map(-1, 0, xSc2, ySc2);
   Radius := xSc - xSc2;
   SetColor(LightBlue);
   Ellipse(xSc-Radius, ySc, 0, 360, 3*Radius, 2*Radius);
   Map(4, 0, xSc2, ySc2);
   SetFillStyle(SolidFill, LightBlue);
   FillEllipse(xSc+XDisp(20), ySc, Radius, Radius);
   PlotLIne(-4.5, 0, 2.5, 0);
   PlotLine(-3.9, -0.25, -1.1, -0.25);
   PlotLine(-3.9, -0.25, -3.8, -0.15);
   PlotLine(-3.9, -0.25, -3.8, -0.35);
   PlotLine(-1.1, -0.25, -1.2, -0.15);
   PlotLine(-1.1, -0.25, -1.2, -0.35);
   PlotLine(-1, -0.1, -1, 1.9);
   PlotLine(-0.75, 0.1, -0.75, 1.8);
   PlotLine(-0.75, 0.1, -0.65, 0.2);
   PlotLine(-0.75, 0.1, -0.85, 0.2);
   PlotLine(-0.75, 1.8, -0.65, 1.7);
   PlotLine(-0.75, 1.8, -0.85, 1.7);
   PlotLine(-0.9, -1.2, 0.4, -1.2);
   PlotLine(-0.9, -1.2, -0.8, -1.3);
   PlotLine(-0.9, -1.2, -0.8, -1.1);
   PlotLine(0.4, -1.2, 0.3, -1.3);
   PlotLine(0.4, -1.2, 0.3, -1.1);
   SetFillStyle(SolidFill, White);
   FillEllipse(xSc+XDisp(20), ySc, XDisp(5), XDisp(5));
   SetColor(White);
   OutTextxy(xSc, ySc+YDisp(15), 'Focus');
   SetColor(LightGray);
   PlotLine(2, 2, 2, 3);
   PlotLine(2, 2, 1.8, 2.2);
   PlotLine(2, 2, 2.2, 2.2);
   Map(1.5, 3.5, xSc2, ySc2);
   OutTextxy(xSc2, ySc2, 'PeriCenter');
   PlotLine(-4, 2, -4, 3);
   PlotLine(-4, 2, -4.2, 2.2);
   PlotLine(-4, 2, -3.8, 2.2);
   Map(-4.5, 3.5, xSc2, ySc2);
   OutTextxy(xSc2+5, ySc2, 'ApoCenter');
   SetColor(Yellow);
   OutTextxy(xSc, ySc-YDisp(20), 'Earth');
   PlotLine(2.5, 0.5, 1.5, -0.5);
   PlotSymbol(2.5, 0.5, 'o');
   PlotSymbol(1.5, -0.5, 'o');
   Map(2, 0, xSc, ySc);
   Arc(xSc, ySc, 0, 45, Trunc(Radius/2));
   OutTextxy(xSc+XDisp(25), ySc-YDisp(15), 'Theta');
   Arc(xSc, ySc, 30, 110, Radius);
   PlotLine(2, 0.95, 2.2, 1.15);
   PlotLine(2, 0.95, 2.2, 0.75);
   OutTextxy(xSc-XDisp(10), ySc-YDisp(80), 'ThetaPrime');
   Map(-1, 0, xSc, ySc);
   OutTextxy(xSc, ySc+YDisp(10), 'C');
   OutTextxy(xSc-XDisp(45), ySc-YDisp(65), 'Semi-');
   OutTextxy(xSc-XDisp(45), ySc-YDisp(55), 'minor  b');
   OutTextxy(xSc-XDisp(45), ySc-YDisp(45), 'axis');
   OutTextxy(xSc-XDisp(130), ySc+YDisp(30), 'Semimajor axis');
   OutTextxy(xSc-XDisp(130), ySc+YDisp(10), '      a      ');
   OutTextxy(xSc+XDisp(30), ySc+YDisp(60), 'ae');
   Map(-2, -3, xSc, ySc);
   OutTextxy(xSc, ySc, 'b = a*Sqrt(1 - e^2)');
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
VAR
   Radius: Real;
   Radius3: Real;
BEGIN
   Radius := (1 - Ecc*Ecc)/(1 + Ecc*Cos(y[3]));
   Radius3 := Radius*Radius*Radius;
   z[1] := y[2];
   z[2] := - NonSphere*(1.5)*sin(2*y[1] - 2*y[3])/(Radius3);
   z[3] := Sqrt(1 - Ecc*Ecc)/(Radius*Radius);
   z[2] := z[2] - TidalFriction*(z[1] - z[3]);
END;

{------------------------------------------------------------------------}

PROCEDURE Step(xin, hin, tol: real; yin: Vector;
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
      temax := tol/10;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotDumbBell(xCenter, yCenter, Angle: Real; PlotColor: Word);
CONST
   Length = 0.05;
VAR
   x1, y1, x2, y2: Real;
   SaveColor: Word;
BEGIN
   SaveColor := GetColor;
   SetColor(PlotColor);
   x1 := Length*Cos(Angle);
   y1 := Length*Sin(Angle);
   x2 := xCenter - x1;
   y2 := yCenter - y1;
   x1 := xCenter + x1;
   y1 := yCenter + y1;
   PlotLine(x1, y1, x2, y2);
   IF PlotColor <> Black THEN SetColor(LightBlue);
   PlotSymbol(x1, y1, 'o');
   IF PlotColor <> Black THEN SetColor(LightRed);
   PlotSymbol(x2, y2, 'o');
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpOrbit;
BEGIN
   Animate := True;
   PhasePlot := False;
   Poincare := False;
   LightMenu := False;
   Lag := 20;
   GraphBackColor := Black;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   SetUpHotKeys;
   PlotSymbol(0, 0, 'O');
   xOld := (1 - Ecc);
   yOld := 0;
   Action := True;
   Pause := False;
   Time := 0;
   h := 0.1;
   OldAngle := y[1];
   PlotDumbBell(xOld, yOld, OldAngle, Yellow);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveOrbit;
VAR
   Radius: Real;
BEGIN
   Delay(Lag);
   IF h > 0.2 THEN h := 0.2;
   Step(Time, h, 0.0000001, y, Time, h, y);
   Radius := (1 - Ecc*Ecc)/(1 + Ecc*Cos(y[3]));
   xNew := Radius*Cos(y[3]);
   yNew := Radius*Sin(y[3]);
   NewAngle := y[1];
   PlotDumbBell(xOld, yOld, OldAngle, Black);
   PlotDumbBell(xNew, yNew, NewAngle, Yellow);
   xOld := xNew; yOld := yNew; OldAngle := NewAngle;
END;

{------------------------------------------------------------------------}

PROCEDURE EllipticOrbitDemo;

VAR
   DemHotKeys                     : THotKeys;
   Key                            : Byte;
   Pause, Action                  : Boolean;
   ChangeEccentricity             : Boolean;
   EccChanged                     : Boolean;
   Ecc                            : Real;
   Sliders                        : TSliders;
   xOrbit, yOrbit                 : Array[0..40] OF Real;
   MeanAnom                       : Real;
   OrbitNumber                    : Integer;

{----------------------------------------------------------------------}

PROCEDURE SetUpDemHotKeys;
BEGIN
   WITH DemHotKeys DO
   BEGIN
      DemHotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Pick E';
      Key[3] := 'F3-Faster';
      Key[4] := 'F4-Slower';
      Key[5] := 'F5-Animate';
      Key[6] := 'F10-Quit';
   END;
   DemHotKeys.BackColor := Blue;
   DemHotKeys.HotKeyColor := Yellow;
   DemHotKeys.Display;
END;

{-----------------------------------------------------------------------}

PROCEDURE FindCoordinates(MeanAnom, Ecc: Real; VAR xEll, yEll: Real);
VAR
   EccAnom: Real;
   SinE, CosE, F, FP, FPP, FPPP: Real;
   DE: Real;
BEGIN
   IF MeanAnom > Pi THEN
   BEGIN
     { MeanAnom := - 2*Pi + MeanAnom;}
      EccAnom := MeanAnom - 0.8*Ecc;
   END
   ELSE EccAnom := MeanAnom + 0.8*Ecc;
   REPEAT
      SinE := Sin(EccAnom);
      CosE := Cos(EccAnom);
      F := EccAnom - Ecc*SinE - MeanAnom;
      FP := 1 - Ecc*CosE;
      FPP := Ecc*SinE;
      FPPP := Ecc*CosE;
      DE := - F/FP;
      DE := - F/(FP + DE*FPP/2);
      DE := - F/(FP + DE*FPP/2 + DE*DE*FPPP/6);
      EccAnom := EccAnom + DE;
   UNTIL Abs(DE) < 0.0001;
   xEll := CosE - Ecc;
   yEll := Sqrt(1 - Ecc*Ecc)*SinE;
END;

{------------------------------------------------------------------------}

PROCEDURE FillPositionArray;
VAR
   DelMeanAnom: Real;
   i: Integer;
BEGIN
   DelMeanAnom := 2*Pi/40;
   MeanAnom := 0;
   xOrbit[0] := 1 - Ecc;
   yOrbit[0] := 0;
   FOR i := 1 TO 40 DO
   BEGIN
      FindCoordinates(MeanAnom, Ecc, xOrbit[i], yOrbit[i]);
     { PlotLine(xOrbit[i-1], yOrbit[i-1], xOrbit[i], yOrbit[i]);}
      MeanAnom := MeanAnom + DelMeanAnom;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE DrawOrbit;
VAR
   i: Integer;
   Theta: Real;
   xOld, yOld, xNew, yNew: Real;
   xSc, ySc: Integer;
BEGIN
   OpenViewPort(5);
   DefineScale(5, -0.5-(1 + Ecc), 0.5+(1 - Ecc),
          -(5/7)*1.5, (5/7)*1.5);
   SelectScale(5);
   SetColor(Yellow);
   PlotSymbol(0, 0, '*');
   SetColor(LightGreen);
   xOld := 1 - Ecc;
   yOld := 0;
   Theta := 0;
   REPEAT
      Theta := Theta + Pi/30;
      xNew := Cos(Theta) - Ecc;
      yNew := Sin(Theta)*Sqrt(1 - Ecc*Ecc);
      PlotLine(xOld, yOld, xNew, yNew);
      xOld := xNew; yOld := yNew;
   UNTIL Theta > 2*Pi;
END;

{----------------------------------------------------------------------}

PROCEDURE SetUpAnimation;
BEGIN
   IF EccChanged THEN
   BEGIN
      FillPositionArray;
      OrbitNumber := 0;
   END;
   EccChanged := False;
   SetColor(Yellow);
   PlotSymbol(0, 0, '*');
   PlotSymbol(xOrbit[OrbitNumber], yOrbit[OrbitNumber], 'O');
   Pause := False;
END;

{----------------------------------------------------------------------}

PROCEDURE MoveOrbit;
BEGIN
   SetColor(GraphBackColor);
   Delay(Lag);
   PlotSymbol(xOrbit[OrbitNumber], yOrbit[OrbitNumber], 'O');
   OrbitNumber := OrbitNumber + 1;
   IF OrbitNumber > 40 THEN OrbitNumber := OrbitNumber - 40;
   SetColor(Yellow);
   PlotSymbol(xOrbit[OrbitNumber], yOrbit[OrbitNumber], 'O');
END;

{-----------------------------------------------------------------------}

PROCEDURE HandleDemHotKeys(Key: Byte);
VAR
   DelLag         : Integer;
BEGIN
   DelLag := 10;
      CASE Key OF
         1: ShowHelp('HelpPend.hlp', 'DBellEccentricityDemoHelp');
         2: BEGIN
               IF NOT Pause THEN
               BEGIN
                  Pause := True;
                  WITH DemHotKeys DO Key[5] := 'F5-Animate';
                  DemHotKeys.BackColor := Blue;
                  DemHotKeys.Display;
               END;
               ChangeEccentricity := True;
            END;
         3: IF Lag > DelLAg THEN LAg := Lag - DelLAg ELSE Lag := 0;
         4: Lag := Lag + DelLAg;
         5: BEGIN
            Action := True;
            IF Pause = True THEN
            BEGIN
               Pause := False;
               WITH DemHotKeys DO Key[5] := 'F5-Stop';
               DemHotKeys.BackColor := Red;
               DemHotKeys.Display;
               SetUpAnimation;
            END
            ELSE
            BEGIN
               Pause := True;
               WITH DemHotKeys DO Key[5] := 'F5-Animate';
               DemHotKeys.BackColor := Blue;
               DemHotKeys.Display;
            END;
         END;
      6: BEGIN
               Action := False;
               Pause := True;
               DemHotKeys.Clear;
               ClearMuppetPort;
               LightMenu := True;
         END;
   END;
END;

PROCEDURE HandleSliders;
BEGIN
   Ecc := Sliders.Value(1);
   EccChanged := True;
   DrawOrbit;
   Pause := True;
   WITH DemHotKeys DO Key[5] := 'F5-Animate';
   DemHotKeys.BackColor := Blue;
   DemHotKeys.Display;
END;


BEGIN
   LightMenu := False;
   Sliders.Init;
   Lag := 200;
   DefineViewPort(5, 0.1, 1, 0.05, 0.95);
   GraphBackColor := Blue;
   SetColor(Yellow);
   OpenViewPort(5);
   SelectScale(5);
   Ecc:= 0.5;
   FillPositionArray;
   OrbitNumber := 0;
   Sliders.Create(1, 0, 0.95, Ecc, 0.05, 0.2, 0.8, 2, '0', '.95', 'E', True);
   Sliders.DrawAll;
   SetUpDemHotKeys;
   Action := True;
   Pause := True;
   DrawOrbit;
   ChangeEccentricity := True;
   REPEAT
      CheckForEvents;
      IF DemHotkeys.Pressed(Key) THEN
            HandleDemHotKeys(Key);
      IF ChangeEccentricity and Sliders.Changed THEN HandleSliders;

      IF Action AND (NOT Pause) THEN MoveOrbit;
      {IF NOT Pause THEN AnimateOrbit;}
   UNTIL NOT Action;
   Sliders.Done;
END;

{-------------------------------------------------------------------------}

PROCEDURE QueryAnimation;
CONST
   RBNames : string = '12345678';
VAR
   Input               : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Do you want to see the animation?');
      LoadLine('  It may be more fun, but it slows ');
      LoadLine('  the mapping.');
      LoadLine('         Yes #1          No #1');
      LoadLine('');
      LoadLine('             [  OK  ]');
      IF SeeDumbbell THEN SetRadioButton(RBNames[1], 1)
                     ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN SeeDumbbell := True
                                        ELSE SeeDumbbell := False;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPhasePlot;
BEGIN
   ClearMuppetPort;
   DefineScale(4, -0.1, 0.1, -0.6, 0.3);
   IF Poincare THEN QueryAnimation;
   HideCursor;
   IF Poincare THEN GraphBackColor := Black ELSE GraphBackColor := DarkGray;
   Message('');
   IF NOT Poincare THEN SeeDumbbell := True;
   IF SeeDumbbell THEN
   BEGIN
      OpenViewPort(2);
      GraphBackColor := Black;
      OpenViewPort(4);
      GraphBackColor := DarkGray;
      SelectScale(4);
      SetColor(White);
      PlotLine(0, -0.1, 0, -0.4);
      PlotLine(0, -0.4, -0.02, -0.38);
      PlotLine(0, -0.4, 0.02, -0.38);
      OutTextXY(MapX(-0.035), MapY(-0.45), 'Earth');
      SelectViewPort(2);
   END
   ELSE OpenViewPort(1);
   DefineScale(2, PxLow, PxHigh, PyLow, PyHigh);
   SelectScale(2);
   SetUpPHotKeys;
   SetColor(White);
   Axis(0, 0, 50, 100);
   OutTextXY(MapX(PxHigh)-XDisp(30), MapY(0)+YDisp(10), 'Phi');
   OutTextXY(MapX(0)+XDisp(10), MapY(PyHigh)+YDisp(10), 'PhiDot');
   ShowCursor;
   LightMenu := False;
END;

{-----------------------------------------------------------------------}

PROCEDURE MovePhasePlot;
VAR
   Radius    : Real;
BEGIN
   IF Poincare AND (NOT SeeDumbbell) THEN SelectViewPort(1);
   Delay(Lag);
   OldAngle := y[1] - y[3] + Pi/2;
   Step(Time, h, 0.0000001, y, Time, h, y);
   xNew := (y[1] - y[3])*180/Pi - DelPhi;
   Radius := (1 - Ecc*Ecc)/(1 + Ecc*Cos(y[3]));
   yNew := y[2] - Sqrt(1 - Ecc*Ecc)/(Radius*Radius);
   yNew := yNew*180/Pi;
   IF (xNew < 180) AND (xNew > -180) THEN
   BEGIN
      SetColor(GraphBackColor); PlotSymbol(xOld, yOld, 'o');
      SetColor(Yellow);
      PlotSymbol(xNew, yNew, 'o');
      PlotLine(xOld1, yOld1, xOld, yOld);
      PlotLine(xOld, yOld, xNew, yNew);
      xOld1 := xOld;
      yOld1 := yOld;
   END
   ELSE
   BEGIN
      IF xNew > 180 THEN
         BEGIN
            xNew := xNew - 360;
            DelPhi := DelPhi + 360;
         END;
      IF xNew < - 180 THEN
         BEGIN
            xNew := xNew + 360;
            DelPhi := DelPhi - 360;
         END;
      SetColor(GraphBackColor);
      xOld1 := xNew;
      yOld1 := yNew;
      PlotSymbol(xOld, yOld, 'o');
   END;
   NewAngle := y[1] - y[3] + Pi/2;
      IF SeeDumbbell THEN
      BEGIN
         SelectViewPort(4);
         SelectScale(4);
         PlotDumbbell(0, 0, OldAngle, Black);
         PlotDumbbell(0, 0, NewAngle, Yellow);
         SelectViewPort(2);
         SelectScale(2);
      END;
   xOld := xNew;
   yOld := yNew;
END;

{-----------------------------------------------------------------------}

PROCEDURE FindNextPoincarePoint;
VAR
   Radius    : Real;
   NextTime  : Real;
   SaveStepSize : Real;
BEGIN
   IF SeeDumbbell THEN SelectViewPort(2) ELSE SelectViewPort(1);
   NextTime := Time + 2*Pi;
   REPEAT
      OldAngle := y[1] - y[3] + Pi/2;
      Step(Time, h, 0.0000001, y, Time, h, y);
      IF SeeDumbbell THEN
      BEGIN
         Delay(10);
         SelectViewPort(4);
         SelectScale(4);
         NewAngle := y[1] - y[3] + Pi/2;
         PlotDumbbell(0, 0, OldAngle, Black);
         PlotDumbbell(0, 0, NewAngle, Yellow);
         SelectViewPort(2);
         SelectScale(2);
      END;
   UNTIL Time > NextTime;
   SaveStepSize := h;
   h := NextTime - Time;
   OldAngle := y[1] - y[3] + Pi/2;
      Step(Time, h, 0.00001, y, Time, h, y);
      IF SeeDumbbell THEN
      BEGIN
         SelectViewPort(4);
         SelectScale(4);
         PlotDumbbell(0, 0, OldAngle, Black);
         NewAngle := y[1] - y[3] + Pi/2;
         PlotDumbbell(0, 0, NewAngle, Yellow);
         SelectViewPort(2);
         SelectScale(2);
      END;
   {ELSE Step(Time, h, 0.00001, y, Time, h, y); }
   h := SaveStepSize;
   xNew := (y[1] - y[3])*180/Pi - DelPhi;
   Radius := (1 - Ecc*Ecc)/(1 + Ecc*Cos(y[3]));
   yNew := y[2] - Sqrt(1 - Ecc*Ecc)/(Radius*Radius);
   yNew := yNew*180/Pi;
   IF (xNew < 180) AND (xNew > -180) THEN
   BEGIN
      SetColor(PoincareColor);
      PlotSymbol(xNew, yNew, '.');
   END
   ELSE
   BEGIN
      IF xNew > 180 THEN
         BEGIN
            REPEAT
               xNew := xNew - 360;
               DelPhi := DelPhi + 360;
            UNTIL xNew < 180;
         END;
      IF xNew < - 180 THEN
         BEGIN
            REPEAT
               xNew := xNew + 360;
               DelPhi := DelPhi - 360;
            UNTIL xNew > - 180;
         END;
      SetColor(PoincareColor);
      PlotSymbol(xNew, yNew, '.');
   END;
   xOld := xNew; yOld := yNew;
END;

{-----------------------------------------------------------------------}

PROCEDURE SelectStart;
VAR
   Inside                       : Boolean;
   SavePhi, SavePhiDot          : Integer;
   a                            : Integer;
   Input                        : TInputScreen;
BEGIN
   IF SeeDumbbell THEN
   BEGIN
      SelectViewPort(4);
      SelectScale(4);
      PlotDumbbell(0, 0, y[1] - y[3] + Pi/2, Black);
      SelectViewPort(2);
      SelectScale(2);
   END;
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.3, 0.7, 0.85, 0.95);
      LoadLine('  Use mouse #1 or keyboard #1?');
      LoadLine('          [  OK  ]');
      IF MouseInput THEN SetRadioButton('1', 1)
                    ELSE SetRadioButton('1', 2);
      AcceptScreen;
      IF GetRadioButton('1') = 1 THEN MouseInput := True
                                 ELSE MouseInput := False;
      Done;
   END;
   IF MouseInput THEN
   BEGIN
      SetColor(White);
      Delay(500);
      Inside := False;
      SavePhi := 0;
      SavePhiDot := 0;
      PrintXY(0.53, 0.982, 'Phi = '+NumStr(Phi, 4, 1)+', PhiDot = '
                                +NumStr(PhiDot, 4, 1));
      REPEAT
         Message('Click on a starting point in the window');
         REPEAT
            IF SeeDumbbell THEN
               MousePosn(Phi, PhiDot, 2, 2, Inside)
               ELSE
               MousePosn(Phi, PhiDot, 1, 2, Inside);
            IF NOT Inside THEN
            BEGIN
               RubOutXY(0.53, 0.982, 35, Blue);
               Beep;
            END;
            IF Abs(MapX(Phi) - SavePhi) + Abs(MapY(PhiDot) - SavePhiDot) > 5
            THEN
            BEGIN
               RubOutXY(0.53, 0.982, 35, Blue);
               PrintXY(0.53, 0.982, 'Phi = '+NumStr(Phi, 4, 1)+', PhiDot = '
                                +NumStr(PhiDot, 4, 1));
               SavePhi := MapX(Phi);
               SavePhiDot := MapY(PhiDot);
            END;
         UNTIL MouseClicked(a, a) AND Inside;
         Message('');
         IF Inside THEN
         BEGIN
            y[1] := Phi*Pi/180;
            y[2] := PhiDot*Pi/180 + Sqrt((1+Ecc)/((1-Ecc)*(1-Ecc)*(1-Ecc)));
            y[3] := 0;
            Action := True;
            Pause := True;
            xOld := Phi;
            yOld := PhiDot;
            xOld1 := xOld;
            yOld1 := yOld;
            DelPhi := 0;
            Time := 0;
            h := 1;
            IF Poincare THEN
            BEGIN
               PoincareColor := PoincareColor + 1;
               IF PoincareColor = 4 THEN PoincareColor := 5;
               IF PoincareColor = 16 THEN PoincareColor := 1;
               SetColor(PoincareColor);
            END
            ELSE SetColor(Yellow);
            IF Poincare THEN PlotSymbol(Phi, PhiDot, '.')
                        ELSE PlotSymbol(Phi, PhiDot, 'o');
         END
         ELSE
         BEGIN
            Message('You clicked outside the window. Please try again');
            Beep;
            Delay(2000);
            Message('');
         END;
      UNTIL Inside;
   END
   ELSE
   BEGIN
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.2, 0.8, 0.35, 0.65);
         LoadLine('');
         LoadLine('    Enter coordinates of the starting point:');
         LoadLine('    '+NumStr(PxLow, 5, 0)+' < x = {       } < '
                        +NumStr(PxHigh, 5, 0));
         LoadLine('    '+NumStr(PyLow, 5, 0)+' < y = {       } < '
                        +NumStr(PyHigh, 5, 0));
         LoadLine('');
         LoadLine('                [  OK  ]');
         SetNumberLimits(1, PxLow, PxHigh);
         SetNumberLimits(2, PyLow, PyHigh);
         SetNumber(1, Phi);
         SetNumber(2, PhiDot);
         AcceptScreen;
         Phi := GetNumber(1);
         PhiDot := GetNumber(2);
         Done;
      END;
      y[1] := Phi*Pi/180;
      y[2] := PhiDot*Pi/180 + Sqrt((1+Ecc)/((1-Ecc)*(1-Ecc)*(1-Ecc)));
      y[3] := 0;
      Action := True;
      Pause := True;
      xOld := Phi;
      yOld := PhiDot;
      xOld1 := xOld;
      yOld1 := yOld;
      DelPhi := 0;
      Time := 0;
      h := 1;
      IF Poincare THEN
      BEGIN
         PoincareColor := PoincareColor + 1;
         IF PoincareColor = 4 THEN PoincareColor := 5;
         IF PoincareColor = 16 THEN PoincareColor := 1;
         SetColor(PoincareColor);
      END
      ELSE SetColor(Yellow);
      IF Poincare THEN PlotSymbol(Phi, PhiDot, '.')
                  ELSE PlotSymbol(Phi, PhiDot, 'o');
   END;
   StartOK := True;
END;

{------------------------------------------------------------------------}

PROCEDURE ChangeRotationRatio;
VAR
   Input       : TInputScreen;
   fNum, fDenom : Real;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.15, 0.85);
      LoadLine('');
      LoadLine('     Suppose the satellite revolves P times');
      LoadLine('  around the planet, while rotating Q times.');
      LoadLine('  If, in inertial space, the rotation is ');
      LoadLine('  specified by Theta and the revolution by V,');
      LoadLine('  then the angle ');
      LoadLine('               Theta - (Q/P)V');
      LoadLine('  will oscillate. This is the angle that will');
      LoadLine('  be plotted.');
      LoadLine('     For synchronous motion, P = 1, Q = 1.');
      LoadLine('     For Mercury, P = 2, Q = 3.');
      LoadLine('     Enter integer values for P and Q ');
      LoadLine('  between 1 and 10:');
      LoadLine('             P = {   }   Q = {   }');
      LoadLine('');
      LoadLine('                  [  OK  ]');
      SetNumber(1, Num);
      SetNumberLimits(1, 1, 10);
      SetNumber(2, Denom);
      SetNumberLimits(2, 1, 10);
      AcceptScreen;
      Num := Trunc(GetNumber(1) + 0.0001);
      Denom := Trunc(GetNumber(2) + 0.0001);
      fNum := Num;
      fDenom := Denom;
      RotationRatio := fDenom/fNum;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Rescale;
VAR
   Input        : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.35, 0.7);
      LoadLine('');
      LoadLine('     Enter limiting values for the display:');
      LoadLine(' Horizontal:');
      LoadLine('     Lower: {       }    Upper: {       }');
      LoadLine(' Vertical:');
      LoadLine('     Lower: {       }    Upper: {       }');
      LoadLine('');
      LoadLine('                [  OK  ]');
      SetNumber(1, PxLow);
      SetNumber(2, PxHigh);
      SetNumber(3, PyLow);
      SetNumber(4, PyHigh);
      REPEAT
         AcceptScreen;
         PxLow := GetNumber(1);
         PxHigh := GetNumber(2);
         PyLow := GetNumber(3);
         PyHigh := GetNumber(4);
         IF (PxLow >= PxHigh) OR (PyLow >= PyHigh) THEN
            Announce('You have confused upper and lower values. Try again');
      UNTIL (PxLow < PxHigh) and (PyLow < PyHigh);
      DefineScale(1, PxLow, PxHigh, PyLow, PyHigh);
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindNewEcc;
VAR
   Input      : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.27, 0.73, 0.37, 0.63);
      LoadLine('');
      LoadLine('     Enter a new eccentricity:');
      LoadLine('    0 <= e = {       } <= 0.9');
      LoadLine('');
      LoadLine('             [  OK  ]');
      SetNumber(1, Ecc);
      SetNumberLimits(1, 0, 0.9);
      AcceptScreen;
      Ecc := GetNumber(1);
      Done;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION SelectPlotScale : Boolean;
VAR
   ScaleInput    : TInputScreen;
   Quit          : Boolean;
BEGIN
   REPEAT
      WITH ScaleInput DO
      BEGIN
         Init;
         DefineInputPort(0.22, 0.78, 0.2, 0.8);
         LoadLine('');
         LoadLine('  Enter extreme values for the plot:');
         LoadLine('  Minimum   t = 0,');
         LoadLine('  Maximum   t: {      } <= 1000,');
         LoadLine('  Minimum Phi: {      } >= -2000, <= 0,');
         LoadLine('  Maximum Phi: {      } <= 2000, >= 0.');
         LoadLine('');
         LoadLine('  Enter the eccentricity:');
         LoadLine('      0 <= e = {      } <= 0.9');
         LoadLine('  Enter initial values, using degrees:');
         LoadLine('  Phi = {      }, PhiDot = {      }.');
         LoadLine('');
         LoadLine('         [  OK  ]    [Cancel]');
         SetNumber(1, xHigh);
         SetNumberLimits(1, 0, 1000);
         SetNumber(2, yLow);
         SetNumberLimits(2, -2000, 0);
         SetNumber(3, yHigh);
         SetNumberLimits(3, 0, 2000);
         SetNumber(4, Ecc);
         SetNumberLimits(4, 0, 0.9);
         SetNumber(5, Phi);
         SetNumberLimits(5, -180, 180);
         SetNumber(6, PhiDot);
         AcceptScreen;
         SelectPlotScale := NOT Canceled;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            Quit := False;
            xLow := 0;
            xHigh := GetNumber(1);
            yLow := GetNumber(2);
            yHigh := GetNumber(3);
            Ecc := GetNumber(4);
            Phi := GetNumber(5);
            PhiDot := GetNumber(6);
         END;
         Done;
      END;
      IF (xHigh <= xLow) OR (yHIgh <= yLow) AND (NOT Quit) THEN
         Announce('Extreme coordinates out of order. Try again.');
   UNTIL (xHigh > xLow) AND (yHigh > yLow) OR Quit;
END;

{-------------------------------------------------------------------------}

FUNCTION SelectSinePlotScale : Boolean;
VAR
   ScaleInput    : TInputScreen;
   Quit          : Boolean;
BEGIN
      WITH ScaleInput DO
      BEGIN
         Init;
         DefineInputPort(0.22, 0.78, 0.23, 0.77);
         LoadLine('');
         LoadLine('  Enter extreme values for the plot:');
         LoadLine('  Minimum   t = 0,');
         LoadLine('  Maximum   t: {      } <= 1000,');
         LoadLine('');
         LoadLine('  Enter the eccentricity:');
         LoadLine('      0 <= e = {      } <= 0.9');
         LoadLine('  Enter initial values, using degrees:');
         LoadLine('  Phi = {      }, PhiDot = {      }.');
         LoadLine('');
         LoadLine('         [  OK  ]    [Cancel]');
         SetNumber(1, xHigh);
         SetNumberLimits(1, 0, 1000);
         SetNumber(2, Ecc);
         SetNumberLimits(2, 0, 0.9);
         SetNumber(3, Phi);
         SetNumberLimits(3, -180, 180);
         SetNumber(4, PhiDot);
         AcceptScreen;
         SelectSinePlotScale := NOT Canceled;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            Quit := False;
            xLow := 0;
            xHigh := GetNumber(1);
            Ecc := GetNumber(2);
            Phi := GetNumber(3);
            PhiDot := GetNumber(4);
         END;
         Done;
      END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolHotKeys;
BEGIN
   WITH SolHotKeys DO
   BEGIN
      SolHotKeys.Init(4);
      Key[1] := 'F2-NewStart';
      Key[2] := 'F3-CleanUp';
      Key[3] := 'F4-Rescale';
      Key[4] := 'F10-Menu';
   END;
   SolHotKeys.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE XTickMarks(YM, XL, XH, YL, YH: Real);
VAR
   Length     : Real;
   Period     : Real;
   I          : Integer;
BEGIN
   Period := 2*Pi;
   Length := (YH - YL)/100;
   FOR I := 1 TO Trunc((XH - XL)/Period) DO
      PlotLine(I*Period, YM-Length, I*Period, YM+Length);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotSolution;
VAR
   DelX, DelY   : Real;
   YZero        : Real;
   xOld, yOld   : Real;
BEGIN
   ChangeRotationRatio;
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   HideMouse;
   LightMenu := False;
   GraphBackColor := DarkGray;
   SetColor(White);
   ClearMuppetPort;
   OpenViewPort(1);
   SetUpSolHotKeys;
   SolutionPlot := True;
   IF PlotSine THEN
      DefineScale(4, xLow-DelX, xHigh+DelX, -1.2, 1.2)
      ELSE
      DefineScale(4, xLow-DelX, xHigh+DelX, yLow-DelY, yHigh+DelY);
   SelectScale(4);
   IF PlotSine THEN
      BEGIN
         Axis(0, 0, 10000, 1);
         PutLabel(Top, 'Time axis marked at intervals of the orbital period');
         PutLabel(Left, 'Sin(Phi)');
         PlotLIne(0, -1.2, 0, 1.2);
         XTickMarks(0, xLow, xHigh, -1, 1);
      END
      ELSE
      BEGIN
         Axis(-10, 0, 100000, 360);
         PutLabel(Top, 'Time axis marked at intervals of the orbital period');
         PutLabel(Left, 'Phi');
      END;
   PlotLine(xLow, 0, xHigh, 0);
   IF NOT PlotSine THEN
   BEGIN
      XTickMarks(0, xLow, xHigh, yLow, yHigh);
      PlotLIne(xLow, yLow, xLow, yHigh);
      DelY := 360;
      YZero := 0;
      REPEAT
         YZero := yZero + DelY;
         IF YZero < YHigh THEN
         BEGIN
            PlotLine(xLow, YZero, xHigh, YZero);
            XTickMarks(YZero, xLow, xHigh, yLow, yHigh);
         END;
      UNTIL YZero > yHigh;
   YZero := 0;
      REPEAT
         YZero := yZero - DelY;
         IF YZero > YLow THEN
         BEGIN
            PlotLine(xLow, YZero, xHigh, YZero);
            XTickMarks(YZero, xLow, xHigh, yLow, yHigh);
         END;
      UNTIL YZero < yLow;
   END;
   y[1] := Phi*Pi/180;
   y[2] := PhiDot*Pi/180 + Sqrt((1+Ecc)/((1-Ecc)*(1-Ecc)*(1-Ecc)));
   y[3] := 0;
  { y[1] := Pi*Theta/180;
   y[2] := Pi*ThetaDot/180;
   y[3] := 0; }
   xOld := xLow;
   IF PlotSine THEN
      yOld := Sin(y[1] - RotationRatio*y[3])
      ELSE
      yOld := 180*(y[1] - RotationRatio*y[3])/Pi;
   Time := 0;
   h := 0.1;
   Message('        Hit a key to stop a plot');
   REPEAT
      Step(Time, h, 0.00000001, y, Time, h, y);
      IF PlotSine THEN
         PLotLine(xOld, yOld, Time, Sin(y[1]-RotationRatio*y[3]))
         ELSE
         PLotLine(xOld, yOld, Time, 180*(y[1]-RotationRatio*y[3])/Pi);
      xOld := Time;
      IF PlotSine THEN
         yOld := Sin(y[1] - RotationRatio*y[3])
         ELSE
         yOld := 180*(y[1] - RotationRatio*y[3])/Pi;
   UNTIL (Time > xHigh) OR KeyPressed;
   ClearMKBuffers;
   Message('');
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE RePlotSolution;
VAR
   xOld, yOld   : Real;
   InputInit    : TInputScreen;
BEGIN
   WITH InputInit DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.32, 0.68);
      LoadLine('');
      LoadLine('     Enter new conditions.');
      LoadLine('  0 <= Eccentricity = {       } <= 0.9');
      LoadLine('     Use degrees:');
      LoadLine('   Theta = {       },  ThetaDot = {       }');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, Ecc);
      SetNumberLimits(1, 0, 0.9);
      SetNumber(2, Theta);
      SetNumberLimits(2, -180, 180);
      SetNumber(3, ThetaDot);
      AcceptScreen;
      Ecc := GetNumber(1);
      Theta := GetNumber(2);
      ThetaDot := GetNumber(3);
      Done;
   END;
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   y[3] := 0;
   xOld := 0;
   IF PlotSine THEN
      yOld := Sin(y[1] - RotationRatio*y[3])
      ELSE
      yOld := 180*(y[1] - RotationRatio*y[3])/Pi;
   Time := xLow;
   h := 0.1;
   HideMouse;
   REPEAT
      Step(Time, h, 0.00000001, y, Time, h, y);
      IF PlotSine THEN
         PLotLine(xOld, yOld, Time, Sin(y[1]-RotationRatio*y[3]))
         ELSE
         PLotLine(xOld, yOld, Time, 180*(y[1]-RotationRatio*y[3])/Pi);
      xOld := Time;
      IF PlotSine THEN
         yOld := Sin(y[1] - RotationRatio*y[3])
         ELSE
         yOld := 180*(y[1] - RotationRatio*y[3])/Pi;
   UNTIL (Time > xHigh) OR KeyPressed;
   ShowMouse;
   ClearMKBuffers;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE ReDrawAxes;
VAR
   DelX, DelY   : Real;
   YZero        : Real;
BEGIN
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   HideMouse;
   GraphBackColor := DarkGray;
   SetColor(White);
   ClearMuppetPort;
   OpenViewPort(1);
   SolHotKeys.Display;
   IF PlotSine THEN
      DefineScale(4, xLow-DelX, xHigh+DelX, -1.2, 1.2)
      ELSE
      DefineScale(4, xLow-DelX, xHigh+DelX, yLow-DelY, yHigh+DelY);
   SelectScale(4);
   IF PlotSine THEN
      BEGIN
         Axis(0, 0, 10000, 1);
         PlotLIne(0, -1.2, 0, 1.2);
         XTickMarks(0, xLow, xHigh, -1, 1);
      END
      ELSE
      Axis(0, 0, 100000, 360);
   PlotLine(xLow, 0, xHigh, 0);
   IF NOT PlotSine THEN
      XTickMarks(0, xLow, xHigh, yLow, yHigh);
      PlotLIne(xLow, yLow, xLow, yHigh);
      DelY := 360;
      YZero := 0;
      REPEAT
         YZero := yZero + DelY;
         IF YZero < YHigh THEN
         BEGIN
            PlotLIne(xLow, YZero, xHigh, YZero);
            XTickMarks(YZero, xLow, xHigh, yLow, yHigh);
         END;
      UNTIL YZero > yHigh;
      YZero := 0;
      REPEAT
         YZero := yZero - DelY;
         IF YZero > YLow THEN
         BEGIN
            PlotLine(xLow, YZero, xHigh, YZero);
            XTickMarks(YZero, xLow, xHigh, yLow, yHigh);
         END;
      UNTIL YZero < yLow;
   ShowMouse;
   RePlotSolution;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleSolHotKeys(Key : Byte);
BEGIN
   CASE Key OF
   1: RePlotSolution;
   2: ReDrawAxes;
   3: IF PlotSine THEN
      BEGIN
         IF SelectSinePlotScale THEN PlotSolution;
      END
      ELSE
      BEGIN
         IF SelectPlotScale THEN PlotSolution;
      END;
   4: BEGIN
         SolutionPlot := False;
         SolHotKeys.Clear;
         LightMenu := True;
      END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Input;
BEGIN
   Message('');
   ShowParameters;
   IF GetDumbBellData THEN
   BEGIN
      GetNonSphereValue;
      SetUpOrbit;
   END
   ELSE
   BEGIN
      Lightmenu := True;
      ClearMuppetPort;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleDumbBellMenu;
BEGIN
   With DumbBellMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: ShowHelp('HelpPend.hlp', 'DBellAboutProgram');
            2: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpPend.hlp', 'DBellAboutModelA');
                  ShowHelp('HelpPend.hlp', 'DBellAboutModelB');
                  ShowHelp('HelpPend.hlp', 'DBellAboutModelC');
               END;
            2: ShowHelp('HelpPend.Hlp', 'DBellInputHelp');
            3: ShowHelp('HelpPend.Hlp', 'DBellPhasePlaneHelp');
            4: BEGIN
                  ShowHelp('HelpPend.hlp', 'DBellPoincareHelpA');
               END;
            5: EllipticOrbitDemo;
            6: BEGIN
                  ShowHelp('WalkThru.hlp', 'Dumbbell1');
                  ShowHelp('WalkThru.hlp', 'Dumbbell2');
                  ShowHelp('WalkThru.hlp', 'Dumbbell3');
                  ShowHelp('WalkThru.hlp', 'Dumbbell4');
                  ShowHelp('WalkThru.hlp', 'Dumbbell5');
               END;
         END;
      3: CASE RowChosen OF
            1: Input;
            2: BEGIN
                  SetUpOrbit;
                  Animate := True;
                  PhasePlot := False;
                  Poincare := False;
               END;
            3: BEGIN
                  SetUpPhasePlot;
                  Animate := False;
                  PhasePlot := True;
                  Poincare := False;
               END;
            4: BEGIN
                  Poincare := True;
                  SetUpPhasePlot;
                  Animate := False;
                  PhasePlot := False;
               END;
            5: BEGIN
                  Animate := False;
                  PhasePlot := False;
                  Poincare := False;
                  PlotSine := False;
                  IF SelectPlotScale THEN
                  PlotSolution;
               END;
            6: BEGIN
                  Animate := False;
                  PhasePlot := False;
                  Poincare := False;
                  PlotSine := True;
                  IF SelectSinePlotScale THEN
                  PlotSolution;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
CONST
   DelLag = 20;
BEGIN
      CASE Key OF
         1: BEGIN
            IF Pause = True THEN
            BEGIN
               Pause := False;
               WITH HotKeys DO Key[1] := 'F2-Pause';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := True;
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag;
      3: Lag := Lag + DelLag;
      4: BEGIN
               Action := False;
               Pause := False;
               HotKeys.Clear;
               ClearMuppetPort;
               LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePHotKeys(Key: Byte);
BEGIN
      CASE Key OF
           1: BEGIN
                 IF NOT StartOK THEN
                 BEGIN
                    Announce('Please use <F3-Input> to select a starting point');
                    Exit;
                 END;
                 IF Pause THEN
                 BEGIN
                    Pause := False;
                    WITH PHotKeys DO Key[1] := 'F2-Pause';
                    PHotKeys.BackColor := Blue;
                    PHotKeys.Display;
                 END
                 ELSE
                 BEGIN
                    Pause := True;
                    WITH PHotKeys DO Key[1] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
              END;
           2: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[1] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                    Pause := True;
                 END;
                 IF Action AND (NOT Poincare) THEN
                 BEGIN
                    SetColor(GraphBackColor);
                    PlotSymbol(xOld, yOld, 'o');
                 END;
                 Action := False;
                 SelectStart;
              END;
           {3: BEGIN
                 Rescale;
                 SetUpPhasePlot;
                 PlotOrbits := True;
              END; }
           3: BEGIN
                 Action := False;
                 ReScale;
                 SetUpPhasePlot;
                 PlotOrbits := True;
              END;
           4: BEGIN
                 Action := False;
                 FindNewEcc;
                 SetUpPhasePlot;
                 PlotOrbits := True;
              END;
           5: BEGIN
                 Action := False;
                 PlotOrbits := False;
                 HotKeys.Clear;
                 LightMenu := True;
              END;
      END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.1, 0.9, 0.1, 0.9);
   DefineViewPort(2, 0.25, 0.95, 0.1, 0.9);
   DefineViewPort(4, 0.0, 0.18, 0.1, 0.9);
   DefineScale(4, -0.1, 0.1, -0.6, 0.3);
   GraphBackColor := Black;
   Animate := False;
   PhasePlot := False;
   Poincare := False;
   MouseInput := True;
   SeeDumbbell := True;
   Lag := 200;
   Ecc := 0;
   Num := 1;
   Denom := 1;
   NonSphere := 1;
   RotationRatio := 1;
   Theta := 0;
   ThetaDot := (180/Pi);
   TidalFriction := 0;
   PxLow := -200;
   PxHigh := 200;
   PyLow := -200;
   PyHigh := 200;
   xLow := 0;
   xHigh := 200;
   yLow := -1000;
   yHigh := 1000;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   DefineScale(1, -0.5-(1 + Ecc), 0.5+(1 - Ecc),
                         -(5/7)*1.5, (5/7)*1.5);
   PoincareColor := 1;
   PlotSine := False;
   Hello('HelpPend.hlp', 'DBellAboutProgram');
   SetUpDumbBellMenu;
END;

{------------------------------------------------------------------------}

BEGIN {main program}
   CUPSInit;
   GetSetUp;
   Input;
   ExitRequest := False;
   REPEAT
      CheckForEvents;
      IF Animate AND Hotkeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF PhasePlot AND pHotKeys.Pressed(Key)
             THEN HandlePHotKeys(Key);
      IF Poincare AND pHotKeys.Pressed(Key)
             THEN HandlePHotKeys(Key);
      IF SolutionPlot AND SolHotKeys.Pressed(Key) THEN HandleSolHotKeys(Key);
      IF PhasePlot AND Action AND (NOT Pause) THEN MovePhasePlot;
      IF Animate AND Action and (NOT Pause) THEN MoveOrbit;
      IF Poincare AND Action AND (NOT Pause) THEN FindNextPoincarePoint;
      IF LightMenu And DumbBellMenu.Chosen THEN HandleDumbBellMenu;
   UNTIL ExitRequest;
   DumbBellMenu.Done;
   CUPSDone;
END.

