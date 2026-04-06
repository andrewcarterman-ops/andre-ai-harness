@echo off
echo.
echo  🚀 Mission Control v2 - Linear Edition
echo  =====================================
echo.
echo  Starting setup...
echo.

cd /d "C:\Users\andre\.openclaw\workspace\skills\mission-control-v2"

echo  📦 Installing dependencies...
call npm install

if %errorlevel% neq 0 (
    echo.
    echo  ❌ Installation failed!
    echo  Make sure Node.js is installed.
    pause
    exit /b 1
)

echo.
echo  ✅ Dependencies installed!
echo.
echo  🚀 Starting development server...
echo  The app will open at http://localhost:3000
echo.

start http://localhost:3000

call npm run dev

pause
