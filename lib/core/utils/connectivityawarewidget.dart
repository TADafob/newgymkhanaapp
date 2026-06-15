import 'dart:async';
import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/connecitivitychecker.dart';

class ConnectivityAwareWidget extends StatefulWidget {
  final Widget child;
  final String? customImagePath;

  const ConnectivityAwareWidget({
    super.key,
    required this.child,
    this.customImagePath,
  });

  @override
  _ConnectivityAwareWidgetState createState() =>
      _ConnectivityAwareWidgetState();
}

class _ConnectivityAwareWidgetState extends State<ConnectivityAwareWidget>
    with TickerProviderStateMixin {
  late final ConnectivityService _connectivityService;
  late final StreamSubscription<bool> _subscription;
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;

  bool _isConnected = true;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = ConnectivityService();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastLinearToSlowEaseIn,
      ),
    );

    _subscription = _connectivityService.connectionChange.listen((status) {
      setState(() => _isConnected = status);

      if (!status) {
        // Went offline → show panel
        _animationController.forward();
      } else if (!_isChecking) {
        // Came back online (and not in retry) → hide panel
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _connectivityService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _retryConnection() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final connected = await _connectivityService.checkConnection();

    if (connected) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.green[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check, color: Colors.white),
                SizedBox(width: 12),
                Text(
                  "Connection Restored",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        setState(() {
          _isChecking = false;
          _isConnected = true;
        });
        _animationController.reverse();
      }
    } else {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        // 1️⃣ Your app content
        widget.child,

        // 2️⃣ TRANSPARENT BARRIER: catches all taps when offline or checking
        if (!_isConnected || _isChecking)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(color: Colors.transparent),
            ),
          ),

        // 3️⃣ Bottom‐sheet panel
        if (!_isConnected || _isChecking)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _slideAnimation,
              child: Material(
                color: Colors.transparent,
                child: Container(
                  height: height * 0.4,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppKolors.secondary, AppKolors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        spreadRadius: 2,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Image
                        Container(
                          height: 120,
                          width: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 4,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              widget.customImagePath ??
                                  'assets/images/common/nointernet.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                        // Status text
                        Column(
                          children: [
                            Text(
                              _isChecking
                                  ? 'Checking connection…'
                                  : 'Connection Lost',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (!_isChecking)
                              Text(
                                'Please check your internet connection',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withValues(alpha: 0.8),
                                ),
                              ),
                          ],
                        ),

                        // Retry button / spinner
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 2,
                              ),
                            ),
                            onPressed: _isChecking ? null : _retryConnection,
                            child: _isChecking
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: const [
                                      Icon(Icons.refresh, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'TRY AGAIN',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
