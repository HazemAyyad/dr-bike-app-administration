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

  factory NotCashedModel.fromJson(Map<String, dynamic> json,
      {required String checksPath}) {
    return NotCashedModel(
      status: json['status'] ?? '',
      checksStatus: json['checks_status'] ?? '',
      checksImagesPath: json['checks_images_path'] ?? '',
      inComingChecksList: (json[checksPath] as List<dynamic>?)
              ?.map(
                (e) => CheckModel.fromJson(
                  e,
                  frontImg: json['front_checks_images_path'] ??
                      json['checks_images_path'],
                  backImg: json['back_checks_images_path'] ?? '',
                ),
              )
              .toList() ??
          [],
      checksCount: (json['checks_count'] ?? '').toString(),
      checksTotalDollar: (json['checks_total_dollar'] ?? '').toString(),
      checksTotalShekel: (json['checks_total_shekel'] ?? '').toString(),
      checksTotalDinar: (json['checks_total_dinar'] ?? '').toString(),
      boxesTotalDollar: (json['boxes_total_dollar'] ?? '').toString(),
      boxesTotalShekel: (json['boxes_total_shekel'] ?? '').toString(),
      boxesTotalDinar: (json['boxes_total_dinar'] ?? '').toString(),
      coverPercentage: json['cover_percentage'],
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
    return CoverPercentageModel(
      dollar: (json['dollar'] ?? 0).toDouble(),
      dinar: (json['dinar'] ?? 0).toDouble(),
      shekel: (json['shekel'] ?? 0).toDouble(),
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
    return CheckModel(
      id: json['id'] ?? 0,
      customerId: json['customer_id']?.toString(),
      status: json['status'] ?? '',
      total: json['total'] ?? '0.00',
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : DateTime.now(),
      currency: json['currency'] ?? '',
      checkId: json['check_id'] ?? '',
      bankName: json['bank_name'] ?? '',
      frontImage: json['front_image'] != null || json['img'] != null
          ? ShowNetImage.getPhoto(
              '$frontImg/${json['front_image'] ?? json['img']}')
          : null,
      backImage: json['back_image'] != null
          ? ShowNetImage.getPhoto('$backImg/${json['back_image']}')
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
      sellerId: json['seller_id']?.toString(),
      customer: json['customer'] != null
          ? SellerModel.fromJson(json['customer'])
          : null,
      seller:
          json['seller'] != null ? SellerModel.fromJson(json['seller']) : null,
      fromCustomer: json['from_customer'] != null
          ? SellerModel.fromJson(json['from_customer'])
          : null,
      fromSeller: json['from_seller'] != null
          ? SellerModel.fromJson(json['from_seller'])
          : null,
      toCustomer: json['to_customer'] != null
          ? SellerModel.fromJson(json['to_customer'])
          : null,
      toSeller: json['to_seller'] != null
          ? SellerModel.fromJson(json['to_seller'])
          : null,
      notes: json['notes'] ?? '',
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
    return SellerModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }
}
