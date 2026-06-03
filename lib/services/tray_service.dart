import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tray_manager/tray_manager.dart';

class TrayService {
  bool _ready = false;

  void Function()? onShow;
  void Function()? onHide;
  void Function()? onRefresh;
  void Function()? onSettings;
  void Function()? onQuit;

  Future<bool> init() async {
    try {
      final iconPath = await _generateIcon();

      trayManager.addListener(_TrayHandler(
        onShow: onShow,
        onHide: onHide,
        onRefresh: onRefresh,
        onSettings: onSettings,
        onQuit: onQuit,
      ));

      await trayManager.setIcon(iconPath);
      await trayManager.setToolTip('DeepSeek Balance');

      try {
        final menu = Menu(items: [
          MenuItem(key: 'show', label: '显示窗口'),
          MenuItem(key: 'hide', label: '隐藏窗口'),
          MenuItem(key: 'settings', label: '设置'),
          MenuItem(key: 'refresh', label: '刷新'),
          MenuItem.separator(),
          MenuItem(key: 'quit', label: '退出'),
        ]);
        await trayManager.setContextMenu(menu);
      } catch (_) {}

      _ready = true;
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<String> _generateIcon() async {
    final image = img.Image(width: 32, height: 32);
    img.fill(image, color: img.ColorRgba8(0, 0, 0, 0));
    const cx = 16, cy = 16, r = 13;
    for (var y = 0; y < 32; y++) {
      for (var x = 0; x < 32; x++) {
        final dx = x - cx, dy = y - cy;
        if (dx * dx + dy * dy <= r * r) {
          image.setPixelRgba(x, y, 59, 130, 246, 255);
        }
      }
    }
    final pngBytes = img.encodePng(image);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/tray_icon.png');
    await file.writeAsBytes(pngBytes);
    return file.path;
  }

  Future<void> destroy() async {
    if (!_ready) return;
    try { await trayManager.destroy(); } catch (_) {}
  }
}

class _TrayHandler extends TrayListener {
  final void Function()? onShow;
  final void Function()? onHide;
  final void Function()? onRefresh;
  final void Function()? onSettings;
  final void Function()? onQuit;

  _TrayHandler({this.onShow, this.onHide, this.onRefresh, this.onSettings, this.onQuit});

  @override
  void onTrayMenuItemClick(MenuItem item) {
    switch (item.key) {
      case 'show': onShow?.call(); break;
      case 'hide': onHide?.call(); break;
      case 'refresh': onRefresh?.call(); break;
      case 'settings': onSettings?.call(); break;
      case 'quit': onQuit?.call(); break;
    }
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }
}
