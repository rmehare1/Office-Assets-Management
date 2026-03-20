import 'package:flutter/material.dart';
import '../models/asset.dart';

class StatusBadge extends StatelessWidget {
  final AssetStatus status;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.fontSize = 12,
  });

  Color get _color {
    switch (status) {
      case AssetStatus.available:
        return const Color(0xFF27AE60);
      case AssetStatus.assigned:
        return const Color(0xFF4A90D9);
      case AssetStatus.maintenance:
        return const Color(0xFFE67E22);
      case AssetStatus.retired:
        return const Color(0xFFE74C3C);
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
        status.name[0].toUpperCase() + status.name.substring(1),
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
