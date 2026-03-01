import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common_widgets.dart';

class NavItem {
  final IconData icon;
  final String label;
  final String path;

  const NavItem({
    required this.icon,
    required this.label,
    required this.path,
  });
}

const navItems = [
  NavItem(icon: Icons.dashboard_outlined, label: 'Overview', path: '/dashboard'),
  NavItem(icon: Icons.inventory_2_outlined, label: 'Registered Objects', path: '/dashboard/objects'),
  NavItem(icon: Icons.add_circle_outline, label: 'Add Object', path: '/dashboard/add-object'),
  NavItem(icon: Icons.camera_alt_outlined, label: 'Live Camera', path: '/dashboard/camera'),
  NavItem(icon: Icons.notifications_outlined, label: 'Alerts & History', path: '/dashboard/alerts'),
  NavItem(icon: Icons.smartphone_outlined, label: 'Phone Recovery', path: '/dashboard/phone-recovery'),
  NavItem(icon: Icons.bluetooth_outlined, label: 'Device Connections', path: '/dashboard/bluetooth'),
  NavItem(icon: Icons.settings_outlined, label: 'Settings', path: '/dashboard/settings'),
];

class MainDashboard extends StatefulWidget {
  final Widget child;

  const MainDashboard({super.key, required this.child});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  bool _drawerOpen = false;

  String _getCurrentPath(BuildContext context) {
    return GoRouterState.of(context).matchedLocation;
  }

  int _getCurrentIndex(String path) {
    for (int i = 0; i < navItems.length; i++) {
      if (navItems[i].path == path) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 768;
    final currentPath = _getCurrentPath(context);
    final currentIndex = _getCurrentIndex(currentPath);

    if (isWide) {
      return _buildWideLayout(context, currentPath, currentIndex);
    }
    return _buildNarrowLayout(context, currentPath, currentIndex);
  }

  Widget _buildWideLayout(
      BuildContext context, String currentPath, int currentIndex) {
    return PulseBackground(
      child: Row(
        children: [
          _buildSidebar(context, currentPath),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(context),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowLayout(
      BuildContext context, String currentPath, int currentIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PulseBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: Drawer(
          child: _buildSidebar(context, currentPath, isDrawer: true),
        ),
        appBar: AppBar(
          backgroundColor: isDark
              ? const Color(0xFF1E293B).withOpacity(0.8)
              : Colors.white.withOpacity(0.8),
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
          title: const PulseLogo(size: 32),
          actions: [
            _ThemeToggleButton(),
            const SizedBox(width: 8),
          ],
        ),
        body: widget.child,
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, String currentPath,
      {bool isDrawer = false}) {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final sidebarBg = isDark
        ? const Color(0xFF1E293B).withOpacity(0.8)
        : Colors.white.withOpacity(0.8);

    return Container(
      width: 256,
      height: double.infinity,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const PulseLogo(size: 36),
          ),
          const SizedBox(height: 24),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...navItems.map((item) {
                  final isActive = currentPath == item.path;
                  return _NavItemTile(
                    item: item,
                    isActive: isActive,
                    onTap: () {
                      if (isDrawer) Navigator.pop(context);
                      context.go(item.path);
                    },
                  );
                }),
              ],
            ),
          ),

          // Bottom section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _ThemeToggleButton(showLabel: true),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton.icon(
                    onPressed: () async {
                      await auth.signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout, color: Colors.red),
                    label: const Text('Sign Out',
                        style: TextStyle(color: Colors.red)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    auth.user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF94A3B8),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withOpacity(0.8)
            : Colors.white.withOpacity(0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          _ThemeToggleButton(),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              auth.user?.email ?? '',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF94A3B8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemTile extends StatelessWidget {
  final NavItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItemTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                )
              : null,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 20,
              color: isActive ? Colors.white : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.w400,
                  color: isActive ? Colors.white : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeToggleButton extends StatelessWidget {
  final bool showLabel;

  const _ThemeToggleButton({this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    if (showLabel) {
      return SizedBox(
        width: double.infinity,
        child: TextButton.icon(
          onPressed: theme.toggleTheme,
          icon: Icon(
            isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            size: 20,
          ),
          label: Text(isDark ? 'Light Mode' : 'Dark Mode'),
          style: TextButton.styleFrom(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            alignment: Alignment.centerLeft,
          ),
        ),
      );
    }

    return IconButton(
      onPressed: theme.toggleTheme,
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
      ),
      tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
    );
  }
}
