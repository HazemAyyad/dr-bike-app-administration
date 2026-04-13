import 'package:doctorbike/core/helpers/json_safe_parser.dart';
import 'package:doctorbike/core/helpers/show_net_image.dart';

class ProjectDetailsModel {
  final int id;
  final String name;
  final String projectCost;
  final List<String> images;
  final String paymentMethod;
  final String notes;
  final List<String> partnershipPapers;
  final String createdAt;
  final String updatedAt;
  final String achievementPercentage;
  final String status;
  final String paymentNotes;
  final PartnershipModel? partnership;
  final List<ProjectProductModel> products;

  ProjectDetailsModel({
    required this.id,
    required this.name,
    required this.projectCost,
    required this.images,
    required this.paymentMethod,
    required this.notes,
    required this.partnershipPapers,
    required this.createdAt,
    required this.updatedAt,
    required this.achievementPercentage,
    required this.status,
    required this.paymentNotes,
    this.partnership,
    required this.products,
  });

  factory ProjectDetailsModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    List<String> mapPhotoList(dynamic raw) {
      if (raw is! List) return [];
      return raw.map((x) => ShowNetImage.getPhoto(asNullableString(x))).toList();
    }

    final partnershipRaw = j['partnership'];
    return ProjectDetailsModel(
      id: asInt(j['id']),
      name: asString(j['name']),
      projectCost: asString(j['project_cost']),
      images: mapPhotoList(j['images']),
      paymentMethod: asString(j['payment_method']),
      notes: asString(j['notes']),
      partnershipPapers: mapPhotoList(j['partnership_papers']),
      createdAt: asString(j['created_at']),
      updatedAt: asString(j['updated_at']),
      achievementPercentage: asString(j['achievement_percentage']),
      status: asString(j['status']),
      paymentNotes: asString(j['payment_notes']),
      partnership: partnershipRaw is Map
          ? PartnershipModel.fromJson(Map<String, dynamic>.from(partnershipRaw))
          : null,
      products: mapList(
        j['products'],
        (Map<String, dynamic> m) => ProjectProductModel.fromJson(m),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'project_cost': projectCost,
      'images': images,
      'payment_method': paymentMethod,
      'notes': notes,
      'partnership_papers': partnershipPapers,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'achievement_percentage': achievementPercentage,
      'status': status,
      'payment_notes': paymentNotes,
      'partnership': partnership?.toJson(),
      'products': products.map((e) => e.toJson()).toList(),
    };
  }
}

class PartnershipModel {
  final String? customerId;
  final String? customerName;
  final String? sellerId;
  final String? sellerName;
  final String share;
  final String partnershipPercentage;

  PartnershipModel({
    required this.customerId,
    required this.customerName,
    this.sellerId,
    this.sellerName,
    required this.share,
    required this.partnershipPercentage,
  });

  factory PartnershipModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return PartnershipModel(
      customerId: asNullableString(j['customer_id']),
      customerName: asNullableString(j['customer_name']),
      sellerId: asNullableString(j['seller_id']),
      sellerName: asNullableString(j['seller_name']),
      share: asString(j['share']),
      partnershipPercentage: asString(j['partnership_percentage']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'customer_name': customerName,
      'seller_id': sellerId,
      'seller_name': sellerName,
      'share': share,
      'partnership_percentage': partnershipPercentage,
    };
  }
}

class ProjectProductModel {
  final String productId;
  final String productName;

  ProjectProductModel({
    required this.productId,
    required this.productName,
  });

  factory ProjectProductModel.fromJson(Map<String, dynamic> json) {
    final j = Map<String, dynamic>.from(json);
    return ProjectProductModel(
      productId: asString(j['product_id'], '0'),
      productName: asString(j['product_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
    };
  }
}
