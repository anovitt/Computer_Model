Program EconomicsOfFishing;

Uses Crt, Graph, CupsMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                      : Vector;
   FishingMenu               : TMenu;
   HotKeys                   : THotKeys;
   Sliders                   : TSliders;
   Lag                       : Integer;
   KeyInitialConditions      : Boolean;
   PlotOrbit, Pause          : Boolean;
   ExitRequest               : Boolean;
   LightMenu                 : Boolean;
   DField                    : Boolean;
   DataCanceled              : Boolean;
   Periodic                  : Boolean;
   ACoeff, APeriod, APhase   : Real;
   CCoeff, CPeriod, CPhase   : Real;
   Key                       : Byte;
   FishA, FishB, Price, Cost : Real;
   xMax, yMax, xMin, yMin    : Real;
   xOld, yOld                : Real;
   Time, StepSize            : Real;
   xEqu, yEqu                : Real;
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

{-------------------------------------------------------------------------}

PROCEDURE SetUpFishingMenu;
VAR
   I      : Integer;
BEGIN
   With FishingMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,2, 'About the program');
       row(1,1, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About periodic changes');
       row(2,3, 'About direction fields');
       row(2,4, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Draw a direction field diagram');
       row(3,3, 'Plot solutions');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   FishingMenu.Display;
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Pause';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-Input';
      Key[5] := 'F6-CleanUp';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetFishingData;
CONST
   RBNames : string = '12345678';
VAR
   FishingDat    : TInputScreen;
BEGIN
   WITH FishingDat DO
   BEGIN
      Init;
      DefineInputPort(0.14, 0.86, 0.07, 0.93);
      LoadLine('');
      LoadLine('          Data for the Economics of Fishing');
      LoadLine('');
      LoadLine('     The model is');
      LoadLine('               dx/dt = ax - bx^2 - Ex,');
      LoadLIne('               dE/dt = E(px - c).');
      LoadLine('');
      LoadLine('      For population growth a = {      }   1 < a < 10');
      LoadLine('                            b = {      } 0.1 < b < 10');
      LoadLine('  The price per unit catch, p = {      }   0 < p < 10');
      LoadLine('  The cost per unit effort, c = {      }   0 < c < 10');
      LoadLine('  The fish population, x, is measured in units,');
      LoadLine('  where one unit might represent a million fish.');
      LoadLIne('  E is the ''effort'' involved in catching fish.');
      LoadLIne('');
      LoadLine('     You have the option of letting a and c vary');
      LoadLine('  periodically. Constant: #1    Periodic: #1');
      LoadLine('  Input from the keyboard #2 or the mouse #2');
      LoadLine('');
      LoadLIne('               [  OK  ]       [Cancel]');
      SetNumber(1, FishA);
      SetNumberLimits(1, 1, 10);
      SetNumber(2, FishB);
      SetNumberLimits(2, 0.01, 10);
      SetNumber(3, Price);
      SetNumberLimits(3, 0, 10);
      SetNumber(4, Cost);
      SetNumberLimits(4, 0, 10);
      IF Periodic THEN SetRadioButton('1', 2) ELSE SetRadioButton('1', 1);
      IF KeyInitialConditions THEN SetRadioButton('2', 1)
                              ELSE SetRadioButton('2', 2);
      AcceptScreen;
      FishA := GetNumber(1);
      FishB := GetNumber(2);
      Price := GetNumber(3);
      Cost := GetNumber(4);
      IF GetRadioButton(RBNames[1]) = 1 THEN
      Periodic := False ELSE Periodic := True;
      IF GetRadioButton(RBNames[2]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      {IF Periodic THEN
         FishingMenu.RowActivate(3, 2, False) ELSE
         FishingMenu.RowActivate(3, 2, True);}
      IF FishingDat.Canceled THEN DataCanceled := True
                             ELSE DataCanceled := False;
      Done;
   END;
   xMax := 1.5*FishA/FishB;
   IF xMax < 1 THEN xMax := 1;

   yMax := 3*FishA;
   IF yMax < 1 THEN yMax := 1;
END;

{------------------------------------------------------------------------}

PROCEDURE GetPeriodicData;
VAR
   Input   : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.15, 0.85);
      LoadLine('');
      LoadLine('           Data for periodic changes');
      LoadLine('');
      LoadLine('   The growth rate for the fish is');
      LoadLine('      a*(1 + a1*Cos(2*Pi/(aPeriod)*Time + aPhase)');
      LoadLine('   Enter:        0 < a1 = {       } < 1');
      LoadLine('            0 < aPeriod = {       }');
      LoadLine('                 aPhase = {       }');
      LoadLine('');
      LoadLine('   The growth rate for the cost is');
      LoadLine('      c*(1 + c1*Cos(2*Pi/(cPeriod)*Time + cPhase)');
      LoadLine('   Enter:        0 < c1 = {       } < 1');
      LoadLine('            0 < cPeriod = {       }');
      LoadLine('                 cPhase = {       }');
      LoadLine('');
      LoadLine('                     [  OK  ]');
      SetNumber(1, ACoeff);
      SetNumber(2, APeriod);
      SetNUmber(3, APhase);
      SetNumber(4, CCoeff);
      SetNumber(5, CPeriod);
      SetNumber(6, CPhase);
      SetNumberLimits(1, 0, 1);
      SetNumberLimits(2, 0, 1000000);
      SetNumberLimits(4, 0, 1);
      SetNumberLimits(5, 0, 1000000);
      AcceptScreen;
      ACoeff := GetNumber(1);
      APeriod := GetNumber(2);
      APhase := GetNumber(3);
      CCoeff := GetNumber(4);
      CPeriod := GetNumber(5);
      CPhase := GetNumber(6);
      Done;
   END;
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
begin
   IF Periodic THEN
   BEGIN
      z[1] := FishA*y[1]*(1 + ACoeff*Cos(2*Pi*x/APeriod + APhase))
               - FishB*y[1]*y[1] - y[1]*y[2];
      z[2] := y[2]*(Price*y[1]
               - Cost*(1 + CCoeff*Cos(2*Pi*x/CPeriod + CPhase)));
   END
   ELSE
   BEGIN
      z[1] := FishA*y[1] - FishB*y[1]*y[1] - y[1]*y[2];
      z[2] := y[2]*(Price*y[1] - Cost);
   END;
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

PROCEDURE DrawEquilibria;
BEGIN
   IF (FishB < 0.01) OR Periodic THEN Exit;
   PlotSymbol(FishA/FishB, 0, '*');
   IF (Price > 0.01) AND (FishA - FishB*Cost/Price > 0) THEN
      PlotSymbol(Cost/Price, FishA - FishB*Cost/Price, '*');
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpOrbit;
BEGIN
   SelectViewPort(1);
   Time := 0;
   StepSize := 0.1;
   WITH HotKeys DO Key[1] := 'F2-Pause';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   SetColor(Yellow);
   PlotOrbit := True;
   Pause := False;
   LightMenu := False;
   xOld := y[1]; yOld := y[2];
END;

{-------------------------------------------------------------------------}

PROCEDURE StepOrbit;
BEGIN
   SetColor(Yellow);
   Delay(Lag);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF y[1] < 0 THEN y[1] := 0;
   IF y[2] < 0 THEN y[2] := 0;
   PlotLine(xOld, yOld, y[1], y[2]);
   xOld := y[1]; yOld := y[2];
   RubOutXY(0.4, 0.105, 20, Blue);
   PrintXY(0.4, 0.105, '('+NumStr(y[1], 4, 2)+', '+NumStr(y[2], 4, 2)+')');
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

{-------------------------------------------------------------------------}

PROCEDURE PromptForClick(text : string);
VAR
   dx,dy,cx,cy,a,n : integer;
   image           : TImage;
   z               : char;
   envir           : TEnvironment;
   Inside, Ins: Boolean;
   Button: Integer;
   xm, ym: Integer;
   MSave, FSave    : Real;
BEGIN
   Inside := True;
   Button := 0;
   envir.Save;
   envir.Standardize;
   SetFillStyle(SolidFill,red);
   dx := TextWidth(text)+XDisp(13);
   dy := RowHt + YDisp(3);
   cx := (GetMaxX-dx) DIV 2;
   cy := (GetMaxY-dy) DIV 8;
   Image.Get(cx,cy,cx+dx,cy+dy);
   HideMouse;
   Bar3D(cx,cy+YDisp(3),cx+dx-XDisp(3),cy+dy,3,true);
   ShowMouse;
   ClearMKBuffers;
   SetColor(Yellow);
   HideMouse;
   OutTextXY(cx+XDisp(6),cy+YDisp(8),Text);
   ShowMouse;
   Envir.Reset;
   REPEAT
      MousePosn(y[1], y[2], 1, 1, Inside);
      IF Inside AND
      (Abs(MSave - (y[1])) + Abs(FSave - (y[2])) > 0.01) THEN
      BEGIN
         RubOutXY(0.4, 0.105, 20, Blue);
         PrintXY(0.4, 0.105, '('+NumStr(y[1], 4, 2)+', '+NumStr(y[2], 4, 2)+')');
         MSave := (y[1]);
         FSave := (y[2]);
      END;
   UNTIL MouseClicked(a,a);
   envir.Save;
   envir.Standardize;
   image.put(cx,cy);
   envir.Reset;
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptInitialConditions;
var 
    x1, y1, x2, y2: integer;
    Inside        : Boolean;
    InitialDat    : TInputScreen;
BEGIN
   ShowCursor;
   Message('');
   IF KeyInitialConditions THEN
   BEGIN
         WITH InitialDat DO
         BEGIN
            Init;
            DefineInputPort(0.3, 0.7, 0.75, 0.9);
            LoadLine('  Enter initial conditions:');
            LoadLine('  x ={      }   E ={      }');
            LoadLine('      [  OK  ]    [Cancel]');
            SetNumber(1, 1);
            SetNumberLimits(1, 0, 10);
            SetNumber(2, 2);
            SetNumberLimits(2, 0, 10);
            AcceptScreen;
            y[1] := GetNumber(1);
            y[2] := GetNumber(2);
            IF InitialDat.Canceled THEN DataCanceled := True
                                   ELSE DataCanceled := False;
            Done;
         END;
   END
   ELSE
   BEGIN
      Map(0, 0, x1, y1);
      Map(xMax, yMax, x2, y2);
      x1 := x1 + Trunc(GetMaxX/10);
      x2 := x2 + Trunc(GetMaxX/10);
      y1 := y1 + Trunc(GetMaxy*0.08);
      y2 := y2 + Trunc(GetMaxy*0.08);
      MouseBorders(x1, y1, x2, y2);
      PromptForClick('Click on a starting point');
      MouseBorders(0, 0, GetMaxX, GetMaxY);
   END;
   IF NOT DataCanceled THEN SetUpOrbit ELSE HotKeys.Clear;
END;

{-------------------------------------------------------------------------}

PROCEDURE  SetUpScreen;
VAR
   FishStr, EffortStr: String;
   xSc, ySc: Integer;
   xMaxInt, yMaxInt: Integer;
   i: Integer;
BEGIN
    IF NOT DField THEN
    BEGIN
       Sliders.Create(1, 0, 10, Price, 0.05, 0.15, 0.85, 1, '0', '10',
                      'Price', True);
       Sliders.Create(2, 0, 10,  Cost, 0.95, 0.15, 0.85, 1, '0', '10',
                      'Cost', True);
       Sliders.DrawAll;
    END;
    HideCursor;
    GraphBackColor := Blue;
    OpenViewPort(1);
    LightMenu := False;
    WITH HotKeys DO Key[1] := 'F2-Pause';
    HotKeys.BackColor := Red;
    HotKeys.Display;
    {IF NOT DField THEN
    BEGIN
       FishingMenu.RowActivate(5, 1, True);
    END; }
    xMaxInt := Trunc(xMax + 0.001);
    yMaxInt := Trunc(yMax + 0.001);
    xMin := - xMax/20; yMin := - yMax/20;
    DefineScale(1, xMin, 1.1*xMax, yMin, 1.1*yMax);
    SelectScale(1);
    SetColor(LightGreen);
    PlotLine(0, 0, 0, yMax);
    PlotLine(0, 0, xMax, 0);
    PlotLine(xMaxInt, 0, xMaxInt, yMax/50);
    Map(xMaxInt, 0, xSc, ySc);
    Str(xMaxInt, FishStr);
    OutTextxy(xSc-XDisp(10), ySc+YDisp(5), FishStr);
    Map(xMax, 0, xSc, ySc);
    OutTextxy(xSc-XDisp(40), ySc - YDisp(15), 'Fish');
    PlotLine(0, yMaxInt, xMax/50, yMaxInt);
    Map(0, yMaxInt, xSc, ySc);
    Str(yMaxInt, EffortStr);
    OutTextxy(xSc+XDisp(10), ySc-YDisp(2), EffortStr);
    Map(0, yMax, xSc, ySc);
    OutTextxy(xSc, ySc - YDisp(15), 'Effort');
    DrawEquilibria;
    IF NOT DField THEN
    BEGIN
       PromptInitialConditions;
       IF DataCanceled THEN
       BEGIN
          PlotOrbit := False;
          ClearMuppetPort;
          FishingMenu.Display;
          LightMenu := True;
          DField := False;
       END
       ELSE
       BEGIN
         {  WITH HotKeys DO Key[1] := 'F2-Pause';
           HotKeys.BackColor := Red;
           HotKeys.Display; }
          SetUpOrbit;
       END;
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
   DField := True;
   xCol := 25;
   yRow := 25;
   GetDFieldData;
 {  HideMouse; }
   SetUpScreen;
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
   Message('Press <F5-Input> to enter starting conditions');
   ShowMouse;
END;


{-------------------------------------------------------------------------}

PROCEDURE DrawDirectionField1;
VAR
   DelX, DelY, Length: Real;
   Slope: Real;
   x, y: Real;
   xEnd, yEnd: Real;
   i, j: Integer;
   Xcol, yRow: Integer;

FUNCTION f(x, y: Real): Real;
BEGIN
   f :=  y*(Price*x - Cost)/(FishA*x - FishB*x*x - x*y);
END;

BEGIN
   DField := True;
   SetUpScreen;
   xCol := 40;
   yRow := 40;
   SetColor(Yellow);
   DelX := (xMax - xMin)/xCol;
   DelY := (yMax - yMin)/yRow;
   Length := DelX;
   IF Length > DelY THEN Length := DelY;
   Length := Length*0.8;
   FOR i := 2 TO xCol DO
   BEGIN
      x := xMin + i*DelX;
      FOR j := 2 TO yRow DO
      BEGIN
         y := yMin + j*DelY;
         Slope := F(x+0.00001, y+0.00001);
         xEnd := Length/Sqrt(1 + Slope*Slope);
         yEnd := Slope*xEnd;
         PlotLine(x, y, x + xEnd, y + yEnd);
      END;
   END;
   ShowCursor;
   PromptInitialConditions;
   IF DataCanceled THEN
   BEGIN
      PlotOrbit := False;
      ClearMuppetPort;
      FishingMenu.Display;
      LightMenu := True;
      DField := False;
   END
   ELSE
      SetUpOrbit;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleFishingMenu;
BEGIN
   With FishingMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            2: ShowHelp('HelpMisc.hlp', 'FishingAboutProgram');
            1: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpMisc.hlp', 'FishingAboutModel');
            2: ShowHelp('HelpMisc.hlp', 'FishingPeriodicHelp');
            3: ShowHelp('HelpMisc.hlp', 'FishingDFieldHelp');
            4: BEGIN
                  ShowHelp('WalkThru.hlp', 'Fishing1');
                  ShowHelp('WalkThru.hlp', 'Fishing2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  GetFishingData;
                  IF NOT DataCanceled AND Periodic THEN GetPeriodicData;
                  IF DataCanceled THEN LightMenu := True;
               END;
            2: IF Periodic THEN
      Announce('No direction field possible with periodic variation with time')
                   ELSE DrawDirectionField;
            3: SetUpScreen;
         END;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION Rescale : Boolean;
VAR
   Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.22, 0.78, 0.35, 0.65);
      LoadLine('  Would you like to change the scale?');
      LoadLine('');
      LoadLine('xMin = 0. 1 <= xMax = {      } <= 100');
      LoadLine('yMin = 0. 1 <= yMax = {      } <= 100');
      LoadLine('');
      LoadLine('        [  OK  ]     [Cancel]');
      SetNumber(1, xMax);
      SetNumberLimits(1, 1, 100);
      SetNumber(2, yMax);
      SetNumberLimits(2, 1, 100);
      AcceptScreen;
      Rescale := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         xMax := GetNumber(1);
         yMax := GetNumber(2);
      END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
         1: BEGIN
               IF Pause THEN
               BEGIN
                  Pause := False;
                  WITH HotKeys DO Key[1] := 'F2-Pause';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
               END
               ELSE
               BEGIN
                  Pause := True;
                  WITH HotKeys DO Key[1] := 'F2-Start';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
               END;
         END;
         2: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
         3: Lag := Lag + DelLag;
         4: BEGIN
               PromptInitialConditions;
               IF DataCanceled THEN
                  BEGIN
                     LightMenu := True;
                     PlotOrbit := False;
                     DField := False;
                  END
                  ELSE
                  SetUpOrbit;
            END;
         5: BEGIN
               ReScale;
               IF DField THEN DrawDirectionField ELSE SetUpScreen;
            END;
         6: BEGIN
                  PlotOrbit := False;
                  DField := False;
                  ClearMuppetPort;
                  FishingMenu.Display;
                  LightMenu := True;
            END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.1, 0.9, 0.08, 0.92);
   ExitRequest := False;
   dField := False;
   Periodic := False;
   KeyInitialConditions := True;
   LightMenu := True;
   Lag := 300;
   FishA := 2;
   FishB := 1;
   Price := 1;
   Cost := 1;
   ACoeff := 0.5;
   APeriod := 1;
   APhase := 0;
   CCoeff := 0.5;
   CPeriod := 1;
   CPhase := 0;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   SetUpFishingMenu;
   SetUpHotKeys;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Sliders.Init;
   Hello('HelpMisc.hlp', 'FishingAboutProgram');
   GetSetUp;
   GetFishingData;
   IF NOT DataCanceled AND Periodic THEN GetPeriodicData;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN
                          HandleHotKeys(Key);
      IF Sliders.Changed THEN
      BEGIN
         SetColor(GraphBackColor); DrawEquilibria;
         Price := Sliders.Value(1);
         Cost := Sliders.Value(2);
         SetColor(Yellow); DrawEquilibria;
      END;
      IF PlotOrbit AND (NOT Pause) THEN StepOrbit;
      IF LightMenu THEN
         IF FishingMenu.Chosen THEN HandleFishingMenu
         ELSE
         IF FishingMenu.Activated THEN HandleFishingMenu;
   UNTIL ExitRequest;
   FishingMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




