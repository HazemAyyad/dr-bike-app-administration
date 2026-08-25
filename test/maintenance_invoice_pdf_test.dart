import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:doctorbike/features/admin/maintenance/data/models/maintenance_invoice_model.dart';
import 'package:doctorbike/features/admin/maintenance/data/models/maintenance_product_model.dart';
import 'package:doctorbike/features/admin/maintenance/presentation/widgets/maintenance_invoice_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('builds the Flutter maintenance invoice PDF', () async {
    const invoice = MaintenanceInvoiceModel(
      maintenanceId: 42,
      invoiceNumber: 'MNT-000042',
      invoiceDate: '2026-08-25 12:30:00',
      invoiceDateDisplay: '2026-08-25 12:30 مساءً',
      status: 'delivered',
      receiptDate: '2026-08-26',
      receiptTime: '14:00',
      receiptDateTimeDisplay: '2026-08-26 02:00 مساءً',
      description: 'تبديل زيت\nملاحظة تجريبية',
      notes: 'ملاحظة تجريبية',
      services: [
        MaintenanceInvoiceServiceModel(
          id: 1,
          name: 'تبديل زيت',
          price: 50,
        ),
      ],
      maintenanceStatusLabel: 'تم التسليم',
      paymentStatus: 'partial',
      paymentStatusLabel: 'مدفوع جزئياً',
      customerTypeLabel: 'زبون',
      customerName: 'زبون تجريبي',
      customerPhone: '0599000000',
      customerAddress: 'رام الله',
      items: [
        MaintenanceProductModel(
          productId: 10,
          productName: 'قطعة غيار تجريبية',
          quantity: 2,
          unitPrice: 25,
          lineTotal: 50,
        ),
      ],
      partsTotal: 50,
      laborCost: 50,
      discount: 10,
      invoiceTotal: 90,
      paidAmount: 40,
      remainingAmount: 50,
      debtAmount: 50,
      hasDebt: true,
      payments: [
        MaintenanceInvoicePaymentModel(
          method: 'cash',
          amount: 40,
          note: 'دفعة أولى',
          createdAt: '2026-08-25 12:30:00',
        ),
      ],
      qrPayload: 'doctorbike://maintenance/invoice/42',
    );

    final bytes = await MaintenanceInvoicePdfBuilder.build(invoice);

    expect(bytes.length, greaterThan(10000));
    expect(ascii.decode(bytes.take(4).toList()), '%PDF');
  });
}
