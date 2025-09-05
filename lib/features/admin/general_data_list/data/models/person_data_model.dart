import 'dart:io';

import 'package:doctorbike/core/helpers/show_net_image.dart';
import 'package:doctorbike/features/admin/general_data_list/domain/entity/add_person_entity.dart';

class PersonDataModel extends AddPersonEntity {
  const PersonDataModel({
    required int id,
    bool? isEdit,
    required String personType,
    required String name,
    required String address,
    required String phone,
    required String subPhone,
    required String jobTitle,
    required String facebookUsername,
    required String facebookLink,
    required String instagramUsername,
    required String instagramLink,
    required String relatedPeople,
    required String relativePhone,
    required String relativeJobTitle,
    required String workAddress,
    required List<File> iDImage,
    required List<File> licenseImage,
  }) : super(
          id: id,
          isEdit: isEdit ?? false,
          personType: personType,
          name: name,
          phone: phone,
          subPhone: subPhone,
          address: address,
          jobTitle: jobTitle,
          facebookUsername: facebookUsername,
          facebookLink: facebookLink,
          instagramUsername: instagramUsername,
          instagramLink: instagramLink,
          relatedPeople: relatedPeople,
          relativePhone: relativePhone,
          relativeJobTitle: relativeJobTitle,
          workAddress: workAddress,
          iDImage: iDImage,
          licenseImage: licenseImage,
        );

  factory PersonDataModel.fromJson(Map<String, dynamic> json) {
    return PersonDataModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'] ?? '',
      subPhone: json['sub_phone'] ?? '',
      jobTitle: json['job_title'] ?? '',
      personType: json['type'] ?? '',
      facebookUsername: json['facebook_username'] ?? '',
      facebookLink: json['facebook_link'] ?? '',
      instagramUsername: json['instagram_username'] ?? '',
      instagramLink: json['instagram_link'] ?? '',
      relatedPeople: json['related_people'] ?? '',
      relativePhone: json['relative_phone'] ?? '',
      relativeJobTitle: json['relative_job_title'] ?? '',
      workAddress: json['work_address'] ?? '',
      iDImage: (json['ID_image'] as List<dynamic>?)
              ?.map((e) => File(ShowNetImage.getPhoto(e)))
              .toList() ??
          [],
      licenseImage: (json['license_image'] as List<dynamic>?)
              ?.map((e) => File(ShowNetImage.getPhoto(e)))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'person_type': personType,
      'name': name,
      'address': address,
      'phone': phone,
      'sub_phone': subPhone,
      'job_title': jobTitle,
      'facebook_username': facebookUsername,
      'facebook_link': facebookLink,
      'instagram_username': instagramUsername,
      'instagram_link': instagramLink,
      'related_people': relatedPeople,
      'relative_phone': relativePhone,
      'relative_job_title': relativeJobTitle,
      'work_address': workAddress,
      'id_image': iDImage,
      'license_image': licenseImage,
    };
  }
}
