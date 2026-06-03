import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

const Color glassBg = Color(0xF0F4F4F8);

class WindowService {
  static const Size normalSize = Size(210, 62);
  static const Size settingsSize = Size(380, 420);

  static Future<void> setup(double? savedX, double? savedY, bool alwaysOnTop) async {
    await windowManager.ensureInitialized();

    final options = WindowOptions(
      size: normalSize,
      minimumSize: const Size(190, 50),
      backgroundColor: glassBg,
      skipTaskbar: true,
      titleBarStyle: TitleBarStyle.hidden,
      alwaysOnTop: alwaysOnTop,
    );

    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });

    final x = savedX ?? 1500;
    final y = savedY ?? 30;
    await windowManager.setPosition(Offset(x, y));
  }

  static Future<void> resizeForSettings() async {
    await windowManager.setMinimumSize(settingsSize);
    await windowManager.setSize(settingsSize);
  }

  static Future<void> resizeToNormal() async {
    await windowManager.setMinimumSize(normalSize);
    await windowManager.setSize(normalSize);
  }

  static Future<void> setAlwaysOnTop(bool on) async {
    await windowManager.setAlwaysOnTop(on);
  }

  static Future<void> showWindow() async {
    await windowManager.show();
    await windowManager.focus();
  }

  static Future<void> hideWindow() async {
    await windowManager.hide();
  }
}
