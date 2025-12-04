#!/usr/bin/env python3
"""
Secure Suite Pro - Compiled Entry Point
This file should be used to run the compiled Cython application
"""

import sys
import os

# Add the src directory to the path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    # Try to import the compiled module
    from src.secure_app import SecurityApp
    
    def main():
        """Main entry point for the compiled application"""
        print("Secure Suite Pro - Compiled Version 3.2")
        print("Starting application...")
        
        app = SecurityApp()
        app.mainloop()
    
    if __name__ == "__main__":
        main()
        
except ImportError as e:
    print(f"Error importing compiled modules: {e}")
    print("\nYou need to compile the Cython modules first.")
    print("Run one of the following:")
    print("  Windows:   compile.bat")
    print("  Linux/Mac: ./compile.sh")
    print("\nOr install in development mode:")
    print("  pip install -e .")
    sys.exit(1)