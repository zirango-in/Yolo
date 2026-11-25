import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../data/demo_content.dart';
import '../../widgets/page_kit.dart';
import '../music/music_pages.dart';

/// Game Center. Games themselves are built in a later phase (see docs/ROADMAP.md).
class GameCenterScreen extends StatelessWidget {
  const GameCenterScreen({super.key, this.embedded = false});
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final grid = GridView.builder(
      padding: EdgeInsets.fromLTRB(20, 8, 20, embedded ? 120 : 40),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 14, crossAxisSpacing: 12, childAspectRatio: 0.78),
      itemCount: demoGames.length,
      itemBuilder: (_, i) {
        final g = demoGames[i];
        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => g.id == 'micgrab' ? Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const MicGrabScreen())) : showYoloToast(context, '${g.name} is coming soon'),
          child: Column(children: [
            Expanded(
              child: Stack(children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(colors: g.colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                    boxShadow: [BoxShadow(color: g.colors.last.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
                  ),
                  alignment: Alignment.center,
                  child: Icon(g.icon, size: 40, color: Colors.white),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: YoloColors.bg.withValues(alpha: 0.6), borderRadius: BorderRadius.circular(8)),
                    child: Text(g.id == 'micgrab' ? 'PLAY' : 'SOON', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: YoloColors.gold)),
                  ),
                ),
              ]),
            ),
            const SizedBox(height: 6),
            Text(g.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text('${g.players} players', style: const TextStyle(fontSize: 11, color: YoloColors.textMuted)),
          ]),
        ).entrance(i);
      },
    );
    if (embedded) {
      return SafeArea(
        bottom: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 4),
            child: Text('Game Center', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Party games are coming soon', style: TextStyle(color: YoloColors.textMuted)),
          ),
          Expanded(child: grid),
        ]),
      );
    }
    return YoloPage(title: 'Game Center', body: grid);
  }
}
