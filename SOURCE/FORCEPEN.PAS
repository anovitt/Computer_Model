Program TheMotionOfAForcedPendulum;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                   : Vector;
   PendMenu               : TMenu;
   HotKeys                : THotKeys;
   BHotKeys               : THotKeys;
   SolHotKeys             : THotKeys;
   Sliders                : TSliders;
   Drag, TimeRatio        : Real;
   Force                  : Real;
   ForceLow, ForceHigh    : Real;
   ForceCurrent           : Real;
   DeltaForce             : Real;
   Frequency              : Real;
   Length                 : Real;
   Lag                    : Integer;
   StoreAngle             : Real;
   Time, StepSize         : Real;
   Theta                  : Real;
   ThetaDot               : Real;
   Y2Sign                 : Real;
   xLow, xHigh, yLow, yHigh: Real;
   xDotLow, xDotHigh      : Real;
   xStart, xpStart        : Real;
   Period                 : Real;
   IPeriod                : Integer;
   TimeDelay              : Real;
   Action                 : Boolean;
   PLotOrbit              : Boolean;
   SolutionPlot           : Boolean;
   Phase                  : Boolean;
   LightMenu              : Boolean;
   ExitRequest            : Boolean;
   Poincare               : Boolean;
   Bifurcate              : Boolean;
   PlotX                  : Boolean;
   PlotSin                : Boolean;
   Input                  : Boolean;
   FindBasins             : Boolean;
   NXBasin, NYBasin       : Integer;
   XCount, YCount         : Integer;
   BasinColor             : Array[0..10] OF Word;
   Key                    : Byte;
   WaitMessage            : TWaitMessage;
   ThetaMin, ThetaMax        : Real;
   xMax, xMin, yMax, yMin : Real;
   NMax, NMin                : Integer;
   ThetaDotMin, ThetaDotMax  : Real;
   BifSamples, BifPoints     : Integer;
   RxDotLow, RxDotHigh       : Real;
   NRuns                     : Integer;
   xI                        : Array[1..3] OF Real;
   xScreenRatio, yScreenRatio : Real;

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
   envir.Reset;
END;

{---------------------------------------------------------------------------}

PROCEDURE SetUpPendMenu;
VAR
   I    : Integer;
BEGIN
   With PendMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Sensitivity');
       row(2,3, 'Phase-plane');
       row(2,4, 'Poincare maps');
       row(2,5, 'Bifurcation diagram');
       row(2,6, 'Numerical ideas');
       row(2,7, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Swing the pendulum');
       row(3,3, 'Plot x versus time');
       row(3,4, 'Plot Sin(x) versus time');
       row(3,5, 'Plot x-prime versus time');
      Column(4, 'PhasePlot');
       row(4,1, 'See phase-plane plot');
       row(4,2, 'See Poincare map');
       row(4,3, 'See bifurcation diagram');
       row(4,4, 'See basins of attraction');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   PendMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(3);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Input';
      Key[3] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   {HotKeys.Display;}
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpBHotKeys;
BEGIN
   WITH BHotKeys DO
   BEGIN
      BHotKeys.Init(1);
      Key[1] := 'F10-Menu';
   END;
END;
{-------------------------------------------------------------------------}

FUNCTION GetPendData :  Boolean;
CONST
   RBNames : string = '12345678';
VAR
   cd, CrossSection, Mass: Real;
   PendDat               : TInputScreen;
BEGIN
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.16, 0.9);
      LoadLine('');
      LoadLine('        Data for the Motion of a Forced Pendulum');
      LoadLine('');
      LoadLine('     x is the angle that the pendulum makes with the');
      LoadLIne('  downward vertical. The model is:');
      LoadLine('    d(dx/dt)/dt = - k(dx/dt) - Sin(x) + fCos(wt)');
      LoadLine('  k and f should be positive and less than 10.');
      LoadLine('  The frequency w should be positive and less than 10');
      LoadLine('');
      LoadLIne('   Enter a value for the parameter f: f = {       }');
      LoadLine('');
      LoadLine('   Enter a value for the parameter k: k = {       }');
      LoadLine('');
      LoadLine('   Enter a value for the parameter w: w = {       }');
      LoadLine('');
      LoadLIne('         [ Help ]       [  OK  ]       [Cancel]');
      SetHelpFile('HlpChaos.hlp', 'NumericalIdeasHelp');
      SetNumber(1, Force);
      SetNumberLimits(1, 0, 10);
      SetNumber(2, Drag);
      SetNumberLimits(2, 0, 10);
      SetNumber(3, Frequency);
      SetNumberLimits(3, 0, 10);
      AcceptScreen;
      GetPendData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Force := GetNumber(1);
         Drag := GetNumber(2);
         Frequency := GetNumber(3);
         Period := 2*Pi/Frequency;
         y[2] := 30;                {Default values.}
         y[1] := 50;
         y[1] := y[1]*Pi/180;
         y[2] := y[2]*Pi/180;
         StoreAngle := 0;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
begin
   z[1] := y[2];
   z[2] := - Drag*y[2] - Sin(y[1]) + Force*Cos(Frequency*x)
end;

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
      temax := tol/10;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol;
   yout := y;
   xout := xtemp + htemp;
   hout := h;
end;

{-----------------------------------------------------------------------}

PROCEDURE FindTopOfSwing;
VAR
   SaveStepSize : Real;
   Count : Integer;
   Z : Vector;
BEGIN
   Count := 0;
   SaveStepSize := StepSize;
   REPEAT
      Count := Count + 1;
      Fun(Time, Y, Z);
      IF Abs(Z[2]) > 0.001 THEN
      BEGIN
         StepSize:= - Y[2]/Z[2];
         Step(Time, StepSize, 0.001, Y, Time, StepSize, Y);
      END;
   UNTIL (ABS(Y[2]) < 0.0001) OR (COUNT = 10) OR (Z[2] = 0);
   Y2Sign := - Y2Sign;
  StepSize:= SaveStepSize;
END;


{-------------------------------------------------------------------------}

PROCEDURE PlotPend(Angle: Real; SColor: Word);
VAR
   Radius: Integer;
   xSc, ySc: Integer;
   xEnd, yEnd: Real;
BEGIN
   Radius := 10;
   SetColor(SColor);
   xEnd := Sin(Angle);
   yEnd := - Cos(Angle);
   PlotLine(0, 0, xEnd, yEnd);
   Map(1.1*xEnd, 1.1*yEnd, xSc, ySc);
   Circle(xSc, ySc, Radius);
END;

{-------------------------------------------------------------------------}

PROCEDURE PrintTime(Time: Real);
VAR
   Seconds, Minutes, Hours: LongInt;
   TimeStr, MinStr, HourStr: String;
   xSc, ySc: Integer;
BEGIN
   Seconds := Trunc(Time);{*TimeRatio); }
   Minutes := Trunc(Seconds/60);
   IF Minutes >= 1 THEN Seconds := Seconds - 60*Minutes;
   Hours := Trunc(Minutes/60);
   IF Hours >= 1 THEN Minutes := Minutes - 60*Hours;
   rubOut(1,21,5,GraphBackColor);
   print (2,21,NumStr(Hours,3,0));
   rubOut(11,21,7,GraphBackColor);
   print (12,21,NumStr(Minutes,3,0));
   rubOut(25,21,7,GraphBackColor);
   print (26,21,NumStr(Seconds,3,0));
   SelectViewPort(1);
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
   xSc1, ySc1, xSc2, ySc2, Radius: Integer;
   Distance, ScaledDistance: Real;
   TimeStr: String;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   PlotOrbit := False;
   Message('');
   OpenViewPort(1);
   SelectScale(1);
   Action := False;
   Input := True;
   WITH HotKeys DO
   BEGIN
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Accept';
      Hotkeys.BackColor := Red;
   END;
   HotKeys.Display;
   Message('Use the sliders to choose initial conditions. Press <Accept> when ready');
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   Sliders.Create(1, 0, 360, ThetaDot, 0.95, 0.2, 0.8, 2, '0', '360', 'x'' deg/sec', True);
   Sliders.Create(2, 0, 360, Theta, 0.05, 0.2, 0.8, 2, '0', '360', 'x deg', True);
   Sliders.DrawAll;
   StoreAngle := y[1];
   PlotPend(y[1], Yellow);
   {GraphBackColor := DarkGray;}
   SelectViewPort(1);
       TimeStr := ('     hours       minutes       seconds');
      print(1,21,TimeStr);
   {PrintTime(0);}
   ShowCursor;   
END;

{------------------------------------------------------------------------}

PROCEDURE MovePendulum;
BEGIN
   Delay(Lag);
   PlotPend(y[1], Black);
   Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   StoreAngle := y[1];
   PlotPend(y[1], Yellow);
   PrintTime(Time);
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE AnimatePendulum;
VAR

   xOld, yOld, xNew, yNew: Real;
   xPend, yPend: Real;
BEGIN
   {PlotPend(StoreAngle, Black);}
   Time := 0;
   PrintTime(0);
   {PlotPend(0, Black);}
   StepSize:= 1;
   PlotOrbit := True;
   Action := False;
   StoreAngle := y[1];
   {IF y[2] > 0 THEN Y2Sign := 1;
   IF y[2] < 0 THEN Y2Sign := -1;
   IF y[2] = 0 THEN
   BEGIN
      IF y[1] > 0 THEN Y2Sign := -1
                  ELSE Y2Sign := 1;
   END; }
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   ThetaDot := Sliders.Value(1);
   Theta := Sliders.Value(2);
   y[1] := Theta*Pi/180;
   PlotPend(StoreAngle, Black);
   PlotPend(y[1], Yellow);
   StoreAngle := y[1];
   y[2] := ThetaDot*Pi/180;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
BEGIN
      CASE Key OF
          1: BEGIN
             IF Input THEN Exit;
             IF Action = True THEN
             BEGIN
                Action := False;
                WITH HotKeys DO Key[1] := 'F2-Run';
                HotKeys.BackColor := Red;
                HotKeys.Display;
             END
             ELSE
             BEGIN
                Action := True;
                WITH HotKeys DO Key[1] := 'F2-Pause';
                HotKeys.BackColor := Blue;
                HotKeys.Display;
             END;
          END;
       2: BEGIN
             IF Input THEN
             BEGIN
                WITH HotKeys DO Key[2] := 'F3-Input';
                HotKeys.Display;
                Message('');
                Input := False;
                AnimatePendulum;
             END
             ELSE
             BEGIN
                Input := True;
                PlotPend(y[1], Black);
                PlotPend(Theta*Pi/180, Yellow);
                y[1] := Theta*Pi/180;
                y[2] := ThetaDot*Pi/180;
                Time := 0;
                Message('Use the sliders to choose initial conditions. Press <Accept> when ready');
                WITH HotKeys DO Key[2] := 'F3-Accept';
                HotKeys.Display;
                IF Action THEN
                BEGIN
                   WITH HotKeys DO Key[1] := 'F2-Run';
                   HotKeys.BackColor := Red;
                   HotKeys.Display;
                END;
                Action := False;
                PlotOrbit := False;
                StoreAngle := Theta*Pi/180;
             END;
          END;
      3: BEGIN
               PlotOrbit := False;
               Action := False;
               HotKeys.Clear;
               CloseViewPort(1);
               LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SeePhaseSpace;
VAR
  PHotKeys                  : THotKeys;
  Pause, PAction, PlotOrbits: Boolean;
  xOld, yOld, xNew, yNew    : Real;

PROCEDURE HandlePHotKeys(Key : Byte); FORWARD;

PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(7);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Run';
      Key[3] := 'F3-Input';
      Key[4] := 'F4-KeyInput';
      Key[5] := 'F5-TimeDelay';
      Key[6] := 'F6-CleanUp';
      Key[7] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Red;
   PHotKeys.HotKeyColor := Yellow;
   PHotKeys.Display;
END;

{-----------------------------------------------------------------------}

PROCEDURE GetPhasePlotScale;
VAR
   PhasePlotData        : TInputScreen;
   Delx                 : Real;
BEGIN
 {  ShowMouse; }
   WITH PhasePlotData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.18, 0.82);
      LoadLine('');
      LoadLine('    Scale for the phase-plane diagram.');
      LoadLine('');
      LoadLine('     The phase-plane diagram is a plot of');
      LoadLine('  theta-prime vs. theta (x'' vs. x.) The');
      LoadLine('  minimum and maximum values of theta are');
      LoadLine('  -360 m and 360 n, where m and n are each');
      LoadLine('  integers between 1 and 10. Enter');
      LoadLine('         m = {   }    n = {   }');
      LoadLine('     Enter the minimum and maximum values');
      LoadLine('  of theta-prime in degrees per second:');
      LoadLine('  Minimum: -1000 <= {      } <= 0');
      LoadLine('  Maximum:     1 <= {      } <= 1000');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, nMin);
      SetNumberLimits(1, 1, 10);
      SetNumber(2, nMax);
      SetNumberLimits(2, 1, 10);
      SetNumber(3, ThetaDotMin);
      SetNumberLimits(3, -1000, 0);
      SetNumber(4, ThetaDotMax);
      SetNumberLimits(4, 1, 1000);
      AcceptScreen;
      nMin := Trunc(GetNumber(1) + 0.001);
      nMax := Trunc(GetNumber(2) + 0.001);
      ThetaDotMin := GetNumber(3);
      ThetaDotMax := GetNumber(4);
      ThetaMax := nMax*2*Pi;
      ThetaMin := -nMin*2*Pi;
      Done;
   END;
   Delx := (nMin + nMax)*2*Pi/50;
   DefineScale(2, -nMin*2*Pi - Delx, nMax*2*Pi + Delx,
                   ThetaDotMin*Pi/180, ThetaDotMax*Pi/180);
   xMax := nMax*2*Pi;
   xMin := -nMin*2*Pi;
   yMax := ThetaDotMax*Pi/180;
   yMin := ThetaDotMin*Pi/180;
   {HideMouse;}
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

{-----------------------------------------------------------------------}

PROCEDURE SetUpPhasePlot;
VAR
   xSc, ySc: Integer;
   CoordStr: String;
   i       : INteger;
   Alternate : Boolean;
BEGIN
   ClearMuppetPort;
   GetPhasePlotScale;
   GraphBackColor := DarkGray;
   IF NOT Poincare THEN OpenViewPort(3);
   SelectScale(1);
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   SetUpPHotKeys;
   SetColor(White);
   HideMouse;
   IF nMin + nMax >= 11 THEN Alternate := True ELSE Alternate :=False;
   PlotLine(ThetaMin, 0, ThetaMax, 0);
   PlotLine(0, yMin, 0, yMax);
   FOR i := 0 TO nMin DO
   BEGIN
      IF (NOT Alternate) OR ((Alternate) AND (Trunc(I/3)=I/3))  THEN
      PlotLine(-2*Pi*i, 0, -2*Pi*i, (ThetaDotMax - ThetaDotMin)*Pi/(180*50));
      IF i = 0 THEN
         OutTextXY(MapX(0)-XDisp(10), MapY(0)+YDisp(10), NumStr(0,1,0))
      ELSE
      BEGIN
      IF (i = 1) AND (NOT Alternate) THEN
         OutTextXY(MapX(-2*Pi*i)-XDisp(10), MapY(0)+YDisp(10),
                 NumStr(-360, 3,0))
               ELSE
         IF (NOT Alternate) OR ((Alternate) AND (Trunc(I/3)=I/3))  THEN
         OutTextXY(MapX(-2*Pi*i)-XDisp(10), MapY(0)+YDisp(10),
                 NumStr(-i,1,0)+'*'+NumStr(360, 3,0));
      END;
   END;
   FOR i := 1 TO nMax DO
   BEGIN
      IF (NOT Alternate) OR ((Alternate) AND (Trunc(I/3)=I/3))  THEN
      PlotLine(2*Pi*i, 0, 2*Pi*i, (ThetaDotMax - ThetaDotMin)*Pi/(180*50));
      IF (i = 1) AND (NOT Alternate) THEN
      OutTextXY(MapX(2*Pi*i)-XDisp(20), MapY(0)+YDisp(10),
                 NumStr(360, 3,0))
      ELSE
      IF (NOT Alternate) OR ((Alternate) AND (Trunc(I/3)=I/3))  THEN
      OutTextXY(MapX(2*Pi*i)-XDisp(30), MapY(0)+YDisp(10),
                 NumStr(i,1,0)+'*'+NumStr(360, 3,0));
   END;
   i := 1;
   REPEAT
      PlotLine(0, 100*i*Pi/180, (ThetaMax - ThetaMin)/50, 100*i*Pi/180);
      OutTextXY(MapX(0)-XDisp(35), MapY(100*i*Pi/180)+YDisp(3),
                NumStr(100*i, 4, 0));
      i := i + 1;
   UNTIL 100*i > ThetaDotMax;
   i := 1;
   REPEAT
      PlotLine(0, -100*i*Pi/180, (ThetaMax - ThetaMin)/50, -100*i*Pi/180);
      OutTextXY(MapX(0)-XDisp(37), MapY(-100*i*Pi/180),
                NumStr(-100*i, 4, 0));
      i := i + 1;
   UNTIL -100*i < ThetaDotMin;
   OutTextXY(MapX(0.9*ThetaMax + 0.1*ThetaMin), MapY(0)-YDisp(20), 'Degrees');
   IF nMax >= nMin THEN
   OutTextXY(MapX(0)+XDisp(10),
             MapY((0.96*ThetaDotMax+0.04*ThetaDotMin)*Pi/180),
                     'Degrees per second')
   ELSE
   OutTextXY(MapX(0)-XDisp(100),
             MapY((0.96*ThetaDotMax+0.04*ThetaDotMin)*Pi/180),
                     'Degrees per second');
   ShowMouse;
   Input := True;
   Pause := True;
END;

PROCEDURE FindNextPoincarePoint;
VAR
   NextTime    : Real;
   XPlot       : Real;
   TempStep    : Real;
BEGIN
   SelectViewPort(2);
   SelectScale(2);
   NextTime := Time + Period;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   UNTIL Time > NextTime;
   Step(Time, NextTime - Time, 0.0000001, y, Time, TempStep, y);
   REPEAT
      IF y[1] > ThetaMax THEN y[1] := y[1] - (ThetaMax - ThetaMin);
   UNTIL y[1] < ThetaMax;
   REPEAT
      IF y[1] < ThetaMin THEN y[1] := y[1] + (ThetaMax - ThetaMin);
   UNTIL y[1] > ThetaMin;
   {xPlot := 180*y[1]/Pi;
   REPEAT IF xPlot > 360 THEN xPlot := xPlot - 720; UNTIL xPlot < 360;
   REPEAT IF xPlot < - 360 THEN xPlot := xPlot + 720; UNTIL xPlot > -360;}
   SetColor(Yellow);
   PlotSymbol(y[1], y[2], '.');
END;

PROCEDURE MovePhasePlot;
BEGIN
   Delay(10);
   IF Pause OR Input THEN Exit;
   SelectViewPort(3);
   SelectScale(1);
   PlotPend(y[1], DarkGray);
   Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   PlotPend(y[1], White);
   SelectViewPort(2);
   SelectScale(2);
         IF (y[1] < ThetaMax) AND (y[1] > ThetaMin) THEN
         BEGIN
            SetColor(GraphBackColor);
            PlotSymbol(xNew, yNew, 'o');
            SetColor(Yellow);
            PlotLine(xOld, yOld, xNew, yNew);
            PlotSymbol(y[1], y[2], 'o');
            PlotLine(xNew, yNew, y[1], y[2]);
            xOld := xNew; yOld := yNew;
            xNew := y[1]; yNew := y[2];
         END
         ELSE
         BEGIN
            IF y[1] > ThetaMax THEN y[1] := y[1] - (ThetaMax - ThetaMin);
            IF y[1] < ThetaMin THEN y[1] := y[1] + (ThetaMax - ThetaMin);
            SetColor(GraphBackColor);
            PlotSymbol(xNew, yNew, 'o');
            SetColor(Yellow);
            PlotLine(xOld, yOld, xNew, yNew);
            xOld := y[1];
            xNew := y[1];
            yOld := y[2];
            yNew := y[2];
         END;
END;


{------------------------------------------------------------------------}


PROCEDURE StartPhasePlot;
VAR
   WaitMessage    : TWaitMessage;
BEGIN
   Pause := False;
   WITH PHotKeys DO Key[2] := 'F2-Pause';
   PHotKeys.BackColor := Blue;
   PHotKeys.Display;
   IF TimeDelay > 0 THEN
   BEGIN
      Time := 0;
      WaitMessage.Show;
      REPEAT
         IF NOT Poincare THEN
         BEGIN
            SelectViewPort(3);
            SelectScale(1);
         END;
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
         WaitMessage.UpDate;
      UNTIL (Time > TimeDelay);
      IF NOT Poincare THEN PlotPend(y[1], DarkGray);
      Step(Time, TimeDelay - Time, 0.0000001, y, Time, StepSize, y);
      IF NOT Poincare THEN PlotPend(y[1], White);
      StepSize := 0.1;
      WaitMessage.Hide;
   END;

   REPEAT
      IF y[1] > ThetaMax THEN y[1] := y[1] - (ThetaMax - ThetaMin);
   UNTIL y[1] < ThetaMax;
   REPEAT
      IF y[1] < ThetaMin THEN y[1] := y[1] + (ThetaMax - ThetaMin);
   UNTIL y[1] > ThetaMin;
   xOld := y[1];
   yOld := y[2];
   xNew := y[1];
   yNew := y[2];
   StepSize:= 0.1;
  { IF NOT Poincare THEN
   BEGIN
      GraphBackColor := DarkGray;
      OpenViewPort(3);
      SelectViewPort(3);
      SelectScale(1);
   END; }
END;

{-------------------------------------------------------------------------}

PROCEDURE SelectStart;
VAR
   Inside: Boolean;
   xSave, ySave    : Real;
   a               : Integer;
BEGIN
      Input := True;
      Delay(500);
      SetColor(Yellow);
      SelectViewPort(2);
      SelectScale(2);
      SetColor(GraphBackColor);
      IF Abs(y[1])+Abs(y[2]) > 0.03 THEN PlotSymbol(y[1], y[2], 'o');
      IF NOT Poincare THEN
      BEGIN
         SelectViewPort(3);
         SelectScale(1);
         PlotPend(y[1], DarkGray);
         SelectViewPort(2);
         SelectScale(2);
      END;
     { SetColor(Yellow);
      IF NOT Input THEN PlotLine(xOld, yOld, xNew, yNew);}
      Inside := False;
      ShowMouse;
            SetColor(White);
      Message('     Click on a starting point');
      REPEAT
         MousePosn(y[1], y[2], 2, 2, Inside);
         IF Inside AND
         (Abs(XSave - y[1]) + Abs(YSave - y[2]) > 0.01) THEN
         BEGIN
            RubOutXY(0.5, 0.98, 20, Blue);
            PrintXY(0.5, 0.98, '('+NumStr(y[1]*180/Pi, 6, 2)
                             +', '+NumStr(y[2]*180/Pi, 6, 2)+')');
            XSave := y[1];
            YSave := y[2];

         END;
         IF NOT Inside THEN
         BEGIN
            RubOutXY(0.5, 0.98, 20, Blue);
            PrintXY(0.5, 0.98, 'INSIDE!');
            Beep;
         END;
      UNTIL MouseClicked(a,a) AND Inside;
      IF y[2] > 0 THEN Y2Sign := 1;
      IF y[2] < 0 THEN Y2Sign := -1;
      IF y[2] = 0 THEN
      BEGIN
         IF y[1] > 0 THEN Y2Sign := -1
                     ELSE Y2Sign := 1;
      END;
      Message('');
      xOld := y[1];
      xNew := y[1];
      yOld := y[2];
      yNew := y[2];
      PAction := True;
     { HideMouse;}
      StartPhasePlot;
 {     REPEAT
         Message('         Click on a starting point in the window');
         WaitOnMouseClick;
         MousePosn(y[1], y[2], 2, 2, Inside);
         {IF y[2] > 0 THEN Y2Sign := 1;
         IF y[2] < 0 THEN Y2Sign := -1;
         IF y[2] = 0 THEN
         BEGIN
            IF y[1] > 0 THEN Y2Sign := -1
                        ELSE Y2Sign := 1;
         END;
         Message('');
         IF Inside THEN
         BEGIN
            xOld := y[1];
            xNew := y[1];
            yOld := y[2];
            yNew := y[2];
            PAction := True;
            HideMouse;
            StartPhasePlot;
            {FindNextPoincarePoint;
         END
         ELSE
         BEGIN
            Message('You clicked outside the window. Please try again');
            Beep;
            Delay(2000);
            Message('         Click on a starting point in the window');
         END;
      UNTIL Inside;   }
      Input := False;
END;

{------------------------------------------------------------------------}

PROCEDURE KeyInput;
VAR
   InputInit    : TInputScreen;
BEGIN
   Message('');
{   ShowMouse;}
   SelectViewPort(2);
   SelectScale(2);
   SetColor(GraphBackColor);
   IF Abs(y[1]) + Abs(y[2]) > 0.03 THEN PlotSymbol(y[1], y[2], 'o');
 {  SetColor(Yellow);
   PlotLine(xOld, yOld, xNew, yNew); }
   WITH InputInit DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Enter new conditions. Use degrees.');
      LoadLine('');
      LoadLine('  Theta = {       },  ThetaPrime = {       }');
      LoadLine('                 f = {       }');
      LoadLine('                 k = {       }');
      LoadLine('                 w = {       }');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, xStart);
      SetNumber(2, xpStart);
      SetNumber(3, Force);
      SetNumber(4, Drag);
      SetNumber(5, Frequency);
      SetNumberLimits(1, -360*nMin, 360*nMax);
      SetNumberLimits(2, ThetaDotMin, ThetaDotMax);
      SetNumberLimits(3, 0, 10);
      SetNumberLimits(4, 0, 10);
      SetNumberLimits(5, 0, 10);
      AcceptScreen;
      xStart := GetNumber(1);
      xpStart := GetNumber(2);
      Force := GetNumber(3);
      Drag := GetNumber(4);
      Frequency := GetNumber(5);
      Period := 2*Pi/Frequency;
      Done;
   END;
   y[1] := xStart*Pi/180;
   y[2] := xpStart*Pi/180;
   Time := 0;
   PAction := True;
  { HideMouse; }
   Input := False;
   StartPhasePlot;
END;

{------------------------------------------------------------------------}

PROCEDURE GetNewTimeDelay;
VAR
   DelayInput   : TInputScreen;
BEGIN
  { ShowMouse; }
   WITH DelayInput DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.25, 0.75);
      LoadLine('');
      LoadLine('     When plotting phase-plane diagrams or');
      LoadLine('  Poincare maps, it is best to wait until ');
      LoadLine('  the transient part of the solution is past.');
      LoadLIne('  This delay is an integral multiple of the');
      LoadLine('  period of the forcing term. Enter a value');
      LoadLine('  for this integer:');
      LoadLine('              IDelay = {   }.');
      LoadLine('   Now the delay is IDelay*(2*Pi)/Frequency.');
      LoadLine('');
      LoadLine('                     [  OK  ]');
      SetNumber(1, IPeriod);
      SetNumberLimits(1, 0, 1000);
      AcceptScreen;
      IPeriod := Trunc(GetNumber(1)+0.1);
      TimeDelay := IPeriod*Period;
      Done;
   END;
  { HideMouse; }
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePHotKeys(Key: Byte);
BEGIN
      CASE Key OF
           1: ShowHelp('HlpChaos.hlp', 'ForcePenHotKeyHelp');
           2: BEGIN
                 IF Input THEN
                 BEGIN
                    Announce('Please enter starting conditions using <F3> or <F4>');
                    Exit;
                 END;
                 IF Pause THEN
                 BEGIN
                    Pause := False;
                    WITH PHotKeys DO Key[2] := 'F2-Pause';
                    PHotKeys.BackColor := Blue;
                    PHotKeys.Display;
                 END
                 ELSE
                 BEGIN
                    Pause := True;
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
              END;
           3: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
                 Pause := True;
                 PAction := False;
                 SelectStart;
              END;
           4: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
                 Pause := True;
                 PAction := False;
                 KeyInput;
              END;
           5: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
                 Pause := True;
                 PAction := False;
                 Input := True;
                 GetNewTimeDelay;
                 Message('Please enter starting conditions using <F3> or <F4>');
                 PlotOrbits := True;
              END;
           6: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
                 Pause := True;
                 PAction := False;
                 SetUpPhasePlot;
                 Message('Please enter starting conditions using <F3> or <F4>');
                 PlotOrbits := True;
                 {SelectStart;}
              END;
           7: BEGIN
                 PAction := False;
                 Phase := False;
                 PlotOrbits := False;
                 PHotKeys.Clear;
                 CloseViewPort(2);
                 CloseViewPort(3);
                 ClearMuppetPort;
                 LightMenu := True;
                 ShowMouse;
              END;
      END;
END;


BEGIN
 {  HideMouse; }
   SetUpPhasePlot;
   GetNewTimeDelay;
   Message('Please enter starting conditions using <F3> or <F4>');
   PlotOrbits := True;
   {SelectStart;}
{   IF Poincare THEN
   BEGIN
      WaitMessage.Show;
      Time := 0;
      StepSize := 0.1;
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
         WaitMessage.UpDate;
      UNTIL (Time > TimeDelay);
      Step(Time, TimeDelay - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
      WaitMessage.Hide;
   END;  }
   Time := 0;
   StepSize := 0.1;
   REPEAT
      CheckForEvents;
      IF PHotkeys.Pressed(Key) THEN
                  HandlePHotKeys(Key);
      IF PAction AND PlotOrbits AND (NOT Pause) AND (NOT Poincare)
         THEN MovePhasePlot;
      IF PAction AND PlotOrbits AND (NOT Pause) AND (Poincare)
         THEN FindNextPoincarePoint;
      IF (NOT PAction) AND (NOT Pause) THEN
      BEGIN
         SetColor(Red);
         PlotSymbol(xOld, yOld, 'o');
      END;
   UNTIL Not PlotOrbits;
   LightMenu := True;
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
         DefineInputPort(0.21, 0.79, 0.25, 0.75);
         LoadLine('');
         LoadLine('  Enter extreme values for the plot:');
         LoadLine('  Minimum t:   0 <= {      } >= 0,');
         LoadLine('  Maximum t:  10 <= {      } <= 1000,');
         LoadLine('  Minimum x: -60 <= {      } <= 0 radians,');
         LoadLine('  Maximum x:   0 <= {      } <= 60 radians.');
         LoadLine('');
         LoadLine('  Enter initial values, using degrees:');
         LoadLine('      x = {      }, xprime = {      }.');
         LoadLine('');
         LoadLine('        [  OK  ]    [Cancel]');
         SetNumber(1, xLow);
         SetNumberLimits(1, 0, 100);
         SetNumber(2, xHigh);
         SetNumberLimits(2, 10, 1000);
         SetNumber(3, yLow);
         SetNumberLimits(3, -60, 0);
         SetNumber(4, yHigh);
         SetNumberLimits(4, 0, 60);
         SetNumber(5, xStart);
         SetNumber(6, xpStart);
         AcceptScreen;
         SelectPlotScale := NOT Canceled;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            Quit := False;
            xLow := GetNumber(1);
            xHigh := GetNumber(2);
            yLow := GetNumber(3);
            yHigh := GetNumber(4);
            xStart := GetNumber(5);
            xpStart := GetNumber(6);
         END;
         Done;
      END;
      IF (xHigh <= xLow) OR (yHIgh <= yLow) AND (NOT Quit) THEN
         Announce('Extreme coordinates out of order. Try again.');
   UNTIL (xHigh > xLow) AND (yHigh > yLow) OR Quit;
END;

{-------------------------------------------------------------------------}

FUNCTION SelectSinPlotScale : Boolean;
VAR
   ScaleInput    : TInputScreen;
   Quit          : Boolean;
BEGIN
   REPEAT
      WITH ScaleInput DO
      BEGIN
         Init;
         DefineInputPort(0.25, 0.75, 0.3, 0.7);
         LoadLine('');
         LoadLine('  Enter extreme values for the plot:');
         LoadLine('  Minimum t: {      } >= 0,');
         LoadLine('  Maximum t: {      } <= 1000,');
         LoadLine('');
         LoadLine('  Enter initial values, using degrees:');
         LoadLine('  x = {      }, xprime = {      }.');
         LoadLine('');
         LoadLIne('        [  OK  ]    [Cancel]');
         SetNumber(1, xLow);
         SetNumberLimits(1, 0, 500);
         SetNumber(2, xHigh);
         SetNumberLimits(2, 0, 1000);
         SetNumber(3, xStart);
         SetNumber(4, xpStart);
         AcceptScreen;
         SelectSinPlotScale := NOT Canceled;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            Quit := False;
            xLow := GetNumber(1);
            xHigh := GetNumber(2);
            yLow := -1.5;
            yHigh := 1.5;
            xStart := GetNumber(3);
            xpStart := GetNumber(4);
         END;
         Done;
      END;
      IF (xHigh <= xLow) OR (yHIgh <= yLow) AND (NOT Quit) THEN
         Announce('Extreme coordinates out of order. Try again.');
   UNTIL (xHigh > xLow) AND (yHigh > yLow) OR Quit;
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
END;

{-------------------------------------------------------------------------}

PROCEDURE XTickMarks(YM, XL, XH, YL, YH: Real);
VAR
   Length     : Real;
   Period     : Real;
   I          : Integer;
BEGIN
   Period := 2*Pi/Frequency;
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
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   HideMouse;
   LightMenu := False;
   GraphBackColor := DarkGray;
   SetColor(White);
   OpenViewPort(1);
   SolHotKeys.Display;
   SolutionPlot := True;
   IF PlotSin THEN
      DefineScale(4, xLow-DelX, xHigh+DelX, yLow-DelY, yHigh+DelY)
      ELSE
      DefineScale(4, xLow-2*DelX, xHigh+DelX, yLow-DelY, yHigh+DelY);
   SelectScale(4);
   PlotLine(xLow, 0, xHigh, 0);
   XTickMarks(0, xLow, xHigh, yLow, yHigh);
   PlotLIne(xLow, yLow, xLow, yHigh);
   DelY := 2*Pi;
   YZero := 0;
   IF PlotSin THEN
   BEGIN
      PlotLine(xLow, 1, xLow+(xHigh-xLow)/50, 1);
      OutTextXY(MapX(xLow-(xHigh-xLow)/50), MapY(1), '1');
      PlotLine(xLow, -1, xLow+(xHigh-xLow)/50, -1);
      OutTextXY(MapX(xLow-(xHigh-xLow)/30), MapY(-1), '-1');
   END
   ELSE
   BEGIN
      OutTextXY(MapX(xLow-(xHigh-xLow)/15), MapY(2*Pi), '2*Pi');
      OutTextXY(MapX(xLow-(xHigh-xLow)/13), MapY(-2*Pi), '-2*Pi');
   END;
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
   PrintXY(0.2, 0.1,'Horizontal marks at intervals of the forcing period.');
   y[1] := xStart*Pi/180;
   y[2] := xpStart*Pi/180;
   xOld := xLow;
   IF PlotSin THEN yOld := Sin(y[1]) ELSE yOld := y[1];
   Time := xLow;
   StepSize:= 0.1;
   Message('        Hit a key to stop a plot');
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      IF PlotSin THEN PLotLine(xOld, yOld, Time, Sin(y[1]))
                 ELSE PLotLine(xOld, yOld, Time, y[1]);
      xOld := Time;
      IF PlotSin THEN yOld := Sin(y[1]) ELSE yOld := y[1];
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
      DefineInputPort(0.2, 0.8, 0.29, 0.71);
      LoadLine('');
      LoadLine('     Enter new conditions. Use degrees.');
      LoadLine('');
      LoadLine('  Theta = {       },  ThetaPrime = {       }');
      LoadLine('                 f = {       }');
      LoadLine('                 k = {       }');
      LoadLine('                 w = {       }');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, xStart);
      SetNumber(2, xpStart);
      SetNumber(3, Force);
      SetNumber(4, Drag);
      SetNumber(5, Frequency);
      SetNumberLimits(3, 0, 10);
      SetNumberLimits(4, 0, 10);
      SetNumberLimits(5, 0, 10);
      AcceptScreen;
      xStart := GetNumber(1);
      xpStart := GetNumber(2);
      Force := GetNumber(3);
      Drag := GetNumber(4);
      Frequency := GetNumber(5);
      Period := 2*Pi/Frequency;
      Done;
   END;
   y[1] := xStart*Pi/180;
   y[2] := xpStart*Pi/180;
   xOld := xLow;
   IF PlotSin THEN yOld := Sin(y[1]) ELSE yOld := y[1];
   Time := xLow;
   StepSize:= 0.1;
   HideMouse;
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      IF PlotSin THEN PLotLine(xOld, yOld, Time, Sin(y[1]))
                 ELSE PLotLine(xOld, yOld, Time, y[1]);
      xOld := Time;
      IF PlotSin THEN yOld := Sin(y[1]) ELSE yOld := y[1];
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
   OpenViewPort(1);
   SolHotKeys.Display;
   IF PlotSin THEN
      DefineScale(4, xLow-DelX, xHigh+DelX, yLow-DelY, yHigh+DelY)
      ELSE
      DefineScale(4, xLow-2*DelX, xHigh+DelX, yLow-DelY, yHigh+DelY);
   SelectScale(4);
   PlotLine(xLow, 0, xHigh, 0);
   XTickMarks(0, xLow, xHigh, yLow, yHigh);
   PlotLIne(xLow, yLow, xLow, yHigh);
   IF PlotSin THEN
   BEGIN
      PlotLine(xLow, 1, xLow+(xHigh-xLow)/50, 1);
      OutTextXY(MapX(xLow-(xHigh-xLow)/50), MapY(1), '1');
      PlotLine(xLow, -1, xLow+(xHigh-xLow)/50, -1);
      OutTextXY(MapX(xLow-(xHigh-xLow)/30), MapY(-1), '-1');
   END
   ELSE
   BEGIN
      OutTextXY(MapX(xLow-(xHigh-xLow)/15), MapY(2*Pi), '2*Pi');
      OutTextXY(MapX(xLow-(xHigh-xLow)/13), MapY(-2*Pi), '-2*Pi');
   END;
   DelY := 2*Pi;
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
   PrintXY(0.2, 0.1,'Horizontal marks at intervals of the forcing period.');
   ShowMouse;
   RePlotSolution;
END;

{-------------------------------------------------------------------------}

FUNCTION SelectPlotScale2 : Boolean;
VAR
   ScaleInput    : TInputScreen;
   Quit          : Boolean;
BEGIN
   REPEAT
      WITH ScaleInput DO
      BEGIN
         Init;
         DefineInputPort(0.2, 0.8, 0.22, 0.78);
         LoadLine('');
         LoadLine('  Enter extreme values for the plot:');
         LoadLine('        Minimum t: {      } >= 0,');
         LoadLine('        Maximum t: {      } <= 1000,');
         LoadLine('  Minimum x-prime: {      } >= -50, <= 0,');
         LoadLine('  Maximum x-prime: {      } <= 50, >= 0.');
         LoadLine(' (For the plot, x-prime is radians/second.)');
         LoadLine('');
         LoadLine('  Enter initial values, using degrees:');
         LoadLine('  x = {      }, xprime = {      }.');
         LoadLine('');
         LoadLIne('          [  OK  ]    [Cancel]');
         SetNumber(1, xLow);
         SetNumberLimits(1, 0, 500);
         SetNumber(2, xHigh);
         SetNumberLimits(2, 0, 1000);
         SetNumber(3, xDotLow);
         SetNumberLimits(3, -50, 0);
         SetNumber(4, xDotHigh);
         SetNumberLimits(4, 0, 50);
         SetNumber(5, xStart);
         SetNumber(6, xpStart);
         AcceptScreen;
         SelectPlotScale2 := NOT Canceled;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            Quit := False;
            xLow := GetNumber(1);
            xHigh := GetNumber(2);
            xDotLow := GetNumber(3);
            xDotHigh := GetNumber(4);
            yLow := GetNumber(3);
            yHigh := GetNumber(4);
            xStart := GetNumber(5);
            xpStart := GetNumber(6);
         END;
         Done;
      END;
      IF (xHigh <= xLow) OR (yHIgh <= yLow) AND (NOT Quit) THEN
         Announce('Extreme coordinates out of order. Try again.');
   UNTIL (xHigh > xLow) AND (yHigh > yLow) OR Quit;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotSolution2;
VAR
   DelX, DelY   : Real;
   YZero        : Real;
   xOld, yOld   : Real;
BEGIN
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   HideMouse;
   LightMenu := False;
   GraphBackColor := DarkGray;
   SetColor(White);
   OpenViewPort(1);
   SolHotKeys.Display;
   SolutionPlot := True;
   DefineScale(4, xLow-1.5*DelX, xHigh+DelX, yLow-DelY, yHigh+DelY);
   SelectScale(4);
   PlotLine(xLow, 0, xHigh, 0);
   XTickMarks(0, xLow, xHigh, yLow, yHigh);
   PlotLIne(0, yLow, 0, yHigh);
   PlotLine(xLow, Trunc(yHigh), xLow+(xHigh-xLow)/70, Trunc(yHigh));
   OutTextXY(MapX(xLow-(xHigh-xLow)/30), MapY(Trunc(yHigh)),
                     NumStr(Trunc(yHigh) , 2, 0));
   PlotLine(xLow, Trunc(yLow), xLow+(xHigh-xLow)/70, Trunc(yLow));
   OutTextXY(MapX(xLow-(xHigh-xLow)/20), MapY(Trunc(yLow)),
                     NumStr(Trunc(yLow) , 3, 0));
   PrintXY(0.2, 0.1,'Horizontal marks at intervals of the forcing period.');
   y[1] := xStart*Pi/180;
   y[2] := xpStart*Pi/180;
   xOld := xLow;
   yOld := y[2];
   Time := xLow;
   StepSize:= 0.1;
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      PLotLine(xOld, yOld, Time, y[2]);
      xOld := Time;
      yOld := y[2];
   UNTIL (Time > xHigh) OR KeyPressed;
   ClearMKBuffers;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE RePlotSolution2;
VAR
   xOld, yOld   : Real;
   InputInit    : TInputScreen;
BEGIN
   WITH InputInit DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.29, 0.71);
      LoadLine('');
      LoadLine('     Enter new conditions. Use degrees.');
      LoadLine('');
      LoadLine('  Theta = {       },  ThetaPrime = {       }');
      LoadLine('          0 <= f = {       } <= 10');
      LoadLine('          0 <= k = {       } <= 10');
      LoadLine('          0 <= w = {       } <= 10');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, xStart);
      SetNumber(2, xpStart);
      SetNumber(3, Force);
      SetNumber(4, Drag);
      SetNumber(5, Frequency);
      SetNumberLimits(3, 0, 10);
      SetNumberLimits(4, 0, 10);
      SetNumberLimits(5, 0, 10);
      AcceptScreen;
      xStart := GetNumber(1);
      xpStart := GetNumber(2);
      Force := GetNumber(3);
      Drag := GetNumber(4);
      Frequency := GetNumber(5);
      Period := 2*Pi/Frequency;
      Done;
   END;
   y[1] := xStart*Pi/180;
   y[2] := xpStart*Pi/180;
   xOld := xLow;
   yOld := y[2];
   Time := xLow;
   StepSize:= 0.1;
   HideMouse;
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      PLotLine(xOld, yOld, Time, y[2]);
      xOld := Time;
      yOld := y[2];
   UNTIL (Time > xHigh) OR KeyPressed;
   ClearMKBuffers;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE ReDrawAxes2;
VAR
   DelX, DelY   : Real;
   YZero        : Real;
BEGIN
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   HideMouse;
   GraphBackColor := DarkGray;
   SetColor(White);
   OpenViewPort(1);
   SolHotKeys.Display;
   DefineScale(4, xLow-1.5*DelX, xHigh+DelX, yLow-DelY, yHigh+DelY);
   SelectScale(4);
   PlotLine(xLow, 0, xHigh, 0);
   XTickMarks(0, xLow, xHigh, yLow, yHigh);
   PlotLIne(0, yLow, 0, yHigh);
   PlotLine(xLow, Trunc(yHigh), xLow+(xHigh-xLow)/70, Trunc(yHigh));
   OutTextXY(MapX(xLow-(xHigh-xLow)/30), MapY(Trunc(yHigh)),
                     NumStr(Trunc(yHigh) , 2, 0));
   PlotLine(xLow, Trunc(yLow), xLow+(xHigh-xLow)/70, Trunc(yLow));
   OutTextXY(MapX(xLow-(xHigh-xLow)/20), MapY(Trunc(yLow)),
                     NumStr(Trunc(yLow) , 3, 0));
   PrintXY(0.2, 0.1,'Horizontal marks at intervals of the forcing period.');
   ShowMouse;
   RePlotSolution2;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleSolHotKeys(Key : Byte);
BEGIN
   CASE Key OF
   1: IF PlotX THEN RePlotSolution ELSE RePlotSolution2;
   2: IF PlotX THEN ReDrawAxes ELSE ReDrawAxes2;
   3: IF PlotSin THEN
      BEGIN
         IF SelectSinPlotScale THEN
         BEGIN
            PlotSolution;
            PlotX := True;
         END;
      END
      ELSE
      BEGIN
         IF PlotX THEN
         BEGIN
            IF SelectPlotScale THEN PlotSolution;
         END
         ELSE
         BEGIN
            IF SelectPlotScale2 THEN PlotSolution2;
         END;
      END;
   4: BEGIN
         SolutionPlot := False;
         PlotSin := False;
         SolHotKeys.Clear;
         LightMenu := True;
      END;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION SetUpBifurcation : Boolean;
VAR
   Input    : TInputScreen;
   InputOK  : Boolean;
   Quit     : Boolean;
BEGIN
   Message('');
   REPEAT
      WITH Input DO
      BEGIN
         Init;
            DefineInputPort(0.1, 0.9, 0.02, 0.97);
            LoadLine('');
            LoadLIne('              Data for a Bifurcation Diagram');
            LoadLine('');
            LoadLine('    In this utility, the value of the parameters k and w');
            LoadLine(' will be kept fixed, and the parameter f will be sampled');
            LoadLine(' n times between two extreme values. All coefficients must');
            LoadLine(' lie between 0 and 10.');
            LoadLine('            Enter a value for k: k = {       }');
            LoadLine('            Enter a value for w: w = {       }');
            LoadLine(' Enter limits for f: Lower: {       }.  Upper: {       }');
            LoadLine(' Number of samples:   10 <= {       } <= 500');
            LoadLine('');
            LoadLine('    dx/dt will be sampled at the start of each cycle. For');
            LoadLine(' the vertical scale enter the limits, using radians:');
            LoadLine('                     Lower: {       }   Upper: {       }');
            LoadLine('');
            LoadLine('    To avoid transient terms p periods (2*Pi/w) are computed');
            LoadLine(' before data are recorded; then data from q periods are found.');
            LoadLine('  Enter values for p:  0 <= {       } <= 20');
            LoadLine('                   q: 10 <= {       } <= 100');
            LoadLine('');
            LoadLine('         [ Help ]         [  OK  ]         [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'PendBifurcationInputHelp');
            SetNumber(1, Drag);
            SetNumber(2, Frequency);
            SetNumber(3, ForceLow);
            SetNumber(4, ForceHigh);
            SetNumber(5, BifSamples);
            SetNumber(6, RxDotLow);
            SetNumber(7, RxDotHigh);
            SetNumber(8, IPeriod);
            SetNumber(9, BifPoints);
            SetNumberLimits(1, 0, 10);
            SetNumberLimits(2, 0, 10);
            SetNumberLimits(3, 0, 10);
            SetNumberLimits(4, 0, 10);
            SetNumberLimits(5, 10, 500);
            SetNumberLimits(8, 0, 20);
            SetNumberLimits(9, 10, 100);
            AcceptScreen;
            IF Canceled THEN
            BEGIN
               Quit := True;
               SetUpBifurcation := False;
            END
            ELSE
            BEGIN
               Quit := False;
               SetUpBifurcation := True;
            END;
            Drag := GetNumber(1);
            Frequency := GetNumber(2);
            Period := 2*Pi/Frequency;
            ForceLow := GetNumber(3);
            ForceHigh := GetNumber(4);
            BifSamples := Trunc(GetNumber(5) + 0.0001);
            RxDotLow := GetNumber(6);
            RxDotHigh := GetNumber(7);
            Iperiod := Trunc(GetNumber(8) + 0.0001);
            BifPoints := Trunc(GetNumber(9) + 0.0001);
         Done;
      END;
      IF (NOT Quit) AND (ForceLow >= ForceHigh) OR (RxDotLow >= RxDotHigh) THEN
      BEGIN
         InputOK := False;
         Announce('You have confused the higher and lower values. Try again.');
      END
      ELSE InputOK := True;
   UNTIL InputOK OR Quit;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpBifurcationScreen;
BEGIN
   ClearMuppetPort;
   Bifurcate := True;
   DefineViewPort(4, 0.15, 0.85, 0.1, 0.9);
   OpenViewPort(4);
   BHotKeys.Display;
   DefineScale(4, ForceLow-(ForceHigh-ForceLow)/20,
                  ForceHigh+(ForceHigh-ForceLow)/20,
                  RxDotLow-(RxDotHigh-RxDotLow)/20,
                  RxDotHigh+(RxDotHigh-RxDotLow)/20);
   SelectScale(4);
   Axis(0, 0, 0.2, 1);
   ForceCurrent := ForceLow;
   DeltaForce := (ForceHigh - ForceLow)/BifSamples;
   LightMenu := False;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpBifurcation2;
VAR
   Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.2, 0.8);
      LoadLine('');
      LoadLIne('         More Data for a Bifurcation Diagram');
      LoadLine('');
      LoadLine('    In order to pick up all branches of bifurcations');
      LoadLine(' more than one set of initial conditions must be used.');
      LoadLine(' Up to three runs are possible. The initial value of');
      LoadLine(' the angle x (in radians) can be varied.');
      LoadLine('');
      LoadLine('    Enter the number of runs:');
      LoadLine('                1 <= I ={      } <= 3');
      LoadLine('    Enter the initial values of x, between 0 and Pi:');
      LoadLine('       x1 = {      }   x2 = {      }   x3 = {      }');
      LoadLine('');
      LoadLine('                          [  OK  ]');
      SetNumber(1, NRuns);
      SetNumberLimits(1, 1, 3);
      SetNumber(2, xI[1]);
      SetNumber(3, xI[2]);
      SetNumber(4, xI[3]);
      SetNumberLimits(2, 0, Pi);
      SetNumberLimits(3, 0, Pi);
      SetNumberLimits(4, 0, Pi);
      AcceptScreen;
      NRuns := Trunc(GetNumber(1) + 0.001);
      xI[1] := GetNumber(2);
      xI[2] := GetNumber(3);
      xI[3] := GetNumber(4);
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotBifurcatePoints;
VAR
   i      : Integer;
   IRuns  : Integer;
   Theta  : Real;
BEGIN
   Force := ForceCurrent;
   FOR IRuns := 1 TO NRuns DO
   BEGIN
      Time := 0;
      y[1] := xI[IRuns];
      y[2] := 0;
      StepSize := 0.01;
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time > IPeriod*Period;
      StepSize  := IPeriod*Period - Time;
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
      Time := 0;
      FOR i := 1 TO BifPoints DO
      BEGIN
         REPEAT
            Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
         UNTIL Time + Stepsize > Period;
         Step(Time, Period-Time, 0.0000001, y, Time, StepSize, y);
         StepSize := 0.1;
         Time := 0;
         Theta := y[2];
         PutPixel(MapX(ForceCurrent), MapY(Theta), White);
      END;
   END;
   ForceCurrent := ForceCurrent + DeltaForce;
   IF ForceCurrent > ForceHigh THEN
   BEGIN
      Bifurcate := False;
      LightMenu := True;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION FindBasinParameters : Boolean;
VAR
   Input       : TInputScreen;
   Quit        : Boolean;
BEGIN
   Quit := False;
   REPEAT
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.15, 0.85, 0.1, 0.9);
         LoadLine('');
         LoadLine('   Parameters for seeing basins of attraction');
         LoadLine('');
         LoadLine('    Enter extreme values for theta and theta-dot.');
         LoadLine('  Theta:     Low {      }  High {      } deg');
         LoadLine('  Theta-dot: Low {      }  High {      } deg/sec');
         LoadLine('');
         LoadLine('    The program will sample a grid of points to');
         LoadLine(' give initial conditions. Enter the numbers of');
         LoadLine(' points in the two directions:');
         LoadLine('       Theta: {      }  Theta-dot: {      }');
         LoadLine('');
         LoadLine('    Integration will continue until a basin is');
         LoadLIne(' identified, or the computation has extended over');
         LoadLine(' IP periods.');
         LoadLine('   Enter IP = {      }');
         LoadLine('');
         LoadLine('            [  OK  ]       [Cancel]');
         SetNumber(1, ThetaMin);
         SetNumber(2, ThetaMax);
         SetNumber(3, ThetaDotMin);
         SetNumber(4, ThetaDotMax);
         SetNumber(5, NXBasin);
         SetNumber(6, NYBasin);
         SetNumberLimits(5, 1, 10000);
         SetNumberLimits(6, 1, 10000);
         SetNumber(7, IPeriod);
         SetNumberLimits(7, 1, 100000);
         AcceptScreen;
         FindBasinParameters := NOT Canceled;
         IF NOT Canceled THEN
         BEGIN
            ThetaMin := GetNumber(1);
            ThetaMax := GetNumber(2);
            ThetaDotMin := GetNumber(3);
            ThetaDotMax := GetNumber(4);
            NXBasin := Trunc(GetNumber(5) + 0.1);
            NYBasin := Trunc(GetNumber(6) + 0.1);
            Iperiod := Trunc(GetNumber(7) + 0.1);
         END
         ELSE Quit := True;
         Done;
      END;
      IF (ThetaMin >= ThetaMax) OR (ThetaDotMin >= ThetaDotMax) THEN
      Announce('Limits are in the wrong order. Try again');
   UNTIL (ThetaMin < ThetaMax) AND (ThetaDotMin < ThetaDotMax) OR Quit;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpBasinGraphics;
VAR
   xTick, yTick      : Integer;
BEGIN
   DefineViewPort(4, 0.2, 0.8, 0.2, 0.8);
   DefineScale(4, ThetaMin, ThetaMax, ThetaDotMin, ThetaDotMax);
   GraphBackColor := Black;
   ClearMuppetPort;
   OpenViewPort(4);
   SelectScale(4);
   xTick := 10;
   IF (ThetaMax - ThetaMin) > 50 THEN xTick := 50;
   yTick := 10;
   IF (ThetaDotMax - ThetaDotMin) > 50 THEN yTick := 50;
   Axis(0, 0, xTick, yTick);
   xMin := ThetaMin*Pi/180;
   xMax := ThetaMax*Pi/180;
   yMin := ThetaDotMin*Pi/180;
   yMax := ThetaDotMax*Pi/180;
   BHotKeys.Display;
   LightMenu := False;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpBasins;

BEGIN
   FindBasins := FindBasinParameters;
   IF FindBasins THEN
   BEGIN
      SetUpBasinGraphics;
      XCount := 1;
      YCount := 0;
   END;
   BasinColor[0] := LightGray;
   BasinColor[1] := Blue;
   BasinColor[2] := LightMagenta;
   BasinColor[3] := LightGreen;
   BasinColor[4] := LightBlue;
   BasinColor[5] := White;
   BasinColor[6] := LightRed;
   BasinColor[7] := Yellow;
   BasinColor[8] := LightCyan;
   BasinColor[9] := Red;
   BasinColor[10] := Brown;
END;

{-------------------------------------------------------------------------}

PROCEDURE IdentifyNextBasin;
VAR
   TempStepSize         : Real;
   NextTime             : Real;
   BasinFound           : Boolean;
   I                    : Integer;

   ThetaStart, ThetaDotStart   : Real;
   y1old, y2Old         : Real;
BEGIN
   YCount := YCount + 1;
   IF YCount > NYBasin THEN
   BEGIN
      YCount := 1;
      XCount := XCount + 1;
   END;
   IF XCount > NXBasin THEN
   BEGIN
      FindBasins := False;
      LightMenu := True;
      Exit;
   END;
   BasinFound := False;
   y[1] := xMin + (XCount/NXBasin)*(xMax - xMin);
   y[2] := yMin + (YCount/NYBasin)*(yMax - yMin);
   ThetaStart := y[1]*180/Pi;
   ThetaDotStart := y[2]*180/Pi;
   Time := 0;
   StepSize := 0.1;
   REPEAT
      NextTime := Time + Period;
      y1Old := y[1];
      y2Old := y[2];
      REPEAT
         Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > NextTime;
      REPEAT
         Step(Time, NextTime - Time, 0.0000001, y, Time, TempStepSize, y);
      UNTIL Abs(Time - NextTime) < 0.0001;
      IF Abs(y[1] - y1Old) + Abs(y[2] - y2Old) < 0.1 THEN
      BEGIN
         I := -6;
         REPEAT
            I := I + 1;
            IF ((I*2-1)*Pi < y[1]) AND (y[1] < (I*2+1)*Pi) THEN
            BEGIN
               BasinFound := True;
               PutPixel(MapX(ThetaStart), MapY(ThetaDotStart), BasinColor[I+5]);
            END;
         UNTIL (I = 5) OR BasinFound;
      END;
   UNTIL BasinFound OR (Time > IPeriod*Period);
   {IF NOT BasinFound THEN
            PutPixel(MapX(ThetaStart), MapY(ThetaDotStart), White);}
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePendMenu;
BEGIN
   With PendMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpChaos.hlp', 'AboutForcePendProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HlpChaos.hlp', 'AboutForcePendModel1');
                  ShowHelp('HlpChaos.hlp', 'AboutForcePendModel2');
               END;
            2: BEGIN
                  ShowHelp('HlpChaos.hlp','SensitivityHelp1');
                  ShowHelp('HlpChaos.hlp','SensitivityHelp2');
               END;
            3: ShowHelp('HlpChaos.hlp','PhasePlaneHelp');
            4: ShowHelp('HlpChaos.hlp','PoincareMapsHelp');
            5: BEGIN
                  ShowHelp('HlpChaos.hlp','PendBifurcationHelp1');
                  ShowHelp('HlpChaos.hlp','PendBifurcationHelp2');
                  ShowHelp('HlpChaos.hlp','PendBifurcationHelp3');
               END;
            6: ShowHelp('HlpChaos.hlp','NumericalIdeasHelp');
            7: BEGIN
                  ShowHelp('WalkThru.hlp', 'ForcePen1');
                  ShowHelp('WalkThru.hlp', 'ForcePen2');
                  ShowHelp('WalkThru.hlp', 'ForcePen3');
                  ShowHelp('WalkThru.hlp', 'ForcePen4');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  PLotOrbit := False;
                  IF NOT GetPendData THEN LightMenu := True
               END;
            2: BEGIN
                  Phase := False;
                  LightMenu := False;
                  SetUpPicture;
               END;
            3: BEGIN
                  IF SelectPlotScale THEN
                  BEGIN
                     PlotSin := False;
                     PlotSolution;
                     PlotX := True;
                  END;
               END;
            4: BEGIN
                  IF SelectSinPlotScale THEN
                  BEGIN
                     PlotSin := True;
                     PlotSolution;
                     PlotX := True;
                  END;
               END;
            5: BEGIN
                  IF SelectPlotScale2 THEN
                  BEGIN
                     PlotSin := False;
                     PlotSolution2;
                     PlotX := False;
                  END;
               END;
         END;

      4: CASE RowChosen OF
            1: BEGIN
                  Phase := True;
                  Poincare := False;
                  SeePhaseSpace;
               END;
            2: BEGIN
                  Phase := True;
                  Poincare := True;
                  SeePhaseSpace;
               END;
            3: IF NOT SetUpBifurcation
               THEN LightMenu := True
               ELSE
               BEGIN
                  SetUpBifurcation2;
                  SetUpBifurcationScreen;
               END;
            4: SetUpBasins;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleBHotKeys(Key : Byte);
BEGIN
   CASE Key OF
   1: BEGIN
         Bifurcate := False;
         FindBasins := False;
         Action := False;
         LightMenu := True;
         ShowMouse;
         BHotKeys.Clear;
      END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   ExitRequest := False;
   DefineViewPort(1, 0, 1, 0.07, 0.95);
   DefineScale(1, -14/5, 14/5, -2, 2);
   DefineViewPort(2, 0.2, 1, 0.1, 0.95);
   DefineScale(2, -400, 400, -5, 5);
   DefineViewPort(3, 0, 0.2, 0.35, 0.65);
   nMin := -1;
   nMax := 1;
   ThetaDotMin := -200;
   ThetaDotMax := 200;
   Lag := 20;
   Force := 1;
   ForceLow := 0.9;
   ForceHigh := 2.0;
   Theta := 30;
   Length := 1;
   Frequency := 1;
   Period := 2*Pi/Frequency;
   IPeriod := 20;
   TimeDelay := IPeriod*Period;
   Drag := 0.1;
   ThetaDot := 20;
   xLow := 0; xHigh := 300;
   yLow := -8*3.15;
   yHigh := 8*3.15;
   xDotLow := -5;
   xDotHigh := 10;
   xStart := 0;
   xpStart := 0;
   RxDotLow := -1;
   RxDotHigh := 3;
   BifSamples := 500;
   BifPoints := 50;
   nRuns := 3;
   xI[1] := 0;
   xI[2] := 1;
   xI[3] := 2;
   LightMenu := True;
   FindBasins := False;
   Bifurcate := False;
   Sliders.Init;
   SolutionPlot := False;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   GetSetUp;
   Hello('HlpChaos.hlp', 'AboutForcePendProgram');
   SetUpPendMenu;
   SetUpHotKeys;
   SetUpBHotKeys;
   SetUpSolHotKeys;
   REPEAT
      CheckForEvents;
      IF NOT Phase THEN
      BEGIN
         IF NOT SolutionPlot AND Hotkeys.Pressed(Key) THEN
                     HandleHotKeys(Key);
         IF Bifurcate AND BHotKeys.Pressed(Key) THEN HandleBHotKeys(Key);
         IF FindBasins AND BHotKeys.Pressed(Key) THEN HandleBHotKeys(Key);
         IF SolutionPlot AND SolHotKeys.Pressed(Key) THEN
                     HandleSolHotKeys(Key);
         IF Input AND Sliders.Changed THEN  HandleSliders;
         IF Bifurcate THEN PlotBifurcatePoints;
         IF FindBasins THEN IdentifyNextBasin;
         IF Action AND PlotOrbit THEN MovePendulum;
      END;
      IF LightMenu THEN
         IF PendMenu.Chosen THEN HandlePendMenu;
   UNTIL ExitRequest;
   PendMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




