@echo off
setlocal EnableDelayedExpansion

echo ==============================
echo Cleaning old build files...
echo ==============================

:: Delete old .pyd files
for /r %%i in (*.pyd) do (
    del /f /q "%%i"
)

:: Delete old dist folder
if exist dist (
    rmdir /s /q dist
)

echo ==============================
echo Installing required packages...
echo ==============================
for /f "usebackq tokens=*" %%i in ("requirements.txt") do (
    pip show %%i >nul 2>&1
    if errorlevel 1 (
        echo Installing %%i...
        pip install %%i
    ) else (
        echo %%i already installed.
    )
)

echo ==============================
echo Compiling Cython modules...
echo ==============================
python setup.py build_ext --inplace

echo ==============================
echo Compiling standalone EXE with Nuitka...
echo ==============================

:: Automatically include all packages from requirements.txt
set "INCLUDE_ARGS="
for /f "usebackq tokens=*" %%i in ("requirements.txt") do (
    set "PKG=%%i"
    set "PKG_NAME=!PKG:>=!"
    set "PKG_NAME=!PKG_NAME:<=!"
    set "PKG_NAME=!PKG_NAME:~0,99!"
    set "INCLUDE_ARGS=!INCLUDE_ARGS! --include-package=!PKG_NAME!"
)

python -m nuitka run_compiled.py ^
    --standalone ^
    --follow-imports ^
    --enable-plugin=numpy ^
    --enable-plugin=tk-inter ^
    %INCLUDE_ARGS% ^
    --output-dir=dist ^
    --show-progress ^
    --verbose

echo ==============================
echo Build finished! Check the dist folder.
echo ==============================
pause
endlocal
