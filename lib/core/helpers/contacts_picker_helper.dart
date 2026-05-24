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

  final selected = <int>{};

  if (!context.mounted) return null;

  final searchController = TextEditingController();
  var contacts = <Contact>[];
  var isLoadingContacts = true;
  var didStartLoadingContacts = false;

  final picked = await showModalBottomSheet<List<PickedContactData>>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (context, setState) {
          if (!didStartLoadingContacts) {
            didStartLoadingContacts = true;
            FlutterContacts.getContacts(
              withProperties: true,
              withPhoto: false,
            ).then((loadedContacts) {
              loadedContacts.sort(
                (a, b) => a.displayName
                    .toLowerCase()
                    .compareTo(b.displayName.toLowerCase()),
              );
              if (context.mounted) {
                setState(() {
                  contacts = loadedContacts;
                  isLoadingContacts = false;
                });
              }
            }).catchError((_) {
              if (context.mounted) {
                setState(() {
                  contacts = [];
                  isLoadingContacts = false;
                });
              }
            });
          }

          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              final query = searchController.text.trim().toLowerCase();
              final filteredIndexes = <int>[];

              for (var i = 0; i < contacts.length; i++) {
                final contact = contacts[i];
                final phone = _bestPhone(contact.phones);
                final name = contact.displayName.toLowerCase();
                if (query.isEmpty ||
                    name.contains(query) ||
                    phone.toLowerCase().contains(query)) {
                  filteredIndexes.add(i);
                }
              }

              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(12.w),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  allowMultiple
                                      ? 'importContacts'.tr
                                      : 'importContact'.tr,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 4.h),
                                Text(
                                  'contactsSelectedCount'.trParams({
                                    'count': selected.length.toString(),
                                  }),
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (selected.isNotEmpty) ...[
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10.w,
                                vertical: 5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20.r),
                              ),
                              child: Text(
                                selected.length.toString(),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(width: 6.w),
                          ],
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
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12.w),
                      child: TextField(
                        controller: searchController,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'search'.tr,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: query.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() {});
                                  },
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.r),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Expanded(
                      child: isLoadingContacts
                          ? const _ContactsSkeletonList()
                          : filteredIndexes.isEmpty
                              ? Center(child: Text('noData'.tr))
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: filteredIndexes.length,
                                  itemBuilder: (context, filteredIndex) {
                                    final index =
                                        filteredIndexes[filteredIndex];
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
                                        phone.isEmpty
                                            ? 'noPhoneNumber'.tr
                                            : phone,
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
                                                          phone: phone,
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

  searchController.dispose();
  return picked;
}

class _ContactsSkeletonList extends StatelessWidget {
  const _ContactsSkeletonList();

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.onSurface.withValues(
          alpha: 0.08,
        );

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      itemCount: 10,
      separatorBuilder: (_, __) => SizedBox(height: 14.h),
      itemBuilder: (context, index) {
        return Row(
          children: [
            Container(
              width: 22.r,
              height: 22.r,
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(4.r),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FractionallySizedBox(
                    widthFactor: index.isEven ? 0.62 : 0.78,
                    child: Container(
                      height: 13.h,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  FractionallySizedBox(
                    widthFactor: index.isEven ? 0.42 : 0.5,
                    child: Container(
                      height: 10.h,
                      decoration: BoxDecoration(
                        color: baseColor,
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
