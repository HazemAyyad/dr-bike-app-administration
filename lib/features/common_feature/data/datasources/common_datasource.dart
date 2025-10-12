import 'package:dio/dio.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import '../../../../core/errors/error_model.dart';
import '../../../../core/errors/expentions.dart';
import '../../../../core/services/initial_bindings.dart';
import '../../../../core/services/user_data.dart';
import '../../../auth/data/models/user_model.dart';

class CommonDatasource {
  final ApiConsumer api;

  CommonDatasource({required this.api});

  Future<Map<String, dynamic>> userProfile({
    required String name,
    required String phone,
    required String subPhone,
    required String city,
    required String address,
  }) async {
    try {
      final response = await api.post(
        EndPoints.updateProfile,
        data: {
          'name': name,
          'phone': phone,
          'sub_phone': subPhone,
          'city': city,
          'address': address,
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

  // get user Data
  Future<UserModel> getUserData() async {
    try {
      final response = await api.post(EndPoints.me);
      final user = UserModel.fromJson(response.data);
      await UserData.saveUser(user);
      final userdata = await UserData.getSavedUser();
      if (userdata != null) {
        final permissionIds =
            userdata.employeePermissions.map((p) => p.permissionId).toList();
        employeePermissions.addAll(permissionIds);
        userType = userdata.user.type;
      }
      return user;
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
