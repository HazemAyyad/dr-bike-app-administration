import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/dio_consumer.dart';
import 'package:doctorbike/core/errors/failure.dart';
import 'package:doctorbike/features/admin/boxes/domain/repositories/boxes_repository.dart';
import 'package:doctorbike/features/admin/boxes/domain/usecases/get_shown_box_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/repositories/checks_repository.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/add_checks_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/add_incoming_checks_batch_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/all_customers_sellers_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/cashed_to_person_cancel_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/chash_to_box_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/delete_check_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/edit_checks_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/general_checks_data_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/get_checks_usecase.dart';
import 'package:doctorbike/features/admin/checks/domain/usecases/return_check_usercase.dart';
import 'package:doctorbike/features/admin/checks/presentation/controllers/checks_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(Get.reset);

  test('blocks a second cash request while the owner phone check is pending',
      () async {
    final api = _OwnerPhoneApi();
    Get.put<DioConsumer>(api);
    final repository = _ChecksRepository();
    final controller = ChecksController(
      addChecksUsecase: AddChecksUsecase(checksRepository: repository),
      addIncomingChecksBatchUsecase:
          AddIncomingChecksBatchUsecase(checksRepository: repository),
      getChecksUsecase: GetChecksUsecase(checksRepository: repository),
      generalChecksDataUsecase:
          GeneralChecksDataUsecase(checksRepository: repository),
      cashedToPersonCancelUsecase:
          CashedToPersonOrCashedUsecase(checksRepository: repository),
      allCustomersSellersUsecase:
          AllCustomersSellersUsecase(checksRepository: repository),
      returnCheckUsercase: ReturnCheckUsercase(checksRepository: repository),
      getShownBoxUsecase:
          GetShownBoxUsecase(boxesRepository: _BoxesRepository()),
      chashToBoxUsecase: ChashToBoxUsecase(checksRepository: repository),
      editChecksUsecase: EditChecksUsecase(checksRepository: repository),
      deleteCheckUsecase: DeleteCheckUsecase(checksRepository: repository),
    );
    addTearDown(controller.onClose);

    final first = controller.chashToBox(checkId: '461', boxId: '94');
    final second = controller.chashToBox(checkId: '461', boxId: '94');
    controller.selectedBulkCheckIds.add(461);
    final bulk = controller.bulkChashToBox(boxId: '94');

    expect(controller.isLoading.value, isTrue);
    expect(api.requests, 1);
    expect(repository.requests, 0);

    api.reply.complete(Response<dynamic>(
      requestOptions: RequestOptions(),
      data: {'requires_owner_phone': false},
    ));
    await Future.wait([first, second, bulk]);
    expect(repository.requests, 1);
    expect(controller.isLoading.value, isFalse);

    await controller.chashToBox(checkId: '461', boxId: '94');
    expect(repository.requests, 2);
  });
}

class _OwnerPhoneApi extends Fake implements DioConsumer {
  final reply = Completer<Response<dynamic>>();
  int requests = 0;

  @override
  Future<Response<dynamic>> get(
    String path, {
    Options? options,
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    requests++;
    return reply.future;
  }
}

class _ChecksRepository extends Fake implements ChecksRepository {
  int requests = 0;

  @override
  Future<Either<Failure, String>> chashToBox({
    required String boxId,
    required String checkId,
    required bool isInComing,
  }) async {
    requests++;
    return Left(ValidationFailure('Try again', null));
  }
}

class _BoxesRepository extends Fake implements BoxesRepository {}
