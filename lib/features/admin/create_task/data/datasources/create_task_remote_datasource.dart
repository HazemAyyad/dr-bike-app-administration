// // ignore_for_file: depend_on_referenced_packages

// import 'package:dio/dio.dart';

// import '../../../../../core/databases/api/api_consumer.dart';
// import '../../../../../core/databases/api/end_points.dart';
// import '../../../../../core/errors/error_model.dart';
// import '../../../../../core/errors/expentions.dart';

// class RemoteDataSource {
//   final ApiConsumer api;

//   RemoteDataSource({required this.api});

//   Future<Map<String, dynamic>> creatSpecialTasks({
//     required String token,
//     required String name,
//     required String description,
//     required String notes,
//     required String points,
//     required String startDate,
//     required String endDate,
//     required String notShownForEmployee,
//     required String taskRecurrence,
//     required String taskRecurrenceTime,
//     required String subSpecialTaskName,
//     required String subSpecialTaskDescription,
//   }) async {
//     try {
//       final response = await api.post(
//         EndPoints.createSpecialTask,
//         data: {
//           'name': name,
//           'description': description,
//           'notes': notes,
//           'points': points,
//           'start_date': startDate,
//           'end_date': endDate,
//           'not_shown_for_employee': notShownForEmployee,
//           'task_recurrence': taskRecurrence,
//           'task_recurrence_time': taskRecurrenceTime,
//           'sub_special_task_name': subSpecialTaskName,
//           'sub_special_task_description': subSpecialTaskDescription,
//         },
//         options: Options(headers: {'Authorization': 'Bearer $token'}),
//       );
//       // final data = response.data;
//       print('Response data: $response');
//       return response.data;
//     } on DioException catch (e) {
//       final data = e.response?.data;
//       throw ServerException(
//         ErrorModel(
//           errorMessage: data['message'] ?? 'Unknown error',
//           status: data['status'] ?? 500,
//           data: data['data'] ?? {},
//         ),
//       );
//     }
//   }
// }
