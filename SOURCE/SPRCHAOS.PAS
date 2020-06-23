PROGRAM ChaoticSpring;

USES Crt, Graph, CUPSMUPP, CUPS, CupsGui;

CONST
   neq = 2;

TYPE
   vector = Array[1..neq] OF real;

VAR
   SpringMenu               : TMenu;
   HotKeys                  : THotKeys;
   SolHotKeys               : THotKeys;
   BHotKeys                 : THotKeys;
   Key                      : Byte;
   y                        : Vector;
   Time                     : Real;
   StepSize                 : Real;
   Action                   : Boolean;
   PlotOrbit                : Boolean;
   Phase                    : Boolean;
   ExitRequest              : Boolean;
   LightMenu                : Boolean;
   Poincare                 : Boolean;
   Input                    : Boolean;
   SolutionPlot             : Boolean;
   PlotX                    : Boolean;
   PlotSin                  : Boolean;
   Bifurcate                : Boolean;
   NewPlot                  : Boolean;
   RA, RB, Dist, D0         : Real;
   Frequency, kOverI        : Real;
   Resistance               : Real;
   TimeOld, PhiOld          : Real;
   Phi0, PhiPrime0          : Real;
   PhiMin, PhiMax           : Real;
   xMax, xMin, yMax, yMin   : Real;
   PhiDotMin, PhiDotMax     : Real;
   Period                   : Real;
   TimeDelay                : Real;
   Y2Sign                   : Real;
   xLow, xHigh, yLow, yHigh : Real;
   xDotMin, xDotMax         : Real;
   Force                    : Real;
   ForceLow, ForceHigh      : Real;
   ForceCurrent             : Real;
   DeltaForce               : Real;
   xScreenRatio, yScreenRatio : Real;
   RxDotLow, RxDotHigh      : Real;
   xI                       : Array[1..3] OF Real;
   Lag                      : Integer;
   nMin, nMax               : Integer;
   IPeriod                  : Integer;
   BifSamples, BifPoints    : Integer;
   NRuns                    : Integer;

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

{-------------------------------------------------------------------------}

PROCEDURE SetUpSpringMenu;
VAR
   I      : Integer;
BEGIN
   With SpringMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Phase-plane');
       row(2,3, 'Poincare maps');
       row(2,4, 'Bifurcation diagram');
       row(2,5, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Enter initial conditions');
       row(3,3, 'Animate');
       row(3,4, 'Plot Phi versus time');
       row(3,5, 'Plot Sin(Phi) versus time');
       row(3,6, 'Plot Phi-prime versus time');
      Column(4, 'PhasePlot');
       row(4,1, 'See phase-plane plot');
       row(4,2, 'See Poincare map');
       row(4,3, 'See bifurcation diagram');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   SpringMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      key[4] := 'F5-Init';
      Key[5] := 'F6-Parameters';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolHotKeys;
BEGIN
   WITH SolHotKeys DO
   BEGIN
      SolHotKeys.Init(5);
      Key[1] := 'F2-NewStart';
      Key[2] := 'F3-Parameters';
      Key[3] := 'F4-CleanUp';
      Key[4] := 'F5-Rescale';
      Key[5] := 'F10-Menu';
   END;
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

{------------------------------------------------------------------------}

PROCEDURE DrawPicture;
VAR
   Radius     : Word;
BEGIN
   Message('');
   DefineViewPort(5, 0.05, 0.95, 0.7, 0.99);
   DefineScale(5, -2, 10, -3, 3);
   GraphBackColor := Blue;
   SetColor(Yellow);
   OpenViewPort(5);
   SelectScale(5);
   HideMouse;
   PlotLine(-1, 0, 9.5, 0);
   Radius := MapX(0.7) - MapX(0);
   Circle(MapX(0), MapY(0), Radius);
   Line(MapX(0), MapY(0), MapX(0)+Trunc(Radius/Sqrt(2)),
                          MapY(0)-Trunc(Radius/Sqrt(2)));
   Radius := MapX(1) - MapX(0);
   Circle(MapX(8), MapY(0), Radius);
   Line(MapX(8), MapY(0), MapX(8)+Trunc(Radius/Sqrt(2)),
                          MapY(0)-Trunc(Radius/Sqrt(2)));
   PlotLine(0, -2.5, 8, -2.5);
   PlotLine(0, -2.6, 0, -2.4);
   PlotLIne(8, -2.6, 8, -2.4);
   OutTextXY(MapX(3.9), MapY(-2), '10');
   OutTextXY(MapX(0), MapY(1), 'a');
   OutTextXY(MapX(8), MapY(1), 'b');
   OutTextXY(MapX(7), MapY(2.5), 'Driven wheel');
   SetColor(Green);
   Line(MapX(0)+Trunc((MapX(0.7) - MapX(0))/Sqrt(2)),
        MapY(0)-Trunc((MapX(0.7) - MapX(0))/Sqrt(2)),
        MapX(8)+Trunc(Radius/Sqrt(2)), MapY(0)-Trunc(Radius/Sqrt(2)));
   ShowMouse;
END;

{------------------------------------------------------------------------}

FUNCTION GetSpringData  : Boolean;
VAR
  SprData          : TInputScreen;
  xAsp, yAsp       : Word;
  xMin, xMax       : Real;
  yMax             : Real;
BEGIN
   ClearMuppetPort;
   DrawPicture;
   WITH SprData DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.01, 0.69);
      LoadLine('                Parameters for the model');
      LoadLine('     The distance between the centers is 10 units of ');
      LoadLine('  length. Enter values for the radii of the wheels,');
      LoadLine('  greater than 0.1. Their SUM MUSt be smaller than 9:');
      LoadLine('        a = {        },   b = {        }');
      LoadLine('  The unstretched length of the spring,');
      LoadLine('           1 <= D0 = {        } < 20');
      LoadLine('  The frequency of the driving term,');
      LoadLine('          0.1 <= w = {        } <= 100,');
      LoadLine('  The ratio of the spring constant divided by the');
      LoadLine('  moment of intertia of the driven wheel,');
      LoadLine('        0.1 <= k/I = {        } <= 100.');
      LoadLine('  The resistance coefficient:');
      LoadLine('            0 <= r = {        } <= 10.');
      LoadLine('  ');
      LoadLine('              [  OK  ]         [Cancel]');
      SetNumber(1, RA);
      SetNumberLimits(1, 0.1, 20);
      SetNumber(2, RB);
      SetNumberLimits(2, 0.1, 20);
      SetNumber(3, D0);
      SetNumberLimits(3, 1, 20);
      SetNumber(4, Frequency);
      SetNumberLimits(5, 0.1, 100);
      SetNumber(5, kOverI);
      SetNumberLimits(6, 0.1, 100);
      SetNumber(6, Resistance);
      SetNumberLimits(6, 0, 10);
      REPEAT
         AcceptScreen;
         GetSpringData := NOT Canceled;
         IF Canceled THEN BEGIN CloseViewPort(5); Exit; END;
         RA := GetNumber(1);
         RB := GetNumber(2);
         D0 := GetNumber(3);
         Frequency := GetNumber(4);
         Period := 2*Pi/Frequency;
         kOverI := GetNumber(5);
         Resistance := GetNumber(6);
         GetAspectRatio(xAsp, yAsp);
         xMin := -11 - Ra;
         xMax := Rb + 1;
         yMax := (Ra + Rb + 12)*(xAsp/yAsp)*(GetMaxY/GetMaxX)*0.5;
         DefineScale(1, xMin, xMax, -yMax, yMax);
      UNTIL (Ra + Rb <= 9) OR Canceled;
      Done;
   END;
   CloseViewPort(5);
END;

{------------------------------------------------------------------------}

FUNCTION GetInitialConditions  : Boolean;
VAR
   Input     : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Enter values for the initial orientation');
      LoadLine('  of the driven wheel. Use degrees.');
      LoadLine('');
      LoadLine('            0 <= Phi = {      } <= 360');
      LoadLine(' -10000 <= Phi-prime = {      } <= 10000');
      LoadLine('');
      LoadLine('          [  OK  ]           [Cancel]');
      SetNumber(1, Phi0);
      SetNumberLimits(1, 0, 360);
      SetNumber(2, PhiPrime0);
      SetNumberLimits(2, -10000, 10000);
      AcceptScreen;
      GetInitialConditions := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Phi0 := GetNumber(1);
         PhiPrime0 := GetNumber(2);
         y[1] := Phi0*Pi/180;
         y[2] := PhiPrime0*Pi/180;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
VAR
   D, DPrime, Theta     : Real;
BEGIN
   Theta := Frequency*Time;
   D := Sqrt(RA*RA + RB*RB - 2*RA*RB*Cos(y[1] - Theta) + Dist*Dist
             + 2*Dist*(RB*Cos(y[1]) - RA*Cos(Theta)));
   DPrime := (RA*RA*Sin(y[1] - Theta) - RB*Dist*Sin(y[1]))/D;
   z[1] := y[2];
   z[2] := -kOverI*(D - D0)*DPrime - Resistance*y[2];
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
      {temax := tol/10; }
      TeMax := Tol/10;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
      {RubOut(10, 10, 10, GraphBackColor); SetColor(Yellow);
      Print(10, 10, NumStr(TeMax, 10, 10)); Beep; StaticPause;}
   until temax < tol;
   yout := y;
   xout := xtemp + htemp;
   hout := h;
END;

{------------------------------------------------------------------------}

PROCEDURE EraseFigure(Theta, Phi : Real; FigColor : Word);
VAR
   StoreColor      : Word;
   Radius          : Integer;
   xA, yA, xB, yB  : Real;
BEGIN
   StoreColor := GetColor;
   SetColor(FigColor);
   xA := -10 + Ra*Cos(Theta);
   yA := Ra*Sin(Theta);
   xB := Rb*Cos(Phi);
   yB := Rb*Sin(Phi);
   PlotSymbol(xA, yA, '*');
   PlotSymbol(xB, yB, '*');
   PlotLine(xA, yA, xB, yB);
   PlotLine(-XB, -YB, xB, yB);
   PlotLine(YB, -XB, -yB, xB);
 {  PlotLine(xA, yA, -xA-20, -yA);
   PlotLine(-yA-10, xA+10, yA-10, -xA-10); }
   SetColor(StoreColor);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotFigure(Theta, Phi : Real; FigColor : Word);
VAR
   StoreColor      : Word;
   Radius          : Integer;
   xA, yA, xB, yB  : Real;
BEGIN
   StoreColor := GetColor;
   SetColor(FigColor);
   PlotLine(-10, 0, 0, 0);
   Radius := MapX(Rb) - MapX(0);
   Circle(MapX(0), MapY(0), Radius);
   Radius := MapX(Ra) - MapX(0);
   Circle(Mapx(-10), MapY(0), Radius);
   xA := -10 + Ra*Cos(Theta);
   yA := Ra*Sin(Theta);
   xB := Rb*Cos(Phi);
   yB := Rb*Sin(Phi);
   PlotSymbol(xA, yA, '*');
   PlotSymbol(xB, yB, '*');
   PlotLine(xA, yA, xB, yB);
   PlotLine(-XB, -YB, xB, yB);
   PlotLine(YB, -XB, -yB, xB);
 {  PlotLine(xA, yA, -xA-20, -yA);
   PlotLine(-yA-10, xA+10, yA-10, -xA-10); }
   SetColor(StoreColor);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveFigure;
BEGIN
   Delay(Lag);
   Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   EraseFigure(TimeOld*Frequency, PhiOld, GraphBackColor);
   PlotFigure(Time*Frequency, y[1], Yellow);
   TimeOld := Time;
   PhiOld := y[1];
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
   Radius    : Integer;
BEGIN

   GraphBackColor := DarkGray;
   OpenViewPort(1);
   SelectScale(1);
   Message('');
   Action := False;
   WITH HotKeys DO Key[1] := 'F2-Run';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   PlotOrbit := True;
   Time := 0;
   StepSize := 0.001;
   TimeOld := Time;
   y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;
   PhiOld := Phi0*Pi/180;
   PlotFigure(Time, y[1], Yellow);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotDot(xDot, yDot : Real; DotColor : Word);
VAR
   xP, yP      : Integer;
   SaveColor   : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(DotColor);
   Map(xDot, yDot, xP, yP);
   Line(xP-1, yP, xP+1, yP);
   Line(xP, yP-1, xP, yP+1);
   SetColor(SaveColor);
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
      PHotKeys.Init(10);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Run';
      Key[3] := 'F3-Faster';
      Key[4] := 'F4-Slower';
      Key[5] := 'F5-Input';
      Key[6] := 'F6-KeyInput';
      Key[7] := 'F7-TimeDelay';
      Key[8] := 'F8-CleanUp';
      Key[9] := 'F9-Parameters';
      Key[10] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Red;
   PHotKeys.HotKeyColor := Yellow;
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
      LoadLine('  Phi-prime vs. Phi (x'' vs. x.) The');
      LoadLine('  minimum and maximum values of Phi are');
      LoadLine('  -360 m and 360 n, where m and n are each');
      LoadLine('  integers between 1 and 10. Enter');
      LoadLine('         m = {   }    n = {   }');
      LoadLine('     Enter the minimum and maximum values');
      LoadLine('  of Phi-prime in degrees per second:');
      LoadLine('  Minimum: -5000 <= {      } <= 0');
      LoadLine('  Maximum:     1 <= {      } <= 5000');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, nMin);
      SetNumberLimits(1, 1, 10);
      SetNumber(2, nMax);
      SetNumberLimits(2, 1, 10);
      SetNumber(3, PhiDotMin);
      SetNumberLimits(3, -5000, 0);
      SetNumber(4, PhiDotMax);
      SetNumberLimits(4, 1, 5000);
      AcceptScreen;
      nMin := Trunc(GetNumber(1) + 0.001);
      nMax := Trunc(GetNumber(2) + 0.001);
      PhiDotMin := GetNumber(3);
      PhiDotMax := GetNumber(4);
      PhiMax := nMax*2*Pi;
      PhiMin := -nMin*2*Pi;
      Done;
   END;
   Delx := (nMin + nMax)*2*Pi/50;
   DefineScale(2, -nMin*2*Pi - Delx, nMax*2*Pi + Delx,
                   PhiDotMin*Pi/180, PhiDotMax*Pi/180);
   xMax := nMax*2*Pi;
   xMin := -nMin*2*Pi;
   yMax := PhiDotMax*Pi/180;
   yMin := PhiDotMin*Pi/180;
   {HideMouse;}
END;

{-----------------------------------------------------------------------}

PROCEDURE TestForNewPlot;
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
      LoadLine('     Would you like to start a new');
      LoadLine('  plot, or to continue the present ');
      LoadLine('  one?');
      LoadLine('        New #1   Continue #1');
      LoadLine('');
      LoadLine('             [  OK  ]');
      IF NewPlot THEN SetRadioButton(RBNames[1], 1)
                      ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN NewPlot := True
                                        ELSE NewPlot := False;
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

{-----------------------------------------------------------------------}

PROCEDURE SetUpPhasePlot;
VAR
   xSc, ySc      : Integer;
   CoordStr      : String;
   i             : Integer;
   DelY          : Integer;
   Alternate     : Boolean;
BEGIN
   ClearMuppetPort;
   GraphBackColor := DarkGray;
      IF NOT Poincare THEN OpenViewPort(3);
      IF Poincare THEN OpenViewPort(1) ELSE OpenViewPort(2);
      SelectScale(2);
      PHotKeys.Display;
      SetColor(White);
      Message('');
      PlotOrbit := True;
      Pause := True;
      IF NewPlot THEN
      BEGIN
         GetPhasePlotScale;
         Input := True;
         Time := 0;
         StepSize := 0.001;
         TimeOld := Time;
         y[1] := Phi0;
         y[2] := PhiPrime0;
         PhiOld := y[1];
      END
      ELSE
      BEGIN
         PAction := True;
         Input := False;
      END;
   HideMouse;
   IF nMin + nMax >= 11 THEN Alternate := True ELSE Alternate :=False;
   PlotLine(PhiMin, 0, PhiMax, 0);
   PlotLine(0, yMin, 0, yMax);
   FOR i := 0 TO nMin DO
   BEGIN
      IF (NOT Alternate) OR ((Alternate) AND (Trunc(I/3)=I/3))  THEN
      PlotLine(-2*Pi*i, 0, -2*Pi*i, (PhiDotMax - PhiDotMin)*Pi/(180*50));
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
      PlotLine(2*Pi*i, 0, 2*Pi*i, (PhiDotMax - PhiDotMin)*Pi/(180*50));
      IF (i = 1) AND (NOT Alternate) THEN
      OutTextXY(MapX(2*Pi*i)-XDisp(20), MapY(0)+YDisp(10),
                 NumStr(360, 3,0))
      ELSE
      IF (NOT Alternate) OR ((Alternate) AND (Trunc(I/3)=I/3))  THEN
      OutTextXY(MapX(2*Pi*i)-XDisp(30), MapY(0)+YDisp(10),
                 NumStr(i,1,0)+'*'+NumStr(360, 3,0));
   END;
   IF PhiDotMax - PhiDotMin < 1000 THEN DelY := 100 ELSE DelY := 500;
   i := 1;
   REPEAT
      PlotLine(0, DelY*i*Pi/180, (PhiMax - PhiMin)/50, DelY*i*Pi/180);
      OutTextXY(MapX(0)-XDisp(35), MapY(DelY*i*Pi/180)+YDisp(3),
                NumStr(DelY*i, 4, 0));
      i := i + 1;
   UNTIL DelY*i > PhiDotMax;
   i := 1;
   REPEAT
      PlotLine(0, -DelY*i*Pi/180, (PhiMax - PhiMin)/50, -DelY*i*Pi/180);
      OutTextXY(MapX(0)-XDisp(37), MapY(-DelY*i*Pi/180),
                NumStr(-DelY*i, 4, 0));
      i := i + 1;
   UNTIL -DelY*i < PhiDotMin;
   OutTextXY(MapX(0.9*PhiMax + 0.1*PhiMin), MapY(0)-YDisp(20), 'Degrees');
   IF nMax >= nMin THEN
   OutTextXY(MapX(0)+XDisp(10),
             MapY((0.96*PhiDotMax+0.04*PhiDotMin)*Pi/180),
                     'Degrees per second')
   ELSE
   OutTextXY(MapX(0)-XDisp(100),
             MapY((0.96*PhiDotMax+0.04*PhiDotMin)*Pi/180),
                     'Degrees per second');
   ShowMouse;
   IF NewPlot THEN Pause := True;
   NewPlot := True;
END;

PROCEDURE FindNextPoincarePoint;
VAR
   NextTime    : Real;
   XPlot       : Real;
   TempStep    : Real;
BEGIN
   SelectViewPort(1);
   SelectScale(2);
   NextTime := Time + Period;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   UNTIL Time > NextTime;
   Step(Time, NextTime - Time, 0.0000001, y, Time, TempStep, y);
   REPEAT
      IF y[1] > PhiMax THEN y[1] := y[1] - (PhiMax - PhiMin);
   UNTIL y[1] < PhiMax;
   REPEAT
      IF y[1] < PhiMin THEN y[1] := y[1] + (PhiMax - PhiMin);
   UNTIL y[1] > PhiMin;
   {xPlot := 180*y[1]/Pi;
   REPEAT IF xPlot > 360 THEN xPlot := xPlot - 720; UNTIL xPlot < 360;
   REPEAT IF xPlot < - 360 THEN xPlot := xPlot + 720; UNTIL xPlot > -360;}
   SetColor(Yellow);
   PlotSymbol(y[1], y[2], '.');
END;

PROCEDURE MovePhasePlot;
BEGIN
   Delay(Lag);
   IF Pause OR Input THEN Exit;
   SelectViewPort(3);
   SelectScale(1);
   MoveFigure;
   SelectViewPort(2);
   SelectScale(2);
         IF (y[1] < PhiMax) AND (y[1] > PhiMin) THEN
         BEGIN
            SetColor(GraphBackColor);
            PlotDot(xNew, yNew, GraphBackColor);
            SetColor(Yellow);
            PlotLine(xOld, yOld, xNew, yNew);
            PlotDot(y[1], y[2], LightBlue);
            PlotLine(xNew, yNew, y[1], y[2]);
            xOld := xNew; yOld := yNew;
            xNew := y[1]; yNew := y[2];
         END
         ELSE
         BEGIN
            IF y[1] > PhiMax THEN y[1] := y[1] - (PhiMax - PhiMin);
            IF y[1] < PhiMin THEN y[1] := y[1] + (PhiMax - PhiMin);
            SetColor(GraphBackColor);
            PlotDot(xNew, yNew, GraphBackColor);
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
 {  y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;}
   Time := 0;
   StepSize := 0.001;
   IF TimeDelay > 0 THEN
   BEGIN
      Time := 0;
      IF Poincare THEN WaitMessage.Show;
      ClearMKBuffers;
      IF NOT Poincare THEN Message('Watch the animation. Press a key to stop.');
      REPEAT
         IF NOT Poincare THEN
         BEGIN
            SelectViewPort(3);
            SelectScale(1);
            EraseFigure(Time*Frequency, y[1], DarkGray);
         END;
         StepSize := 0.005;
         Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
         IF NOT Poincare THEN
         BEGIN
            PlotFigure(Time*Frequency, y[1], Yellow);
            Delay(Trunc(Lag/5 + 1));
         END;
         IF Poincare THEN WaitMessage.UpDate;
      UNTIL (Time > TimeDelay) OR KeyPressed;
      IF KeyPressed THEN
      BEGIN
         Message('');
         PAction := False;
         ClearMKBuffers;
         ShowMouse;
         Exit;
      END;
      IF NOT Poincare THEN EraseFigure(Time*Frequency, y[1], DarkGray);
      IF Poincare THEN WaitMessage.Hide;
      Step(Time, TimeDelay - Time, 0.0000001, y, Time, StepSize, y);
      IF NOT Poincare THEN
      BEGIN
         EraseFigure(TimeOld*Frequency, PhiOld, GraphBackColor);
         PlotFigure(Time*Frequency, y[1], Yellow);
         TimeOld := Time;
         PhiOld := y[1];
      END;
      StepSize := 0.001;
   END;
   REPEAT
      IF y[1] > PhiMax THEN y[1] := y[1] - (PhiMax - PhiMin);
   UNTIL y[1] < PhiMax;
   REPEAT
      IF y[1] < PhiMin THEN y[1] := y[1] + (PhiMax - PhiMin);
   UNTIL y[1] > PhiMin;
   xOld := y[1];
   yOld := y[2];
   xNew := y[1];
   yNew := y[2];
   StepSize:= 0.01;
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
      IF NOT Poincare THEN OpenViewPort(3);
      IF Poincare THEN SelectViewPort(1) ELSE SelectViewPort(2);
      SelectScale(2);
      SetColor(GraphBackColor);
      IF Abs(y[1])+Abs(y[2]) > 0.03 THEN PlotDot(y[1], y[2], GraphBackColor);
     { SetColor(Yellow);
      IF NOT Input THEN PlotLine(xOld, yOld, xNew, yNew);}
      Inside := False;
      ShowMouse;
            SetColor(White);
      Message('     Click on a starting point');
      REPEAT
         IF Poincare THEN MousePosn(y[1], y[2], 1, 2, Inside)
                     ELSE MousePosn(y[1], y[2], 2, 2, Inside);
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
      Phi0 := y[1]*180/Pi;
      PhiPrime0 := y[2]*180/Pi;
      xOld := y[1];
      xNew := y[1];
      yOld := y[2];
      yNew := y[2];
      Time := 0;
      StepSize := 0.001;
      PAction := True;
      HideMouse;
      StartPhasePlot;
      Input := False;
END;

{------------------------------------------------------------------------}

PROCEDURE KeyInput;
VAR
   InputInit    : TInputScreen;
BEGIN
   Message('');
{   ShowMouse;}
   IF Poincare THEN SelectViewPort(1) ELSE SelectViewPort(2);
   SelectScale(2);
   SetColor(GraphBackColor);
   IF Abs(y[1]) + Abs(y[2]) > 0.03 THEN PlotDot(y[1], y[2], GraphBackColor);
 {  SetColor(Yellow);
   PlotLine(xOld, yOld, xNew, yNew); }
   WITH InputInit DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.33, 0.67);
      LoadLine('');
      LoadLine('     Enter new conditions. Use degrees.');
      LoadLine('');
      LoadLine('  Phi = {       },  PhiPrime = {       }');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, Phi0);
      SetNumber(2, PhiPrime0);
      SetNumberLimits(1, -360*nMin, 360*nMax);
      SetNumberLimits(2, PhiDotMin, PhiDotMax);
      AcceptScreen;
      Phi0 := GetNumber(1);
      PhiPrime0 := GetNumber(2);
      Done;
   END;
   y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;
   SetColor(Yellow);
   IF NOT Poincare THEN OpenViewPort(3);
   IF Poincare THEN SelectViewPort(1) ELSE SelectViewPort(2);
   SelectScale(2);
   SetColor(GraphBackColor);
   IF Abs(y[1])+Abs(y[2]) > 0.03 THEN PlotDot(y[1], y[2], GraphBackColor);
   Time := 0;
   StepSize := 0.001;
   PAction := True;
   HideMouse;
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
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 10;
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
                    HideMouse;
                 END
                 ELSE
                 BEGIN
                    Pause := True;
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                    ShowMouse;
                 END;
              END;
           3: IF Lag - DelLag > 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
           4: Lag := Lag + DelLag;
           5: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                    ShowMouse;
                 END;
                 Pause := True;
                 PAction := False;
                 SelectStart;
              END;
           6: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                    ShowMouse;
                 END;
                 Pause := True;
                 PAction := False;
                 KeyInput;
              END;
           7: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                    ShowMouse;
                 END;
                 Pause := True;
                 PAction := False;
                 GetNewTimeDelay;
                 {SetUpPhasePlot;}
                 PlotOrbits := True;
                 {SelectStart;}
              END;
           8: BEGIN
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                    ShowMouse;
                 END;
                 Pause := True;
                 PAction := False;
                 TestForNewPlot;
                 SetUpPhasePlot;
                 PlotOrbits := True;
                 {SelectStart;}
              END;
           9: BEGIN
                 ShowMouse;
                 GetSpringData;
                 IF NOT Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Run';
                    PHotKeys.BackColor := Red;
                    PHotKeys.Display;
                 END;
                 Pause := True;
                 PAction := False;
                 SetUpPhasePlot;
                 PlotOrbits := True;
              END;
           10: BEGIN
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
   SetUpPHotKeys;
   SetUpPhasePlot;
   GetNewTimeDelay;
   Message('Please enter starting conditions using <F5> or <F6>');
   PlotOrbits := True;
   Time := 0;
   StepSize := 0.001;
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
         PlotDot(xOld, yOld, Red);
      END;
   UNTIL Not PlotOrbits;
   LightMenu := True;
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

{------------------------------------------------------------------------}

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
      PrintXY(0.2, 0.9, 'Sin(Phi)');
   END
   ELSE
   BEGIN
      OutTextXY(MapX(xLow-(xHigh-xLow)/15), MapY(2*Pi), '2*Pi');
      OutTextXY(MapX(xLow-(xHigh-xLow)/13), MapY(-2*Pi), '-2*Pi');
      PrintXY(0.1, 0.93, 'Phi');
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
   y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;
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
      DefineInputPort(0.2, 0.8, 0.35, 0.65);
      LoadLine('');
      LoadLine('     Enter new conditions. Use degrees.');
      LoadLine('');
      LoadLine('   Phi = {       },  Phi-Prime = {       }');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, Phi0);
      SetNumber(2, PhiPrime0);
      SetNumberLimits(1, 0, 360);
      SetNumberLimits(2, -10000, 10000);
      AcceptScreen;
      Phi0 := GetNumber(1);
      PhiPrime0 := GetNumber(2);
      Period := 2*Pi/Frequency;
      Done;
   END;
   y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;
   xOld := xLow;
   IF PlotSin THEN yOld := Sin(y[1]) ELSE yOld := y[1];
   Time := xLow;
   StepSize:= 0.1;
   HideMouse;
   Message('        Hit a key to stop a plot');
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      IF PlotSin THEN PLotLine(xOld, yOld, Time, Sin(y[1]))
                 ELSE PLotLine(xOld, yOld, Time, y[1]);
      xOld := Time;
      IF PlotSin THEN yOld := Sin(y[1]) ELSE yOld := y[1];
   UNTIL (Time > xHigh) OR KeyPressed;
   Message('');
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
      PrintXY(0.2, 0.9, 'Sin(Phi)');
   END
   ELSE
   BEGIN
      OutTextXY(MapX(xLow-(xHigh-xLow)/15), MapY(2*Pi), '2*Pi');
      OutTextXY(MapX(xLow-(xHigh-xLow)/13), MapY(-2*Pi), '-2*Pi');
      PrintXY(0.1, 0.93, 'Phi');
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
         SetNumber(5, Phi0);
         SetNumber(6, PhiPrime0);
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
            Phi0 := GetNumber(5);
            PhiPrime0 := GetNumber(6);
         END;
         Done;
      END;
      IF (xHigh <= xLow) OR (yHIgh <= yLow) AND (NOT Quit) THEN
         Announce('Extreme coordinates out of order. Try again.');
   UNTIL (xHigh > xLow) AND (yHigh > yLow) OR Quit;
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
         LoadLine('  Minimum Phi-prime: {      } >= -50, <= 0,');
         LoadLine('  Maximum Phi-prime: {      } <= 50, >= 0.');
         LoadLine(' (For the plot, Phi-prime is radians/second.)');
         LoadLine('');
         LoadLine('  Enter initial values, using degrees:');
         LoadLine('  x = {      }, xprime = {      }.');
         LoadLine('');
         LoadLIne('          [  OK  ]    [Cancel]');
         SetNumber(1, xLow);
         SetNumberLimits(1, 0, 500);
         SetNumber(2, xHigh);
         SetNumberLimits(2, 0, 1000);
         SetNumber(3, XDotMin);
         SetNumberLimits(3, -50, 0);
         SetNumber(4, XDotMax);
         SetNumberLimits(4, 0, 50);
         SetNumber(5, Phi0);
         SetNumber(6, PhiPrime0);
         AcceptScreen;
         SelectPlotScale2 := NOT Canceled;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            Quit := False;
            xLow := GetNumber(1);
            xHigh := GetNumber(2);
            XDotMin := GetNumber(3);
            XDotMax := GetNumber(4);
            yLow := GetNumber(3);
            yHigh := GetNumber(4);
            Phi0 := GetNumber(5);
            PhiPrime0 := GetNumber(6);
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
         SetNumber(3, Phi0);
         SetNumber(4, PhiPrime0);
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
            Phi0 := GetNumber(3);
            PhiPrime0 := GetNumber(4);
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
   PrintXY(0.1, 0.93, 'Phi-prime');
   y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;
   xOld := xLow;
   yOld := y[2];
   Time := xLow;
   Message('        Hit a key to stop a plot');
   StepSize:= 0.1;
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      PLotLine(xOld, yOld, Time, y[2]);
      xOld := Time;
      yOld := y[2];
   UNTIL (Time > xHigh) OR KeyPressed;
   Message('');
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
      DefineInputPort(0.2, 0.8, 0.35, 0.65);
      LoadLine('');
      LoadLine('     Enter new conditions. Use degrees.');
      LoadLine('');
      LoadLine('    Phi = {       },  Phi-Prime = {       }');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, Phi0);
      SetNumber(2, PhiPrime0);
      SetNumberLimits(1, 0, 36);
      SetNumberLimits(2, -10000, 10000);
      AcceptScreen;
      Phi0 := GetNumber(1);
      PhiPrime0 := GetNumber(2);
      Done;
   END;
   y[1] := Phi0*Pi/180;
   y[2] := PhiPrime0*Pi/180;
   xOld := xLow;
   yOld := y[2];
   Time := xLow;
   StepSize:= 0.1;
   HideMouse;
   Message('        Hit a key to stop a plot');
   REPEAT
      Step(Time, StepSize, 0.00000001, y, Time, StepSize, y);
      PLotLine(xOld, yOld, Time, y[2]);
      xOld := Time;
      yOld := y[2];
   UNTIL (Time > xHigh) OR KeyPressed;
   Message('');
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
   PrintXY(0.1, 0.93, 'Phi-prime');
   ShowMouse;
   RePlotSolution2;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleSolHotKeys(Key : Byte);
BEGIN
   CASE Key OF
   1: IF PlotX THEN RePlotSolution ELSE RePlotSolution2;
   2: BEGIN
         GetSpringData;
         IF PlotX THEN ReDrawAxes ELSE ReDrawAxes2;
      END;
   3: IF PlotX THEN ReDrawAxes ELSE ReDrawAxes2;
   4: IF PlotSin THEN
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
   5: BEGIN
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
            LoadLine('    In this utility, the values of the parameters w, for');
            LoadLine(' the forcing frequency, and r, for the resistance, will');
            LoadLine(' be kept fixed, and the parameter f = k/I will be sampled');
            LoadLine(' n times between two extreme values, between 0 and 10.');
            LoadLine('');
            LoadLine(' Enter limits for f: Lower: {       }.  Upper: {       }');
            LoadLine(' Number of samples:   10 <= {       } <= 500');
            LoadLine('');
            LoadLine('    dPhi/dt will be sampled at the start of each cycle. For');
            LoadLine(' the vertical scale enter the limits, using radians:');
            LoadLine('                     Lower: {       }   Upper: {       }');
            LoadLine('');
            LoadLine('    To avoid transient terms p periods (2*Pi/w) are computed');
            LoadLine(' before data are recorded; then data from q periods are found.');
            LoadLine('  Enter values for p:  0 <= {       } <= 50');
            LoadLine('                   q: 10 <= {       } <= 100');
            LoadLine('');
            LoadLine('         [ Help ]         [  OK  ]         [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'PendBifurcationInputHelp');
            SetNumber(1, ForceLow);
            SetNumber(2, ForceHigh);
            SetNumber(3, BifSamples);
            SetNumber(4, RxDotLow);
            SetNumber(5, RxDotHigh);
            SetNumber(6, IPeriod);
            SetNumber(7, BifPoints);
            SetNumberLimits(1, 0, 10);
            SetNumberLimits(2, 0, 10);
            SetNumberLimits(3, 10, 500);
            SetNumberLimits(6, 0, 50);
            SetNumberLimits(7, 10, 100);
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
            ForceLow := GetNumber(1);
            ForceHigh := GetNumber(2);
            BifSamples := Trunc(GetNumber(3) + 0.0001);
            RxDotLow := GetNumber(4);
            RxDotHigh := GetNumber(5);
            Iperiod := Trunc(GetNumber(6) + 0.0001);
            BifPoints := Trunc(GetNumber(7) + 0.0001);
         Done;
      END;
      IF (NOT Quit) AND (ForceLow >= ForceHigh) OR (RxDotLow >= RxDotHigh) THEN
      BEGIN
         InputOK := False;
         IF NOT Quit THEN
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
      DefineInputPort(0.17, 0.83, 0.25, 0.75);
      LoadLine('');
      LoadLIne('       More Data for a Bifurcation Diagram');
      LoadLine('');
      LoadLine('    All runs will be made with the same starting');
      LoadLine(' conditions. Phi-prime will be zero.');
      LoadLine('');
      LoadLine('    Enter the initial value of Phi, in degrees:');
      LoadLine('');
      LoadLine('          180 < Phi = {      } <= 180');
      LoadLine('');
      LoadLine('                    [  OK  ]');
      SetNumber(1, Phi0);
      SetNumberLimits(1, -180, 180);
      AcceptScreen;
      Phi0 := GetNumber(1);
      xI[1] := Phi0*Pi/180;
      NRuns := 1;
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
   kOverI := Force;
   FOR IRuns := 1 TO NRuns DO
   BEGIN
      Time := 0;
      y[1] := xI[IRuns];
      y[2] := 0;
      StepSize := 0.001;
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time > IPeriod*Period;
      StepSize  := IPeriod*Period - Time;
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.001;
      Time := 0;
      FOR i := 1 TO BifPoints DO
      BEGIN
         REPEAT
            Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
         UNTIL Time + Stepsize > Period;
         Step(Time, Period-Time, 0.0000001, y, Time, StepSize, y);
         StepSize := 0.001;
         Time := 0;
         Theta := y[2];
         PutPixel(MapX(ForceCurrent), MapY(Theta), White);
      END;
   END;
   ForceCurrent := ForceCurrent + DeltaForce;
   kOverI := ForceCurrent;
   IF ForceCurrent > ForceHigh THEN
   BEGIN
      Bifurcate := False;
      BHotKeys.Clear;
      LightMenu := True;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleSpringMenu;
BEGIN
   With SpringMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpChaos.hlp', 'AboutForceWheelProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HlpChaos.hlp', 'AboutForceWheelModel1');
                  ShowHelp('HlpChaos.hlp', 'AboutForceWheelModel2');
               END;
            2: ShowHelp('HlpChaos.hlp','PhasePlaneHelp');
            3: ShowHelp('HlpChaos.hlp','PoincareMapsHelp');
            4: BEGIN
                  ShowHelp('HlpChaos.hlp','PendBifurcationHelp1');
                  ShowHelp('HlpChaos.hlp','PendBifurcationHelp2');
                  ShowHelp('HlpChaos.hlp','PendBifurcationHelp3');
               END;
            5: BEGIN
                  ShowHelp('WalkThru.hlp', 'ForceWheel1');
                  ShowHelp('WalkThru.hlp', 'ForceWheel2');
                  ShowHelp('WalkThru.hlp', 'ForceWheel3');
                  ShowHelp('WalkThru.hlp', 'ForceWheel4');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  PLotOrbit := False;
                  IF NOT GetSpringData THEN LightMenu := True
               END;
            2: BEGIN
                  PLotOrbit := False;
                  IF NOT GetInitialConditions THEN LightMenu := True
               END;
            3: BEGIN
                  {Phase := False;}
                  LightMenu := False;
                  SetUpPicture;
               END;
            4: BEGIN
                  IF SelectPlotScale THEN
                  BEGIN
                     PlotSin := False;
                     PlotSolution;
                     PlotX := True;
                  END;
               END;
            5: BEGIN
                  IF SelectSinPlotScale THEN
                  BEGIN
                     PlotSin := True;
                     PlotSolution;
                     PlotX := True;
                  END;
               END;
            6: BEGIN
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
            3: BEGIN
                  IF NOT SetUpBifurcation THEN LightMenu := True
               ELSE
                  BEGIN
                     SetUpBifurcation2;
                     SetUpBifurcationScreen;
                  END;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag       : Word;
BEGIN
   DelLag := 10;
   CASE Key OF
       1: BEGIN
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
             IF Lag - DelLag > 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
          END;
       3: Lag := Lag + DelLag;
       4: BEGIN
             IF Action THEN
             BEGIN
                Action := False;
                WITH HotKeys DO Key[1] := 'F2-Run';
                HotKeys.BackColor := Red;
                HotKeys.Display;
             END;
             IF GetInitialConditions THEN SetUpPicture;
          END;
       5: BEGIN
             IF Action THEN
             BEGIN
                Action := False;
                WITH HotKeys DO Key[1] := 'F2-Run';
                HotKeys.BackColor := Red;
                HotKeys.Display;
             END;
             IF GetSpringData THEN SetUpPicture ELSE SetUpPicture;
          END;
       6: BEGIN
             PlotOrbit := False;
             Action := False;
             HotKeys.Clear;
             CloseViewPort(1);
             LightMenu := True;
          END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleBHotKeys(Key : Byte);
BEGIN
   CASE Key OF
   1: BEGIN
         Bifurcate := False;
         Action := False;
         LightMenu := True;
         ShowMouse;
         BHotKeys.Clear;
      END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUp;

BEGIN
   SetUpHotKeys;
   SetUpSolHotKeys;
   SetUpBHotKeys;
   DefineViewPort(1, 0.07, 0.94, 0.07, 0.94);
   DefineScale(1, -14, 4, -7, 7);
   DefineViewPort(2, 0.2, 1, 0.1, 0.95);
   DefineScale(2, -400, 400, -5, 5);
   DefineViewPort(3, 0, 0.2, 0.35, 0.55);
   PhiDotMin := -400;
   PhiDotMax := 400;
   nMax := 1;
   nMin := 1;
   PhiMax := 2*Pi;
   PhiMin := - 2*Pi;
   xMax := nMax*2*Pi;
   xMin := -nMin*2*Pi;
   yMax := PhiDotMax*Pi/180;
   yMin := PhiDotMin*Pi/180;
   DefineScale(2, -2*Pi, 2*Pi,
                   PhiDotMin*Pi/180, PhiDotMax*Pi/180);
   xDotMin := -5;
   xDotMax := 20;
   xLow := 0;
   xHigh := 20;
   yLow := -10;
   yHigh := 10;
   ExitRequest := False;
   LightMenu := True;
   PlotOrbit := False;
   Action := False;
   Poincare := False;
   NewPlot := True;
   Lag := 100;
   RA := 3;
   RB := 1;
   Dist := 10;
   D0 := 4;
   Frequency := 10;
   Period := 2*Pi/Frequency;
   kOverI := 2;
   Resistance := 0.5;
   ForceLow := 1;
   ForceHigh := 5;
   BifSamples := 100;
   RxDotLow := -10;
   RxDotHigh := 10;
   IPeriod := 0;
   BifPoints := 30;
   y[1] := 0;
   y[2] := 10;
   Time := 0;
   StepSize := 0.001;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   Hello('HlpChaos.hlp', 'AboutForceWheelProgram');
END;

{------------------------------------------------------------------------}



BEGIN
   CUPSInit;
   SetUp;
   SetUpSpringMenu;
   REPEAT
      CheckForEvents;
      IF NOT Phase THEN
      BEGIN
         IF NOT SolutionPlot AND Hotkeys.Pressed(Key) THEN
                     HandleHotKeys(Key);
         IF SolutionPlot AND SolHotKeys.Pressed(Key) THEN
                     HandleSolHotKeys(Key);
         IF Bifurcate AND BHotKeys.Pressed(Key) THEN HandleBHotKeys(Key);
         IF Bifurcate THEN PlotBifurcatePoints;
         IF Action AND PlotOrbit THEN MoveFigure;
      END;
      IF LightMenu AND SpringMenu.Chosen THEN HandleSpringMenu;
   UNTIL ExitRequest;
   CUPSDone;
   SpringMenu.Done;
END.
