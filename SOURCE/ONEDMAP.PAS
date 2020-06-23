PROGRAM QuadraticMap;

USES Graph, Crt, CupsMupp, CUPS, CupsGrph, CupsFunc, CupsProc, CupsGui,
     CupsPars;

VAR
   MapMenu                       : TMenu;
   XFunc                         : TParser;
   XFStr                         : String;
   WebHotKeys                    : THotKeys;
   GenHotKeys                    : THotKeys;
   Key                           : Byte;
   QuadraticC                    : Real;
   LogisticC                     : Real;
   CubicC                        : Real;
   SineC                         : Real;
   CosineC                       : Real;
   TentC                         : Real;
   NewtonC                       : Real;
   DIYC                          : Real;
   C                             : Real;
   xLow, yLow, xHigh, yHigh      : Real;
   SxLow, SyLow, SxHigh, SyHigh  : Real;
   y1High, y1Low                 : Real;
   Start                         : Real;
   CStart, CEnd                  : Real;
   FX, FY                        : Real;
   ModelNumber                   : Integer;
   N0, N1                        : Integer;
   IterationNumber               : Integer;
   LightMenu                     : Boolean;
   ExitRequest                   : Boolean;
   Quit                          : Boolean;
   GoForward                     : Boolean;
   MakeWeb                       : Boolean;
   Iterating                     : Boolean;
   SeedChosen                    : Boolean;
   MouseCoordinates              : Boolean;
   GenF                          : Array[0..500] OF Real;

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

{-------------------------------------------------------------------------}

PROCEDURE SetUpMapMenu;
VAR
   I      : Integer;
BEGIN
   With MapMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Quadratic Map');
       row(2,2, 'Logistic Map');
       row(2,3, 'A cubic map');
       row(2,4, 'Sine and Cosine maps');
       row(2,5, 'The tent map');
       row(2,6, 'Newton''s method');
       row(2,7, 'Cobweb diagrams');
       row(2,8, 'Bifurcation diagrams');
       row(2,9, 'Histograms');
       row(2,10, 'Exponential separation');
       row(2,11, 'Walk-through');
      Column(3, 'Model');
       row(3,1, 'Quadratic Map');
       row(3,2, 'Logistic Map');
       row(3,3, 'A Cubic Map');
       row(3,4, 'A Sine Map');
       row(3,5, 'A Cosine Map');
       row(3,6, 'The Tent Map');
       row(3,7, 'Newton''s method');
       row(3,8, 'Do it yourself');
      Column(4, 'Maps');
       row(4,1, 'See cobwebs');
       row(4,2, 'See generating function');
       row(4,3, 'See bifurcation diagram');
       row(4,4, 'See maps');
       row(4,5, '(x(n), x(n+1))');
       row(4,6, 'See histogram');
       row(4,7, 'See exponential separation');
       row(4,8, 'Vary seeds');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   MapMenu.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpModel;
VAR
   Input       : TInputScreen;
   Str         : String;
   StrOK       : Boolean;
   z, r        : Real;
BEGIN
   ClearMuppetPort;
   CASE ModelNumber OF
      1: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.25, 0.75, 0.25, 0.75);
            LoadLine('');
            LoadLine('         The Quadratic Map');
            LoadLine('');
            LoadLine('         x(n+1) = f(x(n)),');
            LoadLine('       where f(x) = x^2 + C.');
            LoadLine('');
            LoadLine(' Enter a value for the parameter C:');
            LoadLine('     -2 <= C = {       } <= 0.25');
            LoadLine('');
            LoadLine('  [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'QuadraticHelp');
            SetNumber(1, QuadraticC);
            SetNumberLimits(1, -2, 0.25);
            AcceptScreen;
            QuadraticC := GetNumber(1);
            C := QuadraticC;
            CStart := -0.5;
            CEnd := -2;
            Y1Low := -2;
            y1High := 2;
            Done;
         END;
      2: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.25, 0.75, 0.25, 0.75);
            LoadLine('');
            LoadLine('         The Logistic Map');
            LoadLine('');
            LoadLine('         x(n+1) = f(x(n)),');
            LoadLine('      where f(x) = Cx(1 - x).');
            LoadLine('');
            LoadLine(' Enter a value for the parameter C:');
            LoadLine('     0 <= C = {       } <= 4');
            LoadLine('');
            LoadLine('  [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'LogisticHelp');
            SetNumber(1, LogisticC);
            SetNumberLimits(1, 0, 4);
            AcceptScreen;
            LogisticC := GetNumber(1);
            C := LogisticC;
            CStart := 2;
            CEnd := 4;
            Y1Low := 0;
            y1High := 1;
            Done;
         END;
      3: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.25, 0.75, 0.25, 0.75);
            LoadLine('');
            LoadLine('           A Cubic Map');
            LoadLine('');
            LoadLine('         x(n+1) = f(x(n)),');
            LoadLine('       where f(x) = Cx + x^3.');
            LoadLine('');
            LoadLine(' Enter a value for the parameter C:');
            LoadLine('     -3 <= C = {       } <= 1');
            LoadLine('');
            LoadLine('  [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'CubicHelp');
            SetNumber(1, CubicC);
            SetNumberLimits(1, -3, 1);
            AcceptScreen;
            CubicC := GetNumber(1);
            C := CubicC;
            CStart := 0;
            CEnd := -3;
            Y1Low := -2;
            y1High := 2;
            Done;
         END;
      4: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.25, 0.75, 0.25, 0.75);
            LoadLine('');
            LoadLine('           A Sine Map');
            LoadLine('');
            LoadLine('         x(n+1) = f(x(n)),');
            LoadLine('      where f(x) = C*Sin(x).');
            LoadLine('');
            LoadLine(' Enter a value for the parameter C:');
            LoadLine('        1 <= C = {       } ');
            LoadLine('');
            LoadLine('  [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'SineCosineHelp');
            SetNumber(1, SineC);
            SetNumberLimits(1, 1, 100000);
            AcceptScreen;
            SineC := GetNumber(1);
            C := SineC;
            CStart := 1;
            CEnd := 6;
            Y1Low := -6;
            Y1High := 6;
            Done;
         END;
      5: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.25, 0.75, 0.25, 0.75);
            LoadLine('');
            LoadLine('          A Cosine Map');
            LoadLine('');
            LoadLine('         x(n+1) = f(x(n)),');
            LoadLine('      where f(x) = C*Cos(x).');
            LoadLine('');
            LoadLine(' Enter a value for the parameter C:');
            LoadLine('        0 < C = {       } ');
            LoadLine('');
            LoadLine('  [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'SineCosineHelp');
            SetNumber(1, CosineC);
            SetNumberLimits(1, 0.5, 100000);
            AcceptScreen;
            CosineC := GetNumber(1);
            C := CosineC;
            CStart := 0;
            CEnd := 6;
            Y1Low := -6;
            y1High := 6;
            Done;
         END;
      6: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.23, 0.77, 0.25, 0.75);
            LoadLine('');
            LoadLine('            The Tent Map');
            LoadLine('');
            LoadLine('          x(n+1) = f(x(n)),');
            LoadLine(' where f(x) = Cx,     if 0 <= x =< 1/2,');
            LoadLine('   and f(x) = C - Cx if 0.5 < x <= 1.');
            LoadLine('');
            LoadLine('  Enter a value for the parameter C:');
            LoadLine('        0 <= C = {       } <= 2');
            LoadLine('');
            LoadLine('   [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'TentHelp');
            SetNumber(1, TentC);
            SetNumberLimits(1, 0, 2);
            AcceptScreen;
            TentC := GetNumber(1);
            C := TentC;
            CStart := 0;
            CEnd := 2;
            Y1Low := 0;
            y1High := 1;
            Done;
         END;
      7: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.23, 0.77, 0.2, 0.8);
            LoadLine('');
            LoadLine('          Newton''s Method');
            LoadLine('');
            LoadLine('      x(n+1) = f(x(n)), where');
            LoadLine(' f(x) = (x^3 - x^2 - C)/(3x^2 -2x),');
            LoadLine(' solves the equation');
            LoadLine('           x^3 - x^2 - C = 0');
            LoadLine(' by Newton''s method.');
            LoadLine('');
            LoadLine('  Enter a value for the parameter C:');
            LoadLine('             C = {       }');
            LoadLine('');
            LoadLine('   [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'NewtonHelp');
            SetNumber(1, NewtonC);
            AcceptScreen;
            NewtonC := GetNumber(1);
            C := NewtonC;
            CStart := -0.5;
            CEnd := 3;
            Y1Low := -2;
            y1High := 5;
            Done;
         END;
         8: WITH Input DO
         BEGIN
            Init;
            DefineInputPort(0.12, 0.88, 0.2, 0.8);
            LoadLine('');
            LoadLine('                    Make Your Own Map');
            LoadLine('');
            LoadLine('     Because of limitations in the parsing procedure,');
            LoadLine('  the symbol ''C'' cannot be used. In place of this, you');
            LoadLine('  should use the symbol ''y.''   ');
            LoadLine('          x(n+1) = f(x(n)), where');
            LoadLine('  f(x,y) = "                                         " ');
            LoadLine('');
            LoadLine('   Enter a value for the parameter C:');
            LoadLine('                          C = {       } ');
            LoadLine('');
            LoadLine('              [ Help ]    [  OK  ]    [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'DIYHelp');
            SetString(1, XFStr);
            SetNumber(2, DIYC);
            XFunc.Init;
            REPEAT
               AcceptScreen;
               IF NOT Canceled THEN
               BEGIN
                  Str := GetString(1);
                  StrOK := xFunc.parse('x','y','z','r', Str);
                  IF NOT StrOK THEN
                  Announce('Error: Cannot evaluate function. Please try again.');
               END;
            UNTIL StrOk OR Canceled;
            IF NOT Canceled then
            BEGIN
               XFStr := GetString(1);
               DIYC := GetNumber(2);
               C := DIYC;
            END;
            Done;
         END;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION Map(x, C : Real) : Real;
VAR
   y, r, z     : Real;
   Denominator : Real;
BEGIN
   CASE ModelNumber OF
      1: Map := x*x + C;
      2: Map := C*x*(1 - x);
      3: Map := C*x + x*x*x;
      4: Map := C*Sin(x);
      5: Map := C*Cos(x);
      6: IF (x >= 0) AND (x <= 1) THEN
         BEGIN
            IF (0 <= x) AND (x <= 0.5)  THEN Map := C*x
                                        ELSE Map := C*(1 - x);
         END ELSE Map := 0;
      7: BEGIN
            Denominator := 3*x*x - 2*x;
            IF Denominator <> 0
               THEN Map := x - (x*x*x - x*x - C)/Denominator
               ELSE Map := 100000*(x*x*x - x*x - C);
         END;
      8: BEGIN
            y := C;
            Map := XFunc.F(x, y, z, r);
         END;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION CInput  : Boolean;
VAR
  Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.3, 0.7, 0.3, 0.6);
      LoadLine('');
      LoadLine('   Enter a value for C:');
      LoadLine('       C = {      }');
      LoadLine('');
      IF ModelNumber = 8 THEN
         LoadLine('   [  OK  ]    [Cancel]')
         ELSE
         LoadLine('[ Help ] [  OK  ] [Cancel]');
      CASE ModelNumber OF
         1: SetNumber(1, QuadraticC);
         2: SetNumber(1, LogisticC);
         3: SetNumber(1, CubicC);
         4: SetNumber(1, SineC);
         5: SetNumber(1, CosineC);
         6: SetNumber(1, TentC);
         7: SetNumber(1, NewtonC);
         8: SetNumber(1, DIYC);
      END;
      CASE ModelNumber OF
         1: SetHelpFile('HlpChaos.hlp', 'QuadraticHelp');
         2: SetHelpFile('HlpChaos.hlp', 'LogisticHelp');
         3: SetHelpFile('HlpChaos.hlp', 'CubicHelp');
         4: SetHelpFile('HlpChaos.hlp', 'SineCosineHelp');
         5: SetHelpFile('HlpChaos.hlp', 'SineCosineHelp');
         6: SetHelpFile('HlpChaos.hlp', 'TentHelp');
         7: SetHelpFile('HlpChaos.hlp', 'NewtonHelp');
      END;
      AcceptScreen;
      CInput := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         CASE ModelNumber OF
            1: BEGIN QuadraticC := GetNumber(1); C := QuadraticC; END;
            2: BEGIN LogisticC := GetNumber(1); C := LogisticC; END;
            3: BEGIN CubicC := GetNumber(1); C := CubicC; END;
            4: BEGIN SineC := GetNumber(1); C := SineC; END;
            5: BEGIN CosineC := GetNumber(1); C := CosineC; END;
            6: BEGIN TentC := GetNumber(1); C := TentC; END;
            7: BEGIN NewtonC := GetNumber(1); C := NewtonC; END;
            8: BEGIN DIYC := GetNumber(1); C := DIYC; END;
         END;
      END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION FindSeed : Real;
VAR
   Input : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.29, 0.71, 0.32, 0.68);
      LoadLine('');
      LoadLine('     Enter the starting value');
      LoadLine('  of the iteration:');
      LoadLine('        x = {       }');
      LoadLine('');
      LoadLine('            [  OK  ]');
      SetNumber(1, Start);
      AcceptScreen;
      Start := GetNumber(1);
      FindSeed := Start;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE ShowMapping;
VAR
   I      : Integer;
   XSave  : Real;
   DelY   : Real;
   X      : Real;
BEGIN
   ShowHelp('HlpChaos.hlp', 'OneDShowMappingHelp');
   IF NOT CInput THEN Exit;
   X := FindSeed;
   xSave := X;
   ClearMuppetPort;
   OpenViewPort(1);
   yLow := 0;
   yHigh := 0;
   FOR i := 1 TO 100 DO
   BEGIN
      X := Map(X, C);
      IF Abs(X) > 1000 THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C. I''m quitting');
            ShowMouse;
            Exit;
         END;
      IF X > yHigh THEN yHigh := X;
      IF X < yLow THEN yLow := X;
   END;
   DelY := (yHigh - yLow)/10;
   DefineScale(2, 0, 0.9*GetMaxX, yLow - DelY, yHigh + DelY);
   SelectScale(2);
   Axis(0, 0, 100, 1);
   PutLabel(Left, 'x(n)');
   PutLabel(Bottom, 'n');
   I := 0;
   X := XSave;
   REPEAT
      X := Map(X, C);
     IF Abs(X) > 1000 THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C. I''m quitting');
            ShowMouse;
            Exit;
         END;
      I := I + 1;
      PutPixel(I, MapY(X), Yellow);
   UNTIL (I > 0.9*GetMaxX);
END;

{-----------------------------------------------------------------------}

PROCEDURE SeeHistogram;
VAR
   I, J   : Integer;
   XSave  : Real;
   DelY   : Real;
   X      : Real;
   YStart : Integer;
   Hist   : Array[0..400] OF Integer;
BEGIN
   ShowHelp('HlpChaos.hlp', 'HistogramHelp');
   IF NOT CInput THEN Exit;
   X := FindSeed;
   xSave := X;
   ClearMuppetPort;
   OpenViewPort(2);
   yLow := 0;
   yHigh := 0;
   FOR i := 1 TO 100 DO
   BEGIN
      X := Map(X, C);
      IF Abs(X) > 1000 THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C. I''m quitting');
            Exit;
         END;
      IF X > yHigh THEN yHigh := X;
      IF X < yLow THEN yLow := X;
   END;
   DelY := (yHigh - yLow)/10;
   DefineScale(2, yLow - DelY, yHigh + DelY, 0, 1);
   SelectScale(2);
   yStart := MapY(0);
   Axis(0, 0, 1, 10000);
   DelY := (yHigh - yLow)/400;
   X := XSave;
   FOR J := 0 TO 400 DO Hist[J] := 0;
   FOR I := 1 TO 10000 DO
   BEGIN
      X := Map(X, C);
      IF Abs(X) > 1000 THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C. I''m quitting');
            ShowMouse;
            Exit;
         END;
      J := Trunc((X - yLow)/DelY);
      Hist[J] := Hist[J] + 1;
      PutPixel(MapX(yLow)+J, YStart - Hist[J], Yellow);
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE SeeExponentialSeparation;
VAR
   N, NPoints           : Integer;
   X1, X2               : Real;
   DelStart             : Real;
   Input                : TInputScreen;
   Separated            : Boolean;
BEGIN
   DelStart := 1.0E-8;
   IF NOT CInput THEN Exit;
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.25, 0.75);
      LoadLine('');
      LoadLine('     Two iterations will be run using');
      LoadLine('  slightly different starting values,');
      LoadLine('  x1 and x2. Enter x1:');
      LoadLine('            x1 = {       }');
      LoadLine('     x2 will be larger than x1 by a ');
      LoadLine('  small amount, Dx.');
      LoadLine('            Dx = {       } >= 1.0E-12');
      LoadLine('');
      LoadLine('     [ Help ]         [  OK  ]');
      SetHelpFile('HlpChaos.hlp', 'ExponentialHelp');
      SetNumber(1, Start);
      SetNumber(2, DelStart);
      SetNumberLimits(2, 1.0E-12, 0.1);
      AcceptScreen;
      Start := GetNumber(1);
      DelStart := GetNumber(2);
      Done
   END;
   x1 := Start;
   x2 := x1 + DelStart;
   N := 0;
   Separated := False;
   REPEAT
      N := N + 1;
      x1 := Map(x1, C);
      x2 := Map(x2, C);
      IF (Abs(X1) > 1000) OR (Abs(x2) > 1000) THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C. I''m quitting');
            ShowMouse;
            Exit;
         END;
      IF (x1 - x2) <> 0 THEN
         IF (Ln(Abs(x1 - x2)) > -1) THEN Separated := True;
   UNTIL Separated OR (N = 500);
   IF N = 500 THEN BEGIN Announce('Solutions do not separate');  Exit; END;
   yLow := Ln(DelStart);
   ClearMuppetPort;
   OpenViewPort(2);
   DefineScale(2, 0, 1.5*N, 1.1*yLow, 1);
   SelectScale(2);
   Axis(0, 0, 100, 1);
   NPoints := Trunc(1.5*N);
   x1 := Start;
   x2 := x1 + DelStart;
   FOR N := 1 TO NPoints DO
   BEGIN
      x1 := Map(x1, C);
      x2 := Map(x2, C);
      IF x1 - x2 <> 0 THEN PlotSymbol(N, (Ln(Abs(x1 - x2))), '.');
   END;
END;

{-----------------------------------------------------------------------}

FUNCTION FindBifurcationLimits : Boolean;
VAR
   Input  : TInputScreen;
   Quit   : Boolean;
BEGIN
   REPEAT
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.2, 0.8, 0.02, 0.98);
         LoadLine('');
         LoadLine('    In a bifurcation diagram values of C,');
         LoadLine('  from CStart to CEnd are taken along the ');
         LoadLine('  horizontal axis. Successive mappings are');
         LoadLine('  along the vertical axis. Enter values:');
         LoadLine('   CStart = {       }  CEnd = {       }');
         LoadLine('     Enter values for the extremes of the');
         LoadLine('  vertical scale:');
         LoadLine('     Lower: {       }  Upper: {       }');
         LoadLine('');
         LoadLine('     To avoid transient effects, N0 initial');
         LoadLine('  mapped points are not recorded. There-');
         LoadLine('  after, N1 mapped points are recorded.');
         LoadLine('  Enter values for N0 and N1, between 0 and');
         LoadLine('  500. Larger values will lead to finer');
         LoadLine('  detail, but will increase the time of');
         LoadLine('  plotting.');
         LoadLine('         N0 = {   }        N1 = {   }');
         LoadLine('');
         LoadLine('  Enter a starting value for x: {      }');
         LoadLine('');
         LoadLine('    [ Help ]      [  OK  ]      [Cancel]');
         SetHelpFile('HlpChaos.hlp', 'OneDMapBifurcationHelp');
         SetNumber(1, CStart);
         SetNumber(2, CEnd);
         SetNumber(3, y1Low);
         SetNumber(4, y1High);
         SetNumber(5, N0);
         SetNumber(6, N1);
         SetNumber(7, Start);
         SetNumberLimits(5, 0, 500);
         SetNumberLimits(6, 0, 500);
         AcceptScreen;
         IF Canceled THEN Quit := True ELSE
         BEGIN
            Quit := False;
            CStart := GetNumber(1);
            CEnd := GetNumber(2);
            y1Low := GetNumber(3);
            y1High := GetNumber(4);
            yLow := y1Low;
            yHigh := y1High;
            N0 := Trunc(GetNumber(5) + 0.1);
            N1 := Trunc(GetNumber(6) + 0.1);
            Start := GetNumber(7);
         END;
         Done;
      END;
      IF CStart = CEND THEN
            Announce('CStart and CEnd cannot be equal. Try again');
      IF yLow >= yHigh THEN
            Announce('You have confused upper and lower limits. Try again.')
   UNTIL (yLow < yHigh) AND (Abs(CStart - CEnd) <> 0) OR Quit;
   FindBifurcationLimits := NOT Quit;
END;

{-----------------------------------------------------------------------}

PROCEDURE SelectLimits;
VAR
   XCoord, YCoord: Real;
   xm, ym: Integer;
   Ins: Boolean;
   Button    : Integer;
   Clicked   : Boolean;
   PositionOK: Boolean;
   xSc, ySc: Integer;
   i       : Integer;
   xOld, yOld, xNew, yNew: Real;
   ROld                  : Real;
   MaxRad                : Real;
   Save1, Save2          : Real;

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
   SetColor(Whitte);
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
END;

{-----------------------------------------------------------------------}

PROCEDURE Bifurcate;
VAR
   NPoints, I, J                 : Integer;
   JMax                          : Integer;
   X                             : Real;
   xStart                        : Real;
   DelC                          : Real;
BEGIN
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   HideMouse;
   Message('     If it gets too boring, hit a key to stop');
   PrintXY(0.2, 0.93, NumStr(xLow,7,4)+' < x < '+NumStr(xHigh,7,4)+',  '
                     +NumStr(yLow,7,4)+' < y < '+NumStr(yHigh,7,4));
   Axis(0, 0, 1, 1);
   NPoints := MapX(xHigh) - MapX(xLow);
   DelC := (xHigh - xLow)/NPoints;
   IF GoForward THEN xStart := xLow
                ELSE BEGIN xStart := xHigh; DelC := - DelC; END;
   I := 0;
   REPEAT
      i := I + 1;
      C := xStart + I*DelC;
      X := Start;
      JMax := N0 + N1;
      FOR J := 1 TO JMax DO
      BEGIN
         X := Map(X, C);
         IF Abs(X) > 100000 THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C range. I''m quitting');
            ShowMouse;
            Exit;
         END;
         IF (J > N0) AND (X < yHigh) AND (x > yLow) THEN PutPixel(MapX(C), MapY(X), Yellow);
      END;
   UNTIL (I = NPoints) OR KeyPressed;
   ClearMKBuffers;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE Bifurcation;
BEGIN
   IF NOT FindBifurcationLimits THEN Exit;
   SxLow := xLow; SxHigh := xHigh; SyLow := yLow; SyHigh := yHigh;
   IF CStart < CEnd THEN
   BEGIN
      GoForward := True;
      xLow := CStart;
      xHigh := CEnd;
   END
   ELSE
   BEGIN
      GoForward := False;
      xLow := CEnd;
      xHigh := CStart;
   END;
   Quit := False;
   REPEAT
      Bifurcate;
      SelectLimits;
   UNTIL Quit;
   xLow := SxLow; xHigh := SxHigh; yLow := SyLow; yHigh := SyHigh;
END;

{-------------------------------------------------------------------------}

PROCEDURE ShowReturnMap;
VAR
   I      : Integer;
   XSave  : Real;
   DelY   : Real;
   X      : Real;
   XOld   : Real;
BEGIN
   IF NOT CInput THEN Exit;
   X := FindSeed;
   xSave := X;
   ClearMuppetPort;
   OpenViewPort(1);
   Message('   Hit a key to stop');
   yLow := 0;
   yHigh := 0;
   FOR i := 1 TO 100 DO
   BEGIN
      X := Map(X, C);
      IF X > yHigh THEN yHigh := X;
      IF X < yLow THEN yLow := X;
   END;
   DelY := (yHigh - yLow)/10;
   DefineScale(2, yLow - DelY, yHigh + DelY, yLow - DelY, yHigh + DelY);
   SelectScale(2);
   Axis(0, 0, 1, 1);
   PutLabel(Left, 'x(n+1)');
   PutLabel(Bottom, 'x(n)');
   X := XSave;
   xOld := X;
   REPEAT
      X := Map(XOld, C);
      PutPixel(MapX(xOld), MapY(X), Yellow);
      xOld := X;
   UNTIL KeyPressed;
   ClearMKBuffers;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpGenHotKeys;
BEGIN
   WITH GenHotKeys DO
   BEGIN
      GenHotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Next';
      Key[3] := 'F3-ReScale';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F10-Menu';
      Display;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE ShowNextCurve;
VAR
   I            : Integer;
BEGIN
   HideMouse;
   FOR I := 0 TO 500 DO
   BEGIN
      GenF[I] := Map(GenF[i], C);
      IF Abs(GenF[I]) > 100000 THEN
      BEGIN
         Announce('Overflow. I''m quitting');
         ShowMouse;
         Exit;
      END;
      IF I > 0 THEN PlotLine(xLow + (I-1)*0.01, GenF[I-1],
                             xLow + I*0.01, GenF[I]);
   END;
   ShowMouse;
   IterationNumber := IterationNumber + 1;
   Message('      Iteration number '+NumStr(IterationNumber, 2, 0));
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   Input   : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.22, 0.78, 0.35, 0.65);
      LoadLine('');
      LoadLine('     Enter extreme values for the plot.');
      LoadLine('  (The x- and y- ranges are the same.)');
      LoadLine('    Lower: {       }   Upper: {       }');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, xLow);
      SetNumber(2, xHigh);
      REPEAT
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         IF xLow >= xHigh THEN
                Announce('You have confused upper and lower limits. Try again.');
      UNTIL xLow < xHigh;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawScreen;
VAR
   Delx      : Real;
   I         : Integer;
BEGIN
   FindScale;
   Delx := (xHigh - xLow)/20;
   DefineScale(4, xLow - Delx, xHigh + Delx, xLow - Delx, xHigh + Delx);
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(4);
   Axis(0, 0, 1, 1);
   HideMouse;
   FOR I := 0 TO 500 DO GenF[I] := xLow + 0.01*I;
   FOR I := 1 TO 500 DO PlotLine(xLow + (I-1)*0.01, GenF[I-1],
                                 xLow + I*0.01, GenF[I]);
   ShowMouse;
   IterationNumber := 0;
   Message('Warning! Too many iterations may cause overflow.');
   GenHotKeys.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleGenHotKeys(Key  : Byte);
BEGIN
   CASE Key OF
   1: ShowHelp('HlpChaos.hlp', 'GenHotKeysHelp');
   2: ShowNextCurve;
   3: DrawScreen;
   4: BEGIN
         OpenViewPort(1);
         Axis(0, 0, 1, 1);
         PlotLine(xLow, xLow, xHigh, xHigh);
      END;
   5: BEGIN
         Iterating := False;
         LightMenu := True;
         ShowMouse;
         GenHotKeys.Clear;
      END;
   END;
END;

{-------------------------------------------------------------------------}


PROCEDURE IterateGeneratingFunction;
BEGIN
   LightMenu := False;
   Iterating := True;
   DrawScreen;
   SetUpGenHotKeys;
   {REPEAT
      CheckForEvents;
      IF GenHotKeys.Pressed(Key) THEN HandleGenHotKeys(Key);
   UNTIL NOT Iterating;
   LightMenu := True;
   ShowMouse;
   GenHotKeys.Clear;}
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpWebHotKeys;
BEGIN
   WITH WebHotKeys DO
   BEGIN
      WebHotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Seed';
      Key[3] := 'F3-Next';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F5-NewC';
      Key[6] := 'F10-Menu';
      Display;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE NextIteration;
BEGIN
   PlotLine(Fx, Fy, Fy, Fy);
   Fx := Fy;
   Fy := Map(Fy, C);
   PlotLine(Fx, Fx, Fx, Fy);
END;

{-------------------------------------------------------------------------}

PROCEDURE NewSeed;
VAR
   SeedInput        : TInputScreen;
BEGIN
   WITH SeedInput DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.35, 0.6);
      LoadLine('');
      LoadLine(' Enter a starting value for the iteration:');
      LoadLine('         '+NumStr(xLow, 3, 1)+' <= {        } <= '+
                           NumStr(xHigh, 3, 1));
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, Start);
      SetNumberLimits(1, xLow, xHigh);
      AcceptScreen;
      Start := GetNumber(1);
      Done;
   END;
   Fx := Start;
   Fy := Map(Fx, C);
   PlotSymbol(Fx, Fy, '*');
   SeedChosen := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawScreen2;
VAR
   I               : Integer;
   x1, y1, x2, y2  : Real;
   Delx            : Real;
   Input           : TInputScreen;
BEGIN
   REPEAT
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.25, 0.75, 0.35, 0.65);
         LoadLine('');
         LoadLine('   Enter values of limits for x:');
         LoadLine('        Minimum: {       }');
         LoadLine('        Maximum: {       }');
         LoadLine('');
         LoadLine('             [  OK  ]  ');
         SetNumber(1, xLow);
         SetNumber(2, xHigh);
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         Done;
      END;
      IF xLow >= xHigh THEN Announce('Maximum and minimum values are confused');
   UNTIL xLow < xHigh;
   HideMouse;
   ClearMuppetPort;
   OpenViewPort(1);
   DefineScale(4, 1.1*xLow, 1.1*xHigh, 1.1*xLow, 1.1*xHigh);
   SelectScale(4);
   Axis(0, 0, 1, 1);
   SetColor(Yellow);
   PlotLine(xLow, xLow, xHigh, xHigh);
   x1 := xLow;
   y1 := Map(x1, C);
   Delx := (xHigh - xLow)/400;
   FOR I := 1 TO 400 DO
   BEGIN
      x2 := x1 + Delx;
      y2 := Map(x2, C);
      PlotLine(x1, y1, x2, y2);
      x1 := x2;
      y1 := y2;
   END;
   SetColor(White);
   WebHotKeys.Display;
   SeedChosen := False;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleWebHotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HlpChaos.hlp', 'WebHotKeysHelp');
      2: NewSeed;
      3: IF SeedChosen THEN NextIteration
                       ELSE Announce('Please choose a seed');
      4: DrawScreen2;
      5: IF CInput THEN
         BEGIN
            DrawScreen2;
         END;
      6: BEGIN
            MakeWeb := False;
            WebHotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GenerateWebs;
BEGIN
   LightMenu := False;
   MakeWeb := True;
   DrawScreen2;
   SetUpWebHotKeys;
END;

{-----------------------------------------------------------------------}

PROCEDURE PlotVariedSeeds;
VAR
   NPoints, I, J                 : Integer;
   JMax                          : Integer;
   X                             : Real;
   xStart                        : Real;
   DelX                          : Real;
BEGIN
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   Message('     If it gets too boring, hit a key to stop');
   Axis(0, 0, 1, 1);
   PrintXY(0.2, 0.93, NumStr(xLow,7,4)+' < x < '+NumStr(xHigh,7,4)+',  '
                     +NumStr(yLow,7,4)+' < y < '+NumStr(yHigh,7,4));
   NPoints := MapX(xHigh) - MapX(xLow);
   DelX := (xHigh - xLow)/NPoints;
   HideMouse;
   I := 0;
   REPEAT
      i := I + 1;
      XStart := xLow + I*DelX;
      X := xStart;
      JMax := N0 + N1;
      FOR J := 1 TO JMax DO
      BEGIN
         X := Map(X, C);
         IF Abs(X) > 100000 THEN
         BEGIN
            Announce('Overflow problems. Maybe bad C range. I''m quitting');
            ShowMouse;
            Exit;
         END;
         IF (J > N0) AND (X < yHigh) AND (x > yLow)
                  THEN PutPixel(MapX(XStart), MapY(X), Yellow);
      END;
   UNTIL (I = NPoints) OR KeyPressed;
   ShowMouse;
   ClearMKBuffers;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindLimits;
VAR
   Input : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.21, 0.79, 0.15, 0.85);
      LoadLine('');
      LoadLine('     Enter limits for the display:');
      LoadLine('     Horizontal:');
      LoadLine('  Lower: {       }  Upper: {       }');
      LoadLine('     Vertical:');
      LoadLine('  Lower: {       }  Upper: {       }');
      LoadLine('');
      LoadLine('     N0 initial mapped points will not');
      LoadLine('  be recorded. Thereafter, N1 mapped');
      LoadLine('  points will be recorded.');
      LoadLine('  Enter values for N0 and N1, between ');
      LoadLine('  0 and 500:');
      LoadLine('        N0 = {   }     N1 = {   }');
      LoadLine('');
      LoadLine('               [  OK  ]');
      SetNumber(1, xLow);
      SetNumber(2, xHigh);
      SetNumber(3, yLow);
      SetNumber(4, yHigh);
      SetNumber(5, N0);
      SetNumber(6, N1);
      SetNumberLimits(5, 0, 500);
      SetNumberLimits(6, 0, 500);
      REPEAT
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         yLow := GetNumber(3);
         yHigh := GetNumber(4);
         N0 := Trunc(GetNumber(5) + 0.1);
         N1 := Trunc(GetNumber(6) + 0.1);
         IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
            Announce('You have confused upper and lower limits. Try again');
      UNTIL (xLow < xHigh) AND (yLow < yHigh);
      Done;
   END;
END;
{-------------------------------------------------------------------------}

PROCEDURE VarySeeds;
BEGIN
   ShowHelp('HlpChaos.hlp', 'OneDHelpVarySeeds');
   FindLimits;
   SxLow := xLow; SxHigh := xHigh; SyLow := yLow; SyHigh := yHigh;
   IF NOT CInput THEN Exit;
   Quit := False;
   REPEAT
      PlotVariedSeeds;
      SelectLimits;
   UNTIL Quit;
   xLow := SxLow; xHigh := SxHigh; yLow := SyLow; yHigh := SyHigh;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleMapMenu;
BEGIN
   With MapMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpChaos.hlp', 'OneDHelpAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpChaos.hlp', 'QuadraticHelp');
            2: ShowHelp('HlpChaos.hlp', 'LogisticHelp');
            3: ShowHelp('HlpChaos.hlp', 'CubicHelp');
            4: ShowHelp('HlpChaos.hlp', 'SineCosineHelp');
            5: ShowHelp('HlpChaos.hlp', 'TentHelp');
            6: BEGIN
                  ShowHelp('HlpChaos.hlp', 'NewtonHelpA');
                  ShowHelp('HlpChaos.hlp', 'NewtonHelpB');
               END;
            7: ShowHelp('HlpChaos.hlp', 'CobwebHelp');
            8: BEGIN
                  ShowHelp('HlpChaos.hlp', 'BifurcationHelpA');
                  ShowHelp('HlpChaos.hlp', 'BifurcationHelpB');
                  ShowHelp('HlpChaos.hlp', 'BifurcationHelpC');
               END;
            9: ShowHelp('HlpChaos.hlp', 'HistogramHelp');
            10: ShowHelp('HlpChaos.hlp', 'ExponentialHelp');
            11: BEGIN
                   ShowHelp('WalkThru.hlp', 'OneDMap1');
                   ShowHelp('WalkThru.hlp', 'OneDMap2');
                   ShowHelp('WalkThru.hlp', 'OneDMap3');
                   ShowHelp('WalkThru.hlp', 'OneDMap4');
                   ShowHelp('WalkThru.hlp', 'OneDMap5');
                   ShowHelp('WalkThru.hlp', 'OneDMap6');
                   ShowHelp('WalkThru.hlp', 'OneDMap7');
                   ShowHelp('WalkThru.hlp', 'OneDMap8');
                END;
         END;
      3: CASE RowChosen OF
            1: BEGIN ModelNumber := 1; SetUpModel; END;
            2: BEGIN ModelNumber := 2; SetUpModel; END;
            3: BEGIN ModelNumber := 3; SetUpModel; END;
            4: BEGIN ModelNumber := 4; SetUpModel; END;
            5: BEGIN ModelNumber := 5; SetUpModel; END;
            6: BEGIN ModelNumber := 6; SetUpModel; END;
            7: BEGIN ModelNumber := 7; SetUpModel; END;
            8: BEGIN ModelNumber := 8; SetUpModel; END;
         END;
      4: CASE RowChosen OF
            1: GenerateWebs;
            2: IterateGeneratingFunction;
            3: Bifurcation;
            4: ShowMapping;
            5: ShowReturnMap;
            6: SeeHistogram;
            7: SeeExponentialSeparation;
            8: VarySeeds;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.1, 0.9, 0.1, 0.9);
   DefineViewPort(2, 0.05, 0.95, 0.07, 0.93);
   DefineScale(2, 0, 0.9*GetMaxX, -2, 2);
   XFStr := 'x*Exp(y - y*x)';
   C := -2;
   xLow := -2;
   yLow := -2;
   xHigh := 2;
   yHigh := 2;
   y1Low := -2;
   y1High := 2;
   Start := 0.5;
   CStart := -0.5;
   CEnd := -2;
   N0 := 50;
   N1 := 50;
   ModelNumber := 1;
   Hello('HlpChaos.hlp', 'OneDHelpAboutProgram');
   SetUpMapMenu;
   LightMenu := True;
   ExitRequest := False;
END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF MakeWeb AND WebHotKeys.Pressed(Key) THEN HandleWebHotKeys(Key);
      IF Iterating AND GenHotKeys.Pressed(Key) THEN HandleGenHotKeys(Key);
      IF LightMenu AND MapMenu.Chosen THEN HandleMapMenu;
   UNTIL ExitRequest;
   MapMenu.Done;
   CUPSDone;
END.