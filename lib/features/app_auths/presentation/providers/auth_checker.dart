import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import '../../../home/presentation/screens_ui/home_screen.dart';
import '../../presentation/screens_ui/login_screen.dart';
import 'auth_provider.dart';

class AuthChecker extends ConsumerWidget {
  const AuthChecker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) return const LoginScreen();
        return _DeviceSessionGuard(uid: user.uid);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) =>
          const Scaffold(body: Center(child: Text('Something went wrong'))),
    );
  }
}

class _DeviceSessionGuard extends StatefulWidget {
  final String uid;
  const _DeviceSessionGuard({required this.uid});

  @override
  State<_DeviceSessionGuard> createState() => _DeviceSessionGuardState();
}

class _DeviceSessionGuardState extends State<_DeviceSessionGuard> {
  bool _checking = true;
  bool _sessionValid = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    try {
      if (Theme.of(context).platform == TargetPlatform.android) {
        return (await deviceInfo.androidInfo).id;
      } else {
        final info = await deviceInfo.iosInfo;
        return info.identifierForVendor ?? info.name;
      }
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _checkSession() async {
    final currentDeviceId = await _getDeviceId();
    final doc = await FirebaseFirestore.instance
        .collection('users_members')
        .doc(widget.uid)
        .get();

    final storedDeviceId = doc.data()?['activeDeviceId'] as String?;

    if (storedDeviceId == null || storedDeviceId == currentDeviceId) {
      // First login or same device — save locally and allow
      await LocalStorage.setDeviceId(currentDeviceId);
      setState(() {
        _sessionValid = true;
        _checking = false;
      });
    } else {
      // Different device — force sign out
      await FirebaseAuth.instance.signOut();
      await LocalStorage.removeUserId();
      setState(() {
        _sessionValid = false;
        _checking = false;
      });
      if (mounted) {
        _showSessionDialog();
      }
    }
  }

  void _showSessionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Session Active on Another Device'),
        content: const Text(
          'Your account is currently logged in on another device. '
          'Please log out from that device first, or contact support to transfer your session.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _sessionValid ? HomeScreen() : const LoginScreen();
  }
}
