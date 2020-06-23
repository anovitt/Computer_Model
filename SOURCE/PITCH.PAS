PROGRAM BaseBallPitch;


USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 6;

TYPE
   vector = array[1..6] of real;

VAR
   BallMenu                 : TMenu;
   Sliders                  : TSliders;
   HotKeys                  : THotKeys;
   Key                      : Byte;
   Drag                     : Real;
   Lift                     : Real;
   XSpin, YSpin, ZSpin      : Real;
   VXStart, VYStart, VZStart: Real;
   PitchHeight              : Real;
   CD, CL                   : Real;
   Gravity                  : Real;
   Spin, Phase              : Real;
   Y                        : Vector;
   Time, StepSize           : Real;
   ExitRequest              : Boolean;
   LightMenu                : Boolean;
   Action                   : Boolean;
   Pause                    : Boolean;
   XYPlane, YZPlane, ZXPlane: Boolean;
   Pitched                  : Boolean;
   Lag                      : Integer;
   FirstPitch               : Boolean;
   KnuckleBall              : Boolean;
   ShowBall                 : Boolean;
   MinX, MAxX               : Real;
   MinY, MaxY               : Real;
   MinZ, MaxZ               : Real;
   Restitution              : Real;
   Slipping                 : Real;

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
       row(2,4, 'Knuckle-balls');
       row(2,5, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Select display');
       row(3,3, 'See pitches');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   BallMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Pitch';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-HideBall';
      Key[5] := 'F6-NewPitch';
      Key[6] := 'F10-Menu';
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
       DefineInputPort(0.2, 0.8, 0.2, 0.8);
       LoadLine('');
       LoadLine('       Data for a pitch in baseball');
       LoadLine('');
       LoadLine('   Enter a number for the drag coefficient:');
       LoadLine('        0 <= CD = {        } <= 1');
       LoadLine('');
       LoadLine('   Enter a number for the lift coefficient:');
       LoadLine('        0 <= CL = {        } <= 1');
       LoadLine('');
       LoadLine('    Regular pitch: #1  Knuckle ball: #1 ');
       LoadLine('');
       LoadLine('       [ Help ]    [  OK  ]    [Cancel]');
       SetNumber(1, CD);
       SetNumberLimits(1, 0, 1);
       SetNumber(2, CL);
       SetNumberLimits(2, 0, 1);
       IF KnuckleBall THEN SetRadioButton('1', 2) ELSE SetRadioButton('1', 1);
       SetHelpFile('HlpSport.hlp', 'PitchDragandLift');
       AcceptScreen;
       Input := NOT Canceled;
       IF Canceled THEN BEGIN Done; Exit; END;
       CD := GetNumber(1);
       CL := GetNumber(2);
       IF GetRadioButton('1') = 1 THEN KnuckleBall := False
                                  ELSE KnuckleBall := True;
       Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x : Real; y : Vector; VAR z : Vector);
VAR
   Speed     : Real;
BEGIN
   Speed := Sqrt(y[2]*y[2] + y[4]*y[4] + y[6]*y[6]);
   IF KnuckleBall THEN
   BEGIN
      z[1] := y[2];
      z[2] := - CD*Speed*y[2];
      z[3] := y[4];
      z[4] := - CD*Speed*y[4] + (0.0000216*32/0.319)*
                Speed*Speed*Sin(4*Spin*Time + Phase);
      z[5] := y[6];
      z[6] := - CD*Speed*y[6] - Gravity;
   END
   ELSE
   BEGIN
      z[1] := y[2];
      z[2] := - CD*Speed*y[2] + CL*(YSpin*y[6] - ZSpin*y[4]);
      z[3] := y[4];
      z[4] := - CD*Speed*y[4] + CL*(ZSpin*y[2] - XSpin*y[6]);
      z[5] := y[6];
      z[6] := - CD*Speed*y[6] + CL*(XSpin*y[4] - YSpin*y[2]) - Gravity;
   END;
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
         LoadLine('      Options for animation display');
         LoadLine('');
         LoadLine('  The x-axis points toward home plate.');
         LoadLine('  The y-axis points toward first base.');
         LoadLine('  The z-axis points vertically upward.');
         LoadLine('');
         LoadLine('  You can view the animation projected');
         LoadLine('  into any of the coordinate planes.');
         LoadLine('');
         LoadLine('        x-y plane: #1 Yes  #1 No');
         LoadLine('        y-z plane: #2 Yes  #2 No');
         LoadLine('        z-x plane: #3 Yes  #3 No');
         LoadLine('');
         LoadLine('                [  OK  ]     ');
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
            DefineViewPort(1, 0.05, 0.7, 0.7, 0.94); {x-y plane}
            DefineViewPort(2, 0.05, 0.7, 0.1, 0.65); {x-z plane}
            DefineViewPort(3, 0.75, 0.95, 0.1, 0.65); {y-z plane}
         END
         ELSE
         BEGIN
            DefineViewPort(1, 0.05, 0.95, 0.7, 0.94);
            DefineViewPort(2, 0.05, 0.95, 0.1, 0.65);
            {See XY and XZ planes; Viewports 1, 2}
         END;
      END
      ELSE
      BEGIN
         IF YZPlane THEN
         BEGIN
            DefineViewPort(1, 0.05, 0.95, 0.7, 0.94);
            DefineViewPort(3, 0.4, 0.6, 0.1, 0.65);
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
         ELSE DefineViewPort(2, 0.05, 0.95, 0.1, 0.9);
              {See only XZ plane; Viewport 2}
      END
      ELSE DefineViewPort(3, 0.3, 0.7, 0.1, 0.9);
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
      DefineInputPort(0.20, 0.8, 0.06, 0.94);
      LoadLine('');
      LoadLine('     Data for the initial conditions');
      LoadLine('');
      LoadLine('   The x-axis points toward home plate.');
      LoadLine('   The y-axis points toward first base.');
      LoadLine('   The z-axis points vertically upward.');
      LoadLine('');
      LoadLine('   Using radians per second, enter the');
      LoadLine(' three spin components:');
      LoadLine(' wx = {      }, wy = {      }, wz = {      }');
      LoadLine('');
      LoadLine('   Using feet per second, enter the');
      LoadLine(' three velocity components: (vx > 0)');
      LoadLine(' vx = {      }, vy = {      }, vz = {      }');
      LoadLine('');
      LoadLine('   Enter the height of the pitch, in feet:');
      LoadLine('            3 <= z = {      } <= 10');
      LoadLine('');
      LoadLine('          [  OK  ]         [Cancel]');
      SetNumber(1, XSpin);
      SetNumber(2, YSpin);
      SetNumber(3, ZSpin);
      SetNumber(4, VXStart);
      SetNumberLimits(4, 0, 100000);
      SetNumber(5, VYStart);
      SetNumber(6, VZStart);
      SetNumber(7, PitchHeight);
      SetNumberLimits(7, 3, 10);
      AcceptScreen;
      InputData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         XSpin := GetNumber(1);
         YSpin := GetNumber(2);
         ZSpin := GetNumber(3);
         VXStart := GetNumber(4);
         VYStart := GetNumber(5);
         VZStart := GetNumber(6);
         PitchHeight := GetNumber(7);
         y[2] := VXStart;
         y[4] := VYStart;
         y[6] := VZStart;
      END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

FUNCTION KnuckleData : Boolean;
VAR
   SpinData : TInputScreen;
BEGIN
   WITH SpinData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.05, 0.95);
      LoadLine('');
      LoadLine('       Data for the initial conditions');
      LoadLine('');
      LoadLine('   The x-axis points toward home plate.');
      LoadLine('   The y-axis points toward first base.');
      LoadLine('   The z-axis points vertically upward.');
      LoadLine('');
      LoadLine('   Enter the spin rate of the knuckleball');
      LoadLine(' in radian/sec:');
      LoadLine('                -10 <= {      } <= 10');
      LoadLine(' Enter the initial deflection in radians:');
      LoadLine('               -1.5 <= {      } <= 1.5 rad ');
      LoadLine('');
      LoadLine('    Using feet per second, enter the ');
      LoadLine('  three velocity components: (vx > 0)');
      LoadLine(' vx = {      }, vy = {      }, vz = {      }');
      LoadLine('');
      LoadLine('   Enter the height of the pitch, in feet:');
      LoadLine('              3 <= z = {      } <= 10');
      LoadLine('');
      LoadLine('       [ Help ]     [  OK  ]     [Cancel]');
      SetNumber(1, Spin);
      SetNumberLimits(1, -10, 10);
      SetNumber(2, Phase);
      SetNumberLimits(2, -1.5, 1.5);
      SetNumber(3, VXStart);
      SetNumberLimits(3, 0, 100000);
      SetNumber(4, VYStart);
      SetNumber(5, VZStart);
      SetNumber(6, PitchHeight);
      SetNumberLimits(6, 3, 10);
      SetHelpFile('HlpSport.hlp', 'PitchKnuckleBall');
      AcceptScreen;
      KnuckleData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Spin := GetNumber(1);
         Phase := GetNumber(2);
         VXStart := GetNumber(3);
         VYStart := GetNumber(4);
         VZStart := GetNumber(5);
         PitchHeight := GetNumber(6);
         y[2] := VXStart;
         y[4] := VYStart;
         y[6] := VZStart;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE FindBounce;
VAR
   TempStepSize    : Real;
   Eps             : Real;
BEGIN
   Eps := 0.000000001;
   REPEAT
      TempStepSize := - y[5]/y[6];
      Step(Time, TempStepSize, 0.000000001, y, Time, TempStepSize, y);
   UNTIL Abs(y[5]) < Eps;
   y[2] := y[2] + Slipping*0.116*YSpin;
   y[4] := y[4] - Slipping*0.116*XSpin;
   y[6] := - Restitution*y[6];
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScales;
BEGIN
   MinX := 0;
   MaxX := 60;
   MinY := - 0.1;
   MaxY := 0.1;
   MinZ := 0;
   MaxZ := 6;
   y[1] := 0;
   y[3] := 0;
   y[5] := PitchHeight;
   y[2] := VXStart;
   y[4] := VYStart;
   y[6] := VZStart;
   Time := 0;
   StepSize := 0.1;
   REPEAT
      Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
      {IF y[5] < 0 THEN FindBounce;}
      IF y[3] > MaxY THEN MaxY := y[3];
      IF y[3] < MinY THEN MinY := y[3];
      IF y[5] > MaxZ THEN MaxZ := y[5];
   UNTIL (y[1] > 60) OR (y[5] < 0);
   DefineScale(1, -5, 65, 1.2*MinY, 1.2*MaxY);
   DefineScale(2, -5, 65, -0.5, 1.2*MaxZ);
   DefineScale(3, 1.2*MinY, 1.2*MaxY, -0.5, 1.2*MaxZ);
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
      OutTextXY(MapX(-2), MapY(MaxY), 'y');
      IF MaxY > - MinY THEN
         OutTextXY(MapX(62), MapY(0)-7, 'x')
                       ELSE
         OutTextXY(MapX(62), MapY(0)+7, 'x');
   END;
   IF ZXPlane THEN
   BEGIN
      OpenViewPort(2);
      SelectScale(2);
      DrawAxis(0, 0, 10, 1, White);
      OutTextXY(MapX(-2), MapY(1.1*MaxZ), 'z');
      OUtTextXY(MapX(62), MapY(-0.2), 'x');
   END;
   IF YZPlane THEN
   BEGIN
      OpenViewPort(3);
      SelectScale(3);
      DrawAxis(0, 0, YScale, 1, White);
      OutTextXY(MapX(MaxY), MapY(-0.1), 'y');
      IF MaxY > - MinY THEN
         OutTextXY(MapX(0)-7, MapY(1.1*MaxZ), 'z')
                       ELSE
         OutTextXY(MapX(0)+7, MapY(1.1*MaxZ), 'z');
   END;
   y[1] := 0;
   y[2] := VXStart;
   y[3] := 0;
   y[4] := VYStart;
   y[5] := PitchHeight;
   y[6] := VZStart;
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
      OutTextXY(MapX(-2), MapY(MaxY), 'y');
      IF MaxY > - MinY THEN
         OutTextXY(MapX(62), MapY(0)-7, 'x')
                       ELSE
         OutTextXY(MapX(62), MapY(0)+7, 'x');
   END;
   IF ZXPlane THEN
   BEGIN
      OpenViewPort(2);
      SelectScale(2);
      DrawAxis(0, 0, 10, 1, White);
      OutTextXY(MapX(-2), MapY(1.1*MaxZ), 'z');
      OUtTextXY(MapX(62), MapY(-0.2), 'x');
   END;
   IF YZPlane THEN
   BEGIN
      OpenViewPort(3);
      SelectScale(3);
      DrawAxis(0, 0, YScale, 1, White);
      OutTextXY(MapX(MaxY), MapY(-0.1), 'y');
      IF MaxY > - MinY THEN
         OutTextXY(MapX(0)-7, MapY(1.1*MaxZ), 'z')
                       ELSE
         OutTextXY(MapX(0)+7, MapY(1.1*MaxZ), 'z');
   END;
   y[1] := 0;
   y[2] := VXStart;
   y[3] := 0;
   y[4] := VYStart;
   y[5] := PitchHeight;
   y[6] := VZStart;
   Time := 0;
   StepSize := 0.1;
   Action := True;
   Pause := True;
   FirstPitch := True;
   LightMenu := False;
   HotKeys.Key[1] := 'F2-Pitch';
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
   Radius := Trunc(300/(60 - xb + 20));
   SetFillStyle(SolidFill, BColor);
   FillEllipse(MapX(yb), MapY(zb), Radius, Trunc(Radius));
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveBall;
VAR
   SaveY    : Vector;
   i        : Integer;
BEGIN
   FOR i := 1 TO 6 DO SaveY[i] := Y[i];
   Delay(Lag);
   Step(Time, StepSize, 0.000000001, y, Time, StepSize, y);
   {IF y[5] < 0 THEN FindBounce; }
   IF XYPlane THEN
   BEGIN
      SelectViewPort(1);
      SelectScale(1);
      PlotLine(SaveY[1], SaveY[3], y[1], y[3]);
   END;
   IF ZXPlane THEN
   BEGIN
      SelectViewPort(2);
      SelectScale(2);
      PlotLine(SaveY[1], SaveY[5], y[1], y[5]);
   END;
   IF YZPlane THEN
   BEGIN
      SelectViewPort(3);
      SelectScale(3);
      IF ShowBall THEN
      BEGIN
         PlotBall(SaveY[1], SaveY[3], SaveY[5], GraphBackColor);
         PlotBall(y[1], y[3], y[5], White);
      END;
      PlotLine(SaveY[3], SaveY[5], y[3], y[5]);
   END;
   IF (y[1] > 60) OR (y[5] < 0) THEN
   BEGIN
      Action := False;
      Pause := True;
      Pitched := False;
      HotKeys.Key[1] := 'F2-Pitch';
      HotKeys.BackColor := Blue;
      HotKeys.HotKeyColor := Yellow;
      HotKeys.Display;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetInputData;
BEGIN
   IF NOT KnuckleBall THEN
   BEGIN
       IF InputData THEN
       BEGIN
          FindScales;
          SetUpAnimation;
       END;
    END
    ELSE
    BEGIN
    IF KnuckleData THEN
       BEGIN
          FindScales;
          SetUpAnimation;
       END;
    END
END;

{------------------------------------------------------------------------}

PROCEDURE HandleBallMenu;
BEGIN
   With BallMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpSport.hlp', 'PitchAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpSport.hlp', 'PitchAboutModel');
            2: ShowHelp('HlpSport.hlp', 'PitchAboutDrag');
            3: ShowHelp('HlpSport.hlp', 'PitchAboutLift');
            4: ShowHelp('HlpSport.hlp', 'PitchKnuckleBall');
            5: BEGIN
                  ShowHelp('WalkThru.hlp', 'BaseBall1');
                  ShowHelp('WalkThru.hlp', 'BaseBall2');
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
            IF (NOT Pitched) AND (NOT FirstPitch) THEN
            BEGIN
               SetUpGraphicsWindows;
               Pitched := True;
               Action := True;
               Pause := False;
               WITH HotKeys DO Key[1] := 'F2-Pause';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               FirstPitch := False;
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
      4: BEGIN
            IF ShowBall THEN
            BEGIN
               ShowBall := False;
               WITH HotKeys DO Key[4] := 'F5-ShowBall';
               HotKeys.Display;
            END
            ELSE
            BEGIN
               ShowBall := True;
               WITH HotKeys DO Key[4] := 'F5-HideBall';
               HotKeys.Display;
            END;
         END;
      5: BEGIN
            FirstPitch := True;
            GetInputData;
         END;
      6: BEGIN
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
   CD := 0.0025;
   CL := 0.0007;
   PitchHeight := 6;
   VXStart := 120;
   VYStart := 0;
   VZStart := 0;
   XSpin := 0;
   YSpin := 0;
   ZSpin := 0;
   Gravity := 32;
   Slipping := 1;
   Restitution := 0.5;
   Lag := 100;
   SetUpBallMenu;
   SetUpHotKeys;
   Action := False;
   Pause := True;
   Pitched := False;
   ExitRequest := False;
   LightMenu := True;
   XYPlane := True;
   YZPlane := True;
   ZXPlane := True;
   Spin := 4;
   Phase := 1;
   KnuckleBall := False;
   ShowBall := True;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Hello('HlpSport.hlp', 'PitchAboutProgram');
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