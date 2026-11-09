import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/locale/locale_controller.dart';
import '../../l10n/app_localizations.dart';
import '../auth/presentation/auth_controller.dart';

/// Coque de navigation : Accueil, Vente (POS), Produits, Stock, Plus.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final titles = [l10n.tabHome, l10n.tabSell, l10n.tabProducts, l10n.tabStock, l10n.tabMore];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(
        index: _index,
        children: [
          Center(child: Text(l10n.tabHome)),
          Center(child: Text(l10n.tabSell)),
          Center(child: Text(l10n.tabProducts)),
          Center(child: Text(l10n.tabStock)),
          const _MoreTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: l10n.tabHome),
          NavigationDestination(icon: const Icon(Icons.point_of_sale_outlined), selectedIcon: const Icon(Icons.point_of_sale), label: l10n.tabSell),
          NavigationDestination(icon: const Icon(Icons.inventory_2_outlined), selectedIcon: const Icon(Icons.inventory_2), label: l10n.tabProducts),
          NavigationDestination(icon: const Icon(Icons.warehouse_outlined), selectedIcon: const Icon(Icons.warehouse), label: l10n.tabStock),
          NavigationDestination(icon: const Icon(Icons.menu), label: l10n.tabMore),
        ],
      ),
    );
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Get.find<LocaleController>();
    final auth = Get.find<AuthController>();

    return ListView(
      children: [
        Obx(
          () => ListTile(
            leading: const Icon(Icons.language),
            title: Text(l10n.language),
            trailing: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'ar', label: Text(l10n.arabic)),
                ButtonSegment(value: 'fr', label: Text(l10n.french)),
              ],
              selected: {locale.locale.value.languageCode},
              onSelectionChanged: (s) => locale.setLocale(Locale(s.first)),
            ),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
          title: Text(l10n.logout),
          onTap: auth.signOut,
        ),
      ],
    );
  }
}
