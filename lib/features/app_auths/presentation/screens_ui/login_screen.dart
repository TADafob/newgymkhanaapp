import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/errors/app_failure.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/common/sharedpreff/localstorage.dart';
import 'package:nrbgymkhana/features/home/presentation/providers/homeproviders.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  final _membershipController = TextEditingController();
  final _passwordController = TextEditingController();

  String? _membershipError;
  String? _passwordError;
  bool _isLoading = false;
  bool _obscurePassword = true;

  late AnimationController _entryController;
  late Animation<double> _logoFade;
  late Animation<Offset> _formSlide;
  late Animation<double> _formFade;

  final RegExp _membershipRegex = RegExp(r'^[a-zA-Z]-\d{2}-\d{4,5}$');

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    ));

    _formFade = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _membershipController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showPopup(String title, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _signIn() async {
    setState(() {
      _membershipError = null;
      _passwordError = null;
    });

    final membership = _membershipController.text.trim();
    final password = _passwordController.text;

    if (membership.isEmpty || password.isEmpty) {
      setState(() {
        if (membership.isEmpty) {
          _membershipError = 'Please enter membership number';
        }
        if (password.isEmpty) _passwordError = 'Please enter password';
      });
      return;
    }

    if (!_membershipRegex.hasMatch(membership)) {
      setState(() => _membershipError = 'Invalid format — e.g. p-02-0011');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final membershipUpper = membership.toUpperCase();

      // Step 1: Look up real email from Firestore by mem_Number
      final query = await FirebaseFirestore.instance
          .collection('users_members')
          .where('mem_Number', isEqualTo: membershipUpper)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        _showPopup('Member Not Found',
            'Membership number "$membership" was not found. Please contact IT support.');
        return;
      }

      final data = query.docs.first.data();

      if (data['isActive'] != true) {
        _showPopup('Account Inactive',
            'Your membership is currently inactive.\n\nTo activate, please contact IT support or call 0733 401 341');
        return;
      }

      final realEmail = data['email'] as String?;
      if (realEmail == null || realEmail.isEmpty) {
        _showPopup('Setup Incomplete',
            'No email linked to this membership. Please contact IT support.');
        return;
      }

      // Step 2: Sign in with the real email
      final user =
          await ref.read(signInUseCaseProvider).call(realEmail, password);
      if (user == null) return;

      // Step 3: Check device conflict
      final uid = user.uid;
      final currentDeviceId = await _getDeviceId();
      final storedDeviceId = data['activeDeviceId'] as String?;

      if (storedDeviceId != null && storedDeviceId != currentDeviceId) {
        final proceed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Already Logged In'),
            content: const Text(
                'You are logged in on another phone. If you proceed, you will be logged out of that device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Proceed'),
              ),
            ],
          ),
        );
        if (proceed != true) {
          await auth.FirebaseAuth.instance.signOut();
          return;
        }
      }

      await LocalStorage.setUserId(uid);
      await _updateFcmToken(uid);
      await _registerDevice(uid, forceOverwrite: true);

      ref.invalidate(userStreamProvider);
      ref.invalidate(cardStreamProvider);
      ref.invalidate(newsStreamProvider);

      await _askNotificationPermission(context);
    } on AuthFailure catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('wrong-password') ||
          msg.contains('invalid-credential') ||
          msg.contains('invalid credential')) {
        setState(
            () => _passwordError = 'Incorrect password. Please try again.');
      } else if (msg.contains('user-disabled')) {
        _showPopup('Account Disabled',
            'Your account has been disabled. Please contact IT support or call 0733 401 341');
      } else if (msg.contains('too-many-requests')) {
        _showPopup('Too Many Attempts',
            'Too many failed login attempts. Please try again later.');
      } else if (msg.contains('network')) {
        _showPopup('No Internet',
            'Please check your internet connection and try again.');
      } else {
        setState(
            () => _passwordError = 'Incorrect password. Please try again.');
      }
    } on auth.FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          setState(
              () => _passwordError = 'Incorrect password. Please try again.');
          break;
        case 'user-disabled':
          _showPopup('Account Disabled',
              'Your account has been disabled. Please contact IT support or call 0733 401 341');
          break;
        case 'too-many-requests':
          _showPopup('Too Many Attempts',
              'Too many failed login attempts. Please try again later.');
          break;
        case 'network-request-failed':
          _showPopup('No Internet',
              'Please check your internet connection and try again.');
          break;
        default:
          setState(
              () => _passwordError = 'Incorrect password. Please try again.');
      }
    } catch (_) {
      _showPopup('Error', 'Something went wrong. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<String> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Theme.of(context).platform == TargetPlatform.android) {
      return (await deviceInfo.androidInfo).id;
    } else {
      final info = await deviceInfo.iosInfo;
      return info.identifierForVendor ?? info.name;
    }
  }

  Future<void> _registerDevice(String uid,
      {bool forceOverwrite = false}) async {
    final deviceId = await _getDeviceId();
    final docRef =
        FirebaseFirestore.instance.collection('users_members').doc(uid);

    if (forceOverwrite) {
      await docRef.update({'activeDeviceId': deviceId});
    } else {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final snap = await tx.get(docRef);
        final stored = snap.data()?['activeDeviceId'] as String?;
        if (stored != null && stored != deviceId) {
          throw Exception('device_conflict');
        }
        tx.update(docRef, {'activeDeviceId': deviceId});
      });
    }

    await LocalStorage.setDeviceId(deviceId);
  }

  Future<void> _updateFcmToken(String uid) async {
    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true);
      final token = await FirebaseMessaging.instance.getToken();
      await FirebaseFirestore.instance
          .collection('users_members')
          .doc(uid)
          .update({'fcm_Token': token});
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppKolors.dark,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1628), Color(0xFF1a2e35)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Decorative circle top-right
          Positioned(
            top: -80,
            right: -80,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppKolors.primary.withOpacity(0.12),
              ),
            ),
          ),
          // Decorative circle bottom-left
          Positioned(
            bottom: -60,
            left: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppKolors.accent.withOpacity(0.08),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),
                  // Logo + title
                  FadeTransition(
                    opacity: _logoFade,
                    child: Column(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                                width: 1.5),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/common/logo3.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Nairobi Gymkhana',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Member Portal',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: size.height * 0.06),
                  // Form card
                  SlideTransition(
                    position: _formSlide,
                    child: FadeTransition(
                      opacity: _formFade,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.1), width: 1),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Enter your membership credentials',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 28),
                            _buildField(
                              controller: _membershipController,
                              hint: 'Membership No. (e.g. p-02-0011)',
                              icon: Icons.badge_outlined,
                              errorText: _membershipError,
                              isMembership: true,
                            ),
                            const SizedBox(height: 20),
                            _buildField(
                              controller: _passwordController,
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              isPassword: true,
                              errorText: _passwordError,
                            ),
                            const SizedBox(height: 28),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppKolors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                  elevation: 0,
                                ),
                                onPressed: _isLoading ? null : _signIn,
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Sign In',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  FadeTransition(
                    opacity: _formFade,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        text: 'Having trouble? ',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.45),
                            fontSize: 13),
                        children: const [
                          TextSpan(
                            text: 'support@nairobigymkhana.com',
                            style: TextStyle(
                                color: AppKolors.accent, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isMembership = false,
    String? errorText,
  }) {
    final hasError = errorText != null;
    return TextField(
      controller: controller,
      obscureText: isPassword && _obscurePassword,
      inputFormatters: isMembership ? [_MembershipFormatter()] : null,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      cursorColor: AppKolors.primary,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 14),
        errorText: errorText,
        errorStyle: const TextStyle(color: Colors.redAccent, fontSize: 11.5),
        prefixIcon: Icon(icon, color: AppKolors.primary, size: 20),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              )
            : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.07),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError
                ? Colors.redAccent.withOpacity(0.7)
                : Colors.white.withOpacity(0.12),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: hasError ? Colors.redAccent : AppKolors.primary,
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.7)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
      ),
    );
  }
}

class _MembershipFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // Strip everything except alphanumerics
    final digits = newValue.text.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');

    // Format: x-00-0000 or x-00-00000
    // positions: [0]=letter, [1-2]=2 digits, [3-7]=4-5 digits
    final buf = StringBuffer();
    for (int i = 0; i < digits.length && i < 8; i++) {
      if (i == 1 || i == 3) buf.write('-');
      buf.write(digits[i]);
    }

    final text = buf.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

Future<void> _askNotificationPermission(BuildContext context) async {
  final existingPref = await LocalStorage.getNotificationsEnabled();

  if (existingPref == null) {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Allow Notifications?'),
        content: const Text(
          'Would you like to receive notifications from Nairobi Gymkhana?\n\n'
          'You can always change this in the app\'s settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No Thanks'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    if (result != null) {
      await LocalStorage.setNotificationsEnabled(result);

      final uid = auth.FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users_members')
          .doc(uid)
          .update({'notifications_enabled': result});

      if (result) {
        await FirebaseMessaging.instance
            .requestPermission(alert: true, badge: true, sound: true);
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users_members')
              .doc(uid)
              .update({'fcm_Token': token});
        }
      }
    }
  }
}
