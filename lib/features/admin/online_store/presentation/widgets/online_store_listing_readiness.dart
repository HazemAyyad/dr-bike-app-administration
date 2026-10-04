import 'package:flutter/material.dart';

class OnlineStoreListingReadiness extends StatelessWidget {
  const OnlineStoreListingReadiness({
    Key? key,
    required this.state,
    required this.issues,
  }) : super(key: key);

  final String state;
  final List<String> issues;

  @override
  Widget build(BuildContext context) {
    final ready = state == 'ready' && issues.isEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ready ? const Color(0xFFE9F7EF) : const Color(0xFFFFF4E5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ready ? const Color(0xFF3A9D63) : const Color(0xFFD18A1D),
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(
              ready ? Icons.check_circle_outline : Icons.warning_amber_rounded),
          const SizedBox(width: 8),
          Text(ready ? 'جاهز للنشر' : 'متطلبات النشر',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        ...issues.map((issue) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• $issue'),
            )),
      ]),
    );
  }
}
