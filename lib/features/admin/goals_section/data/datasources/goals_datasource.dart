import 'package:dio/dio.dart';
import 'package:doctorbike/features/admin/goals_section/data/models/goals_model.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../projects/data/models/project_details_model.dart';

class GoalsDatasource {
  final ApiConsumer api;

  GoalsDatasource({required this.api});

  Future<List<GoalsModel>> getAllGoals() async {
    try {
      final response = await api.get(EndPoints.getAllGoals);
      final List<GoalsModel> goals = (response.data['goals'] as List)
          .map((goal) => GoalsModel.fromJson(goal))
          .toList();
      return goals;
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

  // add Goal
  Future<Map<String, dynamic>> addGoal({
    String? goalId,
    required String name,
    required String type,
    required String form,
    required String targetedValue,
    required String currentValue,
    required String notes,
    required String scope,
    required String customerId,
    required String employeeId,
    required String sellerId,
    required String boxId,
    required List<ProjectProductModel> productsIds,
    required String mainCategoriesId,
    required String subCategoriesId,
    required DateTime dueDate,
  }) async {
    final Map<String, dynamic> productsList = {};

    for (var i = 0; i < productsIds.length; i++) {
      if (productsIds[i].productId.isNotEmpty) {
        productsList['products[$i][product_id]'] = productsIds[i].productId;
      }
    }

    try {
      final response = await api.post(
        goalId != null && goalId != '' && goalId.isNotEmpty
            ? EndPoints.editGoal
            : EndPoints.addGoal,
        data: {
          if (goalId != null) 'goal_id': goalId,
          'name': name,
          'type': type,
          'form': form,
          'targeted_value': targetedValue,
          if (currentValue.isNotEmpty) 'current_value': currentValue,
          'notes': notes,
          'scope': scope,
          if (customerId.isNotEmpty) 'people[0][customer_id]': customerId,
          // if (employeeId.isNotEmpty && type != 'finish_tasks')
          //   'people[0][employee_id]': employeeId,
          if (sellerId.isNotEmpty) 'people[0][seller_id]': sellerId,
          if (boxId.isNotEmpty) 'box_id': boxId,
          ...productsList,
          if (mainCategoriesId.isNotEmpty)
            'main_categories[0][main_category_id]': mainCategoriesId,
          if (subCategoriesId.isNotEmpty)
            'sub_categories[0][sub_category_id]': subCategoriesId,
          if (employeeId.isNotEmpty) 'employee_id': employeeId,
          'due_date': dueDate,
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

  // get goal details
  Future<dynamic> getGoalDetails({
    required String goalId,
    bool? isCancel,
    bool? isTransfer,
    bool? isDelete,
  }) async {
    try {
      final response = await api.post(
          isCancel != null
              ? EndPoints.cancelGoal
              : isTransfer != null
                  ? EndPoints.transferGoal
                  : isDelete != null
                      ? EndPoints.deleteGoal
                      : EndPoints.showGoal,
          data: {'goal_id': goalId});
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
