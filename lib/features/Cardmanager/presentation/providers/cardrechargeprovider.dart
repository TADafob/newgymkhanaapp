import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/features/Cardmanager/data/models/transactions.dart';

// StateNotifier to handle the recharge amount
class RechargeAmountNotifier extends StateNotifier<String> {
  RechargeAmountNotifier() : super("0.00");

  void updateAmount(String value) {
    state = value;
  }

  void clearAmount() {
    state = "0.00";
  }
}


// StateNotifierProvider to expose the RechargeAmountNotifier
// In your providers file
final rechargeAmountProvider = StateNotifierProvider<RechargeAmountNotifier, String>((ref) {
  return RechargeAmountNotifier();
});

final receiptProvider = StateProvider<Receipt>((ref) {
  return Receipt(
    receiptId: 'cY4434wCKy',
    companyName: 'Nairobi Gymkhana',
    address: 'Off Wangari Mathai Road',
    customerName: 'SWAMINARAYAN OTIENO',
    email: 'brynamegbor@gmail.com',
    phone: '(+233) 558317703',
    meterNumber: 'G131025521 (Bright’s Meter)',
    amount: ref.read(rechargeAmountProvider),
    paymentMethod: 'Lipa Na Mpesa',
    dateTime: DateTime(2025, 2, 20),
    status: true,
  );
});

