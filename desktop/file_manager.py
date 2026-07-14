import sys
import os
import subprocess
from PySide6.QtWidgets import (QApplication, QMainWindow, QWidget, QVBoxLayout, 
                             QHBoxLayout, QListWidget, QListWidgetItem, QTreeWidget, 
                             QTreeWidgetItem, QTabWidget, QToolBar, QLineEdit, 
                             QPushButton, QLabel, QSplitter, QStyle, QFrame)
from PySide6.QtCore import Qt, QSize, QDir

class SplitFilePane(QWidget):
    def __init__(self, parent_manager, initial_path):
        super().__init__()
        self.manager = parent_manager
        self.layout = QHBoxLayout(self)
        self.layout.setContentsMargins(0, 0, 0, 0)
        self.layout.setSpacing(0)

        # Dual Pane Splitter
        self.pane_splitter = QSplitter(Qt.Horizontal)
        self.layout.addWidget(self.pane_splitter)

        # Left List View Pane
        self.left_list = QListWidget()
        self.left_list.setIconSize(QSize(32, 32))
        self.left_list.itemDoubleClicked.connect(self.item_double_clicked)
        self.left_list.itemClicked.connect(lambda item: self.item_clicked(item, "left"))
        self.pane_splitter.addWidget(self.left_list)

        # Right List View Pane (Step 5.1 - Dual-pane split directory layout)
        self.right_list = QListWidget()
        self.right_list.setIconSize(QSize(32, 32))
        self.right_list.itemDoubleClicked.connect(self.item_double_clicked)
        self.right_list.itemClicked.connect(lambda item: self.item_clicked(item, "right"))
        self.pane_splitter.addWidget(self.right_list)

        # Track active focus pane and paths
        self.active_pane = "left"
        self.left_path = initial_path
        self.right_path = initial_path

        # Initial loading
        self.load_pane("left", self.left_path)
        self.load_pane("right", self.right_path)

    def load_pane(self, pane, path):
        if not os.path.exists(path) or not os.path.isdir(path):
            return
        
        list_widget = self.left_list if pane == "left" else self.right_list
        if pane == "left":
            self.left_path = path
        else:
            self.right_path = path

        list_widget.clear()

        # Fetch git status markers
        git_statuses = self.manager.get_git_statuses(path)

        directory = QDir(path)
        entries = directory.entryInfoList(QDir.AllEntries | QDir.NoDotAndDotDot, QDir.DirsFirst | QDir.Name)

        for entry in entries:
            name = entry.fileName()
            full_path = entry.absoluteFilePath()
            is_dir = entry.isDir()

            item = QListWidgetItem(list_widget)
            git_marker = f" [{git_statuses[name]}]" if name in git_statuses else ""

            if is_dir:
                item.setText(f"📁  {name}{git_marker}")
                item.setForeground(Qt.white)
            else:
                item.setText(f"📄  {name}{git_marker}")
                if git_marker:
                    if "M" in git_marker:
                        item.setForeground(Qt.cyan)
                    elif "U" in git_marker:
                        item.setForeground(Qt.red)
                    else:
                        item.setForeground(Qt.yellow)
                else:
                    item.setForeground(Qt.lightGray)

            item.setData(Qt.UserRole, full_path)

    def item_clicked(self, item, pane):
        self.active_pane = pane
        path = self.left_path if pane == "left" else self.right_path
        self.manager.path_input.setText(path)

    def item_double_clicked(self, item):
        target = item.data(Qt.UserRole)
        if os.path.isdir(target):
            self.load_pane(self.active_pane, target)
            self.manager.path_input.setText(target)
        else:
            if sys.platform == "win32":
                os.startfile(target)
            else:
                subprocess.Popen(["xdg-open", target], stderr=subprocess.DEVNULL)

    def get_current_path(self):
        return self.left_path if self.active_pane == "left" else self.right_path


class FileManager(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Agneax Files")
        self.resize(920, 600)
        
        # Design system styles
        self.setStyleSheet("""
            QMainWindow { background-color: #0F1219; }
            QWidget { color: #FFFFFF; font-family: 'Segoe UI', Inter; font-size: 12px; }
            QToolBar { background-color: #0B0D13; border-bottom: 1px solid rgba(255,255,255,0.08); spacing: 8; padding: 6px; }
            QLineEdit { background-color: rgba(255,255,255,0.08); border: 1px solid rgba(255,255,255,0.1); border-radius: 6px; padding: 4px 10px; color: #FFFFFF; }
            QTreeWidget { background-color: #0B0D13; border: none; border-right: 1px solid rgba(255,255,255,0.08); }
            QTreeWidget::item { padding: 6px; }
            QTreeWidget::item:hover { background-color: rgba(255,255,255,0.04); }
            QTreeWidget::item:selected { background-color: rgba(0,242,254,0.15); color: #00F2FE; }
            QTabWidget::pane { border: none; }
            QTabBar::tab { background-color: #0B0D13; color: #A0AEC0; padding: 6px 14px; border-right: 1px solid rgba(255,255,255,0.05); }
            QTabBar::tab:selected { background-color: #141821; color: #FFFFFF; border-bottom: 2px solid #00F2FE; }
            QListWidget { background-color: #141821; border: none; padding: 10px; }
            QListWidget::item { background-color: rgba(255,255,255,0.02); border: 1px solid rgba(255,255,255,0.04); border-radius: 8px; padding: 8px; margin-bottom: 4px; }
            QListWidget::item:hover { background-color: rgba(255,255,255,0.06); }
            QListWidget::item:selected { background-color: rgba(0,242,254,0.15); border-color: #00F2FE; color: #00F2FE; }
            QPushButton { background-color: rgba(255,255,255,0.05); border: 1px solid rgba(255,255,255,0.1); border-radius: 6px; padding: 4px 12px; }
            QPushButton:hover { background-color: rgba(255,255,255,0.1); }
        """)

        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.main_layout = QVBoxLayout(self.central_widget)
        self.main_layout.setContentsMargins(0, 0, 0, 0)
        self.main_layout.setSpacing(0)

        # Toolbar
        self.toolbar = QToolBar()
        self.toolbar.setMovable(False)
        self.addToolBar(self.toolbar)

        self.btn_up = QPushButton("▲")
        self.btn_up.clicked.connect(self.navigate_up)
        self.toolbar.addWidget(self.btn_up)

        self.path_input = QLineEdit()
        self.path_input.returnPressed.connect(self.navigate_to_path)
        self.toolbar.addWidget(self.path_input)

        # Tab creation action (Step 5.1)
        self.btn_new_tab = QPushButton("+ New Tab")
        self.btn_new_tab.clicked.connect(lambda: self.add_new_tab(QDir.homePath()))
        self.toolbar.addWidget(self.btn_new_tab)

        # Sidebar + Tabs splitter
        self.splitter = QSplitter(Qt.Horizontal)
        self.main_layout.addWidget(self.splitter)

        # Sidebar
        self.sidebar = QTreeWidget()
        self.sidebar.setHeaderHidden(True)
        self.sidebar.setIconSize(QSize(18, 18))
        self.sidebar.itemClicked.connect(self.sidebar_item_clicked)
        self.splitter.addWidget(self.sidebar)

        # Tab Widget container (Step 5.1 - Multi-tab layout)
        self.tab_widget = QTabWidget()
        self.tab_widget.setTabsClosable(True)
        self.tab_widget.tabCloseRequested.connect(self.close_tab)
        self.tab_widget.currentChanged.connect(self.tab_changed)
        self.splitter.addWidget(self.tab_widget)

        self.splitter.setStretchFactor(0, 1)
        self.splitter.setStretchFactor(1, 4)

        self.setup_sidebar()
        self.add_new_tab(QDir.homePath())

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

    def add_new_tab(self, path):
        pane = SplitFilePane(self, path)
        title = os.path.basename(path) if path != "/" else "Root"
        idx = self.tab_widget.addTab(pane, title)
        self.tab_widget.setCurrentIndex(idx)
        self.path_input.setText(path)

    def close_tab(self, index):
        if self.tab_widget.count() > 1:
            widget = self.tab_widget.widget(index)
            widget.deleteLater()
            self.tab_widget.removeTab(index)

    def tab_changed(self, index):
        pane = self.tab_widget.widget(index)
        if pane:
            self.path_input.setText(pane.get_current_path())

    def navigate_up(self):
        pane = self.tab_widget.currentWidget()
        if pane:
            current = pane.get_current_path()
            parent = os.path.dirname(current)
            if parent and parent != current:
                pane.load_pane(pane.active_pane, parent)
                self.path_input.setText(parent)
                # Update tab text
                self.tab_widget.setTabText(self.tab_widget.currentIndex(), os.path.basename(parent) or "Root")

    def navigate_to_path(self):
        pane = self.tab_widget.currentWidget()
        target = self.path_input.text()
        if pane and os.path.exists(target) and os.path.isdir(target):
            pane.load_pane(pane.active_pane, target)
            self.tab_widget.setTabText(self.tab_widget.currentIndex(), os.path.basename(target) or "Root")

    def sidebar_item_clicked(self, item, column):
        target = item.data(0, Qt.UserRole)
        pane = self.tab_widget.currentWidget()
        if target and pane:
            pane.load_pane(pane.active_pane, target)
            self.path_input.setText(target)
            self.tab_widget.setTabText(self.tab_widget.currentIndex(), item.text(0).split()[-1])

    def get_git_statuses(self, path):
        statuses = {}
        try:
            if os.path.exists(os.path.join(path, ".git")) or self.is_inside_git_worktree(path):
                out = subprocess.check_output(
                    ["git", "status", "--porcelain"], 
                    cwd=path, 
                    stderr=subprocess.DEVNULL
                ).decode('utf-8')
                
                for line in out.split('\n'):
                    if not line.strip():
                        continue
                    status_flag = line[:2].strip()
                    file_name = line[3:].strip()
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

def main():
    app = QApplication(sys.argv)
    window = FileManager()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
