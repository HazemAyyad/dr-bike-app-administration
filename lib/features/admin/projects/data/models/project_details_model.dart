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
    return ProjectDetailsModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      projectCost: json['project_cost'] ?? "",
      images: List<String>.from(
          json['images'].map((x) => ShowNetImage.getPhoto(x))),
      paymentMethod: json['payment_method'] ?? "",
      notes: json['notes'] ?? "",
      partnershipPapers: List<String>.from(
          json['partnership_papers'].map((x) => ShowNetImage.getPhoto(x))),
      createdAt: json['created_at'] ?? "",
      updatedAt: json['updated_at'] ?? "",
      achievementPercentage: json['achievement_percentage'] ?? "",
      status: json['status'] ?? "",
      paymentNotes: json['payment_notes'] ?? "",
      partnership: (json['partnership'] != null &&
              json['partnership'] is Map<String, dynamic>)
          ? PartnershipModel.fromJson(json['partnership'])
          : null,
      products: (json['products'] as List<dynamic>)
          .map((e) => ProjectProductModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "project_cost": projectCost,
      "images": images,
      "payment_method": paymentMethod,
      "notes": notes,
      "partnership_papers": partnershipPapers,
      "created_at": createdAt,
      "updated_at": updatedAt,
      "achievement_percentage": achievementPercentage,
      "status": status,
      "payment_notes": paymentNotes,
      "partnership": partnership?.toJson(),
      "products": products.map((e) => e.toJson()).toList(),
    };
  }
}

class PartnershipModel {
  final String customerId;
  final String customerName;
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
    return PartnershipModel(
      customerId: json['customer_id'] ?? "",
      customerName: json['customer_name'] ?? "",
      sellerId: json['seller_id'] ?? "",
      sellerName: json['seller_name'] ?? "",
      share: json['share'] ?? "",
      partnershipPercentage: json['partnership_percentage'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "customer_id": customerId,
      "customer_name": customerName,
      "seller_id": sellerId,
      "seller_name": sellerName,
      "share": share,
      "partnership_percentage": partnershipPercentage,
    };
  }
}

class ProjectProductModel {
  final int productId;
  final String? productName;

  ProjectProductModel({
    required this.productId,
    this.productName,
  });

  factory ProjectProductModel.fromJson(Map<String, dynamic> json) {
    return ProjectProductModel(
      productId: json['product_id'] ?? 0,
      productName: json['product_name'] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "product_id": productId,
      "product_name": productName,
    };
  }
}
