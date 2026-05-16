class StockProductFilters {
  const StockProductFilters({
    this.search,
    this.categoryId,
    this.subCategoryId,
    this.tagId,
    this.dateFrom,
    this.dateTo,
    this.sortBy = 'created_at',
    this.sortDirection = 'desc',
  });

  final String? search;
  final String? categoryId;
  final String? subCategoryId;
  final String? tagId;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String sortBy;
  final String sortDirection;

  static const StockProductFilters empty = StockProductFilters();

  bool get hasActiveFilters =>
      (search != null && search!.trim().isNotEmpty) ||
      (categoryId != null && categoryId!.isNotEmpty) ||
      (subCategoryId != null && subCategoryId!.isNotEmpty) ||
      (tagId != null && tagId!.isNotEmpty) ||
      dateFrom != null ||
      dateTo != null ||
      sortBy != 'created_at' ||
      sortDirection != 'desc';

  /// Filters applied via the filter sheet (excludes search text).
  int get activeFilterCount {
    var n = 0;
    if (categoryId != null && categoryId!.isNotEmpty) n++;
    if (subCategoryId != null && subCategoryId!.isNotEmpty) n++;
    if (tagId != null && tagId!.isNotEmpty) n++;
    if (dateFrom != null) n++;
    if (dateTo != null) n++;
    if (sortBy != 'created_at') n++;
    if (sortDirection != 'desc') n++;
    return n;
  }

  StockProductFilters copyWith({
    String? search,
    String? categoryId,
    String? subCategoryId,
    String? tagId,
    DateTime? dateFrom,
    DateTime? dateTo,
    String? sortBy,
    String? sortDirection,
    bool clearSearch = false,
    bool clearCategoryId = false,
    bool clearSubCategoryId = false,
    bool clearTagId = false,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return StockProductFilters(
      search: clearSearch ? null : (search ?? this.search),
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      subCategoryId:
          clearSubCategoryId ? null : (subCategoryId ?? this.subCategoryId),
      tagId: clearTagId ? null : (tagId ?? this.tagId),
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      sortBy: sortBy ?? this.sortBy,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  Map<String, dynamic> toQueryParams({required int page, int perPage = 15}) {
    final params = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      'sort_by': sortBy,
      'sort_direction': sortDirection,
    };
    final s = search?.trim();
    if (s != null && s.isNotEmpty) params['search'] = s;
    if (categoryId != null && categoryId!.isNotEmpty) {
      params['category_id'] = categoryId;
    }
    if (subCategoryId != null && subCategoryId!.isNotEmpty) {
      params['sub_category_id'] = subCategoryId;
    }
    if (tagId != null && tagId!.isNotEmpty) params['tag_id'] = tagId;
    if (dateFrom != null) {
      params['date_from'] = formatDate(dateFrom!);
    }
    if (dateTo != null) {
      params['date_to'] = formatDate(dateTo!);
    }
    return params;
  }

  static String formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }
}
