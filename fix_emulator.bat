@echo off
echo Closing any hanging emulator processes...
taskkill /F /IM qemu-system-x86_64.exe /T 2>nul
taskkill /F /IM emulator.exe /T 2>nul

echo Clearing lock files for Pixel_7...
del /s /q "%USERPROFILE%\.android\avd\Pixel_7.avd\*.lock"

echo.
echo Done! Please try to start the emulator from Device Manager now.
echo If it still fails, use "Cold Boot Now" from the Device Manager menu.
pause