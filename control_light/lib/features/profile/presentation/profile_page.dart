import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/light_controller.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/user_account.dart';
import '../../../services/bluetooth_manager.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser!;
    final lights = context.watch<LightController>();
    final palette = AppColors.of(Theme.of(context).brightness);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.backgroundSoft,
            palette.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
        children: [
          const SizedBox(height: 12),
          GlassCard(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4DD0E1), Color(0xFF7C4DFF)],
                    ),
                  ),
                  child: Icon(Icons.person, color: palette.textPrimary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      user.email,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
                    ),
                    Text(
                      'Role: ${user.role == UserRole.admin ? 'Admin' : 'Operator'}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => context.read<AuthController>().logout(),
                  icon: Icon(Icons.logout, color: palette.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Access map',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 8),
                ...context.read<AuthController>().blockTemplates.map((blockId) {
                  final allowed =
                      user.role == UserRole.admin ||
                      user.access[blockId] == true;
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      allowed ? Icons.check_circle : Icons.cancel,
                      color: allowed ? AppColors.success : palette.textSecondary,
                    ),
                    title: Text(
                      blockId.toUpperCase(),
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: palette.textPrimary),
                    ),
                    subtitle: Text(
                      allowed ? 'Full control' : 'No access',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: palette.textSecondary),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Live snapshot',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _MetricTile(
                      value: lights.blocks.length.toString(),
                      label: 'Blocks',
                      icon: Icons.grid_view,
                      palette: palette,
                    ),
                    _MetricTile(
                      value: lights.blocks
                          .fold<int>(
                            0,
                            (sum, b) => sum + b.lights.where((e) => e).length,
                          )
                          .toString(),
                      label: 'Lights on',
                      icon: Icons.lightbulb,
                      palette: palette,
                    ),
                    _MetricTile(
                      value: context.read<BluetoothManager>().connected
                          ? 'Live'
                          : 'Sim',
                      label: 'Mode',
                      icon: Icons.bluetooth,
                      palette: palette,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.palette,
  });

  final String value;
  final String label;
  final IconData icon;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: palette.glassSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.glassBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: palette.textSecondary, size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
