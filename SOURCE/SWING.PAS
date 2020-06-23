Program ChildOnASwing;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;

const
   neq = 2;

type
   vector = array[1..neq] of real;

VAR
   SwingMenu                  : TMenu;
   HotKeys, AutoHotKeys       : THotKeys;
   PhaseHotKeys               : THotKeys;
   y                          : vector;
   Length, Height, Weight     : Real;
   Resist                     : Real;
   Time, StepSize             : Real;
   Lag                        : Integer;
   Action, Pause, PauseChange : Boolean;
   Standing                   : Boolean;
   Automatic                  : Boolean;
   PhasePlot                  : Boolean;
   ExitRequest                : Boolean;
   LightMenu                  : Boolean;
   Key                        : Byte;
   Theta, ThetaPrime          : Real;
   Frame                      : Integer;
   xOld1, yOld1, xNew1, yNew1 : Real;
   xOld2, yOld2, xNew2, yNew2 : Real;
   xPlot, yPlot               : Array[1..10] OF Real;
   CosAngle, SinAngle         : Real;
   F                          : Real;
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

{---------------------------------------------------------------------------}

PROCEDURE SetUpSwingMenu;
VAR
   I      : Integer;
BEGIN
   With SwingMenu DO
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
       row(3,1, 'Parameters');
       row(3,2, 'Initial conditions');
       row(3,3, 'Swing!');
       row(3,4, 'See phase-plane');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   SwingMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Pause';
      Key[2] := 'F3-Up';
      Key[3] := 'F4-Faster';
      Key[4] := 'F5-Slower';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpAutoHotKeys;
BEGIN
   WITH AutoHotKeys DO
   BEGIN
      AutoHotKeys.Init(4);
      Key[1] := 'F2-Pause';
      Key[2] := 'F4-Faster';
      Key[3] := 'F5-Slower';
      Key[4] := 'F10-Menu';
   END;
   AutoHotKeys.BackColor := Blue;
   AutoHotKeys.HotKeyColor := Yellow;
   AutoHotKeys.Display;
END;

{-------------------------------------------------------------------------}

FUNCTION GetSwingData : Boolean;
CONST
   RBNames: String = '12345';
VAR
   PendDat    : TInputScreen;
BEGIN
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.13, 0.87, 0.1, 0.9);
      LoadLine('');
      LoadLine('             Data for a Child on a Swing.');
      LoadLine('');
      LoadLine(' Enter the length of the swing, between 6 and 20 ft:');
      LoadLine('                 Length = {      } ft');
      LoadLIne(' Enter the height of the child. It should be between');
      LoadLine(' 2 and 5 feet:');
      LoadLine('         Child''s height = {      } ft');
      LoadLine(' Enter the weight of the child, between 20 and 100 lb:');
      LoadLine('         Child''s weight = {      } lb');
      LoadLIne(' Enter a value for the resistance parameter:');
      LoadLine('                     0 <= {      } <= 10');
      LoadLine('');
      LoadLine(' Operate the swing automatically #1 or manually #1 ');
      LoadLine('');
      LoadLine(' See the animated motion #2 or a phase-plane plot #2');
      LoadLine('');
      LoadLIne('            [  OK  ]              [Cancel]');
      SetNumber(1, Length);
      SetNumberLimits(1, 5, 20);
      SetNumber(2, Height);
      SetNumberLimits(2, 2, 5);
      SetNumber(3, Weight);
      SetNumberLimits(3, 20, 100);
      SetNumber(4, Resist);
      SetNumberLimits(4, 0, 10);
      IF Automatic THEN SetRadioButton(RBNames[1], 1)
                   ELSE SetRadioButton(RBNames[1], 2);
      IF NOT PhasePlot THEN SetRadioButton(RBNames[2], 1)
                       ELSE SetRadioButton(RBNames[2], 2);
      AcceptScreen;
      GetSwingData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Length := GetNumber(1);
         Height := GetNumber(2);
         Weight := GetNumber(3);
         Resist := GetNumber(4);
         F := 2*Height/Length;
         IF GetRadioButton(RBNames[1]) = 1 THEN Automatic := True
                                           ELSE Automatic := False;
         IF GetRadioButton(RBNames[2]) = 1 THEN PhasePlot := False
                                           ELSE PhasePlot := True;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION GetSwingStart : Boolean;
VAR
   PendDat    : TInputScreen;
BEGIN
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.13, 0.87, 0.3, 0.7);
      LoadLine('');
      LoadLine('       Starting Conditions for a Child on a Swing.');
      LoadLine('');
      LoadLine(' The swing makes angle Theta with the downward vertical.');
      LoadLine(' It should lie between -180 and 180 degrees.');
      LoadLIne(' Enter initial values: Theta = {       } degrees');
      LoadLine('                  ThetaPrime = {       } degrees/sec');
      LoadLine('');
      LoadLIne('          [  OK  ]              [Cancel]');
      SetNumber(1, Theta);
      SetNumberLimits(1, -180, 180);
      SetNumber(2, ThetaPrime);
      SetNumberLimits(2, -180, 180);
      AcceptScreen;
      GetSwingStart := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Theta := GetNumber(1);
         ThetaPrime := GetNumber(2);
         y[1] := (Pi/180)*Theta;
         y[2] := (Pi/180)*ThetaPrime;
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
VAR
   Ht, Coeff    : Real;
BEGIN
   z[1] := y[2];
   IF Standing THEN Ht := Height ELSE Ht := Height/2;
   Coeff := 32*(Length - Ht/2)/(Length*Length - Length*Ht + Ht*ht/3);
   z[2] := -Resist*Ht*Coeff*y[2]/Weight - Coeff*Sin(y[1]);
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
END;

{------------------------------------------------------------------------}

PROCEDURE Join(x1, y1, x2, y2: Real);
VAR
   xn1, yn1, xn2, yn2 : Real;

BEGIN
   xn1 := x1*CosAngle + y1*SinAngle;
   yn1 := -x1*SinAngle + y1*CosAngle;
   xn2 := x2*CosAngle + y2*SinAngle;
   yn2 := -x2*SinAngle + y2*CosAngle;
   PlotLine(xn1, yn1, xn2, yn2);
END;

{------------------------------------------------------------------------}

Procedure PlotSwing(SwingColor: Word);
VAR
   Px0, Py0, Px1, Py1, Px2, Py2, Px3, Py3: Real;
   xSc, ySc: Integer;
   Radius   : Integer;
BEGIN
   GraphBackColor := Black;
   SetColor(Black);
   SetFillStyle(SolidFill, Black);
   SelectScale(1);
  { IF PhasePlot THEN OpenViewPort(3) ELSE OpenViewPort(1);}
   IF SwingColor <> Black THEN SetColor(LightBlue);
   CosAngle := Cos(y[1]);
   SinAngle := Sin(y[1]);
   Radius :=Trunc((MapX(1) - MapX(0))*F);
   IF SwingColor <> Black THEN SetFillStyle(SolidFill, Green);
   FillEllipse(MapX(0), MapY(0), Radius, Radius-1); {Pivot}
   Join(0, 0, 0, -30); {Rope}
   Join(-2, -30, 2, -30); {Seat}
   IF SwingColor <> Black THEN SetColor(White);
   Join(-1*F, -29.8, 0.5*F, -29.8); {Feet}
   IF NOT Standing THEN
   BEGIN
      Join(-1*F, -(30-0.2*F), 3*F, -(30-1*F)); {Lower leg}
      Join(3*F, -(30-1*F), -1*F, -(30-2*F)); {Upper leg}
      Join(-1*F, -(30-2*F), -2*F, -(30-8*F)); {Torso}
      Join(-1.7*F, -(30-7*F), 0, -(30-12*F)); {Arm}
      IF SwingColor <> Black THEN SetFillStyle(SolidFill, White);
      FillEllipse(MapX(-2*F*CosAngle-(30-9*F)*SinAngle),
      MapY(2*F*SinAngle - (30-9*F)*CosAngle), Radius, Radius-1);
   END
   ELSE
   BEGIN
      Join(-1*F, -(30-0.2*F), -2*F, -(30-8*F)); {Leg}
      Join(-2*F, -(30-8*F), -2*F, -(30-14*F)); {Torso}
      Join(-2*F, -(30-13*F), -2.8*F, -(30-11*F)); {Upper arm}
      Join(-2.8*F, -(30-11*F), 0, -(30-12*F)); {lower arm}
      IF SwingColor <> Black THEN SetFillStyle(SolidFill, White);
      FillEllipse(MapX(-2*F*CosAngle-(30-15*F)*SinAngle),
      MapY(2*F*SinAngle - (30-15*F)*CosAngle), Radius, Radius-1);
   END;
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

{------------------------------------------------------------------------}

PROCEDURE SetUpPhasePlot;
VAR
   xSc, ySc: Integer;
   CoordStr: String;
BEGIN
   Message('');
   PhasePlot := True;
   LightMenu := False;
   GraphBackColor := DarkGray;
   OpenViewPort(2);
   SelectScale(2);
   {SetUpPhaseHotKeys;}
   SetColor(White);
   PlotLine(-380, 0, 380, 0);
   PlotLine(0, -4.1, 0, 4.1);
   PlotLine(-360, 0, -360, 0.1);
   Map(-360, 0, xSc, ySc);
   Str(-360, CoordStr);
   OutTextxy(xSc-XDisp(10), ySc+YDisp(10), CoordStr);
   PlotLine(360, 0, 360, 0.1);
   Map(360, 0, xSc, ySc);
   Str(360, CoordStr);
   OutTextxy(xSc-XDisp(10), ySc+YDisp(10), CoordStr);
   OutTextxy(xSc-XDisp(20), ySc-YDisp(15), 'Theta');
   PlotLine(0, -1.75, 10, -1.75);
   Map(0, -1.75, xSc, ySc);
   Str(-100, CoordStr);
   OutTextxy(xSc-XDisp(5), ySc+YDisp(5), CoordStr);
   PlotLine(0, 1.75, 10, 1.75);
   Map(0, 1.75, xSc, ySc);
   Str(100, CoordStr);
   OutTextxy(xSc+XDisp(5), ySc+YDisp(5), CoordStr);
   PlotLine(0, -3.5, 10, -3.5);
   Map(0, -3.5, xSc, ySc);
   Str(-200, CoordStr);
   OutTextxy(xSc-XDisp(5), ySc+YDisp(5), CoordStr);
   PlotLine(0, 3.5, 10, 3.5);
   Map(0, 3.5, xSc, ySc);
   Str(200, CoordStr);
   OutTextxy(xSc+XDisp(5), ySc+YDisp(5), CoordStr);
   OutTextxy(MapX(0)-XDisp(30), MapY(4.8), 'ThetaPrime');
   GraphBackColor := Black;
   OpenViewPort(3);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotPhase;

PROCEDURE PlotPoint(xp, yp: Real; PColor: Word);
VAR
   SaveColor       : Word;
   xPix, yPix      : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(PColor);
   Map(xp, yp, xPix, yPix);
   Line(xPix-1, yPix, xPix+1, yPix);
   Line(xPix, yPix-1, xPix, yPix+1);
   SetColor(SaveColor);
END;

PROCEDURE PlotTail;
VAR
   i: Integer;
BEGIN
   FOR i := 2 TO 10 DO
   BEGIN
      IF Abs(xPlot[i-1] - xPlot[i]) < 60 THEN
         PlotLine(xPlot[i-1], yPlot[i-1], xPlot[i], yPlot[i]);
      xPlot[i-1] := xPlot[i];
      yPlot[i-1] := yPlot[i];
   END;
END;

BEGIN
   SelectViewPort(3);
   SelectScale(1);
   PlotSwing(Yellow);
   SelectViewPort(2);
   SelectScale(2);
      xPlot[10] := y[1]*180/Pi;
      yPlot[10] := y[2];
      IF (xPlot[10] < 360) AND (xPlot[10] > -360) THEN
      BEGIN
         PlotPoint(xPlot[9], yPlot[9], DarkGray);
         {SetColor(DarkGray); PlotSymbol(xPlot[9], yPlot[9], '.');
         SetColor(LightBlue);
         PlotSymbol(xPlot[10], yPlot[10], '.');}
         PlotPoint(xPlot[10], yPlot[10], LightBlue);
         SetColor(Yellow);
         PlotTail;
      END
      ELSE
      BEGIN
         IF xPlot[10] > 360 THEN xPlot[10] := xPlot[10] - 720;
         IF xPlot[10] < - 360 THEN xPlot[10] := xPlot[10] + 720;
         y[1] := xPlot[10]*Pi/180;
         PlotPoint(xPlot[9], yPlot[9], DarkGray);
         PlotPoint(xPlot[10], yPlot[10], LightBlue); StaticPause;
         {SetColor(DarkGray);
         PlotSymbol(xPlot[9], yPlot[8], 'o');}
         SetColor(Yellow);
         PlotTail;
      END;
END;

{------------------------------------------------------------------------}

PROCEDURE TakeAStep;
BEGIN
   Delay(Lag);
   IF PhasePlot THEN
   SelectViewPort(3) ELSE SelectViewPort(1);
   PlotSwing(Black);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF PhasePlot THEN
   BEGIN
      IF y[1] > 2*Pi THEN y[1] := y[1] - 4*Pi;
      IF y[1] < -2*Pi THEN y[1] := y[1] + 4*Pi;
   END
   ELSE
   BEGIN
      IF y[1] > 2*Pi THEN y[1] := y[1] - 2*Pi;
      IF y[1] < -2*Pi THEN y[1] := y[1] + 2*Pi;
   END;
   IF Automatic THEN
   BEGIN
      IF Sin(y[1])*y[2] > 0 THEN Standing := False ELSE Standing := True;
      IF (y[1] > Pi) OR (y[1] < -Pi) THEN Standing := False;
   END;
   IF PhasePlot THEN PlotPhase ELSE PlotSwing(White);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpAnimation;
VAR
  i         : Integer;
BEGIN
   IF Automatic THEN SetUpAutoHotKeys ELSE SetUpHotKeys;
   LightMenu := False;
   Action := True;
   Pause := False;
   Standing := False;
   SelectViewPort(1);
   SelectScale(1);
   Time := 0;
   StepSize := 0.1;
   FOR i := 1 TO 10 DO
   BEGIN
      xPlot[i] := y[1]*180/Pi;
      yPlot[i] := y[2];
   END;
   HideMouse;
   Message('');
   IF PhasePlot THEN SetUpPhasePlot;
   IF PhasePlot THEN PlotPhase ELSE PlotSwing(White);
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleAutoHotKeys(Key: Byte);
CONST
   DelLag = 20;
BEGIN
      CASE Key OF
         1: BEGIN
            IF Pause = True THEN
            BEGIN
               Pause := False;
               WITH AutoHotKeys DO Key[1] := 'F2-Pause';
               AutoHotKeys.BackColor := Blue;
               AutoHotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := True;
               WITH AutoHotKeys DO Key[1] := 'F2-Run';
               AutoHotKeys.BackColor := Red;
               AutoHotKeys.Display;
            END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag;
      3: Lag := Lag + DelLag;
      4: BEGIN
            Action := False;
            Pause := False;
            PhasePlot := False;
            AutoHotKeys.Clear;
            ClearMuppetPort;
            ShowMouse;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
CONST
   DelLag = 20;
BEGIN
      PauseChange := False;
      CASE Key OF
         1: BEGIN
            PauseChange := True;
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
      2: BEGIN
            IF Standing THEN
            BEGIN
               IF PhasePlot THEN SelectViewPort(3);
               PlotSwing(Black);
               Standing := False;
               WITH HotKeys DO Key[2] := 'F3-Up';
               HotKeys.Display;
            END
            ELSE
            BEGIN
               IF PhasePlot THEN SelectViewPort(3);
               PlotSwing(Black);
               Standing := True;
               WITH HotKeys DO Key[2] := 'F3-Down';
               HotKeys.Display;
            END;
         END;
      3: IF Lag > DelLag THEN Lag := Lag - DelLag;
      4: Lag := Lag + DelLag;
      5: BEGIN
            ClearMuppetPort;
               Action := False;
               Pause := False;
               HotKeys.Clear;
               LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSwingMenu;
BEGIN
   With SwingMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpPend.hlp', 'SwingAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpPend.hlp', 'SwingAboutModel1');
                  ShowHelp('HelpPend.hlp', 'SwingAboutModel2');
                  ShowHelp('HelpPend.hlp', 'SwingAboutModel3');
               END;
            2: BEGIN
                  ShowHelp('WalkThru.hlp', 'Swing1');
                  ShowHelp('WalkThru.hlp', 'Swing2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF GetSwingData THEN IF GetSwingStart THEN SetUpAnimation
                                  ELSE LightMenu := True;
               END;
            2: GetSwingStart;
            3: SetUpAnimation;
            4: BEGIN
                  PhasePlot := True;
                  SetUpAnimation;
               END;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.07, 0.93, 0.08, 0.93);
   DefineScale(1, -50, 50, - 35, 35);
   DefineViewPort(2, 0.2, 0.97, 0.08, 0.92);
   DefineScale(2, -400, 400, -5, 5);
   DefineViewPort(3, 0, 0.2, 0.35, 0.65);
   GraphBackColor := Black;
   Theta := 0;
   ThetaPrime := 50;
   y[1] := (Pi/180)*Theta;
   y[2] := (Pi/180)*ThetaPrime;
   Length := 8;
   Height := 4;
   F := 2*Height/Length;
   Weight := 64;
   Resist := 0.01;
   Lag := 100;
   ExitRequest := False;
   LightMenu := True;
   Automatic := True;
   PhasePlot := False;
   SelectScale(1);
   SelectViewPort(1);
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
END;

{------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   GetSetUp;
   Hello('HelpPend.hlp', 'SwingAboutProgram');
   SetUpSwingMenu;
   IF GetSwingData THEN IF GetSwingStart THEN SetupAnimation;
   REPEAT
      CheckForEvents;
      IF Automatic AND AutoHotkeys.Pressed(Key) THEN HandleAutoHotKeys(Key);
      IF (NOT Automatic) AND HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF (NOT Pause) AND (Action) THEN TakeAStep;
      IF LightMenu THEN
         IF SwingMenu.Chosen THEN HandleSwingMenu;
   UNTIL ExitRequest;
   CUPSDone;
   SwingMenu.Done;
END.

