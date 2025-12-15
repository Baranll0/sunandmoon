import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_manager.dart';

/// Provider for Singleton SyncManager
/// This will be overridden in main.dart with the initialized instance
final syncManagerProvider = Provider<SyncManager?>((ref) => null);
