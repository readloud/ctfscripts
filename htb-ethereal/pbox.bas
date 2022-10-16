REM PasswordBox - Keeps all your passwords safe!
REM Compiled on FreeBASIC v0.21.1
REM Author: Mateusz Viste  //  Credits to Chris Brown (aka Zamaster) for his great AES implementation
REM
REM This program is free software: you can redistribute it and/or modify
REM it under the terms of the GNU General Public License as published by
REM the Free Software Foundation, either version 3 of the License, or
REM (at your option) any later version.


CONST pVer AS STRING = "0.11"
CONST pDate AS STRING = "2009-2010"

CONST Debug AS BYTE = 0 ' Debug mode ON/OFF (1/0)

REDIM SHARED PasswordBoxDesc(1 TO 4) AS STRING
REDIM SHARED PasswordBoxPass(1 TO 4) AS STRING
DIM SHARED AS INTEGER PasswordBoxSize = 0, ScreenWidth, ScreenHeight, MaxQuickSearchFilterSize
DIM SHARED AS STRING EncrBuffer, DecrBuffer, PassPhrase, ConfigFile, NextAction, QuickSearchFilter
DIM SHARED AS BYTE ModFlag = 0, TerminalSizeChanged = 0, AsciiMode
DIM SHARED GraphTable(1 TO 7) AS STRING

SUB FlushKeyb() ' Flush Keyb buffer
  WHILE LEN(INKEY) > 0 : WEND
END SUB

#INCLUDE ONCE "rijndael.bi"
#INCLUDE ONCE "reprint.bi"
#INCLUDE ONCE "throwmsg.bi"


SUB DebugOut(DebugMessage AS STRING)
  IF Debug = 1 THEN
    PRINT "["; DebugMessage; "]"
    SLEEP 500, 1
  END IF
END SUB


FUNCTION CheckDataFile() AS BYTE
  REM Returns 1 if the datafile seems to be a valid PasswordBox datafile, 0 otherwise, and -1 if the file do not exists.
  DIM AS STRING FileHeader = SPACE(12)
  DIM AS BYTE Result = 0
  DIM AS INTEGER OpenResult
  OpenResult = Open(ConfigFile, FOR INPUT, AS #1)
  CLOSE #1
  IF OpenResult <> 0 THEN ' The file doesn't exists
      Result = -1
    ELSE  ' The file exists, so let's check its size & header
      OPEN ConfigFile FOR BINARY AS #1
      IF LOF(1) >= 28 THEN GET #1, 1, FileHeader
      CLOSE #1
  END IF
  IF FileHeader = "PasswordBox" + CHR(26) THEN Result = 1
  RETURN Result
END FUNCTION


FUNCTION CheckPassPhrase() AS BYTE
  REM Returns 1 if the Passphrase decrypted the file's header properly, 0 otherwise.
  DIM AS BYTE Result = 0
  DIM AS STRING LineBuff = SPACE(16), DecryptedHeader
  OPEN ConfigFile FOR BINARY AS #1
  GET #1, 13, LineBuff
  CLOSE #1
  DebugOut("Checking given password...")
  DecryptedHeader =  RIJNDAEL_Encrypt(LineBuff, PassPhrase, 2)
  DebugOut("DecryptedHeader = " + DecryptedHeader)
  IF LEFT(DecryptedHeader, 10) = "Monika <3 " THEN Result = 1
  RETURN Result
END FUNCTION


FUNCTION RandChar() AS STRING
  DIM AS STRING CharPool, Result
  DIM RandByte AS BYTE
  CharPool = "!#$%&()*+-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\]]_abcdefghijklmnopqrstuvwxyz{}"
  RandByte = INT(RND * LEN(CharPool)) ' Generate a number between 0 and LEN(CharPool) - 1
  Result = CHR(CharPool[RandByte])
  RETURN Result
END FUNCTION


SUB LoadBox()
  DIM AS INTEGER x
  DIM AS BYTE EotFlag = 0, ByteBuff
  DIM AS STRING LineBuff = ""
  OPEN ConfigFile FOR BINARY AS #1
  EncrBuffer = SPACE(LOF(1) - 28)
  GET #1, 29, EncrBuffer
  CLOSE #1
  DebugOut("Datafile read (" & LEN(EncrBuffer) & " bytes)")
  DecrBuffer = RIJNDAEL_Encrypt(EncrBuffer, PassPhrase, 2)
  DebugOut("Datafile decrypted.")
  AsciiMode = ASC(LEFT(DecrBuffer, 1))
  DebugOut("AsciiMode = " & AsciiMode)
  FOR x = 2 TO LEN(DecrBuffer)
    IF EotFlag = 0 THEN
      ByteBuff = DecrBuffer[x - 1]
      SELECT CASE ByteBuff
        CASE 10 ' End of record (and start of a new one)
          IF PasswordBoxSize = UBOUND(PasswordBoxPass) THEN ' Redim tables if needed
            REDIM PRESERVE PasswordBoxPass(1 TO PasswordBoxSize * 2) AS STRING
            REDIM PRESERVE PasswordBoxDesc(1 TO PasswordBoxSize * 2) AS STRING
          END IF
          IF PasswordBoxSize > 0 THEN PasswordBoxPass(PasswordBoxSize) = LineBuff
          LineBuff = ""
          PasswordBoxSize += 1
        CASE 13 ' End of description, password follows
          PasswordBoxDesc(PasswordBoxSize) = LineBuff
          LineBuff = ""
        CASE 4  ' EOT byte, end of (interesting) data
          EotFlag = 1
          DebugOut("EOT byte catched after " & PasswordBoxSize & " entries.")
          IF PasswordBoxSize > 0 THEN PasswordBoxPass(PasswordBoxSize) = LineBuff ' Last entry
        CASE ELSE ' Any data
          LineBuff += CHR(ByteBuff)
      END SELECT
    END IF
  NEXT x
  DecrBuffer = ""
  EncrBuffer = ""
END SUB


SUB SaveBox()
  DIM AS INTEGER x
  DIM AS STRING CheckString, LineBuff = ""
  DecrBuffer = CHR(AsciiMode)
  FOR x = 1 TO PasswordBoxSize
    DecrBuffer += CHR(10) & PasswordBoxDesc(x) & CHR(13) & PasswordBoxPass(x)
  NEXT x
  DecrBuffer += CHR(4) ' EOT byte
  EncrBuffer = RIJNDAEL_Encrypt(DecrBuffer, PassPhrase, 1)
  LineBuff = "Monika <3 " & RandChar() & RandChar() & RandChar() & RandChar() & RandChar() & RandChar()
  CheckString = RIJNDAEL_Encrypt(LineBuff, PassPhrase, 1)
  OPEN ConfigFile FOR OUTPUT AS #1
  PRINT #1, "PasswordBox" & CHR(26) & CheckString & EncrBuffer;
  CLOSE #1
END SUB


FUNCTION GetConfFile() AS STRING
  DIM AS STRING Result
  #IFDEF __FB_LINUX__
    Result = ENVIRON("HOME") & "/.pbox.dat"
  #ENDIF
  #IFDEF __FB_WIN32__
    IF LEN(ENVIRON("APPDATA")) > 0 THEN
        Result = ENVIRON("APPDATA") & "\pbox.dat"
      ELSE
        Result = EXEPATH & "\pbox.dat"
    END IF
  #ENDIF
  #IFDEF __FB_DOS__
    Result = EXEPATH & "\pbox.dat"
  #ENDIF
  RETURN Result
END FUNCTION


SUB About()
  DIM HelpScreen AS STRING
  HelpScreen = "PasswordBox v" & pVer & " Copyright (C) Mateusz Viste " & pDate & CHR(10) &_
               " // Credits to Chris Brown (aka Zamaster) for his great AES implementation //" & CHR(10) &_
               CHR(10) &_
               "PasswordBox is a console-mode program which will keep all your passwords safe, inside an encrypted database." & CHR(10) &_
               CHR(10) &_
               "Usage: pbox [--help] [--dump]" & CHR(10) &_
               "  --help  displays this help screen" & CHR(10) &_
               "  --dump  lists all the data of your encrypted database onscreen" & CHR(10) &_
               CHR(10) &_
               "CAUTION: This program features 128 bits AES encryption, which might be illegal in your country." & CHR(10) &_
               CHR(10) &_
               "This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version." & CHR(10) &_
               "This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details." & CHR(10) &_
               "You should have received a copy of the GNU General Public License along with this program. If not, see <http://www.gnu.org/licenses/>."
  WHILE LEN(HelpScreen) > 0
    PRINT WordWrap(HelpScreen, LOWORD(WIDTH) - 1)
  WEND
  PRINT
  PRINT "On your system, the PasswordBox encrypted database is stored at the following location:"
  PRINT GetConfFile()
  PRINT
  END(3)
END SUB


SUB DumpBox()
  DIM AS INTEGER x
  FOR x = 1 TO PasswordBoxSize
    PRINT PasswordBoxDesc(x) & "  ->  " & PasswordBoxPass(x)
  NEXT x
  END(4)
END SUB


FUNCTION GetText(HashChar AS STRING, maxSize AS INTEGER, EscapeAllowed AS INTEGER, RandomPatch AS BYTE = 0) AS STRING
  REM Get some text, and return the string. If EscapeAllowed = 1 then Esc break will be catched, and the returned string will be just CHR(27)
  DIM AS INTEGER xpos, ypos
  DIM AS STRING Result, LastKey
  DIM AS BYTE BackSpaceFlag = 0
  xpos = POS(0)
  ypos = CSRLIN
  LOCATE ,, 1 ' Turn the cursor ON
  DO
    LOCATE ypos, xpos
    IF BackSpaceFlag = 1 THEN
      PRINT RepeatPrint(" ", LEN(Result) + 2);
      LOCATE ypos, xpos
      BackSpaceFlag = 0
    END IF
    IF LEN(HashChar) = 0 THEN
        PRINT Result;
      ELSE
        PRINT RepeatPrint(HashChar, LEN(Result));
    END IF
    LastKey = INKEY
    WHILE LEN(LastKey) = 0  ' Wait for a keypress
      SLEEP 100,1  ' avoids hogging 100% of CPU when the process runs in background
      LastKey = INKEY
    WEND
    IF LEN(LastKey) = 1 THEN
        SELECT CASE ASC(LastKey)
          CASE IS >= 32
            IF LEN(Result) < maxSize THEN Result += LastKey
          CASE 8 ' Backspace
            IF LEN(Result) > 0 THEN Result = LEFT(Result, LEN(Result) - 1)
            BackSpaceFlag = 1
          CASE 27 ' Escape
            IF EscapeAllowed = 1 THEN
              Result = CHR(27)
              LastKey = CHR(13)
            END IF
        END SELECT
      ELSE
        IF LastKey = CHR(255) + "C" THEN ' F9 (Insert a random char)
          IF RandomPatch = 1 AND LEN(Result) < maxSize THEN Result += RandChar()
        END IF
    END IF
  LOOP UNTIL LastKey = CHR(13)
  LOCATE ,, 0 ' Turn the cursor OFF
  RETURN Result
END FUNCTION


SUB DelEntry(SelectedEntry AS INTEGER)
  DIM AS INTEGER x
  PasswordBoxSize -= 1
  FOR x = SelectedEntry TO PasswordBoxSize
    PasswordBoxDesc(x) = PasswordBoxDesc(x + 1)
    PasswordBoxPass(x) = PasswordBoxPass(x + 1)
  NEXT x
  PasswordBoxDesc(PasswordBoxSize + 1) = ""
  PasswordBoxPass(PasswordBoxSize + 1) = ""
  ModFlag = 1
END SUB


SUB AddEntry(BYREF SelectedEntry AS INTEGER)
  DIM AS INTEGER x
  DIM AS BYTE AbortedFlag = 0
  IF PasswordBoxSize = UBOUND(PasswordBoxPass) THEN ' Redim tables if needed
    REDIM PRESERVE PasswordBoxPass(1 TO PasswordBoxSize * 2) AS STRING
    REDIM PRESERVE PasswordBoxDesc(1 TO PasswordBoxSize * 2) AS STRING
  END IF
  PasswordBoxSize += 1
  FOR x = PasswordBoxSize TO SelectedEntry + 2 STEP -1
    PasswordBoxDesc(x) = PasswordBoxDesc(x - 1)
    PasswordBoxPass(x) = PasswordBoxPass(x - 1)
  NEXT x
  COLOR 15, 4
  LOCATE ScreenHeight \ 3 + 1, 3 : PRINT GraphTable(1) & RepeatPrint(GraphTable(2), ScreenWidth - 6) & GraphTable(3);
  LOCATE ScreenHeight \ 3 + 2, 3 : PRINT GraphTable(4) & RepeatPrint(" ", ScreenWidth - 6) & GraphTable(4);
  LOCATE ScreenHeight \ 3 + 3, 3 : PRINT GraphTable(4) & RepeatPrint(" ", ScreenWidth - 6) & GraphTable(4);
  LOCATE ScreenHeight \ 3 + 4, 3 : PRINT GraphTable(5) & RepeatPrint(GraphTable(2), ScreenWidth - 6) & GraphTable(6);
  LOCATE ScreenHeight \ 3 + 2, 5 : PRINT "Summary : ";
  PasswordBoxDesc(SelectedEntry + 1) = GetText("", ScreenWidth - 18, 1)
  IF PasswordBoxDesc(SelectedEntry + 1) = CHR(27) THEN
      AbortedFlag = 1
    ELSE
      IF ScreenWidth >= 40 THEN LOCATE ScreenHeight \ 3 + 4, ScreenWidth - 31 : PRINT "[Use F9 to get random chars]";
      LOCATE ScreenHeight \ 3 + 3, 5 : PRINT "Password: ";
      PasswordBoxPass(SelectedEntry + 1) = GetText("",  ScreenWidth - 18, 1, 1)
      IF PasswordBoxPass(SelectedEntry + 1) = CHR(27) THEN
          AbortedFlag = 1
        ELSE
          ModFlag = 1
          IF PasswordBoxSize = 1 THEN SelectedEntry = 1 ELSE SelectedEntry += 1
      END IF
  END IF
  IF AbortedFlag = 1 THEN
    ThrowMsg("Aborted!", 2000)
    FOR x = SelectedEntry + 1 TO PasswordBoxSize
      PasswordBoxDesc(x) = PasswordBoxDesc(x + 1)
      PasswordBoxPass(x) = PasswordBoxPass(x + 1)
    NEXT x
    PasswordBoxSize -= 1
  END IF
END SUB


SUB GetTerminalSize()
  DIM AS INTEGER RawSysWidth
  RawSysWidth = WIDTH
  IF ScreenWidth <> LOWORD(RawSysWidth) OR ScreenHeight <> HIWORD(RawSysWidth) THEN
      ScreenWidth = LOWORD(RawSysWidth)
      ScreenHeight = HIWORD(RawSysWidth)
      MaxQuickSearchFilterSize = ScreenWidth - 15
      TerminalSizeChanged = 1
    ELSE
      TerminalSizeChanged = 0
  END IF
  IF ScreenWidth < 20 OR ScreenHeight < 10 THEN
    COLOR 7, 0
    CLS
    PRINT "Terminal is not big enough!"
    PRINT "Requires at least 20x10."
    END(10)
  END IF
END SUB


SUB DrawTitleBar()  ' Draw the title bar
  IF TerminalSizeChanged = 1 THEN
    COLOR 14, 2
    LOCATE 1, 1 : PRINT LEFT(" PasswordBox v" & pVer & " Copyright (C) Mateusz Viste " & pDate & SPACE(ScreenWidth), ScreenWidth);
  END IF
END SUB


SUB DrawStatusBar() ' Draw the status bar
  DIM AS STRING InfoTxt
  IF LEN(QuickSearchFilter) = 0 THEN
      IF PasswordBoxSize = 0 THEN InfoTxt = " |  [Press INSERT to create a new entry]" ' If the base is empty, display a little hint
      COLOR 0, 3
      LOCATE ScreenHeight, 1 : PRINT LEFT(" F1: Help  |  Esc: Quit " & InfoTxt & SPACE(ScreenWidth), ScreenWidth);
    ELSE
      COLOR 0, 3
      LOCATE ScreenHeight, 1 : PRINT LEFT(" QuickSearch: " & QuickSearchFilter & SPACE(ScreenWidth), ScreenWidth);
  END IF
END SUB


SUB ShowHelp()
  IF ScreenWidth >= 40 AND ScreenHeight >= 15 THEN
      COLOR 0, 3
      LOCATE 3, 3 : PRINT GraphTable(1); RepeatPrint(GraphTable(2), 34); GraphTable(3);
      LOCATE 4, 3 : PRINT GraphTable(4); " Up/Down: Select an entry         "; GraphTable(4);
      LOCATE 5, 3 : PRINT GraphTable(4); " PgUp/PgDown: Scroll pages        "; GraphTable(4);
      LOCATE 6, 3 : PRINT GraphTable(4); " Home/End: Jump throught list     "; GraphTable(4);
      LOCATE 7, 3 : PRINT GraphTable(4); " ENTER: Display selected password "; GraphTable(4);
      LOCATE 8, 3 : PRINT GraphTable(4); " INSERT: Add a record             "; GraphTable(4);
      LOCATE 9, 3 : PRINT GraphTable(4); " DELETE: Remove selected record   "; GraphTable(4);
      LOCATE 10, 3: PRINT GraphTable(4); " F1: Display this help screen     "; GraphTable(4);
      LOCATE 11, 3: PRINT GraphTable(4); " F10: Setup                       "; GraphTable(4);
      LOCATE 12, 3: PRINT GraphTable(4); " Esc: Quit                        "; GraphTable(4);
      LOCATE 13, 3: PRINT GraphTable(5); RepeatPrint(GraphTable(2), 16); "[ press any key ]"; GraphTable(2); GraphTable(6);
      SLEEP
    ELSE
      ThrowMsg("Terminal is not big enough!", 2000)
  END IF
  FlushKeyb()
END SUB


SUB MoveEntryUp(SelectedEntry AS INTEGER)
  DIM AS STRING TempDesc, TempPass
  TempDesc = PasswordBoxDesc(SelectedEntry)
  TempPass = PasswordBoxPass(SelectedEntry)
  PasswordBoxDesc(SelectedEntry) = PasswordBoxDesc(SelectedEntry - 1)
  PasswordBoxPass(SelectedEntry) = PasswordBoxPass(SelectedEntry - 1)
  PasswordBoxDesc(SelectedEntry - 1) = TempDesc
  PasswordBoxPass(SelectedEntry - 1) = TempPass
  ModFlag = 1
END SUB


SUB MoveEntryDown(SelectedEntry AS INTEGER)
  DIM AS STRING TempDesc, TempPass
  TempDesc = PasswordBoxDesc(SelectedEntry)
  TempPass = PasswordBoxPass(SelectedEntry)
  PasswordBoxDesc(SelectedEntry) = PasswordBoxDesc(SelectedEntry + 1)
  PasswordBoxPass(SelectedEntry) = PasswordBoxPass(SelectedEntry + 1)
  PasswordBoxDesc(SelectedEntry + 1) = TempDesc
  PasswordBoxPass(SelectedEntry + 1) = TempPass
  ModFlag = 1
END SUB


SUB LoadGraphTable()
  SELECT CASE AsciiMode
    CASE 0 ' Plain ASCII
      GraphTable(1) = "+" : GraphTable(2) = "-" : GraphTable(3) = "+"
      GraphTable(4) = "|" : GraphTable(5) = "+" : GraphTable(6) = "+"
      GraphTable(7) = "|"
    CASE 1 ' CP 437
      GraphTable(1) = CHR(201) : GraphTable(2) = CHR(205) : GraphTable(3) = CHR(187)
      GraphTable(4) = CHR(186) : GraphTable(5) = CHR(200) : GraphTable(6) = CHR(188)
      GraphTable(7) = CHR(179)
    CASE 2 ' UTF-8
      GraphTable(1) = "╔" : GraphTable(2) = "═" : GraphTable(3) = "╗"
      GraphTable(4) = "║" : GraphTable(5) = "╚" : GraphTable(6) = "╝"
      GraphTable(7) = "│"
  END SELECT
END SUB


SUB SetupMenu() ' Requires at least a 40x10 terminal
  DIM CPName(0 TO 2) AS STRING*10 => {"ASCII     ","CP437     ","UTF-8     "}
  DIM AS STRING LastKey
  DIM AS INTEGER Choice = 1

  IF ScreenWidth >= 40 AND ScreenHeight >= 10 THEN
      COLOR 0, 3
      LOCATE 3, 4: PRINT GraphTable(1); RepeatPrint(GraphTable(2), 29); GraphTable(3);
      LOCATE 4, 4: PRINT GraphTable(4); RepeatPrint(" ", 29); GraphTable(4);
      LOCATE 5, 4: PRINT GraphTable(4); RepeatPrint(" ", 29); GraphTable(4);
      LOCATE 6, 4: PRINT GraphTable(4); RepeatPrint(" ", 29); GraphTable(4);
      LOCATE 7, 4: PRINT GraphTable(5); RepeatPrint(GraphTable(2), 29); GraphTable(6);
      DO
        IF Choice = 1 THEN COLOR 15, 5 ELSE COLOR 0, 3
        LOCATE 4, 5 : PRINT " Change your MASTER password "
        IF Choice = 2 THEN COLOR 15, 5 ELSE COLOR 0, 3
        LOCATE 5, 5 : PRINT " Display codepage: "; CPName(AsciiMode);
        IF Choice = 3 THEN COLOR 15, 5 ELSE COLOR 0, 3
        LOCATE 6, 5 : PRINT " Go Back                     "
        SLEEP
        LastKey = INKEY
        FlushKeyb()
        SELECT CASE LastKey
          CASE CHR(13)
            SELECT CASE Choice
              CASE 1
                NextAction = "ConfirmChangeMasterPassword"
                LastKey = CHR(27)
              CASE 2
                IF AsciiMode < 2 THEN AsciiMode += 1 ELSE AsciiMode = 0
                ModFlag = 1
              CASE 3
                LastKey = CHR(27)
            END SELECT
          CASE CHR(255) + "H"  ' Up
            IF Choice > 1 THEN Choice -= 1
          CASE CHR(255) + "P"  ' Down
            IF Choice < 3 THEN Choice += 1
        END SELECT
      LOOP UNTIL LastKey = CHR(27)
    ELSE
      ThrowMsg("Terminal is not big enough!", 2000)
  END IF
END SUB


SUB ChangeMasterPassword()
  DIM AS STRING NewPass
  IF ScreenWidth >= 40 AND ScreenHeight >= 10 THEN
      COLOR 0, 6
      LOCATE 3, 3 : PRINT GraphTable(1); RepeatPrint(GraphTable(2), 34); GraphTable(3);
      LOCATE 4, 3 : PRINT GraphTable(4); RepeatPrint(" ", 34); GraphTable(4);
      LOCATE 5, 3 : PRINT GraphTable(4); RepeatPrint(" ", 34); GraphTable(4);
      LOCATE 6, 3 : PRINT GraphTable(5); RepeatPrint(GraphTable(2), 34); GraphTable(6);
      COLOR 7, 6
      LOCATE 4, 5 : PRINT "Enter your new MASTER password";
      COLOR 15, 6
      LOCATE 5, 5
      NewPass = GetText("", 30, 1) ' Max 30 chars, EscapeChar allowed.
      IF NewPass <> CHR(27) THEN
          PassPhrase = LEFT((NewPass & CHR(3,141,59,26,53,58,97,93,238,46,26,43,38,32,79,50,28,8)), 16)
          ModFlag = 1
        ELSE
          ThrowMsg("Password change aborted!", 2000)
      END IF
    ELSE
      ThrowMsg("Terminal is not big enough!", 2000)
  END IF
END SUB


FUNCTION QuickSearch() AS INTEGER
  DIM AS INTEGER Result = 0, x = 0
  WHILE Result = 0 AND x < PasswordBoxSize
    x += 1
    IF INSTR(UCASE(PasswordBoxDesc(x)), UCASE(QuickSearchFilter)) > 0 THEN Result = x
  WEND
  RETURN Result
END FUNCTION


REM  * * *  Here begins the main program  * * *


DIM AS INTEGER x, SelectedEntry = 1, FirstDisplayedEntry = 1
DIM AS STRING LastKey

IF LEN(COMMAND(2)) > 0 THEN About()
REM IF LEN(COMMAND(1)) > 0 AND LCASE(COMMAND(1)) <> "--dump" THEN About()

ConfigFile = GetConfFile()
DebugOut("ConfigFile = " + ConfigFile)

SELECT CASE CheckDataFile()
  CASE 0
    PRINT "Invalid datafile. Program aborted."
    END(2)
  CASE -1
    PRINT "No database have been found. Your encrypted database will be initialised now."
    PRINT "The database will be stored at the following location:"
    PRINT GetConfFile()
    PRINT
    PRINT "Choose a master password: ";
    PassPhrase = GetText("", 30, 0)
    IF LEN(PassPhrase) = 0 THEN PRINT "Invalid master password! (can't be empty)." : END(1)
    PassPhrase = LEFT((PassPhrase & CHR(3,141,59,26,53,58,97,93,238,46,26,43,38,32,79,50,28,8)), 16)
    ModFlag = 1
  CASE 1
    REM PRINT "Enter your master password: ";
    REM PassPhrase = GetText("*", 30, 0)  ' Hash with "*", max 30 chars, EscapeChar not allowed
    PassPhrase = COMMAND(1)
    REM PRINT ' Carriage return
    REM IF LEN(PassPhrase) = 0 THEN SLEEP 2000, 1 : PRINT "Password rejected." : END(1)
    IF LEN(PassPhrase) = 0 THEN END(1)
    PassPhrase = LEFT((PassPhrase & CHR(3,141,59,26,53,58,97,93,238,46,26,43,38,32,79,50,28,8)), 16)
    REM IF CheckPassPhrase() <> 1 THEN SLEEP 2000, 1 : PRINT "Password rejected." : END(1)
    IF CheckPassPhrase() <> 1 THEN END(1)
    PRINT "Password Found: ", COMMAND(1)
    END(0)
    LoadBox()
END SELECT

IF LCASE(COMMAND(1)) = "--dump" THEN DumpBox
LoadGraphTable()
LOCATE ,, 0  ' Turn off the blinking cursor
RANDOMIZE TIMER, 3 ' Seed the random generator with system TIMER, and set the "Mersenne Twister" RND algorithm.

DO
  GetTerminalSize() ' Set ScreenWidth and ScreenHeight, and TerminalSizeChanged if modification detected
  IF PasswordBoxSize = 0 THEN SelectedEntry = 0
  DrawTitleBar()
  FOR x = FirstDisplayedEntry TO FirstDisplayedEntry + ScreenHeight - 3
    LOCATE 2 + x - FirstDisplayedEntry, 1
    IF x <= PasswordBoxSize THEN
        COLOR 8, 0
        PRINT GraphTable(7);
        IF x = SelectedEntry THEN COLOR 7, 1 ELSE COLOR 7, 0
        PRINT LEFT(" " & PasswordBoxDesc(x) & SPACE(ScreenWidth), ScreenWidth - 2);
        COLOR 8, 0
        PRINT GraphTable(7);
      ELSE
        COLOR 8, 0
        PRINT GraphTable(7) & SPACE(ScreenWidth - 2) & GraphTable(7);
    END IF
  NEXT x
  DrawStatusBar()

  FlushKeyb()
  IF LEN(NextAction) = 0 THEN
      SLEEP
      LastKey = INKEY
      SELECT CASE LastKey
        CASE CHR(255) + "H"  ' Up
          IF SelectedEntry > 1 THEN SelectedEntry -= 1
          QuickSearchFilter = ""
        CASE CHR(255) + "P"  ' Down
          IF SelectedEntry < PasswordBoxSize THEN SelectedEntry += 1
          QuickSearchFilter = ""
        CASE CHR(255) + "S"  ' Delete
          IF PasswordBoxSize > 0 THEN
            ThrowMsg("The selected entry will be erased. Shall we proceed? [Y/N]")
            SLEEP
            IF LCASE(INKEY) = "y" THEN
              DelEntry(SelectedEntry)
              IF SelectedEntry > PasswordBoxSize AND PasswordBoxSize > 0 THEN SelectedEntry = PasswordBoxSize
            END IF
          END IF
          QuickSearchFilter = ""
        CASE CHR(255) + "R"  ' Insert
          AddEntry(SelectedEntry)
          QuickSearchFilter = ""
        CASE "+"             ' +
          IF LEN(QuickSearchFilter) = 0 THEN
              IF PasswordBoxSize > 1 AND SelectedEntry < PasswordBoxSize THEN
                MoveEntryDown(SelectedEntry)
                SelectedEntry += 1
              END IF
            ELSE
              IF LEN(QuickSearchFilter) < MaxQuickSearchFilterSize THEN QuickSearchFilter += "+"
          END IF
        CASE "-"             ' -
          IF LEN(QuickSearchFilter) = 0 THEN
              IF PasswordBoxSize > 1 AND SelectedEntry > 1 THEN
                MoveEntryUp(SelectedEntry)
                SelectedEntry -= 1
              END IF
              QuickSearchFilter = ""
            ELSE
              IF LEN(QuickSearchFilter) < MaxQuickSearchFilterSize THEN QuickSearchFilter += "-"
          END IF
        CASE CHR(13)         ' ENTER
          IF PasswordBoxSize > 0 THEN ThrowMsg(PasswordBoxPass(SelectedEntry), -1)
          QuickSearchFilter = ""
        CASE CHR(255) + "G"  ' Home
          SelectedEntry = 1
          QuickSearchFilter = ""
        CASE CHR(255) + "O"  ' End
          IF PasswordBoxSize > 0 THEN SelectedEntry = PasswordBoxSize
          QuickSearchFilter = ""
        CASE CHR(255) + "I"  ' PgUp
          IF PasswordBoxSize > 0 THEN
            IF SelectedEntry - ScreenHeight + 2 > 1 THEN
                SelectedEntry = SelectedEntry - Screenheight + 2
              ELSE
                SelectedEntry = 1
            END IF
          END IF
          QuickSearchFilter = ""
        CASE CHR(255) + "Q"  ' PgDown
          IF PasswordBoxSize > 0 THEN
            IF SelectedEntry + ScreenHeight - 2 < PasswordBoxSize THEN
                SelectedEntry = SelectedEntry + Screenheight - 2
              ELSE
                SelectedEntry = PasswordBoxSize
            END IF
          END IF
          QuickSearchFilter = ""
        CASE CHR(255) + ";"  ' F1 (help)
          ShowHelp()
          QuickSearchFilter = ""
        CASE CHR(255) + "D"  ' F10 (setup)
          SetupMenu()
          LoadGraphTable()
          QuickSearchFilter = ""
        CASE CHR(27)         ' Escape (quit)
          IF LEN(QuickSearchFilter) = 0 THEN
              IF ModFlag = 1 THEN
                ThrowMsg("Some data has been changed. Do you want to save? [Y/N]")
                SLEEP
                IF NOT LCASE(INKEY) = "y" THEN ModFlag = -1
                NextAction = "Quit"
                LastKey = ""
              END IF
            ELSE
              QuickSearchFilter = ""
              LastKey = ""
          END IF
        CASE ELSE ' QuickSearch handler
          IF LEN(LastKey) = 1 THEN
            SELECT CASE ASC(LastKey)
              CASE IS >= 32
                IF LEN(QuickSearchFilter) < MaxQuickSearchFilterSize THEN
                  IF ASC(LastKey) <> 32 OR LEN(QuickSearchFilter) > 0 THEN QuickSearchFilter += LastKey
                END IF
              CASE 8
                IF LEN(QuickSearchFilter) > 0 THEN QuickSearchFilter = LEFT(QuickSearchFilter, LEN(QuickSearchFilter) - 1)
            END SELECT
          END IF
      END SELECT
    ELSE '  A NextAction operation has been already programmed...
      SELECT CASE NextAction
        CASE "ConfirmChangeMasterPassword"
          ThrowMsg("You are going to change your MASTER password. Continue? [Y/N]")
          FlushKeyb()
          SLEEP
          IF LCASE(INKEY) = "y" THEN NextAction = "ChangeMasterPassword" ELSE NextAction = ""
        CASE "ChangeMasterPassword"  ' Requires a terminal of at least 40x10
          ChangeMasterPassword()
          NextAction = ""
        CASE "Quit"
          LastKey = CHR(27)
        CASE ELSE ' Reset the state for any unknown action (just in case...)
          ThrowMsg("Unknown action catched: """ & NextAction & """" & CHR(10) & "Operation aborted!", -1)
          NextAction = ""
      END SELECT
  END IF
  IF LEN(QuickSearchFilter) > 0 THEN
    x = QuickSearch()
    IF x > 0 THEN SelectedEntry = x
  END IF
  IF SelectedEntry > FirstDisplayedEntry + ScreenHeight - 3 THEN FirstDisplayedEntry = SelectedEntry - (ScreenHeight - 3)
  IF FirstDisplayedEntry > SelectedEntry AND SelectedEntry > 0 THEN FirstDisplayedEntry = SelectedEntry
LOOP UNTIL LastKey = CHR(27)

SELECT CASE ModFlag
  CASE 0
    ThrowMsg("No change made", 800)
  CASE 1
    SaveBox()
    ThrowMsg("Saved!", 1000)
  CASE -1
     ThrowMsg("Cancelled!", 800)
END SELECT

COLOR 7,0 : CLS
END
