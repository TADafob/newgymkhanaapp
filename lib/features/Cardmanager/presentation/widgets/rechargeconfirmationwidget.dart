// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/core/utils/mpesa_payment_sheet.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/providers/cardrechargeprovider.dart';

// State for the selected payment method
final selectedPaymentProvider = StateProvider<int>((ref) => 0);

class RechargeConfirmationWidget extends ConsumerWidget {
  const RechargeConfirmationWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accountBalance = "Ksh. 3,200";
    final topUpAmount = ref.watch(rechargeAmountProvider);
    final date = "Nov 19/2024";
    final time = "12:30 PM";
    final accountNumber = "S-02-0034";

    final selectedPaymentIndex = ref.watch(selectedPaymentProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Section
        Container(
          width: double.infinity,
          height: 130,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: const BoxDecoration(
            color: AppKolors.primary,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(60),
            ),
          ),
          child: Column(
            children: [
              const Text(
                "Recharge Card",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Ksh. $topUpAmount',
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // Info Alert
        Container(
          width: double.infinity,
          margin: EdgeInsets.symmetric(horizontal: 30),
          decoration: BoxDecoration(
            color: AppKolors.primary.withValues(alpha: .3),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: const [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "Top up using M-Pesa will incur charges",
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Account Information
        _infoRow("Account Balance", accountBalance, Colors.red),
        const SizedBox(height: 10),
        _infoRow("Top Up Amount", 'Ksh. $topUpAmount', Colors.green),
        const SizedBox(height: 10),
        _infoRow("Date", date),
        const SizedBox(height: 10),
        _infoRow("Time", time),
        const SizedBox(height: 10),
        _infoRow("Account", accountNumber),
        const Divider(height: 40, indent: 20, endIndent: 20,),
        // Payment Method Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Select Payment Method",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              // Payment Options
              _paymentMethod(
                context,
                ref,
                imageUrl: "assets/images/rechargescreen/mastercardLogo.png",
                title: "Master Card",
                description: "4246 7515 4553 5246",
                index: 0,
                isSelected: selectedPaymentIndex == 0,
              ),
              const SizedBox(height: 10),
              _paymentMethod(
                context,
                ref,
                imageUrl: "assets/images/rechargescreen/MpesaLogo.png",
                title: "Mpesa",
                description: "0712 345 678",
                index: 1,
                isSelected: selectedPaymentIndex == 1,
                changeable: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 50),
        // Continue Button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ElevatedButton(
            onPressed: topUpAmount == "0.00" || topUpAmount == "0"
                ? null
                : () async {
                    final parsedAmount =
                        int.tryParse(topUpAmount.replaceAll(',', '').replaceAll('.00', '')) ?? 0;
                    if (parsedAmount <= 0) return;
                    final uid = FirebaseAuth.instance.currentUser?.uid;
                    final paid = await showMpesaPaymentSheet(
                      context,
                      amount: parsedAmount,
                      accountRef: 'CardRecharge',
                      description: 'Card Recharge',
                      title: 'Recharge Card',
                      onSuccess: (data) async {
                        if (uid == null) return;
                        final receiptNo =
                            data['mpesaReceiptNumber'] as String? ?? '';
                        final batch = FirebaseFirestore.instance.batch();
                        final txRef = FirebaseFirestore.instance
                            .collection('users_members')
                            .doc(uid)
                            .collection('card_transactions')
                            .doc();
                        batch.set(txRef, {
                          'trans_Type': 'Top Up',
                          'trans_Amount': parsedAmount,
                          'trans_Descr': 'Card Recharge via M-Pesa',
                          'trans_Id': receiptNo,
                          'trans_Date': Timestamp.now(),
                        });
                        final userRef = FirebaseFirestore.instance
                            .collection('users_members')
                            .doc(uid);
                        batch.update(userRef, {
                          'wallet_Balance': FieldValue.increment(parsedAmount),
                        });
                        await batch.commit();
                      },
                    );
                    if (paid == true && context.mounted) {
                      ref.read(rechargeAmountProvider.notifier).clearAmount();
                      Navigator.of(context).popUntil((r) => r.isFirst);
                    }
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              backgroundColor: const Color(0xFF5E60CE),
            ),
            child: const Text(
              "Continue",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value, [Color? valueColor]) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: valueColor ?? Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentMethod(
    BuildContext context,
    WidgetRef ref, {
    required String imageUrl,
    required String title,
    required String description,
    required int index,
    required bool isSelected,
    bool changeable = false,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(selectedPaymentProvider.notifier).state = index;
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF5E60CE) : Colors.grey.shade400,
          ),
          color: Colors.grey.shade100,
        ),
        child: Row(
          children: [
            Image.asset(
              imageUrl,
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        description,
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      if (changeable)
                        Padding(
                          padding: const EdgeInsets.only(right: 100),
                          child: GestureDetector(onTap: () {}, child: Text('change', style: TextStyle(fontSize: 12, color: Colors.blue))),
                        )
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: isSelected ? const Color(0xFF5E60CE) : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
