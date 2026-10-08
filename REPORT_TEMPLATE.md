# BÁO CÁO MINI-PROJECT 3: OCR EXPENSE TRACKER & RECEIPT PARSER
**Học phần**: Phát triển ứng dụng di động đa nền tảng (Cross-Platform Mobile App Development)  
**Trường**: Trường Đại học Công nghệ Thông tin và Truyền thông Việt - Hàn (VKU)  
**Sinh viên thực hiện**: [Họ và tên sinh viên] - [Mã sinh viên]  
**Repository GitHub**: https://github.com/CMTran2005/ocr-expense-tracker  
**Video Demo (2–3 phút)**: [Link YouTube / Google Drive]  

---

## 1. Feature Checklist (Bảng kiểm tra tính năng)

| STT | Yêu cầu kỹ thuật | Trạng thái | Mô tả chi tiết thực hiện |
| :---: | :--- | :---: | :--- |
| **1** | **Live Camera Viewfinder** | ✅ Hoàn thành | Tích hợp gói `camera`, hiển thị viewfinder mượt mà, hỗ trợ xoay chiều. |
| **2** | **Flash Toggle & Focus Tap** | ✅ Hoàn thành | Bật/tắt đèn Flash (`torch/off`), chạm bất kỳ điểm nào trên màn hình để lấy nét (`setFocusPoint`) kèm hiệu ứng vòng tròn. |
| **3** | **Framing Crop Overlay** | ✅ Hoàn thành | Khung ngắm bán trong suốt vẽ bằng `CustomPainter` với 4 góc bo sáng định hướng hóa đơn. |
| **4** | **Google ML Kit Text Recognition** | ✅ Hoàn thành | Nhận diện offline 100% bằng `google_mlkit_text_recognition`, độ trễ <100ms, không phụ thuộc kết nối mạng. |
| **5** | **Regex Heuristic Parser (Số tiền)** | ✅ Hoàn thành | Bắt từ khóa (`Tổng cộng`, `Thành tiền`, `Total`,...) và regex chuẩn hóa phân cách hàng nghìn `.` và `,`. |
| **6** | **Regex Heuristic Parser (Ngày tháng)**| ✅ Hoàn thành | Trích xuất định dạng ngày `DD/MM/YYYY`, `DD-MM-YYYY`, `YYYY-MM-DD`. |
| **7** | **Regex Heuristic Parser (Merchant)** | ✅ Hoàn thành | Lấy 1–3 dòng đầu hóa đơn và lọc bỏ từ khóa nhiễu (*Hóa đơn, Bill, VAT, Welcome*). |
| **8** | **Interactive Review Screen** | ✅ Hoàn thành | Màn hình xác nhận: sửa thông tin, đổi danh mục, xem văn bản OCR thô, lưu dữ liệu. |
| **9** | **Local Database (SQLite)** | ✅ Hoàn thành | Sử dụng `sqflite`, quản lý vòng đời CRUD, phân loại 5 danh mục bắt buộc + Other. |
| **10**| **Receipt Thumbnail Caching** | ✅ Hoàn thành | Lưu file ảnh hóa đơn vào local app documents (`path_provider`), lưu link vào DB. |
| **11**| **Animated Donut Chart (Canvas)** | ✅ Hoàn thành | Tự vẽ bằng `CustomPainter` (không dùng thư viện 3rd party), hoạt họa quét góc xoay, hiển thị tỉ lệ %. |
| **12**| **Weekly Spending Bar Chart (Canvas)**| ✅ Hoàn thành | Tự vẽ biểu đồ cột 7 ngày trong tuần với nhãn T2–CN, hoạt họa cột mọc từ đáy. |

---

## 2. Kiến trúc hệ thống & Thuật toán Regex Heuristics

### Sơ đồ kiến trúc ứng dụng (Layered Modular Architecture)
```
Presentation Layer (UI Screens & CustomPainters)
       │
       ▼
Controllers & ViewModels (Camera & State Coordination)
       │
       ├─────────────────────────────────┐
       ▼                                 ▼
Heuristic Parser & ML Kit OCR     Database Helper (SQLite)
(Text Processing & Regex Rules)    (Local Storage & Aggregation)
```

### Thuật toán trích xuất dữ liệu Heuristic
1. **Trích xuất số tiền tổng cộng**:
   - Quét ngược từ cuối hóa đơn lên để tìm các dòng có chứa từ khóa: `tổng cộng`, `thành tiền`, `tổng thanh toán`, `total`, `amount due`.
   - Sử dụng Regex bắt số tiền: `([0-9]{1,3}(?:[.,\s][0-9]{3})+|[0-9]{4,8})\s*(?:VND|VNĐ|đ|d|₫)?`.
   - Nếu không khớp từ khóa, thuật toán kích hoạt Fallback: tìm số lớn nhất trong phạm vi giá trị thực tế của một hóa đơn tiêu dùng (1.000đ – 100.000.000đ), loại trừ năm (2024, 2025, 2026), mã số thuế và số điện thoại.
2. **Trích xuất tên cửa hàng / Merchant**:
   - Kiểm tra 5 dòng đầu tiên của hóa đơn.
   - Loại trừ danh sách từ khóa rác (Blacklist): `Hóa đơn bán lẻ`, `Phiếu tính tiền`, `VAT`, `Invoice`, `Địa chỉ`, `MST`, `Hotline`, `Welcome`.
   - Dòng hợp lệ đầu tiên có độ dài $\ge 3$ ký tự được chọn làm tên quán.

---

## 3. Thuật toán vẽ biểu đồ với Flutter CustomPainter

> **Quy định**: Ứng dụng không sử dụng bất kỳ thư viện vẽ biểu đồ bên ngoài nào (No `fl_chart`, No `syncfusion`).

### A. Donut Chart (Phân bổ theo danh mục)
- **Công thức góc quét (Sweep Angle)**:
  $$\text{Proportion}_i = \frac{\text{Amount}_i}{\text{TotalSpending}}, \quad \text{SweepAngle}_i = 2\pi \times \text{Proportion}_i \times \text{animationProgress}$$
- **Kỹ thuật vẽ**:
  - Dùng `canvas.drawArc(rect, startAngle, actualSweep, false, paint)` với `Paint.style = PaintingStyle.stroke` và `strokeWidth = 26.0`.
  - Giữa các lát cắt thêm khoảng trống nhỏ `gapAngle = 0.04` radian để tạo thẩm mỹ hiện đại.
  - Vòng tròn hoạt họa xoay mềm mại nhờ `CurvedAnimation(curve: Curves.easeOutCubic)`.

### B. Weekly Spending Bar Chart (Chi tiêu 7 ngày trong tuần)
- **Công thức chuẩn hóa chiều cao cột**:
  $$\text{Height}_i = \frac{\text{Amount}_i}{\text{MaxWeeklyAmount}} \times \text{ChartHeight} \times \text{animationProgress}$$
- **Kỹ thuật vẽ**:
  - Dùng `canvas.drawRRect` để bo tròn 2 góc đỉnh cột (`Radius.circular(6)`).
  - Sử dụng `TextPainter` để căn giữa và vẽ nhãn ngày (T2, T3, T4, T5, T6, T7, CN).
  - Vẽ đường gióng đứt nét (Dashed line) ở mốc 50% bằng cách lặp bước nhảy đoạn thẳng.

---

## 4. Hình ảnh minh chứng kết quả (Screenshots)

*(Chèn ảnh chụp màn hình ứng dụng thực tế theo 4 bước dưới đây)*

1. **Dashboard & Biểu đồ CustomPainter**:
   - [Screenshot 1: Màn hình Dashboard với Donut Chart và Bar Chart sinh động]
2. **Camera Viewfinder & Lấy nét**:
   - [Screenshot 2: Kính ngắm camera với khung crop bán trong suốt và nút bật flash]
3. **Màn hình Review OCR**:
   - [Screenshot 3: Màn hình xác nhận hiển thị kết quả trích xuất tự động]
4. **Danh sách giao dịch & Chi tiết hóa đơn**:
   - [Screenshot 4: Danh sách giao dịch có lọc danh mục và popup xem ảnh hóa đơn]
