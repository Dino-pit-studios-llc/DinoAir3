import 'package:flutter/material.dart';

class ProjectStatusIndicatorWidget extends StatelessWidget {
  final String status;
  final bool compact;

  const ProjectStatusIndicatorWidget({
    required this.status,
    this.compact = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, label, color) = switch (status.toLowerCase()) {
      'active' => (Icons.play_circle_outline, 'Active', Colors.green),
      'completed' => (Icons.check_circle_outline, 'Completed', Colors.blue),
      'archived' => (Icons.archive_outlined, 'Archived', Colors.grey),
      _ => (Icons.help_outline, 'Unknown', Colors.orange),
    };

    if (compact) {
      return Tooltip(
        message: label,
        child: Icon(
          icon,
          size: 20,
          color: color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
  color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
