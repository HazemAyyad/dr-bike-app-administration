import 'dart:io';

import 'package:doctorbike/core/helpers/json_safe_parser.dart';
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
    final j = Map<String, dynamic>.from(json);
    List<File> mapUrlList(dynamic raw) {
      if (raw is! List) return [];
      return raw
          .map((e) => File(ShowNetImage.getPhoto(asNullableString(e))))
          .toList();
    }

    return PersonDataModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      address: asString(j['address']),
      phone: asString(j['phone']),
      subPhone: asString(j['sub_phone']),
      jobTitle: asString(j['job_title']),
      personType: asString(j['type']),
      facebookUsername: asString(j['facebook_username']),
      facebookLink: asString(j['facebook_link']),
      instagramUsername: asString(j['instagram_username']),
      instagramLink: asString(j['instagram_link']),
      relatedPeople: asString(j['related_people']),
      relativePhone: asString(j['relative_phone']),
      relativeJobTitle: asString(j['relative_job_title']),
      workAddress: asString(j['work_address']),
      iDImage: mapUrlList(j['ID_image']),
      licenseImage: mapUrlList(j['license_image']),
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
