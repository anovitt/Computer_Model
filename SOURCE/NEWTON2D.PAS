PROGRAM NewtonSystem;

USES Graph, Crt, CupsMupp, CUPS, CupsGrph, CupsFunc, CupsProc, CupsGui,
     CupsPars;

VAR
   NewtonMenu                        : TMenu;
   HotKeys, ZoomHotKeys              : THotKeys;
   GFunc, GXFunc, GYFunc             : TParser;
   FFunc, FXFunc, FYFunc             : TParser;
   GStr, GXStr, GYStr                : String;
   FStr, FXStr, FYStr                : String;
   xMinDef, xMaxDef, yMinDef, yMaxDef: Real;
   xMinSel, xMaxSel, yMinSel, yMaxSel: Real;
   xLow, xHigh, yLow, yHigh          : Real;
   xLowIn, yLowIn, xHighIn, yHighIn  : Real;
   Converged                         : Boolean;
   UseKeys                           : Boolean;
   Iterate                           : Boolean;
   Fractals                          : Boolean;
   Plotting                          : Boolean;
   Zoom                              : Boolean;
   Action                            : Boolean;
   ExitRequest                       : Boolean;
   LightMenu                         : Boolean;
   OverFlow                          : Boolean;
   InputOK                           : Boolean;
   xGuess, yGuess                    : Real;
   C                                 : Real;
   Key                               : Byte;
   ModelNumber                       : Integer;
   SolutionNumber                    : Array[1..4] OF Integer;
   xSolution, ySolution              : Array[1..4, 1..20] OF Real;
   Colors                            : Array[1..20] OF Word;
   ColorNumber                       : Integer;
   ZoomFactor                        : Real;
   xPixelNumber                      : Integer;
   FractalNumber                     : Integer;
   MinXPix, MinYPix: Integer; {Pixel coordinates of top left corner of
                               graph.}
   XPixels, YPixels: Integer; {Numbers of pixels inside graph.}
   NX, NY                            : Integer;

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

{----------------------------------------------------------------------}

PROCEDURE SetUpNewtonMenu;
VAR
   I     : Integer;
BEGIN
   With NewtonMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Newton''s method');
       row(2,2, 'Fractal patterns');
       row(2,3, 'Complex equations');
       row(2,4, 'Walk-through');
      Column(3, 'Model');
       row(3,1, 'One');
       row(3,2, 'Two');
       row(3,3, 'Three');
       row(3,4, 'Do it yourself');
      Column(4, 'Run');
       row(4,1, 'Follow iterations');
       row(4,2, 'See fractal patterns 1');
       row(4,3, 'See fractal patterns 2');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   NewtonMenu.Display;
END;

{----------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Mouse';
      Key[3] := 'F3-Keys';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.Display;
END;

{----------------------------------------------------------------------}

PROCEDURE SetUpZoomHotKeys;
BEGIN
   WITH ZoomHotKeys DO
   BEGIN
      ZoomHotKeys.Init(4);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Stop';
      Key[3] := 'F3-ZoomIn';
      Key[4] := 'F10-Menu';
   END;
   ZoomHotKeys.Display;
END;

{----------------------------------------------------------------------}

PROCEDURE GetNewtonData;
VAR
   NewtonDat : TInputScreen;
   StrOK     : Array [1..6] OF Boolean;
   Str       : Array [1..6] of String;
   I         : Integer;
   z, r      : Real;

BEGIN
   CASE ModelNumber OF
   1: BEGIN
         WITH NewtonDat DO
         BEGIN
            Init;
            DefineInputPort(0.2, 0.8, 0.1, 0.9);
            LoadLine('           Input Parameters.');
            LoadLine('');
            LoadLine('    This utility solves the two simultaneous');
            LoadLine(' equations:');
            LoadLine('             x*x + x*y*y*y = 9,');
            LoadLine('             3x*x*y - y*y*y = 4.');
            LoadLine('');
            LoadLine('   Solutions are close to:');
            LoadLine(' (1.34, 1.75), (-3.00, 0.15), (3.00, 0.15)');
            LoadLine('             and (-0.90, -2.09)');
            LoadLine('');
            LoadLine('    Enter values for the extreme coordinates');
            LoadLine(' for the display. (Less than 20 in magnitude.)');
            LoadLine('       XLow = {      }, XHigh = {      }');
            LoadLIne('       YLow = {      }, YHigh = {      }');
            LoadLine('');
            LoadLine('           [  OK  ]        [Cancel] ');
            SetNumber(1, XLowIn);
            SetNumber(2, XHighIn);
            SetNumber(3, YLowIn);
            SetNumber(4, YHighIn);
            SetNumberLimits(1, -20, 20);
            SetNumberLimits(2, -20, 20);
            SetNumberLimits(3, -20, 20);
            SetNumberLimits(4, -20, 20);
            REPEAT
               AcceptScreen;
               XLow := GetNumber(1);
               XHigh := GetNumber(2);
               YLow := GetNumber(3);
               YHigh := GetNumber(4);
               xLowIn := xLow; yLowIn := YLow;
               xHighIn := xHigh; yHighIn := yHigh;
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
               Announce('You confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
         Done;
         END;
         ModelNumber := 1;
         SolutionNumber[1] := 4;
         xSolution[1,1] := 1.3363;
         ySolution[1,1] := 1.7542;
         xSolution[1,2] := -3.0016;
         ySolution[1,2] := 0.1482;
         xSolution[1,3] := 2.9983;
         ySolution[1,3] := 0.1484;
         xSolution[1,4] := -0.9012;
         ySolution[1,4] := -2.0867;
      END;
   2: BEGIN
         WITH NewtonDat DO
         BEGIN
            Init;
            DefineInputPort(0.2, 0.8, 0.1, 0.9);
            LoadLine('             Input Parameters.');
            LoadLine('');
            LoadLine('    This utility solves the two simultaneous');
            LoadLine(' equations:');
            LoadLine('             x^3 - 3x*y^2 = - 1,');
            LoadLine('             3x^2*y - y^3 = 0.');
            LoadLine(' These are equivalent to the complex equation');
            LoadLine('         z^3 = -1, where z = x + iy.');
            LoadLine('');
            LoadLine('   Solutions are close to:');
            LoadLine('   (0.5, 0.866), (-1, 0) and (0.5, -0.866)');
            LoadLine('');
            LoadLine('    Enter values for the extreme coordinates');
            LoadLine(' for the display. (Less than 20 in magnitude.)');
            LoadLine('       XLow = {      }, XHigh = {      }');
            LoadLIne('       YLow = {      }, YHigh = {      }');
            LoadLine('');
            LoadLine('           [  OK  ]        [Cancel] ');
            SetNumber(1, XLowIn);
            SetNumber(2, XHighIn);
            SetNumber(3, YLowIn);
            SetNumber(4, YHighIn);
            SetNumberLimits(1, -20, 20);
            SetNumberLimits(2, -20, 20);
            SetNumberLimits(3, -20, 20);
            SetNumberLimits(4, -20, 20);
            REPEAT
               AcceptScreen;
               XLow := GetNumber(1);
               XHigh := GetNumber(2);
               YLow := GetNumber(3);
               YHigh := GetNumber(4);
               xLowIn := xLow; yLowIn := YLow;
               xHighIn := xHigh; yHighIn := yHigh;
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
               Announce('You confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            Done;
         END;
         ModelNumber := 2;
         SolutionNumber[2] := 3;
         xSolution[2,1] := 0.5;
         ySolution[2,1] := 0.866025;
         xSolution[2,2] := -1;
         ySolution[2,2] := 0.;
         xSolution[2,3] := 0.5;
         ySolution[2,3] := -0.866025;
      END;
      3: BEGIN
         WITH NewtonDat DO
         BEGIN
            Init;
            DefineInputPort(0.08, 0.92, 0.1, 0.9);
            LoadLine('');
            LoadLine('                      Input Parameters.');
            LoadLine('');
            LoadLine('      This utility uses Newton''s method to solve the two ');
            LoadLine('   simultaneous equations:');
            LoadLine('                      F(x,y) = 0 and G(x,y) = 0.');
            LoadLine('   You must enter the functions and also their derivatives');
            LoadLine('   with respect to x and y, FX, Fy, GX and GY.');
            LoadLine('');
            LoadLine('  F(X,Y) = "                                              "');
            LoadLine(' FX(X,Y) = "                                              "');
            LoadLine(' FY(X,Y) = "                                              "');
            LoadLine('  G(X,Y) = "                                              "');
            LoadLine(' GX(X,Y) = "                                              "');
            LoadLine(' GY(X,Y) = "                                              "');
            LoadLine('');
            LoadLine('          [ Help ]        [  OK  ]        [Cancel] ');
            SetHelpFile('HlpChaos.hlp', 'Newton2DDIYInputHelp');
            SetString(1, FStr);
            SetString(2, FXStr);
            SetString(3, FYStr);
            SetString(4, GStr);
            SetString(5, GXStr);
            SetString(6, GYStr);
            FFunc.Init; FXFunc.Init; FYFunc.Init;
            GFunc.Init; GXFunc.Init; GYFunc.Init;
            REPEAT
               AcceptScreen;
               IF NOT Canceled THEN
               BEGIN
                  FOR I := 1 TO 6 DO
                     Str[I] := GetString(I);
                  StrOK[1] := FFunc.Parse('x','y','z','r', Str[1]);
                  StrOK[2] := FXFunc.Parse('x','y','z','r', Str[2]);
                  StrOK[3] := FYFunc.Parse('x','y','z','r', Str[3]);
                  StrOK[4] := GFunc.Parse('x','y','z','r', Str[4]);
                  StrOK[5] := GXFunc.Parse('x','y','z','r', Str[5]);
                  StrOK[6] := GYFunc.Parse('x','y','z','r', Str[6]);
                  InputOK := True;
                  FOR I := 1 TO 6 DO
                  BEGIN
                     IF NOT StrOK[i] THEN
                     BEGIN
                        InputOK := False;
                        Announce('I cannot evaluate function #'
                                   +NumStr(I,1,0)+'. Please try again.')
                     END;
                  END;
               END;
            UNTIL InPutOK OR Canceled;
            IF Canceled THEN InPutOK := False;
         Done;
         END; {WITH NewtonDat}
         ModelNumber := 3;
         IF NOT InputOK THEN Exit;
         WITH NewtonDat DO
         BEGIN
            Init;
            DefineInputPort(0.2, 0.8, 0.2, 0.8);
            LoadLine('');
            LoadLine('     A search for up to 20 solutions will be');
            LoadLine('  made inside a rectangle. Enter the limits:');
            LoadLine('    xLow = {       }   xHigh = {       }');
            LoadLine('    yLow = {       }   yHigh = {       }');
            LoadLine('');
            LoadLine('     The search will use a grid of points ');
            LoadLine('  for starting conditions. Enter the numbers');
            LoadLine('  NX, NY (between 10 and 20) of points in');
            LoadLine('  the x- and y- directions:');
            LoadLine('        NX = {   }          NY = {   }');
            LoadLine('');
            LoadLine('                    [  OK  ]');
            SetNumber(1, xLowIn);
            SetNumber(2, xHighIn);
            SetNumber(3, yLowIn);
            SetNumber(4, yHighIn);
            SetNumber(5, NX);
            SetNumber(6, NY);
            SetNumberLimits(5, 10, 20);
            SetNumberLimits(6, 10, 20);
            REPEAT
               AcceptScreen;
               XLow := GetNumber(1);
               xHigh := GetNumber(2);
               yLow := GetNumber(3);
               yHigh := GetNumber(4);
               IF (xLow >= xHIgh) OR (yLow >= yHigh) THEN
                 Announce('You have confused upper and lower limits. Please try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            xLowIn := xLow;
            xHighIn := xHigh;
            yLowIn := yLow;
            yHighIn := yHigh;
            ModelNumber := 3;
            NX := Trunc(GetNumber(5) + 0.01);
            NY := Trunc(GetNumber(6) + 0.01);
            Done;
         END; {WITH NewtonDat}
      END; {Case 3}
      4: BEGIN
         WITH NewtonDat DO
         BEGIN
            Init;
            DefineInputPort(0.18, 0.81, 0.08, 0.92);
            LoadLine('             Input Parameters.');
            LoadLine('');
            LoadLine('    This utility solves the two simultaneous');
            LoadLine(' equations that are equivalent to the complex');
            LoadLine(' equation');
            LoadLine('   (z^2 - 1)(z^2 + C) = 0, where z = x + iy.');
            LoadLine('');
            LoadLine('    Solutions, for positive C, are:');
            LoadLine('     (1, 0), (-1, 0), (0, D) and (0, -D),');
            LoadLine(' where D^2 = C. Press <Help> for more details.');
            LoadLine('');
            LoadLine('  Enter a value for C: 0 < C = {       } <= 2');
            LoadLine('');
            LoadLine('    Enter values for the extreme coordinates');
            LoadLine(' for the display. (Less than 20 in magnitude.)');
            LoadLine('       XLow = {      }, XHigh = {      }');
            LoadLIne('       YLow = {      }, YHigh = {      }');
            LoadLine('');
            LoadLine('     [ Help ]       [  OK  ]      [Cancel] ');
            SetHelpFile('HlpChaos.hlp', 'Newton2DCase3Help');
            SetNumber(1, C);
            SetNumberLimits(1, 0, 2);
            SetNumber(2, XLowIn);
            SetNumber(3, XHighIn);
            SetNumber(4, YLowIn);
            SetNumber(5, YHighIn);
            SetNumberLimits(5, -20, 20);
            SetNumberLimits(2, -20, 20);
            SetNumberLimits(3, -20, 20);
            SetNumberLimits(4, -20, 20);
            REPEAT
               AcceptScreen;
               C := GetNumber(1);
               XLow := GetNumber(2);
               XHigh := GetNumber(3);
               YLow := GetNumber(4);
               YHigh := GetNumber(5);
               xLowIn := xLow; yLowIn := YLow;
               xHighIn := xHigh; yHighIn := yHigh;
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
               Announce('You confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            Done;
         END;
         ModelNumber := 4;
         SolutionNumber[4] := 4;
         xSolution[4,1] := 1;
         ySolution[4,1] := 0;
         xSolution[4,2] := -1;
         ySolution[4,2] := 0.;
         xSolution[4,3] := 0;
         ySolution[4,3] := Sqrt(C);
         xSolution[4,4] := 0;
         ySolution[4,4] := -Sqrt(C);
      END; {Case 4}
   END; {Case}
END; {Procedure}

{----------------------------------------------------------------------}

PROCEDURE PlotCross(xC, yC: Real);
VAR
   xCrossLength, yCrossLength: Integer;
   xCP, yCP                  : Integer;
BEGIN
   XCrossLength := 10;
   YCrossLength := 10;
   xCP := MapX(xC);
   yCP := MapY(yC);
   Line(xCP - XCrossLength, yCP, xCP + XCrossLength, yCP);
   Line(xCP, yCP - YCrosslength, xCP, yCP + YCrosslength);
END;


{----------------------------------------------------------------------}

PROCEDURE DrawScreen;
VAR
   I                         : Integer;


VAR
   DelX, DelY: Real;
BEGIN
   GraphBackColor := DarkGray;
   SelectScale(1);
   ClearMuppetPort;
   OpenViewPort(1);
   Axis(0, 0, 1, 1);
   PutLabel(Bottom, 'x');
   PutLabel(Left, 'y');
   SetColor(Yellow);
   IF SolutionNumber[ModelNumber] > 0 THEN
      FOR I := 1 TO SolutionNumber[ModelNumber] DO
         PlotCross(xSolution[ModelNumber, I], ySolution[ModelNumber, i]);
END;

{----------------------------------------------------------------------}

PROCEDURE GetFunctionValues(x, y : Real; VAR F, G, FX, FY, GX, GY: Real);
VAR
   z, r      : Real;
BEGIN
   CASE ModelNumber OF
   1: BEGIN
         F := x*x + x*y*y*y - 9;
         G := 3*x*x*y - y*y*y - 4;
         FX := 2*x + y*y*y;
         FY := x*3*y*y;
         GX := 6*x*y;
         GY := 3*x*x - 3*y*y;
      END;
   2: BEGIN
         F := x*x*x - 3*x*y*y + 1;
         G := 3*x*x*y - y*y*y;
         FX := 3*x*x - 3*y*y;
         FY := - 6*x*y;
         GX := 6*x*y;
         GY := 3*x*x - 3*y*y;
      END;
   3: BEGIN
         F := FFunc.F(x, y, z, r);
         FX := FXFunc.F(x, y, z, r);
         FY := FYFunc.F(x, y, z, r);
         G := GFunc.F(x, y, z, r);
         GX := GXFunc.F(x, y, z, r);
         GY := GYFunc.F(x, y, z, r);
      END;
   4: BEGIN
         F := x*x*x*x - 6*x*x*y*y + y*y*y*y + (x*x-y*y)*(C-1) - C;
         FX := 4*x*x*x - 12*x*y*y + 2*x*(C-1);
         FY := -12*x*x*y + 4*y*y*y - 2*y*(C-1);
         G := 4*x*x*x*y - 4*x*y*y*y + 2*x*y*(C-1);
         GX := 12*x*x*y - 4*y*y*y + 2*y*(C-1);
         GY := 4*x*x*x - 12*x*y*y + 2*x*(C-1);
      END;
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE TakeNewtonStep(xIn, yIn, Eps: Real;
                         VAR xOut, yOut: Real; VAR Converged: Boolean);
VAR
   F, G, FX, FY, GX, GY, DelX, DelY: Real;
BEGIN
   OverFlow := False;
   GetFunctionValues(xIn, yIn, F, G, FX, FY, GX, GY);
   IF (FX*GY - GX*FY) = 0 THEN OverFlow := True ELSE
   BEGIN
      DelX := (-F*GY + G*FY)/(FX*GY - GX*FY);
      DelY := (-G*FX + F*GX)/(FX*GY - GX*FY);
      xOut := xIn + DelX;
      yOut := yIn + DelY;
   END;
   IF (Abs(F) + Abs(G) < Eps) OR (Abs(DelX) + ABS(DelY) < Eps) THEN
      Converged := True ELSE Converged := False;
   IF Abs(xOut) + Abs(yOut) > 100000 THEN OverFlow := True;
END;

{----------------------------------------------------------------------}

PROCEDURE SearchForSolutions;
VAR
   I, J, K          : Integer;
   Count            : Integer;
   DelX, DelY       : Real;
   NewSolution      : Boolean;
BEGIN
   ModelNumber := 3;
   SolutionNumber[3] := 0;
   DelX := (xHigh - xLow)/NX;
   DelY := (yHigh - yLow)/NY;
   DefineScale(1, xLow - DelX, xHigh + DelX, yLow - Dely, yHigh + Dely);
   DrawScreen;
   FOR I := 0 TO NX DO
   BEGIN
      xGuess := xLow + I*DelX;
      FOR J := 0 TO NY DO
      BEGIN
         IF SolutionNumber[3] = 20 THEN
         BEGIN
            Announce('I can only use up to 20 solutions');
            Exit;
         END;
         xGuess := xLow + I*DelX;
         yGuess := yLow + J*DelY;
         PlotSymbol(xGuess, yGuess, '.');
         Count := 0;
         REPEAT
            Count := Count + 1;
            TakeNewtonStep(xGuess, yGuess, 0.00001, xGuess, yGuess, Converged);
         UNTIL (Converged) OR (Count > 20) OR OverFlow;
         IF Converged THEN
         BEGIN
            IF SolutionNumber[3] = 0 THEN
            BEGIN
               SolutionNumber[3] := 1;
               xSolution[3, 1] := xGuess;
               ySolution[3, 1] := yGuess;
               PlotCross(xGuess, yGuess);
            END
            ELSE
            BEGIN
               NewSolution := True;
               FOR K := 1 TO SolutionNumber[3] DO
                  IF Abs(xSolution[3, K] - xGuess) +
                     Abs(ySolution[3, K] - yGuess) < 0.01
                  THEN NewSolution := False;
               IF NewSolution THEN
               BEGIN
                  SolutionNumber[3] := SolutionNumber[3] + 1;
                  xSolution[3, SolutionNumber[3]] := xGuess;
                  ySolution[3, SolutionNumber[3]] := yGuess;
                  PlotCross(xGuess, yGuess);
               END;
            END;
         END;
      END; {y loop}
   END; {xloop}
   IF SolutionNumber[3] = 0 THEN
      Announce('No solutions found. You had better check your equations.');
END;

{----------------------------------------------------------------------}

PROCEDURE SolveEquations(xGuess, yGuess: Real;
                         VAR SolutionColor: Word);
VAR
   Count : Integer;
   I     : Integer;
   MaxCount : Integer;
BEGIN
   IF FractalNumber = 1 THEN MaxCount := 20 ELSE MaxCount := 20;
   Count := 0;
   REPEAT
      Count := Count + 1;
      TakeNewtonStep(xGuess, yGuess, 0.001, xGuess, yGuess, Converged);
   UNTIL (Converged) OR (Count > MaxCount);
   SolutionColor := Black;
   IF Count < MaxCount THEN
   BEGIN
      IF FractalNumber = 1 THEN
      BEGIN
         FOR I := 1 TO SolutionNumber[ModelNumber] DO
         IF Abs(xGuess - xSolution[ModelNumber,I]) +
            Abs(yGuess - ySolution[ModelNumber,I]) < 0.01 THEN
                 SolutionColor := Colors[I];
      END
      ELSE SolutionColor := Colors[Count];
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE PlotIterations;
VAR
   xOld, yOld, xNew, yNew: Real;
   Count : Integer;
BEGIN
   Message('                   Hit a key to stop the iterations');
   OverFlow := False;
   SetColor(ColorNumber);
   xOld := xGuess;
   yOld := yGuess;
   PlotSymbol(xOld, yOld, '*');
   Count := 0;
   REPEAT
      Delay(500);
      Count := Count + 1;
      TakeNewtonStep(xOld, yOld, 0.0001, xNew, yNew, Converged);
      IF Abs(xNew) + Abs(yNew) > 10000 THEN
      BEGIN
         OverFlow := True;
         Announce('Overflow! Start again');
      END;
      IF (NOT Converged) OR (NOT OverFlow) THEN
      BEGIN
         PlotLine(xOld, yOld, xNew, yNew);
         PlotSymbol(xNew, yNew, '*');
         Beep;
         xOld := xNew; yOld := yNew;
      END;
   UNTIL (Converged) OR (Count > 20) OR KeyPressed;
   IF Count > 20 THEN Note(880, 1, 10);
   ClearMKBuffers;
   Message('');
END;

{----------------------------------------------------------------------}

PROCEDURE KeyInput;
VAR
   GuessInput: TInputScreen;
   InputOK: Boolean;
   F, G, FX, FY, GX, GY  : Real;
BEGIN
   InputOK := False;
   UseKeys := False;
   WITH GuessInput DO
   BEGIN
      Init;
      DefineInputPort(0.01, 0.25, 0.79, 0.99);
      LoadLine('  Initial guess.');
      LoadLine(' x = {       }');
      LoadLine(' y = {       }');
      LoadLine('[  OK  ] [Cancel]');
      SetNumber(1, xGuess);
      SetNumber(2, yGuess);
      SetNumberLimits(1, xLow, xHigh);
      SetNumberLimits(2, yLow, yHigh);
      REPEAT
         AcceptScreen;
         IF NOT Canceled THEN
         BEGIN
            xGuess := GetNumber(1);
            yGuess := GetNumber(2);
            GetFunctionValues(xGuess, yGuess, F,G, FX, FY, GX, GY);
            IF Abs(FX*GY - FY*GX) > 0.001 THEN InputOK := True;
         END;
      UNTIL InputOK OR Canceled;
      Done;
   END;
   IF InputOK THEN
   BEGIN
      ColorNumber := ColorNumber + 1;
      IF ColorNumber > 14 THEN ColorNumber := 1;
      PlotIterations;
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE MouseInput;
VAR
   Button                        : Word;
   Inside                        : Boolean;
   xm, ym                        : Integer;
   a                             : Integer;
   xSave, ySave                  : Real;
   F, G, FX, GX, FY, GY          : Real;
   D                             : Real;
   SaveColor                     : Word;

BEGIN
   SaveColor := GetColor;
   SetColor(White);
   Message('                 Click on a starting point');
   REPEAT
      MousePosn(xGuess, yGuess, 1, 1, Inside);
      IF Inside AND
      (Abs(xSave - xGuess) + Abs(ySave - yGuess) > 0.01) THEN
      BEGIN
         RubOutXY(0.3, 0.94, 40, Black);
         GetFunctionValues(xGuess, yGuess, F,G, FX, FY, GX, GY);
         D := FX*GY - FY*GX;
         PrintXY(0.3, 0.94, 'x = '+NumStr(xGuess, 4, 2)+
                         ', y = '+NumStr(yGuess, 4, 2)+
                         ', D = '+NumStr(D, 7, 2));
         xSave := xGuess;
         ySave := yGuess;
      END;
      IF NOT Inside THEN RubOutXY(0.3, 0.94, 40, Black);
   UNTIL MouseClicked(a,a) AND Inside;
   ColorNumber := ColorNumber + 1;
   IF ColorNumber > 14 THEN ColorNumber := 1;
   Message('');
   RubOutXY(0.3, 0.94, 40, Black);
   SetColor(SaveColor);
   PlotIterations;
END;

{----------------------------------------------------------------------}

PROCEDURE FollowIterations;
VAR
   DelX, DelY      : Real;
BEGIN
   xLow := xLowIn; yLow := yLowIn;
   xHigh := xHighIn; yHigh := yHighIn;
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   DefineScale(1, xLow - DelX, xHigh + DelX,
                  yLow - DelY, yHigh + DelY);
   DrawScreen;
   SetUpHotKeys;
   LightMenu := False;
   Iterate := True;
   ColorNumber := 1;
END;

{----------------------------------------------------------------------}

PROCEDURE ColorStartingPoints;

VAR

   i, j: Integer;
   SolutionColor: Word;

PROCEDURE XPixelsToCoordinates(xP: Integer; VAR xC: Real);
BEGIN
   xC := xLow + (xHigh - xLow)*(xP - MinxPix)/XPixels;
END;

PROCEDURE YPixelsToCoordinates(yP: Integer; VAR yC: Real);
BEGIN
   yC := yHigh - (yHigh - yLow)*(yP - MinyPix)/YPixels;
END;

BEGIN
   HideMouse;
   XPixelsToCoordinates(MinXPix + XPixelNumber, xGuess);
   FOR j := 1 TO YPixels DO
   BEGIN
      YPixelsToCoordinates(MinYPix + j, yGuess);
      SolveEquations(xGuess, yGuess, SolutionColor);
      PutPixel(MinXPix + XPixelNumber, MinYPix + j, SolutionColor);
   END;
   XPixelNumber := XPixelNumber + 1;
   IF XPixelNumber >= xPixels THEN Plotting := False;
   ShowMouse;
END;

{----------------------------------------------------------------------}

PROCEDURE ShowExtremeCoordinates;
VAR
   xSc, ySc: Integer;
BEGIN
   DefineViewPort(3, 0, 0.1, 0.3, 0.7);
   DefineScale(3, -0.02, 1, 0, 10);
   GraphBackColor := Red;
   OpenViewPort(3);
   SelectScale(3);
   Map(0, 9, xSc, ySc);
   OutTextxy(xSc, ySc, '  XLow');
   Map(0, 8, xSc, ySc);
   OutTextxy(xSc, ySc, NumStr(XLow, 7, 4));
   Map(0, 7, xSc, ySc);
   OutTextxy(xSc, ySc, '  XHigh');
   Map(0, 6, xSc, ySc);
   OutTextxy(xSc, ySc, NumStr(XHigh, 7, 4));
   Map(0, 5, xSc, ySc);
   OutTextxy(xSc, ySc, '  YLow');
   Map(0, 4, xSc, ySc);
   OutTextxy(xSc, ySc, NumStr(YLow, 7, 4));
   Map(0, 3, xSc, ySc);
   OutTextxy(xSc, ySc, '  YHigh');
   Map(0, 2, xSc, ySc);
   OutTextxy(xSc, ySc, NumStr(YHigh, 7, 4));
   SelectViewPort(1);
   SelectScale(1);
END;

{----------------------------------------------------------------------}

PROCEDURE ShowColors;
VAR
   xSc, ySc: Integer;
   I         : Integer;
BEGIN
   DefineViewPort(4, 0.9, 1, 0.1, 0.9);
   DefineScale(4, -0.1, 1, 0, 20);
   GraphBackColor := Black;
   OpenViewPort(4);
   SelectScale(4);
   FOR I := 1 TO 19 DO
   BEGIN
      SetColor(Colors[I]);
      OutTextXY(MapX(0), MapY(20-I), NumStr(I,2,0));
      SetFillStyle(SolidFill, Colors[I]);
      FillEllipse(MapX(0.6), MapY(20-I-0.2), 4, 4);
   END;
   SelectViewPort(1);
   SelectScale(1);
END;

{----------------------------------------------------------------------}

PROCEDURE SetMouseScale;
VAR
   XCoord, YCoord        : Real;
   xm, ym                : Integer;
   Ins                   : Boolean;
   Button                : Integer;
   Clicked               : Boolean;
   Quit                  : Boolean;
   i                     : Integer;
   Save1, Save2          : Real;
   DelX, DelY            : Real;

PROCEDURE MakeRectangle;
BEGIN
   PlotLine(xLow, yLow, xLow, yHigh);
   PlotLine(xLow, yHigh, xHigh, yHigh);
   PlotLine(xHigh, yHigh, xHigh, yLow);
   Plotline(xHigh, yLow, xLow, yLow);
END;

BEGIN
   Message('Click on the lower left corner of the rectangle. Click outside to quit');
   Clicked := False;
   WaitOnMouseClick;
   MousePosn(Save1, Save2, 1, 1, Ins);
   IF NOT Ins THEN BEGIN Quit := True; Exit; END;
   xLow := Save1; yLow := Save2;
   Message('Click on the upper right corner of the rectangle');
   SetColor(White);
   Delay(100);
      SetWriteMode(XORPut);
      REPEAT
         Button := 0;
         MouseGlobalPosn(xm, ym, Button);
         MousePosn(xHigh, yHigh, 1, 1, Ins);
         IF (xHigh <= xLow) OR (yHigh <= yLow) THEN
         BEGIN
            REPEAT
               Beep;
               MousePosn(xHigh, yHigh, 1, 1, Ins);

            UNTIL (xHigh > xLow) AND (yHigh > yLow);
         END;
         MakeRectangle;
         Delay(10);
         MakeRectangle;
      UNTIL (Button <> 0);
      SetWriteMode(CopyPut);
      Message('');
      Plotting := True;
      Zoom := False;
      xPixelNumber := 0;
      DelX := (xHigh - xLow)/20;
      DelY := (yHigh - yLow)/20;
      DefineScale(1, xLow - DelX, xHigh + DelX,
                  yLow - DelY, yHigh + DelY);
      DrawScreen;
      ZoomHotKeys.Display;
      ShowExtremeCoordinates;
      IF FractalNumber = 2 THEN ShowColors;
END;

{----------------------------------------------------------------------}

PROCEDURE SeeFractals;
VAR
   DelX, DelY       : Real;
BEGIN
   Fractals := True;
   Zoom := False;
   Plotting := True;
   XPixelNumber := 0;
   Action := True;
   PLotting := True;
   LightMenu := False;
   xLow := xLowIn; yLow := yLowIn;
   xHigh := xHighIn; yHigh := yHighIn;
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   DefineScale(1, xLow - DelX, xHigh + DelX,
                  yLow - DelY, yHigh + DelY);
   SelectViewPort(1);
   SelectScale(1);
   MinXPix := MapX(xLow);
   MinYPix := MapY(yHigh);
   xPixels := MapX(xHigh) - MinXPix;
   yPixels := MapY(yLow) - MinYPix;
   DrawScreen;
   SetUpZoomHotKeys;
   IF FractalNumber = 2 THEN ShowColors;
END;

{----------------------------------------------------------------------}

PROCEDURE CleanUp;
VAR
   Input          : TInputScreen;
   DelX, DelY     : Real;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.7);
      LoadLine('');
      LoadLine('    Enter values for the extreme coordinates');
      LoadLine(' for the display. (Less than 20 in magnitude.)');
      LoadLine('       XLow = {      }, XHigh = {      }');
      LoadLIne('       YLow = {      }, YHigh = {      }');
      LoadLine('');
      LoadLine('                    [  OK  ]        ');
      SetNumber(1, XLowIn);
      SetNumber(2, XHighIn);
      SetNumber(3, YLowIn);
      SetNumber(4, YHighIn);
      SetNumberLimits(1, -20, 20);
      SetNumberLimits(2, -20, 20);
      SetNumberLimits(3, -20, 20);
      SetNumberLimits(4, -20, 20);
      REPEAT
         AcceptScreen;
         XLow := GetNumber(1);
         XHigh := GetNumber(2);
         YLow := GetNumber(3);
         YHigh := GetNumber(4);
         xLowIn := xLow; yLowIn := YLow;
         xHighIn := xHigh; yHighIn := yHigh;
         IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
               Announce('You confused upper and lower limits. Try again.');
      UNTIL (xLow < xHigh) AND (yLow < yHigh);
      Done;
   END;
   DelX := (xHigh - xLow)/20;
   DelY := (yHigh - yLow)/20;
   DefineScale(1, xLow - DelX, xHigh + DelX, yLow - DelY, yHigh + DelY);
   DrawScreen;
   HotKeys.Display;
END;

{----------------------------------------------------------------------}

PROCEDURE HandleNewtonMenu;
BEGIN
   With NewtonMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpChaos.hlp', 'Newton2DAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HlpChaos.hlp', 'Newton2DModelHelpA');
                  ShowHelp('HlpChaos.hlp', 'Newton2DModelHelpB');
               END;
            2: BEGIN
                  ShowHelp('HlpChaos.hlp', 'Newton2DFractalHelpA');
                  ShowHelp('HlpChaos.hlp', 'Newton2DFractalHelpB');
               END;
            3: BEGIN
                  ShowHelp('HlpChaos.hlp', 'Newton2DComplex1');
                  ShowHelp('HlpChaos.hlp', 'Newton2DComplex2');
               END;
            4: BEGIN
                  ShowHelp('WalkThru.hlp', 'Newton2D1');
                  ShowHelp('WalkThru.hlp', 'Newton2D2');
                  ShowHelp('WalkThru.hlp', 'Newton2D3');
               END;
         END;
      3: BEGIN
            CASE RowChosen OF
               1: ModelNumber := 1;
               2: ModelNumber := 2;
               3: ModelNumber := 4;
               4: ModelNumber := 3;
            END;
            GetNewtonData;
            IF (ModelNumber = 3) AND InputOK THEN SearchForSolutions;
         END;
      4: CASE RowChosen OF
            1: FollowIterations;
            2: BEGIN FractalNumber := 1; SeeFractals; END;
            3: BEGIN FractalNumber := 2; SeeFractals; END;
         END;
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE HandleHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HlpChaos.hlp', 'Newton2DHotkeysHelp');
      2: BEGIN UseKeys := False; MouseInput; END;
      3: BEGIN UseKeys := True; KeyInput; END;
      4: CleanUp;
      5: BEGIN
            Iterate := False;
            LightMenu := True;
            HotKeys.Clear;
         END;
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE HandleZoomHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HlpChaos.hlp', 'Newton2DZoomHotkeysHelp');
      2: BEGIN
            IF Plotting THEN
            BEGIN
               IF Action THEN
               BEGIN
                  Action := False;
                  WITH ZoomHotKeys DO Key[2] := 'F2-Run';
                  ZoomHotKeys.BackColor := Red;
                  ZoomHotKeys.Display;
                  SetColor(Yellow);
               END
               ELSE
               BEGIN
                  Action := True;
                  WITH ZoomHotKeys DO Key[2] := 'F2-Stop';
                  ZoomHotKeys.BackColor := Blue;
                  ZoomHotKeys.Display;
                  SetColor(Yellow);
               END;
            END;
         END;
      3: BEGIN
            IF NOT Action THEN
            BEGIN
               Action := True;
               WITH ZoomHotKeys DO Key[2] := 'F2-Stop';
               ZoomHotKeys.BackColor := Blue;
               ZoomHotKeys.Display;
               SetColor(Yellow);
            END;
            Plotting := False;
            SetMouseScale;
         END;
      4: BEGIN
            Plotting := False;
            Zoom := False;
            Fractals := False;
            LightMenu := True;
            ZoomHotKeys.Clear;
         END;
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE SetUpStartingValues;
VAR i: Integer;
BEGIN
   xLow := -7;
   xHigh := 7;
   yLow := -7;
   yHigh := 7;
   xLowIn := -7;
   xHighIn := 7;
   yLowIn := -7;
   yHighIn := 7;
   xMinDef := -7;
   xMaxDef := 7;
   yMinDef := -7;
   yMaxDef := 7;
   xMinSel := -7;
   xMaxSel := 7;
   yMinSel := -7;
   yMaxSel := 7;
   ModelNumber := 1;
   SolutionNumber[1] := 4;
   xSolution[1,1] := 1.3363;
   ySolution[1,1] := 1.7542;
   xSolution[1,2] := -3.0016;
   ySolution[1,2] := 0.1482;
   xSolution[1,3] := 2.9983;
   ySolution[1,3] := 0.1484;
   xSolution[1,4] := -0.9012;
   ySolution[1,4] := -2.0867;
   SolutionNumber[2] := 3;
   xSolution[2,1] := 0.5;
   ySolution[2,1] := 0.866025;
   xSolution[2,2] := -1;
   ySolution[2,2] := 0;
   xSolution[2,3] := 0.5;
   ySolution[2,3] := -0.866025;
   FStr := 'x^4 - 6*x*x*y*y + y^4';
   FXStr := '4*x^3 - 12*x*y*y';
   FYStr := '-12*x*x*y + 4*y^3';
   GStr := '4*x^3*y - 4*x*y^3 - 1';
   GXStr := '12*x*x*y - 4*y^3';
   GYStr := '4*x^3 - 12*x*y*y';
   DefineViewPort(1, 0.11, 0.89, 0.1, 0.9);
   xGuess := 1;
   yGuess := -2;
   FOR i := 1 TO 7 DO Colors[i] := i;
   FOR i := 8 TO 14 DO Colors[i] := i+1;
   FOR i := 15 TO 20 DO Colors[i] := i-14;
   Hello('HlpChaos.hlp', 'Newton2DAboutProgram');
   SetUpNewtonMenu;
   ExitRequest := False;
   LightMenu := True;
END;

{----------------------------------------------------------------------}

BEGIN
   CUPSInit;
   SetUpStartingValues;
   REPEAT
      CheckForEvents;
      IF Iterate THEN
         IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Fractals AND Plotting AND Action THEN
         ColorStartingPoints;
      IF Fractals THEN
         IF ZoomHotKeys.Pressed(Key) THEN HandleZoomHotKeys(Key);
      IF LightMenu THEN
         IF NewtonMenu.Chosen THEN HandleNewtonMenu;
   UNTIL ExitRequest;
   CUPSDone;
   NewtonMenu.Done;
END.