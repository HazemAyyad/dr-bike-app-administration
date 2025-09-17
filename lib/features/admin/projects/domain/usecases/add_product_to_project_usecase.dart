import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/project_repository.dart';

class AddProductToProjectUsecase {
  final ProjectRepository projectRepository;

  AddProductToProjectUsecase({required this.projectRepository});

  Future<Either<Failure, String>> call({
    required int projectId,
    required String productId,
  }) {
    return projectRepository.addProductToProject(
      projectId: projectId,
      productId: productId,
    );
  }
}
