import 'package:flutter/material.dart';
import 'package:nrbgymkhana/core/utils/africas_talking_service.dart';

class ATTestScreen extends StatefulWidget {
  const ATTestScreen({super.key});

  @override
  State<ATTestScreen> createState() => _ATTestScreenState();
}

class _ATTestScreenState extends State<ATTestScreen> {
  final _phoneCtrl = TextEditingController(text: '+254');
  ATChannel _channel = ATChannel.sms;
  String _status = '';
  bool _loading = false;

  Future<void> _runTest() async {
    setState(() { _loading = true; _status = ''; });
    try {
      final result = await AfricasTalkingService.testSend(
        phone: _phoneCtrl.text.trim(),
        channel: _channel,
      );
      setState(() => _status = 'Success ✅\n${result.toString()}');
    } catch (e) {
      setState(() => _status = 'Error ❌\n$e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Africa's Talking Test")),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone (e.g. +254712345678)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            Row(
              children: ATChannel.values.map((ch) {
                return Expanded(
                  child: RadioListTile<ATChannel>(
                    title: Text(ch.name.toUpperCase()),
                    value: ch,
                    groupValue: _channel,
                    onChanged: (v) => setState(() => _channel = v!),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _runTest,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Send Test Message'),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _status.startsWith('Success')
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _status.startsWith('Success') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(_status),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
