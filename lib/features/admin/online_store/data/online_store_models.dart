Map<String, dynamic> onlineStoreMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> onlineStoreRows(dynamic value) {
  final raw = value is Map ? value['data'] : value;
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(onlineStoreMap).toList(growable: false);
}

class OnlineStoreProductCandidate {
  const OnlineStoreProductCandidate({
    required this.id,
    required this.nameAr,
    this.nameEn = '',
    this.code = '',
    this.imageUrl = '',
    this.stock = 0,
    this.retailPrice = 0,
    this.wholesalePrice = 0,
    this.storeSectionName = '',
    this.hasVariants = false,
    this.variants = const [],
    this.imageUrls = const [],
    this.videoUrl = '',
  });

  final int id;
  final String nameAr;
  final String nameEn;
  final String code;
  final String imageUrl;
  final num stock;
  final num retailPrice;
  final num wholesalePrice;
  final String storeSectionName;
  final bool hasVariants;
  final List<Map<String, dynamic>> variants;
  final List<String> imageUrls;
  final String videoUrl;

  String get displayName => nameAr.isNotEmpty ? nameAr : nameEn;

  factory OnlineStoreProductCandidate.fromJson(Map<String, dynamic> json) {
    String image(dynamic value) {
      if (value is String) return value;
      if (value is Map) {
        return '${value['imageUrl'] ?? value['url'] ?? value['path'] ?? ''}';
      }
      if (value is List && value.isNotEmpty) return image(value.first);
      return '';
    }

    final images = <String>[];
    for (final source in [
      json['product_viewImages'],
      json['viewImages'],
      json['product_normalImages'],
      json['normalImages'],
      json['product_image3d'],
      json['image3d'],
      json['product_variantImages'],
      json['variantImages'],
    ]) {
      if (source is List) {
        for (final item in source) {
          final path = image(item);
          if (path.isNotEmpty && !images.contains(path)) {
            images.add(path);
          }
        }
      }
    }
    final primary = image(json['product_image'] ??
        json['main_image'] ??
        json['view_image'] ??
        json['product_viewImages'] ??
        json['viewImages'] ??
        json['product_normalImages'] ??
        json['normalImages'] ??
        json['product_image3d'] ??
        json['image3d']);
    if (primary.isNotEmpty && !images.contains(primary)) {
      images.insert(0, primary);
    }
    return OnlineStoreProductCandidate(
      id: _int(json['id']),
      nameAr: '${json['nameAr'] ?? json['name_ar'] ?? json['name'] ?? ''}',
      nameEn: '${json['nameEng'] ?? json['name_en'] ?? ''}',
      code: '${json['product_code'] ?? json['code'] ?? ''}',
      imageUrl: primary,
      stock: _num(json['stock']),
      retailPrice: _num(json['normail_price'] ??
          json['product_normail_price'] ??
          json['normailPrice']),
      wholesalePrice: _num(json['wholesale_price'] ?? json['wholesalePrice']),
      storeSectionName: '${json['store_section_name'] ?? ''}',
      hasVariants: _bool(json['has_variants']),
      variants: (json['sizes'] as List? ?? const [])
          .whereType<Map>()
          .map(onlineStoreMap)
          .toList(growable: false),
      imageUrls: images,
      videoUrl:
          '${json['product_video'] ?? json['videoUrl'] ?? json['video_url'] ?? ''}',
    );
  }
}

class OnlineStorePage<T> {
  const OnlineStorePage({required this.items, this.meta = const {}});

  final List<T> items;
  final Map<String, dynamic> meta;

  factory OnlineStorePage.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic> json) parser,
  ) {
    final payload = json['data'];
    final rows = payload is Map ? payload['data'] : payload;
    return OnlineStorePage(
      items: onlineStoreRows(rows).map(parser).toList(growable: false),
      meta: payload is Map
          ? <String, dynamic>{
              'current_page': payload['current_page'],
              'last_page': payload['last_page'],
              'total': payload['total'],
            }
          : onlineStoreMap(json['meta']),
    );
  }
}

class OnlineStoreListing {
  const OnlineStoreListing({
    required this.id,
    required this.productId,
    required this.status,
    required this.readinessState,
    this.productName = '',
    this.titleTranslations = const {},
    this.descriptionTranslations = const {},
    this.badgeTranslations = const {},
    this.detailPresentation = const {},
    this.isFeatured = false,
    this.isNew = false,
    this.showOnHome = false,
    this.showAsOffer = false,
    this.sortOrder = 0,
    this.readinessIssues = const [],
    this.basePrices = const {},
    this.availability = const {},
    this.media = const [],
    this.originalNameTranslations = const {},
    this.originalDescriptionTranslations = const {},
    this.productCode = '',
    this.onlineStockLimit,
    this.viewCount = 0,
    this.updatedAt,
  });

  final int id;
  final int productId;
  final String status;
  final String readinessState;
  final String productName;
  final Map<String, dynamic> titleTranslations;
  final Map<String, dynamic> descriptionTranslations;
  final Map<String, dynamic> badgeTranslations;
  final Map<String, dynamic> detailPresentation;
  final bool isFeatured;
  final bool isNew;
  final bool showOnHome;
  final bool showAsOffer;
  final int sortOrder;
  final List<String> readinessIssues;
  final Map<String, dynamic> basePrices;
  final Map<String, dynamic> availability;
  final List<OnlineStoreMedia> media;
  final Map<String, dynamic> originalNameTranslations;
  final Map<String, dynamic> originalDescriptionTranslations;
  final String productCode;
  final int? onlineStockLimit;
  final int viewCount;
  final String? updatedAt;

  bool get canPublish =>
      (readinessState == 'complete' || readinessState == 'ready') &&
      readinessIssues.isEmpty;
  String get mainMediaUrl {
    final available = media.where(
      (item) => item.isVisible && item.url.trim().isNotEmpty,
    );
    if (available.isEmpty) return '';
    return available
        .firstWhere((item) => item.isMain, orElse: () => available.first)
        .url;
  }

  num get retailPrice => _num(basePrices['retail']);
  int get availableQuantity => _int(availability['available_qty']);

  factory OnlineStoreListing.fromJson(Map<String, dynamic> json) {
    final product = onlineStoreMap(json['product']);
    final display = onlineStoreMap(json['display']);
    return OnlineStoreListing(
      id: _int(json['id']),
      productId: _int(json['product_id'] ?? product['id']),
      status: '${json['status'] ?? 'draft'}',
      readinessState: '${json['readiness_state'] ?? 'draft'}',
      productName:
          '${display['name'] ?? product['name'] ?? json['product_name'] ?? ''}',
      titleTranslations: onlineStoreMap(
          json['name_translations'] ?? json['title_translations']),
      descriptionTranslations: onlineStoreMap(json['description_translations']),
      badgeTranslations: onlineStoreMap(json['badge_translations']),
      detailPresentation: onlineStoreMap(json['detail_presentation']),
      isFeatured: _bool(json['is_featured']),
      isNew: _bool(json['is_new']),
      showOnHome: _bool(json['show_on_home']),
      showAsOffer: _bool(json['show_as_offer']),
      sortOrder: _int(json['sort_order']),
      readinessIssues: (json['readiness_issues'] as List? ?? const [])
          .map((item) => item is Map
              ? '${item['message'] ?? item['code'] ?? ''}'
              : '$item')
          .where((item) => item.isNotEmpty)
          .toList(growable: false),
      basePrices: onlineStoreMap(json['base_prices']),
      availability: onlineStoreMap(json['availability']),
      media: onlineStoreRows(json['media'])
          .map((json) => OnlineStoreMedia.fromJson(json))
          .toList(growable: false),
      originalNameTranslations: onlineStoreMap(product['name_translations']),
      originalDescriptionTranslations:
          onlineStoreMap(product['description_translations']),
      productCode: '${product['code'] ?? ''}',
      onlineStockLimit: json['online_stock_limit'] == null
          ? null
          : _int(json['online_stock_limit']),
      viewCount: _int(json['view_count']),
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toWritableJson() => {
        'name_translations': titleTranslations,
        'description_translations': descriptionTranslations,
        'badge_translations': badgeTranslations,
        'detail_presentation': detailPresentation,
        'is_featured': isFeatured,
        'is_new': isNew,
        'show_on_home': showOnHome,
        'show_as_offer': showAsOffer,
        'sort_order': sortOrder,
        'online_stock_limit': onlineStockLimit,
        if (updatedAt != null) 'updated_at': updatedAt,
      };
}

class OnlineStoreMedia {
  const OnlineStoreMedia({
    required this.sourceMediaId,
    required this.sortOrder,
    this.url = '',
    this.isMain = false,
    this.isVisible = true,
    this.sourceType = 'product',
    this.sourceId,
    this.storeMediaPath,
    this.mediaMetadata = const {},
  });

  final int sourceMediaId;
  final int sortOrder;
  final String url;
  final bool isMain;
  final bool isVisible;
  final String sourceType;
  final int? sourceId;
  final String? storeMediaPath;
  final Map<String, dynamic> mediaMetadata;

  String get mediaType => '${mediaMetadata['media_type'] ?? 'image'}';
  String get role =>
      '${mediaMetadata['role'] ?? (isMain ? 'main' : 'additional')}';

  factory OnlineStoreMedia.fromJson(Map<String, dynamic> json) =>
      OnlineStoreMedia(
        sourceMediaId: _int(json['id'] ??
            json['source_media_id'] ??
            json['media_id'] ??
            json['source_id']),
        sortOrder: _int(json['sort_order']),
        url:
            '${json['resolved_path'] ?? json['url'] ?? json['media_url'] ?? json['path'] ?? ''}',
        isMain: _bool(json['is_main']),
        isVisible: json['is_visible'] == null || _bool(json['is_visible']),
        sourceType: '${json['source_type'] ?? 'product'}',
        sourceId: json['source_id'] == null ? null : _int(json['source_id']),
        storeMediaPath: json['store_media_path']?.toString(),
        mediaMetadata: onlineStoreMap(json['media_metadata']),
      );

  OnlineStoreMedia copyWith({
    int? sortOrder,
    bool? isMain,
    bool? isVisible,
    Map<String, dynamic>? mediaMetadata,
  }) =>
      OnlineStoreMedia(
        sourceMediaId: sourceMediaId,
        sortOrder: sortOrder ?? this.sortOrder,
        url: url,
        isMain: isMain ?? this.isMain,
        isVisible: isVisible ?? this.isVisible,
        sourceType: sourceType,
        sourceId: sourceId,
        storeMediaPath: storeMediaPath,
        mediaMetadata: mediaMetadata ?? this.mediaMetadata,
      );

  Map<String, dynamic> toRequestJson() => {
        'source_type': sourceType,
        'source_id': sourceId,
        'store_media_path': storeMediaPath,
        if (mediaMetadata.isNotEmpty) 'media_metadata': mediaMetadata,
        'is_main': isMain,
        'is_visible': isVisible,
      };
}

class OnlineStoreAccount {
  const OnlineStoreAccount({
    required this.id,
    required this.name,
    this.email,
    this.phone,
    this.profileImageUrl,
    this.isBlocked = false,
    this.isLinkable = true,
    this.links = const [],
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final String? profileImageUrl;
  final bool isBlocked;
  final bool isLinkable;
  final List<OnlineStoreAccountLink> links;

  factory OnlineStoreAccount.fromJson(Map<String, dynamic> json) =>
      OnlineStoreAccount(
        id: _int(json['id']),
        name: '${json['name'] ?? ''}',
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
        profileImageUrl: json['profile_image_url']?.toString(),
        isBlocked: _bool(json['is_blocked']),
        isLinkable: json['is_linkable'] == null || _bool(json['is_linkable']),
        links: onlineStoreRows(json['links'])
            .map((json) => OnlineStoreAccountLink.fromJson(json))
            .toList(growable: false),
      );
}

class OnlineStoreAccountLink {
  const OnlineStoreAccountLink({
    required this.id,
    required this.role,
    required this.status,
    this.partyId,
    this.partyName,
  });

  final int id;
  final String role;
  final String status;
  final int? partyId;
  final String? partyName;

  factory OnlineStoreAccountLink.fromJson(Map<String, dynamic> json) =>
      OnlineStoreAccountLink(
        id: _int(json['id']),
        role: '${json['role'] ?? json['party_type'] ?? ''}',
        status: '${json['status'] ?? 'active'}',
        partyId: _nullableInt(
            json['party_id'] ?? json['customer_id'] ?? json['seller_id']),
        partyName: json['party_name']?.toString(),
      );
}

class OnlineStoreParty {
  const OnlineStoreParty({
    required this.id,
    required this.name,
    this.phone = '',
  });

  final int id;
  final String name;
  final String phone;

  factory OnlineStoreParty.fromJson(Map<String, dynamic> json) =>
      OnlineStoreParty(
        id: _int(json['id']),
        name: '${json['name'] ?? ''}',
        phone: '${json['phone'] ?? ''}',
      );
}

class OnlineStoreCreditSnapshot {
  const OnlineStoreCreditSnapshot({
    required this.eligible,
    required this.currentDebt,
    required this.availableCredit,
    required this.currency,
    this.limit,
    this.expiresAt,
    this.asOf,
  });

  final bool eligible;
  final double? limit;
  final double currentDebt;
  final double availableCredit;
  final String currency;
  final String? expiresAt;
  final String? asOf;

  factory OnlineStoreCreditSnapshot.fromJson(Map<String, dynamic> json) {
    final policy = onlineStoreMap(json['policy']);
    return OnlineStoreCreditSnapshot(
      eligible: _bool(policy['is_eligible'] ?? json['is_eligible']),
      limit: _nullableDouble(
          policy['credit_limit'] ?? policy['limit'] ?? json['credit_limit']),
      currentDebt: _double(json['current_debt']),
      availableCredit: _double(json['available_credit']),
      currency: '${policy['currency'] ?? json['currency'] ?? 'ILS'}',
      expiresAt: (policy['expires_at'] ?? json['expires_at'])?.toString(),
      asOf: json['as_of']?.toString(),
    );
  }
}

class OnlineStoreDashboardSummary {
  const OnlineStoreDashboardSummary(this.values);
  final Map<String, dynamic> values;

  factory OnlineStoreDashboardSummary.fromJson(Map<String, dynamic> json) =>
      OnlineStoreDashboardSummary(onlineStoreMap(json['data']).isEmpty
          ? json
          : onlineStoreMap(json['data']));

  int count(String key) => _int(values[key]);

  int countPath(String group, String key) =>
      _int(onlineStoreMap(values[group])[key]);
}

class OnlineStoreEntity {
  const OnlineStoreEntity(this.values);
  final Map<String, dynamic> values;
  int get id => _int(values['id']);
  String get status => '${values['status'] ?? ''}';
  String get label {
    final translations = onlineStoreMap(
        values['name_translations'] ?? values['title_translations']);
    return '${values['name'] ?? values['title'] ?? translations['ar'] ?? translations['en'] ?? values['key'] ?? values['code'] ?? '#$id'}';
  }

  factory OnlineStoreEntity.fromJson(Map<String, dynamic> json) =>
      OnlineStoreEntity(json);
}

int _int(dynamic value) =>
    (value as num?)?.toInt() ?? int.tryParse('$value') ?? 0;
int? _nullableInt(dynamic value) => value == null ? null : _int(value);
double _double(dynamic value) =>
    (value as num?)?.toDouble() ?? double.tryParse('$value') ?? 0;
double? _nullableDouble(dynamic value) => value == null ? null : _double(value);
num _num(dynamic value) => value is num ? value : num.tryParse('$value') ?? 0;
bool _bool(dynamic value) => value == true || value == 1 || value == '1';
