import '../../../core/constants/categories.dart';

class ExpenseItem {
  final int? id;
  final String merchant;
  final double amount;
  final ExpenseCategory category;
  final DateTime transactionDate;
  final String? receiptImagePath;
  final String? rawOcrText;
  final String? notes;
  final DateTime createdAt;

  ExpenseItem({
    this.id,
    required this.merchant,
    required this.amount,
    required this.category,
    required this.transactionDate,
    this.receiptImagePath,
    this.rawOcrText,
    this.notes,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'merchant': merchant,
      'amount': amount,
      'category': category.name,
      'transactionDate': transactionDate.millisecondsSinceEpoch,
      'receiptImagePath': receiptImagePath,
      'rawOcrText': rawOcrText,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory ExpenseItem.fromMap(Map<String, dynamic> map) {
    return ExpenseItem(
      id: map['id'] as int?,
      merchant: map['merchant'] as String? ?? 'Chưa rõ',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      category: ExpenseCategory.fromString(map['category'] as String?),
      transactionDate: DateTime.fromMillisecondsSinceEpoch(
        map['transactionDate'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
      receiptImagePath: map['receiptImagePath'] as String?,
      rawOcrText: map['rawOcrText'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  ExpenseItem copyWith({
    int? id,
    String? merchant,
    double? amount,
    ExpenseCategory? category,
    DateTime? transactionDate,
    String? receiptImagePath,
    String? rawOcrText,
    String? notes,
    DateTime? createdAt,
  }) {
    return ExpenseItem(
      id: id ?? this.id,
      merchant: merchant ?? this.merchant,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      transactionDate: transactionDate ?? this.transactionDate,
      receiptImagePath: receiptImagePath ?? this.receiptImagePath,
      rawOcrText: rawOcrText ?? this.rawOcrText,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
