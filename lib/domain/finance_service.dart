import 'models.dart';

class FinanceService {
  const FinanceService();

  int earnings({required int revenueMinor, required PaymentSettings payment}) =>
      payment.dailyRateMinor +
      (revenueMinor * payment.revenuePercent / 100).round();
}
