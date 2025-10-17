import 'package:crypto_dash/features/portfolio/domain/holding_entity.dart';

class HoldingRecord {
  const HoldingRecord({
    required this.coinId,
    required this.amount,
    required this.avgBuyPrice,
    required this.updatedAt,
  });

  factory HoldingRecord.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final amount = json['amount'];
    final avg = json['avg'];
    final updated = json['updated'];

    if (id is! String || id.isEmpty) {
      throw const FormatException('Invalid holding id');
    }

    return HoldingRecord(
      coinId: id,
      amount: amount is num ? amount.toDouble() : 0,
      avgBuyPrice: avg is num ? avg.toDouble() : 0,
      updatedAt: updated is String
          ? DateTime.tryParse(updated) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory HoldingRecord.fromEntity(
    HoldingEntity entity, {
    DateTime? updatedAt,
  }) {
    return HoldingRecord(
      coinId: entity.coinId,
      amount: entity.amount,
      avgBuyPrice: entity.avgBuyPrice,
      updatedAt: updatedAt ?? DateTime.now().toUtc(),
    );
  }

  final String coinId;
  final double amount;
  final double avgBuyPrice;
  final DateTime updatedAt;

  HoldingEntity toEntity() =>
      HoldingEntity(coinId: coinId, amount: amount, avgBuyPrice: avgBuyPrice);

  HoldingRecord copyWith({
    String? coinId,
    double? amount,
    double? avgBuyPrice,
    DateTime? updatedAt,
  }) {
    return HoldingRecord(
      coinId: coinId ?? this.coinId,
      amount: amount ?? this.amount,
      avgBuyPrice: avgBuyPrice ?? this.avgBuyPrice,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': coinId,
        'amount': amount,
        'avg': avgBuyPrice,
        'updated': updatedAt.toIso8601String(),
      };
}
