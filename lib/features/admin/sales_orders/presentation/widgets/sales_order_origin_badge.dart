import 'package:flutter/material.dart';

class SalesOrderOriginBadge extends StatelessWidget {
  const SalesOrderOriginBadge({Key? key, required this.origin})
      : super(key: key);

  final String origin;

  String get label => origin == 'store' ? 'المتجر' : 'الإدارة';

  @override
  Widget build(BuildContext context) {
    final color = origin == 'store' ? Colors.teal : Colors.blueGrey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
      ),
    );
  }
}
