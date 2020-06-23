PROGRAM TheSpreadOfMalaria;

USES Crt, Graph, CUPSMUPP, CUPS, CupsGui;


CONST
   neq = 4;

TYPE
   Vector = Array[1..neq] OF real;

VAR
   MalariaMenu                         : TMenu;
   HotKeys                             : THotKeys;
   Key                                 : Byte;
   y                                   : Vector;
   Infect, Recover, Birth, Death       : Array[1..2] OF Real;
   Population, Infected                : Array[1..2] OF Real;
   MaxPopulation                       : Array[1..2] OF Real;
   Colors                              : Array[1..4] OF Word;
   Birth2, MaxM2, Phase1, Phase2       : Real;
   Period                              : Real;
   Bite                                : Real;
   Time0, Time1                        : Real;
   LightMenu, ExitRequest              : Boolean;

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

PROCEDURE SetUpMalariaMenu;
VAR
   I      : Integer;
BEGIN
   With MalariaMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'About the model');
       row(2,2, 'Population growth');
       row(2,3, 'Walk-through');
      Column(3, 'Parameters');
       row(3,1, 'Parameters for the model');
       row(3,2, 'Parameters for the graph');
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
   MalariaMenu.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(3);
      Key[1] := 'F2-Re-Run';
      Key[2] := 'F3-New Time';
      Key[3] := 'F10-Menu';
   END;
END;

{----------------------------------------------------------------------}

FUNCTION Parameters1: Boolean;
VAR
   Input          : TInputScreen;
   i              : Integer;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.08, 0.92, 0.13, 0.87);
      LoadLine('');
      LoadLine('              Parameters for the spread of malaria');
      LoadLine('');
      LoadLine('                  Humans                  Mosquitos');
      LoadLine('  Proportion of those infected who are infectious. Limits 0, 1:');
      LoadLine('                {       }                  {       }');
      LoadLine('  Recovery rate. Limits 0, 50:');
      LoadLine('                {       }                  {       }');
      LoadLine('  Death rate from malaria. Limits 0, 50:');
      LoadLine('                {       }                  {       }');
      LoadLine('  Rate at which mosquitos bite. Limits 0, 50:');
      LoadLine('                                           {       }');
      LoadLine('  (Birth rate - natural death rate). Limits 0, 50:');
      LoadLine('                {       }   ');
      LoadLine('');
      LoadLine('                     [  OK  ]         [Cancel]');
      FOR I := 1 TO 2 DO
      BEGIN
         SetNumber(I, Infect[I]);
         SetNumberLimits(I, 0, 1);
         SetNumber(I+2, Recover[I]);
         SetNumberLimits(I+2, 0, 50);
         SetNumber(I+4, Death[I]);
         SetNumberLimits(I+6, 0, 50);
      END;
      SetNumber(7, Bite);
      SetNumberLimits(7, 0, 50);
      SetNumber(8, Birth[1]);
      SetNumberLimits(8, 0, 50);
      AcceptScreen;
      Parameters1 := NOT Canceled;
      IF Canceled THEN BEGIN Done; Exit; END;
      FOR I := 1 TO 2 DO
      BEGIN
         Infect[I] := GetNumber(I);
         Recover[I] := GetNumber(I+2);
         Death[I] := GetNumber(I+4);
      END;
      Bite := GetNumber(7);
      Birth[1] := GetNumber(8);
      Done;
   END;
END;

{----------------------------------------------------------------------}

FUNCTION Parameters2: Boolean;
VAR
   Input          : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.02, 0.98);
      LoadLine('');
      LoadLine('         Parameters for the spread of malaria');
      LoadLine('');
      LoadLine('     You have the option of having the birth rate');
      LoadLine('  of mosquitos, and their maximum sustainable');
      LoadLine('  population, varying periodically, with period P.');
      LoadLine('  The form is:');
      LoadLine('        Birth-rate = B0 + B1*Cos((2*Pi/P)*t - B2).');
      LoadLine('Maximum population = M0 + M1*Cos((2*Pi/P)*t - M2).');
      LoadLine('');
      LoadLine('     Enter values for the parameters. B0 and B1');
      LoadLine('  should be positive, with B1 <= 2*B0 <= 50.');
      LoadLine('          B0 = {       }     B1 = {       }');
      LoadLine('     Enter values for the parameters. B0 and B1');
      LoadLine('  should be positive, with M0 <= 100, M1 <= 50.');
      LoadLine('          M0 = {       }     M1 = {       }');
      LoadLine('     Enter values for the phase constants, ');
      LoadLine('          B2 = {       }     M2 = {       }');
      LoadLine('     Enter a value for the period,');
      LoadLine('            0.1 <=  P = {       } <= 20');
      LoadLine('');
      LoadLine('               [  OK  ]         [Cancel]');
      SetNumber(1, Birth[2]);
      SetNumberLimits(1, 0, 50);
      SetNumber(2, Birth2);
      SetNumberLimits(2, 0, 100);
      SetNumber(3, MaxPopulation[2]);
      SetNumberLimits(3, 0, 100);
      SetNumber(4, MaxM2);
      SetNumberLimits(4, 0, 50);
      SetNumber(5, Phase1);
      SetNumber(6, Phase2);
      SetNumber(7, Period);
      SetNumberLimits(7, 0, 20);
      REPEAT
         AcceptScreen;
         Parameters2 := NOT Canceled;
         IF NOT Canceled THEN
         BEGIN
            Birth[2] := GetNumber(1);
            Birth2 := GetNumber(2);
            MaxPopulation[2] := GetNumber(3);
            MaxM2 := GetNumber(4);
            Phase1 := GetNumber(5);
            Phase2 := GetNumber(6);
            Period := GetNumber(7);
         END;
         IF (MaxM2 > MaxPopulation[2]) AND (Birth2 > 2*Birth[2])
         THEN Announce('Please follow the inequalities. Try again!');
      UNTIL (MaxM2 <= MaxPopulation[2]) AND (Birth2 <= 2*Birth[2])
         OR Canceled;
      Done;
   END;
END;

{----------------------------------------------------------------------}

FUNCTION Initialize : Boolean;
VAR
   Input        : TInputScreen;
   I            : Integer;
   DataOK       : Boolean;
BEGIN
   REPEAT
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.11, 0.89, 0.15, 0.85);
         LoadLine('');
         LoadLine('  The models for populationg growth are logistic.');
         LoadLine('  Enter maximum human population that can be sustained.');
         LoadLine('  Limits 0, 100.');
         LoadLine('      Humans: {     } ');
         LoadLine('');
         LoadLine('  Enter values for the initial populations. Limits 0, 100:');
         LoadLine('      Humans: {     }     Mosquitos: {     }');
         LoadLine('');
         LoadLine('  Enter values for those initially infected:');
         LoadLine('      Humans: {     }     Mosquitos {     }');
         LoadLine('');
         LoadLine('  The starting time will be t0 = 0. Enter a value for the');
         LoadLine('  final time: t1 = {      }');
         LoadLine('');
         LoadLine('            [  OK  ]           [Cancel]');
         SetNumber(1, MaxPopulation[1]);
            SetNumberLimits(1, 0, 100);
         FOR I := 1 TO 2 DO
         BEGIN
            SetNumber(I+1, Population[I]);
            SetNumberLimits(I+1, 0, 100);
            SetNumber(I+3, Infected[I]);
            SetNumberLimits(I+1, 0, 100);
         END;
         SetNumber(6, Time1);
         SetNumberLimits(6, 0, 10000);
         AcceptScreen;
         Initialize := NOT Canceled;
         IF Canceled THEN BEGIN Done; Exit; END;
         MaxPopulation[1] := GetNumber(1);
         FOR I := 1 TO 2 DO
         BEGIN
            Population[I] := GetNumber(I+1);
            Infected[I] := GetNumber(I+3);
         END;
         Time1 := GetNumber(6);
         Done;
      END;
      DataOK := True;
      IF (Infected[1] >= Population[1]) OR (Infected[2] >= Population[2])
      THEN
      BEGIN
         DataOK := False;
         Announce('Those infected must be fewer than the population. Try again.');
      END;
      IF Time1 = 0 THEN
      BEGIN
         DataOK := False;
         Announce('The final time cannot also be zero. Try again.');
      END;
   UNTIL DataOK;
   y[1] := Infected[1];
   y[2] := Infected[2];
   y[3] := Population[1];
   y[4] := Population[2];
   Time0 := 0;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
VAR
   MBirthRate       : Real;
BEGIN
{y[1] is the number of infected humans.
 y[2] is the number of infected mosquitos.
 y[3] is the population of humans.
 y[4] is the population of mosquitos.}
   MBirthRate := Birth[2] + Birth2*Cos((2*Pi/Period)*x - Phase1);
   z[1] := Bite*Infect[2]*y[2]*(y[3] - y[1])/y[3]
           - (Recover[1] + Death[1])*y[1];
   z[2] := Bite*Infect[1]*y[1]*(y[4] - y[2])/y[3]
           - (Recover[2] + Death[2])*y[2];
   z[3] := Birth[1]*(MaxPopulation[1] - y[3])*y[3] - Death[1]*y[1];
   z[4] := MBirthRate*(MaxPopulation[2]+MaxM2*Cos((2*Pi/Period)*x - Phase2)
           - y[4])*y[4] - Death[2]*y[2];
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

{----------------------------------------------------------------------}

PROCEDURE SetUpScreen;
BEGIN
   ClearMuppetPort;
   PrintXY(0.23, 0.9, 'Humans');
   PrintXY(0.7, 0.9, 'Mosquitos');
   SetColor(Colors[3]);
   PrintXY(0.1, 0.85, 'Population');
   SetColor(Colors[1]);
   PrintXY(0.3, 0.85, 'Infected');
   SetColor(Colors[4]);
   PrintXY(0.6, 0.85, 'Population');
   SetColor(Colors[2]);
   PrintXY(0.8, 0.85, 'Infected');
   OpenViewPort(1);
   IF y[3] < MaxPopulation[1] THEN
      DefineScale(1, Time0, Time1, 0, 1.1*MaxPopulation[1])
      ELSE
      DefineScale(1, Time0, Time1, 0, 1.1*y[3]);
   SelectScale(1);
   setColor(White);
   Axis(Time0, 0, 1, 1);
   OpenViewPort(2);
   DefineScale(2, Time0, Time1, 0, 1.1*(MaxPopulation[2]+ MaxM2));
   SelectScale(2);
   Axis(Time0, 0, 1, 1);
   LightMenu := False;
   HotKeys.Display;
END;

{----------------------------------------------------------------------}

PROCEDURE PlotSolutions;
VAR
   StepSize, Time                      : Real;
   yOld                                : Array[1..4] OF Real;
   I                                   : Integer;
   TimeOld                             : Real;
BEGIN
   HideMouse;
   Time := Time0;
   TimeOld := Time;
   StepSize := 0.1;
   FOR I := 1 TO 4 DO yOld[I] := y[I];
   REPEAT
      Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
      FOR I := 1 TO 4 DO
      BEGIN
         IF (I = 1) OR (I = 3) THEN
         BEGIN
            SelectViewPort(1);
            SelectScale(1);
         END
         ELSE
         BEGIN
            SelectViewPort(2);
            SelectScale(2);
         END;
         SetColor(Colors[I]);
         PlotLine(TimeOld, Yold[I], Time, y[I]);
         YOld[I] := y[I];
      END;
      TimeOld := Time;
   UNTIL (Time > Time1) OR KeyPressed;
   ShowMouse;
END;

{-------------------------------------------------------------------------}

FUNCTION SetNewTimeLimits: Boolean;
VAR
   Input       : TInputScreen;
   Quit        : Boolean;
BEGIN

      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.26, 0.74, 0.28, 0.72);
         LoadLine('');
         LoadLine('     Values of T0 and T1 for are');
         LoadLine('  needed for continuing the plot:');
         LoadLine('  The new value of T0 is the old');
         LoadLine('  T1, so T0 = ' + NumStr(Time1, 4,1));
         LoadLine('  Enter a value of T1 > T0:');
         LoadLine('         T1 = {       }');
         LoadLine('');
         LoadLine('        [  OK  ]    [Cancel]');
         SetNumber(1, Time1 + 10);
         SetNumberLimits(1, Time1+0.000001, 10000000);
         AcceptScreen;
         Quit := Canceled;
         SetNewTimeLimits := NOT Canceled;
         IF NOT Canceled THEN
         BEGIN
            Time0 := Time1;
            Time1 := GetNumber(1);
         END;
         Done;
      END;
END;

{----------------------------------------------------------------------}

PROCEDURE HandleMalariaMenu;
BEGIN
   With MalariaMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpGono.Hlp', 'MalariaAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: BEGIN
                  ShowHelp('HelpGono.Hlp', 'MalariaAboutModel1');
                  ShowHelp('HelpGono.Hlp', 'MalariaAboutModel2');
                  ShowHelp('HelpGono.Hlp', 'MalariaAboutModel3');
               END;
            2: BEGIN
                  ShowHelp('HelpGono.Hlp', 'MalariaAboutPopulationGrowth1');
                  ShowHelp('HelpGono.Hlp', 'MalariaAboutPopulationGrowth2');
               END;
            3: BEGIN
                  ShowHelp('WalkThru.Hlp', 'Malaria1');
                  ShowHelp('WalkThru.Hlp', 'Malaria2');
                  ShowHelp('WalkThru.Hlp', 'Malaria3');
                  ShowHelp('WalkThru.Hlp', 'Malaria4');
               END;
         END;
      3: CASE RowChosen OF
            1: BEGIN
                  IF Parameters1 THEN
                  BEGIN
                     IF Parameters2 AND Initialize THEN
                     BEGIN
                        SetUpScreen;
                        PlotSolutions;
                     END;
                  END;
               END;
            2: IF Initialize THEN
               BEGIN
                  SetUpScreen;
                  PlotSolutions;
               END;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE RePlotSolutions;
BEGIN
   y[1] := Infected[1];
   y[2] := Infected[2];
   y[3] := Population[1];
   y[4] := Population[2];
   SetUpScreen;
   PlotSolutions;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
BEGIN
   CASE Key OF
      1: RePlotSolutions;
      2: IF SetNewTimeLimits THEN
         BEGIN
            SetUpScreen;
            PlotSolutions;
         END;
      3: BEGIN
            HotKeys.Clear;
            ClearMuppetPort;
            LightMenu := True;
         END;
   END;
END;

{----------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.05, 0.48, 0.1, 0.8);
   DefineViewPort(2, 0.55, 0.98, 0.1, 0.8);
   Infect[1] := 1;
   Infect[2] := 1;
   Recover[1] := 1.0;
   Recover[2] := 0.1;
   Birth[1] := 0.01;
   Birth[2] := 1;
   Death[1] := 0.1;
   Death[2] := 1;
   Bite := 1;
   MaxPopulation[1] := 50;
   MaxPopulation[2] := 50;
   Population[1] := 20;
   Population[2] := 20;
   Infected[1] := 10;
   Infected[2] := 10;
   MaxM2 := 0;
   Birth2 := 0;
   Period := 1;
   Phase1 := 0;
   Phase2 := 0;
   Time0 := 0;
   Time1 := 10;
   Colors[1] := Cyan;
   Colors[2] := Yellow;
   Colors[3] := LightBlue;
   Colors[4] := Green;
   SetUpHotKeys;
   Hello('HelpGono.Hlp', 'MalariaAboutProgram');
   SetUpMalariaMenu;
   ExitRequest := False;
   LightMenu := True;
END;

{----------------------------------------------------------------------}

BEGIN
   CUPSInit;
   GetSetUp;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF LightMenu AND MalariaMenu.Chosen THEN HandleMalariaMenu;
   UNTIL ExitRequest;
   MalariaMenu.Done;
   CUPSDone;
END.
