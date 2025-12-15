import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/sync_manager.dart';
import '../../../../core/services/firebase_service.dart';
import '../../home/screens/home_screen.dart';
import 'login_screen.dart';

/// Auth gate - shows login screen if not authenticated, otherwise home
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  AuthService? _authService;
  SyncManager? _syncManager;
  bool _isInitializing = true;
  bool _isSyncing = false;
  
  @override
  void initState() {
    super.initState();
    // Only create AuthService and SyncManager if Firebase is available (not web without config)
    if (!kIsWeb || FirebaseService.isInitialized) {
      _authService = AuthService();
      _syncManager = SyncManager();
      _initializeSyncManager();
    } else {
      // Web without Firebase config - skip initialization
      _isInitializing = false;
    }
  }
  
  Future<void> _initializeSyncManager() async {
    if (_syncManager == null) return;
    
    // Only initialize SyncManager if Firebase is available
    if (FirebaseService.isInitialized || !kIsWeb) {
      try {
        await _syncManager!.initialize();
      } catch (e) {
        debugPrint('SyncManager initialization failed: $e');
        // Continue without sync
      }
    }
    _checkAuthState();
  }

  Future<void> _checkAuthState() async {
    // Wait for auth state to stabilize
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      setState(() {
        _isInitializing = false;
      });

      // If user is signed in, sync data
      if (_authService?.isSignedIn == true) {
        await _syncUserData();
      }
    }
  }

  Future<void> _syncUserData() async {
    if (!mounted || _syncManager == null || _authService == null) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final user = _authService!.currentUser;
      if (user != null) {
        // Sync on login (conflict resolution + merge)
        await _syncManager!.syncOnLogin(user.uid);
      }
    } catch (e) {
      debugPrint('Error syncing user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSyncing = false;
        });
      }
    }
  }
  
  @override
  void dispose() {
    _syncManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // On web without Firebase config, skip login and go directly to home (for testing)
    if (kIsWeb && !FirebaseService.isInitialized) {
      return const HomeScreen();
    }

    // If AuthService is not initialized, show loading
    if (_authService == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService!.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (_isInitializing || snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Show syncing indicator if syncing
        if (_isSyncing) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Syncing your progress...',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          );
        }

        // On web without Firebase config, skip login and go directly to home (for testing)
        if (kIsWeb && !FirebaseService.isInitialized) {
          return const HomeScreen();
        }

        // Show login screen if not authenticated
        if (snapshot.data == null) {
          return const LoginScreen();
        }

        // Show home screen if authenticated
        return const HomeScreen();
      },
    );
  }
}

