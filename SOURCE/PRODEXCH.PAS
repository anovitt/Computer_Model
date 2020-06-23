Program ProductionAndExchange;

Uses Crt, Graph, CupsMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                    : Vector;
   PEMenu                  : TMenu;
   HotKeys                 : THotKeys;
   Sliders                 : TSliders;
   Lag                     : Integer;
   KeyInitialConditions    : Boolean;
   PlotOrbit, Pause        : Boolean;
   ExitRequest             : Boolean;
   LightMenu               : Boolean;
   DField                  : Boolean;
   Equilibrium             : Boolean;
   StartConditions         : Boolean;
   DivideByZero            : Boolean;
   Key                     : Byte;
   Keep1, Keep2            : Real;
   Work1, Work2            : Real;
   Enjoy1, Enjoy2          : Real;
   Time, h                 : Real;
   xOld, yOld, xNew, yNew  : Real;
   InitialX, InitialY      : Real;
   xMax, xMin, yMax, yMin  : Real;
   MaxX, MaxY              : Real;
   xEquil, yEquil          : Real;


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

PROCEDURE SetUpPEMenu;
VAR
   I      : Integer;
BEGIN
   With PEMenu DO
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
       row(3,2, 'Plot solutions');
       row(3,3, 'See the direction field diagram');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   PEMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Start';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-Input';
      Key[5] := 'F6-CleanUp';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindEquilibrium;
VAR
   Ratio1, Ratio2     : Real;
BEGIN
   Ratio1 := Work1/Enjoy1;
   Ratio2 := Work2/Enjoy2;
   Equilibrium := False;
   IF Abs(1 - Keep1 - Keep2) < 0.00001 THEN Exit;
   xEquil := (Ratio1*(1 - Keep2)*(Keep2 - Ratio2)
            - Ratio2*Keep2*(Keep1 - Ratio1))/(Ratio1*Ratio2*(1 - Keep1 - Keep2));
   yEquil := (Ratio2*(1 - Keep1)*(Keep1 - Ratio1)
            - Ratio1*Keep1*(Keep2 - Ratio2))/(Ratio1*Ratio2*(1 - Keep1 - Keep2));
   IF (xEquil >= 0) AND (yEquil >= 0) THEN Equilibrium := True;
END;

{-------------------------------------------------------------------------}

FUNCTION GetPEData: Boolean;
VAR
   GonoDat : TInputScreen;
BEGIN
   Message('');
   WITH GonoDat DO
   BEGIN
      Init;
      DefineInputPort(0.12, 0.88, 0.01, 0.99);
      LoadLine('');
      LoadLine('           Data for ''Production and Exchange''');
      LoadLine('');
      LoadLine('    The model is');
      LoadLine('         dx/dt = e1*p1/(p1*x+(1-p2)*y+1) - r1,');
      LoadLIne('         dy/dt = e2*p2/(p2*y+(1-p1)*x+1) - r2.');
      LoadLine('');
      LoadLine('    The first person produces x amount of goods, keeps ');
      LoadLine(' the proportion p1 and gives away the proportion (1-p1).');
      LoadLine(' e1 is a measure of the person''s enjoyment of owning');
      LoadlIne(' goods. r1 is a measure of the person''s dislike for ');
      LoadLine(' work. (Negative r1 would mean love of work!) ');
      LoadLine('    Similar definitions apply to the second person.');
      LoadLine('');
      LoadLine('    Enter values for these parameters:');
      LoadLine('                0 < p1 = {       } < 1');
      LoadLine('                0 < p2 = {       } < 1');
      LoadLine('              0.1 < e1 = {       } < 1');
      LoadLIne('              0.1 < e2 = {       } < 1');
      LoadLine('               -1 < r1 = {       } < 1');
      LoadLine('               -1 < r2 = {       } < 1');
      LoadLIne('');
      LoadLIne('               [  OK  ]       [Cancel]');
      SetNumber(1, Keep1);
      SetNumberLimits(1, 0, 1);
      SetNumber(2, Keep2);
      SetNumberLimits(2, 0, 1);
      SetNumber(3, Enjoy1);
      SetNumberLimits(3, 0.1, 1);
      SetNumber(4, Enjoy2);
      SetNumberLimits(4, 0.1, 1);
      SetNumber(5, Work1);
      SetNumberLimits(5, -1, 1);
      SetNumber(6, Work2);
      SetNumberLimits(6, -1, 1);
      AcceptScreen;
      GetPEData := NOT Canceled;
      IF Canceled THEN Exit;
      Keep1 := GetNumber(1);
      Keep2 := GetNumber(2);
      Enjoy1 := GetNumber(3);
      Enjoy2 := GetNumber(4);
      Work1 := GetNumber(5);
      Work2 := GetNumber(6);
      FindEquilibrium;
      Done;
   END;
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

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
VAR
   Y1Zero, Y2Zero  : Boolean;
BEGIN
   IF (Abs(Keep1*y[1] + (1 - Keep2)*y[2] + 1) < 0.001)
      OR (Abs(Keep2*y[2] + (1 - Keep1)*y[1] + 1) < 0.001)
   THEN
      DivideByZero := True
   ELSE
   BEGIN
      DivideByZero := False;
      IF y[1] < 0 THEN
      BEGIN
         y[1] := 0;
         Y1Zero := True;
      END
      ELSE Y1Zero := False;
      IF y[2] < 0 THEN
      BEGIN
         y[2] := 0;
         Y2Zero := True;
      END
      ELSE Y2Zero := False;
      z[1] := Enjoy1*Keep1/(Keep1*y[1] + (1 - Keep2)*y[2] + 1) - Work1;
      z[2] := Enjoy2*Keep2/(Keep2*y[2] + (1 - Keep1)*y[1] + 1) - Work2;
      IF Y1Zero AND (z[1] < 0) THEN  z[1] := 0;
      IF Y2Zero AND (z[2] < 0) THEN  z[2] := 0;
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
   WITH HotKeys DO Key[1] := 'F2-Start';
   HotKeys.BackColor := Blue;
   HotKeys.Display;
   SetColor(Yellow);
   PlotOrbit := True;
   Pause := True;
   LightMenu := False;
   StartConditions := True;
   xOld := y[1]; yOld := y[2];
END;

{------------------------------------------------------------------------}

PROCEDURE StepOrbit;
BEGIN
   Delay(Lag);
   SetColor(Yellow);
   IF h > 0.1 THEN h := 0.1;
   Step(Time, h, 0.00000001, y, Time, h, y);
   IF DivideByZero OR (y[1] > 3*maxX) OR (y[2] > 3*MaxY) THEN
   BEGIN
      RubOutXY(0.4, 0.105, 20, DarkGray);
      PrintXY(0.4, 0.105, 'Start again!');
      PrepareToRunOrbit;
   END
   ELSE
   BEGIN
      IF y[1] < 0 THEN y[1] := 0;
      IF y[2] < 0 THEN y[2] := 0;
      xNew := y[1]; yNew := y[2];
      PlotLine(xOld, yOld, xNew, yNew);
      xOld := xNew; yOld := yNew;
      RubOutXY(0.4, 0.105, 20, DarkGray);
      PrintXY(0.4, 0.105, '('+NumStr(y[1], 4, 2)+', '+NumStr(y[2], 4, 2)+')');
   END;
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
   dx := TextWidth(text)+13;
   dy := RowHt + 3;
   cx := (GetMaxX-dx) DIV 2;
   cy := (GetMaxY-dy) DIV 8;
   Image.Get(cx,cy,cx+dx,cy+dy);
   HideMouse;
   Bar3D(cx,cy+3,cx+dx-3,cy+dy,3,true);
   ShowMouse;
   ClearMKBuffers;
   SetColor(Yellow);
   HideMouse;
   OutTextXY(cx+6,cy+8,Text);
   ShowMouse;
   Envir.Reset;
   REPEAT
      MousePosn(y[1], y[2], 1, 1, Inside);
      IF Inside AND
         (Abs(MSave - (y[1])) + Abs(FSave - (y[2])) > 0.02) THEN
      BEGIN
         RubOutXY(0.4, 0.105, 20, DarkGray);
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
    Inside: Boolean;
    InitialDat      : TInputScreen;
BEGIN
   ShowCursor;
   Pause := False;
   KeyInitialConditions := UseKey;
   IF KeyInitialConditions THEN
   BEGIN
      WITH InitialDat DO
      BEGIN
         Init;
         DefineInputPort(0.32, 0.68, 0.72, 0.95);
         LoadLine(' Enter initial conditions:');
         LoadLine(' x = {      } <= '+NumStr(MaxX, 3, 0));
         LoadLine(' y = {      } <= '+NumStr(MaxY, 3, 0));
         LoadLine('');
         LoadLine('          [  OK  ]   ');
         SetNumber(1, InitialX);
         SetNumberLimits(1, 0, MaxX);
         SetNumber(2, InitialY);
         SetNumberLimits(2, 0, MaxY);
         AcceptScreen;
         y[1] := GetNumber(1);
         y[2] := GetNumber(2);
         InitialX := y[1];
         InitialY := y[2];
         {PutPixel(MapX(y[1]), MapY(y[2]), Yellow); }
         Done;
      END;
   END
   ELSE
   BEGIN
      GraphBackColor := DarkGray;
      SetColor(Yellow);
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
END;

{-------------------------------------------------------------------------}

PROCEDURE  DrawArrow(xHead, yHead, xSlope, ySlope: Real);
VAR
   x, y, ASize: Real;
BEGIN
   xSlope := xSlope/Sqrt(xSlope*xSlope + ySlope*ySlope);
   ySlope := ySlope/Sqrt(xSlope*xSlope + ySlope*ySlope);
   ASize := MaxX/50;
   x := xHead - ASize*xSlope + ASize*YSlope;
   y := yHead - ASize*ySlope - ASize*XSlope;
   PlotLine(xHead, yHead, x, y);
   x := xHead - ASize*xSlope - ASize*YSlope;
   y := yHead - ASize*ySlope + ASize*XSlope;
   PlotLine(xHead, yHead, x, y);
END;

{-------------------------------------------------------------------------}

PROCEDURE ReScale;
VAR
   Input             : TInputScreen;

BEGIN
   WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.23, 0.77, 0.33, 0.67);
         LoadLine('');
         LoadLine('   Enter extreme limits for display:');
         LoadLine('    xLow = 0   xHigh = {       } > 1');
         LoadLine('    yLow = 0   yHigh = {       } > 1');
         LoadLine('');
         LoadLine('             [  OK  ]');
         SetNumber(1, MaxX);
         SetNumber(2, MaxY);
         SetNumberLimits(1, 1, 10000000);
         SetNumberLimits(2, 1, 10000000);
         AcceptScreen;
         xMax := GetNumber(1);
         yMax := GetNumber(2);
         MaxX := xMax;
         MaxY := yMax;
         Done;
      END;
END;

{-------------------------------------------------------------------------}


PROCEDURE  SetUpScreen;
VAR
   MaleStr, FemaleStr, EqnStr, AStr, MStr, GStr, BStr, NStr, HStr: String;
   xSc, ySc: Integer;
   PMales, PFemales : Real;
   i: Integer;
BEGIN
    ClearMuppetPort;
    ReScale;
    StartConditions := False;
    IF NOT DField THEN
    BEGIN
       Sliders.Create(1, 0, 1, Keep1, 0.05, 0.05, 0.4, 2, '0', '1', 'P1',
                      True);
       Sliders.Create(2, 0, 1, Keep2, 0.95, 0.05, 0.4, 2, '0', '1', 'P2',
                      True);
       Sliders.Create(3, 0.1, 1, Enjoy1, 0.05, 0.425, 0.675, 2, '0.1', '1', 'E1',
                      True);
       Sliders.Create(4, 0.1, 1, Enjoy2, 0.95, 0.425, 0.675, 2, '0.1', '1', 'E2',
                      True);
       Sliders.Create(5, -1, 1, Work1, 0.05, 0.7, 0.95, 2, '-1', '1', 'W1',
                      True);
       Sliders.Create(6, -1, 1, Work2, 0.95, 0.7, 0.95, 2, '-1', '1', 'W2',
                      True);
       Sliders.DrawAll;
    END;
    GraphBackColor := DarkGray;
    OpenViewPort(1);
    LightMenu := False;
    DefineScale(1, -MaxX/20, 1.05*MaxX, -MaxY/20, 1.05*MaxY);
    SelectScale(1);
    SetColor(LightGreen);
    PlotLine(0, 0, 0, MaxY);
    PlotLine(0, 0, MaxX, 0);
    PlotLine(MaxX, 0, MaxX, MaxY/50);
    Map(MaxX, 0, xSc, ySc);
    Str(Trunc(MaxX), MaleStr);
    PrintXY(0.85, 0.11, MaleStr);
    PrintXY(0.8, 0.14, 'X');
   { OutTextxy(xSc-10, ySc+5, MaleStr);
    OutTextxy(xSc-40, ySc - 15, 'X');}
    PlotLine(0, MaxY, MaxX/50, MaxY);
    Map(0, MaxY, xSc, ySc);
    Str(Trunc(MaxY), FemaleStr);
    PrintXY(0.15, 0.89, FemaleStr);
    PrintXY(0.14, 0.905, 'Y');
   { OutTextxy(xSc+10, ySc-2, FemaleStr);
    OutTextxy(xSc, ySc - 15, 'Y');}
    IF Equilibrium
    THEN
    BEGIN
       Message(        'Equilibrium at ('
       +NumStr(xEquil, 4,2)+', '+NumStr(yEquil, 4,2)+')') ;
       PlotSymbol(xEquil, yEquil, '*');
    END
    ELSE Message('      No equilibrium for these parameters.');
    IF NOT DField THEN
    BEGIN
       WITH HotKeys DO Key[1] := 'F2-Start';
       HotKeys.BackColor := Blue;
       HotKeys.Display;
       Pause := True;
      { PromptInitialConditions;
       PrepareToRunOrbit; }
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
   xMin := -MaxX/20;
   xMax := 1.05*MaxX;
   yMin := -MaxY/20;
   yMax := 1.05*MaxY;
   xCol := 25;
   yRow := 25;
   GetDFieldData;
  { HideMouse;}
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
   HideMouse;
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
   ShowMouse;
         WITH HotKeys DO Key[1] := 'F2-Pause';
       HotKeys.BackColor := Red;
       HotKeys.Display;
       PromptInitialConditions;
       PrepareToRunOrbit;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePEMenu;
BEGIN
   With PEMenu DO
   CASE ColChosen OF
      1: Case RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpMisc.Hlp', 'ProdExchAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpMisc.Hlp', 'ProdExchAboutModelA');
                  ShowHelp('HelpMisc.Hlp', 'ProdExchAboutModelB');
                  ShowHelp('HelpMisc.Hlp', 'ProdExchAboutModelC');
               END;
            2: BEGIN
                  ShowHelp('HelpMisc.Hlp', 'ProdExchDFieldA');
                  ShowHelp('HelpMisc.Hlp', 'ProdExchDFieldB');
               END;
            3: ShowHelp('WalkThru.hlp', 'ProdExchange');
         END;
      3: CASE RowChosen OF
            1: IF GetPEData THEN SetUpScreen;
            2: SetUpScreen;
            3: BEGIN
                  PlotOrbit := False;
                 { IF GetPEData THEN} DrawDirectionField
                                 {ELSE LightMenu := True};
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE ReadSliders;
VAR
   SaveColor  : Word;
BEGIN
   SaveColor := GetColor;
   Keep1 := Sliders.Value(1);
   Keep2 := Sliders.Value(2);
   Enjoy1 := Sliders.Value(3);
   Enjoy2 := Sliders.Value(4);
   Work1 := Sliders.Value(5);
   Work2 := Sliders.Value(6);
   SetColor(GraphBackColor);
   PlotSymbol(xEquil, yEquil, '*');
   SetColor(SaveColor);
   FindEquilibrium;
   IF Equilibrium
    THEN
    BEGIN
       Message(        'Equilibrium at ('
       +NumStr(xEquil, 4,2)+', '+NumStr(yEquil, 4,2)+')') ;
       PlotSymbol(xEquil, yEquil, '*');
    END
    ELSE Message('      No equilibrium for these parameters.');
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
         1: BEGIN
               IF NOT StartConditions THEN
               BEGIN
                  Announce('Please enter initial conditions with <F5-Input>');
                  Exit;
               END;
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
         2: IF Lag > DelLag THEN Lag := Lag - DelLag;
         3: Lag := Lag + DelLag;
         4: BEGIN
               PromptInitialConditions;
               PrepareToRunOrbit;
            END;
         5: BEGIN
               {ReScale; }
               IF DField THEN DrawDirectionField ELSE SetUpScreen;
            END;
         6: BEGIN
               PlotOrbit := False;
               DField := False;
               ClearMuppetPort;
               LightMenu := True;
            END;
   END;
END;


{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DField := False;
   KeyInitialConditions := True;
   DefineViewPort(1, 0.1, 0.9, 0.08, 0.92);
   GraphBackColor := DarkGray;
   Lag := 200;
   LightMenu := True;
   ExitRequest := False;
   Hello('HelpMisc.Hlp', 'ProdExchAboutProgram');
   SetUpPEMenu;
   SetUpHotKeys;
   Keep1 := 0.4;
   Keep2 := 0.4;
   Enjoy1 := 1;
   Enjoy2 := 1;
   Work1 := 0.2;
   Work2 := 0.2;
   MaxX := 10;
   MaxY := 10;
   xMin := 0;
   yMin := 0;
   xMax := MaxX;
   yMax := MaxY;
   FindEquilibrium;
   InitialX := 1.5*XEquil;
   InitialY := 1.5*YEquil;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Sliders.Init;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF PLotOrbit AND (NOT Pause) THEN StepOrbit;
      IF Sliders.Changed THEN ReadSliders;
      IF LightMenu THEN
         IF PEMenu.Chosen THEN HandlePEMenu
   UNTIL ExitRequest;
   PEMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




