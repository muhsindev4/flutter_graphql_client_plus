import 'error.dart';

class ResponseModel {
  final dynamic data;
  final ErrorModel? error;

  ResponseModel({required this.data, required this.error});

  bool get isSuccess => error == null;
}
