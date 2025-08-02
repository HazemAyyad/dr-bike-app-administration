import 'package:dio/dio.dart';

import 'error_model.dart';

//!ServerException
class ServerException implements Exception {
  final ErrorModel errorModel;
  ServerException(this.errorModel);
}

//!CacheExeption
class CacheExeption implements Exception {
  final String errorMessage;
  CacheExeption({required this.errorMessage});
}

class BadCertificateException extends ServerException {
  BadCertificateException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'BadCertificateException: ${errorModel.errorMessage}';
}

class ConnectionTimeoutException extends ServerException {
  ConnectionTimeoutException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'ConnectionTimeoutException: ${errorModel.errorMessage}';
}

class BadResponseException extends ServerException {
  BadResponseException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'BadResponseException: ${errorModel.errorMessage}';
}

class ReceiveTimeoutException extends ServerException {
  ReceiveTimeoutException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'ReceiveTimeoutException: ${errorModel.errorMessage}';
}

class ConnectionErrorException extends ServerException {
  ConnectionErrorException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'ConnectionErrorException: ${errorModel.errorMessage}';
}

class SendTimeoutException extends ServerException {
  SendTimeoutException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'SendTimeoutException: ${errorModel.errorMessage}';
}

class UnauthorizedException extends ServerException {
  UnauthorizedException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'UnauthorizedException: ${errorModel.errorMessage}';
}

class ForbiddenException extends ServerException {
  ForbiddenException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'ForbiddenException: ${errorModel.errorMessage}';
}

class NotFoundException extends ServerException {
  NotFoundException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'NotFoundException: ${errorModel.errorMessage}';
}

class CofficientException extends ServerException {
  CofficientException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'UnauthorizedException: ${errorModel.errorMessage}';
}

class CancelException extends ServerException {
  CancelException(ErrorModel errorModel) : super(errorModel);
  @override
  String toString() => 'UnauthorizedException: ${errorModel.errorMessage}';
}

class UnknownException extends ServerException {
  UnknownException(ErrorModel errorModel) : super(errorModel);

  @override
  String toString() => 'UnauthorizedException: ${errorModel.errorMessage}';
}

void handleDioException(DioException e) {
  final errorModel = ErrorModel.fromJson(e.response?.data);

  switch (e.type) {
    case DioExceptionType.connectionError:
      throw ConnectionErrorException(errorModel);

    case DioExceptionType.badCertificate:
      throw BadCertificateException(errorModel);

    case DioExceptionType.connectionTimeout:
      throw ConnectionTimeoutException(errorModel);

    case DioExceptionType.receiveTimeout:
      throw ReceiveTimeoutException(errorModel);

    case DioExceptionType.sendTimeout:
      throw SendTimeoutException(errorModel);

    case DioExceptionType.badResponse:
      switch (e.response?.statusCode) {
        case 400:
          throw BadResponseException(errorModel);
        case 401:
          throw UnauthorizedException(errorModel);
        case 403:
          throw ForbiddenException(errorModel);
        case 404:
          throw NotFoundException(errorModel);
        case 409:
          throw CofficientException(errorModel);
        case 504:
          throw BadResponseException(errorModel);
        default:
          throw BadResponseException(errorModel);
      }

    case DioExceptionType.cancel:
      throw CancelException(
        ErrorModel(
          errorMessage: "Request was cancelled.",
          status: 499,
        ),
      );

    case DioExceptionType.unknown:
      throw UnknownException(
        ErrorModel(
          errorMessage: "Unexpected error occurred.",
          status: 500,
        ),
      );
  }
}
