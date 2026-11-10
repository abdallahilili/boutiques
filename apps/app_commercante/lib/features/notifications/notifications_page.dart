import 'package:flutter/material.dart';
import 'package:get/get.dart' hide Value;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/session/shop_controller.dart';
import '../../core/types/database_types.dart';
import '../../core/util/errors.dart';
import '../../core/util/format.dart';
import '../../core/widgets/common.dart';
import '../../l10n/app_localizations.dart';

/// Notifications in-app (nouvelles commandes, annonces de l'éditeur). Le push FCM sera branché plus tard.
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _client = Get.find<SupabaseClient>();
  late Future<List<Map<String, dynamic>>> _future = _load();

  Future<List<Map<String, dynamic>>> _load() => _client.from(Tables.notifications).select().eq('utilisateur_id', Get.find<ShopController>().userId).order('cree_le', ascending: false).limit(100);

  Future<void> _markRead(Map<String, dynamic> n) async {
    if (n['lu_le'] != null) return;
    await _client.from(Tables.notifications).update({'lu_le': DateTime.now().toUtc().toIso8601String()}).eq('id', n['id'] as String);
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Scaffold(
      appBar: AppBar(title: Text(l10n.menuNotifications)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return ErrorView(message: friendlyError(l10n, snapshot.error!));
          final items = snapshot.data!;
          if (items.isEmpty) return const EmptyState(icon: Icons.notifications_none);
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final n = items[i];
              final unread = n['lu_le'] == null;
              return ListTile(
                leading: Icon(unread ? Icons.notifications_active : Icons.notifications_none, color: unread ? Theme.of(context).colorScheme.primary : null),
                title: Text(localName(n['titre_ar'] as String?, n['titre_fr'] as String?, arabic: arabic), style: TextStyle(fontWeight: unread ? FontWeight.bold : null)),
                subtitle: Text('${localName(n['corps_ar'] as String?, n['corps_fr'] as String?, arabic: arabic)}\n${formatDate(DateTime.parse(n['cree_le'] as String), Localizations.localeOf(context), time: true)}'),
                isThreeLine: true,
                onTap: () => _markRead(n),
              );
            },
          );
        },
      ),
    );
  }
}
