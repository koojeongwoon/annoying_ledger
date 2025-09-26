import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:annoying_ledger/features/auth/controllers/auth_controller.dart';
import 'package:annoying_ledger/features/auth/models/resource_access.dart';
import 'package:annoying_ledger/features/auth/models/user_profile.dart';
import 'package:annoying_ledger/features/home/widgets/menu_tree_view.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;
        return Consumer<AuthController>(
          builder: (context, auth, _) {
            final profile = auth.profile;
            final menuNodes = auth.menuTree;
            final accessibleMenus = auth.accessibleMenus;
            final refreshCallback = auth.isBusy
                ? null
                : () => _refreshMenus(context);
            final mainContent = _buildMainContent(
              context,
              auth,
              menuNodes,
              profile,
              isWide,
            );

            return isWide
                ? _buildWideScaffold(
                    context,
                    auth,
                    accessibleMenus,
                    refreshCallback,
                    mainContent,
                  )
                : _buildCompactScaffold(
                    context,
                    auth,
                    accessibleMenus,
                    refreshCallback,
                    mainContent,
                  );
          },
        );
      },
    );
  }

  Scaffold _buildCompactScaffold(
    BuildContext context,
    AuthController auth,
    List<ResourceAccessItem> accessibleMenus,
    Future<void> Function()? refreshCallback,
    Widget mainContent,
  ) {
    return Scaffold(
      appBar: _buildAppBar(context, auth, refreshCallback),
      drawer: Drawer(
        child: _AccessPanel(
          profile: auth.profile,
          menus: accessibleMenus,
          onRefresh: refreshCallback,
          closeOnNavigate: true,
        ),
      ),
      body: mainContent,
    );
  }

  Scaffold _buildWideScaffold(
    BuildContext context,
    AuthController auth,
    List<ResourceAccessItem> accessibleMenus,
    Future<void> Function()? refreshCallback,
    Widget mainContent,
  ) {
    return Scaffold(
      appBar: _buildAppBar(context, auth, refreshCallback),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: 320,
              child: Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                child: _AccessPanel(
                  profile: auth.profile,
                  menus: accessibleMenus,
                  onRefresh: refreshCallback,
                  closeOnNavigate: false,
                ),
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: mainContent),
        ],
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    AuthController auth,
    Future<void> Function()? refreshCallback,
  ) {
    return AppBar(
      title: const Text('Annoying Ledger'),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: '권한 새로고침',
          onPressed: refreshCallback,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: '로그아웃',
          onPressed: auth.isBusy ? null : () => _confirmLogout(context),
        ),
      ],
    );
  }

  Widget _buildMainContent(
    BuildContext context,
    AuthController auth,
    List<MenuNode> menuNodes,
    UserProfile? profile,
    bool isWide,
  ) {
    final padding = EdgeInsets.symmetric(
      horizontal: isWide ? 32 : 16,
      vertical: isWide ? 24 : 16,
    );

    final content = profile == null
        ? const Center(child: Text('사용자 정보를 불러오지 못했습니다.'))
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileHeader(profile: profile),
              const Divider(height: 1),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => _refreshMenus(context),
                  child: MenuTreeView(nodes: menuNodes),
                ),
              ),
            ],
          );

    return SafeArea(
      child: Padding(padding: padding, child: content),
    );
  }

  Future<void> _refreshMenus(BuildContext context) {
    final auth = context.read<AuthController>();
    return auth.refreshResources();
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final auth = context.read<AuthController>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('로그아웃'),
          content: const Text('현재 세션에서 로그아웃할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('로그아웃'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await auth.logout();
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final created = profile.createdAt.toLocal();
    final createdText = _formatUserDateTime(created);
    final subtitle = [profile.email, '가입: $createdText'];
    if (profile.age != null) {
      subtitle.insert(1, '나이: ${profile.age}세');
    }

    return ListTile(
      leading: CircleAvatar(child: Text(_userInitial(profile).toUpperCase())),
      title: Text(
        _userDisplayName(profile),
        style: theme.textTheme.titleMedium,
      ),
      subtitle: Text(subtitle.join(' · ')),
    );
  }
}

class _AccessPanel extends StatelessWidget {
  const _AccessPanel({
    required this.profile,
    required this.menus,
    required this.onRefresh,
    required this.closeOnNavigate,
  });

  final UserProfile? profile;
  final List<ResourceAccessItem> menus;
  final Future<void> Function()? onRefresh;
  final bool closeOnNavigate;

  @override
  Widget build(BuildContext context) {
    final sortedMenus = List<ResourceAccessItem>.from(menus)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (profile != null)
            UserAccountsDrawerHeader(
              accountName: Text(_userDisplayName(profile!)),
              accountEmail: Text(profile!.email),
              currentAccountPicture: CircleAvatar(
                child: Text(_userInitial(profile!).toUpperCase()),
              ),
            )
          else
            const DrawerHeader(
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text('프로필 정보를 불러오지 못했습니다.'),
              ),
            ),
          ListTile(
            leading: const Icon(Icons.refresh),
            title: const Text('권한 새로고침'),
            enabled: onRefresh != null,
            onTap: onRefresh == null
                ? null
                : () async {
                    if (closeOnNavigate) {
                      Navigator.of(context).pop();
                    }
                    await onRefresh!.call();
                  },
          ),
          const Divider(height: 1),
          Expanded(
            child: sortedMenus.isEmpty
                ? const Center(child: Text('접근 가능한 메뉴가 없습니다.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemBuilder: (context, index) {
                      final menu = sortedMenus[index];
                      return ListTile(
                        leading: const Icon(Icons.check_circle_outline),
                        title: Text(menu.displayName),
                        subtitle: Text('코드: ${menu.code}'),
                      );
                    },
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemCount: sortedMenus.length,
                  ),
          ),
        ],
      ),
    );
  }
}

String _formatUserDateTime(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  final hh = date.hour.toString().padLeft(2, '0');
  final mm = date.minute.toString().padLeft(2, '0');
  return '$y-$m-$d $hh:$mm';
}

String _userInitial(UserProfile profile) {
  final trimmedName = profile.name.trim();
  if (trimmedName.isNotEmpty) {
    return trimmedName.substring(0, 1);
  }
  final trimmedEmail = profile.email.trim();
  if (trimmedEmail.isNotEmpty) {
    return trimmedEmail.substring(0, 1);
  }
  return '?';
}

String _userDisplayName(UserProfile profile) {
  return profile.name.isEmpty ? profile.email : profile.name;
}
