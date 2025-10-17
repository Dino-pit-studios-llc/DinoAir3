import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../market/domain/coin_entity.dart';
import '../../domain/holding_entity.dart';
import '../providers/portfolio_providers.dart';

enum EntryMode { coinAmount, usdValue }

class EditHoldingSheet extends ConsumerStatefulWidget {
  const EditHoldingSheet({this.initialHolding, required this.coins, super.key});

  final HoldingEntity? initialHolding;
  final List<CoinEntity> coins;

  @override
  ConsumerState<EditHoldingSheet> createState() => _EditHoldingSheetState();
}

class _EditHoldingSheetState extends ConsumerState<EditHoldingSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _coinController;
  late final TextEditingController _amountController;
  late final TextEditingController _avgPriceController;
  bool _submitted = false;
  EntryMode _entryMode = EntryMode.coinAmount;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialHolding;
    _coinController = TextEditingController(text: initial?.coinId ?? '');
    _amountController = TextEditingController(
      text: initial != null ? _trimTrailingZeros(initial.amount) : '',
    );
    _avgPriceController = TextEditingController(
      text: initial != null ? _trimTrailingZeros(initial.avgBuyPrice) : '',
    );
  }

  @override
  void dispose() {
    _coinController.dispose();
    _amountController.dispose();
    _avgPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controllerState = ref.watch(portfolioControllerProvider);
    final isEditing = widget.initialHolding != null;
    final isLoading = controllerState.isLoading;

    ref.listen<AsyncValue<void>>(portfolioControllerProvider, (prev, next) {
      if (!mounted) return;
      if (prev?.isLoading == true && next is AsyncData<void>) {
        final coinId = _coinController.text.trim().toLowerCase();
        Navigator.of(context).pop((coinId: coinId, isEdit: isEditing));
      }
    });

    final mediaQuery = MediaQuery.of(context);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: mediaQuery.viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        autovalidateMode:
            _submitted ? AutovalidateMode.always : AutovalidateMode.disabled,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    isEditing ? 'Edit Holding' : 'Add Holding',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _coinController,
                enabled: !isEditing,
                decoration: const InputDecoration(
                  labelText: 'Coin ID',
                  hintText: 'e.g. bitcoin',
                ),
                validator: (value) {
                  final trimmed = value?.trim() ?? '';
                  if (trimmed.isEmpty) {
                    return 'Coin id is required';
                  }
                  return null;
                },
              ),
              if (!isEditing && widget.coins.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Quick picks', style: theme.textTheme.labelLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.coins.take(8).map((coin) {
                    return ActionChip(
                      label: Text(
                        '${coin.symbol.toUpperCase()} (${coin.name})',
                      ),
                      onPressed: () {
                        _coinController.text = coin.id;
                        _autoFillPrice(coin.id);
                      },
                    );
                  }).toList(growable: false),
                ),
              ],
              const SizedBox(height: 16),
              Text('Entry Method', style: theme.textTheme.labelLarge),
              const SizedBox(height: 8),
              SegmentedButton<EntryMode>(
                segments: const [
                  ButtonSegment(
                    value: EntryMode.coinAmount,
                    label: Text('Coin Amount'),
                    icon: Icon(Icons.numbers),
                  ),
                  ButtonSegment(
                    value: EntryMode.usdValue,
                    label: Text('USD Value'),
                    icon: Icon(Icons.attach_money),
                  ),
                ],
                selected: {_entryMode},
                onSelectionChanged: (Set<EntryMode> newSelection) {
                  setState(() {
                    _entryMode = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: _entryMode == EntryMode.coinAmount
                      ? 'Amount held (coins)'
                      : 'Total value (USD)',
                  hintText: _entryMode == EntryMode.coinAmount
                      ? 'e.g. 2.5'
                      : 'e.g. 50000',
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  if (parsed <= 0) {
                    return _entryMode == EntryMode.coinAmount
                        ? 'Amount must be greater than zero'
                        : 'Value must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _avgPriceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Average buy price (USD)',
                  hintText: 'e.g. 25000',
                  helperText: _entryMode == EntryMode.usdValue
                      ? 'Required for USD value calculation'
                      : null,
                ),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  if (parsed < 0) {
                    return 'Price cannot be negative';
                  }
                  // Extra validation for USD mode
                  if (_entryMode == EntryMode.usdValue && parsed == 0) {
                    return 'Price must be greater than zero for USD entry';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Add Holding'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    setState(() {
      _submitted = true;
    });
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final coinId = _coinController.text.trim().toLowerCase();
    final avgPrice = double.tryParse(_avgPriceController.text.trim());
    if (avgPrice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid average price. Please enter a valid number.'),
        ),
      );
      return;
    }

    // Calculate coin amount based on entry mode
    final double coinAmount;
    if (_entryMode == EntryMode.coinAmount) {
      // User entered coin amount directly
      final parsedAmount = double.tryParse(_amountController.text.trim());
      if (parsedAmount == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid amount. Please enter a valid number.'),
          ),
        );
        return;
      }
      coinAmount = parsedAmount;
    } else {
      // User entered USD value; calculate coin amount
      final usdValue = double.tryParse(_amountController.text.trim());
      if (usdValue == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid USD value. Please enter a valid number.'),
          ),
        );
        return;
      }
      // avgPrice == 0 is already prevented by form validation
      coinAmount = usdValue / avgPrice;
    }

    final holding = HoldingEntity(
      coinId: coinId,
      amount: coinAmount,
      avgBuyPrice: avgPrice,
    );

    try {
      await ref.read(portfolioControllerProvider.notifier).save(holding);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save holding: $error')));
    }
  }

  void _autoFillPrice(String coinId) {
    // Only auto-fill if the price field is empty and not editing
    if (_avgPriceController.text.trim().isNotEmpty ||
        widget.initialHolding != null) {
      return;
    }

    // Find the coin in the list and populate its current price
    final coin = widget.coins.firstWhere(
      (c) => c.id == coinId,
      orElse: () => widget.coins.first,
    );

    if (coin.id == coinId && coin.price > 0) {
      _avgPriceController.text = _trimTrailingZeros(coin.price);

      // Show a helpful snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Current price (${_formatPrice(coin.price)}) auto-filled',
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    if (price >= 1) {
      return '\$${price.toStringAsFixed(2)}';
    } else {
      return '\$${_trimTrailingZeros(price)}';
    }
  }

  String _trimTrailingZeros(double value) {
    var text = value.toStringAsFixed(8);
    if (text.contains('.')) {
      text = text.replaceFirst(RegExp(r'0+$'), '');
      if (text.endsWith('.')) {
        text = text.substring(0, text.length - 1);
      }
    }
    return text;
  }
}
