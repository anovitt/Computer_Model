PROGRAM JupiterAndComet;

USES Dos, Crt, Graph, CUPSMupp, CUPS, CupsGui;

CONST
   neq = 4;

TYPE
   vector = array[1..neq] of real;

VAR
   y                            : Vector;
   CometMenu                    : TMenu;
   HotKeys                      : THotKeys;
   BlowUp                       : TImage;
   A0                           : Real;
   t0, x0, yv0                  : Real;
   MeanMotion, JupiterMass      : Real;
   JupiterRadius                : Real;
   Time, OldTime                : Real;
   CxOld, CyOld, CxNew, CyNew   : Real;
   JxOld, JyOld, JxNew, JyNew   : Real;
   StepSize                     : Real;
   xLow, xHigh, yLow, yHigh     : Real;
   Lag                          : Integer;
   WindowLag                    : Integer;
   x1, y1, x2, y2               : Integer;
   Radius                       : Integer;
   Key                          : Byte;
   CloseApproach                : Boolean;
   WindowOpened                 : Boolean;
   LightMenu                    : Boolean;
   ExitRequest                  : Boolean;
   Action, PlotOrbit            : Boolean;
   ContinueOrbit                : Boolean;
   xScreenRatio, yScreenRatio   : Real;
   CometNumber                  : Integer;
   xComet, yComet               : Array[1..30] OF Integer;

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

{------------------------------------------------------------------------}

PROCEDURE SetUpCometMenu;
VAR
   I      : Integer;
BEGIN
   With CometMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About the program');
       row(1,2, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Running the program');
       row(2,3, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Parameters for Jupiter');
       row(3,2, 'Initial conditions for the comet');
       row(3,3, 'Animate the motion');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   CometMenu.Display;
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

PROCEDURE GetJupiterData;
VAR
   Input         : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.2, 0.8);
      LoadLine('');
      LoadLine('     Enter a value for the mass of Jupiter');
      LoadLine('  in units of the mass of the Sun. The');
      LoadLine('  actual value is approximately 0.001.');
      LoadLine('         0 < Mass = {       } <= 1');
      LoadLine('');
      LoadLine('     Enter a value for the radius of ');
      LoadLine('  Jupiter''s orbit, in astronomical units.');
      LoadLine('  The actual value is approximately 5.2.');
      LoadLine('      1 <= Radius = {       } <= 10');
      LoadLine('');
      LoadLine('          [ Help ]        [  OK  ]');
      SetHelpFile('HelpAstr.Hlp', 'CometJupiterHelp');
      SetNumber(1, JupiterMass);
      SetNumberLimits(1, 0, 1);
      SetNumber(2, JupiterRadius);
      SetNumberLimits(2, 1, 10);
      AcceptScreen;
      JupiterMass := GetNumber(1);
      JupiterRadius := GetNumber(2);
      Done;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION GetCometData : Boolean;
CONST
   RBNames : string = '12345678';
VAR
   CometDat : TInputScreen;
   SpeedOK  : Boolean;
BEGIN
   ContinueOrbit := False;
   WITH CometDat DO
   BEGIN
      Init;
      DefineInputPort(0.64, 1, 0.3, 1);
      LoadLine(' Location of Jupiter:');
      LoadLine('     A0 = {          } deg');
      LoadLine(' Location of the comet:');
      LoadLIne(''+NumStr(2*JupiterRadius, 3,0)+' < x = {          }');
      LoadLine('             < 1,000');
      LoadLine('     y = 0');
      LoadLIne(' Velocity of the comet:');
      LoadLine('     Vx = 0');
      LoadLine('     Vy = {          }');
      LoadLine(' Use this Vy? Yes #1 No #1');
      LoadLine(' If ''No'', the program will');
      LoadLine(' find Vy to make the peri-');
      LoadLine(' helion distance equal to');
      LoadLine(' the radius of Jupiter''s');
      LoadLine(' orbit.');
      LoadLine(' [ Help ] [  OK  ] [Cancel]  ');
      SetHelpFile('HelpAstr.Hlp', 'CometInputHelp');
      SetNumber(1, A0);
      SetNumberLimits(1, 0, 360);
      SetNumber(2, x0);
      SetNumberLimits(2, Trunc(2*JupiterRadius), 1000);
      SetNumber(3, yv0);
      REPEAT
         SetNumber(3, yv0);
         AcceptScreen;
         GetCometData := NOT Canceled;
         IF NOT Canceled THEN
         BEGIN
            SpeedOK := True;
            IF GetNumber(3)*Sqrt(GetNumber(2)) > 1 THEN
            BEGIN
               SpeedOK := False;
               Announce('Speed must bed less than 1/Sqrt(x). Try again.');
            END
            ELSE
            BEGIN
            A0 := GetNumber(1);
            T0 := (Pi/180)*A0*JupiterRadius*Sqrt(JupiterRadius)
                          *Sqrt(1 + JupiterMass);
            x0 := GetNumber(2);
            y[1] := x0;
            y[2] := 0;
            y[3] := 0;
            yv0 := GetNumber(3);
            IF GetRadioButton(RBNames[1]) = 1
            THEN
               y[4] := yv0
            ELSE
            BEGIN
               y[4] :=Sqrt(2*JupiterRadius*(1+JupiterMass)/(x0*(JupiterRadius+x0)));
               yv0 := y[4];
            END;
            MeanMotion := Sqrt(1+JupiterMass)/(JupiterRadius*Sqrt(JupiterRadius));
            xLow := -2*JupiterRadius;
            xHigh := 1.1*y[1];
            yLow := -(5/14)*(-xLow + xHigh);
            yHigh := - yLow;
            DefineScale(1, xLow, xHigh, yLow, yHigh);
         END;
         END;
      UNTIL SpeedOK OR Canceled;
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
   DefineViewPort(2, 0, 0.64, 0.3, 1);
   DefineScale(2, -2.6, 5.4, -5, 6.5);
   HideCursor;
   Message('');
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   Map(-0.5, 5.5, xSc, ySc);
   SetColor(White);
   OutTextxy(MapX(-0.1), ySc, 'Jupiter and a Comet');
   Map(0, 0, xSc, ySc);
   Map(1, 0, xSc2, ySc2);
   Radius := xSc2 - xSc;
   SetColor(LightBlue);
   Circle(xSc, ySc, Radius);
   PlotLine(0.707, -1.29, 0.507, -1.29);
   PlotLine(0.707, -1.29, 0.707, -1.61);
   Ellipse(xSc+Radius+ 0, ySc, 0, 360, 3*Radius, 2*Radius);
   Map(4, 0, xSc2, ySc2);
   SetFillStyle(SolidFill, LightBlue);
   FillEllipse(MapX(2), ySc2, 5, 5);
   OutTextxy(MapX(2), MapY(-0.3), 'Comet');
   PlotLIne(-2.9, 0, 4.9, 0);
   PLotLine(0, 0, 0, 4.5);
   Map(4.5, 0.5, xSc2, ySc2);
   OutTextxy(MapX(4.7), MapY(0.3), 'X');
   Map(0.2, 4.5, xSc2, ySc2);
   OutTextxy(xSc2, ySc2, 'Y');
   SetColor(LightGray);
   PlotLine(-1.6, 0, -1.6, 4);
   Map(-2.5, 4.5, xSc2, ySc2);
   OutTextxy(MapX(-2.2), ySc2, 'Perihelion');
   PlotLine(4.4, 0, 4.4, 4);
   Map(3.5, 4.5, xSc2, ySc2);
   OutTextxy(MapX(3.7), ySc2, 'Aphelion');
   x2 := x1 + 3*sin(Pi/18);
   y2 := y1 + 3*cos(Pi/18);
   SetFillStyle(SolidFill, Yellow);
   SetColor(Yellow);
   FillEllipse(xSc, ySc, Trunc(Radius/5), Trunc(Radius/5));
   OutTextxy(MapX(0.3), MapY(-0.3), 'Sun');
   SetColor(White);
   Arc(xSc, ySc, 0, 60, Trunc(Radius/3));
   SetFillStyle(SolidFill, White);
   xSc2 := xSc + Trunc(0.5*Radius);
   ySc2 := ySc - Trunc(0.866*Radius);
   Line(xSc, ySc, xSc2, ySc2);
   FillEllipse(xSc2, ySc2, 5, 5);
   OutTextxy(MapX(0.7), MapY(1.6), 'Jupiter');
   OutTextxy(MapX(0.3), MapY(0.4), 'A0');
   DefineViewPort(3, 0, 1, 0.05, 0.3);
   DefineScale(3, 0, 10, -6, 20);
   SelectScale(3);
   GraphBackColor := Red;
   OpenViewPort(3);
   SetColor(Yellow);
   Map(1, 18, xSc, ySc);
   OutTextxy(xSc, ySc, 'The unit of distance is the astronomical unit.');
   Map(1, 15, xSc, ySc);
   OutTextxy(xSc, ySc, 'The unit of mass is the mass of the Sun.');
   Map(1, 12, xSc, ySc);
   OutTextxy(xSc, ySc, 'The unit of time is approximately 58 days.');
   Map(1, 9, xSc, ySc);
   OutTextxy(xSc, ySc, 'The radius of Jupiter''s orbit is '
                        +NumStr(JupiterRadius, 2,1)+' astronomical units.');
   Map(1, 6, xSc, ySc);
   OutTextxy(xSc, ySc, 'The mass of Jupiter is '
                        +NumStr(JupiterMass, 5,3)+' solar masses');
   Map(1, 3, xSc, ySc);
   OutTextxy(xSc, ySc, 'If an orbit has perihelion distance P and aphelion distance A');
   Map(0.8, 0, xSc, ySc);
   OutTextxy(xSc, ySc, 'then the speed at aphelion is Sqrt(2*P/(A*(A+P))), where the');
    Map(0.8, -3, xSc, ySc);
   OutTextxy(xSc, ySc, 'mass of Jupiter is neglected');
   ShowCursor;
END;

{------------------------------------------------------------------------}


PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
VAR
   r, xm, ym, rrr, d: Real;
   xj, yj: Real;
BEGIN
   r := sqrt(y[1]*y[1] + y[2]*y[2]);
   rrr := r*r*r;
   z[1] := y[3]; z[2] := y[4];
   xj := JupiterRadius*cos(MeanMotion*(x - t0));
   yj := JupiterRadius*sin(MeanMotion*(x - t0));
   d := sqrt((y[1] - xj)*(y[1] - xj) + (y[2] - yj)*(y[2] - yj));
   z[3] := - y[1]/rrr - JupiterMass*(y[1] - xj)/(d*d*d);
   z[4] := - y[2]/rrr - JupiterMass*(y[2] - yj)/(d*d*d);
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
      temax := Tol/100000;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
END;

{-----------------------------------------------------------------------}

FUNCTION XDisp(Delta : Integer) : Integer;
BEGIN
   XDisp := Trunc(Delta*xScreenRatio);
END;

FUNCTION YDisp(Delta : Integer) : Integer;
BEGIN
   YDisp := Trunc(Delta*yScreenRatio);
END;

{-------------------------------------------------------------------------}

PROCEDURE PrintTime(Time: Real);
VAR
   Years  : Integer;
   StoreColor : Word;
BEGIN
   StoreColor := GetColor;
   Years := Trunc(Time/(2*Pi));
   rubOutXY(0.11,0.135,6,Black);
   SetColor(LightBlue);
   printXY(0.11,0.135,NumStr(Years,6,0));
   SetColor(StoreColor);
   SelectViewPort(1);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawSun;
VAR
   SaveColor     : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(Yellow);
   SetFillStyle(SolidFill, Yellow);
   FillEllipse(MapX(0), MapY(0), XDisp(5), YDisp(5));
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotComet(xc, yc : Real; DrawComet  : Boolean);
VAR
   I, J, xPC, yPC, xP, yP     : Integer;
   nTail                      : Integer;
   xTail, yTail, r            : Real;
BEGIN
   r := Sqrt(xc*xc+yc*yc);
   nTail := 3;
   IF r < 0.4*JupiterRadius THEN nTail := 13;
   IF (r > 0.4*JupiterRadius) AND (r < 0.6*JupiterRadius) THEN nTail := 12;
   IF (r > 0.6*JupiterRadius) AND (r < 0.8*JupiterRadius) THEN nTail := 11;
   IF (r > 0.8*JupiterRadius) AND (r < JupiterRadius) THEN nTail := 10;
   IF (r > JupiterRadius) AND (r < 1.5*JupiterRadius) THEN nTail := 9;
   IF (r > 1.5*JupiterRadius) AND (r < 2*JupiterRadius) THEN nTail := 8;
   IF (r > 2*JupiterRadius) AND (r < 3*JupiterRadius) THEN nTail := 7;
   IF (r > 3*JupiterRadius) AND (r < 4.5*JupiterRadius) THEN nTail := 6;
   IF (r > 4.5*JupiterRadius) AND (r < 7*JupiterRadius) THEN nTail := 5;
   IF (r > 7*JupiterRadius) AND (r < 10*JupiterRadius) THEN nTail := 4;
   xTail := xc/r;
   yTail := yc/r;
   Map(xc, yc, xpc, ypc);
   IF DrawComet THEN
   BEGIN
      CometNumber := 0;
      FOR I := 1 TO 3 DO
      BEGIN
         xp := xpc-2+I;
         FOR J := 1 TO 3 DO
         BEGIN
             yp := ypc-2+J;
             IF GetPixel(xp, yp) = DarkGray THEN
             BEGIN
                CometNumber := CometNumber + 1;
                xComet[CometNumber] := xp;
                yComet[CometNumber] := yp;
             END;
             PutPixel(xp, yp, LightBlue);
         END;
      END;
      FOR I := 1 TO nTail DO
      BEGIN
         xp := xpc + Trunc(I*xTail);
         yp := ypc - Trunc(I*yTail);
         IF GetPixel(xp, yp) = DarkGray THEN
             BEGIN
                CometNumber := CometNumber + 1;
                xComet[CometNumber] := xp;
                yComet[CometNumber] := yp;
             END;
             PutPixel(xp, yp, LightBlue);
      END;
   END
   ELSE
   BEGIN
      FOR I := 1 TO 3 DO
      BEGIN
         xp := xpc-2+I;
         FOR J := 1 TO 3 DO
         BEGIN
             yp := ypc-2+J;
             PutPixel(xp, yp, Black);
         END;
      END;
      FOR I := 1 TO nTail DO
      BEGIN
         xp := xpc + Trunc(I*xTail);
         yp := ypc - Trunc(I*yTail);
         PutPixel(xp, yp, Black);
      END;
      IF CometNumber > 0 THEN
      BEGIN
         FOR I := 1 TO CometNumber DO
            PutPixel(xComet[I], yComet[I], DarkGray);
      END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotJupiter(xc, yc : Real; JColor : Word);
VAR
   I, J, xPC, yPC, xP, yP     : Integer;
BEGIN
   Map(xc, yc, xpc, ypc);
   FOR I := 1 TO 3 DO
   BEGIN
      xp := xpc-2+I;
      FOR J := 1 TO 3 DO
      BEGIN
         yp := ypc-2+J;
         PutPixel(xp, yp, JColor);
      END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE PrepareOrbit;
VAR
   xTick, yTick  : Integer;
BEGIN
   GraphBackColor := Black;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   xTick := Trunc(Ln(Abs(xHigh) + Abs(xLow))/Ln(10)+0.01) - 1;
   yTick := Trunc(Ln(Abs(yHigh) + Abs(yLow))/Ln(10)+0.01) - 1;
   Axis(0, 0, xTick, yTick);
   SetColor(GraphBackColor);
   PlotLine(0.97*xLow, 0, 0.97*xHigh, 0);
   PlotLine(0, 0.97*yLow, 0, 0.97*yHigh);
   SetColor(White);
   PrintXY(0.4, 0.95, 'Astronomical units');
   WITH HotKeys DO Key[2] := 'F2-Run';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   SetColor(Yellow);
   DrawSun;
   IF ContinueOrbit THEN
   OldTime := Time
   ELSE
   BEGIN
      OldTime := 0;
      Time := 0;
   END;
   StepSize := 10;
   JxOld := JupiterRadius*Cos(MeanMotion*(Time - t0));
   JyOld := JupiterRadius*Sin(MeanMotion*(Time - t0));
   CxOld := y[1];
   CyOld := y[2];
   SetColor(White);
   PlotJupiter(JxOld, JyOld, White);
   SetColor(LightBlue);
   PlotComet(CxOld, CyOld, True);
   printXY(0.11,0.135, '       years');
   PrintTime(0);
   Action := False;
   PlotOrbit := True;
   CloseApproach := False;
   WindowOpened := False;
   LightMenu := False;
   x1 := Trunc(0.5*GetMaxX);
   y1 := Trunc(0.5*GetMaxY);
   x2 := Trunc(0.9*GetMaxX);
   y2 := Trunc(0.9*GetMaxY);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveJupiter;
VAR
   DelTime   : Real;
   i, j      : Integer;
BEGIN
   DelTime := 2;
   Delay(10);
   i := 1 + Trunc((Time - OldTime)/DelTime);
   DelTime := (Time - OldTime)/i;
   FOR j := 1 TO i DO
   BEGIN
      SetColor(Black);
      PlotJupiter(JxOld, JyOld, Black);
      JxNew := JupiterRadius*Cos(MeanMotion*(OldTime + j*DelTime - t0));
      JyNew := JupiterRadius*Sin(MeanMotion*(OldTime + j*DelTime - t0));
      SetColor(White);
      PlotJupiter(JxNew, JyNew, White);
      JxOld := JxNew;
      JyOld := JyNew;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE StepOrbit;
BEGIN
   Delay(Lag);
   IF Sqrt(y[1]*y[1] + y[2]*y[2]) < 2 THEN DrawSun;
   Step(OldTime, StepSize, 0.00001, y, Time, StepSize, y);
   IF Sqrt(y[1]*y[1]+y[2]*y[2]) > 10*x0 THEN
   BEGIN
      Announce('I''ve escaped. Goodbye!');
      PlotOrbit := False;
      Exit;
   END;
   PrintTime(Time);
   IF StepSize > 50 THEN StepSize := 50;
   JxNew := JupiterRadius*Cos(MeanMotion*(Time - t0));
   JyNew := JupiterRadius*Sin(MeanMotion*(Time - t0));
   IF (y[1] - JxNew)*(y[1] - JxNew)
          + (y[2] - JyNew)*(y[2] - JyNew) < 1
      THEN CloseApproach := True ELSE CloseApproach := False;
   IF (WindowOpened) AND (NOT CloseApproach) THEN
   BEGIN
      SetColor(Black);
      GraphBackColor := Black;
      OpenViewPort(4);
      SelectViewPort(1);
      BlowUp.Put(x1, y1);
      WindowOpened := False;
   END;
   CxNew := y[1];
   CyNew := y[2];
   SetColor(Black);
   PlotComet(CxOld, CyOld, False);
   SetColor(DarkGray);
   PlotLine(CxOld, CyOld, CxNew, CyNew);
   PlotComet(CxNew, CyNew, True);
   IF NOT CloseApproach THEN MoveJupiter;
   SetColor(LightGray);
   Ellipse(MaPX(0), MapY(0), 0, 360,
          Abs(MapX(JupiterRadius) - MapX(0)), Abs(MapY(JupiterRadius) - MapY(0)));
   SetColor(White);
   IF CloseApproach THEN
   BEGIN
      IF NOT WindowOpened THEN
      BEGIN
         BlowUp.Get(x1, y1, x2, y2);
         DefineViewPort(4, 0.6, 0.9, 0.1, 0.4);
         SetColor(Black);
         PlotJupiter(JxOld, JyOld, Black);
         GraphBackColor := Blue;
         OpenViewPort(4);
         DefineScale(4, -1, 1, -1, 1);
         SelectScale(4);
         SetColor(White);
         PlotSymbol(0, 0, '*');
         WindowOpened := True;
         WindowLag := 400;
      END;
      SelectViewPort(4);
      SelectScale(4);
      SetColor(Blue);
      PlotSymbol(CxOld-JxOld, CyOld-JyOld, 'o');
      SetColor(Yellow);
      PlotLine(CxOld-JxOld, CyOld-JyOld, CxNew-JxNew, CyNew-JyNew);
      PlotSymbol(CxNew-JxNew, CyNew-JyNew, 'o');
      SelectScale(1);
      SelectViewPort(1);
   END;
   CxOld := CxNew;
   CyOld := CyNew;
   JxOld := JxNew;
   JyOld := JyNew;
   OldTime := Time;
END;

{------------------------------------------------------------------------}

PROCEDURE ReScale;
CONST
   RBNames : string = '12345678';
VAR
   ScreenData : TInputScreen;
BEGIN
   WITH ScreenData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.32, 0.78);
      LoadLine('');
      LoadLine('     Enter limiting values for the display:');
      LoadLine(' Horizontal:');
      LoadLine('     Lower: {       }    Upper: {       }');
      LoadLine(' Vertical:');
      LoadLine('     Lower: {       }    Upper: {       }');
      LoadLine('');
      LoadLine('   Continue the plot: #1    Restart: #1');
      LoadLine('');
      LoadLine('                  [  OK  ]');
      SetNumber(1, xLow);
      SetNumber(2, xHigh);
      SetNumber(3, yLow);
      SetNumber(4, yHigh);
      IF ContinueOrbit THEN SetRadioButton(RBNames[1], 1)
                       ELSE SetRadioButton(RBNames[1], 2);
      REPEAT
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         yLow := GetNumber(3);
         yHigh := GetNumber(4);
         IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
            Announce('You have confused upper and lower values. Try again');
      UNTIL (xLow < xHigh) and (yLow < yHigh);
      DefineScale(1, xLow, xHigh, yLow, yHigh);
      IF GetRadioButton(RBNames[1]) = 2
      THEN
      BEGIN
         Time := 0;
         StepSize := 1;
         y[1] := x0;
         y[2] := 0;
         y[3] := 0;
         y[4] := yv0;
         ContinueOrbit := False;
      END
      ELSE ContinueOrbit := True;
      PrepareOrbit;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleCometMenu;
BEGIN
   With CometMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: ShowHelp('HelpAstr.hlp', 'CometAboutProgram');
            2: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpAstr.hlp', 'CometModelHelp');
            2: BEGIN
                  ShowHelp('HelpAstr.hlp', 'CometProgramHelpA');
                  ShowHelp('HelpAstr.hlp', 'CometProgramHelpB');
               END;
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'Comet1');
                  ShowHelp('WalkThru.hlp', 'Comet2');
               END;
         END;
      3: CASE RowChosen OF
            1: GetJupiterData;
            2: BEGIN
                  ShowParameters;
                  IF NOT GetCometData THEN
                  BEGIN
                     ClearMuppetPort;
                     LightMenu := True
                  END
                  ELSE  PrepareOrbit;
               END;
            3: BEGIN
                  Time := 0;
                  StepSize := 1;
                  y[1] := x0;
                  y[2] := 0;
                  y[3] := 0;
                  y[4] := yv0;
                  PrepareOrbit;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag        : Integer;
   DelWindowLag  : Integer;
BEGIN
   DelLag := 10;
   DelWindowLag := 50;
   CASE Key OF
      1: ShowHelp('HelpAstr.Hlp','CometHotKeysHelp');
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
               WITH HotKeys DO Key[2] := 'F2-Pause';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
         END;
      3: IF CloseApproach THEN
         BEGIN
            IF WindowLag > DelWindowLag THEN
                 WindowLag := WindowLag - DelWindowLag;
         END
         ELSE IF Lag > DelLag THEN Lag := Lag - DelLag;
      4: IF CloseApproach THEN
            WindowLag := WindowLag + DelWindowLag
            ELSE
            Lag := Lag + DelLag;
      5: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            ReScale;
         END;
      6: BEGIN
            PlotOrbit := False;
            Action := False;
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.1, 0.95, 0.1, 0.93);
   Lag := 20;
   WindowLag := 400;
   A0 := 187;
   t0 := 40;
   x0 := 100;
   yv0 := 0.03086;
   JupiterMass := 0.001;
   JupiterRadius := 5.2;
   T0 := (Pi/180)*A0*JupiterRadius*Sqrt(JupiterRadius)
                    *Sqrt(1 + JupiterMass);
   y[1] := x0;
   y[2] := 0;
   y[3] := 0;
   y[4] := yv0;
   MeanMotion := Sqrt(1+JupiterMass)/(JupiterRadius*Sqrt(JupiterRadius));
   xLow := -10;
   xHigh := 1.1*y[1];
   yLow := -(5/14)*(1 + 1.1*y[1]);
   yHigh := - yLow;
   DefineScale(1, xLow, xHigh, yLow, yHigh);
   LightMenu := True;
   ExitRequest := False;
   ContinueOrbit := False;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   Hello('HelpAstr.hlp', 'CometAboutProgram');
   SetUpCometMenu;
   SetUpHotKeys;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program}
   CUPSInit;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN
                          HandleHotKeys(Key);
      IF PlotOrbit AND Action THEN StepOrbit;
      IF LightMenu THEN
         IF CometMenu.Chosen THEN HandleCometMenu
      UNTIL ExitRequest;
   CUPSDone;
END.
