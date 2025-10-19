import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/person_data_model.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../../domain/entity/add_person_entity.dart';
import '../models/employee_data_model.dart';

class GeneralDataListDatasource {
  final ApiConsumer api;

  GeneralDataListDatasource({required this.api});

  Future<List<GeneralDataModel>> getGeneralList({required int tab}) async {
    try {
      final response = await api.get(
        tab == 0
            ? EndPoints.mainPageSellers
            : tab == 1
                ? EndPoints.mainPageCustomers
                : EndPoints.mainPageInComplete,
      );
      List<GeneralDataModel> generalDataList = (response.data['data'] as List)
          .map((e) => GeneralDataModel.fromJson(e))
          .toList();
      return generalDataList;
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

  // add person
  Future<dynamic> addPerson({
    required AddPersonEntity data,
    required String customerId,
    required String sellerId,
  }) async {
    try {
      Map<String, dynamic> iDImage = {};
      iDImage['ID_image[]'] = await Future.wait(
        data.iDImage.map((e) async {
          if (e.path.startsWith('http')) {
            return e.path.split('http://doctorbike.mj-sall.com/').last;
          } else {
            final compressedImg = await compressImage(XFile(e.path));
            // لو ملف جديد → Multipart
            return await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }
        }),
      );

      Map<String, dynamic> licenseImage = {};
      licenseImage['license_image[]'] = await Future.wait(
        data.licenseImage.map((e) async {
          if (e.path.startsWith('http')) {
            return e.path.split('http://doctorbike.mj-sall.com/').last;
          } else {
            final compressedImg = await compressImage(XFile(e.path));
            return await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path
                  .split('http://doctorbike.mj-sall.com/')
                  .last,
            );
          }
        }),
      );

      final response = await api.post(
        data.isEdit! ? EndPoints.editPerson : EndPoints.createPerson,
        data: {
          if (customerId.isNotEmpty) 'customer_id': customerId,
          if (sellerId.isNotEmpty) 'seller_id': sellerId,
          if (!data.isEdit!) 'person_type': data.personType,
          'type': data.personType,
          'name': data.name,
          'address': data.address,
          'phone': data.phone,
          'sub_phone': data.subPhone,
          'job_title': data.jobTitle,
          'facebook_username': data.facebookUsername,
          'facebook_link': data.facebookLink,
          'instagram_username': data.instagramUsername,
          'instagram_link': data.instagramLink,
          'related_people': data.relatedPeople,
          'relative_phone': data.relativePhone,
          'relative_job_title': data.relativeJobTitle,
          'work_address': data.workAddress,
          ...iDImage,
          ...licenseImage,
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

  // get person data
  Future<PersonDataModel> getPersonData({
    required String customerId,
    required String sellerId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.showPerson,
        data: {
          'customer_id': customerId,
          'seller_id': sellerId,
        },
      );
      return PersonDataModel.fromJson(response.data['person_details']);
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

  // delete person
  Future<dynamic> deletePerson({
    required String customerId,
    required String sellerId,
  }) async {
    try {
      final response = await api.post(
        EndPoints.deletePerson,
        data: {
          'customer_id': customerId,
          'seller_id': sellerId,
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
