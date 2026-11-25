import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Support tickets (feedback, bug reports, reports, human support requests).
/// Laravel: POST /support/tickets, GET /support/tickets; admin panel handles them.
class Ticket {
  final String id;
  final String kind; // Feedback, Bug, Report, Support
  final String summary;
  final String time;
  final String status; // Open, In review, Resolved
  const Ticket(this.id, this.kind, this.summary, this.time, {this.status = 'Open'});
}

class SupportMessage {
  final bool mine;
  final String text;
  const SupportMessage(this.mine, this.text);
}

class SupportState {
  final List<Ticket> tickets;
  final List<SupportMessage> chat;
  const SupportState({this.tickets = const [], this.chat = const []});
}

const faq = <String, List<(String, String)>>{
  'Account': [
    ('How do I change my nickname?', 'Go to Me → Edit profile, or Settings → Account & security → Nickname.'),
    ('I forgot my password', 'On the login screen tap Email → Forgot password, or recover with your phone number.'),
    ('How do I delete my account?', 'Settings → Account & security → Delete account. You have 7 days to change your mind.'),
  ],
  'Coins & payments': [
    ('I paid but did not get coins', 'Coins usually arrive within 1 minute. If not, contact customer service with your order ID from Wallet → Purchase history.'),
    ('Can I get a refund?', 'Coins are non-refundable once used. For payment problems contact customer service within 7 days.'),
    ('What are diamonds?', 'You earn diamonds when people send you gifts. Exchange them for coins in your Wallet.'),
  ],
  'Voice rooms': [
    ('How do I create a room?', 'Tap the gold + button at the bottom of the Home screen.'),
    ('Someone is rude in my room', 'Tap their seat → Mute, Remove from mic or Ban from room. You can also report them.'),
    ('Why can\'t I take a seat?', 'The seat may be locked, or the room uses mic requests. Ask the host.'),
  ],
  'Safety': [
    ('How do I block someone?', 'Open their profile or chat → ••• → Block. Manage blocked users in Settings.'),
    ('Someone asked me for money', 'Never send money or share codes outside the app. Report the user immediately.'),
  ],
};

final supportProvider = NotifierProvider<SupportController, SupportState>(SupportController.new);

class SupportController extends Notifier<SupportState> {
  @override
  SupportState build() => const SupportState(
        tickets: [Ticket('T10231', 'Feedback', 'Add more room themes', '2 days ago', status: 'Resolved')],
        chat: [SupportMessage(false, 'Hi! I am Yolo Support. How can I help you today?')],
      );

  String _id() => 'T${10232 + state.tickets.length}';

  Ticket submit(String kind, String summary) {
    final t = Ticket(_id(), kind, summary, 'Just now');
    state = SupportState(tickets: [t, ...state.tickets], chat: state.chat);
    return t;
  }

  /// Simple keyword bot. A real agent replies through the admin panel.
  void ask(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    final q = t.toLowerCase();
    final String reply;
    if (q.contains('human') || q.contains('agent')) {
      final ticket = submit('Support', t);
      reply = 'I have connected you to our team. Ticket ${ticket.id} is open — an agent will reply within 24 hours.';
    } else if (q.contains('coin') || q.contains('recharge') || q.contains('pay')) {
      reply = 'For payment issues, please send your order ID from Wallet → Purchase history. Coins usually arrive within 1 minute.';
    } else if (q.contains('ban') || q.contains('blocked') || q.contains('suspend')) {
      reply = 'If your account was restricted you can appeal here. Type "human" to talk to an agent.';
    } else if (q.contains('password') || q.contains('login')) {
      reply = 'You can recover your account from the login screen → Email → Forgot password.';
    } else {
      reply = 'Thanks! Check the Help center for quick answers, or type "human" to talk to an agent.';
    }
    state = SupportState(tickets: state.tickets, chat: [...state.chat, SupportMessage(true, t), SupportMessage(false, reply)]);
  }
}
