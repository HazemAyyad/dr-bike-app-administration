import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/employee_section_repository.dart';

class UpdatePermissionGrantPolicyUsecase {
  final EmployeeRepository employeeRepository;

  UpdatePermissionGrantPolicyUsecase({required this.employeeRepository});

  Future<Either<Failure, String>> call({
    required int permissionId,
    required String grantPolicy,
    required bool applyToGroup,
  }) {
    return employeeRepository.updatePermissionGrantPolicy(
      permissionId: permissionId,
      grantPolicy: grantPolicy,
      applyToGroup: applyToGroup,
    );
  }
}
