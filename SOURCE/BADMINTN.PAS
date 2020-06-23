PROGRAM Badminton;

Uses Crt, Graph, CUPSMupp, CUPS, CupsGui;

CONST
   Neq = 4;

TYPE
   Vector = Array[1..Neq] OF Real;

VAR
   Time, StepSize        : Real;
   Dt                    : Real;
   NextTime              : Real;
   Drag                  : Real;
   ExitRequest           : Boolean;
   LightMenu             : Boolean;
   InputChanged          : Boolean;
   CleanUp               : Boolean;
   HitNet                : Boolean;
   UnderNet              : Boolean;
   FirstTime             : Boolean;
   Y                     : Vector;
   BadmintonMenu         : TMenu;
   HotKeys               : THotKeys;
   Key                   : Byte;
   x0, z0, Angle, Speed  : Real;
   Lag                   : Integer;
   nDt                   : Integer;
   nPoints               : Integer;
   Bx, By                : Array[0..250] OF Real;
   Bvx, Bvy              : Array[0..250] OF Real;

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

PROCEDURE SetUpBadmintonMenu;
VAR
   I      : Integer;
BEGIN
   With BadmintonMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About badminton');
       row(2,3, 'Walk-through');
      Column(3, 'Play');
       row(3,1, 'Play badminton');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   BadmintonMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Hit';
      Key[2] := 'F3-Cleanup';
      Key[3] := 'F4-Input';
      Key[4] := 'F5-Faster';
      Key[5] := 'F6-Slower';
      Key[6] := 'F10-Menu';
   END;
END;

{------------------------------------------------------------------------}

FUNCTION BadmintonData : Boolean;
VAR
   BadmintonDat: TInputScreen;
BEGIN
   WITH BadmintonDat DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.1, 0.9);
      LoadLine('');
      LoadLine('             Data for a stroke in badminton ');
      LoadLine('');
      LoadLine('  The drag coefficient for a shuttlecock is 0.0643 /ft.  ');
      LoadLine('  Enter your own value, if you would like to experiment!');
      LoadLine('  Drag coefficient:           0 <= {        } <= 0.5');
      LoadLine('');
      LoadLine('  Enter the data for the strike:');
      LoadLine('  Horizontal x-coordinate: - 20 <= {        } < 0');
      LoadLine('  Vertical   z-coordinate:     0 < {        } <= 9');
      LoadLine('  Speed in ft/sec:             0 < {        } <= 200');
      LoadLine('  Angle with horizontal:     -90 < {        } < 90 degrees');
      LoadLine('');
      LoadLine('  The path will be marked at regular intervals of time,');
      LoadLine('  0.01*n seconds, for integer n.');
      LoadLine('  Enter n:                     1 < {        } 200 ');
      LoadLine('');
      LoadLine('                [  OK  ]              [Cancel]');
      SetNumber(1, Drag);
      SetNumberLimits(1, 0, 0.5);
      SetNumber(2, x0);
      SetNumberLimits(2, -20, 0);
      SetNumber(3, z0);
      SetNumberLimits(3, 0, 9);
      SetNumber(4, Speed);
      SetNumberLimits(4, 0.000001, 200);
      SetNumber(5, Angle);
      SetNumberLimits(5, -90, 90);
      SetNumber(6, nDt);
      SetNumberLimits(6, 1, 200);
      AcceptScreen;
      BadmintonData := NOT Canceled;
      IF Canceled THEN InputChanged := False
      ELSE
      BEGIN
         InputChanged := True;
         Drag := GetNumber(1);
         x0 := GetNumber(2);
         z0 := GetNumber(3);
         Speed := GetNumber(4);
         Angle := GetNumber(5);
         nDt := Trunc(GetNumber(6));
         Dt := nDt*0.01;
         FirstTime := True;
      END;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpCourt;
BEGIN
   OpenViewPort(1);
   SelectScale(1);
   LightMenu := False;
   Message('');
   SetColor(White);
   PlotLine(-22, 0, 22, 0);
   PlotLine(-22, 20, 22, 20);
   PlotLine(0, 0, 0, 5);
   SetLineStyle(SolidLn, 0, ThickWidth);
   SetColor(LightGreen);
   PlotLine(0, 2.5, 0, 5);
   SetLineStyle(SolidLn, 0, NormWidth);
   SetColor(White);
   PlotLine(-22, 0, -22, 0.5);
   OutTextXY(MapX(-23.5), MapY(-0.5), '-22');
   PlotLine(22, 0, 22, 0.5);
   OutTextXY(MapX(22), MapY(-0.5), '22');
   PlotLine(-19.5, 0, -19.5, 0.5);
   PlotLine(19.5, 0, 19.5, 0.5);
   OutTextXY(MapX(18), MapY(-0.5), '19.5');
   PlotLine(-6.5, 0, -6.5, 0.5);
   OutTextXY(MapX(-7.8), MapY(-0.5), '-6.5');
   PlotLine(6.5, 0, 6.5, 0.5);
   OutTextXY(MapX(5.5), MapY(-0.5), '6.5');
   OutTextXY(MapX(-0.3), MapY(-0.5), '0');
   PlotLine(-25, 5, -24.5, 5);
   OutTextXY(MapX(-23.5), MapY(5.2), '5');
   PlotLine(-25, 10, -24.5, 10);
   OutTextXY(MapX(-24), MapY(10.2), '10');
   PlotLine(-25, 15, -24.5, 15);
   OutTextXY(MapX(-24), MapY(15.2), '15');
   PlotLine(25, 5, 24.5, 5);
   OutTextXY(MapX(23.5), MapY(5.2), '5');
   PlotLine(25, 10, 24.5, 10);
   OutTextXY(MapX(22.7), MapY(10.2), '10');
   PlotLine(25, 15, 24.5, 15);
   OutTextXY(MapX(22.7), MapY(15.2), '15');
   HotKeys.Display;
   IF NOT CleanUp THEN
      IF NOT BadmintonData THEN
      BEGIN
         ClearMuppetPort;
         LightMenu := True;
         Exit;
      END;
   RubOutXY(0.24, 0.81, 50, GraphBackColor);
   SetColor(Yellow);
   PrintXY(0.24, 0.81, 'Path marked at intervals of '+NumStr(dT, 4, 2)
                                + ' seconds');
   SetColor(White);
END;


{------------------------------------------------------------------------}

PROCEDURE DrawShuttleCock(x, y, xv, yv: Real; SColor   : Word);
VAR
   SaveColor     : Word;
   Radius        : Integer;
BEGIN
   Radius := Trunc(3*GetMaxX/639);
   SaveColor := GetColor;
   SetColor(SColor);
   SetFillStyle(SolidFill, SColor);
   FillEllipse(MapX(x), MapY(y), Radius, Radius);
   SetColor(SaveColor);
END;


{------------------------------------------------------------------------}

PROCEDURE Fun(X: Real; Y: Vector; VAR Z: Vector);
VAR
   V    : Real;
BEGIN
   Z[1] := Y[2];
   Z[3] := y[4];
   V := Sqrt(y[2]*y[2] + y[4]*y[4]);
   Z[2] := - Drag*y[2]*V;
   Z[4] := - Drag*y[4]*v - 32;
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

PROCEDURE MarkTimeStep;
VAR
   TempStep  : Real;
   V         : Real;
BEGIN
   SetColor(Yellow);
   TempStep := NextTime - Time;
   IF TempStep > 0.001 THEN
   BEGIN
      Step(Time, TempStep, 0.00001, y, Time, TempStep, y);
   END;
   V := Sqrt(y[2]*y[2] + y[4]*y[4]);
   PlotLine(y[1], y[3], y[1] - 0.9*y[4]/V, y[3] + 0.7*0.9*y[2]/V);
   SetColor(White);
   NextTime := Time + Dt;
END;

{-----------------------------------------------------------------------}

PROCEDURE StoreTrajectory;
VAR
   Oldx    : Real;
BEGIN
   y[1] := x0;
   y[3] := z0;
   y[2] := Speed*Cos(Angle*Pi/180);
   y[4] := Speed*Sin(Angle*Pi/180);
   Bx[0] := y[1];
   By[0] := y[3];
   Bvx[0] := y[2];
   Bvy[0] := y[4];
   Oldx := y[1];
   Time := 0;
   HitNet := False;
   nPoints := 0;
   REPEAT
      StepSize := 0.01;
      NextTime := Time + 0.01;
      REPEAT
         Step(Time, StepSize, 0.00000001, Y, Time, StepSize, Y);
         StepSize := NextTime - Time;
      UNTIL Abs(StepSize) < 0.0001;
      IF (y[1]*Oldx < 0) AND (y[3] < 5) AND (Y[3] > 2.5)
          THEN HitNet := True ELSE HitNet := False;
      IF (y[1] > 0) AND (y[3] < 2.5)
          THEN UnderNet := True ELSE UnderNet := False;
      nPoints := nPoints + 1;
      IF y[3] < 0 THEN By[nPoints] := 0 ELSE By[nPoints] := y[3];
      IF HitNet THEN
      BEGIN
         Bx[nPoints] := 0;
         By[nPoints] := By[nPoints-1];
      END
      ELSE Bx[nPoints] := y[1];
      Bvx[nPoints] := y[2];
      Bvy[nPoints] := y[4];
      Oldx := y[1];
   UNTIL (y[3] < 0) OR (y[3] > 20) OR (y[1] > 25) OR HitNet;
END;

{-----------------------------------------------------------------------}

PROCEDURE RunTrajectory;
VAR
   NPlotted    : Integer;
   N, M        : Integer;
   NextN       : Integer;
   V           : Real;
BEGIN
   HideMouse;
   NPlotted := 0;
   NextN := nDt;
   FOR N := 1 TO nPoints DO
   BEGIN
      DrawShuttleCock(Bx[n-1], By[n-1], Bvx[n-1], Bvy[n-1], GraphBackColor);
      DrawShuttleCock(Bx[n], By[n], Bvx[n], Bvy[n], Yellow);
      IF NPlotted < 3 THEN NPlotted := NPlotted + 1;
      FOR M := 1 TO NPLotted DO
         PlotLine(Bx[N-M], By[N-M], Bx[N-M+1], By[N-M+1]);
      IF N = NextN THEN
      BEGIN
         SetColor(Yellow);
         V := Sqrt(Bvx[n]*Bvx[n] + Bvy[n]*Bvy[n]);
         PlotLine(Bx[n], By[n], Bx[n] - 0.9*Bvy[n]/V, By[n] + 0.7*0.9*Bvx[n]/V);
         SetColor(White);
         NextN := N + Ndt;
      END;
      IF (Bx[N-Nplotted] > 0) AND UnderNet THEN PlotLine(0, 0, 0, 2.5);
      Delay(Lag);
   END;
   IF UnderNet THEN
   BEGIN
      SetColor(White);
      PlotLine(0, 0, 0, 2.5);
   END;
   IF HitNet THEN
   BEGIN
      Delay(500);
      DrawShuttleCock(Bx[nPoints], By[nPoints],
                      Bvx[n], Bvy[n], GraphBackColor);
      SetLineStyle(SolidLn, 0, ThickWidth);
      SetColor(LightGreen);
      PlotLine(0, 2.5, 0, 5);
      SetLineStyle(SolidLn, 0, NormWidth);
      SetColor(White);
      PlotLine(Bx[nPoints-2], By[nPoints-2], Bx[nPoints], By[nPoints]);
      PlotLine(0, By[nPoints], -1, 0);
      DrawShuttleCock(-1, 0,
                      Bvx[n], Bvy[n], Yellow);
   END;
   ShowMouse;
END;

{-----------------------------------------------------------------------}

PROCEDURE HitShuttleCock;
VAR
   Oldx, Oldy, Oldxv, Oldyv : Real;
BEGIN
   IF FirstTime THEN
   BEGIN
      StoreTrajectory;
      FirstTime := False;
   END;
   RunTrajectory;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag      : Integer;
BEGIN
   DelLag := 10;
   CASE Key OF
      1: HitShuttleCock;
      2: BEGIN CleanUp := True; SetUpCourt; END;
      3: BEGIN
            IF NOT BadmintonData THEN
            BEGIN
               ClearMuppetPort;
               LightMenu := True;
               Exit;
            END;
            RubOutXY(0.24, 0.81, 50, GraphBackColor);
            SetColor(Yellow);
            PrintXY(0.24, 0.81, 'Path marked at intervals of '+NumStr(dT, 4, 2)
                                + ' seconds');
            SetColor(White);
         END;
      4: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      5: Lag := Lag + DelLag;
      6: BEGIN
            HotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE HandleBadmintonMenu;

BEGIN
   With BadmintonMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: BEGIN
                  AboutCUPS;
                  LightMenu := True;
               END;
            2: ShowHelp('HlpSport.hlp', 'BadmintonAboutProgram');
            3: BEGIN
                  Configuration;
                  LightMenu := True;
               END;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpSport.hlp', 'BadmintonAboutModel');
            2: ShowHelp('HlpSport.hlp', 'BadmintonAboutBadminton');
            3: ShowHelp('WalkThru.hlp', 'Badminton');
         END;
      3: BEGIN CleanUp := False; SetUpCourt; END;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE SetStartingParameters;
BEGIN
   Drag := 0.0643;
   x0 := -15;
   z0 := 8;
   Speed := 100;
   Angle := 20;
   Dt := 0.05;
   Lag := 10;
   nDt := 10;
   DefineViewPort(1, 0.05, 0.95, 0.15, 0.85);
   DefineScale(1, -25, 25, -2, 23);
   ExitRequest := False;
   LightMenu := False;
   CleanUp := False;
END;

{-----------------------------------------------------------------------}

BEGIN {MAIN PROGRAM}

   CUPSInit;
   SetStartingParameters;
   Hello('HlpSport.hlp', 'BadmintonAboutProgram');
   SetUpBadmintonMenu;
   SetUpHotKeys;
   SetUpCourt;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF LightMenu THEN IF BadmintonMenu.Chosen THEN HandleBadmintonMenu;
   UNTIL ExitRequest;
   CUPSDone;
   BadmintonMenu.Done;
END.

