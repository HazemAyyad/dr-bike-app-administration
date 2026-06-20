import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';
import '../../data/models/admin_user_model.dart';

class GetAdminUsersUsecase {
  final EmployeeRepository employeeRepository;

  GetAdminUsersUsecase({required this.employeeRepository});

  Future<List<AdminUserModel>> call({String? search}) {
    return employeeRepository.getAdminUsers(search: search);
  }
}

class ManageAdminUserUsecase {
  final EmployeeRepository employeeRepository;

  ManageAdminUserUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> create({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
  }) {
    return employeeRepository.createAdminUser(
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  Future<Either<Failure, String>> update({
    required String adminId,
    required String name,
    required String email,
    String? phone,
    String? password,
    String? passwordConfirmation,
  }) {
    return employeeRepository.updateAdminUser(
      adminId: adminId,
      name: name,
      email: email,
      phone: phone,
      password: password,
      passwordConfirmation: passwordConfirmation,
    );
  }

  Future<Either<Failure, String>> delete({required String adminId}) {
    return employeeRepository.deleteAdminUser(adminId: adminId);
  }

  Future<Either<Failure, String>> toggleBlock({required String adminId}) {
    return employeeRepository.toggleBlockAdminUser(adminId: adminId);
  }
}
