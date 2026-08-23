import 'package:doctorbike/features/admin/buying/data/models/bills_models/bills_details_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BillDetailsModel', () {
    test('parses purchase details workflow data used by details tabs', () {
      final model = BillDetailsModel.fromJson({
        'bill_id': 150,
        'seller_id': null,
        'customer_id': 44,
        'seller_name': 'أحمد محمد',
        'created_at': '2026-08-23 10:00',
        'total_bill': 10000,
        'workflow_status': 'partially_received',
        'payment_status': 'partial',
        'final_total': 9800,
        'paid_amount': 5000,
        'remaining_amount': 4800,
        'products': [
          {
            'id': 901,
            'bill_id': 150,
            'product_id': 7,
            'product_name': 'فحمات',
            'product_image': null,
            'quantity': 10,
            'price': 3,
            'sub_total': 30,
            'extra_amount': 2,
            'missing_amount': 1,
            'not_compatible_amount': 1,
            'ordered_quantity': 10,
            'received_owned_quantity': 8,
            'remaining_quantity': 2,
            'custody_quantity': 2,
            'damaged_quantity': 1,
            'mismatched_quantity': 1,
            'amanat_stocks': [
              {
                'id': 31,
                'quantity': 2,
                'remaining_quantity': 2,
                'status': 'active',
                'negotiated_unit_price': 2.5,
                'notes': 'زائد عن الطلب',
              }
            ],
          }
        ],
        'payments': [
          {
            'id': 77,
            'amount': 5000,
            'payment_type': 'initial',
            'paid_at': '2026-08-23',
            'box_id': 3,
            'box_name': 'الصندوق الرئيسي',
            'note': 'دفعة أولى',
          }
        ],
        'returns': [
          {
            'id': 88,
            'status': 'supplier_credit',
            'total_value': 300,
            'created_at': '2026-08-23',
            'items': [
              {
                'id': 99,
                'product_name': 'فحمات',
                'quantity': 1,
                'unit_price': 300,
              }
            ],
          }
        ],
        'attachments': [
          {
            'id': 45,
            'file_name': 'damage.jpg',
            'category': 'damaged_evidence',
            'url': 'https://example.test/damage.jpg',
            'mime_type': 'image/jpeg',
            'size': 2048,
            'created_at': '2026-08-23',
          }
        ],
        'timeline': [
          {
            'id': 1,
            'action': 'purchase_received',
            'title': 'تم الاستلام',
            'description': 'تم تسجيل استلام جزئي',
            'created_at': '2026-08-23 10:20',
          }
        ],
      });

      expect(model.billId, 150);
      expect(model.customerId, '44');
      expect(model.sellerId, isEmpty);
      expect(model.workflowStatus, 'partially_received');
      expect(model.paymentStatus, 'partial');
      expect(model.products, hasLength(1));
      expect(model.products.first.billItemId, 901);
      expect(model.products.first.orderedQuantity, 10);
      expect(model.products.first.receivedOwnedQuantity, 8);
      expect(model.products.first.remainingQuantity, 2);
      expect(model.products.first.damagedQuantity, 1);
      expect(model.products.first.mismatchedQuantity, 1);
      expect(model.products.first.amanatStocks.single.id, 31);
      expect(model.payments.single.boxName, 'الصندوق الرئيسي');
      expect(model.returns.single.items.single.productName, 'فحمات');
      expect(model.attachments.single.category, 'damaged_evidence');
      expect(model.timeline.single.action, 'purchase_received');
    });

    test('falls back to quantity when ordered quantity is missing', () {
      final item = BillProductModel.fromJson({
        'id': 5,
        'bill_id': 1,
        'product_id': 2,
        'product_name': 'بطارية',
        'quantity': '6',
        'price': '40',
        'sub_total': '240',
      });

      expect(item.orderedQuantity, 6);
      expect(item.remainingQuantity, 0);
      expect(item.amanatStocks, isEmpty);
    });
  });
}
