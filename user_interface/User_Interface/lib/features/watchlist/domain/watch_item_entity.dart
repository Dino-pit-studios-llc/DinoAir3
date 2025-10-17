/// Domain entity representing a watchlisted coin.
class WatchItemEntity {
  const WatchItemEntity({required this.coinId, required this.addedAt});
  final String coinId;
  final DateTime addedAt;
}
