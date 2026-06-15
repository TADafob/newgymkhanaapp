import 'package:flutter/material.dart';
import 'package:nrbgymkhana/features/common/widgets/commontopcontainer.dart';
import 'package:nrbgymkhana/features/common/widgets/thankyouwidget.dart';

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //appBar: TopAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            CommonTopContainer(
              title: 'SUPPORT',
              Image_url: 'assets/images/common/calendar.png',
              titleposition: 150,
            ),
            // Contact Info Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Phone Support
                  supportCard('Our 24X7 Member Support Number', '0708042394',
                      Icons.phone, () {}, true),
                  // Email Support
                  supportCard("Email us at", 'Techsupport@nairobigymkhana.com',
                      Icons.mail, () {}, true),
                  // Chat Live
                  supportCard(
                      "chat with us live",
                      'Click to chat with our support team',
                      Icons.mail,
                      () {},
                      false),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // FAQ Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Frequently Asked Questions (FAQ's)",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const FAQItem(
                    question: "Login Issues",
                    answer:
                        "1. Add new fastag.\n2. Go to Fastags.\n3. Click on Recharge button, and enter amount.\n4. Select payment method and pay.",
                  ),
                  const FAQItem(
                    question: "How do i make a booking?",
                    answer: "Yes, you can recharge fastags from any provider.",
                  ),
                  const FAQItem(
                    question:
                        "Recharge successful but amount not reflecting on account?",
                    answer:
                        "The deducted amount will be refunded within 3-5 working days.",
                  ),
                  const FAQItem(
                    question: "Confirmation requests taking long?",
                    answer: "Go to payment settings and add a card.",
                  ),
                  const FAQItem(
                    question: "Can't see my balance/Balance not reflecting?",
                    answer:
                        "No, toll transaction history is available only after account setup.",
                  ),
                  const FAQItem(
                    question: "Changing of personal information?",
                    answer:
                        "No, toll transaction history is available only after account setup.",
                  ),
                ],
              ),
            ),
            thankYouWidget(),
            SizedBox(
              height: 5,
            ),
            Text(
              'Thank you for trusting us',
              style: TextStyle(fontSize: 10),
            ),
            SizedBox(
              height: 20,
            )
          ],
        ),
      ),
    );
  }

  Card supportCard(String title, String subtitle, IconData icon,
      VoidCallback onTap, bool hasDivider) {
    return Card(
      elevation: 0,
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: Colors.blue),
            title: Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.black54),
            ),
            subtitle: Text(
              subtitle,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            onTap: onTap,
          ),
          hasDivider
              ? Divider(
                  indent: 10,
                  endIndent: 20,
                  color: Colors.grey,
                )
              : Container(),
        ],
      ),
    );
  }
}

class FAQItem extends StatefulWidget {
  final String question;
  final String answer;

  const FAQItem({super.key, required this.question, required this.answer});

  @override
  State<FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<FAQItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 10.0),
          title: Text(
            widget.question,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.answer,
                style: const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
          onExpansionChanged: (bool expanded) {
            setState(() {
              isExpanded = expanded;
            });
          },
        ),
      ),
    );
  }
}
