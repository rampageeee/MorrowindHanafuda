@echo off
setlocal
if "%~1"=="" (
  echo usage: set BOB=C:\path\to\bob.jar ^& build_tools\build.bat ^<platform^> [output-dir]
  exit /b 2
)
if "%BOB%"=="" (
  echo BOB must point to a Defold Bob JAR
  exit /b 2
)
if not exist "%BOB%" (
  echo Bob JAR not found: %BOB%
  exit /b 2
)
set PLATFORM=%~1
set OUTPUT=%~2
if "%OUTPUT%"=="" set OUTPUT=dist\%PLATFORM%
if not exist "%OUTPUT%" mkdir "%OUTPUT%"
pushd "%~dp0.."
if "%JAVA%"=="" set "JAVA=java"
"%JAVA%" -jar "%BOB%" --archive --platform "%PLATFORM%" --architectures "%PLATFORM%" --root "%CD%" --output "build/%PLATFORM%" --bundle-output "%OUTPUT%" resolve distclean build bundle
set RESULT=%ERRORLEVEL%
popd
exit /b %RESULT%
