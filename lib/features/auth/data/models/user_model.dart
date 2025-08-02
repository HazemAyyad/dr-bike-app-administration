import '../../../../core/databases/api/end_points.dart';

// class LoginResponseModel {
//   final String status;
//   final UserModel user;
//   final String token;

//   LoginResponseModel({
//     required this.status,
//     required this.user,
//     required this.token,
//   });

//   factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
//     return LoginResponseModel(
//       status: json[ApiKey.status],
//       user: UserModel.fromJson(json[ApiKey.user]),
//       token: json[ApiKey.token],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       ApiKey.status: status,
//       ApiKey.user: user.toJson(),
//       ApiKey.token: token,
//     };
//   }
// }

class UserModel {
  final int id;
  final String name;
  final String email;
  final String? emailVerifiedAt;
  final String phone;
  final String subPhone;
  final String city;
  final String address;
  final String createdAt;
  final String updatedAt;
  final String type;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.emailVerifiedAt,
    required this.phone,
    required this.subPhone,
    required this.city,
    required this.address,
    required this.createdAt,
    required this.updatedAt,
    required this.type,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json[ApiKey.id] ?? 0,
      name: json[ApiKey.name] ?? '',
      email: json[ApiKey.email] ?? '',
      emailVerifiedAt: json[ApiKey.email_verified_at] ?? '',
      phone: json[ApiKey.phone] ?? '',
      subPhone: json[ApiKey.sub_phone] ?? '',
      city: json[ApiKey.city] ?? '',
      address: json[ApiKey.address] ?? '',
      createdAt: json[ApiKey.created_at] ?? '',
      updatedAt: json[ApiKey.updated_at] ?? '',
      type: json[ApiKey.type] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.name: name,
      ApiKey.email: email,
      ApiKey.email_verified_at: emailVerifiedAt,
      ApiKey.phone: phone,
      ApiKey.sub_phone: subPhone,
      ApiKey.city: city,
      ApiKey.address: address,
      ApiKey.created_at: createdAt,
      ApiKey.updated_at: updatedAt,
      ApiKey.type: type,
    };
  }
}
