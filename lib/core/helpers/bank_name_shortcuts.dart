/// اختصارات أسماء البنوك — Enter يكمل الاسم الكامل.
class BankNameShortcut {
  const BankNameShortcut(this.prefix, this.fullName);

  final String prefix;
  final String fullName;
}

const List<BankNameShortcut> kBankNameShortcuts = [
  BankNameShortcut('ف', 'بنك فلسطين'),
  BankNameShortcut('عق', 'البنك العقاري المصري'),
  BankNameShortcut('ق ع', 'بنك القاهرة عمان'),
  BankNameShortcut('ا', 'بنك الاردن'),
  BankNameShortcut('ع', 'البنك العربي'),
  BankNameShortcut('الاس', 'بنك الاستثمار'),
  BankNameShortcut('الاه', 'البنك الاهلي الاردني'),
  BankNameShortcut('الإ', 'بنك الإسكان'),
  BankNameShortcut('الإس', 'البنك الإسلامي الفلسطيني'),
  BankNameShortcut('الإسل', 'البنك الإسلامي العربي'),
  BankNameShortcut('ق', 'بنك القدس'),
  BankNameShortcut('و', 'بنك الوطني'),
  BankNameShortcut('ص', 'بنك الصفا'),
  BankNameShortcut('ك', 'كمبيالة'),
];

List<BankNameShortcut> matchBankShortcuts(String query) {
  final q = query.trim();
  if (q.isEmpty) return [];

  final lower = q.toLowerCase();
  return kBankNameShortcuts.where((s) {
    final p = s.prefix.toLowerCase();
    final n = s.fullName.toLowerCase();
    return p.startsWith(lower) ||
        lower.startsWith(p) ||
        n.contains(lower) ||
        n.startsWith(lower);
  }).toList();
}

String? uniqueBankCompletion(String query) {
  final matches = matchBankShortcuts(query);
  if (matches.length == 1) return matches.first.fullName;
  final q = query.trim().toLowerCase();
  final exact = matches.where((s) => s.prefix.toLowerCase() == q);
  if (exact.length == 1) return exact.first.fullName;
  return null;
}
