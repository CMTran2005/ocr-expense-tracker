# VKU OCR Expense Tracker & Receipt Parser

A modern, offline personal finance management application with on-device AI for scanning receipts, automated heuristic expense parsing, and custom canvas-rendered animated charts at Vietnam-Korea University of Information and Communication Technology (VKU).

[![GitHub Repository](https://img.shields.io/badge/GitHub-Repository-181717?style=for-the-badge&logo=github)](https://github.com/CMTran2005/ocr-expense-tracker)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)](https://dart.dev)
[![Google ML Kit](https://img.shields.io/badge/Google_ML_Kit-Offline_OCR-4285F4?style=for-the-badge&logo=google)](https://developers.google.com/ml-kit)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?style=for-the-badge&logo=sqlite)](https://pub.dev/packages/sqflite)
[![Build APK](https://img.shields.io/github/actions/workflow/status/CMTran2005/ocr-expense-tracker/build-apk.yml?style=for-the-badge&logo=githubactions&label=Build%20APK)](https://github.com/CMTran2005/ocr-expense-tracker/actions)
[![Direct APK Download](https://img.shields.io/badge/Download_APK-Release_v1.0.0-10B981?style=for-the-badge&logo=android&logoColor=white)](https://github.com/CMTran2005/ocr-expense-tracker/releases)

📦 **Submission Package**: GitHub Repository | Live Demo (APK / Video) | Short Report (PDF)  
🎓 **Course**: Cross-Platform Mobile App Development — Mini-Project 3 (Weeks 7 - 8)

---

## Key Features

### 📷 Camera Capture & Viewfinder:
- **Live Viewfinder**: Real-time camera stream using the official `camera` plugin.
- **Flash & Tap-to-Focus**: Toggle torch mode for low-light scanning and tap anywhere to focus with an animated focal indicator.
- **Framing Crop Overlay**: Semi-transparent mask with highlighted corner anchors for accurate receipt framing.
- **Gallery Import Fallback**: Pick existing receipt photos directly from the device gallery for emulator testing.

### 🧠 On-Device AI & Heuristic Parser:
- **Offline ML Kit OCR**: Text extraction powered by `google_mlkit_text_recognition` running locally with zero cloud API costs and sub-100ms latency.
- **Regex Heuristic Engine**:
  - **Monetary Totals**: Extracts totals using proximity keywords (`Tổng cộng`, `Thành tiền`, `Total`, `Amount`) and handles Vietnamese currency delimiters (`150.000 đ`, `150,000 VND`).
  - **Transaction Dates**: Parses standard formats (`DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`).
  - **Merchant Name**: Filters top lines and ignores common noise phrases (*Hóa đơn bán lẻ, VAT, Welcome*).
  - **Auto-Categorization**: Intelligently classifies expenses into Food, Study, Travel, Gear, or Entertainment based on merchant and item keywords.
- **Interactive Review Screen**: Full verification form allowing manual corrections and notes before persistent saving.

### 💾 Expense Management & Local Storage:
- **Persistent SQLite Database**: Built with `sqflite` for fast and reliable local transaction lifecycle management.
- **Category Classification**: Dedicated categories (`Food`, `Study`, `Travel`, `Gear`, `Entertainment`, `Other`) with custom icons and color tokens.
- **Transaction History**: Real-time search by merchant name, filter chips by category, and swipe-to-delete with undo.
- **Receipt Thumbnail Caching**: Automatically saves compressed receipt images to the app storage directory (`path_provider`).

### 📊 Custom Canvas Visualizations (No 3rd-Party Charts):
- **Animated Donut / Pie Chart**:
  - Rendered entirely with Flutter's `CustomPainter` API (`canvas.drawArc`).
  - Smooth radial sweep animation powered by `AnimationController` and `CurvedAnimation`.
  - Center hub displaying total expenses and interactive category legends with percentages.
- **Animated Weekly Spending Bar Chart**:
  - 7-day spending distribution (Monday to Sunday) with rounded bar caps (`canvas.drawRRect`).
  - Day axis labels (T2 – CN) and dynamic height scaling.

---

## Technology Stack

| Component | Technology Used |
| :--- | :--- |
| **Framework** | Flutter 3.x (Material 3) |
| **Language** | Dart 3.x |
| **On-Device OCR** | Google ML Kit (`google_mlkit_text_recognition`) |
| **Camera & Media** | `camera`, `image_picker`, `image` |
| **Local Database** | SQLite (`sqflite`), `path_provider` |
| **Visualizations** | Native Canvas API (`CustomPainter` & `AnimationController`) |
| **Utilities** | `intl` (Vietnamese currency & date formatting) |

---

## Project Architecture

```
mini-project-3-ocr-expense-tracker/
├── lib/
│   ├── core/
│   │   ├── constants/             # ExpenseCategory enum, color & icon mappings
│   │   ├── database/              # SQLite DatabaseHelper, CRUD & demo seeder
│   │   ├── theme/                 # Dark & light theme tokens (Slate & Emerald)
│   │   └── utils/                 # CurrencyFormatter & Date utilities
│   ├── features/
│   │   ├── analytics_charts/      # Custom Canvas Visualizations
│   │   │   ├── painters/          # DonutChartPainter, BarChartPainter
│   │   │   ├── widgets/           # AnimatedDonutChart, AnimatedBarChart
│   │   │   └── presentation/      # DashboardScreen
│   │   ├── camera_scanner/        # Camera Viewfinder & Framing
│   │   │   ├── widgets/           # CameraCropOverlay (Canvas mask)
│   │   │   └── presentation/      # CameraScreen
│   │   ├── expense_tracker/       # Expense Lifecycle Management
│   │   │   ├── models/            # ExpenseItem model & serialization
│   │   │   └── presentation/      # ExpensesListScreen, ExpenseDetailSheet
│   │   └── receipt_parser/        # OCR & Heuristic Engine
│   │       ├── models/            # ParsedReceiptDraft DTO
│   │       ├── services/          # MlKitOcrService, HeuristicParserService
│   │       └── presentation/      # ReviewReceiptScreen
│   └── main.dart                  # Application entry point & Bottom Navigation Shell
├── test/
│   └── heuristic_parser_test.dart # Unit tests for regex heuristics
├── android/                       # Native Android configuration (minSdkVersion 21)
├── pubspec.yaml                   # Project dependencies and asset definitions
├── REPORT_TEMPLATE.md             # 2-4 page report template for submission
└── README.md
```

---

## Getting Started

### 1. Prerequisites
- Flutter SDK (v3.16 or higher)
- Dart SDK (v3.2 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator with camera/webcam support

### 2. Installation
```bash
# Clone repository
git clone https://github.com/CMTran2005/ocr-expense-tracker.git

# Navigate into project directory
cd ocr-expense-tracker

# Install dependencies
flutter pub get
```

### 3. Run Locally

#### Mobile Device / Emulator:
```bash
flutter run
```

#### Run Automated Unit Tests:
```bash
flutter test test/heuristic_parser_test.dart
```

---

## Production Build & Deliverables

### Build Release APK:
```bash
flutter build apk --release
```
*Outputs release APK file at `build/app/outputs/flutter-apk/app-release.apk` for GitHub Releases.*

### Submission Checklist:
1. **GitHub Repository**: [https://github.com/CMTran2005/ocr-expense-tracker](https://github.com/CMTran2005/ocr-expense-tracker)
2. **Live Demo / Video**: 2–3 minute walk-through showcasing OCR capture, review flow, and animated CustomPainter charts.
3. **Short Report (PDF)**: 2–4 page summary generated using `REPORT_TEMPLATE.md`.

---

## License

Distributed under the MIT License. Developed for VKU Cross-Platform Mobile Application Development.
