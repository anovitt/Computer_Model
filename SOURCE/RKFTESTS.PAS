PROGRAM RKFTesting;

USES crt, Graph, CUPSMupp, CUPS, CupsFunc, CupsGui, CUPSPars;

CONST
   Neq = 2;

TYPE
   Vector = Array[1..2] of Real;

VAR
   y: Vector;

VAR
   RKFMenu                    : TMenu;
   HotKeys                    : THotKeys;
   PrintStr                   : String;
   DiffEq                     : TParser;
   DiffEqOK                   : Boolean;
   FString                    : String;
   Solution                   : TParser;
   SolutionOK                 : Boolean;
   SolString                  : String;
   ArbConstant                : TParser;
   ArbConstantOK              : Boolean;
   ConString                  : String;
   Constant                   : Real;
   xPrint, yPrint             : Real;
   x, h                       : Real;
   xIn, yIn                   : Real;
   StepSize                   : Real;
   htemp                      : Real;
   tol                        : Real;
   xMax, xMin, yMax, yMin     : Real;
   xEnd                       : Real;
   xCol, yRow                 : Integer;
   NumSteps                   : Integer;
   ExitRequest                : Boolean;
   NextStep                   : Boolean;
   FinalStep                  : Boolean;
   xSc, ySc                   : Integer;
   Test2, Test4               : Boolean;
   LightMenu                  : Boolean;
   temax                      : Real;
   Key                        : Byte;

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


{-----------------------------------------------------------------------}

PROCEDURE Display;
BEGIN
   ClearMuppetPort;
   RKFMenu.Display;
   HideMouse;
   SelectScale(1);
   GraphBackColor := Red;
   OpenViewPort(2);
   GraphBackColor := Blue;
   SetColor(Yellow);
   OpenViewPort(1);
   SetTextStyle(1,HorizDir,4);
   Map(3.8, 13.5, xSc, ySc);
   OutTextxy(xSc, ySc, 'Testing');
   Map(1, 11.5, xSc, ySc);
   OutTextxy(xSc, ySc, 'Runge-Kutta-Fehlberg');
   SetTextStyle(1,HorizDir,1);
   ShowMouse;
END;

PROCEDURE SetBigWrite;
BEGIN SetTextStyle(1,HorizDir,2);
     { RowHt := 24;
      ColWidth := 16;}
END;

PROCEDURE SetNormalWrite;
BEGIN SetTextStyle(DefaultFont,HorizDir,1);
     { RowHt := 16;
      ColWidth := 8;}
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpRKFMenu;
VAR
   I    : Integer;
BEGIN
   With RKFMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Equation');
       row(2,1, 'Enter a differential equation');
       row(2,2, 'Direction field');
      Column(3, 'RKFTest1');
       row(3,1, 'Help');
       row(3,2, 'Run the test');
      Column(4, 'RKFTest2');
       row(4,1, 'Help');
       row(4,2, 'Run the test');
      Column(5, 'RKFTest3');
       row(5,1, 'Help');
       row(5,2, 'Run the test');
      Column(6, 'RKFTest4');
       row(6,1, 'Help');
       row(6,2, 'Test A');
       row(6,3, 'Test B');
       row(6,4, 'Test C');
      Column(7, 'RKFTest5');
       row(7,1, 'Help');
       row(7,2, 'Run test');
      FOR I := 1 TO 7 DO AutoChecking(I, 1);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(2);
      Key[1] := 'F2-Next';
      Key[2] := 'F10-Menu';
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: NextStep := True;
      2: BEGIN
            LightMenu := True;
            HotKeys.Clear;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE PrintString(xPrint, yPrint: Real; Message: String);
VAR
   xSc, ySc: Integer;
BEGIN
   Map(xPrint, yPrint, xSc, ySc);
   OutTextxy(xSc, ySc, Message);
END;

PROCEDURE PrintStringNum(xPrint, yPrint: Real; Message: String; Number: Real);
VAR
   xSc, ySc: Integer;
   NumberStr: String;
BEGIN
   Str(Number, NumberStr);
   Map(xPrint, yPrint, xSc, ySc);
   OutTextxy(xSc, ySc, Message + NumberStr);
END;

PROCEDURE PrintStringInt(xPrint, yPrint: Real; Message: String;
                         Number: Integer);
VAR
   xSc, ySc: Integer;
   NumberStr: String;
BEGIN
   Map(xPrint, yPrint, xSc, ySc);
   OutTextxy(xSc, ySc, Message + NumStr(Number,3,0));
END;

{--------------------------------------------------------------------}

PROCEDURE EnterFunctions;
VAR
   FInput          : TInputScreen;
   AbandonInput    : Boolean;
   FunctionsOK     : Boolean;
BEGIN
   FunctionsOK := True;
   AbandonInput := False;
   REPEAT
      WITH FInput DO
      BEGIN
         FInput.Init;
         DefineInputPort(0.1, 0.9, 0.1, 0.9);
         LoadLine('');
         LoadLine('     You are to enter three functions. Be careful with');
         LoadLine('  the syntax, and make sure that the formulas are correct.');
         LoadLine('  If there are ANY errors, the tests will not work.');
         LoadLine('');
         LoadLine('     Enter a function f(x, y), where dy/dx = f(x,y):');
         LoadLine('  f(x, y) = "                                          "');
         LoadLine('');
         LoadLine('     In this program, the arbitrary constant is represented');
         LoadLine('  by the symbol ''z''.');
         LoadLine('     Enter a function y(x ,z), which must be the');
         LoadLine('  solution of the equation dy/dx = f(x,y):');
         LoadLine('  y(x, z) = "                                          "');
         LoadLine('');
         LoadLine('     Enter a function C(x, y), which must be the ');
         LoadLine('  solution for Con of the equation y = y(x, Con):');
         LoadLine('  C(x, y) = "                                          "');
         LoadLine('');
         LoadLine('       [ Help ]         [  OK  ]          [Cancel]');
         SetHelpFile('HelpBasc.hlp', 'DFieldsInputScreenHelp');
         SetString(1, FString);
         SetString(2, SolString);
         SetString(3, ConString);
         AcceptScreen;
         IF Canceled THEN AbandonInput := True
         ELSE
         BEGIN
            FString := GetString(1);
            SolString := GetString(2);
            ConString := GetString(3);
            IF NOT DiffEqOK = DiffEq.parse('x','y','z', 't',FString) THEN
            BEGIN
               FunctionsOK := False;
               Announce('Syntax error in the first function. Please try again');
            END;
            IF NOT SolutionOK = Solution.parse('x','y','z', 't',SolString) THEN
            BEGIN
               FunctionsOK := False;
               Announce('Syntax error in the second function. Please try again');
            END;
            IF NOT ArbConstantOK = ArbConstant.parse('x','y','z', 't',ConString) THEN
            BEGIN
               FunctionsOK := False;
               Announce('Syntax error in the third function. Please try again');
            END;
         END;
      Done;
      END;
   UNTIL FunctionsOK OR AbandonInput;
END;

{------------------------------------------------------------------------}

FUNCTION Coordinates : Boolean;
VAR
   XYInput          : TInputScreen;
   CoordinatesOK    : Boolean;
   Quit             : Boolean;
   xl, xh, yl, yh   : Real;
BEGIN
   REPEAT
      WITH XYInput DO
      BEGIN
         Init;
         DefineInputPort(0.23, 0.77, 0.2, 0.85);
         LoadLine('');
         LoadLine('    Enter extreme values for x and y');
         LoadLine('  for the diagram. They should lie');
         LoadLine('  between -10 and 10:');
         LoadLine('       Minimum x: {       }');
         LoadLine('       Maximum x: {       }');
         LoadLine('       Minimum y: {       }');
         LoadLine('       Maximum y: {       }');
         LoadLine('');
         LoadLine('    Enter the number of subdivisions');
         LoadLine('  along the axes. Between 5 and 50:');
         LoadLine('     x-Axis: {   }  y-Axis: {   }');
         LoadLine('');
         LoadLine('   [ Help ]    [  OK  ]   [Cancel]');
         SetHelpFile('HelpBasc.hlp', 'RKFTestsHelpDirectionField');
         SetNumber(1, xMin);
         SetNumber(2, xMax);
         SetNumber(3, yMin);
         SetNumber(4, yMax);
         SetNumberlimits(1, -10, 10);
         SetNumberlimits(2, -10, 10);
         SetNumberlimits(3, -10, 10);
         SetNumberlimits(4, -10, 10);
         SetNumber(5, xCol);
         SetNumber(6, yRow);
         SetNumberLimits(5, 5, 50);
         SetNumberLimits(6, 5, 50);
         AcceptScreen;
         xl := GetNumber(1);
         xh := GetNumber(2);
         yl := GetNumber(3);
         yh := GetNumber(4);
         xCol := Trunc(GetNumber(5) + 0.001);
         yRow := Trunc(GetNumber(6) + 0.001);
         Coordinates := NOT Canceled;
         IF Canceled THEN Quit := True ELSE Quit := False;
         Done;
         IF NOT Quit THEN
         BEGIN
            IF (xl >= xh) OR (yl >= yh) THEN
            BEGIN
               Announce('Largest and smallest values are confused. Try again.');
               CoordinatesOK := False;
            END
            ELSE CoordinatesOK := True;
         END;
      END;
   UNTIL CoordinatesOK OR Quit;
   IF CoordinatesOK THEN
   BEGIN
      xMin := xl;
      xMax := xh;
      yMin := yl;
      yMax := yh;
   END;
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
   SetNormalWrite;
   ClearMuppetPort;
   GraphBackColor := Black;
   SetColor(LightGreen);
   HideCursor;
   DefineViewPort(10, 0.1, 0.9, 0.07, 0.93);
   OpenViewPort(10);
   XPlotHigh := Trunc(XMax);
   IF XPlotHigh < XMax THEN XPlotHigh := XPlotHigh + 1;
   YPlotHigh := Trunc(YMax);
   IF YPlotHigh < YMax THEN YPlotHigh := YPlotHigh + 1;
   XPlotLow := Trunc(XMin);
   IF XPlotLow > XMin THEN XPlotLow := XPlotLow - 1;
   YPlotLow := Trunc(YMin);
   IF YPlotLow > YMin THEN YPlotLow := YPlotLow - 1;
   DefineScale(10, XPlotLow - 0.5, XPlotHigh + 0.5,
                  YPlotLow -0.5, YPlotHigh + 0.5);
   SelectScale(10);
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
   ShowCursor;
   SetBigWrite;
   GraphBackColor := Blue;
END;

{------------------------------------------------------------------------}

PROCEDURE DrawDirectionField;

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




BEGIN
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
   FOR i := 0 TO xCol DO
   BEGIN
      x := xMin + i*DX;
      FOR j := 0 TO yRow DO
      BEGIN
         y := yMin + j*DY;
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

{--------------------------------------------------------------------}

FUNCTION CConst(x, y1: Real): Real;
VAR
   r, s : Real;
BEGIN
   CConst := ArbConstant.F(x, y1, r, s);
END;

{--------------------------------------------------------------------}

FUNCTION YCorrect(x: Real): Real;
VAR
   r, s     : Real;
BEGIN
   YCorrect := Solution.F(x, r, Constant, s);
END;

{--------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
VAR
   r, s    : Real;
BEGIN
   IF Test4 THEN
   BEGIN
      z[1] := y[2];
      z[2] := - y[1];
   END
   ELSE
   BEGIN
      z[1] := DiffEq.F(x, y[1], s, r);
      z[2] := 0;
   END;
END;

{--------------------------------------------------------------------}

Procedure Step(xin, hin, tol: real; yin: Vector;
               VAR xout, hout: real; VAR yout: Vector);

VAR
   a, ch, ct:                      array[1..6] of real;
   b:                              array[1..6,1..5] of real;
   f:                              array[1..6] of vector;
   y, ytemp, te:                          Vector;
   x, xtemp, h      :                   real;
   k, l, n:                        integer;
   HString: String;
   LineNumber: Integer;
   Count : Integer;

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
   Count := 0;
   xtemp := xin;
   h := hin;
   LineNumber := 14;
   IF Test2 THEN
      PrintStringNum(1.5, LineNumber+2,   'Tol: = ', Tol);
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
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
      IF Test2 THEN
      BEGIN
         IF temax > tol THEN
         BEGIN
            Count := Count + 1;
            Str(htemp, HString);
            PrintStringNum(0.4, LineNumber,   'Too big. TeMax: = ', TeMax);
            PrintStringNum(0.5, LineNumber-1, 'Bad stepsize: h = ', htemp);
            IF LineNumber < 5 THEN
            BEGIN
               LineNumber := 14;
               Message('   Click or press a key to continue');
               StaticPause;
               OpenViewPort(7);
               PrintStringNum(1.5, LineNumber+2,   'Tol: = ', Tol);
            END
            ELSE
               LineNumber := LineNumber - 3;
         END
         ELSE
         BEGIN
            PrintStringNum(0.2, LineNumber,   '      OK. TeMax: = ', TeMax);
            Str(htemp, HString);
            PrintStringNum(0.3, LineNumber-1, 'Good stepsize: h = ', htemp);
            Str(h, HString);
            PrintStringNum(0.32, LineNumber-2, 'Next stepsize: h = ', h);
            IF (Temax < tol/1000) AND (Count = 0) THEN
            PrintString(3, LineNumber-4, 'You are a WIMP');
         END
      END;
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
end;

{--------------------------------------------------------------------}

PROCEDURE RunTest1;
VAR
   hOut, Error: Real;
   RKFDat1: TInputScreen;


{------------------------------------------------------------------------}

FUNCTION RKFData1 : Boolean;
VAR
   FKFDat1  : TInputScreen;
BEGIN
   WITH RKFDat1 DO
   BEGIN
      Init;
      DefineInputPort(0.22, 0.78, 0.3, 0.8);
      LoadLine('');
      LoadLine('      DEBUGGING RUNGE-KUTTA-FEHLBERG 1');
      LoadLine('');
      LoadLine('    Enter the initial value of x:  {      }');
      LoadLine('');
      LoadLine('    Enter the initial value of y:  {      }');
      LoadLine('');
      LoadLine('Enter the value of the stepsize h: {      }');
      LoadLine('                 0 < h <= 1 ');
      LoadLine('');
      LoadLine('          [  OK  ]        [Cancel]');
      SetNumber(1, xIn);
      SetNumber(2, yIn);
      SetNumber(3, StepSize);
      SetNumberLimits(3, 0.00001, 1);
      AcceptScreen;
      RKFData1 := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         xIn := GetNumber(1);
         yIn := GetNumber(2);
         x := xIn;
         y[1] := yIn;
         StepSize := GetNumber(3);
         h := StepSize;
      END;
      Done;
   END;   
END;



BEGIN
   ClearMuppetPort;
   RKFMenu.Display;
   IF NOT RKFData1 THEN BEGIN LightMenu := True; Exit; END;
   ClearMuppetPort;
   {RKFMenu.Display;}
   Constant := CConst(x, y[1]);
   Step(x, h, 1, y, x, hOut, y); 
   SetBigWrite;
   OpenViewPort(1);
   SelectScale(1);
   SetColor(Yellow);
   HideCursor;
   PrintStringNum(2.65, 14, 'x = ', x);
   PrintStringNum(1.4, 13, 'Stepsize = ', hTemp);
   PrintStringNum(2.65, 12, 'y = ', y[1]);
   PrintStringNum(1.0, 11, 'y-correct = ', YCorrect(x));
   PrintStringNum(1.85, 10, 'Error = ', yCorrect(x) - y[1]);
   ShowCursor;
   SetNormalWrite;
   GraphBackColor := Red;
   {OpenViewPort(4); }
   SetNormalWrite;
   Message('Click or press a key to return to the menu.');
   StaticPause;
   Display;
   LightMenu := True;
END;

{--------------------------------------------------------------------}

PROCEDURE RunTest2;
VAR
   hOut, Error: Real;
   RKFDat2: TInputScreen;

{------------------------------------------------------------------------}

FUNCTION RKFData2 : Boolean;
BEGIN
   WITH RKFDat2 DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.15, 0.85);
      LoadLine('');
      LoadLine('     DEBUGGING RUNGE-KUTTA-FEHLBERG 2');
      LoadLine('');
      LoadLine('    Enter the initial value of x:  {      }');
      LoadLine('');
      LoadLine('    Enter the initial value of y:  {      }');
      LoadLine('');
      LoadLine('Enter the value of the stepsize h:         ');
      LoadLine('         (0 < h)         h = {            }');
      LoadLine('');
      LoadLine('Enter a value for the greatest tolerable');
      LoadLine('error:    Tol = {            }');
      LoadLine('                 0 < tol < 1');
      LoadLine('');
      LoadLine('          [  OK  ]        [Cancel]');
      SetNumber(1, xIn);
      SetNumber(2, yIn);
      SetNumber(3, StepSize);
      SetNumberLimits(3, 0.000000001, 1000000000);
      SetNumber(4, Tol);
      SetNumberLimits(4, 0.00000000001, 1);
      AcceptScreen;
      RKFData2 := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         xIn := GetNumber(1);
         yIn := GetNumber(2);
         StepSize := GetNumber(3);
         x := xIn;
         y[1] := yIn;
         h := StepSize;
         Tol := GetNumber(4);
      END;
      Done;
   END;   
END;



BEGIN
   Test2 := True;
   ClearMuppetPort;
   RKFMenu.Display;
   IF NOT RKFData2 THEN BEGIN LightMenu := True; Exit; END;
   Constant := CConst(x, y[1]);
   SetBigWrite;
   OpenViewPort(7);
   SelectScale(7);
   SetColor(Yellow);
   HideMouse;
   Step(x, h, tol, y, x, hOut, y);
   OpenViewPort(8);
   SelectScale(8);
   SetColor(Yellow);
   HideCursor;
   PrintStringNum(2.65, 14, 'x = ', x);
   PrintStringNum(1.4, 13, 'Stepsize = ', hTemp);
   PrintStringNum(2.65, 12, 'y = ', y[1]);
   PrintStringNum(1.0, 11, 'y-correct = ', YCorrect(x));
   PrintStringNum(1.85, 10, 'Error = ', yCorrect(x) - y[1]);
   ShowCursor;
   ShowMouse;
   Test2 := False;
   SetNormalWrite;
   {GraphBackColor := Red;
   OpenViewPort(4); }
   SetNormalWrite;
   Message('Click or press a key to return to the menu.');
   StaticPause;
   Display;
   LightMenu := True;
END;

{--------------------------------------------------------------------}

PROCEDURE RunTest3A;
VAR
   hOut, Error          : Real;
   RKFDat3A             : TInputScreen;
   StepCount            : Integer;
   xm, ym               : Real;
   Inside               : Boolean;

{------------------------------------------------------------------------}

FUNCTION RKFData3A : Boolean;
VAR
   fNum: Real;
BEGIN
   WITH RKFDat3A DO
   BEGIN
      Init;
      DefineInputPort(0.22, 0.78, 0.1, 0.8);
      LoadLine('');
      LoadLine('     DEBUGGING RUNGE-KUTTA-FEHLBERG 4A');
      LoadLine('');
      LoadLine('    Enter the initial value of x:  {      }');
      LoadLine('');
      LoadLine('    Enter the initial value of y:  {      }');
      LoadLine('');
      LoadLine('Enter the value of the stepsize h: {      }');
      LoadLine('                 0 < h <= 1 ');
      LoadLine('');
      LoadLine('Enter a value for the greatest tolerable');
      LoadLine('error:    tol = {            }');
      LoadLine('                 0 < tol < 1');
      LoadLine('  Enter the number of steps: {    } < 100');
      LoadLine('');
      LoadLine('          [  OK  ]        [Cancel]');
      SetNumber(1, xIn);
      SetNumber(2, yIn);
      SetNumber(3, StepSize);
      SetNumberLimits(3, 0.00001, 1);
      SetNumber(4, Tol);
      SetNumberLimits(4, 0.00000000001, 1);
      SetNumber(5, NumSteps);
      SetNumberLimits(5, 1, 100);
      AcceptScreen;
      RKFData3A := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         xIn := GetNumber(1);
         yIn := GetNumber(2);
         StepSize := GetNumber(3);
         x := xIn;
         y[1] := yIn;
         h := StepSize;
         Tol := GetNumber(4);
         fNum := GetNumber(5);
         NumSteps := Trunc(fNum + 0.00001);
      END;
      Done;
   END;  
END;

PROCEDURE PrintStuff;
BEGIN
   HideCursor;
   PrintStringInt(1.65, 14.7, 'Step ', StepCount);
   PrintStringNum(2.65, 13.5, 'x = ', x);
   PrintStringNum(1.4, 12.5, 'Stepsize = ', hTemp);
   PrintStringNum(2.65, 11.5, 'y = ', y[1]);
   PrintStringNum(1.0, 10.5, 'y-correct = ', YCorrect(x));
   PrintStringNum(1.85, 9.5, 'Error = ', yCorrect(x) - y[1]);
   ShowCursor;
END;



BEGIN
   ClearMuppetPort; ShowCursor;
   RKFMenu.Display;
   LightMenu := False;
   IF NOT RKFData3A THEN BEGIN LightMenu := True; Exit; END;
   GraphBackColor := Blue;
   SetBigWrite;
   Constant := CConst(x, y[1]);
   SetColor(Yellow);
   Message('     Use the hot keys to see the next step or to quit.');
   ShowCursor;
   SelectScale(1);
   GraphBackColor := Blue;
   SetBigWrite;
   StepCount := 1;
   SetColor(Yellow);
   {First Step}
   Step(x, h, tol, y, x, h, y);
   OpenViewPort(6);
   PrintStuff;
   HotKeys.Display;
   FinalStep := False;
   NextStep := False;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF NextStep THEN
      BEGIN
         IF StepCount = NumSteps-1 THEN
         BEGIN
            FinalStep := True;
            LightMenu := True;
         END;
         OpenViewPort(6);
         PrintStuff;
         ShowCursor;
         Step(x, h, tol, y, x, h, y);
         OpenViewPort(5);
         StepCount := StepCount + 1;
         PrintStuff;
         NextStep := False;
      END;
   UNTIL LightMenu;
   IF FinalStep THEN
   BEGIN
      HotKeys.Clear;
      ClearMKBuffers;
      Message('That''s all! Click or press a key to return to the menu.');
      StaticPause;
   END;
   GraphBackColor := Blue;
   Test4 := False;
   SelectScale(1);
   Display;
   LightMenu := True;
END;

{------------------------------------------------------------------------}

PROCEDURE RunTest3BC(CTrue: Boolean);
VAR
   hOut, Error          : Real;
   RKFDat3BC            : TInputScreen;
   StepCount            : Integer;
   xm, ym               : Real;
   Inside               : Boolean;


FUNCTION RKFData3BC : Boolean;
BEGIN
   WITH RKFDat3BC DO
   BEGIN
      Init;
      DefineInputPort(0.22, 0.78, 0.1, 0.8);
      LoadLine('');
      LoadLine('    DEBUGGING RUNGE-KUTTA-FEHLBERG 4B, C');
      LoadLine('');
      LoadLine('    Enter the initial value of x:  {      }');
      LoadLine('');
      LoadLine('    Enter the initial value of y:  {      }');
      LoadLine('');
      LoadLine('Enter the value of the stepsize h: {      }');
      LoadLine('                 0 < h <= 1 ');
      LoadLine('');
      LoadLine('Enter a value for the greatest tolerable');
      LoadLine('error:    tol = {            }');
      LoadLine('                 0 < tol < 1');
      LoadLine('     Enter the maximum value of x: {      }');
      LoadLine('');
      LoadLine('          [  OK  ]        [Cancel]');
      SetNumber(1, xIn);
      SetNumber(2, yIn);
      SetNumber(3, StepSize);
      SetNumberLimits(3, 0.00001, 1);
      SetNumber(4, Tol);
      SetNumberLimits(4, 0.00000000001, 1);
      SetNumber(5, xEnd);
      SetNumberLimits(5, 1, 1000);
      AcceptScreen;
      RKFData3BC := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         xIn := GetNumber(1);
         yIn := GetNumber(2);
         h := GetNumber(3);
         x := xIn;
         y[1] := yIn;
         h := StepSize;
         Tol := GetNumber(4);
         xEnd := GetNumber(5);
      END;
      Done;
   END;
END;

PROCEDURE PrintStuff;
BEGIN
   HideCursor;
   PrintStringNum(2.65, 14, 'x = ', x);
   PrintStringNum(1.4, 13, 'Stepsize = ', hTemp);
   PrintStringNum(2.65, 12, 'y = ', y[1]);
   PrintStringNum(1.0, 11, 'y-correct = ', YCorrect(x));
   PrintStringNum(1.85, 10, 'Error = ', yCorrect(x) - y[1]);
   ShowCursor;
END;


BEGIN
   ClearMuppetPort; ShowCursor;
   RKFMenu.Display;
   LightMenu := False;
   IF NOT RKFData3BC THEN BEGIN LightMenu := True; Exit; END;
   SetNormalWrite;
   SelectScale(1);
   GraphBackColor := Blue;
   SetBigWrite;
   Constant := CConst(x, y[1]);
   StepCount := 0;
   SetColor(Yellow);
   Message('     Use the hot keys to see the next step or to quit.');
   ShowCursor;
   SelectScale(1);
   GraphBackColor := Blue;
   SetBigWrite;
   StepCount := 0;
   SetColor(Yellow);
   {First Step}
   Step(x, h, tol, y, x, h, y);
   OpenViewPort(6);
   PrintStuff;
   HotKeys.Display;
   NextStep := False;
   FinalStep := False;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF NextStep THEN
      BEGIN
         IF x > xEnd THEN
         BEGIN
            h := xEnd - x;
            FinalStep := True;
            LightMenu := True;
         END;
         OpenViewPort(6);
         PrintStuff;
         ShowCursor;
         Step(x, h, tol, y, x, h, y);
         OpenViewPort(5);
         PrintStuff;
         NextStep := False;
         IF (x > xEnd) AND (NOT CTrue) THEN Lightmenu := True;
      END;
   UNTIL LightMenu;
   IF FinalStep THEN
   BEGIN
      HotKeys.Clear;
      ClearMKBuffers;
      Message('That''s all! Click or press a key to return to the menu.');
      StaticPause;
   END;
   GraphBackColor := Blue;
   Test4 := False;
   SelectScale(1);
   Display;
   LightMenu := True;
END;

{------------------------------------------------------------------------}

PROCEDURE RunTest4;
VAR
   hOut, Error: Real;
   RKFDat4: TInputScreen;
   StepCount: Integer;
   Const1, Const2: Real;
   xm, ym               : Real;
   Inside               : Boolean;


FUNCTION RKFData4 : Boolean;
BEGIN   
   WITH RKFDat4 DO
   BEGIN
      Init;
      DefineInputPort(0.22, 0.78, 0.1, 0.85);
      LoadLine('');
      LoadLine('      DEBUGGING RUNGE-KUTTA-FEHLBERG 5');
      LoadLine('');
      LoadLine('    Enter the initial value of x: {      }');
      LoadLine('');
      LoadLine(' Enter the initial value of y(1): {      }');
      LoadLine(' Enter the initial value of y(2): {      }');
      LoadLine('');
      LoadLine('Enter the value of the stepsize h:{      }');
      LoadLine('');
      LoadLine('Enter a value for the greatest tolerable');
      LoadLine('error:      tol: {            }');
      LoadLine('');
      LoadLine('    Enter the maximum value of x: {      }');
      LoadLine('');
      LoadLine('         [  OK  ]       [Cancel]');
      SetNumber(1, 0);
      SetNumber(2, 1);
      SetNumber(3, 0);
      SetNumber(4, 0.1);
      SetNumber(5, 0.000001);
      SetNumber(6, xEnd);
      SetNumberLimits(4, 0.000001, 1);
      SetNumberLimits(5, 0.00000000001, 1);
      AcceptScreen;
      RKFData4 := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         x := GetNumber(1);
         y[1] := GetNumber(2);
         y[2] := GetNumber(3);
         h := GetNumber(4);
         tol := GetNumber(5);
         xEnd := GetNumber(6);
      END;
      Done;
   END;
END;

PROCEDURE PrintStuff;
BEGIN
   HideCursor;
   PrintStringNum(2.65, 14, 'x = ', x);
   PrintStringNum(1.2, 13, 'Stepsize = ', hTemp);
   PrintStringNum(2.4, 12, 'y1 = ', y[1]);
   PrintStringNum(2.4, 11, 'y2 = ', y[2]);
   PrintStringNum(1.5, 10, 'Error1 = ',  Const1*Cos(x) + Const2*Sin(x)- y[1]);
   PrintStringNum(1.5, 9,  'Error2 = ', -Const1*Sin(x) + Const2*Cos(x)- y[2]);
   ShowCursor;
END;


BEGIN
   Test4 := True;
   LightMenu := False;
   FinalStep := False;
   ClearMuppetPort;
   RKFMenu.Display;
   IF NOT RKFData4 THEN BEGIN LightMenu := True; Exit; END;
   SetNormalWrite;
   Message('     Use the hot keys to see the next step or to quit.');
   ShowCursor;
   SelectScale(1);
   Const1 := y[1]*Cos(x) - y[2]*Sin(x);
   Const2 := y[1]*Sin(x) + y[2]*Cos(x);
   GraphBackColor := Blue;
   SetBigWrite;
   StepCount := 0;
   SetColor(Yellow);
   {First Step}
   Step(x, h, tol, y, x, h, y);
   OpenViewPort(6);
   PrintStuff;
   HotKeys.Display;
   NextStep := False;
   FinalStep := False;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF NextStep THEN
      BEGIN
         IF x > xEnd THEN
         BEGIN
            h := xEnd - x;
            FinalStep := True;
            LightMenu := True;
         END;
         OpenViewPort(6);
         PrintStuff;
         ShowCursor;
         Step(x, h, tol, y, x, h, y);
         OpenViewPort(5);
         PrintStuff;
         NextStep := False;
      END;
   UNTIL LightMenu;
   IF FinalStep THEN
   BEGIN
      HotKeys.Clear;
      ClearMKBuffers;
      Message('That''s all! Click or press a key to return to the menu.');
      StaticPause;
   END;
   GraphBackColor := Blue;
   Test4 := False;
   SelectScale(1);
   Display;
   LightMenu := True;
END;

{--------------------------------------------------------------------}

PROCEDURE RunTest5;
VAR
   LogH, LogTeMax, LogError    : Array[1..10] OF Real;
   H0, DH                      : Real;
   I, J                        : Integer;
   xInit, yInit                : Real;
   LsCoeff                     : Array[1..6] OF Real;
   LsSlope, LsB                : Real;

{--------------------------------------------------------------------}

FUNCTION RKFData5 : Boolean;
VAR
   Input               : TInputScreen;
   Quit                : Boolean;

BEGIN
   REPEAT
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.17, 0.83, 0.15, 0.85);
         LoadLine('');
         LoadLine('        DEBUGGING RUNGE-KUTTA-FEHLBERG 4');
         LoadLine('');
         LoadLine('     The program will take ten steps, each step');
         LoadLine('  starting with the same initial conditions,');
         LoadLine('  y(x0) = y0.');
         LoadLine('     Enter values for these conditions:');
         LoadLine('        x0 = {       }, y0 = {       }.');
         LoadLine('');
         LoadLine('     The steps will use the ten stepsizes:');
         LoadLine('     h0, h0 + dh, h0 + 2dh, ..., h0 + 9dh,');
         LoadLine('  where h0 + 10dh < 1. Enter values:');
         LoadLine('         h = {       }, dh = {       }.');
         LoadLine('');
         LoadLine('           [  OK  ]      [Cancel]');
         SetNumber(1, xIn);
         SetNumber(2, yIn);
         SetNumber(3, h0);
         SetNumber(4, dh);
         SetNumberLimits(3, 0, 1);
         SetNumberLimits(4, 0, 1);
         AcceptScreen;
         Quit := Canceled;
         RKFData5 := NOT Canceled;
         IF NOT Canceled THEN
         BEGIN
            xIn := GetNumber(1);
            yIn := GetNumber(2);
            h0 := GetNumber(3);
            dh := GetNumber(4);
         END;
         Done;
      END;
      IF h0+10*dh >= 1 THEN
         Announce('h0 + 10*dh must be less than one. Try again.');
   UNTIL (h0 + 10*dH < 1) OR Quit;
END;

{--------------------------------------------------------------------}

BEGIN
   DefineViewPort(10, 0.05, 0.48, 0.1, 0.9);
   DefineViewPort(11, 0.55, 0.98, 0.1, 0.9);
   SetNormalWrite;
   H0 := 0.01;
   DH := 0.01;
   ClearMuppetPort;
   IF NOT RKFData5 THEN BEGIN LightMenu := True; Exit; END;
   Constant := CConst(xInit, yInit);
   FOR I := 1 TO 10 DO
   BEGIN
      x := xIn;
      y[1] := yIn;
      h := H0 + (i-1)*DH;
      LogH[I] := Ln(H)/Ln(10);
      Step(x, h, 1, y, x, h, y);
      LogTeMax[I] := Ln(TeMax)/Ln(10);
      LogError[I] := Ln(Abs(yCorrect(x) - y[1]))/Ln(10);
   END;
   DefineScale(10, 1.1*LogH[1], 0.9*LogH[10],
                   1.1*LogTeMax[1], 0.9*LogTeMax[10]);
   DefineScale(11, 1.1*LogH[1], 0.9*LogH[10],
                   1.1*LogError[1], 0.9*LogError[10]);
   GraphBackColor := DarkGray;
   OpenViewPort(10);
   SelectScale(10);
   Axis(0, 0, 0.5, 1);
   OpenViewPort(11);
   SelectScale(11);
   Axis(0, 0, 0.5, 1);
   SetColor(Yellow);
   PrintXY(0.57, 0.8, 'Log(Error)');
   PrintXY(0.7, 0.05, 'Log(H)');
   FOR I := 1 TO 10 DO
      PlotSymbol(LogH[I], LogError[I], '*');
   FOR J := 1 TO 6 DO LsCoeff[j] := 0;
   FOR I := 1 TO 10 DO
   BEGIN
      LsCoeff[1] := LsCoeff[1] + LogH[I]*LogH[I];
      LsCoeff[2] := LsCoeff[2] + LogH[I];
      LsCoeff[3] := LsCoeff[3] + LogH[I]*LogError[I];
      LsCoeff[6] := LsCoeff[6] + LogError[I];
   END;
   LsCoeff[4] := LsCoeff[2];
   LsCoeff[5] := 10;
   LsSlope := (LsCoeff[3]*LsCoeff[5] - LsCoeff[6]*LsCoeff[2])/
              (LsCoeff[1]*LsCoeff[5] - LsCoeff[2]*LsCoeff[4]);
   LsB := -(LsCoeff[3]*LsCoeff[4] - LsCoeff[6]*LsCoeff[1])/
              (LsCoeff[1]*LsCoeff[5] - LsCoeff[2]*LsCoeff[4]);
   PlotLine(LogH[1], LsSlope*LogH[1] + LsB,
            LogH[10], LsSlope*LogH[10] + LsB);
   PrintXY(0.7, 0.2, 'Slope: '+NumStr(LsSlope, 4, 2));
   SetColor(LightCyan);
   PrintXY(0.07, 0.8, 'Log(TeMax)');
   PrintXY(0.2, 0.05, 'Log(H)');
   SelectViewPort(10);
   SelectScale(10);
   FOR I := 1 TO 10 DO
      PlotSymbol(LogH[I], LogTeMax[I], '+');
   FOR J := 1 TO 6 DO LsCoeff[j] := 0;
   FOR I := 1 TO 10 DO
   BEGIN
      LsCoeff[1] := LsCoeff[1] + LogH[I]*LogH[I];
      LsCoeff[2] := LsCoeff[2] + LogH[I];
      LsCoeff[3] := LsCoeff[3] + LogH[I]*LogTeMax[I];
      LsCoeff[6] := LsCoeff[6] + LogTeMax[I];
   END;
   LsCoeff[4] := LsCoeff[2];
   LsCoeff[5] := 10;
   LsSlope := (LsCoeff[3]*LsCoeff[5] - LsCoeff[6]*LsCoeff[2])/
              (LsCoeff[1]*LsCoeff[5] - LsCoeff[2]*LsCoeff[4]);
   LsB := -(LsCoeff[3]*LsCoeff[4] - LsCoeff[6]*LsCoeff[1])/
              (LsCoeff[1]*LsCoeff[5] - LsCoeff[2]*LsCoeff[4]);
   PlotLine(LogH[1], LsSlope*LogH[1] + LsB,
            LogH[10], LsSlope*LogH[10] + LsB);
   PrintXY(0.2, 0.2, 'Slope: '+NumStr(LsSlope, 4, 2));
   Message('      Click or hit any key to continue');
   StaticPause;
END;

{--------------------------------------------------------------------}

PROCEDURE HandleRKFMenu;

BEGIN
   With RKFMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpBasc.hlp', 'RKFTestsAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1:EnterFunctions;
            2: IF Coordinates THEN
               BEGIN
                  SetUpScreen;
                  DrawDirectionField;
               END;
         END;
      3: CASE RowChosen OF
            1: ShowHelp('HelpBasc.hlp', 'RKFTestsHelp1');
            2: RunTest1;
         END;
      5: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpBasc.hlp', 'RKFTestsHelp2A');
                  ShowHelp('HelpBasc.hlp', 'RKFTestsHelp2B');
               END;
            2: RunTest2;
         END;
      4: CASE RowChosen OF
            1:BEGIN
                  ShowHelp('HelpBasc.hlp', 'RKFTestsHelp5A');
                  ShowHelp('HelpBasc.hlp', 'RKFTestsHelp5B');
                  ShowHelp('HelpBasc.hlp', 'RKFTestsHelp5C');
               END;
            2: RunTest5;
         END;
      6: CASE RowChosen OF
            1: ShowHelp('HelpBasc.hlp', 'RKFTestsHelp3');
            2: RunTest3A;
            3: RunTest3BC(False);
            4: RunTest3BC(True);
         END;
      7: CASE RowChosen OF
            1: ShowHelp('HelpBasc.hlp', 'RKFTestsHelp4');
            2: RunTest4;
         END;
    END;
END;

{--------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   Test2 := False;
   Test4 := False;
   ExitRequest := False;
   DefineViewPort(1, 0.1, 0.9, 0.3, 0.7);
   DefineViewPort(2, 0.12, 0.92, 0.32, 0.72);
   DefineViewPort(3, 0.08, 0.92, 0.3, 0.7);
   DefineViewPort(4, 0.15, 0.85, 0.9, 0.95);
   DefineViewPort(5, 0.1, 0.9, 0.1, 0.5);
   DefineViewPort(6, 0.1, 0.9, 0.5, 0.9);
   DefineViewPort(7, 0.08, 0.92, 0.25, 0.9);
   DefineViewPort(8, 0.08, 0.92, 0.0, 0.22);
   DefineScale(8, 0, 10, 9, 14);
   DefineScale(7, 0, 10, 2, 16.5);
   DefineScale(1, 0, 10, 8, 15);
   DefineScale(2, 0, 10, 7.5, 14.5);
   DefineScale(4, 0, 1, 0, 1);
   LightMenu := True;
   SetUpHotKeys;
   xIn := 0;
   yIn := 0;
   xMin := -4;
   xMax := 4;
   yMin := -4;
   yMax := 4;
   xEnd := 2;
   xCol := 20;
   yRow := 20;
   NumSteps := 10;
   StepSize := 0.1;
   Tol := 0.000001;
   FString := 'x + y';
   SolString := 'Z*Exp(x) - x - 1';
   ConString := 'Exp(-x)*(y + x + 1)';
   DiffEqOK := DiffEq.parse('x','y','z', 't',FString);
   SolutionOK := Solution.parse('x','y','z', 't',SolString);
   ArbConstantOK := ArbConstant.parse('x','y','z', 't',ConString);
   Hello('HelpBasc.hlp', 'RKFTestsAboutProgram');
   Display;
   SetUpRKFMenu;
END;

{--------------------------------------------------------------------}

BEGIN
   CUPSInit;
   DiffEq.Init;
   Solution.Init;
   ArbConstant.Init;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF LightMenu THEN
      IF RKFMenu.Chosen THEN HandleRKFMenu
      ELSE
      IF RKFMenu.Activated THEN HandleRKFMenu;
   UNTIL ExitRequest;
   RKFMenu.Done;
   CUPSDone;
END.