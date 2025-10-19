import 'dart:io';

class AddPersonEntity {
  final int? id;
  final bool? isEdit;
  final String personType;
  final String name;
  final String address;
  final String phone;
  final String subPhone;
  final String jobTitle;
  final String facebookUsername;
  final String facebookLink;
  final String instagramUsername;
  final String instagramLink;
  final String relatedPeople;
  final String relativePhone;
  final String relativeJobTitle;
  final String workAddress;
  final List<File> iDImage;
  final List<File> licenseImage;

  const AddPersonEntity({
    this.id,
    this.isEdit,
    required this.personType,
    required this.name,
    required this.phone,
    required this.subPhone,
    required this.address,
    required this.jobTitle,
    required this.facebookUsername,
    required this.facebookLink,
    required this.instagramUsername,
    required this.instagramLink,
    required this.relatedPeople,
    required this.relativePhone,
    required this.relativeJobTitle,
    required this.workAddress,
    required this.iDImage,
    required this.licenseImage,
  });
}
