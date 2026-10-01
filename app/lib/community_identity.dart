import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class CommunityIdentity {
  static const _key = 'nalvium_community_actor_v1';
  static Future<String> id() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.length >= 16) return existing;
    final random = Random.secure();
    final value = List.generate(
      32,
      (_) => random.nextInt(36).toRadixString(36),
    ).join();
    await prefs.setString(_key, value);
    return value;
  }
}
