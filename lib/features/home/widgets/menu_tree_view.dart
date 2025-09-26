import 'package:flutter/material.dart';

import 'package:annoying_ledger/features/auth/models/resource_access.dart';

class MenuTreeView extends StatelessWidget {
  const MenuTreeView({super.key, required this.nodes});

  final List<MenuNode> nodes;

  @override
  Widget build(BuildContext context) {
    if (nodes.isEmpty) {
      return const Center(child: Text('접근 가능한 메뉴가 없습니다.'));
    }

    final tiles = _buildTiles(nodes);
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      physics: const AlwaysScrollableScrollPhysics(),
      children: tiles,
    );
  }

  List<Widget> _buildTiles(List<MenuNode> nodes, {int depth = 0}) {
    final List<Widget> tiles = [];
    for (final node in nodes) {
      tiles.add(_MenuTile(node: node, depth: depth));
      if (node.children.isNotEmpty) {
        tiles.addAll(_buildTiles(node.children, depth: depth + 1));
      }
    }
    return tiles;
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.node, required this.depth});

  final MenuNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final item = node.item;
    final indent = 16.0 + depth * 20.0;
    final theme = Theme.of(context);

    return ListTile(
      contentPadding: EdgeInsets.only(left: indent, right: 16),
      leading: depth == 0
          ? const Icon(Icons.menu)
          : Icon(
              Icons.subdirectory_arrow_right,
              color: theme.colorScheme.primary,
            ),
      title: Text(item.displayName),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('코드: ${item.code}'),
          if (item.allowedActions.isNotEmpty || item.deniedActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final action in item.allowedActions)
                    Chip(
                      label: Text(action),
                      backgroundColor: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.6),
                    ),
                  for (final action in item.deniedActions)
                    Chip(
                      label: Text(action),
                      backgroundColor: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.6),
                    ),
                ],
              ),
            ),
        ],
      ),
      trailing: node.children.isNotEmpty
          ? Text('${node.children.length}')
          : null,
    );
  }
}
