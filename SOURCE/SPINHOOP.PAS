Program TheMotionOfASpinningHoop;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z: Vector;
   HoopMenu: TMenu;
   HotKeys: THotKeys;
   Drag, TimeRatio        : Real;
   Length                 : Real;
   Lag                    : Integer;
   StoreAngle             : Real;
   Time, h                : Real;
   Theta                  : Real;
   ThetaDot               : Real;
   Y2Sign                 : Real;
   Spin                   : Real;
   Action                 : Boolean;
   PLotOrbit              : Boolean;
   Phase                  : Boolean;
   LightMenu              : Boolean;
   ExitRequest            : Boolean;
   Pause                  : Boolean;
   DField                 : Boolean;
   KeyInitialConditions   : Boolean;
   xMax, xMin, yMax, yMin   : Real;
   Key: Byte;
   Sliders: TSliders;

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

PROCEDURE SetUpHoopMenu;
VAR
   I      : Integer;
BEGIN
   With HoopMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About direction fields');
       row(2,3, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Animate');
       row(3,3, 'See phase-space');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   HoopMenu.Display;
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-Faster';
      Key[4] := 'F5-Slower';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

FUNCTION GetHoopData :  Boolean;
CONST
   RBNames : string = '12345678';
VAR
   cd, CrossSection, Mass: Real;
   HoopDat               : TInputScreen;
BEGIN
   WITH HoopDat DO
   BEGIN
      Init;
      DefineInputPort(0.07, 0.93, 0.15, 0.85);
      LoadLine('');
      LoadLine('        Data for the Motion of a Ring on a Spinning Hoop');
      LoadLine('');
      LoadLine('       x is the angle between the downward vertical and the');
      LoadLine('   line from the center of the hoop to the ring.');
      LoadLIne('       The model is:');
      LoadLine('      d(dx/dt)/dt = - k(dx/dt) - sin(x) + w^2sin(x)cos(x)');
      LoadLine('    w is the spin rate of the hoop.    0 <= w <= 10.');
      LoadLine('    k is a parameter for the friction. 0 <= k <= 10.');
      LoadLine('');
      LoadLIne('                    Enter the spin rate: w = {       } rad/sec');
      LoadLine('');
      LoadLine('   Enter the parameter for the friction: k = {       } 1/sec');
      LoadLine('');
      LoadLIne('                   [  OK  ]              [Cancel]');
      SetNumber(1, Spin);
      SetNumberLimits(1, 0, 10);
      SetNumber(2, Drag);
      SetNumberLimits(2, 0, 10);
      AcceptScreen;
      GetHoopData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Spin := GetNumber(1);
         Drag := GetNumber(2);
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
   z[2] := - Drag*y[2] - Sin(y[1]) + Spin*Spin*Sin(y[1])*Cos(y[1])
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
      temax := 0;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      IF temax = 0 THEN TeMax := Tol/100000;
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
end;

{-----------------------------------------------------------------------}

PROCEDURE PlotHoop(Angle: Real; SColor: Word);
VAR
   Radius: Integer;
   xSc, ySc: Integer;
   xEnd, yEnd: Real;
BEGIN
   Radius := MapX(1) - MapX(0);
   SetColor(SColor);
   xEnd := Sin(Angle);
   yEnd := - Cos(Angle);
   SetColor(LightBlue);
   Circle(MapX(0), MapY(0), Radius);
   IF Phase THEN Radius := Radius + Trunc(7*GetMaxX/639)
            ELSE Radius := Radius + Trunc(22*GetMaxX/639);
   Circle(MapX(0), MapY(0), Radius);
   SetColor(SColor);
   IF Phase THEN Map(1.1*xEnd, 0.8*yEnd, xSc, ySc)
   {Map(1.03*xEnd, 0.75*yEnd, xSc, ySc)}
            ELSE Map(1.1*xEnd, 1.1*yEnd, xSc, ySc);
   IF SColor <> Black THEN SetColor(Yellow);
   IF Phase THEN Radius := Trunc(3*GetMaxX/639)
            ELSE Radius := Trunc(9*GetMaxX/639);
   Circle(xSc, ySc, Radius);
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
   OpenViewPort(1);
   SelectScale(1);
   Action := True;
   SetUpHotKeys;
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   Sliders.Create(1, 0, 360, ThetaDot, 0.07, 0.2, 0.8, 2, '0', '360', 'x'' deg/sec', True);
   Sliders.Create(2, 0, 360, Theta, 0.2, 0.2, 0.8, 2, '0', '360', 'x deg', True);
   Sliders.Create(3, 0, 5, Spin, 0.8, 0.2, 0.8, 2, '0', '5', 'Spin', True);
   Sliders.Create(4, 0, 1, Drag, 0.93, 0.2, 0.8, 2, '0', '1', 'Drag', True);
   Sliders.DrawAll;
   PlotHoop(0, Yellow);
   GraphBackColor := DarkGray;
   SelectViewPort(1);
       {TimeStr := ('     hours       minutes       seconds');
      print(1,21,TimeStr);}
   {PrintTime(0); }
   ShowCursor;   
END;

{------------------------------------------------------------------------}

PROCEDURE MoveHoop;
BEGIN
   Delay(Lag);
   PlotHoop(y[1], Black);
   Step(Time, h, 0.0000001, y, Time, h, y);
   {IF DryFriction AND (y[2]*Y2Sign < 0) THEN FindTopOfSwing; }
   StoreAngle := y[1];
   PlotHoop(y[1], Yellow);
   {PrintTime(Time)};
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE AnimateHoop;
VAR

   xOld, yOld, xNew, yNew: Real;
   xHoop, yHoop: Real;
BEGIN
   Message('');
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   PlotHoop(StoreAngle, Black);
   Time := 0;
   {PrintTime(0);}
   PlotHoop(0, Black);
   h := 1;
   PlotOrbit := True;
   Action := False;
   Pause := True;
   StoreAngle := y[1];
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   PlotHoop(y[1], Black);
   y[2] := Sliders.Value(1);
   y[1] := Sliders.Value(2);
   y[1] := y[1]*Pi/180;
   y[2] := y[2]*Pi/180;
   Spin := Sliders.Value(3);
   Drag := Sliders.Value(4);
   IF y[2] > 0 THEN Y2Sign := 1;
   IF y[2] < 0 THEN Y2Sign := -1;
   IF y[2] = 0 THEN
   BEGIN
      IF y[1] > 0 THEN Y2Sign := -1
                  ELSE Y2Sign := 1;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE StartPlot;
BEGIN
   Action := False;
   y[1] := Theta*Pi/180;
   y[2] := ThetaDot*Pi/180;
   {REPEAT
   CheckForEvents;
   IF Sliders.Changed THEN HandleSliders;
      IF Hotkeys.Pressed(Key) THEN
                  HandleHotKeys(Key, Action, Action, PlotOrbit);
   UNTIL Action; }
   {PlotHoop(StoreAngle, Black);}
   AnimateHoop;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag    : Integer;
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
            StoreAngle := y[1];
            IF Action THEN
            BEGIN
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            Action := False;
            PlotOrbit := False;
            AnimateHoop;
            PlotHoop(StoreAngle, Black);
         END;
      3: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      4: Lag := Lag + DelLag;
      5: BEGIN
               PlotOrbit := False;
               Action := False;
               HotKeys.Clear;
               CloseViewPort(1);
               LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotDot(xDot, yDot : Real; DotColor: Word);
VAR
   xC, yC  : Integer;
BEGIN
   xC := MapX(xDot);
   yC := MapY(yDot);
   PutPixel(xC, yC, DotColor);
   PutPixel(xC+1, yC, DotColor);
   PutPixel(xC-1, yC, DotColor);
   PutPixel(xC, yC+1, DotColor);
 {  PutPixel(xC+1, yC+1, DotColor);
   PutPixel(xC-1, yC+1, DotColor);}
   PutPixel(xC, yC-1, DotColor);
  { PutPixel(xC+1, yC-1, DotColor);
   PutPixel(xC-1, yC-1, DotColor);}
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

PROCEDURE PlotDot(xDot, yDot : Real; DotColor: Word);
VAR
   xC, yC  : Integer;
BEGIN
   xC := MapX(xDot);
   yC := MapY(yDot);
   PutPixel(xC, yC, DotColor);
   PutPixel(xC+1, yC, DotColor);
   PutPixel(xC-1, yC, DotColor);
   PutPixel(xC, yC+1, DotColor);
   PutPixel(xC, yC-1, DotColor);
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
   IF Sqrt((sxa-sxb)*(sxa-sxb) + (sya-syb)*(sya-syb)) = 0 THEN Exit;
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

BEGIN
   DField := True;
   xCol := 25;
   yRow := 25;
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
         Fz[1] := Fz[1];
         Factor := Sqrt(Fz[1]*Fz[1] + Fz[2]*Fz[2]);
         IF Factor = 0 THEN Factor := 0.001;
         IF Factor > 0.001 THEN
         BEGIN
            xEnd := DL*Fz[1]/Factor;
            yEnd := DL*Fz[2]/Factor;
            IF Abs(xEnd) + Abs(yEnd) > 0.001 THEN Arrow(x, y, xEnd, yEnd, Length);
         END;
         PlotDot(x, y, White);
      END;
   END;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE SeePhaseSpace;
VAR
  PHotKeys: THotKeys;
  Pause, PAction, PlotOrbits: Boolean;
  xOld, yOld, xNew, yNew: Real;


PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(7);
      Key[1] := 'F2-Pause';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-Faster';
      Key[4] := 'F5-Slower';
      Key[5] := 'F6-D-Field';
      Key[6] := 'F7-CleanUp';
      Key[7] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Blue;
   PHotKeys.HotKeyColor := Yellow;
   PHotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPhasePlot;
VAR
   xSc, ySc     : Integer;
   CoordStr     : String;
   SpinData     : TInputScreen;
   yScale       : Real;
BEGIN
   yScale := 250*Pi/180;
   ClearMuppetPort;
   {HoopMenu.Display;}
   PAction := False;
   Pause := True;
   HideCursor;
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   SetUpPHotKeys;
   SetColor(White);
   PlotLine(-3.5, 0, 3.5, 0);
   PlotLine(0, -4.5, 0, 4.5);
   PlotLine(-Pi, 0, -Pi, 0.1);
   PlotLine(Pi, 0, Pi, 0.1);
   PrintXY(0.24, 0.51, '-360');
   PrintXY(0.92, 0.51, '360');
   PrintXY(0.89, 0.555, 'x, deg');
   PrintXY(0.615, 0.16, '-250');
   PrintXY(0.615, 0.89, '250');
   PlotLine(0, yScale, 0.05, yScale);
   PlotLine(0, -yScale, 0.05, -yScale);
   PrintXY(0.5, 0.922, 'x-prime, deg/sec');
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE MovePhasePlot;
BEGIN
   Delay(Lag);
   SelectViewPort(3);
   SelectScale(1);
   PlotHoop(y[1], Black);
   Step(Time, h, 0.0000001, y, Time, h, y);
   PlotHoop(y[1], White);
   xNew := y[1];
   yNew := y[2];
   SelectViewPort(2);
   SelectScale(2);
   IF (xNew < Pi) AND (xNew > -Pi) THEN
   BEGIN
      SetColor(DarkGray); PlotDot(xOld, yOld, DarkGray);
      SetColor(Yellow);
      PlotDot(xNew, yNew, LightBlue);
      PlotLine(xOld, yOld, xNew, yNew);
   END
   ELSE
   BEGIN
      IF xNew > Pi THEN xNew := xNew - 2*Pi;
      IF xNew < - Pi THEN xNew := xNew + 2*Pi;
      y[1] := xNew;
      SetColor(DarkGray);
      PlotDot(xOld, yOld, DarkGray);
   END;
   xOld := xNew; yOld := yNew;
END;

{------------------------------------------------------------------------}

PROCEDURE StartPhasePlot;
BEGIN
   Pause := False;
   xOld := y[1];
   yOld := y[2];
   Time := 0;
   h := 1;
   GraphBackColor := Black;
   OpenViewPort(3);
   SelectViewPort(3);
   SelectScale(1);
END;

{------------------------------------------------------------------------}

FUNCTION UseKey : Boolean;
CONST
   RBNames : string = '12345678';
VAR
  Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.32, 0.68, 0.35, 0.65);
      LoadLine('');
      LoadLine('  Would you like to use');
      LoadLine('       #1 keyboard');
      LoadLine('   or  #1 mouse?');
      LoadLine('');
      LoadLine('        [  OK  ]');
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      UseKey := True ELSE UseKey := False;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptForClick;
VAR
   Inside, Ins     : Boolean;
   Button          : Integer;
   xm, ym          : Integer;
   MSave, FSave    : Real;
   a               : Integer;
BEGIN
   Inside := True;
   Button := 0;
   Message('Click on a starting point in the window');
   SetColor(Yellow);
   REPEAT
      MousePosn(y[1], y[2], 2, 2, Inside);
      IF Inside AND
      (Abs(MSave - (y[1])) + Abs(FSave - (y[2])) > 0.002) THEN
      BEGIN
         RubOutXY(0.4, 0.12, 20, GraphBackColor);
         PrintXY(0.4, 0.12, '('+NumStr(y[1]*180/Pi, 4, 0)+
                               ','+NumStr(y[2]*180/Pi, 4, 0)+')');
         MSave := (y[1]);
         FSave := (y[2]);
      END;
   UNTIL MouseClicked(a,a);
   IF y[2] > 0 THEN Y2Sign := 1;
   IF y[2] < 0 THEN Y2Sign := -1;
   IF y[2] = 0 THEN
   BEGIN
      IF y[1] > 0 THEN Y2Sign := -1
                  ELSE Y2Sign := 1;
   END;
   RubOutXY(0.4, 0.12, 20, GraphBackColor);
   Message('');
END;

{------------------------------------------------------------------------}

PROCEDURE SelectStart;
VAR
   x1, y1, x2, y2: integer;
   InitialDat      : TInputScreen;
BEGIN
   KeyInitialConditions := UseKey;
   IF KeyInitialConditions THEN
   BEGIN
      WITH InitialDat DO
      BEGIN
         Init;
         DefineInputPort(0.25, 0.75, 0.75, 0.95);
         LoadLine('       Enter initial conditions:');
         LoadLine(' -360 <=  x = {      } <= 360 deg');
         LoadLine(' -250 <= x'' = {      } <= 250 deg/sec');
         LoadLine('              [  OK  ]   ');
         SetNumber(1, Theta);
         SetNumberLimits(1, -360, 360);
         SetNumber(2, ThetaDot);
         SetNumberLimits(2, -250, 250);
         AcceptScreen;
         Theta := GetNumber(1);
         ThetaDot := GetNumber(2);
         y[1] := Theta*Pi/180;
         y[2] := ThetaDot*Pi/180;
         Done;
      END;
   END
   ELSE
   BEGIN
      SetColor(Black);
      GraphBackColor := DarkGray;
      Map(-2*Pi, -250*Pi/180, x1, y1);
      Map(2*Pi, 250*Pi/180, x2, y2);
      x1 := x1 + Trunc(GetMaxX/10);
      x2 := x2 + Trunc(GetMaxX/10);
      y1 := y1 + Trunc(GetMaxy*0.08);
      y2 := y2 + Trunc(GetMaxy*0.08);
      MouseBorders(x1, y1, x2, y2);
      SetColor(Yellow);
      PromptForClick;
      MouseBorders(0, 0, GetMaxX, GetMaxY);
   END;
   PAction := True;
   StartPhasePlot;
END;


{
      HideCursor;
      SetColor(Yellow);
      SelectViewPort(2);
      SelectScale(2);
      Inside := False;
      REPEAT
         Print(5, 21, 'Click on a starting point in the window');
         ShowCursor;
         WaitOnMouseClick;
         MousePosn(y[1], y[2], 2, 2, Inside);
         IF y[2] > 0 THEN Y2Sign := 1;
         IF y[2] < 0 THEN Y2Sign := -1;
         IF y[2] = 0 THEN
         BEGIN
            IF y[1] > 0 THEN Y2Sign := -1
                        ELSE Y2Sign := 1;
         END;
         RubOut(5, 21, 50, DarkGray);
         IF Inside THEN
         BEGIN
            y[1] := y[1];
            PAction := True;
            StartPhasePlot;
         END
         ELSE
         BEGIN
            Print(5, 21, 'You clicked outside the window. Please try again');
            Beep;
            Delay(2000);
            RubOut(5, 21, 50, DarkGray);
         END;
      UNTIL Inside;
END;      }

PROCEDURE HandlePHotKeys(Key: Byte);
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 10;
      CASE Key OF
           1: BEGIN
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
                 IF Pause THEN
                 BEGIN
                    WITH PHotKeys DO Key[1] := 'F2-Pause';
                    PHotKeys.BackColor := Blue;
                    PHotKeys.Display;
                 END;
                 Pause := False;
                 PAction := False;
                 SelectStart;
              END;
           3: IF Lag - DelLag > 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
           4: Lag := Lag + DelLAg;
           5: DrawDirectionField;
           6: BEGIN
                 GetHoopData;
                 SetUpPhasePlot;
                 PlotOrbits := True;
                 SelectStart;
              END;
           7: BEGIN
                 PAction := False;
                 PlotOrbits := False;
                 PHotKeys.Clear;
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
         SetColor(DarkGray);
         PlotDot(xOld, yOld, DarkGray);
      END;
   UNTIL Not PlotOrbits;
   LightMenu := True;
END;


{-------------------------------------------------------------------------}

PROCEDURE HandleHoopMenu;
BEGIN
   With HoopMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('Helpmisc.hlp', 'SpinHoopAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('Helpmisc.hlp', 'SpinHoopAboutModelA');
                  ShowHelp('Helpmisc.hlp', 'SpinHoopAboutModelB');
               END;
            2: ShowHelp('Helpmisc.hlp', 'SpinHoopDFieldHelp');
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'SpinHoop1');
                  ShowHelp('WalkThru.hlp', 'SpinHoop2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  PLotOrbit := False;
                  IF NOT GetHoopData THEN LightMenu := True;
               END;
            2: BEGIN
                  Phase := False;
                  LightMenu := False;
                  SetUpPicture;
                  {StartPlot;}
                  AnimateHoop;
                  Action := False;
                  Pause := True;
               END;
            3: BEGIN
                  Phase := True;
                  SeePhaseSpace;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   ExitRequest := False;
   DefineViewPort(1, 0, 1, 0.07, 0.95);
   DefineScale(1, -2.99, 2.99, -2, 2);
   DefineViewPort(2, 0.2, 1, 0.1, 0.94);
   DefineScale(2, -1.2*Pi, 1.2*Pi, -5, 5);
   xMax := 1.2*Pi;
   xMin := -1.2*Pi;
   yMax := 5;
   yMin := -5;
   DefineViewPort(3, 0, 0.2, 0.37, 0.63);
   Lag := 20;
   Theta := 30;
   Length := 1;
   Drag := 0;
   ThetaDot := 20;
   Spin := 1;
   LightMenu := True;
   Action := False;
   Sliders.Init;
   Hello('Helpmisc.hlp', 'SpinHoopAboutProgram');
   SetUpHoopMenu;
   GetHoopData;
   REPEAT
      CheckForEvents;
      IF NOT Phase THEN
      BEGIN
         IF Hotkeys.Pressed(Key) THEN
                     HandleHotKeys(Key);
         IF Sliders.Changed THEN  HandleSliders;
         IF Action AND PlotOrbit THEN MoveHoop;
      END;
      IF LightMenu THEN
         IF HoopMenu.Chosen THEN HandleHoopMenu;
   UNTIL ExitRequest;
   HoopMenu.Done;
   CUPSDone;
END.




