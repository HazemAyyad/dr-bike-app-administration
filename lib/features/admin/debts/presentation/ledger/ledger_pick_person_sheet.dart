import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../../core/widgets/person_avatar_image.dart';
import '../../data/models/debt_ledger_models.dart';
import '../../domain/repositories/debt_ledger_repository.dart';
import 'ledger_colors.dart';

class LedgerPickPersonSheet extends StatefulWidget {
  const LedgerPickPersonSheet({
    Key? key,
    required this.isCustomer,
    required this.repository,
  }) : super(key: key);

  final bool isCustomer;
  final DebtLedgerRepository repository;

  @override
  State<LedgerPickPersonSheet> createState() => _LedgerPickPersonSheetState();
}

class _LedgerPickPersonSheetState extends State<LedgerPickPersonSheet> {
  final _searchController = TextEditingController();
  final RxList<LedgerPerson> _people = <LedgerPerson>[].obs;
  final RxBool _loading = true.obs;
  Timer? _searchDebounce;

  String get _type => widget.isCustomer ? 'customers' : 'sellers';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load({String? search}) async {
    _loading(true);
    final result = await widget.repository.getPeoplePicker(
      type: _type,
      search: search,
    );
    result.fold(
      (failure) {
        _people.clear();
        Get.snackbar('error'.tr, failure.errMessage);
      },
      (list) => _people.assignAll(list),
    );
    _loading(false);
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(
      const Duration(milliseconds: 350),
      () => _load(search: value.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 16.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.isCustomer
                    ? 'ledgerPickCustomer'.tr
                    : 'ledgerPickSupplier'.tr,
                style: TextStyle(
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w700,
                  color: LedgerColors.primaryBlue,
                ),
              ),
              SizedBox(height: 12.h),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'search'.tr,
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
              SizedBox(height: 8.h),
              SizedBox(
                height: 360.h,
                child: Obx(() {
                  if (_loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (_people.isEmpty) {
                    return Center(child: Text('ledgerNoPeopleFound'.tr));
                  }
                  return ListView.separated(
                    itemCount: _people.length,
                    separatorBuilder: (_, __) => SizedBox(height: 6.h),
                    itemBuilder: (_, index) {
                      final person = _people[index];
                      return ListTile(
                        leading: PersonAvatarImage(
                          imageUrl: person.imageUrl,
                          width: 44.w,
                          height: 44.w,
                          circular: true,
                        ),
                        title: Text(
                          person.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15.sp,
                          ),
                        ),
                        subtitle:
                            person.phone != null && person.phone!.isNotEmpty
                                ? Text(person.phone!)
                                : null,
                        trailing: Icon(
                          Icons.post_add_outlined,
                          color: LedgerColors.primaryBlue,
                          size: 26.sp,
                        ),
                        onTap: () => Get.back(result: person),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
