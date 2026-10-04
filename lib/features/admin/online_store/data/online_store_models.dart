Map<String, dynamic> onlineStoreMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

List<Map<String, dynamic>> onlineStoreRows(dynamic value) {
  final raw = value is Map ? value['data'] : value;
  if (raw is! List) return const [];
  return raw.whereType<Map>().map(onlineStoreMap).toList(growable: false);
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
    this.isFeatured = false,
    this.isNew = false,
    this.showOnHome = false,
    this.showAsOffer = false,
    this.sortOrder = 0,
    this.readinessIssues = const [],
    this.basePrices = const {},
    this.availability = const {},
    this.media = const [],
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
  final bool isFeatured;
  final bool isNew;
  final bool showOnHome;
  final bool showAsOffer;
  final int sortOrder;
  final List<String> readinessIssues;
  final Map<String, dynamic> basePrices;
  final Map<String, dynamic> availability;
  final List<OnlineStoreMedia> media;
  final String? updatedAt;

  bool get canPublish => readinessState == 'ready' && readinessIssues.isEmpty;

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
      updatedAt: json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toWritableJson() => {
        'name_translations': titleTranslations,
        'description_translations': descriptionTranslations,
        'badge_translations': badgeTranslations,
        'is_featured': isFeatured,
        'is_new': isNew,
        'show_on_home': showOnHome,
        'show_as_offer': showAsOffer,
        'sort_order': sortOrder,
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
  });

  final int sourceMediaId;
  final int sortOrder;
  final String url;
  final bool isMain;
  final bool isVisible;
  final String sourceType;

  factory OnlineStoreMedia.fromJson(Map<String, dynamic> json) =>
      OnlineStoreMedia(
        sourceMediaId:
            _int(json['source_media_id'] ?? json['media_id'] ?? json['id']),
        sortOrder: _int(json['sort_order']),
        url: '${json['url'] ?? json['media_url'] ?? json['path'] ?? ''}',
        isMain: _bool(json['is_main']),
        isVisible: json['is_visible'] == null || _bool(json['is_visible']),
        sourceType: '${json['source_type'] ?? 'product'}',
      );

  OnlineStoreMedia copyWith({
    int? sortOrder,
    bool? isMain,
    bool? isVisible,
  }) =>
      OnlineStoreMedia(
        sourceMediaId: sourceMediaId,
        sortOrder: sortOrder ?? this.sortOrder,
        url: url,
        isMain: isMain ?? this.isMain,
        isVisible: isVisible ?? this.isVisible,
        sourceType: sourceType,
      );

  Map<String, dynamic> toRequestJson() => {
        'source_media_id': sourceMediaId,
        'sort_order': sortOrder,
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
    this.isBlocked = false,
    this.isLinkable = true,
    this.links = const [],
  });

  final int id;
  final String name;
  final String? email;
  final String? phone;
  final bool isBlocked;
  final bool isLinkable;
  final List<OnlineStoreAccountLink> links;

  factory OnlineStoreAccount.fromJson(Map<String, dynamic> json) =>
      OnlineStoreAccount(
        id: _int(json['id']),
        name: '${json['name'] ?? ''}',
        email: json['email']?.toString(),
        phone: json['phone']?.toString(),
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
bool _bool(dynamic value) => value == true || value == 1 || value == '1';
