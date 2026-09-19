@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "GODOT=%ROOT%\tools\Godot_v4.3-stable_win64_console.exe"
set "PROJECT=%ROOT%\game"
if not exist "%GODOT%" (
  echo SELFTEST_FAIL missing Godot console: %GODOT%
  exit /b 2
)

echo [1/4] Script and scene parse
"%GODOT%" --headless --path "%PROJECT%" --editor --quit
if errorlevel 1 goto fail

echo [2/4] Main menu startup
"%GODOT%" --headless --path "%PROJECT%" --quit-after 2
if errorlevel 1 goto fail

echo [3/4] Movement scene startup
"%GODOT%" --headless --path "%PROJECT%" res://scenes/arena.tscn --quit-after 2
if errorlevel 1 goto fail

echo [4/4] Current scene files
if not exist "%PROJECT%\scenes\menu.tscn" goto fail
if not exist "%PROJECT%\scenes\arena.tscn" goto fail
if errorlevel 1 goto fail

echo SELFTEST_PASS project_parse menu_start movement_start scene_files
exit /b 0

:fail
echo SELFTEST_FAIL step_failed errorlevel=%errorlevel%
exit /b 1
