PROGRAM PredatorPrey;

USES Graph, Crt, CupsMupp, CUPS, CupsGrph, CupsFunc, CupsProc, CupsGui,
     CupsPars;

const
   neq = 2;

type
   vector = array[1..neq] of real;
   PVector = Array[1..3] of Real;

var
   y                             : Vector;
   Time, StepSize                : Real;
   NextTime, Period              : Real;
   PrA, PrB, PrC, PrD, PrE, PrF  : Real;
   PrA0, PrA1, PrFreq            : Real;
   PredPreyMenu                  : TMenu;
   HotKeys                       : THotKeys;
   FHotKeys                      : THotKeys;
   XFunc, YFunc                  : TParser;
   XFStr, YFStr                  : String;
   Key                           : Byte;
   Model                         : Integer;
   Lag                           : Integer;
   Xcol, yRow                    : Integer;
   KeyInitialConditions          : Boolean;
   PlotOrbit, Action             : Boolean;
   Equilibrium                   : Boolean;
   Fishing                       : Boolean;
   Input2OK                      : Boolean;
   Periodic                      : Boolean;
   Poincare                      : Boolean;
   ReStart                       : Boolean;
   XEquil, YEquil                : Real;
   XMax, XMin, YMax, YMin        : Real;
   xStart, yStart                : Real;
   xOld, yOld, xNew, yNew        : Real;
   MaxTime                       : Real;
   UpperLimit                    : Real;
   Pause                         : Boolean;
   ExitRequest                   : Boolean;
   LightMenu                     : Boolean;

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

PROCEDURE SetUpPredPreyMenu;
BEGIN
   With PredPreyMenu DO
   BEGIN
      Init;
       Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Overview');
       row(2,2, 'Volterra');
       row(2,3, 'Volterra with fishing');
       row(2,4, 'Logistic growth for prey');
       row(2,5, 'Logistic growth for predators');
       row(2,6, 'May''s model');
       row(2,7, 'Periodic birth-rate and chaos');
       row(2,8, 'Do it yourself');
       row(2,9, 'Direction fields');
       row(2,10, 'Walk-through');
      Column(3, 'Model');
       row(3,1, 'Volterra');
       row(3,2, 'Volterra with fishing');
       row(3,3, 'Logistic growth for prey');
       row(3,4, 'Logistic growth for predators');
       row(3,5, 'May''s model');
       row(3,6, 'Cyclical growth rate');
       row(3,7, 'Do it yourself');
      Column(4, 'Data');
       row(4,1, 'Enter parameters');
      Column(5, 'Run');
       row(5,1, 'Predator-prey plot');
       row(5,2, 'Time plots');
       row(5,3, 'Three-D plots');
      AutoChecking(1, 1);
      AutoChecking(2, 1);
      AutoChecking(3, 1);
      AutoChecking(4, 1);
      AutoChecking(5, 1);
   END;
   PredPreyMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(9);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Faster';
      Key[4] := 'F4-Slower';
      Key[5] := 'F5-Input';
      Key[6] := 'F6-Dfield';
      Key[7] := 'F7-Cleanup';
      Key[8] := 'F8-Rescale';
      Key[9] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpFHotKeys;
BEGIN
   WITH FHotKeys DO
   BEGIN
      FHotKeys.Init(9);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Faster';
      Key[4] := 'F4-Slower';
      Key[5] := 'F5-Input';
      Key[6] := 'F6-Fish';
      Key[7] := 'F7-Cleanup';
      Key[8] := 'F8-Rescale';
      Key[9] := 'F10-Menu';
   END;
   FHotKeys.BackColor := Blue;
   FHotKeys.HotKeyColor := Yellow;
   FHotKeys.Display;
END;


{-------------------------------------------------------------------------}

PROCEDURE Input1;
CONST
   RBNames : string = '12345678';
VAR
   PredPreyDat         : TInputScreen;
   Delx, Dely          : Real;
BEGIN
   ClearMuppetPort;
   Periodic := False;
   WITH PredPreyDat DO
   BEGIN
      Init;
      DefineInputPort(0.07, 0.93, 0.02, 0.98);
      LoadLine('');
      LoadLine('               The predator-prey model of Volterra');
      LoadLine('');
      LoadLIne('     Volterra''s equations are:');
      LoadLine('');
      LoadLine('         dx/dt = ax - bxy,   dy/dt = -cy + dxy.');
      LoadLine('');
      LoadLine('     Enter values of these parameters. They should be positive,');
      LoadLine('   and less then 10.');
      LoadLine('     a = {      }   b = {      }   c = {      }   d = {      }');
      LoadLIne('');
      LoadLine('     The equilibrium is at x = c/d, y = a/b. Enter values for');
      LoadLine('   the maximum values of x and y for plotting. They must be');
      LoadLine('   positive and less than 100.');
      LoadLine('                 xMax = {     }, yMax = {     }.');
      LoadLine('');
      LoadLine('   Input data from the keyboard #1 or the mouse #1');
      LoadLine('');
      LoadLine('               [ Help ]      [  OK  ]      [Cancel]');
      LoadLine('');
      LoadLine('      If you want periodic change for the birth-rate of the ');
      LoadLine('   prey, then select <Model> <Cyclical growth rate> AFTER ');
      LoadLine('   entering these data.');
      SetHelpFile('HelpPrPr.hlp', 'DataHelp1');
      SetNumber(1, PrA);
      SetNumberLimits(1, 0.000001, 10);
      SetNumber(2, PrB);
      SetNumberLimits(2, 0.000001, 10);
      SetNumber(3, PrC);
      SetNumberLimits(3, 0.000001, 10);
      SetNumber(4, PrD);
      SetNumberLimits(4, 0.000001, 10);
      SetNumber(5, xMax);
      SetNumberLimits(5, 0.000001, 100);
      SetNumber(6, yMax);
      SetNumberLimits(4, 0.000001, 100);
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      PrA := GetNumber(1);
      PrB := GetNumber(2);
      PrC := GetNumber(3);
      PrD := GetNumber(4);
      xMax := GetNumber(5);
      yMax := GetNumber(6);
      xMin := 0;
      yMin := 0;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      XEquil := PrC/PrD;
      YEquil := PrA/PrB;
      Equilibrium := True;
      Delx := 0;
      Dely := 0;
      DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE Input2;
CONST
   RBNames : string = '12345678';
VAR
   PredPreyDat         : TInputScreen;
   Delx, Dely          : Real;
BEGIN
   ClearMuppetPort;
   Periodic := False;
   WITH PredPreyDat DO
   BEGIN
      Init;
      DefineInputPort(0.09, 0.91, 0.02, 0.98);
      LoadLine('');
      LoadLine('       The predator-prey model of Volterra with fishing');
      LoadLine('');
      LoadLIne('     The equations are:');
      LoadLine('     dx/dt = ax - bxy - fx,   dy/dt = -cy + dxy - fy.');
      LoadLine('');
      LoadLine('     Enter values of these parameters. They should lie');
      LoadLine('   between 0.1 and 10, with f between 0 and 10.');
      LoadLine('        a = {      }   b = {      }   c = {      }   ');
      LoadLIne('               d = {      }   f = {      }');
      LoadLine('     The equilibrium is at x = c/d, y = a/b without fishing, ');
      LoadLine('   x = (c+f)/d, y = (a-f)/b with fishing. Enter values for');
      LoadLine('   the maximum values of x and y for plotting. They must be');
      LoadLine('   positive and less than 100.');
      LoadLine('              xMax = {     }, yMax = {     }.');
      LoadLine('');
      LoadLine('   Input data from the keyboard #1 or the mouse #1');
      LoadLine('');
      LoadLine('             [ Help ]      [  OK  ]      [Cancel]');
      LoadLine('');
      LoadLine('      If you want periodic change for the birth-rate of the ');
      LoadLine('   prey, then select <Model> <Cyclical growth rate> AFTER ');
      LoadLine('   entering these data.');
      SetHelpFile('HelpPrPr.hlp', 'DataHelp2');
      SetNumber(1, PrA);
      SetNumberLimits(1, 0.1, 10);
      SetNumber(2, PrB);
      SetNumberLimits(2, 0.1, 10);
      SetNumber(3, PrC);
      SetNumberLimits(3, 0.1, 10);
      SetNumber(4, PrD);
      SetNumberLimits(4, 0.1, 10);
      SetNumber(5, PrF);
      SetNumberLimits(5, 0, 10);
      SetNumber(6, xMax);
      SetNumberLimits(6, 0.000001, 100);
      SetNumber(7, yMax);
      SetNumberLimits(7, 0.000001, 100);
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF Canceled THEN BEGIN Input2OK := False; Exit; END;
      Input2OK := True;
      PrA := GetNumber(1);
      PrB := GetNumber(2);
      PrC := GetNumber(3);
      PrD := GetNumber(4);
      PrF := GetNumber(5);
      xMax := GetNumber(6);
      yMax := GetNumber(7);
      xMin := 0;
      yMin := 0;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      XEquil := PrC/PrD;
      YEquil := PrA/PrB;
      Equilibrium := True;
      Delx := 0;
      Dely := 0;
      DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
      Done;
   END;
   Fishing := False;
END;

{-------------------------------------------------------------------------}

PROCEDURE Input3;
CONST
   RBNames : string = '12345678';
VAR
   PredPreyData       : TInputScreen;
   DelX, DelY         : Real;
BEGIN
   Periodic := False;
   ClearMuppetPort;
   WITH PredPreyData DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.02, 0.98);
      LoadLine('   Predator-prey model with logistic growth for the prey');
      LoadLine('');
      LoadLine('      The equations of the model are');
      LoadLine('         dx/dt = ax - ex^2- bxy,   dy/dt = -cy + dxy.');
      LoadLine('   a, b, c and d should lie between 0.1 and 10. ');
      LoadLine('   e can lie between 0 and 10.');
      LoadLine('   Enter values of these parameters (start with small e):');
      LoadLine('');
      LoadLine('        a = {      }   b = {      }   c = {      }   ');
      LoadLIne('                 d = {      }   e = {      }');
      LoadLIne('');
      LoadLine('     The equilibrium is at x = c/d, y = a/b - (ec)/(bd). ');
      LoadLine('   Enter values for the maximum values of x and y for');
      LoadLine('   plotting. They must lie between 1 and 100.');
      LoadLine('              xMax = {     }, yMax = {     }.');
      LoadLine('');
      LoadLine('         Input from the keyboard #1 or the mouse #1');
      LoadLIne('');
      LoadLIne('          [ Help ]         [  OK  ]         [Cancel]');
      LoadLine('');
      LoadLine('      If you want periodic change for the birth-rate of the ');
      LoadLine('   prey, then select <Model> <Cyclical growth rate> AFTER ');
      LoadLine('   entering these data.');
      SetHelpFile('HelpPrPr.hlp', 'DataHelp3B');
      SetNumber(1, PrA);
      SetNumberLimits(1, 0.000001, 10);
      SetNumber(2, PrB);
      SetNumberLimits(2, 0.000001, 10);
      SetNumber(3, PrC);
      SetNumberLimits(3, 0.000001, 10);
      SetNumber(4, PrD);
      SetNumberLimits(4, 0.000001, 10);
      SetNumber(5, PrE);
      SetNumberLimits(5, 0, 10);
      SetNumber(6, xMax);
      SetNumberLimits(6, 0.000001, 100);
      SetNumber(7, yMax);
      SetNumberLimits(7, 0.000001, 100);
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF Canceled THEN Exit;
      PrA := GetNumber(1);
      PrB := GetNumber(2);
      PrC := GetNumber(3);
      PrD := GetNumber(4);
      PrE := GetNumber(5);
      xMax := GetNumber(6);
      yMax := GetNumber(7);
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      XEquil := PrC/PrD;
      YEquil := (PrA - PrE*XEquil)/PrB;
      IF XEquil >= 0 THEN Equilibrium := True;
      Delx := 0;
      Dely := 0;
      DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE Input4;
CONST
   RBNames : string = '12345678';
VAR
   PredPreyData      : TInputScreen;
   DelX, DelY        : Real;
BEGIN
   Periodic := False;
   ClearMuppetPort;
   WITH PredPreyData DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.02, 0.98);
      LoadLine('');
      LoadLIne('          Predator-prey model with logistic growth');
      LoadLine('                 for both predator and prey');
      LoadLIne('');
      LoadLine('      The equations of the model are:');
      LoadLine('               dx/dt = ax - ex^2 - bxy,');
      LoadLine('               dy/dt = cy(1 - dy/x)');
      LoadLIne('   Enter values of these parameters (start with small e):');
      LoadLine('        a = {      }   b = {      }   c = {      }   ');
      LoadLIne('                d = {      }   e = {      }');
      LoadLIne('');
      LoadLine('   Enter values for the maximum values of x and y for');
      LoadLine('   plotting. They must lie between 1 and 100.');
      LoadLine('              xMax = {     }, yMax = {     }.');
      LoadLine('');
      LoadLine('   Input from the keyboard #1 or the mouse #1');
      LoadLine('');
      LoadLine('           [ Help ]        [  OK  ]       [Cancel]');
      LoadLine('');
      LoadLine('      If you want periodic change for the birth-rate of the ');
      LoadLine('   prey, then select <Model> <Cyclical growth rate> AFTER ');
      LoadLine('   entering these data.');
      SetHelpFile('HelpPrPr.hlp', 'DataHelp4B');
      SetNumber(1, PrA);
      SetNumberLimits(1, 0.1, 10);
      SetNumber(2, PrB);
      SetNumberLimits(2, 0.1, 10);
      SetNumber(3, PrC);
      SetNumberLimits(3, 0.1, 10);
      SetNumber(4, PrD);
      SetNumberLimits(4, 0.1, 10);
      SetNumber(5, PrE);
      SetNumberLimits(5, 0, 10);
      SetNumber(6, xMax);
      SetNumberLimits(6, 1, 100);
      SetNumber(7, yMax);
      SetNumberLimits(7, 1, 100);
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF Canceled THEN Exit;
      PrA := GetNumber(1);
      PrB := GetNumber(2);
      PrC := GetNumber(3);
      PrD := GetNumber(4);
      PrE := GetNumber(5);
      xMax := GetNumber(6);
      yMax := GetNumber(7);
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      XEquil := PrA*PrD/(PrB + PrE*PrD);
      YEquil := PrA/(PrB + PrE*PrD);
      Equilibrium := True;
      Delx := 0;
      Dely := 0;
      DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE Input5;
CONST
   RBNames : string = '12345678';
VAR
   PredPreyData         : TInputScreen;
   DelX, DelY           : Real;
BEGIN
   Periodic := False;
   ClearMuppetPort;
   WITH PredPreyData DO
   BEGIN
      Init;
      DefineInputPort(0.05, 0.85, 0.02, 0.98);
      LoadLine('');
      LoadLine('                May''s predator-prey model');
      LoadLine('');
      LoadLine('      The equations of the model (after scaling) are:');
      LoadLine('              dX/dT = X - AX^2 - BXY/(1+X),');
      LoadLine('              dY/dT = CY(1 - Y/X).');
      LoadLine('   A lies between 0 and 1. B amd C lie between 0.1 and 10.');
      LoadLine('   Starting trial values might be A = 0.1, B = 1, C = 1/6.');
      LoadLine('   Enter values of these parameters:');
      LoadLine('         A = {       }   B = {       }   C = {       }');
      LoadLine('');
      LoadLine('   Enter values for the maximum values of x and y for');
      LoadLine('   plotting. They must lie between 1 and 100.');
      LoadLine('              xMax = {     }, yMax = {     }.');
      LoadLine('');
      LoadLine('   Input from the keyboard #1 or the mouse #1');
      LoadLine('');
      LoadLine('          [ Help ]         [  OK  ]       [Cancel]');
      LoadLine('');
      LoadLine('      If you want periodic change for the birth-rate of the ');
      LoadLine('   prey, then select <Model> <Cyclical growth rate> AFTER ');
      LoadLine('   entering these data.');
      SetHelpFile('HelpPrPr.hlp', 'DataHelp5B');
      SetNumber(1, PrA);
      SetNumberLimits(1, 0, 1);
      SetNumber(2, PrB);
      SetNumberLimits(2, 0.1, 10);
      SetNumber(3, PrC);
      SetNumberLimits(3, 0.1, 10);
      SetNumber(4, xMax);
      SetNumberLimits(4, 1, 100);
      SetNumber(5, yMax);
      SetNumberLimits(5, 1, 100);
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF Canceled THEN Exit;
      PrA := GetNumber(1);
      PrB := GetNumber(2);
      PrC := GetNumber(3);
      xMax := GetNumber(4);
      yMax := GetNumber(5);
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      Delx := 0;
      Dely := 0;
      DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
      Equilibrium := False;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE Input6;
VAR
   PredPreyData         : TInputScreen;
   Quit                 : Boolean;
BEGIN
   Periodic := False;
   ClearMuppetPort;
   REPEAT
      WITH PredPreyData DO
      BEGIN
         Init;
         DefineInputPort(0.1, 0.85, 0.17, 0.83);
         LoadLine('');
         LoadLine('            Periodic birth-rate for the prey');
         LoadLine('');
         LoadLine('      The term for the birth-rate of the prey is AX.');
         LoadLine('   A is usually taken to be a constant. But it could');
         LoadLine('   vary cyclically, in which case we can use the formula');
         LoadLine('                   (A0 + A1*Sin(p*t))X.');
         LoadLine('   Here A0 and A1 are positive constants, with A0 > A1.');
         LoadLine('   p, the frequency, is also a positive constant.');
         LoadLine('   Enter values of these parameters, between 0 and 10:');
         LoadLine('     A0 = {       }  A1 = {       }  p = {       } > 0.1');
         LoadLine('');
         LoadLine('              [  OK  ]           [Cancel]');
         SetNumber(1, PrA0);
         SetNumberLimits(1, 0, 10);
         SetNumber(2, PrA1);
         SetNumberLimits(2, 0, 10);
         SetNumber(3, PrFreq);
         SetNumberLimits(3, 0.1, 10);
         AcceptScreen;
         IF Canceled THEN Quit := True
         ELSE
         BEGIN
            PrA0 := GetNumber(1);
            PrA1 := GetNumber(2);
            PrFreq := GetNumber(3);
            Period := 2*Pi/PrFreq;
            Equilibrium := False;
            Periodic := True;
         END;
         Done;
      END;
      IF PrA0 < PrA1 THEN Announce('A0 > A1. Try again.');
   UNTIL (PrA0 >= PrA1) OR Quit;
END;

{-------------------------------------------------------------------------}

PROCEDURE Input7;
CONST
   RBNames : string = '12345678';
VAR
   PredPreyData   : TInputScreen;
   Delx, Dely     : Real;
   StrOK          : Array[1..2] OF Boolean;
   Str            : Array [1..2] of String;
   i              : Integer;
   t              : Real;
BEGIN
   Periodic := False;
   ClearMuppetPort;
   WITH PredPreyData DO
   BEGIN
      init;
      DefineInputPort (0.04, 0.96, 0.02, 0.98);
      LoadLine('');
      LoadLine('                  Make your own predator-prey model');
      LoadLine('');
      LoadLine('     Enter the functions for the right hand sides of the two');
      LoadLine('  differential equations. x, y and the time, t, are the only');
      LoadLine('  variables allowed. Do not use symbolic parameters.');
      LoadLine('');
      LoadLine('  dx/dt = "                                                         "');
      LoadLine('  dy/dt = "                                                         "');
      LoadLine('');
      LoadLine('     Enter values for the maximum values of x and y for plotting.');
      LoadLine('  They must lie between 1 and 100.');
      LoadLine('                    xMax = {     }, yMax = {     }.');
      LoadLine('');
      LoadLine('     Input from the keyboard #1 or the mouse #1');
      LoadLine('');
      LoadLine('     If you included a periodic function of t, with frequency p, and');
      LoadLine('  want to see Poincare maps, select the option <Cyclical growth rate>');
      LoadLine('  and enter a value for p, the frequency, equal to the one you have');
      LoadLine('  selected.  I.e., for Cos(3*t), p = 3.');
      LoadLine('');
      LoadLine('               [ Help ]        [  Ok  ]        [Cancel]');
      SetHelpFile('HelpPrPr.hlp', 'DataHelp6');
      SetString(1, XFStr);
      SetString(2, YFStr);
      SetNumber(3, xMax);
      SetNumberLimits(3, 1, 100);
      SetNumber(4, yMax);
      SetNumberLimits(4, 1, 100);
      XFunc.Init; YFunc.Init;
      REPEAT
         AcceptScreen;
         IF NOT Canceled THEN
         BEGIN
            for i := 1 to 2 do Str[i] := GetString(i);
            StrOK[1] := xFunc.parse('x','y','t','r', Str[1]);
            if not StrOK[1] then
               announce('Error: Cannot evaluate x function. Please try again.');
            StrOK[2] := yFunc.parse('x','y','t','r', Str[2]);
            if not StrOK[2] then
               announce('Error: Cannot evaluate y function. Please try again.');
         END;
      UNTIL (StrOk[1] AND StrOk[2]) OR Canceled;
      IF NOT Canceled then
      BEGIN
         XFStr := Str[1];
         YFStr := Str[2];
         xMax := GetNumber(3);
         yMax := GetNumber(4);
         IF GetRadioButton(RBNames[1]) = 1 THEN
         KeyInitialConditions := True ELSE KeyInitialConditions := False;
         Delx := 0.1;
         Dely := 0.1;
         DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
         Equilibrium := False;
      END;
      done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE Fun(t: Real; yF: Vector; VAR zF: Vector);
VAR
   x, y, z, r           : Real;
BEGIN
   CASE Model OF
   1: BEGIN
         IF Periodic THEN
            zF[1] := (PrA0 + PrA1*Sin(PrFreq*t))*yF[1] - PrB*yF[1]*yF[2]
            ELSE zF[1] := PrA*yF[1] - PrB*yF[1]*yF[2];
         zF[2] := - PrC*yF[2] + PrD*yF[1]*yF[2];
      END;
   2: BEGIN
         IF Periodic THEN
            zF[1] := (PrA0 + PrA1*Sin(PrFreq*t))*yF[1] - PrB*yF[1]*yF[2]
            ELSE zF[1] := PrA*yF[1] - PrB*yF[1]*yF[2];
         zF[2] := - PrC*yF[2] + PrD*yF[1]*yF[2];
         IF Fishing THEN
         BEGIN
            zF[1] := zF[1] - PrF*yF[1];
            zF[2] := zF[2] - PrF*yF[2];
         END;
      END;
   3: BEGIN
         IF Periodic THEN
            zF[1] := (PrA0 + PrA1*Sin(PrFreq*t))*yF[1]
            ELSE zF[1] := PrA*yF[1];
         zF[1] := zF[1] - PrE*yF[1]*yF[1] - PrB*yF[1]*yF[2];
         zF[2] := - PrC*yF[2] + PrD*yF[1]*yF[2];
      END;
   4: BEGIN
         IF Periodic THEN
            zF[1] := (PrA0 + PrA1*Sin(PrFreq*t))*yF[1]
            ELSE zF[1] := PrA*yF[1];
         zF[1] := zF[1] - PrE*yF[1]*yF[1] - PrB*yF[1]*yF[2];
         zF[2] := PrC*yF[2]*(1 - PrD*yF[2]/yF[1]);
      END;
   5: BEGIN
         IF Periodic THEN
            zF[1] := (PrA0 + PrA1*Sin(PrFreq*t))*yF[1]
            ELSE zF[1] := yF[1];
         zF[1] := zF[1] - PrA*yF[1]*yF[1] -PrB*yF[1]*yF[2]/(1+yF[1]);
         zF[2] := PrC*yF[2]*(1 - yF[2]/yF[1]);
      END;
   6: BEGIN
         zF[1] := XFunc.F(yF[1], yF[2], t, r);
         zF[2] := YFunc.F(yF[1], yF[2], t, r);
      END;
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
   t, ttemp, h, htemp, temax:                   real;
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

   ttemp := xin;
   h := hin;
   Fun(xin, yin, f[1]);
   ytemp := yin;
   repeat {until temax < tol}
      for k := 2 to 6 do
         begin
            t := ttemp + a[k]*h;
            y := ytemp;
            for n := 1 to neq do
               begin
                  for l := 1 to k-1 do
                      y[n] := y[n] + h*b[k,l]*f[l,n];
               end;
            Fun(t, y, f[k]);
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
      IF TeMax = 0 THEN TeMax := Tol/10000;
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := ttemp + htemp;
   hout := h;
end;

{-------------------------------------------------------------------------}

PROCEDURE PrintTime(Time: Real);
VAR
   SaveColor : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(White);
   rubOutXY(0.08,0.11,10,Black);
   printXY(0.08, 0.11,NumStr(Time,6,2));
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE QueryNewPlot;
CONST
   RBNames : string = '12345678';
VAR
   Input  : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
     Init;
     DefineInputPort(0.26, 0.74, 0.35, 0.65);
     LoadLine('');
     LoadLine('     Would you like to start a');
     LoadLine('  new plot?                  #1');
     LoadLine('  or continue the old one?   #1');
     LoadLine('');
     LoadLine('                  [  OK  ]');
     IF Restart THEN SetRadioButton(RBNames[1], 1)
                ELSE SetRadioButton(RBNames[1], 2);
     AcceptScreen;
     IF GetRadioButton(RBNames[1]) = 1 THEN
        Restart := True ELSE Restart := False;
     Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptInitialConditions;
var 
    xSc, ySC         : Integer;
    a                : Integer;
    xSave, ySave     : Real;
    Inside           : Boolean;
    InitialData      : TInputScreen;
BEGIN
   ShowCursor;
   SetColor(GraphBackColor);
   PlotSymbol(y[1], y[2], 'o');
   IF KeyInitialConditions THEN
   BEGIN
      WITH InitialData DO
      BEGIN
         Init;
         DefineInputPort(0.05, 0.95, 0.95, 1);
         LoadLine('Initially, x = {      }   y = {      }   [  OK  ] ');
         SetNumber(1, xStart);
         SetNumberLimits(1, 0, xMax);
         SetNumber(2, yStart);
         SetNumberLimits(2, 0, yMax);
         AcceptScreen;
         xStart := GetNumber(1);
         yStart := GetNumber(2);
         y[1] := xStart;
         y[2] := yStart;
         Done;
      END;
   END
   ELSE
   BEGIN
      GraphBackColor := DarkGray;
      SetColor(Yellow);
      Message('           Click on a starting point');
      REPEAT
         MousePosn(y[1], y[2], 1, 1, Inside);
         IF Inside AND
         (Abs(XSave - (y[1])) + Abs(YSave - (y[2])) > 0.01) THEN
         BEGIN
            RubOutXY(0.4, 0.11, 20, Black);
            PrintXY(0.4, 0.11, '('+NumStr(y[1], 4, 2)+', '+NumStr(y[2], 4, 2)+')');
            XSave := (y[1]);
            YSave := (y[2]);
         END;
      UNTIL MouseClicked(a,a);
   END;
   RubOutXY(0.4, 0.11, 20, Black);
   Message('');
   Action := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE AnimateSolutions;
BEGIN
   StepSize := 0.1;
   xOld := y[1];
   yOld := y[2];
   xNew := y[1];
   yNew := y[2];
   SetColor(Yellow);
   IF NOT Poincare THEN PlotSymbol(xOld, yOld, 'o');
   Time := 0;
   NextTime := Time + Period;
   SetColor(White);
   IF NOT Poincare THEN PrintXY(0.01, 0.11,'Time');
   SetColor(Yellow);
   IF NOT Poincare THEN PrintTime(Time);
   Action := True;
   Pause := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE QueryPoincareMap;
CONST
   RBNames : string = '12345678';
VAR
   Input  : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
     Init;
     DefineInputPort(0.2, 0.8, 0.25, 0.75);
     LoadLine('');
     LoadLine('    The birth-rate of the prey is varying');
     LoadLine('  periodically. You can plot a continuous');
     LoadLine('  curve, or you can see points only when ');
     LoadLine('  the time is equal to an integer multiple');
     LoadLine('  of the period, generating a ''Poincare');
     LoadLine('  map.'' ');
     LoadLine('        See a continuous curve: #1');
     LoadLine('        See a Poincare map:     #1');
     LoadLine('');
     LoadLine('                  [  OK  ]');
     IF Poincare THEN SetRadioButton(RBNames[1], 2)
                 ELSE SetRadioButton(RBNames[1], 1);
     AcceptScreen;
     IF GetRadioButton(RBNames[1]) = 1 THEN
        Poincare := False ELSE Poincare := True;
     Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpScreen;
BEGIN
   LightMenu := False;
   ClearMuppetPort;
   IF Periodic THEN QueryPoincareMap ELSE Poincare := False;
   SelectScale(1);
   GraphBackColor := DarkGray;
   SetColor(Yellow);
   OpenViewPort(1);
   Axis(xMin, yMin, 1, 1);
   OutTextxy(Mapx(0.9*xMax),Mapy(0.05*yMax), 'Prey');
   OutTextxy(Mapx(0.01*xMax), Mapy(0.95*yMax), 'Predator');
   SetColor(White);
   IF Equilibrium THEN PlotSymbol(XEquil, YEquil, 'o');
   IF Model = 2 THEN SetUpFHotKeys ELSE SetUpHotKeys;
   IF ReStart THEN PromptInitialConditions;
   ReStart := True;
   AnimateSolutions;
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveGraph;
VAR
   NoStepSize   : Real;

FUNCTION OutOfBounds : Boolean;
BEGIN
   OutOfBounds := False;
   IF (y[1] <= 0.001) OR (y[2] <= 0.001) OR (y[1] > 2*xMax) OR (y[2] > 2*yMax)
   THEN OutOfBounds := True;
END;

BEGIN
   IF NOT Poincare THEN Delay(Lag);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF OutOfBounds THEN
   BEGIN
      Action := False;
      Announce('I am too far away. Try again, or, maybe, change the scale');
      Pause := True;
      IF Model = 2 THEN
      BEGIN
         WITH FHotKeys DO Key[2] := 'F2-Start';
         FHotKeys.BackColor := Blue;
         FHotKeys.Display;
      END
      ELSE
      BEGIN
         WITH HotKeys DO Key[2] := 'F2-Start';
         HotKeys.BackColor := Blue;
         HotKeys.Display;
      END;
      Exit;
   END;
   IF Poincare THEN
   BEGIN
      IF (Time > NextTime) THEN
         BEGIN
         REPEAT
            Step(Time, NextTime - Time, 0.000001, y, Time, NoStepSize, y);
         UNTIL Abs(Time - NextTime) < 0.001;
         NextTime := Time + Period;
         PutPixel(MapX(y[1]), MapY(y[2]), White);
      END;
   END
   ELSE
   BEGIN
      SetColor(GraphBackColor);
      PlotSymbol(xNew, yNew, 'o');
      IF (Model = 2) AND Fishing THEN SetColor(LightGray) ELSE SetColor(Yellow);
      PlotLine(xOld, yOld, xNew, yNew);
      PlotLine(xNew, yNew, y[1], y[2]);
      xOld := xNew;
      yOld := yNew;
      xNew := y[1];
      yNew := y[2];
      PlotSymbol(xNew, yNew, 'o');
      PrintTime(Time);
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE Rescale;
VAR
   DelX, DelY        : Real;
   RescaleData       : TInputScreen;
BEGIN
   WITH RescaleData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.25, 0.75);
      LoadLine('            Data for rescaling');
      LoadLine('');
      LoadLine('   Enter new maximum values for x and y.');
      LoadLine('   They must lie between 1 and 100');
      LoadLine('           Maximum x: {     }');
      LoadLine('           Maximum y: {     }');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, xMax);
      SetNumber(2, yMax);
      SetNumberLimits(1, 1, 100);
      SetNumberLimits(2, 1, 100);
      AcceptScreen;
      xMax := GetNumber(1);
      yMax := GetNumber(2);
      Delx := 0;
      Dely := 0;
      DefineScale(1, -Delx, xMax + Delx, -Dely, yMax + Dely);
      Done;
   END;
   SetUpScreen;
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
   PlotOrbit := True;
   ShowMouse;
   PromptInitialConditions;
   AnimateSolutions;
END;

{-------------------------------------------------------------------------}

FUNCTION FindStart : Boolean;
VAR
   TimePlotData      : TInputScreen;
BEGIN
   WITH TimePlotData DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.1, 0.9);
      LoadLine('');
      LoadLine('                 Data for time plots');
      LoadLine('');
      LoadLine('     Enter initial values for the predator and prey.');
      LoadLine('  They must be positive and less than 100. Remember');
      LoadLine('  that these numbers can be scaled; the number 1');
      LoadLine('  might represent one thousand units. Input numbers');
      LoadLine('  of around ten, or less, are best.');
      LoadLine('             Predator: {      }');
      LoadLine('                 Prey: {      }');
      LoadLine('     Enter the final value of the time:');
      LoadLine('                       {      }');
      LoadLine('     Sometimes (especially with variable birth-rate)');
      LoadLine('  there may be an overflow in the calculations. To');
      LoadLine('  reduce this possibility, enter an upper limit for');
      LoadLine('  a population:  10 <= {      } <= 1000');
      LoadLine('');
      LoadLine('               [  OK  ]        [Cancel]');
      SetNumber(1, xStart);
      SetNumber(2, yStart);
      SetNumber(3, MaxTime);
      SetNumber(4, UpperLimit);
      SetNumberLimits(1, 0.00001, 100);
      SetNumberLimits(2, 0.00001, 100);
      SetNumberLimits(3, 0.00001, 1000000);
      SetNumberLimits(4, 10, 1000);
      AcceptScreen;
      FindStart := NOT Canceled;
      IF Canceled THEN Exit;
      xStart := GetNumber(1);
      yStart := GetNumber(2);
      MaxTime := GetNumber(3);
      UpperLimit := GetNumber(4);
      Done;
   END;
END;


{-------------------------------------------------------------------------}

PROCEDURE TimePlot;
VAR
   MaxCoord                   : Real;
   yPred, yPrey               : Real;
   OldTime                    : Real;


{-------------------------------------------------------------------------}

PROCEDURE FindScale;
BEGIN
   y[1] := xStart;
   y[2] := yStart;
   Time := 0;
   StepSize := 0.1;
   MaxCoord := 0;
   REPEAT
      Step(Time, StepSize, 0.0001, y, Time, StepSize, y);
      IF y[1] > MaxCoord THEN MaxCoord := y[1];
      IF y[2] > maxCoord THEN MaxCoord := y[2];
   UNTIL (Time > MaxTime) OR (MaxCoord > UpperLimit);
   IF MaxCoord > UpperLimit THEN
   BEGIN
      MaxTime := Time;
      MaxCoord := UpperLimit;
   END;
   DefineScale(3, 0, MaxTime, 0, 1.05*MaxCoord);
END;

BEGIN
   ClearMuppetPort;
   IF NOT FindStart THEN Exit;
   FindScale;
   HideMouse;
   OpenViewPort(3);
   SelectScale(3);
   SetColor(LightBlue);
   PrintXY(0.1, 0.9, 'Predators ____');
   SetColor(Yellow);
   PrintXY(0.1, 0.86, 'Prey ____');
   Axis(0, 0, 1, 1);
   SetColor(White);
   PutLabel(Bottom, 'Time');
   y[1] := xStart;
   y[2] := yStart;
   yPrey := y[1];
   yPred := y[2];
   Time := 0;
   OldTime := 0;
   StepSize := 0.1;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      SetColor(Yellow);
      PlotLine(OldTime, yPrey, Time, y[1]);
      SetColor(LightBlue);
      PlotLine(OldTime, yPred, Time, y[2]);
      OldTime := Time;
      yPrey := y[1];
      yPred := y[2];
   UNTIL Time > MaxTime;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotThreeD;
VAR
   ButtonX, ButtonY, ButtonZ    : TButtons;
   ButtonA                      : TButtons;
   ThreeDHotKeys                : THotKeys;
   OldVector                    : PVector;
   Radius, Azimuth, Altitude    : Real;
   AzimuthDeg, AltitudeDeg      : Real;
   Caz, Saz, Calt, Salt         : Real;
   Check                        : Boolean;
   ExitThreeD                   : Boolean;
   Plotting                     : Boolean;
   xHigh, yHigh, xLow, yLow     : Real;
   MaxX, MaxY, MaxZ             : Real;

{------------------------------------------------------------------------}

PROCEDURE SetUpThreeDHotKeys;
BEGIN
   WITH ThreeDHotKeys DO
   BEGIN
      ThreeDHotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Faster';
      Key[4] := 'F4-Slower';
      Key[5] := 'F5-Input';
      Key[6] := 'F10-Menu';
   END;
   ThreeDHotKeys.BackColor := Red;
   ThreeDHotKeys.HotKeyColor := Yellow;
   ThreeDHotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE View(x, y, z : Real; VAR XView, YView: Real);
BEGIN
   XView := (y*Caz - x*Saz);
   YView := (z*Calt - (x*Caz + y*Saz)*(Salt));
END;

{------------------------------------------------------------------------}

PROCEDURE ViewAndTest(xv, yv, zv: Real);
VAR
   xTest, yTest : Real;
BEGIN
   View(xv, yv, zv, xTest, yTest);
   IF xTest > xHigh THEN xHigh := xTest;
   IF xTest < xLow THEN xLow := xTest;
   IF yTest > yHigh THEN yHigh := yTest;
   IF yTest < yLow THEN yLow := yTest;
END;

{------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   xTest, yTest               : Real;
   Time                       : Real;
   StepSize                   : Real;
BEGIN
   MaxY := 10;
   MaxX := xStart;  {Prey: x = y[1]}
   MaxZ := yStart;  {Predator: y = y[2]}
   Time := 0;
   y[1] := xStart;
   y[2] := yStart;
   StepSize := 0.1;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      IF y[1] > MaxX THEN MaxX := y[1];
      IF y[2] > MaxZ THEN MaxZ := y[2];
   UNTIL Time > MaxTime;
   MaxX := 1.1*MaxX;
   MaxZ := 1.1*MaxZ;
   xHigh := 0;
   yHigh := 0;
   xLow := 0;
   yLow := 0;
   ViewAndTest(0, 0, 0);
   ViewAndTest(MaxX, 0, 0);
   ViewAndTest(0, MaxY, 0);
   ViewAndTest(0, 0, MaxZ);
   ViewAndTest(0, MaxY, MaxZ);
   ViewAndTest(MaxX, 0, MaxZ);
   ViewAndTest(MaxX, MaxY, 0);
   ViewAndTest(MaxX, MaxY, MaxZ);
   xTest := (xHigh - xLow)/10;
   yTest := (yHigh - yLow)/10;
   DefineScale(6, xLow-xTest, xHigh+xTest, yLow-yTest, yHigh+yTest);
END;

{------------------------------------------------------------------------}

PROCEDURE TrigFunctions;
BEGIN
   Calt := Cos(Altitude);
   Salt := Sin(Altitude);
   Caz := Cos(Azimuth);
   Saz := Sin(Azimuth);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpButtons;
BEGIN
   SetColor(LightBlue);
   PrintXY(0.05, 0.8, 'x-t');
   ButtonZ.Create(1, 0.02, 0.75, 'y');
   ButtonZ.Create(2, 0.08, 0.75, 'n');
   ButtonZ.Number := 1;
   SetColor(LightCyan);
   PrintXY(0.05, 0.6, 'y-t');
   ButtonX.Create(1, 0.02, 0.55, 'y');
   ButtonX.Create(2, 0.08, 0.55, 'n');
   ButtonX.Number := 1;
   SetColor(Green);
   PrintXY(0.05, 0.4, 'x-y');
   ButtonY.Create(1, 0.02, 0.35, 'y');
   ButtonY.Create(2, 0.08, 0.35, 'n');
   ButtonY.Number := 1;
   SetColor(Yellow);
   PrintXY(0.03, 0.2, 'x-y-t');
   ButtonA.Create(1, 0.02, 0.15, 'y');
   ButtonA.Create(2, 0.08, 0.15, 'n');
   ButtonA.Number := 1;
   ButtonX.DrawAll;
   ButtonY.DrawAll;
   ButtonZ.DrawAll;
   ButtonA.DrawAll;
END;

{-------------------------------------------------------------------------}

PROCEDURE  DrawArrow(xTail, yTail, xSlope, ySlope, ASize : Real;
                     AStr : String);
VAR
   x, y, xHead, yHead : Real;
   Length             : Real;
BEGIN
   Length := Sqrt(xSlope*xSlope + ySlope*ySlope);
   xSlope := xSlope/Length;
   ySlope := ySlope/Length;
   xHead := xTail + ASize*xSlope;
   yHead := yTail + ASize*ySlope;
   PlotLine(xTail, yTail, xHead, yHead);
   x := xTail + 2*ASize*xSlope;
   y := yTail + 2*ASize*ySlope;
   OutTextXY(MapX(x), MapY(y), AStr);
   ASize := ASize/2;
   x := xHead - ASize*xSlope + ASize*YSlope;
   y := yHead - ASize*ySlope - ASize*XSlope;
   PlotLine(xHead, yHead, x, y);
   x := xHead - ASize*xSlope - ASize*YSlope;
   y := yHead - ASize*ySlope + ASize*XSlope;
   PlotLine(xHead, yHead, x, y);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
  x0, y0, xA, yA, xB, yB, xC, yC   : Real;
  Length                           : Real;
BEGIN
   {ThreeDHotKeys.Display; }
   OpenViewPort(6);
   SelectScale(6);
   SetColor(Yellow);
   View(0, 0, 0, x0, y0);
   View(MaxX, 0, 0, xA, yA);
   View(0, MaxY, 0, xB, yB);
   View(MaxX, MaxY, 0, xC, yC);
   PlotLine(x0, y0, xA, yA);
   DrawArrow(xA, yA, xA-x0, yA-y0, 0.2, 'x');
   PlotLine(x0, y0, xB, yB);
   DrawArrow(xB, yB, xB-x0, yB-y0, 0.2, 't');
   PlotLine(xA, yA, xC, yC);
   PlotLine(xB, yB, xC, yC);
   View(0, 0, MaxZ, xB, yB);
   View(MaxX, 0, MaxZ, xC, yC);
 {  PlotLine(x0, y0, xA, yA);}
   PlotLine(x0, y0, xB, yB);
   DrawArrow(xB, yB, xB-x0, yB-y0, 0.2, 'y');
   PlotLine(xA, yA, xC, yC);
   PlotLine(xB, yB, xC, yC);

   View(0, MaxY, 0, xA, yA);
   View(0, MaxY, MaxZ, xC, yC);
 {  PlotLine(x0, y0, xA, yA);
   PlotLine(x0, y0, xB, yB);}
   PlotLine(xA, yA, xC, yC);
   PlotLine(xB, yB, xC, yC);

   View(MaxX, MaxY, 1.05*MaxZ, x0, y0);
   View(MaxX, MaxY, 0, xC, yC);
   View(MaxX, 0, MaxZ, xB, yB);
   View(0, MaxY, MaxZ, xA, yA);
   PlotLine(x0, y0, xA, yA);
   PlotLine(x0, y0, xB, yB);
   PlotLine(x0, y0, xC, yC);
   IF Equilibrium THEN
   BEGIN
      View(xEquil, 0, yEquil, xA, yA);
      SetColor(Green);
      PlotSymbol(xA, yA, '*');
   END;
   SetColor(Yellow);
   PrintXY(0.18, 0.15, 'x: Prey.     y: Predators.      t: Time.');
   PrintXY(0.16, 0.1, '0 < x < ' + NumStr(MaxX, 3, 1) + '.  ' +
                      ' 0 < y < ' + NumStr(MaxZ, 3, 1) + '.  ' +
                      '   0 < t < ' + NumStr(MaxTime, 3, 0) + '.');
END;

{------------------------------------------------------------------------}

PROCEDURE PlotCurveSections(xP, yP, zP : Real);
VAR
  x1Plot, y1Plot, x2Plot, y2Plot : Real;
BEGIN
   IF ButtonX.Number = 1 THEN
   BEGIN
      SetColor(LightCyan);
      View(0, OldVector[2], OldVector[3], x1Plot, y1Plot);
      View(0, yP, zP, x2Plot, y2Plot);
      PlotLine(x1Plot, y1Plot, x2Plot, y2Plot);
   END;
   IF ButtonY.Number = 1 THEN
   BEGIN
      SetColor(Green);
      View(OldVector[1], 0, OldVector[3], x1Plot, y1Plot);
      View(xP, 0, zP, x2Plot, y2Plot);
      PlotLine(x1Plot, y1Plot, x2Plot, y2Plot);
   END;
   IF ButtonZ.Number = 1 THEN
   BEGIN
      SetColor(LightBlue);
      View(OldVector[1], OldVector[2], 0, x1Plot, y1Plot);
      View(xP, yP, 0, x2Plot, y2Plot);
      PlotLine(x1Plot, y1Plot, x2Plot, y2Plot);
   END;
   IF ButtonA.Number = 1 THEN
   BEGIN
      SetColor(Yellow);
      View(OldVector[1], OldVector[2], OldVector[3], x1Plot, y1Plot);
      View(xP, yP, zP, x2Plot, y2Plot);
      PlotLine(x1Plot, y1Plot, x2Plot, y2Plot);
   END;
   OldVector[1] := xP;
   OldVector[2] := yP;
   OldVector[3] := zP;
END;

{------------------------------------------------------------------------}

PROCEDURE AdvanceCurve;
BEGIN
   Delay(Lag);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   PlotCurveSections(y[1], Time*10/MaxTime, y[2]);
   IF Time > MaxTime THEN Plotting := False;
END;

{------------------------------------------------------------------------}

PROCEDURE Initialize;
BEGIN
   y[1] := xStart;
   y[2] := yStart;
   Time := 0;;
   OldVector[1] := y[1];
   OldVector[2] := Time;
   OldVector[3] := y[2];
   Plotting := True;
   Pause := True;
   StepSize := 0.1;
END;

{------------------------------------------------------------------------}

PROCEDURE SetViewingDirection;
BEGIN
   Altitude := 0.5;
   Azimuth := 0.5;
   TrigFunctions;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleThreeDHotKeys(Key : Byte);
VAR
   DelLag   : Integer;
BEGIN
   DelLag := 10;
   CASE Key OF
         1: ShowHelp('HelpPrPr.hlp', 'HelpThreeD');
         2: BEGIN
               IF Pause THEN
               BEGIN
                  Pause := False;
                  WITH ThreeDHotKeys DO Key[2] := 'F2-Pause';
                  ThreeDHotKeys.BackColor := Blue;
                  ThreeDHotKeys.Display;
               END
               ELSE
               BEGIN
                  Pause := True;
                  WITH ThreeDHotKeys DO Key[2] := 'F2-Start';
                  ThreeDHotKeys.BackColor := Red;
                  ThreeDHotKeys.Display;
               END;
            END;
         3: IF Lag > DelLag THEN Lag := Lag - DelLag;
         4: Lag := Lag + DelLag;
         5: BEGIN
               Pause := True;
               WITH ThreeDHotKeys DO Key[2] := 'F2-Start';
               ThreeDHotKeys.BackColor := Red;
               ThreeDHotKeys.Display;
               IF NOT FindStart THEN Exit;
               FindScale;
               SetUpPicture;
               Initialize;
            END;
         6: BEGIN
               LightMenu := True;
               ClearMuppetPort;
               ExitThreeD := True;
            END;
   END;
END;

{------------------------------------------------------------------------}

BEGIN
   ClearMuppetPort;
   ButtonX.Init;
   ButtonY.Init;
   ButtonZ.Init;
   ButtonA.Init;
   ExitThreeD := False;
   DefineViewPort(6, 0.15, 0.99, 0.06, 0.94);
   SetViewingDirection;
   Lightmenu := False;
   FindScale;
   SetUpButtons;
   SetUpPicture;
   Initialize;
   SetUpThreeDHotKeys;
   Pause := True;
   REPEAT
      CheckForEvents;
      IF ThreeDHotKeys.Pressed(Key) THEN HandleTHreeDHotKeys(Key);
      IF Plotting AND (NOT Pause) THEN AdvanceCurve;
      Check := ButtonX.Changed;
      Check := ButtonY.Changed;
      Check := ButtonZ.Changed;
      Check := ButtonA.Changed;
   UNTIL ExitThreeD;
   ButtonX.Done;
   ButtonY.Done;
   ButtonZ.Done;
   ButtonA.Done;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePredPreyMenu;
BEGIN
   With PredPreyMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpPrPr.hlp', 'AboutPrPrProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpPrPr.hlp', 'PrPrOverview');
            2: ShowHelp('HelpPrPr.hlp', 'DataHelp1');
            3: ShowHelp('HelpPrPr.hlp', 'DataHelp2');
            4: BEGIN
                  ShowHelp('HelpPrPr.hlp', 'DataHelp3A');
                  ShowHelp('HelpPrPr.hlp', 'DataHelp3B');
               END;
            5: BEGIN
                  ShowHelp('HelpPrPr.hlp', 'DataHelp4A');
                  ShowHelp('HelpPrPr.hlp', 'DataHelp4B');
               END;
            6: BEGIN
                  ShowHelp('HelpPrPr.hlp', 'DataHelp5A');
                  ShowHelp('HelpPrPr.hlp', 'DataHelp5B');
                  ShowHelp('HelpPrPr.hlp', 'DataHelp5C');
               END;
            7: BEGIN
                  ShowHelp('HelpPrPr.hlp', 'ChaosA');
                  ShowHelp('HelpPrPr.hlp', 'ChaosB');
                  ShowHelp('HelpPrPr.hlp', 'ChaosC');
               END;
            8: BEGIN
                  ShowHelp('HelpPrPr.hlp', 'DataHelp6A');
                  ShowHelp('HelpPrPr.hlp', 'DataHelp6B');
               END;
            9: ShowHelp('HelpPrPr.hlp', 'DFieldHelp');
            10: BEGIN
                   ShowHelp('WalkThru.hlp', 'PredatorPrey1');
                   ShowHelp('WalkThru.hlp', 'PredatorPrey2');
                   ShowHelp('WalkThru.hlp', 'PredatorPrey3');
                   ShowHelp('WalkThru.hlp', 'PredatorPrey4');
                END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  Model := 1;
                  Input1;
               END;
            2: BEGIN
                  Model := 2;
                  Input2;
                  IF Input2OK THEN SetUpScreen;
               END;
            3: BEGIN
                  Model := 3;
                  Input3;
               END;
            4: BEGIN
                  Model := 4;
                  Input4;
               END;
            5: BEGIN
                  Model := 5;
                  Input5;
               END;
            6: Input6;
            7: BEGIN
                  Model := 6;
                  Input7;
               END;
         END;
      4: CASE Model OF
            1: Input1;
            2: BEGIN
                  Input2;
                  IF Input2OK THEN SetUpScreen;
               END;
            3: Input3;
            4: Input4;
            5: input5;
            6: Input7;
         END;
      5: CASE RowChosen OF
            1: SetUpScreen;
            2: IF Model = 2
               THEN Announce('This utility not available for fishing model')
               ELSE TimePlot;
            3: IF Model = 2 THEN
                  Announce('This utility not available for fishing model')
                  ELSE
                  IF Periodic THEN
                  Announce('This utility not available for changing birth-rate')
                  ELSE PlotThreeD;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 10;
      CASE Key OF
      1: ShowHelp('HelpPrPr.hlp', 'HelpHK1');
      2: BEGIN
            IF Pause THEN
            BEGIN
               Pause := False;
               WITH HotKeys DO Key[2] := 'F2-Pause';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := True;
               WITH HotKeys DO Key[2] := 'F2-Start';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
         END;
      3: IF Lag < DelLag THEN Lag := 0 ELSE Lag := Lag - DelLag;
      4: Lag := Lag + DelLag;
      5: BEGIN
            Action := False;
            PromptInitialConditions;
            Pause := True;
            WITH HotKeys DO Key[2] := 'F2-Start';
            HotKeys.BackColor := Blue;
            HotKeys.Display;
            AnimateSolutions;
         END;
      6: BEGIN
            Action := False;
            Pause := True;
            WITH HotKeys DO Key[2] := 'F2-Start';
            HotKeys.BackColor := Blue;
            HotKeys.Display;
            IF Periodic THEN
               Announce('This utility cannot be used with changing birth-rate')
               ELSE DrawDirectionField;
         END;
      7: BEGIN
            Action := False;
            Pause := True;
            WITH HotKeys DO Key[2] := 'F2-Start';
            HotKeys.BackColor := Blue;
            HotKeys.Display;
            QueryNewPlot;
            SetUpScreen;
         END;
      8: BEGIN
            PlotOrbit := False;
            Action := False;
            Pause := True;
            WITH HotKeys DO Key[2] := 'F2-Start';
            HotKeys.BackColor := Blue;
            HotKeys.Display;
            ReScale;
         END;
      9: BEGIN
            PlotOrbit := False;
            Action := False;
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;
{-------------------------------------------------------------------------}

PROCEDURE HandleFHotKeys(Key: Byte);
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 10;
      CASE Key OF
      1: ShowHelp('HelpPrPr.hlp', 'HelpHK2');
      2: BEGIN
            IF Pause THEN
            BEGIN
               Pause := False;
               WITH FHotKeys DO Key[2] := 'F2-Pause';
               FHotKeys.BackColor := Red;
               FHotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := True;
               WITH FHotKeys DO Key[2] := 'F2-Start';
               FHotKeys.BackColor := Blue;
               FHotKeys.Display;
            END;
         END;
      3: IF Lag < DelLag THEN Lag := 0 ELSE Lag := Lag - DelLag;
      4: Lag := Lag + DelLag;
      5: BEGIN
            Action := False;
            PromptInitialConditions;
            Pause := True;
            WITH FHotKeys DO Key[2] := 'F2-Start';
            FHotKeys.BackColor := Blue;
            FHotKeys.Display;
            Fishing := False;
            AnimateSolutions;
         END;
      6: BEGIN
            Fishing := True;
            SetColor(LightGray);
            IF (PrA > PrF) AND (NOT Periodic) THEN
               PlotSymbol((PrB+PrF)/PrD, (PrA-PrF)/PrC, 'o');
         END;
      7: BEGIN
            Action := False;
            Pause := True;
            WITH FHotKeys DO Key[2] := 'F2-Start';
            FHotKeys.BackColor := Blue;
            FHotKeys.Display;
            Fishing := False;
            SetUpScreen;
         END;
      8: BEGIN
            PlotOrbit := False;
            Action := False;
            Pause := True;
            WITH FHotKeys DO Key[2] := 'F2-Start';
            FHotKeys.BackColor := Blue;
            FHotKeys.Display;
            ReScale;
            Fishing := False;
         END;
      9: BEGIN
            PlotOrbit := False;
            Action := False;
            FHotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;



{-------------------------------------------------------------------------}

PROCEDURE StartUp;
VAR
   xSc, ySc: Integer;
BEGIN
   SelectScale(4);
   GraphBackColor := Red;
   OpenViewPort(5);
   GraphBackColor := Blue;
   SetColor(Yellow);
   HideCursor;
   OpenViewPort(4);
   SetTextStyle(1,HorizDir,4);
   Map(1, 9, xSc, ySc);
   OutTextxy(xSc, ySc, 'PREDATORS');
   Map(3.7, 6, xSc, ySc);
   OutTextxy(xSc, ySc, 'AGAINST');
   Map(7, 3, xSc, ySc);
   OutTextxy(xSc, ySc, 'PREY');
   SetTextStyle(DefaultFont, HorizDir,1);
   GraphBackColor := DarkGray;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetParameters;
BEGIN
   PrA := 1;
   PrB := 1;
   PrC := 1;
   PrD := 1;
   PrF := 0.3;
   PrA0 := 1;
   PrA1 := 0.2;
   PrFreq := 1;
   xEquil := 1;
   yEquil := 1;
   Equilibrium := True;
   xStart := 1;
   yStart := 2;
   xMax := 7;
   yMax := 7;
   xMin := 0;
   yMin := 0;
   xCol := 25;
   yRow := 25;
   MaxTime := 20;
   Model := 1;
   UpperLimit := 100;
   Periodic := False;
   LightMenu := True;
   ReStart := True;
   KeyInitialConditions := False;
   ExitRequest := False;
   DefineViewPort(1, 0.1, 0.93, 0.15, 0.9);
   DefineScale(1, 0, 7, 0, 7);
   DefineViewPort(2, 0.05, 0.95, 0, 0.05);
   DefineViewPort(3, 0.05, 0.95, 0.2, 0.8);
   DefineViewPort(4, 0.1, 0.9, 0.3, 0.7);
   DefineViewPort(5, 0.12, 0.92, 0.32, 0.72);
   DefineScale(4, 0, 10, 0, 10);
   DefineScale(2, 0, 10, 1, 3);
   Lag := 200;
   xFStr := 'x - x^2 - x*y';
   yFStr := 'y - y^2 - 2*x*y';
   Hello('HelpPrPr.hlp', 'AboutPrPrProgram');
   SetUpPredPreyMenu;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   SetParameters;
   StartUp;
   REPEAT
      CheckForEvents;
      IF (Model <> 2) AND HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF (Model = 2) AND FHotKeys.Pressed(Key) THEN HandleFHotKeys(Key);
      IF Action AND (NOT Pause) THEN MoveGraph;
      IF LightMenu AND PredPreyMenu.Chosen THEN HandlePredPreyMenu;
   UNTIL ExitRequest;
   PredPreyMenu.Done;
   CUPSDone;
END.