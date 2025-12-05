#!/usr/bin/env python3
"""
Secure Suite Pro - Fixed Entry Point for PyInstaller
"""

import sys
import os
import traceback

# ============================================================================
# PATH SETUP - CRITICAL FOR PYINSTALLER
# ============================================================================

def setup_paths():
    """Setup paths for both PyInstaller executable and development mode."""
    
    # PyInstaller support
    if getattr(sys, 'frozen', False):
        # Running as compiled executable
        if hasattr(sys, '_MEIPASS'):
            # PyInstaller creates a temp folder
            base_path = sys._MEIPASS
            print(f"[EXE MODE] Using PyInstaller temp folder: {base_path}")
        else:
            base_path = os.path.dirname(sys.executable)
            print(f"[EXE MODE] Using executable folder: {base_path}")
    else:
        # Running as script
        base_path = os.path.dirname(os.path.abspath(__file__))
        print(f"[DEV MODE] Using script folder: {base_path}")
    
    # Add to Python path
    if base_path not in sys.path:
        sys.path.insert(0, base_path)
    
    # Add src folder if it exists
    src_path = os.path.join(base_path, 'src')
    if os.path.exists(src_path) and src_path not in sys.path:
        sys.path.insert(0, src_path)
    
    # Also try to find src in parent directory (for PyInstaller)
    parent_src = os.path.join(os.path.dirname(base_path), 'src')
    if os.path.exists(parent_src) and parent_src not in sys.path:
        sys.path.insert(0, parent_src)
    
    print(f"Python path: {sys.path}")
    return base_path

# ============================================================================
# DEPENDENCY CHECK
# ============================================================================

def check_dependencies():
    """Check if required packages are available."""
    required = ['customtkinter', 'pyttsx3', 'cryptography', 'psutil', 'qrcode', 'requests']
    missing = []
    
    for package in required:
        try:
            __import__(package)
        except ImportError:
            missing.append(package)
    
    return missing

# ============================================================================
# MAIN APPLICATION
# ============================================================================

def main():
    """Main entry point."""
    
    print("=" * 60)
    print("Secure Suite Pro - Starting")
    print("=" * 60)
    
    # Setup paths
    base_path = setup_paths()
    
    # Check dependencies
    missing = check_dependencies()
    if missing:
        error_msg = f"Missing required packages: {', '.join(missing)}\n\n"
        error_msg += "Please install with:\n"
        error_msg += "pip install " + " ".join(missing)
        show_error("Dependency Error", error_msg)
        return 1
    
    try:
        # DEBUG: Show what's in src folder
        src_path = os.path.join(base_path, 'src')
        if os.path.exists(src_path):
            print(f"\nContents of src folder:")
            for item in os.listdir(src_path):
                print(f"  - {item}")
        else:
            print(f"\nWARNING: src folder not found at: {src_path}")
        
        # Try to import the Cython compiled version
        print("\nAttempting to import SecurityApp...")
        
        # Method 1: Try direct import
        try:
            from src.secure_app import SecurityApp
            print("✓ Successfully imported from src.secure_app")
        except ImportError as e:
            print(f"✗ Import from src.secure_app failed: {e}")
            
            # Method 2: Try to find the module
            print("\nSearching for secure_app module...")
            for path in sys.path:
                secure_app_path = os.path.join(path, 'secure_app.pyx')
                secure_app_pyd = os.path.join(path, 'secure_app.pyd')
                secure_app_py = os.path.join(path, 'secure_app.py')
                
                if os.path.exists(secure_app_pyd):
                    print(f"Found .pyd file at: {secure_app_pyd}")
                if os.path.exists(secure_app_py):
                    print(f"Found .py file at: {secure_app_py}")
            
            raise ImportError("Could not import SecurityApp from any location")
        
        # Create and run the application
        print("\nCreating SecurityApp instance...")
        app = SecurityApp()
        
        print("Starting main loop...")
        app.mainloop()
        
        print("\nApplication closed successfully.")
        return 0
        
    except Exception as e:
        print(f"\n{'='*60}")
        print("FATAL ERROR")
        print(f"{'='*60}")
        print(f"Error type: {type(e).__name__}")
        print(f"Error message: {str(e)}")
        print(f"\nFull traceback:")
        traceback.print_exc()
        
        # Try to show error dialog
        error_msg = f"Application failed to start:\n\n{type(e).__name__}: {str(e)}\n\n"
        error_msg += "Please check the console for details."
        show_error("Startup Error", error_msg)
        
        return 1

# ============================================================================
# ERROR DISPLAY
# ============================================================================

def show_error(title, message):
    """Show error message, trying multiple methods."""
    print(f"\nERROR: {title}")
    print(message)
    
    # Try tkinter first
    try:
        import tkinter as tk
        from tkinter import messagebox
        
        root = tk.Tk()
        root.withdraw()
        messagebox.showerror(title, message)
        root.destroy()
        return
    except:
        pass
    
    # Try ctypes message box
    try:
        import ctypes
        ctypes.windll.user32.MessageBoxW(0, message, title, 0x10)  # 0x10 = Error icon
        return
    except:
        pass
    
    # Last resort: wait for user input
    input("\nPress Enter to exit...")

# ============================================================================
# ENTRY POINT
# ============================================================================

if __name__ == "__main__":
    # Always run with console in debug mode
    exit_code = main()
    
    if exit_code != 0:
        input("\nPress Enter to exit (error code: {})...".format(exit_code))
    
    sys.exit(exit_code)