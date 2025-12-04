#!/bin/bash

echo "========================================"
echo "Secure Suite Pro - Cython Compilation"
echo "========================================"
echo ""

echo "Step 1: Installing dependencies..."
pip3 install -r requirements.txt
if [ $? -ne 0 ]; then
    echo "Failed to install dependencies"
    exit 1
fi

echo ""
echo "Step 2: Compiling Cython modules..."
python3 setup.py build_ext --inplace
if [ $? -ne 0 ]; then
    echo "Compilation failed"
    exit 1
fi

echo ""
echo "Step 3: Creating executable..."
pip3 install pyinstaller
if [ $? -ne 0 ]; then
    echo "Failed to install PyInstaller"
    exit 1
fi

echo "Creating standalone executable..."
pyinstaller --onefile --windowed --name "SecureSuitePro" --add-data "src/*.so:src/" run_compiled.py
if [ $? -ne 0 ]; then
    echo "Failed to create executable"
    exit 1
fi

echo ""
echo "========================================"
echo "Compilation Successful!"
echo "========================================"
echo ""
echo "The compiled executable is in the 'dist' folder"
echo "You can run it directly: ./dist/SecureSuitePro"
echo ""