import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'phone_format_helper.dart';

class PickedContactData {
  const PickedContactData({required this.name, required this.phone});

  final String name;
  final String phone;
}

String _bestPhone(List<Phone> phones) {
  if (phones.isEmpty) return '';
  for (final p in phones) {
    final n = p.number.trim();
    if (n.isNotEmpty) return PhoneFormatHelper.forApi(n);
  }
  return '';
}

/// يعرض قائمة جهات الاتصال مع إمكانية اختيار واحد أو أكثر.
Future<List<PickedContactData>?> pickContactsFromDevice(
  BuildContext context, {
  bool allowMultiple = true,
}) async {
  if (!await FlutterContacts.requestPermission(readonly: true)) {
    Get.snackbar(
      'error'.tr,
      'contactsPermissionRequired'.tr,
      snackPosition: SnackPosition.BOTTOM,
    );
    return null;
  }

  final contacts = await FlutterContacts.getContacts(
    withProperties: true,
    withPhoto: false,
  );

  contacts.sort(
    (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
  );

  final selected = <int>{};

  if (!context.mounted) return null;

  return showModalBottomSheet<List<PickedContactData>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              allowMultiple
                                  ? 'importContacts'.tr
                                  : 'importContact'.tr,
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text('cancel'.tr),
                          ),
                          TextButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    final result = <PickedContactData>[];
                                    for (final i in selected) {
                                      final c = contacts[i];
                                      final phone = _bestPhone(c.phones);
                                      if (phone.isEmpty) continue;
                                      result.add(PickedContactData(
                                        name: c.displayName,
                                        phone: phone,
                                      ));
                                    }
                                    Navigator.pop(ctx, result);
                                  },
                            child: Text('confirm'.tr),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: contacts.length,
                        itemBuilder: (context, index) {
                          final c = contacts[index];
                          final phone = _bestPhone(c.phones);
                          return CheckboxListTile(
                            value: selected.contains(index),
                            onChanged: phone.isEmpty
                                ? null
                                : (v) {
                                    setState(() {
                                      if (v == true) {
                                        if (allowMultiple) {
                                          selected.add(index);
                                        } else {
                                          selected
                                            ..clear()
                                            ..add(index);
                                        }
                                      } else {
                                        selected.remove(index);
                                      }
                                    });
                                  },
                            title: Text(c.displayName),
                            subtitle: Text(
                              phone.isEmpty ? 'noPhoneNumber'.tr : phone,
                            ),
                            secondary: allowMultiple
                                ? null
                                : IconButton(
                                    icon: const Icon(Icons.check),
                                    onPressed: phone.isEmpty
                                        ? null
                                        : () {
                                            Navigator.pop(ctx, [
                                              PickedContactData(
                                                name: c.displayName,
                                                phone: _bestPhone(c.phones),
                                              ),
                                            ]);
                                          },
                                  ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    },
  );
}
