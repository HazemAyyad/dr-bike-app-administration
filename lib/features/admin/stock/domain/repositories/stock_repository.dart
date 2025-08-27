abstract class StockRepository {
  Future<dynamic> getAllStock({required int page});
  // Future<Either<Failure, bool>> creatProduct({
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
