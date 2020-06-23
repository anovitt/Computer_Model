Program TripToTheMoon;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 4;

type
   vector = array[1..neq] of real;

var
   y, z                                        : Vector;
   MoonMenu                                    : TMenu;
   HotKeys                                     : THotKeys;
   BlowUp                                      : TImage;
   ParkingRadius, InitialAngle, InitialSpeed   : Real;
   Altitude                                    : Real;
   AngleDegrees                                : Real;
   Time, StepSize                              : Real;
   xOld, yOld, xNew, yNew                      : Real;
   xMoonOld, yMoonOld, xMoonNew, yMoonNew      : Real;
   MoonMass, MeanMotion                        : Real;
   xLow, xHigh, yLow, yHigh                    : Real;
   x1, y1, x2, y2                              : Integer;
   Lag                                         : Integer;
   PlotOrbit, Action                           : Boolean;
   ExitRequest                                 : Boolean;
   CloseApproach                               : Boolean;
   WindowOpened                                : Boolean;
   LightMenu                                   : Boolean;
   JoinTimes                                   : Boolean;
   ReRun                                       : Boolean;
   DelTimeHours, DelTime, NextTime             : Real;
   Key                                         : Byte;

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

{---------------------------------------------------------------------------}

PROCEDURE SetUpMoonMenu;
VAR
   I      : Integer;
BEGIN
   With MoonMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About the program');
       row(1,2, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Starting conditions');
       row(3,2, 'See the animation');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   MoonMenu.Display;
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Run';
      Key[3] := 'F3-Faster';
      Key[4] := 'F4-Slower';
      Key[5] := 'F5-ReScale';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
END;

{-------------------------------------------------------------------------}

FUNCTION GetMoonData : Boolean;
VAR
   MoonDat : TInputScreen;
BEGIN
   WITH MoonDat DO
   BEGIN
      Init;
      DefineInputPort(0.6, 1, 0.05, 0.95);
      LoadLine('');
      LoadLine('   Launch data for a trip');
      LoadLine('        to the Moon');
      LoadLine('');
      LoadLine('Altitude of the parking orbit, ');
      LoadLine('between 0 and 1000 km:');
      LoadLine('             Alt = {         }');
      LoadLine('Initial speed, in km/sec,');
      LoadLine('which should be positive:');
      LoadLine('               V = {         }');
      LoadLine('Orientation angle, A, which');
      LoadLine('shoud be between -180 and');
      LoadLine('+180 degrees : A = {         }');
      LoadLine('');
      LoadLine('The mass of the Moon is 0.0123');
      LoadLine('Earth masses. You may enter ');
      LoadLine('another value, between 0 and 1:');
      LoadLine('    Mass of Moon = {         }');
      LoadLine('');
      LoadLIne(' [ Help ]  [  OK  ]  [Cancel]');
      SetHelpFile('HelpAstr.Hlp', 'MoonAboutModel');
      SetNumber(1, Altitude);
      SetNumberLimits(1, 0, 1000);
      SetNumber(2, InitialSpeed);
      SetNumber(3, AngleDegrees);
      SetNumberLimits(3, -180, 180);
      SetNumber(4, MoonMass);
      SetNumberLimits(4, 0, 1);
      AcceptScreen;
      GetMoonData := NOT Canceled;
      IF Canceled THEN Exit;
      Altitude := GetNumber(1);
      ParkingRadius := (Altitude + 6378)/384400;
      InitialSpeed := GetNumber(2);
      AngleDegrees := GetNumber(3);
      InitialAngle := AngleDegrees*Pi/180;
      MoonMass := GetNumber(4);
      MeanMotion := sqrt(1+MoonMass);
      y[1] := ParkingRadius*sin(InitialAngle);
      y[2] := - ParkingRadius*cos(InitialAngle);
      y[3] := InitialSpeed*cos(InitialAngle)*0.9834;
      y[4] := InitialSpeed*sin(InitialAngle)*0.9834;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE ShowParameters;
VAR
   xSc, ySc, xSc2, ySc2: Integer;
   Radius: Integer;
   x1, y1, x2, y2: Real;
   i: Integer;
BEGIN
   DefineViewPort(2, 0.05, 0.6, 0.05, 0.95);
   DefineScale(2, -5, 5, -5, 5);
   HideCursor;
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   Message('');
   Map(0, 0, xSc, ySc);
   Map(3, 0, xSc2, ySc2);
   Radius := xSc2 - xSc;
   SetColor(Yellow);
   Circle(xSc, ySc, Radius);
   Arc(xSc, ySc, 270, 350, Trunc(Radius/3));
   x1 := 3*Cos(Pi/18);
   y1 := -3*Sin(Pi/18);
   PlotLIne(0, 0, x1, y1);
   PLotLine(0, 0, 0, -4);
   x1 := 0.95*Cos(Pi/5.9);
   y1 := -0.95*Sin(Pi/5.9);
   PLotLine(x1, y1, x1, y1-0.2);
   PLotLine(x1, y1, x1-0.2, y1+0.1);
   x1 := 3*Cos(Pi/18);
   y1 := -3*Sin(Pi/18);
   x2 := x1 + 3*sin(Pi/18);
   y2 := y1 + 3*cos(Pi/18);
   PlotLine(x1, y1, x2, y2);
   x1 := x2 + 0.5*cos(Pi*55/180);
   y1 := y2 - 0.5*sin(Pi*55/180);
   PlotLine(x1, y1, x2, y2);
   x1 := x2 - 0.5*sin(Pi*55/180);
   y1 := y2 - 0.5*cos(Pi*55/180);
   PlotLine(x1, y1, x2, y2);
   x1 := 0;
   y1 := -4;
   x2 := x1 + 0.5/1.414;
   y2 := y1 + 0.5/1.414;
   PlotLine(x1, y1, x2, y2);
   x2 := x1 - 0.5/1.414;
   PlotLine(x1, y1, x2, y2);
   SetFillStyle(SolidFill, LightBlue); SetColor(LightBlue);
   FillEllipse(xSc, ySc, Trunc(Radius/5), Trunc(Radius/5));
   SetColor(White);
   OutTextxy(MapX(-1), MapY(3.5), 'Parking Orbit');
   OutTextxy(MapX(-1.8), MapY(0.1), 'Earth');
   Map(0.7, -0.7, xSc, ySc);
   OutTextxy(MapX(0.4), MapY(-0.4), 'A');
   Map(3.7, 2.6, xSc, ySc);
   OutTextxy(xSc, ySc, 'V');
   Map(1.6, 0, xSc, ySc);
   OutTextxy(xSc, ySc, 'R0');
   ShowCursor;
END;

{------------------------------------------------------------------------}

PROCEDURE SetDisplayOptions;
CONST
   RBNames : string = '12345678';
VAR
   DisplayInput     : TInputScreen;
BEGIN
   WITH DisplayInput DO
   BEGIN
      Init;
      DefineInputPort(0.12, 0.88, 0.14, 0.87);
      LoadLine('');
      LoadLine('    In the animated display you have the options of');
      LoadLine('  seeing:');
      LoadLine('  (a) The path of the spacecraft, marked at equal in-');
      LoadLine('      tervals of time, and the varying position of the');
      LoadLine('      Moon,');
      LoadLine('  or');
      LoadLine('  (b) Both paths, with positions of the spacecraft and');
      LoadLine('      and Moon joined at equal intervals of time.');
      LoadLine('          Select  #1 (a)  or  #1 (b).');
      LoadLine('');
      LoadLine('    Enter a time interval for the option (b):');
      LoadLine('            2 <= {      } hours <= 100');
      LoadLine('  (A value > 100 will suppress all marking and joining.)');
      LoadLine('');
      LoadLine('                         [  OK  ]');
      IF NOT JoinTimes THEN SetRadioButton(RBNames[1], 1)
                       ELSE SetRadioButton(RBNames[1], 2);
      SetNumber(3, DelTimeHours);
      SetNumberLimits(3, 2, 10000000);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
         JoinTimes := False ELSE JoinTimes := True;
      DelTimeHours := GetNumber(3);
      IF DelTimeHours > 100 THEN JoinTimes := False;
      DelTime := DelTimeHours*(2*Pi)/(27.321662*24);
      Done;
   END;
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
VAR
   r, xm, ym, rrr, d: Real;
begin
   r := sqrt(y[1]*y[1] + y[2]*y[2]);
   rrr := r*r*r;
   z[1] := y[3]; z[2] := y[4];
   xm := cos(MeanMotion*x);
   ym := sin(MeanMotion*x);
   d := sqrt((y[1] - xm)*(y[1] - xm) + (y[2] - ym)*(y[2] - ym));
   z[3] := - y[1]/rrr + MoonMass*((xm - y[1])/(d*d*d) - xm);
   z[4] := - y[2]/rrr + MoonMass*((ym - y[2])/(d*d*d) - ym);
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

PROCEDURE PrintTime(Time: Real);
VAR
   Hours, Days: Integer;
BEGIN
   SetColor(White);
   Hours := Trunc(Time*27.321662*24/(2*Pi));
   Days := Trunc(Hours/24);
   IF Days >= 1 THEN Hours := Hours - 24*Days;
   rubOutXY(0.69, 0.93, 5, Black);
   printXY(0.69, 0.93, NumStr(Days,3,0));
   rubOutXY(0.83, 0.93, 4, Black);
   printXY(0.83, 0.93, NumStr(TRUNC(Hours),3,0));
   SelectViewPort(1);
END;

{-------------------------------------------------------------------------}

PROCEDURE Wow;
VAR
   i: Integer;
BEGIN
   FOR i := 1 TO 50 DO
   BEGIN
      Sound(1000-12*i);
      Delay(10);
      NoSound;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpOrbit;
BEGIN
   y[1] := ParkingRadius*sin(InitialAngle);
   y[2] := - ParkingRadius*cos(InitialAngle);
   y[3] := InitialSpeed*cos(InitialAngle)*0.9834;
   y[4] := InitialSpeed*sin(InitialAngle)*0.9834;
   ClearMuppetPort;
   GraphBackColor := Black;
   OpenViewPort(1);
   IF DelTimeHours < 100
      THEN Message(' The orbits will be joined at intervals of '
                     + NumStr(DelTimeHours, 3, 1) + ' hours');
   SelectScale(1);
   Axis(100, 100, 1, 1);
   SetColor(LightBlue);
   PlotSymbol(0, 0, '0');
   xMoonOld := 1;
   yMoonOld := 0;
   SetColor(White);
   PlotSymbol(xMoonOld, yMoonOld, 'o');
   Time := 0;
   IF DelTimeHours <= 100 THEN NextTime := Time + DelTime
                          ELSE NextTime := Time + 1000000;
   Action := False;
   WITH HotKeys DO Key[2] := 'F2-Run';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   printXY(0.7, 0.93, '     days,       hours');
   PrintTime(0);
   StepSize := 1;
   PlotOrbit := True;
   LightMenu := False;
   CloseApproach := False;
   WindowOpened := False;
   x1 := Trunc(0.0*GetMaxX);
   y1 := Trunc(0.0*GetMaxY);
   x2 := Trunc(0.33*GetMaxX);
   y2 := Trunc(0.36*GetMaxY);
   xOld := y[1]; yOld := y[2];
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpOrbit2;
BEGIN
   ClearMuppetPort;
   GraphBackColor := Black;
   OpenViewPort(1);
   IF DelTimeHours < 100
      THEN Message(' The orbits will be joined at intervals of '
                     + NumStr(DelTimeHours, 3, 1) + ' hours');
   SelectScale(1);
   Axis(100, 100, 1, 1);
   SetColor(LightBlue);
   xMoonOld := cos(MeanMotion*Time);
   yMoonOld := sin(MeanMotion*Time);
   SetColor(Blue);
   PlotSymbol(0, 0, 'o');
   SetColor(White);
   PlotSymbol(xMoonOld, yMoonOld, 'o');
   IF DelTimeHours <= 100 THEN NextTime := Time + DelTime
                          ELSE NextTime := Time + 1000000;
   Action := False;
   WITH HotKeys DO Key[2] := 'F2-Run';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   printXY(0.7, 0.93, '     days,       hours');
   PrintTime(Time);
   StepSize := 1;
   PlotOrbit := True;
   LightMenu := False;
   CloseApproach := False;
   WindowOpened := False;
   x1 := Trunc(0.0*GetMaxX);
   y1 := Trunc(0.0*GetMaxY);
   x2 := Trunc(0.33*GetMaxX);
   y2 := Trunc(0.36*GetMaxY);
   xOld := y[1]; yOld := y[2];
END;

{-------------------------------------------------------------------------}

PROCEDURE StepOrbit;
VAR
   Temph, Tempt                 : Real;
   Radius: Integer;
   xSc1, xSc2, ySc1, ySc2: Integer;
   Tempy                  : Vector;
BEGIN
   SetColor(Yellow);
   Delay(Lag);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF y[1]*y[1]+y[2]*y[2] > 100 THEN
   BEGIN
      PlotOrbit := False;
      Announce('I''ve escaped!');
      HotKeys.Clear;
      LightMenu := True;
      Exit;
   END;
   PrintTime(Time);
   SetColor(Yellow);
   xNew := y[1]; yNew := y[2];
   PlotLine(xOld, yOld, xNew, yNew);
   xMoonNew := cos(MeanMotion*Time);
   yMoonNew := sin(MeanMotion*Time);
   IF NOT (JoinTimes) THEN
   BEGIN
      SetColor(Black);
      PlotSymbol(xMoonOld, yMoonOld, 'o');
      SetColor(White);
      PlotSymbol(xMoonNew, yMoonNew, 'o');
   END;
   IF JoinTimes THEN
   BEGIN
      SetColor(White);
      PlotLine(xMoonOld, yMoonOld, xMoonNew, yMoonNew);
   END;
   IF Time > NextTime THEN
   BEGIN
      Step(Time, NextTime - Time, 0.000001, y, Tempt, Temph, Tempy);
      SetColor(Yellow);
      PlotSymbol(Tempy[1], Tempy[2], '*');
      IF JoinTimes THEN
      BEGIN
         SetLineStyle(DashedLn, 0, NormWidth);
         SetColor(LightGray);
         PlotLine(Tempy[1], Tempy[2],
                     Cos(MeanMotion*Tempt), Sin(MeanMotion*Tempt));
         SetLineStyle(SolidLn, 0, NormWidth);
         SetColor(White);
      END;
      NextTime := TempT + DelTime;
   END;
   {END;}
   IF (y[1] - xMoonNew)*(y[1] - xMoonNew)
          + (y[2] - yMoonNew)*(y[2] - yMoonNew) < 0.05*0.05
   THEN CloseApproach := True ELSE CloseApproach := False;
   IF (WindowOpened) AND (NOT CloseApproach) THEN
   BEGIN
      SetColor(Black);
      GraphBackColor := Black;
      CloseViewPort(4);
      SelectViewPort(1);
      BlowUp.Put(x1, y1);
      WindowOpened := False;
      SetColor(White);
      IF NOT (JoinTimes) THEN PlotSymbol(xMoonNew, yMoonNew, 'o');
   END;
   IF Sqr(xMoonNew - y[1]) + Sqr(yMoonNew - y[2]) < Sqr(0.005) THEN
   BEGIN
      Wow;
      PlotOrbit := False;
      HotKeys.Clear;
      LightMenu := True;
      Exit;
   END;
   IF Sqrt(y[1]*y[1] + y[2]*y[2]) < 0.0166 THEN
   BEGIN
      Announce('Hi! I''ve just landed back on Earth');
      PlotOrbit := False;
      HotKeys.Clear;
      LightMenu := True;
      Exit;
   END;
   IF CloseApproach THEN
   BEGIN
      IF NOT WindowOpened THEN
      BEGIN
         SetColor(Black);
         PlotSymbol(xMoonNew, yMoonNew, 'o');
         BlowUp.Get(x1, y1, x2, y2);
         GraphBackColor := DarkGray;
         OpenViewPort(4);
         SelectScale(4);
         SetColor(White);
         SetFillStyle(SolidFill, White);
         Radius := MapX(0.005) - MapX(0);
         FillEllipse(MapX(0), MapY(0), Radius, Radius);
         WindowOpened := True;
       END;
      SelectViewPort(4);
      SelectScale(4);
      SetColor(Blue);
      SetColor(Yellow);
      PlotLine(xOld-xMoonOld, yOld-yMoonOld, xNew-xMoonNew, yNew-yMoonNew);
      SelectScale(1);
      SelectViewPort(1);
   END;
   xOld := xNew; yOld := yNew;
   xMoonOld := xMoonNew; yMoonOld := yMoonNew;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScale;
CONST
   RBNames : string = '12345678';
VAR
   Input             : TInputScreen;

BEGIN
   WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.23, 0.77, 0.29, 0.71);
         LoadLine('');
         LoadLine('     Enter extreme limits for display:');
         LoadLine('  xLow = {       }   xHigh = {       }');
         LoadLine('  yLow = {       }   yHigh = {       }');
         LoadLine('');
         LoadLine('     Keep running where you stopped: #1');
         LoadLine(' Start again from the parking orbit: #1');
         LoadLine('');
         LoadLine('                 [  OK  ]');
         SetNumber(1, xLow);
         SetNumber(2, xHigh);
         SetNumber(3, yLow);
         SetNumber(4, yHigh);
         IF ReRun THEN SetRadioButton(RBNames[1], 2)
                  ELSE SetRadioButton(RBNames[1], 1);
         REPEAT
            AcceptScreen;
            xLow := GetNumber(1);
            xHigh := GetNumber(2);
            yLow := GetNumber(3);
            yHigh := GetNumber(4);
            IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
               Announce('You have confused upper and lower limits. Try again.');
         UNTIL (xLow < xHigh) AND (yLow < yHigh);
         IF GetRadioButton(RBNames[1]) = 1 THEN
         ReRun := False ELSE ReRun := True;
         Done;
      END;
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   SetDisplayOptions;
   IF ReRun THEN SetUpOrbit ELSE SetUpOrbit2;
   {BEGIN
      y[1] := ParkingRadius*sin(InitialAngle);
      y[2] := - ParkingRadius*cos(InitialAngle);
      y[3] := InitialSpeed*cos(InitialAngle)*0.9834;
      y[4] := InitialSpeed*sin(InitialAngle)*0.9834;
   END;}
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
          1: ShowHelp('HelpAstr.hlp', 'CometHotKeysHelp');
          2: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Action := True;
               WITH HotKeys DO Key[2] := 'F2-Stop';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
         END;
      3: IF Lag > DelLag THEN Lag := Lag - DelLag;
      4: Lag := Lag + DelLag;
      5: BEGIN
            IF Action THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            FindScale;
            {SetDisplayOptions;
            SetUpOrbit;}
         END;
      6: BEGIN
            PlotOrbit := False;
            Action := False;
            HotKeys.Clear;
           { ClearMuppetPort; }
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleMoonMenu;
BEGIN
   With MoonMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: ShowHelp('HelpAstr.hlp', 'MoonAboutProgram');
            2: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpAstr.Hlp', 'MoonAboutModel');
            2: BEGIN
                  ShowHelp('WalkThru.hlp', 'Moon1');
                  ShowHelp('WalkThru.hlp', 'Moon2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  ShowParameters;
                  IF GetMoonData THEN
                  BEGIN
                     SetDisplayOptions;
                     SetUpOrbit;
                  END
                  ELSE
                     BEGIN
                        ClearMuppetPort;
                        LightMenu := True;
                     END;
               END;
            2: BEGIN
                  y[1] := ParkingRadius*sin(InitialAngle);
                  y[2] := - ParkingRadius*cos(InitialAngle);
                  y[3] := InitialSpeed*cos(InitialAngle)*0.9834;
                  y[4] := InitialSpeed*sin(InitialAngle)*0.9834;
                  SetUpOrbit;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   ExitRequest := False;
   Lightmenu := True;
   DefineViewPort(1, 0.1, 0.9, 0.1, 0.9);
   DefineViewPort(4, 0.05, 0.33, 0.64, 0.9);
   {DefineViewPort(4, 0.36, 0.64, 0.53, 0.79);}
   xLow := - 1.5;
   xHigh := 1.5;
   yLow := - 1.5;
   yHigh := 1.5;
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   DefineScale(4, -0.05, 0.05, -0.06, 0.06);
   Lag := 200;
   ParkingRadius := 0.02;
   InitialSpeed := 11;
   AngleDegrees := - 40;
   InitialAngle := AngleDegrees*Pi/180;
   MoonMass := 0.0123;
   Altitude := 100;
   ParkingRadius := (Altitude + 6378)/384400;
   MeanMotion := sqrt(1+MoonMass);
      y[1] := ParkingRadius*sin(InitialAngle);
      y[2] := - ParkingRadius*cos(InitialAngle);
      y[3] := InitialSpeed*cos(InitialAngle)*0.9834;
      y[4] := InitialSpeed*sin(InitialAngle)*0.9834;
   JoinTimes := False;
   ReRun := False;
   DelTimeHours := 12;
   {Hours := Time*27.321662*24/(2*Pi);}
   DelTime := DelTimeHours*(2*Pi)/(27.321662*24);
   Hello('HelpAstr.hlp', 'MoonAboutProgram');
   SetUpMoonMenu;
   SetUpHotKeys;
{   ShowParameters;
   IF GetMoonData THEN
   BEGIN
      SetDisplayOptions;
      SetUpOrbit
   END
   ELSE
   BEGIN
      ClearMuppetPort;
      LightMenu := True;
   END;   }
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF PLotOrbit AND Action THEN StepOrbit;
      IF LightMenu THEN IF MoonMenu.Chosen THEN HandleMoonMenu
   UNTIL ExitRequest;
   MoonMenu.Done;
   CUPSDone;
END.




