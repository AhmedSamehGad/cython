@echo off
echo ============================================
echo    Secure Suite Pro - Build Script
echo ============================================
echo.

echo [1/4] Cleaning previous builds...
if exist build rmdir /s /q build 2>nul
if exist dist rmdir /s /q dist 2>nul
del /f /q *.spec 2>nul

echo.
echo [2/4] Compiling Cython modules...
if exist setup.py (
    echo Compiling Cython extensions...
    python setup.py build_ext --inplace
    if errorlevel 1 (
        echo WARNING: Cython compilation had issues
    ) else (
        echo Cython compilation completed
    )
) else (
    echo WARNING: setup.py not found, skipping Cython compilation
)

echo.
echo [3/4] Creating PyInstaller spec file...
(
echo # -*- mode: python ; coding: utf-8 -*-
echo.
echo block_cipher = None
echo.
echo a = Analysis(
echo     ['run_compiled.py']^,
echo     pathex=[]^,
echo     binaries=[]^,
echo     datas=[('src', 'src')]^,
echo     hiddenimports=[
echo         'customtkinter'^,
echo         'pyttsx3'^,
echo         'pyttsx3.drivers'^,
echo         'pyttsx3.drivers.sapi5'^,
echo         'pyttsx3.drivers.espeak'^,
echo         'pyttsx3.drivers.nsss'^,
echo         'pyttsx3.engine'^,
echo         'pyttsx3.voice'^,
echo         'cryptography'^,
echo         'cryptography.hazmat'^,
echo         'cryptography.hazmat.backends'^,
echo         'cryptography.hazmat.backends.openssl'^,
echo         'cryptography.hazmat.primitives'^,
echo         'cryptography.hazmat.primitives.ciphers'^,
echo         'psutil'^,
echo         'psutil._psutil_windows'^,
echo         'qrcode'^,
echo         'requests'^,
echo         'requests.certs'^,
echo         'urllib3'^,
echo         'chardet'^,
echo         'idna'^,
echo         'PIL'^,
echo         'PIL._imaging'^,
echo         'PIL.Image'^,
echo         'numpy'^,
echo     ]^,
echo     hookspath=[]^,
echo     hooksconfig={}^,
echo     runtime_hooks=[]^,
echo     excludes=[]^,
echo     win_no_prefer_redirects=False^,
echo     win_private_assemblies=False^,
echo     cipher=block_cipher^,
echo     noarchive=False^,
echo ^)
echo.
echo # Collect all package data
echo for pkg in ['customtkinter', 'pyttsx3', 'cryptography', 'psutil', 'qrcode', 'requests', 'PIL']:
echo     a.datas += collect_all(pkg, include_py_files=True^)
echo.
echo pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher^)
echo.
echo exe = EXE(
echo     pyz^,
echo     a.scripts^,
echo     a.binaries^,
echo     a.zipfiles^,
echo     a.datas^,
echo     []^,
echo     name='SecureSuitePro'^,
echo     debug=False^,
echo     bootloader_ignore_signals=False^,
echo     strip=False^,
echo     upx=True^,
echo     upx_exclude=[]^,
echo     runtime_tmpdir=None^,
echo     console=True^,
echo     disable_windowed_traceback=False^,
echo     argv_emulation=False^,
echo     target_arch=None^,
echo     codesign_identity=None^,
echo     entitlements_file=None^,
echo     icon=None^,
echo ^)
) > pyinstaller_spec.py

echo Spec file created: pyinstaller_spec.py

echo.
echo [4/4] Building with PyInstaller using spec file...
echo This may take a few minutes...
echo.

python -m PyInstaller --onefile pyinstaller_spec.py

echo.
echo Checking results...
if exist "dist\SecureSuitePro.exe" (
    echo.
    echo ============================================
    echo   BUILD SUCCESSFUL!
    echo ============================================
    echo   Executable: dist\SecureSuitePro.exe
    echo.
    echo To test, run:
    echo   dist\SecureSuitePro.exe
    echo.
    echo IMPORTANT: Keep the console window open to see errors!
) else (
    echo.
    echo ============================================
    echo   BUILD FAILED!
    echo ============================================
    echo   No executable was created.
    echo.
    echo Check for error messages above.
)

echo.
pause