import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudSyncService with WidgetsBindingObserver {
  CloudSyncService._();

  static final CloudSyncService instance = CloudSyncService._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Timer? _timer;
  String? _uid;
  bool _running = false;
  bool _busy = false;

  Future<void> startForUser(String uid) async {
    if (_uid == uid && _running) return;
    await stop();
    _uid = uid;
    _running = true;
    WidgetsBinding.instance.addObserver(this);
    await pullRemoteToLocal();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => pushLocalToRemote());
  }

  Future<void> stop() async {
    if (_running) {
      await pushLocalToRemote();
    }
    _timer?.cancel();
    _timer = null;
    _uid = null;
    _running = false;
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_running) return;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      pushLocalToRemote();
    }
  }

  Future<void> pullRemoteToLocal() async {
    if (_uid == null || _busy) return;
    _busy = true;
    try {
      final doc = await _db.collection('users').doc(_uid).collection('meta').doc('prefs').get();
      final data = doc.data();
      if (data == null) return;
      final payload = data['payload'];
      if (payload is! Map) return;
      final prefs = await SharedPreferences.getInstance();
      for (final entry in payload.entries) {
        final key = entry.key.toString();
        final val = entry.value;
        if (val is bool) {
          await prefs.setBool(key, val);
        } else if (val is int) {
          await prefs.setInt(key, val);
        } else if (val is double) {
          await prefs.setDouble(key, val);
        } else if (val is String) {
          await prefs.setString(key, val);
        } else if (val is List) {
          final strings = val.map((e) => e.toString()).toList();
          await prefs.setStringList(key, strings);
        }
      }
    } catch (_) {
      // Keep app usable offline; sync failures should not block user flows.
    } finally {
      _busy = false;
    }
  }

  Future<void> pushLocalToRemote() async {
    if (_uid == null || _busy) return;
    _busy = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final payload = <String, dynamic>{};
      for (final key in keys) {
        payload[key] = prefs.get(key);
      }
      await _db.collection('users').doc(_uid).collection('meta').doc('prefs').set({
        'payload': payload,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Ignore transient failures and retry on next cycle.
    } finally {
      _busy = false;
    }
  }
}
