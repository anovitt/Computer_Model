
PROGRAM DirectionField;

USES crt, Graph, CUPSMupp, CUPS, CupsFunc, CupsGui, CUPSPars;

VAR
   DFieldMenu                              : TMenu;
   DiffEq                                  : TParser;
   FString                                 : String;
   XLow, XHigh, YLow, YHigh                : Real;
   ClickForSolution                        : Boolean;
   FunctionOK                              : Boolean;
   DataComplete                            : Boolean;
   AbandonInput                            : Boolean;
   AxesPlotted                             : Boolean;
   LightMenu                               : Boolean;
   ExitRequest                             : Boolean;
   BackToMenu                              : Boolean;
   xCol, yRow                              : Integer;
   xColR, yRowR                            : Real;
   xInitial, yInitial                      : Real;
   StepSize                                : Real;

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

{--------------------------------------------------------------------}

PROCEDURE SetUpDFieldMenu;
VAR
   i    : Integer;
BEGIN
   With DFieldMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Information on the direction field');
       row(2,2, 'Information on Euler''s method');
       row(2,3, 'The Improved Euler''s method');
      Column(3, 'Solutions');
       row(3,1, 'Enter f(x,y) and graph parameters');
       row(3,2, 'Enter initial conditions: keyboard');
       row(3,3, 'Enter initial conditions: mouse');
       row(3,4, 'Clean up the screen');
      Column(4, 'Euler');
       row(4,1, 'Regular Euler''s method');
       row(4,2, 'Improved Euler''s method');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   DFieldMenu.Display;
END;
{------------------------------------------------------------------------}


FUNCTION FInput : Boolean;
CONST
   RBNames        : String = '12345678';
VAR
   n              : byte;
   FScreen        : TInputScreen;

BEGIN
   DataComplete := False;
   DFieldMenu.RowActivate(3,2, False);
   DFieldMenu.RowActivate(3,3, False);
   DFieldMenu.RowActivate(3,4, False);
   DFieldMenu.RowActivate(4,1, False);
   DFieldMenu.RowActivate(4,2, False);
   xInitial := 0;
   yInitial := 0;
   WITH FScreen DO
   BEGIN
      Init;
      DefineInputPort (0.16, 0.84, 0.07, 0.93);
      LoadLine('');
      LoadLine('         Input Data for a Direction Field');
      LoadLIne('');
      LoadLine('  Enter a function f(x,y), where dy/dx = f(x,y).');
      LoadLine('  You Can Use: *, ^,ln, log, exp, pi, e, sqr, sqrt, ');
      LoadLine('  and all trigonometric and hyperbolic functions and');
      LoadLine('  their inverses. i.e., 2*x*sin(x+y^2).');
      LoadLine('  f(x,y) = "                                    "');
      LoadLine('');
      LoadLine('  Enter extreme values of the coordinates, between');
      LoadLine('                  -10 and 10:');
      LoadLine('  Minimum x = {      }  Maximum x = {      }');
      LoadLine('  Minimum y = {      }  Maximum y = {      }');
      LoadLIne('');
      LoadLine('  For the direction field, enter the number of sub-');
      LoadLine('  divisions along the axes. Do not exceed 50:');
      LoadLine('       x-axis: {    }        y-axis: {    }');
    {  LoadLine('');
      LoadLine('  Input from the keyboard #1 or the mouse #1'); }
      LoadLine('');
      LoadLine('       [ Help ]         [  OK  ]          [Cancel]');
      SetHelpFile('HelpBasc.hlp', 'DFieldsInputScreenHelp');
      SetString(1, FString);
      SetNumber(2, xLow);
      SetNumber(3, xHigh);
      SetNumber(4, yLow);
      SetNumber(5, yHigh);
      SetNumber(6, xColR);
      SetNumber(7, yRowR);
      SetNumberLimits(6, 1, 50);
      SetNumberLimits(7, 1, 50);
    {  IF NOT ClickForSolution THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);}
      AcceptScreen;
      IF Canceled THEN AbandonInput := True
      ELSE
      BEGIN
         FString := GetString(1);
         XLow := GetNumber(2);
         XHigh := GetNumber(3);
         YLow := GetNumber(4);
         YHigh := GetNumber(5);
         XColR := GetNumber(6);
         YRowR := GetNumber(7);
         SetNumberLimits(2, -10, 10);
         SetNumberLimits(3, -10, 10);
         SetNumberLimits(4, -10, 10);
         SetNumberLimits(5, -10, 10);
         SetNumberLimits(6, 5, 50);
         SetNumberLimits(7, 5, 50);
         xInitial := (xHigh + xLow)/2;
         yInitial := (yHigh + yLow)/2;
        { IF GetRadioButton(RBNames[1]) = 1 THEN
         ClickForSolution := False ELSE ClickForSolution := True;}
         AbandonInput := False;
      END;
      Done;
   END;
   FInput := DiffEq.parse('x','y','z', 't',FString);
   XCol := Trunc(XColR + 0.001);
   YRow := Trunc(YRowR + 0.001);
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpScreen;
VAR
   CoordStr: String;
   MaxCoord, MinCoord: Integer;
   nCoord, n: Integer;
   xSc, ySc: Integer;
   XPlotHigh, XPlotLow, YPlotHigh, YPlotLow: Integer;
BEGIN
   GraphBackColor := Black;
   SetColor(LightGreen);
   HideCursor;
   OpenViewPort(1);
   XPlotHigh := Trunc(XHigh);
   IF XPlotHigh < XHigh THEN XPlotHigh := XPlotHigh + 1;
   YPlotHigh := Trunc(YHigh);
   IF YPlotHigh < YHigh THEN YPlotHigh := YPlotHigh + 1;
   XPlotLow := Trunc(XLow);
   IF XPlotLow > XLow THEN XPlotLow := XPlotLow - 1;
   YPlotLow := Trunc(YLow);
   IF YPlotLow > YLow THEN YPlotLow := YPlotLow - 1;
   DefineScale(1, XPlotLow - 0.5, XPlotHigh + 0.5,
                  YPlotLow -0.5, YPlotHigh + 0.5);
   SelectScale(1);
   IF (YPlotHigh*YPlotLow <= 0) THEN
      PlotLine(XPlotLow, 0, XPlotHigh, 0)
   ELSE PlotLine(XPlotLow, YPlotLow, XPlotHigh, YPLotLow);
   IF (XPlotHigh*XPlotLow <= 0) THEN
      PlotLine(0, YPlotLow, 0, YPlotHigh)
   ELSE PlotLine(XPLotLow, YPlotLow, XPLotLow, YPlotHigh);
   nCoord := XPLotHigh - XPLotLow;
   FOR n := 0 TO nCoord DO
   BEGIN
      IF (YPlotHigh*YPlotLow <= 0) THEN
      BEGIN
         PlotLine(XPLotLow + n, 0, XPLotLow + n, 0.1);
         Map(XPLotLow + n, - 0.1, xSc, ySc);
      END
      ELSE
      BEGIN
         PlotLine(XPLotLow + n, YPLotLow, XPLotLow + n, YPLotLow + 0.1);
         Map(XPLotLow + n, YPLotLow - 0.1, xSc, ySc);
      END;
      Str(XPLotLow + n, CoordStr);
      IF XPLotLow + n <> 0 THEN OutTextxy(xSc, ySc, CoordStr);
      IF XPlotLow + n = 0 THEN OutTextxy(xSc - 15, ySc, CoordStr);
   END;
   nCoord := YPLotHigh - YPLotLow;
   FOR n := 0 TO nCoord DO
   BEGIN
      IF (XPlotHigh*XPlotLow <= 0) THEN
      BEGIN
         PlotLine(0, YPlotLow + n, 0.1, YPlotLow + n);
         Map(-0.2, YPLotLow + n, xSc, ySc);
      END
      ELSE
      BEGIN
         PlotLine(XPLotLow, YPLotLow + n, XPLotLow + 0.1, YPLotLow + n);
         Map(XPLotLow - 0.2, YPLotLow + n, xSc, ySc);
      END;
      Str(YPLotLow + n, CoordStr);
      IF YPLotLow + n > 0 THEN OutTextxy(xSc, ySc, CoordStr);
      IF YPLotLow + n < 0 THEN OutTextxy(xSc-10, ySc, CoordStr);
   END;
  { Map(-0.1, -0.1, xSc, ySc);
   OutTextxy(xSc, ySc, '0'); }
   DFieldMenu.RowActivate(5,1, True);
   DFieldMenu.Display;
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE DrawDirectionField;
{VAR
   DelX, DelY, Length: Real;
   DelXPixel, DelYPixel  : Real;
   Ratio                 : Real;
   Slope: Real;
   x, y: Real;
   z, r                  : Real;
   xEnd, yEnd: Real;
   i, j: Integer;}

VAR
   DelX, DelY, Length       : Integer;
   DX, DY, DL               : Real;
   Slope                    : Real;
   x, y                     : Real;
   xEnd, yEnd               : Real;
   i, j                     : Integer;
   Factor                   : Real;
   z, r                     : Real;

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



{PROCEDURE PlotDot(x,y: Real);
VAR
   XP, yP      : Integer;
   i, j        : Integer;
BEGIN
   xP := Mapx(x);
   yP := Mapy(y);
   FOR i := 1 TO 3 DO
   BEGIN
      FOR J := 1 TO 3 DO
         PutPixel(xP-2+i, yP-2+j, White);
   END;
END;  }

BEGIN
   HideMouse;
   SetColor(Yellow);
   DelX := Trunc((MapX(xHigh) - MapX(xLow))/xCol);
   DelY := Trunc(Abs(MapY(yHigh) - MapY(yLow))/yRow);
   Length := DelX;
   DX := (xHigh - xLow)/xCol;
   DY := (yHigh - yLow)/yRow;
   DL := DX;
   IF DY < DL THEN DL := DY;
   IF Length > DelY THEN Length := DelY;
   Length := Trunc(Length*0.9);
   FOR i := 0 TO xCol DO
   BEGIN
      x := xLow + i*DX;
      FOR j := 0 TO yRow DO
      BEGIN
         y := yLow + j*DY;
         Slope := DiffEq.F(x+0.00001, y+0.00001, z, r);
         Factor := Sqrt(1 + Slope*Slope);
         IF Factor > 0.001 THEN
         BEGIN
            xEnd := DL/Factor;
            yEnd := DL*Slope/Factor;
            Arrow(x, y, xEnd, yEnd, Length);
         END;
         PlotDot(x, y);
      END;
   END;
   ShowMouse;
END;



 {  HideMouse;
   SetColor(White);
   DelXPixel := GetMaxX/(xHigh - xLow);
   DelYPixel := GetMaxY/(yHigh - yLow);
   Ratio := DelYPixel/DelXPixel;
   DelX := (xHigh - xLow)/xCol;
   DelY := (yHigh - yLow)/yRow;
   Length := DelX;
   IF Length > DelY THEN
           Length := Dely;
           IF GetMaxX/Delx > GetMaxY/Dely THEN
            Length := Length*(GetMaxY/Dely)/(GetMaxX/DelX);
   Length := Length*0.8;
   FOR i := 0 TO xCol DO
   BEGIN
      x := xLow + (i+0.5)*DelX;
      FOR j := 0 TO yRow DO
      BEGIN
         y := yLow + (j+0.5)*DelY;
         Slope := DiffEq.F(x+0.00001, y+0.00001, z, r);
         xEnd := Length/Sqrt(1 + Ratio*Ratio*Slope*Slope)/2;
         yEnd := Slope*xEnd;
         PlotLine(x - xEnd, y - yEnd, x + xEnd, y + yEnd);
         PlotDot(x,y);
      END;
   END;
   ShowMouse;
END;   }

{------------------------------------------------------------------------}

PROCEDURE PlotSolution(x0, y0: Real);
CONST
   neq = 1;
TYPE
Vector = Array[1..neq] OF Real;

VAR
   xOld, yOld, xNew, yNew: Real;
   PlotOK: Boolean;
   y, z: Vector;
   x, h: Real;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
VAR
   r, s    : Real;
BEGIN
   z[1] := DiffEq.F(x, y[1], s, r);
   IF z[1] > 100 THEN PlotOK := False;
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

BEGIN
   SetColor(Yellow);
   PlotOK := True;
   xOld := x0;
   yOld := y0;
   x := x0;
   y[1] := y0;
   h := 0.1;
   REPEAT
      Step(x, h, 0.000001, y, x, h, y);
      xNew := x;
      yNew := y[1];
      PlotLine(xOld, yOld, xNew, yNew);
      xOld := xNew;
      yOld := yNew;
      IF (x > xHigh) OR (y[1] > yHigh) OR (y[1] < yLow)
                 THEN PlotOK := False;
   UNTIL Not PlotOK;
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptForClick(text : string; VAR x0, y0 : Real);
VAR
   dx,dy,cx,cy,a,n : integer;
   image           : TImage;
   DatImage        : TImage;
   z               : char;
   envir           : TEnvironment;
   Inside, Ins: Boolean;
   Button: Integer;
   xm, ym: Integer;
   MSave, FSave    : Real;
BEGIN
   Inside := True;
   Button := 0;
{   envir.Save;
   envir.Standardize;}
   SetFillStyle(SolidFill,red);
   dx := TextWidth(text)+13;
   dy := RowHt + 3;
   cx := (GetMaxX-dx) DIV 2;
   cy := (GetMaxY-dy) DIV 1;
 {  Image.Get(cx,cy,cx+dx,cy+dy);
   DatImage.Get(cx, cy-100, cx+dx, cy+dy-10);}
   HideMouse;
{   Bar3D(cx,cy+3,cx+dx-3,cy+dy,3,true);}
   ShowMouse;
   ClearMKBuffers;
   SetColor(Yellow);
   HideMouse;
 {  OutTextXY(cx+6,cy+8,Text); }
   ShowMouse;
 {  Envir.Reset;}
   SetColor(Yellow);
   REPEAT
      MousePosn(x0, y0, 1, 1, Inside);
      IF NOT Inside THEN RubOutXY(0.4, 0.02, 20, Black);
      IF Inside AND
      (Abs(MSave - (x0)) + Abs(FSave - (y0)) > 0.01) THEN
      BEGIN
         RubOutXY(0.4, 0.02, 20, Black);
         PrintXY(0.4, 0.02, '('+NumStr(x0, 4, 2)+', '+NumStr(y0, 4, 2)+')');
         MSave := (x0);
         FSave := (y0);
      END;
   UNTIL MouseClicked(a,a);
   RubOutXY(0.4, 0.02, 20, Black);
   Message('');
{   envir.Save;
   envir.Standardize;
   image.put(cx,cy);
   DatImage.Put(cx, cy-100);
   envir.Reset; }
END;

{------------------------------------------------------------------------}   

PROCEDURE MouseSolution;
VAR
   Inside: Boolean;
   xIn, yIn: Real;
BEGIN
   Delay(300);
   ShowCursor;
   Message('Click on a starting point. Click outside the window to quit.');
   PromptForClick(
   '',
   xIn, yIn);
 {  WaitOnMouseClick;}
   MousePosn(xIn, yIn, 1, 1, Inside);
   IF NOT Inside THEN
   BEGIN
      BackToMenu := True;
     { Comment(0.1, 0.05, ' ');}
   END
   ELSE
   BEGIN
      xInitial := xIn;
      yInitial := yIn;
      PlotSolution(xInitial, yInitial);
      BackToMenu := False;
      DFieldMenu.RowActivate(4,1, True);
      DFieldMenu.RowActivate(4,2, True)
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE KeySolution;
VAR
   x0, y0      : Real;
   KeyScreen   : TInputScreen;
BEGIN
   Message('');
   WITH KeyScreen DO
   BEGIN
      Init;
      DefineInputPort(0.05, 0.95, 0, 0.05);
      LoadLine('x = {      }, y = {      }   [  OK  ]   [Cancel]');
      SetNumber(1, xInitial);
      SetNumberLimits(1, xLow, xHigh);
      SetNumber(2, yInitial);
      SetNumberLimits(2, yLow, yHigh);
      AcceptScreen;
      IF Canceled THEN BackToMenu := True
      ELSE
      BEGIN
         BackToMenu := False;
         xInitial := GetNumber(1);
         yInitial := GetNumber(2);
         DFieldMenu.RowActivate(4,1, True);
         DFieldMenu.RowActivate(4,2, True)
      END;
      Done;
   END;
   IF NOT BackToMenu THEN
   BEGIN
      GraphBackColor := Red;
      {SetColor(DarkGray);
      OpenViewPort(2);}
      SelectViewPort(1);
      PlotSolution(xInitial, yInitial);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE RequestStepSize(VAR StepSize: REAL);
VAR
   StepDat   : TInputScreen;
BEGIN
   WITH StepDat DO
   BEGIN
      Init;
      DefineInputPort(0.05, 0.95, 0, 0.05);
      LoadLine('Stepsize, 0 < h <= 1. {      }   [  OK  ]   [Cancel]');
      SetNumber(1, StepSize);
      SetNumberLimits(1, 0.000001, 1);
      AcceptScreen;
      IF Canceled THEN BEGIN Done; BackToMenu := True; Exit;  END
      ELSE
      BEGIN
         StepSize := GetNumber(1);
         BackToMenu := False;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE EulerStep;
VAR
   xc, yc: Real;
   r, s     : Real;
BEGIN
   Message('            Press a key to stop computation');
   SetColor(LightMagenta);
   xc := xInitial;
   yc := yInitial;
   REPEAT
      PlotSymbol(xc, yc, '.');
      yc := yc + StepSize*DiffEq.F(xc, yc, r, s);
      xc := xc + StepSize;
   UNTIL (xc > xHigh) OR (yc > yHigh) OR (yc < yLow) OR KeyPressed;
   ClearMKBuffers;
   Message('');
END;

{------------------------------------------------------------------------}

PROCEDURE ImpEulerStep;
VAR
   xc, yc, yE, fE  : Real;
   r, s            : Real;
BEGIN
   SetColor(Yellow);
   Message('            Press a key to stop computation');
   xc := xInitial;
   yc := yInitial;
   REPEAT
      PlotSymbol(xc, yc, '*');
      fE := DiffEq.F(xc, yc, r, s);
      yE := yc + StepSize*fE;
      xc := xc + StepSize;
      yc := yc + 0.5*StepSize*(fE + DiffEq.F(xc, yE, r, s));
   UNTIL (xc > xHigh) OR (yc > yHigh) OR (yc < yLow) OR KeyPressed;
   Message('');
   ClearMKBuffers;
END;


{------------------------------------------------------------------------}

PROCEDURE RunEulersMethod;
BEGIN
   SetUpScreen;
   LightMenu := False;
   IF ClickForSolution THEN MouseSolution ELSE KeySolution;
   IF BackToMenu THEN BEGIN LightMenu := True; Exit; END;
   REPEAT
      RequestStepSize(StepSize);
      IF NOT BackToMenu THEN EulerStep;
   UNTIL BackToMenu;
   SetColor(DarkGray);
   SelectViewPort(1);
   LightMenu := True;
END;

{------------------------------------------------------------------------}

PROCEDURE RunImprovedEulersMethod;
VAR
   FirstTime: Boolean;
BEGIN
   FirstTime := True;
   LightMenu := False;
   SetUpScreen;
   IF ClickForSolution THEN MouseSolution ELSE KeySolution;
   IF BackToMenu THEN BEGIN LightMenu := True; Exit; END;
   REPEAT
      RequestStepSize(StepSize);
      IF (NOT FirstTime) AND (NOT BackToMenu) THEN
      BEGIN
         SetUpScreen;
         PlotSolution(xInitial, yInitial);
      END;
      IF NOT BackToMenu THEN
      BEGIN
         ImpEulerStep;
         EulerStep;
         FirstTime := False;
      END;
   UNTIL BackToMenu;
   SetColor(DarkGray);
   SelectViewPort(1);
   LightMenu := True;
END;

{------------------------------------------------------------------------}

PROCEDURE GetData;
BEGIN
   ClearMuppetPort;
   FunctionOK := True;
   REPEAT
      FunctionOK := FInput;
      IF NOT AbandonInput THEN
      BEGIN
         IF NOT FunctionOK THEN
         BEGIN
            Announce('There is a syntax error in your function. Try again');
         END
         ELSE
         BEGIN
            IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
            BEGIN
               Announce('Stupid coordinate limits! Try again.');
               FunctionOK := False;
            END;
         END;
      END;
   UNTIL (FunctionOK) OR (AbandonInput);
   IF AbandonInput THEN
   BEGIN
      LightMenu := True;
      DFieldMenu.RowActivate(3,2, False);
      DFieldMenu.RowActivate(3,3, False);
      DFieldMenu.RowActivate(3,4, False);
      DFieldMenu.RowActivate(4,1, False);
      DFieldMenu.RowActivate(4,2, False);
   END
   ELSE
   BEGIN
      SetUpScreen;
      DrawDirectionField;
      DFieldMenu.RowActivate(3,2, True);
      DFieldMenu.RowActivate(3,3, True);
      DFieldMenu.RowActivate(3,4, True);
      DFieldMenu.RowActivate(4,1, True);
      DFieldMenu.RowActivate(4,2, True);
      LightMenu := True;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleDFieldMenu;

BEGIN
   With DFieldMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpBasc.hlp','DFieldsAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpBasc.hlp', 'DFieldsDFieldHelp1');
                  ShowHelp('HelpBasc.hlp', 'DFieldsDFieldHelp2');
                  ShowHelp('HelpBasc.hlp', 'DFieldsDFieldHelp3');
               END;
            2: BEGIN
                  ShowHelp('HelpBasc.hlp', 'DFieldsEulerHelp1');
                  ShowHelp('HelpBasc.hlp', 'DFieldsEulerHelp2');
               END;
            3: BEGIN
                  ShowHelp('HelpBasc.hlp', 'DFieldsImpEulerHelp1');
                  ShowHelp('HelpBasc.hlp', 'DFieldsImpEulerHelp2');
               END;
         END;
      3: CASE RowChosen OF
            1: GetData;
            2: BEGIN
                  REPEAT
                     KeySolution;
                  UNTIL BackToMenu;
                  SetColor(DarkGray);
                  SelectViewPort(1);
                  LightMenu := True;
               END;
            3: BEGIN
                  REPEAT
                     MouseSolution;
                  UNTIL BackToMenu;
                  SetColor(DarkGray);
                  SelectViewPort(1);
                  LightMenu := True;
               END;
            4: BEGIN
                  SetUpScreen;
                  DrawDirectionField;
                  LightMenu := True;
               END;
         END;
      4: CASE RowChosen OF
            1: RunEulersMethod;
            2: RunImprovedEulersMethod;
         END;
    END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.05, 0.95, 0.05, 0.95);
   DefineViewPort(2, 0.05, 0.95, 0, 0.05);
   DefineScale(2, 0, 10, 0, 3);
   AxesPlotted := False;
   ExitRequest := False;
   LightMenu := True;
   FString := 'x + y';
   StepSize := 0.1;
   xLow := -4;
   xHigh := 4;
   yLow := -4;
   yHigh := 4;
   xColR := 20;
   yRowR := 20;
   xCol := 20;
   yRow := 20;
   GraphBackColor := Black;
   SetColor(Black);
   Hello('HelpBasc.hlp','DFieldsAboutProgram');
   SetUpDFieldMenu;
   DFieldMenu.RowActivate(3,2, False);
   DFieldMenu.RowActivate(3,3, False);
   DFieldMenu.RowActivate(4,1, False);
   DFieldMenu.RowActivate(4,2, False);
END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   GetSetUp;
   GetData;
   REPEAT
      CheckForEvents;
      IF LightMenu THEN
      IF DFieldMenu.Chosen THEN HandleDFieldMenu;
   UNTIL ExitRequest;
   DFieldMenu.Done;
   CUPSDone;
END.