PROGRAM PitAndPendulum;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;

CONST
   neq = 2;

TYPE
   vector = array[1..neq] of real;


VAR
   y, z                                   : Vector;
   PendMenu                               : TMenu;
   HotKeys                                : THotKeys;
   Lag                                    : Integer;
   Resistance                             : Real;
   dead, Saved                            : Boolean;
   PlotPend, Action                       : Boolean;
   EscapeLeft                             : Boolean;
   LightMenu                              : Boolean;
   ExitRequest                            : Boolean;
   Key                                    : Byte;
   xSc, ySc                               : Integer;
   Length, LengthRate, Angle, AngleRate   : Real;
   Time, h                                : Real;
   x1Blade, y1Blade, x2Blade, y2Blade     : Real;

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
       row(1,2, 'About the program');
       row(1,1, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'Animate');
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
      Key[1] := 'F2-Run';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

FUNCTION GetPendData  : Boolean;
VAR
   PendDat   : TInputScreen;
BEGIN
   WITH PendDat DO
   BEGIN
      Init;   
      DefineInputPort(0.1, 0.9, 0.1, 0.8);
      LoadLine('');
      LoadLine('             Data for the Pit and the Pendulum');
      LoadLine('');
      LoadLine(' Enter the initial length of the pendulum:');
      LoadLine('      (between 1 and 19 feet)              {       } ft');
      LoadLine('');
      Loadline(' Enter the rate of increase of the length: {       } ft/sec');
      LoadLine('');
      LoadLine(' The resistance is a constant multiplied by the');
      LoadLine(' angular velocity. Enter its value:        {       } lb sec');
      LoadLine('');
      LoadLine(' Enter the initial angular displacement:');
      LoadLine('      (between -180 and 180)               {       } degrees');
      LoadLine(' Enter the initial angular rate of change: {       } deg/sec');
      LoadLine('');
      LoadLine('                [  OK  ]             [Cancel]');
      SetNumber(1, Length);     
      SetNumberLimits(1, 1, 19);
      SetNumber(2, LengthRate);
      SetNumberLimits(2, 0, 100);
      SetNumber(3, Resistance);
      SetNumberLimits(3, 0, 10000);
      SetNumber(4, Angle);
      SetNumberLimits(4, -180, 180);
      SetNumber(5, AngleRate);
      AcceptScreen;
      GetPendData := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
      Length := GetNumber(1);
      LengthRate := GetNumber(2);
      Resistance := GetNumber(3);
      Angle := GetNumber(4);
      AngleRate := GetNumber(5);
      y[1] := (Pi/180)*Angle;
      y[2] := (Pi/180)*AngleRate;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
CONST
   Gravitation = 32;
VAR
   CurrentLength: Real;
BEGIN
   CurrentLength := Length + LengthRate*x;
   z[1] := y[2];
   z[2] := - (Gravitation/CurrentLength)*Sin(y[1])
           - 2*(LengthRate/CurrentLength)*y[2]
           - Resistance*y[2]/CurrentLength;
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

{-------------------------------------------------------------------------}

PROCEDURE PlotPendulum(PendAngle, PendTime : Real; PendColor : Word);
VAR
   SinAngle, CosAngle                            : Real;
   xEnd, yEnd                                    : Real;
   SaveColor                                     : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(PendColor);
   SinAngle := Sin(PendAngle);
   CosAngle := Cos(PendAngle);
   xEnd := (Length + LengthRate*Pendtime)*SinAngle;
   yEnd := 20 - (Length + LengthRate*Pendtime)*CosAngle;
   IF PendColor = GraphBackColor THEN SetColor(GraphBackColor)
                                 ELSE SetColor(White);
   PlotLine(0, 20, xEnd, yEnd);
   x1Blade := xEnd + 0.9*CosAngle; y1Blade := yEnd + 0.9*SinAngle;
   x2Blade := xEnd - 0.9*CosAngle; y2Blade := yEnd - 0.9*SinAngle;
   IF PendColor = GraphBackColor THEN SetColor(GraphBackColor)
                                 ELSE SetColor(LightRed);
   PlotLine(x1Blade, y1Blade, x2Blade, y2Blade);
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotBody(BodyColor: Word);
VAR
   i: Integer;
BEGIN
   SetColor(BodyColor);
   FOR i := 1 TO 8 DO
   BEGIN
      PlotLine(-3, i/40, 2.5, i/40);
      PlotLine(-0, i/20, 3-0.5*(i-8)*(i-8)/64, i/20);
      PlotLine(-3, 0.2+i/20, -2.8, 0.2+i/20);
      IF Dead THEN Delay(100);
   END;
   FOR i := 1 TO 8 DO
   BEGIN
      PlotLine(2+0.3*i*i/64, 0.4+i/20, 3-0.6*i*i/64, 0.4+i/20);
      IF Dead THEN Delay(100);
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE SitUp(BodyColor: Word);
VAR
   i         : Integer;
   Radius    : Integer;
BEGIN
   Radius := MapX(0.5) - MapX(0);
   SetColor(BodyColor);
   SetFillStyle(SolidFill, BodyColor);
   FOR i := 1 TO 8 DO
   BEGIN
      PlotLine(-3, i/50, 0.4, i/50);    {Legs}
      PLotLine(i/20, 0, i/20, 2.2);        {Trunk}
      PlotLine(-3, 0.15+i/20, -2.8, 0.15+i/20);  {Feet}
   END;
   FillEllipse(MapX(0.1), MapY(2.5), Trunc(0.8*Radius), Radius);  {Head}
   PlotLine(0.2, 2, 1, 0);
   PlotLine(0.21, 2, 1.01, 0); {Arm}
END;

{-------------------------------------------------------------------------}

PROCEDURE StandUp(BodyColor: Word; x: Real);
VAR
   i, Radius   : Integer;
BEGIN
   Radius := MapX(0.5) - MapX(0);
   SetColor(BodyColor);
   SetFillStyle(SolidFill, BodyColor);


   FOR i := 1 TO 8 DO
   BEGIN
      PLotLine(x+i/20, 3, x+i/20, 5.5);   {Trunk}
      IF EscapeLeft THEN
      BEGIN
         PlotLine(x+0.4-i/50, 0,  x+0.4-i/50, 3.2);  {Legs}
         PlotLine(x+0.4, i/50, x-0.4, i/50);  {Feet}
      END
      ELSE
      BEGIN
         PlotLine(x+i/50, 0,  x+i/50, 3.2);  {Legs}
         PlotLine(x, i/50, x+0.8, i/50);
      END;
   END;
   IF EscapeLeft THEN
      FillEllipse(MapX(x+0.1), MapY(5.5), Trunc(0.8*Radius), Radius)
                 ELSE
      FillEllipse(MapX(x+0.3), MapY(5.5), Trunc(0.8*Radius), Radius);
END;

{-------------------------------------------------------------------------}

PROCEDURE Run(BodyColor: Word; x: Real);
VAR
   i, Radius: Integer;
BEGIN
   SetColor(BodyColor);
   SetFillStyle(SolidFill, BodyColor);
   Radius := MapX(0.5) - MapX(0);
   IF EscapeLeft THEN
      FillEllipse(MapX(x+0.1), MapY(5.5), Trunc(0.8*Radius), Radius)
                 ELSE
      FillEllipse(MapX(x+0.3), MapY(5.5), Trunc(0.8*Radius), Radius);
   FOR i := 1 TO 8 DO
   BEGIN
      PLotLine(x+i/20, 3, x+i/20, 5.5);   {Trunk}
      {IF EscapeLeft THEN PlotLine(x-i/20, 5, x-i/20, 6)
                    ELSE PlotLine(x+0.4+i/20, 5, x+0.4+i/20, 6);}
   END;
   FOR i := 1 TO 4 DO
   BEGIN
      PlotLine(x+i/30, 5, x+i/30-1, 3);
      PlotLine(x+0.2+i/30, 5, x+0.2+i/30+1, 3);
      PlotLine(x+i/20, 3, x+i/20-1, 0.5);
      PlotLine(x+0.2+i/20, 3, x+0.2+i/20+1, 0.5);
   END;
   IF EscapeLeft THEN
   BEGIN
      PlotLine(x-1, 0.5, x-1.2-0.3, 0.6);
      PlotLine(x+1.2, 0.5, x+1.2-0.3, 0.6);
      PlotLine(x-1, 0.55, x-1.2-0.3, 0.65);
      PlotLine(x+1.2, 0.55, x+1.2-0.3, 0.65);
   END
   ELSE
   BEGIN
      PlotLine(x-0.8, 0.5, x-0.8+0.3, 0.6);
      PlotLine(x+1.4, 0.5, x+1.4+0.3, 0.6);
      PlotLine(x-0.8, 0.55, x-0.8+0.3, 0.65);
      PlotLine(x+1.4, 0.55, x+1.4+0.3, 0.65);
   END
END;



{-------------------------------------------------------------------------}

PROCEDURE Escape;
VAR
   i: Integer;
BEGIN
   Delay(1000);
   PlotBody(Black);
   SitUp(White);
   Delay(1000);
   SitUp(Black);
   EscapeLeft := True;
   StandUp(White, 0);
   Delay(1000);
   StandUp(Black, 0);
   IF Sin(y[1]) > 0 THEN EscapeLeft := True ELSE EscapeLeft := False;
   FOR i := 0 TO 15 DO
   BEGIN
      IF EscapeLeft THEN
      BEGIN
         StandUp(White, -2*i);
         Delay(100);
         StandUp(Black, -2*i);
         Run(White, -2*i-1);
         Delay(100);
         Run(Black, -2*i-1);
      END
      ELSE
      BEGIN
         StandUp(White, 2*i);
         Delay(100);
         StandUp(Black, 2*i);
         Run(White, 2*i+1);
         Delay(100);
         Run(Black, 2*i+1);
      END;
   END;
   Action := False;
   PlotPend := False;
   HotKeys.Clear;
   LightMenu := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE Animate;
BEGIN
   GraphBackColor := Black;
   HideCursor; OpenViewPort(1); ShowCursor;
   DefineScale(1, -28, 28, -1, 40);
   SelectScale(1);
   SetUpHotKeys;
   Time := 0;
   h := 0.1;
   PlotPend := True;
   LightMenu := False;
   Action := False;
   Dead := False;
   Saved := False;
   SetColor(Yellow);
   PlotLine(-28, -0.1, 28, -0.1);
   PlotBody(White);
   PlotPendulum(y[1], Time, White);
END;

{---------------------------------------------------------------------}

PROCEDURE MovePendulum;
VAR
   k            : Integer;
   SaveAngle    : Real;
   SaveTime     : Real;
BEGIN
   Delay(Lag);
   Dead := False;
   Saved := False;
      SaveAngle := y[1];
      SaveTime := Time;
      if y[1] > 2*Pi then y[1] := y[1] - 2*Pi;
      if y[1] < - 2*Pi then y[1] := y[1] + 2*Pi;
      IF h > 0.05 THEN h :=0.05;
      Step(Time, h, 0.0000001, y, Time, h, y);
      PlotPendulum(SaveAngle, SaveTime, GraphBackColor);
      PlotPendulum(y[1], Time, White);
      IF ((Y1Blade < 0) OR (Y2Blade < 0)) AND (Abs(Sin(y[1])) > 0.15)
      {IF ((Length + Time*LengthRate)*Cos(y[1]) > 20) AND (Abs(y[1]) > 0.15)}
                THEN Saved := True
      ELSE
      IF ((Y1Blade < 0.4) OR (Y2Blade < 0.4)) AND (Abs(Sin(y[1])) < 0.14)
      {IF (Length + Time*LengthRate > 19.1) AND (Abs(y[1]) < 0.15)
                                           AND (y[1] > 0)
                THEN Dead := True;
      IF (Length + Time*LengthRate > 19.5) AND (Abs(y[1]) < 0.15)
                                           AND (y[1] < 0) }
                THEN Dead := True;
   IF Saved THEN Escape;
   IF Dead THEN
   BEGIN
      HideMouse;
      sound(1000);
      delay(2000);
      for k := 1 to 200 do
      begin
         sound(1000 - k*5);
         delay(15);
         nosound;
      end;
      nosound;
      PlotBody(LightRed);
      Delay(100);
      SetColor(LightRed);
      FOR k := 1 to 500 DO
      BEGIN
         PlotLine(-3 - k/20, 0.1, -3 - k/20, 0.3);
         PlotLine(3 + k/20, 0.1, 3 + k/20, 0.3);
         Delay(20);
      END;
      Action := False;
      PlotPend := False;
      HotKeys.Clear;
      LightMenu := True;
      ShowMouse;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
   CASE Key OF
      1: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[1] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END
            ELSE
            BEGIN
               Action := True;
               WITH HotKeys DO Key[1] := 'F2-Pause';
               HotKeys.BackColor := Blue;
               HotKeys.Display;
            END;
         END;
      2: IF Lag > DelLag THEN Lag := Lag - DelLag;
      3: Lag := Lag + DelLag;
      4: BEGIN
            Action := False;
            PlotPend := False;
            LightMenu := True;
            HotKeys.Clear;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandlePendMenu;
BEGIN
   With PendMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            2: ShowHelp('HelpPend.hlp', 'PitPendAboutProgram');
            1: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: BEGIN
            ShowHelp('HelpPend.hlp', 'PitPendAboutModel');
         END;
      3: CASE RowChosen OF
            1: IF GetPendData THEN Animate;
            2: Animate;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE StartUp;
VAR
   x1, y1, x2, y2       : Integer;
   Radius               : Integer;
   I                    : Integer;
BEGIN
   SelectScale(2);
   GraphBackColor := Red;
   OpenViewPort(3);
   GraphBackColor := Blue;
   SetColor(Yellow);
   HideCursor;
   OpenViewPort(2);
   SetTextStyle(1,HorizDir,4);
   Map(4, 9, xSc, ySc);
   OutTextxy(xSc, ySc, 'THE PIT');
   Map(4.5, 6, xSc, ySc);
   OutTextxy(xSc, ySc, 'AND');
   Map(2.7, 3, xSc, ySc);
   OutTextxy(xSc, ySc, 'THE PENDULUM');
   Delay(2000);
   {ClearMuppetPort;}
   GraphBackColor := Black;
   OpenViewPort(4);
   SelectScale(2);
   SetColor(White);
   PlotLine(4.5, 0.9, 5.8, 0.9);
   PlotLine(4.5, 0.95, 5.8, 0.95);
   PlotLine(4.5, 1, 5.8, 1);
   PlotLine(4.5, 1.05, 5.8, 1.05);
   PlotLine(4.5, 1.1, 5.8, 1.1);  {Trunk}
   Radius := MapX(5.8) - MapX(5.66);
   FillEllipse(MapX(5.65), MapY(1), Radius, Radius);   {Head}
   PlotLine(4.5, 0.9, 3.5, 0.5);
   PlotLine(4.5, 1.1, 3.5, 1.5);
   PlotLine(5.5, 0.9, 4.8, 0.5);
   Plotline(5.5, 1.1, 4.8, 1.5);
   SetColor(Yellow);
   PlotLine(5, 9, 8, 4);
   SetColor(LightRed);
   PlotLine(8 + 0.2, 4 + 0.5, 8 - 0.2, 4 - 0.5);
   Delay(2000);
   {ClearMuppetPort};
   GraphBackColor := Black;
   OpenViewPort(4);
   SelectScale(2);
   SetColor(Yellow);
   PlotLine(5, 9, 2, 4);
   SetColor(LightRed);
   PlotLine(2 + 0.2, 4 - 0.5, 2 - 0.2, 4 + 0.5);
   SetColor(White);
   PlotLine(4.5, 0.9, 5.8, 0.9);
   PlotLine(4.5, 0.95, 5.8, 0.95);
   SetColor(White);
   PlotLine(4.5, 0.9, 5.8, 0.9);
   PlotLine(4.5, 0.95, 5.8, 0.95);
   PlotLine(4.5, 1, 5.8, 1);
   PlotLine(4.5, 1.05, 5.8, 1.05);
   PlotLine(4.5, 1.1, 5.8, 1.1);
   FillEllipse(MapX(5.65), MapY(1), Radius, Radius);
   PlotLine(5.5, 0.9, 5, 0.5);
   Plotline(5.5, 1.1, 5, 1.5);
   PlotLine(4.5, 0.9, 3.5, 0.5);
   PlotLine(4.5, 1.1, 3.5, 1.5);
   SetColor(LightRed);
   PlotLine(4.5, 1.05, 5.8, 1.05);
   PlotLine(4.5, 1, 5.8, 1);
   PlotLine(4.5, 0.95, 5.8, 0.95);
   FOR I := 1 TO 20 DO
   BEGIN
      Delay(200);
      PlotSymbol(5.8, 1-I/20, '.');
      PlotSymbol(5.4, 1-I/20, '.');
      PlotSymbol(5.0, 1-I/20, '.');
      PlotSymbol(4.5, 1-I/20, '.');
   END;
   ClearMuppetPort;
   SetTextStyle(0,HorizDir,1);
END;

{------------------------------------------------------------------------}

BEGIN {MAIN PROGRAM}
   CUPSInit;
   DefineViewPort(1, 0.05, 0.95, 0.07, 0.95);
   DefineViewPort(2, 0.1, 0.9, 0.4, 0.8);
   DefineViewPort(3, 0.12, 0.92, 0.42, 0.82);
   DefineScale(2, 0, 10, 0, 10);
   DefineViewPort(4, 0.1, 0.9, 0, 0.4);
   StartUp;
   Hello('HelpPend.hlp', 'PitPendAboutProgram');
   Length := 8;
   LengthRate := 0.5;
   Angle := 60;
   AngleRate := 0;
   Resistance := 0.1;
   ExitRequest := False;
   LightMenu := True;
   Lag := 200;
   SetUpPendMenu;
   ShowCursor;
   IF GetPendData THEN Animate;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF Action AND PlotPend THEN MovePendulum;
      IF LightMenu AND PendMenu.Chosen THEN HandlePendMenu;
   UNTIL ExitRequest;
END.

