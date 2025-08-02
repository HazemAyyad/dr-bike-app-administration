import 'package:get/get.dart';

import '../../data/models/spotsale_model.dart';

class SalesService {
  final Rxn<SpotsaleModel> spotsaleModel = Rxn<SpotsaleModel>();

  // singleton pattern
  static final SalesService _instance = SalesService._internal();
  factory SalesService() => _instance;
  SalesService._internal();
}
