import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FinancialImageCache {
  FinancialImageCache._();

  static final CacheManager instance = CacheManager(
    Config(
      'doctorBikeFinancialMediaV1',
      stalePeriod: const Duration(days: 180),
      maxNrOfCacheObjects: 1500,
    ),
  );
}
