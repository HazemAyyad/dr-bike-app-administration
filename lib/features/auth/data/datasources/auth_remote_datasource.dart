// ignore_for_file: depend_on_referenced_packages

import 'package:dio/dio.dart';

import '../../../../core/databases/api/api_consumer.dart';
import '../../../../core/databases/api/end_points.dart';
import '../../../../core/errors/error_model.dart';
import '../../../../core/errors/expentions.dart';

class AuthRemoteDataSource {
  final ApiConsumer api;

  AuthRemoteDataSource({required this.api});

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await api.post(
        EndPoints.register,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmPassword,
        },
      );
      // final data = response.data;

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

  Future<Map<String, dynamic>> sendOtpToEmail({
    required String email,
  }) async {
    try {
      final response = await api.post(
        EndPoints.sendCode,
        data: {'email': email},
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

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await api.post(
        EndPoints.verifyCode,
        data: {'email': email, 'otp_code': otpCode},
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

  Future<dynamic> login({
    required String email,
    required String password,
    required String fcmToken,
  }) async {
    try {
      final response = await api.post(
        EndPoints.login,
        data: {
          'email': email,
          'password': password,
          'fcm_token': fcmToken,
        },
      );
      return response;
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

  Future<dynamic> logout({required String token}) async {
    try {
      final response = await api.post(
        EndPoints.logout,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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

  // Future<dynamic> requesToChangePassword({required String email}) async {
  //   try {
  //     final response = await api.post(
  //       EndPoints.forgetPassword,
  //       data: {'email': email},
  //     );
  //     if ((response.statusCode == 200 || response.statusCode == 201) &&
  //             response.data['status'] == 'true' ||
  //         response.data['status'] == true) {
  //       return response.data;
  //     } else {
  //       return response.data;
  //     }
  //   } on dio.DioException catch (e) {
  //     if (e.response != null && e.response?.data != null) {
  //       return e.response?.data['message'].toString();
  //     } else {
  //       return false;
  //     }
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // Future<dynamic> verifyChangePassword({
  //   required String email,
  //   required String otpCode,
  // }) async {
  //   try {
  //     final response = await api.post(
  //       EndPoints.verifyForgetPasswordToken,
  //       data: {'email': email, 'otp_code': otpCode},
  //     );

  //     if ((response.statusCode == 200 || response.statusCode == 201) &&
  //             response.data['status'] == 'true' ||
  //         response.data['status'] == true) {
  //       return response.data;
  //     } else {
  //       return response.data;
  //     }
  //   } catch (e) {
  //     return false;
  //   }
  // }

  // Future<Either<Failure, String>> setNewPassword(
  //     {required String email, required String newPassword}) async {
  //   try {
  //     final response = await api.post(
  //       EndPoints.forgetPasswordApi,
  //       // options: dio.Options(headers: {'Authorization': 'Bearer $token'}),
  //       data: {
  //         'email': email,
  //         'new_password': newPassword,
  //         'new_password_confirmation': newPassword,
  //       },
  //     );
  //     if ((response.statusCode == 200 || response.statusCode == 201) &&
  //             response.data['status'] == 'true' ||
  //         response.data['status'] == true) {
  //       return right(response.data['message']);
  //     } else {
  //       return left(Failure(errMessage: response.data['message']));
  //     }
  //   } on Exception catch (e) {
  //     return left(Failure(errMessage: e.toString()));
  //   }
  // }

  // Future<dynamic> getCities() async {
  //   try {
  //     final response = await api.get(EndPoints.cities);
  //     if ((response.statusCode == 200 || response.statusCode == 201) &&
  //             response.data['status'] == 'true' ||
  //         response.data['status'] == true) {
  //       final response1 = CitiesResponseModel.fromJson(response.data);
  //       return response1;
  //     } else {
  //       return response.data['message'];
  //     }
  //   } on dio.DioException catch (e) {
  //     return handleDioException(e);
  //   }
  // }

  // // get all Areas
  // Future getAreas() async {
  //   try {
  //     final response = await api.get(EndPoints.areas);
  //     if ((response.statusCode == 200 || response.statusCode == 201) &&
  //             response.data['status'] == 'true' ||
  //         response.data['status'] == true) {
  //       final response1 = AreasResponse.fromJson(response.data);
  //       return response1;
  //     } else {
  //       return response.data['message'];
  //     }
  //   } on dio.DioException catch (e) {
  //     return handleDioException(e);
  //   }
  // }

  Future<dynamic> changePassword({
    required String token,
    required String oldPassword,
    required String password,
    required String confirmPassword,
  }) async {
    try {
      final response = await api.post(
        EndPoints.changePassword,
        data: {
          'old_password': oldPassword,
          'password': password,
          'password_confirmation': confirmPassword,
        },
        options: Options(headers: {'Authorization': 'Bearer $token'}),
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
