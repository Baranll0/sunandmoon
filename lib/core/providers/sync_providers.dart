import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../services/sync_manager.dart';
import '../repositories/game_state_repository.dart';

part 'sync_providers.g.dart';

/// SyncManager provider (singleton)
@Riverpod(keepAlive: true)
Future<SyncManager> syncManager(SyncManagerRef ref) async {
  final manager = SyncManager();
  await manager.initialize();
  ref.onDispose(() => manager.dispose());
  return manager;
}

/// GameStateRepository provider
@riverpod
Future<GameStateRepository> gameStateRepository(GameStateRepositoryRef ref) async {
  final syncManager = await ref.watch(syncManagerProvider.future);
  return GameStateRepository(syncManager);
}

