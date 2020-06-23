PROGRAM TwoDimensionalMapping;

USES Graph, Crt, CupsMupp, CUPS, CupsGrph, CupsFunc, CupsProc, CupsGui,
     CupsPars;

VAR
   MapMenu                       : TMenu;
   XFunc, YFunc                  : TParser;
   HotKeys                       : THotKeys;
   Key                           : Byte;
   XFStr, YFStr                  : String;
   xHigh, xLow, yHigh, yLow      : Real;
   xStart, yStart                : Real;
   xMap, yMap                    : Real;
   C                             : Real;
   CLow, CHigh                   : Real;
   Action                        : Boolean;
   LightMenu                     : Boolean;
   KeyInitialConditions          : Boolean;
   ExitRequest                   : Boolean;
   ChangeScale                   : Boolean;
   KeyScale                      : Boolean;
   FirstScreen                   : Boolean;
   Input                         : Boolean;
   ModelNumber                   : Integer;

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
   envir.Reset;
END;

{-------------------------------------------------------------------------}

PROCEDURE SetUpMapMenu;
VAR
   I      : Integer;
BEGIN
   With MapMenu DO
   BEGIN
   Init;
      Column(1, 'File');
       row(1,1, 'About CUPS');
       row(1,2, 'About the program');
       row(1,3, 'Configuration');
       row(1,4, 'Leave the program');
      Column(2, 'Help');
       row(2,1, 'Two dimensional maps');
       row(2,2, 'Walk-through');
      Column(3, 'Model');
       row(3,1, 'One');
       row(3,2, 'Two');
       row(3,3, 'Three');
       row(3,4, 'Four');
       row(3,5, 'Make your own');
       Display;
      FOR I := 1 TO 3 DO AutoChecking(I, 1);
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpHotKeys;
BEGIN
   WITH HotKeys DO
   BEGIN
      HotKeys.Init(6);
      Key[1] := 'F1-Help';
      Key[2] := 'F2-Start';
      Key[3] := 'F3-Input';
      Key[4] := 'F4-NewC';
      Key[5] := 'F5-CleanUp';
      Key[6] := 'F10-Menu';
   END;
   HotKeys.BackColor := Red;
   HotKeys.HotKeyColor := Yellow;
   HotKeys.Display;
END;

{----------------------------------------------------------------------}

FUNCTION GetModelData : Boolean;
VAR
   Screen   : TInputScreen;
   n        : byte;
   StrOK    : Array[1..2] OF Boolean;
   Str      : Array [1..2] of String;
   MaxMinOK : Boolean;
   dx, dy   : Real;
   z, r     : Real;

BEGIN
   CASE ModelNumber OF
      1: BEGIN
         WITH Screen DO
         BEGIN
            init;
            DefineInputPort (0.18, 0.82, 0.15, 0.85);
            LoadLine('');
            LoadLine('               Mapping functions');
            LoadLine('');
            LoadLine('          The program uses a mapping:');
            LoadLine('  x(n+1) = x(n) + C*y(n)*(1 - y(n)*y(n)),');
            LoadLine('  y(n+1) = y(n) - C*x(n+1)*(1 - x(n+1)*x(n+1)).');
            LoadLine('');
            LoadLine('     Enter a value for the parameter C:');
            LoadLine('        '+NumStr(CLow, 1,0)+' < C = {       } < '
                               +NumStr(CHigh, 1,0));
            LoadLine('');
            LoadLine('  Enter the extreme coordinates for the figure:');
            LoadLine('  Minimum x = {       }  Maximum x = {       }');
            LoadLine('  Minimum y = {       }  Maxumum y = {       }');
            LoadLine('');
            LoadLine('       [ Help ]     [  Ok  ]     [Cancel]  ');
            SetHelpFile('HlpChaos.hlp', 'TwoDMapModelHelpA');
            SetNumber(1, C);
            SetNumberLimits(1, CLow, CHigh);
            SetNumber(2, xLow);
            SetNumber(3, xHigh);
            SetNumber(4, yLow);
            SetNumber(5, yHigh);
            REPEAT
               AcceptScreen;
               GetModelData := NOT Canceled;
               IF Canceled THEN BEGIN Done; Exit; END;
               C := GetNumber(1);
               xLow := GetNumber(2);
               xHigh := GetNumber(3);
               yLow := GetNumber(4);
               yHigh := GetNumber(5);
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
                  Announce('You have confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            Done;
         END;
         END;
      2: BEGIN
         WITH Screen DO
         BEGIN
            init;
            DefineInputPort (0.16, 0.84, 0.15, 0.85);
            LoadLine('');
            LoadLine('                Mapping functions');
            LoadLine('');
            LoadLine('          The program uses a mapping:');
            LoadLine('  x(n+1) = x(n)*CosC - y(n)*SinC + x(n)*x(n)*SinC');
            LoadLine('  y(n+1) = x(n)*SinC + y(n)*CosC - x(n)*x(n)*CosC');
            LoadLine('');
            LoadLine('     Enter a value for the parameter C:');
            LoadLine('        '+NumStr(CLow, 2,1)+' < C = {       } < '
                               +NumStr(CHigh, 2,1));
            LoadLine('');
            LoadLine('  Enter the extreme coordinates for the figure:');
            LoadLine('  Minimum x = {       }  Maximum x = {       }');
            LoadLine('  Minimum y = {       }  Maxumum y = {       }');
            LoadLine('');
            LoadLine('       [ Help ]      [  Ok  ]     [Cancel]  ');
            SetHelpFile('HlpChaos.hlp', 'TwoDMapModelHelpA');
            SetNumber(1, C);
            SetNumberLimits(1, CLow, CHigh);
            SetNumber(2, xLow);
            SetNumber(3, xHigh);
            SetNumber(4, yLow);
            SetNumber(5, yHigh);
            REPEAT
               AcceptScreen;
               GetModelData := NOT Canceled;
               IF Canceled THEN BEGIN Done; Exit; END;
               C := GetNumber(1);
               xLow := GetNumber(2);
               xHigh := GetNumber(3);
               yLow := GetNumber(4);
               yHigh := GetNumber(5);
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
                  Announce('You have confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            Done;
         END;
         END;
      3: BEGIN
         WITH Screen DO
         BEGIN
            init;
            DefineInputPort (0.175, 0.825, 0.15, 0.85);
            LoadLine('');
            LoadLine('               Mapping functions');
            LoadLine('');
            LoadLine('          The program uses a mapping:');
            LoadLine('      x(n+1) = C*x(n)*(1 - x(n) - y(n))');
            LoadLine('      y(n+1) = C*x(n)*y(n)');
            LoadLine('');
            LoadLine('     Enter a value for the parameter C:');
            LoadLine('        '+NumStr(CLow, 1,0)+' < C = {       } < '
                               +NumStr(CHigh, 1,0));
            LoadLine('');
            LoadLine('  Enter the extreme coordinates for the figure:');
            LoadLine('  Minimum x = {       }  Maximum x = {       }');
            LoadLine('  Minimum y = {       }  Maxumum y = {       }');
            LoadLine('');
            LoadLine('       [ Help ]      [  Ok  ]     [Cancel]  ');
            SetHelpFile('HlpChaos.hlp', 'TwoDMapModelHelpA');
            SetNumber(1, C);
            SetNumberLimits(1, CLow, CHigh);
            SetNumber(2, xLow);
            SetNumber(3, xHigh);
            SetNumber(4, yLow);
            SetNumber(5, yHigh);
            REPEAT
               AcceptScreen;
               GetModelData := NOT Canceled;
               IF Canceled THEN BEGIN Done; Exit; END;
               C := GetNumber(1);
               xLow := GetNumber(2);
               xHigh := GetNumber(3);
               yLow := GetNumber(4);
               yHigh := GetNumber(5);
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
                  Announce('You have confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            Done;
         END;
         END;
      4: BEGIN
         WITH Screen DO
         BEGIN
            init;
            DefineInputPort (0.175, 0.825, 0.15, 0.85);
            LoadLine('');
            LoadLine('                Mapping functions');
            LoadLine('');
            LoadLine('          The program uses a mapping:');
            LoadLine('    x(n+1) = y(n)');
            LoadLine('    y(n+1) = C*y(n)*(1 - x(n)/2 - y(n)/2)');
            LoadLine('');
            LoadLine('     Enter a value for the parameter C:');
            LoadLine('        '+NumStr(CLow, 1,0)+' < C = {       } < '
                               +NumStr(CHigh, 1,0));
            LoadLine('');
            LoadLine('  Enter the extreme coordinates for the figure:');
            LoadLine('  Minimum x = {       }  Maximum x = {       }');
            LoadLine('  Minimum y = {       }  Maxumum y = {       }');
            LoadLine('');
            LoadLine('       [ Help ]       [  Ok  ]      [Cancel]  ');
            SetHelpFile('HlpChaos.hlp', 'TwoDMapModelHelpB');
            SetNumber(1, C);
            SetNumberLimits(1, CLow, CHigh);
            SetNumber(2, xLow);
            SetNumber(3, xHigh);
            SetNumber(4, yLow);
            SetNumber(5, yHigh);
            REPEAT
               AcceptScreen;
               GetModelData := NOT Canceled;
               IF Canceled THEN BEGIN Done; Exit; END;
               C := GetNumber(1);
               xLow := GetNumber(2);
               xHigh := GetNumber(3);
               yLow := GetNumber(4);
               yHigh := GetNumber(5);
               IF (xLow >= xHigh) OR (yLow >= yHigh) THEN
                  Announce('You have confused upper and lower limits. Try again.');
            UNTIL (xLow < xHigh) AND (yLow < yHigh);
            Done;
         END;
         END;
      5: BEGIN
         WITH Screen DO
         BEGIN
            init;
            DefineInputPort (0.04, 0.96, 0.06, 0.94);
            LoadLine('');
            LoadLine('                         Mapping functions');
            LoadLine('');
            LoadLine('                 The program uses a mapping:');
            LoadLine('                  x(n+1) = f(x(n), y(n), C),');
            LoadLine('                  y(n+1) = g(x(n), y(n), C).');
            LoadLine('   For use in the parser for this program it is ESSENTIAL that the');
            LoadLine(' symbol ''z'' be used IN PLACE of C.');
            LoadLine('   Enter the functions');
            LoadLine(' f(x,y,z) = "                                                        "');
            LoadLine(' g(x,y,z) = "                                                        "');
            LoadLine('');
            LoadLine('   Enter a value for the parameter C:');
            LoadLine('                  C = {       }');
            LoadLine('');
            LoadLine('   Enter the extreme coordinates for the figure:');
            LoadLine('          Minimum x = {       }  Maximum x = {       }');
            LoadLine('          Minimum y = {       }  Maxumum y = {       }');
            LoadLine('');
            LoadLine('            [ Help ]        [  Ok  ]       [Cancel]');
            SetHelpFile('HlpChaos.hlp', 'TwoDDIYHelp');
            SetString(1, xFStr);
            SetString(2, yFStr);
            SetNumber(3, C);
            SetNumber(4, xLow);
            SetNumber(5, xHigh);
            SetNumber(6, yLow);
            SetNumber(7, yHigh);
            XFunc.Init; YFunc.Init;
            REPEAT
               AcceptScreen;
               GetModelData := NOT Canceled;
               IF Canceled THEN BEGIN Done; Exit; END;
               IF NOT Canceled THEN
               BEGIN
               Str[1] := GetString(1);
               Str[2] := GetString(2);
               StrOK[1] := xFunc.parse('x','y','z','r', Str[1]);
               if not StrOK[1] then
                  announce('Error: Cannot evaluate x function. Please try again.');
               StrOK[2] := yFunc.parse('x','y','z','r', Str[2]);
               if not StrOK[2] then
                  announce('Error: Cannot evaluate y function. Please try again.');
               xLow := GetNumber(4);
               xHigh := GetNumber(5);
               yLow := GetNumber(6);
               yHigh := GetNumber(7);
               IF (xLow >= xHigh) OR (yLow >= yHigh)
               THEN
               BEGIN
                  MaxMinOK := False;
                  Announce('You have confused upper and lower limits. Please try again.');
               END
               ELSE MaxMinOK := True;
               END;
            UNTIL (StrOk[1] AND StrOk[2] AND MaxMinOK) OR Canceled;
            IF NOT Canceled then
            BEGIN
               xFStr := Str[1];
               yFStr := Str[2];
               C := GetNumber(3);
            END;
            done;
       END;
   END;
   END;
   dx := (xHigh - xLow)/20;
   dy := (yHigh - yLow)/20;
   DefineScale(1, xLow-dx, xHigh+dx, yLow-2*dy, yHigh+dy);
END;

{------------------------------------------------------------------------}

PROCEDURE MapPoint;
VAR
   xSave, ySave       : Real;
   z, r               : Real;
   CosC, SinC         : Real;
BEGIN
   xSave := xMap;
   ySave := yMap;
   CASE ModelNumber OF
      1: BEGIN
            xMap := xSave + C*ySave*(1 - ySave*ySave);
            yMap := ySave - C*xMap*(1 - xMap*xMap);
         END;
      2: BEGIN
            CosC := Cos(C);
            SinC := Sin(C);
            xMap := xSave*CosC - ySave*SinC + xSave*xSave*SinC;
            yMap := xSave*SinC + ySave*CosC - xSave*xSave*CosC;
         END;
      3: BEGIN
            xMap := C*xSave*(1 - xSave - ySave);
            yMap := C*xSave*ySave;
         END;
      4: BEGIN
            xMap := ySave;
            yMap := C*ySave*(1 - xSave/2 - ySave/2);
         END;
      5: BEGIN
            z := C;
            xMap := xFunc.F(xSave, ySave, z, r);
            yMap := yFunc.F(xSave, ySave, z, r);
         END;
   END;
END;

{---------------------------------------------------------------------}

PROCEDURE MoveMap;
BEGIN
   MapPoint; IF (Abs(xMap) > 10000) OR (Abs(yMap) > 10000) THEN
   BEGIN
      Action := False;
      Input := False;
      Announce('Overflow. Let''s start again.');
      Action := False;
      WITH HotKeys DO Key[2] := 'F2-Run';
      HotKeys.BackColor := Red;
      HotKeys.Display;
      ShowMouse;
   END
   ELSE
   PutPixel(MapX(xMap), MapY(yMap), Yellow);
END;

{------------------------------------------------------------------------}

PROCEDURE SetKeyScale;
VAR
   Input      : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.35, 0.65);
      LoadLine('');
      LoadLine('     Enter extreme limits for display:');
      LoadLine('  xLow = {       }   xHigh = {       }');
      LoadLine('  yLow = {       }   yHigh = {       }');
      LoadLine('');
      LoadLine('                 [  OK  ]');
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
   DefineScale(1, xLow, xHigh, yLow, yHigh);
END;

{------------------------------------------------------------------------}

PROCEDURE SetMouseScale;
VAR
   XCoord, YCoord        : Real;
   xm, ym                : Integer;
   Ins                   : Boolean;
   Button                : Integer;
   Clicked               : Boolean;
   Quit                  : Boolean;
   i                     : Integer;
   Save1, Save2          : Real;

PROCEDURE MakeRectangle;
BEGIN
   PlotLine(xLow, yLow, xLow, yHigh);
   PlotLine(xLow, yHigh, xHigh, yHigh);
   PlotLine(xHigh, yHigh, xHigh, yLow);
   Plotline(xHigh, yLow, xLow, yLow);
END;

BEGIN
   Message('Click on the lower left corner of the rectangle. Click outside to quit');
   Clicked := False;
   WaitOnMouseClick;
   MousePosn(Save1, Save2, 1, 1, Ins);
   IF NOT Ins THEN BEGIN Quit := True; Exit; END;
   xLow := Save1; yLow := Save2;
   Message('Click on the upper right corner of the rectangle');
   SetColor(White);
   Delay(100);
      SetWriteMode(XORPut);
      REPEAT
         Button := 0;
         MouseGlobalPosn(xm, ym, Button);
         MousePosn(xHigh, yHigh, 1, 1, Ins);
         IF (xHigh <= xLow) OR (yHigh <= yLow) THEN
         BEGIN
            REPEAT
               Beep;
               MousePosn(xHigh, yHigh, 1, 1, Ins);

            UNTIL (xHigh > xLow) AND (yHigh > yLow);
         END;
         MakeRectangle;
         Delay(10);
         MakeRectangle;
      UNTIL (Button <> 0);
      SetWriteMode(CopyPut);
      Message('');
      DefineScale(1, xLow, xHigh, yLow, yHigh);
END;


{------------------------------------------------------------------------}

PROCEDURE QueryKeyOrMouse;
CONST
   RBNames : string = '12345678';
VAR
   Input         : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.275, 0.725, 0.4, 0.6);
      LoadLine('');
      LoadLine('   Use keyboard #1 or mouse #1');
      LoadLine('');
      LoadLine('            [  OK  ]');
      IF KeyScale THEN SetRadioButton(RBNames[1], 1)
                  ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyScale := True ELSE KeyScale := False;
      Done;
   END;
   IF KeyScale THEN SetKeyScale ELSE SetMouseScale;
END;

{------------------------------------------------------------------------}

PROCEDURE QueryChangeScale;
CONST
   RBNames : string = '12345678';
VAR
   Input         : TInputScreen;
BEGIN
   ShowMouse;
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.4, 0.6);
      LoadLine('');
      LoadLine('   Change scale? Yes #1   No #1');
      LoadLine('');
      LoadLine('            [  OK  ]');
      IF ChangeScale THEN SetRadioButton(RBNames[1], 1)
                     ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      ChangeScale := True ELSE ChangeScale := False;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetUpScreen;
BEGIN
   IF NOT FirstScreen THEN
   BEGIN
      QueryChangeScale;
      IF ChangeScale THEN QueryKeyOrMouse;
   END;
   FirstScreen := False;
   ClearMuppetPort;
   OpenViewPort(1);
   SelectScale(1);
   Axis(0, 0, 1, 1);
   PutLabel(Left, 'y(n)');
   PutLabel(Bottom, 'x(n)');
   PrintXY(0.2, 0.93, NumStr(xLow, 7,5) + ' < x < '+NumStr(xHigh, 7,5) +
           ',   '+ NumStr(yLow, 7,5) + ' < y < '+NumStr(yHigh, 7,5) );
   SetUpHotKeys;
   Input := False;
   Action := False;
   LightMenu := False;
END;

{------------------------------------------------------------------------}

PROCEDURE FindNewC;
VAR
   Input        : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.27, 0.73, 0.36, 0.64);
      LoadLine('');
      LoadLine('     Enter a new value for C:');
      LoadLine('         C = {       }');
      LoadLine('');
      LoadLine('             [  OK  ]');
      SetNumber(1, C);
      AcceptScreen;
      C := GetNumber(1);
      Done;
   END;
   FirstScreen := True;
   SetUpScreen;
END;

{------------------------------------------------------------------------}

PROCEDURE KeyStart;
VAR
   Input     : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.25, 0.75, 0.35, 0.65);
      LoadLine('');
      LoadLine('     Enter initial values: ');
      LoadLine('      '+NumStr(xLow, 3, 1)+' < x = {       } < '
                   +NumStr(xHigh, 3, 1));
      LoadLine('      '+NumStr(yLow, 3, 1)+' < y = {       } < '
                   +NumStr(yHigh, 3, 1));
      LoadLine('');
      LoadLine('            [  OK  ]');
      SetNumber(1, xStart);
      SetNumberLimits(1, xLow-0.1, xHigh+0.1);
      SetNumber(2, yStart);
      SetNumberLimits(2, yLow-0.1, yHigh+0.1);
      AcceptScreen;
      xStart := GetNumber(1);
      yStart := GetNumber(2);
      xMap := xStart;
      yMap := yStart;
      Done;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE MouseStart;
VAR
   dx,dy,cx,cy,a,n : integer;
   Inside, Ins     : Boolean;
   Button          : Integer;
   xm, ym          : Integer;
   MSave, FSave    : Real;
   y, z, r         : Real;
BEGIN
   Inside := True;
   Button := 0;
   Message('    Click to choose a starting value for x');
   SetColor(White);
   REPEAT
      MousePosn(xStart, yStart, 1, 1, Inside);
      IF Inside AND
      (Abs(MSave - xStart) + Abs(FSave - yStart) > 0.01) THEN
      BEGIN
         RubOutXY(0.65, 0.982, 25, Blue);
         PrintXY(0.65, 0.982, 'x = '+NumStr(xStart, 4, 2)+
                    '   y = '+NumStr(yStart, 4, 2));
         MSave := (xStart);
         FSave := (yStart);
      END;
   UNTIL MouseClicked(a,a);
   SetColor(Yellow);
   PlotSymbol(xStart, yStart, '.');
   xMap := xStart;
   yMap := yStart;
   RubOutXY(0.65, 0.982, 25, Blue);
   Message('');
END;

{------------------------------------------------------------------------}

PROCEDURE FindInitialConditions;
CONST
   RBNames : string = '12345678';
VAR
   Input         : TInputScreen;
BEGIN
   WITH Input DO
   BEGIN
      Init;
      DefineInputPort(0.275, 0.725, 0.4, 0.6);
      LoadLine('');
      LoadLine('   Use keyboard #1 or mouse #1');
      LoadLine('');
      LoadLine('            [  OK  ]');
      IF KeyInitialConditions THEN SetRadioButton(RBNames[1], 1)
                              ELSE SetRadioButton(RBNames[1], 2);
      AcceptScreen;
      IF GetRadioButton(RBNames[1]) = 1 THEN
      KeyInitialConditions := True ELSE KeyInitialConditions := False;
      Done;
   END;
   IF KeyInitialConditions THEN KeyStart ELSE MouseStart;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleHotKeys(key: Byte);
BEGIN
   CASE Key OF
      1: ShowHelp('HlpChaos.hlp', 'TwoDMapHotKeysHelp');
      2: BEGIN
            IF NOT Input THEN Announce('Please enter a starting point')
            ELSE
            BEGIN
               IF Action = True THEN
               BEGIN
                  Action := False;
                  WITH HotKeys DO Key[2] := 'F2-Run';
                  HotKeys.BackColor := Red;
                  HotKeys.Display;
                  ShowMouse;
               END
               ELSE
               BEGIN
                  Action := True;
                  HideMouse;
                  WITH HotKeys DO Key[2] := 'F2-Stop';
                  HotKeys.BackColor := Blue;
                  HotKeys.Display;
               END;
            END;
         END;
      3: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            ShowMouse;
            FindInitialConditions;
            Input := True;
         END;
      4: BEGIN
            IF Action = True THEN
            BEGIN
               Action := False;
               WITH HotKeys DO Key[2] := 'F2-Run';
               HotKeys.BackColor := Red;
               HotKeys.Display;
            END;
            ShowMouse;
            FindNewC;
         END;
      5: BEGIN {FirstScreen := True;} SetUpScreen; END;
      6: BEGIN
            Action := False;
            LightMenu := True;
            HotKeys.Clear;
            ShowMouse;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE SetDefaultValues;
BEGIN
   CASE ModelNumber OF
      1: BEGIN
            xLow := -1;
            xHigh := 1;
            yLow := -1;
            yHigh := 1;
            C := 1.5;
            CLow := 0;
            CHigh := 3;
         END;
      2: BEGIN
            xLow := -1;
            xHigh := 1;
            yLow := -1;
            yHigh := 1;
            C := 5;
            CLow := 0;
            CHigh := 6.3;
         END;
      3: BEGIN
            xLow := 0;
            xHigh := 1;
            yLow := 0;
            yHigh := 1;
            C := 3.2;
            CLow := 0;
            CHigh := 4;
         END;
      4: BEGIN
            xLow := 0;
            xHigh := 1;
            yLow := 0;
            yHigh := 1;
            C := 3;
            CLow := 0;
            CHigh := 4;
         END;
   END;
END;

{------------------------------------------------------------------------}

PROCEDURE HandleMapMenu;
BEGIN
   With MapMenu DO
   CASE ColChosen OF
      1: CASE RowChosen OF
            1: AboutCUPS;
            2: ShowHelp('HlpChaos.hlp', 'TwoDMapAboutProgram');
            3: Configuration;
            4: ExitRequest := True;
         END;
      2: BEGIN
            CASE RowChosen OF
               1: BEGIN
                     ShowHelp('HlpChaos.hlp', 'TwoDMapModelHelpA');
                     ShowHelp('HlpChaos.hlp', 'TwoDMapModelHelpB');
                  END;
               2: BEGIN
                     ShowHelp('WalkThru.hlp', 'TwoDMap1');
                     ShowHelp('WalkThru.hlp', 'TwoDMap2');
                     ShowHelp('WalkThru.hlp', 'TwoDMap3');
                  END;
            END;
         END;
      3: BEGIN
            CASE RowChosen OF
               1: BEGIN ModelNumber := 1; SetDefaultValues; END;
               2: BEGIN ModelNumber := 2; SetDefaultValues; END;
               3: BEGIN ModelNumber := 3; SetDefaultValues; END;
               4: BEGIN ModelNumber := 4; SetDefaultValues; END;
               5: ModelNumber := 5;
            END;
            IF GetModelData THEN
            BEGIN
               FirstScreen := True;
               SetUpScreen;
            END;
         END;
   END;
END;

{------------------------------------------------------------------------}

BEGIN
   CUPSInit;
   DefineViewPort(1, 0.1, 0.9, 0.1, 0.9);
   ModelNumber := 1;
   xLow := -1.5;
   xHigh := 1.5;
   yLow := -0.5;
   yHigh := 0.5;
   XFStr := 'y+1-z*x*x';
   YFStr := '0.3*x';
   xStart := 0;
   yStart := 0;
   Hello('HlpChaos.Hlp', 'TwoDMapAboutProgram');
   ExitRequest := False;
   SetUpMapMenu;
   LightMenu := True;
   REPEAT
      CheckForEvents;
      IF HotKeys.Pressed(Key) THEN HandleHotKeys(Key);
      IF LightMenu AND MapMenu.Chosen THEN HandleMapMenu;
      IF Action THEN MoveMap;
   UNTIL ExitRequest;
   CUPSDone;
   MapMenu.Done;
END.