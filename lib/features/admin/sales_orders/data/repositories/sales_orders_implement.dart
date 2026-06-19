import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:doctorbike/core/connection/network_info.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/core/errors/expentions.dart';
import 'package:doctorbike/core/errors/failure.dart';

import '../datasources/sales_orders_datasource.dart';
import '../../../checks/data/models/check_model.dart';
import '../models/sales_order_model.dart';

abstract class SalesOrdersRepository {
  Future<Either<Failure, List<SalesOrderListItemModel>>> getOrders({
    String? status,
  });

  Future<Either<Failure, SalesOrderDetailModel>> getOrder(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> createOrder(
    Map<String, dynamic> body,
  );

  Future<Either<Failure, SalesOrderDetailModel>> updateOrder(
    int orderId,
    Map<String, dynamic> body,
  );

  Future<Either<Failure, SalesOrderDetailModel>> confirmOrder(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> markReady(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> handover(
    int orderId,
    Map<String, dynamic> body,
  );

  Future<Either<Failure, SalesOrderDetailModel>> deliver(
    int orderId,
    Map<String, dynamic> body,
  );

  Future<Either<Failure, SalesOrderDetailModel>> settle(
    int orderId,
    Map<String, dynamic> body,
  );

  Future<Either<Failure, SalesOrderDetailModel>> archive(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> cancel(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> revertOrder(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> uploadMedia(
    int orderId,
    List<MultipartFile> files, {
    String? category,
  });

  Future<Either<Failure, SalesOrderDetailModel>> postpone(
    int orderId,
    String postponedUntil, {
    String? reason,
  });

  Future<Either<Failure, SalesOrderDetailModel>> markStuck(
    int orderId, {
    String? reason,
  });

  Future<Either<Failure, Map<String, dynamic>>> bulkStatus({
    required List<int> orderIds,
    required String action,
  });

  Future<Either<Failure, SalesOrderDetailModel>> partialDeliver(
    int orderId,
    List<Map<String, dynamic>> items,
  );

  Future<Either<Failure, SalesOrderDetailModel>> followUp(int orderId);

  Future<Either<Failure, SalesOrderDetailModel>> partialReturn(
    int orderId,
    List<Map<String, dynamic>> items,
  );

  Future<Either<Failure, SalesOrderDetailModel>> alternativeReturn(
    int orderId,
    List<Map<String, dynamic>> items,
  );

  Future<Either<Failure, Map<String, dynamic>>> fetchStatement(int orderId);

  Future<Either<Failure, List<CityModel>>> getCities();

  Future<Either<Failure, List<DeliveryCompanyModel>>> getDeliveryCompanies();

  Future<Either<Failure, ShiplyAddressOptionsResult>> getShiplyAddressOptions();

  Future<Either<Failure, double?>> calculateShiplyDeliveryFee({
    required int villageId,
    double price,
  });

  Future<Either<Failure, List<SellerModel>>> getCustomersList();

  Future<Either<Failure, List<SellerModel>>> getSellersList();

  Future<Either<Failure, SellerModel>> createPersonQuick({
    required String personType,
    required String name,
    required String phone,
  });

  Future<Either<Failure, void>> updatePersonPhone({
    required bool isCustomer,
    required int personId,
    required String name,
    required String phone,
  });
}

class SalesOrdersImplement implements SalesOrdersRepository {
  SalesOrdersImplement({
    required this.networkInfo,
    required this.datasource,
  });

  final NetworkInfo networkInfo;
  final SalesOrdersDatasource datasource;

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      return Right(await run());
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    } catch (_) {
      return Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<SalesOrderListItemModel>>> getOrders({
    String? status,
  }) =>
      _guard(() => datasource.fetchOrders(status: status));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> getOrder(int orderId) =>
      _guard(() => datasource.fetchOrder(orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> createOrder(
    Map<String, dynamic> body,
  ) =>
      _guard(() => datasource.createOrder(body));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> updateOrder(
    int orderId,
    Map<String, dynamic> body,
  ) =>
      _guard(() => datasource.updateOrder(orderId, body));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> confirmOrder(int orderId) =>
      _guard(() => datasource.postAction(EndPoints.salesOrderConfirm, orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> markReady(int orderId) =>
      _guard(() => datasource.postAction(EndPoints.salesOrderReady, orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> handover(
    int orderId,
    Map<String, dynamic> body,
  ) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderHandover,
            orderId,
            extra: body,
          ));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> deliver(
    int orderId,
    Map<String, dynamic> body,
  ) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderDeliver,
            orderId,
            extra: body,
          ));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> settle(
    int orderId,
    Map<String, dynamic> body,
  ) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderSettle,
            orderId,
            extra: body,
          ));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> archive(int orderId) =>
      _guard(() => datasource.postAction(EndPoints.salesOrderArchive, orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> cancel(int orderId) =>
      _guard(() => datasource.postAction(EndPoints.salesOrderCancel, orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> revertOrder(int orderId) =>
      _guard(() => datasource.postAction(EndPoints.salesOrderRevert, orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> uploadMedia(
    int orderId,
    List<MultipartFile> files, {
    String? category,
  }) =>
      _guard(() => datasource.uploadMedia(orderId, files, category: category));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> postpone(
    int orderId,
    String postponedUntil, {
    String? reason,
  }) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderPostpone,
            orderId,
            extra: {
              'postponed_until': postponedUntil,
              if (reason != null && reason.isNotEmpty) 'reason': reason,
            },
          ));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> markStuck(
    int orderId, {
    String? reason,
  }) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderMarkStuck,
            orderId,
            extra: {
              if (reason != null && reason.isNotEmpty) 'reason': reason,
            },
          ));

  @override
  Future<Either<Failure, Map<String, dynamic>>> bulkStatus({
    required List<int> orderIds,
    required String action,
  }) =>
      _guard(() => datasource.bulkStatus(orderIds: orderIds, action: action));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> partialDeliver(
    int orderId,
    List<Map<String, dynamic>> items,
  ) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderPartialDeliver,
            orderId,
            extra: {'items': items},
          ));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> followUp(int orderId) =>
      _guard(() => datasource.postAction(EndPoints.salesOrderFollowUp, orderId));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> partialReturn(
    int orderId,
    List<Map<String, dynamic>> items,
  ) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderPartialReturn,
            orderId,
            extra: {'items': items},
          ));

  @override
  Future<Either<Failure, SalesOrderDetailModel>> alternativeReturn(
    int orderId,
    List<Map<String, dynamic>> items,
  ) =>
      _guard(() => datasource.postAction(
            EndPoints.salesOrderAlternativeReturn,
            orderId,
            extra: {'items': items},
          ));

  @override
  Future<Either<Failure, Map<String, dynamic>>> fetchStatement(int orderId) =>
      _guard(() => datasource.fetchStatement(orderId));

  @override
  Future<Either<Failure, List<CityModel>>> getCities() =>
      _guard(() => datasource.fetchCities());

  @override
  Future<Either<Failure, List<DeliveryCompanyModel>>> getDeliveryCompanies() =>
      _guard(() => datasource.fetchDeliveryCompanies());

  @override
  Future<Either<Failure, ShiplyAddressOptionsResult>> getShiplyAddressOptions() =>
      _guard(() => datasource.fetchShiplyAddressOptions());

  @override
  Future<Either<Failure, double?>> calculateShiplyDeliveryFee({
    required int villageId,
    double price = 0,
  }) =>
      _guard(() => datasource.fetchShiplyDeliveryFee(
            villageId: villageId,
            price: price,
          ));

  @override
  Future<Either<Failure, List<SellerModel>>> getCustomersList() =>
      _guard(() => datasource.fetchCustomersList());

  @override
  Future<Either<Failure, List<SellerModel>>> getSellersList() =>
      _guard(() => datasource.fetchSellersList());

  @override
  Future<Either<Failure, SellerModel>> createPersonQuick({
    required String personType,
    required String name,
    required String phone,
  }) =>
      _guard(() => datasource.createPersonQuick(
            personType: personType,
            name: name,
            phone: phone,
          ));

  @override
  Future<Either<Failure, void>> updatePersonPhone({
    required bool isCustomer,
    required int personId,
    required String name,
    required String phone,
  }) =>
      _guard(() => datasource.updatePersonPhone(
            isCustomer: isCustomer,
            personId: personId,
            name: name,
            phone: phone,
          ));
}
