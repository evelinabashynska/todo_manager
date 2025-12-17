import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/task_model.dart';
import '../utils/priority_helper.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final bool isMobile;
  final Function(bool) onCheckboxChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback? onTap;

  const TaskCard({
    super.key,
    required this.task,
    this.isMobile = false,
    required this.onCheckboxChanged,
    required this.onDelete,
    required this.onEdit,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        padding: EdgeInsets.all(isMobile ? 16 : 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        Row(
          children: [
            Checkbox(
              value: task.isCompleted,
              onChanged: (value) => onCheckboxChanged(value ?? false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: task.isCompleted
                          ? Colors.grey[400]
                          : AppColors.textPrimary,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    task.date,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: PriorityHelper.getBackgroundColor(task.priority),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                task.priorityLabel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: PriorityHelper.getTextColor(task.priority),
                ),
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: onEdit,
                  color: AppColors.textPrimary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: onDelete,
                  color: Colors.red[400],
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Checkbox(
          value: task.isCompleted,
          onChanged: (value) => onCheckboxChanged(value ?? false),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          activeColor: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: task.isCompleted
                      ? Colors.grey[400]
                      : AppColors.textPrimary,
                  decoration: task.isCompleted
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                task.date,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: PriorityHelper.getBackgroundColor(task.priority),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            task.priorityLabel,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PriorityHelper.getTextColor(task.priority),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: onEdit,
          color: AppColors.textPrimary,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: onDelete,
          color: Colors.red[400],
        ),
      ],
    );
  }
}
