import 'dart:async';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../models/balance_info.dart';
import '../services/api_service.dart';
import '../services/config_service.dart';
import '../services/window_service.dart';

class FloatingWindow extends StatefulWidget {
  final ConfigService config;
  const FloatingWindow({super.key, required this.config});
  @override
  FloatingWindowState createState() => FloatingWindowState();
}

class FloatingWindowState extends State<FloatingWindow> {
  final ApiService _api = ApiService();
  BalanceInfo? _balance;
  String? _error;
  String? _updateTime;
  bool _loading = false;
  Timer? _pollTimer;
  bool _settingsOpen = false;

  bool get hasKey => widget.config.apiKey.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (hasKey) triggerPoll();
    _startPollTimer();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _startPollTimer() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(
      Duration(minutes: widget.config.intervalMinutes),
      (_) => _doPoll(),
    );
  }

  void triggerPoll() => _doPoll();
  void openSettings() => _showSettingsDialog();

  Future<void> _doPoll() async {
    if (!hasKey || _loading) return;
    setState(() { _loading = true; _error = null; });
    try {
      final infos = await _api.queryBalance(widget.config.apiKey);
      if (!mounted) return;
      final now = DateTime.now();
      setState(() {
        _balance = infos.isNotEmpty ? infos.first : null;
        _updateTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showSettingsDialog() async {
    if (_settingsOpen) return;
    _settingsOpen = true;
    await WindowService.resizeForSettings();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) { _settingsOpen = false; return; }

    final keyCtrl = TextEditingController(text: widget.config.apiKey);
    var interval = widget.config.intervalMinutes;
    var autoStart = widget.config.autoStart;
    var alwaysOnTop = widget.config.alwaysOnTop;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _SettingsDialog(
        keyCtrl: keyCtrl,
        interval: interval,
        autoStart: autoStart,
        alwaysOnTop: alwaysOnTop,
        onIntervalChanged: (v) => interval = v,
        onAutoStartChanged: (v) => autoStart = v,
        onAlwaysOnTopChanged: (v) => alwaysOnTop = v,
      ),
    );

    keyCtrl.dispose();

    if (result == true && mounted) {
      widget.config.apiKey = keyCtrl.text;
      widget.config.intervalMinutes = interval;
      widget.config.autoStart = autoStart;
      widget.config.alwaysOnTop = alwaysOnTop;
      await widget.config.save();
      await WindowService.setAlwaysOnTop(alwaysOnTop);
      _startPollTimer();
      if (hasKey) triggerPoll();
    }

    _settingsOpen = false;
    // Wait for dialog close animation before resizing
    await Future.delayed(const Duration(milliseconds: 200));
    await WindowService.resizeToNormal();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
        onPanStart: (_) => windowManager.startDragging(),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: glassBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 0.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Expanded(child: _buildBalanceContent()),
                    SizedBox(
                      width: 24, height: 24,
                      child: IconButton(
                        padding: EdgeInsets.zero, iconSize: 14,
                        onPressed: hasKey ? _doPoll : _showSettingsDialog,
                        icon: Icon(hasKey ? Icons.refresh : Icons.settings),
                      ),
                    ),
                  ],
                ),
              ),
              if (_updateTime != null)
                Text(_updateTime!, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceContent() {
    if (_balance != null) {
      return Text(_balance!.displayText,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF198246)));
    }
    if (_loading) return const Text('...', style: TextStyle(fontSize: 13, color: Colors.grey));
    if (_error != null) return Text(_error!, style: const TextStyle(fontSize: 10, color: Color(0xFFC83232)), overflow: TextOverflow.ellipsis);
    if (!hasKey) return const Text('请设置 API Key', style: TextStyle(fontSize: 12, color: Colors.grey));
    return const SizedBox.shrink();
  }
}

// ── 设置对话框 ──

class _SettingsDialog extends StatefulWidget {
  final TextEditingController keyCtrl;
  final int interval;
  final bool autoStart;
  final bool alwaysOnTop;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<bool> onAutoStartChanged;
  final ValueChanged<bool> onAlwaysOnTopChanged;

  const _SettingsDialog({
    required this.keyCtrl,
    required this.interval,
    required this.autoStart,
    required this.alwaysOnTop,
    required this.onIntervalChanged,
    required this.onAutoStartChanged,
    required this.onAlwaysOnTopChanged,
  });

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  late int _interval;
  late bool _autoStart;
  late bool _alwaysOnTop;

  @override
  void initState() {
    super.initState();
    _interval = widget.interval;
    _autoStart = widget.autoStart;
    _alwaysOnTop = widget.alwaysOnTop;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('设置'),
      content: SizedBox(
        width: 300,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('API Key', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              TextField(
                controller: widget.keyCtrl,
                obscureText: true,
                decoration: const InputDecoration(hintText: 'sk-...', border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 14),
              const Text('查询间隔', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              DropdownButtonFormField<int>(
                value: _interval,
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: 1, child: Text('1 分钟')),
                  DropdownMenuItem(value: 5, child: Text('5 分钟')),
                  DropdownMenuItem(value: 10, child: Text('10 分钟')),
                  DropdownMenuItem(value: 30, child: Text('30 分钟')),
                ],
                onChanged: (v) {
                  setState(() => _interval = v ?? 5);
                  widget.onIntervalChanged(_interval);
                },
                decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              ),
              const SizedBox(height: 12),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('开机自动启动'),
                value: _autoStart,
                onChanged: (v) {
                  setState(() => _autoStart = v ?? false);
                  widget.onAutoStartChanged(_autoStart);
                },
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('窗口始终置顶'),
                value: _alwaysOnTop,
                onChanged: (v) {
                  setState(() => _alwaysOnTop = v ?? true);
                  widget.onAlwaysOnTopChanged(_alwaysOnTop);
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
        ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('保存')),
      ],
    );
  }
}
