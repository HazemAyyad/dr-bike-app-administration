class StockImagesExportModel {
  const StockImagesExportModel({
    required this.id,
    required this.status,
    required this.totalProducts,
    required this.processedProducts,
    required this.imagesAdded,
    required this.fileName,
    required this.fileSizeHuman,
    required this.errorMessage,
    required this.createdAt,
    required this.startedAt,
    required this.completedAt,
    required this.downloadUrl,
    required this.sourceSummary,
  });

  final String id;
  final String status;
  final int totalProducts;
  final int processedProducts;
  final int imagesAdded;
  final String fileName;
  final String fileSizeHuman;
  final String errorMessage;
  final String createdAt;
  final String startedAt;
  final String completedAt;
  final String downloadUrl;
  final StockImagesExportSourceSummary sourceSummary;

  bool get isCompleted => status == 'completed';
  bool get isRunning => status == 'pending' || status == 'processing';
  bool get isFailed => status == 'failed';
  bool get isDeleted => status == 'deleted';

  double get progress {
    if (totalProducts <= 0) {
      return isCompleted ? 1 : 0;
    }
    final value = processedProducts / totalProducts;
    return value.clamp(0, 1).toDouble();
  }

  factory StockImagesExportModel.fromJson(Map<String, dynamic> json) {
    return StockImagesExportModel(
      id: _string(json['id']),
      status: _string(json['status']),
      totalProducts: _int(json['total_products']),
      processedProducts: _int(json['processed_products']),
      imagesAdded: _int(json['images_added']),
      fileName: _string(json['file_name']),
      fileSizeHuman: _string(json['file_size_human']),
      errorMessage: _string(json['error_message']),
      createdAt: _string(json['created_at']),
      startedAt: _string(json['started_at']),
      completedAt: _string(json['completed_at']),
      downloadUrl: _string(json['download_url']),
      sourceSummary: StockImagesExportSourceSummary.fromJson(
        json['source_summary'] is Map
            ? Map<String, dynamic>.from(json['source_summary'] as Map)
            : const <String, dynamic>{},
      ),
    );
  }
}

class StockImagesExportSourceSummary {
  const StockImagesExportSourceSummary({
    required this.sources,
    required this.tables,
    required this.linksSeen,
    required this.imagesAdded,
    required this.missingImages,
  });

  final List<StockImagesExportSourceCount> sources;
  final List<StockImagesExportTableCount> tables;
  final int linksSeen;
  final int imagesAdded;
  final int missingImages;

  factory StockImagesExportSourceSummary.fromJson(Map<String, dynamic> json) {
    return StockImagesExportSourceSummary(
      sources: _list(json['sources'])
          .whereType<Map>()
          .map((e) => StockImagesExportSourceCount.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      tables: _list(json['tables'])
          .whereType<Map>()
          .map((e) => StockImagesExportTableCount.fromJson(
                Map<String, dynamic>.from(e),
              ))
          .toList(),
      linksSeen: _int(json['links_seen']),
      imagesAdded: _int(json['images_added']),
      missingImages: _int(json['missing_images']),
    );
  }
}

class StockImagesExportSourceCount {
  const StockImagesExportSourceCount({
    required this.label,
    required this.imagesAdded,
  });

  final String label;
  final int imagesAdded;

  factory StockImagesExportSourceCount.fromJson(Map<String, dynamic> json) {
    return StockImagesExportSourceCount(
      label: _string(json['label']),
      imagesAdded: _int(json['images_added']),
    );
  }
}

class StockImagesExportTableCount {
  const StockImagesExportTableCount({
    required this.label,
    required this.linksSeen,
    required this.imagesAdded,
    required this.missingImages,
  });

  final String label;
  final int linksSeen;
  final int imagesAdded;
  final int missingImages;

  factory StockImagesExportTableCount.fromJson(Map<String, dynamic> json) {
    return StockImagesExportTableCount(
      label: _string(json['label']),
      linksSeen: _int(json['links_seen']),
      imagesAdded: _int(json['images_added']),
      missingImages: _int(json['missing_images']),
    );
  }
}

List<dynamic> _list(dynamic value) => value is List ? value : const [];

String _string(dynamic value) => value?.toString() ?? '';

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
