@echo off
cd /d "%~dp0"
call dart tool\setup.dart
if errorlevel 1 exit /b 1
