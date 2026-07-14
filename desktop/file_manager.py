import sys
import os
import subprocess
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QListWidget, QListWidgetItem, QTreeWidget, 
                             QTreeWidgetItem, QTabWidget, QToolBar, QLineEdit, 
                             QPushButton, QLabel, QSplitter, QStyle, QFrame)
from PySide6.QtCore import Qt, QSize, QDir

class FileManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Agneax Files")
        self.resize(850, 560)
        
        # Design system styles (Sleek dark theme)
        self.setStyleSheet("""
            QMainWindow {
                background-color: #0F1219;
            }
            QWidget {
                color: #FFFFFF;
                font-family: 'Segoe UI', Inter, Roboto;
                font-size: 12px;
            }
            QToolBar {
                background-color: #0B0D13;
                border-bottom: 1px solid rgba(255, 255, 255, 0.08);
                spacing: 8;
                padding: 6px;
            }
            QLineEdit {
                background-color: rgba(255, 255, 255, 0.08);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 6px;
                padding: 4px 10px;
                color: #FFFFFF;
            }
            QTreeWidget {
                background-color: #0B0D13;
                border: none;
                border-right: 1px solid rgba(255, 255, 255, 0.08);
            }
            QTreeWidget::item {
                padding: 6px;
            }
            QTreeWidget::item:hover {
                background-color: rgba(255, 255, 255, 0.04);
                border-radius: 4px;
            }
            QTreeWidget::item:selected {
                background-color: rgba(0, 242, 254, 0.15);
                color: #00F2FE;
                font-weight: bold;
            }
            QListWidget {
                background-color: #141821;
                border: none;
                padding: 10px;
            }
            QListWidget::item {
                background-color: rgba(255, 255, 255, 0.03);
                border: 1px solid rgba(255, 255, 255, 0.05);
                border-radius: 8px;
                padding: 10px;
                margin-bottom: 6px;
            }
            QListWidget::item:hover {
                background-color: rgba(255, 255, 255, 0.08);
                border-color: rgba(0, 242, 254, 0.3);
            }
            QListWidget::item:selected {
                background-color: rgba(0, 242, 254, 0.15);
                border-color: #00F2FE;
                color: #00F2FE;
            }
            QPushButton {
                background-color: rgba(255, 255, 255, 0.05);
                border: 1px solid rgba(255, 255, 255, 0.1);
                border-radius: 6px;
                padding: 4px 12px;
            }
            QPushButton:hover {
                background-color: rgba(255, 255, 255, 0.1);
            }
        """)

        # Main Layout
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.main_layout = QVBoxLayout(self.central_widget)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.main_layout.setSpacing(0)

        # 1. Navigation Toolbar
        self.toolbar = QToolBar()
        self.toolbar.setMovable(False)
        self.addToolBar(self.toolbar)

        self.btn_back = QPushButton("◀")
        self.btn_back.clicked.connect(self.navigate_back)
        self.toolbar.addWidget(self.btn_back)

        self.btn_up = QPushButton("▲")
        self.btn_up.clicked.connect(self.navigate_up)
        self.toolbar.addWidget(self.btn_up)

        self.path_input = QLineEdit()
        self.path_input.returnPressed.connect(self.navigate_to_path)
        self.toolbar.addWidget(self.path_input)

        self.btn_go = QPushButton("Go")
        self.btn_go.clicked.connect(self.navigate_to_path)
        self.toolbar.addWidget(self.btn_go)

        # 2. Main Body Splitter (Sidebar + Files Grid)
        self.splitter = QSplitter(Qt.Horizontal)
        self.main_layout.addWidget(self.splitter)

        # Sidebar tree navigation
        self.sidebar = QTreeWidget()
        self.sidebar.setHeaderHidden(True)
        self.sidebar.setIconSize(QSize(18, 18))
        self.sidebar.itemClicked.connect(self.sidebar_item_clicked)
        self.splitter.addWidget(self.sidebar)

        # Files list viewport
        self.files_list = QListWidget()
        self.files_list.setIconSize(QSize(36, 36))
        self.files_list.itemDoubleClicked.connect(self.file_item_double_clicked)
        self.splitter.addWidget(self.files_list)

        # Configure Splitter resizing layout ratios
        self.splitter.setStretchFactor(0, 1)
        self.splitter.setStretchFactor(1, 4)

        # Initialize folders list
        self.current_dir = QDir.homePath()
        self.path_history = []
        
        self.setup_sidebar()
        self.load_directory(self.current_dir)

    def setup_sidebar(self):
        root_node = QTreeWidgetItem(self.sidebar, ["Shortcuts"])
        root_node.setExpanded(True)

        home_node = QTreeWidgetItem(root_node, ["Home Directory"])
        home_node.setData(0, Qt.UserRole, QDir.homePath())
        home_node.setText(0, "🏠 Home")

        docs_node = QTreeWidgetItem(root_node, ["Documents"])
        docs_node.setData(0, Qt.UserRole, QDir.homePath() + "/Documents")
        docs_node.setText(0, "📄 Documents")

        dl_node = QTreeWidgetItem(root_node, ["Downloads"])
        dl_node.setData(0, Qt.UserRole, QDir.homePath() + "/Downloads")
        dl_node.setText(0, "📥 Downloads")

        root_sys = QTreeWidgetItem(self.sidebar, ["Filesystem"])
        root_sys.setExpanded(True)
        
        slash_node = QTreeWidgetItem(root_sys, ["Root (/)"])
        slash_node.setData(0, Qt.UserRole, "/")
        slash_node.setText(0, "📦 Root (/)")

    def load_directory(self, path):
        if not os.path.exists(path) or not os.path.isdir(path):
            return
        
        self.current_dir = path
        self.path_input.setText(path)
        self.files_list.clear()

        # Check for Git status integration details in background
        git_statuses = self.get_git_statuses(path)

        directory = QDir(path)
        entries = directory.entryInfoList(QDir.AllEntries | QDir.NoDotAndDotDot, QDir.DirsFirst | QDir.Name)

        for entry in entries:
            name = entry.fileName()
            full_path = entry.absoluteFilePath()
            is_dir = entry.isDir()

            item = QListWidgetItem(self.files_list)
            
            # Git status markers
            git_marker = ""
            if name in git_statuses:
                git_marker = f" [{git_statuses[name]}]"

            # Set Icons & decorations
            if is_dir:
                item.setText(f"📁  {name}{git_marker}")
                item.setForeground(Qt.white)
            else:
                item.setText(f"📄  {name}{git_marker}")
                if git_marker:
                    # Color git-decorated items
                    if "M" in git_marker:
                        item.setForeground(Qt.cyan)
                    elif "U" in git_marker:
                        item.setForeground(Qt.red)
                    else:
                        item.setForeground(Qt.yellow)
                else:
                    item.setForeground(Qt.lightGray)

            item.setData(Qt.UserRole, full_path)

    def get_git_statuses(self, path):
        # Scan if inside a git repository
        statuses = {}
        try:
            # Check if git is available and it's a repository
            if os.path.exists(os.path.join(path, ".git")) or self.is_inside_git_worktree(path):
                # Run git status --porcelain
                out = subprocess.check_output(
                    ["git", "status", "--porcelain"], 
                    cwd=path, 
                    stderr=subprocess.DEVNULL
                ).decode('utf-8')
                
                for line in out.split('\n'):
                    if not line.strip():
                        continue
                    # Format: XY filename
                    status_flag = line[:2].strip()
                    file_name = line[3:].strip()
                    # Keep basename for matching list
                    base = file_name.split('/')[0]
                    statuses[base] = status_flag
        except Exception:
            pass
        return statuses

    def is_inside_git_worktree(self, path):
        try:
            res = subprocess.run(
                ["git", "rev-parse", "--is-inside-work-tree"],
                cwd=path, stdout=subprocess.PIPE, stderr=subprocess.PIPE
            )
            return res.returncode == 0
        except Exception:
            return False

    def sidebar_item_clicked(self, item, column):
        target = item.data(0, Qt.UserRole)
        if target:
            self.path_history.append(self.current_dir)
            self.load_directory(target)

    def file_item_double_clicked(self, item):
        target = item.data(Qt.UserRole)
        if os.path.isdir(target):
            self.path_history.append(self.current_dir)
            self.load_directory(target)
        else:
            # Run application launcher open
            if sys.platform == "win32":
                os.startfile(target)
            else:
                subprocess.Popen(["xdg-open", target], stderr=subprocess.DEVNULL)

    def navigate_back(self):
        if self.path_history:
            prev = self.path_history.pop()
            self.load_directory(prev)

    def navigate_up(self):
        parent = os.path.dirname(self.current_dir)
        if parent and parent != self.current_dir:
            self.path_history.append(self.current_dir)
            self.load_directory(parent)

    def navigate_to_path(self):
        target = self.path_input.text()
        if os.path.exists(target) and os.path.isdir(target):
            self.path_history.append(self.current_dir)
            self.load_directory(target)

def main():
    app = QApplication(sys.argv)
    window = FileManager()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
