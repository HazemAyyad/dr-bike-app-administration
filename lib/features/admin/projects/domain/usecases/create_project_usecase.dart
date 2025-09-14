import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../repositories/project_repository.dart';

class CreateProjectUsecase {
  final ProjectRepository projectRepository;

  CreateProjectUsecase({required this.projectRepository});

  Future<Either<Failure, String>> call({
    required String name,
    required String projectCost,
    required String productId,
    required List<File> projectImages,
    required String partnerShare,
    required String partnerPercentage,
    required String notes,
    required String paymentMethod,
    required String paymentNote,
    required List<File> paperImages,
    String? customerId,
    String? sellerId,
  }) {
    return projectRepository.createProject(
      name: name,
      projectCost: projectCost,
      productId: productId,
      projectImages: projectImages,
      partnerShare: partnerShare,
      partnerPercentage: partnerPercentage,
      notes: notes,
      paymentMethod: paymentMethod,
      paymentNote: paymentNote,
      paperImages: paperImages,
      customerId: customerId,
      sellerId: sellerId,
    );
  }
}
