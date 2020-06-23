PROGRAM Golf;


USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 6;

TYPE
   vector = array[1..6] of real;

VAR
   BallMenu                 : TMenu;
   HotKeys                  : THotKeys;
   Key                      : Byte;
   XSpin, YSpin, ZSpin      : Real;
   VStart, ThetaStart       : Real;
   CD, CL                   : Real;
   Gravity                  : Real;
   Y                        : Vector;
   Time, StepSize           : Real;
   ExitRequest              : Boolean;
   LightMenu                : Boolean;
   Action                   : Boolean;
   Pause                    : Boolean;
   XYPlane, YZPlane, ZXPlane: Boolean;
   Driven                   : Boolean;
   Lag                      : Integer;
   FirstDrive               : Boolean;
   MinX, MAxX               : Real;
   MinY, MaxY               : Real;
   MinZ, MaxZ               : Real;
   xB, yB, zB               : Array[0..200] OF Real;
   StepNumber               : Integer;

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

PROCEDURE SetUpBallMenu;
VAR
   I      : Integer;
BEGIN
   With BallMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About drag');
       row(2,3, 'About lift');
       row(2,4, 'About the demonstration');
       row(2,5, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Select display');
       row(3,3, 'See drives');
       row(3,4, 'Run demonstration');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   BallMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Drive';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-NewDrive';
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
       DefineInputPort(0.2, 0.8, 0.25, 0.75);
       LoadLine('');
       LoadLine('       Data for a Drive in Golf');
       LoadLine('');
       LoadLine('   Enter a number for the drag coefficient:');
       LoadLine('        0 <= CD = {        } <= 1');
       LoadLine('');
       LoadLine('   Enter a number for the lift coefficient:');
       LoadLine('        0 <= CL = {        } <= 1');
       LoadLine('');
       LoadLine('       [ Help ]    [  OK  ]    [Cancel]');
       SetNumber(1, CD);
       SetNumberLimits(1, 0, 1);
       SetNumber(2, CL);
       SetNumberLimits(2, 0, 1);
       SetHelpFile('HlpSport.hlp', 'GolfDragAndLift');
       AcceptScreen;
       Input := NOT Canceled;
       IF Canceled THEN BEGIN Done; Exit; END;
       CD := GetNumber(1);
       CL := GetNumber(2);
       Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x : Real; y : Vector; VAR z : Vector);
VAR
   Speed     : Real;
   L         : Real;
BEGIN
   Speed := Sqrt(y[2]*y[2] + y[4]*y[4] + y[6]*y[6]);
   z[1] := y[2];
   z[2] := - CD*Speed*y[2] + CL*(YSpin*y[6] - ZSpin*y[4]);
   z[3] := y[4];
   z[4] := - CD*Speed*y[4] + CL*(ZSpin*y[2] - XSpin*y[6]);
   z[5] := y[6];
   z[6] := - CD*Speed*y[6] + CL*(XSpin*y[4] - YSpin*y[2]) - Gravity;
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

PROCEDURE SelectDisplay;
VAR
   DisplayData    : TInputScreen;
   InputStupid    : Boolean;
BEGIN
   REPEAT
      WITH DisplayData DO
      BEGIN
         Init;
         DefineInputPort(0.23, 0.77, 0.15, 0.85);
         LoadLine('');
         LoadLine('    Options for animation display');
         LoadLine('');
         LoadLine('  The x-axis points forward.');
         LoadLine('  The y-axis points to the left.');
         LoadLine('  The z-axis points vertically upward.');
         LoadLine('');
         LoadLine('  You can view the animation projected');
         LoadLine('  into any of the coordinate planes.');
         LoadLine('');
         LoadLine('        x-y plane: #1 Yes  #1 No');
         LoadLine('        y-z plane: #2 Yes  #2 No');
         LoadLine('        z-x plane: #3 Yes  #3 No');
         LoadLine('');
         LoadLine('               [  OK  ]     ');
         IF XYPlane THEN SetRadioButton('1', 1) ELSE SetRadioButton('1', 2);
         IF YZPlane THEN SetRadioButton('2', 1) ELSE SetRadioButton('2', 2);
         IF ZXPlane THEN SetRadioButton('3', 1) ELSE SetRadioButton('3', 2);
         AcceptScreen;
         IF Canceled THEN
         BEGIN
            Done;
            LightMenu := True;
            Exit;
         END;
         IF GetRadioButton('1') = 1 THEN XYPlane := True
                                    ELSE XYPlane := False;
         IF GetRadioButton('2') = 1 THEN YZPlane := True
                                    ELSE YZPlane := False;
         IF GetRadioButton('3') = 1 THEN ZXPlane := True
                                    ELSE ZXPlane := False;
         Done;
     END;
     IF (XYPlane = False) AND (YZPlane = False) AND (ZXPlane = False)
     THEN
     BEGIN
        InPutStupid := True;
        Announce('You gotta see at least ONE plane, stupid');
     END
     ELSE InputStupid := False;
   UNTIL NOT InputStupid;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpGraphics;
BEGIN
   IF XYPlane THEN
   BEGIN
      IF ZXPlane THEN
      BEGIN
         IF YZPlane THEN
         BEGIN
            {For seeing all three projections:}
            DefineViewPort(1, 0.07, 0.7, 0.75, 0.99); {x-y plane}
            DefineViewPort(2, 0.07, 0.7, 0.12, 0.67); {x-z plane}
            DefineViewPort(3, 0.77, 0.95, 0.12, 0.67); {y-z plane}
         END
         ELSE
         BEGIN
            DefineViewPort(1, 0.07, 0.95, 0.74, 0.98);
            DefineViewPort(2, 0.07, 0.95, 0.15, 0.65);
            {See XY and XZ planes; Viewports 1, 2}
         END;
      END
      ELSE
      BEGIN
         IF YZPlane THEN
         BEGIN
            DefineViewPort(1, 0.05, 0.95, 0.74, 0.98);
            DefineViewPort(3, 0.4, 0.6, 0.13, 0.65);
            {See XY and YZ planes; Viewport 1, 3}
         END
         ELSE DefineViewPort(1, 0.05, 0.95, 0.2, 0.8);
              {See only XY plane; Viewport 1}
      END;
   END
   ELSE
   BEGIN
      IF ZXPlane THEN
      BEGIN
         IF YZPlane THEN
         BEGIN
            DefineViewPort(2, 0.05, 0.7, 0.1, 0.9);
            DefineViewPort(3, 0.75, 0.95, 0.1, 0.9);
            {See  XZ and YZ planes; Viewports 2, 3}
         END
         ELSE DefineViewPort(2, 0.05, 0.95, 0.15, 0.95);
              {See only XZ plane; Viewport 2}
      END
      ELSE DefineViewPort(3, 0.3, 0.7, 0.15, 0.95);
           {See only YZ plane; Viewport 3}
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION InputData : Boolean;
VAR
   SpinData : TInputScreen;
BEGIN
   WITH SpinData DO
   BEGIN
      Init;
      DefineInputPort(0.17, 0.83, 0.06, 0.94);
      LoadLine('');
      LoadLine('     Data for the initial conditions');
      LoadLine('');
      LoadLine('   The x-axis points toward the green.');
      LoadLine('   The y-axis points toward the left.');
      LoadLine('   The z-axis points vertically upward.');
      LoadLine('');
      LoadLine('   Using radians per second, enter the');
      LoadLine(' three spin components:');
      LoadLine('    wx = {      }, wy = {      }, wz = {      }');
      LoadLine('');
      LoadLine('   The initial direction will be toward the green.');
      LoadLine(' Enter the initial speed');
      LoadLine('                    v = {      } ft/sec');
      LoadLine(' and the angle the initial velocity makes with the');
      LoadLine(' horizontal:      0 <=  {      } <= 45 degrees');
      LoadLine('');
      LoadLine('          [  OK  ]         [Cancel]');
      SetNumber(1, XSpin);
      SetNumber(2, YSpin);
      SetNumber(3, ZSpin);
      SetNumber(4, VStart);
      SetNumberLimits(4, 0, 100000);
      SetNumber(5, ThetaStart);
      SetNumberLimits(5, 0, 45);
      AcceptScreen;
      InputData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         XSpin := GetNumber(1);
         YSpin := GetNumber(2);
         ZSpin := GetNumber(3);
         VStart := GetNumber(4);
         ThetaStart := GetNumber(5);
         y[2] := VStart*Cos(ThetaStart*Pi/180);
         y[4] := 0;
         y[6] := VStart*Sin(ThetaStart*Pi/180);
      END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScales;
VAR
   NextTime      : Real;
   FlightTime    : Real;
   DelTime       : Real;
   WaitMessage   : TWaitMessage;
BEGIN
   MinX := 0;
   MaxX := 0;
   MinY := - 0.1;
   MaxY := 0.1;
   MinZ := 0;
   MaxZ := 0;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   WaitMessage.Show;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
   UNTIL y[5] < 0;
   FlightTime := Time;
   DelTime := FlightTime/100;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   StepNumber := 0;
   xB[0] := y[1];
   yB[0] := y[3];
   zB[0] := y[5];
   REPEAT
      StepNumber := StepNumber + 1;
      WaitMessage.Update;
      NextTime := Time + DelTime;
      REPEAT
         StepSize := NextTime - Time;
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Abs(Time - NextTime) < 0.00001;
      xB[StepNumber] := y[1];
      yB[StepNumber] := y[3];
      IF y[5] < 0 THEN zB[StepNumber] := 0 ELSE zB[StepNumber] := y[5];
      IF y[3] > MaxY THEN MaxY := y[3];
      IF y[3] < MinY THEN MinY := y[3];
      IF y[5] > MaxZ THEN MaxZ := y[5];
      IF y[1] > MaxX THEN MaxX := y[1];
   UNTIL (y[5] <= 0);
   WaitMessage.Hide;
   DefineScale(1, -0.05*MaxX, 1.05*MaxX, 1.2*MinY, 1.2*MaxY);
   DefineScale(2, -0.05*MaxX, 1.05*MaxX, -0.05*MaxZ, 1.1*MaxZ);
   DefineScale(3, 1.2*MinY, 1.2*MaxY, -0.05*MaxZ, 1.1*MaxZ);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpGraphicsWindows;
VAR
   YScale   : Real;
BEGIN
   ClearMuppetPort;
   IF MaxY > - MinY THEN YScale := MaxY ELSE YScale := - MinY;
   IF YScale > 1 THEN YScale := 1
   ELSE IF YScale > 0.2 THEN YScale := 0.2 ELSE YScale := 0.1;
   IF XYPlane THEN
   BEGIN
      OpenViewPort(1);
      SelectScale(1);
      DrawAxis(0, 0, 10, YScale, White);
      PutLabel(Bottom, 'x');
      {PutLabel(Left, 'y');}
      OutTextXY(MapX(0.02*MaxX), MapY(0.95*MaxY), 'y');
   END;
   IF ZXPlane THEN
   BEGIN
      OpenViewPort(2);
      SelectScale(2);
      DrawAxis(0, 0, 10, 1, White);
      PutLabel(Bottom, 'x');
     { PutLabel(left, 'z');}
      OutTextXY(MapX(0.02*MaxX), MapY(1.0*MaxZ), 'z');
      {OUtTextXY(MapX(62), MapY(-0.2), 'x');}
   END;
   IF YZPlane THEN
   BEGIN
      OpenViewPort(3);
      SelectScale(3);
      DrawAxis(0, 0, 10*YScale, 1, White);
      PutLabel(Bottom, 'y');
      {OutTextXY(MapX(MaxY), MapY(-0.1), 'y');}
      IF MaxY > - MinY THEN
         OutTextXY(MapX(-0.1*MaxX), MapY(1.0*MaxZ), 'z')
                       ELSE
         OutTextXY(MapX(0.1*MaxX), MapY(1.0*MaxZ), 'z');
   END;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpAnimation;
VAR
   YScale    : Real;
BEGIN
   ClearMuppetPort;
   IF MaxY > - MinY THEN YScale := MaxY ELSE YScale := - MinY;
   IF YScale > 1 THEN YScale := 1
   ELSE IF YScale > 0.2 THEN YScale := 0.2 ELSE YScale := 0.1;
   IF XYPlane THEN
   BEGIN
      OpenViewPort(1);
      SelectScale(1);
      DrawAxis(0, 0, 10, YScale, White);
      PutLabel(Bottom, 'x');
   END;
   IF ZXPlane THEN
   BEGIN
      OpenViewPort(2);
      SelectScale(2);
      DrawAxis(0, 0, 10, 1, White);
      PutLabel(Bottom, 'x');
      OutTextXY(MapX(0.02*MaxX), MapY(1.0*MaxZ), 'z');
   END;
   IF YZPlane THEN
   BEGIN
      OpenViewPort(3);
      SelectScale(3);
      DrawAxis(0, 0, 10*YScale, 1, White);
      PutLabel(Bottom, 'y');
      IF MaxY > - MinY THEN
         OutTextXY(MapX(0.1*MaxY), MapY(1.0*MaxZ), 'z')
                       ELSE
         OutTextXY(MapX(-0.1*MinY), MapY(1.0*MaxZ), 'z');
   END;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   Action := True;
   Pause := True;
   FirstDrive := True;
   LightMenu := False;
   HotKeys.Key[1] := 'F2-Drive';
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotBall(xb, yb, zb : Real; BColor : Word);
VAR
   Radius      : Integer;
   SaveColor   : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(BColor);
   Radius := 5;
   SetFillStyle(SolidFill, BColor);
   FillEllipse(MapX(yb), MapY(zb), Radius, Trunc(Radius));
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveBall;
VAR
   SaveY        : Vector;
   i            : Integer;
   J, JStart    : Integer;
BEGIN
   FOR i := 1 TO 6 DO SaveY[i] := Y[i];
   FOR I := 1 TO StepNumber DO
   BEGIN
      Delay(Lag);
      SetColor(White);
      IF XYPlane THEN
      BEGIN
         SelectViewPort(1);
         SelectScale(1);
         PlotLine(xB[I - 1], yB[I - 1],
                  xB[I], yB[I]);
      END;
      IF ZXPlane THEN
      BEGIN
         SelectViewPort(2);
         SelectScale(2);
         PlotLine(xB[I - 1], zB[I - 1],
                  xB[I], zB[I]);
      END;
      IF YZPlane THEN
      BEGIN
         SelectViewPort(3);
         SelectScale(3);
         PlotBall(xB[I-1], yB[I-1], zB[I-1],
                  GraphBackColor);
         PlotBall(xB[I], yB[I], zB[I], White);
        { PlotLine(yB[I - 1], zB[I - 1],
                  yB[I], zB[I]);}
         IF I-6 > 0 THEN Jstart := I-6 ELSE JStart := 0;
         FOR J := JStart TO I-1 DO PlotLine (yB[J], zB[J],
                  yB[J+1], zB[J+1]);
      END;
   END;
   PrintXY(0.75, 0.85, 'Range:');
   PrintXY(0.75, 0.82, 'x = '+NumStr(xB[StepNumber], 4, 1)+' ft');
   PrintXY(0.75, 0.79, 'y = '+NumStr(yB[StepNumber], 4, 1)+' ft');
   Action := False;
   Pause := True;
   Driven := False;
   HotKeys.Key[1] := 'F2-Drive';
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE Demonstration;
VAR
   SXSpin, SYSpin, SZSpin      : Real;
   SCD, SCL                    : Real;

{-------------------------------------------------------------------------}

FUNCTION DemoInputData : Boolean;
VAR
   SpinData : TInputScreen;
BEGIN
   WITH SpinData DO
   BEGIN
      Init;
      DefineInputPort(0.17, 0.83, 0.06, 0.94);
      LoadLine('');
      LoadLine('        Data for the initial conditions');
      LoadLine('');
      LoadLine('   In this demonstration we follow motion');
      LoadLine(' in the x-z plane, where the z-axis points');
      LoadLine(' vertically upward. The x-axis points toward');
      LoadLine(' the green. Only wy, the y-component of spin,');
      LoadLine(' is considered.');
      LoadLine('');
      LoadLine('   Enter a value for this spin:');
      LoadLine('                  wy = {      } rad/sec');
      LoadLine('');
      LoadLine('   Enter the initial speed:');
      LoadLine('                   v = {      } ft/sec');
      LoadLine(' and the angle the initial velocity makes with the');
      LoadLine(' the horizontal: 0 <=  {      } <= 45 degrees');
      LoadLine('');
      LoadLine('            [  OK  ]         [Cancel]');
      SetNumber(1, YSpin);
      SetNumber(2, VStart);
      SetNumberLimits(2, 0, 100000);
      SetNumber(3, ThetaStart);
      SetNumberLimits(3, 0, 45);
      AcceptScreen;
      DemoInputData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         YSpin := GetNumber(1);
         VStart := GetNumber(2);
         ThetaStart := GetNumber(3);
         y[2] := VStart*Cos(ThetaStart*Pi/180);
         y[4] := 0;
         y[6] := VStart*Sin(ThetaStart*Pi/180);
      END;
      Done;
   END;
END;



PROCEDURE FindDemoScale;
VAR
   WaitMessage                 : TWaitMessage;
BEGIN
   MinX := 0;
   MaxX := 0;
   MinZ := 0;
   MaxZ := 0;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   WaitMessage.Show;
   CD := 0;
   CL := 0;
   REPEAT
      WaitMessage.Update;
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF y[5] > MaxZ THEN MaxZ := y[5];
      IF y[1] > MaxX THEN MaxX := y[1];
   UNTIL y[5] < 0;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   StepNumber := 0;
   CD := SCD;
   REPEAT
      WaitMessage.Update;
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF y[5] > MaxZ THEN MaxZ := y[5];
      IF y[1] > MaxX THEN MaxX := y[1];
   UNTIL (y[5] <= 0);
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   StepNumber := 0;
   CD := SCD;
   CL := SCL;
   REPEAT
      WaitMessage.Update;
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF y[5] > MaxZ THEN MaxZ := y[5];
      IF y[1] > MaxX THEN MaxX := y[1];
   UNTIL (y[5] <= 0);
   WaitMessage.Hide;
   DefineScale(2, -0.05*MaxX, 1.05*MaxX, -0.05*MaxZ, 1.1*MaxZ);
END;

PROCEDURE SetUpDemoScreen;
BEGIN
   DefineViewPort(2, 0.25, 0.95, 0.15, 0.85);
   ClearMuppetPort;
   OpenViewPort(2);
   SelectScale(2);
   Axis(0, 0, 10, 10);
END;

PROCEDURE RunDemo;
VAR
   xOld, yOld       : Real;
BEGIN
   MinX := 0;
   MaxX := 0;
   MinZ := 0;
   MaxZ := 0;
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   CD := 0;
   CL := 0;
   SetColor(Yellow);
   REPEAT
      xOld := y[1];
      yOld := y[5];
      IF StepSize > 0.1 THEN StepSize := 0.1;
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF y[5] < 0 THEN
      BEGIN
         y[1] := xOld + (yOld/(Yold - y[5]))*(y[1] - xOld);
         y[5] := -0.001;
      END;
      PlotLine(xOld, yOld, y[1], y[5]);
   UNTIL y[5] < 0;
   PrintXY(0.0, 0.8, 'No drag or lift');
   PrintXY(0.0, 0.75, 'Range = '+ NumStr(y[1], 4, 1)+' ft');
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   CD := SCD;
   SetColor(LightBlue);
   REPEAT
      xOld := y[1];
      yOld := y[5];
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF y[5] < 0 THEN
      BEGIN
         y[1] := xOld + (yOld/(Yold - y[5]))*(y[1] - xOld);
         y[5] := -0.001;
      END;
      PlotLine(xOld, yOld, y[1], y[5]);
   UNTIL y[5] < 0;
   PrintXY(0.0, 0.6, 'Drag but no lift');
   PrintXY(0.0, 0.55, 'Range = '+ NumStr(y[1], 4, 1)+' ft');
   y[1] := 0;
   y[3] := 0;
   y[5] := 0;
   y[2] := VStart*Cos(ThetaStart*Pi/180);
   y[4] := 0;
   y[6] := VStart*Sin(ThetaStart*Pi/180);
   Time := 0;
   StepSize := 0.1;
   StepNumber := 0;
   CD := SCD;
   CL := SCL;
   SetColor(White);
   REPEAT
      xOld := y[1];
      yOld := y[5];
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF y[5] < 0 THEN
      BEGIN
         y[1] := xOld + (yOld/(Yold - y[5]))*(y[1] - xOld);
         y[5] := -0.001;
      END;
      PlotLine(xOld, yOld, y[1], y[5]);
   UNTIL y[5] < 0;
   PrintXY(0.0, 0.4, 'Drag and lift');
   PrintXY(0.0, 0.35, 'Range = '+ NumStr(y[1], 4, 1)+' ft');
END;

BEGIN
   SXSpin := XSpin;
   SYSpin := YSpin;
   SZSpin := ZSpin;
   SCD := CD;
   SCL := CL;
   xSpin := 0;
   zSpin := 0;
   IF Input AND DemoInputData THEN FindDemoScale ELSE Exit;
   SetUpDemoScreen;
   RunDemo;
   XSpin := SXSpin;
   YSpin := SYSpin;
   ZSpin := SZSpin;
   CD := SCD;
   CL := SCL;
END;

{------------------------------------------------------------------------}

PROCEDURE GetInputData;
BEGIN
    IF InputData THEN
    BEGIN
       FindScales;
       SetUpAnimation;
    END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleBallMenu;
BEGIN
   With BallMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpSport.hlp', 'GolfAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpSport.hlp', 'GolfAboutModel');
            2: ShowHelp('HlpSport.hlp', 'GolfAboutDrag');
            3: BEGIN
                  ShowHelp('HlpSport.hlp', 'GolfAboutLiftA');
                  ShowHelp('HlpSport.hlp', 'GolfAboutLiftB');
               END;
            4: ShowHelp('HlpSport.hlp', 'GolfAboutDemonstration');
            5: BEGIN
                  ShowHelp('WalkThru.hlp', 'Golf1');
                  ShowHelp('WalkThru.hlp', 'Golf2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF Input THEN
                  BEGIN
                     SelectDisplay;
                     SetUpGraphics;
                     GetInputData;
                  END;
               END;
            2: BEGIN
                  SelectDisplay;
                  SetUpGraphics;
                  GetInputData;
               END;
            3: BEGIN
                  SetUpGraphics;
                  GetInputData;
               END;
            4: Demonstration;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag   : Integer;
BEGIN
   DelLag := 5;
   CASE Key OF
      1: BEGIN
            IF (NOT Driven) AND (NOT FirstDrive) THEN
            BEGIN
               SetUpGraphicsWindows;
               Driven := True;
               Action := True;
               Pause := False;
               WITH HotKeys DO Key[1] := 'F2-Pause';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               IF Pause = True THEN
               BEGIN
                  Pause := False;
                  WITH HotKeys DO Key[1] := 'F2-Pause';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
               END
               ELSE
               BEGIN
                  Pause := True;
                  WITH HotKeys DO Key[1] := 'F2-Run';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
               END;
            END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      3: Lag := Lag + DelLag;
      4: GetInputData;
      5: BEGIN
            Action := False;
            Pause := False;
            HotKeys.Clear;
            LightMenu := True;
            ShowCursor;
         END;
   END;
   FirstDrive := False;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   CD := 0.00231;
   CL := 0.00041;
   VStart := 200;
   ThetaStart := 10;
   XSpin := 0;
   YSpin := -300;
   ZSpin := 0;
   Gravity := 32;
   Lag := 50;
   SetUpBallMenu;
   SetUpHotKeys;
   Action := False;
   Pause := True;
   Driven := False;
   ExitRequest := False;
   LightMenu := True;
   XYPlane := True;
   YZPlane := True;
   ZXPlane := True;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Hello('HlpSport.hlp', 'GolfAboutProgram');
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Action AND (NOT Pause) THEN MoveBall;
      IF LightMenu THEN IF BallMenu.Chosen THEN HandleBallMenu;
   UNTIL ExitRequest;
   CUPSDone;
   BallMenu.Done;
END.