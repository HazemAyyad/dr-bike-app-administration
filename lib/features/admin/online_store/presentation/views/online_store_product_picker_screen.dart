import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../../core/databases/api/end_points.dart';
import '../../data/online_store_models.dart';
import '../../domain/online_store_repository.dart';
import '../controllers/online_store_listings_controller.dart';

class OnlineStoreProductPickerScreen extends StatefulWidget {
  const OnlineStoreProductPickerScreen({Key? key}) : super(key: key);
  @override
  State<OnlineStoreProductPickerScreen> createState() =>
      _OnlineStoreProductPickerScreenState();
}

class _OnlineStoreProductPickerScreenState
    extends State<OnlineStoreProductPickerScreen> {
  final search = TextEditingController();
  List<Map<String, dynamic>> rows = const [];
  bool loading = false;

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final json = await Get.find<OnlineStoreRepository>().get(
        EndPoints.searchProducts,
        query: {'search': search.text.trim()},
      );
      setState(() => rows = onlineStoreRows(json['products'] ?? json['data']));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('اختيار منتج من المخزون')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onSubmitted: (_) => _load(),
              decoration: InputDecoration(
                hintText: 'اسم المنتج أو رقمه',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                    onPressed: _load, icon: const Icon(Icons.arrow_back)),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: rows.length,
                    itemBuilder: (_, index) {
                      final product = rows[index];
                      final id = (product['id'] as num?)?.toInt() ?? 0;
                      return ListTile(
                        title: Text('${product['name'] ?? 'منتج #$id'}'),
                        subtitle: const Text(
                            'السعر والمخزون يُداران من المنتج الأصلي'),
                        trailing: const Icon(Icons.add_circle_outline),
                        onTap: () async {
                          final listing =
                              await Get.find<OnlineStoreListingsController>()
                                  .create(id);
                          if (listing != null && mounted) {
                            Get.back(result: listing);
                          }
                        },
                      );
                    },
                  ),
          ),
        ]),
      );

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }
}
