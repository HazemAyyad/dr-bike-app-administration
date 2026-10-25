import 'package:flutter/material.dart';

class SalesOrderNotesBadges extends StatelessWidget {
  const SalesOrderNotesBadges(
      {Key? key,
      required this.internalCount,
      required this.externalCount,
      this.onSelected})
      : super(key: key);
  final int internalCount;
  final int externalCount;
  final ValueChanged<String>? onSelected;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 6, runSpacing: 5, children: [
        if (internalCount > 0)
          _badge('internal', 'داخلية', internalCount, Icons.lock_outline),
        if (externalCount > 0)
          _badge('external', 'خارجية', externalCount, Icons.comment_outlined),
      ]);

  Widget _badge(String scope, String label, int count, IconData icon) =>
      Tooltip(
        message: 'ملاحظات $label: $count',
        child: Material(
            color: const Color(0xFFEAECF0),
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: onSelected == null ? null : () => onSelected!(scope),
              child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon, size: 14, color: const Color(0xFF635CB1)),
                    const SizedBox(width: 4),
                    Text('$label $count',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF374151))),
                  ])),
            )),
      );
}
