import '../../../core/constants/categories.dart';
import '../../../core/utils/currency_formatter.dart';
import '../models/parsed_receipt_draft.dart';

class HeuristicParserService {
  /// Keywords used to locate the total monetary amount line
  static final List<String> _totalKeywords = [
    'tổng cộng',
    'tong cong',
    'thành tiền',
    'thanh tien',
    'tổng thanh toán',
    'tong thanh toan',
    'thanh toán',
    'thanh toan',
    'cộng tiền hàng',
    'cong tien hang',
    'phải trả',
    'phai tra',
    'tiền mặt',
    'tien mat',
    'total amount',
    'grand total',
    'total',
    'amount due',
    'net total',
  ];

  /// Keywords identifying noise lines that should NOT be considered merchant names
  static final List<String> _merchantBlacklist = [
    'hóa đơn',
    'hoa don',
    'phiếu tính tiền',
    'phieu tinh tien',
    'phiếu thanh toán',
    'phieu thanh toan',
    'receipt',
    'bill',
    'invoice',
    'vat',
    'cộng hòa xã hội',
    'độc lập tự do',
    'mã số thuế',
    'mst',
    'tel',
    'sđt',
    'hotline',
    'địa chỉ',
    'dia chi',
    'welcome',
    'xin chào',
    'cảm ơn',
    'cam on',
    'thank you',
    'thu ngân',
    'khách hàng',
    'bàn số',
    'ngày in',
  ];

  /// Parses raw text extracted by ML Kit into a structured draft
  ParsedReceiptDraft parse(String rawText, {String? imagePath}) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    double totalAmount = _extractTotalAmount(lines, rawText);
    DateTime transactionDate = _extractDate(lines, rawText);
    String merchant = _extractMerchant(lines);
    ExpenseCategory category = _classifyCategory(rawText, merchant);

    double confidence = 0.5;
    if (totalAmount > 0) confidence += 0.25;
    if (merchant.isNotEmpty && merchant != 'Cửa hàng không tên') confidence += 0.15;
    if (category != ExpenseCategory.other) confidence += 0.1;

    return ParsedReceiptDraft(
      merchant: merchant,
      totalAmount: totalAmount,
      transactionDate: transactionDate,
      suggestedCategory: category,
      confidenceScore: confidence.clamp(0.0, 1.0),
      rawText: rawText,
      imagePath: imagePath,
      extractedLines: lines,
    );
  }

  /// Extracts the monetary total amount using heuristic keyword-proximity & regex
  double _extractTotalAmount(List<String> lines, String fullText) {
    // Phase 1: Search in lines containing priority total keywords
    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      for (final keyword in _totalKeywords) {
        if (lineLower.contains(keyword)) {
          // Look for amount in the same line
          final amount = _findFirstAmountInText(line);
          if (amount > 0) return amount;

          // If not in the same line, look in the immediately following line (common in OCR)
          if (i + 1 < lines.length) {
            final nextAmount = _findFirstAmountInText(lines[i + 1]);
            if (nextAmount > 0) return nextAmount;
          }
        }
      }
    }

    // Phase 2: If keyword search fails, look for amount pattern near currency symbols
    final currencyPattern = RegExp(
      r'([0-9]{1,3}(?:[.,\s][0-9]{3})+|[0-9]{4,8})\s*(?:VND|VNĐ|đ|d|₫)',
      caseSensitive: false,
    );
    final match = currencyPattern.firstMatch(fullText);
    if (match != null) {
      final parsed = CurrencyFormatter.parseAmount(match.group(1) ?? '');
      if (parsed > 0) return parsed;
    }

    // Phase 3: Fallback heuristic - find the maximum reasonable monetary number
    double maxCandidate = 0.0;
    final genericNumPattern = RegExp(r'\b[0-9]{1,3}(?:[.,][0-9]{3})+\b');
    for (final m in genericNumPattern.allMatches(fullText)) {
      final val = CurrencyFormatter.parseAmount(m.group(0) ?? '');
      // Filter out reasonable invoice numbers / phone numbers
      if (val >= 1000 && val <= 100000000) {
        if (val > maxCandidate) {
          maxCandidate = val;
        }
      }
    }

    return maxCandidate;
  }

  double _findFirstAmountInText(String text) {
    // Regex matching amounts like: 150,000 | 150.000 | 150 000 | 150000
    final pattern = RegExp(
      r'([0-9]{1,3}(?:[.,\s][0-9]{3})+|[0-9]{4,8})',
    );
    final matches = pattern.allMatches(text);
    for (final m in matches) {
      final candidateStr = m.group(1);
      if (candidateStr != null) {
        final amount = CurrencyFormatter.parseAmount(candidateStr);
        // Exclude year 2024, 2025, 2026 or small quantities
        if (amount > 500 && amount != 2024 && amount != 2025 && amount != 2026) {
          return amount;
        }
      }
    }
    return 0.0;
  }

  /// Extracts transaction date matching DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD
  DateTime _extractDate(List<String> lines, String fullText) {
    // Regex matching DD/MM/YYYY, DD-MM-YYYY, DD.MM.YYYY, YYYY-MM-DD, DD/MM/YY
    final datePattern = RegExp(
      r'\b([0-3]?[0-9])[/\-\.]([0-1]?[0-9])[/\-\.]([1-2][0-9]{3}|[0-9]{2})\b',
    );

    // Look for lines that also mention 'ngày', 'date', 'time' first
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (lower.contains('ngày') || lower.contains('date') || lower.contains('time') || lower.contains('ngay')) {
        final match = datePattern.firstMatch(line);
        if (match != null) {
          final dt = _parseDateMatch(match);
          if (dt != null) return dt;
        }
      }
    }

    // Scan whole text
    final match = datePattern.firstMatch(fullText);
    if (match != null) {
      final dt = _parseDateMatch(match);
      if (dt != null) return dt;
    }

    return DateTime.now();
  }

  DateTime? _parseDateMatch(RegExpMatch match) {
    try {
      int day = int.parse(match.group(1)!);
      int month = int.parse(match.group(2)!);
      int year = int.parse(match.group(3)!);

      if (year < 100) year += 2000;
      if (month > 12 && day <= 12) {
        // Swap if MM/DD format
        final temp = day;
        day = month;
        month = temp;
      }

      if (day >= 1 && day <= 31 && month >= 1 && month <= 12 && year >= 2020 && year <= 2030) {
        return DateTime(year, month, day);
      }
    } catch (_) {}
    return null;
  }

  /// Extracts Merchant/Store Name from top header lines
  String _extractMerchant(List<String> lines) {
    // Examine top 5 lines of the receipt
    final maxCheck = lines.length < 5 ? lines.length : 5;

    for (int i = 0; i < maxCheck; i++) {
      final line = lines[i];
      final lineLower = line.toLowerCase();

      // Check if line contains any blacklisted noise word
      bool isNoise = false;
      for (final noise in _merchantBlacklist) {
        if (lineLower.contains(noise)) {
          isNoise = true;
          break;
        }
      }

      // Ignore pure numbers or very short strings (< 3 chars)
      if (!isNoise && line.length >= 3 && !RegExp(r'^[0-9\s\.\,\:\-\/]+$').hasMatch(line)) {
        return line.replaceAll(RegExp(r'[\*#_]'), '').trim();
      }
    }

    return 'Cửa hàng không tên';
  }

  /// Heuristically auto-classifies category based on merchant & item keywords
  ExpenseCategory _classifyCategory(String fullText, String merchant) {
    final text = '$merchant $fullText'.toLowerCase();

    // Food
    if (text.contains('cà phê') ||
        text.contains('coffee') ||
        text.contains('trà') ||
        text.contains('tea') ||
        text.contains('phở') ||
        text.contains('cơm') ||
        text.contains('bánh') ||
        text.contains('bún') ||
        text.contains('winmart') ||
        text.contains('circle k') ||
        text.contains('co.op') ||
        text.contains('siêu thị') ||
        text.contains('nhà hàng') ||
        text.contains('quán ăn') ||
        text.contains('highlands') ||
        text.contains('phúc long') ||
        text.contains('lotteria') ||
        text.contains('kfc')) {
      return ExpenseCategory.food;
    }

    // Study
    if (text.contains('sách') ||
        text.contains('vở') ||
        text.contains('bút') ||
        text.contains('fahasa') ||
        text.contains('nhà sách') ||
        text.contains('photo') ||
        text.contains('in ấn') ||
        text.contains('học phí') ||
        text.contains('tài liệu') ||
        text.contains('văn phòng phẩm')) {
      return ExpenseCategory.study;
    }

    // Travel
    if (text.contains('xăng') ||
        text.contains('petrolimex') ||
        text.contains('grab') ||
        text.contains('be') ||
        text.contains('gojek') ||
        text.contains('vé xe') ||
        text.contains('vé máy bay') ||
        text.contains('bãi xe') ||
        text.contains('gửi xe') ||
        text.contains('taxi')) {
      return ExpenseCategory.travel;
    }

    // Gear
    if (text.contains('ugreen') ||
        text.contains('chuột') ||
        text.contains('bàn phím') ||
        text.contains('tai nghe') ||
        text.contains('fpt shop') ||
        text.contains('thế giới di động') ||
        text.contains('tgdd') ||
        text.contains('cellphones') ||
        text.contains('dây sạc') ||
        text.contains('pin dự phòng') ||
        text.contains('laptop') ||
        text.contains('linh kiện')) {
      return ExpenseCategory.gear;
    }

    // Entertainment
    if (text.contains('cgv') ||
        text.contains('lotte cinema') ||
        text.contains('cinema') ||
        text.contains('rạp') ||
        text.contains('billiards') ||
        text.contains('bi-a') ||
        text.contains('game') ||
        text.contains('karaoke') ||
        text.contains('vé tham quan') ||
        text.contains('netflix') ||
        text.contains('spotify')) {
      return ExpenseCategory.entertainment;
    }

    return ExpenseCategory.other;
  }
}
