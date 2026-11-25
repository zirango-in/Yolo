# Progress Log

Read this first when starting a new session: it says exactly where we stopped.

## Session 1 (2026-11-25)

### Done
- `docs/FEATURES.md`: full WePlay-equivalent feature list (18 modules), admin panel module map, Laravel API contract.
- Design canvas with 5 premium screens (Login, Home, Voice Room, Send Gift, Profile & VIP). Source in `design/`.
- Flutter app (`app/`), Phase 1 UI on demo data:
  - Login screen with animated logo (demo login, no real OTP yet)
  - Home: room tabs, event banner with shimmer, animated room cards, pull to refresh, bottom nav with gold create button
  - Voice room: host seat, 8 mic seats (take/leave/locked), animated speaking glow, live chat, mic toggle, follow button
  - Gift panel: recipients, 8 gifts, quantity, coin balance check, full-screen gift animation, gift message in chat
  - Profile: gold-frame avatar, VIP badge, stats, VIP Center card, menu, logout
  - Data layer ready for Laravel: `ApiRepository` + `AppConfig.useDemoData`
- Automated test `app/test/app_flow_test.dart` (login → room → seat → chat → gift): passing.

### Not done / blocked
- **APK not built yet**: the cloud session could not install the Android SDK. Build it on your computer with Android Studio (see README).
- Real live voice (Agora) is not connected yet. Speaking animation is simulated.
- Games and Messages tabs show "coming soon" screens.

### Next steps
1. Build and run on a physical phone; fix anything that looks off.
2. Phone OTP + Google login screens (UI), wired to `ApiRepository`.
3. Agora voice in rooms (needs an Agora App ID).
4. Room settings, admin controls (lock/mute/kick), room member list.

## Session 1, continued — Step 1 done
- Full roadmap from the owner's 17-section list: `docs/ROADMAP.md` (games moved to the end, by owner's choice).
- Step 1 pages built on demo data, all reachable from Home quick entries / bottom nav:
  Discover (search users/rooms/ID, follow, topics), Game Center (coming soon), Friends (friends/following/followers),
  Messages inbox + 1-to-1 chat, Moments (trending/following, like), Family (join/leave, my family, members),
  Events (current/upcoming, details & rules), Shop (buy with coins, equip), Notifications (categories, read all),
  Settings home, other user profile (follow, message, report/block).
- Tests: `test/app_flow_test.dart`, `test/main_pages_test.dart` — passing.
- Next: Step 2 (login & account pages).

## Step 2 done — Login & account
- Welcome carousel (3 slides) → Login (phone, Google, email, guest).
- Phone login: country code, validation → OTP screen (6 boxes, 60s resend timer, wrong-code error;
  demo code 123456) → registration (nickname, gender, birthday, 18+ check).
- Email login with validation, forgot password → account recovery (phone OTP, email reset link, support).
- Account page (Settings → Account & security): copy Yolo ID, buy lucky number, change nickname,
  change phone (OTP), link/unlink Phone/Email/Google/Facebook/Apple (keeps at least one), delete account (type DELETE).
- Guest accounts show a warning to bind a login method.
- Test `test/auth_account_test.dart` (full flows) + earlier tests: 4 passing.
- Laravel endpoints needed: /auth/otp/send, /auth/otp/verify, /auth/email/login, /auth/password/forgot,
  /auth/guest, /me/profile, /me/account/bindings, /me/lucky-id, DELETE /me.
- Next: Step 3 (user profile pages).

## Step 3 done — User profile
- My profile (Me tab): chosen background, avatar in equipped frame, copyable Yolo ID, stats (tap → friends),
  avatar studio + levels shortcuts, VIP card, badges row, achievements progress, my moments, menu.
- Edit profile: photo (gallery / camera via image_picker, avatar, or color), nickname, bio, gender, birthday,
  profile background (6 covers), avatar frame (from owned shop frames).
- Avatar studio (layered 2D, drawn in code): skin tone, eyes, 6 hairstyles + colors, 4 outfits + colors,
  accessories (glasses, shades, crown, headphones, cap), randomize. 3D can replace it later.
- Levels page (user / wealth / charm with progress + level rewards), Badges and Achievements (claim coin rewards).
- Other user profile: cover, relation (Friends / Follows you), mutual followers, follow back, message,
  badges, gift wall, their moments, report / block.
- Test `test/profile_test.dart`; all 5 tests passing.
- Next: Step 4 (voice room features).

## Working agreement (owner's instructions — follow every session)
- Build features step by step from `docs/ROADMAP.md`. Games come LAST (after all app features).
- After each step: run tests → commit → push to `develop` → tell the owner → WAIT for the owner's go-ahead.
- Push before running out of session budget; keep this file updated with what is done and what is next.
- Backend will be PHP Laravel + MySQL; admin panel later. Keep the app's API layer matching `docs/FEATURES.md`.
- Owner tests in Android Studio on a physical phone from `~/Documents/Yolo` (git clone of this repo, `git pull` to update).
- Explain things simply; stop immediately when the owner says stop/wait.

## Step 4 done — Voice rooms
- Create room (+ button): name, announcement, category, cover, 8/12 seats, private with password.
- Private rooms ask for the password (demo: "VIP Lounge", password 1234); lock icon on cards.
- Seat menu: take seat, lock/unlock, invite to seat; on users: profile, gift, leave mic,
  mute/unmute, remove from mic, make/remove admin (owner), ban. Mute and admin badges on seats.
- Room menu: Settings (name, announcement, password lock, mic-request mode, 6 themes), Music
  (6 placeholder tracks, play/pause, now-playing chip), Members (roles), Invite (friends + copy link),
  Ranking (gift contributions), Details, Report (reasons), Exit (minimize / exit; back button asks).
- Speaker on/off, mic on/off, room games button (games come later), family voice room from Family page.
- Fixed: invite button layout bug; toasts no longer cover bottom controls.
- Real live voice still needs Agora + Laravel token endpoint.
- Tests: `test/voice_room_test.dart`; all 6 tests passing.

## Step 5 done — Friends & chat
- Friends page: Friends (mutual follows) / Following / Followers, online status + last seen, requests banner.
- Friend requests page: accept / decline received, cancel sent. Add friends: search by name or exact Yolo ID.
- Messages: Requests shortcut with badge, Groups section, new group (pick 2+ friends), add-friends button.
- Chat: online status in header, text, photo sharing (gallery), hold-to-record voice messages with
  playback animation (demo: no real audio recorded yet), chat history kept per chat, clear history,
  block / unblock (input disabled while blocked), report user. Group chat shows sender names.
- Block list page (Settings → Blocked users); blocked users hidden in Messages, Friends, Discover.
- Fixed: voice message was not sent on release (mic button disappeared while recording).
- Real audio recording needs the `record` package + microphone permission (do with Laravel upload API).
- Tests: `test/friends_chat_test.dart`; all 7 tests passing.

## Step 6 done — Moments
- Feed tabs: Trending, Following (people + followed topics + my posts), Topics (chips, follow/unfollow topic).
- Create post: caption (500 chars), up to 9 photos (gallery multi-pick) or 1 video, topic picker.
- Post card: like (animated), comments count, share (to a friend's chat or copy link), options
  (copy link, delete my post, report others' posts). Tap a topic tag → that topic's feed.
- Post details: full post + comments list + add comment.
- Profile "My moments" shows my real posts; Discover topic chips open the topic feed.
- Video playback is a placeholder card for now (needs video_player + Laravel upload).
- Tests: `test/moments_test.dart`; all 8 tests passing.

## Step 7 done — Family
- Not in a family: create card (5,000 coins), search by name/ID, recommended list → family profile → Join.
- My family: badge, name, slogan, level, my role, title; funds / my family coins / activeness;
  level progress; Sign in (+10 activeness, +20 FC); Donate 100/500/1,000 coins (funds + activeness + FC);
  Upgrade (leader/deputy, costs level × 5,000 funds).
- Feature grid: Voice room (family room), Quests & chests (5 daily quests, 3 activeness chests),
  Lucky roll (daily free roll, then 30 FC; animated board), Family shop (titles + frames with FC),
  Members (roles; leader/deputy can promote/demote/remove), Ranking (weekly by activeness), Leave/Disband.
- Data in `lib/data/family_providers.dart` (Laravel endpoints listed at the top).
- Tests: `test/family_test.dart`; all 9 tests passing.

## Step 8 done — Gifts & virtual items
- 17 gifts in 4 categories: Popular, Lucky (30% chance to win 2×/5×/10× back), VIP (needs VIP level), Special.
- Gift store (Home → Gifts): category tabs, animated preview, buy to backpack, send to a friend.
- Room gift panel tabs now work: Gifts / Lucky / VIP (locked by VIP level) / Backpack (free sends with counts).
- Send gifts outside rooms from any user profile (gift button) — also posts a note in your chat.
- Gift history (sent / received with totals), gift ranking (top senders / receivers).
- My items (backpack): gifts + owned frames, entry effects, special effects, bubbles, themes, decorations; equip/unequip.
- Shop gained Special effects and Decorations categories.
- Data in `lib/data/gift_providers.dart` (single place every gift goes through; maps to Laravel POST /gifts/send).
- Tests: `test/gifts_test.dart`; all 10 tests passing.

## Step 9 done — Coins, wallet & shop
- Every coin change goes through `SessionController.spend/earn(note:)` and is written to `ledgerProvider`.
- Wallet (tap coins on Home, or Me → Wallet): animated balance, diamonds + exchange (10 diamonds = 1 coin),
  first-recharge double bonus, 6 recharge packages (demo payment), links to rewards, monthly pack,
  transactions, purchase history, gift card redeem (demo codes YOLO100, WELCOME500, PARTY2026), shop,
  VIP (Step 10), family coins.
- Transactions (All / Income / Spent), Purchase history (orders with IDs).
- Rewards center: 7-day check-in calendar, monthly pack (300 coins/day × 30 days), daily tasks claim,
  invite friends (code, copy, share link, joined list), event rewards claim.
- Real payments need Google Play Billing (`in_app_purchase`) + Laravel receipt verification.
- Tests: `test/wallet_test.dart`; all 11 tests passing.

## Step 10 done — VIP membership
- 7 VIP levels (Knight → King) with monthly coin price and daily free coins; data in `lib/data/vip_providers.dart`.
- VIP Center (Me → VIP Center, or Wallet → VIP): my status (level, days left, auto-renew), claim daily VIP coins,
  tier strip, per-tier card with 12 privileges (locked/unlocked), VIP gifts, VIP ring (VIP 4+, equip),
  buy / renew / upgrade (upgrade credits unused days of the current tier; lower tiers blocked).
- Subscription page: plan, expiry, auto-renew switch, cancel (stays active until expiry).
- VIP purchase history.
- Tests: `test/vip_test.dart`; all 12 tests passing.

## Step 11 done — Rankings & leaderboards
- Rankings hub (Home trophy button, Discover banner / "Ranking" links): tabs Wealth (top gift senders),
  Charm (top receivers), Rooms, Families, Popular users, Games (live when games launch), Events.
- Daily / Weekly / Monthly, Global / Friends filter, animated top-3 podium, list, pinned "My position"
  with the gap to the next rank. Tap a row → user profile / room (password check) / family profile.
- Uses real gift records and family activeness; demo numbers otherwise. Laravel: GET /rankings/{type}?period=&scope=
- Tests: `test/rankings_test.dart`; all 13 tests passing.

## Step 12 done — Events & missions
- Events home: live-event banner carousel with live countdowns, shortcuts (Missions, Check-in, Achievements,
  Rankings), Current / Upcoming / Ended tabs with Joined + reminder markers.
- Event details: big countdown, Join (live) / Remind me (upcoming), my points + rank, rules, milestone rewards
  (claim when points reached), event gifts (count as points), event leaderboard.
- Event points come automatically from gifts sent (GiftCenter → EventsController.onGiftSent).
- Missions: Daily (shared with Rewards), Weekly, New user — progress, claim coins, reset countdown.
- Home "Ludo Party Night" banner opens the live event. Data in `lib/data/events_providers.dart`.
- Tests: `test/events_test.dart`; all 14 tests passing.

## Step 13 done — Notifications
- Notification center with 9 types and tabs (All, Friends, Messages, Gifts, Invites, Family, Events, Rewards, System).
- Unread count in the title, red dots, badge on the Home bell and on the Messages tab.
- Actions: Accept / decline friend, Reply (opens chat), Say thanks for a gift (sends chat message),
  Join room (password check), Open family, View event, Claim reward (coins), Read system notice; game invites "Soon".
- Tap marks read, swipe left deletes, menu: mark all as read, clear all, settings (Step 14).
- GoldButton labels now shrink to fit (narrow buttons / large accessibility fonts).
- Data in `lib/data/notifications_providers.dart`; push delivery (FCM) comes with the Laravel backend.
- Tests: `test/notifications_test.dart`; all 15 tests passing.

## Step 14 done — Settings
- Every Settings row now opens a working page (data in `lib/data/settings_providers.dart`):
  Account & security, Privacy (who can message me, hide online / visitors / gift wall, show location),
  Blocked users, Notifications (7 categories, sound, vibrate, do-not-disturb), Sound (room & effects volume,
  gift sounds, noise suppression, vibration), Language (8 languages; Arabic/Urdu switch the app to
  right-to-left — full translations need ARB language files), Theme & display (royal dark; light theme later;
  text size small/default/large applied app-wide; reduce motion), Permissions (mic, camera, photos, location,
  notifications via permission_handler; request / open phone settings), Cache & storage (breakdown + clear), Log out.
- Android manifest now declares INTERNET, RECORD_AUDIO, CAMERA, READ_MEDIA_*, location, POST_NOTIFICATIONS.
- Tests: `test/settings_test.dart`; all 16 tests passing.

## NEXT: Step 15 — Safety & support
Help center (FAQ), customer service chat, feedback, bug report, report user / room / post / game issue,
block user, safety guidelines, privacy policy, terms of service, account deletion.
