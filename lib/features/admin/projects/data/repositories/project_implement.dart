import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:doctorbike/features/admin/projects/data/models/project_details_model.dart';

import '../../../../../core/connection/network_info.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../../../core/errors/failure.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_datasource.dart';

class ProjectImplement implements ProjectRepository {
  final NetworkInfo networkInfo;
  final ProjectDataSource projectDataSource;

  ProjectImplement({
    required this.networkInfo,
    required this.projectDataSource,
  });

  // get projects
  @override
  Future<dynamic> getProjects({required bool isCompleted}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await projectDataSource.getProjects(isCompleted: isCompleted);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }

  // create project
  @override
  Future<Either<Failure, String>> createProject({
    required String name,
    required String projectCost,
    required String productId,
    required List<File> projectImages,
    required String partnerShare,
    required String partnerPercentage,
    required String notes,
    required String paymentMethod,
    required String paymentNote,
    required List<File> paperImages,
    String? customerId,
    String? sellerId,
  }) async {
    if (!await networkInfo.isConnected) {
      return Left(NoConnectionFailure());
    }
    try {
      final result = await projectDataSource.createProject(
        projectName: name,
        projectCost: projectCost,
        productId: productId,
        projectImages: projectImages,
        partnerShare: partnerShare,
        partnerPercentage: partnerPercentage,
        notes: notes,
        paymentMethod: paymentMethod,
        paymentNote: paymentNote,
        paperImages: paperImages,
        customerId: customerId,
        sellerId: sellerId,
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

  @override
  Future<ProjectDetailsModel> getProjectDetails(
      {required int projectId}) async {
    if (!await networkInfo.isConnected) {
      throw NoConnectionFailure();
    }
    try {
      final result =
          await projectDataSource.getProjectDetails(projectId: projectId);
      return result;
    } on ServerException catch (e) {
      throw ServerFailure(e.errorModel.errorMessage, e.errorModel.data);
    }
  }
}
