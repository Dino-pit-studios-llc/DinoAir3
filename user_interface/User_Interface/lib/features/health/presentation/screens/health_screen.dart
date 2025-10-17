// Health monitor screen with backend health checks and metrics summary.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../../services/api/api_providers.dart';
import '../../../../services/api/api_endpoints.dart';

/// Represents the status of an individual backend component/service.
class ServiceStatus {
  const ServiceStatus({
    required this.name,
    required this.status,
    this.detail,
  });

  final String name;
  final String status;
  final String? detail;
}

/// Aggregated health overview of the backend and notable subsystems.
class HealthOverview {
  const HealthOverview({
    required this.backendOk,
    required this.services,
    required this.fetchedAt,
    this.version,
    this.metricsSummary,
  });

  final bool backendOk;
  final List<ServiceStatus> services;
  final DateTime fetchedAt;
  final String? version;
  final String? metricsSummary;
}

/// Repository that fetches health information from the DinoAir backend.
class HealthRepository {
  HealthRepository(this.ref);

  final Ref ref;

  Future<HealthOverview> fetchHealth() async {
    final dio = ref.read(backendDioProvider);

    Map<String, dynamic>? extended;
    // Try extended health endpoint first (if available).
    try {
      final res = await dio.get('/api/v1/health');
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        extended = res.data as Map<String, dynamic>;
      }
    } catch (_) {
      // Ignore and fallback to basic /health
    }

    if (extended != null) {
      final overview = _fromExtended(extended);
      final metrics = await _tryFetchMetrics(dio);
      return HealthOverview(
        backendOk: overview.backendOk,
        services: overview.services,
        fetchedAt: DateTime.now(),
        version: overview.version,
        metricsSummary: metrics,
      );
    }

    // Fallback to basic health check
    bool ok = false;
    String? version;
    try {
      final res = await dio.get(ApiEndpoints.health);
      if (res.statusCode == 200) {
        final data = res.data;
        if (data is Map<String, dynamic>) {
          final statusStr =
              (data['status'] ?? data['state'] ?? data['ok'] ?? 'unknown')
                  .toString()
                  .toLowerCase();
          ok = statusStr.contains('ok') ||
              statusStr == 'healthy' ||
              statusStr == 'up' ||
              statusStr == 'true';
          version = data['version']?.toString();
        } else {
          // Many simple health endpoints just return "OK" string
          ok = true;
        }
      }
    } catch (_) {
      ok = false;
    }

    final metrics = await _tryFetchMetrics(dio);

    return HealthOverview(
      backendOk: ok,
      services: const [],
      fetchedAt: DateTime.now(),
      version: version,
      metricsSummary: metrics,
    );
  }

  HealthOverview _fromExtended(Map<String, dynamic> json) {
    final statusValue = (json['status'] ?? json['ok'] ?? 'unknown').toString();
    final backendOk = statusValue.toLowerCase().contains('ok') ||
        (json['ok'] == true) ||
        statusValue.toLowerCase() == 'healthy' ||
        statusValue.toLowerCase() == 'up';

    final List<ServiceStatus> services = [];

    void addService(String name, dynamic value) {
      if (value == null) return;
      if (value is Map<String, dynamic>) {
        final st =
            (value['status'] ?? value['state'] ?? value['ok'] ?? 'unknown')
                .toString();
        final msg =
            value['message']?.toString() ?? value['detail']?.toString();
        services.add(ServiceStatus(name: name, status: st, detail: msg));
      } else {
        services.add(ServiceStatus(name: name, status: value.toString()));
      }
    }

    addService('Service Registry', json['service_registry']);
    addService('LM Studio', json['lmstudio'] ?? json['lm_studio']);
    addService('Database', json['database'] ?? json['db']);
    addService('Router', json['router']);
    addService('Vector Store', json['vector_store'] ?? json['qdrant']);

    final version = json['version']?.toString();

    return HealthOverview(
      backendOk: backendOk,
      services: services,
      fetchedAt: DateTime.now(),
      version: version,
      metricsSummary: null, // filled by metrics call
    );
  }

  Future<String?> _tryFetchMetrics(Dio dio) async {
    try {
      final res = await dio.get(
        ApiEndpoints.metrics,
        options: Options(responseType: ResponseType.plain),
      );
      if (res.statusCode == 200 && res.data is String) {
        final text = res.data as String;
        final lines = text.split('\n');
        final nonComment =
            lines.where((l) => l.isNotEmpty && !l.trimLeft().startsWith('#'));
        final sample = nonComment.take(3).join('\n');
        return 'Metrics available (${lines.length} lines).\n$sample';
      }
    } catch (_) {
      // Metrics may be disabled in some environments.
    }
    return null;
  }
}

/// Provider that exposes the current HealthOverview (auto-disposed on leave).
final healthOverviewProvider =
    FutureProvider.autoDispose<HealthOverview>((ref) async {
  final repo = HealthRepository(ref);
  return repo.fetchHealth();
});

/// Health Monitor screen showing backend/API status and subsystem summaries.
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(healthOverviewProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(healthOverviewProvider);
          try {
            await ref.read(healthOverviewProvider.future);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Health Monitor',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            async.when(
              data: (overview) => _buildContent(context, overview, ref),
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => _buildError(context, e, ref),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(
      BuildContext context, Object error, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error, size: 32),
            const SizedBox(height: 12),
            Text(
              'Failed to load health status',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                ref.invalidate(healthOverviewProvider);
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    HealthOverview overview,
    WidgetRef ref,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatusCard(
          title: 'Backend API',
          subtitle: [
            if (overview.version != null) 'Version: ${overview.version}',
            'Fetched: ${overview.fetchedAt}',
          ].join(' • '),
          ok: overview.backendOk,
        ),
        const SizedBox(height: 12),
        if (overview.services.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'Subsystems'),
                  ...overview.services.map((s) => ListTile(
                        leading: Icon(
                          Icons.circle,
                          size: 14,
                          color: _statusColor(context, s.status),
                        ),
                        title: Text(s.name),
                        subtitle: s.detail != null ? Text(s.detail!) : null,
                        trailing: _StatusChip(label: _statusLabel(s.status)),
                      )),
                ],
              ),
            ),
          ),
        if (overview.services.isNotEmpty) const SizedBox(height: 12),
        if (overview.metricsSummary != null)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SectionHeader(title: 'Metrics'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      overview.metricsSummary!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Color _statusColor(BuildContext context, String status) {
    final s = status.toLowerCase();
    if (s.contains('ok') || s == 'healthy' || s == 'up' || s == 'true') {
      return Colors.green;
    }
    if (s.contains('warn') || s.contains('degraded')) {
      return Colors.orange;
    }
    if (s.contains('down') || s.contains('fail') || s == 'false') {
      return Theme.of(context).colorScheme.error;
    }
    return Colors.grey;
  }

  String _statusLabel(String status) {
    final s = status.toLowerCase();
    if (s.contains('ok') || s == 'healthy' || s == 'up' || s == 'true') {
      return 'OK';
    }
    if (s.contains('warn') || s.contains('degraded')) {
      return 'WARN';
    }
    if (s.contains('down') || s.contains('fail') || s == 'false') {
      return 'DOWN';
    }
    return status.toUpperCase();
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.title,
    required this.ok,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool ok;

  @override
  Widget build(BuildContext context) {
    final color = ok ? Colors.green : Theme.of(context).colorScheme.error;
    final label = ok ? 'OK' : 'DOWN';
    final subtitleWidget = subtitle != null ? Text(subtitle!) : null;

    return Card(
      child: ListTile(
        leading: Icon(Icons.circle, color: color, size: 18),
        title: Text(title),
        subtitle: subtitleWidget,
        trailing: _StatusChip(label: label, color: color),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bg = (color ?? Colors.grey).withOpacity(0.15);
    final fg = color ?? Theme.of(context).colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (color ?? Colors.grey).withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
