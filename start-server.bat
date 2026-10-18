@echo off
title Scroll POC Local Server
echo Starting local web server...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1" -Port 8080
pause
