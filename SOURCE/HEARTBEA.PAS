Program HeartBeat;

Uses Crt, Graph, CupsMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                   : Vector;
   h                      : Real;
   Time                   : Real;
   SaveTime, SaveY2       : Real;
   X0, x1, b0, b1, b10    : Real;
   B1Old, x1Old           : Real;
   Tension                : Real;
   Epsilon                : Real;
   xMax, yMax, xMin, yMin : Real;
   MaxX, MinX             : Real;
   MaxY, MinY             : Real;
   MaxTime                : Real;
   bStart, xStart         : Real;
   Control                : Integer;
   NumberStored           : Integer;
   EKGNumberStored        : Integer;
   Lag                    : Integer;
   HotKeys                : THotKeys;
   ContractKeys           : THotKeys;
   InputHotKeys           : THotKeys;
   ZeemanMenu             : TMenu;
   Sliders                : TSliders;
   TensionSlider          : TSliders;
   ExitRequest            : Boolean;
   HeartBeating           : Boolean;
   Contraction            : Boolean;
   CompleteCycles         : Boolean;
   FirstBeat              : Boolean;
   LightMenu              : Boolean;
   Sliding                : Boolean;
   EKG                    : Boolean;
   FindTension            : Boolean;
   Inputting              : Boolean;
   UseMouse               : Boolean;
   Key                    : Byte;
   StoreX, StoreY         : Array[0..50] OF Real;
   EKGX, EKGY             : Array[0..50] OF Real;
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

PROCEDURE SetUpZeemanMenu;
VAR
   I      : Integer;
BEGIN
   With ZeemanMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'The model');
       row(2,2, 'Contraction');
       row(2,3, 'Cycles');
       row(2,4, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Follow contraction to systole');
       row(3,2, 'See complete cycles');
       row(3,3, 'Plot an EKG');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   ZeemanMenu.Display;
END;

{----------------------Integration Procedures-----------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
begin
   IF Contraction THEN Control := 1;
   z[1] := - (y[1]*y[1]*y[1] - Tension*y[1] + y[2])/Epsilon;
   z[2] := (y[1] - x0) + Control*(x0 - x1);
end;

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
      temax := tol/10000;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol;
   yout := y;
   xout := xtemp + htemp;
   hout := h;
end;

{---------------------End of Integation procedures----------------------}
{-------------------------Graphics procedures---------------------------}

PROCEDURE PlotPoint(xp, yp : Real; pcolor : Word);
VAR
   xsc, ysc, i, j      : Integer;
BEGIN
   Map(xp, yp, xsc, ysc);
   FOR i := 1 TO 3 DO
      FOR j := 1 TO 3 DO
         PutPixel(xsc-1+I, ysc-1+j, pcolor);
END;

{-----------------------------------------------------------------------}

FUNCTION FindScale  : Boolean;
VAR
   SaveControl   : Integer;
   ChangeControl : Integer;
   DelX          : Real;
   WaitMessage   : TWaitMessage;
BEGIN
   MaxX := b1;
   MinX := b0;
   MaxY := x0;
   MinY := x1;
   y[1] := x0;
   y[2] := 0.9*b0;
   Epsilon := 0.1;
   Control := 1;
   SaveControl := Control;
   ChangeControl := 0;
   Time := 0;
   h := 0.1;
   DelX := (MaxX - MinX)/100;
   Message('Calculating the scale. Press any key to stop');
   WaitMessage.Show;
   REPEAT
      Step(Time, h, 0.00001, y, Time, h, y);
      IF (y[1] - x1)*(y[1] - x1) + (y[2] - b1)*(y[2] - b1) < DelX
          THEN Control := 0;
      IF (y[1] - x0)*(y[1] - x0) + (y[2] - b0)*(y[2] - b0) < DelX
          THEN Control := 1;
      IF y[2] > b1 THEN Control := 0;
      IF Control - SaveControl <> 0 THEN
      BEGIN
         ChangeControl := ChangeControl + 1;
         SaveControl := Control;
      END;
      IF MinX > y[2] THEN MinX := y[2];
      IF MaxX < y[2] THEN MaxX := y[2];
      IF MinY > y[1] THEN MinY := y[1];
      IF MaxY < y[1] THEN MaxY := y[1];
      WaitMessage.UpDate;
   UNTIL (ChangeControl = 2) OR KeyPressed;
   MaxTime := 5*Time;
   FindScale := NOT KeyPressed;
   ClearMKBuffers;
   WaitMessage.Hide;
END;

{-------------------------------------------------------------------------}

FUNCTION XDisp(Delta : Integer) : Integer;
BEGIN
   XDisp := Trunc(Delta*xScreenRatio);
END;

FUNCTION YDisp(Delta : Integer) : Integer;
BEGIN
   YDisp := Trunc(Delta*yScreenRatio);
END;

{-----------------------------------------------------------------------}

PROCEDURE DrawAxes;
VAR
   xSc, ySc : Integer;
   i        : Integer;
BEGIN
   HideMouse;
   SetColor(White);
   PlotLine(MinX, 0, MaxX, 0);
   PlotLine(0, MaxY, 0, MinY);
   Map(MaxX + 0.1, 0.1, xSc, ySc);
   OutTextxy(xSc, ySc, 'b');
   Map(0, MaxY, xSc, ySc);
   OutTextxy(xSc+10, ySc, 'x');
   IF NOT EKG THEN
   BEGIN
      Map(MinX, 1.4*MaxY, xSc, ySc);
      OutTextxy(xSc+XDisp(10), ySc+YDisp(10), 'x refers to muscle fiber length');
      OutTextxy(xSc+XDisp(10), ySc+YDisp(20), 'b refers to electrochemical activity');
   END;
   i := 1;
   REPEAT
      IF i < MaxX THEN
      BEGIN
         PlotLine(i, 0, i, 0.1);
         OutTextXY(MapX(i)-XDisp(20), MapY(-0.1), NumStr(i, 2, 0));
      END;
      IF -i > MinX THEN
      BEGIN
         PlotLine(-i, 0, -i, 0.1);
         OutTextXY(MapX(-i)-XDisp(10), MapY(-0.1), NumStr(-i, 2, 0));
      END;
      i := i + 1;
   UNTIL (i > MaxX) AND (-i < MinX);
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE FindSystole;
VAR
   i       : Integer;
   xSearch : Real;
   dx      : Real;
   Sign    : Real;
BEGIN
   xSearch := 0.01;
   Sign := xSearch*xSearch*xSearch - Tension*xSearch + b1;
   dx := 0.01;
   REPEAT
      xSearch := xSearch - dx;
   UNTIL (xSearch*xSearch*xSearch - Tension*xSearch + b1)*Sign < 0;
   x1 := xSearch;
   i := 0;
   REPEAT
      i := i + 1;
      dx :=  - (x1*x1*x1 - Tension*x1 + b1)/(3*x1*x1 - Tension);
      x1 := x1 + dx;
   UNTIL (Abs(dx) < 0.0001) OR (i = 10);
END;

{------------------------------------------------------------------------}

PROCEDURE FindDiastole;
VAR
   i       : Integer;
   xSearch : Real;
   dx      : Real;
   Sign    : Real;
BEGIN
   xSearch := - 0.01;
   Sign := xSearch*xSearch*xSearch - Tension*xSearch + b0;
   dx := 0.01;
   REPEAT
      xSearch := xSearch + dx;
   UNTIL (xSearch*xSearch*xSearch - Tension*xSearch + b0)*Sign < 0;
   x0 := xSearch;
   i := 0;
   REPEAT
      i := i + 1;
      dx :=  - (x0*x0*x0 - Tension*x0 + b0)/(3*x0*x0 - Tension);
      x0 := x0 + dx;
   UNTIL (Abs(dx) < 0.0001) OR (i = 10);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawAttractor;
VAR
   i               : Integer;
   YStart, YEnd    : Real;
   DelY            : Real;

FUNCTION F(x : Real): Real;
BEGIN
   F := - x*x*x + Tension*x;
END;

BEGIN
   SetColor(LightBlue);
   YStart := MaxY;
   IF F(YStart) - MinX < 0 THEN
   BEGIN
      REPEAT
         YStart := YStart - 0.01;
      UNTIL F(YStart) - MinX > 0;
   END;
   YEnd := MinY;
   IF F(YEnd) - MaxX > 0 THEN
   BEGIN
      REPEAT
         YEnd := YEnd + 0.01;
      UNTIL F(YEnd) - MaxX < 0;
   END;
   DelY := (YStart - YEnd)/30;
   HideMouse;
   FOR i := 0 TO 30 DO
   BEGIN
      StoreY[i] := YStart - i*DelY;
      StoreX[i] := StoreY[i]*(Tension - StoreY[i]*StoreY[i]);
      IF i > 0 THEN
      PlotLine(StoreX[i-1], StoreY[i-1],
                             StoreX[i], StoreY[i]);
   END;
   ShowMouse;
   IF Contraction THEN
   BEGIN
      PlotSymbol(b1, x1, '*');
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE ReDrawAttractor;
VAR
   SaveColor  : Word;
   i          : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(GraphBackColor);
   HideMouse;
   FOR i := 1 TO 30 DO
      PlotLine(StoreX[i-1], StoreY[i-1],
                             StoreX[i], StoreY[i]);
   IF Contraction THEN PlotSymbol(b1Old, x1Old, '*');
   SetColor(White);
   PlotLine(0, -2.5, 0, 2.5);
   SetColor(SaveColor);
   ShowMouse;
   DrawAttractor;
   IF Contraction THEN
   BEGIN
      PlotSymbol(b1, x1, '*');
      b1Old := b1;
      x1Old := x1;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION StartHeartBeat : Boolean;
VAR
   xSc, ySc : Integer;
   i        : Integer;
BEGIN
   IF EKG THEN
   BEGIN
      CloseViewPort(1);
      OpenViewPort(3);
      OpenViewPort(4);
   END
   ELSE
   BEGIN
      OpenViewPort(1);
      HotKeys.Display;
   END;
   TensionSlider.Create(1, 0, 5, Tension, 0.05, 0.2, 0.8, 2, '0', '5', 'Tension', True);
   TensionSlider.DrawAll;
   FindSystole;
   FindDiastole;
   IF NOT FindScale THEN
   BEGIN
      StartHeartBeat := False;
      Exit;
   END
   ELSE StartHeartBeat := True;
   DefineScale(1, MinX-1, MaxX+1, 1.4*MinY, 1.4*MaxY);
   SelectScale(1);
   PlotSymbol(b0, x0, '*');
   Map(b0, x0, xSc, ySc);
   OutTextxy(xSc-XDisp(25), ySc-YDisp(20), 'Diastole');
   PlotSymbol(b1, x1, '*');
   Map(b1, x1, xSc, ySc);
   OutTextxy(xSc-XDisp(25), ySc+YDisp(20), 'Systole');
   DrawAxes;
   SetColor(LightGreen);
   DrawAttractor;
   SetColor(Yellow);
   y[1] := x0;
   y[2] := 0.9*b0;
   NumberStored := 0;
   StoreX[1] := y[2];
   StoreY[1] := y[1];
   Epsilon := 0.1;
   Control := 1;
   Time := 0;
   h := 0.1;
   SetColor(Yellow);
   PlotPoint(y[2], y[1], Cyan);
   FirstBeat := True;
END;

{-----------------Procedures for complete cycles-------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Tension';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-Faster';
      Key[4] := 'F5-Slower';
      Key[5] := 'F10-Menu';
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpInputHotKeys;
BEGIN
   WITH InputHotKeys DO
   BEGIN
      InputHotKeys.Init(1);
      Key[1] := 'F2-Systole';
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE NewInput;
BEGIN
   GraphBackColor := Black;
   OpenViewPort(1);
   DefineScale(1, -9, 9, -3, 3);
   SelectScale(1);
   MaxX := 8;
   MinX := -8;
   MaxY := 2.9;
   MinY := -2.9;
   DrawAxes;
   DrawAttractor;
   WITH InputHotKeys DO Key[1] := 'F2-Systole';
   InputHotKeys.Display;
   TensionSlider.Create(1, 0, 5, Tension, 0.05, 0.2, 0.8, 2, '0', '5', 'Tension', True);
   TensionSlider.DrawAll;
   Inputting := True;
   Sliding := True;
   HeartBeating := False;
   Message('Select a tension. Then press or click on <F2-Systole>.');
END;

PROCEDURE SelectKeyEquilibria;
VAR
   Input   : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.8, 1);
      LoadLine('              Enter values of B:');
      LoadLine(' Diastole:  - 8 < B0 = {      } < 0');
      LoadLine(' Systole:     0 < B1 = {      } < 8');
      LoadLine('             [  OK  ]');
      SetNumber(1, b0);
      SetNumberLimits(1, -8, 0);
      SetNUmber(2, b1);
      SetNumberLimits(2, 0, 8);
      AcceptScreen;
      b0 := GetNumber(1);
      b1 := GetNumber(2);
      Done;
   END;
   FindDiastole;
   FindSystole;
   PlotSymbol(b0, x0, '*');
   PlotSymbol(b1, x1, '*');
   HideMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE SelectMouseEquilibria;
VAR
   Inside   : Boolean;
   Found    : Boolean;
BEGIN
   SetColor(White);
   Message('      Click on the systole.  b > 0, x < 0, on the attractor.');
   Delay(500);
   REPEAT
      WaitOnMouseClick;
      MousePosn(b1, x1, 1, 1, Inside);
      IF (Abs(x1*x1*x1 - Tension*x1 + b1) < 0.4) AND (x1 < 0) AND (b1 > 0) THEN
      BEGIN
         Found := True;
         b1 := - x1*x1*x1 + x1*Tension;
         PlotSymbol(b1, x1, '*');
      END
      ELSE
      BEGIN
         Found := False;
         Announce('Too far from the attractor. Try again');
      END;
   UNTIL Found;
   WITH InputHotKeys DO Key[1] := 'F2-Diastole';
            InputHotKeys.Display;
   Delay(500);
   Message('      Click on the diastole.  b < 0, x > 0, on the attractor.');
   REPEAT
      WaitOnMouseClick;
      MousePosn(b0, x0, 1, 1, Inside);
      IF (Abs(x0*x0*x0 - Tension*x0 + b0) < 0.4) AND (x0 > 0) AND (b0 < 0) THEN
      BEGIN
         Found := True;
         b0 := - x0*x0*x0 + Tension*x0;
         PlotSymbol(b0, x0, '*');
      END
      ELSE
      BEGIN
         Found := False;
         Announce('Too far from the attractor. Try again');
      END;
   UNTIL Found;
   HideMouse;
   ClearMKBuffers;
   Message('');
END;

{-------------------------------------------------------------------------}

PROCEDURE SelectEquilibria;
VAR
   Input      : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.3, 0.7, 0.8, 0.9);
      LoadLine('  Use mouse #1 or keyboard #1');
      LoadLine('        [  OK  ]');
      IF UseMouse THEN SetRadioButton('1', 1)
                  ELSE SetRadioButton('1', 2);
      AcceptScreen;
      IF GetRadioButton('1') = 1 THEN
              UseMouse := True ELSE UseMouse := False;
      Done;
   END;
   IF UseMouse THEN SelectMouseEquilibria ELSE SelectKeyEquilibria;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotTail;
VAR
   i : Integer;
BEGIN
   IF NumberStored > 1 THEN
   BEGIN
      FOR i := 1 TO NumberStored-1 DO
         PlotLine(StoreX[i], StoreY[i], StoreX[i+1], StoreY[i+1]);
      PlotLine(StoreX[i+1], StoreY[i+1], y[2], y[1]);
   END;
   IF NumberStored < 20 THEN
   BEGIN
      NumberStored := NumberStored + 1;
      StoreX[NumberStored] := y[2];
      StoreY[NumberStored] := y[1];
   END;
   IF NumberStored = 20 THEN
   BEGIN
      FOR i := 1 TO 19 DO
      BEGIN
         StoreX[i] := StoreX[i+1];
         StoreY[i] := StoreY[i+1];
      END;
      StoreX[20] := y[2];
      StoreY[20] := y[1];
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HeartBeatStep;
VAR
  DelX : Real;
BEGIN
      IF EKG THEN
      BEGIN
         SelectViewPort(4);
         SelectScale(1);
      END
      ELSE
      BEGIN
         IF NOT Contraction THEN
         BEGIN
            SelectViewPort(1);
            SelectScale(1);
         END;
      END;
      FirstBeat := False;
      Delay(Lag);
      SetColor(GraphBackColor);
      PlotPoint(y[2], y[1], GraphBackColor);
      SetColor(White);
      IF NOT Contraction THEN PlotSymbol(b0, x0, '*');
      PlotSymbol(b1, x1, '*');
      SetColor(Yellow);
      Step(Time, h, 0.00001, y, Time, h, y);
      PlotPoint(y[2], y[1], Cyan);
      PlotTail;
      DelX := (MaxX - MinX)/100;
      IF (y[1] - x1)*(y[1] - x1) + (y[2] - b1)*(y[2] - b1) < DelX
          THEN Control := 0;
      IF (y[1] - x0)*(y[1] - x0) + (y[2] - b0)*(y[2] - b0) < DelX
          THEN Control := 1;
      IF y[2] > b1 THEN Control := 0;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag      : Integer;
BEGIN
   DelLag := 5;
      CASE Key OF
      1: BEGIN
            Message('Use the slider to define a new tension');
            Sliding := True;
            ShowMouse;
         END;
      2: BEGIN
            HeartBeating := False;
           { EKG := False;}
            ShowMouse;
            NewInput;
         END;
      3: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      4: Lag := Lag + DelLag;
      5: BEGIN
            ShowMouse;
            LightMenu := True;
            HeartBeating := False;
            EKG := False;
            ClearMuppetPort;
            ZeemanMenu.Display;
            ClearMKBuffers;
            CloseViewPort(1);
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpEKG;
VAR
   xSc, ySc    : Integer;
BEGIN
   OpenViewPort(3);
   HeartBeating := True;
   DefineScale(3, -2, MaxTime, 1.1*MinX, 1.1*MaxX);
   SelectScale(3);
   SetColor(White);
   Map(-2, 2*b1, xSc, ySc);
   OutTextxy(xSc+XDisp(10), ySc+YDisp(20), 'x refers to muscle fiber length');
   OutTextxy(xSc+XDisp(10), ySc+YDisp(30), 'b refers to electrochemical activity');
   PlotLine(0, 0, MaxTime, 0);
   PlotLine(0, 1.5*b0, 0, 1.5*b1);
   Map(85, 0, xSc, ySc);
   OutTextxy(xSc, ySc+YDisp(15), 'Time');
   Map(0, 1.5*b1, xSc, ySc);
   OutTextxy(xSc+XDisp(10), ySc, 'b');
   EKG := True;
   HotKeys.Display;
   HeartBeating := False;
   Time := 0;
   SaveTime := Time;
   SaveY2 := y[2];
   EKGX[1] := Time;
   EKGY[1] := y[2];
   NumberStored := 1;
   EKGNumberStored := 1;
   Epsilon := 0.1;
   Control := 1;
   h := 0.1;
   Lag := 20;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleInputHotKeys(Key : Byte);
BEGIN
   CASE Key OF
   1: BEGIN
         Sliding := False;
         Inputting := False;
         SelectEquilibria;
         InputHotKeys.Clear;
         IF StartHeartBeat THEN
         BEGIN
            IF EKG THEN SetUpEKG;
            HeartBeating := True;
         END
         ELSE
         BEGIN
            ClearMuppetPort;
            LightMenu := True;
         END;
      END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotEKGTail;
VAR
   i : Integer;
BEGIN
   IF EKGNumberStored > 1 THEN
   BEGIN
      FOR i := 1 TO EKGNumberStored-1 DO
         PlotLine(EKGX[i], EKGY[i], EKGX[i+1], EKGY[i+1]);
      PlotLine(EKGX[EKGNumberStored], EKGY[EKGNumberStored], Time, y[2]);
   END;
   IF EKGNumberStored < 40 THEN
   BEGIN
      EKGNumberStored := EKGNumberStored + 1;
      EKGX[EKGNumberStored] := Time;
      EKGY[EKGNumberStored] := y[2];
   END;
   IF EKGNumberStored = 40 THEN
   BEGIN
      FOR i := 1 TO 39 DO
      BEGIN
         EKGX[i] := EKGX[i+1];
         EKGY[i] := EKGY[i+1];
      END;
      EKGX[40] := Time;
      EKGY[40] := y[2];
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE TakeEKGStep;
BEGIN
   IF Time > MaxTime THEN Exit;
   SelectViewPort(3);
   SelectScale(3);
   Delay(Lag);
   SetColor(GraphBackColor);
   PlotPoint(SaveTime, SaveY2, GraphBackColor);
   SaveTime := Time;
   SaveY2 := y[2];
   SetColor(Yellow);
   PlotPoint(Time, y[2], Cyan);
   PlotEKGTail;
END;

{--------------------End of procedures for complete cycles---------------}
{-----------------------Procedures for contraction-----------------------}

PROCEDURE SetUpContractKeys;
BEGIN
   WITH ContractKeys DO
   BEGIN
      ContractKeys.Init(5);
      Key[1] := 'F1-Tension';
      Key[2] := 'F2-DField';
      Key[3] := 'F3-Solution';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F10-Menu';
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpContraction;
VAR
   i : Integer;
BEGIN
   GraphBackColor := Black;
   OpenViewPort(2);
   DefineScale(2, -9, 9, -3, 3);
   SelectScale(2);
   Contraction := True;
   MaxX := 8;
   MinX := -8;
   MaxY := 2.9;
   MinY := -2.9;
   Tension := 0;
   Lag := 20;
   b1 := 1;
   FindSystole;
   b1Old := b1;
   x1Old := x1;
   Message('');
   WITH ContractKeys DO Key[3] := 'F3-Solution';
      ContractKeys.BackColor := Blue;
      ContractKeys.Display;
   DrawAxes;
   DrawAttractor;
   Sliders.Create(1, 0, 5, Tension, 0.05, 0.2, 0.8, 2, '0', '5', 'Tension', True);
   Sliders.Create(2, 0.1, 8, b1, 0.93, 0.2, 0.8, 2, '0.1', '8', 'b-Systole', True);
   Sliders.DrawAll;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawDirectionField;
VAR
   DelX, DelY, Length       : Integer;
   DX, DY, DL               : Real;
   Slope                    : Real;
   x, y                     : Real;
   xEnd, yEnd               : Real;
   i, j                     : Integer;
   Xcol, yRow               : Integer;
   xMax, xMin               : Real;
   yMax, yMin               : Real;
   Factor                   : Real;

PROCEDURE GetDFieldData;
VAR
   DFieldData    : TInputScreen;
BEGIN
   WITH DFieldData DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.3, 0.75);
      LoadLine('      Data for the Direction Field');
      LoadLine('');
      LoadLine('     Arrows will be plotted using a grid of');
      LoadLine('  points in the x-y plane. Enter the numbers');
      LoadLine('  grid points along the axes; these must lie ');
      LoadLine('  between 10 and 50.');
      LoadLine('');
      LoadLine('       x-axis: {   }    y-axis: {   }');
      LoadLine('');
      LoadLine('                 [  OK  ]');
      SetNumber(1, XCol);
      SetNumber(2, YRow);
      SetNumberLimits(1, 10, 50);
      SetNumberLimits(2, 10, 50);
      AcceptScreen;
      XCol := Trunc(GetNumber(1) + 0.0001);
      YRow := Trunc(GetNumber(2) + 0.0001);
      Done;
   END;
END;

{------------------------------------------------------------------------}

Procedure Arrow(xa, ya, xb, yb: Real; Length: Integer);
VAR
   x, y: Integer;
   Fraction: Real;
   sxa, sya, sxb, syb   : Integer;
   Delx, Dely           : Integer;
   Ratio                : Real;
BEGIN
   sxa := MapX(xa);
   sya := MapY(ya);
   sxb := MapX(xa+xb/2);
   syb := MapY(ya+yb/2);
   Ratio := 0.5*Length/Sqrt((sxa-sxb)*(sxa-sxb) + (sya-syb)*(sya-syb));
   Delx := Trunc(Ratio*(sxb-sxa));
   Dely := Trunc(Ratio*(syb-sya));
   sxb := sxa + Delx;
   syb := sya + Dely;
   sxa := sxa - Delx;
   sya := sya - Dely;
   SetColor(Yellow);
   Fraction := 0.1;
   Line(sxa, sya, sxb, syb);
   x := Trunc(sxb - Fraction*(sxb - sxa) + Fraction*(syb - sya));
   y := Trunc(syb - Fraction*(syb - sya) - Fraction*(sxb - sxa));
   Line(sxb, syb, x, y);
   x := Trunc(sxb - Fraction*(sxb - sxa) - Fraction*(syb - sya));
   y := Trunc(syb - Fraction*(syb - sya) + Fraction*(sxb - sxa));
   Line(sxb, syb, x, y);
END;
   
{------------------------------------------------------------------------}

PROCEDURE PlotDot(xDot, yDot : Real);
VAR
   xC, yC  : Integer;
BEGIN
   xC := MapX(xDot);
   yC := MapY(yDot);
   PutPixel(xC, yC, White);
   PutPixel(xC+1, yC, White);
   PutPixel(xC-1, yC, White);
   PutPixel(xC, yC+1, White);
   PutPixel(xC, yC-1, White);
END;

{------------------------------------------------------------------------}


FUNCTION Num(x, y: Real): Real;
BEGIN
   Num := - (y*y*y - Tension*y + x);
END;

FUNCTION Denom(x, y: Real): Real;
BEGIN
   Denom := Epsilon*(y - x1);
END;

BEGIN
   SetColor(LightRed);
   xCol := 25;
   yRow := 25;
   GetDFieldData;
   xMax := MaxX;
   xMin := MinX;
   yMax := MaxY;
   yMin := MinY;
   SetColor(Yellow);
   DelX := Trunc((MapX(xMax) - MapX(xMin))/xCol);
   DelY := Trunc(Abs(MapY(yMax) - MapY(yMin))/yRow);
   Length := DelX;
   DX := (xMax - xMin)/xCol;
   DY := (yMax - yMin)/yRow;
   DL := DX;
   IF DY < DL THEN DL := DY;
   IF Length > DelY THEN Length := DelY;
   Length := Trunc(Length*0.8);
   HideMouse;
   FOR i := 1 TO xCol DO
   BEGIN
      x := xMin + i*DX;
      FOR j := 1 TO yRow DO
      BEGIN
         y := yMin + j*DY;
         Factor := Sqrt(Num(x,y)*Num(x,y) + Denom(x,y)*Denom(x,y));
         IF Factor > 0.001 THEN
         BEGIN
            xEnd := DL*Denom(x,y)/Factor;
            yEnd := DL*Num(x,y)/Factor;
            Arrow(x, y, xEnd, yEnd, Length);
         END;
         PlotDot(x, y);
      END;
   END;
   ShowMouse;
   SetColor(Yellow);
END;

{------------------------------------------------------------------------}

PROCEDURE SelectMouseStart;
VAR
   Inside: Boolean;
BEGIN
   Message('                      Click on a starting point.');
   WaitOnMouseClick;
   MousePosn(y[2], y[1], 2, 2, Inside);
   Message('');
   HideMouse;
   bStart := y[2];
   xStart := y[1];
   NumberStored := 0;
   h := 0.05;
   Lag := 20;
END;

{------------------------------------------------------------------------}

PROCEDURE SelectKeyStart;
VAR
   Input     : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.3, 0.7, 0.4, 0.6);
      LoadLine('   Enter starting values for');
      LoadLine('     -8 < b = {      } < 8');
      LoadLine( '  -2.9 < x = {      } < 2.9');
      LoadLine('           [  OK  ]');
      SetNumber(1, bStart);
      SetNumberLimits(1, -8, 8);
      SetNumber(2, xStart);
      SetNumberLimits(2, -2.9, 2.9);
      AcceptScreen;
      bStart := GetNumber(1);
      xStart := GetNumber(2);
      y[2] := bStart;
      y[1] := xStart;
      Done;
   END;
   NumberStored := 0;
   h := 0.05;
   Lag := 20;
END;

{-------------------------------------------------------------------------}

PROCEDURE KeyOrMouse;
VAR
   Input      : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.3, 0.7, 0.8, 0.9);
      LoadLine('  Use mouse #1 or keyboard #1');
      LoadLine('        [  OK  ]');
      IF UseMouse THEN SetRadioButton('1', 1)
                  ELSE SetRadioButton('1', 2);
      AcceptScreen;
      IF GetRadioButton('1') = 1 THEN
              UseMouse := True ELSE UseMouse := False;
      Done;
   END;
   IF UseMouse THEN SelectMouseStart ELSE SelectKeyStart;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleContractKeys(Key: Byte);
BEGIN
      CASE Key OF
      1: BEGIN
            Sliding := True;
            HeartBeating := False;
            OpenViewPort(2);
            DrawAxes;
            DrawAttractor;
            Message('Use the left slider for a new tension,'+
                      ' and the right slider for a new systole');
            WITH ContractKeys DO Key[3] := 'F3-Solution';
            ContractKeys.BackColor := Blue;
            ContractKeys.Display;
            ShowMouse;
         END;
      2: BEGIN
            Sliding := False;
            IF HeartBeating THEN ShowMouse;
            HeartBeating := False;
            Message('');
            WITH ContractKeys DO Key[3] := 'F3-Solution';
            ContractKeys.BackColor := Blue;
            ContractKeys.Display;
            DrawDirectionField;

         END;
      3: BEGIN
            Sliding := False;
            Message('');
            IF NOT HeartBeating THEN
            BEGIN
               HeartBeating := True;
               WITH ContractKeys DO Key[3] := 'F3-Stop';
               ContractKeys.BackColor := Red;
               ContractKeys.Display;
               KeyOrMouse;
            END
            ELSE
            BEGIN
               HeartBeating := False;
               ShowMouse;
               WITH ContractKeys DO Key[3] := 'F3-Solution';
               ContractKeys.BackColor := Blue;
               ContractKeys.Display;
            END;
         END;
      4: BEGIN
            HeartBeating := False;
            Sliding := False;
            Message('');
            {ShowMouse;}
            WITH ContractKeys DO Key[3] := 'F3-Solution';
            ContractKeys.BackColor := Blue;
            ContractKeys.Display;
            OpenViewPort(2);
            DrawAxes;
            DrawAttractor;
            ShowMouse;
         END;
      5: BEGIN
            Sliding := False;
            Contraction := False;
            LightMenu := True;
            ClearMuppetPort;
            ZeemanMenu.Display;
            ClearMKBuffers;
         END;
   END;
END;     

{--------------------End of procedures for contraction-------------------}

PROCEDURE HandleZeemanMenu;
BEGIN
   With ZeemanMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpGono.Hlp', 'HeartBeatAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpGono.Hlp', 'HeartBeatAboutModelA');
                  ShowHelp('HelpGono.Hlp', 'HeartBeatAboutModelB');
               END;
            2: ShowHelp('HelpGono.Hlp', 'HeartBeatContraction');
            3: BEGIN
                  ShowHelp('HelpGono.Hlp', 'HeartBeatCyclesA');
                  ShowHelp('HelpGono.Hlp', 'HeartBeatCyclesB');
               END;
            4: BEGIN
                  ShowHelp('WalkThru.hlp', 'HeartBeat1');
                  ShowHelp('WalkThru.hlp', 'HeartBeat2');
                  ShowHelp('WalkThru.hlp', 'HeartBeat3');
                  ShowHelp('WalkThru.hlp', 'HeartBeat4');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  Contraction := True;
                  CompleteCycles := False;
                  HeartBeating := False;
                  LightMenu := False;
                  SetUpContraction;
               END;
            2: BEGIN
                  CompleteCycles := True;
                  Contraction := False;
                  EKG := False;
                  LightMenu := False;
                  NewInput;
               END;
            3: BEGIN
                  CompleteCycles := True;
                  Contraction := False;
                  LightMenu := False;
                  EKG := True;
                  NewInput;
                 { IF NOT Inputting THEN
                  BEGIN
                     EKG := True;
                     StartHeartBeat;
                     SetUpEKG;
                  END;}
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE TestForCycleEvents;
BEGIN
   IF (HeartBeating) AND (NOT Sliding) THEN
   BEGIN
      HeartBeatStep;
      IF EKG THEN TakeEKGStep;
   END;
   IF Sliding THEN
   BEGIN
      IF Inputting THEN
      BEGIN
         IF TensionSlider.Changed THEN
         BEGIN
            Tension := TensionSlider.Value(1);
            ReDrawAttractor;
         END;
      END
      ELSE
      BEGIN
         IF TensionSlider.Changed THEN
         BEGIN
            Tension := TensionSlider.Value(1);
            Sliding := False;
            Message('');
            DrawAxes;
            StartHeartBeat;
            IF EKG THEN SetUpEKG;
            HeartBeating := True;
            HideMouse;
         END;
      END;
   END;
   IF (Inputting) AND (InputHotKeys.Pressed(Key)) THEN
            HandleInputHotKeys(Key);
   IF ((HeartBeating) AND (NOT FirstBeat)) THEN
   BEGIN
      IF EKG THEN
      BEGIN
         IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      END
      ELSE
      BEGIN
         IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE TestForContractEvents;
BEGIN
   IF (HeartBeating) AND (NOT Sliding) THEN HeartBeatStep;
   IF Sliding THEN
   BEGIN
      IF Sliders.Changed THEN
      BEGIN
         Tension := Sliders.Value(1);
         b1 := Sliders.Value(2);
         FindSystole;
         ReDrawAttractor;
      END;
   END;
   IF ContractKeys.Pressed(Key) THEN HandleContractKeys(Key);
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   ExitRequest := False;
   HeartBeating := False;
   Contraction := False;
   Sliding := False;
   LightMenu := True;
   Inputting := False;
   EKG := False;
   Epsilon := 0.1;
   Tension := 2;
   x0 := 2;
   x1 := -1.75;
   b1 := 2;
   b0 := -2;
   MinX := - 4;
   MaxX := 4;
   MinY := -3;
   MaxY := 3;
   MaxTime := 100;
   UseMouse := True;
   bStart := 0;
   xStart := 0;
   DefineViewPort(1, 0.1, 1, 0.07, 0.93);
   DefineViewPort(2, 0.11, 0.88, 0.07, 0.93);
   DefineViewPort(3, 0.1, 0.54, 0.07, 0.93);
   DefineViewPort(4, 0.56, 1, 0.07, 0.93);
   SetUpHotKeys;
   SetUpContractKeys;
   SetUpInputHotKeys;
   Hello('HelpGono.Hlp', 'HeartBeatAboutProgram');
   SetUpZeemanMenu;
   Lag := 20;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Sliders.Init;
   TensionSlider.Init;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF (NOT Contraction) AND CompleteCycles THEN TestForCycleEvents;
      IF Contraction THEN TestForContractEvents;
      IF LightMenu THEN
         IF ZeemanMenu.Chosen THEN HandleZeemanMenu;
   UNTIL ExitRequest;
   CUPSDone;
   ZeemanMenu.Done;
   Sliders.Done;
   TensionSlider.Done;
END.




