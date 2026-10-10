import 'package:doctorbike/core/widgets/notification_swipe_card.dart';
import 'package:doctorbike/core/widgets/person_avatar_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget card({String? avatarImageUrl}) => MaterialApp(
        home: Scaffold(
          body: NotificationSwipeCard(
            notificationKey: 'notification-1',
            title: 'طلب جديد',
            body: 'أنشأ العميل طلبًا جديدًا',
            createdAt: '2026-10-10',
            isRead: false,
            icon: Icons.receipt_long_outlined,
            avatarImageUrl: avatarImageUrl,
            accent: Colors.orange,
            onTap: () {},
            onMarkRead: () async {},
            onDelete: () async {},
          ),
        ),
      );

  testWidgets('shows the notification icon without a customer image', (
    tester,
  ) async {
    await tester.pumpWidget(card());

    expect(find.byIcon(Icons.receipt_long_outlined), findsOneWidget);
    expect(find.byType(PersonAvatarImage), findsNothing);
  });

  testWidgets('shows the customer avatar when its URL is provided', (
    tester,
  ) async {
    await tester.pumpWidget(
      card(avatarImageUrl: 'https://example.com/customer.jpg'),
    );

    expect(find.byType(PersonAvatarImage), findsOneWidget);
    expect(find.byIcon(Icons.receipt_long_outlined), findsNothing);
  });
}
