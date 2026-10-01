import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class EquipmentPhotoStore {
  static const _key = 'nalvium_equipment_photo_paths_v1';

  Future<void> save(String mediaId, String path) async {
    final prefs = await SharedPreferences.getInstance();
    final values = _read(prefs);
    values[mediaId] = path;
    await prefs.setString(_key, jsonEncode(values));
  }

  Future<String?> pathFor(String? mediaId) async {
    if (mediaId == null || mediaId.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    return _read(prefs)[mediaId];
  }

  Map<String, String> _read(SharedPreferences prefs) {
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map;
      return decoded.map(
        (key, value) => MapEntry(key.toString(), value.toString()),
      );
    } catch (_) {
      return {};
    }
  }
}
