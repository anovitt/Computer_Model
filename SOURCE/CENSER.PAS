PROGRAM Censer;

Uses Crt, Graph, CUPSMupp, CUPS, CupsGui;

CONST
   Neq = 2;

TYPE
   Vector = Array[1..Neq] OF Real;

VAR
   Time, StepSize        : Real;
   Length, LengthRate    : Real;
   LengthMax, LengthMin  : Real;
   LengthMean            : Real;
   LengthFraction        : Real;
   PeriodFraction        : Real;
   Period0               : Real;
   DelT                  : Real;
   CritLength            : Real;
   StartLength           : Real;
   OldLength             : Real;
   Friction              : Real;
   ExitRequest           : Boolean;
   LightMenu             : Boolean;
   Running               : Boolean;
   Pulling               : Boolean;
   Starting              : Boolean;
   FirstStep             : Boolean;
   MouseInput            : Boolean;
   Y                     : Vector;
   Y1Sign, Y2Sign        : Real;
   SaveAngle             : Real;
   CenserMenu            : TMenu;
   HotKeys               : THotKeys;
   Key                   : Byte;
   Lag                   : Integer;
   BottomFound           :Boolean;
   xScreenRatio, yScreenRatio : Real;

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

PROCEDURE SetUpCenserMenu;
VAR
   I      : Integer;
BEGIN
   With CenserMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
      Column(3, 'Run');
       row(3,1, 'Enter data');
       row(3,2, 'Swing the censer');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   CenserMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(4);
      Key[1] := 'F2-ReStart';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F10-Menu';
   END;
   {HotKeys.Display;}
END;

{------------------------------------------------------------------------}

FUNCTION CenserData : Boolean;
VAR
   CenserDat: TInputScreen;
BEGIN
   Message('');
   WITH CenserDat DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.01, 0.99);
      LoadLine('');
      LoadLine('                  Data for a Swinging Censer ');
      LoadLine('');
      LoadLine('     The pendulum has length varying between two extremes.');
      LoadLine('  Enter the AVERAGE length: 1 < L0 = {       } < 5 meters');
      LoadLine('     The extreme values of the length are L0*(1+f) and');
      LoadLine('  L0*(1-f).');
      LoadLine('        Enter a value for f: 0 < f = {       } < 0.5');
      LoadLIne('');
      LoadLine('     During each oscillation, the length of the pendulum');
      LoadLine('  will be changed four times. If dP is one fourth of the');
      LoadLine('  period, each change will last for a time c*dP.');
      LoadLIne('      Enter a value for p: 0.5 < p = {       } < 0.8');
      LoadLine('');
      LoadLine('     The censer is subject to a resisting force');
      LoadLine('  proportional to its angular velocity. This is specified');
      LoadLine('  by a parameter k. k = 0 stands for no resistance.');
      LoadLine('            Enter a value for k: k = {       } >= 0');
      LoadLine('');
      LoadLine('     Use mouse #1 or keyboard #1 for starting?');
      LoadLine('');
      LoadLine('                [  OK  ]              [Cancel]');
      SetNumber(1, LengthMean);
      SetNumberLimits(1, 1, 5);
      SetNumber(2, LengthFraction);
      SetNumberLimits(2, 0, 0.5);
      SetNumber(3, PeriodFraction);
      SetNumberLimits(3, 0.5, 0.8);
      SetNumber(4, Friction);
      SetNumberLimits(4, 0, 10000000);
      IF MouseInput THEN SetRadioButton('1', 1)
                    ELSE SetRadioButton('1', 2);
      AcceptScreen;
      CenserData := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
         LengthMean := GetNumber(1);
         LengthFraction := GetNumber(2);
         PeriodFraction := GetNumber(3);
         Friction := GetNumber(4);
      IF GetRadioButton('1') = 1 THEN MouseInput := True
                                 ELSE MouseInput := False;
      Done;
   END;
   Period0 := 2*Pi*Sqrt(LengthMean/9.81);
   DelT := Period0*PeriodFraction/4;
   LengthMax := LengthMean*(1 + LengthFraction);
   LengthMin := LengthMean*(1 - LengthFraction);
   LengthRate := (LengthMax - LengthMin)/(DelT*DelT);
   DefineScale(1, -1.2*LengthMax, 2.1*LengthMax,
                  -1.2*LengthMax - 2, 1.2*LengthMax);
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

PROCEDURE PlotMonk(xm, ym, Angle : Real; SColor : Word);
VAR
   xSc, ySc   : Integer;
   x1, x2     : Integer;
   i          : Integer;
   SaveColor  : Word;
BEGIN
   SaveColor := GetColor;
   SetFillStyle(SolidFill, DarkGray);
   IF SColor <> DarkGray THEN SetColor(White);
   Map(xm, ym, xSc, ySc);
   IF (SColor = GraphBackColor) AND FirstStep THEN
      BEGIN
         Bar(xSc-XDisp(8), ySc-YDisp(11), xSc+XDisp(88), ySc+YDisp(28));
         FirstStep := False;
      END;
   xSc := xSc - XDisp(15);
   FOR I := 0 TO 3 DO
   BEGIN
      xSc := xSc + XDisp(20);
      Line(xSc-XDisp(5), ySc, xSc+XDisp(5), ySc+YDisp(5));
      Circle(xSc+XDisp(5), ySc-10, XDisp(5));
      Line(xSc+XDisp(3), ySc-YDisp(5), xSc-XDisp(5), ySc+YDisp(20));
      Line(xSc-XDisp(5), ySc+YDisp(20), xSc+XDisp(15), ySc+YDisp(20));
      Line(xSc+XDisp(15), ySc+YDisp(20), xSc+XDisp(7), ySc-YDisp(5));
      Line(xSc-XDisp(1), ySc+YDisp(7), xSc+XDisp(11), ySc+YDisp(7));
      Line(xSc-XDisp(2), ySc+YDisp(8), xSc+XDisp(12), ySc+YDisp(8));
      Line(xSc+XDisp(5), ySc+YDisp(8), xSc+XDisp(5), ySc+YDisp(12));
      IF SColor = GraphBackColor THEN
      BEGIN
         x1 := xSc+XDisp(5) + Trunc(6*Cos(8*(SaveAngle-0.1)));
         x2 := xSc+YDisp(5) - Trunc(6*Cos(8*(SaveAngle-0.1)));
      END
      ELSE
      BEGIN
         x1 := xSc+XDisp(5) + Trunc(6*Cos(8*SaveAngle));
         x2 := xSc+XDisp(5) - Trunc(6*Cos(8*SaveAngle));
      END;
      Line(x1, ySc+YDisp(20), x1, ySc+YDisp(28));
      Line(x1, ySc+YDisp(28), x1-XDisp(2), ySc+YDisp(28));
      Line(x2, ySc+YDisp(20), x2, ySc+YDisp(28));
      Line(x2, ySc+YDisp(28), x2-XDisp(2), ySc+YDisp(28));
   END;
   IF SColor <> GraphBackColor THEN SetColor(Yellow);
   Line(xSc-XDisp(65), ySc, xSc-XDisp(5), ySc);
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotPendulum(Angle, Len: Real; SColor: Word);
VAR
   Radius: Integer;
   xSc, ySc: Integer;
   xEnd, yEnd: Real;
   StoreColor: Word;
BEGIN
   StoreColor := GetColor;
   Radius := XDisp(30);
   SetColor(SColor);
   xEnd :=  - Len+ 2.5*LengthMean;
   yEnd := -1.2*LengthMax;
   PLotLine(0, 0, LengthMean, 0);
   IF SColor = GraphBackColor THEN PlotLine(LengthMean, 0, xEnd, yEnd)
                              ELSE PlotLine(LengthMean, 0, xEnd, yEnd);
   IF Starting THEN
   BEGIN
      PlotMonk(xEnd, yEnd, 0.001, SColor);
      Starting := False;
   END
   ELSE
      IF Running AND Pulling THEN PlotMonk(xEnd, yEnd, Angle, SColor);
   xEnd := Len*Sin(Angle);
   yEnd := - Len*Cos(Angle);
   PlotLine(0, 0, xEnd, yEnd);
   Map(xEnd, yEnd, xSc, ySc);
      IF SColor <> GraphBackColor THEN SetColor(LightBlue);
      Arc(xSc, ySc, 180+Trunc(180*Angle/Pi-5), Trunc(360+180*Angle/Pi+5), Radius);
      Line(Trunc(xSc-1.01*Radius*Cos(Angle)), Trunc(ySc+1.01*Radius*Sin(Angle)),
           Trunc(xSc+1.01*Radius*Cos(Angle)), Trunc(ySc-1.01*Radius*Sin(Angle)));
   SetColor(StoreColor);
END;

{------------------------------------------------------------------------}

Procedure StartCenser;
VAR
   Inside, Ins               : Boolean;
   Angle                     : Real;
   x1, y1, r1, v1            : Real;
   xSc, ySc                  : Integer;
   i                         : Integer;
   Button                    : Integer;
   xm, ym                    : Integer;
   Radius                    : Real;
   xOld, yOld, xNew, yNew    : Real;
   Input                     : TInputScreen;

{------------------------------------------------------------------------}

BEGIN
   Radius := 1.3;
   Inside := False;
   CritLength := LengthMin;
   StartLength := LengthMin;
   Length := LengthMin;
   GraphBackColor := DarkGray;
   OpenViewPort(1);
   SelectScale(1);
   HotKeys.Display;
   IF MouseInput THEN
   BEGIN
      Message('   Click on the censer and drag. Release to start the Censer');

      MouseBorders(0, MapY(-2-LengthMax) + Trunc(GetMaxY*0.08),
                   GetMaxX, Trunc(MapY(0)+GetMaxy*0.08));
      Starting := True;
      SaveAngle := 0;
      PlotPendulum(0, Length, Yellow);
      SaveAngle := 0;
      x1 := 0; y1 := -1;
      Map(0, 0, xSc, ySc);
      Map(0, -1, xm, ym);
      ShowMouse;
      REPEAT MouseGlobalPosn(xm,ym,button) UNTIL button<>0;
      ShowMouse;
      REPEAT
         HideMouse;
         IF y1 <> 0 THEN PlotPendulum(- ArcTan(x1/y1), Length, GraphBackColor);
         MouseGlobalPosn(xm, ym, button);
         MousePosn(x1, y1, 1, 1, Ins);
         IF y1 <> 0 THEN PlotPendulum(- ArcTan(x1/y1), Length, Yellow);
         ShowMouse;
         delay(10)
      UNTIL button=0;
      IF y1 <> 0 THEN PlotPendulum(- ArcTan(x1/y1), Length, Yellow);
      Message('');
      HideMouse;
      Starting := False;
      IF x1 <> 0 THEN
      BEGIN
         y[1] := - ArcTan(x1/y1);
         y[2] := 0;
         IF x1 > 0 THEN
         BEGIN
            Y1Sign := 1;
            Y2Sign := -1;
         END
         ELSE
         BEGIN
            Y1Sign := -1;
            Y2Sign := 1;
         END;
      END;
   END
   ELSE
   BEGIN
      ShowMouse;
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.25, 0.75, 0.35, 0.65);
         LoadLine('');
         LoadLine('   Enter a starting angle in degrees:');
         LoadLine('        -90 < {      } < 90');
         LoadLine('');
         LoadLine('              [  OK  ]');
         SetNumber(1, 0);
         SetNumberLimits(1, -90, 90);
         AcceptScreen;
         y[1] := GetNumber(1)*Pi/180;
         y[2] := 0;
         HideMouse;
         Starting := False;
         IF y[1] > 0 THEN
         BEGIN
            Y1Sign := 1;
            Y2Sign := -1;
         END
         ELSE
         BEGIN
            Y1Sign := -1;
            Y2Sign := 1;
         END;
         Done;
      END;
   END;

      Running := True;
      LightMenu := False;
      Time := 0;
      StepSize := 0.1;
      Starting := False;
   Pulling := True;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(X: Real; Y: Vector; VAR Z: Vector);
VAR
   LPrime    : Real;
BEGIN
   IF Y1Sign*Y2Sign < 0 THEN  {Descending}
   BEGIN
      IF Time < 2*DelT THEN
      BEGIN
         IF Time < DelT THEN
         BEGIN
            LPrime := LengthRate*Time;
            Length := LengthMin + LengthRate*Time*Time/2;
         END
         ELSE
         BEGIN
            LPrime := LengthRate*Delt - LengthRate*(Time - DelT);
            Length := LengthMin + LengthRate*DelT*DelT/2
                      - LengthRate*(Time - DelT)*(Time - DelT)/2
                      + LengthRate*DelT*(Time - DelT);
         END;
      END
      ELSE
      BEGIN
         LPrime := 0;
         Length := LengthMax;
      END;
   END
   ELSE  {Ascending}
   BEGIN
      IF Time < 2*DelT THEN
      BEGIN
         IF Time < DelT THEN
         BEGIN
            LPrime := -LengthRate*Time;
            Length := LengthMax - LengthRate*Time*Time/2;
         END
         ELSE
         BEGIN
            LPrime := -LengthRate*Delt + LengthRate*(Time - DelT);
            Length := LengthMax - LengthRate*DelT*DelT/2
                      + LengthRate*(Time - DelT)*(Time - DelT)/2
                      - LengthRate*DelT*(Time - DelT);
         END;
      END
      ELSE
      BEGIN
         LPrime := 0;
         Length := LengthMin;
      END;
   END ;
   Z[1] := Y[2];
   Z[2] := - 9.81*Sin(Y[1])/Length - Friction*y[2]/(Length*Length)
           - 2*LPrime*y[2]/Length;
END;

{-----------------------------------------------------------------------}

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
END;

{-----------------------------------------------------------------------}

PROCEDURE FindBottomOfSwing;
VAR
   SaveStepSize : Real;
   Count : Integer;
BEGIN
   Count := 0;
   SaveStepSize := StepSize;
   REPEAT
      Count := Count + 1;
      StepSize := - Y[1]/Y[2];
      Step(Time, StepSize, 0.001, Y, Time, StepSize, Y);
   UNTIL (Abs(Y[1]) < 0.001) OR (COUNT = 10);
   Y1Sign := - Y1Sign;
   StepSize := SaveStepSize;
   Time := 0;
   CritLength := Length; BottomFound := True;
   FirstStep := True;
END;
{-----------------------------------------------------------------------}

PROCEDURE FindTopOfSwing;
VAR
   SaveStepSize : Real;
   Count : Integer;
   Z : Vector;
BEGIN
   Count := 0;
   SaveStepSize := StepSize;
   REPEAT
      Count := Count + 1;
      Fun(Time, Y, Z);
      IF Abs(Z[2]) > 0.001 THEN
      BEGIN
         StepSize := - Y[2]/Z[2];
         Step(Time, StepSize, 0.001, Y, Time, StepSize, Y);
      END;
   UNTIL (ABS(Y[2]) < 0.0001) OR (COUNT = 10) OR (Z[2] = 0);
   Y2Sign := - Y2Sign;
   StepSize := SaveStepSize;
   Time := 0;
   CritLength := Length;
   FirstStep := True;
END;

{-----------------------------------------------------------------------}

PROCEDURE RunPendulum;
VAR
   OldAngle  : Real;
BEGIN

   OldAngle := y[1];
   OldLength := Length;
   IF Time < 2*DelT THEN
   BEGIN
      Pulling := True;
   END
   ELSE Pulling := False;
   IF Pulling THEN SaveAngle := SaveAngle + 0.1;
   IF (Time < DelT) AND (Time + StepSize > DelT)
        THEN StepSize := DelT - Time;
   IF (Time < 2*DelT) AND (Time + StepSize > 2*DelT)
        THEN StepSize := 2*DelT - Time;
   Step(Time, StepSize, 0.00000001, Y, Time, StepSize, Y);
   IF y[1] > 2*Pi THEN y[1] := y[1] - 2*Pi;
   IF y[1] < -2*Pi THEN y[1] := y[1] + 2*Pi;
   IF (y[1] < Pi) AND (y[1] > -Pi) THEN
   BEGIN
      IF Y1Sign*Y[1] < 0 THEN FindBottomOfSwing;
      IF Y2Sign*Y[2] < 0 THEN FindTopOfSwing;
   END;
   PlotPendulum(OldAngle, OldLength, GraphBackColor);
   PlotPendulum(y[1], Length, Yellow);
   Delay(Lag);
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 10;
      CASE Key OF
          1: BEGIN
                Running := False;
                StartCenser;
             END;
          2: IF Lag - DelLag > 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
          3: Lag := Lag + DelLag;
          4: BEGIN
               Running := False;
               HotKeys.Clear;
               MouseBorders(0, GetMaxY, GetMaxX, 0);
               LightMenu := True;
               ShowMouse;
            END;
      END;
END;

{-----------------------------------------------------------------------}

PROCEDURE HandleCenserMenu;

BEGIN
   With CenserMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: BEGIN
                  AboutCUPS;
                  LightMenu := True;
               END;
            2: BEGIN
                  ShowHelp('HelpPend.hlp', 'CenserAboutProgram');;
                  LightMenu := True;
               END;
            3: BEGIN
                  Configuration;
                  LightMenu := True;
               END;
            4: ExitRequest := True;
         END;
      2: BEGIN
            ShowHelp('HelpPend.hlp', 'CenserAboutModelA');
            ShowHelp('HelpPend.hlp', 'CenserAboutModelB');
            ShowHelp('HelpPend.hlp', 'CenserAboutModelC');
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF CenserData THEN StartCenser;
               END;
            2: StartCenser;
         END;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE SetStartingParameters;
BEGIN
   LengthMean := 3;
   StartLength := LengthMin;
   Length := LengthMin;
   Period0 := 2*Pi*Sqrt(LengthMean/9.81);
   LengthFraction := 0.2;
   PeriodFraction := 0.5;
   DelT := Period0*PeriodFraction/4;
   LengthMax := Length*(1 + LengthFraction);
   LengthMin := Length*(1 - LengthFraction);
   CritLength := LengthMin;
   Friction := 0.05;
   LengthRate := (LengthMax - LengthMin)/(DelT*DelT);
   Period0 := 2*Pi*Sqrt(LengthMean/9.81);
   DelT := Period0*PeriodFraction/4;
   LengthMax := LengthMean*(1 + LengthFraction);
   LengthMin := LengthMean*(1 - LengthFraction);
   LengthRate := (LengthMax - LengthMin)/(DelT*DelT);
   DefineScale(1, -1.2*LengthMax, 2.1*LengthMax,
                  -1.2*LengthMax - 2, 1.2*LengthMax);
   Lag := 100;
   ExitRequest := False;
   Running := False;
   MouseInput := True;
   LightMenu := True;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   DefineViewPort(1, 0.05, 0.95, 0.07, 0.93);
   DefineScale(1, -1.2*LengthMax, 1.8*LengthMax + 1.4,
                  -1.2*LengthMax - 2, 1.2*LengthMax);
   BottomFound := False;
END;

{-----------------------------------------------------------------------}

BEGIN {MAIN PROGRAM}

   CUPSInit;
   SetStartingParameters;
   Hello('HelpPend.hlp', 'CenserAboutProgram');
   SetUpCenserMenu;
   SetUpHotKeys;
   IF CenserData THEN StartCenser;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Running THEN RunPendulum;
      IF LightMenu THEN IF CenserMenu.Chosen THEN HandleCenserMenu;
   UNTIL ExitRequest;
   CUPSDone;
   CenserMenu.Done;
END.

