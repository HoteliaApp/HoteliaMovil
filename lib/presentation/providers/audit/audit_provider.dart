import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_app/domain/domain.dart';
import 'package:hotel_app/infrastructure/datasource/audit_datasource_impl.dart';
import 'package:hotel_app/infrastructure/repositories/audit_repository_impl.dart';
import 'package:hotel_app/presentation/providers/auth/auth_provider.dart';
import 'package:hotel_app/presentation/providers/rooms/rooms_provider.dart';

// ─────────────────────────── Inyección de dependencias ────────────────────────

final auditDatasourceProvider = Provider<AuditDatasource>((ref) {
  final hotelId = ref.watch(currentHotelIdProvider);
  return AuditDatasourceImpl(hotelId: hotelId);
});

final auditRepositoryProvider = Provider<AuditRepository>((ref) {
  final ds = ref.watch(auditDatasourceProvider);
  final hotelId = ref.watch(currentHotelIdProvider);
  return AuditRepositoryImpl(ds, hotelId);
});

// ─────────────────────────── Stream en tiempo real ────────────────────────────

final auditLogsStreamProvider =
    StreamProvider.autoDispose<List<AuditLog>>((ref) {
  final repository = ref.watch(auditRepositoryProvider);
  final hotelId = ref.watch(currentHotelIdProvider);
  return repository.watchAuditLogs(hotelId: hotelId);
});

// ───────────────────────────── Estado de Auditoría ────────────────────────────

class AuditState {
  final List<AuditLog> logs;
  final bool isLoading;
  final String? errorMessage;
  final AuditActionType? selectedFilter;
  final String searchQuery;
  final DateTimeRange? selectedDateRange;

  const AuditState({
    this.logs = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedFilter,
    this.searchQuery = '',
    this.selectedDateRange,
  });

  /// Lista de logs procesada aplicando los filtros activos y búsqueda textual
  List<AuditLog> get filteredLogs {
    var result = List<AuditLog>.from(logs);

    if (selectedFilter != null) {
      result = result.where((l) => l.actionType == selectedFilter).toList();
    }

    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((l) {
        final action = l.action.toLowerCase();
        final desc = l.description.toLowerCase();
        final op = l.operatorDisplayName.toLowerCase();
        final target = l.targetId.toLowerCase();
        final reason = (l.reason ?? '').toLowerCase();
        return action.contains(q) ||
            desc.contains(q) ||
            op.contains(q) ||
            target.contains(q) ||
            reason.contains(q);
      }).toList();
    }

    if (selectedDateRange != null) {
      final start = DateTime(
        selectedDateRange!.start.year,
        selectedDateRange!.start.month,
        selectedDateRange!.start.day,
      );
      final end = DateTime(
        selectedDateRange!.end.year,
        selectedDateRange!.end.month,
        selectedDateRange!.end.day,
        23,
        59,
        59,
      );
      result = result.where((l) {
        return l.timestamp.isAfter(start) && l.timestamp.isBefore(end);
      }).toList();
    }

    return result;
  }

  bool get hasActiveFilters =>
      selectedFilter != null ||
      searchQuery.trim().isNotEmpty ||
      selectedDateRange != null;

  AuditState copyWith({
    List<AuditLog>? logs,
    bool? isLoading,
    String? errorMessage,
    AuditActionType? selectedFilter,
    bool clearFilter = false,
    String? searchQuery,
    DateTimeRange? selectedDateRange,
    bool clearDateRange = false,
    bool clearError = false,
  }) {
    return AuditState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      selectedFilter:
          clearFilter ? null : selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedDateRange:
          clearDateRange ? null : selectedDateRange ?? this.selectedDateRange,
    );
  }
}

// ─────────────────────────── Notifier (Riverpod 3) ───────────────────────────

class AuditNotifier extends Notifier<AuditState> {
  StreamSubscription<List<AuditLog>>? _subscription;

  @override
  AuditState build() {
    _subscribeToStream();
    ref.onDispose(() {
      _subscription?.cancel();
    });
    return const AuditState(isLoading: true);
  }

  void _subscribeToStream() {
    final repository = ref.read(auditRepositoryProvider);
    final hotelId = ref.read(currentHotelIdProvider);

    _subscription?.cancel();
    _subscription = repository.watchAuditLogs(hotelId: hotelId).listen(
      (logs) {
        state = state.copyWith(
          logs: logs,
          isLoading: false,
          clearError: true,
        );
      },
      onError: (e) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        );
      },
    );
  }

  void setFilter(AuditActionType? filter) {
    if (state.selectedFilter == filter) {
      state = state.copyWith(clearFilter: true);
    } else {
      state = state.copyWith(
        selectedFilter: filter,
        clearFilter: filter == null,
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setDateRange(DateTimeRange? range) {
    state = state.copyWith(
      selectedDateRange: range,
      clearDateRange: range == null,
    );
  }

  void clearFilters() {
    state = state.copyWith(
      clearFilter: true,
      searchQuery: '',
      clearDateRange: true,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final repository = ref.read(auditRepositoryProvider);
      final hotelId = ref.read(currentHotelIdProvider);
      final logs = await repository.getAuditLogs(hotelId: hotelId);
      state = state.copyWith(logs: logs, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final auditNotifierProvider =
    NotifierProvider<AuditNotifier, AuditState>(AuditNotifier.new);
