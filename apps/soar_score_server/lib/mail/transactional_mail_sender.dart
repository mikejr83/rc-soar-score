/// A plain-text message for the shared transactional sender.
///
/// Callers describe the intended destinations; [TransactionalMailSender]
/// applies the delivery mode (live or redirect) before anything is sent.
/// Nothing here is support-specific, so invitation mail (#790) can reuse it.
class MailMessage {
  const MailMessage({
    required this.to,
    this.cc = const [],
    this.bcc = const [],
    required this.replyTo,
    required this.subject,
    required this.text,
  });

  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final List<String> replyTo;
  final String subject;
  final String text;
}

/// The result of one send.
sealed class MailOutcome {
  const MailOutcome();
}

/// The provider accepted the message and returned [messageId].
final class MailAccepted extends MailOutcome {
  const MailAccepted(this.messageId);
  final String messageId;
}

/// The provider explicitly refused the request; nothing was sent.
final class MailRejected extends MailOutcome {
  const MailRejected();
}

/// The sender cannot send right now (missing configuration, throttling,
/// denied credentials). Nothing was sent.
final class MailUnavailable extends MailOutcome {
  const MailUnavailable();
}

/// The request may or may not have been accepted: a server failure, a lost
/// response, a timeout or a success without a message id.
final class MailUnconfirmed extends MailOutcome {
  const MailUnconfirmed();
}

/// Sends mail on behalf of the application.
abstract interface class TransactionalMailSender {
  Future<MailOutcome> send(MailMessage message);
}
