import 'package:dartz/dartz.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class AddEmployeeUsecase {
  final EmployeeRepository employeeRepository;

  AddEmployeeUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    String? employeeId,
    required String name,
    required String email,
    required String phone,
    required String subPhone,
    required String password,
    required String passwordConfirmation,
    required String hourWorkPrice,
    required String overtimeWorkPrice,
    required String numberOfWorkHours,
    required String startWorkTime,
    required XFile? documentImg,
    required XFile? employeeImg,
    required List<String> permissions,
  }) {
    return employeeRepository.creatEmployee(
      employeeId: employeeId,
      name: name,
      email: email,
      phone: phone,
      subPhone: subPhone,
      password: password,
      passwordConfirmation: passwordConfirmation,
      hourWorkPrice: hourWorkPrice,
      overtimeWorkPrice: overtimeWorkPrice,
      numberOfWorkHours: numberOfWorkHours,
      startWorkTime: startWorkTime,
      documentImg: documentImg,
      employeeImg: employeeImg,
      permissions: permissions,
    );
  }
}
