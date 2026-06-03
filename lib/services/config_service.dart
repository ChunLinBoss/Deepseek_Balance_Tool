import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConfigService {
  String apiKey = '';
  int intervalMinutes = 5;
  bool autoStart = false;
  bool alwaysOnTop = true;
  double? windowX;
  double? windowY;

  Future<File> _configFile() async {
    final dir = await getApplicationSupportDirectory();
    final configDir = Directory('${dir.path}/deepseek_balance');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return File('${configDir.path}/config.json');
  }

  Future<void> load() async {
    try {
      final file = await _configFile();
      if (await file.exists()) {
        final content = await file.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        apiKey = json['api_key'] as String? ?? '';
        intervalMinutes = json['interval_minutes'] as int? ?? 5;
        autoStart = json['auto_start'] as bool? ?? false;
        alwaysOnTop = json['always_on_top'] as bool? ?? true;
        windowX = (json['window_x'] as num?)?.toDouble();
        windowY = (json['window_y'] as num?)?.toDouble();
      }
    } catch (_) {
      // Use defaults
    }
  }

  Future<void> save() async {
    try {
      final file = await _configFile();
      final json = {
        'api_key': apiKey,
        'interval_minutes': intervalMinutes,
        'auto_start': autoStart,
        'always_on_top': alwaysOnTop,
        'window_x': windowX,
        'window_y': windowY,
      };
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(json));
    } catch (_) {}
  }
}
