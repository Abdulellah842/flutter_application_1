import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'auth_screen.dart';
import 'auth_service.dart';
import 'cloud_sync_service.dart';
import 'home_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  String? _activeUid;

  Future<void> _syncForUser(User user) async {
    if (_activeUid == user.uid) return;
    _activeUid = user.uid;
    await CloudSyncService.instance.startForUser(user.uid);
  }

  Future<void> _stopSync() async {
    _activeUid = null;
    await CloudSyncService.instance.stop();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        if (user == null) {
          _stopSync();
          return const AuthScreen();
        }
        _syncForUser(user);
        return const HomeScreen();
      },
    );
  }
}
