import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../core/theme/app_colors.dart';
import '../admin/presentation/admin_panel_page.dart';
import '../control/presentation/control_panel_page.dart';
import '../profile/presentation/profile_page.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthController>().isAdmin;
    final themeCtrl = context.watch<ThemeController>();
    final palette = AppColors.of(Theme.of(context).brightness);
    final pages = <Widget>[
      const ControlPanelPage(),
      if (isAdmin) const AdminPanelPage(),
      const ProfilePage(),
    ];
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.lightbulb_outline),
        label: 'Control',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(Icons.admin_panel_settings),
          label: 'Admin',
        ),
      const NavigationDestination(
        icon: Icon(Icons.person_outline),
        label: 'Profile',
      ),
    ];
    final accents = <Color>[
      AppColors.accentCyan,
      if (isAdmin) AppColors.accentPurple,
      AppColors.accentGreen,
    ];
    final currentAccent = accents[index.clamp(0, accents.length - 1)];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Text(
          'Lumen Control',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle theme',
            icon: Icon(
              themeCtrl.isDark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () => themeCtrl.toggle(),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton(
              tooltip: 'Sign out',
              icon: const Icon(Icons.logout),
              onPressed: () => context.read<AuthController>().logout(),
            ),
          ),
        ],
      ),
      body: pages[index],
      bottomNavigationBar: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              palette.navSurface,
              currentAccent.withValues(alpha: 0.18),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(
            top: BorderSide(color: palette.navBorder),
          ),
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (i) => setState(() => index = i),
          backgroundColor: Colors.transparent,
          indicatorColor: currentAccent.withValues(alpha: 0.25),
          height: 74,
          destinations: destinations,
        ),
      ),
    );
  }
}
