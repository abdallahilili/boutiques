import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;

import '../../core/db/app_database.dart';
import '../../core/session/shop_controller.dart';
import '../../core/sync/sync_service.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';

/// État de la synchronisation : opérations en attente, opérations refusées par le serveur (relancer / abandonner).
class SyncPage extends StatelessWidget {
  const SyncPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sync = Get.find<SyncService>();
    final db = Get.find<AppDatabase>();
    final shop = Get.find<ShopController>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuSync)),
      body: ListView(children: [
        Obx(() => ListTile(
              leading: Icon(sync.online.value ? Icons.cloud_done_outlined : Icons.cloud_off_outlined),
              title: Text(sync.online.value ? l10n.synced : l10n.offlineBanner),
              subtitle: sync.lastSync.value == null ? null : Text(l10n.lastSync(formatDate(sync.lastSync.value!, Localizations.localeOf(context), time: true))),
              trailing: sync.syncing.value ? const CircularProgressIndicator() : IconButton(icon: const Icon(Icons.sync), onPressed: sync.syncAll),
            )),
        StreamBuilder<int>(stream: db.watchPendingCount(shop.shopId), builder: (context, snapshot) => ListTile(leading: const Icon(Icons.outbox_outlined), title: Text(l10n.syncPending(snapshot.data ?? 0)))),
        const Divider(),
        Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 0), child: Text(l10n.syncIssuesTitle, style: Theme.of(context).textTheme.titleMedium)),
        Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 8), child: Text(l10n.syncIssuesHint, style: Theme.of(context).textTheme.bodySmall)),
        StreamBuilder<List<OutboxItem>>(
          stream: db.watchFailedItems(shop.shopId),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <OutboxItem>[];
            if (items.isEmpty) return const Padding(padding: EdgeInsets.all(24), child: Center(child: Icon(Icons.check_circle_outline, color: Colors.green, size: 40)));
            return Column(children: [
              for (final item in items)
                ListTile(
                  leading: const Icon(Icons.error_outline, color: Colors.red),
                  title: Text(item.kind),
                  subtitle: Text(item.lastError ?? ''),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.refresh), tooltip: l10n.retry, onPressed: () async { await db.retryFailed(item.id); await sync.syncAll(); }),
                    IconButton(icon: const Icon(Icons.delete_outline), tooltip: l10n.discard, onPressed: () async { if (await confirmDialog(context, title: l10n.discard)) await db.removeOutbox(item.id); }),
                  ]),
                ),
            ]);
          },
        ),
      ]),
    );
  }
}
