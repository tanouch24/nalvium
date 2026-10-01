import 'package:shared_preferences/shared_preferences.dart';

class AssistantStore {
  static const _threadKey = 'nalvium_assistant_thread_v1';

  Future<String?> threadId() async =>
      (await SharedPreferences.getInstance()).getString(_threadKey);

  Future<void> saveThreadId(String id) async =>
      (await SharedPreferences.getInstance()).setString(_threadKey, id);
}
