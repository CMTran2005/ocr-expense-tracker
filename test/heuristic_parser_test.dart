import 'package:flutter_test/flutter_test.dart';
import 'package:ocr_expense_tracker/core/constants/categories.dart';
import 'package:ocr_expense_tracker/features/receipt_parser/services/heuristic_parser_service.dart';

void main() {
  group('HeuristicParserService Tests', () {
    late HeuristicParserService parser;

    setUp(() {
      parser = HeuristicParserService();
    });

    test('should correctly parse Vietnamese supermarket receipt', () {
      const sampleOcrText = '''
HÓA ĐƠN BÁN LẺ
WINMART+ TRẦN ĐẠI NGHĨA
Đ/C: 450 Trần Đại Nghĩa, Ngũ Hành Sơn, Đà Nẵng
Ngày bán: 08/10/2026 10:15
Thu ngân: NV01
1. Sữa tươi TH True Milk 1L     36.000
2. Bánh mì bơ tỏi               25.000
3. Xúc xích Đức                 54.000
--------------------------------------
Cộng tiền hàng:                115.000 đ
TỔNG CỘNG: 115.000 VND
CẢM ƠN QUÝ KHÁCH HẸN GẶP LẠI
      ''';

      final draft = parser.parse(sampleOcrText);

      expect(draft.merchant.contains('WINMART'), isTrue);
      expect(draft.totalAmount, equals(115000.0));
      expect(draft.transactionDate.day, equals(8));
      expect(draft.transactionDate.month, equals(10));
      expect(draft.transactionDate.year, equals(2026));
      expect(draft.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('should parse coffee receipt with comma separator', () {
      const sampleOcrText = '''
HIGHLANDS COFFEE FPT
Hóa đơn số: #98234
Ngày: 05/10/2026
1x Phin Sữa Đá Size L      49,000
1x Trà Sen Vàng            55,000
---------------------------------
Thành tiền:               104,000 đ
      ''';

      final draft = parser.parse(sampleOcrText);

      expect(draft.merchant.contains('HIGHLANDS'), isTrue);
      expect(draft.totalAmount, equals(104000.0));
      expect(draft.transactionDate.day, equals(5));
      expect(draft.transactionDate.month, equals(10));
      expect(draft.suggestedCategory, equals(ExpenseCategory.food));
    });

    test('should classify bookstore receipt to study category', () {
      const sampleOcrText = '''
NHÀ SÁCH FAHASA ĐÀ NẴNG
Ngày: 01/10/2026
Sách Lập Trình Flutter      180.000
Vở kẻ ngang 200 trang        25.000
-----------------------------------
TỔNG THANH TOÁN: 205.000 VND
      ''';

      final draft = parser.parse(sampleOcrText);

      expect(draft.merchant.contains('FAHASA'), isTrue);
      expect(draft.totalAmount, equals(205000.0));
      expect(draft.suggestedCategory, equals(ExpenseCategory.study));
    });
  });
}
