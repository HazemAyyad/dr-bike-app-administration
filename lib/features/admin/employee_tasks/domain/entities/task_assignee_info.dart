class TaskAssigneeInfo {
  final int id;
  final String name;
  final String photoUrl;

  const TaskAssigneeInfo({
    required this.id,
    required this.name,
    this.photoUrl = '',
  });
}
