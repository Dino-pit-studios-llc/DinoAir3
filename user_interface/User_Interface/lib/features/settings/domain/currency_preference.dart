/// Supported fiat currencies for value display.
enum FiatCurrency { usd, eur }

extension FiatCurrencyCode on FiatCurrency {
  String get code =>
      switch (this) { FiatCurrency.usd => 'USD', FiatCurrency.eur => 'EUR' };
}
