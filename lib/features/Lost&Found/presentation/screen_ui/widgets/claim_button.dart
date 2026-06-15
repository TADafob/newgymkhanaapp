import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// If you have a ClaimItem use-case, import it here.
// import 'package:nrbgymkhana/features/lost_and_found/domain/usecases/claim_item.dart';

class ClaimButton extends ConsumerWidget {
  final bool isClaimed;
  final bool isCollected;
  final String documentId;
  const ClaimButton({
    required this.isClaimed,
    required this.isCollected,
    required this.documentId,
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton(
      onPressed: isClaimed ? null : () => _confirmAndClaim(context, ref),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isClaimed ? Icons.check_circle : Icons.add_circle_outline),
          const SizedBox(width: 12),
          Text(
            isCollected
                ? "Already Collected"
                : isClaimed
                    ? "Already Claimed"
                    : "Claim This Item",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndClaim(BuildContext context, WidgetRef ref) async {
    // duplicate your existing dialog + Firestore update logic here,
    // or better still call your ClaimItem use-case.
  }
}
