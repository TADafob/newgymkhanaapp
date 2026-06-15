
class Subscription {
  final String subsId;
  final String docId;
  final String subsPlan;
  final String subsCatId;
  final String userId;
  final String status;
  final DateTime subsDate;
  final DateTime expiryDate;
  final int amount;
  final bool isPaid;

  Subscription({
    required this.subsId,
    this.docId = '',
    required this.subsPlan,
    required this.subsCatId,
    required this.userId,
    required this.status,
    required this.subsDate,
    required this.expiryDate,
    required this.amount,
    required this.isPaid,
  });
}