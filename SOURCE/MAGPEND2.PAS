Program TheMotionOfA2DMagneticPendulum;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                   : Vector;
   PendMenu               : TMenu;
   HotKeys                : THotKeys;
   Drag, TimeRatio        : Real;
   Length                 : Real;
   Lag                    : Integer;
   MagHeight              : Real;
   MagSep1, MagSep2       : Real;
   MagStrength1           : Real;
   MagStrength2           : Real;
   StoreAngle             : Real;
   Time, h                : Real;
   StepSize               : Real;
   Theta                  : Real;
   ThetaDot               : Real;
   MaxTime                : Real;
   xMax, xMin, yMax, yMin : Real;
   Action                 : Boolean;
   PLotOrbit              : Boolean;
   Phase                  : Boolean;
   LightMenu              : Boolean;
   ExitRequest            : Boolean;
   Input                  : Boolean;
   DField                 : Boolean;
   Equilibria          : Boolean;
   Key                    : Byte;
   Sliders                : TSliders;
   ThetaMin, ThetaMax        : Real;
   NMax, NMin                : Integer;
   ThetaDotMin, ThetaDotMax  : Real;

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
       row(2,2, 'Equilibria');
       row(2,3, 'The direction field');
       row(2,4, 'Walk-Through');
      Column(3, 'Data');
       row(3,1, 'Enter parameters');
       row(3,2, 'See equilibria');
      Column(4, 'Animate');
       row(4,1, 'Swing the pendulum');
       row(4,2, 'Time plots');
       row(4,3, 'Phase-space');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
 {  PendMenu.Display;}
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
VAR
   PendDat               : TInputScreen;
BEGIN
   Message('');
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.02, 0.93);
      LoadLine('        Data for the Motion of a Magnetic Pendulum');
      LoadLine('');
      LoadLine('     The length of the pendulum is one unit of length.');
      LoadLIne('     Enter the height of the point of suspension above ');
      LoadLine('  the level of the fixed magnets:');
      LoadLine('                   -2 <= {       } <= 2');
      LoadLine('');
      LoadLine('     Enter the distances between the two fixed magnets');
      LoadLine('  and the vertical line through the point of suspension:');
      LoadLine('  A1: 0 <= {       } <= 10.   A2 0 <= {       } <= 10.');
      LoadLine('');
      LoadLine('     The parameter for the magnetic strength of the ');
      LoadLine('   swinging magnet is 1.');
      LoadLine('   Enter parameters for the magnetic strengths of the');
      LoadLine('   fixed magnets, M1 and M2, between -10 and 10.');
      LoadLine('            M1 = {       }, M2 = {       }');
      LoadLine('');
      LoadLine('      Enter the parameter for the drag term, k:');
      LoadLine('                    0 <= {       } <= 10');
      LoadLine('');
      LoadLIne('         [ Help ]        [  OK  ]        [Cancel]');
      SetHelpFile('HelpPend.hlp', 'Mag2PendInputHelp');
      SetNumber(1, MagHeight);
      SetNumberLimits(1, -2, 2);
      SetNumber(2, MagSep1);
      SetNumberLimits(2, 0, 10);
      SetNumber(3, MagSep2);
      SetNumberLimits(3, 0, 10);
      SetNumber(4, MagStrength1);
      SetNumberLimits(4, -10, 10);
      SetNumber(5, MagStrength2);
      SetNumberLimits(5, -10, 10);
      SetNumber(6, Drag);
      SetNumberLimits(6, 0, 10);
      AcceptScreen;
      GetPendData := NOT Canceled;
      IF Canceled THEN Exit;
      MagHeight := GetNumber(1);
      MagSep1 := GetNumber(2);
      MagSep2 := GetNumber(3);
      MagStrength1 := GetNumber(4);
      MagStrength2 := GetNumber(5);
      Drag := GetNumber(6);
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
VAR
   Dist1, Dist2, MagForce: Real;
BEGIN
   Dist1 := ((MagSep1-Sin(y[1]))*(MagSep1-Sin(y[1])) +
                 (MagHeight-Cos(y[1]))*(MagHeight-Cos(y[1])));
   Dist2 := ((MagSep2+Sin(y[1]))*(MagSep2+Sin(y[1])) +
                 (MagHeight-Cos(y[1]))*(MagHeight-Cos(y[1])));
   Dist1 := Dist1*Sqrt(Dist1);
   Dist2 := Dist2*Sqrt(Dist2);
   MagForce := MagStrength1*(MagSep1*Cos(y[1]) - MagHeight*Sin(y[1]))/Dist1
               - MagStrength2*(MagSep2*Cos(y[1]) + MagHeight*Sin(y[1]))/Dist2;
   z[1] := y[2];
   z[2] := - Drag*y[2] - Sin(y[1]) + MagForce;
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
      temax := tol/100000;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
end;

{-------------------------------------------------------------------------}

PROCEDURE PlotPend(Angle: Real; SColor: Word);
VAR
   Radius: Integer;
   xSc, ySc: Integer;
   xEnd, yEnd: Real;
   SaveColor    : Word;
BEGIN
   SaveColor := GetColor;
   Radius := Trunc(10*GetMaxX/639);
   SetColor(SColor);
   xEnd := Sin(Angle);
   yEnd := - Cos(Angle);
   PlotLine(0, 0, 0.95*xEnd, 0.95*yEnd);
   Map(xEnd, yEnd, xSc, ySc);
   Circle(xSc, ySc, Radius);
   SetColor(SaveColor);
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
   rubOut(1,21,5,DarkGray);
   print (2,21,NumStr(Hours,3,0));
   rubOut(11,21,7,DarkGray);
   print (12,21,NumStr(Minutes,3,0));
   rubOut(25,21,7,DarkGray);
   print (26,21,NumStr(Seconds,3,0));
   SelectViewPort(1);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotMagnets;
VAR
   StoreColor     : Word;
   i              : Integer;
   Del1, Del2     : Real;
BEGIN
   StoreColor := GetColor;
   SetColor(Green);
   Del1 := (MagSep1 + MagSep2)/40;
   Del2 := Del1;
   FOR i := 1 TO 5 DO
   BEGIN
      IF MagStrength1 > 0 THEN SetColor(Green) ELSE SetColor(Blue);
      PlotLine(-MagSep1-Del1, - MagHeight + i/100,
               -MagSep1+Del1, - MagHeight + i/100);
      IF MagStrength2 > 0 THEN SetColor(Green) ELSE SetColor(Blue);
      PlotLine(MagSep2-Del2, - MagHeight +i/100,
               MagSep2+Del2, - MagHeight +i/100);
   END;
   SetColor(White);
   PlotLine(-MagSep1/0.9, - MagHeight, MagSep2/0.9, -MagHeight);
   SetColor(StoreColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
   i            : Integer;
   MinX, MinY   : Real;
   MaxX, MaxY   : Real;
   DelX, DelY   : Real;
   TimeStr      : String;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   PlotOrbit := False;
   Message('');
   IF Equilibria THEN OpenViewPort(8) ELSE OpenViewPort(1);
   IF MagSep1 > 1 THEN MinX := -MagSep1/0.9 ELSE MinX := -1.1;
   IF MagSep2 > 1 THEN MaxX := MagSep2/0.9 ELSE MaxX := 1.1;
   IF MagHeight > 1 THEN MinY := -0.1 - MagHeight ELSE MinY := -1.1;
   MaxY := 1.1;
   IF MaxX - MinX > MaxY - MinY THEN
   BEGIN
      DelY := (MaxX - MinX) - (MaxY - MinY);
      MinY := MinY - DelY/2;
      MaxY := MaxY + DelY/2;
   END
   ELSE
   BEGIN
      DelX := (MaxY - MinY) - (MaxX - MinX);
      MinX := MinX - DelY/2;
      MAxX := MaxX + DelY/2;
   END;
   DefineScale(4, MinX, MaxX, 1.1*MinY, 1.1*MaxY);
   SelectScale(4);
   IF NOT Equilibria THEN
   BEGIN
      Action := False;
      Input := True;
      SetUpHotKeys;
      Message('Use the sliders to choose initial conditions. Press <Accept> when ready');
      y[1] := Theta*Pi/180;
      y[2] := ThetaDot*Pi/180;
      Sliders.Create(1, 0, 360, ThetaDot, 0.95, 0.2, 0.8, 2, '0', '360', 'x'' deg/sec', True);
      Sliders.Create(2, 0, 360, Theta, 0.05, 0.2, 0.8, 2, '0', '360', 'x deg', True);
      Sliders.DrawAll;
      PlotPend(Theta*Pi/180, Yellow);
      GraphBackColor := DarkGray;
   END;
   PlotMagnets;
   SelectViewPort(1);
  { TimeStr := ('     hours       minutes       seconds');
   print(1,21,TimeStr);}
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE MovePendulum;
BEGIN
   Delay(Lag);
   PlotPend(y[1], Black);
   Step(Time, h, 0.0000001, y, Time, h, y);
   StoreAngle := y[1];
   PlotPend(y[1], Yellow);
   IF MagHeight < 1 THEN PlotMagnets;
   {PrintTime(Time);}
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
   {PrintTime(0);}
   {PlotPend(0, Black);}
   h := 1;
   PlotOrbit := True;
   Action := False;
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   StoreAngle := y[1];
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
         Fy[1] := x*Pi/180;
         Fy[2] := y*Pi/180;
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
      LoadLine('  theta-prime vs. theta (x'' vs. x.) Enter');
      LoadLine('  minimum and maximum values of theta.');
      LoadLine('  Minimum: -520 <= {      } <= -5');
      LoadLine('  Maximum:    5 <= {      } <= 520');
      LoadLine('    ');
      LoadLine('     Enter the minimum and maximum values');
      LoadLine('  of theta-prime in degrees per second:');
      LoadLine('  Minimum: -300 <= {      } <= 0');
      LoadLine('  Maximum:    0 <= {      } <= 300');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, ThetaMin);
      SetNumberLimits(1, -520, -5);
      SetNumber(2, ThetaMax);
      SetNumberLimits(2, 5, 520);
      SetNumber(3, ThetaDotMin);
      SetNumberLimits(3, -300, 0);
      SetNumber(4, ThetaDotMax);
      SetNumberLimits(4, 0, 300);
      AcceptScreen;
      ThetaDotMin := GetNumber(3);
      ThetaDotMax := GetNumber(4);
      ThetaMin := GetNumber(1);
      ThetaMax := GetNumber(2);
      Done;
   END;
   DefineScale(2, ThetaMin, ThetaMax,
                   ThetaDotMin, ThetaDotMax);
   xMax := ThetaMax;
   xMin := ThetaMin;
   yMax := ThetaDotMax;
   yMin := ThetaDotMin;
END;

{-----------------------------------------------------------------------}

PROCEDURE SetUpPhasePlot;
VAR
   xSc, ySc: Integer;
   CoordStr: String;
   i       : Integer;
BEGIN
   ClearMuppetPort;
   GetPhasePlotScale;
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   SetUpPHotKeys;
   SetColor(White);
   Axis(0, 0, 10, 10);
   PutLabel(Bottom, 'Degrees');
   PutLabel(Right, 'Degrees per second');
END;


PROCEDURE MovePhasePlot;
BEGIN
   Delay(Lag);
   SelectViewPort(3);
   SelectScale(1);
   PlotPend(y[1], DarkGray);
   Step(Time, h, 0.0000001, y, Time, h, y);
   PlotPend(y[1], White);
   IF MagHeight < 1 THEN PlotMagnets;
   SelectViewPort(2);
   SelectScale(2);
   {SetColor(DarkGray); PlotSymbol(xNew, yNew, 'o');}
   SetColor(Yellow);
   PlotLine(xOld, yOld, xNew, yNew);
   {PlotSymbol(y[1]*180/Pi, y[2]*180/Pi, 'o'); }
   PlotLine(xNew, yNew, y[1]*180/Pi, y[2]*180/Pi);
   xOld := xNew; yOld := yNew;
   xNew := y[1]*180/Pi; yNew := y[2]*180/Pi;
END;


PROCEDURE StartPhasePlot;
BEGIN
   Pause := False;
   xOld := y[1]*180/Pi;
   yOld := y[2]*180/Pi;
   Time := 0;
   h := 1;
   GraphBackColor := DarkGray;
   OpenViewPort(3);
   SelectViewPort(3);
   SelectScale(1);
   PlotMagnets;
END;

PROCEDURE SelectStart;
VAR
   Inside: Boolean;
   xMouse, yMouse    : Real;
   a                 : Integer;
   xm, ym, Button    : Integer;
   xSave, ySave      : Real;
BEGIN
   HideCursor;
   SetColor(Yellow);
   SelectViewPort(2);
   SelectScale(2);
  { SetColor(Red);
   PlotSymbol(y[1], y[2], 'o');}
   SetColor(Yellow);
   PlotLine(xOld, yOld, xNew, yNew);
   Inside := False;
   SetColor(White);
   Message('   Click on a starting point in the window');
   ShowCursor;
   REPEAT
      MouseGlobalPosn(xm, ym, Button);
      MousePosn(xMouse, yMouse, 2, 2, Inside);
      IF NOT Inside THEN
      BEGIN
         IF (Abs(XSave - xMouse) + Abs(YSave - yMouse) > 0.01) THEN
         BEGIN
            RubOutXY(0.6, 0.982, 20, Blue);
            PrintXY(0.6, 0.982, 'IN the window!');
         END;
         XSave := xMouse;
         YSave := yMouse;
      END
      ELSE
         IF (Abs(XSave - xMouse) + Abs(YSave - yMouse) > 0.01) THEN
         BEGIN
            RubOutXY(0.6, 0.982, 20, Blue);
            PrintXY(0.6, 0.982, '('+NumStr(xMouse, 4, 1)+
                           ', '+NumStr(yMouse, 4, 1)+')');
            XSave := xMouse;
            YSave := yMouse;
         END;
      UNTIL InSide AND (Button <> 0);
      Message('');
      SetColor(Yellow);
        {    IF Inside AND
            (Abs(XSave - xMouse) + Abs(YSave - yMouse) > 0.01) THEN
            BEGIN
               RubOutXY(0.0, 0.08, 15, Black);
               PrintXY(0.0, 0.08, '('+NumStr(xMouse, 4, 1)+
                                 ', '+NumStr(yMouse, 4, 1)+')');
               XSave := xMouse;
               YSave := yMouse;
            END;
         UNTIL MouseClicked(a,a);
         IF Inside THEN
         BEGIN     }
            xOld := xMouse;
            yOld := yMouse;
            xNew := xOld;
            y[1] := xOld*Pi/180;
            yNew := yOld;
            y[2] := yOld*Pi/180;
            RubOutXY(0.0, 0.08, 15, Black);
            PAction := True;
            StartPhasePlot;
       {  END
         ELSE
         BEGIN
            Message('You clicked outside the window. Please try again');
            Beep;
            Delay(2000);
         END;
      UNTIL Inside;
      Message(''); }
      HideMouse;
END;

PROCEDURE HandlePHotKeys(Key: Byte);
BEGIN
      CASE Key OF
           1: ShowHelp('HelpPend.hlp', 'HelpPendHK');
           2: BEGIN
                 ShowMouse;
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
                 ShowMouse;
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
                 ShowMouse;
                 DrawDirectionField;
              END;
           5: BEGIN
                 ShowMouse;
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
                 ClearMuppetPort;
                 LightMenu := True;
                 ShowMouse;
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
        { SetColor(Red);
         PlotSymbol(xOld, yOld, 'o');}
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


{-------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   Factor    : Real;
   Wait      : TWaitMessage;
BEGIN
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   Time := 0;
   StepSize := 0.1;
   MaxTheta := 0;
   MinTheta := 0;
   MaxThetaDot := 0;
   MinThetaDot := 0;
   Wait.Show;
   REPEAT
      Step(Time, StepSize, 0.0001, y, Time, StepSize, y);
      Wait.Update;
      IF y[1] > MaxTheta THEN MaxTheta := y[1];
      IF y[1] < MinTheta THEN MinTheta := y[1];
      IF y[2] > MaxThetaDot THEN MaxThetaDot := y[2];
      IF y[2] < MinThetaDot THEN MinThetaDot := y[2];
   UNTIL Time > MaxTime;
   Wait.Hide;
   Factor := 1.05*180/Pi;
   DefineScale(4, 0, MaxTime, Factor*MinTheta, Factor*MaxTheta);
   DefineScale(5, 0, MaxTime, Factor*MinThetaDot, Factor*MaxThetaDot);
END;

BEGIN
   ClearMuppetPort;
   FindStart;
   FindScale;
   HideMouse;
   DefineViewPort(4, 0.1, 0.95, 0.55, 0.9);
   DefineViewPort(5, 0.1, 0.95, 0.1, 0.45);
   OpenViewPort(4);
   SelectScale(4);
   Axis(0, 0, 1, 100);
   PutLabel(Bottom, 'Time');
   PutLabel(Left, 'Theta');
   OpenViewPort(5);
   SelectScale(5);
   Axis(0, 0, 1, 100);
   PutLabel(Bottom, 'Time');
   PutLabel(Left, 'Theta-prime');
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   Time := 0;
   OldTime := 0;
   OldTheta := Theta;
   OldThetaDot := ThetaDot;
   StepSize := 0.1;
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
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE SeeEquilibria;
VAR
   Angle, DelAngle        : Real;
   xOld, yOld             : Real;
   xNew, yNew             : Real;
   NPoints, i             : Integer;
   YTick                  : Integer;
   EquSliders             : TSliders;
   EquHotKeys             : THotkeys;
   Leave                  : Boolean;

PROCEDURE SetUpEquHotKeys;
BEGIN
   WITH EquHotKeys DO
   BEGIN
      Init(3);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-ReDraw';
      Key[3] := 'F10-Menu';
   END;
   EquHotKeys.Display;
END;

FUNCTION Torque : Real;
VAR
   Dist1, Dist2, MagForce: Real;
BEGIN
   Dist1 := ((MagSep1-Sin(Angle))*(MagSep1-Sin(Angle)) +
                 (MagHeight-Cos(Angle))*(MagHeight-Cos(Angle)));
   Dist2 := ((MagSep2+Sin(Angle))*(MagSep2+Sin(Angle)) +
                 (MagHeight-Cos(Angle))*(MagHeight-Cos(Angle)));
   IF (Dist1 < 0.001) OR (Dist2 < 0.001) THEN Torque := 10 ELSE
   BEGIN
      Dist1 := Dist1*Sqrt(Dist1);
      Dist2 := Dist2*Sqrt(Dist2);
      MagForce := MagStrength1*(MagSep1*Cos(Angle) - MagHeight*Sin(Angle))/Dist1
                  - MagStrength2*(MagSep2*Cos(Angle) + MagHeight*Sin(Angle))/Dist2;
      Torque := - Sin(Angle) + MagForce;
   END;
END;

PROCEDURE FindLimits;
VAR
   i              : Integer;
   Upper, Lower   : Real;
   Test           : Real;
BEGIN
   DelAngle := 2*Pi/20;
   Angle := -Pi;
   Upper := Torque;
   Lower := Upper;
   FOR i := 1 TO 20 DO
   BEGIN
      Angle := Angle + DelAngle;
      Test := Torque;
      IF Upper < Test THEN Upper := Test;
      IF Lower > Test THEN Lower := Test;
   END;
   IF Upper > 10 THEN Upper := 10;
   IF Lower < - 10 THEN Lower := - 10;
   DefineScale(6, -180, 180, 1.1*Lower, 1.1*Upper);
   IF Upper - Lower > 10 THEN YTick := 2 ELSE YTick := 1;
END;



PROCEDURE DrawCurve;
VAR
   i        : Integer;
BEGIN
   SetUpPicture;
   NPoints := 200;
   DefineViewPort(6, 0.05, 0.95, 0.12, 0.45);
   DefineScale(7, -1.2, 1.2, -1.4, 1.4);
   DrawAxis(0, 0, 45, YTick, Black);
   FindLimits;
   OpenViewPort(6);
   SelectScale(6);
   DrawAxis(0, 0, 45, YTick, White);
   PutLabel(Inside, 'Torque');
   PutLabel(Bottom, 'Theta');
   SetColor(White);
   xOld := -180;
   Angle := -Pi;
   DelAngle := 2*Pi/NPoints;
   yOld := Torque;
   FOR i := 1 TO NPoints+1 DO
   BEGIN
      Angle := Angle + DelAngle;
      xNew := xOld + 360/NPoints;
      yNew := Torque;
      IF i <= NPoints THEN PlotLine(xOld, yOld, xNew, yNew);
      IF yOld*yNew < 0 THEN
      BEGIN
         SelectViewPort(8);
         SelectScale(7);
         PlotPend(Angle-DelAngle*(yNew/(yNew - yOld)), Yellow);
         SelectViewPort(6);
         SelectScale(6);
      END;
      xOld := xNew;
      yOld := yNew;
   END;
END;

PROCEDURE SetUpScreen;
BEGIN
   ClearMuppetPort;
   EquSliders.Create(1, -2, 2, MagHeight,
                  0.05, 0.5, 0.95, 1, '-2', '2', 'H', True);
   EquSliders.Create(2, 0, 5, MagSep1,
                  0.15, 0.5, 0.95, 1, '0', '5', 'A1', True);
   EquSliders.Create(3, 0, 5, MagSep2,
                  0.25, 0.5, 0.95, 1, '0', '5', 'A2', True);
   EquSliders.Create(4, -10, 10, MagStrength1,
                  0.35, 0.5, 0.95, 1, '-10', '10', 'M1', True);
   EquSliders.Create(5, -10, 10, MagStrength2,
                  0.45, 0.5, 0.95, 1, '-10', '10', 'M2', True);
   EquSliders.DrawAll;
   GraphBackColor := DarkGray;
  { SetUpPicture;}
   SetUpEquHotKeys;
   DrawCurve;
END;


PROCEDURE HandleEquHotKeys(Key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HelpPend.hlp', 'Mag2PendEquHelp');
      2: SetUpScreen;
      3: BEGIN Leave := True; Equilibria := False; END;
   END;
END;

BEGIN
   Leave := False;
   DefineViewPort(8, 0.55, 0.95, 0.55, 0.95);
   Equilibria := True;
   EquSliders.Init;
   SetUpScreen;
   REPEAT
      CheckForEvents;
      IF EquHotKeys.Pressed(Key) THEN HandleEquHotKeys(Key);
      IF EquSliders.Changed THEN
      BEGIN
         MagHeight := EquSliders.Value(1);
         MagSep1 := EquSliders.Value(2);
         MagSep2 := EquSliders.Value(3);
         MagStrength1 := EquSliders.Value(4);
         MagStrength2 := EquSliders.Value(5);
      END;
   UNTIL Leave;
   EquSliders.Done;
   ClearMuppetPort;
   LightMenu := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePendMenu;
BEGIN
   With PendMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpPend.hlp', 'AboutMag2PendProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpPend.hlp', 'Mag2PendModel1');
                  ShowHelp('HelpPend.hlp', 'Mag2PendModel2');
               END;
            2: ShowHelp('HelpPend.hlp', 'Mag2PendEquilibria');
            3: ShowHelp('HelpPend.hlp', 'Mag2PendDFieldHelp');
            4: BEGIN
                  ShowHelp('WalkThru.hlp', 'MagPend1');
                  ShowHelp('WalkThru.hlp', 'MagPend2');
                  ShowHelp('WalkThru.hlp', 'MagPend3');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  PLotOrbit := False;
                  IF NOT GetPendData THEN LightMenu := True
               END;
            2: SeeEquilibria;
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
               StoreAngle := Theta*Pi/180;
            END;
         END;
      3: BEGIN
               PlotOrbit := False;
               Action := False;
               HotKeys.Clear;
               CloseViewPort(1);
               ClearMuppetPort;
               LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   ExitRequest := False;
   DefineViewPort(1, 0.15, 0.85, 0.07, 0.95);
   DefineViewPort(2, 0.2, 0.95, 0.1, 0.9);
   DefineViewPort(3, 0, 0.2, 0.35, 0.65);
   Lag := 40;
   MagHeight := 1.2;
   MagSep1 := 0.6;
   MagSep2 := 0.6;
   MagStrength1 := 0.5;
   MagStrength2 := 0.5;
   DefineScale(1, -1.2, 1.2, -1.4, 1.2);
   Drag := 0.1;
   DField := False;
   MaxTime := 10;
   nMin := -2;
   nMax := 2;
   ThetaDotMin := -50;
   ThetaDotMax := 50;
   ThetaMin := -45;
   ThetaMax := 45;
   DefineScale(2, ThetaMin, ThetaMax, ThetaDotMin, ThetaDotMax);
   Theta := 0;
   Length := 1;
   ThetaDot := 20;
   LightMenu := True;
   Equilibria := False;
   Sliders.Init;
   Hello('HelpPend.hlp', 'AboutMag2PendProgram');
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




