import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String statusName;
  final String? statusColorStr;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.statusName,
    this.statusColorStr,
    this.fontSize = 12,
  });

  Color get _color {
    if (statusColorStr != null && statusColorStr!.startsWith('0x')) {
      try {
        return Color(int.parse(statusColorStr!));
      } catch (e) {
        return const Color(0xFF27AE60);
      }
    }
    // Simple fallback colors for default statuses if color not defined in DB
    switch (statusName.toLowerCase()) {
      case 'available':
        return const Color(0xFF27AE60);
      case 'assigned':
        return const Color(0xFF4A90D9);
      case 'maintenance':
        return const Color(0xFFE67E22);
      case 'retired':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        statusName.isEmpty ? 'Unknown' : statusName[0].toUpperCase() + statusName.substring(1),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
