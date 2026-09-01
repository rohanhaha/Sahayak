import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../auth/screens/auth_screen.dart';
import '../customer/screens/customer_home_screen.dart';
import '../worker/screens/worker_home_screen.dart';

/// App Startup Router that checks stored session
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isChecking = true;
  String? _userRole;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      final role = await AuthService.getRole();
      setState(() {
        _isLoggedIn = true;
        _userRole = role;
        _isChecking = false;
      });
    } else {
      setState(() {
        _isLoggedIn = false;
        _isChecking = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isChecking) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF1E7E34),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return const AuthScreen();
    }

    if (_userRole == 'WORKER') {
      return const WorkerHomeScreen();
    }

    return const CustomerHomeScreen();
  }
}
