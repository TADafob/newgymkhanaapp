import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nrbgymkhana/core/utils/appcolors.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/providers/cardrechargeprovider.dart';
import 'package:nrbgymkhana/features/Cardmanager/presentation/screen_ui/viewreceipt.dart';

// State provider for the top-up details
class TopUpSuccessPage extends ConsumerWidget {
  const TopUpSuccessPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receipt = ref.watch(receiptProvider);
    final isSuccess = receipt.status;

    return Scaffold(
      //appBar: TopAppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              color: AppKolors.primary,
              borderRadius: BorderRadiusDirectional.vertical(bottom: Radius.circular(50))
            ),
            child: Column(
              children: [
                Text(
                  'Recharge Card ${isSuccess ? 'Successful': 'failed'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.0,
                  ),
                ),
                Text(
                  'KSH ${receipt.amount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          // Success or Failure Icon
          CircleAvatar(
            radius: 80,
            backgroundColor: isSuccess ? Colors.green[100] : Colors.red[100],
            child: CircleAvatar(
              radius: 60,
            backgroundColor: isSuccess ? Colors.green.shade200 : Colors.red.shade300,
              child: CircleAvatar(
                radius: 40,
            backgroundColor: isSuccess ? Colors.green.shade300 : Colors.red.shade300,
                child: Icon(
                  isSuccess ? Icons.check_circle : Icons.cancel,
                  color: isSuccess ? Colors.white : Colors.red,
                  size: 60,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Success or Failure message
          Text(
            isSuccess ? 'Top Up Success' : 'Top Up Failed',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          // Amount Display
          Text(
            'Total Top Up\nKSH ${receipt.amount}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 10),
          // View Receipt link (only if success)
          if (isSuccess)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ViewReceiptPage(),
                  ),
                );
              },
              child: const Text(
                'View Receipt',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          const SizedBox(height: 30),
          // Instruction text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              isSuccess
                  ? 'The Top Up will reflect into your account after confirmation from the club\'s management. If this takes more than 2 minutes please call, 0712 347 899'
                  : 'Something went wrong. Please try again later or call 0712 347 899 for assistance.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14.0,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 30),
          // Back to Home button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ), 
              ),
              onPressed: () {
                ref.read(rechargeAmountProvider.notifier).clearAmount();
                context.go('/');
              },
              child: const Text(
                'Back to Home',
                style: TextStyle(
                  fontSize: 16.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}