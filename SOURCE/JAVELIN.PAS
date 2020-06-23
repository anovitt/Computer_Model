PROGRAM Javelin;


USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 6;

TYPE
   vector = array[1..6] of real;

VAR
   JavelinMenu                 : TMenu;
   Sliders                     : TSliders;
   HotKeys                     : THotKeys;
   Key                         : Byte;
   Drag                        : Real;
   Lift                        : Real;
   HeightStart                 : Real;
   SpeedStart                  : Real;
   ThetaStart, ThetaDotStart   : Real;
   Delta                       : Real;
   Factor                      : Real;
   Dt                          : Real;
   Y                           : Vector;
   Time, StepSize              : Real;
   ExitRequest                 : Boolean;
   LightMenu                   : Boolean;
   Action                      : Boolean;
   Pause                       : Boolean;
   Lag                         : Integer;
   MinX, MAxX                  : Real;
   MinY, MaxY                  : Real;
   xJ, yJ, tJ                  : Array[0..200] OF Real;
   StepNumber                  : Integer;
   DelTime                     : Real;

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

PROCEDURE SetUpJavelinMenu;
VAR
   I      : Integer;
BEGIN
   WITH JavelinMenu DO
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
       row(3,2, 'Animate');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   JavelinMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Throw';
      Key[2] := 'F4-Faster';
      Key[3] := 'F5-Slower';
      Key[4] := 'F6-Input';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
END;

{-------------------------------------------------------------------------}

FUNCTION Input  : Boolean;
VAR
   BallData       : TInputScreen;
BEGIN
   WITH BallData DO
   BEGIN
       Init;
       DefineInputPort(0.14, 0.86, 0.06, 0.94);
       LoadLine('');
       LoadLine('           Data for Throwing a Javelin');
       LoadLine('');
       LoadLine('     The drag and lift forces act at the ''center of');
       LoadLine('  pressure,'' which is at a distance Delta from the');
       LoadLine('  center of mass. Enter a value in meters:');
       LoadLine('     Delta = {      } m, limits 0.1 to 0.5');
       LoadLine('');
       LoadLine('     Enter initial conditions:');
       LoadLine('           Height = {      } m,     limits 1 to 3');
       LoadLine('            Speed = {      } m/s,   limits 10 to 100');
       LoadLine('  Elevation angle = {      } deg,   limits 0 to 90');
       LoadLine('     Angular rate = {      } deg/s, limits -90 to 90');
       LoadLine('');
       LoadLine('     Enter a time interval for plotting the javelin:');
       LoadLine('               Dt = {       } > 0.01');
       LoadLine('     Enter a factor for exaggerating the length of the');
       LoadLine('  javelin: Factor = {       },      limits 1 to 10');
       LoadLine('');
       LoadLine('         [ Help ]       [  OK  ]      [Cancel]');
       SetHelpFile('HlpSport.hlp', 'JavelinInputHelp');
       SetNumber(1, Delta);
       SetNumberLimits(1, 0.1, 0.5);
       SetNumber(2, HeightStart);
       SetNumberLimits(2, 1, 3);
       SetNumber(3, SpeedStart);
       SetNumberLimits(3, 10, 100);
       SetNumber(4, ThetaStart);
       SetNumberLimits(4, 0, 90);
       SetNumber(5, ThetaDotStart);
       SetNumberLimits(5, -90, 90);
       SetNumber(6, Dt);
       SetNumberLimits(6, 0.01, 100);
       SetNumber(7, Factor);
       SetNumberLimits(7, 1, 10);
       AcceptScreen;
       Input := NOT Canceled;
       IF Canceled THEN Exit;
       Delta := GetNumber(1);
       HeightStart := GetNumber(2);
       SpeedStart := GetNumber(3);
       ThetaStart := GetNumber(4);
       ThetaDotStart := GetNumber(5);
       Dt := GetNumber(6);
       Factor := GetNumber(7);
       y[1] := 0;
       y[2] := SpeedStart*Cos(ThetaStart*Pi/180);
       y[3] := HeightStart;
       y[4] := SpeedStart*Sin(ThetaStart*Pi/180);
       y[5] := ThetaStart*Pi/180;
       y[6] := ThetaDotStart*Pi/180;
       Time := 0;
       StepSize := 0.1;
       Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x : Real; y : Vector; VAR z : Vector);
VAR
   Speed, Phi, Alpha, Drag, Lift     : Real;
BEGIN
   Speed := Sqrt(y[2]*y[2] + y[4]*y[4]);
   Phi := ArcTan(y[4]/y[2]);
   Alpha := Sin(y[5] - Phi);
   Drag := 0.00024*Exp(5.157*Abs(Alpha));
   Lift := 0.0;
   IF Alpha > 0.001 THEN
      Lift := 0.0127*Exp(1.34*Ln(Abs(Alpha)));
   z[1] := y[2];
   z[2] := - (Drag*y[2]*Speed + Lift*y[4]*Speed)/0.80625;
   z[3] := y[4];
   z[4] := - (Drag*y[4]*Speed - Lift*y[2]*Speed)/0.80625 - 9.81;
   z[5] := y[6];
   z[6] := - Delta*Speed*Speed*(Drag*Sin(Alpha) + Lift*Cos(Alpha))/0.42;
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
      temax := tol/100000;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol;
   yout := y;
   xout := xtemp + htemp;
   hout := h;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   ySave       : Vector;
   FlightTime  : Real;
   NextTime    : Real;
   WaitMessage : TWaitMessage;
BEGIN
   MinX := 0;
   MaxX := 0;
   MinY := 0;
   MaxY := 0;
   ySave := y;
   Time := 0;
   StepSize := 0.1;
   WaitMessage.Show;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      IF y[1] > MaxX THEN MaxX := y[1];
      IF y[3] > MaxY THEN MaxY := y[3];
   UNTIL (y[3] < 0);
   FlightTime := Time;
   DelTime := FlightTime/100;
   y := ySave;
   Time := 0;
   xJ[0] := y[1];
   yJ[0] := y[3];
   tJ[0] := y[5];
   StepNumber := 0;
   REPEAT
      WaitMessage.UpDate;
      StepNumber := StepNumber + 1;
      NextTime := Time + DelTime;
      REPEAT
         StepSize := NextTime - Time;
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Abs(Time - NextTime) < 0.0001;
      xJ[StepNumber] := y[1];
      yJ[StepNumber] := y[3];
      tJ[StepNumber] := y[5];
   UNTIL (y[3] < 0);
   yJ[StepNumber] := 0;
   WaitMessage.Hide;
   DefineScale(1, -0.1*MaxX, 1.1*MaxX, -0.2*MaxY, 1.2*MaxY);
   y := ySave;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotJavelin(xJ, yJ, Angle: Real; JavelinColor: Word);
VAR
   xTip, yTip, xTail, yTail     : Real;
BEGIN
   xTip := xJ + Factor*Cos(Angle);
   yTip := yJ + Factor*Sin(Angle);
   xTail := 2*xJ - xTip;
   yTail := 2*yJ - yTip;
   IF JavelinColor = GraphBackColor THEN
   BEGIN
      SetColor(JavelinColor);
      PlotLine(xJ, yJ, xTip, yTip);
      PlotLine(xJ, yJ, xTail, yTail);
   END
   ELSE
   BEGIN
      SetColor(Yellow);
      PlotLine(xJ, yJ, xTip, yTip);
      SetColor(White);
      PlotLine(xJ, yJ, xTail, yTail);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpAnimation;
BEGIN
   FindScale;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   DrawAxis(0, 0, 10, 10, White);
   PutLabel(Bottom, 'meters');
   PutLabel(left, 'meters');
   Time := 0;
   StepSize := 0.1;
   Action := True;
   Pause := True;
   LightMenu := False;
   HotKeys.Key[1] := 'F2-Throw';
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotTrajectory;
VAR
   NextTime       : Real;
   xOld, yOld     : Real;
   I              : Integer;
BEGIN
   Time := 0;
   I := 0;
   REPEAT
      NextTime := Time + Dt;
      REPEAT
         I := I + 1;
         PlotLine(xJ[I-1], yJ[I-1], xJ[I], yJ[I]);
         Time := Time + DelTime;
      UNTIL (Time + DelTime > NextTime) OR (I = StepNumber);
      PlotJavelin(xJ[I], yJ[I], tJ[I], Yellow);
   UNTIL I = StepNumber;
END;

{------------------------------------------------------------------------}

PROCEDURE MoveJavelin;
VAR
   OldY    : Vector;
   I       : Integer;
BEGIN
   FOR I := 1 TO StepNumber DO
   BEGIN
      Delay(Lag);
      PlotJavelin(xJ[I-1], yJ[I-1], tJ[I-1], GraphBackColor);
      PlotJavelin(xJ[I], yJ[I], tJ[I], White);
   END;
   BEGIN
      Action := False;
      Pause := True;
      HotKeys.Key[1] := 'F2-Throw';
      HotKeys.BackColor := Blue;
      HotKeys.HotKeyColor := Yellow;
      HotKeys.Display;
      PlotTrajectory;
      PrintXY(0.4, 0.25, 'Range: '+NumStr(xJ[StepNumber], 4, 1)+' meters');
      PrintXY(0.25, 0.88, 'Javelin shown at intervals of '+NumStr(Dt, 4, 2)+
                         ' seconds');
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleJavelinMenu;
BEGIN
   With JavelinMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpSport.hlp', 'JavelinAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpSport.hlp', 'JavelinAboutModel');
            2: ShowHelp('WalkThru.hlp', 'Javelin');
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF Input THEN
                  BEGIN
                     SetUpAnimation;
                  END;
               END;
            2: SetUpAnimation;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag   : Integer;
BEGIN
   DelLag := 10;
   CASE Key OF
      1: BEGIN
               IF Pause THEN
               BEGIN
                  Pause := False;
                  WITH HotKeys DO Key[1] := 'F2-Pause';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
               END
               ELSE
               BEGIN
                  Pause := True;
                  WITH HotKeys DO Key[1] := 'F2-Move';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
               END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      3: Lag := Lag + DelLag;
      4: IF Input THEN SetUpAnimation;
      5: BEGIN
            Action := False;
            Pause := False;
            HotKeys.Clear;
            LightMenu := True;
            ShowCursor;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.1, 0.9, 0.2, 0.8);
   HeightStart := 2;
   SpeedStart := 25;
   ThetaStart := 45;
   ThetaDotStart := 0;
   Delta := 0.255;
   Dt := 0.2;
   Factor := 5;
   y[1] := 0;
   y[2] := SpeedStart*Cos(ThetaStart*Pi/180);
   y[3] := HeightStart;
   y[4] := SpeedStart*Sin(ThetaStart*Pi/180);
   y[5] := ThetaStart*Pi/180;
   y[6] := ThetaDotStart*Pi/180;
   Time := 0;
   StepSize := 0.1;
   Lag := 50;
   Hello('HlpSport.hlp', 'JavelinAboutProgram');
   SetUpJavelinMenu;
   SetUpHotKeys;
   Action := False;
   Pause := True;
   ExitRequest := False;
   LightMenu := True;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   GetSetUp;
   IF Input THEN SetUpAnimation;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Action AND (NOT Pause) THEN MoveJavelin;
      IF LightMenu THEN IF JavelinMenu.Chosen THEN HandleJavelinMenu;
   UNTIL ExitRequest;
   CUPSDone;
   JavelinMenu.Done;
END.