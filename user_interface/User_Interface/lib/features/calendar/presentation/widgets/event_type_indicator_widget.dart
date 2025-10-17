import 'package:flutter/material.dart';

class EventTypeIndicatorWidget extends StatelessWidget {
  const EventTypeIndicatorWidget({
    required this.eventType,
    this.size = 32,
    super.key,
  });

  final String eventType;
  final double size;

  @override
  Widget build(BuildContext context) {
    final config = _getTypeConfig();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(
        config.icon,
        color: config.color,
        size: size * 0.6,
      ),
    );
  }

  _TypeConfig _getTypeConfig() {
    switch (eventType.toLowerCase()) {
      case 'meeting':
        return _TypeConfig(
          icon: Icons.people,
          color: Colors.blue,
        );
      case 'task':
        return _TypeConfig(
          icon: Icons.check_box,
          color: Colors.green,
        );
      case 'reminder':
        return _TypeConfig(
          icon: Icons.notifications,
          color: Colors.orange,
        );
      case 'event':
      default:
        return _TypeConfig(
          icon: Icons.event_note,
          color: Colors.purple,
        );
    }
  }
}

class _TypeConfig {
  const _TypeConfig({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;
}
