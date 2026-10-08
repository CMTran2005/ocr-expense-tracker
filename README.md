# OCR Expense Tracker & Receipt Parser (Flutter & Dart)

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![ML Kit](https://img.shields.io/badge/Google_ML_Kit-Offline_OCR-4285F4?style=for-the-badge&logo=google&logoColor=white)](https://developers.google.com/ml-kit)
[![SQLite](https://img.shields.io/badge/SQLite-sqflite-003B57?style=for-the-badge&logo=sqlite&logoColor=white)](https://pub.dev/packages/sqflite)
[![CustomPainter](https://img.shields.io/badge/Canvas-CustomPainter-FF6F00?style=for-the-badge)](https://api.flutter.dev/flutter/rendering/CustomPainter-class.html)

**Mini-Project 3** for **Cross-Platform Mobile App Development** (VKU - Vietnam-Korea University of Information and Communication Technology).

---

## 📌 Tổng quan dự án

Ứng dụng quản lý tài chính và chi tiêu thông minh với trí tuệ nhân tạo **On-Device AI** (Google ML Kit Text Recognition) hoạt động **hoàn toàn offline**, không tốn chi phí Cloud API, thời gian trích xuất dưới 100ms. 

Ứng dụng giải quyết triệt để vấn đề nhập liệu thủ công tốn thời gian và dễ nhầm lẫn của sinh viên và thủ quỹ câu lạc bộ khi phải xử lý hàng tá hóa đơn thanh toán giấy (siêu thị, quán cafe, nhà sách, xăng xe,...).

---

## ✨ Tính năng cốt lõi (Core Specifications)

### 1. 📷 Camera Capture & Image Cropping
- **Live Viewfinder**: Kính ngắm máy ảnh trực tiếp bằng gói `camera`.
- **Flash Toggle**: Bật/tắt đèn pin (`FlashMode.torch` / `FlashMode.off`) để quét hóa đơn trong điều kiện thiếu sáng.
- **Tap to Focus**: Chạm vào bất kỳ điểm nào trên khung hình để lấy nét và điều chỉnh phơi sáng với hoạt họa vòng tròn focus.
- **Framing Crop Overlay**: Khung ngắm bán trong suốt có 4 góc bo sáng định hướng cự ly hóa đơn.
- **Gallery Fallback**: Cho phép chọn ảnh hóa đơn từ bộ sưu tập ảnh máy khi chạy trên thiết bị không có camera vật lý.

### 2. 🧠 On-Device Text Recognition & Heuristic Regex Engine
- **Offline ML Kit OCR**: Tích hợp `google_mlkit_text_recognition` nhận diện ký tự quang học offline với độ trễ <100ms.
- **Heuristic Regex Engine**:
  - **Tổng tiền**: Bắt từ khóa ưu tiên (`Tổng cộng`, `Thành tiền`, `Total`, `Thanh toán`,...) kết hợp regex số tiền chuẩn hóa định dạng dấu `.` và `,` (`150.000 đ`, `150,000 VND`). Fallback tìm giá trị tiền hợp lý lớn nhất.
  - **Ngày giao dịch**: Bắt định dạng `DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`.
  - **Tên người bán / Cửa hàng**: Lọc 1–3 dòng đầu của hóa đơn, loại bỏ từ khóa nhiễu (*Hóa đơn bán lẻ, Phiếu tính tiền, VAT, Welcome,...*).
  - **Tự động phân loại (Auto-Categorization)**: Dựa trên từ khóa mặt hàng và tên quán để gợi ý danh mục chuẩn xác (*Food, Study, Travel, Gear, Entertainment*).
- **Màn hình Review tương tác**: Cho phép người dùng kiểm tra thông tin, sửa đổi số tiền, thay đổi danh mục, ghi chú trước khi lưu vào cơ sở dữ liệu.

### 3. 💾 Local Database & Transaction Lifecycle
- **Cơ sở dữ liệu SQLite**: Sử dụng `sqflite` lưu trữ toàn bộ lịch sử chi tiêu bền vững.
- **Phân loại danh mục chuẩn**:
  - 🍔 **Food**: Ăn uống, cà phê, nhà hàng, siêu thị.
  - 📚 **Study**: Sách vở, tài liệu, in ấn, học phí.
  - 🚗 **Travel**: Đi lại, xăng xe, Grab, vé tàu xe.
  - 💻 **Gear**: Thiết bị điện tử, phụ kiện công nghệ.
  - 🎮 **Entertainment**: Giải trí, rạp chiếu phim, bi-a, game.
  - 🏷️ **Other**: Các khoản chi tiêu khác.
- **Receipt Thumbnail Caching**: Lưu ảnh hóa đơn vào thư mục tài liệu của ứng dụng (`path_provider`), lưu đường dẫn tham chiếu trong cơ sở dữ liệu.

### 4. 📊 Custom Canvas Visualizations with `CustomPainter`
> 🚫 **Nghiêm ngặt**: Tuyệt đối **không sử dụng** bất kỳ thư viện biểu đồ bên thứ 3 nào (`fl_chart`, `syncfusion_flutter_charts`,...).

- **Animated Category Donut Chart**:
  - Vẽ trực tiếp trên Canvas với `canvas.drawArc` và `PaintingStyle.stroke`.
  - Tính góc quét tỉ lệ: $Angle_i = 2\pi \times \frac{Amount_i}{Total}$.
  - Hoạt họa xoay quét mượt mà với `AnimationController` & `CurvedAnimation(curve: Curves.easeOutCubic)`.
  - Hiển thị tâm: Tổng số tiền chi tiêu và số danh mục.
  - Chú giải (Legend) màu sắc và tỉ lệ phần trăm tương ứng.
- **Animated Weekly Spending Bar Chart**:
  - Phân bổ chi tiêu 7 ngày trong tuần (T2 đến CN).
  - Vẽ cột bo góc bằng `canvas.drawRRect`.
  - Vẽ nhãn ngày và đường kẻ gióng bằng `TextPainter` và dashed lines.
  - Hoạt họa cột mọc từ đáy lên trên theo hệ số scale `animationProgress`.

---

## 🏗️ Kiến trúc ứng dụng (Architecture)

```
lib/
├── core/
│   ├── constants/             # Danh mục chi tiêu (ExpenseCategory enum)
│   ├── database/              # SQLite DatabaseHelper & CRUD operations
│   ├── theme/                 # Dark Theme & bảng màu Emerald
│   └── utils/                 # CurrencyFormatter (VND formatting, string parsing)
├── features/
│   ├── camera_scanner/        # Camera viewfinder, flash, tap-to-focus & crop overlay
│   ├── receipt_parser/        # Google ML Kit OCR service, Heuristic Regex engine & Review screen
│   ├── expense_tracker/       # Quản lý giao dịch, tìm kiếm, lọc danh mục, chi tiết hóa đơn
│   └── analytics_charts/      # CustomPainter Donut & Bar Charts (Animated Canvas)
└── main.dart                  # Điểm khởi chạy ứng dụng & Bottom navigation shell
```

---

## 🚀 Hướng dẫn cài đặt & Chạy ứng dụng

### 1. Yêu cầu môi trường
- Flutter SDK `>=3.16.0` (Dart `>=3.2.0`)
- Android SDK (minSdkVersion: `21`) hoặc thiết bị di động Android / iOS thực tế.

### 2. Cài đặt Dependencies
```bash
flutter pub get
```

### 3. Chạy kiểm thử tự động (Unit Tests)
```bash
flutter test test/heuristic_parser_test.dart
```

### 4. Khởi chạy trên thiết bị hoặc máy ảo
```bash
flutter run
```

---

## 📦 Gói nộp bài (Mandatory Submission Deliverables)

1. **Live Demo URL / Video**:
   - Link tải APK phát hành: `Releases` trên GitHub.
   - Video demo 2–3 phút thao tác quét hóa đơn thực tế và tương tác biểu đồ.
2. **GitHub Repository**:
   - URL: `https://github.com/CMTran2005/ocr-expense-tracker`
   - Lịch sử commit rõ ràng theo Conventional Commits.
3. **Báo cáo ngắn (Short Report PDF)**:
   - File tài liệu `REPORT_TEMPLATE.md` sẵn sàng xuất thành PDF (2–4 trang).
