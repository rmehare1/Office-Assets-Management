import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

Future<void> sendEmail(String to, String subject, String body) async {
  final smtpServer = gmail('your-email@gmail.com', 'your-password');

  final message = Message()
    ..from = Address('your-email@gmail.com', 'Your Name')
    ..recipients.add(to)
    ..subject = subject
    ..text = body;

  try {
    await send(message, smtpServer);
    print('Email sent successfully!');
  } catch (e) {
    print('Error sending email: $e');
  }
}

extension StringExtension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}
