import 'package:flutter/material.dart';

Future<bool?> showExitConfirmationDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Cancel Booking'),
      content: Text('Are you sure you want to cancel the booking process? Your changes will not be saved.'),
      actions: [
        TextButton(
          onPressed: Navigator.of(context).pop,
          child: Text('No'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
          },
          child: Text('Yes'),
        ),
      ],
    ),
  );
}