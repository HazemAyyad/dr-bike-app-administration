abstract class MaintenanceRepository {
  Future<dynamic> getMaintenances({required int tab});
  // Future<Either<Failure, bool>> creatSpecialTasks({
  //   required String token,
  //   required String name,
  //   required String description,
  //   required String notes,
  //   required String points,
  //   required String startDate,
  //   required String endDate,
  //   required String notShownForEmployee,
  //   required String taskRecurrence,
  //   required String taskRecurrenceTime,
  //   required String subSpecialTaskName,
  //   required String subSpecialTaskDescription,
  // });
}
