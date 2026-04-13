import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

import '../../domain/entity/check_entity.dart';

// import '../../domain/entity/check_entity.dart';

class NotCashedModel {
  final String status;
  final String checksStatus;
  final String checksImagesPath;
  final List<CheckModel> inComingChecksList;
  final String checksCount;
  final String checksTotalDollar;
  final String checksTotalShekel;
  final String checksTotalDinar;
  final String boxesTotalDollar;
  final String boxesTotalShekel;
  final String boxesTotalDinar;
  final Map<String, dynamic>? coverPercentage;

  NotCashedModel({
    required this.status,
    required this.checksStatus,
    required this.checksImagesPath,
    required this.inComingChecksList,
    required this.checksCount,
    required this.checksTotalDollar,
    required this.checksTotalShekel,
    required this.checksTotalDinar,
    required this.boxesTotalDollar,
    required this.boxesTotalShekel,
    required this.boxesTotalDinar,
    required this.coverPercentage,
  });

  factory NotCashedModel.fromJson(
    Map<String, dynamic> json, {
    required String checksPath,
  }) {
    final j = Map<String, dynamic>.from(json);
    final frontImgBase = asNullableString(j['front_checks_images_path']) ??
        asNullableString(j['checks_images_path']) ??
        '';
    final backImgBase = asString(j['back_checks_images_path']);

    List<CheckModel> mapChecks() {
      final raw = j[checksPath];
      if (raw is! List) return [];
      return raw.map((e) {
        final m = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
        return CheckModel.fromJson(
          m,
          frontImg: frontImgBase,
          backImg: backImgBase,
        );
      }).toList();
    }

    return NotCashedModel(
      status: asString(j['status']),
      checksStatus: asString(j['checks_status']),
      checksImagesPath: asString(j['checks_images_path']),
      inComingChecksList: mapChecks(),
      checksCount: asString(j['checks_count']),
      checksTotalDollar: asString(j['checks_total_dollar']),
      checksTotalShekel: asString(j['checks_total_shekel']),
      checksTotalDinar: asString(j['checks_total_dinar']),
      boxesTotalDollar: asString(j['boxes_total_dollar']),
      boxesTotalShekel: asString(j['boxes_total_shekel']),
      boxesTotalDinar: asString(j['boxes_total_dinar']),
      coverPercentage: j['cover_percentage'] is Map
          ? Map<String, dynamic>.from(j['cover_percentage'] as Map)
          : j['cover_percentage'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'checks_status': checksStatus,
      'checks_images_path': checksImagesPath,
      'not_cashed_checks': inComingChecksList.map((e) => e.toJson()).toList(),
      'checks_count': checksCount,
      'checks_total_dollar': checksTotalDollar,
      'checks_total_shekel': checksTotalShekel,
      'checks_total_dinar': checksTotalDinar,
      'boxes_total_dollar': boxesTotalDollar,
      'boxes_total_shekel': boxesTotalShekel,
      'boxes_total_dinar': boxesTotalDinar,
      'cover_percentage': coverPercentage,
    };
  }
}

class CoverPercentageModel {
  final double dollar;
  final double dinar;
  final double shekel;

  CoverPercentageModel({
    required this.dollar,
    required this.dinar,
    required this.shekel,
  });

  factory CoverPercentageModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return CoverPercentageModel(
      dollar: asDouble(j['dollar']),
      dinar: asDouble(j['dinar']),
      shekel: asDouble(j['shekel']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dollar': dollar,
      'dinar': dinar,
      'shekel': shekel,
    };
  }
}

class CheckModel extends CheckEntity {
  const CheckModel({
    required int id,
    String? customerId,
    required String status,
    required String total,
    required DateTime dueDate,
    required String currency,
    required String checkId,
    required String bankName,
    String? frontImage,
    String? backImage,
    required DateTime createdAt,
    required DateTime updatedAt,
    String? sellerId,
    Seller? customer,
    Seller? seller,
    Seller? fromCustomer,
    Seller? fromSeller,
    Seller? toCustomer,
    Seller? toSeller,
    String? notes,
  }) : super(
          id: id,
          customerId: customerId,
          status: status,
          total: total,
          dueDate: dueDate,
          currency: currency,
          checkId: checkId,
          bankName: bankName,
          frontImage: frontImage,
          backImage: backImage,
          createdAt: createdAt,
          updatedAt: updatedAt,
          sellerId: sellerId,
          customer: customer,
          seller: seller,
          fromCustomer: fromCustomer,
          fromSeller: fromSeller,
          toCustomer: toCustomer,
          toSeller: toSeller,
          notes: notes,
        );

  factory CheckModel.fromJson(
    Map<String, dynamic> json, {
    required String frontImg,
    required String backImg,
  }) {
    final j = Map<String, dynamic>.from(json);
    final frontRel =
        asNullableString(j['front_image']) ?? asNullableString(j['img']);
    final backRel = asNullableString(j['back_image']);

    return CheckModel(
      id: asInt(j['id']),
      customerId: asNullableString(j['customer_id']),
      status: asString(j['status']),
      total: asString(j['total'], '0.00'),
      dueDate: parseApiDateTime(j['due_date']),
      currency: asString(j['currency']),
      checkId: asString(j['check_id']),
      bankName: asString(j['bank_name']),
      frontImage: frontRel != null
          ? ShowNetImage.getPhoto('$frontImg/$frontRel')
          : null,
      backImage: backRel != null
          ? ShowNetImage.getPhoto('$backImg/$backRel')
          : null,
      createdAt: parseApiDateTime(j['created_at']),
      updatedAt: parseApiDateTime(j['updated_at']),
      sellerId: asNullableString(j['seller_id']),
      customer: j['customer'] != null
          ? SellerModel.fromJson(asMap(j['customer']))
          : null,
      seller: j['seller'] != null
          ? SellerModel.fromJson(asMap(j['seller']))
          : null,
      fromCustomer: j['from_customer'] != null
          ? SellerModel.fromJson(asMap(j['from_customer']))
          : null,
      fromSeller: j['from_seller'] != null
          ? SellerModel.fromJson(asMap(j['from_seller']))
          : null,
      toCustomer: j['to_customer'] != null
          ? SellerModel.fromJson(asMap(j['to_customer']))
          : null,
      toSeller: j['to_seller'] != null
          ? SellerModel.fromJson(asMap(j['to_seller']))
          : null,
      notes: asString(j['notes']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'status': status,
      'total': total,
      'due_date': dueDate.toIso8601String(),
      'currency': currency,
      'check_id': checkId,
      'bank_name': bankName,
      'img': frontImage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'seller_id': sellerId,
      'customer': customer,
      'seller': seller,
      'from_customer': fromCustomer,
      'from_seller': fromSeller,
      'to_customer': toCustomer,
      'to_seller': toSeller,
      'notes': notes,
    };
  }
}

class SellerModel extends Seller {
  const SellerModel({
    required int id,
    required String name,
  }) : super(
          id: id,
          name: name,
        );

  factory SellerModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return SellerModel(
      id: asInt(j['id']),
      name: asString(j['name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
