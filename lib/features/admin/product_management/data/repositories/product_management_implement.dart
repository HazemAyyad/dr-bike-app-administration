import 'package:dartz/dartz.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/product_management_repository.dart';
import '../datasources/product_management_datasource.dart';
import '../models/product_development_model.dart';

class ProductManagementImplement implements ProductManagementRepository {
  final NetworkInfo networkInfo;
  final ProductManagementDatasource productManagementDatasource;

  ProductManagementImplement(
      {required this.networkInfo, required this.productManagementDatasource});

  @override
  Future<List<ProductDevelopmentModel>> getProductDevelopments() async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result = await productManagementDatasource.getProductDevelopments();

      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  @override
  Future<Either<Failure, String>> createProductDevelopment({
    required String productId,
    required String description,
    required String step,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await productManagementDatasource.createProductDevelopment(
        productId: productId,
        description: description,
        step: step,
      );
      if (result['status'] == 'success') {
        return Right(result['message']);
      }
      return Left(
        ValidationFailure(
          result['message'] ?? 'Unknown error',
          result,
        ),
      );
    } on ServerException catch (e) {
      return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
    }
  }
}
