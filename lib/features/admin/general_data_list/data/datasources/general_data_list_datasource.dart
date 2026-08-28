import 'package:dio/dio.dart';
import 'package:doctorbike/core/databases/api/end_points.dart';
import 'package:doctorbike/features/admin/general_data_list/data/models/person_data_model.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/databases/api/api_consumer.dart';
import '../../../../../core/errors/error_model.dart';
import '../../../../../core/errors/expentions.dart';
import '../../../checks/data/datasources/checks_datasource.dart';
import '../../../debts/data/models/debt_ledger_models.dart';
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
      final endpoint = tab == 0
          ? EndPoints.mainPageSellers
          : tab == 1
              ? EndPoints.mainPageCustomers
              : EndPoints.mainPageInComplete;
      final rawPeople = response.data['data'] as List;
      if (kDebugMode) {
        final summary = rawPeople.map((person) {
          final map = person as Map<String, dynamic>;
          return '${map['id']}:${map['type']}:${map['is_canceled']}';
        }).join(', ');
        debugPrint(
          '[PERSON_LIST] endpoint=$endpoint count=${rawPeople.length} '
          'people=[$summary]',
        );
      }
      List<GeneralDataModel> generalDataList =
          rawPeople.map((e) => GeneralDataModel.fromJson(e)).toList();
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
      final formFields = <String, dynamic>{
        if (customerId.isNotEmpty) 'customer_id': customerId,
        if (sellerId.isNotEmpty) 'seller_id': sellerId,
        if (!data.isEdit!) 'person_type': data.personType,
        'type': data.customerCategory,
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
      };

      if (data.contactCategoryIds.isNotEmpty) {
        formFields['contact_category_ids[]'] = data.contactCategoryIds;
      }

      if (data.iDImage.isNotEmpty) {
        formFields['ID_image[]'] = await Future.wait(
          data.iDImage.map((e) async {
            if (e.path.startsWith('http')) {
              return e.path.split('http://doctorbike.mj-sall.com/').last;
            }
            final compressedImg = await compressImage(XFile(e.path));
            return await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }),
        );
      }

      if (data.licenseImage.isNotEmpty) {
        formFields['license_image[]'] = await Future.wait(
          data.licenseImage.map((e) async {
            if (e.path.startsWith('http')) {
              return e.path.split('http://doctorbike.mj-sall.com/').last;
            }
            final compressedImg = await compressImage(XFile(e.path));
            return await MultipartFile.fromFile(
              compressedImg.path,
              filename: compressedImg.path.split('/').last,
            );
          }),
        );
      }

      if (kDebugMode) {
        debugPrint(
            '[PERSON_EDIT] endpoint=${data.isEdit! ? EndPoints.editPerson : EndPoints.createPerson}');
        debugPrint(
          '[PERSON_EDIT] isEdit=${data.isEdit} customerId=$customerId '
          'sellerId=$sellerId personType=${data.personType} '
          'category=${data.customerCategory}',
        );
        debugPrint(
          '[PERSON_EDIT] request customer_id=${formFields['customer_id']} '
          'seller_id=${formFields['seller_id']} type=${formFields['type']} '
          'name=${formFields['name']}',
        );
      }

      final response = await api.post(
        data.isEdit! ? EndPoints.editPerson : EndPoints.createPerson,
        data: formFields,
        isFormData: true,
      );
      if (kDebugMode) {
        debugPrint('[PERSON_EDIT] response=${response.data}');
      }
      return response.data;
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[PERSON_EDIT] DioException status=${e.response?.statusCode} '
          'response=${e.response?.data} message=${e.message}',
        );
      }
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

  Future<List<ContactCategory>> getContactCategories() async {
    try {
      final response = await api.get(EndPoints.contactCategories);
      return (response.data['categories'] as List<dynamic>? ?? [])
          .map((e) => ContactCategory.fromJson(e as Map<String, dynamic>))
          .toList();
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
