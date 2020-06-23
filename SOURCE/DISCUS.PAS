PROGRAM Discus;

USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 4;

TYPE
   vector = array[1..4] of real;

VAR
   DiscusMenu                 : TMenu;
   HotKeys                    : THotKeys;
   Key                        : Byte;
   WindVel                    : Real;
   DiskAngle                  : Real;
   SinAngle, CosAngle         : Real;
   Density                    : Real;
   Area                       : Real;
   Time                       : Real;
   Mass                       : Real;
   Height                     : Real;
   Gravity                    : Real;
   StepSize                   : Real;
   InitSpeed                  : Real;
   InitBeta                   : Real;
   xMax, yMax                 : Real;
   Lag                        : Integer;
   Action                     : Boolean;
   LightMenu                  : Boolean;
   ExitRequest                : Boolean;
   InputCanceled              : Boolean;
   Rescale                    : Boolean;
   Y                          : Vector;
   TailX, TailY               : Array[0..10] OF Real;
   TailNumber                 : Word;

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

PROCEDURE SetUpDiscusMenu;
VAR
   I      : Integer;
BEGIN
   With DiscusMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Throw the discus');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   DiscusMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(7);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Throw';
      Key[3] := 'F3-Cleanup';
      Key[4] := 'F4-Input';
      Key[5] := 'F5-Faster';
      Key[6] := 'F6-Slower';
      Key[7] := 'F10-Menu';
   END;
END;

{------------------------------------------------------------------------}

FUNCTION GetDiscusData : Boolean;
VAR
   DiscusData   : TInputScreen;
BEGIN
   WITH DiscusData DO
   BEGIN
     Init;
     DefineInputPort(0.16, 0.84, 0.0, 0.95);
     LoadLine('');
     LoadLine('            Input for throwing a discus');
     LoadLine('');
     LoadLine('  Enter the initial conditions: ');
     LoadLine('     Height at which the discus is thrown:');
     LoadLine('            1 <= {     } <= 2 meters');
     LoadLine('                  Speed:');
     LoadLine('            1 <= {     } <= 50 m/s');
     LoadLine('  Angle between the velocity and the horizontal:');
     LoadLine('            0 <= {     } <= 80 degrees');
     LoadLine('');
     LoadLine('     The angle between the discus and the');
     LoadLine('  horizontal remains constant. It should be ');
     LoadLine('  between 0 to 20 degrees less than the angle');
     LoadLIne('  immediately above. Enter this angle:');
     LoadLine('                 {     } degrees');
     LoadLIne('');
     LoadLine('  Enter the wind speed. (Positive if if discus is');
     LoadLIne('  thrown into the wind.)');
     LoadLine('          -50 <= {     } <= 50 m/s');
     LoadLine('');
     LoadLine('             [  OK  ]            [Cancel]');
     SetNumber(1, Height);
     SetNumberLimits(1, 0, 2);
     SetNumber(2, InitSpeed);
     SetNumberLimits(2, 1, 50);
     SetNumber(3, InitBeta);
     SetNumberLimits(3, 0, 80);
     SetNumber(4, DiskAngle);
     SetNumber(5, WindVel);
     SetNumberLimits(5, -50, 50);
     AcceptScreen;
     GetDiscusData := NOT Canceled;
     IF NOT Canceled THEN
     BEGIN
        Height := GetNumber(1);
        InitSpeed := GetNumber(2);
        InitBeta := GetNumber(3);
        DiskAngle := GetNumber(4);
        WindVel := GetNumber(5);
        SinAngle := Sin(DiskAngle*Pi/180);
        CosAngle := Cos(DiskAngle*Pi/180);
        Rescale := True;
     END;
     Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION DragCoefficient(Psi  : Real): Real;
BEGIN
   Psi := (180/Pi)*Psi;
   IF Psi <= 5 THEN DragCoefficient := 0.06;
   IF (Psi > 5) AND (Psi <= 30) THEN
                     DragCoefficient := 0.06 + (0.48/25)*(Psi - 5);
   IF (Psi > 30) AND (Psi <= 70) THEN
                     DragCoefficient := 0.54 + (0.46/40)*(Psi - 30);
   IF (Psi > 70) AND (Psi <= 90) THEN
                     DragCoefficient := 1.00 + (0.07/20)*(Psi - 70);
END;

{------------------------------------------------------------------------}

FUNCTION LiftCoefficient(Psi  : Real): Real;
BEGIN
   Psi := (180/Pi)*Psi;
   IF Psi <= 28 THEN LiftCoefficient := (0.875/28)*Psi;
   IF (Psi > 28) AND (Psi <= 35) THEN
                     LiftCoefficient := 0.875 - (0.275/7)*(Psi - 28);
   IF (Psi > 35) AND (Psi <= 70) THEN
                     LiftCoefficient := 0.60 - (0.25/35)*(Psi - 35);
   IF (Psi > 70) AND (Psi <= 90) THEN
                     LiftCoefficient := 0.35 - (0.35/20)*(Psi - 70);
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
VAR
   VRelX, VRelY, VRelMag   : Real;
   AttackAngle             : Real;
BEGIN
   VRelX := y[2] + WindVel;
   VRelY := y[4];
   VRelMag := Sqrt(VRelX*VRelX + VRelY*VRelY);
   IF Abs(VRelX) > 0.01 THEN
        AttackAngle := Abs(ArcTan(VRelY/VRelX) - DiskAngle*(Pi/180))
   ELSE AttackAngle := Abs(Pi/2 - DiskAngle*(Pi/180));
   z[1] := y[2];
   z[2] := - (Density*Area/(2*Mass))*VRelMag*
              (DragCoefficient(AttackAngle)*VRelX +
               LiftCoefficient(AttackAngle)*VRelY);
   z[3] := y[4];
   z[4] := - (Density*Area/(2*Mass))*VRelMag*
              (DragCoefficient(AttackAngle)*VRelY -
               LiftCoefficient(AttackAngle)*VRelX) - Gravity;
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

{------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   YScale     : Vector;
   IMax, I    : Integer;
BEGIN
   y[1] := 0;
   y[3] := Height;
   y[2] := InitSpeed*Cos(InitBeta*(Pi/180));
   y[4] := InitSpeed*Sin(InitBeta*(Pi/180));
   YScale[1] := y[1];
   YScale[2] := y[2];
   YScale[3] := y[3];
   YScale[4] := y[4];
   Time := 0;
   StepSize := 0.1;
   Action := True;
   YMax := 0;
   REPEAT
      Step(Time, StepSize, 0.000001, YScale, Time, StepSize, YScale);
      IF yScale[3] > YMax THEN YMax := yScale[3];
   UNTIL (yScale[3] < 0) OR (y[1] > 1000) OR (Time > 10);
   xMax := YScale[1];
   DefineScale(1, -0.1*xMax, 1.1*xMax, -0.2*Ymax, 1.1*YMax);
   OpenViewPort(1);
   SelectScale(1);
   HotKeys.Display;
   Message('');
   Time := 0;
   PlotLine(0, 0, yScale[1] + 5, 0);
   IMax := Trunc(xMax/10);
   IF IMax >= 1 THEN
   BEGIN
      FOR i := 1 TO IMax DO
      BEGIN
         PlotLine(I*10, 0, I*10, 0.05*yMax);
         OutTextXY(MapX(I*10-XMax/30), MapY(-0.05*YMax), NumStr(I*10, 3, 0));
         IF I = IMax THEN
            OutTextXY(MapX(I*10-XMax/20), MapY(-0.1*YMax), 'meters');
      END;
   END;
   PlotLine(0, 0, 0, 1.05*yMax);
   PlotLine(0, Trunc(yMax), 0.02*xMax, Trunc(yMax));
   OutTextXY(MapX(-0.05*xMax), MapY(Trunc(yMax)), NumStr(Trunc(yMax), 2, 0));
   Rescale := False;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotDiscus(xd, yd : Real; DColor : Word);
VAR
   SaveColor      : Word;
   x1, y1, x2, y2 : Real;
   Radius         : Real;
BEGIN
   SaveColor := GetColor;
   SetColor(DColor);
   Radius := xMax/100;
   x1 := xd - Radius*CosAngle;
   y1 := yd - Radius*SinAngle;
   x2 := xd + Radius*CosAngle;
   y2 := yd + Radius*SinAngle;
   PlotLine(x1, y1, x2, y2);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotTail;
VAR
   I      : Integer;
BEGIN
   IF TailNumber < 10 THEN
   BEGIN
      TailNumber := TailNumber + 1;
      TailX[TailNumber] := y[1];
      TailY[TailNumber] := y[3];
   END
   ELSE
   BEGIN
      FOR I := 0 TO 9 DO
      BEGIN
         TailX[I] := TailX[I+1];
         TailY[I] := TailY[I+1];
      END;
      TailX[10] := y[1];
      TailY[10] := y[3];
   END;
   FOR I := 1 TO TailNumber DO
      PlotLine(TailX[i-1], TailY[i-1], TailX[i], TailY[i]);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveDiscus;
VAR
   xOld, yOld        : Real;
   xFinal            : Real;
   xPrint, yPrint    : Real;
BEGIN
   xPrint := MapX(1.05*xMax)/GetMaxX;
   yPrint := 1 - MapY(-0.12*yMax)/GetMaxY;
   Delay(Lag);
   xOld := y[1]; yOld := y[3];
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF StepSize > 0.01 THEN StepSize := 0.01;
   PlotDiscus(xOld, yOld, GraphBackColor);
   IF y[3] >= 0 THEN
      BEGIN
         PlotTail;
         PlotDiscus(y[1], y[3], White);
      END
      ELSE
      BEGIN
         xFinal := (xOld*y[3]-yOld*y[1])/(y[3]-yOld);
         PlotLine(xOld, yOld, xFinal, 0);
         Action := False;
         RubOutXY(xPrint, yPrint, 6, GraphBackColor);
         PrintXY(xPrint, yPrint, NumStr(xFinal, 3, 1));
      END;
   IF y[1] > 1.1*xMax THEN Action := False;
END;

{------------------------------------------------------------------------}

PROCEDURE ThrowDiscus;
BEGIN
   {FindScale;}
   y[1] := 0;
   y[3] := Height;
   y[2] := InitSpeed*Cos(InitBeta*(Pi/180));
   y[4] := InitSpeed*Sin(InitBeta*(Pi/180));
   Time := 0;
   TailNumber := 0;
   TailX[0] := y[1];
   TailY[0] := y[3];
   StepSize := 0.1;
   Action := True;
   LightMenu := False;
   HideMouse;
   REPEAT
      Delay(Lag);
      MoveDiscus;
   UNTIL NOT Action;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE GetData;
VAR
   DataOK   : Boolean;
BEGIN
   DataOK := False;
   REPEAT
      IF NOT GetDiscusData THEN
         InputCanceled := True
      ELSE
      BEGIN
         InputCanceled := False;
         IF (InitBeta - DiskAngle < 0)
            OR (InitBeta - DiskAngle > 20)
         THEN
         BEGIN
            DataOK := False;
            Announce(
            'Difference between the angles is too great. Try again');
         END
         ELSE DataOK := True;
      END;
   UNTIL DataOK OR InputCanceled;
   IF (NOT DataOK) OR InputCanceled THEN
                 LightMenu := True;
      {ELSE ThrowDiscus;}
END;

{------------------------------------------------------------------------}

PROCEDURE HandleDiscusMenu;
BEGIN
   With DiscusMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpSport.hlp', 'DiscusAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpSport.hlp', 'DiscusAboutModel');
            2: ShowHelp('WalkThru.hlp', 'Discus');
         END;
      3: CASE RowChosen OF
            1: GetData;
            2: BEGIN
                  LightMenu := False;
                  IF Rescale THEN FindScale;
                  {ThrowDiscus;}
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag      : Integer;
BEGIN
   DelLag := 5;
   CASE Key OF
      1: ShowHelp('HlpSport.hlp', 'DiscusHotKeyHelp');
      2: ThrowDiscus;
      3: FindScale;
      4: GetData;
      5: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      6: Lag := Lag + DelLag;
      7: BEGIN
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.05, 0.95, 0.1, 0.94);
   Density := 1.29;
   Mass := 2.0;
   Area := 0.038;
   Gravity := 9.81;
   InitSpeed := 25;
   InitBeta := 20;
   DiskAngle := (InitBeta - 10);
   SinAngle := Sin(DiskAngle*Pi/180);
   CosAngle := Cos(DiskAngle*Pi/180);
   WindVel := 0;
   Height := 1.8;
   Rescale := True;
   xMax := 60;
   yMax := 6;
   DefineScale(1, -0.1*xMax, 1.1*xMax, -0.2*Ymax, 1.1*YMax);
   Lag := 20;
   ExitRequest := False;
   LightMenu := True;
   SetUpHotKeys;
   SetUpDiscusMenu;
END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Hello('HlpSport.hlp', 'DiscusAboutProgram');
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF LightMenu THEN IF DiscusMenu.Chosen THEN HandleDiscusMenu;
   UNTIL ExitRequest;
   CUPSDone;
   DiscusMenu.Done;
END.

