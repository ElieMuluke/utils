import os
from dotenv import load_dotenv
import sys
import asyncio
from PyQt5.QtWidgets import QApplication, QWidget, QVBoxLayout, QPushButton, QTextEdit, QFileDialog
from PyQt5.QtCore import QThread, pyqtSignal
from pyqtspinner.spinner import WaitingSpinner

load_dotenv()  # take environment variables from .env.

API_KEY = os.environ['API_KEY']
class VirusTotalWorker(QThread):
    result_ready = pyqtSignal(str)

    def __init__(self, file_path):
        super().__init__()
        self.file_path = file_path

    async def upload_and_scan(self):
        async with vt.Client(API_KEY) as client:
            with open(self.file_path, "rb") as f:
                analysis = await client.scan_file(f)
            await analysis.wait_for_completion()
            report = await client.get_object(f"/analyses/{analysis.id}")
            return report

    def run(self):
        loop = asyncio.new_event_loop()
        asyncio.set_event_loop(loop)
        report = loop.run_until_complete(self.upload_and_scan())
        loop.close()
        self.result_ready.emit(str(report))

class VirusTotalScanner(QWidget):
    def __init__(self):
        super().__init__()
        self.init_ui()

    def init_ui(self):
        layout = QVBoxLayout()

        self.upload_button = QPushButton('Upload File', self)
        self.upload_button.clicked.connect(self.upload_file)

        self.result_text = QTextEdit(self)
        self.result_text.setReadOnly(True)

        self.spinner = WaitingSpinner(self, True, True, Qt.ApplicationModal)
        self.spinner.setRoundness(70.0)
        self.spinner.setMinimumTrailOpacity(15.0)
        self.spinner.setTrailFadePercentage(70.0)
        self.spinner.setNumberOfLines(12)
        self.spinner.setLineLength(10)
        self.spinner.setLineWidth(5)
        self.spinner.setInnerRadius(10)
        self.spinner.setRevolutionsPerSecond(1)
        self.spinner.setColor(QColor(81, 4, 71))

        layout.addWidget(self.upload_button)
        layout.addWidget(self.result_text)

        self.setLayout(layout)
        self.setGeometry(300, 300, 400, 300)
        self.setWindowTitle('VirusTotal Scanner')

    def upload_file(self):
        file_dialog = QFileDialog()
        file_path, _ = file_dialog.getOpenFileName()

        if file_path:
            self.spinner.start()
            self.upload_button.setEnabled(False)
            self.worker = VirusTotalWorker(file_path)
            self.worker.result_ready.connect(self.display_result)
            self.worker.start()

    def display_result(self, result):
        self.spinner.stop()
        self.upload_button.setEnabled(True)
        self.result_text.setText(result)

if __name__ == '__main__':
    app = QApplication(sys.argv)
    window = VirusTotalScanner()
    window.show()
    sys.exit(app.exec_())
