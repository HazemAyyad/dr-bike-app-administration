import 'package:doctorbike/features/technical_support/data/support_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store conversation parses requester, assignment, and product context',
      () {
    final conversation = SupportConversation.fromJson({
      'id': 8,
      'source': 'online_store',
      'requester_name': 'عميل المتجر',
      'requester_phone': '0590000000',
      'subject': 'استفسار',
      'status': 'open',
      'priority': 'normal',
      'support_unread_count': 1,
      'requester_unread_count': 0,
      'assigned_to_user_id': 4,
      'assigned_to_name': 'Support Agent',
      'product_context': {
        'listing_id': 31,
        'product_id': 12,
        'name_ar': 'دراجة',
      },
    });

    expect(conversation.source, 'online_store');
    expect(conversation.requesterName, 'عميل المتجر');
    expect(conversation.assignedToUserId, 4);
    expect(conversation.productContext?['listing_id'], 31);
    expect(conversation.productContext?['product_id'], 12);
  });

  test('employee conversation remains backward compatible', () {
    final conversation = SupportConversation.fromJson({
      'id': 9,
      'employee_id': 2,
      'employee_name': 'موظف',
      'status': 'pending',
      'priority': 'normal',
    });

    expect(conversation.source, 'employee');
    expect(conversation.employeeName, 'موظف');
    expect(conversation.productContext, isNull);
  });

  test('support message keeps optimistic identity and delivery state', () {
    const optimistic = SupportMessage(
      id: -1,
      conversationId: 8,
      senderUserId: 0,
      senderEmployeeId: 0,
      senderName: '',
      senderType: 'support',
      messageType: 'text',
      body: 'مرحبا',
      attachments: [],
      reactions: [],
      myReaction: '',
      createdAt: null,
      clientMessageId: 'fixed-id',
      delivery: SupportMessageDelivery.sending,
    );

    final failed = optimistic.copyWith(
      delivery: SupportMessageDelivery.failed,
    );
    expect(failed.clientMessageId, 'fixed-id');
    expect(failed.delivery, SupportMessageDelivery.failed);
  });
}
