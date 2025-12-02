import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../../core/extensions/iterable_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../models/user_account.dart';

class AdminPanelPage extends StatelessWidget {
  const AdminPanelPage({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              palette.backgroundAdmin,
              palette.background,
            ],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  Icon(Icons.admin_panel_settings, color: palette.textPrimary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin panel - manage users and their block access',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.person_add),
                    label: const Text('New user'),
                    onPressed: () => _openNewUserSheet(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            ...auth.users.mapIndexed((i, user) {
              return GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.role == UserRole.admin
                                ? AppColors.accentPurple.withValues(alpha: 0.2)
                                : AppColors.accentCyan.withValues(alpha: 0.2),
                          ),
                          child: Icon(
                            user.role == UserRole.admin
                                ? Icons.key
                                : Icons.person,
                            color: palette.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: palette.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                            Text(
                              user.email,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: palette.textSecondary),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _RoleChip(user: user, auth: auth),
                        IconButton(
                          tooltip: 'Delete user',
                          onPressed: user.id == auth.currentUser?.id
                              ? null
                              : () => auth.deleteUser(user.id),
                          icon: Icon(
                            Icons.delete_outline,
                            color: palette.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Block permissions',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(
                            color: palette.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: auth.blockTemplates.map((blockId) {
                        final allowed = user.access[blockId] ?? false;
                        return FilterChip(
                          label: Text(
                            blockId.toUpperCase(),
                            style: TextStyle(color: palette.textPrimary),
                          ),
                          selected: allowed,
                          selectedColor:
                              AppColors.accentGreen.withValues(alpha: 0.4),
                          backgroundColor: palette.glassSurface,
                          onSelected: (value) {
                            auth.updateUserAccess(
                              userId: user.id,
                              blockId: blockId,
                              allowed: value,
                            );
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: palette.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Created ${_relative(user.createdAt)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: palette.textMuted),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.07);
            }),
          ],
        ),
      ),
    );
  }

  String _relative(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _openNewUserSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final auth = context.read<AuthController>();
    final access = <String, bool>{
      for (final b in auth.blockTemplates) b: false,
    };
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.black.withValues(alpha: 0.6),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'New member',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) => v == null || !v.contains('@')
                      ? 'Valid email required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Temp password'),
                  validator: (v) =>
                      v == null || v.length < 4 ? 'Min 4 chars' : null,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: auth.blockTemplates.map((blockId) {
                    return FilterChip(
                      label: Text(
                        blockId.toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                      selected: access[blockId] ?? false,
                      onSelected: (value) {
                        access[blockId] = value;
                        (ctx as Element).markNeedsBuild();
                      },
                      selectedColor: Colors.green.withValues(alpha: 0.3),
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: () {
                    if (!formKey.currentState!.validate()) return;
                    final err = auth.register(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      password: passCtrl.text.trim(),
                      accessOverride: access,
                    );
                    if (err != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }
                    Navigator.of(ctx).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User ${nameCtrl.text.trim()} added'),
                      ),
                    );
                  },
                  child: const Text('Create'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.user, required this.auth});

  final UserAccount user;
  final AuthController auth;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.of(Theme.of(context).brightness);
    return InkWell(
      onTap: () {
        final newRole = user.role == UserRole.admin
            ? UserRole.operator
            : UserRole.admin;
        auth.updateUser(user.id, role: newRole);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: user.role == UserRole.admin
              ? AppColors.accentPurple.withValues(alpha: 0.25)
              : palette.glassSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: palette.glassBorder),
        ),
        child: Row(
          children: [
            Icon(
              user.role == UserRole.admin ? Icons.key : Icons.shield_moon,
              color: palette.textPrimary,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              user.role == UserRole.admin ? 'Admin' : 'Operator',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: palette.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}
