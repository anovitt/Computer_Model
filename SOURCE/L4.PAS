

PROGRAM MotionNearL4;   {L4.PAS}



Uses Crt, Graph, CUPSMupp, CUPS, CupsGui;

CONST
   neq  = 4;

TYPE
   Vector = Array[1..4] of Real;

VAR
   L4Menu                          : TMenu;
   OrbitHotKeys, PoincareHotKeys   : THotKeys;
   ThreeDHotKeys                   : THotKeys;
   Sliders                         : TSliders;
   Key                             : Byte;
   MassRatio                       : real;
   Lag                             : Integer;
   Energy                          : real;
   x0, y0, xv0, yv0                : Real;
   xOld, yOld, xNew, yNew          : Real;
   xMin, xMax, yMin, yMax          : Real;
   MinX, MinY                      : Real;
   MaxX, MaxY                      : Real;
   MaxZ, MinZ                      : Real;
   dx, dy, vx, vy                  : Real;
   State                           : Vector;
   MassRatioChosen: Boolean;
   DataChosen                      : Boolean;
   PlotOrbit                       : Boolean;
   Action                          : Boolean;
   Pause                           : Boolean;
   DataOK                          : Boolean;
   exitRequest                     : Boolean;
   Poincare                        : Boolean;
   FirstPlot                       : Boolean;
   LightMenu                       : Boolean;
   PoincareOnly                    : Boolean;
   ThreeDim                        : Boolean;
   SetView                         : Boolean;
   InertialAxes                    : Boolean;
   KeyInput                        : Boolean;
   vy0Positive                     : Boolean;
   CrossSign                       : Integer;
   MapColor                        : Integer;
   PxMin, PxMax, PyMin, PyMax      : Real;  {Graph limits for the Poincare maps.}
   Time, StepSize                  : Real;
   Theta, ThetaDeg                 : Real;
   Phi, PhiDeg                     : Real;
   ProjMatrix                      : ARRAY[1..2, 1..3] OF Real;
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

{------------------------------------------------------------------------}

PROCEDURE SetUpL4Menu;
VAR
   I      : Integer;
BEGIN
   With L4Menu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'General information');
       row(2,2, 'Observing orbits');
       row(2,3, 'Poincare maps');
       row(2,4, 'Running 2-D Poincare maps');
       row(2,5, 'Running 3-D Poincare maps');
       row(2,6, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter mass parameter');
       row(3,2, 'See orbits with fixed axes');
       row(3,3, 'See orbits with rotating axes');
       row(3,4, 'See Poincare maps');
       row(3,5, 'See Poincare maps in 3-D');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   L4Menu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpOrbitHotKeys;
BEGIN
   WITH OrbitHotKeys DO
   BEGIN
      OrbitHotKeys.Init(4);
      Key[1] := 'F2-Stop';
      Key[2] := 'F5-Faster';
      Key[3] := 'F6-Slower';
      Key[4] := 'F10-Menu';
   END;
   OrbitHotKeys.BackColor := Blue;
   OrbitHotKeys.HotKeyColor := Yellow;
   OrbitHotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPoincareHotKeys;
BEGIN
   WITH PoincareHotKeys DO
   BEGIN
      PoincareHotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Stop';
      Key[3] := 'F3-NewMap';
      Key[4] := 'F4-ReScale';
      Key[5] := 'F10-Menu';
   END;
   PoincareHotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpThreeDHotKeys;
BEGIN
   WITH ThreeDHotKeys DO
   BEGIN
      ThreeDHotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Input';
      Key[4] := 'F4-View';
      Key[5] := 'F10-Menu';
   END;
   ThreeDHotKeys.BackColor := Red;
   ThreeDHotKeys.HotKeyColor := Yellow;
   ThreeDHotKeys.Display;
END;

{------------------------------------------------------------------------}

FUNCTION L4Data(VAR MassRatio: real): Boolean;
VAR
   L4Dat       : TInputScreen;
BEGIN
WITH L4Dat DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.25, 0.75);
      LoadLine('');
      LoadLine('            Data for motion close to L4  ');
      LoadLine('');
      LoadLine(' Enter the mass ratio; it should be between 0 and 1.  ');
      LoadLine('           Mass ratio = {         }');
      LoadLine('');
      LoadLine('    Note that L4 is unstable if the mass ratio');
      LoadLine(' is greater than 0.0385209, or is equal to');
      LoadLine(' 0.0135160 or 0.0242939.');
      LoadLine('');
      LoadLine('             [  OK  ]           [Cancel]');
      SetNumber(1, MassRatio);
      SetNumberLimits(1, 0.000001, 0.999999);
      AcceptScreen;
      L4Data := NOT Canceled;
      IF Canceled THEN Exit;
      MassRatio := GetNumber(1);
      DefineScale(1, -MassRatio - 0.5, 1 - MassRatio + 0.5, -0.5, 1.2);
      MassRatioChosen := True;
      Done;
   END;
END;

{----------------------Graphics Procedures--------------------------------}

{------------------------------------------------------------------------}

PROCEDURE Cross(xCross, yCross: Real);
VAR
   xSize, ySize: Integer;
   xC, yC      : Integer;
BEGIN
   xSize := 10;
   ySize := 10;
   xC := MapX(xCross);
   yC := MapY(yCross);
   Line(xC - xSize, yC, xC + xSize, yC);
   Line(xC, yC - ySize, xC, yC + ySize);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpGraphics;
BEGIN
   SetBkColor(Black);
   SetColor(Yellow);
   DefineViewPort(1, 0.05, 0.95, 0.07, 0.95);
   DefineViewPort(2, 0, 1, 0.9, 0.95);
   DefineScale(2, 0, 1, 0, 2);
   DefineViewPort(4, 0, 1, 0, 0.05);
   DefineScale(4, 0, 1, 0, 2);
   DefineViewPort(5, 0, 0.495, 0.07, 0.95);
   DefineViewPort(6, 0.505, 1, 0.07, 0.95);
   DefineViewPort(7, 0.75, 1, 0.07, 0.4);
   DefineViewPort(9, 0, 0.65, 0.07, 0.93);
   DefineViewPort(8, 0.75, 1, 0.6, 0.93);
   DefineScale(7, -2, 2, -2, 2);
   DefineScale(8, -2, 2, -1.5, 1.5);
   SelectScale(1);
END;

{------------------------------------------------------------------------}

Procedure SetUpScreen;
VAR
   xSc, ySc: integer;
BEGIN
   IF PoincareOnly THEN Exit;
   HideCursor;
   FirstPlot := True;
   DataChosen := False;
   GraphBackColor := DarkGray;
   IF NOT Poincare THEN OpenViewPort(1) ELSE OpenViewPort(5);
   SelectScale(1);
   {IF NOT Poincare THEN SetBkColor(Blue) ELSE SetBkColor(Black); }
   SetColor(White);
   PlotSymbol(- MassRatio, 0, 'o');
   Map(- MassRatio, -0.1, xSc, ySc);
   OutTextXY(xSc, ySc, 'A');
   PlotSymbol(1 - MassRatio, 0, 'o');
   Map(1 - MassRatio, -0.1, xSc, ySc);
   OutTextXY(xSc, ySc, 'B');
   Cross(0.5-MassRatio, 0.866);
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE DrawInertialScreen(STime : Real; SColor : Word);
VAR
   SaveColor           : Word;
   Angle               : Real;
   xPlot, yPlot        : Real;
   CosAngle,SinAngle   : Real;

PROCEDURE Rotate(x0, y0 : Real; VAR x1, y1 : Real);
BEGIN
   x1 := x0*CosAngle - y0*SinAngle;
   y1 := x0*SinAngle + y0*CosAngle;
END;

BEGIN
   SaveColor := GetColor;
   SetColor(SColor);
   Angle := STime;
   CosAngle := Cos(Angle);
   SinAngle := Sin(Angle);
   Rotate(-MassRatio, 0, xPlot, yPlot);
   PlotSymbol(xPlot, yPlot, 'E');
   Rotate(1-MassRatio, 0, xPlot, yPlot);
   PlotSymbol(xPlot, yPlot, 'M');
   Rotate(0.5 - MassRatio, 0.866, xPlot, yPlot);
   PlotSymbol(xPlot, yPlot, '.');
   Rotate(State[1], State[3], xPlot, yplot);
   PlotSymbol(xPlot, yPlot, 'o');
   SetColor(SaveColor);
END;

{-------------------Procedures for integrating orbits--------------------}


Function EnergyFun(xf, yf, mu: real): real;
VAR
   rho1, rho2, val: real;
BEGIN
   rho1 := Sqrt((xf + mu)*(xf + mu) + yf*yf);
   rho2 := Sqrt((xf - 1 + mu)*(xf - 1 + mu) + yf*yf);
   IF (rho1 < (1 - mu)/500) OR (rho2 < mu/500)
   THEN EnergyFun := 50
   ELSE
   BEGIN
      val := xf*xf + yf*yf + mu*(1 - mu) + 2*((1 - mu)/rho1 + mu/rho2);
      if val > 50 then val := 50;
      EnergyFun := val;
   END;
END;

Procedure Fun(x: real; y: Vector; VAR z: Vector);
VAR
   Term1, Term2: real;
{y[1] and y[3] are components of position; y[2] and y[4] are components of velocity,}
BEGIN
   Term1 := Sqr(y[1]+MassRatio) + Sqr(y[3]);
   Term2 := Sqr(y[1]-1+MassRatio) + Sqr(y[3]);
   Term1 := (1-MassRatio)/(Term1 * Sqrt(Term1)) ;
   Term2 := MassRatio/(Term2 * Sqrt(Term2)) ;
   z[1] := y[2];
   z[3] := y[4];
   z[2] := 2*y[4]+y[1]-(y[1]+MassRatio)*Term1 - (y[1]-1+MassRatio)*Term2 ;
   z[4] := -2*y[2]+y[3]*(1 - Term1 - Term2);
END;

{-----------------------------------------------------------------------}

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

{--------------End of procedures for integrating orbits-----------------}
{------------------Procedures for plotting orbits-----------------------}

FUNCTION StartData(Mu: Real; VAR y: Vector): Boolean;
VAR
   StartDat       : TInputScreen;
BEGIN
WITH StartDat DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.38, 0.7);
      LoadLine('');
      LoadLine('      Initial conditions close to L4  ');
      LoadLine('');
      LoadLine('  Position: dx = {      },  dy = {      }');
      LoadLine('  Velocity: vx = {      },  vy = {      }');
      LoadLine('');
      LoadLine('                [  OK  ]         ');
      SetNumber(1, dx);
      SetNumberLimits(1, -1, 1);
      SetNumber(2, dy);
      SetNumberLimits(1, -1, 1);
      SetNumber(3, vx);
      SetNumberLimits(1, -1, 1);
      SetNumber(4, vy);
      SetNumberLimits(1, -1, 1);
      AcceptScreen;
      StartData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         dx := GetNumber(1);
         y[1] := dx + (1 - 2*Mu)/2;
         dy := GetNumber(2);
         y[3] := dy + Sqrt(3)/2;
         vx := GetNumber(3);
         y[2] := vx;
         vy := GetNumber(4);
         y[4] := vy;
      END;
      Done;
   END; 
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpRotatingOrbitPlot;

BEGIN
   IF NOT StartData(MassRatio, State) THEN Exit;
   InertialAxes := False;
   ClearMuppetPort;
   SetUpScreen;
   Energy := EnergyFun(State[1], State[3], MassRatio) -
                            State[2]*State[2] - State[4]*State[4];
   Message('Energy for these conditions: C = '
                       +NumStr(Energy, 10, 7));
   Time := 0;                   
   StepSize := 0.1;
   xOld := State[1];
   yOld := State[3];
   Lag := 100;
   SetUpOrbitHotKeys;
   SetColor(Yellow);
   GraphBackColor := DarkGray;
   SelectViewPort(1);
   SelectScale(1);
   SetColor(Yellow);
   PlotOrbit := True;
   Action := True;
   LightMenu := False;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpInertialOrbitPlot;
BEGIN
   IF NOT StartData(MassRatio, State) THEN Exit;
   InertialAxes := True;
   ClearMuppetPort;
   Energy := EnergyFun(State[1], State[3], MassRatio) -
                            State[2]*State[2] - State[4]*State[4]; 
   Message('Energy for these conditions: C = '
                       +NumStr(Energy, 10, 7));
   Time := 0;                   
   StepSize := 0.1;
   Lag := 100;
   SetUpOrbitHotKeys;
   SetColor(Yellow);
   GraphBackColor := DarkGray;
   OpenViewPort(1);
   SelectScale(8);
   DrawInertialScreen(0, Yellow);
   PlotOrbit := True;
   Action := True;
   LightMenu := False;
END;


{-----------------------------------------------------------------------}

PROCEDURE MoveOrbit;
BEGIN
   Delay(Lag);
   Step(Time, StepSize, 0.000001, State, Time, StepSize, State);
   xNew := State[1]; yNew := State[3];
   PlotLine(xOld, yOld, xNew, yNew);
   xOld := xNew; yOld := yNew;
END;

{-----------------------------------------------------------------------}

PROCEDURE MoveInertialOrbit;
BEGIN
   Delay(Lag);
   DrawInertialScreen(Time, GraphBackColor);
   Step(Time, StepSize, 0.00000001, State, Time, StepSize, State);
   DrawInertialScreen(Time, Yellow);
END;

{------------------End of procedures for plotting orbits------------------}
{------------------Procedures for plotting Poincare maps------------------}

FUNCTION XDisp(Delta : Integer) : Integer;
BEGIN
   XDisp := Trunc(Delta*xScreenRatio);
END;

FUNCTION YDisp(Delta : Integer) : Integer;
BEGIN
   YDisp := Trunc(Delta*yScreenRatio);
END;

{-----------------------------------------------------------------------}


PROCEDURE MakeMapScreen;
VAR
   xSc, ySc: Integer;
   BoundStr: String;
   xL4, yL4: Real;
   x, Delx : Real;
   Test    : Real;
   i       : Integer;
   Region  : Boolean;
   yOld, xOld    : Real;
BEGIN
   GraphBackColor := Black;
   SetBkColor(Black);
   HideCursor;
   ClearMuppetPort;
   LightMenu := False;
   SetUpScreen;
   IF PoincareOnly THEN OpenViewPort(1) ELSE OpenViewPort(6);
   SelectScale(6);
   SetColor(Yellow);
   xL4 := 0;
   yL4 := 0;
   IF (PyMin - yL4)*(PyMax - yL4) < 0 THEN
   BEGIN
      PlotLine(PxMin, yL4, PxMax, yL4);
      Map(PxMin, yL4, xSc, ySc);
      Str(PxMin:5:3, BoundStr);
      OutTextxy(xSc, ySc-YDisp(10), BoundStr);
      Map(PxMax, yL4, xSc, ySc);
      Str(PxMax:5:3, BoundStr);
      OutTextxy(xSc-XDisp(50), ySc-YDisp(10), BoundStr);
      OutTextxy(xSc-XDisp(40), ySc+YDisp(10), 'dx');
   END
   ELSE
   BEGIN
      Map(PxMin, 0.5*(PyMin + PyMax), xSc, ySc);
      Str(PxMin:5:3, BoundStr);
      OutTextxy(xSc, ySc, BoundStr);
      Map(PxMax, 0.5*(PyMin + PyMax), xSc, ySc);
      Str(PxMax:5:3, BoundStr);
      OutTextxy(xSc-XDisp(50), ySc, BoundStr);
      OutTextxy(xSc-XDisp(40), ySc+YDisp(20), 'dx');
   END;
   IF (PxMin- xL4)*(PxMax - xL4) < 0 THEN
   BEGIN
      PlotLine(xL4, PyMin, xL4, PyMax);
      Map(xL4, PyMin, xSc, ySc);
      Str(PyMin:6:3, BoundStr);
      OutTextxy(xSc+5, ySc-YDisp(10), BoundStr);
      Map(xL4, PyMax, xSc, ySc);
      Str(PyMax:6:3, BoundStr);
      OutTextxy(xSc+XDisp(5), ySc+YDisp(10), BoundStr);
      OutTextxy(xSc-XDisp(20), ySc+YDisp(10), 'vx');
   END
   ELSE
   BEGIN
      Map(0.5*(PxMin + PxMax), PyMin, xSc, ySc);
      Str(PxMin:6:3, BoundStr);
      OutTextxy(xSc, ySc-YDisp(10), BoundStr);
      Map(0.5*(PxMin + PxMax), PyMax, xSc, ySc);
      Str(PyMax:6:3, BoundStr);
      OutTextxy(xSc, ySc+YDisp(10), BoundStr);
      OutTextxy(xSc-XDisp(25), ySc+YDisp(10), 'vx');
   END;
   LightMenu := False;

 {  EnergyFun(x0, y0, MassRatio) - Energy - xv0*xv0; }
   SetColor(LightGray);
   Delx := (PxMax - PxMin)/100;
   Region := False;
   FOR i := 0 TO 100 DO
   BEGIN
      x := PxMin + i*Delx;
      Test := EnergyFun(x+0.5-MassRatio, Sqrt(3)/2, MassRatio) - Energy;
      IF (i = 0) AND (Test > 0) THEN
      BEGIN
         yOld := Sqrt(Test);
         xOld := x;
         Region := True;
      END;
      IF (NOT Region) AND (Test > 0) THEN
      BEGIN
         yOld := Sqrt(Test);
         xOld := x;
         Region := True;
         Line(MapX(x), MapY(yOld), MapX(x), MapY(-yOld));
      END;
      IF (Region) AND (Test < 0) THEN
      BEGIN
         Region := False;
         Line(MapX(xOld), MapY(yOld), MapX(xOld), MapY(-yOld));
      END;
      IF Region AND (Test > 0) THEN
      BEGIN
         Test := Sqrt(Test);
         Line(MapX(xOld), MapY(yOld), MapX(x), MapY(Test));
         Line(MapX(xOld), MapY(-yOld), MapX(x), MapY(-Test));
         xOld := x;
         yOld := Test;
      END;
   END;
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE SetNewMapLimits;
VAR
   MapDat    : TInputScreen;
   i         : Integer;
BEGIN
   WITH MapDat DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.7, 0.95);
      LoadLine('');
      LoadLine('   Min x = {        }   Max x = {        }');
      LoadLine('   Min y = {        }   Max y = {        }');
      LoadLine('');
      LoadLine('                  [  OK  ]');
      SetNumber(1, PxMin);
      SetNumber(2, PxMax);
      SetNumber(3, PyMin);
      SetNumber(4, PyMax);
      REPEAT
         AcceptScreen;
         PxMin := GetNumber(1);
         PxMax := GetNumber(2);
         PyMin := GetNumber(3);
         PyMax := GetNumber(4);
         IF (PxMin >= PxMax) OR (PyMin >= PyMax) THEN
           Announce('You have confused upper and lower limits.Try again.');
      UNTIL (PxMin < PxMax) AND (PyMin < PyMax);
      Done;
   END;
   DefineScale(6, PxMin, PxMax, PyMin, PyMax);
   MakeMapScreen;
END;

{------------------------------------------------------------------------}

PROCEDURE StartPoincareMap(Energy, MassRatio: Real; VAR x0, y0, xv0, yv0: Real);
VAR
   Inside      : Boolean;
   VSquare     : Real;
   dx0         : Real;
   xSc, ySc    : Integer;
   a           : Integer;
   PositionOK  : Boolean;
   dxOld, xvOld : Real;
   x            : Real;
   y, z         : Vector;

PROCEDURE ChangeMapColor(ColorIn: Integer; VAR ColorOut: Integer);
BEGIN
   ColorOut := ColorIn + 1;
   IF ColorOut = 4 THEN ColorOut := 5;
   IF ColorOut = 6 THEN ColorOut := 7;
   IF ColorOut = 8 THEN ColorOut := 9;
   IF ColorOut = 16 THEN ColorOut := 2;
END;

{------------------------------------------------------------------------}

PROCEDURE QueryKeyOrMouse;
CONST
   RBNames : string = '12345678';
VAR
   Input         : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.32, 0.68);
      LoadLine('');
      LoadLine('  Use keyboard #1    or mouse #1');
      LoadLine('');
      LoadLine('  Take initial y-velocity component');
      LoadLine('      positive #2 or negative #2');
      LoadLine('');
      LoadLine('              [  OK  ]');
      IF KeyInput THEN SetRadioButton(RBNames[1], 1)
                  ELSE SetRadioButton(RBNames[1], 2);
      IF vy0Positive THEN SetRadioButton(RBNames[2], 1)
                     ELSE SetRadioButton(RBNames[2], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInput := True ELSE KeyInput := False;
      IF GetRadioButton(RBNames[2]) = 1 THEN
      vy0Positive := True ELSE vy0Positive := False;
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION PromptInitialConditions : Boolean;
VAR
   Input         : TInputScreen;
   InputOK       : Boolean;
   VSquare       : Real;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Enter initial conditions. If they are');
      LoadLine('  not consistent with the chosen energy,');
      LoadLine('  then this screen will reappear.');
      LoadLine('');
      LoadLine('    x-distance from L4: dx = {       }');
      LoadLine('  x-velocity component: vx = {       }');
      LoadLine('');
      LoadLine('          [  OK  ]         [Cancel]');
      SetNumber(1, dx);
      SetNumber(2, vx);
      InputOK := False;
      REPEAT
         AcceptScreen;
         dx := GetNumber(1);
         vx := GetNumber(2);
         x0 := dx + (1 - 2*MassRatio)/2;
         y0 := Sqrt(3)/2;
         xv0 := vx;
         VSquare := EnergyFun(x0, y0, MassRatio) - Energy - vx*vx;
         IF Abs(VSquare) < 0.00001 THEN VSquare := 0;
         IF (VSquare < 0) AND (NOT Canceled)
            THEN Announce('Forbidden region. Please try again.');
      UNTIL (VSquare >= 0) OR Canceled;
      PromptInitialConditions := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
      IF VSquare >= 0 THEN yv0 := Sqrt(VSquare);
      IF NOT PoincareOnly THEN SelectViewPort(6)
      ELSE SelectViewPort(1);
      SelectScale(6);
      SetColor(MapColor);
      PlotSymbol(dx, xv0, '.');
      Done;
   END;
END;

{------------------------------------------------------------------------}

BEGIN
   QueryKeyOrMouse;
   y0 := Sqrt(3)/2;
   IF KeyInput THEN
   BEGIN
      IF NOT PromptInitialConditions THEN Exit;
      PlotOrbit := True;
      ChangeMapColor(MapColor, MapColor);
   END
   ELSE
   BEGIN
      Message('         Click on a starting point');
      IF NOT PoincareOnly THEN
      BEGIN
         MouseBorders(Trunc(GetMaxX/2), GetMaxY, GetMaxX, 0);
         SelectViewPort(6);
      END
      ELSE SelectViewPort(1);
      SelectScale(6);
      Delay(500);
      dxOld := 0;
      xvOld := 0;
      SetColor(White);
      ChangeMapColor(MapColor, MapColor);
      REPEAT
         IF PoincareOnly THEN MousePosn(dx0, xv0, 1, 6, Inside)
                         ELSE MousePosn(dx0, xv0, 6, 6, Inside);
         IF Abs(MapX(dxOld)-MapX(dx0)) + Abs(MapY(xvOld)-MapY(xv0)) > 1 THEN
         BEGIN
            RubOutXY(0.5, 0.981, 30, Blue);
            PrintXY(0.5, 0.981, 'dx = '+NumStr(dx0, 7, 5)+', vx = '
                                     +NumStr(xv0, 7, 5));
         END;
         x0 := 0.5 - MassRatio + dx0;
         VSquare := EnergyFun(x0, y0, MassRatio) - Energy - xv0*xv0;
         IF VSquare < 0 THEN
         BEGIN
            PositionOK := False;
            Sound(440);
            Delay(100);
            NoSound;
         END
         ELSE PositionOK := True;
         dxOld := dx0;
         xvOld := xv0;
      UNTIL MouseClicked(a,a) AND (PositionOK = True);
      IF PoincareOnly THEN MousePosn(dx0, xv0, 1, 6, Inside)
                      ELSE MousePosn(dx0, xv0, 6, 6, Inside);
      x0 := 0.5 - MassRatio + dx0;
      Message('');
      yv0 := Sqrt(VSquare);
      SetColor(MapColor);
      PlotSymbol(dx0, xv0, '.');
      MouseBorders(0, GetMaxY, GetMaxX, 0);
      PlotOrbit := True;
   END;
   IF NOT vy0Positive THEN yv0 := - yv0;
END;


{------------------------------------------------------------------------}

PROCEDURE FindPoincareCrossing(LocalState: Vector);
VAR
   StepSize: Real;
   Counter: Integer;
   StoreColor: Integer;
BEGIN
   Counter := 0;
   REPEAT
      Counter := Counter + 1;
      StepSize := - (LocalState[3]-0.866025)/LocalState[4];
      Step(Time, StepSize, 0.00001, LocalState, Time, StepSize, LocalState);
   UNTIL (Abs(LocalState[3]-0.866025) < 0.0001) OR (Counter = 10);
   IF Counter < 10 THEN
   BEGIN
      IF PoincareOnly THEN SelectViewPort(1) ELSE SelectViewPort(6);
      SelectScale(6);
      HideCursor;
      StoreColor := GetColor;
      {IF LocalState[4] > 0 THEN SetColor(MapColor) ELSE SetColor(Blue);}
      PlotSymbol(LocalState[1] - 0.5 + MassRatio, LocalState[2], '.');
      SetColor(StoreColor);
      ShowCursor;
      SelectViewPort(5);
      SelectScale(1);
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE StartPoincare(x0, y0, xv0, yv0, MassRatio: Real);
BEGIN
   State[1] := x0;
   State[2] := xv0;
   State[3] := y0;
   State[4] := yv0;
   Time := 0;
   StepSize := 0.1;
   xOld := x0; yOld := y0;
   SelectViewPort(5);
   SelectScale(1);
   IF (State[3] - 0.8660254) > 0 THEN CrossSign := 1 ELSE CrossSign := -1;
   SetUpPoincareHotKeys;
   {PlotOrbit := True;}
   Action := True;
END;

{------------------------------------------------------------------------}

PROCEDURE MovePoincare;
BEGIN
   Delay(10);
   Step(Time, StepSize, 0.000001, State, Time, StepSize, State);
   IF CrossSign*(State[3] - 0.8660254) < 0.0 THEN
   BEGIN
      FindPoincareCrossing(State);
      CrossSign := - CrossSign;
   END;
   xNew := State[1]; yNew := State[3];
   IF NOT PoincareOnly THEN PlotLine(xOld, yOld, xNew, yNew);
   xOld := xNew; yOld := yNew;
END;

{-----------------------------------------------------------------------}

FUNCTION GetEnergy(VAR Energy: Real): Boolean;
VAR
   EnergyDat     : TInputScreen;
BEGIN
   WITH EnergyDat DO
   BEGIN
      Init;
      DefineInputPort(0.25,0.75, 0.3,0.6);
      LoadLine('');
      LoadLine('Enter the energy for the Poincare');
      LoadLine('maps. It should be very close to 3.');
      LoadLine('      Energy = {        }');
      LoadLine('');
      LoadLine('   [  OK  ]        [Cancel]');
      SetNumber(1, Energy);
      AcceptScreen;
      GetEnergy := NOT Canceled;
      IF Canceled THEN Exit;
      Energy := GetNumber(1);
      Done;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE QueryPoincareMap;
CONST
   RBNames : string = '12345678';
VAR
   Input           : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.4, 0.65);
      LoadLine('');
      LoadLine('  See Poincare maps and orbits: #1');
      LoadLine('  See only Poincare maps:       #1');
      LoadLine('');
      LoadLine('              [  OK  ]');
      IF PoincareOnly THEN SetRadioButton(RBNames[1], 2)
                      ELSE SetRadioButton(RBNames[1], 1);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      PoincareOnly := False ELSE PoincareOnly := True;
      Done;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE MakePoincareMap;
BEGIN
   QueryPoincareMap;
   IF NOT GetEnergy(Energy) THEN Exit;
   Poincare := True;
   HideCursor;
   PxMin := -0.2;
   PxMax := 0.2;
   PyMin := -0.3;
   PyMax := 0.3;
   DefineScale(6, PxMin, PxMax, PyMin, PyMax);
   MakeMapScreen;
   IF NOT PoincareOnly THEN SelectViewPort(5);
   MapColor := 2;
   ShowCursor;
   StartPoincareMap(Energy, MassRatio, x0, y0, xv0, yv0);
   StartPoincare(x0, y0, xv0, yv0, MassRatio);
END;

{--------------End of procedures for plottting Poincare maps- -----------}

{---------Procedures for plotting three dimsnsional Poincare maps--------}

PROCEDURE View(x, y, z : Real; VAR ViewX, ViewY: Real);
BEGIN
   ViewX := ProjMatrix[1, 1]*x + ProjMatrix[1, 2]*y;
   ViewY := ProjMatrix[2, 1]*x + ProjMatrix[2, 2]*y + ProjMatrix[2, 3]*z;
END;

{------------------------------------------------------------------------}

PROCEDURE SetViewingMatrix;
BEGIN
   ProjMatrix[1, 1] := Sin(Theta);
   ProjMatrix[1, 2] := Cos(Theta);
   ProjMatrix[1, 3] := 0;
   ProjMatrix[2, 1] := - Cos(Theta)*(Cos(Phi));
   ProjMatrix[2, 2] := - Sin(Theta)*(Cos(Phi));
   ProjMatrix[2, 3] := Sin(Phi);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawArrow2(xa, ya, xb, yb : Real; FlukeLength : Integer;
                     ArrowColor : Word; TNB: String);
VAR
   x, y                 : Integer;
   sxa, sya, sxb, syb   : LongInt;
   Delx, Dely           : Integer;
   xSc, ySc             : Integer;
   Length               : Real;
   SaveColor            : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(ArrowColor);
   sxa := MapX(xa);
   sya := MapY(ya);
   sxb := MapX(xb);
   syb := MapY(yb);
   Length := Sqrt(Sqr(sxb - sxa) + Sqr(syb - sya));
   IF Length = 0 THEN Length := 1;
   Line(sxa, sya, sxb, syb);
   x := Trunc(sxb + FlukeLength*(- (sxb - sxa) + (syb - sya))/Length);
   y := Trunc(syb + FlukeLength*(- (syb - sya) - (sxb - sxa))/Length);
   Line(sxb, syb, x, y);
   x := Trunc(sxb + FlukeLength*(- (sxb - sxa) - (syb - sya))/Length);
   y := Trunc(syb + FlukeLength*(- (syb - sya) + (sxb - sxa))/Length);
   Line(sxb, syb, x, y);
   xSc := Trunc(sxb + 10*(sxb - sxa)/Length);
   ySc := Trunc(syb + 10*(syb - sya)/Length);
   OutTextxy(xSc, ySc, TNB);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE SetScale;
VAR
  XMax, XMin, YMax, YMin : Real;

PROCEDURE Test(x, y, z : Real);
VAR
   xTest, yTest : Real;
BEGIN
    View(x, y, z, xTest, yTest);
   IF xTest > XMax THEN XMax := xTest;
   IF xTest < XMin THEN XMin := xTest;
   IF yTest > YMax THEN YMax := yTest;
   IF yTest < YMin THEN YMin := yTest;
END;

BEGIN
   XMax := 0; XMin := 0; YMax := 0; YMin := 0;
   Test(MinX, MinY, MinZ);
   Test(MaxX, MinY, MinZ);
   Test(MaxX, MinY, MaxZ);
   Test(MinX, MinY, MaxZ);
   Test(MinX, MaxY, MinZ);
   Test(MaxX, MaxY, MinZ);
   Test(MaxX, MaxY, MaxZ);
   Test(MinX, MaxY, MaxZ);
   DefineScale(6, XMin - (XMax-XMin)*0.1, XMax + (XMax-XMin)*0.1,
                  YMin - (YMax-YMin)*0.1, YMax + (YMax-YMin)*0.1);
   SelectScale(6);
END;

{------------------------------------------------------------------------}

FUNCTION FindMaxMinLimits(y : Vector): Boolean;
VAR
   MaxCoord      : Real;
   xView, yView  : Real;
BEGIN
   Time := 0;
   StepSize := 0.1;
   MaxCoord := 0;
   MinX := 0;
   MaxX := 0;
   MinY := 0;
   MaxY := 0;
   MaxZ := 0;
   MinZ := 0;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      IF MinX > y[1] - 0.5 + MassRatio THEN MinX := y[1] - 0.5 + MassRatio;
      IF MaxX < y[1] - 0.5 + MassRatio THEN MaxX := y[1] - 0.5 + MassRatio;
      IF MinY > y[2] THEN MinY := y[2];
      IF MaxY < y[2] THEN MaxY := y[2];
      IF MinZ > y[3] - 0.866025 THEN MinZ := y[3] - 0.866025;
      IF MaxZ < y[3] - 0.866025 THEN MaxZ := y[3] - 0.866025;
      IF MaxCoord < Abs(MaxX - MinX + MaxY - MinY + MaxZ - MinZ) THEN
         MaxCoord := Abs(MaxX - MinX + MaxY - MinY + MaxZ - MinZ);
   UNTIL (Time > 100) OR (MaxCoord > 10);
   IF MaxCoord < 10 THEN FindMaxMinLimits := True
                    ELSE FindMaxMinLimits := False;
END;

{------------------------------------------------------------------------}

FUNCTION PromptInitialConditions : Boolean;
VAR
   Input         : TInputScreen;
   InputOK       : Boolean;
   VSquare       : Real;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Enter initial conditions. If they are');
      LoadLine('  not consistent with the chosen energy,');
      LoadLine('  then this screen will reappear.');
      LoadLine('');
      LoadLine('    x-distance from L4: dx = {       }');
      LoadLine('  x-velocity component: vx = {       }');
      LoadLine('');
      LoadLine('          [  OK  ]         [Cancel]');
      SetNumber(1, dx);
      SetNumber(2, vx);
      InputOK := False;
      REPEAT
         AcceptScreen;
         dx := GetNumber(1);
         vx := GetNumber(2);
         State[1] := dx + (1 - 2*MassRatio)/2;
         State[3] := Sqrt(3)/2;
         State[2] := vx;
         VSquare := EnergyFun(State[1], State[3], MassRatio) - Energy - vx*vx;
         IF (VSquare < 0) AND (NOT Canceled)
            THEN Announce('Forbidden region. Please try again.');
      UNTIL (VSquare >= 0) OR Canceled;
      PromptInitialConditions := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
      IF VSquare >= 0 THEN State[4] := Sqrt(VSquare);
      IF NOT FindMaxMinLimits(State) THEN
      BEGIN
         Announce('Unbounded orbit. Impossible to scale.');
         PromptInitialConditions := False;
         Done;
         Exit;
      END;
      Time := 0;
      StepSize := 0.1;
      View(State[1]-0.5+MassRatio, State[2], State[3]-0.866, xOld, yOld);
      CrossSign := 1;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE DrawBox;
VAR
   x1, y1, x2, y2, x3, y3, x4, y4  : Real;
   x5, y5, x6, y6, x7, y7, x8, y8  : Real;
   SaveColor                       : Word;
BEGIN
   OpenViewPort(7);
   SelectScale(7);
   SaveColor := GetColor;
   SetColor(White);
  { View(MinX, MinY, MinZ, x1, y1);
   View(MaxX, MinY, MinZ, x2, y2);
   View(MaxX, MinY, MaxZ, x3, y3);
   View(MinX, MinY, MaxZ, x4, y4);
   View(MinX, MaxY, MinZ, x5, y5);
   View(MaxX, MaxY, MinZ, x6, y6);
   View(MaxX, MaxY, MaxZ, x7, y7);
   View(MinX, MaxY, MaxZ, x8, y8);}
   View(-1, -1, -1, x1, y1);
   View( 1, -1, -1, x2, y2);
   View( 1, -1,  1, x3, y3);
   View(-1, -1,  1, x4, y4);
   View(-1,  1, -1, x5, y5);
   View( 1,  1, -1, x6, y6);
   View( 1,  1,  1, x7, y7);
   View(-1,  1,  1, x8, y8);
   PlotLine(x1, y1, x2, y2);
   PlotLine(x2, y2, x3, y3);
   PlotLine(x3, y3, x4, y4);
   PlotLine(x4, y4, x1, y1);
   PlotLine(x5, y5, x6, y6);
   PlotLine(x6, y6, x7, y7);
   PlotLine(x7, y7, x8, y8);
   PlotLine(x8, y8, x5, y5);
   PlotLine(x1, y1, x5, y5);
   PlotLine(x2, y2, x6, y6);
   PlotLine(x3, y3, x7, y7);
   PlotLine(x4, y4, x8, y8);
   DrawArrow2(x1, y1, x2+0.1*(x2-x1), y2+0.1*(y2-y1), 5, White, 'x');
   DrawArrow2(x1, y1, x5+0.1*(x5-x1), y5+0.1*(y5-y1), 5, White, 'vx');
   DrawArrow2(x1, y1, x4+0.1*(x4-x1), y4+0.1*(y4-y1), 5, White, 'y');
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawAxes;
VAR
   x1, y1, x2, y2    : Real;
   SaveColor         : Word;
BEGIN
   SaveColor := GetColor;
   OpenViewPort(9);
   SelectScale(6);
   View(0, 0, 0, x1, y1);
   View(MaxX, 0, 0, x2, y2);
   DrawArrow2(x1, y1, x2, y2, 10, White, 'x');
   View(0, MaxY, 0, x2, y2);
   DrawArrow2(x1, y1, x2, y2, 10, White, 'vx');
   View(0, 0, MaxZ, x2, y2);
   DrawArrow2(x1, y1, x2, y2, 10, White, 'y');
   SetColor(White);
   View(MinX, 0, 0, x2, y2);
   PlotLine(x1, y1, x2, y2);
   View(0, 0, MinZ, x2, y2);
   PlotLine(x1, y1, x2, y2);
   View(0, MinY, 0, x2, y2);
   PlotLine(x1, y1, x2, y2);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpThreeD;
BEGIN
   Theta := ThetaDeg*PI/180;
   Phi := PhiDeg*Pi/180;
   SetViewingMatrix;
   IF NOT PromptInitialConditions THEN Exit;
   ThreeDim := True;
   ClearMuppetPort;
   GraphBackColor := Black;
   LightMenu := False;
   SetScale;
   OpenViewPort(7);
   Sliders.create(1, 0, 360,ThetaDeg, 0.71, 0.43, 0.99,0,'0',
                      '360','Theta',false);
   Sliders.create(2, 0, 180, PhiDeg, 0.71, 0.07, 0.4,0,
                     '0','180','Phi',true );
   Sliders.DrawAll;
   SetColor(White);
   DrawBox;
   DrawAxes;
   SetColor(LightBlue);
   Action := True;
   Pause := True;
   Poincare := True;
   ThreeDHotKeys.Key[1] := 'F2-Start';
   ThreeDHotKeys.BackColor := Red;
   SetUpThreeDHotKeys;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleSliders;
VAR
   y     : Vector;
BEGIN
   ThetaDeg := Sliders.Value(1);
   PhiDeg := Sliders.Value(2);
   Theta := ThetaDeg*Pi/180;
   Phi := PhiDeg*Pi/180;
   SetViewingMatrix;
   SetScale;
   OpenViewPort(7);
   DrawBox;
   DrawAxes;
END;

{------------------------------------------------------------------------}

PROCEDURE FindThreeDPoincareCrossing;
VAR
   Counter         : Integer;
   SaveStepSize    : Real;
BEGIN
   SaveStepSize := StepSize;
   Counter := 0;
   REPEAT
      Counter := Counter + 1;
      StepSize := - (State[3]-0.866025)/State[4];
      Step(Time, StepSize, 0.00001, State, Time, StepSize, State);
   UNTIL (Abs(State[3]-0.866025) < 0.0001) OR (Counter = 10);
   IF Counter < 10 THEN
   BEGIN
      SetColor(White);
      View(State[1]-0.5+MassRatio, State[2], State[3]-0.866, xNew, yNew);
      PlotSymbol(xNew, yNew, '.');
      Delay(500);
      SetColor(Yellow);
   END;
   StepSize := SaveStepSize;
END;


{------------------------------------------------------------------------}

PROCEDURE TakeThreeDStep;
BEGIN
   Delay(10);
   Step(Time, StepSize, 0.000001, State, Time, StepSize, State);
   IF CrossSign*(State[3] - 0.8660254) < 0.0 THEN
   BEGIN
      FindThreeDPoincareCrossing;
      CrossSign := - CrossSign;
   END;
   View(State[1]-0.5+MassRatio, State[2], State[3]-0.866, xNew, yNew);
   IF CrossSign = 1 THEN SetColor(LightGray) ELSE SetColor(LightRed);
   Line(MapX(xOld), MapY(yOld), MapX(xNew), MapY(yNew));
   xOld := xNew; yOld := yNew;
END;

{-----End of procedures for plotting three dimensional Poincare maps-----}
{------------------------------------------------------------------------}


PROCEDURE GetData;
BEGIN 
   DataOK := False;
   Poincare := False;
   GraphBackColor := DarkGray;
   IF NOT L4Data(MassRatio) THEN LightMenu := True ELSE
END;

{------------------------------------------------------------------------}

PROCEDURE HandleOrbitHotKeys(key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
      1: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH OrbitHotKeys DO Key[1] := 'F2-Run';
               OrbitHotKeys.BackColor := Red;
               OrbitHotKeys.Display;
               SetColor(Yellow);
            END
            ELSE
            BEGIN
               Action := True;
               WITH OrbitHotKeys DO Key[1] := 'F2-Stop';
               OrbitHotKeys.BackColor := Blue;
               OrbitHotKeys.Display;
               SetColor(Yellow);
            END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag;
      3: Lag := Lag + DelLag;
      4: BEGIN PlotOrbit := False;
               InertialAxes := False;
               OrbitHotKeys.BackColor := Blue;
               LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleThreeDHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HelpAstr.Hlp', 'L4Poincare3DHotKeysHelp');
      2: BEGIN
            IF SetView OR (NOT Action) THEN Exit;
            SetView := False;
            Message('');
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH ThreeDHotKeys DO Key[2] := 'F2-Start';
               ThreeDHotKeys.BackColor := Red;
               ThreeDHotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := False;
               WITH ThreeDHotKeys DO Key[2] := 'F2-Stop';
               ThreeDHotKeys.BackColor := Blue;
               ThreeDHotKeys.Display;
            END;
         END;
      3: BEGIN
            IF SetView THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH ThreeDHotKeys DO Key[2] := 'F2-Run';
               ThreeDHotKeys.BackColor := Red;
               ThreeDHotKeys.Display;
            END;
            SetView := False;
            Message('');
            DrawAxes;
            PromptInitialConditions;
         END;
      4: BEGIN
            IF SetView THEN
            BEGIN
               SetView := False;
               WITH ThreeDHotKeys DO Key[4] := 'F4-View';
               ThreeDHotKeys.Display;
               Message('');
            END
            ELSE
            BEGIN
               SetView := True;
               WITH ThreeDHotKeys DO Key[4] := 'F4-Accept';
               ThreeDHotKeys.Display;
               Message('  Use the sliders to set a new direction of viewing');
            END
         END;
      5: BEGIN
            Pause := False;
            ThreeDim := False;
            Poincare := False;
            Action := False;
            SetView := False;
            LightMenu := True;
            ThreeDHotKeys.Clear;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePoincareHotKeys(Key : Byte);
BEGIN
   CASE Key OF
     1: ShowHelp('HelpAstr.hlp', 'L4Poincare2DHotKeysHelp');
     2: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH PoincareHotKeys DO Key[2] := 'F2-Run';
               PoincareHotKeys.BackColor := Red;
               PoincareHotKeys.Display;
               SetColor(Yellow);
            END
            ELSE
            BEGIN
               Action := True;
               WITH PoincareHotKeys DO Key[2] := 'F2-Stop';
               PoincareHotKeys.BackColor := Blue;
               PoincareHotKeys.Display;
               SetColor(Yellow);
            END;
         END;
      3: BEGIN
            IF NOT Action THEN
            BEGIN
               Action := True;
               WITH PoincareHotKeys DO Key[2] := 'F2-Stop';
               PoincareHotKeys.BackColor := Blue;
               PoincareHotKeys.Display;
               SetColor(Yellow);
            END;
            PlotOrbit := False;
            GraphBackColor := Black;
            SetBkColor(Black);
            SetUpScreen;
            StartPoincareMap(Energy, MassRatio, x0, y0, xv0, yv0);
            StartPoincare(x0, y0, xv0, yv0, MassRatio);
         END;
      4: BEGIN
            IF NOT Action THEN
            BEGIN
               Action := True;
               WITH PoincareHotKeys DO Key[2] := 'F2-Stop';
               PoincareHotKeys.BackColor := Blue;
               PoincareHotKeys.Display;
               SetColor(Yellow);
            END;
            PlotOrbit := False;
            ShowCursor;
            SetNewMapLimits;
            StartPoincareMap(Energy, MassRatio, x0, y0, xv0, yv0);
            StartPoincare(x0, y0, xv0, yv0, MassRatio);
         END;
      5: BEGIN
            Poincare := False;
            PoincareOnly := False;
            PlotOrbit := False;
            PoincareHotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleL4Menu;

BEGIN
   With L4Menu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpAstr.Hlp', 'L4AboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpAstr.Hlp', 'L4AboutModelA');
                  ShowHelp('HelpAstr.Hlp', 'L4AboutModelB');
               END;
            2: ShowHelp('HelpAstr.Hlp', 'L4RunningOrbits');
            3: ShowHelp('HelpAstr.Hlp', 'L4PoincareMaps');
            4: BEGIN
                  ShowHelp('HelpAstr.Hlp', 'L4RunPoincare2dA');
                  ShowHelp('HelpAstr.Hlp', 'L4RunPoincare2dB');
               END;
            5: ShowHelp('HelpAstr.Hlp', 'L4RunPoincare3d');
            6: BEGIN
                  ShowHelp('WalkThru.hlp', 'L41');
                  ShowHelp('WalkThru.hlp', 'L42');
                  ShowHelp('WalkThru.hlp', 'L43');
                  ShowHelp('WalkThru.hlp', 'L44');
                  ShowHelp('WalkThru.hlp', 'L45');
               END;
         END;
      3: CASE RowChosen OF
            1: GetData;
            2: SetUpInertialOrbitPlot;
            3: SetUpRotatingOrbitPlot;
            4: MakePoincareMap;
            5: SetUpThreeD;
         {   6: IF Poincare THEN MakePoincareMap
               ELSE
                  BEGIN
                     ClearMuppetPort;
                     SetUpScreen;
                  END; }
         END;
    END;
END;

{------------------------------------------------------------------------}

BEGIN   {Main Program.}
   CUPSinit;
   Sliders.Init;
   exitRequest := false;
   DataChosen := False;
   MassRatioChosen := False;
   Poincare := False;
   FirstPlot := True;
   LightMenu := True;
   InertialAxes := False;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   xMin := -1.5;
   xMax := 1.5;
   yMin := -0.5;
   yMax := 1.2;
   dx := 0.02;
   dy := 0;
   Energy := 3;
   MassRatio := 0.01;
   vx := 0;
   vy := 0;
   ThetaDeg := 30;
   PhiDeg := 30;
   Lag := 10;
   PoincareOnly := False;
   KeyInput := False;
   vy0Positive := True;
   SetUpGraphics;
   Hello('HelpAstr.Hlp', 'L4AboutProgram');
   ShowCursor;
   SetUpL4Menu;
   GetData;
   REPEAT
      CheckForEvents;
      IF (ThreeDim) AND (ThreeDHotKeys.Pressed(Key)) THEN
                        HandleThreeDHotKeys(Key);
      IF (NOT Poincare) AND OrbitHotKeys.Pressed(Key) THEN
                          HandleOrbitHotKeys(Key);
      IF Poincare AND (NOT ThreeDim) AND PoincareHotKeys.Pressed(Key) THEN
                          HandlePoincareHotKeys(Key);
      IF ThreeDim AND Action AND (NOT Pause) AND NOT SetView THEN
                  TakeThreeDStep;
      IF SetView AND Sliders.Changed THEN HandleSliders;
      IF (NOT InertialAxes) AND (NOT Poincare) AND (Action)
          AND (PlotOrbit) THEN MoveOrbit;
      IF InertialAxes AND Action AND PlotOrbit THEN MoveInertialOrbit;
      IF Poincare AND Action AND PlotOrbit THEN MovePoincare;
      IF LightMenu THEN IF L4Menu.Chosen THEN HandleL4Menu;
   UNTIL  ExitRequest;
   L4Menu.done;
   CUPSDone;
   Sliders.Done;
END.
