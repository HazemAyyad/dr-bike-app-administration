import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/online_store_audit_controller.dart';
import '../widgets/online_store_state_view.dart';
import '../utils/online_store_admin_ui.dart';

class OnlineStoreAuditScreen extends GetView<OnlineStoreAuditController> {
  const OnlineStoreAuditScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('سجل تدقيق المتجر')),
        body: Column(children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Wrap(spacing: 8, runSpacing: 8, children: [
              Obx(() => DropdownButton<String>(
                    value: controller.entityType.value,
                    items: const [
                      'all',
                      'listing',
                      'promotion',
                      'coupon',
                      'settings',
                      'account_link',
                      'credit_policy',
                      'review',
                      'pricing'
                    ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) => controller.entityType.value = v ?? 'all',
                  )),
              Obx(() => DropdownButton<String>(
                    value: controller.actionFilter.value,
                    items: const [
                      'all',
                      'created',
                      'updated',
                      'linked',
                      'approved',
                      'suspended',
                      'activated',
                      'deactivated',
                      'published',
                      'hidden',
                      'status_changed',
                      'moderated',
                      'previewed'
                    ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                    onChanged: (v) =>
                        controller.actionFilter.value = v ?? 'all',
                  )),
              SizedBox(
                width: 110,
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'رقم المنفذ'),
                  onChanged: (v) => controller.actorUserId.value = v,
                ),
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'من'),
                  onChanged: (v) => controller.from.value = v,
                ),
              ),
              SizedBox(
                width: 130,
                child: TextField(
                  decoration: const InputDecoration(labelText: 'إلى'),
                  onChanged: (v) => controller.to.value = v,
                ),
              ),
              OutlinedButton.icon(
                style: OnlineStoreAdminUi.actionButtonStyle,
                onPressed: controller.applyFilters,
                icon: const Icon(Icons.filter_alt_outlined),
                label: const Text('تطبيق'),
              ),
            ]),
          ),
          Expanded(
              child: Obx(() => OnlineStoreStateView(
                    loading: controller.loading.value,
                    error: controller.error.value,
                    isEmpty: controller.items.isEmpty,
                    onRetry: controller.applyFilters,
                    child: ListView.builder(
                      itemCount: controller.items.length,
                      itemBuilder: (_, index) {
                        final event = controller.items[index].values;
                        return ExpansionTile(
                          title: Text(
                              '${event['action'] ?? '—'} • ${event['entity_type'] ?? '—'} #${event['entity_id'] ?? '—'}'),
                          subtitle: Text('${event['occurred_at'] ?? ''}'),
                          children: [
                            ListTile(
                                title: const Text('قبل (منقح)'),
                                subtitle:
                                    Text('${event['before_values'] ?? {}}')),
                            ListTile(
                                title: const Text('بعد (منقح)'),
                                subtitle:
                                    Text('${event['after_values'] ?? {}}')),
                          ],
                        );
                      },
                    ),
                  ))),
        ]),
      );
}
