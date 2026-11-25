# Yolo — Full Feature & Function List

Yolo is a premium voice party app with the same feature set as WePlay, under
its own name and design. This document is the **single source of truth** for:

- **App** — Flutter (Android first, iOS later)
- **Backend** — PHP Laravel + MySQL (REST API + realtime via Laravel Reverb / Pusher protocol)
- **Admin panel** — Laravel web panel built on the same features

Each module lists what the user does in the app, what the admin controls, and
the main API endpoints the Laravel backend should provide.

**Status legend:** `[ ]` not started · `[~]` UI with demo data · `[x]` fully working with backend

**Phases:** P1 = core · P2 = social & gifts · P3 = games · P4 = monetization & growth

---

## 1. Account & Onboarding (P1)

| Feature | App | Admin |
|---|---|---|
| Splash screen, app version check, force-update | [ ] | Set min/latest version, update URL |
| Login with phone + OTP | [ ] | SMS provider config |
| Login with Google / Facebook / Apple | [ ] | Enable/disable each method |
| Guest browse (limited) | [ ] | Toggle |
| Profile setup: nickname, gender, birthday, country, avatar | [ ] | — |
| Unique user ID (numeric, e.g. 1048576) and **fancy/VIP IDs** (purchasable short IDs) | [ ] | Manage fancy ID pool and prices |
| Language selection (English, Arabic, Hindi, Urdu, Turkish, Indonesian…) with RTL | [ ] | Manage translations |
| Terms, privacy policy, community rules acceptance | [ ] | Edit pages |
| Device/IP ban check on login | [ ] | Ban user / device / IP |
| Account deletion & logout | [ ] | — |

API: `POST /auth/otp/send`, `POST /auth/otp/verify`, `POST /auth/social`, `POST /auth/logout`, `GET /app/config`, `PUT /me/profile`, `DELETE /me`

## 2. User Profile (P1)

| Feature | App | Admin |
|---|---|---|
| Profile page: avatar, frame, nickname, ID (copy), gender/age badge, country flag | [ ] | View/edit any user |
| Bio / signature, photo album (up to 9 photos), voice intro | [ ] | Photo moderation queue |
| Levels: **User level (XP)**, **Wealth level** (coins spent), **Charm level** (gifts received) | [ ] | Level thresholds & rewards |
| Badges / medals wall | [ ] | Create medals, grant manually |
| VIP / Noble badge display | [ ] | — |
| Following / Followers / Friends / Visitors counts | [ ] | — |
| Gift wall (gifts received) | [ ] | — |
| CP / relationship display (couple, best friend…) | [ ] | — |
| Current room ("In room — tap to join") | [ ] | — |
| Edit profile, privacy settings (hide visitors, hide location, who can message) | [ ] | — |
| Block / report user | [ ] | Report queue |

API: `GET /users/{id}`, `PUT /me/profile`, `POST /me/photos`, `GET /users/{id}/gifts`, `GET /users/{id}/badges`, `POST /users/{id}/report`, `POST /users/{id}/block`

## 3. Social Graph (P2)

| Feature | App | Admin |
|---|---|---|
| Follow / unfollow; friends = mutual follow | [ ] | — |
| Followers, following, friends, visitors lists | [ ] | — |
| Search users by ID or nickname | [ ] | — |
| "People nearby" / recommended users | [ ] | Recommendation rules |
| Online status & last seen | [ ] | — |

API: `POST /users/{id}/follow`, `DELETE /users/{id}/follow`, `GET /me/followers|following|friends|visitors`, `GET /search/users?q=`

## 4. Voice Party Rooms (P1 — core)

| Feature | App | Admin |
|---|---|---|
| Room list: tabs Popular / Following / New / by country / by category (Chat, Music, Games, Friends, Dating) | [ ] | Pin / hot-list rooms, categories |
| Create my room (one permanent room per user): name, cover, announcement, tag, language | [ ] | — |
| Room ID, room level, room member count, online count | [ ] | — |
| **Mic seats**: 8 or 12 (or 16) seat layouts + owner seat | [ ] | Allowed layouts |
| Take seat, leave seat, request to join mic (queue), invite to mic | [ ] | — |
| Lock / unlock seat, mute seat, kick from seat | [ ] | — |
| Roles: Owner, Admin (up to N), Member, Visitor | [ ] | — |
| Live voice for seated users (Agora/ZEGO RTC); mute own mic, mute speaker | [ ] | RTC keys, usage stats |
| **Speaking animation** (glowing ring / wave on avatar) | [ ] | — |
| Room chat (text, emoji, @mention), system messages (joined, followed, gifted) | [ ] | Banned-words list |
| Entry announcement with **entry effect / mount** animation | [ ] | — |
| Room settings: password lock, mic mode (free / apply), background theme, chat on/off | [ ] | Upload themes |
| Kick / ban from room, mute in chat, blacklist | [ ] | Global room ban, close room |
| Room members list, online users list with roles | [ ] | — |
| Follow / join room as member (room fans) | [ ] | — |
| Share room link / invite friends | [ ] | — |
| Minimize room (floating bubble while browsing app) | [ ] | — |
| Background music player for owner/admins | [ ] | — |
| Room contribution ranking (daily/weekly top gifters in room) | [ ] | — |
| Room PK (two rooms/teams compete by gift points, timer) | [ ] | PK config |
| Room level & room tasks | [ ] | Level thresholds |
| Lucky bag / red packet in room (coins split among grabbers) | [ ] | Limits, fees |
| Super-mic / emoji reactions on seat (dice, rock-paper-scissors, number) | [ ] | Emoji packs |
| Report room | [ ] | Report queue, live monitor (listen in) |

API: `GET /rooms?tab=`, `POST /rooms`, `GET /rooms/{id}`, `PUT /rooms/{id}`, `POST /rooms/{id}/join`, `POST /rooms/{id}/leave`, `POST /rooms/{id}/seats/{n}/take|leave|lock|mute|kick`, `POST /rooms/{id}/admins`, `POST /rooms/{id}/ban`, `GET /rooms/{id}/rtc-token`, `GET /rooms/{id}/ranking`
Realtime channel `presence-room.{id}` events: `seat.updated`, `user.joined`, `user.left`, `chat.message`, `gift.sent`, `room.updated`, `user.kicked`, `pk.updated`

## 5. Messaging (P2)

| Feature | App | Admin |
|---|---|---|
| Inbox: private chats, system notices, official announcements | [ ] | Send official/broadcast messages |
| 1-to-1 chat: text, emoji, image, voice note, gift in chat | [ ] | Message moderation (reports) |
| Read receipts, typing indicator, unread badges | [ ] | — |
| Room invitation cards in chat | [ ] | — |
| Group chats (family/club groups) | [ ] | — |
| Push notifications (FCM) | [ ] | Push campaigns |

API: `GET /conversations`, `GET /conversations/{id}/messages`, `POST /conversations/{id}/messages`, realtime `private-user.{id}`

## 6. Gifts & Effects (P2)

| Feature | App | Admin |
|---|---|---|
| Gift panel: tabs Gifts / Lucky / VIP / Country / Backpack | [ ] | Gift CRUD: name, icon, animation (Lottie/SVGA/MP4), price, category, sort |
| Send to one, several, or all seated users; quantity (1, 10, 66, 99, 520, 1314) | [ ] | — |
| Full-screen gift animations for expensive gifts | [ ] | — |
| **Global broadcast banner** (huge gift seen in all rooms) | [ ] | Threshold |
| Lucky gifts (random multiplier coin return) | [ ] | Win rates, pool |
| Combo sending (tap repeatedly, combo counter) | [ ] | — |
| Receiver earns **diamonds/beans**; sender earns wealth XP | [ ] | Conversion rates |
| Gift history (sent / received) | [ ] | Gift logs |

API: `GET /gifts`, `POST /rooms/{id}/gifts` `{gift_id, receivers[], qty}`, `GET /me/gift-history`

## 7. Wallet & Economy (P4)

| Feature | App | Admin |
|---|---|---|
| Coins balance; recharge via Google Play / App Store in-app purchase | [ ] | Packages & prices |
| Recharge via **coin sellers/resellers** (agents who transfer coins) | [ ] | Manage coin sellers, their stock |
| Diamonds/beans balance (from gifts) → exchange to coins or withdraw | [ ] | Exchange rates, withdrawal approvals |
| Transaction history | [ ] | Full ledger, manual adjust |
| First-recharge bonus, recharge events | [ ] | Configure |

API: `GET /wallet`, `GET /wallet/packages`, `POST /wallet/iap/verify`, `POST /wallet/exchange`, `GET /wallet/transactions`

## 8. VIP / Noble System (P4)

| Feature | App | Admin |
|---|---|---|
| VIP tiers (e.g. VIP1–VIP7 / Knight → King) bought monthly | [ ] | Tier prices & privileges |
| Privileges: badge, colored name, exclusive frame, entry effect, chat bubble, anti-kick, hide visitors, exclusive gifts, daily coins | [ ] | — |
| VIP center page comparing tiers | [ ] | — |

API: `GET /vip/tiers`, `POST /vip/purchase`

## 9. Store & Backpack (P4)

| Feature | App | Admin |
|---|---|---|
| Store: avatar frames, entry effects / mounts (cars), chat bubbles, room themes, profile cards, fancy IDs | [ ] | Item CRUD, prices, durations |
| Buy for self or gift to friend; time-limited items (7/30 days) | [ ] | — |
| Backpack: owned items, equip / unequip, expiry | [ ] | Grant items |

API: `GET /store/items?type=`, `POST /store/purchase`, `GET /me/backpack`, `POST /me/backpack/{id}/equip`

## 10. Mini Games (P3)

All games run inside a room or in a game lobby with matchmaking. Multiplayer
state is server-authoritative (Laravel + Reverb, or a small Node game server).

| Game | Players | App | Admin |
|---|---|---|---|
| Draw & Guess | 2–8 | [ ] | Word lists per language |
| Who is the Spy / Undercover | 4–8 | [ ] | Word pairs |
| Werewolf (voice) | 6–12 | [ ] | Role config |
| Ludo | 2–4 | [ ] | Entry fee / reward |
| UNO-style card game | 2–6 | [ ] | — |
| Domino | 2–4 | [ ] | — |
| Lucky wheel / spin | 1 | [ ] | Prizes & odds |
| Dice / coin betting (room game) | many | [ ] | Odds, limits |

Shared: game lobby, quick match, play with room members, coin entry fee & prize, game history, game leaderboards.

API: `GET /games`, `POST /games/{type}/match`, `POST /games/{id}/action`, realtime `presence-game.{id}`

## 11. Family / Club (P4)

| Feature | App | Admin |
|---|---|---|
| Create family (cost coins), join / leave / apply | [ ] | Approve, dissolve |
| Family roles: leader, deputy, elders, members | [ ] | — |
| Family level, family badge on members, family group chat | [ ] | Level rules |
| Family tasks & weekly ranking | [ ] | — |

API: `GET /families`, `POST /families`, `POST /families/{id}/join`, `GET /families/{id}/members`

## 12. CP / Relationships (P4)

| Feature | App | Admin |
|---|---|---|
| Send CP request with a ring gift; CP pair shown on both profiles | [ ] | Relationship types |
| Relationship types: Couple, Best friend, Brother, Sister | [ ] | — |
| CP level grows by gifts between pair; break up | [ ] | — |

## 13. Rankings & Leaderboards (P2)

Daily / weekly / monthly: **Wealth** (top senders), **Charm** (top receivers), **Rooms**, **Families**, **Games**. Global and by country.
Admin: reset cycles, reward top ranks.
API: `GET /rankings/{type}?period=`

## 14. Moments / Feed (P4)

Post text + photos, like, comment, share; following feed and trending feed.
Admin: post moderation, delete, pin.
API: `GET /moments`, `POST /moments`, `POST /moments/{id}/like`, `POST /moments/{id}/comments`

## 15. Tasks, Check-in & Events (P4)

| Feature | App | Admin |
|---|---|---|
| Daily check-in calendar with rewards | [ ] | Reward table |
| Daily / newbie tasks (stay in room 10 min, send a gift, follow 3 users…) | [ ] | Task CRUD |
| Event banners on home (web-view event pages) | [ ] | Banner CRUD, schedule |
| Invite friends / referral rewards | [ ] | Referral rules |

## 16. Host & Agency System (P4)

Hosts (talents) join an **agency**; earn salary from diamonds received and mic time.
Admin: approve agencies, link hosts, salary policies, monthly settlement reports.

## 17. Safety & Moderation (P1–P4)

Report user/room/message/moment, banned-words filter, image moderation, user ban (temporary/permanent), device ban, room close, live room monitor, appeal flow, minor protection.

## 18. Settings (P1)

Account & security, notifications, privacy, blacklist, language, clear cache, about, help & feedback, logout.

---

## Admin Panel (Laravel) — Module Map

1. **Dashboard** — DAU/MAU, new users, revenue, online now, live rooms, top gifts
2. **Users** — search, view, edit, ban, coin/item adjust, login history
3. **Rooms** — list, live monitor, close, pin, categories, themes
4. **Gifts** — CRUD, animations upload, lucky-gift config, gift logs
5. **Store & VIP** — items, tiers, prices
6. **Wallet** — recharge packages, coin sellers, exchange, withdrawals, ledger
7. **Games** — enable/disable, word lists, odds, history
8. **Families / Agencies / Hosts**
9. **Rankings & Events** — banners, tasks, check-in rewards, referral
10. **Moderation** — reports queue, banned words, photo/moment review
11. **Messaging** — official notices, push campaigns
12. **Settings** — app config, versions, login methods, RTC/SMS/payment keys, translations
13. **Admins & roles** — staff accounts with permissions

---

## Technical Contract (App ↔ Laravel)

- REST JSON under `/api/v1`, auth with **Laravel Sanctum** bearer tokens.
- Response envelope: `{ "success": true, "data": {...}, "message": "" }`; errors use HTTP status + `{ "success": false, "message": "...", "errors": {} }`.
- Pagination: `?page=` with `meta: { current_page, last_page, total }`.
- Realtime: **Laravel Reverb** (Pusher protocol); private/presence channels authorized via `/broadcasting/auth`.
- Voice: **Agora RTC**; Laravel issues RTC tokens (`GET /rooms/{id}/rtc-token`).
- Files: avatars/covers uploaded via multipart to Laravel (S3 or local storage).
- The Flutter app has a `DataSource` layer: **demo data now**, switched to the Laravel API by changing one config flag (`AppConfig.useDemoData`).
