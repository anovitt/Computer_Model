PROGRAM Tennis;


USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 6;

TYPE
   vector = array[1..6] of real;

VAR
   TennisMenu               : TMenu;
   HotKeys                  : THotKeys;
   Key                      : Byte;
   Drag                     : Real;
   Lift                     : Real;
   XSpin, YSpin, ZSpin      : Real;
   VStart, VAStart, VBStart : Real;
   VXStart, VYStart, VZStart: Real;
   xStart, yStart, zStart   : Real;
   CD, CL                   : Real;
   Gravity                  : Real;
   Y                        : Vector;
   Time, StepSize           : Real;
   ExitRequest              : Boolean;
   LightMenu                : Boolean;
   Action                   : Boolean;
   Pause                    : Boolean;
   XYPlane, YZPlane, ZXPlane: Boolean;
   Served                   : Boolean;
   Lag                      : Integer;
   FirstServe               : Boolean;
   Swing                    : Boolean;
   Bounced                  : Boolean;
   MinX, MAxX               : Real;
   MinY, MaxY               : Real;
   MinZ, MaxZ               : Real;
   Restitution              : Real;
   Slipping                 : Real;
   xB, yB, zB               : Array[0..200] OF Real;
   xBounce, yBounce         : Real;
   StepNumber               : Integer;
   Net, Out                 : Boolean;

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

PROCEDURE SetUpTennisMenu;
VAR
   I      : Integer;
BEGIN
   With TennisMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Serving in tennis');
       row(2,3, 'About drag');
       row(2,4, 'About lift');
       row(2,5, 'About bouncing');
       row(2,6, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Bounce parameters');
       row(3,3, 'Select display');
       row(3,4, 'See Serves');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   TennisMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Serve';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F6-NewServe';
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
       LoadLine('         Data for serving in tennis');
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
       SetHelpFile('HlpSport.hlp', 'TennisDragAndLift');
       AcceptScreen;
       Input := NOT Canceled;
       IF Canceled THEN BEGIN Done; Exit; END;
       CD := GetNumber(1);
       CL := GetNumber(2);
       Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetBounceData;
VAR
   Data       : TInputScreen;
BEGIN
   WITH Data DO
   BEGIN
       Init;
       DefineInputPort(0.16, 0.84, 0.08, 0.92);
       LoadLine('');
       LoadLine('       Parameters for the bounce of a ball');
       LoadLine('');
       LoadLine('     The coefficient of restitution is a number');
       LoadLine('   between 0 and 1. 0 would correspond to no');
       LoadLine('   bounce. 1 would produce bounces all with the');
       LoadLine('   same maximum height. For a Tennis ball the');
       LoadLine('   value is 0.5.  Enter a value:');
       LoadLine('   Coefficient of restitution = {      }.');
       LoadLine('');
       LoadLine('     When a spinning ball hits a surface there');
       LoadLine('   will be some slippage relative to the surface.');
       LoadLine('   This is described by a parameter Grip which is');
       LoadLine('   zero for total slippage and 1 for no slippage.');
       LoadLIne('   Enter a value for this parameter:');
       LoadLine('                         Grip = {      }.');
       LoadLine('');
       LoadLine('         [ Help ]     [  OK  ]    [Cancel]');
       SetNumber(1, Restitution);
       SetNumberLimits(1, 0, 1);
       SetNumber(2, Slipping);
       SetNumberLimits(2, 0, 1);
       SetHelpFile('HlpSport.hlp', 'CricketBounce');
       AcceptScreen;
       IF Canceled THEN BEGIN Done; Exit; END;
       Restitution := GetNumber(1);
       Slipping := GetNumber(2);
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
         LoadLine('  The x-axis points toward the net.');
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
            DefineViewPort(1, 0.73, 0.99, 0.15, 0.85); {x-y plane}
            DefineViewPort(2, 0.07, 0.65, 0.15, 0.5); {x-z plane}
            DefineViewPort(3, 0.07, 0.65, 0.6, 0.95); {y-z plane}
         END
         ELSE
         BEGIN
            DefineViewPort(1, 0.73, 0.99, 0.15, 0.85); {x-y plane}
            DefineViewPort(2, 0.07, 0.65, 0.35, 0.65); {x-z plane}
            {See XY and XZ planes; Viewports 1, 2}
         END;
      END
      ELSE
      BEGIN
         IF YZPlane THEN
         BEGIN
            DefineViewPort(1, 0.73, 0.99, 0.15, 0.85); {x-y plane}
            DefineViewPort(3, 0.07, 0.65, 0.35, 0.65); {y-z plane}
            {See XY and YZ planes; Viewport 1, 3}
         END
         ELSE DefineViewPort(1, 0.35, 0.65, 0.15, 0.85); {x-y plane}
              {See only XY plane; Viewport 1}
      END;
   END
   ELSE
   BEGIN
      IF ZXPlane THEN
      BEGIN
         IF YZPlane THEN
         BEGIN
            DefineViewPort(2, 0.1, 0.9, 0.15, 0.5); {x-z plane}
            DefineViewPort(3, 0.1, 0.9, 0.6, 0.95); {y-z plane}
            {See  XZ and YZ planes; Viewports 2, 3}
         END
         ELSE DefineViewPort(2, 0.1, 0.9, 0.35, 0.65); {x-z plane}
              {See only XZ plane; Viewport 2}
      END
      ELSE DefineViewPort(3, 0.1, 0.9, 0.35, 0.65); {y-z plane}
           {See only YZ plane; Viewport 3}
   END;
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
      SetColor(White);
      PlotLine(Minx, Miny, Minx, Maxy);
      PlotLine(Maxx, Miny, Maxx, Maxy);
      PLotLine(Minx, Miny, Maxx, Miny);
      PlotLine(Minx, Maxy, Maxx, Maxy);
      PlotLine(MinX, MaxY-4.5, MaxX, MaxY-4.5);
      PlotLine(MinX, MinY+4.5, MaxX, MinY+4.5);
      PlotLine(MaxX-18, MinY+4.5, MaxX-18, MaxY-4.5);
      PlotLine(MinX+18, MinY+4.5, MinX+18, MaxY-4.5);
      PlotLine(-21, 0, 21, 0);
      DrawAxis(0, 0, 10, YScale, White);
      SetColor(LightGray);
      PlotLine(0, Miny*7/6, 0, Maxy*7/6);
      SetColor(White);
      PutLabel(Bottom, 'x');
      OutTextXY(MapX(0.02*MaxX), MapY(0.95*MaxY), 'y');
   END;
   IF ZXPlane THEN
   BEGIN
      OpenViewPort(2);
      SelectScale(2);
      PlotLine(MaxX, 0, MaxX, 0.5);
      PlotLine(MinX, 0, MinX, 0.5);
      PlotLine(21, 0, 21, 0.5);
      PlotLine(-21, 0, -21, 0.5);
      DrawAxis(100, 0, 10, 1, White);
      SetColor(LightGray);
      PlotLine(0, 0, 0, 3);
      SetColor(White);
      PutLabel(Bottom, 'x');
      OutTextXY(MapX(0.02*MaxX), MapY(1.0*MaxZ), 'z');
   END;
   IF YZPlane THEN
   BEGIN
      OpenViewPort(3);
      SelectScale(3);
      SetColor(LightGray);
      SetFillStyle(HatchFill, LightGray);
      PlotLine(MinY, 0, MaxY, 0);
      PlotLine(MaxY, 0, MaxY, 3);
      PlotLine(MaxY, 3, MinY, 3);
      PlotLine(MinY, 3, MinY, 0);
      FloodFill(MapX(0), MapY(1.5), LightGray);
      SetColor(White);
      PlotLine(-18, 0, -18, 0.5);
      PlotLine(-13.5, 0, -13.5, 0.5);
      PlotLine(18, 0, 18, 0.5);
      PlotLine(13.5, 0, 13.5, 0.5);
      DrawAxis(0, 0, YScale, 1, White);
      PutLabel(Bottom, 'y');
      OutTextXY(MapX(0.1*MaxY), MapY(1.0*MaxZ), 'z');
   END;
   y[1] := XStart;
   y[2] := VXStart;
   y[3] := YStart;
   y[4] := VYStart;
   y[5] := ZStart;;
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
      SetColor(White);
         SetColor(White);
   PlotLine(MaxY, MaxX, MaxY, MinX);
   PlotLine(MaxY, MinX, MinY, MinX);
   PlotLine(MinY, MinX, MinY, MaxX);
   PlotLine(MinY, MaxX, MaxY, MaxX);
   PlotLine(-13.5, -21, 13.5, -21);
   PlotLine(-13.5, 21, 13.5, 21);
   PlotLine(-13.5, 39, -13.5, -39);
   PlotLine(13.5, 39, 13.5, -39);
   PlotLine(0, -21, 0, 21);
   PlotLine(-21, 0, 21, 0);
   PlotLine(0, -39.5, 0, -38.5);
   PLotLine(0, 39.5, 0, 38.5);
   DrawAxis(0, 0, 10, 10, White);
   PutLabel(Top, 'x');
   OutTextXY(MapX(-21), MapY(-0.5), 'y');
   END;
   IF ZXPlane THEN
   BEGIN
      OpenViewPort(2);
      SelectScale(2);
      PlotLine(MaxX, 0, MaxX, 0.5);
      PlotLine(MinX, 0, MinX, 0.5);
      PlotLine(21, 0, 21, 0.5);
      PlotLine(-21, 0, -21, 0.5);
      DrawAxis(100, 0, 10, 2, White);
      SetColor(LightGray);
      PlotLine(0, 0, 0, 3);
      SetColor(White);
      PutLabel(Bottom, 'x');
      OutTextXY(MapX(0.02*MaxX), MapY(1.0*MaxZ), 'z');
   END;
   IF YZPlane THEN
   BEGIN
      OpenViewPort(3);
      SelectScale(3);
      SetColor(LightGray);
      SetFillStyle(HatchFill, LightGray);
      PlotLine(MinY-1, 0, MaxY+1, 0);
      PlotLine(MaxY+1, 0, MaxY+1, 3);
      PlotLine(MaxY+1, 3, MinY-1, 3);
      PlotLine(MinY-1, 3, MinY-1, 0);
      FloodFill(MapX(0), MapY(1.5), LightGray);
      SetColor(White);
      SetLineStyle(SolidLn, 0, ThickWidth);
      PlotLine(MaxY+1, 0, MaxY+1, 3.3);
      PlotLine(MinY-1, 3.3, MinY-1, 0);
      SetLineStyle(SolidLn, 0, NormWidth);
      DrawAxis(0, 0, 10, 2, White);
      PlotLine(-18, 0, -18, 0.5);
      PlotLine(-13.5, 0, -13.5, 0.5);
      PlotLine(18, 0, 18, 0.5);
      PlotLine(13.5, 0, 13.5, 0.5);
      PutLabel(Bottom, 'y');
      OutTextXY(MapX(-0.1*MinY), MapY(1.0*MaxZ), 'z');
   END;
   y[1] := XStart;
   y[2] := VXStart;
   y[3] := YStart;
   y[4] := VYStart;
   y[5] := ZStart;;
   y[6] := VZStart;
   Time := 0;
   StepSize := 0.1;
   Action := True;
   Pause := True;
   FirstServe := True;
   LightMenu := False;
   HotKeys.Key[1] := 'F2-Serve';
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE ShowTennisCourt;
BEGIN
   DefineViewPort(6, 0.68, 0.96, 0.15, 0.85);
   DefineScale(6, -22, 22, -45, 45);
   OpenViewPort(6);
   SelectScale(6);
   SetColor(White);
   PlotLine(MaxY, MaxX, MaxY, MinX);
   PlotLine(MaxY, MinX, MinY, MinX);
   PlotLine(MinY, MinX, MinY, MaxX);
   PlotLine(MinY, MaxX, MaxY, MaxX);
   PlotLine(-13.5, -21, 13.5, -21);
   PlotLine(-13.5, 21, 13.5, 21);
   PlotLine(-13.5, 39, -13.5, -39);
   PlotLine(13.5, 39, 13.5, -39);
   PlotLine(0, -21, 0, 21);
   PlotLine(-21, 0, 21, 0);
   PlotLine(0, -39.5, 0, -38.5);
   PLotLine(0, 39.5, 0, 38.5);
   SetColor(LightGray);
   PlotLine(0, 21, 0, 45);
   OutTextXY(MapX(0.5), MapY(44), 'x');
   PlotLine(-18, 0, -22, 0);
   OutTextXY(MapX(-21), MapY(-0.5), 'y');
   OutTextXY(MapX(-1.5), MapY(-41), '36');
   PlotLine(-18, -42, -2.5, -42);
   PlotLine(2.5, -42, 18, -42);
   OutTextXY(MapX(-1.5), MapY(-23), '27');
   PlotLine(-13.5, -24, -2.5, -24);
   PlotLine(2.5, -24, 13.5, -24);
   OutTextXY(MapX(10), MapY(11.5), '21');
   PlotLine(11, 0, 11, 8.5);
   PlotLine(11, 12.5, 11, 21);
   OutTextXY(MapX(10), MapY(31), '18');
   PlotLine(11, 21, 11, 28);
   PlotLine(11, 32, 11, 39);

END;

{-------------------------------------------------------------------------}

FUNCTION InputData : Boolean;
VAR
   SpinData : TInputScreen;
BEGIN
   Message('');
   ShowTennisCourt;
   WITH SpinData DO
   BEGIN
      Init;
      DefineInputPort(0.05, 0.63, 0.05, 0.97);
      LoadLine('');
      LoadLine('   Data for the initial conditions');
      LoadLine('');
      LoadLine('   Enter coordinates of the serve:');
      LoadLine('   x:         -39 < {      } < 0 ft');
      LoadLine('   y:         -18 < {      } < 18 ft');
      LoadLine('   z:           2 < {      } < 15 ft');
      LoadLine('');
      LoadLine('   Enter conditions for the velocity of ');
      LoadLine(' the serve:');
      LoadLine('   Speed:       0 < {      } < 250 ft/sec');
      LoadLine('   Angle with the horizontal:');
      LoadLine('              -10 < {      } < 45 degrees');
      LoadLine('   Angle with the x-axis:');
      LoadLine('              -45 < {      } < 45 degrees');
      LoadLine('');
      LoadLine('   Using radians per second, enter the ');
      LoadLine(' three spin components:');
      LoadLine('wx = {      }, wy = {      }, wz = {      }');
      LoadLine('');
      LoadLine('   [ Help ]      [  OK  ]      [Cancel]');
      SetHelpFile('HlpSport.hlp', 'TennisAboutServingB');
      SetNumber(1, XStart);
      SetNumberLimits(1, -40, 0);
      SetNumber(2, YStart);
      SetNumberLimits(2, -18, 18);
      SetNumber(3, ZStart);
      SetNumberLimits(3, 2, 15);
      SetNumber(4, VStart);
      SetNumberLimits(4, 0, 250);
      SetNumber(5, VAStart);
      SetNumberLimits(5, -10, 45);
      SetNumber(6, VBStart);
      SetNumberLimits(6, -45, 45);
      SetNumber(7, xSpin);
      SetNumber(8, ySpin);
      SetNumber(9, zSpin);
      AcceptScreen;
      InputData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         xStart := GetNumber(1);
         yStart := GetNumber(2);
         zStart := GetNumber(3);
         VStart := GetNumber(4);
         VAStart := GetNumber(5);
         VBStart := GetNumber(6);
         XSpin := GetNumber(7);
         YSpin := GetNumber(8);
         ZSpin := GetNumber(9);
         y[1] := xStart;
         y[3] := yStart;
         y[5] := zStart;
         VXStart := VStart*Cos(VAStart*Pi/180)*Cos(VBStart*Pi/180);
         VYStart := VStart*Cos(VAStart*Pi/180)*Sin(VBStart*Pi/180);
         VZStart := VStart*Sin(VAStart*Pi/180);
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
   xBounce := y[1];
   yBounce := y[3];
   Bounced := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE FindScales;
VAR
   NextTime      : Real;
BEGIN
   MaxZ := ZStart;
   y[1] := XStart;
   y[3] := YStart;
   y[5] := ZStart;
   y[2] := VXStart;
   y[4] := VYStart;
   y[6] := VZStart;
   Time := 0;
   StepNumber := 0;
   Net := False;
   Out := False;
   Bounced := False;
   xB[0] := y[1];
   yB[0] := y[3];
   zB[0] := y[5];
   REPEAT
      StepNumber := StepNumber + 1;
      NextTime := Time + 0.01;
      REPEAT
         StepSize := NextTime - Time;
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      UNTIL Abs(Time - NextTime) < 0.00001;
      xB[StepNumber] := y[1];
      yB[StepNumber] := y[3];
      IF (y[1]*xB[StepNumber-1] < 0) AND (y[5] < 3) THEN
      BEGIN
         Net := True;
         xB[StepNumber] := 0;
         zB[StepNumber] := y[5];
         StepNumber := StepNumber + 1;
         zB[StepNumber] := 0;
         xB[StepNumber] := - y[2]*Time/10;
         yB[StepNumber] := yB[StepNumber-1] + y[4]*Time/10;
      END;
      IF Abs(y[3]) > MaxY THEN Out := True;
      IF NOT Net THEN
      BEGIN
         IF y[5] < 0 THEN zB[StepNumber] := 0 ELSE zB[StepNumber] := y[5];
         IF y[5] < 0 THEN FindBounce;
         IF y[5] > MaxZ THEN MaxZ := y[5];
      END;
   UNTIL (y[1] > MaxX) OR Net OR Out;
   DefineScale(1, 1.2*MinY, 1.2*MaxY, MinX-5, MaxX+5);
   DefineScale(2, MinX-5, MaxX+5, -0.5, 1.2*MaxZ);
   DefineScale(3, 1.2*MinY, 1.2*MaxY, -0.5, 1.2*MaxZ);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotBall(xb, yb, zb : Real; BColor : Word);
VAR
   Radius      : Integer;
   SaveColor   : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(BColor);
   Radius := Trunc(300/(60 - xb + 50));
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
   FOR I := 1 TO StepNumber DO
   BEGIN
      IF Net AND (I = StepNumber) THEN Delay(400) ELSE Delay(Lag);
      SetColor(White);
      IF XYPlane THEN
      BEGIN
         SelectViewPort(1);
         SelectScale(1);
         PlotLine(yB[I - 1], xB[I - 1],
                  yB[I], xB[I]);
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
         PlotLine(yB[I - 1], zB[I - 1],
                  yB[I], zB[I]);
         IF Net AND (I = StepNumber-1) THEN PlotSymbol(yB[I], zB[I], '*');
      END;
   END;
   IF XYPlane AND Bounced THEN
   BEGIN
      SelectViewPort(1);
      SelectScale(1);
      SetColor(Yellow);
      PlotSymbol(yBounce, xBounce, '*');
   END;
   BEGIN
      Action := False;
      Pause := True;
      Served := False;
      HotKeys.Key[1] := 'F2-Serve';
      HotKeys.BackColor := Blue;
      HotKeys.HotKeyColor := Yellow;
      HotKeys.Display;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetInputData;
BEGIN
   ClearMuppetPort;
   IF InputData THEN
   BEGIN
      FindScales;
      SetUpAnimation;
   END
   ELSE
   BEGIN
      ClearMuppetPort;
      LightMenu := True;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleTennisMenu;
BEGIN
   With TennisMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpSport.hlp', 'TennisAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpSport.hlp', 'TennisAboutModel');
            2: BEGIN
                  ShowHelp('HlpSport.hlp', 'TennisAboutServingA');
                  ShowTennisCourt;
                  ShowHelp('HlpSport.hlp', 'TennisAboutServingB');
                  ClearMuppetPort;
               END;
            3: ShowHelp('HlpSport.hlp', 'TennisAboutDrag');
            4: BEGIN
                  ShowHelp('HlpSport.hlp', 'TennisAboutLiftA');
                  ShowHelp('HlpSport.hlp', 'TennisAboutLiftB');
               END;
            5: ShowHelp('HlpSport.hlp', 'CricketBounce');
            6: BEGIN
                  ShowHelp('WalkThru.hlp', 'Tennis1');
                  ShowHelp('WalkThru.hlp', 'Tennis2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF Input THEN
                  BEGIN
                     GetBounceData;
                     SelectDisplay;
                     SetUpGraphics;
                     GetInputData;
                  END;
               END;
            2: GetBounceData;
            3: BEGIN
                  SelectDisplay;
                  SetUpGraphics;
                  GetInputData;
               END;
            4: BEGIN
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
            IF (NOT Served) AND (NOT FirstServe) THEN
            BEGIN
               {SetUpGraphicsWindows;}
               Served := True;
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
   FirstServe := False;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   CD := 0.00412;
   CL := 0.0011;
   XStart := -39;
   YStart := 8;
   ZStart := 8;
   VStart := 100;
   VAStart := -1;
   VBStart := -10;
   XSpin := 0;
   YSpin := 0;
   ZSpin := 0;
   Gravity := 32;
   Slipping := 1;
   Restitution := 0.5;
   Lag := 50;
   MinX := -39;
   MaxX := 39;
   MinY := -18;
   MaxY := 18;
   MinZ := 0;
   SetUpTennisMenu;
   SetUpHotKeys;
   Action := False;
   Pause := True;
   Served := False;
   ExitRequest := False;
   LightMenu := True;
   XYPlane := True;
   YZPlane := True;
   ZXPlane := True;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Hello('HlpSport.hlp', 'TennisAboutProgram');
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Action AND (NOT Pause) THEN MoveBall;
      IF LightMenu THEN IF TennisMenu.Chosen THEN HandleTennisMenu;
   UNTIL ExitRequest;
   CUPSDone;
   TennisMenu.Done;
END.