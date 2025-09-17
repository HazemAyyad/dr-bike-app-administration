import 'package:dio/dio.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/databases/api/end_points.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';

class MaintenanceDatasource {
  final ApiConsumer api;

  MaintenanceDatasource({required this.api});

  Future<dynamic> getMaintenances({required int tab}) async {
    try {
      final response = await api.get(
        tab == 0
            ? EndPoints.getNewMaintenances
            : tab == 1
                ? EndPoints.getOngoingMaintenances
                : tab == 2
                    ? EndPoints.getReadyMaintenances
                    : EndPoints.getDeliveredMaintenances,
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

  // // add person
  // Future<dynamic> addPerson({
  //   required AddPersonEntity data,
  //   required String customerId,
  //   required String sellerId,
  // }) async {
  //   try {
  //     Map<String, dynamic> iDImage = {};
  //     iDImage['ID_image[]'] = await Future.wait(
  //       data.iDImage.map((e) async {
  //         if (e.path.startsWith('http')) {
  //           return e.path.split('http://doctorbike.mj-sall.com/').last;
  //         } else {
  //           // لو ملف جديد → Multipart
  //           return await MultipartFile.fromFile(
  //             e.path,
  //             filename: e.path.split('/').last,
  //           );
  //         }
  //       }),
  //     );

  //     Map<String, dynamic> licenseImage = {};
  //     licenseImage['license_image[]'] = await Future.wait(
  //       data.licenseImage.map((e) async {
  //         if (e.path.startsWith('http')) {
  //           return e.path.split('http://doctorbike.mj-sall.com/').last;
  //         } else {
  //           return await MultipartFile.fromFile(
  //             e.path,
  //             filename: e.path.split('http://doctorbike.mj-sall.com/').last,
  //           );
  //         }
  //       }),
  //     );

  //     final response = await api.post(
  //       data.isEdit! ? EndPoints.editPerson : EndPoints.createPerson,
  //       data: {
  //         if (customerId.isNotEmpty) 'customer_id': customerId,
  //         if (sellerId.isNotEmpty) 'seller_id': sellerId,
  //         if (!data.isEdit!) 'person_type': data.personType,
  //         'type': data.personType,
  //         'name': data.name,
  //         'address': data.address,
  //         'phone': data.phone,
  //         'sub_phone': data.subPhone,
  //         'job_title': data.jobTitle,
  //         'facebook_username': data.facebookUsername,
  //         'facebook_link': data.facebookLink,
  //         'instagram_username': data.instagramUsername,
  //         'instagram_link': data.instagramLink,
  //         'related_people': data.relatedPeople,
  //         'relative_phone': data.relativePhone,
  //         'relative_job_title': data.relativeJobTitle,
  //         'work_address': data.workAddress,
  //         ...iDImage,
  //         ...licenseImage,
  //       },
  //       isFormData: true,
  //     );
  //     return response.data;
  //   } on DioException catch (e) {
  //     final data = e.response?.data;
  //     throw ServerException(
  //       ErrorModel(
  //         errorMessage: data['message'] ?? 'Unknown error',
  //         status: data['status'] ?? 500,
  //         data: data['data'] ?? {},
  //       ),
  //     );
  //   }
  // }

  // // get person data
  // Future<PersonDataModel> getPersonData({
  //   required String customerId,
  //   required String sellerId,
  // }) async {
  //   try {
  //     final response = await api.post(EndPoints.showPerson,
  //         data: {'customer_id': customerId, 'seller_id': sellerId});
  //     return PersonDataModel.fromJson(response.data['person_details']);
  //   } on DioException catch (e) {
  //     final data = e.response?.data;
  //     throw ServerException(
  //       ErrorModel(
  //         errorMessage: data['message'] ?? 'Unknown error',
  //         status: data['status'] ?? 500,
  //         data: data['data'] ?? {},
  //       ),
  //     );
  //   }
  // }
}
