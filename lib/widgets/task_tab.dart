import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class TaskTab extends StatelessWidget {
  final String label;
  final int index;
  final int selectedIndex;
  final Function(int) onTap;
  final bool isMobile;

  const TaskTab({
    super.key,
    required this.label,
    required this.index,
    required this.selectedIndex,
    required this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: isMobile ? EdgeInsets.zero : const EdgeInsets.only(right: 8),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cardBackground : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 13 : 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
