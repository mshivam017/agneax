import sys
import os
import subprocess
import threading
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QTextEdit, QLineEdit, QTabWidget, 
                             QComboBox, QLabel, QPushButton)
from PySide6.QtCore import Qt, Signal, Slot, QProcess
from PySide6.QtGui import QFont, QTextCursor

class TerminalTab(QWidget):
    outputReceived = Signal(str)

    def __init__(self):
        super().__init__()
        self.layout = QVBoxLayout(self)
        self.layout.setContentsMargins(0, 0, 0, 0)
        self.layout.setSpacing(0)

        # Output viewer pane
        self.output_area = QTextEdit()
        self.output_area.setReadOnly(True)
        self.output_area.setFont(QFont("Consolas, Courier New, monospace", 11))
        self.output_area.setStyleSheet("background-color: #0B0D13; color: #00FF66; border: none; padding: 10px;")
        self.layout.addWidget(self.output_area)

        # Input line layout
        self.input_layout = QHBoxLayout()
        self.input_layout.setContentsMargins(10, 5, 10, 10)
        self.input_layout.setSpacing(6)
        
        self.prompt_label = QLabel("$")
        self.prompt_label.setStyleSheet("color: #00F2FE; font-weight: bold;")
        self.input_layout.addWidget(self.prompt_label)

        self.input_line = QLineEdit()
        self.input_line.setFont(QFont("Consolas, Courier New, monospace", 11))
        self.input_line.setStyleSheet("background-color: rgba(255,255,255,0.05); color: #FFFFFF; border: 1px solid rgba(255,255,255,0.1); border-radius: 4px; padding: 4px;")
        self.input_line.returnPressed.connect(self.send_command)
        self.input_layout.addWidget(self.input_line)

        self.layout.addLayout(self.input_layout)

        # Interactive Shell process runner
        self.process = QProcess(self)
        self.process.readyReadStandardOutput.connect(self.read_stdout)
        self.process.readyReadStandardError.connect(self.read_stderr)
        
        # Start command interpreter shell
        shell = "powershell.exe" if sys.platform == "win32" else "/bin/bash"
        self.process.start(shell)
        
        # Initial greeting banner
        self.output_area.append("=== Agneax GPU-Accelerated Terminal v0.1.0 ===\n")

    def read_stdout(self):
        data = self.process.readAllStandardOutput().data().decode('utf-8', errors='ignore')
        self.output_area.moveCursor(QTextCursor.End)
        self.output_area.insertPlainText(data)

    def read_stderr(self):
        data = self.process.readAllStandardError().data().decode('utf-8', errors='ignore')
        self.output_area.moveCursor(QTextCursor.End)
        self.output_area.insertPlainText(data)

    def send_command(self):
        cmd = self.input_line.text()
        self.input_line.clear()
        
        # Append input line locally
        self.output_area.append(f"\n$ {cmd}\n")
        
        # Write to shell stream
        self.process.write((cmd + "\n").encode('utf-8'))


class TerminalWindow(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Agneax Console")
        self.resize(750, 480)
        
        # Theme stylesheet
        self.setStyleSheet("""
            QMainWindow {
                background-color: #0F1219;
            }
            QTabWidget::pane {
                border: 1px solid rgba(255,255,255,0.08);
                background-color: #0F1219;
            }
            QTabBar::tab {
                background-color: #0B0D13;
                color: #A0AEC0;
                padding: 8px 16px;
                border-right: 1px solid rgba(255,255,255,0.05);
            }
            QTabBar::tab:selected {
                background-color: #141821;
                color: #FFFFFF;
                border-bottom: 2px solid #00F2FE;
            }
            QComboBox {
                background-color: #0B0D13;
                color: #FFFFFF;
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 4px;
                padding: 4px;
            }
        """)

        # Central widgets layout
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        self.layout.setContentsMargins(10, 10, 10, 10)
        
        # Toolbar header (Add tab + Theme selector)
        self.header_layout = QHBoxLayout()
        
        self.btn_new_tab = QPushButton("+ New Tab")
        self.btn_new_tab.setStyleSheet("background-color: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.1); color: white; padding: 4px 10px; border-radius: 4px;")
        self.btn_new_tab.clicked.connect(self.add_terminal_tab)
        self.header_layout.addWidget(self.btn_new_tab)

        self.header_layout.addStretch()

        self.theme_label = QLabel("Theme:")
        self.theme_label.setStyleSheet("color: white;")
        self.header_layout.addWidget(self.theme_label)

        self.theme_combo = QComboBox()
        self.theme_combo.addItems(["Agneax Neon", "Dracula Dark", "Cyberpunk Pink"])
        self.theme_combo.currentIndexChanged.connect(self.change_theme)
        self.header_layout.addWidget(self.theme_combo)

        self.layout.addLayout(self.header_layout)

        # Tab view manager
        self.tab_widget = QTabWidget()
        self.layout.addWidget(self.tab_widget)
        
        self.add_terminal_tab()

    def add_terminal_tab(self):
        tab = TerminalTab()
        index = self.tab_widget.addTab(tab, f"Shell {self.tab_widget.count() + 1}")
        self.tab_widget.setCurrentIndex(index)
        self.apply_theme_to_tab(tab, self.theme_combo.currentText())

    def change_theme(self, index):
        theme_name = self.theme_combo.currentText()
        for i in range(self.tab_widget.count()):
            tab = self.tab_widget.widget(i)
            self.apply_theme_to_tab(tab, theme_name)

    def apply_theme_to_tab(self, tab, theme_name):
        if not tab:
            return
        
        # Color palettes profiles
        if theme_name == "Agneax Neon":
            tab.output_area.setStyleSheet("background-color: #0B0D13; color: #00FF66; border: none; padding: 10px;")
        elif theme_name == "Dracula Dark":
            tab.output_area.setStyleSheet("background-color: #282a36; color: #f8f8f2; border: none; padding: 10px;")
        elif theme_name == "Cyberpunk Pink":
            tab.output_area.setStyleSheet("background-color: #1a0826; color: #ff007f; border: none; padding: 10px;")

def main():
    app = QApplication(sys.argv)
    window = TerminalWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
