Program ArmsRace;

Uses Crt, Graph, CupsMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                                       : Vector;
   ArmsA, ArmsM, ArmsG, ArmsB, ArmsN, ArmsH   : Real;
   ArmsMenu                                   : TMenu;
   HotKeys                                    : THotKeys;
   Sliders                                    : TSliders;
   Lag                                        : Integer;
   KeyInitialConditions                       : Boolean;
   PlotOrbit, Action                          : Boolean;
   ExitRequest                                : Boolean;
   LightMenu                                  : Boolean;
   Equilibrium                                : Boolean;
   SeeLines                                   : Boolean;
   DField                                     : Boolean;
   Key                                        : Byte;
   Time, h                                    : Real;
   xStart, yStart                             : Real;
   xMin, xMax, yMin, yMax                     : Real;
   xEqu, yEqu                                 : Real;
   xCol, yRow                                 : Integer;

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
   SetRGBPalette(green, $00, $18, $7);
   SetColor(White);
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

PROCEDURE SetUpArmsMenu;
VAR
   I    : Integer;
BEGIN
   With ArmsMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Running the model');
       row(2,3, 'Direction fields');
       row(2,4, 'Equilibrium');
      Column(3, 'Run');
       row(3,1, 'Enter model parameters');
       row(3,2, 'Enter graph parameters');
       row(3,3, 'Plot solutions');
       row(3,4, 'Plot the direction field');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   ArmsMenu.Display;
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Stop';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-Arrow';
      Key[4] := 'F5-Clear';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

FUNCTION GetArmsData: Boolean;
CONST
   RBNames : string = '12345678';
VAR
   ArmsDat        : TInputScreen;
BEGIN
   WITH ArmsDat DO
   BEGIN
      Init;
      DefineInputPort(0.18, 0.82, 0.17, 0.83);
      LoadLine('');
      LoadLine('            Data for an Arms Race ');
      LoadLine('');
      LoadLine('    dx/dt = ay - mx + g,  dy/dt = bx - ny + h');
      LoadLine('');
      LoadLine('     a = {     }   m = {     }   g = {     }');
      LoadLine('     b = {     }   n = {     }   h = {     }');
      LoadLine('  0 <= a, b, m, n, <= 20, -10 <= g, h, <= 10.');
      LoadLine('');
      LoadLine('  If there is an equilibrium, it will be at the');
      LoadLine('  intersection of the lines:');
      LoadLine('        0 = ay - mx + g, and  0 = bx - ny + h');
      LoadLine('  Do you want to see these lines? Yes #1  No #1');
      LoadLine('');
      LoadLine('      [ Help ]      [  OK   ]      [Cancel]');
      SetHelpFile('HelpBasc.hlp', 'ArmsRaceInputHelp');
      SetNumber(1, ArmsA);
      SetNumberLimits(1, 0, 20);
      SetNumber(2, ArmsM);
      SetNumberLimits(2, 0, 20);
      SetNumber(3, ArmsG);
      SetNumberLimits(3, -10, 10);
      SetNumber(4, ArmsB);
      SetNumberLimits(4, 0, 20);
      SetNumber(5, ArmsN);
      SetNumberLimits(5, 0, 20);
      SetNumber(6, ArmsH);
      SetNumberLimits(6, -10, 10);
      IF SeeLines THEN SetRadioButton('1', 1) ELSE SetRadioButton('1', 2);
      AcceptScreen;
      GetArmsData := NOT Canceled;
      IF Canceled THEN Exit;
      ArmsA := GetNumber(1);
      ArmsM := GetNumber(2);
      ArmsG := GetNumber(3);
      ArmsB := GetNumber(4);
      ArmsN := GetNumber(5);
      ArmsH := GetNumber(6);
      IF GetRadioButton('1') = 1 THEN
      SeeLines := True ELSE SeeLines := False;
      Done;
   END;     
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE FindEquilibrium;
VAR
   Delta                  : Real;
BEGIN
   Delta := ArmsA*ArmsB - ArmsM*ArmsN;
   IF Delta <> 0 THEN
   BEGIN
      xEqu := (- ArmsH*ArmsA - ArmsG*ArmsN)/Delta;
      yEqu := (- ArmsH*ArmsM - ArmsG*ArmsB)/Delta;
   END;
   IF (Delta = 0) OR (xEqu < 0) OR (yEqu < 0) THEN
      Equilibrium := False ELSE Equilibrium := True;
END;

{------------------------------------------------------------------------}

FUNCTION GetGraphData : Boolean;
VAR
   Delta                  : Real;
   GraphData              : TInputScreen;
BEGIN
   Delta := ArmsA*ArmsB - ArmsM*ArmsN;
   IF Delta <> 0 THEN
   BEGIN
      xEqu := (- ArmsH*ArmsA - ArmsG*ArmsN)/Delta;
      yEqu := (- ArmsH*ArmsM - ArmsG*ArmsB)/Delta;
   END;
   IF (Delta = 0) OR (xEqu < 0) OR (yEqu < 0) THEN
      Equilibrium := False ELSE Equilibrium := True;
   WITH GraphData DO
   BEGIN
      Init;
      DefineInputPort(0.12, 0.88, 0.35, 0.65);
      LoadLine('');
      IF Equilibrium THEN
         LoadLine('  There is an equilibrium at xEqu = '
         +NumStr(xEqu, 5, 2)+', yEqu = '+NumStr(yEqu, 5, 2))
      ELSE
         LoadLine('            There is no equilibrium');
      LoadLine('  Enter extreme values of x and y for the graph:');
      LoadLine('       xMax = {      }, yMax = {      }');
      LoadLine('');
      LoadLine('                [  OK  ]        [Cancel]');
      SetNumber(1, xMax);
      SetNumberLimits(1, 0.001, 100000);
      SetNumber(2, yMax);
      SetNumberLimits(2, 0.001, 100000);
      AcceptScreen;
      GetGraphData := NOT Canceled;
      IF NOT Canceled THEN
         xMax := GetNumber(1);
         yMax := GetNumber(2);
         DefineScale(1, -xMax/20, xMax, -yMax/20, yMax);
      Done;
   END;
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
begin
   z[1] := ArmsA*y[2] - ArmsM*y[1] + ArmsG;
   z[2] := ArmsB*y[1] - ArmsN*y[2] + ArmsH
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

{-------------------------------------------------------------------------}

PROCEDURE PrepareToRunOrbit;
BEGIN
   SelectViewPort(1);
   Time := 0;
   h := 0.1;
   SetColor(Yellow);
   Action := True;
   {PlotOrbit := True;}
END;

{-------------------------------------------------------------------------}

PROCEDURE TakeOrbitStep;
VAR
   xOld, yOld, xNew, yNew: Real;
BEGIN
   Delay(Lag);
   xOld := y[1]; yOld := y[2];
   Step(Time, h, 0.000001, y, Time, h, y);
   xNew := y[1]; yNew := y[2];
   IF (y[1] < 0) OR (y[2] < 0) OR (y[1] > 1.1*xMax) OR (y[2] > 1.1*yMax) THEN
   BEGIN
      Action := False;
      PlotOrbit := False;
      WITH HotKeys DO Key[1] := 'F2-Start';
      HotKeys.BackColor := Red;
      HotKeys.Display;
   END;
   IF Action AND PlotOrbit THEN PlotLine(xOld, yOld, xNew, yNew);
END;

{-------------------------------------------------------------------------}

FUNCTION PromptInitialConditions : Boolean;
CONST
   RBNames : string = '12345678';
VAR
    Inside           : Boolean;
    InitialDat       : TInputScreen;
    Y1Save, Y2Save   : Real;
    a                : Integer;
BEGIN
   ShowCursor;
   WITH InitialDat DO
   BEGIN
      Init;
      DefineInputPort(0.28, 0.72, 0.4, 0.6);
      LoadLine('');
      LoadLine('   Use keyboard #1 or mouse #1 ?');
      LoadLine('');
      LoadLine('             [  OK  ]');
      IF KeyInitialConditions THEN
         SetRadioButton('1', 1) ELSE SetRadioButton('1', 2);
      AcceptScreen;
      IF GetRadioButton('1') = 1 THEN
         KeyInitialConditions := True ELSE KeyInitialConditions := False;
      Done;
   END;
   IF KeyInitialConditions THEN
   BEGIN
      WITH InitialDat DO
      BEGIN
         Init;
         DefineInputPort(0.15, 0.85, 0.85, 0.95);
         LoadLine(' Enter initial conditions: x = {     }   y = {     }');
         LoadLIne('           [  OK  ]           [Cancel]');
         SetNumber(1, xStart);
         SetNumberLimits(1, 0, xMax);
         SetNumber(2, yStart);
         SetNumberLimits(2, 0, yMax);
         AcceptScreen;
         PromptInitialConditions := NOT Canceled;
         IF Canceled THEN PlotOrbit := False
         ELSE
         BEGIN
            y[1] := GetNumber(1);
            y[2] := GetNumber(2);
            xStart := y[1];
            yStart := y[2];
         END;
         Done;
      END;
   END
   ELSE
   BEGIN
      Message('                 Click on a starting point');
      REPEAT
         MousePosn(y[1], y[2], 1, 1, Inside);
         IF NOT Inside
         AND
         (Abs(y1Save - (y[1])) + Abs(y2Save - (y[2])) > 0.01)
              THEN RubOutXY(0.6, 0.983, 15, Blue);
         IF Inside AND
         (Abs(y1Save - (y[1])) + Abs(y2Save - (y[2])) > 0.01) THEN
         BEGIN
            RubOutXY(0.6, 0.983, 15, Blue);
            PrintXY(0.6, 0.983, '('+NumStr(y[1], 4, 2)
                         +', '+NumStr(y[2], 4, 2)+')');
         END;
            y1Save := (y[1]);
            y2Save := (y[2]);
         IF (NOT Inside) AND MouseClicked(a,a) THEN
         BEGIN
            Message('          Please click inside the screen');
            Beep;
            Delay(1000);
            Beep;
            Message('                 Click on a starting point');
         END;
      UNTIL MouseClicked(a,a) AND Inside;
      MousePosn(y[1], y[2], 1, 1, Inside);
      Message('');
   END;
   PrepareToRunOrbit;
END;

{-------------------------------------------------------------------------}

PROCEDURE  DrawArrow(xHead, yHead, xSlope, ySlope: Real);
VAR
   xh, yh, xt, yt        : Integer;
   xTail, yTail          : Real;
   Length                : Real;
   Size                  : Integer;
   Slope                 : Real;
   x, y, ASize: Real;
BEGIN
   Size := 10;
   xSlope := xSlope/Sqrt(xSlope*xSlope + ySlope*ySlope);
   ySlope := ySlope/Sqrt(xSlope*xSlope + ySlope*ySlope);
   xTail := xHead - xSlope;
   yTail := yHead - ySlope;
   xt := MapX(xTail);
   xh := MapX(xHead);
   yt := MapY(yTail);
   yh := MapY(yHead);
   Length := Sqrt((xt-xh)*(xt-xh) + (yt-yh)*(yt-yh));
   xt := Trunc(((Length-Size)/Length)*xh + (Size/Length)*xt);
   yt := Trunc(((Length-Size)/Length)*yh + (Size/Length)*yt);
   Slope := - (xh-xt)/(yh-yt);
   Line(xh, yh, xt+(yh-yt), yt-(xh-xt));
   Line(xh, yh, xt-(yh-yt), yt+(xh-xt));
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawLine(a, b, c: Real; LineColor : Word); {ax + by + c = 0.}{0 < x < 6, 0 < y < 6.}
VAR
   x1, y1, x2, y2: Real;
   Count: Integer;
BEGIN
   Count := 0;
   IF a <> 0 THEN
   BEGIN
      IF (-c/a >= 0) AND (-c/a <= xMax) THEN
                   BEGIN x1 := -c/a; y1 := 0; Count := 1; END;
      IF (-(c+yMax*b)/a >= 0) AND (-(c+yMax*b)/a <= xMax) THEN
      BEGIN IF Count = 1 THEN
                   BEGIN x2 := -(c+yMax*b)/a; y2 := yMax;  Count := 2; END
           ELSE    BEGIN x1 := -(c+yMax*b)/a; y1 := yMax;  Count := 1; END;
      END;
   END;
   IF b <> 0 THEN
   BEGIN
      IF (-c/b >= 0) AND (-c/b <= yMax) THEN
      BEGIN IF Count = 0 THEN
                   BEGIN x1 := 0; y1 := -c/b; Count := 1; END
           ELSE    BEGIN x2 := 0; y2 := -c/b; Count := 2; END;
      END;
      IF (-(c+xMax*a)/b >= 0) AND (-(c+xMax*a)/b <= yMax) THEN
      BEGIN IF Count = 1 THEN
                   BEGIN x2 := xMax; y2 := -(c+xMax*a)/b;  Count := 2; END;
      END;
   END;
   IF Count = 2 THEN
   BEGIN
      SetColor(LineColor);
      SetLineStyle(DottedLn, 0, NormWidth);
      PlotLine(x1, y1, x2, y2);
      SetLineStyle(SolidLn, 0, NormWidth);
      SetColor(Yellow);
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE WriteEquations;
VAR
   EqnStr, AStr, MStr, GStr, BStr, NStr, HStr: String;
BEGIN
    Str(ABS(ArmsA): 4 : 1, AStr);
    IF ArmsA < 0 THEN AStr := '- '+ AStr; 
    Str(ABS(ArmsB): 4 : 1, BStr);
    IF ArmsB < 0 THEN BStr := '- ' + BStr;
    Str(ABS(ArmsM): 4 : 1, MStr);
    IF ArmsM < 0 THEN MStr := '+ ' + MStr ELSE MStr := '- ' + MStr;
    Str(ABS(ArmsN): 4 : 1, NStr);
    IF ArmsN < 0 THEN NStr := '+ ' + NStr ELSE NStr := '- ' + NStr;
    Str(ABS(ArmsG): 4 : 1, GStr);
    IF ArmsG > 0 THEN GStr := '+ ' + GStr ELSE GStr := '- ' + GStr;
    Str(ABS(ArmsH): 4 : 1, HStr);
    IF ArmsH > 0 THEN HStr := '+ ' + HStr ELSE HStr := '- ' + HStr;
    RubOutXY(0.3, 0.15, 40, Black);
    RubOutXY(0.3, 0.1, 40, Black);
    SetColor(White);
    EqnStr := 'dx/dt = ' + Astr + 'x ' + MStr + 'y ' + GStr;
    PrintXY(0.3, 0.15, EqnStr);
    EqnStr := 'dy/dt = ' + Bstr + 'x ' + NStr + 'y ' + HStr;
    PrintXY(0.3, 0.1, EqnStr);
END;

{-------------------------------------------------------------------------}

PROCEDURE  SetUpScreen;
VAR
   EqnStr, AStr, MStr, GStr, BStr, NStr, HStr: String;
   xSc, ySc: Integer;
   i: Integer;
BEGIN
    HideCursor;
    GraphBackColor := DarkGray;
    ClearMuppetPort;
    OpenViewPort(1);
    Message('');
    IF NOT DField THEN
    BEGIN
    Sliders.Create(1, 0, 20, ArmsA, 0.05, 0.05, 0.335, 1, '0', '20', 'Arm',
                   True);
    Sliders.Create(4, 0, 20, ArmsB, 0.93, 0.05, 0.335, 1, '0', '20', 'Arm',
                   True);
    Sliders.Create(2, 0, 20, ArmsM, 0.05, 0.355, 0.64, 1, '0', '20', 'Save',
                   True);
    Sliders.Create(5, 0, 20, ArmsN, 0.93, 0.355, 0.64, 1, '0', '20', 'Save',
                   True);
    Sliders.Create(3, -10, 10, ArmsG, 0.05, 0.66, 0.945, 1, '-10', '10', 'Hate',
                   True);
    Sliders.Create(6, -10, 10, ArmsH, 0.93, 0.66, 0.945 , 1, '-10', '10', 'Hate',
                   True);
    Sliders.DrawAll;
    PrintXY(0.01, 0.55, 'x');
    PrintXY(0.98, 0.55, 'y');
    END;
    LightMenu := False;
    SetUpHotKeys;
    SetColor(LightGreen);
    Axis(0, 0, 1, 1);
    IF Equilibrium THEN PlotSymbol(xEqu, yEqu, '*');
    IF SeeLines THEN
    BEGIN
       DrawLine(-ArmsM, ArmsA, ArmsG, White);
       DrawLine(ArmsB, -ArmsN, ArmsH, White);
    END;
    WriteEquations;
    LightMenu := False;
    IF NOT DField THEN
    BEGIN
       IF PromptInitialConditions THEN PlotOrbit := True
       ELSE PlotOrbit := False;
    END
    ELSE ShowMouse;
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
   PlotOrbit := False;
   IF PromptInitialConditions THEN PlotOrbit := True
                              ELSE PlotOrbit := False;
END;



{-------------------------------------------------------------------------}

PROCEDURE HandleArmsMenu;
BEGIN
   With ArmsMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpBasc.hlp', 'ArmsRaceAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpBasc.hlp', 'ArmsRaceAboutModel1');
                  ShowHelp('HelpBasc.hlp', 'ArmsRaceAboutModel2');
               END;
            2: BEGIN
                  ShowHelp('HelpBasc.hlp', 'ArmsRaceRunningModel1');
                  ShowHelp('HelpBasc.hlp', 'ArmsRaceRunningModel2');
               END;
            3: ShowHelp('HelpBasc.hlp', 'ArmsRaceDirectionFields');
            4: BEGIN
                  ShowHelp('HelpBasc.hlp', 'ArmsRaceEquilibrium1');
                  ShowHelp('HelpBasc.hlp', 'ArmsRaceEquilibrium2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF GetArmsData THEN
                     IF GetGraphData THEN
                        SetUpScreen
               END;
            2: GetGraphData;
            3: SetUpScreen;
            4: BEGIN
                  DField := True;
                  SetUpScreen;
                  DrawDirectionField;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE ReadSliders;
BEGIN
   IF SeeLines THEN
   BEGIN
      DrawLine(-ArmsM, ArmsA, ArmsG, GraphBackColor);
      DrawLine(ArmsB, -ArmsN, ArmsH, GraphBackColor);
   END;
   ArmsA := Sliders.Value(1);
   ArmsM := Sliders.Value(2);
   ArmsG := Sliders.Value(3);
   ArmsB := Sliders.Value(4);
   ArmsN := Sliders.Value(5);
   ArmsH := Sliders.Value(6);
   WriteEquations;
   IF SeeLines THEN
   BEGIN
      DrawLine(-ArmsM, ArmsA, ArmsG, White);
      DrawLine(ArmsB, -ArmsN, ArmsH, White);
   END;
   IF Equilibrium THEN
   BEGIN
      SetColor(GraphBackColor);
      PlotSymbol(xEqu, yEqu, '*');
      SetColor(Yellow);
   END;
   FindEquilibrium;
   IF Equilibrium THEN PlotSymbol(xEqu, yEqu, '*');
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte; VAR Action, PlotOrbit: Boolean);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
      1: BEGIN
            IF NOT PlotOrbit THEN
            BEGIN
               Announce('Please enter starting conditions');
               Exit;
            END;
            IF NOT Action THEN
               BEGIN
                  Action := True;
                  WITH HotKeys DO Key[1] := 'F2-Stop';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
               END
               ELSE
               BEGIN
                  Action := False;
                  WITH HotKeys DO Key[1] := 'F2-Start';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
               END;
            END;
      2: BEGIN
            IF NOT Action THEN
            BEGIN
               Action := True;
               WITH HotKeys DO Key[1] := 'F2-Stop';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
            PlotOrbit := False;
            IF PromptInitialConditions THEN PlotOrbit := True;
         END;
      3: BEGIN Fun(1, y, z); DrawArrow(y[1], y[2], z[1], z[2]); END;
      4: BEGIN
            GetGraphData;
            SetUpScreen;
         END;
      5: BEGIN
            PlotOrbit := False;
            DField := False;
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Hello('HelpBasc.hlp', 'ArmsRaceAboutProgram');
   ExitRequest := False;
   KeyInitialConditions := False;
   SeeLines := True;
   LightMenu := True;
   DField := False;
   DefineViewPort(1, 0.13, 0.87, 0.2, 0.94);
   SelectScale(1);
   xMin := 0;
   yMin := 0;
   xMax := 6;
   yMax := 7;
   DefineScale(1, -xMax/20, xMax, -yMax/20, yMax);
   Lag := 200;
   xStart := 1;
   yStart := 2;
   ArmsA := 1; ArmsM := 2; ArmsG := 3; ArmsB := 4; ArmsN := 5; ArmsH := 6;
   SetUpArmsMenu;
   LightMenu := True;
   IF GetArmsData THEN IF GetGraphData THEN SetUpScreen;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN
                          HandleHotKeys(Key, Action, PlotOrbit);
      IF LightMenu THEN  IF ArmsMenu.Chosen THEN HandleArmsMenu;
      IF Action AND PlotOrbit THEN TakeOrbitStep;
      IF Sliders.Changed THEN ReadSliders;
      {IF ArmsMenu.Activated THEN HandleArmsMenu;}
   UNTIL ExitRequest;
   ArmsMenu.Done;
   CUPSDone;
END.




