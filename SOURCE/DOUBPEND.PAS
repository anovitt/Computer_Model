Program Double_pendulum;
{Follows the motion of a double pendulum in two dimensions and
contructs a Poincare map showing the sometimes chaotic behavior
of the system.}

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;

const
   neq = 4;

type
   vector = array[1..neq] of real;

VAR
   PendMenu                   : TMenu;
   HotKeys                    : THotKeys;
   PHotKeys                   : THotKeys;
   Image                      : TImage;
   Envir                      : TEnvironment;
   Buttons                    : TButtons;
   y                          : Vector;
   Action, Pause              : Boolean;
   ExitRequest                : Boolean;
   LightMenu                  : Boolean;
   Poincare                   : Boolean;
   FirstPoint                 : Boolean;
   SelectColor                : Boolean;
   SeeAnimation               : Boolean;
   MouseInput                 : Boolean;
   Time, StepSize             : Real;
   Key                        : Byte;
   Theta, ThetaPrime          : Real;
   Phi, PhiPrime              : Real;
   xPoinc, yPoinc             : Real;
   Energy                     : Real;
   xLow, yLow, xHigh, yHigh   : Real;
   Crooked                    : Integer;
   Lag                        : Integer;
   MapColor                   : Word;

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

PROCEDURE SetUpPendMenu;
VAR
   I     : Integer;
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
       row(3,1, 'Enter initial conditions');
       row(3,2, 'Animate the pendulums');
       row(3,3, 'See Poincare maps');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   PendMenu.Display;
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
      PHotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Input';
      Key[4] := 'F4-CleanUp';
      Key[5] := 'F10-Menu';
   END;
   PHotKeys.BackColor := Red;
   PHotKeys.HotKeyColor := Yellow;
   PHotKeys.Display;
   Pause := True;
END;

{-------------------------------------------------------------------------}

FUNCTION GetPendData : Boolean;
VAR
   PendDat  : TInputScreen;
BEGIN
   WITH PendDat DO
   BEGIN
      Init;
      DefineInputPort(0.13, 0.87, 0.15, 0.85);
      LoadLine('');
      LoadLine('       Data for the Motion of a Double Pendulum');
      LoadLine('');
      LoadLine('    In the model the pendulums have equal lengths, and');
      LoadLine(' the masses are equal.');
      LoadLine('    The upper and lower pendulums make angles Theta');
      LoadLine(' and Phi respectively, with the downward vertical.');
      LoadLine(' Each angle should lie between -180 and 180 degrees.');
      LoadLine(''); 
      LoadLIne(' Enter initial values: Theta = {       } degrees');
      LoadLine('                  ThetaPrime = {       } degrees/sec');
      LoadLine('                         Phi = {       } degrees');
      LoadLIne('                    PhiPrime = {       } degrees/sec');
      LoadLine('');
      LoadLIne('            [  OK  ]              [Cancel]');
      SetNumber(1, Theta);
      SetNumberLimits(1, -180, 180);
      SetNumber(2, ThetaPrime);
      SetNumberLimits(3, -180, 180);
      SetNumber(3, Phi);
      SetNumber(4, PhiPrime);
      AcceptScreen;
      GetPendData := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         Theta := GetNumber(1);
         ThetaPrime := GetNumber(2);
         Phi := GetNumber(3);
         PhiPrime := GetNumber(4);
         y[1] := (Pi/180)*Theta;
         y[2] := (Pi/180)*ThetaPrime;
         y[3] := (Pi/180)*Phi;
         y[4] := (Pi/180)*PhiPrime;
         IF Sin(y[1] - y[3]) > 0 THEN Crooked := 1 ELSE Crooked := -1;
         PendMenu.RowActivate(3, 2, True);
         PendMenu.RowActivate(3, 3, True);
      END;
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION EnergyFun : Real;
BEGIN
   EnergyFun := 0.5*(2*y[2]*y[2] + y[4]*y[4] + 2*y[2]*y[4]*Cos(y[1] - y[3]))
                 - 2*Cos(y[1]) - Cos(y[3]);
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
VAR
   c, s: Real;
BEGIN
   s := sin(y[1] - y[3]);
   c := cos(y[1] - y[3]);
   z[1] := y[2]; z[3] := y[4];
   z[2] := (- y[4]*y[4]*s - 2*sin(y[1])
           - y[2]*y[2]*s*c + sin(y[3])*c)/(2 - c*c);
   z[4] := (2*y[2]*y[2]*s - 2*sin(y[3])
           + y[4]*y[4]*s*c + 2*sin(y[1])*c)/(2 - c*c);
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

Function Atan2(si, co: real): real;
{Finds the angle between 0 and 2*Pi of which
the sine is proportional to si and the cosine is proportional to co.
equivalent to the FORTRAN function.}
VAR
   Pi: real;
begin
   Pi := 3.141592653589793;
   if si < 0 then
      begin
         if co = 0 then Atan2 := 1.5*Pi
         else
            if co > 0 then Atan2 := 2*Pi + ArcTan(si/co)
            else Atan2 := Pi + ArcTan(si/co);
      end
   else
      begin
         if co = 0 then Atan2 := Pi/2
                   else Atan2 := ArcTan(si/co);
         if co < 0 then Atan2 := Pi + ArcTan(si/co);
      end;
end;


{------------------------------------------------------------------------}

PROCEDURE DrawMapScreen;
VAR
   xValue, yValue, xTest             : Real;
   xStart, xEnd, I                   : Integer;
   xTick, yTick                      : Real;

BEGIN
   DefineScale(3, xLow, xHigh, yLow, yHigh);
   OpenViewPort(3);
   SelectScale(3);
   IF xHigh - xLow > 1 THEN xTick := 1 ELSE xTick := 0.1;
   Axis(0, 0, xTick, 1);
   SetColor(White);
   PrintXY(0.71, 0.53, 'Cos(theta)');
   PrintXY(0.27, 0.85, 'theta-dot');
  { OutTextXY(MapX(xHigh)- 80, MapY(0)-15, 'Cos(theta)');
   OutTextXY(MapX(xLow)+50, MapY(yHigh)+10, 'theta-dot');}
   FirstPoint := True;
   xStart := MapX(xLow);
   xEnd := MapX(xHigh);
   I := xStart;
   REPEAT
      xValue := xLow + (xHigh - xLow)*(I - xStart)/(xEnd - xStart);
      xTest := 6*xValue+2*Energy;
      IF xTest > 0 THEN
      BEGIN
         yValue := Sqrt(xTest);
         PutPixel(MapX(xValue), MapY(yValue), LightGray);
         PutPixel(MapX(xValue), MapY(-yValue), LightGray);
      END;
      i := I + 1;
   UNTIL I >= xEnd;
   Action := False;
   SetUpPHotKeys;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpMapScreen;
VAR
   DelX, DelY                      : Real;
BEGIN
   yHigh := Sqrt(2*Energy + 6);
   xHigh := 1;
   IF Energy >= 3 THEN xLow := -1 ELSE xLow := -Energy/3;
  { BEGIN
      xHigh := 1;
      IF -6*Energy + 2 > 0 THEN
         xLow := -1 ELSE xLow := -2/(6*Energy);
   END;
   IF Energy < 0 THEN
   BEGIN
      xLow := -1;
      IF -6*Energy + 2 > 0 THEN
         xHigh := 1 ELSE xHigh := -2/(6*Energy);
   END; }
   DelY := yHigh/10;
   yHigh := yHigh + DelY;
   yLow := - yHigh;
   DrawMapScreen;
   Message('Select <F3-Input> to start mapping');
END;

{------------------------------------------------------------------------}

PROCEDURE PlotStar(xStar, yStar : Real);
VAR
   Sx,Sy   : Integer;
BEGIN
   Map(xStar, yStar, Sx, Sy);
   PutPixel(Sx, Sy-1, MapColor);
   PutPixel(Sx-1, Sy, MapColor);
   PutPixel(Sx, Sy, MapColor);
   PutPixel(Sx+1, Sy, MapColor);
   PutPixel(Sx-1, Sy+1, MapColor);
END;

{------------------------------------------------------------------------}

PROCEDURE InitializeMap;
VAR
   Inside                       : Boolean;
   SaveX, SaveY                 : Integer;
   a                            : Integer;
   xm, ym                       : Real;
   xm0, ym0                     : Real;
   SaveColor                    : Word;
   b, Button                    : Integer;
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
         Message('Click on a starting point in the window');
         REPEAT
            MousePosn(Xm, Ym, 3, 3, Inside);
            MouseGlobalPosn(a, b, Button);
            IF (6*Xm + 2*Energy - Ym*Ym < 0) OR (NOT Inside) THEN
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
         UNTIL (Button <> 0) AND Inside;
         Message('');
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
               IF (NOT Canceled) AND (6*Xm + 2*Energy - Ym*Ym < 0) THEN
                      Announce('Conditions inconsistent with the energy');
            UNTIL (6*Xm + 2*Energy - Ym*Ym >= 0) OR Canceled;
            Done;
         END;
      END;
      IF (6*Xm + 2*Energy - Ym*Ym < 0)  THEN Exit;
         HideMouse;
         SetColor(SaveColor);
         y[1] := ATan2(Sqrt(1 - Xm*Xm), Xm);
         y[3] := y[1];
         y[2] := Ym;
         y[4] :=-y[2] + Sqrt(6*Xm + 2*Energy - Ym*Ym);
         SetColor(MapColor);
         PlotStar(xM, Ym);
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
      LoadLine('    -3 < Energy = {       } <= 10');
      LoadLine('  ');
      LoadLine('     Do you want to see the pendulums?');
      LoadLine('  It may be more fun, but it slows ');
      LoadLine('  the mapping.');
      LoadLine('         Yes #1          No #1');
      LoadLine('     For input, use');
      LoadLine('       mouse #2 or keyboard #2');
      LoadLine('');
      LoadLine('             [  OK  ]');
      SetNumber(1, Energy);
      SetNumberLimits(1, -3, 10);
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
    ShowMouse;
   WITH MapDat DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.8, 1);
      LoadLine('');
      LoadLine('   Min x = {        }   Max x = {        }');
      LoadLine('   Min y = {        }   Max y = {        }');
      LoadLine('                    [  OK  ]');
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
           Announce('You have confused upper and lower limits. Try again.');
      UNTIL (xLow < xHigh) AND (yLow < yHigh);
      Done;
   END;
   HideMouse;
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
         MapColor := 16-Buttons.Number;
         SetColor(16-Buttons.Number);
         {OutTextXY(10, 5*Buttons.Number, NumStr(Buttons.Number, 2, 0));}
      END
      ELSE BEGIN DeleteButtons; Message(''); END;
   END;
END;

{------------------------------------------------------------------------}

Procedure PlotPendulums(yPend : Vector; PColor : Word);
VAR
   Px1, Py1, Px2, Py2        : Real;
   xSc, ySc                  : Integer;
   SaveColor                 : Word;
   R1a, R1b, R2a, R2b        : Integer;
BEGIN
   SaveColor := GetColor;
   SetColor(PColor);
   IF Poincare THEN
   BEGIN
      SelectViewPort(2);
      SelectScale(2);
   END
   ELSE
   BEGIN
      SelectViewPort(1);
      SelectScale(1);
   END;
   IF PColor <> Black THEN SetColor(LightBlue);
   Px1 := Sin(yPend[1]);
   Py1 := - Cos(yPend[1]);
   Px2 := Px1 + Sin(yPend[3]);
   Py2 := Py1 - Cos(yPend[3]);
   PlotLine(0, 0, Px1, Py1);
   PlotLine(Px1, Py1, Px2, Py2);
   IF PColor <> Black THEN SetFillStyle(SolidFill, Magenta)
                      ELSE SetFillStyle(SolidFill, Black);
   IF PColor <> Black THEN SetColor(LightRed);
   Map(Px1, Py1, xSc, ySc);
   R1a := Trunc(3*GetMaxX/639);
   R1b := Trunc(2*GetMaxY/479);
   R2a := Trunc(6*GetMaxX/639);
   R2b := Trunc(5*GetMaxY/479);
   IF Poincare THEN FillEllipse(xSc, ySc, R1a, R1b)
               ELSE FillEllipse(xSc, ySc, R2a, R2b);
   Map(Px2, Py2, xSc, ySc);
   IF Poincare THEN FillEllipse(xSc, ySc, R1a, R1b)
               ELSE FillEllipse(xSc, ySc, R2a, R2b);
   IF PColor <> Black THEN SetFillStyle(SolidFill, Green)
                      ELSE SetFillStyle(SolidFill, Black);
   Map(0, 0, xSc, ySc);
   IF Poincare THEN FillEllipse(xSc, ySc, R1a, R1b)
               ELSE FillEllipse(xSc, ySc, R2a, R2b);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPendulums;
BEGIN
   HideCursor;
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
   {IF SeeAnimation OR (NOT Poincare) THEN PlotPendulums(y, White);}
   IF NOT Poincare THEN PlotPendulums(y, White);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotPoincarePoint;
VAR
   PStep  : Real;
   Count  : Integer;
   ySave : Vector;
BEGIN
   Count := 0;
   ySave := y;
   SetColor(MapColor);
{   REPEAT
       Count := Count + 1;
       PStep := - Sin(y[1] - y[3])/((y[2] - y[4])*Cos(y[1] - y[3]));
       Step(Time, PStep, 0.0001, y, Time, PStep, y);
   UNTIL (Count > 5) OR (Abs(Sin(y[1] - y[3])) < 0.0001); }
 {  IF Cos(y[1] - y[3]) > 0 THEN
   BEGIN }
      REPEAT
          Count := Count + 1;
          IF Abs(y[2] - y[4]) < 0.001 THEN
             BEGIN y := ySave; Exit; END;
          PStep := - (y[1] - y[3])/((y[2] - y[4]));
          IF Abs(PStep) > 0.1 THEN
             BEGIN y := ySave; Exit; END;
          Step(Time, PStep, 0.000001, y, Time, PStep, y);
      UNTIL (Count > 5) OR (Abs((y[1] - y[3])) < 0.00001);
  { END
   ELSE
   BEGIN
      y[3] := y[3] + Pi;
      REPEAT
          Count := Count + 1;
          PStep := - (y[1] - y[3])/((y[2] - y[4]));
          Step(Time, PStep, 0.0001, y, Time, PStep, y);
      UNTIL (Count > 5) OR (Abs((y[1] - y[3])) < 0.0001);
   END; }
   Crooked := - Crooked;
   xPoinc := Cos(y[1]);
   yPoinc := y[2];
   y := ySave;
   IF Count > 5 THEN Exit;
   SelectViewPort(3);
   SetColor(MapColor);
   SelectScale(3);
   IF (y[2] + y[4] > 0) AND (Sin(y[1]) <1) THEN PlotStar(xPoinc, yPoinc);
   SelectViewPort(2);
   SelectScale(2);
END;

{------------------------------------------------------------------------}

PROCEDURE MovePendulums;
VAR
   ySave   : Vector;
BEGIN
   IF SeeAnimation THEN
   BEGIN
      Delay(Lag);
      ySave := y;
   END;
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF y[1] > Pi THEN y[1] := y[1] - 2*Pi;
   IF y[1] < -Pi THEN y[1] := y[1] + 2*Pi;
   IF y[3] > Pi THEN y[3] := y[3] - 2*Pi;
   IF y[3] < -Pi THEN y[3] := y[3] + 2*Pi;
   IF Poincare THEN
   BEGIN
      IF NOT FirstPoint THEN
      BEGIN
         IF Crooked*(y[1] - y[3]) < 0 THEN PlotPoincarePoint;
      END
      ELSE FirstPoint := False;
   END;
   IF SeeAnimation THEN
   BEGIN
      PlotPendulums(ySave, Black);
      PlotPendulums(y, White);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePendMenu;
BEGIN
   With PendMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpPend.hlp', 'DoubPendAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpPend.hlp', 'DoubPendAboutModel');
            2: BEGIN
                  ShowHelp('HelpPend.hlp', 'DoubPendPoincareMapsA');
                  ShowHelp('HelpPend.hlp', 'DoubPendPoincareMapsB');
                  ShowHelp('HelpPend.hlp', 'DoubPendPoincareMapsC');
               END;
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'DoubPend1');
                  ShowHelp('WalkThru.hlp', 'DoubPend2');
               END;
         END;
      3: CASE RowChosen OF
            1: IF NOT GetPendData THEN LightMenu := True;
            2: BEGIN
                  Poincare := False;
                  SeeAnimation := True;
                  SetUpPendulums;
               END;
            3: BEGIN
                  Poincare := True;
                  QueryEnergy;
                  SetUpPendulums;
               END;
         END;
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
               ShowCursor;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandlePHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HelpPend.hlp', 'DoubPendHotKeysHelp');
      2: BEGIN
            IF SelectColor THEN Exit;
            IF NOT Action THEN
            BEGIN
               Announce('Please use <F3-Input> to enter a starting value');
               Exit;
            END;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH PHotKeys DO Key[2] := 'F2-Run';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := False;
               WITH PHotKeys DO Key[2] := 'F2-Stop';
               PHotKeys.BackColor := Blue;
               PHotKeys.Display;
            END;
         END;
      3: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH PHotKeys DO Key[2] := 'F2-Run';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END;
            IF MouseInput THEN SetUpButtons ELSE PickAColor;
         END;
      4: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = True THEN
            BEGIN
               Pause := False;
               WITH PHotKeys DO Key[2] := 'F2-Run';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END;
            SetNewMapLimits;
         END;
      5: BEGIN
            Pause := False;
            Action := False;
            LightMenu := True;
            IF SelectColor THEN DeleteButtons;
            HotKeys.Clear;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.07, 0.93, 0.08, 0.93);
   DefineScale(1, -3, 3, - 2.2, 2.2);
   DefineViewPort(2, 0, 0.2, 0.36, 0.64);
   DefineScale(2, -2.2, 2.2, -3.5, 3.5);
   DefineViewPort(3, 0.25, 0.85, 0.1, 0.9);
   DefineViewPort(5, 0.85, 1, 0.1, 0.9);
   DefineScale(5, 0, 3, -2, 17);
   GraphBackColor := Black;
   Theta := 120;
   ThetaPrime := -60;
   Phi := -100;
   PhiPrime := 50;
   Lag := 50;
   xLow := -1.2;
   yLow := -10;
   xHigh := 1.2;
   yHigh := 10;
   DefineScale(3, xLow, xHigh, yLow, yHigh);
   ExitRequest := False;
   LightMenu := True;
   SeeAnimation := True;
   MouseInput := True;
   Energy := -2;
   MapColor := White;
   Hello('HelpPend.hlp', 'DoubPendAboutProgram');
   SetUpPendMenu;
END;

{------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Buttons.Init;
   GetSetUp;
   IF NOT GetPendData THEN
   BEGIN
      PendMenu.RowActivate(3, 2, False);
      PendMenu.RowActivate(3, 3, False);
   END;
   REPEAT
      CheckForEvents;
      IF (NOT Poincare) AND HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Poincare AND PHotKeys.Pressed(Key) THEN HandlePHotKeys(Key);
      IF SelectColor AND MouseInput THEN HandleButtons;
      IF (Action) AND (NOT Pause) THEN MovePendulums;
      IF LightMenu THEN IF PendMenu.Chosen THEN HAndlePendMenu;
   UNTIL ExitRequest;
   PendMenu.Done;
   Buttons.Done;
   CUPSDone;
END.

