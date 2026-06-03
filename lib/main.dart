import 'dart:io';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:win32_registry/win32_registry.dart';
import 'screens/floating_window.dart';
import 'services/config_service.dart';
import 'services/tray_service.dart';
import 'services/window_service.dart';

final configService = ConfigService();
final trayService = TrayService();
final GlobalKey<FloatingWindowState> floatingKey = GlobalKey();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configService.load();
  await WindowService.setup(
    configService.windowX,
    configService.windowY,
    configService.alwaysOnTop,
  );

  // Close → hide to tray: prevent close, hide instead
  await windowManager.setPreventClose(true);

  _setupAutoStart();
  await _setupTray();
  runApp(const DeepSeekBalanceApp());
}

void _setupAutoStart() {
  if (!Platform.isWindows) return;
  try {
    final exePath = Platform.resolvedExecutable;
    final hkcu = Registry.openPath(RegistryHive.currentUser);
    final runKey = hkcu.createKey(r'Software\Microsoft\Windows\CurrentVersion\Run');
    if (configService.autoStart) {
      runKey.createValue(RegistryValue(
        'DeepSeekBalance',
        RegistryValueType.string,
        exePath.codeUnits,
      ));
    } else {
      try { runKey.deleteValue('DeepSeekBalance'); } catch (_) {}
    }
  } catch (_) {}
}

Future<void> _setupTray() async {
  trayService.onShow = () => WindowService.showWindow();
  trayService.onHide = () => WindowService.hideWindow();
  trayService.onRefresh = () => floatingKey.currentState?.triggerPoll();
  trayService.onSettings = () {
    WindowService.showWindow();
    floatingKey.currentState?.openSettings();
  };
  trayService.onQuit = () async {
    await trayService.destroy();
    exit(0);
  };

  final ok = await trayService.init();
  if (!ok) {
    // Tray not available, app continues without it
  }
}

class DeepSeekBalanceApp extends StatelessWidget {
  const DeepSeekBalanceApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: FloatingWindow(key: floatingKey, config: configService),
    );
  }
}
