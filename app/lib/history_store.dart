import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class HistoryStore {
  static const _key = 'nalvium_history_v1';
  Future<List<Map<String, dynamic>>> list() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_key) ?? [])
        .map((value) => jsonDecode(value) as Map<String, dynamic>)
        .toList();
  }

  Future<void> save(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final items = await list();
    items.removeWhere((old) => old['session_id'] == item['session_id']);
    items.insert(0, item);
    await prefs.setStringList(_key, items.take(30).map(jsonEncode).toList());
  }
}
