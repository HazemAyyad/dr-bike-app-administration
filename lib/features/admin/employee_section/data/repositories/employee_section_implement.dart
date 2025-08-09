// import 'package:dartz/dartz.dart';

// import '../../../../../core/connection/network_info.dart';
// import '../../../../../core/errors/expentions.dart';
// import '../../../../../core/errors/failure.dart';
// import '../../domain/repositories/admin_repository.dart';
// import '../datasources/admin_remote_datasource.dart';

// class Implement implements AdminRepository {
//   final NetworkInfo networkInfo;
//   final RemoteDataSource RemoteDataSource;

//   Implement(
//       {required this.networkInfo, required this.RemoteDataSource});

//   @override
//   Future<Either<Failure, bool>> creatSpecialTasks({
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
//     if (!await networkInfo.isConnected) {
//       return Left(NoConnectionFailure());
//     }
//     try {
//       final result = await adminRemoteDataSource.creatSpecialTasks(
//         token: token,
//         name: name,
//         description: description,
//         notes: notes,
//         points: points,
//         startDate: startDate,
//         endDate: endDate,
//         notShownForEmployee: notShownForEmployee,
//         taskRecurrence: taskRecurrence,
//         taskRecurrenceTime: taskRecurrenceTime,
//         subSpecialTaskName: subSpecialTaskName,
//         subSpecialTaskDescription: subSpecialTaskDescription,
//       );
//       if (result['status'] == 'success') {
//         return Right(true);
//       }
//       return Left(
//         ValidationFailure(
//           result['message'] ?? 'Unknown error',
//           result,
//         ),
//       );
//     } on ServerException catch (e) {
//       return Left(ServerFailure(e.errorModel.errorMessage, e.errorModel.data));
//     }
//   }
// }
