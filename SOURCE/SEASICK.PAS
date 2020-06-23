Program PitchingAndRollingAtSea;

Uses Crt, Graph, CUPSMUPP, CUPS, CupsGui;

CONST
   Neq = 4;

type
   vector = array[1..neq] of real;

var
   SeasickMenu                        : TMenu;
   HotKeys                            : THotKeys;
   RollFreq, RollRes, RollSeaAmp      : Real;
   PitchFreq, PitchRes, PitchSeaAmp   : Real;
   PitchCouple, RollCouple            : Real;
   PitchAngle, RollAngle              : Real;
   SeaFreq                            : Real;
   ThetaSave, PhiSave, SeaSave        : Real;
   Time, StepSize                     : Real;
   y                                  : Vector;
   Lag                                : Integer;
   PlotOrbit, Fire, MayDay            : Boolean;
   Pause                              : Boolean;
   ExitRequest                        : Boolean;
   LightMenu                          : Boolean;
   Sliding                            : Boolean;
   Key                                : Byte;
   KeyData                            : Boolean;
   DataIn                             : Boolean;
   Sliders                            : TSliders;
   MaxTime, MaxAngles                 : Real;
   Th0, ThDot0, Ph0, PhDot0           : Real;

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

PROCEDURE SetUpSeasickMenu;
VAR
   I      : Integer;
BEGIN
   With SeasickMenu DO
   BEGIN
   Init;
   Column(1, 'File');
    row(1,2, 'About the program');
    row(1,1, 'About CUPS');
    row(1,3, 'Configuration');
    row(1,4, 'Leave the program');
   Column(2, 'Help');
    row(2,1, 'About the model');
    row(2,2, 'Walk-through');
   Column(3, 'Run');
    row(3,1, 'Enter parameters');
    row(3,2, 'Animate');
    row(3,3, 'Time plots');
   FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   {SeasickMenu.Display;}
END;
{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(5);
      Key[1] := 'F2-Input';
      Key[2] := 'F3-Run';
      Key[3] := 'F4-Faster';
      Key[4] := 'F5-Slower';
      Key[5] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{-------------------------------------------------------------------------}

Procedure GetSeasickData;
CONST
   RBNames: String = '12345';
VAR
   SeasickDat   :TInputScreen;
BEGIN
   Message('');
   WITH SeasickDat DO
   BEGIN
      Init;
      DefineInputPort(0.11, 0.89, 0.0, 1);
      LoadLine('           Data for Pitching and Rolling at Sea');
      LoadLine('      All numbers must be positive and less then 10');
      LoadLine('');
      LoadLIne('     Enter the natural frequencies, w1 and w2, for:');
      LoadLine('       pitching, {      } > 0.01, rolling, {      } > 0.01');
      LoadLine('');
      LoadLine('     Enter the resisting terms, r and s, for: ');
      LoadLine('       pitching, {      },        rolling, {      }');
      LoadLine('');
      LoadLine('     Enter the frequency, w, of the waves:');
      LoadLine('                         {      } > 0.01');
      LoadLIne('');
      LoadLine('     Enter the forcing amplitudes, p and q, for: ');
      LoadLine('       pitching, {      },        rolling, {      }');
      LoadLine('');
      LoadLine('     Enter coefficients k and l to control the extent of');
      LoadLine('  coupling between:');
      LoadLine('  roll-to-pitch, {      },  pitch-to-roll, {      }');
      LoadLine('');
      LoadLine('     Enter initial conditions from the ');
      LoadLine('                   mouse #1  or keyboard #1 ');
      LoadLine('');
      LoadLIne('          [ Help ]       [  OK  ]      [Cancel]');
      SetNumber(1, PitchFreq);
      SetNumberLimits(1, 0.01, 10);
      SetNumber(2, RollFreq);
      SetNumberLimits(2, 0.01, 10);
      SetNumber(3, PitchRes);
      SetNumberLimits(3, 0, 10);
      SetNumber(4, RollRes);
      SetNumberLimits(4, 0, 10);
      SetNumber(5, SeaFreq);
      SetNumberLimits(5, 0.01, 10);
      SetNumber(6, PitchSeaAmp);
      SetNumberLimits(6, 0, 10);
      SetNumber(7, RollSeaAmp);
      SetNumberLimits(7, 0, 10);
      SetNumber(8, PitchCouple);
      SetNumberLimits(8, 0, 10);
      SetNUmber(9, RollCouple);
      SetNumberLimits(9, 0, 10);
      IF KeyData THEN SetRadioButton('1', 2)
                 ELSE SetRadioButton('1', 1);
      SetHelpFile('HelpMisc.hlp', 'SeasickInputHelp');
      AcceptScreen;
      PitchFreq := GetNumber(1);
      RollFreq := GetNumber(2); 
      PitchRes := GetNumber(3); 
      RollRes := GetNumber(4);
      SeaFreq := GetNumber(5);
      PitchSeaAmp := GetNumber(6);
      RollSeaAmp := GetNumber(7);
      PitchCouple := GetNumber(8);
      RollCouple := GetNumber(9);
      IF GetRadioButton(RBNames[1]) = 1 THEN KeyData := False
                                        ELSE KeyData := True;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

Procedure Fun(x: Real; y: Vector; VAR z: Vector);
begin
   z[1] := y[3]; z[2] := y[4];
   z[3] := - PitchFreq*PitchFreq*Sin(y[1]) - PitchRes*y[3] + PitchCouple*y[2]*y[2]
           + PitchSeaAmp*Cos(SeaFreq*x);
   z[4] := - RollFreq*RollFreq*Sin(y[2]) - RollRes*y[4] + RollCouple*y[1]*y[2]
           + RollSeaAmp*Cos(SeaFreq*x);
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
end;

{-------------------------------------------------------------------------}

PROCEDURE PlotPitch(S, C, xPitch, yPitch: Real; PColor: Word);
VAR
   SaveColor        : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(PColor);
   PlotLine(xPitch-6*C,     yPitch-6*S,     xPitch+6*C,     yPitch+6*S);
   PLotLIne(xPitch-6*C,     yPitch-6*S,     xPitch-5*C+2*S, yPitch-5*S-2*C);
   PLotLine(xPitch-5*C+2*S, yPitch-5*S-2*C, xPitch+4*C+2*S, yPitch+4*S-2*C);
   PlotLine(xPitch+4*C+2*S, yPitch+4*S-2*C, xPitch+6*C,     yPitch+6*S);
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotRoll(S, C, xRoll, yRoll: Real; RColor: Word);
VAR
   SaveColor        : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(RColor);
   PlotLine(xRoll-2*C, yRoll-2*S, xRoll+2*C, yRoll+2*S);
   PLotLIne(xRoll-2*C, yRoll-2*S, xRoll-C+2*S, yRoll-S-2*C);
   PLotLine(xRoll-C+2*S, yRoll-S-2*C, xRoll+C+2*S, yRoll+S-2*C);
   PlotLine(xRoll+C+2*S, yRoll+S-2*C, xRoll+2*C, yRoll+2*S);
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE PlotSea(SeaTime: Real; SColor: Word);
VAR
   SeaLevel1, SeaLevel2: Real;
   i: Integer;
   VAR
   SaveColor        : Word;
BEGIN
   SaveColor := GetColor;
   SetColor(SColor);
   SeaLevel1 := 7 + 0.4*Sin(SeaTime*SeaFreq);
   SeaLevel2 := 7 - 0.4*Sin(SeaTime*SeaFreq);
   FOR I := 0 TO 8 DO
   BEGIN
      PlotLine(2*i+1, SeaLevel1, 2*i+2, SeaLevel1);
      PlotLine(2*i+2, SeaLevel2, 2*i+3, SeaLevel2);
   END;
   SetColor(SaveColor);
END;

{-------------------------------------------------------------------------}

PROCEDURE PrintMessage;
BEGIN
   SetColor(Yellow);
   Print(4, 1,'Select <Input> for starting conditions and then <Run> to start');
   Print(4, 2,'the animation.');
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpPicture;
BEGIN
   GraphBackColor := Black;
   HideCursor;
   LightMenu := False;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   PlotOrbit := True;
   SetUpHotKeys;
   PrintMessage;
   IF Not KeyData THEN
   BEGIN
      Sliders.Create(1, -90, 90, PitchAngle, 0.05, 0.1, 0.45, 2,
      '-90', '90', 'Pitch', True);
      Sliders.Create(2, -90, 90, RollAngle, 0.05, 0.55, 0.9, 2,
      '-90', '90', 'Roll', True);
   Sliders.DrawAll;
   END;
   PlotPitch(0, 1, 7, 8, Green);
   PlotRoll(0, 1, 17, 8, Green);
   PlotSea(0, Blue);
   ThetaSave := 0;
   PhiSave := 0;
   SeaSave := 0;
   DataIn := False;
   ShowCursor;
END;

{-------------------------------------------------------------------------}

PROCEDURE Sink;
VAR
   t, dt: Real;
   i: Integer;
BEGIN
   MayDay := False;
   PlotOrbit := False;
   DataIn := False;
   Fire := False;
   t :=0; dt := 0.2;
   REPEAT
      Sound(440+Trunc(300*Sin(t)));
      Delay(20);
      NoSound;
      t := t + dt;
   UNTIL t > 30;
      PlotPitch(Sin(y[1]), Cos(y[1]), 7, 8, Black);
      PlotRoll(Sin(y[2]), Cos(y[2]), 17, 8, Black);
      FOR i := 1 TO 50 DO
      BEGIN
         PlotPitch(1, 0, 7, 8 - i/4, Green);
         PlotRoll(1, 0, 17, 8 - i/4, Green);
         Delay(100);
         PlotPitch(1, 0, 7, 8 - i/4, Black);
         PlotRoll(1, 0, 17, 8 - i/4, Black);
      END;
      PlotSea(SeaSave, Black);
      OpenViewPort(1);
      PlotSea(0, Blue);
      WITH HotKeys DO Key[2] := 'F3-Run';
      HotKeys.BackColor := Red;
      HotKeys.Display;
      DataIn := False;
      y[1] := Pi*PitchAngle/180;
      y[2] := Pi*RollAngle/180;
      y[3] := 0;
      y[4] := 0;
      Time := 0;
      StepSize := 0.1;
END;

{-------------------------------------------------------------------------}

PROCEDURE TakeStep;
VAR
   SinPitch, CosPitch, SinRoll, CosRoll: Real;
BEGIN
   HideMouse;
   PlotPitch(Sin(y[1]), Cos(y[1]), 7, 8, Black);
   PlotRoll(Sin(y[2]), Cos(y[2]), 17, 8, Black);
   PlotSea(Time, Black);
   Step(Time, StepSize, 0.00001, y, Time, StepSize, y);
   ThetaSave := y[1];
   PhiSave := y[2];
   SeaSave := Time;
   PlotPitch(Sin(y[1]), Cos(y[1]), 7, 8, Green);
   PlotRoll(Sin(y[2]), Cos(y[2]), 17, 8, Green);
   PlotSea(Time, Blue);
   IF (Abs(y[1]) > Pi/2) OR (Abs(y[2]) > Pi/2) THEN
   BEGIN
      PlotOrbit := False;
      MayDay := True;
   END;
   Delay(Lag);
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE RunOrbit;
VAR
   Time, h: Real;
   SinPitch, CosPitch, SinRoll, CosRoll: Real;
   PlotOrbit: Boolean;
BEGIN
   Time := 0;
   StepSize := 0.1;
   PlotOrbit := True;
   MayDay := False;
   PlotPitch(Sin(ThetaSave), Cos(ThetaSave), 7, 8, Black);
   PlotRoll(Sin(PhiSave), Cos(PhiSave), 17, 8, Black);
   PlotSea(SeaSave, Black);
END;

{-------------------------------------------------------------------------}

PROCEDURE KeyAimAndFire;
VAR
   KeyDat     : TInputScreen;
BEGIN
   Fire := False;
   WITH KeyDat DO
   BEGIN
      Init;
      DefineInputPort(0, 0.15, 0.3, 0.7);
      LoadLine('  Pitch');
      LoadLine('= {      }');
      LoadLine('degrees');
      LoadLine('   Roll');
      LoadLine('= {      }');
      LoadLine('degrees');
      LoadLine('');
      LoadLine(' [  OK  ]');
      LoadLine(' [Cancel]');
      SetNumber(1, PitchAngle);
      SetNumberLimits(1, -90, 90);
      SetNumber(2, RollAngle);
      SetNumberLimits(2, -90, 90);
      AcceptScreen;
      PitchAngle := GetNumber(1);
      RollAngle := GetNumber(2);
      y[1] := Pi*PitchAngle/180;
      y[2] := Pi*RollAngle/180;
      y[3] := 0;
      y[4] := 0;
      Time := 0;
      StepSize := 0.1;
      Done;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSliders;
BEGIN
   PitchAngle := Sliders.Value(1);
   Th0 := PitchAngle;
   y[1] := PitchAngle*Pi/180;
   RollAngle := Sliders.Value(2);
   y[2] := RollAngle*Pi/180;
   Ph0 := RollAngle;
   y[3] := 0; y[4] := 0;
   Time := 0;
   StepSize := 0.1;
END;

{-------------------------------------------------------------------------}

PROCEDURE TimePlots;
VAR
   StepSize, TimeOld, ThOld, PhiOld : Real;
   Input                            : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.2, 0.8);
      LoadLine('');
      LoadLine('   Enter initial values, using degrees:');
      LoadLIne(' Pitch:  Theta = {      } ThetaDot = {      }');
      LoadLIne('  Roll:    Phi = {      }   PhiDot = {      }');
      LoadLine('');
      LoadLine('   Enter the maximum angular deflection for');
      LoadLine(' the plot: {      }');
      LoadLIne('   Enter the maximum time for the plot:');
      LoadLIne('           {      }');
      LoadLIne('');
      LoadLIne('                  [  OK  ]');
      SetNumber(1, Th0);
      SetNUmber(2, ThDot0);
      SetNumber(3, Ph0);
      SetNumber(4, PhDot0);
      SetNumber(5, MaxAngles);
      SetNumber(6, MaxTime);
      AcceptScreen;
      Th0 := GetNumber(1);
      ThDot0 := GetNumber(2);
      Ph0 := GetNumber(3);
      PhDot0 := GetNumber(4);
      MaxAngles := GetNumber(5);
      MaxTime := GetNumber(6);
      Done;
   END;
   DefineViewPort(2, 0.05, 0.9, 0.1, 0.9);
   DefineScale(2, 0, MaxTime, -MaxAngles, MaxAngles);
   GraphBackColor := DarkGray;
   ClearMuppetPort;
   OpenViewPort(2);
   SelectScale(2);
   SetColor(White);
   PrintXY(0.1, 0.92, 'Pitch');
   SetColor(LightBlue);
   PrintXY(0.2, 0.92, 'Roll');
   Axis(0, 0, 1, 10);
   y[1] := Th0*Pi/180;
   y[2] := Ph0*Pi/180;
   y[3] := ThDot0*Pi/180;
   y[4] := PhDot0*Pi/180;
   Time := 0;
   TimeOld := 0;
   ThOld := y[1]*180/Pi;
   PhiOld := y[2]*180/Pi;
   StepSize := 0.1;
   HideMouse;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      SetColor(White);PlotLine(TimeOld, ThOld, Time, y[1]*180/Pi);
      SetColor(LightBlue);PlotLine(TimeOld, PhiOld, Time, y[2]*180/Pi);
      TimeOld := Time;
      ThOld := y[1]*180/Pi;
      PhiOld := y[2]*180/Pi;
   UNTIL (Time > MaxTime) OR (Abs(ThOld) > 2*MaxAngles)
                          OR (Abs(PhiOld) > 2*MaxAngles);
   ShowMouse;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte; 
                        VAR Fire, PlotOrbit: Boolean);
VAR
   DelLag          : Integer;
BEGIN
   DelLag := 20;
      CASE Key OF
          1: BEGIN
                DataIn := False;
                PlotOrbit := False;
                Fire := False;
                Pause := True;
                WITH HotKeys DO Key[2] := 'F3-Run';
                HotKeys.BackColor := Blue;
                HotKeys.Display;
                IF KeyData THEN KeyAimAndFire ELSE Sliding := True;
             END;
           2: BEGIN
              {IF DataIn THEN }
              IF NOT Fire THEN
              BEGIN
                 Fire := True;
                 PlotOrbit := True;
                 Sliding := False;
                 RunOrbit;
                 RubOut(4, 1, 62, Black);
                 RubOut(4, 2, 20, Black);
              END;
              BEGIN
                IF Pause THEN
                BEGIN
                   Pause := False;
                   HotKeys.BackColor := Green;
                   WITH HotKeys DO Key[2] := 'F3-Stop';
                   HotKeys.Display;
                END
                ELSE
                BEGIN
                   Pause := True;
                   HotKeys.BackColor := Red;
                   WITH HotKeys DO Key[2] := 'F3-Run';
                   HotKeys.Display;
                END;
             END; 
             END;
          3: IF Lag > DelLag THEN Lag := Lag - DelLag ELSE Lag := 0;
          4: Lag := Lag + DelLag;
          5: BEGIN
                PlotOrbit := False;
                Pause := True;
                Sliding := False;
                HotKeys.Clear;
                LightMenu := True;
             END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleSeasickMenu;
BEGIN
   With SeasickMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            2: ShowHelp('HelpMisc.hlp', 'SeasickAboutProgram');
            1: AboutCUPS;
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpMisc.hlp', 'SeasickAboutModelA');
                  ShowHelp('HelpMisc.hlp', 'SeasickAboutModelB');
                  ShowHelp('HelpMisc.hlp', 'SeasickAboutModelC');
               END;
            2: BEGIN
                  ShowHelp('WalkThru.hlp', 'Seasick1');
                  ShowHelp('WalkThru.hlp', 'Seasick2');
               END;
         END;
      3: CASE RowChosen OF
            1: GetSeasickData;
            2: SetUpPicture;
            3: TimePlots;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   PitchFreq := 1;
   RollFreq := 0.49;
   PitchRes := 0.001;
   RollRes := 0.001;
   SeaFreq := 0.51;
   PitchSeaAmp := 0.001;
   RollSeaAmp := 0.001;
   ExitRequest := False;
   DefineViewPort(1, 0.15, 1, 0.07, 0.95);
   DefineScale(1, 0, 20, 0, 16);
   Lag := 200;
   PitchAngle := 10;
   RollAngle := 0;
   PitchCouple := 1;
   RollCouple := 1;
   Sliders.Init;
   Sliding := False;
   Hello('HelpMisc.hlp', 'SeasickAboutProgram');
   DataIn := False;
   Pause := True;
   SetUpSeasickMenu;
   Th0 := 10;
   ThDot0 := 0;
   Ph0 := 0;
   PhDot0 := 0;
   MaxAngles := 20;
   MaxTime := 100;
   LightMenu := True;
END;

{-------------------------------------------------------------------------}

BEGIN {Main program.}
   CUPSInit;
   GetSetUp;
   GetSeasickData;
   REPEAT
      CheckForEvents;
      IF Hotkeys.Pressed(Key) THEN
                  HandleHotKeys(Key, Fire, PlotOrbit);
      IF Sliding AND Sliders.Changed THEN HandleSliders;
      IF PlotOrbit AND (NOT Pause) THEN TakeStep;
      IF MayDay THEN Sink;
      IF LightMenu THEN IF SeasickMenu.Chosen THEN HandleSeasickMenu;
   UNTIL ExitRequest;
   SeasickMenu.Done;
   Sliders.Done;
   CUPSDone;
END.




