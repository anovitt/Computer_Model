Program DescentOfSkylab;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 4;

type
   vector = array[1..neq] of real;

var
   y                           : Vector;
   SkylabMenu                  : TMenu;
   HotKeys                     : THotKeys;
   EarthRadius, AltScale, Mu   : Real;
   CrossSection, Mass          : Real;
   Time, StepSize              : Real;
   Drag                        : Real;
   Lag                         : Integer;
   PlotOrbit, Action           : Boolean;
   ExitRequest                 : Boolean;
   LightMenu                   : Boolean;
   Trail                       : Boolean;
   AltitudePlot                : Boolean;
   xTrail, yTrail              : Array[1..10] OF Real;
   nTrail                      : Integer;
   Key                         : Byte;
   xIn, yIn, xvIn, yvIn        : Real;
   CD                          : Real;
   SmAxis                      : Real;
   MaxDistance                 : Real;
   Period                      : Real;
   R, VS                       : Real;
   ScreenRatio                 : Real;

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

PROCEDURE SetUpSkylabMenu;
VAR
   I      : Integer;
BEGIN
   With SkylabMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About the program');
       row(1,2, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'The model');
       row(2,2, 'Atmospheric drag');
       row(2,3, 'Velocity of escape');
       row(2,4, 'Running the program');
       row(2,5, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Parameters and Initial conditions');
       row(3,2, 'See animation');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   SkylabMenu.Display;
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
      Key[5] := 'F5-NoTrail';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
END;

{-------------------------------------------------------------------------}

FUNCTION GetSkylabData : Boolean;
VAR
   SkylabDat: TInputScreen;
   R, VS    : Real;
BEGIN
   ClearMuppetPort;
   WITH SkylabDat DO
   BEGIN
      Init;
      DefineInputPort(0.11, 0.89, 0.06, 0.94);
      LoadLIne('');
      LoadLine('              Data for the Descent of SkyLab');
      LoadLine('');
      LoadLIne(' Enter the cross-sectional area: {       } square meters');
      LoadLine('            Enter the mass: 1 <= {       } kg');
      LoadLine(' Enter the drag coefficient:');
      LoadLine('                        0 < CD = {       } <= 2');
      LoadLine('');
      LoadLine(' The radius of the Earth is 6378km. The initial altitude');
      LoadLine(' must exceed 10 km. x and y cannot exceed 10,000 km');
      LoadLine(' Initial coordinates: x = {       },  y = {       } km');
      LoadLine('   Initial velocity: vx = {       }, vy = {       } km/sec');
      LoadLine('');         
      LoadLine(' On the screen a dotted line will appear at altitude');
      LoadLine(' 100 km. Enter a scale factor for exaggerating the');
      LoadLIne(' altitude:                  1 <= {       } <= 100');
      LoadLine(' Note: This will distort the observed geometrical shape of');
      LoadLine('       the orbit.');
      LoadLine('');
      LoadLIne('           [ Help ]        [  OK  ]       [Cancel]');
      SetHelpFile('HelpAstr.Hlp', 'SkyLabInputHelp');
      SetNumber(1, CrossSection);
      SetNumberLimits(1, 0.00001, 100000);
      SetNumber(2, Mass);
      SetNumberLimits(2, 1, 1000000);
      SetNumber(3, CD);
      SetNumberLimits(3, 0.00001, 2);
      SetNumber(4, xIn);
      SetNumberLimits(4, 0, 10000);
      SetNumber(5, yIn);
      SetNumberLimits(5, 0, 10000);
      SetNumber(6, xvIn);
      SetNumber(7, yvIn);
      SetNumber(8, AltScale);
      SetNumberLimits(8, 1, 100);
      REPEAT
         AcceptScreen;
         GetSkyLabData := NOT Canceled;
         IF Canceled THEN BEGIN Done; Exit; END;
         CrossSection := GetNumber(1);
         Mass := GetNumber(2);
         CD := GetNumber(3);
         y[1] := GetNumber(4);
         y[2] := GetNumber(5);
         y[3] := GetNumber(6);
         y[4] := GetNumber(7);
         xIn := y[1];
         yIn := y[2];
         xvIn := y[3];
         yvIn := y[4];
         AltScale := GetNumber(8);
         Drag := cd*CrossSection*1000000.0/(2*Mass);
         R := Sqrt(y[1]*y[1] + y[2]*y[2]);
         VS := y[3]*y[3] + y[4]*y[4];
         IF R > 0 THEN SmAxis := 1/(2/R - VS/Mu);
         IF VS > 0.81*2*Mu/R THEN
            Announce('You are over or too close to the escape velocity. Try again');
         IF R <= EarthRadius+10 THEN
            Announce('You have put Skylab underground! Try again');
      UNTIL (R > EarthRadius+10) AND (SmAxis > 0);
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE AtmosphericDensity(Altitude: Real; VAR Density: Real);
var
   nc: integer;
   dalt: real;
begin
   nc := Trunc(Altitude/10.0);
   dalt := Altitude/10 - nc;
   Case nc of
   10:  Density := 5.67E-7 - dalt*4.75E-7;
   11:  Density := 9.72E-8 - dalt*7.46E-8;
   12:  Density := 2.26E-8 - dalt*1.46E-8;
   13:  Density := 7.97E-9 - dalt*4.31E-9;
   14:  Density := 3.66E-9 - dalt*1.67E-9;
   15:  Density := 1.99E-9 - dalt*0.78E-9;
   16:  Density := 1.21E-9 - dalt*0.43E-9;
   17:  Density := 7.84E-10 - dalt*2.50E-10;
   18:  Density := 5.34E-10 - dalt*1.58E-10;
   19:  Density := 3.76E-10 - dalt*1.04E-10;
   20:  Density := 2.72E-10 - dalt*0.72E-10;
   21:  Density := 2.00E-10 - dalt*0.50E-10;
   22:  Density := 1.50E-10 - dalt*0.36E-10;
   23:  Density := 1.14E-10 - dalt*0.27E-10;
   24:  Density := 8.74E-11 - dalt*1.95E-11;
   25:  Density := 6.79E-11 - dalt*1.47E-11;
   26:  Density := 5.32E-11 - dalt*1.12E-11;
   27:  Density := 4.20E-11 - dalt*0.86E-11;
   28:  Density := 3.34E-11 - dalt*0.66E-11;
   29:  Density := 2.68E-11 - dalt*0.52E-11;
   30:  Density := 2.16E-11 - dalt*0.41E-11;
   31:  Density := 1.75E-11 - dalt*0.33E-11;
   32:  Density := 1.42E-11 - dalt*0.26E-11;
   33:  Density := 1.16E-11 - dalt*0.21E-11;
   34:  Density := 9.53E-12 - dalt*1.68E-12;
   35:  Density := 7.85E-12 - dalt*1.37E-12;
   36:  Density := 6.48E-12 - dalt*1.11E-12;
   37:  Density := 5.37E-12 - dalt*0.90E-12;
   38:  Density := 4.47E-12 - dalt*0.75E-12;
   39:  Density := 3.72E-12 - dalt*0.61E-12;
   end;
end;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
VAR
   r, rrr, v, Density, Altitude: Real;
begin
   r := sqrt(y[1]*y[1] + y[2]*y[2]);
   rrr := r*r*r;
   v := sqrt(y[3]*y[3] + y[4]*y[4]);
   z[1] := y[3]; z[2] := y[4];
   Altitude := r - EarthRadius;
   if Altitude < 90 then Density := 0.001225*exp(- 0.1385*Altitude)
  { else BEGIN AtmosphericDensity(Altitude, Density);
   Density := Density/1000.0; END; }
   ELSE Density := 0.0007133/exp(4.411*ln(Altitude - 75.05));
   {18.739/exp(4.411*ln(10.01*Altitude-751.44));}
   z[3] := - mu*y[1]/rrr - drag*Density*v*y[3];
   z[4] := - mu*y[2]/rrr - drag*Density*v*y[4];
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
      temax := Tol/100000;
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

PROCEDURE FindScale;
VAR
   Distance               : Real;
   ScaledDistance         : Real;
   DelY                   : Real;
   WaitMessage            : TWaitMessage;
BEGIN
   Period := 2*Pi*Sqrt(Smaxis*SmAxis*SmAxis/Mu);
   Time := 0;
   StepSize := 1;
   MaxDistance := 6500;
   y[1] := xIn; y[2] := yIn; y[3] := xvIn; y[4] := yvIn;
   Message('                Finding a scale for the figure');
   {WaitMessage.Show;}
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      {WaitMessage.UpDate;}
      Distance := Sqrt(y[1]*y[1] + y[2]*y[2]);
      IF Distance > MaxDistance THEN MaxDistance := Distance;
   UNTIL (Time > Period) OR (Distance < EarthRadius);
   {WaitMessage.Hide;}
   Message('');
   ScaledDistance := 1 + AltScale*(MaxDistance/EarthRadius - 1);
   DelY := 1.1*(MaxDistance/EarthRadius)*ScaledDistance;
   DefineScale(1, -DelY*ScreenRatio, DelY*ScreenRatio, -DelY, DelY);
   Time := 0;
   StepSize := 1;
   y[1] := xIn; y[2] := yIn; y[3] := xvIn; y[4] := yvIn;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotSkylab(Sx, Sy  : Real; SColor: Word);
VAR
   Distance, ScaledDistance, DistanceRatio, xSkylab, ySkylab: Real;
   I, J, xPC, yPC, xP, yP                                   : Integer;
BEGIN
   Distance := Sqrt(Sx*Sx + Sy*Sy);
   ScaledDistance := EarthRadius + AltScale*(Distance - EarthRadius);
   DistanceRatio := 1 + AltScale*(Distance/EarthRadius - 1);
   xSkylab := DistanceRatio*Sx/EarthRadius;
   ySkylab := DistanceRatio*Sy/EarthRadius;
  { SetColor(SColor);
   PlotSymbol(xSkylab, ySkylab, 'o');}
   Map(xSkyLab, ySkyLab, xpc, ypc);
   FOR I := 1 TO 3 DO
   BEGIN
      xp := xpc-2+I;
      FOR J := 1 TO 3 DO
      BEGIN
          yp := ypc-2+J;
          PutPixel(xp, yp, SColor);
      END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE PrintTime(Time: Real);
VAR
   Minutes, Hours, Days     : Integer;
   TimeStr, DayStr, HourStr : String;
   xSc, ySc                 : Integer;
   StoreColor               : Word;
BEGIN
   StoreColor := GetColor;
   SetColor(White);
   Minutes := Trunc(Time/60);
   Hours := Trunc(Minutes/60);
   IF Hours >= 1 THEN Minutes := Minutes - 60*Hours;
   Days := Trunc(Hours/24);
   IF Days >= 1 THEN Hours := Hours - 24*Days;
   IF (Days > 0) OR (Minutes = 0)  THEN
   BEGIN
      rubOut(1,20,5,black);
      print (1,20,NumStr(Days,3,0));
   END;
   rubOut(10,20,7,black);
   print (12,20,NumStr(TRUNC(Hours),3,0));
   rubOut(22,20,7,black);
   print (24,20,NumStr(Minutes,3,0));
   SelectViewPort(1);
   SetColor(StoreColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
   xSc1, ySc1, xSc2, ySc2, Radius: Integer;
   Distance, ScaledDistance: Real;
   TimeStr: String;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   HotKeys.BackColor := Red;
   WITH HotKeys DO Key[2] := 'F2-Run';
   WITH HotKeys DO Key[5] := 'F5-NoTrail';
   Trail := False;
   HotKeys.Display;
   SetFillStyle(SolidFill, Blue);
   SetColor(Blue);
   Map(0, 0, xSc1, ySc1);
   Map(1, 0, xSc2, ySc2);
   Radius := xSc2 - xSc1;
   IF Radius < 5 THEN Radius := 5;
   FillEllipse(xSc1, ySc1, Radius, Radius);
   SetLineStyle(DashedLn, 0, NormWidth);
   SetColor(LightRed);
   Map(1 + 100*AltScale/EarthRadius, 0, xSc2, ySc2);
   Radius := xSc2 - xSc1;
   IF Radius < 6 THEN Radius := 6;
   Circle(xSc1, ySc1, Radius);
   SetLineStyle(SolidLn, 0, NormWidth);
   Print(5, 2, 'Altitude 100 km _____');
   PlotSkylab(y[1], y[2], Yellow);
   GraphBackColor := DarkGray;
   SelectViewPort(1);
   TimeStr := ('     days       hours       minutes');
      print(1,20,TimeStr);
   PrintTime(0);
   ShowCursor;
   LightMenu := False;
   Time := 0;
   StepSize := 1;
   PlotOrbit := True;
   Action := False;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotAltitude;
VAR
   TimeMax : Real;
   xOld, yOld, xNew, yNew      : Real;
   r, Sqv, SMAxis, SqAMomentum, ApoGee: Real;
   TimeStr, AltStr: String;
   MaxX, Maxy: LongInt;
   xSc, ySc: Integer;
BEGIN
   r := Sqrt(xIn*xIn + yIn*yIn);
   Sqv := xvIn*xvIn + yvIn*yvIn;
   SqAmomentum := Sqr(xIn*yvIn - yIn*xvIn);
   SMAxis := 1/(2/r - Sqv/mu);
   ApoGee := SMAxis*(1 + Sqrt(1 - SqAMomentum/(mu*SMAxis))) - EarthRadius;
   TimeMax := Time;
   MaxX := 1 + Trunc(TimeMax/3600);
   MaxY := 10 + 10*Trunc((MaxDistance-EarthRadius)/10);
   DefineScale(2, -0.05*MaxX, 1.05*MaxX, -0.1*MaxY, 1.1*MaxY);
   OpenViewPort(2);
   SelectScale(2);
   SetColor(Yellow);
   HideMouse;
   PlotLine(0, 0, MaxX, 0);
   PlotLine(0, 0, 0, MaxY);
   Map(MaxX, 0, xSc, ySc);
   Str(MaxX, TimeStr);
   PrintXY(0.88, 0.13, TimeStr);
  { OutTextxy(xSc-10, ySc+10, TimeStr); }
   PlotLine(MaxX, 0, MaxX, MaxY/50);
   PrintXY(0.8, 0.1, 'Time  Hours');
  { OutTextxy(xSc-70, ySc+20, 'Time  Hours');}
   Map(0, MaxY, xSc, ySc);
   Str(MaxY, AltStr);
  { OutTextxy(xSc+10, ySc, AltStr); }
   PrintXY(0.11, 0.87, AltStr);
   PlotLine(0, MaxY, MaxX/100, MaxY);
   PrintXY(0.07, 0.9, 'Altitude Km');
  { OutTextxy(xSc-10, ySc-20, 'Altitude  Km '); }
   Time := 0;
   StepSize := 1;
   xOld := 0;
   yOld := r - EarthRadius;
   y[1] := xIn; y[2] := yIn; y[3] := xvIn; y[4] := yvIn;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      xNew := Time/3600;
      yNew := Sqrt(y[1]*y[1] + y[2]*y[2]) - EarthRadius;
      IF yNew > 0 THEN PlotLIne(xOld, yOld, xNew, yNew);
      xOld := xNew;
      yOld := yNew;
   UNTIL (yNew < 0) OR (Time > TimeMax);
   LightMenu := True;
   ShowMouse;
END;

{-------------------------------------------------------------------------}
PROCEDURE QueryAltitudePlot;

PROCEDURE AskAltitudePlot;
CONST
   RBNames: String = '12345';
VAR
   QueryAlt: TInputScreen;
BEGIN
   WITH QueryAlt DO
   BEGIN
      Init;
      DefineInputPort(0.27, 0.73, 0.8, 0.9);
      LoadLine(' See altitude plot? Yes #1  No #1');
      IF AltitudePlot THEN SetRadioButton(RBNames[1], 1)
                      ELSE SetRadioButton(RBNames[1], 2);
      LoadLine('       [  OK  ]   [Cancel]');
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN AltitudePlot := True
                                        ELSE AltitudePlot := False;
      IF Canceled THEN AltitudePlot := False;
      Done;
   END;
END;

BEGIN
   AskAltitudePlot;
   IF ALtitudePlot THEN PlotAltitude
                   ELSE LightMenu := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawTrail;
VAR
   i     : Integer;
   Distance, ScaledDistance, DistanceRatio, xSkylab, ySkylab: Real;
BEGIN
   Distance := Sqrt(y[1]*y[1] + y[2]*y[2]);
   ScaledDistance := EarthRadius + AltScale*(Distance - EarthRadius);
   DistanceRatio := ScaledDistance/EarthRadius;
   xSkylab := DistanceRatio*y[1]/EarthRadius;
   ySkylab := DistanceRatio*y[2]/EarthRadius;
   IF nTrail < 10 THEN
   BEGIN
      nTrail := nTrail + 1;
      xTrail[nTrail] := xSkyLab;
      yTrail[nTrail] := ySkyLab;
   END
   ELSE
   BEGIN
      FOR i := 1 TO 9 DO
      BEGIN
         xTrail[i] := xTrail[i+1];
         yTrail[i] := yTrail[i+1];
      END;
      xTrail[10] := xSkyLab;
      yTrail[10] := ySkyLab;
   END;
   SetColor(LightGray);
   FOR i := 1 TO nTrail-1 DO
      PlotLine(xTrail[i], yTrail[i], xTrail[i+1], yTrail[i+1]);
END;

{-------------------------------------------------------------------------}

PROCEDURE StepOrbit;
VAR
   SaveX, SaveY     : Real;
BEGIN
   Delay(Lag);
   SaveX := y[1];
   SaveY := y[2];
   Step(Time, Stepsize, 0.00001, y, Time, StepSize, y);
   PlotSkyLab(SaveX, SaveY, Black);
   PlotSkylab(y[1], y[2], Yellow);
   IF Trail THEN DrawTrail;
   PrintTime(Time);
   IF y[1]*y[1] + y[2]*y[2] < EarthRadius*EarthRadius THEN
   BEGIN
      IF Trail THEN ShowMouse;
      PlotOrbit := False;
      HotKeys.Clear;
      QueryAltitudePlot;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
   CASE Key OF
      1: ShowHelp('HelpAstr.Hlp', 'SkyLabHotKeysHelp');
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
            IF Trail THEN
            BEGIN
               Trail := False;
               ShowMouse;
               WITH HotKeys DO Key[5] := 'F5-NoTrail';
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Trail := True;
               nTrail := 0;
               HideMouse;
               WITH HotKeys DO Key[5] := 'F5-Trail';
               HotKeys.Display;
            END;
         END;
      6: BEGIN
            PlotOrbit := False;
            Action := False;
            ClearMuppetPort;
            IF Trail THEN ShowMouse;
            IF Time > 5000 THEN
            QueryAltitudePlot ELSE LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSkylabMenu;
BEGIN
   With SkylabMenu DO
      CASE ColChosen OF
         1: CASE RowChosen OF
               1: ShowHelp('HelpAstr.Hlp', 'SkyLabAboutProgram');
               2: AboutCUPS;
               3: Configuration;
               4: ExitRequest := True;
            END;
         2: CASE RowChosen OF
               1: ShowHelp('HelpAstr.Hlp', 'SkyLabAboutModel');
               2: BEGIN
                     ShowHelp('HelpAstr.Hlp', 'SkyLabDragHelpA');
                     ShowHelp('HelpAstr.Hlp', 'SkyLabDragHelpB');
                  END;
               3: ShowHelp('HelpAstr.Hlp', 'SkyLabEscapeHelp');
               4: BEGIN
                     ShowHelp('HelpAstr.Hlp', 'SkyLabRunProgramA');
                     ShowHelp('HelpAstr.Hlp', 'SkyLabRunProgramB');
                  END;
               5: BEGIN
                     ShowHelp('WalkThru.Hlp', 'SkyLab1');
                     ShowHelp('WalkThru.Hlp', 'SkyLab2');
                     ShowHelp('WalkThru.Hlp', 'SkyLab3');
                  END;
            END;
         3: CASE RowChosen OF
               1: IF NOT GetSkyLabData
                  THEN LightMenu := True
                       ELSE
                       BEGIN
                          IF SmAxis <= 0 THEN
                          BEGIN
                             Announce('Hyperbolic orbit. Speed too high.');
                             LightMenu := True;
                          END
                          ELSE
                          BEGIN
                             FindScale;
                             SetUpPicture;
                          END;
                       END;
               2: BEGIN FindScale; SetUpPicture; END;
         END;
      END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
VAR
   xAsp, yAsp     : Word;
BEGIN
   ExitRequest := False;
   LightMenu := True;
   AltitudePlot := True;
   DefineViewPort(1, 0.07, 0.93, 0.07, 0.93);
   {DefineScale(1, -28/5, 28/5, -4, 4);}
   GetAspectRatio(xAsp, yAsp);
   ScreenRatio := (yAsp/xAsp)*(GetMaxX/GetMaxY);
   DefineScale(1, -4*ScreenRatio, 4*ScreenRatio, -4, 4);
   DefineViewPort(2, 0.05, 0.95, 0.07, 0.93);
   cd := 1; {Drag coefficient.}
   mu := 398618.0; {Mass of the Earth times the constant of gravitation.}
   EarthRadius := 6378; {Radius of the Earth in km.}
   Lag := 100;
   xIn := 6480;
   yIn := 0;
   xvIn := 0;
   yvIn := 7.9;
   y[1] := xIn;
   y[2] := yIn;
   y[3] := xvIn;
   y[4] := yvIn;
   Mass := 77000;
   CrossSection := 10;
   Drag := cd*CrossSection*1000000.0/(2*Mass);
   R := Sqrt(y[1]*y[1] + y[2]*y[2]);
   VS := y[3]*y[3] + y[4]*y[4];
   SmAxis := 1/(2/R - VS/Mu);
   AltScale := 50;
   Trail := False;
   SetUpHotKeys;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   GetSetUp;
   Hello('HelpAstr.Hlp', 'SkyLabAboutProgram');
   SetUpSkylabMenu;
   IF GetSkylabData THEN
   BEGIN
      IF SmAxis <= 0 THEN Announce('Hyperbolic orbit. Speed too high.')
      ELSE
      BEGIN
         FindScale;
         SetUpPicture;
      END;
   END;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF PlotOrbit AND Action THEN StepOrbit;
      IF LightMenu THEN
         IF SkyLabMenu.Chosen THEN HandleSkyLabMenu
   UNTIL ExitRequest;
   SkylabMenu.Done;
   CUPSDone;
END.




