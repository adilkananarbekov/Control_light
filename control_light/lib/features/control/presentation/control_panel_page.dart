import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../controllers/light_controller.dart';
import '../../../core/extensions/iterable_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/light_block.dart';
import '../../../services/bluetooth_manager.dart';

class ControlPanelPage extends StatelessWidget {
  const ControlPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    final lights = context.watch<LightController>();
    final auth = context.watch<AuthController>();
    final bluetooth = context.watch<BluetoothManager>();
    final totalOn = lights.blocks.fold<int>(
      0,
      (sum, block) => sum + block.lights.where((l) => l).length,
    );
    final totalLights = lights.blocks.fold<int>(
      0,
      (sum, block) => sum + block.lights.length,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            palette.backgroundAlt,
            palette.background,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
        children: [
          _ConnectionCard(bluetooth: bluetooth),
          const SizedBox(height: 12),
          _SummaryCard(
            totalOn: totalOn,
            totalLights: totalLights,
            bluetooth: bluetooth,
          ),
          const SizedBox(height: 8),
          ...lights.blocks.mapIndexed((i, block) {
            final allowed = auth.canControlBlock(block.id);
            return BlockCard(
              index: i,
              block: block,
              allowed: allowed,
              onToggle: (lightIdx, value) {
                if (!allowed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You do not have permission for this block',
                      ),
                    ),
                  );
                  return;
                }
                context.read<LightController>().toggle(
                      block.id,
                      lightIdx,
                      value,
                    );
              },
              onToggleAll: (value) {
                if (!allowed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You do not have permission for this block',
                      ),
                    ),
                  );
                  return;
                }
                context.read<LightController>().toggleWholeBlock(
                      block.id,
                      value,
                    );
              },
            ).animate(delay: (80 * i).ms).fadeIn().slideY(begin: 0.08);
          }),
        ],
      ),
    );
  }
}

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({required this.bluetooth});
  final BluetoothManager bluetooth;

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  final TextEditingController _addressCtrl = TextEditingController();

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    final bt = widget.bluetooth;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: bt.connected
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.danger.withValues(alpha: 0.2),
                ),
                child: Icon(
                  bt.connected
                      ? Icons.bluetooth_connected
                      : Icons.bluetooth_disabled,
                  color: palette.textPrimary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bt.connected
                        ? 'HC-05 connected'
                        : 'Bluetooth idle (simulated)',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(
                          color: palette.textPrimary,
                        ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 180),
                    child: Text(
                      bt.statusText,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (bt.busy)
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _addressCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Device MAC / name',
                    hintText: "Leave empty for default Ma'Dory (98:D3:41:F7:24:A4)",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              FilledButton.icon(
                icon: Icon(bt.connected ? Icons.link_off : Icons.link),
                label: Text(bt.connected ? 'Disconnect' : 'Connect'),
                onPressed: bt.busy
                    ? null
                    : () {
                        if (bt.connected) {
                          bt.disconnect();
                        } else {
                          bt.connect(_addressCtrl.text.trim());
                        }
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalOn,
    required this.totalLights,
    required this.bluetooth,
  });

  final int totalOn;
  final int totalLights;
  final BluetoothManager bluetooth;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    final ratio = totalOn / totalLights;
    return GlassCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 92,
                  height: 92,
                  child: CircularProgressIndicator(
                    value: ratio,
                    strokeWidth: 8,
                    backgroundColor: palette.glassBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color.lerp(
                        AppColors.accentCyan,
                        AppColors.accentGreen,
                        ratio,
                      )!,
                    ),
                  ),
                ),
                Text(
                  '${(ratio * 100).round()}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lighting overview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: palette.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalOn of $totalLights lights are active',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: palette.textSecondary),
                ),
                const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    bluetooth.connected
                        ? Icons.check_circle
                        : Icons.warning_amber,
                    size: 18,
                    color: bluetooth.connected
                        ? AppColors.success
                        : AppColors.warning,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      bluetooth.connected
                          ? 'Live hardware mode'
                          : 'Simulated mode until connected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                  ),
                ],
              ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Turn all off',
            onPressed: () => context.read<LightController>().turnAll(false),
            icon: Icon(Icons.power_settings_new, color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

class BlockCard extends StatelessWidget {
  const BlockCard({
    super.key,
    required this.block,
    required this.allowed,
    required this.onToggle,
    required this.onToggleAll,
    required this.index,
  });

  final LightBlock block;
  final bool allowed;
  final void Function(int idx, bool value) onToggle;
  final void Function(bool value) onToggleAll;
  final int index;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    final activeCount = block.lights.where((l) => l).length;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            block.accent.withValues(alpha: 0.28),
            palette.glassSurface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.glassBorder),
        boxShadow: [
          BoxShadow(
            color: block.accent.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'block-${block.id}',
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: block.accent.withValues(alpha: 0.8),
                  ),
                  child: const Icon(Icons.light_mode, color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    block.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    '$activeCount / ${block.lights.length} lights on',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                          color: palette.textSecondary,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    allowed ? 'Allowed' : 'Locked',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color:
                              allowed ? palette.textPrimary : palette.textSecondary,
                        ),
                  ),
                  Switch(
                    value: block.lights.every((l) => l),
                    onChanged: allowed ? onToggleAll : null,
                    thumbIcon: WidgetStateProperty.all(
                      Icon(
                        block.lights.every((l) => l)
                            ? Icons.flash_on
                            : Icons.flashlight_off,
                        size: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < block.lights.length; i++)
                _LightPill(
                  index: i,
                  enabled: block.lights[i],
                  accent: block.accent,
                  onTap: () => onToggle(i, !block.lights[i]),
                  disabled: !allowed,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LightPill extends StatelessWidget {
  const _LightPill({
    required this.enabled,
    required this.onTap,
    required this.index,
    required this.accent,
    required this.disabled,
  });

  final bool enabled;
  final bool disabled;
  final VoidCallback onTap;
  final int index;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          color: enabled
              ? accent.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.04),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled ? Icons.circle : Icons.circle_outlined,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Light ${index + 1}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: palette.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
