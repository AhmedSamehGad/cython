# pyinstaller_spec.py
import PyInstaller.__main__
import os

args = [
    'run_compiled.py',
    '--name=SecureSuitePro',
    '--onefile',
    '--console',
    '--clean',
    '--noconfirm',
    
    # Add data
    '--add-data=src;src',
    
    # Hidden imports for all packages
    '--hidden-import=customtkinter',
    '--hidden-import=pyttsx3',
    '--hidden-import=pyttsx3.drivers',
    '--hidden-import=pyttsx3.drivers.sapi5',
    '--hidden-import=cryptography',
    '--hidden-import=cryptography.hazmat',
    '--hidden-import=cryptography.hazmat.backends',
    '--hidden-import=cryptography.hazmat.backends.openssl',
    '--hidden-import=cryptography.hazmat.primitives',
    '--hidden-import=cryptography.hazmat.primitives.ciphers',
    '--hidden-import=psutil',
    '--hidden-import=qrcode',
    '--hidden-import=requests',
    '--hidden-import=requests.certs',
    '--hidden-import=urllib3',
    '--hidden-import=chardet',
    '--hidden-import=idna',
    
    # Collect all data from these packages
    '--collect-all=customtkinter',
    '--collect-all=pyttsx3',
    '--collect-all=cryptography',
    '--collect-all=psutil',
    '--collect-all=qrcode',
    '--collect-all=requests',
]

PyInstaller.__main__.run(args)
