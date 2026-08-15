import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../../../../core/databases/api/end_points.dart';
import '../../domain/entities/employee_entity.dart';

class EmployeeModel extends EmployeeEntity {
  const EmployeeModel({
    required int id,
    required String name,
    required String hourWorkPrice,
    required String points,
    required String image,
    required bool hasAttendedToday,
    required bool isWorkingNow,
    required bool isCameOnTime,
    required bool isConnectedToAllowedWifi,
    required bool isNetworkConnected,
    required String wifiPresenceState,
    String? wifiSsid,
    String? wifiStatusUpdatedAt,
    bool isWifiStatusStale = true,
    bool isSuspended = false,
    String? suspendedAt,
    String? suspensionReason,
    EmployeePointsSummaryEntity? pointsSummary,
  }) : super(
          id: id,
          employeeName: name,
          hourWorkPrice: hourWorkPrice,
          points: points,
          employeeImg: image,
          hasAttendedToday: hasAttendedToday,
          isWorkingNow: isWorkingNow,
          isCameOnTime: isCameOnTime,
          isConnectedToAllowedWifi: isConnectedToAllowedWifi,
          isNetworkConnected: isNetworkConnected,
          wifiPresenceState: wifiPresenceState,
          wifiSsid: wifiSsid,
          wifiStatusUpdatedAt: wifiStatusUpdatedAt,
          isWifiStatusStale: isWifiStatusStale,
          isSuspended: isSuspended,
          suspendedAt: suspendedAt,
          suspensionReason: suspensionReason,
          pointsSummary: pointsSummary,
        );

  factory EmployeeModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    EmployeePointsSummaryEntity? summary;
    final ps = j['points_summary'];
    if (ps is Map) {
      final m = Map<String, dynamic>.from(ps);
      summary = EmployeePointsSummaryEntity(
        earnedPoints: asInt(m['earned_points']),
        deductedPoints: asInt(m['deducted_points']),
        netPoints: asInt(m['net_points']),
        rewardAmount: asString(m['reward_amount'], '0.00'),
        rewardRuleId:
            m['reward_rule_id'] == null ? null : asInt(m['reward_rule_id']),
        rewardStatusLabel: asNullableString(m['reward_status_label']),
        rewardStatusColor: asNullableString(m['reward_status_color']),
      );
    }
    final wifiStatus = asMap(j['wifi_status']);
    return EmployeeModel(
      id: asInt(j[ApiKey.id]),
      name: asString(j[ApiKey.employee_name], 'unknown'),
      hourWorkPrice: asString(j[ApiKey.hour_work_price], '0'),
      points: asString(j[ApiKey.points], '0'),
      image: ShowNetImage.getPhoto(asNullableString(j[ApiKey.employee_img])),
      hasAttendedToday: asBool(j['has_attended_today']),
      isWorkingNow: asBool(j['is_working_now']),
      isCameOnTime: asBool(j['is_came_on_time']),
      isConnectedToAllowedWifi: asBool(wifiStatus['connected']),
      isNetworkConnected: asBool(wifiStatus['network_connected']),
      wifiPresenceState: asString(
        wifiStatus['state'],
        asBool(wifiStatus['connected'])
            ? 'green'
            : (asBool(wifiStatus['network_connected']) ? 'orange' : 'red'),
      ),
      wifiSsid: asNullableString(wifiStatus['ssid']),
      wifiStatusUpdatedAt: asNullableString(wifiStatus['updated_at']),
      isWifiStatusStale: asBool(wifiStatus['stale'], true),
      isSuspended: asBool(j['is_suspended']),
      suspendedAt: asNullableString(j['suspended_at']),
      suspensionReason: asNullableString(j['suspension_reason']),
      pointsSummary: summary,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ApiKey.id: id,
      ApiKey.employee_name: employeeName,
      ApiKey.hour_work_price: hourWorkPrice,
      ApiKey.points: points,
      ApiKey.employee_img: employeeImg,
      'has_attended_today': hasAttendedToday,
      'is_working_now': isWorkingNow,
      'is_came_on_time': isCameOnTime,
      'wifi_status': {
        'connected': isConnectedToAllowedWifi,
        'network_connected': isNetworkConnected,
        'state': wifiPresenceState,
        'ssid': wifiSsid,
        'updated_at': wifiStatusUpdatedAt,
        'stale': isWifiStatusStale,
      },
      'is_suspended': isSuspended,
      'suspended_at': suspendedAt,
      'suspension_reason': suspensionReason,
    };
  }
}
