import '../repositories/project_repository.dart';

class GetProjectDetailsUsecase {
  final ProjectRepository projectRepository;

  GetProjectDetailsUsecase({required this.projectRepository});

  Future<dynamic> call({required int projectId}) {
    return projectRepository.getProjectDetails(projectId: projectId);
  }
}
