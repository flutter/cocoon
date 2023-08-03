:: Copyright 2020 The Flutter Authors. All rights reserved.
:: Use of this source code is governed by a BSD-style license that can be
:: found in the LICENSE file.

REM Checks if cipd command is available.
FOR /F "tokens=*" %%g IN ('where cipd') do (SET CIPD=%%g)
IF %ERRORLEVEL% NEQ 0 (
        ECHO "Please install CIPD (available from depot_tools) and add to path first.";
        EXIT
)

REM `path` is \path\to\device_doctor\tool\
REM `DIR` is \path\to\device_doctor\tool
SET path=%~dp0
SET DIR=%path:~0,-1%
%CIPD% ensure --ensure-file %path%\ensure_file_windows -root %DIR%

REM `BUILD_DIR` is \path\to\device_doctor
for %%a in (%DIR:~0,-1%) do set "BUILD_DIR=%%~dpa"
PUSHD %BUILD_DIR%
if exist %BUILD_DIR%\build (
        ECHO "Please remove the build directory before proceeding"
        EXIT 1
)
MKDIR %BUILD_DIR%\build

call tool\bin\dart.exe pub get
call tool\bin\dart.exe compile exe bin\main.dart -o build\device_doctor.exe
IF "%ERRORLEVEL%" NEQ "0" (
        EXIT 1
)

REM Add PATH for xcopy
SET "PATH=%PATH%;C:\Windows\system32"
xcopy LICENSE %BUILD_DIR%\build\.
