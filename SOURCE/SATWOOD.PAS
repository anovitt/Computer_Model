PROGRAM SwingingAtwoodMachine;


USES Crt, Graph, CUPSMupp, CUPS, Cupsgui;

CONST
   neq = 4;

TYPE
   vector = array[1..4] of real;

VAR
   AtwoodMenu       : TMenu;
   HotKeys          : THotKeys;
   PHotKeys         : THotKeys;
   Buttons          : TButtons;
   Image            : TImage;
   Sliders          : TSliders;
   Envir            : TEnvironment;
   Key              : Byte;
   M1, M2, Mu       : Real;
   Length           : Real;
   Gravity          : Real;
   Time             : Real;
   StepSize         : Real;
   InitialLength    : Real;
   ThetaDeg         : Real;
   ThetaDotDeg      : Real;
   ScaleFactor      : Real;
   MaxLength        : Real;
   MaxR             : Real;
   Energy           : Real;
   Y1Start, Y2Start : Real;
   Y3Sign           : Integer;
   Lag              : Integer;
   y                : Vector;
   Poincare         : Boolean;
   ExitRequest      : Boolean;
   Action           : Boolean;
   Pause            : Boolean;
   LightMenu        : Boolean;
   PlotGraph        : Boolean;
   SelectColor      : Boolean;
   SeeAnimation     : Boolean;
   KeyInitialConditions : Boolean;

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

FUNCTION Input  : Boolean;
VAR
   AtwoodData       : TInputScreen;
BEGIN
   WITH AtwoodData DO
   BEGIN
       Init;
       DefineInputPort(0.12, 0.85, 0.15, 0.88);
       LoadLine('');
       LoadLine('         Data for the Swinging Atwood Machine');
       LoadLine('');
       LoadLine('      M1 is the hanging mass. M2 is the swinging mass.');
       LoadLine('   Enter the ratio M1/M2:  {       } > 1.1');
       LoadLine('');
       LoadLine('      Enter initial conditions.  Displacement is');
       LoadLine('   measured from the downward vertical. The initial');
       LoadLIne('   rate of change of the pendulum length will be zero.');
       LoadLine('        Pendulum length:   {       } > 0.1 meters');
       LoadLIne('        Displacement:      {       } degrees');
       LoadLine('        Displacement rate: {       } degrees/sec');
       LoadLine('');
       LoadLine('             [  OK  ]              [Cancel]');
       SetNumber(1, Mu);
       SetNumberLimits(1, 1.1, 10000);
       SetNumber(2, InitialLength);
       SetNumberLimits(2, 0.1, 10000);
       SetNumber(3, ThetaDeg);
       SetNumber(4, ThetaDotDeg);
       AcceptScreen;
       Input := NOT Canceled;
       IF Canceled THEN BEGIN Done; Exit; END;
       Mu := GetNumber(1);
       InitialLength := GetNumber(2);
       ThetaDeg := GetNumber(3);
       ThetaDotDeg := GetNumber(4);
       y[1] := InitialLength;
       y[2] := 0;
       y[3] := ThetaDeg*(Pi/180);
       y[4] := ThetaDotDeg*(Pi/180);
       Energy := 0.5*y[1]*y[1]*y[4]*y[4] - y[1]*Cos(y[3]) + Mu*y[1];
       MaxLength := 1.2*Energy/(Mu - 1);
       DefineScale(1, -2*MaxLength, MaxLength, -1.5*MaxLength, MaxLength);
       DefineScale(3, -1.2*MaxLength, 1.2*MaxLength, -MaxLength, MaxLength);
       Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpAtwoodMenu;
VAR
   I      : Integer;
BEGIN
   With AtwoodMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'About Poincare maps');
       row(2,3, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Animate the machine');
       row(3,3, 'See Poincare maps');
       row(3,4, 'Plot path of pendulum');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   AtwoodMenu.Display;
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
   {HotKeys.Display;}
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Mouse';
      Key[4] := 'F4-KeyBoard';
      Key[5] := 'F5-CleanUp';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x : Real; y : Vector; VAR z : Vector);
BEGIN
   z[1] := y[2];
   z[3] := y[4];
   z[2] := (y[1]*y[4]*y[4] + Gravity*(Cos(y[3]) - Mu))/(1 + Mu);
   z[4] := - 2*y[2]*y[4]/y[1] - Gravity*Sin(y[3])/y[1];
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
end;

{-------------------------------------------------------------------------}

PROCEDURE PlotFigure(V : Vector; FigColor : Word);
VAR
   SaveColor                     : Word;
   Radius1, Radius2, Radius3     : Integer;
   {ScaleY     : Vector;
   i                             : Integer;}
BEGIN
   SelectScale(1);
   IF SeeAnimation THEN SelectViewPort(7) ELSE SelectViewPort(1);
   SaveColor := GetColor;
   SetColor(FigColor);
   IF FigColor = GraphBackColor THEN
            SetFillStyle(SolidFill, GraphBackColor) ELSE
            SetFillStyle(SolidFill, Blue);
   Radius1 := MapX(MaxLength/40) - MapX(0); {Wheels}
   Radius2 := Trunc(Radius1*2); {Left weight}
   Radius3 := Trunc(Radius1*1.5); {Right weight}
   PlotLine(-1.3*MaxLength, MaxLength/40, 0, MaxLength/40);
   PlotLine(-1.3*MaxLength-MaxLength/40, 0,
            -1.3*MaxLength-MaxLength/40, - 1.2*MaxLength + V[1]);
   PlotLine(Cos(V[3])*MaxLength/40, Sin(V[3])*MaxLength/40,
            V[1]*Sin(V[3]), - V[1]*Cos(V[3]));
   Circle(MapX(0), MapY(0), Radius1);
   Circle(MapX(-1.3*MaxLength), MapY(0), Radius1);
   IF FigColor = GraphBackColor THEN
            SetColor(GraphBackColor) ELSE
            SetColor(LightGreen);
   FillEllipse(MapX(-1.3*MaxLength)-Radius1, MapY(-1.2*MaxLength + V[1])+Radius2,
               Radius2, Radius2);
   IF FigColor = GraphBackColor THEN
            SetFillStyle(SolidFill, GraphBackColor) ELSE
            SetFillStyle(SolidFill, Red);
   IF FigColor = GraphBackColor THEN
            SetColor(GraphBackColor) ELSE
            SetColor(Yellow);
   FillEllipse(MapX((V[1]+MaxLength*3/80)*Sin(V[3])),
               MapY((-V[1]-MaxLength*3/80)*Cos(V[3])), Radius3, Radius3);
   SetColor(SaveColor);
END;

{------------------------------------------------------------------------}

PROCEDURE PlotPoincarePoint;
VAR
   PStep              : Real;
   Count              : Integer;
   z                  : Vector;
   xPoinc, yPoinc    : Real;
   V                  : Vector;
BEGIN
   V := y;
   Count := 0;
   REPEAT
       Count := Count + 1;
       PStep := - y[3]/y[4];
       Step(Time, PStep, 0.0001, y, Time, PStep, y);
   UNTIL (Count > 5) OR (Abs(y[3]) < 0.0001);
   Y3Sign := - Y3Sign;
   IF SeeAnimation THEN
   BEGIN
      SelectViewPort(7);
      PlotFigure(V, GraphBackColor);
      PlotFigure(y, White);
   END;
   IF SeeAnimation THEN SelectViewPort(6) ELSE SelectViewPort(3);
   SelectScale(6);
   PlotSymbol(y[1], y[2], '.');
END;


{------------------------------------------------------------------------}

PROCEDURE Move;
VAR
   xOld, yOld, xNew, yNew        : Real;
   y3Mod2pi                      : Real;
   V                             : Vector;
BEGIN
   V := y;
   Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);

   IF SeeAnimation THEN
   BEGIN
      Delay(10);
      SelectViewPort(7);
      PlotFigure(V, GraphBackColor);
      PlotFigure(y, White);
   END;
   IF NOT Poincare THEN
   BEGIN
      Delay(Lag);
      IF NOT PlotGraph THEN
      BEGIN
         SelectViewPort(1);
         PlotFigure(V, GraphBackColor);
         PlotFigure(y, White);
      END;
      IF PlotGraph THEN
      BEGIN
         xOld := V[1]*Sin(V[3]);
         yOld := - V[1]*Cos(V[3]);
         xNew := y[1]*Sin(y[3]);
         yNew := - y[1]*Cos(y[3]);
         SelectScale(3);
         PlotLine(xOld, yOld, xNew, yNew);
      END;
      IF y[3] > 2*Pi THEN
      BEGIN
         REPEAT y[3] := y[3] - 2*Pi; UNTIL y[3] < 0;
         y[3] := y[3] + 2*Pi;
      END;
      IF y[3] < -2*Pi THEN
      BEGIN
         REPEAT y[3] := y[3] + 2*Pi; UNTIL y[3] > 0;
         y[3] := y[3] - 2*Pi;
      END;
   END
   ELSE
   BEGIN
      IF y[3] > Pi THEN BEGIN y[3] := y[3] - 2*Pi; Y3Sign := - Y3Sign; END;
      IF y[3] < -Pi THEN BEGIN y[3] := y[3] + 2*Pi; Y3Sign := - Y3Sign; END;
      IF Y3Sign*y[3] < 0 THEN PlotPoincarePoint;
   END;
   IF (y[1]) < 0.01 THEN
   BEGIN
      Action := False;
      IF Poincare THEN Announce('You have collided with the pulley. Try again?');
      Pause := False;
      IF NOT Poincare THEN
      BEGIN
         HotKeys.Clear;
         LightMenu := True;
      END;
      ShowCursor;
   END;
 {  IF Poincare THEN
   BEGIN
      IF y[3] > 2*Pi THEN y[3] := y[3] - 2*Pi;
      IF y[3] < -2*Pi THEN y[3] := y[3] + 2*Pi;
   END; }
END;

{------------------------------------------------------------------------}

PROCEDURE GetKeyInput;
VAR
   Input       : TInputScreen;
   InputOK     : Boolean;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0, 0.3, 0.7, 1);
      LoadLine('Starting values:');
      LoadLine('');
      LoadLine('    r = {       }');
      LoadLine(' rdot = {       }');
      LoadLine('');
      LoadLine('  [  OK  ]  [Cancel]');
      SetNumber(1, Y1Start);
      SetNumber(2, Y2Start);
      REPEAT
         AcceptScreen;
         Y1Start := GetNumber(1);
         Y2Start := GetNumber(2);
         y[1] := Y1Start;
         y[2] := Y2Start;
         IF (2 - 2*(Mu - 1)*y[1] - (1 + Mu)*y[2]*y[2] < 0) OR (y[1] < 0)
         THEN InputOK := False ELSE InputOK := True;
         IF NOT InputOK THEN Announce('Point out of bounds. Try again');
      UNTIL InputOK OR Canceled;
      Done;
   END;
   IF SeeAnimation THEN SelectViewPort(6) ELSE SelectViewPort(3);
   IF SeeAnimation THEN OpenViewPort(7);
   SelectScale(6);
   y[3] := 0;
   y[4] := Sqrt(2 - 2*(Mu - 1)*y[1] - (1 + Mu)*y[2]*y[2])/y[1];
   Energy := 1;{0.5*y[1]*y[1]*y[4]*y[4] - y[1]*Cos(y[3]) + Mu*y[1];}
   MaxLength := 1.2*Energy/(Mu - 1);
   DefineScale(1, -2*MaxLength, MaxLength, -1.5*MaxLength, MaxLength);
   SelectScale(6);
   PlotSymbol(y[1], y[2], '.');
   Y3Sign := 1;
   Action := True;
   Pause := True;
END;

{------------------------------------------------------------------------}

PROCEDURE SelectPoint;
VAR
   a                  : Integer;
   Inside             : Boolean;
   Outside            : Boolean;
   Button             : Integer;
   xm, ym             : Integer;
   RSave, RDotSave    : Real;
BEGIN
   Delay(500);
   Inside := True;
   Button := 0;
   IF SeeAnimation THEN SelectViewPort(6) ELSE SelectViewPort(3);
   SelectScale(6);
   ClearMKBuffers;
   IF KeyInitialConditions THEN GetKeyInput ELSE
   BEGIN
      Message('Click inside the parabola to select a point.');
      REPEAT
         IF SeeAnimation THEN
            MousePosn(y[1], y[2], 6, 6, Inside)
            ELSE
            MousePosn(y[1], y[2], 3, 6, Inside);
         IF Inside AND (y[1] >= 0)
         AND (2 - 2*(Mu - 1)*y[1] - (1 + Mu)*y[2]*y[2] > 0)
         AND (Abs(RSave - (y[1])) + Abs(RDotSave - (y[2])) > 0.01) THEN
         BEGIN
            RubOutXY(0.6, 0.2, 15, GraphBackColor);
            PrintXY(0.6, 0.2, '('+NumStr(y[1], 4, 2)+', '+NumStr(y[2], 4, 2)+')');
            RSave := (y[1]);
            RDotSave := (y[2]);
         END;
         IF (2 - 2*(Mu - 1)*y[1] - (1 + Mu)*y[2]*y[2] < 0) OR (y[1] < 0)
         THEN
         BEGIN
            Outside := True;
            RubOutXY(0.6, 0.2, 15, GraphBackColor);
            Beep;
         END
         ELSE Outside := False;
      UNTIL MouseClicked(a,a) AND (NOT Outside);
      RubOutXY(0.6, 0.2, 15, GraphBackColor);
      IF (2 - 2*(Mu - 1)*y[1] - (1 + Mu)*y[2]*y[2] < 0) THEN Exit;
      y[3] := 0;
      y[4] := Sqrt(2 - 2*(Mu - 1)*y[1] - (1 + Mu)*y[2]*y[2])/y[1];
      {SetColor(Yellow); }
      PlotSymbol(y[1], y[2], '.');
      Y1Start := y[1];
      Y2Start := y[2];
      Energy := 1;{0.5*y[1]*y[1]*y[4]*y[4] - y[1]*Cos(y[3]) + Mu*y[1];}
      MaxLength := 1.2*Energy/(Mu - 1);
      DefineScale(1, -2*MaxLength, MaxLength, -1.5*MaxLength, MaxLength);
      Y3Sign := 1;
      Action := True;
      Pause := True;
      Message('');
      IF SeeAnimation THEN OpenViewPort(7);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE QueryAnimation;
CONST
   RBNames : string = '12345678';
VAR
   Input               : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.3, 0.7);
      LoadLine('');
      LoadLine('     Do you want to see the animation?');
      LoadLine('  It may be more fun, but it slows ');
      LoadLine('  the mapping.');
      LoadLine('         No #1          Yes #1');
      LoadLine('');
      LoadLine('              [  OK  ]');
      IF SeeAnimation THEN SetRadioButton(RBNames[1], 2)
                      ELSE SetRadioButton(RBNames[1], 1);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN SeeAnimation := False
                                        ELSE SeeAnimation := True;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPoincareGraphics;
VAR
   MaxR, MaxRDot            : Real;
   i                        : Integer;
   xOld, yOld, xNew, yNew   : Real;
BEGIN
   ClearMuppetPort;
   GraphBackColor := Black;
   SetColor(White);
   QueryAnimation;
   IF SeeAnimation THEN
   BEGIN
      OpenViewPort(7);
      OpenViewPort(6);
   END
   ELSE OpenViewPort(3);
   MaxR := 1/(Mu - 1);
   MaxRDot := Sqrt(2/(Mu + 1));
   DefineScale(6, -0.1*MaxR, 1.1*MaxR, -1.1*MaxRDot, 1.1*MaxRDot);
   SelectScale(6);
   PlotLine(0, 0, 1.05*MaxR, 0);
   PlotLine(0, -1.05*MaxRDot, 0, 1.05*MaxRDot);
   xOld := MaxR; yOld := 0;
   FOR I := 1 TO 20 DO
   BEGIN
      yNew := I*MaxRDot/20;
      xNew := (2 - (1 + Mu)*yNew*yNew)/(2*(Mu - 1));
      PlotLine(xOld, yOld, xNew, yNew);
      PlotLine(xOld, -yOld, xNew, -yNew);
      xOld := xNew;
      yOld := yNew;
   END;
   HideMouse;
   OutTextXY(MapX(MaxR/3), MapY(MaxRDot), 'Maximum r = '+NumStr(MaxR, 2, 6));
   OutTextXY(MapX(MaxR/3), MapY(MaxRDot)+Trunc(10*GetMaxY/479),
        'Maximum rDot = '+NumStr(MaxRDot, 2, 6));
   OutTextXY(MapX(MaxR*1.05), MapY(-0.05*MaxRDot), 'r');
   OutTextXY(MapX(MaxR*0.05), MapY(MaxRDot*1.05), 'rDot');
   {Y1Start := MaxR/2;
   Y2Start := MaxRDot/4;}
   ShowMouse;
   Message('Select <Mouse> or <Keyboard> to enter a starting value');
   PHotKeys.Display;
   LightMenu := False;
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
      WITH PHotKeys DO Key[2] := 'F2-Run';
      PHotKeys.BackColor := Red;
      PHotKeys.Display;
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
  { SelectViewPort(1);
   SelectScale(1); }
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
   IF SeeAnimation THEN SelectViewPort(6) ELSE SelectViewPort(3);
   SelectScale(1);
   GraphBackColor := Black;
   Message('');
   IF NOT LightMenu THEN SelectPoint;
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

PROCEDURE SetUpGraphics;
VAR
   TickMark    : Real;
BEGIN
   ClearMuppetPort;
   OpenViewPort(1);
   IF PlotGraph THEN
   BEGIN
      IF Trunc(MaxLength) >= 1 THEN TickMark := Trunc(MaxLength)
                               ELSE TickMark := 0.1*Trunc(10*MaxLength);
      SelectScale(3);
      SelectScale(3);
      SetColor(White);
      PrintXY(0.1, 0.9, 'Path of the end of the swinging pendulum');
      SetColor(LightBlue);
      PlotLine(-1.1*MaxLength, 0, 1.1*MaxLength, 0);
      PlotLine(0, -1.05*MaxLength, 0, 1.05*MaxLength);
      PlotLine(-TickMark, 0, -TickMark, 0.05*MaxLength);
      PlotLine(TickMark, 0, TickMark, 0.05*MaxLength);
      PlotLine(0, -TickMark, 0.05*MaxLength, -TickMark);
      PlotLine(0, TickMark, 0.05*MaxLength, TickMark);
      IF TickMark >=1 THEN
      OutTextXY(MapX(TickMark-0.07*MaxLength), MapY(-0.05*MaxLength),
                  NumStr(TickMark, 3,0))
      ELSE
      OutTextXY(MapX(TickMark-0.07*MaxLength), MapY(-0.05*MaxLength),
                  NumStr(TickMark, 2,1));
      SetColor(White);
   END
   ELSE
   BEGIN
    {  Energy := 0.5*y[1]*y[1]*y[4]*y[4] - y[1]*Cos(y[3]) + Mu*y[1];
      MaxLength := 1.2*Energy/(Mu - 1);
      DefineScale(1, -2*MaxLength, MaxLength, -1.5*MaxLength, MaxLength); }
      SelectScale(1);
   END;
   HotKeys.Key[1] := 'F2-Pause';
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
   Time := 0;
   StepSize := 0.1;
   Action := True;
   LightMenu := False;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleAtwoodMenu;
BEGIN
   With AtwoodMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpMisc.hlp', 'AtwoodAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpMisc.hlp', 'AtwoodAboutModelA');
                  ShowHelp('HelpMisc.hlp', 'AtwoodAboutModelB');
               END;
            2: BEGIN
                  ShowHelp('HelpMisc.hlp', 'AtwoodAboutPoincareMapsA');
                  ShowHelp('HelpMisc.hlp', 'AtwoodAboutPoincareMapsB');
                  ShowHelp('HelpMisc.hlp', 'AtwoodAboutPoincareMapsC');
               END;
            3: BEGIN
                  ShowHelp('WalkThru.hlp', 'Atwood1');
                  ShowHelp('WalkThru.hlp', 'Atwood2');
               END;
         END;
      3: CASE RowChosen OF
            1: Input;
            2: BEGIN Poincare := False; PlotGraph := False; SetUpGraphics; END;
            3: BEGIN
                  Poincare := True;
                  PlotGraph := False;
                  SetUpPoincareGraphics;
               END;
            4: BEGIN PlotGraph := True; Poincare := False; SetUpGraphics; END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag : Integer;
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
      2: IF Lag - DelLag >= 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
      3: Lag := Lag + DelLag;
      4: BEGIN
               Action := False;
               Pause := False;
               HotKeys.Clear;
               LightMenu := True;
               ShowCursor;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: BEGIN
            ShowHelp('HelpMisc.hlp', 'AtwoodAboutPoincareMapsA');
            ShowHelp('HelpMisc.hlp', 'AtwoodAboutPoincareMapsB');
            ShowHelp('HelpMisc.hlp', 'AtwoodAboutPoincareMapsC');
         END;
      2: BEGIN
            IF SelectColor THEN Exit;
            IF NOT Action THEN Exit;
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
            KeyInitialConditions := False;
            SetUpButtons;
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
            KeyInitialConditions := True;
            PickAColor;
            SelectPoint;
         END;
      5: BEGIN
            IF SelectColor THEN Exit;
            IF Pause = False THEN
            BEGIN
               Pause := True;
               WITH PHotKeys DO Key[2] := 'F2-Run';
               PHotKeys.BackColor := Red;
            END;
            SetUpPoincareGraphics;
         END;
      6: BEGIN
            IF SelectColor THEN Exit;
            Pause := False;
            Action := False;
            LightMenu := True;
            SeeAnimation := False;
            IF SelectColor THEN DeleteButtons;
            PHotKeys.Clear;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.05, 0.95, 0.07, 0.95);
   DefineScale(1, -1, 8, -4, 2);
   DefineViewPort(2, 0, 0.2, 0.4, 0.6);
   DefineViewPort(3, 0.1, 0.9, 0.1, 0.9);
   DefineScale(3, -5, 5, -5, 5);
   DefineViewPort(4, 0, 1, 0, 1);
   DefineViewPort(5, 0.85, 1, 0.1, 0.9);
   DefineScale(5, 0, 3, -2, 17);
   DefineViewPort(6, 0.2, 1, 0.1, 0.9);
   DefineViewPort(7, 0, 0.2, 0.35, 0.65);
   Gravity := 1;
   M1 := 3;
   M2 := 1;
   Mu := M1/M2;
   InitialLength := 1;
   ThetaDeg := 30;
   ThetaDotDeg := 0;
   y[1] := InitialLength;
   y[2] := 0;
   y[3] := ThetaDeg*(Pi/180);
   y[4] := ThetaDotDeg*(Pi/180);
   Energy := 0.5*y[1]*y[1]*y[4]*y[4] - y[1]*Cos(y[3]) + Mu*y[1];
   MaxLength := 1.2*Energy/(Mu - 1);
   DefineScale(1, -2*MaxLength, MaxLength, -1.5*MaxLength, MaxLength);
   DefineScale(3, -1.2*MaxLength, 1.2*MaxLength, -MaxLength, MaxLength);
   Time := 0;
   StepSize := 0.1;
   Lag := 25;
   ExitRequest := False;
   Action := False;
   Pause := False;
   LightMenu := True;
   SeeAnimation := False;
   Buttons.Init;
   Hello('HelpMisc.hlp', 'AtwoodAboutProgram');
   SetUpAtwoodMenu;
   SetUpHotKeys;
   SetUpPHotKeys;
END;

{-------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   GetSetUp;
   Input;
   REPEAT
      CheckForEvents;
      IF NOT Poincare AND HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Poincare AND PHotKeys.Pressed(Key) THEN HandlePHotKeys(Key);
      IF Action AND (NOT Pause) THEN Move;
      IF SelectColor AND (NOT KeyInitialConditions) THEN HandleButtons;
      IF LightMenu THEN
         IF AtwoodMenu.Chosen THEN HandleAtwoodMenu;
   UNTIL ExitRequest;
   CUPSDone;
   AtwoodMenu.Done;
   Buttons.Done;
END.