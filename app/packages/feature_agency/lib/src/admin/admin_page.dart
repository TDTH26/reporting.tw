import 'package:flutter/material.dart';

import '../common/l10n.dart';
import 'feed_clients_admin.dart';
import 'templates_admin.dart';
import 'users_admin.dart';
import 'zone_editor.dart';

class AdminPage extends StatelessWidget {
  const AdminPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l;
    return DefaultTabController(
      length: 4,
      child: Column(children: [
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: [
            Tab(icon: const Icon(Icons.layers_outlined), text: l.tabZones),
            Tab(icon: const Icon(Icons.text_snippet_outlined), text: l.tabTemplates),
            Tab(icon: const Icon(Icons.vpn_key_outlined), text: l.tabFeedClients),
            Tab(icon: const Icon(Icons.people_outline), text: l.tabUsers),
          ],
        ),
        const Divider(height: 1),
        const Expanded(
          child: TabBarView(
            physics: NeverScrollableScrollPhysics(),
            children: [ZonesAdmin(), TemplatesAdmin(), FeedClientsAdmin(), UsersAdmin()],
          ),
        ),
      ]),
    );
  }
}
