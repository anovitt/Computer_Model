PROGRAM TheSpreadOfDisease;

USES Crt, Graph, CUPSMUPP, CUPS, CupsGui;


CONST
   neq = 5;

TYPE
   vector = array[1..neq] of real;

VAR
   y, z                            : Vector;
   Time, NextTime                  : Real;
   StepSize                        : Real;
   yInit                           : Vector;
   DiseaseMenu                     : TMenu;
   HotKeys, PHotKeys               : THotKeys;
   Button1, Button2, Button3       : TButtons;
   Button4, Button5, Button6       : TButtons;
   Key                             : Byte;
   Vaccination                     : Boolean;
   Incubation                      : Boolean;
   BirthDeath                      : Boolean;
   PeriodicInfection               : Boolean;
   Check                           : Boolean;
   PhasePlane                      : Boolean;
   Poincare                        : Boolean;
   Action, Pause                   : Boolean;
   KeyInitialConditions            : Boolean;
   InputNeeded                     : Boolean;
   InfectionRate0                  : Real;
   InfectionPeriod                 : Real;
   InfectionRate1                  : Real;
   CureRate                        : Real;
   IncubationRate                  : Real;
   VaccinationRate                 : Real;
   xDiv, yDiv                      : Real;
   Birth, Death                    : Vector;
   VaccinationPower                : Integer;
   S0, E0, I0                      : Real;
   T0, T1                          : Real;
   MaxCoord                        : Real;
   Population                      : Real;
   xMax, yMax                      : Real;
   xOld, yOld                      : Real;
   ExitRequest                     : Boolean;
   LightMenu                       : Boolean;

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

PROCEDURE SetUpDiseaseMenu;
VAR
   I      : Integer;
BEGIN
   With DiseaseMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Variables');
       row(2,2, 'Basic model');
       row(2,3, 'Vaccination');
       row(2,4, 'Incubation');
       row(2,5, 'Cyclic infection');
       row(2,6, 'Birth and death');
       row(2,7, 'Walk-through');
       row(2,8, 'Change maximum coordinate');
      Column(3, 'Parameters');
       row(3,1, 'Enter options');
       row(3,2, 'Infection and cure rates');
       row(3,3, 'Vaccination');
       row(3,4, 'Incubation');
       row(3,5, 'Birth and Death');
      Column(4, 'Display');
       row(4,1, 'Graph parameters');
       row(4,2, 'Time plots');
       row(4,3, 'Phase-plane S-I plots');
       Display;
      FOR I := 1 TO 4 DO AutoChecking(I, 1);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(4);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Re-Run';
      Key[3] := 'F3-New Time';
      Key[4] := 'F10-Menu';
   END;
   HotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpPHotKeys;
BEGIN
   WITH PHotKeys DO
   BEGIN
      PHotKeys.Init(5);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Input';
      Key[4] := 'F4-ResScale';
      Key[5] := 'F10-Menu';
   END;
   PHotKeys.Display;
END;

{------------------------------------------------------------------------}

PROCEDURE SetMaximumCoordinate;
VAR
   MaxScreen    : TInputScreen;
BEGIN
   WITH MaxScreen DO
   BEGIN
      Init;
      DefineInputPort(0.12, 0.88, 0.08, 0.92);
      LoadLine('');
      LoadLine('     Numbers for populations in various categories can');
      LoadLine('  be scaled. For instance, the number 2 might indicate');
      LoadLine('  that 2,000 people were infected. Things work best if');
      LoadLine('  the numbers used are of the order of ten or less.');
      LoadLine('');
      LoadLine('     However, some numbers may grow unexpectedly, if');
      LoadLine('  birth and death are included. The program will stop');
      LoadLine('  a calculation if a specific number is exceeded. Only');
      LoadLine('  calculated values up to that point will be shown.');
      LoadLine('');
      LoadLine('     Enter a value for this number:');
      LoadLine('                  10 <= {     } <= 1000');
      LoadLine('');
      LoadLine('     If you wish to change this during the running of');
      LoadLine('  the program, select <Change maximum coordinate> from');
      LoadLine('  the <Help> menu.');
      LoadLine('');
      LoadLine('                        [  OK  ]');
      SetNumber(1, MaxCoord);
      SetNumberLimits(1, 10, 1000);
      AcceptScreen;
      MaxCoord := GetNumber(1);
      Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION SetOptions : Boolean;
VAR
   OptionInput        : TInputScreen;
   I                  : Integer;
BEGIN
   WITH OptionInput DO
   BEGIN
      Init;
      DefineInputPort(0.2, 0.8, 0.26, 0.7);
      LoadLine('');
      LoadLine('     Select those of the following options');
      LoadLine('  that you wish to use:');
      LoadLine('     Vaccination:         #1 Yes    #1 No');
      LoadLine('     Incubation:          #2 Yes    #2 No');
      LoadLine('     Periodic infection:  #3 Yes    #3 No');
      LoadLine('     Birth and Death:     #4 Yes    #4 No');
      LoadLine('');
      LoadLine('    [ Help ]    [  OK  ]    [Cancel]');
      SetHelpFile('HelpGono.Hlp', 'DisaeaseCategories');
      IF Vaccination THEN
         SetRadioButton('1', 1) ELSE SetRadioButton('1', 2);
      IF Incubation THEN
         SetRadioButton('2', 1) ELSE SetRadioButton('2', 2);
      IF PeriodicInfection THEN
         SetRadioButton('3', 1) ELSE SetRadioButton('3', 2);
      IF BirthDeath THEN
         SetRadioButton('4', 1) ELSE SetRadioButton('4', 2);
      AcceptScreen;
      SetOptions := NOT Canceled;
      IF GetRadioButton('1') = 1
         THEN Vaccination := True ELSE Vaccination := False;
      IF GetRadioButton('2') = 1
         THEN Incubation := True ELSE Incubation := False;
      IF GetRadioButton('3') = 1
         THEN PeriodicInfection := True ELSE PeriodicInfection := False;
      IF GetRadioButton('4') = 1
         THEN BirthDeath := True ELSE BirthDeath := False;
      Done;
   END;
      IF Vaccination THEN DiseaseMenu.RowActivate(3,3, True)
                     ELSE DiseaseMenu.RowActivate(3,3, False);
      IF Incubation THEN DiseaseMenu.RowActivate(3,4, True)
                    ELSE DiseaseMenu.RowActivate(3,4, False);
      IF BirthDeath THEN DiseaseMenu.RowActivate(3,5, True)
                    ELSE DiseaseMenu.RowActivate(3,5, False);
      DiseaseMenu.RowActivate(4,2, False);
      IF NOT Vaccination THEN VaccinationRate := 0;
      IF NOT Incubation THEN IncubationRate := 0;
      IF NOT BirthDeath THEN
      BEGIN
         FOR I := 1 TO 5 DO
         BEGIN
            Birth[I] := 0;
            Death[I] := 0;
         END
         ELSE
         BEGIN
            Birth[1] := 3; Death[1] := 2.4;
            Birth[2] := 0; Death[2] := 1;
            Birth[3] := 0; Death[3] := 3;
            Birth[4] := 0; Death[4] := 3;
            Birth[5] := 0; Death[5] := 1;
         END;
      END;
END;

{------------------------------------------------------------------------}

FUNCTION Input1 : Boolean;
VAR
   Input            : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
     Init;
     DefineInputPort(0.19, 0.81, 0.22, 0.78);
     LoadLine('');
     LoadLine('     If the number of susceptibles is S, then');
     LoadLine('  the rate of infection is aS. Enter a value');
     LoadLine('  for a between 0 and 10:');
     LoadLine('                   a = {       }');
     LoadLine('');
     LoadLine('     If the number of infectives is I, then');
     LoadLine('  the rate of curing is bI. Enter a value for');
     LoadLine('  b, between 0 and 10:');
     LoadLine('                   b = {       }');
     LoadLine('');
     LoadLine('    [ Help ]      [  OK  ]     [Cancel]');
     SetHelpFile('HelpGono.Hlp', 'DisaeaseBasicModel');
     SetNumber(1, InfectionRate0);
     SetNumber(2, CureRate);
     SetNumberLimits(1, 0, 10);
     SetNumberLimits(2, 0, 10);
     AcceptScreen;
     Input1 := NOT Canceled;
     IF NOT Canceled THEN
     BEGIN
        InfectionRate0 := GetNumber(1);
        CureRate := GetNumber(2);
        VaccinationRate := 0;
        InfectionRate1 := 0;
     END;
     Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION Input2 : Boolean;
VAR
   Input            : TInputScreen;
BEGIN
   REPEAT
      WITH Input DO
      BEGIN
        Init;
        DefineInputPort(0.18, 0.82, 0.15, 0.85);
        LoadLine('');
        LoadLine('     If the number of susceptibles is S, then');
        LoadLine('  the rate of infection is');
        LoadLine('   (a0 + a1*Sin(2*Pi*t/P))S, where a1 <= a0.');
        LoadLine('  t is the time. P is the period of the varying');
        LoadLine('  infectiousness. 0 <= a0, a1, <= 10.');
        LoadLine('  Enter values:');
        LoadLine('  a0 = {       }, a1 = {       }, P = {       }.');
        LoadLine('');
        LoadLine('     If the number of infectives is I, then');
        LoadLine('  the rate of curing is bI. Enter a value for');
        LoadLine('  b, between 0 and 10:');
        LoadLine('                   b = {       }');
        LoadLine('');
        LoadLine('       [ Help ]     [  OK  ]     [Cancel]');
        SetHelpFile('HelpGono.Hlp', 'DisaeasePeriodicInfection');
        SetNumber(1, InfectionRate0);
        SetNumber(2, InfectionRate1);
        SetNumber(3, InfectionPeriod);
        SetNumber(4, CureRate);
        SetNumberLimits(1, 0, 10);
        SetNumberLimits(2, 0, 10);
        SetNumberLimits(3, 0, 1000000);
        SetNumberLimits(4, 0, 10);
        AcceptScreen;
        Input2 := NOT Canceled;
        IF NOT Canceled THEN
        BEGIN
           InfectionRate0 := GetNumber(1);
           InfectionRate1 := GetNumber(2);
           InfectionPeriod := GetNumber(3);
           CureRate := GetNumber(4);
        END;
        Done;
      END;
      IF InfectionRate0 < InfectionRate1 THEN
         Announce('Make a1 less than a0. Try again.');
   UNTIL InfectionRate0 >= InfectionRate1;
END;

{------------------------------------------------------------------------}

FUNCTION Input3 : Boolean;
VAR
   Input            : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
     Init;
     DefineInputPort(0.17, 0.83, 0.06, 0.9);
     LoadLine('');
     LoadLine('     S is the number of susceptibles.');
     LoadLine('     D is the number infected, but not yet');
     LoadLine('  infectious.');
     LoadLine('     I is the number of infectives.');
     LoadLine('  Then');
     LoadLine('               S'' = - a*S*I,');
     LoadLine('               D'' = a*S*I - d*D,');
     LoadLine('               I'' = d*D - b*I.');
     LoadLine('');
     LoadLine('    (These can be modified to include birth,');
     LoadLine('  death and vaccination.)');
     LoadLine('');
     LoadLine('    Values for a, the rate of infection, and b,');
     LoadLine('  the rate of cure, are entered in another input');
     LoadLine('  screen. Enter a value for d, between 0 and 10:');
     LoadLine('                   d = {       }');
     LoadLine('');
     LoadLine('            [  OK  ]          [Cancel]');
     SetNumber(1, IncubationRate);
     SetNumberLimits(1, 0, 10);
     AcceptScreen;
     Input3 := NOT Canceled;
     IF NOT Canceled THEN
     BEGIN
        IncubationRate := GetNumber(1);
     END;
     Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION Input4 : Boolean;
VAR
   Input            : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
     Init;
     DefineInputPort(0.19, 0.81, 0.22, 0.78);
     LoadLine('');
     LoadLine('     If the number of susceptibles is S, and');
     LoadLine('  the number of infectives is I, then the');
     LoadLine('  vaccination rate is expressed as');
     LoadLine('                  c*S*I^k,');
     LoadLine('  where c lies between 0 and 10 and k can');
     LoadLine('  take one of the values 0, 1, 2.');
     LoadLine('');
     LoadLine('     Enter values:');
     LoadLine('            c = {       }, k = { }.');
     LoadLine('');
     LoadLine('      [ Help ]     [  OK  ]     [Cancel]');
     SetHelpFile('HelpGono.Hlp', 'DisaeaseVaccination');
     SetNumber(1, VaccinationRate);
     SetNumber(2, VaccinationPower);
     SetNumberLimits(1, 0, 10);
     SetNumberLimits(2, 0, 2);
     AcceptScreen;
     Input4 := NOT Canceled;
     IF NOT Canceled THEN
     BEGIN
        VaccinationRate := GetNumber(1);
        VaccinationPower := Trunc(GetNumber(2) + 0.1);
     END;
     Done;
   END;
END;

{------------------------------------------------------------------------}

FUNCTION Input5 : Boolean;
VAR
   Input            : TInputScreen;
   i                : Integer;
BEGIN
   WITH Input DO
   BEGIN
     Init;
     DefineInputPort(0.12, 0.88, 0.08, 0.92);
     LoadLine('');
     LoadLine('     Enter birth and death rates, between 0 and 5, for:');
     LoadLine('');
     LoadLine('  Those who are susceptible:');
     LoadLine('          Birth: {       }    Death: {       }');
     LoadLine('');
     LoadLine('  Those who are diseased and infectious:');
     LoadLine('          Birth: {       }    Death: {       }');
     LoadLine('');
     LoadLine('  Those who have been cured, and are immune:');
     LoadLine('          Birth: {       }    Death: {       }');
     LoadLine('');
     IF Vaccination THEN
     BEGIN
        LoadLine('  Those who have been vaccinated:');
        LoadLine('          Birth: {       }    Death: {       }');
        LoadLine('');
     END;
     IF Incubation THEN
     BEGIN
        LoadLine('  Those who have the disease but are not yet infectious:');
        LoadLine('          Birth: {       }    Death: {       }');
        LoadLine('');
     END;
     LoadLine('       [ Help ]      [  OK  ]      [Cancel]');
     SetHelpFile('HelpGono.Hlp', 'DiseaseBirthDeath');
     SetNumber(1, Birth[1]);
     SetNumber(2, Death[1]);

     SetNumber(3, Birth[4]);
     SetNumber(4, Death[4]);
     SetNumber(5, Birth[5]);
     SetNumber(6, Death[5]);
     IF Vaccination THEN
     BEGIN
        SetNumber(7, Birth[2]);
        SetNumber(8, Death[2]);
     END;
     IF Vaccination AND Incubation THEN
     BEGIN
        SetNumber(9, Birth[3]);
        SetNumber(10, Death[3]);
     END;
     IF (NOT Vaccination) AND Incubation THEN
     BEGIN
        SetNumber(7, Birth[3]);
        SetNumber(8, Death[3]);
     END;
     FOR I := 1 TO 6 DO
        SetNumberLimits(i, 0, 5);
     IF Vaccination OR Incubation THEN
     BEGIN
        SetNumberLimits(7, 0, 5);
        SetNumberLimits(8, 0, 5);
     END;
     IF Vaccination AND Incubation THEN
     BEGIN
        SetNumberLimits(9, 0, 5);
        SetNumberLimits(10, 0, 5);
     END;
     AcceptScreen;
     Input5 := NOT Canceled;
     IF NOT Canceled THEN
     BEGIN
        Birth[1] := GetNumber(1);
        Death[1] := GetNumber(2);

        Birth[4] := GetNumber(3);
        Death[4] := GetNumber(4);
        Birth[5] := GetNumber(5);
        Death[5] := GetNumber(6);
        IF Vaccination THEN
        BEGIN
           Birth[2] := GetNumber(7);
           Death[2] := GetNumber(8);
        END;
        IF Vaccination AND Incubation THEN
        BEGIN
           Birth[3] := GetNumber(9);
           Death[3] := GetNumber(10);
        END;
        IF (NOT Vaccination) AND Incubation THEN
        BEGIN
           Birth[3] := GetNumber(7);
           Death[3] := GetNumber(8);
        END;
     END;
     Done;
   END;
END;


{------------------------------------------------------------------------}

PROCEDURE SetParameters;
BEGIN
   IF SetOptions THEN
   BEGIN
      IF PeriodicInfection THEN
      BEGIN
         IF (NOT Input2) THEN Exit
      END
      ELSE
      BEGIN
         IF (NOT Input1) THEN Exit;
      END;
      IF Incubation THEN IF NOT Input3 THEN Exit;
      IF Vaccination THEN IF NOT Input4 THEN Exit;
      IF BirthDeath THEN IF NOT Input5 THEN Exit;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE Fun(x: Real; y: Vector; VAR z: Vector);
{Right hand sides of the differential equations.}
VAR
   InfectionRate       : Real;
   I                   : Integer;
BEGIN
   FOR I := 1 TO 5 DO IF y[I] < 0 THEN y[I] := 0;
   InfectionRate := InfectionRate0;
   IF PeriodicInfection THEN
      InfectionRate := InfectionRate + InfectionRate1*Sin(2*Pi*x/InfectionPeriod);
   z[2] := 0;
   IF Vaccination THEN
   BEGIN
      CASE VaccinationPower+1 OF
         1: z[2] := VaccinationRate*y[1];
         2: z[2] := VaccinationRate*y[1]*y[4];
         3: z[2] := VaccinationRate*y[1]*y[4]*y[4];
      END;
   END;
   z[1] := - InfectionRate*y[1]*y[4] - z[2];
   IF Incubation THEN
      z[3] := InfectionRate*y[1]*y[4] - IncubationRate*y[3]
   ELSE
      z[3] := 0;
   IF Incubation THEN
      z[4] := IncubationRate*y[3] - CureRate*y[4]
   ELSE
      z[4] := InfectionRate*y[1]*y[4] - CureRate*y[4];
   z[5] := CureRate*y[4];
   IF BirthDeath THEN
   BEGIN
      FOR I := 1 TO 5 DO
         z[1] := z[1] + Birth[I]*y[I];
      FOR I := 1 TO 5 DO
         z[I] := z[I] - Death[I]*y[I];
   END;
   FOR I := 1 TO 5 DO IF (y[I] <= 0) AND (z[I] < 0) THEN z[I] := 0;
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

PROCEDURE SetUpButtons;
BEGIN
   SetColor(White);
   PrintXY(0.0, 0.9, 'Susceptible');
   Button1.Create(1, 0.02, 0.85, 'y');
   Button1.Create(2, 0.08, 0.85, 'n');
   Button1.Number := 1;
   SetColor(Yellow);
   PrintXY(0.0, 0.75, 'Infective');
   Button4.Create(1, 0.02, 0.7, 'y');
   Button4.Create(2, 0.08, 0.7, 'n');
   Button4.Number := 1;
   SetColor(LightBlue);
   PrintXY(0.0, 0.6, 'Removed');
   Button5.Create(1, 0.02, 0.55, 'y');
   Button5.Create(2, 0.08, 0.55, 'n');
   Button5.Number := 1;
   IF Vaccination THEN
   BEGIN
      SetColor(Green);
      PrintXY(0.0, 0.45, 'Vaccinated');
   Button2.Create(1, 0.02, 0.4, 'y');
   Button2.Create(2, 0.08, 0.4, 'n');
   Button2.Number := 1;
   END;
   IF Incubation THEN
   BEGIN
      SetColor(LightCyan);
      PrintXY(0.0, 0.3, 'Incubated');
   Button3.Create(1, 0.02, 0.25, 'y');
   Button3.Create(2, 0.08, 0.25, 'n');
   Button3.Number := 1;
   END;
   IF BirthDeath THEN
   BEGIN
      SetColor(LightRed);
      PrintXY(0.0, 0.15, 'Population');
   Button6.Create(1, 0.02, 0.1, 'y');
   Button6.Create(2, 0.08, 0.1, 'n');
   Button6.Number := 1;
   END;
   Button1.DrawAll;
   IF Vaccination THEN Button2.DrawAll;
   IF Incubation THEN Button3.DrawAll;
   IF BirthDeath THEN Button6.DrawAll;
   Button4.DrawAll;
   Button5.DrawAll;

END;

{------------------------------------------------------------------------}

FUNCTION GetStarted : Boolean;
VAR
   Input    : TInputScreen;
   I        : Integer;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.2, 0.75);
      LoadLine('');
      LoadLine('    Enter initial values for:');
      LoadLine('     Sucsceptibles: {       }');
      LoadLine('        Infectives: {       }');
      LoadLine('  Don''t pick enormous values. The');
      LoadLine('  figures can be scaled.');
      LoadLine('');
      LoadLine('    The plot starts at time t0=0.');
      LoadLine(' Enter the final time, t1:');
      LoadLine('               t1 = {       }');
      LoadLine('');
      LoadLine('       [  OK  ]    [Cancel]');
      SetNumber(1, S0);
      SetNumberLimits(1, 0, 100000);
      SetNumber(2, I0);
      SetNumberLimits(2, 0, 100000);
      SetNumber(3, T1);
      SetNumberLimits(3, 0, 100000);
      AcceptScreen;
      GetStarted := NOT Canceled;
      IF NOT Canceled THEN
      BEGIN
         S0 := GetNumber(1);
         I0 := GetNumber(2);
         T1 := GetNumber(3);
         y[1] := S0;
         y[2] := 0;
         y[3] := 0;
         y[4] := I0;
         y[5] := 0;
         T0 := 0;
         Population := S0 + I0;
         FOR I := 1 TO 5 DO YInit[I] := y[I];
      END;
      Done;
   END;
   DiseaseMenu.RowActivate(4,2, True);
END;

{------------------------------------------------------------------------}

PROCEDURE FindScale;
VAR
   Time, StepSize     : Real;
   I                  : Integer;
   WaitMessage        : TWaitMessage;
BEGIN
   IF BirthDeath THEN
   BEGIN
      WaitMessage.Show;
      FOR I := 1 TO 5 DO y[I] := yInit[I];
      Population := y[1] + y[2] + y[3] + y[4] + y[5];
      Time := T0;
      StepSize := 0.1;
      REPEAT
         Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
         FOR I := 1 TO 5 DO IF y[i] < 0 THEN y[i] := 0;
         {IF (y[1] < 0) OR (y[2] < 0) OR (y[3] < 0) OR (y[4] < 0)
         OR (y[5] < 0) THEN PrintXY(0.1, 0.2, 'negative');}
         IF Population < y[1] + y[2] + y[3] + y[4] + y[5] THEN
            Population := y[1] + y[2] + y[3] + y[4] + y[5];
         WaitMessage.Update;
         {IF KeyPressed THEN
         BEGIN
            ClearMKBuffers;
            Exit;
         END; }
      UNTIL (Time > T1) OR (Population > MaxCoord);
      IF Population > MaxCoord THEN
      BEGIN
         T1 := Time;
         Population := MaxCoord;
      END;
      DefineScale(1, T0, (T1 - T0)*1.05, 0, Population*1.05);
      FOR I := 1 TO 5 DO y[I] := yInit[I];
      WaitMessage.Hide;
   END
   ELSE
      DefineScale(1, T0, T0 + (T1 - T0)*1.05, 0, (S0 + I0)*1.05);
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpScreen;
BEGIN
   ClearMuppetPort;
   FindScale;
   SetUpButtons;
   OpenViewPort(1);
   SelectScale(1);
   IF T1 - T0 > 10 THEN xDiv := 10 ELSE xDiv := 1;
   IF (Population) < 100 THEN yDiv := 10 ELSE yDiv := 100;
   IF (Population) < 10 THEN yDiv := 1;
   Axis(0, 0, xDiv, yDiv);
   SetUpHotKeys;
   LightMenu := False;
END;

{------------------------------------------------------------------------}

PROCEDURE PlotSolutions;
VAR
   y1Old, y2Old, y3Old, y4Old, y5Old     : Real;
   PopulationOld                         : Real;
   StepSize                              : Real;
   TimeOld, Time                         : Real;
   I                                     : Integer;
BEGIN
   FOR I := 1 TO 5 DO y[I] := yInit[I];
   y1Old := y[1];
   y2Old := y[2];
   y3Old := y[3];
   y4Old := y[4];
   y5Old := y[5];
   PopulationOld := y[1] + y[2] + y[3] + y[4] + y[5];
   Time := T0;
   TimeOld := Time;
   StepSize := 0.1;
   REPEAT
      Step(Time, StepSize, 0.0000001, y, Time, StepSize, y);
      FOR i := 1 TO 5 DO IF y[i] < 0 THEN y[i] := 0;
      SetColor(White);
      IF Button1.Number = 1 THEN
         PlotLine(TimeOld, y1Old, Time, y[1]);
      SetColor(Yellow);
      IF Button4.Number = 1 THEN
         PlotLine(TimeOld, y4Old, Time, y[4]);
      SetColor(LightBlue);
      IF Button5.Number = 1 THEN
         PlotLine(TimeOld, y5Old, Time, y[5]);
      SetColor(Green);
      IF Vaccination AND (Button2.Number = 1) THEN
         PlotLine(TimeOld, y2Old, Time, y[2]);
      SetColor(LightCyan);
      IF Incubation AND (Button3.Number = 1) THEN
         PLotLine(TimeOld, y3Old, Time, y[3]);
      SetColor(LightRed);
      IF BirthDeath AND (Button6.Number = 1) THEN
      BEGIN
         Population := y[1] + y[2] + y[3] + y[4] + y[5];
         PlotLine(TimeOld, PopulationOld, Time, Population);
         PopulationOld := Population;
      END;
      y1Old := y[1];
      y2Old := y[2];
      y3Old := y[3];
      y4Old := y[4];
      y5Old := y[5];
      TimeOld := Time;
   UNTIL Time > T1;
END;

{-------------------------------------------------------------------------}

PROCEDURE RePlotSolutions;
VAR
   I      : Integer;
BEGIN
   OpenViewPort(1);
   Axis(0, 0, xDiv, yDiv);
   FOR I := 1 TO 5 DO y[I] := yInit[I];
   PlotSolutions;
END;

{-------------------------------------------------------------------------}

FUNCTION SetNewTimeLimits: Boolean;
VAR
   Input       : TInputScreen;
   Quit        : Boolean;
   I           : Integer;
BEGIN
   REPEAT
      WITH Input DO
      BEGIN
         Init;
         DefineInputPort(0.26, 0.74, 0.28, 0.72);
         LoadLine('');
         LoadLine('     Values of T0 and T1 for are');
         LoadLine('  needed for continuing the plot:');
         LoadLine('  The new value of T0 is the old');
         LoadLine('  T1, so T0 = ' + NumStr(T1, 4,1));
         LoadLine('  Enter a value of T1 > T0:');
         LoadLine('         T1 = {       }');
         LoadLine('');
         LoadLine('        [  OK  ]    [Cancel]');
         SetNumber(1, T1 + 5);
         SetNumberLimits(1, 0, 10000000);
         AcceptScreen;
         Quit := Canceled;
         SetNewTimeLimits := NOT Canceled;
         IF NOT Canceled THEN T1 := GetNumber(1);
         Done;
      END;
   IF T1 <= T0 THEN
      Announce('T1 > T0. Try again.');
   UNTIL (T1 > T0) OR Quit;
   IF NOT Quit THEN
      FOR I := 1 TO 5 DO yInit[I] := y[I];
END;

{-------------------------------------------------------------------------}

PROCEDURE PromptInitialConditions;
var 
    xSc, ySC         : Integer;
    a                : Integer;
    xSave, ySave     : Real;
    Inside           : Boolean;
    InitialData      : TInputScreen;
BEGIN
   WITH InitialData DO
   BEGIN
      Init;
      DefineInputPort(0.32, 0.68, 0.35, 0.65);
      LoadLine('');
      LoadLine('  Would you like to use');
      LoadLine('       #1 keyboard');
      LoadLine('   or  #1 mouse?');
      LoadLine('');
      LoadLine('        [  OK  ]');
      IF KeyInitialConditions THEN SetRadioButton('1', 1)
                              ELSE SetRadioButton('1', 2);
      AcceptScreen;
      IF GetRadioButton('1') = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      Done;
   END;
   IF KeyInitialConditions THEN
   BEGIN
      WITH InitialData DO
      BEGIN
         Init;
         DefineInputPort(0.32, 0.68, 0.35, 0.65);
         LoadLine('');
         LoadLine('  Initially:');
         LoadLine('   0 <= S = {      } <= '+NumStr(xMax, 4, 1));
         LoadLIne('   0 <= I = {      } <= '+NumStr(yMax, 4, 1));
         LoadLIne('');
         LoadlIne('        [  OK  ] ');
         SetNumber(1, S0);
         SetNumberLimits(1, 0, xMax);
         SetNumber(2, I0);
         SetNumberLimits(2, 0, yMax);
         AcceptScreen;
         S0 := GetNumber(1);
         I0 := GetNumber(2);
         y[1] := S0;
         y[2] := 0;
         y[3] := 0;
         y[4] := I0;
         y[5] := 0;
         xOld := y[1];
         yOld := y[4];
         Time := 0;
         NextTime := Time + InfectionPeriod;
         StepSize := 0.1;
         Action := True;
         Pause := True;
         InputNeeded := False;
         Done;
      END;
   END
   ELSE
   BEGIN
      SetColor(White);
      Message('     Click on a starting point');
      REPEAT
         MousePosn(S0, I0, 2, 2, Inside);
         IF Inside AND
         (Abs(XSave - S0) + Abs(YSave - (I0)) > 0.01) THEN
         BEGIN
            RubOutXY(0.5, 0.98, 20, Blue);
            PrintXY(0.5, 0.98, '('+NumStr(S0, 4, 2)+', '+NumStr(I0, 4, 2)+')');
            XSave := S0;
            YSave := I0;
         END;
      UNTIL MouseClicked(a,a);
   END;
   Message('');
   y[1] := S0;
   y[2] := 0;
   y[3] := 0;
   y[4] := I0;
   y[5] := 0;
   xOld := y[1];
   yOld := y[4];
   Time := 0;
   NextTime := Time + InfectionPeriod;
   StepSize := 0.1;
   Action := True;
   Pause := True;
   InputNeeded := False;
END;


{-------------------------------------------------------------------------}

PROCEDURE SeePhasePlane;
VAR
   Input        : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.15, 0.85, 0.13, 0.87);
      LoadLine('');
      LoadLine('     In the phase-plane diagram the susceptibles,');
      LoadLIne('  S, are plotted on the horizontal axis and the');
      LoadLine('  infectives, I, on the vertical axis. Enter ');
      LoadLine('  maximum values for these. They should be great-');
      LoadLine('  than 1, and less than '+NumStr(MaxCoord, 4, 0)+'.');
      LoadLine('     Maximum S: {      }   Maximum I: {      }');
      LoadLine('');
      LoadLine('     You have the option of seeing the path plotted');
      LoadLine('  continuously, or as points at equal intervals of ');
      LoadLine('  time. The period being that of the varying infec-');
      LoadLine('  rate. This will produce a ''Poincare map.'' (If');
      LoadLine('  you have not chosen to have a periodic infection');
      LoadLine('  rate, then the second option is ignored.)');
      LoadLine('       Continuous plot: #1  Poincare map: #1');
      LoadLine('');
      LoadLine('                       [  OK  ]');
      SetNumber(1, xMax);
      SetNumberLimits(1, 1, MaxCoord);
      SetNumber(2, yMax);
      SetNumberLimits(2, 1, MaxCoord);
      IF PeriodicInfection AND Poincare THEN
         SetRadioButton('1', 2)
      ELSE SetRadioButton('1', 1);
      AcceptScreen;
      xMax := GetNumber(1);
      yMax := GetNumber(2);
      IF PeriodicInfection AND (GetRadioButton('1') = 2)
         THEN  Poincare := True ELSE Poincare := False;
      Done;
   END;
   DefineViewPort(2, 0.1, 0.9, 0.15, 0.85);
   DefineScale(2, 0, xMax, 0, yMax);
   OpenViewPort(2);
   SelectScale(2);
   Axis(0, 0, 5, 5);
   SetColor(White);
   PutLabel(Bottom, 'Susceptibles');
   PutLabel(Left, 'Infectives');
   SetUpPHotKeys;
   PhasePlane := True;
   LightMenu := False;
   PromptInitialConditions;
END;

{-------------------------------------------------------------------------}

PROCEDURE MoveGraph;
VAR
   NoStepSize   : Real;
   Lag          : Integer;
   i            : Integer;

FUNCTION OutOfBounds : Boolean;
BEGIN
   OutOfBounds := False;
   IF (y[1] > 10*xMax) OR (y[4] > 10*yMax)
   THEN OutOfBounds := True;
END;

BEGIN
   Lag := 50;
   IF NOT Poincare THEN Delay(Lag);
   Step(Time, StepSize, 0.000001, y, Time, StepSize, y);
   IF OutOfBounds OR (ABS(y[1]) < 0.0001) OR (Abs(y[4]) < 0.0001) THEN
   BEGIN
      Action := False;
      Pause := True;
      WITH PHotKeys DO Key[2] := 'F2-Start';
           PHotKeys.BackColor := Blue;
           PHotKeys.Display;
           InputNeeded := True;
      Exit;
   END;
   IF Poincare THEN
   BEGIN
      IF (Time > NextTime) THEN
         BEGIN
         REPEAT
            Step(Time, NextTime - Time, 0.000001, y, Time, NoStepSize, y);
         UNTIL Abs(Time - NextTime) < 0.001;
         NextTime := Time +InfectionPeriod;
         PutPixel(MapX(y[1]), MapY(y[4]), White);
      END;
   END
   ELSE
   BEGIN
      SetColor(Yellow);
      PlotLine(xOld, yOld, y[1], y[4]);
      xOld := y[1];
      yOld := y[4];
   END;
END;


{-------------------------------------------------------------------------}

PROCEDURE HandlePHotKeys(Key : Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HelpPrPr.hlp', 'HelpHK1');
      2: BEGIN
            IF InputNeeded THEN BEGIN
            Announce('Please enter input for a new solution'); Exit; END;
            IF Pause THEN
            BEGIN
               Pause := False;
               WITH PHotKeys DO Key[2] := 'F2-Pause';
               PHotKeys.BackColor := Red;
               PHotKeys.Display;
            END
            ELSE
            BEGIN
               Pause := True;
               WITH PHotKeys DO Key[2] := 'F2-Start';
               PHotKeys.BackColor := Blue;
               PHotKeys.Display;
            END;
         END;
      3: BEGIN
            Action := False;
            PromptInitialConditions;
            Pause := True;
            WITH PHotKeys DO Key[2] := 'F2-Start';
            PHotKeys.BackColor := Blue;
            PHotKeys.Display;
         END;
      4: BEGIN
            Action := False;
            Pause := True;
            WITH PHotKeys DO Key[2] := 'F2-Start';
            PHotKeys.BackColor := Blue;
            PHotKeys.Display;
            SeePhasePlane;
         END;
      5: BEGIN
            Action := False;
            PhasePlane := False;
            PHotKeys.Clear;
            LightMenu := True;
         END;
   END;
END;

{-------------------------------------------------------------------------}

PROCEDURE CheckButtons;
BEGIN
   Check := Button1.Changed;
   Check := Button2.Changed;
   Check := Button3.Changed;
   Check := Button4.Changed;
   Check := Button5.Changed;
   Check := Button6.Changed;
END;

{-------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(Key: Byte);
BEGIN
      CASE Key OF
      1: ShowHelp('HelpPrPr.hlp', 'HelpHK2');
      2: RePlotSolutions;
      3: IF SetNewTimeLimits THEN
         BEGIN
            SetUpScreen;
            PlotSolutions;
         END;
      4: BEGIN
            HotKeys.Clear;
            ClearMuppetPort;
            LightMenu := True;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleDiseaseMenu;
BEGIN
   With DiseaseMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HelpGono.Hlp', 'DiseaseAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: CASE RowChosen OF
            1: ShowHelp('HelpGono.Hlp', 'DiseaseVariables');
            2: ShowHelp('HelpGono.Hlp', 'DiseaseBasicModel');
            3: ShowHelp('HelpGono.Hlp', 'DiseaseVaccination');
            4: ShowHelp('HelpGono.Hlp', 'DiseaseIncubation');
            5: ShowHelp('HelpGono.Hlp', 'DiseasePeriodicInfection');
            6: ShowHelp('HelpGono.Hlp', 'DiseaseBirthDeath');
            7: BEGIN
                  ShowHelp('WalkThru.hlp', 'Disease1');
                  ShowHelp('WalkThru.hlp', 'Disease2');
                  ShowHelp('WalkThru.hlp', 'Disease3');
               END;
            8: SetMaximumCoordinate;
         END;
      3: CASE RowChosen OF
            1: SetParameters;
            2: IF PeriodicInfection THEN
               BEGIN
                  IF NOT Input2 THEN Exit;
               END
               ELSE
               BEGIN
                  IF NOT Input1 THEN Exit;
               END;
            3: IF NOT Input4 THEN Exit;
            4: IF NOT Input3 THEN Exit;
            5: IF NOT Input5 THEN Exit;
         END;
      4: CASE RowChosen OF
            1: BEGIN
                  GetStarted;
                  SetUpScreen;
                  PlotSolutions;
               END;
            2: BEGIN
                  SetUpScreen;
                  PlotSolutions;
               END;
            3: SeePhasePlane;
         END;
   END;
END;


{------------------------------------------------------------------------}

PROCEDURE GetSetUp;
BEGIN
   DefineViewPort(1, 0.2, 0.95, 0.10, 0.93);
   Vaccination := False;
   Incubation := False;
   BirthDeath := False;
   PeriodicInfection := False;
   ExitRequest := False;
   PhasePlane := False;
   LightMenu := True;
   InfectionRate0 := 1;
   InfectionPeriod := 1;
   InfectionRate1 := 0.8;
   CureRate := 1;
   IncubationRate := 1;
   VaccinationRate := 0.5;
   VaccinationPower := 2;
   T0 := 0;
   T1 := 5;
   S0 := 9;
   I0 := 1;
   Birth[1] := 3; Death[1] := 2.4;
   Birth[2] := 0; Death[2] := 1;
   Birth[3] := 0; Death[3] := 3;
   Birth[4] := 0; Death[4] := 3;
   Birth[5] := 0; Death[5] := 1;
   MaxCoord := 100;
   xMax := 10;
   yMax := 10;
   Hello('HelpGono.Hlp', 'DiseaseAboutProgram');
   SetMaximumCoordinate;
   SetUpDiseaseMenu;

END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   Button1.Init;
   Button2.Init;
   Button3.Init;
   Button4.Init;
   Button5.Init;
   Button6.Init;
   GetSetUp;
   SetParameters;
   REPEAT
      CheckForEvents;
      IF (NOT PhasePlane) AND HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF PhasePlane AND PHotKeys.Pressed(Key) THEN HandlePHotKeys(Key);
      IF NOT PhasePlane THEN CheckButtons;
      IF Action AND (NOT Pause) AND PhasePlane THEN MoveGraph;
      IF LightMenu THEN
         IF DiseaseMenu.Chosen THEN HandleDiseaseMenu;
   UNTIL ExitRequest;
   CUPSDone;
   Button1.Done;
   Button2.Done;
   Button3.Done;
   Button4.Done;
   Button5.Done;
   Button6.Done;
   DiseaseMenu.Done;
END.
