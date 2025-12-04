# cython: language_level=3

import customtkinter as ctk
import tkinter.simpledialog as sd
import tkinter.filedialog as fd
import tkinter.messagebox as mb
import os
import datetime
import pyttsx3
import threading
from tkinter import ttk

# Import compiled tools module
from . import secure_tools

ctk.set_appearance_mode("dark")
ctk.set_default_color_theme("blue")

class AccessibilityManager:
    def __init__(self):
        self.tts_engine = None
        self.high_contrast_mode = False
        self.speak_ui_changes = False
        self.large_text_mode = False
        self.reduce_motion = False
        self.initialize_tts()
    
    def initialize_tts(self):
        try:
            self.tts_engine = pyttsx3.init()
            self.tts_engine.setProperty('rate', 150)
            self.tts_engine.setProperty('volume', 1.0)
            voices = self.tts_engine.getProperty('voices')
            if voices:
                self.tts_engine.setProperty('voice', voices[0].id)
        except Exception as e:
            print(f"TTS initialization error: {e}")
            self.tts_engine = None
    
    def speak(self, text, interrupt=False):
        if self.speak_ui_changes and self.tts_engine:
            try:
                if interrupt:
                    self.tts_engine.stop()
                def speak_thread():
                    try:
                        self.tts_engine.say(text)
                        self.tts_engine.runAndWait()
                    except RuntimeError:
                        self.tts_engine = None
                        self.initialize_tts()
                thread = threading.Thread(target=speak_thread, daemon=True)
                thread.start()
            except Exception as e:
                print(f"Speak error: {e}")
    
    def toggle_high_contrast(self, app):
        self.high_contrast_mode = not self.high_contrast_mode
        
        if self.high_contrast_mode:
            colors = {
                "bg": "#000000",
                "fg": "#FFFFFF",
                "button_bg": "#000000",
                "button_hover": "#333333",
                "button_text": "#FFFFFF",
                "button_border": "#FFFFFF",
                "text": "#FFFFFF",
                "console_bg": "#000000",
                "console_fg": "#FFFFFF",
                "border": "#FFFFFF",
                "tab_bg": "#000000",
                "tab_fg": "#FFFFFF",
                "tab_selected": "#333333",
                "header_bg": "#000000",
                "header_fg": "#FFFFFF"
            }
        else:
            colors = {
                "bg": "#2b2b2b",
                "fg": "#D4D4D4",
                "button_bg": "#1f538d",
                "button_hover": "#14375e",
                "button_text": "#D4D4D4",
                "button_border": "#3e3e42",
                "text": "#D4D4D4",
                "console_bg": "#1e1e1e",
                "console_fg": "#cccccc",
                "border": "#3e3e42",
                "tab_bg": "#2b2b2b",
                "tab_fg": "#D4D4D4",
                "tab_selected": "#1f538d",
                "header_bg": "#2b2b2b",
                "header_fg": "#00aaff"
            }
        
        app.configure(fg_color=colors["bg"])
        app.console.configure(
            fg_color=colors["console_bg"],
            text_color=colors["console_fg"],
            border_color=colors["border"]
        )
        
        for widget in app.winfo_children():
            self.update_widget_colors(widget, colors, app)
        
        self.speak("High contrast mode " + ("enabled" if self.high_contrast_mode else "disabled"))
    
    def update_widget_colors(self, widget, colors, app):
        try:
            if isinstance(widget, ctk.CTkFrame):
                if widget.cget("fg_color") not in ["transparent", None]:
                    widget.configure(fg_color=colors["bg"], border_color=colors["border"])
            
            elif isinstance(widget, ctk.CTkButton):
                widget.configure(
                    fg_color=colors["button_bg"],
                    hover_color=colors["button_hover"],
                    text_color=colors["button_text"],
                    border_color=colors["button_border"],
                    border_width=1 if self.high_contrast_mode and colors["button_border"] != "#3e3e42" else 0
                )
            
            elif isinstance(widget, (ctk.CTkLabel, ctk.CTkEntry, ctk.CTkTextbox)):
                widget.configure(text_color=colors["text"])
            
            elif isinstance(widget, ctk.CTkTabview):
                widget.configure(
                    fg_color=colors["tab_bg"],
                    segmented_button_fg_color=colors["tab_selected"],
                    segmented_button_selected_color=colors["tab_selected"],
                    segmented_button_selected_hover_color=colors["tab_selected"],
                    segmented_button_unselected_color=colors["tab_bg"],
                    segmented_button_unselected_hover_color=colors["tab_selected"],
                    text_color=colors["tab_fg"],
                    border_color=colors["border"]
                )
            
            for child in widget.winfo_children():
                self.update_widget_colors(child, colors, app)
        except Exception:
            pass
    
    def toggle_speak_ui(self):
        self.speak_ui_changes = not self.speak_ui_changes
        status = "enabled" if self.speak_ui_changes else "disabled"
        self.speak(f"Screen reader {status}")
        return self.speak_ui_changes
    
    def toggle_large_text(self, app):
        self.large_text_mode = not self.large_text_mode
        
        width = app.winfo_width()
        if self.large_text_mode:
            if width < 768:
                font_sizes = {"title": 20, "subtitle": 16, "section": 18, "button": 14, "label": 14, "console": 13}
            else:
                font_sizes = {"title": 32, "subtitle": 20, "section": 20, "button": 16, "label": 16, "console": 14}
        else:
            if width < 768:
                font_sizes = {"title": 18, "subtitle": 14, "section": 16, "button": 12, "label": 12, "console": 11}
            else:
                font_sizes = {"title": 28, "subtitle": 18, "section": 18, "button": 14, "label": 14, "console": 11}
        
        self.update_font_sizes(app, font_sizes)
        self.speak("Large text mode " + ("enabled" if self.large_text_mode else "disabled"))
    
    def update_font_sizes(self, widget, font_sizes):
        try:
            if isinstance(widget, ctk.CTkLabel):
                font_info = widget.cget("font")
                if isinstance(font_info, tuple):
                    current_font = list(font_info)
                    if len(current_font) > 1:
                        if "bold" in str(font_info).lower() and "century" in str(font_info).lower():
                            current_font[1] = font_sizes.get("title", current_font[1])
                        else:
                            current_font[1] = font_sizes.get("label", current_font[1])
                        widget.configure(font=tuple(current_font))
            
            elif isinstance(widget, ctk.CTkButton):
                font_info = widget.cget("font")
                if isinstance(font_info, tuple):
                    current_font = list(font_info)
                    if len(current_font) > 1:
                        current_font[1] = font_sizes.get("button", current_font[1])
                        widget.configure(font=tuple(current_font))
            
            elif isinstance(widget, ctk.CTkTextbox):
                widget.configure(font=("Consolas", font_sizes.get("console", 11)))
            
            for child in widget.winfo_children():
                self.update_font_sizes(child, font_sizes)
        except Exception:
            pass
    
    def toggle_reduce_motion(self):
        self.reduce_motion = not self.reduce_motion
        self.speak("Reduced motion " + ("enabled" if self.reduce_motion else "disabled"))
        return self.reduce_motion

class ConsoleOutput(ctk.CTkTextbox):
    def __init__(self, master, **kwargs):
        super().__init__(master, **kwargs)
        self.font_size = 11
        self.configure(
            font=("Consolas", self.font_size),
            fg_color="#1e1e1e",
            text_color="#cccccc",
            border_width=1,
            border_color="#333333",
            wrap="word"
        )
        self.tag_config("timestamp", foreground="#6a9955")
        self.tag_config("success", foreground="#4ec9b0")
        self.tag_config("error", foreground="#f44747")
        self.tag_config("warning", foreground="#d7ba7d")
        self.tag_config("info", foreground="#9cdcfe")
        self.tag_config("input", foreground="#ce9178")
        self.tag_config("system", foreground="#569cd6")
        
        self.bind("<Control-MouseWheel>", self.zoom_text)
        self.bind("<Control-plus>", lambda e: self.zoom_in())
        self.bind("<Control-minus>", lambda e: self.zoom_out())
        self.bind("<Control-0>", lambda e: self.reset_zoom())
        
    def log(self, message, tag="info"):
        timestamp = datetime.datetime.now().strftime("[%H:%M:%S]")
        self.insert("end", f"{timestamp} ", "timestamp")
        self.insert("end", f"{message}\n", tag)
        self.see("end")
        
    def clear(self):
        self.delete("1.0", "end")
        
    def zoom_text(self, event):
        if event.delta > 0:
            self.zoom_in()
        else:
            self.zoom_out()
            
    def zoom_in(self):
        if self.font_size < 24:
            self.font_size += 1
            self.configure(font=("Consolas", self.font_size))
            
    def zoom_out(self):
        if self.font_size > 8:
            self.font_size -= 1
            self.configure(font=("Consolas", self.font_size))
            
    def reset_zoom(self):
        self.font_size = 11
        self.configure(font=("Consolas", self.font_size))

class AccessibilitySettingsWindow(ctk.CTkToplevel):
    def __init__(self, parent, accessibility_manager):
        super().__init__(parent)
        self.accessibility = accessibility_manager
        
        self.title("Accessibility Settings")
        self.geometry("500x600")
        self.resizable(False, False)
        
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)
        
        container = ctk.CTkFrame(self)
        container.grid(row=0, column=0, padx=20, pady=20, sticky="nsew")
        container.grid_columnconfigure(0, weight=1)
        
        title = ctk.CTkLabel(container, text="Accessibility Settings", 
                            font=("Century Gothic", 24, "bold"))
        title.grid(row=0, column=0, pady=(0, 20), sticky="w")
        
        self.create_toggle_switch(container, 1, "Screen Reader", 
                                 "Speak UI elements and notifications",
                                 self.accessibility.speak_ui_changes,
                                 self.toggle_screen_reader)
        
        self.create_toggle_switch(container, 2, "High Contrast Mode",
                                 "Black and white high contrast mode",
                                 self.accessibility.high_contrast_mode,
                                 lambda: self.toggle_high_contrast(parent))
        
        self.create_toggle_switch(container, 3, "Large Text Mode",
                                 "Increase text size throughout the application",
                                 self.accessibility.large_text_mode,
                                 lambda: self.toggle_large_text(parent))
        
        self.create_toggle_switch(container, 4, "Reduce Motion",
                                 "Reduce animations and transitions",
                                 self.accessibility.reduce_motion,
                                 self.toggle_reduce_motion)
        
        separator = ctk.CTkFrame(container, height=2, fg_color="#3e3e42")
        separator.grid(row=5, column=0, pady=20, sticky="ew")
        
        test_button = ctk.CTkButton(container, text="Test Screen Reader", 
                                   command=self.test_screen_reader,
                                   height=40, font=("Segoe UI", 14))
        test_button.grid(row=6, column=0, pady=5, sticky="ew")
        
        self.create_button(container, 7, "Reset All Settings", 
                          self.reset_settings, "#e74c3c", "#c0392b")
        
        self.create_button(container, 8, "Close", 
                          self.destroy, "#2d2d30", "#3e3e42")
    
    def create_toggle_switch(self, parent, row, title, description, initial_state, command):
        frame = ctk.CTkFrame(parent, fg_color="transparent")
        frame.grid(row=row, column=0, pady=10, sticky="ew")
        frame.grid_columnconfigure(0, weight=1)
        
        label_frame = ctk.CTkFrame(frame, fg_color="transparent")
        label_frame.grid(row=0, column=0, sticky="w")
        
        title_label = ctk.CTkLabel(label_frame, text=title, 
                                  font=("Segoe UI", 16, "bold"))
        title_label.grid(row=0, column=0, sticky="w")
        
        desc_label = ctk.CTkLabel(label_frame, text=description,
                                 font=("Segoe UI", 12), text_color="#aaaaaa")
        desc_label.grid(row=1, column=0, pady=(2, 0), sticky="w")
        
        switch = ctk.CTkSwitch(frame, text="", command=command)
        switch.grid(row=0, column=1, padx=10)
        
        if initial_state:
            switch.select()
    
    def create_button(self, parent, row, text, command, fg_color, hover_color):
        btn = ctk.CTkButton(parent, text=text, command=command,
                           height=40, font=("Segoe UI", 14),
                           fg_color=fg_color, hover_color=hover_color)
        btn.grid(row=row, column=0, pady=5, sticky="ew")
    
    def toggle_screen_reader(self):
        state = self.accessibility.toggle_speak_ui()
        if state:
            self.accessibility.speak("Accessibility settings opened. Screen reader is now active.")
    
    def toggle_high_contrast(self, app):
        self.accessibility.toggle_high_contrast(app)
    
    def toggle_large_text(self, app):
        self.accessibility.toggle_large_text(app)
    
    def toggle_reduce_motion(self):
        self.accessibility.toggle_reduce_motion()
    
    def test_screen_reader(self):
        self.accessibility.speak("This is a test of the screen reader functionality. If you can hear this, the text to speech is working correctly.")
    
    def reset_settings(self):
        self.accessibility.speak_ui_changes = False
        self.accessibility.high_contrast_mode = False
        self.accessibility.large_text_mode = False
        self.accessibility.reduce_motion = False
        self.accessibility.speak("All accessibility settings have been reset to default")
        self.destroy()

class SecurityApp(ctk.CTk):
    def __init__(self):
        super().__init__()
        
        self.accessibility = AccessibilityManager()
        self.title("Secure Suite Pro")
        self.state('zoomed')
        
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(0, weight=1)
        self.grid_rowconfigure(1, weight=20)
        self.grid_rowconfigure(2, weight=0)
        self.grid_rowconfigure(3, weight=5)
        
        self.setup_header()
        self.setup_mobile_nav()
        self.console = ConsoleOutput(self)
        self.setup_tabs()
        self.setup_console()
        
        self.console.log("Secure Suite Pro initialized", "success")
        self.console.log("Ready to use security tools", "info")
        
        self.bind("<Configure>", self.on_window_resize)
        self.bind("<Control-Shift-A>", lambda e: self.open_accessibility_settings())
        self.bind("<Control-Shift-S>", lambda e: self.accessibility.toggle_speak_ui())
        self.bind("<Control-Shift-C>", lambda e: self.accessibility.toggle_high_contrast(self))
        
        self.update_mobile_view()
        
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Secure Suite Pro application loaded")

    def setup_header(self):
        self.header = ctk.CTkFrame(self, height=60)
        self.header.grid(row=0, column=0, sticky="nsew", padx=10, pady=(10, 0))
        self.header.grid_columnconfigure(0, weight=1)
        
        self.title_label = ctk.CTkLabel(self.header, text="Secure Suite Pro", 
                            font=("Century Gothic", 28, "bold"), 
                            text_color="#00aaff")
        self.title_label.grid(row=0, column=0, padx=20, pady=10, sticky="w")
        
        self.settings_button = ctk.CTkButton(self.header, text="⚙️", width=50, height=40,
                                       font=("Arial", 20), command=self.open_accessibility_settings,
                                       fg_color="transparent", hover_color="#3e3e42",
                                       border_width=1, border_color="#3e3e42")
        self.settings_button.grid(row=0, column=1, padx=20, pady=10, sticky="e")
    
    def setup_mobile_nav(self):
        self.mobile_nav = ctk.CTkFrame(self, height=60, fg_color="transparent")
        self.mobile_nav.grid(row=2, column=0, sticky="nsew", padx=10, pady=(0, 5))
        self.mobile_nav.grid_columnconfigure(0, weight=1)
        self.mobile_nav.grid_columnconfigure(1, weight=1)
        self.mobile_nav.grid_columnconfigure(2, weight=1)
        self.mobile_nav.grid_columnconfigure(3, weight=1)
        
        self.nav_buttons = []
        
        nav_items = [
            ("🏠", "Home", 0),
            ("🔐", "Password", 1),
            ("🔒", "Encryption", 2),
            ("📁", "Files", 3),
            ("🌐", "Network", 4),
            ("⚡", "Advanced", 5)
        ]
        
        for i, (icon, text, tab_index) in enumerate(nav_items):
            btn = ctk.CTkButton(self.mobile_nav, text=f"{icon}\n{text}", 
                               command=lambda idx=tab_index: self.switch_to_tab(idx),
                               height=60,
                               fg_color="transparent",
                               hover_color="#3e3e42",
                               border_width=1,
                               border_color="#3e3e42",
                               font=("Arial", 10))
            btn.grid(row=0, column=i, sticky="nsew", padx=2)
            self.nav_buttons.append(btn)

    def switch_to_tab(self, tab_index):
        tabs = ["Home", "Password Tools", "Encryption", "File Tools", "Network Tools", "Advanced Tools"]
        if tab_index < len(tabs):
            self.tabview.set(tabs[tab_index])
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak(f"Switched to {tabs[tab_index]} tab")

    def open_accessibility_settings(self):
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Opening accessibility settings")
        
        if hasattr(self, '_accessibility_window') and self._accessibility_window.winfo_exists():
            self._accessibility_window.lift()
        else:
            self._accessibility_window = AccessibilitySettingsWindow(self, self.accessibility)
            self._accessibility_window.focus()
            self._accessibility_window.protocol("WM_DELETE_WINDOW", 
                                              self._accessibility_window.destroy)

    def on_window_resize(self, event):
        width = self.winfo_width()
        height = self.winfo_height()
        
        self.update_mobile_view()
        
        if width < 768:
            self.tabview.configure(width=width-40)
            for tab_name in ["Home", "Password Tools", "Encryption", "File Tools", "Network Tools", "Advanced Tools"]:
                tab = self.tabview.tab(tab_name)
                for widget in tab.winfo_children():
                    if isinstance(widget, ctk.CTkScrollableFrame):
                        widget.configure(width=width-60)
                        
        elif width < 1024:
            self.tabview.configure(width=width-100)
        else:
            self.tabview.configure(width=1150)
    
    def update_mobile_view(self):
        width = self.winfo_width()
        
        if width < 768:
            self.header.grid_remove()
            self.mobile_nav.grid()
            self.tabview.grid(row=1, column=0, padx=5, pady=(5, 0), sticky="nsew")
            self.title_label.configure(font=("Century Gothic", 20, "bold"))
            
            for btn in self.nav_buttons:
                btn.configure(font=("Arial", 9))
        else:
            self.header.grid()
            self.mobile_nav.grid_remove()
            self.tabview.grid(row=1, column=0, padx=10, pady=(10, 5), sticky="nsew")
            self.title_label.configure(font=("Century Gothic", 28, "bold"))

    def setup_tabs(self):
        self.tabview = ctk.CTkTabview(self)
        self.tabview.grid(row=1, column=0, padx=10, pady=(10, 5), sticky="nsew")
        
        self.tabview.add("Home")
        self.tabview.add("Password Tools")
        self.tabview.add("Encryption")
        self.tabview.add("File Tools")
        self.tabview.add("Network Tools")
        self.tabview.add("Advanced Tools")
        
        self.setup_home_tab()
        self.setup_password_tab()
        self.setup_encryption_tab()
        self.setup_file_tab()
        self.setup_network_tab()
        self.setup_advanced_tab()

    def setup_console(self):
        console_header = ctk.CTkFrame(self, height=40)
        console_header.grid(row=3, column=0, padx=20, pady=(5, 0), sticky="ew")
        console_header.grid_columnconfigure(0, weight=1)
        
        console_label = ctk.CTkLabel(console_header, text="Console Output", font=("Consolas", 14, "bold"), text_color="#4ec9b0")
        console_label.grid(row=0, column=0, padx=10, pady=5, sticky="w")
        
        zoom_frame = ctk.CTkFrame(console_header, fg_color="transparent")
        zoom_frame.grid(row=0, column=1, padx=5, pady=5)
        
        zoom_in_btn = ctk.CTkButton(zoom_frame, text="+", width=30, height=30, command=self.console.zoom_in)
        zoom_in_btn.pack(side="left", padx=2)
        
        zoom_out_btn = ctk.CTkButton(zoom_frame, text="-", width=30, height=30, command=self.console.zoom_out)
        zoom_out_btn.pack(side="left", padx=2)
        
        reset_zoom_btn = ctk.CTkButton(zoom_frame, text="Reset", width=60, height=30, command=self.console.reset_zoom)
        reset_zoom_btn.pack(side="left", padx=2)
        
        button_frame = ctk.CTkFrame(console_header, fg_color="transparent")
        button_frame.grid(row=0, column=2, padx=5, pady=5)
        
        clear_btn = ctk.CTkButton(button_frame, text="Clear", width=80, height=30, command=self.clear_console, fg_color="#2d2d30", hover_color="#3e3e42")
        clear_btn.pack(side="left", padx=2)
        
        copy_btn = ctk.CTkButton(button_frame, text="Copy", width=80, height=30, command=self.copy_console, fg_color="#2d2d30", hover_color="#3e3e42")
        copy_btn.pack(side="left", padx=2)
        
        self.console.grid(row=4, column=0, padx=20, pady=(0, 20), sticky="nsew")

    def clear_console(self):
        self.console.clear()
        self.console.log("Console cleared", "info")
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Console cleared")

    def copy_console(self):
        content = self.console.get("1.0", "end-1c")
        self.clipboard_clear()
        self.clipboard_append(content)
        self.console.log("Console content copied to clipboard", "success")
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Console content copied to clipboard")

    def setup_home_tab(self):
        tab = self.tabview.tab("Home")
        frame = ctk.CTkScrollableFrame(tab)
        frame.pack(pady=10, fill="both", expand=True)
        
        width = self.winfo_width()
        if width < 768:
            title_size = 24
            subtitle_size = 14
            feature_font_size = 12
        else:
            title_size = 48 if width > 1024 else 32
            subtitle_size = 24 if width > 1024 else 18
            feature_font_size = 16 if width > 1024 else 14
        
        title = ctk.CTkLabel(frame, text="Secure Suite Pro", font=("Century Gothic", title_size, "bold"), text_color="#00aaff")
        title.pack(pady=20 if width > 768 else 10)
        
        subtitle = ctk.CTkLabel(frame, text="Professional Security Toolkit", font=("Century Gothic", subtitle_size), text_color="#aaaaaa")
        subtitle.pack(pady=10 if width > 768 else 5)
        
        features_frame = ctk.CTkFrame(frame, fg_color="transparent")
        features_frame.pack(pady=20 if width > 768 else 10)
        
        features = [
            "Password Generation & Strength Analysis",
            "Multiple Encryption Methods",
            "File Operations",
            "Network Tools",
            "Security Utilities",
            "Resizable Console"
        ]
        
        for feature in features:
            feature_frame = ctk.CTkFrame(features_frame, fg_color="transparent")
            feature_frame.pack(pady=3)
            icon = ctk.CTkLabel(feature_frame, text="✓", font=("Arial", feature_font_size), text_color="#4CAF50", width=20)
            icon.pack(side="left", padx=(0, 5))
            label = ctk.CTkLabel(feature_frame, text=feature, font=("Segoe UI", feature_font_size), text_color="#cccccc")
            label.pack(side="left")
        
        quick_btn = ctk.CTkButton(frame, text="Quick System Info", command=self.quick_system_info, 
                                  width=200 if width > 768 else 150, 
                                  height=40 if width > 768 else 30)
        quick_btn.pack(pady=15)
        
        version = ctk.CTkLabel(frame, text="Version 3.2 • Accessibility Edition", font=("Century Gothic", 12), text_color="#666666")
        version.pack(pady=10)

    def setup_password_tab(self):
        tab = self.tabview.tab("Password Tools")
        frame = ctk.CTkScrollableFrame(tab)
        frame.pack(pady=10, fill="both", expand=True)
        
        width = self.winfo_width()
        title_size = 28 if width > 1024 else 22 if width > 768 else 18
        
        title = ctk.CTkLabel(frame, text="Password Tools", font=("Century Gothic", title_size, "bold"))
        title.pack(pady=15)
        
        self.create_section(frame, "Password Generation", [
            ("Generate Strong Password", self.generate_password),
            ("Generate Passphrase", self.generate_passphrase),
            ("Generate Username", self.generate_username)
        ])
        
        self.create_input_section(frame, "Password Analysis", "Enter password:", self.check_password)
        self.create_input_section(frame, "Password Entropy", "Enter password:", self.calculate_entropy)
        self.create_input_section(frame, "Password Strength", "Enter password:", self.password_strength)
        self.create_input_section(frame, "Check Pwned Password", "Enter password:", self.check_pwned)
        self.create_input_section(frame, "Wordlist Generator", "Enter base word:", self.generate_wordlist)
        
        hash_frame = ctk.CTkFrame(frame, corner_radius=10)
        hash_frame.pack(fill="x", padx=20, pady=10)
        ctk.CTkLabel(hash_frame, text="String Hashing", font=("Century Gothic", 18)).pack(pady=10)
        
        hash_input_frame = ctk.CTkFrame(hash_frame, fg_color="transparent")
        hash_input_frame.pack(pady=10)
        
        self.hash_text_entry = ctk.CTkEntry(hash_input_frame, width=300, placeholder_text="Enter text to hash")
        self.hash_text_entry.pack(side="left", padx=5)
        
        self.hash_algo_var = ctk.StringVar(value="sha256")
        hash_combo = ctk.CTkComboBox(hash_input_frame, values=["md5", "sha1", "sha256", "sha512"], 
                                     variable=self.hash_algo_var, width=120)
        hash_combo.pack(side="left", padx=5)
        
        hash_btn = ctk.CTkButton(hash_input_frame, text="Hash", width=80, command=self.hash_string)
        hash_btn.pack(side="left", padx=5)

    def setup_encryption_tab(self):
        tab = self.tabview.tab("Encryption")
        frame = ctk.CTkScrollableFrame(tab)
        frame.pack(pady=10, fill="both", expand=True)
        
        width = self.winfo_width()
        title_size = 28 if width > 1024 else 22 if width > 768 else 18
        
        title = ctk.CTkLabel(frame, text="Encryption Tools", font=("Century Gothic", title_size, "bold"))
        title.pack(pady=15)
        
        sections = [
            ("Caesar Encrypt", "Enter text:", self.caesar_encrypt),
            ("Caesar Decrypt", "Enter text:", self.caesar_decrypt),
            ("Caesar Bruteforce", "Enter text:", self.caesar_bruteforce),
            ("ROT13 Transform", "Enter text:", self.rot13_transform),
            ("Base64 Encode", "Enter text:", self.base64_encode),
            ("Base64 Decode", "Enter text:", self.base64_decode),
            ("Hex Encode", "Enter text:", self.hex_encode),
            ("Hex Decode", "Enter hex:", self.hex_decode),
            ("Morse Encode", "Enter text:", self.morse_encode),
            ("Morse Decode", "Enter morse:", self.morse_decode),
            ("Reverse String", "Enter text:", self.reverse_string),
            ("URL Encode", "Enter text:", self.url_encode),
            ("URL Decode", "Enter URL:", self.url_decode)
        ]
        
        for section_title, placeholder, command in sections:
            self.create_input_section(frame, section_title, placeholder, command)
        
        self.create_section(frame, "AES Encryption", [
            ("Generate AES Key", self.generate_aes_key),
            ("AES Encrypt File", self.aes_encrypt_file),
            ("AES Decrypt File", self.aes_decrypt_file)
        ])
        
        self.create_section(frame, "XOR Encryption", [
            ("XOR Encrypt String", self.xor_string_encrypt),
            ("XOR Decrypt String", self.xor_string_decrypt),
            ("Generate Random Key", self.generate_random_key)
        ])

    def setup_file_tab(self):
        tab = self.tabview.tab("File Tools")
        frame = ctk.CTkScrollableFrame(tab)
        frame.pack(pady=10, fill="both", expand=True)
        
        width = self.winfo_width()
        title_size = 28 if width > 1024 else 22 if width > 768 else 18
        
        title = ctk.CTkLabel(frame, text="File Tools", font=("Century Gothic", title_size, "bold"))
        title.pack(pady=15)
        
        file_sections = [
            ("Calculate MD5", self.calculate_md5),
            ("Calculate SHA256", self.calculate_sha256),
            ("File Integrity Check", self.file_integrity_check),
            ("Analyze File Type", self.analyze_file_type),
            ("Secure Delete File", self.secure_delete_file)
        ]
        
        for section_title, command in file_sections:
            self.create_file_section(frame, section_title, command)
        
        self.create_input_section(frame, "Generate QR Code", "Enter text:", self.generate_qr)

    def setup_network_tab(self):
        tab = self.tabview.tab("Network Tools")
        frame = ctk.CTkScrollableFrame(tab)
        frame.pack(pady=10, fill="both", expand=True)
        
        width = self.winfo_width()
        title_size = 28 if width > 1024 else 22 if width > 768 else 18
        
        title = ctk.CTkLabel(frame, text="Network Tools", font=("Century Gothic", title_size, "bold"))
        title.pack(pady=15)
        
        self.create_input_section(frame, "Validate IP Address", "Enter IP:", self.validate_ip)
        self.create_input_section(frame, "Port Scanner", "Enter target IP:", self.port_scan)
        
        self.create_section(frame, "System Information", [
            ("Get System Info", self.get_system_info),
            ("Get Network Info", self.get_network_info),
            ("Monitor Processes", self.monitor_processes)
        ])
        
        self.create_simple_button(frame, "Detect Keylogger", self.detect_keylogger)

    def setup_advanced_tab(self):
        tab = self.tabview.tab("Advanced Tools")
        frame = ctk.CTkScrollableFrame(tab)
        frame.pack(pady=10, fill="both", expand=True)
        
        width = self.winfo_width()
        title_size = 28 if width > 1024 else 22 if width > 768 else 18
        
        title = ctk.CTkLabel(frame, text="Advanced Tools", font=("Century Gothic", title_size, "bold"))
        title.pack(pady=15)
        
        self.create_section(frame, "RSA Encryption", [("Generate RSA Keys", self.generate_rsa_keys)])
        self.create_section(frame, "File Operations", [
            ("XOR Encrypt File", self.xor_encrypt_file),
            ("XOR Decrypt File", self.xor_decrypt_file)
        ])
        
        self.create_simple_button(frame, "Clear All Temporary Files", self.clear_temp_files)
        self.create_simple_button(frame, "Show All Available Functions", self.show_all_functions)

    def create_section(self, parent, title, buttons):
        section = ctk.CTkFrame(parent, corner_radius=10)
        section.pack(fill="x", padx=20, pady=10)
        
        width = self.winfo_width()
        font_size = 18 if width > 1024 else 16 if width > 768 else 14
        
        ctk.CTkLabel(section, text=title, font=("Century Gothic", font_size)).pack(pady=8)
        
        for btn_text, command in buttons:
            btn_width = 300 if width > 1024 else 250 if width > 768 else 200
            btn = ctk.CTkButton(section, text=btn_text, command=command, 
                               height=40 if width > 768 else 35, 
                               width=btn_width,
                               font=("Segoe UI", 12 if width > 768 else 10))
            btn.pack(pady=3)

    def create_input_section(self, parent, title, placeholder, command):
        section = ctk.CTkFrame(parent, corner_radius=10)
        section.pack(fill="x", padx=20, pady=10)
        
        width = self.winfo_width()
        font_size = 18 if width > 1024 else 16 if width > 768 else 14
        
        ctk.CTkLabel(section, text=title, font=("Century Gothic", font_size)).pack(pady=8)
        
        input_frame = ctk.CTkFrame(section, fg_color="transparent")
        input_frame.pack(pady=8)
        
        entry_width = 350 if width > 1024 else 250 if width > 768 else 200
        entry = ctk.CTkEntry(input_frame, width=entry_width, placeholder_text=placeholder,
                            font=("Segoe UI", 12 if width > 768 else 10))
        entry.pack(side="left", padx=5)
        
        btn = ctk.CTkButton(input_frame, text="Execute", width=100, 
                           command=lambda: command(entry.get()),
                           font=("Segoe UI", 12 if width > 768 else 10))
        btn.pack(side="left", padx=5)

    def create_file_section(self, parent, title, command):
        section = ctk.CTkFrame(parent, corner_radius=10)
        section.pack(fill="x", padx=20, pady=10)
        
        width = self.winfo_width()
        font_size = 18 if width > 1024 else 16 if width > 768 else 14
        
        ctk.CTkLabel(section, text=title, font=("Century Gothic", font_size)).pack(pady=8)
        
        btn_width = 300 if width > 1024 else 250 if width > 768 else 200
        btn = ctk.CTkButton(section, text="Select File", command=command, 
                           height=40 if width > 768 else 35, 
                           width=btn_width,
                           font=("Segoe UI", 12 if width > 768 else 10))
        btn.pack(pady=8)

    def create_simple_button(self, parent, text, command):
        width = self.winfo_width()
        btn_width = 350 if width > 1024 else 250 if width > 768 else 200
        font_size = 16 if width > 1024 else 14 if width > 768 else 12
        
        btn = ctk.CTkButton(parent, text=text, command=command, 
                           height=50 if width > 768 else 40, 
                           width=btn_width, 
                           font=("Century Gothic", font_size))
        btn.pack(pady=15)

    def generate_password(self):
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Opening password generation dialog")
        try:
            length = sd.askinteger("Password Length", "Enter password length:", initialvalue=12, minvalue=4, maxvalue=50)
            if length:
                self.console.log(f"Generating password with length {length}...", "info")
                password = secure_tools.generate_password(length)
                self.console.log(f"Generated Password: {password}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak(f"Password generated successfully")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def generate_passphrase(self):
        try:
            self.console.log("Generating passphrase...", "info")
            passphrase = secure_tools.generate_passphrase()
            self.console.log(f"Generated Passphrase: {passphrase}", "success")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak("Passphrase generated")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def generate_username(self):
        try:
            self.console.log("Generating username...", "info")
            username = secure_tools.generate_username()
            self.console.log(f"Generated Username: {username}", "success")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak("Username generated")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def check_password(self, password):
        if password:
            try:
                self.console.log(f"Analyzing password...", "info")
                result = secure_tools.evaluate_password(password)
                self.console.log(f"Password Analysis:\n{result}", "info")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Password analysis completed")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def calculate_entropy(self, password):
        if password:
            try:
                entropy_value = secure_tools.entropy(password)
                self.console.log(f"Password: {'*' * len(password)}", "input")
                self.console.log(f"Entropy: {entropy_value} bits", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak(f"Password entropy is {entropy_value} bits")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def password_strength(self, password):
        if password:
            try:
                self.console.log(f"Checking password strength...", "info")
                result = secure_tools.password_strength_meter(password)
                self.console.log(f"Password Strength:\n{result}", "info")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Password strength check completed")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def check_pwned(self, password):
        if password:
            try:
                self.console.log(f"Checking password against breaches...", "info")
                result = secure_tools.check_pwned_password(password)
                self.console.log(result, "warning" if "found" in result else "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Password breach check completed")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def generate_wordlist(self, word):
        if word:
            try:
                self.console.log(f"Generating wordlist from: {word}", "info")
                filename = secure_tools.wordlist_generator(word)
                self.console.log(f"Wordlist saved to: {filename}", "success")
                mb.showinfo("Success", f"Wordlist saved as {filename}")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Wordlist generated and saved")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def hash_string(self):
        text = self.hash_text_entry.get()
        if text:
            try:
                algorithm = self.hash_algo_var.get()
                self.console.log(f"Hashing with {algorithm}...", "info")
                result = secure_tools.hash_string(text, algorithm)
                self.console.log(f"Input: {text}", "input")
                self.console.log(f"{algorithm.upper()}: {result}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak(f"Text hashed using {algorithm}")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def caesar_encrypt(self, text):
        if text:
            try:
                shift = sd.askinteger("Shift Value", "Enter shift value:", initialvalue=3, minvalue=1, maxvalue=25)
                if shift is not None:
                    self.console.log(f"Encrypting with Caesar shift {shift}...", "info")
                    encrypted = secure_tools.caesar_cipher(text, shift)
                    self.console.log(f"Original: {text}", "input")
                    self.console.log(f"Encrypted: {encrypted}", "success")
                    if self.accessibility.speak_ui_changes:
                        self.accessibility.speak("Text encrypted using Caesar cipher")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def caesar_decrypt(self, text):
        if text:
            try:
                shift = sd.askinteger("Shift Value", "Enter shift value:", initialvalue=3, minvalue=1, maxvalue=25)
                if shift is not None:
                    self.console.log(f"Decrypting with Caesar shift {shift}...", "info")
                    decrypted = secure_tools.caesar_decipher(text, shift)
                    self.console.log(f"Encrypted: {text}", "input")
                    self.console.log(f"Decrypted: {decrypted}", "success")
                    if self.accessibility.speak_ui_changes:
                        self.accessibility.speak("Text decrypted using Caesar cipher")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def caesar_bruteforce(self, text):
        if text:
            try:
                self.console.log(f"Bruteforcing Caesar cipher...", "info")
                self.console.log(f"Encrypted text: {text}", "input")
                results = secure_tools.caesar_bruteforce(text)
                self.console.log("Bruteforce Results:", "info")
                self.console.log(results, "info")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Caesar cipher brute force completed")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def rot13_transform(self, text):
        if text:
            try:
                self.console.log(f"Applying ROT13...", "info")
                result = secure_tools.rot13(text)
                self.console.log(f"Original: {text}", "input")
                self.console.log(f"ROT13: {result}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("ROT13 transformation applied")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def base64_encode(self, text):
        if text:
            try:
                self.console.log(f"Encoding to Base64...", "info")
                encoded = secure_tools.encode_base64(text)
                self.console.log(f"Original: {text}", "input")
                self.console.log(f"Base64: {encoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Text encoded to Base64")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def base64_decode(self, text):
        if text:
            try:
                self.console.log(f"Decoding from Base64...", "info")
                decoded = secure_tools.decode_base64(text)
                self.console.log(f"Base64: {text}", "input")
                self.console.log(f"Decoded: {decoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Base64 decoded")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def hex_encode(self, text):
        if text:
            try:
                self.console.log(f"Encoding to Hex...", "info")
                encoded = secure_tools.hex_encode(text)
                self.console.log(f"Original: {text}", "input")
                self.console.log(f"Hex: {encoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Text encoded to hexadecimal")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def hex_decode(self, hex_string):
        if hex_string:
            try:
                self.console.log(f"Decoding from Hex...", "info")
                decoded = secure_tools.hex_decode(hex_string)
                self.console.log(f"Hex: {hex_string}", "input")
                self.console.log(f"Decoded: {decoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Hexadecimal decoded")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def morse_encode(self, text):
        if text:
            try:
                self.console.log(f"Encoding to Morse...", "info")
                encoded = secure_tools.morse_encode(text)
                self.console.log(f"Original: {text}", "input")
                self.console.log(f"Morse: {encoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Text encoded to Morse code")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def morse_decode(self, morse):
        if morse:
            try:
                self.console.log(f"Decoding from Morse...", "info")
                decoded = secure_tools.morse_decode(morse)
                self.console.log(f"Morse: {morse}", "input")
                self.console.log(f"Decoded: {decoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Morse code decoded")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def reverse_string(self, text):
        if text:
            try:
                self.console.log(f"Reversing string...", "info")
                reversed_text = secure_tools.reverse_string(text)
                self.console.log(f"Original: {text}", "input")
                self.console.log(f"Reversed: {reversed_text}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("String reversed")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def url_encode(self, text):
        if text:
            try:
                self.console.log(f"URL encoding...", "info")
                encoded = secure_tools.url_encode(text)
                self.console.log(f"Original: {text}", "input")
                self.console.log(f"URL Encoded: {encoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("URL encoded")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def url_decode(self, text):
        if text:
            try:
                self.console.log(f"URL decoding...", "info")
                decoded = secure_tools.url_decode(text)
                self.console.log(f"URL: {text}", "input")
                self.console.log(f"Decoded: {decoded}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("URL decoded")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def generate_aes_key(self):
        try:
            key = secure_tools.aes_generate_key()
            file = fd.asksaveasfilename(defaultextension=".key", filetypes=[("Key files", "*.key")])
            if file:
                with open(file, 'wb') as f:
                    f.write(key)
                self.console.log(f"AES Key saved to: {file}", "success")
                mb.showinfo("Success", f"AES key saved to {file}")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("AES key generated and saved")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def aes_encrypt_file(self):
        try:
            file = fd.askopenfilename(title="Select file to encrypt")
            if file:
                key_file = fd.askopenfilename(title="Select AES Key File", filetypes=[("Key files", "*.key")])
                if key_file:
                    with open(key_file, 'rb') as f:
                        key = f.read()
                    with open(file, 'rb') as f:
                        data = f.read()
                    encrypted = secure_tools.aes_encrypt(data, key)
                    save_file = fd.asksaveasfilename(defaultextension=".enc", filetypes=[("Encrypted files", "*.enc")])
                    if save_file:
                        with open(save_file, 'wb') as f:
                            f.write(encrypted)
                        self.console.log(f"File encrypted to: {save_file}", "success")
                        mb.showinfo("Success", f"File encrypted to {save_file}")
                        if self.accessibility.speak_ui_changes:
                            self.accessibility.speak("File encrypted using AES")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def aes_decrypt_file(self):
        try:
            file = fd.askopenfilename(title="Select file to decrypt")
            if file:
                key_file = fd.askopenfilename(title="Select AES Key File", filetypes=[("Key files", "*.key")])
                if key_file:
                    with open(key_file, 'rb') as f:
                        key = f.read()
                    with open(file, 'rb') as f:
                        data = f.read()
                    try:
                        decrypted = secure_tools.aes_decrypt(data, key)
                        save_file = fd.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt")])
                        if save_file:
                            with open(save_file, 'wb') as f:
                                f.write(decrypted)
                            self.console.log(f"File decrypted to: {save_file}", "success")
                            mb.showinfo("Success", f"File decrypted to {save_file}")
                            if self.accessibility.speak_ui_changes:
                                self.accessibility.speak("File decrypted using AES")
                    except Exception as e:
                        self.console.log(f"Decryption failed: {str(e)}", "error")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def xor_string_encrypt(self):
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Opening XOR encryption dialog")
        text = sd.askstring("XOR Encrypt", "Enter text to encrypt:")
        if text:
            key = sd.askstring("XOR Key", "Enter encryption key:")
            if key:
                try:
                    self.console.log(f"XOR encrypting...", "info")
                    encrypted = secure_tools.xor_encrypt_string(text, key)
                    self.console.log(f"Text: {text}", "input")
                    self.console.log(f"Key: {key}", "input")
                    self.console.log(f"Encrypted: {encrypted}", "success")
                    if self.accessibility.speak_ui_changes:
                        self.accessibility.speak("Text encrypted using XOR")
                except Exception as e:
                    self.console.log(f"Error: {str(e)}", "error")

    def xor_string_decrypt(self):
        if self.accessibility.speak_ui_changes:
            self.accessibility.speak("Opening XOR decryption dialog")
        text = sd.askstring("XOR Decrypt", "Enter text to decrypt:")
        if text:
            key = sd.askstring("XOR Key", "Enter decryption key:")
            if key:
                try:
                    self.console.log(f"XOR decrypting...", "info")
                    decrypted = secure_tools.xor_decrypt_string(text, key)
                    self.console.log(f"Encrypted: {text}", "input")
                    self.console.log(f"Key: {key}", "input")
                    self.console.log(f"Decrypted: {decrypted}", "success")
                    if self.accessibility.speak_ui_changes:
                        self.accessibility.speak("Text decrypted using XOR")
                except Exception as e:
                    self.console.log(f"Error: {str(e)}", "error")

    def generate_random_key(self):
        try:
            length = sd.askinteger("Key Length", "Enter key length in bytes:", initialvalue=32, minvalue=8, maxvalue=128)
            if length:
                key = secure_tools.generate_random_key(length)
                self.console.log(f"Generated Random Key: {key}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Random key generated")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def xor_encrypt_file(self):
        try:
            file = fd.askopenfilename(title="Select file to encrypt")
            if file:
                key = sd.askstring("XOR Key", "Enter encryption key:")
                if key:
                    with open(file, 'rb') as f:
                        data = f.read()
                    encrypted = secure_tools.xor_encrypt(data, key.encode())
                    save_file = fd.asksaveasfilename(defaultextension=".xor", filetypes=[("XOR files", "*.xor")])
                    if save_file:
                        with open(save_file, 'wb') as f:
                            f.write(encrypted)
                        self.console.log(f"File XOR encrypted to: {save_file}", "success")
                        mb.showinfo("Success", f"File encrypted to {save_file}")
                        if self.accessibility.speak_ui_changes:
                            self.accessibility.speak("File encrypted using XOR")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def xor_decrypt_file(self):
        try:
            file = fd.askopenfilename(title="Select file to decrypt")
            if file:
                key = sd.askstring("XOR Key", "Enter decryption key:")
                if key:
                    with open(file, 'rb') as f:
                        data = f.read()
                    decrypted = secure_tools.xor_decrypt(data, key.encode())
                    save_file = fd.asksaveasfilename(defaultextension=".txt", filetypes=[("Text files", "*.txt")])
                    if save_file:
                        with open(save_file, 'wb') as f:
                            f.write(decrypted)
                        self.console.log(f"File XOR decrypted to: {save_file}", "success")
                        mb.showinfo("Success", f"File decrypted to {save_file}")
                        if self.accessibility.speak_ui_changes:
                            self.accessibility.speak("File decrypted using XOR")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def calculate_md5(self):
        try:
            file = fd.askopenfilename(title="Select file for MD5 hash")
            if file:
                self.console.log(f"Calculating MD5 for {os.path.basename(file)}...", "info")
                md5 = secure_tools.calculate_md5(file)
                self.console.log(f"MD5 Hash: {md5}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("MD5 hash calculated")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def calculate_sha256(self):
        try:
            file = fd.askopenfilename(title="Select file for SHA256 hash")
            if file:
                self.console.log(f"Calculating SHA256 for {os.path.basename(file)}...", "info")
                sha256 = secure_tools.calculate_sha256(file)
                self.console.log(f"SHA256 Hash: {sha256}", "success")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("SHA256 hash calculated")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def file_integrity_check(self):
        try:
            file1 = fd.askopenfilename(title="Select first file")
            if file1:
                file2 = fd.askopenfilename(title="Select second file")
                if file2:
                    self.console.log(f"Checking integrity between {os.path.basename(file1)} and {os.path.basename(file2)}...", "info")
                    result = secure_tools.file_integrity_check(file1, file2)
                    self.console.log(result, "info")
                    if self.accessibility.speak_ui_changes:
                        self.accessibility.speak("File integrity check completed")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def analyze_file_type(self):
        try:
            file = fd.askopenfilename(title="Select file to analyze")
            if file:
                self.console.log(f"Analyzing file type of {os.path.basename(file)}...", "info")
                result = secure_tools.analyze_file_type(file)
                self.console.log(result, "info")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("File type analysis completed")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def generate_qr(self, text):
        if text:
            try:
                self.console.log(f"Generating QR code for: {text}", "info")
                filename = secure_tools.generate_qr(text)
                self.console.log(f"QR code saved to: {filename}", "success")
                mb.showinfo("QR Code", f"QR code saved as {filename}")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("QR code generated")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def secure_delete_file(self):
        try:
            file = fd.askopenfilename(title="Select file to securely delete")
            if file:
                if mb.askyesno("Confirm", f"Securely delete {os.path.basename(file)}?\nThis action cannot be undone!"):
                    self.console.log(f"Securely deleting {file}...", "warning")
                    if secure_tools.secure_delete(file):
                        self.console.log(f"File securely deleted: {file}", "success")
                        mb.showinfo("Success", "File securely deleted")
                        if self.accessibility.speak_ui_changes:
                            self.accessibility.speak("File securely deleted")
                    else:
                        self.console.log("File not found or could not be deleted", "error")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def validate_ip(self, ip):
        if ip:
            try:
                self.console.log(f"Validating IP: {ip}", "info")
                is_valid = secure_tools.validate_ip(ip)
                result = "Valid IP address" if is_valid else "Invalid IP address"
                self.console.log(result, "success" if is_valid else "error")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak(f"IP address validation: {result}")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def port_scan(self, target):
        if target:
            try:
                if secure_tools.validate_ip(target):
                    self.console.log(f"Scanning {target}...", "info")
                    open_ports = secure_tools.port_scan(target)
                    if open_ports:
                        self.console.log(f"Open ports on {target}: {open_ports}", "warning")
                        if self.accessibility.speak_ui_changes:
                            self.accessibility.speak(f"Found {len(open_ports)} open ports")
                    else:
                        self.console.log(f"No common ports open on {target}", "info")
                        if self.accessibility.speak_ui_changes:
                            self.accessibility.speak("No open ports found")
                else:
                    self.console.log("Invalid IP address format", "error")
            except Exception as e:
                self.console.log(f"Error: {str(e)}", "error")

    def detect_keylogger(self):
        try:
            self.console.log("Scanning for keyloggers...", "info")
            processes = secure_tools.detect_keylogger()
            if processes:
                self.console.log(f"Suspicious processes detected:", "warning")
                for proc in processes:
                    self.console.log(f"  • {proc}", "warning")
                mb.showwarning("Warning", "Suspicious processes detected!")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Warning: Suspicious processes detected")
            else:
                self.console.log("No keyloggers detected", "success")
                mb.showinfo("Security Check", "No keyloggers detected")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Security check passed: No keyloggers detected")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def get_system_info(self):
        try:
            self.console.log("Getting system information...", "info")
            info = secure_tools.get_system_info()
            self.console.log("System Information:", "system")
            self.console.log(info, "info")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak("System information retrieved")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def get_network_info(self):
        try:
            self.console.log("Getting network information...", "info")
            info = secure_tools.get_network_info()
            self.console.log("Network Information:", "system")
            self.console.log(info, "info")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak("Network information retrieved")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def monitor_processes(self):
        try:
            self.console.log("Monitoring processes...", "info")
            processes = secure_tools.monitor_processes()
            if processes:
                self.console.log("Top 20 Processes:", "system")
                for proc in processes:
                    self.console.log(f"PID {proc['pid']}: {proc['name']} - CPU: {proc['cpu_percent']}%, Memory: {proc['memory_percent']}%", "info")
                if self.accessibility.speak_ui_changes:
                    self.accessibility.speak("Process monitoring completed")
            else:
                self.console.log("No process information available", "error")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def generate_rsa_keys(self):
        try:
            self.console.log("Generating RSA keys...", "info")
            private_key, public_key = secure_tools.generate_rsa_keys()
            private_file = fd.asksaveasfilename(defaultextension=".pem", filetypes=[("PEM files", "*.pem")], initialfile="private_key.pem")
            if private_file:
                with open(private_file, 'w') as f:
                    f.write(private_key)
                self.console.log(f"Private key saved to: {private_file}", "success")
            public_file = fd.asksaveasfilename(defaultextension=".pem", filetypes=[("PEM files", "*.pem")], initialfile="public_key.pem")
            if public_file:
                with open(public_file, 'w') as f:
                    f.write(public_key)
                self.console.log(f"Public key saved to: {public_file}", "success")
            mb.showinfo("RSA Keys", "RSA keys generated successfully")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak("RSA keys generated successfully")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def clear_temp_files(self):
        try:
            self.console.log("Clearing temporary files...", "info")
            files_removed = 0
            for file in ['qr.png', 'wordlist.txt', 'private_key.pem', 'public_key.pem']:
                if os.path.exists(file):
                    os.remove(file)
                    self.console.log(f"Removed: {file}", "info")
                    files_removed += 1
            self.console.log(f"Cleared {files_removed} temporary files", "success")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak(f"Cleared {files_removed} temporary files")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def show_all_functions(self):
        try:
            self.console.log("Available functions in secure_tools.py:", "system")
            functions = [name for name in dir(secure_tools) if callable(getattr(secure_tools, name)) and not name.startswith('_')]
            for i, func in enumerate(sorted(functions), 1):
                self.console.log(f"{i:2d}. {func}", "info")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak(f"Found {len(functions)} available functions")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")

    def quick_system_info(self):
        try:
            self.console.log("Quick System Info:", "system")
            sys_info = secure_tools.get_system_info()
            net_info = secure_tools.get_network_info()
            self.console.log(sys_info, "info")
            self.console.log(net_info, "info")
            if self.accessibility.speak_ui_changes:
                self.accessibility.speak("Quick system information displayed")
        except Exception as e:
            self.console.log(f"Error: {str(e)}", "error")