// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/providers/cardrechargeprovider.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/rechargeconfirmationpage.dart';

class RechargeCardScreen extends ConsumerWidget {
  const RechargeCardScreen({super.key});

  void updateAmount(WidgetRef ref, String value) {
    final currentAmount = ref.read(rechargeAmountProvider);

    if (value == 'x') {
      ref.read(rechargeAmountProvider.notifier).state =
          currentAmount.length > 1 ? currentAmount.substring(0, currentAmount.length - 1) : "0.00";
    } else {
      ref.read(rechargeAmountProvider.notifier).state =
          currentAmount == "0.00" ? value : currentAmount + value;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amount = ref.watch(rechargeAmountProvider);

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppKolors.primary,
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              const Text(
                "Recharge Card",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.normal,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Enter the number Recharge Amount",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "KSH $amount",
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _quickAmountButton(context, ref, "100.00"),
                    _quickAmountButton(context, ref, "500.00"),
                    _quickAmountButton(context, ref, "1,000.00"),
                    _quickAmountButton(context, ref, "1,500.00"),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 30),
        _buildKeypad(ref),
        const SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: ElevatedButton(
            onPressed: amount == "0.00" || amount == "0" ? null : () {
              ref.read(rechargeAmountProvider.notifier).updateAmount(amount);
              Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CardRechargeConfirmation()),
            );
            },
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor: amount == "0.00" || amount == "0"
                  ? Colors.grey.shade300
                  : AppKolors.primary,
            ),
            child: Text(
              "Continue",
              style: TextStyle(
                fontSize: 18,
                color: amount == "0.00" || amount == "0" ? Colors.grey : Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _quickAmountButton(BuildContext context, WidgetRef ref, String value) {
    return ElevatedButton(
      onPressed: () {
        
      },
      style: ElevatedButton.styleFrom(
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        backgroundColor: AppKolors.primary,
        foregroundColor: Colors.white,
        side: BorderSide(color: AppKolors.secondary.withValues(alpha: 0.2)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      child: Text(value),
    );
  }

  Widget _buildKeypad(WidgetRef ref) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      shrinkWrap: true,
      itemCount: 12,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.8,
        crossAxisSpacing: 15,
        mainAxisSpacing: 20,
      ),
      itemBuilder: (context, index) {
        String label;
        if (index < 9) {
          label = '${index + 1}';
        } else if (index == 9) {
          label = 'C';
        } else {
          label = index == 10 ? '0' : 'x';
        }
        return GestureDetector(
          onTap: () => label == 'C'
              ? ref.read(rechargeAmountProvider.notifier).clearAmount()
              : updateAmount(ref, label),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade400),
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}
