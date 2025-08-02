class ErrorModel {
  final String errorMessage;
  final int status;
  final dynamic data;

  ErrorModel({
    required this.status,
    required this.errorMessage,
    this.data,
  });

  factory ErrorModel.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return ErrorModel(
        errorMessage: "Unknown error occurred",
        status: 404,
      );
    }

    return ErrorModel(
      errorMessage: json['message']?.toString() ?? "Unknown error",
      status: json['status'] ?? 500,
    );
  }

  @override
  String toString() => 'Error($status): $errorMessage';
}
