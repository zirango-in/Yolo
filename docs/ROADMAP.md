# Yolo Build Roadmap

The full feature list requested by the owner, grouped into build steps.
Each step is built, tested and pushed before the next one starts.

`[x]` done (UI working on demo data) · `[ ]` not started · `[api]` needs Laravel backend to be fully live

Naming: "WePlay UID" → **Yolo ID**. WePlay-original games get Yolo's own versions and names
(shown in brackets) so the app is safe to publish.

---

## Step 1 — Main Navigation & Home Pages
- [x] Home Page
- [x] Discover / Explore Page
- [x] Game Center
- [x] Voice Room Page
- [x] Friends Page
- [x] Messages / Chat Page
- [x] Moments / Posts Page
- [x] Family Page
- [x] Profile / Me Page
- [x] Events Page
- [x] Shop Page
- [x] Notifications Page

## Step 2 — Login & Account
- [x] Welcome Page
- [x] Login Page
- [x] Phone Number Login
- [x] Email Login
- [x] Guest Login
- [x] Account Registration
- [x] OTP Verification
- [x] Account Binding
- [x] Account Management
- [x] Change Phone Number
- [x] Change Nickname
- [x] Yolo ID (UID)
- [x] Lucky Number
- [x] Account Recovery
- [x] Delete Account

## Step 3 — User Profile
- [x] My Profile · Other User Profile · Edit Profile · Profile Photo
- [x] Avatar Customization (layered 2D first; 3D later): Face · Hairstyle · Clothes / Outfit · Accessories
- [x] Avatar Frames · Profile Background
- [x] User Level · User ID · Badges · Achievements
- [x] User Posts / Moments · Follow / Friend info

## Step 4 — Voice Rooms
- [ ] Room List · Public Room · Private Room · Create Room · Join Room · Room Details
- [ ] Owner / Host · Admin Management
- [ ] Mic Seats · Join Mic · Leave Mic · Mic On / Off · Speaker Controls
- [ ] Room Chat · Room Members · Invite Friends
- [ ] Room Background · Room Theme · Room Music
- [ ] Room Games · Room Gifts · Gift Animations · Room Rankings
- [ ] Room Settings · Password · Announcement · Lock / Unlock · Exit · Report Room
- [ ] Family Voice Room
- [ ] [api] Real live voice (Agora)

## Step 5 — Friends & Chat
- [ ] Friends List · Add Friends · Search User · Search by Yolo ID · Friend Requests
- [ ] Following · Followers · Mutual Friends
- [ ] Private Chat · Group Chat · Chat History
- [ ] Text Messages · Voice Messages · Image Sharing
- [ ] Online Status · Block List · Report User

## Step 6 — Moments / Social Feed
- [ ] Feed · Create Post · Upload Photo · Upload Video · Caption · Topic / Area
- [ ] Like · Comment · Share · Follow Topics
- [ ] User Posts · Post Details · Delete Post · Report Post

## Step 7 — Family
- [ ] Family Home · Create · Join · Search · Profile · Members
- [ ] Leader · Deputy · Admin · Roles
- [ ] Level · Funds · Coins · Quests · Donations · Activeness
- [ ] Gacha · Daily Free Roll · Chests · Rewards · Family Shop
- [ ] Family Voice Room · Title · Avatar Frame · Sign-in
- [ ] Rankings · Upgrade · Leave Family

## Step 8 — Gifts & Virtual Items
- [ ] Gift Store · Send · Receive · Categories · Animations · Special Gifts
- [ ] Gift History · My Gifts · Gift Rankings
- [ ] Avatar Items · Avatar Frames · Decorations · Special Effects

## Step 9 — Coins, Wallet & Shop
- [ ] Coins · Recharge [api: Google Play billing] · Purchase History · Transactions
- [ ] Daily Check-in · Daily Tasks · Rewards · Invite Rewards · Event Rewards
- [ ] Family Coins · Family Funds
- [ ] Shop · Gift Cards · Virtual Items · Monthly Packs · VIP Purchase

## Step 10 — VIP Membership
- [ ] VIP Center · Benefits · Levels · VIP Gifts · VIP Rings · Privileges
- [ ] Monthly Subscription · Subscription Management · VIP Purchase History

## Step 11 — Rankings & Leaderboards
- [ ] Global · User · Game · Voice Room · Gift · Family
- [ ] Popular Users · Popular Rooms · Weekly · Event

## Step 12 — Events & Missions
- [ ] Events Home · Current · Upcoming · Details · Rules
- [ ] Daily Missions · Weekly Missions · New User Tasks · Check-in Rewards
- [ ] Event Leaderboard · Event Gifts · Claim Rewards · Achievements

## Step 13 — Notifications
- [ ] All · Friend Requests · Messages · Gifts · Room Invites · Game Invites
- [ ] Family · System · Events · Rewards

## Step 14 — Settings
- [ ] Settings Home · Account · Privacy · Notifications · Sound · Language · Theme
- [ ] Blocked Users · Permissions (Microphone · Camera · Gallery · Location)
- [ ] Cache / Storage · Logout

## Step 15 — Safety & Support
- [ ] Help Center · Customer Service · Feedback · Bug Report
- [ ] Report User / Room / Post / Game Issue · Block User
- [ ] Safety Guidelines · Privacy Policy · Terms of Service · Account Deletion

## Step 16+ — Games (one game per step, each fully playable) — LATER, after all app features (owner's decision)
Shared screens for every game: Lobby · Create · Join · Matchmaking · Player List · Rules · Settings ·
Start · Game Interface · Turns · Game Chat · Results · Winner · Rewards · History

- [ ] Ludo
- [ ] Reversi
- [ ] Bingo
- [ ] Draw & Guess
- [ ] Who Is Spy
- [ ] Werewolf
- [ ] Space Werewolf → (Yolo: **Star Impostor**)
- [ ] Mic Grab
- [ ] Oh My Card → (Yolo: **Wild Cards**, UNO-style)
- [ ] Liar's Party → (Yolo: **Bluff Party**)
- [ ] Paint Hide & Seek → (Yolo: **Color Hide**)
- [ ] Alpaca → (Yolo: **Llama Dash**)
- [ ] Trickster's Cafe → (Yolo: **Trick Café**)
- [ ] Jackaroo
- [ ] More party games

Online multiplayer for games needs the Laravel realtime server [api]; until then games run
against computer players / pass-and-play.

## Step 17 — Music & Singing
- [ ] Music Page · Karaoke · Mic Grab · Song List · Popular Songs · Song Search
- [ ] Singing Room · Singing Battle · Mic Selection · Singer Queue · Singing Results
- [ ] Music Upload
- Note: real songs need licensed music; demo uses placeholder tracks.
