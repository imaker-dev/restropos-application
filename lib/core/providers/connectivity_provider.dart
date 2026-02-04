import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectivityStatus { online, offline, syncing }

class ConnectivityState {
  final ConnectivityStatus status;
  final DateTime? lastSyncTime;
  final int pendingSyncCount;

  const ConnectivityState({
    this.status = ConnectivityStatus.online,
    this.lastSyncTime,
    this.pendingSyncCount = 0,
  });

  bool get isOnline => status == ConnectivityStatus.online;
  bool get isOffline => status == ConnectivityStatus.offline;
  bool get isSyncing => status == ConnectivityStatus.syncing;

  ConnectivityState copyWith({
    ConnectivityStatus? status,
    DateTime? lastSyncTime,
    int? pendingSyncCount,
  }) {
    return ConnectivityState(
      status: status ?? this.status,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      pendingSyncCount: pendingSyncCount ?? this.pendingSyncCount,
    );
  }
}

class ConnectivityNotifier extends StateNotifier<ConnectivityState> {
  Timer? _syncTimer;
  
  ConnectivityNotifier() : super(const ConnectivityState()) {
    _startAutoSync();
  }

  void _startAutoSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (state.isOnline && state.pendingSyncCount > 0) {
        sync();
      }
    });
  }

  void setOnline() {
    state = state.copyWith(status: ConnectivityStatus.online);
    if (state.pendingSyncCount > 0) {
      sync();
    }
  }

  void setOffline() {
    state = state.copyWith(status: ConnectivityStatus.offline);
  }

  void addPendingSync() {
    state = state.copyWith(pendingSyncCount: state.pendingSyncCount + 1);
  }

  Future<void> sync() async {
    if (state.isOffline || state.isSyncing) return;
    
    state = state.copyWith(status: ConnectivityStatus.syncing);
    
    // Simulate sync delay
    await Future.delayed(const Duration(seconds: 1));
    
    state = state.copyWith(
      status: ConnectivityStatus.online,
      lastSyncTime: DateTime.now(),
      pendingSyncCount: 0,
    );
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, ConnectivityState>((ref) {
  return ConnectivityNotifier();
});

// Widget to show connectivity status
class ConnectivityIndicator extends ConsumerWidget {
  const ConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getBackgroundColor(connectivity.status),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (connectivity.isSyncing)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          else
            Icon(
              _getIcon(connectivity.status),
              size: 14,
              color: Colors.white,
            ),
          const SizedBox(width: 4),
          Text(
            _getLabel(connectivity),
            style: const TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return Colors.green;
      case ConnectivityStatus.offline:
        return Colors.red;
      case ConnectivityStatus.syncing:
        return Colors.orange;
    }
  }

  IconData _getIcon(ConnectivityStatus status) {
    switch (status) {
      case ConnectivityStatus.online:
        return Icons.cloud_done;
      case ConnectivityStatus.offline:
        return Icons.cloud_off;
      case ConnectivityStatus.syncing:
        return Icons.sync;
    }
  }

  String _getLabel(ConnectivityState state) {
    if (state.isSyncing) return 'Syncing...';
    if (state.isOffline) return 'Offline';
    if (state.pendingSyncCount > 0) return 'Pending: ${state.pendingSyncCount}';
    return 'Online';
  }
}

// Compact indicator for mobile
class CompactConnectivityIndicator extends ConsumerWidget {
  const CompactConnectivityIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connectivity.isOnline 
            ? Colors.green 
            : connectivity.isSyncing 
                ? Colors.orange 
                : Colors.red,
      ),
    );
  }
}
