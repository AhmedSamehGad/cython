@echo off
echo ========================================
echo Secure Suite Pro - Cython Compilation
echo ========================================
echo.

echo Step 1: Installing dependencies...
pip install -r requirements.txt
if %ERRORLEVEL% neq 0 (
    echo Failed to install dependencies
    pause
    exit /b 1
)

echo.
echo Step 2: Compiling Cython modules...
python setup.py build_ext --inplace
if %ERRORLEVEL% neq 0 (
    echo Compilation failed
    pause
    exit /b 1
)

echo.
echo Step 3: Creating executable...
pip install pyinstaller
if %ERRORLEVEL% neq 0 (
    echo Failed to install PyInstaller
    pause
    exit /b 1
)

echo Creating standalone executable...
pyinstaller --onefile --windowed --name "SecureSuitePro" --icon=icon.ico --add-data "src/*.pyd;src/" run_compiled.py
if %ERRORLEVEL% neq 0 (
    echo Failed to create executable
    pause
    exit /b 1
)

echo.
echo ========================================
echo Compilation Successful!
echo ========================================
echo.
echo The compiled executable is in the 'dist' folder
echo You can run it directly: dist\SecureSuitePro.exe
echo.
pause