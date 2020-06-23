PROGRAM YoYo;

USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 3;

TYPE
   vector = array[1..3] of real;

VAR
   YoYoMenu                     : TMenu;
   HotKeys                      : THotKeys;
   Key                          : Byte;
   ThetaDot                     : Real;
   xMax, xDotMax, ThetaDotMax   : Real;
   Y                            : Vector;
   XArray, ThArray              : Array[0..1000] OF Real;
   DelTime                      : Real;
   StepSize                     : Real;
   Time                         : Real;
   TimeMax                      : Real;
   xDot                         : Real;
   IM, Length                   : Real;
   Alpha                        : Real;
   Radius, R0, R1, R2           : Real;
   Gravity                      : Real;
   Gyration                     : Real;
   Count                        : Integer;
   InputStupid                  : Boolean;
   LightMenu                    : Boolean;
   ExitRequest                  : Boolean;
   Lag                          : Integer;

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

PROCEDURE SetUpYoyoMenu;
VAR
   I      : Integer;
BEGIN
   With YoyoMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About the parameters');
       row(2,3, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Enter initial conditions');
       row(3,3, 'Play');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   YoyoMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Parameters';
      Key[3] := 'F3-Start';
      Key[4] := 'F4-Yoyo';
      Key[5] := 'F10-Menu';
   END;
END;

{------------------------------------------------------------------------}

FUNCTION SetParameters : Boolean;
VAR
   Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
         DefineInputPort(0.06, 0.94, 0.05, 0.95);
         LoadLine('');
         LoadLine('                    Parameters for a Yoyo');
         LoadLine('');
         LoadLine('    R0 is the radius of the spindle at the center of the yoyo.');
         LoadLine('    R1 is the radius of the combination spindle and string, ');
         LoadLine(' when the string is fully wound around the spindle.');
         LoadLine('    R2 is the outer radius of the Yoyo.');
         LoadLine('    Enter values. 0 < R0 < R1 < R2. Units are inches.');
         LoadLine('             R0:       0 < {        } < 1 ');
         LoadLine('             R1:       0 < {        } < 1 ');
         LoadLine('             R2:       0 < {        } < 2 ');
         LoadLine('    Enter the length of the string wound around the spindle');
         LoadLine(' when it is fully wound.');
         LoadLine('                      12 < {        } < 36');
         LoadLine('    The moment of inertia of the yoyo is I = k*M*R2^2, where');
         LoadLine(' where M is the mass and k can lie between 0.2 and 1. If k = 1,');
         LoadLine(' all the mass is concentrated at the outer rim. Enter a value for');
         LoadLine('              k:     0.1 < {        } < 1');
         LoadLine('');
         LoadLine('             [ Help ]      [  OK  ]      [Cancel]');
         SetNumber(1, R0);
         SetNumberLimits(1, 0.0000001, 1);
         SetNumber(2, R1);
         SetNumberLimits(2, 0.0000001, 1);
         SetNumber(3, R2);
         SetNumberLimits(3, 0.0000001, 2);
         SetNumber(4, Length);
         SetNumberLimits(5, 12, 36);
         SetNumber(5, Gyration);
         SetNumberLimits(5, 0.2, 1);
         SetHelpFile('HelpMisc.Hlp', 'YoyoAboutParameters');
         AcceptScreen;
         InputStupid := False;
         SetParameters := NOT Canceled;
         IF Canceled THEN Exit;
         R0 := GetNumber(1);
         R1 := GetNumber(2);
         R2 := GetNumber(3);
         Length := GetNumber(4);
         Gyration := GetNumber(5);
         IF (R0 >= R1) OR (R1 >= R2) THEN InputStupid := True;
         IF NOT InputStupid THEN
         BEGIN
            Alpha := (R1*R1 - R0*R0)/(2*Length);
            IM := Gyration*R2*R2;
         END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
{y1 is theta, y2 is x, y3 is xdot.}
BEGIN
   Radius := R1 - Alpha*y[1];
   z[1] := y[3]/Radius;
   z[2] := y[3];
   z[3] := (Gravity*12 - Alpha*IM*y[3]*y[3]/(Radius*Radius*Radius*Radius))
            /(1 + IM/(Radius*Radius));
   ThetaDot := z[1];
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

PROCEDURE DrawYoyo(Distance, Radius, Angle : Real; YoyoColor : Word);
VAR
   SaveColor           : Word;
   InnerRad, OuterRad  : Integer;
   xCenter, yCenter    : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(YoyoColor);
   InnerRad := MapX(Radius) - MapX(0);
   OuterRad := MapX(R2) - MapX(0);
   xCenter := MapX(0);
   yCenter := MapY(-Distance);
   Circle(xCenter-InnerRad, yCenter, InnerRad);
   Circle(xCenter-InnerRad, yCenter, OuterRad);
   PlotLine(0, 3, 0, - Distance);
   {PlotLine(0, -Distance,
   Radius*Cos(Angle), -Distance + Radius*Sin(Angle));}
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE FindMaximumValues;
VAR
   NextTime     : Real;
BEGIN
   Time := 0;
   y[2] := 0;
   y[3] := xDot;
   y[1] := 0;
   StepSize := DelTime;
   XArray[0] := 0;
   ThArray[0] := 0;
   xMax := Length;
   xDotMax := 0;
   ThetaDotMax := 0;
   Time := 0;
   Count := 0;
   NextTime := Time + DelTime;
   REPEAT
      REPEAT
         StepSize := NextTime - Time;
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Abs(NextTime - Time) < 0.00001;
      NextTime := Time + DelTime;
      Count := Count + 1;
      XArray[Count] := y[2];
      ThArray[Count] := y[1];
      IF ThetaDot > ThetaDotMax THEN ThetaDotMax := ThetaDot;
      IF y[3] > xDotMax THEN xDotMax := y[3];
   UNTIL y[2] > Length;
   DefineScale(1, -Time*0.05, Time*1.05, -Length*0.05, Length*1.05);
   DefineScale(2, -Time*0.05, Time*1.05, -xDotMax*0.05, xDotMax*1.05);
   DefineScale(3, -Time*0.05, Time*1.05, -ThetaDotMax*0.05,
                                          ThetaDotMax*1.05);
   DefineScale(4, -4, 4, -Length-4, 4);
   TimeMax := Time;
END;

{------------------------------------------------------------------------}

PROCEDURE MoveYoyo;
VAR
   I       : Integer;
   Rad     : Real;
   Test    : Real;
BEGIN
   OpenViewPort(4);
   SelectScale(4);
   HideMouse;
   DrawYoyo(0, R1, 0, White);
   Rad := R1;
   FOR I := 1 TO Count DO
   BEGIN
      Test := R1 - Alpha*ThArray[I];
      Delay(30);
      DrawYoyo(XArray[I-1], Rad, ThArray[I-1], GraphBackColor);
      IF Test > 0 THEN Rad := (Test) ELSE Rad := R0;
      DrawYoyo(XArray[I], Rad, ThArray[I], White);
   END;
   Delay(100);
   FOR I := 1 TO Count DO
   BEGIN
      Test := R1*R1 - 2*Alpha*XArray[Count - I];
      Delay(30);
      DrawYoyo(XArray[Count+1-I], Rad, ThArray[Count+1-I], GraphBackColor);
      IF Test > 0 THEN Rad := Sqrt(Test) ELSE Rad := R0;
      DrawYoyo(XArray[Count-I], Rad, ThArray[Count-I], White);
   END;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotData;
VAR
   xOld, xDotOld, ThetaDotOld, TimeOld : Real;
BEGIN
   FindMaximumValues;
   OpenViewPort(1);
   SelectScale(1);
   LightMenu := False;
   Message('');
   HotKeys.Display;
   PlotLine(0, 0, TimeMax, 0);
   PLotLine(0, 0, 0, Length);
   PlotLine(0, Length, TimeMax/50, Length);
   OutTextXY(MapX(0), MapY(Length), NumStr(Length, 3, 0)+'    x, in');
   OpenViewPort(2);
   SelectScale(2);
   PlotLine(0, 0, TimeMax, 0);
   PLotLine(0, 0, 0, xDotMax);
   PlotLine(0, Trunc(xDotMax), TimeMax/50, Trunc(xDotMax));
   OutTextXY(MapX(0), MapY(Trunc(xDotMax)),
   NumStr(Trunc(xDotMax), 3, 0)+'    xDot, in/sec' );
   OpenViewPort(3);
   SelectScale(3);
   PlotLine(0, 0, TimeMax, 0);
   PLotLine(0, 0, 0, ThetaDotMax);
   PlotLine(0, Trunc(ThetaDotMax), TimeMax/50, Trunc(ThetaDotMax));
   OutTextXY(MapX(0), MapY(Trunc(ThetaDotMax)),
          NumStr(Trunc(ThetaDotMax), 4, 0)+'    ThetaDot, rad/sec');
   PlotLine(TimeMax, 0, TimeMax, ThetaDotMax/50);
   OutTextXY(MapX(TimeMax/2), MapY(ThetaDotMax/10), 'Time, sec');
   OutTextXY(MapX(TimeMax*0.95), MapY(ThetaDotMax/10), NumStr(TimeMax, 4, 2));
   Time := 0;
   y[2] := 0;
   y[3] := xDot;
   y[1] := 0;
   StepSize := 0.1;
   Time := 0;
   TimeOld := Time;
   xOld := y[2];
   xDotOld := y[3];
   ThetaDotOld := y[3]/R1;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      SelectViewPort(1);
      SelectScale(1);
      PlotLine(TimeOld, xOld, Time, y[2]);
      xOld := y[2];
      SelectViewPort(2);
      SelectScale(2);
      PlotLine(TimeOld, xDotOld, Time, y[3]);
      xDotOld := y[3];
      SelectViewPort(3);
      SelectScale(3);
      PlotLine(TimeOld, ThetaDotOld, Time, ThetaDot);
      ThetaDotOld := ThetaDot;
      TimeOld := Time;
   UNTIL y[2] > Length;
   MoveYoyo;
END;

{------------------------------------------------------------------------}

PROCEDURE GetXDot;
VAR
   Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.35, 0.65);
      LoadLine('');
      LoadLine(' Enter a positive value for the initial speed:');
      LoadLine('            xDot = {        } in/sec');
      LoadLine('');
      LoadLine('                   [  OK  ]');
      SetNumber(1, xDot);
      AcceptScreen;
      xDot := GetNumber(1);
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetData;
BEGIN
   REPEAT
      IF SetParameters AND NOT InputStupid THEN
      BEGIN
         GetXDot;
         PlotData;
      END;
      IF InputStupid THEN Announce('Make R0 < R1 < R2, you fool!');
   UNTIL NOT InputStupid;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleYoyoMenu;
BEGIN
   With YoyoMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpMisc.Hlp', 'YoyoAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpMisc.Hlp', 'YoyoAboutModelA');
                  ShowHelp('HelpMisc.Hlp', 'YoyoAboutModelB');
               END;
            2: ShowHelp('HelpMisc.Hlp', 'YoyoAboutParameters');
            3: ShowHelp('WalkThru.hlp', 'Yoyo');
         END;
      3: CASE RowChosen OF
            1: GetData;
            2: GetXDot;
            3: PlotData;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag      : Integer;
BEGIN
   DelLag := 10;
   CASE Key OF
      1: ShowHelp('HelpMisc.Hlp', 'YoyoHotKeysHelp');
      2: GetData;
      3: BEGIN
            GetXDot;
            PlotData;
         END;
      4: MoveYoyo;
      5: BEGIN
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   Gravity := 32;
   R0 := 0.05;
   R1 := 0.2;
   R2 := 2;
   xDot := 1;
   Gyration := 0.2;
   Length := 36;
   IM := Gyration*R2*R2;
   DefineViewPort(1, 0.05, 0.80, 0.66, 0.94);
   DefineViewPort(2, 0.05, 0.80, 0.36, 0.64);
   DefineViewPort(3, 0.05, 0.80, 0.06, 0.34);
   DefineViewPort(4, 0.82, 0.95, 0.06, 0.94);
   DelTime := 0.04;
   ExitRequest := False;
   LightMenu := True;
   SetUpHotKeys;
   SetUpYoyoMenu;
END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Hello('HelpMisc.Hlp', 'YoYoAboutProgram');
   GetSetUp;
   GetData;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF LightMenu AND YoyoMenu.Chosen THEN HandleYoyoMenu;
   UNTIL ExitRequest;
   CUPSDone;
   YoyoMenu.Done;
END.

