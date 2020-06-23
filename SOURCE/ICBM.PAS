Program TheRangeOfAnICBM;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;


const
   neq = 4;

type
   vector = array[1..neq] of real;

var
   y, z                    : Vector;
   Time, StepSize          : Real;
   ICBMMenu                : TMenu;
   HotKeys                 : THotKeys;
   Sliders                 : TSliders;
   Key                     : Byte;
   CrossSection, Mass      : Real;
   EarthRadius, Mu         : Real;
   AltScale                : Real;
   Drag                    : Real;
   Height                  : Real;
   xOld, yOld              : Real;
   ElevationDeg            : Real;
   ElevationRad            : Real;
   Speed                   : Real;
   xLow, xHigh, yLow, yHigh: Real;
   Lag                     : Integer;
   PlotOrbit               : Boolean;
   ExitRequest             : Boolean;
   LightMenu               : Boolean;
   Accept                  : Boolean;
   HideICBM                : Boolean;

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

PROCEDURE SetUpICBMMenu;
VAR
   I      : Integer;
BEGIN
   With ICBMMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'The model');
       row(2,2, 'Atmospheric drag');
       row(2,3, 'Running the program');
       row(2,4, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Parameters');
       row(3,2, 'Animate');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   ICBMMenu.Display;
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Aim';
      Key[3] := 'F3-FIRE';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

FUNCTION GetICBMData : Boolean;
VAR
   ICBMData        : TInputScreen;
   cd: Real;
BEGIN
   WITH ICBMData DO
   BEGIN
      Init;
      DefineInputPort(0.61, 1, 0.1, 0.9);
      LoadLine('    Data for the Range ');
      LoadLine('       of an ICBM');
      LoadLine('');
      LoadLIne('Enter the cross-sectional ');
      LoadLine('area:     A =  {       } m^2');
      LoadLine('');
      LoadLine('Enter the mass:');
      LoadLine('          M =  {       } kg');
      LoadLine('');
      LoadLine('  Enter the altitude at ');
      LoadLine('launch: Alt =  {       } km');
      LoadLine('On the screen a dotted line ');
      LoadLine('will appear at altitude 100');
      LoadLine('km. Enter a scale factor ');
      LoadLIne('exaggerating the altitude:');
      LoadLine('Less than 100) {       }');
      LoadLine('');
      LoadLIne('     [  OK  ]    [Cancel]');
      SetNumber(1, CrossSection);
      SetNumberLimits(1, 0.00001, 10000);
      SetNumber(2, Mass);
      SetNumberLimits(2, 0, 10000000);
      SetNumber(3, Height);
      SetNumberLimits(3, 0, 100);
      SetNumber(4, AltScale);
      SetNumberLimits(4, 1, 100);
      AcceptScreen;
      GetICBMData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         CrossSection := GetNumber(1);
         Mass := GetNumber(2);
         Height := GetNumber(3);
         AltScale := GetNumber(4);
         cd := 1; {Drag coefficient.}
         mu := 398618.0; {Mass of the Earth times the constant of gravitation.}
         Drag := cd*CrossSection*1000000.0/(2*Mass);
         EarthRadius := 6387.388; {Radius of the Earth in km.}
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE ShowParameters;
VAR
   Radius       : Integer;
BEGIN
   DefineViewPort(5, 0.05, 0.6, 0.1, 0.9);
   DefineScale(5, -2, 10, -4, 10);
   GraphBackColor := DarkGray;
   OpenViewPort(5);
   SelectScale(5);
   Message('');
   SetColor(White);
   Radius := MapX(5) - MapX(0);
   SetColor(DarkGray);
   SetFillStyle(WideDotFill, LightGray);
   PieSlice(MapX(0), MapY(0), 0, 90, Radius);
   SetColor(White);
   Arc(MapX(0), MapY(0), 0, 90, Radius);
   SetColor(LightGray);
   SetLineStyle(DashedLn, 0, NormWidth);
   Radius := MapX(6.75) - MapX(0);
   Arc(MapX(0), MapY(0), 0, 90, Radius);
   Line(MapX(0), MapY(0), MapX(8), MapY(8));
   {Line(MapX(7*0.707), MapY(7*0.707), MapX(2*0.707), MapY(12*0.707));}
   Line(MapX(12*0.707), MapY(2*0.707), MapX(2*0.707), MapY(12*0.707));
   Radius := Abs(MapY(5) - MapY(6.5));
   Arc(MapX(7*0.707), MapY(7*0.707), 105, 135, Radius);{41);}
   SetLineStyle(SolidLn, 0, NormWidth);
   Line(MapX(4.6), MapY(6.4), MapX(4.35), MapY(6.55));
   Line(MapX(4.6), MapY(6.4), MapX(4.5), MapY(6.0));
   SetLineStyle(SolidLn, 0, NormWidth);
   SetColor(White);
   Line(MapX(7*0.707), MapY(7*0.707), MapX(4), MapY(9));
   Line(MapX(4), MapY(9), MapX(3.6), MapY(8.5));
   Line(MapX(4), MapY(9), MapX(4.5), MapY(8.7));
   OutTextXY(MapX(3.9), MapY(9.5), 'V');
   OutTextXY(MapX(0.5), MapY(0), 'Center');
   OutTextXY(MapX(0), MapY(5), 'Earth');
   OutTextXY(MapX(4.3), MapY(4), 'Alt');
   OutTextXY(MapX(4.0), MapY(6.8), 'E');
   OutTextXY(MapX(5.4), MapY(5), 'P');
   OutTextXY(MapX(-1), MapY(-1), 'P is the point of blastoff');
   OutTextXY(MapX(-1), MapY(-1.5), 'Alt is the altitude of blastoff');
   OutTextXY(MapX(-1), MapY(-2), 'E is the elevation angle of blastoff');
   OutTextXY(MapX(-1), MapY(-2.5), 'V is the speed of blastoff');
   SetFillStyle(SolidFill, White);
   Radius := Trunc(2*GetMaxX/639);
   FillEllipse(MapX(0), MapY(0), Radius, Radius);
   FillEllipse(MapX(7*0.707), MapY(7*0.707), Radius, Radius);
   OutTextXY(MapX(7.5), MapY(3.5), 'Local');
   OutTextXY(MapX(7.5), MapY(3), 'horizon');
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
   ELSE Density := 18.739/exp(4.411*ln(10.01*Altitude-751.44));
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

Procedure GetCoordinates(xIn, yIn: Real; VAR xOut,yOut: Real);
VAR
   Distance, ScaledDistance, DistanceRatio, xICBM, yICBM: Real;
BEGIN
   Distance := Sqrt(xIn*xIn + yIn*yIn);
   ScaledDistance := EarthRadius + AltScale*(Distance - EarthRadius);
   DistanceRatio := ScaledDistance/EarthRadius;
   xOut := DistanceRatio*xIn/EarthRadius;
   yOut := DistanceRatio*yIn/EarthRadius;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotICBM(SColor: Word);
VAR
   Distance, ScaledDistance, DistanceRatio, xICBM, yICBM: Real;
   SaveColor  : Word;
BEGIN
   IF HideICBM THEN Exit;
   SaveColor := GetColor;
   Distance := Sqrt(y[1]*y[1] + y[2]*y[2]);
   ScaledDistance := EarthRadius + AltScale*(Distance - EarthRadius);
   DistanceRatio := ScaledDistance/EarthRadius;
   xICBM := DistanceRatio*y[1]/EarthRadius;
   yICBM := DistanceRatio*y[2]/EarthRadius;
   SetColor(SColor);
   PlotSymbol(xICBM, yICBM, 'o');
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE PrintTime(Time: Real);
VAR
   Minutes, Seconds: Integer;
   xSc, ySc: Integer;
BEGIN
   Seconds := Trunc(Time);
   Minutes := Trunc(Time/60);
   IF Minutes >=1 THEN Seconds := Seconds - 60*Minutes;
   SetColor(Yellow);
   rubOut(1,21,5,red);
   print (2,21,NumStr(Minutes,3,0));
   rubOut(13,21,5,red);
   print (15,21,NumStr(Seconds,3,0));
   SelectViewPort(1);
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
   xSc1, ySc1, xSc2, ySc2, RadiusX, RadiusY: Integer;
   Distance, ScaledDistance: Real;
   TimeStr: String;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   Axis(1000,1000,1,1);
   Message('  The altitude scale is increased by the factor '
             +NumStr(AltScale, 3, 0));
   LightMenu := False;
   SetUpHotKeys;
   Sliders.Create(1, 0, 20, Speed, 0.05, 0.2, 0.8, 2, '0', '20', 'V km/sec', True);
   Sliders.Create(2, 0, 90, ElevationDeg, 0.95, 0.2, 0.8, 2, '0', '90', 'Elev', True);
   Sliders.DrawAll;
   SetFillStyle(SolidFill, Blue);
   SetColor(Blue);
   Map(0, 0, xSc1, ySc1);
   Map(1, 0, xSc2, ySc2);
   RadiusX := xSc2 - xSc1;
   RadiusY := MapY(0) - MapY(1);
   FillEllipse(xSc1, ySc1, RadiusX, RadiusY);
   SetLineStyle(DashedLn, 0, NormWidth);
   SetColor(LightRed);
   Map(1 + 100*AltScale/EarthRadius, 0, xSc2, ySc2);
   RadiusX := xSc2 - xSc1;
   Map(0, 1 + 100*AltScale/EarthRadius, xSc2, ySc2);
   RadiusY := ySc1 - ySc2;
   Ellipse(xSc1, ySc1, 0, 360, RadiusX, RadiusY);
   SetLineStyle(SolidLn, 0, NormWidth);
   {PlotICBM(Yellow);}
   GraphBackColor := DarkGray;
   SelectViewPort(1);
   SetColor(Yellow);
   TimeStr := ('     Minutes      Seconds');
      print(1,21,TimeStr);
   {PrintTime(0); }
   PlotOrbit := False;
   Time := 0;
   StepSize := 1;
   PlotOrbit := False;
   xOld := 0;
   yOld := 0;
   y[1] := (EarthRadius + Height)*Cos(Pi/4);
   y[2] := (EarthRadius + Height)*Sin(Pi/4);
   y[3] := - Speed*Cos(ElevationRad + Pi/4);
   y[4] := Speed*Sin(ElevationRad + Pi/4);
   ShowCursor;
   Accept := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE PrintRange;
VAR
   RangeStr: String;
   RangeAngle, Range: Real;

{------------------------------------------------------------------------}

Function Atan2(si, co: real): real;
{Finds the angle between 0 and 2*Pi of which
the sine is proportional to si and the cosine is proportional to co.
equivalent to the FORTRAN function.}
VAR
   Pi: real;
begin
   Pi := 3.141592653589793;
   if si < 0 then
      begin
         if co = 0 then Atan2 := 1.5*Pi
         else
            if co > 0 then Atan2 := 2*Pi + ArcTan(si/co)
            else Atan2 := Pi + ArcTan(si/co);
      end
   else
      begin
         if co = 0 then Atan2 := Pi/2
                   else Atan2 := ArcTan(si/co);
         if co < 0 then Atan2 := Pi + ArcTan(si/co);
      end;
end;

{------------------------------------------------------------------------}

BEGIN
   RangeAngle := ATan2((-y[1]+y[2]), (y[1]+y[2]));
   Range := RangeAngle*EarthRadius;
   RangeStr := NumStr(Range, 5, 0);
   SetColor(Yellow);
   rubOutXY(0.4,0.8,18,Black);
   printXY(0.4, 0.8,'Range = ' + RangeStr + ' km');
   PlotOrbit := False;
   HotKeys.Key[3] := 'F3-Fire';
   HotKeys.BackColor := Red;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveOrbit;
VAR
   xNew, yNew: Real;
   xICBM, yICBM: Real;
BEGIN
   Delay(Lag);
   PlotICBM(Black);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   PlotICBM(Yellow);
   GetCoordinates(y[1], y[2], xNew, yNew);
   PlotLine(xOld, yOld, xNew, yNew);
   SetLineStyle(SolidLn, 0, NormWidth);
   SetColor(White);
   xOld := xNew; yOld := yNew;
   IF Time > 1 THEN PrintTime(Time);
   IF (y[1]*y[1] + y[2]*y[2] < EarthRadius*EarthRadius)
   OR  (y[1]*y[1] + y[2]*y[2] > 100*EarthRadius*EarthRadius) THEN
   BEGIN
      PlotOrbit := False;
      IF (y[1]*y[1] + y[2]*y[2] > 100*EarthRadius*EarthRadius) THEN
           Announce('I''ve escaped. Bye!');
      HotKeys.Key[3] := 'F3-Fire';
                HotKeys.BackColor := Red;
                HotKeys.Display;
                Accept := False;
   END;
   IF (y[1]*y[1] + y[2]*y[2] < EarthRadius*EarthRadius) THEN
   BEGIN
      xOld := 0;
      yOld := 0;
      SetColor(Green);
      SetLineStyle(DashedLn, 0, NormWidth);
      PlotLine(xNew, yNew, xOld, yOld);
      SetColor(White);
      SetLineStyle(SolidLn, 0, NormWidth);
      PrintRange;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   Speed := Sliders.Value(1);
   ElevationDeg := Sliders.Value(2);
   ElevationRad := ElevationDeg*Pi/180;
   y[1] := (EarthRadius + Height)*Cos(Pi/4);
   y[2] := (EarthRadius + Height)*Sin(Pi/4);
   y[3] := - Speed*Cos(ElevationRad + Pi/4);
   y[4] := Speed*Sin(ElevationRad + Pi/4);
   xOld := 0;
   yOld := 0;
END;

{-------------------------------------------------------------------------}

PROCEDURE CleanUp;
CONST
   RBNames : string = '12345678';
VAR
   Input         : TInputScreen;
BEGIN
   Message('  The altitude scale is increased by the factor '
             +NumStr(AltScale, 3, 0));
   WITH Input DO
   BEGIN
      init;
      DefineInputPort (0.18, 0.82, 0.2, 0.75);
      LoadLine('');
      LoadLine('  Enter the extreme coordinates for the figure:');
      LoadLine('  Minimum x = {       }  Maximum x = {       }');
      LoadLine('  Minimum y = {       }  Maxumum y = {       }');
      LoadLine('');
      LoadLine('  Enter a new value for the scale factor for');
      LoadLine('  exaggerating the altitude:         {       }');
      LoadLine('');
      LoadLine('  To see more detail in the orbital path, would');
      LoadLine('  like to hide the ICBM?  No #1  Yes #1');
      LoadLine('');
      LoadLine('                   [  Ok  ]      ');
      SetNumber(1, xLow);
      SetNumber(2, xHigh);
      SetNumber(3, yLow);
      SetNumber(4, yHigh);
      SetNumber(5, AltScale);
      SetNumberLimits(5, 1, 100);
      IF HideICBM THEN
         SetRadioButton('1', 2) ELSE SetRadioButton('1', 1);
      REPEAT
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         yLow := GetNumber(3);
         yHigh := GetNumber(4);
         AltScale := GetNumber(5);
         IF GetRadioButton(RBNames[1]) = 1 THEN
         HideICBM := False ELSE HideICBM := True;
         IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
                  Announce('You have confused upper and lower limits. Try again.');
      UNTIL (xLow < xHigh) AND (yLow < yHigh);
      Done;
   END;
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   SetUpPicture;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
BEGIN
   CASE Key OF
       1: ShowHelp('HelpAstr.Hlp', 'ICBMHotKeysHelp');
       2: BEGIN
             IF PlotOrbit THEN Exit;
             IF HotKeys.Key[2] = 'F2-Aim' THEN
             BEGIN
                Accept := False;
                Message('Use the sliders to aim the missile. Press <F2-Accept> when done');
                HotKeys.BackColor := Green;
                HotKeys.Key[2] := 'F2-Accept';
                HotKeys.Display;
                PlotOrbit := False;
             END
             ELSE
             BEGIN
                Accept := True;
                HotKeys.BackColor := Red;
                HotKeys.Key[2] := 'F2-Aim';
                HotKeys.Display;
                Message('');
                y[1] := (EarthRadius + Height)*Cos(Pi/4);
                y[2] := (EarthRadius + Height)*Sin(Pi/4);
                y[3] := - Speed*Cos(ElevationRad + Pi/4);
                y[4] := Speed*Sin(ElevationRad + Pi/4);
                xOld := 0;
                yOld := 0;
             END;
            { IF NOT Accept THEN
             BEGIN
                Accept := True;
                HotKeys.BackColor := Red;
                HotKeys.Key[2] := 'F2-Aim';
                HotKeys.Display;
                Message('');
             END
             ELSE
             BEGIN
                Accept := False;
                Message('Use the sliders to aim the missile. Press <F2-Accept> when done');
                HotKeys.BackColor := Green;
                HotKeys.Key[2] := 'F2-Accept';
                HotKeys.Display;
                PlotOrbit := False;
             END;   }
          END;
       3: BEGIN
             IF NOT Accept THEN
                BEGIN
                   Announce('Please re-aim');
                   Exit;
                END;
             IF PlotOrbit THEN
             BEGIN
                PlotOrbit := False;
                HotKeys.Key[3] := 'F3-Fire';
                HotKeys.BackColor := Red;
                HotKeys.Display;
                Accept := False;
                xOld := 0;
                yOld := 0;
                SetColor(Green);
                SetLineStyle(DottedLn, 0, NormWidth);
             END
             ELSE
             BEGIN
                PlotOrbit := True;
                HotKeys.Key[3] := 'F3-Abort';
                HotKeys.BackColor := Blue;
                HotKeys.Display;
                Message('      The altitude scale is increased by the factor '
                        +NumStr(AltScale, 3, 0));
                SetColor(Green);
                SetLineStyle(DottedLn, 0, NormWidth);
             END;
          END;
       4: CleanUp;
       5: BEGIN
            PlotOrbit := False;
            HotKeys.Clear;
            LightMenu := True;
          END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleICBMMenu;
BEGIN
   With ICBMMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpAstr.hlp', 'ICBMAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpAstr.hlp', 'ICBMAboutModel');
            2: ShowHelp('HelpAstr.hlp', 'ICBMDragHelp');
            3: BEGIN
                  ShowHelp('HelpAstr.hlp', 'ICBMRunProgramA');
                  ShowHelp('HelpAstr.hlp', 'ICBMRunProgramB');
               END;
            4: ShowHelp('WalkThru.hlp', 'ICBM');
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  ShowParameters;
                  IF GetICBMData THEN SetUpPicture
                   ELSE ClearMuppetPort;
               END;
            2: SetUpPicture;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   ExitRequest := False;
   DefineViewPort(1, 0.15, 0.85, 0.1, 0.9);
   xLow := -5;
   xHigh := 5;
   yLow := -2;
   yHigh := 6;
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   Lag := 100;
   CrossSection := 0.1;
   Mass := 1000;
   EarthRadius := 6387.388;
   mu := 398618.0;
   Height := 5;
   AltScale := 25;
   ElevationDeg := 30;
   ElevationRad := ElevationDeg*Pi/180;
   Speed := 7;
   Drag := CrossSection*1000000.0/(2*Mass);
   y[1] := (EarthRadius + Height)*Cos(Pi/4);
   y[2] := (EarthRadius + Height)*Sin(Pi/4);
   y[3] := - Speed*Cos(ElevationRad + Pi/4);
   y[4] := Speed*Sin(ElevationRad + Pi/4);
   Sliders.Init;
   LightMenu := True;
   HideICBM := False;
   Hello('HelpAstr.hlp', 'ICBMAboutProgram');
   SetUpICBMMenu;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF Hotkeys.Pressed(Key) THEN
                  HandleHotKeys(Key);
      IF (NOT Accept) AND Sliders.Changed THEN HandleSliders;
      IF PlotOrbit THEN MoveOrbit;
      IF LightMenu THEN IF ICBMMenu.Chosen THEN HandleICBMMenu;
   UNTIL ExitRequest;
   ICBMMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




