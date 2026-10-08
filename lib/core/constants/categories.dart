import 'package:flutter/material.dart';

/// Predefined expense categories specified in Mini-Project 3
enum ExpenseCategory {
  food,
  study,
  travel,
  gear,
  entertainment,
  other;

  String get id => name;

  String get displayName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food (Ăn uống)';
      case ExpenseCategory.study:
        return 'Study (Học tập)';
      case ExpenseCategory.travel:
        return 'Travel (Đi lại / Du lịch)';
      case ExpenseCategory.gear:
        return 'Gear (Thiết bị / Đồ dùng)';
      case ExpenseCategory.entertainment:
        return 'Entertainment (Giải trí)';
      case ExpenseCategory.other:
        return 'Other (Khác)';
    }
  }

  String get shortName {
    switch (this) {
      case ExpenseCategory.food:
        return 'Food';
      case ExpenseCategory.study:
        return 'Study';
      case ExpenseCategory.travel:
        return 'Travel';
      case ExpenseCategory.gear:
        return 'Gear';
      case ExpenseCategory.entertainment:
        return 'Entertainment';
      case ExpenseCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ExpenseCategory.food:
        return Icons.restaurant_rounded;
      case ExpenseCategory.study:
        return Icons.menu_book_rounded;
      case ExpenseCategory.travel:
        return Icons.directions_car_rounded;
      case ExpenseCategory.gear:
        return Icons.laptop_mac_rounded;
      case ExpenseCategory.entertainment:
        return Icons.sports_esports_rounded;
      case ExpenseCategory.other:
        return Icons.category_rounded;
    }
  }

  Color get color {
    switch (this) {
      case ExpenseCategory.food:
        return const Color(0xFFF59E0B); // Amber
      case ExpenseCategory.study:
        return const Color(0xFF3B82F6); // Blue
      case ExpenseCategory.travel:
        return const Color(0xFF10B981); // Emerald
      case ExpenseCategory.gear:
        return const Color(0xFF8B5CF6); // Purple
      case ExpenseCategory.entertainment:
        return const Color(0xFFEC4899); // Pink
      case ExpenseCategory.other:
        return const Color(0xFF94A3B8); // Slate
    }
  }

  static ExpenseCategory fromString(String? value) {
    if (value == null) return ExpenseCategory.other;
    for (final cat in ExpenseCategory.values) {
      if (cat.name.toLowerCase() == value.toLowerCase() ||
          cat.shortName.toLowerCase() == value.toLowerCase()) {
        return cat;
      }
    }
    return ExpenseCategory.other;
  }
}
