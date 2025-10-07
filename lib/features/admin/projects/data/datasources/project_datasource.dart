// ignore_for_file: depend_on_referenced_packages

import 'dart:io';

import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../models/project_details_model.dart';

class ProjectDatasource {
  final ApiConsumer api;

  ProjectDatasource({required this.api});

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
    required String projectId,
    required String projectName,
    required String projectCost,
    required List<ProjectProductModel> productId,
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
      print('customerId: $customerId');
      final productIdList = <String, dynamic>{};

      for (int i = 0; i < productId.length; i++) {
        productIdList['products[$i][product_id]'] = productId[i].productId;
      }
      final response = await api.post(
        projectId.isNotEmpty ? EndPoints.editProject : EndPoints.createProject,
        data: {
          if (projectId.isNotEmpty) 'project_id': projectId,
          'name': projectName,
          'project_cost': projectCost,
          ...productIdList,
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
      print('response: $response');
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

  // add product to project
  Future<Map<String, dynamic>> addProductToProject({
    required int projectId,
    required String productId,
  }) async {
    try {
      final response = await api.post(
        productId.isEmpty
            ? EndPoints.completeProject
            : EndPoints.addProductToProject,
        data: {
          'project_id': projectId,
          if (productId.isNotEmpty) 'product_id': productId
        },
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

  // get project expenses and sales
  Future<dynamic> getProjectExpensesAndSales({
    required bool isSales,
    required String projectId,
    required String expenses,
    required String notes,
  }) async {
    try {
      final response = await api.post(
        isSales
            ? EndPoints.projectSales
            : expenses.isEmpty
                ? EndPoints.getProjectExpenses
                : EndPoints.addProjectExpense,
        data: {
          'project_id': projectId,
          if (expenses.isNotEmpty) 'expenses': expenses,
          if (notes.isNotEmpty) 'notes': notes,
        },
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
}
