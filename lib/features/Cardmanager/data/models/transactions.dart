class Receipt {
  final String receiptId;
  final String companyName;
  final String address;
  final String customerName;
  final String email;
  final String phone;
  final String meterNumber;
  final String amount;
  final String paymentMethod;
  final DateTime dateTime;
  final bool status; // true = success, false = failed

  Receipt({
    required this.receiptId,
    required this.companyName,
    required this.address,
    required this.customerName,
    required this.email,
    required this.phone,
    required this.meterNumber,
    required this.amount,
    required this.paymentMethod,
    required this.dateTime,
    required this.status,
  });
}
