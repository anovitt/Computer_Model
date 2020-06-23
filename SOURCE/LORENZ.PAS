PROGRAM Lorenz;

USES Graph, Crt, CupsMupp, CUPS, CupsGrph, CupsFunc, CupsProc, CupsGui,
     CupsPars;

CONST
   neq = 3;

TYPE
   vector = array[1..3] of real;

VAR
   DMenu                  : TMenu;
   Sliders                : TSliders;
   ThreeDHotKeys          : THotKeys;
   ChangeRHotKeys         : THotKeys;
   XFunc, YFunc, ZFunc    : TParser;
   XFStr, YFStr, ZFStr    : String;
   DelR                   : Real;
   Key                    : Byte;
   y                      : Vector;
   StepSize               : Real;
   Time                   : Real;
   LS, LR, LB             : Real;
   RA, RB, RC             : Real;
   DR, DN, DS             : Real;
   xOld, yOld             : Real;
   xtAxes, ytAxes, ztAxes : Boolean;
   xyAxes, yzAxes, xzAxes : Boolean;
   IDisplay               : Integer;
   xStart, yStart, zStart : Real;
   xMin, xMax             : Real;
   yMin, yMax             : Real;
   zMin, zMax             : Real;
   tMin, tMax             : Real;
   rMin, rMax             : Real;
   DistMin                : Real;
   rNum                   : Integer;
   Theta, Phi             : Real;
   ThetaDeg, PhiDeg       : Real;
   r                      : Real;
   ProjMatrix             : ARRAY[1..2, 1..3] OF Real;
   LimitsFound            : Boolean;
   ExitRequest            : Boolean;
   ThreeDim               : Boolean;
   LightMenu              : Boolean;
   ChangeR                : Boolean;
   Action                 : Boolean;
   Peaks                  : Array[1..500] OF Real;
   PeaksNum               : Integer;
   ModelNumber            : Integer;
   LorenzNumber           : Integer;

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
   SetLineStyle(solidLn, 0,NormWidth);
   ClearMuppetPort;
   envir.Reset;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpDMenu;
VAR
   I     : Integer;
BEGIN
   With DMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Lorenz''s equations');
       row(2,2, 'Rossler''s equations');
       row(2,3, 'Dynamo model');
       row(2,4, 'Lorenz maps');
       row(2,5, 'Walk-through');
      Column(3, 'Model');
       row(3,1, 'Lorenz');
       row(3,2, 'Rossler');
       row(3,3, 'Dynamo');
       row(3,4, 'Do it yourself');
      Column(4, 'Run');
       row(4,1, 'Viewing parameters');
       row(4,2, 'Initial conditions');
       row(4,3, 'Plot the solution');
       row(4,4, 'Plot Lorenz map');
       row(4,5, 'See solution in three dimensions');
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
   DMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE GetParameters;
VAR
   ParInput       : TInputScreen;
   StrOK          : Array[1..3] OF Boolean;
   Str            : Array [1..3] of String;
   i              : Integer;
BEGIN
   CASE ModelNumber OF
   1: BEGIN
         WITH ParInput DO
         BEGIN
            Init;
            DefineInputPort(0.26, 0.74, 0.2, 0.82);
            LoadLine('');
            LoadLine('      The Lorenz Equations');
            LoadLine('');
            LoadLine(' The equations of the model are:');
            LoadLine('        x'' = - s*x + s*y,');
            LoadLine('        y'' = r*x - y - x*z,');
            LoadLine('        z'' = x*y - b*z.');
            LoadLine(' Enter values for the paramters;');
            LoadLine(' these must all be positive.');
            LoadLine('   0 <= s = {        } <= 1000');
            LoadLine('   0 <= r = {        } <= 1000');
            LoadLine('   0 <= b = {        } <= 1000');
            LoadLine('');
            LoadLine('      [ Help ]     [  OK  ]   ');
            SetHelpFile('HlpChaos.hlp', 'LorenzEquations');
            SetNumber(1, LS);
            SetNumber(2, LR);
            SetNumber(3, LB);
            SetNumberlimits(1, 0, 1000);
            SetNumberlimits(2, 0, 1000);
            SetNumberlimits(3, 0, 1000);
            AcceptScreen;
            LS := GetNumber(1);
            LR := GetNumber(2);
            LB := GetNumber(3);
            LimitsFound := False;
            Done;
         END;
      END;
   2: BEGIN
         WITH ParInput DO
         BEGIN
            Init;
            DefineInputPort(0.26, 0.74, 0.2, 0.82);
            LoadLine('');
            LoadLine('      Rossler''s Equations');
            LoadLine('');
            LoadLine(' The equations of the model are:');
            LoadLine('        x'' = - y - z,');
            LoadLine('        y'' = x + a*y,');
            LoadLine('        z'' = b + z*(x - c).');
            LoadLine(' Enter values for the paramters;');
            LoadLine(' these must all be positive.');
            LoadLine('   0 <= a = {        } <= 1000');
            LoadLine('   0 <= b = {        } <= 1000');
            LoadLine('   0 <= c = {        } <= 1000');
            LoadLine('');
            LoadLine('       [ Help ]     [  OK  ]   ');
            SetHelpFile('HlpChaos.Hlp', 'RosslerEquations');
            SetNumber(1, RA);
            SetNumber(2, RB);
            SetNumber(3, RC);
            SetNumberlimits(1, 0, 10000);
            SetNumberlimits(2, 0, 10000);
            SetNumberlimits(3, 0, 10000);
            AcceptScreen;
            RA := GetNumber(1);
            RB := GetNumber(2);
            RC := GetNumber(3);
            LimitsFound := False;
            Done;
         END;
      END;
   3: BEGIN
         WITH ParInput DO
         BEGIN
            Init;
            DefineInputPort(0.26, 0.74, 0.2, 0.82);
            LoadLine('');
            LoadLine('   A Dynamo with Magnetic Reversal');
            LoadLine('');
            LoadLine(' The equations of the model are:');
            LoadLine('        x'' = r - y*z - n*x,');
            LoadLine('        y'' = s*(z - y),');
            LoadLine('        z'' = x*y - z.');
            LoadLine(' Enter values for the paramters;');
            LoadLine(' these must all be positive.');
            LoadLine('   0 <= r = {        } <= 1000');
            LoadLine('   0 <= n = {        } <= 1000');
            LoadLine('   0 <= s = {        } <= 1000');
            LoadLine('');
            LoadLine('       [ Help ]     [  OK  ]   ');
            SetHelpFile('HlpChaos.Hlp', 'DynamoEquationsC');
            SetNumber(1, DR);
            SetNumber(2, DN);
            SetNumber(3, DS);
            SetNumberlimits(1, 0, 10000);
            SetNumberlimits(2, 0, 10000);
            SetNumberlimits(3, 0, 10000);
            AcceptScreen;
            DR := GetNumber(1);
            DN := GetNumber(2);
            DS := GetNumber(3);
            LimitsFound := False;
            Done;
         END;
      END;
   4: BEGIN
         WITH ParInput DO
         BEGIN
            Init;
            DefineInputPort (0.04, 0.96, 0.15, 0.82);
            LoadLine('');
            LoadLine('                       Make your own model');
            LoadLine('');
            LoadLine('         Enter the functions for the right hand sides of the');
            LoadLine('      three differential equations. x, y and z are the only');
            LoadLine('      variables allowed. Do not use symbolic parameters.');
            LoadLine('');
            LoadLine('         Note that the utility <Lorenz Map> cannot be used with');
            LoadLine('      this model.');
            LoadLine('');
            LoadLine(' dx/dt = "                                                         "');
            LoadLine(' dy/dt = "                                                         "');
            LoadLine(' dz/dt = "                                                         "');
            LoadLine('');
            LoadLine('             [ Help ]          [  OK  ]          [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'LorenzInputHelp4');
            SetString(1, XFStr);
            SetString(2, YFStr);
            SetString(3, ZFStr);
            XFunc.Init; YFunc.Init; ZFunc.Init;
            REPEAT
               AcceptScreen;
               IF NOT Canceled THEN
               BEGIN
                  for i := 1 to 3 do Str[i] := GetString(i);
                  StrOK[1] := xFunc.parse('x','y','z','r', Str[1]);
                  if not StrOK[1] then
                     announce('Error: Cannot evaluate x function. Please try again.');
                  StrOK[2] := yFunc.parse('x','y','z','r', Str[2]);
                  if not StrOK[2] then
                     announce('Error: Cannot evaluate y function. Please try again.');
                  StrOK[3] := zFunc.parse('x','y','z','r', Str[3]);
                  if not StrOK[3] then
                     announce('Error: Cannot evaluate y function. Please try again.');
               END;
            UNTIL (StrOk[1] AND StrOk[2]) AND StrOk[3] OR Canceled;
            IF Canceled THEN
            BEGIN
               ModelNumber := 1;
               DMenu.RowActivate(4, 4, True);
            END
            ELSE
            BEGIN
               XFStr := Str[1];
               YFStr := Str[2];
               ZFStr := Str[3];
            END;
            Done;
         END;
      END;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION GetViewingParameters: Integer;
VAR
   ViewInput            : TInputScreen;
BEGIN
   WITH ViewInput DO
   BEGIN
      Init;
      DefineInputPort(0.23, 0.77, 0.3, 0.7);
      LoadLine('');
      LoadLine('  Select one mode for viewing the output');
      LoadLine(' coordinates, x, y, z and the time t:');
      LoadLine('');
      LoadLine('       #1 x-t,   #1 y-t,   #1 z-t');
      LoadLine('       #1 x-y,   #1 y-z,   #1 x-z');
      LoadLine('');
      LoadLine('                [  OK  ]      ');
      SetRadioButton('1', IDisplay);
      AcceptScreen;
      GetViewingParameters := GetRadioButton('1');
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION InitialConditions: Boolean;
VAR
   InitInput      : TInputScreen;
BEGIN
   WITH InitInput DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.25, 0.75);
      LoadLIne('');
      LoadLine('          Enter initial conditions:');
      LoadLine(' When t = 0, ');
      LoadLIne(' x = {        }, y = {        }, z= {        }');
      LoadLine('');
      LoadLine(' The output will be displayed for values of t between');
      LoadLine(' tMin and tMax. (tMax must be greater than tMin.);');
      LoadLine(' enter their values (between 0 and 10000):');
      LoadLine('       tMin = {       },  tMax = {       }');
      LoadLine('');
      LoadLine('                      [  OK  ]');
      SetNumber(1, xStart);
      SetNumber(2, yStart);
      SetNumber(3, zStart);
      SetNumber(4, tMin);
      SetNumber(5, tMax);
      SetNumberLimits(4, 0, 10000);
      SetNumberLimits(5, 0, 10000);
      AcceptScreen;
      xStart := GetNumber(1);
      yStart := GetNumber(2);
      zStart := GetNumber(3);
      tMin := GetNumber(4);
      tMax := GetNumber(5);
      LimitsFound := False;
      If tMin < tMax THEN InitialConditions := True
                     ELSE InitialConditions := False;
      Done;
      If tMin > tMax THEN
        Announce('tMax must be greater then tMin');
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
BEGIN
   CASE ModelNumber OF
   1: BEGIN
         z[1] := LS*(y[2] - y[1]);
         z[2] := LR*y[1] - y[2] - y[1]*y[3];
         z[3] := y[1]*y[2] - LB*y[3];
      END;
   2: BEGIN
         z[1] := - y[2] - y[3];
         z[2] := y[1] + RA*y[2];
         z[3] := RB + y[3]*(y[1] - RC);
      END;
   3: BEGIN
         z[1] := DR - y[2]*y[3] - DN*y[1];
         z[2] := DS*(y[3] -y[2]);
         z[3] := y[1]*y[2] - y[3];
      END;
   4: BEGIN
         z[1] := XFunc.F(y[1], y[2], y[3], r);
         z[2] := YFunc.F(y[1], y[2], y[3], r);
         z[3] := ZFunc.F(y[1], y[2], y[3], r);
      END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Step(xin, hin, tol: real; yin: Vector;
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
      IF TeMax = 0 THEN TeMax := tol/100000;
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol;
   yout := y;
   xout := xtemp + htemp;
   hout := h;
END;

{------------------------------------------------------------------------}

PROCEDURE FindLimits;
VAR
   WaitMessage   : TWaitMessage;
   TEnd          : Real;
BEGIN
   xMin := 0;
   xMax := 0;
   yMin := 0;
   yMax := 0;
   zMin := 0;
   zMax := 0;
   Time := 0;
   IF ChangeR THEN TEnd := 20 ELSE TEnd := TMax;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   StepSize := 0.1;
   WaitMessage.Show;
   IF (tMin > 0) AND (NOT ChangeR) THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
   END;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      WaitMessage.Update;
      IF xMin > y[1] THEN xMin := y[1];
      IF xMax < y[1] THEN xMax := y[1];
      IF yMin > y[2] THEN yMin := y[2];
      IF yMax < y[2] THEN yMax := y[2];
      IF zMin > y[3] THEN zMin := y[3];
      IF zMax < y[3] THEN zMax := y[3];
   UNTIL Time > TEnd;
   LimitsFound := True;
   WaitMessage.Hide;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolution1;
VAR
   Delx, Dely       : Real;
BEGIN
   DelX := (tMax - tMin)/100;
   DelY := (xMax - xMin)/100;
   DefineScale(1, tMin - DelX, tMax + 4*Delx, xMin - Dely, xMax + Dely);
   SelectScale(1);
   ClearMuppetPort;
   DMenu.Display;
   OpenViewPort(1);
   Axis(0, 0, 10, 10);
   PutLabel(Right, 't');
   PutLabel(Top, 'x');
   {PlotLine(tMin, 0, tMax, 0);
   OutTextxy(MapX(tMax+DelX), MapY(DelY), 't');
   PlotLine(0, xMin, 0, xMax);
   OutTextxy(MapX(DelX), MapY(xMax-DelY), 'x');}
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution1;
VAR
   xOld, yOld      : Real;
   Delx, Dely      : Real;
BEGIN
   HideMouse;
   SetUpSolution1;
   xOld := tMin;
   yOld := xStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   yOld := y[1];
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      PlotLine(xOld, yOld, Time, y[1]);
      xOld := Time;
      yOld := y[1];
   UNTIL Time > tMax;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolution2;
VAR
   Delx, Dely      : Real;
BEGIN
   DelX := (tMax - tMin)/100;
   DelY := (yMax - yMin)/100;
   DefineScale(1, tMin - DelX, tMax + 4*Delx, yMin - Dely, yMax + Dely);
   SelectScale(1);
   ClearMuppetPort;
   DMenu.Display;
   OpenViewPort(1);
   Axis(0, 0, 10, 10);
   PutLabel(Right, 't');
   PutLabel(Top, 'y');
   {PlotLine(tMin, 0, tMax, 0);
   OutTextxy(MapX(tMax+DelX), MapY(DelY), 't');
   OutTextxy(MapX(DelX), MapY(yMax-DelY), 'y');
   PlotLine(0, yMin, 0, yMax);}
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution2;
VAR
   xOld, yOld      : Real;
BEGIN
   HideMouse;
   SetUpSolution2;
   xOld := tMin;
   yOld := yStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   yOld := y[2];
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      PlotLine(xOld, yOld, Time, y[2]);
      xOld := Time;
      yOld := y[2];
   UNTIL Time > tMax;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolution3;
VAR
   Delx, Dely      : Real;
BEGIN
   DelX := (tMax - tMin)/100;
   DelY := (zMax - zMin)/100;
   DefineScale(1, tMin - DelX, tMax + 4*Delx, zMin - Dely, zMax + Dely);
   SelectScale(1);
   ClearMuppetPort;
   DMenu.Display;
   OpenViewPort(1);
   Axis(0, 0, 10, 10);
   PutLabel(Right, 't');
   PutLabel(Top, 'z');
   {PlotLine(tMin, 0, tMax, 0);
   OutTextxy(MapX(tMax+DelX), MapY(DelY), 't');
   OutTextxy(MapX(DelX), MapY(zMax-DelY), 'z');
   PlotLine(0, zMin, 0, zMax);}
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution3;
VAR
   xOld, yOld      : Real;
   Delx, Dely      : Real;
BEGIN
   HideMouse;
   SetUpSolution3;
   xOld := tMin;
   yOld := zStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   yOld := y[3];
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      PlotLine(xOld, yOld, Time, y[3]);
      xOld := Time;
      yOld := y[3];
   UNTIL Time > tMax;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolution4;
VAR
   Delx, Dely      : Real;
BEGIN
   DelX := (xMax - xMin)/100;
   DelY := (yMax - yMin)/100;
   DefineScale(1, xMin - DelX, xMax + 4*Delx, yMin - Dely, yMax + 4*Dely);
   SelectScale(1);
   ClearMuppetPort;
   DMenu.Display;
   OpenViewPort(1);
   Axis(0, 0, 10, 10);
   PutLabel(Right, 'x');
   PutLabel(Top, 'y');
   {PlotLine(xMin, 0, xMax, 0);
   OutTextxy(MapX(xMax+DelX), MapY(DelY), 'x');
   OutTextxy(MapX(-DelX/2), MapY(yMax+3*DelY), 'y');
   PlotLine(0, yMin, 0, yMax);}
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution4;
VAR
   xOld, yOld      : Real;
   Delx, Dely      : Real;
BEGIN
   HideMouse;
   SetUpSolution4;
   xOld := xStart;
   yOld := yStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   xOld := y[1];
   yOld := y[2];
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      PlotLine(xOld, yOld, y[1], y[2]);
      xOld := y[1];
      yOld := y[2];
   UNTIL Time > tMax;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolution5;
VAR
   Delx, Dely      : Real;
BEGIN
   DelX := (yMax - yMin)/100;
   DelY := (zMax - zMin)/100;
   DefineScale(1, yMin - DelX, yMax + 4*Delx, zMin - Dely, zMax + 4*Dely);
   SelectScale(1);
   ClearMuppetPort;
   DMenu.Display;
   OpenViewPort(1);
   Axis(0, 0, 10, 10);
   PutLabel(Right, 'y');
   PutLabel(Top, 'z');
   {HideMouse;
   PlotLine(yMin, 0, yMax, 0);
   OutTextxy(MapX(yMax+DelX), MapY(DelY), 'y');
   OutTextxy(MapX(-DelX/2), MapY(zMax+3*DelY), 'z');
   PlotLine(0, zMin, 0, zMax);}
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution5;
VAR
   xOld, yOld      : Real;
BEGIN
   HideMouse;
   SetUpSolution5;
   xOld := yStart;
   yOld := zStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   xOld := y[2];
   yOld := y[3];
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      PlotLine(xOld, yOld, y[2], y[3]);
      xOld := y[2];
      yOld := y[3];
   UNTIL Time > tMax;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpSolution6;
VAR
   Delx, Dely      : Real;
BEGIN
   DelX := (xMax - xMin)/100;
   DelY := (zMax - zMin)/100;
   DefineScale(1, xMin - DelX, xMax + 4*Delx, zMin - Dely, zMax +4* Dely);
   SelectScale(1);
   ClearMuppetPort;
   DMenu.Display;
   OpenViewPort(1);
   Axis(0, 0, 10, 10);
   PutLabel(Right, 'x');
   PutLabel(Top, 'z');
   {PlotLine(xMin, 0, xMax, 0);
   OutTextxy(MapX(xMax+DelX), MapY(DelY), 'x');
   OutTextxy(MapX(-DelX/2), MapY(zMax+3*DelY), 'z');
   PlotLine(0, zMin, 0, zMax);}
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution6;
VAR
   xOld, yOld      : Real;
   Delx, Dely      : Real;
BEGIN
   HideMouse;
   SetUpSolution6;
   xOld := xStart;
   yOld := zStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   xOld := y[1];
   yOld := y[3];
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      PlotLine(xOld, yOld, y[1], y[3]);
      xOld := y[1];
      yOld := y[3];
   UNTIL Time > tMax;
   ShowMouse;
END;

{------------------------------------------------------------------------}
{Procdures for seeing three-dimensional projections.}

PROCEDURE SetUpThreeDHotKeys;
BEGIN
   WITH ThreeDHotKeys DO
   BEGIN
      Init(2);
      Key[1] := 'F2-Redraw';
      Key[2] := 'F10-Menu';
   END;
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

{-----------------------------------------------------------------------}

PROCEDURE View(x, y, z : Real; VAR ViewX, ViewY: Real);
BEGIN
   ViewX := ProjMatrix[1, 1]*x + ProjMatrix[1, 2]*y;
   ViewY := ProjMatrix[2, 1]*x + ProjMatrix[2, 2]*y + ProjMatrix[2, 3]*z;
END;


PROCEDURE SetScale;
VAR
   MaxX, MinX, MaxY, MinY : Real;

PROCEDURE Test(x, y, z : Real);
VAR
   xTest, yTest : Real;
BEGIN
    View(x, y, z, xTest, yTest);
   IF xTest > MaxX THEN MAxX := xTest;
   IF xTest < MinX THEN MinX := xTest;
   IF yTest > MaxY THEN MAxY := yTest;
   IF yTest < MinY THEN MinY := yTest;
END;

BEGIN
   MaxX := 0; MinX := 0; MaxY := 0; MinY := 0;
   Test(XMax, YMax, ZMax);
   Test(XMax, YMax, ZMin);
   Test(XMax, YMin, ZMax);
   Test(XMax, YMin, ZMin);
   Test(XMin, YMax, ZMax);
   Test(XMin, YMax, ZMin);
   Test(XMin, YMin, ZMax);
   Test(XMin, YMin, ZMin);
   DefineScale(5, MinX - (MaxX-MinX)*0.1, MaxX + (MaxX-MinX)*0.1,
                  MinY - (MaxY-MinY)*0.1, MaxY + (MaxY-MinY)*0.1);
   SelectScale(5);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawArrow2(XTail, YTail, XHead, YHead, Ratio: Real;
                     ArrowColor : Word; TNB: String);
VAR
   Length: Real;
   XBarb, YBarb: Real;
   xSc, ySc: Integer;
   SaveColor : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(ArrowColor);
   Length := Sqrt(Sqr(XHead - XTail) + Sqr(YHead - YTail));
   IF Length = 0 THEN Exit;
   PlotLine(XTail, YTail, XHead, YHead);
   XBarb := XHead + Ratio*(-XHead + XTail + 0.5*(YHead - YTail))/Length;
   YBarb := YHead + Ratio*(-YHead + YTail - 0.5*(XHead - XTail))/Length;
   PlotLine(XHead, YHead, XBarb, YBarb);
   XBarb := XHead + Ratio*(-XHead + XTail - 0.5*(YHead - YTail))/Length;
   YBarb := YHead + Ratio*(-YHead + YTail + 0.5*(XHead - XTail))/Length;
   PlotLine(XHead, YHead, XBarb, YBarb);
   Map(XTail + 1.05*(XHead - XTail),  YTail + 1.1*(YHead - YTail), xSc, ySc);
   OutTextxy(xSc, ySc, TNB);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawBox;
VAR
   x1, y1, x2, y2, x3, y3, x4, y4  : Real;
   x5, y5, x6, y6, x7, y7, x8, y8  : Real;
BEGIN
   View(XMax, YMax, ZMax, x1, y1);
   View(XMin, YMax, ZMax, x2, y2);
   View(XMin, YMin, ZMax, x3, y3);
   View(XMax, YMin, ZMax, x4, y4);
   View(XMax, YMax, ZMin, x5, y5);
   View(XMin, YMax, ZMin, x6, y6);
   View(XMin, YMin, ZMin, x7, y7);
   View(XMax, YMin, ZMin, x8, y8);




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
   DrawArrow2(x7, y7, x8+0.1*(x8-x7), y8+0.1*(y8-y7), 0.5, White, 'x');
   DrawArrow2(x7, y7, x6+0.1*(x6-x7), y6+0.1*(y6-y7), 0.5, White, 'y');
   DrawArrow2(x7, y7, x3+0.1*(x3-x7), y3+0.1*(y3-y7), 0.5, White, 'z');
END;

{------------------------------------------------------------------------}

PROCEDURE GraphThreeD;
VAR
   xOld, yOld, xNew, yNew      : Real;
BEGIN
   HideMouse;
   SetViewingMatrix;
   SetScale;
   OpenViewPort(5);
   DrawBox;
   xOld := xStart;
   yOld := yStart;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Time := 0;
   Message('                 Press a key to halt graphing');
   IF tMin > 0 THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
      Step(Time, tMin - Time, 0.0000001, y, Time, StepSize, y);
      StepSize := 0.1;
   END;
   View(y[1], y[2], y[3], xOld, yOld);
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      View(y[1], y[2], y[3], xNew, yNew);
      PlotLine(xOld, yOld, xNew, yNew);
      xOld := xNew;
      yOld := yNew;
   UNTIL (Time > tMax) OR (KeyPressed);
   ClearMKBuffers;
   Message('');
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   ThetaDeg := Sliders.Value(1);
   PhiDeg := Sliders.Value(2);
   Theta := ThetaDeg*Pi/180;
   Phi := PhiDeg*Pi/180;
   SetViewingMatrix;
   SetScale;
   OpenViewPort(6);
   DrawBox;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleThreeDHotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: GraphThreeD;
      2: BEGIN
            ThreeDHotKeys.Clear;
            ThreeDim := False;
            LightMenu := True;
            ClearMuppetPort;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpThreeD;
BEGIN
   ClearMuppetPort;
   GraphBackColor := DarkGray;
   LightMenu := False;
   ThreeDim := True;
   Theta := ThetaDeg*PI/180;
   Phi := PhiDeg*Pi/180;
   SetViewingMatrix;
   IF NOT LimitsFound THEN FindLimits;
   SetScale;
   OpenViewPort(6);
   Sliders.create(1, 0, 360,ThetaDeg, 0.71, 0.43, 0.99,0,'0',
                      '360','Theta',false);
   Sliders.create(2, 0, 180, PhiDeg, 0.71, 0.07, 0.4,0,
                     '0','180','Phi',true );
   Sliders.DrawAll;
   SetColor(White);
   DrawBox;
   ThreeDHotKeys.Display;
   GraphThreeD;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolution;
BEGIN
   CASE IDisplay OF
      1: PlotSolution1;
      2: PlotSolution2;
      3: PlotSolution3;
      4: PlotSolution4;
      5: PlotSolution5;
      6: PlotSolution6;
   END;
END;

{------------------------------------------------------------------------}
{Procdures for varung the parameter r.}

PROCEDURE SetUpChangeRHotKeys;
BEGIN
   WITH ChangeRHotKeys DO
   BEGIN
      Init(6);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-DelR';
      Key[3] := 'F4-R+';
      Key[4] := 'F5-R-';
      Key[5] := 'F6-CleanUp';
      Key[6] := 'F10-Menu';
      BackColor := Red;
      Display;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpChangeRScreen;
BEGIN
   CASE IDisplay OF
      1: SetUpSolution1;
      2: SetUpSolution2;
      3: SetUpSolution3;
      4: SetUpSolution4;
      5: SetUpSolution5;
      6: SetUpSolution6;
   END;
   SetUpChangeRHotKeys;
   Action := False;
   Message('           r = ' + NumStr(LR, 6, 3));
   HideMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE CleanUp;
BEGIN
   Time := 0;
   TMin := 0;
   FindLimits;
   CASE IDisplay OF
      1: SetUpSolution1;
      2: SetUpSolution2;
      3: SetUpSolution3;
      4: SetUpSolution4;
      5: SetUpSolution5;
      6: SetUpSolution6;
   END;
END;


{------------------------------------------------------------------------}

PROCEDURE TakeStep;
VAR
   xOld, yOld      : Real;
BEGIN
   CASE IDisplay OF
      1: BEGIN xOld := Time; yOld := y[1]; END;
      2: BEGIN xOld := Time; yOld := y[2]; END;
      3: BEGIN xOld := Time; yOld := y[3]; END;
      4: BEGIN xOld := y[1]; yOld := y[2]; END;
      5: BEGIN xOld := y[2]; yOld := y[3]; END;
      6: BEGIN xOld := y[1]; yOld := y[3]; END;
   END;
   Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   CASE IDisplay OF
      1: BEGIN
            PlotLine(xOld, yOld, Time, y[1]);
            xOld := Time;
            yOld := y[1];
         END;
      2: BEGIN
            PlotLine(xOld, yOld, Time, y[2]);
            xOld := Time;
            yOld := y[2];
         END;
      3: BEGIN
            PlotLine(xOld, yOld, Time, y[3]);
            xOld := Time;
            yOld := y[3];
         END;
      4: BEGIN
            PlotLine(xOld, yOld, y[1], y[2]);
            xOld := y[1];
            yOld := y[2];
         END;
      5: BEGIN
            PlotLine(xOld, yOld, y[2], y[3]);
            xOld := y[2];
            yOld := y[3];
         END;
      6: BEGIN
            PlotLine(xOld, yOld, y[1], y[3]);
            xOld := y[1];
            yOld := y[3];
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetNewDelR;
VAR
   DelRInputScreen    : TInputScreen;
BEGIN
   ShowMouse;
   WITH DelRInputScreen DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.4, 0.7);
      LoadLine('');
      LoadLine('  Enter a value for the increment DelR.');
      LoadLine('  It should lie between 0 and 10.');
      LoadLine('            DelR = {      }');
      LoadLine('');
      LoadLIne('                  [  OK  ]');
      SetNumber(1, DelR);
      SetNumberLimits(1, 0, 10);
      AcceptScreen;
      DelR := GetNumber(1);
      Done;
   END;
   HideMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleChangeRHotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH ChangeRHotKeys DO Key[1] := 'F2-Run';
               ChangeRHotKeys.BackColor := Red;
               ChangeRHotKeys.Display;
            END
            ELSE
            BEGIN
               Action := True;
               WITH ChangeRHotKeys DO Key[1] := 'F2-Stop';
               ChangeRHotKeys.BackColor := Blue;
               ChangeRHotKeys.Display;
            END;
         END;
      2: GetNewDelR;
      3: BEGIN
            LR := LR + DelR;
            Message('           r = ' + NumStr(LR, 6, 3));
         END;
      4: BEGIN
            LR := LR - DelR;
            Message('           r = ' + NumStr(LR, 6, 3));
         END;
      5: CleanUp;
      6: BEGIN
            Action := False;
            ChangeR := False;
            ChangeRHotKeys.Clear;
            Lightmenu := True;
            ShowMouse;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE FindXPeaks;
VAR
   WaitMessage   : TWaitMessage;
   xDot          : Real;
   TempStepSize  : Real;
   z             : Vector;
   I             : Integer;
   Z1Prime       : Real;
BEGIN
   Time := 0;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Fun(Time, y, z);
   IF z[1] < 0 THEN xDot := -1 ELSE xDot := 1;
   StepSize := 0.1;
   I := 0;
   WaitMessage.Show;
   IF (tMin > 0) THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
   END;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      Fun(Time, y, z);
      IF xDot*z[1] < 0 THEN
      BEGIN
         I := I + 1;
         WaitMessage.Update;
         REPEAT
            Fun(Time, y, z);
            CASE ModelNumber OF
               1: Z1Prime := LS*(z[2] - z[1]);
               2: Z1Prime := z[2] - z[3];
               3: Z1Prime := - z[2]*y[3] - y[2]*z[3]- DN*z[1];
            END;
            TempStepSize := - z[1]/(Z1Prime);
            Step(Time, TempStepSize,0.00001, y, Time, TempStepSize, y);
            Fun(Time, y, z);
         UNTIL Abs(z[1]) < 0.001;
         Peaks[I] := y[1];
         xDot := - xDot;
      END;
   UNTIL (Time > TMax) OR (I = 500);
   PeaksNum := I;
   WaitMessage.Hide;
END;

{------------------------------------------------------------------------}

PROCEDURE FindYPeaks;
VAR
   WaitMessage   : TWaitMessage;
   yDot          : Real;
   TempStepSize  : Real;
   z             : Vector;
   I             : Integer;
   Z2Prime       : Real;
BEGIN
   Time := 0;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Fun(Time, y, z);
   IF z[2] < 0 THEN yDot := -1 ELSE yDot := 1;
   StepSize := 0.1;
   I := 0;
   WaitMessage.Show;
   IF (tMin > 0) THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
   END;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      Fun(Time, y, z);
      IF yDot*z[2] < 0 THEN
      BEGIN
         I := I + 1;
         WaitMessage.Update;
         REPEAT
            Fun(Time, y, z);
            CASE ModelNumber OF
               1: Z2Prime := LR*z[1] - z[2] - z[1]*y[3] - y[1]*z[3];
               2: Z2Prime := z[1] + RA*z[2];
               3: Z2Prime := DS*(z[3] - z[2]);
            END;
            TempStepSize := - z[2]/(Z2Prime);
            Step(Time, TempStepSize,0.00001, y, Time, TempStepSize, y);
            Fun(Time, y, z);
         UNTIL Abs(z[2]) < 0.001;
         Peaks[I] := y[2];
         yDot := - yDot;
      END;
   UNTIL (Time > TMax) OR (I = 500);
   PeaksNum := I;
   WaitMessage.Hide;
END;

{------------------------------------------------------------------------}

PROCEDURE FindZPeaks;
VAR
   WaitMessage   : TWaitMessage;
   zDot          : Real;
   TempStepSize  : Real;
   z             : Vector;
   I             : Integer;
   Z3Prime       : Real;
BEGIN
   Time := 0;
   y[1] := xStart;
   y[2] := yStart;
   y[3] := zStart;
   Fun(Time, y, z);
   IF z[3] < 0 THEN zDot := -1 ELSE zDot := 1;
   StepSize := 0.1;
   I := 0;
   WaitMessage.Show;
   IF (tMin > 0) THEN
   BEGIN
      REPEAT
         Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      UNTIL Time + StepSize > tMin;
   END;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      Fun(Time, y, z);
      IF zDot*z[3] < 0 THEN
      BEGIN
         I := I + 1;
         WaitMessage.Update;
         REPEAT
            Fun(Time, y, z);
            CASE ModelNumber OF
               1: Z3Prime := z[1]*y[2] + y[1]*z[2] - LB*z[3];
               2: Z3Prime := z[3]*(y[1] - RC) + z[1]*y[3];
               3: Z3Prime := z[1]*y[2] + y[1]*z[2] - z[3];
            END;
            TempStepSize := - z[3]/(Z3Prime);
            Step(Time, TempStepSize,0.00001, y, Time, TempStepSize, y);
            Fun(Time, y, z);
         UNTIL Abs(z[3]) < 0.001;
         Peaks[I] := y[3];
         zDot := - zDot;
      END;
   UNTIL (Time > TMax) OR (I = 500);
   PeaksNum := I;
   WaitMessage.Hide;
END;

{------------------------------------------------------------------------}

FUNCTION LorenzMapInput: Integer;
CONST
   RBNames : string = '12345678'; 
VAR
   Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.2, 0.75);
      LoadLine('');
      LoadLine('     This utility will generate values');
      LoadLine('  of maxima of x(t), y(t) or z(t). Select');
      LoadLine('  one of these.');
      LoadLine('      x(t)#1       y(t)#1      z(t)#1');
      LoadLine('');
      LoadLine('     The output will be displayed for values');
      LoadLine('  of t between tMin and tMax. Enter their');
      LoadLine('  values (between 0 and 10000):');
      LoadLine('      tMin = {      },  tMax = {      }');
      LoadLine('');
      LoadLine('          [ Help ]        [  OK  ]');
      SetHelpFile('HlpChaos .hlp', 'LorenzMaps');
      SetRadioButton(RBNames[1], LorenzNumber);
      SetNumber(4, tMin);
      SetNumber(5, tMax);
      SetNumberLimits(4, 0, 10000);
      SetNumberLimits(5, 0, 10000);
      AcceptScreen;
      LorenzMapInput := GetRadioButton(RBNames[1]);
      tMin := GetNumber(4);
      tMax := GetNumber(5);
      Done;
   END;
END;


{------------------------------------------------------------------------}

PROCEDURE PlotLorenzMap;
VAR
   zPMax, zPMin    : Real;
   I               : Integer;
   Delz            : Real;
BEGIN
   ClearMuppetPort;
   DefineViewPort(2, 0.2, 0.8, 0.15, 0.85);
   REPEAT
      LorenzNumber := LorenzMapInput;
      IF tMax <= tMin THEN Announce('tMax must be GREATER than tMin');
   UNTIL tMax > tMin;
   zPMax := 0;
   zPMin := 0;
   CASE LorenzNumber OF
      1: FindXPeaks;
      2: FindYPeaks;
      3: FindZPeaks;
   END;
   FOR I := 1 TO PeaksNum DO
   BEGIN
      IF ZPMax < Peaks[i] THEN zPMax := Peaks[i];
      IF zPMin > Peaks[i] THEN zpMin := Peaks[i];
   END;
   Delz := (zpMax - zpMin)/10;
   DefineScale(2, zpMin - Delz, zpmax + delz, zpMin - Delz, zpMax + delz);
   OpenViewPort(2);
   SelectScale(2);
   IF Delz > 1 THEN Axis(0, 0, 10, 10) ELSE Axis(0, 0, 1, 1);
   CASE LorenzNumber OF
      1: PutLabel(Bottom, 'x');
      2: PutLabel(Bottom, 'y');
      3: PutLabel(Bottom, 'z');
   END;
   FOR I := 1 TO PeaksNum - 1 DO
      PlotSymbol(Peaks[i], Peaks[i+1], '.');
END;

{------------------------------------------------------------------------}

PROCEDURE HandleDMenu;

BEGIN
   With DMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: BEGIN
                  AboutCUPS;
               END;
            2: ShowHelp('HlpChaos.hlp', 'AboutLorenzProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpChaos.hlp', 'LorenzEquations');
            2: ShowHelp('HlpChaos.hlp', 'RosslerEquations');
            3: BEGIN
                  ShowHelp('HlpChaos.hlp', 'DynamoEquationsA');
                  ShowHelp('HlpChaos.hlp', 'DynamoEquationsB');
                  ShowHelp('HlpChaos.hlp', 'DynamoEquationsC');
               END;
            4: ShowHelp('HlpChaos.hlp', 'LorenzMaps');
            5: BEGIN
                  ShowHelp('WalkThru.hlp', 'Lorenz1');
                  ShowHelp('WalkThru.hlp', 'Lorenz2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  ModelNumber := 1;
                  GetParameters;
                  DMenu.RowActivate(4, 4, True);
               END;
            2: BEGIN
                  ModelNumber := 2;
                  GetParameters;
                  DMenu.RowActivate(4, 4, True);
               END;
            3: BEGIN
                  ModelNumber := 3;
                  GetParameters;
                  DMenu.RowActivate(4, 4, True);
               END;
            4: BEGIN
                  ModelNumber := 4;
                  GetParameters;
                  DMenu.RowActivate(4, 4, False);
               END;
         END;
      4: CASE RowChosen OF
            1: IDisplay := GetViewingParameters;
            2: REPEAT UNTIL InitialConditions;
            3: BEGIN
                  IF NOT LimitsFound THEN FindLimits;
                  ChangeR := False;
                  PlotSolution;
               END;
            4: PlotLorenzMap;
            5: BEGIN
                  ThreeDim := True;
                  LightMenu := False;
                  SetUpThreeD;
               END;
         END;
    END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(5, 0, 0.65, 0.07, 0.93);
   DefineViewPort(6, 0.75, 1, 0.07, 0.4);
   Time := 0;
   xStart := 0;
   yStart := 1;
   zStart := 0;
   ThetaDeg := 10;
   PhiDeg := 10;
   tMin := 0;
   tMax := 50;
   rMin := 145;
   rMax := 167;
   rNum := 30;
   y[1] := 0;
   y[2] := 1;
   y[3] := 0;
   LS := 10;
   LR := 28;
   LB := 8/3;
   DS := 5;
   DN := 1;
   DR := 14.5;
   RA := 0.35;
   RB := 2;
   RC := 4;
   xFStr := '- x + y*z';
   yFStr := '- y + x*z - x';
   zFStr := '1 - x*y';
   DelR := 1;
   DistMin := 0.1;
   IDisplay := 1;
   ModelNumber := 1;
   LorenzNumber := 3;
   DefineViewPort(1, 0.1, 0.9, 0.1, 0.9);
   Hello('HlpChaos.hlp', 'AboutLorenzProgram');
   SetUpDMenu;
   SetUpThreeDHotKeys;
   ChangeR := False;
   LimitsFound := False;
   ThreeDim := False;
   LightMenu := True;
   ExitRequest := False;
END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Sliders.Init;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF CHangeR THEN
      BEGIN
         IF ChangeRHotKeys.Pressed(Key) THEN HandleChangeRHotKeys(Key);
         IF Action THEN TakeStep;
      END;
      IF ThreeDim THEN
      BEGIN
         IF ThreeDHotKeys.Pressed(Key) THEN HandleThreeDHotKeys(Key);
         IF Sliders.Changed THEN HandleSliders;
      END;
      IF LightMenu AND DMenu.Chosen THEN HandleDMenu;
   UNTIL ExitRequest;
   CUPSDone;
   DMenu.Done;
   Sliders.Done;
END.


