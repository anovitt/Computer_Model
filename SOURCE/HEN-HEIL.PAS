PROGRAM HenonHeilesPoincareMaps;

USES Crt, Graph, CUPSMUPP, CUPS, CupsGui;

CONST
   neq = 4;

TYPE
   vector = Array[1..neq] OF real;

VAR
   HHMenu               : TMenu;
   HotKeys              : THotKeys;
   ThreeDHotKeys        : THotKeys;
   Buttons              : TButtons;
   Image                : TImage;
   Sliders              : TSliders;
   Envir                : TEnvironment;
   y                    : Vector;
   Action, Pause        : Boolean;
   ExitRequest          : Boolean;
   LightMenu            : Boolean;
   Poincare             : Boolean;
   KeyInitialConditions : Boolean;
   SelectColor          : Boolean;
   ThreeDim             : Boolean;
   SetView              : Boolean;
   Time, StepSize       : Real;
   Energy               : Real;
   Key                  : Byte;
   xSign                : Real;
   MinX, MinY           : Real;
   MaxX, MaxY           : Real;
   yStart, vyStart      : Real;
   Theta, ThetaDeg      : Real;
   Phi, PhiDeg          : Real;
   ProjMatrix                   : ARRAY[1..2, 1..3] OF Real;
   PointX, PointY       : Array[1..500] OF Real;
   PPointNumber           : Integer;

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
   SetLineStyle(solidLn, 0,NormWidth);
   ClearMuppetPort;
   envir.Reset;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHHMenu;
VAR
   I    : Integer;
BEGIN
   With HHMenu DO
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
       row(3,1, 'Enter value for the energy');
       row(3,2, 'See Poincare map');
       row(3,3, 'See three-dimensional motion');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   HHMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(4);
      Key[1] := 'F2-Start';
      Key[2] := 'F3-Mouse';
      Key[3] := 'F4-KeyBoard';
      Key[4] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   {HotKeys.Display;}
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpThreeDHotKeys;
BEGIN
   WITH ThreeDHotKeys DO
   BEGIN
      ThreeDHotKeys.Init(4);
      Key[1] := 'F2-Start';
      Key[2] := 'F3-Input';
      Key[3] := 'F4-View';
      Key[4] := 'F10-Menu';
   END;
   ThreeDHotKeys.BackColor := Red;
   ThreeDHotKeys.HotKeyColor := Yellow;
END;

{------------------------------------------------------------------------}

FUNCTION EnergyInput : Boolean;
VAR
   EnergyData        : TInputScreen;
BEGIN
   WITH EnergyData DO
   BEGIN
      Init;
         DefineInputPort(0.16, 0.84, 0.18, 0.8);
         LoadLine('');
         LoadLine('                  Energy Input');
         LoadLine('');
         LoadLine('  The model of Henon and Heiles has the integral:');
         LoadLine('');
         LoadLine('  (x^2 + y^2 + vx^2 + vy^2)/2 + x^2y - y^3/3 = E.');
         LoadLine('');
         LoadLine('  Select a value for E. Then, using the keyboard ');
         LoadLine('  or the mouse, you can select initial conditions');
         LoadLine('  and see Poincare maps.');
         LoadLine('');
         LoadLine('           0 < E = {         } < 1/6.');
         LoadLine('');
         LoadLine('            [  OK  ]          [Cancel]');
         SetNumber(1, Energy);
         SetNumberLimits(1, 0, 1/6);
         AcceptScreen;
         EnergyInput := NOT Canceled;
         IF NOT Canceled THEN Energy := GetNumber(1);
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x : Real; y : Vector; VAR z : Vector);
BEGIN
   z[1] := y[2];
   z[2] := - y[1] - 2*y[1]*y[3];
   z[3] := y[4];
   z[4] := - y[3] - y[1]*y[1] + y[3]*y[3];
END;

{------------------------------------------------------------------------}

PROCEDURE FindScale1;
VAR
   y0, fy0      : Real;

FUNCTION FY(y : Real) : Real;
BEGIN
   FY := 2*Energy - y*y + (2/3)*y*y*y;
END;

BEGIN
   IF Energy > 1/6 THEN Energy := 1/6-0.0001;
   MaxY := 1.1*Sqrt(2*Energy);
   MinY := - MaxY;
   y0 := 0;
   REPEAT
      y0 := y0 + 0.01;
      fy0 := FY(y0);
   UNTIL fy0 < 0;
   MaxX := 1.1*y0;
   y0 := 0;
   REPEAT
      y0 := y0 - 0.01;
      fy0 := FY(y0);
   UNTIL fy0 < 0;
   MinX := 1.1*y0;
   DefineScale(1, MinX, MaxX, Miny, Maxy);
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

{-------------------------------------------------------------------------}

PROCEDURE PlotCross(xc,yc : Real);
VAR
  xp, yp    : Integer;
BEGIN
   Map(xc, yc, xp, yp);
   Line(xp-1, yp, xp+1, yp);
   Line(xp, yp-1, xp, yp+1);
END;
{-------------------------------------------------------------------------}

PROCEDURE PlotDot(xc,yc : Real);
VAR
  xp, yp    : Integer;
BEGIN
   IF PPointNumber < 500 THEN
   BEGIN
      PPointNumber := PPointNumber + 1;
      Pointx[PPointNumber] := xc;
      Pointy[Ppointnumber] := yc;
   END;
   Map(xc, yc, xp, yp);
   Line(xp-1, yp, xp+1, yp);
   Line(xp, yp-1, xp, yp+1);
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptInitialConditions;
VAR
    x1, y1, x2, y2  : integer;
    Inside          : Boolean;
    InitialDat      : TInputScreen;
    ConditionsOK    : Boolean;
    Test            : Real;
    y3Save, y4Save  : Real;
    a               : Integer;
BEGIN
   ShowCursor;
   IF ThreeDim THEN KeyInitialConditions := True;
   IF KeyInitialConditions THEN
   BEGIN
      REPEAT
         WITH InitialDat DO
         BEGIN
            Init;
            DefineInputPort(0.165, 0.835, 0.15, 0.86);
            LoadLine('');
            LoadLine('                Initial conditions.');
            LoadLine('');
            LoadLine('      The four coordinates for the system are');
            LoadLine('   x, y, vx and vy. For the value of the energy');
            LoadLine('   that you have specified, only three of these');
            LoadLine('   need to be specified. We shall take x = 0, ');
            LoadLine('   and enter values for y and vy. These must be');
            LoadLine('   consistent with the value of the energy. If');
            LoadLine('   in doubt, refer to the figure, where the ');
            LoadLine('   boundary of the permitted region is shown.');
            LoadLine('');
            LoadLine('         y = {        }, vy = {        }.');
            LoadLine('');
            LoadLIne('            [  OK  ]           [Cancel]');
            SetNumber(1, yStart);
            SetNumber(2, vyStart);
            AcceptScreen;
            IF Canceled THEN
            BEGIN
               LightMenu := True;
               Exit;
            END
            ELSE
            BEGIN
               y[1] := 0;
               y[3] := GetNumber(1);
               y[4] := GetNumber(2);
               yStart := y[3];
               vyStart := y[4];
            END;
         Done;
         END;
         Test := 2*Energy - y[4]*y[4] - y[3]*y[3] + 2*y[3]*y[3]*y[3]/3;
         IF Test > 0 THEN ConditionsOK := True ELSE ConditionsOK := False;
      UNTIL ConditionsOK;
      y[2] := Sqrt(Test);
      xSign := 1;
      IF NOT ThreeDim THEN PlotCross(y[3], y[4]);
      Pause := True;
      Action := True;
   END
   ELSE
   BEGIN
      Message('Click on a starting point. Click outside the window to quit.');
      REPEAT
         REPEAT
            MousePosn(y[3], y[4], 1, 1, Inside);
            Test := 2*Energy - y[4]*y[4] - y[3]*y[3] + 2*y[3]*y[3]*y[3]/3;
            IF Test < 0 THEN
            BEGIN
               IF (Abs(y3Save - (y[3])) + Abs(y4Save - (y[4])) > 0.01) THEN
               BEGIN
                  RubOutXY(0.75, 0.105, 15, GraphBackColor);
                  y3Save := (y[3]);
                  y4Save := (y[4]);
               END;
            END
            ELSE
            BEGIN
               IF Inside AND
               (Abs(y3Save - (y[3])) + Abs(y4Save - (y[4])) > 0.01) THEN
               BEGIN
                  RubOutXY(0.75, 0.105, 15, GraphBackColor);
                  PrintXY(0.75, 0.105, '('+NumStr(y[3], 4, 2)
                               +', '+NumStr(y[4], 4, 2)+')');
                  y3Save := (y[3]);
                  y4Save := (y[4]);
               END;
            END;
         UNTIL MouseClicked(a,a);
         MousePosn(y[3], y[4], 1, 1, Inside);
         RubOutXY(0.75, 0.105, 15, GraphBackColor);
         {WaitOnMouseClick;
         MousePosn(y[3], y[4], 1, 1, Inside);}
         IF NOT Inside THEN
         BEGIN
            LightMenu := True;
            Message('');
            HotKeys.Clear;
            Exit;
         END;
         Test := 2*Energy - y[4]*y[4] - y[3]*y[3] + 2*y[3]*y[3]*y[3]/3;
         IF Test > 0 THEN ConditionsOK := True ELSE ConditionsOK := False;
         IF NOT ConditionsOK THEN
         BEGIN
            Message('         Click INSIDE the boundary!');
            Beep;
            Delay(500);
            Message('Click on a starting point. Click outside the screen to quit.');
         END;
      UNTIL ConditionsOK;
      yStart := y[3];
      vyStart := y[4];
      y[1] := 0;
      y[2] := Sqrt(Test);
      xSign := 1;
      PlotCross(y[3], y[4]);
      Pause := True;
      Action := True;
      Message('');
   END;
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
   SelectColor := False;
   ClearMKBuffers;
   CloseViewPort(5);
   Envir.Save;
   Envir.Standardize;
   Image.Put(Trunc(0.8*GetMaxX), 0);
   Envir.Reset;
   Message('');
   SelectViewPort(1);
   SelectScale(1);
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
      Buttons.Create(i, 0.9, 0.86-0.042*i, '');
      SetColor(i);
      PlotSymbol(2, i, '*');
   END;
   SetColor(SaveColor);
   Buttons.Create(16, 0.9, 0.86-0.042*16, '  OK');
   Buttons.Number := 16 - GetColor;
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
   IF ThreeDim THEN
   BEGIN
      SelectViewPort(6);
      SelectScale(6);
   END
   ELSE
   BEGIN
      SelectViewPort(1);
      SelectScale(1);
   END;
   GraphBackColor := DarkGray;
   Message('');
   IF NOT LightMenu THEN PromptInitialConditions;
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
         SetColor(16-Buttons.Number);
         {OutTextXY(10, 5*Buttons.Number, NumStr(Buttons.Number, 2, 0));}
      END
      ELSE BEGIN DeleteButtons; Message(''); END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotBoundaryCurve;
VAR
   y0, Fy0   : Real;
   vy0       : Real;
   Dely      : Real;
   xOld, yOld: Real;
   xNew, yNew: Real;
   i         : Integer;
BEGIN
   HideMouse;
   Dely := MaxX/250;
   y0 := 0;
   SetColor(White);
   REPEAT
      Fy0 := 2*Energy - y0*y0 + (2/3)*y0*y0*y0;
      IF Fy0 > 0 THEN
      BEGIN
         Vy0 := Sqrt(Fy0);
         PutPixel(MapX(y0), MapY(vy0), GetColor);
         PutPixel(Mapx(y0), MapY(-vy0), GetColor);
      END;
      y0 := y0 + Dely;
   UNTIL Fy0 < 0;
   y0 := y0 - Dely;
   xOld := y0;
   yOld := Fy0;
   FOR i := 1 TO 20 DO
   BEGIN
      y0 := y0 - Dely;
      xNew := y0;
      yNew := Sqrt(2*Energy - y0*y0 + (2/3)*y0*y0*y0);
      PlotLine(xOld, yOld, xNew, yNew);
      PlotLine(xOld, -yOld, xNew, -yNew);
      xOld := xNew;
      yOld := yNew;
   END;
   y0 := 0;
   REPEAT
      Fy0 := 2*Energy - y0*y0 + (2/3)*y0*y0*y0;
      IF Fy0 > 0 THEN
      BEGIN
         Vy0 := Sqrt(Fy0);
         PutPixel(MapX(y0), MapY(vy0), GetColor);
         PutPixel(Mapx(y0), MapY(-vy0), GetColor);
      END;
      y0 := y0 - Dely;
   UNTIL Fy0 < 0;
   y0 := y0 + Dely;
   xOld := y0;
   yOld := Fy0;
   FOR i := 1 TO 20 DO
   BEGIN
      y0 := y0 + Dely;
      xNew := y0;
      yNew := Sqrt(2*Energy - y0*y0 + (2/3)*y0*y0*y0);
      PlotLine(xOld, yOld, xNew, yNew);
      PlotLine(xOld, -yOld, xNew, -yNew);
      xOld := xNew;
      yOld := yNew;
   END;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpMapScreen;
VAR
   DelX, DelY        : Real;
   TickLocation      : Real;
BEGIN
   HideMouse;
   FindScale1;
   IF MaxX > 0.1 THEN DelX := 0.1 ELSE DelX := 0.01;
   IF MaxX > 0.5 THEN DelX := 0.2;
   IF MaxY > 0.1 THEN DelY := 0.1 ELSE DelY := 0.01;
   GraphBackColor := DarkGray;
   OpenViewPort(1);
   SelectScale(1);
   SetColor(Yellow);
   PlotLine(0.95*MinX, 0, 0.95*MaxX, 0);
   TickLocation := 0;
   REPEAT
      TickLocation := TickLocation + DelX;
      PlotLine(TickLocation, 0, TickLocation, 0.02*MaxY);
      OutTextXY(MapX(TickLocation)-15, MapY(-0.02*MaxY),
                    NumStr(TickLocation, 4, 2));
   UNTIL (TickLocation > MaxX - 2*DelX);
   TickLocation := 0;
   REPEAT
      TickLocation := TickLocation - DelX;
      PlotLine(TickLocation, 0, TickLocation, 0.02*MaxY);
      OutTextXY(MapX(TickLocation)-20, MapY(-0.02*MaxY),
                    NumStr(TickLocation, 4, 2));
   UNTIL (TickLocation < MinX + 2*DelX);
   OutTextXY(MapX(0.96*MaxX), MapY(0.01*MaxY), 'y');
   PlotLine(0, 0.95*Miny, 0, 0.95*MaxY);
   TickLocation := 0;
   REPEAT
      TickLocation := TickLocation + DelY;
      PlotLine(0, TickLocation, 0.02*MaxX, TickLocation);
      OutTextXY(MapX(0)+10, MapY(TickLocation)+3,
                    NumStr(TickLocation, 4, 2));
      PlotLine(0, -TickLocation, 0.02*MaxX, -TickLocation);
      OutTextXY(MapX(0)+10, MapY(-TickLocation)+3,
                    NumStr(-TickLocation, 4, 2));
   UNTIL (TickLocation > MaxY - 2*DelY);
   OutTextXY(MapX(0.02*MaxX), MapY(0.95*MaxY), 'vy');
   PlotBoundaryCurve;
   StepSize := 0.1;
   Time := 0;
   Message('       Select Keyboard or Mouse to pick a starting point');
   HotKeys.Key[1] := 'F2-Start';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   LightMenu := False;
   Action := False;
   ShowMouse;
END;

{------------------------------------------------------------------------}

PROCEDURE View(x, y, z : Real; VAR ViewX, ViewY: Real);
BEGIN
   ViewX := ProjMatrix[1, 1]*x + ProjMatrix[1, 2]*y;
   ViewY := ProjMatrix[2, 1]*x + ProjMatrix[2, 2]*y + ProjMatrix[2, 3]*z;
END;

{------------------------------------------------------------------------}

PROCEDURE FindCrossing;
VAR
   HTemp    : Real;
   Count    : Integer;
   x1, y1   : Real;
BEGIN
   Count := 0;
   REPEAT
      Count := Count + 1;
      hTemp := - y[1]/y[2];
      Step(Time, hTemp, 0.0000001, y, Time, hTemp, y);
   UNTIL (Abs(y[1]) < 0.0001) OR (Count = 5);
   IF ThreeDim THEN
   BEGIN
      View(y[3], y[4], y[1], x1, y1);
      SetColor(White);
      PlotDot(x1, y1);
      {SetColor(LightBlue);}
   END
   ELSE
   PlotCross(y[3], y[4]);
   xSign := - xSign;
END;

{------------------------------------------------------------------------}

PROCEDURE TakeStep;
VAR
   x1, y1, x2, y2    : Real;
   SaveColor         : Word;
BEGIN
   IF ThreeDim THEN Delay(30);
   IF ThreeDim THEN View(y[3], y[4], y[1], x1, y1);
   Step(Time, StepSize, 0.000000001, y, Time, StepSize, y);
   IF xSign*y[1] < 0 THEN FindCrossing;
   IF ThreeDim THEN
   BEGIN
      SaveColor := GetColor;
      View(y[3], y[4], y[1], x2, y2);
      IF xSign > 0 THEN SetColor(Blue) ELSE SetColor(Green);
      PlotLine(x1, y1, x2, y2);
      SetColor(SaveColor);
   END;
END;

{------------------------------------------------------------------------}
{Procdures for seeing three-dimensional projections.}

PROCEDURE SetViewingMatrix;
BEGIN
   ProjMatrix[1, 1] := Sin(Theta);
   ProjMatrix[1, 2] := Cos(Theta);
   ProjMatrix[1, 3] := 0;
   ProjMatrix[2, 1] := - Cos(Theta)*(Cos(Phi));
   ProjMatrix[2, 2] := - Sin(Theta)*(Cos(Phi));
   ProjMatrix[2, 3] := Sin(Phi);
END;

{------------------------------------------------------------------------}


PROCEDURE DrawArrow2(xa, ya, xb, yb : Real; FlukeLength : Integer;
                     ArrowColor : Word; TNB: String);
VAR
   x, y                 : Integer;
   sxa, sya, sxb, syb   : LongInt;
   Delx, Dely           : Integer;
   xSc, ySc             : Integer;
   Length               : Real;
   SaveColor            : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(ArrowColor);
   sxa := MapX(xa);
   sya := MapY(ya);
   sxb := MapX(xb);
   syb := MapY(yb);
   Length := Sqrt(Sqr(sxb - sxa) + Sqr(syb - sya));
   IF Length = 0 THEN Length := 1;
   Line(sxa, sya, sxb, syb);
   x := Trunc(sxb + FlukeLength*(- (sxb - sxa) + (syb - sya))/Length);
   y := Trunc(syb + FlukeLength*(- (syb - sya) - (sxb - sxa))/Length);
   Line(sxb, syb, x, y);
   x := Trunc(sxb + FlukeLength*(- (sxb - sxa) - (syb - sya))/Length);
   y := Trunc(syb + FlukeLength*(- (syb - sya) + (sxb - sxa))/Length);
   Line(sxb, syb, x, y);
   xSc := Trunc(sxb + 10*(sxb - sxa)/Length);
   ySc := Trunc(syb + 10*(syb - sya)/Length);
   OutTextxy(xSc, ySc, TNB);
   SetColor(SaveColor);
END;

{PROCEDURE DrawArrow2(XTail, YTail, XHead, YHead, Ratio: Real;
                     ArrowColor : Word; TNB: String);
VAR
   Length: Real;
   XBarb, YBarb: Real;
   xSc, ySc: Integer;
   SaveColor : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(ArrowColor);
   Length := Sqrt(Sqr(XHead - XTail) + Sqr(YHead - YTail));
   IF Length = 0 THEN Exit;
   PlotLine(XTail, YTail, XHead, YHead);
   XBarb := XHead + Ratio*(-XHead + XTail + 0.5*(YHead - YTail))/Length;
   YBarb := YHead + Ratio*(-YHead + YTail - 0.5*(XHead - XTail))/Length;
   PlotLine(XHead, YHead, XBarb, YBarb);
   XBarb := XHead + Ratio*(-XHead + XTail - 0.5*(YHead - YTail))/Length;
   YBarb := YHead + Ratio*(-YHead + YTail + 0.5*(XHead - XTail))/Length;
   PlotLine(XHead, YHead, XBarb, YBarb);
   Map(XTail + 1.05*(XHead - XTail),  YTail + 1.1*(YHead - YTail), xSc, ySc);
   OutTextxy(xSc, ySc, TNB);
   SetColor(SaveColor);
END;   }

{------------------------------------------------------------------------}

PROCEDURE SetScale;
VAR
  XMax, XMin, YMax, YMin : Real;

PROCEDURE Test(x, y, z : Real);
VAR
   xTest, yTest : Real;
BEGIN
    View(x, y, z, xTest, yTest);
   IF xTest > XMax THEN XMax := xTest;
   IF xTest < XMin THEN XMin := xTest;
   IF yTest > YMax THEN YMax := yTest;
   IF yTest < YMin THEN YMin := yTest;
END;

BEGIN
   XMax := 0; XMin := 0; YMax := 0; YMin := 0;
   Test(MaxX, MaxY, MaxY);
   Test(MaxX, MaxY, MinY);
   Test(MaxX, MinY, MaxY);
   Test(MaxX, MinY, MinY);
   Test(MinX, MaxY, MaxY);
   Test(MinX, MaxY, MinY);
   Test(MinX, MinY, MaxY);
   Test(MinX, MinY, MinY);
   DefineScale(6, XMin - (XMax-XMin)*0.1, XMax + (XMax-XMin)*0.1,
                  YMin - (YMax-YMin)*0.1, YMax + (YMax-YMin)*0.1);
   SelectScale(6);
END;


{------------------------------------------------------------------------}

PROCEDURE DrawBox;
VAR
   x1, y1, x2, y2, x3, y3, x4, y4  : Real;
   x5, y5, x6, y6, x7, y7, x8, y8  : Real;
   SaveColor                       : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(White);
   View(MaxX, MaxY, MaxY, x1, y1);
   View(MinX, MaxY, MaxY, x2, y2);
   View(MinX, MinY, MaxY, x3, y3);
   View(MaxX, MinY, MaxY, x4, y4);
   View(MaxX, MaxY, MinY, x5, y5);
   View(MinX, MaxY, MinY, x6, y6);
   View(MinX, MinY, MinY, x7, y7);
   View(MaxX, MinY, MinY, x8, y8);
   PlotLine(x1, y1, x2, y2);
   PlotLine(x2, y2, x3, y3);
   PlotLine(x3, y3, x4, y4);
   PlotLine(x4, y4, x1, y1);
   PlotLine(x5, y5, x6, y6);
   PlotLine(x6, y6, x7, y7);
   PlotLine(x7, y7, x8, y8);
   PlotLine(x8, y8, x5, y5);
   PlotLine(x1, y1, x5, y5);
   PlotLine(x2, y2, x6, y6);
   PlotLine(x3, y3, x7, y7);
   PlotLine(x4, y4, x8, y8);
   DrawArrow2(x7, y7, x8+0.1*(x8-x7), y8+0.1*(y8-y7), 5, White, 'y');
   DrawArrow2(x7, y7, x6+0.1*(x6-x7), y6+0.1*(y6-y7), 5, White, 'vy');
   DrawArrow2(x7, y7, x3+0.1*(x3-x7), y3+0.1*(y3-y7), 5, White, 'x');
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE DrawAxes;
VAR
   x1, y1, x2, y2    : Real;
   SaveColor         : Word;
BEGIN
   SaveColor := GetColor;
   OpenViewPort(6);
   SelectScale(6);
   View(0, 0, 0, x1, y1);
   View(MaxX, 0, 0, x2, y2);
   DrawArrow2(x1, y1, x2, y2, 10, White, 'y');
   View(0, MaxY, 0, x2, y2);
   DrawArrow2(x1, y1, x2, y2, 10, White, 'vy');
   View(0, 0, MaxY, x2, y2);
   DrawArrow2(x1, y1, x2, y2, 10, White, 'x');
   SetColor(White);
   View(MinX, 0, 0, x2, y2);
   PlotLine(x1, y1, x2, y2);
   View(0, 0, MinY, x2, y2);
   PlotLine(x1, y1, x2, y2);
   View(0, MinY, 0, x2, y2);
   PlotLine(x1, y1, x2, y2);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpThreeD;
BEGIN
   ThreeDim := True;
   ClearMuppetPort;
   GraphBackColor := Black;
   LightMenu := False;
   FindScale1;
   Theta := ThetaDeg*PI/180;
   Phi := PhiDeg*Pi/180;
   SetViewingMatrix;
   SetScale;
   OpenViewPort(7);
   Sliders.create(1, 0, 360,ThetaDeg, 0.71, 0.43, 0.99,0,'0',
                      '360','Theta',false);
   Sliders.create(2, 0, 180, PhiDeg, 0.71, 0.07, 0.4,0,
                     '0','180','Phi',true );
   Sliders.DrawAll;
   SetColor(White);
   DrawBox;
   DrawAxes;
   StepSize := 0.1;
   PromptInitialConditions;
   SetColor(LightBlue);
   Action := True;
   Pause := True;
   ThreeDHotKeys.Key[1] := 'F2-Start';
   ThreeDHotKeys.BackColor := Red;
   ThreeDHotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(key: Byte);
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
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := False;
               WITH HotKeys DO Key[1] := 'F2-Stop';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
         END;
      2: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            KeyInitialConditions := False;
            SetUpButtons;
         END;
      3: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            KeyInitialConditions := True;
            IF NOT ThreeDim THEN
            BEGIN
               PickAColor;
               PromptInitialConditions;
            END;
            IF ThreeDim THEN
            BEGIN
               DrawAxes;
               PromptInitialConditions;
            END;
         END;
      4: BEGIN
            Pause := False;
            LightMenu := True;
            IF SelectColor THEN DeleteButtons;
            HotKeys.Clear;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleThreeDHotKeys(key: Byte);
VAR I :Integer;
BEGIN
   CASE Key OF
      1: BEGIN
            IF SetView OR (NOT Action) THEN Exit;
            SetView := False;
            Message('');
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH ThreeDHotKeys DO Key[1] := 'F2-Run';
               ThreeDHotKeys.BackColor := Red;
               ThreeDHotKeys.Display;
               For I := 1 TO PPointNumber DO PlotDot(Pointx[i], Pointy[i]);
            END
            ELSE
            BEGIN
               Pause := False;
               WITH ThreeDHotKeys DO Key[1] := 'F2-Stop';
               ThreeDHotKeys.BackColor := Blue;
               ThreeDHotKeys.Display;
               PPointNumber := 0;
            END;
         END;
      2: BEGIN
            IF SetView THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH ThreeDHotKeys DO Key[1] := 'F2-Run';
               ThreeDHotKeys.BackColor := Red;
               ThreeDHotKeys.Display;
            END;
            SetView := False;
            Message('');
            KeyInitialConditions := True;
            DrawAxes;
            PromptInitialConditions;
         END;
      3: BEGIN
            IF SetView THEN
            BEGIN
               SetView := False;
               WITH ThreeDHotKeys DO Key[3] := 'F4-View';
               ThreeDHotKeys.Display;
               Message('');
            END
            ELSE
            BEGIN
               SetView := True;
               WITH ThreeDHotKeys DO Key[3] := 'F4-Accept';
               ThreeDHotKeys.Display;
               Message('Use the sliders to set a new direction of viewing. Then press <F4>-Accept');
            END
         END;
      4: BEGIN
            Pause := False;
            Action := False;
            SetView := False;
            LightMenu := True;
            IF SelectColor THEN DeleteButtons;
            ThreeDim := False;
            ClearMuppetPort;
            ThreeDHotKeys.Clear;
         END;
   END;
END;


{------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   ThetaDeg := Sliders.Value(1);
   PhiDeg := Sliders.Value(2);
   Theta := ThetaDeg*Pi/180;
   Phi := PhiDeg*Pi/180;
   SetViewingMatrix;
   SetScale;
   OpenViewPort(7);
   DrawBox;
   DrawAxes;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleHHMenu;

BEGIN
   With HHMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpChaos.hlp', 'AboutHHProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HlpChaos.hlp', 'AboutHHModel');
            2: BEGIN
                  ShowHelp('HlpChaos.hlp', 'AboutPoincareMapsA');
                  ShowHelp('HlpChaos.hlp', 'AboutPoincareMapsB');
               END;
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'Henon-Heiles1');
                  ShowHelp('WalkThru.hlp', 'Henon-Heiles2');
                  ShowHelp('WalkThru.hlp', 'Henon-Heiles3');
               END;
         END;
      3: CASE RowChosen OF
            1: IF EnergyInput THEN SetUpMapScreen;
            2: SetUpMapScreen;
            3: SetUpThreeD;
         END;
    END;
END;

{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.05, 0.95, 0.07, 0.94);
   DefineViewPort(4, 0, 1, 0, 1);
   DefineViewPort(5, 0.85, 1, 0.1, 0.9);
   DefineScale(5, 0, 3, -2, 17);
   DefineViewPort(6, 0, 0.65, 0.07, 0.93);
   DefineViewPort(7, 0.75, 1, 0.07, 0.4);
   DefineViewPort(8, 0.75, 1, 0.6, 0.93);
   SetUpHotKeys;
   SetUpThreeDHotKeys;
   Hello('HlpChaos.hlp', 'AboutHHProgram');
   SetUpHHMenu;
   ExitRequest := False;
   LightMenu :=True;
   KeyInitialConditions := True;
   Pause := True;
   Action := False;
   SetView := False;
   SelectColor := False;
   ThreeDim := False;
   Energy := 0.1;
   yStart := 0;
   vyStart := 0;
   ThetaDeg := 110;
   PhiDeg := 40;
   StepSize := 0.1;
END;


{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Buttons.Init;
   Sliders.Init;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF (NOT ThreeDim) AND (HotKeys.Pressed(Key)) THEN HandleHotKeys(Key);
      IF (ThreeDim) AND (ThreeDHotKeys.Pressed(Key)) THEN
                        HandleThreeDHotKeys(Key);
      IF Action AND (NOT Pause) AND NOT SetView THEN TakeStep;
      IF SelectColor THEN HandleButtons;
      IF SetView AND Sliders.Changed THEN HandleSliders;
      IF LightMenu THEN
        IF HHMenu.Chosen THEN HandleHHMenu;
   UNTIL ExitRequest;
   CUPSDone;
   HHMenu.Done;
   Buttons.Done;
   Sliders.Done;
END.

