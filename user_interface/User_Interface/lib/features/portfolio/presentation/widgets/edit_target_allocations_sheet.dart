import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../market/domain/coin_entity.dart';
import '../../domain/portfolio_summary_entity.dart';
import '../providers/portfolio_providers.dart';

class EditTargetAllocationsSheet extends ConsumerStatefulWidget {
  const EditTargetAllocationsSheet({
    required this.summary,
    required this.coinLookup,
    required this.initialTargets,
    super.key,
  });

  final PortfolioSummaryEntity summary;
  final Map<String, CoinEntity> coinLookup;
  final Map<String, double> initialTargets;

  @override
  ConsumerState<EditTargetAllocationsSheet> createState() =>
      _EditTargetAllocationsSheetState();
}

class _EditTargetAllocationsSheetState
    extends ConsumerState<EditTargetAllocationsSheet> {
  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 1,
  );

  late final Map<String, TextEditingController> _controllers;
  late final List<_TargetRow> _rows;
  double _totalPercent = 0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initializeRows();
    _totalPercent = _calculateTotal();
  }

  void _initializeRows() {
    final actualMap = {
      for (final allocation in widget.summary.allocations)
        allocation.coinId: allocation.percent,
    };

    final allIds = <String>{...actualMap.keys, ...widget.initialTargets.keys};

    _rows = allIds
        .map(
          (id) => _TargetRow(
            coinId: id,
            displayName: widget.coinLookup[id]?.name ?? id.toUpperCase(),
            actualPercent: actualMap[id] ?? 0.0,
          ),
        )
        .toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    _controllers = {for (final row in _rows) row.coinId: _buildController(row)};
  }

  TextEditingController _buildController(_TargetRow row) {
    final existing = widget.initialTargets[row.coinId];
    return TextEditingController(
      text: existing != null ? _formatPercentValue(existing * 100) : '',
    )..addListener(_handleFieldChanged);
  }

  static String _formatPercentValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller
        ..removeListener(_handleFieldChanged)
        ..dispose();
    }
    super.dispose();
  }

  double _calculateTotal() {
    var total = 0.0;
    for (final controller in _controllers.values) {
      final parsed = double.tryParse(controller.text);
      if (parsed != null && parsed > 0) {
        total += parsed;
      }
    }
    return total;
  }

  void _handleFieldChanged() {
    setState(() {
      _totalPercent = _calculateTotal();
    });
  }

  Future<void> _onSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    final newTargets = <String, double>{};
    for (final row in _rows) {
      final controller = _controllers[row.coinId]!;
      final raw = controller.text.trim();
      if (raw.isEmpty) continue;
      final parsed = double.tryParse(raw);
      if (parsed == null) continue;
      final decimal = (parsed / 100).clamp(0.0, 1.0);
      if (decimal <= 0) continue;
      newTargets[row.coinId] = decimal;
    }

    try {
      await ref
          .read(portfolioTargetAllocationsProvider.notifier)
          .saveAll(newTargets);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _promptAddCoin() async {
    final controller = TextEditingController();
    final theme = Theme.of(context);
    final newId = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add target coin'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Coin ID (e.g. btc)',
            hintText: 'Enter lowercase ID from data source',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text('Cancel', style: theme.textTheme.labelLarge),
          ),
          FilledButton(
            onPressed: () => Navigator.of(
              dialogContext,
            ).pop(controller.text.trim().toLowerCase()),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (newId == null || newId.isEmpty) return;
    if (_controllers.containsKey(newId)) return;

    final displayName = widget.coinLookup[newId]?.name ?? newId.toUpperCase();
    final allocation = widget.summary.allocations.firstWhere(
      (allocation) => allocation.coinId == newId,
      orElse: () => const Allocation(coinId: '', value: 0, percent: 0),
    );
    final newRow = _TargetRow(
      coinId: newId,
      displayName: displayName,
      actualPercent: allocation.percent,
    );

    setState(() {
      _rows
        ..add(newRow)
        ..sort((a, b) => a.displayName.compareTo(b.displayName));
      _controllers[newId] = TextEditingController()
        ..addListener(_handleFieldChanged);
      _totalPercent = _calculateTotal();
    });
  }

  void _clearTarget(String coinId) {
    final controller = _controllers[coinId];
    if (controller == null) return;
    controller.text = '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final targetDecimal = (_totalPercent / 100).clamp(0.0, 10.0);
    final remaining = 100 - _totalPercent;
    final remainingLabel = remaining > 0
        ? '${remaining.toStringAsFixed(remaining.abs() < 1 ? 1 : 0)}% unassigned'
        : remaining < 0
            ? '${remaining.abs().toStringAsFixed(remaining.abs() < 1 ? 1 : 0)}% over target'
            : 'Targets total 100%';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Target allocations',
                            style: theme.textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Set the ideal percentage for each position. Leave blank to skip.',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add custom coin target',
                      onPressed: _promptAddCoin,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _rows.length,
                  separatorBuilder: (context, _) => const Divider(height: 24),
                  itemBuilder: (context, index) => _TargetRowTile(
                    row: _rows[index],
                    controller: _controllers[_rows[index].coinId]!,
                    onClear: () => _clearTarget(_rows[index].coinId),
                  ),
                ),
              ),
              const Divider(height: 0),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    Icon(
                      Icons.toll_outlined,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Targets cover ${_percentFormat.format(targetDecimal)}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    remainingLabel,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: remaining > 0
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.error,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: _isSaving ? null : _onSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save),
                      label: const Text('Save targets'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TargetRow {
  const _TargetRow({
    required this.coinId,
    required this.displayName,
    required this.actualPercent,
  });

  final String coinId;
  final String displayName;
  final double actualPercent;
}

class _TargetRowTile extends StatelessWidget {
  const _TargetRowTile({
    required this.row,
    required this.controller,
    required this.onClear,
  });

  final _TargetRow row;
  final TextEditingController controller;
  final VoidCallback onClear;

  static final NumberFormat _percentFormat = NumberFormat.decimalPercentPattern(
    decimalDigits: 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final actualLabel = _percentFormat.format(row.actualPercent);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.displayName, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                'Actual: $actualLabel',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\.]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Target %',
              suffixText: '%',
            ),
          ),
        ),
        IconButton(
          tooltip: 'Clear target',
          onPressed: onClear,
          icon: const Icon(Icons.clear),
        ),
      ],
    );
  }
}
