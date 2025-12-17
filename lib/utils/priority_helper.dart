import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class PriorityHelper {
  static Color getBackgroundColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.priorityHighBg;
      case 'medium':
        return AppColors.priorityMediumBg;
      case 'low':
        return AppColors.priorityLowBg;
      default:
        return Colors.grey[200]!;
    }
  }

  static Color getTextColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.priorityHighText;
      case 'medium':
        return AppColors.priorityMediumText;
      case 'low':
        return AppColors.priorityLowText;
      default:
        return Colors.grey[700]!;
    }
  }
}
