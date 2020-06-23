Program SpringPendulum;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;

const
   neq = 4;

type
   vector = array[1..neq] of real;

VAR
   PendMenu                              : TMenu;
   HotKeys                               : THotKeys;
   PHotKeys                              : THotKeys;
   Image                                 : TImage;
   Envir                                 : TEnvironment;
   Buttons                               : TButtons;
   FirstPoint                            : Boolean;
   SelectColor                           : Boolean;
   y                                     : Vector;
   Action, Pause                         : Boolean;
   Key                                   : Byte;
   Theta, ThetaPrime                     : Real;
   ThetaIn, ThetaPrimeIn, LengthIn       : Real;
   Grav, SprCon, L0, Length0             : Real;
   Time, StepSize                        : Real;
   Energy                                : Real;
   MinEnergy                             : Real;
   xPoinc, yPoinc                        : Real;
   xLow, yLow, xHigh, yHigh              : Real;
   Y3Sign                                : Real;
   ScaleLength                           : Real;
   MapColor                              : Word;
   SeeAnimation                          : Boolean;
   Poincare                              : Boolean;
   LightMenu                             : Boolean;
   ExitRequest                           : Boolean;
   MouseInput                            : Boolean;
   Lag                                   : Integer;

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

PROCEDURE SetUpPendMenu;
VAR
   I      : Integer;
BEGIN
   With PendMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Poincare maps');
       row(2,3, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Parameters');
       row(3,2, 'Animate');
       row(3,3, 'See Poincare maps');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   {PendMenu.Display; }
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(4);
      Key[1] := 'F2-Pause';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F10-Menu';
   END;
   HotKeys.BackColor := Blue;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(4);
      Key[1] := 'F2-Start';
      Key[2] := 'F3-Input';
      Key[3] := 'F5-CleanUp';
      Key[4] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Red;
   PHotKeys.HotKeyColor := Yellow;
   PHotKeys.Display;
   Pause := True;
END;

{-------------------------------------------------------------------------}

FUNCTION GetPendData : Boolean;
VAR
   PendDat                               : TInputScreen;
BEGIN
   Message('');
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.13, 0.87, 0, 0.93);
      LoadLine('');
      LoadLine('        Data for the Motion of a Spring Pendulum');
      LoadLine('');
      LoadLine('     The pendulum makes an angle Theta with the down-');
      LoadLine('  ward vertical. It should lie between -180 and 180 ');
      LoadLine('  degrees. Its rate of change should lie between ');
      LoadLine('  -200 and 200 degrees/sec.');
      LoadLIne('  Enter initial values: Theta = {       } degrees');
      LoadLine('                   ThetaPrime = {       } degrees/sec');
      LoadLine('');
      LoadLine('     The natural length of the spring is one meter.');
      LoadLine('  Enter its initial length, which should be between');
      LoadLine('  0.5 and 1.5 meters:');
      LoadLine('                        Length = {       } meters');
      LoadLine('  (The initial rate of change of the length is zero.)');
      LoadLine('');
      LoadLine('     Enter the ratio (Spring constant)/(Mass):');
      LoadLIne('  (Between 1 and 100)      k/M = {       } /sec/sec');
      LoadLine('');
      LoadLIne('            [  OK  ]              [Cancel]');
      SetNumber(1, ThetaIn);
      SetNumberLimits(1, -180, 180);
      SetNumber(2, ThetaPrimeIn);
      SetNumberLimits(3, -200, 200);
      SetNumber(3, LengthIn);
      SetNumberLimits(3, 0.5, 1.5);
      SetNumber(4, SprCon);
      SetNumberLimits(4, 1, 100);
      AcceptScreen;
      GetPendData := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
      ThetaIn := GetNumber(1);
      ThetaPrimeIn := GetNumber(2);
      y[3] := (Pi/180)*ThetaIn;
      y[4] := (Pi/180)*ThetaPrimeIn;
      LengthIn := GetNumber(3);
      y[1] := LengthIn;
      y[2] := 0;
      SprCon := GetNumber(4);
      Y3Sign := 1;
      IF y[4] <> 0 THEN IF y[4] < 0 THEN Y3Sign := -1
                   ELSE IF y[3] > 0 THEN Y3Sign := -1;
      MinEnergy := - 2*Grav*L0 - Grav*Grav/SprCon;
      ScaleLength := 3*(1 + grav/SprCon);
      DefineScale(1, -(7/5)*ScaleLength, (7/5)*ScaleLength,
      - ScaleLength, ScaleLength);
      SelectScale(1);
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION EnergyFun : Real;
BEGIN
   EnergyFun := y[2]*y[2] + y[1]*y[1]*y[4]*y[4] - 2*Grav*y[1]*Cos(y[3])
               + SprCon*(y[1] - L0)*(y[1] - L0);
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
BEGIN
   z[1] := y[2];
   z[2] := y[1]*y[4]*y[4] + Grav*Cos(y[3]) - SprCon*(y[1] - L0);
   z[3] := y[4];
   z[4] := - 2*y[2]*y[4]/y[1] - Grav*Sin(y[3])/y[1];
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

{------------------------------------------------------------------------}

PROCEDURE DrawMapScreen;
VAR
   t, dt                             : Real;
   I                                 : Integer;
   xTick, yTick                      : Real;
   A, B, DX                          : Real;
   xOld, yOld, xNew, yNew            : Real;
BEGIN
   HideMouse;
   B := Sqrt(Energy +2*Grav*L0 + Grav*Grav/SprCon);
   A := B/Sqrt(SprCon);
   DX := L0 + Grav/SprCon;
   DefineScale(3, xLow, xHigh, yLow, yHigh);
   OpenViewPort(3);
   SelectScale(3);
   IF xHigh - xLow > 1 THEN xTick := 1 ELSE xTick := 0.1;
   Axis(0, 0, xTick, 1);
   SetColor(White);
   PutLabel(Top, 'length');
   PutLabel(Right, 'length-prime');
   FirstPoint := True;
   Ellipse(MapX(DX), MapY(0), 0, 360, MapX(A) - MapX(0), MapY(0) - MapY(B));
   SetUpPHotKeys;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpMapScreen;
VAR
   DelX, DelY                      : Real;
   A, B, DX                        : Real;
BEGIN
   B := Sqrt(Energy +2*Grav*L0 + Grav*Grav/SprCon);
   A := B/Sqrt(SprCon);
   DX := L0 + Grav/SprCon;
   yHigh := B;
   xHigh := A + DX;
   xLow := -A + Dx;
   DelX := A/10;
   DelY := B/10;
   xHigh := xHigh + DelX;
   yHigh := yHigh + DelY;
   xLow := xLow - DelX;
   yLow := - yHigh;
   DrawMapScreen;
   Message('Select <F3-Input> to start mapping');
END;

{------------------------------------------------------------------------}

PROCEDURE InitializeMap;
VAR
   Inside                       : Boolean;
   SaveX, SaveY                 : Integer;
   a                            : Integer;
   xm, ym                       : Real;
   xm0, ym0                     : Real;
   Test                         : Real;
   SaveColor                    : Word;
   Input                        : TInputScreen;
BEGIN
   SaveColor := GetColor;
   ShowMouse;
   SelectViewPort(3);
   SelectScale(3);
   SetColor(White);
   Delay(500);
   Inside := False;
   SaveX := 0;
   SaveY := 0;
   IF MouseInput THEN
   BEGIN
      PrintXY(0.53, 0.982, 'X = '+NumStr(y[1], 5, 3)+', Y = '
                                +NumStr(y[2], 5, 3));
         Message('Click on a starting point in the window');
         REPEAT
            MousePosn(Xm, Ym, 3, 3, Inside);
            IF Energy - Ym*Ym + 2*Grav*Xm - SprCon*(Xm - L0)*(Xm - L0) < 0
            THEN
            BEGIN
               RubOutXY(0.53, 0.982, 35, Blue);
               Beep;
            END;
            IF Abs(MapX(Xm) - SaveX) + Abs(MapY(Ym) - SaveY) > 5
            THEN
            BEGIN
               RubOutXY(0.53, 0.982, 35, Blue);
               PrintXY(0.53, 0.982, 'X = '+NumStr(Xm, 5, 3)+', Y = '
                                +NumStr(Ym, 5, 3));
               SaveX := MapX(Xm);
               SaveY := MapY(Ym);
            END;
         UNTIL MouseClicked(a, a) AND Inside;
         Message('');
         HideMouse;
      END
      ELSE
      BEGIN
         xm0 := (xHigh + xLow)/2;
         ym0 := (yHigh + yLow)/2;
         WITH Input Do
         BEGIN
            Init;
            DefineInputPort(0.21, 0.79, 0.7, 0.95);
            LoadLine('');
            LoadLine('  Enter starting coordinates for the map.');
            LoadLine('      x = {       }, y = {       }');
            LoadLine('');
            LoadLine('          [  OK  ]       [Cancel]');
            REPEAT
               SetNumber(1, xm0);
               SetNumber(2, ym0);
               AcceptScreen;
               Xm := GetNumber(1);
               Ym := GetNumber(2);
               Test := Energy - Ym*Ym + 2*Grav*Xm
                       - SprCon*(Xm - L0)*(Xm - L0);
               IF (NOT Canceled) AND (Test < 0) THEN
                      Announce('Conditions inconsistent with the energy');
            UNTIL (Test >= 0) OR Canceled;
            Done;
         END;
      END;
         SetColor(SaveColor);
         y[1] := xM;
         y[2] := yM;
         y[3] := 0;
         y[4] := Sqrt(Energy - Ym*Ym + 2*Grav*Xm - SprCon*(Xm - L0)*(Xm - L0))/y[1];
         PlotSymbol(y[1], y[2], '.');
         IF SeeAnimation THEN
         BEGIN
            OpenViewPort(2);
            SelectScale(1);
         END;
         Action := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE QueryEnergy;
CONST
   RBNames : string = '12345678';
VAR
   Input               : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.2, 0.8);
      LoadLine('');
      LoadLine('     Enter a value for the energy:');
      LoadLine(NumStr(MinEnergy, 4, 2)+' < Energy = {       } < 5 ');
      LoadLine('  ');
      LoadLine('     Do you want to see the pendulum?');
      LoadLine('  It may be more fun, but it slows ');
      LoadLine('  the mapping.');
      LoadLine('         Yes #1          No #1');
      LoadLine('     For input, use');
      LoadLine('       mouse #2 or keyboard #2');
      LoadLine('');
      LoadLine('             [  OK  ]');
      SetNumber(1, Energy);
      SetNumberLimits(1, MinEnergy, 5);
      IF SeeAnimation THEN SetRadioButton(RBNames[1], 1)
                      ELSE SetRadioButton(RBNames[1], 2);
      IF MouseInput THEN SetRadioButton(RBNames[2], 1)
                    ELSE SetRadioButton(RBNames[2], 2);
      AcceptScreen;
      Energy := GetNumber(1);
      IF GetRadioButton(RBNames[1]) = 1 THEN SeeAnimation := True
                                        ELSE SeeAnimation := False;
      IF GetRadioButton(RBNames[2]) = 1 THEN MouseInput := True
                                        ELSE MouseInput := False;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetNewMapLimits;
VAR
   MapDat    : TInputScreen;
   i         : Integer;
BEGIN
   WITH MapDat DO
   BEGIN
      Init;
      DefineInputPort(0, 1, 0.9, 0.95);
      LoadLine('Min x = {    } Max x = {    } Min y = {    } Max y = {    } [  OK  ]');
      SetNumber(1, xLow);
      SetNumber(2, xHigh);
      SetNumber(3, yLow);
      SetNumber(4, yHigh);
      REPEAT
         AcceptScreen;
         xLow := GetNumber(1);
         xHigh := GetNumber(2);
         yLow := GetNumber(3);
         yHigh := GetNumber(4);
         IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
           Announce('You have confused upper and lower limits.Try again.');
      UNTIL (xLow < xHigh) AND (yLow < yHigh);
      Done;
   END;
   DrawMapScreen;
END;

{-------------------------------------------------------------------------}

PROCEDURE PickAColor;
VAR
   Input        : TInputScreen;
   ColorChoice  : Word;
   I            : Integer;
   SaveColor    : Word;
BEGIN
    Action := False;
   IF NOT Pause THEN
   BEGIN
      Pause := True;
      WITH HotKeys DO Key[1] := 'F2-Run';
      HotKeys.BackColor := Red;
      HotKeys.Display;
   END;
   Message('     Choose a color for the next set of maps');
   SaveColor := GetColor;
   SelectViewPort(4);
   Envir.Save;
   Envir.Standardize;
   Image.Get(Trunc(0.8*GetMaxX), 0, GetMaxX, GetMaxY);
   Envir.Reset;
   SelectColor := True;
   GraphBackColor := Black;
   OpenViewPort(5);
   SelectScale(5);
   FOR i := 1 TO 15 DO
   BEGIN
      SetColor(i);
      PlotSymbol(2, i+0.5, '*');
   END;
   SetColor(SaveColor);
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.79, 0.91, 0.1, 0.9);
      LoadLine('');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('   #1');
      LoadLine('');
      LoadLine('[  OK  ]');
      SetRadioButton('1', 16-SaveColor);
      AcceptScreen;
      ColorChoice := GetRadioButton('1');
      Done;
   END;
   SetColor(16-ColorChoice);
   MapColor := 16-ColorChoice;
   SelectColor := False;
   ClearMKBuffers;
   CloseViewPort(5);
   Envir.Save;
   Envir.Standardize;
   Image.Put(Trunc(0.8*GetMaxX), 0);
   Envir.Reset;
   Message('');
{   SelectViewPort(1);
   SelectScale(1);}
   InitializeMap;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpButtons;
VAR
   i             : Integer;
   SaveColor     : Word;
BEGIN
   Action := False;
   IF NOT Pause THEN
   BEGIN
      Pause := True;
      WITH PHotKeys DO Key[1] := 'F2-Run';
      PHotKeys.BackColor := Red;
      PHotKeys.Display;
   END;
   Message('     Choose a color for the next set of maps');
   ShowMouse;
   SaveColor := GetColor;
   DefineViewPort(4, 0, 1, 0, 1);
   SelectViewPort(4);
   Envir.Save;
   Envir.Standardize;
   Image.Get(Trunc(0.8*GetMaxX), 0, GetMaxX, GetMaxY);
   Envir.Reset;
   SelectColor := True;
   GraphBackColor := Black;
   OpenViewPort(5);
   SelectScale(5);
   FOR i := 1 TO 15 DO
   BEGIN
      Buttons.Create(i, 0.9, 0.86-0.042*i, '');
      SetColor(i);
      PlotSymbol(2, i, '*');
   END;
   SetColor(SaveColor);
   Buttons.Create(16, 0.9, 0.86-0.042*16, '  OK');
   Buttons.Number := 16 - MapColor;
   Buttons.DrawAll;
END;

{-------------------------------------------------------------------------}

PROCEDURE DeleteButtons;
VAR
   i      : Integer;
BEGIN
   FOR i := 1 TO 16 DO Buttons.Delete(i);
   SelectColor := False;
   ClearMKBuffers;
   CloseViewPort(5);
  { SelectViewPort(4);}
   Envir.Save;
   Envir.Standardize;
   Image.Put(Trunc(0.8*GetMaxX), 0);
   Envir.Reset;
      SelectViewPort(1);
      SelectScale(1);
   Message('');
   IF NOT LightMenu THEN InitializeMap;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleButtons;
BEGIN
   IF (Buttons.Changed)
   THEN
   BEGIN
      IF (Buttons.Number < 16)
      THEN
      BEGIN
         MapColor := 16 - Buttons.Number;
         SetColor(16-Buttons.Number);
         {OutTextXY(10, 5*Buttons.Number, NumStr(Buttons.Number, 2, 0));}
      END
      ELSE BEGIN DeleteButtons; Message(''); END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE DrawSpring(x, y, Angle, Length: Real; SColor : Word);
CONST
   NSegment = 15;
   {SegmentLength = 0.5;}
VAR
   DLength, Displacement: Real;
   CosAngle, SinAngle: Real;
   x1, y1, x2, y2: Real;
   i: Integer;
   SegmentLength: Real;
   SaveColor : Word;

PROCEDURE Rotate(x, y, c, s, xIn, yIn: Real; VAR xOut, yOut: Real);
BEGIN
   xOut := x + c*xIn + s*yIn;
   yOut := y - s*xIn + c*yIn;
END;

BEGIN
   SaveColor := GetColor;
   SetColor(SColor);
   SegmentLength := 2.5*(1 + grav/SprCon)/15;
   CosAngle := Cos(Angle);
   SinAngle := Sin(Angle);
   DLength := Length/NSegment;
   IF DLength > SegmentLength THEN Displacement := 0 ELSE
   Displacement := 0.5*Sqrt(Sqr(SegmentLength) - Sqr(DLength));
   x1 := 0.5*DLength;
   y1 := Displacement;
   Rotate(x, y, CosAngle, SinAngle, x1, y1, x1, y1);
   PlotLine(x, y, x1, y1);
   FOR i := 1 TO NSegment-1 DO
   BEGIN
      x2 := (0.5 + i)*DLength;
      Displacement := - Displacement;
      y2 := Displacement;
      Rotate(x, y, CosAngle, SinAngle, x2, y2, x2, y2);
      PlotLine(x1, y1, x2, y2);
      x1 := x2;
      y1 := y2;
   END;
   x2 := Length;
   y2 := 0;
   Rotate(x, y, CosAngle, SinAngle, x2, y2, x2, y2);
   PlotLine(x1, y1, x2, y2);
   SetColor(SaveColor);
END;


{------------------------------------------------------------------------}

Procedure PlotSpringPendulum(ys : Vector; SColor  : Word);
VAR
   Px1, Py1            : Real;
   xSc, ySc            : Integer;
   SaveColor           : Word;
   R1a, R1b, R2a, R2b  : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(SColor);
   IF Poincare THEN
   BEGIN
      SelectViewPort(2);
      SelectScale(1);
   END
   ELSE
   BEGIN
      SelectViewPort(1);
      SelectScale(1);
   END;
   SetFillStyle(SolidFill, SColor);
   IF SColor <> BLack THEN SetColor(LightBlue);
   DrawSpring(0, 0, -ys[3]+Pi/2, ys[1], SColor);
   Px1 := ys[1]*Sin(ys[3]);
   Py1 := - ys[1]*Cos(ys[3]);
   IF SColor <> BLack THEN SetFillStyle(SolidFill, Yellow);
   IF SColor <> BLack THEN SetColor(LightRed);
   Map(Px1, Py1, xSc, ySc);
   R1a := Trunc(4*GetMaxX/639);
   R1b := Trunc(3*GetMaxY/479);
   R2a := Trunc(12*GetMaxX/639);
   R2b := Trunc(10*GetMaxY/479);
   IF Poincare THEN FillEllipse(xSc, ySc, R1a, R1b)
               ELSE FillEllipse(xSc, ySc, R2a, R2b);
   IF SColor <> BLack THEN SetFillStyle(SolidFill, Green);
   Map(0, 0, xSc, ySc);
   R1a := Trunc(3*GetMaxX/639);
   R1b := Trunc(2*GetMaxY/479);
   R2a := Trunc(6*GetMaxX/639);
   R2b := Trunc(5*GetMaxY/479);
   IF Poincare THEN FillEllipse(xSc, ySc, R1a, R1b)
               ELSE FillEllipse(xSc, ySc, R2a, R2b);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpAnimation;
BEGIN
   ClearMuppetPort;
   IF NOT Poincare THEN SetUpHotKeys;
   Action := True;
   Pause := False;
   LightMenu := False;
   Time := 0;
   StepSize := 0.1;
   IF Poincare THEN SetUpMapScreen;
   IF NOT Poincare THEN OpenViewPort(1)
                   ELSE IF SeeAnimation THEN OpenViewPort(2);
   SelectScale(1);
   IF SeeAnimation THEN HideMouse;
   IF (NOT Poincare) THEN PlotSpringPendulum(y, White);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotPoincarePoint;
VAR
   PStep  : Real;
   Count  : Integer;
BEGIN
   Count := 0;
   REPEAT
       Count := Count + 1;
       PStep := - (y[3])/(y[4]);
       Step(Time, PStep, 0.0001, y, Time, PStep, y);
   UNTIL (Count > 5) OR (Abs(y[3]) < 0.0001);
   Y3Sign := - Y3Sign;
   IF Count > 5 THEN Exit;
   SelectViewPort(3);
   SelectScale(3);
   xPoinc := y[1];
   yPoinc := y[2];
   SetColor(MapColor);
   PlotSymbol(xPoinc, yPoinc, '.');
   SelectViewPort(2);
   SelectScale(1);
END;

{------------------------------------------------------------------------}

PROCEDURE MoveSpringPendulum;
VAR
   ySave   : Vector;
BEGIN
   IF SeeAnimation THEN
   BEGIN
      Delay(Lag);
      ySave := y;
   END;
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF y[3] > Pi THEN y[3] := y[3] - 2*Pi;
   IF y[3] < -Pi THEN y[3] := y[3] + 2*Pi;
   IF y[1] < 0.2*L0 THEN y[2] := ABS(y[2]);
   IF Poincare THEN
   BEGIN
      IF NOT FirstPoint THEN
      BEGIN
         IF Y3Sign*y[3] < 0 THEN PlotPoincarePoint;
      END
      ELSE FirstPoint := False;
   END;
   IF SeeAnimation THEN
   BEGIN
      PlotSpringPendulum(ySave, Black);
      PlotSpringPendulum(y, White);
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag     : Integer;
BEGIN
   DelLag := 10;
      CASE Key OF
          1: BEGIN
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
      2: IF Lag >= DelLag+10 THEN Lag := Lag - DelLag ELSE Lag := 10;
      3: lag := Lag + DelLAg;
      4: BEGIN
               Action := False;
               Pause := False;
               HotKeys.Clear;
               LightMenu := True;
               ShowMouse;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: BEGIN
            IF SelectColor THEN Exit;
            IF NOT Action THEN
            BEGIN
               Announce('Please use <F3-Input> to enter a starting value');
               Exit;
            END;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH PHotKeys DO Key[1] := 'F2-Run';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := False;
               WITH PHotKeys DO Key[1] := 'F2-Stop';
               PHotKeys.BackColor := Blue;
               PHotKeys.Display;
            END;
         END;
      2: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH PHotKeys DO Key[1] := 'F2-Run';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END;
            IF MouseInput THEN SetUpButtons ELSE PickAColor;
         END;
      3: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = True THEN
            BEGIN
               Pause := False;
               WITH PHotKeys DO Key[1] := 'F2-Run';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END;
            SetNewMapLimits;
         END;
      4: BEGIN
            Pause := False;
            Action := False;
            LightMenu := True;
            IF SelectColor THEN DeleteButtons;
            HotKeys.Clear;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePendMenu;
BEGIN
   With PendMenu DO
      CASE ColChosen OF
         1: CASE RowChosen OF
             1: AboutCUPS;
             2: ShowHelp('HelpPend.hlp', 'SprPendAboutProgram');
             3: Configuration;
             4: ExitRequest := True;
          END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpPend.hlp', 'SprPendAboutModelA');
                  ShowHelp('HelpPend.hlp', 'SprPendAboutModelB');
               END;
            2: BEGIN
                  ShowHelp('HelpPend.hlp', 'SprPendPoincareHelpA');
                  ShowHelp('HelpPend.hlp', 'SprPendPoincareHelpB');
                  ShowHelp('HelpPend.hlp', 'SprPendPoincareHelpC');
               END;
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'SprPend1');
                  ShowHelp('WalkThru.hlp', 'SprPend2');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF NOT GetPendData
                  THEN LightMenu := True
                  ELSE
                  BEGIN
                     Poincare := False;
                     SeeAnimation := True;
                     SetUpAnimation;
                  END;
               END;
            2: BEGIN
                  Poincare := False;
                  SeeAnimation := True;
                  SetUpAnimation;
               END;
            3: BEGIN
                  Poincare := True;
                  QueryEnergy;
                  SetUpAnimation;
               END;
         END;
   END;
END;


{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.07, 0.93, 0.08, 0.93);
   DefineViewPort(2, 0, 0.2, 0.36, 0.64);
   DefineScale(2, -2.2, 2.2, -3.5, 3.5);
   DefineViewPort(3, 0.25, 0.85, 0.1, 0.9);
   DefineViewPort(5, 0.85, 1, 0.1, 0.9);
   DefineScale(5, 0, 3, -2, 17);
   GraphBackColor := Black;
   GraphBackColor := Black;
   ThetaIn := 150;
   ThetaPrimeIn := 0;
   LengthIn := 1.1;
   SprCon := 10;
   Lag := 50;
   Grav := 9.81;
   L0 := 1;
   MinEnergy := - 2*Grav*L0 - Grav*Grav/SprCon;
   ScaleLength := 3*(1 + grav/SprCon);
   DefineScale(1, -(7/5)*ScaleLength, (7/5)*ScaleLength,
      - ScaleLength, ScaleLength);
   y[3] := (Pi/180)*ThetaIn;
   y[4] := (Pi/180)*ThetaPrimeIn;
   y[1] := LengthIn;
   y[2] := 0;
   xLow := -1.2;
   yLow := -10;
   xHigh := 1.2;
   yHigh := 10;
   MapColor := White;
   DefineScale(3, xLow, xHigh, yLow, yHigh);
      Y3Sign := 1;
      IF y[4] <> 0 THEN IF y[4] < 0 THEN Y3Sign := -1
                   ELSE IF y[3] > 0 THEN Y3Sign := -1;
   ExitRequest := False;
   LightMenu := False;
   MouseInput := True;
   SelectViewPort(1);
   Hello('HelpPend.hlp', 'SprPendAboutProgram');
   SetUpPendMenu;
END;

{------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Buttons.Init;
   GetSetUp;
   IF NOT GetPendData
   THEN LightMenu := True
   ELSE
   BEGIN
      Poincare := False;
      SeeAnimation := True;
      SetUpAnimation;
   END;
   REPEAT
      CheckForEvents;
      IF (NOT Poincare) AND HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Poincare AND PHotKeys.Pressed(Key) THEN HandlePHotKeys(Key);
      IF SelectColor AND MouseInput THEN HandleButtons;
      IF Action AND (NOT Pause) THEN MoveSpringPendulum;
      IF LightMenu THEN IF PendMenu.Chosen THEN HandlePendMenu;
   UNTIL ExitRequest;
   PendMenu.Done;
   Buttons.Done;
   CUPSDone;
END.

