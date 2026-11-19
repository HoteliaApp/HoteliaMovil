import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/infrastructure/services/connectivity_service.dart';

// ─────────────────────────── Inyección de dependencias ────────────────────────

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityServiceImpl();
});

// ─────────────────────────── Stream reactivo de conectividad ──────────────────

final isOnlineStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.watchIsOnline();
});

// ───────────────────────────── Estado de Sincronización y Red ─────────────────

class SyncState {
  final bool isOnline;
  final bool hasPendingWrites;
  final bool isFromCache;
  final DateTime? lastSyncTime;

  const SyncState({
    this.isOnline = true,
    this.hasPendingWrites = false,
    this.isFromCache = false,
    this.lastSyncTime,
  });

  SyncState copyWith({
    bool? isOnline,
    bool? hasPendingWrites,
    bool? isFromCache,
    DateTime? lastSyncTime,
  }) {
    return SyncState(
      isOnline: isOnline ?? this.isOnline,
      hasPendingWrites: hasPendingWrites ?? this.hasPendingWrites,
      isFromCache: isFromCache ?? this.isFromCache,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() {
    final service = ref.watch(connectivityServiceProvider);

    // Consulta inicial del estado de red
    service.checkIsOnline().then((online) {
      state = state.copyWith(isOnline: online);
    }).catchError((_) {});

    // Escucha cambios reactivos de conectividad
    final sub = service.watchIsOnline().listen((online) {
      state = state.copyWith(
        isOnline: online,
        lastSyncTime: online ? DateTime.now() : state.lastSyncTime,
      );
    });

    ref.onDispose(() => sub.cancel());

    return const SyncState();
  }

  void updateSyncMetadata({bool? hasPendingWrites, bool? isFromCache}) {
    state = state.copyWith(
      hasPendingWrites: hasPendingWrites,
      isFromCache: isFromCache,
    );
  }

  void setOnline(bool online) {
    state = state.copyWith(isOnline: online);
  }
}

final syncProvider = NotifierProvider<SyncNotifier, SyncState>(SyncNotifier.new);

/// Provider directo booleano: true = en línea, false = modo fuera de línea
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(syncProvider).isOnline;
});
