import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../widgets/common.dart';
import '../../widgets/page_kit.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final list = demoEvents.where((e) => e.live == (_tab == 0)).toList();
    return YoloPage(
      title: 'Events',
      bottom: YoloTabs(tabs: const ['Current', 'Upcoming'], index: _tab, onChanged: (i) => setState(() => _tab = i)),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 40),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final e = list[i];
          return GlassCard(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            padding: const EdgeInsets.all(18),
            gradient: LinearGradient(colors: e.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
            onTap: () => _details(context, e),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Badge2(e.live ? 'LIVE' : 'SOON', bg: e.live ? const Color(0xFFEF4444) : const Color(0x33FFFFFF), fg: Colors.white),
                  const SizedBox(height: 8),
                  Text(e.title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text(e.subtitle, style: const TextStyle(fontSize: 13, color: Color(0xFFF1E6FF))),
                  const SizedBox(height: 8),
                  Text(e.when, style: const TextStyle(fontSize: 12, color: Color(0xFFFDE7A8), fontWeight: FontWeight.w700)),
                ]),
              ),
              Icon(e.icon, size: 56, color: Colors.white.withValues(alpha: 0.85)),
            ]),
          ).entrance(i);
        },
      ),
    );
  }

  void _details(BuildContext context, YoloEvent e) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YoloColors.sheet,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(e.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(e.when, style: const TextStyle(color: YoloColors.gold, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          const Text('Rules', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text('• ${e.subtitle}\n• Rankings update every 10 minutes\n• Rewards are sent to your backpack when the event ends',
              style: const TextStyle(color: YoloColors.textSoft, height: 1.6)),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: GoldButton(
              label: e.live ? 'Join now' : 'Remind me',
              onPressed: () {
                Navigator.pop(context);
                showYoloToast(context, e.live ? 'Good luck!' : 'We will remind you');
              },
            ),
          ),
        ]),
      ),
    );
  }
}
