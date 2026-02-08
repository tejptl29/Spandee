import 'package:flutter/material.dart';

class CategoryUtils {
  static String getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return '🍔';
      case 'Travel':
        return '🚗';
      case 'Rent':
        return '🏠';
      case 'Shopping':
        return '🛍️';
      case 'Health':
        return '🏥';
      case 'Movies':
        return '🎬';
      case 'Education':
        return '🎓';
      case 'Bills':
        return '💡';
      case 'Gifts':
        return '🎁';
      case 'Snacks':
        return '🍕';
      case 'Other':
        return '📦';
      default:
        return '💰';
    }
  }

  static Color getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange.withAlpha(30);
      case 'Travel':
        return Colors.blue.withAlpha(30);
      case 'Rent':
        return Colors.purple.withAlpha(30);
      case 'Shopping':
        return Colors.pink.withAlpha(30);
      case 'Health':
        return Colors.red.withAlpha(30);
      case 'Movies':
        return Colors.indigo.withAlpha(30);
      case 'Education':
        return Colors.brown.withAlpha(30);
      case 'Bills':
        return Colors.amber.withAlpha(30);
      case 'Gifts':
        return Colors.cyan.withAlpha(30);
      case 'Snacks':
        return Colors.deepOrange.withAlpha(30);
      case 'Other':
        return Colors.grey.withAlpha(30);
      default:
        return Colors.teal.withAlpha(30);
    }
  }

  static Color getCategoryTextColor(String category, bool isDark) {
    if (isDark) {
      switch (category) {
        case 'Food':
          return Colors.orange.shade300;
        case 'Travel':
          return Colors.blue.shade300;
        case 'Rent':
          return Colors.purple.shade300;
        case 'Shopping':
          return Colors.pink.shade300;
        case 'Health':
          return Colors.red.shade300;
        case 'Movies':
          return Colors.indigo.shade300;
        case 'Education':
          return Colors.brown.shade300;
        case 'Bills':
          return Colors.amber.shade300;
        case 'Gifts':
          return Colors.cyan.shade300;
        case 'Snacks':
          return Colors.deepOrange.shade300;
        case 'Other':
          return Colors.grey.shade400;
        default:
          return Colors.teal.shade300;
      }
    }
    switch (category) {
      case 'Food':
        return Colors.orange.shade700;
      case 'Travel':
        return Colors.blue.shade700;
      case 'Rent':
        return Colors.purple.shade700;
      case 'Shopping':
        return Colors.pink.shade700;
      case 'Health':
        return Colors.red.shade700;
      case 'Movies':
        return Colors.indigo.shade700;
      case 'Education':
        return Colors.brown.shade700;
      case 'Bills':
        return Colors.amber.shade700;
      case 'Gifts':
        return Colors.cyan.shade700;
      case 'Snacks':
        return Colors.deepOrange.shade700;
      case 'Other':
        return Colors.grey.shade700;
      default:
        return Colors.teal.shade700;
    }
  }
}
