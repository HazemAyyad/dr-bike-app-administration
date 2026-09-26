import 'package:doctorbike/features/admin/buying/data/models/bills_models/bills_details_model.dart';
import 'package:doctorbike/features/admin/buying/data/models/bills_models/bills_model.dart';
import 'package:doctorbike/features/admin/buying/presentation/controllers/bills_controller.dart';
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
            'actor_id': 12,
            'actor_name': 'موظف الاستلام',
            'actor_type': 'employee',
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
      expect(model.timeline.single.actorId, '12');
      expect(model.timeline.single.actorName, 'موظف الاستلام');
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

  group('BillDataModel purchase actions', () {
    test('received invoice without issues can be approved from its card', () {
      final bill = BillDataModel.fromJson({
        'id': 71,
        'workflow_status': 'received',
        'payment_status': 'unpaid',
        'remaining_amount': 200,
        'receiving_issues_count': 0,
      });

      expect(bill.isAwaitingApproval, isTrue);
      expect(bill.canQuickFinalize, isTrue);
      expect(bill.canQuickPay, isTrue);
    });

    test('received invoice with unresolved issues cannot be quick approved',
        () {
      final bill = BillDataModel.fromJson({
        'id': 72,
        'workflow_status': 'received',
        'payment_status': 'unpaid',
        'remaining_amount': 200,
        'receiving_issues_count': 1,
      });

      expect(bill.isAwaitingApproval, isTrue);
      expect(bill.canQuickFinalize, isFalse);
      expect(bill.canQuickPay, isTrue);
    });

    test('cancelled invoice cannot be paid from its card', () {
      final bill = BillDataModel.fromJson({
        'id': 73,
        'workflow_status': 'cancelled',
        'payment_status': 'unpaid',
        'remaining_amount': 200,
      });

      expect(bill.canQuickPay, isFalse);
    });

    test('finalized unpaid invoice stays actionable until fully paid', () {
      final bill = BillDataModel.fromJson({
        'id': 74,
        'workflow_status': 'finalized',
        'payment_status': 'unpaid',
        'final_total': 90,
        'paid_amount': 0,
        'remaining_amount': 90,
      });

      expect(bill.needsFullPayment, isTrue);
      expect(bill.needsPartialPayment, isFalse);
      expect(bill.isPaymentComplete, isFalse);
      expect(bill.canQuickPay, isTrue);
    });

    test('finalized partially paid invoice stays actionable', () {
      final bill = BillDataModel.fromJson({
        'id': 75,
        'workflow_status': 'finalized',
        'payment_status': 'partially_paid',
        'final_total': 90,
        'paid_amount': 80,
        'remaining_amount': 10,
      });

      expect(bill.needsFullPayment, isFalse);
      expect(bill.needsPartialPayment, isTrue);
      expect(bill.isPaymentComplete, isFalse);
      expect(bill.canQuickPay, isTrue);
    });

    test('only invoice without remaining payment is complete', () {
      final bill = BillDataModel.fromJson({
        'id': 76,
        'workflow_status': 'finalized',
        'payment_status': 'paid',
        'final_total': 90,
        'paid_amount': 90,
        'remaining_amount': 0,
      });

      expect(bill.needsFullPayment, isFalse);
      expect(bill.needsPartialPayment, isFalse);
      expect(bill.isPaymentComplete, isTrue);
      expect(bill.canQuickPay, isFalse);
    });
  });

  group('PurchaseReceivingRowModel', () {
    BillProductModel product({num remaining = 6}) => BillProductModel.fromJson({
          'id': 91,
          'bill_id': 9,
          'product_id': 7,
          'product_name': 'قطعة اختبار',
          'quantity': 6,
          'price': 5,
          'sub_total': 30,
          'ordered_quantity': 6,
          'received_owned_quantity': 6 - remaining,
          'remaining_quantity': remaining,
        });

    test('splits six remaining items into five good and one damaged', () {
      final row = PurchaseReceivingRowModel(product: product())
        ..prepareForMode('damaged');
      addTearDown(row.dispose);

      expect(row.accepted, 5);
      expect(row.damaged, 1);
      expect(row.orderedOutcomeQuantity, 6);
      expect(row.isValid, isTrue);
      expect(row.toApiMap(), containsPair('accepted_quantity', 5));
      expect(row.toApiMap(), containsPair('damaged_quantity', 1));
    });

    test('rejects a good and damaged total above the remaining quantity', () {
      final row = PurchaseReceivingRowModel(product: product())
        ..prepareForMode('damaged');
      addTearDown(row.dispose);
      row.acceptedController.text = '6';
      row.damagedController.text = '1';

      expect(row.isValid, isFalse);
      expect(row.validationMessage, contains('لا يمكن أن يتجاوز 6'));
    });

    test('keeps extra custody outside the ordered quantity limit', () {
      final row = PurchaseReceivingRowModel(product: product())
        ..prepareForMode('extra');
      addTearDown(row.dispose);

      expect(row.accepted, 6);
      expect(row.effectiveExtra, 1);
      expect(row.orderedOutcomeQuantity, 6);
      expect(row.isValid, isTrue);
    });

    test('uses the fractional remainder as the default issue quantity', () {
      final row = PurchaseReceivingRowModel(product: product(remaining: .5))
        ..prepareForMode('missing');
      addTearDown(row.dispose);

      expect(row.accepted, 0);
      expect(row.missing, .5);
      expect(row.isValid, isTrue);
    });
  });
}
