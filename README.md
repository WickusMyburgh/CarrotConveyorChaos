# 🥕 Carrot Conveyor Chaos

**Summer Rabbits Factory — The Game**

A forced-perspective, swipe-to-sort reflex game. Carrots rush down a conveyor toward you: keep the good ones, toss the rotten ones, defuse the bombs, and grab power-ups — all while the belt speeds up shift after shift.

Single self-contained HTML file. No build step, no dependencies, no bundler.

---

## 🎮 How to play

| Input | Action |
|---|---|
| **Swipe left** | Keep — good 🥕 and golden ✨ carrots |
| **Swipe right** | Toss — rotten 🤢 carrots and bombs 💣 |
| **Swipe up** | Grab a power-up |
| Arrow keys | Same three actions on desktop |

- **3 mistakes** cost a life. **Mishandling a bomb** costs one instantly.
- Sorting 3 in a row **repairs** one mistake.
- Combos multiply your score up to ×5.
- The belt speeds up every 40 seconds — each new *shift* pays a bonus.

**Power-ups:** ⏱️ slow-mo · ⭐ double points · 🛡️ shield (absorbs one mistake) · 🧲 auto-sort (next 5 handled for you) · 💗 extra life

### Two modes

- **🏁 Daily Shift** — the same carrot sequence for every player worldwide, rerolled at UTC midnight. This is the fair race, and it feeds the **daily leaderboard**.
- **♾️ Endless** — a fresh random run every time. Feeds the **all-time leaderboard**.

---

## 🚀 Deploy to GitHub Pages

1. Create a new repository on GitHub (e.g. `carrot-conveyor-chaos`).
2. Upload every file from this folder to the repo root:
   ```
   index.html
   manifest.webmanifest
   sw.js
   icon-192.png
   icon-512.png
   apple-touch-icon.png
   .nojekyll
   README.md
   supabase-setup.sql
   ```
3. Go to **Settings → Pages**.
4. Under **Source**, choose **Deploy from a branch**; pick branch `main` and folder `/ (root)`. Save.
5. Wait ~60 seconds. Your game is live at:
   ```
   https://YOUR-USERNAME.github.io/carrot-conveyor-chaos/
   ```

> `.nojekyll` matters: without it GitHub Pages runs Jekyll, which ignores files beginning with an underscore and can interfere with asset serving.

The game is fully playable at this point — leaderboards just stay local to each device until you do the next section.

---

## 🏆 Enable the online leaderboards

Both boards run on [Supabase](https://supabase.com)'s free tier via plain REST calls — no SDK, no server, no build step.

### 1. Create the project
1. Sign up at [supabase.com](https://supabase.com) and create a new project (free tier is plenty).
2. Pick any region close to your players. Wait for provisioning to finish.

### 2. Create the table
1. Open **SQL Editor → New query**.
2. Paste the entire contents of **`supabase-setup.sql`** and hit **Run**.

This creates the `scores` table, its indexes, and the Row Level Security policies.

### 3. Wire up the game
1. In Supabase go to **Project Settings → API**.
2. Copy the **Project URL** and the **`anon` / `public` key**.
3. Open `index.html`, find this block near the top of the `<script>`:

   ```js
   const SB_URL = 'YOUR_SUPABASE_URL';
   const SB_KEY = 'YOUR_SUPABASE_ANON_KEY';
   ```
4. Replace both with your values:
   ```js
   const SB_URL = 'https://abcdefghijkl.supabase.co';
   const SB_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6...';
   ```
5. Commit and push. Bump `CACHE` in `sw.js` (e.g. `carrot-conveyor-v2`) so returning players get the new build instead of the cached old one.

### Is it safe to publish the anon key?

Yes — that's what it's designed for. It identifies the project, not a user, and it's visible in every Supabase browser app. Row Level Security is the actual protection: the policies in the SQL file allow only `SELECT` and `INSERT` on `scores`. There is deliberately **no** `UPDATE` or `DELETE` policy, so with RLS enabled those are denied to anyone holding the anon key. The `CHECK` constraints additionally reject malformed names and absurd scores.

Never publish the **`service_role`** key — that one bypasses RLS entirely.

---

## 🔒 A note on leaderboard integrity

This is a client-authoritative browser game, so a determined person can open devtools and submit a score they didn't earn. That's inherent to any static-hosted game with an open write endpoint — the SQL constraints raise the effort bar and cap the damage, but they don't make it tamper-proof.

For a casual game shared with friends this is normally fine. If it ever matters more, the usual escalation path is:

1. Add a Supabase **Edge Function** that validates a submission before inserting, and revoke direct insert from `anon`.
2. Have the client send a compact **replay** (the seed plus input timings) rather than a score, and re-simulate it server-side.
3. Rate-limit submissions per device/IP.

Because the Daily Shift is fully seeded, option 2 is genuinely practical here — the same seed replays identically, which is exactly what server-side verification needs.

---

## 🛠️ Tech notes

- **Rendering** — HTML5 Canvas 2D, everything drawn procedurally. No sprite sheets or image assets.
- **Perspective** — items carry a depth `z`; `project(z, x)` maps depth to screen position and scale via `s = FOCAL / (FOCAL + z)`, giving the forced-perspective corridor. Cast shadows are drawn at each item's floor contact point.
- **Responsive** — the canvas fills the viewport in any orientation. The virtual space is ~1000 units tall with width following the real aspect ratio, so nothing is ever letterboxed.
- **Determinism** — the Daily Shift seeds a `mulberry32` PRNG from the UTC day index. Every gameplay draw comes from that stream; all cosmetic randomness uses `Math.random` so visual variation can never desync the shared sequence.
- **Offline** — a service worker caches the game. Scores earned offline queue in `localStorage` and upload on reconnect.
- **Audio** — all sound is synthesised at runtime with the Web Audio API. No audio files.

### Tuning

Handy constants near the top of the script:

| Constant | Effect |
|---|---|
| `SHIFT_DURATION` | Seconds per shift before the belt speeds up |
| `zSpeed()` | How fast items travel toward you |
| `spawnSpacingZ()` | Gap between items (lower = denser) |
| `ZONE_Z` | Depth at which an item becomes swipeable |
| `START_LIVES` / `MAX_LIVES` | Life economy |
| `BASE_POINTS` | Score per item type |
| `FOCAL` / `NEAR_Y` | Perspective strength and how close items get |

---

## 📄 License

MIT — do what you like with it.
