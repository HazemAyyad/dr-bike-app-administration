import 'package:get/get.dart';

import '../../data/models/maintenances_model.dart';

class MaintenanceServes {
  final List<MaintenanceDataModel> maintenancesList = [];
  final List<MaintenanceDataModel> ongoingMaintenancesList = [];
  final List<MaintenanceDataModel> readyMaintenancesList = [];
  final List<MaintenanceDataModel> archiveMaintenancesList = [];

  final maintenancesTasks = <String, List<MaintenanceDataModel>>{}.obs;
  final ongoingMaintenancesTasks = <String, List<MaintenanceDataModel>>{}.obs;
  final readyMaintenancesTasks = <String, List<MaintenanceDataModel>>{}.obs;
  final archiveMaintenancesTasks = <String, List<MaintenanceDataModel>>{}.obs;

  // singleton pattern
  static final MaintenanceServes _instance = MaintenanceServes._internal();
  factory MaintenanceServes() => _instance;
  MaintenanceServes._internal();
}
