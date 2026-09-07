import 'package:doctorbike/features/admin/whatsapp_center/presentation/utils/social_datetime_formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formats message time using a 12 hour Arabic period', () {
    expect(formatSocialClock(DateTime(2026, 9, 7, 0, 5)), '12:05 ص');
    expect(formatSocialClock(DateTime(2026, 9, 7, 12, 30)), '12:30 م');
    expect(formatSocialClock(DateTime(2026, 9, 7, 19, 32)), '7:32 م');
  });

  test('formats today and yesterday chat dividers', () {
    final now = DateTime(2026, 9, 7, 15);
    expect(formatSocialDayDivider(DateTime(2026, 9, 7, 8), now: now), 'اليوم');
    expect(formatSocialDayDivider(DateTime(2026, 9, 6, 23), now: now), 'أمس');
  });

  test('formats older chat dividers with weekday and full date', () {
    expect(
      formatSocialDayDivider(
        DateTime(2026, 9, 5, 10),
        now: DateTime(2026, 9, 7, 15),
      ),
      'السبت، 5/9/2026',
    );
  });

  test('formats conversation list stamp consistently', () {
    final now = DateTime(2026, 9, 7, 15);
    expect(
      formatSocialConversationStamp(DateTime(2026, 9, 7, 7, 2), now: now),
      '7:02 ص',
    );
    expect(
      formatSocialConversationStamp(DateTime(2026, 9, 6, 7, 2), now: now),
      'أمس',
    );
    expect(
      formatSocialConversationStamp(DateTime(2026, 9, 5, 7, 2), now: now),
      '5/9/26',
    );
  });
}
