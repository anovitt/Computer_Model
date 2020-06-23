Program AircraftLanding;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;

CONST
   Neq = 4;

type
   vector = array[1..neq] of real;

var
   AircraftMenu                       : TMenu;
   HotKeys                            : THotKeys;
   AircraftDat, KeyDat                : TInputScreen;
   Time, StepSize                     : Real;
   y                                  : Vector;
   Friction, AirResistance, Spring    : Real;
   AirSpeed                           : Real;
   LandingSpeed                       : Real;
   Speed                              : Real;
   WAircraft, WSandbag                : Real;
   xAircraft, xSandbag                : Real;
   DeckLength, RopeLength             : Real;
   CarrierSpeed, WindSpeed            : Real;
   Lag                                : Integer;
   PlotOrbit, Land, Action            : Boolean;
   ExitRequest                        : Boolean;
   DataOK                             : Boolean;
   LightMenu                          : Boolean;
   GetData                            : Boolean;
   Key                                : Byte;
   KeyData                            : Boolean;
   Sliders                            : TSliders;
   xScreenRatio, yScreenRatio         : Real;

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

PROCEDURE SetUpAircraftMenu;
VAR
   I      : Integer;
BEGIN
   With AircraftMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About the program');
       row(1,2, 'About CUPS');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Run demonstration');
       row(2,3, 'Walk-through');
      Column(3, 'Run');
       row(3,1, 'Enter parameters');
       row(3,2, 'See the animation');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   {AircraftMenu.Display;}
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F2-Input';
      Key[2] := 'F3-Land';
      Key[3] := 'F4-Pause';
      Key[4] := 'F5-Faster';
      Key[5] := 'F6-Slower';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
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

{-------------------------------------------------------------------------}

PROCEDURE DrawAircraft(x: Real; AColor: Word);
VAR
   xSc, ySC: Integer;
BEGIN
   SetColor(AColor);
   Map(x, 0, xSc, ySc);
   Ellipse(xSc, ySc - YDisp(8), 0, 360, XDisp(30), YDisp(7));
   Ellipse(xSc, ySc - YDisp(7), 0, 360, XDisp(10), YDisp(3));
   Ellipse(xSc-XDisp(25), ySc - YDisp(10), 0, 180, XDisp(5), YDisp(15));
   Line(xSc-XDisp(33), ySc-YDisp(10), xSc-XDisp(17), ySc-YDisp(10));
   Line(xSc+XDisp(29), ySc-YDisp(15), xSc+XDisp(29), ySc-YDisp(1));
END;

{-------------------------------------------------------------------------}

PROCEDURE DrawSandBag(x: Real; SColor: Word);
VAR
   xSc, ySc: Integer;
BEGIN
   SetColor(SColor);
   Map(x, 0, xSc, ySc);
   Circle(xSc, ySc - YDisp(5), XDisp(4));
END;

{--------------------------------------------------------------------------}

PROCEDURE DrawRope(x1, x2: Real; RColor: Word);
BEGIN
   SetColor(RColor);
   PlotLine(x1 + 0.1, 0.1, x2 - 1, 0.1);
END;

{--------------------------------------------------------------------------}

PROCEDURE RunDemo;
VAR
   xSandbag, dxSandbag, ddxSandbag      : Real;
   xAircraft, DxAircraft                : Real;
   Time                                 : Real;
   Dem1HK, Dem2HK, Dem3HK               : THotKeys;
   QuitDemo                             : Boolean;
   Dem1, Dem2, Dem3                     : Boolean;

{-----------------------------------------------------------------------}

PROCEDURE SetUpDem1HotKeys;
BEGIN
   WITH Dem1HK DO
   BEGIN
      Dem1HK.Init(3);
      Key[1] := 'F2-Move';
      Key[2] := 'Right-Next';
      Key[3] := 'F10-Menu';
   END;
   Dem1HK.Display;
END;

{-----------------------------------------------------------------------}

PROCEDURE SetUpDem2HotKeys;
BEGIN
   WITH Dem2HK DO
   BEGIN
      Dem2HK.Init(4);
      Key[1] := 'F2-Move';
      Key[2] := 'Right-Next';
      Key[3] := 'Left-Previous';
      Key[4] := 'F10-Menu';
   END;
   Dem2HK.Display;
END;

{-----------------------------------------------------------------------}

PROCEDURE SetUpDem3HotKeys;
BEGIN
   WITH Dem3HK DO
   BEGIN
      Dem3HK.Init(3);
      Key[1] := 'F2-Move';
      Key[2] := 'Left-Previous';
      Key[3] := 'F10-Menu';
   END;
   Dem3HK.Display;
END;

{-----------------------------------------------------------------------}

PROCEDURE Screen1;
BEGIN
   OpenViewPort(2);
   SelectScale(2);
   ClearMKBuffers;
   Dem1 := True; Dem2 := False; Dem3 := False;
   SetUpDem1HotKeys;
   SetColor(Yellow);
   Print(10, 2, 'Three types of motion may take place in this model.');
   Print(30, 5, '1: Stretching.');
   Print(5, 16, 'The sandbag is at rest, and the tension in the cable is less');
   Print(5, 17, 'than the dry friction between the sandbag and the deck.');
   Print(5, 18, 'This continues until the forces are equal.');
   Print(10, 20, 'Watch the stretch, then click to continue');
   SetColor(White);
   PlotLine(0, 0, 20, 0);
   XSandbag := 1;
   DrawSandBag(XSandbag, Green);
   XAircraft := 5;
   dXAircraft := 0.1;
   DrawAircraft(XAircraft, Yellow);
   DrawRope(XSandbag, XAircraft, White);
END;

{-----------------------------------------------------------------------}

PROCEDURE Move1;
BEGIN
   DrawAircraft(XAircraft, Blue);
   DrawRope(XSandbag, XAircraft, Blue);
   XAircraft := 5;
   DrawAircraft(XAircraft, Yellow);
   DrawRope(XSandbag, XAircraft, White);
   REPEAT
      DrawAircraft(XAircraft, Blue);
      XAircraft := XAircraft + dXAircraft;
      DrawAircraft(XAircraft, Yellow);
      DrawRope(XSandbag, XAircraft, White);
      Delay(200);
   UNTIL Xaircraft > 7;
END;

{-----------------------------------------------------------------------}

PROCEDURE Screen2;
BEGIN
   OpenViewPort(2);
   SelectScale(2);
   ClearMKBuffers;
   Dem2 := True; Dem1 := False; Dem3 := False;
   SetUpDem2HotKeys;
   SetColor(Yellow);
   Print(10, 2, 'Three types of motion may take place in this model.');
   Print(20, 5, '2: Cable stretched; full motion.');
   Print(5, 16, 'The cable is stretched and the sandbag is moving. Because of');
   Print(5, 17, 'its smaller mass, the sandbag soon moves faster than the');
   Print(5, 18, 'aircraft, and eventually the cable becomes slack.');
   Print(10, 20, 'Watch the motion, then click to continue');
   SetColor(White);
   PlotLine(0, 0, 20, 0);
   XSandbag := 1;
   DrawSandBag(XSandbag, Green);
   XAircraft := 7;
   dXAircraft := 0.1;
   ddXSandbag := 0.01;
   Time := 0;
   DrawAircraft(XAircraft, Yellow);
   DrawRope(XSandbag, XAircraft, White);
END;

{-----------------------------------------------------------------------}

PROCEDURE Move2;
BEGIN
   DrawSandbag(XSandBag, Blue);
   DrawRope(XSandbag, XAircraft, Blue);
   DrawAircraft(XAircraft, Blue);
   XSandbag := 1;
   DrawSandBag(XSandbag, Green);
   XAircraft := 7;
   dXAircraft := 0.1;
   ddXSandbag := 0.01;
   Time := 0;
   DrawAircraft(XAircraft, Yellow);
   DrawRope(XSandbag, XAircraft, White);
   REPEAT
      Time := Time + 1;
      DrawSandbag(XSandBag, Blue);
      DrawRope(XSandbag, XAircraft, Blue);
      XSandBag := 1 + ddXSandbag*Time*Time;
      DrawSandbag(XSandbag, Green);
      DrawAircraft(XAircraft, Blue);
      XAircraft := XAircraft + dXAircraft;
      DrawAircraft(XAircraft, Yellow);
      DrawRope(XSandbag, XAircraft, White);
      Delay(200);
   UNTIL Time = 20;
END;

{-----------------------------------------------------------------------}

PROCEDURE Screen3;
BEGIN
   OpenViewPort(2);
   SelectScale(2);
   ClearMKBuffers;
   Dem3 := True; Dem2 := False; Dem1 := False;
   SetUpDem3HotKeys;
   SetColor(Yellow);
   Print(10, 2, 'Three types of motion may take place in this model.');
   Print(18, 5, '3: Cable slack; independent motion.');
   Print(5, 15, 'The cable is slack, so the tension is zero. The two bodies');
   Print(5, 16, 'move independently, with the sandbag slowing down more');
   Print(5, 17, 'rapidly. When the cable again becomes taut, the sandbag may be');
   Print(5, 18, 'at rest, when stretching starts, or it may still be moving.');
   Print(10, 20, 'Watch the motion, then click to continue');
   SetColor(White);
   PlotLine(0, 0, 20, 0);
   XSandbag := 5;
   DrawSandBag(XSandbag, Green);
   XAircraft := 9;
   dXAircraft := 0.1;
   dXSandbag := 0.4;
   ddXSandbag := 0.01;
   Time := 0;
   DrawAircraft(XAircraft, Yellow);
   DrawRope(XSandbag, XAircraft, White);
END;

{-----------------------------------------------------------------------}

PROCEDURE Move3;
BEGIN
   DrawAircraft(XAircraft, Blue);
   DrawSandbag(XSandbag, Blue);
   DrawRope(XSandbag, XAircraft, Blue);
   SetColor(White);
   PlotLine(0, 0, 20, 0);
   XSandbag := 5;
   DrawSandBag(XSandbag, Green);
   XAircraft := 9;
   dXAircraft := 0.1;
   dXSandbag := 0.4;
   ddXSandbag := 0.01;
   Time := 0;
   DrawAircraft(XAircraft, Yellow);
   DrawRope(XSandbag, XAircraft, White);
   REPEAT
      Time := Time + 1;
      DrawSandbag(XSandBag, Blue);
      DrawRope(XSandbag, XAircraft, Blue);
      XSandBag := 5 + dXSandbag*Time - ddXSandbag*Time*Time;
      DrawSandbag(XSandbag, Green);
      DrawAircraft(XAircraft, Blue);
      XAircraft := XAircraft + dXAircraft;
      DrawAircraft(XAircraft, Yellow);
      DrawRope(XSandbag, XAircraft, White);
      Delay(200);
   UNTIL Time = 20;
   REPEAT
      DrawAircraft(XAircraft, Blue);
      XAircraft := XAircraft + dXAircraft;
      DrawAircraft(XAircraft, Yellow);
      DrawRope(XSandbag, XAircraft, White);
      Delay(200);
   UNTIL Xaircraft > 13;
END;

{-----------------------------------------------------------------------}

PROCEDURE HandleDem1HotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: Move1;
      2: BEGIN Dem1HK.Clear; Screen2; END;
      3: QuitDemo := True;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE HandleDem2HotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: Move2;
      2: BEGIN Dem2HK.Clear; Screen3; END;
      3: BEGIN Dem2HK.Clear; Screen1; END;
      4: QuitDemo := True;
   END;
END;

{-----------------------------------------------------------------------}

PROCEDURE HandleDem3HotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: Move3;
      2: BEGIN Dem3HK.Clear; Screen2; END;
      3: QuitDemo := True;
   END;
END;

{-----------------------------------------------------------------------}


BEGIN
   GraphBackColor := Blue;
   DefineViewPort(2, 0.05, 0.95, 0.05, 0.95);
   DefineScale(2, 0, 20, -5, 5);
   QuitDemo := False;
   LightMenu := False;
   Screen1;
   REPEAT
      CheckForEvents;
      IF Dem1 AND Dem1HK.Pressed(Key)
         THEN HandleDem1HotKeys(Key)
         ELSE
         BEGIN
            IF Dem2 AND Dem2HK.Pressed(Key)
               THEN HandleDem2HotKeys(Key)
               ELSE
                  IF Dem3 AND Dem3HK.Pressed(Key) THEN HandleDem3HotKeys(Key);
        END;
   UNTIL QuitDemo;
   ClearMuppetPort;
   LightMenu := True;
END;

{--------------------------------------------------------------------------}

FUNCTION GetAircraftData : Boolean;
CONST
   RBNames: String = '12345';
BEGIN
   Message('');
   WITH AircraftDat DO
   BEGIN
      Init;
      DefineInputPort(0.07, 0.93, 0.02, 0.98);
      LoadLine('             Parameters for an Aircraft Landing');
      LoadLine('');
      LoadLIne('            The weight of the aircraft = {       } > 100 lb');
      LoadLine('             The weight of the sandbag = {       } > 10 lb');
      LoadLine('');
      LoadLine('    The coefficient of dry friction between the ');
      LoadLine('                  sandbag and the deck = {       } > 0 lb');
      LoadLine('');
      LoadLine('    The coefficient of resistance between the ');
      LoadLine('                  aircraft and the air = {       } > 0 lb/(ft/s)^2');
      LoadLine('');
      LoadLine('      The spring constant for the wire = {       } > 0 lb/ft');
      LoadLine('');
      LoadLine(' The speed of the carrier to the right = {       } > 0 ft/s');
      LoadLine('     The speed of the wind to the left = {       } > 0 ft/s');
      LoadLine('');
      LoadLine('        The length of the landing deck = {       } > 50 ft');
      LoadLine('    The unstretched lengh of the cable = {       } > 1 ft');
      LoadLine('');
      LoadLine('     Enter data from the mouse #1  or keyboard #1 ');
      LoadLine('');
      LoadLIne('            [  OK  ]              [Cancel]');
      SetNumber(1, WAircraft);
      SetNumberLimits(1, 100, 100000);
      SetNumber(2, WSandbag);
      SetNumberLimits(2, 10, 10000);
      SetNumber(3, Friction);
      SetNumberLimits(3, 0, 10000);
      SetNumber(4, AirResistance);
      SetNumberLimits(4, 0, 100);
      SetNumber(5, Spring);
      SetNumberLimits(5, 0, 1000000);
      SetNumber(6, CarrierSpeed);
      SetNumber(7, WindSpeed);
      SetNumber(8, DeckLength);
      SetNumberLimits(8, 50, 10000);
      SetNumber(9, RopeLength);
      SetNumberLimits(9, 1, 100000);
      IF KeyData THEN
         SetRadioButton('1', 2) ELSE SetRadioButton('1', 1);
      AcceptScreen;
      GetAircraftData := NOT Canceled;
      WAircraft := GetNumber(1);
      WSandBag := GetNumber(2);
      Friction := GetNumber(3);
      AirResistance := GetNumber(4);
      Spring := GetNumber(5);
      CarrierSpeed := GetNumber(6);
      WindSpeed := GetNumber(7);
      DeckLength := GetNumber(8);
      RopeLength := GetNumber(9);
      AirSpeed := WindSpeed + CarrierSpeed;
      DefineScale(1, 0, DeckLength+5, -5, 5);
      IF GetRadioButton(RBNames[1]) = 1 THEN KeyData := False
                                        ELSE KeyData := True;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
VAR
   Tension: Integer;
BEGIN
   IF y[1] > y[3] THEN Tension := 1 else Tension := 0;
   z[1] := y[2]; z[3] := y[4];
   Z[2] := -(AirResistance*(Y[2] + AirSpeed)*(Y[2] + AirSpeed)
           + Tension*Spring*(Y[1] - Y[3]))*32/WAircraft;
   IF Y[4] < 0.001 THEN
   BEGIN
      z[3] := 0;
      y[4] := 0;
      z[4] := (- Friction + Tension*Spring*(Y[1]-Y[3]))*32/WSandBag;
      IF z[4] < 0 THEN z[4] := 0;  
   END
   ELSE
      Z[4] := (- Friction +
               Tension*Spring*(Y[1]-Y[3]))*32/WSandBag;

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
      temax := tol/100;
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

PROCEDURE PrintMessage;
BEGIN
   SetColor(Yellow);
   PrintXY(0.17, 0.9,'Select ''Input'' for starting conditions and then ''Land'' to start');
   PrintXY(0.17, 0.86,'the animation.');
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   ClearMuppetPort;
   SelectScale(1);
   PlotOrbit := True;
   LightMenu := False;
   SetUpHotKeys;
   IF Not KeyData THEN
   BEGIN
      Sliders.Create(1, 0, 200, LandingSpeed, 0.05, 0.2, 0.8, 2, '0', '200', 'ft/s', True);
      Sliders.DrawAll;
      PrintXY(0.02, 0.18, 'Landing');
      PrintXY(0.02, 0.15, ' speed');
   END;
   Message('Speed relative to the carrier is:  Landing speed - '
        +NumStr(AirSpeed, 4,1)+'ft/s');
   OpenViewPort(1);
   PrintMessage;
   SetColor(White);
   PlotLine(1, 0, DeckLength, 0);
   PlotLine(1, 0, 2, -2);
   PlotLine(DeckLength, 0, 0.9*DeckLength, -2);
   SetColor(Blue);
   PlotLine(0, -2, DeckLength+5, -2);
   {DrawAircraft(2, Yellow);}
   DrawSandBag(1, Green);
   SetColor(White);
   printXY(0.27, 0.3, 'Sandbag');
   printXY(0.7, 0.3, 'Aircraft');
   printXY(0.16, 0.26, 'Displacement =           ft');
   printXY(0.16, 0.22, '       Speed =          ft/s');
   printXY(0.6, 0.26, 'Displacement =           ft');
   printXY(0.6, 0.22, '       Speed =          ft/s');
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE RestorePicture;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   OpenViewPort(1);
   SelectScale(1);
   PlotOrbit := True;
   SetUpHotKeys;
   SetColor(White);
   PlotLine(1, 0, DeckLength, 0);
   PlotLine(1, 0, 2, -2);
   PlotLine(DeckLength, 0, 0.9*DeckLength, -2);
   SetColor(Blue);
   PlotLine(0, -2, DeckLength+5, -2);
   DrawAircraft(1 + RopeLength, Yellow);
   DrawSandBag(1, Green);
   SetColor(White);
   printXY(0.27, 0.3, 'Sandbag');
   printXY(0.7, 0.3, 'Aircraft');
   printXY(0.16, 0.26, 'Displacement =           ft');
   printXY(0.16, 0.22, '       Speed =          ft/s');
   printXY(0.6, 0.26, 'Displacement =           ft');
   printXY(0.6, 0.22, '       Speed =          ft/s');
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpOrbit;
BEGIN
   LightMenu := False;
   Time := 0;
   y[1] := 0;
   y[2] := Speed - AirSpeed;
   y[3] := 0;
   y[4] := 0;
   StepSize := 0.1;
   PlotOrbit := True;
   RestorePicture;
   printXY(0.45, 0.4, 'Stretching');
   xAircraft := 1+RopeLength;
   xSandBag := 1;
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveOrbit;
BEGIN
   HideMouse;
   Delay(Lag);
   Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
   IF y[2] < 0 THEN PlotOrbit := False;
   IF PlotOrbit THEN
   BEGIN
      DrawAircraft(xAirCraft, Black);
      DrawSandBag(xSandBag, Black);
      DrawRope(xSandbag, xAircraft, Black);
      xAircraft := 1 + RopeLength + y[1];
      xSandBag := 1 + y[3];
      DrawAircraft(xAirCraft, Yellow);
      DrawSandBag(xSandBag, Green);
      DrawRope(xSandbag, xAircraft, White);
      RubOutXY(0.45, 0.4, 11, Black);
      IF y[1] < y[3] THEN printXY(0.45, 0.4, 'Cable slack')
      ELSE
      BEGIN
         IF Abs(y[4]) < 0.001 THEN printXY(0.45, 0.4, 'Stretching')
                              ELSE printXY(0.45, 0.4, 'Full motion');
      END;
   END;
   IF PlotOrbit = False THEN
   BEGIN
      RubOutXY(0.45, 0.4, 11, Black);
      PrintXY(0.45, 0.4, 'Stopped');
   END;
   IF y[1] > DeckLength-RopeLength-1 THEN
   BEGIN
      RubOutXY(0.45, 0.4, 11, Black);
      PrintXY(0.45, 0.4, 'SPLASH');
      PlotOrbit := False;
      DrawAircraft(xAirCraft, Black);
      DrawRope(xSandbag, xAircraft, Black);
   END;
   SetColor(White);
   rubOutXY(0.35, 0.26, 8, Black);
   RubOutXY(0.35, 0.22, 8, Black);
   printXY(0.35, 0.26, NumStr(y[3],5,2));
   IF y[4] < 0 THEN
   BEGIN
      y[4] := 0;
   END;
   printXY(0.35, 0.22, NumStr(y[4],5,2));
   rubOutXY(0.79, 0.26, 8, Black);
   RubOutXY(0.79, 0.22, 8, Black);
   SetColor(White);
   printXY(0.79, 0.26, NumStr(y[1],5,2));
   IF y[2] > 0 THEN printXY(0.79, 0.22, NumStr(y[2],5,2))
               ELSE printXY(0.79, 0.22, ' 0.00');
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE KeyLand;
BEGIN
   Land := False;
   Action := False;
   WITH KeyDat DO
   BEGIN
      Init;
      DefineInputPort(0, 0.15, 0.37, 0.63);
      LoadLine('  Landing');
      LoadLine('   speed');
      LoadLine('= {      }');
      LoadLine('   ft/s');
      LoadLine(' [  OK  ]');
      SetNumber(1, LandingSpeed);
      SetNumberLimits(1, 0, 10000);
      AcceptScreen;
      Speed := GetNumber(1);
      LandingSpeed := Speed;
      Done;
   END;
END;


{-------------------------------------------------------------------------}

PROCEDURE MouseLand;
VAR
   Speed: Real;
BEGIN
   Land := False;
   Action := False;
   GetData := True;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
VAR
   DelLag    : Integer;
BEGIN
   DelLag := 10;
   CASE Key OF
      1: BEGIN
            HotKeys.BackColor := Blue;
            HotKeys.Display;
            Land := False;
            PrintMessage;
            IF KeyData THEN KeyLand ELSE MouseLand;
         END;
      2: BEGIN
            HotKeys.BackColor := Red;
            HotKeys.Display;
            GetData := False;
            SetUpOrbit;
            Land := True;
            Action := True;
            RubOutXY(0.17, 0.9, 61, Black);
            RubOutXY(0.17, 0.86, 20, Black);
         END;
      3: BEGIN
            IF (Action) AND (Land) THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[3] := 'F4-Start';
               HotKeys.BackColor := Green;
               HotKeys.Display;
               Exit;
            END;
            IF (NOT Action) AND (Land)
            THEN
            BEGIN
               Action := True;
               WITH HotKeys DO Key[3] := 'F4-Pause';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
         END;
      4: IF Lag - DelLag >= 0 THEN Lag := Lag - DelLag ELSE Lag := 0;
      5: Lag := Lag + DelLag;
      6: BEGIN
           PlotOrbit := False;
           Action := False;
           Land := False;
           HotKeys.Clear;
           LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}


PROCEDURE HandleAircraftMenu;
BEGIN
   With AircraftMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: ShowHelp('HelpMisc.hlp', 'AircraftAboutProgram');
            2: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpMisc.hlp', 'AircraftAboutModelA');
                  ShowHelp('HelpMisc.hlp', 'AircraftAboutModelB');
                  ShowHelp('HelpMisc.hlp', 'AircraftAboutModelC');
               END;
            2: RunDemo;
            3: ShowHelp('WalkThru.hlp', 'AirPlane');
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  Land := False;
                  IF GetAircraftData THEN SetUpPicture;
               END;
            2: BEGIN
                  Land := False;
                  SetUpPicture;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   ExitRequest := False;
   LightMenu := True;
   Action := False;
   PLotOrbit := False;
   GetData := False;
   DefineViewPort(1, 0.15, 1, 0.07, 0.95);
   DeckLength := 100;
   RopeLength := 20;
   DefineScale(1, 0, DeckLength+5, -5, 5);
   Lag := 100;
   LandingSpeed := 75;
   Speed := 75;
   WAircraft := 3000;
   WSandBag := 400;
   Friction := 400;
   AirResistance := 0.0363;
   Spring := 40000;
   CarrierSpeed := 40;
   WindSpeed := 10;
   xScreenRatio := GetMaxX/639;
   yScreenRatio := GetMaxY/479;
   Sliders.Init;
   Hello('HelpMisc.hlp', 'AircraftAboutProgram');
   SetUpAircraftMenu;
   REPEAT
      CheckForEvents;
      IF Hotkeys.Pressed(Key) THEN
                  HandleHotKeys(Key);
      IF PlotOrbit AND Action THEN MoveOrbit;
      IF GETData AND Sliders.Changed THEN
      BEGIN
         Speed := Sliders.Value(1);
         LandingSpeed := Speed;
      END;
      IF LightMenu AND AircraftMenu.Chosen THEN HandleAircraftMenu;
   UNTIL ExitRequest;
   AircraftMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




