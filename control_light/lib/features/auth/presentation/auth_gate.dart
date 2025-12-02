import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../controllers/auth_controller.dart';
import '../../dashboard/dashboard_shell.dart';
import 'auth_flow.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      child: user == null ? const AuthFlow() : const DashboardShell(),
    );
  }
}
