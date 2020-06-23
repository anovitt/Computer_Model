PROGRAM  ViolinBowOnString;

USES Crt, Graph, CupsMUPP, CUPS, CupsGui;

CONST
   neq = 2;

TYPE
   vector = array[1..neq] of real;

VAR
   ViolinMenu             : TMenu;
   HotKeys                : THotKeys;
   Sliders                : TSliders;
   Key                    : Byte;
   y, z                   : Vector;
   y1Max, y1Min           : Real;
   StepSize               : Real;
   Time                   : Real;
   DelTime                : Real;
   FrictA, FrictB         : Real;
   FrictSign              : Real;
   MaxT                   : Real;
   Speed                  : Real;
   RelativeSpeed          : Real;
   SprConst               : Real;
   xOld, yOld             : Real;
   SpokeAngle             : Real;
   XScaleFactor           : Real;
   Lag                    : Integer;
   Stretch                : Boolean;
   ExitRequest            : Boolean;
   LightMenu              : Boolean;
   Playing                : Boolean;
   Pause                  : Boolean;
   FigureChanged          : Boolean;
   Tick                   : Array[1..10] OF Real;

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

{--------------------------------- Help ------------------------------------}

PROCEDURE HelpXY(x1,y1 : real; helpScr : HelpScrType);
VAR
   envir   : TEnvironment;
   image   : TImage;
   x,y,dx,dy,h,i,size,color : word;
BEGIN
   envir.Save;
   envir.Standardize;
   ClearMKBuffers;
   SetRGBPalette(green, $00, $18, $7);
   SetFillStyle(SolidFill,green);
   SetLineStyle(solidLn, 0,thickWidth);
   dx := round(0.5*GetMaxX);
   IF GraphMode=VGAMed THEN dy:= round(0.88 *GetMaxY)
   ELSE dy:= round(0.64 *GetMaxY);
   x := round(x1*GetMaxX);
   y := round(y1*GetMaxY);
   IF (x<0) OR (x+dx>GetMaxX) THEN x := (GetMaxX-dx) DIV 2;
   IF (y<0) OR (y+dy>GetMaxY) THEN y := (GetMaxY-dy) DIV 2;
   SetViewPort(x, y, x+dx, y+dy, clipOn);
   HideMouse;
   image.get(0,0,dx,dy);
   Bar(0,0,dx,dy);
   rectangle(1,1,dx-1,dy-1);
   h := 3 * TextHeight('O') DIV 2;
   FOR i := 1 TO 25 DO OutTextXY(5,(i-1)*h + 5, helpScr[i]);
   ShowMouse;
   StaticPause;
   HideMouse;
   image.put(0,0);
   ClearMuppetPort;
   ShowMouse;
   ClearMKBuffers;
   SetRGBPalette(green, $00, $24, $00);
   envir.Reset;
END;

{---------------------------------------------------------------------------}

PROCEDURE HelpFriction;
CONST
   HelpScr: HelpScrType =
   ('                                       ',
    '                                       ',
    '              Dry Friction.            ',
    '                                       ',
    '    If two dry surfaces are incontact, ',
    '  then the force resisting the motion  ',
    '  of one relative to the other is      ',
    '  called "dry" of "Coulomb" friction.  ',
    '  a feature of this is that it is      ',
    '  usually greatest when the relative   ',
    '  speed is zero.                       ',
    '                                       ',
    '    Let this relative speed be z. The  ',
    '  model used un this program for the   ',
    '  friction is:                         ',
    '          F = (A + Bz)/(1 + z).        ',
    '  A and B are positive constants, and  ',
    '  A is greater than B. So, when the    ',
    '  surfaces are relatively at rest, the ',
    '  maximum frictional force is A. As    ',
    '  the relative speed increases, the    ',
    '  force approaches the limit B.        ',
    '                                       ',
    '   Click, or hit any key to continue.  ',
    '                                       ');
VAR
   i  : Integer;

FUNCTION FFrict(x : Real): Real;
BEGIN
   FFrict := (8 + 2*x)/(1 + x);
END;

BEGIN
   DefineViewPort(3, 0.55, 1, 0.16, 0.8);
   DefineScale(3, -2, 11, -1, 11);
   SelectScale(3);
   OpenViewPort(3);
   SetColor(Cyan);
   PlotLine(0, 0, 0, 10);
   PlotLine(0, 0, 10, 0);
   SetTextStyle(DefaultFont, VertDir, 1);
   PrintXY(0.59, 0.6, 'Frictional force');
   SetTextStyle(DefaultFont, HorizDir, 1);
   PrintXY(0.7, 0.2, 'Relative speed');
   SetLineStyle(DottedLn, 0, NormWidth);
   SetColor(Yellow);
   Line(MapX(0), MapY(2), MapX(10), MapY(2));
   SetLineStyle(SolidLn, 0, NormWidth);
   FOR i := 0 TO 19 DO
      PlotLine(i/2, FFrict(i/2), (i+1)/2, FFrict((i+1)/2));
   OutTextXY(MapX(-0.5), MapY(2), 'B');
   OutTextXY(MapX(-0.5), MapY(8), 'A');
   SetColor(White);
   HelpXY(0, 0.2, HelpScr);
   CloseViewPort(3);
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpViolinMenu;
VAR
   I      : Integer;
BEGIN
   With ViolinMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,2, 'About the program');
       row(1,1, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About dry friction');
       row(2,3, 'Walk-through');
      Column(3, 'Action');
       row(3,1, 'Enter parameters');
       row(3,2, 'See the animation');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   ViolinMenu.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Start';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-ReScale';
      Key[5] := 'F10-Exit';
   END;
   HotKeys.BackColor := Red;
END;

{------------------------------------------------------------------------}

FUNCTION GetParameters : Boolean;
VAR
   Input     : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.12, 0.88, 0.1, 0.9);
      LoadLine('');
      LoadLine('        The Action of a Violin Bow on the String');
      LoadLine('');
      LoadLine('     During the animation you will be able to change');
      LoadLine('  these numbers using sliders. The purpose of this');
      LoadLine('  screen is to allow you to enter precise values. Note');
      LoadLine('  that the units in this model are not specified.');
      LoadLine('');
      LoadLine('     The speed of the bow relative to the string:');
      LoadLine('                  0 < {       } < 10');
      LoadLine('     The spring constant, restoring the string to its');
      LoadLine('  equilibrium:  0.1 < {       } < 10');
      LoadLine('     The two parameters controlling dry friction:');
      LoadLine('            0.1 < A = {       } < 11');
      LoadLine('              0 < B = {       } < 10');
      LoadLine('  Note: It is essential that B <= A.');
      LoadLine('');
      LoadLine('               [  OK  ]          [Cancel]');
      SetNumber(1, Speed);
      SetNumberLimits(1, 0, 10);
      SetNumber(2, SprConst);
      SetNumberLimits(2, 0.1, 10);
      SetNumber(3, FrictA);
      SetNumberLimits(3, 0.1, 11);
      SetNumber(4, FrictB);
      SetNumberLimits(4, 0, 10);
      REPEAT
         AcceptScreen;
         GetParameters := NOT Canceled;
         IF NOT Canceled THEN
         BEGIN
            Speed := GetNumber(1);
            SprConst := GetNumber(2);
            FrictA := GetNumber(3);
            FrictB := GetNumber(4);
            IF FrictB > FrictB THEN
               Announce('B must not be greater than A. Try again.');
         END;
      UNTIL (FrictB < FrictA) OR Canceled;
      Done;
      FigureChanged := True;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
BEGIN
   RelativeSpeed := Abs(Speed - y[2]);
   z[1] := SprConst*y[2];
   z[2] := - y[1]*10 + FrictSign*(FrictA + FrictB*RelativeSpeed)/(1 + RelativeSpeed);
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

{------------------------------------------------------------------------}

PROCEDURE DrawSpring(x, y, Length: Real);
CONST
   NSegment = 15;
   {SegmentLength = 0.5;}
VAR
   DLength, Displacement: Real;
   x1, y1, x2, y2: Real;
   i: Integer;
   SegmentLength: Real;

BEGIN
   DLength := Length/NSegment;
   Displacement := 0.2;
   x1 := x + 0.5*DLength;
   y1 := y + Displacement;
   PlotLine(x, y, x1, y1);
   FOR i := 1 TO NSegment-1 DO
   BEGIN
      x2 := x + (0.5 + i)*DLength;
      Displacement := - Displacement;
      y2 := y + Displacement;
      PlotLine(x1, y1, x2, y2);
      x1 := x2;
      y1 := y2;
   END;
   x2 := x + Length;
   y2 := y;
   PlotLine(x1, y1, x2, y2);
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawSpokes;
VAR
  CosAngle, SinAngle   : Real;
  Radius               : Real;
BEGIN
   Radius := 1.25;
   CosAngle := Radius*Cos(SpokeAngle);
   SinAngle := Radius*Sin(SpokeAngle);
   PlotLine(2 + SinAngle, 5 + CosAngle, 2 - SinAngle, 5 - CosAngle);
   PlotLine(2 - CosAngle, 5 + SinAngle, 2 + CosAngle, 5 - SinAngle);
   PlotLine(12 + SinAngle, 5 + CosAngle, 12 - SinAngle, 5 - CosAngle);
   PlotLine(12 - CosAngle, 5 + SinAngle, 12 + CosAngle, 5 - SinAngle);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawFigure;
VAR
   xSc, ySc       : Integer;
   Radius         : Integer;
   i              : Integer;
BEGIN
   HideMouse;
   Sliders.Create(2, 0.1, 11, FrictA, 0.15, 0.05, 0.45, 1, '0.1', '11', 'A',
                   True);
   Sliders.Create(3, 0, 10, FrictB, 0.15, 0.5, 0.95, 1, '0', '10', 'B<A',
                   True);
   Sliders.Create(1, 0.1, 10, Speed, 0.05, 0.05, 0.45, 1, '0.1', '10', 'Speed',
                   True);
   Sliders.Create(4, 0.1, 10, SprConst, 0.05, 0.5, 0.95, 1, '0.1', '10', 'Spring',
                   True);

   Sliders.DrawAll;
   OpenViewPort(2);
   SelectScale(2);
   Message('');
   PlotLine(0, 0, MaxT, 0);
   PlotLine(0, y1Min, 0, y1Max);
   OutTextXY(MapX(1.01*MaxT), MapY(-0.1), 'Time');
   OutTextXY(MapX(0.02*MaxT), MapY(y1Max), 'x');
   PlotLine(MaxT, 0, MaxT, (y1Max - y1Min)/20);
   OutTextXY(MapX(0.95*MaxT), MapY((y1Max - y1Min)/10), NumStr(MaxT, 3,1));
   IF FigureChanged THEN
   BEGIN
   OpenViewPort(1);
   SelectScale(1);
   PlotLine(7.5, 8, 7.5, 7.6);
   PlotLine(7.5, 8, 11, 8);
   PlotLine(11, 8, 10.7, 8.3);
   PlotLine(11, 8, 10.7, 7.7);
   OutTextXY(MapX(11.1), MapY(8), 'x');
   Circle(MapX(2), MapY(5), MapY(2) -  MapY(3.5));
   Circle(MapX(12), MapY(5), MapY(2) - MapY(3.5));
   Circle(MapX(2), MapY(5), MapY(2) -  MapY(3.3));
   Circle(MapX(12), MapY(5), MapY(2) - MapY(3.3));
   PlotLine(2, 6.5, 12, 6.5);
   PlotLine(2, 3.52, 12, 3.52);
   FOR i := 1 TO 9 DO
   BEGIN
      PlotLine(Tick[i], 6.45, Tick[i], 6.25);
      PlotLine(14 - Tick[i], 3.55, 14 - Tick[i], 3.75);
   END;
   DrawSpokes;
   Rectangle(MapX(2), MapY(8), MapX(3.5), MapY(6.75));
   DrawSpring(3.5, 7, y[1]/5+3.5);
   {PlotLine(4.5, 7, y[1]/5+8, 7);}
   Rectangle(MapX(y[1]/5+7), MapY(7.5), MapX(y[1]/5 + 8), MapY(6.55));
   END;
   FigureChanged := False;
   WITH HotKeys DO Key[1] := 'F2-Start';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawMovedBow;
VAR
   StoreColor  : Word;
   i           : Integer;
   ScaledY1    : Real;
   ScaledSpeed : Real;
BEGIN
   ScaledY1 := XScaleFactor*y[1];
   ScaledSpeed := Speed*XScaleFactor;
   SelectViewPort(1);
   SelectScale(1);
   HideMouse;
   StoreColor := GetColor;
   SetColor(GraphBackColor);
   {PlotLine(4.5, 7, xOld+8, 7);}
   DrawSpokes;
   SetColor(StoreColor);
   SpokeAngle := SpokeAngle + ScaledSpeed*DelTime/1.5;
   DrawSpokes;
   SetColor(GraphBackColor);
   SetFillStyle(1, DarkGray);
   {Bar(MapX(3.55), MapY(7.3), MapX(xOld+8), MapY(6.7));}
   Bar(MapX(3.55), MapY(7.3), MapX(XScaleFactor*xOld+8), MapY(6.7));
   SetColor(StoreColor);
   {DrawSpring(3.5, 7, y[1]/5+3.5);}
   DrawSpring(3.5, 7, ScaledY1/5+3.5);
   SetColor(GraphBackColor);
   {Rectangle(MapX(xOld+7), MapY(7.5), MapX(xOld + 8), MapY(6.55));}
   Rectangle(MapX(XScaleFactor*xOld+7), MapY(7.5),
             MapX(XScaleFactor*xOld + 8), MapY(6.55));
   SetColor(StoreColor);
   {Rectangle(MapX(y[1]/5+7), MapY(7.5), MapX(y[1]/5 + 8), MapY(6.55));}
   Rectangle(MapX(ScaledY1/5+7), MapY(7.5), MapX(ScaledY1/5 + 8), MapY(6.55));
   SetColor(GraphBackColor);
   {DrawSpring(3.5, 7, xOld+3.5);}
   FOR i := 1 TO 9 DO
   BEGIN
      PlotLine(Tick[i], 6.45, Tick[i], 6.25);
      PlotLine(14 - Tick[i], 3.55, 14 - Tick[i], 3.75);
   END;
   FOR i := 1 TO 9 DO
      Tick[i] := Tick[i] + DelTime*ScaledSpeed/5;
   IF Tick[9] > 11.5 THEN
   BEGIN
      FOR i := 1 TO 9 DO
         Tick[i] := Tick[i] - 1;
   END;
   SetColor(StoreColor);
   {PlotLine(4.5, 7, y[1]/5+8, 7);}

   FOR i := 1 TO 9 DO
   BEGIN
      PlotLine(Tick[i], 6.45, Tick[i], 6.25);
      PlotLine(14 - Tick[i], 3.55, 14 - Tick[i], 3.75);
   END;
   {xOld := y[1]/5; }
   Circle(MapX(2), MapY(5), MapY(2) -  MapY(3.5));
   Circle(MapX(12), MapY(5), MapY(2) - MapY(3.5));


   SelectViewPort(2);
   SelectScale(2);
   IF Stretch THEN SetColor(LightBlue) ELSE SetColor(Yellow);
   PlotLine(yOld, 5*xOld, Time, y[1]);
   SetColor(White);
   xOld := y[1]/5;
   yOld := Time;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   CountChange    : Integer;
BEGIN
   y1Max := 0;
   y1Min := -0.1;
   y[1] := 0;
   y[2] := Speed;
   Time := 0;
   StepSize := 0.1;
   Stretch := True;
   CountChange := 0;
   REPEAT
      IF Stretch THEN
      BEGIN
         y[1] := y[1] + DelTime*Speed;
         y[2] := Speed;
         IF y[1] > y1Max THEN y1Max := y[1];
         IF y[1] < y1Min THEN y1Min := y[1];
         Time := Time + DelTime;
         IF y[1]*SprConst > FrictA THEN
         BEGIN
            y[1] := FrictA/SprConst;
            IF y[1] > y1Max THEN y1Max := y[1];
            IF y[1] < y1Min THEN y1Min := y[1];
            Stretch := False;
            CountChange := CountChange + 1;
         END;
      END
      ELSE
      BEGIN
         RelativeSpeed := Abs(Speed - y[2]);
         IF RelativeSpeed <> 0 THEN FrictSign := (Speed - y[2])/RelativeSpeed
         ELSE FrictSign := 0;
         Step(Time, DelTime, 0.000001, y, Time, StepSize, y);
         IF y[1] > y1Max THEN y1Max := y[1];
         IF y[1] < y1Min THEN y1Min := y[1];
         IF Speed - y[2] < 0 THEN
         BEGIN
            REPEAT
               Fun(Time, y, z);
               Step(Time, (Speed - y[2])/z[2], 0.000001, y, Time, StepSize, y);
            UNTIL Abs(Speed - y[2]) < 0.001;
            IF y[1] > y1Max THEN y1Max := y[1];
            IF y[1] < y1Min THEN y1Min := y[1];
            Stretch := True;
            CountChange := CountChange + 1;
         END;
      END;
   UNTIL CountChange = 4;
   DefineScale(2, -0.05*MaxT, 1.1*MaxT, y1Min - (y1Max - y1Min)/20,
                          y1Max + (y1Max - y1Min)/20);
   IF y1Max > 15 THEN XScaleFactor := 15/y1Max ELSE XScaleFactor := 1;
END;

{-------------------------------------------------------------------------}

PROCEDURE StartBow;
VAR
   i       : Integer;
BEGIN
   FindScale;
   y[1] := 0;
   y[2] := Speed;
   Time := 0;
   xOld := y[1]/5;
   yOld := Time;
   Stretch := True;
   LightMenu := False;
   SpokeAngle := 0;
   FOR i := 1 TO 9 DO
      Tick[i] := 2 + i;
   DrawFigure;
   Playing := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveBow;
BEGIN
   Delay(Lag);
   IF Stretch THEN
   BEGIN
      IF SprConst*(y[1] + DelTime*Speed) > FrictA THEN
      BEGIN
         Time := Time + (FrictA/SprConst - y[1])/Speed;
         y[1] := FrictA/SprConst;
         Stretch := False;
         RubOutXY(0.47, 0.69, 10, GraphBackColor);
         SetColor(Yellow);
         PrintXY(0.47, 0.69, 'Fly-back');
         SetColor(White);
      END
      ELSE
      BEGIN
         y[1] := y[1] + DelTime*Speed;
         y[2] := Speed;
         Time := Time + DelTime;
      END;
     { y[1] := y[1] + DelTime*Speed;
      y[2] := Speed;
      Time := Time + DelTime;
      IF SprConst*y[1] > FrictA THEN
      BEGIN
         y[1] := FrictA/SprConst;
         Stretch := False;
         RubOutXY(0.47, 0.69, 10, GraphBackColor);
         SetColor(Yellow);
         PrintXY(0.47, 0.69, 'Fly-back');
         SetColor(White);
      END;}
   END
   ELSE
   BEGIN
      RelativeSpeed := Abs(Speed - y[2]);
      IF RelativeSpeed <> 0 THEN FrictSign := (Speed - y[2])/RelativeSpeed
      ELSE FrictSign := 0;
      Step(Time, DelTime, 0.000001, y, Time, StepSize, y);
      IF Speed - y[2] < 0 THEN
      BEGIN
         REPEAT
            Fun(Time, y, z);
            Step(Time, (Speed - y[2])/z[2], 0.000001, y, Time, StepSize, y);
         UNTIL Abs(Speed - y[2]) < 0.001;
         Stretch := True;
         RubOutXY(0.47, 0.69, 10, GraphBackColor);
         SetColor(LightBlue);
         PrintXY(0.47, 0.69, 'Stretch');
         SetColor(White);
      END;
   END;
   DrawMovedBow;
   IF Time >= MaxT THEN
   BEGIN
      Pause := True;
      WITH HotKeys DO Key[1] := 'F2-Start';
      HotKeys.BackColor := Red;
      HotKeys.Display;
      ShowMouse;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION FindNewTimeScale  : Boolean;
VAR
   Input  : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.26, 0.74, 0.35, 0.65);
      LoadLine('');
      LoadLine('      Enter a value for the maximum');
      LoadLine(' time in the graph:');
      LoadLine('     MaxTime = {       } > 1');
      LoadLine('');
      LoadLine('       [  OK  ]    [Cancel]');
      SetNumber(1, MaxT);
      SetNumberLimits(1, 1, 10000000);
      AcceptScreen;
      FindNewTimeScale := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         {FigureChanged := True; }
         MaxT := GetNumber(1);
      END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleViolinMenu;
BEGIN
   WITH ViolinMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            2: ShowHelp('HelpMisc.hlp', 'ViolinAboutProgram');
            1: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpMisc.hlp', 'ViolinAboutModelA');
                  ShowHelp('HelpMisc.hlp', 'ViolinAboutModelB');
               END;
            2: HelpFriction;
            3: ShowHelp('WalkThru.hlp', 'Violin');
         END;
      3: CASE RowChosen OF
            1: IF GetParameters THEN StartBow;
            2: StartBow;
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
         1: BEGIN
               IF Pause THEN
               BEGIN
                  Pause := False;
                  FigureChanged := True;
                  WITH HotKeys DO Key[1] := 'F2-Pause';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
                  IF Stretch THEN
                  BEGIN
                     SetColor(LightBlue);
                     PrintXY(0.47, 0.69, 'Stretch');
                     SetColor(White);
                  END;
                  HideMouse;
               END
               ELSE
               BEGIN
                  Pause := True;
                  WITH HotKeys DO Key[1] := 'F2-Start';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
                  ShowMouse;
               END;
         END;
         2: IF Lag - DelLag >= 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
         3: Lag := Lag + DelLag;
         4: BEGIN
               IF NOT Pause THEN
               BEGIN
                  Pause := True;
                  WITH HotKeys DO Key[1] := 'F2-Start';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
                  ShowMouse;
               END;
               IF FindNewTimeScale THEN StartBow;
            END;
         5: BEGIN
                  Playing := False;
                  ClearMuppetPort;
                  ViolinMenu.Display;
                  FigureChanged := True;
                  LightMenu := True;
                  Pause := True;
            END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   IF Sliders.Value(3) > Sliders.Value(2) THEN
   BEGIN
      Announce('B must not be greater than A. Values ignored.');
      {Announce('I have made B = A/2. If you don''t like it, tough!'); }
      Sliders.Reset(3, FrictA/2);
   END;
   Speed := Sliders.Value(1);
   FrictA := Sliders.Value(2);
   FrictB := Sliders.Value(3);
   SprConst := Sliders.Value(4);
   IF FrictB >= FrictA THEN FrictB := FrictA/2;
   StartBow;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.2, 0.99, 0.52, 0.95);
   DefineScale(1, -1, 15, 2.5, 8.5);
   DefineViewPort(2, 0.2, 0.99, 0.08, 0.48);
   MaxT := 30;
   DefineScale(2, -0.05*MaxT, 1.1*MaxT, -3.5, 3.5);
   FrictA := 2;
   FrictB := 1;
   Speed := 1;
   SprConst := 1;
   Time := 0;
   DelTime := 0.05;
   XScaleFactor := 1;
   Lag := 50;
   Stretch := True;
   ExitRequest := False;
   FigureChanged := True;
   LightMenu := True;
   Pause := True;
   SetUpHotKeys;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Sliders.Init;
   GetSetUp;
   Hello('HelpMisc.hlp', 'ViolinAboutProgram');
   SetUpViolinMenu;
   IF GetParameters THEN StartBow;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Pause AND Sliders.Changed THEN HandleSliders;
      IF LightMenu THEN
         IF ViolinMenu.Chosen THEN HAndleViolinMenu
      ELSE
         IF ViolinMenu.Activated THEN HandleViolinMenu;
      IF Playing AND (NOT Pause) THEN MoveBow;
   UNTIL ExitRequest;
   CUPSDone;
   ViolinMenu.Done;
   Sliders.Done;
END.
