import '../../../core/constants/categories.dart';

class ParsedReceiptDraft {
  final String merchant;
  final double totalAmount;
  final DateTime transactionDate;
  final ExpenseCategory suggestedCategory;
  final double confidenceScore;
  final String rawText;
  final String? imagePath;
  final List<String> extractedLines;

  ParsedReceiptDraft({
    required this.merchant,
    required this.totalAmount,
    required this.transactionDate,
    required this.suggestedCategory,
    required this.confidenceScore,
    required this.rawText,
    this.imagePath,
    required this.extractedLines,
  });

  ParsedReceiptDraft copyWith({
    String? merchant,
    double? totalAmount,
    DateTime? transactionDate,
    ExpenseCategory? suggestedCategory,
    double? confidenceScore,
    String? rawText,
    String? imagePath,
    List<String>? extractedLines,
  }) {
    return ParsedReceiptDraft(
      merchant: merchant ?? this.merchant,
      totalAmount: totalAmount ?? this.totalAmount,
      transactionDate: transactionDate ?? this.transactionDate,
      suggestedCategory: suggestedCategory ?? this.suggestedCategory,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      rawText: rawText ?? this.rawText,
      imagePath: imagePath ?? this.imagePath,
      extractedLines: extractedLines ?? this.extractedLines,
    );
  }
}
