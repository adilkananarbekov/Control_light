import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'controllers/auth_controller.dart';
import 'controllers/light_controller.dart';
import 'controllers/theme_controller.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_gate.dart';
import 'services/bluetooth_manager.dart';

class ControlLightApp extends StatelessWidget {
  const ControlLightApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => BluetoothManager()),
        ChangeNotifierProvider(
          create: (ctx) => LightController(ctx.read<BluetoothManager>()),
        ),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Builder(
        builder: (context) {
          final themeMode = context.watch<ThemeController>().mode;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Lumen Control',
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: themeMode,
            home: const AuthGate(),
          );
        },
      ),
    );
  }
}
