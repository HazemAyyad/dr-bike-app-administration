import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failure.dart';
import '../../data/models/project_details_model.dart';

abstract class ProjectRepository {
  Future<dynamic> getProjects({required bool isCompleted});

  Future<Either<Failure, String>> createProject({
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
  });

  Future<ProjectDetailsModel> getProjectDetails({required int projectId});
}
