PROGRAM TheMotionOfBernoullisBalance;

USES Crt, Graph, CUPSMUPP, CUPS, CupsGui;


CONST
   neq = 6;

TYPE
   vector = Array[1..neq] OF real;

VAR
   BernoulliMenu          : TMenu;
   HotKeys                : THotKeys;
   PlotHotKeys            : THotKeys;
   Button1, Button2       : TButtons;
   Button3                : TButtons;
   y, y0, z               : Vector;
   Beta, Gamma, Mu        : Real;
   BeamMass, BeamLength   : Real;
   PanMass, PanLength     : Real;
   PanWidth               : Real;
   Gravity                : Real;
   Time, StepSize         : Real;
   Theta0, ThetaDot0      : Real;
   Phi0, PhiDot0          : Real;
   Psi0, PsiDot0          : Real;
   ExitRequest            : Boolean;
   LightMenu              : Boolean;
   Action, Pause          : Boolean;
   Select, Check          : Boolean;
   PlotVariable           : Boolean;
   PlotTheta, PlotPhi     : Boolean;
   PlotPsi                : Boolean;
   AnglePlot              : Boolean;
   MaxTime                : Real;
   MaxAngle, MinAngle     : Real;
   MaxAngleRate           : Real;
   MinAngleRate           : Real;
   Lag                    : Integer;
   Key                    : Byte;

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

PROCEDURE SetUpBernoulliMenu;
VAR
   I      : Integer;
BEGIN
   With BernoulliMenu DO
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
       row(3,1, 'Parameters');
       row(3,2, 'Initial conditions');
       row(3,3, 'Swing!');
       row(3,4, 'Plot angles');
       row(3,5, 'Plot angular rates');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   BernoulliMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-NewStart';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPlotHotKeys;
BEGIN
   WITH PlotHotKeys DO
   BEGIN
      PlotHotKeys.Init(4);
      Key[1] := 'F2-Select';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-Rescale';
      Key[4] := 'F10-Menu';
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotBalance(Theta, Phi, Psi : Real; BColor : Word);
VAR
   SaveColor            : Word;
   xA, yA               : Real;
   xRight, yRight       : Real;
   xLeft, yLeft         : Real;
   CPhi, SPhi, CPsi, SPsi : Real;
   Radius                 : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(BColor);
   CPhi := Cos(Phi);
   SPhi := Sin(Phi);
   CPsi := Cos(Psi);
   SPsi := Sin(Psi);
   Radius := Trunc(5*GetMaxX/639);
   xA := 0.5*BeamLength*Cos(Theta);
   yA := 0.5*BeamLength*Sin(Theta);
   xRight := xA + PanLength*SPhi;
   yRight := yA - PanLength*CPhi;
   xLeft := -xA + PanLength*SPsi;
   yLeft := -yA - PanLength*CPsi;
   SetLineStyle(SolidLn, 0, ThickWidth);
   PlotLine(-xA, -yA, xA, yA);
   SetLineStyle(SolidLn, 0, NormWidth);
   IF BColor <> GraphBackColor THEN
   BEGIN
      SetColor(LightBlue);
      SetFillStyle(SolidFill, Green);
   END
   ELSE SetFillStyle(SolidFill, BColor);
   FillEllipse(MapX(0), MapY(0), Radius, Radius);
   SetColor(BColor);
   IF BColor <> GraphBackColor THEN SetColor(Yellow);
   PlotLine(-xA, -yA, xLeft, yLeft);
   PlotLine(xLeft + PanWidth*CPsi, yLeft + PanWidth*SPsi,
            xLeft - PanWidth*CPsi, yLeft - PanWidth*SPsi);
   SetColor(BColor);
   IF BColor <> GraphBackColor THEN SetColor(LightMagenta);
   PlotLine(xA, yA, xRight, yRight);
   PlotLine(xRight + PanWidth*CPhi, yRight + PanWidth*SPhi,
            xRight - PanWidth*CPhi, yRight - PanWidth*SPhi);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
VAR
   Radius           : Integer;
BEGIN
   ClearMuppetPort;
   DefineViewPort(3, 0.6, 0.98, 0.3, 0.7);
   DefineScale(3, -3.5, 3.5, -1.5, 0.5);
   OpenViewPort(3);
   SelectScale(3);
   Radius := Trunc(5*GetMaxX/639);
   SetLineStyle(SolidLn, 0, ThickWidth);
   PlotLine(-2, 0, 2, 0);
   SetLineStyle(SolidLn, 0, NormWidth);
   SetColor(LightBlue);
   SetFillStyle(SolidFill, Green);
   FillEllipse(MapX(0), MapY(0), Radius, Radius);
   SetColor(Yellow);
   PlotLine(-2, 0, -2, -1);
   PlotLine(-2.4, -1, -1.6, -1);
   SetColor(LightMagenta);
   PlotLine(2, 0, 2, -1);
   PlotLine(1.6, -1, 2.4, -1);
   SetLineStyle(DashedLn, 0, NormWidth);
   SetColor(White);
   PlotLine(-2, 0.2, 2, 0.2);
   OutTextXY(MapX(0), MapY(0.4), 'L');
   SetColor(Yellow);
   PlotLine(-2.6, 0, -2.6, -1);
   OutTextXY(MapX(-3), MapY(-0.5), 'H');
   SetColor(LightMagenta);
   PlotLine(2.6, 0, 2.6, -1);
   OutTextXY(MapX(2.8), MapY(-0.5), 'H');
END;

{------------------------------------------------------------------------}

FUNCTION GetParameters : Boolean;
VAR
   Input      : TInputScreen;
BEGIN
   SetUpPicture;
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.02, 0.58, 0.2, 0.8);
      LoadLine('');
      LoadLine('          Parameters for the Balance');
      LoadLine('');
      LoadLine('   Enter the total width of the beam:');
      LoadLine('       1 < L = {       } < 4 ft');
      LoadLine('   Enter the weight of the beam:');
      LoadLine('           1 < {       } < 4 lb');
      LoadLine('   Enter the length of each balance:');
      LoadLine('       1 < H = {       } 2 ft');
      LoadLine('   Enter the weight of each pan:');
      LoadLine('           1 < {       } 5 lb');
      LoadLine('');
      LoadLine('            [  OK  ]        [Cancel]');
      SetNumber(1, BeamLength);
      SetNumberLimits(1, 1, 4);
      SetNumber(2, BeamMass);
      SetNumberLimits(2, 1, 4);
      SetNumber(3, PanLength);
      SetNumberLimits(3, 1, 2);
      SetNumber(4, PanMass);
      SetNumberLimits(4, 1, 5);
      AcceptScreen;
      GetParameters := NOT Canceled;
      IF Canceled THEN BEGIN CloseViewPort(3); Exit; END;
      BeamLength := GetNumber(1);
      BeamMass := GetNumber(2);
      PanLength := GetNumber(3);
      PanMass := GetNumber(4);
      PanWidth := PanLength/5;
      Gamma := 32/PanLength;
      Beta := BeamLength/PanLength;
      Mu := ((BeamMass/PanMass)/3 + 2)*BeamLength/PanLength;
      Done;
   END;
   CloseViewPort(3);
END;

{------------------------------------------------------------------------}

PROCEDURE ShowPicture;
VAR
   Radius        : Integer;
BEGIN
   ClearMuppetPort;
   DefineViewPort(2, 0.2, 0.8, 0.48, 0.98);
   DefineScale(2, -3.5, 4.5, -1.5, 0.5);
   OpenViewPort(2);
   SelectScale(2);
   SetLineStyle(DashedLn, 0, NormWidth);
   SetColor(White);
   PlotLine(-1.4, 0, 1.4, 0);
   PlotLine(-1.8, -0.4, -1.8, -1.4);
   PlotLine(1.8, 0.4, 1.8, -0.6);
   SetLineStyle(SolidLn, 0, ThickWidth);
   PlotLine(-1.8, -0.4, 1.8, 0.4);
   SetLineStyle(SolidLn, 0, NormWidth);
   Radius := Trunc(40*GetMaxX/639);
   Ellipse(MapX(0), MapY(0), 0, 30, Radius, Radius);
   PrintXY(0.52, 0.88, 'Theta');
   SetColor(Yellow);
   PlotLine(-1.8, -0.4, -1.0, -1.3);
   Ellipse(MapX(-1.8), MapY(-0.4), 270, 290, Radius, Radius);
   PrintXY(0.33, 0.6, 'Psi');
   {PlotLine(xLeft + PanWidth*CPsi, yLeft + PanWidth*SPsi,
            xLeft - PanWidth*CPsi, yLeft - PanWidth*SPsi); }
   SetColor(LightMagenta);
   PlotLine(1.8, 0.4, 2.7, -0.5);
   Ellipse(MapX(1.8), MapY(0.4), 270, 290, Radius, Radius);
   PrintXY(0.605, 0.8, 'Phi');
   SetColor(LightBlue);
   SetFillStyle(SolidFill, Green);
   Radius := Trunc(Radius/8);
   FillEllipse(MapX(0), MapY(0), 5, 5);
   {PlotLine(xRight + PanWidth*CPhi, yRight + PanWidth*SPhi,
            xRight - PanWidth*CPhi, yRight - PanWidth*SPhi);}
END;

{------------------------------------------------------------------------}

FUNCTION GetStart : Boolean;
VAR
   Input      : TInputScreen;
   I          : Integer;
BEGIN
   ShowPicture;
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.05, 0.45);
      LoadLine('');
      LoadLIne('             Initial Conditions');
      LoadLIne('     Units are degrees and seconds.');
      LoadLine('');
      LoadLine(' Theta = {       }    ThetaDot = {       }');
      LoadLine('   Phi = {       }      PhiDot = {       }');
      LoadLine('   Psi = {       }      PsiDot = {       }');
      LoadLine('');
      LoadLine('         [  OK  ]           [Cancel]');
      SetNumber(1, Theta0);
      SetNumber(2, ThetaDot0);
      SetNumber(3, Phi0);
      SetNumber(4, PhiDot0);
      SetNumber(5, Psi0);
      SetNumber(6, PsiDot0);
      AcceptScreen;
      GetStart := Not Canceled;
      IF Canceled THEN BEGIN ClearMuppetPort; Exit; END;
      Theta0 := GetNumber(1);
      ThetaDot0 := GetNumber(2);
      Phi0 := GetNumber(3);
      PhiDot0 := GetNumber(4);
      Psi0 := GetNumber(5);
      PsiDot0 := GetNumber(6);
      FOR I := 1 TO 6 DO y[I] := GetNumber(I)*Pi/180;
      FOR I := 1 TO 6 DO y0[I] := GetNumber(I)*Pi/180;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
VAR
   S1, C1, S2, C2, Alpha: Real;
BEGIN
   S1 := Sin(y[1] - y[3]);
   C1 := Cos(y[1] - y[3]);
   S2 := Sin(y[1] - y[5]);
   C2 := Cos(y[1] - y[5]);
   Alpha := Mu - Beta*(S1*S1 + S2*S2);
   z[1] := y[2];
   z[2] := (Beta*(S1*C1 + S2*C2)*y[2]*y[2] -
            Gamma*(S1*Sin(y[3]) - S2*Sin(y[5]))
            -C1*y[4]*y[4] + C2*y[6]*y[6])/Alpha;
   z[3] := y[4];
   z[4] := Beta*S1*z[2] + Beta*C1*y[2]*y[2] - Gamma*Sin(y[3]);
   z[5] := y[6];
   z[6] := -Beta*S2*z[2] - Beta*C2*y[2]*y[2] - Gamma*Sin(y[5]);
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
      temax := tol/100000;
      for n := 1 to neq do
         if temax < te[n] then temax := te[n];
      htemp := h;
      h := 0.9*h*exp(ln(tol/temax)/5);
   until temax < tol; 
   yout := y;
   xout := xtemp + htemp;
   hout := h;
end;

{-------------------------------------------------------------------------}

PROCEDURE OpenBalanceScreen;
VAR
  ScreenSize : Real;
BEGIN
   ClearMuppetPort;
   DefineViewPort(1, 0.1, 0.9, 0.1, 0.9);
   ScreenSize := 1.1*(0.5*BeamLength + PanLength);
   DefineScale(1, -ScreenSize, ScreenSize, -ScreenSize, ScreenSize);
   OpenViewPort(1);
   SelectScale(1);
   SetColor(White);
   PrintXY(0.02, 0.99, 'Initial values:');
   PrintXY(0.05, 0.96, 'Theta = '+NumStr(Theta0, 6,3));
   PrintXY(0.05, 0.93, 'ThetaDot = '+NumStr(ThetaDot0, 6,3));
   PrintXY(0.35, 0.96, 'Phi = '+NumStr(Phi0, 6,3));
   PrintXY(0.35, 0.93, 'PhiDot = '+NumStr(PhiDot0, 6,3));
   PrintXY(0.65, 0.96, 'Psi = '+NumStr(Psi0, 6,3));
   PrintXY(0.65, 0.93, 'PsiDot = '+NumStr(PsiDot0, 6,3));
   PrintXY(0.9, 0.96, 'deg');
   PrintXY(0.9, 0.93, 'deg/sec');
   LightMenu := False;
   Action := True;
   Pause := True;
   Time := 0;
   StepSize := 0.1;
   SetUpHotKeys;
   PlotBalance(y[1], y[3], y[5], White);
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveBalance;
VAR
   ThetaOld, PhiOld, PsiOld   : Real;
BEGIN
   ThetaOld := y[1];
   PhiOld := y[3];
   PsiOld := y[5];
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   PlotBalance(ThetaOld, PhiOld, PsiOld, GraphBackColor);
   PlotBalance(y[1], y[3], y[5], White);
   Delay(Lag);
END;

{-------------------------------------------------------------------------}
{-------------------Procedures for plotting variables---------------------}

FUNCTION Rescale  :  Boolean;
VAR
   ScaleInput    : TInputScreen;
BEGIN
IF ANglePlot THEN
BEGIN
   WITH ScaleInput DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.25, 0.75);
      LoadLine('');
      LoadLine('   Enter the maximum value of the time:');
      LoadLine('        5 <= {      } <= 200');
      LoadLine('   Enter the minimum value of the angle:');
      LoadLine('    -3000 <= {      } -10 deg');
      LoadLine('   Enter the maximum value of the angle:');
      LoadLine('       10 <= {      } <= 3000 deg');
      LoadLine('');
      LoadLine('        [  OK  ]        [Cancel]');
      SetNumber(1, MaxTime);
      SetNumberLimits(1, 5, 200);
      SetNumber(2, MinAngle);
      SetNumberLimits(2, -3000, -10);
      SetNumber(3, MaxAngle);
      SetNumberLimits(3, 10, 3000);
      AcceptScreen;
      ReScale := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         MaxTime := GetNumber(1);
         Minangle := GetNumber(2);
         MaxAngle := GetNumber(3);
      END;
      Done;
   END;
END
ELSE
BEGIN
   WITH ScaleInput DO
   BEGIN
      Init;
      DefineInputPort(0.17, 0.83, 0.28, 0.72);
      LoadLine('');
      LoadLine('   Enter the maximum value of the time:');
      LoadLine('            1 <= {      } <= 200');
      LoadLine('   Enter the minimum value of the anglular rate:');
      LoadLine('        -50000 <= {      } -10 deg');
      LoadLine('   Enter the maximum value of the anglular rate:');
      LoadLine('           10 <= {      } <= 50000 deg');
      LoadLine('');
      LoadLine('             [  OK  ]        [Cancel]');
      SetNumber(1, MaxTime);
      SetNumberLimits(1, 1, 200);
      SetNumber(2, MinAngleRate);
      SetNumberLimits(2, -50000, -10);
      SetNumber(3, MaxAngleRate);
      SetNumberLimits(3, 10, 50000);
      AcceptScreen;
      ReScale := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         MaxTime := GetNumber(1);
         MinAngleRate := GetNumber(2);
         MaxAngleRate := GetNumber(3);
      END;
      Done;
   END;
END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpButtons;
BEGIN
   SetColor(White);
   IF AnglePlot THEN PrintXY(0.0, 0.8, 'Theta')
                ELSE PrintXY(0.0, 0.8, 'Theta-dot');
   Button1.Create(1, 0.02, 0.75, 'y');
   Button1.Create(2, 0.08, 0.75, 'n');
   IF PlotTheta THEN Button1.Number := 1 ELSE Button1.Number := 2;
   SetColor(Yellow);
   IF AnglePlot THEN PrintXY(0.0, 0.6, 'Phi')
                ELSE PrintXY(0.0, 0.6, 'Phi-dot');
   Button2.Create(1, 0.02, 0.55, 'y');
   Button2.Create(2, 0.08, 0.55, 'n');
   IF PlotPhi THEN Button2.Number := 1 ELSE Button2.Number := 2;
   SetColor(LightBlue);
   IF AnglePlot THEN PrintXY(0.0, 0.4, 'Psi')
                ELSE PrintXY(0.0, 0.4, 'Psi-dot');
   Button3.Create(1, 0.02, 0.35, 'y');
   Button3.Create(2, 0.08, 0.35, 'n');
   IF PlotPsi THEN Button3.Number := 1 ELSE Button3.Number := 2;
   Button1.DrawAll;
   Button2.DrawAll;
   Button3.DrawAll;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPlotScreen;
BEGIN
   ClearMuppetPort;
   LightMenu := False;
   PlotHotKeys.Display;
   SetUpButtons;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotAngles;
VAR
   TimeOld, ThetaOld, PhiOld, PsiOld   : Real;
   xTick, yTick                        : Integer;
   I                                   : Integer;
BEGIN
   DefineViewPort(2, 0.18, 0.98, 0.09, 0.94);
   DefineScale(2, 0, MaxTime, MinAngle, MaxAngle);
   IF MaxTime < 100 THEN xTick := 10 ELSE xTick := 100;
   IF (MaxAngle - MinAngle) < 100 THEN yTick := 10 ELSE yTick := 100;
   OpenViewPort(2);
   SelectScale(2);
   SetColor(White);
   PrintXY(0.13, 0.98, 'Degrees');
   Axis(0, 0, 10, 10);
   SetLineStyle(DottedLn, 0, NormWidth);
   SetColor(White);
   I := 0;
   REPEAT
      I := I + 1;
      IF MaxAngle > 360*I THEN PlotLine(0, 360*I, MaxTime, 360*I);
   UNTIL 360*I > MaxAngle;
   I := 0;
   REPEAT
      I := I + 1;
      IF MinAngle < -360*I THEN PlotLine(0, -360*I, MaxTime, -360*I);
   UNTIL -360*I < MaxAngle;
   SetLineStyle(SolidLn, 0, NormWidth);
   TimeOld := 0;
   ThetaOld := Theta0;
   PhiOld := Phi0;
   PsiOld := Psi0;
   FOR I := 1 TO 6 DO y[I] := y0[I];
   Time := 0;
   StepSize := 0.1;
   HideMouse;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF Button1.Number = 1 THEN
      BEGIN
         SetColor(White);
         PlotLine(TimeOld, ThetaOld, Time, y[1]*180/Pi);
         ThetaOld := y[1]*180/Pi;
      END;
      IF Button2.Number = 1 THEN
      BEGIN
         SetColor(Yellow);
         PlotLine(TimeOld, PhiOld, Time, y[3]*180/Pi);
         PhiOld := y[3]*180/Pi;
      END;
      IF Button3.Number = 1 THEN
      BEGIN
         SetColor(LightBlue);
         PlotLine(TimeOld, PsiOld, Time, y[5]*180/Pi);
         PsiOld := y[5]*180/Pi;
      END;
      TimeOld := Time;
   UNTIL (Time > MaxTime) OR KeyPressed;
   ClearMKBuffers;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotAngleRates;
VAR
   TimeOld, ThetaOld, PhiOld, PsiOld   : Real;
   xTick, yTick                        : Integer;
   I                                   : Integer;
BEGIN
   DefineViewPort(2, 0.18, 0.98, 0.09, 0.94);
   DefineScale(2, 0, MaxTime, MinAngleRate, MaxAngleRate);
   IF MaxTime < 100 THEN xTick := 10 ELSE xTick := 100;
   IF (MaxAngle - MinAngle) < 100 THEN yTick := 10 ELSE yTick := 100;
   OpenViewPort(2);
   SelectScale(2);
   SetColor(White);
   PrintXY(0.09, 0.98, 'Degrees/second');
   Axis(0, 0, 10, 10);
   SetColor(White);
   TimeOld := 0;
   ThetaOld := ThetaDot0;
   PhiOld := PhiDot0;
   PsiOld := PsiDot0;
   FOR I := 1 TO 6 DO y[I] := y0[I];
   Time := 0;
   StepSize := 0.1;
   HideMouse;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      IF Button1.Number = 1 THEN
      BEGIN
         SetColor(White);
         PlotLine(TimeOld, ThetaOld, Time, y[2]*180/Pi);
         ThetaOld := y[2]*180/Pi;
      END;
      IF Button2.Number = 1 THEN
      BEGIN
         SetColor(Yellow);
         PlotLine(TimeOld, PhiOld, Time, y[4]*180/Pi);
         PhiOld := y[4]*180/Pi;
      END;
      IF Button3.Number = 1 THEN
      BEGIN
         SetColor(LightBlue);
         PlotLine(TimeOld, PsiOld, Time, y[6]*180/Pi);
         PsiOld := y[6]*180/Pi;
      END;
      TimeOld := Time;
   UNTIL (Time > MaxTime) OR KeyPressed;
   ClearMKBuffers;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE CheckButtons;
BEGIN
   Check := Button1.Changed;
   Check := Button2.Changed;
   Check := Button3.Changed;
   IF Button1.Number = 1 THEN PlotTheta := True ELSE PlotTheta := False;
   IF Button2.Number = 1 THEN PlotPhi := True ELSE PlotPhi := False;
   IF Button3.Number = 1 THEN PlotPsi := True ELSE PlotPsi := False;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleBernoulliMenu;
BEGIN
   With BernoulliMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpMisc.hlp', 'BernoulliAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: BEGIN
            ShowHelp('HelpMisc.hlp', 'BernoulliAboutModelA');
            ShowHelp('HelpMisc.hlp', 'BernoulliAboutModelB');
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF GetParameters THEN
                  BEGIN
                     IF GetStart THEN OpenBalanceScreen
                                 ELSE LightMenu := True;
                  END
                  ELSE LightMenu := True;
               END;
            2: IF GetStart THEN OpenBalanceScreen;
            3: OpenBalanceScreen;
            4: BEGIN
                  AnglePlot := True;
                  Plotvariable := True;
                  SetUpPlotScreen;
                  PlotAngles;
               END;
            5: BEGIN
                  AnglePlot := False;
                  Plotvariable := True;
                  SetUpPlotScreen;
                  PlotAngleRates;
               END;
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
          1: BEGIN
             IF NOT Pause THEN
             BEGIN
                Pause := True;
                WITH HotKeys DO Key[1] := 'F2-Run';
                HotKeys.BackColor := Red;
                HotKeys.Display;
                ShowMouse;
             END
             ELSE
             BEGIN
                Pause := False;
                WITH HotKeys DO Key[1] := 'F2-Pause';
                HotKeys.BackColor := Blue;
                HotKeys.Display;
                HideMouse;
            END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
      3: Lag := Lag + DelLag;
      4: BEGIN
            IF NOT Pause THEN
            BEGIN
               Pause := True;
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
               ShowMouse;
            END;
            IF GetParameters THEN IF GetStart THEN OpenBalanceScreen;
         END;
      5: BEGIN
               Action := False;
               Pause := True;
               HotKeys.Clear;
               ClearMuppetPort;
               LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePlotHotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: Select := True;
      2: BEGIN
            Select := False;
            IF GetParameters THEN
            BEGIN
               IF GetStart THEN
               BEGIN
                  SetUpPlotScreen;
                  IF AnglePlot THEN PlotAngles ELSE PlotAngleRates;
               END;
            END
            ELSE SetUpPlotScreen;
         END;
      3: BEGIN
            Select := False;
            IF Rescale THEN
            BEGIN
               SetUpPlotScreen;
               IF AnglePlot THEN PlotAngles ELSE PlotAngleRates;
            END;
         END;
      4: BEGIN
            Select := False;
            PlotVariable := False;
            PlotHotKeys.Clear;
            ClearMuppetPort;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
VAR
   I       : Integer;
BEGIN
   BeamMass := 1;
   PanMass := 2;
   BeamLength := 2;
   PanLength := 1;
   Theta0 := 0;
   ThetaDot0 := 0;
   Phi0 := 0;
   PhiDot0 := 300;
   Psi0 := 0;
   PsiDot0 := 0;
   FOR I := 1 TO 6 DO y[I] := 0;
   y[4] := PhiDot0*Pi/180;
   Lag := 100;
   PanWidth := PanLength/5;
   Gamma := 32/PanLength;
   Beta := BeamLength/PanLength;
   Mu := ((BeamMass/PanMass)/3 + 2)*BeamLength/PanLength;
   MaxTime := 10;
   MinAngle := -90;
   MaxAngle := 90;
   MinAngleRate := -500;
   MaxAngleRate := 500;
   PlotTheta := True;
   PlotPhi := True;
   PlotPsi := True;
   ExitRequest := False;
   AnglePlot := False;
   LightMenu := True;
   SetUpPlotHotKeys;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Button1.Init;
   Button2.Init;
   Button3.Init;
   GetSetUp;
   Hello('HelpMisc.HLP', 'BernoulliAboutProgram');
   SetUpBernoulliMenu;
   IF GetParameters THEN IF GetStart THEN OpenBalanceScreen;
   REPEAT
      CheckForEvents;
      IF (NOT PlotVariable) AND HotKeys.Pressed(Key)
         THEN HandleHotKeys(Key);
      IF PlotVariable AND PlotHotKeys.Pressed(Key)
         THEN HandlePlotHotKeys(Key);
      IF PlotVariable AND Select THEN CheckButtons;
      IF Action AND (NOT Pause) THEN MoveBalance;
      IF LightMenu AND BernoulliMenu.Chosen THEN HandleBernoulliMenu;
   UNTIL ExitRequest;
   Button1.Done;
   Button2.Done;
   Button3.Done;
   BernoulliMenu.Done;
   CUPSDone;
END.