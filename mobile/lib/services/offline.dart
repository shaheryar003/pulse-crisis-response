import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tiny queue for citizen reports that fail when device is offline.
/// Persisted in SharedPreferences so submissions survive app restart.
class OfflineQueue {
  static const _key = 'pulse.offline.queue.v1';

  static Future<List<Map<String, dynamic>>> _read() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString(_key);
    if (raw == null) return [];
    return (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
  }

  static Future<void> _write(List<Map<String, dynamic>> items) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_key, jsonEncode(items));
  }

  static Future<void> enqueue(Map<String, dynamic> payload) async {
    final items = await _read();
    items.add(payload);
    await _write(items);
  }

  static Future<List<Map<String, dynamic>>> drain() async {
    final items = await _read();
    await _write([]);
    return items;
  }

  static Future<int> pending() async {
    return (await _read()).length;
  }
}
