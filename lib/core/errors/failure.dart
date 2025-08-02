import 'package:get/get.dart';

abstract class Failure {
  final String errMessage;
  final dynamic data;
  Failure(this.errMessage, {this.data});

  @override
  String toString() => errMessage;
}

class NoConnectionFailure extends Failure {
  NoConnectionFailure() : super('noInternetConnection'.tr);
}

class ServerFailure extends Failure {
  ServerFailure(String errorMessage, dynamic data)
      : super(errorMessage, data: data);
}

class UnexpectedFailure extends Failure {
  UnexpectedFailure() : super('makeSureTheDataIsCorrect'.tr);
}

class ValidationFailure extends Failure {
  ValidationFailure(String errorMessage, dynamic data)
      : super(errorMessage, data: data);
}
