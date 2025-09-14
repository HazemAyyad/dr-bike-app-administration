import '../repositories/project_repository.dart';

class GetProjectsUsecase {
  final ProjectRepository projectRepository;

  GetProjectsUsecase({required this.projectRepository});

  Future<dynamic> call({required bool isCompleted}) {
    return projectRepository.getProjects(isCompleted: isCompleted);
  }
}
