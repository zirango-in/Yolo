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

## NEXT: Step 7 — Family
Create family, search, profile, roles (leader/deputy/admin), level, funds/coins, quests, donations,
activeness, gacha/daily free roll, chests, rewards, family shop, title, frame, sign-in, rankings,
upgrade, leave.
