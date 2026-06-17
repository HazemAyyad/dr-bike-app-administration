import 'package:flutter/material.dart';

import 'sales_orders_table.dart';
import 'sales_orders_toolbar.dart';

/// تبويب الطلبيات داخل شاشة المبيعات.
class SalesOrdersTab extends StatelessWidget {
  const SalesOrdersTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SalesOrdersToolbar(),
        SalesOrdersTable(),
      ],
    );
  }
}
