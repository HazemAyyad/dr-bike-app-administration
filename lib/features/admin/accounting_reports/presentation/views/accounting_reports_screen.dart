import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../../routes/app_routes.dart';

class AccountingReportsScreen extends StatelessWidget {
  const AccountingReportsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('تقارير محاسبية')),
        body: Directionality(
            textDirection: TextDirection.rtl,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text('اختر التقرير المطلوب',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold))),
                _card(
                    'إجمالي المبيعات',
                    'حسب الزبون أو الشهر أو اليوم، مع الخصومات والمرتجعات والنسب.',
                    Icons.bar_chart_rounded,
                    AppRoutes.SALESACCOUNTINGSCREEN),
                _card(
                    'كشف حركات المصاريف',
                    'الحركات والسندات والرصيد المدور، حسب المصروف والصندوق والفترة.',
                    Icons.receipt_long_outlined,
                    AppRoutes.EXPENSEACCOUNTINGSCREEN),
                _card(
                    'قائمة الدخل المفصّلة',
                    'الإيرادات وتكلفة المبيعات وتفصيل المصاريف وصافي الربح أو الخسارة.',
                    Icons.account_balance_outlined,
                    AppRoutes.INCOMEACCOUNTINGSCREEN),
              ],
            )),
      );
  Widget _card(String title, String description, IconData icon, String route) =>
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: Icon(icon),
          title:
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Padding(
              padding: const EdgeInsets.only(top: 6), child: Text(description)),
          trailing: const Icon(Icons.chevron_left),
          onTap: () => Get.toNamed(route),
        ),
      );
}
