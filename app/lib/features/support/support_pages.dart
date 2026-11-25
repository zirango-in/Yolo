import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/support_providers.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

InputDecoration _deco(String label) => InputDecoration(
      labelText: label,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
    );

void _submitted(BuildContext context, Ticket t) {
  showYoloToast(context, 'Sent! Ticket ${t.id}');
  context.pop();
}

/// Help center: search FAQ, quick actions, safety & legal, my tickets.
class HelpCenterScreen extends ConsumerStatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  ConsumerState<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends ConsumerState<HelpCenterScreen> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final tickets = ref.watch(supportProvider).tickets;
    final q = _q.trim().toLowerCase();

    Widget action(IconData icon, String label, Color color, String route) => Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(route),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(children: [TintIcon(icon, color: color, size: 46), const SizedBox(height: 6), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))]),
            ),
          ),
        );

    return YoloPage(
      title: 'Help center',
      body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _q = v),
            decoration: InputDecoration(
              hintText: 'Search help articles',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
            ),
          ),
        ),
        if (q.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(children: [
              action(Icons.support_agent_rounded, 'Customer service', const Color(0xFF86EFAC), '/support/chat'),
              action(Icons.rate_review_rounded, 'Feedback', const Color(0xFF7DD3FC), '/support/feedback'),
              action(Icons.bug_report_rounded, 'Report a bug', const Color(0xFFFDBA74), '/support/bug'),
              action(Icons.flag_rounded, 'Report issue', const Color(0xFFF87171), '/support/report'),
            ]),
          ),
        for (final entry in faq.entries) ...[
          if (q.isEmpty || entry.value.any((f) => '${f.$1} ${f.$2}'.toLowerCase().contains(q))) SectionTitle(entry.key),
          for (final (question, answer) in entry.value)
            if (q.isEmpty || '$question $answer'.toLowerCase().contains(q))
              GlassCard(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: EdgeInsets.zero,
                child: ExpansionTile(
                  title: Text(question, style: const TextStyle(fontWeight: FontWeight.w600)),
                  iconColor: YoloColors.gold,
                  collapsedIconColor: YoloColors.textMuted,
                  shape: const Border(),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  expandedAlignment: Alignment.centerLeft,
                  children: [Text(answer, style: const TextStyle(color: YoloColors.textSoft, height: 1.45))],
                ),
              ),
        ],
        if (q.isEmpty) ...[
          const SectionTitle('Safety & legal'),
          GlassCard(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: EdgeInsets.zero,
            child: Column(children: [
              for (final (icon, label, route) in [
                (Icons.shield_rounded, 'Safety guidelines', '/legal/safety'),
                (Icons.privacy_tip_rounded, 'Privacy policy', '/legal/privacy'),
                (Icons.description_rounded, 'Terms of service', '/legal/terms'),
                (Icons.delete_forever_rounded, 'Delete my account', '/account'),
              ])
                ListTile(
                  leading: Icon(icon, color: YoloColors.gold),
                  title: Text(label),
                  trailing: const Icon(Icons.chevron_right_rounded, color: YoloColors.textMuted),
                  onTap: () => context.push(route),
                ),
            ]),
          ),
          SectionTitle('My tickets (${tickets.length})', action: 'See all', onAction: () => context.push('/support/tickets')),
        ],
      ]),
    );
  }
}

/// Customer service chat (keyword bot + human handoff).
class CustomerServiceScreen extends ConsumerStatefulWidget {
  const CustomerServiceScreen({super.key});

  @override
  ConsumerState<CustomerServiceScreen> createState() => _CustomerServiceScreenState();
}

class _CustomerServiceScreenState extends ConsumerState<CustomerServiceScreen> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? text]) {
    ref.read(supportProvider.notifier).ask(text ?? _input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(supportProvider).chat;
    return YoloPage(
      title: 'Customer service',
      body: Column(children: [
        Expanded(
          child: ListView.builder(
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: chat.length,
            itemBuilder: (_, i) {
              final m = chat[chat.length - 1 - i];
              return Align(
                alignment: m.mine ? Alignment.centerRight : Alignment.centerLeft,
                child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (!m.mine) const Padding(padding: EdgeInsets.only(right: 6), child: TintIcon(Icons.support_agent_rounded, color: Color(0xFF86EFAC), size: 32)),
                  Flexible(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      constraints: const BoxConstraints(maxWidth: 270),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        gradient: m.mine ? YoloColors.goldGradient : null,
                        color: m.mine ? null : YoloColors.surface,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Text(m.text, style: TextStyle(color: m.mine ? YoloColors.onGold : YoloColors.text)),
                    ),
                  ),
                ]),
              ).entrance(0);
            },
          ),
        ),
        SizedBox(
          height: 44,
          child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: [
            for (final s in ['Coins not received', 'Account banned', 'Forgot password', 'Talk to a human'])
              Padding(padding: const EdgeInsets.only(right: 8), child: ActionChip(label: Text(s), onPressed: () => _send(s))),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  decoration: InputDecoration(
                    hintText: 'Describe your problem',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.08),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  ),
                ),
              ),
              IconButton(tooltip: 'Send', icon: const Icon(Icons.send_rounded, color: YoloColors.gold), onPressed: _send),
            ]),
          ),
        ),
      ]),
    );
  }
}

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _text = TextEditingController();
  int _stars = 0;
  String _topic = 'Suggestion';

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _stars > 0 && _text.text.trim().length >= 5;
    return YoloPage(
      title: 'Feedback',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('How do you like Yolo?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 1; i <= 5; i++)
            IconButton(
              tooltip: '$i stars',
              iconSize: 40,
              icon: Icon(i <= _stars ? Icons.star_rounded : Icons.star_outline_rounded, color: YoloColors.gold),
              onPressed: () => setState(() => _stars = i),
            ),
        ]),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: [
          for (final t in ['Suggestion', 'Compliment', 'Complaint', 'Other'])
            ChoiceChip(
              label: Text(t),
              selected: _topic == t,
              onSelected: (_) => setState(() => _topic = t),
              selectedColor: YoloColors.gold,
              showCheckmark: false,
              labelStyle: TextStyle(color: _topic == t ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
            ),
        ]),
        const SizedBox(height: 14),
        TextField(controller: _text, maxLines: 5, maxLength: 500, onChanged: (_) => setState(() {}), decoration: _deco('Tell us more')),
        const SizedBox(height: 10),
        Opacity(
          opacity: ok ? 1 : 0.5,
          child: GoldButton(
            label: 'Send feedback',
            onPressed: ok ? () => _submitted(context, ref.read(supportProvider.notifier).submit('Feedback', '$_stars★ $_topic: ${_text.text.trim()}')) : null,
          ),
        ),
      ]),
    );
  }
}

class BugReportScreen extends ConsumerStatefulWidget {
  const BugReportScreen({super.key});

  @override
  ConsumerState<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends ConsumerState<BugReportScreen> {
  final _text = TextEditingController();
  String _area = 'Voice rooms';
  String? _shot;
  bool _deviceInfo = true;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _text.text.trim().length >= 10;
    return YoloPage(
      title: 'Report a bug',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        const Text('Where did it happen?', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final a in ['Voice rooms', 'Chat', 'Gifts & coins', 'Profile', 'Family', 'Login', 'Other'])
            ChoiceChip(
              label: Text(a),
              selected: _area == a,
              onSelected: (_) => setState(() => _area = a),
              selectedColor: YoloColors.gold,
              showCheckmark: false,
              labelStyle: TextStyle(color: _area == a ? YoloColors.onGold : YoloColors.text, fontWeight: FontWeight.w700),
            ),
        ]),
        const SizedBox(height: 14),
        TextField(controller: _text, maxLines: 6, maxLength: 1000, onChanged: (_) => setState(() {}), decoration: _deco('What happened? Steps to reproduce (at least 10 characters)')),
        const SizedBox(height: 8),
        GlassCard(
          onTap: () async {
            try {
              final img = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
              if (img != null) setState(() => _shot = img.path);
            } catch (_) {
              if (context.mounted) showYoloToast(context, 'Could not open gallery');
            }
          },
          child: Row(children: [
            if (_shot != null && !kIsWeb)
              ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(_shot!), width: 48, height: 48, fit: BoxFit.cover))
            else
              const Icon(Icons.add_photo_alternate_rounded, color: YoloColors.gold, size: 32),
            const SizedBox(width: 12),
            Expanded(child: Text(_shot == null ? 'Attach a screenshot (optional)' : 'Screenshot attached')),
          ]),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include device info'),
          subtitle: const Text('Phone model, Android version and app version', style: TextStyle(fontSize: 12)),
          value: _deviceInfo,
          activeThumbColor: YoloColors.gold,
          onChanged: (v) => setState(() => _deviceInfo = v),
        ),
        const SizedBox(height: 8),
        Opacity(
          opacity: ok ? 1 : 0.5,
          child: GoldButton(
            label: 'Send bug report',
            onPressed: ok ? () => _submitted(context, ref.read(supportProvider.notifier).submit('Bug', '$_area: ${_text.text.trim()}')) : null,
          ),
        ),
      ]),
    );
  }
}

/// Report a user, room, post or game issue.
class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen> {
  static const _types = ['User', 'Room', 'Post', 'Game issue'];
  static const _reasons = ['Harassment', 'Sexual content', 'Hate speech', 'Scam / fraud', 'Violence', 'Underage', 'Cheating', 'Other'];
  final _target = TextEditingController();
  final _details = TextEditingController();
  String _type = 'User';
  String? _reason;

  @override
  void dispose() {
    _target.dispose();
    _details.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ok = _reason != null && _target.text.trim().isNotEmpty;
    return YoloPage(
      title: 'Report an issue',
      body: ListView(padding: const EdgeInsets.all(20), children: [
        SegmentedButton<String>(
          showSelectedIcon: false,
          segments: [for (final t in _types) ButtonSegment(value: t, label: Text(t))],
          selected: {_type},
          onSelectionChanged: (v) => setState(() => _type = v.first),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _target,
          onChanged: (_) => setState(() {}),
          decoration: _deco(switch (_type) { 'User' => 'Yolo ID of the user', 'Room' => 'Room ID', 'Post' => 'Post link', _ => 'Game name' }),
        ),
        const SizedBox(height: 14),
        const Text('Reason', style: TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in _reasons)
            ChoiceChip(
              label: Text(r),
              selected: _reason == r,
              onSelected: (_) => setState(() => _reason = r),
              selectedColor: const Color(0xFFF87171),
              showCheckmark: false,
            ),
        ]),
        const SizedBox(height: 14),
        TextField(controller: _details, maxLines: 4, maxLength: 500, decoration: _deco('Details (optional)')),
        const SizedBox(height: 8),
        const Text('Reports are confidential. The person you report will not know it was you.', style: TextStyle(fontSize: 12, color: YoloColors.textMuted)),
        const SizedBox(height: 14),
        Opacity(
          opacity: ok ? 1 : 0.5,
          child: GoldButton(
            label: 'Submit report',
            onPressed: ok ? () => _submitted(context, ref.read(supportProvider.notifier).submit('Report', '$_type ${_target.text.trim()}: $_reason')) : null,
          ),
        ),
      ]),
    );
  }
}

class TicketsScreen extends ConsumerWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tickets = ref.watch(supportProvider).tickets;
    Color color(String s) => s == 'Resolved' ? YoloColors.online : (s == 'Open' ? YoloColors.gold : const Color(0xFF7DD3FC));
    return YoloPage(
      title: 'My tickets',
      body: tickets.isEmpty
          ? const EmptyState(icon: Icons.confirmation_number_rounded, title: 'No tickets yet')
          : ListView(children: [
              for (final t in tickets)
                ListTile(
                  leading: TintIcon(
                    switch (t.kind) { 'Bug' => Icons.bug_report_rounded, 'Report' => Icons.flag_rounded, 'Support' => Icons.support_agent_rounded, _ => Icons.rate_review_rounded },
                    color: YoloColors.gold,
                    size: 40,
                  ),
                  title: Text(t.summary, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${t.id} · ${t.kind} · ${t.time}', style: const TextStyle(fontSize: 12, color: YoloColors.textMuted)),
                  trailing: Badge2(t.status, bg: color(t.status).withValues(alpha: 0.18), fg: color(t.status)),
                ),
            ]),
    );
  }
}

/// Safety guidelines, privacy policy and terms (templates — the owner must replace placeholders with final legal text).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});
  final String page;

  static const _pages = {
    'safety': ('Safety guidelines', [
      ('Be respectful', 'No bullying, harassment, hate speech or threats. Treat everyone the way you want to be treated.'),
      ('Protect yourself', 'Never share passwords, verification codes, home address or bank details. Yolo staff will never ask for your password.'),
      ('No scams', 'Do not send money or buy coins from strangers outside the app. Report anyone who asks.'),
      ('Adults only', 'Yolo is for people 18 and older. Report users who appear to be underage.'),
      ('Keep it clean', 'No sexual content, nudity, violence or illegal activity in rooms, chats or moments.'),
      ('Use the tools', 'Block, mute, remove from mic and report are always one tap away. Our team reviews reports 24/7.'),
    ]),
    'privacy': ('Privacy policy', [
      ('Template notice', 'This is a starting template. Replace [COMPANY NAME], [ADDRESS] and [CONTACT EMAIL] and have it reviewed by a lawyer before publishing.'),
      ('What we collect', 'Account details (phone or email, nickname, birthday), profile content you add, messages and room activity, purchases, and device information.'),
      ('How we use it', 'To run the service, keep users safe, process payments, show rankings and send notifications you allow.'),
      ('Sharing', 'We do not sell personal data. We share it only with service providers (hosting, payments, voice) and when the law requires.'),
      ('Your choices', 'Change privacy settings, download or delete your data, and turn off notifications at any time.'),
      ('Contact', 'Questions: [CONTACT EMAIL] · [COMPANY NAME], [ADDRESS].'),
    ]),
    'terms': ('Terms of service', [
      ('Template notice', 'This is a starting template. Replace [COMPANY NAME] and [COUNTRY] and have it reviewed by a lawyer before publishing.'),
      ('Eligibility', 'You must be at least 18 years old to use Yolo.'),
      ('Your account', 'Keep your login safe. You are responsible for activity on your account.'),
      ('Virtual items', 'Coins, gifts and items have no cash value, cannot be exchanged outside the app and are non-refundable except where the law requires.'),
      ('Content rules', 'Follow the Safety guidelines. We may remove content or suspend accounts that break them.'),
      ('Changes', 'We may update these terms and will tell you about important changes in the app.'),
      ('Governing law', 'These terms are governed by the laws of [COUNTRY].'),
    ]),
  };

  @override
  Widget build(BuildContext context) {
    final (title, sections) = _pages[page] ?? _pages['safety']!;
    return YoloPage(
      title: title,
      body: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 40), children: [
        for (final (h, body) in sections) ...[
          Text(h, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: YoloColors.gold)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(color: YoloColors.textSoft, height: 1.5)),
          const SizedBox(height: 18),
        ],
      ]),
    );
  }
}
