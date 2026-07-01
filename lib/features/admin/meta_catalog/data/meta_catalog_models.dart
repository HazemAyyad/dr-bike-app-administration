class MetaCatalogStatus {
  final bool configured;
  final String? configurationError;
  final String? catalogId;
  final int totalProducts;
  final int synced;
  final int failed;
  final int pending;
  final int disabled;
  final String? lastSyncedAt;
  final int totalProductSets;
  final int syncedProductSets;
  final int failedProductSets;

  MetaCatalogStatus.fromJson(Map<String, dynamic> json)
      : configured = json['configured'] == true,
        configurationError = json['configuration_error']?.toString(),
        catalogId = json['catalog_id']?.toString(),
        totalProducts = _int(json['total_local_products']),
        synced = _int(json['synced_products']),
        failed = _int(json['failed_products']),
        pending = _int(json['pending_products']),
        disabled = _int(json['disabled_products']),
        lastSyncedAt = json['last_synced_at']?.toString(),
        totalProductSets = _int(json['total_product_sets']),
        syncedProductSets = _int(json['synced_product_sets']),
        failedProductSets = _int(json['failed_product_sets']);
}

class MetaCatalogProductSet {
  final int id;
  final String sourceType;
  final int sourceId;
  final int? parentSourceId;
  final String name;
  final String status;
  final String? metaProductSetId;
  final String? lastSyncedAt;
  final String? error;

  MetaCatalogProductSet.fromJson(Map<String, dynamic> json)
      : id = _int(json['id']),
        sourceType = json['source_type']?.toString() ?? 'category',
        sourceId = _int(json['source_id']),
        parentSourceId = json['parent_source_id'] == null
            ? null
            : _int(json['parent_source_id']),
        name = json['name']?.toString() ?? '',
        status = json['sync_status']?.toString() ?? 'pending',
        metaProductSetId = json['meta_product_set_id']?.toString(),
        lastSyncedAt = json['last_synced_at']?.toString(),
        error = json['last_error']?.toString();
}

class MetaCatalogVariant {
  final int id;
  final String name;
  final double price;
  final int quantity;
  final String status;
  final String? error;

  MetaCatalogVariant.fromJson(Map<String, dynamic> json)
      : id = _int(json['id']),
        name = json['name']?.toString() ?? '',
        price = _double(json['price']),
        quantity = _int(json['quantity']),
        status = json['meta_catalog_sync_status']?.toString() ?? 'pending',
        error = json['meta_catalog_last_error']?.toString();
}

class MetaCatalogProduct {
  final int id;
  final String name;
  final String? image;
  final double price;
  final int quantity;
  final String? category;
  final String status;
  final String? lastSyncedAt;
  final String? error;
  final String? retailerId;
  final List<MetaCatalogVariant> variants;

  MetaCatalogProduct.fromJson(Map<String, dynamic> json)
      : id = _int(json['id']),
        name = json['name']?.toString() ?? '',
        image = json['image']?.toString(),
        price = _double(json['price']),
        quantity = _int(json['quantity']),
        category = json['category']?.toString(),
        status = json['meta_catalog_sync_status']?.toString() ?? 'pending',
        lastSyncedAt = json['meta_catalog_last_synced_at']?.toString(),
        error = json['meta_catalog_last_error']?.toString(),
        retailerId = json['meta_catalog_retailer_id']?.toString(),
        variants = (json['variants'] as List? ?? const [])
            .whereType<Map>()
            .map((e) =>
                MetaCatalogVariant.fromJson(Map<String, dynamic>.from(e)))
            .toList();
}

class MetaCatalogSyncLog {
  final int id;
  final String action;
  final String status;
  final String? productName;
  final String? retailerId;
  final String? error;
  final String? createdAt;

  MetaCatalogSyncLog.fromJson(Map<String, dynamic> json)
      : id = _int(json['id']),
        action = json['action']?.toString() ?? '',
        status = json['status']?.toString() ?? '',
        productName = (json['product'] is Map
                ? (json['product']['nameAr'] ?? json['product']['nameEng'])
                : null)
            ?.toString(),
        retailerId = json['retailer_id']?.toString(),
        error = json['error_message']?.toString(),
        createdAt = json['created_at']?.toString();
}

class MetaCatalogSettings {
  bool autoSync;
  bool showQuantity;
  String currency;
  String defaultBrand;

  MetaCatalogSettings.fromJson(Map<String, dynamic> json)
      : autoSync = json['auto_sync_meta_catalog'] == true,
        showQuantity = json['enable_show_quantity_in_catalog'] == true,
        currency = json['meta_catalog_currency']?.toString() ?? 'ILS',
        defaultBrand =
            json['meta_catalog_default_brand']?.toString() ?? 'Dr Bike';

  Map<String, dynamic> toJson() => {
        'auto_sync_meta_catalog': autoSync,
        'enable_show_quantity_in_catalog': showQuantity,
        'meta_catalog_currency': currency,
        'meta_catalog_default_brand': defaultBrand,
      };
}

int _int(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;
double _double(dynamic value) => double.tryParse(value?.toString() ?? '') ?? 0;
