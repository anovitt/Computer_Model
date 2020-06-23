Program TheMotionOfASimplePendulum;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z: Vector;
   PendMenu: TMenu;
   HotKeys: THotKeys;
   Drag, TimeRatio        : Real;
   Length                 : Real;
   Lag                    : Integer;
   StoreAngle             : Real;
   Time, h                : Real;
   StepSize               : Real;
   Theta                  : Real;
   ThetaDot               : Real;
   Y2Sign                 : Real;
   MaxTime                : Real;
   TimeStopped            : Real;
   xMax, xMin, yMax, yMin : Real;
   Action                 : Boolean;
   PLotOrbit              : Boolean;
   Phase                  : Boolean;
   LightMenu              : Boolean;
   ExitRequest            : Boolean;
   DryFriction            : Boolean;
   Input                  : Boolean;
   DField                 : Boolean;
   Key                    : Byte;
   Sliders                : TSliders;
   ThetaMin, ThetaMax        : Real;
   NMax, NMin                : Integer;
   ThetaDotMin, ThetaDotMax  : Real;
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
   envir.reset;
END;

{---------------------------------------------------------------------------}

PROCEDURE SetUpPendMenu;
VAR
   I      : Integer;
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
       row(2,1, 'The model');
       row(2,2, 'The direction field');
       row(2,3, 'Walk-through');
      Column(3, 'Data');
       row(3,1, 'Enter parameters');
      Column(4, 'Animate');
       row(4,1, 'Swing the pendulum');
       row(4,2, 'Time plots');
       row(4,3, 'Phase-space');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   {PendMenu.Display; }
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(3);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Accept';
      Key[3] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

FUNCTION GetPendData :  Boolean;
CONST
   RBNames : string = '12345678';
VAR
   cd, CrossSection, Mass: Real;
   PendDat               : TInputScreen;
BEGIN
   Message('');
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.12, 0.87, 0.08, 0.9);
      LoadLine('');
      LoadLine('        Data for the Motion of a Simple Pendulum');
      LoadLine('');
      LoadLine('      x is the angle that the pendulum makes with the');
      LoadLIne('   downward vertical. The model is:');
      LoadLine('   (a)     d(dx/dt)/dt = - k(dx/dt) - (g/L)sin(x)');
      LoadLine('   for friction proportional to the angular rate, or');
      LoadLine('   (b)  d(dx/dt)/dt = - k*Sign(dx/dt) - (g/L)sin(x)');
      LoadLine('   for dry friction.');
      LoadLine('');
      LoadLIne('   Enter the length of the pendulum. 0.1 <= L <= 10.');
      LoadLine('                    L = {       } meters');
      LoadLine('');
      LoadLine('   Enter the parameter for the drag term. 0 <= k <= 10.');
      LoadLine('                    k = {       } 1/sec');
      LoadLine('');
      LoadLIne('       Choose:    Case (a) #1       Case (b) #1');
      LoadLine('');
      LoadLIne('       [ Help ]         [  OK  ]          [Cancel]');
      SetHelpFile('HelpPend.hlp', 'SimplePendInputHelp');
      SetNumber(1, Length);
      SetNumberLimits(1, 0.1, 10);
      SetNumber(2, Drag);
      SetNumberLimits(2, 0, 10);
      IF NOT DryFriction THEN SetRadioButton(RBNames[1], 1)
                         ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      GetPendData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Length := GetNumber(1);
         TimeRatio := 1/Sqrt(Length);
         Drag := TimeRatio*GetNumber(2);
         y[2] := 30;                {Default values.}
         y[1] := 50;
         y[1] := y[1]*Pi/180;
         y[2] := y[2]*Pi/180;
         StoreAngle := 0;
         IF GetRadioButton(RBNames[1]) = 1 THEN
         DryFriction := False ELSE DryFriction := True;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
begin
   z[1] := y[2];
   IF DField THEN
   BEGIN
      IF y[2] > 0 THEN Y2Sign := 1
                  ELSE Y2Sign := -1;
   END;
   IF NOT DryFriction THEN
         z[2] := - Drag*y[2] - Sin(y[1])
      ELSE
         z[2] := - Y2Sign*Drag - Sin(y[1]);
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
   SaveStepSize := h;
   REPEAT
      Count := Count + 1;
      Fun(Time, Y, Z);
      IF Abs(Z[2]) > 0.001 THEN
      BEGIN
         h := - Y[2]/Z[2];
         Step(Time, h, 0.001, Y, Time, h, Y);
      END;
   UNTIL (ABS(Y[2]) < 0.0001) OR (COUNT = 10) OR (Z[2] = 0);
   Y2Sign := - Y2Sign;
   h := SaveStepSize;
END;


{-------------------------------------------------------------------------}

PROCEDURE PlotPend(Angle: Real; SColor: Word);
VAR
   Radius: Integer;
   xSc, ySc: Integer;
   xEnd, yEnd: Real;
BEGIN
   Radius := Trunc(10*GetMaxX/639);
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
   Seconds := Trunc(Time*TimeRatio);
   Minutes := Trunc(Seconds/60);
   IF Minutes >= 1 THEN Seconds := Seconds - 60*Minutes;
   Hours := Trunc(Minutes/60);
   IF Hours >= 1 THEN Minutes := Minutes - 60*Hours;
   rubOut(1,21,5,Black);
   print (2,21,NumStr(Hours,3,0));
   rubOut(11,21,7,Black);
   print (12,21,NumStr(Minutes,3,0));
   rubOut(25,21,7,Black);
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
   ClearMuppetPort;
   HideCursor;
   PlotOrbit := False;
   Message('');
   OpenViewPort(1);
   SelectScale(1);
   Action := False;
   Input := True;
   SetUpHotKeys;
   Message('Use the sliders to choose initial conditions. Press <Accept> when ready');
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   Sliders.Create(1, 0, 360, ThetaDot, 0.95, 0.2, 0.8, 2, '0', '360', 'x'' deg/sec', True);
   Sliders.Create(2, 0, 360, Theta, 0.05, 0.2, 0.8, 2, '0', '360', 'x deg', True);
   Sliders.DrawAll;
   PlotPend(0, Yellow);
   GraphBackColor := DarkGray;
   SelectViewPort(1);
       TimeStr := ('     hours       minutes       seconds');
      print(1,21,TimeStr);
   {PrintTime(0); }
   ShowCursor;   
END;

{------------------------------------------------------------------------}

PROCEDURE MovePendulum;
BEGIN
   Delay(Lag);
   PlotPend(y[1], Black);
   Step(Time, h, 0.0000001, y, Time, h, y);
   IF DryFriction AND (y[2]*Y2Sign < 0) THEN FindTopOfSwing;
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
   h := 1;
   PlotOrbit := True;
   Action := False;
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   StoreAngle := y[1];
   IF y[2] > 0 THEN Y2Sign := 1;
   IF y[2] < 0 THEN Y2Sign := -1;
   IF y[2] = 0 THEN
   BEGIN
      IF y[1] > 0 THEN Y2Sign := -1
                  ELSE Y2Sign := 1;
   END;
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
   IF y[2] > 0 THEN Y2Sign := 1;
   IF y[2] < 0 THEN Y2Sign := -1;
   IF y[2] = 0 THEN
   BEGIN
      IF y[1] > 0 THEN Y2Sign := -1
                  ELSE Y2Sign := 1;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawDirectionField;
VAR
   DelX, DelY, Length       : Integer;
   DX, DY, DL               : Real;
   Slope                    : Real;
   x, y                     : Real;
   xEnd, yEnd               : Real;
   i, j                     : Integer;
   xCol, yRow               : Integer;
   Fy, Fz                   : Vector;
   Factor                   : Real;

PROCEDURE GetDFieldData;
VAR
   DFieldData    : TInputScreen;
BEGIN
   WITH DFieldData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.75);
      LoadLine('      Data for the Direction Field');
      LoadLine('');
      LoadLine('     Arrows will be plotted using a grid of');
      LoadLine('  points in the x-y plane. Enter the numbers');
      LoadLine('  grid points along the axes; these must lie ');
      LoadLine('  between 10 and 50.');
      LoadLine('');
      LoadLine('       x-axis: {   }    y-axis: {   }');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, XCol);
      SetNumber(2, YRow);
      SetNumberLimits(1, 10, 50);
      SetNumberLimits(2, 10, 50);
      AcceptScreen;
      XCol := Trunc(GetNumber(1) + 0.0001);
      YRow := Trunc(GetNumber(2) + 0.0001);
      Done;
   END;
END;

{------------------------------------------------------------------------}
   
Procedure Arrow(xa, ya, xb, yb: Real; Length: Integer);
VAR
   x, y: Integer;
   Fraction: Real;
   sxa, sya, sxb, syb   : Integer;
   Delx, Dely           : Integer;
   Ratio                : Real;
BEGIN
   sxa := MapX(xa);
   sya := MapY(ya);
   sxb := MapX(xa+xb/2);
   syb := MapY(ya+yb/2);
   Ratio := 0.5*Length/Sqrt((sxa-sxb)*(sxa-sxb) + (sya-syb)*(sya-syb));
   Delx := Trunc(Ratio*(sxb-sxa));
   Dely := Trunc(Ratio*(syb-sya));
   sxb := sxa + Delx;
   syb := sya + Dely;
   sxa := sxa - Delx;
   sya := sya - Dely;
   SetColor(Yellow);
   Fraction := 0.2;
   Line(sxa, sya, sxb, syb);
   x := Trunc(sxb - Fraction*(sxb - sxa) + Fraction*(syb - sya));
   y := Trunc(syb - Fraction*(syb - sya) - Fraction*(sxb - sxa));
   Line(sxb, syb, x, y);
   x := Trunc(sxb - Fraction*(sxb - sxa) - Fraction*(syb - sya));
   y := Trunc(syb - Fraction*(syb - sya) + Fraction*(sxb - sxa));
   Line(sxb, syb, x, y);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotDot(xDot, yDot : Real);
VAR
   xC, yC  : Integer;
BEGIN
   xC := MapX(xDot);
   yC := MapY(yDot);
   PutPixel(xC, yC, White);
   PutPixel(xC+1, yC, White);
   PutPixel(xC-1, yC, White);
   PutPixel(xC, yC+1, White);
   PutPixel(xC, yC-1, White);
END;


{------------------------------------------------------------------------}


BEGIN
   xCol := 25;
   yRow := 25;
   DField := True;
   GetDFieldData;
   HideMouse;
   SetColor(Yellow);
   DelX := Trunc((MapX(xMax) - MapX(xMin))/xCol);
   DelY := Trunc(Abs(MapY(yMax) - MapY(yMin))/yRow);
   Length := DelX;
   DX := (xMax - xMin)/xCol;
   DY := (yMax - yMin)/yRow;
   DL := DX;
   IF DY < DL THEN DL := DY;
   IF Length > DelY THEN Length := DelY;
   Length := Trunc(Length*0.9);
   FOR i := 1 TO xCol DO
   BEGIN
      x := xMin + i*DX;
      FOR j := 1 TO yRow DO
      BEGIN
         y := yMin + j*DY;
         Fy[1] := x;
         Fy[2] := y;
         Fun(Time, Fy, Fz);
         Factor := Sqrt(Fz[1]*Fz[1] + Fz[2]*Fz[2]);
         IF Factor > 0.001 THEN
         BEGIN
            xEnd := DL*Fz[1]/Factor;
            yEnd := DL*Fz[2]/Factor;
            Arrow(x, y, xEnd, yEnd, Length);
         END;
         PlotDot(x, y);
      END;
   END;
   PlotOrbit := True;
   DField := False;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotPoint(xp, yp: Real; PColor: Word);
VAR
   SaveColor       : Word;
   xPix, yPix      : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(PColor);
   Map(xp, yp, xPix, yPix);
   Line(xPix-1, yPix-1, xPix+1, yPix-1);
   Line(xPix-1, yPix, xPix+1, yPix);
   Line(xPix-1, yPix+1, xPix-1, yPix+1);
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE SeePhaseSpace;
VAR
  PHotKeys                  : THotKeys;
  Pause, PAction, PlotOrbits: Boolean;
  xOld, yOld, xNew, yNew    : Real;

PROCEDURE HandlePHotKeys(Key: Byte); FORWARD;

PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Pause';
      Key[3] := 'F3-Input';
      Key[4] := 'F4-DField';
      Key[5] := 'F5-CleanUp';
      Key[6] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Blue;
   PHotKeys.HotKeyColor := Yellow;
   PHotKeys.Display;
END;

{-----------------------------------------------------------------------}

PROCEDURE GetPhasePlotScale;
VAR
   PhasePlotData        : TInputScreen;
   Delx                 : Real;
BEGIN
   WITH PhasePlotData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.2, 0.8);
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
   i       : Integer;
   Alternate : Boolean;
BEGIN
   ClearMuppetPort;
   GetPhasePlotScale;
   HideCursor;
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   SetUpPHotKeys;
   SetColor(White);
   IF nMin + nMax >= 11 THEN Alternate := True ELSE Alternate :=False;
   PlotLine(ThetaMin, 0, ThetaMax, 0);
   PlotLine(0, ThetaDotMin, 0, ThetaDotMax);
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
   ShowCursor;
END;


PROCEDURE MovePhasePlot;
BEGIN
   Delay(Lag);
   SelectViewPort(3);
   SelectScale(1);
   PlotPend(y[1], DarkGray);
   Step(Time, h, 0.0000001, y, Time, h, y);
   IF DryFriction AND (y[2]*Y2Sign < 0) THEN FindTopOfSwing;
   PlotPend(y[1], White);
   {xNew := y[1]*180/Pi;
   yNew := y[2];}
   SelectViewPort(2);
   SelectScale(2);
   IF (y[1] < ThetaMax) AND (y[1] > ThetaMin) THEN
   BEGIN
      PlotPoint(xNew, yNew, Red);
      {SetColor(Red); PlotSymbol(xNew, yNew, 'o');}
      SetColor(Yellow);
      PlotLine(xOld, yOld, xNew, yNew);
      PlotPoint(y[1], y[2], LightBlue);
     { PlotSymbol(y[1], y[2], 'o');}
      PlotLine(xNew, yNew, y[1], y[2]);
      xOld := xNew; yOld := yNew;
      xNew := y[1]; yNew := y[2];
   END
   ELSE
   BEGIN
      IF y[1] > ThetaMax THEN y[1] := y[1] - (ThetaMax - ThetaMin);
      IF y[1] < ThetaMin THEN y[1] := y[1] + (ThetaMax - ThetaMin);
      PlotPoint(xNew, yNew, Red);
      SetColor(Red);
      {PlotSymbol(xNew, yNew, 'o');}
      SetColor(Yellow);
      PlotLine(xOld, yOld, xNew, yNew);
      xOld := y[1];
      xNew := y[1];
      yOld := y[2];
      yNew := y[2];
   END;
END;


PROCEDURE StartPhasePlot;
BEGIN
   Pause := False;
   xOld := y[1];
   yOld := y[2];
   Time := 0;
   h := 1;
   GraphBackColor := DarkGray;
   OpenViewPort(3);
   SelectViewPort(3);
   SelectScale(1);
END;

PROCEDURE SelectStart;
VAR
   Inside                : Boolean;
   a                     : Integer;
   xm, ym, button        : Integer;
   savey1, savey2        : Real;
BEGIN
      HideCursor;
      SetColor(Yellow);
      SelectViewPort(2);
      SelectScale(2);
      SetColor(Red);
      PlotPoint(y[1], y[2], Red);
      {PlotSymbol(y[1], y[2], 'o');}
      SetColor(Yellow);
      PlotLine(xOld, yOld, xNew, yNew);
      Inside := False;
      Message('Click on a starting point in the window');
      SetColor(White);
      REPEAT
         ShowMouse;
         {WaitOnMouseClick; }
         MousePosn(y[1], y[2], 2, 2, Inside);
         MouseGlobalPosn(xm, ym, Button);
         IF NOT Inside THEN
         RubOutXY(0.6, 0.982, 20, Blue)
         ELSE
         IF Abs(Savey1 - y[1]) + Abs(Savey2 - y[2]) > 0.01 THEN
         BEGIN
            RubOutXY(0.6, 0.982, 20, Blue);
            PrintXY(0.6, 0.982, '('+NumStr(180*y[1]/Pi, 5, 0)+','
                                  +NumStr(180*y[2]/Pi, 5, 0)+')');
            SaveY1 := y[1];
            SaveY2 := y[2];
         END;
      UNTIL InSide AND (Button <> 0);
      Message('');
      SetColor(Yellow);
         IF y[2] > 0 THEN Y2Sign := 1;
         IF y[2] < 0 THEN Y2Sign := -1;
         IF y[2] = 0 THEN
         BEGIN
            IF y[1] > 0 THEN Y2Sign := -1
                        ELSE Y2Sign := 1;
         END;
        { RubOut(5, 21, 50, Black);
         IF Inside THEN
         BEGIN  }
            xOld := y[1];
            xNew := y[1];
            yOld := y[2];
            yNew := y[2];
            PAction := True;
            StartPhasePlot;
        { END
         ELSE
         BEGIN
            Print(5, 21, 'You clicked outside the window. Please try again');
            Beep;
            Delay(2000);
            RubOut(5, 21, 50, Black);
         END;
      UNTIL Inside; }
END;

PROCEDURE HandlePHotKeys(Key: Byte);
BEGIN
      CASE Key OF
           1: ShowHelp('HelpPend.hlp', 'HelpPendHK');
           2: BEGIN
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
                 IF Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[2] := 'F2-Pause';
                    PHotKeys.BackColor := Blue;
                    PHotKeys.Display;
                 END;
                 Pause := False;
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
                 {PAction := False;}
                 DrawDirectionField;
              END;
           5: BEGIN
                 SetUpPhasePlot;
                 PlotOrbits := True;
                 SelectStart;
              END;
           6: BEGIN
                 PAction := False;
                 PlotOrbits := False;
                 HotKeys.Clear;
                 CloseViewPort(2);
                 CloseViewPort(3);
                 LightMenu := True;
              END;
      END;
END;


BEGIN
   SetUpPhasePlot;
   PlotOrbits := True;
   SelectStart;
   REPEAT
      CheckForEvents;
      IF PHotkeys.Pressed(Key) THEN
                  HandlePHotKeys(Key);
      IF PAction AND PlotOrbits AND (NOT Pause) THEN MovePhasePlot;
      IF (NOT PAction) AND (NOT Pause) THEN
      BEGIN
         PlotPoint(xOld, yOld, Red);
         {SetColor(Red);
         PlotSymbol(xOld, yOld, 'o'); }
      END;
   UNTIL Not PlotOrbits;
   LightMenu := True;
END;

{-------------------------------------------------------------------------}

FUNCTION FindStart : Boolean;
VAR
   TimePlotData      : TInputScreen;
BEGIN
   WITH TimePlotData DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.3, 0.8);
      LoadLine('       Data for time plots');
      LoadLine('');
      LoadLine(' Enter initial values theta (x) and');
      LoadLine(' thetadot (x'').  ');
      LoadLine(' 0 <= x <= 180, -200 <= x'' <= 200');
      LoadLine('   Theta:     {      } degrees');
      LoadLine('   Thetadot:  {      } degrees/sec');
      LoadLine(' Enter the final value of the time:');
      LoadLine('         1 <= {      } <= 100 sec');
      LoadLine('');
      LoadLine('       [  OK  ]        [Cancel]');
      SetNumber(1, Theta);
      SetNumber(2, ThetaDot);
      SetNumber(3, MaxTime);
      SetNumberLimits(1, 0, 180);
      SetNumberLimits(2, -200, 200);
      SetNumberLimits(3, 1, 100);
      AcceptScreen;
      FindStart := NOT Canceled;
      IF Canceled THEN Exit;
      Theta := GetNumber(1);
      ThetaDot := GetNumber(2);
      MaxTime := GetNumber(3);
      y[1] := Theta*Pi/180;
      y[2] := ThetaDot*Pi/180;
      Time := 0;
      StepSize := 0.1;
      IF y[2] > 0 THEN Y2Sign := 1;
         IF y[2] < 0 THEN Y2Sign := -1;
         IF y[2] = 0 THEN
         BEGIN
            IF y[1] > 0 THEN Y2Sign := -1
                        ELSE Y2Sign := 1;
         END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE TimePlot;
VAR
   MaxTheta, MaxThetaDot      : Real;
   MinTheta, MinThetaDot      : Real;
   xTheta, xThetaDot          : Real;
   OldTime                    : Real;
   OldTheta, OldThetaDot      : Real;
   I, J                       : Integer;
   Stuck                      : Array[1..10] OF Real;
   StuckSum                   : Real;
   Stopped                    : Boolean;

{-------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   Factor    : Real;
   I, J      : Integer;

BEGIN
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   Time := 0;
   StepSize := 0.1;
   MaxTheta := 0;
   MinTheta := 0;
   MaxThetaDot := 0;
   MinThetaDot := 0;
   J := 0;
   IF DryFriction THEN
   BEGIN
      FOR I := 1 TO 10 DO Stuck[I] := 1;
      Stopped := False;
      REPEAT
         Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
         Stuck[10] := Abs(y[2]);
         TimeStopped := Time;
         IF y[1] > MaxTheta THEN MaxTheta := y[1];
         IF y[1] < MinTheta THEN MinTheta := y[1];
         IF y[2] > MaxThetaDot THEN MaxThetaDot := y[2];
         IF y[2] < MinThetaDot THEN MinThetaDot := y[2];
         IF (y[2]*Y2Sign < 0) THEN FindTopOfSwing;
         StuckSum := 0;
         FOR I := 1 TO 10 DO StuckSum := StuckSum + Stuck[I];
         IF StuckSum < 0.5 THEN Stopped := True;
         FOR I := 1 TO 9 DO Stuck[I] := Stuck[I+1];
      UNTIL (Time > MaxTime) OR Stopped;
   END
   ELSE
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0001, y, Time, StepSize, y);
         IF y[1] > MaxTheta THEN MaxTheta := y[1];
         IF y[1] < MinTheta THEN MinTheta := y[1];
         IF y[2] > MaxThetaDot THEN MaxThetaDot := y[2];
         IF y[2] < MinThetaDot THEN MinThetaDot := y[2];
      UNTIL Time > MaxTime;
   END;
   Factor := 1.05*180/Pi;
   DefineScale(4, 0, MaxTime, Factor*MinTheta, Factor*MaxTheta);
   DefineScale(5, 0, MaxTime, Factor*MinThetaDot, Factor*MaxThetaDot);
END;

BEGIN
   ClearMuppetPort;
   IF NOT FindStart THEN Exit;
   FindScale;
   HideMouse;
   DefineViewPort(4, 0.1, 0.95, 0.55, 0.9);
   DefineViewPort(5, 0.1, 0.95, 0.1, 0.45);
   OpenViewPort(4);
   SelectScale(4);
   Axis(0, 0, 1, 100);
   SetColor(White);
   PutLabel(Bottom, 'Time');
   PutLabel(Left, 'Theta');
   OpenViewPort(5);
   SelectScale(5);
   Axis(0, 0, 1, 100);
   PutLabel(Bottom, 'Time');
   PutLabel(Left, 'Theta-prime');
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   IF y[2] > 0 THEN Y2Sign := 1;
         IF y[2] < 0 THEN Y2Sign := -1;
         IF y[2] = 0 THEN
         BEGIN
            IF y[1] > 0 THEN Y2Sign := -1
                        ELSE Y2Sign := 1;
         END;
   Time := 0;
   OldTime := 0;
   OldTheta := Theta;
   OldThetaDot := ThetaDot;
   StepSize := 0.1;
   J := 0;
   IF DryFriction THEN
   BEGIN
      FOR I := 1 TO 10 DO Stuck[I] := 1;
      Stopped := False;
      REPEAT
         Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
         Stuck[10] := Abs(y[2]);
         IF (y[2]*Y2Sign < 0) THEN FindTopOfSwing;
         StuckSum := 0;
         FOR I := 1 TO 10 DO StuckSum := StuckSum + Stuck[I];
         IF StuckSum < 0.5 THEN Stopped := True;
         FOR I := 1 TO 9 DO Stuck[I] := Stuck[I+1];
         SelectViewPort(4);
         SelectScale(4);
         SetColor(Yellow);
         PlotLine(OldTime, OldTheta, Time, y[1]*180/Pi);
         SelectViewPort(5);
         SelectScale(5);
         PlotLine(OldTime, OldThetaDot, Time, y[2]*180/Pi);
         OldTime := Time;
         OldTheta := y[1]*180/Pi;
         OldThetaDot := y[2]*180/Pi;
      UNTIL (Time > MaxTime) OR Stopped;
   END
   ELSE
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
         SelectViewPort(4);
         SelectScale(4);
         SetColor(Yellow);
         PlotLine(OldTime, OldTheta, Time, y[1]*180/Pi);
         SelectViewPort(5);
         SelectScale(5);
         PlotLine(OldTime, OldThetaDot, Time, y[2]*180/Pi);
         OldTime := Time;
         OldTheta := y[1]*180/Pi;
         OldThetaDot := y[2]*180/Pi;
      UNTIL Time > MaxTime;
   END;
   ShowMouse;
END;


{-------------------------------------------------------------------------}

PROCEDURE HandlePendMenu;
BEGIN
   With PendMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpPend.hlp', 'AboutSimplePendProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpPend.hlp', 'SimplePendModel1');
                  ShowHelp('HelpPend.hlp', 'SimplePendModel2');
               END;
            2: ShowHelp('HelpPend.hlp', 'PendDFieldHelp');
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'Pendulum1');
                  ShowHelp('WalkThru.hlp', 'Pendulum2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  PLotOrbit := False;
                  IF NOT GetPendData THEN LightMenu := True
                  ELSE
                  BEGIN
                     PendMenu.RowActivate(3,1, True);
                     PendMenu.RowActivate(3,2, True);
                  END;
               END;
            END;
      4: CASE RowChosen OF
            1: BEGIN
                  Phase := False;
                  LightMenu := False;
                  SetUpPicture;
                  {StartPlot;}
                  AnimatePendulum;
               END;
            2: TimePlot;
            3: BEGIN
                  Phase := True;
                  SeePhaseSpace;
               END;
         END;
   END;
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
               PlotPend(y[1], Black);
               PlotPend(Theta*Pi/180, Yellow);
               y[1] := Theta*Pi/180;
               y[2] := ThetaDot*Pi/180;
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

BEGIN {Main program.}
   CUPSInit;
   ExitRequest := False;
   DefineViewPort(1, 0, 1, 0.07, 0.95);
   DefineScale(1, -14/5, 14/5, -2, 2);
   DefineViewPort(2, 0.2, 1, 0.07, 0.95);
   DefineViewPort(3, 0, 0.2, 0.35, 0.65);
   ThetaMin := -2*Pi;
   ThetaMax := 2*Pi;
   DField := False;
   MaxTime := 10;
   nMin := 2;
   nMax := 2;
   ThetaDotMin := -200;
   ThetaDotMax := 200;
   DefineScale(2, ThetaMin, ThetaMax, ThetaDotMin, ThetaDotMax);
   Lag := 40;
   Theta := 0;
   Length := 1;
   Drag := 0;
   ThetaDot := 20;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   LightMenu := True;
   Sliders.Init;
   Hello('HelpPend.hlp', 'AboutSimplePendProgram');
   SetUpPendMenu;
   IF NOT GetPendData THEN LightMenu := True;
   REPEAT
      CheckForEvents;
      IF NOT Phase THEN
      BEGIN
         IF Hotkeys.Pressed(Key) THEN
                     HandleHotKeys(Key);
         IF Input AND Sliders.Changed THEN  HandleSliders;
         IF Action AND PlotOrbit THEN MovePendulum;
      END;
      IF LightMenu THEN
         IF PendMenu.Chosen THEN HandlePendMenu;
   UNTIL ExitRequest;
   PendMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




