class StockMovementsFilters {
  const StockMovementsFilters({
    this.dateFrom,
    this.dateTo,
    this.type,
  });

  final DateTime? dateFrom;
  final DateTime? dateTo;
  final String? type;

  bool get hasActiveFilters =>
      dateFrom != null || dateTo != null || (type != null && type!.isNotEmpty);

  int get activeCount {
    var n = 0;
    if (dateFrom != null) n++;
    if (dateTo != null) n++;
    if (type != null && type!.isNotEmpty) n++;
    return n;
  }

  StockMovementsFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? type,
    bool clearDateFrom = false,
    bool clearDateTo = false,
    bool clearType = false,
  }) {
    return StockMovementsFilters(
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
      type: clearType ? null : (type ?? this.type),
    );
  }

  String? get apiDateFrom =>
      dateFrom == null ? null : _formatDate(dateFrom!);

  String? get apiDateTo => dateTo == null ? null : _formatDate(dateTo!);

  static String _formatDate(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String formatDisplayDate(DateTime d) => _formatDate(d);
}
