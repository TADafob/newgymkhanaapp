import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:nrbgymkhana/features/Events/presentation/providers/ticketnotifier.dart';

class TicketSection extends ConsumerWidget {
  final List<Map<String, dynamic>> categories;
  final bool isFree;
  final int basePrice;

  const TicketSection({
    super.key,
    required this.categories,
    required this.isFree,
    required this.basePrice,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(ticketQuantitiesProvider);
    if (categories.isEmpty) {
      final q = qty['default'] ?? 0;
      return Column(children: [
        _QuantityRow(label: 'Quantity', quantity: q, onDec: () => ref.read(ticketQuantitiesProvider.notifier).decrement('default'),
          onInc: () => ref.read(ticketQuantitiesProvider.notifier).increment('default'),
        ),
        _TotalRow(
          label: 'Total Price',
          text: isFree ? 'Free' : 'KES ${basePrice * q}',
        ),
      ]);
    }

    return Column(
      children: categories.map((cat) {
        final name = cat['name'] as String? ?? '';
        final price = cat['price'] as int? ?? 0;
        final max   = cat['maxTickets'] as int? ?? 100;
        final cur   = qty[name] ?? 0;

        return _CategoryTile(
          name: name, price: price, quantity: cur, max: max,
          onDec: () => ref.read(ticketQuantitiesProvider.notifier).decrement(name),
          onInc: () => ref.read(ticketQuantitiesProvider.notifier).increment(name),
        );
      }).toList(),
    );
  }
}

class _QuantityRow extends StatelessWidget {
  final String label;
  final int quantity;
  final VoidCallback onDec, onInc;
  const _QuantityRow({required this.label, required this.quantity, required this.onDec, required this.onInc});

  @override
  Widget build(BuildContext c) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label),
      Row(children: [
        IconButton(onPressed: onDec, icon: const Icon(Icons.remove)),
        Text('$quantity'),
        IconButton(onPressed: onInc, icon: const Icon(Icons.add)),
      ]),
    ],
  );
}

class _TotalRow extends StatelessWidget {
  final String label, text;
  const _TotalRow({required this.label, required this.text});
  @override
  Widget build(BuildContext c) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [Text(label), Text(text, style: const TextStyle(fontWeight: FontWeight.bold))],
  );
}

class _CategoryTile extends StatelessWidget {
  final String name;
  final int price, quantity, max;
  final VoidCallback onDec, onInc;
  const _CategoryTile({
    required this.name, required this.price, required this.quantity, required this.max,
    required this.onDec, required this.onInc,
  });

  @override
  Widget build(BuildContext c) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(name),
          if (quantity > 0) Text('KSH ${price * quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        Row(children: [Text('KSH $price per ticket')]),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Quantity:'),
          Row(children: [
            IconButton(onPressed: onDec, icon: const Icon(Icons.remove)),
            Text('$quantity'),
            IconButton(onPressed: onInc, icon: const Icon(Icons.add)),
          ]),
        ]),
        if (quantity == max) Text('Maximum $max tickets allowed.', style: TextStyle(color: Colors.red[700])),
      ]),
    );
  }
}
