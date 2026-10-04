import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/online_store_credit_controller.dart';

class OnlineStoreCreditPolicyScreen extends StatefulWidget {
  const OnlineStoreCreditPolicyScreen({Key? key}) : super(key: key);
  @override
  State<OnlineStoreCreditPolicyScreen> createState() =>
      _OnlineStoreCreditPolicyScreenState();
}

class _OnlineStoreCreditPolicyScreenState
    extends State<OnlineStoreCreditPolicyScreen> {
  final controller = Get.find<OnlineStoreCreditController>();
  final limit = TextEditingController();
  final expiresAt = TextEditingController();
  bool eligible = false;
  String currency = 'ILS';

  @override
  void initState() {
    super.initState();
    controller.load(Get.arguments as int).then((_) {
      final value = controller.snapshot.value;
      if (value != null && mounted) {
        setState(() {
          eligible = value.eligible;
          limit.text = value.limit?.toString() ?? '';
          expiresAt.text = value.expiresAt ?? '';
          currency = value.currency;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سياسة الائتمان')),
        body: Obx(() {
          final value = controller.snapshot.value;
          if (controller.loading.value || value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(padding: const EdgeInsets.all(14), children: [
            Card(
                color: const Color(0xFFF2F2F5),
                child: Column(children: [
                  ListTile(
                      title: const Text('الدين الحالي من دفتر الحسابات'),
                      trailing: Text('${value.currentDebt} ${value.currency}')),
                  ListTile(
                      title: const Text('الائتمان المتاح محسوب من الخادم'),
                      trailing:
                          Text('${value.availableCredit} ${value.currency}')),
                  ListTile(
                      title: const Text('آخر احتساب'),
                      subtitle: Text(value.asOf ?? 'غير متاح')),
                ])),
            SwitchListTile(
              value: eligible,
              onChanged: (v) => setState(() => eligible = v),
              title: const Text('مؤهل للائتمان'),
            ),
            TextField(
              controller: limit,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'حد اختياري'),
            ),
            DropdownButtonFormField<String>(
              initialValue: currency,
              decoration: const InputDecoration(labelText: 'العملة'),
              items: const [DropdownMenuItem(value: 'ILS', child: Text('ILS'))],
              onChanged: (v) => currency = v ?? 'ILS',
            ),
            TextField(
              controller: expiresAt,
              decoration: const InputDecoration(
                labelText: 'تاريخ انتهاء الأهلية (اختياري)',
                hintText: 'YYYY-MM-DD',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => controller.savePolicy(
                eligible: eligible,
                limit: double.tryParse(limit.text),
                currency: currency,
                expiresAt: expiresAt.text.trim().isEmpty
                    ? null
                    : expiresAt.text.trim(),
              ),
              child: const Text('حفظ السياسة'),
            ),
          ]);
        }),
      );

  @override
  void dispose() {
    limit.dispose();
    expiresAt.dispose();
    super.dispose();
  }
}
