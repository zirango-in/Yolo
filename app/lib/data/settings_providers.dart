import 'package:flutter_riverpod/flutter_riverpod.dart';

/// App settings. Stored on the device (and synced to Laravel /me/settings later).
class AppSettings {
  // Privacy
  final String whoCanMessage; // everyone, friends, nobody
  final bool hideOnline;
  final bool hideVisitors;
  final bool showLocation;
  final bool hideGiftWall;
  // Notifications
  final Map<String, bool> notify;
  final bool doNotDisturb; // 23:00–08:00
  final bool notifySound;
  final bool notifyVibrate;
  // Sound
  final double roomVolume;
  final double effectsVolume;
  final bool giftSounds;
  final bool noiseSuppression;
  final bool vibration;
  // Language & display
  final String language; // code
  final double textScale;
  final bool reduceMotion;

  const AppSettings({
    this.whoCanMessage = 'everyone',
    this.hideOnline = false,
    this.hideVisitors = false,
    this.showLocation = true,
    this.hideGiftWall = false,
    this.notify = const {'messages': true, 'friends': true, 'gifts': true, 'rooms': true, 'family': true, 'events': true, 'system': true},
    this.doNotDisturb = false,
    this.notifySound = true,
    this.notifyVibrate = true,
    this.roomVolume = 0.8,
    this.effectsVolume = 0.6,
    this.giftSounds = true,
    this.noiseSuppression = true,
    this.vibration = true,
    this.language = 'en',
    this.textScale = 1.0,
    this.reduceMotion = false,
  });

  AppSettings copyWith({
    String? whoCanMessage,
    bool? hideOnline,
    bool? hideVisitors,
    bool? showLocation,
    bool? hideGiftWall,
    Map<String, bool>? notify,
    bool? doNotDisturb,
    bool? notifySound,
    bool? notifyVibrate,
    double? roomVolume,
    double? effectsVolume,
    bool? giftSounds,
    bool? noiseSuppression,
    bool? vibration,
    String? language,
    double? textScale,
    bool? reduceMotion,
  }) =>
      AppSettings(
        whoCanMessage: whoCanMessage ?? this.whoCanMessage,
        hideOnline: hideOnline ?? this.hideOnline,
        hideVisitors: hideVisitors ?? this.hideVisitors,
        showLocation: showLocation ?? this.showLocation,
        hideGiftWall: hideGiftWall ?? this.hideGiftWall,
        notify: notify ?? this.notify,
        doNotDisturb: doNotDisturb ?? this.doNotDisturb,
        notifySound: notifySound ?? this.notifySound,
        notifyVibrate: notifyVibrate ?? this.notifyVibrate,
        roomVolume: roomVolume ?? this.roomVolume,
        effectsVolume: effectsVolume ?? this.effectsVolume,
        giftSounds: giftSounds ?? this.giftSounds,
        noiseSuppression: noiseSuppression ?? this.noiseSuppression,
        vibration: vibration ?? this.vibration,
        language: language ?? this.language,
        textScale: textScale ?? this.textScale,
        reduceMotion: reduceMotion ?? this.reduceMotion,
      );

  bool get isRtl => rtlLanguages.contains(language);
}

/// (code, native name, English name)
const appLanguages = [
  ('en', 'English', 'English'),
  ('hi', 'हिन्दी', 'Hindi'),
  ('ur', 'اردو', 'Urdu'),
  ('ar', 'العربية', 'Arabic'),
  ('bn', 'বাংলা', 'Bengali'),
  ('id', 'Bahasa Indonesia', 'Indonesian'),
  ('tr', 'Türkçe', 'Turkish'),
  ('es', 'Español', 'Spanish'),
];
const rtlLanguages = {'ar', 'ur'};

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => const AppSettings();

  void update(AppSettings Function(AppSettings) f) => state = f(state);

  void toggleNotify(String key) => state = state.copyWith(notify: {...state.notify, key: !(state.notify[key] ?? true)});
}
