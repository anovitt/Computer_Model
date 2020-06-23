Program SpreadOfGonorrhea;

Uses Crt, Graph, CupsMUPP, CUPS, CupsGui;


const
   neq = 2;

type
   vector = array[1..neq] of real;

var
   y, z                    : Vector;
   GonoMenu                : TMenu;
   HotKeys                 : THotKeys;
   Sliders                 : TSliders;
   Lag                     : Integer;
   KeyInitialConditions    : Boolean;
   PlotOrbit, Pause        : Boolean;
   ExitRequest             : Boolean;
   LightMenu               : Boolean;
   DField                  : Boolean;
   Key                     : Byte;
   Males, Females          : Real;
   MaleCure, FemaleCure    : Real;
   MaleInfect, FemaleInfect: Real;
   Time, h                 : Real;
   xOld, yOld, xNew, yNew  : Real;
   InitialX, InitialY      : Real;
   xMax, xMin, yMax, yMin  : Real;
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

{-------------------------------------------------------------------------}

PROCEDURE SetUpGonoMenu;
VAR
   I      : Integer;
BEGIN
   With GonoMenu DO
   BEGIN
      Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Running the program');
       row(2,3, 'About direction fields');
      Column(3, 'Run');
       row(3,1, 'Set parameters');
       row(3,2, 'Plot solutions');
       row(3,3, 'See the direction field diagram');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   GonoMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Pause';
      Key[2] := 'F3-Faster';
      Key[3] := 'F4-Slower';
      Key[4] := 'F5-Input';
      Key[5] := 'F6-CleanUp';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
END;

{-------------------------------------------------------------------------}

FUNCTION GetGonoData: Boolean;
VAR
   GonoDat : TInputScreen;
BEGIN
   WITH GonoDat DO
   BEGIN
      Init;
      DefineInputPort(0.1, 0.9, 0.15, 0.85);
      LoadLine('');
      LoadLine('              Data for the Spread of Gonorrhea');
      LoadLine('');
      LoadLine('    The model is');
      LoadLine('                 dx/dt = - ax + by(m - x),');
      LoadLIne('                 dy/dt = - cy + dx(f - y).');
      LoadLine('');
      LoadLine('      The total number of males, m  = {      } 1 < m < 200');
      LoadLine('    The total number of females, f  = {      } 1 < f < 200');
      LoadLine('        The cure rate for males, a1 = {      } 0 < a < 40');
      LoadLine('      The cure rate for females, a2 = {      } 0 < c < 40');
      LoadLine('   The infection rate for males, b1 = {      } 0 < b < 1');
      LoadLIne(' The infection rate for females, b2 = {      } 0 < d < 1');
      LoadLIne('');
      LoadLIne('                   [  OK  ]       [Cancel]');
      SetNumber(1, Males);
      SetNumberLimits(1, 1, 200);
      SetNumber(2, Females);
      SetNumberLimits(2, 1, 200);
      SetNumber(3, MaleCure);
      SetNumberLimits(3, 0, 40);
      SetNumber(4, FemaleCure);
      SetNumberLimits(4, 0, 40);
      SetNumber(5, MaleInfect);
      SetNumberLimits(5, 0, 1);
      SetNumber(6, FemaleInfect);
      SetNumberLimits(6, 0, 1);
      AcceptScreen;
      GetGonoData := NOT Canceled;
      Males := GetNumber(1);
      Females := GetNumber(2);
      MaleCure := GetNumber(3);
      FemaleCure := GetNumber(4);
      MaleInfect := GetNumber(5);
      FemaleInfect := GetNumber(6);
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION UseKey : Boolean;
CONST
   RBNames : string = '12345678';
VAR
  Input    : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.32, 0.68, 0.35, 0.65);
      LoadLine('');
      LoadLine('  Would you like to use');
      LoadLine('       #1 keyboard');
      LoadLine('   or  #1 mouse?');
      LoadLine('');
      LoadLine('        [  OK  ]');
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      UseKey := True ELSE UseKey := False;
      Done;
   END;
END;

{------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
{Right-hand sides of the differential equations.}
begin
   IF y[1] < 0 THEN y[1] := 0;
   IF y[2] < 0 THEN y[2] := 0;
   z[1] := - MaleCure*y[1] + MaleInfect*y[2]*(Males - y[1]);
   z[2] := - FemaleCure*y[2] + FemaleInfect*y[1]*(Females - y[2]);
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

{-------------------------------------------------------------------------}

PROCEDURE PrepareToRunOrbit;

BEGIN
   SelectViewPort(1);
   Time := 0;
   h := 0.1;
   WITH HotKeys DO Key[1] := 'F2-Pause';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   SetColor(Yellow);
   PlotOrbit := True;
   Pause := False;
   LightMenu := False;
   xOld := y[1]; yOld := y[2];
END;

{------------------------------------------------------------------------}

PROCEDURE StepOrbit;
BEGIN
   Delay(Lag);
   Step(Time, h, 0.000001, y, Time, h, y);
   IF y[1] < 0 THEN y[1] := 0;
   IF y[2] < 0 THEN y[2] := 0;
   xNew := y[1]; yNew := y[2];
   PlotLine(xOld, yOld, xNew, yNew);
   xOld := xNew; yOld := yNew;
   RubOutXY(0.4, 0.105, 20, GraphBackColor);
   PrintXY(0.4, 0.105, '('+NumStr(y[1], 3, 0)+', '+NumStr(y[2], 3, 0)+')');
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptForClick(text : string);
VAR
   dx,dy,cx,cy,a,n : integer;
   image           : TImage;
   z               : char;
   envir           : TEnvironment;
   Inside, Ins: Boolean;
   Button: Integer;
   xm, ym: Integer;
   MSave, FSave    : Integer;
BEGIN
   Inside := True;
   Button := 0;
   envir.Save;
   envir.Standardize;
   SetFillStyle(SolidFill,red);
   dx := TextWidth(text)+13;
   dy := RowHt + 3;
   cx := (GetMaxX-dx) DIV 2;
   cy := (GetMaxY-dy) DIV 8;
   Image.Get(cx,cy,cx+dx,cy+dy);
   HideMouse;
   Bar3D(cx,cy+3,cx+dx-3,cy+dy,3,true);
   ShowMouse;
   ClearMKBuffers;
   SetColor(Yellow);
   HideMouse;
   OutTextXY(cx+6,cy+8,Text);
   ShowMouse;
   Envir.Reset;
   REPEAT
      MousePosn(y[1], y[2], 1, 1, Inside);
      IF Inside AND
      (Abs(MSave - Trunc(y[1])) + Abs(FSave - Trunc(y[2])) > 2) THEN
      BEGIN
         RubOutXY(0.4, 0.105, 20, GraphBackColor);
         PrintXY(0.4, 0.105, '('+NumStr(y[1], 3, 0)+', '+NumStr(y[2], 3, 0)+')');
         MSave := Trunc(y[1]);
         FSave := Trunc(y[2]);
      END;
   UNTIL MouseClicked(a,a);
   InitialX := y[1];
   InitialY := y[2];
   envir.Save;
   envir.Standardize;
   image.put(cx,cy);
   envir.Reset;
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptInitialConditions;
var 
    x1, y1, x2, y2: integer;
    Inside: Boolean;
    InitialDat      : TInputScreen;
BEGIN
   ShowCursor;
   Pause := False;
   KeyInitialConditions := UseKey;
   IF KeyInitialConditions THEN
   BEGIN
      WITH InitialDat DO
      BEGIN
         Init;
         DefineInputPort(0.3, 0.7, 0.75, 0.95);
         LoadLine('  Enter initial conditions:');
         LoadLine('      x = {      } <= '+NumStr(Males, 3, 0));
         LoadLine('      y = {      } <= '+NumStr(Females, 3, 0));
         LoadLine('          [  OK  ]   ');
         SetNumber(1, Trunc(InitialX));
         SetNumberLimits(1, 0, Males);
         SetNumber(2, Trunc(InitialY));
         SetNumberLimits(2, 0, Females);
         AcceptScreen;
         y[1] := GetNumber(1);
         y[2] := GetNumber(2);
         InitialX := y[1];
         InitialY := y[2];
         Done;
      END;
   END
   ELSE
   BEGIN
      SetColor(Black);
      GraphBackColor := DarkGray;
      Map(0, 0, x1, y1);
      Map(Males, Females, x2, y2);
      x1 := x1 + Trunc(GetMaxX/10);
      x2 := x2 + Trunc(GetMaxX/10);
      y1 := y1 + Trunc(GetMaxy*0.08);
      y2 := y2 + Trunc(GetMaxy*0.08);
      MouseBorders(x1, y1, x2, y2);
      SetColor(Yellow);
      PromptForClick('Click on a starting point');
      MouseBorders(0, 0, GetMaxX, GetMaxY);
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE  DrawArrow(xHead, yHead, xSlope, ySlope: Real);
VAR
   x, y, ASize: Real;
BEGIN
   xSlope := xSlope/Sqrt(xSlope*xSlope + ySlope*ySlope);
   ySlope := ySlope/Sqrt(xSlope*xSlope + ySlope*ySlope);
   ASize := Males/50;
   x := xHead - ASize*xSlope + ASize*YSlope;
   y := yHead - ASize*ySlope - ASize*XSlope;
   PlotLine(xHead, yHead, x, y);
   x := xHead - ASize*xSlope - ASize*YSlope;
   y := yHead - ASize*ySlope + ASize*XSlope;
   PlotLine(xHead, yHead, x, y);
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

PROCEDURE  SetUpScreen;
VAR
   MaleStr, FemaleStr, EqnStr, AStr, MStr, GStr, BStr, NStr, HStr: String;
   xSc, ySc: Integer;
   PMales, PFemales : Real;
   i: Integer;
BEGIN
    ClearMuppetPort;
    IF NOT DField THEN
    BEGIN
   { Males := 100;
    Females := 100;}
    Sliders.Create(1, 1, 200, Males, 0.05, 0.05, 0.4, 0, '1', '200', 'Males',
                   True);
    Sliders.Create(4, 1, 200, Females, 0.95, 0.05, 0.4, 0, '1', '200', 'Females',
                   True);
    Sliders.Create(2, 0, 40, MaleCure, 0.05, 0.425, 0.675, 1, '0', '40', 'Cure',
                   True);
    Sliders.Create(5, 0, 40, FemaleCure, 0.95, 0.425, 0.675, 1, '0', '40', 'Cure',
                   True);
    Sliders.Create(3, 0, 1, MaleInfect, 0.05, 0.7, 0.95, 2, '0', '1', 'Infect',
                   True);
    Sliders.Create(6, 0, 1, MaleInfect, 0.95, 0.7, 0.95, 2, '0', '1', 'Infect',
                   True);
    Sliders.DrawAll;
    END;
    GraphBackColor := DarkGray;
    OpenViewPort(1);
    LightMenu := False;
    IF DField THEN
    BEGIN
       PMales := Males;
       PFemales := Females;
    END
    ELSE
    BEGIN
       PMales := 200;
       PFemales := 200;
    END;
    DefineScale(1, -PMales/20, 1.05*PMales, -PFemales/20, 1.05*PFemales);
    SelectScale(1);
    SetColor(LightGreen);
    PlotLine(0, 0, 0, PFemales);
    PlotLine(0, 0, PMales, 0);
    PlotLine(PMales, 0, PMales, PFemales/50);
    Map(PMales, 0, xSc, ySc);
    Str(Trunc(PMales), MaleStr);
    OutTextxy(xSc-XDisp(10), ySc+YDisp(5), MaleStr);
    OutTextxy(xSc-XDisp(40), ySc - YDisp(15), 'Males');
    PlotLine(0, PFemales, PMales/50, PFemales);
    Map(0, PFemales, xSc, ySc);
    Str(Trunc(PFemales), FemaleStr);
    OutTextxy(xSc+XDisp(10), ySc-YDisp(2), FemaleStr);
    OutTextxy(xSc, ySc - YDisp(15), 'Females');
    IF NOT DField THEN
    BEGIN
       WITH HotKeys DO Key[1] := 'F2-Pause';
       HotKeys.BackColor := Red;
       HotKeys.Display;
       PromptInitialConditions;
       PrepareToRunOrbit;
   END;
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
   xCol, yRow               : Integer;
   Fy, Fz                   : Vector;
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
   Fraction := 0.2;
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

BEGIN
   DField := True;
   xMin := -Males/20;
   xMax := 1.05*Males;
   yMin := -Females/20;
   yMax := 1.05*Females;
   xCol := 25;
   yRow := 25;
   GetDFieldData;
   HideMouse;
   SetUpScreen;
   SetColor(Yellow);
   DelX := Trunc((MapX(xMax) - MapX(xMin))/xCol);
   DelY := Trunc(Abs(MapY(yMax) - MapY(yMin))/yRow);
   Length := DelX;
   DX := (xMax - xMin)/xCol;
   DY := (yMax - yMin)/yRow;
   DL := DX;
   IF DY < DL THEN DL := DY;
   IF Length > DelY THEN Length := DelY;
   Length := Trunc(Length*0.9);
   FOR i := 1 TO xCol DO
   BEGIN
      x := xMin + i*DX;
      FOR j := 1 TO yRow DO
      BEGIN
         y := yMin + j*DY;
         Fy[1] := x;
         Fy[2] := y;
         Fun(Time, Fy, Fz);
         Factor := Sqrt(Fz[1]*Fz[1] + Fz[2]*Fz[2]);
         IF Factor > 0.001 THEN
         BEGIN
            xEnd := DL*Fz[1]/Factor;
            yEnd := DL*Fz[2]/Factor;
            Arrow(x, y, xEnd, yEnd, Length);
         END;
         PlotDot(x, y);
      END;
   END;
   PlotOrbit := True;
   ShowMouse;
         WITH HotKeys DO Key[1] := 'F2-Pause';
       HotKeys.BackColor := Red;
       HotKeys.Display;
       PromptInitialConditions;
       PrepareToRunOrbit;
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawDirectionField1;
VAR
   DelX, DelY, Length: Real;
   Slope: Real;
   x, y: Real;
   xEnd, yEnd: Real;
   i, j: Integer;
   Xcol, yRow: Integer;
   xMax, xMin, yMax, yMin: Real;

FUNCTION f(x, y: Real): Real;
BEGIN
   f :=  (- FemaleCure*y + FemaleInfect*x*(Females - y))/
         (- MaleCure*x + MaleInfect*y*(Males - x));
END;

BEGIN
   GonoMenu.RowActivate(5, 1, False);
   DField := True;
   SetUpScreen;
   xMin := -Males/20;
   xMax := 1.05*Males;
   yMin := -Females/20;
   yMax := 1.05*Females;
   xCol := 40;
   yRow := 40;
   SetColor(Yellow);
   DelX := (xMax - xMin)/xCol;
   DelY := (yMax - yMin)/yRow;
   Length := DelX;
   IF Length > DelY THEN Length := DelY;
   Length := Length*0.8;
   FOR i := 2 TO xCol DO
   BEGIN
      x := xMin + i*DelX;
      FOR j := 2 TO yRow DO
      BEGIN
         y := yMin + j*DelY;
         Slope := F(x+0.00001, y+0.00001);
         xEnd := Length/Sqrt(1 + Slope*Slope);
         yEnd := Slope*xEnd;
         PlotLine(x, y, x + xEnd, y + yEnd);
      END;
   END;
   ShowCursor;
   WITH HotKeys DO Key[1] := 'F2-Pause';
   HotKeys.BackColor := Red;
   HotKeys.Display;
   GonoMenu.RowActivate(5, 1, True);
   PromptInitialConditions;
   PrepareToRunOrbit;
END;


{-------------------------------------------------------------------------}

PROCEDURE HandleGonoMenu;
BEGIN
   With GonoMenu DO
   CASE ColChosen OF
      1: Case RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpGono.Hlp', 'GonoAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpGono.Hlp', 'GonoAboutModelA');
                  ShowHelp('HelpGono.Hlp', 'GonoAboutModelB');
               END;
            2: ShowHelp('HelpGono.Hlp', 'GonoRunProgram');
            3: BEGIN
                  ShowHelp('HelpGono.Hlp', 'GonoDFieldA');
                  ShowHelp('HelpGono.Hlp', 'GonoDFieldB');
               END;
         END;
      3: CASE RowChosen OF
            1: IF NOT GetGonoData THEN LightMenu := True;
            2: SetUpScreen;
            3: BEGIN
                  PlotOrbit := False;
                  IF GetGonoData THEN DrawDirectionField
                                 ELSE LightMenu := True;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE ReadSliders;
BEGIN
   Males := Sliders.Value(1);
   IF y[1] > Males THEN y[1] := Males;
   MaleCure := Sliders.Value(2);
   MaleInfect := Sliders.Value(3);
   Females := Sliders.Value(4);
   IF y[2] > Females THEN y[2] := Females;
   FemaleCure := Sliders.Value(5);
   FemaleInfect := Sliders.Value(6);
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag: Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
         1: BEGIN
               IF Pause THEN
               BEGIN
                  Pause := False;
                  WITH HotKeys DO Key[1] := 'F2-Pause';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
               END
               ELSE
               BEGIN
                  Pause := True;
                  WITH HotKeys DO Key[1] := 'F2-Start';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
               END;
            END;
         2: IF Lag > DelLag THEN Lag := Lag - DelLag;
         3: Lag := Lag + DelLag;
         4: BEGIN
               PromptInitialConditions;
               PrepareToRunOrbit;
            END;
         5: IF DField THEN DrawDirectionField ELSE SetUpScreen;
         6: BEGIN
               PlotOrbit := False;
               DField := False;
               ClearMuppetPort;
               LightMenu := True;
            END;
   END;
END;


{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DField := False;
   KeyInitialConditions := True;
   DefineViewPort(1, 0.1, 0.9, 0.08, 0.92);
   GraphBackColor := DarkGray;
   Lag := 200;
   LightMenu := True;
   ExitRequest := False;
   Hello('HelpGono.Hlp', 'GonoAboutProgram');
   SetUpGonoMenu;
   SetUpHotKeys;
   Males := 100;
   Females := 100;
   MaleCure := 20;
   FemaleCure := 15;
   MaleInfect := 0.5;
   FemaleInfect := 0.5;
   InitialX := 10;
   InitialY := 10;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   Sliders.Init;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF PLotOrbit AND (NOT Pause) THEN StepOrbit;
      IF Sliders.Changed THEN ReadSliders;
      IF LightMenu THEN
         IF GonoMenu.Chosen THEN HandleGonoMenu
   UNTIL ExitRequest;
   GonoMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




