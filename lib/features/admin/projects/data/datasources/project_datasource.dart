// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/project_details_model.dart';

class ProjectDataSource {
  final ApiConsumer api;

  ProjectDataSource({required this.api});

  // get projects
  Future<dynamic> getProjects({required bool isCompleted}) async {
    try {
      final response = await api.get(
        isCompleted ? EndPoints.completedProjects : EndPoints.ongoingProjects,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // create project
  Future<Map<String, dynamic>> createProject({
    required String projectName,
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
    try {
      final response = await api.post(
        EndPoints.createProject,
        data: {
          'name': projectName,
          'project_cost': projectCost,
          'products[0][product_id]': productId,
          'images[]': await Future.wait(
            projectImages.map((e) async {
              if (e.path.startsWith('http')) {
                return e.path;
              } else {
                return await MultipartFile.fromFile(
                  e.path,
                  filename: e.path.split('/').last,
                );
              }
            }),
          ),
          if (customerId != null) 'customer_id': customerId,
          if (sellerId != null) 'seller_id': sellerId,
          'share': partnerShare,
          'partnership_percentage': partnerPercentage,
          'notes': notes,
          'partnership_papers[]': await Future.wait(
            paperImages.map((e) async {
              if (e.path.startsWith('http')) {
                return e.path;
              } else {
                return await MultipartFile.fromFile(
                  e.path,
                  filename: e.path.split('/').last,
                );
              }
            }),
          ),
          'payment_method': paymentMethod,
          'payment_notes': paymentNote,
        },
        isFormData: true,
      );
      return response.data;
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }

  // get project details
  Future<ProjectDetailsModel> getProjectDetails({
    required int projectId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.showProject,
        data: {'project_id': projectId},
      );
      return ProjectDetailsModel.fromJson(response.data['project']);
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        ErrorModel(
          errorMessage: data['message'] ?? 'Unknown error',
          status: data['status'] ?? 500,
          data: data['data'] ?? {},
        ),
      );
    }
  }
}
